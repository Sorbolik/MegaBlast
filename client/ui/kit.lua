-- The "Raggi" interface kit (Sergio, 10 Nov; Figma "MegaBlast · Interfaccia",
-- page 3): the game world darkened behind, rays from the character, an ember
-- seam at the bottom and straight parallelogram plates with a solid offset
-- shadow. One function per category, each with its own shape:
--   plate / sand   buttons (dark plate, or the sand one for the name)
--   action         the one main action of a screen, glowing, alone on the right
--   pips / bar     the progress a button carries
--   title / back   the screen's name written like the logo, the way back at the bottom left
--   scene          the backdrop: veil, rays, halo, seam, sparks
--
-- Everything is placed with the Figma's coordinates: 1280 x 720, x from the
-- left and y from the TOP, text on its baseline. A group is an origin in
-- those coordinates:
--   local root = kit.anchor(0, 0)                       -- or stuck to an edge: kit.anchor(x, y, gui.ANCHOR_LEFT, gui.ANCHOR_TOP)
--   local p = kit.plate(root, 30, 226, 380, 88, kit.C.ROSE)
--   kit.text(p.g, "CAMPAGNA", 150, 266, 27, kit.C.SAND)
--   kit.button(list_of, p, "campagna")                  -- for ui.touch
--
-- The shapes are white pieces of the ui atlas (tools/grafica/piastre.py)
-- colored here; colors are the "Inferno" palette.

local screen = require "ui.screen"

local M = {}

local function hex(s, a)
	return vmath.vector4(tonumber(s:sub(1, 2), 16) / 255, tonumber(s:sub(3, 4), 16) / 255, tonumber(s:sub(5, 6), 16) / 255, a or 1)
end
M.hex = hex

M.C = {
	INK = hex("170b0c"),            -- the dark: veils, text on light plates
	SAND = hex("f5e4c0"),           -- text, and the light plates
	SAND_SHADOW = hex("c9a878"),
	MUTE = hex("bfa9a4"),           -- secondary text
	LINE = hex("5e3e40"),           -- unlit pips, faint outlines
	RAY = hex("70383c"),
	CARD_TOP = hex("402123"),       -- a dark plate, from top...
	CARD_BOTTOM = hex("1f1011"),    -- ...to bottom
	TRACK = hex("472f31"),          -- the empty part of a bar
	ROSE = hex("cd6f75"),           -- the shadow of a plate at rest
	HOT = hex("ffd029"),            -- the action's color (lava yellow)
	HOT_TOP = hex("fffa4f"),
	HOT_BOTTOM = hex("ffbd1a"),
	HOT_EDGE = hex("ffe23d"),
	SEAM = hex("fffd9a"),
	SEAM_GLOW = hex("ffda2e"),
	HALO = hex("ffeb4a"),
	TINT = hex("5a0a0a"),           -- the red cast over the world
	STAR = hex("fff1cf"),
	RED = hex("ff3b4e"),
	OBSIDIAN = hex("ff70d1"),
	MINT = hex("5cdbb8"),
	STEEL = hex("9ec4e0"),
	PURPLE = hex("c49cff"),
}
local C = M.C

local function with_alpha(c, a) return vmath.vector4(c.x, c.y, c.z, a) end
M.with_alpha = with_alpha

local V = vmath.vector3()
local function vec(x, y) return vmath.vector3(x, y, 0) end
local CLEAR = vmath.vector4(0, 0, 0, 0)

local function empty(x, y, w, h, parent)
	local n = gui.new_box_node(vec(x, y), vec(w or 0, h or 0))
	gui.set_visible(n, false)
	if parent then gui.set_parent(n, parent) end
	return n
end

local function shape(tex, x, y, w, h, color, parent)
	local n = gui.new_box_node(vec(x, y), vec(w, h))
	if tex then
		gui.set_texture(n, "ui")
		gui.play_flipbook(n, tex)
	end
	gui.set_color(n, color)
	if parent then gui.set_parent(n, parent) end
	return n
end

-- ---------------------------------------------------------------- groups

