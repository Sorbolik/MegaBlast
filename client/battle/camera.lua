-- Battle camera: looks at a point in the world with a zoom and chases it with
-- an exponential spring (same at 60, 90 or 120 Hz).
--
-- The zoom is continuous (Sergio, 3 Nov: «niente tre livelli, uno zoom a piacere»):
-- c.f goes from 0 (the farthest zoom, the whole play space on screen) to 1
-- (NEAR). The play space comes from the match (M.space): from the lowest floor
-- to the highest platform, between the HUD at the top and the one at the
-- bottom. The character always stays in the center, even near the edges of
-- the map (there the painted background goes on); in the last stretch of the
-- zoom the center slides gently onto the play space, and at the farthest zoom
-- it frames all of it.
--
-- Pure Lua: game.gui_script applies it to the GUI's "mondo" node and to the
-- render's view (terrain). From screen to world: x = (sx - tx) / s.
--
--   local c = camera.new(1280, 720, 1920, 1080)   -- screen, map
--   camera.viewport(c, x0, y0, x1, y1)        -- the real screen (ui/screen.lua)
--   camera.space(c, x0, y0, x1, y1)           -- the play space (nil = the map)
--   camera.from_terrain(c, terrain, above)    -- or measured on the terrain
--   camera.follow(c, dt, x, y, zoom, fast)    -- every frame
--   camera.frame_on(c, dt, ax, ay, bx, by, zoom)  -- or: two points together
--   camera.zoom(c)                            -- the chosen zoom (c.f) now
--   camera.trascina(c, f) / camera.passo(c, d) / camera.toggle(c)
--   local tx, ty = camera.spostamento(c)      -- screen = world * c.s + t
--   camera.shake(c, dx, dy, force)            -- a hit: shake toward (dx, dy)
--   local ox, oy = camera.shake_frame(c, dt)  -- every frame, pixels to add

local M = {}

-- the nearest zoom (screen units per world unit)
M.NEAR = 2.2
-- the old levels (imposta zoom N in the scenarios, the missions that widen):
-- 1 near, 2 medium (zoom 1), 3 the farthest zoom
local MEDIUM = 1
-- in the last TOWARD_SPACE of c.f the center slides from the character to the play space
local TOWARD_SPACE = 0.3

-- how fast the camera reaches the point (1/s): higher = stiffer
local FOLLOW, FOLLOW_FAST, ZOOM = 5, 9, 6
-- zooming out is quicker than zooming in, so the shot doesn't escape the screen
local ZOOM_OUT = 12
-- screen pixels below the play space (the HUD bar), above it (the points)
-- and on the sides. With some margin past the HUD (Sergio, 3 Nov: at the
-- farthest zoom the buttons sometimes covered the characters): below, the bar
-- and the sticks; on the sides, the columns of round buttons that rise above the bar
M.BELOW = 150
M.ABOVE = 85
M.LATO = 44

local function clamp(v, a, b)
	return math.min(math.max(v, a), b)
end

-- w, h: the screen; mw, mh: the map; margin: the terrain beside it (platforms
-- jutting out of the walls); reach: how far sideways a point can still be
-- framed (where you die)
function M.new(w, h, mw, mh, margin, reach)
	local c = { w = w, h = h, cx = w / 2, cy = h / 2, mw = mw, mh = mh, x = mw / 2, y = mh / 2, s = 1,
		margin = margin or 0, reach = reach or 0,
		f = 1, f_before = nil, sc_x = 0, sc_y = 0, sc_f = 0, sc_t = 0, mx = 120, msu = 90, mgiu = 170 }
	return c
end

-- The real screen in game coordinates: wider than w on a 20:9 phone,
-- taller on a 4:3 tablet (ui/screen.lua)
function M.viewport(c, x0, y0, x1, y1)
	c.w, c.h, c.cx, c.cy = x1 - x0, y1 - y0, (x0 + x1) / 2, (y0 + y1) / 2
end

-- the play space in world units (nil: the whole map)
function M.space(c, x0, y0, x1, y1)
	c.space = x0 and { x0 = x0, y0 = y0, x1 = x1, y1 = y1 } or nil
	if c.level_n then c.requested_level = c.level_n end
end

-- The play space measured on the terrain, at the start of a match: from the
-- lowest floor (those under a platform too: you walk on them) to the highest
-- surface, with room above it (over_it, world units) for a character and its
-- plate. One column every two cells: a surface is a full cell with air above it
local BELOW_TERRAIN, SIDES = 12, 10
function M.from_terrain(c, t, over_it)
	local x0, x1, low, high
	local w, data = t.w, t.data
	for cx = 1, w - 2, 2 do
		for cy = 0, t.h - 2 do
			local i = cy * w + cx + 1
			if data[i] ~= 0 and data[i + w] == 0 then
				local y = (cy + 1) * t.cell
				local x = (cx - t.ox) * t.cell
				x0, x1 = x0 or x, x
				low, high = math.min(low or y, y), math.max(high or y, y)
			end
		end
	end
	if not x0 then return M.space(c, nil) end
	M.space(c, math.max(-c.margin, x0 - SIDES), math.max(0, low - BELOW_TERRAIN),
		math.min(c.mw + c.margin, x1 + SIDES), math.min(c.mh, high + over_it))
