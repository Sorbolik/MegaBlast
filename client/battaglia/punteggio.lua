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
-- - Due squadre: i turni vanno a coppie (Rosso, Blu). Il numero grande è il
--   punteggio a turni pari: i punti di chi ha aperto la coppia restano "in
--   attesa" in un gettone con la clessidra accanto al suo riquadro (e a righe
--   sulla fune) finché l'altra squadra non ha risposto; sotto quella compare
--   "+N PER PAREGGIARE" (Sergio, 31 ottobre: il distacco a metà giro non deve
--   demotivare). Sotto ogni riquadro un pallino per giocatore: pieno se in
--   questo giro ha già giocato.
-- - Ultimo giro (punti doppi, game.final_round): uno striscione d'oro, i
--   riquadri e i pallini d'oro, i numeri d'oro col loro ×2 (il numero è già doppio); nell'ultimo minuto
--   prima, sotto il tabellone, "TRA POCO: ULTIMO GIRO ×2".
--
--   local p = punteggio.nuovo(colori, tick)  -- in init; tick(velocita) suona un punto
--   punteggio.partita(p, g, nomi, targhe)    -- a ogni partita nuova; nomi delle squadre
--   punteggio.punti(p, e, x, y)              -- evento "points": x, y sullo schermo dove nasce
--   punteggio.turno(p, g)                    -- evento "turn"
--   punteggio.update(p, dt, g, mio)          -- ogni frame; mio: il robot di chi guarda
--   punteggio.obiettivo(p, testo)            -- nelle missioni: cosa resta da fare, fisso sotto i punti (nil = niente)
--   punteggio.ultimo_giro(p)                 -- evento "final_round": lo striscione
--   punteggio.set_enabled(p, on)
--   punteggio.nascondi(p, si)                -- le lezioni che non hanno ancora spiegato i punti: resta l'obiettivo
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
local FASCIA_W, FASCIA_PASSO, FASCIA_V = 4, 10, 16  -- fasce dei punti in attesa: larghe, ogni, px/s
local MORBIDO = 60                    -- coi primi punti la fune si sposta poco
local SCRITTA, PICCOLA = 0.8, 0.6     -- scale di ui.testo
local CORONA_SCALA = 1.4              -- larga circa 25 px (ui.corona)
local CORONA_Y = GET_H / 2 + 4
local VOLO_SCALA, ARRIVO_SCALA = 1.7, 0.8
local NASCE_T, VOLO_T, SALE = 0.5, 0.45, 24
local TURNO_T, TURNO_SVANISCE = 2.4, 0.8
local NUMERI = 8
local TICK_OGNI, TICK_PASSO = 0.045, 5  -- un tic ogni 5 punti, non più spesso di così
-- coppie di turni: gettone dei punti in attesa accanto al riquadro, pallini sotto
local ATTESA_W, ATTESA_H, ATTESA_GAP = 58, 24, 8
local PALLINO, PALLINO_GAP, PALLINO_Y = 10, 5, GET_H / 2 + 9
local SOTTO_Y = GET_H / 2 + 27              -- distacco e "+N PER PAREGGIARE", sotto i pallini
-- ultimo giro: lo striscione e l'avviso prima
local STRISCIONE_T, STRISCIONE_W, STRISCIONE_H = 2.6, 760, 112
local AVVISO_PRIMA = 60 * 60                -- tick di gioco prima dell'ultimo giro

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
	-- i punti in attesa: un gettone tratteggiato... a modo nostro, bordo nel
	-- colore della squadra, una clessidra (due barrette e una X) e il numero
	gt.attesa = radice(0, 0)
	gui.set_parent(gt.attesa, gt.radice)
	gui.set_visible(gt.attesa, false)
	local fondo, bordo = ui.pannello(0, 0, ATTESA_W, ATTESA_H, gt.attesa)
	gui.set_color(fondo, ui.C.PANNELLO)
	gui.set_color(bordo, colore)
	local cx = -ATTESA_W / 2 + 12
	box(gt.attesa, cx, 5, 9, 2, colore)
	box(gt.attesa, cx, -5, 9, 2, colore)
	for _, a in ipairs({ 50, -50 }) do
		local x = box(gt.attesa, cx, 0, 2, 11, colore)
		gui.set_euler(x, vmath.vector3(0, 0, a))
	end
	gt.attesa_testo = ui.testo("", 6, 0, PICCOLA, ui.C.TESTO, gt.attesa)
	gt.attesa_on = false
	gui.set_enabled(gt.attesa, false)
	-- i pallini dei turni del giro (al massimo due per squadra), sotto il riquadro
	gt.pallini = {}
	for i = 1, 2 do
		local pl = { anello = ui.anello(0, -PALLINO_Y, PALLINO, 2, colore, gt.radice) }
		pl.pieno = ui.disco(0, -PALLINO_Y, PALLINO - 3, colore, gt.radice)
		gui.set_enabled(pl.anello, false)
		gui.set_enabled(pl.pieno, false)
		gt.pallini[i] = pl
	end
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
	-- la parte della fune dei punti in attesa: come la fune, nel colore di chi
	-- li ha, ma a fasce diagonali che scorrono verso l'altra squadra (le fasce
	-- sono ritagliate dalla parte stessa, che fa da stampo)
	p.fune_attesa = box(p.fune, 0, 0, 0, FUNE_H, colori[1])
	gui.set_pivot(p.fune_attesa, gui.PIVOT_W)
	gui.set_clipping_mode(p.fune_attesa, gui.CLIPPING_MODE_STENCIL)
	gui.set_enabled(p.fune_attesa, false)
	p.fasce = {}
	for i = 1, math.ceil(FUNE_W / FASCIA_PASSO) + 3 do
		local f = box(p.fune_attesa, 0, 0, FASCIA_W, FUNE_H * 2.2, colori[1])
		gui.set_rotation(f, vmath.vector3(0, 0, 45))
		p.fasce[i] = f
	end
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
	-- "+N PER PAREGGIARE" sotto la squadra che deve rispondere
	p.pareggio = radice(0, Y - SOTTO_Y)
	p.pareggio_testo = ui.testo("", 0, 0, PICCOLA, ui.C.TESTO, p.pareggio)
	p.pareggio_s = ""
	-- prima dell'ultimo giro, sotto il tabellone
	p.avviso = radice(MEZZO, Y - GET_H / 2 - 62)
	ui.testo("TRA POCO: ULTIMO GIRO ×2", 0, 0, PICCOLA, ui.ORO, p.avviso)
	p.avviso_on = false
	gui.set_enabled(p.avviso, false)
	-- lo striscione dell'ultimo giro, al centro dello schermo
	p.striscione = radice(MEZZO, 400)
	box(p.striscione, 0, 0, STRISCIONE_W, STRISCIONE_H, vmath.vector4(0.16, 0.1, 0.02, 0.9))
	box(p.striscione, 0, STRISCIONE_H / 2, STRISCIONE_W, 3, ui.ORO)
	box(p.striscione, 0, -STRISCIONE_H / 2, STRISCIONE_W, 3, ui.ORO)
	ui.testo("ULTIMO GIRO", 0, 14, 2.4, ui.ORO, p.striscione)
	ui.testo("OGNI PUNTO VALE DOPPIO", 0, -32, 0.9, ui.C.TESTO, p.striscione)
	p.striscione_t = 0
	gui.set_inherit_alpha(p.striscione, true)
	gui.set_enabled(p.striscione, false)

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
	posizione(p.avviso, MEZZO, Y - GET_H / 2 - 62)
	posizione(p.striscione, MEZZO, y1 / 2 + 40)
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

