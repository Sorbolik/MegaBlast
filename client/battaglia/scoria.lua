-- Il diavoletto: il personaggio della battaglia, della home e del podio. È fatto
-- di pezzi disegnati a vettori (strumenti/grafica/diavoletto.py ->
-- battaglia/diavoletto.lua) e animati qui nel codice: niente fotogrammi, così
-- il movimento è fluido a qualsiasi frequenza e l'atlante pesa poco. Dai piedi
-- alla cima della testa è alto come il corpo della simulazione (ROBOT_H);
-- corna, coda e fiammella escono.
--
-- Lo usano la battaglia (game.gui_script), la home (menu/home.lua) e il podio:
--   local s = scoria.new(colore)
--   scoria.update(s, dt, stato)    -- a ogni frame, nessuna allocazione
--   scoria.set_weapon(s, nome) / hit(s, dx) / fire(s, tipo) / lunge(s) / die(s)
--   scoria.set_color(s, colore)    -- la squadra cambia da una partita all'altra
-- stato: x, y, facing, grounded, moving, aim (nil se non mira), turno (è di turno),
-- paracadute (appeso al paracadute aperto), vittoria (festeggia sul podio)
--
-- Pezzi: testa (con occhiali e corna, in quattro facce), busto, due gambe, due
-- braccia che pendono, l'ala, la coda in segmenti, la fiammella e il paracadute.
-- Chi è di turno (o mira) tiene l'arma: le braccia che pendono spariscono e
-- due avambracci vanno dalle spalle ai pugni sull'arma, che gira attorno alla
-- spalla verso la mira; la testa guarda dove si mira. Mirando (o colpendo) la
-- mira vince su tutto tranne la sconfitta: anche in aria, correndo o colpiti.
--
-- Il movimento è fatto di molle (schiaccia e allunga, inclinazione, spinta del
-- colpo, rinculo, testa, coda, fiammella) e di pose per stato, scelte in
-- ordine: sconfitta (cade all'indietro e svanisce), colpito (lampo bianco,
-- faccia colpita, braccia all'aria), paracadute (appeso alle cinghie, gambe
-- unite che dondolano), aria (gambe raccolte salendo, avanti scendendo, l'ala
-- sbatte), corsa (passi con la strada fatta, braccia opposte), vittoria (salta
-- con le braccia in alto), fermo (respira; chi non è di turno fa ogni tanto una
-- scenetta a caso: si gratta la testa, sbadiglia, guarda la coda). Spinto o
-- trascinato senza comandi non corre: resta fermo.
-- La fiammella ha il colore della squadra ed è l'indicatore di chi gioca: su chi
-- è di turno è grande e accesa, sugli altri piccola e più scura.

local game = require "sim.game"
local D = require "battaglia.diavoletto"
local DA = require("battaglia.armi").armi

local M = {}

local P, PT = D.pezzi, D.punti

local sin, cos, min, max, abs, pi, sqrt = math.sin, math.cos, math.min, math.max, math.abs, math.pi, math.sqrt
local atan2, acos = math.atan2, math.acos
local DEG = 180 / pi

local OMBRA = vmath.vector4(0, 0, 0, 0.35)
local BIANCO = vmath.vector4(1, 1, 1, 1)
-- quanto è bianco il lampo del colpo al massimo (1 tutto bianco)
local LAMPO = 0.85

-- le tre forme della fiammella, alternate a scatti
local FIAMME = { P.fiammella_1, P.fiammella_2, P.fiammella_3 }
-- la fiammella: quanto è grande su chi è di turno e sugli altri, con la luce
local FUOCO_TURNO, FUOCO_ATTESA, LUCE_ATTESA = 2.2, 0.8, 0.6

-- molle: posizione, velocità, rigidità, smorzamento
local SQ, LEAN, SHOVE, KICK, TESTA, CODA, FUOCO = 1, 2, 3, 4, 5, 6, 7
local W_MOLLA = { 16, 10, 12, 18, 11, 7, 6 }
local Z_MOLLA = { 0.3, 0.45, 0.5, 0.45, 0.28, 0.25, 0.4 }

-- altezza del diavoletto dai piedi alla cima della fiammella com'è ora (grande
-- su chi è di turno), per mettere sopra la targa
local CIMA_FIAMMA = (PT.collo[2] + PT.cima[2]) * game.ROBOT_H / D.altezza
local FIAMMA_H = P.fiammella_1.h * 0.8 * game.ROBOT_H / D.altezza
function M.altezza(s)
	return CIMA_FIAMMA + FIAMMA_H * s.x[FUOCO]
end

