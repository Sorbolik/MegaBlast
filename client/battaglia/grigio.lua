-- Corpo in grigio (fase 2 della roadmap): una capsula con un occhio, grande
-- esattamente come il corpo della simulazione (ROBOT_H x 2 ROBOT_HALF_W), così
-- quello che si vede è quello che colpisce e viene colpito. Serve a decidere
-- taglia, salto e armi prima di disegnare il personaggio vero.
--
-- Lo usano la battaglia (game.gui_script) e la home (menu/home.lua):
--   local s = grigio.new(colore)
--   grigio.update(s, dt, stato)    -- a ogni frame, nessuna allocazione
--   grigio.set_weapon(s, nome) / hit(s) / fire(s, tipo) / teleport(s) / die(s)
--
-- Le animazioni sono poche molle sul corpo intero: schiaccia e allunga
-- (atterraggio, stacco, teletrasporto), inclinazione nella corsa, spinta e lampo
-- bianco quando si viene colpiti, rinculo dell'arma, occhio che sbatte e guarda
-- dove si mira.

local game = require "sim.game"

local M = {}

local sin, cos, min, max, abs, pi = math.sin, math.cos, math.min, math.max, math.abs, math.pi
local DEG = 180 / pi

local GRIGIO = vmath.vector4(0.64, 0.62, 0.7, 1)
local BORDO = vmath.vector4(0.07, 0.06, 0.09, 1)
local BIANCO = vmath.vector4(1, 1, 1, 1)
local FERRO = vmath.vector4(0.3, 0.29, 0.34, 1)
local LAMA = vmath.vector4(0.86, 0.88, 0.95, 1)

-- molle: posizione, velocità, rigidità, smorzamento
local SQ, LEAN, SHOVE, KICK = 1, 2, 3, 4
local W_MOLLA = { 16, 10, 12, 18 }
local Z_MOLLA = { 0.3, 0.45, 0.5, 0.45 }

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
	local n = box(parent, x, y, 0, 0)
	gui.set_visible(n, false)
	return n
end

