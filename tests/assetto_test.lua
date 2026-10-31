-- Test di albero di abilità, set, assetti, riconoscimenti e profilo. Dalla radice del repository:
--   luajit tests/assetto_test.lua
package.path = "client/?.lua;" .. package.path

local abilita = require "sim.abilita"
local equip = require "sim.equipaggiamento"
local assetto = require "sim.assetto"
local riconoscimenti = require "sim.riconoscimenti"
local profilo = require "menu.profilo"

local failures = 0
local function check(cond, msg)
	if cond then
		print("ok   " .. msg)
	else
		print("FAIL " .. msg)
		failures = failures + 1
	end
end

local game = require "sim.game"
local BASE = game.base_stats()

-- Regola 1: l'albero costa almeno il doppio dei punti massimi
local total = 0
for _, n in ipairs(abilita.NODES) do total = total + n.ranks * n.cost end
check(total >= 2 * abilita.POINTS_MAX, "l'albero costa " .. total .. " punti, almeno il doppio di " .. abilita.POINTS_MAX)
-- ogni chiave toccata da albero e set esiste nelle statistiche della sim
for _, n in ipairs(abilita.NODES) do
	for _, e in ipairs(n.effects) do check(BASE[e.stat] ~= nil, "albero: " .. n.id .. " tocca " .. e.stat) end
end
for _, s in ipairs(equip.SETS) do
	for slot, eff in pairs(s.pieces) do
		for _, e in ipairs(eff) do check(BASE[e.stat] ~= nil, "set: " .. s.id .. "." .. slot .. " tocca " .. e.stat) end
	end
	for v, b in pairs(s.bonus or {}) do
		for _, e in ipairs(b.effects) do check(BASE[e.stat] ~= nil, "bonus: " .. s.id .. "." .. v .. " tocca " .. e.stat) end
	end
end

-- Punti per livello
check(abilita.points(5) == 10 and abilita.points(99) == abilita.POINTS_MAX, "punti: due per livello fino al massimo")

-- Righe: la riga 2 si apre dopo ROW_GATE punti nel ramo
local t = {}
check(abilita.can_add(t, "jump", 5), "si prende un nodo della prima riga")
check(not abilita.can_add(t, "air", 5), "la seconda riga è chiusa all'inizio")
t.jump = 2
check(abilita.can_add(t, "air", 6), "con 4 punti nel ramo la seconda riga si apre")
t.air = 1
check(not abilita.can_remove(t, "jump"), "non si toglie un grado che chiude una riga usata")
check(abilita.can_remove(t, "air"), "l'ultimo nodo si toglie")
check(not abilita.can_add({ jump = 3 }, "jump", 20), "un nodo al massimo non sale")
check(not abilita.can_add({ walk = 2 }, "hp", 5), "senza punti non si prende niente")
check(not abilita.valid({ air = 1 }, 20), "un albero con una riga saltata non è valido")
check(not abilita.valid({ jump = 4 }, 20), "un albero con troppi gradi non è valido")

-- Statistiche: albero e set si sommano alla base
local a = assetto.new()
a.tree = { hp = 2 }
local st = assetto.stats(BASE, a)
check(st.max_hp == BASE.max_hp + 4, "l'albero alza la vita")
a.tree = { jump = 3 }
st = assetto.stats(BASE, a)
check(st.jump_height > BASE.jump_height, "l'albero alza il salto")
check(BASE.jump_height == game.base_stats().jump_height, "la base non cambia")

