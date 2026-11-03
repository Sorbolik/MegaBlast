-- The marker on the lessons' target (sim/missions.lua bersaglio): four red
-- corners around whoever has to be hit now, like a locked-on reticle,
-- breathing. Different from the yellow light on the controls: that one says
-- what to use, this one whom to hit. In the world, a few nodes made once.
--
--   local s = segnale.new(world)        -- world: the world node
--   s:display(x, y, alto, largo, clock)    -- every frame: x, y the feet; x nil: not there

local M = {}

-- sizes in world units (the devil is about twenty tall)
local ARM, THICK, BORDER = 6, 1.6, 0.9
local MARGIN = 5
local RED = vmath.vector4(1, 0.3, 0.22, 1)
local DARK = vmath.vector4(0.1, 0.05, 0.07, 0.85)
local V = vmath.vector3()

local function box(w, h, color, parent)
	local n = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(w, h, 0))
	gui.set_color(n, color)
	gui.set_parent(n, parent)
	return n
end

-- a corner: a horizontal and a vertical stroke meeting at the vertex, with a
-- dark border below so it shows on any background
local function angle_deg(parent, sx, sy)
	local a = { radice = box(0, 0, DARK, parent), sx = sx, sy = sy }
	for _, color in ipairs({ DARK, RED }) do
		local b = color == DARK and BORDER or 0
		local o = box(ARM + 2 * b, THICK + 2 * b, color, a.radice)
		gui.set_position(o, vmath.vector3(sx * (ARM / 2 - THICK / 2), 0, 0))
		local v = box(THICK + 2 * b, ARM + 2 * b, color, a.radice)
		gui.set_position(v, vmath.vector3(0, sy * (ARM / 2 - THICK / 2), 0))
	end
	return a
end

function M.new(world)
	local s = setmetatable({}, { __index = M })
	s.radice = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(0, 0, 0))
	gui.set_parent(s.radice, world)
	-- each corner's vertex faces out, the arms toward the center
	s.angoli = {
		angle_deg(s.radice, 1, -1), angle_deg(s.radice, -1, -1),
		angle_deg(s.radice, 1, 1), angle_deg(s.radice, -1, 1),
	}
	gui.set_enabled(s.radice, false)
	return s
end

function M.display(s, x, y, tall, wide, clock)
	gui.set_enabled(s.radice, x ~= nil)
	if not x then return end
	V.x, V.y, V.z = x, y + tall / 2, 0
	gui.set_position(s.radice, V)
	-- breathes: tightens and widens slightly, twice a second
	local d = MARGIN + 1.5 * (1 + math.sin((clock or 0) * 6))
	local mx, my = wide + d, tall / 2 + d
	for _, a in ipairs(s.angoli) do
		V.x, V.y = -a.sx * mx, -a.sy * my
		gui.set_position(a.radice, V)
	end
end

return M
