-- La targa sopra la Scoria in battaglia: il nome e una barra della vita sottile,
-- solo forme semplici disegnate dal codice (nessuna immagine) con la palette e il
-- font dell'interfaccia (ui/ui.lua), nel colore della squadra. Il danno si vede in due tempi: la vita scende subito, il pezzo perso
-- resta bianco un attimo e poi si consuma; la barra sobbalza e lampeggia. Sotto
-- il 30% la vita pulsa. Lo scudo, se c'è, è un tratto chiaro dopo la vita.
--
--   local tt = targa.nuove(colori, nomi)  -- una targa per colore, tutte insieme
--   targa.vita(t, vita, massima, scudo)   -- quando cambia (scudo può mancare)
--   targa.update(t, dt, x, y, scala, cam, su) -- a ogni frame: x, y è il centro in basso (nel
--                                          mondo); cam (battaglia/camera.lua) per la riga
--   targa.set_enabled(t, on) / targa.nome(t, nome) / targa.colore(t, colore)
--   targa.stato(t, testo)                 -- gli effetti addosso, sotto la barra ("" = niente)
--   targa.annuncio(t, testo)              -- una scritta che sale sopra il nome e svanisce
--   targa.riga(t, testo)                  -- il suggerimento delle missioni, sopra tutto ("" = niente)
--   targa.battuta(t, testo)               -- quello che dice il personaggio: una nuvoletta che
--                                          -- resta un paio di secondi e svanisce
--   targa.posto(t, testo, corona)         -- il posto in classifica a sinistra della barra
--                                          -- ("" = niente) e la Corona sopra il nome
--
-- Ogni targa ha due radici, t.barre e t.testi, che si muovono insieme. La GUI
-- disegna i nodi nell'ordine in cui stanno: chi le mette nella scena mette prima
-- le barre di tutte le targhe e poi tutti i testi, così bastano due draw call per
-- tutte (forme senza immagine, poi il font). Non usiamo i layer della GUI perché
-- disegnerebbero le targhe sopra i pulsanti e i menu.

local ui = require "ui.ui"
local schermo = require "ui.schermo"
local camera = require "battaglia.camera"

local M = {}

local max = math.max

-- misure in unità della GUI con scala 1
local W, H = 44, 4          -- la barra
local BORDO = 1             -- il fondo scuro attorno
local NOME_Y = 10           -- centro del nome sopra la barra
-- scala del font "titolo" (scala 1 = circa 40 px)
local NOME_SCALA, NUMERO_SCALA, STATO_SCALA, ANNUNCIO_SCALA = 0.25, 0.2, 0.18, 0.3
local STATO_Y, ANNUNCIO_Y, ANNUNCIO_SALE, ANNUNCIO_T = -8, 22, 14, 1.4
local CORONA_Y, CORONA_SCALA = NOME_Y + 10, 0.5
-- dove finisce la targa in alto (Corona compresa): sopra ci sta il cartellino della mira
M.SOPRA = CORONA_Y + 6
-- la riga delle missioni: sopra la Corona e gli annunci che salgono, a capo
-- oltre RIGA_W; grande RIGA_SCALA sullo schermo a ogni zoom (circa 22 px: con la
-- camera lontana non si rimpicciolisce come il resto della targa)
local RIGA_Y, RIGA_SCALA, RIGA_W = CORONA_Y + 30, 0.55, 1800
-- e non sale fin sotto i punti e l'obiettivo in cima (battaglia/punteggio.lua):
-- col robot in alto scende, sopra il robot
local RIGA_CIMA = 130
-- la nuvoletta delle battute: sopra la Corona, grande BATTUTA_SCALA sullo
-- schermo a ogni zoom, col fondo scuro attorno (BATTUTA_BORDO px)
local BATTUTA_Y, BATTUTA_SCALA, BATTUTA_BORDO, BATTUTA_T = CORONA_Y + 14, 0.42, 8, 2.6
local NUVOLA = vmath.vector4(0.06, 0.05, 0.08, 0.82)

