-- Il diavoletto: il personaggio della battaglia, della home e del podio, grande
-- come il corpo della simulazione (ROBOT_H x 2 ROBOT_HALF_W), così quello che si
-- vede è quello che colpisce e viene colpito (corna, coda e fiammella escono).
--
-- Lo usano la battaglia (game.gui_script), la home (menu/home.lua) e il podio:
--   local s = scoria.new(colore)
--   scoria.update(s, dt, stato)    -- a ogni frame, nessuna allocazione
--   scoria.set_weapon(s, nome) / hit(s) / fire(s, tipo) / lunge(s) / teleport(s) / die(s)
--   scoria.set_color(s, colore)    -- la squadra cambia da una partita all'altra
-- stato: x, y, facing, grounded, moving, aim (nil se non mira), turno (è di turno)
--
-- Pezzi disegnati (immagini a colori di strumenti/grafica/scoria.py): testa con
-- occhiali, busto con l'ala, due gambe uguali, la coda in segmenti e la fiammella
-- sopra la testa. Mani e armi sono nodi GUI. Ogni pezzo ha tre copie in tre strati:
-- il contorno chiaro dietro a tutto (così il diavoletto si stacca dallo sfondo
-- scuro come un pezzo unico), il colore, e la sagoma bianca del lampo del colpo,
-- accesa solo quando serve.
--
-- La fiammella dice la squadra (ha il suo colore) e il turno: su chi gioca è più
-- grande e accesa, sugli altri piccola e più scura.
--
-- Le animazioni sono molle: schiaccia e allunga (atterraggio, stacco,
-- teletrasporto), inclinazione nella corsa, spinta e lampo bianco quando si viene
-- colpiti, rinculo dell'arma, testa che ondeggia e guarda dove si mira, gambe che
-- fanno i passi in base alla strada fatta, coda che ondeggia e frusta, fiammella
-- che trema.

local game = require "sim.game"
local config = require "sim.config"
local PEZZI = require "battaglia.scoria_pezzi"

local M = {}

-- altezza del diavoletto in cima alla fiammella, per mettere sopra vita e freccia
M.ALTEZZA = game.ROBOT_H * (200 - (PEZZI.fiammella.y - PEZZI.fiammella.h / 2)) / 200

local sin, cos, min, max, abs, pi = math.sin, math.cos, math.min, math.max, math.abs, math.pi
local DEG = 180 / pi

local INCHIOSTRO = vmath.vector4(0.078, 0.071, 0.094, 1)
local LUCE = vmath.vector4(1, 0.886, 0.769, 0.6)
local OMBRA = vmath.vector4(0, 0, 0, 0.35)
local BIANCO = vmath.vector4(1, 1, 1, 1)
local PELLE = vmath.vector4(0.78, 0.68, 0.6, 1)
local FERRO = vmath.vector4(0.3, 0.29, 0.34, 1)
local LAMA = vmath.vector4(0.86, 0.88, 0.95, 1)

-- molle: posizione, velocità, rigidità, smorzamento
local SQ, LEAN, SHOVE, KICK, TESTA, CODA, FUOCO = 1, 2, 3, 4, 5, 6, 7
local W_MOLLA = { 16, 10, 12, 18, 11, 7, 6 }
local Z_MOLLA = { 0.3, 0.45, 0.5, 0.45, 0.28, 0.25, 0.4 }

-- punti del disegno (unità della pagina dei pezzi, y verso il basso)
local COLLO = { PEZZI.testa.px, PEZZI.testa.py }
local BACINO = { PEZZI.busto.px, PEZZI.busto.py }
local FIAMMA = { PEZZI.fiammella.px, PEZZI.fiammella.py }
local ANCHE = { { 58, 136.5 }, { 82, 136.5 } }
local SPALLA = { 62, 100 }
-- la mano sull'impugnatura, davanti alla spalla lungo l'arma
local PRESA = 20
-- un passo: la strada che fa il corpo mentre una gamba fa un'oscillazione intera
local PASSO = 0.9
-- la fiammella di chi è di turno e degli altri: grandezza e luce
local FUOCO_TURNO, FUOCO_ATTESA, LUCE_ATTESA = 1.35, 0.85, 0.6

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

