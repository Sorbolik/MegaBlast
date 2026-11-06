-- Favilla in the cortile and her spark (sim/missions.lua, guida and scintilla).
-- Favilla is a puppet: the lesson says where she is every tick, here she's
-- drawn with the same rig as the robots (battle/scoria.lua), in her own pieces
-- (WB-013, skin "favilla"), and is never hit. The spark is a light blue glow
-- that pulses in the air, where a full jump reaches.
--
--   local favilla = require "battle.favilla"
--   local f = favilla.new(world, under)   -- world: the world node; under: the node to stay behind
--   favilla.update(f, dt, clock, pos, sx, sy, look_x)  -- every frame: pos = missions.guida(r) or nil,
--                                            -- sx, sy = missions.scintilla(r) or nil,
--                                            -- look_x = where she turns when still (you)
--   favilla.destroy(f)

local scoria = require "battle.scoria"
local ui = require "ui.ui"
local T = require("lang.text").vignette

local M = {}

-- her pieces (battle/skins.lua)
M.LOOK = { "favilla" }

-- her light blue (WB-013, the shadow of her flame #8CCFEF)
local COLOR = vmath.vector4(0.55, 0.81, 0.94, 1)
local SPARK = vmath.vector4(0.75, 0.93, 1, 0.9)
local SPARK_D = 26
-- her name above her head, in her light blue (world units: it follows the zoom)
local NAME_Y, NAME_SCALE = 58, 0.15
local V = vmath.vector3()

function M.new(world, under)
	local f = { st = { turno = false } }
	f.rig = scoria.new(COLOR, M.LOOK)
	gui.set_parent(f.rig.root, world)
	if under then gui.move_below(f.rig.root, under) end
	scoria.set_weapon(f.rig, "missile")
	scoria.empty_hands(f.rig, true)
	scoria.set_enabled(f.rig, false)
	f.name = gui.new_text_node(vmath.vector3(0, 0, 0), T.favilla_name)
	gui.set_parent(f.name, world)
	gui.set_font(f.name, "titolo")
	gui.set_color(f.name, COLOR)
	gui.set_outline(f.name, ui.C.SHADOW)
	gui.set_scale(f.name, vmath.vector3(NAME_SCALE, NAME_SCALE, 1))
	gui.set_enabled(f.name, false)
	f.spark = ui.alone(0, 0, SPARK_D, SPARK, world)
	f.core = ui.alone(0, 0, SPARK_D * 0.45, vmath.vector4(1, 1, 1, 1), f.spark)
	gui.set_enabled(f.spark, false)
	return f
end

function M.update(f, dt, clock, pos, sx, sy, look_x)
	scoria.set_enabled(f.rig, pos ~= nil)
	gui.set_enabled(f.name, pos ~= nil)
	if pos then
		local st = f.st
		st.x, st.y, st.grounded, st.moving, st.facing = pos.x, pos.y, pos.grounded, pos.vx, pos.facing
		-- standing still she looks at you
		if pos.vx == 0 and look_x and look_x ~= pos.x then st.facing = look_x < pos.x and -1 or 1 end
		scoria.update(f.rig, dt, st)
		V.x, V.y, V.z = pos.x, pos.y + NAME_Y, 0
		gui.set_position(f.name, V)
	end
	gui.set_enabled(f.spark, sx ~= nil)
	if sx then
		-- it floats a little and breathes
		V.x, V.y = sx, sy + math.sin(clock * 3) * 3 -- centred where the simulation takes it
		gui.set_position(f.spark, V)
		local k = 1 + math.sin(clock * 7) * 0.15
		V.x, V.y, V.z = k, k, 1
		gui.set_scale(f.spark, V)
		V.z = 0
	end
end

function M.destroy(f)
	gui.delete_node(f.rig.root)
	gui.delete_node(f.spark)
	gui.delete_node(f.name)
end

return M
