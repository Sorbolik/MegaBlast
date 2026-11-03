-- The entry screen (Sergio, 1 Nov: proposal C "Fiammella"): the live
-- background of the circle you have reached (today the Prologue, the Forge:
-- gironi/forgia.fp), in the middle Favilla's head in a breathing paper disc,
-- the name below. It stays until the game has what the home needs from the
-- server (main/game.gui_script entra), then it dissolves.
--
--   local ingresso = require "ui.ingresso"
--   local e = ingresso.new()
--   ingresso.update(e, dt)
--   ingresso.riga(e, "Senza rete")      -- the line under the name
--   ingresso.close_view(e, done)             -- fade, then done() and the nodes go

local ui = require "ui.ui"
local screen = require "ui.schermo"
local background = require "gironi.sfondo"

local M = {}

local W, H = 1280, 720
local CARD = vmath.vector4(0.94, 0.9, 0.82, 1)
-- how long the fade toward the home lasts
M.FADE = 0.16

local V = vmath.vector3()

local function child(n, parent)
	gui.set_parent(n, parent)
	gui.set_inherit_alpha(n, true)
	return n
end

function M.new()
	local e = { t = 0 }
	e.radice = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(0, 0, 0))
	gui.set_visible(e.radice, false)
	e.sfondo = background.new("forgia")
	child(e.sfondo.nodo, e.radice)
	-- the disc: an ember halo behind, the paper with Favilla's head
	e.centro = gui.new_box_node(vmath.vector3(W / 2, H / 2 + 50, 0), vmath.vector3(0, 0, 0))
	gui.set_adjust_mode(e.centro, gui.ADJUST_FIT)
	gui.set_visible(e.centro, false)
	child(e.centro, e.radice)
	e.alone = child(ui.alone(0, 0, 520, ui.C.BRACE), e.centro)
	e.disco = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(230, 230, 0))
	gui.set_texture(e.disco, "ui")
	gui.play_flipbook(e.disco, "favilla")
	gui.set_color(e.disco, CARD)
	child(e.disco, e.centro)
	local nome = child(ui.titolo("MEGABLAST", 0, -185, 1.2, ui.C.LIGHT), e.centro)
	gui.set_adjust_mode(nome, gui.ADJUST_FIT)
	e.riga = child(ui.testo("", 0, -240, 0.75, ui.C.TEXT), e.centro)
	M.update(e, 0)
	return e
end

function M.update(e, dt)
	e.t = e.t + dt
	background.update(e.sfondo, dt)
	-- the paper breathes slowly, the ember behind pulses
	local k = 1 + 0.025 * math.sin(e.t * 3.4)
	V.x, V.y, V.z = k, k, 1
	gui.set_scale(e.disco, V)
	local c = ui.C.BRACE
	gui.set_color(e.alone, vmath.vector4(c.x, c.y, c.z, 0.32 + 0.1 * math.sin(e.t * 2.1)))
end

function M.riga(e, txt)
	gui.set_text(e.riga, txt)
end

function M.close_view(e, done)
	if e.closed then return end
	e.closed = true
	gui.animate(e.radice, "color.w", 0, gui.EASING_OUTQUAD, M.FADE, 0, function()
		gui.delete_node(e.radice)
		if done then done() end
	end)
end

-- at once, without fading (the scenarios that start already in a match)
function M.via(e)
	if e.closed then return end
	e.closed = true
	gui.delete_node(e.radice)
end

return M
