-- The Forge (sim/forge.lua, rules in docs/commesse.md "La Fornace"): the wall,
-- the flight of the drop, pours, throws, prizes, the bonus throw, melting.
-- From the root:
--   luajit tests/forge_test.lua
package.path = "client/?.lua;" .. package.path

local forge = require "sim.forge"
local wallet = require "sim.wallet"
local orders = require "sim.orders"
local progress = require "sim.progress"

local failures = 0
local function check(cond, msg)
	if cond then
		print("ok   " .. msg)
	else
		print("FAIL " .. msg)
		failures = failures + 1
	end
end

local TODAY = "2026-11-24"
local function new(obs)
	local p = wallet.init({ stelle = {} })
	p.ossidiana = obs or 100
	orders.init(p)
	forge.init(p)
	return p
end

-- an angle and power that put the drop in mould slot (the first found)
local AIMS = {}
for deg = 5, 85, 0.5 do
	for pw = 20, 100 do
		local a, w = math.rad(deg), pw / 100
		local r = forge.fly(a, w, {})
		if r.esito == "stampo" and not AIMS[r.slot] then AIMS[r.slot] = { a, w } end
	end
end

-- the wall
local wall = forge.wall(TODAY .. "#0")
local sc, fr = 0, 0
for _, m in ipairs(wall) do
	if m.scaglie then sc = sc + m.scaglie else fr = fr + m.n end
end
check(#wall == 12 and sc == 255 and fr == 8, "12 stampi, 255 Scaglie e 8 frammenti per muro")
check(forge.key(TODAY, 0) == TODAY .. "#0" and forge.key(TODAY, 8) == TODAY .. "#1" and forge.key(TODAY, 23) == TODAY .. "#2",
	"tre muri al giorno (5, 13, 21)")
local differ = false
for i, m in ipairs(forge.wall(TODAY .. "#1")) do
	if m.set and m.set ~= wall[i].set then differ = true end
end
check(differ, "le famiglie cambiano col muro")

-- every mould can be hit, the far ones need almost all the power
local all = true
for i = 1, 12 do
	if not AIMS[i] then all = false; print("     stampo " .. i .. " irraggiungibile") end
end
check(all, "ogni stampo si può centrare")
local strongest = 0
for i = 1, 12 do
	local best = 1
	for deg = 5, 85, 0.5 do
		for pw = 20, 100 do
			local r = forge.fly(math.rad(deg), pw / 100, {})
			if r.esito == "stampo" and r.slot == i then best = math.min(best, pw / 100) end
		end
	end
	strongest = math.max(strongest, best)
end
check(strongest > 0.85 and strongest <= 1, "il più lontano chiede quasi tutta la forza (" .. strongest .. ")")
check(forge.fly(math.rad(45), 0.1, {}).esito == "secchio", "una goccia corta cade nel secchio")

-- a pour
local p = new(30)
check(not forge.throw(p, 0.5, 0.5), "senza colata non si tira")
check(not forge.pour(p, "2026-11-23#2", TODAY), "il muro deve essere di oggi")
check(not forge.pour(p, "boh", TODAY), "muro illeggibile")
check(forge.pour(p, TODAY .. "#1", TODAY) and p.ossidiana == 10 and p.fornace.tiri == 3, "colata: 20 Ossidiana, 3 tiri")
check(not forge.pour(p, TODAY .. "#1", TODAY), "una colata alla volta")
local s0 = p.scaglie
local r = forge.throw(p, AIMS[1][1], AIMS[1][2])
check(r.esito == "stampo" and r.slot == 1 and r.scaglie == 15 and p.scaglie == s0 + 15, "centro: le Scaglie dello stampo")
r = forge.throw(p, AIMS[1][1], AIMS[1][2])
check(r.esito ~= "stampo" and p.scaglie == s0 + 15 + forge.MISS, "uno stampo pieno non paga più: secchio")
local slot2 = AIMS[2]
r = forge.throw(p, slot2[1], slot2[2])
local m2 = forge.wall(TODAY .. "#1")[2]
check(r.esito == "stampo" and r.set == m2.set and p.commesse.frammenti[m2.set] == 1, "centro: i frammenti della famiglia")
check(p.fornace.tiri == 0 and not r.bonus, "due su tre: niente tiro in più")
check(not forge.pour(p, TODAY .. "#1", TODAY), "senza 20 Ossidiana niente colata")

-- going back to an older wall can't refill it; a new wall empties the moulds
p.ossidiana = 100
check(not forge.pour(p, TODAY .. "#0", TODAY), "non si torna a un muro vecchio")
check(forge.pour(p, TODAY .. "#1", TODAY) and p.fornace.pieni[1], "stesso muro: gli stampi pieni restano pieni")
forge.throw(p, 0.5, 0.1); forge.throw(p, 0.5, 0.1); forge.throw(p, 0.5, 0.1)
check(forge.pour(p, TODAY .. "#2", TODAY) and next(p.fornace.pieni) == nil, "muro nuovo: stampi vuoti")

-- three hits out of three: one throw more
for _, i in ipairs({ 3, 5, 8 }) do r = forge.throw(p, AIMS[i][1], AIMS[i][2]) end
check(r.bonus == 1 and p.fornace.tiri == 1, "tre centri su tre: un tiro in più")
r = forge.throw(p, AIMS[10][1], AIMS[10][2])
check(r.esito == "stampo" and not r.bonus and p.fornace.tiri == 0, "il tiro in più si gioca, una volta sola")

-- melting
p = new()
p.commesse.frammenti.corvo = 5
check(not forge.melt(p, "corvo", "corvo"), "non si fonde nella stessa famiglia")
check(forge.melt(p, "corvo", "vuoto") and p.commesse.frammenti.corvo == 1 and p.commesse.frammenti.vuoto == 1, "4 frammenti per 1 di un'altra famiglia")
check(not forge.melt(p, "corvo", "vuoto"), "servono 4 frammenti")
local before = p.scaglie
check(forge.melt(p, "corvo") and p.scaglie == before + 20 and p.commesse.frammenti.corvo == 0, "1 frammento per 20 Scaglie")
check(not forge.melt(p, "drago"), "famiglia sconosciuta")

-- the same through the profile's actions (phone and server)
p = new()
check(progress.act(p, { k = "colata", muro = TODAY .. "#0" }, TODAY), "azione colata")
r = progress.act(p, { k = "tiro", angolo = AIMS[12][1], forza = AIMS[12][2] }, TODAY)
check(r and r.esito == "stampo" and r.scaglie == 80, "azione tiro")
check(progress.act(p, { k = "fondi", da = "fabbro" }, TODAY) == nil, "azione fondi senza frammenti")

if failures > 0 then
	print(failures .. " falliti")
	os.exit(1)
end
print("tutti ok")
