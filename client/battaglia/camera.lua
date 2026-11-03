-- Camera della battaglia: guarda un punto del mondo con uno zoom, e lo insegue
-- con una molla esponenziale (uguale a 60, 90 o 120 Hz).
--
-- Lo zoom è continuo (Sergio, 3 nov: «niente tre livelli, uno zoom a piacere»):
-- c.f va da 0 (lo zoom massimo, tutto lo spazio di gioco sullo schermo) a 1
-- (VICINO). Lo spazio di gioco lo dà la partita (M.spazio): dal pavimento più
-- basso alla piattaforma più alta, fra l'HUD in alto e quello in basso. Il
-- personaggio sta sempre al centro, anche vicino ai bordi della mappa (lì si
-- vede lo sfondo dipinto che continua); nell'ultimo tratto dello zoom il centro
-- scivola piano sullo spazio di gioco, e allo zoom massimo inquadra tutto.
--
-- Lua puro: game.gui_script la applica al nodo "mondo" della GUI e alla vista
-- del render (terreno). Da schermo a mondo: x = (sx - tx) / s.
--
--   local c = camera.new(1280, 720, 1920, 1080)   -- schermo, mappa
--   camera.vista(c, x0, y0, x1, y1)           -- lo schermo vero (ui/schermo.lua)
--   camera.spazio(c, x0, y0, x1, y1)          -- lo spazio di gioco (nil = la mappa)
--   camera.dal_terreno(c, terreno, sopra)     -- oppure misurato sul terreno
--   camera.segui(c, dt, x, y, zoom, veloce)   -- a ogni frame
--   camera.inquadra(c, dt, ax, ay, bx, by, zoom)  -- oppure: due punti insieme
--   camera.zoom(c)                            -- lo zoom scelto (c.f) adesso
--   camera.trascina(c, f) / camera.passo(c, d) / camera.alterna(c)
--   local tx, ty = camera.spostamento(c)      -- schermo = mondo * c.s + t
--   camera.scuoti(c, dx, dy, forza)           -- un colpo: scossa verso (dx, dy)
--   local ox, oy = camera.scossa(c, dt)       -- a ogni frame, pixel da aggiungere

local M = {}

-- lo zoom più vicino (unità dello schermo per unità del mondo)
M.VICINO = 2.2
-- i vecchi livelli (imposta zoom N negli scenari, le missioni che allargano):
-- 1 vicino, 2 medio (zoom 1), 3 lo zoom massimo
local MEDIO = 1
-- nell'ultimo VERSO_SPAZIO di c.f il centro scivola dal personaggio allo spazio di gioco
local VERSO_SPAZIO = 0.3

-- quanto in fretta la camera raggiunge il punto (1/s): più alto = più rigida
local SEGUI, SEGUI_VELOCE, ZOOM = 5, 9, 6
-- allontanarsi è più svelto di avvicinarsi, perché il colpo non scappi dallo schermo
local ZOOM_FUORI = 12
-- pixel dello schermo sotto lo spazio di gioco (la barra dell'HUD), sopra (i
-- punti) e ai lati. Con un po' di margine oltre l'HUD (Sergio, 3 nov: allo zoom
-- massimo i pulsanti a volte coprivano i personaggi): sotto la barra e le
-- levette, ai lati le colonne di pulsanti tondi che salgono più della barra
M.SOTTO = 150
M.SOPRA = 85
M.LATO = 44

local function clamp(v, a, b)
	return math.min(math.max(v, a), b)
end

-- w, h: lo schermo; mw, mh: la mappa
function M.new(w, h, mw, mh)
	local c = { w = w, h = h, cx = w / 2, cy = h / 2, mw = mw, mh = mh, x = mw / 2, y = mh / 2, s = 1,
		f = 1, f_prima = nil, sc_x = 0, sc_y = 0, sc_f = 0, sc_t = 0, mx = 120, msu = 90, mgiu = 170 }
	return c
end