-- Le lezioni che non hanno ancora spiegato i punti non li mostrano (sim/missioni.lua vedi)
function M.nascondi(p, si)
	p.nascosti = si
	M.set_enabled(p, p.on)
end

function M.set_enabled(p, on)
	p.on = on
	-- l'obiettivo resta anche senza i punti
	local punti = on and not p.nascosti
	for t, gt in ipairs(p.gettoni) do gui.set_enabled(gt.radice, punti and p.squadre and p.squadre[t] or false) end
	gui.set_enabled(p.fune, punti and p.fune_on or false)
	gui.set_enabled(p.distacco, punti)
	gui.set_enabled(p.riga, punti and p.riga_t > 0)
	gui.set_enabled(p.obiettivo, on and p.obiettivo_on)
	gui.set_enabled(p.pareggio, punti and p.pareggio_s ~= "")
	gui.set_enabled(p.avviso, punti and p.avviso_on and not p.obiettivo_on)
	gui.set_enabled(p.striscione, punti and p.striscione_t > 0)
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
			-- i due capi della fune; il gettone dei punti in attesa dal lato di fuori
			forma(gt, VAL_W, i == 2)
			gt.x = i == 1 and p.x0 + VAL_W / 2 or p.x0 + VAL_W + 2 * FUNE_GAP + FUNE_W + VAL_W / 2
			gt.attesa_x = (i == 1 and -1 or 1) * (VAL_W / 2 + ATTESA_GAP + ATTESA_W / 2)
			posizione(gt.attesa, gt.attesa_x, 0)
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
	p.striscione_t, p.ultimo = 0, nil
	for _, gt in ipairs(p.gettoni) do
		gt.attesa_on, gt.attesa_s, gt.pallini_s = false, nil, nil
		gui.set_enabled(gt.attesa, false)
		for _, pl in ipairs(gt.pallini) do gui.set_enabled(pl.anello, false); gui.set_enabled(pl.pieno, false) end
	end
	p.inizio = punti_squadre(p, g)
	p.di_turno = g.robots[g.current] and g.robots[g.current].team
	for i in ipairs(g.robots) do targa.posto(targhe[i], "", false) end
	p.posti = {}
	M.set_enabled(p, p.on)
