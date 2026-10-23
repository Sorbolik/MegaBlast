-- La Scoria (fase 4 della roadmap): la sagoma "Corona del Titano con le gambe",
-- grande esattamente come il corpo della simulazione (ROBOT_H x 2 ROBOT_HALF_W),
-- così quello che si vede è quello che colpisce e viene colpito.
--
-- Lo usano la battaglia (game.gui_script) e la home (menu/home.lua):
--   local s = scoria.new(colore)
--   scoria.update(s, dt, stato)    -- a ogni frame, nessuna allocazione
--   scoria.set_weapon(s, nome) / hit(s) / fire(s, tipo) / teleport(s) / die(s)
--
-- Pochi pezzi: testa con le corna, mantello, due gambe e due mani staccate
-- sull'arma (immagini di strumenti/grafica/scoria.py); occhio e Nucleo del colore
-- della squadra. Ogni immagine ha una copia allargata e chiara disegnata dietro a
-- tutto, così la sagoma nera si stacca dallo sfondo scuro.
--
-- Le animazioni sono molle: schiaccia e allunga (atterraggio, stacco,
-- teletrasporto), inclinazione nella corsa, spinta e lampo bianco quando si viene
-- colpiti, rinculo dell'arma, testa che ondeggia e guarda dove si mira, gambe che
-- fanno i passi in base alla strada fatta, occhio che sbatte e Nucleo che respira.

local game = require "sim.game"
local PEZZI = require "battaglia.scoria_pezzi"

local M = {}

-- altezza della Scoria in cima alle corna, per mettere sopra vita e freccia
M.ALTEZZA = game.ROBOT_H * (200 - (PEZZI.testa.y - PEZZI.testa.h / 2)) / 200

local sin, cos, min, max, abs, pi = math.sin, math.cos, math.min, math.max, math.abs, math.pi
local DEG = 180 / pi

local INCHIOSTRO = vmath.vector4(0.078, 0.071, 0.094, 1)
local LUCE = vmath.vector4(1, 0.886, 0.769, 0.6)
local OMBRA = vmath.vector4(0, 0, 0, 0.35)
local BIANCO = vmath.vector4(1, 1, 1, 1)
local FERRO = vmath.vector4(0.3, 0.29, 0.34, 1)
local LAMA = vmath.vector4(0.86, 0.88, 0.95, 1)

-- molle: posizione, velocità, rigidità, smorzamento
local SQ, LEAN, SHOVE, KICK, TESTA = 1, 2, 3, 4, 5
local W_MOLLA = { 16, 10, 12, 18, 11 }
local Z_MOLLA = { 0.3, 0.45, 0.5, 0.45, 0.28 }

-- punti del disegno (unità della pagina delle sagome, y verso il basso)
local COLLO = { 78, 100 }
local ANCHE = { { 55.5, 172 }, { 95.5, 172 } }
local OCCHIO = { 96, 64, 28 }
local NUCLEO = { 62, 150, 14 }
local SPALLA = { 80, 118 }
-- la mano sull'impugnatura, davanti alla spalla lungo l'arma
local PRESA = 20
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

-- un pezzo disegnato: un giunto nel punto (x, y) del disegno, attorno a cui gira,
-- e sotto l'immagine al suo posto
local function pezzo(s, parent, nome, immagine, x, y, color)
	local p = PEZZI[nome]
	local g = vuoto(parent, gx(s, x), gy(s, y))
	local n = box(g, (p.x - x) * s.k, (y - p.y) * s.k, p.w * s.k, p.h * s.k, color)
	gui.set_texture(n, "battaglia")
	gui.play_flipbook(n, immagine)
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
}

-- una mano staccata: un cerchio nero col bordo chiaro
local function mano(s, g, x, y)
	local d = 22 * s.k
	cerchio(g, x, y, d + 2 * 6 * s.k, LUCE)
	cerchio(g, x, y, d, INCHIOSTRO)
