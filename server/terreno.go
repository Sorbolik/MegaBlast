package main

import (
	"math"
	"sync"

	lua "github.com/yuin/gopher-lua"
)

// Terreno del server: le celle stanno in un []byte invece che in una tabella
// Lua da 230.400 valori. Una partita occupa 230 KB invece di 3,7 MB, e i
// controlli più usati dalla simulazione (collisioni, scavi) girano in Go.
//
// Si sostituiscono solo le funzioni di sim.terrain che leggono o scrivono le
// celle; tutto il resto (load, rect, circle, generate...) resta il Lua di
// client/sim/terrain.lua e arriva alle celle attraverso t.data, che qui è un
// userdata con __index e __newindex. TestGoTerrainMatchesLua controlla che
// il risultato sia identico a quello del Lua puro, cella per cella.

type cells []byte

const cellsType = "megablast.cells"

// Celle delle mappe fisse già disegnate, condivise da tutti gli stati Lua del
// processo (sola lettura): una partita nuova le copia in pochi microsecondi.
var baseCells sync.Map // id mappa -> cells

func installGoTerrain(L *lua.LState) {
	L.Push(L.GetGlobal("require"))
	L.Push(lua.LString("sim.terrain"))
	L.Call(1, 1)
	mod := L.CheckTable(-1)
	L.Pop(1)

	mt := L.NewTypeMetatable(cellsType)
	mt.RawSetString("__index", L.NewFunction(func(L *lua.LState) int {
		c := L.CheckUserData(1).Value.(cells)
		i, ok := index(L.Get(2), len(c))
		if !ok {
			L.Push(lua.LNil)
		} else {
			L.Push(lua.LNumber(c[i]))
		}
		return 1
	}))
	mt.RawSetString("__newindex", L.NewFunction(func(L *lua.LState) int {
		c := L.CheckUserData(1).Value.(cells)
		i, ok := index(L.Get(2), len(c))
		if !ok {
			L.RaiseError("cella fuori dal terreno: %v", L.Get(2))
		}
		c[i] = byte(L.CheckNumber(3))
		return 0
	}))

	grid := func(L *lua.LState) (*lua.LTable, cells, int, int) {
		t := L.CheckTable(1)
		c := t.RawGetString("data").(*lua.LUserData).Value.(cells)
		return t, c, int(t.RawGetString("w").(lua.LNumber)), int(t.RawGetString("h").(lua.LNumber))
	}
	// get come in Lua: fuori dalla griglia 0, indice non intero nil
	get := func(c cells, w, h int, cx, cy float64) lua.LValue {
		if cx < 0 || cy < 0 || cx >= float64(w) || cy >= float64(h) {
			return lua.LNumber(0)
		}
		if cx != math.Floor(cx) || cy != math.Floor(cy) {
			return lua.LNil
		}
		return lua.LNumber(c[int(cy)*w+int(cx)])
	}

	set := func(name string, fn lua.LGFunction) { mod.RawSetString(name, L.NewFunction(fn)) }

	set("new", func(L *lua.LState) int {
		w, h, cell := L.CheckNumber(1), L.CheckNumber(2), L.CheckNumber(3)
		ud := L.NewUserData()
		ud.Value = make(cells, int(w)*int(h))
		L.SetMetatable(ud, mt)
		t := L.NewTable()
		t.RawSetString("w", w)
		t.RawSetString("h", h)
		t.RawSetString("cell", cell)
		t.RawSetString("data", ud)
		L.SetMetatable(t, mod)
		L.Push(t)
		return 1
	})
	set("get", func(L *lua.LState) int {
		_, c, w, h := grid(L)
		L.Push(get(c, w, h, float64(L.CheckNumber(2)), float64(L.CheckNumber(3))))
		return 1
	})
	set("set", func(L *lua.LState) int {
		_, c, w, h := grid(L)
		cx, cy := int(L.CheckNumber(2)), int(L.CheckNumber(3))
		if cx >= 0 && cy >= 0 && cx < w && cy < h {
			c[cy*w+cx] = byte(L.CheckNumber(4))
		}
		return 0
	})
	set("solid", func(L *lua.LState) int {
		t, c, w, h := grid(L)
		size := float64(t.RawGetString("cell").(lua.LNumber))
		v := get(c, w, h, math.Floor(float64(L.CheckNumber(2))/size), math.Floor(float64(L.CheckNumber(3))/size))
		L.Push(lua.LBool(v != lua.LNumber(0)))
		return 1
	})
	set("any_solid", func(L *lua.LState) int {
		_, c, w, h := grid(L)
		cx0, cx1 := max(0, int(L.CheckNumber(2))), min(w-1, int(L.CheckNumber(3)))
		cy0, cy1 := max(0, int(L.CheckNumber(4))), min(h-1, int(L.CheckNumber(5)))
		if cx0 > cx1 {
			cy1 = -1 // rettangolo tutto fuori dalla griglia
		}
		for cy := cy0; cy <= cy1; cy++ {
			for _, v := range c[cy*w+cx0 : cy*w+cx1+1] {
				if v != 0 {
					L.Push(lua.LTrue)
					return 1
				}
			}
		}
		L.Push(lua.LFalse)
		return 1
	})
	set("carve", func(L *lua.LState) int {
		t, c, w, h := grid(L)
		size := float64(t.RawGetString("cell").(lua.LNumber))
		x, y, r := float64(L.CheckNumber(2)), float64(L.CheckNumber(3)), float64(L.CheckNumber(4))
		cx0 := max(0, int(math.Floor((x-r)/size)))
		cx1 := min(w-1, int(math.Floor((x+r)/size)))
		cy0 := max(0, int(math.Floor((y-r)/size)))
		cy1 := min(h-1, int(math.Floor((y+r)/size)))
		r2 := r * r
		for cy := cy0; cy <= cy1; cy++ {
			dy := float64((float64(cy)+0.5)*size) - y
			for cx := cx0; cx <= cx1; cx++ {
				dx := float64((float64(cx)+0.5)*size) - x
				// le conversioni esplicite impediscono a Go di fondere le
				// operazioni (FMA): i conti restano identici a quelli di Lua
				if float64(dx*dx)+float64(dy*dy) <= r2 && c[cy*w+cx] == 1 {
					c[cy*w+cx] = 0
				}
			}
		}
		L.Push(lua.LNumber(cy0))
		L.Push(lua.LNumber(cy1))
		return 2
	})
	groundBelow := func(t *lua.LTable, c cells, w, h int, x, y float64) lua.LValue {
		size := float64(t.RawGetString("cell").(lua.LNumber))
		cx := math.Floor(x / size)
		start := min(float64(h-1), math.Floor(y/size))
		for cy := start; cy >= 0; cy-- {
			if get(c, w, h, cx, cy) != lua.LNumber(0) && get(c, w, h, cx, cy+1) == lua.LNumber(0) {
				return lua.LNumber((cy + 1) * size)
			}
		}
		return lua.LNil
	}
	set("ground_below", func(L *lua.LState) int {
		t, c, w, h := grid(L)
		L.Push(groundBelow(t, c, w, h, float64(L.CheckNumber(2)), float64(L.CheckNumber(3))))
		return 1
	})
	set("surface_y", func(L *lua.LState) int {
		t, c, w, h := grid(L)
		size := float64(t.RawGetString("cell").(lua.LNumber))
		L.Push(groundBelow(t, c, w, h, float64(L.CheckNumber(2)), float64(h)*size))
		return 1
	})

	// per net.lua: celle delle mappe fisse disegnate una volta per processo
	L.SetGlobal("terrain_restore", L.NewFunction(func(L *lua.LState) int {
		_, c, _, _ := grid(L)
		base, ok := baseCells.Load(L.CheckString(2))
		if ok && len(base.(cells)) == len(c) {
			copy(c, base.(cells))
		}
		L.Push(lua.LBool(ok))
		return 1
	}))
	L.SetGlobal("terrain_store", L.NewFunction(func(L *lua.LState) int {
		_, c, _, _ := grid(L)
		baseCells.LoadOrStore(L.CheckString(2), append(cells(nil), c...))
		return 0
	}))
}

// index converte una chiave Lua nella posizione in c (le chiavi partono da 1).
func index(k lua.LValue, n int) (int, bool) {
	f, ok := k.(lua.LNumber)
	if !ok || float64(f) != math.Floor(float64(f)) || f < 1 || int(f) > n {
		return 0, false
	}
	return int(f) - 1, true
}
