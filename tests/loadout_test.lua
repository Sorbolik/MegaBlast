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
-- Families (14 Nov): main from the slot, two other secondaries, a minus
-- elsewhere, a signature only that piece has; two pieces of a slot never alike
local signs_seen = {}
for _, f in ipairs(equip.SETS) do
	for _, sl in ipairs(equip.SLOTS) do
		local pc = f.pieces[sl.id]
		local main = false
		for _, j in ipairs(equip.MAINS[sl.id]) do main = main or j == pc[1] end
		local all = { pc[1], pc[2][1], pc[2][2], pc[3] }
		local known, distinct = true, true
		for i, st in ipairs(all) do
			known = known and equip.STATS[st] ~= nil and BASE[st] ~= nil
			for j = i + 1, #all do distinct = distinct and all[j] ~= st end
		end
		check(main and known and distinct and #pc[2] == 2, "piece " .. f.id .. "." .. sl.id .. ": main from the slot, four different stats")
		check(equip.SIGNS[pc[4]] and BASE[pc[4]] == 0 and not signs_seen[pc[4]], "piece " .. f.id .. "." .. sl.id .. ": its own signature " .. pc[4])
		signs_seen[pc[4]] = true
	end
	check(BASE[f.pair.stat] ~= nil and equip.STATS[f.pair.stat] ~= nil, "family " .. f.id .. ": pair bonus on a known stat")
end
for _, sl in ipairs(equip.SLOTS) do
	local seen = {}
	for _, f in ipairs(equip.SETS) do
		local pc = f.pieces[sl.id]
		local k = pc[1] .. "|" .. pc[2][1] .. "|" .. pc[2][2] .. "|" .. pc[3]
		check(not seen[k], sl.id .. " of " .. f.id .. ": rows unlike every other " .. sl.id)
		seen[k] = true
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

-- Pieces: the rows grow from 20% at level 1 to all at 30, with a jump at each step
local function near(x, y) return math.abs(x - y) < 1e-9 end
check(near(equip.growth(1), 0.2) and near(equip.growth(30), 1) and equip.growth(10) - equip.growth(9) > 2 * (equip.growth(9) - equip.growth(8)),
	"growth: 20% at 1, all at 30, the step is felt")
local rows = equip.piece("fabbro", "mask", 30)
check(rows[1].row == "main" and near(rows[1].good, equip.MAIN) and near(rows[2].good, equip.SECOND)
	and near(rows[4].good, -equip.MINUS) and rows[5].row == "sign" and near(rows[5].good, equip.SIGNS.sig_sword.max),
	"Fabbro helmet at 30: main, secondaries, minus, signature full")
check(equip.piece("fabbro", "mask", 9)[5].good == 0 and near(equip.piece("fabbro", "mask", 10)[5].good, equip.SIGNS.sig_sword.max / 2),
	"the signature lights up at the step 10, at half")
check(near(equip.piece("fabbro", "mask", 1)[4].good, -equip.MINUS), "the minus is there from level 1 and stays")
a = loadout.new()
a.gear = { mask = "fabbro" }
st = loadout.stats(BASE, a, { mask = 30 })
check(st.attack == 25 and st.max_hp == BASE.max_hp + 10 and near(st.walk_speed / BASE.walk_speed, 0.92) and st.sig_sword == 0.2,
	"Fabbro helmet at 30: Attack +25, life +10, run -8%, Lama +20%")
st = loadout.stats(BASE, a)
check(st.attack == 5 and st.sig_sword == 0, "at level 1: Attack +5, no signature")
-- a build all on Attack: main of the helmet and three secondaries
a.gear = { mask = "fabbro", chest = "fabbro", legs = "fornace", cloak = "fornace" }
st = loadout.stats(BASE, a, { mask = 30, chest = 30, legs = 30, cloak = 30 })
check(st.attack == 55, "all on Attack: +55")
-- the caps: movement from the pieces +25% at most
a.gear = { legs = "corvo", cloak = "corvo", mask = "corvo", chest = "corvo" }
st = loadout.stats(BASE, a, { mask = 30, chest = 30, legs = 30, cloak = 30 })
check(near(st.jump_height / BASE.jump_height, 1 + equip.CAP_PIECES.move), "Corvo jump: capped at +25%")
a.gear = { legs = "corvo" }
a.tree = { wings = 25, pick = { wings = { 2 } } }
local sig = loadout.stats(BASE, { tree = a.tree, gear = {} })
st = loadout.stats(BASE, a, { legs = 30 })
check(st.jump_height >= sig.jump_height and st.jump_height <= math.max(sig.jump_height, BASE.jump_height * (1 + equip.CAP_ALL.move)) + 1e-9,
	"pieces and Sigilli together: movement +30% at most")
a.tree = {}
a.gear = { mask = "leviatano", chest = "leviatano" }
local k19 = loadout.stats(BASE, a, { mask = 19, chest = 19 }).knockback_mul
local k20 = loadout.stats(BASE, a, { mask = 20, chest = 20 }).knockback_mul
check(k20 < k19 * (1 - 0.039), "two gold Leviatano pieces: their bonus too")
check(#equip.pairs_on({ mask = "corvo", chest = "corvo", cloak = "vuoto", legs = "vuoto" },
	{ mask = 20, chest = 25, cloak = 30, legs = 20 }) == 2, "two plus two: two family bonuses")
