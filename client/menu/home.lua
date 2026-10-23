-- La home (menu principale), come nel concept grafica/concept/home_v1.png: sfondo
-- del cimitero dei Titani, il personaggio sullo sperone di roccia, il logo, i bottoni
-- del kit UI. Funzionano GIOCA (partita online) e STESSO TELEFONO; gli altri
-- bottoni sono le schermate che verranno, con il lucchetto.
--
-- Uso (dal gui_script, che ha le texture menu, sfondo_home e il font titoli):
--   local home = require "menu.home"
--   local h = home.new(colore)                  -- crea i nodi, nascosta
--   home.show(h) / home.hide(h)
--   home.update(h, dt)                          -- a ogni frame mentre si vede
--   local scelta = home.on_input(h, action_id, action)   -- "online", "local", "armeria", "negozio", "eventi" o nil

local game = require "sim.game"
local scoria = require "battaglia.scoria"

local M = {}

local W, H = 1280, 720
-- testo chiaro sul ferro, testo scuro sull'oro
local AVORIO = vmath.vector4(0.93, 0.87, 0.75, 1)
local BRUNO = vmath.vector4(0.17, 0.10, 0.04, 1)
local OMBRA = vmath.vector4(0.04, 0.03, 0.05, 1)
local SPENTO = vmath.vector4(0.55, 0.52, 0.50, 1)
local BRACE = vmath.vector4(1, 0.36, 0.14, 1)
local TRASPARENTE = vmath.vector4(0, 0, 0, 0)

-- bordi 9-slice dei pezzi del kit (assets/menu/kit/kit_menu.json)
local SLICE = {
	bottone_principale = 29, bottone_principale_premuto = 29,
	bottone_secondario = 20, bottone_secondario_premuto = 20,
	slot = 26, slot_bloccato = 26,
}

-- Sfondo: 2048 x 947, sullo schermo alto quanto lo schermo e tagliato ai lati
local SFONDO_W, SFONDO_H = H * 2048 / 947, H
-- piedi del personaggio sullo sperone, rispetto al centro dello sfondo
local CORPO_X, CORPO_Y = -225, -176
-- la Scoria (alta game.ROBOT_H) alta circa 180 px
local CORPO_K = 180 / game.ROBOT_H

local V = vmath.vector3()

local function vec(x, y) return vmath.vector3(x, y, 0) end

local function vuoto(x, y, parent)
	local n = gui.new_box_node(vec(x, y), vec(0, 0))
	gui.set_visible(n, false)
	if parent then gui.set_parent(n, parent) end
	return n
end

local function immagine(texture, anim, x, y, w, h, parent)
	local n = gui.new_box_node(vec(x, y), vec(w, h))
	gui.set_texture(n, texture)
	gui.play_flipbook(n, anim)
	if parent then gui.set_parent(n, parent) end
	return n
end

local function pezzo(anim, x, y, w, h, parent)
	local n = immagine("menu", anim, x, y, w, h, parent)
	local b = SLICE[anim]
	if b then gui.set_slice9(n, vmath.vector4(b, b, b, b)) end
	return n
end

local function testo(t, x, y, scala, colore, parent)
	local n = gui.new_text_node(vec(x, y), t)
	gui.set_font(n, "titoli")
	gui.set_color(n, colore or AVORIO)
	gui.set_outline(n, OMBRA)
	V.x, V.y, V.z = scala, scala, 1
	gui.set_scale(n, V)
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

