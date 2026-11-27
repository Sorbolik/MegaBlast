-- Map hazards (sim/hazards.lua) and the first circles' maps. From the repository root:
--   luajit tests/hazards_test.lua
package.path = "client/?.lua;" .. package.path

local game = require "sim.game"
local config = require "sim.config"
local maps = require "sim.maps"
local hazards = require "sim.hazards"
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

-- Limbo: the lever turns the map upside down
do
	local map = maps.get("limbo")
	local g = started(1, "limbo", { players = C.MODES["2v2"] })
	local hz = g.hz
	check(g.gravity == game.GRAVITY, "limbo: the usual gravity")
	check(#map.respawns == 12 and #map.levers >= 20, "limbo: 12 respawns and at least 20 studs for the lever")
	-- every respawn is on steel on both faces, every stud is steel
	local both = true
	for _, s in ipairs(map.respawns) do
		local c = g.terrain.cell
		both = both and g.terrain:get(math.floor(s.x / c), math.floor(s.y / c) - 1) == 2
			and g.terrain:get(math.floor(s.x / c), math.floor((g.WORLD_H - s.y2) / c)) == 2
			and not g.terrain:solid(s.x, s.y + 1)
	end
	check(both, "limbo: the respawns stand on steel beams free on both faces")
	local steel, blocked = true, {}
	for i, s in ipairs(map.levers) do
		steel = steel and g.terrain:get(math.floor(s.x / 3), math.floor(s.y / 3)) == 2
		-- the knob leans to one side, then to the other
		for _, t in ipairs({ C.LEVER.tilt, -C.LEVER.tilt }) do
			local c, sn = math.cos(t), math.sin(t)
			local kx, ky = s.x + (s.dx * c - s.dy * sn) * C.LEVER.out, s.y + (s.dx * sn + s.dy * c) * C.LEVER.out
			if g.terrain:solid(kx, ky) then blocked[#blocked + 1] = i end
		end
	end
	check(steel, "limbo: every stud of the lever is steel")
	check(#blocked == 0, "limbo: the knob is out of the terrain on both sides (" .. table.concat(blocked, ",") .. ")")
	check(hz.flip == 0 and hz.at >= 1 and hz.at <= #map.levers, "limbo: the lever starts on a stud, the map the right way up")
	-- the map mirrors: a cell and its mirror swap, robots too
	local before = {}
	for i = 1, #g.terrain.data do before[i] = g.terrain.data[i] end
	local rb = g.robots[1]
	local x0, y0 = rb.x, rb.y
	local kx, ky = hazards.lever_knob(g, hz)
	local at = hz.at
	hazards.blast(g, kx, ky, 10, 1)
	g:step()
	check(hz.flip == 1 and hz.n == 1, "limbo: a blast on the knob flips the map")
	local credit = true
	for _, o in ipairs(g.robots) do
		if (o.team ~= rb.team) ~= (o.last_hit == rb.id) then credit = false end
	end
	check(credit, "limbo: whoever pulls the lever hit all their enemies (the falls are their kills)")
	local w, h, same = g.terrain.w, g.terrain.h, true
	for _, cy in ipairs({ 0, 40, 100, 200, 359 }) do
		for cx = 0, w - 1, 7 do
			if g.terrain.data[cy * w + cx + 1] ~= before[(h - 1 - cy) * w + (w - 1 - cx) + 1] then same = false end
		end
	end
	check(same, "limbo: the terrain is the one before turned half a turn")
	check(math.abs(rb.y - (g.WORLD_H - y0 - g.ROBOT_H)) < 1e-6 and math.abs(rb.x - (g.WORLD_W - x0)) < 1e-6 and not rb.grounded,
		"limbo: the robots turn with the map and fall")
	check(hz.at ~= at, "limbo: the lever jumps to another stud")
	check(hz.freeze == C.LEVER.freeze - 1 or hz.freeze == C.LEVER.freeze, "limbo: time stops for a second")
	-- in the freeze nothing moves, not even the turn clock
	local timer, ry = g.timer, rb.y
	run(g, 20)
	check(g.timer == timer and rb.y == ry, "limbo: in the freeze nothing moves")
	check(hz.ly[1] ~= nil, "limbo: where each one lands is known")
	run(g, C.LEVER.freeze)
	check(rb.y < ry, "limbo: after the freeze everyone falls")
	-- the respawns swapped face
	check(g.spawn_spots[1].y == map.respawns[1].y2 and g.spawn_spots[1].x == g.WORLD_W - map.respawns[1].x,
		"limbo: the respawns are on the other face of the beams, on the other side")
	-- in the cool down nothing pulls it, then a body does
	kx, ky = hazards.lever_knob(g, hz)
	hazards.blast(g, kx, ky, 10, 1)
	g:step()
	check(hz.n == 1, "limbo: right after a flip the lever rests")
	run(g, C.LEVER.cool + 10)
	kx, ky = hazards.lever_knob(g, hz)
	local o = g.robots[2]
	o.x, o.y = kx, ky - g.HURT_Y
	g:step()
	check(hz.n == 2 and hz.flip == 0 and hz.by == 2, "limbo: touching the knob with the body flips it back")
	-- the same seed gives the same flips: client and server agree
	local function play(seed)
		local a = started(seed, "limbo", { players = C.MODES["2v2"] })
		for _ = 1, 3 do
			local x, y = hazards.lever_knob(a, a.hz)
			hazards.blast(a, x, y, 10, a.current)
			run(a, C.LEVER.freeze + C.LEVER.cool + 5)
		end
		return a.hz.at, a.hz.n, a:fingerprint()
	end
	local a1, n1, f1 = play(7)
	local a2, n2, f2 = play(7)
	check(a1 == a2 and n1 == n2 and f1 == f2 and n1 == 3, "limbo: the flips are the same with the same seed")
	-- the next stud is far from whoever pulled it
	local far, total = 0, 0
	for seed = 1, 40 do
		local b = started(seed, "limbo")
		local x, y = hazards.lever_knob(b, b.hz)
		hazards.blast(b, x, y, 10, 1)
		b:step()
		local lx, ly = b.hz.lx[1], b.hz.ly[1]
		local sx, sy = hazards.lever_spot(b, b.hz, b.hz.at)
		if ly >= 0 then
			total = total + 1
			local dx, dy = sx - lx, sy - ly
			if dx * dx + dy * dy > C.LEVER.near * C.LEVER.near then far = far + 1 end
		end
	end
	check(total > 0 and far >= total * 0.8, string.format("limbo: the lever reappears far from the puller (%d of %d)", far, total))
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

-- The risk of each hazard (hazards.risk): what the bots see of it
do
	local function risk_of(id, seed)
		local g = started(seed or 1, id)
		return g, hazards.risk(g)
	end
	local g, f = risk_of("pavimento")
	check(f == nil, "risk: a map without a hazard has none")
	local function put(g, rb, x, y)
		rb.x, rb.y = x, y or g.terrain:ground_below(x, g.terrain.h * g.terrain.cell - 1)
		rb.facing = 1
		return rb
	end
	-- hail: under a mark it hurts, far from every mark it does not
	g, f = risk_of("gola")
	local mark = g.hz.marks[1]
	local under = put(g, g.robots[1], mark)
	check(f(under) >= C.HAIL.blast.damage_min, "risk: gola: under a shadow of the hail it hurts")
	local free
	for x = 300, 1500, 20 do
		local far = true
		for _, m in ipairs(g.hz.marks) do far = far and math.abs(m - x) > 120 end
		if far and g.terrain:ground_below(x, g.terrain.h * g.terrain.cell - 1) then free = x break end
	end
	check(f(put(g, g.robots[2], free)) == 0, "risk: gola: away from the shadows nothing")
	-- water: under the next surface it kills
	g, f = risk_of("ira")
	check(f({ x = 800, y = g.hz.level - 5, facing = 1 }) >= hazards.DEATH, "risk: ira: under the water it kills")
	check(f({ x = 800, y = g.hz.level + C.WATER.step * 4, facing = 1 }) == 0, "risk: ira: high above it is safe")
	-- tombs: standing in one burns
	g, f = risk_of("eresia")
	local t = g.tombs[1]
	check(f({ x = (t[1] + t[2]) / 2, y = (t[3] + t[4]) / 2 }) == C.STATUS.burn.damage, "risk: eresia: a tomb burns")
	-- bridges: on a bridge that stands it kills, once fallen it does not
	g, f = risk_of("malebolge")
	local b = g.bridges[1]
	local on = { x = (b[1] + b[2]) / 2, y = b[4], facing = 1 }
	check(f(on) >= hazards.DEATH, "risk: malebolge: on a bridge it kills")
	-- boulders: on the way of the rock it hurts, far from it not
	g, f = risk_of("avarizia")
	local r0 = g.rocks[1]
	local y0 = g.terrain:ground_below(r0.x, g.terrain.h * g.terrain.cell - 1)
	check(f({ x = r0.x + r0.dir * 100, y = y0, facing = 1 }) == C.BOULDER.damage, "risk: avarizia: on the way of a rock it hurts")
	-- wind: the void at the edge in the way of the gust kills; the same spot against the gust does not
	g, f = risk_of("lussuria")
	local mid = g.terrain.cell * (g.terrain.w - 2 * g.terrain.ox) / 2
	local function risks_at(x)
		local y = g.terrain:ground_below(x, g.terrain.h * g.terrain.cell - 1)
		return y and f({ x = x, y = y, facing = 1 }) or 0
	end
	check(risks_at(mid) < hazards.DEATH, "risk: lussuria: the middle of the map is safe")
	-- ice with wings: the push away from the middle kills at the edge of the lake
	g, f = risk_of("lucifero")
	local died = false
	for x = 0, g.terrain.cell * (g.terrain.w - 2 * g.terrain.ox), 12 do
		local y = g.terrain:ground_below(x, g.terrain.h * g.terrain.cell - 1)
		if y and f({ x = x, y = y, facing = 1 }) >= hazards.DEATH then died = true end
	end
	check(died, "risk: lucifero: somewhere the ice or the wings kill")
end

-- The bots mind it more or less according to their level
do
	local bot = require "sim.bot"
	check(bot.new(1, 9, 1).liv.pericolo == 1, "bot: the hard levels mind the hazard in full")
	local easy = bot.new(1, 1, 1).liv.pericolo
	check(easy < 1 and easy >= 0, "bot: the easy levels mind it less")
end

if failures > 0 then
	print(failures .. " tests failed")
	os.exit(1)
end
print("all tests passed")
