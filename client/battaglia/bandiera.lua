-- The lessons' checkered flag (sim/missions.lua, reach with flag): a
-- pole and a black-and-white checkered drape waving, in the world, where you
-- have to get to. A few nodes made once.
--
--   local b = bandiera.new(world, under)   -- world: the world node; under: the node to keep in front of
--   b:display(x, y, clock)                    -- every frame; x nil: not there

local M = {}

-- sizes in world units (the devil is about twenty tall)
local POLE_H, POLE_W = 38, 1.6
local COLUMNS, ROWS, SIDE = 6, 4, 3
local WHITE = vmath.vector4(0.95, 0.93, 0.9, 1)
local BLACK = vmath.vector4(0.08, 0.07, 0.09, 1)
local POLE = vmath.vector4(0.62, 0.58, 0.55, 1)
local V = vmath.vector3()
local EULER = vmath.vector3()

local function box(x, y, w, h, color, parent)
	local n = gui.new_box_node(vmath.vector3(x, y, 0), vmath.vector3(w, h, 0))
	gui.set_color(n, color)
	gui.set_parent(n, parent)
	return n
end

function M.new(world, under)
	local b = setmetatable({}, { __index = M })
	b.radice = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(0, 0, 0))
	gui.set_parent(b.radice, world)
	if under then gui.move_below(b.radice, under) end
	box(0, POLE_H / 2, POLE_W, POLE_H, POLE, b.radice)
	-- the drape turns around the attachment at the top of the pole
	b.drape = box(POLE_W / 2, POLE_H - ROWS * SIDE / 2, 0, 0, WHITE, b.radice)
	for i = 0, COLUMNS - 1 do
		for j = 0, ROWS - 1 do
			box((i + 0.5) * SIDE, (j + 0.5 - ROWS / 2) * SIDE, SIDE, SIDE, (i + j) % 2 == 0 and BLACK or WHITE, b.drape)
		end
	end
	gui.set_enabled(b.radice, false)
	return b
end

function M.display(b, x, y, clock)
	gui.set_enabled(b.radice, x ~= nil)
	if not x then return end
	V.x, V.y, V.z = x, y, 0
	gui.set_position(b.radice, V)
	EULER.z = math.sin((clock or 0) * 3) * 6
	gui.set_euler(b.drape, EULER)
end

return M
