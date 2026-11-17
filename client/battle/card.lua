-- The card of a new weapon, the Card (Sergio, 29 Oct; the proposals:
-- https://claude.ai/artifact/8ARwTr2xjcdXZxq7UhgnMK): in the middle of the
-- screen the icon, the name, a line on what it does, three dotted bars
-- (damage, range and one that depends on the kind) and how to use it with the
-- controls you have. It closes with OK. It knows nothing about the match: the
-- weapon draft opens it (in battle a weapon found no longer has its card:
-- Sergio, 4 Nov, its icon flies to its button), and the Armory will use it too.
--
--   local c = scheda.open_view("missile", commands)     -- commands: "telefono", "computer" or "controller" (how to use it)
--   if c:press(x, y) then c:close_view() end            -- a tap: on the button? (x, y as in gui.pick_node)
--   scheda.DATI.missile                            -- the kind and the bars, for whoever shows it elsewhere (what it does: lang/it.lua card.what)

local ui = require "ui.ui"
local kit = require "ui.kit"
local controller = require "ui.controller"
local hud = require "battle.hud"
local screen = require "ui.screen"
local T = require("lang.text").card
local common = require("lang.text").common

local M = {}

local C = ui.C
-- the weapon kind: the label at the top, its color (the one of the
-- weapon bar) and the third bar
local TYPES = {
	primaria = { nome = T.kinds.primaria, colore = C.BRACE, terza = T.third_bar.primaria },
	secondaria = { nome = T.kinds.secondaria, colore = C.STEEL, terza = T.third_bar.secondaria },
	movimento = { nome = T.kinds.movimento, colore = C.PURPLE },
	oggetto = { nome = T.kinds.oggetto, colore = C.MINT },
}

-- the kind, and the dots (1 to 5) for damage, range and third bar
M.DATI = {
	missile = { tipo = "primaria", bars = { 3, 4, 3 } },
	grenade = { tipo = "primaria", bars = { 4, 3, 5 } },
	shards = { tipo = "primaria", bars = { 3, 3, 2 } },
	punch = { tipo = "primaria", bars = { 4, 1, 1 } },
	sniper = { tipo = "primaria", bars = { 4, 5, 1 } },
	sword = { tipo = "secondaria", bars = { 2, 1, 2 } },
	eagle = { tipo = "secondaria", bars = { 3, 4, 4 } },
	mallet = { tipo = "secondaria", bars = { 3, 1, 4 } },
	lunge = { tipo = "secondaria", bars = { 3, 2, 3 } },
	bellows = { tipo = "secondaria", bars = { 1, 2, 5 } },
	boomerang = { tipo = "primaria", bars = { 3, 3, 3 } },
	tar = { tipo = "primaria", bars = { 2, 3, 5 } },
	drill = { tipo = "primaria", bars = { 3, 3, 2 } },
	vortex = { tipo = "secondaria", bars = { 2, 4, 4 } },
	cannon = { tipo = "secondaria", bars = { 3, 5, 5 } },
	petard = { tipo = "secondaria", bars = { 1, 3, 5 } },
	hook = { tipo = "movimento" },
	parachute = { tipo = "oggetto", in_air = true },
	trap = { tipo = "oggetto" },
	shield = { tipo = "oggetto" },
	trampoline = { tipo = "oggetto" },
}

local BAR_NAMES = T.bars
local OFF = vmath.vector4(1, 1, 1, 0.14)
local W, H = 560, 600
local WIDE = 480
-- the OK button: its size and its middle, from the card's middle
local OK_W, OK_H, OK_Y = 230, 64, -246

-- how to use it, with the controls you have
local function use(d, weapon_name, commands)
	local button_key = controller.name_of
	if d.tipo == "oggetto" and commands == "controller" then
		return weapon_name == "parachute" and T.parachute_pad:format(button_key("paracadute"))
			or (d.in_air and T.item_pad_air or T.item_pad):format(button_key("oggetti"), button_key("usa_oggetto"))
	elseif d.tipo == "oggetto" then
		return d.in_air and T.item_touch_air or T.item_touch
	end
	if commands == "controller" then
		return T.aim_pad:format(controller.side("mira") == "dx" and common.stick_side.dx or common.stick_side.sx, button_key("spara"))
	elseif commands == "telefono" then
		return T.aim_phone
	end
	return T.aim_computer
end

-- a text that wraps within WIDE
local function riga(t, y, scale, color, parent)
	local n = ui.text(t, 0, y, scale, color, parent)
	gui.set_line_break(n, true)
	gui.set_size(n, vmath.vector3(WIDE / (scale * 0.5), 200, 0))
	return n
end

function M.open_view(weapon_name, commands)
	local d = assert(M.DATI[weapon_name], "scheda sconosciuta: " .. tostring(weapon_name))
	local kind = TYPES[d.tipo]
	local col = kind.colore
	local c = setmetatable({ arma = weapon_name }, { __index = M })
	-- the dark veil over the whole screen, and the card in the middle
	c.radice = gui.new_box_node(vmath.vector3(640, 360, 0), vmath.vector3(0, 0, 0))
	local veil = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(1280 * screen.FULL, 720 * screen.FULL, 0))
	gui.set_color(veil, vmath.vector4(0, 0, 0, 0.62))
	gui.set_parent(veil, c.radice)
	-- the iron panel of the menus, with its ink outline (ui/kit.lua; Sergio, 17 Nov)
	local paper = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(W, H, 0))
	gui.set_visible(paper, false)
	gui.set_parent(paper, c.radice)
	kit.panel(paper, W, H)
	ui.text(kind.nome, 0, 258, 0.8, col, paper)
	ui.alone(0, 162, 230, vmath.vector4(col.x, col.y, col.z, 0.4), paper)
	local icon_img = gui.new_box_node(vmath.vector3(0, 162, 0), vmath.vector3(130, 130, 0))
	gui.set_texture(icon_img, "armi")
	gui.play_flipbook(icon_img, weapon_name .. "_icona")
	gui.set_parent(icon_img, paper)
	ui.title(hud.NAMES[weapon_name] or string.upper(weapon_name), 0, 70, 0.9, C.LIGHT, paper)
	riga(T.what[weapon_name], 14, 0.9, C.TEXT, paper)
	local y = -50
	if d.bars then
		for i, v in ipairs(d.bars) do
			local nome = ui.text(BAR_NAMES[i] or kind.terza, -190, y, 0.8, C.OFF, paper)
			gui.set_pivot(nome, gui.PIVOT_W)
			for k = 1, 5 do
				ui.disc(40 + (k - 1) * 34, y, 20, k <= v and col or OFF, paper)
			end
			y = y - 36
		end
	end
	-- how to use it: its two lines end well above the button
	riga(use(d, weapon_name, commands), d.bars and -172 or -100, 0.8, C.TEXT, paper)
	-- OK is the primary button of the menus, the gem
	c.ok = kit.action({ node = paper, ox = 0, oy = 0 }, T.ok, -OK_W / 2, -OK_Y - OK_H / 2, OK_W, OK_H, { size = 30 })
	-- arrives with a small hop
	gui.set_scale(paper, vmath.vector3(0.6, 0.6, 1))
	gui.animate(paper, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, 0.35)
	return c
end

function M.press(c, x, y)
	return gui.pick_node(c.ok.node, x, y)
end

function M.close_view(c)
	gui.delete_node(c.radice)
end

return M