end

-- screen pixels that framing two points leaves free at the edges (sides,
-- top, bottom): given by whoever draws the HUD, which sits above and below
function M.margins(c, x, above, fell)
	c.mx, c.msu, c.mgiu = x, above, fell
end

local function bounds(c, whole_map)
	local sp = not whole_map and c.space
	if sp then return sp.x0, sp.y0, sp.x1, sp.y1 end
	return -c.margin, 0, c.mw + c.margin, c.mh
end

-- the zoom at which the play space (or, with whole_map, the map) fits between
-- the HUD at the top, the one at the bottom and the sides: the farthest the camera goes
function M.tutta(c, whole_map)
	local x0, y0, x1, y1 = bounds(c, whole_map)
	return math.min((c.w - 2 * M.LATO) / (x1 - x0), (c.h - M.BELOW - M.ABOVE) / (y1 - y0))
end

-- where the camera looks at zoom s to have the play space in the middle between the HUD
local function space_center(c, s, whole_map)
	local x0, y0, x1, y1 = bounds(c, whole_map)
	return (x0 + x1) / 2, (y0 + y1) / 2 - (M.BELOW - M.ABOVE) / (2 * s)
end

-- c.f (0 the farthest zoom, 1 NEAR) to zoom, and back: in between it goes at an
-- even pace (logarithmic), so every stretch of the finger changes the zoom by the same share
local function from_f(c, f)
	local t = M.tutta(c)
	if t >= M.NEAR then return t end
	return math.exp(math.log(t) + (math.log(M.NEAR) - math.log(t)) * f)
end

local function to_f(c, s)
	local t = M.tutta(c)
	if t >= M.NEAR then return 1 end
	return clamp((math.log(s) - math.log(t)) / (math.log(M.NEAR) - math.log(t)), 0, 1)
end

-- the old levels: 1 near, 2 medium, 3 the farthest zoom. The medium one is
-- computed when needed, because it depends on the screen and the map.
-- Until the player changes it, the level holds for every match: every new
-- play space recomputes it
function M.livello(c, n)
	c.level_n, c.requested_level = n, n
end

local function resolve(c)
	local n = c.requested_level
	if not n then return end
	c.requested_level = nil
	c.f = n <= 1 and 1 or (n >= 3 and 0 or to_f(c, MEDIUM))
end

-- the chosen zoom, now
function M.zoom(c)
	resolve(c)
	return from_f(c, c.f)
end

-- dragging the button (Z1): the new c.f
function M.trascina(c, f)
	resolve(c)
	c.f, c.level_n = clamp(f, 0, 1), nil
end

-- the wheel, the keys: positive d is closer
function M.passo(c, d)
	M.trascina(c, c.f + d)
end

-- a tap on the button: from the chosen zoom to the farthest and back
function M.toggle(c)
	resolve(c)
	c.level_n = nil
	if c.f > 0.02 then
		c.f_before, c.f = c.f, 0
	else
		c.f = c.f_before or to_f(c, MEDIUM)
	end
end

-- a mission wants to see at least up to level n: the zoom widens
function M.allarga(c, n)
	resolve(c)
	local f = n <= 1 and 1 or (n >= 3 and 0 or to_f(c, MEDIUM))
	if f < c.f then c.f, c.level_n = f, nil end
end

-- Goes straight to the point, without chasing it (start of the match, menu)
function M.salta(c, x, y, s)
	c.s = s
	c.x, c.y = x, y
end

-- The opening shot of a level (ui/intro.lua): k 0 is the nearest zoom on (x, y),
-- k 1 the farthest zoom on the play space, in between at an even pace
function M.apertura(c, k, x, y)
	local t = M.tutta(c)
	local s = M.NEAR
	if t < s then s = math.exp(math.log(s) + (math.log(t) - math.log(s)) * k) end
	local bx, by = space_center(c, s)
	local w = k * k * (3 - 2 * k)
	M.salta(c, x + (bx - x) * w, y + (by - y) * w, s)
end

-- how far the center goes toward the play space: 0 while the chosen zoom is
-- above TOWARD_SPACE, 1 at the farthest zoom
local function toward_space(c)
	if c.f >= TOWARD_SPACE then return 0 end
	local k = 1 - c.f / TOWARD_SPACE
	return k * k * (3 - 2 * k)
end

