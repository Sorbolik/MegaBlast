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
--   gear_ui.families(s, g, x, y, active)                -- the families' dots
--   gear_ui.effects(set, slot, level)                   -- "+4% IN ARIA  −2% VITA"
--   gear_ui.devil(s, g, cx, feet, h)                    -- the apprentice, s.figure

local ui = require "ui.ui"
local kit = require "ui.kit"
local game = require "sim.game"
local equip = require "sim.gear"
local loadout = require "sim.loadout"
local scoria = require "battle.scoria"
local wallet = require "menu.wallet"
local TA = require("lang.text").armory
local T = require("lang.text").gear_ui

local M = {}

local KC = kit.C
M.ROMAN = { "I", "II", "III", "IV" }

-- the name of a slot in the pictures' names (WB-043)
M.ART = { mask = "elmo", chest = "corazza", cloak = "mantello", legs = "stivali" }
-- the families' colors (gear.SETS[].color)
function M.color(set)
	local f = equip.BY_ID[set]
	return f and kit.hex(f.color) or KC.SAND
end

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

-- the rows of a piece but its signature, in one line
function M.effects(set, slot, level)
	local t = {}
	for _, e in ipairs(equip.piece(set, slot, level)) do
		if e.row ~= "sign" then t[#t + 1] = M.effect(e) end
	end
	return table.concat(t, "  ")
end

-- A square slot s wide at the Figma point (x, y): the frame (gold when chosen),
-- the family's line, the piece's picture, its level in the corner and the tick
-- when it is worn. Without a set: the empty frame with the slot's shadow
function M.slot(g, x, y, s, opt)
	opt = opt or {}
	local frame = opt.sel and "casella_scelta" or opt.set and "casella" or "casella_vuota"
	kit.pic(g, frame, x - s * 0.04, y - s * 0.04, s * 1.08, s * 1.08)
	if not opt.set then
		if opt.slot then kit.pic(g, "vuoto_" .. M.ART[opt.slot], x + s * 0.14, y + s * 0.12, s * 0.72, s * 0.72) end
		return
	end
	local line = kit.rect(g, x + s * 0.18, y + s - 12, s * 0.64, 5, M.color(opt.set))
	kit.pic(g, M.icon(opt.set, opt.slot, opt.level), x + s * 0.1, y + s * 0.07, s * 0.8, s * 0.8)
	if opt.level then
		local top = opt.level >= equip.LIVELLO_MAX
		kit.pic(g, top and "livello_oro" or "livello_ferro", x + s - 28, y - 10, 38, 38)
		kit.text(g, tostring(opt.level), x + s - 9, y + 15, 16, top and KC.INK or KC.SAND, "middle")
	end
	if opt.worn then kit.pic(g, "spunta", x + 3, y + 3, 26, 26) end
	return line
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
	s.st = { x = 0, y = 0, facing = 1, grounded = true, moving = 0, fermo = true }
	scoria.update(s.figure, 0, s.st)
	gui.set_parent(s.figure.root, pose.node)
	scoria.set_enabled(s.figure, true)
	return pose
end

-- The pieces worn by the loadout a, each in its slot in the column x (tops at ys),
-- with a line and a nail to where it sits on the devil. Tapping one: "posto:<slot>".
-- sel: the slot chosen (lit). try: { set, slot } a piece tried on instead
function M.worn(s, g, a, cx, feet, h, x, ys, size, sel, try)
	local P = body(cx, feet, h)
	for i, sl in ipairs(equip.SLOTS) do
		local set = a.gear[sl.id]
		if try and try[2] == sl.id then set = try[1] end
		local level = set and wallet.level(s.prof, set, sl.id)
		local y = ys[i]
		local px, py = P[sl.id][1], P[sl.id][2]
		local sx, sy = x + size + 4, y + size / 2
		kit.line(g, sx, sy, sx + 18, sy, 5, KC.INK)
		kit.line(g, sx + 18, sy, px, py, 5, KC.INK)
		local lit = sel == sl.id and KC.HOT or KC.SAND
		kit.line(g, sx, sy, sx + 18, sy, 2, lit)
		kit.line(g, sx + 18, sy, px, py, 2, lit)
		kit.pic(g, "chiodo", px - 8, py - 8, 16, 16)
		kit.text(g, sl.name, x, y - 9, 18, KC.SAND, "start", 1)
		M.slot(g, x, y, size, { set = set, slot = sl.id, level = level, sel = sel == sl.id })
		kit.zone(g, s.buttons, x - 4, y - 24, size + 30, size + 28, "posto:" .. sl.id)
	end
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
function M.stats(s, g, x, y, w, a, a2, o)
	o = o or {}
	local p = s.prof
	local base = game.base_stats()
	local now = loadout.stats(base, a, wallet.levels(p, a), p.livello)
	local after = a2 and loadout.stats(base, a2, wallet.levels(p, a2), p.livello)
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
	local rh = big and 54 or 27
	local name_size, value_size = big and 19 or 16, big and 22 or 18
	local tall = 34 + (big and M.STAT_ROWS or math.max(#order, o.empty and 1 or 0)) * rh
	kit.panel(kit.group(g, x + w / 2, y + tall / 2).node, w + 2 * M.STAT_PAD, tall + 2 * M.STAT_PAD)
	if o.title ~= false then kit.text(g, T.stats, x, y + 18, 22, KC.HOT, "start", 1) end
	if o.empty and #order == 0 then
		kit.text(g, kit.upper(o.empty), x, y + 38 + 19, 16, KC.MUTE, "start", 0.5)
	end
	for i = from, to do
		local st = order[i]
		local k, how = st[1], st[2]
		local yy = y + 38 + (i - from) * rh
		if (i - from) % 2 == 0 then
			local r = kit.strip(g, "riga_scura", x - 8, yy, w + 16, rh - 4)
			kit.tint(r.parts, kit.with_alpha(KC.SAND, 0.55))
		end
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
		local n = kit.text(g, t, x + w, yy + (big and 33 or 20), value_size, col, "end")
		local vw = kit.width(n)
		if vw > w * 0.52 then
			gui.set_scale(n, gui.get_scale(n) * (w * 0.52 / vw))
			vw = w * 0.52
		end
		if changes then
			-- the signs drawn by Codex (WB-061), ivory: tinted like the number
			local arrow = kit.piece(g, up and "segno_sale" or "segno_scende", x + w - vw - 12, yy + (big and 26 or 13), big and 18 or 16)
			gui.set_color(arrow, col)
			vw = vw + 24
		end
		local name = kit.text(g, kit.upper(TA.stats[k]), x, yy + (big and 32 or 19), name_size, KC.SAND)
		local wide, room = kit.width(name), w - vw - 10
		-- never under 16 (the smallest text of the menus)
		if wide > room then gui.set_scale(name, gui.get_scale(name) * math.max(room / wide, 16 / name_size)) end
	end
end

-- The column of the stats (Impeccable and Taste skill, Sergio 15 Nov: not the
-- same wall of 16 rows on four screens): only the rows the piece chosen
-- changes (a2), or with nothing chosen the rows your pieces move from the base;
-- under it VEDI TUTTE opens all of them in one screen (M.sheet, "foglio").
-- Returns the bottom of the button
function M.stats_short(s, g, x, y, w, a, a2)
	local p = s.prof
	local base = game.base_stats()
	local now = loadout.stats(base, a, wallet.levels(p, a), p.livello)
	local ref = a2 and loadout.stats(base, a2, wallet.levels(p, a2), p.livello) or base
	local rows = {}
	for _, st in ipairs(M.STATS) do
		if ref[st[1]] ~= now[st[1]] then rows[#rows + 1] = st end
	end
	M.stats(s, g, x, y, w, a, a2, { rows = rows, empty = a2 and T.no_change or T.all_base })
	local bottom = y + 34 + math.max(#rows, 1) * 27 + M.STAT_PAD + 14
	local b = kit.card(g, x - M.STAT_PAD, bottom, w + 2 * M.STAT_PAD, 56, KC.ROSE)
	kit.text(b.g, T.see_all, x + w / 2, bottom + 36, 20, KC.SAND, "middle", 0.5)
	kit.button(s.buttons, b, "foglio")
	return bottom + 56
end

-- All the stats in one screen (Sergio, 15 Nov: no pages), big, in two columns
-- in the middle of the screen; the button at the top right closes it (back: its label)
function M.sheet(s, g, a, a2, back)
	M.stats(s, g, 460, 110, 370, a, a2, { from = 1, to = M.STAT_ROWS })
	M.stats(s, g, 878, 110, 370, a, a2, { from = M.STAT_ROWS + 1, to = #M.STATS, title = false })
	-- (drawn after the panels: it sits in the head of the second one)
	local b = kit.card(g, 1248 - 236, 102, 236, 44, KC.ROSE, { sel = true })
	kit.text(b.g, back, 1248 - 118, 131, 19, KC.SAND, "middle")
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

-- The families as dots of their color from (x, y): tapping one shows only its
-- pieces ("famiglia:<id>"), again all of them; the chosen one has a ring
function M.families(s, g, x, y, active)
	for i, f in ipairs(equip.SETS) do
		local cx, cy = x + (i - 1) * 50 + 24, y + 24
		if active == f.id then kit.dot(g, cx, cy, 44, KC.HOT) end
		kit.dot(g, cx, cy, 34, KC.INK)
		kit.dot(g, cx, cy, 28, kit.hex(f.color))
		kit.zone(g, s.buttons, cx - 25, cy - 30, 50, 60, "famiglia:" .. f.id)
	end
end

return M
