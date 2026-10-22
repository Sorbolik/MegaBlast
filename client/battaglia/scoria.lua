-- La Scoria in battaglia e nella home: i pezzi del personaggio (assets/personaggio)
-- montati con nodi GUI su uno scheletro di giunture e animati nel codice.
--
-- Lo scheletro (battaglia/personaggio_rig.lua, generato da
-- strumenti/grafica/personaggio_esporta.py) dice dove ruota ogni pezzo e dove
-- si attacca al genitore. Le animazioni non sono clip registrate: a ogni frame
-- si calcola una posa obiettivo (respiro, passo, salto, mira, colpi...) e le
-- giunture la inseguono con delle molle, così i movimenti hanno peso, ritardo e
-- rimbalzi. Braccia e gambe si muovono con l'IK a due ossa: si decide dove va
-- la mano (o il piede) e spalla e gomito (anca e ginocchio) si piegano di
-- conseguenza. Così i piedi restano a terra anche quando il corpo si abbassa.
-- Occhio e Nucleo si tingono col colore della squadra.
--
-- Uso:
--   local scoria = require "battaglia.scoria"
--   local s = scoria.new(colore)          -- crea i nodi
--   scoria.new(colore, "scoria_hd")       -- con un altro atlante (la home usa i pezzi grandi)
--   scoria.new(colore, nil, k)            -- k volte più grande di SCALE
--   scoria.update(s, dt, stato)           -- a ogni frame, nessuna allocazione
--   scoria.hit(s)                         -- colpo subito
--   scoria.fire(s, tipo)                  -- "missile", "throw" (uovo, globo), "shards"
--   scoria.teleport(s)                    -- appena arrivato col Passo d'Ombra
--   scoria.die(s)                         -- cade e sparisce

local RIG = require "battaglia.personaggio_rig"

local M = {}

-- Altezza nel mondo: il rig è alto 128 unità (dai piedi alle corna), nel mondo così
M.SCALE = 0.39

local ATLAS = "battaglia"
local P = RIG.pezzi

local sin, cos, atan2, sqrt, abs, min, max = math.sin, math.cos, math.atan2, math.sqrt, math.abs, math.min, math.max
local acos, pi, exp = math.acos, math.pi, math.exp
local DEG, RAD = 180 / pi, pi / 180

local function clamp(x, a, b)
	if x < a then return a elseif x > b then return b end
	return x
end

-- angolo in [-pi, pi)
local function wrap(a)
	return (a + pi) % (2 * pi) - pi
end

-- da coordinate di un'immagine (y in giù) a coordinate della giuntura (origine nel perno, y in su)
local function locale(perno, x, y)
	return x - perno[1], perno[2] - y
end

-- Geometria di un arto a due ossa (j1 -> j2 -> j3), letta dallo scheletro.
-- Angoli in radianti, y in su, nel sistema del genitore di j1: a1 e a2 sono
-- le direzioni delle due ossa con le giunture a zero; ox, oy dove si attacca
-- l'arto; th, d, h la posa di riposo (estremità a distanza d in direzione th,
-- estremità girata di h); piega: da che parte va il gomito (o il ginocchio).
local function arto_geo(j1, j2, j3, man)
	local p1, p2, p3 = P[j1], P[j2], P[j3]
	local A = {}
	A.ox, A.oy = locale(P[p1.genitore].perno, p1.aggancio[1], p1.aggancio[2])
	local ex, ey = locale(p1.perno, p2.aggancio[1], p2.aggancio[2])
	local wx, wy = locale(p2.perno, p3.aggancio[1], p3.aggancio[2])
	A.l1, A.a1 = sqrt(ex * ex + ey * ey), atan2(ey, ex)
	A.l2, A.a2 = sqrt(wx * wx + wy * wy), atan2(wy, wx)
	A.lungo = A.l1 + A.l2
	-- direzione dall'estremità al centro della mano (per posa), o 0 per il piede
	A.mano, A.centro = {}, {}
	if p3.mani then
		for posa, m in pairs(p3.mani) do
			local cx, cy = locale(m.perno, m.size[1] / 2, m.size[2] / 2)
			A.mano[posa] = atan2(cy, cx)
			A.centro[posa] = { cx, cy }
		end
	end
	local r = RIG.riposo
	local s1, s2, s3 = r[j1] * RAD, r[j2] * RAD, r[j3] * RAD
	local q1, q2 = A.a1 + s1, A.a2 + s1 + s2
	local x = A.l1 * cos(q1) + A.l2 * cos(q2)
	local y = A.l1 * sin(q1) + A.l2 * sin(q2)
	A.th, A.d = atan2(y, x), sqrt(x * x + y * y)
	A.x, A.y = A.ox + x, A.oy + y
	A.h = q2 - A.a2 + s3 + (man and A.mano[man] or 0)
	local cross = x * (A.l1 * sin(q1)) - y * (A.l1 * cos(q1))
	A.piega = cross < 0 and 1 or -1
	A.j1, A.j2, A.j3 = j1, j2, j3
	return A
