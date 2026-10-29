package main

import (
	"encoding/json"
	"fmt"
	"log"
	"strings"
	"sync/atomic"

	lua "github.com/yuin/gopher-lua"
)

const (
	tickRate      = 60
	snapshotEvery = 2 // 30 stati al secondo, come SNAPSHOT_TICKS in client/sim/game.lua
)

// Messaggio da un client:
//
//	{"t":"hello","v":2,"mode":"1v1"}   primo messaggio: versione del protocollo e modalità
//	{"t":"hello","v":2,"tok":"..."}    oppure: torno nella partita da cui sono caduto
//	{"t":"hello","v":2,"mode":"2v2","tool":"wall"}   tool: l'attrezzo dell'assetto, già scelto nel draft
//	{"t":"pick","w":"shards"}           scelta d'inizio partita: una primaria, una secondaria e un
//	                                    attrezzo (l'arma dice la categoria; si cambia fino allo scadere)
//	{"t":"swap","to":3}                 propone lo scambio delle scelte al compagno 3 (se lui
//	                                    lo propone a sua volta, lo scambio si fa); "to":0 ritira la proposta
//	{"t":"in","l":true,"r":false,"j":true} | {"t":"jump"} | {"t":"fire","a":1.2,"p":0.7,"w":"missile"}
//	{"t":"leave"}                       esco dalla partita (rotellina in partita): non torno, gli
//	                                    altri lo sanno subito (vale anche durante la scelta)
//
// "j" dice se il salto è ancora tenuto premuto: lasciandolo mentre si sale il salto è corto.
// "w" è l'arma: "missile" (se manca), "sword", "teleport", una secondaria scelta
// all'inizio ("eagle", "mallet", "lunge") o un'arma delle casse ("grenade",
// "shards", "punch", "sniper": la simulazione la usa solo se il robot ha colpi).
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
	Tool string  `json:"tool"`
	To   int     `json:"to"`
}

func parseClientMsg(data []byte) (clientMsg, error) {
	var msg clientMsg
	err := json.Unmarshal(data, &msg)
	return msg, err
}

// roomMsg arriva alla stanza dalle goroutine delle connessioni. La stanza li
// legge solo all'inizio del suo tick, sul suo worker: lo stato della partita
// non è mai toccato da due goroutine insieme e non servono lock.
type roomMsg struct {
	slot   int
	msg    clientMsg
	attach *Player // il giocatore del posto slot si è riconnesso con questa connessione
}

type held struct {
	left, right, jump, hold, fire bool
	angle, power                  float64
	weapon                        string
}

// seat è un posto nella stanza: il robot slot+1.
type seat struct {
	p    *Player // nil mentre il giocatore è disconnesso
	tok  string  // per tornare nella partita
	away int     // tick passati da disconnesso
	gone bool    // non torna più
	team int
	swap int // posto del compagno a cui propone lo scambio, -1 nessuno
	in   held
}

// Room è una partita: la simulazione Lua e i suoi giocatori.
type Room struct {
	srv   *Server
	mode  Mode
	seed  int64
	mapID string // la sceglie la simulazione dal seed (maps.pick) quando parte
	seats []*seat
	in    chan roomMsg
	eng   *Engine
	sim   *Sim // nil durante la scelta delle armi
	tick  int
	ended atomic.Bool

	draft     lua.LValue // stato di sim/draft.lua finché si sceglie
	draftLeft int        // tick alla fine della scelta
	players   []byte     // squadre in JSON, [{"team":1},...]; da start anche le scelte del draft
}

