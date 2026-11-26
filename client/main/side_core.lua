-- The bots think on another core (client/pensiero, sim/second_core.lua): a twin
-- of the match plays there, and in the bots' turns it sends their keys here.
-- Only against the MAESTRO for now (bot.LEVELS.maestro), the one that thinks a
-- hundred times more: the others think here, a little per tick, as always.
-- Without the extension (browser, simulator) nothing changes: the bots think here.
--
--   side_core.start(r, bots)   -- after replay.match: true if the bots now think over there
--   side_core.ready(g)         -- false: the bot's keys for the next tick aren't here yet (don't step)
--   side_core.person(g, keys)  -- before g:step(keys) in a person's turn: the keys go over there too
--   side_core.played(g)        -- after g:step: checks now and then that it is the same match
--   side_core.stop()           -- the match is over or left

local replay = require "sim.replay"
local second = require "sim.second_core"

local M = {}

-- Every module of client/sim (the twin needs them all; tests/bot_test.lua
-- checks this list against the folder): game.project's custom_resources has /sim
M.MODULES = { "awards", "body", "bot", "campaign", "config", "draft", "forge", "game", "gear", "hazards", "judge",
	"levels", "loadout", "mapdata", "maps", "master", "melee", "milestones", "missions", "netkeys", "orders",
	"profile", "progress", "replay", "rete", "rng", "rules", "second_core", "skills", "tally", "terrain", "wallet" }

-- waiting more than this for a bot's keys means the other core is gone: the bots think here again
local GIVE_UP_MS = 3000

local started -- nil: not tried yet; false: no extension or it didn't start
local s       -- this match: { bots, keys = {[tick] = keys}, theirs and mine = {[tick] = fingerprint}, waited }

local function boot()
	if started ~= nil then return started end
	started = false
	if not pensiero then return false end
	local src = {}
	for _, n in ipairs(M.MODULES) do
		local text = sys.load_resource("/sim/" .. n .. ".lua")
		if not text then return false end
		src["sim." .. n] = text
	end
	started = pensiero.avvia(src, "sim.second_core") and true or false
	return started
end

-- the bots of this match think here again (the twin went wrong or quiet)
local function here()
	if not s then return end
	for _, b in pairs(s.bots) do b.script = nil end
	print("[pensiero] i bot tornano a pensare qui")
	s = nil
	pensiero.manda("X")
end

-- the fingerprints of tick t from both sides: different, the twin went wrong
local function compare(t)
	local a, b = s.theirs[t], s.mine[t]
	if a and b then
		s.theirs[t], s.mine[t] = nil, nil
		if a ~= b then
			print("[pensiero] la partita dell'altro core è diversa al tick " .. t)
			here()
		end
	end
end

-- reads what the other core has sent; wait (ms): how long to wait for one message
local function drain(wait)
	local m = wait and pensiero.attendi(wait) or pensiero.ricevi()
	while m do
		local kind = m:sub(1, 1)
		if kind == "B" then
			local t, k = m:match("^B(%d+) (.*)$")
			s.keys[tonumber(t)] = second.decode(k)
		elseif kind == "F" then
			local t, h = m:match("^F(%d+) (.*)$")
			t = tonumber(t)
			s.theirs[t] = h
			compare(t)
			if not s then return end
		end
		m = pensiero.ricevi()
	end
end

function M.start(r, bots)
	M.stop()
	local maestro = false
	for _, p in ipairs(r.opzioni.players or {}) do
		if p.bot == "maestro" then maestro = true end
	end
	if not maestro or not boot() then return false end
	s = { bots = bots, keys = {}, theirs = {}, mine = {} }
	pensiero.manda("S" .. replay.encode(r))
	for _, b in pairs(bots) do
		b.script = function(g)
			local t = g.tick + 1
			if not s.keys[t] then
				-- only who steps without asking ready (a replay played at once) waits here
				drain(GIVE_UP_MS)
				if not s.keys[t] then
					here()
					return {}
				end
			end
			local k = s.keys[t]
			s.keys[t] = nil
			return k
		end
	end
	return true
end

function M.ready(g)
	if not s or not s.bots[g.current] then return true end
	if s.keys[g.tick + 1] then return true end
	drain()
	if not s then return true end
	if s.keys[g.tick + 1] then
		s.waited = nil
		return true
	end
	-- not yet: this frame the match waits (it slows a moment, it doesn't stutter)
	s.waited = s.waited or socket.gettime()
	if socket.gettime() - s.waited > GIVE_UP_MS / 1000 then
		here()
		return true
	end
	return false
end

function M.person(g, keys)
	if s and not s.bots[g.current] then pensiero.manda("K" .. (g.tick + 1) .. " " .. second.encode(keys)) end
end

function M.played(g)
	if not s or g.tick % replay.EVERY ~= 0 then return end
	-- the same match over there? (the twin's fingerprint may come before or after)
	s.mine[g.tick] = tostring(g:fingerprint())
	compare(g.tick)
end

function M.stop()
	if s then
		s = nil
		pensiero.manda("X")
	end
end

return M
