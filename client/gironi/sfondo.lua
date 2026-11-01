-- Lo sfondo vivo di un girone: un solo nodo della GUI grande come tutto lo
-- schermo, disegnato dal suo materiale (gironi/<girone>.fp con i piani di
-- gironi/strati.glsl). Niente immagini: costa un rettangolo.
--
--   local sfondo = require "gironi.sfondo"
--   local s = sfondo.new("forgia", parent)   -- il nome del materiale in game.gui
--   sfondo.update(s, dt)                      -- a ogni frame mentre si vede
--
-- Un girone nuovo: gironi/<nome>.fp e .material (forgia.fp è il modello) e una
-- riga materials in game.gui.

local schermo = require "ui.schermo"

local M = {}

local W, H = 1280, 720
-- dopo 256 secondi il tempo ricomincia (sta in due canali del colore)
local GIRO_TEMPO = 256

function M.new(girone, parent)
	local n = gui.new_box_node(vmath.vector3(W / 2, H / 2, 0), vmath.vector3(W * schermo.PIENO, H * schermo.PIENO, 0))
	gui.set_adjust_mode(n, gui.ADJUST_FIT)
	gui.set_material(n, girone)
	if parent then gui.set_parent(n, parent) end
	local s = { nodo = n, t = 0, colore = vmath.vector4(0, 0, 0.25, 1) }
	M.update(s, 0)
	return s
end

-- Il tempo e la misura di un pixel passano nel colore del nodo (gironi/girone.vp):
-- r il resto del secondo, g i secondi interi, b quanti pixel del gioco fa un
-- pixel dello schermo (diviso 4)
function M.update(s, dt)
	s.t = (s.t + dt) % GIRO_TEMPO
	local w, h = window.get_size()
	local u = math.min(w / W, h / H)
	local c = s.colore
	c.x = s.t % 1
	c.y = math.floor(s.t) / 255
	c.z = u > 0 and math.min(1, 1 / (u * 4)) or 0.25
	gui.set_color(s.nodo, c)
end

return M
