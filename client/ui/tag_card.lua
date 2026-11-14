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
--   cartellino.small(g, v, x, y, w, h, opt)          -- the short tag of the waiting room and the lineup
--                                                    -- (ui/kit.lua coordinates): update and destroy as above
--   cartellino.badge(b, x, y, d, parent)             -- a badge alone (STATISTICHE tab)
--   cartellino.pezzo(p, squadra, x, y, d, parent)    -- a piece alone (SCHEDA tab)

local ui = require "ui.ui"
local kit = require "ui.kit"
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
-- the colors of the Sigilli, in the order of skills.PATHS (as in menu/seals.lua)
local BRANCHES = { C.PURPLE, C.STEEL, C.BRACE }
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
	local n = ui.text(t, x, y, scale, color, parent)
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

-- A piece: the box with the tier border, the image, the level and the upgrade
-- ticks. p = { slot, set, livello, tier }
function M.piece(p, team, x, y, d, parent)
	local col = C.SQUADRA[team] or C.LIGHT
	local empty = not p.set
	local border_col = empty and C.LINE or p.tier >= 3 and C.GOLD or p.tier == 2 and C.STEEL
		or with_alpha(C.LIGHT, 0.5)
	-- no box around it (Sergio, 12 Nov): the piece alone, a golden glow behind the best
	local outside = box(x, y, d, d, C.LIGHT, parent)
	gui.set_visible(outside, false)
	if p.tier and p.tier >= equip.TIERS and not empty then
		ui.alone(0, 0, d * 1.6, with_alpha(C.GOLD, 0.35), outside)
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
		local t = kit.piece({ node = outside, ox = 0, oy = 0 }, "tacca", -d / 2 + 8 + (i - 1) * 11, -(d / 2 - 7), 11)
		gui.set_color(t, p.livello >= s and C.GOLD or with_alpha(C.LIGHT, 0.3))
	end
	-- the level at the bottom right
	local lw = p.livello >= 10 and 28 or 22
	txt(tostring(p.livello), d / 2 - lw / 2 + 4, -d / 2 + 6, 0.7, border_col, outside)
	return outside
end

-- A golden pill per power; sx: the left edge
-- how wide a ui.text text is at that scale, without creating it
local function wide(t, scale)
	return resource.get_text_metrics(gui.get_font_resource(hash("titolo")), t).width * scale * 0.5
end

-- the power pills: first the shapes, then the text (so it sits on top)
local function pills(abilities, sx, y, space, parent)
	if #abilities == 0 then
		local w = wide(T.no_power, 0.58) + 16
		txt(T.no_power, sx, y, 0.58, C.OFF, parent, gui.PIVOT_W)
		return
	end
	local x = sx
	for _, p in ipairs(abilities) do
		local w = wide(p, 0.58) + 16
		if x + w > sx + space then break end
		txt(p, x, y, 0.58, C.GOLD, parent, gui.PIVOT_W)
		x = x + w
	end
end

function M.new(v, x, y, opt, parent)
	opt = opt or {}
	local c = { v = v }
	local W, H = M.WIDE, M.TALL(opt)
	local col = C.SQUADRA[v.squadra] or C.LIGHT
	c.alto = H
	-- the border in the team color: solid for whoever plays here
	-- an iron panel of the kit, as big as opt.scale says (1: as in a match)
	local k = opt.scale or 1
	c.root = box(x, y - H * k / 2, W, H, C.LIGHT, parent)
	gui.set_visible(c.root, false)
	gui.set_scale(c.root, vmath.vector3(k, k, 1))
	kit.panel(c.root, W, H, opt.tu and "pannello_caldo" or "pannello")
	if opt.tu then kit.panel(c.root, W - 10, H - 10, "pannello") end
	local sx, dx = -W / 2 + PAD, W / 2 - PAD
	local top = H / 2 - PAD

	-- level, name, badges
	local cy = top - HEAD / 2 + 4
	kit.piece({ node = c.root, ox = 0, oy = 0 }, "tondo_ferro", sx + 22, -cy, 48)
	if v.livello then
		txt(tostring(v.livello), sx + 22, cy - (v.torneo and 4 or 0), 0.95, col, c.root)
		if v.torneo then txt(common.tournament, sx + 22, cy + 11, 0.3, col, c.root) end
	else
		txt(v.bot and common.bot or "–", sx + 22, cy, v.bot and 0.62 or 0.95, col, c.root)
	end
	local nome = ui.title(v.nome or "?", sx + 52, cy + 8, 0.5, C.LIGHT, c.root)
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
		M.piece(p, v.squadra, sx + PIECE / 2 + (i - 1) * (PIECE + PIECE_GAP) + 1, yy - PIECE / 2, PIECE, c.root)
	end
	yy = yy - PIECE - 10

	-- the powers
	pills(v.abilities or {}, sx, yy - POWERS / 2 + 2, W - 2 * PAD, c.root)
	yy = yy - POWERS

	-- the stats: bars from the center (the base is the same for everyone)
	txt(common.stats, sx, yy - LABEL / 2, 0.42, C.OFF, c.root, gui.PIVOT_W)
	yy = yy - LABEL
	local bx, bw = sx + 62, W - 2 * PAD - 62 - 50
	for _, r in ipairs(showcase.rows(v)) do
		local ry = yy - ROW / 2
		txt(r.nome, sx, ry, 0.62, C.TEXT, c.root, gui.PIVOT_W)
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
		if vo[3] then ui.ring_node(x + 6, ry, 12, 2, vo[2], c.root) else ui.disc(x + 6, ry, 12, vo[2], c.root) end
		local n = txt(vo[1], x + 16, ry, 0.6, C.TEXT, c.root, gui.PIVOT_W)
		x = x + 16 + text_width(n) + 12
	end
	yy = yy - RESOURCES

	-- the Sigilli: one bar of POINTS_MAX, a stretch in each path's color
	txt(T.tree:format(v.punti or skills.POINTS_MAX), sx, yy - LABEL / 2, 0.42, C.OFF, c.root, gui.PIVOT_W)
	yy = yy - LABEL
	local bw = W - 2 * PAD
	box(sx + bw / 2, yy - TREE / 2, bw, 9, with_alpha(C.LIGHT, 0.1), c.root)
	local bx = sx
	for i, punti in ipairs(v.albero or {}) do
		local w = bw * punti / skills.POINTS_MAX
		if w > 0 then
			local b = box(bx, yy - TREE / 2, w - 2, 9, BRANCHES[i] or C.LIGHT, c.root)
			gui.set_pivot(b, gui.PIVOT_W)
		end
		bx = bx + w
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

