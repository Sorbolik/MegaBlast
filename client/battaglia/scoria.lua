-- Il personaggio in battaglia: il diavoletto di Gabriella in pixel art, animato
-- coi fotogrammi di Ludo (strumenti/grafica/diavoletto.py). Dalla cima della
-- testa ai piedi è alto come il corpo della simulazione (ROBOT_H), così quello
-- che si vede è quello che colpisce e viene colpito; corna e fiammella sporgono sopra.
--
-- Lo usano la battaglia (game.gui_script), la home (menu/home.lua) e il podio:
--   local s = scoria.new(colore)
--   scoria.update(s, dt, stato)    -- a ogni frame, nessuna allocazione
--   scoria.set_weapon(s, nome) / hit(s) / fire(s, tipo) / lunge(s) / teleport(s) / die(s)
--   scoria.set_color(s, colore)    -- la squadra cambia da una partita all'altra
-- stato: x, y, facing, grounded, moving, aim (se mira), paracadute, festa (podio)
--
-- Un foglio di fotogrammi per azione: riposo (con un sospiro ogni tanto), corsa,
-- corsa armata, salto, mira, fendente, lancio, colpito, teletrasporto, vittoria e
-- paracadute. L'arma gira attorno alla spalla con la mira; il braccio è già nei
-- disegni. Il colore della squadra è l'alone attorno alla fiammella.
--
-- I fotogrammi non si deformano: il movimento è tutto nei disegni. Sopra restano
-- solo la spinta e il lampo rosso quando si viene colpiti e il rinculo dell'arma.

local game = require "sim.game"
local config = require "sim.config"
local FOTO = require "battaglia.diavoletto"

local M = {}

-- altezza del personaggio in cima alla fiammella, per mettere sopra vita e freccia
local R = FOTO.riposo[1]
M.ALTEZZA = game.ROBOT_H * (R.y + R.h / 2) / 200

local sin, cos, min, max, abs, pi, floor = math.sin, math.cos, math.min, math.max, math.abs, math.pi, math.floor
local DEG = 180 / pi

local OMBRA = vmath.vector4(0, 0, 0, 0.35)
local BIANCO = vmath.vector4(1, 1, 1, 1)
-- il colpo subito tinge di rosso (i colori dei disegni si possono solo scurire)
local LAMPO = vmath.vector4(1, 0.3, 0.3, 1)
local FERRO = vmath.vector4(0.3, 0.29, 0.34, 1)
local LAMA = vmath.vector4(0.86, 0.88, 0.95, 1)

-- molle: posizione, velocità, rigidità, smorzamento
local SHOVE, KICK = 1, 2
local W_MOLLA = { 12, 18 }
local Z_MOLLA = { 0.5, 0.45 }

-- la mano sull'impugnatura, a PRESA dalla spalla lungo l'arma (unità)
local PRESA = 52
-- la spalla nei fotogrammi, dal punto d'appoggio (unità, y verso l'alto)
local SPALLA = FOTO.spalla
-- un passo: la strada che fa il corpo in un giro intero della corsa
local PASSO = 0.9
-- i fogli di Ludo vanno a 12 fotogrammi al secondo; il sospiro parte da fermo
-- ogni SOSPIRO secondi (più o meno), dal punto in cui il respiro torna indietro
local FPS = 12
local SOSPIRO = { 6, 10 }