local FONDO = ui.C.OMBRA
local SCIA = ui.C.LUCE
local SCUDO = vmath.vector4(0.75, 0.86, 1, 1)

local V = vmath.vector3(0, 0, 0)
local C = vmath.vector4(1, 1, 1, 1)

local function rettangolo(parent, x, y, w, h, colore)
	local n = gui.new_box_node(vmath.vector3(x, y, 0), vmath.vector3(w, h, 0))
	gui.set_parent(n, parent)
	gui.set_inherit_alpha(n, true)
	gui.set_color(n, colore)
	return n
end

local function testo(parent, x, y, s, scala, colore)
	local n = gui.new_text_node(vmath.vector3(x, y, 0), s)
	gui.set_parent(n, parent)
	gui.set_inherit_alpha(n, true)
	gui.set_font(n, "titolo")
	gui.set_color(n, colore)
	gui.set_outline(n, ui.C.OMBRA)
	gui.set_scale(n, vmath.vector3(scala, scala, 1))
	return n
end

-- un pezzo della barra: parte dal bordo sinistro, largo w (da x)
local function pezzo(t, colore)
	local n = rettangolo(t.dentro, -W / 2, 0, 0, H, colore)
	gui.set_pivot(n, gui.PIVOT_W)
	return n
end

local function larghezza(n, x, w)
	gui.set_enabled(n, w > 0.05)
	V.x, V.y, V.z = -W / 2 + x, 0, 0
	gui.set_position(n, V)
	V.x, V.y = w, H
	gui.set_size(n, V)
end

-- un nodo radice invisibile che segue la Scoria, con dentro il nodo che sobbalza
local function radice()
	local r = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(0, 0, 0))
	gui.set_visible(r, false)
	gui.set_adjust_mode(r, gui.ADJUST_FIT)
	local d = rettangolo(r, 0, H / 2 + BORDO, 0, 0, FONDO)
	gui.set_visible(d, false)
	return r, d
end

function M.nuove(colori, nomi)
	local tt = {}
	-- prima le barre di tutte le targhe
	for i, colore in ipairs(colori) do
		local t = { colore = vmath.vector4(colore.x, colore.y, colore.z, 1), vita_f = 1, scia_f = 1,
			scudo_f = 0, max_f = 1, attesa = 0, colpo = 0, t = 0, annuncio_t = 0 }
		t.barre, t.dentro = radice()
		rettangolo(t.dentro, 0, 0, W + 2 * BORDO, H + 2 * BORDO, FONDO)
		t.scia = pezzo(t, SCIA)
		t.scudo = pezzo(t, SCUDO)
		t.pieno = pezzo(t, colore)
		t.corona = ui.corona(0, CORONA_Y, nil, t.dentro)
		gui.set_scale(t.corona, vmath.vector3(CORONA_SCALA, CORONA_SCALA, 1))
		gui.set_enabled(t.corona, false)
		-- il fondo della nuvoletta, con le forme (fuori dal nodo che sobbalza)
		t.nuvola = rettangolo(t.barre, 0, BATTUTA_Y, 0, 0, NUVOLA)
		gui.set_pivot(t.nuvola, gui.PIVOT_S)
		gui.set_enabled(t.nuvola, false)
		t.battuta_t = 0
		tt[i] = t
	end
	-- poi i testi
	for i, t in ipairs(tt) do
		t.testi, t.dentro_testi = radice()
		t.nome = testo(t.dentro_testi, 0, NOME_Y, nomi[i] or "", NOME_SCALA, t.colore)
		t.numero = testo(t.dentro_testi, W / 2 + BORDO + 3, 0, "", NUMERO_SCALA, ui.C.TESTO)
		gui.set_pivot(t.numero, gui.PIVOT_W)
		t.posto = testo(t.dentro_testi, -W / 2 - BORDO - 3, 0, "", NUMERO_SCALA, ui.C.TESTO)
		gui.set_pivot(t.posto, gui.PIVOT_E)
		t.stato = testo(t.dentro_testi, 0, STATO_Y, "", STATO_SCALA, ui.C.TESTO)
		t.annuncio = testo(t.dentro_testi, 0, ANNUNCIO_Y, "", ANNUNCIO_SCALA, ui.C.LUCE)
		gui.set_enabled(t.annuncio, false)
		t.riga = testo(t.testi, 0, RIGA_Y, "", RIGA_SCALA, ui.C.LUCE)
		gui.set_pivot(t.riga, gui.PIVOT_S)
		gui.set_line_break(t.riga, true)
		gui.set_size(t.riga, vmath.vector3(RIGA_W, 0, 0))
		t.riga_testo, t.riga_h = "", 0
		t.battuta = testo(t.testi, 0, BATTUTA_Y, "", BATTUTA_SCALA, ui.C.TESTO)
		gui.set_pivot(t.battuta, gui.PIVOT_S)
		gui.set_enabled(t.battuta, false)
		M.vita(t, 1, 1)
	end
	return tt