-- The short tag (waiting room, lineup): a card in the team's color with level,
-- name, the devil, the four stats as bars and what he carries. g, x, y, w, h as
-- in ui/kit.lua (top left corner). opt: color, sel, role (the line under the
-- name, else the showcase's), facing
function M.small(g, v, x, y, w, h, opt)
	opt = opt or {}
	local KC = kit.C
	local col = opt.color or C.SQUADRA[v.squadra] or KC.ROSE
	local k = kit.card(g, x, y, w, h, col, { sel = opt.sel })
	local c = { v = v, root = k.node, card = k }
	local cx, cy = x + w / 2, y + h / 2
	ui.disc(x + 48 - cx, cy - (y + 36), 38, KC.INK, k.node)
	ui.ring_node(x + 48 - cx, cy - (y + 36), 38, 3, col, k.node)
	local level = v.livello and tostring(v.livello) or v.bot and common.bot or "–"
	kit.text(k.g, level, x + 48, y + 43 - (#level > 2 and 2 or 0), #level > 2 and 11 or 18, KC.SAND, "middle")
	local name = kit.text(k.g, kit.upper(v.nome or "?"), x + 76, y + 36, 22, KC.SAND)
	local wide_name = kit.width(name)
	if wide_name > w - 106 then
		local sc = gui.get_scale(name)
		gui.set_scale(name, vec(sc.x * (w - 106) / wide_name, sc.y * (w - 106) / wide_name))
	end
	kit.text(k.g, kit.upper(opt.role or v.sotto or ""), x + 76, y + 54, 11, KC.MUTE, "start", 1.5)
	-- the devil, his feet above the bars
	local scoria = require "battle.scoria"
	local pose = box(4, cy - (y + 212), 0, 0, C.LIGHT, k.node)
	gui.set_visible(pose, false)
	c.figure = scoria.new(C.SQUADRA[v.squadra] or col, scoria.PERSONAGGIO)
	c.st = { x = 0, y = 0, facing = opt.facing or v.verso or 1, grounded = true, moving = 0, fermo = true }
	scoria.update(c.figure, 0, c.st)
	local sc = 102 / game.DISEGNO_H
	gui.set_scale(pose, vmath.vector3(sc, sc, 1))
	local ground = ui.alone(0, 0, 96 / sc, with_alpha(KC.INK, 0.6), pose)
	gui.set_scale(ground, vmath.vector3(1, 0.14, 1))
	gui.set_parent(c.figure.root, pose)
	scoria.set_enabled(c.figure, true)
	-- the stats: a bar each, the base in the middle
	local y0 = y + 226
	for i, r in ipairs(showcase.rows(v)) do
		local d = (i - 1) * 1.5
		kit.text(k.g, r.nome, x + 22 - d, y0 + (i - 1) * 17 + 9, 10, KC.MUTE, "start", 1)
		kit.bar(k.g, x + 74 - d, y0 + (i - 1) * 17, w - 118, 8, math.max(0.15, math.min(1, 0.6 + 0.4 * r.offset)),
			r.offset < 0 and KC.ROSE or KC.MINT)
	end
	local rs = showcase.resources(v)
	kit.text(k.g, kit.upper((rs.globi == 1 and T.orb or T.orbs):format(rs.globi) .. " · " .. T.parachutes:format(rs.paracadute)),
		x + 14, y + h - 14, 10, KC.SAND, "start", 1)
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