-- quanto durano le azioni (secondi) e da che fotogrammi passano
local AZIONI = {
	colpito = { "colpito", 0.5, 1, #FOTO.colpito },
	lancio = { "lancio", 0.5, 1, #FOTO.lancio },
	-- il teletrasporto arriva quando il robot è già nel punto nuovo: ricompare
	-- dalla fiammella (fotogramma 6)
	teletrasporto = { "teletrasporto", 0.5, 6, #FOTO.teletrasporto },
	rinculo = { "mira", 0.35, 8, 12 },
	-- dopo il salto: dall'atterraggio (12) a in piedi (16)
	atterraggio = { "salto", 0.35, 12, 16 },
	-- il sospiro: dal respiro (riposo a metà giro) agli occhi chiusi e di nuovo all'inizio
	sospiro = { "sospiro", #FOTO.sospiro / FPS, 1, #FOTO.sospiro },
}
-- in aria il salto va per velocità: dallo stacco (1) alla caduta (11), a
-- metà quando è in cima; V_SALTO è la velocità con cui si stacca da terra
local SALTO_ARIA = 11
local V_SALTO = math.sqrt(2 * game.GRAVITY * game.base_stats().jump_height)
-- sconfitta: per ora i fotogrammi del colpo, poi svanisce
local MORTE_FOTO, MORTE_VIA, MORTE_FINE = 0.5, 1.0, 1.5

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
		x = {}, v = {}, goal = {} }
	local k = s.k
	s.root = vuoto(nil, 0, 0)
	gui.set_adjust_mode(s.root, gui.ADJUST_STRETCH)
	s.alpha = vmath.vector4(1, 1, 1, 1)
	s.luce_col = vmath.vector4(color.x, color.y, color.z, 0.8)
	s.tinta = vmath.vector4(1, 1, 1, 1)

	s.ombra = cerchio(s.root, 0, 0, Wd * 1.3, OMBRA)
	scale(s.ombra, 1, 0.22)
	-- corpo: la spinta quando si viene colpiti
	s.corpo = vuoto(s.root, 0, 0)
	s.figura = immagine(s.corpo, R.img)
	-- l'alone della squadra attorno alla fiammella
	s.luce = immagine(s.corpo, "bagliore")
	gui.set_size(s.luce, vmath.vector3(60 * k, 60 * k, 0))
	gui.set_blend_mode(s.luce, gui.BLEND_ADD)
	gui.set_color(s.luce, s.luce_col)
	s.tinte[#s.tinte + 1] = s.luce

	-- l'arma gira attorno alla spalla
	s.spalla = vuoto(s.corpo, SPALLA[1] * k, SPALLA[2] * k)
	gui.set_visible(s.spalla, false)
	for name in pairs(ARMI) do arma(s, name, color) end
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
	s.t = math.random() * 10
	s.vy, s.last_x, s.last_y, s.ground = 0, nil, nil, true
	s.passo, s.cammina, s.in_moto = 0, 0, 0
	s.flash = 0
	s.azione, s.at = nil, 0
	s.mira = ARMI.missile.riposo
	s.morte, s.morto = nil, nil
	s.fermo, s.sospiro = 0, SOSPIRO[1] + math.random() * (SOSPIRO[2] - SOSPIRO[1])
	s.alpha.w = 1
	gui.set_color(s.root, s.alpha)
	gui.set_color(s.figura, BIANCO)
	if s.arma_scelta then gui.set_enabled(s.armi[s.arma_scelta], true) end
	s.foto = nil
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

-- Mostra il fotogramma i dell'azione: immagine, misura, posto e fiammella
local function mostra(s, azione, i)
	local lista = FOTO[azione]
	local f = lista[max(1, min(#lista, i))]
	if s.foto == f then return end
	s.foto = f
	local k = s.k
	gui.play_flipbook(s.figura, f.img)
	V.x, V.y, V.z = f.w * k, f.h * k, 0
	gui.set_size(s.figura, V)
	pos(s.figura, f.x * k, f.y * k)
	if f.fx then
		pos(s.luce, f.fx * k, f.fy * k)
		gui.set_enabled(s.luce, true)
	else
		gui.set_enabled(s.luce, false)
	end
end

-- un giro che si ripete: il fotogramma a t (in fotogrammi)
local function giro(s, azione, t)
	local n = #FOTO[azione]
	mostra(s, azione, 1 + floor(t) % n)
end

-- un'azione a tempo: dal suo primo all'ultimo fotogramma in AZIONI[nome][2] secondi
local function azione(s, nome)
	s.azione, s.at = nome, 0
end

-- Sconfitta: i fotogrammi fino a terra, poi svanisce. Il terreno sotto può non
-- esserci più (il cratere), quindi alla fine non resta niente
local function morte(s, dt)
	local t = s.morte + dt
	s.morte = t
	mostra(s, "colpito", 1 + floor(min(1, t / MORTE_FOTO) * (#FOTO.colpito - 1) + 0.5))
	s.alpha.w = min(1, max(0, (MORTE_FINE - t) / (MORTE_FINE - MORTE_VIA)))
	gui.set_color(s.root, s.alpha)
	if s.alpha.w == 0 then
		s.morto = true
		gui.set_enabled(s.root, false)
	end
end

-- l'angolo della Lama nel fendente (locale, verso avanti) diventa il fotogramma:
-- da dietro la schiena (SWORD_FROM) a davanti in basso (SWORD_TO)
local function fendente(a)
	local da, a_ = game.SWORD_FROM, game.SWORD_TO
	if a < a_ - 0.5 then a = a + 2 * pi end
	local p = max(0, min(1, (da - a) / (da - a_)))
	return 1 + floor(p * (#FOTO.fendente - 1) + 0.5)
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
	if corre then s.passo = (s.passo + dx / (PASSO * s.h)) % 1 end
	s.cammina = s.cammina + ((corre and 1 or 0) - s.cammina) * min(1, dt * 10)
	s.in_moto = corre and s.in_moto + dt or 0

	-- atterraggio: il fotogramma accucciato del salto
	if ground and not s.ground and s.vy < -40 then azione(s, "atterraggio") end
	s.ground = ground

	molle(s, dt)
	pos(s.corpo, -s.x[SHOVE] * s.w, 0)

	-- l'arma gira attorno alla spalla verso la mira; dopo lo sparo resta dov'era
	if st.aim then s.mira = face > 0 and st.aim or pi - st.aim end

	-- la posa: prima le azioni a tempo, poi la mira, poi il movimento
	local braccio = false
	local A = s.azione and AZIONI[s.azione]
	if A and st.aim and s.azione == "lancio" then A = nil end
	if A then
		s.at = s.at + dt
		local p = min(1, s.at / A[2])
		mostra(s, A[1], A[3] + floor(p * (A[4] - A[3]) + 0.5))
		braccio = s.azione == "rinculo"
		if s.at >= A[2] then s.azione = nil end
	elseif st.aim then
		braccio = true
		if s.arma_scelta == "sword" then
			mostra(s, "fendente", fendente(s.mira))
		elseif s.cammina > 0.5 then
			-- corre mirando: le gambe corrono, l'arma segue il dito
			giro(s, "corsa_armata", s.passo * #FOTO.corsa_armata)
		else
			-- mirando respira avanti e indietro tra le pose ferme (1-7)
			local i = floor(s.t * 6) % 12
			mostra(s, "mira", 1 + (i < 7 and i or 12 - i))
		end
	elseif st.paracadute then
		giro(s, "paracadute", s.t * FPS)
	elseif not ground then
		local p = max(0, min(1, (V_SALTO - s.vy) / (2 * V_SALTO)))
		mostra(s, "salto", 1 + floor(p * (SALTO_ARIA - 1) + 0.5))
	elseif s.cammina > 0.5 then
		giro(s, "corsa", s.passo * #FOTO.corsa)
	elseif st.festa then
		giro(s, "vittoria", s.t * FPS / 2)
	else
		-- il respiro va avanti e indietro; a metà giro (occhi aperti, il punto
		-- da cui parte il sospiro nel foglio), se è ora, sospira
		local n = #FOTO.riposo
		local i = floor(s.fermo * FPS) % n
		if i == floor(n / 2) and s.fermo > s.sospiro then
			s.fermo, s.sospiro = 0, SOSPIRO[1] + math.random() * (SOSPIRO[2] - SOSPIRO[1])
			azione(s, "sospiro")
		end
		mostra(s, "riposo", 1 + i)
	end
	-- il respiro conta solo da fermi
	if s.azione or st.aim or not ground or s.cammina > 0.5 or st.festa or st.paracadute then
		if s.azione ~= "sospiro" then s.fermo = 0 end
	else
		s.fermo = s.fermo + dt
	end
	gui.set_enabled(s.armi[s.arma_scelta], braccio)

	-- l'alone respira
	s.luce_col.w = 0.55 + 0.25 * sin(s.t * 3.1)
	gui.set_color(s.luce, s.luce_col)

	-- lampo rosso del colpo
	if s.flash > 0 then
		s.flash = max(0, s.flash - dt * 6)
		local f = min(1, s.flash * 1.5)
		C.x, C.y, C.z, C.w = 1, 1 + (LAMPO.y - 1) * f, 1 + (LAMPO.z - 1) * f, 1
		gui.set_color(s.figura, C)
	end

	local a = st.aim and s.mira or (braccio and s.mira or ARMI[s.arma_scelta].riposo)
	rot(s.spalla, a)
	-- il rinculo porta indietro arma e braccio, mai oltre la spalla
	local r = -min(s.x[KICK] * s.w * 0.6, PRESA * s.k * 0.8)
	pos(s.armi[s.arma_scelta], r, 0)
end

function M.set_weapon(s, name)
	if s.arma_scelta == name or not s.armi[name] then return end
	if s.arma_scelta then gui.set_enabled(s.armi[s.arma_scelta], false) end
	s.arma_scelta = name
	-- da morto l'arma non c'è più
	gui.set_enabled(s.armi[name], not s.morte)
end

-- Colpo subito: lampo rosso, i fotogrammi del colpo, spinta e inclinazione nella
-- direzione del colpo (dx: verso dove spinge, nel mondo; senza, da davanti)
function M.hit(s, dx)
	local d = (dx and dx ~= 0) and (dx > 0 and 1 or -1) * s.face or -1
	s.flash = 1
	azione(s, "colpito")
	s.v[SHOVE] = s.v[SHOVE] - 9 * d
end

-- Colpo sparato: rinculo dell'arma e del corpo; un lancio ha i suoi fotogrammi
function M.fire(s, kind)
	local k = kind == "shards" and 0.5 or 1
	azione(s, kind == "throw" and "lancio" or "rinculo")
	s.v[KICK] = s.v[KICK] + 14 * k
end

-- Scatto dell'Affondo: il corpo parte un attimo prima, in avanti
function M.lunge(s)
	s.v[SHOVE] = s.v[SHOVE] - 6
end

-- Arrivo col teletrasporto: ricompare dalla fiammella
function M.teleport(s)
	azione(s, "teletrasporto")
end

function M.die(s)
	if s.morte then return end
	s.morte = 0
	gui.set_enabled(s.armi[s.arma_scelta], false)
end

return M
