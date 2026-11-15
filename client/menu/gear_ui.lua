-- The pieces shared by the ZAINO and the ARMERIA (Figma "RIORGANIZZAZIONE MENU ·
-- 14 nov", Consigliata/2..5): the square slot with a piece's icon (WB-043/044),
-- the pieces worn with their labels on the devil, the column of the stats, the
-- loadouts 1 2 3, the filters. Everything placed with the Figma's coordinates
-- (ui/kit.lua: x from the left, y from the top).
--
--   local gear_ui = require "menu.gear_ui"
--   gear_ui.slot(g, x, y, s, opt)        -- opt: set, slot, level, worn, sel, empty_slot
--   gear_ui.worn(s, g, cx, feet, h, x, ys, size, sel)   -- the labels of the pieces worn
--   gear_ui.stats(g, x, y, w, now, after)               -- the column of the stats
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
		kit.text(g, sl.name, x, y - 8, 14, KC.SAND, "start", 1)
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

-- The stats of the loadout a (and of a2, the same with a piece changed: "a → b")
-- in the column at (x, y), w wide: STATISTICHE, then a row each, every other row
-- on a dark strip; better than the base in mint, worse in ice (the font has no
-- arrow: "a › b")
function M.stats(s, g, x, y, w, a, a2)
	local p = s.prof
	local base = game.base_stats()
	local now = loadout.stats(base, a, wallet.levels(p, a), p.livello)
	local after = a2 and loadout.stats(base, a2, wallet.levels(p, a2), p.livello)
	kit.text(g, T.stats, x, y + 16, 18, KC.HOT, "start", 1)
	local rh = 27.5
	for i, st in ipairs(M.STATS) do
		local k, how = st[1], st[2]
		local yy = y + 34 + (i - 1) * rh
		if i % 2 == 1 then
			local r = kit.strip(g, "riga_scura", x - 8, yy - 4, w + 16, rh)
			kit.tint(r.parts, kit.with_alpha(KC.SAND, 0.55))
		end
		local name = kit.text(g, kit.upper(TA.stats[k]), x, yy + 15, 14, KC.SAND)
		local wide = kit.width(name)
		if wide > w * 0.62 then gui.set_scale(name, gui.get_scale(name) * (w * 0.62 / wide)) end
		local v, b = now[k], base[k]
		local col = KC.SAND
		if type(v) == "number" and type(b) == "number" and v ~= b then
			col = ((v > b) ~= (LESS[k] == true)) and KC.MINT or KC.ICE
		end
		local t = kit.upper(M.value(v, how))
		if after and after[k] ~= v then
			t = t .. " › " .. kit.upper(M.value(after[k], how))
			col = KC.HOT
		end
		local n = kit.text(g, t, x + w, yy + 15, 16, col, "end")
		local vw = kit.width(n)
		if vw > w * 0.5 then gui.set_scale(n, gui.get_scale(n) * (w * 0.5 / vw)) end
	end
end

-- The three loadouts at (x, y): the label, then 1 2 3 on small plates, the
-- active one light; a closed one says from which level. Tapping: "<prefix>:<i>"
function M.loadouts(s, g, x, y, active, prefix, label)
	kit.text(g, label, x, y + 12, 14, KC.MUTE, "start", 1)
	local n = 0
	for i = 1, loadout.LOADOUTS do
		local bx = x + n * 62
		if loadout.open(i, s.prof.livello) then
			local on = i == active
			kit.strip(g, on and "piastrina_chiara" or "piastrina", bx, y + 20, 54, 42)
			kit.text(g, tostring(i), bx + 27, y + 49, 22, on and KC.INK or KC.SAND, "middle")
			kit.zone(g, s.buttons, bx - 3, y + 14, 60, 54, prefix .. ":" .. i)
			n = n + 1
		else
			kit.text(g, T.loadout_locked:format(loadout.LOADOUT_LEVELS[i]), bx + 4, y + 47, 13, KC.MUTE, "start", 1)
			break
		end
	end
end

-- A row of filters from (x, y): small iron plates, the active one warm.
-- list: { { label, ui_action }, ... }
function M.chips(s, g, x, y, list, active)
	local cx = x
	for i, c in ipairs(list) do
		local w = #c[1] * 9.5 + 20
		local on = i == active
		kit.strip(g, on and "piastrina_calda" or "piastrina", cx, y, w, 36)
		kit.text(g, c[1], cx + w / 2, y + 24, 14.4, on and KC.HOT or KC.SAND, "middle")
		kit.zone(g, s.buttons, cx, y - 4, w, 44, c[2])
		cx = cx + w + 6
	end
	return cx
end

-- The families as dots of their color from (x, y): tapping one shows only its
-- pieces ("famiglia:<id>"), again all of them; the chosen one has a ring
function M.families(s, g, x, y, active)
	for i, f in ipairs(equip.SETS) do
		local cx, cy = x + (i - 1) * 30 + 12, y + 18
		if active == f.id then kit.dot(g, cx, cy, 32, KC.HOT) end
		kit.dot(g, cx, cy, 24, KC.INK)
		kit.dot(g, cx, cy, 19, kit.hex(f.color))
		kit.zone(g, s.buttons, cx - 15, cy - 22, 30, 44, "famiglia:" .. f.id)
	end
end

return M
