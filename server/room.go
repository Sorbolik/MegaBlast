package main

import (
	"encoding/json"
	"fmt"
	"log"
	"regexp"
	"strconv"
	"strings"
	"sync/atomic"
)

const (
	tickRate      = 60
	snapshotEvery = 2 // 30 states per second, like SNAPSHOT_TICKS in client/sim/game.lua
)

// Message from a client:
//
//	{"t":"hello","v":8,"mode":"2v2","vetrina":{"liv":12,"bdg":[{"id":"mira","grado":2}]}}
//	                                    first message: protocol version, queue ("1v1",
//	                                    "2v2", "ffa" or the id of an event with its queue, GET /eventi)
//	                                    and card (level and badges, the others see them)
//	{"t":"hello","v":8,"tok":"..."}    or: I'm back in the match I dropped from
//	{"t":"hello","v":8,"privata":"nuova"} or "privata":"4821": I open a private room,
//	                                    or join the one with that code (private.go, with its messages)
//	{"t":"pick","w":"shards"}           start-of-match draft: one primary and one secondary
//	                                    (the weapon tells the category; can change until time's up)
//	{"t":"in","l":true,"r":false,"j":true} | {"t":"jump"} | {"t":"fire","a":1.2,"p":0.7,"w":"missile"}
//	{"t":"aim","a":1.2} | {"t":"aim_end"}  I'm aiming at that angle (at most a few per second) | I stopped:
//	                                    the others see it in the state ("aim"), without the power
//	{"t":"leave"}                       I leave the match (in-match gear wheel): I don't come
//	                                    back, the others know at once (also during the draft);
//	                                    still queued: out of the queue, the server closes
//
// "j" says whether jump is still held down: releasing it while rising makes the jump short.
// "w" is the weapon: "missile" (if missing), "sword", "teleport", a secondary picked
// at the start ("eagle", "mallet", "lunge", "bellows") or a crate weapon ("grenade",
// "shards", "punch", "sniper": the simulation only uses it if the robot has shots).
type clientMsg struct {
	T    string  `json:"t"`
	L    bool    `json:"l"`
	R    bool    `json:"r"`
	J    bool    `json:"j"`
	A    float64 `json:"a"`
	P    float64 `json:"p"`
	W    string  `json:"w"`
	V    int     `json:"v"`
	Mode string  `json:"mode"`
	Tok  string  `json:"tok"`
	// private rooms (private.go): "nuova" or the code in the hello; seat and bot grade
	Private string `json:"privata"`
	I       int    `json:"i"`
	G       int    `json:"g"`
	// with the greeting: level and badges of the card (menu/showcase.lua, per_rete)
	// (raw: a wrong card must not make the greeting fail)
	Showcase json.RawMessage `json:"vetrina"`
}

type showcaseMsg struct {
	Level int `json:"liv"`
	Bdg   []struct {
		ID    string `json:"id"`
		Grade int    `json:"grado"`
	} `json:"bdg"`
}

// Badges are few (menu/milestones.lua): at most badgeMax get through, with a
// short name of lowercase letters and a grade from 1 to gradeMax
const (
	badgeMax = 3
	gradeMax = 4
	levelMax = 999
)

var badgeID = regexp.MustCompile(`^[a-z_]{1,16}$`)

// showcaseJSON checks what the client sends and rewrites it as JSON: the other
// players receive it as it is in the draft and start messages. Whatever can't
// be read (or is missing) becomes an empty card
func showcaseJSON(raw json.RawMessage) []byte {
	var v showcaseMsg
	if len(raw) == 0 || json.Unmarshal(raw, &v) != nil {
		// for example "bdg":{} (an empty Lua table becomes an object)
		var only struct {
			Level int `json:"liv"`
		}
		if json.Unmarshal(raw, &only) != nil || only.Level == 0 {
			return []byte("{}")
		}
		v = showcaseMsg{Level: only.Level}
	}
	out := fmt.Appendf(nil, `{"liv":%d,"bdg":[`, min(max(v.Level, 1), levelMax))
	n := 0
	for _, b := range v.Bdg {
		if n == badgeMax {
			break
		}
		if !badgeID.MatchString(b.ID) || b.Grade < 1 || b.Grade > gradeMax {
			continue
		}
		if n > 0 {
			out = append(out, ',')
		}
		out = fmt.Appendf(out, `{"id":%q,"grado":%d}`, b.ID, b.Grade)
		n++
	}
	return append(out, "]}"...)
}

