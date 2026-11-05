-- The full-screen backgrounds of the menus: each screen its own theme, made
-- of flat shapes (no painted images: the UI is code, 23 Oct) on any
-- proportion (ui/screen.lua). A theme draws on the plain background of
-- ui.sfondo, colors it and adds its shapes once; they are all untextured
-- boxes, so the whole background is one draw call. The text on it must keep
-- its contrast: ui.C.TEXT at least 7:1 on every color of a theme.
--
--   local backdrop = require "ui.backdrop"
--   local n = backdrop.new("legno")   -- the root node: gui.delete_node(n) removes it all
--
-- Themes: "legno" the board of the Forge (menu/campaign.lua). Anything else is
-- the plain dark of ui.sfondo.

local ui = require "ui.ui"

local M = {}

local function c4(r, g, b, a) return vmath.vector4(r, g, b, a or 1) end

local function box(x, y, w, h, color, parent)
	local n = gui.new_box_node(vmath.vector3(x, y, 0), vmath.vector3(w, h, 0))
	gui.set_color(n, color)
	gui.set_adjust_mode(n, gui.ADJUST_FIT)
	gui.set_parent(n, parent)
	return n
end

-- How far the shapes go from the middle: 2 times the 1280 x 720 frame each
-- way (20:9, 4:3 and the square foldables fit with room to spare)
local HALF_W, HALF_H = 1280, 720

local THEMES = {}

-- The wall of planks of the board of the Forge (Sergio, 5 Nov: the board
-- fills the whole screen): long planks 58 tall, every other one a touch
-- darker, the seam between them, two lines of grain and a joint each, from
-- PATTERN in turn (no random: the same wall every time). Text: C.TEXT 9.3:1
-- on the lightest grain. About 135 boxes
local WOOD, WOOD_ALT, PLANK, GRAIN = c4(0.29, 0.17, 0.09), c4(0.265, 0.155, 0.08), c4(0.23, 0.13, 0.07), c4(0.33, 0.20, 0.11)
local PLANK_H = 58
-- { grain y, grain x, grain length, joint x }
local PATTERN = { { 14, -420, 700, 610 }, { -12, 260, 900, -150 }, { 6, -760, 520, 980 },
	{ -16, 120, 640, -820 }, { 10, -180, 980, 330 } }

function THEMES.legno(n)
	gui.set_color(n, WOOD)
	local rows = math.ceil(HALF_H / PLANK_H)
	for i = -rows, rows do
		local y = i * PLANK_H
		local mid = y + PLANK_H / 2
		if i % 2 ~= 0 then box(0, mid, HALF_W * 2, PLANK_H, WOOD_ALT, n) end
		box(0, y, HALF_W * 2, 3, PLANK, n)
		local p = PATTERN[i % #PATTERN + 1]
		box(p[2], mid + p[1], p[3], 2, GRAIN, n)
		box(p[2] + 900, mid - p[1] / 2, p[3] / 2, 2, GRAIN, n)
		box(p[4], mid, 3, PLANK_H, PLANK, n)
	end
end

function M.new(theme, parent)
	local n = ui.sfondo(parent)
	if THEMES[theme] then THEMES[theme](n) end
	return n
end

return M