end

-- un numero nasce in x, y (schermo); se lo stesso robot ne ha uno appena nato
-- dallo stesso colpo (danno e uccisione insieme) si somma a quello
function M.punti(p, e, x, y)
	if not p.squadre or p.nascosti or e.amount == 0 then return end
	local r = e.robot
	p.volo[r] = (p.volo[r] or 0) + e.amount
	for _, n in ipairs(p.numeri) do
		if n.attivo and n.fase == 1 and n.chi == r and n.altro == e.other then
			n.punti, n.t = n.punti + e.amount, 0
			gui.set_text(n.nodo, con_segno(n.punti) .. (n.doppio and " ×2" or ""))
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
	n.doppio = p.ultimo
	p.nato = n.nato
	n.x, n.y = x, y
	gui.set_text(n.nodo, con_segno(n.punti) .. (n.doppio and " ×2" or ""))
	gui.set_enabled(n.nodo, p.on)
end

-- Comincia l'ultimo giro: lo striscione d'oro
function M.ultimo_giro(p)
	if not p.squadre or p.nascosti then return end
	p.striscione_t = STRISCIONE_T
	gui.set_enabled(p.striscione, p.on)
end

-- a ogni turno nuovo, il bilancio di quello appena finito
function M.turno(p, g)
	if not p.squadre or p.nascosti then return end
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
	-- i punti in attesa vanno nel loro gettone, accanto al riquadro
	if gt.attesa_on then return gt.x + gt.attesa_x, Y end
	return gt.x + (gt.w == GET_W and gt.w / 2 - 22 or 0), Y
end

local function numeri(p, dt, g)
	for _, n in ipairs(p.numeri) do
		if n.attivo then
			n.t = n.t + dt
			local rb = g.robots[n.chi]
			local c = rb and p.gettoni[rb.team] and p.gettoni[rb.team].colore or ui.C.TESTO
			if n.punti < 0 then c = ui.C.SPENTO elseif n.doppio then c = ui.ORO end
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