end
local DAVANTI = arto_geo("spalla_davanti", "gomito_davanti", "polso_davanti", "aperta")
local DIETRO = arto_geo("spalla_dietro", "gomito_dietro", "polso_dietro", "aperta")
local GAMBA_D = arto_geo("anca_davanti", "ginocchio_davanti", "caviglia_davanti")
local GAMBA_T = arto_geo("anca_dietro", "ginocchio_dietro", "caviglia_dietro")
GAMBA_D.suola, GAMBA_T.suola = P.caviglia_davanti.suola, P.caviglia_dietro.suola

-- IK a due ossa: angoli assoluti delle due ossa perché l'estremità arrivi a
-- distanza d in direzione th
local function ik(A, th, d)
	local l1, l2 = A.l1, A.l2
	d = clamp(d, abs(l1 - l2) + 0.5, l1 + l2 - 0.05)
	local c = clamp((l1 * l1 + d * d - l2 * l2) / (2 * l1 * d), -1, 1)
	local p1 = th - acos(c) * A.piega
	local p2 = atan2(d * sin(th) - l1 * sin(p1), d * cos(th) - l1 * cos(p1))
	return p1, p2
end

-- Armi in mano, nel pugno davanti. presa: il punto dell'immagine (px dell'arma
-- in battaglia) che sta al centro della mano; scala: unità del rig per pixel;
-- rot: di quanto è girato il disegno rispetto alla direzione dell'arma;
-- sopra: si disegna sopra la mano (bracciale, guanto) invece che dietro le dita;
-- mira: quanto si stende il braccio mirando (frazione del braccio teso);
-- riposo: dove punta l'arma senza mirare (nil: dove punta la mano);
-- braccio: posa del braccio senza mirare, { direzione (rad), distanza (frazione) }
-- (nil: lungo il fianco), per tenere l'arma davanti a sé invece che sull'anca.
local ARMI = {
	missile = { img = "lanciarune", w = 64, h = 53, presa = { 20, 27 }, scala = 0.36, sopra = true, mano = "pugno",
		mira = 0.9, bocca = { 58, 24 }, riposo = -10 * RAD, braccio = { -0.75, 0.66 } },
	-- con la spada in mano e senza mirare la lama sta bassa davanti, punta verso terra
	-- la punta arriva a circa 90 unità dalla spalla: nel mondo è la portata del fendente (40)
	sword = { img = "lama_di_nucleo", w = 192, h = 43, presa = { 29.4, 22.5 }, scala = 0.31, mano = "pugno", mira = 0.92,
		luce = 0.6, riposo = -40 * RAD },
	teleport = { img = "passo_ombra", w = 64, h = 57, presa = { 20, 30 }, scala = 0.24, mano = "artigli", mira = 0.88,
		braccio = { -0.9, 0.7 } },
	punch = { img = "pugno_del_titano", w = 64, h = 60, presa = { 26, 28 }, scala = 0.3, rot = 40, sopra = true,
		mano = "pugno", mira = 0.82, battaglia = true },
	grenade = { img = "uovo_di_fiamma", w = 56, h = 64, presa = { 22, 34 }, scala = 0.22, mano = "artigli", mira = 0.88,
		braccio = { -0.9, 0.7 }, battaglia = true },
	shards = { img = "sciame_di_schegge", w = 60, h = 64, presa = { 12, 34 }, scala = 0.3, rot = -38, sopra = true,
		mano = "artigli", mira = 0.92, battaglia = true },
}
-- di quanto i piedi affondano nel terreno: gli artigli toccano la superficie disegnata
local AFFONDO = 2

-- Passo: lunghezza (unità del rig) e altezza a cui si alza il piede
local PASSO, ALZATA = 30, 7
-- velocità vista che vale "corsa piena" (unità del rig al secondo)
local CORSA = 150

-- Molle, una per canale. w: rigidità (rad/s), z: smorzamento (1 = senza rimbalzo)
local BY, BX, BR, COLLO, TESTA, FTH, FD, FH, TTH, TD, TH, OCCHIO, SQ = 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13
local N_CANALI = 13
local MOLLA_W = { 11, 14, 9, 9, 11, 12, 15, 14, 9, 12, 12, 28, 20 }
local MOLLA_Z = { 0.45, 0.6, 0.55, 0.5, 0.42, 0.62, 0.5, 0.55, 0.55, 0.5, 0.5, 0.6, 0.3 }
-- canali che sono angoli: inseguono la strada più corta
local ANGOLO = { [FTH] = true, [FH] = true, [TTH] = true, [TH] = true }

local V = vmath.vector3(0, 0, 0)
local function pos(node, x, y)
	V.x, V.y, V.z = x, y, 0
	gui.set_position(node, V)
end
local function rot(node, deg)
	V.x, V.y, V.z = 0, 0, deg
	gui.set_euler(node, V)
