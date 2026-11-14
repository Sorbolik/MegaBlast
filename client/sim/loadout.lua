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
-- pieces ({ mask = 1..30, ... }, missing: 1). level: the player's level (nil:
-- 1). First the Sigilli, then the pieces with their caps (sim/gear.lua), then
-- what the level gives by itself (sim/skills.lua). Integer values (hp,
-- ticks) stay integers.
function M.stats(base, a, levels, level)
	local st = {}
	for k, v in pairs(base) do st[k] = v end
	local mods = {}
	skills.mods(a.tree or {}, mods)
	apply(st, mods)
	equip.apply(st, base, a.gear or {}, levels)
	for stat, v in pairs(skills.level_bonus(level)) do st[stat] = st[stat] + v end
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

return M