func parseClientMsg(data []byte) (clientMsg, error) {
	var msg clientMsg
	err := json.Unmarshal(data, &msg)
	return msg, err
}

// roomMsg reaches the room from the connection goroutines. The room reads them
// only at the start of its tick, on its worker: the match state is never
// touched by two goroutines at once and no locks are needed.
type roomMsg struct {
	slot   int
	msg    clientMsg
	attach *Player // the player of seat slot reconnected with this connection
}

type held struct {
	left, right, jump, hold, fire bool
	angle, power                  float64
	weapon                        string
	aiming                        bool    // aiming now ("aim"): the others see it in the state
	aim                           float64 // at which angle
}

// seat is a place in the room: robot slot+1.
type seat struct {
	p    *Player // nil while the player is disconnected
	tok  string  // to come back to the match
	away int     // ticks spent disconnected
	gone bool    // not coming back
	team int
	bot  int // > 0: a bot of that grade (sim/bot.lua GRADES) that fills the queue, no connection
	in   held
}

// Room is a match: its players here, its simulation (draft, then match) in
// the LuaJIT process of its worker (proc.go, server/worker.lua), by id. The
// room writes its commands into the worker's batch of the tick; the answers
// come back in the callbacks, on the same worker, before the next tick.
type Room struct {
	srv   *Server
	id    int64
	mode  Mode
	rules []byte // the event's rules as Lua (luaFromJSON), nil outside events
	seed  int64
	mapID string // the simulation picks it from the seed (maps.pick) when it starts
	seats []*seat
	in    chan roomMsg
	back  chan roomMsg // reconnections: a channel of their own, a full in can't lose them
	tick  int
	ended atomic.Bool

	opened  bool // the draft has been created in the process
	ready   bool // and its time is known (draftLeft)
	started bool // the match has been created (after the draft)
	cur     int  // seat on turn (from 0), from the last tick's answer

	draftLeft int    // tick at the end of the draft
	players   []byte // teams as JSON, [{"team":1},...]; from start also the draft picks
	showcases []byte // the players' cards as JSON, [{"liv":12,"bdg":[...]},...]
}

// room ids, the same in Go and in the processes
var roomIDs atomic.Int64

// seatSpec says who takes a seat of a new room, in config.MODES order: a
// person, or a bot of grade bot (sim/bot.lua GRADES) when p is nil.
type seatSpec struct {
	p   *Player
	bot int
}

// queueSeats: the people of a queue in order, then bots of grade grade in the
// empty seats (lobby.go fills a queue after BotAfter). In queue order the
// people land on alternating teams (config.MODES), so two people in a 2 vs 2
// play against each other.
func queueSeats(mode Mode, players []*Player, grade int) []seatSpec {
	specs := make([]seatSpec, mode.Players)
	for i := range specs {
		if i < len(players) {
			specs[i].p = players[i]
		} else {
			specs[i].bot = grade
		}
	}
	return specs
}

// newRoom prepares the room outside the workers: the weapon draft opens on
// its first tick, in its worker's process. specs has one entry per seat of
// the mode: a queue's (queueSeats) or a private room's (private.go), where
// people and bots sit where they chose.
func newRoom(srv *Server, mode Mode, specs []seatSpec, seed int64) (*Room, error) {
	rules, err := luaFromJSON(mode.Rules)
	if err != nil {
		return nil, err
	}
	r := &Room{srv: srv, id: roomIDs.Add(1), mode: mode, rules: rules, seed: seed,
		in: make(chan roomMsg, 64*mode.Players), back: make(chan roomMsg, 4*mode.Players)}
	teams, showcases := []string{}, []string{}
	for i := 0; i < mode.Players; i++ {
		team := modeTeam(mode.Sim, i) // as in config.MODES (TestModesMatchConfig)
		p := specs[i].p
		if p == nil {
			showcases = append(showcases, `{"bot":true}`)
			teams = append(teams, fmt.Sprintf(`{"team":%d,"bot":%d}`, team, specs[i].bot))
			r.seats = append(r.seats, &seat{team: team, bot: specs[i].bot})
			continue
		}
		if p.showcase != nil {
			showcases = append(showcases, string(p.showcase))
		} else {
			showcases = append(showcases, "{}")
		}
		teams = append(teams, fmt.Sprintf(`{"team":%d}`, team))
		s := &seat{p: p, tok: srv.newToken(), team: team}
		r.seats = append(r.seats, s)
		srv.sessions.Store(s.tok, seatRef{r, i})
		p.room.Store(&seatRef{r, i})
	}
	r.players = []byte("[" + strings.Join(teams, ",") + "]")
	r.showcases = []byte("[" + strings.Join(showcases, ",") + "]")
	return r, nil
}

