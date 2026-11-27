-- The pieces shared by the ZAINO, the BOTTEGA and the players' tags: the piece cards
-- (big with their rows, small with only the picture), the apprentice wearing a piece
-- tried on, the column of what you wear, the column of the stats, the loadouts 1 2 3,
-- the filters. Everything placed with the Figma's coordinates
-- (ui/kit.lua: x from the left, y from the top).
--
--   local gear_ui = require "menu.gear_ui"
--   gear_ui.card(g, x, y, opt) / gear_ui.mini(g, x, y, s, opt)   -- the piece cards, big and small
--   gear_ui.devil(s, g, cx, feet, h, look)              -- the apprentice (s.figure), wearing look
--   gear_ui.tokens(s, g, a, try, x, y0, size, gap, sh)  -- the column of what you wear
--   gear_ui.stats(s, g, x, y, w, now, after, o)         -- the column of the stats, all in one screen
--   gear_ui.stats_short(s, g, x, y, w, a, a2)           -- only the rows that change, and VEDI TUTTE
--   gear_ui.sheet(s, g, a, a2, back)                    -- all the stats, big, in the middle
--   gear_ui.loadouts(s, g, x, y, active, prefix, label) -- the three loadouts
--   gear_ui.chips(s, g, x, y, list, active)             -- a row of filters
--   gear_ui.effects(set, slot, level)                   -- "+4% IN ARIA  −2% VITA"
--   gear_ui.tried(s, a, try) / gear_ui.light_try(s, try) -- the gear with a piece tried on, lit
--   gear_ui.swap_check(s, g, gear, cx, feet, h, strong) -- a piece changed on the apprentice shows

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
local sheen = require "ui.sheen"
local coins = require "ui.coins"
local wallet = require "sim.wallet"
local TA = require("lang.text").armory
local T = require("lang.text").gear_ui

local M = {}

local KC = kit.C
M.ROMAN = { "I", "II", "III", "IV" }

