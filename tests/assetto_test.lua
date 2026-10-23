-- Test di albero di abilità, set, assetti e riconoscimenti. Dalla radice del repository:
--   luajit tests/assetto_test.lua
package.path = "client/?.lua;" .. package.path
-- le schermate caricano la palette di ui/ui.lua: basta un finto vmath
local function vec(x, y, z, w) return { x = x, y = y, z = z, w = w } end
vmath = { vector3 = vec, vector4 = vec }

local abilita = require "sim.abilita"
local equip = require "sim.equipaggiamento"
local assetto = require "sim.assetto"
local riconoscimenti = require "sim.riconoscimenti"
local profilo = require "menu.profilo"
local eventi = require "menu.eventi"

local failures = 0
local function check(cond, msg)
	if cond then
		print("ok   " .. msg)
	else
		print("FAIL " .. msg)
		failures = failures + 1
	end
end

-- statistiche base finte: le vere sono in config.STATS della sim
local BASE = {
	walk_speed = 70, jump_height = 56, air_speed = 90, max_hp = 150, teleport_ticks = 120,
	teleport_cost = 1, parachute_cost = 1, shield_cost = 2, air_jumps = 0, air_jump_cost = 1,
	start_nucleo = 1, status_ticks = 60, trap_radius = 24, fall_damage_mul = 1, knockback_mul = 1,
	free_parachutes = 0, free_teleports = 0, burning_blasts = false,
}

-- Regola 1: l'albero costa almeno il doppio dei punti massimi
local total = 0
for _, n in ipairs(abilita.NODES) do total = total + n.ranks * n.cost end
check(total >= 2 * abilita.POINTS_MAX, "l'albero costa " .. total .. " punti, almeno il doppio di " .. abilita.POINTS_MAX)
-- ogni chiave toccata dall'albero esiste nelle statistiche
for _, n in ipairs(abilita.NODES) do
	for _, e in ipairs(n.effects) do check(BASE[e.stat] ~= nil, "albero: " .. n.id .. " tocca " .. e.stat) end
end
for _, s in ipairs(equip.SETS) do
	for slot, eff in pairs(s.pieces) do
		for _, e in ipairs(eff) do check(BASE[e.stat] ~= nil, "set: " .. s.id .. "." .. slot .. " tocca " .. e.stat) end
	end
end

-- Punti per livello e Torneo
check(abilita.points(5) == 5 and abilita.points(99) == abilita.POINTS_MAX, "punti: uno per livello fino al massimo")
check(abilita.points(1, true) == abilita.POINTS_MAX, "in Torneo tutti hanno i punti massimi")

-- Righe: la riga 2 si apre dopo ROW_GATE punti nel ramo
local t = {}
check(abilita.can_add(t, "jump", 5), "si prende un nodo della prima riga")
check(not abilita.can_add(t, "air", 5), "la seconda riga è chiusa all'inizio")
t.jump = 3
check(abilita.can_add(t, "air", 5), "con 3 punti nel ramo la seconda riga si apre")
t.air = 1
check(not abilita.can_remove(t, "jump"), "non si toglie un grado che chiude una riga usata")
check(abilita.can_remove(t, "air"), "l'ultimo nodo si toglie")
check(not abilita.can_add(t, "jump", 5), "un nodo al massimo non sale")
check(not abilita.can_add({ walk = 3, jump = 2 }, "hp", 5), "senza punti non si prende niente")
check(not abilita.valid({ air = 1 }, 20), "un albero con una riga saltata non è valido")
check(not abilita.valid({ jump = 4 }, 20), "un albero con troppi gradi non è valido")

-- Statistiche: albero e set si sommano alla base
local a = assetto.new()
a.tree = { jump = 3, walk = 1 }
local st = assetto.stats(BASE, a)
check(st.jump_height == 65 and st.walk_speed == 74, "l'albero alza salto e corsa")
check(BASE.jump_height == 56, "la base non cambia")

a.gear = { mask = "corvo", chest = "corvo", cloak = "corvo", legs = "corvo" }
st = assetto.stats(BASE, a)
check(st.air_jumps == 1 and st.air_jump_cost == 0 and st.fall_damage_mul == 0, "set Corvo completo: doppio salto e niente caduta")
check(st.max_hp == math.floor((150 - 5) * 0.9 + 0.5), "set Corvo: vita -10% dopo i pezzi")
a.variant = "b"
st = assetto.stats(BASE, a, { mask = 1, chest = 3, cloak = 3, legs = 3 })
check(st.fall_damage_mul == 0, "la variante B vuole tutti i pezzi al tier III")
st = assetto.stats(BASE, a, { mask = 3, chest = 3, cloak = 3, legs = 3 })
check(st.fall_damage_mul == 1 and st.air_speed > BASE.air_speed, "tier III: variante B del Corvo")

