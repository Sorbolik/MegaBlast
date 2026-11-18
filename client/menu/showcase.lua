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
--   vetrina.from_eq(eq, nome, squadra, sotto)  -- a bot wearing an eq (training, sim/loadout.lua rival)
--   vetrina.with_stats(v, st)                -- the match's real stats (g.robots[i].stats)
--   vetrina.righe(v, base)                   -- the four bars: { nome, valore, offset }
--   vetrina.resources(v)                     -- orbs, parachutes, air jumps

local game = require "sim.game"
local skills = require "sim.skills"
local equip = require "sim.gear"
local profile = require "menu.profile"
local wallet = require "sim.wallet"
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

-- A loadout's powers: those taken in the Sigilli (the pieces give no powers,
-- page "I Pezzi della Forgia")
function M.abilities(a)
	local out = {}
	for _, w in ipairs(skills.powers(a.tree or {})) do
		if w.power.power_name then out[#out + 1] = w.power.power_name end
	end
	return out
end

function M.from_profile(p, nome, team, under, tournament)
	local a = profile.active_loadout(p)
	local tiers = profile.tier(p, a)
	local v = { nome = nome, squadra = team, sotto = under, livello = p.livello, torneo = tournament,
		badge = profile.badge(p), pezzi = {}, abilities = M.abilities(a), albero = {},
		punti = profile.points(p, tournament) }
	for i, s in ipairs(equip.SLOTS) do
		local set = a.gear[s.id]
		v.pezzi[i] = { slot = s.id, set = set, livello = set and wallet.level(p, set, s.id) or 0, tier = tiers[s.id] or 1 }
	end
	for i, r in ipairs(skills.PATHS) do v.albero[i] = skills.spent(a.tree or {}, r.id) end
	v.stats = copy_stats(profile.stats(p, a, game.base_stats()))
	return v
end

function M.simple(nome, team, under, livello, badge)
	local v = { nome = nome, squadra = team, sotto = under, livello = livello, badge = badge or {},
		pezzi = empty_pieces(), abilities = {}, albero = {}, punti = 0 }
	for i in ipairs(skills.PATHS) do v.albero[i] = 0 end
	v.stats = copy_stats(game.base_stats())
	return v
end

-- A bot that wears an eq (sim/loadout.lua, rival: the training's bots): its
-- level, its pieces and its Sigilli, with the stats that come out of them
function M.from_eq(eq, nome, team, under)
	local loadout = require "sim.loadout"
	local v = M.simple(nome, team, under, eq.liv)
	for i, s in ipairs(equip.SLOTS) do
		local set = eq.gear and eq.gear[s.id]
		if set then v.pezzi[i] = { slot = s.id, set = set, livello = eq.lv[s.id], tier = equip.tier(eq.lv[s.id]) } end
	end
	local a = { tree = {} }
	for k, n in pairs(eq.tree or {}) do
		if k == "pick" then
			a.tree.pick = {}
			for path, list in pairs(n) do
				a.tree.pick[path] = {}
				for j, w in pairs(list) do a.tree.pick[path][tonumber(j) or j] = w end
			end
		else
			a.tree[k] = n
		end
	end
	v.abilities = M.abilities(a)
	for i, r in ipairs(skills.PATHS) do v.albero[i] = skills.spent(a.tree, r.id) end
	v.punti = skills.points(eq.liv)
	v.stats = copy_stats(loadout.net_stats(eq, game.base_stats()))
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
function M.rows(v, base)
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

-- A showcase arriving from outside (online): level, badges and the pieces worn
-- (pz, one per slot in the order of equip.SLOTS: { set, liv }), checked. The
-- pieces are only shown, on the tag and on the devil: online they don't change
-- the stats yet (they will count with the profiles on the server)
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
	for i, s in ipairs(equip.SLOTS) do
		local pz = type(t) == "table" and type(t.pz) == "table" and t.pz[i]
		local set, l = type(pz) == "table" and pz.set, type(pz) == "table" and tonumber(pz.liv)
		if type(set) == "string" and equip.BY_ID[set] and l then
			l = math.max(1, math.min(equip.LIVELLO_MAX, math.floor(l)))
			v.pezzi[i] = { slot = s.id, set = set, livello = l, tier = equip.tier(l) }
		end
	end
	-- a bot that fills the queue (server/lobby.go): its ring says BOT
	v.bot = type(t) == "table" and t.bot == true or nil
	return v
end

-- What is sent to the server with the greeting (hello): level, badges and the
-- pieces worn (an empty slot: set "")
function M.for_net(p)
	local bdg = {}
	for _, b in ipairs(profile.badge(p)) do bdg[#bdg + 1] = { id = b.id, grado = b.grado } end
	-- (no badges, no bdg: the empty table would be an object in JSON)
	local a = profile.active_loadout(p)
	local pz = {}
	for i, s in ipairs(equip.SLOTS) do
		local set = a.gear[s.id]
		pz[i] = { set = set or "", liv = set and wallet.level(p, set, s.id) or 0 }
	end
	return { liv = p.livello, bdg = #bdg > 0 and bdg or nil, pz = pz }
end

-- What whoever plays here wears, for the server: it works out the stats of
-- their robot online (sim/loadout.lua, net_clean): the Sigilli, the pieces with
-- their levels (lv) and signatures lit (sg), the player's level (liv)
function M.equip_for_net(p)
	local a = profile.active_loadout(p)
	return require("sim.loadout").net_clean({ tree = a.tree, gear = a.gear, variant = a.variant, liv = p.livello,
		lv = wallet.levels(p, a), sg = wallet.signs(p, a) })
end

return M
