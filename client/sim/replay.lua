-- Match recipe: the little data needed to replay it identically (the
-- simulation is deterministic). Seed, map, game.new options (with the players,
-- and the level for bots), the real players' keys only when they change, and
-- the state fingerprints (game:impronta) every EVERY ticks and at the end:
-- whoever replays it must find them all the same, otherwise the match is not
-- valid (different version, changed code, tampered data).
-- Used by the bot arena (strumenti/arena), by replays and by server checks.
--
--   local replay = require "sim.replay"
--   local r = replay.nuova(seed, map, opts)      -- opts as in game.new; players[i].bot = "normale" for a bot (and carattere, pesi)
--   local g, bots = replay.partita(r)
--   every tick:
--     local input = replay.input(r, g, bots, player_input)
--     g:step(input)
--     replay.dopo(r, g)
--   local ok, tick = replay.verifica(r)          -- replays it: true, or false and the tick where it diverges

local game = require "sim.game"
local bot = require "sim.bot"

local M = {}

M.VERSION = 1
-- how many ticks between fingerprints (10 s)
M.EVERY = 600

local function copy(t)
	if type(t) ~= "table" then return t end
	local o = {}
	for k, v in pairs(t) do o[k] = copy(v) end
	return o
end

function M.nuova(seed_value, map_name, opts)
	return { versione = M.VERSION, seme = seed_value, mappa = map_name,
		opzioni = copy(opts or {}), input = {}, impronte = {} }
end

-- The recipe's match and bots, at the start
function M.partita(r)
	local g = game.new(r.seme, r.mappa, copy(r.opzioni))
	-- durata: the match shortened by hand (in scenarios, prova_durata)
	if r.durata then g.match_left = r.durata end
	local bots = {}
	for i, p in ipairs(r.opzioni.players or {}) do
		if p.bot then bots[i] = bot.new(i, p.bot, r.seme, p.pesi, p.carattere) end
	end
	r.ultimo = nil
	return g, bots
end

local function same_input(a, b)
	return (a.left or false) == (b.left or false) and (a.right or false) == (b.right or false)
		and (a.jump or false) == (b.jump or false) and a.hold == b.hold
end

-- This tick's input: the bot's if it is a bot's turn, otherwise the player's,
-- which is written into the recipe (only changes and shots)
function M.input(r, g, bots, human)
	local b = bots[g.current]
	if b then return bot.input(b, g) end
	human = human or {}
	local first_one = r.ultimo or {}
	if human.fire or not same_input(human, first_one) then
		local f = human.fire
		r.input[#r.input + 1] = { t = g.tick + 1, l = human.left or false, r = human.right or false,
			j = human.jump or false, h = human.hold,
			f = f and { w = f.weapon, a = f.angle, p = f.power } or nil }
	end
	r.ultimo = human
	return human
end

-- After g:step: the fingerprint, every EVERY ticks and at the end
function M.dopo(r, g)
	if g.tick % M.EVERY == 0 or g.phase == "over" then
		r.impronte[#r.impronte + 1] = { t = g.tick, h = g:impronta() }
	end
end

-- Reads a recipe back: the real players' keys tick by tick (bots think on
-- their own, as when it was played). Used by verifica and by the in-game
-- replay (MATCHES tab of the profile).
function M.reader(r)
	return { r = r, k = 1, cur = {} }
end

-- The input of g's next step, read from the recipe
function M.read_step(l, g, bots)
	local b = bots[g.current]
	-- the shot lasts one tick only
	if l.cur.fire then l.cur = { left = l.cur.left, right = l.cur.right, jump = l.cur.jump, hold = l.cur.hold } end
	if b then return bot.input(b, g) end
	local e = l.r.input[l.k]
	while e and e.t == g.tick + 1 do
		l.cur = { left = e.l, right = e.r, jump = e.j, hold = e.h,
			fire = e.f and { weapon = e.f.w, angle = e.f.a, power = e.f.p } or nil }
		l.k = l.k + 1
		e = l.r.input[l.k]
	end
	return l.cur
end

-- Replays the recipe and compares fingerprints. Returns true, or false and
-- the tick of the first different (or missing) fingerprint.
function M.verifica(r, max_tick)
	local g, bots = M.partita(r)
	local l = M.reader(r)
	local n = 1
	local waits = r.impronte
	max_tick = max_tick or (waits[#waits] and waits[#waits].t) or 0
	while g.phase ~= "over" and g.tick < max_tick do
		g:step(M.read_step(l, g, bots))
		local a = waits[n]
		if a and a.t == g.tick then
			if a.h ~= g:impronta() then return false, g.tick end
			n = n + 1
		end
	end
	if waits[n] then return false, waits[n].t end
	return true
end

return M
