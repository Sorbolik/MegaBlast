-- Il personaggio in battaglia, nella home e sul podio: il diavoletto a
-- fotogrammi (strumenti/grafica/diavolo.py -> battaglia/diavolo.lua). Dalla cima
-- della testa ai piedi è alto come il corpo della simulazione (ROBOT_H); corna,
-- fiammella e coda sporgono.
--
--   local p = personaggio.new(colore)
--   personaggio.update(p, dt, stato)     -- a ogni frame, nessuna allocazione
--   personaggio.set_weapon(p, nome) / hit(p) / fire(p, tipo) / lunge(p) / teleport(p) / die(p)
--   personaggio.set_color(p, colore)     -- la squadra cambia da una partita all'altra
-- stato: x, y, facing, grounded, moving, aim (se mira), suolo (il terreno sotto
-- il centro, se c'è), fendente (0..1 durante il colpo), paracadute, festa (podio)
--
-- Il disegno non ha braccia: il gioco aggiunge il braccio davanti, che gira
-- attorno alla spalla con l'arma, e per le armi a due mani quello dietro, che
-- dalla sua spalla raggiunge la seconda presa passando davanti al petto. Con
-- un'arma a una mano il braccio dietro non c'è: di tre quarti resta nascosto.
--
-- Animazioni: una per stato, scelte in ordine (sconfitta, teletrasporto,
-- colpito, fendente, lancio, aria, corsa, guardia). Quelle a tempo vanno a fps
-- fissi; la corsa va con la strada fatta, il salto con la velocità verticale, il
-- fendente con il colpo. Un'animazione che non c'è ancora diventa la guardia.

local game = require "sim.game"
local config = require "sim.config"
local D = require "battaglia.diavolo"

local M = {}

local A = D.animazioni
local K = game.ROBOT_H / D.altezza   -- unità del mondo per pixel del disegno
-- altezza in cima alla fiammella, per mettere sopra vita e freccia
M.ALTEZZA = D.fiammella[2] * K

local sin, min, max, abs, pi, floor, atan2, sqrt = math.sin, math.min, math.max, math.abs, math.pi, math.floor, math.atan2, math.sqrt
local DEG = 180 / pi

local OMBRA = vmath.vector4(0, 0, 0, 0.35)
local LAMPO = vmath.vector4(1, 0.3, 0.3, 1)
local FERRO = vmath.vector4(0.3, 0.29, 0.34, 1)
local LAMA = vmath.vector4(0.86, 0.88, 0.95, 1)

-- un giro della corsa: la strada che fa il corpo, in altezze del personaggio
local PASSO = 1.6
-- quanto durano le azioni a tempo (secondi)
local DURATA = { colpito = 0.4, lancio = 0.45, teletrasporto = 0.4 }
-- il disegno scende sul terreno sotto il centro (al massimo un gradino) e sale
-- i gradini in questo tempo, invece di scattare
local SCALINO = 0.08
-- da sconfitto resta almeno MORTE secondi, poi svanisce in mezzo secondo
local MORTE = 0.8

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
local function size(node, w, h)
	V.x, V.y, V.z = w, h, 0
	gui.set_size(node, V)
end

local function setup(n, parent, color)
	gui.set_inherit_alpha(n, true)
	if parent then gui.set_parent(n, parent) end
	if color then gui.set_color(n, color) end
	return n
end
local function box(parent, x, y, w, h, color)
	return setup(gui.new_box_node(vmath.vector3(x, y, 0), vmath.vector3(w, h, 0)), parent, color)
end
local function cerchio(parent, x, y, d, color)
	local n = setup(gui.new_pie_node(vmath.vector3(x, y, 0), vmath.vector3(d, d, 0)), parent, color)
	gui.set_perimeter_vertices(n, 32)
	return n
end
local function vuoto(parent, x, y)
	local n = box(parent, x, y, 0, 0)
	gui.set_visible(n, false)
	return n
end
local function immagine(parent, nome)
	local n = box(parent, 0, 0, 0, 0)
	gui.set_texture(n, "battaglia")
	gui.play_flipbook(n, nome)
	return n
end

-- Le armi: angolo a riposo (radianti, verso avanti) e, per quelle a due mani,
-- dove sta la seconda mano lungo l'arma, davanti alla prima (in altezze): la
-- spalla dietro, di tre quarti, è più avanti di quella davanti
local ARMI = {
	missile = { riposo = -0.35, presa2 = 0.2 },
	sword = { riposo = -1.9, presa2 = 0.08 },
	teleport = { riposo = -0.5 },
	grenade = { riposo = -0.5 },
	shards = { riposo = -0.3, presa2 = 0.2 },
	punch = { riposo = -0.9 },
	eagle = { riposo = -0.6 },
	hook = { riposo = -0.4 },
	mallet = { riposo = -1.6, presa2 = 0.2 },
	lunge = { riposo = -1.4, presa2 = 0.2 },
}

-- il pugno del braccio davanti è a PRESA dalla spalla: lì comincia l'arma
local PRESA = D.braccio.presa * K

local function arma(p, name, color)
	local H = p.h
	-- l'arma gira con la spalla; il suo zero è nel pugno
	local g = vuoto(p.spalla, PRESA, 0)
	if name == "missile" then
		-- la bocca è dove la simulazione fa partire il colpo (game.MUZZLE)
		local L = game.MUZZLE
		box(g, L / 2 - PRESA * 0.6, 0, L, H * 0.22, FERRO)
		p.tinte[#p.tinte + 1] = box(g, L - PRESA * 0.6 - H * 0.05, 0, H * 0.1, H * 0.26, color)
	elseif name == "sword" then
		-- la lama arriva fino a SWORD_REACH dalla spalla
		local L = game.SWORD_REACH - PRESA
		box(g, H * 0.06 + L / 2, 0, L, max(2, H * 0.1), LAMA)
		box(g, H * 0.06, 0, H * 0.06, H * 0.3, FERRO)
		box(g, -H * 0.06, 0, H * 0.2, max(2, H * 0.07), FERRO)
	elseif name == "shards" then
		box(g, H * 0.15, 0, H * 0.7, H * 0.3, FERRO)
	elseif name == "teleport" then
		p.tinte[#p.tinte + 1] = cerchio(g, H * 0.1, 0, H * 0.32, color)
	elseif name == "grenade" then
		cerchio(g, H * 0.1, 0, H * 0.36, FERRO)
	elseif name == "eagle" then
		-- Tonante: canna corta e grossa, il calcio in giù nel pugno
		box(g, H * 0.25, H * 0.08, H * 0.55, H * 0.16, FERRO)
		box(g, 0, 0, H * 0.1, H * 0.2, FERRO)
	elseif name == "hook" then
		-- Rampino: una canna sottile con l'uncino aperto in punta
		box(g, H * 0.3, 0, H * 0.7, max(2, H * 0.08), FERRO)
		box(g, H * 0.65, H * 0.08, max(2, H * 0.08), H * 0.2, LAMA)
	elseif name == "mallet" then
		-- Maglio: manico lungo, le mani in fondo, la testa pesante in punta
		local L = H * 1.1
		box(g, L * 0.5 - H * 0.35, 0, L, max(2, H * 0.08), FERRO)
		box(g, L - H * 0.35, 0, H * 0.22, H * 0.4, FERRO)
		box(g, L - H * 0.29, 0, H * 0.06, H * 0.4, LAMA)
	elseif name == "lunge" then
		-- Affondo: lancia lunga e sottile, con la punta chiara
		local L = config.LUNGE.speed * config.LUNGE.ticks / 60 * 0.4
		box(g, L * 0.5 - H * 0.35, 0, L, max(2, H * 0.07), FERRO)
		box(g, L - H * 0.35, 0, H * 0.18, max(2, H * 0.12), LAMA)
	else -- punch: il guanto attorno al pugno
		cerchio(g, 0, 0, H * 0.32, FERRO)
	end
	gui.set_enabled(g, false)
	p.armi[name] = g
end

local function braccio(parent, nome)
	local b = D.braccio
	local n = immagine(parent, nome)
	pos(n, b.x * K, b.y * K)
	size(n, b.w * K, b.h * K)
	return n
end

function M.new(color)
	local H = game.ROBOT_H
	local p = { color = color, h = H, armi = {}, tinte = {} }
	p.root = vuoto(nil, 0, 0)
	gui.set_visible(p.root, true)
	gui.set_adjust_mode(p.root, gui.ADJUST_STRETCH)
	p.alpha = vmath.vector4(1, 1, 1, 1)
	p.luce_col = vmath.vector4(color.x, color.y, color.z, 0.6)

	p.ombra = cerchio(p.root, 0, 0, 2 * game.ROBOT_HALF_W * 1.2, OMBRA)
	V.x, V.y, V.z = 1, 0.22, 1
	gui.set_scale(p.ombra, V)
	-- corpo: la spinta quando si viene colpiti; dentro, in ordine di disegno,
	-- l'alone della squadra, il disegno, il braccio dietro (che con le armi a
	-- due mani passa davanti al petto), l'arma e il braccio davanti
	p.corpo = vuoto(p.root, 0, 0)
	p.luce = cerchio(p.corpo, 0, 0, H * 0.22, p.luce_col)
	p.figura = immagine(p.corpo, A.guardia[1].img)
	p.spalla_dietro = vuoto(p.corpo, 0, 0)
	p.braccio_dietro = braccio(p.spalla_dietro, "braccio_dietro")
	p.spalla = vuoto(p.corpo, 0, 0)
	for name in pairs(ARMI) do arma(p, name, color) end
	p.braccio = braccio(p.spalla, "braccio")
	M.set_weapon(p, "missile")
	M.reset(p)
	return p
end

function M.set_color(p, color)
	if p.color == color then return end
	p.color = color
	p.luce_col.x, p.luce_col.y, p.luce_col.z = color.x, color.y, color.z
	C.x, C.y, C.z, C.w = color.x, color.y, color.z, 1
	for _, n in ipairs(p.tinte) do gui.set_color(n, C) end
end

function M.reset(p)
	p.t = math.random() * 10
	p.azione, p.azione_t = nil, 0
	p.passo, p.vy, p.last_x, p.last_y, p.yd = 0, 0, nil, nil, nil
	p.flash, p.spinta, p.rinculo = 0, 0, 0
	p.morte, p.morto = nil, nil
	p.alpha.w = 1
	gui.set_color(p.root, p.alpha)
	gui.set_enabled(p.braccio, true)
	if p.arma_scelta then gui.set_enabled(p.armi[p.arma_scelta], true) end
	gui.set_color(p.figura, vmath.vector4(1, 1, 1, 1))
	p.face = 1
end

function M.set_enabled(p, on)
	if on and p.morte then M.reset(p) end
	gui.set_enabled(p.root, on)
end

-- Mostra il fotogramma i (da 1) dell'animazione nome; ritorna il fotogramma
local function mostra(p, nome, i)
	local anim = A[nome] or A.guardia
	local f = anim[max(1, min(#anim, i))]
	if p.img ~= f.img then
		gui.play_flipbook(p.figura, f.img)
		size(p.figura, f.w * K, f.h * K)
		pos(p.figura, f.x * K, f.y * K)
		p.img = f.img
	end
	return f
end
-- fotogramma di un'animazione a tempo dopo t secondi
local function a_tempo(nome, t)
	local anim = A[nome] or A.guardia
	local i = floor(t * anim.fps)
	return anim.giro and 1 + i % #anim or 1 + min(i, #anim - 1)
end
-- fotogramma di un'animazione portata da 0 a 1
local function a_parte(nome, u)
	local anim = A[nome] or A.guardia
	return 1 + floor(max(0, min(0.999, u)) * #anim)
end

-- la velocità con cui si stacca da terra saltando, per il salto in aria
local V_SALTO = sqrt(2 * game.GRAVITY * game.base_stats().jump_height)

function M.update(p, dt, st)
	if p.morto then return end
	dt = min(dt, 1 / 20)
	p.t = p.t + dt
	local face = st.facing
	p.face = face
	V.x, V.y, V.z = face, 1, 1
	gui.set_scale(p.root, V)

	if p.last_y then
		local vy = (st.y - p.last_y) / max(dt, 1e-4)
		p.vy = p.vy + (vy - p.vy) * min(1, dt * 14)
	end
	local dx = p.last_x and abs(st.x - p.last_x) or 0
	p.last_x, p.last_y = st.x, st.y

	-- dove si disegna: a terra sul terreno sotto il centro, salendo i gradini
	-- in SCALINO secondi; in aria dove dice la simulazione
	local y = st.y
	if st.grounded and st.suolo and st.suolo <= st.y and st.suolo > st.y - game.MAX_CLIMB then y = st.suolo end
	if st.grounded and p.yd and abs(y - p.yd) < game.MAX_CLIMB * 1.5 then
		y = p.yd + (y - p.yd) * min(1, dt / SCALINO)
	end
	p.yd = y
	pos(p.root, st.x, y)

	-- il fotogramma: il primo stato che vale, in ordine
	local f
	if p.morte then
		p.morte = p.morte + dt
		local anim = A.sconfitta
		local fine = anim and #anim / anim.fps or 0
		f = mostra(p, anim and "sconfitta" or "guardia", a_tempo("sconfitta", p.morte))
		-- il terreno sotto può non esserci più (il cratere): alla fine svanisce
		p.alpha.w = max(0, 1 - max(0, p.morte - max(fine, MORTE)) / 0.5)
		gui.set_color(p.root, p.alpha)
		if p.alpha.w == 0 then
			p.morto = true
			gui.set_enabled(p.root, false)
			return
		end
	elseif p.azione and p.azione_t < DURATA[p.azione] then
		p.azione_t = p.azione_t + dt
		f = mostra(p, p.azione, a_parte(p.azione, p.azione_t / DURATA[p.azione]))
	elseif st.fendente then
		f = mostra(p, "fendente", a_parte("fendente", st.fendente))
	elseif st.paracadute and not st.grounded then
		f = mostra(p, "paracadute", a_tempo("paracadute", p.t))
	elseif not st.grounded then
		-- dallo stacco (velocità piena in su) alla caduta (piena in giù): la
		-- prima parte del salto; l'ultima è l'atterraggio
		f = mostra(p, "salto", a_parte("salto", (0.5 - p.vy / (2 * V_SALTO)) * 0.75))
	elseif st.moving ~= 0 and dx < p.h then
		p.passo = (p.passo + dx / (PASSO * p.h)) % 1
		f = mostra(p, "corsa", a_parte("corsa", p.passo))
	elseif st.festa then
		f = mostra(p, "vittoria", a_tempo("vittoria", p.t))
	else
		f = mostra(p, "guardia", a_tempo("guardia", p.t))
	end

	-- l'alone della squadra attorno alla fiammella, che respira
	pos(p.luce, (D.fiammella[1] + f.dx) * K, (D.fiammella[2] + f.dy) * K)
	p.luce_col.w = 0.45 + 0.2 * sin(p.t * 3.1)
	gui.set_color(p.luce, p.luce_col)

	-- lampo rosso del colpo
	if p.flash > 0 then
		p.flash = max(0, p.flash - dt * 6)
		local q = min(1, p.flash * 1.5)
		C.x, C.y, C.z, C.w = 1, 1 + (LAMPO.y - 1) * q, 1 + (LAMPO.z - 1) * q, 1
		gui.set_color(p.figura, C)
	end
	-- spinta del colpo subito e rinculo dell'arma: tornano a zero in fretta
	p.spinta = p.spinta * max(0, 1 - dt * 10)
	p.rinculo = p.rinculo * max(0, 1 - dt * 14)
	pos(p.corpo, -p.spinta * p.h, 0)

	-- braccio davanti e arma: dalla spalla verso la mira, altrimenti a riposo
	local w = ARMI[p.arma_scelta]
	local a = w.riposo
	if st.aim then a = face > 0 and st.aim or pi - st.aim end
	local sx, sy = (D.spalla[1] + f.dx) * K, (D.spalla[2] + f.dy) * K
	pos(p.spalla, sx, sy)
	rot(p.spalla, a)
	-- il rinculo porta indietro arma e braccio lungo l'arma
	local r = p.rinculo * p.h * 0.15
	pos(p.armi[p.arma_scelta], PRESA - r, 0)
	pos(p.braccio, D.braccio.x * K - r, D.braccio.y * K)

	-- braccio dietro: solo con le armi a due mani, dalla sua spalla alla seconda presa
	local due = w.presa2 ~= nil and not p.morte
	gui.set_enabled(p.spalla_dietro, due)
	if due then
		local d = PRESA + w.presa2 * p.h
		local tx, ty = sx + math.cos(a) * d, sy + sin(a) * d
		local bx, by = (D.spalla_dietro[1] + f.dx) * K, (D.spalla_dietro[2] + f.dy) * K
		pos(p.spalla_dietro, bx, by)
		rot(p.spalla_dietro, atan2(ty - by, tx - bx))
		-- il braccio si allunga o si accorcia un po' per arrivare alla presa
		local l = sqrt((tx - bx) ^ 2 + (ty - by) ^ 2) / PRESA
		V.x, V.y, V.z = max(0.5, min(1.6, l)), 1, 1
		gui.set_scale(p.spalla_dietro, V)
	end
end

function M.set_weapon(p, name)
	if p.arma_scelta == name or not p.armi[name] then return end
	if p.arma_scelta then gui.set_enabled(p.armi[p.arma_scelta], false) end
	p.arma_scelta = name
	-- da morto l'arma non c'è più
	gui.set_enabled(p.armi[name], not p.morte)
end

local function azione(p, nome)
	p.azione, p.azione_t = nome, 0
end

-- Colpo subito: lampo rosso, i fotogrammi del colpo e una spinta nella
-- direzione del colpo (dx: verso dove spinge, nel mondo; senza, da davanti)
function M.hit(p, dx)
	local d = (dx and dx ~= 0) and (dx > 0 and 1 or -1) * p.face or -1
	p.flash = 1
	p.spinta = 0.25 * d
	azione(p, "colpito")
end

-- Colpo sparato: rinculo dell'arma; un lancio ha i suoi fotogrammi
function M.fire(p, kind)
	p.rinculo = kind == "shards" and 0.5 or 1
	if kind == "throw" then azione(p, "lancio") end
end

-- Scatto dell'Affondo: il corpo parte un attimo prima, in avanti
function M.lunge(p)
	p.spinta = -0.2
end

-- Arrivo col teletrasporto: ricompare dalla fiammella
function M.teleport(p)
	azione(p, "teletrasporto")
end

-- Sconfitta: l'arma cade e il braccio sparisce, poi i fotogrammi e svanisce
function M.die(p)
	if p.morte then return end
	p.morte = 0
	gui.set_enabled(p.armi[p.arma_scelta], false)
	gui.set_enabled(p.braccio, false)
	gui.set_enabled(p.spalla_dietro, false)
end

return M