-- Lo schermo vero in coordinate del gioco: più largo di w su un telefono 20:9,
-- più alto su un tablet 4:3 (ui/schermo.lua)
function M.vista(c, x0, y0, x1, y1)
	c.w, c.h, c.cx, c.cy = x1 - x0, y1 - y0, (x0 + x1) / 2, (y0 + y1) / 2
end

-- lo spazio di gioco in unità del mondo (nil: tutta la mappa)
function M.spazio(c, x0, y0, x1, y1)
	c.spazio = x0 and { x0 = x0, y0 = y0, x1 = x1, y1 = y1 } or nil
	if c.livello_n then c.livello_chiesto = c.livello_n end
end

-- Lo spazio di gioco misurato sul terreno, a inizio partita: dal pavimento più
-- basso (anche quelli sotto una piattaforma: ci si cammina) alla superficie più
-- alta, col posto sopra (sopra, unità del mondo) per un personaggio e la sua
-- targa. Una colonna ogni due celle: una superficie è una cella piena con
-- l'aria sopra
local SOTTO_TERRENO, LATI = 12, 10
function M.dal_terreno(c, t, sopra)
	local x0, x1, basso, alto
	local w, data = t.w, t.data
	for cx = 1, w - 2, 2 do
		for cy = 0, t.h - 2 do
			local i = cy * w + cx + 1
			if data[i] ~= 0 and data[i + w] == 0 then
				local y = (cy + 1) * t.cell
				x0, x1 = x0 or cx * t.cell, cx * t.cell
				basso, alto = math.min(basso or y, y), math.max(alto or y, y)
			end
		end
	end
	if not x0 then return M.spazio(c, nil) end
	M.spazio(c, math.max(0, x0 - LATI), math.max(0, basso - SOTTO_TERRENO),
		math.min(c.mw, x1 + LATI), math.min(c.mh, alto + sopra))
end

-- pixel dello schermo che l'inquadratura di due punti lascia liberi ai bordi
-- (ai lati, sopra, sotto): li dà chi disegna l'HUD, che sta sopra e sotto
function M.margini(c, x, su, giu)
	c.mx, c.msu, c.mgiu = x, su, giu
end

local function riquadro(c, intera)
	local sp = not intera and c.spazio
	if sp then return sp.x0, sp.y0, sp.x1, sp.y1 end
	return 0, 0, c.mw, c.mh
end

-- lo zoom con cui lo spazio di gioco (o, con intera, la mappa) entra fra l'HUD
-- in alto, quello in basso e i lati: il più lontano che la camera va
function M.tutta(c, intera)
	local x0, y0, x1, y1 = riquadro(c, intera)
	return math.min((c.w - 2 * M.LATO) / (x1 - x0), (c.h - M.SOTTO - M.SOPRA) / (y1 - y0))
end

-- dove guarda la camera allo zoom s per avere lo spazio di gioco nel mezzo fra l'HUD
local function centro_spazio(c, s, intera)
	local x0, y0, x1, y1 = riquadro(c, intera)
	return (x0 + x1) / 2, (y0 + y1) / 2 - (M.SOTTO - M.SOPRA) / (2 * s)
end

-- c.f (0 lo zoom massimo, 1 VICINO) in zoom, e il contrario: in mezzo va piano
-- uguale (logaritmico), così ogni tratto del dito cambia lo zoom della stessa parte
local function da_f(c, f)
	local t = M.tutta(c)
	if t >= M.VICINO then return t end
	return math.exp(math.log(t) + (math.log(M.VICINO) - math.log(t)) * f)
end

local function a_f(c, s)
	local t = M.tutta(c)
	if t >= M.VICINO then return 1 end
	return clamp((math.log(s) - math.log(t)) / (math.log(M.VICINO) - math.log(t)), 0, 1)
end

-- i vecchi livelli: 1 vicino, 2 medio, 3 lo zoom massimo. Il medio si calcola
-- quando serve, perché dipende dallo schermo e dalla mappa
-- Finché chi gioca non lo cambia, il livello vale per ogni partita: ogni spazio
-- di gioco nuovo lo ricalcola
function M.livello(c, n)
	c.livello_n, c.livello_chiesto = n, n
