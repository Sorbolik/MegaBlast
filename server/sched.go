package main

import (
	"sync/atomic"
	"time"
)

// Scheduler runs rooms on one worker per core. Each worker has a single 60 Hz
// ticker and on every tick advances all its rooms, one after another: with a
// thousand rooms that's 4 wake-ups per tick instead of a thousand, and a room
// always lives on the same worker, so its match needs no lock.
type Scheduler struct {
	workers []*worker
}

type worker struct {
	add   chan *Room
	rooms atomic.Int32 // rooms in this worker
	busy  atomic.Int64 // duration of the last tick in nanoseconds
	late  atomic.Int64 // ticks that went over 16.6 ms (slowed matches)
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

// Add puts the room on the worker with the fewest rooms.
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
			clear(rooms[len(live):]) // finished rooms can be released
			rooms = live
			d := time.Since(start)
			w.busy.Store(int64(d))
			if d > period {
				w.late.Add(1)
			}
		}
	}
}

// Load is the fraction of the tick used by the busiest worker (1 = full).
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
