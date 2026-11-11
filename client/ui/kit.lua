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
local ui = require "ui.ui"

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

-- A picture cut to a slant, centered on parent: w wide at the base and h
-- tall, its top sk to the right (a band as tall as the picture, a leaning box
-- in it). The picture covers the place keeping its shape (ratio: its width
-- over its height). Without a texture, a dark plate
function M.picture(parent, texture, w, h, sk, ratio)
	local band = gui.new_box_node(vec(0, 0), vec(w + sk, h))
	gui.set_clipping_mode(band, gui.CLIPPING_MODE_STENCIL)
	gui.set_clipping_visible(band, false)
	gui.set_parent(band, parent)
	local lean = math.atan2(sk, h)
	local cut = gui.new_box_node(vec(0, 0), vec(w * math.cos(lean), h / math.cos(lean) + sk + 2 * w * math.sin(lean)))
	gui.set_clipping_mode(cut, gui.CLIPPING_MODE_STENCIL)
	gui.set_clipping_visible(cut, false)
	V.x, V.y, V.z = 0, 0, -math.deg(lean)
	gui.set_rotation(cut, V)
	gui.set_parent(cut, band)
	ratio = ratio or 16 / 9
	local tall = math.max(h, (w + sk) / ratio) + 4
	local img = gui.new_box_node(vec(0, 0), vec(tall * ratio, tall))
	if texture then gui.set_texture(img, texture) else gui.set_color(img, C.CARD_BOTTOM) end
	V.z = math.deg(lean)
	gui.set_rotation(img, V)
	gui.set_parent(img, cut)
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

-- Capitals, the accented letters too (string.upper leaves them small)
local ACCENTS = { ["à"] = "À", ["è"] = "È", ["é"] = "É", ["ì"] = "Ì", ["ò"] = "Ò", ["ù"] = "Ù" }
function M.upper(t)
	return (string.upper(t):gsub("\195[\160-\191]", ACCENTS))
end

