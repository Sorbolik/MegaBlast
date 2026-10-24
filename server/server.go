package main

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net/http"
	"runtime"
	"sync"
	"sync/atomic"
	"time"

	"github.com/coder/websocket"
)

// Versione del protocollo: va cambiata insieme a PROTOCOL in
// client/main/game.gui_script ogni volta che i messaggi cambiano in modo che
// un client vecchio non capirebbe.
const protocolVersion = 2

type Config struct {
	Node           string // nome del nodo, entra nei gettoni: un bilanciatore può mandare chi torna al nodo giusto
	Workers        int
	ReconnectTicks int // quanto si aspetta chi è caduto prima di toglierlo dalla partita
	DraftTicks     int // se > 0 sostituisce config.DRAFT_SECONDS (per le prove)
	PingEvery      time.Duration
}

func DefaultConfig() Config {
	return Config{
		Node:           "n1",
		Workers:        runtime.GOMAXPROCS(0),
		ReconnectTicks: 20 * tickRate,
		PingEvery:      10 * time.Second,
	}
}

// Server è un nodo: accetta i giocatori, li mette in coda e fa girare le stanze.
// Non tiene stato condiviso con altri nodi, così per reggere più giocatori
// basta aggiungere nodi dietro un bilanciatore (vedi docs/server.md).
type Server struct {
	cfg      Config
	sched    *Scheduler
	lobby    *Lobby
	sessions sync.Map // gettone -> seatRef, per chi si riconnette
	online   atomic.Int64
	draining atomic.Bool
}

func NewServer(cfg Config) *Server {
	s := &Server{cfg: cfg, sched: NewScheduler(cfg.Workers)}
	s.lobby = NewLobby(s)
	return s
}

func (s *Server) newToken() string {
	var b [16]byte
	rand.Read(b[:])
	return s.cfg.Node + "." + hex.EncodeToString(b[:])
}

// Drain prepara lo spegnimento: niente partite nuove, quelle in corso finiscono.
func (s *Server) Drain() {
	s.draining.Store(true)
	s.lobby.Drain()
}

func (s *Server) Handler() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("/ws", s.handleWS)
	// per il bilanciatore: 503 quando il nodo si sta spegnendo o è pieno
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		if s.draining.Load() || s.sched.Load() > 0.8 {
			w.WriteHeader(http.StatusServiceUnavailable)
		}
	})
	mux.HandleFunc("/stats", func(w http.ResponseWriter, r *http.Request) {
		json.NewEncoder(w).Encode(map[string]any{
			"node": s.cfg.Node, "online": s.online.Load(), "waiting": s.lobby.Waiting(),
			"rooms": s.sched.Rooms(), "load": s.sched.Load(), "late_ticks": s.sched.Late(),
			"draining": s.draining.Load(),
		})
	})
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("MegaBlast server\n"))
	})
	return mux
}

// Player è una connessione di un giocatore.
type Player struct {
	out       chan []byte // nil: chiudi dopo aver scritto quello che c'è prima
	ctx       context.Context
	cancel    context.CancelFunc
	room      atomic.Pointer[seatRef] // la partita in cui gioca, nil se non gioca
	closeOnce sync.Once
}

// Send non blocca mai la partita. Se il client non smaltisce i messaggi lo
// disconnettiamo: tornando riceve lo stato completo, mentre perdere un
// messaggio (uno scavo nel terreno) lo lascerebbe con una mappa sbagliata.
func (p *Player) Send(msg []byte) {
	select {
	case p.out <- msg:
	default:
		p.cancel()
	}
}

// Close chiude la connessione dopo aver mandato i messaggi già in coda.
func (p *Player) Close() {
	p.closeOnce.Do(func() {
		select {
		case p.out <- nil:
		default:
			p.cancel()
		}
	})
}

func (p *Player) Closed() bool { return p.ctx.Err() != nil }

func (s *Server) handleWS(w http.ResponseWriter, r *http.Request) {
	conn, err := websocket.Accept(w, r, &websocket.AcceptOptions{InsecureSkipVerify: true})
	if err != nil {
		return
	}
	defer conn.CloseNow()
	conn.SetReadLimit(1024) // i messaggi dei client sono di poche decine di byte
	s.online.Add(1)
	defer s.online.Add(-1)

	ctx, cancel := context.WithCancel(r.Context())
	defer cancel()
	p := &Player{out: make(chan []byte, 256), ctx: ctx, cancel: cancel}
	go s.writeLoop(conn, p)
	defer s.lobby.Leave(p)

	hello := true
	for {
		_, data, err := conn.Read(ctx)
		if err != nil {
			return
		}
		msg, err := parseClientMsg(data)
		if err != nil {
			continue
		}
		if hello {
			if !s.hello(p, msg) {
				p.Close()
				<-ctx.Done()
				return
			}
			hello = false
			continue
		}
		if ref := p.room.Load(); ref != nil {
			ref.room.Post(roomMsg{slot: ref.slot, msg: msg})
		}
	}
}

// hello controlla la versione e mette il giocatore in coda o nella sua partita.
func (s *Server) hello(p *Player, m clientMsg) bool {
	if m.T != "hello" || m.V != protocolVersion {
		p.Send(fmt.Appendf(nil, `{"t":"error","e":"version","v":%d}`, protocolVersion))
		return false
	}
	if m.Tok != "" {
		v, ok := s.sessions.Load(m.Tok)
		if !ok {
			p.Send([]byte(`{"t":"error","e":"expired"}`))
			return false
		}
		ref := v.(seatRef)
		p.room.Store(&ref)
		ref.room.Post(roomMsg{slot: ref.slot, attach: p})
		if ref.room.ended.Load() {
			// la partita si è chiusa proprio adesso: se close non ha visto il
			// nostro attach, rispondiamo noi (Close vale una volta sola)
			p.Send([]byte(`{"t":"error","e":"expired"}`))
			return false
		}
		return true
	}
	if s.draining.Load() {
		p.Send([]byte(`{"t":"error","e":"draining"}`))
		return false
	}
	mode, ok := modes[m.Mode]
	if !ok {
		mode = modes["1v1"]
	}
	s.lobby.Join(p, mode)
	return true
}

// writeLoop manda i messaggi in ordine e tiene viva la connessione con un ping:
// sui telefoni una connessione può morire senza avvisare.
func (s *Server) writeLoop(conn *websocket.Conn, p *Player) {
	ping := time.NewTicker(s.cfg.PingEvery)
	defer ping.Stop()
	defer p.cancel()
	for {
		select {
		case msg := <-p.out:
			if msg == nil {
				conn.Close(websocket.StatusNormalClosure, "")
				return
			}
			if conn.Write(p.ctx, websocket.MessageText, msg) != nil {
				return
			}
		case <-ping.C:
			ctx, cancel := context.WithTimeout(p.ctx, 5*time.Second)
			err := conn.Ping(ctx)
			cancel()
			if err != nil {
				return
			}
		case <-p.ctx.Done():
			return
		}
	}
}
