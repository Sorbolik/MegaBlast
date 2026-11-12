-- The "Fucina contro Abisso" interface kit (Sergio, 12 Nov; Figma "MegaBlast ·
-- Interfaccia", page 3): a comic forge against the ice. Dark soot behind, a
-- thread at the bottom that goes from ember to frost, and pieces drawn by hand
-- (Codex, WB-022) whose shape says what they are. One function per category:
--   plate / sand   buttons: a beaten iron plate (dark, warm when it is yours or
--                  lit, light for the name), a shard of ice when it is closed
--   action         the one main action of a screen: the red-hot ingot
--   pips / bar     the progress a button carries
--   title / back   the screen's name, the way back at the bottom left
--   scene          the backdrop: soot, a warm light bottom left and a cold one
--                  top right, the thread
--
-- Everything is placed with the Figma's coordinates: 1280 x 720, x from the
-- left and y from the TOP, text on its baseline. A group is an origin in
-- those coordinates:
--   local root = kit.anchor(0, 0)                       -- or stuck to an edge: kit.anchor(x, y, gui.ANCHOR_LEFT, gui.ANCHOR_TOP)
--   local p = kit.plate(root, 30, 226, 380, 88, kit.C.ROSE)
--   kit.text(p.g, "CAMPAGNA", 150, 266, 27, kit.C.SAND)
--   kit.button(list_of, p, "campagna")                  -- for ui.touch
--
-- The pieces are pictures of the fucina atlas (tools/grafica/fucina.py), twice
-- as big as they are shown. A long piece is in three parts: the two ends
-- whole, the middle stretched; so nothing is ever deformed or blurred. The
-- small flat shapes (notches, lines) are white pieces of the ui atlas.

local screen = require "ui.screen"
local ui = require "ui.ui"
local P = require "ui.pieces"

local M = {}

local function hex(s, a)
	return vmath.vector4(tonumber(s:sub(1, 2), 16) / 255, tonumber(s:sub(3, 4), 16) / 255, tonumber(s:sub(5, 6), 16) / 255, a or 1)
end
M.hex = hex

M.C = {
	INK = hex("0a080b"),            -- the ink: outlines, text on light plates
	SOOT = hex("121013"),           -- the dark behind everything
	SAND = hex("f4ece1"),           -- text (ivory), and the light plates
	SAND_SHADOW = hex("9e958f"),
	MUTE = hex("9e958f"),           -- secondary text (ash)
	LINE = hex("4a4550"),           -- unlit pips, faint outlines (steel)
	NIGHT = hex("38b6ff"),
	CARD_TOP = hex("2e2a33"),       -- a dark face, from top...
	CARD_BOTTOM = hex("1e1a22"),    -- ...to bottom
	TRACK = hex("3a3540"),          -- the empty part of a bar
	ROSE = hex("4a4550"),           -- a plate at rest
	HOT = hex("ffb703"),            -- yours, lit, the action (molten gold)
	HOT_TOP = hex("ffd24a"),
	HOT_BOTTOM = hex("f26419"),     -- ember
	HOT_EDGE = hex("ffb703"),
	SEAM = hex("fff3b0"),           -- spark
	SEAM_GLOW = hex("ffb703"),
	HALO = hex("f26419"),
	ICE = hex("38b6ff"),            -- closed, cost, minus
	FROST = hex("caf0f8"),
	TINT = hex("5a0a0a"),
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
local card_in, piece_in    -- the entrances (below, with the motion)

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

-- A picture of the fucina atlas
local function pic(name, x, y, w, h, parent)
	local n = gui.new_box_node(vec(x, y), vec(w, h))
	gui.set_texture(n, "fucina")
	gui.play_flipbook(n, name)
	if parent then gui.set_parent(n, parent) end
	return n
end

-- A long piece w x h centered on parent, in three parts: the ends keep their
-- shape (as wide as the height asks), only the middle is stretched
local function three(parent, name, w, h)
	local m = P[name]
	local cw = math.min(m.c * h / m.h, w / 2)
	return {
		pic(name .. "_cx", 0, 0, math.max(1, w - 2 * cw + 1), h, parent),
		pic(name .. "_sx", -w / 2 + cw / 2, 0, cw, h, parent),
		pic(name .. "_dx", w / 2 - cw / 2, 0, cw, h, parent),
	}
end

-- The room to write in on a long piece w x h centered at the Figma point
-- (cx, cy): the biggest plain rectangle of its drawing, away from the rim,
-- the rivets and the scratches (pieces.lua, box). Each piece has its own, so
-- the writings of two plates do not line up: that is wanted (Sergio, 12 Nov)
local function room(name, cx, cy, w, h)
	local m = P[name]
	local b = m and m.box
	if not b then return nil end
	local k = h / m.h
	local cw = math.min(m.c * k, w / 2)
	-- a margin inside the cap scales with it; past it, it is in the stretched middle
	local stretch = (w - 2 * cw) / math.max(1, (m.w - 2 * m.c) * k)
	local function inset(v)
		v = v * k
		local cap = m.c * k
		if v <= cap then return v * cw / cap end
		return cw + (v - cap) * stretch
	end
	return { x0 = cx - w / 2 + inset(b[1]), x1 = cx + w / 2 - inset(b[3]), y0 = cy - h / 2 + b[2] * k, y1 = cy + h / 2 - b[4] * k }
end

-- A panel w x h centered on parent, in nine parts: whole corners c wide,
-- the sides stretched along their length only
local function nine(parent, name, w, h, c)
	c = math.min(c or 24, w / 2, h / 2)
	local xs = { { -w / 2 + c / 2, c }, { 0, w - 2 * c + 1 }, { w / 2 - c / 2, c } }
	local ys = { { h / 2 - c / 2, c }, { 0, h - 2 * c + 1 }, { -h / 2 + c / 2, c } }
	local parts, k = {}, 1
	for r = 1, 3 do
		for q = 1, 3 do
			parts[k] = pic(name .. "_" .. k, xs[q][1], ys[r][1], xs[q][2], ys[r][2], parent)
			k = k + 1
		end
	end
	return parts
end

-- A whole piece h tall centered at (x, y) of parent
local function whole(name, x, y, h, parent)
	local m = P[name]
	return pic(name, x, y, m.w * h / m.h, h, parent)
end

-- A whole piece of the fucina atlas (an ember, the lock, a coin...) h tall,
-- centered at the Figma point (cx, cy)
function M.piece(g, name, cx, cy, h)
	return whole(name, cx - g.ox, g.oy - cy, h, g.node)
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

-- ---------------------------------------------------------------- air

-- Where the screen is wider than 16:9 the menus with the devil on the left
-- breathe (Sergio, 11 Nov: «dai più spazio alle cose tra loro»). One measure
-- for all of them:
--   M.side()   the room at each side of the 1280 in the middle
--   M.lean()   how far the whole content goes left, toward the devil
--   M.air(k)   how far a second column goes right of the first (k: 0.5 for
--              a middle one of three)
function M.side()
	return math.min(220, math.max(0, (screen.width() - 1280) / 2))
end
function M.lean() return M.side() * 0.25 end
function M.air(k) return M.side() * 0.6 * (k or 1) end

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

-- A plate: a piece of beaten iron as big as the box x..x+w+sk, y..y+h. shadow
-- says its mood: C.HOT a warm one (yours, lit), anything else dark.
-- opt: sk, piece (another piece in three parts: "piastra_freccia",
-- "piastra_stendardo", "scheggia"...), fill (C.SAND: the light one), d
function M.plate(g, x, y, w, h, shadow, opt)
	opt = opt or {}
	local sk = opt.sk or math.min(28, h * 0.32)
	local p = M.para(g, x, y, w, h, sk, CLEAR)
	gui.delete_node(p.parts[1]); gui.delete_node(p.parts[2]); gui.delete_node(p.parts[3])
	p.face_node = empty(0, 0, 0, 0, p.node)
	p.shadow_node = p.face_node
	local small = h <= 52
	local name = opt.piece
	if not name then
		if opt.fill == C.SAND then name = small and "piastrina_chiara" or "piastra_chiara"
		elseif shadow == C.HOT then name = small and "piastrina_calda" or "piastra_calda"
		else name = small and "piastrina" or "piastra_storta" end
	end
	if w < h * 2 then
		-- a tall plate (a portrait): the panel, not a long piece
		p.parts = nine(p.face_node, opt.fill == C.SAND and "pannello_chiaro" or "pannello", w + sk, h, 30)
	else
		p.parts = three(p.face_node, name, w + sk, h)
		-- what is written on it (M.text on p.g) stays in its room
		p.box = room(name, x + (w + sk) / 2, y + h / 2, w + sk, h)
		p.g.box = p.box
	end
	p.shadow = {}
	p.d = opt.d or 6
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
	if g.box then M.keep_in(n, g.box, g, x, y, size, anchor) end
	return n
end

-- A text just made at the baseline (x, y) of g, moved (and, too wide, shrunk)
-- so that it stays inside the room `box` of its plate: never on the rim
function M.keep_in(n, box, g, x, y, size, anchor)
	local w = M.width(n)
	local wide = box.x1 - box.x0
	local k = 1
	if w > wide then k = wide / w; w = wide end
	local left = anchor == "middle" and x - w / 2 or anchor == "end" and x - w or x
	left = math.max(box.x0, math.min(box.x1 - w, left))
	local tall = size * k * 0.72
	local base = math.max(box.y0 + tall, math.min(box.y1, y))
	if box.y1 - box.y0 < tall then base = (box.y0 + box.y1 + tall) / 2 end
	local px = anchor == "middle" and left + w / 2 or anchor == "end" and left + w or left
	gui.set_position(n, vec(px - g.ox, g.oy - base + size * k * BASELINE))
	V.x, V.y, V.z = size * k / FONT_SIZE, size * k / FONT_SIZE, 1
	gui.set_scale(n, V)
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

-- The main action: the red-hot ingot and, under it, a line saying what it
-- starts. opt: size (of the label), sub, off (it can't be done now: a dark
-- plate, and the line says why)
local function sub_y(y, h)
	-- under the ingot, or over it when the thread is there
	return y + h + 30 > 640 and y - 10 or y + h + 30
end

function M.action(g, label, x, y, w, h, opt)
	opt = opt or {}
	local sk = 46
	local size = opt.size or math.min(92, (w - 60) / (#label * 0.56))
	if opt.off then
		local p = M.plate(g, x, y, w, h, C.LINE, { sk = sk })
		p.label = M.text(p.g, label, x + w / 2 + 23, y + h / 2 + size * 0.36, size, with_alpha(C.MUTE, 0.7), "middle")
		gui.set_parent(p.label, p.face_node, true)
		if opt.sub then p.sub = M.text(g, opt.sub, x + w / 2 + 23, sub_y(y, h), 15, C.FROST, "middle", 1.2) end
		return p
	end
	local p = M.plate(g, x, y, w, h, C.HOT, { sk = sk, piece = "lingotto" })
	-- (the ingot's face is under its lighter top: the label sits a little lower)
	p.label = M.text(p.g, label, x + w / 2 + 23, y + h * 0.58 + size * 0.36, size, C.INK, "middle")
	gui.set_parent(p.label, p.face_node, true)
	if opt.sub then p.sub = M.text(g, opt.sub, x + w / 2 + 23, sub_y(y, h), 15, C.MUTE, "middle", 1.2) end
	-- now and then a small flame lights on it
	p.flame = whole("fiamma", (w + sk) * 0.24, h * 0.5 + h * 0.08, h * 0.3, p.face_node)
	gui.set_pivot(p.flame, gui.PIVOT_S)
	gui.set_scale(p.flame, vmath.vector3(0.01, 0.01, 1))
	local function flick()
		gui.animate(p.flame, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, 0.3, 4.5, function()
			gui.animate(p.flame, "scale", vmath.vector3(0.01, 0.01, 1), gui.EASING_INQUAD, 0.4, 1.3, flick)
		end)
	end
	flick()
	piece_in(p.node, "action")
	return p
end

-- A plate goes down when pressed, and comes back
function M.press(p, down)
	local d = down and p.d * 0.75 or 0
	gui.animate(p.face_node, "position", vec(0, -d), gui.EASING_OUTQUAD, 0.06)
end

-- ---------------------------------------------------------------- header

-- The screen's name written like the logo: in the accent (gold), ink just behind
function M.title(g, label, accent, x, y, size)
	x, y, size = x or 30, y or 76, size or 50
	return { M.text(g, label, x + 3, y + 4, size, C.INK, "start", 1), M.text(g, label, x, y, size, accent or C.HOT, "start", 1) }
end

-- The way back: the small iron arrow at the bottom left, on the thread, with where it
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
		local bn = empty(40, 60, 72, 48, bl.node)
		h.back = { node = bn, face_node = empty(0, 0, 0, 0, bn), d = 5, g = { node = bn, ox = 40, oy = 660 } }
		whole("indietro", 0, 0, 48, h.back.face_node)
		gui.set_parent(M.line(h.back.g, 44, 650, 33, 660, 4, C.SAND), h.back.face_node, true)
		gui.set_parent(M.line(h.back.g, 33, 660, 44, 670, 4, C.SAND), h.back.face_node, true)
		M.text(bl, from or "", 40, 704, 10, C.MUTE, "middle", 1)
		-- a generous zone around the small plate
		local zone = empty(40, 46, 96, 92, bl.node)
		list_of[#list_of + 1] = { nodo = zone, bordo = zone, colore = CLEAR, riposo = CLEAR, ui_action = back_action, piastra = h.back }
	end
	local tr = M.anchor(1280, 0, gui.ANCHOR_RIGHT, gui.ANCHOR_TOP)
	h.tops[#h.tops + 1] = tr.node
	h.top_right = tr
	piece_in(tl.node, "title")
	if h.back then piece_in(h.back.node, "back") end
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

-- TABS: small plates in a row; the active one is light.
-- tabs: { { label, ui_action }, ... }
function M.tabs(g, list_of, x, y, tabs, active, accent)
	local h, cx = 40, x
	for i, tab in ipairs(tabs) do
		local w = #tab[1] * 13 + 44
		local on = i == active
		local n = empty(cx + w / 2 - g.ox, g.oy - (y + h / 2), w, h, g.node)
		three(n, on and "piastrina_chiara" or "piastrina", w, h)
		local name = on and "piastrina_chiara" or "piastrina"
		local box = room(name, cx + w / 2, y + h / 2, w, h)
		M.text({ node = n, ox = cx + w / 2, oy = y + h / 2, box = box }, tab[1], (box.x0 + box.x1) / 2, (box.y0 + box.y1) / 2 + 7, 19,
			on and C.INK or M.with_alpha(C.SAND, 0.8), "middle", 0.5)
		list_of[#list_of + 1] = { nodo = n, bordo = n, colore = CLEAR, riposo = CLEAR, ui_action = tab[2] }
		cx = cx + w + 6 + (g.air and M.air(0.1) or 0)
	end
	M.rect(g, x - 6, y + h + 4, cx - x + 6, 3, accent or C.HOT)
	return cx
end

-- CHOICES: a small label and the options in a row on a thin line, the light
-- plate behind the chosen one. opts: { { label, ui_action }, ... }; w: an
-- option's width; off: dim, nothing to tap
function M.choice(g, list_of, x, y, label, opts, active, w, off)
	local h = 44
	if g.air then w = w + M.air(0.25) end
	M.text(g, label, x + 6, y - 10, 14, with_alpha(C.MUTE, off and 0.5 or 1), "start", 1.5)
	M.rect(g, x, y + h - 2, #opts * w, 2, with_alpha(C.LINE, 0.6))
	for i, o in ipairs(opts) do
		local ox = x + (i - 1) * w
		local on = i == active and not off
		if on then three(empty(ox + w / 2 - 6 - g.ox, g.oy - (y + h / 2), 0, 0, g.node), "piastrina_chiara", w - 12, h) end
		local box = on and room("piastrina_chiara", ox + w / 2 - 6, y + h / 2, w - 12, h) or nil
		local tx = box and (box.x0 + box.x1) / 2 or ox + w / 2
		M.text({ node = g.node, ox = g.ox, oy = g.oy, box = box }, o[1], tx, y + h / 2 + 6, #o[1] > 14 and 14 or 18, on and C.INK or with_alpha(C.MUTE, off and 0.4 or 1), "middle")
		if not off then M.zone(g, list_of, ox, y - 6, w, h + 12, o[2]) end
	end
end

-- CARDS: an iron panel with a short line in the card's color at the top left.
-- opt: sel (chosen: a warm frame), off (dim). Returns { node, g }
function M.card(g, x, y, w, h, color, opt)
	opt = opt or {}
	local cx, cy = x + w / 2, y + h / 2
	local n = empty(cx - g.ox, g.oy - cy, w, h, g.node)
	local k = { node = n, g = { node = n, ox = cx, oy = cy }, x = x, y = y, w = w, h = h }
	-- chosen: the same panel in ember, a little bigger, under it (a rim drawn by hand)
	if opt.sel then nine(n, "pannello_caldo", w + 12, h + 12, math.min(26, h * 0.34)) end
	local parts = nine(n, "pannello", w, h, math.min(22, h * 0.3))
	if opt.off then tint(parts, vmath.vector4(0.62, 0.62, 0.7, 0.8)) end
	if not opt.sel then
		M.line(k.g, x + 14, y + 7, x + math.min(64, w * 0.4), y + 7, 3, with_alpha(color, opt.off and 0.4 or 1))
	end
	card_in(n)
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
	-- in the plate's room: the name on the left, the level over its bar on the right
	local b = p.box
	local mid = (b.y0 + b.y1) / 2
	p.name = M.text(p.g, name, b.x0, mid + 7, 20, C.INK)
	local from = math.max(b.x0 + M.width(p.name) + 10, b.x1 - 150)
	p.right = M.text({ node = p.g.node, ox = p.g.ox, oy = p.g.oy, box = { x0 = from, x1 = b.x1, y0 = b.y0, y1 = b.y1 } },
		right, b.x1, b.y0 + 12, 13, with_alpha(C.INK, 0.75), "end", 1)
	p.bar = M.bar(p.g, from, b.y1 - 9, b.x1 - from, 6, f, C.HOT_BOTTOM, C.SAND_SHADOW)
	return p
end

-- ---------------------------------------------------------------- scene

-- The backdrop of a menu: the soot over the game world, a warm light at the
-- bottom left and a cold one at the top right (fire against ice, on every
-- screen), and at the bottom the thread, ember on the left and frost on the
-- right, with a spark running along it now and then. opt: bg (the screen's
-- name: for the drawings of each screen, which a thread is still choosing;
-- M.backdrop, if set, draws them), seam (false: no thread), dim (0..1: how
-- much the world behind is covered; the screens over a battle just ended).
-- There is ONE backdrop for every menu: kit.scene returns the screen's hold
-- on it; kit.scene_drop(s) when the screen goes away
local S

-- M.backdrop(name, S): hook for the per-screen drawings (not there yet)
M.backdrop = nil

local function scene_nodes()
	if S then return S end
	S = { tops = {} }
	S.base = shape(nil, 640, 360, 1280 * screen.FULL, 720 * screen.FULL, C.SOOT)
	S.tops[#S.tops + 1] = S.base
	-- the two lights, each stuck to its corner
	local warm = M.anchor(0, 720, gui.ANCHOR_LEFT, gui.ANCHOR_BOTTOM)
	S.tops[#S.tops + 1] = warm.node
	S.warm = shape("alone", 60, 40, 1500, 1300, with_alpha(C.HOT_BOTTOM, 0.2), warm.node)
	gui.set_blend_mode(S.warm, gui.BLEND_ADD)
	local cold = M.anchor(1280, 0, gui.ANCHOR_RIGHT, gui.ANCHOR_TOP)
	S.tops[#S.tops + 1] = cold.node
	S.cold = shape("alone", -60, -40, 1500, 1300, with_alpha(C.ICE, 0.16), cold.node)
	gui.set_blend_mode(S.cold, gui.BLEND_ADD)
	-- the thread (stuck to the real bottom): ink behind, the color over it
	local low = M.anchor(640, 720, nil, gui.ANCHOR_BOTTOM)
	S.tops[#S.tops + 1] = low.node
	S.low = low.node
	S.seam_ink = shape(nil, 0, 59, 1280, 8, C.INK, low.node)
	S.seam = gui.new_box_node(vec(0, 59), vec(1280, 4))
	gui.set_texture(S.seam, "fucina")
	gui.play_flipbook(S.seam, "filo")
	gui.set_parent(S.seam, low.node)
	S.spark = shape(nil, 0, 59, 26, 4, C.SEAM, low.node)
	gui.set_enabled(S.spark, false)
	local function run()
		local w = screen.width()
		gui.set_enabled(S.spark, true)
		gui.set_position(S.spark, vec(-w / 2, 59))
		gui.animate(S.spark, "position.x", w / 2, gui.EASING_INOUTSINE, 2.2, 0, function()
			gui.set_enabled(S.spark, false)
			gui.animate(S.spark, "color.w", 1, gui.EASING_LINEAR, 7, 0, run)
		end)
	end
	gui.animate(S.spark, "color.w", 1, gui.EASING_LINEAR, 3, 0, run)
	return S
end

-- The thread runs between the real edges of the screen: call it when the
-- screen is shown (the proportions may have changed)
function M.scene_fit()
	if not S then return end
	local w = screen.width()
	gui.set_size(S.seam, vec(w, 4))
	gui.set_size(S.seam_ink, vec(w, 8))
end

-- the backdrop takes the screen's place
local function claim(s)
	S.owner = s
	for _, n in ipairs(S.tops) do gui.set_enabled(n, true) end
	gui.set_color(S.base, with_alpha(C.SOOT, s.opt.dim or 1))
	gui.set_enabled(S.low, s.opt.seam ~= false)
	if M.backdrop then M.backdrop(s.opt.bg, S) end
	M.scene_fit()
end

-- The screen's backdrop, above everything made so far (what the screen
-- creates next goes over it). fx, fy: where the screen's subject is
function M.scene(fx, fy, opt)
	scene_nodes()
	local s = { fx = fx, fy = fy, opt = opt or {} }
	for _, n in ipairs(S.tops) do gui.move_above(n, nil) end
	claim(s)
	return s
end

-- The backdrop just "above" or "below" a node of the screen (a screen that
-- is kept and shown again)
function M.scene_place(s, where, ref)
	if S.owner ~= s then return end
	if where == "below" then
		for i = 1, #S.tops do gui.move_below(S.tops[i], ref) end
	else
		for i = #S.tops, 1, -1 do gui.move_above(S.tops[i], ref) end
	end
end

-- The screen's subject moves (nothing follows it, for now)
function M.scene_focus(s, fx, fy)
	s.fx, s.fy = fx, fy
end

function M.scene_drop(s)
	if not S or S.owner ~= s then return end
	S.owner = nil
	for _, n in ipairs(S.tops) do gui.set_enabled(n, false) end
end

function M.scene_show(s, on)
	if on then claim(s) else M.scene_drop(s) end
end

-- The backdrop's own entrance (when the game opens): the thread draws itself
-- from the middle
function M.scene_enter(delay)
	delay = delay or 0
	for _, n in ipairs({ S.seam, S.seam_ink }) do
		gui.cancel_animations(n, "scale.x")
		gui.set_scale(n, vmath.vector3(0.01, 1, 1))
		gui.animate(n, "scale.x", 1, gui.EASING_OUTCUBIC, 0.5, delay + 0.3)
	end
end

-- ---------------------------------------------------------------- motion

-- While a screen is being made after a transition (M.entering: the
-- gui_script sets it around the change) its pieces arrive by themselves: the
-- title from the left, the cards from the right one after the other, the
-- action pops; quickly, so that a tap finds them in place.
-- M.wait: seconds before they move
M.entering, M.wait = false, 0
local auto = {}        -- node -> where it rests, for the pieces already sent in
local stagger = 0

function M.enter_begin(wait)
	M.entering, M.wait, auto, stagger = true, wait or 0, {}, 0
end

function M.enter_end()
	M.entering, M.wait = false, 0
end

-- A piece arrives from (dx, dy) away, in `time` seconds after `delay`,
-- overshooting a little. node: any node; its resting position is the current one
function M.arrive(node, dx, dy, delay, time)
	local p = auto[node] or gui.get_position(node)
	auto[node] = M.entering and p or nil
	gui.cancel_animations(node, "position")
	gui.set_position(node, vec(p.x + dx, p.y + dy))
	gui.animate(node, "position", p, gui.EASING_OUTBACK, time or 0.32, (delay or 0) + M.wait)
	return p
end

-- A piece pops: from small to its size, overshooting
function M.pop(node, delay, time, from, done)
	gui.cancel_animations(node, "scale")
	local k = from or 0.86
	gui.set_scale(node, vmath.vector3(k, k, 1))
	gui.animate(node, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, time or 0.3, (delay or 0) + M.wait, done)
end

-- a card of a screen being made: from the right, each a little later
function card_in(node)
	if not M.entering or stagger >= 8 then return end
	M.arrive(node, 520, 0, stagger * 0.03, 0.28)
	stagger = stagger + 1
end

-- the title and the way back, from the left; the action pops (no sparks:
-- Sergio, 11 Nov, «sembrano fuochi d'artificio»; they are for the touch)
function piece_in(node, kind)
	if not M.entering then return end
	if kind == "action" then
		M.pop(node, 0.08, 0.3, 0.7)
	else
		M.arrive(node, -460, 0, kind == "back" and 0.05 or 0, 0.28)
	end
end

-- ---------------------------------------------------------------- effects

-- A burst of sparks at a point of the SCREEN (pixels, like action.screen_x):
-- n rhombi flying out and going off. Two bursts can live together
local bursts, burst_i = {}, 0
local BURST_N = 16
local burst_seed = 11
local function brnd()
	burst_seed = (burst_seed * 1664525 + 1013904223) % 4294967296
	return burst_seed / 4294967296
end

function M.burst(sx, sy, n, color)
	burst_i = burst_i % 2 + 1
	local b = bursts[burst_i]
	if not b then
		b = { root = empty(0, 0), bits = {} }
		for i = 1, BURST_N do
			b.bits[i] = shape(nil, 0, 0, 10, 10, C.HOT, b.root)
			V.x, V.y, V.z = 0, 0, 45
			gui.set_rotation(b.bits[i], V)
		end
		bursts[burst_i] = b
	end
	gui.move_above(b.root, nil)
	gui.set_screen_position(b.root, vec(sx, sy))
	n = math.min(n or 10, BURST_N)
	for i = 1, BURST_N do
		local q = b.bits[i]
		gui.cancel_animations(q, "position")
		gui.cancel_animations(q, "scale")
		gui.cancel_animations(q, "color.w")
		gui.set_enabled(q, i <= n)
		if i <= n then
			local a = (i + brnd() * 0.8) / n * math.pi * 2
			local r = 60 + brnd() * 100
			local t = 0.42 + brnd() * 0.26
			local k = 0.7 + brnd() * 0.8
			gui.set_position(q, vec(0, 0))
			gui.set_scale(q, vmath.vector3(k, k, 1))
			gui.set_color(q, color or (i % 3 == 0 and C.SAND or (i % 2 == 0 and C.HOT_TOP or C.HOT)))
			gui.animate(q, "position", vec(math.cos(a) * r, math.sin(a) * r), gui.EASING_OUTCUBIC, t)
			gui.animate(q, "scale", vmath.vector3(0.2, 0.2, 1), gui.EASING_INQUAD, t)
			gui.animate(q, "color.w", 0, gui.EASING_INQUAD, t, 0, function() gui.set_enabled(q, false) end)
		end
	end
end

-- the burst where a node is
function M.burst_at(node, n, color)
	local p = gui.get_screen_position(node)
	M.burst(p.x, p.y, n, color)
end

-- A white flash over everything, going off at once
local flash
function M.flash(a)
	if not flash then flash = shape(nil, 640, 360, 1280 * screen.FULL, 720 * screen.FULL, CLEAR) end
	gui.move_above(flash, nil)
	gui.set_enabled(flash, true)
	gui.cancel_animations(flash, "color.w")
	gui.set_color(flash, vmath.vector4(1, 1, 1, a or 0.25))
	gui.animate(flash, "color.w", 0, gui.EASING_OUTQUAD, 0.28, 0, function() gui.set_enabled(flash, false) end)
end

-- A short shake of some top-level groups (not of pieces that are arriving):
-- down, up a little, back
local shaking = {}
function M.shake(nodes, amount)
	for _, n in ipairs(nodes) do
		local y = shaking[n] or gui.get_position(n).y
		shaking[n] = y
		gui.cancel_animations(n, "position.y")
		gui.set_position(n, vmath.vector3(gui.get_position(n).x, y - amount, 0))
		gui.animate(n, "position.y", y, gui.EASING_OUTELASTIC, 0.3, 0, function() shaking[n] = nil end)
	end
end

-- Touching a plate (ui.touch): sparks under the finger, the plate bounces;
-- the main action flashes too. Only the kit's plates: the HUD in battle is not touched
ui.on_hit = function(b, action)
	if not b.piastra then return end
	if action and action.screen_x then
		M.burst(action.screen_x, action.screen_y, b.luce and 16 or 9)
	else
		M.burst_at(b.nodo, b.luce and 16 or 9)
	end
	M.pop(b.piastra.node, 0, 0.24, 0.93)
	if b.luce then M.flash(0.22) end
end

return M
