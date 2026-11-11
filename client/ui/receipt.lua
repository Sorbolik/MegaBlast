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
-- The experience goes first: after the count, sparks fly from its total into
-- the level bar, which fills a step and swells at each one (the sound rises
-- by a semitone); with a new level the last one bursts in a gold ring.
--
--   local r = receipt.new(gain, prof, top, buttons, parent)
--     top: where GUADAGNI is written (ui/kit.lua coordinates: 1280 x 720, y from the top);
--       the rows go down from there, on the right; parent: a node at the screen's bottom left
--     gain: profile.match_end or profile.mission (lines, xp, level_before, livello, braci...)
--       gain.coins = { rows, obsidian } (menu/wallet.lua), already in the profile
--     buttons: the screen's list, METTI I PUNTI goes there with the action "sigilli"
--   receipt.update(r, dt, tick, coin, xp)  -- tick(i): the sound of a line, i from 1;
--                                          -- coin(kind, i): a coin landing in the pill;
--                                          -- xp(i, n, level_up): a spark of experience landing
--                                          -- in the bar, the last one (i == n) with level_up true
--                                          -- when it brings a new level
--   receipt.skip(r)               -- everything at once (a tap during the count or the flight)

local ui = require "ui.ui"
local kit = require "ui.kit"
local coins = require "ui.coins"
local profile = require "menu.profile"
local T = require("lang.text").receipt
local TM = require("lang.text").milestones

local M = {}

