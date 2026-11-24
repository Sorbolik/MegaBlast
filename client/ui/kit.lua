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

-- the measures of the fucina atlas's pieces (ui/pieces.lua)
M.PIECES = P

-- The top nodes a screen makes (kit.anchor, ui.root) while it is tracked:
-- the passages that move a whole screen (ui/door_pass.lua)
function M.track_begin()
	M.tracking = {}
	ui.tracking = M.tracking
end
function M.tracked() return M.tracking or {} end
function M.track_end()
	M.tracking, ui.tracking = nil, nil
end

local function hex(s, a)
	return vmath.vector4(tonumber(s:sub(1, 2), 16) / 255, tonumber(s:sub(3, 4), 16) / 255, tonumber(s:sub(5, 6), 16) / 255, a or 1)
end
M.hex = hex

M.C = {
	INK = hex("0a080b"),            -- the ink: outlines, text on light plates
	SOOT = hex("121013"),           -- the dark behind everything
	SAND = hex("f4ece1"),           -- text (ivory), and the light chips and panels
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
-- The thread: its height in Figma coordinates. Under it the band with the way
-- back on the left and the screen's action on the right
M.THREAD = 612
M.BAND = 720 - M.THREAD
-- where the light plate of a screen sits in the band (the devil's name, where you are), after the way back
M.PLATE_X, M.PLATE_Y = 168, 635

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

-- The pieces whose ends do not meet at the same height (the rim of the slanted
-- plates climbs along the middle): squeezing the middle makes a step where the
-- ends meet (Sergio, 19 Nov). M.least says how narrow they can go: the ends
-- whole and 70% of the middle (the step stays under half a pixel). The
-- simulator fails on a narrower one (tools/simula/simula.py)
local SLANTED = { piastrina = true, piastrina_calda = true, piastrina_chiara = true, piastra_storta = true,
	piastra_calda = true, scheggia = true }
function M.least(name, h)
	local m = P[name]
	if not SLANTED[name] then return 0 end
	return (2 * m.c + 0.7 * (m.w - 2 * m.c)) * h / m.h
end
local narrow_told = {}
local function too_narrow(name, w, h)
	local key = name .. math.floor(w)
	if narrow_told[key] then return end
	narrow_told[key] = true
	print(("SIMULA pezzo_stretto %s %d x %d, almeno %d"):format(name, w, h, M.least(name, h)))
end

-- A long piece w x h centered on parent, in three parts: the ends keep their
-- shape (as wide as the height asks), only the middle is stretched
local function three_fit(parts, name, w, h)
	local m = P[name]
	if w < M.least(name, h) - 0.5 then too_narrow(name, w, h) end
	local cw = math.min(m.c * h / m.h, w / 2)
	gui.set_size(parts[1], vec(math.max(1, w - 2 * cw + 1), h))
	gui.set_size(parts[2], vec(cw, h)); gui.set_position(parts[2], vec(-w / 2 + cw / 2, 0))
	gui.set_size(parts[3], vec(cw, h)); gui.set_position(parts[3], vec(w / 2 - cw / 2, 0))
end

local function three(parent, name, w, h)
	local parts = { pic(name .. "_cx", 0, 0, 1, h, parent), pic(name .. "_sx", 0, 0, 1, h, parent), pic(name .. "_dx", 0, 0, 1, h, parent) }
	three_fit(parts, name, w, h)
	return parts
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

-- An iron panel w x h centered on a node (name: "pannello", "pannello_caldo", "pannello_chiaro")
function M.panel(parent, w, h, name)
	return nine(parent, name or "pannello", w, h, math.min(26, h * 0.3, w * 0.3))
end

-- A drawn plate in nine parts (the powers of the Sigilli, WB-062: name
-- "bivio_piastra_acceso" ...) filling the Figma box x..x+w, y..y+h; the corners
-- at most a third of the height. Returns { node, g } like a card
function M.drawn_plate(g, name, x, y, w, h)
	local cx, cy = x + w / 2, y + h / 2
	local n = empty(cx - g.ox, g.oy - cy, w, h, g.node)
	local c = math.min(P[name].c, h * 0.34)
	nine(n, name, w, h, c)
	return { node = n, g = { node = n, ox = cx, oy = cy }, x = x, y = y, w = w, h = h }
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

-- A paper ticket of the Smith's orders (WB-085) w x h centered on a node: the sheet
-- in nine parts, the corners 34 (the dog-ear whole), and the reinforced hole in
-- the middle of the top, where the nail goes (its middle 10 under the top)
function M.paper(parent, w, h)
	local c = math.min(34, h * 0.3, w * 0.3)
	local parts = nine(parent, "cartellino", w, h, c)
	local k = c / P.cartellino.c
	local hole = P.cartellino_foro.h * k
	parts.hole = whole("cartellino_foro", 0, h / 2 - hole / 2, hole, parent)
	return parts
end

-- A long piece in three parts filling the Figma box x..x+w, y..y+h (a row, a
-- bar): the ends whole, the middle stretched. Returns { node, parts, g }
function M.strip(g, name, x, y, w, h)
	local cx, cy = x + w / 2, y + h / 2
	local n = empty(cx - g.ox, g.oy - cy, 0, 0, g.node)
	local parts = three(n, name, w, h)
	local b = room(name, cx, cy, w, h)
	return { node = n, parts = parts, g = { node = n, ox = cx, oy = cy, box = b }, box = b, name = name, w = w, h = h }
end

-- Changes the width of a strip, keeping its left end where it is
function M.strip_width(s, w)
	three_fit(s.parts, s.name, w, s.h)
	local p = gui.get_position(s.node)
	gui.set_position(s.node, vec(p.x + (w - s.w) / 2, p.y))
	s.w = w
end

-- A whole piece filling the Figma box x..x+w, y..y+h (its drawing's shape:
-- give w and h in its proportions)
function M.pic(g, name, x, y, w, h)
	return pic(name, x + w / 2 - g.ox, g.oy - (y + h / 2), w, h, g.node)
end

-- A whole drawn button (the home's doors and GIOCA, WB-046) w wide, its top
-- left at the Figma point (x, y), as tall as its drawing: nothing is
-- stretched. Like a plate it goes down when pressed (M.press, M.button), and
-- what is written on p.g stays in the room measured on the drawing
-- (pieces.lua, box)
function M.sign(g, name, x, y, w)
	local m = P[name]
	local h = w * m.h / m.w
	local cx, cy = x + w / 2, y + h / 2
	local n = empty(cx - g.ox, g.oy - cy, w, h, g.node)
	local p = { node = n, x = x, y = y, w = w, h = h, d = 4 }
	p.face_node = empty(0, 0, 0, 0, n)
	p.pic = pic(name, 0, 0, w, h, p.face_node)
	p.g = { node = p.face_node, ox = cx, oy = cy }
	local b, k = m.box, w / m.w
	if b then
		p.box = { x0 = x + b[1] * k, x1 = x + w - b[3] * k, y0 = y + b[2] * k, y1 = y + h - b[4] * k }
		p.g.box = p.box
	end
	return p
end

-- ---------------------------------------------------------------- groups

-- A top-level group at the Figma point (x, y), optionally stuck to a real
-- edge of the screen (ui/screen.lua): only nodes without a parent do that
function M.anchor(x, y, xa, ya)
	local n = empty(x or 0, 720 - (y or 0))
	if M.tracking then M.tracking[#M.tracking + 1] = n end
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
		if opt.fill == C.SAND then name = "piastrina_chiara"
		elseif shadow == C.HOT then name = small and "piastrina_calda" or "piastra_calda"
		else name = small and "piastrina" or "piastra_storta" end
	end
	if w < h * 2 and not opt.piece then
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

-- Where a title or a line of state goes on its own, without a plate (Sergio,
-- 19 Nov: the light slanted plate is gone): the text sits, glowing, where the
-- plate's writing was, in the room of the box x..x+w+sk, y..y+h. Write on its
-- g in M.TAB_HOT, the red-hot gold of the active tab
function M.caption(g, x, y, w, h, sk)
	sk = sk or 0
	local cx, cy = x + (w + sk) / 2, y + h / 2
	local n = empty(cx - g.ox, g.oy - cy, 0, 0, g.node)
	local box = room("piastra_storta", cx, cy, w + sk, h)
	return { node = n, g = { node = n, ox = cx, oy = cy, box = box }, box = box }
end

-- The light small plate behind what is chosen (a tab, an option): the box
-- x..x+w+sk, y..y+h
function M.light(g, x, y, w, h, sk)
	local n = empty(x + (w + (sk or 0)) / 2 - g.ox, g.oy - (y + h / 2), 0, 0, g.node)
	three(n, "piastrina_chiara", w + (sk or 0) + 8, h + 6)
	return n
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

-- The smallest text of the menus (Sergio, 15 Nov: everything at the size of a
-- phone): the one place to change it; M.text never writes smaller
M.MIN_TEXT = 16

-- A text shrunk to fit its room must not go under MIN_TEXT: the simulator fails
-- on this line (tools/simula/simula.py), once for each text
local told = {}
function M.check_small(n)
	local size = gui.get_scale(n).x * FONT_SIZE
	if size >= M.MIN_TEXT - 0.5 then return end
	local t = gui.get_text(n)
	if told[t] then return end
	told[t] = true
	print(("SIMULA testo_piccolo %.1f px: %s"):format(size, t))
end

-- Text of `size` pixels on the baseline (x, y). anchor: "start" (default),
-- "middle", "end". spacing: extra pixels between letters
function M.text(g, t, x, y, size, color, anchor, spacing)
	size = math.max(size, M.MIN_TEXT)
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
	M.check_small(n)
end

-- game.gui_script says when you are in the queue (M.in_queue); the pill sits on
-- the thread (ui/pill.lua), the band under it stays free
M.in_queue = false

-- A line of the footer, left of the action, starting at x of g (stuck to the
-- left edge): as wide as `wide` at most; in the queue it stops before the pill
-- and goes on a second line under it (Sergio, 15 Nov). Returns the lines
function M.foot_text(g, t, x, y, size, color, wide, spacing)
	local room = wide
	local function one(txt, ly)
		local n = M.text(g, txt, x, ly, size, color, "start", spacing)
		local w = M.width(n)
		if w > room then gui.set_scale(n, gui.get_scale(n) * (room / w)); M.check_small(n) end
		return n
	end
	local n = M.text(g, t, x, y, size, color, "start", spacing)
	if M.width(n) <= room or not M.in_queue then
		local w = M.width(n)
		if w > room then gui.set_scale(n, gui.get_scale(n) * (room / w)); M.check_small(n) end
		return { n }
	end
	gui.delete_node(n)
	-- the cut nearest the middle: after a " · ", or else a space
	local best, mid = nil, #t / 2
	for _, sep in ipairs({ " · ", " " }) do
		local i = 1
		while true do
			local a, b = t:find(sep, i, true)
			if not a then break end
			if not best or math.abs(a - mid) < math.abs(best[1] - mid) then best = { a, b } end
			i = b + 1
		end
		if best then break end
	end
	if not best then return { one(t, y) } end
	return { one(t:sub(1, best[1] - 1), y), one(t:sub(best[2] + 1), y + size + 2) }
end

-- The lines of a text that stay `wide` at that size, word by word (a word
-- wider than that stays alone on its line: shrink it)
function M.wrap(g, t, size, wide)
	local function measure(txt)
		local n = M.text(g, txt, 0, 0, size)
		local w = M.width(n)
		gui.delete_node(n)
		return w
	end
	local lines = {}
	for word in t:gmatch("%S+") do
		local try = lines[#lines] and (lines[#lines] .. " " .. word)
		if try and measure(try) <= wide then lines[#lines] = try else lines[#lines + 1] = word end
	end
	return lines
end

-- Capitals, the accented letters too (string.upper leaves them small)
local ACCENTS = { ["à"] = "À", ["è"] = "È", ["é"] = "É", ["ì"] = "Ì", ["ò"] = "Ò", ["ù"] = "Ù" }
function M.upper(t)
	return (string.upper(t):gsub("\195[\160-\191]", ACCENTS))
end

-- How wide a text node is, in pixels
function M.width(n)
	-- with its letter spacing, or a spaced text would go past its room
	local m = resource.get_text_metrics(gui.get_font_resource(gui.get_font(n)), gui.get_text(n), { tracking = gui.get_tracking(n) })
	return m.width * gui.get_scale(n).x
end

-- ---------------------------------------------------------------- progress

-- n small slanted notches, the first `lit` in color
function M.pips(g, x, y, n, lit, color)
	local list_of = {}
	for i = 0, n - 1 do
		-- the ivory notch of the fucina atlas, in its color (kit.tint(q.parts, ...) changes it)
		local q = whole("tacca", x + i * 15 + 8 - g.ox, g.oy - (y + 8), 19, g.node)
		gui.set_color(q, i < lit and color or C.LINE)
		list_of[#list_of + 1] = { node = q, parts = { q } }
	end
	return list_of
end

-- A bar filled to f (0..1): the iron trough and in it a strip of ember (warm
-- colors), of frost (cold ones) or, any other color, the plain strip tinted.
-- M.bar_fill(b, f) changes how full it is
-- The bars (Sergio, 23 Nov, docs/ui-catalogo.md, purpose 10): every bar is the
-- groove and the strip of the home's experience (WB-075): the groove drawn in
-- vectors (solco), the strip ember as it is drawn or, for the other colors, its
-- colorless twin tinted. The strip fills the dark bottom of the groove: from 8
-- to 27 of its 32 sixteenths
local GROOVE_TOP, GROOVE_IN, GROOVE_END = 8 / 32, 19 / 32, 3 / 32
local function strip_of(color)
	if color == C.HOT or color == C.HOT_BOTTOM or color == C.HOT_TOP or color == C.STAR then
		return "barra_stendardo"
	end
	return "barra_stendardo_chiara"
end

-- The groove around the box x..x+w, y..y+h (the strip's place)
function M.groove(g, x, y, w, h)
	local gh = h / GROOVE_IN
	local pad = gh * GROOVE_END
	local cy = y - gh * GROOVE_TOP + gh / 2
	local n = empty(x + w / 2 - g.ox, g.oy - cy, 0, 0, g.node)
	three(n, "solco", w + 2 * pad, gh)
	return n
end

function M.bar_fill(b, f)
	f = math.max(0, math.min(1, f))
	gui.set_enabled(b.front.node, f > 0.005)
	local w = math.max(b.h, b.w * f)
	three_fit(b.front.parts, b.strip, w, b.h)
	gui.set_position(b.front.node, vec(b.x + w / 2 - b.g.ox, b.g.oy - (b.y + b.h / 2)))
end

function M.bar(g, x, y, w, h, f, color)
	local b = { g = g, x = x, y = y, w = w, h = h, color = color, strip = strip_of(color) }
	local cx, cy = x + w / 2 - g.ox, g.oy - (y + h / 2)
	b.back = { node = M.groove(g, x, y, w, h) }
	b.front = { node = empty(cx, cy, 0, 0, g.node) }
	b.front.parts = three(b.front.node, b.strip, w, h)
	if b.strip == "barra_stendardo_chiara" then tint(b.front.parts, color) end
	M.bar_fill(b, f)
	return b
end

-- A bar in parts (the stats: base, level, pieces, Sigilli): one strip from 0 to
-- the last part's end, each part its own color. parts: { { x1, x2, color }, ... }
-- in pixels from x, in order. The ends are the strip's round caps
function M.bar_parts(g, x, y, w, h, parts)
	M.groove(g, x, y, w, h)
	local last = 0
	for _, q in ipairs(parts) do last = math.max(last, q[2]) end
	if last <= 0 then return end
	local m = P.barra_stendardo_chiara
	local cw = math.min(m.c * h / m.h, last / 2)
	for i, q in ipairs(parts) do
		local x1, x2 = q[1], q[2]
		if x2 > x1 then
			-- the middle of the strip over this part, the caps at the two ends (ember
			-- as drawn, the other colors on the colorless strip)
			local name = strip_of(q[3])
			local color = name == "barra_stendardo" and vmath.vector4(1, 1, 1, 1) or q[3]
			local a, z = math.max(x1, cw), math.min(x2, last - cw)
			if z > a then gui.set_color(pic(name .. "_cx", x + (a + z) / 2 - g.ox, g.oy - (y + h / 2), z - a + 0.5, h, g.node), color) end
			if x1 < cw then gui.set_color(pic(name .. "_sx", x + cw / 2 - g.ox, g.oy - (y + h / 2), cw, h, g.node), color) end
			if x2 > last - cw then gui.set_color(pic(name .. "_dx", x + last - cw / 2 - g.ox, g.oy - (y + h / 2), cw, h, g.node), color) end
		end
	end
end

-- ---------------------------------------------------------------- buttons

-- Makes a plate a button of list_of (ui.touch, the controller's light)
function M.button(list_of, p, ui_action, opt)
	local b = { nodo = p.node, bordo = p.node, colore = CLEAR, riposo = CLEAR, ui_action = ui_action, piastra = p,
		spento = opt and opt.spento, luce = opt and opt.main and p.node or nil, on_press = p.on_press }
	list_of[#list_of + 1] = b
	return b
end

-- The buttons (Sergio, 23 Nov, docs/ui-catalogo.md, purposes 1 and 2): one slab
-- for all, the «Ferro liscio» drawn in tools/grafica/fucina.py, the same height
-- side by side, each with its big icon sticking out of its left end. The main
-- action is the same slab in red-hot iron (principale_*), the others dark iron
-- (secondario_*). Four drawings: lit, lighter (the mouse or the controller's
-- light on it: ui.lua, on_light), pressed (the finger on it), off (cold grey
-- iron: it can't be done now, and the short line under the label says why).

-- At the bottom right, under the thread: the main action's place on every screen
local FOOT = { x = 948, y = 640, w = 308, h = 62 }

-- (x, y) its top left, w x h. opt: icon, sub, sub_color, off, main, size (of the
-- label). Returns the plate for M.button
function M.secondary(g, label, x, y, w, h, opt)
	opt = opt or {}
	local kind = opt.main and "principale_" or "secondario_"
	local cx, cy = x + w / 2, y + h / 2
	local n = empty(cx - g.ox, g.oy - cy, w, h, g.node)
	local p = { node = n, g = { node = n, ox = cx, oy = cy }, x = x, y = y, w = w, h = h }
	local k = h / P[kind .. "acceso"].h
	-- one slab of three nodes: a state change swaps its drawings (four looks of
	-- nodes each filled the GUI's buffer in the ZAINO, Sergio 24 Nov)
	local slab, parts = empty(0, 0, 0, 0, n), nil
	local function look(state)
		local name = kind .. state
		local sh = P[name].h * k
		gui.set_position(slab, vec(0, (sh - h) / 2))
		if not parts then
			parts = three(slab, name, w, sh)
			return
		end
		for i, part in ipairs({ "_cx", "_sx", "_dx" }) do gui.play_flipbook(parts[i], name .. part) end
		three_fit(parts, name, w, sh)
	end
	look(opt.off and "spento" or "acceso")
	-- the face: what moves down when pressed (the icon and the words)
	p.face_node = empty(0, 0, 0, 0, n)
	local f = { node = p.face_node, ox = cx, oy = cy }
	-- the coin or icon sticks out of the left end, big and a little crooked, with
	-- its flat ink shadow on the iron (Sergio, 18 Nov: «moneta che sporge»)
	if opt.icon then
		local ix, iy, ih = x + h * 0.36, y + h * 0.44, h * 1.18
		local sh = M.piece(f, opt.icon, ix + 3, iy + 4, ih)
		gui.set_color(sh, C.INK)
		local ic = M.piece(f, opt.icon, ix, iy, ih)
		for _, n in ipairs({ sh, ic }) do gui.set_rotation(n, vmath.vector3(0, 0, 10)) end
		if opt.off then gui.set_color(ic, vmath.vector4(0.45, 0.45, 0.5, 1)) end
	end
	-- the words after the icon; without one (its icon still to come) in the middle
	local box = room(kind .. "acceso", cx, cy, w, h)
	local x0 = opt.icon and box and box.x0 or x + h * 0.4
	local x1 = box and box.x1 or x + w - 12
	local room_w = x1 - x0
	local tx, align = opt.icon and x0 or (x0 + x1) / 2, opt.icon and "start" or "middle"
	local ink = opt.off and with_alpha(C.SAND, 0.45) or C.SAND
	local size = math.max(M.MIN_TEXT, math.min(opt.size or 20, h * (opt.sub and 0.34 or 0.42)))
	local lt = M.text(f, label, tx, opt.sub and y + h * 0.48 or y + h / 2 + size * 0.36, size, ink, align, 0.5)
	local full = gui.get_scale(lt)
	-- another label on the same button (the vignette: AVANTI, then VAI!)
	p.set_label = function(t)
		gui.set_text(lt, t)
		gui.set_scale(lt, full)
		if M.width(lt) > room_w then gui.set_scale(lt, full * (room_w / M.width(lt))); M.check_small(lt) end
	end
	p.set_label(label)
	p.label = lt
	if opt.sub then
		local st = M.text(f, opt.sub, tx, y + h * 0.8, 16, opt.off and with_alpha(C.MUTE, 0.7) or opt.sub_color or (opt.main and C.HOT or C.MUTE), align, 0.5)
		if M.width(st) > room_w then gui.set_scale(st, gui.get_scale(st) * (room_w / M.width(st))) end
		p.sub = st
	end
	if not opt.off then
		local down_now, lit_now = false, false
		local shown = "acceso"
		local function show()
			local state = down_now and "premuto" or lit_now and "chiaro" or "acceso"
			if state ~= shown then shown = state; look(state) end
		end
		p.on_press = function(down)
			down_now = down
			show()
			gui.set_position(p.face_node, vec(0, down and -3 or 0))
		end
		p.on_light = function(on)
			lit_now = on
			show()
		end
	end
	return p
end

-- The main action: the red-hot slab. At the bottom right (y from 540) it takes
-- its place under the thread, as tall as the others beside it; higher (the
-- vignette, a weapon's sheet) it is drawn where asked, w x h
function M.action(g, label, x, y, w, h, opt)
	opt = opt or {}
	if y >= 540 then x, y, w, h = FOOT.x, FOOT.y, FOOT.w, FOOT.h end
	local o = {}
	for k, v in pairs(opt) do o[k] = v end
	o.main = true
	o.size = opt.size and math.min(opt.size, 30) or 30
	return M.secondary(g, label, x, y, w, h, o)
end

-- A secondary button centered at (x, y) of a node (GUI coordinates, like the old
-- ui.button: the wheel of the battle, ESCI of the draft). Returns its node and plate
function M.button_at(list_of, x, y, w, h, label, ui_action, icon, parent)
	local p = M.secondary({ node = parent, ox = 0, oy = 0 }, label, x - w / 2, -y - h / 2, w, h, { icon = icon })
	M.button(list_of, p, ui_action)
	return p.node, p
end

-- A plate goes down when pressed, and comes back
function M.press(p, down)
	-- (the slabs have their own pressed drawing: M.secondary, on_press)
	if not p.d then return end
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
		-- big, under the thread: the thumb finds it without looking
		local bn = empty(74, 62, 114, 76, bl.node)
		h.back = { node = bn, face_node = empty(0, 0, 0, 0, bn), d = 5, g = { node = bn, ox = 74, oy = 658 } }
		whole("indietro", 0, 0, 76, h.back.face_node)
		-- the little white arrow, one piece with a clean tip (tools/grafica/fucina.py, freccina)
		whole("freccina", -2, 0, 36, h.back.face_node)
		M.text(bl, from or "", 74, 713, 16, C.MUTE, "middle", 1)
		-- the whole corner takes the tap
		local zone = empty(76, M.BAND / 2, 152, M.BAND, bl.node)
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

-- A round dot d wide centered at the Figma point (cx, cy)
function M.dot(g, cx, cy, d, color)
	return shape("disco", cx - g.ox, g.oy - cy, d, d, color, g.node)
end

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
-- tag: the tabs next to the title (ZAINO, ARMERIA, PROFILO, EVENTI): no plate
-- at all (Sergio, 18 Nov: the light plates looked like buttons and like
-- labels at once), only the words: the active one red-hot gold over a glow,
-- the others cold grey-ice. Changing tab, the glow slides from the old one to
-- the new one
local tab_line = {}
local TAB_HOT, TAB_COLD = vmath.vector4(1, 0.76, 0.23, 1), vmath.vector4(0.56, 0.64, 0.7, 1)

-- One word like an open or closed tab, centered at mid, its baseline at base: red-hot
-- over a flat ember glow, or cold (the choices, the loadouts: no light plates)
function M.hot_word(g, t, mid, base, on, size_on, size_off)
	if on then
		local glow = shape("alone", mid - g.ox, g.oy - (base - size_on * 0.36), #t * size_on * 0.7 + 60, size_on * 2.2,
			with_alpha(C.HOT_BOTTOM, 0.5), g.node)
		gui.set_blend_mode(glow, gui.BLEND_ADD)
	end
	return M.text(g, t, mid, base, on and size_on or size_off, on and TAB_HOT or TAB_COLD, "middle", 1)
end
M.TAB_HOT, M.TAB_COLD = TAB_HOT, TAB_COLD

-- the slant of the blade's cut across the tags (degrees, up to the right)
M.CUT_SLANT = 1.6

-- one side of a cut word: a stencil as wide as the word, its edge on the cut
-- line, with a copy of the text inside (kept where it was on the screen)
local function cut_half(g, text, mid, cut_y, w, up, size, color)
	local clip = gui.new_box_node(vec(mid - g.ox, g.oy - (cut_y + (up and -50 or 50))), vec(w, 100))
	gui.set_adjust_mode(clip, gui.ADJUST_FIT)
	gui.set_clipping_mode(clip, gui.CLIPPING_MODE_STENCIL)
	gui.set_clipping_visible(clip, false)
	gui.set_parent(clip, g.node)
	gui.set_rotation(clip, vec(0, 0, M.CUT_SLANT))
	-- the text where it was, turned back by as much as the stencil is turned
	local n = M.text(g, text[1], text[2], text[3], size, color, "middle", 1)
	local d = gui.get_position(n) - gui.get_position(clip)
	local a = -math.rad(M.CUT_SLANT)
	gui.set_parent(n, clip)
	gui.set_position(n, vec(d.x * math.cos(a) - d.y * math.sin(a), d.x * math.sin(a) + d.y * math.cos(a)))
	gui.set_rotation(n, vec(0, 0, -M.CUT_SLANT))
	return clip, n
end

-- cut: a table, when the tags are cut through by the blade (the ARMERIA in the
-- ZAINO, Sergio 18 Nov): the open word cold, in two halves along a slanted line, the
-- others whole (Sergio, 19 Nov: only INVENTARIO); cut[i] = { top, bottom, top_text, bottom_text, mid }
function M.tabs(g, list_of, x, y, tabs, active, accent, tag, cut)
	-- every tab is the incandescent word (Sergio, 23 Nov: Campagna and Allenamento too,
	-- docs/ui-catalogo.md purpose 5); the plates below stay only for the record
	tag = true
	local h, cx = tag and 50 or 58, x
	local key = tag and tabs[1] and tabs[1][2]
	for i, tab in ipairs(tabs) do
		local on = i == active
		if tag then
			-- each word in the room its plate had (the taps stay where they were); the
			-- open one is red-hot metal, gold over a glow of ember, the others cold
			-- grey-ice (Sergio, 18 Nov, proposal C · Scritta incandescente)
			local slot = #tab[1] * 14 + 64
			local mid = cx + slot / 2
			if cut and on then
				local size, base = 30, y + 37
				-- each word cut through its own middle (a long slant would miss the last one)
				local cut_y = base - size * 0.36
				local text = { tab[1], mid, base }
				local top, tt = cut_half(g, text, mid, cut_y, slot + 40, true, size, TAB_COLD)
				local bottom, bt = cut_half(g, text, mid, cut_y, slot + 40, false, size, TAB_COLD)
				cut[#cut + 1] = { top = top, bottom = bottom, top_text = tt, bottom_text = bt, mid = mid, cut_y = cut_y }
			elseif on then
				local glow = shape("alone", mid - g.ox, g.oy - (y + 26), #tab[1] * 22 + 80, 70, with_alpha(C.HOT_BOTTOM, 0.55), g.node)
				gui.set_blend_mode(glow, gui.BLEND_ADD)
				local last = tab_line[key]
				if last and last ~= mid then
					-- from where it was, across to the new one
					local to = gui.get_position(glow)
					gui.set_position(glow, to + vec(last - mid, 0))
					gui.animate(glow, "position", to, gui.EASING_OUTCUBIC, 0.22)
				end
				tab_line[key] = mid
				M.text(g, tab[1], mid, y + 37, 30, TAB_HOT, "middle", 1)
			else
				M.text(g, tab[1], mid, y + 35, 22, TAB_COLD, "middle", 1)
			end
			M.zone(g, list_of, cx, y, slot, h, tab[2])
			cx = cx + slot + 8 + (g.air and M.air(0.1) or 0)
		end
	end
	return cx
end

-- CHOICES: a small label and the options in a row, the chosen one red-hot. opts: { { label, ui_action }, ... }; w: an
-- option's width; off: dim, nothing to tap
function M.choice(g, list_of, x, y, label, opts, active, w, off)
	local h = 58
	if g.air then w = w + M.air(0.25) end
	-- the label nearer its own row than the one above (Sergio, 17 Nov)
	M.text(g, label, x + 6, y - 6, 16, with_alpha(C.MUTE, off and 0.5 or 1), "start", 1.5)
	for i, o in ipairs(opts) do
		local ox = x + (i - 1) * w
		local on = i == active and not off
		-- every option is a word like the tabs (Sergio, 23 Nov, no light plates): the
		-- chosen one red-hot over its ember glow, the others cold
		local mid = ox + w / 2 - 4
		if on then
			local glow = shape("alone", mid - g.ox, g.oy - (y + h / 2 - 4), #o[1] * 18 + 70, 60, with_alpha(C.HOT_BOTTOM, 0.5), g.node)
			gui.set_blend_mode(glow, gui.BLEND_ADD)
		end
		local t = M.text(g, o[1], mid, y + h / 2 + (on and 9 or 7), on and 26 or 21,
			on and TAB_HOT or with_alpha(TAB_COLD, off and 0.4 or 1), "middle", 1)
		if M.width(t) > w - 12 then gui.set_scale(t, gui.get_scale(t) * ((w - 12) / M.width(t))); M.check_small(t) end
		if not off then M.zone(g, list_of, ox, y - 4, w, h + 8, o[2]) end
	end
end

-- CARDS: an iron panel with a short line in the card's color at the top left.
-- opt: sel (chosen: a warm frame), off (dim). Returns { node, g }
function M.card(g, x, y, w, h, color, opt)
	opt = opt or {}
	local cx, cy = x + w / 2, y + h / 2
	local n = empty(cx - g.ox, g.oy - cy, w, h, g.node)
	local k = { node = n, g = { node = n, ox = cx, oy = cy }, x = x, y = y, w = w, h = h }
	-- the minimal card (tools/grafica/fucina.py, fai_card_filo): its thread says the
	-- state, gold the chosen one, ice an event, ember, off a closed one
	local name = opt.sel and "pannello_caldo" or opt.off and "pannello_spento"
		or opt.kind and "pannello_" .. opt.kind or "pannello"
	k.parts = nine(n, name, w, h, math.min(22, h * 0.3))
	return k
end

-- The cards of GIOCA ONLINE: the minimal card like every other (Sergio, 23 Nov),
-- its thread by what they are: kind "brace" and "ferro" (a mode: iron at rest),
-- "gelo" (an event: ice), "spenta" (not yet open). opt.sel: the chosen one (gold)
local MODE_KIND = { brace = nil, ferro = nil, gelo = "gelo" }
function M.mode_card(g, x, y, w, h, kind, opt)
	opt = opt or {}
	return M.card(g, x, y, w, h, nil, { sel = opt.sel, off = kind == "spenta", kind = MODE_KIND[kind] })
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

-- INFORMATION: something to read, not to press: no box at all (Sergio, 12
-- Nov: «piuttosto lascia le cose senza box»). Returns an empty node there
function M.info(g, x, y, w, h)
	return empty(x + w / 2 - g.ox, g.oy - (y + h / 2), w, h, g.node)
end

-- LABELS: a small blade and the name in color
-- how wide the backed label of the word t is
function M.label_width(t)
	local n = gui.new_text_node(vec(0, 0), t)
	gui.set_font(n, "titolo")
	local m = resource.get_text_metrics(gui.get_font_resource(gui.get_font(n)), t, { tracking = 1 / 16 })
	gui.delete_node(n)
	return math.ceil(m.width * 16 / FONT_SIZE) + 40
end

-- A thin thread around a word on the dark (Sergio, 23 Nov: labels and filters, no
-- plates): the box x..x+w, y..y+h, the thread in color. Returns its node
function M.thread_chip(g, x, y, w, h, color)
	local n = empty(x + w / 2 - g.ox, g.oy - (y + h / 2), w, h, g.node)
	three(n, "filo_fondo", w, h)
	tint(three(n, "filo_bordo", w, h), color)
	return n
end

function M.label(g, x, y, t, color, backed)
	if backed then
		-- on a picture: the word in a thin thread of its color
		local w, h = M.label_width(t) - 8, 30
		local cx, cy = x - 8 + w / 2, y + h / 2
		local n = M.thread_chip(g, x - 8, y, w, h, color)
		return M.text({ node = n, ox = cx, oy = cy }, t, cx, cy + 6, 16, color, "middle", 1)
	end
	return M.text(g, t, x, y + 18, 16, color, "start", 1.2)
end

-- A section's small heading
function M.heading(g, t, x, y, color)
	return M.text(g, t, x, y, 17, color or C.HOT_TOP, "start", 1.5)
end

-- REGULATORS: the small controls inside a screen are round irons: "−" and
-- "+" (Sergio, 10 Nov), big enough for a thumb. off_minus, off_plus: that
-- side can't be used
function M.stepper(g, list_of, x, y, minus, plus, off_minus, off_plus, value)
	local d = 56
	local w = d * 2 + (value and 56 or 12)
	local n = empty(x + w / 2 - g.ox, g.oy - (y + d / 2), w, d, g.node)
	local sg = { node = n, ox = x + w / 2, oy = y + d / 2 }
	for _, side in ipairs({ { x + d / 2, "−", off_minus, minus }, { x + w - d / 2, "+", off_plus, plus } }) do
		local q = whole("tondo_ferro", side[1] - sg.ox, 0, d, n)
		if side[3] then gui.set_color(q, vmath.vector4(1, 1, 1, 0.4)) end
		M.text(sg, side[2], side[1], y + d / 2 + 11, 32, side[3] and C.LINE or C.SAND, "middle")
		local z = M.zone(sg, list_of, side[1] - d / 2 - 4, y - 4, d + 8, d + 8, side[4])
		z.spento = side[3] or nil
	end
	if value then M.text(sg, tostring(value), x + w / 2, y + d / 2 + 9, 24, C.SAND, "middle") end
	return n
end

-- A round button inside a card (QUI): a regulator, not a plate
function M.round(g, list_of, cx, cy, label, ui_action)
	local n = empty(cx - g.ox, g.oy - cy, 60, 60, g.node)
	whole("tondo_ferro", 0, 0, 58, n)
	M.text({ node = n, ox = cx, oy = cy }, label, cx, cy + 6, 16, C.SAND, "middle", 0.5)
	local b = { nodo = n, bordo = n, colore = CLEAR, riposo = CLEAR, ui_action = ui_action }
	list_of[#list_of + 1] = b
	return b
end

-- ---------------------------------------------------------------- scene

-- The backdrop of a menu: the soot over the game world, a warm light at the
-- bottom left and a cold one at the top right (fire against ice, on every
-- screen), and at the bottom the thread, ember on the left and frost on the
-- right, with a spark running along it now and then. opt: bg (the screen's
-- painting of the place reached: true), seam (false: no thread), dim (0..1: how
-- much the world behind is covered; the screens over a battle just ended), over
-- (a scene in front of a screen that stays: its own copy, M.scene).
-- There is ONE backdrop for every menu: kit.scene returns the screen's hold
-- on it; kit.scene_drop(s) when the screen goes away
local S

-- The painting behind every screen (ui/backdrops.lua): the place of the
-- campaign the player has reached (Sergio, 13 Nov; WB-030/031, comic style,
-- big masses at the sides, the middle empty). Only one is loaded at a time.
-- It covers the screen keeping its shape (never stretched: on a long screen
-- it grows and loses a little at the top), its painted floor on the thread
local BACKDROPS = require "ui.backdrops"
-- the flat backdrops made in code (ui/flat_backdrops.lua): opt.bg is their name
local FLAT = require "ui.flat_backdrops"
local THREAD_Y = M.BAND

-- the place of each chapter of the campaign (its id in sim/campaign.lua)
local PLACES = { addestramento = "cortile", girone_1 = "forgia" }
local PLACE = "cortile"

-- The painting a screen asks for: opt.bg true is the place reached, a name is
-- the screen's flat backdrop (ui/flat_backdrops.lua, no painting); false or nil: none
local function painting_of(on)
	return on == true and PLACE or nil
end

-- its texture, loaded if it isn't (each painting has its own: a copy of the
-- backdrop may keep the one of the screen under it, M.scene_copy)
local function load_painting(name)
	local id = "sfondo_" .. name
	if S.loaded[name] then return id end
	local data = sys.load_resource("/paintings/backdrops/" .. name .. ".jpg")
	local img = data and image.load(data)
	if img and gui.new_texture(id, img.width, img.height, img.type, img.buffer) then
		S.loaded[name] = true
		return id
	end
end

local function unload_painting(name)
	if name and S.loaded[name] and name ~= S.bg_name and name ~= S.kept then
		gui.delete_texture("sfondo_" .. name)
		S.loaded[name] = nil
	end
end

-- the flat backdrop of the screen (nil: none), under the thread like the painting
-- fade: seconds for the new theme to come in over the old one (the ARMERIA in the ZAINO)
local function flat_backdrop(on, fade)
	local name = FLAT.has(on) and on or nil
	if S.flat_name == name then return end
	-- one going away from a crossfade before: gone now
	if S.fading then
		FLAT.drop(S.fading[1], S.fading[2])
		S.fading = nil
	end
	local old, old_timer = S.flat, S.flat_timer
	if not (fade and old and name) then
		FLAT.drop(old, old_timer)
		old = nil
	end
	S.flat, S.flat_timer, S.flat_name = nil, nil, name
	if not name then return end
	S.flat, S.flat_timer = FLAT.make(name, S.clip or S.back, THREAD_Y, C.SOOT, true)
	if S.clip then
		local p = gui.get_position(S.flat)
		gui.set_position(S.flat, vec(p.x, p.y - 360))
	end
	if old then
		-- made after the old one, so over it: it comes in, then the old one goes
		local going = { old, old_timer }
		S.fading = going
		gui.set_color(S.flat, vmath.vector4(1, 1, 1, 0))
		gui.animate(S.flat, "color.w", 1, gui.EASING_OUTQUAD, fade, 0, function()
			if S.fading == going then
				FLAT.drop(old, old_timer)
				S.fading = nil
			end
		end)
	end
end

-- on: the screen's painting (false: only the soot, over a battle)
local function backdrop(on, fade)
	flat_backdrop(on, fade)
	local name = painting_of(on)
	if S.bg_name ~= name then
		local old = S.bg_name
		S.bg_name = nil
		local id = name and load_painting(name)
		if id then
			S.bg_name = name
			gui.set_texture(S.bg, id)
		else
			gui.set_texture(S.bg, "ui")
		end
		unload_painting(old)
	end
	local shown = S.bg_name ~= nil
	gui.set_enabled(S.bg, shown)
	shown = shown or S.flat_name ~= nil
	-- the two lights are in the painting already
	gui.set_enabled(S.warm, not shown)
	gui.set_enabled(S.cold, not shown)
end

-- where the painting goes: it covers the real screen, whatever its shape: wide
-- enough, tall enough above its floor, and a little more
local function painting_box(name)
	local f = BACKDROPS[name]
	local h = math.max(720 * 1.14, screen.width() * 1.02 * 9 / 16, (screen.height() - THREAD_Y) / (1 - f) * 1.01)
	return vec(h * 16 / 9, h), vec(0, THREAD_Y - f * h + h / 2)
end

local function backdrop_fit()
	if not S.bg_name then return end
	local size, at = painting_box(S.bg_name)
	gui.set_size(S.bg, size)
	gui.set_position(S.bg, at)
end

-- a light dark veil over every painting, so it never steals the scene
-- (Sergio, 15 Nov: «solo una lieve opacizzazione»)
local VEIL = vmath.vector4(0.8, 0.8, 0.8, 1)

local function scene_nodes()
	if S then return S end
	S = { tops = {}, loaded = {} }
	S.base = shape(nil, 640, 360, 1280 * screen.FULL, 720 * screen.FULL, C.SOOT)
	S.tops[#S.tops + 1] = S.base
	-- the painting, stuck to the real bottom like the thread
	local back = M.anchor(640, 720, nil, gui.ANCHOR_BOTTOM)
	S.tops[#S.tops + 1] = back.node
	S.bg = gui.new_box_node(vec(0, 360), vec(1280, 720))
	gui.set_color(S.bg, VEIL)
	gui.set_parent(S.bg, back.node)
	gui.set_enabled(S.bg, false)
	S.back = back.node
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
	S.seam_ink = shape(nil, 0, THREAD_Y, 1280, 11, C.INK, low.node)
	S.seam = gui.new_box_node(vec(0, THREAD_Y), vec(1280, 6))
	gui.set_texture(S.seam, "fucina")
	gui.play_flipbook(S.seam, "filo")
	gui.set_parent(S.seam, low.node)
	-- the thread is alive (Sergio, 12 Nov): it breathes, and two glints run
	-- along it without stopping, an ember from the left and a frost from the right
	gui.animate(S.seam, "color", vmath.vector4(0.72, 0.72, 0.72, 1), gui.EASING_INOUTSINE, 1.6, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
	S.glints = {}
	for i, c in ipairs({ C.SEAM, C.FROST }) do
		local q = shape("alone", 0, THREAD_Y, 260, 30, with_alpha(c, 0.95), low.node)
		gui.set_blend_mode(q, gui.BLEND_ADD)
		S.glints[i] = q
	end
	return S
end

-- the two glints along a thread w wide, one from each side, without stopping
local function run_glints(glints, w)
	for i, q in ipairs(glints) do
		local from = (i == 1 and -1 or 1) * (w / 2 + 130)
		gui.cancel_animations(q, "position.x")
		gui.set_position(q, vec(from, THREAD_Y))
		gui.animate(q, "position.x", -from, gui.EASING_INOUTSINE, 4.2, (i - 1) * 2.1, nil, gui.PLAYBACK_LOOP_FORWARD)
	end
end

-- The thread runs between the real edges of the screen: call it when the
-- screen is shown (the proportions may have changed)
function M.scene_fit()
	if not S then return end
	local w = screen.width()
	backdrop_fit()
	if S.fit_w == w then return end
	S.fit_w = w
	-- a flat backdrop stuck to the real edges is made again
	if S.flat_name and FLAT.follows_width(S.flat_name) then
		local name = S.flat_name
		flat_backdrop(nil)
		flat_backdrop(name)
	end
	gui.set_size(S.seam, vec(w, 6))
	gui.set_size(S.seam_ink, vec(w, 11))
	run_glints(S.glints, w)
end

-- the backdrop takes the screen's place
local function claim(s)
	S.owner = s
	for _, n in ipairs(S.tops) do gui.set_enabled(n, true) end
	gui.set_color(S.base, with_alpha(C.SOOT, s.opt.dim or 1))
	gui.set_enabled(S.low, s.opt.seam ~= false)
	backdrop(not s.opt.dim and s.opt.bg)
	M.scene_fit()
end

-- The chapter of the campaign the player has reached (its id in
-- sim/campaign.lua): its place gives the backdrop of every screen. In the
-- scenarios "imposta prova_luogo limbo" picks the place
function M.reached(chapter_id)
	local place = sys.get_config_string("megablast.prova_luogo", "")
	if place == "" or not BACKDROPS[place] then place = PLACES[chapter_id] or PLACE end
	if place == PLACE then return end
	PLACE = place
	if S and S.owner then backdrop(not S.owner.opt.dim and S.owner.opt.bg); M.scene_fit() end
end

-- The screen's backdrop, above everything made so far (what the screen
-- creates next goes over it). fx, fy: where the screen's subject is
-- opt.over: a scene in front of a screen that stays (the step of a piece, a
-- mission's postcard) gets its own copy of the backdrop, above everything, and
-- leaves the real one to the screen under it: taken and dropped, the screen
-- under it would stay without its backdrop, and the doors of the home would
-- drag it disabled (an animation doesn't run on a disabled node) and leave it
-- off its place (18 Nov)
function M.scene(fx, fy, opt)
	scene_nodes()
	local s = { fx = fx, fy = fy, opt = opt or {} }
	if s.opt.over then
		s.copy = M.copy_of(s.opt, true)
		-- its painting (nil without one), for a scene that moves it (ui/step_scene.lua)
		s.painting = s.copy.painting
		for _, n in ipairs(s.copy) do gui.move_above(n, nil) end
		return s
	end
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

-- The backdrop's top nodes: ui/door_pass.lua drags them in with a screen
function M.scene_tops()
	return S and S.tops or {}
end

-- While its screen is dragged in (ui/door_pass.lua) the backdrop is cut to
-- the real screen: nothing of it goes past the page's edge. on false: as before
function M.scene_cut(on)
	if not S then return end
	local w = screen.width()
	if on and not S.clip then
		gui.set_size(S.base, vec(w, 720 * screen.FULL))
		local parent = gui.get_parent(S.bg)
		S.clip = gui.new_box_node(vec(0, 360), vec(w, 720 * 4))
		gui.set_clipping_mode(S.clip, gui.CLIPPING_MODE_STENCIL)
		gui.set_clipping_visible(S.clip, false)
		gui.set_parent(S.clip, parent)
		for _, n in ipairs({ S.bg, S.flat }) do
			local p = gui.get_position(n)
			gui.set_parent(n, S.clip)
			gui.set_position(n, vec(p.x, p.y - 360))
		end
		for _, q in ipairs(S.glints) do gui.set_enabled(q, false) end
	elseif not on and S.clip then
		gui.set_size(S.base, vec(1280 * screen.FULL, 720 * screen.FULL))
		for _, n in ipairs({ S.bg, S.flat }) do
			local p = gui.get_position(n)
			gui.set_parent(n, gui.get_parent(S.clip))
			gui.set_position(n, vec(p.x, p.y + 360))
		end
		gui.delete_node(S.clip)
		S.clip = nil
		for _, q in ipairs(S.glints) do gui.set_enabled(q, true) end
	end
end

-- A still copy of the backdrop of the screen s (its hold, M.scene), under
-- everything (ui/door_pass.lua: the home keeps it while a screen with the
-- real one is dragged over it). Returns it, for M.scene_copy_drop
-- (the copies still alive: M.scene_clear deletes the ones a passage forgot)
local COPIES = {}
function M.scene_copy(s)
	if not S then return {} end
	local out = M.copy_of(s.opt)
	for i = #out, 1, -1 do gui.move_below(out[i], nil) end
	COPIES[out] = true
	return out
end

-- The nodes of a copy of the backdrop for opt (M.scene's), in order from the
-- lowest. live: it moves like the real one (the lights, the thread breathing
-- and its glints), for a scene in front of a screen (opt.over)
function M.copy_of(opt, live)
	local out = { shape(nil, 640, 360, 1280 * screen.FULL, 720 * screen.FULL, with_alpha(C.SOOT, opt.dim or 1)) }
	local name = not opt.dim and painting_of(opt.bg)
	local id = name and load_painting(name)
	if not opt.dim and FLAT.has(opt.bg) then
		local back = empty(640, 0)
		gui.set_yanchor(back, gui.ANCHOR_BOTTOM)
		-- the flat backdrop of a copy always moves, on the same clock as the real
		-- one, so nothing jumps when one takes the other's place (Sergio, 18 Nov);
		-- it moves until it is deleted (its timer stops by itself)
		gui.set_inherit_alpha(FLAT.make(opt.bg, back, THREAD_Y, C.SOOT, true), true)
		out[#out + 1] = back
	elseif id then
		S.kept = name
		local back = empty(640, 0)
		gui.set_yanchor(back, gui.ANCHOR_BOTTOM)
		local size, at = painting_box(name)
		local bg = gui.new_box_node(at, size)
		gui.set_color(bg, VEIL)
		gui.set_texture(bg, id)
		gui.set_parent(bg, back)
		gui.set_inherit_alpha(bg, true)
		out[#out + 1] = back
		out.painting = bg
	elseif live then
		-- the two lights, each stuck to its corner (the painting has them already)
		local warm = empty(0, 0)
		gui.set_xanchor(warm, gui.ANCHOR_LEFT)
		gui.set_yanchor(warm, gui.ANCHOR_BOTTOM)
		gui.set_blend_mode(shape("alone", 60, 40, 1500, 1300, with_alpha(C.HOT_BOTTOM, 0.2), warm), gui.BLEND_ADD)
		local cold = empty(1280, 720)
		gui.set_xanchor(cold, gui.ANCHOR_RIGHT)
		gui.set_yanchor(cold, gui.ANCHOR_TOP)
		gui.set_blend_mode(shape("alone", -60, -40, 1500, 1300, with_alpha(C.ICE, 0.16), cold), gui.BLEND_ADD)
		out[#out + 1] = warm
		out[#out + 1] = cold
	end
	if opt.seam ~= false then
		local w = screen.width()
		local low = empty(640, 0)
		gui.set_yanchor(low, gui.ANCHOR_BOTTOM)
		gui.set_inherit_alpha(shape(nil, 0, THREAD_Y, w, 11, C.INK, low), true)
		local seam = gui.new_box_node(vec(0, THREAD_Y), vec(w, 6))
		gui.set_texture(seam, "fucina")
		gui.play_flipbook(seam, "filo")
		gui.set_parent(seam, low)
		gui.set_inherit_alpha(seam, true)
		if live then
			gui.animate(seam, "color", vmath.vector4(0.72, 0.72, 0.72, 1), gui.EASING_INOUTSINE, 1.6, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
			local glints = {}
			for i, c in ipairs({ C.SEAM, C.FROST }) do
				glints[i] = shape("alone", 0, THREAD_Y, 260, 30, with_alpha(c, 0.95), low)
				gui.set_blend_mode(glints[i], gui.BLEND_ADD)
			end
			run_glints(glints, w)
		end
		out[#out + 1] = low
	end
	return out
end

-- Between two menus (ui/transition.lua, pieces): a still copy of the backdrop
-- shown now, then (scene_still_fade, once the new screen is made) put just over
-- the new backdrop, under the new screen, and faded out in t seconds
function M.scene_still()
	if not S or not S.owner then return {} end
	local out = M.scene_copy(S.owner)
	for _, n in ipairs(out) do gui.move_above(n, nil) end
	return out
end

function M.scene_still_fade(out, t)
	if #out == 0 then return end
	local below = S.tops[#S.tops]
	for _, n in ipairs(out) do
		gui.move_above(n, below)
		below = n
		gui.animate(n, "color.w", 0, gui.EASING_OUTQUAD, t)
	end
	timer.delay(t, false, function() M.scene_copy_drop(out) end)
end

function M.scene_copy_drop(out)
	if out and not COPIES[out] then return end
	if out then COPIES[out] = nil end
	for _, n in ipairs(out or {}) do gui.delete_node(n) end
	local kept = S and S.kept
	if kept then
		S.kept = nil
		unload_painting(kept)
	end
end

-- The screen's backdrop changes (a screen with two views: the campaign's
-- boards and its map of the circles)
-- fade: seconds of a crossfade from the old flat backdrop (nil: at once)
function M.scene_bg(s, bg, fade)
	if s.opt.bg == bg then return end
	s.opt.bg = bg
	if S and S.owner == s then
		backdrop(not s.opt.dim and bg, fade)
		M.scene_fit()
	end
end

-- The screen's subject moves (nothing follows it, for now)
function M.scene_focus(s, fx, fy)
	s.fx, s.fy = fx, fy
end

function M.scene_drop(s)
	if s.copy then
		for _, n in ipairs(s.copy) do gui.delete_node(n) end
		s.copy = nil
		return
	end
	if not S or S.owner ~= s then return end
	S.owner = nil
	for _, n in ipairs(S.tops) do gui.set_enabled(n, false) end
end

-- In a match no menu backdrop may stay on: it would cover the world, with
-- the robots floating on the home's sky (Sergio's photo, 21 Nov). true if
-- there was one (the real backdrop still taken, or a passage's copy)
function M.scene_clear()
	local any = false
	for out in pairs(COPIES) do
		any = true
		M.scene_copy_drop(out)
	end
	if S and (S.owner or S.clip or gui.is_enabled(S.base)) then
		any = true
		M.scene_cut(false)
		S.owner = nil
		for _, n in ipairs(S.tops) do gui.set_enabled(n, false) end
	end
	return any
end

function M.scene_show(s, on)
	if s.copy then
		for _, n in ipairs(s.copy) do gui.set_enabled(n, on) end
		return
	end
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

-- A piece pops: from small to its size, overshooting
function M.pop(node, delay, time, from, done)
	gui.cancel_animations(node, "scale")
	local k = from or 0.86
	gui.set_scale(node, vmath.vector3(k, k, 1))
	gui.animate(node, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, time or 0.3, delay or 0, done)
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
	local p = screen.node_pos(node)
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
