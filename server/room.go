package main

import (
	"encoding/json"
	"fmt"
	"log"
	"regexp"
	"strconv"
	"strings"
	"sync/atomic"
	"time"
)

const (
	tickRate = 60
	// a state every stateEvery ticks (2 a second): the phones play the match
	// themselves from the keys ("k"), the state is only the check that they
	// are where the server is (its fingerprint, fp) and the stand-in (si)
	stateEvery = 30
	// at most this many ticks of the player on turn per tick of the server: the
	// match catches up after a hiccup of their connection
	leadCatchUp = 4
	// at most this many ticks of keys waiting from a player (10 s)
	keysMax = 600
	// the longest key code of a tick (sim/netkeys.lua: a shot is about 50)
	codeMax = 80
	// whoever comes back gets all the keys from the start, this many per message
	keysResume = 3000
)

// Message from a client:
//
//	{"t":"hello","v":11,"mode":"2v2","profilo":"12.4f9a..."}
//	                                    first message: protocol version, queue ("1v1",
//	                                    "2v2", "ffa" or the id of an event with its queue, GET /eventi)
//	                                    and guest profile (accounts.go: the card the others see and
//	                                    what the robot wears come from it, the prizes go to it)
//	{"t":"hello","v":11,"tok":"..."}   or: I'm back in the match I dropped from
//	{"t":"hello","v":11,"privata":"nuova"} or "privata":"4821": I open a private room,
//	                                    or join the one with that code (private.go, with its messages)
//	{"t":"pick","w":"shards"}           start-of-match draft: one primary and one secondary
//	                                    (the weapon tells the category; can change until time's up)
//	{"t":"ready"}                       draft: PRONTO, both weapons picked and confirmed; the others see
//	                                    it ("rd" in the draft), a different pick undoes it; with
//	                                    everyone ready the match starts before time's up
//	{"t":"k","n":812,"k":["","r","r","fmissile,1.2,0.7"],"m":1.2}
//	                                    on my turn: the keys of the ticks my phone has already
//	                                    played (from tick n, sim/netkeys.lua); m: where I aim (the
//	                                    others see it, without the power), absent if I'm not aiming
//	{"t":"nota","w":"..."}              back after a drop: why it had dropped or stalled, for the server's log (server.go)
//	{"t":"leave"}                       I leave the match (in-match gear wheel): I don't come
//	                                    back, the others know at once (also during the draft);
//	                                    still queued: out of the queue, the server closes
//
// Online every phone plays the match itself from the same keys (Sergio, 22 Nov:
// «deve essere il client a comandare quello che vedi»): on your turn your phone
// steps it at once with your keys and sends them, the room applies them
// (waiting for them: your phone leads your turn) and passes everyone the keys
// of every tick ("k" below), bots' included. A phone that finds itself
// different from the server (the fingerprint of the state) comes back in.
type clientMsg struct {
	T    string   `json:"t"`
	W    string   `json:"w"`
	V    int      `json:"v"`
	Mode string   `json:"mode"`
	Tok  string   `json:"tok"`
	N    int      `json:"n"`
	K    []string `json:"k"`
	M    *float64 `json:"m"`
	// private rooms (private.go): "nuova" or the code in the hello; seat and bot grade
	Private string `json:"privata"`
	I       int    `json:"i"`
	G       int    `json:"g"`
	// with the greeting: the guest profile, "<id>.<chiave>" (server.go cards)
	Profile string `json:"profilo"`
}

// equipMax: the longest "eq" that is read (a full one is under 1 KB)
const equipMax = 4096

// equipLua writes what a profile wears (sim/profile.lua equip) as a Lua value for the room's process;
// nil if it's missing, too long or not an object: the base stats
func equipLua(raw json.RawMessage) []byte {
	if len(raw) < 2 || len(raw) > equipMax || raw[0] != '{' {
		return nil
	}
	lua, err := luaFromJSON(raw)
	if err != nil {
		return nil
	}
	return lua
}

type showcaseMsg struct {
	Level int `json:"liv"`
	Bdg   []struct {
		ID    string `json:"id"`
		Grade int    `json:"grado"`
	} `json:"bdg"`
	// the pieces worn, one per slot (sim/gear.lua SLOTS): only shown on the cards
	Pz []struct {
		Set   string `json:"set"`
		Level int    `json:"liv"`
	} `json:"pz"`
}

