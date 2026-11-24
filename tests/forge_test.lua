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

-- an angle and power for each mould of a wall (the first found), and the least
-- power that reaches each one
local function aims(wall)
	local out, least = {}, {}
	for deg = 5, 85, 1 do
		for pw = 20, 100 do
			local a, w = math.rad(deg), pw / 100
			local r = forge.fly(a, w, wall, {})
			if r.esito == "stampo" then
				out[r.slot] = out[r.slot] or { a, w }
				least[r.slot] = math.min(least[r.slot] or 1, w)
			end
		end
	end
	return out, least
end

-- the walls: 12 moulds, 255 Scaglie and 8 fragments, all reachable, in new places
local seen_places, strongest, all_ok = {}, 0, true
for i = 1, 10 do
	local key = string.format("2026-11-%02d#%d", 10 + i % 9, i % 3)
	local wall = forge.layout(key, 1234 + i)
	local sc, fr = 0, 0
	for _, m in ipairs(wall) do
		if m.scaglie then sc = sc + m.scaglie else fr = fr + m.n end
		seen_places[m.x .. "," .. m.y] = true
	end
	local _, least = aims(wall)
	local n = 0
	for s = 1, 12 do if least[s] then n = n + 1; strongest = math.max(strongest, least[s]) end end
	if #wall ~= 12 or sc ~= 255 or fr ~= 8 or n ~= 12 then
		all_ok = false
		print("     muro " .. key .. ": " .. #wall .. " stampi, " .. sc .. " Scaglie, " .. fr .. " frammenti, " .. n .. " raggiungibili")
	end
	for a = 1, #wall do
		for b = a + 1, #wall do
			if (wall[a].x - wall[b].x) ^ 2 + (wall[a].y - wall[b].y) ^ 2 < forge.SPOT_GAP ^ 2 then all_ok = false end
		end
	end
end
check(all_ok, "ogni muro: 12 stampi staccati, 255 Scaglie e 8 frammenti, tutti centrabili")
local places = 0
for _ in pairs(seen_places) do places = places + 1 end
check(places > 60, "a ogni muro gli stampi cambiano posto (" .. places .. " posti in 10 muri)")
check(strongest > 0.8 and strongest <= 1, "il più lontano chiede quasi tutta la forza (" .. strongest .. ")")
check(forge.key(TODAY, 0) == TODAY .. "#0" and forge.key(TODAY, 8) == TODAY .. "#1" and forge.key(TODAY, 23) == TODAY .. "#2",
	"tre muri al giorno (5, 13, 21)")
local wa, wb = forge.layout(TODAY .. "#0", 1), forge.layout(TODAY .. "#0", 2)
check(wa[1].x ~= wb[1].x or wa[1].y ~= wb[1].y, "ogni giocatore ha i suoi muri")
check(forge.fly(math.rad(45), 0.1, wa, {}).esito == "secchio", "una goccia corta cade nel secchio")

-- the drop is a ball: it bounces off the iron and still counts until it touches
-- the floor (Sergio, 24 Nov); it always ends, on the floor or in a mould
do
	local bounced_in, bounced, ended = 0, 0, true
	for deg = 10, 85, 1 do
		for pw = 10, 100, 2 do
			local r, path = forge.fly(math.rad(deg), pw / 100, wa, {}, true)
			if r.ticks >= forge.MAX_TICKS then ended = false end
			if r.rimbalzi > 0 then
				bounced = bounced + 1
				if r.esito == "stampo" then bounced_in = bounced_in + 1 end
			end
			local last = path[#path]
			if r.esito == "secchio" and last[2] - forge.DROP_R >= forge.FLOOR and last[1] > -400 and last[1] < 2000
				and r.ticks < forge.MAX_TICKS then
				-- (or still on a lip, dripping)
			end
		end
	end
	check(ended, "ogni goccia finisce, a terra o in uno stampo")
	check(bounced > 50, "la goccia rimbalza sul ferro (" .. bounced .. " tiri)")
	check(bounced_in > 5, "e dopo un rimbalzo può entrare in uno stampo (" .. bounced_in .. " tiri)")
	-- a full mould is closed: the drop bounces off its metal
	local m = wa[1]
	for deg = 20, 80, 2 do
		for pw = 10, 100, 1 do
			local r = forge.fly(math.rad(deg), pw / 100, wa, {})
			if r.esito == "stampo" and r.slot == 1 and r.rimbalzi == 0 then
				local r2 = forge.fly(math.rad(deg), pw / 100, wa, { [1] = true })
				check(r2.slot ~= 1 and r2.rimbalzi > 0, "uno stampo pieno è chiuso: la goccia ci rimbalza sopra")
				m = nil
				break
			end
		end
		if not m then break end
	end
end

-- the lucky mould: about one wall in 8, for sure within 15
do
	local q = new(1e6)
	local gaps, last, lucky, worst = 0, 0, 0, 0
	for i = 1, 400 do
		local key = string.format("2027-%02d-%02d#%d", 1 + math.floor(i / 84) % 12, 1 + math.floor(i / 3) % 28, i % 3)
		if key > q.fornace.muro then
			forge.pour(q, key, key:sub(1, 10))
			if q.fornace.fortunato then
				lucky = lucky + 1
				worst = math.max(worst, i - last)
				last = i
			end
			q.fornace.tiri = 0
		end
	end
	check(lucky > 25 and lucky < 80 and worst <= forge.LUCKY_PITY, "lo stampo fortunato: circa un muro su 8, al più ogni 15 (" .. lucky .. " in 400, distanza massima " .. worst .. ")")
	local w = forge.wall(q, q.fornace.muro)
	local doubled = true
	for _, m in ipairs(w) do
		if m.lucky then doubled = (m.scaglie or 0) == 2 * (forge.PRIZES[m.slot].scaglie or 0) and (m.n or 0) == 2 * (forge.PRIZES[m.slot].frammenti or 0) end
	end
	check(doubled, "lo stampo fortunato dà il doppio")
end

-- a pour
local p = new(30)
check(not forge.throw(p, 0.5, 0.5), "senza colata non si tira")
check(not forge.pour(p, "2026-11-23#2", TODAY), "il muro deve essere di oggi")
check(not forge.pour(p, "boh", TODAY), "muro illeggibile")
check(forge.pour(p, TODAY .. "#1", TODAY) and p.ossidiana == 10 and p.fornace.tiri == 3, "colata: 20 Ossidiana, 3 tiri")
check(not forge.pour(p, TODAY .. "#1", TODAY), "una colata alla volta")
local AIMS = aims(forge.wall(p, TODAY .. "#1"))
local s0 = p.scaglie
local first = forge.wall(p, TODAY .. "#1")[1]
local r = forge.throw(p, AIMS[1][1], AIMS[1][2])
check(r.esito == "stampo" and r.slot == 1 and r.scaglie == first.scaglie and p.scaglie == s0 + first.scaglie, "centro: le Scaglie dello stampo")
r = forge.throw(p, AIMS[1][1], AIMS[1][2])
check(r.esito ~= "stampo" and p.scaglie == s0 + first.scaglie + forge.MISS, "uno stampo pieno non paga più: secchio")
local slot2 = AIMS[2]
r = forge.throw(p, slot2[1], slot2[2])
local m2 = forge.wall(p, TODAY .. "#1")[2]
check(r.esito == "stampo" and r.set == m2.set and p.commesse.frammenti[m2.set] == m2.n, "centro: i frammenti della famiglia")
check(p.fornace.tiri == 0 and not r.bonus, "due su tre: niente tiro in più")
check(not forge.pour(p, TODAY .. "#1", TODAY), "senza 20 Ossidiana niente colata")

-- going back to an older wall can't refill it; a new wall empties the moulds
p.ossidiana = 100
check(not forge.pour(p, TODAY .. "#0", TODAY), "non si torna a un muro vecchio")
check(forge.pour(p, TODAY .. "#1", TODAY) and p.fornace.pieni[1], "stesso muro: gli stampi pieni restano pieni")
forge.throw(p, 0.5, 0.1); forge.throw(p, 0.5, 0.1); forge.throw(p, 0.5, 0.1)
check(forge.pour(p, TODAY .. "#2", TODAY) and next(p.fornace.pieni) == nil, "muro nuovo: stampi vuoti")
AIMS = aims(forge.wall(p, TODAY .. "#2"))

-- three hits out of three: one throw more
for _, i in ipairs({ 3, 5, 8 }) do r = forge.throw(p, AIMS[i][1], AIMS[i][2]) end
check(r.bonus == 1 and p.fornace.tiri == 1, "tre centri su tre: un tiro in più")
r = forge.throw(p, AIMS[10][1], AIMS[10][2])
check(r.esito == "stampo" and not r.bonus and p.fornace.tiri == 0, "il tiro in più si gioca, una volta sola")

-- the jackpot: the last empty mould of a wall filled
p = new()
forge.pour(p, TODAY .. "#0", TODAY)
local jw = forge.wall(p, TODAY .. "#0")
for i = 2, 12 do p.fornace.pieni[i] = true end
local ja
for deg = 5, 85 do
	for pw = 20, 100 do
		local rr = forge.fly(math.rad(deg), pw / 100, jw, p.fornace.pieni)
		if not ja and rr.esito == "stampo" and rr.slot == 1 then ja = { math.rad(deg), pw / 100 } end
	end
end
local before = p.scaglie or 0
r = forge.throw(p, ja[1], ja[2])
check(r.jackpot == forge.JACKPOT and r.medal and p.fornace.jackpot == 1
	and p.scaglie == before + jw[1].scaglie + forge.JACKPOT, "muro pieno: jackpot e medaglia la prima volta")
local medal
for _, b in ipairs(orders.badges(p)) do if b.id == orders.JACKPOT_BADGE then medal = b end end
local milestones = require "sim.milestones"
check(medal and milestones.valid(medal) and not milestones.valid({ id = orders.JACKPOT_BADGE, grado = 4 }),
	"la medaglia del jackpot è un badge del profilo (oro)")

-- melting
p = new()
p.commesse.frammenti.corvo = 5
check(not forge.melt(p, "corvo", "corvo"), "non si fonde nella stessa famiglia")
check(forge.melt(p, "corvo", "vuoto") and p.commesse.frammenti.corvo == 1 and p.commesse.frammenti.vuoto == 1, "4 frammenti per 1 di un'altra famiglia")
check(not forge.melt(p, "corvo", "vuoto"), "servono 4 frammenti")
before = p.scaglie
check(forge.melt(p, "corvo") and p.scaglie == before + 20 and p.commesse.frammenti.corvo == 0, "1 frammento per 20 Scaglie")
check(not forge.melt(p, "drago"), "famiglia sconosciuta")

-- the same through the profile's actions (phone and server)
p = new()
check(progress.act(p, { k = "colata", muro = TODAY .. "#0" }, TODAY), "azione colata")
AIMS = aims(forge.wall(p, TODAY .. "#0"))
local last = forge.wall(p, TODAY .. "#0")[12]
r = progress.act(p, { k = "tiro", angolo = AIMS[12][1], forza = AIMS[12][2] }, TODAY)
check(r and r.esito == "stampo" and r.scaglie == last.scaglie, "azione tiro")
check(progress.act(p, { k = "fondi", da = "fabbro" }, TODAY) == nil, "azione fondi senza frammenti")

if failures > 0 then
	print(failures .. " falliti")
	os.exit(1)
end
print("tutti ok")
