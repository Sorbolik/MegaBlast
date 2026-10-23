// Server di MegaBlast: mette in coda i giocatori e fa girare le partite.
//
//	go run ./server              (dalla radice del repository)
//	go run ./server -addr :9000 -node eu1
//
// Architettura e numeri di carico: docs/server.md.
package main

import (
	"context"
	"flag"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
)

func main() {
	cfg := DefaultConfig()
	addr := flag.String("addr", ":8080", "indirizzo su cui ascoltare")
	flag.StringVar(&cfg.Node, "node", cfg.Node, "nome del nodo (entra nei gettoni di riconnessione)")
	flag.IntVar(&cfg.Workers, "workers", cfg.Workers, "worker che fanno girare le stanze (di solito uno per core)")
	flag.Parse()

	srv := NewServer(cfg)
	hs := &http.Server{Addr: *addr, Handler: srv.Handler()}
	go func() {
		log.Printf("MegaBlast server %s in ascolto su %s (WebSocket su /ws, %d worker)", cfg.Node, *addr, cfg.Workers)
		if err := hs.ListenAndServe(); err != http.ErrServerClosed {
			log.Fatal(err)
		}
	}()

	// Spegnimento morbido (SIGTERM da un deploy): niente partite nuove, il
	// bilanciatore vede /health a 503, le partite in corso finiscono.
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGINT, syscall.SIGTERM)
	<-stop
	log.Printf("spegnimento: aspetto la fine di %d partite", srv.sched.Rooms())
	srv.Drain()
	deadline := time.Now().Add(10 * time.Minute)
	for srv.sched.Rooms() > 0 && time.Now().Before(deadline) {
		select {
		case <-stop:
			deadline = time.Now() // secondo segnale: si esce subito
		case <-time.After(time.Second):
		}
	}
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	hs.Shutdown(ctx)
}
