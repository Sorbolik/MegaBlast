-- Tests of skill tree, sets, loadouts, awards and profile. From the repository root:
--   luajit tests/loadout_test.lua
package.path = "client/?.lua;" .. package.path

local abilita = require "sim.skills"
local equip = require "sim.gear"
local assetto = require "sim.loadout"
local riconoscimenti = require "sim.awards"
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

-- Rule 1: the tree costs at least twice the maximum points
local total = 0
for _, n in ipairs(abilita.NODES) do total = total + n.ranks * n.cost end
check(total >= 2 * abilita.POINTS_MAX, "the tree costs " .. total .. " points, at least twice " .. abilita.POINTS_MAX)
-- every key touched by tree and sets exists in the sim stats
for _, n in ipairs(abilita.NODES) do
	for _, e in ipairs(n.effects) do check(BASE[e.stat] ~= nil, "tree: " .. n.id .. " touches " .. e.stat) end
end
for _, s in ipairs(equip.SETS) do
	for slot, eff in pairs(s.pieces) do
		for _, e in ipairs(eff) do check(BASE[e.stat] ~= nil, "set: " .. s.id .. "." .. slot .. " touches " .. e.stat) end
	end
	for v, b in pairs(s.bonus or {}) do
		for _, e in ipairs(b.effects) do check(BASE[e.stat] ~= nil, "bonus: " .. s.id .. "." .. v .. " touches " .. e.stat) end
	end
end

-- Points per level
check(abilita.points(5) == 10 and abilita.points(99) == abilita.POINTS_MAX, "points: two per level up to the maximum")

-- Rows: row 2 opens after ROW_GATE points in the branch
local t = {}
check(abilita.can_add(t, "jump", 5), "a first row node can be taken")
check(not abilita.can_add(t, "air", 5), "the second row is closed at the start")
t.jump = 2
check(abilita.can_add(t, "air", 6), "with 4 points in the branch the second row opens")
t.air = 1
check(not abilita.can_remove(t, "jump"), "a rank that closes a used row can't be removed")
check(abilita.can_remove(t, "air"), "the last node can be removed")
check(not abilita.can_add({ jump = 3 }, "jump", 20), "a maxed node doesn't go up")
check(not abilita.can_add({ walk = 2 }, "hp", 5), "without points nothing can be taken")
check(not abilita.valid({ air = 1 }, 20), "a tree with a skipped row isn't valid")
check(not abilita.valid({ jump = 4 }, 20), "a tree with too many ranks isn't valid")

-- Stats: tree and sets add to the base
local a = assetto.new()
a.tree = { hp = 2 }
local st = assetto.stats(BASE, a)
check(st.max_hp == BASE.max_hp + 4, "the tree raises life")
a.tree = { jump = 3 }
st = assetto.stats(BASE, a)
check(st.jump_height > BASE.jump_height, "the tree raises the jump")
check(BASE.jump_height == game.base_stats().jump_height, "the base doesn't change")

-- Rule 3: with all points, in any valid tree, no stat changes more than 10%
-- (up or, for those where less is better, down)
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
local trees = {}
tutti(abilita.NODES, 1, {}, trees)
local peggio = 0
for _, tree in ipairs(trees) do
	local s2 = assetto.stats(BASE, { tree = tree, gear = {}, variant = "a" })
	for _, k in ipairs({ "walk_speed", "jump_height", "air_speed", "max_hp", "trap_radius",
			"teleport_ticks", "knockback_mul", "fall_damage_mul" }) do
		peggio = math.max(peggio, math.abs(s2[k] / BASE[k] - 1))
	end
