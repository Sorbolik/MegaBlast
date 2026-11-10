-- Tests of skill tree, sets, loadouts, awards and profile. From the repository root:
--   luajit tests/loadout_test.lua
package.path = "client/?.lua;" .. package.path

local skills = require "sim.skills"
local equip = require "sim.gear"
local loadout = require "sim.loadout"
local awards = require "sim.awards"
local profile = require "menu.profile"

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

-- Rule 1: three paths of PATH_MAX for POINTS_MAX points: you can't fill them all
check(#skills.PATHS * skills.PATH_MAX > skills.POINTS_MAX, "the paths hold " .. #skills.PATHS * skills.PATH_MAX
	.. " points, more than the " .. skills.POINTS_MAX .. " you get")
check(skills.POINTS_MAX == skills.LEVEL_MAX and skills.points(1) == 1 and skills.points(99) == skills.POINTS_MAX,
	"one point per level, up to the maximum")
-- every path has a pair of powers at each threshold, every key exists in the sim stats
for _, p in ipairs(skills.PATHS) do
	check(#p.steps == skills.STEPS, p.id .. ": a threshold every " .. skills.STEP .. " points")
	for _, e in ipairs(p.per_point) do check(BASE[e.stat] ~= nil, p.id .. " per point touches " .. e.stat) end
	for k, pair in ipairs(p.steps) do
		check(#pair == 2, p.id .. " threshold " .. k .. ": two powers")
		for _, w in ipairs(pair) do
			for _, e in ipairs(w.effects) do check(BASE[e.stat] ~= nil, p.id .. ": " .. w.name .. " touches " .. e.stat) end
		end
	end
end
for _, s in ipairs(equip.SETS) do
	for slot, eff in pairs(s.pieces) do
		for _, e in ipairs(eff) do check(BASE[e.stat] ~= nil, "set: " .. s.id .. "." .. slot .. " touches " .. e.stat) end
	end
	for v, b in pairs(s.bonus or {}) do
		for _, e in ipairs(b.effects) do check(BASE[e.stat] ~= nil, "bonus: " .. s.id .. "." .. v .. " touches " .. e.stat) end
	end
end

-- Points: they go in and out of a path, never over the path or the level
local t = {}
check(skills.move(t, "wings", 3, 10) == 3 and t.wings == 3, "three points in ALI")
check(skills.move(t, "armor", 20, 10) == 7 and skills.spent(t) == 10, "no more points than the level gives")
check(skills.move(t, "wings", 30, 50) == 22 and t.wings == skills.PATH_MAX, "a path stops at " .. skills.PATH_MAX)
check(not skills.can_add(t, "wings", 50) and skills.can_add(t, "forge", 50), "a full path takes no more")
check(skills.move(t, "armor", -9, 50) == 7 and t.armor == nil, "points come out down to zero")
check(skills.reached(t, "wings") == skills.STEPS and skills.to_choose(t) == "wings", "a reached threshold asks to choose")
skills.choose(t, "wings", 1, 2)
check(skills.pick(t, "wings", 1) == 2 and select(2, skills.to_choose(t)) == 2, "the choice is kept, the next one asks")
check(skills.valid(t, 50) and not skills.valid(t, 20), "the tree is valid only with enough points")
check(not skills.valid({ wings = 26 }, 50) and not skills.valid({ nodo = 1 }, 50)
	and not skills.valid({ pick = { wings = { 3 } } }, 50), "too many points, unknown paths, wrong picks aren't valid")

-- Stats: points and powers add to the base; a pick counts only on its reached threshold
local a = loadout.new()
a.tree = { armor = 10 }
local st = loadout.stats(BASE, a)
check(st.max_hp == BASE.max_hp + 4, "10 CORAZZA points: life +4")
a.tree = { armor = 10, pick = { armor = { 1, 2 } } }
st = loadout.stats(BASE, a)
check(st.max_hp == BASE.max_hp + 9 and st.start_shields == 1, "Crosta and Scudo pronto")
a.tree = { armor = 4, pick = { armor = { 1 } } }
st = loadout.stats(BASE, a)
check(st.max_hp == BASE.max_hp + 2, "a pick before its threshold gives nothing")
a.tree = { wings = 25 }
st = loadout.stats(BASE, a)
check(st.jump_height > BASE.jump_height and BASE.jump_height == game.base_stats().jump_height, "ALI raises the jump, the base doesn't change")

-- Rule 3: all the points of a path raise its stat 10% at most, without powers
for _, p in ipairs(skills.PATHS) do
	local s2 = loadout.stats(BASE, { tree = { [p.id] = skills.PATH_MAX }, gear = {}, variant = "a" })
	for _, e in ipairs(p.per_point) do
		local d = math.abs(s2[e.stat] / BASE[e.stat] - 1)
		check(d <= 0.1 + 1e-9, string.format("%s full: %s %+.1f%%", p.id, e.stat, d * 100))
	end
end

-- Sets: the full Vuoto has the bonus, variant B only at tier III
a = loadout.new()
a.gear = { mask = "vuoto", chest = "vuoto", cloak = "vuoto", legs = "vuoto" }
st = loadout.stats(BASE, a)
check(st.teleport_ticks < BASE.teleport_ticks * 0.75 and st.max_hp < BASE.max_hp, "full Vuoto set: faster teleport, less life")
a.variant = "b"
st = loadout.stats(BASE, a, { mask = 1, chest = equip.TIERS, cloak = equip.TIERS, legs = equip.TIERS })
check(st.teleports == BASE.teleports, "variant B needs all pieces at tier III")
st = loadout.stats(BASE, a, { mask = equip.TIERS, chest = equip.TIERS, cloak = equip.TIERS, legs = equip.TIERS })
check(st.teleports == BASE.teleports + 1, "tier III: Vuoto variant B, one more teleport")
a.gear = { mask = "leviatano", chest = "leviatano", cloak = "leviatano", legs = "leviatano" }
a.variant = "a"
st = loadout.stats(BASE, a)
check(st.knockback_mul < 0.7 and st.fall_damage_mul == 0.5 and st.walk_speed < BASE.walk_speed,
	"full Leviatano set: less push, half fall damage, slower")
a.tree = { wings = 10, armor = 5, pick = { wings = { 1, 2 }, armor = { 2 } } }
st = loadout.stats(BASE, a)
check(st.parachutes == BASE.parachutes + 1 and st.fall_damage_mul < 0.5, "tree: one more parachute and lighter falls")
a.tree = {}
a.gear = { mask = "fornace", chest = "fornace", cloak = "fornace", legs = "fornace" }
st = loadout.stats(BASE, a)
check(st.burning_blasts == 1 and st.status_turns == BASE.status_turns, "full Fornace set: burning shots")
a.variant = "b"
st = loadout.stats(BASE, a, { mask = equip.TIERS, chest = equip.TIERS, cloak = equip.TIERS, legs = equip.TIERS })
check(st.burning_blasts == 1 and st.status_turns == BASE.status_turns + 1, "tier III: Fornace variant B")
a.variant = "a"
a.gear = { mask = "corvo", chest = "corvo", cloak = "corvo", legs = "corvo" }
st = loadout.stats(BASE, a)
check(st.air_jumps == 1 and st.fall_damage_mul == 0, "full Corvo set: double jump and fall without damage")
a.variant = "b"
st = loadout.stats(BASE, a, { mask = equip.TIERS, chest = equip.TIERS, cloak = equip.TIERS, legs = equip.TIERS })
check(st.air_jumps == 2, "tier III: two air jumps")
a.variant = "a"
a.tree = { wings = 15, pick = { wings = { 1, 1, 2 } } }
st = loadout.stats(BASE, a)
check(st.teleports == BASE.teleports + 1, "tree: one more teleport")
a.tree = {}

a.gear = { mask = "vuoto", chest = "corvo" }
check(loadout.valid(a, 20), "valid loadout")
a.gear.mask = "drago"
check(not loadout.valid(a, 20), "an unknown set isn't valid")

-- Tier from the piece's level, and the price list (page "Scaglie e Ossidiana")
check(equip.tier(1) == 1 and equip.tier(10) == 2 and equip.tier(20) == 3 and equip.tier(30) == equip.TIERS,
	"tier from the level, one per step")
check(equip.tier(29) < equip.TIERS, "variant B only at 30")
check(equip.next_tier(12) == 20 and equip.next_tier(30) == nil, "next step")
local total = 0
for l = 2, equip.LIVELLO_MAX do total = total + equip.cost(l) end
check(total == 3050 and equip.cost(2) == 15 and equip.cost(10) == 150 and equip.cost(30) == 450 and equip.cost(31) == nil,
	"a piece at 30 costs 3,050 Scaglie")
check(equip.cost(10, true) == 105 and equip.cost(2, true) == 10, "the Smith's hand: 30% off, rounded to 5")
check(equip.proof(10) == 3 and equip.proof(20) == 5 and equip.proof(30) == 8 and equip.proof(11) == 0, "the steps ask for a Proof")

-- Awards
local ranking = {
	{ robot = 2, place = 1, damage = 120, env_kills = 0, avg_attack_secs = 9, turns = 3, teleports = 1, crates = 0 },
	{ robot = 1, place = 2, damage = 90, env_kills = 2, avg_attack_secs = 4, turns = 3, teleports = 3, crates = 1 },
	{ robot = 3, place = 3, damage = 10, env_kills = 0, avg_attack_secs = 2, turns = 0, teleports = 0, crates = 0 },
}
local by, list = awards.assign(ranking)
check(by[1] and by[1][1].id == "becchino", "Becchino to whoever knocks down the most enemies")
check(by[1] and by[1][2].id == "fulmine", "Fulmine to the fastest who played at least one turn")
check(#by[1] == awards.PER_PLAYER, "at most " .. awards.PER_PLAYER .. " each")
check(by[2] and by[2][1].id == "martello", "Martello to whoever does the most damage")
check(by[3] == nil, "whoever didn't play gets nothing")
check(#list >= 3, "list of awards in order")

-- Profile: experience, levels and the Proof of the pieces
local p = profile.new()
check(#p.loadouts == loadout.LOADOUTS and p.livello == 1, "new profile: 3 loadouts, level 1")
p.loadouts[1].gear = { mask = "vuoto", chest = "corvo" }
p.pezzi.vuoto_mask = 9
local gu = profile.match_end(p, { points = 148, won = true, mvp = true, awards = { awards.LIST[1] } })
local x = profile.XP
check(gu.xp == x.match + 74 + x.win + x.mvp + x.award and #gu.lines == 5, "receipt: match, points 148 -> 74, win, MVP, award")
check(p.livello == 2 and gu.level_before == 1 and gu.livello == 2, "a good win levels you up")
check(p.prova.vuoto_mask == 1 and p.prova.corvo_chest == nil, "a match for the Proof of the piece one level below a step")
check(profile.points(p) == 2, "a Sigilli point per level")
gu = profile.match_end(p, { points = 1000, won = false })
check(gu.lines[2].xp == x.points_max and #gu.lines == 2, "the points give at most " .. x.points_max)
gu = profile.match_end(p, { points = 0, second = true })
check(#gu.lines == 2 and gu.lines[2].key == "second", "second in free for all")
-- after the last level: braci
p.livello, p.xp = profile.LEVEL_MAX, 0
gu = profile.match_end(p, { points = 240, won = true, mvp = true })
gu = profile.match_end(p, { points = 240, won = true, mvp = true })
for _ = 1, 4 do gu = profile.match_end(p, { points = 240, won = true, mvp = true }) end
check(p.livello == profile.LEVEL_MAX and p.braci >= 1, "past level " .. profile.LEVEL_MAX .. " the bar gives braci")
-- campaign levels: first time, new stars, replay
p = profile.new()
gu = profile.mission(p, "primo_sangue", { true, true, false })
check(gu.xp == profile.XP_MISSION.done + 2 * profile.XP_MISSION.star, "first time with two stars")
gu = profile.mission(p, "primo_sangue", { true, false, true })
check(gu.xp == profile.XP_MISSION.star, "one new star")
gu = profile.mission(p, "primo_sangue", { true, true, true })
check(gu.xp == profile.XP_MISSION.replay and gu.lines[1].key == "replay", "nothing new: replay")
-- loadouts open with the level
check(loadout.open(1, 1) and not loadout.open(2, 14) and loadout.open(2, 15) and not loadout.open(3, 29)
	and loadout.open(3, 30), "loadouts 2 and 3 at levels 15 and 30")
-- MVP: most points, even losing
check(awards.mvp({ { robot = 1, points = 80 }, { robot = 2, points = 120 } }) == 2
	and awards.mvp({ { robot = 1, points = 0 } }) == nil, "MVP: most points, nobody without points")

if failures > 0 then
	print(failures .. " tests failed")
	os.exit(1)
end
print("all tests passed")
