-- Interfaccia minimale di MegaBlast, nello stile della Scoria: forme piatte color
-- carbone col bordo chiaro (come il contorno del personaggio) e il bagliore del
-- Nucleo, nel colore della squadra, su quello che conta. Niente immagini dipinte:
-- poche forme bianche (assets/ui/, strumenti/grafica/ui.py) colorate da qui.
-- I pezzi si aggiungono solo quando una schermata ne ha bisogno.
--
-- Il .gui che lo usa deve avere la texture "ui" (/ui/ui.atlas) e il font
-- "titolo" (/ui/titolo.font). Per cambiare stile si cambiano i valori qui.
--
--   local ui = require "ui.ui"
--   local lista = {}                                   -- i bottoni di una schermata
--   ui.bottone(lista, x, y, w, h, "GIOCA", "online", { principale = true }, parent)
--   local azione = ui.tocco(lista, action_id, action)  -- in on_input: l'azione o nil
--   (anche col controller: action_id ui.PAD, action.ui "su" "giu" "sinistra"
--   "destra" spostano la luce sui bottoni, "conferma" e "indietro" li usano;
--   ui/controller.lua)

local schermo = require "ui.schermo"

local M = {}

local function c(r, g, b, a) return vmath.vector4(r, g, b, a or 1) end

-- Palette: dal personaggio (scoria.lua) e dalla bibbia grafica
M.C = {
	FONDO = c(0.051, 0.047, 0.063),       -- quasi nero, il buio del cimitero
	PANNELLO = c(0.078, 0.071, 0.094),    -- il carbone della Scoria
	LINEA = c(1, 0.886, 0.769, 0.28),     -- bordo dei pezzi a riposo
	LUCE = c(1, 0.886, 0.769),            -- il contorno chiaro della Scoria
	TESTO = c(0.95, 0.91, 0.85),
	SPENTO = c(0.55, 0.52, 0.52),
	BRACE = c(1, 0.42, 0.16),             -- accento quando non c'è una squadra; colore delle armi primarie
	ACCIAIO = c(0.62, 0.77, 0.88),        -- colore delle armi secondarie (danno secco, ti muovono)
	VIOLA = c(0.77, 0.61, 1),             -- il movimento: teletrasporto e Rampino
	MENTA = c(0.36, 0.86, 0.72),          -- gli oggetti che si consumano: paracadute, trappola, scudo, trampolino
	OMBRA = c(0, 0, 0, 0.6),
	SQUADRA = { c(1, 0.231, 0.306), c(0.239, 0.482, 1), c(0.18, 0.75, 0.44), c(0.96, 0.77, 0.09) },
}
local C = M.C

local BORDO_9 = vmath.vector4(16, 16, 16, 16)
-- le forme che si allungano in 9-slice (le altre si scalano intere)
local NOVE = { forma = true, bordo = true }
local V = vmath.vector3()
local PREMUTO, NORMALE = vmath.vector3(0.96, 0.96, 1), vmath.vector3(1, 1, 1)

local function vec(x, y) return vmath.vector3(x, y, 0) end

local function nodo(tex, x, y, w, h, colore, parent)
	local n = gui.new_box_node(vec(x, y), vec(w, h))
	if tex then
		gui.set_texture(n, "ui")
		gui.play_flipbook(n, tex)
		if NOVE[tex] then gui.set_slice9(n, BORDO_9) end
	end
	gui.set_color(n, colore)
	if parent then gui.set_parent(n, parent) end
	return n
end

local function scrivi(font, t, x, y, scala, colore, parent)
	local n = gui.new_text_node(vec(x, y), t)
	gui.set_font(n, font)
	gui.set_color(n, colore or C.TESTO)
	gui.set_outline(n, C.OMBRA)
	V.x, V.y, V.z = scala or 1, scala or 1, 1
	gui.set_scale(n, V)
	if parent then gui.set_parent(n, parent) end
	return n
end

