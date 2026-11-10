-- The receipt (Sergio, 10 Nov: "deve essere molto chiaro"): what a match or a
-- level gave, line by line. The lines come in one at a time with a tick, then
-- the total counts up, the level bar fills and, with a new level, the points
-- to put in the Sigilli with the button that takes you there. Used by the
-- podium (menu/podium.lua) and the end of a level (menu/level_end.lua).
--
-- Two columns (page "Scaglie e Ossidiana", choice 10A): the experience and
-- the Scaglie, one line per key; a line only one of them gives has the
-- other empty. The Ossidiana comes last, in its color. When the total has
-- counted, the coins fly from it into the wallet pill at the top right
-- (ui/coins.lua), which shows the balance before the match until they land.
--
--   local r = receipt.new(gain, prof, x, y, buttons, parent)
--     gain: profile.match_end or profile.mission (lines, xp, level_before, livello, braci...)
--       gain.coins = { rows, obsidian } (menu/wallet.lua), already in the profile
--     buttons: the screen's list, METTI I PUNTI goes there with the action "sigilli"
--   receipt.update(r, dt, tick, coin)  -- tick(i): the sound of a line, i from 1;
--                                      -- coin(kind, i): a coin landing in the pill
--   receipt.skip(r)               -- everything at once (a tap during the count or the flight)

local ui = require "ui.ui"
local coins = require "ui.coins"
local profile = require "menu.profile"
local T = require("lang.text").receipt
local TM = require("lang.text").milestones

local M = {}

