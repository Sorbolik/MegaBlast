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

// Load test: N simultaneous matches with fake players connected over
// WebSocket, who walk, jump and shoot at random.
//
//	go test ./server/ -run Load -v -carico 500 -durata 20s [-modo ffa]
//
// The clients run in the same process and steal CPU from the server: so the
// numbers are worse than those of a server on its own.
var (
	loadRooms    = flag.Int("carico", 0, "simultaneous matches of the load test (0 = skip)")
	loadDuration = flag.Duration("durata", 15*time.Second, "duration of the load test")
	loadMode     = flag.String("modo", "1v1", "mode of the load test matches")
)

func TestLoad(t *testing.T) {
	if *loadRooms == 0 {
		t.Skip("load test: -carico N")
	}
	cfg := DefaultConfig()
	cfg.DraftTicks = 1 // the weapon draft doesn't matter for load
	srv := NewServer(cfg)
	hs := httptest.NewServer(srv.Handler())
	defer hs.Close()
	url := "ws" + strings.TrimPrefix(hs.URL, "http") + "/ws"
	ctx, cancel := context.WithTimeout(context.Background(), *loadDuration+2*time.Minute)
	defer cancel()

	var before runtime.MemStats
	runtime.GC()
	runtime.ReadMemStats(&before)

	start := time.Now()
	var wg sync.WaitGroup
	stop := make(chan struct{})
	for i := 0; i < *loadRooms*modes[*loadMode].Players; i++ {
		wg.Add(1)
		go func(seed int64) {
			defer wg.Done()
			bot(ctx, url, seed, stop)
		}(int64(i))
		if i%50 == 49 {
			time.Sleep(20 * time.Millisecond) // players arrive a few at a time
		}
	}
	for srv.sched.Rooms() < *loadRooms && time.Since(start) < time.Minute {
		time.Sleep(50 * time.Millisecond)
	}
	t.Logf("%d rooms ready in %v", srv.sched.Rooms(), time.Since(start).Round(time.Millisecond))

	if f, err := os.Create(os.Getenv("CARICO_PROF")); err == nil {
		pprof.StartCPUProfile(f)
		defer pprof.StopCPUProfile()
	}
	// measure: the load of the busiest worker, sampled every 100 ms
	lateBefore := srv.sched.Late()
	var sum, top float64
	n := 0
	end := time.Now().Add(*loadDuration)
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
	ticks := float64(loadDuration.Seconds()) * tickRate
	t.Logf("rooms %d, workers %d, average load %.0f%% (peak %.0f%%), late ticks %.1f%%, memory %d MB (%.1f MB per room)",
		rooms, srv.cfg.Workers, sum/float64(n)*100, top*100,
		float64(srv.sched.Late()-lateBefore)/(ticks*float64(srv.cfg.Workers))*100,
		(after.HeapAlloc-before.HeapAlloc)>>20, float64(after.HeapAlloc-before.HeapAlloc)/float64(max(rooms, 1))/(1<<20))
	if rooms > 0 {
		t.Logf("CPU time per room and tick: %.1f µs (one core handles about %d rooms)",
			sum/float64(n)*float64(time.Second/tickRate)/float64(rooms)*float64(srv.cfg.Workers)/1000,
			int(float64(rooms)/(sum/float64(n)*float64(srv.cfg.Workers))))
	}
	close(stop)
	wg.Wait()
}

// bot plays at random until stop is closed.
func bot(ctx context.Context, url string, seed int64, stop chan struct{}) {
	conn, _, err := websocket.Dial(ctx, url, nil)
	if err != nil {
		return
	}
	defer conn.CloseNow()
	conn.Write(ctx, websocket.MessageText, fmt.Appendf(nil, `{"t":"hello","v":8,"mode":%q}`, *loadMode))
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
