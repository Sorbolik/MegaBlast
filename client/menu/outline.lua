-- The lit contour of the worn pieces, in the backpack and in the armory: each
-- place of the gear (helmet with the horns, armour with the shoulder pads, the
-- two boots, the gloves) has one line along its outer edge, as it is seen on the
-- devil, nothing inside (Sergio, 18 Nov: «devi andare solo di contorni»).
--
-- A second devil, never seen (scoria.new with shadow), follows the real one and
-- is drawn apart into two images (render/lit.render_script): where each place's
-- pieces are and what is in front. A node over the devil draws the line from
-- them (battle/outline.fp). The cape is behind everything: it lights its own
-- edge (battle/cape.fp).
--
--   outline.new(figure, pose, look)  over the devil figure (wearing look), in the node pose
--   outline.colors(o, colors)      { elmo = vector4, corazza =, stivali =, guanti =, mantello = } or nil each
--   outline.update(o)              every frame, after scoria.update
--   outline.off()                  when the screen closes

local scoria = require "battle.scoria"

local M = {}

local PLACES = { "elmo", "corazza", "stivali", "guanti" }
local NONE = vmath.vector4(0, 0, 0, 0)
-- the rectangle around the devil, in its own units from the feet: half the
-- width, below, above (tail, cape and horns inside)
local HALF, BELOW, ABOVE = 1.05, 0.12, 1.75
-- the line's width, in devil heights: the least, and the most where the drawing's
-- black line is wider
local WIDTH, WIDTH_INK = 0.0115, 0.032
-- two pieces of a place nearer than twice this are one shape (devil heights)
local CLOSE = 0.016
-- the glow around the lit pieces: how far it goes (devil heights) and how strong
local GLOW, GLOW_ALPHA = 0.05, 0.38

function M.new(figure, pose, look)
	local o = { figure = figure }
	o.shadow = scoria.new(figure.color, look, nil, false, true)
	gui.set_parent(o.shadow.root, pose)
	scoria.set_enabled(o.shadow, true)
	local h = scoria.height()
	local function corner(x, y)
		local n = gui.new_box_node(vmath.vector3(x, y, 0), vmath.vector3(0, 0, 0))
		gui.set_parent(n, pose)
		gui.set_visible(n, false)
		return n
	end
	o.low = corner(-HALF * h, -BELOW * h)
	o.high = corner(HALF * h, ABOVE * h)
	-- the line: a node as big as the rectangle (the material reads the window's pixels)
	o.node = gui.new_box_node(vmath.vector3(0, (ABOVE - BELOW) / 2 * h, 0),
		vmath.vector3(2 * HALF * h, (ABOVE + BELOW) * h, 0))
	gui.set_parent(o.node, pose)
	gui.set_material(o.node, "contorno")
	-- the cape's line: right above the cape, under the body (it stays there when
	-- the clips change the layers)
	if figure.mantello then
		o.cape = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(8 * h, 8 * h, 0))
		gui.set_parent(o.cape, gui.get_parent(figure.mantello))
		gui.set_material(o.cape, "contorno_mantello")
		gui.move_above(o.cape, figure.mantello)
		table.insert(figure.level_nodes.mantello, o.cape)
	end
	-- the node of the passes over the silhouettes' images (closing the slits, the
	-- glow): drawn only into them, over all of the image
	o.closer = gui.new_box_node(vmath.vector3(0, (ABOVE - BELOW) / 2 * h, 0),
		vmath.vector3(4 * HALF * h, 2 * (ABOVE + BELOW) * h, 0))
	gui.set_parent(o.closer, pose)
	gui.set_material(o.closer, "sagoma_chiudi")
	o.h = h
	M.colors(o, {})
	M.update(o)
	return o
end

function M.colors(o, colors)
	for i, place in ipairs(PLACES) do
		gui.set(o.node, "c" .. i, colors[place] or NONE)
	end
	if o.cape then gui.set(o.cape, "c1", colors.mantello or NONE) end
end

function M.update(o)
	scoria.mirror(o.shadow, o.figure)
	local a, b = gui.get_screen_position(o.low), gui.get_screen_position(o.high)
	local x, y = math.floor(a.x), math.floor(a.y)
	local w, h = math.ceil(b.x) - x, math.ceil(b.y) - y
	if x ~= o.x or y ~= o.y or w ~= o.w or h ~= o.hh then
		o.x, o.y, o.w, o.hh = x, y, w, h
		msg.post("@render:", "outline", { rect = vmath.vector4(x, y, w, h), close = CLOSE * h / (ABOVE + BELOW),
			glow = GLOW * h / (ABOVE + BELOW) })
		local width = vmath.vector4(WIDTH * h / (ABOVE + BELOW), WIDTH_INK * h / (ABOVE + BELOW), GLOW_ALPHA, 0)
		gui.set(o.node, "width", width)
		if o.cape then gui.set(o.cape, "width", width) end
	end
end

function M.off()
	msg.post("@render:", "outline", {})
end

return M
