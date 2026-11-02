// MegaBlast server: queues players and runs matches.
//
//	go run ./server              (from the repository root)
//	go run ./server -addr :9000 -node eu1
//	go run ./server -eventi https://…/eventi.json   (event calendar from the panel, events.go)
//	go run ./server -eventi eventi.json             (or from a file)
//
// Architecture and load numbers: docs/server.md.
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
	flag.StringVar(&cfg.EventList, "eventi", cfg.EventList, "calendario degli eventi: l'indirizzo del pannello (https://…/eventi.json) o un file JSON (si rilegge quando cambia)")
	flag.Parse()

	srv := NewServer(cfg)
	hs := &http.Server{Addr: *addr, Handler: srv.Handler()}
	go func() {
		log.Printf("MegaBlast server %s in ascolto su %s (WebSocket su /ws, %d worker)", cfg.Node, *addr, cfg.Workers)
		if err := hs.ListenAndServe(); err != http.ErrServerClosed {
			log.Fatal(err)
		}
	}()

	// Graceful shutdown (SIGTERM from a deploy): no new matches, the load
	// balancer sees /health at 503, running matches finish.
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGINT, syscall.SIGTERM)
	<-stop
	log.Printf("spegnimento: aspetto la fine di %d partite", srv.sched.Rooms())
	srv.Drain()
	deadline := time.Now().Add(10 * time.Minute)
	for srv.sched.Rooms() > 0 && time.Now().Before(deadline) {
		select {
		case <-stop:
			deadline = time.Now() // second signal: exit at once
		case <-time.After(time.Second):
		}
	}
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	hs.Shutdown(ctx)
}
