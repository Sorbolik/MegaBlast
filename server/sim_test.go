package main

import (
	"encoding/json"
	"testing"
)

// Sim is a match in a LuaJIT process driven one command at a time, for the
// tests (online the rooms send one batch per tick, room.go).
type Sim struct {
	p  *Proc // nil: the utility process
	id int64
}

// Input of the player on turn for one tick.
type Input struct {
	Left, Right, Jump bool
	Hold              bool // jump is still held down
	Fire              bool
	Angle, Power      float64
	Weapon            string
}

func (s *Sim) call(b *Batch) (Result, error) {
	if s.p == nil {
		return callUtil(b)
	}
	return callOne(s.p, b)
}

func (s *Sim) cmd(f string) *Batch {
	b := &Batch{}
	b.Cmd(f, s.id, nil)
	return b
}

// newTestSim creates a match on the utility process; mapID "" lets the seed
// pick it (maps.pick).
func newTestSim(t testing.TB, seed int64, mapID string) *Sim {
	return newTestSimOn(t, nil, seed, mapID)
}

func newTestSimOn(t testing.TB, p *Proc, seed int64, mapID string) *Sim {
	s := &Sim{p: p, id: roomIDs.Add(1)}
	b := s.cmd("new").Int("seed", seed)
	if mapID != "" {
		b.Str("map", mapID)
	}
	b.End()
	if _, err := s.call(b); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		b := s.cmd("free")
		b.End()
		s.call(b)
	})
	return s
}

// testProc is a process of its own for the test.
func testProc(t testing.TB) *Proc {
	p, err := startProc()
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(p.Close)
	return p
}

func (s *Sim) state() (cur int, over bool, mapID string) {
	b := s.cmd("current")
	b.End()
	res, _ := s.call(b)
	var v struct {
		Cur  int    `json:"cur"`
		Over bool   `json:"over"`
		Map  string `json:"map"`
	}
	json.Unmarshal(res.Head, &v)
	return v.Cur, v.Over, v.Map
}

func (s *Sim) Map() string  { _, _, m := s.state(); return m }
func (s *Sim) Current() int { c, _, _ := s.state(); return c }
func (s *Sim) Over() bool   { _, o, _ := s.state(); return o }

func (s *Sim) Step(in Input) error {
	b := s.cmd("step").Bool("l", in.Left).Bool("rt", in.Right).Bool("j", in.Jump).Bool("h", in.Hold)
	if in.Fire {
		b.Num("a", in.Angle).Num("p", in.Power).Str("w", in.Weapon)
	}
	b.End()
	_, err := s.call(b)
	return err
}

func (s *Sim) Remove(i int) error {
	b := s.cmd("remove").Int("i", int64(i))
	b.End()
	_, err := s.call(b)
	return err
}

// Snapshot: the state; aiming says whether the player on turn is aiming, at angle.
func (s *Sim) Snapshot(aiming bool, angle float64) []byte {
	b := s.cmd("snapshot")
	if aiming {
		b.Num("m", angle)
	}
	b.End()
	res, _ := s.call(b)
	if len(res.Raw) == 0 {
		return nil
	}
	return res.Raw[0]
}

// Events returns the events of the last tick, one JSON per element.
func (s *Sim) Events() [][]byte {
	b := s.cmd("events")
	b.End()
	res, _ := s.call(b)
	return res.Raw
}

// luaEval runs Lua (with N, server/net.lua) on the utility process and
// decodes what it returns into v (if not nil).
func luaEval(t testing.TB, code string, v any) {
	t.Helper()
	b := &Batch{}
	b.Cmd("eval", 0, nil).Str("code", code).End()
	res, err := callUtil(b)
	if err != nil {
		t.Fatal(err)
	}
	if v != nil {
		var w struct {
			V json.RawMessage `json:"v"`
		}
		if err := json.Unmarshal(res.Head, &w); err != nil {
			t.Fatal(err)
		}
		if err := json.Unmarshal(w.V, v); err != nil {
			t.Fatalf("%v: %s", err, w.V)
		}
	}
}

// The answer headers are read with or without \r (luajit on Windows writes
// "\r\n").
func TestAnswerHeaderLines(t *testing.T) {
	for line, want := range map[string][3]int{
		"0 11\n": {0, 11, 1}, "0 11\r\n": {0, 11, 1}, "840\r\n": {840, 0, 1}, "840\n": {840, 0, 1},
		"x\n": {0, 0, 0}, "\r\n": {0, 0, 0},
	} {
		a, b, ok := twoInts([]byte(line))
		if a != want[0] || b != want[1] || ok != (want[2] == 1) {
			t.Fatalf("%q: %d %d %v", line, a, b, ok)
		}
	}
}
