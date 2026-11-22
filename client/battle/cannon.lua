-- The Cannonata as drawn (Sergio, 22 Nov: "il personaggio si trasforma in una
-- palla di cannone", proposal 2 of https://claude.ai/artifact/VM4s5mkDWYW7pbuv5yZwXY).
-- The cannon in hand jumps to the ground and grows, the devil curls up and jumps
-- into its muzzle, the fuse sizzles while the cannon swells three times, BOOM:
-- out flies an iron ball with the devil's head behind it (horns and flame above,
-- the eyes through the slit, battle/scoria.lua st.palla). On landing the ball
-- splits in two shells and the devil pops out. Graphics only: the windup and the
-- flight are in sim/game.lua (config.CANNON.windup), here only what is seen.
--
--   local c = cannon.new(fx, sign)             -- fx: battle/impact.lua's pool, sign: its colours
--   cannon.nodes(c)                            -- the nodes to put in the world
--   cannon.start(c, robot, x, y, angle, color) -- the "cannon" event: x, y the feet
--   cannon.fire(c)                             -- "cannon_fire": BOOM
--   cannon.land(c, x, y)                       -- "cannon_land": x, y the feet
--   cannon.rig(c, i, rb, st, dt)               -- every frame, before scoria.update: robot i's state
--   cannon.update(c, dt)                       -- every frame: cannon and shells

local impact = require "battle.impact"
local game = require "sim.game"
local config = require "sim.config"
local PIECES = require("battle.weapons").pieces

local M = {}

