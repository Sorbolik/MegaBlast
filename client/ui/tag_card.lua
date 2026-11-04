-- A player's tag (character sheet, Sergio 31 Oct): the same everywhere, in the
-- lineup before and during the weapon draft, in a match by tapping the plate,
-- in the profile ("COSÌ TI VEDONO"), in past matches. From the top: level,
-- name and three badges; the devil (if there is room); the four pieces with
-- their level and the upgrade ticks; the powers; the four stats as offset from
-- the base (bars from the center: pieces give and take, and with normal bars a
-- +4% wouldn't show); orbs, parachutes and air jumps; the tree points per
-- branch. The data is a showcase (menu/showcase.lua). Shapes and colors from
-- ui/ui.lua, the pieces from the devil's atlas.
--
--   local c = cartellino.new(v, x, y, opt, parent)  -- x, y: top center; opt: portrait, tu
--   cartellino.update(c, dt)                         -- if it has the devil, makes it breathe
--   cartellino.destroy(c)
--   cartellino.TALL(opt) / cartellino.WIDE           -- how big it is
--   cartellino.badge(b, x, y, d, parent)             -- a badge alone (STATISTICHE tab)
--   cartellino.pezzo(p, squadra, x, y, d, parent)    -- a piece alone (SCHEDA tab)

local ui = require "ui.ui"
local game = require "sim.game"
local skills = require "sim.skills"
local equip = require "sim.gear"
local skins = require "battle.skins"
local milestones = require "menu.milestones"
local showcase = require "menu.showcase"
local T = require("lang.text").tag_card
local common = require("lang.text").common

local M = {}

local C = ui.C
M.WIDE = 286
local PAD = 14
local HEAD = 52          -- level, name and badges
local PORTRAIT = 196      -- the devil
local FIGURE_H = 124      -- how tall the devil is up to the head
local PIECE, PIECE_GAP = 60, 6
local POWERS = 30
local LABEL = 18
local ROW = 21
local RESOURCES = 24
local TREE = 12
local LEGEND = 18

-- the pieces in the devil's atlas: the apprentice's (everyone's character)
-- and, for the cloak, the base wing (the apprentice has no wings)
local SKIN = skins.skins.apprendista.pieces
local PIECE_IMAGES = { mask = SKIN.testa, chest = SKIN.busto, cloak = require("battle.devil").pieces.ala, legs = SKIN.gamba }
-- the colors of the tree branches, in the order of skills.BRANCHES
local BRANCHES = { C.STEEL, C.MINT, C.BRACE }
local ABBREVIATIONS = T.branches
local ROMAN = { "I", "II", "III", "IV" }

local function vec(x, y) return vmath.vector3(x, y, 0) end
local function with_alpha(c, a) return vmath.vector4(c.x, c.y, c.z, a) end

local function box(x, y, w, h, color, parent)
	local n = gui.new_box_node(vec(x, y), vec(w, h))
	gui.set_color(n, color)
	gui.set_parent(n, parent)
	return n
end

local function txt(t, x, y, scale, color, parent, pivot)
	local n = ui.testo(t, x, y, scale, color, parent)
	if pivot then gui.set_pivot(n, pivot) end
	return n
end

local function text_width(n)
	local m = resource.get_text_metrics(gui.get_font_resource(gui.get_font(n)), gui.get_text(n))
	return m.width * gui.get_scale(n).x
end

function M.TALL(opt)
	opt = opt or {}
	return PAD + HEAD + (opt.portrait and PORTRAIT or 0) + PIECE + 10 + POWERS + LABEL + 4 * ROW
		+ RESOURCES + LABEL + TREE + LEGEND + 6
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
			n = ui.disco(0, 0, d * k, color, root_node)
		elseif s.forma == "esagono" then
			n = ui.disco(0, 0, d * k, color, root_node)
			gui.set_perimeter_vertices(n, 6)
		elseif s.forma == "stella" then
			n = ui.stella(0, 0, d * 1.15 * k, color, root_node)
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

-- A piece: the box with the tier border, the image, the level and the upgrade
-- ticks. p = { slot, set, livello, tier }
function M.pezzo(p, team, x, y, d, parent)
	local col = C.SQUADRA[team] or C.LIGHT
	local empty = not p.set
	local border_col = empty and C.LINE or p.tier >= 3 and C.GOLD or p.tier == 2 and C.STEEL
		or with_alpha(C.LIGHT, 0.5)
	local outside, border = ui.pannello(x, y, d, d, parent)
	gui.set_color(border, border_col)
	if p.tier and p.tier >= equip.TIERS and not empty then
		local a = ui.alone(0, 0, d * 1.6, with_alpha(C.GOLD, 0.35), outside)
		gui.move_below(a, border)
	end
	-- the piece's image, whole in the box
	local img = PIECE_IMAGES[p.slot]
	if img then
		local k = (d - 10) / math.max(img.w, img.h)
		local alpha = empty and 0.22 or 1
		local n = box(0, 0, img.w * k, img.h * k, with_alpha(vmath.vector4(1, 1, 1, 1), alpha), outside)
		gui.set_texture(n, "diavoletto")
		gui.play_flipbook(n, img.img)
		if img.tint then
			local t = box(0, 0, img.w * k, img.h * k, with_alpha(col, alpha), outside)
			gui.set_texture(t, "diavoletto")
			gui.play_flipbook(t, img.tint)
		end
	end
	if empty then return outside end
	-- the upgrade ticks at the top left: gold for those taken
	for i, s in ipairs(equip.TIER_LEVELS) do
		local t = box(-d / 2 + 8 + (i - 1) * 10, d / 2 - 8, 7, 7, p.livello >= s and C.GOLD or with_alpha(C.LIGHT, 0.3), outside)
		gui.set_euler(t, vmath.vector3(0, 0, 45))
	end
	-- the level at the bottom right
	local lw = p.livello >= 10 and 28 or 22
	box(d / 2 - lw / 2 + 4, -d / 2 + 4, lw + 3, 21, C.LIGHT, outside)
	box(d / 2 - lw / 2 + 4, -d / 2 + 4, lw, 18, C.BOTTOM, outside)
	txt(tostring(p.livello), d / 2 - lw / 2 + 4, -d / 2 + 4, 0.62, C.LIGHT, outside)
	return outside
end

-- A golden pill per power; sx: the left edge
-- how wide a ui.testo text is at that scale, without creating it
local function wide(t, scale)
	return resource.get_text_metrics(gui.get_font_resource(hash("titolo")), t).width * scale * 0.5
end

-- the power pills: first the shapes, then the text (so it sits on top)
local function pills(abilities, sx, y, space, parent)
	if #abilities == 0 then
		local w = wide(T.no_power, 0.58) + 16
		box(sx + w / 2, y, w + 2, 24, C.LINE, parent)
		box(sx + w / 2, y, w, 22, C.PANEL, parent)
		txt(T.no_power, sx + 8, y, 0.58, C.OFF, parent, gui.PIVOT_W)
		return
	end
	local x = sx
	for _, p in ipairs(abilities) do
		local w = wide(p, 0.58) + 16
		if x + w > sx + space then break end
		box(x + w / 2, y, w + 3, 25, C.GOLD, parent)
		box(x + w / 2, y, w, 22, C.BOTTOM, parent)
		txt(p, x + 8, y, 0.58, C.GOLD, parent, gui.PIVOT_W)
		x = x + w + 6
	end
end

function M.new(v, x, y, opt, parent)
	opt = opt or {}
	local c = { v = v }
	local W, H = M.WIDE, M.TALL(opt)
	local col = C.SQUADRA[v.squadra] or C.LIGHT
	c.alto = H
	-- the border in the team color: solid for whoever plays here
	c.root, c.bordo = ui.pannello(x, y - H / 2, W, H, parent)
	gui.set_color(c.bordo, opt.tu and col or with_alpha(col, 0.6))
	local sx, dx = -W / 2 + PAD, W / 2 - PAD
	local top = H / 2 - PAD

	-- level, name, badges
	local cy = top - HEAD / 2 + 4
	ui.ring_node(sx + 22, cy, 44, 3, col, c.root)
	if v.livello then
		txt(tostring(v.livello), sx + 22, cy - (v.torneo and 4 or 0), 0.95, col, c.root)
		if v.torneo then txt(common.tournament, sx + 22, cy + 11, 0.3, col, c.root) end
	else
		txt(v.bot and common.bot or "–", sx + 22, cy, v.bot and 0.62 or 0.95, col, c.root)
	end
	local nome = ui.titolo(v.nome or "?", sx + 52, cy + 8, 0.5, C.LIGHT, c.root)
	gui.set_pivot(nome, gui.PIVOT_W)
	txt(string.upper(v.sotto or ""), sx + 52, cy - 13, 0.52, C.OFF, c.root, gui.PIVOT_W)
	for i, b in ipairs(v.badge or {}) do
		M.badge(b, dx - 12 - (#v.badge - i) * 28, cy + 2, 25, c.root)
	end
	local yy = top - HEAD

	-- the devil
	if opt.portrait then
		local scoria = require "battle.scoria"
		-- the portrait's dark frame, with the devil inside
		box(0, yy - PORTRAIT / 2 + 2, 128, PORTRAIT - 12, with_alpha(C.BOTTOM, 0.7), c.root)
		local pose = box(0, yy - PORTRAIT + 16, 0, 0, C.LIGHT, c.root)
		gui.set_visible(pose, false)
		c.figure = scoria.new(col, scoria.PERSONAGGIO, "missile")
		-- always with the weapon in hand (as in the proposals), not its turn
		c.figure.holding_weapon, c.figure.weapon_t = true, math.huge
		c.st = { x = 0, y = 0, facing = v.verso or 1, grounded = true, moving = 0, turno = false }
		scoria.update(c.figure, 0, c.st)
		local k = FIGURE_H / game.DISEGNO_H
		gui.set_scale(pose, vmath.vector3(k, k, 1))
		ui.alone(0, 70 / k, 200 / k, with_alpha(col, 0.18), pose)
		gui.set_parent(c.figure.root, pose)
		scoria.set_enabled(c.figure, true)
		yy = yy - PORTRAIT
	end

	-- the pieces
	for i, p in ipairs(v.pezzi or {}) do
		M.pezzo(p, v.squadra, sx + PIECE / 2 + (i - 1) * (PIECE + PIECE_GAP) + 1, yy - PIECE / 2, PIECE, c.root)
	end
	yy = yy - PIECE - 10

	-- the powers
	pills(v.abilities or {}, sx, yy - POWERS / 2 + 2, W - 2 * PAD, c.root)
	yy = yy - POWERS

	-- the stats: bars from the center (the base is the same for everyone)
	txt(common.stats, sx, yy - LABEL / 2, 0.42, C.OFF, c.root, gui.PIVOT_W)
	yy = yy - LABEL
	local bx, bw = sx + 62, W - 2 * PAD - 62 - 50
	for _, r in ipairs(showcase.righe(v)) do
		local ry = yy - ROW / 2
		txt(r.nome, sx, ry, 0.62, C.TEXT, c.root, gui.PIVOT_W)
		box(bx + bw / 2, ry, bw, 10, with_alpha(C.LIGHT, 0.08), c.root)
		if r.offset ~= 0 then
			local w = math.abs(r.offset) * bw / 2
			local f = box(bx + bw / 2, ry, w, 10, r.offset > 0 and C.MINT or C.BRACE, c.root)
			gui.set_pivot(f, r.offset > 0 and gui.PIVOT_W or gui.PIVOT_E)
		end
		box(bx + bw / 2, ry, 2, 16, with_alpha(C.LIGHT, 0.7), c.root)
		txt(r.valore, dx, ry, 0.62, r.offset > 0 and C.MINT or r.offset < 0 and C.BRACE or C.TEXT, c.root, gui.PIVOT_E)
		yy = yy - ROW
	end

	-- orbs, parachutes, air jumps
	local rs = showcase.resources(v)
	local ry = yy - RESOURCES / 2 - 2
	local entries = {
		{ (rs.globi == 1 and T.orb or T.orbs):format(rs.globi), C.PURPLE },
		{ T.parachutes:format(rs.paracadute), C.MINT },
		{ T.air_jumps:format(rs.aria), C.STEEL, true },
	}
	local x = sx
	for _, vo in ipairs(entries) do
		if vo[3] then ui.ring_node(x + 6, ry, 12, 2, vo[2], c.root) else ui.disco(x + 6, ry, 12, vo[2], c.root) end
		local n = txt(vo[1], x + 16, ry, 0.6, C.TEXT, c.root, gui.PIVOT_W)
		x = x + 16 + text_width(n) + 12
	end
	yy = yy - RESOURCES

	-- the tree: twenty colored ticks per branch
	txt(T.tree:format(v.punti or skills.POINTS_MAX), sx, yy - LABEL / 2, 0.42, C.OFF, c.root, gui.PIVOT_W)
	yy = yy - LABEL
	local n, tw = skills.POINTS_MAX, (W - 2 * PAD - (skills.POINTS_MAX - 1) * 2) / skills.POINTS_MAX
	local palette = {}
	for i, punti in ipairs(v.albero or {}) do
		for _ = 1, punti do palette[#palette + 1] = BRANCHES[i] end
	end
	for i = 1, n do
		box(sx + tw / 2 + (i - 1) * (tw + 2), yy - TREE / 2, tw, 9, palette[i] or with_alpha(C.LIGHT, 0.1), c.root)
	end
	yy = yy - TREE
	local ly = yy - LEGEND / 2 - 2
	for i = 1, #BRANCHES do
		local lx = sx + (i - 1) * (W - 2 * PAD) / #BRANCHES
		box(lx + 4, ly, 8, 8, BRANCHES[i], c.root)
		txt(ABBREVIATIONS[i] .. " " .. ((v.albero or {})[i] or 0), lx + 13, ly, 0.55, C.OFF, c.root, gui.PIVOT_W)
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
