-- Il personaggio in battaglia: il diavoletto di Gabriella (ramo di prova della
-- designer), grande come il corpo della simulazione (ROBOT_H x 2 ROBOT_HALF_W)
-- dalla cima della testa ai piedi, così quello che si vede è quello che colpisce
-- e viene colpito. Corna e fiammella sporgono sopra.
--
-- Lo usano la battaglia (game.gui_script), la home (menu/home.lua) e il podio:
--   local s = scoria.new(colore)
--   scoria.update(s, dt, stato)    -- a ogni frame, nessuna allocazione
--   scoria.set_weapon(s, nome) / hit(s) / fire(s, tipo) / lunge(s) / teleport(s) / die(s)
--   scoria.set_color(s, colore)    -- la squadra cambia da una partita all'altra
--
-- Nove pezzi disegnati (strumenti/grafica/diavolo.py): coda, ali, braccio e
-- gamba dietro, gamba davanti, corpo, testa con la fiammella e il braccio
-- davanti, che tiene l'arma e gira con la mira. Il colore della squadra è
-- l'alone attorno alla fiammella.
--
-- Le animazioni sono molle: schiaccia e allunga (atterraggio, stacco,
-- teletrasporto), inclinazione nella corsa, spinta e lampo rosso quando si viene
-- colpiti, rinculo dell'arma, testa che ondeggia e guarda dove si mira, gambe e
-- braccio dietro che fanno i passi in base alla strada fatta, coda che ondeggia,
-- ali che sbattono in aria e fiammella che fluttua.

local game = require "sim.game"
local config = require "sim.config"
local PEZZI = require "battaglia.scoria_pezzi"

local M = {}

-- altezza del personaggio in cima alla fiammella, per mettere sopra vita e freccia
M.ALTEZZA = game.ROBOT_H * (200 - (PEZZI.fiamma.y - PEZZI.fiamma.h / 2)) / 200

local sin, cos, min, max, abs, pi = math.sin, math.cos, math.min, math.max, math.abs, math.pi
local DEG = 180 / pi

local OMBRA = vmath.vector4(0, 0, 0, 0.35)
local BIANCO = vmath.vector4(1, 1, 1, 1)
-- il colpo subito tinge i pezzi di rosso (i colori dei disegni si possono solo scurire)
local LAMPO = vmath.vector4(1, 0.3, 0.3, 1)
local FERRO = vmath.vector4(0.3, 0.29, 0.34, 1)
local LAMA = vmath.vector4(0.86, 0.88, 0.95, 1)

-- molle: posizione, velocità, rigidità, smorzamento
local SQ, LEAN, SHOVE, KICK, TESTA = 1, 2, 3, 4, 5
local W_MOLLA = { 16, 10, 12, 18, 11 }
local Z_MOLLA = { 0.3, 0.45, 0.5, 0.45, 0.28 }

-- perni del disegno (unità della pagina, y verso il basso)
local PERNI = PEZZI.perni
local COLLO, SPALLA, FIAMMA = PERNI.collo, PERNI.spalla, PERNI.fiamma
local ANCHE = { PERNI.anca_davanti, PERNI.anca_dietro }
-- il braccio davanti va dalla spalla alla mano: la mano è sull'impugnatura,
-- a PRESA dalla spalla lungo l'arma; BRACCIO è l'angolo del braccio nel disegno
local PRESA = math.sqrt((PERNI.mano[1] - SPALLA[1]) ^ 2 + (PERNI.mano[2] - SPALLA[2]) ^ 2)
local BRACCIO = math.atan2(SPALLA[2] - PERNI.mano[2], PERNI.mano[1] - SPALLA[1])
-- un passo: la strada che fa il corpo mentre una gamba fa un'oscillazione intera
local PASSO = 0.9

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