// open creates the draft in the process and sends it to everyone.
func (r *Room) open(b *Batch) {
	r.opened = true
	b.Cmd("open", r.id, func(next *Batch, res Result) {
		if r.ended.Load() {
			return
		}
		var v struct {
			Secs int `json:"secs"`
		}
		if res.Err == nil {
			res.Err = json.Unmarshal(res.Head, &v)
		}
		if res.Err != nil {
			r.fail(next, "errore nella scelta delle armi", res.Err)
			return
		}
		r.draftLeft, r.ready = v.Secs*tickRate, true
		if r.srv.cfg.DraftTicks > 0 {
			r.draftLeft = r.srv.cfg.DraftTicks
		}
	}).Int("seed", r.seed).Str("mode", r.mode.Sim).Lit("rules", r.rules).Raw(",bots={")
	for i, s := range r.seats {
		if s.bot > 0 {
			b.Raw("[" + strconv.Itoa(i+1) + "]=" + strconv.Itoa(s.bot) + ",")
		}
	}
	b.Raw("}").End()
	for i := range r.seats {
		r.sendDraft(b, i)
	}
}

// fail closes the room after an error of the simulation.
func (r *Room) fail(b *Batch, what string, err error) {
	log.Printf("%s: %v", what, err)
	r.broadcast([]byte(`{"t":"error"}`))
	r.close(b)
}

// seatRef says where a player is: room and seat.
type seatRef struct {
	room *Room
	slot int
}

// Post delivers a message to the room without ever blocking the sender: if
// the queue is full (clients flooding messages, which the rate limit of
// server.go prevents) the message is lost. A reconnection goes in its own
// queue; if even that is full (four reconnections per seat in one tick) the
// player is told to come back.
func (r *Room) Post(m roomMsg) {
	if m.attach != nil {
		select {
		case r.back <- m:
		default:
			m.attach.Send([]byte(`{"t":"error","e":"expired"}`))
			m.attach.Close()
		}
		return
	}
	select {
	case r.in <- m:
	default:
	}
}

func (r *Room) send(slot int, msg []byte) {
	if p := r.seats[slot].p; p != nil {
		p.Send(msg)
	}
}

func (r *Room) broadcast(msg []byte) {
	for _, s := range r.seats {
		if s.p != nil {
			s.p.Send(msg)
		}
	}
}

// rules: those of the queue's event (sim/rules.lua), the client passes them to
// its copy of the match; null outside events.
func (r *Room) sendStart(slot int, resume bool) {
	rules := r.mode.Rules
	if rules == nil {
		rules = []byte("null")
	}
	r.send(slot, fmt.Appendf(nil, `{"t":"start","seed":%d,"map":%q,"mode":%q,"you":%d,"tok":%q,"resume":%t,"players":%s,"regole":%s,"vetrine":%s}`,
		r.seed, r.mapID, r.mode.Name, slot+1, r.seats[slot].tok, resume, r.players, rules, r.showcases))
}

// sendDraft sends a player the weapon draft: fans, their picks (p, p2: the
// others' aren't shown), ticks left, and who they are (you, tok, players: also
// needed to come back if they drop now).
func (r *Room) sendDraft(b *Batch, slot int) {
	b.Cmd("draft", r.id, func(_ *Batch, res Result) { r.draftAnswer(slot, res) }).Int("i", int64(slot+1)).End()
}

