-- Simulation tests. From the repository root:
--   lua tests/sim_test.lua
package.path = "client/?.lua;" .. package.path

local game = require "sim.game"
local config = require "sim.config"
local melee = require "sim.melee"
local maps = require "sim.maps"
local terrain = require "sim.terrain"

-- The tests run on the floor ("pavimento", some on the pit, "fossa").

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

local function solid_count(t)
	local n = 0
	for i = 1, #t.data do if t.data[i] ~= 0 then n = n + 1 end end
	return n
end

-- Every map: robots appear resting on the terrain
for _, id in ipairs(maps.order) do
	local m = game.new(42, id)
	run(m, 120)
	check(m.robots[1].grounded and m.robots[2].grounded, id .. ": robots rest on the terrain")
	check(not m.robots[1].dead and not m.robots[2].dead, id .. ": no robot dies at startup")
end

-- Real matches: without a map the seed picks it, among those of maps.ROTATION
do
	local seen = {}
	for seed = 1, #maps.ROTATION do
		local id = game.new(seed).map
		check(id == game.new(seed).map, "same seed, same map")
		seen[id] = true
	end
	for _, id in ipairs(maps.ROTATION) do
		check(maps.maps[id] and seen[id], id .. ": comes up in matches")
	end
end

local g = game.new(42, "pavimento")
run(g, 120)

-- The robot on turn walks
local x0, x2 = g.robots[1].x, g.robots[2].x
run(g, 60, { right = true })
check(g.robots[1].x > x0 + 20, "the robot walks to the right")
check(g.robots[2].x == x2, "the opponent stays still")

-- Vertical jump: without a direction the robot goes straight up and lands at the same spot
local rb = g.robots[1]
local sx, sy = rb.x, rb.y
g:step({ jump = true })
check(not rb.grounded, "the robot jumps")
local top = rb.y
for _ = 1, 120 do
	g:step()
	top = math.max(top, rb.y)
end
check(rb.grounded and rb.x == sx, "the jump without direction is vertical")
check(math.abs(top - sy - rb.stats.jump_height) < 4, "the jump reaches the stats height")

-- Air control: jump straight and then move in mid-air
g:step({ jump = true })
run(g, 20, { left = true })
check(rb.x < sx - 10 and not rb.grounded, "in the air the robot moves left")
run(g, 120)

-- No inertia in the air: the direction changes at once, at air_speed
do
	local q = game.new(42, "pavimento", { players = { { team = 1, stats = { air_speed = 60 } }, { team = 2 } } })
	run(q, 120)
	local r = q.robots[1]
	q:step({ jump = true, right = true })
	run(q, 10, { right = true })
	q:step({ left = true })
	check(not r.grounded and r.vx == -60, "in the air the direction changes at once (" .. r.vx .. ")")
end

-- Stats change the jump height
local hj = game.new(42, "pavimento", { players = { { team = 1, stats = { jump_height = 120 } }, { team = 2 } } })
run(hj, 120)
local hy = hj.robots[1].y
hj:step({ jump = true })
local htop = hy
for _ = 1, 120 do hj:step(); htop = math.max(htop, hj.robots[1].y) end
check(htop - hy > 100, "high jump_height jumps higher")

-- Steel can't be dug
local tt = g.terrain
local before_steel, before_dirt = 0, 0
for i = 1, #tt.data do
	if tt.data[i] == terrain.STEEL then before_steel = before_steel + 1 end
end
tt:carve(250, 40, 40)
local after_steel = 0
for i = 1, #tt.data do
	if tt.data[i] == terrain.STEEL then after_steel = after_steel + 1 end
end
check(before_steel > 0 and after_steel == before_steel, "steel pipes remain after an explosion")

-- Shooting: after the shot you can still move for a few seconds, then the turn passes
run(g, 60)
local fx = rb.x
g:step({ fire = { angle = math.rad(60), power = 0.6 } })
check(g.phase == "aim" and g.window > 0 and g.used.primary, "the missile leaves and the second attack window opens")
run(g, 30, { left = true })
check(rb.x < fx - 10, "after the shot the robot moves")
local exploded = false
for _ = 1, 900 do
	g:step()
	for _, e in ipairs(g:pop_events()) do
		if e.type == "explosion" or e.type == "miss" then exploded = true end
	end
	if g.current == 2 then break end
end
check(exploded, "the missile explodes or leaves the map")
check(g.current == 2, "the turn passes to player 2")
local lx = rb.x
run(g, 30, { left = true })
check(rb.x == lx, "after the retreat the robot no longer moves")

-- Direct explosion on a robot: damage and crater
local g2 = game.new(7, "pavimento")
run(g2, 120)
local r2 = g2.robots[2]
local t0 = solid_count(g2.terrain)
g2:explode(r2.x, r2.y + 2)
check(r2.hp < r2.max_hp, "the explosion does damage")
check(solid_count(g2.terrain) < t0, "the explosion digs a crater")

-- Teleport and Lama di Nucleo ---------------------------------------------

-- An area of open sky to place robots by hand
local function sky_spot(q, x0, w)
	for y = game.WORLD_H - 60, 100, -4 do
		local free = true
		for x = x0 - w, x0 + w, 4 do
			if q:robot_collides(x, y) or q:robot_collides(x, y - 40) then free = false; break end
		end
		if free then return y end
	end
end

local function place(rb, x, y)
	rb.x, rb.y, rb.vx, rb.vy, rb.grounded, rb.knocked = x, y, 0, 0, false, false
end

-- Fires the Rampino and waits for the hook, which flies (config.HOOK.shot_speed):
-- returns the "hook" event (without target or anchor on a miss). ogni() runs on
-- every tick of flight (to keep the puller still)
local function hook(g, angle, ogni)
	local rb = g.robots[g.current]
	g:step({ fire = { angle = angle, power = 1, weapon = "hook" } })
	for _ = 1, 60 do
		for _, e in ipairs(g:pop_events()) do if e.type == "hook" then return e end end
		if not rb.hook_shot then return nil end
		if ogni then ogni() end
		g:step()
	end
end

-- Throwing the orb doesn't end the turn; after 2 seconds the robot is where the orb is
local tp = game.new(42, "pavimento")
run(tp, 120)
tp:pop_events()
local tr = tp.robots[1]
tp:step({ fire = { angle = math.rad(70), power = 0.5, weapon = "teleport" } })
check(tp.orbs[1] ~= nil and tp.phase == "aim", "the orb leaves and the turn goes on")
tp:step()
local ox, oy = tp.orbs[1].x, tp.orbs[1].y
tp:step()
check(tp.orbs[1].x ~= ox or tp.orbs[1].y ~= oy, "the orb flies")
local tp_ev, last_orb
for _ = 1, game.TELEPORT_TICKS do
	if tp.orbs[1] then last_orb = { x = tp.orbs[1].x, y = tp.orbs[1].y } end
	tp:step()
	for _, e in ipairs(tp:pop_events()) do
		if e.type == "teleport" then tp_ev = e end
	end
end
check(tp_ev and tp_ev.type == "teleport", "after a few seconds the robot teleports")
check(tp_ev and math.abs(tp_ev.x - last_orb.x) <= 8 and math.abs(tp_ev.y - (last_orb.y - game.ROBOT_H / 2)) <= 24,
	"the robot appears where the orb is")
