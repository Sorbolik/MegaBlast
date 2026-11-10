-- Impact effects (game feel): explosion, sparks on whoever is hit, the damage
-- number, the embers a shot sheds in flight. Everything is a particle: a soft
-- halo (battle.atlas "bagliore") in a pool of nodes created once and reused in
-- rotation, so during the match nothing is created and nothing allocates per
-- frame. Client only: it reads events and never touches the simulation.
--
--   local s = impact.new()                  -- once, with the other nodes
--   impact.nodes(s)                         -- the nodes in drawing order
--   impact.explosion(s, x, y, r)            -- an explosion of radius r
--   impact.sparks(s, x, y, dx, dy, tier)    -- a hit, thrown toward (dx, dy)
--   impact.trail(s, dt, x, y, rate)         -- the embers a shot sheds (every frame)
--   impact.update(s, dt)                    -- every frame
--   impact.tier(damage)                     -- 1 small, 2 medium, 3 big
--   impact.reset(s)                         -- new match
local M = {}

local rand, cos, sin, sqrt, exp, min, max = math.random, math.cos, math.sin, math.sqrt, math.exp, math.min, math.max

-- the world's gravity (same as the debris'), in world units per second squared
local GRAVITY = 900

-- the size of the pool of each kind: smoke below, fire and sparks above
local SMOKE_N, FX_N = 20, 90

local FIRE0 = { 1.0, 0.95, 0.7 }    -- the core of the fire: almost white
local FIRE1 = { 1.0, 0.35, 0.05 }   -- cooling: orange, then red
local SPARK = { 1.0, 0.8, 0.4 }
local SMOKE = { 0.12, 0.1, 0.11 }

-- damage tiers (points of life lost in one hit)
local TIER2, TIER3 = 14, 32
function M.tier(damage)
	return damage >= TIER3 and 3 or (damage >= TIER2 and 2 or 1)
end

local function halo(add)
	local n = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(1, 1, 0))
	gui.set_adjust_mode(n, gui.ADJUST_FIT)
	gui.set_texture(n, "battaglia")
	gui.play_flipbook(n, "bagliore")
	gui.set_blend_mode(n, add and gui.BLEND_ADD or gui.BLEND_ALPHA)
	gui.set_enabled(n, false)
	return n
end

local function pool(count, add)
	local p = { n = count, i = 0, live = 0, list = {} }
	for k = 1, count do
		p.list[k] = {
			node = halo(add), on = false, x = 0, y = 0, vx = 0, vy = 0, t = 0, life = 1,
			s0 = 1, s1 = 1, grav = 0, drag = 0, a = 1,
			c0r = 1, c0g = 1, c0b = 1, c1r = 1, c1g = 1, c1b = 1,
			col = vmath.vector4(1, 1, 1, 1), size = vmath.vector3(1, 1, 0), pos = vmath.vector3(0, 0, 0),
		}
	end
	return p
end

-- takes the next particle of the pool (the oldest one if all are flying)
local function take(p)
	p.i = p.i % p.n + 1
	local q = p.list[p.i]
	if not q.on then p.live = p.live + 1 end
	q.on, q.t = true, 0
	gui.set_enabled(q.node, true)
	return q
end

local function fill(q, x, y, vx, vy, life, s0, s1, c0, c1, a, grav, drag)
	q.x, q.y, q.vx, q.vy, q.life, q.s0, q.s1, q.a, q.grav, q.drag = x, y, vx, vy, life, s0, s1, a, grav or 0, drag or 0
	q.c0r, q.c0g, q.c0b, q.c1r, q.c1g, q.c1b = c0[1], c0[2], c0[3], c1[1], c1[2], c1[3]
end

function M.new()
	local s = { smoke = pool(SMOKE_N, false), fx = pool(FX_N, true), ember_t = 0 }
	return s
end

