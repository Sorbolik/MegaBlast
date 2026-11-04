-- The queue pill (Sergio, 3 Nov: "una bella proposta di design che ti ricordi
-- che sei in coda e che ti faccia capire anche quando si sta riempiendo e
-- quando stai per essere portato in partita"): while you stay in the online
-- queue outside the waiting room (menus, training), a pill with Favilla's
-- head, one dot per place and the time. Two forms (Sergio, 4 Nov: it has its
-- own place on every screen, nothing moves for it):
--   - in the menus the whole pill, with the text (IN CODA, the mode, BOT TRA),
--     in the middle of the header (ui.header: the place nobody else uses).
--     Tapping it goes back to the room;
--   - in a match (the draft, the battle, the podium) the chip: head, dots and
--     time, right of the gear (or at the edge where there is no gear). It
--     can't be tapped there (the finger is playing).
-- When the queue is full it lights up (PARTITA TROVATA · 3) and, in a match,
-- a veil comes down with the count. It is created above everything and
-- raised again when a screen opens (pill.raise).
--
--   local pill = require "ui.pill"
--   local p = pill.new()
--   pill.show(p, on, beside)           -- beside: nil (menus) or the gear node the chip sits next to,
--                                      -- or true (a match screen without a gear: at the edge)
--   pill.set(p, text, short, places, of, hot) -- text for the pill, short for the chip; places: dots lit
--   pill.flash(p)                      -- someone arrived: a small jump
--   pill.found(p, n)                   -- the veil with PARTITA TROVATA and n (nil: no veil)
--   pill.hit(p, x, y) -> true          -- x, y as gui.pick_node wants them (only the whole pill)
--   pill.raise(p)                      -- above the nodes created after it
--   pill.update(p, dt)

local ui = require "ui.ui"
local screen = require "ui.screen"
local T = require("lang.text").pill

local M = {}

local C = ui.C
local W, H = 1280, 720
local CHIP_W = 176
local CARD = vmath.vector4(0.94, 0.9, 0.82, 1)
local DOT = 12
local V = vmath.vector3()

local function with_alpha(c, a) return vmath.vector4(c.x, c.y, c.z, a) end

function M.new()
	local p = { t = 0, of = 0, dots = {}, w = ui.SLOT_W }
	p.root = gui.new_box_node(vmath.vector3(W / 2, ui.HEAD_Y, 0), vmath.vector3(0, 0, 0))
	gui.set_visible(p.root, false)
	-- stuck to the real screen's top edge, like the header (ui/screen.lua)
	gui.set_yanchor(p.root, gui.ANCHOR_TOP)
	-- round ends, like Android's pills (Sergio, 4 Nov: "leggermente più alta ed ovale")
	p.panel, p.border = ui.pannello(0, 0, ui.SLOT_W, ui.SLOT_H, p.root, "pillola")
	-- Favilla's logo (art/personaggi/favilla.svg, exported by strumenti/grafica/ingresso.py),
	-- with air around it, at the center of the left end; the small image (no steps)
	p.head = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(36, 36, 0))
	gui.set_texture(p.head, "ui")
	gui.play_flipbook(p.head, "favilla_p")
	gui.set_color(p.head, CARD)
	gui.set_parent(p.head, p.root)
	p.text = ui.testo("", 0, 0, 0.62, C.TEXT, p.root)
	p.short = ui.testo("", 0, 0, 0.66, C.TEXT, p.root)
	gui.set_pivot(p.short, gui.PIVOT_E)
	-- the veil of a match found in a battle: dark, with the count in the middle
	p.veil = gui.new_box_node(vmath.vector3(W / 2, H / 2, 0), vmath.vector3(W * screen.FULL, H * screen.FULL, 0))
	gui.set_adjust_mode(p.veil, gui.ADJUST_FIT)
	gui.set_color(p.veil, vmath.vector4(0.04, 0.03, 0.05, 0.6))
	ui.titolo(T.found, 0, 90, 1.1, C.LIGHT, p.veil)
	p.count = ui.titolo("3", 0, 0, 2.2, C.TEXT, p.veil)
	ui.testo(T.cancelled, 0, -80, 0.8, C.OFF, p.veil)
	gui.set_enabled(p.veil, false)
	gui.set_enabled(p.root, false)
	return p
