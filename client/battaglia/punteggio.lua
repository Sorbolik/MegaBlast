-- I punti della partita sullo schermo (docs/decisioni/interfaccia.md, 29 ottobre):
-- in alto al centro la classifica, che si capisce senza leggere.
--
-- - Tutti contro tutti: un gettone per squadra in ordine di posto, che scivolano
--   quando la classifica cambia; il tuo ha il bordo spesso, il primo la Corona.
-- - Due squadre (1 contro 1, 2 contro 2): il tiro alla fune, una barra coi due
--   colori che si sposta verso chi è avanti, coi punti ai due capi.
-- - Ogni punto nasce dove succede (sul colpito, sul tuo scudo) e vola nel
--   gettone di chi lo prende; lì il numero sale con un ticchettio che si alza.
-- - Sotto il tuo gettone il distacco (dal primo, o sul secondo se sei primo);
--   a fine turno una riga col bilancio del turno, che svanisce da sola.
-- - Sopra la testa di ognuno il posto e la Corona (targa.posto).
--
--   local p = punteggio.nuovo(colori, tick)  -- in init; tick(velocita) suona un punto
--   punteggio.partita(p, g, nomi, targhe)    -- a ogni partita nuova; nomi delle squadre
--   punteggio.punti(p, e, x, y)              -- evento "points": x, y sullo schermo dove nasce
--   punteggio.turno(p, g)                    -- evento "turn"
--   punteggio.update(p, dt, g, mio)          -- ogni frame; mio: il robot di chi guarda
--   punteggio.obiettivo(p, testo)            -- nelle missioni: cosa resta da fare, fisso sotto i punti (nil = niente)
--   punteggio.set_enabled(p, on)
--
-- I numeri in volo restano fuori dai gettoni finché non arrivano: il gettone
-- mostra i punti veri meno quelli ancora in volo, così online (dove i punti
-- arrivano con lo stato) e in locale si vede la stessa cosa.

local ui = require "ui.ui"
local targa = require "battaglia.targa"

local M = {}

local max, min, floor, abs = math.max, math.min, math.floor, math.abs

local SQUADRE = 4
-- centro della fila, centrata sullo schermo (M.cima); abbastanza in basso da
-- lasciare sopra il posto alla Corona
local CIMA = 38
local Y, MEZZO = 720 - CIMA, 640
local GET_W, GET_H, GET_GAP = 104, 30, 6
local STRISCIA, BORDO_MIO = 6, 3
-- due squadre: due gettoni dei punti e la fune in mezzo
local VAL_W, FUNE_W, FUNE_H, FUNE_GAP = 60, 250, 12, 8
local MORBIDO = 60                    -- coi primi punti la fune si sposta poco
local SCRITTA, PICCOLA = 0.8, 0.6     -- scale di ui.testo
local CORONA_SCALA = 1.4              -- larga circa 25 px (ui.corona)
local CORONA_Y = GET_H / 2 + 4
local VOLO_SCALA, ARRIVO_SCALA = 1.7, 0.8
local NASCE_T, VOLO_T, SALE = 0.5, 0.45, 24
local TURNO_T, TURNO_SVANISCE = 2.4, 0.8
local NUMERI = 8
local TICK_OGNI, TICK_PASSO = 0.045, 5  -- un tic ogni 5 punti, non più spesso di così

local V = vmath.vector3(0, 0, 0)
local C = vmath.vector4(1, 1, 1, 1)

local function radice(x, y)
	local r = gui.new_box_node(vmath.vector3(x, y, 0), vmath.vector3(0, 0, 0))
	gui.set_adjust_mode(r, gui.ADJUST_FIT)
	gui.set_visible(r, false)
	return r
end

local function box(parent, x, y, w, h, colore)
	local n = gui.new_box_node(vmath.vector3(x, y, 0), vmath.vector3(w, h, 0))
	gui.set_parent(n, parent)
	gui.set_inherit_alpha(n, true)
	gui.set_color(n, colore)
	return n
