-- Battle aiming (Sergio, 29 October 2026): only angle and power, never the
-- trajectory, the same for every weapon (drawn proposals at
-- https://claude.ai/artifact/NSsa8ht7XJfyJ6ZrgdxTSd). Two modes, picked from
-- the wheel (the profile's "mira" setting): the gauge, the default because
-- beginners get it right away, and the reticle. Everything is the same size on
-- screen at every zoom, like the interface:
-- - the gauge: straight out of the weapon's muzzle, always the same length,
--   with 10 ticks that fill with the team color as power grows;
-- - the reticle: a small ring at a fixed distance from the muzzle, in the
--   aiming direction, that fills with the team color as power grows (from
--   the top, clockwise), joined to the muzzle by a very thin line that shows
--   the tilt (Sergio);
-- - the tag above the head: the degrees (0° horizontal toward where you face,
--   90° up, negative down, the same right and left) and the power in percent
--   with a small bar in the team color;
-- - only in the Training lessons, as help, the whole trajectory: light dots
--   with a thin dark border at the same on-screen spacing.
-- Close-range weapons (M.MELEE: Blade, Fist, Mallet, Lunge, Bellows) have no
-- power: no gauge, reticle or tag but a "lit, minimal target" (Sergio,
-- proposals https://claude.ai/artifact/AfpFkoHGuUdS2eiZmsrpcF): a small tip
-- in the hit direction and, at the feet of whoever would be hit, a flattened
-- ring in the team color.
--
--   local m = mira.nuova()                         -- m.nodi (dots and reticle) and m.sign: to put in the world
--   mira.mirino(m, x, y, angle_deg, s, potenza, color)   -- x, y: the muzzle in the world, s the zoom
--   mira.lancetta(m, x, y, angle_deg, s, potenza, color) -- same, the other mode
--   mira.tag(m, x, y, s, gradi, potenza, color)    -- x, y: where its bottom sits, in the world
--   mira.trajectory(m, pts, n, s)                  -- pts[1..n] in the world
--   mira.punta(m, x, y, angle_deg, s, color)       -- close-range weapons: x, y the muzzle
--   mira.bersagli(m, pos, n, s, color)             -- rings at the feet of pos[1..n] = { x, y }
--   mira.via(m) / mira.trajectory_off(m)           -- turns everything off / only the trajectory
--   mira.gradi(angle_deg), mira.notch(potenza)     -- the numbers (no nodes, for the tests)
--   mira.posa(pts, n, step, max, out)              -- where the dots go (no nodes)

local ui = require "ui.ui"

local M = {}

local sqrt, floor, max, deg, cos, sin = math.sqrt, math.floor, math.max, math.deg, math.cos, math.sin

-- sizes in screen pixels (GUI at 1280 x 720)
M.STEP = 10          -- between one dot and the next
M.POINTS = 80          -- dots at most (with a long trajectory they spread out)
M.BADGE_CARD_H = 40   -- how tall the tag is with its gap
local DOT, DOT_BORDER = 4, 6
-- the reticle: how far past the muzzle it sits, its diameter, the thickness
-- of the ring and of the fill, the dot in the middle
M.RETICLE_D = 50
local RETICLE, TRACE, FULL, CENTER = 30, 3, 5, 5
-- the line from the muzzle to the reticle: thickness of the light line and of its shadow
local LINE, LINE_SHADOW = 1.5, 3.5
-- the gauge: where it starts after the muzzle, how long it is, the ticks,
-- their thickness and the gap between them, the end-of-travel tick
local LAUNCH_FROM, LANC_L, NOTCHES, NOTCH_H, NOTCH_GAP, END_H = 6, 100, 10, 4, 2.5, 14
-- power can make a micro-vibration at every tick: off by default (Sergio,
-- 29 Oct: it vibrates only when the shot becomes releasable), it will be
-- switched on from the settings (docs/impostazioni.md)
M.NOTCH = 0.05
M.VIBRATE_TICKS = false
-- close-range weapons: the tip (how far past the muzzle, length and thickness
-- of its two strokes) and the ring at the feet (width, height, thickness), at most RINGS
M.MELEE = { sword = true, punch = true, mallet = true, lunge = true, bellows = true }
local TIP_D, TIP_L, TIP_H = 26, 12, 4
local RING_W, RING_H, RING_S = 56, 18, 4
M.RINGS = 3

local LIGHT, SHADOW = ui.C.LIGHT, vmath.vector4(0, 0, 0, 0.55)
local TRACE_C = vmath.vector4(LIGHT.x, LIGHT.y, LIGHT.z, 0.35)
local LINE_C, LINE_SHADOW_C = vmath.vector4(LIGHT.x, LIGHT.y, LIGHT.z, 0.7), vmath.vector4(0, 0, 0, 0.35)
local V, S = vmath.vector3(0, 0, 0), vmath.vector3(1, 1, 1)
local E = vmath.vector3(0, 0, 0)

-- Whole degrees as the player reads them
function M.gradi(a)
	local g = deg(a)
	if math.cos(a) < 0 then g = 180 - g end
	g = (g + 180) % 360 - 180
	return floor(g + 0.5)
end

function M.notch(strength)
	return floor(strength / M.NOTCH + 1e-6)
end

-- Where the dots go along the line pts[1..n], one every step (in the world),
-- at most max: out[i] = { x, y }; returns how many there are. The line starts
-- at the muzzle, one step before pts[1].
function M.posa(pts, n, step, maxn, out)
	if n < 2 then return 0 end
	-- the muzzle: one step before the first point
	local px, py = 2 * pts[1].x - pts[2].x, 2 * pts[1].y - pts[2].y
	local lung = 0
	local x0, y0 = px, py
	for i = 1, n do
		local dx, dy = pts[i].x - x0, pts[i].y - y0
		lung = lung + sqrt(dx * dx + dy * dy)
		x0, y0 = pts[i].x, pts[i].y
	end
	if lung <= 0 then return 0 end
	step = max(step, lung / maxn)
	-- from half a step after the muzzle to the end
	local k, d, done = 0, step * 0.5, 0
	x0, y0 = px, py
	for i = 1, n do
		local x1, y1 = pts[i].x, pts[i].y
		local dx, dy = x1 - x0, y1 - y0
		local l = sqrt(dx * dx + dy * dy)
		while l > 0 and d <= done + l and k < maxn do
			local t = (d - done) / l
			k = k + 1
			local o = out[k] or {}
			o.x, o.y = x0 + dx * t, y0 + dy * t
			out[k] = o
			d = d + step
		end
		done = done + l
		x0, y0 = x1, y1
	end
	return k
end

local function disc(d, color)
	local n = ui.disco(0, 0, d, color)
	gui.set_adjust_mode(n, gui.ADJUST_FIT)
	gui.set_enabled(n, false)
	return n
end

local function root_node()
	local n = gui.new_box_node(V, V)
	gui.set_visible(n, false)
	gui.set_adjust_mode(n, gui.ADJUST_FIT)
	gui.set_enabled(n, false)
	return n
end

local function child(n, parent)
	gui.set_parent(n, parent)
	gui.set_enabled(n, true)
	return n
end

function M.nuova()
	local m = { nodi = {}, shadows = {}, lights = {}, out = {} }
	for i = 1, M.POINTS do
		m.shadows[i] = disc(DOT_BORDER, SHADOW)
		m.nodi[#m.nodi + 1] = m.shadows[i]
	end
	for i = 1, M.POINTS do
		m.lights[i] = disc(DOT, LIGHT)
		m.nodi[#m.nodi + 1] = m.lights[i]
	end

	-- the line from the muzzle to the reticle (with its shadow), then the reticle:
	-- shadow, light ring, fill, dot in the middle
	m.segments = {}
	for i, c in ipairs({ LINE_SHADOW_C, LINE_C }) do
		local n = gui.new_box_node(V, V)
		gui.set_color(n, c)
		gui.set_pivot(n, gui.PIVOT_W)
		gui.set_adjust_mode(n, gui.ADJUST_FIT)
		gui.set_enabled(n, false)
		m.segments[i] = n
		m.nodi[#m.nodi + 1] = n
	end
	m.mir = root_node()
	child(disc(RETICLE + 6, SHADOW), m.mir)
	local trace = child(disc(RETICLE, TRACE_C), m.mir)
	gui.set_inner_radius(trace, RETICLE / 2 - TRACE)
	m.full = child(disc(RETICLE + 2, LIGHT), m.mir)
	gui.set_inner_radius(m.full, RETICLE / 2 + 1 - FULL)
	child(disc(CENTER, LIGHT), m.mir)
	m.nodi[#m.nodi + 1] = m.mir

	-- the gauge: turned like the aim, with the shadow below, the ticks and the end of travel
	m.lanc = root_node()
	local function crossbar(x, w, h, color)
		local n = child(gui.new_box_node(vmath.vector3(x, 0, 0), vmath.vector3(w, h, 0)), m.lanc)
		gui.set_pivot(n, gui.PIVOT_W)
		gui.set_color(n, color)
		gui.set_adjust_mode(n, gui.ADJUST_FIT)
		return n
	end
	crossbar(LAUNCH_FROM - 1.5, LANC_L + 3, NOTCH_H + 3, SHADOW)
	crossbar(LAUNCH_FROM + LANC_L + 1, 4, END_H + 3, SHADOW)
	m.ticks = {}
	local step = LANC_L / NOTCHES
	for i = 1, NOTCHES do
		m.ticks[i] = crossbar(LAUNCH_FROM + (i - 1) * step + NOTCH_GAP / 2, step - NOTCH_GAP, NOTCH_H, TRACE_C)
	end
	crossbar(LAUNCH_FROM + LANC_L + 2, 2, END_H, LIGHT)
	m.nodi[#m.nodi + 1] = m.lanc

	-- the tip of close-range weapons: two ">" strokes meeting at the tip
	m.punta, m.tip_lights = root_node(), {}
	for _, c in ipairs({ SHADOW, LIGHT }) do
		local shadow = c == SHADOW and 2 or 0
		for _, a in ipairs({ 40, -40 }) do
			local n = child(gui.new_box_node(V, vmath.vector3(TIP_L + shadow, TIP_H + shadow, 0)), m.punta)
			gui.set_pivot(n, gui.PIVOT_E)
			gui.set_color(n, c)
			gui.set_adjust_mode(n, gui.ADJUST_FIT)
			E.z = a
			gui.set_euler(n, E)
			if c == LIGHT then m.tip_lights[#m.tip_lights + 1] = n end
		end
	end
	m.nodi[#m.nodi + 1] = m.punta
	-- the rings at the feet of whoever would be hit: shadow and color
	m.anelli, m.rings_c = {}, {}
	for i = 1, M.RINGS do
		local r = root_node()
		local shadow = child(ui.disco(0, 0, 1, SHADOW), r)
		gui.set_size(shadow, vmath.vector3(RING_W + 4, RING_H + 4, 0))
		gui.set_inner_radius(shadow, RING_W / 2 - RING_S - 2)
		local c = child(ui.disco(0, 0, 1, LIGHT), r)
		gui.set_size(c, vmath.vector3(RING_W, RING_H, 0))
		gui.set_inner_radius(c, RING_W / 2 - RING_S)
		for _, n in ipairs({ shadow, c }) do gui.set_adjust_mode(n, gui.ADJUST_FIT) end
		m.anelli[i], m.rings_c[i] = r, c
		m.nodi[#m.nodi + 1] = r
	end

	-- the tag: charcoal with a light border, degrees on the left, power on the right
	local c = {}
	c.radice = root_node()
	c.fondo, c.bordo = ui.pannello(0, 0, 120, 34, c.radice)
	gui.set_color(c.fondo, vmath.vector4(ui.C.PANEL.x, ui.C.PANEL.y, ui.C.PANEL.z, 0.92))
	gui.set_color(c.bordo, LIGHT)
	c.riga = gui.new_box_node(vmath.vector3(2, 0, 0), vmath.vector3(1.5, 22, 0))
	gui.set_color(c.riga, ui.C.LINE)
	gui.set_parent(c.riga, c.radice)
	c.bar = ui.bar(32, -10, 40, 4, LIGHT, c.radice)
	c.gradi = ui.titolo("", -28, 1, 0.6, LIGHT, c.radice)
	c.potenza = ui.titolo("", 32, 4, 0.42, LIGHT, c.radice)
	for _, n in ipairs({ c.fondo, c.bordo, c.riga, c.bar.nodo, c.bar.full, c.gradi, c.potenza }) do
		gui.set_adjust_mode(n, gui.ADJUST_FIT)
	end
	m.c = c
	m.sign = c.radice
	return m
end

local function move(n, x, y, scale)
	V.x, V.y, V.z = x, y, 0
	gui.set_position(n, V)
	S.x, S.y = scale, scale
	gui.set_scale(n, S)
end

function M.trajectory(m, pts, n, s)
	local k = M.posa(pts, n, M.STEP / s, M.POINTS, m.out)
	local scale = 1 / s
	for i = 1, M.POINTS do
		local on = i <= k
		gui.set_enabled(m.shadows[i], on)
		gui.set_enabled(m.lights[i], on)
		if on then
			local o = m.out[i]
			move(m.shadows[i], o.x, o.y, scale)
			move(m.lights[i], o.x, o.y, scale)
		end
	end
end

function M.mirino(m, x, y, angle_deg, s, strength, color)
	local d = M.RETICLE_D / s
	move(m.mir, x + cos(angle_deg) * d, y + sin(angle_deg) * d, 1 / s)
	-- the pie fills counterclockwise from the right: turned like this it starts
	-- from the top and grows clockwise
	local f = 360 * math.min(1, math.max(0, strength))
	gui.set_fill_angle(m.full, f)
	E.z = 90 - f
	gui.set_euler(m.full, E)
	gui.set_color(m.full, color)
	gui.set_enabled(m.mir, true)
	gui.set_enabled(m.lanc, false)
	gui.set_enabled(m.punta, false)
	-- the line starts at the muzzle and stops where the ring begins
	E.z = deg(angle_deg)
	for i, n in ipairs(m.segments) do
		V.x, V.y, V.z = x, y, 0
		gui.set_position(n, V)
		V.x, V.y = (M.RETICLE_D - RETICLE / 2 - 1) / s, (i == 1 and LINE_SHADOW or LINE) / s
		gui.set_size(n, V)
		gui.set_euler(n, E)
		gui.set_enabled(n, true)
	end
end

function M.lancetta(m, x, y, angle_deg, s, strength, color)
	move(m.lanc, x, y, 1 / s)
	E.z = deg(angle_deg)
	gui.set_euler(m.lanc, E)
	-- ticks full up to the power (the first lights up at once)
	local full_fs = math.max(1, math.floor(strength * NOTCHES + 0.5))
	for i, n in ipairs(m.ticks) do gui.set_color(n, i <= full_fs and color or TRACE_C) end
	gui.set_enabled(m.lanc, true)
	gui.set_enabled(m.mir, false)
	gui.set_enabled(m.punta, false)
	for _, n in ipairs(m.segments) do gui.set_enabled(n, false) end
end

function M.punta(m, x, y, angle_deg, s, color)
	local d = TIP_D / s
	move(m.punta, x + cos(angle_deg) * d, y + sin(angle_deg) * d, 1 / s)
	E.z = deg(angle_deg)
	gui.set_euler(m.punta, E)
	for _, n in ipairs(m.tip_lights) do gui.set_color(n, color) end
	gui.set_enabled(m.punta, true)
	gui.set_enabled(m.lanc, false)
	gui.set_enabled(m.mir, false)
	for _, n in ipairs(m.segments) do gui.set_enabled(n, false) end
	gui.set_enabled(m.c.radice, false)
end

function M.bersagli(m, pos, n, s, color)
	for i = 1, M.RINGS do
		local on = i <= n
		gui.set_enabled(m.anelli[i], on)
		if on then
			move(m.anelli[i], pos[i].x, pos[i].y, 1 / s)
			gui.set_color(m.rings_c[i], color)
		end
	end
end

function M.tag(m, x, y, s, degrees, strength, color)
	local c = m.c
	local txt = degrees .. "°"
	if c.testo ~= txt then
		gui.set_text(c.gradi, txt)
		c.testo = txt
	end
	local p = floor(strength * 100 + 0.5)
	if c.p ~= p then
		gui.set_text(c.potenza, p .. "%")
		ui.bar_value(c.bar, strength)
		c.p = p
	end
	gui.set_color(c.bar.full, color)
	-- the bottom of the tag at (x, y), 17 pixels below the center
	move(c.radice, x, y + 17 / s, 1 / s)
	gui.set_enabled(c.radice, true)
end

function M.trajectory_off(m)
	for i = 1, M.POINTS do
		gui.set_enabled(m.shadows[i], false)
		gui.set_enabled(m.lights[i], false)
	end
end

function M.via(m)
	M.trajectory_off(m)
	gui.set_enabled(m.mir, false)
	gui.set_enabled(m.lanc, false)
	gui.set_enabled(m.punta, false)
	for _, n in ipairs(m.segments) do gui.set_enabled(n, false) end
	gui.set_enabled(m.c.radice, false)
	M.bersagli(m, nil, 0)
end

return M
