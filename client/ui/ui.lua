-- MegaBlast's minimal interface, in the Scoria's style: flat charcoal shapes
-- with a light border (like the character's outline) and the Core's glow, in
-- the team color, on what matters. No painted images: a few white shapes
-- (assets/ui/, tools/grafica/ui.py; one shape per family of controls) colored from here.
-- Pieces are added only when a screen needs them.
--
-- The .gui using it must have the "ui" texture (/ui/ui.atlas) and the
-- "titolo" font (/ui/title.font). To change style, change the values here.
--
--   local ui = require "ui.ui"
--   local list_of = {}                                 -- a screen's buttons
--   ui.button(list_of, x, y, w, h, "GIOCA", "online", { main = true }, parent)
--   local ui_action = ui.tocco(list_of, action_id, action)  -- in on_input: the action or nil
--   (also with the controller: action_id ui.PAD, action.ui "su" "giu" "sinistra"
--   "destra" move the light over the buttons, "conferma" and "indietro" use them;
--   ui/controller.lua)

local screen = require "ui.screen"

local M = {}

local function c(r, g, b, a) return vmath.vector4(r, g, b, a or 1) end

-- Palette: from the character (scoria.lua) and the art bible
M.C = {
	BOTTOM = c(0.051, 0.047, 0.063),       -- almost black, the graveyard's dark
	PANEL = c(0.078, 0.071, 0.094),    -- the Scoria's charcoal
	LINE = c(1, 0.886, 0.769, 0.28),     -- border of pieces at rest
	LIGHT = c(1, 0.886, 0.769),            -- the Scoria's light outline
	TEXT = c(0.95, 0.91, 0.85),
	OFF = c(0.675, 0.643, 0.627),         -- #ACA4A0: 4.5:1 at least on every menu background (ui/backdrop.lua)
	BRACE = c(1, 0.42, 0.16),             -- accent when there is no team; color of the primary weapons
	STEEL = c(0.62, 0.77, 0.88),        -- color of the secondary weapons (plain damage, they move you)
	PURPLE = c(0.77, 0.61, 1),             -- movement: teleport and Grapple
	MINT = c(0.36, 0.86, 0.72),          -- consumable items: parachute, trap, shield, springboard
	SHADOW = c(0, 0, 0, 0.6),
	SQUADRA = { c(1, 0.231, 0.306), c(0.239, 0.482, 1), c(0.18, 0.75, 0.44), c(0.96, 0.77, 0.09) },
	-- the grades of badges (I..IV) and of pieces (ui/tag_card.lua): bronze, silver, gold, ember
	GRADI = { c(0.79, 0.54, 0.35), c(0.79, 0.83, 0.86), c(0.96, 0.77, 0.09), c(1, 0.42, 0.16) },
	GOLD = c(0.96, 0.77, 0.09),            -- the powers and the pieces' upgrades
}
local C = M.C

-- the shapes that stretch in 9-slice and their border (the others scale
-- whole). One family per kind of control (style "Sagoma tattica", report
-- UI-002): forma/bordo panels, tabs and the plain buttons; eroe the main
-- button (chamfered); slot_arma the weapons of the bar; badge the ammo pill;
-- pillola the queue's pill (round ends)
local B16, B12 = vmath.vector4(16, 16, 16, 16), vmath.vector4(12, 12, 12, 12)
local B24 = vmath.vector4(24, 24, 24, 24)
local NINE = { forma = B16, bordo = B16, eroe_forma = B16, eroe_bordo = B16, pillola_forma = B24, pillola_bordo = B24,
	slot_arma_forma = B16, slot_arma_bordo = B16, badge_forma = B12, badge_bordo = B12 }
local V = vmath.vector3()
local PRESSED, NORMAL = vmath.vector3(0.96, 0.96, 1), vmath.vector3(1, 1, 1)

local function vec(x, y) return vmath.vector3(x, y, 0) end

local function gui_node(tex, x, y, w, h, color, parent)
	local n = gui.new_box_node(vec(x, y), vec(w, h))
	if tex then
		gui.set_texture(n, "ui")
		gui.play_flipbook(n, tex)
		if NINE[tex] then gui.set_slice9(n, NINE[tex]) end
	end
	gui.set_color(n, color)
	if parent then gui.set_parent(n, parent) end
	return n
end

-- A white shape of the ui atlas, colored (9-slice if it is one of NINE)
M.sagoma = gui_node

local function write(font, t, x, y, scale, color, parent)
	local n = gui.new_text_node(vec(x, y), t)
	gui.set_font(n, font)
	gui.set_color(n, color or C.TEXT)
	gui.set_outline(n, C.SHADOW)
	V.x, V.y, V.z = scale or 1, scale or 1, 1
	gui.set_scale(n, V)
	if parent then gui.set_parent(n, parent) end
	return n
end

-- Normal text and title (today the same font, bigger)
function M.text(t, x, y, scale, color, parent)
	return write("titolo", t, x, y, (scale or 1) * 0.5, color, parent)
end

function M.title(t, x, y, scale, color, parent)
	return write("titolo", t, x, y, scale or 1, color or C.LIGHT, parent)
end

-- Soft additive halo: the glow of the Core and of the eye
function M.alone(x, y, d, color, parent)
	local n = gui_node("alone", x, y, d, d, color, parent)
	gui.set_blend_mode(n, gui.BLEND_ADD)
	return n
end

-- Full-screen solid background, on any proportion (ui/screen.lua)
function M.background(parent)
	local n = gui_node(nil, 640, 360, 1280 * screen.FULL, 720 * screen.FULL, C.BOTTOM, parent)
	gui.set_adjust_mode(n, gui.ADJUST_FIT)
	return n
end

-- Panel: charcoal with a faint light border. Also returns the border node, to
-- light it (C.LIGHT) when the panel is selected. shape: the family's prefix
-- ("slot_arma", "badge"; nil the plain panel)
function M.panel(x, y, w, h, parent, shape)
	local n = gui_node(shape and shape .. "_forma" or "forma", x, y, w, h, C.PANEL, parent)
	return n, gui_node(shape and shape .. "_bordo" or "bordo", 0, 0, w, h, C.LINE, n)
end

-- Button. opt: main (the chamfered shape, solid border, Core lit and a thin
-- line in its color at the bottom), colore (of the Core, usually the team),
-- tacca (a colored notch on the left: the mode's color, in the home),
-- spento (visible but not responding)
function M.button(list_of, x, y, w, h, label, ui_action, opt, parent)
	opt = opt or {}
	local main = opt.main
	local n = gui_node(main and "eroe_forma" or "forma", x, y, w, h, C.PANEL, parent)
	local col = opt.colore or C.BRACE
	local b = { nodo = n, ui_action = ui_action, spento = opt.spento, colore = col }
	b.bordo = gui_node(main and "eroe_bordo" or "bordo", 0, 0, w, h, main and C.LIGHT or C.LINE, n)
	b.riposo = gui.get_color(b.bordo)
	if opt.tacca then
		gui_node(nil, -w / 2 + 12, 0, 5, h - 30, opt.spento and C.OFF or opt.tacca, n)
	end
	local tx = 0
	if main and not opt.spento then
		-- the accent at the bottom, between the two chamfers
		gui_node(nil, 0, -h / 2 + 9, w - 56, 3, vmath.vector4(col.x, col.y, col.z, 0.8), n)
		-- the Core: a lit dot with its halo, left of the label
		local r = h * 0.5
		b.luce = M.alone(-w / 2 + r, 0, h * 1.1, vmath.vector4(col.x, col.y, col.z, 0.55), n)
		M.alone(-w / 2 + r, 0, h * 0.34, vmath.vector4((1 + col.x) / 2, (1 + col.y) / 2, (1 + col.z) / 2, 1), n)
		M.alone(-w / 2 + r, 0, h * 0.18, C.LIGHT, n)
		tx = h * 0.3
	end
	b.testo = M.text(label, tx, 0, opt.scala or (h >= 90 and 1.6 or 0.9),
		opt.spento and C.OFF or C.TEXT, n)
	list_of[#list_of + 1] = b
	return n
end

-- Tab: like a button, the active one has the light border and lit text
function M.tab(list_of, x, y, w, h, label, ui_action, activate, parent)
	local n = M.button(list_of, x, y, w, h, label, ui_action, nil, parent)
	M.sheet_active(list_of[#list_of], activate)
	return n
end

function M.sheet_active(b, activate)
	b.riposo = activate and C.LIGHT or C.LINE
	gui.set_color(b.bordo, b.riposo)
	gui.set_color(b.testo, activate and C.TEXT or C.OFF)
end

local function arrow(n)
	for i = -1, 1, 2 do
		local s = gui_node(nil, -2, i * 7, 22, 4, C.LIGHT, n)
		gui.set_rotation(s, vmath.vector3(0, 0, i * 45))
	end
end

-- Back: square with the arrow, stuck at the top left
function M.back(list_of, ui_action, parent)
	local n = M.button(list_of, 30 + 32, 720 - 30 - 32, 64, 64, "", ui_action, nil, parent)
	gui.set_xanchor(n, gui.ANCHOR_LEFT)
	gui.set_yanchor(n, gui.ANCHOR_TOP)
	arrow(n)
	return n
end

-- The header of the menu screens (Sergio, 4 Nov: "le interfacce non si
-- devono spostare per lei, ma devono essere già pensate con lei in mente"):
-- the same on every screen. One row EDGE from the real top: on the left the
-- back button and the title, in the middle the queue's pill (ui/pill.lua, a
-- SLOT_W x SLOT_H place nothing else ever uses), on the right the screen's
-- own controls. The tabs go in the first row under it, at the content's left
-- margin (EDGE in game coordinates): they belong to the content, which on a
-- 20:9 screen stays in the middle. The header's nodes have no parent, so
-- they stick to the real edges (ui/screen.lua);
-- create it before the screen's root (the root's veils cover it) and delete
-- it with ui.header_delete. The screen's root (ui.radice) and the tabs follow
-- the real top too: on a taller screen (4:3 tablet) the content stays the
-- same distance under the header and the spare room goes to the bottom
-- (report UI-001; before, the header went to the edge and the content stayed
-- in the middle, 200 px below it).
--
--   local h = ui.header(list_of, "ARMERIA", "indietro")   -- nil action: no back button
--   local radice = ui.radice()                             -- the content's root, in game coordinates
--   ui.header_tabs(h, list_of, { { "SET", "scheda:set", 150 }, ... }, active_index [, x0])
--   ...children of h.right at x < 0 (h.right is the right edge, y the header's center)
M.EDGE = 30
M.HEAD_Y = 720 - 62            -- center of the header row (of the back button)
M.TITLE_X = 118                 -- where the title starts
M.TITLE_SCALE = 0.85
M.CONTENT_TOP = 720 - 118      -- the first row under the header (24 under it)
M.TABS_Y = M.CONTENT_TOP - 24  -- center of the tabs, in that first row
M.TAB_H = 48
M.BODY_TOP = 720 - 190          -- on a screen with tabs the content starts under them
M.SLOT_W, M.SLOT_H = 440, 52    -- the pill's place, in the middle of the header

local function corner(x, xanchor, yanchor)
	local n = gui.new_box_node(vec(x, yanchor and M.HEAD_Y or 0), vec(0, 0))
	gui.set_visible(n, false)
	gui.set_xanchor(n, xanchor)
	if yanchor then gui.set_yanchor(n, yanchor) end
	return n
end

-- The root of a screen's content (no parent, invisible): as far under the
-- real top as at 16:9. Moved by hand (screen.y1) and not with ANCHOR_TOP:
-- Defold moves an anchored node at y = 0 toward the bottom, not the top.
-- The screens build their root again every time they open.
function M.root()
	local n = gui.new_box_node(vec(0, screen.y1 - 720), vec(0, 0))
	gui.set_visible(n, false)
	return n
end

function M.header(list_of, title, back_action)
	local h = { left = corner(0, gui.ANCHOR_LEFT, gui.ANCHOR_TOP), right = corner(1280, gui.ANCHOR_RIGHT, gui.ANCHOR_TOP) }
	if back_action then
		h.back = M.button(list_of, M.EDGE + 32, 0, 64, 64, "", back_action, nil, h.left)
		arrow(h.back)
	end
	if title then
		h.title = M.title(title, M.TITLE_X, 0, M.TITLE_SCALE, C.TEXT, h.left)
		gui.set_pivot(h.title, gui.PIVOT_W)
	end
	return h
end

-- The tabs: { label, action, width } from the left edge (or from x0); returns their nodes
function M.header_tabs(h, list_of, tabs, active, x0)
	if h.tabs then gui.delete_node(h.tabs) end
	h.tabs = M.root()
	local x, nodes = x0 or M.EDGE, {}
	for i, t in ipairs(tabs) do
		nodes[i] = M.tab(list_of, x + t[3] / 2, M.TABS_Y, t[3], M.TAB_H, t[1], t[2], i == active, h.tabs)
		x = x + t[3] + 12
	end
	return nodes
end

function M.header_delete(h)
	if not h then return end
	gui.delete_node(h.left)
	gui.delete_node(h.right)
	if h.tabs then gui.delete_node(h.tabs) end
end

-- Settings: the same square with the wheel, at the top left (in a match) or
-- right (in the home)
function M.settings_button(list_of, ui_action, parent, right)
	local n = M.button(list_of, right and 1280 - 30 - 32 or 30 + 32, 720 - 30 - 32, 64, 64, "", ui_action, nil, parent)
	gui.set_xanchor(n, right and gui.ANCHOR_RIGHT or gui.ANCHOR_LEFT)
	gui.set_yanchor(n, gui.ANCHOR_TOP)
	gui_node("ingranaggio", 0, 0, 34, 34, C.LIGHT, n)
	return n
end

-- Star of the lessons and of the campaign: d is the side
-- (small ones from the 48 px image: the ui atlas has no mipmaps, and the big
-- one shrunk a lot shows steps)
function M.star(x, y, d, color, parent)
	return gui_node(d <= 40 and "stella_p" or "stella", x, y, d, d, color, parent)
end

-- Favilla's medal of the cortile (sim/missions.lua, medaglia): her head, the
-- logo of Sergio's drawing; lit in her light blue (M.MEDAL)
function M.medal(x, y, d, color, parent)
	return gui_node(d <= 64 and "favilla_p" or "favilla", x, y, d, d, color, parent)
end

-- Padlock of locked missions and chapters
function M.padlock(x, y, d, color, parent)
	return gui_node(d <= 48 and "lucchetto_p" or "lucchetto", x, y, d, d, color, parent)
end

-- Disc and ring (pie nodes): sticks, round buttons, stopwatch. d is the
-- diameter, thickness the ring's toward the inside. A pie polygon has no
-- antialiasing and shows steps (Sergio, 4 Nov: "piene di scalini"), so the
-- node draws a soft white image of the disc or ring (tools/grafica/ui.py)
-- and its own polygon only cuts around it, in the clear part: the edges are
-- the image's. The fill angle (the stopwatch's arc) still works.
-- the rings' thickness / diameter, the same list as ui.py (ANELLI)
local RINGS = { 0.014, 0.018, 0.023, 0.028, 0.034, 0.041, 0.05, 0.06, 0.071, 0.084,
	0.1, 0.12, 0.14, 0.165, 0.2, 0.25 }
local RING_IMG, RING_IMG_SMALL = {}, {}
for i, k in ipairs(RINGS) do
	RING_IMG[i] = string.format("anello_%03d", math.floor(k * 1000 + 0.5))
	RING_IMG_SMALL[i] = RING_IMG[i] .. "_p"
end
-- under this diameter the 64 px images (the ui atlas has no mipmaps)
local SMALL = 48

function M.disc(x, y, d, color, parent)
	local n = gui.new_pie_node(vec(x, y), vec(d, d))
	gui.set_outer_bounds(n, gui.PIEBOUNDS_ELLIPSE)
	gui.set_perimeter_vertices(n, 64)
	gui.set_texture(n, "ui")
	gui.play_flipbook(n, d <= SMALL and "disco_p" or "disco")
	gui.set_color(n, color)
	if parent then gui.set_parent(n, parent) end
	return n
end

-- Turns the pie node n into a ring d wide (h high: an ellipse), thickness
-- toward the inside measured on d: the image with the nearest thickness, the
-- polygon's hole a little inside the image's
function M.ring(n, d, thickness, h)
	local k, best = thickness / d, 1
	for i = 2, #RINGS do
		if math.abs(RINGS[i] - k) < math.abs(RINGS[best] - k) then best = i end
	end
	V.x, V.y, V.z = d, h or d, 0
	gui.set_size(n, V)
	gui.play_flipbook(n, d <= SMALL and RING_IMG_SMALL[best] or RING_IMG[best])
	gui.set_inner_radius(n, math.max(0, d / 2 - RINGS[best] * d - 2))
end

function M.ring_node(x, y, d, thickness, color, parent)
	local n = M.disc(x, y, d, color, parent)
	M.ring(n, d, thickness)
	return n
end

-- Progress bar (health, experience): dark track and colored fill
function M.bar(x, y, w, h, color, parent)
	local n = gui_node(nil, x, y, w, h, C.SHADOW, parent)
	local p = gui_node(nil, -w / 2, 0, w, h, color or C.LIGHT, n)
	gui.set_pivot(p, gui.PIVOT_W)
	return { nodo = n, full = p, w = w, h = h }
end

function M.bar_value(b, v)
	V.x, V.y, V.z = b.w * math.max(0, math.min(1, v)), b.h, 0
	gui.set_size(b.full, V)
end

-- the gold of the Crown and of what counts double
M.GOLD = c(1, 0.8, 0.25)
M.MEDAL = c(0.55, 0.81, 0.94)

-- Tap on the buttons of a list: pressed, released over it (the action) or
-- outside. The last one added wins, which is drawn on top (a button inside a panel)
local function under(list_of, x, y)
	for i = #list_of, 1, -1 do
		local b = list_of[i]
		if not b.spento and gui.is_enabled(b.nodo, true) and gui.pick_node(b.nodo, x, y) then return b end
	end
end

local function premi(b, fell)
	gui.set_scale(b.nodo, fell and PRESSED or NORMAL)
	gui.set_color(b.bordo, fell and b.colore or b.riposo)
end

-- Controller: one button at a time has the light (lit border, a bit bigger).
-- The d-pad moves it toward the nearest button in that direction. The list
-- may also hold pieces that aren't buttons (the draft's cards), as long as
-- they have nodo, bordo, colore and riposo.
M.PAD = hash("pad")
M.TOUCH = hash("touch")
local LIGHT_SCALE = vmath.vector3(1.06, 1.06, 1)
-- the action of the last button confirmed: when the screen is rebuilt, the
-- light goes back on it
local remember

local function usable(b)
	return not b.spento and gui.is_enabled(b.nodo, true)
end

-- The light on b (nil: off)
function M.light(list_of, b)
	local first_one = list_of.luce
	if first_one and first_one ~= b then
		gui.set_scale(first_one.nodo, NORMAL)
		gui.set_color(first_one.bordo, first_one.riposo)
	end
	list_of.luce = b
	if b then
		gui.set_scale(b.nodo, LIGHT_SCALE)
		gui.set_color(b.bordo, b.colore)
	end
end

-- The light again where it was, after the screen recolored the borders
function M.relight(list_of)
	local b = list_of.luce
	if b and usable(b) then M.light(list_of, b) elseif b then M.light(list_of, nil) end
end

-- Where the light starts: the last confirmed, the main one, or the first
-- (not those in a corner: back and the wheel)
local ANGLE = { indietro = true, rotellina = true, impostazioni = true }
local function first(list_of)
	local main, another, angle_deg
	for _, b in ipairs(list_of) do
		if usable(b) then
			if remember and b.ui_action == remember then return b end
			-- (b.luce is the Core, which only main ones have)
			if ANGLE[b.ui_action] then angle_deg = angle_deg or b
			elseif b.luce then main = main or b
			else another = another or b end
		end
	end
	return main or another or angle_deg
end

local DIR_NODE = { su = { 0, 1 }, giu = { 0, -1 }, sinistra = { -1, 0 }, destra = { 1, 0 } }
function M.navigate(list_of, toward)
	local b = list_of.luce
	if not (b and usable(b)) then
		M.light(list_of, first(list_of))
		return
	end
	local d = DIR_NODE[toward]
	local p = gui.get_screen_position(b.nodo)
	local better, cost
	for _, o in ipairs(list_of) do
		if o ~= b and usable(o) then
			local q = gui.get_screen_position(o.nodo)
			local dx, dy = q.x - p.x, q.y - p.y
			local forward = dx * d[1] + dy * d[2]
			if forward > 1 then
				-- forward counts little, sideways a lot: go straight if you can
				local k = forward + 2.5 * math.abs(dx * d[2] - dy * d[1])
				if not cost or k < cost then better, cost = o, k end
			end
		end
	end
	if better then M.light(list_of, better) end
end

-- The button with the light (or nil)
function M.lit_up(list_of)
	local b = list_of.luce
	return b and usable(b) and b or nil
end

function M.touch(list_of, action_id, action)
	if action_id == M.PAD then
		if not action.pressed then return nil end
		local u = action.ui
		if DIR_NODE[u] then
			M.navigate(list_of, u)
		elseif u == "conferma" then
			local b = M.lit_up(list_of)
			if not b then
				M.light(list_of, first(list_of))
				return nil
			end
			if not ANGLE[b.ui_action] then remember = b.ui_action end
			return b.ui_action
		elseif u == "indietro" then
			for _, b in ipairs(list_of) do
				if b.ui_action == "indietro" and usable(b) then return "indietro" end
			end
		end
		return nil
	end
	if action_id ~= M.TOUCH then return nil end
	if action.pressed then
		list_of.held_down = under(list_of, action.x, action.y)
		if list_of.held_down then premi(list_of.held_down, true) end
	elseif action.released and list_of.held_down then
		local b = list_of.held_down
		list_of.held_down = nil
		premi(b, false)
		if under(list_of, action.x, action.y) == b then return b.ui_action end
	end
	return nil
end

return M