-- zoom and follow: stiffness of the two springs (1/s)
local function toward(c, dt, x, y, s, zoom, follow)
	c.s = c.s + (s - c.s) * (1 - math.exp(-dt * zoom))
	local w = toward_space(c)
	if w > 0 then
		-- toward the center of the play space, but the followed point stays on
		-- screen (a crater below the lowest floor, a shot on the edge)
		local bx, by = space_center(c, c.s)
		local px, py = x, y
		x, y = x + (bx - x) * w, y + (by - y) * w
		local s = c.s
		x = clamp(x, px - (c.w / 2 - M.LATO) / s, px + (c.w / 2 - M.LATO) / s)
		y = clamp(y, py - (c.h / 2 - M.ABOVE) / s, py + (c.h / 2 - M.BELOW) / s)
	end
	local k = 1 - math.exp(-dt * follow)
	c.x = c.x + (x - c.x) * k
	c.y = c.y + (y - c.y) * k
end

-- fast: for shots in flight, which would otherwise escape the screen
function M.follow(c, dt, x, y, s, fast)
	toward(c, dt, x, y, s, ZOOM, fast and FOLLOW_FAST or FOLLOW)
end

-- In the menu: the whole map, still, in the middle
function M.mappa(c, dt)
	local s = M.tutta(c, true)
	local x, y = space_center(c, s, true)
	c.s = c.s + (s - c.s) * (1 - math.exp(-dt * ZOOM))
	local k = 1 - math.exp(-dt * FOLLOW)
	c.x, c.y = c.x + (x - c.x) * k, c.y + (y - c.y) * k
end

-- Keeps two points in view (the shooter and their shot): stays at zoom s if
-- they fit, otherwise zooms out just enough (at most the farthest zoom).
-- The center sits in the part of the screen not covered by the HUD.
function M.frame_on(c, dt, ax, ay, bx, by, s)
	local x0, x1 = math.max(-c.reach, math.min(ax, bx)), math.min(c.mw + c.reach, math.max(ax, bx))
	local y0, y1 = math.max(0, math.min(ay, by)), math.min(c.mh, math.max(ay, by))
	local needs = math.min((c.w - 2 * c.mx) / math.max(1, x1 - x0),
		(c.h - c.msu - c.mgiu) / math.max(1, y1 - y0))
	s = math.max(M.tutta(c), math.min(s, needs))
	toward(c, dt, (x0 + x1) / 2, (y0 + y1) / 2 - (c.mgiu - c.msu) / (2 * c.s), s,
		s < c.s and ZOOM_OUT or ZOOM, FOLLOW_FAST)
	-- the springs lag behind: if a point is about to leave, zoom out at once
	local m = c.s
	for i = 1, 2 do
		local dx, dy = math.abs((i == 1 and x0 or x1) - c.x), (i == 1 and y0 or y1) - c.y
		if dx > 0 then m = math.min(m, (c.w / 2 - c.mx) / dx) end
		if dy > 0 then m = math.min(m, (c.h / 2 - c.msu) / dy) end
		if dy < 0 then m = math.min(m, (c.h / 2 - c.mgiu) / -dy) end
	end
	if m < c.s then c.s = math.max(M.tutta(c), m) end
end

function M.spostamento(c)
	return c.cx - c.x * c.s, c.cy - c.y * c.s
end

function M.to_world(c, sx, sy)
	local tx, ty = M.spostamento(c)
	return (sx - tx) / c.s, (sy - ty) / c.s
end

function M.to_screen(c, x, y)
	local tx, ty = M.spostamento(c)
	return x * c.s + tx, y * c.s + ty
end

-- Screen shake: the hit pushes the screen 'force' pixels in direction
-- (dx, dy), then it swings back and dies down quickly. It depends on time,
-- not on frames, so it is the same at 60, 90 or 120 Hz.
local SC_SWING, SC_DAMP, SC_END = 32, 8, 0.6

local function force_now(c)
	if c.sc_t >= SC_END then return 0 end
	return c.sc_f * math.exp(-c.sc_t * SC_DAMP)
end

-- if a stronger shake is still going, that one wins
function M.shake(c, dx, dy, force)
	if force < force_now(c) then return end
	local l = math.sqrt(dx * dx + dy * dy)
	if l < 1e-6 then dx, dy, l = 0, -1, 1 end
	c.sc_x, c.sc_y, c.sc_f, c.sc_t = dx / l, dy / l, force, 0
end

function M.shake_frame(c, dt)
	c.sc_t = c.sc_t + dt
	local f = force_now(c)
	if f == 0 then return 0, 0 end
	local t = c.sc_t * SC_SWING
	-- along the hit direction, plus a little sideways so it doesn't look like a spring
	local a, b = f * math.cos(t), f * 0.3 * math.sin(t * 1.7)
	return c.sc_x * a - c.sc_y * b, c.sc_y * a + c.sc_x * b
end

return M
