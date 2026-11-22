-- Loadout: skill tree plus gear, and the robot stats that come out of them.
-- Pure Lua: the client sends it to the server, which checks it with valid()
-- and passes stats() to the match (opts.stats[i]).
--
-- A loadout: { tree = { wings = 18, ..., pick = ... } (sim/skills.lua), gear = { mask = "corvo", ... }, variant = "a" | "b" }
-- (variant: of the four-piece style, which comes with the next PR)
-- It can be rebuilt for free outside a match; each player keeps LOADOUTS of them,
-- the second and third open at the levels of LOADOUT_LEVELS.

local skills = require "sim.skills"
local equip = require "sim.gear"
local rng = require "sim.rng"

local M = {}

M.LOADOUTS = 3
M.LOADOUT_LEVELS = { 1, 15, 30 }

-- is loadout i open at this player level?
function M.open(i, level)
	return (level or 1) >= (M.LOADOUT_LEVELS[i] or math.huge)
end

-- stat limits after tree and sets
M.MIN = { max_hp = 1, teleport_ticks = 30, teleports = 0, parachutes = 0 }

function M.new()
	return { tree = {}, gear = {}, variant = "a" }
end

-- Applies the effect groups (a piece, a rank, a bonus): sums first, then
-- multiplications
local function apply(st, mods)
	for _, g in ipairs(mods) do
		for _, e in ipairs(g) do if e.add then st[e.stat] = st[e.stat] + e.add end end
	end
	for _, g in ipairs(mods) do
		for _, e in ipairs(g) do if e.mul then st[e.stat] = st[e.stat] * e.mul end end
	end
	for k, v in pairs(M.MIN) do
		if type(st[k]) == "number" and st[k] < v then st[k] = v end
	end
	return st
end

-- Final stats. base: the sim's game.base_stats(). levels: levels of the worn
-- pieces ({ mask = 1..30, ... }, missing: 1), signs: their signatures lit
-- ({ mask = 0..3 }, nil: as far as the levels go). level: the player's level (nil:
-- 1). First the Sigilli, then what the level gives by itself (sim/skills.lua),
-- then the pieces, which stop at the caps over the base (sim/gear.lua). Integer values (hp,
-- ticks) stay integers.
function M.stats(base, a, levels, level, signs)
	local st = {}
	for k, v in pairs(base) do st[k] = v end
	local mods = {}
	skills.mods(a.tree or {}, mods)
	apply(st, mods)
	for stat, v in pairs(skills.level_bonus(level)) do st[stat] = st[stat] + v end
	for stat, v in pairs(skills.level_move(level)) do st[stat] = st[stat] * (1 + v) end
	equip.apply(st, base, a.gear or {}, levels, signs)
	for k, v in pairs(M.MIN) do
		if type(st[k]) == "number" and st[k] < v then st[k] = v end
	end
	for _, k in ipairs({ "max_hp", "teleport_ticks" }) do
		if type(st[k]) == "number" then st[k] = math.floor(st[k] + 0.5) end
	end
	-- Attack and Defense to a tenth of a point
	for _, k in ipairs({ "attack", "defense" }) do st[k] = math.floor(st[k] * 10 + 0.5) / 10 end
	return st
end

-- is the loadout playable with these points? (the server checks it before the match)
function M.valid(a, points)
	if type(a) ~= "table" or type(a.gear) ~= "table" then return false end
	for slot, set in pairs(a.gear) do
		if not equip.BY_ID[set] then return false end
		local known = false
		for _, s in ipairs(equip.SLOTS) do known = known or s.id == slot end
		if not known then return false end
	end
	if a.variant ~= "a" and a.variant ~= "b" then return false end
	return skills.valid(a.tree or {}, points)
end

-- Online (server/net.lua): what a player wears travels as
-- eq = { tree, gear, variant, lv = levels of the worn pieces by slot, sg = their
-- signatures lit by slot, liv = the player's level }, where the picks of the
-- tree's thresholds are { wings = { ["2"] = 1 } } (a list with holes isn't JSON).
-- net_clean checks one that arrived and returns a copy with only what counts
-- (whole numbers and names: it travels again as it is), or nil if it can't be
-- played; net_stats gives its stats, the same on the server and on every phone.
local function whole(v, lo, hi)
	return type(v) == "number" and v % 1 == 0 and v >= lo and v <= hi
end

local function net_loadout(eq)
	local tree = {}
	for k, v in pairs(eq.tree or {}) do
		if k == "pick" then
			tree.pick = {}
			for path, list in pairs(v) do
				local t = {}
				for i, w in pairs(list) do t[tonumber(i) or i] = w end
				tree.pick[path] = t
			end
		else
			tree[k] = v
		end
	end
	return { tree = tree, gear = eq.gear or {}, variant = eq.variant }
end

