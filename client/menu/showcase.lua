-- Showcase: what a player's tag shows (ui/tag_card.lua), as data. Pure Lua,
-- so it is tested, saved in the profile's matches (what that player was like
-- that time) and sent to the others online.
--
--   v = { nome, squadra (1..4), sotto (the line under the name), livello (nil: unknown), bot,
--         torneo (the values are the Tournament's), badge = { { id, grado }, ... },
--         pezzi = { { slot, set, livello, tier } x4 (set nil: empty) },
--         abilities = { "doppio salto", ... }, albero = { points per branch }, punti (of the tree),
--         stats = { the in-match stats the tag shows } }
--
--   vetrina.from_profile(p, nome, squadra, sotto, torneo)  -- whoever plays on this phone
--   vetrina.simple(nome, squadra, sotto, livello, badge)   -- bots, teammates, online opponents
--   vetrina.with_stats(v, st)                -- the match's real stats (g.robots[i].stats)
--   vetrina.righe(v, base)                   -- the four bars: { nome, valore, offset }
--   vetrina.resources(v)                     -- orbs, parachutes, air jumps

local game = require "sim.game"
local skills = require "sim.skills"
local loadout = require "sim.loadout"
local equip = require "sim.gear"
local profile = require "menu.profile"
local T = require("lang.text").showcase

local M = {}

-- the stats the tag reads
M.KEYS = { "max_hp", "jump_height", "walk_speed", "air_speed", "teleports", "parachutes", "air_jumps" }
-- the four bars: health in points, the others in percent of the base
M.BARS = { { "max_hp", T.health, "punti" }, { "jump_height", T.jump }, { "walk_speed", T.run }, { "air_speed", T.air } }
-- how far a bar goes (full on one side): 10% above or below the base
M.SCALE = 0.1

local function copy_stats(st)
	local o = {}
	for _, k in ipairs(M.KEYS) do o[k] = st[k] end
	return o
end

local function empty_pieces()
	local out = {}
	for i, s in ipairs(equip.SLOTS) do out[i] = { slot = s.id, livello = 0, tier = 1 } end
	return out
end

-- A loadout's powers: the full-set bonus and those taken in the Sigilli
function M.abilities(a, tiers)
	local out = {}
	local id, top = equip.full_set(a.gear or {}, tiers)
	local set = id and equip.BY_ID[id]
	if set and set.bonus then
		local b = set.bonus[(a.variant == "b" and top) and "b" or "a"]
		out[#out + 1] = b.power_name
	end
	for _, w in ipairs(skills.powers(a.tree or {})) do
		if w.power.power_name then out[#out + 1] = w.power.power_name end
	end
	return out
end

function M.from_profile(p, nome, team, under, tournament)
	local a = profile.active_loadout(p)
	local tiers = profile.tier(p, a)
	local v = { nome = nome, squadra = team, sotto = under, livello = p.livello, torneo = tournament,
		badge = profile.badge(p), pezzi = {}, abilities = M.abilities(a, tiers), albero = {},
		punti = profile.punti(p, tournament) }
	for i, s in ipairs(equip.SLOTS) do
		local set = a.gear[s.id]
		local n = set and (p.mastery[set .. "_" .. s.id] or 0) or 0
		v.pezzi[i] = { slot = s.id, set = set, livello = set and equip.livello(n) or 0, tier = tiers[s.id] or 1 }
	end
	for i, r in ipairs(skills.PATHS) do v.albero[i] = skills.spent(a.tree or {}, r.id) end
	v.stats = copy_stats(loadout.stats(game.base_stats(), a, tiers))
	return v
end

function M.simple(nome, team, under, livello, badge)
	local v = { nome = nome, squadra = team, sotto = under, livello = livello, badge = badge or {},
		pezzi = empty_pieces(), abilities = {}, albero = {}, punti = 0 }
	for i in ipairs(skills.PATHS) do v.albero[i] = 0 end
	v.stats = copy_stats(game.base_stats())
	return v
end

-- The match's real stats (online gear doesn't count yet: the tag says what
-- really applies)
function M.with_stats(v, st)
	if st then v.stats = copy_stats(st) end
	return v
end

local function round_off(x) return math.floor(x + 0.5) end

-- The four bars: name, written value and offset from the base (-1..1 = ±SCALE)
function M.righe(v, base)
	base = base or game.base_stats()
	local out = {}
	for i, b in ipairs(M.BARS) do
		local k = b[1]
		local val, ref = v.stats[k] or base[k], base[k]
		local frac = ref ~= 0 and (val / ref - 1) or 0
		local txt
		if b[3] == "punti" then
			txt = tostring(round_off(val))
		else
			local pc = round_off(frac * 100)
			txt = pc == 0 and "=" or (pc > 0 and "+" or "−") .. math.abs(pc) .. "%"
		end
		out[i] = { nome = b[2], valore = txt, offset = math.max(-1, math.min(1, frac / M.SCALE)) }
	end
	return out
end

function M.resources(v)
	local st = v.stats
	return { globi = st.teleports or 0, paracadute = st.parachutes or 0, aria = st.air_jumps or 0 }
end

-- A showcase arriving from outside (online): only level and badges, checked
-- (pieces don't count online yet: they will come with profiles on the server)
function M.from_net(t, nome, team, under)
	local milestones = require "menu.milestones"
	local liv = type(t) == "table" and tonumber(t.liv)
	if liv then liv = math.max(1, math.min(999, math.floor(liv))) end
	local badge = {}
	for _, b in ipairs(type(t) == "table" and type(t.bdg) == "table" and t.bdg or {}) do
		local ok = milestones.valid(b)
		if ok and #badge < milestones.SHOWN then badge[#badge + 1] = ok end
	end
	local v = M.simple(nome, team, under, liv, badge)
	-- a bot that fills the queue (server/lobby.go): its ring says BOT
	v.bot = type(t) == "table" and t.bot == true or nil
	return v
end

-- What is sent to the server with the greeting (hello): level and badges
function M.per_rete(p)
	local bdg = {}
	for _, b in ipairs(profile.badge(p)) do bdg[#bdg + 1] = { id = b.id, grado = b.grado } end
	-- (no badges, no bdg: the empty table would be an object in JSON)
	return { liv = p.livello, bdg = #bdg > 0 and bdg or nil }
end

return M
