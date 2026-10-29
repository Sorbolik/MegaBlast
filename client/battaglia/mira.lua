-- La mira della battaglia (Sergio, 29 ottobre 2026): solo angolo e potenza, mai
-- la traiettoria, uguale per tutte le armi (proposte disegnate in
-- https://claude.ai/artifact/NSsa8ht7XJfyJ6ZrgdxTSd). Due modi, si sceglie
-- dalla rotellina (impostazione "mira" del profilo): la lancetta, di base
-- perché chi comincia la capisce subito, e il mirino. Tutto grande uguale sullo
-- schermo a ogni zoom, come l'interfaccia:
-- - la lancetta: dritta dalla bocca dell'arma, lunga sempre uguale, a 10 tacche
--   che si riempiono del colore della squadra con la potenza;
-- - il mirino: un anellino a distanza fissa dalla bocca dell'arma, nella
--   direzione in cui si mira, che si riempie del colore della squadra con la
--   potenza (da sopra, in senso orario), unito alla bocca da una linea
--   sottilissima che fa vedere l'inclinazione (Sergio);
-- - il cartellino sopra la testa: i gradi (0° orizzontale verso dove si guarda,
--   90° in alto, negativi in basso, uguali a destra e a sinistra) e la potenza in
--   percento con una barretta del colore della squadra;
-- - solo nelle lezioni dell'Addestramento, come aiuto, la traiettoria intera:
--   puntini chiari col bordino scuro alla stessa distanza sullo schermo (il
--   Bastione: il bordo del blocco).
--
--   local m = mira.nuova()                         -- m.nodi (puntini e mirino) e m.cartello: da mettere nel mondo
--   mira.mirino(m, x, y, angolo, s, potenza, colore)  -- x, y: la bocca dell'arma nel mondo, s lo zoom
--   mira.lancetta(m, x, y, angolo, s, potenza, colore) -- uguale, l'altro modo
--   mira.cartellino(m, x, y, s, gradi, potenza, colore)  -- x, y: dove sta il fondo, nel mondo
--   mira.traiettoria(m, pts, n, s, sagoma)         -- pts[1..n] nel mondo; sagoma: puntini sui punti
--   mira.via(m) / mira.traiettoria_via(m)          -- spegne tutto / solo la traiettoria
--   mira.gradi(angolo), mira.tacca(potenza)        -- i numeri (senza nodi, per i test)
--   mira.posa(pts, n, passo, max, sagoma, out)     -- dove vanno i puntini (senza nodi)

local ui = require "ui.ui"

local M = {}

local sqrt, floor, max, deg, cos, sin = math.sqrt, math.floor, math.max, math.deg, math.cos, math.sin

-- misure in pixel dello schermo (GUI a 1280 x 720)
M.PASSO = 10          -- tra un puntino e l'altro
M.PUNTI = 80          -- puntini al massimo (con la traiettoria lunga si allargano)
M.CARTELLINO_H = 40   -- quanto è alto il cartellino col suo stacco
local DOT, DOT_BORDO = 4, 6
-- il mirino: quanto sta oltre la bocca dell'arma, il diametro, lo spessore
-- dell'anello e del riempimento, il puntino in mezzo
M.MIRINO_D = 50
local MIRINO, TRACCIA, PIENO, CENTRO = 30, 3, 5, 5
-- la linea dalla bocca al mirino: spessore della linea chiara e della sua ombra
local LINEA, LINEA_OMBRA = 1.5, 3.5
-- la lancetta: dove comincia dopo la bocca, quanto è lunga, le tacche, il loro
-- spessore e lo stacco fra l'una e l'altra, la tacca di fine corsa
local LANC_DA, LANC_L, TACCHE, TACCA_H, TACCA_STACCO, FINE_H = 6, 100, 10, 4, 2.5, 14
-- la potenza può fare una micro-vibrazione a ogni tacca: spenta di base (Sergio,
-- 29 ott: vibra solo quando il colpo diventa sganciabile), si accenderà dalle
-- impostazioni (docs/impostazioni.md)
M.TACCA = 0.05
M.VIBRA_TACCHE = false

local LUCE, OMBRA = ui.C.LUCE, vmath.vector4(0, 0, 0, 0.55)
local TRACCIA_C = vmath.vector4(LUCE.x, LUCE.y, LUCE.z, 0.35)
local LINEA_C, LINEA_OMBRA_C = vmath.vector4(LUCE.x, LUCE.y, LUCE.z, 0.7), vmath.vector4(0, 0, 0, 0.35)
local V, S = vmath.vector3(0, 0, 0), vmath.vector3(1, 1, 1)
local E = vmath.vector3(0, 0, 0)

-- Gradi interi come li legge il giocatore
function M.gradi(a)
	local g = deg(a)
	if math.cos(a) < 0 then g = 180 - g end
	g = (g + 180) % 360 - 180
	return floor(g + 0.5)
end

function M.tacca(potenza)
	return floor(potenza / M.TACCA + 1e-6)
end

-- Dove vanno i puntini lungo la linea pts[1..n], uno ogni passo (nel mondo),
-- al massimo max: out[i] = { x, y }; torna quanti sono. La linea parte dalla
-- bocca dell'arma, un passo prima di pts[1]. Con sagoma i puntini stanno
-- proprio sui punti (il bordo del Bastione).
function M.posa(pts, n, passo, maxn, sagoma, out)
	if sagoma then
		for i = 1, math.min(n, maxn) do
			local o = out[i] or {}
			o.x, o.y = pts[i].x, pts[i].y
			out[i] = o
		end
		return math.min(n, maxn)
	end
	if n < 2 then return 0 end
	-- la bocca: un passo prima del primo punto
	local px, py = 2 * pts[1].x - pts[2].x, 2 * pts[1].y - pts[2].y
	local lung = 0
	local x0, y0 = px, py
	for i = 1, n do
		local dx, dy = pts[i].x - x0, pts[i].y - y0
		lung = lung + sqrt(dx * dx + dy * dy)
		x0, y0 = pts[i].x, pts[i].y
	end
	if lung <= 0 then return 0 end
	passo = max(passo, lung / maxn)
	-- da mezzo passo dopo la bocca fino alla fine
	local k, d, fatto = 0, passo * 0.5, 0
	x0, y0 = px, py
	for i = 1, n do
		local x1, y1 = pts[i].x, pts[i].y
		local dx, dy = x1 - x0, y1 - y0
		local l = sqrt(dx * dx + dy * dy)
		while l > 0 and d <= fatto + l and k < maxn do
			local t = (d - fatto) / l
			k = k + 1
			local o = out[k] or {}
			o.x, o.y = x0 + dx * t, y0 + dy * t
			out[k] = o
			d = d + passo
		end
		fatto = fatto + l
		x0, y0 = x1, y1
	end
	return k
end

local function disco(d, colore)
	local n = ui.disco(0, 0, d, colore)
	gui.set_adjust_mode(n, gui.ADJUST_FIT)
	gui.set_enabled(n, false)
	return n
end

local function radice()
	local n = gui.new_box_node(V, V)
	gui.set_visible(n, false)
	gui.set_adjust_mode(n, gui.ADJUST_FIT)
	gui.set_enabled(n, false)
	return n
end

local function figlio(n, parent)
	gui.set_parent(n, parent)
	gui.set_enabled(n, true)
	return n
end

function M.nuova()
	local m = { nodi = {}, ombre = {}, luci = {}, out = {} }
	for i = 1, M.PUNTI do
		m.ombre[i] = disco(DOT_BORDO, OMBRA)
		m.nodi[#m.nodi + 1] = m.ombre[i]
	end
	for i = 1, M.PUNTI do
		m.luci[i] = disco(DOT, LUCE)
		m.nodi[#m.nodi + 1] = m.luci[i]
	end

	-- la linea dalla bocca al mirino (con la sua ombra), poi il mirino: ombra,
	-- anello chiaro, riempimento, puntino in mezzo
	m.linee = {}
	for i, c in ipairs({ LINEA_OMBRA_C, LINEA_C }) do
		local n = gui.new_box_node(V, V)
		gui.set_color(n, c)
		gui.set_pivot(n, gui.PIVOT_W)
		gui.set_adjust_mode(n, gui.ADJUST_FIT)
		gui.set_enabled(n, false)
		m.linee[i] = n
		m.nodi[#m.nodi + 1] = n
	end
	m.mir = radice()
	figlio(disco(MIRINO + 6, OMBRA), m.mir)
	local traccia = figlio(disco(MIRINO, TRACCIA_C), m.mir)
	gui.set_inner_radius(traccia, MIRINO / 2 - TRACCIA)
	m.pieno = figlio(disco(MIRINO + 2, LUCE), m.mir)
	gui.set_inner_radius(m.pieno, MIRINO / 2 + 1 - PIENO)
	figlio(disco(CENTRO, LUCE), m.mir)
	m.nodi[#m.nodi + 1] = m.mir

	-- la lancetta: girata come la mira, con l'ombra sotto, le tacche e la fine corsa
	m.lanc = radice()
	local function sbarra(x, w, h, colore)
		local n = figlio(gui.new_box_node(vmath.vector3(x, 0, 0), vmath.vector3(w, h, 0)), m.lanc)
		gui.set_pivot(n, gui.PIVOT_W)
		gui.set_color(n, colore)
		gui.set_adjust_mode(n, gui.ADJUST_FIT)
		return n
	end
	sbarra(LANC_DA - 1.5, LANC_L + 3, TACCA_H + 3, OMBRA)
	sbarra(LANC_DA + LANC_L + 1, 4, FINE_H + 3, OMBRA)
	m.tacche = {}
	local passo = LANC_L / TACCHE
	for i = 1, TACCHE do
		m.tacche[i] = sbarra(LANC_DA + (i - 1) * passo + TACCA_STACCO / 2, passo - TACCA_STACCO, TACCA_H, TRACCIA_C)
	end
	sbarra(LANC_DA + LANC_L + 2, 2, FINE_H, LUCE)
	m.nodi[#m.nodi + 1] = m.lanc

	-- il cartellino: carbone col bordo chiaro, gradi a sinistra, potenza a destra
	local c = {}
	c.radice = radice()
	c.fondo, c.bordo = ui.pannello(0, 0, 120, 34, c.radice)
	gui.set_color(c.fondo, vmath.vector4(ui.C.PANNELLO.x, ui.C.PANNELLO.y, ui.C.PANNELLO.z, 0.92))
	gui.set_color(c.bordo, LUCE)
	c.riga = gui.new_box_node(vmath.vector3(2, 0, 0), vmath.vector3(1.5, 22, 0))
	gui.set_color(c.riga, ui.C.LINEA)
	gui.set_parent(c.riga, c.radice)
	c.barra = ui.barra(32, -10, 40, 4, LUCE, c.radice)
	c.gradi = ui.titolo("", -28, 1, 0.6, LUCE, c.radice)
	c.potenza = ui.titolo("", 32, 4, 0.42, LUCE, c.radice)
	for _, n in ipairs({ c.fondo, c.bordo, c.riga, c.barra.nodo, c.barra.pieno, c.gradi, c.potenza }) do
		gui.set_adjust_mode(n, gui.ADJUST_FIT)
	end
	m.c = c
	m.cartello = c.radice
	return m
end

local function sposta(n, x, y, scala)
	V.x, V.y, V.z = x, y, 0
	gui.set_position(n, V)
	S.x, S.y = scala, scala
	gui.set_scale(n, S)
end

function M.traiettoria(m, pts, n, s, sagoma)
	local k = M.posa(pts, n, M.PASSO / s, M.PUNTI, sagoma, m.out)
	local scala = 1 / s
	for i = 1, M.PUNTI do
		local on = i <= k
		gui.set_enabled(m.ombre[i], on)
		gui.set_enabled(m.luci[i], on)
		if on then
			local o = m.out[i]
			sposta(m.ombre[i], o.x, o.y, scala)
			sposta(m.luci[i], o.x, o.y, scala)
		end
	end
end

function M.mirino(m, x, y, angolo, s, potenza, colore)
	local d = M.MIRINO_D / s
	sposta(m.mir, x + cos(angolo) * d, y + sin(angolo) * d, 1 / s)
	-- la torta si riempie in senso antiorario da destra: girata così parte da
	-- sopra e cresce in senso orario
	local f = 360 * math.min(1, math.max(0, potenza))
	gui.set_fill_angle(m.pieno, f)
	E.z = 90 - f
	gui.set_euler(m.pieno, E)
	gui.set_color(m.pieno, colore)
	gui.set_enabled(m.mir, true)
	gui.set_enabled(m.lanc, false)
	-- la linea parte dalla bocca e si ferma dove comincia l'anello
	E.z = deg(angolo)
	for i, n in ipairs(m.linee) do
		V.x, V.y, V.z = x, y, 0
		gui.set_position(n, V)
		V.x, V.y = (M.MIRINO_D - MIRINO / 2 - 1) / s, (i == 1 and LINEA_OMBRA or LINEA) / s
		gui.set_size(n, V)
		gui.set_euler(n, E)
		gui.set_enabled(n, true)
	end
end

function M.lancetta(m, x, y, angolo, s, potenza, colore)
	sposta(m.lanc, x, y, 1 / s)
	E.z = deg(angolo)
	gui.set_euler(m.lanc, E)
	-- piene le tacche fino alla potenza (la prima si accende subito)
	local piene = math.max(1, math.floor(potenza * TACCHE + 0.5))
	for i, n in ipairs(m.tacche) do gui.set_color(n, i <= piene and colore or TRACCIA_C) end
	gui.set_enabled(m.lanc, true)
	gui.set_enabled(m.mir, false)
	for _, n in ipairs(m.linee) do gui.set_enabled(n, false) end
end

function M.cartellino(m, x, y, s, gradi, potenza, colore)
	local c = m.c
	local testo = gradi .. "°"
	if c.testo ~= testo then
		gui.set_text(c.gradi, testo)
		c.testo = testo
	end
	local p = floor(potenza * 100 + 0.5)
	if c.p ~= p then
		gui.set_text(c.potenza, p .. "%")
		ui.barra_valore(c.barra, potenza)
		c.p = p
	end
	gui.set_color(c.barra.pieno, colore)
	-- il fondo del cartellino su (x, y), 17 pixel sotto il centro
	sposta(c.radice, x, y + 17 / s, 1 / s)
	gui.set_enabled(c.radice, true)
end

function M.traiettoria_via(m)
	for i = 1, M.PUNTI do
		gui.set_enabled(m.ombre[i], false)
		gui.set_enabled(m.luci[i], false)
	end
end

function M.via(m)
	M.traiettoria_via(m)
	gui.set_enabled(m.mir, false)
	gui.set_enabled(m.lanc, false)
	for _, n in ipairs(m.linee) do gui.set_enabled(n, false) end
	gui.set_enabled(m.c.radice, false)
end

return M
