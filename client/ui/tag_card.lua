-- A player's tag (character sheet, Sergio 31 Oct): the same everywhere, in the
-- lineup before and during the weapon draft, in a match by tapping the plate,
-- in the profile ("COSÌ TI VEDONO"), in past matches. From the top: level,
-- name and three badges; the devil (if there is room); the four pieces worn,
-- each in its slot with its picture and level (the slots of the ZAINO: Sergio,
-- 16 Nov, "non fa vedere gli item che hai addosso"); the powers; the four stats
-- with the bars of the menus' stats (grey the base, mint what is above it; a
-- value under the base in red); orbs, parachutes and air jumps; the points of
-- the Sigilli per path. The data is a showcase (menu/showcase.lua). Everything
-- drawn with ui/kit.lua, no text under its smallest size.
--
--   local c = cartellino.new(v, x, y, opt, parent)  -- x, y: top center; opt: portrait, tu
--   cartellino.update(c, dt)                         -- if it has the devil, makes it breathe
--   cartellino.destroy(c)
--   cartellino.TALL(opt) / cartellino.WIDE           -- how big it is
--   cartellino.TOP(opt)                              -- the y of its top, in the middle of the screen above the thread
--   cartellino.badge(b, x, y, d, parent)             -- a badge alone

local ui = require "ui.ui"
local kit = require "ui.kit"
local game = require "sim.game"
local skills = require "sim.skills"
local milestones = require "menu.milestones"
local showcase = require "menu.showcase"
local gear_ui = require "menu.gear_ui"
local T = require("lang.text").tag_card
local common = require("lang.text").common

local M = {}