-- Regola 3: con tutti i punti, in qualunque albero valido, nessuna statistica
-- cambia più del 10% (in su o, per quelle dove meno è meglio, in giù)
local function tutti(nodi, i, tree, out)
	if i > #nodi then
		if abilita.valid(tree, abilita.POINTS_MAX) then out[#out + 1] = tree end
		return
	end
	for r = 0, nodi[i].ranks do
		local t2 = {}
		for k, v in pairs(tree) do t2[k] = v end
		t2[nodi[i].id] = r > 0 and r or nil
		tutti(nodi, i + 1, t2, out)
	end
end
local alberi = {}
tutti(abilita.NODES, 1, {}, alberi)
local peggio = 0
for _, tree in ipairs(alberi) do
	local s2 = assetto.stats(BASE, { tree = tree, gear = {}, variant = "a" })
	for _, k in ipairs({ "walk_speed", "jump_height", "air_speed", "max_hp", "trap_radius",
			"teleport_ticks", "knockback_mul", "fall_damage_mul" }) do
		peggio = math.max(peggio, math.abs(s2[k] / BASE[k] - 1))
	end
end
check(#alberi > 100 and peggio <= 0.1, string.format("%d alberi validi: al massimo %.1f%% su una statistica", #alberi, peggio * 100))

-- Set: il Vuoto completo ha il bonus, la variante B solo al tier III
a = assetto.new()
a.gear = { mask = "vuoto", chest = "vuoto", cloak = "vuoto", legs = "vuoto" }
st = assetto.stats(BASE, a)
check(st.teleport_ticks < BASE.teleport_ticks * 0.75 and st.max_hp < BASE.max_hp, "set Vuoto completo: teletrasporto più rapido, meno vita")
a.variant = "b"
st = assetto.stats(BASE, a, { mask = 1, chest = 3, cloak = 3, legs = 3 })
check(st.teleports == BASE.teleports, "la variante B vuole tutti i pezzi al tier III")
st = assetto.stats(BASE, a, { mask = 3, chest = 3, cloak = 3, legs = 3 })
check(st.teleports == BASE.teleports + 1, "tier III: variante B del Vuoto, un teletrasporto in più")
a.gear = { mask = "leviatano", chest = "leviatano", cloak = "leviatano", legs = "leviatano" }
a.variant = "a"
st = assetto.stats(BASE, a)
check(st.knockback_mul < 0.7 and st.fall_damage_mul == 0.5 and st.walk_speed < BASE.walk_speed,
	"set Leviatano completo: meno spinta, metà danno da caduta, più lento")
a.tree = { fall = 2, anchor = 1, hp = 2, parachute = 1 }
st = assetto.stats(BASE, a)
check(st.parachutes == BASE.parachutes + 1 and st.fall_damage_mul < 0.5, "albero: un paracadute in più e cadute più leggere")
a.tree = {}
a.gear = { mask = "fornace", chest = "fornace", cloak = "fornace", legs = "fornace" }
st = assetto.stats(BASE, a)
check(st.burning_blasts == 1 and st.status_turns == BASE.status_turns, "set Fornace completo: colpi brucianti")
a.variant = "b"
st = assetto.stats(BASE, a, { mask = 3, chest = 3, cloak = 3, legs = 3 })
check(st.burning_blasts == 1 and st.status_turns == BASE.status_turns + 1, "tier III: variante B della Fornace")
a.variant = "a"
a.gear = { mask = "corvo", chest = "corvo", cloak = "corvo", legs = "corvo" }
st = assetto.stats(BASE, a)
check(st.air_jumps == 1 and st.fall_damage_mul == 0, "set Corvo completo: doppio salto e caduta senza danno")
a.variant = "b"
st = assetto.stats(BASE, a, { mask = 3, chest = 3, cloak = 3, legs = 3 })
check(st.air_jumps == 2, "tier III: due salti in aria")
a.variant = "a"
a.tree = { hp = 2, fall = 2, anchor = 1, teleport = 1 }
st = assetto.stats(BASE, a)
check(st.teleports == BASE.teleports + 1, "albero: un teletrasporto in più")
a.tree = {}

a.gear = { mask = "vuoto", chest = "corvo" }
check(assetto.valid(a, 20), "assetto valido")
a.gear.mask = "drago"
check(not assetto.valid(a, 20), "un set sconosciuto non è valido")

-- Tier dalla maestria
check(equip.tier(0) == 1 and equip.tier(10) == 2 and equip.tier(500) == 3, "tier dalle partite giocate")

-- Riconoscimenti
local ranking = {
	{ robot = 2, place = 1, damage = 120, env_kills = 0, avg_attack_secs = 9, turns = 3, teleports = 1, crates = 0 },
	{ robot = 1, place = 2, damage = 90, env_kills = 2, avg_attack_secs = 4, turns = 3, teleports = 3, crates = 1 },
	{ robot = 3, place = 3, damage = 10, env_kills = 0, avg_attack_secs = 2, turns = 0, teleports = 0, crates = 0 },
}
local by, list = riconoscimenti.assign(ranking)
check(by[1] and by[1][1].id == "becchino", "Becchino a chi butta giù più nemici")
check(by[1] and by[1][2].id == "fulmine", "Fulmine al più veloce che ha giocato almeno un turno")
check(#by[1] == riconoscimenti.PER_PLAYER, "al massimo " .. riconoscimenti.PER_PLAYER .. " a testa")
check(by[2] and by[2][1].id == "martello", "Martello a chi fa più danno")
check(by[3] == nil, "chi non ha giocato non prende niente")
check(#list >= 3, "lista dei riconoscimenti in ordine")

-- Profilo: esperienza, livelli e maestria
local p = profilo.nuovo()
check(#p.assetti == assetto.LOADOUTS and p.livello == 1, "profilo nuovo: 3 assetti, livello 1")
p.assetti[1].gear = { mask = "vuoto" }
local gu = profilo.fine_partita(p, 1, { riconoscimenti.LIST[1] })
check(gu.xp == profilo.XP_POSTO[1] + profilo.XP_RICONOSCIMENTO and p.livello == 2, "il primo posto fa salire di livello")
check(p.maestria.vuoto_mask == 1, "una partita di maestria per il pezzo indossato")
check(profilo.punti(p) == 4, "punti abilità dal livello")

if failures > 0 then
	print(failures .. " test falliti")
	os.exit(1)
end
print("tutti i test superati")
