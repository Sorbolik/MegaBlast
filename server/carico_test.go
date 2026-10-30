package main

import (
	"context"
	"flag"
	"fmt"
	"math/rand"
	"net/http/httptest"
	"os"
	"runtime"
	"runtime/pprof"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/coder/websocket"
)

// Prova di carico: N partite in contemporanea con giocatori finti collegati
// via WebSocket, che camminano, saltano e sparano a caso.
//
//	go test ./server/ -run Carico -v -carico 500 -durata 20s [-modo ffa]
//
// I client girano nello stesso processo e rubano CPU al server: i numeri
// sono quindi peggiori di quelli di un server da solo.
var (
	caricoStanze = flag.Int("carico", 0, "partite contemporanee della prova di carico (0 = salta)")
	caricoDurata = flag.Duration("durata", 15*time.Second, "durata della prova di carico")
	caricoModo   = flag.String("modo", "1v1", "modalità delle partite della prova di carico")
)

func TestCarico(t *testing.T) {
	if *caricoStanze == 0 {
		t.Skip("prova di carico: -carico N")
	}
	cfg := DefaultConfig()
	cfg.DraftTicks = 1 // la scelta dell'arma non conta per il carico
	srv := NewServer(cfg)
	hs := httptest.NewServer(srv.Handler())
	defer hs.Close()
	url := "ws" + strings.TrimPrefix(hs.URL, "http") + "/ws"
	ctx, cancel := context.WithTimeout(context.Background(), *caricoDurata+2*time.Minute)
	defer cancel()

	var before runtime.MemStats
	runtime.GC()
	runtime.ReadMemStats(&before)

	start := time.Now()
	var wg sync.WaitGroup
	stop := make(chan struct{})
	for i := 0; i < *caricoStanze*modes[*caricoModo].Players; i++ {
		wg.Add(1)
		go func(seed int64) {
			defer wg.Done()
			bot(ctx, url, seed, stop)
		}(int64(i))
		if i%50 == 49 {
			time.Sleep(20 * time.Millisecond) // i giocatori arrivano un po' alla volta
		}
	}
	for srv.sched.Rooms() < *caricoStanze && time.Since(start) < time.Minute {
		time.Sleep(50 * time.Millisecond)
	}
	t.Logf("%d stanze pronte in %v", srv.sched.Rooms(), time.Since(start).Round(time.Millisecond))

	if f, err := os.Create(os.Getenv("CARICO_PROF")); err == nil {
		pprof.StartCPUProfile(f)
		defer pprof.StopCPUProfile()
	}
	// misura: il carico del worker più pieno, campionato ogni 100 ms
	lateBefore := srv.sched.Late()
	var sum, top float64
	n := 0
	end := time.Now().Add(*caricoDurata)
	for time.Now().Before(end) {
		time.Sleep(100 * time.Millisecond)
		l := srv.sched.Load()
		sum += l
		top = max(top, l)
		n++
	}
	var after runtime.MemStats
	runtime.ReadMemStats(&after)
	rooms := srv.sched.Rooms()
	ticks := float64(caricoDurata.Seconds()) * tickRate
	t.Logf("stanze %d, worker %d, carico medio %.0f%% (picco %.0f%%), tick in ritardo %.1f%%, memoria %d MB (%.1f MB a stanza)",
		rooms, srv.cfg.Workers, sum/float64(n)*100, top*100,
		float64(srv.sched.Late()-lateBefore)/(ticks*float64(srv.cfg.Workers))*100,
		(after.HeapAlloc-before.HeapAlloc)>>20, float64(after.HeapAlloc-before.HeapAlloc)/float64(max(rooms, 1))/(1<<20))
	if rooms > 0 {
		t.Logf("tempo di CPU per stanza e tick: %.1f µs (un core regge circa %d stanze)",
			sum/float64(n)*float64(time.Second/tickRate)/float64(rooms)*float64(srv.cfg.Workers)/1000,
			int(float64(rooms)/(sum/float64(n)*float64(srv.cfg.Workers))))
	}
	close(stop)
	wg.Wait()
}

// bot gioca a caso finché stop non si chiude.
func bot(ctx context.Context, url string, seed int64, stop chan struct{}) {
	conn, _, err := websocket.Dial(ctx, url, nil)
	if err != nil {
		return
	}
	defer conn.CloseNow()
	conn.Write(ctx, websocket.MessageText, fmt.Appendf(nil, `{"t":"hello","v":3,"mode":%q}`, *caricoModo))
	go func() {
		for {
			if _, _, err := conn.Read(ctx); err != nil {
				return
			}
		}
	}()
	rng := rand.New(rand.NewSource(seed))
	tick := time.NewTicker(250 * time.Millisecond)
	defer tick.Stop()
	for {
		select {
		case <-stop:
			return
		case <-ctx.Done():
			return
		case <-tick.C:
		}
		var msg string
		switch r := rng.Intn(12); {
		case r == 0:
			msg = fmt.Sprintf(`{"t":"fire","a":%.2f,"p":%.2f}`, rng.Float64()*3.14, 0.3+rng.Float64()*0.7)
		case r == 1:
			msg = `{"t":"jump"}`
		default:
			msg = fmt.Sprintf(`{"t":"in","l":%t,"r":%t}`, r%3 == 0, r%3 == 1)
		}
		if conn.Write(ctx, websocket.MessageText, []byte(msg)) != nil {
			return
		}
	}
}
