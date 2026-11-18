-- The pieces shared by the ZAINO and the ARMERIA (Figma "RIORGANIZZAZIONE MENU ·
-- 14 nov", Consigliata/2..5): the square slot with a piece's icon (WB-043/044),
-- the pieces worn with their labels on the devil, the column of the stats, the
-- loadouts 1 2 3, the filters. Everything placed with the Figma's coordinates
-- (ui/kit.lua: x from the left, y from the top).
--
--   local gear_ui = require "menu.gear_ui"
--   gear_ui.slot(g, x, y, s, opt)        -- opt: set, slot, level, worn, sel, empty_slot
--   gear_ui.worn(s, g, cx, feet, h, x, ys, size, sel)   -- the labels of the pieces worn
--   gear_ui.stats(s, g, x, y, w, now, after, o)         -- the column of the stats, all in one screen
--   gear_ui.stats_short(s, g, x, y, w, a, a2)           -- only the rows that change, and VEDI TUTTE
--   gear_ui.sheet(s, g, a, a2, back)                    -- all the stats, big, in the middle
--   gear_ui.loadouts(s, g, x, y, active, prefix, label) -- the three loadouts
--   gear_ui.chips(s, g, x, y, list, active)             -- a row of filters
--   gear_ui.effects(set, slot, level)                   -- "+4% IN ARIA  −2% VITA"
--   gear_ui.devil(s, g, cx, feet, h)                    -- the apprentice, s.figure

local ui = require "ui.ui"
local kit = require "ui.kit"
local screen = require "ui.screen"
local P = require "ui.pieces"
local game = require "sim.game"
local equip = require "sim.gear"
local loadout = require "sim.loadout"
local scoria = require "battle.scoria"
local outline = require "menu.outline"
local clock = require "ui.clock"
local wallet = require "sim.wallet"
local TA = require("lang.text").armory
local T = require("lang.text").gear_ui

local M = {}

local KC = kit.C
M.ROMAN = { "I", "II", "III", "IV" }

-- the name of a slot in the pictures' names (WB-043)
M.ART = { mask = "elmo", chest = "corazza", cloak = "mantello", legs = "stivali" }
function M.slot_of(id)
	for _, sl in ipairs(equip.SLOTS) do if sl.id == id then return sl end end
	return equip.SLOTS[1]
end

-- "ELMO · CORVO"
function M.name(set, slot)
	return T.piece:format(M.slot_of(slot).name, equip.BY_ID[set].name)
end

-- the picture of a piece: the forged one from gold (level 20) on
function M.icon(set, slot, level)
	return "ic_" .. set .. "_" .. M.ART[slot] .. ((level or 1) >= equip.GOLD and "_forgiato" or "_base")
end

-- "+10 ATTACCO": what a row really does to the stat (the stats where less is
-- better go down with a plus; life, Attack and Defense in points)
function M.effect(e)
	local info = equip.STATS[e.stat]
	local name = kit.upper(TA.stats[e.stat] or e.stat)
	if info.points then return string.format("%+d %s", math.floor(e.good * 100 + 0.5), name):gsub("^%-", "−") end
	local v = (info.less and -e.good or e.good) * 100
	local t = string.format("%+.1f%%", v):gsub("%.0%%", "%%"):gsub("%.", ",")
	return (t:gsub("^%-", "−")) .. " " .. name
end

-- a row split in two: its value ("−19,1%", "+15") and its stat's name; with
-- e2, the change from e to e2 instead of the value ("−0,4%")
function M.effect_parts(e, e2)
	local info = equip.STATS[e.stat]
	local name = kit.upper(TA.stats[e.stat] or e.stat)
	local function shown(x)
		if info.points then return math.floor(x.good * 100 + 0.5) end
		return (info.less and -x.good or x.good) * 100
	end
	local v = e2 and shown(e2) - shown(e) or shown(e)
	local t = info.points and string.format("%+d", v) or string.format("%+.1f%%", v):gsub("%.0%%", "%%"):gsub("%.", ",")
	return (t:gsub("^%-", "−")), name
end

-- the colour of each kind of row (Sergio, 18 Nov): the main bonus, the second
-- ones, the minus, the signature (its own colour, the Ossidiana's)
M.ROW_COLOR = { main = kit.C.HOT, second = kit.C.STEEL, minus = kit.C.RED, sign = kit.C.PURPLE }

-- A piece's rows on one or two lines from (x, y), at most room wide: each its
-- number a bit bigger than its name, in the colour of its kind; the signature
-- by its name (dim while it is off). Returns the lines used and the nodes
function M.effect_row(g, x, y, set, slot, level, lit, room, line_h)
	local items = {}
	for _, e in ipairs(equip.piece(set, slot, level, lit)) do
		local col = M.ROW_COLOR[e.row] or kit.C.SAND
		if e.row == "sign" then
			if (lit or 0) == 0 then col = kit.with_alpha(col, 0.55) end
			items[#items + 1] = { nil, kit.upper(equip.SIGNS[e.stat].name), col }
		else
			local v, name = M.effect_parts(e)
			items[#items + 1] = { v, name, col }
		end
	end
	local cx, line, made = x, 1, {}
	for _, it in ipairs(items) do
		local num = it[1] and kit.text(g, it[1], 0, 0, 20, it[3], "start")
		local name = kit.text(g, it[2], 0, 0, kit.MIN_TEXT, it[3], "start", 0.5)
		local nw = num and kit.width(num) + 5 or 0
		local w = nw + kit.width(name)
		if cx > x and cx + w > x + room and line < 2 then cx, line = x, line + 1 end
		local by = y + (line - 1) * (line_h or 22)
		for _, n in ipairs({ num, name }) do
			if n then
				made[#made + 1] = n
				local pos = gui.get_position(n)
				pos.x = pos.x + (n == name and cx + nw or cx)
				pos.y = pos.y - by
				gui.set_position(n, pos)
			end
		end
		cx = cx + w + 18
	end
	return line, made
end

-- the rows of a piece but its signature, in one line
function M.effects(set, slot, level)
	local t = {}
	for _, e in ipairs(equip.piece(set, slot, level)) do
		if e.row ~= "sign" then t[#t + 1] = M.effect(e) end
	end
	return table.concat(t, "  ")
end

-- the colour of each family's pieces (their main colour, measured on the icons
-- and made a bit lighter): the type symbol of a piece is filled with it (Sergio, 18 Nov)
local function hexc(h)
	return vmath.vector4(tonumber(h:sub(1, 2), 16) / 255, tonumber(h:sub(3, 4), 16) / 255, tonumber(h:sub(5, 6), 16) / 255, 1)
end
-- the type symbol's colour: one per slot, the same whatever the family, like a label
-- (Sergio, 18 Nov: «sempre uguale per tutte le armature, sempre uguale per tutte le scarpe»)
M.TINT = { mask = hexc("f26419"), chest = hexc("9ec4e0"), cloak = hexc("b07ce8"), legs = hexc("5cdbb8"), gloves = hexc("ffb703") }

-- the name of a slot in the type symbols (WB-078)
local TYPE = { mask = "tipo_elmo", chest = "tipo_corazza", cloak = "tipo_mantello", legs = "tipo_stivali", gloves = "tipo_guanti" }

-- a picture inside the box (x, y, w, h), as large as it fits and centered: never stretched
local function fit(g, name, x, y, w, h)
	local m = P[name]
	local k = math.min(w / m.w, h / m.h)
	return kit.pic(g, name, x + (w - m.w * k) / 2, y + (h - m.h * k) / 2, m.w * k, m.h * k)
end

-- A square slot s wide at the Figma point (x, y), with the straight frames of WB-078
-- (Sergio, 18 Nov): the frame (lit when chosen), the piece's picture in the middle, on
-- the top left corner the tab with the symbol of its type, its level on the top right,
-- and the band INDOSSATO at the bottom when it is worn. Without a set: the empty frame
-- with the shadow of the slot and its type. Everything grows with s. Returns its nodes
function M.slot(g, x, y, s, opt)
	opt = opt or {}
	local made = {}
	local function keep(n) made[#made + 1] = n return n end
	local frame = opt.sel and "casella_scelta" or opt.set and "casella" or "casella_vuota"
	keep(kit.pic(g, frame, x - s * 0.04, y - s * 0.04, s * 1.08, s * 1.08))
	if opt.set then
		keep(fit(g, M.icon(opt.set, opt.slot, opt.level), x + s * 0.12, y + s * 0.12, s * 0.76, s * 0.76))
	elseif opt.slot and M.ART[opt.slot] then
		keep(fit(g, "vuoto_" .. M.ART[opt.slot], x + s * 0.16, y + s * 0.16, s * 0.68, s * 0.68))
	end
	local tab = s * 0.34
	if opt.slot and TYPE[opt.slot] then
		keep(kit.pic(g, "linguetta", x - s * 0.05, y - s * 0.05, tab, tab))
		local sym = keep(fit(g, TYPE[opt.slot], x - s * 0.05 + tab * 0.18, y - s * 0.05 + tab * 0.16, tab * 0.64, tab * 0.64))
		gui.set_color(sym, M.TINT[opt.slot])
	end
	if not opt.set then return made end
	if opt.level then
		local top = opt.level >= equip.LIVELLO_MAX
		local d = math.max(30, s * 0.34)
		keep(kit.pic(g, top and "livello_oro" or "livello_ferro", x + s - d + d * 0.25, y - d * 0.25, d, d))
		local fs = math.max(16, d * 0.45)
		keep(kit.text(g, tostring(opt.level), x + s - d / 2 + d * 0.25, y + d * 0.25 + fs * 0.37, fs,
			top and KC.INK or KC.SAND, "middle"))
	end
	if opt.worn then
		local bw = s * 0.94
		local bh = bw * P.fascia_indossato.h / P.fascia_indossato.w
		local by = y + s - bh - s * 0.03
		keep(kit.pic(g, "fascia_indossato", x + s * 0.03, by, bw, bh))
		local fs = math.max(16, s * 0.15)
		local n = keep(kit.text(g, T.worn, x + s / 2, by + bh / 2 + fs * 0.37, fs, KC.INK, "middle"))
		local w = kit.width(n)
		if w > bw * 0.9 then gui.set_scale(n, gui.get_scale(n) * (bw * 0.9 / w)) end
	end
	return made
end

-- where the pieces sit on the devil (feet at (cx, feet), h tall)
local function body(cx, feet, h)
	local k = h / 380
	return { mask = { cx - 10 * k, feet - 330 * k }, chest = { cx + 8 * k, feet - 190 * k },
		cloak = { cx - 70 * k, feet - 175 * k }, legs = { cx - 30 * k, feet - 18 * k } }
end

-- The apprentice h tall, its feet at the Figma point (cx, feet), on the group g
function M.devil(s, g, cx, feet, h)
	local pose = kit.group(g, cx, feet)
	-- (the apprentice of the Figma is 380 tall at 338 / DISEGNO_H: menu/home.lua)
	local k = 338 * h / 380 / game.DISEGNO_H
	gui.set_scale(pose.node, vmath.vector3(k, k, 1))
	s.figure = scoria.new(s.colore, scoria.player)
	clock.sync(s.figure)
	s.st = { x = 0, y = 0, facing = 1, grounded = true, moving = 0, fermo = true }
	scoria.update(s.figure, 0, s.st)
	gui.set_parent(s.figure.root, pose.node)
	scoria.set_enabled(s.figure, true)
	s.outline = outline.new(s.figure, pose.node, scoria.player)
	return pose
end

-- The pieces worn by the loadout a, each in its slot in the column x (tops at ys),
-- with a line and a nail to where it sits on the devil. Tapping one: "posto:<slot>".
-- sel: the slot chosen (lit). try: { set, slot } a piece tried on instead
M.LABEL = "secondario_acceso"

-- moves a text made at x = 0 to start at x
local function shift(n, x)
	local pos = gui.get_position(n)
	pos.x = pos.x + x
	gui.set_position(n, pos)
end

function M.worn(s, g, a, cx, feet, h, x, ys, size, sel, try, bare)
	local k = h / 380
	-- where each level sits, next to its piece, and the zone that opens it
	-- (Sergio, 18 Nov: helmet, armour and gloves on the right, the gloves by the
	-- hand behind; cloak and boots on the left)
	local at = { mask = { 88, -318, 190, 120 }, chest = { 92, -205, 150, 110 }, gloves = { 96, -120, 110, 80 },
		cloak = { -128, -150, 90, 150 }, legs = { -118, -40, 230, 80 } }
	local left = { cloak = true, legs = true }
	local cats = { mask = "elmo", chest = "corazza", cloak = "mantello", legs = "stivali" }
	local colors = {}
	for _, sl in ipairs(equip.SLOTS) do
		local set = a.gear[sl.id]
		if try and try[2] == sl.id then set = try[1] end
		local level = set and wallet.level(s.prof, set, sl.id)
		local p = at[sl.id]
		local bx, by = cx + p[1] * k, feet + p[2] * k
		-- only the piece chosen is lit (Sergio, 18 Nov)
		if sel == sl.id then colors[cats[sl.id]] = vmath.vector4(1, 0.62, 0.12, 1) end
		-- one label, shaped like a button: the type's symbol and the level, or
		-- only the dimmed symbol on an empty place (Sergio, 18 Nov); on the outer side, never over
		-- the devil. Symbol, number and arrow are measured, then the label is as
		-- wide as them with even padding; all centered on the plate's face (2 px
		-- above its middle: the shadow under it), the arrow sits 2 px lower
		-- bare: no labels (the SHOP, Sergio 18 Nov: «lì non vuoi potenziare niente»)
		if TYPE[sl.id] and not bare then
			local top = level and level >= equip.LIVELLO_MAX
			local lh, pad, sym, gap = 44, 16, 26, 8
			local cy = by - 2
			-- empty: only the symbol, dimmed (no number, no arrow: Sergio, 18 Nov)
			local num = level and kit.text(g, tostring(level), 0, cy + 7, 19, top and KC.HOT or KC.SAND)
			local arrow = level and kit.text(g, "›", 0, cy + 5, 19, KC.MUTE)
			local nw, aw = num and kit.width(num) or 0, arrow and kit.width(arrow) or 0
			local lw = level and pad + sym + gap + nw + 6 + aw + pad or pad + sym + pad
			local lx = left[sl.id] and math.max(screen.x0 + 12, bx + 17 - lw) or bx - 17
			local plate = kit.strip(g, M.LABEL, lx, by - lh / 2, lw, lh)
			local icon = fit(g, TYPE[sl.id], lx + pad, cy - sym / 2, sym, sym)
			if num then
				gui.move_below(plate.node, num)
				shift(num, lx + pad + sym + gap)
				shift(arrow, lx + pad + sym + gap + nw + 6)
			end
			local tint = M.TINT[sl.id]
			gui.set_color(icon, num and tint or vmath.vector4(tint.x, tint.y, tint.z, 0.45))
			-- the label opens the place too
			kit.zone(g, s.buttons, lx, by - lh / 2, lw, lh, "posto:" .. sl.id)
		end
		local zx = sl.id == "cloak" and cx - 150 * k or cx - p[3] / 2 * k
		kit.zone(g, s.buttons, zx, by - p[4] / 2 * k, p[3] * k, p[4] * k, "posto:" .. sl.id)
	end
	if s.outline then outline.colors(s.outline, colors) end
end

-- the stats shown, in this order, and how each is written
M.STATS = {
	{ "attack" }, { "defense" }, { "max_hp" }, { "walk_speed" }, { "jump_height" }, { "air_speed" },
	{ "teleport_ticks", "seconds" }, { "teleports" }, { "parachutes" }, { "air_jumps" },
	{ "fall_damage_mul", "percent" }, { "knockback_mul", "percent" }, { "blast_push", "percent" },
	{ "trap_radius" }, { "status_turns" }, { "burning_blasts", "yes_no" },
}
local LESS = { teleport_ticks = true, fall_damage_mul = true, knockback_mul = true }

function M.value(v, how)
	if type(v) ~= "number" then return v and TA.yes or TA.no end
	if how == "seconds" then return TA.seconds:format(v / 60) end
	if how == "yes_no" then return v > 0 and TA.yes or TA.no end
	if how == "percent" then return string.format("%d%%", math.floor(v * 100 + 0.5)) end
	if v % 1 ~= 0 then return string.format("%.1f", v) end
	return tostring(v)
end

-- The stats of the loadout a (and of a2, the same with a piece changed: its value and an arrow)
-- in the column at (x, y), w wide: STATISTICHE and all the rows in one screen
-- (Sergio, 15 Nov: no pages), every other row on a dark strip, the texts at the
-- smallest size of the menus. The rows that change with a2 come first. Better
-- than the base in mint, worse in red (Sergio, 15 Nov: ice for worse is
-- counterintuitive).
-- o.from, o.to: only those rows, big (the sheet of the Sigilli, two columns of
-- M.STAT_ROWS); o.title = false: no title
M.STAT_ROWS = 8
M.STAT_PAD = 12
M.SHORT_ROWS = 7
-- where each point comes from (Statistiche A, Sergio 15 Nov 22:48): the colors of
-- the parts of a bar, in this order
M.PART_COLORS = { kit.hex("7d7068"), kit.hex("ffc83d"), kit.hex("ff7a1a"), kit.hex("8fdcff") }

-- The parts of every stat of the loadout a: base, level, pieces, sigilli
-- (the pieces are what is left, so the parts always add up to the value)
local function parts_of(p, base, a, now)
	local zero = loadout.stats(base, {}, {}, 1)
	local lvl = loadout.stats(base, {}, {}, p.livello)
	local sig = loadout.stats(base, { tree = a.tree }, {}, 1)
	local out = {}
	for k, v in pairs(now) do
		if type(v) == "number" and type(zero[k]) == "number" then
			local b, l, g = zero[k], lvl[k] - zero[k], sig[k] - zero[k]
			out[k] = { b, l, v - b - l - g, g }
		end
	end
	return out
end

-- vertical stripes from x1 to x2 (the piece chosen: mint better, red worse)
local function stripes(g, y, h, x1, x2, color)
	local px = x1
	while px < x2 do
		kit.rect(g, px, y, math.min(4, x2 - px), h, color)
		px = px + 7
	end
end

-- The bars run from the base to the highest value in the game (Sergio, 15 Nov
-- 23:14): menu/stat_max.lua, written by tools/statistiche/massimi.lua (tutti.sh
-- fails when it is behind the pieces and the Sigilli). The base is a fixed
-- stub on the left, the rest of the bar is what you can still gain; a change
-- is never thinner than DELTA_MIN, its size is written next to the bar.
-- Only the stats where more is better have a bar (not the counts, not the
-- ones where less is better).
M.MAX = require "menu.stat_max"
M.BASE_STUB, M.DELTA_MIN = 0.2, 8
-- colors: the parts' colors, when they aren't the four of the menus (the tag)
function M.bar(g, x, y, w, h, parts, now, after, k, colors)
	colors = colors or M.PART_COLORS
	local mx = M.MAX[k]
	if not parts or not mx or type(now) ~= "number" then return end
	local b = parts[1]
	local stub = w * M.BASE_STUB
	local function at(v)
		if v <= b then
			if b <= 0 then return v >= b and stub or 0 end
			return stub * math.max(v, 0) / b
		end
		return stub + (w - stub) * math.min(1, (v - b) / math.max(mx - b, 1e-9))
	end
	kit.rect(g, x - 2, y - 2, w + 4, h + 4, KC.INK)
	kit.rect(g, x, y, w, h, KC.TRACK)
	local solid = math.min(now, type(after) == "number" and after or now)
	-- the base, then level, pieces and Sigilli above it, up to the value
	local v, edge = b, 0
	local function seg(x1, x2, color)
		if x2 > x1 then
			kit.rect(g, x + x1, y, x2 - x1, h, color)
			kit.rect(g, x + x2 - 1, y, 2, h, KC.INK)
		end
	end
	seg(0, at(math.min(b, solid)), colors[1])
	for i = 2, 4 do
		if parts[i] > 0 then
			seg(at(math.min(v, solid)), at(math.min(v + parts[i], solid)), colors[i])
			v = v + parts[i]
		end
	end
	if type(after) == "number" and after ~= now then
		local x1, x2 = at(math.min(now, after)), at(math.max(now, after))
		x2 = math.max(x2, x1 + M.DELTA_MIN)
		if x2 > w then x2, x1 = w, w - M.DELTA_MIN end
		stripes(g, y, h, x + x1, x + x2, after > now and KC.MINT or KC.RED)
	end
end

-- how much a stat changes, written like its value: "+2", "+10%", "−0.4 S"
function M.delta(v, v2, how)
	if type(v) ~= "number" or type(v2) ~= "number" or how == "yes_no" then return nil end
	local d = v2 - v
	local t
	if how == "percent" then t = string.format("%+d%%", math.floor(d * 100 + (d > 0 and 0.5 or -0.5)))
	elseif how == "seconds" then t = string.format("%+.1f S", d / 60)
	elseif math.abs(d - math.floor(d + 0.5)) < 1e-6 then t = string.format("%+d", math.floor(d + 0.5))
	else t = string.format("%+.1f", d) end
	return (t:gsub("^%-", "−"))
end

-- the four colors of the bars and their names, two by two, w wide from (x, y)
function M.legend(g, x, y, w)
	for i, c in ipairs(M.PART_COLORS) do
		local cx, cy = x + ((i - 1) % 2) * w / 2, y + math.floor((i - 1) / 2) * 22
		kit.rect(g, cx, cy + 4, 16, 12, KC.INK)
		kit.rect(g, cx + 2, cy + 6, 12, 8, c)
		kit.text(g, T.parts[i], cx + 22, cy + 16, 16, KC.MUTE, "start")
	end
end

-- The stats of the loadout a (and of a2, the same with a piece changed: its value and an arrow)
-- in the column at (x, y), w wide: STATISTICHE and the rows, each with its bar
-- (Statistiche A: where the points come from, and the piece chosen striped).
-- Better than the base in mint, worse in red (Sergio, 15 Nov: ice for worse is
-- counterintuitive). The rows that change with a2 come first.
-- o.from, o.to: only those rows, big (the sheet, two columns of M.STAT_ROWS);
-- o.title = false: no title; o.rows: these rows; o.empty: the text with no rows;
-- o.legend: the colors' names under the rows (in the sheet: in the head).
-- Returns how tall the rows are
function M.stats(s, g, x, y, w, a, a2, o)
	o = o or {}
	local p = s.prof
	local base = game.base_stats()
	local now = loadout.stats(base, a, wallet.levels(p, a), p.livello, wallet.signs(p, a))
	local after = a2 and loadout.stats(base, a2, (a2.levels or wallet.levels(p, a2)), p.livello, wallet.signs(p, a2))
	local parts = parts_of(p, base, a, now)
	local order = {}
	if o.rows then
		order = o.rows
	elseif after then
		for _, st in ipairs(M.STATS) do if after[st[1]] ~= now[st[1]] then order[#order + 1] = st end end
		for _, st in ipairs(M.STATS) do if after[st[1]] == now[st[1]] then order[#order + 1] = st end end
	else
		order = M.STATS
	end
	-- behind the column an iron panel (Sergio, 15 Nov): the rows are read on it,
	-- not on the painting; the same margin (M.STAT_PAD) on every side of the rows
	local big = o.from ~= nil
	local from, to = o.from or 1, o.to or #order
	local rh = big and 52 or 40
	local head = big and 50 or 34
	local name_size, value_size = big and 19 or 16, big and 22 or 18
	local rows_h = (big and M.STAT_ROWS or math.max(#order, o.empty and 1 or 0)) * rh
	-- o.fixed: the panel as tall as that many rows, whatever it shows (what hangs
	-- under it never moves)
	local box_h = o.fixed and math.max(rows_h, o.fixed * rh) or rows_h
	local tall = head + box_h + ((o.legend and not big) and 52 or 0)
	kit.panel(kit.group(g, x + w / 2, y + tall / 2).node, w + 2 * M.STAT_PAD, tall + 2 * M.STAT_PAD)
	if o.title ~= false then kit.text(g, T.stats, x, y + 18, 22, KC.HOT, "start", 1) end
	if o.legend then
		if big then M.legend(g, x + w - 210, y - 2, 220) else M.legend(g, x, y + head + box_h + 8, w) end
	end
	if o.empty and #order == 0 then
		kit.text(g, kit.upper(o.empty), x, y + head + 19, 16, KC.MUTE, "start", 0.5)
	end
	for i = from, math.min(to, #order) do
		local st = order[i]
		local k, how = st[1], st[2]
		local yy = y + head + (i - from) * rh
		local line = yy + (big and 22 or 17)
		local v, b = now[k], base[k]
		local col = KC.SAND
		if type(v) == "number" and type(b) == "number" and v ~= b then
			col = ((v > b) ~= (LESS[k] == true)) and KC.MINT or KC.RED
		end
		local t = kit.upper(M.value(v, how))
		-- with the piece chosen on: the new value, in mint when it gets better and in red
		-- when it gets worse (the colors of plus and minus everywhere), and a small
		-- arrow that says where the number goes, for who does not tell the colors
		local changes = after and after[k] ~= v
		local up
		if changes then
			local v2 = after[k]
			t = kit.upper(M.value(v2, how))
			up = (type(v2) == "number" and v2 or v2 and 1 or 0) > (type(v) == "number" and v or v and 1 or 0)
			col = (up ~= (LESS[k] == true)) and KC.MINT or KC.RED
		end
		local n = kit.text(g, t, x + w, line, value_size, col, "end")
		local vw = kit.width(n)
		if vw > w * 0.52 then
			gui.set_scale(n, gui.get_scale(n) * (w * 0.52 / vw))
			vw = w * 0.52
		end
		if changes then
			-- the signs drawn by Codex (WB-061), ivory: tinted like the number
			local arrow = kit.piece(g, up and "segno_sale" or "segno_scende", x + w - vw - 12, line - 7, big and 18 or 16)
			gui.set_color(arrow, col)
			vw = vw + 24
		end
		local name = kit.text(g, kit.upper(TA.stats[k]), x, line, name_size, KC.SAND)
		local wide, room = kit.width(name), w - vw - 10
		-- never under 16 (the smallest text of the menus)
		if wide > room then gui.set_scale(name, gui.get_scale(name) * math.max(room / wide, 16 / name_size)) end
		-- under the name the bar, and at its right how much the piece chosen changes
		local dt = changes and M.delta(v, after[k], how)
		local bw = w
		if dt then
			kit.text(g, dt, x + w, line + (big and 23 or 19), 16, col, "end")
			bw = w - (big and 70 or 56)
		end
		M.bar(g, x, line + (big and 10 or 7), bw, big and 12 or 10, parts[k], v, changes and after[k] or nil, k)
	end
	return tall
end

-- The column of the stats (Impeccable and Taste skill, Sergio 15 Nov: not the
-- same wall of 16 rows on four screens): only the rows the piece chosen
-- changes (a2), or with nothing chosen the rows your pieces move from the base,
-- at most M.SHORT_ROWS; under it VEDI TUTTE opens all of them in one screen
-- (M.sheet, "foglio"). The same column on every screen where the gear changes
-- (Sergio, 15 Nov 22:48)
function M.stats_short(s, g, x, y, w, a, a2)
	local p = s.prof
	local base = game.base_stats()
	local now = loadout.stats(base, a, wallet.levels(p, a), p.livello, wallet.signs(p, a))
	local ref = a2 and loadout.stats(base, a2, (a2.levels or wallet.levels(p, a2)), p.livello, wallet.signs(p, a2)) or base
	local rows = {}
	for _, st in ipairs(M.STATS) do
		if ref[st[1]] ~= now[st[1]] and #rows < M.SHORT_ROWS then rows[#rows + 1] = st end
	end
	local tall = M.stats(s, g, x, y, w, a, a2, { rows = rows, empty = a2 and T.no_change or T.all_base, legend = true, fixed = M.SHORT_ROWS })
	-- VEDI TUTTE hangs from the panel like a tag, on two straps (Sergio, 18 Nov:
	-- apart from it, it wasn't clear it was about the stats); the panel is always
	-- as tall, so it never moves (Sergio, 17 Nov)
	local bottom = y + tall + M.STAT_PAD
	local tw, th = math.min(w, 170), 46
	local tx, ty = x + (w - tw) / 2, bottom + 12
	for _, sx in ipairs({ tx + 26, tx + tw - 26 }) do
		local strap = ui.sagoma("forma", sx - g.ox, g.oy - (bottom + 6), 9, 26, KC.INK, g.node)
		gui.set_slice9(strap, vmath.vector4(3, 3, 3, 3))
	end
	local b = kit.card(g, tx, ty, tw, th, KC.ROSE)
	kit.text(b.g, T.see_all, x + w / 2, ty + 30, 18, KC.SAND, "middle", 0.5)
	kit.button(s.buttons, b, "foglio")
end

-- All the stats in one screen (Sergio, 15 Nov: no pages), big, in two columns
-- in the middle of the screen; the button at the top right closes it (back: its label)
function M.sheet(s, g, a, a2, back)
	M.stats(s, g, 460, 110, 370, a, a2, { from = 1, to = M.STAT_ROWS, legend = true })
	M.stats(s, g, 878, 110, 370, a, a2, { from = M.STAT_ROWS + 1, to = #M.STATS, title = false })
	-- (drawn after the panels: it sits inside the head of the second one, the
	-- same plate as VEDI TUTTE; Sergio, 15 Nov: not the lit frame over the edge)
	local b = kit.card(g, 1248 - 206, 106, 206, 44, KC.ROSE)
	kit.text(b.g, back, 1248 - 103, 135, 18, KC.SAND, "middle", 0.5)
	kit.button(s.buttons, b, "foglio")
end

-- The three loadouts at (x, y): the label, then 1 2 3 on small plates, the
-- active one light; a closed one says from which level. Tapping: "<prefix>:<i>"
function M.loadouts(s, g, x, y, active, prefix, label)
	kit.text(g, label, x, y + 14, 18, KC.MUTE, "start", 1)
	local n = 0
	for i = 1, loadout.LOADOUTS do
		local bx = x + n * 76
		if loadout.open(i, s.prof.livello) then
			local on = i == active
			kit.strip(g, on and "piastrina_chiara" or "piastrina", bx, y + 24, 66, 52)
			kit.text(g, tostring(i), bx + 33, y + 60, 28, on and KC.INK or KC.SAND, "middle")
			kit.zone(g, s.buttons, bx - 5, y + 18, 76, 64, prefix .. ":" .. i)
			n = n + 1
		else
			kit.text(g, T.loadout_locked:format(loadout.LOADOUT_LEVELS[i]), bx + 4, y + 58, 17, KC.MUTE, "start", 1)
			break
		end
	end
end

-- A row of filters from (x, y): small iron plates, the active one warm.
-- list: { { label, ui_action }, ... }
function M.chips(s, g, x, y, list, active)
	local cx = x
	for i, c in ipairs(list) do
		local on = i == active
		local n = kit.text(g, c[1], 0, y + 31, 19, on and KC.HOT or KC.SAND, "middle")
		local w = kit.width(n) + 30
		gui.delete_node(n)
		kit.strip(g, on and "piastrina_calda" or "piastrina", cx, y, w, 48)
		kit.text(g, c[1], cx + w / 2, y + 31, 19, on and KC.HOT or KC.SAND, "middle")
		kit.zone(g, s.buttons, cx - 3, y - 6, w + 6, 60, c[2])
		cx = cx + w + 8
	end
	return cx
end

return M