// newRoom prepara la partita fuori dai worker e apre la scelta delle armi.
func newRoom(srv *Server, mode Mode, players []*Player, seed int64) (*Room, error) {
	r := &Room{srv: srv, mode: mode, seed: seed, in: make(chan roomMsg, 64*len(players))}
	eng, err := newEngine()
	if err != nil {
		return nil, err
	}
	r.eng = eng
	list, err := eng.call("mode_players", lua.LString(mode.Sim))
	if err == nil {
		tools := eng.L.NewTable()
		for _, p := range players {
			tools.Append(lua.LString(p.tool))
		}
		r.draft, err = eng.call("draft_new", lua.LNumber(seed), lua.LString(mode.Sim), tools)
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
	teams := []string{}
	for i, p := range players {
		team := int(list.(*lua.LTable).RawGetInt(i + 1).(*lua.LTable).RawGetString("team").(lua.LNumber))
		teams = append(teams, fmt.Sprintf(`{"team":%d}`, team))
		s := &seat{p: p, tok: srv.newToken(), team: team, swap: -1}
		r.seats = append(r.seats, s)
		srv.sessions.Store(s.tok, seatRef{r, i})
		p.room.Store(&seatRef{r, i})
	}
	r.players = []byte("[" + strings.Join(teams, ",") + "]")
	for i := range r.seats {
		r.sendDraft(i)
	}
	return r, nil
}

// seatRef dice dove sta un giocatore: stanza e posto.
type seatRef struct {
	room *Room
	slot int
}

// Post consegna un messaggio alla stanza senza mai bloccare chi lo manda: se la
// coda è piena (client che inonda di messaggi) il messaggio si perde.
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

func (r *Room) sendStart(slot int, resume bool) {
	r.send(slot, fmt.Appendf(nil, `{"t":"start","seed":%d,"map":%q,"mode":%q,"you":%d,"tok":%q,"resume":%t,"players":%s}`,
		r.seed, r.mapID, r.mode.Name, slot+1, r.seats[slot].tok, resume, r.players))
}

// sendDraft manda a un giocatore la scelta delle armi: ventagli, scelte
// fatte (p, p2, p3), proposte di scambio (sw[i]: il compagno a cui il robot i
// propone lo scambio, 0 nessuno), tick rimasti, e chi è (you, tok, players:
// serve anche per tornare se cade adesso).
func (r *Room) sendDraft(slot int) {
	st, err := r.eng.call("draft_state", r.draft)
	if err != nil {
		return
	}
	t := st.(*lua.LTable)
	sw := r.eng.L.NewTable()
	for _, s := range r.seats {
		sw.Append(lua.LNumber(s.swap + 1))
	}
	t.RawSetString("sw", sw)
	t.RawSetString("left", lua.LNumber(r.draftLeft))
	t.RawSetString("you", lua.LNumber(slot+1))
	t.RawSetString("tok", lua.LString(r.seats[slot].tok))
	t.RawSetString("mode", lua.LString(r.mode.Name))
	msg := appendJSON(nil, t)
	// le squadre sono già in JSON: le aggiungiamo in coda all'oggetto
	msg = append(append(append(msg[:len(msg)-1], `,"players":`...), r.players...), '}')
	r.send(slot, msg)
}

// startMatch chiude la scelta delle armi e crea la partita.
func (r *Room) startMatch() error {
	players, err := r.eng.call("draft_finish", r.draft)
	if err != nil {
		return err
	}
	r.draft = nil
	if r.sim, err = r.eng.NewSim(r.seed, "", players, r.mode.Normalize); err != nil {
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

// Tick fa avanzare la partita di un passo. Restituisce false quando è finita.
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
	// salto e sparo valgono per un solo tick; i tasti tenuti premuti restano
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
			s.p.Close() // la vecchia connessione non serve più
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

// handleDraft: scelte e scambi durante la scelta delle armi. A ogni cambio
// tutti ricevono le scelte aggiornate.
func (r *Room) handleDraft(m roomMsg) {
	changed := false
	switch m.msg.T {
	case "pick":
		v, _ := r.eng.call("draft_pick", r.draft, lua.LNumber(m.slot+1), lua.LString(m.msg.W))
		changed = v == lua.LTrue
	case "swap":
		to := m.msg.To - 1
		if to == -1 {
			changed = r.seats[m.slot].swap != -1
			r.seats[m.slot].swap = -1
			break
		}
		if to < 0 || to >= len(r.seats) || to == m.slot || r.seats[to].team != r.seats[m.slot].team {
			return
		}
		if r.seats[to].swap == m.slot {
			// l'altro l'aveva già proposto: lo scambio si fa
			r.eng.call("draft_swap", r.draft, lua.LNumber(m.slot+1), lua.LNumber(to+1))
			r.seats[to].swap, r.seats[m.slot].swap = -1, -1
		} else {
			r.seats[m.slot].swap = to
		}
		changed = true
	}
	if changed {
		for i := range r.seats {
			r.sendDraft(i)
		}
	}
}

// checkAway si accorge delle connessioni cadute e conta il tempo di chi è
// disconnesso. Passato il tempo per tornare il giocatore esce davvero; la
// partita continua finché restano almeno due squadre con qualcuno collegato o
// in arrivo.
// Restituisce false se la partita va chiusa.
func (r *Room) checkAway() bool {
	teams := map[int]bool{}
	for i, s := range r.seats {
		if s.p != nil && s.p.Closed() {
			s.p, s.away, s.in = nil, 0, held{} // i tasti tenuti si lasciano
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
		}
	}
	return len(teams) >= 2
}

// leave: il giocatore del posto slot esce di sua scelta. Come chi non torna in
// tempo, ma subito: il posto non si tiene e gli altri ricevono "left". La
// partita continua (checkAway) se restano almeno due squadre.
func (r *Room) leave(slot int) {
	s := r.seats[slot]
	s.p.room.Store(nil)
	s.p.Close()
	s.p, s.gone, s.in = nil, true, held{}
	r.srv.sessions.Delete(s.tok)
	r.broadcast(fmt.Appendf(nil, `{"t":"left","robot":%d}`, slot+1))
}

// close chiude la partita e le connessioni (dopo aver mandato gli ultimi messaggi).
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
