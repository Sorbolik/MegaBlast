package main

import (
	"sync/atomic"
	"time"
)

// Scheduler fa girare le stanze su un worker per core. Ogni worker ha un solo
// ticker a 60 Hz e a ogni tick fa avanzare tutte le sue stanze, una dopo
// l'altra: con mille stanze sono 4 risvegli per tick invece di mille, e una
// stanza vive sempre sullo stesso worker, quindi la sua partita non ha lock.
type Scheduler struct {
	workers []*worker
}

type worker struct {
	add   chan *Room
	rooms atomic.Int32 // stanze in questo worker
	busy  atomic.Int64 // durata dell'ultimo tick in nanosecondi
	late  atomic.Int64 // tick che hanno sforato i 16,6 ms (partite rallentate)
}

func NewScheduler(n int) *Scheduler {
	s := &Scheduler{}
	for i := 0; i < n; i++ {
		w := &worker{add: make(chan *Room, 64)}
		s.workers = append(s.workers, w)
		go w.run()
	}
	return s
}

// Add mette la stanza sul worker con meno stanze.
func (s *Scheduler) Add(r *Room) {
	best := s.workers[0]
	for _, w := range s.workers[1:] {
		if w.rooms.Load() < best.rooms.Load() {
			best = w
		}
	}
	best.rooms.Add(1)
	best.add <- r
}

func (w *worker) run() {
	period := time.Second / tickRate
	ticker := time.NewTicker(period)
	defer ticker.Stop()
	var rooms []*Room
	for {
		select {
		case r := <-w.add:
			rooms = append(rooms, r)
		case <-ticker.C:
			start := time.Now()
			live := rooms[:0]
			for _, r := range rooms {
				if r.Tick() {
					live = append(live, r)
				} else {
					w.rooms.Add(-1)
				}
			}
			clear(rooms[len(live):]) // le stanze finite si possono liberare
			rooms = live
			d := time.Since(start)
			w.busy.Store(int64(d))
			if d > period {
				w.late.Add(1)
			}
		}
	}
}

// Load è la frazione del tick usata dal worker più carico (1 = pieno).
func (s *Scheduler) Load() float64 {
	var top int64
	for _, w := range s.workers {
		top = max(top, w.busy.Load())
	}
	return float64(top) / float64(time.Second/tickRate)
}

func (s *Scheduler) Rooms() int {
	n := 0
	for _, w := range s.workers {
		n += int(w.rooms.Load())
	}
	return n
}

func (s *Scheduler) Late() int64 {
	var n int64
	for _, w := range s.workers {
		n += w.late.Load()
	}
	return n
}
