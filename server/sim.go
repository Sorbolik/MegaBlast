package main

import (
	_ "embed"
	"fmt"
	"path"
	"strings"
	"sync"

	megablast "github.com/Sorbolik/MegaBlast"
	lua "github.com/yuin/gopher-lua"
	"github.com/yuin/gopher-lua/parse"
)

//go:embed net.lua
var netLua string

// The Lua code is compiled only once for the whole process: compiled protos
// don't change and gopher-lua allows sharing them between states.
var (
	compileOnce sync.Once
	simProtos   map[string]*lua.FunctionProto // "sim.game" -> proto
	netProto    *lua.FunctionProto
	compileErr  error
)

func compileLua(name, src string) (*lua.FunctionProto, error) {
	chunk, err := parse.Parse(strings.NewReader(src), name)
	if err != nil {
		return nil, err
	}
	return lua.Compile(chunk, name)
}

func compileAll() {
	simProtos = map[string]*lua.FunctionProto{}
	entries, err := megablast.SimFS.ReadDir("client/sim")
	if err != nil {
		compileErr = err
		return
	}
	// all the modules of client/sim: whoever adds one doesn't have to touch the server
	for _, e := range entries {
		file := "client/sim/" + e.Name()
		src, err := megablast.SimFS.ReadFile(file)
		if err != nil {
			compileErr = err
			return
		}
		p, err := compileLua(file, string(src))
		if err != nil {
			compileErr = err
			return
		}
		simProtos["sim."+strings.TrimSuffix(e.Name(), path.Ext(e.Name()))] = p
	}
	netProto, compileErr = compileLua("server/net.lua", netLua)
}

// Engine is a Lua state with the simulation loaded: one per room. With the
// code already compiled and the map already drawn (terrain.go) creating one
// takes less than a millisecond, so there's no need to keep them around.
type Engine struct {
	L   *lua.LState
	net *lua.LTable
}

func newEngine() (*Engine, error) { return buildEngine(installGoTerrain) }

// buildEngine prepares the state; setup runs after the modules are loaded and
// before net.lua (tests use it to compare the pure Lua terrain).
func buildEngine(setup func(*lua.LState)) (*Engine, error) {
	compileOnce.Do(compileAll)
	if compileErr != nil {
		return nil, compileErr
	}
	L := lua.NewState()
	for name, proto := range simProtos {
		proto := proto
		L.PreloadModule(name, func(L *lua.LState) int {
			L.Push(L.NewFunctionFromProto(proto))
			L.Call(0, 1)
			return 1
		})
	}
	if err := L.CallByParam(lua.P{Fn: L.NewFunction(func(L *lua.LState) int { setup(L); return 0 }), Protect: true}); err != nil {
		L.Close()
		return nil, err
	}
	L.Push(L.NewFunctionFromProto(netProto))
	if err := L.PCall(0, 1, nil); err != nil {
		L.Close()
		return nil, err
	}
	net, ok := L.Get(-1).(*lua.LTable)
	L.Pop(1)
	if !ok {
		L.Close()
		return nil, fmt.Errorf("net.lua non restituisce una tabella")
	}
	return &Engine{L: L, net: net}, nil
}

func (e *Engine) call(fn string, args ...lua.LValue) (lua.LValue, error) {
	if err := e.L.CallByParam(lua.P{Fn: e.net.RawGetString(fn), NRet: 1, Protect: true}, args...); err != nil {
		return lua.LNil, err
	}
	ret := e.L.Get(-1)
	e.L.Pop(1)
	return ret, nil
}

// Sim is a match running on an Engine.
type Sim struct {
	e *Engine
	g lua.LValue
}

// NewSim creates the match; mapID "" lets the seed pick it (maps.pick).
// players is the opts.players list (teams and weapons picked, from
// N.draft_finish), LNil for a 1 v 1; rules are those of the queue's event as
// JSON (sim/rules.lua, already checked by events.go), nil outside events.
func (e *Engine) NewSim(seed int64, mapID string, players lua.LValue, rules []byte) (*Sim, error) {
	m := lua.LValue(lua.LNil)
	if mapID != "" {
		m = lua.LString(mapID)
	}
	r, err := e.fromJSON(rules)
	if err != nil {
		return nil, err
	}
	g, err := e.call("new", lua.LNumber(seed), m, players, r)
	if err != nil {
		return nil, err
	}
	return &Sim{e: e, g: g}, nil
}

// Input of the player on turn for one tick.
type Input struct {
	Left, Right, Jump bool
	Hold              bool // jump is still held down
	Fire              bool
	Angle, Power      float64
	Weapon            string // "missile", "sword", "teleport", the secondaries ("eagle", "mallet", "lunge", "bellows"), crate weapons or an item
}

// Map is the match's map.
func (s *Sim) Map() string {
	return s.g.(*lua.LTable).RawGetString("map").String()
}

func (s *Sim) Step(in Input) error {
	angle, power := lua.LValue(lua.LNil), lua.LValue(lua.LNil)
	if in.Fire {
		angle, power = lua.LNumber(in.Angle), lua.LNumber(in.Power)
	}
	_, err := s.e.call("step", s.g, lua.LBool(in.Left), lua.LBool(in.Right), lua.LBool(in.Jump), lua.LBool(in.Hold), angle, power, lua.LString(in.Weapon))
	return err
}

func (s *Sim) Current() int {
	v, _ := s.e.call("current", s.g)
	n, _ := v.(lua.LNumber)
	return int(n)
}

// Remove removes robot i (from 1) of whoever left the match.
func (s *Sim) Remove(i int) error {
	_, err := s.e.call("remove", s.g, lua.LNumber(i))
	return err
}

func (s *Sim) Over() bool {
	v, _ := s.e.call("over", s.g)
	return v == lua.LTrue
}

// JSON messages come back as new []byte: they're sent as they are to all the
// players in the room, and nobody modifies them any more.

// Snapshot: the state; aiming says whether the player on turn is aiming, at
// angle (the others see it: without it people looked frozen, Sergio 9 Nov).
func (s *Sim) Snapshot(aiming bool, angle float64) []byte {
	aim := lua.LValue(lua.LNil)
	if aiming {
		aim = lua.LNumber(angle)
	}
	v, _ := s.e.call("snapshot", s.g, aim)
	return appendJSON(make([]byte, 0, 1024), v)
}

// Events returns the events of the last tick, one JSON per element.
func (s *Sim) Events() [][]byte {
	v, _ := s.e.call("events", s.g)
	t, ok := v.(*lua.LTable)
	if !ok || t.Len() == 0 {
		return nil
	}
	out := make([][]byte, t.Len())
	for i := range out {
		out[i] = appendJSON(make([]byte, 0, 96), t.RawGetInt(i+1))
	}
	return out
}

// Sync returns the digs made so far in the terrain, for whoever reconnects.
func (s *Sim) Sync() []byte {
	v, _ := s.e.call("sync", s.g)
	return appendJSON(nil, v)
}