end

local function dimensione(n, w, h)
	V.x, V.y, V.z = w, h, 0
	gui.set_size(n, V)
end

local function posizione(n, x, y)
	V.x, V.y, V.z = x, y, 0
	gui.set_position(n, V)
end

local function scala(n, s)
	V.x, V.y, V.z = s, s, 1
	gui.set_scale(n, V)
end

local function arrotonda(v) return floor(v + 0.5) end

local function con_segno(v)
	v = arrotonda(v)
	return (v > 0 and "+" or "") .. v
end

-- un gettone: bordo (chiaro e spesso il tuo), fondo, striscia nel colore della squadra,
-- posto, Corona e punti
local function gettone(colore)
	local gt = { colore = colore, x = 0, tx = 0, mostra = 0, bump = 0, w = GET_W }
	gt.radice = radice(0, Y)
	gt.dentro = box(gt.radice, 0, 0, 0, 0, vmath.vector4(1, 1, 1, 1))
	gui.set_visible(gt.dentro, false)
	gt.bordo = box(gt.dentro, 0, 0, GET_W + 2 * BORDO_MIO, GET_H + 2 * BORDO_MIO, ui.C.LUCE)
	gt.fondo = box(gt.dentro, 0, 0, GET_W, GET_H, ui.C.PANNELLO)
	gt.striscia = box(gt.dentro, -GET_W / 2 + STRISCIA / 2, 0, STRISCIA, GET_H, colore)
	gt.posto = ui.testo("", -GET_W / 2 + STRISCIA + 6, 0, SCRITTA, colore, gt.dentro)
	gui.set_pivot(gt.posto, gui.PIVOT_W)
	-- la Corona del primo: grande, appoggiata sul bordo in alto del gettone
	gt.corona = ui.corona(0, CORONA_Y, nil, gt.dentro)
	scala(gt.corona, CORONA_SCALA)
	gt.valore = ui.testo("0", GET_W / 2 - 8, 0, SCRITTA, ui.C.TESTO, gt.dentro)
	gui.set_pivot(gt.valore, gui.PIVOT_E)
	return gt
end

-- larghezza del gettone; la striscia sta dal lato di fuori (destra: a destra)
local function forma(gt, w, destra)
	gt.w = w
	gt.mio = nil
	dimensione(gt.fondo, w, GET_H)
	posizione(gt.striscia, (destra and 1 or -1) * (w / 2 - STRISCIA / 2), 0)
	if w == GET_W then
		posizione(gt.valore, w / 2 - 8, 0)
		gui.set_pivot(gt.valore, gui.PIVOT_E)
	else
		-- capo della fune: il numero al centro
		posizione(gt.valore, (destra and -1 or 1) * STRISCIA / 2, 0)
		gui.set_pivot(gt.valore, gui.PIVOT_CENTER)
	end
end

