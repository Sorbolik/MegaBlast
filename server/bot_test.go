package main

import (
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

// Una partita tra bot (sim/bot.lua) con la sua ricetta (sim/replay.lua):
// restituisce le impronte dello stato, separate da virgole.
const botMatchLua = `
local replay = require "sim.replay"
local players = { { team = 1, bot = "normale" }, { team = 2, bot = "difficile" } }
local r = replay.nuova(7, "forgia", { players = players })
local g, bots = replay.partita(r)
while g.tick < 3600 and g.phase ~= "over" do
	g:step(replay.input(r, g, bots))
	replay.dopo(r, g)
end
local s = {}
for _, x in ipairs(r.impronte) do s[#s + 1] = string.format("%d", x.h) end
return table.concat(s, ",")
`

// Il bot e la partita danno le stesse impronte sul server (gopher-lua, terreno
// in Go) e sul telefono (LuaJIT): così il server può far giocare i bot e
// controllare le ricette delle partite. Senza luajit il confronto si salta.
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
		t.Fatalf("poche impronte: %q", server)
	}
	luajit, err := exec.LookPath("luajit")
	if err != nil {
		t.Skip("manca luajit: confronto col client saltato")
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
		t.Fatalf("impronte diverse:\nserver %s\nclient %s", server, client)
	}
}