function M.net_clean(eq)
	if type(eq) ~= "table" then return nil end
	local out = { liv = type(eq.liv) == "number" and math.max(1, math.min(skills.LEVEL_MAX, math.floor(eq.liv))) or 1, variant = eq.variant == "b" and "b" or "a",
		lv = {}, sg = {} }
	if type(eq.gear) == "table" and next(eq.gear) then
		out.gear = {}
		for slot, set in pairs(eq.gear) do out.gear[slot] = set end
	end
	if type(eq.tree) == "table" and next(eq.tree) then
		out.tree = {}
		for k, v in pairs(eq.tree) do
			if k ~= "pick" then
				out.tree[k] = v
			elseif type(v) == "table" then
				local pick = {}
				for path, list in pairs(v) do
					if type(list) ~= "table" then return nil end
					local t = {}
					for i, w in pairs(list) do t[tostring(i)] = w end
					if next(t) then pick[path] = t end
				end
				if next(pick) then out.tree.pick = pick end
			else
				return nil
			end
		end
	end
	for _, s in ipairs(equip.SLOTS) do
		local l, sg = type(eq.lv) == "table" and eq.lv[s.id], type(eq.sg) == "table" and eq.sg[s.id]
		out.lv[s.id] = whole(l, 1, equip.LIVELLO_MAX) and l or 1
		-- a signature is lit as far as the piece's step (sim/wallet.lua, sign)
		out.sg[s.id] = whole(sg, 0, #equip.SIGN_TIERS - 1) and math.min(sg, equip.tier(out.lv[s.id]) - 1) or 0
	end
	if not M.valid(net_loadout(out), skills.points(out.liv)) then return nil end
	return out
end

-- eq: one that net_clean returned (here or on the server); base: game.base_stats()
function M.net_stats(eq, base)
	return M.stats(base, net_loadout(eq), eq.lv, eq.liv, eq.sg)
end

-- How much a robot's stats are worth over the base, in one number: life,
-- Attack and Defense a point every 100, the others their share over the base
-- (the "less is better" ones the other way). It weighs the training's bots
function M.power(st, base)
	local sum = 0
	for k, kind in pairs(equip.STATS) do
		local v, b = st[k] or base[k], base[k]
		if kind.points then
			sum = sum + (v - b) / 100
		elseif b and b ~= 0 then
			sum = sum + (kind.less and (1 - v / b) or (v / b - 1))
		end
	end
	return sum
end

-- One bot built from the player's eq (mine, cleaned) with the generator r: on
-- the player's slots, at the same levels and signatures, each family swapped
-- for another (the same one for all its pieces: who has a family pair, the
-- bot has one too); the same Sigilli points, a threshold at a time on random
-- paths, with random powers
local function build(mine, r)
	local function shuffle(list)
		for i = #list, 2, -1 do
			local j = r:next_int() % i + 1
			list[i], list[j] = list[j], list[i]
		end
		return list
	end
	local families, swap, n = {}, {}, 0
	for i, f in ipairs(equip.SETS) do families[i] = f.id end
	shuffle(families)
	local out = { liv = mine.liv, variant = "a", gear = {}, lv = {}, sg = {} }
	for _, s in ipairs(equip.SLOTS) do
		local f = mine.gear and mine.gear[s.id]
		if f then
			if not swap[f] then n = n + 1; swap[f] = families[n] end
			out.gear[s.id], out.lv[s.id], out.sg[s.id] = swap[f], mine.lv[s.id], mine.sg[s.id]
		end
	end
	local left = math.min(skills.spent(mine.tree or {}), skills.points(mine.liv))
	local tree = {}
	while left > 0 do
		local open = {}
		for _, p in ipairs(skills.PATHS) do
			if (tree[p.id] or 0) < skills.PATH_MAX then open[#open + 1] = p.id end
		end
		if #open == 0 then break end
		local path = open[r:next_int() % #open + 1]
		local k = math.min(left, skills.STEP, skills.PATH_MAX - (tree[path] or 0))
		tree[path], left = (tree[path] or 0) + k, left - k
	end
	for _, p in ipairs(skills.PATHS) do
		for k = 1, skills.reached(tree, p.id) do skills.choose(tree, p.id, k, r:next_int() % 2 + 1) end
	end
	out.tree = tree
	return M.net_clean(out)
end

-- A bot as strong as the player in training (Sergio, 18 Nov: "equipaggiamenti
-- comparabili"): RIVAL_TRIES bots built from what the player wears (eq, as
-- net_clean takes it; same level, slots, piece levels, signatures and
-- Sigilli points, other families and paths), and of those the one whose
-- power (M.power) is closest to the player's. Pure and deterministic: seed
-- is the match's, nth the bot's robot, so the server rebuilds the same one
-- from the recipe (server/verify.lua). Returns an eq like net_clean's (nil if
-- the player's doesn't hold)
M.RIVAL_TRIES = 12

function M.rival(eq, seed, nth)
	local mine = M.net_clean(eq)
	if not mine then return nil end
	local base = require("sim.game").base_stats()
	local target = M.power(M.net_stats(mine, base), base)
	local r = rng.new((math.floor(seed or 1) % 1000003) * 64 + (nth or 1))
	local best, gap
	for _ = 1, M.RIVAL_TRIES do
		local c = build(mine, r)
		local d = c and math.abs(M.power(M.net_stats(c, base), base) - target)
		if d and (not gap or d < gap) then best, gap = c, d end
	end
	return best
end

-- Every bot of a match as strong as the people (Sergio, 22 Nov: online too,
-- in every mode, like in training): players by robot ({ team, bot, eq }),
-- the people's eq as their phones send it. Each bot is the rival (M.rival)
-- of one person: the people of the other teams in turn, by the order of the
-- bots (so two people against two bots meet one copy each, and a person with
-- a bot against a person with a bot each meet the other's copy: the teams
-- weigh the same), and only if there are none the people of its own team.
-- In training (one person) every bot is the person's rival. A bot whose
-- person wears nothing (eq nil) stays bare. Fills p.eq of the bots and
-- returns players
function M.dress_bots(players, seed)
	local n = 0
	for i, p in ipairs(players) do
		if p.bot then
			local theirs, mates = {}, {}
			for _, q in ipairs(players) do
				if not q.bot then
					local list = q.team == p.team and mates or theirs
					list[#list + 1] = q
				end
			end
			local from = #theirs > 0 and theirs or mates
			local q = from[n % math.max(1, #from) + 1]
			p.eq = q and q.eq ~= nil and M.rival(q.eq, seed, i) or nil
			n = n + 1
		end
	end
	return players
end

return M
