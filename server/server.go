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

// Protocol version: change it together with PROTOCOL in
// client/main/game.gui_script every time the messages change in a way an old
// client wouldn't understand.
const protocolVersion = 8

type Config struct {
	Node           string // node name, goes into tokens: a load balancer can send whoever comes back to the right node
	Workers        int
	ReconnectTicks int // how long to wait for someone who dropped before removing them from the match
	DraftTicks     int // if > 0 replaces config.DRAFT_SECONDS (for tests)
	PingEvery      time.Duration
	EventList      string        // event calendar (events.go): panel address or file, empty = no events
	BotAfter       time.Duration // bots fill a normal queue this long after the first joined (0 = never)
}

func DefaultConfig() Config {
	return Config{
		Node:           "n1",
		Workers:        runtime.GOMAXPROCS(0),
		ReconnectTicks: 20 * tickRate,
		PingEvery:      10 * time.Second,
		BotAfter:       25 * time.Second,
	}
}

// Server is a node: it accepts players, queues them and runs rooms.
// It shares no state with other nodes, so to handle more players you just add
// nodes behind a load balancer (see docs/server.md).
type Server struct {
	cfg      Config
	sched    *Scheduler
	botSched *Scheduler // rooms with bots (lobby.go): their own workers
	lobby    *Lobby
	events   *Calendar
	sessions sync.Map // token -> seatRef, for whoever reconnects
	online   atomic.Int64
	draining atomic.Bool
}

func NewServer(cfg Config) *Server {
	s := &Server{cfg: cfg, sched: NewScheduler(cfg.Workers), botSched: NewScheduler(cfg.Workers), events: NewCalendar(cfg.EventList)}
	s.lobby = NewLobby(s)
	return s
}

func (s *Server) newToken() string {
	var b [16]byte
	rand.Read(b[:])
	return s.cfg.Node + "." + hex.EncodeToString(b[:])
}

// Drain prepares the shutdown: no new matches, running ones finish.
func (s *Server) Drain() {
	s.draining.Store(true)
	s.lobby.Drain()
}

func (s *Server) Handler() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("/ws", s.handleWS)
	// for the load balancer: 503 when the node is shutting down or full
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		if s.draining.Load() || max(s.sched.Load(), s.botSched.Load()) > 0.8 {
			w.WriteHeader(http.StatusServiceUnavailable)
		}
	})
	mux.HandleFunc("/stats", func(w http.ResponseWriter, r *http.Request) {
		json.NewEncoder(w).Encode(map[string]any{
			"node": s.cfg.Node, "online": s.online.Load(), "waiting": s.lobby.Waiting(),
			"rooms": s.sched.Rooms() + s.botSched.Rooms(), "bot_rooms": s.botSched.Rooms(),
			"load": max(s.sched.Load(), s.botSched.Load()), "late_ticks": s.sched.Late(), "bot_late_ticks": s.botSched.Late(),
			"draining": s.draining.Load(),
		})
	})
	// the calendar for the game's board: running and in the next few days
	mux.HandleFunc("/eventi", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Header().Set("Access-Control-Allow-Origin", "*") // the HTML5 build asks for it from another site
		// always fresh: the game asks for it on entry and the home must be right
		w.Header().Set("Cache-Control", "no-store")
		json.NewEncoder(w).Encode(map[string]any{"ora": s.events.now().Unix(), "eventi": s.events.Occurrences()})
	})
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("MegaBlast server\n"))
	})
	return mux
}

// Player is one player's connection.
type Player struct {
	out       chan []byte // nil: close after writing what's ahead of it
	ctx       context.Context
	cancel    context.CancelFunc
	room      atomic.Pointer[seatRef] // the match they're playing, nil if not playing
	closeOnce sync.Once
	showcase  []byte    // the card as JSON, checked (showcaseJSON): level and badges
	joined    time.Time // when they entered the queue (bots after BotAfter, lobby.go)
	private   *Private  // the private room they are in before the match (private.go; under the lobby's lock)
}

// Send never blocks the match. If the client doesn't drain its messages we
// disconnect it: coming back it gets the full state, while losing one message
// (a dig in the terrain) would leave it with a wrong map.
func (p *Player) Send(msg []byte) {
	select {
	case p.out <- msg:
	default:
		p.cancel()
	}
}

// Close closes the connection after sending the messages already queued.
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
	conn.SetReadLimit(1024) // client messages are a few tens of bytes
	s.online.Add(1)
	defer s.online.Add(-1)

	ctx, cancel := context.WithCancel(r.Context())
	defer cancel()
	p := &Player{out: make(chan []byte, 256), ctx: ctx, cancel: cancel}
	go s.writeLoop(conn, p)
	defer s.lobby.Leave(p)

	hello := true
	var limit rateLimit
	for {
		_, data, err := conn.Read(ctx)
		if err != nil {
			return
		}
		if !limit.allow(time.Now()) {
			continue
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
		} else if msg.T != "leave" {
			// in a private room: seats, bots, mode, start (private.go)
			s.lobby.PrivateMsg(p, msg)
		} else {
			// out of the queue (ESCI DALLA CODA, another queue): at once, not when
			// the client closes, so a ghost can't hold first place (the bots'
			// clock) or take a seat in the next match
			s.lobby.Leave(p)
			p.Close()
		}
	}
}

// rateLimit: at most msgRate messages a second per connection, with bursts
// up to msgBurst; the rest is dropped before it's even read. A client sends a
// few a second (keys when they change, the aim at most 10, the shot), so only
// a broken or hostile client hits it: it can't fill its room's queue and make
// the others' keys get lost.
type rateLimit struct {
	tokens float64
	last   time.Time
}

const (
	msgRate  = 30
	msgBurst = 60
)

func (l *rateLimit) allow(now time.Time) bool {
	if l.last.IsZero() {
		l.tokens = msgBurst
	} else {
		l.tokens = min(msgBurst, l.tokens+now.Sub(l.last).Seconds()*msgRate)
	}
	l.last = now
	if l.tokens < 1 {
		return false
	}
	l.tokens--
	return true
}

// hello checks the version and puts the player in the queue or in their match.
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
			// the match closed right now: if close didn't see our attach, we answer
			// ourselves (Close only works once)
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
	if !ok && m.Mode != "" {
		// an event's queue (GET /eventi): if it ended meanwhile, we say so
		if mode, ok = s.events.Queue(m.Mode); !ok {
			p.Send([]byte(`{"t":"error","e":"evento"}`))
			return false
		}
	}
	if !ok {
		mode = modes["2v2"]
	}
	p.showcase = showcaseJSON(m.Showcase)
	// a private room (private.go): "nuova" opens one, a code joins it
	if m.Private == "nuova" {
		s.lobby.NewPrivate(p)
		return true
	} else if m.Private != "" {
		return s.lobby.JoinPrivate(p, m.Private)
	}
	s.lobby.Join(p, mode)
	return true
}

// writeLoop sends messages in order and keeps the connection alive with a
// ping: on phones a connection can die without notice.
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
