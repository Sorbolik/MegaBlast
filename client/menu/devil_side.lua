-- The devil on the left of the screens that are not yet redrawn (ALLENAMENTO,
-- the queue, the private room, the events' board), with a glowing line under it
-- that says what the place is. Where there is room at the sides (a screen
-- wider than 16:9) it goes left with the real edge and the rest breathes
-- (Sergio, 11 Nov; the measures are kit.side, kit.lean and kit.air).
--
--   local devil_side = require "menu.devil_side"
--   devil_side.x(), devil_side.Y                -- where the devil is (Figma coordinates)
--   devil_side.devil(s, line)                   -- s: colore, radice, low, accent

local ui = require "ui.ui"
local kit = require "ui.kit"
local game = require "sim.game"
local scoria = require "battle.scoria"
local clock = require "ui.clock"

local M = {}

local C = ui.C
local KC = kit.C

function M.x() return 250 - kit.side() end
M.Y = 420    -- its height (the middle of its body)

local function box(x, y, parent)
	local n = gui.new_box_node(vmath.vector3(x, y, 0), vmath.vector3(0, 0, 0))
	gui.set_parent(n, parent)
	gui.set_visible(n, false)
	return n
end

function M.devil(s, line)
	-- the content leans toward the devil and its columns part (kit.air)
	local rp = gui.get_position(s.radice)
	rp.x = -kit.lean()
	gui.set_position(s.radice, rp)
	if s.kg then s.kg.air = true end
	-- its feet on the thread
	local pose = box(M.x() + kit.lean(), kit.BAND + 8, s.radice)
	s.figure = scoria.new(s.colore, scoria.player)
	clock.sync(s.figure)
	s.st = { x = 0, y = 0, facing = 1, grounded = true, moving = 0, fermo = true }
	scoria.update(s.figure, 0, s.st)
	local k = 300 / game.DISEGNO_H
	gui.set_scale(pose, vmath.vector3(k, k, 1))
	gui.set_parent(s.figure.root, pose)
	scoria.set_enabled(s.figure, true)
	-- a glowing line that says what the place is
	local on_plate = kit.caption(s.low, kit.PLATE_X, kit.PLATE_Y, 340, 62, 22)
	kit.text(on_plate.g, line, kit.PLATE_X + 170, kit.PLATE_Y + 38, 22, kit.TAB_HOT, "middle", 1)
end

return M
