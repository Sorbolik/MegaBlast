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
	snapshotEvery = 2 // 30 stati al secondo, come SNAPSHOT_TICKS in client/sim/game.lua
)

// Messaggio da un client:
//
//	{"t":"hello","v":7,"mode":"2v2","vetrina":{"liv":12,"bdg":[{"id":"mira","grado":2}]}}
//	                                    primo messaggio: versione del protocollo, coda ("1v1",
//	                                    "2v2", "ffa" o l'id di un evento con la sua coda, GET /eventi)
//	                                    e cartellino (livello e badge, li vedono gli altri)
//	{"t":"hello","v":7,"tok":"..."}    oppure: torno nella partita da cui sono caduto
//	{"t":"pick","w":"shards"}           scelta d'inizio partita: una primaria e una secondaria
//	                                    (l'arma dice la categoria; si cambia fino allo scadere)
//	{"t":"in","l":true,"r":false,"j":true} | {"t":"jump"} | {"t":"fire","a":1.2,"p":0.7,"w":"missile"}
//	{"t":"leave"}                       esco dalla partita (rotellina in partita): non torno, gli
//	                                    altri lo sanno subito (vale anche durante la scelta)
//
// "j" dice se il salto è ancora tenuto premuto: lasciandolo mentre si sale il salto è corto.
// "w" è l'arma: "missile" (se manca), "sword", "teleport", una secondaria scelta
// all'inizio ("eagle", "mallet", "lunge", "bellows") o un'arma delle casse ("grenade",
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
	// col saluto: livello e badge del cartellino (menu/vetrina.lua, per_rete)
	// (grezzo: un cartellino sbagliato non deve far fallire il saluto)
	Vetrina json.RawMessage `json:"vetrina"`
}

type vetrinaMsg struct {
	Liv int `json:"liv"`
	Bdg []struct {
		ID    string `json:"id"`
		Grado int    `json:"grado"`
	} `json:"bdg"`
}

// I badge sono pochi (menu/traguardi.lua): ne passano al massimo badgeMax, con
// un nome corto di lettere minuscole e un grado da 1 a gradoMax
const (
	badgeMax = 3
	gradoMax = 4
	livMax   = 999
)

var badgeID = regexp.MustCompile(`^[a-z_]{1,16}$`)

// vetrinaJSON controlla quello che manda il client e lo riscrive in JSON:
// gli altri giocatori lo ricevono così com'è nei messaggi draft e start. Quello
// che non si legge (o manca) diventa un cartellino vuoto
func vetrinaJSON(raw json.RawMessage) []byte {
	var v vetrinaMsg
	if len(raw) == 0 || json.Unmarshal(raw, &v) != nil {
		// per esempio "bdg":{} (una tabella Lua vuota diventa un oggetto)
		var solo struct {
			Liv int `json:"liv"`
		}
		if json.Unmarshal(raw, &solo) != nil || solo.Liv == 0 {
			return []byte("{}")
		}
		v = vetrinaMsg{Liv: solo.Liv}
	}
	out := fmt.Appendf(nil, `{"liv":%d,"bdg":[`, min(max(v.Liv, 1), livMax))
	n := 0
	for _, b := range v.Bdg {
		if n == badgeMax {
			break
		}
		if !badgeID.MatchString(b.ID) || b.Grado < 1 || b.Grado > gradoMax {
			continue
		}
		if n > 0 {
			out = append(out, ',')
		}
		out = fmt.Appendf(out, `{"id":%q,"grado":%d}`, b.ID, b.Grado)
		n++
	}
	return append(out, "]}"...)
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
	vetrine   []byte     // i cartellini dei giocatori in JSON, [{"liv":12,"bdg":[...]},...]
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
		var regole lua.LValue
		if regole, err = eng.fromJSON(mode.Regole); err == nil {
			r.draft, err = eng.call("draft_new", lua.LNumber(seed), lua.LString(mode.Sim), regole)
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
	teams, vetrine := []string{}, []string{}
	for i, p := range players {
		if p.vetrina != nil {
			vetrine = append(vetrine, string(p.vetrina))
		} else {
			vetrine = append(vetrine, "{}")
		}
		team := int(list.(*lua.LTable).RawGetInt(i + 1).(*lua.LTable).RawGetString("team").(lua.LNumber))
		teams = append(teams, fmt.Sprintf(`{"team":%d}`, team))
		s := &seat{p: p, tok: srv.newToken(), team: team}
		r.seats = append(r.seats, s)
		srv.sessions.Store(s.tok, seatRef{r, i})
		p.room.Store(&seatRef{r, i})
	}
	r.players = []byte("[" + strings.Join(teams, ",") + "]")
	r.vetrine = []byte("[" + strings.Join(vetrine, ",") + "]")
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

// regole: quelle dell'evento della coda (sim/regole.lua), il client le passa
// alla sua copia della partita; null fuori dagli eventi.
func (r *Room) sendStart(slot int, resume bool) {
	regole := r.mode.Regole
	if regole == nil {
		regole = []byte("null")
	}
	r.send(slot, fmt.Appendf(nil, `{"t":"start","seed":%d,"map":%q,"mode":%q,"you":%d,"tok":%q,"resume":%t,"players":%s,"regole":%s,"vetrine":%s}`,
		r.seed, r.mapID, r.mode.Name, slot+1, r.seats[slot].tok, resume, r.players, regole, r.vetrine))
}

// sendDraft manda a un giocatore la scelta delle armi: ventagli, le sue
// scelte (p, p2: quelle degli altri non si vedono), tick rimasti, e chi è
// (you, tok, players: serve anche per tornare se cade adesso).
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
	// le squadre sono già in JSON: le aggiungiamo in coda all'oggetto
	msg = append(append(append(msg[:len(msg)-1], `,"players":`...), r.players...), `,"vetrine":`...)
	msg = append(append(msg, r.vetrine...), '}')
	r.send(slot, msg)
}

// startMatch chiude la scelta delle armi e crea la partita.
func (r *Room) startMatch() error {
	players, err := r.eng.call("draft_finish", r.draft)
	if err != nil {
		return err
	}
	r.draft = nil
	if r.sim, err = r.eng.NewSim(r.seed, "", players, r.mode.Regole); err != nil {
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

// handleDraft: le scelte durante la scelta delle armi. Gli altri non le
// vedono: la conferma torna solo a chi ha scelto.
func (r *Room) handleDraft(m roomMsg) {
	if m.msg.T != "pick" {
		return
	}
	if v, _ := r.eng.call("draft_pick", r.draft, lua.LNumber(m.slot+1), lua.LString(m.msg.W)); v == lua.LTrue {
		r.sendDraft(m.slot)
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
	// in partita il suo robot sparisce subito (durante la scelta non c'è ancora)
	if r.sim != nil {
		if err := r.sim.Remove(slot + 1); err != nil {
			log.Printf("errore remove: %v", err)
		}
	}
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
