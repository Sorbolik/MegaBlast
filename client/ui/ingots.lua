-- The level of a piece as thirty beads on an ink thread (Sergio, 18 Nov, 12:47:
-- «proviamole», variant 2 of the page "Proposte zaino e scatto"; 12:48: the official
-- way to show the upgrades everywhere). The beads reached in the grade's color, the
-- next one in ember, the others dark iron; at 10, 20 and 30, once the step is done,
-- the big bead of the signature: a round iron token with a hollow in the shape of the
-- gem (the gem in it when the Ossidiana lit it). Drawn here until the art of WB-074.
-- Used by the piece's card (menu/bench.lua), the ZAINO's band, the step's scene
-- (ui/step_scene.lua) and the signature's lighting (ui/sign_light.lua).
--
--   local ingots = require "ui.ingots"
--   local bar = ingots.draw(g, x, y, w, h, level, lit, born)
--   bar.set(level, color, time, delay)  -- the beads up to level (time: a wave from the left)

local ui = require "ui.ui"
local kit = require "ui.kit"
local equip = require "sim.gear"

local KC = kit.C
local M = {}

local vec = function(x, y) return vmath.vector3(x, y, 0) end
local function hex(s)
	return vmath.vector4(tonumber(s:sub(1, 2), 16) / 255, tonumber(s:sub(3, 4), 16) / 255, tonumber(s:sub(5, 6), 16) / 255, 1)
end
local IRON, IRON_L, IRON_D = hex("3a3340"), hex("5a5263"), hex("1e1a22")
local HOLLOW = hex("141017")
local STUD_OFF = HOLLOW
M.LEVELS = 30
M.STUD_OFF = STUD_OFF

-- The gem's hollow, d wide (a bit taller): squares turned 45 degrees with round
-- corners, squeezed into a rhombus; made at 96 px and scaled, so the corners stay
-- round at every size. Returns its bottom (the node the heat colors)
local function hollow(parent, d)
	local tall = vmath.vector3(1, 1.21, 1)
	local squeeze = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_visible(squeeze, false)
	gui.set_parent(squeeze, parent)
	gui.set_scale(squeeze, tall)
	local turn = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_visible(turn, false)
	gui.set_parent(turn, squeeze)
	gui.set_rotation(turn, vmath.vector3(0, 0, 45))
	local side = d * 0.95 / math.sqrt(2)
	local k = side / 96
	gui.set_scale(turn, vmath.vector3(k, k, 1))
	local function sq(f, color, ox, oy)
		return ui.sagoma("forma", ox or 0, oy or 0, 96 * f, 96 * f, color, turn)
	end
	-- (turned that way, the square's own (-1, 1) points up on the screen)
	sq(1, KC.INK)
	sq(0.86, IRON)
	sq(0.8, IRON_L, 6, -6)
	sq(0.8, IRON_D, -6, 6)
	sq(0.62, KC.INK)
	return sq(0.56, HOLLOW)
end

-- A bead d wide at x: ink, its color, a light on the top left. Returns the node
-- that takes the color
local function bead(parent, x, d, color)
	local n = gui.new_box_node(vec(x, 0), vec(0, 0))
	gui.set_visible(n, false)
	gui.set_parent(n, parent)
	ui.disc(0, 0, d, KC.INK, n)
	local face = ui.disc(0, 0, d - math.max(2, d * 0.28), color, n)
	ui.disc(-d * 0.14, d * 0.14, d * 0.26, vmath.vector4(1, 1, 1, 0.45), n)
	return n, face
end

local function bead_color(i, lv, color)
	if i <= lv then return color or ui.C.GRADI[equip.tier(math.max(1, lv))] end
	if i == lv + 1 then return KC.HOT_BOTTOM end
	return IRON
end

-- The thirty beads w wide from (x, y) (Figma), h tall (the signature's big beads;
-- the small ones about a third of it); lit: how many signature slots are lit;
-- born: a slot drawn before its step (the step's scene makes it grow).
-- Returns { node, beads, faces, next, tip, studs, gems, lit_parts, set }: beads are
-- the small beads' nodes (nil where a slot is), studs the slots (only those there),
-- gems their hollows' bottoms, lit_parts the gem in a lit one, next the next bead
function M.draw(g, x, y, w, h, level, lit, born)
	local root = gui.new_box_node(vec(x - g.ox, g.oy - (y + h / 2)), vec(0, 0))
	gui.set_visible(root, false)
	gui.set_parent(root, g.node)
	local bar = { node = root, level = level, beads = {}, faces = {} }
	local d = h
	local pitch = (w - d) / (M.LEVELS - 1)
	local small = math.min(pitch * 0.72, math.max(6, h * 0.42))
	local function at(i) return d / 2 + (i - 1) * pitch end
	-- the thread
	ui.sagoma(nil, w / 2, 0, w - d, math.max(2, math.floor(h * 0.12)), KC.INK, root)
	-- the slots there (from their step on), the small beads elsewhere
	bar.studs, bar.gems, bar.lit_parts = {}, {}, {}
	local slot_at = {}
	for s = 1, 3 do
		if level >= s * 10 or born == s then slot_at[s * 10] = s end
	end
	for i = 1, M.LEVELS do
		local s = slot_at[i]
		if s then
			local stud = gui.new_box_node(vec(at(i), 0), vec(0, 0))
			gui.set_visible(stud, false)
			gui.set_parent(stud, root)
			ui.disc(0, 0, d, KC.INK, stud)
			local b = math.max(2, d * 0.1)
			ui.disc(0, 0, d - 2 * b, IRON, stud)
			ui.disc(-d * 0.2, d * 0.2, d * 0.22, kit.with_alpha(IRON_L, 0.9), stud)
			bar.gems[s] = hollow(stud, d * 0.62)
			if s <= (lit or 0) then
				bar.lit_parts[s] = { kit.piece({ node = stud, ox = 0, oy = 0 }, "gemma", 0, 0, d * 0.62) }
			end
			bar.studs[s] = stud
		else
			bar.beads[i], bar.faces[i] = bead(root, at(i), small, IRON)
		end
	end
	bar.tip = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_visible(bar.tip, false)
	gui.set_parent(bar.tip, root)

	-- the beads up to lv in color (its grade's by default); time > 0: a wave from the left
	function bar.set(lv, color, time, delay)
		bar.level = lv
		for i = 1, M.LEVELS do
			local f = bar.faces[i]
			if f then
				local c = bead_color(i, lv, color)
				if time and time > 0 and i <= lv then
					gui.animate(f, "color", c, gui.EASING_OUTQUAD, 0.12, (delay or 0) + time * (i - 1) / math.max(1, lv))
				else
					gui.cancel_animations(f, "color")
					gui.set_color(f, c)
				end
			end
		end
		bar.next = bar.beads[lv + 1]
		bar.next_face = bar.faces[lv + 1]
		gui.set_position(bar.tip, vec(at(math.max(1, lv)), 0))
	end

	bar.set(level)
	return bar
end

return M