-- un pezzo disegnato: un giunto nel punto p del disegno, attorno a cui gira, e
-- sotto l'immagine al suo posto. Il giunto sta in (x, y) nel genitore
local function pezzo(s, parent, nome, p, x, y)
	local q = PEZZI[nome]
	local g = vuoto(parent, x, y)
	local n = box(g, (q.x - p[1]) * s.k, (p[2] - q.y) * s.k, q.w * s.k, q.h * s.k)
	gui.set_texture(n, "battaglia")
	gui.play_flipbook(n, nome)
	s.pelle[#s.pelle + 1] = n
	return g
end
-- un pezzo appeso al corpo (alla forma), col giunto nel suo perno
local function membro(s, nome, p)
	local g = pezzo(s, s.forma, nome, p, gx(s, p[1]), gy(s, p[2]))
	s.membra[#s.membra + 1] = g
	return g
end

-- Le armi in mano, attorno alla spalla: angolo di riposo (radianti, verso avanti)
local ARMI = {
	missile = { riposo = -0.35 },
	sword = { riposo = -1.9 },
	teleport = { riposo = -0.5 },
	grenade = { riposo = -0.5 },
	shards = { riposo = -0.3 },
	punch = { riposo = -0.9 },
	eagle = { riposo = -0.6 },
	hook = { riposo = -0.4 },
	mallet = { riposo = -1.6 },
	lunge = { riposo = -1.4 },
}

local function arma(s, name, color)
	local H, k = s.h, s.k
	local g = vuoto(s.spalla, 0, 0)
	if name == "missile" then
		-- la bocca è dove la simulazione fa partire il colpo (game.MUZZLE)
		local L = game.MUZZLE
		box(g, L / 2, 0, L, H * 0.22, FERRO)
		s.tinte[#s.tinte + 1] = box(g, L - H * 0.05, 0, H * 0.1, H * 0.26, color)
	elseif name == "sword" then
		-- la lama parte dalla mano
		local L, P = game.SWORD_REACH, PRESA * k
		box(g, (L + P) / 2, 0, L - P, max(2, H * 0.1), LAMA)
		box(g, P + H * 0.06, 0, H * 0.08, H * 0.3, FERRO)
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
	-- l'ultimo nodo è la mano, sull'impugnatura (asse dell'arma): la disegna il braccio
	vuoto(g, PRESA * k, 0)
	gui.set_enabled(g, false)
	s.armi[name] = g
end

function M.new(color)
	local H, Wd = game.ROBOT_H, 2 * game.ROBOT_HALF_W
	local s = { color = color, h = H, w = Wd, k = H / 200, armi = {}, pelle = {}, tinte = {}, membra = {},
		x = {}, v = {}, goal = {}, gambe = {}, gamba_a = { 0, 0 } }
	s.root = vuoto(nil, 0, 0)
	gui.set_adjust_mode(s.root, gui.ADJUST_STRETCH)
	s.alpha = vmath.vector4(1, 1, 1, 1)
	s.luce_col = vmath.vector4(color.x, color.y, color.z, 0.8)

	s.ombra = cerchio(s.root, 0, 0, Wd * 1.3, OMBRA)
	scale(s.ombra, 1, 0.22)
	-- corpo: inclinazione e spinta; forma: schiaccia e allunga. Il braccio con
	-- l'arma sta sul corpo e non sulla forma, così schiacciandosi non si storce la mira
	s.corpo = vuoto(s.root, 0, 0)
	s.forma = vuoto(s.corpo, 0, 0)

	-- dal fondo al davanti
	s.coda = membro(s, "coda", PERNI.coda)
	s.ali = membro(s, "ali", PERNI.ali)
	s.braccio_dietro = membro(s, "braccio_dietro", PERNI.spalla_dietro)
	s.gambe[2] = membro(s, "gamba_dietro", ANCHE[2])
	s.gambe[1] = membro(s, "gamba_davanti", ANCHE[1])
	membro(s, "corpo", { 75, 150 })
	s.testa = pezzo(s, s.forma, "testa", COLLO, gx(s, COLLO[1]), gy(s, COLLO[2]))
	-- la fiammella fluttua sopra la testa, con attorno l'alone della squadra
	local k = s.k
	s.fiamma = pezzo(s, s.testa, "fiamma", FIAMMA, (FIAMMA[1] - COLLO[1]) * k, (COLLO[2] - FIAMMA[2]) * k)
	s.luce = box(s.fiamma, 0, 0, 70 * k, 70 * k, s.luce_col)
	gui.set_texture(s.luce, "battaglia")
	gui.play_flipbook(s.luce, "bagliore")
	gui.set_blend_mode(s.luce, gui.BLEND_ADD)
	s.tinte[#s.tinte + 1] = s.luce

	-- il braccio davanti gira attorno alla spalla con l'arma: girato di BRACCIO,
	-- la mano sta sull'asse dell'arma
	s.spalla = vuoto(s.corpo, gx(s, SPALLA[1]), gy(s, SPALLA[2]))
	for name in pairs(ARMI) do arma(s, name, color) end
	s.braccio = vuoto(s.spalla, 0, 0)
	local b = pezzo(s, s.braccio, "braccio_davanti", SPALLA, 0, 0)
	rot(b, -BRACCIO)
	s.membra[#s.membra + 1] = s.braccio
	M.set_weapon(s, "missile")

	M.reset(s)
	return s
end

-- Ridipinge l'alone della fiammella e le armi con il colore di un'altra squadra
function M.set_color(s, color)
	if s.color == color then return end
	s.color = color
	s.luce_col.x, s.luce_col.y, s.luce_col.z = color.x, color.y, color.z
	for _, n in ipairs(s.tinte) do gui.set_color(n, s.luce_col) end
end

function M.reset(s)
	for i = 1, #W_MOLLA do s.x[i], s.v[i], s.goal[i] = 0, 0, 0 end
	s.x[SQ] = 1
	s.t = math.random() * 10
	s.vy, s.last_x, s.last_y, s.ground = 0, nil, nil, true
	s.passo, s.cammina = 0, 0
	s.gamba_a[1], s.gamba_a[2] = 0, 0
	s.flash = 0
	s.morte, s.morto = nil, nil
	s.alpha.w = 1
	gui.set_color(s.root, s.alpha)
	for i = 1, #s.membra do gui.set_color(s.membra[i], s.alpha) end
	for i = 1, #s.pelle do gui.set_color(s.pelle[i], BIANCO) end
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

-- Morte: la testa salta via girando con la fiammella, il resto si accascia e
-- svanisce. Il terreno sotto può non esserci più (il cratere), quindi niente
-- resta appoggiato: tutto svanisce
local MORTE_CORPO, MORTE_TESTA = 0.5, 1.1
local function morte(s, dt)
	local t = s.morte + dt
	s.morte = t
	s.tvy = s.tvy - 9 * s.h * dt
	s.tx, s.ty = s.tx + s.tvx * dt, s.ty + s.tvy * dt
	s.ta = s.ta + s.tgira * dt
	pos(s.testa, s.tx, s.ty)
	rot(s.testa, s.ta)
	-- il corpo svanisce prima della testa
	C.x, C.y, C.z, C.w = 1, 1, 1, max(0, 1 - t / MORTE_CORPO)
	for i = 1, #s.membra do gui.set_color(s.membra[i], C) end
	scale(s.forma, 1 + min(0.3, t), max(0.35, 1 - t * 3))
	rot(s.corpo, min(0.35, t * 2))
	s.alpha.w = min(1, max(0, (MORTE_TESTA - t) / 0.4))
	gui.set_color(s.root, s.alpha)
	if s.alpha.w == 0 then
		s.morto = true
		gui.set_enabled(s.root, false)
	end
end

-- le gambe: oscillano attorno all'anca camminando, in aria restano indietro
-- salendo e vanno avanti scendendo, per l'atterraggio. Il braccio dietro va
-- con la gamba dietro, come chi cammina
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
		pos(s.gambe[i], gx(s, ANCHE[i][1]), gy(s, ANCHE[i][2]) + su)
		rot(s.gambe[i], s.gamba_a[i])
	end
	rot(s.braccio_dietro, -s.gamba_a[2] * 0.8 + sin(s.t * 2) * 0.04)
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

	-- atterraggio e stacco: schiaccia e allunga, la testa fa un cenno
	if ground and not s.ground and s.vy < -40 then
		s.v[SQ] = s.v[SQ] - min(7, -s.vy / 40)
		s.v[TESTA] = s.v[TESTA] - min(4, -s.vy / 80)
	elseif not ground and s.ground and s.vy > 20 then
		s.v[SQ] = s.v[SQ] + 4
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
	s.goal[SQ], s.goal[LEAN], s.goal[TESTA] = sq, lean, testa
	molle(s, dt)

	local q = max(0.4, s.x[SQ])
	scale(s.forma, 1 + (1 - q) * 0.8, q)
	rot(s.corpo, s.x[LEAN])
	pos(s.corpo, -s.x[SHOVE] * s.w, 0)
	-- la spalla sale e scende con la forma
	pos(s.spalla, gx(s, SPALLA[1]), gy(s, SPALLA[2]) * q)
	scale(s.ombra, 1 + (1 - q) * 0.5, 0.22)
	gambe(s, dt, ground)
	-- la testa sobbalza a ogni passo
	pos(s.testa, gx(s, COLLO[1]), gy(s, COLLO[2]) + abs(sin(s.passo)) * 4 * s.k * s.cammina)
	rot(s.testa, s.x[TESTA])
	-- la coda ondeggia, più forte correndo, e in aria resta indietro
	local coda = sin(s.t * 2.1) * 0.08 + sin(s.passo) * 0.15 * s.cammina
	if not ground then coda = coda + (s.vy > 0 and -0.25 or 0.2) end
	rot(s.coda, coda)
	-- le ali: chiuse a terra, in aria sbattono
	rot(s.ali, ground and sin(s.t * 1.6) * 0.04 or -0.2 + sin(s.t * 18) * 0.3)
	-- la fiammella fluttua e l'alone respira
	pos(s.fiamma, (FIAMMA[1] - COLLO[1]) * s.k, (COLLO[2] - FIAMMA[2] + 3 * sin(s.t * 3)) * s.k)
	scale(s.fiamma, 1 + 0.06 * sin(s.t * 9), 1 + 0.08 * sin(s.t * 7))
	s.luce_col.w = 0.6 + 0.25 * sin(s.t * 3.1)
	gui.set_color(s.luce, s.luce_col)

	-- lampo rosso del colpo
	if s.flash > 0 then
		s.flash = max(0, s.flash - dt * 6)
		local f = min(1, s.flash * 1.5)
		C.x, C.y, C.z, C.w = 1, 1 + (LAMPO.y - 1) * f, 1 + (LAMPO.z - 1) * f, 1
		for i = 1, #s.pelle do gui.set_color(s.pelle[i], C) end
	end

	-- la spalla è dentro il corpo, che è inclinato: togliamo l'inclinazione
	a = a - s.x[LEAN]
	rot(s.spalla, a)
	-- il rinculo porta indietro arma e braccio, mai oltre la spalla
	local r = -min(s.x[KICK] * s.w * 0.6, PRESA * s.k * 0.8)
	pos(s.armi[s.arma_scelta], r, 0)
	pos(s.braccio, r, 0)
end

function M.set_weapon(s, name)
	if s.arma_scelta == name or not s.armi[name] then return end
	if s.arma_scelta then gui.set_enabled(s.armi[s.arma_scelta], false) end
	s.arma_scelta = name
	-- da morto l'arma non c'è più
	gui.set_enabled(s.armi[name], not s.morte)
end

-- Colpo subito: lampo rosso, spinta e inclinazione nella direzione del colpo
-- (dx: verso dove spinge, nel mondo; senza, da davanti), schiacciata, testa che
-- scatta
function M.hit(s, dx)
	local d = (dx and dx ~= 0) and (dx > 0 and 1 or -1) * s.face or -1
	s.flash = 1
	s.v[SHOVE] = s.v[SHOVE] - 9 * d
	s.v[SQ] = s.v[SQ] - 4
	s.v[LEAN] = s.v[LEAN] - 5 * d
	s.v[TESTA] = s.v[TESTA] - 8 * d
end

-- Colpo sparato: rinculo dell'arma e del corpo
function M.fire(s, kind)
	local k = kind == "shards" and 0.5 or 1
	s.v[KICK] = s.v[KICK] + 14 * k
	s.v[LEAN] = s.v[LEAN] + 3 * k
	s.v[SQ] = s.v[SQ] - 1.5 * k
	s.v[TESTA] = s.v[TESTA] + 3 * k
end

-- Scatto dell'Affondo: si allunga in avanti e si piega
function M.lunge(s)
	s.v[SQ] = s.v[SQ] + 6
	s.v[LEAN] = s.v[LEAN] + 8
	s.v[TESTA] = s.v[TESTA] + 4
end

-- Arrivo col teletrasporto: compare schiacciato e si allunga con un rimbalzo
function M.teleport(s)
	s.x[SQ], s.v[SQ] = 0.5, 4
end

function M.die(s)
	if s.morte then return end
	s.morte = 0
	local H = s.h
	s.tx, s.ty, s.ta = gx(s, COLLO[1]), gy(s, COLLO[2]), s.x[TESTA]
	s.tvx, s.tvy, s.tgira = -0.8 * H, 2.6 * H, 9
	scale(s.forma, 1, 1)
	gui.set_enabled(s.armi[s.arma_scelta], false)
end

return M