-- un passo: la strada che fa il corpo mentre una gamba fa un'oscillazione
-- intera, in altezze del personaggio
local PASSO = 0.9
-- quanto durano le azioni a tempo (secondi)
local DURATA = { colpito = 0.45 }
-- la testa guarda dove si mira, fino a questo angolo (radianti) in su e in giù
local TESTA_SU, TESTA_GIU = 0.45, 0.3
-- la sconfitta: cade in questo tempo, poi svanisce
local CADE, SVANISCE = 0.5, 0.6
-- fermo, chi non è di turno fa ogni tanto una scenetta a caso: fra una e l'altra
-- da PAUSA_DA a PAUSA_DA + PAUSA_A secondi (math.random: solo grafica, la
-- simulazione ha il suo generatore)
local PAUSA_DA, PAUSA_A = 3, 6
-- la velocità con cui si stacca da terra saltando
local V_SALTO = sqrt(2 * game.GRAVITY * game.base_stats().jump_height)

local V = vmath.vector3(0, 0, 0)
local C = vmath.vector4(0, 0, 0, 1)
local function pos(node, x, y)
	V.x, V.y, V.z = x, y, 0
	gui.set_position(node, V)
end
local function rot(node, rad)
	V.x, V.y, V.z = 0, 0, rad * DEG
	gui.set_euler(node, V)
end
local function scale(node, x, y)
	V.x, V.y, V.z = x, y, 1
	gui.set_scale(node, V)
end
local function size(node, w, h)
	V.x, V.y, V.z = w, h, 0
	gui.set_size(node, V)
end

local function setup(n, parent, color)
	if gui.set_inherit_alpha then gui.set_inherit_alpha(n, true) end
	if parent then gui.set_parent(n, parent) end
	if color then gui.set_color(n, color) end
	return n
end
local function box(parent, x, y, w, h, color)
	return setup(gui.new_box_node(vmath.vector3(x, y, 0), vmath.vector3(w, h, 0)), parent, color)
end
local function cerchio(parent, x, y, d, color)
	local n = setup(gui.new_pie_node(vmath.vector3(x, y, 0), vmath.vector3(d, d, 0)), parent, color)
	-- abbastanza lati da restare tondo anche grande, nella home
	gui.set_perimeter_vertices(n, 32)
	return n
end
-- un giunto: un nodo vuoto in (x, y) attorno a cui girano i pezzi figli
local function giunto(parent, x, y)
	local n = box(parent, 0, 0, 0, 0)
	pos(n, x, y)
	gui.set_visible(n, false)
	return n
