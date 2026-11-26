-- The bots thinking on another core (client/main/side_core.lua, sim/second_core.lua):
-- here the other core is a coroutine with the same messages as client/pensiero.
-- The match played with the twin's keys must be the one played with the bots
-- thinking here, tick for tick. From the root: luajit tests/side_core_test.lua
package.path = "client/?.lua;" .. package.path

local bot = require "sim.bot"
local replay = require "sim.replay"
local second = require "sim.second_core"

local failures = 0
local function check(cond, msg)
	if cond then
		print("ok   " .. msg)
	else
		print("FAIL " .. msg)
		failures = failures + 1
	end
end

-- the other core, pretended: a coroutine that runs a few steps every time the game looks
local inbox, outbox, worker = {}, {}, nil
local function pump(n)
	for _ = 1, n do
		if coroutine.status(worker) == "dead" then return end
		local ok, err = coroutine.resume(worker)
		assert(ok, err)
		if #outbox > 0 then return end
	end
end
local ch = {
	receive = function(block)
		while #inbox == 0 do
			if not block then return nil end
			coroutine.yield()
		end
		return table.remove(inbox, 1)
	end,
	send = function(m)
		outbox[#outbox + 1] = m
		coroutine.yield()
	end,
}
local loaded = {}
pensiero = {
	avvia = function(src, main)
		for k in pairs(src) do loaded[#loaded + 1] = k end
		worker = coroutine.create(function() require(main).run(ch) end)
		return true
	end,
	manda = function(m) inbox[#inbox + 1] = m end,
	ricevi = function()
		pump(3)
		return table.remove(outbox, 1)
	end,
	attendi = function()
		pump(100000)
		return table.remove(outbox, 1)
	end,
}
sys = { load_resource = function(path)
	local f = io.open("client" .. path, "rb")
	if not f then return nil end
	local t = f:read("*a")
	f:close()
	return t
end }
socket = { gettime = os.clock }

local side = require "main.side_core"

-- every module of client/sim is in the list the twin loads
do
	local listed, missing = {}, {}
	for _, n in ipairs(side.MODULES) do listed[n] = true end
	local p = io.popen('ls client/sim')
	for f in p:lines() do
		local n = f:match("^(.-)%.lua$")
		if n and not listed[n] then missing[#missing + 1] = n end
	end
	p:close()
	check(#missing == 0, "side_core.MODULES has every file of client/sim " .. table.concat(missing, ", "))
end

check(second.decode(second.encode({ left = true, hold = true, fire = { weapon = "missile", angle = 0.1234567890123, power = 1 / 3 } })).fire.power == 1 / 3,
	"keys as text: the shot's numbers come back exact")

-- A 1v1 against the MAESTRO: the person is a difficile bot pressing the keys
local function play(twin, ticks)
	local players = { { team = 1 }, { team = 2, bot = "maestro" } }
	local r = replay.new(33, "pavimento", { players = players })
	local g, bots = replay.match(r)
	local person = bot.new(1, "difficile", 33)
	local on = twin and side.start(r, bots)
	local prints, waits = {}, 0
	while g.phase ~= "over" and g.tick < ticks do
		if twin and not side.ready(g) then
			waits = waits + 1
			pump(50)
		else
			local keys = replay.input(r, g, bots, bot.input(person, g))
			if twin then side.person(g, keys) end
			g:step(keys)
			g:pop_events()
			if twin then side.played(g) end
			if g.tick % 300 == 0 then prints[#prints + 1] = g:fingerprint() end
		end
	end
	side.stop()
	return table.concat(prints, ","), on, waits, bots
end

local here = play(false, 3000)
local there, on, waits, bots = play(true, 3000)
check(on, "the twin starts against the MAESTRO (" .. #loaded .. " modules sent)")
check(bots[2].script ~= nil, "the MAESTRO's keys come from the other core to the end")
check(here == there, "the match with the twin's keys is the one with the bots thinking here (" .. waits .. " frames waited)")

if failures > 0 then
	print(failures .. " tests failed")
	os.exit(1)
end
print("all tests passed")
