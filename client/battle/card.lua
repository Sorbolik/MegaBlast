-- The card of a new weapon, the Card (Sergio, 29 Oct; the proposals:
-- https://claude.ai/artifact/8ARwTr2xjcdXZxq7UhgnMK): in the middle of the
-- screen the icon, the name, a line on what it does, three dotted bars
-- (damage, range and one that depends on the kind) and how to use it with the
-- controls you have. It closes with PROVALA. It knows nothing about the match:
-- the battle opens it when you find a new weapon, and the weapon draft and the
-- Armory will use it too.
--
--   local c = scheda.open_view("missile", commands)     -- commands: "telefono", "computer" or "controller" (how to use it)
--   local c = scheda.open_view("missile", commands, true) -- reviewed (weapon draft): no ARMA NUOVA, closes with OK
--   if c:premi(x, y) then c:close_view() end            -- a tap: on the button? (x, y as in gui.pick_node)
--   scheda.DATI.missile                            -- what it does and the bars, for whoever shows it elsewhere

local ui = require "ui.ui"
local controller = require "ui.controller"
local hud = require "battle.hud"
local screen = require "ui.screen"

local M = {}

local C = ui.C
-- the weapon kind: the label at the top, the border color (the one of the
-- weapon bar) and the third bar
local TYPES = {
	primaria = { nome = "PRIMARIA", colore = C.BRACE, terza = "Area" },
	secondaria = { nome = "SECONDARIA", colore = C.STEEL, terza = "Spinta" },
	movimento = { nome = "MOVIMENTO", colore = C.PURPLE },
	oggetto = { nome = "OGGETTO", colore = C.MINT },
}

-- what it does, and the dots (1 to 5) for damage, range and third bar
M.DATI = {
	missile = { tipo = "primaria", cosa = "Spara una runa che esplode dove tocca: fa danno a chi è vicino e scava il terreno",
		bars = { 3, 4, 3 } },
	grenade = { tipo = "primaria", cosa = "Un uovo che rimbalza e scoppia dopo 5 secondi: cratere grande",
		bars = { 4, 3, 5 } },
	shards = { tipo = "primaria", cosa = "Una raffica di 8 schegge: rallenta chi colpisce", bars = { 3, 3, 2 } },
	punch = { tipo = "primaria", cosa = "Un montante da vicino: lancia in alto e incrina l'armatura", bars = { 4, 1, 1 } },
	sniper = { tipo = "primaria", cosa = "Parte veloce e cala a poco a poco; rimbalza e sbalza chi colpisce",
		bars = { 4, 5, 1 } },
	sword = { tipo = "secondaria", cosa = "Sempre con te: un colpo da vicino", bars = { 2, 1, 2 } },
	eagle = { tipo = "secondaria", cosa = "Un colpo dritto e subito; il rinculo ti spinge dall'altra parte",
		bars = { 3, 4, 4 } },
	mallet = { tipo = "secondaria", cosa = "Un colpo ad arco dove miri; quando sbatte su qualcosa o qualcuno rimbalzi in alto",
		bars = { 3, 1, 4 } },
	lunge = { tipo = "secondaria", cosa = "Uno scatto che passa oltre chi hai davanti e lo colpisce", bars = { 3, 2, 3 } },
	bellows = { tipo = "secondaria", cosa = "Il soffio della forgia: spinge via chi hai davanti", bars = { 1, 2, 5 } },
	hook = { tipo = "movimento", cosa = "Aggancia un bordo e ti arrampichi; su un nemico, lo tiri da te" },
	parachute = { tipo = "oggetto", cosa = "Aprilo in aria: scendi piano e atterri senza farti male", in_air = true },
	trap = { tipo = "oggetto", cosa = "Posala a terra: scatta quando ci passa un nemico" },
	shield = { tipo = "oggetto", cosa = "Ti ripara dai colpi fino al tuo prossimo turno" },
	trampoline = { tipo = "oggetto", cosa = "Posalo a terra: chi ci salta sopra vola in alto" },
}

local BAR_NAMES = { "Danno", "Gittata" }
local OFF = vmath.vector4(1, 1, 1, 0.14)
local W, H = 560, 560
local WIDE = 480

-- how to use it, with the controls you have
local function use(d, weapon_name, commands)
	local button_key = controller.name_of
	if d.tipo == "oggetto" and commands == "controller" then
		return weapon_name == "parachute" and "In aria premi " .. button_key("paracadute")
			or (d.in_air and "In aria sceglilo" or "Sceglilo") .. " fra gli OGGETTI con " .. button_key("oggetti")
			.. " e usalo con " .. button_key("usa_oggetto")
	elseif d.tipo == "oggetto" then
		return d.in_air and "In aria toccalo fra gli OGGETTI" or "Toccalo fra gli OGGETTI"
	end
	if commands == "controller" then
		return "Muovi la levetta " .. (controller.lato("mira") == "dx" and "di destra" or "di sinistra") .. " per sistemare la traiettoria, usa " .. button_key("spara") .. " per far partire il colpo"
	elseif commands == "telefono" then
		return "Sposta l'analogico di destra per sistemare la traiettoria, rilascialo per far partire il colpo"
	end
	return "Trascina dal diavoletto per sistemare la traiettoria, lascia per far partire il colpo"
end

-- a text that wraps within WIDE
local function riga(t, y, scale, color, parent)
	local n = ui.testo(t, 0, y, scale, color, parent)
	gui.set_line_break(n, true)
	gui.set_size(n, vmath.vector3(WIDE / (scale * 0.5), 200, 0))
	return n
end

function M.open_view(weapon_name, commands, reviewed)
	local d = assert(M.DATI[weapon_name], "scheda sconosciuta: " .. tostring(weapon_name))
	local kind = TYPES[d.tipo]
	local col = kind.colore
	local c = setmetatable({ arma = weapon_name }, { __index = M })
	-- the dark veil over the whole screen, and the card in the middle
	c.radice = gui.new_box_node(vmath.vector3(640, 360, 0), vmath.vector3(0, 0, 0))
	local veil = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(1280 * screen.FULL, 720 * screen.FULL, 0))
	gui.set_color(veil, vmath.vector4(0, 0, 0, 0.62))
	gui.set_parent(veil, c.radice)
	local paper, border = ui.pannello(0, 0, W, H, c.radice)
	gui.set_color(border, col)
	ui.testo(reviewed and kind.nome or "ARMA NUOVA  ·  " .. kind.nome, 0, 245, 0.8, col, paper)
	ui.alone(0, 150, 230, vmath.vector4(col.x, col.y, col.z, 0.4), paper)
	local icon_img = gui.new_box_node(vmath.vector3(0, 150, 0), vmath.vector3(130, 130, 0))
	gui.set_texture(icon_img, "armi")
	gui.play_flipbook(icon_img, weapon_name .. "_icona")
	gui.set_parent(icon_img, paper)
	ui.titolo(hud.NAMES[weapon_name] or string.upper(weapon_name), 0, 58, 0.9, C.LIGHT, paper)
	riga(d.cosa, 2, 0.9, C.TEXT, paper)
	local y = -62
	if d.bars then
		for i, v in ipairs(d.bars) do
			local nome = ui.testo(BAR_NAMES[i] or kind.terza, -190, y, 0.8, C.OFF, paper)
			gui.set_pivot(nome, gui.PIVOT_W)
			for k = 1, 5 do
				ui.disco(40 + (k - 1) * 34, y, 20, k <= v and col or OFF, paper)
			end
			y = y - 36
		end
	end
	riga(use(d, weapon_name, commands), d.bars and -188 or -110, 0.8, C.TEXT, paper)
	c.prova = ui.button({}, 0, -240, 250, 64, reviewed and "OK" or "PROVALA", nil, { main = true, colore = col }, paper)
	-- arrives with a small hop
	gui.set_scale(paper, vmath.vector3(0.6, 0.6, 1))
	gui.animate(paper, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, 0.35)
	return c
end

function M.premi(c, x, y)
	return gui.pick_node(c.prova, x, y)
end

function M.close_view(c)
	gui.delete_node(c.radice)
end

return M
