package main

import "testing"

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
