-- The level of a piece as one bar of molten metal (Sergio, 18 Nov, variant 3 of the
-- page "Proposte zaino e scatto": «vai di barra di metallo fuso»): a round ink tube
-- that fills with the grade's color like poured metal, the thirty levels only hinted
-- by thin marks, and at 10, 20 and 30 the round stud of the signature (magenta when
-- the Ossidiana lit it). Everything is round, as the rest of the game. Used by the
-- piece's card (menu/bench.lua), the ZAINO's band and the step's scene (ui/step_scene.lua).
--
--   local ingots = require "ui.ingots"
--   local bar = ingots.draw(g, x, y, w, h, level, lit)
--   bar.set(level, color, time)  -- the fill to that level (time: it flows there)

local ui = require "ui.ui"
local kit = require "ui.kit"
local equip = require "sim.gear"

local KC = kit.C
local M = {}

local vec = function(x, y) return vmath.vector3(x, y, 0) end
local function hex(s)
	return vmath.vector4(tonumber(s:sub(1, 2), 16) / 255, tonumber(s:sub(3, 4), 16) / 255, tonumber(s:sub(5, 6), 16) / 255, 1)
end
local TRACK = hex("2a2330")
local STUD_OFF = hex("3a3340")
local STUD_DARK = hex("8a2d73")
local STUD_LIGHT = hex("ffd6f2")
M.LEVELS = 30
M.STUD_OFF = STUD_OFF

-- A round pill from its left end (game coordinates), h tall: under 48 px the
-- 48 px 9-slice pill made bigger and scaled down, so its ends stay round
local function pill(parent, x, y, w, h, color)
	local k = math.min(1, h / 48)
	local n = ui.sagoma("pillola_forma", x, y, math.max(w, h) / k, h / k, color, parent)
	gui.set_pivot(n, gui.PIVOT_W)
	gui.set_scale(n, vmath.vector3(k, k, 1))
	return n, k
end

local function width(n, k, w, h)
	gui.set_size(n, vec(math.max(w, h) / k, h / k))
end

-- The bar w wide from (x, y) (Figma), h tall, filled to level in the color of its
-- grade, the next level to buy in ember; lit: how many signature studs are lit.
-- Returns { node, fill, next, studs, gems, lit_parts, tip, set }: gems are the
-- studs' faces, lit_parts the discs of a lit one,
-- tip an empty node at the end of the fill (for sparks), STUD_OFF its color unlit
function M.draw(g, x, y, w, h, level, lit)
	local root = gui.new_box_node(vec(x - g.ox, g.oy - (y + h / 2)), vec(0, 0))
	gui.set_visible(root, false)
	gui.set_parent(root, g.node)
	local bar = { node = root, level = level }
	local border = h >= 24 and 4 or 3
	local ih = h - 2 * border
	local inset = h >= 24 and 3 or 2
	local fh = ih - 2 * inset
	local x0, iw = border + inset, w - 2 * (border + inset)
	pill(root, 0, 0, w, h, KC.INK)
	pill(root, border, 0, w - 2 * border, ih, TRACK)
	-- the next level, under the fill
	bar.next = pill(root, x0, 0, iw / M.LEVELS, fh, kit.with_alpha(KC.HOT_BOTTOM, 0.55))
	local fill, k = pill(root, x0, 0, 0, fh, ui.C.GRADI[equip.tier(math.max(1, level))])
	bar.fill = fill
	-- its light on top, its shadow below
	local sh = math.max(3, math.floor(fh * 0.28))
	local shine, ks = pill(root, x0 + fh * 0.25, fh / 2 - sh / 2 - math.max(1, fh * 0.1), 0, sh, vmath.vector4(1, 1, 1, 0.28))
	bar.tip = gui.new_box_node(vec(x0, 0), vec(0, 0))
	gui.set_visible(bar.tip, false)
	gui.set_parent(bar.tip, root)
	-- the thin marks of the levels (not where the studs are)
	local mw = h >= 24 and 3 or 2
	for i = 1, M.LEVELS - 1 do
		if i % 10 ~= 0 then
			local m = ui.sagoma("forma", x0 + iw * i / M.LEVELS, 0, mw, fh - 2, kit.with_alpha(KC.INK, 0.5), root)
			gui.set_slice9(m, vmath.vector4(1, 1, 1, 1))
		end
	end
	-- the signature's studs at 10, 20 and 30
	local d = h + 2
	bar.studs, bar.gems, bar.lit_parts = {}, {}, {}
	for s = 1, 3 do
		local sx = x0 + iw * s / 3 - (s == 3 and d / 2 - border or 0)
		local stud = gui.new_box_node(vec(sx, 0), vec(0, 0))
		gui.set_visible(stud, false)
		gui.set_parent(stud, root)
		ui.disc(0, 0, d, KC.INK, stud)
		local on = s <= (lit or 0)
		local face = ui.disc(0, 0, d - 2 * border, on and STUD_DARK or STUD_OFF, stud)
		if on then
			local f = d - 2 * border
			bar.lit_parts[s] = { face, ui.disc(-f * 0.07, f * 0.07, f * 0.78, KC.OBSIDIAN, stud),
				ui.disc(-f * 0.2, f * 0.2, f * 0.26, STUD_LIGHT, stud) }
		end
		bar.studs[s], bar.gems[s] = stud, face
	end

	-- the fill to level (color: its grade's by default); time > 0: it flows there
	function bar.set(lv, color, time, delay)
		bar.level = lv
		local fw = lv <= 0 and 0 or iw * lv / M.LEVELS
		gui.set_enabled(fill, lv > 0)
		gui.set_enabled(shine, fw > fh)
		gui.set_color(fill, color or ui.C.GRADI[equip.tier(math.max(1, lv))])
		local tw, sw = math.max(fw, fh) / k, math.max(fw - fh * 0.5, sh) / ks
		local tip = vec(x0 + fw, 0)
		if time and time > 0 then
			gui.animate(fill, "size.x", tw, gui.EASING_OUTCUBIC, time, delay or 0)
			gui.animate(shine, "size.x", sw, gui.EASING_OUTCUBIC, time, delay or 0)
			gui.animate(bar.tip, "position", tip, gui.EASING_OUTCUBIC, time, delay or 0)
		else
			width(fill, k, fw, fh)
			gui.set_size(shine, vec(sw, sh / ks))
			gui.set_position(bar.tip, tip)
		end
		gui.set_enabled(bar.next, lv < M.LEVELS)
		gui.set_position(bar.next, vec(x0 + math.max(0, fw - 3), 0))
	end

	-- how much of the next level is filled (0..1): the step's scene fills it at each blow
	function bar.next_fill(p)
		width(bar.next, k, iw / M.LEVELS * p + 3, fh)
	end

	bar.set(level)
	return bar
end

return M
