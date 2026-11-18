-- The level of a piece as one bar of molten metal (Sergio, 18 Nov, variant 3 of the
-- page "Proposte zaino e scatto": «vai di barra di metallo fuso»): a round ink tube
-- that fills with the grade's color like poured metal, the thirty levels only hinted
-- by thin marks, and at 10, 20 and 30, once the step is done, the gem-shaped hollow
-- of the signature (the gem in it when the Ossidiana lit it). Everything is round,
-- as the rest of the game. Used by the
-- piece's card (menu/bench.lua), the ZAINO's band and the step's scene (ui/step_scene.lua).
--
--   local ingots = require "ui.ingots"
--   local bar = ingots.draw(g, x, y, w, h, level, lit, born)
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
local IRON, IRON_L, IRON_D = hex("3a3340"), hex("5a5263"), hex("1e1a22")
local HOLLOW = hex("141017")
local STUD_OFF = HOLLOW
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

-- The bar w wide from (x, y) (Figma), h tall, filled to level in the color of its
-- grade, the next level to buy in ember; lit: how many signature slots are lit;
-- born: a slot drawn before its step (the step's scene makes it grow).
-- Returns { node, fill, next, studs, gems, lit_parts, tip, set }: studs are the
-- slots (only those there), gems their hollows' bottoms, lit_parts the gem in a lit one,
-- tip an empty node at the end of the fill (for sparks), STUD_OFF its color unlit
function M.draw(g, x, y, w, h, level, lit, born)
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
	-- the next level: the fill one level longer in ember, under it (only its end shows,
	-- the same rounded end as the metal)
	local lw = iw / M.LEVELS
	bar.next = pill(root, x0, 0, lw, fh, kit.with_alpha(KC.HOT_BOTTOM, 0.55))
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
			-- (a plain box: a 9-slice this thin draws each mark a little differently)
			local mx = math.floor(x0 + iw * i / M.LEVELS + 0.5)
			ui.sagoma(nil, mx, 0, mw, fh - 4, kit.with_alpha(KC.INK, 0.5), root)
		end
	end
	-- the signature's slots at 10, 20 and 30 (Sergio, 18 Nov, B · Incavo a gemma): a
	-- hollow in the shape of the gem, dug as the new coins are (dark band above, light
	-- below); lit, the gem sits in it. A slot is there only from its step on (born:
	-- the one the step's scene makes grow, there but at nothing)
	local d = h + 10
	bar.studs, bar.gems, bar.lit_parts = {}, {}, {}
	for s = 1, 3 do
		if level >= s * 10 or born == s then
			local sx = x0 + iw * s / 3 - (s == 3 and h / 2 - border or 0)
			local stud = gui.new_box_node(vec(sx, 0), vec(0, 0))
			gui.set_visible(stud, false)
			gui.set_parent(stud, root)
			bar.gems[s] = hollow(stud, d)
			if s <= (lit or 0) then
				bar.lit_parts[s] = { kit.piece({ node = stud, ox = 0, oy = 0 }, "gemma", 0, 0, d * 0.55) }
			end
			bar.studs[s] = stud
		end
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
		if time and time > 0 then
			gui.animate(bar.next, "size.x", math.max(fw + lw, fh) / k, gui.EASING_OUTCUBIC, time, delay or 0)
		else
			width(bar.next, k, fw + lw, fh)
		end
	end


	bar.set(level)
	return bar
end

return M