-- A top-level group at the Figma point (x, y), optionally stuck to a real
-- edge of the screen (ui/screen.lua): only nodes without a parent do that
function M.anchor(x, y, xa, ya)
	local n = empty(x or 0, 720 - (y or 0))
	if xa then gui.set_xanchor(n, xa) end
	if ya then gui.set_yanchor(n, ya) end
	return { node = n, ox = x or 0, oy = y or 0 }
end

-- A group inside another, at the Figma point (x, y): to move or scale its
-- pieces together
function M.group(g, x, y)
	return { node = empty(x - g.ox, g.oy - y, 0, 0, g.node), ox = x, oy = y }
end

-- ---------------------------------------------------------------- shapes

-- The three pieces of a parallelogram centered on parent: the top side is
-- sk to the right of the bottom one. faded: full at the top, nothing at the bottom
local function fill(parent, w, h, sk, color, faded)
	local lap = color.w >= 1 and 1 or 0
	local suffix = faded and "_sfuma" or ""
	return {
		shape("taglio_sx" .. suffix, -w / 2, 0, sk, h, color, parent),
		shape(faded and "sfuma" or nil, 0, 0, w - sk + lap, h, color, parent),
		shape("taglio_dx" .. suffix, w / 2, 0, sk, h, color, parent),
	}
end

local function tint(parts, color)
	for i = 1, #parts do gui.set_color(parts[i], color) end
end
M.tint = tint

-- A bare parallelogram: (x, y) the bottom-left... in Figma terms the box
-- x..x+w at the bottom, shifted sk at the top. Returns { node, parts, g }
function M.para(g, x, y, w, h, sk, color)
	local cx, cy = x + (w + sk) / 2, y + h / 2
	local n = empty(cx - g.ox, g.oy - cy, w + sk, h, g.node)
	return { node = n, parts = fill(n, w, h, sk, color), g = { node = n, ox = cx, oy = cy }, x = x, y = y, w = w, h = h, sk = sk }
end

-- A plate: the solid shadow (d to the right and below) and the face, dark
-- from CARD_TOP to CARD_BOTTOM or flat (opt.fill). opt: sk, d, fill
function M.plate(g, x, y, w, h, shadow, opt)
	opt = opt or {}
	local sk = opt.sk or math.min(28, h * 0.32)
	local d = opt.d or 8
	local p = M.para(g, x, y, w, h, sk, CLEAR)
	gui.delete_node(p.parts[1]); gui.delete_node(p.parts[2]); gui.delete_node(p.parts[3])
	local sh = empty(d, -(d + 1), 0, 0, p.node)
	p.shadow = fill(sh, w, h, sk, shadow)
	p.shadow_node = sh
	p.face_node = empty(0, 0, 0, 0, p.node)
	if opt.fill then
		p.parts = fill(p.face_node, w, h, sk, opt.fill)
	else
		p.parts = fill(p.face_node, w, h, sk, C.CARD_BOTTOM)
		p.top = fill(p.face_node, w, h, sk, C.CARD_TOP, true)
	end
	p.d = d
	p.shadow_color = shadow
	return p
end

