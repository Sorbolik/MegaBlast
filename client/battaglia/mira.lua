-- La mira della battaglia (Sergio, 29 ottobre 2026: proposte disegnate in
-- https://claude.ai/artifact/WZreQpDg1ySdYkGo8UgRvj, scelte la freccia della 1 e
-- il cartellino della 3). Due pezzi, tutti e due grandi uguali sullo schermo a
-- ogni zoom, come l'interfaccia:
-- - la freccia: puntini chiari tutti uguali col bordino scuro, alla stessa
--   distanza l'uno dall'altro sullo schermo, dalla bocca dell'arma fino a una
--   punta del colore della squadra. Segue la traiettoria che già mostravamo
--   (stessa lunghezza: quanto se ne vede è una scelta di gioco, game.AIM_PREVIEW_DOTS);
-- - il cartellino sopra la testa: i gradi (0° orizzontale verso dove si guarda,
--   90° in alto, negativi in basso, uguali a destra e a sinistra) e, per le armi
--   che ce l'hanno, la potenza in percento con una barretta del colore della squadra.
--
--   local m = mira.nuova()                         -- m.nodi (la freccia) e m.cartello: da mettere nel mondo
--   mira.freccia(m, pts, n, s, colore, sagoma)     -- pts[1..n] nel mondo, s lo zoom della camera;
--                                                  -- sagoma: solo puntini sui punti (il Bastione)
--   mira.cartellino(m, x, y, s, gradi, potenza, colore)  -- x, y: dove sta il fondo, nel mondo;
--                                                  -- potenza nil: solo i gradi
--   mira.freccia_via(m) / mira.cartellino_via(m)   -- spegne l'uno o l'altro
--   mira.gradi(angolo), mira.tacca(potenza)        -- i numeri (senza nodi, per i test)
--   mira.posa(pts, n, passo, max, sagoma, out)     -- dove vanno i puntini (senza nodi)

local ui = require "ui.ui"

local M = {}

local sqrt, atan2, floor, max, deg = math.sqrt, math.atan2, math.floor, math.max, math.deg

-- misure in pixel dello schermo (GUI a 1280 x 720)
M.PASSO = 15          -- tra un puntino e l'altro
M.PUNTI = 40          -- puntini al massimo (con la freccia lunga si allargano)
local DOT, DOT_BORDO = 7, 10
-- raggi della punta: dentro, bordo chiaro, ombra
local PUNTA, PUNTA_LUCE, PUNTA_OMBRA = 15, 19, 22
-- la potenza fa una micro-vibrazione a ogni tacca
M.TACCA = 0.05
-- armi in cui la potenza conta (le altre vanno dritte o a distanza fissa)
M.POTENZA = { missile = true, grenade = true, trampoline = true, teleport = true, wall = true }

local LUCE, OMBRA = ui.C.LUCE, vmath.vector4(0, 0, 0, 0.55)
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
-- al massimo max: out[i] = { x, y }. Torna quanti sono e la punta (x, y,
-- direzione), o nil con sagoma (i puntini stanno proprio sui punti). La linea
-- parte dalla bocca dell'arma, un passo prima di pts[1].
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
	-- la punta: sull'ultimo punto, girata come l'ultimo tratto che si muove
	local ax, ay, dir = pts[n].x, pts[n].y, 0
	for i = n, 1, -1 do
		local bx, by = i > 1 and pts[i - 1].x or px, i > 1 and pts[i - 1].y or py
		if bx ~= ax or by ~= ay then
			dir = atan2(ay - by, ax - bx)
			break
		end
	end
	-- i puntini da mezzo passo dopo la bocca fino a un passo prima della punta
	local k, d, fatto = 0, passo * 0.5, 0
	x0, y0 = px, py
	for i = 1, n do
		local x1, y1 = pts[i].x, pts[i].y
		local dx, dy = x1 - x0, y1 - y0
		local l = sqrt(dx * dx + dy * dy)
		while l > 0 and d <= fatto + l and d <= lung - passo and k < maxn do
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
	return k, ax, ay, dir
end

local function disco(d, colore)
	local n = ui.disco(0, 0, d, colore)
	gui.set_adjust_mode(n, gui.ADJUST_FIT)
	gui.set_enabled(n, false)
	return n
end

-- la punta: uno spicchio di torta stretto, col vertice al centro del nodo e
-- la pancia che si apre all'indietro
local SPICCHIO = 50
local function spicchio(r, colore)
	local n = disco(2 * r, colore)
	gui.set_fill_angle(n, SPICCHIO)
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
	m.punta = { spicchio(PUNTA_OMBRA, OMBRA), spicchio(PUNTA_LUCE, LUCE), spicchio(PUNTA, LUCE) }
	for _, n in ipairs(m.punta) do m.nodi[#m.nodi + 1] = n end

	-- il cartellino: carbone col bordo chiaro, gradi a sinistra, potenza a destra
	local c = {}
	c.radice = gui.new_box_node(V, V)
	gui.set_visible(c.radice, false)
	gui.set_adjust_mode(c.radice, gui.ADJUST_FIT)
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
	gui.set_enabled(c.radice, false)
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

function M.freccia(m, pts, n, s, colore, sagoma)
	local k, ax, ay, dir = M.posa(pts, n, M.PASSO / s, M.PUNTI, sagoma, m.out)
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
	local punta = ax ~= nil
	-- lo spicchio parte dall'angolo 0 e gira di SPICCHIO: va centrato all'indietro
	E.z = punta and deg(dir) + 180 - SPICCHIO / 2 or 0
	for i, t in ipairs(m.punta) do
		gui.set_enabled(t, punta)
		if punta then
			-- la punta un passo oltre l'ultimo punto; ombra e bordo un poco più
			-- avanti, così il bordo gira attorno al vertice
			local avanti = (8 + (3 - i) * 3) / s
			sposta(t, ax + math.cos(dir) * avanti, ay + math.sin(dir) * avanti, scala)
			gui.set_euler(t, E)
		end
	end
	gui.set_color(m.punta[3], colore)
end

function M.cartellino(m, x, y, s, gradi, potenza, colore)
	local c = m.c
	local testo = gradi .. "°"
	if c.testo ~= testo then
		gui.set_text(c.gradi, testo)
		c.testo = testo
	end
	local con = potenza ~= nil
	if c.con ~= con then
		-- solo i gradi: il cartellino si stringe
		local w = con and 120 or 64
		V.x, V.y, V.z = w, 34, 0
		gui.set_size(c.fondo, V)
		gui.set_size(c.bordo, V)
		V.x, V.y = con and -28 or 0, 1
		gui.set_position(c.gradi, V)
		gui.set_enabled(c.riga, con)
		gui.set_enabled(c.barra.nodo, con)
		gui.set_enabled(c.potenza, con)
		c.con = con
	end
	if con then
		local p = floor(potenza * 100 + 0.5)
		if c.p ~= p then
			gui.set_text(c.potenza, p .. "%")
			ui.barra_valore(c.barra, potenza)
			c.p = p
		end
		gui.set_color(c.barra.pieno, colore)
	end
	-- il fondo del cartellino su (x, y), 17 pixel sotto il centro
	sposta(c.radice, x, y + 17 / s, 1 / s)
	gui.set_enabled(c.radice, true)
end

function M.freccia_via(m)
	for i = 1, M.PUNTI do
		gui.set_enabled(m.ombre[i], false)
		gui.set_enabled(m.luci[i], false)
	end
	for _, t in ipairs(m.punta) do gui.set_enabled(t, false) end
end

function M.cartellino_via(m)
	gui.set_enabled(m.c.radice, false)
end

return M
