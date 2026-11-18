package main

import (
	"encoding/json"
	"net/http"
	"strings"
	"testing"
)

// A recipe written in Lua (a short 1 vs 1 between bots, with their keys)
// comes back the same through /ricetta; with a different seed it doesn't.
func TestRecipeCheck(t *testing.T) {
	var text string
	luaEval(t, `
		local replay = require "sim.replay"
		local config = require "sim.config"
		local players = {}
		for i, p in ipairs(config.MODES["1v1"]) do players[i] = { team = p.team, bot = "normale" } end
		local r = replay.new(3, "pavimento", { players = players })
		r.bot_keys = true
		local g, bots = replay.match(r)
		while g.phase ~= "over" and g.tick < 1800 do
			g:step(replay.input(r, g, bots))
			replay.after(r, g)
		end
		return replay.encode(r)`, &text)
	url := "http" + strings.TrimPrefix(strings.TrimSuffix(testServer(t), "/ws"), "ws") + "/ricetta?p=prova&j=LuaJIT"
	post := func(body string) RecipeCheck {
		t.Helper()
		res, err := http.Post(url, "text/plain", strings.NewReader(body))
		if err != nil {
			t.Fatal(err)
		}
		defer res.Body.Close()
		var c RecipeCheck
		if err := json.NewDecoder(res.Body).Decode(&c); err != nil {
			t.Fatal(err)
		}
		return c
	}
	c := post(text)
	if !c.Physics || !c.Bots || c.Ticks != 1800 {
		t.Fatalf("the recipe should come back the same: %+v", c)
	}
	if c := post(strings.Replace(text, `["seme"]=3`, `["seme"]=4`, 1)); c.Physics || c.Bots {
		t.Fatalf("another seed should not come back the same: %+v", c)
	}
	if c := post("os.exit()"); c.Err == "" {
		t.Fatalf("not a recipe: %+v", c)
	}
}

// Training against the bots: the bots wear what the server builds from the
// player's eq and the seed (sim/loadout.lua rival), so a recipe whose bot
// was made weaker on the phone doesn't come back the same.
func TestRecipeRivalGear(t *testing.T) {
	var texts []string
	luaEval(t, `
		local replay = require "sim.replay"
		local loadout = require "sim.loadout"
		local mine = { liv = 40, variant = "a", gear = { mask = "corvo", chest = "fornace", legs = "vuoto" },
			lv = { mask = 25, chest = 18, legs = 22 }, sg = { mask = 2, chest = 1, legs = 2 },
			tree = { armor = 20, forge = 15, pick = { armor = { ["1"] = 1, ["2"] = 2 } } } }
		local players = { { team = 1, eq = mine }, { team = 2, bot = "normale", eq = loadout.rival(mine, 5, 2) } }
		local r = replay.new(5, "pavimento", { players = players })
		r.bot_keys = true
		local g, bots = replay.match(r)
		while g.phase ~= "over" and g.tick < 1800 do
			g:step(replay.input(r, g, bots))
			replay.after(r, g)
		end
		local good = replay.encode(r)
		r.opzioni.players[2].eq = loadout.rival({ liv = 1 }, 5, 2)
		return { good, replay.encode(r) }`, &texts)
	url := "http" + strings.TrimPrefix(strings.TrimSuffix(testServer(t), "/ws"), "ws") + "/ricetta?p=prova&j=LuaJIT"
	post := func(body string) RecipeCheck {
		t.Helper()
		res, err := http.Post(url, "text/plain", strings.NewReader(body))
		if err != nil {
			t.Fatal(err)
		}
		defer res.Body.Close()
		var c RecipeCheck
		if err := json.NewDecoder(res.Body).Decode(&c); err != nil {
			t.Fatal(err)
		}
		return c
	}
	if c := post(texts[0]); !c.Physics || !c.Bots {
		t.Fatalf("the training recipe should come back the same: %+v", c)
	}
	if c := post(texts[1]); !c.Physics || !c.Bots {
		t.Fatalf("the server rebuilds the bot's gear, the weakened one should come back the same too: %+v", c)
	}
}