// Badges are few (menu/milestones.lua): at most badgeMax get through, with a
// short name of lowercase letters and a grade from 1 to gradeMax
const (
	badgeMax = 3
	gradeMax = 4
	levelMax = 999
	// the slots of the gear and the last level of a piece (sim/gear.lua)
	pieceSlots    = 5
	pieceLevelMax = 30
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
		// (the pieces alone, if they can be read)
		var pieces struct {
			Pz json.RawMessage `json:"pz"`
		}
		if json.Unmarshal(raw, &pieces) == nil {
			_ = json.Unmarshal(pieces.Pz, &v.Pz)
		}
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
	out = append(out, ']')
	// the pieces worn: exactly pieceSlots places, a name of lowercase letters
	// and a level in range, else the place is empty. The server has no profiles
	// yet: it can't know whether the player owns them, they are only shown
	if len(v.Pz) > 0 {
		out = append(out, `,"pz":[`...)
		for i := 0; i < pieceSlots; i++ {
			if i > 0 {
				out = append(out, ',')
			}
			if i < len(v.Pz) && badgeID.MatchString(v.Pz[i].Set) && v.Pz[i].Level >= 1 {
				out = fmt.Appendf(out, `{"set":%q,"liv":%d}`, v.Pz[i].Set, min(v.Pz[i].Level, pieceLevelMax))
			} else {
				out = append(out, `{"set":"","liv":0}`...)
			}
		}
		out = append(out, ']')
	}
	return append(out, '}')
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

// seat is a place in the room: robot slot+1.
type seat struct {
	p    *Player // nil while the player is disconnected
	tok  string  // to come back to the match
	away int     // ticks spent disconnected
	gone bool    // not coming back
	sub  bool    // away in the match: a bot plays their turns until they are back (standIn)
	team int
	bot  int // > 0: a bot of that grade (sim/bot.lua GRADES) that fills the queue, no connection
	// the ticks of their turn their phone has played and the room hasn't yet
	// (keys[0] is tick keysAt), where they aim, and how long the match has been
	// waiting for their keys on their turn
	keys   []string
	keysAt int
	aim    *float64
	wait   int
	// the guest profile of whoever sits here (accounts.go), 0: none; the prizes go to it
	account int64
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
	step    int  // ticks of the match asked so far (the next one is tick step)

	// the code of every tick played (sim/netkeys.lua), for whoever comes back;
	// the last ones not yet sent (sent: how many of log went out), the robots
	// removed before the next tick, where the bot on turn aims
	log    []string
	sent   int
	gone   string
	botAim string

	// the private room (private.go) its people go back to when it closes, nil: a queue's
	private *Private

	draftLeft int    // tick at the end of the draft
	players   []byte // teams as JSON, [{"team":1},...]; from the draft also what everyone wears (eq), from start the picks
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
		s := &seat{p: p, tok: srv.newToken(), team: team, account: p.account}
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
		// the players with what everyone wears, the bots too (net.lua draft_new)
		if len(res.Raw) > 0 {
			r.players = res.Raw[0]
		}
		if r.srv.cfg.DraftTicks > 0 {
			r.draftLeft = r.srv.cfg.DraftTicks
		}
	}).Int("seed", r.seed).Str("mode", r.mode.Sim).Lit("rules", r.rules).Raw(",bots={")
	for i, s := range r.seats {
		if s.bot > 0 {
			b.Raw("[" + strconv.Itoa(i+1) + "]=" + strconv.Itoa(s.bot) + ",")
		}
	}
	b.Raw("},eq={")
	for i, s := range r.seats {
		if s.p != nil && s.p.equip != nil {
			b.Raw("[" + strconv.Itoa(i+1) + "]=" + string(s.p.equip) + ",")
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
	r.send(slot, fmt.Appendf(nil, `{"t":"start","seed":%d,"map":%q,"mode":%q,"you":%d,"tok":%q,"resume":%t,"cur":%d,"players":%s,"regole":%s,"vetrine":%s}`,
		r.seed, r.mapID, r.mode.Name, slot+1, r.seats[slot].tok, resume, r.cur+1, r.players, rules, r.showcases))
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
	// the keys of the last tick's steps (the answers came after it)
	r.flush()
	if !r.checkAway(b) {
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

	// whoever is on turn leads: their phone has already played these ticks and
	// the match waits for them (a few at a time if they arrive together); the
	// bots and whoever is disconnected play on the server's clock
	if s := r.seats[r.cur]; s.bot == 0 && s.p != nil && !s.sub {
		for len(s.keys) > 0 && s.keysAt < r.step {
			s.keys, s.keysAt = s.keys[1:], s.keysAt+1
		}
		n := 0
		for ; n < leadCatchUp && len(s.keys) > 0 && s.keysAt == r.step; n++ {
			r.stepTick(b, s.keys[0], r.cur+1)
			s.keys, s.keysAt = s.keys[1:], s.keysAt+1
		}
		if n > 0 {
			s.wait = 0
		} else if s.wait++; s.wait > r.srv.cfg.StandInTicks {
			// connected but silent (the app in the background): like away
			log.Printf("stanza %d: il robot %d non manda tasti da %d s, gioca un bot", r.id, r.cur+1, s.wait/tickRate)
			s.wait = 0
			r.standIn(b, r.cur, true)
		}
	} else {
		r.stepTick(b, "", 0)
	}
	r.tick++
}

// stepTick asks a tick of the match: with the code of the keys of robot lead
// (0: none, a bot's turn or nobody's keys)
func (r *Room) stepTick(b *Batch, code string, lead int) {
	r.step++
	c := b.Cmd("tick", r.id, r.ticked).Bool("s", r.step%stateEvery == 0)
	if lead > 0 {
		c.Str("k", code).Int("lead", int64(lead))
	}
	c.End()
}

// flush sends everyone the keys of the ticks played since the last time (and
// whoever comes back all of them from the start, keysMsg)
func (r *Room) flush() {
	if r.sent == len(r.log) {
		return
	}
	r.broadcast(r.keysMsg(r.sent, len(r.log)))
	r.sent = len(r.log)
}

// keysMsg: {"t":"k","n":from,"k":[codes of the ticks from from to to],"cur":robot
// on turn,"si":a bot plays for them,"m":where they aim}
func (r *Room) keysMsg(from, to int) []byte {
	codes, _ := json.Marshal(r.log[from:to])
	s := r.seats[r.cur]
	msg := fmt.Appendf(nil, `{"t":"k","n":%d,"k":%s,"cur":%d,"si":%t`, from, codes, r.cur+1, s.sub)
	if s.bot == 0 && !s.sub {
		if s.aim != nil {
			msg = fmt.Appendf(msg, `,"m":%.2f`, *s.aim)
		}
	} else if r.botAim != "" {
		msg = fmt.Appendf(msg, `,"m":%s`, r.botAim)
	}
	return append(msg, '}')
}

// ticked: the answer of a tick of the match (worker.lua, tick).
func (r *Room) ticked(next *Batch, res Result) {
	if r.ended.Load() {
		return
	}
	var v [4]int // cur, now, over, st
	f := strings.Fields(string(res.Head))
	if res.Err == nil {
		if len(f) == len(v)+2 {
			for i := range v {
				if v[i], res.Err = strconv.Atoi(f[i]); res.Err != nil {
					break
				}
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
	// the keys applied, with the robots that left right before (leave)
	code := f[4]
	if code == "-" {
		code = ""
	}
	r.log = append(r.log, r.gone+code)
	r.gone = ""
	if r.botAim = f[5]; r.botAim == "-" {
		r.botAim = ""
	}
	if now != cur {
		for i, s := range r.seats {
			s.keys, s.aim, s.wait = nil, nil, 0
			// whoever came back while the bot played their turn has the keys again
			if s.sub && s.p != nil {
				r.standIn(next, i, false)
			}
		}
	}
	r.cur = now - 1
	// the state (the check of the phones)
	for _, e := range res.Raw {
		r.broadcast(e)
	}
	if over == 1 {
		r.flush()
		r.prizes(next)
	}
}

// prizes: the match is over; each person's profile gets what they did
// (worker.lua prizes, accounts.go Award) and their phone the gain ("premio",
// for the podium), then the room closes. Who left by choice gets nothing.
func (r *Room) prizes(b *Batch) {
	acc := r.srv.accounts
	if acc == nil {
		r.close(b)
		return
	}
	b.Cmd("prizes", r.id, func(next *Batch, res Result) {
		if res.Err != nil {
			log.Printf("errore premi: %v", res.Err)
		}
		held := map[*Player]bool{}
		for i, s := range r.seats {
			if s.account == 0 || s.gone || i >= len(res.Raw) || len(res.Raw[i]) == 0 {
				continue
			}
			p, id, action := s.p, s.account, string(res.Raw[i])
			if p != nil {
				held[p] = true
			}
			go func() {
				gain, sum, err := acc.Award(id, action, time.Now())
				if err != nil {
					log.Printf("profili: premio di %d non dato: %v", id, err)
				} else {
					log.Printf("profili: %d premiato online: %s", id, sum)
				}
				if p != nil {
					if gain != nil {
						p.Send(append(append([]byte(`{"t":"premio","g":`), gain...), '}'))
					}
					// from a private room the connection stays: it is back there (closeExcept)
					if r.private == nil {
						p.Close()
					}
				}
			}()
		}
		r.closeExcept(next, held)
	}).End()
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
		log.Printf("stanza %d: il robot %d è tornato dopo %.1f s", r.id, m.slot+1, float64(s.away)/tickRate)
		s.p, s.away = m.attach, 0
		// back in the middle of their turn: the bot finishes it (ticked)
		if s.sub && !(r.started && r.cur == m.slot) {
			r.standIn(b, m.slot, false)
		}
		if !r.started {
			r.sendDraft(b, m.slot)
		} else {
			// start again, and the keys of every tick so far: the phone plays the
			// match again from the seed up to here, quickly (the ones not sent yet
			// arrive twice: the phone skips them)
			r.sendStart(m.slot, true)
			// all the keys from the start (at least one message, even empty)
			for from := 0; ; from += keysResume {
				to := min(from+keysResume, len(r.log))
				r.send(m.slot, r.keysMsg(from, to))
				if to == len(r.log) {
					break
				}
			}
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
		if m.msg.T == "k" {
			s.addKeys(m.msg.N, m.msg.K)
			s.aim = m.msg.M
		}
	}
}

// handleDraft: picks and PRONTO during the weapon draft. The others don't see
// the picks (the confirmation goes back only to whoever picked), but they see
// who is ready: when everyone is, the match starts without waiting for the time.
func (r *Room) handleDraft(b *Batch, m roomMsg) {
	slot := m.slot
	switch m.msg.T {
	case "pick":
		b.Cmd("pick", r.id, func(next *Batch, res Result) {
			var v struct {
				Un bool `json:"un"`
			}
			if res.Err == nil && json.Unmarshal(res.Head, &v) == nil && v.Un {
				r.sendDraftAll(next) // the pick took PRONTO away
				return
			}
			r.draftAnswer(slot, res)
		}).Int("i", int64(slot+1)).Str("w", m.msg.W).End()
	case "ready":
		b.Cmd("ready", r.id, func(next *Batch, res Result) {
			var v struct {
				Ok  bool `json:"ok"`
				All bool `json:"all"`
			}
			if r.ended.Load() || res.Err != nil || json.Unmarshal(res.Head, &v) != nil || !v.Ok {
				return
			}
			r.sendDraftAll(next)
			if v.All && r.draftLeft > 1 {
				r.draftLeft = 1 // the next tick starts the match
			}
		}).Int("i", int64(slot+1)).End()
	}
}

// sendDraftAll sends everyone their draft again (who is ready has changed).
func (r *Room) sendDraftAll(b *Batch) {
	if r.ended.Load() {
		return
	}
	for i := range r.seats {
		r.sendDraft(b, i)
	}
}

// checkAway notices dropped connections and counts the time of whoever is
// disconnected. During the draft, once the time to come back has passed the
// player really leaves; in the match the seat is kept to the end and a bot
// plays their turns meanwhile (standIn). The match goes on as long as at least
// two teams have someone who didn't leave, and someone is there or has been
// away for less than EmptyTicks.
// Returns false if the match must be closed.
func (r *Room) checkAway(b *Batch) bool {
	teams := map[int]bool{}
	people, here := 0, false
	for i, s := range r.seats {
		if s.bot > 0 {
			teams[s.team] = true
			continue
		}
		if s.p != nil && s.p.Closed() {
			s.p, s.away, s.keys = nil, 0, nil
			log.Printf("stanza %d: il robot %d ha perso la connessione (tick %d)", r.id, i+1, r.tick)
			r.broadcast(fmt.Appendf(nil, `{"t":"away","robot":%d}`, i+1))
		}
		if s.p == nil && !s.gone {
			s.away++
			// in the match the seat stays theirs to the end: if they are away when
			// their turn comes (a short drop is only a pause) a bot plays it
			if r.started && !s.sub && r.cur == i && s.away > r.srv.cfg.StandInTicks {
				r.standIn(b, i, true)
			}
			if !r.started && s.away > r.srv.cfg.ReconnectTicks {
				s.gone = true
				r.srv.sessions.Delete(s.tok)
				r.broadcast(fmt.Appendf(nil, `{"t":"left","robot":%d}`, i+1))
			}
		}
		if !s.gone {
			teams[s.team] = true
			people++
			// connected, or away for less than the time an empty room is kept
			here = here || s.p != nil || s.away <= r.srv.cfg.EmptyTicks
		}
	}
	// bots alone don't play for nobody: neither when everyone left, nor when
	// everyone has been away for a while (Sergio, 18 Nov: «falla chiudere quando
	// escono tutti»; the bots that stand in would play to the end of the match)
	if r.started && people > 0 && !here {
		log.Printf("stanza %d: tutti assenti da più di %d s, si chiude", r.id, r.srv.cfg.EmptyTicks/tickRate)
		return false
	}
	return len(teams) >= 2 && people > 0
}

// standIn gives the turns of seat slot to a bot while its player is away (on),
// or back to the player (worker.lua, stand_in). The bot has the grade of the
// room's bots, or the queue's for these people (botGrade). The seat stays the
// player's until the match ends (Sergio, 17 Nov): they can come back at any time.
func (r *Room) standIn(b *Batch, slot int, on bool) {
	r.seats[slot].sub = on
	c := b.Cmd("stand_in", r.id, func(_ *Batch, res Result) {
		if res.Err != nil {
			log.Printf("errore stand_in: %v", res.Err)
		}
	}).Int("i", int64(slot+1))
	if on {
		grade, people := 0, []*Player{}
		for _, s := range r.seats {
			if s.bot > 0 && grade == 0 {
				grade = s.bot
			}
			if s.p != nil {
				people = append(people, s.p)
			}
		}
		if grade == 0 {
			grade = 3
			if len(people) > 0 {
				grade = botGrade(people)
			}
		}
		c = c.Int("g", int64(grade))
	}
	c.End()
}

// leave: the player of seat slot leaves by choice. Like someone who doesn't
// come back in time, but at once: the seat isn't kept and the others receive
// "left". The match goes on (checkAway) if at least two teams remain.
func (r *Room) leave(b *Batch, slot int) {
	s := r.seats[slot]
	s.p.room.Store(nil)
	s.p.Close()
	s.p, s.gone, s.keys = nil, true, nil
	r.srv.sessions.Delete(s.tok)
	// in the match their robot disappears at once (during the draft it doesn't exist yet)
	if r.started {
		// the phones remove it before the next tick (the code of the keys, "x2;")
		r.gone += fmt.Sprintf("x%d;", slot+1)
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
func (r *Room) close(b *Batch) { r.closeExcept(b, nil) }

// closeExcept: like close, but the connections in held stay open (their
// prizes close them)
func (r *Room) closeExcept(b *Batch, held map[*Player]bool) {
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
	// from a private room whoever is still connected goes back there (private.go)
	var back []*Player
	if r.private != nil {
		back = make([]*Player, len(r.seats))
	}
	for i, s := range r.seats {
		r.srv.sessions.Delete(s.tok)
		if s.p != nil {
			s.p.room.Store(nil)
			if back != nil {
				back[i] = s.p
			} else if !held[s.p] {
				s.p.Close()
			}
		}
	}
	if back != nil {
		r.srv.lobby.privateOver(r.private, back)
	}
}

// addKeys: keys of ticks from n that the phone of this seat has played. They
// count only right after the ones already waiting (or as the first ones):
// others mean the phone has gone its own way, it notices and comes back in.
func (s *seat) addKeys(n int, k []string) {
	if len(k) == 0 || len(k) > keysMax {
		return
	}
	for _, c := range k {
		if len(c) > codeMax {
			return
		}
	}
	if len(s.keys) == 0 {
		s.keysAt = n
	} else if n != s.keysAt+len(s.keys) {
		return
	}
	if len(s.keys)+len(k) > keysMax {
		s.keys = nil
		return
	}
	s.keys = append(s.keys, k...)
}
