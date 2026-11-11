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
	check(in_rotation or maps.OFFLINE[id], id .. ": is in the online rotation (or an arena of a single level)")
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
	-- against a wall the gust stops: robot 1 at the left edge pushed to the left
	local h = started(3, "lussuria", { players = C.MODES["2v2"] })
	local rb = h.robots[1]
	rb.x = 100
	rb.y = h.terrain:ground_below(100, 600)
	h.hz.dir = -1
	h.order_pos = #h.order
	h:end_turn()
	check(rb.x >= 44 * 1.5 + game.ROBOT_HALF_W - 1 and not h:terrain_collides(rb.x, rb.y), "lussuria: a wall stops the gust")
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

-- Flegetonte: the pools of blood set alight, once
do
	local g = started(5, "flegetonte")
	local rb, free = g.robots[1], g.robots[2]
	for i, m in ipairs(maps.get("flegetonte").blood) do
		local cx = (m[1] + m[2]) / 2
		local ground = g.terrain:ground_below(cx, m[4] + 30)
		check(ground and ground >= m[3] and ground <= m[4], "flegetonte: pool " .. i .. " has its ground inside the rectangle")
	end
	local m = maps.get("flegetonte").blood[1]
	rb.x, rb.y = (m[1] + m[2]) / 2, g.terrain:ground_below((m[1] + m[2]) / 2, m[4] + 30)
	rb.vx, rb.vy, rb.grounded = 0, 0, true
	run(g, 3)
	check(rb.status.burn ~= nil, "flegetonte: a robot in the blood burns")
	check(free.status.burn == nil, "flegetonte: one on the bank does not")
end

-- Sabbione: the fire rain
do
	local g = started(5, "sabbione")
	local hz = g.hz
	check(#hz.marks == C.FIRE_RAIN.count, "sabbione: four shadows announce the rain")
	local victim = g.robots[1]
	hz.stones = { { x = victim.x, y = victim.y + 200 } }
	hz.marks = {}
	run(g, 120)
	check(#hz.stones == 0 and victim.status.burn ~= nil and victim.hp < 100, "sabbione: a stone that hits a robot hurts and sets it alight")
	g.order_pos = #g.order
	g.current = g.order[#g.order]
	g:pop_events()
	g:end_turn()
	local fire
	for _, e in ipairs(g:pop_events()) do if e.type == "hail" then fire = e.fire end end
	check(fire == true, "sabbione: the event says it is fire")
end

-- Malebolge: the cracked bridges crumble under a robot, and under a shot
do
	local g = started(5, "malebolge")
	local br = maps.get("malebolge").bridges
	local hz = g.hz
	check(#hz.t == 2 and hz.t[1] == 0 and hz.t[2] == 0, "malebolge: two quiet bridges at the start")
	for i, b in ipairs(br) do
		local cx = (b[1] + b[2]) / 2
		check(g.terrain:solid(cx, b[4] - 3) and not g.terrain:solid(cx, b[3] - 12), "malebolge: bridge " .. i .. " is in the mask and nothing is under it")
	end
	local b = br[1]
	local rb = g.robots[1]
	rb.x, rb.y, rb.vx, rb.vy, rb.grounded = (b[1] + b[2]) / 2, b[4], 0, 0, true
	run(g, 3)
	check(hz.t[1] > 0 and hz.t[2] == 0, "malebolge: stepping on a bridge starts only its crumbling")
	run(g, C.BRIDGE.delay + 2)
	check(hz.t[1] == -1 and not g.terrain:solid((b[1] + b[2]) / 2, b[4] - 3), "malebolge: the bridge falls")
	run(g, 120)
	check(rb.dead or rb.y < b[3], "malebolge: whoever was on it falls")
	-- a shot that takes cells off the second bridge
	local c = br[2]
	g.terrain:carve((c[1] + c[2]) / 2, (c[3] + c[4]) / 2, 8)
	run(g, 3)
	check(hz.t[2] > 0, "malebolge: a shot makes the bridge tremble")
end

-- Cocito: the ice slides
do
	local g = started(5, "cocito")
	local p = started(5, "pavimento")
	local function slide(game_)
		local rb = game_.robots[game_.current]
		for _ = 1, 40 do game_:step({ right = true, hold = true }) end
		local x = rb.x
		for _ = 1, 60 do game_:step() end
		return rb.x - x
	end
	local on_ice, on_floor = slide(g), slide(p)
	check(on_ice > 10 and on_floor < 1, string.format("cocito: whoever stops keeps sliding (%.0f against %.0f)", on_ice, on_floor))
	check(on_ice < 80, "cocito: and the slide dies out")
end

-- Lucifero: the wings push away from the middle
do
	local g = started(5, "lucifero", { players = C.MODES["2v2"] })
	local mid = 960
	local before = {}
	for i, rb in ipairs(g.robots) do before[i] = math.abs(rb.x - mid) end
	g.order_pos = #g.order
	g.current = g.order[#g.order]
	g:pop_events()
	g:end_turn()
	local wings
	for _, e in ipairs(g:pop_events()) do wings = wings or e.type == "wings" end
	local ok = true
	for i, rb in ipairs(g.robots) do ok = ok and math.abs(rb.x - mid) >= before[i] - 0.01 end
	check(wings and ok, "lucifero: the wings push everyone away from the middle")
	check(maps.OFFLINE.lucifero, "lucifero: not in the online rotation")
end

if failures > 0 then
	print(failures .. " tests failed")
	os.exit(1)
end
print("all tests passed")
