// Server di MegaBlast: abbina i giocatori a coppie e fa girare le partite.
//
//	go run ./server              (dalla radice del repository)
//	go run ./server -addr :9000
package main

import (
	"context"
	"flag"
	"log"
	"net/http"
	"sync"
	"time"

	"github.com/coder/websocket"
)

// Player è un client connesso.
type Player struct {
	conn  *websocket.Conn
	out   chan string
	match *Match
	index int
}

func (p *Player) Send(msg string) {
	select {
	case p.out <- msg:
	default: // client troppo lento: scartiamo il messaggio invece di bloccare la partita
	}
}

// Lobby tiene al massimo un giocatore in attesa di avversario.
type Lobby struct {
	mu      sync.Mutex
	waiting *Player
	ready   map[*Player]chan struct{}
}

func (l *Lobby) Join(p *Player) <-chan struct{} {
	l.mu.Lock()
	defer l.mu.Unlock()
	ch := make(chan struct{})
	if l.waiting == nil {
		l.waiting = p
		l.ready[p] = ch
		return ch
	}
	other := l.waiting
	l.waiting = nil
	m := NewMatch(other, p, time.Now().UnixNano()%2147483646+1)
	close(l.ready[other])
	delete(l.ready, other)
	close(ch)
	go m.Run()
	return ch
}

func (l *Lobby) Leave(p *Player) {
	l.mu.Lock()
	defer l.mu.Unlock()
	if l.waiting == p {
		l.waiting = nil
		delete(l.ready, p)
	}
}

func (l *Lobby) handle(w http.ResponseWriter, r *http.Request) {
	conn, err := websocket.Accept(w, r, &websocket.AcceptOptions{InsecureSkipVerify: true})
	if err != nil {
		return
	}
	defer conn.CloseNow()
	ctx, cancel := context.WithCancel(r.Context())
	defer cancel()

	p := &Player{conn: conn, out: make(chan string, 256)}
	go func() {
		for {
			select {
			case msg := <-p.out:
				if conn.Write(ctx, websocket.MessageText, []byte(msg)) != nil {
					cancel()
					return
				}
			case <-ctx.Done():
				return
			}
		}
	}()

	p.Send(`{"t":"wait"}`)
	ready := l.Join(p)
	defer l.Leave(p)

	// Leggiamo i messaggi in una goroutine, così ci accorgiamo anche
	// di una disconnessione mentre il giocatore è in attesa.
	msgs := make(chan []byte)
	go func() {
		defer cancel()
		for {
			_, data, err := conn.Read(ctx)
			if err != nil {
				return
			}
			select {
			case msgs <- data:
			case <-ctx.Done():
				return
			}
		}
	}()

	select {
	case <-ready:
	case <-ctx.Done():
		return
	}

	m := p.match
	defer func() {
		select {
		case m.in <- playerMsg{from: p.index, left: true}:
		default:
		}
	}()
	for {
		select {
		case data := <-msgs:
			msg, err := parseClientMsg(data)
			if err != nil {
				continue
			}
			select {
			case m.in <- playerMsg{from: p.index, msg: msg}:
			default:
			}
		case <-ctx.Done():
			return
		}
	}
}

func main() {
	addr := flag.String("addr", ":8080", "indirizzo su cui ascoltare")
	flag.Parse()

	lobby := &Lobby{ready: map[*Player]chan struct{}{}}
	log.Printf("MegaBlast server in ascolto su %s (WebSocket su /ws)", *addr)
	log.Fatal(http.ListenAndServe(*addr, httpHandler(lobby)))
}

func httpHandler(lobby *Lobby) http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("/ws", lobby.handle)
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("MegaBlast server\n"))
	})
	return mux
}