check(tp.phase == "aim" and tp.current == 1, "after the teleport you can still attack")
check(tp.orbs[1] == nil, "the orb disappears after the teleport")
check(tr.teleports_left == config.STATS.teleports - 1, "the teleport uses up an orb")
tr.teleports_left = 5
tp:step({ fire = { angle = math.rad(70), power = 0.5, weapon = "teleport" } })
check(tp.orbs[1] ~= nil and tr.teleports_left == 4, "with orbs in hand another one can be thrown, on the first turn too")
tr.teleports_left = 0
tp:step({ fire = { angle = math.rad(70), power = 0.5, weapon = "teleport" } })
check(#tp.orbs == 1, "without orbs the teleport doesn't leave")

-- Several orbs in flight together: each teleports when its time is up, and in
-- between you can shoot. The turn passes only when all are done.
-- A robot that can teleport as much as it likes (for tests)
local function free_tp(r)
	r.teleports_left, r.turns = 99, 2
end

local function multi(plan)
	local q = game.new(42, "pavimento")
	run(q, 120)
	q:pop_events()
	free_tp(q.robots[1])
	local seq = {}
	for i = 1, 900 do
		local f = plan[i]
		if f == "tp" then
			q:step({ fire = { angle = math.rad(90), power = 0.15, weapon = "teleport" } })
		elseif f == "missile" then
			q:step({ fire = { angle = math.rad(60), power = 0.6 } })
		else
			q:step()
		end
		for _, e in ipairs(q:pop_events()) do
			if e.type == "orb" or e.type == "teleport" or e.type == "fire" or e.type == "turn" then
				seq[#seq + 1] = e.type
			end
		end
		if q.current == 2 then break end
	end
	return table.concat(seq, " ")
end
local m1 = multi({ [1] = "tp", [20] = "tp", [40] = "missile" })
check(m1 == "orb orb fire teleport teleport turn", "tp, tp, missile: two teleports and then the turn passes (" .. m1 .. ")")
local m2 = multi({ [1] = "tp", [60] = "tp", [game.TELEPORT_TICKS + 10] = "missile" })
check(m2 == "orb orb teleport fire teleport turn", "tp, tp, teleport, missile, teleport (" .. m2 .. ")")

-- State is kept: whoever is falling keeps falling at the same speed
local function falling(with_orb)
	local q = game.new(42, "pavimento")
	run(q, 120)
	local r = q.robots[1]
	local y = sky_spot(q, 640, 120)
	place(r, 560, y)
	r.vx, r.vy = 40, -250
	if with_orb then
		q.orbs = { { x = 720, y = y + game.ROBOT_H / 2, vx = 0, vy = 0, owner = 1, timer = 1 } }
	end
	q:step()
	return r, y
end
local fr, fy = falling(true)
local nr = falling(false)
check(fr.x == 720 and math.abs(fr.y - fy) < 1, "the teleport carries the robot to the orb's point")
check(fr.vx == nr.vx and fr.vy == nr.vy and fr.vy < -250,
	"the fall speed stays the same after the teleport")
check(not fr.grounded, "the robot isn't set down on the ground")

-- The orb doesn't stick: it touches ground and rolls
local rl = game.new(42, "pavimento")
run(rl, 120)
local rr = rl.robots[1]
local gy = rr.y
rl.orbs = { { x = rr.x + 30, y = gy + 40, vx = 120, vy = -100, owner = 1, timer = 60 } }
local touched_x
for _ = 1, 40 do
	rl:step()
	if rl.orbs[1] and not touched_x and rl.terrain:solid(rl.orbs[1].x, rl.orbs[1].y - 3) then touched_x = rl.orbs[1].x end
end
check(touched_x and rl.orbs[1] and rl.orbs[1].x > touched_x + 10, "the orb rolls after touching ground")
check(rl.orbs[1] and not rl.terrain:solid(rl.orbs[1].x, rl.orbs[1].y), "the orb doesn't go into the terrain")

-- The teleport always happens, even if the orb is at an impossible spot
local im = game.new(42, "pavimento")
run(im, 120)
local ir = im.robots[1]
local tx0 = ir.x
-- a tunnel too narrow for the robot, dug into the solid terrain under its feet
for cx = math.floor((tx0 + 100) / game.CELL), math.floor((tx0 + 110) / game.CELL) do
	im.terrain:set(cx, math.floor((ir.y - 30) / game.CELL), 0)
end
im.orbs = { { x = tx0 + 105, y = ir.y - 30, vx = 0, vy = 0, owner = 1, timer = 1 } }
local im_tp
im:step()
for _, e in ipairs(im:pop_events()) do if e.type == "teleport" then im_tp = e end end
check(im_tp ~= nil, "at the impossible spot it teleports you anyway")
check(im_tp and not im:robot_collides(ir.x, ir.y, ir) and math.abs(ir.x - (tx0 + 105)) <= 48,
	"and puts you at the nearest free point")

-- If the orb leaves the map the teleport takes you there and you fall
local om = game.new(42, "pavimento")
run(om, 120)
om.orbs = { { x = -200, y = -100, vx = 0, vy = 0, owner = 1, timer = 1 } }
om:step()
om:step()
check(om.robots[1].dead, "an orb off the map makes you fall into the void")

-- Slash: hits behind the back and in front
local function sword_game()
	local q = game.new(42, "pavimento")
	run(q, 120)
	q:pop_events()
	local y = sky_spot(q, 640, 300)
	-- a third robot to try the behind + in front combo
	local r3 = {}
	for k, v in pairs(q.robots[2]) do r3[k] = v end
	r3.id = 3
	q.robots[3] = r3
	return q, y
end

local SWORD_TICKS = game.melee_ticks(melee.slash)
local sw, swy = sword_game()
place(sw.robots[1], 640, swy)
place(sw.robots[2], 640 - 25, swy)  -- behind (robot 1 faces right)
place(sw.robots[3], 640 + 25, swy)  -- in front
sw:step({ fire = { angle = 0, power = 1, weapon = "sword" } })
check(sw.used.secondary and sw.window > 0, "the slash is an attack: the second attack window opens")
local order = {}
for _ = 1, SWORD_TICKS do
	sw:step()
	for _, e in ipairs(sw:pop_events()) do
		if e.type == "sword_hit" then order[#order + 1] = e.target end
	end
end
check(#order == 2, "the sword hits whoever is behind and whoever is in front (" .. table.concat(order, " ") .. ")")
check(sw.robots[2].hp == sw.robots[2].max_hp - game.SWORD_DAMAGE and sw.robots[3].hp == sw.robots[3].max_hp - game.SWORD_DAMAGE,
	"each target takes the damage only once")

-- Combo: teleport mid-slash, the blade also catches whoever is at the arrival
-- point (all hits land when the window closes)
local function combo(with_orb)
	local q, y = sword_game()
	place(q.robots[1], 400, y)
	place(q.robots[2], 400 - 25, y)  -- behind, at the starting point
	place(q.robots[3], 800 + 25, y)  -- in front, at the arrival point
	q.robots[3].vy, q.robots[3].vx = 0, 0
	if with_orb then
		q.orbs = { { x = 800, y = y + game.ROBOT_H / 2, vx = 0, vy = 0, owner = 1, timer = 30 } }
	end
	q:step({ fire = { angle = 0, power = 1, weapon = "sword" } })
	local seq = {}
	for _ = 1, SWORD_TICKS do
		q:step()
		for _, e in ipairs(q:pop_events()) do
			if e.type == "sword_hit" then seq[#seq + 1] = "hit" .. e.target end
			if e.type == "teleport" then seq[#seq + 1] = "tp" end
		end
	end
	return table.concat(seq, " ")
end
check(combo(true) == "tp hit2 hit3", "combo: teleport and hit on whoever was behind and whoever is at the arrival (" .. combo(true) .. ")")
check(combo(false) == "hit2", "without an orb the far target isn't hit")

-- The turn waits for the orb and the retreat, then passes to the opponent
local tw = game.new(42, "pavimento")
run(tw, 120)
tw:step({ fire = { angle = math.rad(90), power = 0.2, weapon = "teleport" } })
run(tw, 30)
tw:step({ fire = { angle = 0, power = 1, weapon = "sword" } })
local tw_tp = false
for _ = 1, 900 do
	tw:step()
	for _, e in ipairs(tw:pop_events()) do
		if e.type == "teleport" then tw_tp = tw.current == 1 end
	end
	if tw.current == 2 then break end
end
check(tw_tp, "the turn doesn't pass before the orb is done")
check(tw.current == 2, "after slash and teleport the turn passes")

-- Two attacks per turn and teleports --------------------------------------------------
do

	local MISSILE = { fire = { angle = math.rad(60), power = 0.6 } }
	local SWORD = { fire = { angle = 0, power = 1, weapon = "sword" } }
	local TELE_BTN = { fire = { angle = math.rad(90), power = 0.2, weapon = "teleport" } }

	-- Orb thresholds: within 9 s two, within 17 s one, after that none, never three
	check(game.orbs_for(0) == 2 and game.orbs_for(9 * 60) == 2 and game.orbs_for(9 * 60 + 1) == 1
		and game.orbs_for(17 * 60) == 1 and game.orbs_for(17 * 60 + 1) == 0, "orb thresholds 9 s and 17 s")

	-- First attack after 12 s: one teleport
	local at = game.new(42, "pavimento")
	local ar = at.robots[1]
	run(at, 12 * 60 - 1)
	at:pop_events()
	at:step(MISSILE)
	local gain = 1
	local nev
	for _, e in ipairs(at:pop_events()) do if e.type == "teleports" then nev = e end end
	check(gain >= 1 and ar.teleports_left == config.STATS.teleports + gain and nev and nev.amount == gain,
		"the seconds left at the first attack become teleports (" .. ar.teleports_left .. ")")
	check(at.window == game.AFTER_ATTACK_TICKS, "after the first attack 8 s remain")
	at:step(MISSILE)
	check(not at:can_use("missile") and at.used.primary, "only one weapon per turn")
	local n0 = ar.teleports_left
	run(at, game.AFTER_ATTACK_TICKS - 30)
	check(at:can_use("sword"), "the second attack can be done until the last second")
	at:step(SWORD)
	check(at.used.secondary and at.window > 0, "after the second attack time goes on")
	check(ar.teleports_left == n0, "the second attack gives no teleports")
	check(not at:can_use("missile") and not at:can_use("sword"), "after the two attacks no more attacks")
	local turn_at
	for i = 1, 2000 do
		at:step()
		if at.current == 2 then turn_at = i break end
	end
	check(turn_at and turn_at >= 28, "the turn passes when the 8 s run out")

	-- Any order: first the sword, then the missile
	local ao = game.new(42, "pavimento")
	run(ao, 60)
	ao:step(SWORD)
	run(ao, 30)
	check(ao:can_use("missile"), "after the sword you can still shoot")
	ao:step(MISSILE)
	check(ao.used.primary and ao.used.secondary, "sword and missile in the same turn")

	-- The teleport never goes off by shooting: after the secondary, after the
	-- primary and after both it can still be thrown, like items
	for _, order in ipairs({ { "sword" }, { "missile" }, { "sword", "missile" }, { "missile", "sword" } }) do
		local q = game.new(42, "pavimento")
		run(q, 120)
		free_tp(q.robots[1])
		for _, w in ipairs(order) do
			q:step({ fire = { angle = math.rad(60), power = 0.6, weapon = w } })
		end
		local label = table.concat(order, "+")
		check(q.phase == "aim" and q:can_use("teleport"), "teleport usable after " .. label)
		q:step({ fire = { angle = math.rad(90), power = 0.15, weapon = "teleport" } })
		check(#q.orbs == 1, "the orb leaves after " .. label)
	end

	-- Whoever attacks at the last moment has no time for anything else
	local az = game.new(42, "pavimento")
	run(az, game.TURN_TICKS - 2)
	az:step(MISSILE)
	check(az.used.primary and az.window <= 1, "attacking at the last moment leaves no time")
	run(az, 3)
	check(az.phase ~= "aim", "the turn closes on time even after an attack")

	-- On the first turn every orb can be thrown, the starting ones too (Sergio,
	-- 3 November: no more limit of one), and then the ones earned by attacking
	local ft = game.new(42, "pavimento")
	local fr = ft.robots[1]
	local start = fr.teleports_left
	run(ft, 30)
	for k = 1, start do
		check(ft:can_use("teleport"), "starting orb " .. k .. " usable on the first turn")
		ft:step(TELE_BTN)
	end
	check(not ft:can_use("teleport"), "no orbs left after the starting ones")
	ft:step(MISSILE)
	check(fr.teleports_left == 2, "attacking at once earns two orbs (" .. fr.teleports_left .. ")")
	for k = 1, 2 do
		check(ft:can_use("teleport"), "earned orb " .. k .. " usable on the first turn")
		ft:step(TELE_BTN)
	end
	check(#ft.orbs == start + 2 and fr.teleports_left == 0, "all the orbs leave")

	-- Swapping the second attack for a teleport (Sergio, 29 October)
	local sw = game.new(42, "pavimento")
	local swr = sw.robots[1]
	run(sw, 30)
	check(not sw:can_use("swap"), "no swap before the first attack")
	for _ = 1, swr.teleports_left do sw:step(TELE_BTN) end
	run(sw, 20 * 60)
	sw:step(MISSILE)
	local n_sw = swr.teleports_left
	check(sw:can_use("swap") and not sw:can_use("teleport"), "after the first attack (late, no orbs) you can swap")
	sw:step({ fire = { angle = 0, power = 1, weapon = "swap" } })
	check(swr.teleports_left == n_sw + 1 and sw.used.primary and sw.used.secondary, "the swap gives an orb and closes the attacks")
	check(not sw:can_use("sword") and not sw:can_use("swap"), "after the swap no second attack or other swap")
	check(sw:can_use("teleport"), "the swap orb can be thrown at once")
	sw:step(TELE_BTN)
	check(#sw.orbs >= 1 and swr.teleports_left == n_sw, "the swap orb leaves")
	local sw2 = game.new(42, "pavimento")
	run(sw2, 30)
	sw2:step(MISSILE)
	sw2:step(SWORD)
	check(not sw2:can_use("swap"), "after two attacks no swap")

	-- No cap: orbs pile up
	local fz = game.new(42, "pavimento", { players = { { team = 1, stats = { teleports = 5 } }, { team = 2 } } })
	run(fz, 60)
	fz:step(MISSILE)
	check(fz.robots[1].teleports_left == 7, "teleports pile up without a cap")

	-- Life starts from the config value and can be changed per robot
	local hv = game.new(42, "pavimento", { players = { { team = 1, stats = { max_hp = 200 } }, { team = 2 } } })
	check(hv.robots[1].hp == 200 and hv.robots[2].hp == config.STATS.max_hp, "life from the robot's stats")
end

-- From 2 to 4 players, with teams -------------------------------------------------
do

	-- 2 v 2: teams alternate and teammates start on the same side
	local four = { { team = 1 }, { team = 1 }, { team = 2 }, { team = 2 } }
	for _, id in ipairs(maps.order) do
		local q = game.new(42, id, { players = four })
		run(q, 120)
		local ok = #q.robots == 4
		for _, r in ipairs(q.robots) do ok = ok and r.grounded and not r.dead end
		check(ok, id .. ": four robots appear resting on the terrain")
		local mid = game.WORLD_W / 2
		check((q.robots[1].x < mid) == (q.robots[2].x < mid) and (q.robots[3].x < mid) == (q.robots[4].x < mid)
			and (q.robots[1].x < mid) ~= (q.robots[3].x < mid), id .. ": teammates start on the same side")
	end

	-- Plays the current turn (a missile upwards) and returns who plays next
	local function next_turn(q)
		local cur = q.current
		q:step({ fire = { angle = math.rad(90), power = 0.1 } })
		for _ = 1, 3000 do
			q:step()
			if q.current ~= cur or q.phase == "over" then break end
		end
		return q.current
	end

	local q4 = game.new(42, "pavimento", { players = four })
	check(q4.mode == "2v2" and table.concat(q4.order, " ") == "1 3 2 4",
		"2 v 2: turns A1, B1, A2, B2 (" .. table.concat(q4.order, " ") .. ")")
	local seen4 = { q4.current }
	for _ = 1, 4 do seen4[#seen4 + 1] = next_turn(q4) end
	check(table.concat(seen4, " ") == "1 3 2 4 1", "turns follow the order of the teams (" .. table.concat(seen4, " ") .. ")")
	-- whoever dies starts again after RESPAWN_TICKS, even mid-turn, and doesn't lose their turn
	q4:kill(q4.robots[3])
	run(q4, game.RESPAWN_TICKS)
	check(not q4.robots[3].dead and q4.robots[3].hp == q4.robots[3].max_hp and q4.current == 1,
		"the dead robot starts again in the same turn with full life")
	check(next_turn(q4) == 3, "and plays its turn")
	-- whoever dies in their own turn starts again and the turn goes on
	local own = game.new(42, "pavimento")
	run(own, 30)
	own:kill(own.robots[1], "fell")
	run(own, game.RESPAWN_TICKS + 5)
	check(own.current == 1 and own.phase == "aim" and not own.robots[1].dead and own:can_use("missile"),
		"died in their own turn: starts again and the turn goes on")

	-- Free for all: four teams of one, turns in order of arrival
	local ffa = game.new(42, "pavimento", { players = { { team = 1 }, { team = 2 }, { team = 3 }, { team = 4 } } })
	check(ffa.mode == "ffa" and table.concat(ffa.order, " ") == "1 2 3 4", "free for all: turns 1, 2, 3, 4")
	check(game.new(42, "pavimento").mode == "1v1", "without players it's a 1 v 1")
end

-- Tactical items: traps, shields, trampolines, parachutes, healing circles -------------
do
	-- crates contain only weapons; items drop on their own, visible
	local mix = game.new(5, "pavimento")
	local seen, items = {}, {}
	for _ = 1, 60 do
		mix.crates = {}
		local c = mix:spawn_crate()
		if c then seen[c.weapon] = true end
		local it = mix:spawn_crate(nil, nil, true)
		if it and it.item then items[it.weapon] = true end
	end
	check(not seen.trap and not seen.shield and not seen.trampoline and seen.grenade, "crates contain only weapons")
	check(items.trap and items.shield and items.trampoline, "items drop on the map: traps, shields and trampolines")
	mix.crates = {}
	mix:spawn_crate(nil, nil, true)
	mix:spawn_crate(nil, nil, true)
	check(mix:spawn_crate(nil, nil, true) == nil and mix:spawn_crate() ~= nil,
		"at most " .. config.ITEM_DROPS.max .. " items on the map, crates counted apart")

	-- items can also be used while repositioning and aren't attacks
	local q = game.new(42, "pavimento", { ammo = { trap = 1, shield = 1 } })
	run(q, 60)
	local r1, r2 = q.robots[1], q.robots[2]
	q:step({ fire = { angle = 0, power = 1, weapon = "shield" } })
	check(r1.shield == config.SHIELD.hp and not q.used.primary and not q.used.secondary,
		"the shield turns on and isn't an attack")
	q:step({ fire = { angle = math.rad(60), power = 0.6 } })
	q:step({ fire = { angle = 0, power = 1, weapon = "sword" } })
	check(q.window > 0 and q:can_use("trap"), "after the two attacks the trap can still be placed")
	q:step({ fire = { angle = 0, power = 1, weapon = "trap" } })
	local trap = q.placed[1]
	check(trap and trap.kind == "trap" and not trap.armed and r1.ammo.trap == 0, "the trap is placed at the feet, not armed yet")

	-- shield: absorbs damage and ends at the start of the owner's next turn
	q:hurt(r1, 20, r2)
	check(r1.hp == r1.max_hp and r1.shield == config.SHIELD.hp - 20, "the shield absorbs the damage")
	check(q:knock_mul(r1) < 1, "with the shield you get pushed less")

	-- on the next turn the trap is armed: the opponent stepping on it gets its
	-- feet locked (no damage, no launch) until the end of its turn
	for _ = 1, 3000 do
		q:step()
		if q.current == 2 then break end
	end
	check(trap.armed and r1.shield, "on the next turn the trap is armed and the shield is still there")
	r1.x = trap.x + 150
	r2.x, r2.y, r2.vx, r2.vy, r2.grounded = trap.x, trap.y, 0, 0, true
	local hp2, pts1 = r2.hp, r1.points
	q:step()
	check(r2.trapped and r2.hp == hp2 and #q.placed == 0 and r1.points > pts1,
		"the trap locks the opponent's feet, without damage, and gives points to whoever placed it")
	local x2 = r2.x
	for _ = 1, 60 do q:step({ right = true, jump = true }) end
	check(r2.x == x2 and r2.grounded, "with locked feet it doesn't walk or jump")
	check(not q:can_use("hook") and q:can_use("missile"), "nor use the Rampino, but it can still shoot")
	for _ = 1, 3000 do
		q:step()
		if q.current == 1 then break end
	end
	check(not r2.trapped, "the trap lets go at the end of its turn")
	check(r1.shield == nil, "the shield ends at the start of the owner's turn")

	-- a teammate doesn't set off the trap
	local t2 = game.new(42, "pavimento", { players = config.MODES["2v2"], ammo = { trap = 1 } })
	run(t2, 60)
	t2:step({ fire = { angle = 0, power = 1, weapon = "trap" } })
	local tt = t2.placed[1]
	tt.armed = true
	local mate = t2.robots[3]
	mate.x, mate.y, mate.vy, mate.grounded = tt.x, tt.y, 0, true
	t2.robots[1].x = tt.x + 60
	t2:step()
	check(#t2.placed == 1 and mate.vy <= 0, "the teammate doesn't set off the trap")

	-- trampoline (Molla): it's thrown; thrown at a robot it lands at its feet,
	-- leaning the way it was thrown, and launches it far that way
	local tb = game.new(42, "pavimento", { ammo = { trampoline = 1 } })
	run(tb, 60)
	local a, b = tb.robots[1], tb.robots[2]
	b.x, b.y = a.x + 40, a.y
	run(tb, 5)
	tb:step({ fire = { angle = math.rad(10), power = 0.4, weapon = "trampoline" } })
	local tramp = tb.placed[1]
	check(tramp and tramp.flying and a.ammo.trampoline == 0 and tramp.dir == 1, "the trampoline is thrown, leaning right")
	local first_vy, first_vx, start_x, landed_at
	for _ = 1, 600 do
		tb:step()
		for _, e in ipairs(tb:pop_events()) do
			if e.type == "bounce" and e.robot == 2 and not first_vy then
				first_vy, first_vx, start_x = b.vy, b.vx, b.x
				check(math.abs(tramp.x - b.x) <= tramp.r + game.ROBOT_HALF_W, "thrown at a robot it lands at its feet")
			end
		end
		if first_vy and b.grounded and not landed_at then landed_at = b.x end
	end
	check(first_vy == config.TRAMPOLINE.launch_vy and first_vx == config.TRAMPOLINE.push_vx,
		"and launches it up and sideways")
	check(landed_at and landed_at - start_x >= 350, "far away: " .. tostring(landed_at and math.floor(landed_at - start_x)) .. " px")
	check(b.last_hit == 1, "an opponent's Molla gives the kill if you fall")
	-- stepping on it again you are launched again
	b.x, b.y, b.vy = tramp.x, tramp.y, 0
	local again
	for _ = 1, 5 do
		tb:step()
		for _, e in ipairs(tb:pop_events()) do if e.type == "bounce" then again = b.vy end end
	end
	check(again == config.TRAMPOLINE.launch_vy, "stepping back on it you bounce high again")
	run(tb, 400)

	-- everything bounces on the trampoline: missile, Uovo, shards, Cecchino, orb, crate.
	-- Each body falls straight onto the board and must go back up at the bounce
	-- speed; shots also leave sideways, crates fall straight
	local top = tramp.y + config.TRAMPOLINE.top
	local function falls_on(body, advance)
		body.x, body.y, body.vy = tramp.x + tramp.r - 1, top + 3, -200
		if body.vx then body.vx = 0 end
		for _ = 1, 3 do
			advance()
			if body.vy > 0 then return body.vy end
		end
	end
	local bodies = {
		missile = { kind = "missile", owner = 1, age = 100, vx = 0 },
		grenade = { kind = "grenade", owner = 1, age = 100, fuse = 600, vx = 0 },
		sniper = { kind = "sniper", owner = 1, age = 100, bounces = 0, vx = 0 },
	}
	for _, kind in ipairs({ "missile", "grenade", "sniper" }) do
		local body = bodies[kind]
		tb.projectile = body
		local vy = falls_on(body, function() tb:update_projectile() end)
		check(tb.projectile == body and vy == config.TRAMPOLINE.launch_vy and body.vx > 0,
			"bounces on the trampoline and leaves sideways: " .. kind)
	end
	tb.projectile = nil
	local shard = { owner = 1, age = 100, vx = 0 }
	tb.shards[1] = shard
	check(falls_on(shard, function() tb:update_shards() end) == config.TRAMPOLINE.launch_vy and tb.shards[1] == shard,
		"bounces on the trampoline: shard")
	tb.shards[1] = nil
	local orb = { id = 99, owner = 1, age = 100, timer = 600, vx = 0 }
	check(falls_on(orb, function() tb:update_orb(orb) end) == config.TRAMPOLINE.launch_vy,
		"bounces on the trampoline: orb")
	local crate = { id = 99, weapon = "grenade", landed = false }
	check(falls_on(crate, function() tb:fall(crate, game.CRATE_HALF_W, game.CRATE_FALL) end)
		== config.TRAMPOLINE.launch_vy, "bounces on the trampoline: crate")
	-- a crate left on it bounces less and less and then settles
	crate.x, crate.y, crate.vy = tramp.x, top + 20, 0
	tb:pop_events()
	local crate_bounces = 0
	for _ = 1, 900 do
		tb:fall(crate, game.CRATE_HALF_W, game.CRATE_FALL)
		for _, e in ipairs(tb:pop_events()) do
			if e.type == "bounce" and not e.robot then crate_bounces = crate_bounces + 1 end
		end
	end
	check(crate_bounces >= 2 and crate.vy == 0, "a crate bounces lower and lower and settles (" .. crate_bounces .. ")")

	-- your own Molla carries you past your run, and the parachute gives control back
	local own = game.new(42, "pavimento", { ammo = { trampoline = 1 } })
	run(own, 60)
	local me = own.robots[1]
	own.placed[1] = { id = 1, kind = "trampoline", x = me.x + 30, y = me.y, vy = 0, owner = 1, team = me.team,
		r = config.TRAMPOLINE.half_w, age = 0, dir = 1 }
	local sprung_vx
	for _ = 1, 60 do
		own:step({ right = true })
		if me.sprung and not sprung_vx then sprung_vx = me.vx end
	end
	check(sprung_vx == config.TRAMPOLINE.push_vx and me.sprung, "on your own Molla you fly sideways faster than your run")
	own:step({ left = true })
	check(me.vx > 0 and me.vx < config.TRAMPOLINE.push_vx, "while flying the controls only counter the push a little")
	own:step({ fire = { angle = 0, power = 1, weapon = "parachute" } })
	own:step({ left = true })
	check(not me.sprung and me.vx < 0, "the parachute gives control back")

	-- an explosion takes away what's placed
	tb:explode(tramp.x, tramp.y + 4)
	check(#tb.placed == 0, "an explosion destroys the trampoline")

	-- parachute: in the air a tap opens it (one per match), it slows the fall,
	-- gives more horizontal control and cancels fall damage
	local pc = game.new(42, "pavimento")
	run(pc, 60)
	local p = pc.robots[1]
	check(not pc:can_use("parachute"), "on the ground the parachute doesn't open")
	local safe, dmg, max = game.FALL_SAFE, game.FALL_DAMAGE, game.FALL_DAMAGE_MAX
	game.FALL_SAFE, game.FALL_DAMAGE, game.FALL_DAMAGE_MAX = 10, 1, 100
	local y = sky_spot(pc, 640, 200)
	place(p, 640, y)
	pc:step()
	pc:step({ fire = { angle = 0, power = 1, weapon = "parachute" } })
	check(p.parachute and p.parachutes_left == config.STATS.parachutes - 1, "the parachute opens in the air and uses one up")
	check(pc:can_use("parachute"), "once open it can be closed again")
	local slowest, fastest = 0, 0
	-- to the right only for a second: with the fast parachute you'd leave the map
	for i = 1, 1200 do
		pc:step({ right = i <= 60 })
		slowest = math.min(slowest, p.vy)
		fastest = math.max(fastest, p.vx)
		if p.grounded then break end
	end
	check(slowest >= -config.PARACHUTE.fall_speed - 1 and p.hp == p.max_hp and not p.parachute,
		"with the parachute you come down slowly and land without damage")
	check(fastest > p.stats.air_speed, "with the parachute you go a bit faster horizontally")
	-- closing it doesn't give it back
	p.parachutes_left = 3
	place(p, 640, y)
	pc:step()
	pc:step({ fire = { angle = 0, power = 1, weapon = "parachute" } })
	pc:step({ fire = { angle = 0, power = 1, weapon = "parachute" } })
	check(not p.parachute and p.parachutes_left == 2, "another tap closes it")
	p.parachutes_left = 0
	check(not pc:can_use("parachute"), "once the match's parachutes are used up it no longer opens")
	game.FALL_SAFE, game.FALL_DAMAGE, game.FALL_DAMAGE_MAX = safe, dmg, max

	-- healing circle: at the end of the turn whoever has their feet inside is
	-- healed and the circle disappears (at the start of a turn another can appear)
	local hg = game.new(42, "pavimento")
	run(hg, 60)
	local function has_heal(id)
		for _, x in ipairs(hg.heals) do if x.id == id then return true end end
		return false
	end
	local h = hg:spawn_heal()
	local ha, hb = hg.robots[1], hg.robots[2]
	ha.x, ha.y, ha.hp = h.x, h.y, 50
	hg:end_turn()
	check(ha.hp == 50 + config.HEAL.hp and not has_heal(h.id), "at the end of the turn in the circle you heal and the circle disappears")
	hg.heals = {}
	local h2 = hg:spawn_heal()
	hb.x, hb.y, hb.hp = h2.x, h2.y, hb.max_hp
	hg:end_turn()
	check(has_heal(h2.id), "with full life the circle stays")
	hb.hp = 10
	hb.x = h2.x + config.HEAL.r + 10
	hg:end_turn()
	check(hb.hp == 10 and has_heal(h2.id), "outside the circle no healing")
end

-- The Uovo bounces on robots, like the teleport orb
do
	local q = game.new(42, "pavimento", { ammo = { grenade = 1 } })
	run(q, 60)
	local a, b = q.robots[1], q.robots[2]
	b.x, b.y = a.x + 60, a.y
	run(q, 5)
	q:step({ fire = { angle = math.rad(5), power = 0.6, weapon = "grenade" } })
	local max_x = 0
	for _ = 1, 60 do
		q:step()
		if q.projectile then max_x = math.max(max_x, q.projectile.x) end
	end
	check(q.projectile and max_x < b.x and q.projectile.touched, "the Uovo bounces on the robot instead of passing through it")
end

-- Cecchino: slow, straight and then drops, bounces, knocks in the direction of the shot ---
do
	local q = game.new(42, "pavimento", { ammo = { sniper = 1 } })
	run(q, 60)
	local a, b = q.robots[1], q.robots[2]
	-- in the sky, so the terrain doesn't get in the way
	local sy = sky_spot(q, 640, 80)
	place(a, 600, sy)
	place(b, 650, sy)
	local hp = b.hp
	q:step({ fire = { angle = 0, power = 1, weapon = "sniper" } })
	check(q.projectile and q.projectile.kind == "sniper" and a.ammo.sniper == 0, "the sniper fires")
	local hit
	for _ = 1, 60 do
		q:step()
		for _, e in ipairs(q:pop_events()) do if e.type == "sniper_hit" then hit = e end end
		if hit then break end
	end
	check(hit and hit.target == 2 and hp - b.hp == config.SNIPER.damage, "it hits and does damage")
	check(b.vx > 0 and not b.grounded and b.knocked, "knocks in the direction of the shot")
	local sp = math.sqrt(b.vx * b.vx + b.vy * b.vy)
	check(sp <= config.SNIPER.push + config.SNIPER.lift + 1, "with a moderate push")

	-- it starts fast and almost straight, then slows down and drops more and more
	local d = game.new(42, "pavimento", { ammo = { sniper = 1 } })
	run(d, 60)
	local from_pt = d.robots[1]
	d.robots[2].x = -1000
	local dy = sky_spot(d, 500, 300)
	place(from_pt, 200, dy)
	d.terrain:rect(0, dy - 200, 1280, 260, 0)  -- open sky ahead
	d:step({ fire = { angle = 0, power = 1, weapon = "sniper" } })
	local p = d.projectile
	run(d, 10)
	check(d.projectile == p and p.vy > -40 and p.vx > game.SNIPER_SPEED * 0.9, "at first it goes almost straight and fast")
	local vy10 = p.vy
	run(d, 30)
	check(d.projectile == p and p.vy < vy10 - 40 and p.vx < game.SNIPER_SPEED * 0.85, "then it drops more and more and slows down")

	-- towards the terrain it bounces (doesn't dig), and after the last bounce it stops
	local r = game.new(42, "pavimento", { ammo = { sniper = 1 } })
	run(r, 60)
	local cells = solid_count(r.terrain)
	r:step({ fire = { angle = math.rad(-75), power = 1, weapon = "sniper" } })
	local bounces, speeds = 0, {}
	for _ = 1, game.SNIPER_LIFE + 5 do
		r:step()
		for _, e in ipairs(r:pop_events()) do
			if e.type == "sniper_bounce" then
				bounces = bounces + 1
				local pr = r.projectile
				speeds[bounces] = math.sqrt(pr.vx * pr.vx + pr.vy * pr.vy)
			end
		end
		if not r.projectile then break end
	end
	check(bounces >= 1 and bounces <= config.SNIPER.bounces, "bounces on the terrain, at most " .. config.SNIPER.bounces .. " times (" .. bounces .. ")")
	local slower = true
	for i = 2, bounces do if speeds[i] >= speeds[i - 1] then slower = false end end
	check(slower, "like a ball: each bounce it's slower")
	check(solid_count(r.terrain) == cells, "the sniper doesn't dig")

	-- the aim line bends at the first bounce
	local pts = r:preview(math.rad(-60), 1, 30, 4, nil, "sniper")
	check(#pts == 30 and pts[30].y > pts[1].y - 200, "the sniper aim follows the bounce")
end

-- Ranged secondaries and Affondo: Tonante, Rampino, Affondo --------------------
do
	-- Tonante: straight instant shot, flat damage without effects, recoil on the shooter
	local q = game.new(42, "pavimento", { secondary = "eagle" })
	run(q, 60)
	local a, b = q.robots[1], q.robots[2]
	local sy = sky_spot(q, 640, 80)
	place(a, 600, sy)
	place(b, 700, sy)
	local hp = b.hp
	q:step({ fire = { angle = 0, power = 1, weapon = "eagle" } })
	local ev
	for _, e in ipairs(q:pop_events()) do if e.type == "eagle" then ev = e end end
	check(ev and ev.target == 2 and hp - b.hp == config.EAGLE.damage, "the Tonante hits at once and does flat damage")
	check(next(b.status) == nil and b.vx == 0, "without status effects and without pushing the target")
	check(a.recoil and a.recoil_vx < 0 and a.recoil_vy == 0 and not a.grounded, "the recoil pushes the shooter the opposite way")
	check(not q.projectile, "no projectile in flight")

	-- the recoil is the same in every direction: in the sky it moves you the same
	-- distance right, left, up and diagonally
	local push = config.EAGLE.recoil * config.EAGLE.recoil_ticks / 60
	for _, deg in ipairs({ 0, 180, 90, -90, 45, -45, -135 }) do
		local d = game.new(42, "pavimento", { secondary = "eagle" })
		run(d, 60)
		local from_pt = d.robots[1]
		d.robots[2].x = -1000
		-- a hole of radius 150 px in the terrain, to have room on all sides
		d.terrain:carve(640, 400, 150)
		place(from_pt, 640, 400 - game.ROBOT_H / 2)
		local x0, y0 = from_pt.x, from_pt.y
		d:step({ fire = { angle = math.rad(deg), power = 1, weapon = "eagle" } })
		run(d, config.EAGLE.recoil_ticks)
		local dist = math.sqrt((from_pt.x - x0) ^ 2 + (from_pt.y - y0) ^ 2)
		check(math.abs(dist - push) <= 2 and not from_pt.recoil and from_pt.vx == 0 and from_pt.vy == 0,
			"recoil of " .. math.floor(push) .. " px shooting at " .. deg .. " degrees (" .. math.floor(dist) .. ")")
	end

	-- from the ground, shooting horizontally, you slide on the terrain the same distance
	local g2 = game.new(42, "pavimento", { secondary = "eagle" })
	run(g2, 60)
	local ga = g2.robots[1]
	g2.robots[2].x = -1000
	local gx = ga.x
	g2:step({ fire = { angle = math.pi, power = 1, weapon = "eagle" } })
	run(g2, config.EAGLE.recoil_ticks)
	check(ga.x - gx > push * 0.8, "from the ground the horizontal recoil moves as much as in the air (" .. math.floor(ga.x - gx) .. ")")

	-- terrain stops the shot, within range
	local t = game.new(42, "pavimento", { secondary = "eagle" })
	run(t, 60)
	t.robots[2].x = -1000
	t:step({ fire = { angle = math.rad(-90), power = 1, weapon = "eagle" } })
	for _, e in ipairs(t:pop_events()) do if e.type == "eagle" then ev = e end end
	check(ev and ev.target == nil and ev.y0 - ev.y1 < 40, "terrain stops the shot")
	local pts = t:preview(0, 1, 12, 4, nil, "eagle")
	check(#pts == 12 and math.abs(pts[12].x - pts[1].x) <= config.EAGLE.range, "the aim line is straight and doesn't go past the range")

	-- Rampino: an item, one per turn, not an attack; reels the target straight
	-- towards the hand, right up to the puller, then releases it
	local h = game.new(42, "pavimento")
	run(h, 60)
	local ha, hb = h.robots[1], h.robots[2]
	sy = sky_spot(h, 640, 120)
	-- open sky all around: the rope goes all the way to the puller
	h.terrain:rect(500, sy - 60, 300, 140, 0)
	place(ha, 560, sy)
	place(hb, 740, sy)
	hp = hb.hp
	check(h:can_use("hook"), "the Rampino is used without shots")
	ev = hook(h, 0, function() ha.y, ha.vy, hb.y, hb.vy = sy, 0, sy, 0 end)
	check(ev and ev.target == 2 and hb.hp == hp, "the Rampino hooks without doing damage")
	check(h.used.tool and not h:can_use("hook") and not h.used.primary and not h.used.secondary and h.window == 0,
		"one per turn and doesn't count as an attack")
	check(hb.hooked and hb.hooked.by == 1 and ha.vx == 0, "the target hangs from the rope, the puller doesn't")
	local y_start = hb.y
	-- the puller stays still there (in the sky they would fall and the rope would follow)
	for _ = 1, 10 do
		ha.y, ha.vy = sy, 0
		h:step()
	end
	check(hb.x < 740 - 40 and math.abs(hb.y - y_start) < 2 and hb.hooked, "it's pulled straight, without falling")
	local ended
	for _ = 1, 60 do
		ha.y, ha.vy = sy, 0
		h:step()
		for _, e in ipairs(h:pop_events()) do if e.type == "hook_end" then ended = e end end
		if not hb.hooked then break end
	end
	check(ended and not ended.snap and not hb.hooked and math.abs(hb.x - ha.x) < 2 * game.ROBOT_HALF_W + 2, "it comes right up to the puller and is released")
	run(h, 5)
	check(hb.y < y_start and hb.vx == 0, "and falls straight where it is")
	-- pulled from below it rises up to the puller; a nearby robot stops the rope
	local u = game.new(42, "pavimento")
	run(u, 60)
	local ua, ub = u.robots[1], u.robots[2]
	sy = sky_spot(u, 640, 120)
	place(ua, 640, sy)
	place(ub, 640 + 30, sy - 60)
	hook(u, math.atan2(-60 + game.ROBOT_H / 2, 30))
	check(ub.hooked, "it hooks diagonally too")
	for _ = 1, 40 do
		u:step()
		if not ub.hooked then break end
	end
	check(not ub.hooked and ub.y > sy - 60 + 15 and math.abs(ub.x - ua.x) < 2 * game.ROBOT_HALF_W + 2,
		string.format("from below it pulls it up to the shooter and stops it right there (%s, rose %.0f, at %.0f px)",
			tostring(ub.hooked), ub.y - (sy - 60), math.abs(ub.x - ua.x)))
	-- on terrain it's the puller who climbs along the rope and gets on top of the
	-- platform hit: from below a platform you end up standing on top
	local m = game.new(42, "pavimento")
	run(m, 60)
	local ma, mb = m.robots[1], m.robots[2]
	mb.x = -1000
	-- a column of open sky with a separate platform inside, empty below and above
	m.terrain:rect(560, 100, 160, 900, 0)
	m.terrain:rect(600, 300, 80, 16, 1)
	place(ma, 640, 240)
	local y0 = ma.y
	ev = hook(m, math.rad(90))
	check(ev and ev.anchor and not ev.target and ma.hooked and ma.hooked.x == 640, "on terrain the rope hooks and the puller hangs")
	for _ = 1, 40 do
		m:step()
		if not ma.hooked then break end
	end
	run(m, 5)
	check(not ma.hooked and math.abs(ma.y - 316) < 4 and math.abs(ma.x - 640) < 10 and ma.grounded,
		"climbs along the rope and stands on top of the platform")
	-- from below diagonally the climb hits the bottom of the platform before
	-- reaching the point: within config.HOOK.grab it gets on top anyway
	local dg = game.new(42, "pavimento")
	run(dg, 60)
	local from_pt = dg.robots[1]
	dg.robots[2].x = -1000
	dg.terrain:rect(500, 200, 900, 900, 0)
	dg.terrain:rect(900, 500, 200, 30, 1)
	place(from_pt, 850, 420)
	ev = hook(dg, math.atan2(499 - 420 - game.DISEGNO_H / 2, 1000 - 850), function() from_pt.vy = 0 end)
	for _ = 1, 60 do
		dg:step()
		if not from_pt.hooked then break end
	end
	run(dg, 20)
	check(ev and ev.anchor and from_pt.grounded and math.abs(from_pt.y - 530) < 4,
		"from below diagonally it gets on top of the platform")
	-- the side of a high wall (top past config.HOOK.climb) no: it stays there and falls
	dg.terrain:rect(1200, 200, 60, 400, 1)
	place(from_pt, 1100, 300)
	dg.used.tool = false
	ev = hook(dg, 0, function() from_pt.vy = 0 end)
	for _ = 1, 60 do
		dg:step()
		if not from_pt.hooked then break end
	end
	run(dg, 10)
	check(ev and ev.anchor and from_pt.y < 590, "on the side of a high wall it doesn't climb to the top")
	-- shooting into the void nothing happens
	place(ma, 640, 340)
	m.used.tool = false
	ev = hook(m, math.rad(90))
	check(ev and not ev.anchor and not ev.target and not ma.hooked and ma.vx == 0, "in the void the Rampino hooks nothing")
	-- the hook flies: at the end of its reach it takes more than one tick, and gets all the way there
	local far = game.new(42, "pavimento")
	run(far, 60)
	local fa, fb = far.robots[1], far.robots[2]
	fb.x = -1000
	far.terrain:rect(400, 100, 900, 900, 0)
	place(fa, 500, 400)
	local ticks = 0
	ev = hook(far, 0, function() ticks = ticks + 1; fa.y, fa.vy = 400, 0 end)
	check(ev and not ev.anchor and not ev.target and ticks >= math.floor(config.HOOK.range / config.HOOK.shot_speed * 60) - 3,
		"the hook flies over its whole reach and if it catches nothing it's lost")
	far.terrain:rect(500 + config.HOOK.range - 20, 380, 40, 60, 1)
	place(fa, 500, 400)
	far.used.tool = false
	ev = hook(far, 0, function() fa.y, fa.vy = 400, 0 end)
	check(ev and ev.anchor, "at the end of its reach it still hooks the terrain")
	-- a far enemy: the rope runs out before arriving and releases it in mid-air (snap)
	far = game.new(42, "pavimento")
	run(far, 60)
	fa, fb = far.robots[1], far.robots[2]
	far.terrain:rect(400, 100, 900, 900, 0)
	place(fa, 500, 400)
	place(fb, 500 + config.HOOK.range - 30, 400)
	ev = hook(far, 0, function() fa.y, fa.vy, fb.y, fb.vy = 400, 0, 400, 0 end)
	local end_of
	for _ = 1, 120 do
		fa.y, fa.vy = 400, 0
		far:step()
		for _, e in ipairs(far:pop_events()) do if e.type == "hook_end" then end_of = e end end
		if end_of then break end
	end
	check(ev and ev.target == 2 and end_of and end_of.snap and fb.x - fa.x > 100,
		"from far away the rope runs out halfway and breaks (snap)")

	-- Mantice (secondary): blows away whoever is in front, little damage, never effects
	local function bellows(dist, angle, setup)
		local q = game.new(42, "pavimento", { secondary = "bellows" })
		run(q, 60)
		local a, b = q.robots[1], q.robots[2]
		local gy = 100
		q.terrain:rect(300, gy, 800, 400, 0)
		q.terrain:rect(300, gy - 20, 800, 20, 1)
		place(a, 600, gy)
		place(b, 600 + dist, gy)
		if setup then setup(q, a, b) end
		run(q, 20)
		local hp, x0 = b.hp, b.x
		q:step({ fire = { angle = angle or 0, power = 1, weapon = "bellows" } })
		local vx, vy = b.vx, b.vy
		return q, a, b, hp, x0, vx, vy
	end
	local q, a, b, hp, x0, vx, vy = bellows(60)
	check(hp - b.hp == config.BELLOWS.damage and vx > 300 and vy > 0 and b.knocked, "the Mantice pushes whoever is in front far away")
	check(next(b.status) == nil and q.used.secondary and not q.used.primary, "it's a secondary and leaves no effects")
	check(a.vx == 0 and a.x == 600, "the user stays where they are")
	run(q, 30)
	check(b.x > x0 + 60, "the target flies away")
	local _, _, _, _, _, vfar = bellows(config.BELLOWS.range - 25)
	check(vfar > 0 and vfar < vx, "the further it is, the less it pushes")
	local _, _, b2, hp2 = bellows(config.BELLOWS.range + 30)
	check(b2.hp == hp2 and not b2.knocked, "it doesn't reach past its range")
	local _, _, b3, hp3 = bellows(60, math.pi)
	check(b3.hp == hp3, "it doesn't reach behind the back")
	local _, _, b4, hp4 = bellows(90, 0, function(q2) q2.terrain:rect(640, 100, 9, 60, 1) end)
	check(b4.hp == hp4, "terrain in between shelters")
	-- category rule: no secondary leaves status effects
	local rq = game.new(42, "pavimento")
	for w in pairs(game.SECONDARY) do
		rq:hit_status(rq.robots[2], w, rq.robots[1])
		check(next(rq.robots[2].status) == nil, "the secondary " .. w .. " leaves no effects")
	end

	-- Maglio: arc around the shoulder like the Lama, from above the head (behind)
	-- to below the feet; it hits everything along the arc, the head stops on
	-- terrain; in the air, if it slams while coming down, the attacker bounces up.
	-- sky(g): clears a column of sky and returns a point in the middle
	local function sky(g)
		g.terrain:rect(540, 200, 200, 300, 0)
		return 640, 350
	end
	-- mallet(g, angle): the whole swing; returns the impacts and the attacker's vy
	-- right after each impact
	local function mallet(g, angle)
		local rb = g.robots[g.current]
		g:step({ fire = { angle = angle, power = 1, weapon = "mallet" } })
		local hits = {}
		for _ = 1, config.MALLET.ticks + config.MALLET.hold + 2 do
			for _, e in ipairs(g:pop_events()) do
				if e.type == "mallet_hit" then e.vy = rb.vy; hits[#hits + 1] = e end
			end
			if not rb.mallet then break end
			g:step()
		end
		return hits, rb
	end
	-- in the air: the robot under the feet is hit while the hammer comes down, and you bounce
	local g1 = game.new(42, "pavimento", { secondary = "mallet" })
	run(g1, 60)
	local ga, gb = g1.robots[1], g1.robots[2]
	local sx
	sx, sy = sky(g1)
	place(ga, sx, sy)
	place(gb, sx, sy - game.ROBOT_H - 6)
	hp = gb.hp
	local hits = mallet(g1, 0)
	check(#hits == 1 and hits[1].target == 2 and hits[1].bounce and hp - gb.hp == config.MALLET.damage
		and next(gb.status) == nil, "in the air it hits the robot below, flat damage, and bounces")
	check(hits[1].vy >= config.MALLET.bounce - 20 and gb.vx == 0, "the attacker goes up, the target isn't pushed")
	check(ga.mallet == nil, "the swing ends")
	-- like the Lama it catches everything on the arc: also whoever is behind and
	-- high, where the hammer starts; and there too you bounce (Sergio, 30 Oct: every time it hits)
	local g5 = game.new(42, "pavimento", { secondary = "mallet" })
	run(g5, 60)
	local g5a, g5b = g5.robots[1], g5.robots[2]
	sx, sy = sky(g5)
	place(g5a, sx, sy)
	place(g5b, sx - 20, sy + 35)
	hp = g5b.hp
	hits = mallet(g5, 0)
	check(#hits == 1 and hits[1].target == 2 and hits[1].bounce and hp - g5b.hp == config.MALLET.damage,
		"it also hits behind and high, at the start of the arc, and bounces")
	-- on the terrain under the feet the head stops and you bounce (pogo)
	local g2 = game.new(42, "pavimento", { secondary = "mallet" })
	run(g2, 60)
	local g2a = g2.robots[1]
	g2.robots[2].x = -1000
	place(g2a, g2a.x, g2a.y + 20)
	g2:step({ fire = { angle = 0, power = 1, weapon = "mallet" } })
	local stop
	for _ = 1, config.MALLET.ticks do
		g2:step()
		if g2a.mallet_stop and not stop then stop = g2a.mallet_stop; check(g2a.vy >= config.MALLET.bounce - 20, "on the terrain under the feet it bounces up (pogo)") end
	end
	check(stop and stop < config.MALLET.ticks and game.mallet_angle(config.MALLET.ticks, 0, stop) == game.mallet_angle(stop),
		"the head stops where it slams and stays there")
	-- a miss in the air doesn't bounce
	local g3 = game.new(42, "pavimento", { secondary = "mallet" })
	run(g3, 60)
	local g3a = g3.robots[1]
	g3.robots[2].x = -1000
	place(g3a, sky(g3))
	hits = mallet(g3, 0)
	check(#hits == 0 and g3a.vy < 0, "a miss in the air doesn't bounce")
	-- on the ground it hits in front and you bounce (Sergio, 30 Oct: even without jumping)
	local g4 = game.new(42, "pavimento", { secondary = "mallet" })
	run(g4, 60)
	local g4a, g4b = g4.robots[1], g4.robots[2]
	place(g4b, g4a.x + 2 * game.ROBOT_HALF_W + 16, g4a.y)
	g4b.grounded = true
	hp = g4b.hp
	hits = mallet(g4, 0)
	check(hp - g4b.hp == config.MALLET.damage and hits[1].target == 2 and hits[1].bounce and hits[1].vy >= config.MALLET.bounce - 20,
		"on the ground it hits in front and bounces up")
	check(#hits == 1 or not hits[2].bounce, "only once per swing")
	-- the arc rotates with the aim: whoever is behind, under the feet, only gets hit aiming down
	for _, try_it in ipairs({ { 0, false }, { math.rad(-70), true } }) do
		local gd = game.new(42, "pavimento", { secondary = "mallet" })
		run(gd, 60)
		local from_pt, db = gd.robots[1], gd.robots[2]
		local px, py = sky(gd)
		place(from_pt, px, py)
		local q, d = math.rad(-150), config.MALLET.reach * 0.8
		place(db, px + math.cos(q) * d, py + game.SWORD_PIVOT_Y + math.sin(q) * d - game.HURT_Y)
		hits = mallet(gd, try_it[1])
		check((#hits > 0 and hits[1].target == 2) == try_it[2],
			try_it[2] and "aiming down the Maglio catches whoever is behind under the feet" or "aiming straight it doesn't")
	end
	check(not g4:can_use("sword") and g4:can_use("missile"), "Maglio and Lama are both secondaries")

	-- Affondo: dash that goes through the robot in front and hits it once
	local l = game.new(42, "pavimento", { secondary = "lunge" })
	run(l, 60)
	local la, lb = l.robots[1], l.robots[2]
	sy = sky_spot(l, 640, 120)
	place(la, 600, sy)
	place(lb, 640, sy)
	hp = lb.hp
	local x1 = la.x
	l:step({ fire = { angle = 0, power = 1, weapon = "lunge" } })
	check(la.lunge == config.LUNGE.ticks and la.lunge_vx > 0, "the Affondo starts")
	run(l, config.LUNGE.ticks)
	check(la.lunge == nil and la.x > lb.x + 10, "and goes past the robot in front")
	check(hp - lb.hp == config.LUNGE.damage and next(lb.status) == nil, "hitting it once, without effects")
	check(la.vx > 0 and la.vx < config.LUNGE.speed, "at the end some momentum remains")
	-- terrain stops it
	local w = game.new(42, "pavimento", { secondary = "lunge" })
	run(w, 60)
	local wa = w.robots[1]
	local y1 = wa.y
	w:step({ fire = { angle = math.rad(-90), power = 1, weapon = "lunge" } })
	run(w, 2)
	check(wa.lunge == nil and wa.y >= y1 - 2, "terrain stops the Affondo")
	-- small steps and bumps don't stop it: it climbs them and goes on
	local v = game.new(42, "pavimento", { secondary = "lunge" })
	run(v, 60)
	local va, vb = v.robots[1], v.robots[2]
	v.terrain:rect(300, 200, 680, 300, 0)
	v.terrain:rect(300, 200, 680, 20, 1)
	v.terrain:rect(500, 220, 10, 12, 1)
	place(va, 440, 220)
	vb.x = -1000
	v:step({ fire = { angle = 0, power = 1, weapon = "lunge" } })
	run(v, config.LUNGE.ticks)
	check(va.x > 440 + 0.9 * config.LUNGE.speed * config.LUNGE.ticks / 60, "it climbs the bump and does the whole dash")
	-- a high wall stops it
	local wl = game.new(42, "pavimento", { secondary = "lunge" })
	run(wl, 60)
	local wla = wl.robots[1]
	wl.robots[2].x = -1000
	wl.terrain:rect(300, 200, 680, 300, 0)
	wl.terrain:rect(300, 200, 680, 20, 1)
	wl.terrain:rect(500, 220, 10, 100, 1)
	place(wla, 440, 220)
	wl:step({ fire = { angle = 0, power = 1, weapon = "lunge" } })
	run(wl, config.LUNGE.ticks)
	check(wla.x < 500 and wla.x > 480, "against a high wall it stops")
	-- the spear also hits whoever is just past the end of the dash
	local q = game.new(42, "pavimento", { secondary = "lunge" })
	run(q, 60)
	local qa, qb = q.robots[1], q.robots[2]
	q.terrain:rect(300, 200, 680, 300, 0)
	q.terrain:rect(300, 200, 680, 20, 1)
	place(qa, 400, 220)
	local fin = 400 + config.LUNGE.speed * config.LUNGE.ticks / 60
	place(qb, fin + 2 * game.ROBOT_HALF_W + 12, 220)
	hp = qb.hp
	q:step({ fire = { angle = 0, power = 1, weapon = "lunge" } })
	run(q, config.LUNGE.ticks)
	check(hp - qb.hp == config.LUNGE.damage, "the spear catches whoever is just past the end of the dash")
	-- Affondo and Lama are both secondaries: one per turn
	check(not w:can_use("sword") and w:can_use("missile"), "after the Affondo no Lama in the same turn")
end

-- Status effects: burn, slow, cracked armour ------------------
do
	local function to_turn(q, who)
		for _ = 1, 4000 do
			q:step()
			if q.current == who and q.phase == "aim" then return end
		end
	end

	-- shards slow: run and jump reduced until the end of the owner's next turn
	local q = game.new(42, "pavimento")
	run(q, 30)
	local r1, r2 = q.robots[1], q.robots[2]
	q:explode(r2.x, r2.y + 4, 1, game.SHARD_BLAST, "shards")
	check(r2.status.slow and r2.status.slow.turns == 1, "shards slow")
	local x0 = r2.x
	q.current = 2
	run(q, 20, { right = true })
	local slow_dx = math.abs(r2.x - x0)
	r2.status.slow = nil
	x0 = r2.x
	run(q, 20, { right = true })
	check(slow_dx < math.abs(r2.x - x0) * 0.8, "slowed you run slower")
	q.current = 1

	-- armour cracked by the punch: you take more damage
	local c = game.new(42, "pavimento")
	local a, b = c.robots[1], c.robots[2]
	c:punch_hit(a, b, 1)
	check(b.status.cracked, "the punch cracks the armour")
	local hp = b.hp
	c:hurt(b, 20, a)
	check(hp - b.hp == math.floor(20 * config.STATUS.cracked.damage + 0.5), "with cracked armour the damage goes up")

	-- a shield that holds stops the effect (the Pugno, 47, would break it: shards don't)
	local s = game.new(42, "pavimento")
	run(s, 30)
	local sb = s.robots[2]
	sb.shield = config.SHIELD.hp
	s:explode(sb.x, sb.y + 4, 1, game.SHARD_BLAST, "shards")
	check(sb.shield < config.SHIELD.hp and not sb.status.slow, "the shield stops the status effect")

	-- normal Uovo: no burn; with the Fornace set (burning_blasts) the Uovo burns,
	-- the missile doesn't
	local f = game.new(42, "pavimento", { players = { { team = 1, stats = { burning_blasts = 1 } }, { team = 2 } } })
	run(f, 30)
	local fa, fb = f.robots[1], f.robots[2]
	f:explode(fb.x, fb.y + 4, 2, nil, "grenade")
	check(not fa.status.burn, "the Uovo without Fornace doesn't burn")
	f:explode(fb.x + 20, fb.y + 4, 1, nil, "missile")
	check(not fb.status.burn, "with the Fornace set the missile doesn't burn")
	f:explode(fb.x + 20, fb.y + 4, 1, nil, "grenade")
	check(fb.status.burn and fb.status.burn.by == 1, "with the Fornace set the Uovo burns")
	-- at the start of the turn whoever is burning takes damage, and at the end of the turn the effect ends
	run(f, 200)
	fb.hp = 50 -- the three blasts above nearly finished it: the burn would kill it
	local before, points = fb.hp, fa.points
	to_turn(f, 2)
	check(fb.hp == before - config.STATUS.burn.damage and fa.points > points, "the burn does damage at the start of the turn and gives points")
	to_turn(f, 1)
	check(next(fb.status) == nil, "effects end at the end of the owner's turn")

	-- the attacker's status_turns makes the effect last longer
	local l = game.new(42, "pavimento", { players = { { team = 1, stats = { status_turns = 2 } }, { team = 2 } } })
	run(l, 30)
	local lb = l.robots[2]
	l:explode(lb.x, lb.y + 4, 1, game.SHARD_BLAST, "shards")
	to_turn(l, 2)
	to_turn(l, 1)
	check(lb.status.slow and lb.status.slow.turns == 1, "with status_turns 2 it lasts one more turn")

	-- death clears the effects
	l:kill(lb, "damage")
	l:respawn(lb)
	check(next(lb.status) == nil, "after respawn no effects")
end

-- Start-of-match draft (sim/draft.lua) ----------------------------------------
do
	local draft = require "sim.draft"
	local d = draft.new(7, config.MODES["2v2"])
	check(#d.offer == config.DRAFT_OFFER, "the fan has " .. config.DRAFT_OFFER .. " weapons")
	local again = draft.new(7, config.MODES["2v2"])
	check(table.concat(d.offer, ",") == table.concat(again.offer, ","), "same seed, same fan")
	local w1, w2 = d.offer[1], d.offer[2]
	check(draft.pick(d, 1, w1), "the first one picks")
	check(draft.pick(d, 3, w1), "the teammate can take the same weapon too")
	check(not draft.pick(d, 1, "teleport") and not draft.pick(d, 1, "hook"), "only weapons from the fan, no tools")
	check(draft.pick(d, 1, w2) and d.picks[1] == w2, "the pick can be changed")
	local players = draft.finish(d)
	check(players[2].pick == d.offer[1] and players[4].pick == d.offer[1],
		"when time's up whoever didn't pick takes the first weapon of the fan")
	local g = game.new(7, "pavimento", { players = players })
	check(g.robots[1].ammo[w2] == config.DRAFT_SHOTS and g.robots[1].ammo[w1] == 0, "in the match the picked weapon has its shots")
	for _ = 1, 600 do if g.phase == "aim" then break end g:step() end
	check(g:can_use("hook"), "everyone has the Rampino, without picking it")

	-- the second fan: the secondaries, unlimited
	check(#d.offer2 == math.min(config.DRAFT_OFFER, #game.DRAFT_SECONDARIES) and game.SECONDARY[d.offer2[1]],
		"the secondaries fan")
	local e = draft.new(9, config.MODES["2v2"])
	local s1, s2 = e.offer2[1], e.offer2[2]
	check(not draft.done(e, 1) and draft.pick(e, 1, s1) and not draft.done(e, 1), "the secondary alone isn't enough")
	check(draft.pick(e, 1, e.offer[1]) and draft.done(e, 1), "primary and secondary: done")
	draft.pick(e, 1, s2)
	local ep = draft.finish(e)
	check(ep[2].secondary == e.offer2[1], "when time's up the first secondary")
	local eg = game.new(9, "pavimento", { players = ep })
	local r1 = eg.robots[1]
	check(r1.secondary == s2 and game.has_weapon(r1, s2) and game.has_weapon(r1, "sword") and not game.has_weapon(r1, s1),
		"in the match you have the Lama and the picked secondary, not the others")
	check(r1.ammo[s2] == config.SECONDARY_SHOTS.draft and eg:can_use(s2) and eg:can_use("sword"),
		"the picked secondary has its shots, the Lama is unlimited")
	eg:step({ fire = { angle = 0, power = 1, weapon = s2 } })
	check(eg.used.secondary and not eg.used.primary and not eg:can_use("sword") and eg:can_use("missile"),
		"once the picked secondary is used, the Lama can't be used in the turn")
	check(r1.ammo[s2] == config.SECONDARY_SHOTS.draft - 1, "the secondary uses up a shot")
	-- the Lama on an enemy gives back a secondary shot, up to the maximum; on a teammate no
	r1.ammo[s2] = 0
	check(not game.has_weapon(r1, s2) and game.has_weapon(r1, "sword"), "when the shots are over the Lama remains")
	local enemy, teammate
	for _, rb in ipairs(eg.robots) do
		if rb.team ~= r1.team then enemy = enemy or rb elseif rb ~= r1 then teammate = rb end
	end
	eg:pop_events()
	eg:sword_hit(r1, teammate)
	check(r1.ammo[s2] == 0, "the Lama on a teammate doesn't reload")
	eg:sword_hit(r1, enemy)
	local ev = eg:pop_events()
	local recharge = false
	for _, e in ipairs(ev) do if e.type == "recharge" and e.robot == r1.id and e.weapon == s2 then recharge = true end end
	check(r1.ammo[s2] == 1 and recharge and game.has_weapon(r1, s2), "the Lama on an enemy gives back a shot")
	for _ = 1, 5 do eg:sword_hit(r1, enemy) end
	check(r1.ammo[s2] == config.SECONDARY_SHOTS.max, "never past the maximum")

	-- the campaign offers only the weapons already seen; an empty fan isn't picked from
	local v = draft.new(3, config.MODES["1v1"], { grenade = true, sniper = true, missile = true })
	check(#v.offer == 2 and #v.offer2 == 0, "only the seen weapons")
	check(draft.pick(v, 1, "sniper") and draft.done(v, 1), "with no secondaries seen the primary is enough")
	local vp = draft.finish(v)
	check(vp[1].pick == "sniper" and vp[1].secondary == nil and vp[2].pick == v.offer[1], "no extra secondary")
end

-- Air jump, shield, fixed level ----------------------------------------------------
do
	-- air jump: with air_jumps, pressing again in flight, free
	local q = game.new(42, "pavimento", { players = { { team = 1, stats = { air_jumps = 1 } }, { team = 2 } } })
	run(q, 60)
	local r = q.robots[1]
	q:step({ jump = true })
	run(q, 10, { jump = true })
	check(r.air_left == 1, "holding jump doesn't jump in the air")
	run(q, 2)
	local vy0 = r.vy
	q:step({ jump = true })
	check(r.vy > vy0 and r.air_left == 0, "pressing again in the air jumps again")
	run(q, 2)
	vy0 = r.vy
	q:step({ jump = true })
	check(r.vy < vy0, "only one air jump with air_jumps 1")
	local n = game.new(42, "pavimento")
	run(n, 60)
	local nr = n.robots[1]
	n:step({ jump = true })
	run(n, 12)
	vy0 = nr.vy
	n:step({ jump = true })
	check(nr.vy < vy0, "without air_jumps no air jump")

	-- shield: found only in crates and used whenever you like
	local s = game.new(42, "pavimento")
	run(s, 30)
	local sr = s.robots[1]
	check(not s:can_use("shield"), "without crate shields no shield")
	sr.ammo.shield = 1
	check(s:can_use("shield"), "with a shield in the pocket it's used at once")
	s:step({ fire = { angle = 0, power = 1, weapon = "shield" } })
	check(sr.shield == config.SHIELD.hp and sr.ammo.shield == 0, "the crate shield is used up")

	-- fixed level (event rule): tree and gear stats don't count, the picked weapon does
	local custom = { { team = 1, stats = { max_hp = 300, walk_speed = 999 }, pick = "shards" }, { team = 2 } }
	local t = game.new(42, "pavimento", { players = custom, normalize = true })
	check(t.robots[1].max_hp == config.STATS.max_hp and t.robots[1].stats.walk_speed == t.robots[2].stats.walk_speed,
		"at fixed level everyone has the base stats")
	check(t.robots[1].ammo.shards == config.DRAFT_SHOTS and t:results().normalized, "at fixed level the picked weapon stays")
end

-- Determinism: same seed, same inputs, same result
local function play(seed, map)
	local p = game.new(seed, map)
	for i = 1, 3000 do
		local input = { left = math.floor(i / 40) % 3 == 0, jump = i % 97 == 0 }
		if p.phase == "aim" and p.timer == game.TURN_TICKS - 30 then
			input.fire = { angle = math.rad(p.current == 1 and 45 or 135), power = 0.7,
				weapon = p.current == 2 and "sword" or nil }
		elseif p.phase == "aim" and p.timer == game.TURN_TICKS - 10 then
			input.fire = { angle = math.rad(60), power = 0.5, weapon = "teleport" }
		end
		p:step(input)
	end
	return p.robots[1].x, p.robots[1].hp, p.robots[2].x, p.robots[2].hp, solid_count(p.terrain)
end
for _, map in ipairs(maps.order) do
	local a = { play(99, map) }
	local b = { play(99, map) }
	local same = true
	for i = 1, #a do if a[i] ~= b[i] then same = false end end
	check(same, map .. ": same seed and same inputs give the same result")
end

-- Points, kills and respawn -------------------------------------------------------
do
	-- kill by hits: damage and kill points to the attacker, minus for whoever dies
	local g3 = game.new(3, "pavimento")
	run(g3, 60)
	local a, b = g3.robots[1], g3.robots[2]
	b.hp = 10
	g3:pop_events()
	g3:explode(b.x, b.y + 8, 1)
	local death
	for _, e in ipairs(g3:pop_events()) do if e.type == "death" then death = e end end
	check(b.dead and death and death.by == 1 and not death.env, "the kill goes to whoever hit")
	check(a.kills == 1 and a.points == 10 * config.SCORE.damage + config.SCORE.kill and b.points == config.SCORE.death,
		"points: damage and kill to the attacker (" .. a.points .. "), " .. config.SCORE.death .. " to whoever dies")
	-- after RESPAWN_TICKS it starts again at a random free point, in the killer's turn
	local resp
	for _ = 1, game.RESPAWN_TICKS do
		g3:step()
		for _, e in ipairs(g3:pop_events()) do if e.type == "respawn" then resp = e end end
	end
	check(resp and not b.dead and b.hp == b.max_hp and g3.current == 1,
		"on death you start again with full life, in the same turn")
	check(not g3:robot_collides(b.x, b.y, b), "at a free point")

	-- environmental kill: whoever hits a robot that then falls off the map also
	-- gets the bonus; without recent hits nobody gets anything
	local ge = game.new(3, "pavimento")
	run(ge, 60)
	local ea, eb = ge.robots[1], ge.robots[2]
	ge:hurt(eb, 5, ea)
	eb.x, eb.y = -game.KILL_SIDE - 40, 300
	ge:step()
	check(eb.dead and ea.env_kills == 1 and eb.falls == 1, "whoever knocks someone off the map makes an environmental kill")
	check(ea.points == 5 + config.SCORE.kill + config.SCORE.env_kill, "which is worth more than a kill by hits (" .. ea.points .. ")")
	local gf = game.new(3, "pavimento")
	run(gf, 60)
	gf:hurt(gf.robots[2], 5, gf.robots[1])
	gf.tick = gf.tick + config.KILL_CREDIT_SECONDS * 60 + 1
	gf:kill(gf.robots[2], "fell")
	check(gf.robots[1].kills == 0, "a fall long after the hit doesn't count as a kill")

	-- whoever jumps off in their own turn: the kill goes to whoever did them the
	-- most damage in this life (without environmental bonus) and they lose more
	local gs = game.new(3, "pavimento", { players = config.MODES.ffa })
	run(gs, 60)
	local s1, s2, s3 = gs.robots[1], gs.robots[2], gs.robots[3]
	gs:hurt(s1, 30, s2)
	gs:hurt(s1, 10, s3)
	gs.tick = gs.tick + config.KILL_CREDIT_SECONDS * 60 + 1
	gs:pop_events()
	s1.x, s1.y = -game.KILL_SIDE - 40, 300
	gs:step()
	local sd
	for _, e in ipairs(gs:pop_events()) do if e.type == "death" then sd = e end end
	check(s1.dead and sd and sd.own and sd.by == 2 and not sd.env, "whoever jumps off gives the kill to whoever did them the most damage")
	check(s2.kills == 1 and s2.env_kills == 0 and s2.points == 30 + config.SCORE.kill and s3.points == 10,
		"who gets the points of a kill (" .. s2.points .. ")")
	check(s1.points == config.SCORE.death + config.SCORE.self_death, "and whoever jumps off loses more (" .. s1.points .. ")")
	run(gs, game.RESPAWN_TICKS + 5)
	check(not s1.dead and gs.current == 1 and gs.phase == "aim" and next(s1.life_damage) == nil,
		"then starts again in their turn, and the damage of the previous life no longer counts")
	-- in their own turn, recently hit by an opponent: the normal rule applies
	local gr = game.new(3, "pavimento")
	run(gr, 60)
	gr:hurt(gr.robots[1], 5, gr.robots[2])
	gr:kill(gr.robots[1], "fell")
	check(gr.robots[2].env_kills == 1 and gr.robots[1].points == config.SCORE.death, "recently hit: normal environmental kill")
	-- in their own turn without damage from anyone: no points to the others, but the penalty yes
	local gn = game.new(3, "pavimento")
	run(gn, 60)
	gn:kill(gn.robots[1], "fell")
	check(gn.robots[2].kills == 0 and gn.robots[1].points == config.SCORE.death + config.SCORE.self_death,
		"died alone without damage: only the penalty")

	-- hitting whoever is first is worth more
	-- (the Crown only exists after SCORE.crown_rounds full rounds)
	local g0 = game.new(3, "pavimento", { players = config.MODES.ffa })
	g0.robots[3].points = 100
	check(config.SCORE.crown_rounds >= 1 and g0:leader() == nil, "in the first round nobody has the Crown")
	for _ = 1, 4 do g0:end_turn() end
	check(g0.round == 2 and g0:leader() == g0.robots[3], "from the second round the Crown goes to the leader")
	local gl = game.new(3, "pavimento", { players = config.MODES.ffa })
	gl.round = config.SCORE.crown_rounds + 1
	gl.robots[3].points = 100
	gl:hurt(gl.robots[3], 10, gl.robots[1])
	gl:hurt(gl.robots[4], 10, gl.robots[2])
	check(gl.robots[1].points == 10 * config.SCORE.leader and gl.robots[2].points == 10, "hitting the leader is worth more")

	-- Crown: whoever downs the leader gets crown extra
	local gc = game.new(3, "pavimento", { players = config.MODES.ffa })
	gc.round = config.SCORE.crown_rounds + 1
	gc.robots[3].points = 100
	gc:hurt(gc.robots[3], gc.robots[3].hp, gc.robots[1])
	local hp3 = gc.robots[3].max_hp
	check(gc.robots[1].kills == 1 and gc.robots[1].points == (hp3 + config.SCORE.kill) * config.SCORE.leader + config.SCORE.crown,
		"downing the leader is also worth the Crown (" .. gc.robots[1].points .. ")")
	-- every point is also a "points" event (the number flying in the UI)
	local sum, reasons = { 0, 0, 0, 0 }, {}
	for _, e in ipairs(gc:pop_events()) do
		if e.type == "points" then
			sum[e.robot] = sum[e.robot] + e.amount
			reasons[e.reason] = e.other
		end
	end
	check(sum[1] == gc.robots[1].points and sum[3] == config.SCORE.death and reasons.damage == 3
		and reasons.kill == 3 and reasons.death == 1, "points events add up the points, with the reason and the other robot")

	-- Rampino and trampoline: whoever moves an enemy without damage gets the kill if it falls
	local gk = game.new(3, "pavimento")
	run(gk, 60)
	gk:credit(gk.robots[2], gk.robots[1])
	gk:kill(gk.robots[2], "fell")
	check(gk.robots[1].kills == 1 and gk.robots[1].env_kills == 1
		and gk.robots[1].points == config.SCORE.kill + config.SCORE.env_kill, "whoever pulls someone off with the Rampino gets the environmental kill")

	-- parry: the shield gives points to its carrier for the enemy damage it stops, up to parry_max
	local gp = game.new(3, "pavimento", { ammo = { shield = 1 } })
	run(gp, 60)
	local p1, p2 = gp.robots[1], gp.robots[2]
	gp:step({ fire = { angle = 0, power = 1, weapon = "shield" } })
	gp:hurt(p1, 20, p2)
	check(p1.points == 20 * config.SCORE.parry, "the parry gives points to the shield carrier (" .. p1.points .. ")")
	gp:hurt(p1, 100, p2)
	check(p1.points == config.SCORE.parry_max, "but at most parry_max per shield (" .. p1.points .. ")")

	-- in 2 v 2 damage to a teammate gives no points, and points add up per team
	local gt = game.new(3, "pavimento", { players = config.MODES["2v2"] })
	gt:hurt(gt.robots[3], 10, gt.robots[1])
	check(gt.robots[1].points == 0, "hitting a teammate gives no points")
	gt.robots[2].points, gt.robots[3].points, gt.robots[4].points = 30, 20, 0
	local res = gt:results()
	check(res.mode == "2v2" and res.winner == 2 and res.ranking[1].robot == 2 and res.ranking[2].robot == 4
		and res.ranking[2].place == 1 and res.ranking[3].place == 2, "results: standings by team points")
	gt.robots[3].points = 30
	check(gt:results().winner == nil, "equal teams: a draw")
end

-- The slash stays in the starting direction even if the robot turns
local g5 = game.new(7, "pavimento")
for _ = 1, 120 do g5:step({}) end -- robots fall and settle
g5.robots[2].x, g5.robots[2].y = g5.robots[1].x + 25, g5.robots[1].y
g5.robots[2].vx, g5.robots[2].vy = 0, 0
g5:step({ fire = { angle = 0, power = 1, weapon = "sword" } })
check(g5.robots[1].swing_dir == 1, "the slash starts to the right")
for _ = 1, 4 do g5:step({ left = true }) end
check(g5.robots[1].facing == -1 and g5.robots[1].swing_dir == 1, "turning doesn't change the direction of the slash")
run(g5, SWORD_TICKS)
check(g5.robots[2].hp < g5.robots[2].max_hp, "the slash hits to the right even after turning")

-- The sword hit does damage but doesn't make the opponent fly
local g6 = game.new(7, "pavimento")
for _ = 1, 120 do g6:step({}) end
local t6 = g6.robots[2]
t6.x, t6.y = g6.robots[1].x + 25, g6.robots[1].y
for _ = 1, 30 do g6:step({}) end -- settles at the new point
local tx6, ty6 = t6.x, t6.y
g6:step({ fire = { angle = 0, power = 1, weapon = "sword" } })
run(g6, SWORD_TICKS + 30)
check(t6.hp < t6.max_hp, "the sword does damage")
check(t6.x == tx6 and t6.y == ty6 and t6.grounded, "the sword doesn't move the opponent")

-- Timed match: around 5 minutes there's the last round, then it ends and whoever has the most points wins
local g7 = game.new(42, "pavimento")
g7.robots[2].points = 10
local ticks7 = 0
while g7.phase ~= "over" and ticks7 < game.MATCH_TICKS + 4000 do
	g7:step({})
	ticks7 = ticks7 + 1
end
check(g7.phase == "over" and g7.final_round and g7.match_left <= g7:final_round_ticks(),
	"the match ends after the last round, around 5 minutes")
check(g7.winner == 2, "when time's up whoever has the most points wins")
check(g7.robots[1].turns == g7.robots[2].turns, "everyone played the same turns")

-- Last round (Sergio, 31 Oct): the round that starts with less than half a
-- round of time left is the last, points are worth double, and when it ends it's over
do
	local ot = game.new(42, "pavimento")
	run(ot, 60)
	ot.match_left = 10
	run(ot, 20)
	check(not ot.final_round and ot.phase == "aim" and ot.current == 1,
		"the round already started doesn't become the last: the current turn goes on")
	for _ = 1, 4000 do
		ot:step()
		if ot.current == 2 or ot.phase == "over" then break end
	end
	check(ot.current == 2 and ot.phase == "aim" and not ot.final_round, "the round is finished: the second one plays too")
	ot:pop_events()
	local announcement = false
	for _ = 1, 4000 do
		ot:step()
		for _, e in ipairs(ot:pop_events()) do
			if e.type == "final_round" then announcement = true end
		end
		if ot.current == 1 or ot.phase == "over" then break end
	end
	check(ot.final_round and announcement and ot.current == 1 and ot.phase == "aim", "then the last round starts, with the event")
	local first_one = ot.robots[1].points
	ot:add_points(ot.robots[1], 10, "damage", ot.robots[2])
	check(ot.robots[1].points == first_one + 10 * config.SCORE.final_round, "in the last round points are worth double")
	for _ = 1, 8000 do
		ot:step()
		if ot.phase == "over" then break end
	end
	check(ot.phase == "over" and ot.current == 2, "after the last round the match ends")
	check(ot.robots[1].turns == ot.robots[2].turns, "everyone played the same turns")
end

-- Turn pairs with two teams: whoever opens the pair has "pending" points
-- until the other team has answered (battle/score.lua)
do
	local pc = game.new(42, "pavimento", { players = config.MODES["2v2"] })
	check(pc.ahead == 1 and pc.ahead_base == 0, "the first turn opens a pair")
	pc.robots[1].points = 40
	local function next_one(g)
		local c = g.current
		for _ = 1, 4000 do
			g:step()
			if g.current ~= c or g.phase == "over" then break end
		end
	end
	next_one(pc)
	check(pc.current == 2 and pc.ahead == 1 and pc.ahead_base == 0, "while the other team answers the points stay pending")
	next_one(pc)
	check(pc.current == 3 and pc.ahead == 1 and pc.ahead_base == 40, "once the pair is closed, the points count")
	local ffa = game.new(42, "pavimento", { players = config.MODES.ffa })
	check(ffa.ahead == 0, "with more than two teams no pairs")
end


-- Collisions: robots don't pass through each other, walking they push a tiny bit
local cg = game.new(7, "pavimento")
for _ = 1, 120 do cg:step({}) end
local c1, c2 = cg.robots[1], cg.robots[2]
c2.x, c2.y, c2.vx, c2.vy = c1.x + 20, c1.y + 4, 0, 0
for _ = 1, 30 do cg:step({}) end -- robot 2 settles
local c2x = c2.x
local c1x = c1.x
for _ = 1, 60 do cg:step({ right = true }) end
check(c2.x > c1.x and cg:robot_at(c1.x, c1.y, c1) == nil, "robots don't pass through each other")
check(c2.x > c2x + 2 and c2.x < c2x + 35, string.format("walking you push the other a tiny bit (%.1f px)", c2.x - c2x))
check(c1.x < c1x + 50, "whoever pushes goes slower")

-- A robot falling on another stays on top of it
local hg = game.new(7, "pavimento")
for _ = 1, 120 do hg:step({}) end
local h1, h2 = hg.robots[1], hg.robots[2]
h2.x, h2.y, h2.vx, h2.vy, h2.grounded = h1.x, h1.y + 60, 0, 0, false
for _ = 1, 90 do hg:step({}) end
check(h2.grounded and math.abs(h2.y - (h1.y + game.ROBOT_H)) < 1.01, "whoever falls on a robot stays on its head")

-- The orb landing on a robot moves it a tiny bit and bounces
local og = game.new(7, "pavimento")
for _ = 1, 120 do og:step({}) end
local o2 = og.robots[2]
local o2x = o2.x
og.orbs = { { id = 99, x = o2.x - 30, y = o2.y + 8, vx = 400, vy = 0, owner = 1, timer = 60, age = 100 } }
local bounced = false
for _ = 1, 10 do
	og:step({})
	if og.orbs[1] and og.orbs[1].vx < 0 then bounced = true end
end
check(o2.x > o2x and o2.x <= o2x + game.ORB_NUDGE + 0.01, string.format("the orb moves the robot a tiny bit (%.1f px)", o2.x - o2x))
check(bounced, "the orb bounces on the robot")

-- Orbs also bump into each other
local bg = game.new(42, "pavimento")
run(bg, 120)
local by = 950 -- open sky on the floor
bg.orbs = {
	{ id = 1, x = 600, y = by, vx = 200, vy = 0, owner = 1, timer = 100, age = 100 },
	{ id = 2, x = 680, y = by, vx = -200, vy = 0, owner = 1, timer = 100, age = 100 },
}
for _ = 1, 20 do bg:step({}) end
check(bg.orbs[1].x < bg.orbs[2].x and bg.orbs[1].vx < 0 and bg.orbs[2].vx > 0, "two colliding orbs bounce")

-- Crate weapons -------------------------------------------------------------

-- Without shots crate weapons don't fire; with one shot they fire once
local am = game.new(42, "pavimento")
run(am, 120)
am:step({ fire = { angle = math.rad(45), power = 0.6, weapon = "grenade" } })
check(am.phase == "aim" and not am.projectile, "without shots the Uovo di Fiamma doesn't leave")
am.robots[1].ammo.grenade = 1
am:step({ fire = { angle = math.rad(45), power = 0.6, weapon = "grenade" } })
check(am.projectile and am.projectile.kind == "grenade" and am.robots[1].ammo.grenade == 0,
	"with one shot the Uovo leaves and the shot is used up")

-- Uovo di Fiamma: bounces, settles and blows up after 5 seconds, bigger than the missile
local gr = game.new(42, "pavimento")
run(gr, 120)
gr:pop_events()
gr.robots[1].ammo.grenade = 1
local gy0 = sky_spot(gr, 640, 60)
place(gr.robots[1], 640, gy0)
gr:step({ fire = { angle = math.rad(-60), power = 0.8, weapon = "grenade" } })
local bounced, boom, boom_tick = false, nil, nil
for i = 1, game.GRENADE_FUSE + 5 do
	local p = gr.projectile
	local vy0 = p and p.vy
	gr:step()
	if p and gr.projectile and vy0 < 0 and gr.projectile.vy > 0 then bounced = true end
	for _, e in ipairs(gr:pop_events()) do
		if e.type == "explosion" and not boom then boom, boom_tick = e, i end
	end
end
check(bounced, "the Uovo bounces on the terrain")
check(boom and boom.r == game.GRENADE_BLAST.r and boom.r > game.MISSILE_BLAST.r, "the Uovo makes a bigger explosion than the missile")
check(boom_tick and math.abs(boom_tick - game.GRENADE_FUSE) <= 1, "the Uovo blows up after 5 seconds (" .. tostring(boom_tick) .. " tick)")

-- Sciame di Schegge: a burst of SHARD_COUNT shards with small craters
local sh = game.new(42, "pavimento")
run(sh, 120)
sh:pop_events()
sh.robots[1].ammo.shards = 1
local tx = sh.robots[2]
sh:step({ fire = { angle = math.atan2(tx.y - sh.robots[1].y, tx.x - sh.robots[1].x), power = 1, weapon = "shards" } })
local booms, max_flying = 0, 0
for _ = 1, 120 do
	sh:step()
	local n = 0
	for i = 1, game.SHARD_COUNT do if sh.shards[i] then n = n + 1 end end
	max_flying = math.max(max_flying, n)
	for _, e in ipairs(sh:pop_events()) do
		if e.type == "explosion" then
			booms = booms + 1
			check(e.r == game.SHARD_BLAST.r, "shards make small craters")
		end
	end
end
check(booms == game.SHARD_COUNT, "the burst fires " .. game.SHARD_COUNT .. " shards (" .. booms .. ")")
check(max_flying > 1, "several shards in flight together")
check(not sh:shards_flying(), "after the burst nothing is left in flight")

-- shot straight up they leave the map from the top and disappear there (bug of
-- 2 November: with almost no gravity they flew for more than a minute)
local up = game.new(42, "pavimento")
up.shards[1] = { x = game.WORLD_W / 2, y = game.WORLD_H - 10, vx = 0, vy = game.SHARD_SPEED, owner = 1, age = 100 }
for _ = 1, 60 do up:update_shards() end
check(not up:shards_flying(), "shards shot upwards are gone within a second")

-- Pugno del Titano: launches up whoever is in front, not whoever is behind
local function punch_game(dx)
	local q = game.new(42, "pavimento")
	run(q, 120)
	q:pop_events()
	local y = sky_spot(q, 640, 120)
	place(q.robots[1], 640, y)
	place(q.robots[2], 640 + dx, y)
	q.robots[1].ammo.punch = 1
	q:step({ fire = { angle = 0, power = 1, weapon = "punch" } })
	local hit
	for _ = 1, game.melee_ticks(melee.uppercut) do
		q:step()
		for _, e in ipairs(q:pop_events()) do
			if e.type == "punch_hit" then hit = { vx = q.robots[2].vx, vy = q.robots[2].vy } end
		end
	end
	return q, hit
end
local pq, ph = punch_game(2 * game.U)
check(ph and pq.robots[2].hp == pq.robots[2].max_hp - game.PUNCH_DAMAGE, "the punch hits whoever is in front")
check(ph and ph.vy == game.PUNCH_LAUNCH and ph.vx == 0, "the punch launches straight up")
local _, ph2 = punch_game(-6 * game.U)
check(ph2 == nil, "the punch doesn't hit whoever is behind")

-- Crates ---------------------------------------------------------------------------

-- With a rate (event rules, opts.crate_every) a crate drops after every 3
-- turns, always at the same point with the same seed
local function crate_turns(seed)
	local q = game.new(seed, "fossa", { crate_every = 3 })
	local spawned = {}
	for _ = 1, 12000 do
		q:step()
		for _, e in ipairs(q:pop_events()) do
			if e.type == "crate" then spawned[#spawned + 1] = { turn = q.turn_no, x = e.x, y = e.y } end
		end
		if #spawned >= 2 then break end
	end
	return q, spawned
end
local cq, cs = crate_turns(42)
check(cs[1] and cs[1].turn == 4 and cs[2] and cs[2].turn == 7, "one crate every 3 turns (turns " ..
	tostring(cs[1] and cs[1].turn) .. ", " .. tostring(cs[2] and cs[2].turn) .. ")")
local _, cs2 = crate_turns(42)
check(cs2[1] and cs2[1].x == cs[1].x and cs2[2].x == cs[2].x, "same seed, crates at the same points")
local _, cs3 = crate_turns(7)
check(cs3[1] and cs3[1].x ~= cs[1].x, "with another seed crates drop elsewhere")
local weapon_crates, item_drops = {}, {}
for _, k in ipairs(cq.crates) do
	if k.item then item_drops[#item_drops + 1] = k else weapon_crates[#weapon_crates + 1] = k end
end
local c1, c2 = weapon_crates[1], weapon_crates[2]
check(#weapon_crates == 2 and c2.y > game.WORLD_H, "the new crate drops from the sky")
check(#item_drops == 1 and game.ITEM_SET[item_drops[1].weapon], "an item drops every 6 turns, visible")
check(c1.landed and math.abs(c1.y - cs[1].y) <= game.CELL, "the crate settles on the surface")
check(c1.x >= 40 and c1.x <= game.WORLD_W - 40 and c2.x >= 40 and c2.x <= game.WORLD_W - 40, "crates are inside the map")

-- Touching a crate gives a shot of a crate weapon
local pk = game.new(42, "pavimento", { crate_every = 1 })
run(pk, 120)
local c = pk:spawn_crate()
check(c ~= nil and c.y > game.WORLD_H, "the crate starts from the sky")
run(pk, 600)
check(c.landed, "the crate lands")
pk:pop_events()
local pr = pk.robots[pk.current]
place(pr, c.x, c.y)
pk:step()
local got
for _, e in ipairs(pk:pop_events()) do if e.type == "crate_pick" then got = e end end
check(got and got.robot == pr.id and pr.ammo[got.weapon] == 1, "whoever touches the crate finds a weapon (" ..
	tostring(got and got.weapon) .. ")")
check(#pk.crates == 0, "the picked crate disappears")

-- Crates pick all three weapons
local seen = {}
local mix = game.new(11, "pavimento")
for _ = 1, 30 do
	mix.crates = {}
	local cc = mix:spawn_crate()
	if cc then seen[cc.weapon] = true end
end
check(seen.grenade and seen.shards and seen.punch, "all three weapons are found in crates")

-- Determinism with the new weapons: same seed and same inputs, same result
local function play2(seed)
	local p = game.new(seed, "fossa", { ammo = { grenade = 9, shards = 9, punch = 9 }, crate_every = 1 })
	local ws = { "grenade", "shards", "punch", "missile" }
	local k = 0
	for i = 1, 4000 do
		local input = { right = math.floor(i / 50) % 2 == 0, jump = i % 83 == 0 }
		if p.phase == "aim" and p.timer == game.TURN_TICKS - 40 then
			k = k + 1
			input.fire = { angle = math.rad(p.current == 1 and 40 or 140), power = 0.7, weapon = ws[k % #ws + 1] }
		end
		p:step(input)
	end
	local r = { p.robots[1].x, p.robots[1].hp, p.robots[2].x, p.robots[2].hp, solid_count(p.terrain), #p.crates }
	for _, cr in ipairs(p.crates) do r[#r + 1] = cr.x; r[#r + 1] = cr.y end
	return table.concat(r, " ")
end
check(play2(5) == play2(5), "crate weapons and crates are deterministic")

-- Physics: run, jump, explosions, melee, falls ------------------------------

local U = game.U

-- Movement: run 5 u/s, jump 5.2 u high
local bm = game.new(42, "pavimento")
run(bm, 120)
local br = bm.robots[1]
local x0 = br.x
run(bm, 60, { right = true })
check(math.abs((br.x - x0) - 5 * U) < 2, string.format("run 5 u/s (%.1f px in 1 s)", br.x - x0))
local top, base = br.y, br.y
bm:step({ jump = true })
for _ = 1, 200 do
	bm:step()
	top = math.max(top, br.y)
end
check(math.abs((top - base) - 5.2 * U) < 0.35 * U, string.format("jump 5.2 u high (%.1f px)", top - base))

-- Instant air control; without direction the speed stays
local ba = game.new(42, "pavimento")
run(ba, 120)
local ar = ba.robots[1]
ba:step({ jump = true, right = true })
run(ba, 5, { right = true })
check(ar.vx == ar.stats.air_speed, "in the air it goes full speed at once")
ba:step({ left = true })
check(ar.vx == -ar.stats.air_speed, "and turns sharply")
ba:step()
check(ar.vx == -ar.stats.air_speed and not ar.grounded, "without direction in the air the speed stays")

-- Explosion: damage from the nearest point of the square, no push on a direct
-- hit, maximum at half radius, half damage to oneself
local function blast_at(dx, owner)
	local q = game.new(42, "pavimento")
	run(q, 120)
	local r = q.robots[2]
	local y = sky_spot(q, 640, 60)
	place(r, 640, y)
	local hp = r.hp
	-- the right edge of the square around the hit circle
	local edge = game.HURT_R + game.HURT_FAT
	q:explode(640 + edge + dx, y + game.HURT_Y, owner, game.MISSILE_BLAST)
	return r, hp - r.hp
end
local B = game.MISSILE_BLAST
local d0r, d0 = blast_at(-1, 1)
check(d0 == math.floor(B.damage + 0.5) and d0r.vx == 0 and d0r.vy == 0,
	"direct hit, full damage and no push")
local half = B.damage_r / 2
local dhr, dh = blast_at(half, 1)
check(math.abs(dhr.vx + half * B.impulse * 0.5) < 0.01 and dhr.vy == 0,
	string.format("at half radius a push of %.0f px/s", -dhr.vx))
check(dh == math.floor(B.damage_min + (B.damage - B.damage_min) * 0.5 + 0.5), "damage between minimum and maximum")
local _, ds = blast_at(-1, 2)
check(ds == math.floor(B.damage * 0.5 + 0.5), "half damage to oneself")

-- Where you get hit: a circle at mid height, not the box
local hb = game.new(42, "pavimento")
local hr = hb.robots[2]
local hcy = hr.y + game.HURT_Y
check(hb:hits_robot(hr.x + game.HURT_R - 0.5, hcy, 1, 0) and not hb:hits_robot(hr.x + game.HURT_R + 0.5, hcy, 1, 0),
	"the target is a circle of radius HURT_R")
check(not hb:hits_robot(hr.x + game.ROBOT_HALF_W, hr.y, 1, 0), "the bottom corner of the box doesn't count")

-- Walking capsule and hit circle come from sim/body.lua (the animation editor
-- changes them); the drawing keeps its own size
local body_shape = require "sim.body"
check(game.ROBOT_H == body_shape.walk.height and game.ROBOT_HALF_W * 2 == body_shape.walk.width
	and game.HURT_R == body_shape.hit.radius and game.HURT_Y == body_shape.hit.center,
	"capsule and hit circle from sim/body.lua")
check(game.DISEGNO_H == game.REF_H * game.CORPO, "the drawing doesn't depend on sim/body.lua")

-- Melee on the aim: target = position of the target relative to the feet (in U
-- units), robots stay still in the air; returns the tick of the hit or false
local function melee_at(deg, tx, ty, weapon)
	local q = game.new(42, "pavimento")
	run(q, 120)
	q:pop_events()
	local pos = { { 0, 0 }, { tx * U, ty * U } }
	local function hold()
		for i, rb in ipairs(q.robots) do
			rb.x, rb.y, rb.vx, rb.vy, rb.grounded = 640 + pos[i][1], 400 + pos[i][2], 0, 0, false
		end
	end
	hold()
	if weapon == "punch" then q.robots[1].ammo.punch = 1 end
	q:step({ fire = { angle = math.rad(deg), power = 1, weapon = weapon or "sword" } })
	for t = 1, 200 do
		hold()
		q:step()
		for _, e in ipairs(q:pop_events()) do
			if e.type == "sword_hit" or e.type == "punch_hit" then return t, q end
		end
	end
	return false, q
end
local close = math.ceil(melee.slash.hit_to * 60 / melee.slash.fps)
check(melee_at(0, 5, 0) == close, "the slash hits when the window closes (0.8 s)")
check(melee_at(0, -4, 0) and melee_at(0, 0, 7), "aiming straight it also catches behind and above the head")
check(melee_at(-60, 4, -4) and not melee_at(60, 4, -4), "aiming down the blade comes down in front, low")
-- the targets not to be hit are further away as much as the body is bigger
-- than the reference robot (CORPO)
local C = game.CORPO
check(melee_at(60, 4, 5) and melee_at(-60, 0, -5) and not melee_at(60, 0, -5 - 7.5 * (C - 1)),
	"the hit rotates with the aim")
check(melee_at(-90, 4, -4) and not melee_at(-90, -4, 0), "aiming down it doesn't catch whoever is behind")
local pt, pq2 = melee_at(0, 2, 0, "punch")
check(pt and pq2.robots[2].vy == game.PUNCH_LAUNCH and pq2.robots[2].vx == 0,
	"the uppercut launches straight up")
check(not melee_at(-60, 0, 4 + 7.5 * (C - 1), "punch"), "the uppercut aimed down doesn't catch whoever is above")


-- Fall damage past 40 u
local bf = game.new(42, "pavimento")
run(bf, 120)
local fr2 = bf.robots[1]
local hp0 = fr2.hp
-- the map is 57.6 u tall: to have room the threshold goes down to 20 u
local safe0 = game.FALL_SAFE
game.FALL_SAFE = 20 * U
local DROP = math.floor(28 * U)
local fx, gy2
for x = 60, game.WORLD_W - 60, 8 do
	-- the highest ground under the robot, 2 * ROBOT_HALF_W wide
	local gy
	for _, o in ipairs({ -game.ROBOT_HALF_W, 0, game.ROBOT_HALF_W }) do
		local g = bf.terrain:ground_below(x + o, game.WORLD_H - 1)
		if g and (not gy or g > gy) then gy = g end
	end
	if gy and gy + DROP < game.WORLD_H - game.ROBOT_H and not bf:robot_collides(x, gy + DROP)
		and math.abs(x - bf.robots[2].x) > 4 * game.ROBOT_HALF_W then
		fx, gy2 = x, gy
		break
	end
end
check(fx ~= nil, "there's a point to fall from")
place(fr2, fx, gy2 + DROP)
for _ = 1, 400 do
	bf:step()
	if fr2.grounded then break end
end
local fall = gy2 + DROP - fr2.y
local expect = math.floor(math.min((fall - game.FALL_SAFE) * game.FALL_DAMAGE, game.FALL_DAMAGE_MAX) + 0.5)
game.FALL_SAFE = safe0
check(fr2.grounded and fall > 20 * U and expect > 0 and hp0 - fr2.hp == expect,
	string.format("falling from %.0f px it loses %d (%d)", fall, expect, hp0 - fr2.hp))
local bf2 = game.new(42, "pavimento")
run(bf2, 120)
local sr = bf2.robots[1]
bf2:step({ jump = true })
run(bf2, 200)
check(sr.hp == sr.max_hp, "a jump does no damage")

-- Power: 20% dead zone and quadratic curve
check(game.aim_power(0.2) == 0.1 and game.aim_power(1) == 1 and math.abs(game.aim_power(0.6) - 0.25) < 1e-9,
	"quadratic power with dead zone")

-- Random crates: they drop, and always at the same points with the same seed
local function crates_seen(seed)
	local q = game.new(seed, "fossa")
	local seen = {}
	for i = 1, 12 * (game.TURN_TICKS + 200) do
		q:step()
		for _, e in ipairs(q:pop_events()) do
			if e.type == "crate" then seen[#seen + 1] = e.x end
		end
		if q.phase == "over" then break end
	end
	return table.concat(seen, " ")
end
local cs = crates_seen(9)
check(cs ~= "" and cs == crates_seen(9), "crates drop at random but the same with the same seed (" .. cs .. ")")


-- Capsule body, short jump, coyote time and early jump -----------------

-- An empty world with solid terrain below ground(x) (pixels from the bottom)
local function shaped_world(ground)
	local q = game.new(42, "pavimento")
	local t, c = q.terrain, game.CELL
	for i = 1, #t.data do t.data[i] = 0 end
	for cx = 0, game.WORLD_W / c - 1 do
		local h = ground(cx * c + c / 2)
		for cy = 0, math.floor(h / c) - 1 do t:set(cx, cy, 1) end
	end
	place(q.robots[2], 60, ground(60))
	q.robots[2].grounded = true
	q:pop_events()
	return q
end

-- On a 45 degree slope the round bottom stays close to the terrain (a
-- rectangle would stay hanging on the corner)
local function slope_gap()
	local slope = function(x) return 100 + math.max(0, math.min(200, x - 500)) end
	local q = shaped_world(slope)
	local r = q.robots[1]
	place(r, 600, 260)
	run(q, 120)
	return r.y - slope(r.x), r.grounded
end
local gap_round, gr = slope_gap()
check(gr and gap_round < game.ROBOT_HALF_W * 0.6, string.format("capsule: at the centre it's as far above the slope as the edge of the circle (%.1f px)", gap_round))

-- Short jump: releasing the button at once rises much less
local function jump_top(hold_ticks)
	local q = shaped_world(function() return 100 end)
	local r = q.robots[1]
	place(r, 640, 100)
	run(q, 30)
	local base, top = r.y, r.y
	q:step({ jump = true, hold = true })
	for i = 1, 150 do
		q:step({ hold = i < hold_ticks })
		top = math.max(top, r.y)
	end
	return top - base
end
local full, short = jump_top(1000), jump_top(4)
check(math.abs(full - 5.2 * U) < 0.35 * U, string.format("short jump: holding it the jump is full (%.1f px)", full))
check(short < full * 0.5, string.format("short jump: releasing at once rises less than half (%.1f px)", short))

-- Coyote time: right after stepping off the edge you can still jump, a bit later no
local function ledge_jump(after)
	local q = shaped_world(function(x) return x < 640 and 200 or 40 end)
	local r = q.robots[1]
	place(r, 600, 200)
	run(q, 30)
	local n = 0
	while r.grounded and n < 200 do q:step({ right = true }); n = n + 1 end
	run(q, after - 1)
	q:step({ jump = true })
	return r.vy > 0
end
check(ledge_jump(3), "coyote: three ticks after the edge the jump starts")
check(not ledge_jump(game.COYOTE_TICKS + 4), "coyote: later in the air you can't jump")

-- Early jump: asked just before landing it starts as soon as you touch ground
local function buffered(early)
	local q = shaped_world(function() return 100 end)
	local r = q.robots[1]
	place(r, 640, 160)
	local n = 0
	while not r.grounded and n < 300 do q:step(); n = n + 1 end
	place(r, 640, 160)
	for i = 1, n do q:step({ jump = i == n - early }) end
	q:step()
	return r.vy > 0 and not r.grounded
end
check(buffered(3), "early jump: asked 3 ticks before, starts on landing")
check(not buffered(game.JUMP_BUFFER_TICKS + 4), "early jump: asked too early doesn't count")

-- Rampino on a robot on the ground: the floor under the target doesn't stop
-- the rope, neither on the flat (even with the puller one cell lower) nor on a
-- slope, uphill or downhill: it comes right up to the puller. Before, 9 times
-- out of 10 it stopped at once. hook_drag gives the final distance between the two.
local function hook_drag(ground, xa, xb)
	local q = shaped_world(ground)
	local a, b = q.robots[1], q.robots[2]
	place(a, xa, ground(xa))
	place(b, xb, ground(xb))
	for _ = 1, 30 do q:step() end
	local ang = math.atan2(b.y + game.ROBOT_H / 2 - (a.y + game.SWORD_PIVOT_Y), b.x - a.x)
	hook(q, ang)
	if not b.hooked then return math.huge end
	for _ = 1, 60 do
		q:step()
		if not b.hooked then break end
	end
	return math.abs(b.x - a.x)
end
local close = 2 * game.ROBOT_HALF_W + 4
check(hook_drag(function() return 100 end, 500, 680) < close, "Rampino on the flat: the enemy on the ground is dragged right up")
check(hook_drag(function(x) return x < 560 and 100 - game.CELL or 100 end, 500, 680) < close,
	"Rampino on the flat, puller one cell lower: dragged anyway")
check(hook_drag(function(x) return 100 + (x - 500) * 0.4 end, 500, 680) < close,
	"Rampino uphill (enemy higher): dragged down")
check(hook_drag(function(x) return 200 - (x - 500) * 0.4 end, 500, 680) < close,
	"Rampino downhill (enemy lower): dragged up")
check(hook_drag(function(x) return 100 + math.floor(x / 24) % 2 * 4 end, 500, 680) < close,
	"Rampino on a stepped floor: dragged anyway")
-- on the real maps: enemies on the ground at 120 pixels, at many different points
for _, id in ipairs(maps.order) do
	local pulled, tries = 0, 0
	for x0 = 100, game.WORLD_W - 220, 37 do
		local q = game.new(42, id)
		run(q, 60)
		local a, b = q.robots[1], q.robots[2]
		local ya = q.terrain:ground_below(x0, game.WORLD_H - 1)
		local yb = q.terrain:ground_below(x0 + 120, game.WORLD_H - 1)
		if ya and yb and math.abs(ya - yb) < 30 then
			place(a, x0, ya)
			place(b, x0 + 120, yb)
			run(q, 30)
			if a.grounded and b.grounded and not a.dead and not b.dead then
				local bx, by = b.x, b.y
				hook(q, math.atan2(b.y + game.ROBOT_H / 2 - (a.y + game.SWORD_PIVOT_Y), b.x - a.x))
				if b.hooked then
					tries = tries + 1
					for _ = 1, 40 do
						q:step()
						if not b.hooked then break end
					end
					if math.sqrt((bx - b.x) ^ 2 + (by - b.y) ^ 2) > 80 then pulled = pulled + 1 end
				end
			end
		end
	end
	check(tries > 0 and pulled == tries, id .. ": the Rampino drags the enemy on the ground every time (" .. pulled .. "/" .. tries .. ")")
end
check(hook_drag(function(x) return (x > 560 and x < 572) and 100 + game.ROBOT_H or 100 end, 500, 650) > 650 - 560,
	"Rampino: a high wall stops the enemy")

-- Performance: one crater and 600 ticks of simulation
local t = os.clock()
local g4 = game.new(5, "pavimento")
for i = 1, 600 do g4:step({ right = i % 2 == 0 }) end
for i = 1, 20 do g4.terrain:carve(100 + i * 50, 200, 30) end
print(string.format("info 600 ticks + 20 craters in %.1f ms", (os.clock() - t) * 1000))

-- Phone sticks (client/battle/sticks.lua)
do
	local sticks = require "battle.sticks"
	local s = sticks.new()
	sticks.move(s, 0.1, 0)
	check(not s.moving, "stick: at 10% sideways it doesn't walk")
	sticks.move(s, 0.5, 0)
	check(s.moving and s.dir == 1, "stick: sideways it walks right")
	local jumped = sticks.move(s, 0.5, 0.5)
	check(s.moving and s.jumping and jumped, "stick: diagonally it walks and jumps")
	check(not sticks.move(s, 0.5, 0.55), "stick: the jump starts only once")
	sticks.move(s, 0.05, 0.6)
	check(not s.moving and s.jumping, "stick: straight up it jumps in place")
	sticks.move(s, -0.6, -0.1)
	check(s.moving and s.dir == -1 and not s.jumping, "stick: down left it walks and doesn't jump")
	sticks.move(s, -0.05, 0)
	check(not s.moving, "stick: back at the centre it stops")
	sticks.move(s, 0.2, -0.6)
	check(not s.moving, "stick: downwards 25% sideways is needed")

	local a = sticks.new()
	sticks.aim(a, 0.15, 0)
	check(not a.active, "aim: below 20% off")
	sticks.aim(a, 0, -0.6)
	check(a.active and math.abs(a.angle + math.pi / 2) < 1e-6 and math.abs(a.f - 0.5) < 1e-6,
		"aim: on, downwards, power 0.5 at 60%")
	sticks.aim(a, 0.15, 0)
	check(a.active, "aim: between 10% and 20% it stays on")
	sticks.aim(a, 0.05, 0)
	check(not a.active, "aim: below 10% it turns off")

	-- the thumb slipping at the last instant doesn't count
	local r = sticks.new()
	for i = 0, 30 do sticks.record(r, i / 60, i < 28 and 1.0 or 2.0, 0.7, i < 30) end
	local h = sticks.on_release(r, 30 / 60)
	check(h and h.angle == 1.0 and h.active, "aim: on release the aim of 50 ms earlier counts")
	local sa, sp = sticks.shot(r, 30 / 60, 9, 9)
	check(sa == h.angle and sp == h.power, "aim: the shot (and the lessons' trajectory) use the aim of 50 ms earlier")
	sticks.reset(r)
	check(sticks.on_release(r, 1) == nil, "aim: after reset no aim recorded")
	check(select(1, sticks.shot(r, 1, 9, 9)) == 9, "aim: nothing recorded, the live aim")
end

do
	-- whoever leaves online disappears: no points, no respawn, the turn passes
	local g = game.new(42, "pavimento", { players = { { team = 1 }, { team = 2 }, { team = 3 }, { team = 4 } } })
	g:pop_events()
	local point_total = g.robots[2].points
	g:remove(1)
	local ev = g:pop_events()
	local kinds = {}
	for _, e in ipairs(ev) do kinds[#kinds + 1] = e.type end
	check(g.robots[1].gone and g.robots[1].dead and g.current == 2, "the one on turn leaves: the turn passes to 2")
	check(table.concat(g.order, " ") == "2 3 4" and table.concat(kinds, " "):find("gone") and not table.concat(kinds, " "):find("death"),
		"leaves: out of the order, gone event and no death")
	check(g.robots[2].points == point_total, "leaves: no points to anyone")
	g:remove(3)
	g:end_turn()
	check(g.current == 4, "after 2 it's 4's turn (3 left)")
	g:end_turn()
	check(g.current == 2, "and then 2 again")
	for _ = 1, game.RESPAWN_TICKS + 5 do g:step({}) end
	check(g.robots[1].dead and g.robots[3].dead, "whoever left doesn't respawn")
end

-- match time doesn't go down while waiting for everything to settle between turns
do
	local g = game.new(42, "pavimento")
	g:step({ fire = { weapon = "missile", angle = 1.2, power = 0.8 } })
	while g.phase == "aim" do g:step() end
	local first_one, t = g.match_left, 0
	while g.phase == "settle" do
		g:step()
		t = t + 1
	end
	check(t > 1 and g.match_left == first_one, "match time is stopped between turns")
end

-- rules as data (sim/rules.lua): the whitelist and what reaches game.new and the draft
do
	local rules = require "sim.rules"
	local draft = require "sim.draft"
	check(rules.validate({ casse = 2, cure = false, livello = "fisso", armi = { "punch", "mallet" }, punti = { kill = 80 } }),
		"rules: a correct rule passes")
	for _, r in ipairs({ { wind = 3 }, { casse = 0 }, { casse = 2.5 }, { armi = { "punch" } }, { armi = { "laser", "mallet" } },
		{ punti = { volo = 3 } }, { punti = { kill = 5000 } }, { livello = "alto" }, { cure = "no" } }) do
		local k = next(r)
		check(not rules.validate(r), "rules: rejected " .. k)
	end
	check(rules.validate({ tetto = 15 }, true) and not rules.validate({ tetto = 30 }) and not rules.validate({ tetto = 0 }),
		"rules: the level cap goes from 1 to below the maximum")
	check(not rules.validate({ casse = 2 }, true), "rules: on a normal queue only the cap")
	local opts = rules.options({ casse = 2, cure = false, punti = { kill = 80 } }, {})
	local g = game.new(7, "pavimento", opts)
	check(g.crate_every == 2 and not g.heals_on and g.score.kill == 80 and g.score.damage == config.SCORE.damage,
		"rules: crates, heals and points reach the match")
	local d = draft.new(7, config.MODES["2v2"], rules.weapons({ armi = { "punch", "mallet", "eagle" } }))
	check(#d.offer == 1 and d.offer[1] == "punch" and #d.offer2 == 2, "rules: the draft offers only the event's weapons")
	check(rules.weapons({ casse = 2 }) == nil, "rules: without weapons the draft stays the usual one")
end

-- random start points (real matches, not the campaign): far from enemies and teammates,
-- on the ground, never under a ceiling, the same for the same seed
do
	for _, map in ipairs({ "pavimento", "fossa" }) do
		for seed = 1, 60 do
			local g = game.new(seed, map, { players = config.MODES["2v2"], random_spawns = true })
			local g2 = game.new(seed, map, { players = config.MODES["2v2"], random_spawns = true })
			local ok = true
			for i, a in ipairs(g.robots) do
				local b = g2.robots[i]
				ok = ok and a.x == b.x and a.y == b.y and g.terrain:ground_below(a.x, a.y + 2) == a.y
					and not g.terrain:any_solid(math.floor(a.x / 3), math.floor(a.x / 3),
						math.floor(a.y / 3) + 1 + 40, math.floor(a.y / 3) + 80)
				for j = i + 1, #g.robots do
					local o = g.robots[j]
					local d = math.sqrt((a.x - o.x) ^ 2 + (a.y - o.y) ^ 2)
					ok = ok and d >= (a.team == o.team and 190 or 250)
				end
			end
			check(ok, "random start: " .. map .. " seed " .. seed)
		end
	end
	local fixed = game.new(5, "pavimento", { players = config.MODES["2v2"] })
	check(fixed.robots[1].x == 225, "random start: without the option the map's points stay (campaign)")
end

-- Wide side limits (Sergio, 9 Nov 2026): beside the map there is room for platforms and
-- you die a long way out, so the parachute can still save you
do
	local m = game.new(42, "pavimento")
	local t = m.terrain
	check(t.ox == game.MARGIN_CELLS and t.w == game.GRID_W, "the grid has a margin beside the map")
	-- no side walls or ledges on the Forge any more (Sergio, 11 Nov): only the courtyard has them
	check(not t:solid(-60, 480) and not t:solid(game.WORLD_W + 60, 480),
		"pavimento: nothing beside the map")
	local rb = m.robots[1]
	rb.x, rb.y, rb.vy, rb.grounded = -500, 800, 0, false
	m:step()
	check(not rb.dead, "500 units beside the map you are still alive")
	rb.x = -game.KILL_SIDE - 10
	m:step()
	check(rb.dead, "far beyond the side limit you die")
end


-- The Sigilli's powers (sim/skills.lua): each one does what it says, and with
-- the base stats nothing changes
do
	local function duel(st)
		return game.new(42, "pavimento", { players = { { team = 1, stats = st, secondary = "eagle" }, { team = 2, secondary = "eagle" } } })
	end
	local m = duel({ last_stand = 1, burn_immune = 1, start_shields = 1, extra_secondary = 1 })
	local a, b = m.robots[1], m.robots[2]
	check(a.ammo.shield == b.ammo.shield + 1 and a.ammo.eagle == b.ammo.eagle + 1, "Scudo pronto and Tasca in più")
	m:hurt(a, 500, b)
	check(not a.dead and a.hp == 1, "Ultimo respiro: 1 hp instead of dying")
	m:hurt(a, 5, b)
	check(a.dead, "Ultimo respiro only once")
	m = duel({ burn_immune = 1 })
	m:add_status(m.robots[1], "burn", m.robots[2])
	check(not m.robots[1].status.burn, "Pelle di brace: no burning")
	m = duel({ crate_bonus = 1, double_traps = 1 })
	a = m.robots[1]
	local g0, t0 = a.ammo.grenade, a.ammo.trap
	game.give(a, "grenade")
	game.give(a, "trap")
	check(a.ammo.grenade == g0 + 2 and a.ammo.trap == t0 + 2, "Cassa piena and Trappola doppia")
	m = duel({ phoenix = 1 })
	a, b = m.robots[1], m.robots[2]
	b.x, b.y = a.x + 20, a.y
	local hp = b.hp
	m:hurt(a, 500, b)
	check(a.dead and b.hp < hp, "Fenice: dying you hurt who is near")
	m = duel({ extra_hooks = 1 })
	m:start_turn(1)
	m.used.tool = true
	check(m:can_use("hook"), "Doppio Rampino: a second Rampino")
	m:use_tool("hook", { angle = 1 })
	check(not m:can_use("hook"), "but not a third")
	m = duel({})
	m:start_turn(1)
	m.used.tool = true
	check(not m:can_use("hook"), "without powers one Rampino per turn")
end

-- Giano: a coin thrown like the missile; the first robot it touches (not the
-- thrower) trades places and movement with the thrower. No damage, no credit.
do
	local j = game.new(42, "pavimento")
	run(j, 60)
	local ja, jb = j.robots[1], j.robots[2]
	local sy = sky_spot(j, 640, 120)
	j.terrain:rect(400, sy - 60, 700, 140, 0)
	place(ja, 500, sy)
	place(jb, 700, sy)
	local hp, ax, bx = jb.hp, ja.x, jb.x
	check(j:can_use("janus"), "Giano is a tool, usable without shots")
	j:step({ fire = { angle = 0, power = 1, weapon = "janus" } })
	check(j.projectile and j.projectile.kind == "janus" and j.used.tool and not j.used.primary and not j:can_use("hook"),
		"Giano flies as a projectile, uses the tool of the turn and is not an attack")
	local swapped
	for _ = 1, 120 do
		j:step()
		for _, e in ipairs(j:pop_events()) do if e.type == "janus_swap" then swapped = e end end
		if swapped then break end
	end
	check(swapped and swapped.a == 1 and swapped.b == 2 and ja.x == bx and jb.x == ax and not j.projectile,
		"the first robot it touches trades places with the thrower")
	check(jb.hp == hp and not jb.last_hit, "the swap does no damage and gives no credit")
	-- terrain stops it: nobody moves
	local k = game.new(42, "pavimento")
	run(k, 60)
	local ka, kb = k.robots[1], k.robots[2]
	local x0 = ka.x
	k:step({ fire = { angle = math.rad(-90), power = 1, weapon = "janus" } })
	local fizzle
	for _ = 1, 120 do
		k:step()
		for _, e in ipairs(k:pop_events()) do if e.type == "janus_fizzle" then fizzle = e end end
		if not k.projectile then break end
	end
	check(fizzle and ka.x == x0 and not k.projectile, "terrain stops Giano without a swap")
end

if failures > 0 then
	print(failures .. " tests failed")
	os.exit(1)
end
print("all tests passed")
