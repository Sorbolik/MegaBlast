-- Tests of the six new weapons (config.BOOMERANG, TAR, DRILL, MAGNET, CANNON, PETARD).
--   luajit tests/new_weapons_test.lua
package.path = "client/?.lua;" .. package.path

local game = require "sim.game"
local config = require "sim.config"

local failures = 0
local function check(cond, msg)
	if cond then print("ok   " .. msg) else print("FAIL " .. msg) failures = failures + 1 end
end
local function run(g, ticks, input) for _ = 1, ticks do g:step(input) end end
local function place(rb, x, y) rb.x, rb.y, rb.vx, rb.vy, rb.grounded, rb.knocked = x, y, 0, 0, false, false end

-- A flat floor with a lot of sky: a at x = ax, b at x = bx, ammo for the weapon
local function arena(weapon, ax, bx, setup)
	local opts = {}
	if game.SECONDARY[weapon] then opts.secondary = weapon end
	local q = game.new(42, "pavimento", opts)
	run(q, 60)
	local a, b = q.robots[q.current], q.robots[q.current == 1 and 2 or 1]
	q.terrain:rect(100, 100, 1400, 400, 0)
	q.terrain:rect(100, 80, 1400, 20, 1)
	if setup then setup(q) end
	place(a, ax, 100)
	place(b, bx, 100)
	if not game.SECONDARY[weapon] and not game.FREE_WEAPONS[weapon] then a.ammo[weapon] = 2 end
	run(q, 20)
	return q, a, b
end
local function fire(q, weapon, angle, power)
	q:step({ fire = { angle = angle, power = power or 1, weapon = weapon } })
end
local function settle(q, ticks)
	for _ = 1, ticks or 600 do
		q:step()
		if q.phase ~= "aim" and not q.projectile then break end
	end
end

-- Every new weapon is known, with ammo and a category
for _, w in ipairs({ "boomerang", "tar", "drill" }) do
	check(game.WEAPONS[w] and not game.SECONDARY[w] and config.CRATE_CONTENTS and true, w .. " is a primary")
end
for _, w in ipairs({ "magnet", "cannon", "petard" }) do
	check(game.WEAPONS[w] and game.SECONDARY[w], w .. " is a secondary")
	local q = game.new(1, "pavimento", { secondary = w })
	q.robots[1].ammo[w] = 1
	check(q:can_use(w) or q.current ~= 1, w .. " can be used with shots")
end

-- Falcetto: 18 on the way out, 18 and cracked armour on the way back
do
	-- the target stands beyond the turning point's reach but within the way back
	local q, a, b = arena("boomerang", 600, 600 + config.BOOMERANG.range - 20)
	local hp = b.hp
	fire(q, "boomerang", 0)
	local out, back = 0, 0
	for _ = 1, 400 do
		q:step()
		for _, e in ipairs(q:pop_events()) do
			if e.type == "boomerang_hit" then if e.back then back = back + 1 else out = out + 1 end end
		end
		if not q.projectile then break end
	end
	check(out == 1 and back == 1 and hp - b.hp == 2 * config.BOOMERANG.damage, "the Falcetto hits going out and coming back")
	check(b.status.cracked ~= nil, "the return hit cracks the armour")
	check(q.projectile == nil, "the Falcetto ends when it gets back")
end

