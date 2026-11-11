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
-- Families (page "I Pezzi della Forgia"): every plus from its slot's job, every stat known
for _, f in ipairs(equip.SETS) do
	for _, sl in ipairs(equip.SLOTS) do
		local pc = f.pieces[sl.id]
		local job = false
		for _, j in ipairs(equip.JOBS[sl.id]) do job = job or j == pc[1] end
		check(job and equip.STATS[pc[1]] and equip.STATS[pc[2]] and BASE[pc[1]] ~= nil and BASE[pc[2]] ~= nil and pc[1] ~= pc[2],
			"family " .. f.id .. "." .. sl.id .. ": plus from the slot's job, minus elsewhere")
	end
	check(BASE[f.pair.stat] ~= nil and equip.STATS[f.pair.stat] ~= nil, "family " .. f.id .. ": pair bonus on a known stat")
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

-- Pieces: the plus grows with the level, the minus halves at 20 and is gone at 30
check(math.abs(equip.plus("walk_speed", 1) - 0.02) < 1e-9 and math.abs(equip.plus("walk_speed", 30) - 0.049) < 1e-9,
	"plus from +2% to +4.9%")
check(equip.plus("max_hp", 1) == 2 and equip.plus("max_hp", 30) == 5, "life from +2 to +5")
check(equip.minus("walk_speed", 19) == 0.02 and equip.minus("walk_speed", 20) == 0.01 and equip.minus("walk_speed", 30) == 0,
	"minus -2%, -1% from 20, nothing at 30")
a = loadout.new()
a.gear = { legs = "fabbro" }
st = loadout.stats(BASE, a)
check(math.abs(st.walk_speed / BASE.walk_speed - 1.02) < 1e-9 and math.abs(st.jump_height / BASE.jump_height - 0.98) < 1e-9,
	"Fabbro boots at 1: run +2%, jump -2%")
st = loadout.stats(BASE, a, { legs = 30 })
check(math.abs(st.walk_speed / BASE.walk_speed - 1.049) < 1e-9 and st.jump_height == BASE.jump_height,
	"Fabbro boots at 30: run +4.9%, no minus")
a.gear = { mask = "corvo" }
st = loadout.stats(BASE, a)
check(st.teleport_ticks < BASE.teleport_ticks and st.max_hp == BASE.max_hp - 2, "Corvo helmet: faster orb, life -2")
a.gear = { mask = "leviatano", chest = "leviatano" }
st = loadout.stats(BASE, a, { mask = 19, chest = 19 })
check(st.knockback_mul > 0.96 + 1e-9, "two Leviatano pieces under 20: no family bonus")
st = loadout.stats(BASE, a, { mask = 20, chest = 20 })
check(math.abs(st.knockback_mul - (1 - 0.039 - 0.04)) < 1e-9, "two gold Leviatano pieces: their bonus, push -4% more")
check(#equip.pairs_on({ mask = "corvo", chest = "corvo", cloak = "vuoto", legs = "vuoto" },
	{ mask = 20, chest = 25, cloak = 30, legs = 20 }) == 2, "two plus two: two family bonuses")
-- the caps: pieces +10% at most, pieces and Sigilli +20% at most
a.gear = { mask = "fabbro", chest = "fabbro", cloak = "fabbro", legs = "fabbro" }
st = loadout.stats(BASE, a, { mask = 30, chest = 30, cloak = 30, legs = 30 })
check(st.max_hp == BASE.max_hp + 5 + 3, "Fabbro at 30: life +5 and the pair +3")
a.gear = { mask = "fornace", chest = "fornace" }
st = loadout.stats(BASE, a, { mask = 30, chest = 30 })
check(st.max_hp == BASE.max_hp + 10, "life +5 +5: exactly the cap of +10")
a.gear = { mask = "fornace", chest = "fornace", legs = "fabbro", cloak = "fabbro" }
st = loadout.stats(BASE, a, { mask = 30, chest = 30, legs = 30, cloak = 30 })
check(st.max_hp == BASE.max_hp + 10, "pieces never give more than +10 life")
a.gear = { legs = "fabbro" }
a.tree = { wings = 25 }
local sig = loadout.stats(BASE, { tree = a.tree, gear = {} })
st = loadout.stats(BASE, a, { legs = 30 })
check(st.walk_speed >= sig.walk_speed and st.walk_speed <= math.max(sig.walk_speed, BASE.walk_speed * 1.2) + 1e-9,
	"pieces and Sigilli together: +20% at most")
a.tree = {}
a.gear = { mask = "fabbro", cloak = "corvo" }
st = loadout.stats(BASE, a, { cloak = 30 })
check(st.max_hp == BASE.max_hp + 2 and math.abs(st.knockback_mul - 1) < 1e-9, "Corvo cape at 30: no minus left")

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