end

local function arma(s, name, color)
	local H, k = s.h, s.k
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
	local s = { color = color, h = H, w = Wd, k = H / 200, armi = {}, pelle = {},
		x = {}, v = {}, goal = {}, testa = {}, gambe = { {}, {} }, gamba_a = { 0, 0 } }
	s.root = vuoto(nil, 0, 0)
	gui.set_adjust_mode(s.root, gui.ADJUST_STRETCH)
	s.alpha = vmath.vector4(1, 1, 1, 1)
	s.occhio_col = vmath.vector4(color.x, color.y, color.z, 1)
	s.nucleo_col = vmath.vector4(color.x, color.y, color.z, 1)

	s.ombra = cerchio(s.root, 0, 0, Wd * 1.3, OMBRA)
	scale(s.ombra, 1, 0.22)
	-- corpo: inclinazione e spinta; forma: schiaccia e allunga. L'arma sta sul
	-- corpo e non sulla forma, così schiacciandosi non si storce la mira
	s.corpo = vuoto(s.root, 0, 0)
	s.forma = vuoto(s.corpo, 0, 0)

	-- prima tutti i bordi chiari, poi le sagome nere sopra: così i pezzi della
	-- stessa Scoria si uniscono senza righe in mezzo
	for strato = 1, 2 do
		local suff = strato == 1 and "_bordo" or ""
		local col = strato == 1 and LUCE or INCHIOSTRO
		for i = 1, 2 do
			local g, n = pezzo(s, s.forma, "gamba", "gamba" .. suff, ANCHE[1][1], ANCHE[1][2], col)
			pos(g, gx(s, ANCHE[i][1]), gy(s, ANCHE[i][2]))
			s.gambe[i][strato] = g
			if strato == 2 then s.pelle[#s.pelle + 1] = n end
		end
		local _, n = pezzo(s, s.forma, "mantello", "mantello" .. suff, 75, 140, col)
		if strato == 2 then s.pelle[#s.pelle + 1] = n end
		s.testa[strato], n = pezzo(s, s.forma, "testa", "testa" .. suff, COLLO[1], COLLO[2], col)
		if strato == 2 then s.pelle[#s.pelle + 1] = n end
	end

	-- l'occhio, sulla testa: il colore della squadra con il centro più chiaro che
	-- guarda dove si mira
	local k = s.k
	s.occhio = vuoto(s.testa[2], (OCCHIO[1] - COLLO[1]) * k, (COLLO[2] - OCCHIO[2]) * k)
	cerchio(s.occhio, 0, 0, OCCHIO[3] * k, s.occhio_col)
	s.pupilla = cerchio(s.occhio, 0, 0, OCCHIO[3] * k * 0.45,
		vmath.vector4((1 + color.x) / 2, (1 + color.y) / 2, (1 + color.z) / 2, 1))
	s.nucleo = cerchio(s.forma, gx(s, NUCLEO[1]), gy(s, NUCLEO[2]), NUCLEO[3] * k, s.nucleo_col)

	s.spalla = vuoto(s.corpo, gx(s, SPALLA[1]), gy(s, SPALLA[2]))
	for name in pairs(ARMI) do arma(s, name, color) end
	M.set_weapon(s, "missile")

	M.reset(s)
	return s
end

function M.reset(s)
	for i = 1, #W_MOLLA do s.x[i], s.v[i], s.goal[i] = 0, 0, 0 end
	s.x[SQ] = 1
	s.t = math.random() * 10
	s.vy, s.last_x, s.last_y, s.ground = 0, nil, nil, true
	s.passo, s.cammina = 0, 0
	s.gamba_a[1], s.gamba_a[2] = 0, 0
	s.flash, s.blink = 0, 2 + math.random() * 3
	s.morte, s.morto = nil, nil
	s.alpha.w = 1
	gui.set_color(s.root, s.alpha)
	for i = 1, #s.pelle do gui.set_color(s.pelle[i], INCHIOSTRO) end
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
		for strato = 1, 2 do
			pos(g[strato], gx(s, ANCHE[i][1]), gy(s, ANCHE[i][2]) + su)
			rot(g[strato], s.gamba_a[i])
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
	if s.morte then
		s.morte = s.morte + dt
		sq, lean, testa = 0.4, 0.9, 0.6
		s.alpha.w = max(0, 1 - s.morte / 0.6)
		gui.set_color(s.root, s.alpha)
		if s.morte > 0.6 then
			s.morto = true
			gui.set_enabled(s.root, false)
			return
		end
	end
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
	local hy = gy(s, COLLO[2]) + abs(sin(s.passo)) * 4 * s.k * s.cammina
	for strato = 1, 2 do
		pos(s.testa[strato], gx(s, COLLO[1]), hy)
		rot(s.testa[strato], s.x[TESTA])
	end

	-- lampo bianco del colpo
	if s.flash > 0 then
		s.flash = max(0, s.flash - dt * 6)
		local f = min(1, s.flash * 1.5)
		C.x = INCHIOSTRO.x + (1 - INCHIOSTRO.x) * f
		C.y = INCHIOSTRO.y + (1 - INCHIOSTRO.y) * f
		C.z = INCHIOSTRO.z + (1 - INCHIOSTRO.z) * f
		C.w = 1
		for i = 1, #s.pelle do gui.set_color(s.pelle[i], C) end
	end

	-- la spalla è dentro il corpo, che è inclinato: togliamo l'inclinazione
	a = a - s.x[LEAN]
	rot(s.spalla, a)
	local g = s.armi[s.arma_scelta]
	-- il rinculo non porta mai la mano dietro la spalla
	pos(g, -min(s.x[KICK] * s.w * 0.6, PRESA * s.k * 0.8), 0)

	-- occhio: sbatte ogni tanto e guarda dove punta l'arma (tolta la testa)
	s.blink = s.blink - dt
	local oy = 1
	if s.blink < 0.12 then oy = 0.15 end
	if s.blink < 0 then s.blink = 2 + math.random() * 3 end
	scale(s.occhio, 1, oy)
	local look = OCCHIO[3] * s.k * 0.25
	local al = a + s.x[LEAN] - s.x[TESTA]
	pos(s.pupilla, cos(al) * look, sin(al) * look)
	-- il Nucleo respira
	s.nucleo_col.w = 0.7 + 0.3 * sin(s.t * 3.1)
	gui.set_color(s.nucleo, s.nucleo_col)
end

function M.set_weapon(s, name)
	if s.arma_scelta == name or not s.armi[name] then return end
	if s.arma_scelta then gui.set_enabled(s.armi[s.arma_scelta], false) end
	s.arma_scelta = name
	gui.set_enabled(s.armi[name], true)
end

-- Colpo subito: lampo bianco, spinta indietro, schiacciata e testa all'indietro
function M.hit(s)
	s.flash = 1
	s.v[SHOVE] = s.v[SHOVE] + 9
	s.v[SQ] = s.v[SQ] - 4
	s.v[LEAN] = s.v[LEAN] + 5
	s.v[TESTA] = s.v[TESTA] + 8
end

-- Colpo sparato: rinculo dell'arma e del corpo
function M.fire(s, kind)
	local k = kind == "shards" and 0.5 or 1
	s.v[KICK] = s.v[KICK] + 14 * k
	s.v[LEAN] = s.v[LEAN] + 3 * k
	s.v[SQ] = s.v[SQ] - 1.5 * k
	s.v[TESTA] = s.v[TESTA] + 3 * k
end

-- Arrivo col teletrasporto: compare schiacciato e si allunga con un rimbalzo
function M.teleport(s)
	s.x[SQ], s.v[SQ] = 0.5, 4
end

function M.die(s)
	if not s.morte then s.morte = 0 end
end

return M
