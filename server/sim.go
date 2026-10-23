package main

import (
	_ "embed"
	"fmt"
	"strings"

	megablast "github.com/Sorbolik/MegaBlast"
	lua "github.com/yuin/gopher-lua"
)

//go:embed net.lua
var netLua string

// Sim è una partita in esecuzione nella simulazione Lua condivisa col client.
type Sim struct {
	L   *lua.LState
	net *lua.LTable
	g   lua.LValue
}

func NewSim(seed int64, mapID string) (*Sim, error) {
	L := lua.NewState()
	for _, name := range []string{"config", "rng", "terrain", "mapdata", "maps", "mischia", "game"} {
		src, err := megablast.SimFS.ReadFile("client/sim/" + name + ".lua")
		if err != nil {
			L.Close()
			return nil, err
		}
		code := string(src)
		L.PreloadModule("sim."+name, func(L *lua.LState) int {
			if err := L.DoString(code); err != nil {
				L.RaiseError("%v", err)
			}
			return 1
		})
	}
	if err := L.DoString(netLua); err != nil {
		L.Close()
		return nil, err
	}
	net, ok := L.Get(-1).(*lua.LTable)
	L.Pop(1)
	if !ok {
		L.Close()
		return nil, fmt.Errorf("net.lua non restituisce una tabella")
	}
	s := &Sim{L: L, net: net}
	g, err := s.call("new", lua.LNumber(seed), lua.LString(mapID))
	if err != nil {
		L.Close()
		return nil, err
	}
	s.g = g
	return s, nil
}

func (s *Sim) call(fn string, args ...lua.LValue) (lua.LValue, error) {
	if err := s.L.CallByParam(lua.P{Fn: s.net.RawGetString(fn), NRet: 1, Protect: true}, args...); err != nil {
		return lua.LNil, err
	}
	ret := s.L.Get(-1)
	s.L.Pop(1)
	return ret, nil
}

// Input del giocatore di turno per un tick.
type Input struct {
	Left, Right, Jump bool
	Hold              bool // il salto è ancora tenuto premuto
	Fire              bool
	Angle, Power      float64
	Weapon            string // "missile", "sword", "teleport", "grenade", "shards" o "punch"
}

func (s *Sim) Step(in Input) error {
	angle, power := lua.LValue(lua.LNil), lua.LValue(lua.LNil)
	if in.Fire {
		angle, power = lua.LNumber(in.Angle), lua.LNumber(in.Power)
	}
	_, err := s.call("step", s.g, lua.LBool(in.Left), lua.LBool(in.Right), lua.LBool(in.Jump), lua.LBool(in.Hold), angle, power, lua.LString(in.Weapon))
	return err
}

func (s *Sim) Current() int {
	v, _ := s.call("current", s.g)
	n, _ := v.(lua.LNumber)
	return int(n)
}

func (s *Sim) Over() bool {
	v, _ := s.call("over", s.g)
	return v == lua.LTrue
}

func (s *Sim) Snapshot() string {
	v, _ := s.call("snapshot", s.g)
	return v.String()
}

// Events restituisce gli eventi dell'ultimo tick, un JSON per elemento.
func (s *Sim) Events() []string {
	v, _ := s.call("events", s.g)
	str := v.String()
	if str == "" {
		return nil
	}
	return strings.Split(str, "\n")
}

func (s *Sim) Close() { s.L.Close() }
