-- Camera della battaglia: guarda un punto del mondo con uno zoom, e lo insegue
-- con una molla esponenziale (uguale a 60, 90 o 120 Hz). Non esce mai dai lati
-- e dalla cima della mappa; sotto scende di SOTTO pixel dello schermo, così il
-- fondo della mappa resta sopra l'HUD (sotto c'è il baratro, terreno.fp).
--
-- Lua puro: game.gui_script la applica al nodo "mondo" della GUI e alla vista
-- del render (terreno). Da schermo a mondo: x = (sx - tx) / s.
--
--   local c = camera.new(1280, 720, 1920, 1080)   -- schermo, mappa
--   camera.vista(c, x0, y0, x1, y1)           -- lo schermo vero (ui/schermo.lua)
--   camera.segui(c, dt, x, y, zoom, veloce)   -- a ogni frame
--   camera.inquadra(c, dt, ax, ay, bx, by, zoom)  -- oppure: due punti insieme
--   local tx, ty = camera.spostamento(c)      -- schermo = mondo * c.s + t
--   camera.scuoti(c, dx, dy, forza)           -- un colpo: scossa verso (dx, dy)
--   local ox, oy = camera.scossa(c, dt)       -- a ogni frame, pixel da aggiungere

local M = {}

-- livelli di zoom che si scelgono col pulsante, la rotella o il tasto Z
-- (MAPPA è 1280 / 1920: tutta la mappa sullo schermo)
M.LIVELLI = { 2.2, 1, 2 / 3 }
M.NOMI = { "VICINO", "MEDIO", "MAPPA" }

-- quanto in fretta la camera raggiunge il punto (1/s): più alto = più rigida
local SEGUI, SEGUI_VELOCE, ZOOM = 5, 9, 6
-- allontanarsi è più svelto di avvicinarsi, perché il colpo non scappi dallo schermo
local ZOOM_FUORI = 12
-- pixel dello schermo sotto la mappa: l'altezza della barra dell'HUD
M.SOTTO = 120

local function limita(c)
	local hw = c.w / (2 * c.s)
	c.x = math.min(math.max(c.x, hw), c.mw - hw)
	c.y = math.min(math.max(c.y, (c.h / 2 - M.SOTTO) / c.s), c.mh - c.h / (2 * c.s))
end

-- w, h: lo schermo; mw, mh: la mappa
function M.new(w, h, mw, mh)
	local c = { w = w, h = h, cx = w / 2, cy = h / 2, mw = mw, mh = mh, x = mw / 2, y = mh / 2, s = 1, livello = 1,
		sc_x = 0, sc_y = 0, sc_f = 0, sc_t = 0, mx = 120, msu = 90, mgiu = 170 }
	return c
end

-- Lo schermo vero in coordinate del gioco: più largo di w su un telefono 20:9,
-- più alto su un tablet 4:3 (ui/schermo.lua)
function M.vista(c, x0, y0, x1, y1)
	c.w, c.h, c.cx, c.cy = x1 - x0, y1 - y0, (x0 + x1) / 2, (y0 + y1) / 2
	limita(c)
end

-- pixel dello schermo che l'inquadratura di due punti lascia liberi ai bordi
-- (ai lati, sopra, sotto): li dà chi disegna l'HUD, che sta sopra e sotto
function M.margini(c, x, su, giu)
	c.mx, c.msu, c.mgiu = x, su, giu
end

-- lo zoom con cui si vede tutta la mappa (larga quanto lo schermo)
function M.tutta(c)
	return math.max(c.w / c.mw, c.h / c.mh)
end

-- Va subito sul punto, senza inseguirlo (inizio partita, menu)
function M.salta(c, x, y, s)
	c.x, c.y, c.s = x, y, s
	limita(c)
end

-- zoom e segui: rigidezza delle due molle (1/s)
local function verso(c, dt, x, y, s, zoom, segui)
	c.s = c.s + (s - c.s) * (1 - math.exp(-dt * zoom))
	local k = 1 - math.exp(-dt * segui)
	c.x = c.x + (x - c.x) * k
	c.y = c.y + (y - c.y) * k
	limita(c)
end

