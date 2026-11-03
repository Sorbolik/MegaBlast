package main

import (
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

// A match between bots (sim/bot.lua) with its recipe (sim/replay.lua):
// returns the state fingerprints, comma separated. The second bot plays with
// a neural network (sim/rete.lua) with fixed weights.
const botMatchLua = `
local replay = require "sim.replay"
local bot, rete = require "sim.bot", require "sim.rete"
local strati = { bot.CARATTERISTICHE, 8, 1 }
local w, x = {}, 11
for i = 1, rete.quanti(strati) do
	x = (x * 1103515245 + 12345) % 2147483648
	w[i] = x / 2147483648 * 2 - 1
end
local players = { { team = 1, bot = "normale" }, { team = 2, bot = "difficile" },
	{ team = 3, bot = "difficile", pesi = { rete = { strati = strati, w = w } } } }
local r = replay.nuova(7, "pavimento", { players = players })
local g, bots = replay.partita(r)
while g.tick < 3600 and g.phase ~= "over" do
	g:step(replay.input(r, g, bots))
	replay.dopo(r, g)
end
local s = {}
for _, x in ipairs(r.impronte) do s[#s + 1] = string.format("%d", x.h) end
return table.concat(s, ",")
`

// The bot and the match give the same fingerprints on the server (gopher-lua,
// Go terrain) and on the phone (LuaJIT): so the server can have bots play and
// check match recipes. Without luajit the comparison is skipped.
func TestBotSameOnServerAndClient(t *testing.T) {
	e, err := newEngine()
	if err != nil {
		t.Fatal(err)
	}
	defer e.L.Close()
	if err := e.L.DoString(botMatchLua); err != nil {
		t.Fatal(err)
	}
	server := e.L.Get(-1).String()
	if strings.Count(server, ",") < 4 {
		t.Fatalf("too few fingerprints: %q", server)
	}
	luajit, err := exec.LookPath("luajit")
	if err != nil {
		t.Skip("luajit missing: comparison with the client skipped")
	}
	root, _ := filepath.Abs("..")
	cmd := exec.Command(luajit, "-e", `package.path = "client/?.lua;" .. package.path
local f = load([==[`+botMatchLua+`]==])
io.write(f())`)
	cmd.Dir = root
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("luajit: %v\n%s", err, out)
	}
	if client := string(out); client != server {
		t.Fatalf("different fingerprints:\nserver %s\nclient %s", server, client)
	}
}