end
check(#trees > 100 and peggio <= 0.1, string.format("%d valid trees: at most %.1f%% on one stat", #trees, peggio * 100))

-- Sets: the full Vuoto has the bonus, variant B only at tier III
a = assetto.new()
a.gear = { mask = "vuoto", chest = "vuoto", cloak = "vuoto", legs = "vuoto" }
st = assetto.stats(BASE, a)
check(st.teleport_ticks < BASE.teleport_ticks * 0.75 and st.max_hp < BASE.max_hp, "full Vuoto set: faster teleport, less life")
a.variant = "b"
st = assetto.stats(BASE, a, { mask = 1, chest = equip.TIERS, cloak = equip.TIERS, legs = equip.TIERS })
check(st.teleports == BASE.teleports, "variant B needs all pieces at tier III")
st = assetto.stats(BASE, a, { mask = equip.TIERS, chest = equip.TIERS, cloak = equip.TIERS, legs = equip.TIERS })
check(st.teleports == BASE.teleports + 1, "tier III: Vuoto variant B, one more teleport")
a.gear = { mask = "leviatano", chest = "leviatano", cloak = "leviatano", legs = "leviatano" }
a.variant = "a"
st = assetto.stats(BASE, a)
check(st.knockback_mul < 0.7 and st.fall_damage_mul == 0.5 and st.walk_speed < BASE.walk_speed,
	"full Leviatano set: less push, half fall damage, slower")
a.tree = { fall = 2, anchor = 1, hp = 2, parachute = 1 }
st = assetto.stats(BASE, a)
check(st.parachutes == BASE.parachutes + 1 and st.fall_damage_mul < 0.5, "tree: one more parachute and lighter falls")
a.tree = {}
a.gear = { mask = "fornace", chest = "fornace", cloak = "fornace", legs = "fornace" }
st = assetto.stats(BASE, a)
check(st.burning_blasts == 1 and st.status_turns == BASE.status_turns, "full Fornace set: burning shots")
a.variant = "b"
st = assetto.stats(BASE, a, { mask = equip.TIERS, chest = equip.TIERS, cloak = equip.TIERS, legs = equip.TIERS })
check(st.burning_blasts == 1 and st.status_turns == BASE.status_turns + 1, "tier III: Fornace variant B")
a.variant = "a"
a.gear = { mask = "corvo", chest = "corvo", cloak = "corvo", legs = "corvo" }
st = assetto.stats(BASE, a)
check(st.air_jumps == 1 and st.fall_damage_mul == 0, "full Corvo set: double jump and fall without damage")
a.variant = "b"
st = assetto.stats(BASE, a, { mask = equip.TIERS, chest = equip.TIERS, cloak = equip.TIERS, legs = equip.TIERS })
check(st.air_jumps == 2, "tier III: two air jumps")
a.variant = "a"
a.tree = { hp = 2, fall = 2, anchor = 1, teleport = 1 }
st = assetto.stats(BASE, a)
check(st.teleports == BASE.teleports + 1, "tree: one more teleport")
a.tree = {}

a.gear = { mask = "vuoto", chest = "corvo" }
check(assetto.valid(a, 20), "valid loadout")
a.gear.mask = "drago"
check(not assetto.valid(a, 20), "an unknown set isn't valid")

-- Tier from mastery
check(equip.tier(0) == 1 and equip.tier(10) == 2 and equip.tier(20) == 3 and equip.tier(500) == equip.TIERS,
	"tier from matches played, one per step")
check(equip.tier(29) < equip.TIERS and equip.tier(30) == equip.TIERS, "variant B at 30 matches with each piece, as before")
check(equip.livello(0) == 0 and equip.livello(12) == 12 and equip.livello(99) == equip.LIVELLO_MAX, "piece level")
check(equip.prossimo_scatto(12) == 20 and equip.prossimo_scatto(30) == nil, "next step")

-- Awards
local ranking = {
	{ robot = 2, place = 1, damage = 120, env_kills = 0, avg_attack_secs = 9, turns = 3, teleports = 1, crates = 0 },
	{ robot = 1, place = 2, damage = 90, env_kills = 2, avg_attack_secs = 4, turns = 3, teleports = 3, crates = 1 },
	{ robot = 3, place = 3, damage = 10, env_kills = 0, avg_attack_secs = 2, turns = 0, teleports = 0, crates = 0 },
}
local by, list = riconoscimenti.assign(ranking)
check(by[1] and by[1][1].id == "becchino", "Becchino to whoever knocks down the most enemies")
check(by[1] and by[1][2].id == "fulmine", "Fulmine to the fastest who played at least one turn")
check(#by[1] == riconoscimenti.PER_PLAYER, "at most " .. riconoscimenti.PER_PLAYER .. " each")
check(by[2] and by[2][1].id == "martello", "Martello to whoever does the most damage")
check(by[3] == nil, "whoever didn't play gets nothing")
check(#list >= 3, "list of awards in order")

-- Profile: experience, levels and mastery
local p = profilo.nuovo()
check(#p.assetti == assetto.LOADOUTS and p.livello == 1, "new profile: 3 loadouts, level 1")
p.assetti[1].gear = { mask = "vuoto" }
local gu = profilo.fine_partita(p, 1, { riconoscimenti.LIST[1] })
check(gu.xp == profilo.XP_POSTO[1] + profilo.XP_RICONOSCIMENTO and p.livello == 2, "first place levels you up")
check(p.maestria.vuoto_mask == 1, "a mastery match for the worn piece")
check(profilo.punti(p) == 4, "skill points from the level")

if failures > 0 then
	print(failures .. " tests failed")
	os.exit(1)
end
print("all tests passed")