-- veloce: per i colpi in volo, che altrimenti scappano dallo schermo
function M.segui(c, dt, x, y, s, veloce)
	verso(c, dt, x, y, s, ZOOM, veloce and SEGUI_VELOCE or SEGUI)
end

-- Tiene dentro due punti (chi ha sparato e il suo colpo): resta allo zoom s se
-- ci stanno, altrimenti si allontana quanto basta (al massimo tutta la mappa).
-- Il centro sta nella parte di schermo libera dall'HUD.
function M.inquadra(c, dt, ax, ay, bx, by, s)
	local x0, x1 = math.max(0, math.min(ax, bx)), math.min(c.mw, math.max(ax, bx))
	local y0, y1 = math.max(0, math.min(ay, by)), math.min(c.mh, math.max(ay, by))
	local serve = math.min((c.w - 2 * c.mx) / math.max(1, x1 - x0),
		(c.h - c.msu - c.mgiu) / math.max(1, y1 - y0))
	s = math.max(M.tutta(c), math.min(s, serve))
	verso(c, dt, (x0 + x1) / 2, (y0 + y1) / 2 - (c.mgiu - c.msu) / (2 * c.s), s,
		s < c.s and ZOOM_FUORI or ZOOM, SEGUI_VELOCE)
	-- le molle arrivano in ritardo: se un punto sta per uscire si allontana subito
	local m = c.s
	for i = 1, 2 do
		local dx, dy = math.abs((i == 1 and x0 or x1) - c.x), (i == 1 and y0 or y1) - c.y
		if dx > 0 then m = math.min(m, (c.w / 2 - c.mx) / dx) end
		if dy > 0 then m = math.min(m, (c.h / 2 - c.msu) / dy) end
		if dy < 0 then m = math.min(m, (c.h / 2 - c.mgiu) / -dy) end
	end
	if m < c.s then
		c.s = math.max(M.tutta(c), m)
		limita(c)
	end
end

function M.spostamento(c)
	return c.cx - c.x * c.s, c.cy - c.y * c.s
end

function M.al_mondo(c, sx, sy)
	local tx, ty = M.spostamento(c)
	return (sx - tx) / c.s, (sy - ty) / c.s
end

function M.allo_schermo(c, x, y)
	local tx, ty = M.spostamento(c)
	return x * c.s + tx, y * c.s + ty
end

-- mai così lontano da vedere fuori dai lati della mappa (su uno schermo largo
-- il livello MAPPA diventa M.tutta)
function M.zoom(c)
	return math.max(M.LIVELLI[c.livello], M.tutta(c))
end

-- passo +1 = più lontano, -1 = più vicino
function M.cambia(c, passo)
	c.livello = math.min(#M.LIVELLI, math.max(1, c.livello + passo))
end

-- Scossa dello schermo: il colpo spinge lo schermo di 'forza' pixel nella
-- direzione (dx, dy), poi torna indietro oscillando e si smorza in fretta. Dipende
-- dal tempo e non dai fotogrammi, quindi è uguale a 60, 90 o 120 Hz.
local SC_OSCILLA, SC_SMORZA, SC_FINE = 32, 8, 0.6

local function forza_ora(c)
	if c.sc_t >= SC_FINE then return 0 end
	return c.sc_f * math.exp(-c.sc_t * SC_SMORZA)
end

-- se c'è ancora una scossa più forte vince quella
function M.scuoti(c, dx, dy, forza)
	if forza < forza_ora(c) then return end
	local l = math.sqrt(dx * dx + dy * dy)
	if l < 1e-6 then dx, dy, l = 0, -1, 1 end
	c.sc_x, c.sc_y, c.sc_f, c.sc_t = dx / l, dy / l, forza, 0
end

function M.scossa(c, dt)
	c.sc_t = c.sc_t + dt
	local f = forza_ora(c)
	if f == 0 then return 0, 0 end
	local t = c.sc_t * SC_OSCILLA
	-- lungo la direzione del colpo, più un po' di traverso perché non sembri una molla
	local a, b = f * math.cos(t), f * 0.3 * math.sin(t * 1.7)
	return c.sc_x * a - c.sc_y * b, c.sc_y * a + c.sc_x * b
end

-- il pulsante gira: vicino, medio, mappa, vicino...
function M.prossimo(c)
	c.livello = c.livello % #M.LIVELLI + 1
end

return M
