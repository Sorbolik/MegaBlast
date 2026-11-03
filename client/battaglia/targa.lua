-- La targa sopra la Scoria in battaglia: il nome, senza targhetta, sopra una lama
-- d'acciaio sottile con la vita che scorre nella scanalatura, nel colore della
-- squadra (stile C della scheda WB-011, "lama incisa", scelta di Sergio del 3 nov,
-- con la sua Corona d'oro). Le immagini le taglia strumenti/grafica/targa.py dal
-- foglio di ChatGPT; il font è quello dell'interfaccia (ui/ui.lua). Il danno si vede in due tempi: la vita scende subito, il pezzo perso
-- resta bianco un attimo e poi si consuma; la barra sobbalza e lampeggia. Sotto
-- il 30% la vita pulsa. Lo scudo, se c'è, è un tratto chiaro dopo la vita.
--
--   local tt = targa.nuove(colori, nomi)  -- una targa per colore, tutte insieme
--   targa.vita(t, vita, massima, scudo)   -- quando cambia (scudo può mancare)
--   targa.update(t, dt, x, y, scala, cam)   -- a ogni frame: x, y è il centro in basso (nel
--                                          mondo); cam (battaglia/camera.lua) per la riga
--   targa.scala(cam)                      -- la scala da dare a update: la targa resta
--                                          -- grande uguale sullo schermo a ogni zoom
--   targa.set_enabled(t, on) / targa.nome(t, nome) / targa.colore(t, colore)
--   targa.stato(t, testo)                 -- gli effetti addosso, sotto la barra ("" = niente)
--   targa.annuncio(t, testo)              -- una scritta che sale sopra il nome e svanisce
--   targa.riga(t, testo)                  -- il suggerimento delle missioni, sopra tutto ("" = niente)
--   targa.battuta(t, testo)               -- quello che dice il personaggio: una nuvoletta che
--                                          -- resta un paio di secondi e svanisce
--   targa.posto(t, testo, corona)         -- il posto in classifica a sinistra della barra
--                                          -- ("" = niente) e la Corona accanto al nome
--   targa.sopra(t)                        -- dove finisce la targa in alto (unità a scala 1)
--
-- La freccia di ferro di chi è di turno (scheda WB-010, scelta di Sergio del 2 nov):
-- una sola per tutta la partita, sopra il nome, che dondola
-- con la brace del colore della squadra che pulsa (più accesa giù in basso).
--   local f = targa.freccia()             -- f.radice va nella scena fra le barre e i testi
--   targa.freccia_su(f, t)                -- a ogni frame, prima di targa.update: su t (nil = via)
--
-- Ogni targa ha due radici, t.barre e t.testi, che si muovono insieme. La GUI
-- disegna i nodi nell'ordine in cui stanno: chi le mette nella scena mette prima
-- le barre di tutte le targhe, poi la freccia e poi tutti i testi, così bastano due
-- draw call per tutte: le immagini dell'atlante della battaglia (lama, vita, Corona,
-- fondo delle battute e freccia: anche i rettangoli usano targa_bianco), poi il font. Non usiamo i layer della GUI perché
-- disegnerebbero le targhe sopra i pulsanti e i menu.

local ui = require "ui.ui"
local schermo = require "ui.schermo"
local camera = require "battaglia.camera"

local M = {}

local max = math.max

