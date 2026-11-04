-- Favilla in the cortile and her spark (sim/missions.lua, guida and scintilla).
-- Favilla is a puppet: the lesson says where she is every tick, here she's
-- drawn with the same rig as the robots (battle/scoria.lua) and is never hit.
-- Until her pieces arrive (WB-013) she wears the character in her light blue
-- (level plan, choice 1). The spark is a light blue glow that pulses in the
-- air, where a full jump reaches.
--
--   local favilla = require "battle.favilla"
--   local f = favilla.new(world, under)   -- world: the world node; under: the node to stay behind
--   favilla.update(f, dt, clock, pos, sx, sy)  -- every frame: pos = missions.guida(r) or nil,
--                                            -- sx, sy = missions.scintilla(r) or nil
--   favilla.destroy(f)

local scoria = require "battle.scoria"
local ui = require "ui.ui"

local M = {}

-- her light blue (WB-013, the shadow of her flame #8CCFEF)
local COLOR = vmath.vector4(0.55, 0.81, 0.94, 1)
local SPARK = vmath.vector4(0.75, 0.93, 1, 0.9)
local SPARK_D = 26
local V = vmath.vector3()

function M.new(world, under)
	local f = { st = { turno = false } }
	f.rig = scoria.new(COLOR, scoria.PERSONAGGIO)
	gui.set_parent(f.rig.root, world)
	if under then gui.move_below(f.rig.root, under) end
	scoria.set_weapon(f.rig, "missile")
	scoria.empty_hands(f.rig, true)
	scoria.set_enabled(f.rig, false)
	f.spark = ui.alone(0, 0, SPARK_D, SPARK, world)
	f.core = ui.alone(0, 0, SPARK_D * 0.45, vmath.vector4(1, 1, 1, 1), f.spark)
	gui.set_enabled(f.spark, false)
	return f
end

function M.update(f, dt, clock, pos, sx, sy)
	scoria.set_enabled(f.rig, pos ~= nil)
	if pos then
		local st = f.st
		st.x, st.y, st.grounded, st.moving, st.facing = pos.x, pos.y, pos.grounded, pos.vx, pos.facing
		scoria.update(f.rig, dt, st)
	end
	gui.set_enabled(f.spark, sx ~= nil)
	if sx then
		-- it floats a little and breathes
		V.x, V.y = sx, sy + 6 + math.sin(clock * 3) * 3
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
end

return M