// draftAnswer sends the draft state that came from the process, if any.
func (r *Room) draftAnswer(slot int, res Result) {
	if r.ended.Load() || res.Err != nil || len(res.Raw) == 0 {
		return
	}
	msg := res.Raw[0]
	// who they are, and the teams already JSON: at the end of the object
	msg = fmt.Appendf(msg[:len(msg)-1], `,"left":%d,"you":%d,"tok":%q,"mode":%q,"players":`,
		r.draftLeft, slot+1, r.seats[slot].tok, r.mode.Name)
	msg = append(append(append(msg, r.players...), `,"vetrine":`...), r.showcases...)
	r.send(slot, append(msg, '}'))
}

// startMatch closes the weapon draft and creates the match.
func (r *Room) startMatch(b *Batch) {
	r.started = true
	b.Cmd("start", r.id, func(next *Batch, res Result) {
		if r.ended.Load() {
			return
		}
		var v struct {
			Map string `json:"map"`
			Cur int    `json:"cur"`
		}
		if res.Err == nil {
			res.Err = json.Unmarshal(res.Head, &v)
		}
		if res.Err != nil || len(res.Raw) == 0 {
			r.fail(next, "errore all'inizio della partita", res.Err)
			return
		}
		r.players, r.mapID, r.cur = res.Raw[0], v.Map, v.Cur-1
		for i := range r.seats {
			r.sendStart(i, false)
		}
	}).End()
}

// Tick writes into b what the room does in this tick: the players' messages,
// then a step of the match (or of the draft's clock). Whether the room is over
// is known after the answers (r.ended).
func (r *Room) Tick(b *Batch) {
	if !r.opened {
		r.open(b)
	}
	for {
		select {
		case m := <-r.back:
			r.handle(b, m)
			continue
		case m := <-r.in:
			r.handle(b, m)
			continue
		default:
		}
		break
	}
	if r.ended.Load() {
		return
	}
	if !r.checkAway() {
		r.close(b)
		return
	}
	if !r.started {
		if !r.ready {
			return
		}
		if r.draftLeft--; r.draftLeft > 0 {
			return
		}
		r.startMatch(b)
	}

	// the keys of whoever is on turn (the others' don't count)
	b.Cmd("tick", r.id, r.ticked).Bool("s", r.tick%snapshotEvery == 0)
	if h := &r.seats[r.cur].in; *h != (held{}) {
		b.Raw(",k={").Bool("l", h.left).Bool("r", h.right).Bool("j", h.jump).Bool("h", h.hold)
		if h.fire {
			b.Num("a", h.angle).Num("p", h.power).Str("w", h.weapon)
		}
		if h.aiming {
			b.Num("m", h.aim)
		}
		b.Raw("}")
	}
	b.End()
	// jump and fire count for one tick only
	for _, s := range r.seats {
		s.in.jump, s.in.fire = false, false
	}
	r.tick++
}

// ticked: the answer of a tick of the match (worker.lua, tick).
func (r *Room) ticked(next *Batch, res Result) {
	if r.ended.Load() {
		return
	}
	var v [4]int // cur, now, over, st
	if res.Err == nil {
		if f := strings.Fields(string(res.Head)); len(f) == len(v) {
			for i := range v {
				v[i], res.Err = strconv.Atoi(f[i])
			}
		} else {
			res.Err = fmt.Errorf("risposta %q", res.Head)
		}
	}
	cur, now, over := v[0], v[1], v[2]
	if res.Err != nil {
		r.fail(next, "errore step", res.Err)
		return
	}
	// held keys stay, but not into the next turn: a release that arrives
	// after the turn is over (the client sends only on its own turn) would make
	// the next one start walking (Sergio, 5 Nov)
	if now != cur {
		for _, s := range r.seats {
			s.in = held{}
		}
	}
	r.cur = now - 1
	for _, e := range res.Raw {
		r.broadcast(e)
	}
	if over == 1 {
		r.close(next)
	}
}

