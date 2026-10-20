-- La Scoria in battaglia: pezzi ritagliati (assets/scoria) montati con nodi GUI
-- e animati nel codice. Niente fogli di animazione: ogni pezzo ruota attorno al
-- suo perno (scoria_rig.json) e occhio, Nucleo e crepe si tingono col colore
-- della squadra disegnandoli in additivo.
--
-- Uso:
--   local scoria = require "battaglia.scoria"
--   local s = scoria.new(colore)          -- crea i nodi
--   scoria.new(colore, "scoria_hd")       -- con un altro atlante (la home usa i master)
--   scoria.update(s, dt, stato)           -- a ogni frame, nessuna allocazione

local M = {}

-- Altezza nel mondo: la Scoria è disegnata a 128 px, nel mondo è alta così
M.SCALE = 0.26
-- Piedi nel sistema di scoria_corpo.png (origine in alto a sinistra, y in giù)
local FX, FY = 37, 117

-- atlante dei pezzi: stessi nomi delle animazioni, risoluzione a scelta
local ATLAS = "battaglia"

-- Dati di scoria_rig.json (export 128 px)
local RIG = {
	corna_davanti = { perno = { 30.5, 18.3 }, aggancio = { 40.3, 13.2 }, size = { 35, 20 } },
	corna_dietro = { perno = { 14.6, 20.1 }, aggancio = { 25.9, 8.1 }, size = { 20, 22 } },
	braccio_davanti = { perno = { 7.3, 4.9 }, aggancio = { 14.0, 44.5 }, size = { 44, 54 } },
	braccio_dietro = { perno = { 6.1, 5.5 }, aggancio = { 51.2, 40.3 }, size = { 40, 63 } },
	gamba_davanti = { perno = { 13.4, 7.3 }, aggancio = { 26.2, 84.2 }, size = { 26, 41 } },
	gamba_dietro = { perno = { 9.8, 6.7 }, aggancio = { 48.2, 84.2 }, size = { 27, 40 } },
}
local CORPO_SIZE = { 65, 93 }
local OCCHIO_POS, OCCHIO_SIZE = { 41.2, 13.3 }, { 20, 19 }
-- Nucleo sul petto (per l'alone), nelle coordinate del corpo
local NUCLEO_POS = { 34, 56 }
-- Mano del braccio davanti (coordinate dell'immagine del braccio) e direzione
-- del braccio a riposo, dal perno alla mano, in gradi (y in su)
local MANO = { 30, 31 }
local BRACCIO_RIPOSO = math.deg(math.atan2(-(MANO[2] - 4.9), MANO[1] - 7.3))
local ARMA_SCALE = 0.5
-- di quanto avanza la spalla del braccio davanti quando si mira (px del rig)
local SPALLA_MIRA = 26
-- Bocca del Lanciarune, nel sistema della sua immagine (64 x 53), per il bagliore
local ARMA_BOCCA = { 58, 24 }

-- da coordinate del rig (y in giù, origine del corpo) a coordinate locali (y in su, origine ai piedi)
local function lx(x) return x - FX end
local function ly(y) return FY - y end

local V = vmath.vector3(0, 0, 0)
local function pos(node, x, y)
	V.x, V.y, V.z = x, y, 0
	gui.set_position(node, V)
end
local function rot(node, deg)
	V.x, V.y, V.z = 0, 0, deg
	gui.set_euler(node, V)
end

local function image(anim, parent, x, y, w, h)
	local n = gui.new_box_node(vmath.vector3(x, y, 0), vmath.vector3(w, h, 0))
	gui.set_texture(n, ATLAS)
	gui.play_flipbook(n, anim)
	gui.set_parent(n, parent)
	return n
end

local function empty(parent, x, y)
	local n = gui.new_box_node(vmath.vector3(x, y, 0), vmath.vector3(0, 0, 0))
	gui.set_visible(n, false)
	gui.set_parent(n, parent)
	return n
end

-- Un pezzo che ruota attorno al perno: un nodo vuoto nel punto di aggancio
-- e l'immagine spostata in modo che il perno cada sull'origine del nodo
local function joint(s, name)
	local r = RIG[name]
	local j = empty(s.root, lx(r.aggancio[1]), ly(r.aggancio[2]))
	local w, h = r.size[1], r.size[2]
	local img = image("scoria_" .. name, j, w / 2 - r.perno[1], -(h / 2 - r.perno[2]), w, h)
	s.base[name] = { lx(r.aggancio[1]), ly(r.aggancio[2]) }
	s[name] = j
	return j, img
end

local function glow(anim, parent, x, y, w, h, color)
	local n = image(anim, parent, x, y, w, h)
	gui.set_blend_mode(n, gui.BLEND_ADD)
	gui.set_color(n, color)
	return n
end

function M.new(color, atlas)
	ATLAS = atlas or "battaglia"
	local s = { base = {}, color = color }
	s.root = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(0, 0, 0))
	gui.set_visible(s.root, false)
	gui.set_adjust_mode(s.root, gui.ADJUST_STRETCH)
	gui.set_scale(s.root, vmath.vector3(M.SCALE, M.SCALE, 1))

	-- ordine di disegno di scoria_rig.json
	joint(s, "braccio_dietro")
	joint(s, "gamba_dietro")
	joint(s, "corna_dietro")

	local cw, ch = CORPO_SIZE[1], CORPO_SIZE[2]
	s.busto = empty(s.root, 0, 0)
	s.corpo = image("scoria_corpo", s.busto, lx(cw / 2), ly(ch / 2), cw, ch)
	local soft = vmath.vector4(color.x, color.y, color.z, 0.35)
	s.alone_nucleo = glow("bagliore", s.busto, lx(NUCLEO_POS[1]), ly(NUCLEO_POS[2]), 46, 46, soft)
	s.nucleo = glow("scoria_nucleo_luce", s.busto, lx(cw / 2), ly(ch / 2), cw, ch, color)
	local ox, oy = OCCHIO_POS[1] + OCCHIO_SIZE[1] / 2, OCCHIO_POS[2] + OCCHIO_SIZE[2] / 2
	s.alone_occhio = glow("bagliore", s.busto, lx(ox), ly(oy), 40, 40, soft)
	s.occhio = glow("scoria_occhio_neutro", s.busto, lx(ox), ly(oy), OCCHIO_SIZE[1], OCCHIO_SIZE[2], color)
	s.espressione = "neutro"

	joint(s, "gamba_davanti")
	joint(s, "corna_davanti")
	local _, braccio = joint(s, "braccio_davanti")

	-- Lanciarune in mano, allineato al braccio
	local r = RIG.braccio_davanti
	local mx = MANO[1] - r.size[1] / 2
	local my = -(MANO[2] - r.size[2] / 2)
	s.arma = empty(braccio, mx, my)
	V.x, V.y, V.z = ARMA_SCALE, ARMA_SCALE, 1
	gui.set_scale(s.arma, V)
	rot(s.arma, BRACCIO_RIPOSO)
	-- il bracciale avvolge il polso, la bocca guarda lungo il braccio
	image("lanciarune", s.arma, 4, 0, 64, 53)
	s.arma_luce = glow("lanciarune_luce", s.arma, 4, 0, 64, 53, color)
	s.bocca = glow("bagliore", s.arma, 4 + ARMA_BOCCA[1] - 32, -(ARMA_BOCCA[2] - 26.5), 30, 30, soft)

	s.t = math.random() * 10
	s.walk = 0
	s.face = 1
	s.hit = 0
	s.vy = 0
	s.aimk = 0
	s.last_y = nil
	return s
end

function M.set_enabled(s, on)
	gui.set_enabled(s.root, on)
end

local function set_expression(s, e)
	if s.espressione ~= e then
		s.espressione = e
		gui.play_flipbook(s.occhio, "scoria_occhio_" .. e)
	end
end

-- Mette un pezzo nel punto di aggancio spostato di (dx, dy)
local function place(s, name, dx, dy, deg)
	local b = s.base[name]
	pos(s[name], b[1] + dx, b[2] + dy)
	rot(s[name], deg)
end

-- st: x, y (piedi, mondo), facing (-1/1), grounded, moving (velocità x vista),
--     aim (angolo in radianti o nil), expression (stringa o nil per automatica),
--     hp, dt
function M.update(s, dt, st)
	s.t = s.t + dt
	local t = s.t

	-- girarsi: la scala x passa da un lato all'altro in fretta, sembra una piroetta
	local want = st.facing
	s.face = s.face + (want - s.face) * math.min(1, dt * 18)
	if math.abs(s.face - want) < 0.01 then s.face = want end
	V.x, V.y, V.z = M.SCALE * s.face, M.SCALE, 1
	gui.set_scale(s.root, V)
	pos(s.root, st.x, st.y)

	-- velocità verticale vista, per corna e gambe in aria
	if s.last_y then
		local vy = (st.y - s.last_y) / math.max(dt, 1e-4)
		s.vy = s.vy + (vy - s.vy) * math.min(1, dt * 12)
	end
	s.last_y = st.y

	local speed = math.abs(st.moving)
	local ground = st.grounded
	local gamba_d, gamba_t, bob, lean = 0, 0, 0, 0
	if ground and speed > 4 then
		-- passo: le gambe oscillano in controfase, il corpo sobbalza
		s.walk = s.walk + dt * (6 + speed * 0.08)
		local sw = math.sin(s.walk)
		gamba_d, gamba_t = sw * 26, -sw * 26
		bob = math.abs(math.cos(s.walk)) * 3
		lean = -5
	elseif not ground then
		-- in aria: gambe raccolte, piegate in avanti quando sale
		local k = math.max(-1, math.min(1, s.vy / 200))
		gamba_d, gamba_t = 18 + k * 12, -10 + k * 10
		lean = -k * 4
	else
		-- fermo: respira
		s.walk = 0
		bob = math.sin(t * 2.2) * 1.2
	end

	local hit = s.hit
	if hit > 0 then
		s.hit = math.max(0, hit - dt)
		lean = lean + math.sin(hit * 40) * hit * 18
	end

	pos(s.busto, 0, bob)
	rot(s.busto, lean)
	place(s, "gamba_davanti", 0, 0, gamba_d)
	place(s, "gamba_dietro", 0, 0, gamba_t)
	-- le corna seguono il busto e ondeggiano con la velocità verticale
	local corna = math.max(-14, math.min(14, -s.vy * 0.04)) + math.sin(t * 2.2 + 0.6) * 1.5
	place(s, "corna_davanti", 0, bob, corna)
	place(s, "corna_dietro", 0, bob, corna * 0.8)

	local swing = math.sin(t * 2.2 + 1.2) * 3
	if ground and speed > 4 then swing = -math.sin(s.walk) * 18 end
	place(s, "braccio_dietro", 0, bob, swing)
	local front = -swing
	-- mirando, la spalla del braccio davanti scivola sul petto: così l'arma
	-- esce davanti al corpo invece di passare sopra la faccia
	local ak = st.aim and 1 or 0
	s.aimk = s.aimk + (ak - s.aimk) * math.min(1, dt * 14)
	if st.aim then
		-- il braccio con il Lanciarune punta dove si mira (in spazio locale, già specchiato)
		local a = math.deg(st.aim)
		if s.face < 0 then a = 180 - a end
		front = a - BRACCIO_RIPOSO
		if front > 180 then front = front - 360 elseif front < -180 then front = front + 360 end
		front = front - lean
	end
	place(s, "braccio_davanti", SPALLA_MIRA * s.aimk, bob + 2 * s.aimk, front)

	-- il Nucleo pulsa piano, l'alone dell'arma brilla quando si mira
	local pulse = 0.82 + 0.18 * math.sin(t * 3.1)
	V.x, V.y, V.z = pulse, pulse, 1
	gui.set_scale(s.alone_nucleo, V)
	gui.set_enabled(s.bocca, st.aim ~= nil)
	set_expression(s, st.expression or "neutro")
end

-- Colpo subito: scossa del corpo e occhio "colpito" per un attimo
function M.hit(s)
	s.hit = 0.45
end

return M
