package main

import (
	"testing"
	"time"
)

// The profile and wallet rules (sim/profile.lua, sim/wallet.lua) run in the
// server's Lua too, with the same sums as the phone: a won online match, a
// campaign mission and a training match against bots on a new profile. The
// numbers are those of the client (luajit on client/sim, 18 Nov): if the rules
// change, they change here as well.
func TestProfileRules(t *testing.T) {
	var got []float64
	luaEval(t, `
		local profile = require "sim.profile"
		local wallet = require "sim.wallet"
		local p = profile.new()
		local today = "2026-11-18"
		local r = { points = 160, won = true, mvp = true, awards = { { name = "a" } } }
		local g = profile.match_end(p, r, today)
		local rows, obs = wallet.match(p, r, today)
		wallet.apply(p, rows)
		wallet.apply(p, obs)
		local gm = profile.mission(p, "primi_passi", { true, true, false }, 300)
		local rb = { points = 90, bots = true }
		profile.match_end(p, rb, today)
		wallet.apply(p, (wallet.match(p, rb, today)))
		return { p.livello, p.xp, p.scaglie, p.ossidiana, g.xp, gm.xp, p.bot_partite }`, &got)
	want := []float64{1, 438, 86, 7, 235, 160, 1}
	if len(got) != len(want) {
		t.Fatalf("profilo sul server: %v, attesi %v", got, want)
	}
	for i := range want {
		if got[i] != want[i] {
			t.Fatalf("profilo sul server: %v, attesi %v", got, want)
		}
	}
}

// The Smith's orders (sim/orders.lua, docs/commesse.md) run in the server's Lua:
// what prizes (worker.lua) tells of an online match opens the bottega at the
// fifth, then drops the map's material and moves the orders; the delivery is
// an action of the profile (sim/progress.lua).
func TestOrdersRules(t *testing.T) {
	var got []float64
	luaEval(t, `
		local profile = require "sim.profile"
		local progress = require "sim.progress"
		local orders = require "sim.orders"
		local p = profile.new()
		local today = "2026-11-23"
		local res = { mode = "2v2", winner = 1, ranking = {
			{ robot = 1, team = 1, place = 1, points = 120, damage = 120, env_kills = 1 },
			{ robot = 3, team = 1, place = 2, points = 60, damage = 60 },
			{ robot = 2, team = 2, place = 3, points = 40, damage = 40 },
			{ robot = 4, team = 2, place = 4, points = 10, damage = 10 } } }
		local function match(humans)
			return progress.act(p, { k = "partita", r = { points = 120, won = true, online = true, awards = {} },
				commesse = orders.summary(res, 1, "gola", humans, 0, {}) }, today)
		end
		local gain
		for _ = 1, orders.OPEN_AFTER do gain = match(2) end
		local opened = gain.commesse[1].key == "open" and 1 or 0
		match(1)
		local alone = orders.materials(p, "grandine")
		match(2)
		local rows = progress.act(p, { k = "consegna", n = p.commesse.fabbro.n, set = "corvo" }, today)
		return { opened, alone, orders.materials(p, "grandine"), rows and 1 or 0, orders.fragments(p, "corvo") > 0 and 1 or 0 }`, &got)
	want := []float64{1, 0, 3, 1, 1}
	if len(got) != len(want) {
		t.Fatalf("commesse sul server: %v, attese %v", got, want)
	}
	for i := range want {
		if got[i] != want[i] {
			t.Fatalf("commesse sul server: %v, attese %v", got, want)
		}
	}
}

// The day of the rules turns at 5 in the morning in Italy (Sergio, 23 Nov)
func TestDayAtFive(t *testing.T) {
	at := func(h, m int) time.Time { return time.Date(2026, 11, 24, h, m, 0, 0, rome) }
	if d := today(at(4, 59)); d != "2026-11-23" {
		t.Fatalf("alle 4:59 il giorno è %s, atteso ieri", d)
	}
	if d := today(at(5, 0)); d != "2026-11-24" {
		t.Fatalf("alle 5:00 il giorno è %s, atteso oggi", d)
	}
}

// The Forge (sim/forge.lua, docs/commesse.md "La Fornace") runs in the server's
// Lua: the phone says the wall, then angle and power of each throw; the drop's
// flight and the prize are computed here, the same as on the phone.
func TestForgeRules(t *testing.T) {
	var got []float64
	luaEval(t, `
		local profile = require "sim.profile"
		local progress = require "sim.progress"
		local p = profile.new()
		p.ossidiana = 25
		local today = "2026-11-24"
		local ok = progress.act(p, { k = "colata", muro = today .. "#0" }, today)
		local r = progress.act(p, { k = "tiro", angolo = math.rad(45), forza = 0.1 }, today)
		local old = progress.act(p, { k = "colata", muro = "2026-11-23#2" }, today)
		return { ok and 1 or 0, p.ossidiana, r and r.scaglie or -1, p.fornace.tiri, old and 1 or 0 }`, &got)
	want := []float64{1, 10, 30, 2, 0}
	if len(got) != len(want) {
		t.Fatalf("fornace sul server: %v, attesa %v", got, want)
	}
	for i := range want {
		if got[i] != want[i] {
			t.Fatalf("fornace sul server: %v, attesa %v", got, want)
		}
	}
}