function M.nodes(s)
	local out = {}
	for _, q in ipairs(s.smoke.list) do out[#out + 1] = q.node end
	for _, q in ipairs(s.fx.list) do out[#out + 1] = q.node end
	return out
end

function M.reset(s)
	for _, p in ipairs({ s.smoke, s.fx }) do
		for _, q in ipairs(p.list) do q.on = false; gui.set_enabled(q.node, false) end
		p.live = 0
	end
end

-- An explosion: a fireball that blooms and cools, sparks that fly out and fall,
-- smoke that rises. Bigger radius, more of everything but with a ceiling, so a
-- big one doesn't swallow the screen.
function M.explosion(s, x, y, r)
	local big = min(1.6, max(0.6, r / 30))
	-- the fireball: a quick white flash and a few overlapping blooms
	fill(take(s.fx), x, y, 0, 0, 0.16, r * 2.2, r * 3.4, FIRE0, FIRE0, 1)
	for _ = 1, 4 do
		local a, d = rand() * 6.283, rand() * r * 0.45
		fill(take(s.fx), x + cos(a) * d, y + sin(a) * d, cos(a) * r * 0.5, sin(a) * r * 0.5 + r * 0.3,
			0.32 + rand() * 0.18, r * 0.9, r * (2.4 + rand() * 0.8), FIRE0, FIRE1, 0.95, 0, 3)
	end
	-- sparks: quick, they fly up and out and fall back
	for _ = 1, math.floor(10 * big) do
		local a = math.pi / 2 + (rand() * 2 - 1) * 1.5
		local v = r * (4 + rand() * 6)
		fill(take(s.fx), x, y, cos(a) * v, sin(a) * v, 0.5 + rand() * 0.5, r * 0.28, r * 0.06, SPARK, FIRE1, 1, GRAVITY, 1.2)
	end
	-- smoke: dark halos that grow while they rise and fade
	for _ = 1, math.floor(4 * big) do
		local a, d = rand() * 6.283, rand() * r * 0.7
		fill(take(s.smoke), x + cos(a) * d, y + sin(a) * d, cos(a) * r * 0.3, r * (0.6 + rand() * 0.8),
			0.8 + rand() * 0.4, r * 1.0, r * (2.2 + rand()), SMOKE, SMOKE, 0.55, 0, 1.5)
	end
end

-- Giano's swap, at each of the two spots: a ring-like bloom in the color of whoever
-- arrives (c = { r, g, b }) and gold sparks flying out
local GOLD = { 1, 0.8, 0.25 }
function M.swap(s, x, y, c)
	fill(take(s.fx), x, y, 0, 0, 0.45, 24, 200, c, c, 0.9)
	fill(take(s.fx), x, y, 0, 0, 0.14, 30, 90, FIRE0, FIRE0, 0.9)
	for k = 1, 8 do
		local a = k / 8 * 6.283 + rand() * 0.4
		fill(take(s.fx), x, y, cos(a) * 170, sin(a) * 170, 0.4 + rand() * 0.2, 9, 2, GOLD, c, 1, 0, 2.5)
	end
end

-- Sparks on whoever is hit: they leave the point of impact along the push (dx, dy
-- need not be normalized). Tier 1 a handful, tier 3 a burst with a white flash.
function M.sparks(s, x, y, dx, dy, tier)
	local l = sqrt(dx * dx + dy * dy)
	if l < 1e-6 then dx, dy, l = 0, 1, 1 end
	local base = math.atan2(dy / l, dx / l)
	for _ = 1, 4 + tier * 3 do
		local a = base + (rand() * 2 - 1) * 0.9
		local v = 90 + rand() * 120 + tier * 40
		fill(take(s.fx), x, y, cos(a) * v, sin(a) * v, 0.3 + rand() * 0.3, 7 + tier * 2, 1.5,
			tier == 3 and FIRE0 or SPARK, FIRE1, 1, GRAVITY * 0.6, 1.5)
	end
	if tier >= 2 then
		fill(take(s.fx), x, y, 0, 0, 0.12, 20 + tier * 10, 50 + tier * 12, FIRE0, FIRE0, 0.9)
	end
end

-- The embers a shot sheds in flight (rate per second, the same at any frame
-- rate): small, they fall behind slowly and go out.
function M.trail(s, dt, x, y, rate)
	s.ember_t = min(3, s.ember_t + dt * rate)
	while s.ember_t >= 1 do
		s.ember_t = s.ember_t - 1
		local a = rand() * 6.283
		fill(take(s.fx), x + cos(a) * 3, y + sin(a) * 3, cos(a) * 25, sin(a) * 25 - 10,
			0.3 + rand() * 0.25, 6 + rand() * 4, 1, SPARK, FIRE1, 0.9, GRAVITY * 0.15, 2)
	end
end

local function advance(p, dt)
	if p.live == 0 then return end
	for k = 1, p.n do
		local q = p.list[k]
		if q.on then
			q.t = q.t + dt
			if q.t >= q.life then
				q.on = false
				p.live = p.live - 1
				gui.set_enabled(q.node, false)
			else
				local u = q.t / q.life
				q.vy = q.vy - q.grav * dt
				local d = exp(-q.drag * dt)
				q.vx, q.vy = q.vx * d, q.vy * d
				q.x, q.y = q.x + q.vx * dt, q.y + q.vy * dt
				local sz = q.s0 + (q.s1 - q.s0) * u
				q.size.x, q.size.y = sz, sz
				q.pos.x, q.pos.y = q.x, q.y
				-- the fire cools toward the second color; the alpha holds, then falls
				q.col.x, q.col.y, q.col.z = q.c0r + (q.c1r - q.c0r) * u, q.c0g + (q.c1g - q.c0g) * u, q.c0b + (q.c1b - q.c0b) * u
				q.col.w = q.a * (u < 0.35 and 1 or (1 - u) / 0.65)
				gui.set_position(q.node, q.pos)
				gui.set_size(q.node, q.size)
				gui.set_color(q.node, q.col)
			end
		end
	end
end

function M.update(s, dt)
	advance(s.smoke, dt)
	advance(s.fx, dt)
end

return M
