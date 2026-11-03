-- The waiting flame (Sergio, 1 Nov): when the game really waits for something
-- (the connection, the opponents, the reconnection) Favilla's head burns in
-- the middle of the screen in its paper disc, with a line below. It appears
-- only if the wait lasts more than AFTER seconds (short waits don't show)
-- and, once it appears, it stays at least AT_LEAST seconds (no flicker).
--
--   local attesa = require "ui.waiting"
--   local a = attesa.new()
--   attesa.display(a, "In attesa di un avversario...")
--   attesa.via(a)
--   attesa.update(a, dt)

local ui = require "ui.ui"

local M = {}

M.AFTER = 0.3
M.AT_LEAST = 0.4
local CARD = vmath.vector4(0.94, 0.9, 0.82, 1)
local V = vmath.vector3()

function M.new()
	local a = { t = 0 }
	a.nodo = gui.new_box_node(vmath.vector3(640, 380, 0), vmath.vector3(0, 0, 0))
	gui.set_visible(a.nodo, false)
	a.alone = ui.alone(0, 0, 300, ui.C.BRACE, a.nodo)
	a.disco = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(120, 120, 0))
	gui.set_texture(a.disco, "ui")
	gui.play_flipbook(a.disco, "favilla")
	gui.set_color(a.disco, CARD)
	gui.set_parent(a.disco, a.nodo)
	a.riga = ui.testo("", 0, -100, 0.8, ui.C.TEXT, a.nodo)
	gui.set_enabled(a.nodo, false)
	return a
end

function M.display(a, txt)
	gui.set_text(a.riga, txt)
	if not a.requested then
		a.requested, a.t, a.visto = true, 0, nil
	end
	a.close_view = nil
end

function M.via(a)
	if not a.requested then return end
	if a.visto and a.visto < M.AT_LEAST then
		a.close_view = true
		return
	end
	a.requested, a.visto, a.close_view = nil, nil, nil
	gui.set_enabled(a.nodo, false)
end

function M.update(a, dt)
	if not a.requested then return end
	a.t = a.t + dt
	if not a.visto and a.t >= M.AFTER then
		a.visto = 0
		gui.set_enabled(a.nodo, true)
		gui.move_above(a.nodo, nil)
	end
	if not a.visto then return end
	a.visto = a.visto + dt
	if a.close_view and a.visto >= M.AT_LEAST then
		M.via(a)
		return
	end
	-- burning: breathes fast, the ember pulses
	local k = 1 + 0.035 * math.sin(a.t * 7)
	V.x, V.y, V.z = k, k, 1
	gui.set_scale(a.disco, V)
	local c = ui.C.BRACE
	gui.set_color(a.alone, vmath.vector4(c.x, c.y, c.z, 0.28 + 0.1 * math.sin(a.t * 4.3)))
end

return M