-- misure in unità della GUI con scala 1. La vita è larga W e alta H; la lama è alta
-- LAMA_H, comincia PRIMA della vita (il manico) e finisce DOPO (la punta), e la vita
-- sta SU sopra il suo centro. L'immagine ha LAMA_PX pixel per unità e si allunga
-- solo fra i bordi LAMA_SX e LAMA_DX (pixel): misure da strumenti/grafica/targa.py
local W = 36
local H, LAMA_H, PRIMA, DOPO, SU = 2.59, 9, 8.44, 12.6, 0.39
local LAMA_PX, LAMA_SX, LAMA_DX = 4, 47, 92
local BASE = LAMA_H / 2     -- dal punto in basso della targa al centro della lama
local NOME_Y = LAMA_H / 2 + 6 -- centro del nome sopra la lama
-- scala del font "titolo" (scala 1 = circa 40 px)
local NOME_SCALA, NUMERO_SCALA, STATO_SCALA, ANNUNCIO_SCALA = 0.25, 0.2, 0.18, 0.3
local STATO_Y, ANNUNCIO_Y, ANNUNCIO_SALE, ANNUNCIO_T = -(LAMA_H / 2 + 4), 22, 14, 1.4
-- La targa resta grande uguale sullo schermo a ogni zoom (Sergio, 3 nov: da
-- lontano non deve essere più grande del personaggio): scala SCHERMO / zoom
local SCHERMO = 0.85
-- la Corona del primo sulla riga del nome, a sinistra (Sergio, 3 nov, scelta L1:
-- la targa resta bassa), larga CORONA_W e alta CORONA_H come l'immagine (108 x 59)
local CORONA_W, CORONA_STACCO = 13.5, 2
local CORONA_H = CORONA_W * 59 / 108
-- dove finisce il nome in alto
local NOME_CIMA = NOME_Y + 6
-- la freccia di ferro: larga FRECCIA_W (alta come dice l'immagine), FRECCIA_STACCO
-- sopra il nome (nel nodo che sobbalza col colpo, come lui);
-- dondola di FRECCIA_DONDOLA in su e in giù ogni FRECCIA_T secondi
local FRECCIA_W = 18
local FRECCIA_STACCO, FRECCIA_DONDOLA, FRECCIA_T = 3, 1.5, 1.4
-- la riga delle missioni: sopra la Corona e gli annunci che salgono, a capo
-- oltre RIGA_W; grande RIGA_SCALA sullo schermo a ogni zoom (circa 22 px: con la
-- camera lontana non si rimpicciolisce come il resto della targa). Non esce
-- dai lati dello schermo: col robot vicino a un bordo si sposta verso il centro
local RIGA_STACCO, RIGA_SCALA, RIGA_W, RIGA_LATO = 13, 0.55, 1640, 16
-- e non sale fin sotto i punti e l'obiettivo in cima (battaglia/punteggio.lua):
-- col robot in alto scende, sopra il robot
local RIGA_CIMA = 130
-- la nuvoletta delle battute: sopra il nome, grande BATTUTA_SCALA sullo
-- schermo a ogni zoom, col fondo scuro attorno (BATTUTA_BORDO px)
-- (BATTUTA_STACCO sopra il nome, o FRECCIA_SOPRA sopra la freccia)
local BATTUTA_STACCO, BATTUTA_SCALA, BATTUTA_BORDO, BATTUTA_T = 2, 0.42, 8, 2.6
local FRECCIA_SOPRA = 2
local NUVOLA = vmath.vector4(0.06, 0.05, 0.08, 0.82)

local SCIA = ui.C.LUCE
local SCUDO = vmath.vector4(0.75, 0.86, 1, 1)

local V = vmath.vector3(0, 0, 0)
local C = vmath.vector4(1, 1, 1, 1)

-- un'immagine dell'atlante della battaglia, grande w x h
local function immagine(parent, nome, x, y, w, h)
	local n = gui.new_box_node(vmath.vector3(x, y, 0), vmath.vector3(w, h, 0))
	gui.set_texture(n, "battaglia")
	gui.play_flipbook(n, nome)
	gui.set_adjust_mode(n, gui.ADJUST_FIT)
	gui.set_parent(n, parent)
	gui.set_inherit_alpha(n, true)
	return n
end

-- un rettangolo pieno: targa_bianco tinto (così sta nella draw call delle immagini)
local function rettangolo(parent, x, y, w, h, colore)
	local n = immagine(parent, "targa_bianco", x, y, w, h)
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
	local n = rettangolo(t.dentro, -W / 2, SU, 0, H, colore)
	gui.set_pivot(n, gui.PIVOT_W)
	return n
end

local function larghezza(n, x, w)
	gui.set_enabled(n, w > 0.05)
	V.x, V.y, V.z = -W / 2 + x, SU, 0
	gui.set_position(n, V)
	V.x, V.y = w, H
	gui.set_size(n, V)
end

-- un nodo radice invisibile che segue la Scoria, con dentro il nodo che sobbalza
local function radice()
	local r = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(0, 0, 0))
	gui.set_visible(r, false)
	gui.set_adjust_mode(r, gui.ADJUST_FIT)
	local d = gui.new_box_node(vmath.vector3(0, BASE, 0), vmath.vector3(0, 0, 0))
	gui.set_parent(d, r)
	gui.set_inherit_alpha(d, true)
	gui.set_visible(d, false)
	return r, d
end

