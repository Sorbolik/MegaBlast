package main

import (
	"encoding/json"
	"fmt"
	"log"
	"math"
	"strings"
	"sync"
	"time"
)

// Mode is a game queue: how many players a match needs, which simulation mode
// to use (config.MODES, which defines the teams) and, for event queues
// (events.go), the event rules as JSON (sim/rules.lua).
type Mode struct {
	Name    string
	Players int
	Sim     string
	Rules   []byte
}

// The player counts must match config.MODES (checked by TestModesMatchConfig).
var modes = map[string]Mode{
	"1v1": {"1v1", 2, "1v1", nil},
	"2v2": {"2v2", 4, "2v2", nil},
	"ffa": {"ffa", 4, "ffa", nil},
}

// Lobby keeps one queue per mode. The lock is only needed when someone joins
// or leaves a queue, never during matches.
type Lobby struct {
	srv    *Server
	mu     sync.Mutex
	queues map[string][]*Player
	sizes  map[string]int // players a queue's match needs (also event queues)
	// private rooms by code (private.go)
	privates map[string]*Private
}

func NewLobby(srv *Server) *Lobby {
	l := &Lobby{srv: srv, queues: map[string][]*Player{}, sizes: map[string]int{}, privates: map[string]*Private{}}
	if srv.cfg.BotAfter > 0 {
		go l.fillLoop()
	}
	return l
}

// Bots fill a normal queue (Sergio, 3 Nov: "coda da 25 secondi che poi ti
// matcha con i bot", no button: with two people waiting, who would choose?):
// BotAfter after the first in line joined, the match starts with whoever is
// there and bots in the empty seats. Event queues wait for people (their
// leaderboards would count the bots).
func (l *Lobby) fillLoop() {
	t := time.NewTicker(time.Second / 4)
	defer t.Stop()
	for range t.C {
		l.mu.Lock()
		var groups [][]*Player
		var ms []Mode
		for name, q := range l.queues {
			m, normal := modes[name]
			if !normal || len(q) == 0 || time.Since(q[0].joined) < l.srv.cfg.BotAfter {
				continue
			}
			groups, ms = append(groups, q), append(ms, m)
			delete(l.queues, name)
		}
		l.mu.Unlock()
		for i, g := range groups {
			go l.start(ms[i], g)
		}
	}
}

// botGrade: the bots' grade (sim/bot.lua GRADES, 1-10) from the average level
// of the people in the match: 3 up to level 4, one more every 5 levels, at
// most 8 (the two strongest stay for the arena).
func botGrade(players []*Player) int {
	sum := 0
	for _, p := range players {
		var v showcaseMsg
		if p.showcase != nil && json.Unmarshal(p.showcase, &v) == nil {
			sum += v.Level
		}
	}
	return min(8, 3+sum/len(players)/5)
}

// Join puts the player in the queue; when the queue has enough players a
// match starts.
func (l *Lobby) Join(p *Player, mode Mode) {
	l.mu.Lock()
	p.joined = time.Now()
	l.sizes[mode.Name] = mode.Players
	q := append(l.queues[mode.Name], p)
	var group []*Player
	if len(q) >= mode.Players {
		group, q = q[:mode.Players:mode.Players], q[mode.Players:]
	}
	l.queues[mode.Name] = q
	if group == nil {
		l.announce(mode.Name, q, mode.Players)
	}
	l.mu.Unlock()

	if group != nil {
		go l.start(mode, group)
	}
}

// announce tells everyone in a queue who is waiting (the waiting room's cards,
// client/menu/lobby.lua): {"t":"wait","of":4,"you":2,"vetrine":[{"liv":12,...},{}]}
// in queue order, you = your place. Called with the lock held, at every join and leave.
// bot_in: the seconds before the bots (normal queues only).
func (l *Lobby) announce(name string, q []*Player, of int) {
	cards := make([]string, len(q))
	for i, x := range q {
		cards[i] = "{}"
		if x.showcase != nil {
			cards[i] = string(x.showcase)
		}
	}
	list := strings.Join(cards, ",")
	bots := ""
	if _, normal := modes[name]; normal && l.srv.cfg.BotAfter > 0 && len(q) > 0 {
		left := l.srv.cfg.BotAfter - time.Since(q[0].joined)
		bots = fmt.Sprintf(`,"bot_in":%d`, max(0, int(math.Ceil(left.Seconds()))))
	}
	for i, x := range q {
		x.Send(fmt.Appendf(nil, `{"t":"wait","of":%d,"you":%d,"vetrine":[%s]%s}`, of, i+1, list, bots))
	}
}

func (l *Lobby) start(mode Mode, players []*Player) {
	l.open(mode, queueSeats(mode, players, botGrade(players)))
}

// open creates the room of a full queue or of a private room (private.go)
func (l *Lobby) open(mode Mode, specs []seatSpec) {
	r, err := newRoom(l.srv, mode, specs, time.Now().UnixNano()%2147483646+1)
	if err != nil {
		log.Printf("errore simulazione: %v", err)
		for _, sp := range specs {
			if sp.p != nil {
				sp.p.Send([]byte(`{"t":"error"}`))
				sp.p.Close()
			}
		}
		return
	}
	// rooms with bots on their own workers: a bot thinking (peaks of 20 ms)
	// must not slow down the matches between people
	bots := false
	for _, sp := range specs {
		bots = bots || sp.p == nil
	}
	if bots {
		l.srv.botSched.Add(r)
		return
	}
	l.srv.sched.Add(r)
}

// Leave removes from the queue (or from the private room) whoever disconnects while waiting.
func (l *Lobby) Leave(p *Player) {
	l.mu.Lock()
	defer l.mu.Unlock()
	l.leavePrivate(p)
	for name, q := range l.queues {
		for i, x := range q {
			if x == p {
				q = append(q[:i:i], q[i+1:]...)
				l.queues[name] = q
				l.announce(name, q, l.sizes[name])
				return
			}
		}
	}
}

// Drain empties the queues: whoever is waiting goes looking for a match on another server.
func (l *Lobby) Drain() {
	l.mu.Lock()
	defer l.mu.Unlock()
	for name, q := range l.queues {
		for _, p := range q {
			p.Send([]byte(`{"t":"error","e":"draining"}`))
			p.Close()
		}
		delete(l.queues, name)
	}
	for code, r := range l.privates {
		for _, p := range r.people() {
			p.private = nil
			p.Send([]byte(`{"t":"error","e":"draining"}`))
			p.Close()
		}
		delete(l.privates, code)
	}
}

// Waiting is the number of players in queue.
func (l *Lobby) Waiting() int {
	l.mu.Lock()
	defer l.mu.Unlock()
	n := 0
	for _, q := range l.queues {
		n += len(q)
	}
	return n
}
