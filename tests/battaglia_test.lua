-- Test della Scoria (battaglia/scoria.lua) e della targa con nome e vita
-- (battaglia/targa.lua) con un finto gui, e della camera (battaglia/camera.lua). Dalla radice del repository:
--   luajit tests/battaglia_test.lua
package.path = "client/?.lua;" .. package.path

-- finti vmath e gui: ogni nodo ricorda posizione, rotazione, scala e genitore
local function vec(x, y, z, w) return { x = x or 0, y = y or 0, z = z or 0, w = w } end
vmath = { vector3 = vec, vector4 = vec }
hash = function(s) return "#" .. s end
local nodi = {}
ordine = 0
local function nuovo(p, s)
	ordine = ordine + 1
	local n = { pos = vec(p.x, p.y), euler = vec(), scale = vec(1, 1, 1), size = s, enabled = true, ordine = ordine }
	nodi[#nodi + 1] = n
	return n
end
local function copia(v) return vec(v.x, v.y, v.z, v.w) end
gui = {
	ADJUST_STRETCH = 2,
	new_box_node = nuovo, new_pie_node = nuovo,
	set_parent = function(n, p) n.parent = p end,
	set_position = function(n, v) n.pos = copia(v) end,
	set_euler = function(n, v) n.euler = copia(v) end,
	set_scale = function(n, v) n.scale = copia(v) end,
	set_enabled = function(n, on) n.enabled = on end,
	set_visible = function(n, on) n.invisibile = not on end, set_color = function() end, set_adjust_mode = function() end,
	set_inherit_alpha = function() end, set_perimeter_vertices = function() end, set_fill_angle = function() end, set_inner_radius = function() end,
	set_texture = function() end, play_flipbook = function(n, img) n.img = img end, set_material = function() end,
	new_text_node = function(p, text) local n = nuovo(p); n.text = text; return n end,
	set_text = function(n, text) n.text = text end,
	set_size = function(n, v) n.size = copia(v) end,
	get_size = function(n) return n.size end,
	set_font = function() end, set_outline = function() end, set_pivot = function() end, set_line_break = function() end,
	set_slice9 = function() end, PIVOT_W = 3,
	set_outer_bounds = function() end, PIEBOUNDS_ELLIPSE = 1, ADJUST_FIT = 0,
	-- l'ordine fra i fratelli: move_above(n, nil) lo porta sopra a tutti
	move_above = function(n) ordine = ordine + 1; n.ordine = ordine end,
}

local game = require "sim.game"
local scoria = require "battaglia.scoria"
local camera = require "battaglia.camera"
local targa = require "battaglia.targa"

local failures = 0
local function check(cond, msg)
	if cond then
		print("ok   " .. msg)
	else
		print("FAIL " .. msg)
		failures = failures + 1
	end
end

-- posizione nel sistema della radice di un punto locale del nodo n
local function mondo(n, x, y)
	while n.parent do
		local a = math.rad(n.euler.z)
		x, y = x * n.scale.x, y * n.scale.y
		x, y = x * math.cos(a) - y * math.sin(a), x * math.sin(a) + y * math.cos(a)
		x, y = x + n.pos.x, y + n.pos.y
		n = n.parent
	end
	-- la radice: scala (verso) e posizione
	x, y = x * n.scale.x, y * n.scale.y
	return x + n.pos.x, y + n.pos.y
end

local function finito(v) return v == v and v > -1e6 and v < 1e6 end
local function tutto_finito()
	for _, n in ipairs(nodi) do
		if not (finito(n.pos.x) and finito(n.pos.y) and finito(n.euler.z) and finito(n.scale.x)) then return false end
	end
	return true
end

local function angolo(a) return (a + math.pi) % (2 * math.pi) - math.pi end

-- Scoria -------------------------------------------------------------------

local s = scoria.new(vec(1, 0.2, 0.3, 1))
local st = { x = 100, y = 50, facing = 1, grounded = true, moving = 0, turno = true }
for _ = 1, 60 do scoria.update(s, 1 / 60, st) end
check(tutto_finito(), "a riposo: valori finiti")

-- presa, perno e spalla di ogni arma (battaglia/impugnature.lua)
local PRESE = require "battaglia.impugnature"
local D0 = require "battaglia.diavoletto"
-- chi impugna l'arma (lo dice la clip) la tiene: la manina sta sulla presa, il
-- braccio punta verso la presa (ci arriva solo se la presa è lontana dalla
-- spalla quanto è lungo il braccio, e le clip possono spostare la spalla)
local function tiene(v, name)
	local g = PRESE[name]
	local gx, gy = mondo(v.armi[name], g.presa[1], g.presa[2])
	local chi = v.posa.clip and v.posa.clip.impugna or "braccio_a"
	if chi:find("^manina") then
		local mx, my = mondo(v[chi], 0, 0)
		return math.abs(gx - mx) < 0.5 and math.abs(gy - my) < 0.5, chi
	elseif chi:find("^braccio") then
		local pz = D0.pezzi[chi == "braccio_a" and "braccio" or "braccio_dietro"]
		local jx, jy = mondo(v[chi], 0, 0)
		local hx, hy = mondo(v[chi], pz.x * v.k, (pz.y - pz.h / 2 + D0.pezzi.pugno.h * 0.4) * v.k)
		return math.abs(angolo(math.atan2(hy - jy, hx - jx) - math.atan2(gy - jy, gx - jx))) < 0.02, chi
	end
	return true, chi
end
-- la direzione dell'arma nel mondo
local function verso_arma(v, name)
	local x0, y0 = mondo(v.armi[name], 0, 0)
	local x1, y1 = mondo(v.armi[name], 1, 0)
	return math.atan2(y1 - y0, x1 - x0)
end

-- mirando il braccio davanti punta dove si mira e l'arma lo prolunga: l'arma
-- va nella direzione della mira, la presa nella mano, girati a destra o a sinistra
for _, name in ipairs({ "missile", "sword", "mallet" }) do
	scoria.set_weapon(s, name)
	for _, a in ipairs({ 0.4, -0.8, 2.3, math.pi - 0.2 }) do
		st.aim = a
		st.facing = math.cos(a) < 0 and -1 or 1
		for _ = 1, 30 do scoria.update(s, 1 / 60, st) end
		local d = angolo(verso_arma(s, name) - a)
		check(math.abs(d) < 0.02, string.format("%s mirando a %.1f: l'arma punta dove si mira (scarto %.3f)", name, a, d))
		local ok, chi = tiene(s, name)
		check(ok, string.format("%s mirando a %.1f: %s tiene la presa", name, a, chi))
	end
end

-- il rinculo sposta l'arma indietro lungo il suo asse, senza staccarla dalla mira
scoria.set_weapon(s, "missile")
st.aim, st.facing = 0.6, 1
for _ = 1, 30 do scoria.update(s, 1 / 60, st) end
local mx0, my0 = mondo(s.armi.missile, 0, 0)
scoria.fire(s, "missile")
scoria.update(s, 1 / 60, st)
local mx, my = mondo(s.armi.missile, 0, 0)
check((mx - mx0) ^ 2 + (my - my0) ^ 2 > 0.25, "rinculo: l'arma torna indietro")
check(math.abs(angolo(math.atan2(my0 - my, mx0 - mx) - 0.6)) < 0.02, "rinculo: l'arma si sposta lungo il suo asse")

st.aim = nil
-- in ordine fisso: pairs cambia ordine da un'esecuzione all'altra e, se
-- l'ultima fosse la Lama, il controllo della morte qui sotto non la cambierebbe
local nomi = {}
for name in pairs(require("battaglia.armi").armi) do nomi[#nomi + 1] = name end
table.sort(nomi)
for _, name in ipairs(nomi) do
	check(s.armi[name] ~= nil, name .. ": c'è il disegno in mano")
	scoria.set_weapon(s, name)
	for _ = 1, 10 do scoria.update(s, 1 / 60, st) end
end
check(tutto_finito(), "tutte le armi a riposo: valori finiti")

-- salto e atterraggio: i fotogrammi del salto senza esplodere
st.grounded = false
for i = 1, 30 do st.y = 50 + i * 3; scoria.update(s, 1 / 60, st) end
for i = 1, 30 do st.y = 140 - i * 3; scoria.update(s, 1 / 60, st) end
st.grounded = true
for _ = 1, 30 do scoria.update(s, 1 / 120, st) end
check(tutto_finito(), "salto e atterraggio (anche a 120 Hz): valori finiti")

scoria.hit(s)
for _ = 1, 30 do scoria.update(s, 1 / 60, st) end
check(tutto_finito(), "colpo: valori finiti")

-- l'attesa: fermo, e prima o poi una scenetta a caso che finisce
st.turno = false
for _ = 1, 60 * 30 do scoria.update(s, 1 / 60, st) end
check(s.n_scenette > 0, "attesa: in 30 secondi almeno una scenetta")
check(tutto_finito(), "attesa e scenette: valori finiti")
st.turno = true

scoria.hit(s, 30)
scoria.hit(s, -30)
for _ = 1, 10 do scoria.update(s, 1 / 60, st) end
check(tutto_finito(), "colpi da destra e da sinistra: valori finiti")

scoria.die(s)
scoria.set_weapon(s, "sword")
check(not s.armi.sword.enabled, "morte: l'arma sparisce, anche cambiandola")
for _ = 1, 30 do scoria.update(s, 1 / 60, st) end
check(tutto_finito() and s.root.enabled, "morte: il corpo cade e c'è ancora")
for _ = 1, 200 do scoria.update(s, 1 / 60, st) end
check(not s.root.enabled, "morte: poi il corpo sparisce")
scoria.set_enabled(s, true)
check(s.root.enabled and not s.morte, "nuova partita: il corpo torna")
check(math.abs(game.DISEGNO_H - s.h) < 1e-9, "il corpo è alto quanto il disegno (DISEGNO_H)")

-- Pose (battaglia/pose.lua) e clip (battaglia/animazioni.lua) ------------------

local pose = require "battaglia.pose"
local A = require "battaglia.animazioni"
local function vicino(a, b) return math.abs(a - b) < 1e-6 end
local clip = { durata = 1, ciclo = true, tracce = { testa = { 0, 0, 0, 0.5, 1, 1, 0.75, 2, 2 } },
	viso = { 0.2, "testa_felice", 0.6, "testa_ko" } }
local tr = clip.tracce.testa
check(vicino(pose.valore(tr, 0, 1, true), 0) and vicino(pose.valore(tr, 0.5, 1, true), 1),
	"pose: sulle chiavi il valore della chiave")
check(vicino(pose.valore(tr, 0.625, 1, true), 1.5), "pose: curva dritta a metà")
check(vicino(pose.valore(tr, 0.9, 1, true), 2), "pose: curva a scatto tiene il valore")
local p = pose.nuova()
pose.aggiungi(p, clip, 3.5, 0.5)
check(vicino(p.testa, 0.5) and vicino(p.schiaccia, 1) and vicino(p.braccio_a, 0),
	"pose: in ciclo il tempo gira, il peso scala, i canali assenti restano neutri")
check(p.viso == "testa_felice", "pose: la faccia a scatti")
pose.azzera(p)
pose.aggiungi(p, clip, 0.1, 1)
check(p.viso == "testa_ko", "pose: prima della prima faccia, in ciclo, l'ultima")
local fine = { durata = 1, ciclo = false, tracce = { corpo = { 0, 0, 0, 1, 2, 0 } } }
check(vicino(pose.valore(fine.tracce.corpo, 0.5, 1, false), 1) and vicino(pose.valore(fine.tracce.corpo, 1, 1, false), 2),
	"pose: una clip che non gira parte e arriva piano e si ferma alla fine")
local nomi = {}
for _, c in ipairs(pose.CANALI) do nomi[c] = true end
local buone = true
for nome, c in pairs(A) do
	if not (c.durata > 0) then buone = false; print("     " .. nome .. ": durata") end
	for canale, tr in pairs(c.tracce) do
		if not nomi[canale] or #tr % 3 ~= 0 or #tr == 0 then buone = false; print("     " .. nome .. "." .. canale) end
		for k = 1, #tr - 3, 3 do
			if tr[k + 3] < tr[k] or tr[k] < 0 or tr[k + 3] > c.durata then buone = false; print("     " .. nome .. "." .. canale .. ": tempi") end
		end
	end
end
check(buone, "animazioni: canali noti, chiavi in ordine dentro la durata")
for _, nome in ipairs({ "fermo", "corsa", "aria", "sale", "scende", "paracadute", "colpito", "vittoria",
	"sconfitta", "naso", "sbadiglio", "guarda_coda", "fermo_arma", "corsa_arma", "aria_arma", "sale_arma",
	"scende_arma", "mira", "fiammella" }) do
	check(A[nome] ~= nil, "animazioni: c'è la clip " .. nome)
end

-- gli spostamenti avanti e indietro e su e giù dei pezzi
do
	local A2 = require "battaglia.animazioni"
	local vecchia = A2.fermo
	A2.fermo = { durata = 1, ciclo = true, tracce = { testa_x = { 0, 10, 0 }, braccio_d_y = { 0, -8, 0 }, coda_x = { 0, 5, 0 } } }
	local v = scoria.new(vec(1, 0.2, 0.3, 1))
	local st2 = { x = 100, y = 50, facing = 1, grounded = true, moving = 0 }
	for _ = 1, 5 do scoria.update(v, 1 / 60, st2) end
	local D = require "battaglia.diavoletto"
	local k = v.k
	check(math.abs(v.collo.pos.x - (D.punti.collo[1] + 10) * k) < 1e-6
		and math.abs(v.braccio_d.pos.y - (D.punti.spalle[2] - 8) * k) < 1e-6
		and math.abs(v.coda[1][2].pos.x - (D.punti.coda[1] + 5) * k) < 1e-6,
		"pose: testa, braccio e coda si spostano coi canali x e y")
	A2.fermo = vecchia
end

-- i perni spostati dall'editor (battaglia/perni.lua): il giunto si sposta, i
-- pezzi al contrario, così da fermi restano dove sono
do
	local D = require "battaglia.diavoletto"
	package.loaded["battaglia.perni"] = { braccio = { 3, -2 }, testa = { 1, 4 } }
	package.loaded["battaglia.scoria"] = nil
	local sc2 = require "battaglia.scoria"
	local v = sc2.new(vec(1, 0.2, 0.3, 1))
	sc2.update(v, 1 / 60, { x = 100, y = 50, facing = 1, grounded = true, moving = 0 })
	local k = v.k
	local braccio, testa
	for _, n in ipairs(nodi) do
		if n.parent == v.braccio_a and n.img == "braccio" then braccio = n end
		if n.parent == v.testa and n.img == "testa" then testa = n end
	end
	check(braccio and math.abs(braccio.pos.x - (D.pezzi.braccio.x - 3) * k) < 1e-6
		and math.abs(braccio.pos.y - (D.pezzi.braccio.y + 2) * k) < 1e-6
		and math.abs(v.braccio_a.pos.x - (D.punti.spalle[1] + 3 + v.posa.braccio_a_x) * k) < 1e-6,
		"perni: il braccio gira attorno al perno spostato e da fermo resta dov'era")
	check(testa and math.abs(testa.pos.y - (D.pezzi.testa.y - 4) * k) < 1e-6
		and math.abs(v.cima.pos.y - (D.punti.cima[2] - 4 + v.posa_fiamma.fiamma_y) * k) < 1e-6,
		"perni: la testa e la fiammella restano dov'erano")
	package.loaded["battaglia.perni"] = nil
	package.loaded["battaglia.scoria"] = nil
	scoria = require "battaglia.scoria"
end

-- il perno del braccio davanti spostato: l'arma resta nella mano (con una
-- mira che non sposta niente e il braccio davanti che impugna)
do
	local A2 = require "battaglia.animazioni"
	local vecchia = A2.mira_missile
	A2.mira_missile = { durata = 1, ciclo = true, tracce = {} }
	package.loaded["battaglia.perni"] = { braccio = { 3, -2 } }
	package.loaded["battaglia.scoria"] = nil
	local sc2 = require "battaglia.scoria"
	local v = sc2.new(vec(1, 0.2, 0.3, 1))
	sc2.set_weapon(v, "missile")
	for _ = 1, 30 do sc2.update(v, 1 / 60, { x = 100, y = 50, facing = 1, grounded = true, moving = 0, turno = true, aim = 0.3 }) end
	local g = PRESE.missile
	local gx, gy = mondo(v.armi.missile, g.presa[1], g.presa[2])
	local px, py = mondo(v.braccio_a, 0, 0)
	local b, pu = D0.pezzi.braccio, D0.pezzi.pugno
	local hx, hy = mondo(v.braccio_a, (b.x - 3) * v.k, (b.y + 2 - b.h / 2 + pu.h * 0.4) * v.k)
	check(math.abs(gx - hx) < 0.5 and math.abs(gy - hy) < 0.5 and px ~= gx, "perni: col perno del braccio spostato l'arma resta nella mano")
	A2.mira_missile = vecchia
	package.loaded["battaglia.perni"] = nil
	package.loaded["battaglia.scoria"] = nil
	scoria = require "battaglia.scoria"
end

-- i pezzi che le clip mostrano e tolgono, e le clip con l'arma in mano
do
	local A2 = require "battaglia.animazioni"
	local vecchie = { fermo = A2.fermo, fermo_arma = A2.fermo_arma, fermo_arma_missile = A2.fermo_arma_missile }
	A2.fermo_arma_missile = nil
	A2.fermo = { durata = 1, ciclo = true, tracce = { mostra_braccio_a = { 0, 0, 2 }, mostra_manina_a = { 0, 1, 2 },
		manina_a_x = { 0, 7, 2 }, manina_a = { 0, 0.5, 2 }, mostra_ala = { 0, 0, 2 }, mostra_coda = { 0, 0, 2 },
		mostra_testa = { 0, 0, 2 }, mostra_gamba_d = { 0, 0, 2 } } }
	A2.fermo_arma = { durata = 1, ciclo = true, tracce = { mostra_braccio_a = { 0, 0, 2 }, arma = { 0, 0.5, 2 } } }
	package.loaded["battaglia.scoria"] = nil
	local sc2 = require "battaglia.scoria"
	local v = sc2.new(vec(1, 0.2, 0.3, 1))
	local st2 = { x = 100, y = 50, facing = 1, grounded = true, moving = 0, turno = false }
	v.arma_t = 100
	for _ = 1, 3 do sc2.update(v, 1 / 60, st2) end
	check(not v.braccio_a.enabled and v.manina_a.enabled
		and v.braccio_d.enabled and not v.manina_d.enabled and not v.ala.enabled
		and not v.coda[1][1].enabled and not v.coda[1][2].enabled and not v.testa.enabled and v.collo.enabled
		and not v.gamba_d.enabled and v.gamba_a.enabled and v.busto.enabled,
		"pezzi: la clip toglie braccio, testa (non la fiammella), gamba, ala e coda e mette la manina")
	local D = require "battaglia.diavoletto"
	local mx = (D.punti.spalle[1] + D.pezzi.braccio.x + 7) * v.k
	check(math.abs(v.manina_a.pos.x - mx) < 1e-6 and math.abs(math.rad(v.manina_a.euler.z) - 0.5) < 1e-6,
		"pezzi: la manina è libera, la clip la sposta e la gira")
	st2.turno = true
	for _ = 1, 30 do sc2.update(v, 1 / 60, st2) end
	check(v.ala.enabled and v.coda[1][1].enabled and not v.braccio_a.enabled and v.presa.enabled,
		"pezzi: di turno la clip con l'arma, l'arma senza braccio")
	check(math.abs(math.rad(v.giro.euler.z) - (-0.35 + 0.5)) < 0.05,
		"clip con l'arma: il canale arma gira l'arma attorno al perno")
	-- chi aspetta prende e posa l'arma a caso
	st2.turno = false
	v.arma_t = 1
	local presa, posata = false, false
	for _ = 1, 60 * 40 do
		sc2.update(v, 1 / 60, st2)
		if v.presa.enabled then presa = true elseif presa then posata = true end
	end
	check(presa and posata, "attesa: chi non è di turno prende e posa l'arma")
	A2.fermo, A2.fermo_arma, A2.fermo_arma_missile = vecchie.fermo, vecchie.fermo_arma, vecchie.fermo_arma_missile
	package.loaded["battaglia.scoria"] = nil
	scoria = require "battaglia.scoria"
end

-- le clip solo per un'arma (fermo_arma_mallet) e le impugnature di ogni arma
do
	local A2 = require "battaglia.animazioni"
	local st2 = { x = 100, y = 50, facing = 1, grounded = true, moving = 0, turno = true }
	local function gira(nome)
		package.loaded["battaglia.scoria"] = nil
		local sc2 = require "battaglia.scoria"
		local v = sc2.new(vec(1, 0.2, 0.3, 1))
		sc2.set_weapon(v, nome)
		for _ = 1, 30 do sc2.update(v, 1 / 60, st2) end
		return math.rad(v.giro.euler.z)
	end
	local maglio0, missile0 = gira("mallet"), gira("missile")
	A2.fermo_arma_mallet = { durata = 1, ciclo = true, tracce = { arma = { 0, 1, 2 } } }
	local maglio, missile = gira("mallet"), gira("missile")
	check(maglio - maglio0 > 0.8 and math.abs(missile - missile0) < 0.05,
		"clip dell'arma: il Maglio usa fermo_arma_mallet, le altre fermo_arma")
	A2.fermo_arma_mallet = nil
	package.loaded["battaglia.scoria"] = nil
	scoria = require "battaglia.scoria"
	-- l'arma è un pezzo come gli altri: la clip la toglie (mostra_arma)
	A2.fermo_arma_sword = { durata = 1, ciclo = true, tracce = { mostra_arma = { 0, 0, 2 } } }
	package.loaded["battaglia.scoria"] = nil
	local sc3 = require "battaglia.scoria"
	local v = sc3.new(vec(1, 0.2, 0.3, 1))
	sc3.set_weapon(v, "sword")
	for _ = 1, 3 do sc3.update(v, 1 / 60, st2) end
	check(not v.presa.enabled and v.braccio_a.enabled, "pezzi: la clip toglie l'arma, il braccio resta")
	A2.fermo_arma_sword = nil
	package.loaded["battaglia.scoria"] = nil
	scoria = require "battaglia.scoria"
	local PR = require "battaglia.impugnature"
	for nome in pairs(require("battaglia.armi").armi) do
		local g = PR[nome]
		check(g ~= nil and #g.presa == 2 and #g.perno == 2 and #g.spalla == 2, nome .. ": ha presa, perno e spalla")
	end

	-- chi impugna l'arma lo sceglie la clip; l'arma gira attorno al perno, che
	-- sta sulla spalla dell'arma (più arma_x e arma_y della clip)
	local function prova(tracce, impugna, livelli)
		A2.fermo_arma_sword = { durata = 1, ciclo = true, tracce = tracce, impugna = impugna, livelli = livelli }
		package.loaded["battaglia.scoria"] = nil
		local sc = require "battaglia.scoria"
		local v = sc.new(vec(1, 0.2, 0.3, 1))
		sc.set_weapon(v, "sword")
		for _ = 1, 60 do sc.update(v, 1 / 60, st2) end
		v.x[1], v.x[2] = 1, 0
		sc.update(v, 0, st2)
		return v
	end
	local g = PR.sword
	local function vicini(ax, ay, bx, by) return math.abs(ax - bx) < 0.3 and math.abs(ay - by) < 0.3 end
	local function perno(v) return mondo(v.armi.sword, g.perno[1], g.perno[2]) end
	local v1 = prova({ arma = { 0, 0.3, 2 } }, "manina_d")
	local mx, my = mondo(v1.manina_d, 0, 0)
	check(vicini(mx, my, mondo(v1.armi.sword, g.presa[1], g.presa[2])), "impugna manina dietro: la manina sta sulla presa")
	local v2 = prova({ arma = { 0, 1.2, 2 } }, "manina_d")
	local p1x, p1y = perno(v1)
	local p2x, p2y = perno(v2)
	check(vicini(p1x, p1y, p2x, p2y), "perno: girando l'arma il perno resta fermo")
	local sx, sy = mondo(v2.forma, g.spalla[1] * v2.k, g.spalla[2] * v2.k)
	check(vicini(p2x, p2y, sx, sy), "perno: sta sulla spalla dell'arma")
	local v3 = prova({ arma_x = { 0, 10, 2 } }, "manina_d")
	local p3x, p3y = perno(v3)
	sx, sy = mondo(v3.forma, (g.spalla[1] + 10) * v3.k, g.spalla[2] * v3.k)
	check(vicini(p3x, p3y, sx, sy), "perno: arma_x lo sposta")
	-- il braccio dietro gira verso la presa (ci arriva se la presa è lontana dalla
	-- sua spalla quanto è lungo il braccio)
	local v4 = prova({}, "braccio_d")
	local b, pu = D0.pezzi.braccio_dietro, D0.pezzi.pugno
	local jx, jy = mondo(v4.braccio_d, 0, 0)
	local hx, hy = mondo(v4.braccio_d, b.x * v4.k, (b.y - b.h / 2 + pu.h * 0.4) * v4.k)
	local gx, gy = mondo(v4.armi.sword, g.presa[1], g.presa[2])
	check(math.abs(angolo(math.atan2(hy - jy, hx - jx) - math.atan2(gy - jy, gx - jx))) < 0.01,
		"impugna braccio dietro: il braccio punta verso la presa")
	-- i livelli della clip: il braccio davanti sotto il busto, l'arma in fondo
	local v5 = prova({}, nil, { "arma", "coda", "ala", "braccio_d", "manina_d", "gamba_d", "gamba_a", "braccio_a",
		"busto", "testa", "manina_a" })
	check(v5.presa.ordine < v5.coda[1][1].ordine and v5.braccio_a.ordine < v5.busto.ordine
		and v5.busto.ordine < v5.collo.ordine, "livelli: la clip sceglie cosa sta davanti")
	A2.fermo_arma_sword = nil
	package.loaded["battaglia.scoria"] = nil
	scoria = require "battaglia.scoria"
end

-- Pelli (battaglia/pelli.lua) ---------------------------------------------------

-- pelli finte: una testa nuova senza facce col colore della squadra, un elmo
-- sopra, una coda a segmenti, braccia nuove
local PELLI = require "battaglia.pelli"
local function pz(img, modo, tinta) return { img = img, tinta = tinta, x = 1, y = 2, w = 30, h = 40, modo = modo } end
PELLI.pelli.prova_testa = { categoria = "testa", pezzi = { testa = pz("t", "sostituisce", "t_tinta") } }
PELLI.pelli.prova_elmo = { categoria = "elmo", pezzi = { testa = pz("e", "sopra"), busto = pz("eb", "sopra") } }
local coda = {}
for i = 1, 5 do
	coda["coda_" .. i] = pz("c" .. i, "sostituisce")
	coda["coda_" .. i .. "_bordo"] = pz("cb" .. i, "sostituisce")
end
PELLI.pelli.prova_coda = { categoria = "coda", pezzi = coda }
PELLI.pelli.prova_corpo = { categoria = "corpo", pezzi = { braccio = pz("br", "sostituisce"),
	braccio_dietro = pz("bd", "sostituisce") } }
local function immagini(da)
	local l = {}
	for i = da, #nodi do
		local n = nodi[i]
		if n.img then l[n.img] = (l[n.img] or 0) + 1 end
	end
	return l
end
check(immagini(1).braccio and immagini(1).coda_1, "pelli: senza, il diavoletto di base")
local primo = #nodi + 1
local v = scoria.new(vec(1, 0.2, 0.3, 1), { "prova_elmo", "prova_testa", "prova_coda", "prova_corpo" })
local im = immagini(primo)
check(im.t == 1 and im.e == 1 and im.eb == 1 and not im.testa, "pelli: la testa sostituita, l'elmo sopra")
check(im.c1 == 1 and im.cb5 == 1 and not im.coda_1 and not im.coda_5_bordo
	and v.coda[1][1] ~= v.coda[1][2], "pelli: la coda nuova a segmenti, bordi e colori")
check(im.br == 1 and im.bd == 1 and not im.braccio and not im.braccio_dietro, "pelli: le braccia nuove, una per lato")
check(v.teste[2].parent == v.testa and v.teste[1].img == "t" and v.teste[2].img == "e", "pelli: l'elmo sta sulla testa")
check(v.teste_t[1].enabled and v.teste_t[1].img == "t_tinta" and not v.teste_t[2].enabled,
	"pelli: il colore della squadra sulla testa nuova, sotto l'elmo")
st = { x = 100, y = 50, facing = 1, grounded = true, moving = 0, turno = true }
for _ = 1, 30 do scoria.update(v, 1 / 60, st) end
scoria.hit(v, 1)
for _ = 1, 10 do scoria.update(v, 1 / 60, st) end
check(v.faccia == "testa_colpita" and v.teste[1].img == "t" and v.teste[2].enabled and v.teste[2].img == "e",
	"pelli: colpito, la testa nuova fa anche la faccia colpita, l'elmo resta")
scoria.die(v)
for _ = 1, 60 do scoria.update(v, 1 / 60, st) end
check(tutto_finito(), "pelli: animato, valori finiti")
for nome in pairs(PELLI.pelli) do
	if nome:sub(1, 6) == "prova_" then PELLI.pelli[nome] = nil end
end

-- Targa ------------------------------------------------------------------------

local primo = #nodi + 1
local tt = targa.nuove({ vec(1, 0.2, 0.3, 1), vec(0.2, 0.5, 1, 1) }, { "Rosso", "Blu" })
local primo_testo, ultima_forma = math.huge, 0
for k = primo, #nodi do
	if nodi[k].text then primo_testo = math.min(primo_testo, k)
	elseif not nodi[k].invisibile then ultima_forma = k end
end
check(ultima_forma < primo_testo, "targhe: prima tutte le barre, poi tutti i testi (due draw call)")
local t = tt[1]
targa.vita(t, 100, 100)
targa.update(t, 1 / 60, 0, 0, 1)
local piena = t.pieno.size.x
targa.vita(t, 60, 100)
targa.update(t, 1 / 60, 0, 0, 1)
check(t.numero.text == "60", "targa: il numero è la vita")
check(math.abs(t.pieno.size.x - piena * 0.6) < 0.5, "targa: la vita scende subito")
check(math.abs(t.scia.size.x - piena) < 0.5, "targa: il pezzo perso resta un attimo")
for _ = 1, 120 do targa.update(t, 1 / 60, 0, 0, 1) end
check(math.abs(t.scia.size.x - t.pieno.size.x) < 0.5, "targa: poi si consuma fino alla vita")
targa.vita(t, 60, 100, 20)
targa.update(t, 1 / 60, 0, 0, 1)
check(t.scudo.enabled and math.abs(t.scudo.pos.x - t.pieno.pos.x - t.pieno.size.x) < 0.5,
	"targa: lo scudo comincia dove finisce la vita")
targa.vita(t, 100, 100, 50)
targa.update(t, 1 / 60, 0, 0, 1)
check(t.pieno.size.x + t.scudo.size.x <= piena + 0.5, "targa: vita più scudo stanno nella cornice")
targa.vita(t, 0, 100)
targa.update(t, 1 / 60, 0, 0, 1)
check(not t.pieno.enabled and tutto_finito(), "targa: a zero la vita sparisce, valori finiti")

-- Camera -----------------------------------------------------------------------

local c = camera.new(1280, 720, 1920, 1080)
camera.salta(c, 960, 540, camera.tutta(c))
check(c.x == 960 and c.y == 540, "zoom mappa: si vede tutta la mappa, la camera non si sposta")
camera.salta(c, 100, 100, camera.tutta(c))
local _, fondo = camera.allo_schermo(c, 960, 0)
check(c.x == 960 and math.abs(fondo - camera.SOTTO) < 1e-9, "zoom mappa: in basso il fondo della mappa resta sopra l'HUD")
check(camera.tutta(c) == camera.LIVELLI[#camera.LIVELLI], "l'ultimo livello di zoom mostra tutta la mappa")

camera.salta(c, 640, 360, 2.2)
local px, py = camera.allo_schermo(c, 700, 400)
local wx, wy = camera.al_mondo(c, px, py)
check(math.abs(wx - 700) < 1e-9 and math.abs(wy - 400) < 1e-9, "da mondo a schermo e ritorno")
px, py = camera.allo_schermo(c, 640, 360)
check(px == 640 and py == 360, "il punto seguito sta al centro dello schermo")

camera.salta(c, 0, 0, 2.2)
px, py = camera.allo_schermo(c, 0, 0)
check(math.abs(px) < 1e-9 and math.abs(py - camera.SOTTO) < 1e-9,
	"nell'angolo la camera non esce dai lati, e il fondo della mappa resta sopra l'HUD")
camera.salta(c, 1920, 1080, 2.2)
px, py = camera.allo_schermo(c, 1920, 1080)
check(math.abs(px - 1280) < 1e-9 and math.abs(py - 720) < 1e-9, "in alto a destra la camera non esce dalla mappa")

-- telefono 20:9 (ui/schermo.lua): lo schermo vero va da x = -160 a 1440
local l = camera.new(1280, 720, 1920, 1080)
camera.vista(l, -160, 0, 1440, 720)
camera.salta(l, 1000, 500, 1)
px, py = camera.allo_schermo(l, 1000, 500)
check(px == 640 and py == 360, "schermo largo: il punto seguito sta al centro")
check(math.abs(camera.tutta(l) - 1600 / 1920) < 1e-9, "schermo largo: la mappa intera è larga quanto lo schermo")
camera.cambia(l, 5)
check(camera.zoom(l) == camera.tutta(l), "schermo largo: il livello MAPPA non mostra il vuoto ai lati")
camera.salta(l, 0, 540, camera.zoom(l))
px = camera.allo_schermo(l, 0, 540)
check(math.abs(px + 160) < 1e-9, "schermo largo: il bordo sinistro della mappa sul bordo vero dello schermo")

-- l'inseguimento non dipende dalla frequenza dello schermo
local a, b = camera.new(1280, 720, 1920, 1080), camera.new(1280, 720, 1920, 1080)
camera.salta(a, 400, 300, 2.2)
camera.salta(b, 400, 300, 2.2)
for _ = 1, 30 do camera.segui(a, 1 / 60, 800, 420, 2.2) end
for _ = 1, 60 do camera.segui(b, 1 / 120, 800, 420, 2.2) end
check(math.abs(a.x - b.x) < 0.01 and math.abs(a.y - b.y) < 0.01,
	string.format("a 60 e 120 Hz la camera arriva allo stesso punto (%.2f, %.2f)", a.x - b.x, a.y - b.y))
for _ = 1, 300 do camera.segui(a, 1 / 60, 800, 420, 1.5) end
check(math.abs(a.x - 800) < 0.5 and math.abs(a.s - 1.5) < 0.01, "la camera raggiunge il punto e lo zoom")

-- inquadratura di chi spara e del colpo: da vicino tutti e due restano sullo
-- schermo (sopra l'HUD) mentre il colpo vola via, e quando sono vicini lo zoom non cambia
local function dentro(cam, x, y)
	local sx, sy = camera.allo_schermo(cam, x, y)
	return sx >= 0 and sx <= cam.w and sy >= 150 and sy <= cam.h
end
local q = camera.new(1280, 720, 1920, 1080)
camera.salta(q, 300, 400, 2.2)
local tutti_dentro = true
for i = 1, 90 do
	camera.inquadra(q, 1 / 60, 300, 400, 300 + i * 16, 400 + i * 5, 2.2)
	tutti_dentro = tutti_dentro and dentro(q, 300, 400) and dentro(q, 300 + i * 16, 400 + i * 5)
end
check(tutti_dentro, "inquadratura: chi spara e il colpo restano sempre sullo schermo")
check(q.s < 2.2 and q.s >= camera.tutta(q), "inquadratura: si allontana, ma non oltre tutta la mappa")
for _ = 1, 600 do camera.inquadra(q, 1 / 60, 300, 400, 330, 410, 2.2) end
check(math.abs(q.s - 2.2) < 0.01, "inquadratura: con il colpo vicino torna allo zoom scelto")
local q2 = camera.new(1280, 720, 1920, 1080)
camera.salta(q2, 300, 400, 2.2)
for _ = 1, 60 do camera.inquadra(q2, 1 / 60, 300, 400, 1700, 900, 2.2) end
local q3 = camera.new(1280, 720, 1920, 1080)
camera.salta(q3, 300, 400, 2.2)
for _ = 1, 120 do camera.inquadra(q3, 1 / 120, 300, 400, 1700, 900, 2.2) end
check(math.abs(q2.s - q3.s) < 0.01 and math.abs(q2.x - q3.x) < 0.5,
	"inquadratura: uguale a 60 e 120 Hz")

-- la scossa: parte nella direzione del colpo, è uguale a 60 e 120 Hz e si spegne
camera.scuoti(a, 1, 0, 20)
camera.scuoti(b, 1, 0, 20)
local ox = camera.scossa(a, 0)
check(math.abs(ox - 20) < 1e-9, "scossa: lo schermo parte spinto nella direzione del colpo")
for _ = 1, 6 do ox = camera.scossa(a, 1 / 60) end
local ox2
for _ = 1, 12 do ox2 = camera.scossa(b, 1 / 120) end
check(math.abs(ox - ox2) < 1e-6, "scossa: uguale a 60 e 120 Hz")
camera.scuoti(a, 0, 1, 5)
check(a.sc_x == 1, "scossa: una più debole non cancella quella in corso")
for _ = 1, 60 do ox = camera.scossa(a, 1 / 60) end
check(ox == 0, "scossa: dopo un attimo si ferma")

camera.cambia(c, 5)
check(camera.zoom(c) == camera.tutta(c), "rotella indietro: si ferma su tutta la mappa")
camera.cambia(c, -5)
check(camera.zoom(c) == camera.LIVELLI[1], "rotella avanti: si ferma sul più vicino")
camera.prossimo(c); camera.prossimo(c); camera.prossimo(c)
check(c.livello == 1, "il pulsante gira: vicino, medio, mappa, vicino")

-- La mira (battaglia/mira.lua): gradi uguali a destra e a sinistra, tacche
-- della potenza, puntini alla stessa distanza e punta sull'ultimo punto
local mira = require "battaglia.mira"
check(mira.gradi(math.rad(40)) == 40 and mira.gradi(math.rad(140)) == 40, "mira: 40° a destra e a sinistra")
check(mira.gradi(math.rad(-30)) == -30 and mira.gradi(math.rad(-150)) == -30, "mira: in basso i gradi sono negativi")
check(mira.gradi(math.rad(90)) == 90, "mira: dritto in alto 90°")
check(mira.tacca(0.94) == 18 and mira.tacca(0.95) == 19 and mira.tacca(1) == 20, "mira: una tacca ogni 5%")
local linea = {}
for i = 1, 4 do linea[i] = { x = 40 * i, y = 0 } end
local out = {}
local k = mira.posa(linea, 4, 15, 40, out)
check(k == 11 and out[1].x == 7.5 and math.abs(out[2].x - out[1].x - 15) < 1e-9 and out[k].x <= 160,
	"mira: un puntino ogni 15 dalla bocca fino in fondo")
k = mira.posa(linea, 4, 1, 40, out)
check(k <= 40 and k >= 38, "mira: non più di 40 puntini, si allargano")
local m = mira.nuova()
check(#m.nodi == 2 * mira.PUNTI + 5 + mira.ANELLI and m.cartello, "mira: puntini, linea, mirino, lancetta, punta, anelli e cartellino")
mira.cartellino(m, 0, 0, 2, 40, 0.94, vec(1, 0, 0, 1))
check(m.c.testo == "40°" and m.c.p == 94 and m.c.radice.scale.x == 0.5, "mira: gradi e potenza, grandi uguali a ogni zoom")
mira.mirino(m, 100, 50, 0, 2, 0.5, vec(1, 0, 0, 1))
check(m.mir.enabled and m.mir.scale.x == 0.5 and math.abs(m.mir.pos.x - (100 + mira.MIRINO_D / 2)) < 1e-9 and m.mir.pos.y == 50,
	"mira: il mirino a distanza fissa sullo schermo nella direzione della mira")
check(m.linee[2].enabled and m.linee[2].pos.x == 100 and m.linee[2].size.x < mira.MIRINO_D / 2, "mira: la linea dalla bocca fino al mirino")
mira.lancetta(m, 100, 50, math.rad(30), 2, 0.5, vec(1, 0, 0, 1))
check(m.lanc.enabled and not m.mir.enabled and not m.linee[2].enabled and math.abs(m.lanc.euler.z - 30) < 1e-6 and m.lanc.scale.x == 0.5,
	"mira: la lancetta girata come la mira prende il posto del mirino")
mira.punta(m, 100, 50, math.pi, 2, vec(1, 0, 0, 1))
check(m.punta.enabled and not m.lanc.enabled and not m.c.radice.enabled and m.punta.pos.x < 100 and m.punta.scale.x == 0.5,
	"mira: le armi da vicino hanno solo la punta, senza lancetta né cartellino")
mira.bersagli(m, { { x = 10, y = 20 }, { x = 30, y = 40 } }, 2, 2, vec(1, 0, 0, 1))
check(m.anelli[1].enabled and m.anelli[2].enabled and not m.anelli[3].enabled and m.anelli[2].pos.x == 30,
	"mira: un anello ai piedi di ogni bersaglio")
mira.via(m)
check(not m.lanc.enabled and not m.mir.enabled and not m.c.radice.enabled and not m.linee[2].enabled
	and not m.punta.enabled and not m.anelli[1].enabled, "mira: via spegne tutto")

-- Controller (ui/controller.lua): le azioni come le manda Defold
local controller = require "ui.controller"
local c = controller.new("Android")
check(controller.input(c, hash("touch"), { pressed = true }) == nil, "controller: il tocco non è suo")
local ev = controller.input(c, hash("pad_a"), { pressed = true, value = 1 })
check(#ev == 1 and ev[1].nome == "a" and ev[1].premuto and ev[1].ui == "conferma" and c.giu.a, "controller: A premuto, nei menu conferma")
ev = controller.input(c, hash("pad_a"), { value = 1 })
check(#ev == 0, "controller: A tenuto non si ripete")
ev = controller.input(c, hash("pad_a"), { released = true, value = 0 })
check(#ev == 1 and not ev[1].premuto and not c.giu.a, "controller: A lasciato")
ev = controller.input(c, hash("pad_rt"), { value = 0.3 })
check(#ev == 0, "controller: il grilletto a un terzo non spara")
ev = controller.input(c, hash("pad_rt"), { value = 0.8 })
check(#ev == 1 and ev[1].nome == "rt", "controller: il grilletto oltre metà sì")
controller.input(c, hash("pad_dx_destra"), { value = 0.6 })
controller.input(c, hash("pad_dx_su"), { value = 0.8 })
check(math.abs(c.dx.x - 0.6) < 1e-9 and math.abs(c.dx.y + 0.8) < 1e-9, "controller: su Android gli assi verticali arrivano capovolti e si raddrizzano")
local pc = controller.new("Windows")
controller.input(pc, hash("pad_dx_su"), { value = 0.8 })
check(math.abs(pc.dx.y - 0.8) < 1e-9, "controller: sul computer la levetta destra, y in su")
controller.input(c, hash("pad_dx_su"), { value = 1 })
controller.input(c, hash("pad_dx_destra"), { value = 1 })
check(math.abs(c.dx.x ^ 2 + c.dx.y ^ 2 - 1) < 1e-9, "controller: in diagonale la levetta non va oltre 1")
controller.input(c, hash("pad_dx_destra"), { released = true, value = 0 })
check(c.dx.x == 0 and c.dx.y == -1, "controller: lasciato un asse, l'altro resta")
ev = controller.input(c, hash("pad_sx_sinistra"), { value = 0.9 })
check(#ev == 1 and ev[1].nome == "sinistra" and ev[1].levetta and ev[1].ui == "sinistra", "controller: la levetta sinistra fa da croce nei menu")
ev = controller.input(c, hash("pad_sx_sinistra"), { value = 0.95 })
check(#ev == 0, "controller: una volta sola finché non torna indietro")
controller.input(c, hash("pad_sx_sinistra"), { released = true, value = 0 })
ev = controller.input(c, hash("pad_sx_sinistra"), { value = 0.9 })
check(#ev == 1, "controller: tornata al centro, di nuovo")
-- un controller che Defold non conosce: dall'azione grezza, coi numeri di Android
controller.input(c, hash("pad_connesso"), { gamepad = 1, gamepad_unknown = true })
ev = controller.input(c, hash("pad_grezzo"), { gamepad = 2, gamepad_buttons = { 1 } })
check(#ev == 0, "controller: il grezzo di un controller conosciuto non conta")
local tasti = {}
for i = 1, 20 do tasti[i] = 0 end
tasti[1], tasti[7] = 1, 1
ev = controller.input(c, hash("pad_grezzo"), { gamepad = 1, gamepad_buttons = tasti,
	gamepad_axis = { 0.1, 0, 0.5, -0.5, 0, 1, 0, -1 } })
local nomi = {}
for _, e in ipairs(ev) do nomi[#nomi + 1] = e.nome end
check(table.concat(nomi, " ") == "a rt su y", "controller sconosciuto: A, Y, la croce in su e RT (premuto su questo controller: quello di prima non conta più), in ordine di nome")
check(c.sx.x == 0 and math.abs(c.dx.x - 0.5) < 1e-9 and math.abs(c.dx.y + 0.5) < 1e-9, "controller sconosciuto: zona morta e levetta destra, capovolta su Android")
check(controller.new("Darwin").grezzi == nil, "controller: sul computer i grezzi non si leggono")
ev = controller.input(c, hash("pad_a"), { gamepad = 1, pressed = true, value = 1 })
check(#ev == 0, "controller: un controller letto dai grezzi non conta anche tradotto (una fonte sola)")
-- su Android il PlayStation è anche "Touchpad" e "Motion Sensors": non contano
-- (scrivevano sulle levette e la mira scattava)
local ps = controller.new("Android")
controller.input(ps, hash("pad_connesso"), { gamepad = 0, gamepad_name = "Wireless Controller" })
controller.input(ps, hash("pad_connesso"), { gamepad = 1, gamepad_name = "Wireless Controller Touchpad" })
controller.input(ps, hash("pad_connesso"), { gamepad = 2, gamepad_name = "Wireless Controller Motion Sensors", gamepad_unknown = true })
check(ps.famiglia == "playstation", "controller: il touchpad non cambia il controller in uso")
controller.input(ps, hash("pad_dx_destra"), { gamepad = 0, value = 0.8 })
controller.input(ps, hash("pad_dx_destra"), { gamepad = 1, value = 0.1 })
controller.input(ps, hash("pad_dx_destra"), { gamepad = 1, released = true, value = 0 })
controller.input(ps, hash("pad_grezzo"), { gamepad = 2, gamepad_buttons = {}, gamepad_axis = { 0, 0, 0, 0 } })
check(math.abs(ps.dx.x - 0.8) < 1e-9, "controller: touchpad e sensori non toccano le levette")
-- due controller: le levette contano da quello che ha premuto un tasto per ultimo
controller.input(ps, hash("pad_dx_destra"), { gamepad = 3, value = 0.3 })
check(math.abs(ps.dx.x - 0.8) < 1e-9, "controller: le levette di un altro controller non contano")
controller.input(ps, hash("pad_a"), { gamepad = 3, pressed = true, value = 1 })
controller.input(ps, hash("pad_dx_destra"), { gamepad = 3, value = 0.3 })
check(math.abs(ps.dx.x - 0.3) < 1e-9, "controller: premuto un tasto, contano le sue")
-- il grilletto che trema attorno a metà corsa non si preme due volte (Sergio:
-- una pressione sparava anche con l'arma dopo)
local tr = controller.new("Android")
local function rt(v, gp)
	local e = controller.input(tr, hash("pad_rt"), { gamepad = gp or 0, value = v, released = v == 0, pressed = v > 0 and not tr.giu.rt })
	local n = {}
	for _, x in ipairs(e) do n[#n + 1] = (x.premuto and "+" or "-") .. x.nome end
	return table.concat(n, " ")
end
local seq = { rt(0.8), rt(0.45), rt(0.6), rt(0.3), rt(0.55), rt(0.1), rt(0) }
check(table.concat(seq, ",") == "+rt,,,,,-rt,", "controller: il grilletto si preme oltre metà e si lascia sotto il 20%")
rt(0.9)
check(rt(0, 1) == "" and tr.giu.rt, "controller: un altro controller non lascia il grilletto di questo")
-- Defold mette released quando un valore scende sotto 0,9, non quando torna a
-- zero: non vuol dire lasciato (Sergio: la mira scattava sempre allo stesso
-- angolo e una pressione sparava due volte)
local dv = controller.new("Android")
controller.input(dv, hash("pad_dx_destra"), { value = 1, pressed = true })
controller.input(dv, hash("pad_dx_su"), { value = 0.3 })
controller.input(dv, hash("pad_dx_destra"), { value = 0.85, released = true })
check(math.abs(dv.dx.x - 0.85) < 1e-9, "controller: la levetta sotto 0,9 non torna a zero (la mira non scatta)")
controller.input(dv, hash("pad_dx_destra"), { value = 0 })
check(dv.dx.x == 0, "controller: tornata a zero, zero")
local function rt2(v, extra)
	local a = { value = v }
	for k, x in pairs(extra or {}) do a[k] = x end
	local e = controller.input(dv, hash("pad_rt"), a)
	local n = {}
	for _, x in ipairs(e) do n[#n + 1] = (x.premuto and "+" or "-") .. x.nome end
	return table.concat(n, " ")
end
local seq2 = { rt2(0.6), rt2(1, { pressed = true }), rt2(0.85, { released = true }), rt2(0.6), rt2(0.3), rt2(0.1), rt2(0) }
check(table.concat(seq2, ",") == "+rt,,,,,-rt,", "controller: il grilletto che torna su si lascia una volta sola, sotto il 20%")
-- le impostazioni: i tasti da cambiare (menu/impostazioni.lua)
local m = controller.new("Windows")
check(controller.assegna(m, "spara", "b") and m.tasti.b == "spara" and m.tasti.rt == "baratto",
	"controller: SPARA su B, il baratto prende RT")
check(not controller.assegna(m, "spara", "start") and m.tasti.start == "rotellina", "controller: Start resta alla rotellina")
local salvati = controller.da_salvare(m)
check(salvati.start == nil and salvati.b == "spara", "controller: si salva senza Start")
local m2 = controller.new("Windows")
check(controller.usa(m2, salvati) and m2.tasti.b == "spara" and m2.tasti.start == "rotellina", "controller: la mappatura salvata si riprende")
check(controller.usa(m2, { a = "spara" }) and m2.tasti.a == "spara" and controller.tasto_di(m2, "baratto") == nil,
	"controller: una mappatura con comandi senza tasto si prende")
check(not controller.usa(m2, { a = "vola" }) and not controller.usa(m2, { a = "spara", b = "spara" }),
	"controller: comandi sconosciuti o doppi no")
controller.base(m2)
check(controller.tasto_di(m2, "salta") == nil, "controller: di base si salta con la levetta")
check(controller.assegna(m2, "salta", "a") and m2.tasti.a == "salta" and m2.tasti.su == "teletrasporto",
	"controller: SALTA su A, il teletrasporto va sul primo tasto libero (croce su)")
controller.togli(m2, "teletrasporto")
check(controller.tasto_di(m2, "teletrasporto") == nil and m2.tasti.su == nil, "controller: Y toglie il tasto")
controller.togli(m2, "rotellina")
check(m2.tasti.start == "rotellina", "controller: Start non si toglie")
local mv = controller.new("Windows")
controller.input(mv, hash("pad_rt"), { value = 0.3 })
check(math.abs(mv.valore.rt - 0.3) < 1e-9, "controller: quanto è premuto il grilletto")
controller.input(mv, hash("pad_rt"), { released = true, value = 0 })
check(mv.valore.rt == 0, "controller: grilletto lasciato")
controller.base(m2)
check(m2.tasti.rt == "spara" and m2.tasti.b == "baratto", "controller: RIPRISTINA torna a quella di Sergio")
check(controller.famiglia("Sony Interactive Entertainment Wireless Controller") == "playstation"
	and controller.famiglia("Nintendo Switch Pro Controller") == "nintendo"
	and controller.famiglia("Xbox Wireless Controller") == "xbox" and controller.famiglia("Wireless Controller") == "playstation" and controller.famiglia("8BitDo SN30") == "xbox",
	"controller: la famiglia dal nome")
m2.famiglia = "nintendo"
check(controller.nome(m2, "a") == "B" and controller.nome(m2, "rt") == "ZR" and controller.nome(m2, "giu") == "CROCE GIÙ",
	"controller: su Nintendo il tasto in basso si chiama B")

if failures > 0 then
	print(failures .. " test falliti")
	os.exit(1)
end
print("tutti i test passati")
