-- The receipt (Sergio, 10 Nov: "deve essere molto chiaro"): what a match or a
-- level gave, line by line. The lines come in one at a time with a tick, then
-- the total counts up, the level bar fills and, with a new level, the points
-- to put in the Sigilli with the button that takes you there. Used by the
-- podium (menu/podium.lua) and the end of a level (menu/level_end.lua).
--
-- Each line has one value per column; today only experience. The coins
-- (thread "valute") will add their column: cols grows, the lines carry one
-- more value, the panel is already wide enough for two.
--
--   local r = receipt.new(gain, prof, x, y, buttons, parent)
--     gain: profile.match_end or profile.mission (lines, xp, level_before, livello, braci...)
--     buttons: the screen's list, METTI I PUNTI goes there with the action "sigilli"
--   receipt.update(r, dt, tick)   -- tick(i): the sound of a line, i from 1
--   receipt.skip(r)               -- everything at once (a tap during the count)

local ui = require "ui.ui"
local profile = require "menu.profile"
local T = require("lang.text").receipt

local M = {}

M.W = 400
M.LINE_H = 40
-- when the first line comes, the rhythm of the others, how long the total counts
M.FIRST, M.RHYTHM, M.COUNT = 0.9, 0.22, 0.6

local C = ui.C

local function vec(x, y) return vmath.vector3(x, y, 0) end
local function alpha(n, a)
	local c = gui.get_color(n)
	c.w = a
	gui.set_color(n, c)
end

local function label(l)
	if l.key == "points" then return T.points:format(l.n) end
	if l.key == "award" then return T.award:format(l.name) end
	if l.key == "stars" then return T.stars:format(l.n) end
	return T.lines[l.key]
end

function M.new(gain, prof, x, y, buttons, parent)
	local lines = gain.lines or {}
	local level_up = gain.livello > gain.level_before
	local braci = (gain.braci or 0) - (gain.braci_before or 0)
	local h = 196 + #lines * M.LINE_H + (level_up and 132 or braci > 0 and 50 or 0)
	local r = { t = 0, shown = 0, rows = {}, gain = gain, prof = prof }
	local top = h / 2
	r.panel = ui.panel(x, y - h / 2, M.W, h, parent)
	local p = r.panel
	local left, right = -M.W / 2 + 26, M.W / 2 - 26
	local t = ui.title(T.title, left, top - 34, 0.6, C.TEXT, p)
	gui.set_pivot(t, gui.PIVOT_W)
	local ly = top - 82
	for i, l in ipairs(lines) do
		local a = ui.text(label(l), left, ly, 0.8, C.TEXT, p)
		gui.set_pivot(a, gui.PIVOT_W)
		local b = ui.text(T.plus:format(l.xp), right, ly, 0.85, C.GOLD, p)
		gui.set_pivot(b, gui.PIVOT_E)
		alpha(a, 0)
		alpha(b, 0)
		r.rows[i] = { a, b }
		ly = ly - M.LINE_H
	end
	-- the line and the total
	local line = gui.new_box_node(vec(0, ly + 16), vec(M.W - 52, 2))
	gui.set_color(line, C.LINE)
	gui.set_parent(line, p)
	ly = ly - 18
	local tl = ui.title(T.total, left, ly, 0.55, C.TEXT, p)
	gui.set_pivot(tl, gui.PIVOT_W)
	r.total = ui.title(T.plus:format(0), right, ly, 0.7, C.GOLD, p)
	gui.set_pivot(r.total, gui.PIVOT_E)
	-- the level and its bar
	ly = ly - 46
	local lv = level_up and T.level_up:format(gain.livello) or T.level:format(gain.livello)
	r.level = ui.title(lv, left, ly, 0.5, level_up and C.BRACE or C.TEXT, p)
	gui.set_pivot(r.level, gui.PIVOT_W)
	alpha(r.level, 0)
	ly = ly - 26
	r.bar = ui.bar(0, ly, M.W - 52, 10, C.BRACE, p)
	local before = (prof.xp - gain.xp) / profile.xp_level(gain.level_before)
	if level_up or braci > 0 then before = 0 end
	r.bar_from, r.bar_to = math.max(0, before), prof.xp / profile.xp_level(prof.livello)
	ui.bar_value(r.bar, r.bar_from)
	-- what the new level gives
	r.after = {}
	-- each one in an empty node of its own: the pop animates that, not the text's scale
	local function holder(y)
		local n = gui.new_box_node(vec(0, y), vec(0, 0))
		gui.set_visible(n, false)
		gui.set_parent(n, p)
		r.after[#r.after + 1] = n
		return n
	end
	if level_up then
		ly = ly - 36
		local n = math.min(profile.LEVEL_MAX, gain.livello) - gain.level_before
		ui.text((n == 1 and T.point or T.points):format(n), 0, 0, 0.8, C.GOLD, holder(ly))
		ly = ly - 50
		ui.button(buttons, 0, 0, M.W - 52, 56, T.place_points, "sigilli", { main = true, colore = C.GOLD }, holder(ly))
	elseif braci > 0 then
		ly = ly - 36
		ui.text((braci == 1 and T.brace or T.braci):format(braci), 0, 0, 0.8, C.GOLD, holder(ly))
	end
	for _, n in ipairs(r.after) do gui.set_scale(n, vec(0.01, 0.01)) end
	r.h = h
	return r
end

local function show_after(r)
	if r.after_shown then return end
	r.after_shown = true
	alpha(r.level, 1)
	for i, n in ipairs(r.after) do
		gui.animate(n, "scale", vec(1, 1), gui.EASING_OUTBACK, 0.3, 0.1 * (i - 1))
	end
end

function M.update(r, dt, tick)
	r.t = r.t + dt
	-- the lines, one at a time
	while r.shown < #r.rows and r.t >= M.FIRST + r.shown * M.RHYTHM do
		r.shown = r.shown + 1
		for _, n in ipairs(r.rows[r.shown]) do alpha(n, 1) end
		if tick then tick(r.shown) end
	end
	-- then the total counts and the bar fills
	local t0 = M.FIRST + #r.rows * M.RHYTHM
	if r.t >= t0 then
		local k = math.min(1, (r.t - t0) / M.COUNT)
		gui.set_text(r.total, T.plus:format(math.floor(r.gain.xp * k + 0.5)))
		ui.bar_value(r.bar, r.bar_from + (r.bar_to - r.bar_from) * k)
		if k >= 1 then show_after(r) end
	end
end

function M.skip(r)
	r.t = math.max(r.t, M.FIRST + #r.rows * M.RHYTHM + M.COUNT)
end

return M
