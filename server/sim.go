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

// Il codice Lua si compila una volta sola per tutto il processo: le proto
// compilate non cambiano e gopher-lua permette di condividerle tra gli stati.
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
	// tutti i moduli di client/sim: chi ne aggiunge uno non deve toccare il server
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

// Engine è uno stato Lua con la simulazione caricata: uno per stanza. Con il
// codice già compilato e la mappa già disegnata (terreno.go) crearne uno
// costa meno di un millisecondo, quindi non serve tenerli da parte.
type Engine struct {
	L   *lua.LState
	net *lua.LTable
}

func newEngine() (*Engine, error) { return buildEngine(installGoTerrain) }

// buildEngine prepara lo stato; setup gira dopo il caricamento dei moduli e
// prima di net.lua (le prove lo usano per confrontare il terreno Lua puro).
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

// Sim è una partita in esecuzione su un Engine.
type Sim struct {
	e *Engine
	g lua.LValue
}

// NewSim crea la partita. players è la lista di opts.players (squadre e armi
// scelte, da N.draft_finish), LNil per un 1 contro 1; normalize è il Torneo.
func (e *Engine) NewSim(seed int64, mapID string, players lua.LValue, normalize bool) (*Sim, error) {
	g, err := e.call("new", lua.LNumber(seed), lua.LString(mapID), players, lua.LBool(normalize))
	if err != nil {
		return nil, err
	}
	return &Sim{e: e, g: g}, nil
}

// Input del giocatore di turno per un tick.
type Input struct {
	Left, Right, Jump bool
	Hold              bool // il salto è ancora tenuto premuto
	Fire              bool
	Angle, Power      float64
	Weapon            string // "missile", "sword", "teleport", le secondarie ("eagle", "hook", "lunge"), quelle delle casse o un oggetto
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

func (s *Sim) Over() bool {
	v, _ := s.e.call("over", s.g)
	return v == lua.LTrue
}

// I messaggi JSON tornano come []byte nuovi: si mandano così come sono a tutti
// i giocatori della stanza, e nessuno li modifica più.

func (s *Sim) Snapshot() []byte {
	v, _ := s.e.call("snapshot", s.g)
	return appendJSON(make([]byte, 0, 1024), v)
}

// Events restituisce gli eventi dell'ultimo tick, un JSON per elemento.
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

// Sync restituisce gli scavi fatti finora nel terreno, per chi si riconnette.
func (s *Sim) Sync() []byte {
	v, _ := s.e.call("sync", s.g)
	return appendJSON(nil, v)
}