M.LINE_H = 46
M.LINE_MIN = 28   -- with many lines they get closer, down to this
M.BOTTOM = 546    -- everything stays above this (the screens' buttons)
-- when the first line comes, the rhythm of the others, how long the total counts
M.FIRST, M.RHYTHM, M.COUNT = 0.9, 0.22, 0.6
-- the sparks of experience: one every GAP seconds, each FLIGHT long
M.XP_GAP, M.XP_FLIGHT = 0.07, 0.38

local C = ui.C
local KC = kit.C
local BAR = KC.HOT

local function vec(x, y) return vmath.vector3(x, y, 0) end
local function alpha(n, a)
	local c = gui.get_color(n)
	c.w = a
	gui.set_color(n, c)
end
local function xp_text(n) return T.plus:format(n) .. " " .. T.xp end

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

function M.new(gain, prof, top, buttons, parent)
	local lines = M.merge(gain.lines or {}, gain.coins)
	local level_up = gain.livello > gain.level_before
	local braci = (gain.braci or 0) - (gain.braci_before or 0)
	local sc, ob = 0, 0
	for _, l in ipairs(lines) do sc, ob = sc + (l.scaglie or 0), ob + (l.ossidiana or 0) end
	local r = { t = 0, shown = 0, rows = {}, gain = gain, prof = prof, sc = sc, ob = ob }
	-- everything in a node at the parent's origin: kit coordinates inside
	r.panel = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_visible(r.panel, false)
	gui.set_parent(r.panel, parent)
	local p = r.panel
	local g = { node = p, ox = 0, oy = 720 }
	local first = top + 14
	-- the total, the Ossidiana's, the level, what the level gives
	local fixed = 46 + (ob > 0 and 46 or 0) + 78 + ((level_up or braci > 0) and 66 or 0)
	local step = math.max(M.LINE_MIN, math.min(M.LINE_H, (M.BOTTOM - first - fixed) / math.max(1, #lines)))
	local tall = math.min(36, step - 4)
	-- the rows lean like everything else: lower is more to the left
	local function lean(y) return 810 - (y - first) * 4 / 46 end
	-- a coin's amount at the row's end, with the coin before it
	local function coin_cell(kind, n, x, y, size)
		local t = kit.text(g, T.plus:format(coins.format(n)), x + 414, y, size, kind == "scaglia" and KC.SAND or coins.COLOR[kind], "end")
		local icon = coins.icon(kind, x + 342, 720 - y + size * 0.36, 16, p)
		return t, icon
	end
	kit.text(g, T.title, 820, top, 14, KC.HOT_TOP, "start", 1.5)
	local y = first
	for i, l in ipairs(lines) do
		local x = lean(y)
		kit.info(g, x, y, 430, tall, KC.ROSE)
		local base = y + tall / 2 + 5
		local name = kit.text(g, kit.upper(label(l)), x + 24, base, 14, KC.SAND)
		local wide = kit.width(name)
		if wide > 220 then
			local sca = gui.get_scale(name)
			gui.set_scale(name, vec(sca.x * 220 / wide, sca.y * 220 / wide))
		end
		local row = { name }
		if l.xp then row[2] = kit.text(g, xp_text(l.xp), x + 314, base, 15, KC.MINT, "end") end
		if l.scaglie or l.ossidiana then
			local a, b = coin_cell(l.ossidiana and "ossidiana" or "scaglia", l.scaglie or l.ossidiana, x, base, 15)
			row[#row + 1], row.icon = a, b
			gui.set_enabled(b, false)
		end
		for _, n in ipairs(row) do alpha(n, 0) end
		r.rows[i] = row
		y = y + step
	end
	-- the total
	local x = lean(y)
	kit.info(g, x, y, 430, 36, KC.SAND)
	kit.text(g, T.total, x + 24, y + 25, 18, KC.SAND)
	r.total = kit.text(g, xp_text(0), x + 314, y + 25, 16, KC.MINT, "end")
	r.spark_from = vec(x + 270, 720 - (y + 18))
	-- the coins' totals: where they fly from (in the parent's space)
	r.coin_total = { scaglia = coin_cell("scaglia", 0, x, y + 25, 16) }
	r.from = { scaglia = vec(x + 342, 720 - (y + 18)) }
	if ob > 0 then
		y = y + 46
		x = lean(y)
		kit.info(g, x, y, 430, 36, coins.COLOR.ossidiana)
		r.coin_total.ossidiana = coin_cell("ossidiana", 0, x, y + 25, 16)
		r.from.ossidiana = vec(x + 342, 720 - (y + 18))
	end
	-- the level and its bar
	y = y + 56
	kit.info(g, 786, y, 440, 58, KC.HOT)
	local lv = level_up and T.level_up:format(gain.livello) or T.level:format(gain.livello)
	r.level = kit.text(g, lv, 812, y + 28, 22, KC.HOT)
	alpha(r.level, 0)
	r.bar = ui.bar(960, 720 - (y + 42), 300, 8, BAR, p)
	gui.set_color(r.bar.nodo, KC.TRACK)
	r.level_up, r.bar_x, r.bar_y = level_up, 960, 720 - (y + 42)
	kit.text(g, math.floor(prof.xp) .. " / " .. profile.xp_level(prof.livello), 1206, y + 46, 11, KC.MUTE, "end", 1)
	local before = (prof.xp - gain.xp) / profile.xp_level(gain.level_before)
	if level_up or braci > 0 then before = 0 end
	r.bar_from, r.bar_to = math.max(0, before), prof.xp / profile.xp_level(prof.livello)
	ui.bar_value(r.bar, r.bar_from)
	-- what the new level gives: a row in an empty node of its own (the pop animates that)
	r.after = {}
	y = y + 72
	local function holder()
		local n = gui.new_box_node(vec(996, 720 - (y + 26)), vec(0, 0))
		gui.set_visible(n, false)
		gui.set_parent(n, p)
		gui.set_scale(n, vec(0.01, 0.01))
		r.after[#r.after + 1] = n
		return { node = n, ox = 996, oy = y + 26 }
	end
	if level_up then
		local n = math.min(profile.LEVEL_MAX, gain.livello) - gain.level_before
		local h = holder()
		kit.info(h, 776, y, 440, 52, KC.PURPLE)
		kit.text(h, kit.upper((n == 1 and T.seal_point or T.seal_points):format(n)), 800, y + 32, 13, KC.SAND)
		local go = kit.sand(h, 1050, y + 8, 150, 36, KC.HOT, { sk = 9, d = 4 })
		kit.text(go.g, T.place_points, 1130, y + 32, 13, KC.INK, "middle")
		kit.button(buttons, go, "sigilli")
	elseif braci > 0 then
		local h = holder()
		kit.info(h, 776, y, 440, 52, KC.PURPLE)
		kit.text(h, kit.upper((braci == 1 and T.brace or T.braci):format(braci)), 800, y + 32, 13, KC.SAND)
	end
	-- the wallet pill at the top right, with the balance before these coins
	r.wallet = coins.wallet(prof.scaglie - sc, prof.ossidiana - ob, parent, 1110, 720 - 44)
	return r
end

-- a ring that opens from (x, y) in the panel and fades
local function burst(r, x, y, d0, d1, color, secs)
	local n = ui.ring_node(x, y, d0, 3, color, r.panel)
	gui.animate(n, "size.x", d1, gui.EASING_OUTQUAD, secs)
	gui.animate(n, "size.y", d1, gui.EASING_OUTQUAD, secs)
	gui.animate(n, "color.w", 0, gui.EASING_INQUAD, secs, 0, function() gui.delete_node(n) end)
end

-- the bar swells and flashes white at each spark
local function pulse(r, strong)
	local b = r.bar
	gui.cancel_animations(b.nodo, "scale")
	gui.set_scale(b.nodo, vec(1, strong and 2.6 or 1.9))
	gui.animate(b.nodo, "scale", vec(1, 1), gui.EASING_OUTQUAD, strong and 0.4 or 0.18)
	gui.cancel_animations(b.full, "color")
	gui.set_color(b.full, vmath.vector4(1, 0.95, 0.8, 1))
	gui.animate(b.full, "color", BAR, gui.EASING_INQUAD, strong and 0.5 or 0.25)
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

-- the last spark is in: the new level lights up, then the coins fly
local function sparks_done(r, coin)
	if r.sparks_ended then return end
	r.sparks_ended = true
	show_after(r)
	fly(r, coin)
end

local function spark_land(r, f, i, xp, coin, quiet)
	if f.landed[i] then return end
	f.landed[i] = true
	if f.nodes[i] then gui.delete_node(f.nodes[i]); f.nodes[i] = nil end
	local frac = r.bar_from + (r.bar_to - r.bar_from) * i / f.n
	ui.bar_value(r.bar, frac)
	local last = i == f.n
	if quiet then
		if last then sparks_done(r, coin) end
		return
	end
	local hx = r.bar_x - r.bar.w / 2 + r.bar.w * frac
	pulse(r, last and r.level_up)
	burst(r, hx, r.bar_y, 8, last and r.level_up and 150 or 34, last and r.level_up and C.GOLD or C.LIGHT,
		last and r.level_up and 0.55 or 0.25)
	if xp then xp(i, f.n, last and r.level_up) end
	if last then sparks_done(r, coin) end
end

-- the sparks of experience leave the total for the bar, in an arc
local function sparks(r, coin, xp)
	if r.sparks then return end
	local n = math.min(10, math.max(3, math.ceil(r.gain.xp / 10)))
	local f = { n = n, nodes = {}, landed = {} }
	r.sparks = f
	if r.gain.xp <= 0 then
		f.n = 1
		spark_land(r, f, 1, nil, coin, true)
		return
	end
	for i = 1, n do
		local node = ui.disc(r.spark_from.x, r.spark_from.y, 14, C.GOLD, r.panel)
		gui.set_scale(node, vec(0.01, 0.01))
		local frac = r.bar_from + (r.bar_to - r.bar_from) * i / n
		local hx = r.bar_x - r.bar.w / 2 + r.bar.w * frac
		local delay = (i - 1) * M.XP_GAP
		gui.animate(node, "scale", vec(1, 1), gui.EASING_OUTBACK, 0.1, delay)
		gui.animate(node, "position.x", hx, gui.EASING_OUTQUAD, M.XP_FLIGHT, delay + 0.06)
		gui.animate(node, "position.y", r.bar_y, gui.EASING_INQUAD, M.XP_FLIGHT, delay + 0.06, function()
			spark_land(r, f, i, xp, coin)
		end)
		f.nodes[i] = node
	end
end

function M.update(r, dt, tick, coin, xp)
	r.t = r.t + dt
	-- the lines, one at a time
	while r.shown < #r.rows and r.t >= M.FIRST + r.shown * M.RHYTHM do
		r.shown = r.shown + 1
		local row = r.rows[r.shown]
		for _, n in ipairs(row) do alpha(n, 1) end
		if row.icon then gui.set_enabled(row.icon, true) end
		if tick then tick(r.shown) end
	end
	-- then the totals count; when they are done the sparks fly into the bar
	local t0 = M.FIRST + #r.rows * M.RHYTHM
	if r.t >= t0 then
		local k = math.min(1, (r.t - t0) / M.COUNT)
		gui.set_text(r.total, xp_text(math.floor(r.gain.xp * k + 0.5)))
		gui.set_text(r.coin_total.scaglia, T.plus:format(coins.format(r.sc * k + 0.5)))
		if r.coin_total.ossidiana then gui.set_text(r.coin_total.ossidiana, T.plus:format(coins.format(r.ob * k + 0.5))) end
		if k >= 1 then
			r.coin_cb = coin
			sparks(r, coin, xp)
		end
	end
end

-- a tap: the count ends; another one: the sparks and the coins land at once
function M.skip(r)
	local done = M.FIRST + #r.rows * M.RHYTHM + M.COUNT
	if r.t < done then
		r.t = done
		return
	end
	local f = r.sparks
	if f then
		for i = 1, f.n do spark_land(r, f, i, nil, r.coin_cb, true) end
	end
	coins.finish(r.wallet)
end

function M.delete(r)
	coins.delete(r.wallet)
end

return M