end
-- un pezzo disegnato (p di diavoletto.lua), k unità del mondo per unità del
-- disegno, nel giunto parent; col lampo del colpo se non è tinto
local function pezzo(s, parent, p, k)
	local n = box(parent, p.x * k, p.y * k, p.w * k, p.h * k)
	gui.set_texture(n, "diavoletto")
	gui.play_flipbook(n, p.img)
	if p.tinta then
		local t = box(parent, p.x * k, p.y * k, p.w * k, p.h * k)
		gui.set_texture(t, "diavoletto")
		gui.play_flipbook(t, p.tinta)
		s.tinte[#s.tinte + 1] = t
	else
		gui.set_material(n, "lampo")
		s.lampi[#s.lampi + 1] = n
	end
	return n
end

-- Le armi in mano, attorno alla spalla: angolo di riposo (radianti, verso avanti).
-- Le immagini, i pugni e le misure sono in battaglia/armi.lua (strumenti/grafica/armi.py)
local ARMI = {
	missile = -0.35, sniper = -0.3, sword = -1.9, teleport = -0.5, grenade = -0.5, shards = -0.3,
	punch = -0.9, eagle = -0.6, hook = -0.4,
	mallet = 2,  -- in spalla: lungo com'è, in giù entrerebbe nel terreno
	lunge = 1.3,  -- dritta in su: in giù entrerebbe nel terreno
}
-- la mano sull'impugnatura, davanti alla spalla lungo l'arma (unità del mondo su 200)
local PRESA = 20

-- un'immagine dell'atlante delle armi, misure in unità del mondo
local function figura_arma(parent, img, x, y, w, h)
	local n = box(parent, x, y, w, h)
	gui.set_texture(n, "armi")
	gui.play_flipbook(n, img)
	return n
end

-- le armi sono grandi come il mondo, non come il corpo (game.CORPO): l'immagine,
-- sopra le parti col colore della squadra. I pugni li mettono le braccia.
local function arma(s, name, color)
	local a = DA[name]
	local g = giunto(s.spalla, 0, 0)
	figura_arma(g, a.img, a.x, a.y, a.w, a.h)
	if a.tinta then
		s.tinte_arma[#s.tinte_arma + 1] = setup(figura_arma(g, a.tinta, a.x, a.y, a.w, a.h), nil, color)
	end
	gui.set_enabled(g, false)
	s.armi[name] = g
end

-- un braccio sull'arma: braccio (spalla-gomito) e avambraccio (gomito-pugno),
-- prima i due bordi e poi i due colori così si fondono senza giunture (come la
-- coda); il pugno sta in pugno_parent, sopra l'arma. Il gioco lo piega col
-- gomito (piega) verso la mano sull'arma
local function braccio_arma(s, parent, pugno_parent, k, dietro)
	local b = { ossa = {} }
	local nomi = { "omero_bordo", "avambraccio_bordo", dietro and "omero_dietro" or "omero",
		dietro and "avambraccio_dietro" or "avambraccio" }
	for i = 1, 4 do
		local g = giunto(parent, 0, 0)
		pezzo(s, g, P[nomi[i]], k)
		b.ossa[i] = g
	end
	b.pugno = giunto(pugno_parent, 0, 0)
	pezzo(s, b.pugno, P.pugno, k)
	return b
end

function M.new(color)
	local H, Wd = game.ROBOT_H, 2 * game.ROBOT_HALF_W
	local k = H / D.altezza
	local s = { color = color, h = H, w = Wd, k = k, armi = {}, tinte = {}, tinte_arma = {}, lampi = {},
		x = {}, v = {}, goal = {}, coda = {}, coda_a = {},
		-- gli angoli (in radianti) e le mete delle braccia e delle gambe che pendono
		braccia = { 0, 0 }, gambe = { 0, 0 }, meta_braccia = { 0, 0 }, meta_gambe = { 0, 0 }, alza = { 0, 0 } }
	s.root = giunto(nil, 0, 0)
	gui.set_adjust_mode(s.root, gui.ADJUST_STRETCH)
	s.alpha = vmath.vector4(1, 1, 1, 1)
	s.lampo_col = vmath.vector4(1, 1, 1, 1)

	s.ombra = cerchio(s.root, 0, 0, Wd * 1.3, OMBRA)
	scale(s.ombra, 1, 0.22)
	-- il paracadute, dietro a tutto: dondola attorno al punto dove convergono le funi
	s.para = giunto(s.root, 0, D.paracadute_y * k)
	pezzo(s, s.para, P.paracadute, k)
	gui.set_enabled(s.para, false)
	-- corpo: inclinazione e spinta; forma: schiaccia e allunga. L'arma sta sul
	-- corpo e non sulla forma, così schiacciandosi non si storce la mira
	s.corpo = giunto(s.root, 0, 0)
	s.forma = giunto(s.corpo, 0, 0)

	-- dal fondo: la coda (prima tutti i bordi, poi tutti i colori: così i
	-- segmenti si fondono in una coda sola), l'ala, il braccio di dietro (quello
	-- che pende o l'avambraccio della mira), le gambe, il busto, la testa con la
	-- fiammella, il braccio davanti
	for strato = 1, 2 do
		local padre, x, y = s.forma, PT.coda[1] * k, PT.coda[2] * k
		for i = 1, #D.coda do
			padre = giunto(padre, x, y)
			pezzo(s, padre, P["coda_" .. i .. (strato == 1 and "_bordo" or "")], k)
			s.coda[i] = s.coda[i] or {}
			s.coda[i][strato] = padre
			x, y = D.coda[i] * k, 0
		end
	end
	s.ala = giunto(s.forma, PT.ala[1] * k, PT.ala[2] * k)
	pezzo(s, s.ala, P.ala, k)
	s.braccio_d = giunto(s.forma, -PT.spalle[1] * k, PT.spalle[2] * k)
	pezzo(s, s.braccio_d, P.braccio_dietro, k)
	s.gamba_d = giunto(s.forma, -PT.anche[1] * k, PT.anche[2] * k)
	pezzo(s, s.gamba_d, P.gamba_dietro, k)
	s.gamba_a = giunto(s.forma, PT.anche[1] * k, PT.anche[2] * k)
	pezzo(s, s.gamba_a, P.gamba, k)
	s.busto = giunto(s.forma, PT.bacino[1] * k, PT.bacino[2] * k)
	pezzo(s, s.busto, P.busto, k)
	-- l'arma gira attorno alla spalla, sul corpo (non sulla forma: schiacciandosi
	-- non si storce la mira); sopra, i pugni e il braccio davanti
	s.spalla = giunto(s.corpo, PT.spalla_arma[1] * k, PT.spalla_arma[2] * k)
	-- il braccio di dietro sull'impugnatura passa davanti al petto, sotto la
	-- testa: sta sulla forma, in un giunto che toglie la schiacciata
	s.arma_dietro = giunto(s.forma, 0, 0)
	s.mano_d = braccio_arma(s, s.arma_dietro, s.corpo, k, true)
	s.collo = giunto(s.forma, PT.collo[1] * k, PT.collo[2] * k)
	s.testa = pezzo(s, s.collo, P.testa, k)
	s.cima = giunto(s.collo, PT.cima[1] * k, PT.cima[2] * k)
	s.fuoco = pezzo(s, s.cima, P.fiammella_1, k)
	s.fuoco_tinta = s.tinte[#s.tinte]
	s.braccio_a = giunto(s.forma, PT.spalle[1] * k, PT.spalle[2] * k)
	pezzo(s, s.braccio_a, P.braccio, k)

	for name in pairs(ARMI) do arma(s, name, color) end
	-- i giunti dei pugni sono già sul corpo (prima dell'arma, dopo la forma):
	-- si spostano in coda così stanno sopra l'arma; poi il braccio davanti
	gui.set_parent(s.mano_d.pugno, s.corpo, false)
	s.mano_a = braccio_arma(s, s.corpo, s.corpo, k, false)
	gui.set_parent(s.mano_a.pugno, s.corpo, false)
	M.set_weapon(s, "missile")

	M.set_color(s, color, true)
	M.reset(s)
	return s
end

-- Ridipinge fiammella, paracadute e armi con il colore di un'altra squadra
function M.set_color(s, color, forza)
	if s.color == color and not forza then return end
	s.color = color
	C.x, C.y, C.z, C.w = color.x, color.y, color.z, 1
	for _, n in ipairs(s.tinte) do gui.set_color(n, C) end
	for _, n in ipairs(s.tinte_arma) do gui.set_color(n, C) end
end

-- il lampo del colpo: i pezzi diventano bianchi, a scendere. Lo fa il materiale
-- lampo (battaglia/lampo.fp): il verde del colore dice quanto è bianco
local function lampo(s, q)
	local c = s.lampo_col
	c.y = 1 - LAMPO * q
	for i = 1, #s.lampi do gui.set_color(s.lampi[i], c) end
end

local function faccia(s, nome)
	if s.faccia ~= nome then
		s.faccia = nome
		gui.play_flipbook(s.testa, P[nome].img)
	end
end

function M.reset(s)
	for i = 1, #W_MOLLA do s.x[i], s.v[i], s.goal[i] = 0, 0, 0 end
	s.x[SQ], s.x[FUOCO] = 1, 1
	s.t = math.random() * 10
	s.azione, s.azione_t = nil, 0
	s.vy, s.vx, s.last_x, s.last_y, s.ground = 0, 0, nil, nil, true
	s.passo, s.cammina, s.dondolo = 0, 0, 0
	for i = 1, 2 do s.braccia[i], s.gambe[i], s.alza[i] = 0, 0, 0 end
	for i = 1, #D.coda do s.coda_a[i] = D.coda_riposo[i] - (i > 1 and D.coda_riposo[i - 1] or 0) end
	s.flash, s.fuoco_n, s.fuoco_t = 0, 1, 0
	s.morte, s.morto = nil, nil
	s.scenetta, s.scenetta_t, s.n_scenette = nil, 0, 0
	s.pausa = PAUSA_DA + PAUSA_A * math.random()
	s.alpha.w = 1
	gui.set_color(s.root, s.alpha)
	rot(s.corpo, 0)
	scale(s.forma, 1, 1)
	lampo(s, 0)
	faccia(s, "testa")
	if s.arma_scelta then gui.set_enabled(s.armi[s.arma_scelta], true) end
	s.in_mano = nil
	s.face = 1
end

function M.set_enabled(s, on)
	if on and s.morte then M.reset(s) end
	gui.set_enabled(s.root, on)
end

local function molle(s, dt)
	local x, v, goal = s.x, s.v, s.goal
	local n = max(1, math.ceil(dt * 120))
	local h = dt / n
	for _ = 1, n do
		for i = 1, #W_MOLLA do
			local w, z = W_MOLLA[i], Z_MOLLA[i]
			v[i] = v[i] + (w * w * (goal[i] - x[i]) - 2 * z * w * v[i]) * h
			x[i] = x[i] + v[i] * h
		end
	end
end

-- Le scenette dell'attesa: ognuna dura un po' e dice, a u da 0 a 1, cosa fanno
-- testa, braccia e coda. Il braccio davanti alzato di pi va alla testa.
local SCENETTE = {
	-- si gratta la testa, guardando in su
	naso = { durata = 2.2, posa = function(s, u)
		local su = min(1, u * 4) * min(1, (1 - u) * 4)
		s.meta_braccia[1] = -(2.9 + sin(u * 40) * 0.12) * su
		s.posa_testa = 0.25 * su
	end },
	-- sbadiglia: testa all'indietro, bocca aperta, le braccia si stirano
	sbadiglio = { durata = 2.4, posa = function(s, u)
		local su = min(1, u * 3) * min(1, (1 - u) * 3)
		s.posa_testa = 0.35 * su
		s.meta_braccia[1], s.meta_braccia[2] = -0.7 * su, 0.7 * su
		s.posa_sq = 1 + 0.04 * su
		if u > 0.25 and u < 0.8 then s.posa_viso = "testa_colpita" end
	end },
	-- si gira a guardare la coda, che si agita
	coda = { durata = 2.0, posa = function(s, u)
		local su = min(1, u * 4) * min(1, (1 - u) * 4)
		s.posa_testa = 0.5 * su
		s.posa_coda = sin(u * 30) * 0.3 * su
	end },
}
local NOMI_SCENETTE = { "naso", "sbadiglio", "coda" }

local function attesa(s, dt)
	if s.scenetta then
		local sc = SCENETTE[s.scenetta]
		s.scenetta_t = s.scenetta_t + dt
		if s.scenetta_t < sc.durata then return sc.posa(s, s.scenetta_t / sc.durata) end
		s.scenetta, s.pausa = nil, PAUSA_DA + PAUSA_A * math.random()
	end
	s.pausa = s.pausa - dt
	if s.pausa <= 0 then
		s.scenetta, s.scenetta_t = NOMI_SCENETTE[math.random(#NOMI_SCENETTE)], 0
		s.n_scenette = s.n_scenette + 1
	end
end

-- la coda: un'onda che parte dalla schiena e arriva alla punta, più la molla CODA
-- (resta indietro correndo, frusta saltando e quando arriva un colpo). Ogni
-- segmento insegue il suo angolo un po' più piano del precedente: così il moto
-- arriva alla punta in ritardo
local function coda(s, dt)
	local base = s.x[CODA]
	local prima = 0
	for i = 1, #s.coda_a do
		local riposo = D.coda_riposo[i] - prima
		prima = D.coda_riposo[i]
		local a = riposo + (base + sin(s.t * 2.6 - i * 0.8) * 0.05) * (0.5 + 0.1 * i)
		s.coda_a[i] = s.coda_a[i] + (a - s.coda_a[i]) * min(1, dt * (18 - 2.5 * i))
		rot(s.coda[i][1], s.coda_a[i])
		rot(s.coda[i][2], s.coda_a[i])
	end
end

-- la fiammella: cambia forma a scatti (tre disegni), trema e su chi è di turno
-- si gonfia e si accende
local function fiammella(s, dt, turno)
	s.fuoco_t = s.fuoco_t + dt
	if s.fuoco_t > 0.09 then
		s.fuoco_t = 0
		local n = s.fuoco_n % #FIAMME + 1
		s.fuoco_n = n
		local p = FIAMME[n]
		gui.play_flipbook(s.fuoco, p.img)
		gui.play_flipbook(s.fuoco_tinta, p.tinta)
	end
	local f = s.x[FUOCO]
	local tr = sin(s.t * 11) * 0.06 + sin(s.t * 17.3) * 0.04
	scale(s.cima, f * (1 - tr * 0.5), f * (1 + tr))
	rot(s.cima, sin(s.t * 6.7) * 0.06)
	local l = turno and 1 or LUCE_ATTESA
	C.x, C.y, C.z, C.w = s.color.x * l, s.color.y * l, s.color.z * l, 1
	gui.set_color(s.fuoco_tinta, C)
end

-- un braccio piegato dalla spalla (sx, sy) al pugno (px, py), nel sistema del
-- corpo: il gomito sta dal lato destro della direzione spalla-pugno (in basso
-- mirando avanti, indietro mirando in giù, avanti mirando in su). Se il pugno
-- è più lontano di quanto il braccio arrivi, le ossa si allungano
local function piega(s, b, sx, sy, px, py)
	local l1, l2 = D.braccio[1] * s.k, D.braccio[2] * s.k
	local dx, dy = px - sx, py - sy
	local d = max(1e-6, sqrt(dx * dx + dy * dy))
	local f = max(1, d / (l1 + l2))
	l1, l2 = l1 * f, l2 * f
	local c = (d * d + l1 * l1 - l2 * l2) / (2 * d * l1)
	local ang = atan2(dy, dx) - acos(max(-1, min(1, c)))
	local ex, ey = sx + l1 * cos(ang), sy + l1 * sin(ang)
	local ang2 = atan2(py - ey, px - ex)
	local o = b.ossa
	for i = 1, 3, 2 do
		pos(o[i], sx, sy)
		rot(o[i], ang)
		scale(o[i], f, 1)
		pos(o[i + 1], ex, ey)
		rot(o[i + 1], ang2)
		scale(o[i + 1], f, 1)
	end
	pos(b.pugno, px, py)
end

-- una mano dell'arma (hx, hy, unità del mondo attorno alla spalla dell'arma,
-- girati con la mira) portata a portata del braccio dalla spalla (sx, sy):
-- scivola lungo l'arma verso la spalla dell'arma finché il braccio ci arriva
-- allungandosi al più di stira; torna il punto nel sistema del corpo. La mano
-- sulla canna può stare ovunque sul manico e non si stira; quella
-- sull'impugnatura resta sull'impugnatura finché il braccio si stira un po'
local STIRA_CANNA, STIRA_PRESA = 0.97, 1.35
local function a_portata(s, sx, sy, hx, hy, c, sn, stira)
	local spx, spy = s.spx, s.spy
	local r = (D.braccio[1] + D.braccio[2]) * s.k * stira
	-- il punto dell'asse dell'arma a hx = 0, dalla spalla del braccio
	local qx, qy = spx - hy * sn - sx, spy + hy * c - sy
	local lungo = qx * c + qy * sn
	local disc = lungo * lungo - (qx * qx + qy * qy) + r * r
	if disc > 0 then hx = max(0, min(hx, -lungo + sqrt(disc))) end
	return spx + hx * c - hy * sn, spy + hx * sn + hy * c
end

-- Le braccia sull'arma, piegate dalle spalle alle mani (battaglia/armi.lua):
-- con due mani quella davanti va sulla canna (la prima) e quella di dietro
-- sull'impugnatura (l'ultima); con una mano sola la tiene il braccio davanti e
-- quello di dietro pende; senza mani (il Pugno è un guanto) il braccio davanti
-- arriva al polsino, sulla spalla dell'arma. ox è il rinculo, lungo l'arma
local function braccia_arma(s, a, q, ox)
	local arma = DA[s.arma_scelta]
	local c, sn = cos(a), sin(a)
	local lx = (1 + (1 - q) * 0.8)
	s.spx, s.spy = PT.spalla_arma[1] * s.k * lx, PT.spalla_arma[2] * s.k * q
	local n = #arma.mani
	local sx, sy = PT.spalle[1] * s.k * lx, PT.spalle[2] * s.k * q
	local m = arma.mani[1]
	local px, py
	if m then
		px, py = a_portata(s, sx, sy, m[1] + ox, m[2], c, sn, n >= 2 and STIRA_CANNA or STIRA_PRESA)
	else
		px, py = s.spx + ox * c, s.spy + ox * sn
	end
	gui.set_enabled(s.mano_a.pugno, m ~= nil)
	piega(s, s.mano_a, sx, sy, px, py)
	s.pugno_presa = s.mano_a.pugno
	local due = n >= 2
	if s.due ~= due then
		s.due = due
		gui.set_enabled(s.arma_dietro, due)
		gui.set_enabled(s.mano_d.pugno, due)
		gui.set_enabled(s.braccio_d, not due)
	end
	if due then
		m = arma.mani[n]
		px, py = a_portata(s, -sx, sy, m[1] + ox, m[2], c, sn, STIRA_PRESA)
		scale(s.arma_dietro, 1 / lx, 1 / q)
		piega(s, s.mano_d, -sx, sy, px, py)
		s.pugno_presa = s.mano_d.pugno
	end
end

-- Sconfitta: l'arma cade, cade all'indietro con la faccia a X, la fiammella
-- si spegne, poi svanisce. Il terreno sotto può non esserci più (il cratere),
-- quindi niente resta appoggiato: tutto svanisce
local function morte(s, dt)
	local t = s.morte + dt
	s.morte = t
	local u = min(1, t / CADE)
	u = u * u * (3 - 2 * u)
	rot(s.corpo, u * 1.45)
	s.meta_gambe[1], s.meta_gambe[2] = 0.5 * u, 0.3 * u
	s.meta_braccia[1], s.meta_braccia[2] = 0.4 * u, -0.6 * u
	s.goal[FUOCO] = 0
	s.goal[TESTA] = -0.3 * u
	s.alpha.w = max(0, 1 - max(0, t - CADE - 0.3) / SVANISCE)
	gui.set_color(s.root, s.alpha)
	if s.alpha.w == 0 then
		s.morto = true
		gui.set_enabled(s.root, false)
	end
end

function M.update(s, dt, st)
	if s.morto then return end
	dt = min(dt, 1 / 20)
	s.t = s.t + dt
	local face = st.facing
	s.face = face
	scale(s.root, face, 1)
	pos(s.root, st.x, st.y)

	if s.last_y then
		local vy = (st.y - s.last_y) / max(dt, 1e-4)
		s.vy = s.vy + (vy - s.vy) * min(1, dt * 14)
		local vx = (st.x - s.last_x) / max(dt, 1e-4) * face
		if abs(vx) < 20 * s.h then s.vx = s.vx + (vx - s.vx) * min(1, dt * 8) end
	end
	local dx = s.last_x and abs(st.x - s.last_x) or 0
	s.last_x, s.last_y = st.x, st.y
	local ground = st.grounded

	-- passi: contano la strada fatta a terra (non i teletrasporti)
	local corre = ground and st.moving ~= 0 and dx < s.h and not s.morte
	if corre then s.passo = (s.passo + dx / (PASSO * s.h) * 2 * pi) % (2 * pi) end
	s.cammina = s.cammina + ((corre and 1 or 0) - s.cammina) * min(1, dt * 10)

	-- atterraggio e stacco: schiaccia e allunga, la testa fa un cenno, la coda frusta
	if ground and not s.ground and s.vy < -40 then
		s.v[SQ] = s.v[SQ] - min(7, -s.vy / 40)
		s.v[TESTA] = s.v[TESTA] - min(4, -s.vy / 80)
		s.v[CODA] = s.v[CODA] - min(3, -s.vy / 100)
	elseif not ground and s.ground and s.vy > 20 then
		s.v[SQ] = s.v[SQ] + 4
		s.v[CODA] = s.v[CODA] + 2
	end
	s.ground = ground
	if s.azione then s.azione_t = s.azione_t + dt end

	-- l'arma gira attorno alla spalla: verso la mira, altrimenti a riposo
	local a = ARMI[s.arma_scelta]
	if st.aim then a = face > 0 and st.aim or pi - st.aim end
	if a > pi then a = a - 2 * pi end
	local para = st.paracadute and not ground and not s.morte
	-- chi è di turno (o mira) tiene l'arma; da morto, sul podio e appeso al
	-- paracadute (le mani sono sulle cinghie) no
	local in_mano = (st.turno or st.aim ~= nil) and not s.morte and not st.vittoria and not para
	local mira = st.aim ~= nil and not s.morte and not para

	-- le mete di questo frame: a riposo, poi la posa dello stato le cambia
	local mb, mg = s.meta_braccia, s.meta_gambe
	mb[1], mb[2], mg[1], mg[2] = -0.12, 0.12, 0, 0
	s.alza[1], s.alza[2] = 0, 0
	local avanti = st.moving * face
	local lean = -0.22 * max(-1, min(1, avanti / 70)) * s.cammina
	local sq = 1 + 0.025 * sin(s.t * 2.4)
	-- la testa ondeggia nei passi; mirando guarda dove si mira
	local testa = sin(s.passo * 2) * 0.05 * s.cammina
	if mira then testa = max(-TESTA_GIU, min(TESTA_SU, a * 0.5)) end
	-- correndo la coda si allontana dal corpo, verso dietro, e torna quando ci si
	-- ferma; in aria segue la velocità
	local cd = 0.2 * max(-1, min(1, avanti / 70)) * s.cammina
	if not ground then cd = cd + max(-0.2, min(0.2, s.vy / 900)) end
	local ala = sin(s.t * 1.3) * 0.05
	local hop = 0
	local viso = "testa"
	gui.set_enabled(s.para, para)

	if s.morte then
		morte(s, dt)
		viso = "testa_ko"
	elseif s.azione == "colpito" and s.azione_t < DURATA.colpito then
		-- colpito: faccia colpita, braccia all'aria (se non tengono l'arma)
		viso = "testa_colpita"
		mb[1], mb[2] = -2.4, 2.4
	elseif para then
		-- appeso alle cinghie: gambe unite che dondolano, il paracadute inclinato
		-- contro la velocità, l'ala che sbatte piano
		s.dondolo = s.dondolo + (-max(-0.35, min(0.35, s.vx / 400)) - s.dondolo) * min(1, dt * 4)
		mb[1], mb[2] = 3.35, 2.93
		mg[1], mg[2] = 0.2 + sin(s.t * 3) * 0.08, 0.1 + sin(s.t * 3) * 0.08
		rot(s.para, s.dondolo * 0.6)
		ala = sin(s.t * 5) * 0.3
		lean = s.dondolo * 0.5
		sq = 1
	elseif not ground then
		-- in aria: salendo gambe raccolte e braccia indietro, scendendo gambe
		-- avanti per atterrare; l'ala sbatte
		local su = max(-1, min(1, s.vy / V_SALTO))
		mg[1], mg[2] = 0.45 * max(0, su) + 0.25 * max(0, -su), -0.3 * max(0, su) + 0.1 * max(0, -su)
		mb[1], mb[2] = -1.0, -0.6
		ala = sin(s.t * 14) * 0.45 - 0.2
		sq = 1 + min(0.2, abs(s.vy) / 900)
	elseif corre or s.cammina > 0.05 then
		-- la corsa: gambe e braccia opposte, il piede si alza quando torna avanti
		local c = s.cammina
		mg[1], mg[2] = sin(s.passo) * 0.6 * c, -sin(s.passo) * 0.6 * c
		s.alza[1], s.alza[2] = max(0, cos(s.passo)) * c, max(0, -cos(s.passo)) * c
		mb[1], mb[2] = -sin(s.passo) * 0.7 * c - 0.1, sin(s.passo) * 0.7 * c + 0.1
	elseif st.vittoria then
		-- festeggia: salta sul posto con le braccia in alto
		local u = (s.t * 1.6) % 1
		hop = sin(u * pi) * 12
		mb[1], mb[2] = 3.0 + sin(s.t * 9) * 0.3, 3.3 - sin(s.t * 9) * 0.3
		mg[1], mg[2] = 0.15 * hop / 12, -0.15 * hop / 12
		testa = sin(s.t * 3) * 0.1
		viso = "testa_felice"
	elseif not st.turno and not mira then
		-- fermo, non di turno: ogni tanto una scenetta
		s.posa_testa, s.posa_sq, s.posa_coda, s.posa_viso = nil, nil, nil, nil
		attesa(s, dt)
		testa = s.posa_testa or testa
		sq = s.posa_sq or sq
		cd = s.posa_coda or cd
		viso = s.posa_viso or viso
	end
	if not s.morte then
		s.goal[SQ], s.goal[LEAN], s.goal[TESTA], s.goal[CODA] = sq, lean, testa, cd
		s.goal[FUOCO] = st.turno and FUOCO_TURNO or FUOCO_ATTESA
	else
		s.goal[SQ], s.goal[LEAN], s.goal[CODA] = 1, 0, 0
	end
	faccia(s, viso)
	molle(s, dt)

	local q = max(0.4, s.x[SQ])
	local lx = 1 + (1 - q) * 0.8
	-- la testa non si schiaccia (i dettagli del disegno si vedrebbero storti):
	-- scende e sale con il busto
	scale(s.forma, lx, q)
	if not s.morte then rot(s.corpo, s.x[LEAN]) end
	pos(s.corpo, -s.x[SHOVE] * s.w, hop * s.k)
	scale(s.ombra, 1 + (1 - q) * 0.5, 0.22)

	-- braccia e gambe inseguono le mete; le gambe si alzano nei passi
	local segui = min(1, dt * 16)
	for i = 1, 2 do
		s.braccia[i] = s.braccia[i] + (mb[i] - s.braccia[i]) * segui
		s.gambe[i] = s.gambe[i] + (mg[i] - s.gambe[i]) * segui
	end
	rot(s.braccio_a, s.braccia[1])
	rot(s.braccio_d, s.braccia[2])
	rot(s.gamba_a, s.gambe[1])
	rot(s.gamba_d, s.gambe[2])
	pos(s.gamba_a, PT.anche[1] * s.k, (PT.anche[2] + s.alza[1] * 8) * s.k)
	pos(s.gamba_d, -PT.anche[1] * s.k, (PT.anche[2] + s.alza[2] * 8) * s.k)
	rot(s.ala, ala)
	coda(s, dt)
	-- la testa sobbalza a ogni passo
	local hy = (PT.collo[2] + abs(sin(s.passo)) * 4 * s.cammina) * s.k
	pos(s.collo, PT.collo[1] * s.k, hy)
	rot(s.collo, s.x[TESTA])
	scale(s.collo, 1 / lx, 1 / q)
	fiammella(s, dt, st.turno)

	-- lampo bianco del colpo
	if s.flash > 0 then
		s.flash = max(0, s.flash - dt * 6)
		lampo(s, min(1, s.flash * 1.5))
	end

	-- l'arma: in mano a chi è di turno o mira; le braccia vanno sull'arma
	if s.in_mano ~= in_mano then
		s.in_mano = in_mano
		gui.set_enabled(s.spalla, in_mano)
		for i = 1, 4 do gui.set_enabled(s.mano_a.ossa[i], in_mano) end
		gui.set_enabled(s.mano_a.pugno, in_mano)
		gui.set_enabled(s.braccio_a, not in_mano)
		if not in_mano then
			s.due = false
			gui.set_enabled(s.arma_dietro, false)
			gui.set_enabled(s.mano_d.pugno, false)
			gui.set_enabled(s.braccio_d, true)
		end
	end
	if in_mano then
		-- la spalla sale e scende con la forma; la spalla è dentro il corpo,
		-- che è inclinato: l'inclinazione non cambia la mira
		pos(s.spalla, PT.spalla_arma[1] * s.k * lx, PT.spalla_arma[2] * s.k * q)
		local aa = a - s.x[LEAN]
		rot(s.spalla, aa)
		-- il rinculo non porta mai la mano dietro la spalla
		local ox = -min(s.x[KICK] * s.w * 0.6, PRESA * s.h / 200 / game.CORPO * 0.8)
		pos(s.armi[s.arma_scelta], ox, 0)
		braccia_arma(s, aa, q, ox)
	end
end

function M.set_weapon(s, name)
	if s.arma_scelta == name or not s.armi[name] then return end
	if s.arma_scelta then gui.set_enabled(s.armi[s.arma_scelta], false) end
	s.arma_scelta = name
	-- da morto l'arma non c'è più
	gui.set_enabled(s.armi[name], not s.morte)
end

-- Colpo subito: lampo bianco, spinta e inclinazione nella direzione del colpo
-- (dx: verso dove spinge, nel mondo; senza, da davanti), schiacciata, testa che
-- scatta, coda che frusta
function M.hit(s, dx)
	if s.morte then return end
	local d = (dx and dx ~= 0) and (dx > 0 and 1 or -1) * s.face or -1
	s.flash = 1
	s.v[SHOVE] = s.v[SHOVE] - 9 * d
	s.v[SQ] = s.v[SQ] - 4
	s.v[LEAN] = s.v[LEAN] - 5 * d
	s.v[TESTA] = s.v[TESTA] - 8 * d
	s.v[CODA] = s.v[CODA] + 4 * d
	s.azione, s.azione_t = "colpito", 0
end

-- Colpo sparato: rinculo dell'arma lungo il suo asse (il corpo non si piega né
-- si schiaccia: sposterebbe la mano fuori dalla mira), testa e coda scattano
function M.fire(s, kind)
	local k = kind == "shards" and 0.5 or 1
	s.v[KICK] = s.v[KICK] + 14 * k
	s.v[TESTA] = s.v[TESTA] + 3 * k
	s.v[CODA] = s.v[CODA] - 1.5 * k
end

-- Scatto dell'Affondo: si allunga in avanti e si piega
function M.lunge(s)
	s.v[SQ] = s.v[SQ] + 6
	s.v[LEAN] = s.v[LEAN] + 8
	s.v[TESTA] = s.v[TESTA] + 4
	s.v[CODA] = s.v[CODA] - 3
end

-- Sconfitta: l'arma cade, cade all'indietro e svanisce
function M.die(s)
	if s.morte then return end
	s.morte = 0
	s.flash = 0
	s.azione = nil
	lampo(s, 0)
	faccia(s, "testa_ko")
	gui.set_enabled(s.para, false)
end

return M
