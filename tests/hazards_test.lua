-- Map hazards (sim/hazards.lua) and the first circles' maps. From the repository root:
--   luajit tests/hazards_test.lua
package.path = "client/?.lua;" .. package.path

local game = require "sim.game"
local config = require "sim.config"
local maps = require "sim.maps"
local C = config

local failures = 0
local function check(cond, msg)
	if cond then
		print("ok   " .. msg)
	else
		print("FAIL " .. msg)
		failures = failures + 1
	end
end

local function run(g, ticks, input)
	for _ = 1, ticks do g:step(input) end
end

-- the 3-2-1 first
local function started(seed, id, opts)
	opts = opts or {}
	local g = game.new(seed, id, opts)
	run(g, 5)
	return g
end

-- Every circle map: spawns and random starts rest on the terrain, 1 v 1 and 2 v 2
for _, id in ipairs(maps.CIRCLES) do
	check(maps.maps[id] ~= nil, id .. ": is a map")
	local in_rotation = false
	for _, r in ipairs(maps.ROTATION) do in_rotation = in_rotation or r == id end
	check(in_rotation, id .. ": is in the online rotation")
	local ok = true
	for seed = 1, 6 do
		for _, players in ipairs({ C.MODES["1v1"], C.MODES["2v2"] }) do
			local g = game.new(seed, id, { players = players, random_spawns = true })
			run(g, 120)
			for _, rb in ipairs(g.robots) do
				if not rb.grounded or rb.dead or g:terrain_collides(rb.x, rb.y) then ok = false end
			end
		end
	end
	check(ok, id .. ": every robot starts resting on the ground, in 1v1 and 2v2")
	local g = game.new(1, id, { players = C.MODES["2v2"] })
	local free = true
	for _, rb in ipairs(g.robots) do free = free and not g:robot_collides(rb.x, rb.y, rb) and g.terrain:solid(rb.x, rb.y - 1) end
	check(free, id .. ": the fixed spawns stand on the ground")
end

-- Limbo: less gravity, same jump speed: higher and longer
do
	local low, normal = started(1, "limbo"), started(1, "pavimento")
	check(math.abs(low.gravity - game.GRAVITY * maps.get("limbo").gravity) < 1e-9, "limbo: gravity from the map")
	check(normal.gravity == game.GRAVITY, "the other maps keep the usual gravity")
	local function apex(g)
		local rb = g.robots[1]
		local y0 = rb.y
		local top = y0
		local input = { jump = true, hold = true }
		for _ = 1, 120 do
			g:step(input)
			if rb.y > top then top = rb.y end
		end
		return top - y0
	end
	local a, b = apex(low), apex(normal)
	check(a > b * 1.4, string.format("limbo: the jump is higher (%.0f against %.0f)", a, b))
	-- a shot flies farther: the range of a missile at 45 degrees on flat ground
	local function range(g)
		local vx, vy = math.cos(0.78) * game.MISSILE_SPEED, math.sin(0.78) * game.MISSILE_SPEED
		local gr = g.gravity * game.MISSILE_GRAVITY
		return vx * (2 * vy / gr)
	end
	check(range(low) > range(normal) * 1.5, "limbo: the shots fly farther")
end

