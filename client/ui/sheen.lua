-- The light that runs over the frames of the piece cards (Sergio, 27 Nov: «la fascia
-- di luce che passa nella roccia del piedistallo», once for all of them, not card
-- by card): one straight band that crosses the whole screen now and then, the
-- pedestal's band of the home (battle/flash.fp, "band"), here in each frame's own
-- slot colour. A frame's light is a copy of its band (cornice_pezzo_luce), added
-- on top and on only while the band runs.
--
--   local sh = sheen.new(g, x0, x1)    the band runs from x0 to x1 (Figma x of g)
--   sheen.add(sh, node, color)         a node lit by the band, in that color
--   sheen.update(sh, dt)               every frame
-- The clock is shared: a screen built again does not restart the band.

local M = {}

-- every PERIOD seconds the band runs for RUN seconds; HALF its half width (Figma
-- pixels, as on the pedestal), STRENGTH how much light it adds
local PERIOD, RUN, HALF, STRENGTH = 6.5, 1.6, 35, 0.85
local clock = 2.5
local B = vmath.vector4()

function M.new(g, x0, x1)
	local sh = { nodes = {}, x0 = x0 - g.ox, x1 = x1 - g.ox }
	sh.at = gui.new_box_node(vmath.vector3(sh.x0, 0, 0), vmath.vector3(0, 0, 0))
	gui.set_visible(sh.at, false)
	gui.set_parent(sh.at, g.node)
	sh.edge = gui.new_box_node(vmath.vector3(HALF, 0, 0), vmath.vector3(0, 0, 0))
	gui.set_visible(sh.edge, false)
	gui.set_parent(sh.edge, sh.at)
	return sh
end

function M.add(sh, node, color)
	if not sh then return end
	gui.set_material(node, "lampo")
	gui.set_blend_mode(node, gui.BLEND_ADD)
	gui.set_color(node, color)
	gui.set_enabled(node, false)
	sh.nodes[#sh.nodes + 1] = node
end

local function ease(u)
	return u < 0.5 and 2 * u * u or 1 - (2 - 2 * u) * (2 - 2 * u) / 2
end

function M.update(sh, dt)
	if not sh then return end
	clock = (clock + dt) % PERIOD
	local on = clock < RUN
	if on then
		gui.set_position(sh.at, vmath.vector3(sh.x0 + (sh.x1 - sh.x0) * ease(clock / RUN), 0, 0))
		local p, e = gui.get_screen_position(sh.at), gui.get_screen_position(sh.edge)
		B.x, B.y, B.z, B.w = p.x, math.abs(e.x - p.x), -STRENGTH, 1
	end
	if on or sh.was_on then
		for _, n in ipairs(sh.nodes) do
			gui.set_enabled(n, on)
			if on then gui.set(n, "band", B) end
		end
	end
	sh.was_on = on
end

return M