-- the level by itself: nothing at 1, Attack and life +10 at 50, a jump every ten levels
check(next(skills.level_bonus(1)) == nil or (skills.level_bonus(1).attack == 0 and skills.level_bonus(1).max_hp == 0), "level 1: nothing")
check(skills.level_bonus(50).attack == 10 and skills.level_bonus(50).max_hp == 10, "level 50: Attack and life +10")
check(skills.level_share(10) - skills.level_share(9) > 3 * (skills.level_share(9) - skills.level_share(8)), "level 10 is felt")
st = loadout.stats(BASE, loadout.new(), nil, 50)
check(st.attack == 10 and st.max_hp == BASE.max_hp + 10, "a level 50 devil with nothing: Attack 10, life 110")

-- In the match: damage = weapon x (100 + Attack) / (100 + Defense), signatures on top
local function duel(s1, s2)
	local g = game.new(42, "pavimento", { players = { { team = 1, stats = s1 }, { team = 2, stats = s2 } } })
	return g, g.robots[1], g.robots[2]
end
local g, r1, r2 = duel({ attack = 25 }, { defense = 25 })
local hp = r2.hp
g:hurt(r2, 40, r1)
check(hp - r2.hp == 40, "Attack 25 against Defense 25: the same damage")
g, r1, r2 = duel({ attack = 50 }, {})
hp = r2.hp
g:hurt(r2, 40, r1)
check(hp - r2.hp == 60, "Attack 50: x1.5")
g, r1, r2 = duel({}, { defense = 100 })
hp = r2.hp
g:hurt(r2, 40, r1)
check(hp - r2.hp == 20, "Defense 100: half, like double life")
g, r1, r2 = duel({ sig_sword = 0.2 }, {})
hp = r2.hp
g:hurt(r2, 40, r1, nil, "sword")
check(hp - r2.hp == 48, "Mano del mestiere: the Lama +20%")
hp = r2.hp
g:hurt(r2, 40, r1, nil, "mallet")
check(hp - r2.hp == 40, "...only the Lama")
g, r1, r2 = duel({}, { sig_thorns = 1 })
g:hurt(r2, 10, r1, nil, "mallet")
check(r1.status.burn ~= nil, "Brace addosso: who hits up close burns")
g, r1, r2 = duel({ sig_self = 0.5 }, {})
hp = r1.hp
g:hurt(r1, 40, r1)
check(hp - r1.hp == 20, "Guscio di bottega: your blasts hurt you half")
g, r1, r2 = duel({}, { sig_first_guard = 0.2 })
hp = r2.hp
g:hurt(r2, 40, r1)
g:hurt(r2, 40, r1)
check(hp - r2.hp == 32 + 40, "Pelle dura: only the first hit of the turn")

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