end

local function risolvi(c)
	local n = c.livello_chiesto
	if not n then return end
	c.livello_chiesto = nil
	c.f = n <= 1 and 1 or (n >= 3 and 0 or a_f(c, MEDIO))
end

-- lo zoom scelto, adesso
function M.zoom(c)
	risolvi(c)
	return da_f(c, c.f)
end

-- trascinando il pulsante (Z1): c.f nuovo
function M.trascina(c, f)
	risolvi(c)
	c.f, c.livello_n = clamp(f, 0, 1), nil
end

-- la rotella, i tasti: d positivo più vicino
function M.passo(c, d)
	M.trascina(c, c.f + d)
end

-- un tocco sul pulsante: dallo zoom scelto allo zoom massimo e ritorno
function M.alterna(c)
	risolvi(c)
	c.livello_n = nil
	if c.f > 0.02 then
		c.f_prima, c.f = c.f, 0
	else
		c.f = c.f_prima or a_f(c, MEDIO)
	end
end

-- una missione vuole vedere almeno fino al livello n: lo zoom si allarga
function M.allarga(c, n)
	risolvi(c)
	local f = n <= 1 and 1 or (n >= 3 and 0 or a_f(c, MEDIO))
	if f < c.f then c.f, c.livello_n = f, nil end
end

-- Va subito sul punto, senza inseguirlo (inizio partita, menu)
function M.salta(c, x, y, s)
	c.s = s
	c.x, c.y = x, y
end

-- quanto il centro va verso lo spazio di gioco: 0 finché lo zoom scelto è
-- sopra VERSO_SPAZIO, 1 allo zoom massimo
local function verso_spazio(c)
	if c.f >= VERSO_SPAZIO then return 0 end
	local k = 1 - c.f / VERSO_SPAZIO
	return k * k * (3 - 2 * k)
end

-- zoom e segui: rigidezza delle due molle (1/s)
local function verso(c, dt, x, y, s, zoom, segui)
	c.s = c.s + (s - c.s) * (1 - math.exp(-dt * zoom))
	local w = verso_spazio(c)
	if w > 0 then
		-- verso il centro dello spazio di gioco, ma il punto seguito resta sullo
		-- schermo (un cratere sotto il pavimento più basso, un colpo sul bordo)
		local bx, by = centro_spazio(c, c.s)
		local px, py = x, y
		x, y = x + (bx - x) * w, y + (by - y) * w
		local s = c.s
		x = clamp(x, px - (c.w / 2 - M.LATO) / s, px + (c.w / 2 - M.LATO) / s)
		y = clamp(y, py - (c.h / 2 - M.SOPRA) / s, py + (c.h / 2 - M.SOTTO) / s)
	end
	local k = 1 - math.exp(-dt * segui)
	c.x = c.x + (x - c.x) * k
	c.y = c.y + (y - c.y) * k
end

-- veloce: per i colpi in volo, che altrimenti scappano dallo schermo
function M.segui(c, dt, x, y, s, veloce)
	verso(c, dt, x, y, s, ZOOM, veloce and SEGUI_VELOCE or SEGUI)
end

-- Nel menu: tutta la mappa ferma nel mezzo
function M.mappa(c, dt)
	local s = M.tutta(c, true)
	local x, y = centro_spazio(c, s, true)
	c.s = c.s + (s - c.s) * (1 - math.exp(-dt * ZOOM))
	local k = 1 - math.exp(-dt * SEGUI)
	c.x, c.y = c.x + (x - c.x) * k, c.y + (y - c.y) * k
end

-- Tiene dentro due punti (chi ha sparato e il suo colpo): resta allo zoom s se
-- ci stanno, altrimenti si allontana quanto basta (al massimo lo zoom massimo).
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
	if m < c.s then c.s = math.max(M.tutta(c), m) end
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

return M
