-- Il personaggio in battaglia: PROVA del diavoletto a pezzi staccati di
-- Gabriella (ramo della designer). Testa, fiammella, corpo, ala, coda, pugni e
-- scarpe sono ritagliati dal suo disegno (strumenti/grafica/diavolo_pezzi.py)
-- e si muovono in codice: niente braccia né gambe, i pezzi galleggiano vicini.
-- Dalla cima della testa ai piedi è alto come il corpo della simulazione.
--
-- Stessa interfaccia del personaggio a fotogrammi:
--   local s = scoria.new(colore)
--   scoria.update(s, dt, stato)    -- a ogni frame, nessuna allocazione
--   scoria.set_weapon(s, nome) / hit(s) / fire(s, tipo) / lunge(s) / teleport(s) / die(s)
--   scoria.set_color(s, colore)
-- stato: x, y, facing, grounded, moving, aim (se mira), paracadute, festa (podio)
--
-- Il pugno davanti tiene l'arma e gira con la mira attorno alla spalla; il
-- colore della squadra è l'alone attorno alla fiammella.

local game = require "sim.game"
local config = require "sim.config"
local PEZZI = require "battaglia.diavolo_pezzi"

local M = {}

local P = {}
for _, p in ipairs(PEZZI) do P[p.nome] = p end
M.ALTEZZA = game.ROBOT_H * (P.fiammella.y + P.fiammella.h / 2) / 200

local sin, cos, min, max, abs, pi, floor = math.sin, math.cos, math.min, math.max, math.abs, math.pi, math.floor
local DEG = 180 / pi

local OMBRA = vmath.vector4(0, 0, 0, 0.35)
local BIANCO = vmath.vector4(1, 1, 1, 1)
local LAMPO = vmath.vector4(1, 0.3, 0.3, 1)
local FERRO = vmath.vector4(0.3, 0.29, 0.34, 1)
local LAMA = vmath.vector4(0.86, 0.88, 0.95, 1)

-- molle: spinta del colpo e rinculo dell'arma
local SHOVE, KICK = 1, 2
local W_MOLLA = { 12, 18 }
local Z_MOLLA = { 0.5, 0.45 }

