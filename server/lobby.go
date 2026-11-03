package main

import (
	"fmt"
	"log"
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
}

func NewLobby(srv *Server) *Lobby {
	return &Lobby{srv: srv, queues: map[string][]*Player{}, sizes: map[string]int{}}
}

// Join puts the player in the queue; when the queue has enough players a
// match starts.
func (l *Lobby) Join(p *Player, mode Mode) {
	l.mu.Lock()
	l.sizes[mode.Name] = mode.Players
	q := append(l.queues[mode.Name], p)
	var group []*Player
	if len(q) >= mode.Players {
		group, q = q[:mode.Players:mode.Players], q[mode.Players:]
	}
	l.queues[mode.Name] = q
	if group == nil {
		l.announce(q, mode.Players)
	}
	l.mu.Unlock()

	if group != nil {
		go l.start(mode, group)
	}
}

// announce tells everyone in a queue who is waiting (the waiting room's cards,
// client/menu/sala.lua): {"t":"wait","of":4,"you":2,"vetrine":[{"liv":12,...},{}]}
// in queue order, you = your place. Called with the lock held, at every join and leave.
func (l *Lobby) announce(q []*Player, of int) {
	cards := make([]string, len(q))
	for i, x := range q {
		cards[i] = "{}"
		if x.showcase != nil {
			cards[i] = string(x.showcase)
		}
	}
	list := strings.Join(cards, ",")
	for i, x := range q {
		x.Send(fmt.Appendf(nil, `{"t":"wait","of":%d,"you":%d,"vetrine":[%s]}`, of, i+1, list))
	}
}

func (l *Lobby) start(mode Mode, players []*Player) {
	r, err := newRoom(l.srv, mode, players, time.Now().UnixNano()%2147483646+1)
	if err != nil {
		log.Printf("errore simulazione: %v", err)
		for _, p := range players {
			p.Send([]byte(`{"t":"error"}`))
			p.Close()
		}
		return
	}
	l.srv.sched.Add(r)
}

// Leave removes from the queue whoever disconnects while waiting.
func (l *Lobby) Leave(p *Player) {
	l.mu.Lock()
	defer l.mu.Unlock()
	for name, q := range l.queues {
		for i, x := range q {
			if x == p {
				q = append(q[:i:i], q[i+1:]...)
				l.queues[name] = q
				l.announce(q, l.sizes[name])
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