end
local function scale(node, x, y)
	V.x, V.y, V.z = x, y, 1
	gui.set_scale(node, V)
end

local function nodo(parent, x, y, w, h)
	local n = gui.new_box_node(vmath.vector3(x, y, 0), vmath.vector3(w, h, 0))
	if gui.set_inherit_alpha then gui.set_inherit_alpha(n, true) end
	if parent then gui.set_parent(n, parent) end
	return n
end

local function image(anim, parent, x, y, w, h)
	local n = nodo(parent, x, y, w, h)
	gui.set_texture(n, ATLAS)
	gui.play_flipbook(n, anim)
	return n
end

local function empty(parent, x, y)
	local n = nodo(parent, x, y, 0, 0)
	gui.set_visible(n, false)
	return n
end

local function glow(anim, parent, x, y, w, h, color)
	local n = image(anim, parent, x, y, w, h)
	gui.set_blend_mode(n, gui.BLEND_ADD)
	gui.set_color(n, color)
	return n
end

-- immagine di un pezzo dentro la sua giuntura: il perno cade sull'origine
local function pezzo(anim, parent, perno, size)
	local w, h = size[1], size[2]
	return image(anim, parent, w / 2 - perno[1], -(h / 2 - perno[2]), w, h)
end

-- giuntura nel punto di aggancio del genitore, con la sua immagine
local function giuntura(s, name, parent, senza_immagine)
	local p = P[name]
	local x, y = locale(P[p.genitore].perno, p.aggancio[1], p.aggancio[2])
	local j = empty(parent, x, y)
	if not senza_immagine then pezzo(p.img, j, p.perno, p.size) end
	s[name] = j
	return j
end