-- la Corona a sinistra del nome: dipende da quanto è largo
local function corona_posto(t)
	local font = gui.get_font_resource(gui.get_font(t.nome))
	local w = resource.get_text_metrics(font, gui.get_text(t.nome)).width * NOME_SCALA
	V.x, V.y, V.z = -w / 2 - CORONA_STACCO - CORONA_W / 2, NOME_Y, 0
	gui.set_position(t.corona, V)
end

function M.nuove(colori, nomi)
	local tt = {}
	-- prima le barre di tutte le targhe
	for i, colore in ipairs(colori) do
		local t = { colore = vmath.vector4(colore.x, colore.y, colore.z, 1), vita_f = 1, scia_f = 1,
			scudo_f = 0, max_f = 1, attesa = 0, colpo = 0, t = 0, annuncio_t = 0 }
		t.barre, t.dentro = radice()
		-- la lama: si allunga solo nel mezzo (slice9 in pixel dell'immagine,
		-- per questo è grande LAMA_PX volte e rimpicciolita)
		local lw = PRIMA + W + DOPO
		local lama = immagine(t.dentro, "targa_lama", (DOPO - PRIMA) / 2, 0, lw * LAMA_PX, LAMA_H * LAMA_PX)
		gui.set_slice9(lama, vmath.vector4(LAMA_SX, 0, LAMA_DX, 0))
		gui.set_scale(lama, vmath.vector3(1 / LAMA_PX, 1 / LAMA_PX, 1))
		t.scia = pezzo(t, SCIA)
		t.scudo = pezzo(t, SCUDO)
		t.pieno = pezzo(t, colore)
		t.corona = immagine(t.dentro, "targa_corona", 0, NOME_Y, CORONA_W, CORONA_H)
		gui.set_enabled(t.corona, false)
		-- il fondo della nuvoletta, con le forme (fuori dal nodo che sobbalza)
		t.nuvola = rettangolo(t.barre, 0, 0, 0, 0, NUVOLA)
		gui.set_pivot(t.nuvola, gui.PIVOT_S)
		gui.set_enabled(t.nuvola, false)
		t.battuta_t = 0
		tt[i] = t
	end
	-- poi i testi
	for i, t in ipairs(tt) do
		t.testi, t.dentro_testi = radice()
		t.nome = testo(t.dentro_testi, 0, NOME_Y, nomi[i] or "", NOME_SCALA, t.colore)
		t.numero = testo(t.dentro_testi, W / 2 + DOPO + 2, 0, "", NUMERO_SCALA, ui.C.TESTO)
		gui.set_pivot(t.numero, gui.PIVOT_W)
		t.posto = testo(t.dentro_testi, -W / 2 - PRIMA - 2, 0, "", NUMERO_SCALA, ui.C.TESTO)
		gui.set_pivot(t.posto, gui.PIVOT_E)
		t.stato = testo(t.dentro_testi, 0, STATO_Y, "", STATO_SCALA, ui.C.TESTO)
		t.annuncio = testo(t.dentro_testi, 0, ANNUNCIO_Y, "", ANNUNCIO_SCALA, ui.C.LUCE)
		gui.set_enabled(t.annuncio, false)
		t.riga = testo(t.testi, 0, 0, "", RIGA_SCALA, ui.C.LUCE)
		gui.set_pivot(t.riga, gui.PIVOT_S)
		gui.set_line_break(t.riga, true)
		gui.set_size(t.riga, vmath.vector3(RIGA_W, 0, 0))
		t.riga_testo, t.riga_h = "", 0
		t.battuta = testo(t.testi, 0, 0, "", BATTUTA_SCALA, ui.C.TESTO)
		gui.set_pivot(t.battuta, gui.PIVOT_S)
		gui.set_enabled(t.battuta, false)
		M.vita(t, 1, 1)
		corona_posto(t)
	end
	return tt
end

function M.nome(t, nome)
	gui.set_text(t.nome, nome)
	corona_posto(t)
end

function M.scala(cam)
	return SCHERMO / cam.s
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

-- dove finisce la targa in alto, freccia compresa (unità a scala 1, dal centro
-- in basso): sopra ci stanno le battute e la riga
function M.sopra(t)
	return max(NOME_CIMA, t.freccia_cima or 0)
end

function M.riga(t, s)
	if t.riga_testo == s then return end
	t.riga_testo = s
	gui.set_text(t.riga, s)
	local font = gui.get_font_resource(gui.get_font(t.riga))
	local m = s ~= "" and resource.get_text_metrics(font, s, { width = RIGA_W, line_break = true })
	t.riga_h, t.riga_w = m and m.height or 0, m and m.width or 0
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