a.gear = { mask = "vuoto", chest = "corvo" }
st = assetto.stats(BASE, a)
check(st.air_jumps == 0, "pezzi di set diversi: niente bonus")
check(assetto.valid(a, 20), "assetto valido")
a.gear.mask = "drago"
check(not assetto.valid(a, 20), "un set sconosciuto non è valido")

-- Nessuna combinazione sposta una statistica di movimento più del 25%
local best = assetto.new()
best.tree = { jump = 3, walk = 3, air = 3, orb_fast = 2, air_jump = 1 }
best.gear = { mask = "corvo", chest = "corvo", cloak = "corvo", legs = "corvo" }
best.variant = "b"
st = assetto.stats(BASE, best, { mask = 3, chest = 3, cloak = 3, legs = 3 })
check(st.air_speed <= BASE.air_speed * 1.25 and st.jump_height <= BASE.jump_height * 1.25,
	"massimo di Mobilità e Corvo: entro il 25% della base")

-- Tier dalla maestria
check(equip.tier(0) == 1 and equip.tier(10) == 2 and equip.tier(500) == 3, "tier dalle partite giocate")

-- Riconoscimenti
local ranking = {
	{ robot = 2, place = 1, damage = 120, env_kills = 0, avg_attack_secs = 9, turns = 3, teleports = 1, nucleo_spent = 1, crates = 0 },
	{ robot = 1, place = 2, damage = 90, env_kills = 2, avg_attack_secs = 4, turns = 3, teleports = 3, nucleo_spent = 3, crates = 1 },
	{ robot = 3, place = 3, damage = 10, env_kills = 0, avg_attack_secs = 2, turns = 0, teleports = 0, nucleo_spent = 0, crates = 0 },
}
local by, list = riconoscimenti.assign(ranking)
check(by[1] and by[1][1].id == "becchino", "Becchino a chi butta giù più nemici")
check(by[1] and by[1][2].id == "fulmine", "Fulmine al più veloce che ha giocato almeno un turno")
check(#by[1] == riconoscimenti.PER_PLAYER, "al massimo " .. riconoscimenti.PER_PLAYER .. " a testa")
check(by[2] and by[2][1].id == "martello", "Martello a chi fa più danno")
check(by[3] == nil, "chi non ha giocato non prende niente")
check(#list >= 3, "lista dei riconoscimenti in ordine")

-- Profilo: esperienza, livelli, Scorie e maestria
local p = profilo.nuovo()
check(#p.assetti == assetto.LOADOUTS and p.livello == 1, "profilo nuovo: 3 assetti, livello 1")
p.assetti[1].gear = { mask = "vuoto" }
local gu = profilo.fine_partita(p, 1, { riconoscimenti.LIST[1] })
check(gu.xp == profilo.XP_POSTO[1] + profilo.XP_RICONOSCIMENTO and p.livello == 2, "il primo posto fa salire di livello")
check(p.scorie == profilo.SCORIE_INIZIO + profilo.SCORIE_POSTO[1], "Scorie del primo posto")
check(p.maestria.vuoto_mask == 1, "una partita di maestria per il pezzo indossato")
check(profilo.punti(p) == 2 and profilo.punti(p, true) == abilita.POINTS_MAX, "punti abilità dal livello, in Torneo il massimo")

-- Eventi: le prossime due settimane, in ordine, senza quelli già finiti
local adesso = os.time({ year = 2026, month = 10, day = 24, hour = 23 }) -- sabato sera, Torneo finito
local lista = eventi.prossimi(adesso)
check(#lista > 0 and lista[1].data.wday == 1, "il primo evento dopo il Torneo finito è domenica")
local adesso2 = os.time({ year = 2026, month = 10, day = 24, hour = 16 })
check(eventi.prossimi(adesso2)[1].in_corso, "il Torneo del sabato pomeriggio è in corso")

if failures > 0 then
	print(failures .. " test falliti")
	os.exit(1)
end
print("tutti i test superati")