M.W = 400
M.LINE_H = 40
M.LINE_MIN = 28   -- with many lines they get closer, down to this
M.BOTTOM = 100    -- the panel stays above this (the screens' buttons)
M.OBS_H = 34      -- the Ossidiana's total, under the other one
-- the columns' right edges, from the panel's right inner edge: experience, coins
local XP_COL, COIN_COL, COIN_ICON = -128, -30, -10
-- when the first line comes, the rhythm of the others, how long the total counts
M.FIRST, M.RHYTHM, M.COUNT = 0.9, 0.22, 0.6

local C = ui.C

local function vec(x, y) return vmath.vector3(x, y, 0) end
local function alpha(n, a)
	local c = gui.get_color(n)
	c.w = a
	gui.set_color(n, c)
end

local ROMAN = { "I", "II", "III", "IV" }

local function label(l)
	if l.key == "points" then return T.points_line:format(l.n) end
	if l.key == "award" then return T.award:format(l.name) end
	if l.key == "stars" then return T.stars:format(l.n) end
	if l.key == "badge" then return T.badge:format(TM.names[l.id] or l.id, ROMAN[l.grade]) end
	return T.lines[l.key]
end

-- The lines of the experience with the coins next to them: a coin row goes
-- on the first line with its key that has none yet, or becomes a line of its
-- own; the Ossidiana's rows come after
function M.merge(lines, c)
	local out = {}
	for i, l in ipairs(lines) do out[i] = { key = l.key, n = l.n, name = l.name, xp = l.xp } end
	for _, row in ipairs(c and c.rows or {}) do
		local into
		for _, l in ipairs(out) do
			if l.key == row.key and not l.scaglie and not into then into = l end
		end
		if not into then
			into = { key = row.key, n = row.n }
			out[#out + 1] = into
		end
		into.scaglie = row.scaglie
	end
	for _, row in ipairs(c and c.obsidian or {}) do
		out[#out + 1] = { key = row.key, id = row.id, grade = row.grade, ossidiana = row.ossidiana }
	end
	return out
end

-- a coin's amount in its column, with the coin after it
local function coin_cell(kind, n, x, y, parent)
	local t = ui.text(T.plus:format(coins.format(n)), x + COIN_COL, y, 0.85, coins.COLOR[kind], parent)
	gui.set_pivot(t, gui.PIVOT_E)
	local icon = coins.icon(kind, x + COIN_ICON, y, 20, parent)
	return t, icon
end

function M.new(gain, prof, x, y, buttons, parent)
	local lines = M.merge(gain.lines or {}, gain.coins)
	local level_up = gain.livello > gain.level_before
	local braci = (gain.braci or 0) - (gain.braci_before or 0)
	local sc, ob = 0, 0
	for _, l in ipairs(lines) do sc, ob = sc + (l.scaglie or 0), ob + (l.ossidiana or 0) end
	local fixed = 196 + (ob > 0 and M.OBS_H or 0) + (level_up and 132 or braci > 0 and 50 or 0)
	local line_h = math.max(M.LINE_MIN, math.min(M.LINE_H, (y - M.BOTTOM - fixed) / math.max(1, #lines)))
	local h = fixed + #lines * line_h
	local r = { t = 0, shown = 0, rows = {}, gain = gain, prof = prof, sc = sc, ob = ob }
	local top = h / 2
	r.panel = ui.panel(x, y - h / 2, M.W, h, parent)
	local p = r.panel
	local left, right = -M.W / 2 + 26, M.W / 2 - 26
	local t = ui.title(T.title, left, top - 34, 0.6, C.TEXT, p)
	gui.set_pivot(t, gui.PIVOT_W)
	-- the columns' heads: XP and the Scaglia
	t = ui.text(T.xp, right + XP_COL, top - 34, 0.7, C.OFF, p)
	gui.set_pivot(t, gui.PIVOT_E)
	coins.icon("scaglia", right + COIN_ICON, top - 34, 24, p)
	local ly = top - 82
	for i, l in ipairs(lines) do
		local row = { ui.text(label(l), left, ly, 0.8, C.TEXT, p) }
		gui.set_pivot(row[1], gui.PIVOT_W)
		if l.xp then
			row[2] = ui.text(T.plus:format(l.xp), right + XP_COL, ly, 0.85, C.GOLD, p)
			gui.set_pivot(row[2], gui.PIVOT_E)
		end
		if l.scaglie or l.ossidiana then
			local a, b = coin_cell(l.ossidiana and "ossidiana" or "scaglia", l.scaglie or l.ossidiana, right, ly, p)
			row[#row + 1], row.icon = a, b
			gui.set_enabled(b, false)
		end
		for _, n in ipairs(row) do alpha(n, 0) end
		r.rows[i] = row
		ly = ly - line_h
	end
	-- the line and the total
	local line = gui.new_box_node(vec(0, ly + 16), vec(M.W - 52, 2))
	gui.set_color(line, C.LINE)
	gui.set_parent(line, p)
	ly = ly - 18
	local tl = ui.title(T.total, left, ly, 0.55, C.TEXT, p)
	gui.set_pivot(tl, gui.PIVOT_W)
	r.total = ui.title(T.plus:format(0), right + XP_COL, ly, 0.7, C.GOLD, p)
	gui.set_pivot(r.total, gui.PIVOT_E)
	-- the coins' totals: where they fly from (in the parent's space)
	local base = vmath.vector3(x, y - h / 2, 0)
	r.coin_total = { scaglia = ui.title(T.plus:format(0), right + COIN_COL, ly, 0.7, coins.COLOR.scaglia, p) }
	gui.set_pivot(r.coin_total.scaglia, gui.PIVOT_E)
	coins.icon("scaglia", right + COIN_ICON, ly, 24, p)
	r.from = { scaglia = base + vec(right + COIN_ICON, ly) }
	if ob > 0 then
		ly = ly - M.OBS_H
		r.coin_total.ossidiana = ui.title(T.plus:format(0), right + COIN_COL, ly, 0.7, coins.COLOR.ossidiana, p)
		gui.set_pivot(r.coin_total.ossidiana, gui.PIVOT_E)
		coins.icon("ossidiana", right + COIN_ICON, ly, 24, p)
		r.from.ossidiana = base + vec(right + COIN_ICON, ly)
	end
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
		ui.text((n == 1 and T.seal_point or T.seal_points):format(n), 0, 0, 0.8, C.GOLD, holder(ly))
		ly = ly - 50
		ui.button(buttons, 0, 0, M.W - 52, 56, T.place_points, "sigilli", { main = true, colore = C.GOLD }, holder(ly))
	elseif braci > 0 then
		ly = ly - 36
		ui.text((braci == 1 and T.brace or T.braci):format(braci), 0, 0, 0.8, C.GOLD, holder(ly))
	end
	for _, n in ipairs(r.after) do gui.set_scale(n, vec(0.01, 0.01)) end
	r.h = h
	-- the wallet pill at the top right, with the balance before these coins
	r.wallet = coins.wallet(prof.scaglie - sc, prof.ossidiana - ob, parent, 1280 - ui.EDGE - coins.W / 2, 720 - 30 - coins.H / 2)
	return r
end

-- the coins leave the totals for the pill: some Scaglie, then the Ossidiana
-- (fewer, bigger and slower)
local function fly(r, coin)
	if r.flown then return end
	r.flown = true
	if r.sc > 0 then
		coins.fly(r.wallet, "scaglia", r.from.scaglia, math.min(12, math.max(3, math.ceil(r.sc / 5))), r.sc,
			coin and function(i) coin("scaglia", i) end)
	end
	if r.ob > 0 then
		coins.fly(r.wallet, "ossidiana", r.from.ossidiana, math.min(5, math.max(1, math.floor(r.ob / 5))), r.ob,
			coin and function(i) coin("ossidiana", i) end)
	end
end

local function show_after(r)
	if r.after_shown then return end
	r.after_shown = true
	alpha(r.level, 1)
	for i, n in ipairs(r.after) do
		gui.animate(n, "scale", vec(1, 1), gui.EASING_OUTBACK, 0.3, 0.1 * (i - 1))
	end
end

function M.update(r, dt, tick, coin)
	r.t = r.t + dt
	-- the lines, one at a time
	while r.shown < #r.rows and r.t >= M.FIRST + r.shown * M.RHYTHM do
		r.shown = r.shown + 1
		local row = r.rows[r.shown]
		for _, n in ipairs(row) do alpha(n, 1) end
		if row.icon then gui.set_enabled(row.icon, true) end
		if tick then tick(r.shown) end
	end
	-- then the total counts and the bar fills
	local t0 = M.FIRST + #r.rows * M.RHYTHM
	if r.t >= t0 then
		local k = math.min(1, (r.t - t0) / M.COUNT)
		gui.set_text(r.total, T.plus:format(math.floor(r.gain.xp * k + 0.5)))
		gui.set_text(r.coin_total.scaglia, T.plus:format(coins.format(r.sc * k + 0.5)))
		if r.coin_total.ossidiana then gui.set_text(r.coin_total.ossidiana, T.plus:format(coins.format(r.ob * k + 0.5))) end
		ui.bar_value(r.bar, r.bar_from + (r.bar_to - r.bar_from) * k)
		if k >= 1 then
			show_after(r)
			fly(r, coin)
		end
	end
end

function M.skip(r)
	local done = M.FIRST + #r.rows * M.RHYTHM + M.COUNT
	if r.t < done then r.t = done else coins.finish(r.wallet) end
end

function M.delete(r)
	coins.delete(r.wallet)
end

return M
