-- La home (menu principale): fondo scuro, la Scoria col bagliore del Nucleo
-- dietro, il nome del gioco e solo i bottoni che servono oggi: GIOCA (partita
-- online) e STESSO TELEFONO. Le schermate nuove aggiungono qui il loro bottone
-- quando esistono (stile in ui/ui.lua).
--
-- Uso (dal gui_script, che ha la texture ui e il font titolo):
--   local home = require "menu.home"
--   local h = home.new(colore)                  -- crea i nodi, nascosta
--   home.show(h) / home.hide(h)
--   home.update(h, dt)                          -- a ogni frame mentre si vede
--   local scelta = home.on_input(h, action_id, action)   -- "online", "local" o nil

local game = require "sim.game"
local scoria = require "battaglia.scoria"
local ui = require "ui.ui"

local M = {}

local W, H = 1280, 720
-- la Scoria (alta game.ROBOT_H) alta circa 220 px, piedi qui
local CORPO_X, CORPO_Y = 400, 200
local CORPO_K = 220 / game.ROBOT_H

local V = vmath.vector3()

local function vuoto(x, y, parent)
	local n = gui.new_box_node(vmath.vector3(x, y, 0), vmath.vector3(0, 0, 0))
	gui.set_visible(n, false)
	if parent then gui.set_parent(n, parent) end
	return n
end

-- gruppo agganciato a un bordo dello schermo
local function angolo(h, x, y, xa, ya)
	local n = vuoto(x, y)
	gui.set_xanchor(n, xa)
	gui.set_yanchor(n, ya)
	h.tops[#h.tops + 1] = n
	return n
end

function M.new(colore)
	local h = { tops = {}, bottoni = {}, t = 0, colore = colore }

	h.tops[#h.tops + 1] = ui.sfondo()

	-- il bagliore del Nucleo dietro la Scoria, che respira
	h.posa = vuoto(CORPO_X, CORPO_Y)
	h.tops[#h.tops + 1] = h.posa
	h.luce = ui.alone(0, 110, 620, colore, h.posa)
	-- un velo d'ombra sotto i piedi: il suolo che non c'è
	local suolo = ui.alone(0, 0, 260, ui.C.OMBRA, h.posa)
	gui.set_blend_mode(suolo, gui.BLEND_ALPHA)
	V.x, V.y, V.z = 1, 0.16, 1
	gui.set_scale(suolo, V)
	local corpo = vuoto(0, 0, h.posa)
	V.x, V.y, V.z = CORPO_K, CORPO_K, 1
	gui.set_scale(corpo, V)
	h.corpo = scoria.new(colore)
	gui.set_parent(h.corpo.root, corpo)
	scoria.set_enabled(h.corpo, true)
	h.st = { x = 0, y = 0, facing = 1, grounded = true, moving = 0 }

	-- il nome in alto a sinistra
	local alto_sx = angolo(h, 48, H - 56, gui.ANCHOR_LEFT, gui.ANCHOR_TOP)
	local nome = ui.titolo("MEGABLAST", 0, 0, 1.3, ui.C.LUCE, alto_sx)
	gui.set_pivot(nome, gui.PIVOT_W)

	-- in basso a destra: le partite
	local dx = angolo(h, W - 48 - 170, 48, gui.ANCHOR_RIGHT, gui.ANCHOR_BOTTOM)
	ui.bottone(h.bottoni, 0, 168, 340, 72, "STESSO TELEFONO", "local", nil, dx)
	ui.bottone(h.bottoni, 0, 60, 340, 108, "GIOCA", "online", { principale = true, colore = colore }, dx)

	-- velo nero che si dissolve quando la home compare
	h.velo = gui.new_box_node(vmath.vector3(W / 2, H / 2, 0), vmath.vector3(W, H, 0))
	gui.set_adjust_mode(h.velo, gui.ADJUST_STRETCH)
	gui.set_color(h.velo, vmath.vector4(0, 0, 0, 1))

	M.hide(h)
	return h
end

function M.show(h)
	for _, n in ipairs(h.tops) do gui.set_enabled(n, true) end
	h.bottoni.premuto = nil
	gui.set_enabled(h.velo, true)
	gui.set_color(h.velo, vmath.vector4(0, 0, 0, 1))
	gui.animate(h.velo, "color.w", 0, gui.EASING_OUTQUAD, 0.35, 0, function()
		gui.set_enabled(h.velo, false)
	end)
	h.visibile = true
end

function M.hide(h)
	for _, n in ipairs(h.tops) do gui.set_enabled(n, false) end
	gui.cancel_animations(h.velo, "color.w")
	gui.set_enabled(h.velo, false)
	h.visibile = false
end

function M.update(h, dt)
	if not h.visibile then return end
	h.t = h.t + dt
	scoria.update(h.corpo, dt, h.st)
	local c = h.colore
	gui.set_color(h.luce, vmath.vector4(c.x, c.y, c.z, 0.22 + 0.08 * math.sin(h.t * 1.7)))
end

function M.on_input(h, action_id, action)
	if not h.visibile then return nil end
	return ui.tocco(h.bottoni, action_id, action)
end

return M
