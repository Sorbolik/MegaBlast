-- The queue pill (Sergio, 3 Nov: "una bella proposta di design che ti ricordi
-- che sei in coda e che ti faccia capire anche quando si sta riempiendo e
-- quando stai per essere portato in partita"): while you stay in the online
-- queue outside the waiting room (menus, training), a small pill in the
-- middle at the bottom (in a battle at the top) with Favilla's head, the mode, one dot per place and the
-- time. Tapping it goes back to the room. When the queue is full it lights
-- up (PARTITA TROVATA · 3) and, in a match, a veil comes down with the count.
-- It is created above everything (like the waiting flame) and raised again
-- when a screen opens (pill.raise).
--
--   local pill = require "ui.pill"
--   local p = pill.new()
--   pill.show(p, on, in_battle)        -- in a battle it sits at the top, under the scores
--   pill.set(p, text, places, of, hot) -- places: how many are in (dots lit), of: how many are needed
--   pill.flash(p)                      -- someone arrived: a small jump
--   pill.found(p, n)                   -- the veil with PARTITA TROVATA and n (nil: no veil)
--   pill.hit(p, x, y) -> true          -- x, y as gui.pick_node wants them
--   pill.raise(p)                      -- above the nodes created after it
--   pill.update(p, dt)

local ui = require "ui.ui"
local screen = require "ui.screen"

local M = {}

local C = ui.C
local W, H = 1280, 720
-- where it sits: on the menus at the bottom (at the top there are the screens'
-- tabs), in a battle at the top under the scores (at the bottom the weapons)
local LOW, HIGH = 24, H - 112
local CARD = vmath.vector4(0.94, 0.9, 0.82, 1)
local DOT = 12
local V = vmath.vector3()

local function with_alpha(c, a) return vmath.vector4(c.x, c.y, c.z, a) end

function M.new()
	local p = { t = 0, of = 0, dots = {} }
	p.root = gui.new_box_node(vmath.vector3(W / 2, LOW, 0), vmath.vector3(0, 0, 0))
	gui.set_visible(p.root, false)
	p.panel, p.border = ui.pannello(0, 0, 520, 34, p.root)
	p.head = gui.new_box_node(vmath.vector3(-238, 0, 0), vmath.vector3(28, 28, 0))
	gui.set_texture(p.head, "ui")
	gui.play_flipbook(p.head, "favilla")
	gui.set_color(p.head, CARD)
	gui.set_parent(p.head, p.root)
	p.text = ui.testo("", 10, 0, 0.62, C.TEXT, p.root)
	-- the veil of a match found in a battle: dark, with the count in the middle
	p.veil = gui.new_box_node(vmath.vector3(W / 2, H / 2, 0), vmath.vector3(W * screen.FULL, H * screen.FULL, 0))
	gui.set_adjust_mode(p.veil, gui.ADJUST_FIT)
	gui.set_color(p.veil, vmath.vector4(0.04, 0.03, 0.05, 0.6))
	ui.titolo("PARTITA TROVATA", 0, 90, 1.1, C.LIGHT, p.veil)
	p.count = ui.titolo("3", 0, 0, 2.2, C.TEXT, p.veil)
	ui.testo("questa partita contro i bot si annulla", 0, -80, 0.8, C.OFF, p.veil)
	gui.set_enabled(p.veil, false)
	gui.set_enabled(p.root, false)
	return p
end

function M.show(p, on, in_battle)
	gui.set_enabled(p.root, on)
	if not on then gui.set_enabled(p.veil, false) end
	V.x, V.y, V.z = W / 2, in_battle and HIGH or LOW, 0
	gui.set_position(p.root, V)
	-- stuck to the real screen's edge (20:9, 4:3: ui/screen.lua)
	gui.set_yanchor(p.root, in_battle and gui.ANCHOR_TOP or gui.ANCHOR_BOTTOM)
end

-- The dots, one per place, to the right of the text
local function place_dots(p, of)
	for _, d in ipairs(p.dots) do gui.delete_node(d) end
	p.dots, p.of = {}, of
	for i = 1, of do
		local d = gui.new_box_node(vmath.vector3(232 - (of - i) * (DOT + 6), 0, 0), vmath.vector3(DOT, DOT, 0))
		gui.set_texture(d, "ui")
		gui.play_flipbook(d, "forma")
		gui.set_parent(d, p.root)
		p.dots[i] = d
	end
end

function M.set(p, text, places, of, hot)
	gui.set_text(p.text, text)
	if of ~= p.of then place_dots(p, of) end
	for i, d in ipairs(p.dots) do
		gui.set_color(d, i <= places and C.TEXT or with_alpha(C.LIGHT, 0.25))
	end
	p.hot = hot
	gui.set_color(p.border, hot and C.BRACE or C.LINE)
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
	return gui.is_enabled(p.root) and gui.pick_node(p.panel, x, y)
end

function M.raise(p)
	gui.move_above(p.veil, nil)
	gui.move_above(p.root, nil)
end

function M.update(p, dt)
	if not gui.is_enabled(p.root) then return end
	p.t = p.t + dt
	-- the full queue breathes in the accent color
	if p.hot then
		gui.set_color(p.border, with_alpha(C.BRACE, 0.6 + 0.4 * math.sin(p.t * 8)))
	end
end

return M