func (r *Room) handle(b *Batch, m roomMsg) {
	s := r.seats[m.slot]
	switch {
	case m.attach != nil:
		if s.gone {
			m.attach.Send([]byte(`{"t":"error","e":"expired"}`))
			m.attach.Close()
			return
		}
		if s.p != nil && s.p != m.attach {
			s.p.Close() // the old connection isn't needed any more
		}
		s.p, s.away = m.attach, 0
		if !r.started {
			r.sendDraft(b, m.slot)
		} else {
			slot := m.slot
			// start again, the digs so far and the state
			b.Cmd("resume", r.id, func(_ *Batch, res Result) {
				if r.ended.Load() || res.Err != nil {
					return
				}
				r.sendStart(slot, true)
				for _, msg := range res.Raw {
					r.send(slot, msg)
				}
			}).End()
		}
		r.broadcast(fmt.Appendf(nil, `{"t":"back","robot":%d}`, m.slot+1))
	default:
		if s.p == nil {
			return
		}
		if m.msg.T == "leave" {
			r.leave(b, m.slot)
			return
		}
		if !r.started {
			r.handleDraft(b, m)
			return
		}
		h := &s.in
		switch m.msg.T {
		case "in":
			h.left, h.right, h.hold = m.msg.L, m.msg.R, m.msg.J
		case "jump":
			h.jump, h.hold = true, true
		case "fire":
			h.fire, h.angle, h.power, h.weapon = true, m.msg.A, m.msg.P, m.msg.W
			h.aiming = false
		case "aim":
			h.aiming, h.aim = true, m.msg.A
		case "aim_end":
			h.aiming = false
		}
	}
}

// handleDraft: picks during the weapon draft. The others don't see them: the
// confirmation goes back only to whoever picked.
func (r *Room) handleDraft(b *Batch, m roomMsg) {
	if m.msg.T != "pick" {
		return
	}
	slot := m.slot
	b.Cmd("pick", r.id, func(_ *Batch, res Result) { r.draftAnswer(slot, res) }).
		Int("i", int64(slot+1)).Str("w", m.msg.W).End()
}

// checkAway notices dropped connections and counts the time of whoever is
// disconnected. Once the time to come back has passed the player really
// leaves; the match goes on as long as at least two teams have someone
// connected or on the way.
// Returns false if the match must be closed.
func (r *Room) checkAway() bool {
	teams := map[int]bool{}
	people := 0
	for i, s := range r.seats {
		if s.bot > 0 {
			teams[s.team] = true
			continue
		}
		if s.p != nil && s.p.Closed() {
			s.p, s.away, s.in = nil, 0, held{} // held keys are released
			r.broadcast(fmt.Appendf(nil, `{"t":"away","robot":%d}`, i+1))
		}
		if s.p == nil && !s.gone {
			s.away++
			if s.away > r.srv.cfg.ReconnectTicks {
				s.gone = true
				r.srv.sessions.Delete(s.tok)
				r.broadcast(fmt.Appendf(nil, `{"t":"left","robot":%d}`, i+1))
			}
		}
		if !s.gone {
			teams[s.team] = true
			people++
		}
	}
	// bots alone don't play for nobody
	return len(teams) >= 2 && people > 0
}

// leave: the player of seat slot leaves by choice. Like someone who doesn't
// come back in time, but at once: the seat isn't kept and the others receive
// "left". The match goes on (checkAway) if at least two teams remain.
func (r *Room) leave(b *Batch, slot int) {
	s := r.seats[slot]
	s.p.room.Store(nil)
	s.p.Close()
	s.p, s.gone, s.in = nil, true, held{}
	r.srv.sessions.Delete(s.tok)
	// in the match their robot disappears at once (during the draft it doesn't exist yet)
	if r.started {
		b.Cmd("remove", r.id, func(_ *Batch, res Result) {
			if res.Err != nil {
				log.Printf("errore remove: %v", res.Err)
			}
		}).Int("i", int64(slot+1)).End()
	}
	r.broadcast(fmt.Appendf(nil, `{"t":"left","robot":%d}`, slot+1))
}

// close closes the match and the connections (after sending the last
// messages); its simulation is freed with b (nil: the process is gone).
func (r *Room) close(b *Batch) {
	if r.ended.Swap(true) {
		return
	}
	if b != nil && r.opened {
		b.Cmd("free", r.id, nil).End()
	}
	for {
		select {
		case m := <-r.back:
			m.attach.Send([]byte(`{"t":"error","e":"expired"}`))
			m.attach.Close()
			continue
		default:
		}
		break
	}
	for _, s := range r.seats {
		r.srv.sessions.Delete(s.tok)
		if s.p != nil {
			s.p.room.Store(nil)
			s.p.Close()
		}
	}
}