-- the name of a slot in the pictures' names (WB-043)
M.ART = { mask = "elmo", chest = "corazza", cloak = "mantello", legs = "stivali", gloves = "guanti" }
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
-- e2, the change from e to e2 instead of the value ("−0,4%"; in points a
-- change below one keeps its decimal, "+0,4": a level never reads "+0")
function M.effect_parts(e, e2)
	local info = equip.STATS[e.stat]
	local name = kit.upper(TA.stats[e.stat] or e.stat)
	local function shown(x)
		if info.points then return x.good * 100 end
		return (info.less and -x.good or x.good) * 100
	end
	local v = e2 and shown(e2) - shown(e) or shown(e)
	local whole = info.points and (not e2 or math.abs(v) >= 1 or v == 0)
	local t = whole and string.format("%+d", math.floor(v + 0.5)) or string.format(info.points and "%+.1f" or "%+.1f%%", v):gsub("%.0%%", "%%"):gsub("%.", ",")
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
			local off = (lit or 0) == 0
			if off then col = kit.with_alpha(col, 0.55) end
			items[#items + 1] = { nil, kit.upper(equip.SIGNS[e.stat].name), col, off_sign = off }
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
		local over = cx > x and cx + w > x + room
		if over and it.off_sign then
			-- the signature still off never takes a line of its own: it waits until there is room
			gui.delete_node(name)
			break
		end
		if over and line < 2 then cx, line = x, line + 1 end
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
		cx = cx + w + 16
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
M.TYPE = TYPE

-- a picture inside the box (x, y, w, h), as large as it fits and centered: never stretched
local function fit(g, name, x, y, w, h)
	local m = P[name]
	local k = math.min(w / m.w, h / m.h)
	return kit.pic(g, name, x + (w - m.w * k) / 2, y + (h - m.h * k) / 2, m.w * k, m.h * k)
end

-- THE PIECE CARDS (Sergio, 27 Nov; docs/ui-catalogo.md, scopo 6): an ink frame with a band
-- in the colour of the piece's slot (M.TINT: lit on the chosen card, deeper at rest), the
-- light of ui/sheen.lua running over the band, a gold line inside when the piece is worn,
-- its level as "+24" in the top right corner (Sergio: a round badge looked like a
-- notification). The big card (ZAINO, BOTTEGA) has the piece's rows inside; the small one
-- (the players' tags, the column of what you wear) only its picture.
M.CARD_W, M.CARD_H = 284, 136
local CARD_C = 22
local ROWS_X, ROWS_PAD = 103, 23

local function mixed(c, k, white)
	return vmath.vector4(c.x * k + (1 - c.x * k) * white, c.y * k + (1 - c.y * k) * white, c.z * k + (1 - c.z * k) * white, 1)
end
-- the band's colour: lit, at rest, empty; the light that runs over it
function M.band_color(slot, lit, empty)
	local t = M.TINT[slot] or KC.SAND
	return empty and mixed(t, 0.32, 0) or lit and t or mixed(t, 0.62, 0)
end
function M.light_color(slot)
	return mixed(M.TINT[slot] or KC.SAND, 1, 0.55)
end

-- the frame in the box x, y, w, h with corners c: the dark ground, the band, its
-- light (in sh), the gold line inset `gold` when worn. Returns the band's parts
local function frame(g, x, y, w, h, c, slot, o, sh)
	kit.drawn_plate(g, "cornice_pezzo_fondo", x, y, w, h, c)
	local band = kit.drawn_plate(g, "cornice_pezzo", x, y, w, h, c)
	local col = M.band_color(slot, o.sel, o.empty)
	for _, n in ipairs(band.parts) do gui.set_color(n, col) end
	if sh and not o.empty then
		local light = kit.drawn_plate(g, "cornice_pezzo_luce", x, y, w, h, c)
		local lc = M.light_color(slot)
		for _, n in ipairs(light.parts) do sheen.add(sh, n, lc) end
	end
	if o.worn then
		local i = c * 0.68
		local ring = kit.drawn_plate(g, "anello_oro", x + i, y + i, w - 2 * i, h - 2 * i, c * 0.55)
		for _, n in ipairs(ring.parts) do gui.set_color(n, KC.HOT) end
	end
	return band
end

-- "+24": the level in the top right corner, right edge at x, baseline at y
local function level_mark(g, level, x, y, size)
	local top = level >= equip.LIVELLO_MAX
	return kit.text(g, "+" .. level, x, y, size, top and KC.HOT or KC.SAND, "end")
end

-- a row of a piece in the card: its value and the short name of its stat
function M.effect_short(e)
	local v = M.effect_parts(e)
	return v .. " " .. kit.upper(TA.stats_short[e.stat] or TA.stats[e.stat] or e.stat)
end

-- The big card at (x, y) of g. opt: set, slot, level (the +N; nil: none), form (the level
-- that picks the picture), worn, sel, lit (the signature, for the rows), sheen, and in
-- the BOTTEGA price = { cost, hot } or own (TUO), badge ("−33%"). Returns the nodes'
-- group { node, g } and the picture's node
function M.card(g, x, y, opt)
	local w, h = M.CARD_W, M.CARD_H
	local cx, cy = x + w / 2, y + h / 2
	local root = gui.new_box_node(vmath.vector3(cx - g.ox, g.oy - cy, 0), vmath.vector3(0, 0, 0))
	gui.set_visible(root, false)
	gui.set_parent(root, g.node)
	local cg = { node = root, ox = cx, oy = cy }
	local set, slot = opt.set, opt.slot
	frame(cg, x, y, w, h, CARD_C, slot, opt, opt.sheen)
	local shop = opt.price or opt.own
	local icon = fit(cg, M.icon(set, slot, opt.form or opt.level), x + 23, y + (shop and 18 or 32), 72, 72)
	if opt.level then level_mark(cg, opt.level, x + w - ROWS_PAD, y + 38, 21) end
	local room = w - ROWS_X - ROWS_PAD
	local name = kit.text(cg, equip.BY_ID[set].name, x + ROWS_X, y + 40, 20, KC.SAND)
	-- (the name leaves room to the +N)
	local nroom = room - (opt.level and 44 or 0)
	if kit.width(name) > nroom then gui.set_scale(name, gui.get_scale(name) * nroom / kit.width(name)); kit.check_small(name) end
	local ry = y + 59
	for _, e in ipairs(equip.piece(set, slot, opt.form or opt.level or 1, opt.lit)) do
		if e.row ~= "sign" then
			local n = kit.text(cg, M.effect_short(e), x + ROWS_X, ry, 16, M.ROW_COLOR[e.row] or KC.SAND)
			if kit.width(n) > room then gui.set_scale(n, gui.get_scale(n) * room / kit.width(n)); kit.check_small(n) end
			ry = ry + 17
		end
	end
	if opt.own then
		kit.text(cg, kit.upper(TA.yours), x + 59, y + 115, 17, KC.MUTE, "middle", 0.5)
	elseif opt.price then
		local num = kit.text(cg, coins.format(opt.price[1]), 0, y + 115, 18, opt.price[2] and KC.HOT or KC.SAND)
		local nw = kit.width(num)
		local left = x + 59 - (24 + nw) / 2
		kit.piece(cg, "scaglia", left + 10, y + 108, 20)
		local pos = gui.get_position(num)
		pos.x = pos.x + left + 24
		gui.set_position(num, pos)
	end
	if opt.badge then
		kit.pic(cg, "sconto", x + w - 72, y - 12, 80, 32)
		kit.text(cg, opt.badge, x + w - 32, y + 10, 18, KC.SAND, "middle")
	end
	return cg, icon
end

-- The small card s wide at (x, y) of g: the frame, the picture, the +N over its top
-- right corner. opt: set, slot, level, form, worn, sel, sheen; without a set the
-- shadow of the slot in a dim frame. Returns the group { node, ox, oy }
function M.mini(g, x, y, s, opt)
	local cx, cy = x + s / 2, y + s / 2
	local root = gui.new_box_node(vmath.vector3(cx - g.ox, g.oy - cy, 0), vmath.vector3(0, 0, 0))
	gui.set_visible(root, false)
	gui.set_parent(root, g.node)
	local cg = { node = root, ox = cx, oy = cy }
	local o = { worn = opt.worn and opt.set, sel = opt.sel, empty = not opt.set }
	local c = math.max(8, s * 0.2)
	frame(cg, x, y, s, s, c, opt.slot, o, opt.set and opt.sheen)
	if opt.set then
		cg.icon = fit(cg, M.icon(opt.set, opt.slot, opt.form or opt.level), x + s * 0.17, y + s * 0.17, s * 0.66, s * 0.66)
		if opt.level and s >= 100 then
			-- a big one (POTENZIA): inside its top right corner, as on the big card
			local size = s * 0.15
			level_mark(cg, opt.level, x + s - c * 0.75, y + c * 0.75 + size * 0.72, size)
		elseif opt.level then
			local size = math.max(kit.MIN_TEXT, s * 0.27)
			level_mark(cg, opt.level, x + s + size * 0.25, y + size * 0.3, size)
		end
	elseif M.ART[opt.slot] then
		local n = fit(cg, "vuoto_" .. M.ART[opt.slot], x + s * 0.2, y + s * 0.2, s * 0.6, s * 0.6)
		gui.set_color(n, vmath.vector4(1, 1, 1, 0.5))
	end
	return cg
end

-- The apprentice h tall, its feet at the Figma point (cx, feet), on the group g;
-- look: what it wears (a piece tried on: scoria.look_of), else the player's
function M.devil(s, g, cx, feet, h, look)
	local pose = kit.group(g, cx, feet)
	-- (the apprentice of the Figma is 380 tall at 338 / DISEGNO_H: menu/home.lua)
	local k = 338 * h / 380 / game.DISEGNO_H
	gui.set_scale(pose.node, vmath.vector3(k, k, 1))
	s.figure = scoria.new(s.colore, look or scoria.player)
	clock.sync(s.figure)
	s.st = { x = 0, y = 0, facing = 1, grounded = true, moving = 0, fermo = true }
	scoria.update(s.figure, 0, s.st)
	gui.set_parent(s.figure.root, pose.node)
	scoria.set_enabled(s.figure, true)
	s.outline = outline.new(s.figure, pose.node, look or scoria.player)
	s.pose, s.pose_k = pose, k
	return pose
end

-- the places of the gear in the drawings' categories (menu/outline.lua)
M.CAT = { mask = "elmo", chest = "corazza", cloak = "mantello", legs = "stivali", gloves = "guanti" }

-- gear (the loadout's) with the piece try = { set, slot } on instead, and the
-- look of it (a worn piece from gold on has its forged shape)
function M.tried(s, a, try)
	local gear, tiers = {}, {}
	for k, v in pairs(a.gear) do gear[k] = v end
	if try then gear[try[2]] = try[1] end
	for _, sl in ipairs(equip.SLOTS) do
		if gear[sl.id] then tiers[sl.id] = equip.tier(wallet.level(s.prof, gear[sl.id], sl.id)) end
	end
	return gear, scoria.look_of(gear, tiers)
end

-- The piece tried on is lit on the devil: its exact contour, in its slot's colour
function M.light_try(s, try)
	if not s.outline then return end
	outline.colors(s.outline, try and { [M.CAT[try[2]]] = M.TINT[try[2]] } or {})
end

-- where each place sits on the devil drawn by M.devil(s, g, cx, feet, h)
local SPOT = { mask = { -10, -330 }, chest = { 8, -200 }, cloak = { -80, -170 }, legs = { -15, -20 }, gloves = { 70, -135 } }
function M.spot(cx, feet, h, slot)
	local k, p = h / 380, SPOT[slot] or SPOT.chest
	return cx + p[1] * k, feet + p[2] * k
end

-- A piece changed on you (tried, taken off, worn): the apprentice squashes from its
-- feet and bounces back, a flash lights it, sparks in the slot's colour fly from
-- where the piece sits (Sergio, 27 Nov). strong: INDOSSA (bigger)
function M.swap_fx(s, slot, at, strong)
	local pose, k = s.pose and s.pose.node, s.pose_k
	if pose then
		gui.cancel_animations(pose, "scale")
		gui.set_scale(pose, vmath.vector3(k * 1.05, k * (strong and 0.9 or 0.93), 1))
		gui.animate(pose, "scale", vmath.vector3(k, k, 1), gui.EASING_OUTELASTIC, strong and 0.55 or 0.42)
	end
	if s.figure then s.figure.flash = (strong and 0.7 or 0.45) + 0.1 end
	if at then kit.burst_at(at, strong and 16 or 10, M.TINT[slot]) end
end

-- After a screen is built with gear on the apprentice drawn by M.devil(s, g, cx, feet, h):
-- the first place that changed since the last build (another piece, or its level)
-- shows with M.swap_fx. s.look keeps what it wore; gear nil forgets it
function M.swap_check(s, g, gear, cx, feet, h, strong)
	if not gear then s.look = nil return end
	local now = {}
	for i, slot in ipairs(M.TOKEN_ORDER) do
		now[i] = (gear[slot] or "-") .. "." .. (gear[slot] and wallet.level(s.prof, gear[slot], slot) or 0)
	end
	for i, slot in ipairs(M.TOKEN_ORDER) do
		if s.look and s.look[i] ~= now[i] then
			local x, y = M.spot(cx, feet, h, slot)
			M.swap_fx(s, slot, kit.group(g, x, y).node, strong)
			break
		end
	end
	s.look = now
end

-- The column of what you wear, beside the apprentice (Sergio, 27 Nov, choice B): one
-- small card per slot, head to feet, with the gold line of a worn piece and its +N;
-- the piece tried on sits in its place, without the gold line, and bobs. A tap on
-- one: "gettone:<slot>". Returns the small cards by slot
M.TOKEN_ORDER = { "mask", "chest", "cloak", "gloves", "legs" }
function M.tokens(s, g, a, try, x, y0, size, gap, sh)
	local made = {}
	for i, slot in ipairs(M.TOKEN_ORDER) do
		local y = y0 + (i - 1) * (size + gap)
		local set = a.gear[slot]
		local trying = try and try[2] == slot and try[1] ~= set
		if trying then set = try[1] end
		local level = set and wallet.level(s.prof, set, slot)
		local cg = M.mini(g, x, y, size, { set = set, slot = slot, level = level, worn = not trying,
			sel = trying, sheen = sh })
		if trying then
			local at = gui.get_position(cg.node)
			gui.animate(cg.node, "position.y", at.y + 4, gui.EASING_INOUTSINE, 0.5, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
		end
		if set then kit.zone(g, s.buttons, x - 4, y - 4, size + 8, size + 8, "gettone:" .. slot) end
		made[slot] = cg
	end
	return made
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
	local solid = math.min(now, type(after) == "number" and after or now)
	-- the base, then level, pieces and Sigilli above it, up to the value: one strip
	-- in the groove of every bar (kit.bar_parts), each part its color
	local v, list = b, {}
	local function seg(x1, x2, color)
		if x2 > x1 then list[#list + 1] = { x1, x2, color } end
	end
	seg(0, at(math.min(b, solid)), colors[1])
	for i = 2, 4 do
		if parts[i] > 0 then
			seg(at(math.min(v, solid)), at(math.min(v + parts[i], solid)), colors[i])
			v = v + parts[i]
		end
	end
	kit.bar_parts(g, x, y, w, h, list)
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

-- a loadout's chip: never narrower than kit.least (Sergio, 19 Nov)
local CHIP_W, CHIP_H = 84, 46

-- The three loadouts at (x, y): the label, then 1 2 3 like tabs, the active one
-- red-hot; a closed one says from which level. Tapping: "<prefix>:<i>"
function M.loadouts(s, g, x, y, active, prefix, label)
	kit.text(g, label, x, y + 14, 18, KC.MUTE, "start", 1)
	local n = 0
	for i = 1, loadout.LOADOUTS do
		local bx = x + n * (CHIP_W + 10)
		if loadout.open(i, s.prof.livello) then
			local on = i == active
			-- the number like a tab, red-hot the active one (Sergio, 23 Nov: no light plates)
			kit.hot_word(g, tostring(i), bx + CHIP_W / 2, y + 60, on, 36, 28)
			kit.zone(g, s.buttons, bx - 5, y + 18, CHIP_W + 10, CHIP_H + 12, prefix .. ":" .. i)
			n = n + 1
		else
			kit.text(g, T.loadout_locked:format(loadout.LOADOUT_LEVELS[i]), bx + 4, y + 58, 17, KC.MUTE, "start", 1)
			break
		end
	end
end

-- A row of filters from (x, y): small iron plates, the active one warm.
-- list: { { label, ui_action }, ... }
-- maxw: the room they have (the padding shrinks to stay in it, never under 20;
-- a chip is never narrower than kit.least, so the row can pass it).
-- c.slot: a chip with the symbol of that slot's type instead of words (the
-- filters of the ZAINO, Sergio 19 Nov), in the type's colour, dimmed when off
local ICON = 30
function M.chips(s, g, x, y, list, active, maxw)
	local widths = {}
	for i, c in ipairs(list) do
		if c.slot then
			widths[i] = ICON
		else
			local n = kit.text(g, c[1], 0, y + 31, 19, KC.SAND, "middle")
			widths[i] = kit.width(n)
			gui.delete_node(n)
		end
	end
	local pad, gap, size = 30, 8, 19
	local least = 48
	local function row(p, k)
		local t = gap * (#list - 1)
		for i = 1, #list do t = t + math.max(widths[i] * k + p, least) end
		return t
	end
	if maxw then
		gap = 6
		while pad > 20 and row(pad, 1) > maxw do pad = pad - 1 end
		-- still too wide: smaller words, never under the smallest text of the menus
		while size > kit.MIN_TEXT and row(pad, size / 19) > maxw do size = size - 0.5 end
	end
	local k = size / 19
	local cx = x
	for i, c in ipairs(list) do
		local on = i == active
		local w = math.max(widths[i] * k + pad, least)
		-- a thin thread around it, gold the chosen one (kit.thread_chip)
		kit.thread_chip(g, cx, y + 2, w, 44, on and KC.HOT or KC.LINE)
		if c.slot then
			local icon = fit(g, TYPE[c.slot], cx + (w - ICON) / 2, y + 24 - ICON / 2 - 2, ICON, ICON)
			local t = M.TINT[c.slot]
			gui.set_color(icon, on and t or vmath.vector4(t.x, t.y, t.z, 0.6))
		else
			kit.text(g, c[1], cx + w / 2, y + 31 - (19 - size) * 0.37, size, on and KC.HOT or KC.SAND, "middle")
		end
		kit.zone(g, s.buttons, cx - 3, y - 6, w + 6, 60, c[2])
		cx = cx + w + gap
	end
	return cx
end

return M
