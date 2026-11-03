-- The live background of a circle: a single GUI node as big as the whole
-- screen, drawn by its material (gironi/<circle>.fp with the planes of
-- gironi/strati.glsl). No images: it costs one rectangle.
--
--   local sfondo = require "gironi.sfondo"
--   local s = sfondo.new("forgia", parent)   -- the material's name in game.gui
--   sfondo.update(s, dt)                      -- every frame while it is visible
--
-- A new circle: gironi/<name>.fp and .material (forgia.fp is the model) and a
-- materials line in game.gui.

local screen = require "ui.schermo"

local M = {}

local W, H = 1280, 720
-- after 256 seconds time starts over (it lives in two color channels)
local ROUND_TIME = 256

function M.new(circle, parent)
	local n = gui.new_box_node(vmath.vector3(W / 2, H / 2, 0), vmath.vector3(W * screen.FULL, H * screen.FULL, 0))
	gui.set_adjust_mode(n, gui.ADJUST_FIT)
	gui.set_material(n, circle)
	if parent then gui.set_parent(n, parent) end
	local s = { nodo = n, t = 0, colore = vmath.vector4(0, 0, 0.25, 1) }
	M.update(s, 0)
	return s
end

-- Time and the size of a pixel go through the node's color (gironi/girone.vp):
-- r the fraction of the second, g the whole seconds, b how many game pixels
-- one screen pixel is (divided by 4)
function M.update(s, dt)
	s.t = (s.t + dt) % ROUND_TIME
	local w, h = window.get_size()
	local u = math.min(w / W, h / H)
	local c = s.colore
	c.x = s.t % 1
	c.y = math.floor(s.t) / 255
	c.z = u > 0 and math.min(1, 1 / (u * 4)) or 0.25
	gui.set_color(s.nodo, c)
end

return M
