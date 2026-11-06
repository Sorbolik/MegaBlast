package main

import (
	"fmt"
	"math/rand/v2"
	"strings"
)

// Private rooms (Sergio, 6 Nov: "una modalità partita privata [...] si deve
// poter scegliere il livello dei bot, se contro o con, tutto quello che serve
// per una lobby privata online"). Whoever creates one gets a 4 digit code to
// pass to friends; every seat of the mode (config.MODES, so the teams) is a
// person or a bot. The creator (host) picks the mode, the grade of each bot
// and starts the match; everyone can move to a bot's seat (team change).
// Whoever joins takes the first bot seat. The match is a normal room
// (room.go), with the people and the bots where they sat.
//
// Client to server, before the match (with the "privata" hello, room.go):
//
//	{"t":"posto","i":3}             I move to seat 3 (a bot's: the bot takes mine)
//	{"t":"bot","i":3,"g":7}         host: the bot of seat 3 is grade 7 (1-10, sim/bot.lua GRADES)
//	{"t":"modo","mode":"1v1"}       host: another mode ("1v1", "2v2", "ffa"), if the people fit
//	{"t":"via"}                     host: the match starts (weapon draft, like a queue)
//	{"t":"leave"}                   I leave the room (the server closes)
//
// Server to everyone in the room, at every change:
//
//	{"t":"privata","code":"4821","mode":"2v2","you":1,"host":1,
//	 "posti":[{"team":1,"vetrina":{"liv":12,"bdg":[]}},{"team":2,"bot":5},...]}
//
// you and host are seats (from 1). A wrong code gets {"t":"error","e":"codice"},
// a room full of people {"t":"error","e":"piena"}.
type Private struct {
	code  string
	mode  Mode
	seats []seatSpec // one per seat of the mode
	teams []int      // config.MODES
	host  *Player
}

const botGradeMax = 10 // len(sim/bot.lua GRADES)

// privateModes: the modes a private room can have
var privateModes = []string{"2v2", "1v1", "ffa"}

// NewPrivate opens a private room with p as host, in 2 vs 2, bots in the
// other seats with the queue's grade (botGrade).
func (l *Lobby) NewPrivate(p *Player) {
	l.mu.Lock()
	defer l.mu.Unlock()
	code := ""
	for code == "" || l.privates[code] != nil {
		code = fmt.Sprintf("%04d", rand.IntN(10000))
	}
	r := &Private{code: code, host: p}
	l.privates[code] = r
	p.private = r
	l.setMode(r, modes["2v2"], []*Player{p}, botGrade([]*Player{p}))
	l.tellPrivate(r)
}

// JoinPrivate puts p in the room with that code, in the first bot seat.
func (l *Lobby) JoinPrivate(p *Player, code string) bool {
	l.mu.Lock()
	defer l.mu.Unlock()
	r := l.privates[code]
	if r == nil {
		p.Send([]byte(`{"t":"error","e":"codice"}`))
		return false
	}
	for i := range r.seats {
		if r.seats[i].p == nil {
			r.seats[i].p = p
			p.private = r
			l.tellPrivate(r)
			return true
		}
	}
	p.Send([]byte(`{"t":"error","e":"piena"}`))
	return false
}

// setMode lays the seats of mode out: the people first, in order (so on
// alternating teams), then bots of grade grade.
func (l *Lobby) setMode(r *Private, mode Mode, people []*Player, grade int) {
	r.mode = mode
	r.seats = queueSeats(mode, people, grade)
	r.teams = make([]int, mode.Players)
	for i := range r.teams {
		r.teams[i] = modeTeam(mode.Sim, i)
	}
}

// modeTeam: the team of seat i (from 0) in config.MODES. Every mode
// alternates teams 1..T, T being 2 or the number of players (ffa).
func modeTeam(sim string, i int) int {
	if sim == "ffa" {
		return i + 1
	}
	return i%2 + 1
}

// PrivateMsg: a message of someone in a private room, before the match.
// Whoever is in no private room is ignored.
func (l *Lobby) PrivateMsg(p *Player, m clientMsg) {
	l.mu.Lock()
	r := p.private
	if r == nil {
		l.mu.Unlock()
		return
	}
	me := -1
	for i, s := range r.seats {
		if s.p == p {
			me = i
		}
	}
	host := r.host == p
	var start []seatSpec
	switch m.T {
	case "posto":
		if i := m.I - 1; i >= 0 && i < len(r.seats) && r.seats[i].p == nil {
			r.seats[i], r.seats[me] = r.seats[me], r.seats[i]
		}
	case "bot":
		if i := m.I - 1; host && i >= 0 && i < len(r.seats) && r.seats[i].p == nil {
			r.seats[i].bot = min(max(m.G, 1), botGradeMax)
		}
	case "modo":
		mode, ok := modes[m.Mode]
		people := r.people()
		if host && ok && mode.Name != r.mode.Name && len(people) <= mode.Players {
			l.setMode(r, mode, people, r.grade())
		}
	case "via":
		if host {
			start = r.seats
			for _, s := range r.seats {
				if s.p != nil {
					s.p.private = nil
				}
			}
			delete(l.privates, r.code)
		}
	}
	if start == nil {
		l.tellPrivate(r)
	}
	l.mu.Unlock()
	if start != nil {
		l.open(r.mode, start)
	}
}

// leavePrivate takes p out of their private room (lock held): the seat goes
// to a bot, the host passes to the next person, an empty room closes.
func (l *Lobby) leavePrivate(p *Player) {
	r := p.private
	if r == nil {
		return
	}
	p.private = nil
	for i, s := range r.seats {
		if s.p == p {
			r.seats[i] = seatSpec{bot: r.grade()}
		}
	}
	people := r.people()
	if len(people) == 0 {
		delete(l.privates, r.code)
		return
	}
	if r.host == p {
		r.host = people[0]
	}
	l.tellPrivate(r)
}

func (r *Private) people() []*Player {
	var out []*Player
	for _, s := range r.seats {
		if s.p != nil {
			out = append(out, s.p)
		}
	}
	return out
}

// grade: the grade of a new bot, that of the first bot in the room (the host's
// last choice is the likeliest for the others too), or the queue's
func (r *Private) grade() int {
	for _, s := range r.seats {
		if s.p == nil && s.bot > 0 {
			return s.bot
		}
	}
	return botGrade(r.people())
}

// tellPrivate sends everyone in the room how it is now (lock held)
func (l *Lobby) tellPrivate(r *Private) {
	seats := make([]string, len(r.seats))
	host := 0
	for i, s := range r.seats {
		if s.p == nil {
			seats[i] = fmt.Sprintf(`{"team":%d,"bot":%d}`, r.teams[i], s.bot)
			continue
		}
		if s.p == r.host {
			host = i + 1
		}
		card := "{}"
		if s.p.showcase != nil {
			card = string(s.p.showcase)
		}
		seats[i] = fmt.Sprintf(`{"team":%d,"vetrina":%s}`, r.teams[i], card)
	}
	list := strings.Join(seats, ",")
	for i, s := range r.seats {
		if s.p != nil {
			s.p.Send(fmt.Appendf(nil, `{"t":"privata","code":%q,"mode":%q,"you":%d,"host":%d,"posti":[%s]}`,
				r.code, r.mode.Name, i+1, host, list))
		}
	}
}
