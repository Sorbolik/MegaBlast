-- The full-screen backgrounds of the menus: each screen its own theme
-- (Sergio, 5 Nov: «mi piacciono tutte», proposals in docs/sfondi_menu.md),
-- made of flat shapes (no painted images: the UI is code, 23 Oct) on any
-- proportion (ui/screen.lua). A theme draws on the plain background of
-- ui.background, colors it and adds its shapes once, when the screen opens. Each
-- screen takes the color of its notch in the home (UI-002): the campaign the
-- wood, the armory the embers, the training steel, the events red.
--
-- Rules (docs/sfondi_menu.md): dark under the text, ui.C.TEXT at least 7:1
-- and ui.C.OFF at least 4.5:1 on the lightest pixel of every theme; at most
-- 200 nodes; first the untextured boxes, then the shapes of the ui atlas (one
-- draw call each, plus one for the additive halos); nothing random, nothing
-- moving. Buttons and panels stay the same on every theme.
--
--   local backdrop = require "ui.backdrop"
--   local n = backdrop.new("fucina")   -- the root node: gui.delete_node(n) removes it all
--   backdrop.new("schieramento", nil, { col1, col2 })  -- the lineup: the teams' colors, left to right
--
-- Themes: legno (campaign and the end of a level), fucina (armory), campo
-- (training), arena (where do you play?), stendardi (events), banco
-- (settings), camerino (profile), raggi (podium), schieramento (lineup).
-- Anything else is the plain dark of ui.background.

local ui = require "ui.ui"
local screen = require "ui.screen"

local M = {}

local function c4(r, g, b, a) return vmath.vector4(r, g, b, a or 1) end
local function hex(h, a)
	return c4(tonumber(h:sub(1, 2), 16) / 255, tonumber(h:sub(3, 4), 16) / 255, tonumber(h:sub(5, 6), 16) / 255, a)
end

local function box(x, y, w, h, color, parent)
	local n = gui.new_box_node(vmath.vector3(x, y, 0), vmath.vector3(w, h, 0))
	gui.set_color(n, color)
	gui.set_adjust_mode(n, gui.ADJUST_FIT)
	gui.set_parent(n, parent)
	return n
end

local function turned(n, degrees)
	gui.set_rotation(n, vmath.vector3(0, 0, degrees))
	return n
end

-- How far the shapes go from the middle: 2 times the 1280 x 720 frame each
-- way (20:9, 4:3 and the square foldables fit with room to spare)
local HALF_W, HALF_H = 1280, 720

-- the real bottom of the screen, from the middle of the frame (the backdrop's
-- origin): what glows from the floor sits there on every proportion
local function floor_y() return screen.y0 - 360 end

-- lines every step on both axes, every major-th one thicker in its color
local function grid(n, step, major, line, major_line, thin, thick)
	for k = -math.floor(HALF_W / step), math.floor(HALF_W / step) do
		local big = k % major == 0
		box(k * step, 0, big and thick or thin, HALF_H * 2, big and major_line or line, n)
	end
	for k = -math.floor(HALF_H / step), math.floor(HALF_H / step) do
		local big = k % major == 0
		box(0, k * step, HALF_W * 2, big and thick or thin, big and major_line or line, n)
	end
end

local THEMES = {}

-- The wall of planks of the board of the Forge (Sergio, 5 Nov: the board
-- fills the whole screen): long planks 58 tall, every other one a touch
-- darker, the seam between them, two lines of grain and a joint each, from
-- PATTERN in turn. About 135 boxes
local WOOD, WOOD_ALT, PLANK, GRAIN = hex("4A2B17"), hex("442814"), hex("3B2112"), hex("54331C")
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

-- ARMERIA: the wall of the Forge where the Smith hangs the pieces, riveted
-- iron plates 320 x 240 and the embers glowing from the floor. 16 seams, 126
-- rivets, 1 halo
function THEMES.fucina(n)
	gui.set_color(n, hex("1A1311"))
	local seam, rivet, shine = hex("100B0A"), hex("2A201C"), hex("3A2C25")
	for i = -3, 3 do box(0, i * 240 + 120, HALF_W * 2, 4, seam, n) end
	for j = -4, 4 do box(j * 320, 0, 4, HALF_H * 2, seam, n) end
	for i = -3, 3 do
		for j = -4, 4 do
			ui.disc(j * 320, i * 240 + 120, 18, rivet, n)
			ui.disc(j * 320 - 2, i * 240 + 122, 8, shine, n)
		end
	end
	ui.alone(0, floor_y() - 120, 1600, vmath.vector4(1, 0.42, 0.16, 0.11), n)