end

function M.nome(t, nome)
	gui.set_text(t.nome, nome)
end

-- il colore della squadra (cambia da una partita all'altra)
function M.colore(t, colore)
	t.colore.x, t.colore.y, t.colore.z = colore.x, colore.y, colore.z
	gui.set_color(t.nome, t.colore)
end

function M.stato(t, s)
	gui.set_text(t.stato, s)
end

function M.posto(t, s, corona)
	gui.set_text(t.posto, s)
	gui.set_enabled(t.corona, corona)
end

function M.riga(t, s)
	if t.riga_testo == s then return end
	t.riga_testo = s
	gui.set_text(t.riga, s)
	local font = gui.get_font_resource(gui.get_font(t.riga))
	t.riga_h = s == "" and 0 or resource.get_text_metrics(font, s, { width = RIGA_W, line_break = true }).height
end

function M.battuta(t, s)
	gui.set_text(t.battuta, s)
	local font = gui.get_font_resource(gui.get_font(t.battuta))
	local m = resource.get_text_metrics(font, s)
	t.battuta_w, t.battuta_h = m.width, m.height
	t.battuta_t = BATTUTA_T
	gui.set_enabled(t.battuta, true)
	gui.set_enabled(t.nuvola, true)
end

function M.annuncio(t, s)
	gui.set_text(t.annuncio, s)
	gui.set_enabled(t.annuncio, true)
	t.annuncio_t = ANNUNCIO_T
end

function M.set_enabled(t, on)
	gui.set_enabled(t.barre, on)
	gui.set_enabled(t.testi, on)
end

-- vita e scudo in punti; la barra conta fino a massima, o a vita + scudo se di più
function M.vita(t, vita, massima, scudo)
	vita, scudo = max(0, vita), max(0, scudo or 0)
	local tot = max(massima, vita + scudo)
	local f = vita / tot
	if f < t.vita_f - 1e-6 then
		-- colpo: la scia parte da dove era la vita (se non era già più su)
		t.scia_f = max(t.scia_f, t.vita_f)
		t.attesa = 0.45
		t.colpo = 1
	elseif f > t.scia_f then
		t.scia_f = f
	end
	t.vita_f, t.scudo_f, t.max_f = f, scudo / tot, massima / tot
	gui.set_text(t.numero, tostring(math.floor(vita + 0.5)))
end

function M.update(t, dt, x, y, scala, cam, su)
	t.t = t.t + dt
	V.x, V.y, V.z = x, y, 0
	gui.set_position(t.barre, V)
	gui.set_position(t.testi, V)
	V.x, V.y, V.z = scala, scala, 1
	gui.set_scale(t.barre, V)
	gui.set_scale(t.testi, V)
	if cam then
		-- la scala del mondo è cam.s: la riga resta grande uguale sullo schermo
		local k = RIGA_SCALA / (scala * cam.s)
		V.x, V.y = k, k
		gui.set_scale(t.riga, V)
		local _, tetto = camera.al_mondo(cam, 0, schermo.y1 - RIGA_CIMA - t.riga_h * RIGA_SCALA)
		-- su: pixel dello schermo in più sopra la targa (il cartellino della mira)
		V.x, V.y = 0, math.min(RIGA_Y + (su or 0) / (scala * cam.s), (tetto - y) / scala)
		gui.set_position(t.riga, V)
	end

	-- la nuvoletta: grande uguale sullo schermo, svanisce nell'ultimo mezzo secondo
	if t.battuta_t > 0 then
		t.battuta_t = t.battuta_t - dt
		local zoom = scala * (cam and cam.s or 1)
		local k, bordo = BATTUTA_SCALA / zoom, BATTUTA_BORDO / zoom
		V.x, V.y, V.z = k, k, 1
		gui.set_scale(t.battuta, V)
		V.x, V.y, V.z = t.battuta_w * k + 2 * bordo, t.battuta_h * k + 2 * bordo, 0
		gui.set_size(t.nuvola, V)
		V.x, V.y = 0, BATTUTA_Y + bordo
		gui.set_position(t.battuta, V)
		local a = math.min(1, t.battuta_t * 2)
		C.x, C.y, C.z, C.w = ui.C.TESTO.x, ui.C.TESTO.y, ui.C.TESTO.z, a
		gui.set_color(t.battuta, C)
		C.x, C.y, C.z, C.w = NUVOLA.x, NUVOLA.y, NUVOLA.z, NUVOLA.w * a
		gui.set_color(t.nuvola, C)
		if t.battuta_t <= 0 then
			gui.set_enabled(t.battuta, false)
			gui.set_enabled(t.nuvola, false)
		end
	end

	-- la scia aspetta un attimo e poi si consuma fino alla vita
	if t.attesa > 0 then
		t.attesa = t.attesa - dt
	elseif t.scia_f > t.vita_f then
		t.scia_f = max(t.vita_f, t.scia_f - dt * 0.9)
	end
	-- sobbalzo del colpo
	t.colpo = max(0, t.colpo - dt * 5)
	local k = 1 + 0.25 * t.colpo
	V.x, V.y, V.z = k, k, 1
	gui.set_scale(t.dentro, V)
	gui.set_scale(t.dentro_testi, V)

	-- l'annuncio sale e svanisce
	if t.annuncio_t > 0 then
		t.annuncio_t = t.annuncio_t - dt
		local f = 1 - max(0, t.annuncio_t) / ANNUNCIO_T
		V.x, V.y, V.z = 0, ANNUNCIO_Y + ANNUNCIO_SALE * f, 0
		gui.set_position(t.annuncio, V)
		C.x, C.y, C.z, C.w = ui.C.LUCE.x, ui.C.LUCE.y, ui.C.LUCE.z, math.min(1, 3 * (1 - f))
		gui.set_color(t.annuncio, C)
		if t.annuncio_t <= 0 then gui.set_enabled(t.annuncio, false) end
	end

	larghezza(t.scia, 0, W * t.scia_f)
	larghezza(t.pieno, 0, W * t.vita_f)
	larghezza(t.scudo, W * t.vita_f, W * t.scudo_f)

	-- colore della vita: bianco nel colpo, pulsa quando è bassa
	local bianco = t.colpo
	if t.vita_f > 0 and t.vita_f < 0.3 * t.max_f then
		bianco = max(bianco, 0.3 + 0.3 * math.sin(t.t * 9))
	end
	local c = t.colore
	C.x, C.y, C.z, C.w = c.x + (1 - c.x) * bianco, c.y + (1 - c.y) * bianco, c.z + (1 - c.z) * bianco, 1
	gui.set_color(t.pieno, C)
end

return M
