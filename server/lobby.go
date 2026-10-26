package main

import (
	"log"
	"sync"
	"time"
)

// Mode è una coda di gioco: quanti giocatori servono per una partita, quale
// modo della simulazione usare (config.MODES, che dice le squadre) e se le
// statistiche sono normalizzate (Torneo: albero ed equipaggiamento non contano).
type Mode struct {
	Name      string
	Players   int
	Sim       string
	Normalize bool
}

// I numeri di giocatori devono essere quelli di config.MODES (lo controlla
// TestModesMatchConfig).
var modes = map[string]Mode{
	"1v1":    {"1v1", 2, "1v1", false},
	"2v2":    {"2v2", 4, "2v2", false},
	"ffa":    {"ffa", 4, "ffa", false},
	"torneo": {"torneo", 2, "1v1", true},
}

// Lobby tiene una coda per modalità. Il lock serve solo quando qualcuno entra
// o esce dalla coda, mai durante le partite.
type Lobby struct {
	srv    *Server
	mu     sync.Mutex
	queues map[string][]*Player
}

func NewLobby(srv *Server) *Lobby {
	return &Lobby{srv: srv, queues: map[string][]*Player{}}
}

// Join mette il giocatore in coda; quando la coda ha abbastanza giocatori
// parte una partita.
func (l *Lobby) Join(p *Player, mode Mode) {
	l.mu.Lock()
	q := append(l.queues[mode.Name], p)
	var group []*Player
	if len(q) >= mode.Players {
		group, q = q[:mode.Players:mode.Players], q[mode.Players:]
	}
	l.queues[mode.Name] = q
	l.mu.Unlock()

	if group == nil {
		p.Send([]byte(`{"t":"wait"}`))
		return
	}
	go l.start(mode, group)
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

// Leave toglie dalla coda chi si disconnette mentre aspetta.
func (l *Lobby) Leave(p *Player) {
	l.mu.Lock()
	defer l.mu.Unlock()
	for name, q := range l.queues {
		for i, x := range q {
			if x == p {
				l.queues[name] = append(q[:i:i], q[i+1:]...)
				return
			}
		}
	}
}

// Drain svuota le code: chi aspetta va a cercare partita su un altro server.
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

// Waiting è il numero di giocatori in coda.
func (l *Lobby) Waiting() int {
	l.mu.Lock()
	defer l.mu.Unlock()
	n := 0
	for _, q := range l.queues {
		n += len(q)
	}
	return n
}