-- The light plate (the player's name, the current chapter)
function M.sand(g, x, y, w, h, shadow, opt)
	opt = opt or {}
	return M.plate(g, x, y, w, h, shadow or C.HOT, { sk = opt.sk, d = opt.d, fill = C.SAND })
end

-- A straight segment between two Figma points, thick t
function M.line(g, x1, y1, x2, y2, t, color)
	local dx, dy = x2 - x1, y2 - y1
	local n = shape(nil, (x1 + x2) / 2 - g.ox, g.oy - (y1 + y2) / 2, math.sqrt(dx * dx + dy * dy), t, color, g.node)
	V.x, V.y, V.z = 0, 0, -math.deg(math.atan2(dy, dx))
	gui.set_rotation(n, V)
	return n
end

-- The outline of a parallelogram, thick t
function M.outline(g, x, y, w, h, sk, t, color)
	return {
		M.line(g, x + sk, y, x + w + sk, y, t, color),
		M.line(g, x, y + h, x + w, y + h, t, color),
		M.line(g, x + sk, y, x, y + h, t, color),
		M.line(g, x + w + sk, y, x + w, y + h, t, color),
	}
end

-- A picture cut to the slant at the left end of a plate (a door's
-- miniature): `wide` pixels at the base, then a thin line in `edge` color.
-- texture and image: a gui texture and one of its images
function M.thumb(p, texture, image, wide, edge)
	local h, sk = p.h, p.sk
	local band = gui.new_box_node(vec(-(p.w + sk) / 2 + (wide + sk) / 2, 0), vec(wide + sk, h))
	gui.set_clipping_mode(band, gui.CLIPPING_MODE_STENCIL)
	gui.set_clipping_visible(band, false)
	gui.set_parent(band, p.face_node)
	local lean = math.atan2(sk, h)
	local cut = gui.new_box_node(vec(0, 0), vec(wide * math.cos(lean), h / math.cos(lean) + sk))
	gui.set_clipping_mode(cut, gui.CLIPPING_MODE_STENCIL)
	gui.set_clipping_visible(cut, false)
	V.x, V.y, V.z = 0, 0, -math.deg(lean)
	gui.set_rotation(cut, V)
	gui.set_parent(cut, band)
	local img = gui.new_box_node(vec(0, 0), vec((h + 30) * 16 / 9, h + 30))
	gui.set_texture(img, texture)
	gui.play_flipbook(img, image)
	V.z = math.deg(lean)
	gui.set_rotation(img, V)
	gui.set_parent(img, cut)
	gui.set_color(img, vmath.vector4(0.8, 0.72, 0.72, 1))
	local x0 = p.x + wide
	local line = M.line(p.g, x0 + sk, p.y, x0, p.y + h, 3, edge or C.ROSE)
	gui.set_parent(line, p.face_node, true)
	return img
end

-- ---------------------------------------------------------------- text

local FONT_SIZE = 40
-- from the baseline up to the middle of the line box, in font sizes
local BASELINE = 0.36
local PIVOTS = { start = gui.PIVOT_W, middle = gui.PIVOT_CENTER, ["end"] = gui.PIVOT_E }

-- Text of `size` pixels on the baseline (x, y). anchor: "start" (default),
-- "middle", "end". spacing: extra pixels between letters
function M.text(g, t, x, y, size, color, anchor, spacing)
	local n = gui.new_text_node(vec(x - g.ox, g.oy - y + size * BASELINE), t)
	gui.set_font(n, "titolo")
	gui.set_pivot(n, PIVOTS[anchor or "start"])
	gui.set_color(n, color or C.SAND)
	gui.set_outline(n, CLEAR)
	gui.set_shadow(n, CLEAR)
	V.x, V.y, V.z = size / FONT_SIZE, size / FONT_SIZE, 1
	gui.set_scale(n, V)
	if spacing and spacing ~= 0 then gui.set_tracking(n, spacing / size) end
	gui.set_parent(n, g.node)
	return n
end

-- ---------------------------------------------------------------- progress

-- n small slanted notches, the first `lit` in color
function M.pips(g, x, y, n, lit, color)
	local list_of = {}
	for i = 0, n - 1 do
		list_of[#list_of + 1] = M.para(g, x + i * 15, y, 10, 16, 5, i < lit and color or C.LINE)
	end
	return list_of
end

-- A slanted bar filled to f (0..1)
function M.bar(g, x, y, w, h, f, color, track)
	local b = { back = M.para(g, x, y, w, h, h * 0.4, track or C.TRACK), g = g, x = x, y = y, w = w, h = h, color = color }
	if f > 0 then b.front = M.para(g, x, y, math.max(h, w * f), h, h * 0.4, color) end
	return b
end

-- ---------------------------------------------------------------- buttons

-- Makes a plate a button of list_of (ui.touch, the controller's light)
function M.button(list_of, p, ui_action, opt)
	local b = { nodo = p.node, bordo = p.node, colore = CLEAR, riposo = CLEAR, ui_action = ui_action, piastra = p,
		spento = opt and opt.spento, luce = opt and opt.main and p.node or nil }
	list_of[#list_of + 1] = b
	return b
end

-- The main action: the glowing plate with the sand shadow and, under it, a
-- dark tag saying what it starts. opt: size (of the label), sub
function M.action(g, label, x, y, w, h, opt)
	opt = opt or {}
	local sk = 46
	local cx, cy = x + (w + sk) / 2, y + h / 2
	local glow = shape("alone", cx - g.ox, g.oy - cy, (w + sk) * 1.5, h * 2.6, with_alpha(C.HOT, 0.5), g.node)
	gui.set_blend_mode(glow, gui.BLEND_ADD)
	local p = M.plate(g, x, y, w, h, C.SAND, { sk = sk, d = 14, fill = C.HOT_BOTTOM })
	p.top = fill(p.face_node, w, h, sk, C.HOT_TOP, true)
	p.glow = glow
	p.rim = M.outline(p.g, x + 12, y + 10, w - 24, h - 20, 40, 2, vmath.vector4(1, 1, 1, 0.35))
	for i = 1, 4 do gui.set_parent(p.rim[i], p.face_node, true) end
	local size = opt.size or math.min(92, (w - 60) / (#label * 0.56))
	p.label = M.text(p.g, label, x + w / 2 + 23, y + h / 2 + size * 0.36, size, C.INK, "middle")
	gui.set_parent(p.label, p.face_node, true)
	if opt.sub then
		p.tag = M.para(g, x + 14, y + h + 16, w - 28, 40, 14, C.INK)
		p.sub = M.text(p.tag.g, opt.sub, x + w / 2 + 10, y + h + 43, 16, C.SAND, "middle", 1.2)
	end
	gui.animate(glow, "color.w", 0.25, gui.EASING_INOUTSINE, 1.4, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
	return p
end

-- A plate goes down onto its shadow when pressed, and comes back
function M.press(p, down)
	local d = down and p.d * 0.75 or 0
	gui.animate(p.face_node, "position", vec(d, -d), gui.EASING_OUTQUAD, 0.06)
end

-- ---------------------------------------------------------------- header

-- The screen's name written like the logo: sand, with the accent just behind
function M.title(g, label, accent, x, y, size)
	x, y, size = x or 30, y or 76, size or 50
	return { M.text(g, label, x + 4, y + 4, size, accent or C.HOT, "start", 1), M.text(g, label, x, y, size, C.SAND, "start", 1) }
end

-- ---------------------------------------------------------------- scene

local RAYS = 18

-- The backdrop of a menu over the game world: a red cast and a dark veil,
-- the rays turning slowly around (fx, fy), the halo there, the dark rising
-- from the bottom, the ember seam and the sparks. opt: dim (0.5), halo
-- (its radius, 400), accent (a wide soft light in the menu's color).
-- Returns the scene: scene.tops are its top-level nodes (to enable/disable)
function M.scene(fx, fy, opt)
	opt = opt or {}
	local s = { tops = {}, sparks = {} }
	local function full(color)
		local n = shape(nil, 640, 360, 1280 * screen.FULL, 720 * screen.FULL, color)
		s.tops[#s.tops + 1] = n
		return n
	end
	full(with_alpha(C.TINT, 0.5))
	full(with_alpha(C.INK, opt.dim or 0.5))
	-- the rays
	local hub = M.anchor(fx, fy)
	s.tops[#s.tops + 1] = hub.node
	s.hub = hub
	local spin = empty(0, 0, 0, 0, hub.node)
	s.spin = spin
	for i = 0, RAYS - 1 do
		local a = i / RAYS * math.pi * 2 + 0.07
		local wide = 0.09 + (i % 3) * 0.03
		local n = shape("taglio_sx", 0, 0, 1800, 1800 * math.tan(wide), with_alpha(C.RAY, 0.4), spin)
		gui.set_pivot(n, gui.PIVOT_SW)
		V.x, V.y, V.z = 0, 0, -math.deg(a + wide)
		gui.set_rotation(n, V)
	end
	gui.animate(spin, "rotation.z", -360, gui.EASING_LINEAR, 240, 0, nil, gui.PLAYBACK_LOOP_FORWARD)
	if opt.accent then
		local n = shape("alone", 0, 0, 1500, 1500, with_alpha(opt.accent, 0.13), hub.node)
		gui.set_blend_mode(n, gui.BLEND_ADD)
	end
	local r = opt.halo or 400
	s.halo = shape("alone", 0, 0, r * 2.4, r * 2.4, with_alpha(C.HALO, 0.38), hub.node)
	gui.set_blend_mode(s.halo, gui.BLEND_ADD)
	gui.animate(s.halo, "color.w", 0.3, gui.EASING_INOUTSINE, 2.6, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
	-- the dark from the bottom (stuck to the real bottom) and the seam
	local low = M.anchor(640, 720, nil, gui.ANCHOR_BOTTOM)
	s.tops[#s.tops + 1] = low.node
	s.low = low
	local fade = shape("sfuma", 0, 125, 1280 * screen.FULL, 250, with_alpha(C.INK, 0.9), low.node)
	V.x, V.y, V.z = 0, 0, 180
	gui.set_rotation(fade, V)
	shape(nil, 0, -360 * screen.FULL / 2, 1280 * screen.FULL, 360 * screen.FULL, with_alpha(C.INK, 0.9), low.node)
	if opt.seam ~= false then
		s.seam_glow = shape("alone", 0, 59, 1300, 20, with_alpha(C.SEAM_GLOW, 0.35), low.node)
		gui.set_blend_mode(s.seam_glow, gui.BLEND_ADD)
		s.seam = shape(nil, 0, 59, 1220, 2, C.SEAM, low.node)
	end
	-- the sparks: small rhombi rising and twinkling
	local seed = 5
	local function rnd()
		seed = (seed * 1664525 + 1013904223) % 4294967296
		return seed / 4294967296
	end
	local air = M.anchor(0, 0)
	s.tops[#s.tops + 1] = air.node
	for _ = 1, opt.sparks or 22 do
		local x, y = 60 + rnd() * 1160, 90 + rnd() * 510
		local d = 3 + rnd() * 5
		local n = shape(nil, x, 720 - y, d, d, with_alpha(rnd() > 0.5 and C.HOT_TOP or C.HOT, 0.55 + rnd() * 0.4), air.node)
		V.x, V.y, V.z = 0, 0, 45
		gui.set_rotation(n, V)
		gui.animate(n, "position.y", 720 - y + 50 + rnd() * 40, gui.EASING_INOUTSINE, 3 + rnd() * 3, rnd() * 3, nil, gui.PLAYBACK_LOOP_PINGPONG)
		gui.animate(n, "color.w", 0.3, gui.EASING_INOUTSINE, 1.2 + rnd() * 2, rnd() * 2, nil, gui.PLAYBACK_LOOP_PINGPONG)
		s.sparks[#s.sparks + 1] = n
	end
	return s
end

-- The seam runs between the real edges of the screen: call it when the
-- screen is shown (the proportions may have changed)
function M.scene_fit(s)
	if not s.seam then return end
	local w = screen.width() - 60
	gui.set_size(s.seam, vec(w, 2))
	gui.set_size(s.seam_glow, vec(w + 80, 20))
end

function M.scene_show(s, on)
	for _, n in ipairs(s.tops) do gui.set_enabled(n, on) end
	if on then M.scene_fit(s) end
end

-- ---------------------------------------------------------------- motion

-- A piece arrives from (dx, dy) away, in `time` seconds after `delay`,
-- overshooting a little. node: any node; its resting position is the current one
function M.arrive(node, dx, dy, delay, time)
	local p = gui.get_position(node)
	gui.cancel_animations(node, "position")
	gui.set_position(node, vec(p.x + dx, p.y + dy))
	gui.animate(node, "position", p, gui.EASING_OUTBACK, time or 0.32, delay or 0)
	return p
end

-- A piece pops: from small to its size, overshooting
function M.pop(node, delay, time, from)
	gui.cancel_animations(node, "scale")
	local k = from or 0.86
	gui.set_scale(node, vmath.vector3(k, k, 1))
	gui.animate(node, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, time or 0.3, delay or 0)
end

return M