function M.nuovo(colori, tick)
	local p = { gettoni = {}, numeri = {}, tick = tick, tick_t = 0, tick_n = 0, on = true }
	for t = 1, SQUADRE do p.gettoni[t] = gettone(colori[t]) end

	-- la fune
	p.fune = radice(MEZZO, Y)
	box(p.fune, 0, 0, FUNE_W + 4, FUNE_H + 4, ui.C.OMBRA)
	p.fune_a = box(p.fune, -FUNE_W / 2, 0, FUNE_W / 2, FUNE_H, colori[1])
	gui.set_pivot(p.fune_a, gui.PIVOT_W)
	p.fune_b = box(p.fune, FUNE_W / 2, 0, FUNE_W / 2, FUNE_H, colori[2])
	gui.set_pivot(p.fune_b, gui.PIVOT_E)
	p.fune_segno = box(p.fune, 0, 0, 3, FUNE_H + 10, ui.C.LUCE)
	p.fune_f = 0.5

	-- distacco sotto il tuo gettone, bilancio del turno sotto la fila
	p.distacco = radice(0, Y - GET_H / 2 - 12)
	p.distacco_testo = ui.testo("", 0, 0, PICCOLA, ui.C.TESTO, p.distacco)
	p.riga = radice(MEZZO, Y - GET_H / 2 - 34)
	p.riga_testo = ui.testo("", 0, 0, PICCOLA, ui.C.LUCE, p.riga)
	p.riga_t = 0
	-- l'obiettivo della missione, sotto la riga del turno
	p.obiettivo = radice(MEZZO, Y - GET_H / 2 - 64)
	p.obiettivo_testo = ui.testo("", 0, 0, SCRITTA, ui.ORO, p.obiettivo)
	p.obiettivo_on = false

	-- i numeri che volano, sopra a tutto il resto
	for i = 1, NUMERI do
		local n = { nodo = ui.testo("", 0, 0, VOLO_SCALA, ui.C.TESTO), colore = vmath.vector4(1, 1, 1, 1) }
		gui.set_adjust_mode(n.nodo, gui.ADJUST_FIT)
		gui.set_enabled(n.nodo, false)
		p.numeri[i] = n
	end
	M.set_enabled(p, false)
	return p
end

-- La cima vera dello schermo (ui/schermo.lua: più in alto di 720 su un tablet)
function M.cima(p, y1)
	Y = y1 - CIMA
	posizione(p.fune, MEZZO, Y)
	posizione(p.riga, MEZZO, Y - GET_H / 2 - 34)
	posizione(p.obiettivo, MEZZO, Y - GET_H / 2 - 64)
	for _, gt in ipairs(p.gettoni) do
		if gt.x then posizione(gt.radice, gt.x, Y) end
	end
end

function M.obiettivo(p, testo)
	p.obiettivo_on = testo ~= nil
	if testo and testo ~= p.obiettivo_scritto then gui.set_text(p.obiettivo_testo, testo) end
	p.obiettivo_scritto = testo
	gui.set_enabled(p.obiettivo, p.on and p.obiettivo_on)
end

function M.set_enabled(p, on)
	p.on = on
	for t, gt in ipairs(p.gettoni) do gui.set_enabled(gt.radice, on and p.squadre and p.squadre[t] or false) end
	gui.set_enabled(p.fune, on and p.fune_on or false)
	gui.set_enabled(p.distacco, on)
	gui.set_enabled(p.riga, on and p.riga_t > 0)
	gui.set_enabled(p.obiettivo, on and p.obiettivo_on)
	if not on then
		for _, n in ipairs(p.numeri) do n.attivo = false; gui.set_enabled(n.nodo, false) end
	end
end

-- squadra -> punti veri (o, con volo, meno quelli ancora in aria)
local function punti_squadre(p, g, volo)
	local s = {}
	for t in pairs(p.squadre) do s[t] = 0 end
	for i, rb in ipairs(g.robots) do s[rb.team] = s[rb.team] + rb.points - (volo and p.volo[i] or 0) end
	return s
end