-- Testo normale e titolo (oggi lo stesso font, più grande)
function M.testo(t, x, y, scala, colore, parent)
	return scrivi("titolo", t, x, y, (scala or 1) * 0.5, colore, parent)
end

function M.titolo(t, x, y, scala, colore, parent)
	return scrivi("titolo", t, x, y, scala or 1, colore or C.LUCE, parent)
end

-- Alone morbido in additivo: il bagliore del Nucleo e dell'occhio
function M.alone(x, y, d, colore, parent)
	local n = nodo("alone", x, y, d, d, colore, parent)
	gui.set_blend_mode(n, gui.BLEND_ADD)
	return n
end

-- Fondo pieno a tutto schermo, su ogni proporzione (ui/schermo.lua)
function M.sfondo(parent)
	local n = nodo(nil, 640, 360, 1280 * schermo.PIENO, 720 * schermo.PIENO, C.FONDO, parent)
	gui.set_adjust_mode(n, gui.ADJUST_FIT)
	return n
end

-- Pannello: carbone col bordo chiaro appena accennato. Rende anche il nodo del
-- bordo, per accenderlo (C.LUCE) quando il pannello è scelto
function M.pannello(x, y, w, h, parent)
	local n = nodo("forma", x, y, w, h, C.PANNELLO, parent)
	return n, nodo("bordo", 0, 0, w, h, C.LINEA, n)
end