end

-- ALLENAMENTO: the proving ground, a steel slate with the chalk grid and a
-- target right of the middle. About 100 lines, 5 shapes
function THEMES.campo(n)
	gui.set_color(n, hex("141B24"))
	grid(n, 40, 4, hex("1A2330"), hex("1F2A39"), 2, 3)
	local target = hex("223042")
	for _, d in ipairs({ 660, 480, 300, 120 }) do ui.ring_node(400, -60, d, 6, target, n) end
	ui.disc(400, -60, 36, target, n)
end

-- GIOCA ONLINE (where do you play?): the floor of the arena seen from above,
-- rings rising from the bottom, and the lights of the four teams waiting. 12
-- discs, 4 halos
function THEMES.arena(n)
	gui.set_color(n, hex("110F18"))
	local cy = floor_y() - 260
	local ring, ring_alt = hex("1C1826"), hex("17141F")
	local i = 0
	for r = 1300, 200, -110 do
		ui.disc(0, cy, r * 2, i % 2 == 0 and ring or ring_alt, n)
		i = i + 1
	end
	for k, col in ipairs(ui.C.SQUADRA) do
		ui.alone(-760 + (k - 1) * 506, floor_y() - 60, 700, vmath.vector4(col.x, col.y, col.z, 0.10), n)
	end
end

-- EVENTI: the banners of the events hanging in the hall, wine red drapes 150
-- wide with their folds and a gold thread. About 50 boxes
function THEMES.stendardi(n)
	gui.set_color(n, hex("1E0C10"))
	local drape, fold, thread = hex("250F14"), hex("16080B"), hex("3A2414")
	for k = -9, 9 do
		local x = k * 150
		if k % 2 == 0 then
			box(x, 0, 150, HALF_H * 2, drape, n)
			box(x, 0, 2, HALF_H * 2, thread, n)
		end
		box(x + 75, 0, 4, HALF_H * 2, fold, n)
	end
end

-- IMPOSTAZIONI: the workbench of the controls, a blueprint grid: neutral, as
-- a technical screen should be, but not flat black. About 125 lines
function THEMES.banco(n)
	gui.set_color(n, hex("13151A"))
	grid(n, 32, 4, hex("181B21"), hex("1E222A"), 1, 2)
end

-- PROFILO: the devil's dressing room, velvet wallpaper with stripes (the glow
-- of its Core behind it is already the profile's). About 55 boxes
function THEMES.camerino(n)
	gui.set_color(n, hex("17101C"))
	local stripe = hex("1C1423")
	for k = -26, 26, 2 do box(k * 48, 0, 24, HALF_H * 2, stripe, n) end
end

-- PODIO: golden rays from the podium. 18 turned boxes, 1 halo
function THEMES.raggi(n)
	gui.set_color(n, hex("15100A"))
	local ray = hex("21180C")
	for k = 0, 17 do turned(box(0, -160, 3400, 70, ray, n), k * 10) end
	ui.alone(0, -100, 900, vmath.vector4(0.96, 0.77, 0.09, 0.14), n)
end

-- SCHIERAMENTO: the teams facing each other, the screen split on a slant (8
-- degrees) in the dark of each one's color, left to right (colors: the
-- teams'; in free-for-all one band per team), a line between them where VS is
local SLANT, LINE = -8, hex("2A2430")

local function dark(col)
	local b = ui.C.BOTTOM
	return c4(b.x + (col.x - b.x) * 0.06, b.y + (col.y - b.y) * 0.06, b.z + (col.z - b.z) * 0.06)
end

function THEMES.schieramento(n, colors)
	colors = colors or {}
	local k = #colors
	if k < 2 then return end
	local w = 1280 / k
	for i, col in ipairs(colors) do
		local x0, x1 = -640 + (i - 1) * w, -640 + i * w
		-- the outer bands go on past the edges of the frame
		if i == 1 then x0 = x0 - HALF_W end
		if i == k then x1 = x1 + HALF_W end
		turned(box((x0 + x1) / 2, 0, x1 - x0, HALF_H * 3, dark(col), n), SLANT)
	end
	for i = 1, k - 1 do turned(box(-640 + i * w, 0, 6, HALF_H * 3, LINE, n), SLANT) end
end

function M.new(theme, parent, extra)
	local n = ui.background(parent)
	if THEMES[theme] then THEMES[theme](n, extra) end
	return n
end

return M
