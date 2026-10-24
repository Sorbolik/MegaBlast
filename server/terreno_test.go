package main

import (
	"math/rand"
	"strings"
	"testing"

	lua "github.com/yuin/gopher-lua"
)

// Stato Lua col terreno di client/sim/terrain.lua così com'è, per confronto.
func luaTerrainEngine(t *testing.T) *Engine {
	e, err := buildEngine(func(L *lua.LState) {
		if err := L.DoString(`terrain_restore = function() return false end; terrain_store = function() end`); err != nil {
			L.RaiseError("%v", err)
		}
	})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(e.L.Close)
	return e
}

// Le stesse operazioni sul terreno Go e su quello Lua danno le stesse celle e
// le stesse risposte.
const terrainOps = `
local terrain = require "sim.terrain"
local maps = require "sim.maps"
local rng = require "sim.rng"
return function(map_id, seed)
	local t = terrain.new(640, 360, 2)
	maps.get(map_id).build(t, seed)
	local r = rng.new(seed)
	local out = {}
	local function cells()
		local n, h = 0, 0
		for i = 1, t.w * t.h do
			local v = t.data[i]
			if v ~= 0 then n = n + 1; h = (h * 31 + i * v) % 2147483647 end
		end
		out[#out + 1] = n .. ":" .. h
	end
	cells()
	for k = 1, 400 do
		local x, y = r:range(-40, 1320), r:range(-40, 760)
		if k % 4 == 0 then
			out[#out + 1] = table.concat({ t:carve(x, y, r:range(5, 60)) }, ",")
		end
		local cx, cy = math.floor(x / 2), math.floor(y / 2)
		out[#out + 1] = tostring(t:any_solid(cx, cx + math.floor(r:range(-2, 12)), cy, cy + math.floor(r:range(-2, 20))))
		out[#out + 1] = tostring(t:solid(x, y)) .. tostring(t:get(cx, cy)) .. tostring(t:ground_below(x, y))
			.. tostring(t:surface_y(x)) .. tostring(t:get(x / 2, cy))
		if k % 50 == 0 then cells() end
	end
	return table.concat(out, " ")
end
`

func runTerrainOps(t *testing.T, e *Engine, mapID string, seed int) string {
	if err := e.L.DoString(terrainOps); err != nil {
		t.Fatal(err)
	}
	fn := e.L.Get(-1)
	e.L.Pop(1)
	if err := e.L.CallByParam(lua.P{Fn: fn, NRet: 1, Protect: true}, lua.LString(mapID), lua.LNumber(seed)); err != nil {
		t.Fatal(err)
	}
	out := e.L.Get(-1).String()
	e.L.Pop(1)
	return out
}

func TestGoTerrainMatchesLua(t *testing.T) {
	goE, err := newEngine()
	if err != nil {
		t.Fatal(err)
	}
	defer goE.L.Close()
	luaE := luaTerrainEngine(t)
	for _, m := range []string{"forgia", "isole", "casuale"} {
		for seed := 1; seed <= 3; seed++ {
			a, b := runTerrainOps(t, goE, m, seed), runTerrainOps(t, luaE, m, seed)
			if a != b {
				t.Fatalf("mappa %s seed %d: terreno Go diverso da quello Lua", m, seed)
			}
		}
	}
}

// Una partita intera con comandi a caso: col terreno Go il server deve
// vedere esattamente quello che vedrebbe col Lua puro (e quindi il client).
func TestGoTerrainSameMatch(t *testing.T) {
	goE, err := newEngine()
	if err != nil {
		t.Fatal(err)
	}
	defer goE.L.Close()
	luaE := luaTerrainEngine(t)
	explosions := 0
	for k := 0; k < 12; k++ {
		m, seed := []string{"forgia", "isole"}[k%2], int64(11+k)
		a, err := goE.NewSim(seed, m, lua.LNil, false)
		if err != nil {
			t.Fatal(err)
		}
		b, err := luaE.NewSim(seed, m, lua.LNil, false)
		if err != nil {
			t.Fatal(err)
		}
		rng := rand.New(rand.NewSource(seed))
		var in Input
		for tick := 0; tick < 8000 && !a.Over(); tick++ {
			in.Fire, in.Jump = false, false
			if tick%20 == 0 {
				r := rng.Intn(14)
				in = Input{Left: r%3 == 0, Right: r%3 == 1, Hold: r%2 == 0}
				switch r {
				case 0:
					in = Input{Fire: true, Angle: rng.Float64() * 3.14, Power: 0.3 + rng.Float64()*0.7}
				case 1:
					in.Jump = true
				case 2:
					in = Input{Fire: true, Angle: rng.Float64() * 3.14, Power: 0.5, Weapon: "teleport"}
				case 3:
					in = Input{Fire: true, Angle: rng.Float64() * 3.14, Weapon: "sword"}
				}
			}
			if err := a.Step(in); err != nil {
				t.Fatal(err)
			}
			if err := b.Step(in); err != nil {
				t.Fatal(err)
			}
			ea, eb := a.Events(), b.Events()
			if len(ea) != len(eb) {
				t.Fatalf("%s tick %d: eventi diversi", m, tick)
			}
			for i := range ea {
				if strings.Contains(string(ea[i]), `"explosion"`) {
					explosions++
				}
				if !sameJSON(ea[i], eb[i]) {
					t.Fatalf("%s tick %d: evento diverso\n%s\n%s", m, tick, ea[i], eb[i])
				}
			}
			if tick%10 == 0 && !sameJSON(a.Snapshot(), b.Snapshot()) {
				t.Fatalf("%s tick %d: stato diverso\n%s\n%s", m, tick, a.Snapshot(), b.Snapshot())
			}
		}
	}
	if explosions < 20 {
		t.Fatalf("solo %d esplosioni, la prova non scava abbastanza", explosions)
	}
}
