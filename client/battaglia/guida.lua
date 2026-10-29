-- La guida delle lezioni (sim/missioni.lua, evidenzia): un anello giallo che
-- pulsa sul comando da toccare e, per i gesti, un dito che li fa. Sul telefono
-- il dito sposta di lato la levetta di sinistra (cammina) o la spinge in su
-- (salta), spinge la levetta di destra verso il bersaglio (mira) o tocca la
-- metà destra dello schermo mentre si mira (annulla); sul computer pulsano i
-- tasti (A D, SPAZIO). Pochi nodi fatti una volta: a ogni frame si spostano soltanto.
--
--   local gd = guida.new()                          -- dopo l'HUD, così sta sopra
--   guida.aggiorna(gd, cosa, dove, telefono, pads)  -- a ogni frame; cosa nil: niente
--   guida.gesto(cosa)                               -- un gesto (salta, mira...), non un pulsante
--     dove = { x, y, d }: il comando da cerchiare (o nil); pads = { muovi, mira }:
--     i centri delle levette; telefono: i gesti col dito, se no i tasti

local ui = require "ui.ui"

local M = {}

local GIALLO = vmath.vector4(1, 0.82, 0.25, 1)
local DITO = vmath.vector4(1, 1, 1, 0.9)
local ONDA = vmath.vector4(1, 1, 1, 0.85)
-- quanto va il dito sulla levetta, e dove tocca per annullare
local CORSA = 95
local ANNULLA = { x = 960, y = 400 }
-- i gesti col dito: su quale levetta, verso dove, e la freccia
local GESTI = {
	cammina = { pad = "muovi", dx = 1, dy = 0, freccia = ">" },
	salta = { pad = "muovi", dx = 0, dy = 1, freccia = "^" },
	mira = { pad = "mira", dx = 0.7, dy = 0.7 },
}
-- sul computer i tasti
local TASTI = { cammina = "A   D", salta = "SPAZIO" }
local V = vmath.vector3(0, 0, 0)

local function pos(n, x, y)
	V.x, V.y, V.z = x, y, 0
	gui.set_position(n, V)
end

function M.new()
	local gd = { cosa = nil }
	gd.anello = ui.anello(0, 0, 100, 7, GIALLO)
	gd.dito = ui.disco(0, 0, 48, DITO)
	gd.onda = ui.anello(0, 0, 48, 5, ONDA)
	gd.freccia = ui.titolo("^", 0, 0, 1.6, GIALLO)
	gd.tasto = ui.pannello(0, 0, 170, 58)
	gd.tasto_scritta = ui.titolo("", 0, 2, 0.75, ui.C.LUCE, gd.tasto)
	for _, n in ipairs({ gd.anello, gd.dito, gd.onda, gd.freccia, gd.tasto }) do gui.set_enabled(n, false) end
	return gd
end

-- Riparte il giro delle animazioni: cambia solo quando cambia il comando
local function anima(gd, cosa, telefono, pads)
	for _, n in ipairs({ gd.anello, gd.dito, gd.onda, gd.freccia, gd.tasto }) do
		gui.cancel_animations(n)
		gui.set_scale(n, vmath.vector3(1, 1, 1))
	end
	gui.animate(gd.anello, "scale", vmath.vector3(1.22, 1.22, 1), gui.EASING_INOUTSINE, 0.55, 0, nil,
		gui.PLAYBACK_LOOP_PINGPONG)
	gui.set_color(gd.dito, DITO)
	gui.set_color(gd.onda, ONDA)
	local gesto = GESTI[cosa]
	if gesto and telefono then
		-- il dito parte dal centro della levetta e va verso il gesto, a giro
		local p = pads[gesto.pad]
		local x, y = p.x + gesto.dx * CORSA, p.y + gesto.dy * CORSA
		pos(gd.dito, p.x, p.y)
		gui.animate(gd.dito, "position", vmath.vector3(x, y, 0), gui.EASING_OUTQUAD, 0.8, 0.2, nil,
			gui.PLAYBACK_LOOP_FORWARD)
		gui.animate(gd.dito, "color.w", 0, gui.EASING_INQUAD, 0.8, 0.2, nil, gui.PLAYBACK_LOOP_FORWARD)
		if gesto.freccia then
			gui.set_text(gd.freccia, gesto.freccia)
			pos(gd.freccia, x + gesto.dx * 40, y + gesto.dy * 40)
			gui.animate(gd.freccia, "scale", vmath.vector3(1.3, 1.3, 1), gui.EASING_INOUTSINE, 0.5, 0, nil,
				gui.PLAYBACK_LOOP_PINGPONG)
		end
	elseif cosa == "annulla" and telefono then
		-- un tocco sulla metà destra: il dito e l'onda che si allarga
		pos(gd.dito, ANNULLA.x, ANNULLA.y)
		pos(gd.onda, ANNULLA.x, ANNULLA.y)
		gui.animate(gd.onda, "scale", vmath.vector3(2.6, 2.6, 1), gui.EASING_OUTQUAD, 0.9, 0, nil,
			gui.PLAYBACK_LOOP_FORWARD)
		gui.animate(gd.onda, "color.w", 0, gui.EASING_OUTQUAD, 0.9, 0, nil, gui.PLAYBACK_LOOP_FORWARD)
	elseif TASTI[cosa] then
		gui.set_text(gd.tasto_scritta, TASTI[cosa])
		pos(gd.tasto, pads.muovi.x, pads.muovi.y)
		gui.animate(gd.tasto, "scale", vmath.vector3(1.12, 1.12, 1), gui.EASING_INOUTSINE, 0.45, 0, nil,
			gui.PLAYBACK_LOOP_PINGPONG)
	end
end

-- È un gesto (o un tasto), non un pulsante da cerchiare?
function M.gesto(cosa)
	return GESTI[cosa] ~= nil or cosa == "annulla"
end

function M.aggiorna(gd, cosa, dove, telefono, pads)
	local chiave = cosa and (cosa .. (telefono and "t" or "c")) or nil
	if chiave ~= gd.cosa then
		gd.cosa = chiave
		local gesto = GESTI[cosa]
		gui.set_enabled(gd.dito, telefono and (gesto ~= nil or cosa == "annulla"))
		gui.set_enabled(gd.onda, cosa == "annulla" and telefono)
		gui.set_enabled(gd.freccia, telefono and gesto ~= nil and gesto.freccia ~= nil)
		gui.set_enabled(gd.tasto, not telefono and TASTI[cosa] ~= nil)
		if cosa then anima(gd, cosa, telefono, pads) end
	end
	gui.set_enabled(gd.anello, dove ~= nil)
	if dove then
		pos(gd.anello, dove.x, dove.y)
		local d = dove.d + 26
		V.x, V.y, V.z = d, d, 0
		gui.set_size(gd.anello, V)
		gui.set_inner_radius(gd.anello, d / 2 - 7)
	end
end

return M
