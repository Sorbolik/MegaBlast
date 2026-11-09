package main

import (
	"log"
	"sync/atomic"
	"time"
)

// Scheduler runs rooms on one worker per core. Each worker has a single 60 Hz
// ticker and on every tick advances all its rooms, one after another: with a
// thousand rooms that's 4 wake-ups per tick instead of a thousand, and a room
// always lives on the same worker, so its match needs no lock. Each worker has
// its LuaJIT process (proc.go) with the simulations of its rooms: one round
// trip per tick for all of them.
type Scheduler struct {
	workers []*worker
}

type worker struct {
	add   chan *Room
	rooms atomic.Int32 // rooms in this worker
	// average duration of a tick in nanoseconds, over about half a second: a
	// single slow tick (a bot thinking) doesn't make /health answer 503
	avg  atomic.Int64
	late atomic.Int64 // ticks that went over 16.6 ms (slowed matches)
}

// roomCost is what a new room is assumed to cost until the worker measures it
// (a 1 v 1 between people, docs/server.md)
const roomCost = 250 * time.Microsecond

func NewScheduler(n int) *Scheduler {
	s := &Scheduler{}
	for i := 0; i < n; i++ {
		w := &worker{add: make(chan *Room, 64)}
		s.workers = append(s.workers, w)
		go w.run()
	}
	return s
}

// Add puts the room on the least loaded worker: by measured time, not by
// number of rooms (a room with three bots costs as much as four without). The
// room's cost is counted at once, so rooms created together spread out.
func (s *Scheduler) Add(r *Room) {
	best := s.workers[0]
	for _, w := range s.workers[1:] {
		if w.avg.Load() < best.avg.Load() {
			best = w
		}
	}
	best.avg.Add(int64(roomCost))
	best.rooms.Add(1)
	best.add <- r
}

func (w *worker) run() {
	period := time.Second / tickRate
	ticker := time.NewTicker(period)
	defer ticker.Stop()
	var rooms []*Room
	var proc *Proc
	b, next := &Batch{}, &Batch{}
	for {
		select {
		case r := <-w.add:
			rooms = append(rooms, r)
		case <-ticker.C:
			start := time.Now()
			// the rooms write their commands after those left by the last
			// tick's answers (rooms that closed), then one round trip
			for _, r := range rooms {
				r.Tick(b)
			}
			if b.Len() > 0 {
				err := error(nil)
				if proc == nil {
					proc, err = startProc()
				}
				if err == nil {
					err = proc.Run(b, next)
				}
				if err != nil {
					// the process is gone with all its matches: they close
					// with an error, a new process for the next rooms
					log.Printf("simulazione: %v", err)
					for _, r := range rooms {
						if !r.ended.Load() {
							r.broadcast([]byte(`{"t":"error"}`))
							r.close(nil)
						}
					}
					proc = nil
					next.Reset()
				}
			}
			b.Reset()
			b, next = next, b
			live := rooms[:0]
			for _, r := range rooms {
				if r.ended.Load() {
					w.rooms.Add(-1)
				} else {
					live = append(live, r)
				}
			}
			clear(rooms[len(live):]) // finished rooms can be released
			rooms = live
			d := time.Since(start)
			// moving average over 32 ticks (Add may have raised it meanwhile)
			for {
				old := w.avg.Load()
				if w.avg.CompareAndSwap(old, old+(int64(d)-old)/32) {
					break
				}
			}
			if d > period {
				w.late.Add(1)
			}
		}
	}
}

// Load is the fraction of the tick used by the busiest worker, on average
// over the last half second (1 = full).
func (s *Scheduler) Load() float64 {
	var top int64
	for _, w := range s.workers {
		top = max(top, w.avg.Load())
	}
	return float64(top) / float64(time.Second/tickRate)
}

// Mean is the fraction of the tick used by the workers on average: the CPU
// the rooms take (Load says how close the busiest one is to being late).
func (s *Scheduler) Mean() float64 {
	var sum int64
	for _, w := range s.workers {
		sum += w.avg.Load()
	}
	return float64(sum) / float64(len(s.workers)) / float64(time.Second/tickRate)
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
