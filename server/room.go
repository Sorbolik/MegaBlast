package main

import (
	"encoding/json"
	"fmt"
	"log"
	"regexp"
	"strings"
	"sync/atomic"

	lua "github.com/yuin/gopher-lua"
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
//	{"t":"pick","w":"shards"}           start-of-match draft: one primary and one secondary
//	                                    (the weapon tells the category; can change until time's up)
//	{"t":"in","l":true,"r":false,"j":true} | {"t":"jump"} | {"t":"fire","a":1.2,"p":0.7,"w":"missile"}
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

// Room is a match: the Lua simulation and its players.
type Room struct {
	srv   *Server
	mode  Mode
	seed  int64
	mapID string // the simulation picks it from the seed (maps.pick) when it starts
	seats []*seat
	in    chan roomMsg
	eng   *Engine
	sim   *Sim // nil during the weapon draft
	tick  int
	ended atomic.Bool

	draft     lua.LValue // state of sim/draft.lua while picking
	draftLeft int        // tick at the end of the draft
	players   []byte     // teams as JSON, [{"team":1},...]; from start also the draft picks
	showcases []byte     // the players' cards as JSON, [{"liv":12,"bdg":[...]},...]
}

// newRoom prepares the match outside the workers and opens the weapon draft.
// The seats past the players are bots of grade botGrade (lobby.go fills a
// queue after BotAfter); in queue order the players land on alternating teams
// (config.MODES), so two people in a 2 vs 2 play against each other.
func newRoom(srv *Server, mode Mode, players []*Player, seed int64, botGrade int) (*Room, error) {
	r := &Room{srv: srv, mode: mode, seed: seed, in: make(chan roomMsg, 64*mode.Players)}
	eng, err := newEngine()
	if err != nil {
		return nil, err
	}
	r.eng = eng
	list, err := eng.call("mode_players", lua.LString(mode.Sim))
	if err == nil {
		var rules lua.LValue
		if rules, err = eng.fromJSON(mode.Rules); err == nil {
			bots := eng.L.NewTable()
			for i := len(players); i < mode.Players; i++ {
				bots.RawSetInt(i+1, lua.LNumber(botGrade))
			}
			r.draft, err = eng.call("draft_new", lua.LNumber(seed), lua.LString(mode.Sim), rules, bots)
		}
	}
	var secs lua.LValue
	if err == nil {
		secs, err = eng.call("draft_seconds")
	}
	if err != nil {
		eng.L.Close()
		return nil, err
	}
	r.draftLeft = int(secs.(lua.LNumber)) * tickRate
	if srv.cfg.DraftTicks > 0 {
		r.draftLeft = srv.cfg.DraftTicks
	}
	teams, showcases := []string{}, []string{}
	for i := 0; i < mode.Players; i++ {
		team := int(list.(*lua.LTable).RawGetInt(i + 1).(*lua.LTable).RawGetString("team").(lua.LNumber))
		if i >= len(players) {
			showcases = append(showcases, `{"bot":true}`)
			teams = append(teams, fmt.Sprintf(`{"team":%d,"bot":%d}`, team, botGrade))
			r.seats = append(r.seats, &seat{team: team, bot: botGrade})
			continue
		}
		p := players[i]
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
	for i := range r.seats {
		r.sendDraft(i)
	}
	return r, nil
}

// seatRef says where a player is: room and seat.
type seatRef struct {
	room *Room
	slot int
}

// Post delivers a message to the room without ever blocking the sender: if
// the queue is full (a client flooding messages) the message is lost.
func (r *Room) Post(m roomMsg) {
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
func (r *Room) sendDraft(slot int) {
	st, err := r.eng.call("draft_state", r.draft, lua.LNumber(slot+1))
	if err != nil {
		return
	}
	t := st.(*lua.LTable)
	t.RawSetString("left", lua.LNumber(r.draftLeft))
	t.RawSetString("you", lua.LNumber(slot+1))
	t.RawSetString("tok", lua.LString(r.seats[slot].tok))
	t.RawSetString("mode", lua.LString(r.mode.Name))
	msg := appendJSON(nil, t)
	// teams are already JSON: we append them at the end of the object
	msg = append(append(append(msg[:len(msg)-1], `,"players":`...), r.players...), `,"vetrine":`...)
	msg = append(append(msg, r.showcases...), '}')
	r.send(slot, msg)
}

// startMatch closes the weapon draft and creates the match.
func (r *Room) startMatch() error {
	players, err := r.eng.call("draft_finish", r.draft)
	if err != nil {
		return err
	}
	r.draft = nil
	if r.sim, err = r.eng.NewSim(r.seed, "", players, r.mode.Rules); err != nil {
		return err
	}
	list, err := r.eng.call("start_players", players)
	if err != nil {
		return err
	}
	r.players = appendJSON(nil, list)
	r.mapID = r.sim.Map()
	for i := range r.seats {
		r.sendStart(i, false)
	}
	return nil
}

// Tick advances the match by one step. Returns false when it's over.
func (r *Room) Tick() bool {
	for {
		select {
		case m := <-r.in:
			r.handle(m)
			continue
		default:
		}
		break
	}
	if !r.checkAway() {
		r.close()
		return false
	}
	if r.sim == nil {
		if r.draftLeft--; r.draftLeft > 0 {
			return true
		}
		if err := r.startMatch(); err != nil {
			log.Printf("errore all'inizio della partita: %v", err)
			r.broadcast([]byte(`{"t":"error"}`))
			r.close()
			return false
		}
	}

	cur := r.sim.Current() - 1
	h := r.seats[cur].in
	err := r.sim.Step(Input{Left: h.left, Right: h.right, Jump: h.jump, Hold: h.hold, Fire: h.fire, Angle: h.angle, Power: h.power, Weapon: h.weapon})
	if err != nil {
		log.Printf("errore step: %v", err)
		r.broadcast([]byte(`{"t":"error"}`))
		r.close()
		return false
	}
	// jump and fire count for one tick only; held keys stay
	for _, s := range r.seats {
		s.in.jump, s.in.fire = false, false
	}
	for _, e := range r.sim.Events() {
		r.broadcast(e)
	}
	over := r.sim.Over()
	if r.tick%snapshotEvery == 0 || over {
		r.broadcast(r.sim.Snapshot())
	}
	r.tick++
	if over {
		r.close()
		return false
	}
	return true
}

func (r *Room) handle(m roomMsg) {
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
		if r.sim == nil {
			r.sendDraft(m.slot)
		} else {
			r.sendStart(m.slot, true)
			r.send(m.slot, r.sim.Sync())
			r.send(m.slot, r.sim.Snapshot())
		}
		r.broadcast(fmt.Appendf(nil, `{"t":"back","robot":%d}`, m.slot+1))
	default:
		if s.p == nil {
			return
		}
		if m.msg.T == "leave" {
			r.leave(m.slot)
			return
		}
		if r.sim == nil {
			r.handleDraft(m)
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
		}
	}
}

// handleDraft: picks during the weapon draft. The others don't see them: the
// confirmation goes back only to whoever picked.
func (r *Room) handleDraft(m roomMsg) {
	if m.msg.T != "pick" {
		return
	}
	if v, _ := r.eng.call("draft_pick", r.draft, lua.LNumber(m.slot+1), lua.LString(m.msg.W)); v == lua.LTrue {
		r.sendDraft(m.slot)
	}
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
func (r *Room) leave(slot int) {
	s := r.seats[slot]
	s.p.room.Store(nil)
	s.p.Close()
	s.p, s.gone, s.in = nil, true, held{}
	r.srv.sessions.Delete(s.tok)
	// in the match their robot disappears at once (during the draft it doesn't exist yet)
	if r.sim != nil {
		if err := r.sim.Remove(slot + 1); err != nil {
			log.Printf("errore remove: %v", err)
		}
	}
	r.broadcast(fmt.Appendf(nil, `{"t":"left","robot":%d}`, slot+1))
}

// close closes the match and the connections (after sending the last messages).
func (r *Room) close() {
	r.ended.Store(true)
	for {
		select {
		case m := <-r.in:
			if m.attach != nil {
				m.attach.Send([]byte(`{"t":"error","e":"expired"}`))
				m.attach.Close()
			}
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
	r.sim = nil
	r.eng.L.Close()
	r.eng = nil
}