local freccia_update -- più sotto, con la freccia

function M.update(t, dt, x, y, scala, cam)
	t.t = t.t + dt
	t.x, t.y, t.scala = x, y, scala
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
		local sx = camera.allo_schermo(cam, x, y)
		local mezzo = (t.riga_w or 0) * RIGA_SCALA / 2 + RIGA_LATO
		local cx = math.max(schermo.x0 + mezzo, math.min(schermo.x1 - mezzo, sx))
		if schermo.x1 - schermo.x0 < 2 * mezzo then cx = (schermo.x0 + schermo.x1) / 2 end
		V.x = (camera.al_mondo(cam, cx, 0) - x) / scala
		V.y = math.min(M.sopra(t) + RIGA_STACCO, (tetto - y) / scala)
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
		local y0 = M.sopra(t) + (t.freccia and FRECCIA_SOPRA or BATTUTA_STACCO)
		V.x, V.y = 0, y0
		gui.set_position(t.nuvola, V)
		V.y = y0 + bordo
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
	if t.freccia then freccia_update(t.freccia, t, dt, k) end

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

-- la freccia: il ferro, la brace bianca tinta col colore della squadra, il cuore
-- bianco (strumenti/grafica/freccia.py), nell'atlante della battaglia. Larga
-- FRECCIA_W, alta quanto dice l'immagine (niente si deforma)
local function strato(r, nome)
	local n = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(0, 0, 0))
	gui.set_texture(n, "battaglia")
	gui.set_size_mode(n, gui.SIZE_MODE_AUTO)
	gui.play_flipbook(n, nome)
	local px = gui.get_size(n)
	gui.set_size_mode(n, gui.SIZE_MODE_MANUAL)
	gui.set_size(n, vmath.vector3(FRECCIA_W, FRECCIA_W * px.y / px.x, 0))
	gui.set_adjust_mode(n, gui.ADJUST_FIT)
	gui.set_parent(n, r)
	gui.set_inherit_alpha(n, true)
	return n
end

function M.freccia()
	local f = { t = 0 }
	f.radice = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(0, 0, 0))
	gui.set_visible(f.radice, false)
	gui.set_adjust_mode(f.radice, gui.ADJUST_FIT)
	f.ferro = strato(f.radice, "freccia_ferro")
	f.brace = strato(f.radice, "freccia_brace")
	f.cuore = strato(f.radice, "freccia_cuore")
	f.h = gui.get_size(f.ferro).y
	gui.set_enabled(f.radice, false)
	return f
end

-- il centro della freccia sopra il nome (nel nodo che sobbalza)
local function freccia_base(f)
	return NOME_CIMA + FRECCIA_STACCO + f.h / 2
end

-- la freccia va su t (la targa di chi è di turno, nil = nessuno): prima di
-- targa.update, che la mette al suo posto, così cartellino e battute la sanno già
function M.freccia_su(f, t)
	if f.su ~= t then
		if f.su then f.su.freccia, f.su.freccia_cima = nil, nil end
		f.su = t
		gui.set_enabled(f.radice, t ~= nil)
	end
	if not t then return end
	t.freccia = f
	t.freccia_cima = BASE + freccia_base(f) + f.h / 2 + FRECCIA_DONDOLA
end

-- in targa.update, col sobbalzo del colpo (k) come il nome e la Corona. In alto
-- dondola piano con la brace bassa, in basso è accesa
freccia_update = function(f, t, dt, k)
	f.t = (f.t + dt) % FRECCIA_T
	local c = math.cos(f.t / FRECCIA_T * 2 * math.pi)
	local accesa = (1 - c) / 2
	V.x, V.y, V.z = t.x, t.y + (BASE + (freccia_base(f) + FRECCIA_DONDOLA * c) * k) * t.scala, 0
	gui.set_position(f.radice, V)
	V.x, V.y, V.z = t.scala * k, t.scala * k, 1
	gui.set_scale(f.radice, V)
	local col = t.colore
	C.x, C.y, C.z, C.w = col.x, col.y, col.z, 0.55 + 0.45 * accesa
	gui.set_color(f.brace, C)
	C.x, C.y, C.z, C.w = 1, 1, 1, 0.15 + 0.85 * accesa * accesa
	gui.set_color(f.cuore, C)
end

return M
