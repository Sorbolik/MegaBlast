-- Match recipe: the little data needed to replay it identically (the
-- simulation is deterministic). Seed, map, game.new options (with the players,
-- and the level for bots), the real players' keys only when they change, and
-- the state fingerprints (game:fingerprint) every EVERY ticks and at the end:
-- whoever replays it must find them all the same, otherwise the match is not
-- valid (different version, changed code, tampered data).
-- Used by the bot arena (tools/arena), by replays and by server checks.
--
--   local replay = require "sim.replay"
--   local r = replay.nuova(seed, map, opts)      -- opts as in game.new; players[i].bot = "normale" for a bot (and carattere, pesi)
--   r.bot_keys = true                            -- optional: the bots' keys go into the recipe too
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

function M.new(seed_value, map_name, opts)
	return { versione = M.VERSION, seme = seed_value, mappa = map_name,
		opzioni = copy(opts or {}), input = {}, impronte = {} }
end

-- The recipe's match and bots, at the start
function M.match(r)
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

-- Writes keys into the recipe (only changes and shots)
local function write(r, g, keys)
	if keys.fire or not same_input(keys, r.ultimo or {}) then
		local f = keys.fire
		r.input[#r.input + 1] = { t = g.tick + 1, l = keys.left or false, r = keys.right or false,
			j = keys.jump or false, h = keys.hold,
			f = f and { w = f.weapon, a = f.angle, p = f.power } or nil }
	end
	r.ultimo = keys
end

-- This tick's input: the bot's if it is a bot's turn, otherwise the player's,
-- which is written into the recipe. With r.bot_keys the bots' keys are written
-- too: replaying it the bots don't think again, so the in-game replay jumps to
-- a moment in milliseconds instead of seconds
function M.input(r, g, bots, human)
	local b = bots[g.current]
	if b then
		local keys = bot.input(b, g)
		if r.bot_keys then write(r, g, keys) end
		return keys
	end
	human = human or {}
	write(r, g, human)
	return human
end

-- After g:step: the fingerprint, every EVERY ticks and at the end
function M.after(r, g)
	if g.tick % M.EVERY == 0 or g.phase == "over" then
		r.impronte[#r.impronte + 1] = { t = g.tick, h = g:fingerprint() }
	end
end

-- Reads a recipe back: the real players' keys tick by tick (bots think on
-- their own, as when it was played, unless the recipe has their keys too). Used by verifica and by the in-game
-- replay (MATCHES tab of the profile).
function M.reader(r)
	return { r = r, k = 1, cur = {} }
end

-- The input of g's next step, read from the recipe
function M.read_step(l, g, bots)
	local b = (l.rethink or not l.r.bot_keys) and bots[g.current]
	-- the shot lasts one tick only
	if l.cur.fire then l.cur = { left = l.cur.left, right = l.cur.right, jump = l.cur.jump, hold = l.cur.hold } end
	if b then
		local keys = bot.input(b, g)
		if l.rethink then
			-- the bots think again: their written keys are skipped, and the
			-- last ones stay held as when the recipe was written
			local e = l.r.input[l.k]
			while e and e.t <= g.tick + 1 do
				l.k = l.k + 1
				e = l.r.input[l.k]
			end
			l.cur = keys
		end
		return keys
	end
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
-- rethink: the bots think again even if the recipe has their keys (the
-- server checks the bots too, not only the physics)
function M.verify(r, max_tick, rethink)
	local g, bots = M.match(r)
	local l = M.reader(r)
	l.rethink = rethink
	local n = 1
	local waits = r.impronte
	max_tick = max_tick or (waits[#waits] and waits[#waits].t) or 0
	while g.phase ~= "over" and g.tick < max_tick do
		g:step(M.read_step(l, g, bots))
		local a = waits[n]
		if a and a.t == g.tick then
			if a.h ~= g:fingerprint() then return false, g.tick end
			n = n + 1
		end
	end
	if waits[n] then return false, waits[n].t end
	return true
end

-- A recipe as text, to send it to the server: a Lua table literal with the
-- numbers at 17 digits, so the shots' angles and powers come back exact
-- (a JSON at 14 digits would change them and the match with them).
local function encode(v, out)
	local kind = type(v)
	if kind == "number" then
		assert(v == v and v ~= math.huge and v ~= -math.huge, "recipe: number not finite")
		if v == math.floor(v) and math.abs(v) < 2 ^ 53 then
			out[#out + 1] = string.format("%d", v)
		else
			out[#out + 1] = string.format("%.17g", v)
		end
	elseif kind == "string" then
		out[#out + 1] = string.format("%q", v)
	elseif kind == "boolean" then
		out[#out + 1] = tostring(v)
	elseif kind == "table" then
		out[#out + 1] = "{"
		local n = #v
		for i = 1, n do
			encode(v[i], out)
			out[#out + 1] = ","
		end
		-- the other keys in order, so the same recipe is always the same text
		local keys = {}
		for k in pairs(v) do
			if not (type(k) == "number" and k >= 1 and k <= n and k == math.floor(k)) then keys[#keys + 1] = k end
		end
		table.sort(keys, function(a, b)
			if type(a) ~= type(b) then return type(a) < type(b) end
			return a < b
		end)
		for _, k in ipairs(keys) do
			out[#out + 1] = "["
			encode(k, out)
			out[#out + 1] = "]="
			encode(v[k], out)
			out[#out + 1] = ","
		end
		out[#out + 1] = "}"
	else
		error("recipe: cannot write a " .. kind)
	end
end

function M.encode(r)
	local t = {}
	for k, v in pairs(r) do
		-- ultimo: the last keys, only for writing it
		if k ~= "ultimo" then t[k] = v end
	end
	local out = {}
	encode(t, out)
	return table.concat(out)
end

-- The recipe back from M.encode's text, or nil. The text runs with no
-- globals at all, so it can only build tables (whoever sends a loop gets
-- stopped by the server's timeout).
function M.decode(s)
	if type(s) ~= "string" then return nil end
	local f = loadstring("return " .. s, "=ricetta")
	if not f then return nil end
	setfenv(f, {})
	local ok, r = pcall(f)
	if ok and type(r) == "table" and type(r.input) == "table" and type(r.impronte) == "table" then return r end
	return nil
end

return M
