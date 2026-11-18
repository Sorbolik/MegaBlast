package main

import (
	"encoding/json"
	"net/http"
	"os"
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
	// every recipe that arrives is kept for the bots' training, the bad ones too
	MatchDir = t.TempDir()
	defer func() { MatchDir = "" }()
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
	if files, _ := os.ReadDir(MatchDir); len(files) != 3 || !strings.HasSuffix(files[0].Name(), "_prova.lua") {
		t.Fatalf("the three recipes should be kept: %v", files)
	}
}