end

-- The dots, one per place: on the right of the pill, after the head on the chip
local function place_dots(p)
	for _, d in ipairs(p.dots) do gui.delete_node(d) end
	p.dots = {}
	for i = 1, p.of do
		local x = p.chip and (-CHIP_W / 2 + 54 + (i - 1) * (DOT + 6))
			or (p.w / 2 - 26 - (p.of - i) * (DOT + 6))
		local d = gui.new_box_node(vmath.vector3(x, 0, 0), vmath.vector3(DOT, DOT, 0))
		gui.set_texture(d, "ui")
		gui.play_flipbook(d, "disco_p")
		gui.set_parent(d, p.root)
		p.dots[i] = d
	end
end

-- The pill or the chip: sizes and places of the pieces
local function shape(p, chip)
	p.chip = chip
	p.w = chip and CHIP_W or ui.SLOT_W
	V.x, V.y, V.z = p.w, ui.SLOT_H, 0
	gui.set_size(p.panel, V)
	gui.set_size(p.border, V)
	V.x, V.y = -p.w / 2 + 26, 0
	gui.set_position(p.head, V)
	gui.set_enabled(p.text, not chip)
	gui.set_enabled(p.short, chip)
	-- the text between the head and the dots
	V.x = -12
	gui.set_position(p.text, V)
	V.x = p.w / 2 - 16
	gui.set_position(p.short, V)
	gui.set_xanchor(p.root, chip and gui.ANCHOR_LEFT or gui.ANCHOR_NONE)
	place_dots(p)
end

function M.show(p, on, beside)
	gui.set_enabled(p.root, on)
	p.beside = beside
	if not on then
		gui.set_enabled(p.veil, false)
		return
	end
	local chip = beside ~= nil
	if chip ~= p.chip then shape(p, chip) end
	M.place(p)
end

-- Where it sits: the middle of the header, or right of the gear (which may move:
-- the draft's goes under the strip of tags)
function M.place(p)
	if p.chip then
		local g = type(p.beside) ~= "boolean" and p.beside
		V.x = (g and ui.TITLE_X or ui.EDGE) + CHIP_W / 2
		V.y = g and gui.get_position(g).y or ui.HEAD_Y
	else
		V.x, V.y = W / 2, ui.HEAD_Y
	end
	V.z = 0
	gui.set_position(p.root, V)
end

function M.set(p, text, short, places, of, hot)
	gui.set_text(p.text, text)
	gui.set_text(p.short, short)
	if of ~= p.of then
		p.of = of
		place_dots(p)
	end
	for i, d in ipairs(p.dots) do
		gui.set_color(d, i <= places and C.TEXT or with_alpha(C.LIGHT, 0.25))
	end
	p.hot = hot
	gui.set_color(p.border, hot and C.BRACE or C.LINE)
	gui.set_color(p.short, short:find("^BOT") and C.BRACE or C.TEXT)
end

function M.flash(p)
	gui.cancel_animations(p.root, "scale")
	V.x, V.y, V.z = 1.12, 1.12, 1
	gui.set_scale(p.root, V)
	V.x, V.y = 1, 1
	gui.animate(p.root, "scale", V, gui.EASING_OUTBACK, 0.3)
end

function M.found(p, n)
	gui.set_enabled(p.veil, n ~= nil)
	if n then gui.set_text(p.count, tostring(n)) end
end

function M.hit(p, x, y)
	return gui.is_enabled(p.root) and not p.chip and gui.pick_node(p.panel, x, y)
end

function M.raise(p)
	gui.move_above(p.veil, nil)
	gui.move_above(p.root, nil)
end

function M.update(p, dt)
	if not gui.is_enabled(p.root) then return end
	p.t = p.t + dt
	if p.chip and p.beside ~= true then M.place(p) end
	-- the full queue breathes in the accent color
	if p.hot then
		gui.set_color(p.border, with_alpha(C.BRACE, 0.6 + 0.4 * math.sin(p.t * 8)))
	end
end

return M