-- I pallini dei turni della squadra t: uno per giocatore, nell'ordine dei
-- turni; pieno chi ha già giocato in questo giro, pulsa chi gioca adesso.
-- Nell'ultimo giro d'oro.
local function pallini(p, g, t, gt)
	local chi = {}
	for _, id in ipairs(g.order) do
		local rb = g.robots[id]
		if rb and rb.team == t and not rb.gone and #chi < #gt.pallini then chi[#chi + 1] = rb end
	end
	local key = (p.ultimo and "u" or "") .. #chi
	for _, rb in ipairs(chi) do key = key .. (rb.round_done and "1" or "0") end
	if gt.pallini_s ~= key then
		gt.pallini_s = key
		local col = p.ultimo and ui.ORO or gt.colore
		for i, pl in ipairs(gt.pallini) do
			local rb = chi[i]
			gui.set_enabled(pl.anello, rb ~= nil)
			gui.set_enabled(pl.pieno, rb ~= nil and rb.round_done or false)
			if rb then
				local x = (i - (#chi + 1) / 2) * (PALLINO + PALLINO_GAP)
				posizione(pl.anello, x, -PALLINO_Y)
				posizione(pl.pieno, x, -PALLINO_Y)
				gui.set_color(pl.anello, col)
				gui.set_color(pl.pieno, col)
			end
		end
	end
	for i, pl in ipairs(gt.pallini) do
		local rb = chi[i]
		scala(pl.anello, rb and rb.id == g.current and g.phase ~= "over" and 1.15 + 0.2 * math.sin(p.ora * 7) or 1)
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
	if not p.squadre or not p.on or p.nascosti then return end
	p.ora = (p.ora or 0) + dt
	numeri(p, dt, g)

	-- quello che i gettoni mostrano: i punti arrivati, arrotondati
	local v = punti_squadre(p, g, true)
	for t, x in pairs(v) do v[t] = arrotonda(x) end
	p.ultimo = g.final_round or nil
	-- coppie di turni: i punti di chi ha aperto la coppia oltre quelli che
	-- aveva allora restano in attesa; il resto del tabellone è a turni pari
	local attesa_t, attesa, vivo = nil, 0, nil
	if p.fune_on and (g.ahead or 0) > 0 and v[g.ahead] then
		local d = v[g.ahead] - arrotonda(g.ahead_base or 0)
		if d >= 1 then
			attesa_t, attesa = g.ahead, d
			vivo = { [p.lista[1]] = v[p.lista[1]], [p.lista[2]] = v[p.lista[2]] }
			v[attesa_t] = v[attesa_t] - d
		end
	end
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
		local k = (t == mia and 1 or 0) + (p.ultimo and 2 or 0)
		if gt.bordo_k ~= k then
			gt.bordo_k, gt.mio = k, t == mia
			local b = gt.mio and BORDO_MIO or 1
			dimensione(gt.bordo, gt.w + 2 * b, GET_H + 2 * b)
			-- nell'ultimo giro i riquadri sono d'oro
			gui.set_color(gt.bordo, p.ultimo and ui.ORO or gt.mio and ui.C.LUCE or ui.C.LINEA)
		end
		-- i punti in attesa accanto al riquadro
		local on = attesa_t == t
		if gt.attesa_on ~= on then gt.attesa_on = on; gui.set_enabled(gt.attesa, on) end
		if on then
			local s = "+" .. attesa
			if gt.attesa_s ~= s then gui.set_text(gt.attesa_testo, s); gt.attesa_s = s end
		end
		if p.fune_on then pallini(p, g, t, gt) end
		local s = not p.fune_on and pos[t] and (pos[t] .. "°") or ""
		if gt.posto_s ~= s then gui.set_text(gt.posto, s); gt.posto_s = s end
		-- la Corona al gettone primo da solo, quando i suoi punti sono arrivati
		-- (e dopo i primi giri senza Corona, come game:leader)
		gui.set_enabled(gt.corona, pos[t] == 1 and primi == 1 and (g.round or 1) > (g.score.crown_rounds or 0))
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
		-- dove sarebbe coi punti in attesa: una parte che pulsa nel colore di chi li ha
		local fv = p.fune_f
		if vivo then
			local va, vb = vivo[p.lista[1]], vivo[p.lista[2]]
			fv = max(0.04, min(0.96, 0.5 + 0.5 * (va - vb) / (max(va, 0) + max(vb, 0) + MORBIDO)))
		end
		p.fune_v = (p.fune_v or fv) + (fv - (p.fune_v or fv)) * min(1, dt * 10)
		local da, a2 = min(p.fune_f, p.fune_v), max(p.fune_f, p.fune_v)
		local on = vivo ~= nil and a2 - da > 0.002
		gui.set_enabled(p.fune_attesa, on)
		if on then
			posizione(p.fune_attesa, FUNE_W * (da - 0.5), 0)
			dimensione(p.fune_attesa, FUNE_W * (a2 - da), FUNE_H)
			-- fondo più scuro e fasce nel colore pieno della squadra
			if p.fasce_t ~= attesa_t then
				p.fasce_t = attesa_t
				local c = p.gettoni[attesa_t].colore
				C.x, C.y, C.z, C.w = c.x * 0.55, c.y * 0.55, c.z * 0.55, 1
				gui.set_color(p.fune_attesa, C)
				for _, f in ipairs(p.fasce) do gui.set_color(f, c) end
			end
			-- le fasce sono ferme rispetto alla fune e scorrono verso chi deve rispondere
			local verso = attesa_t == p.lista[1] and 1 or -1
			local x0 = (FUNE_W * (0.5 - da) + verso * p.ora * FASCIA_V) % FASCIA_PASSO - 2 * FASCIA_PASSO
			for i, f in ipairs(p.fasce) do posizione(f, x0 + (i - 1) * FASCIA_PASSO, 0) end
		end
	end

	-- "+N PER PAREGGIARE" sotto chi deve rispondere
	local altra
	if attesa_t then
		for _, t in ipairs(p.lista) do if t ~= attesa_t then altra = t end end
	end
	local ps = altra and string.format("+%d PER PAREGGIARE", attesa) or ""
	if p.pareggio_s ~= ps then
		gui.set_text(p.pareggio_testo, ps)
		if altra then gui.set_color(p.pareggio_testo, p.gettoni[altra].colore) end
		p.pareggio_s = ps
		gui.set_enabled(p.pareggio, ps ~= "")
	end
	if altra then posizione(p.pareggio, p.gettoni[altra].x, Y - SOTTO_Y) end

	-- prima dell'ultimo giro l'avviso
	local avviso = not p.ultimo and g.phase ~= "over" and g.match_left <= g:final_round_ticks() + AVVISO_PRIMA
	if p.avviso_on ~= avviso then
		p.avviso_on = avviso
		gui.set_enabled(p.avviso, avviso and not p.obiettivo_on)
	end

	-- lo striscione dell'ultimo giro entra di colpo e svanisce
	if p.striscione_t > 0 then
		p.striscione_t = p.striscione_t - dt
		local passato = STRISCIONE_T - p.striscione_t
		C.x, C.y, C.z, C.w = 1, 1, 1, min(1, passato / 0.15, max(0, p.striscione_t) / 0.6)
		gui.set_color(p.striscione, C)
		scala(p.striscione, 1 + 0.25 * max(0, 1 - passato / 0.2))
		if p.striscione_t <= 0 then gui.set_enabled(p.striscione, false) end
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
	-- sotto il mio riquadro il "+N PER PAREGGIARE" prende il posto del distacco
	if altra and altra == mia then s = "" end
	if p.distacco_s ~= s then gui.set_text(p.distacco_testo, s); p.distacco_s = s end
	if mia then posizione(p.distacco, p.gettoni[mia].x, Y - (p.fune_on and SOTTO_Y or GET_H / 2 + 13)) end

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
