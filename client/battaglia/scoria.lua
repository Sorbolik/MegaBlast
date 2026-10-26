-- Il diavoletto: il personaggio della battaglia, della home e del podio, a
-- fotogrammi (fogli di Ludo.ai, strumenti/grafica/diavoletto.py ->
-- battaglia/diavoletto.lua). Dai piedi alla cima della testa è alto come il corpo
-- della simulazione (ROBOT_H); corna, coda e fiammella escono.
--
-- Lo usano la battaglia (game.gui_script), la home (menu/home.lua) e il podio:
--   local s = scoria.new(colore)
--   scoria.update(s, dt, stato)    -- a ogni frame, nessuna allocazione
--   scoria.set_weapon(s, nome) / hit(s) / fire(s, tipo) / lunge(s) / teleport(s) / die(s)
--   scoria.set_color(s, colore)    -- la squadra cambia da una partita all'altra
-- stato: x, y, facing, grounded, moving, aim (nil se non mira), turno (è di turno),
-- paracadute (appeso al paracadute aperto), vittoria (festeggia sul podio)
--
-- Un'animazione per stato, scelta in ordine: sconfitta (gira la testa, cade e si
-- addormenta, poi svanisce), teletrasporto (ricompare dalla scintilla), mira
-- (mirando o colpendo vince sul resto: in aria con le gambe raccolte, correndo
-- con la corsa in mira), colpito, paracadute (appeso, aperto), aria (salto, con il fotogramma
-- scelto dalla velocità in su o in giù), atterraggio, corsa (con la strada fatta;
-- chi è di turno corre con l'arma in mano), vittoria (il primo sul podio), mira
-- (chi è di turno, fermo) e attesa (gli altri: fermo, con ogni tanto una
-- scenetta a caso).
-- Nella mira il foglio non ha testa né braccia: il gioco ci mette la testa, che
-- guarda dove si mira, e pugni e arma, che girano attorno alla spalla. Nelle
-- altre animazioni il diavoletto ha le sue braccia e l'arma non si vede.
-- La fiammella sopra la testa ha il colore della squadra e dice il turno: su chi
-- gioca è più grande e accesa, sugli altri piccola e più scura.

local game = require "sim.game"
local config = require "sim.config"
local D = require "battaglia.diavoletto"

local M = {}

local A = D.animazioni
local T = D.testa
local K = game.ROBOT_H / D.altezza   -- unità del mondo per pixel delle immagini

local sin, min, max, abs, pi, floor, sqrt = math.sin, math.min, math.max, math.abs, math.pi, math.floor, math.sqrt
local DEG = 180 / pi

local INCHIOSTRO = vmath.vector4(0.078, 0.071, 0.094, 1)
local OMBRA = vmath.vector4(0, 0, 0, 0.35)
local BIANCO = vmath.vector4(1, 1, 1, 1)
local LAMPO = vmath.vector4(1, 0.35, 0.35, 1)
local PELLE = vmath.vector4(0.76, 0.72, 0.64, 1)
local FERRO = vmath.vector4(0.3, 0.29, 0.34, 1)
local LAMA = vmath.vector4(0.86, 0.88, 0.95, 1)

-- la fiammella: quanto sta sopra la cima della testa (pixel delle immagini) e
-- quanto è grande su chi è di turno e sugli altri, con la luce
local FUOCO_SU = 10
local FUOCO_TURNO, FUOCO_ATTESA, LUCE_ATTESA = 1.25, 0.8, 0.6
-- altezza del diavoletto in cima alla fiammella, per mettere sopra vita e freccia
M.ALTEZZA = (D.altezza + FUOCO_SU + A.fiammella[1].h * FUOCO_TURNO) * K

-- un giro della corsa: la strada che fa il corpo, in altezze del personaggio
local PASSO = 1.1
-- il salto: i primi fotogrammi sono in aria (dallo stacco alla caduta), gli
-- ultimi ARRIVO l'atterraggio
local ARIA, ARRIVO = 10, 8
-- quanto durano le azioni a tempo (secondi)
local DURATA = { colpito = 0.6, atterra = 0.3, teletrasporto = 0.6 }
-- la testa guarda dove si mira, fino a questo angolo (radianti) in su e in giù
local TESTA_SU, TESTA_GIU = 0.45, 0.3
-- da sconfitto, finita l'animazione (si addormenta), svanisce in questo tempo
local SVANISCE = 0.6
-- nell'attesa, ogni tanto una scenetta a caso: fra una e l'altra da DA a DA + A
-- secondi (math.random: solo grafica, la simulazione ha il suo generatore)
local SCENETTE = { "naso", "sbadiglio", "coda" }
local PAUSA_DA, PAUSA_A = 3, 6

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
local function vuoto(parent, x, y)
	local n = box(parent, 0, 0, 0, 0)
	pos(n, x, y)
	gui.set_visible(n, false)
	return n
end
local function immagine(parent, nome)
	local n = box(parent, 0, 0, 0, 0)
	gui.set_texture(n, "diavoletto")
	gui.play_flipbook(n, nome)
	return n
end
-- un fotogramma f (di diavoletto.lua) sul nodo n
local function fotogramma(n, f)
	gui.play_flipbook(n, f.img)
	size(n, f.w * K, f.h * K)
	pos(n, f.x * K, f.y * K)
end

-- Le armi in mano, attorno alla spalla: angolo di riposo (radianti, verso avanti)
local ARMI = {
	missile = { riposo = -0.35, due_mani = true },
	sword = { riposo = -1.9 },
	teleport = { riposo = -0.5 },
	grenade = { riposo = -0.5 },
	shards = { riposo = -0.3, due_mani = true },
	punch = { riposo = -0.9 },
	eagle = { riposo = -0.6 },
	hook = { riposo = -0.4 },
	mallet = { riposo = -1.6, due_mani = true },
	lunge = { riposo = -1.4, due_mani = true },
}
-- la mano sull'impugnatura, davanti alla spalla lungo l'arma (unità su 200)
local PRESA = 20

-- una mano staccata: un pugno color pelle (quella dei fogli di Ludo) col contorno scuro
local function mano(g, k, x, y)
	local d = 20 * k
	cerchio(g, x, y, d + 2 * 3 * k, INCHIOSTRO)
	cerchio(g, x, y, d, PELLE)
end

-- le armi e le mani sono grandi come il mondo, non come il corpo (game.CORPO)
local function arma(s, name, color)
	local H = s.h / game.CORPO
	local k = H / 200
	local g = vuoto(s.spalla, 0, 0)
	if name == "missile" then
		-- la bocca è dove la simulazione fa partire il colpo (game.MUZZLE)
		local L = game.MUZZLE
		box(g, L / 2, 0, L, H * 0.22, FERRO)
		s.tinte[#s.tinte + 1] = box(g, L - H * 0.05, 0, H * 0.1, H * 0.26, color)
	elseif name == "sword" then
		local L = game.SWORD_REACH
		box(g, L * 0.55, 0, L * 0.9, max(2, H * 0.1), LAMA)
		box(g, L * 0.08, 0, H * 0.08, H * 0.3, FERRO)
	elseif name == "shards" then
		box(g, H * 0.32, 0, H * 0.7, H * 0.3, FERRO)
	elseif name == "teleport" then
		s.tinte[#s.tinte + 1] = cerchio(g, H * 0.45, 0, H * 0.32, color)
	elseif name == "grenade" then
		cerchio(g, H * 0.45, 0, H * 0.36, FERRO)
	elseif name == "eagle" then
		-- Tonante: canna corta e grossa, il calcio in giù dietro la mano
		box(g, H * 0.5, H * 0.04, H * 0.6, H * 0.16, FERRO)
		box(g, H * 0.22, -H * 0.1, H * 0.1, H * 0.22, FERRO)
	elseif name == "hook" then
		-- Rampino: una canna sottile con l'uncino aperto in punta
		box(g, H * 0.45, 0, H * 0.7, max(2, H * 0.08), FERRO)
		box(g, H * 0.8, H * 0.08, max(2, H * 0.08), H * 0.2, LAMA)
	elseif name == "mallet" then
		-- Maglio: manico lungo con la testa pesante in punta
		local L = H * 1.1
		box(g, L * 0.5, 0, L, max(2, H * 0.08), FERRO)
		box(g, L, 0, H * 0.22, H * 0.4, FERRO)
		box(g, L + H * 0.06, 0, H * 0.06, H * 0.4, LAMA)
	elseif name == "lunge" then
		-- Affondo: lancia lunga e sottile, con la punta chiara
		local L = config.LUNGE.speed * config.LUNGE.ticks / 60 * 0.4
		box(g, L * 0.5, 0, L, max(2, H * 0.07), FERRO)
		box(g, L, 0, H * 0.18, max(2, H * 0.12), LAMA)
	else -- punch
		cerchio(g, H * 0.45, 0, s.w / game.CORPO * 0.8, FERRO)
	end
	-- le mani: la seconda sotto la canna, l'ultima sull'impugnatura (asse dell'arma)
	if ARMI[name].due_mani then mano(g, k, 58 * k, -14 * k) end
	mano(g, k, PRESA * k, 0)
	gui.set_enabled(g, false)
	s.armi[name] = g
end

function M.new(color)
	local H, Wd = game.ROBOT_H, 2 * game.ROBOT_HALF_W
	local s = { color = color, h = H, w = Wd, armi = {}, tinte = {} }
	s.root = vuoto(nil, 0, 0)
	gui.set_adjust_mode(s.root, gui.ADJUST_STRETCH)
	s.alpha = vmath.vector4(1, 1, 1, 1)
	s.fuoco_col = vmath.vector4(color.x, color.y, color.z, 1)

	s.ombra = cerchio(s.root, 0, 0, Wd * 1.3, OMBRA)
	scale(s.ombra, 1, 0.22)
	-- corpo: la spinta del colpo; dentro, in ordine di disegno, il fotogramma, la
	-- testa della mira sul suo collo, pugni e arma sulla spalla, la fiammella
	s.corpo = vuoto(s.root, 0, 0)
	s.figura = immagine(s.corpo, A.attesa[1].img)
	s.collo = vuoto(s.corpo, 0, 0)
	s.testa = immagine(s.collo, T.img)
	size(s.testa, T.w * K, T.h * K)
	pos(s.testa, T.x * K, T.y * K)
	s.spalla = vuoto(s.corpo, 0, 0)
	for name in pairs(ARMI) do arma(s, name, color) end
	s.fuoco = immagine(s.corpo, A.fiammella[1].img)
	gui.set_pivot(s.fuoco, gui.PIVOT_S)
	gui.set_color(s.fuoco, s.fuoco_col)
	M.set_weapon(s, "missile")

	M.reset(s)
	return s
end

-- Ridipinge la fiammella e le armi con il colore di un'altra squadra
function M.set_color(s, color)
	if s.color == color then return end
	s.color = color
	s.fuoco_col.x, s.fuoco_col.y, s.fuoco_col.z = color.x, color.y, color.z
	C.x, C.y, C.z, C.w = color.x, color.y, color.z, 1
	for _, n in ipairs(s.tinte) do gui.set_color(n, C) end
end

-- il lampo del colpo: corpo e testa tinti di rosso, a scendere
local function lampo(s, q)
	C.x, C.y, C.z, C.w = 1, 1 + (LAMPO.y - 1) * q, 1 + (LAMPO.z - 1) * q, 1
	gui.set_color(s.figura, C)
	gui.set_color(s.testa, C)
end

function M.reset(s)
	s.t = math.random() * 10
	s.azione, s.azione_t = nil, 0
	s.passo, s.vy, s.last_x, s.last_y, s.ground = 0, 0, nil, nil, true
	s.flash, s.spinta, s.rinculo, s.fuoco_k = 0, 0, 0, 1
	s.morte, s.morto, s.tele = nil, nil, nil
	s.scenetta, s.pausa = nil, PAUSA_DA + PAUSA_A * math.random()
	s.img, s.fuoco_img, s.mira = nil, nil, nil
	s.alpha.w = 1
	gui.set_color(s.root, s.alpha)
	if s.arma_scelta then gui.set_enabled(s.armi[s.arma_scelta], true) end
	lampo(s, 0)
	s.face = 1
end

function M.set_enabled(s, on)
	if on and s.morte then M.reset(s) end
	gui.set_enabled(s.root, on)
end

-- fotogramma di un'animazione a tempo dopo t secondi
local function a_tempo(anim, t)
	local i = floor(t * anim.fps)
	return anim.giro and 1 + i % #anim or 1 + min(i, #anim - 1)
end
-- fotogramma i (da 1) di un pezzo dell'animazione, da da a a, portato da 0 a 1
local function a_parte(da, a, u)
	return da + floor(max(0, min(0.999, u)) * (a - da + 1))
end

-- la velocità con cui si stacca da terra saltando, per il salto in aria
local V_SALTO = sqrt(2 * game.GRAVITY * game.base_stats().jump_height)

-- Mostra il fotogramma i dell'animazione nome; nella mira accende testa e arma
local function mostra(s, nome, i)
	local anim = A[nome] or A.attesa
	local f = anim[max(1, min(#anim, i))]
	if s.img ~= f.img then
		fotogramma(s.figura, f)
		s.img = f.img
	end
	local mira = f.cx ~= nil
	if s.mira ~= mira then
		s.mira = mira
		gui.set_enabled(s.collo, mira)
		gui.set_enabled(s.spalla, mira)
	end
	return f
end

-- L'attesa: fermo, e ogni tanto una scenetta a caso
local function attesa(s, dt)
	if s.scenetta then
		local an = A[s.scenetta]
		local i = 1 + floor(s.scenetta_t * an.fps)
		s.scenetta_t = s.scenetta_t + dt
		if i <= #an then return mostra(s, s.scenetta, i) end
		s.scenetta, s.pausa = nil, PAUSA_DA + PAUSA_A * math.random()
	end
	s.pausa = s.pausa - dt
	if s.pausa <= 0 then
		local nome = SCENETTE[math.random(#SCENETTE)]
		if A[nome] then s.scenetta, s.scenetta_t = nome, 0 end
		s.pausa = PAUSA_DA + PAUSA_A * math.random()
	end
	return mostra(s, "attesa", 1)
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
	end
	local dx = s.last_x and abs(st.x - s.last_x) or 0
	s.last_x, s.last_y = st.x, st.y
	local ground = st.grounded
	if ground and not s.ground and not s.morte then s.azione, s.azione_t = "atterra", 0 end
	s.ground = ground

	-- la corsa va con la strada fatta (non con i teletrasporti)
	local corre = ground and st.moving ~= 0 and dx < s.h
	if corre then s.passo = (s.passo + dx / (PASSO * s.h)) % 1 end

	-- il fotogramma: il primo stato che vale, in ordine
	local f
	if s.morte then
		s.morte = s.morte + dt
		local an = A.sconfitta
		f = mostra(s, "sconfitta", a_tempo(an, s.morte))
		-- finita l'animazione svanisce
		s.alpha.w = max(0, 1 - max(0, s.morte - #an / an.fps) / SVANISCE)
		gui.set_color(s.root, s.alpha)
		if s.alpha.w == 0 then
			s.morto = true
			gui.set_enabled(s.root, false)
			return
		end
	elseif s.tele then
		-- arrivo col teletrasporto: ricompare dalla scintilla
		s.tele = s.tele + dt
		f = mostra(s, "teletrasporto", a_parte(1, #A.teletrasporto, s.tele / DURATA.teletrasporto))
		if s.tele >= DURATA.teletrasporto then s.tele = nil end
	elseif st.aim and not ground and A.mira_aria then
		-- mirando (o colpendo) vince la mira, anche in aria (col suo foglio di
		-- gambe raccolte), correndo o colpiti
		f = mostra(s, "mira_aria", a_parte(1, #A.mira_aria, 0.5 - s.vy / (2 * V_SALTO)))
	elseif st.aim and corre and A.corsa_mira then
		f = mostra(s, "corsa_mira", a_parte(1, #A.corsa_mira, s.passo))
	elseif st.aim then
		f = mostra(s, "mira", a_tempo(A.mira, s.t))
	elseif s.azione == "colpito" and s.azione_t < DURATA.colpito then
		f = mostra(s, "colpito", a_parte(1, #A.colpito, s.azione_t / DURATA.colpito))
	elseif st.paracadute and not ground and A.paracadute then
		f = mostra(s, "paracadute", a_tempo(A.paracadute, s.t))
	elseif not ground then
		-- dallo stacco (velocità piena in su) alla caduta (piena in giù)
		f = mostra(s, "salto", a_parte(1, ARIA, 0.5 - s.vy / (2 * V_SALTO)))
	elseif s.azione == "atterra" and s.azione_t < DURATA.atterra then
		f = mostra(s, "salto", a_parte(ARIA + 1, ARIA + ARRIVO, s.azione_t / DURATA.atterra))
	elseif corre then
		-- sul proprio turno si corre con l'arma in mano (senza mirare)
		local nome = st.turno and A.corsa_mira and "corsa_mira" or "corsa"
		f = mostra(s, nome, a_parte(1, #A[nome], s.passo))
	elseif st.vittoria and A.vittoria then
		f = mostra(s, "vittoria", a_tempo(A.vittoria, s.t))
	elseif st.turno then
		f = mostra(s, "mira", a_tempo(A.mira, s.t))
	else
		f = attesa(s, dt)
	end
	if s.azione then s.azione_t = s.azione_t + dt end

	-- l'arma verso la mira, altrimenti a riposo; la testa guarda nella stessa
	-- direzione, un po' meno
	local a = ARMI[s.arma_scelta].riposo
	if st.aim then a = face > 0 and st.aim or pi - st.aim end
	if a > pi then a = a - 2 * pi end
	local ta = 0
	if s.mira then
		ta = st.aim and max(-TESTA_GIU, min(TESTA_SU, a * 0.5)) or 0
		pos(s.collo, f.cx * K, f.cy * K)
		rot(s.collo, ta)
		pos(s.spalla, f.sx * K, f.sy * K)
		rot(s.spalla, a)
		-- il rinculo non porta mai la mano dietro la spalla
		pos(s.armi[s.arma_scelta], -min(s.rinculo * s.w * 0.6, PRESA * s.h / 200 / game.CORPO * 0.8), 0)
	end

	-- la fiammella: sulla cima della testa (quella del foglio o quella della mira,
	-- che gira), trema con i suoi fotogrammi e su chi è di turno si gonfia
	local fx, fy
	if s.mira then
		local c, sn = math.cos(ta), sin(ta)
		fx = f.cx + T.tx * c - T.ty * sn
		fy = f.cy + T.tx * sn + T.ty * c
	else
		fx, fy = f.tx, f.ty
	end
	local fa = A.fiammella
	local ff = fa[a_tempo(fa, s.t)]
	if s.fuoco_img ~= ff.img then
		gui.play_flipbook(s.fuoco, ff.img)
		size(s.fuoco, ff.w * K, ff.h * K)
		s.fuoco_img = ff.img
	end
	local goal = st.turno and FUOCO_TURNO or FUOCO_ATTESA
	s.fuoco_k = s.fuoco_k + (goal - s.fuoco_k) * min(1, dt * 8)
	pos(s.fuoco, (fx + ff.x) * K, (fy + FUOCO_SU) * K)
	-- nel teletrasporto la fiammella cresce col diavoletto
	local q = s.tele and min(1, s.tele / DURATA.teletrasporto) or 1
	scale(s.fuoco, s.fuoco_k * q, s.fuoco_k * q)
	rot(s.fuoco, ta * 0.5)
	local l = st.turno and 1 or LUCE_ATTESA
	C.x, C.y, C.z, C.w = s.color.x * l, s.color.y * l, s.color.z * l, s.morte and max(0, 1 - s.morte * 4) or q
	gui.set_color(s.fuoco, C)

	-- lampo rosso del colpo
	if s.flash > 0 then
		s.flash = max(0, s.flash - dt * 6)
		lampo(s, min(1, s.flash * 1.5))
	end
	-- spinta del colpo e rinculo dell'arma: tornano a zero in fretta
	s.spinta = s.spinta * max(0, 1 - dt * 10)
	s.rinculo = s.rinculo * max(0, 1 - dt * 14)
	if not s.morte then pos(s.corpo, -s.spinta * s.w, 0) end
end

function M.set_weapon(s, name)
	if s.arma_scelta == name or not s.armi[name] then return end
	if s.arma_scelta then gui.set_enabled(s.armi[s.arma_scelta], false) end
	s.arma_scelta = name
	-- da morto l'arma non c'è più
	gui.set_enabled(s.armi[name], not s.morte)
end

-- Colpo subito: lampo rosso, i fotogrammi del colpo e una spinta nella direzione
-- del colpo (dx: verso dove spinge, nel mondo; senza, da davanti)
function M.hit(s, dx)
	local d = (dx and dx ~= 0) and (dx > 0 and 1 or -1) * s.face or -1
	s.flash = 1
	s.spinta = 0.6 * d
	s.azione, s.azione_t = "colpito", 0
end

-- Colpo sparato: rinculo dell'arma
function M.fire(s, kind)
	s.rinculo = kind == "shards" and 0.5 or 1
end

-- Scatto dell'Affondo: il corpo parte un attimo prima, in avanti
function M.lunge(s)
	s.spinta = -0.5
end

-- Arrivo col teletrasporto: ricompare dalla scintilla
function M.teleport(s)
	s.tele = 0
end

-- Sconfitta: l'arma cade, gira la testa, cade e si addormenta, poi svanisce
function M.die(s)
	if s.morte then return end
	s.morte = 0
	s.flash = 0
	lampo(s, 0)
	s.tele = nil
	-- la prossima mostra() spegne testa e arma: la sconfitta non è la mira
	s.mira = nil
end

return M