local C = ui.C
M.WIDE = 286
local PAD = 16
local HEAD = 56          -- level, name and badges
local PORTRAIT = 150      -- the devil
local FIGURE_H = 124      -- how tall the devil is up to the head
local PIECE, PIECE_GAP = 56, 10
local PIECES = PIECE + 14
local POWERS = 26
local LABEL = 24
local ROW = 30
local RESOURCES = 42
local TREE = 22 + 16 + 22
local TREE_LINE = 32      -- the Sigilli on one line (the lineup's tags)

-- the colors of the Sigilli, in the order of skills.PATHS (as in menu/backpack.lua)
local KC = kit.C
local BRANCHES = { KC.STEEL, KC.MINT, KC.HOT_BOTTOM }
local ABBREVIATIONS = T.branches
local ROMAN = { "I", "II", "III", "IV" }
-- the bars of the stats: the base, and what is above it
local BAR_COLORS = { gear_ui.PART_COLORS[1], KC.MINT }

local function vec(x, y) return vmath.vector3(x, y, 0) end
local function with_alpha(c, a) return vmath.vector4(c.x, c.y, c.z, a) end

local function box(x, y, w, h, color, parent)
	local n = gui.new_box_node(vec(x, y), vec(w, h))
	gui.set_color(n, color)
	gui.set_parent(n, parent)
	return n
end

local function txt(t, x, y, scale, color, parent, pivot)
	local n = ui.text(t, x, y, scale, color, parent)
	if pivot then gui.set_pivot(n, pivot) end
	return n
end

-- a text never wider than max (a long one shrinks)
local function fit(n, max)
	local nw = kit.width(n)
	if nw > max then gui.set_scale(n, gui.get_scale(n) * (max / nw)) end
	return n
end

-- where the top of a tag goes (y from the bottom) to stand in the middle of
-- the screen above the thread
function M.TOP(opt)
	return 417 + M.TALL(opt) / 2
end

-- how big a piece's slot is on a tag that wide
local function piece_size(W)
	return math.min(PIECE, math.floor((W - 2 * PAD - 3 * 8) / 4))
end

-- opt.portrait: true, or how tall the devil's room is; opt.wide: narrower than
-- WIDE (the slots shrink); opt.label = false: no STATISTICHE title;
-- opt.tree = "line": the Sigilli on one line, without the bar; opt.short: no
-- stats and no Sigilli (the waiting room, where there is little room);
-- opt.color: the team's color, if not the showcase's
function M.TALL(opt)
	opt = opt or {}
	local portrait = opt.portrait == true and PORTRAIT or opt.portrait or 0
	local top = PAD + HEAD + portrait + piece_size(opt.wide or M.WIDE) + 14 + POWERS
	if opt.short then return top + 4 + RESOURCES + PAD - 4 end
	return top + (opt.label == false and 4 or LABEL) + 4 * ROW
		+ RESOURCES + (opt.tree == "line" and TREE_LINE or TREE) + PAD - 4
end

-- A badge: the stat's shape in the grade's color, with the grade written inside
function M.badge(b, x, y, d, parent)
	local s = milestones.BY_ID[b.id]
	local col = C.GRADI[b.grado] or C.OFF
	local root_node = box(x, y, 0, 0, col, parent)
	gui.set_visible(root_node, false)
	local function shape(k, color)
		local n
		if s.forma == "cerchio" then
			n = ui.disc(0, 0, d * k, color, root_node)
		elseif s.forma == "esagono" then
			n = ui.disc(0, 0, d * k, color, root_node)
			gui.set_perimeter_vertices(n, 6)
		elseif s.forma == "stella" then
			n = ui.star(0, 0, d * 1.15 * k, color, root_node)
		else
			n = box(0, 0, d * 0.72 * k, d * 0.72 * k, color, root_node)
			gui.set_euler(n, vmath.vector3(0, 0, 45))
		end
		return n
	end
	shape(1, col)
	shape(0.74, with_alpha(C.BOTTOM, 0.9))
	txt(ROMAN[b.grado] or "", 0, 0, d / 52, col, root_node)
	return root_node
end

function M.new(v, x, y, opt, parent)
	opt = opt or {}
	local c = { v = v }
	local W, H = opt.wide or M.WIDE, M.TALL(opt)
	local col = opt.color or C.SQUADRA[v.squadra] or C.LIGHT
	c.alto = H
	-- an iron panel of the kit (warm for whoever plays here), as big as
	-- opt.scale says (1: as in a match)
	local k = opt.scale or 1
	c.root = box(x, y - H * k / 2, W, H, C.LIGHT, parent)
	gui.set_visible(c.root, false)
	gui.set_scale(c.root, vmath.vector3(k, k, 1))
	kit.panel(c.root, W, H, opt.tu and "pannello_caldo" or "pannello")
	if opt.tu then kit.panel(c.root, W - 10, H - 10, "pannello") end
	-- the kit's coordinates on the card: x from its left, y from its top
	local g = { node = c.root, ox = W / 2, oy = H / 2 }
	local sx, wide = PAD, W - 2 * PAD
	local yy = PAD

	-- level, name, badges
	kit.piece(g, "tondo_ferro", sx + 24, yy + 26, 48)
	local level = v.livello and tostring(v.livello) or v.bot and common.bot or "–"
	fit(kit.text(g, level, sx + 24, yy + 33, 20, col, "middle"), 34)
	local badges = #(v.badge or {})
	fit(kit.text(g, v.nome or "?", sx + 56, yy + 24, 22, KC.SAND), wide - 56 - badges * 28 - (badges > 0 and 6 or 0))
	fit(kit.text(g, kit.upper(v.torneo and common.tournament or v.sotto or ""), sx + 56, yy + 45, 16, KC.MUTE, "start", 0.5), wide - 56)
	for i, b in ipairs(v.badge or {}) do
		M.badge(b, W / 2 - PAD - 12 - (badges - i) * 28, H / 2 - (yy + 18), 25, c.root)
	end
	yy = yy + HEAD

	-- the devil
	if opt.portrait then
		local scoria = require "battle.scoria"
		local room = opt.portrait == true and PORTRAIT or opt.portrait
		local pose = box(0, H / 2 - (yy + room - 10), 0, 0, C.LIGHT, c.root)
		gui.set_visible(pose, false)
		-- with the pieces he wears on (the forged shape from the upgrade tier 3)
		local gear, tiers = {}, {}
		for _, p in ipairs(v.pezzi or {}) do gear[p.slot], tiers[p.slot] = p.set, p.tier end
		c.figure = scoria.new(col, scoria.look_of(gear, tiers), "missile")
		-- always with the weapon in hand (as in the proposals), not its turn
		c.figure.holding_weapon, c.figure.weapon_t = true, math.huge
		c.st = { x = 0, y = 0, facing = v.verso or 1, grounded = true, moving = 0, turno = false }
		scoria.update(c.figure, 0, c.st)
		local fk = FIGURE_H * room / PORTRAIT / game.DISEGNO_H
		gui.set_scale(pose, vmath.vector3(fk, fk, 1))
		ui.alone(0, 70 / fk, 200 / fk, with_alpha(col, 0.18), pose)
		gui.set_parent(c.figure.root, pose)
		scoria.set_enabled(c.figure, true)
		yy = yy + room
	end

	-- the pieces worn: the slots of the ZAINO, each with its picture and level
	-- (an empty slot: the shadow of what goes there)
	local ps = piece_size(W)
	local pgap = (wide - 4 * ps) / 3
	for i, p in ipairs(v.pezzi or {}) do
		gear_ui.slot(g, sx + (i - 1) * (ps + pgap), yy, ps,
			{ set = p.set, slot = p.slot, level = p.set and p.livello or nil })
	end
	yy = yy + ps + 14

	-- the powers, as many as stay in the line
	local powers = v.abilities or {}
	if #powers == 0 then
		kit.text(g, kit.upper(T.no_power), sx, yy + 16, 16, KC.MUTE, "start", 0.5)
	else
		local line, shown = "", 0
		for i, pw in ipairs(powers) do
			local try = (i > 1 and line .. " · " or "") .. kit.upper(pw)
			local n = kit.text(g, try .. (i < #powers and " +" .. (#powers - i) or ""), 0, 0, 16, KC.HOT, "start", 0.5)
			local fits = kit.width(n) <= wide
			gui.delete_node(n)
			if not fits and i > 1 then break end
			line, shown = try, i
		end
		if shown < #powers then line = line .. " +" .. (#powers - shown) end
		fit(kit.text(g, line, sx, yy + 16, 16, KC.HOT, "start", 0.5), wide)
	end
	yy = yy + POWERS

	-- the stats, with the bars of the menus: the base, what is above it in mint;
	-- a value under the base in red
	if opt.short or opt.label == false then
		yy = yy + 4
	else
		kit.text(g, common.stats, sx, yy + 16, 18, KC.HOT, "start", 1)
		yy = yy + LABEL
	end
	local base = game.base_stats()
	for i, r in ipairs(opt.short and {} or showcase.rows(v, base)) do
		local key = showcase.BARS[i][1]
		local now, b = v.stats[key] or base[key], base[key]
		kit.text(g, r.nome, sx, yy + 14, 16, KC.SAND, "start", 0.5)
		kit.text(g, r.valore, sx + wide, yy + 14, 18, r.offset > 0 and KC.MINT or r.offset < 0 and KC.RED or KC.SAND, "end")
		gear_ui.bar(g, sx, yy + 19, wide, 8, { b, math.max(0, now - b), 0, 0 }, now, nil, key, BAR_COLORS)
		yy = yy + ROW
	end

	-- orbs, parachutes, air jumps: three numbers, each over its name
	local rs = showcase.resources(v)
	local entries = {
		{ rs.globi, (rs.globi == 1 and T.orb or T.orbs):format(""), KC.PURPLE },
		{ rs.paracadute, T.parachutes:format(""), KC.MINT },
		{ rs.aria, T.air_jumps:format(""), KC.STEEL },
	}
	for i, e in ipairs(entries) do
		local cx = sx + (i - 0.5) * wide / #entries
		kit.text(g, tostring(e[1]), cx, yy + 20, 20, e[3], "middle")
		fit(kit.text(g, kit.upper((e[2]:gsub("^%s+", ""))), cx, yy + 38, 16, KC.MUTE, "middle", 0.3), wide / #entries - 6)
	end
	yy = yy + RESOURCES
	if opt.short then return c end

	-- the Sigilli: one bar of POINTS_MAX, a stretch in each path's color
	if opt.tree == "line" then
		yy = yy - 10
	else
		kit.text(g, T.tree:format(v.punti or skills.POINTS_MAX), sx, yy + 16, 16, KC.MUTE, "start", 0.5)
		yy = yy + 22
		kit.rect(g, sx - 2, yy - 2, wide + 4, 14, KC.INK)
		kit.rect(g, sx, yy, wide, 10, KC.TRACK)
		local bx = sx
		for i, punti in ipairs(v.albero or {}) do
			local w = wide * punti / skills.POINTS_MAX
			if w > 0 then
				kit.rect(g, bx, yy, w, 10, BRANCHES[i] or KC.SAND)
				kit.rect(g, bx + w - 1, yy, 2, 10, KC.INK)
			end
			bx = bx + w
		end
	end
	yy = yy + 16
	for i = 1, #BRANCHES do
		local lx = sx + (i - 1) * wide / #BRANCHES
		kit.rect(g, lx, yy + 4, 12, 12, KC.INK)
		kit.rect(g, lx + 2, yy + 6, 8, 8, BRANCHES[i])
		kit.text(g, ABBREVIATIONS[i] .. " " .. ((v.albero or {})[i] or 0), lx + 18, yy + 16, 16, KC.MUTE, "start", 0.3)
	end
	return c
end

function M.update(c, dt)
	if c.figure then
		require("battle.scoria").update(c.figure, dt, c.st)
	end
end

function M.destroy(c)
	if c.root then gui.delete_node(c.root) end
	c.root = nil
end

return M