-- perni (unità del disegno, dall'appoggio, y in su): dove gira ogni pezzo
local PERNO = {
	coda = { -62, 70 },      -- la punta che entra dietro il pugno
	ala = { -26, 112 },      -- l'attacco dietro la spalla
	corpo = { 0, 34 },       -- in basso al centro: si piega sui piedi
	testa = { 0, 120 },      -- il collo
	fiammella = { 6, 205 },
	pugno_sx = { -44, 68 },
	pugno_dx = { 52, 69 },
	scarpa_sx = { -24, 4 },
	scarpa_dx = { 31, 4 },
}
-- la spalla dell'arma e la presa: il pugno davanti sta a PRESA dalla spalla
local SPALLA = { 20, 98 }
local PRESA = 34
-- un passo: la strada che fa il corpo in un giro intero dei piedi
local PASSO = 0.9
local MORTE_VIA, MORTE_FINE = 0.9, 1.4

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
local function immagine(parent, nome)
	local n = box(parent, 0, 0, 0, 0)
	gui.set_texture(n, "battaglia")
	gui.play_flipbook(n, nome)
	return n
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
	gui.set_enabled(g, false)
	s.armi[name] = g
end

function M.new(color)
	local H, Wd = game.ROBOT_H, 2 * game.ROBOT_HALF_W
	local s = { color = color, h = H, w = Wd, k = H / 200, armi = {}, tinte = {},
		x = {}, v = {}, goal = {}, n = {}, img = {} }
	local k = s.k
	s.root = vuoto(nil, 0, 0)
	gui.set_adjust_mode(s.root, gui.ADJUST_STRETCH)
	s.alpha = vmath.vector4(1, 1, 1, 1)
	s.luce_col = vmath.vector4(color.x, color.y, color.z, 0.8)

	s.ombra = cerchio(s.root, 0, 0, Wd * 1.3, OMBRA)
	scale(s.ombra, 1, 0.22)
	-- tutto: la spinta quando si viene colpiti
	s.corpo = vuoto(s.root, 0, 0)
	for _, p in ipairs(PEZZI) do
		local q = PERNO[p.nome]
		local g = vuoto(s.corpo, q[1] * k, q[2] * k)
		local im = immagine(g, p.nome)
		gui.set_size(im, vmath.vector3(p.w * k, p.h * k, 0))
		pos(im, (p.x - q[1]) * k, (p.y - q[2]) * k)
		s.n[p.nome], s.img[p.nome] = g, im
		if p.nome == "fiammella" then
			-- l'alone della squadra attorno alla fiammella
			s.luce = immagine(g, "bagliore")
			gui.set_size(s.luce, vmath.vector3(60 * k, 60 * k, 0))
			gui.set_blend_mode(s.luce, gui.BLEND_ADD)
			gui.set_color(s.luce, s.luce_col)
			pos(s.luce, (p.x - q[1]) * k, (p.y - q[2] - 6) * k)
			s.tinte[#s.tinte + 1] = s.luce
		end
	end

	-- l'arma gira attorno alla spalla; il pugno davanti la tiene alla presa
	s.spalla = vuoto(s.corpo, SPALLA[1] * k, SPALLA[2] * k)
	gui.set_visible(s.spalla, false)
	for name in pairs(ARMI) do arma(s, name, color) end
	s.presa = vuoto(s.spalla, 0, 0)
	local pd = P.pugno_dx
	s.pugno_arma = immagine(s.presa, "pugno_dx")
	gui.set_size(s.pugno_arma, vmath.vector3(pd.w * k, pd.h * k, 0))
	pos(s.pugno_arma, PRESA * k, 0)
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

local function tinta(s, c)
	for _, im in pairs(s.img) do gui.set_color(im, c) end
	gui.set_color(s.pugno_arma, c)
end

function M.reset(s)
	for i = 1, #W_MOLLA do s.x[i], s.v[i], s.goal[i] = 0, 0, 0 end
	s.t = math.random() * 10
	s.vy, s.last_x, s.last_y, s.ground = 0, nil, nil, true
	s.passo, s.cammina, s.aria = 0, 0, 0
	s.flash, s.colpo, s.tele, s.lancio, s.atterra = 0, 0, 1, 0, 0
	s.mira = ARMI.missile.riposo
	s.morte, s.morto = nil, nil
	s.alpha.w = 1
	gui.set_color(s.root, s.alpha)
	tinta(s, BIANCO)
	scale(s.corpo, 1, 1)
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

-- mette un pezzo al suo perno spostato di (dx, dy) unità e girato di r radianti
local function metti(s, nome, dx, dy, r)
	local q, k = PERNO[nome], s.k
	pos(s.n[nome], (q[1] + dx) * k, (q[2] + dy) * k)
	rot(s.n[nome], r or 0)
end

-- Sconfitta: i pezzi si sparpagliano cadendo, poi svanisce
local function morte(s, dt)
	local t = s.morte + dt
	s.morte = t
	local c = min(1, t / 0.6)
	local g = c * c
	metti(s, "testa", -10 * c, 30 * c - 140 * g, 1.2 * c)
	metti(s, "fiammella", 0, 60 * c, 0)
	gui.set_color(s.img.fiammella, vmath.vector4(1, 1, 1, max(0, 1 - c)))
	metti(s, "corpo", 0, -10 * g, -1.4 * c)
	metti(s, "pugno_sx", -30 * c, 20 * c - 60 * g, -2 * c)
	metti(s, "pugno_dx", 30 * c, 25 * c - 60 * g, 2 * c)
	metti(s, "ala", -10 * c, -60 * g, -0.8 * c)
	metti(s, "coda", -20 * c, -60 * g, 0.6 * c)
	metti(s, "scarpa_sx", -12 * c, 0, 0)
	metti(s, "scarpa_dx", 12 * c, 0, 0)
	s.alpha.w = min(1, max(0, (MORTE_FINE - t) / (MORTE_FINE - MORTE_VIA)))
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
	local t = s.t
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

	local corre = ground and st.moving ~= 0 and dx < s.h
	if corre then s.passo = (s.passo + dx / (PASSO * s.h)) % 1 end
	s.cammina = s.cammina + ((corre and 1 or 0) - s.cammina) * min(1, dt * 10)
	s.aria = s.aria + (((ground or st.paracadute) and 0 or 1) - s.aria) * min(1, dt * 12)
	if ground and not s.ground and s.vy < -40 then s.atterra = 1 end
	s.ground = ground
	s.atterra = max(0, s.atterra - dt * 4)
	s.colpo = max(0, s.colpo - dt * 3)
	s.lancio = max(0, s.lancio - dt * 3)
	s.tele = min(1, s.tele + dt * 4)

	molle(s, dt)
	pos(s.corpo, -s.x[SHOVE] * s.w, 0)
	if st.aim then s.mira = face > 0 and st.aim or pi - st.aim end
	local braccio = st.aim ~= nil or s.x[KICK] > 0.02

	-- respiro, passi, aria: quanto pesa ciascuno
	local cm, ar = s.cammina * (1 - s.aria), s.aria
	local fermo = 1 - max(cm, ar)
	local resp = sin(t * 3)
	local fase = s.passo * 2 * pi
	local passo1, passo2 = sin(fase), sin(fase + pi)
	local rimbalzo = abs(cos(fase))
	-- in aria: su quando sale, giù quando scende
	local su = max(-1, min(1, s.vy / 120))

	-- corpo e testa: respirano da fermi, rimbalzano a ogni passo, si piegano avanti correndo
	local giu = -6 * s.atterra
	local cy = fermo * 1.5 * resp + cm * 5 * rimbalzo + giu + ar * 3 * su
	local lean = -cm * 0.12 + s.colpo * 0.25
	metti(s, "corpo", 0, cy, lean)
	metti(s, "testa", lean * 40, cy + fermo * 2 * sin(t * 3 - 0.5) + cm * 4 * abs(cos(fase - 0.4)) + ar * 5 * su + giu * 0.6,
		lean * 0.8 + fermo * 0.03 * sin(t * 1.3) - s.colpo * 0.2)
	-- la fiammella tremola e segue la testa con ritardo
	metti(s, "fiammella", lean * 55 + 1.5 * sin(t * 9), cy + 3 * sin(t * 5) + ar * 8 * su, 0.15 * sin(t * 7))
	scale(s.img.fiammella, 1 + 0.08 * sin(t * 11), 1 + 0.12 * sin(t * 13 + 1))

	-- piedi: un giro per passo, uno su mentre l'altro spinge; in aria raccolti
	local pa = 14 * cm
	metti(s, "scarpa_sx", -pa * cos(fase) + ar * 4, cm * 9 * max(0, passo1) + ar * (10 - 4 * su), cm * 0.25 * max(0, passo1) - ar * 0.3)
	metti(s, "scarpa_dx", -pa * cos(fase + pi) - ar * 2, cm * 9 * max(0, passo2) + ar * (6 - 4 * su), cm * 0.25 * max(0, passo2) - ar * 0.2)

	-- pugni: oscillano in controfase coi piedi; in aria in su, alla festa in alto
	local festa = st.festa and 1 or 0
	local salto_festa = festa * abs(sin(t * 6))
	local py = fermo * 2.5 * sin(t * 3 - 0.9) + cy + ar * 14 * (0.5 + 0.5 * su) + festa * 60 * salto_festa
	metti(s, "pugno_sx", cm * 10 * cos(fase) - s.lancio * 10, py + cm * 3 * passo2, cm * 0.3 * cos(fase))
	metti(s, "pugno_dx", cm * 10 * cos(fase + pi) + s.lancio * 30, py + cm * 3 * passo1 + s.lancio * 25, cm * 0.3 * cos(fase + pi))
	gui.set_enabled(s.n.pugno_dx, not braccio)
	gui.set_enabled(s.spalla, braccio)

	-- ala e coda: battono e ondeggiano, più forte correndo e in aria
	metti(s, "ala", lean * 30, cy, 0.08 * sin(t * 2.6) + cm * 0.2 * sin(fase * 2) + ar * 0.6 * sin(t * 18))
	metti(s, "coda", lean * 20, cy * 0.6, 0.1 * sin(t * 2) + cm * (0.25 + 0.08 * sin(fase * 2)) + ar * 0.3 * su)

	-- arrivo col teletrasporto: si ricompone dal piccolo
	local e = 1 - (1 - s.tele) ^ 2
	scale(s.corpo, e, e)

	-- l'alone respira
	s.luce_col.w = 0.55 + 0.25 * sin(t * 3.1)
	gui.set_color(s.luce, s.luce_col)

	if s.flash > 0 then
		s.flash = max(0, s.flash - dt * 6)
		local f = min(1, s.flash * 1.5)
		C.x, C.y, C.z, C.w = 1, 1 + (LAMPO.y - 1) * f, 1 + (LAMPO.z - 1) * f, 1
		tinta(s, C)
	end

	rot(s.spalla, s.mira)
	local r = -min(s.x[KICK] * s.w * 0.6, PRESA * s.k * 0.8)
	pos(s.armi[s.arma_scelta], r, 0)
	pos(s.presa, r, 0)
	pos(s.spalla, (SPALLA[1] + lean * 30) * s.k, (SPALLA[2] + cy) * s.k)
end

function M.set_weapon(s, name)
	if s.arma_scelta == name or not s.armi[name] then return end
	if s.arma_scelta then gui.set_enabled(s.armi[s.arma_scelta], false) end
	s.arma_scelta = name
	gui.set_enabled(s.armi[name], not s.morte)
end

-- Colpo subito: lampo rosso, spinta e testa all'indietro
function M.hit(s, dx)
	local d = (dx and dx ~= 0) and (dx > 0 and 1 or -1) * s.face or -1
	s.flash = 1
	s.colpo = 1
	s.v[SHOVE] = s.v[SHOVE] - 9 * d
end

-- Colpo sparato: rinculo dell'arma; un lancio spinge avanti il pugno
function M.fire(s, kind)
	if kind == "throw" then
		s.lancio = 1
		return
	end
	local k = kind == "shards" and 0.5 or 1
	s.v[KICK] = s.v[KICK] + 14 * k
end

-- Scatto dell'Affondo: il corpo parte un attimo prima, in avanti
function M.lunge(s)
	s.v[SHOVE] = s.v[SHOVE] - 6
end

-- Arrivo col teletrasporto: si ricompone dal piccolo
function M.teleport(s)
	s.tele = 0
end

function M.die(s)
	if s.morte then return end
	s.morte = 0
	gui.set_enabled(s.spalla, false)
	gui.set_enabled(s.n.pugno_dx, true)
end

return M
