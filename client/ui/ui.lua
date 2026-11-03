-- MegaBlast's minimal interface, in the Scoria's style: flat charcoal shapes
-- with a light border (like the character's outline) and the Core's glow, in
-- the team color, on what matters. No painted images: a few white shapes
-- (assets/ui/, strumenti/grafica/ui.py) colored from here.
-- Pieces are added only when a screen needs them.
--
-- The .gui using it must have the "ui" texture (/ui/ui.atlas) and the
-- "titolo" font (/ui/titolo.font). To change style, change the values here.
--
--   local ui = require "ui.ui"
--   local list_of = {}                                 -- a screen's buttons
--   ui.button(list_of, x, y, w, h, "GIOCA", "online", { main = true }, parent)
--   local ui_action = ui.tocco(list_of, action_id, action)  -- in on_input: the action or nil
--   (also with the controller: action_id ui.PAD, action.ui "su" "giu" "sinistra"
--   "destra" move the light over the buttons, "conferma" and "indietro" use them;
--   ui/controller.lua)

local screen = require "ui.schermo"

local M = {}

local function c(r, g, b, a) return vmath.vector4(r, g, b, a or 1) end

-- Palette: from the character (scoria.lua) and the art bible
M.C = {
	BOTTOM = c(0.051, 0.047, 0.063),       -- almost black, the graveyard's dark
	PANEL = c(0.078, 0.071, 0.094),    -- the Scoria's charcoal
	LINE = c(1, 0.886, 0.769, 0.28),     -- border of pieces at rest
	LIGHT = c(1, 0.886, 0.769),            -- the Scoria's light outline
	TEXT = c(0.95, 0.91, 0.85),
	OFF = c(0.55, 0.52, 0.52),
	BRACE = c(1, 0.42, 0.16),             -- accent when there is no team; color of the primary weapons
	STEEL = c(0.62, 0.77, 0.88),        -- color of the secondary weapons (plain damage, they move you)
	PURPLE = c(0.77, 0.61, 1),             -- movement: teleport and Grapple
	MINT = c(0.36, 0.86, 0.72),          -- consumable items: parachute, trap, shield, springboard
	SHADOW = c(0, 0, 0, 0.6),
	SQUADRA = { c(1, 0.231, 0.306), c(0.239, 0.482, 1), c(0.18, 0.75, 0.44), c(0.96, 0.77, 0.09) },
	-- the grades of badges (I..IV) and of pieces (ui/cartellino.lua): bronze, silver, gold, ember
	GRADI = { c(0.79, 0.54, 0.35), c(0.79, 0.83, 0.86), c(0.96, 0.77, 0.09), c(1, 0.42, 0.16) },
	GOLD = c(0.96, 0.77, 0.09),            -- the powers and the pieces' upgrades
}
local C = M.C

local BORDER_9 = vmath.vector4(16, 16, 16, 16)
-- the shapes that stretch in 9-slice (the others scale whole)
local NINE = { forma = true, bordo = true }
local V = vmath.vector3()
local PRESSED, NORMAL = vmath.vector3(0.96, 0.96, 1), vmath.vector3(1, 1, 1)

local function vec(x, y) return vmath.vector3(x, y, 0) end

local function gui_node(tex, x, y, w, h, color, parent)
	local n = gui.new_box_node(vec(x, y), vec(w, h))
	if tex then
		gui.set_texture(n, "ui")
		gui.play_flipbook(n, tex)
		if NINE[tex] then gui.set_slice9(n, BORDER_9) end
	end
	gui.set_color(n, color)
	if parent then gui.set_parent(n, parent) end
	return n
end

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
function M.testo(t, x, y, scale, color, parent)
	return write("titolo", t, x, y, (scale or 1) * 0.5, color, parent)
end

function M.titolo(t, x, y, scale, color, parent)
	return write("titolo", t, x, y, scale or 1, color or C.LIGHT, parent)
end

-- Soft additive halo: the glow of the Core and of the eye
function M.alone(x, y, d, color, parent)
	local n = gui_node("alone", x, y, d, d, color, parent)
	gui.set_blend_mode(n, gui.BLEND_ADD)
	return n
end

-- Full-screen solid background, on any proportion (ui/schermo.lua)
function M.sfondo(parent)
	local n = gui_node(nil, 640, 360, 1280 * screen.FULL, 720 * screen.FULL, C.BOTTOM, parent)
	gui.set_adjust_mode(n, gui.ADJUST_FIT)
	return n
end

-- Panel: charcoal with a faint light border. Also returns the border node, to
-- light it (C.LIGHT) when the panel is selected
function M.pannello(x, y, w, h, parent)
	local n = gui_node("forma", x, y, w, h, C.PANEL, parent)
	return n, gui_node("bordo", 0, 0, w, h, C.LINE, n)
end

-- Button. opt: main (solid border and Core lit), colore (of the Core, usually
-- the team), spento (visible but not responding)
function M.button(list_of, x, y, w, h, label, ui_action, opt, parent)
	opt = opt or {}
	local n = gui_node("forma", x, y, w, h, C.PANEL, parent)
	local col = opt.colore or C.BRACE
	local b = { nodo = n, ui_action = ui_action, spento = opt.spento, colore = col }
	b.bordo = gui_node("bordo", 0, 0, w, h, opt.main and C.LIGHT or C.LINE, n)
	b.riposo = gui.get_color(b.bordo)
	local tx = 0
	if opt.main and not opt.spento then
		-- the Core: a lit dot with its halo, left of the label
		local r = h * 0.5
		b.luce = M.alone(-w / 2 + r, 0, h * 1.1, vmath.vector4(col.x, col.y, col.z, 0.55), n)
		M.alone(-w / 2 + r, 0, h * 0.34, vmath.vector4((1 + col.x) / 2, (1 + col.y) / 2, (1 + col.z) / 2, 1), n)
		M.alone(-w / 2 + r, 0, h * 0.18, C.LIGHT, n)
		tx = h * 0.3
	end
	b.testo = M.testo(label, tx, 0, opt.scala or (h >= 90 and 1.6 or 0.9),
		opt.spento and C.OFF or C.TEXT, n)
	list_of[#list_of + 1] = b
	return n
end

-- Tab: like a button, the active one has the light border and lit text
function M.scheda(list_of, x, y, w, h, label, ui_action, activate, parent)
	local n = M.button(list_of, x, y, w, h, label, ui_action, nil, parent)
	M.sheet_active(list_of[#list_of], activate)
	return n
end

function M.sheet_active(b, activate)
	b.riposo = activate and C.LIGHT or C.LINE
	gui.set_color(b.bordo, b.riposo)
	gui.set_color(b.testo, activate and C.TEXT or C.OFF)
end

-- Back: square with the arrow, stuck at the top left
function M.indietro(list_of, ui_action, parent)
	local n = M.button(list_of, 30 + 32, 720 - 30 - 32, 64, 64, "", ui_action, nil, parent)
	gui.set_xanchor(n, gui.ANCHOR_LEFT)
	gui.set_yanchor(n, gui.ANCHOR_TOP)
	for i = -1, 1, 2 do
		local s = gui_node(nil, -2, i * 7, 22, 4, C.LIGHT, n)
		gui.set_rotation(s, vmath.vector3(0, 0, i * 45))
	end
	return n
end

-- Settings: the same square with the wheel, at the top left (in a match) or
-- right (in the home)
function M.impostazioni(list_of, ui_action, parent, right)
	local n = M.button(list_of, right and 1280 - 30 - 32 or 30 + 32, 720 - 30 - 32, 64, 64, "", ui_action, nil, parent)
	gui.set_xanchor(n, right and gui.ANCHOR_RIGHT or gui.ANCHOR_LEFT)
	gui.set_yanchor(n, gui.ANCHOR_TOP)
	gui_node("ingranaggio", 0, 0, 34, 34, C.LIGHT, n)
	return n
end

-- Star of the lessons and of the campaign: d is the side
function M.stella(x, y, d, color, parent)
	return gui_node("stella", x, y, d, d, color, parent)
end

-- Disc and ring (pie nodes): sticks, round buttons, stopwatch. d is the
-- diameter, thickness the ring's toward the inside
function M.disco(x, y, d, color, parent)
	local n = gui.new_pie_node(vec(x, y), vec(d, d))
	gui.set_outer_bounds(n, gui.PIEBOUNDS_ELLIPSE)
	gui.set_perimeter_vertices(n, 64)
	gui.set_color(n, color)
	if parent then gui.set_parent(n, parent) end
	return n
end

function M.ring_node(x, y, d, thickness, color, parent)
	local n = M.disco(x, y, d, color, parent)
	gui.set_inner_radius(n, d / 2 - thickness)
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

-- The standings leader's Crown: a band and three diamond points, with a dark
-- border. Returns the root (invisible), centered on the band; sizes in GUI
-- units at scale 1 (18 wide).
M.GOLD = c(1, 0.8, 0.25)
local WHITE = c(1, 1, 1)
local CROWN_PIECES = { { 0, 0, 16, 5, 0 }, { -6, 4, 5, 5, 45 }, { 0, 6, 5, 5, 45 }, { 6, 4, 5, 5, 45 } }

function M.crown(x, y, color, parent)
	local r = gui_node(nil, x, y, 0, 0, WHITE, parent)
	gui.set_visible(r, false)
	for pass = 1, 2 do
		local b = pass == 1 and 2 or 0
		for _, p in ipairs(CROWN_PIECES) do
			local n = gui_node(nil, p[1], p[2], p[3] + b, p[4] + b, pass == 1 and C.BOTTOM or color or M.GOLD, r)
			gui.set_inherit_alpha(n, true)
			gui.set_euler(n, vmath.vector3(0, 0, p[5]))
		end
	end
	return r
end

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
local LIGHT_SCALE = vmath.vector3(1.06, 1.06, 1)
-- the action of the last button confirmed: when the screen is rebuilt, the
-- light goes back on it
local remember

local function usable(b)
	return not b.spento and gui.is_enabled(b.nodo, true)
end

-- The light on b (nil: off)
function M.luce(list_of, b)
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
	if b and usable(b) then M.luce(list_of, b) elseif b then M.luce(list_of, nil) end
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
		M.luce(list_of, first(list_of))
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
	if better then M.luce(list_of, better) end
end

-- The button with the light (or nil)
function M.lit_up(list_of)
	local b = list_of.luce
	return b and usable(b) and b or nil
end

function M.tocco(list_of, action_id, action)
	if action_id == M.PAD then
		if not action.pressed then return nil end
		local u = action.ui
		if DIR_NODE[u] then
			M.navigate(list_of, u)
		elseif u == "conferma" then
			local b = M.lit_up(list_of)
			if not b then
				M.luce(list_of, first(list_of))
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
	if action_id ~= hash("touch") then return nil end
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