function M.partita(p, g, nomi, targhe)
	p.nomi, p.targhe, p.volo = nomi, targhe, {}
	p.squadre, p.lista = {}, {}
	for _, rb in ipairs(g.robots) do
		if not p.squadre[rb.team] then p.squadre[rb.team] = true; p.lista[#p.lista + 1] = rb.team end
	end
	table.sort(p.lista)
	p.fune_on = #p.lista == 2
	-- bordo sinistro della fila, così è centrata
	local n = #p.lista
	p.x0 = MEZZO - (p.fune_on and (2 * VAL_W + 2 * FUNE_GAP + FUNE_W) or (n * GET_W + (n - 1) * GET_GAP)) / 2
	for _, n in ipairs(p.numeri) do n.attivo = false; gui.set_enabled(n.nodo, false) end
	for i, t in ipairs(p.lista) do
		local gt = p.gettoni[t]
		gt.mostra, gt.bump = 0, 0
		gui.set_text(gt.valore, "0")
		gui.set_text(gt.posto, "")
		gui.set_enabled(gt.corona, false)
		if p.fune_on then
			-- i due capi della fune
			forma(gt, VAL_W, i == 2)
			gt.x = i == 1 and p.x0 + VAL_W / 2 or p.x0 + VAL_W + 2 * FUNE_GAP + FUNE_W + VAL_W / 2
		else
			forma(gt, GET_W, false)
			gt.x = p.x0 + GET_W / 2 + (i - 1) * (GET_W + GET_GAP)
		end
		gt.tx = gt.x
		posizione(gt.radice, gt.x, Y)
	end
	if p.fune_on then
		gui.set_color(p.fune_a, p.gettoni[p.lista[1]].colore)
		gui.set_color(p.fune_b, p.gettoni[p.lista[2]].colore)
	end
	p.fune_f, p.riga_t = 0.5, 0
	p.inizio = punti_squadre(p, g)
	p.di_turno = g.robots[g.current] and g.robots[g.current].team
	for i in ipairs(g.robots) do targa.posto(targhe[i], "", false) end
	p.posti = {}
	M.set_enabled(p, p.on)
end

-- un numero nasce in x, y (schermo); se lo stesso robot ne ha uno appena nato
-- dallo stesso colpo (danno e uccisione insieme) si somma a quello
function M.punti(p, e, x, y)
	if not p.squadre or e.amount == 0 then return end
	local r = e.robot
	p.volo[r] = (p.volo[r] or 0) + e.amount
	for _, n in ipairs(p.numeri) do
		if n.attivo and n.fase == 1 and n.chi == r and n.altro == e.other then
			n.punti, n.t = n.punti + e.amount, 0
			gui.set_text(n.nodo, con_segno(n.punti))
			return
		end
	end
	local n
	for _, m in ipairs(p.numeri) do
		if not m.attivo then n = m; break end
	end
	if not n then
		-- tutti in aria: il più vecchio arriva subito
		n = p.numeri[1]
		for _, m in ipairs(p.numeri) do if m.nato < n.nato then n = m end end
		p.volo[n.chi] = p.volo[n.chi] - n.punti
	end
	n.attivo, n.fase, n.t, n.chi, n.altro, n.punti, n.nato = true, 1, 0, r, e.other, e.amount, (p.nato or 0) + 1
	p.nato = n.nato
	n.x, n.y = x, y
	gui.set_text(n.nodo, con_segno(n.punti))
	gui.set_enabled(n.nodo, p.on)
end

-- a ogni turno nuovo, il bilancio di quello appena finito
function M.turno(p, g)
	if not p.squadre then return end
	local ora = punti_squadre(p, g)
	local t = p.di_turno
	if t and p.inizio[t] then
		local d = arrotonda(ora[t] - p.inizio[t])
		if d ~= 0 then
			gui.set_text(p.riga_testo, string.format("Turno di %s  %s", p.nomi[t], con_segno(d)))
			local c = p.gettoni[t].colore
			p.riga_colore = p.riga_colore or vmath.vector4(1, 1, 1, 1)
			p.riga_colore.x, p.riga_colore.y, p.riga_colore.z = c.x, c.y, c.z
			p.riga_t = TURNO_T
			gui.set_enabled(p.riga, p.on)
		end
	end
	p.inizio = ora
	p.di_turno = g.robots[g.current] and g.robots[g.current].team
end

local function arriva(p, n)
	n.attivo = false
	gui.set_enabled(n.nodo, false)
	p.volo[n.chi] = (p.volo[n.chi] or 0) - n.punti
	if abs(p.volo[n.chi]) < 1e-6 then p.volo[n.chi] = 0 end
end

-- dove arriva il numero di r: il suo gettone
local function bersaglio(p, g, r)
	local rb = g.robots[r]
	local gt = rb and p.gettoni[rb.team]
	if not gt then return 0, Y end
	return gt.x + (gt.w == GET_W and gt.w / 2 - 22 or 0), Y
end

local function numeri(p, dt, g)
	for _, n in ipairs(p.numeri) do
		if n.attivo then
			n.t = n.t + dt
			local rb = g.robots[n.chi]
			local c = rb and p.gettoni[rb.team] and p.gettoni[rb.team].colore or ui.C.TESTO
			if n.punti < 0 then c = ui.C.SPENTO end
			local s, x, y
			if n.fase == 1 then
				-- nasce: salta fuori grande e sale un poco
				local k = min(1, n.t / NASCE_T)
				s = VOLO_SCALA * (1 + 0.5 * max(0, 1 - n.t / 0.12))
				x, y = n.x, n.y + SALE * (1 - (1 - k) * (1 - k))
				if n.t >= NASCE_T then n.fase, n.t, n.x0, n.y0 = 2, 0, x, y end
			else
				-- vola nel gettone, sempre più veloce
				local k = min(1, n.t / VOLO_T)
				local e = k * k
				local tx, ty = bersaglio(p, g, n.chi)
				x, y = n.x0 + (tx - n.x0) * e, n.y0 + (ty - n.y0) * e
				s = VOLO_SCALA + (ARRIVO_SCALA - VOLO_SCALA) * e
				if k >= 1 then
					arriva(p, n)
					if rb and p.gettoni[rb.team] then p.gettoni[rb.team].bump = 1 end
				end
			end
			if n.attivo then
				posizione(n.nodo, x, y)
				scala(n.nodo, s * 0.5)
				C.x, C.y, C.z, C.w = c.x, c.y, c.z, 1
				gui.set_color(n.nodo, C)
			end
		end
	end
end

-- i posti: 1 + quante squadre hanno più punti; nessuno se sono tutti pari
local function posti(p, v)
	local out, pari = {}, true
	local primo = v[p.lista[1]]
	for _, t in ipairs(p.lista) do
		if v[t] ~= primo then pari = false end
	end
	for _, t in ipairs(p.lista) do
		local k = 1
		for _, u in ipairs(p.lista) do if v[u] > v[t] then k = k + 1 end end
		out[t] = not pari and k or nil
	end
	return out
end

function M.update(p, dt, g, mio)
	if not p.squadre or not p.on then return end
	numeri(p, dt, g)

	-- quello che i gettoni mostrano: i punti arrivati, arrotondati
	local v = punti_squadre(p, g, true)
	for t, x in pairs(v) do v[t] = arrotonda(x) end
	local pos = posti(p, v)
	local capo = g:leader()
	local primi = 0
	for _, t in ipairs(p.lista) do if pos[t] == 1 then primi = primi + 1 end end
	local mia = g.robots[mio] and g.robots[mio].team

	-- tutti contro tutti: i gettoni si mettono in fila per posto (a pari, per squadra)
	if not p.fune_on then
		local ordine = {}
		for i, t in ipairs(p.lista) do ordine[i] = t end
		table.sort(ordine, function(a, b)
			if v[a] ~= v[b] then return v[a] > v[b] end
			return a < b
		end)
		for i, t in ipairs(ordine) do p.gettoni[t].tx = p.x0 + GET_W / 2 + (i - 1) * (GET_W + GET_GAP) end
	end

	local tick = false
	for _, t in ipairs(p.lista) do
		local gt = p.gettoni[t]
		-- scivola al suo posto in meno di 200 ms
		gt.x = gt.x + (gt.tx - gt.x) * min(1, dt * 22)
		if abs(gt.tx - gt.x) < 0.5 then gt.x = gt.tx end
		posizione(gt.radice, gt.x, Y)
		-- il numero sale verso i punti arrivati, a scatti di TICK_PASSO
		if gt.mostra ~= v[t] then
			local d = v[t] - gt.mostra
			local passo = max(1, abs(d) * dt * 8, 40 * dt)
			local prima = gt.mostra
			gt.mostra = abs(d) <= passo and v[t] or gt.mostra + (d > 0 and passo or -passo)
			if d > 0 and floor(gt.mostra / TICK_PASSO) ~= floor(prima / TICK_PASSO) then tick = true end
			gui.set_text(gt.valore, tostring(arrotonda(gt.mostra)))
		end
		gt.bump = max(0, gt.bump - dt * 5)
		scala(gt.dentro, 1 + 0.18 * gt.bump)
		if gt.mio ~= (t == mia) then
			gt.mio = t == mia
			local b = gt.mio and BORDO_MIO or 1
			dimensione(gt.bordo, gt.w + 2 * b, GET_H + 2 * b)
			gui.set_color(gt.bordo, gt.mio and ui.C.LUCE or ui.C.LINEA)
		end
		local s = not p.fune_on and pos[t] and (pos[t] .. "°") or ""
		if gt.posto_s ~= s then gui.set_text(gt.posto, s); gt.posto_s = s end
		-- la Corona al gettone primo da solo, quando i suoi punti sono arrivati
		gui.set_enabled(gt.corona, pos[t] == 1 and primi == 1)
	end

	-- il ticchettio sale di tono finché i punti continuano ad arrivare
	p.tick_t = p.tick_t - dt
	if tick and p.tick_t <= 0 and p.tick then
		p.tick(1 + 0.05 * min(p.tick_n, 16))
		p.tick_n, p.tick_t = p.tick_n + 1, TICK_OGNI
	elseif not tick and p.tick_t < -0.4 then
		p.tick_n = 0
	end

	-- la fune: verso chi è avanti, ferma al centro quando sono pari
	if p.fune_on then
		local a, b = v[p.lista[1]], v[p.lista[2]]
		local f = 0.5 + 0.5 * (a - b) / (max(a, 0) + max(b, 0) + MORBIDO)
		f = max(0.04, min(0.96, f))
		p.fune_f = p.fune_f + (f - p.fune_f) * min(1, dt * 10)
		dimensione(p.fune_a, FUNE_W * p.fune_f, FUNE_H)
		dimensione(p.fune_b, FUNE_W * (1 - p.fune_f), FUNE_H)
		posizione(p.fune_segno, FUNE_W * (p.fune_f - 0.5), 0)
	end

	-- distacco sotto il tuo gettone
	local s = ""
	if mia and pos[mia] then
		local mio_v, altro = v[mia], nil
		for _, t in ipairs(p.lista) do
			if t ~= mia then
				if pos[mia] == 1 then
					if not altro or v[t] > altro then altro = v[t] end
				elseif pos[t] == 1 then
					altro = v[t]
				end
			end
		end
		if altro then
			if p.fune_on then
				s = con_segno(mio_v - altro)
			elseif mio_v == altro then
				s = "pari col 1°"
			else
				s = pos[mia] == 1 and string.format("+%d sul 2°", mio_v - altro) or string.format("%d dal 1°", mio_v - altro)
			end
		end
	end
	if p.distacco_s ~= s then gui.set_text(p.distacco_testo, s); p.distacco_s = s end
	if mia then posizione(p.distacco, p.gettoni[mia].x, Y - GET_H / 2 - 13) end

	-- la riga del turno resta un attimo e svanisce
	if p.riga_t > 0 then
		p.riga_t = p.riga_t - dt
		local c = p.riga_colore
		C.x, C.y, C.z, C.w = c.x, c.y, c.z, min(1, p.riga_t / TURNO_SVANISCE)
		gui.set_color(p.riga_testo, C)
		if p.riga_t <= 0 then gui.set_enabled(p.riga, false) end
	end

	-- posto e Corona sopra la testa
	for i, rb in ipairs(g.robots) do
		local k = pos[rb.team]
		local testo = k and (k .. "°") or ""
		local corona = capo == rb
		local key = testo .. (corona and "c" or "")
		if p.posti[i] ~= key then
			targa.posto(p.targhe[i], testo, corona)
			p.posti[i] = key
		end
	end
end

return M