-- Lussuria: the storm
do
	local g = started(3, "lussuria", { players = C.MODES["2v2"] })
	check(g.hz and (g.hz.dir == 1 or g.hz.dir == -1), "lussuria: the storm has a direction from the start")
	local a, b = g.robots[1], g.robots[3]
	local x1, x3, dir = a.x, b.x, g.hz.dir
	-- close the round: the last in the order ends its turn
	g.order_pos = #g.order
	g.current = g.order[#g.order]
	g:pop_events()
	g:end_turn()
	local gust
	for _, e in ipairs(g:pop_events()) do
		if e.type == "gust" then gust = e end
	end
	check(gust and gust.dir == dir, "lussuria: the gust blows the way shown")
	local moved1, moved3 = (a.x - x1) * dir, (b.x - x3) * dir
	check(moved1 >= 0 and moved1 <= C.WIND.step + 0.01 and moved3 >= 0 and moved3 <= C.WIND.step + 0.01,
		string.format("lussuria: the gust moves a robot at most a step (%.0f, %.0f)", moved1, moved3))
	check(moved1 > 0 or moved3 > 0, "lussuria: somebody got moved")
	check(not g:terrain_collides(a.x, a.y) and not g:terrain_collides(b.x, b.y), "lussuria: nobody ends inside a wall")
	check(g.hz.dir == 1 or g.hz.dir == -1, "lussuria: the next gust has its direction")
	-- no wall at the edge: a gust to the left carries a robot standing near it out of the map
	local h = started(3, "lussuria", { players = C.MODES["2v2"] })
	local rb = h.robots[1]
	rb.x = 40
	rb.y = h.terrain:ground_below(40, 700)
	h.hz.dir = -1
	h.order_pos = #h.order
	h:end_turn()
	check(rb.x < 40 and not h:terrain_collides(rb.x, rb.y), "lussuria: no wall at the edge, the gust carries on")
	-- the other maps have no hazard and no gust
	local p = started(3, "pavimento")
	p.order_pos = #p.order
	p:pop_events()
	p:end_turn()
	local any = false
	for _, e in ipairs(p:pop_events()) do any = any or e.type == "gust" or e.type == "hail" end
	check(p.hz == nil and not any, "pavimento: no hazard")
end

-- Gola: the hail
do
	local g = started(5, "gola")
	local hz = g.hz
	check(#hz.marks == C.HAIL.count and #hz.stones == 0, "gola: three shadows announce the hail, no stone yet")
	local ok = true
	for i, x in ipairs(hz.marks) do
		ok = ok and g.terrain:ground_below(x, game.WORLD_H - 1) ~= nil and (i == 1 or x - hz.marks[i - 1] >= C.HAIL.gap)
	end
	check(ok, "gola: the shadows are on the ground, apart from each other")
	local marks = { hz.marks[1], hz.marks[2], hz.marks[3] }
	g.order_pos = #g.order
	g.current = g.order[#g.order]
	g:pop_events()
	g:end_turn()
	local announced = false
	for _, e in ipairs(g:pop_events()) do announced = announced or e.type == "hail" end
	check(announced and #hz.stones == C.HAIL.count, "gola: at the end of the round the stones start to fall")
	local differs = false
	for i, x in ipairs(hz.marks) do differs = differs or x ~= marks[i] end
	check(differs, "gola: the new shadows are somewhere else")
	check(require("sim.hazards").busy(g), "gola: the turn does not end under the stones")
	-- they fall on the shadows, one explosion each
	local booms = {}
	for _ = 1, 600 do
		g:advance(nil, false)
		for _, e in ipairs(g:pop_events()) do
			if e.type == "explosion" then booms[#booms + 1] = e.x end
		end
		if #hz.stones == 0 then break end
	end
	check(#hz.stones == 0 and #booms == C.HAIL.count, "gola: every stone blows up")
	table.sort(booms)
	local same = #booms == #marks
	for i, x in ipairs(marks) do same = same and math.abs(booms[i] - x) < 1 end
	check(same, "gola: where the shadows said")
end

-- Gola: the mud slows, once, whoever stands in it
do
	local g = started(5, "gola")
	g.hz.marks = {}   -- no hail in the way
	local rb, free = g.robots[1], g.robots[2]
	for i, m in ipairs(maps.get("gola").mud) do
		local cx = (m[1] + m[2]) / 2
		local ground = g.terrain:ground_below(cx, m[4] + 30)
		check(ground >= m[3] and ground <= m[4], "gola: pool " .. i .. " has its ground inside the rectangle")
	end
	local m = maps.get("gola").mud[1]
	rb.x, rb.y = (m[1] + m[2]) / 2, g.terrain:ground_below((m[1] + m[2]) / 2, m[4] + 30)
	rb.vx, rb.vy, rb.grounded = 0, 0, true
	run(g, 3)
	check(rb.status.slow ~= nil, "gola: a robot in the mud is slowed")
	check(free.status.slow == nil, "gola: a robot on the hill is not")
end

-- the end of a round, as the last turn of the order closes it
local function close_round(g)
	g.order_pos = #g.order
	g.current = g.order[#g.order]
	g:pop_events()
	g:end_turn()
end

-- Avarizia: the boulders
do
	local g = started(2, "avarizia", { players = C.MODES["2v2"] })
	local hz = g.hz
	check(hz and #hz.rocks == 0, "avarizia: no boulder before the first round ends")
	local clear = {}
	for _, rb in ipairs(g.robots) do clear[#clear + 1] = rb end
	close_round(g)
	check(#hz.rocks == #maps.get("avarizia").rocks and require("sim.hazards").busy(g), "avarizia: a boulder starts from each slope, the turn waits")
	-- away from the robots, they come down to the middle and crumble
	for _, rb in ipairs(g.robots) do rb.x, rb.y, rb.vy = 960, 3000, 0 end
	local x0, top = hz.rocks[1].x, hz.rocks[1].y
	local fastest, ticks = 0, 0
	for _ = 1, 3000 do
		for _, r in ipairs(hz.rocks) do fastest = math.max(fastest, r.v) end
		for _, rb in ipairs(g.robots) do rb.x, rb.y, rb.vy, rb.vx = 960, 3000, 0, 0 end
		g:advance(nil, false)
		ticks = ticks + 1
		if #hz.rocks == 0 then break end
	end
	check(#hz.rocks == 0, string.format("avarizia: the boulders stop and crumble (%d ticks)", ticks))
	check(fastest > 150 and fastest <= C.BOULDER.vmax + 0.01, string.format("avarizia: they speed up downhill (%.0f)", fastest))
	-- a robot in the way is hurt once and shoved
	local h = started(2, "avarizia")
	local rb = h.robots[2]
	local sx = maps.get("avarizia").rocks[1].x
	h.hz.rocks[1] = { x = sx + 120, y = h.terrain:ground_below(sx + 120, 500), dir = 1, v = 200, hit = {} }
	rb.x, rb.y, rb.vx, rb.vy = sx + 180, h.terrain:ground_below(sx + 180, 500), 0, 0
	local hp = rb.hp
	for _ = 1, 60 do
		rb.vx, rb.vy = 0, 0
		h:advance(nil, false)
	end
	check(rb.hp == hp - C.BOULDER.damage, "avarizia: a boulder hurts whoever it meets, once")
	check(not h:terrain_collides(rb.x, rb.y), "avarizia: and nobody ends inside a wall")
end

-- Ira: the rising water
do
	local g = started(2, "ira")
	local hz = g.hz
	local y0 = maps.get("ira").water.y
	check(hz.level == y0 and hz.rise == false, "ira: the water starts low and does not rise in the first round")
	close_round(g)
	check(hz.level == y0 and hz.rise == true, "ira: the first round end brings no rise, the next will")
	close_round(g)
	check(hz.level == y0 + C.WATER.step, "ira: from the third round it rises at the end of the round")
	-- whoever is under the surface is out; the others are not
	local low, high = g.robots[1], g.robots[2]
	low.x, low.y, low.vy = 165, g.terrain:ground_below(165, 900), 0
	high.x, high.y, high.vy = 960, 700, 0
	hz.level = low.y + 5
	g:advance(nil, false)
	check(low.dead and not high.dead, "ira: the water drowns whoever it covers")
	-- the other maps have no water and keep the old rules
	check(started(2, "pavimento").hz == nil, "pavimento: no water")
end

-- Eresia: the tombs
do
	local g = started(4, "eresia")
	local hz = g.hz
	local tombs = maps.get("eresia").tombs
	local hazards = require "sim.hazards"
	for i, m in ipairs(tombs) do
		local cx = (m[1] + m[2]) / 2
		local ground = g.terrain:ground_below(cx, m[4] + 30)
		check(ground >= m[3] and ground <= m[4], "eresia: tomb " .. i .. " has its floor inside the rectangle")
	end
	check(hazards.tomb_open(hz, 1) ~= hazards.tomb_open(hz, 2), "eresia: neighbouring tombs are one open, one closed")
	local open_i, closed_i
	for i = 1, #tombs do
		if hazards.tomb_open(hz, i) then open_i = open_i or i else closed_i = closed_i or i end
	end
	local a, b = g.robots[1], g.robots[2]
	local function stand(rb, m)
		rb.x = (m[1] + m[2]) / 2
		rb.y = g.terrain:ground_below(rb.x, m[4] + 30)
		rb.vx, rb.vy, rb.grounded = 0, 0, true
	end
	stand(a, tombs[open_i])
	stand(b, tombs[closed_i])
	run(g, 3)
	check(a.status.burn ~= nil and b.status.burn == nil, "eresia: an open tomb sets alight, a closed one is a shelter")
	-- at the end of the round the halves swap
	local was = hazards.tomb_open(hz, open_i)
	close_round(g)
	check(hazards.tomb_open(hz, open_i) ~= was, "eresia: the tombs swap at the end of the round")
	local seen
	for _, e in ipairs(g:pop_events()) do seen = seen or e.type == "tombs" end
	check(seen, "eresia: the swap is announced")
end

if failures > 0 then
	print(failures .. " tests failed")
	os.exit(1)
end
print("all tests passed")