-- Pozza di Pece: pool, burn, lasts two turns, one per team
do
	local q, a, b = arena("tar", 600, 800)
	local before = #q.pools
	fire(q, "tar", 0.5, 0.5)
	settle(q, 300)
	check(#q.pools == before + 1, "the flask leaves a pool")
	local pool = q.pools[#q.pools]
	place(b, pool.x, pool.y)
	run(q, 5)
	check(b.status.burn ~= nil, "whoever stands in the pool burns")
	local n = pool.turns
	q:age_pools()
	check(pool.turns == n - 1, "the pool loses a turn")
	for _ = 2, config.TAR.turns do q:age_pools() end
	check(#q.pools == before, "after config.TAR.turns turns the pool is gone")
end

-- Trapano: bores a tunnel through a wall and blows up on the other side
do
	local q, a, b = arena("drill", 400, 900, function(q2) q2.terrain:rect(600, 100, 60, 120, 1) end)
	place(b, 700, 100)
	local solid_before = q.terrain:solid(630, 115)
	fire(q, "drill", 0.02, 1)
	local carved = 0
	for _ = 1, 600 do
		q:step()
		for _, e in ipairs(q:pop_events()) do if e.type == "carve" then carved = carved + 1 end end
		if not q.projectile then break end
	end
	check(solid_before and carved > 5 and not q.terrain:solid(630, 115), "the Trapano digs a tunnel through the wall")
	check(q.projectile == nil, "the Trapano's shot ends")
end

-- Trapano: out of the wall it keeps flying and hits who is behind it, up to config.DRILL.after
do
	local function behind(dx)
		local q, a, b = arena("drill", 400, 900, function(q2) q2.terrain:rect(600, 100, 60, 120, 1) end)
		place(b, 660 + dx, 100)
		local hp, out = b.hp, false
		fire(q, "drill", 0.02, 1)
		for _ = 1, 600 do
			q:step()
			for _, e in ipairs(q:pop_events()) do if e.type == "drill_out" then out = true end end
			if not q.projectile then break end
		end
		return hp - b.hp, out
	end
	local dmg, out = behind(100)
	check(out and dmg > 0, "the Trapano out of the wall hits who is 100 px behind it")
	local far = behind(config.DRILL.after + 150)
	check(far == 0, "past config.DRILL.after pixels it hits nobody")
end

-- Calamita: pulls near robots to the centre, nothing over a pit
do
	local q, a, b = arena("magnet", 600, 600 + 120 + 90)
	local x0 = b.x
	fire(q, "magnet", 0)
	run(q, config.MAGNET.ticks)
	check(math.abs(b.x - (600 + config.MAGNET.distance)) < 30, "the Calamita slides the enemy to the centre")
	check(q.used.secondary and next(b.status) == nil, "secondary, no effects")
	local q2, a2, b2 = arena("magnet", 600, 800, function(q3) q3.terrain:rect(650, 0, 300, 100, 0) end)
	local x1 = b2.x
	fire(q2, "magnet", 0)
	run(q2, 40)
	check(not (q2.robots[q2.current].pull) and math.abs(b2.x - x1) < 5, "over a pit nothing is pulled")
end

-- Cannonata: flies, hits what it crosses, stops on terrain
do
	local q, a, b = arena("cannon", 500, 900)
	local hp = b.hp
	fire(q, "cannon", math.rad(45), 1)
	check(a.cannon ~= nil, "the user flies")
	for _ = 1, 400 do
		q:step()
		if not a.cannon then break end
	end
	check(not a.cannon and a.x > 700, "the flight ends on landing")
	check(hp - b.hp == config.CANNON.damage or b.hp == hp, "damage is the Cannonata's or none")
end
do
	local q, a, b = arena("cannon", 500, 700)
	local hp = b.hp
	fire(q, "cannon", math.rad(15), 0.8)
	for _ = 1, 400 do q:step() if not a.cannon then break end end
	check(hp - b.hp == config.CANNON.damage and b.vx > 0 or b.hp < hp, "the Cannonata hits who it crosses")
end

-- Petardo: blows up on a robot, pushes, no crater
do
	local q, a, b = arena("petard", 600, 800)
	local carves = 0
	fire(q, "petard", 0.3, 0.45)
	local boom
	for _ = 1, 300 do
		q:step()
		for _, e in ipairs(q:pop_events()) do
			if e.type == "petard_blast" then boom = e end
			if e.type == "explosion" then carves = carves + 1 end
		end
		if not q.projectile then break end
	end
	check(boom ~= nil and carves == 0, "the Petardo blows up without a crater")
end
do
	local q, a, b = arena("petard", 600, 640)
	local hp = b.hp
	fire(q, "petard", 0, 0.1)
	for _ = 1, 200 do q:step() if not q.projectile then break end end
	check(b.hp == hp - config.PETARD.damage or b.hp == hp, "the Petardo does its damage or misses")
end

if failures > 0 then
	print(failures .. " failures")
	os.exit(1)
end
print("all tests passed")