-- dal disegno al gioco: origine ai piedi, y verso l'alto, k unità per punto
local function gx(s, x) return (x - 75) * s.k end
local function gy(s, y) return (200 - y) * s.k end

-- i tre strati di ogni pezzo: contorno, colore, lampo
local STRATI = { { "_bordo", LUCE }, { "", BIANCO }, { "_sagoma", BIANCO } }

-- un pezzo disegnato, in uno strato: un giunto nel punto (x, y) del disegno
-- (relativo al giunto genitore, rx, ry), attorno a cui gira, e sotto l'immagine
local function pezzo(s, parent, p, nome, strato, x, y, rx, ry)
	local g = vuoto(parent, (x - rx) * s.k, (ry - y) * s.k)
	local n = box(g, (p.x - x) * s.k, (y - p.y) * s.k, p.w * s.k, p.h * s.k, STRATI[strato][2])
	gui.set_texture(n, "battaglia")
	gui.play_flipbook(n, nome .. STRATI[strato][1])
	if strato == 3 then s.lampi[#s.lampi + 1] = n end
	return g, n
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

-- una mano staccata: un pugno color pelle col contorno scuro
local function mano(s, g, x, y)
	local d = 20 * s.k
	cerchio(g, x, y, d + 2 * 3 * s.k, INCHIOSTRO)
	cerchio(g, x, y, d, PELLE)
end

local function arma(s, name, color)
	local H, k = s.h, s.k
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
		cerchio(g, H * 0.45, 0, s.w * 0.8, FERRO)
	end
	-- le mani: la seconda sotto la canna, l'ultima sull'impugnatura (asse dell'arma)
	if ARMI[name].due_mani then mano(s, g, 58 * k, -14 * k) end
	mano(s, g, PRESA * k, 0)
	gui.set_enabled(g, false)
	s.armi[name] = g
end

function M.new(color)
	local H, Wd = game.ROBOT_H, 2 * game.ROBOT_HALF_W
	local s = { color = color, h = H, w = Wd, k = H / 200, armi = {}, tinte = {}, lampi = {},
		x = {}, v = {}, goal = {}, testa = {}, busto = {}, fiammella = {}, fuoco = {},
		gambe = { {}, {} }, gamba_a = { 0, 0 }, coda = {}, coda_a = {} }
	for i = 1, #PEZZI.coda do s.coda[i], s.coda_a[i] = {}, 0 end
	s.root = vuoto(nil, 0, 0)
	gui.set_adjust_mode(s.root, gui.ADJUST_STRETCH)
	s.alpha = vmath.vector4(1, 1, 1, 1)
	s.fuoco_col = vmath.vector4(color.x, color.y, color.z, 1)
	s.lampo_col = vmath.vector4(1, 1, 1, 0)

	s.ombra = cerchio(s.root, 0, 0, Wd * 1.3, OMBRA)
	scale(s.ombra, 1, 0.22)
	-- corpo: inclinazione e spinta; forma: schiaccia e allunga. L'arma sta sul
	-- corpo e non sulla forma, così schiacciandosi non si storce la mira
	s.corpo = vuoto(s.root, 0, 0)
	s.forma = vuoto(s.corpo, 0, 0)

	-- strato per strato: prima tutti i contorni, poi i colori, poi i lampi; dentro
	-- uno strato dal fondo: coda, gambe, busto, testa, fiammella
	for strato = 1, 3 do
		local padre, px, py = s.forma, 75, 200
		for i, p in ipairs(PEZZI.coda) do
			padre = pezzo(s, padre, p, "coda" .. i, strato, p.px, p.py, px, py)
			px, py = p.px, p.py
			s.coda[i][strato] = padre
		end
		for i = 1, 2 do
			s.gambe[i][strato] = pezzo(s, s.forma, PEZZI.gamba, "gamba", strato, 0, 0, 0, 0)
		end
		s.busto[strato] = pezzo(s, s.forma, PEZZI.busto, "busto", strato, BACINO[1], BACINO[2], 75, 200)
		s.testa[strato] = pezzo(s, s.forma, PEZZI.testa, "testa", strato, COLLO[1], COLLO[2], 75, 200)
		local g, n = pezzo(s, s.testa[strato], PEZZI.fiammella, "fiammella", strato,
			FIAMMA[1], FIAMMA[2], COLLO[1], COLLO[2])
		s.fiammella[strato] = g
		if strato == 2 then s.fuoco_n = n end
	end
	gui.set_color(s.fuoco_n, s.fuoco_col)

	s.spalla = vuoto(s.corpo, gx(s, SPALLA[1]), gy(s, SPALLA[2]))
	for name in pairs(ARMI) do arma(s, name, color) end
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

-- il lampo bianco: le sagome si accendono sopra i colori
local function lampo(s, a)
	s.lampo_col.w = a
	for i = 1, #s.lampi do
		gui.set_color(s.lampi[i], s.lampo_col)
		gui.set_enabled(s.lampi[i], a > 0)
	end
end

function M.reset(s)
	for i = 1, #W_MOLLA do s.x[i], s.v[i], s.goal[i] = 0, 0, 0 end
	s.x[SQ], s.x[FUOCO] = 1, 1
	s.t = math.random() * 10
	s.vy, s.last_x, s.last_y, s.ground = 0, nil, nil, true
	s.passo, s.cammina = 0, 0
	s.gamba_a[1], s.gamba_a[2] = 0, 0
	for i = 1, #s.coda_a do s.coda_a[i] = 0 end
	s.flash = 0
	s.morte, s.morto = nil, nil
	s.alpha.w = 1
	gui.set_color(s.root, s.alpha)
	for strato = 1, 3 do
		scale(s.busto[strato], 1, 1)
		gui.set_color(s.busto[strato], s.alpha)
		gui.set_color(s.coda[1][strato], s.alpha)
		gui.set_color(s.gambe[1][strato], s.alpha)
		gui.set_color(s.gambe[2][strato], s.alpha)
		gui.set_color(s.fiammella[strato], s.alpha)
	end
	lampo(s, 0)
	if s.arma_scelta then gui.set_enabled(s.armi[s.arma_scelta], true) end
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

-- Morte: la testa salta via girando, busto, coda e gambe si accasciano e
-- svaniscono, la fiammella si gonfia e si spegne. Il terreno sotto può non
-- esserci più (il cratere), quindi niente resta appoggiato: tutto svanisce
local MORTE_CORPO, MORTE_TESTA = 0.5, 1.1
local function morte(s, dt)
	local t = s.morte + dt
	s.morte = t
	s.tvy = s.tvy - 9 * s.h * dt
	s.tx, s.ty = s.tx + s.tvx * dt, s.ty + s.tvy * dt
	s.ta = s.ta + s.tgira * dt
	-- il corpo svanisce prima della testa
	C.x, C.y, C.z, C.w = 1, 1, 1, max(0, 1 - t / MORTE_CORPO)
	local f = 1 + t * 4
	for strato = 1, 3 do
		pos(s.testa[strato], s.tx, s.ty)
		rot(s.testa[strato], s.ta)
		scale(s.busto[strato], 1 + min(0.3, t), max(0.35, 1 - t * 3))
		gui.set_color(s.busto[strato], C)
		gui.set_color(s.coda[1][strato], C)
		gui.set_color(s.gambe[1][strato], C)
		gui.set_color(s.gambe[2][strato], C)
		scale(s.fiammella[strato], f, f)
	end
	rot(s.corpo, min(0.35, t * 2))
	C.w = max(0, 1 - t * 4)
	for strato = 1, 3 do gui.set_color(s.fiammella[strato], C) end
	s.alpha.w = min(1, max(0, (MORTE_TESTA - t) / 0.4))
	gui.set_color(s.root, s.alpha)
	if s.alpha.w == 0 then
		s.morto = true
		gui.set_enabled(s.root, false)
	end
end

-- le gambe: oscillano attorno all'anca camminando, in aria restano indietro
-- salendo e vanno avanti scendendo, per l'atterraggio
local function gambe(s, dt, ground)
	local segui = min(1, dt * 16)
	for i = 1, 2 do
		local fase = s.passo + (i - 1) * pi
		local a
		if ground then
			a = sin(fase) * 0.6 * s.cammina
		else
			a = (s.vy > 0 and -0.35 or 0.3) + (i == 1 and -0.12 or 0.12)
		end
		s.gamba_a[i] = s.gamba_a[i] + (a - s.gamba_a[i]) * segui
		-- il piede si alza mentre torna avanti
		local su = ground and max(0, cos(fase)) * s.cammina * 8 * s.k or 0
		local g = s.gambe[i]
		for strato = 1, 3 do
			pos(g[strato], gx(s, ANCHE[i][1]), gy(s, ANCHE[i][2]) + su)
			rot(g[strato], s.gamba_a[i])
		end
	end
end

-- la coda: un'onda che parte dalla schiena e arriva alla punta, più la molla CODA
-- (resta indietro correndo, frusta saltando e quando arriva un colpo). Ogni
-- segmento insegue il suo angolo un po' più piano del precedente: così il moto
-- arriva alla punta in ritardo
local function coda(s, dt)
	local base = s.x[CODA]
	for i = 1, #s.coda_a do
		local a = (base + sin(s.t * 2.6 - i * 0.8) * 0.1) * (0.6 + 0.15 * i)
		s.coda_a[i] = s.coda_a[i] + (a - s.coda_a[i]) * min(1, dt * (18 - 2.5 * i))
		for strato = 1, 3 do rot(s.coda[i][strato], s.coda_a[i]) end
	end
end

-- la fiammella trema (due onde che non si ripetono mai uguali) e su chi è di
-- turno si gonfia e si accende
local function fiammella(s, turno)
	local f = s.x[FUOCO]
	local tr = sin(s.t * 11) * 0.06 + sin(s.t * 17.3) * 0.04
	for strato = 1, 3 do
		scale(s.fiammella[strato], f * (1 - tr * 0.5), f * (1 + tr))
		rot(s.fiammella[strato], sin(s.t * 6.7) * 0.06 - s.x[TESTA] * 0.5)
	end
	local l = turno and 1 or LUCE_ATTESA
	C.x, C.y, C.z, C.w = s.color.x * l, s.color.y * l, s.color.z * l, 1
	gui.set_color(s.fuoco_n, C)
end

function M.update(s, dt, st)
	if s.morto then return end
	dt = min(dt, 1 / 20)
	s.t = s.t + dt
	local face = st.facing
	s.face = face
	scale(s.root, face, 1)
	pos(s.root, st.x, st.y)
	if s.morte then return morte(s, dt) end

	if s.last_y then
		local vy = (st.y - s.last_y) / max(dt, 1e-4)
		s.vy = s.vy + (vy - s.vy) * min(1, dt * 14)
	end
	local dx = s.last_x and abs(st.x - s.last_x) or 0
	s.last_x, s.last_y = st.x, st.y
	local ground = st.grounded

	-- passi: contano la strada fatta a terra (non i teletrasporti)
	local corre = ground and st.moving ~= 0 and dx < s.h
	if corre then s.passo = (s.passo + dx / (PASSO * s.h) * 2 * pi) % (2 * pi) end
	s.cammina = s.cammina + ((corre and 1 or 0) - s.cammina) * min(1, dt * 10)

	-- atterraggio e stacco: schiaccia e allunga, la testa fa un cenno, la coda frusta
	if ground and not s.ground and s.vy < -40 then
		s.v[SQ] = s.v[SQ] - min(7, -s.vy / 40)
		s.v[TESTA] = s.v[TESTA] - min(4, -s.vy / 80)
		s.v[CODA] = s.v[CODA] - min(6, -s.vy / 50)
	elseif not ground and s.ground and s.vy > 20 then
		s.v[SQ] = s.v[SQ] + 4
		s.v[CODA] = s.v[CODA] + 4
	end
	s.ground = ground

	local sq = 1 + 0.025 * sin(s.t * 2.4)
	if not ground then sq = 1 + min(0.2, abs(s.vy) / 900) end
	-- si piega in avanti correndo
	local avanti = st.moving * face
	local lean = -0.22 * max(-1, min(1, avanti / 70))
	-- l'arma gira attorno alla spalla: verso la mira, altrimenti a riposo
	local a = ARMI[s.arma_scelta].riposo
	if st.aim then a = face > 0 and st.aim or pi - st.aim end
	-- la testa guarda un po' dove si mira e ondeggia nei passi
	local testa = max(-0.25, min(0.25, sin(a) * 0.2)) + sin(s.passo * 2) * 0.05 * s.cammina
	-- la coda resta indietro correndo (si alza) e in aria segue la velocità
	local cd = 0.35 * max(-1, min(1, avanti / 70))
	if not ground then cd = cd + max(-0.4, min(0.4, -s.vy / 500)) end
	s.goal[SQ], s.goal[LEAN], s.goal[TESTA], s.goal[CODA] = sq, lean, testa, -cd
	s.goal[FUOCO] = st.turno and FUOCO_TURNO or FUOCO_ATTESA
	molle(s, dt)

	local q = max(0.4, s.x[SQ])
	-- la testa non si schiaccia (i dettagli del disegno si vedrebbero storti):
	-- scende e sale con il busto
	scale(s.forma, 1 + (1 - q) * 0.8, q)
	rot(s.corpo, s.x[LEAN])
	pos(s.corpo, -s.x[SHOVE] * s.w, 0)
	-- la spalla sale e scende con la forma
	pos(s.spalla, gx(s, SPALLA[1]), gy(s, SPALLA[2]) * q)
	scale(s.ombra, 1 + (1 - q) * 0.5, 0.22)
	gambe(s, dt, ground)
	coda(s, dt)
	-- la testa sobbalza a ogni passo
	local hy = gy(s, COLLO[2]) + abs(sin(s.passo)) * 4 * s.k * s.cammina
	for strato = 1, 3 do
		pos(s.testa[strato], gx(s, COLLO[1]), hy)
		rot(s.testa[strato], s.x[TESTA])
		scale(s.testa[strato], 1 / (1 + (1 - q) * 0.8), 1 / q)
	end
	fiammella(s, st.turno)

	-- lampo bianco del colpo
	if s.flash > 0 then
		s.flash = max(0, s.flash - dt * 6)
		lampo(s, min(1, s.flash * 1.5))
	end

	-- la spalla è dentro il corpo, che è inclinato: togliamo l'inclinazione
	a = a - s.x[LEAN]
	rot(s.spalla, a)
	local g = s.armi[s.arma_scelta]
	-- il rinculo non porta mai la mano dietro la spalla
	pos(g, -min(s.x[KICK] * s.w * 0.6, PRESA * s.k * 0.8), 0)
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
	local d = (dx and dx ~= 0) and (dx > 0 and 1 or -1) * s.face or -1
	s.flash = 1
	s.v[SHOVE] = s.v[SHOVE] - 9 * d
	s.v[SQ] = s.v[SQ] - 4
	s.v[LEAN] = s.v[LEAN] - 5 * d
	s.v[TESTA] = s.v[TESTA] - 8 * d
	s.v[CODA] = s.v[CODA] + 8 * d
end

-- Colpo sparato: rinculo dell'arma e del corpo
function M.fire(s, kind)
	local k = kind == "shards" and 0.5 or 1
	s.v[KICK] = s.v[KICK] + 14 * k
	s.v[LEAN] = s.v[LEAN] + 3 * k
	s.v[SQ] = s.v[SQ] - 1.5 * k
	s.v[TESTA] = s.v[TESTA] + 3 * k
	s.v[CODA] = s.v[CODA] - 3 * k
end

-- Scatto dell'Affondo: si allunga in avanti e si piega
function M.lunge(s)
	s.v[SQ] = s.v[SQ] + 6
	s.v[LEAN] = s.v[LEAN] + 8
	s.v[TESTA] = s.v[TESTA] + 4
	s.v[CODA] = s.v[CODA] - 6
end

-- Arrivo col teletrasporto: compare schiacciato e si allunga con un rimbalzo
function M.teleport(s)
	s.x[SQ], s.v[SQ] = 0.5, 4
	s.v[FUOCO] = s.v[FUOCO] + 6
end

function M.die(s)
	if s.morte then return end
	s.morte = 0
	local H = s.h
	s.tx, s.ty, s.ta = gx(s, COLLO[1]), gy(s, COLLO[2]), s.x[TESTA]
	s.tvx, s.tvy, s.tgira = -0.8 * H, 2.6 * H, 9
	scale(s.forma, 1, 1)
	for strato = 1, 3 do scale(s.testa[strato], 1, 1) end
	lampo(s, 0)
	gui.set_enabled(s.armi[s.arma_scelta], false)
end

return M
