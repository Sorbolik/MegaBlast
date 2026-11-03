-- Battle camera: looks at a point in the world with a zoom and chases it with
-- an exponential spring (same at 60, 90 or 120 Hz). Around the map there is an
-- "untouchable" band (Sergio, 2 Nov): on the sides and at the top the camera
-- goes BAND screen pixels past the map, BELOW pixels at the bottom, so the
-- bottom of the map stays above the HUD (below it is the abyss, terreno.fp).
-- The MAPPA level shows the whole map with the bands around it.
--
-- Pure Lua: game.gui_script applies it to the GUI "mondo" node and to the
-- render view (terrain). Screen to world: x = (sx - tx) / s.
--
--   local c = camera.new(1280, 720, 1920, 1080)   -- screen, map
--   camera.viewport(c, x0, y0, x1, y1)        -- the real screen (ui/schermo.lua)
--   camera.follow(c, dt, x, y, zoom, fast)    -- every frame
--   camera.frame_on(c, dt, ax, ay, bx, by, zoom)  -- or: two points together
--   local tx, ty = camera.spostamento(c)      -- screen = world * c.s + t
--   camera.shake(c, dx, dy, force)            -- a hit: shake toward (dx, dy)
--   local ox, oy = camera.shake_frame(c, dt)  -- every frame, pixels to add

local M = {}

-- zoom levels picked with the button, the mouse wheel or the Z key
-- (MAPPA has no number: it is M.tutta, the whole map and its bands on screen)
M.LIVELLI = { 2.2, 1, 0 }
M.NAMES = { "VICINO", "MEDIO", "MAPPA" }

-- how fast the camera reaches the point (1/s): higher = stiffer
local FOLLOW, FOLLOW_FAST, ZOOM = 5, 9, 6
-- zooming out is quicker than zooming in, so the shot doesn't leave the screen
local ZOOM_OUT = 12
-- screen pixels below the map: the height of the HUD bar
M.BELOW = 120
-- screen pixels beside and above the map
M.BAND = 40

-- the center stays between a and b; if the screen is bigger than the map with its bands, halfway
local function among(v, a, b)
	if a > b then return (a + b) / 2 end
	return math.min(math.max(v, a), b)
end

local function clamp_to(c)
	local hw, hh, b = c.w / (2 * c.s), c.h / (2 * c.s), M.BAND / c.s
	c.x = among(c.x, hw - b, c.mw - hw + b)
	c.y = among(c.y, hh - M.BELOW / c.s, c.mh - hh + b)
end

-- w, h: the screen; mw, mh: the map
function M.new(w, h, mw, mh)
	local c = { w = w, h = h, cx = w / 2, cy = h / 2, mw = mw, mh = mh, x = mw / 2, y = mh / 2, s = 1, livello = 1,
		sc_x = 0, sc_y = 0, sc_f = 0, sc_t = 0, mx = 120, msu = 90, mgiu = 170 }
	return c
end

-- The real screen in game coordinates: wider than w on a 20:9 phone,
-- taller on a 4:3 tablet (ui/schermo.lua)
function M.viewport(c, x0, y0, x1, y1)
	c.w, c.h, c.cx, c.cy = x1 - x0, y1 - y0, (x0 + x1) / 2, (y0 + y1) / 2
	clamp_to(c)
end

-- screen pixels that framing two points leaves free at the edges
-- (sides, top, bottom): given by whoever draws the HUD, which sits above and below
function M.margins(c, x, above, fell)
	c.mx, c.msu, c.mgiu = x, above, fell
end

-- the zoom that shows the whole map with the bands around it (the MAPPA level,
-- and the farthest the camera goes)
function M.tutta(c)
	return math.min((c.w - 2 * M.BAND) / c.mw, (c.h - M.BAND - M.BELOW) / c.mh)
end

-- Jumps straight to the point without chasing it (match start, menus)
function M.salta(c, x, y, s)
	c.x, c.y, c.s = x, y, s
	clamp_to(c)
end

-- zoom and follow: stiffness of the two springs (1/s)
local function toward(c, dt, x, y, s, zoom, follow)
	c.s = c.s + (s - c.s) * (1 - math.exp(-dt * zoom))
	local k = 1 - math.exp(-dt * follow)
	c.x = c.x + (x - c.x) * k
	c.y = c.y + (y - c.y) * k
	clamp_to(c)
end

-- fast: for shots in flight, which would otherwise leave the screen
function M.follow(c, dt, x, y, s, fast)
	toward(c, dt, x, y, s, ZOOM, fast and FOLLOW_FAST or FOLLOW)
end

-- Keeps two points in view (the shooter and their shot): stays at zoom s if
-- they fit, otherwise zooms out just enough (at most the whole map).
-- The center sits in the part of the screen not covered by the HUD.
function M.frame_on(c, dt, ax, ay, bx, by, s)
	local x0, x1 = math.max(0, math.min(ax, bx)), math.min(c.mw, math.max(ax, bx))
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
	if m < c.s then
		c.s = math.max(M.tutta(c), m)
		clamp_to(c)
	end
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

-- never farther than M.tutta (on a small screen MEDIO can get there too)
function M.zoom(c)
	return math.max(M.LIVELLI[c.livello], M.tutta(c))
end

-- step +1 = farther, -1 = closer
function M.cambia(c, step)
	c.livello = math.min(#M.LIVELLI, math.max(1, c.livello + step))
end

-- Screen shake: the hit pushes the screen 'force' pixels in direction
-- (dx, dy), then it swings back and dies down quickly. It depends on time,
-- not on frames, so it is the same at 60, 90 or 120 Hz.
local SC_SWING, SC_DAMP, SC_END = 32, 8, 0.6

local function force_now(c)
	if c.sc_t >= SC_END then return 0 end
	return c.sc_f * math.exp(-c.sc_t * SC_DAMP)
end

-- if a stronger shake is still running, that one wins
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
	-- along the hit direction, plus a bit sideways so it doesn't look like a spring
	local a, b = f * math.cos(t), f * 0.3 * math.sin(t * 1.7)
	return c.sc_x * a - c.sc_y * b, c.sc_y * a + c.sc_x * b
end

-- the button cycles: near, medium, map, near...
function M.next_one(c)
	c.livello = c.livello % #M.LIVELLI + 1
end

return M