local function bottone(h, nodo, tipo, azione)
	local b = { nodo = nodo, tipo = tipo, azione = azione }
	h.bottoni[#h.bottoni + 1] = b
	return b
end

local function lucchetto(x, y, d, parent)
	immagine("menu", "icona_lucchetto", x, y, d, d, parent)
end

-- bottone del kit con icona e scritta, per la colonna di sinistra
local function voce(h, parent, y, icona, nome, azione)
	local n = pezzo("bottone_secondario", 0, y, 250, 74, parent)
	immagine("menu", "icona_" .. icona, -88, 0, 58, 58, n)
	testo(nome, 18, 0, 0.5, azione and AVORIO or SPENTO, n)
	if not azione then lucchetto(100, 0, 26, n) end
	bottone(h, n, "bottone_secondario", azione or "presto")
end

-- casella quadrata con icona e scritta sotto, per la fila in basso
local function casella(h, parent, x, icona, nome, azione)
	local n = pezzo("slot", x, 0, 98, 98, parent)
	immagine("menu", "icona_" .. icona, 0, 10, 60, 60, n)
	testo(nome, 0, -34, 0.23, azione and AVORIO or SPENTO, n)
	if not azione then lucchetto(34, 34, 22, n) end
	bottone(h, n, "slot", azione or "presto")
end

function M.new(colore)
	local h = { tops = {}, bottoni = {}, t = 0, avviso_t = 0 }

	-- sfondo che copre tutto lo schermo a qualunque proporzione
	h.sfondo = immagine("sfondo_home", "home_sfondo", W / 2, H / 2, SFONDO_W, SFONDO_H)
	gui.set_adjust_mode(h.sfondo, gui.ADJUST_ZOOM)
	h.tops[#h.tops + 1] = h.sfondo

	-- il personaggio sullo sperone, si muove con lo sfondo
	h.posa = vuoto(CORPO_X, CORPO_Y, h.sfondo)
	V.x, V.y, V.z = CORPO_K, CORPO_K, 1
	gui.set_scale(h.posa, V)
	h.corpo = scoria.new(colore)
	gui.set_parent(h.corpo.root, h.posa)
	scoria.set_enabled(h.corpo, true)
	h.st = { x = 0, y = 0, facing = 1, grounded = true, moving = 0 }

	-- logo in alto a sinistra, con la brace che respira
	local alto_sx = angolo(h, 30, H - 30, gui.ANCHOR_LEFT, gui.ANCHOR_TOP)
	immagine("menu", "logo", 165, -55, 330, 107, alto_sx)
	h.logo_luce = immagine("menu", "logo_luce", 165, -55, 330, 107, alto_sx)
	gui.set_blend_mode(h.logo_luce, gui.BLEND_ADD)
	gui.set_color(h.logo_luce, BRACE)

	-- colonna di sinistra: le schermate dell'equipaggiamento (ancora chiuse)
	local sx = angolo(h, 30 + 125, H / 2 + 40, gui.ANCHOR_LEFT, gui.ANCHOR_NONE)
	voce(h, sx, 88, "armatura", "ARMERIA", "armeria")
	voce(h, sx, 0, "armi", "ARMI")
	voce(h, sx, -88, "forgia", "FORGIA")

	-- fila in basso a sinistra
	local basso = angolo(h, 30 + 49, 30 + 49, gui.ANCHOR_LEFT, gui.ANCHOR_BOTTOM)
	casella(h, basso, 0, "shop", "NEGOZIO", "negozio")
	casella(h, basso, 108, "inventario", "INVENTARIO")
	casella(h, basso, 216, "classifica", "CLASSIFICA")
	casella(h, basso, 324, "missioni", "EVENTI", "eventi")

	-- impostazioni in alto a destra
	local alto_dx = angolo(h, W - 30 - 34, H - 30 - 34, gui.ANCHOR_RIGHT, gui.ANCHOR_TOP)
	local imp = pezzo("slot", 0, 0, 68, 68, alto_dx)
	immagine("menu", "icona_impostazioni", 0, 0, 46, 46, imp)
	bottone(h, imp, "slot", "presto")

	-- in basso a destra: le partite
	local dx = angolo(h, W - 30 - 175, 30, gui.ANCHOR_RIGHT, gui.ANCHOR_BOTTOM)
	local locale = pezzo("bottone_secondario", 0, 205, 300, 80, dx)
	immagine("menu", "icona_gioca", -112, 0, 52, 52, locale)
	testo("STESSO TELEFONO", 22, 0, 0.42, AVORIO, locale)
	bottone(h, locale, "bottone_secondario", "local")

	h.gioca = pezzo("bottone_principale", 0, 72, 350, 124, dx)
	testo("GIOCA", 0, 10, 1.05, BRUNO, h.gioca)
	local sotto = testo("ONLINE", 0, -32, 0.4, BRUNO, h.gioca)
	gui.set_outline(sotto, TRASPARENTE)
	bottone(h, h.gioca, "bottone_principale", "online")

	-- avviso per i bottoni chiusi
	h.avviso = testo("", W / 2, H - 70, 0.7, AVORIO)
	gui.set_yanchor(h.avviso, gui.ANCHOR_TOP)
	h.tops[#h.tops + 1] = h.avviso

	-- velo nero che si dissolve quando la home compare
	h.velo = gui.new_box_node(vec(W / 2, H / 2), vec(W, H))
	gui.set_adjust_mode(h.velo, gui.ADJUST_STRETCH)
	gui.set_color(h.velo, vmath.vector4(0, 0, 0, 1))

	M.hide(h)
	return h
end

function M.show(h)
	for _, n in ipairs(h.tops) do gui.set_enabled(n, true) end
	gui.set_text(h.avviso, "")
	h.premuto = nil
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
	-- brace del logo e dell'oro di GIOCA: respiro lento
	gui.set_color(h.logo_luce, vmath.vector4(BRACE.x, BRACE.y, BRACE.z, 0.55 + 0.35 * math.sin(h.t * 1.7)))
	if h.avviso_t > 0 then
		h.avviso_t = h.avviso_t - dt
		if h.avviso_t <= 0 then gui.set_text(h.avviso, "") end
	end
end

local function premi(b, giu)
	local anim = b.tipo
	if giu and SLICE[b.tipo .. "_premuto"] then anim = b.tipo .. "_premuto" end
	gui.play_flipbook(b.nodo, anim)
	local s = giu and 0.96 or 1
	V.x, V.y, V.z = s, s, 1
	gui.set_scale(b.nodo, V)
end

local function sotto_dito(h, x, y)
	for _, b in ipairs(h.bottoni) do
		if gui.pick_node(b.nodo, x, y) then return b end
	end
end

function M.on_input(h, action_id, action)
	if not h.visibile or action_id ~= hash("touch") then return nil end
	if action.pressed then
		h.premuto = sotto_dito(h, action.x, action.y)
		if h.premuto then premi(h.premuto, true) end
	elseif action.released and h.premuto then
		local b = h.premuto
		h.premuto = nil
		premi(b, false)
		if sotto_dito(h, action.x, action.y) ~= b then return nil end
		if b.azione == "presto" then
			gui.set_text(h.avviso, "In arrivo")
			h.avviso_t = 1.5
			return nil
		end
		return b.azione
	end
	return nil
end

return M
