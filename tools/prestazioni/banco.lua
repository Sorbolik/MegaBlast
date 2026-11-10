-- Banco di prova della simulazione e del bot (docs/prestazioni.md, "Il banco").
-- Gioca partite fra bot senza disegno e misura, tick per tick, quanto costano
-- la simulazione (game:step) e il bot (bot.input): tempo medio, 99° percentile,
-- peggiore e memoria nuova (KB). Il raccoglitore è fermo durante la misura,
-- così i KB sono quelli veri.
--
--   luajit tools/prestazioni/banco.lua          (col JIT: Android, PC)
--   luajit -joff tools/prestazioni/banco.lua    (senza JIT: come su iPhone)
--
-- Sul telefono i tempi sono 3-5 volte quelli del PC: conta il confronto fra
-- prima e dopo una modifica, sulla stessa macchina.

package.path = "client/?.lua;" .. package.path
local game = require "sim.game"
local bot = require "sim.bot"

local PARTITE = {
	{ nome = "2v2 pavimento", mappa = "pavimento", squadre = { 1, 2, 1, 2 }, seme = 5 },
	{ nome = "2v2 fossa", mappa = "fossa", squadre = { 1, 2, 1, 2 }, seme = 7 },
	{ nome = "1v1 pavimento", mappa = "pavimento", squadre = { 1, 2 }, seme = 3 },
}
local LIVELLO = "difficile"
local MAX_TICK = 60 * 240

local function percentile(t, p)
	table.sort(t)
	return t[math.max(1, math.floor(#t * p + 0.5))] or 0
end

local function gioca(def)
	local players = {}
	for i, s in ipairs(def.squadre) do players[i] = { team = s } end
	local g = game.new(def.seme, def.mappa, { players = players })
	local bots = {}
	for i = 1, #players do bots[i] = bot.new(i, LIVELLO, def.seme) end
	collectgarbage("collect")
	collectgarbage("stop")
	local tick_ms, kb_bot, kb_sim = {}, 0, 0
	local peggiore, kb_peggiore = 0, 0
	for t = 1, MAX_TICK do
		local t0, k0 = os.clock(), collectgarbage("count")
		local input = bot.input(bots[g.current], g)
		local k1 = collectgarbage("count")
		g:step(input)
		g:pop_events()
		local k2 = collectgarbage("count")
		local ms = (os.clock() - t0) * 1000
		tick_ms[t] = ms
		kb_bot, kb_sim = kb_bot + (k1 - k0), kb_sim + (k2 - k1)
		if ms > peggiore then peggiore = ms end
		if k2 - k0 > kb_peggiore then kb_peggiore = k2 - k0 end
		-- oltre 1 GB si raccoglie (fuori dalla misura del tick)
		if k2 > 1000000 then collectgarbage("collect") end
		if g.phase == "over" then break end
	end
	collectgarbage("restart")
	local n, somma = #tick_ms, 0
	for i = 1, n do somma = somma + tick_ms[i] end
	return string.format("%-14s %6d tick  medio %6.3f ms  99%% %6.3f ms  peggiore %6.2f ms  KB/tick: bot %5.2f  sim %5.2f  (peggiore %4.0f)",
		def.nome, n, somma / n, percentile(tick_ms, 0.99), peggiore, kb_bot / n, kb_sim / n, kb_peggiore)
end

print(string.format("Banco %s, bot %s, JIT %s", jit and jit.version or _VERSION, LIVELLO,
	jit and jit.status() and "acceso" or "spento"))
for _, def in ipairs(PARTITE) do print(gioca(def)) end