-- un braccio: spalla, gomito, polso con le tre pose della mano
local function braccio(s, lato, parent, armi)
	local spalla = giuntura(s, "spalla_" .. lato, parent)
	local gomito = giuntura(s, "gomito_" .. lato, spalla)
	local polso = giuntura(s, "polso_" .. lato, gomito, true)
	-- le armi stanno dietro le dita (l'impugnatura nel pugno) o sopra (bracciali)
	if armi then s.armi_dietro = empty(polso, 0, 0) end
	local mani = {}
	for posa, m in pairs(P["polso_" .. lato].mani) do
		mani[posa] = pezzo(m.img, polso, m.perno, m.size)
		gui.set_enabled(mani[posa], posa == "aperta")
	end
	if armi then s.armi_sopra = empty(polso, 0, 0) end
	s["mani_" .. lato] = mani
	s["posa_" .. lato] = "aperta"
end

local function gamba(s, lato, parent)
	local anca = giuntura(s, "anca_" .. lato, parent)
	local ginocchio = giuntura(s, "ginocchio_" .. lato, anca)
	giuntura(s, "caviglia_" .. lato, ginocchio)
end

local function arma(s, name, color, soft)
	local a = ARMI[name]
	local g = empty(a.sopra and s.armi_sopra or s.armi_dietro, 0, 0)
	scale(g, a.scala, a.scala)
	local inner = empty(g, 0, 0)
	rot(inner, a.rot or 0)
	local x, y = a.w / 2 - a.presa[1], -(a.h / 2 - a.presa[2])
	image(a.img, inner, x, y, a.w, a.h)
	local c = color
	if a.luce then c = vmath.vector4(color.x, color.y, color.z, a.luce) end
	glow(a.img .. "_luce", inner, x, y, a.w, a.h, c)
	if a.bocca then
		s.bocca = glow("bagliore", inner, a.bocca[1] - a.presa[1], -(a.bocca[2] - a.presa[2]), 34, 34, soft)
	end
	s.armi[name] = g
end

function M.new(color, atlas, k)
	ATLAS = atlas or "battaglia"
	local s = { color = color, scale = M.SCALE * (k or 1), armi = {}, x = {}, v = {}, o = {} }
	s.root = nodo(nil, 0, 0, 0, 0)
	gui.set_visible(s.root, false)
	gui.set_adjust_mode(s.root, gui.ADJUST_STRETCH)
	scale(s.root, s.scale, s.scale)
	s.alpha = vmath.vector4(1, 1, 1, 1)
	local soft = vmath.vector4(color.x, color.y, color.z, 0.35)

	-- alone del colore della squadra dietro al corpo: stacca il personaggio
	-- dallo sfondo scuro e dice di che squadra è
	s.c_alone = vmath.vector4(color.x, color.y, color.z, 0.22)
	s.alone = glow("bagliore", s.root, 0, 64, 120, 150, s.c_alone)

	-- Ordine di disegno: braccio e gamba dietro, bacino, gamba davanti, busto,
	-- testa, braccio davanti. Il bacino è la radice dello scheletro; il busto
	-- (con braccia e testa) è figlio del bacino, ma il braccio dietro va
	-- disegnato prima di tutto: sta in un busto "ombra" che segue quello vero.
	s.bacino = empty(s.root, 0, RIG.bacino_y)
	local bp = P.busto
	local bx, by = locale(P.bacino.perno, bp.aggancio[1], bp.aggancio[2])
	s.busto_dietro = empty(s.bacino, bx, by)
	braccio(s, "dietro", s.busto_dietro)
	local sp = P.spallaccio_dietro
	s.spallaccio_dietro = empty(s.busto_dietro, locale(bp.perno, sp.aggancio[1], sp.aggancio[2]))
	pezzo(sp.img, s.spallaccio_dietro, sp.perno, sp.size)
	gamba(s, "dietro", s.bacino)
	pezzo(P.bacino.img, s.bacino, P.bacino.perno, P.bacino.size)
	gamba(s, "davanti", s.bacino)

	s.busto = giuntura(s, "busto", s.bacino, true)
	s.busto_img = pezzo(bp.img, s.busto, bp.perno, bp.size)

	-- Nucleo: la gemma tinta col colore della squadra, con l'alone che pulsa
	local nu = P.nucleo
	local nx, ny = locale(bp.perno, nu.aggancio[1], nu.aggancio[2])
	s.alone_nucleo = glow("bagliore", s.busto, nx, ny, 18, 18, soft)
	s.nucleo = image(nu.img, s.busto, nx, ny, nu.size[1] * 0.8, nu.size[2] * 0.8)
	gui.set_color(s.nucleo, color)
	s.c_nucleo = vmath.vector4(color.x, color.y, color.z, 0.5)
	s.luce_nucleo = glow(nu.img, s.busto, nx, ny, nu.size[1] * 0.8, nu.size[2] * 0.8, s.c_nucleo)

	local collo = giuntura(s, "collo", s.busto)
	local testa = giuntura(s, "testa", collo)
	-- occhio: il buco della maschera pieno di luce
	local o = RIG.occhio
	local ox, oy = locale(P.testa.perno, o.pos[1], o.pos[2])
	s.alone_occhio = glow("bagliore", testa, ox, oy, 14, 14, soft)
	s.c_occhio = vmath.vector4(color.x, color.y, color.z, 1)
	s.occhio = glow("pg_occhio", testa, ox, oy, o.size[1], o.size[2], s.c_occhio)

	braccio(s, "davanti", s.busto, true)
	giuntura(s, "spallaccio_davanti", s.busto)

	-- le armi: un gruppo per arma, si vede solo quella equipaggiata
	-- (quelle delle casse solo in battaglia: l'atlante della home non le ha)
	for name, a in pairs(ARMI) do
		if not a.battaglia or ATLAS == "battaglia" then arma(s, name, color, soft) end
	end
	s.arma_scelta = nil
	M.set_weapon(s, "missile")

	M.reset(s)
	return s
end

-- Tutto a riposo (all'inizio di una partita)
function M.reset(s)
	local x, v = s.x, s.v
	for i = 1, N_CANALI do x[i], v[i] = 0, 0 end
	x[OCCHIO], x[SQ] = 1, 1
	x[FTH], x[FD], x[FH] = DAVANTI.th, DAVANTI.d, DAVANTI.h
	x[TTH], x[TD], x[TH] = DIETRO.th, DIETRO.d, DIETRO.h
	s.t = math.random() * 10
	s.passo = 0
	s.corsa = 0
	s.hit = 0
	s.vy = 0
	s.aimk = 0
	s.aim = 0
	s.last_y = nil
	s.ground = true
	s.aria = 0
	s.terra_d, s.terra_t = 0, 0
	s.blink = 2 + math.random() * 3
	s.colpo, s.colpo_t, s.colpo_a = nil, 0, 0
	s.morte, s.morto = nil, nil
	s.alpha.w = 1
	gui.set_color(s.root, s.alpha)
end

function M.set_enabled(s, on)
	if on and s.morte then M.reset(s) end
	gui.set_enabled(s.root, on)
end

local function mano(s, lato, posa)
	local ora = s["posa_" .. lato]
	if ora ~= posa then
		local m = s["mani_" .. lato]
		gui.set_enabled(m[ora], false)
		gui.set_enabled(m[posa], true)
		s["posa_" .. lato] = posa
	end
end

-- Muove le molle verso gli obiettivi in s.o (passi da 1/120 s al massimo)
local function molle(s, dt)
	local x, v, o = s.x, s.v, s.o
	local n = math.ceil(dt * 120)
	local h = dt / n
	for _ = 1, n do
		for i = 1, N_CANALI do
			local e = o[i] - x[i]
			if ANGOLO[i] then e = wrap(e) end
			local w, z = MOLLA_W[i], MOLLA_Z[i]
			v[i] = v[i] + (w * w * e - 2 * z * w * v[i]) * h
			x[i] = x[i] + v[i] * h
		end
	end
end

-- Un braccio in posa: polso a distanza d dalla spalla in direzione th, mano
-- girata verso ha (radianti, nel sistema del busto). Restituisce l'angolo del
-- sistema del polso e la rotazione della spalla.
local function posa_braccio(s, A, th, d, ha, posa)
	local p1, p2 = ik(A, th, d)
	local r1, r2 = p1 - A.a1, p2 - A.a2
	rot(s[A.j1], r1 * DEG)
	rot(s[A.j2], (r2 - r1) * DEG)
	local polso = ha - A.mano[posa]
	rot(s[A.j3], (polso - r2) * DEG)
	return polso, r1
end

-- Una gamba in posa: caviglia nel punto (x, y) del sistema del bacino, piede
-- girato di fa (radianti; 0 = piatto come nel disegno)
local function posa_gamba(s, G, x, y, fa)
	local dx, dy = x - G.ox, y - G.oy
	local p1, p2 = ik(G, atan2(dy, dx), sqrt(dx * dx + dy * dy))
	local r1, r2 = p1 - G.a1, p2 - G.a2
	rot(s[G.j1], r1 * DEG)
	rot(s[G.j2], (r2 - r1) * DEG)
	rot(s[G.j3], (fa - r2) * DEG)
end

-- Altezza del terreno sotto il punto x del rig (unità del rig, rispetto ai
-- piedi del robot): si cerca da TERRA_SU sopra a TERRA_GIU sotto, a passi di 1
-- pixel del mondo. 0 se lì sotto non c'è niente (il piede resta dov'è).
local TERRA_SU, TERRA_GIU = 8, 14
local function terra(s, st, x)
	local wx = st.x + x * s.scale * st.facing
	local t = st.terreno
	for d = TERRA_SU, -TERRA_GIU, -1 do
		if t:solid(wx, st.y + d - 0.5) then
			return d / s.scale
		end
	end
	return 0
end

-- st: x, y (piedi, mondo), facing (-1/1), grounded, moving (velocità x vista),
--     aim (angolo in radianti o nil), expression (stringa o nil),
--     terreno (facoltativo: oggetto con solid(x, y), per appoggiare i piedi)
function M.update(s, dt, st)
	if s.morto then return end
	dt = min(dt, 1 / 20)
	s.t = s.t + dt
	local t = s.t
	local o = s.o
	local face = st.facing
	local arma_s = s.arma_scelta
	local A = ARMI[arma_s]

	-- girarsi: l'immagine si specchia subito
	scale(s.root, s.scale * face, s.scale)
	pos(s.root, st.x, st.y)

	-- velocità vista, in "corse" (1 = correre)
	if s.last_y then
		local vy = (st.y - s.last_y) / max(dt, 1e-4)
		s.vy = s.vy + (vy - s.vy) * min(1, dt * 14)
	end
	s.last_y = st.y
	local vx = clamp(st.moving * face / s.scale / CORSA, -1.5, 1.5)
	local vy = clamp(s.vy / s.scale / 450, -1.5, 1.5)
	local ground = st.grounded

	-- atterraggio: le gambe ammortizzano, il corpo affonda e rimbalza
	if ground and not s.ground and vy < -0.15 then
		local f = min(1.2, -vy)
		s.v[BY] = s.v[BY] - 110 * f
		s.v[TESTA] = s.v[TESTA] - 160 * f
		s.v[BR] = s.v[BR] - 60 * f
		s.v[SQ] = s.v[SQ] - 1.5 * f
	elseif not ground and s.ground and vy > 0.1 then
		-- stacco: si allunga
		s.v[SQ] = s.v[SQ] + 1.2
		s.v[BY] = s.v[BY] + 40
	end
	s.ground = ground
	s.aria = ground and 0 or min(1, s.aria + dt * 6)

	-- Posa di base: in piedi, respira --------------------------------------------
	local by = sin(t * 2.2) * 0.6 - 2.5
	local bx, lean = 0, sin(t * 1.1) * 1
	local collo, testa = sin(t * 0.7) * 2, sin(t * 0.7 + 0.4) * 3 + sin(t * 1.9) * 1.2
	local fth, fd, fh = DAVANTI.th + sin(t * 2.2 - 0.7) * 0.04, DAVANTI.d, DAVANTI.h + sin(t * 2.2 - 1.2) * 0.1
	local tth, td, th = DIETRO.th + sin(t * 2.2 - 1.1) * 0.04, DIETRO.d, DIETRO.h + sin(t * 2.2 - 1.6) * 0.1
	if A and A.braccio then
		fth, fd = A.braccio[1] + sin(t * 2.2 - 0.7) * 0.04, DAVANTI.lungo * A.braccio[2]
		fh = fth + 0.2
	end
	local sq = 1
	local occhio, occhio_a = 1, 1
	local posa_f, posa_t = "aperta", "aperta"
	-- piedi: (x, alzata) rispetto alla posa di riposo, angolo del piede
	local pdx, pdy, pda = 0, 0, 0
	local ptx, pty, pta = 0, 0, 0

	local speed = abs(vx)
	local k = min(1, speed / 0.15)
	s.corsa = s.corsa + ((ground and k or 0) - s.corsa) * min(1, dt * 10)
	local corsa = s.corsa
	if ground and speed > 0.02 then
		s.passo = s.passo + dt * pi * vx * CORSA / PASSO
	elseif corsa < 0.05 then
		-- fermo: il passo si chiude con i piedi al loro posto
		s.passo = 0
	end
	if corsa > 0.001 then
		-- passo: ogni piede va avanti alzandosi e torna indietro a terra
		-- (in controfase); il corpo scende quando le gambe sono aperte, si
		-- piega in avanti, le braccia oscillano al contrario delle gambe
		local w = s.passo
		local c, sn = cos(w), sin(w)
		local a = min(1, speed) * corsa
		pdx, pdy = c * PASSO * 0.5 * a, max(0, -sn) * ALZATA * a
		ptx, pty = -c * PASSO * 0.5 * a, max(0, sn) * ALZATA * a
		pda, pta = -max(0, -sn) * 0.35 * a, -max(0, sn) * 0.35 * a
		by = by - (2.5 + 1.8 * c * c) * a
		lean = lean - 10 * vx * corsa
		collo = collo + 5 * vx * corsa
		testa = testa + 3 * vx * corsa + sin(w * 2) * 1.5 * a
		fth = fth - c * 0.35 * a - 0.15 * vx * corsa
		tth = tth + c * 0.35 * a - 0.15 * vx * corsa
		fh = fh - c * 0.4 * a
		th = th + c * 0.4 * a
	end
	if not ground then
		-- in aria: salendo ginocchia su e braccia aperte, scendendo le gambe si
		-- allungano verso terra e le braccia si alzano
		local q = s.aria
		local kv = clamp(vy, -1, 1)
		local su = max(0, kv)
		pdx, pdy, pda = 5 * q, (6 + 10 * su) * q, -0.35 * q
		ptx, pty, pta = -4 * q, (3 + 6 * su) * q, -0.5 * q
		by = by + 2 * q
		lean = lean - 8 * vx + kv * 4
		fth = fth + (-0.3 - (1 - kv) * 0.45 - fth) * q
		tth = tth + (-2.6 + (1 - kv) * 0.4 - tth) * q
		fd = fd + (DAVANTI.lungo * 0.85 - fd) * q
		td = td + (DIETRO.lungo * 0.85 - td) * q
		fh, th = fh + (fth - 0.3 - fh) * q, th + (tth + 0.3 - th) * q
		testa = testa - kv * 8 * q
		if q > 0.5 then posa_f, posa_t = "artigli", "artigli" end
	end

	-- Espressioni ----------------------------------------------------------------
	local e = st.expression or "neutro"
	if e == "paura" then
		-- si accuccia e si ripara il muso col braccio, trema
		occhio = 1.35
		by = by - 5
		lean = lean + 6 + sin(t * 47) * 1
		tth, td, th = 1.0, DIETRO.lungo * 0.6, 1.9
		posa_t = "artigli"
		testa = testa - 10
	elseif e == "poca_vita" then
		-- curvo e stanco, il Nucleo e l'occhio tremolano
		by = by - 4 + sin(t * 1.3) * 0.6
		lean = lean - 10
		collo, testa = collo - 6, testa - 10
		fd, td = DAVANTI.lungo * 0.97, DIETRO.lungo * 0.97
		occhio = 0.8
		occhio_a = 0.55 + 0.45 * abs(sin(t * 7.3) * sin(t * 3.1))
	elseif e == "vittoria" then
		-- pugni al cielo, saltella sulle ginocchia
		local b = abs(sin(t * 5))
		by = by - 3 + b * 3
		lean = lean + 7
		testa = testa + 12
		fth, fd, fh = 1.25 + b * 0.15, DAVANTI.lungo * 0.92, 1.45 + b * 0.2
		tth, td, th = 1.9 - b * 0.15, DIETRO.lungo * 0.92, 1.7 - b * 0.2
		posa_f, posa_t = "pugno", "pugno"
		occhio = 1.15 + b * 0.15
	end

	-- Colpo subito: trema, l'occhio sfarfalla
	local hit = s.hit
	if hit > 0 then
		s.hit = max(0, hit - dt)
		lean = lean + sin(hit * 50) * hit * 8
		bx = bx + sin(hit * 61) * hit * 2
		occhio = 1.3
		occhio_a = 0.4 + 0.6 * abs(sin(hit * 70))
		posa_t = "artigli"
	end

	-- palpebra: ogni tanto l'occhio si chiude un attimo
	s.blink = s.blink - dt
	if s.blink < 0 then
		occhio = 0.08
		if s.blink < -0.11 then s.blink = 2.5 + math.random() * 3.5 end
	end

	-- Mira --------------------------------------------------------------------
	-- dopo lo sparo il braccio resta puntato ancora un attimo
	local aim = st.aim
	local colpo = s.colpo
	if colpo then
		s.colpo_t = s.colpo_t + dt
		if s.colpo_t > 0.45 then
			s.colpo, colpo = nil, nil
		elseif not aim then
			aim = s.colpo_a
		end
	end
	if st.aim then s.colpo_a = st.aim end
	s.aimk = s.aimk + ((aim and 1 or 0) - s.aimk) * min(1, dt * 16)
	local aimk = s.aimk
	-- l'angolo arriva nel mondo: lo portiamo nel sistema girato a destra
	if aim then s.aim = wrap(face < 0 and pi - aim or aim) end
	local la = s.aim
	if arma_s == "sword" then
		-- con la spada il corpo carica all'indietro e si butta in avanti col fendente
		lean = lean - 12 * cos(la) * aimk
		by = by - (1.5 + 1.5 * sin(la)) * aimk
		pdx, ptx = pdx + 3 * aimk, ptx - 3 * aimk
	else
		lean = lean + 4 * sin(la) * aimk
	end
	-- la testa guarda dove si mira, l'occhio si stringe
	testa = testa + clamp(la * DEG * 0.35, -22, 28) * aimk
	if aimk > 0.5 and e == "neutro" then occhio = 0.6 end

	-- colpi: rinculo del Lanciarune, slancio del lancio, raffica di schegge
	local rinculo, lancio = 0, 0
	if colpo then
		local u = s.colpo_t
		if colpo == "missile" then
			rinculo = 0.3 * exp(-u * 12) * min(1, u * 40)
			lean = lean + 8 * exp(-u * 8)
			bx = bx - 3 * exp(-u * 8)
		elseif colpo == "throw" then
			lancio = -0.9 * sin(min(1, u / 0.3) * pi * 0.5) * exp(-u * 3)
			lean = lean - 8 * exp(-u * 6)
		elseif colpo == "shards" then
			rinculo = 0.1 * abs(sin(u * 45))
			bx = bx - 1 * abs(sin(u * 45))
		end
	end

	-- Morte: l'occhio si spegne, crolla in ginocchio e svanisce
	if s.morte then
		local u = s.morte + dt
		s.morte = u
		local q = min(1, u / 0.45)
		q = q * q * (3 - 2 * q)
		by = -RIG.bacino_y * 0.42 * q
		lean = -35 * q
		collo, testa = -15 * q, -30 * q
		pdx, pdy, pda = 8 * q, 0, 0
		ptx, pty, pta = -10 * q, 0, 0
		fth, fd, fh = -1.35, DAVANTI.lungo, -1.5
		tth, td, th = -1.8, DIETRO.lungo, -1.6
		occhio_a = max(0, 1 - u * 3)
		aimk = 0
		s.alpha.w = clamp(1 - (u - 0.6) / 0.6, 0, 1)
		gui.set_color(s.root, s.alpha)
		if u > 1.2 then
			s.morto = true
			gui.set_enabled(s.root, false)
			return
		end
	end

	-- Obiettivi delle molle --------------------------------------------------------
	o[BY], o[BX], o[BR], o[SQ] = by, bx, lean, sq
	o[COLLO], o[TESTA] = collo, testa
	o[FTH], o[FD], o[FH] = fth, fd, fh
	o[TTH], o[TD], o[TH] = tth, td, th
	o[OCCHIO] = occhio
	-- mirando la mano dietro si fa avanti, tesa
	if aimk > 0.01 then
		o[TTH] = tth + wrap(-0.9 - tth) * aimk * 0.7
		o[TD] = td * (1 - 0.1 * aimk)
		if aimk > 0.5 and posa_t == "aperta" then posa_t = "artigli" end
	end
	molle(s, dt)
	local x = s.x

	-- Piedi sul terreno vero: la scatola del robot è dritta, quindi su una
	-- salita o su un bordo poggia su un angolo e il centro resta sospeso.
	-- Ogni piede cerca il terreno sotto di sé; il bacino scende quanto serve
	-- perché il piede più basso ci arrivi. Solo disegno, la fisica non cambia.
	local td, tt = 0, 0
	if st.terreno and ground and not s.morte then
		td = terra(s, st, GAMBA_D.x + pdx)
		tt = terra(s, st, GAMBA_T.x + ptx)
	end
	local kt = min(1, dt * 18)
	s.terra_d = s.terra_d + (td - s.terra_d) * kt
	s.terra_t = s.terra_t + (tt - s.terra_t) * kt
	local giu = min(0, s.terra_d, s.terra_t)

	-- corpo: il bacino sale e scende, il busto si piega in vita
	local bacino_y = RIG.bacino_y + x[BY] + giu
	pos(s.bacino, x[BX], bacino_y)
	scale(s.bacino, 2 - x[SQ], x[SQ])
	rot(s.busto, x[BR])
	rot(s.busto_dietro, x[BR])
	local r = 1 + sin(t * 2.2 + 0.5) * 0.012
	scale(s.busto_img, r, r)
	rot(s.collo, x[COLLO])
	rot(s.testa, x[TESTA] - x[COLLO] * 0.5)

	-- gambe: i piedi a terra (o dove dice il passo), nel sistema del bacino
	local sq_y = 1 / x[SQ]
	local gy = -(bacino_y + AFFONDO) * sq_y
	posa_gamba(s, GAMBA_D, GAMBA_D.x + pdx - x[BX], gy + (GAMBA_D.suola + pdy + s.terra_d) * sq_y, pda)
	posa_gamba(s, GAMBA_T, GAMBA_T.x + ptx - x[BX], gy + (GAMBA_T.suola + pty + s.terra_t) * sq_y, pta)

	-- braccio davanti: la posa delle molle, verso la mira quanto aimk.
	-- Mirando segue l'angolo esatto senza ritardo: è quello del colpo.
	local fth2, fd2, fh2 = x[FTH], x[FD], x[FH]
	if aimk > 0.001 then
		local mira = la - x[BR] * RAD + lancio
		local d = DAVANTI.lungo * ((A and A.mira or 0.86) - rinculo)
		fth2 = fth2 + wrap(mira - fth2) * aimk
		fd2 = fd2 + (d - fd2) * aimk
		fh2 = fh2 + wrap(mira - fh2) * aimk
	end
	local presa = A and A.mano or "aperta"
	if posa_f ~= "aperta" and presa == "aperta" then presa = posa_f end
	mano(s, "davanti", presa)
	local polso, spalla_f = posa_braccio(s, DAVANTI, fth2, fd2, fh2, presa)
	-- l'arma va dove punta la mano, o dove dice il suo riposo
	local wa = fh2
	if A and A.riposo then wa = A.riposo + wrap(fh2 - A.riposo) * aimk end
	local c = DAVANTI.centro[presa]
	pos(s.armi_dietro, c[1], c[2])
	pos(s.armi_sopra, c[1], c[2])
	local ra = (wa - polso) * DEG
	rot(s.armi_dietro, ra)
	rot(s.armi_sopra, ra)

	-- braccio dietro
	mano(s, "dietro", posa_t)
	local _, spalla_t = posa_braccio(s, DIETRO, x[TTH], x[TD], x[TH], posa_t)
	-- gli spallacci seguono un po' le spalle
	rot(s.spallaccio_davanti, clamp(spalla_f * DEG * 0.2, -20, 20))
	rot(s.spallaccio_dietro, clamp(spalla_t * DEG * 0.2, -20, 20))

	-- l'alone segue il corpo e respira col Nucleo
	pos(s.alone, x[BX], 30 + bacino_y * 0.5)

	-- occhio e Nucleo
	local oc = x[OCCHIO]
	scale(s.occhio, 0.85 + 0.15 * oc, oc)
	s.c_occhio.w = occhio_a
	gui.set_color(s.occhio, s.c_occhio)
	local pulse = 0.82 + 0.18 * sin(t * 3.1)
	if e == "poca_vita" then pulse = pulse * occhio_a end
	s.c_alone.w = 0.16 + 0.08 * pulse
	gui.set_color(s.alone, s.c_alone)
	scale(s.alone_nucleo, pulse, pulse)
	s.c_nucleo.w = 0.25 + 0.35 * pulse
	gui.set_color(s.luce_nucleo, s.c_nucleo)
	if s.bocca then gui.set_enabled(s.bocca, st.aim ~= nil and arma_s == "missile") end
end

-- Arma in mano: "missile" (Lanciarune), "sword" (Lama di Nucleo), "teleport" (Passo d'Ombra),
-- "punch" (Pugno del Titano), "grenade" (Uovo di Fiamma), "shards" (Sciame di Schegge)
function M.set_weapon(s, name)
	if s.arma_scelta == name or not s.armi[name] then return end
	s.arma_scelta = name
	for k, g in pairs(s.armi) do gui.set_enabled(g, k == name) end
end

-- Colpo subito: il corpo va indietro, la testa scatta, l'occhio sfarfalla
function M.hit(s)
	s.hit = 0.45
	s.v[BR] = s.v[BR] + 220
	s.v[TESTA] = s.v[TESTA] + 380
	s.v[BX] = s.v[BX] - 30
	s.v[BY] = s.v[BY] - 50
end

-- Colpo sparato: "missile" (rinculo), "throw" (uovo e globo: slancio del braccio),
-- "shards" (la raffica fa tremare il braccio)
function M.fire(s, kind)
	s.colpo, s.colpo_t = kind, 0
end

-- Arrivo col Passo d'Ombra: compare schiacciato e si allunga con un rimbalzo
function M.teleport(s)
	s.x[SQ], s.v[SQ] = 0.55, 3
	s.v[OCCHIO] = 20
end

-- Morte: crolla, l'occhio si spegne e svanisce (poi il nodo si spegne da solo)
function M.die(s)
	if not s.morte then s.morte = 0 end
end

return M
