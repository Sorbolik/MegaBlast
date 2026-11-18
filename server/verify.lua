-- Replays a recipe of a match played on a phone (server/recipe.go): the
-- recipe text (sim/replay.lua, M.encode) comes on stdin, one JSON line goes
-- out on stdout. Twice: with the bots' keys written in the recipe (is the
-- physics the same here?) and with the bots thinking again (are the bots the
-- same too?). Guest profiles plan, PR 1: measures whether a match played on
-- the phone comes out identical on the server.

local dir = arg[1] or "."
package.path = dir .. "/?.lua;" .. package.path
-- stdout is only for the answer
_G.print = function(...)
	local t = { ... }
	for i = 1, select("#", ...) do t[i] = tostring(t[i]) end
	io.stderr:write(table.concat(t, "\t"), "\n")
end

local replay = require "sim.replay"

local r = replay.decode(io.read("*a"))
if not r then
	io.write('{"err":"ricetta illeggibile"}\n')
	return
end
local last = r.impronte[#r.impronte]

-- training against the bots: the bots wear what the server builds from the
-- player's eq and the seed (sim/loadout.lua, rival), not what the phone says
local players = type(r.opzioni) == "table" and type(r.opzioni.players) == "table" and r.opzioni.players or {}
local mine = type(players[1]) == "table" and players[1].eq
if mine then
	local loadout = require "sim.loadout"
	for i, p in ipairs(players) do
		if i > 1 and type(p) == "table" and p.bot then
			local ok, eq = pcall(loadout.rival, mine, r.seme, i)
			p.eq = ok and eq or nil
		end
	end
end

local function run(rethink)
	local t0 = os.clock()
	local ok, res, tick = pcall(replay.verify, r, nil, rethink)
	local ms = math.floor((os.clock() - t0) * 1000 + 0.5)
	if not ok then return false, -1, ms end
	return res, tick or 0, ms
end

local ok, tick, ms = run(false)
local ok_bots, tick_bots, ms_bots = true, 0, 0
if r.bot_keys then ok_bots, tick_bots, ms_bots = run(true) end
io.write(string.format('{"physics":%s,"physics_tick":%d,"bots":%s,"bots_tick":%d,"ticks":%d,"ms":%d,"bots_ms":%d}\n',
	tostring(ok), tick, tostring(r.bot_keys and ok_bots or false), tick_bots, last and last.t or 0, ms, ms_bots))
