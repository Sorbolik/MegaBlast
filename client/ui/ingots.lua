-- The level of a piece as thirty beads on an ink thread (Sergio, 18 Nov, 12:47:
-- «proviamole», variant 2 of the page "Proposte zaino e scatto"; 12:48: the official
-- way to show the upgrades everywhere). The beads reached in the grade's color, the
-- next one in ember, the others dark iron; at 10, 20 and 30, once the step is done,
-- the big bead of the signature: a round iron token with a hollow in the shape of the
-- gem (the gem in it when the Ossidiana lit it). The pieces are WB-074's.
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
M.LEVELS = 30

-- The beads' pieces (WB-074): the full one is grey, the game tints it with the grade
local function bead_piece(i, lv)
	if i <= lv then return "perla_piena" end
	if i == lv + 1 then return "perla_prossima" end
	return "perla_vuota"
end

-- The thirty beads w wide from (x, y) (Figma), h tall (the signature's slots; the
-- small beads under half of it). Every bead and slot has its own room, the same gap
-- between all of them: the slots never sit over the beads (Sergio, 18 Nov). lit: how
-- many signature slots are lit; born: a slot drawn before its step (the step's scene
-- makes it grow). Returns { node, beads, next, tip, studs, gems, hot, lit_parts, set }:
-- beads the small beads (nil where a slot is), studs the slots there, hot their
-- red-hot face (hidden), lit_parts the lit one's, next the next bead, seed the
-- ember bead in the place of the slot about to be born
function M.draw(g, x, y, w, h, level, lit, born)
	local root = gui.new_box_node(vec(x - g.ox, g.oy - (y + h / 2)), vec(0, 0))
	gui.set_visible(root, false)
	gui.set_parent(root, g.node)
	local bar = { node = root, level = level, beads = {}, kind = {} }
	local d = h
	local b = math.min(h * 0.46, (w - 3 * d - 29 * 3) / 27)
	local gap = (w - 27 * b - 3 * d) / 29
	local at, cx = {}, 0
	for i = 1, M.LEVELS do
		local size = i % 10 == 0 and d or b
		at[i] = cx + size / 2
		cx = cx + size + gap
	end
	-- the thread
	ui.sagoma(nil, w / 2, 0, w - d, math.max(2, math.floor(h * 0.1)), KC.INK, root)
	bar.studs, bar.gems, bar.hot, bar.lit_parts = {}, {}, {}, {}
	for i = 1, M.LEVELS do
		local s = i % 10 == 0 and i / 10
		if s and (level >= i or born == s) then
			local stud = gui.new_box_node(vec(at[i], 0), vec(0, 0))
			gui.set_visible(stud, false)
			gui.set_parent(stud, root)
			local pg = { node = stud, ox = 0, oy = 0 }
			bar.gems[s] = kit.piece(pg, "slot_vuoto", 0, 0, d)
			if s <= (lit or 0) then bar.lit_parts[s] = { kit.piece(pg, "slot_acceso", 0, 0, d) } end
			bar.hot[s] = kit.piece(pg, "slot_rovente", 0, 0, d)
			gui.set_enabled(bar.hot[s], false)
			bar.studs[s] = stud
			if born == s and level < i then
				-- until it is born, the next bead (in ember) holds its place: the dot it grows from
				local n = gui.new_box_node(vec(at[i], 0), vec(0, 0))
				gui.set_visible(n, false)
				gui.set_parent(n, root)
				bar.seed = kit.piece({ node = n, ox = 0, oy = 0 }, "perla_prossima", 0, 0, b)
			end
		else
			local n = gui.new_box_node(vec(at[i], 0), vec(0, 0))
			gui.set_visible(n, false)
			gui.set_parent(n, root)
			bar.beads[i] = kit.piece({ node = n, ox = 0, oy = 0 }, "perla_vuota", 0, 0, b)
		end
	end
	bar.tip = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_visible(bar.tip, false)
	gui.set_parent(bar.tip, root)

	-- the beads up to lv (in color: its grade's by default); time > 0: a wave from the left
	function bar.set(lv, color, time, delay)
		bar.level = lv
		local tint = color or ui.C.GRADI[equip.tier(math.max(1, lv))]
		for i = 1, M.LEVELS do
			local n = bar.beads[i]
			if n then
				local kind = bead_piece(i, lv)
				local function show()
					gui.play_flipbook(n, kind)
					gui.set_color(n, i <= lv and tint or vmath.vector4(1, 1, 1, 1))
				end
				if time and time > 0 and i <= lv then
					gui.animate(n, "scale", gui.get_scale(n), gui.EASING_LINEAR, 0.001,
						(delay or 0) + time * (i - 1) / math.max(1, lv), show)
				else
					show()
				end
			end
		end
		bar.next = bar.beads[lv + 1]
		gui.set_position(bar.tip, vec(at[math.max(1, lv)], 0))
	end

	bar.set(level)
	return bar
end

return M