-- Bottone. opz: principale (bordo pieno e Nucleo acceso), colore (del Nucleo,
-- di solito la squadra), spento (si vede ma non risponde)
function M.bottone(lista, x, y, w, h, scritta, azione, opz, parent)
	opz = opz or {}
	local n = nodo("forma", x, y, w, h, C.PANNELLO, parent)
	local col = opz.colore or C.BRACE
	local b = { nodo = n, azione = azione, spento = opz.spento, colore = col }
	b.bordo = nodo("bordo", 0, 0, w, h, opz.principale and C.LUCE or C.LINEA, n)
	b.riposo = gui.get_color(b.bordo)
	local tx = 0
	if opz.principale and not opz.spento then
		-- il Nucleo: un punto acceso con il suo alone, a sinistra della scritta
		local r = h * 0.5
		b.luce = M.alone(-w / 2 + r, 0, h * 1.1, vmath.vector4(col.x, col.y, col.z, 0.55), n)
		M.alone(-w / 2 + r, 0, h * 0.34, vmath.vector4((1 + col.x) / 2, (1 + col.y) / 2, (1 + col.z) / 2, 1), n)
		M.alone(-w / 2 + r, 0, h * 0.18, C.LUCE, n)
		tx = h * 0.3
	end
	b.testo = M.testo(scritta, tx, 0, opz.scala or (h >= 90 and 1.6 or 0.9),
		opz.spento and C.SPENTO or C.TESTO, n)
	lista[#lista + 1] = b
	return n
end

-- Scheda: come un bottone, l'attiva ha il bordo chiaro e il testo acceso
function M.scheda(lista, x, y, w, h, scritta, azione, attiva, parent)
	local n = M.bottone(lista, x, y, w, h, scritta, azione, nil, parent)
	M.scheda_attiva(lista[#lista], attiva)
	return n
end

function M.scheda_attiva(b, attiva)
	b.riposo = attiva and C.LUCE or C.LINEA
	gui.set_color(b.bordo, b.riposo)
	gui.set_color(b.testo, attiva and C.TESTO or C.SPENTO)
end

-- Indietro: quadrato con la freccia, agganciato in alto a sinistra
function M.indietro(lista, azione, parent)
	local n = M.bottone(lista, 30 + 32, 720 - 30 - 32, 64, 64, "", azione, nil, parent)
	gui.set_xanchor(n, gui.ANCHOR_LEFT)
	gui.set_yanchor(n, gui.ANCHOR_TOP)
	for i = -1, 1, 2 do
		local s = nodo(nil, -2, i * 7, 22, 4, C.LUCE, n)
		gui.set_rotation(s, vmath.vector3(0, 0, i * 45))
	end
	return n
end

-- Impostazioni in partita: lo stesso quadrato con la rotellina, in alto a sinistra
function M.impostazioni(lista, azione, parent)
	local n = M.bottone(lista, 30 + 32, 720 - 30 - 32, 64, 64, "", azione, nil, parent)
	gui.set_xanchor(n, gui.ANCHOR_LEFT)
	gui.set_yanchor(n, gui.ANCHOR_TOP)
	nodo("ingranaggio", 0, 0, 34, 34, C.LUCE, n)
	return n
end

-- Stella delle lezioni e della campagna: d è il lato
function M.stella(x, y, d, colore, parent)
	return nodo("stella", x, y, d, d, colore, parent)
end

-- Disco e anello (nodi a torta): levette, pulsanti tondi, cronometro. d è il
-- diametro, spessore quello dell'anello verso l'interno
function M.disco(x, y, d, colore, parent)
	local n = gui.new_pie_node(vec(x, y), vec(d, d))
	gui.set_outer_bounds(n, gui.PIEBOUNDS_ELLIPSE)
	gui.set_perimeter_vertices(n, 64)
	gui.set_color(n, colore)
	if parent then gui.set_parent(n, parent) end
	return n
end

function M.anello(x, y, d, spessore, colore, parent)
	local n = M.disco(x, y, d, colore, parent)
	gui.set_inner_radius(n, d / 2 - spessore)
	return n
end

-- Barra di avanzamento (vita, esperienza): binario scuro e riempimento colorato
function M.barra(x, y, w, h, colore, parent)
	local n = nodo(nil, x, y, w, h, C.OMBRA, parent)
	local p = nodo(nil, -w / 2, 0, w, h, colore or C.LUCE, n)
	gui.set_pivot(p, gui.PIVOT_W)
	return { nodo = n, pieno = p, w = w, h = h }
end

function M.barra_valore(b, v)
	V.x, V.y, V.z = b.w * math.max(0, math.min(1, v)), b.h, 0
	gui.set_size(b.pieno, V)
end

-- La Corona del primo in classifica: una fascia e tre punte a rombo, col bordo
-- scuro. Restituisce la radice (invisibile), centrata sulla fascia; misure in
-- unità della GUI a scala 1 (larga 18).
M.ORO = c(1, 0.8, 0.25)
local BIANCO = c(1, 1, 1)
local PEZZI_CORONA = { { 0, 0, 16, 5, 0 }, { -6, 4, 5, 5, 45 }, { 0, 6, 5, 5, 45 }, { 6, 4, 5, 5, 45 } }

function M.corona(x, y, colore, parent)
	local r = nodo(nil, x, y, 0, 0, BIANCO, parent)
	gui.set_visible(r, false)
	for passata = 1, 2 do
		local b = passata == 1 and 2 or 0
		for _, p in ipairs(PEZZI_CORONA) do
			local n = nodo(nil, p[1], p[2], p[3] + b, p[4] + b, passata == 1 and C.FONDO or colore or M.ORO, r)
			gui.set_inherit_alpha(n, true)
			gui.set_euler(n, vmath.vector3(0, 0, p[5]))
		end
	end
	return r
end

-- Tocco sui bottoni di una lista: premuto, rilasciato sopra (l'azione) o fuori.
-- Vince l'ultimo aggiunto, che è disegnato sopra (un bottone dentro un pannello)
local function sotto(lista, x, y)
	for i = #lista, 1, -1 do
		local b = lista[i]
		if not b.spento and gui.is_enabled(b.nodo, true) and gui.pick_node(b.nodo, x, y) then return b end
	end
end

local function premi(b, giu)
	gui.set_scale(b.nodo, giu and PREMUTO or NORMALE)
	gui.set_color(b.bordo, giu and b.colore or b.riposo)
end

-- Controller: un bottone alla volta ha la luce (bordo acceso, un po' più
-- grande). La croce la sposta verso il bottone più vicino in quella direzione.
-- Nella lista vanno anche pezzi che non sono bottoni (le carte della scelta),
-- basta che abbiano nodo, bordo, colore e riposo.
M.PAD = hash("pad")
local LUCE_SCALA = vmath.vector3(1.06, 1.06, 1)
-- l'azione dell'ultimo bottone confermato: quando la schermata si ricostruisce,
-- la luce ci torna sopra
local ricorda

local function usabile(b)
	return not b.spento and gui.is_enabled(b.nodo, true)
end

-- La luce su b (nil: spenta)
function M.luce(lista, b)
	local prima = lista.luce
	if prima and prima ~= b then
		gui.set_scale(prima.nodo, NORMALE)
		gui.set_color(prima.bordo, prima.riposo)
	end
	lista.luce = b
	if b then
		gui.set_scale(b.nodo, LUCE_SCALA)
		gui.set_color(b.bordo, b.colore)
	end
end

-- Di nuovo la luce dov'era, dopo che la schermata ha ricolorato i bordi
function M.riaccendi(lista)
	local b = lista.luce
	if b and usabile(b) then M.luce(lista, b) elseif b then M.luce(lista, nil) end
end

-- Dove parte la luce: l'ultimo confermato, il principale, o il primo
-- (non quelli in un angolo: indietro e la rotellina)
local ANGOLO = { indietro = true, rotellina = true }
local function primo(lista)
	local principale, altro, angolo
	for _, b in ipairs(lista) do
		if usabile(b) then
			if ricorda and b.azione == ricorda then return b end
			-- (b.luce è il Nucleo, che hanno solo i principali)
			if ANGOLO[b.azione] then angolo = angolo or b
			elseif b.luce then principale = principale or b
			else altro = altro or b end
		end
	end
	return principale or altro or angolo
end

local DIR = { su = { 0, 1 }, giu = { 0, -1 }, sinistra = { -1, 0 }, destra = { 1, 0 } }
function M.naviga(lista, verso)
	local b = lista.luce
	if not (b and usabile(b)) then
		M.luce(lista, primo(lista))
		return
	end
	local d = DIR[verso]
	local p = gui.get_screen_position(b.nodo)
	local meglio, costo
	for _, o in ipairs(lista) do
		if o ~= b and usabile(o) then
			local q = gui.get_screen_position(o.nodo)
			local dx, dy = q.x - p.x, q.y - p.y
			local avanti = dx * d[1] + dy * d[2]
			if avanti > 1 then
				-- avanti conta poco, di lato tanto: si va dritti se si può
				local k = avanti + 2.5 * math.abs(dx * d[2] - dy * d[1])
				if not costo or k < costo then meglio, costo = o, k end
			end
		end
	end
	if meglio then M.luce(lista, meglio) end
end

-- Il bottone con la luce (o nil)
function M.illuminato(lista)
	local b = lista.luce
	return b and usabile(b) and b or nil
end

function M.tocco(lista, action_id, action)
	if action_id == M.PAD then
		if not action.pressed then return nil end
		local u = action.ui
		if DIR[u] then
			M.naviga(lista, u)
		elseif u == "conferma" then
			local b = M.illuminato(lista)
			if not b then
				M.luce(lista, primo(lista))
				return nil
			end
			if not ANGOLO[b.azione] then ricorda = b.azione end
			return b.azione
		elseif u == "indietro" then
			for _, b in ipairs(lista) do
				if b.azione == "indietro" and usabile(b) then return "indietro" end
			end
		end
		return nil
	end
	if action_id ~= hash("touch") then return nil end
	if action.pressed then
		lista.premuto = sotto(lista, action.x, action.y)
		if lista.premuto then premi(lista.premuto, true) end
	elseif action.released and lista.premuto then
		local b = lista.premuto
		lista.premuto = nil
		premi(b, false)
		if sotto(lista, action.x, action.y) == b then return b.azione end
	end
	return nil
end

return M