-- capsula larga w e alta h con il fondo in y = 0; restituisce i suoi tre nodi
local function capsula(parent, w, h, y0, color, out)
	local r = w / 2
	out[#out + 1] = cerchio(parent, 0, y0 + r, w, color)
	out[#out + 1] = cerchio(parent, 0, y0 + h - r, w, color)
	out[#out + 1] = box(parent, 0, y0 + h / 2, w, max(0, h - w), color)
end

-- Le armi in mano, attorno alla spalla: angolo di riposo (radianti, verso
-- avanti) e come sono fatte, in proporzione all'altezza del corpo
local ARMI = {
	missile = { riposo = -0.35 },
	sword = { riposo = -1.9 },
	teleport = { riposo = -0.5 },
	grenade = { riposo = -0.5 },
	shards = { riposo = -0.3 },
	punch = { riposo = -0.9 },
}

local function arma(s, name, color)
	local H, Wd = s.h, s.w
	local g = vuoto(s.spalla, 0, 0)
	if name == "missile" then
		-- la bocca è dove la simulazione fa partire il colpo (game.MUZZLE)
		local L = game.MUZZLE
		box(g, L / 2, 0, L, H * 0.22, FERRO)
		box(g, L - H * 0.05, 0, H * 0.1, H * 0.26, color)
	elseif name == "sword" then
		local L = game.SWORD_REACH
		box(g, L * 0.55, 0, L * 0.9, max(2, H * 0.1), LAMA)
		box(g, L * 0.08, 0, H * 0.08, H * 0.3, FERRO)
	elseif name == "shards" then
		box(g, H * 0.32, 0, H * 0.7, H * 0.3, FERRO)
	elseif name == "teleport" then
		cerchio(g, H * 0.45, 0, H * 0.32, color)
	elseif name == "grenade" then
		cerchio(g, H * 0.45, 0, H * 0.36, FERRO)
	else -- punch
		cerchio(g, H * 0.45, 0, Wd * 0.8, FERRO)
	end
	-- la mano che tiene l'arma
	cerchio(g, H * 0.16, 0, Wd * 0.42, GRIGIO)
	gui.set_enabled(g, false)
	s.armi[name] = g
end

function M.new(color)
	local H, Wd = game.ROBOT_H, 2 * game.ROBOT_HALF_W
	local s = { color = color, h = H, w = Wd, armi = {}, pelle = {}, x = {}, v = {} }
	s.root = vuoto(nil, 0, 0)
	gui.set_adjust_mode(s.root, gui.ADJUST_STRETCH)
	s.alpha = vmath.vector4(1, 1, 1, 1)

	s.ombra = cerchio(s.root, 0, 0, Wd * 1.3, vmath.vector4(0, 0, 0, 0.35))
	scale(s.ombra, 1, 0.22)
	-- corpo: inclinazione e spinta; forma: schiaccia e allunga. L'arma sta sul
	-- corpo e non sulla forma, così schiacciandosi non si storce la mira
	s.corpo = vuoto(s.root, 0, 0)
	s.forma = vuoto(s.corpo, 0, 0)
	local bordo = {}
	capsula(s.forma, Wd + 2, H + 2, -1, BORDO, bordo)
	capsula(s.forma, Wd, H, 0, GRIGIO, s.pelle)

	-- l'occhio: il colore della squadra, con la pupilla che guarda dove si mira
	s.occhio = vuoto(s.forma, Wd * 0.14, H * 0.66)
	cerchio(s.occhio, 0, 0, Wd * 0.66, BORDO)
	cerchio(s.occhio, 0, 0, Wd * 0.56, color)
	s.pupilla = cerchio(s.occhio, 0, 0, Wd * 0.22, BIANCO)

	s.spalla = vuoto(s.corpo, -Wd * 0.05, H * 0.45)
	for name in pairs(ARMI) do arma(s, name, color) end
	M.set_weapon(s, "missile")

	M.reset(s)
	return s
end

function M.reset(s)
	for i = 1, #W_MOLLA do s.x[i], s.v[i] = 0, 0 end
	s.x[SQ] = 1
	s.t = math.random() * 10
	s.vy, s.last_y, s.ground = 0, nil, true
	s.flash, s.blink = 0, 2 + math.random() * 3
	s.morte, s.morto = nil, nil
	s.alpha.w = 1
	gui.set_color(s.root, s.alpha)
end

function M.set_enabled(s, on)
	if on and s.morte then M.reset(s) end
	gui.set_enabled(s.root, on)
end

local function molle(s, dt, target_sq, target_lean)
	local x, v = s.x, s.v
	local n = max(1, math.ceil(dt * 120))
	local h = dt / n
	for _ = 1, n do
		for i = 1, #W_MOLLA do
			local w, z = W_MOLLA[i], Z_MOLLA[i]
			local goal = i == SQ and target_sq or (i == LEAN and target_lean or 0)
			v[i] = v[i] + (w * w * (goal - x[i]) - 2 * z * w * v[i]) * h
			x[i] = x[i] + v[i] * h
		end
	end
end

function M.update(s, dt, st)
	if s.morto then return end
	dt = min(dt, 1 / 20)
	s.t = s.t + dt
	local face = st.facing
	scale(s.root, face, 1)
	pos(s.root, st.x, st.y)

	if s.last_y then
		local vy = (st.y - s.last_y) / max(dt, 1e-4)
		s.vy = s.vy + (vy - s.vy) * min(1, dt * 14)
	end
	s.last_y = st.y
	local ground = st.grounded

	-- atterraggio e stacco: schiaccia e allunga
	if ground and not s.ground and s.vy < -40 then
		s.v[SQ] = s.v[SQ] - min(7, -s.vy / 40)
	elseif not ground and s.ground and s.vy > 20 then
		s.v[SQ] = s.v[SQ] + 4
	end
	s.ground = ground

	local sq = 1 + 0.025 * sin(s.t * 2.4)
	if not ground then sq = 1 + min(0.2, abs(s.vy) / 900) end
	-- si piega in avanti correndo
	local avanti = st.moving * face
	local lean = -0.22 * max(-1, min(1, avanti / 70))
	if s.morte then
		s.morte = s.morte + dt
		sq, lean = 0.4, 0.9
		s.alpha.w = max(0, 1 - s.morte / 0.6)
		gui.set_color(s.root, s.alpha)
		if s.morte > 0.6 then
			s.morto = true
			gui.set_enabled(s.root, false)
			return
		end
	end
	molle(s, dt, sq, lean)

	local q = max(0.4, s.x[SQ])
	scale(s.forma, 1 + (1 - q) * 0.8, q)
	rot(s.corpo, s.x[LEAN])
	pos(s.corpo, -s.x[SHOVE] * s.w, 0)
	-- la spalla sale e scende con la forma
	pos(s.spalla, -s.w * 0.05, s.h * 0.45 * q)
	scale(s.ombra, 1 + (1 - q) * 0.5, 0.22)

	-- lampo bianco del colpo
	if s.flash > 0 then
		s.flash = max(0, s.flash - dt * 6)
		local f = min(1, s.flash * 1.5)
		C.x = GRIGIO.x + (1 - GRIGIO.x) * f
		C.y = GRIGIO.y + (1 - GRIGIO.y) * f
		C.z = GRIGIO.z + (1 - GRIGIO.z) * f
		for i = 1, #s.pelle do gui.set_color(s.pelle[i], C) end
	end

	-- l'arma gira attorno alla spalla: verso la mira, altrimenti a riposo
	local a = ARMI[s.arma_scelta].riposo
	if st.aim then a = face > 0 and st.aim or pi - st.aim end
	-- la spalla è dentro il corpo, che è inclinato: togliamo l'inclinazione
	a = a - s.x[LEAN]
	rot(s.spalla, a)
	local g = s.armi[s.arma_scelta]
	-- il rinculo non porta mai la mano dietro la spalla
	pos(g, -min(s.x[KICK] * s.w * 0.6, s.h * 0.12), 0)

	-- occhio: sbatte ogni tanto e guarda dove punta l'arma
	s.blink = s.blink - dt
	local oy = 1
	if s.blink < 0.12 then oy = 0.15 end
	if s.blink < 0 then s.blink = 2 + math.random() * 3 end
	scale(s.occhio, 1, oy)
	local look = s.w * 0.14
	pos(s.pupilla, cos(a) * look, sin(a) * look)
end

function M.set_weapon(s, name)
	if s.arma_scelta == name or not s.armi[name] then return end
	if s.arma_scelta then gui.set_enabled(s.armi[s.arma_scelta], false) end
	s.arma_scelta = name
	gui.set_enabled(s.armi[name], true)
end

-- Colpo subito: lampo bianco, spinta indietro e schiacciata
function M.hit(s)
	s.flash = 1
	s.v[SHOVE] = s.v[SHOVE] + 9
	s.v[SQ] = s.v[SQ] - 4
	s.v[LEAN] = s.v[LEAN] + 5
end

-- Colpo sparato: rinculo dell'arma e del corpo
function M.fire(s, kind)
	local k = kind == "shards" and 0.5 or 1
	s.v[KICK] = s.v[KICK] + 14 * k
	s.v[LEAN] = s.v[LEAN] + 3 * k
	s.v[SQ] = s.v[SQ] - 1.5 * k
end

-- Arrivo col teletrasporto: compare schiacciato e si allunga con un rimbalzo
function M.teleport(s)
	s.x[SQ], s.v[SQ] = 0.5, 4
end

function M.die(s)
	if not s.morte then s.morte = 0 end
end

return M
