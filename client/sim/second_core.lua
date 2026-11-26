-- The match's twin on another core of the phone (client/pensiero, a second Lua
-- engine on its own thread): it plays the same match tick by tick from the same
-- recipe, like the online lockstep (the simulation is deterministic), and in
-- the bots' turns it goes ahead on its own, thinking for them, and sends their
-- keys to the game, which only draws. So the MAESTRO (sim/master.lua), which
-- thinks a hundred times more than the other bots, never takes time from the
-- frames (Sergio, 26 Nov 2026: "facciamolo"). The bots are the same objects the
-- server makes when it checks the match, thinking a little per tick in the same
-- way: the keys are those, tick for tick.
--
--   require("sim.second_core").run(ch)   -- ch.receive(block) -> message or nil, ch.send(message)
--
-- Messages (strings), from the game: "S" .. recipe (replay.encode, at the start:
-- a new match), "K<tick> <keys>" (the keys a person played to get to tick),
-- "X" (no match). To the game: "B<tick> <keys>" (a bot's keys to get to tick),
-- "F<tick> <fingerprint>" (every replay.EVERY ticks: the game checks it is the
-- same match). The keys are written by M.encode.

local replay = require "sim.replay"
local bot = require "sim.bot"

local M = {}

-- Keys as text: four flags and the shot, with the numbers exact (%.17g)
function M.encode(k)
	local s = (k.left and "1" or "0") .. (k.right and "1" or "0") .. (k.jump and "1" or "0") .. (k.hold and "1" or "0")
	local f = k.fire
	if f then s = s .. " " .. f.weapon .. " " .. string.format("%.17g %.17g", f.angle, f.power) end
	return s
end

function M.decode(s)
	local k = { left = s:sub(1, 1) == "1", right = s:sub(2, 2) == "1", jump = s:sub(3, 3) == "1", hold = s:sub(4, 4) == "1" }
	local w, a, p = s:match("^%d%d%d%d (%S+) (%S+) (%S+)$")
	if w then k.fire = { weapon = w, angle = tonumber(a), power = tonumber(p) } end
	return k
end

function M.run(ch)
	local g, bots, keys = nil, nil, {}
	local function take(m)
		local kind = m:sub(1, 1)
		if kind == "S" then
			local r = assert(replay.decode(m:sub(2)), "ricetta illeggibile")
			g, bots = replay.match(r)
			keys = {}
			M.twin = g -- (only for the tests: the same Lua engine there)
		elseif kind == "K" then
			local t, k = m:match("^K(%d+) (.*)$")
			keys[tonumber(t)] = M.decode(k)
		elseif kind == "X" then
			g, bots, keys = nil, nil, {}
		end
	end
	while true do
		-- it can go ahead in a bot's turn, or with a person's keys already here
		local ahead = g and g.phase ~= "over" and (bots[g.current] ~= nil or keys[g.tick + 1] ~= nil)
		local m = ch.receive(not ahead)
		while m do
			take(m)
			m = ch.receive(false)
		end
		if g and g.phase ~= "over" then
			local t = g.tick + 1
			local b = bots[g.current]
			local k
			if b then
				k = bot.input(b, g)
				ch.send("B" .. t .. " " .. M.encode(k))
			else
				k = keys[t]
			end
			if k then
				keys[t] = nil
				g:step(k)
				g:pop_events()
				if g.tick % replay.EVERY == 0 then ch.send("F" .. g.tick .. " " .. tostring(g:fingerprint())) end
			end
		end
	end
end

return M
