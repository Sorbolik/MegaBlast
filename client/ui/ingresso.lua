-- La schermata d'ingresso (Sergio, 1 nov: proposta C "Fiammella"): lo sfondo
-- vivo del girone dove sei arrivato (oggi il Prologo, la Forgia:
-- gironi/forgia.fp), al centro la testa di Favilla in un disco di carta che
-- respira, sotto il nome. Resta finché il gioco non ha dal server quello che
-- serve alla home (main/game.gui_script entra), poi si dissolve.
--
--   local ingresso = require "ui.ingresso"
--   local e = ingresso.new()
--   ingresso.update(e, dt)
--   ingresso.riga(e, "Senza rete")      -- la riga sotto il nome
--   ingresso.chiudi(e, fatto)           -- dissolvenza, poi fatto() e via i nodi

local ui = require "ui.ui"
local schermo = require "ui.schermo"
local sfondo = require "gironi.sfondo"

local M = {}

local W, H = 1280, 720
local CARTA = vmath.vector4(0.94, 0.9, 0.82, 1)
-- quanto dura la dissolvenza verso la home
M.DISSOLVENZA = 0.16

local V = vmath.vector3()

local function figlio(n, parent)
	gui.set_parent(n, parent)
	gui.set_inherit_alpha(n, true)
	return n
end

function M.new()
	local e = { t = 0 }
	e.radice = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(0, 0, 0))
	gui.set_visible(e.radice, false)
	e.sfondo = sfondo.new("forgia")
	figlio(e.sfondo.nodo, e.radice)
	-- il disco: un alone di brace dietro, la carta con la testa di Favilla
	e.centro = gui.new_box_node(vmath.vector3(W / 2, H / 2 + 50, 0), vmath.vector3(0, 0, 0))
	gui.set_adjust_mode(e.centro, gui.ADJUST_FIT)
	gui.set_visible(e.centro, false)
	figlio(e.centro, e.radice)
	e.alone = figlio(ui.alone(0, 0, 520, ui.C.BRACE), e.centro)
	e.disco = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(230, 230, 0))
	gui.set_texture(e.disco, "ui")
	gui.play_flipbook(e.disco, "favilla")
	gui.set_color(e.disco, CARTA)
	figlio(e.disco, e.centro)
	local nome = figlio(ui.titolo("MEGABLAST", 0, -185, 1.2, ui.C.LUCE), e.centro)
	gui.set_adjust_mode(nome, gui.ADJUST_FIT)
	e.riga = figlio(ui.testo("", 0, -240, 0.75, ui.C.TESTO), e.centro)
	M.update(e, 0)
	return e
end

function M.update(e, dt)
	e.t = e.t + dt
	sfondo.update(e.sfondo, dt)
	-- la carta respira piano, la brace dietro pulsa
	local k = 1 + 0.025 * math.sin(e.t * 3.4)
	V.x, V.y, V.z = k, k, 1
	gui.set_scale(e.disco, V)
	local c = ui.C.BRACE
	gui.set_color(e.alone, vmath.vector4(c.x, c.y, c.z, 0.32 + 0.1 * math.sin(e.t * 2.1)))
end

function M.riga(e, testo)
	gui.set_text(e.riga, testo)
end

function M.chiudi(e, fatto)
	if e.chiusa then return end
	e.chiusa = true
	gui.animate(e.radice, "color.w", 0, gui.EASING_OUTQUAD, M.DISSOLVENZA, 0, function()
		gui.delete_node(e.radice)
		if fatto then fatto() end
	end)
end

-- subito, senza dissolvenza (gli scenari che partono già in partita)
function M.via(e)
	if e.chiusa then return end
	e.chiusa = true
	gui.delete_node(e.radice)
end

return M