-- How wide a text node is, in pixels
function M.width(n)
	local m = resource.get_text_metrics(gui.get_font_resource(gui.get_font(n)), gui.get_text(n))
	return m.width * gui.get_scale(n).x
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
-- dark tag saying what it starts. opt: size (of the label), sub, off (it
-- can't be done now: dark, and the tag says why)
function M.action(g, label, x, y, w, h, opt)
	opt = opt or {}
	local sk = 46
	local cx, cy = x + (w + sk) / 2, y + h / 2
	local size = opt.size or math.min(92, (w - 60) / (#label * 0.56))
	if opt.off then
		-- not now: a dark plate, and the tag says what is missing
		local p = M.plate(g, x, y, w, h, C.LINE, { sk = sk, d = 14 })
		p.label = M.text(p.g, label, x + w / 2 + 23, y + h / 2 + size * 0.36, size, with_alpha(C.MUTE, 0.7), "middle")
		gui.set_parent(p.label, p.face_node, true)
		if opt.sub then
			p.tag = M.para(g, x + 14, y + h + 16, w - 28, 40, 14, C.INK)
			p.sub = M.text(p.tag.g, opt.sub, x + w / 2 + 10, y + h + 43, 16, C.HOT_TOP, "middle", 1.2)
		end
		return p
	end
	local glow = shape("alone", cx - g.ox, g.oy - cy, (w + sk) * 1.5, h * 2.6, with_alpha(C.HOT, 0.5), g.node)
	gui.set_blend_mode(glow, gui.BLEND_ADD)
	local p = M.plate(g, x, y, w, h, C.SAND, { sk = sk, d = 14, fill = C.HOT_BOTTOM })
	p.top = fill(p.face_node, w, h, sk, C.HOT_TOP, true)
	p.glow = glow
	p.rim = M.outline(p.g, x + 12, y + 10, w - 24, h - 20, 40, 2, vmath.vector4(1, 1, 1, 0.35))
	for i = 1, 4 do gui.set_parent(p.rim[i], p.face_node, true) end
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

-- The way back: a small plate at the bottom left, on the seam, with where it
-- goes written under it (Sergio, 10 Nov: the title and the way back are two
-- different things). Returns the header: h.tops its top-level nodes
function M.header(list_of, label, accent, back_action, from)
	local h = { tops = {} }
	local tl = M.anchor(0, 0, gui.ANCHOR_LEFT, gui.ANCHOR_TOP)
	h.tops[#h.tops + 1] = tl.node
	h.title = M.title(tl, label, accent)
	h.top_left = tl
	if back_action then
		local bl = M.anchor(0, 720, gui.ANCHOR_LEFT, gui.ANCHOR_BOTTOM)
		h.tops[#h.tops + 1] = bl.node
		h.back = M.plate(bl, 8, 636, 52, 48, accent or C.HOT, { sk = 12, d = 5 })
		gui.set_parent(M.line(h.back.g, 35, 650, 24, 660, 5, C.SAND), h.back.face_node, true)
		gui.set_parent(M.line(h.back.g, 24, 660, 35, 670, 5, C.SAND), h.back.face_node, true)
		M.text(bl, from or "", 36, 704, 10, M.with_alpha(C.SAND, 0.8), "middle", 1)
		-- a generous zone around the small plate
		local zone = empty(40, 46, 96, 92, bl.node)
		list_of[#list_of + 1] = { nodo = zone, bordo = zone, colore = CLEAR, riposo = CLEAR, ui_action = back_action, piastra = h.back }
	end
	local tr = M.anchor(1280, 0, gui.ANCHOR_RIGHT, gui.ANCHOR_TOP)
	h.tops[#h.tops + 1] = tr.node
	h.top_right = tr
	return h
end

function M.header_delete(h)
	for _, n in ipairs(h.tops) do gui.delete_node(n) end
end

-- ---------------------------------------------------------------- categories

function M.rect(g, x, y, w, h, color)
	return shape(nil, x + w / 2 - g.ox, g.oy - (y + h / 2), w, h, color, g.node)
end

-- An invisible zone that takes the taps of list_of
function M.zone(g, list_of, x, y, w, h, ui_action)
	local n = empty(x + w / 2 - g.ox, g.oy - (y + h / 2), w, h, g.node)
	local b = { nodo = n, bordo = n, colore = CLEAR, riposo = CLEAR, ui_action = ui_action }
	list_of[#list_of + 1] = b
	return b
end

-- TABS: trapezoids standing on a rail; the active one is sand.
-- tabs: { { label, ui_action }, ... }
function M.tabs(g, list_of, x, y, tabs, active, accent)
	local h, cx = 40, x
	for i, tab in ipairs(tabs) do
		local w = #tab[1] * 13 + 44
		local on = i == active
		local color = on and C.SAND or C.CARD_TOP
		local n = empty(cx + w / 2 - g.ox, g.oy - (y + h / 2), w, h, g.node)
		shape("taglio_sx", -w / 2 + 6, 0, 12, h, color, n)
		shape(nil, 0, 0, w - 24 + 1, h, color, n)
		local r = shape("taglio_dx", w / 2 - 6, 0, h, 12, color, n)
		V.x, V.y, V.z = 0, 0, 90
		gui.set_rotation(r, V)
		M.text({ node = n, ox = cx + w / 2, oy = y + h / 2 }, tab[1], cx + w / 2, y + 27, 19,
			on and C.INK or M.with_alpha(C.SAND, 0.8), "middle", 0.5)
		list_of[#list_of + 1] = { nodo = n, bordo = n, colore = CLEAR, riposo = CLEAR, ui_action = tab[2] }
		cx = cx + w + 6
	end
	M.rect(g, x - 14, y + h, cx - x + 22, 5, C.SAND)
	M.rect(g, x - 14, y + h + 5, cx - x + 22, 3, accent or C.HOT)
	return cx
end

-- CHOICES: a small label and the options in a row on a thin line, the sand
-- blade behind the chosen one. opts: { { label, ui_action }, ... }; w: an
-- option's width; off: dim, nothing to tap
function M.choice(g, list_of, x, y, label, opts, active, w, off)
	local h = 44
	M.text(g, label, x + 6, y - 10, 14, with_alpha(C.MUTE, off and 0.5 or 1), "start", 1.5)
	M.rect(g, x, y + h - 2, #opts * w, 2, with_alpha(C.LINE, 0.6))
	for i, o in ipairs(opts) do
		local ox = x + (i - 1) * w
		local on = i == active and not off
		if on then M.para(g, ox, y, w - 12, h, 12, C.SAND) end
		M.text(g, o[1], ox + w / 2, y + h / 2 + 6, #o[1] > 14 and 14 or 18, on and C.INK or with_alpha(C.MUTE, off and 0.4 or 1), "middle")
		if not off then M.zone(g, list_of, ox, y - 6, w, h + 12, o[2]) end
	end
end

-- CARDS: a cut corner at the top right and a frame in the card's color.
-- opt: sel (chosen: sand frame and a glow), off (dim). Returns { node, g }
function M.card(g, x, y, w, h, color, opt)
	opt = opt or {}
	local c = math.min(24, h * 0.34)
	local cx, cy = x + w / 2, y + h / 2
	local n = empty(cx - g.ox, g.oy - cy, w, h, g.node)
	local k = { node = n, g = { node = n, ox = cx, oy = cy }, x = x, y = y, w = w, h = h }
	if opt.sel then
		local glow = shape("alone", 0, 0, w * 1.5, h * 1.6, with_alpha(C.HOT, 0.45), n)
		gui.set_blend_mode(glow, gui.BLEND_ADD)
	end
	local fa = opt.off and 0.75 or 1
	local bottom, top = with_alpha(C.CARD_BOTTOM, fa), with_alpha(C.CARD_TOP, fa)
	-- the face: everything but the cut corner
	shape(nil, -c / 2, 0, w - c, h, bottom, n)
	shape(nil, w / 2 - c / 2, -c / 2, c, h - c, bottom, n)
	local tri = shape("taglio_dx", w / 2 - c / 2, h / 2 - c / 2, c, c, top, n)
	V.x, V.y, V.z = 0, 0, 90
	gui.set_rotation(tri, V)
	shape("sfuma", -c / 2, 0, w - c, h, top, n)
	shape("sfuma", w / 2 - c / 2, -c / 2, c, h - c, with_alpha(C.CARD_TOP, fa * (1 - c / h)), n)
	-- the frame
	local col = opt.sel and C.SAND or with_alpha(color, opt.off and 0.4 or 1)
	local t = opt.sel and 4 or 3
	k.frame = {
		M.line(k.g, x, y, x + w - c, y, t, col), M.line(k.g, x + w - c, y, x + w, y + c, t, col),
		M.line(k.g, x + w, y + c, x + w, y + h, t, col), M.line(k.g, x + w, y + h, x, y + h, t, col),
		M.line(k.g, x, y + h, x, y, t, col),
	}
	local tip = shape("taglio_dx", w / 2 - (c - 7) / 2, h / 2 - (c - 7) / 2, c - 7, c - 7, col, n)
	V.z = -90
	gui.set_rotation(tip, V)
	return k
end

-- A picture at the top of a card, `tall` pixels, cut to the card's corner
-- (two clippers, like M.thumb). The picture covers the place keeping its
-- shape (ratio: its width over its height). dim: how bright (a closed card)
function M.card_picture(k, texture, tall, ratio, dim)
	local w, h = k.w, k.h
	local c = math.min(24, h * 0.34)
	local ay = h / 2 - 4 - tall / 2
	local band = gui.new_box_node(vec(0, ay), vec(w - 8, tall))
	gui.set_clipping_mode(band, gui.CLIPPING_MODE_STENCIL)
	gui.set_clipping_visible(band, false)
	gui.set_parent(band, k.node)
	-- a big square turned 45 degrees, its top right side along the cut
	local big = 1200
	local r = math.sqrt(2) / 2
	local px, py = w / 2 - c / 2 - 3 - big / 2 * r, h / 2 - c / 2 - 3 - big / 2 * r - ay
	local cut = gui.new_box_node(vec(px, py), vec(big, big))
	gui.set_clipping_mode(cut, gui.CLIPPING_MODE_STENCIL)
	gui.set_clipping_visible(cut, false)
	gui.set_parent(cut, band)
	-- a square at 45 degrees clips like a diamond: its side toward (1, 1) is the cut
	V.x, V.y, V.z = 0, 0, 45
	gui.set_rotation(cut, V)
	local iw, ih = w - 8, tall
	ratio = ratio or 16 / 9
	if iw / ih > ratio then ih = iw / ratio else iw = ih * ratio end
	-- back to the band's middle, in the turned square's own axes
	local dx, dy = -px, -py
	local img = gui.new_box_node(vec((dx + dy) * r, (dy - dx) * r), vec(iw, ih))
	gui.set_texture(img, texture)
	V.z = -45
	gui.set_rotation(img, V)
	gui.set_color(img, vmath.vector4(dim or 1, dim or 1, dim or 1, 1))
	gui.set_parent(img, cut)
	return img
end

-- INFORMATION: a dark row with a spine of color, no shadow: it is read, not pressed
function M.info(g, x, y, w, h, color)
	M.rect(g, x, y, w, h, with_alpha(C.INK, 0.5))
	return M.rect(g, x, y, 5, h, color)
end

-- LABELS: a small blade and the name in color
function M.label(g, x, y, t, color, backed)
	if backed then M.para(g, x - 6, y, #t * 9 + 30, 22, 6, with_alpha(C.INK, 0.8)) end
	M.para(g, x, y + 3, 7, 16, 4, color)
	return M.text(g, t, x + 16, y + 17, 13, color, "start", 1.2)
end

-- A section's small heading
function M.heading(g, t, x, y, color)
	return M.text(g, t, x, y, 14, color or C.HOT_TOP, "start", 1.5)
end

-- MEASURES: round seals on the thresholds of a bar. state: "got" (full, in
-- color), "cur" (the one you are looking at: bigger, sand ring, a glow),
-- "todo" (dark, a ring in color)
function M.seal(g, cx, cy, t, state, color)
	local r = state == "cur" and 22 or 16
	local x, y = cx - g.ox, g.oy - cy
	if state == "cur" then
		local glow = shape("alone", x, y, r * 4.4, r * 4.4, with_alpha(color, 0.7), g.node)
		gui.set_blend_mode(glow, gui.BLEND_ADD)
	end
	ui.disc(x, y, r * 2 + 3, state == "cur" and C.SAND or color, g.node)
	ui.disc(x, y, r * 2 - 3, state == "got" and color or C.INK, g.node)
	ui.ring_node(x, y, (r - 4) * 2, 2, state == "got" and C.INK or color, g.node)
	return M.text(g, t, cx, cy + 5, state == "cur" and 16 or 13, state == "got" and C.INK or C.SAND, "middle")
end

-- REGULATORS: the small controls inside a screen are round, not plates: the
-- capsule "- +" (Sergio, 10 Nov). off_minus, off_plus: that side can't be used
function M.stepper(g, list_of, x, y, minus, plus, off_minus, off_plus, value)
	local w, h = value and 124 or 92, 36
	local n, border = ui.panel(x + w / 2 - g.ox, g.oy - (y + h / 2), w, h, g.node, "pillola")
	gui.set_color(n, with_alpha(C.INK, 0.85))
	gui.set_color(border, with_alpha(C.SAND, 0.3))
	local sg = { node = n, ox = x + w / 2, oy = y + h / 2 }
	M.text(sg, "−", x + 22, y + 26, 24, off_minus and C.LINE or C.SAND, "middle")
	M.text(sg, "+", x + w - 22, y + 26, 24, off_plus and C.LINE or C.SAND, "middle")
	if value then
		M.text(sg, tostring(value), x + w / 2, y + 25, 18, C.SAND, "middle")
	else
		M.rect(sg, x + w / 2 - 1, y + 8, 2, 20, with_alpha(C.SAND, 0.2))
	end
	local a = M.zone(sg, list_of, x - 4, y - 6, w / 2 + 4, h + 12, minus)
	a.spento = off_minus or nil
	local b = M.zone(sg, list_of, x + w / 2, y - 6, w / 2 + 4, h + 12, plus)
	b.spento = off_plus or nil
	return n
end

-- A small round button inside a card (QUI): a regulator, not a plate
function M.round(g, list_of, cx, cy, label, ui_action)
	local n = empty(cx - g.ox, g.oy - cy, 48, 48, g.node)
	gui.set_blend_mode(ui.disc(0, 0, 42, with_alpha(C.INK, 0.85), n), gui.BLEND_ALPHA)
	ui.ring_node(0, 0, 42, 2, with_alpha(C.SAND, 0.4), n)
	M.text({ node = n, ox = cx, oy = cy }, label, cx, cy + 5, 13, C.SAND, "middle", 0.5)
	local b = { nodo = n, bordo = n, colore = CLEAR, riposo = CLEAR, ui_action = ui_action }
	list_of[#list_of + 1] = b
	return b
end

-- The player's plate: name (or what it is), a line on the right, the bar
function M.nameplate(g, x, y, name, right, f, accent)
	local p = M.sand(g, x, y, 340, 62, accent or C.HOT, { sk = 22 })
	p.name = M.text(p.g, name, x + 36, y + 39, 22, C.INK)
	p.right = M.text(p.g, right, x + 330, y + 26, 18, with_alpha(C.INK, 0.75), "end", 1)
	p.bar = M.bar(p.g, x + 176, y + 40, 150, 7, f, C.HOT_BOTTOM, C.SAND_SHADOW)
	return p
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
	-- opt.world: the game world behind stays the main thing, the rays just a hint
	local world = opt.world or M.WORLD
	full(with_alpha(C.TINT, world and 0.22 or 0.5))
	full(with_alpha(C.INK, world and 0.22 or opt.dim or 0.5))
	-- the rays
	local hub = M.anchor(fx, fy)
	s.tops[#s.tops + 1] = hub.node
	s.hub = hub
	local spin = empty(0, 0, 0, 0, hub.node)
	s.spin = spin
	for i = 0, RAYS - 1 do
		local a = i / RAYS * math.pi * 2 + 0.07
		local wide = 0.09 + (i % 3) * 0.03
		local n = shape("taglio_sx", 0, 0, 1800, 1800 * math.tan(wide), with_alpha(C.RAY, world and 0.2 or 0.4), spin)
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
