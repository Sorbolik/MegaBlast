-- Tests of the online playout (main/playout.lua): states that arrive unevenly
-- (one late, then several together, like the phone's WiFi) must be drawn at
-- an even pace, and a robot that teleports must not slide. From the
-- repository root:
--   luajit tests/playout_test.lua
package.path = "client/?.lua;" .. package.path
local playout = require "main.playout"

local fails = 0
local function check(ok, what)
	if not ok then
		fails = fails + 1
		print("FAIL " .. what)
	end
end

-- a pose with one robot; the "world" is a robot moving 6 px per state
local function new_pose() return { r = { { x = 0, y = 0 } } } end
local function capture(pose, g) pose.r[1].x, pose.r[1].y = g.x, g.y end
local PERIOD = 2 / 60

local function drawn(a, b, k) return a.r[1].x + (b.r[1].x - a.r[1].x) * k end

-- Plays n states that leave the server every PERIOD and arrive at arrival(i);
-- the screen runs at 120 Hz. Returns the drawn positions per frame.
local function play(arrival, n, teleport_at)
	local g = { x = 0, y = 0 }
	local p = playout.new(new_pose, capture, PERIOD)
	playout.reset(p, g)
	local xs, snapped = {}, {}
	local nxt, t, dt = 1, 0, 1 / 120
	while nxt <= n or t < arrival(n) + 0.2 do
		t = t + dt
		while nxt <= n and arrival(nxt) <= t do
			g.x = nxt * 6
			local snaps
			if nxt == teleport_at then
				g.x = g.x + 500
				snaps = { [1] = true }
			elseif teleport_at and nxt > teleport_at then
				g.x = g.x + 500
			end
			playout.arrive(p, g, t, snaps)
			nxt = nxt + 1
		end
		local a, b, k = playout.advance(p, dt, t, function(i) snapped[#snapped + 1] = i end)
		xs[#xs + 1] = drawn(a, b, k)
	end
	return xs, snapped
end

-- steps between frames while moving (after the start and before the end)
local function steps(xs)
	local d = {}
	for i = 2, #xs do d[#d + 1] = xs[i] - xs[i - 1] end
	return d
end

-- 1. on time: it moves every frame, 6 px per state = 1.5 px per frame at 120 Hz
do
	local xs = play(function(i) return i * PERIOD + 0.02 end, 120)
	local d = steps(xs)
	local stops, back = 0, 0
	for i = 30, #d - 60 do
		if d[i] < 0.5 then stops = stops + 1 end
		if d[i] < 0 then back = back + 1 end
	end
	check(stops == 0, "in orario: si ferma " .. stops .. " volte")
	check(back == 0, "in orario: torna indietro")
end

-- 2. WiFi: every 15 states a 110 ms stop, then those held back arrive together
do
	local function arrival(i)
		local hold = (i % 15 >= 12 or i % 15 == 0) and 0.11 or 0
		local base = math.floor((i - 1) / 15) * 15 + 15
		return hold > 0 and (base * PERIOD + 0.02) or (i * PERIOD + 0.02)
	end
	local xs = play(arrival, 300)
	local d = steps(xs)
	-- after the first stop the playout has learnt the delay: from there on it must not stop
	local stops, worst = 0, 0
	for i = 150, #d - 80 do
		if d[i] < 0.3 then stops = stops + 1 end
		worst = math.max(worst, d[i])
	end
	check(stops == 0, "WiFi: si ferma " .. stops .. " volte dopo aver imparato il ritardo")
	-- it never jumps ahead: at most a little faster than 1.5 px per frame
	check(worst < 1.5 * 1.6, string.format("WiFi: salto di %.1f px in un frame", worst))
end

-- 3. teleport: the robot reappears in one frame, it doesn't slide for 500 px
do
	local xs, snapped = play(function(i) return i * PERIOD + 0.02 end, 60, 30)
	local d = steps(xs)
	local big = 0
	for i = 1, #d do
		if d[i] > 100 then big = big + 1 end
	end
	check(big == 1, "teletrasporto: " .. big .. " salti grandi invece di uno")
	check(#snapped == 1 and snapped[1] == 1, "teletrasporto: il robot non è stato spostato")
end

if fails == 0 then print("OK playout") end