local GROW, JUMP, WINDUP = 0.25, 0.5, config.CANNON.windup
-- the cannon on the ground is the hand one this many times (tools/grafica/armi.py, cannone_grande)
local BIG = 1.9
-- where its muzzle is, from its pivot (the hand cannon's box times BIG: x forward, y up)
local MUZZLE_X, MUZZLE_Y = 30.4, 1
-- how far the shot kicks it back, and when it fades
local RECOIL, FADE_FROM, FADE = 7, 0.45, 0.4
-- the shells: gravity, how long they stay, when they start fading
local SHELL_G, SHELL_LIFE, SHELL_FADE = 700, 0.75, 0.3
-- the trail of smoke in flight: a puff every
local PUFF_EVERY = 0.06

local V = vmath.vector3()
local DEG = 180 / math.pi
local sin, cos, min, max, pi = math.sin, math.cos, math.min, math.max, math.pi

local function picture(name, parent)
	local p = PIECES[name]
	local n = gui.new_box_node(vmath.vector3(p.x, p.y, 0), vmath.vector3(p.w, p.h, 0))
	gui.set_adjust_mode(n, gui.ADJUST_FIT)
	gui.set_texture(n, "armi")
	gui.play_flipbook(n, p.img)
	gui.set_inherit_alpha(n, true)
	if parent then gui.set_parent(n, parent) end
	local t
	if p.tint then
		t = gui.new_box_node(vmath.vector3(p.x, p.y, 0), vmath.vector3(p.w, p.h, 0))
		gui.set_adjust_mode(t, gui.ADJUST_FIT)
		gui.set_texture(t, "armi")
		gui.play_flipbook(t, p.tint)
		gui.set_inherit_alpha(t, true)
		gui.set_parent(t, parent or n)
	end
	return n, t
end

-- a joint with a picture (and its team-colour layer) inside
local function holder(name)
	local root = gui.new_box_node(vmath.vector3(), vmath.vector3())
	gui.set_adjust_mode(root, gui.ADJUST_FIT)
	gui.set_visible(root, false)
	local _, tint = picture(name, root)
	gui.set_enabled(root, false)
	return { node = root, tint = tint, col = vmath.vector4(1, 1, 1, 1) }
end

function M.new(fx, sign)
	return { fx = fx, sign = sign, cannon = holder("cannone_grande"), shells = { holder("guscio_su"), holder("guscio_giu") },
		robot = nil, t = 0, puff = 0 }
end

function M.nodes(c)
	return { c.cannon.node, c.shells[1].node, c.shells[2].node }
end

local function place(h, x, y, a, sx, sy, alpha)
	V.x, V.y, V.z = x, y, 0
	gui.set_position(h.node, V)
	V.x, V.y, V.z = 0, 0, a * DEG
	gui.set_euler(h.node, V)
	V.x, V.y, V.z = sx, sy, 1
	gui.set_scale(h.node, V)
	h.col.w = alpha
	gui.set_color(h.node, h.col)
end

local function tint(h, color)
	if h.tint then gui.set_color(h.tint, vmath.vector4(color.x, color.y, color.z, 1)) end
end

-- back-out easing: overshoots a bit and settles
local function back(u)
	u = max(0, min(1, u)) - 1
	return 1 + 2.9 * u * u * u + 1.9 * u * u
end

-- the turn of the cannon and its mirror: it points at angle with the wheel down
local function aim(a)
	if cos(a) < 0 then return a - pi, -1 end
	return a, 1
end
-- a point of the cannon (u, v from its pivot, unscaled) in the world
local function on_cannon(c, u, v)
	local r, f = aim(c.angle)
	u = u * f
	return c.px + u * cos(r) - v * sin(r), c.py + u * sin(r) + v * cos(r)
end

function M.start(c, robot, x, y, angle, color)
	c.robot, c.t, c.angle, c.fired, c.landed, c.bx, c.by = robot, 0, angle, nil, nil, nil, nil
	c.x0, c.y0 = x, y
	-- the muzzle is where the flight starts (sim: the robot's centre)
	c.mx, c.my = x, y + game.DISEGNO_H / 2
	local r, f = aim(angle)
	c.px = c.mx - (MUZZLE_X * f * cos(r) - MUZZLE_Y * sin(r))
	c.py = c.my - (MUZZLE_X * f * sin(r) + MUZZLE_Y * cos(r))
	tint(c.cannon, color)
	for _, h in ipairs(c.shells) do tint(h, color) end
	gui.set_enabled(c.cannon.node, true)
	M.update(c, 0)
end

function M.fire(c)
	if not c.robot then return end
	c.fired, c.puff = c.t, 0
	-- BOOM: the ring of smoke out of the muzzle, a darker puff behind it
	local dx, dy = cos(c.angle), sin(c.angle)
	impact.sign(c.fx, "fx_anello_fumo", c.mx + dx * 10, c.my + dy * 10, 46, c.sign.white, "pop")
	impact.sign(c.fx, "fx_anello_fumo", c.mx + dx * 24, c.my + dy * 24, 24, c.sign.white, "drift")
	impact.sign(c.fx, "fx_stella", c.mx + dx * 6, c.my + dy * 6, 30, c.sign.brace, "pop")
end

function M.land(c, x, y)
	if not c.robot then return end
	c.landed = 0
	local face = cos(c.angle) < 0 and -1 or 1
	local cy = y + game.DISEGNO_H / 2
	-- the top shell jumps up and back, the bottom one slides forward
	c.shells[1].s = { x = x, y = cy, vx = -face * 70, vy = 240, a = 0, va = -face * 5 }
	c.shells[2].s = { x = x, y = cy, vx = face * 60, vy = 110, a = 0, va = face * 4 }
	for _, h in ipairs(c.shells) do gui.set_enabled(h.node, true) end
	impact.sign(c.fx, "fx_anello_fumo", x, cy, 34, c.sign.white, "pop")
end

-- Robot i's state while it fires the Cannonata, before scoria.update
function M.rig(c, i, rb, st, dt)
	st.rannicchia, st.scala, st.nascosto, st.palla, st.palla_giro = nil, nil, nil, nil, nil
	if c.robot ~= i then return end
	local ball = rb.cannon
	if rb.dead or not ball then
		-- landed (or gone): out it pops
		if not c.landed then c.robot = nil end
		return
	end
	local t = c.t
	if ball.wait > 0 then
		if t < GROW then
			-- it bends its knees while the cannon jumps out of its hands
			st.rannicchia = 0.35 * t / GROW
		elseif t < JUMP then
			-- the jump into the muzzle: curled up, smaller and smaller
			local u = (t - GROW) / (JUMP - GROW)
			st.rannicchia = 1
			st.scala = 1 - 0.7 * u
			st.x = c.x0 + (c.mx - c.x0) * u
			st.y = c.y0 + (c.my - game.DISEGNO_H * 0.3 - c.y0) * u + 18 * sin(pi * u)
			st.grounded = false
		else
			st.nascosto = true
		end
	else
		st.palla = true
		st.palla_giro = sin(t * 7) * 0.22
		-- the trail of smoke behind the ball
		-- the trail of smoke behind the ball (where it was a moment ago)
		c.puff = c.puff + dt
		if c.puff >= PUFF_EVERY and c.bx then
			c.puff = 0
			local dx, dy = st.x - c.bx, st.y - c.by
			local d = math.sqrt(dx * dx + dy * dy)
			if d > 0.5 then
				impact.sign(c.fx, "fx_anello_fumo", st.x - dx / d * 16, st.y + game.DISEGNO_H / 2 - dy / d * 16, 11, c.sign.white, "drift")
			end
		end
		c.bx, c.by = st.x, st.y
	end
end

function M.update(c, dt)
	if not c.robot and not c.landed then
		gui.set_enabled(c.cannon.node, false)
		return
	end
	c.t = c.t + dt
	local t = c.t
	-- the cannon: grows from the hand to the ground, swells with the fuse, recoils, fades
	local alpha, sx, sy, kick = 1, 1, 1, 0
	local px, py = c.px, c.py
	local r, f = aim(c.angle)
	local grow = back(t / GROW)
	local k = (1 / BIG) + (1 - 1 / BIG) * grow
	if t < GROW then
		-- from the hand: it starts where the devil holds it
		local u = max(0, min(1, t / GROW))
		local hx, hy = c.x0 + f * 6, c.y0 + game.DISEGNO_H * 0.45
		px, py = hx + (c.px - hx) * u, hy + (c.py - hy) * u + 14 * sin(pi * u)
	elseif not c.fired and t > JUMP then
		-- the fuse: three swells, stronger and stronger
		local u = min(1, (t - JUMP) / (WINDUP - JUMP))
		local w = max(0, sin(u * pi * 6)) * (0.6 + u)
		sx, sy = 1 + 0.07 * w, 1 - 0.05 * w
		-- the fuse sizzles on the breech
		c.spark = (c.spark or 0) + dt
		if c.spark > 0.08 then
			c.spark = 0
			local bx, by = on_cannon(c, -12 * BIG, 7 * BIG)
			impact.sign(c.fx, "fx_stella", bx, by, 9 + 5 * math.random(), c.sign.brace, "pop", math.random(0, 90))
			if math.random() < 0.4 then impact.sign(c.fx, "fx_anello_fumo", bx, by + 4, 7, c.sign.white, "drift") end
		end
	end
	if c.fired then
		local d = t - c.fired
		kick = -RECOIL * math.exp(-d * 6) * min(1, d * 30)
		sx = d < 0.08 and 0.88 or 1
		alpha = max(0, 1 - (d - FADE_FROM) / FADE)
		if alpha <= 0 then gui.set_enabled(c.cannon.node, false) end
	end
	place(c.cannon, px + kick * cos(c.angle), py + kick * sin(c.angle), r, f * k * sx, k * sy, alpha)
	-- the shells fly, spin and fade
	if c.landed then
		c.landed = c.landed + dt
		local d = c.landed
		for _, h in ipairs(c.shells) do
			local s = h.s
			s.vy = s.vy - SHELL_G * dt
			s.x, s.y, s.a = s.x + s.vx * dt, s.y + s.vy * dt, s.a + s.va * dt
			place(h, s.x, s.y, s.a, 1, 1, max(0, min(1, (SHELL_LIFE - d) / SHELL_FADE)))
		end
		if d >= SHELL_LIFE then
			for _, h in ipairs(c.shells) do gui.set_enabled(h.node, false) end
			c.landed = nil
			if not c.robot then gui.set_enabled(c.cannon.node, false) end
		end
	end
end

return M
