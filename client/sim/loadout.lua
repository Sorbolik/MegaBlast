-- Loadout: skill tree plus gear, and the robot stats that come out of them.
-- Pure Lua: the client sends it to the server, which checks it with valid()
-- and passes stats() to the match (opts.stats[i]).
--
-- A loadout: { tree = { [node] = ranks }, gear = { mask = "corvo", ... }, variant = "a" | "b" }
-- It can be rebuilt for free outside a match; each player keeps LOADOUTS of them.

local skills = require "sim.skills"
local equip = require "sim.gear"

local M = {}

M.LOADOUTS = 3

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

-- Final stats. base: the sim's game.base_stats(). tiers: tiers of the worn
-- pieces ({ mask = 1..3, ... }), only needed for variant B.
-- Integer values (hp, ticks) stay integers.
function M.stats(base, a, tiers)
	local st = {}
	for k, v in pairs(base) do st[k] = v end
	local mods = {}
	skills.mods(a.tree or {}, mods)
	equip.mods(a.gear or {}, tiers, a.variant, mods)
	apply(st, mods)
	for _, k in ipairs({ "max_hp", "teleport_ticks" }) do
		if type(st[k]) == "number" then st[k] = math.floor(st[k] + 0.5) end
	end
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
