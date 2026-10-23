package main

import (
	"encoding/json"
	"fmt"
	"log"
	"sync/atomic"
)

const (
	tickRate      = 60
	snapshotEvery = 2 // 30 stati al secondo, come SNAPSHOT_TICKS in client/sim/game.lua
)

// Messaggio da un client:
//
//	{"t":"hello","v":2,"mode":"1v1"}   primo messaggio: versione del protocollo e modalità
//	{"t":"hello","v":2,"tok":"..."}    oppure: torno nella partita da cui sono caduto
//	{"t":"in","l":true,"r":false,"j":true} | {"t":"jump"} | {"t":"fire","a":1.2,"p":0.7,"w":"missile"}
//
// "j" dice se il salto è ancora tenuto premuto: lasciandolo mentre si sale il salto è corto.
// "w" è l'arma: "missile" (se manca), "sword", "teleport" o un'arma delle casse
// ("grenade", "shards", "punch": la simulazione la usa solo se il robot ha colpi).
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
	in   held
}

// Room è una partita: la simulazione Lua e i suoi giocatori.
type Room struct {
	srv   *Server
	mode  Mode
	seed  int64
	mapID string
	seats []*seat
	in    chan roomMsg
	eng   *Engine
	sim   *Sim
	tick  int
	ended atomic.Bool
}

// newRoom prepara la partita fuori dai worker (creare la simulazione costa
// decine di millisecondi e non deve fermare le altre stanze).
func newRoom(srv *Server, mode Mode, players []*Player, seed int64) (*Room, error) {
	r := &Room{srv: srv, mode: mode, seed: seed, mapID: defaultMap, in: make(chan roomMsg, 64*len(players))}
	eng, err := newEngine()
	if err != nil {
		return nil, err
	}
	sim, err := eng.NewSim(seed, r.mapID)
	if err != nil {
		eng.L.Close()
		return nil, err
	}
	r.eng, r.sim = eng, sim
	for i, p := range players {
		s := &seat{p: p, tok: srv.newToken()}
		r.seats = append(r.seats, s)
		srv.sessions.Store(s.tok, seatRef{r, i})
		p.room.Store(&seatRef{r, i})
		r.sendStart(i, false)
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
	r.send(slot, fmt.Appendf(nil, `{"t":"start","seed":%d,"map":%q,"mode":%q,"you":%d,"tok":%q,"resume":%t}`,
		r.seed, r.mapID, r.mode.Name, slot+1, r.seats[slot].tok, resume))
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
		r.sendStart(m.slot, true)
		r.send(m.slot, r.sim.Sync())
		r.send(m.slot, r.sim.Snapshot())
		r.broadcast(fmt.Appendf(nil, `{"t":"back","robot":%d}`, m.slot+1))
	default:
		if s.p == nil {
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

// checkAway si accorge delle connessioni cadute e conta il tempo di chi è
// disconnesso. Passato il tempo per tornare il giocatore esce davvero; la
// partita continua finché restano almeno due giocatori collegati o in arrivo.
// Restituisce false se la partita va chiusa.
func (r *Room) checkAway() bool {
	present := 0
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
			present++
		}
	}
	return present >= 2
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
