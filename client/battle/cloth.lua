-- Cloth: a chain of points with weight, simulated (Verlet), that a soft piece
-- of the devil hangs on (the cape, battle/scoria.lua). The first point is
-- pinned where the piece is attached (the shoulders), the others follow it
-- with their inertia: running, jumping, falling, the weapon's recoil and the
-- hits move them by themselves, without poses. They don't go into the body
-- (circles) or into the terrain, and they keep their length. Graphics only:
-- the game's simulation doesn't know it (math.random is not used either).
--
--   local cloth = require "battle.cloth"
--   local c = cloth.new(6, 14)              -- 6 points, 14 world units apart
--   cloth.reset(c, x, y)                     -- hanging straight down from (x, y)
--   cloth.step(c, dt, x, y, opts)            -- the pin moved to (x, y)
--   cloth.push(c, vx, vy)                    -- a blow (world units per second)
--
-- opts: gravity (world units/s^2, downward), drag (1/s), bend (radians a joint
-- bends at most), from, to (the angles, radians, the first segment stays
-- between: so it never flips over where it is attached), circles ({ x, y, r,
-- ... } world, flat), solid(x, y) (terrain)

local M = {}

local sqrt, min, max, ceil, atan2, cos, sin = math.sqrt, math.min, math.max, math.ceil, math.atan2 or math.atan, math.cos, math.sin

-- the simulation step (s): fixed, so the cloth behaves the same at every frame rate
M.STEP = 1 / 120
-- how many times per step the lengths are put back
M.ITERATIONS = 4
-- a jump of the pin longer than this many cloth lengths is a teleport: the
-- cloth starts again hanging
M.TELEPORT = 1.5

function M.new(n, seg)
	local c = { n = n, seg = seg, x = {}, y = {}, ox = {}, oy = {}, t = 0 }
	for i = 1, n do c.x[i], c.y[i], c.ox[i], c.oy[i] = 0, -(i - 1) * seg, 0, -(i - 1) * seg end
	return c
end

-- hanging still from (x, y), slightly back (dir: -1 back is left, 1 right)
function M.reset(c, x, y, dir)
	local a = -math.pi / 2 + 0.12 * (dir or 0)
	for i = 1, c.n do
		local d = (i - 1) * c.seg
		c.x[i], c.y[i] = x + cos(a) * d, y + sin(a) * d
		c.ox[i], c.oy[i] = c.x[i], c.y[i]
	end
	c.ax, c.ay = x, y
end

-- a blow to every point, more toward the free end
function M.push(c, vx, vy)
	for i = 2, c.n do
		local w = (i - 1) / (c.n - 1)
		c.ox[i] = c.ox[i] - vx * M.STEP * w
		c.oy[i] = c.oy[i] - vy * M.STEP * w
	end
end

local function circles(c, list)
	if not list then return end
	for i = 2, c.n do
		for j = 1, #list, 3 do
			local dx, dy, r = c.x[i] - list[j], c.y[i] - list[j + 1], list[j + 2]
			local d2 = dx * dx + dy * dy
			if d2 < r * r then
				local d = sqrt(d2)
				if d < 1e-6 then dx, dy, d = -1, 0, 1 end
				c.x[i], c.y[i] = list[j] + dx / d * r, list[j + 1] + dy / d * r
			end
		end
	end
end

-- the lengths, and every joint bends at most `bend` from the segment before
local function constraints(c, bend, from, to)
	local x, y, seg = c.x, c.y, c.seg
	for i = 2, c.n do
		local dx, dy = x[i] - x[i - 1], y[i] - y[i - 1]
		local d = sqrt(dx * dx + dy * dy)
		if d < 1e-6 then dx, dy, d = 0, -1, 1 end
		local a = atan2(dy, dx)
		if i == 2 and from then
			-- the first segment: between from and to (angles measured from from, going up)
			local da = (a - from) % (2 * math.pi)
			local span = (to - from) % (2 * math.pi)
			if da > span then
				-- outside: to the nearer end
				if da - span < 2 * math.pi - da then a = to else a = from end
			end
		elseif i > 2 and bend then
			local pa = atan2(y[i - 1] - y[i - 2], x[i - 1] - x[i - 2])
			local da = (a - pa + math.pi) % (2 * math.pi) - math.pi
			if da > bend then a = pa + bend elseif da < -bend then a = pa - bend end
		end
		-- the point moves, the one before stays: from the pin to the end
		x[i], y[i] = x[i - 1] + cos(a) * seg, y[i - 1] + sin(a) * seg
	end
end

function M.step(c, dt, ax, ay, opts)
	local lx, ly = c.ax or ax, c.ay or ay
	local jx, jy = ax - lx, ay - ly
	if jx * jx + jy * jy > (M.TELEPORT * c.seg * (c.n - 1)) ^ 2 or not c.ax then
		M.reset(c, ax, ay, opts.dir)
		return
	end
	c.ax, c.ay = ax, ay
	c.t = c.t + dt
	local n = max(1, ceil(c.t / M.STEP - 1e-6))
	n = min(n, 12)
	c.t = max(0, c.t - n * M.STEP)
	local h = M.STEP
	local g, keep = (opts.gravity or 0) * h * h, 1 - min(1, (opts.drag or 0) * h)
	local wind_x, wind_y = (opts.wind_x or 0) * h * h, (opts.wind_y or 0) * h * h
	local x, y, ox, oy = c.x, c.y, c.ox, c.oy
	for s = 1, n do
		-- the pin goes from where it was to where it is, step by step
		local f = s / n
		x[1], y[1] = lx + jx * f, ly + jy * f
		ox[1], oy[1] = x[1], y[1]
		for i = 2, c.n do
			local vx, vy = (x[i] - ox[i]) * keep, (y[i] - oy[i]) * keep
			ox[i], oy[i] = x[i], y[i]
			x[i], y[i] = x[i] + vx + wind_x, y[i] + vy - g + wind_y
		end
		for _ = 1, M.ITERATIONS do
			constraints(c, opts.bend, opts.from, opts.to)
			circles(c, opts.circles)
		end
		-- the terrain: a point that went in goes back where it was (and slows down)
		if opts.solid then
			for i = 2, c.n do
				if opts.solid(x[i], y[i]) then
					x[i], y[i] = ox[i], oy[i]
				end
			end
		end
	end
end

return M
