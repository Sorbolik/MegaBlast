-- Test della Scoria (battaglia/scoria.lua) e della targa con nome e vita
-- (battaglia/targa.lua) con un finto gui, e della camera (battaglia/camera.lua). Dalla radice del repository:
--   luajit tests/battaglia_test.lua
package.path = "client/?.lua;" .. package.path

-- finti vmath e gui: ogni nodo ricorda posizione, rotazione, scala e genitore
local function vec(x, y, z, w) return { x = x or 0, y = y or 0, z = z or 0, w = w } end
vmath = { vector3 = vec, vector4 = vec }
local nodi = {}
local function nuovo(p, s)
	local n = { pos = vec(p.x, p.y), euler = vec(), scale = vec(1, 1, 1), size = s, enabled = true }
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
	set_inherit_alpha = function() end, set_perimeter_vertices = function() end,
	set_texture = function() end, play_flipbook = function(n, img) n.img = img end, set_material = function() end,
	new_text_node = function(p, text) local n = nuovo(p); n.text = text; return n end,
	set_text = function(n, text) n.text = text end,
	set_size = function(n, v) n.size = copia(v) end,
	get_size = function(n) return n.size end,
	set_font = function() end, set_outline = function() end, set_pivot = function() end,
	set_slice9 = function() end, PIVOT_W = 3,
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

-- il pugno davanti, sull'impugnatura: lo mette l'avambraccio della mira
local function mano(name)
	return s.pugno_presa
end

-- dove deve stare la mano sull'impugnatura (battaglia/impugnature.lua), vista
-- dalla spalla, mirando ad a girati verso facing
local PRESE = require "battaglia.impugnature"
local function verso_mano(name, a, facing)
	local m = PRESE[name][#PRESE[name]]
	local al = facing > 0 and a or math.pi - a
	local x = m[1] * math.cos(al) - m[2] * math.sin(al)
	local y = m[1] * math.sin(al) + m[2] * math.cos(al)
	return math.atan2(y, x * facing)
end

-- l'arma gira attorno alla spalla e la mano la segue: dalla spalla, la mano
-- sta dov'è l'impugnatura con l'arma nella direzione della mira, girati a
-- destra o a sinistra
for _, name in ipairs({ "missile", "sword" }) do
	scoria.set_weapon(s, name)
	for _, a in ipairs({ 0.4, -0.8, 2.3, math.pi - 0.2 }) do
		st.aim = a
		st.facing = math.cos(a) < 0 and -1 or 1
		for _ = 1, 30 do scoria.update(s, 1 / 60, st) end
		local sx, sy = mondo(s.spalla, 0, 0)
		local mx, my = mondo(mano(name), 0, 0)
		local d = angolo(math.atan2(my - sy, mx - sx) - verso_mano(name, a, st.facing))
		check(math.abs(d) < 0.02, string.format("%s mirando a %.1f: la mano è nella direzione della mira (scarto %.3f)", name, a, d))
	end
end

-- il rinculo sposta arma e mano lungo l'asse, senza staccarle dalla mira
scoria.set_weapon(s, "missile")
st.aim, st.facing = 0.6, 1
for _ = 1, 30 do scoria.update(s, 1 / 60, st) end
local sx, sy = mondo(s.spalla, 0, 0)
local mx0, my0 = mondo(mano("missile"), 0, 0)
scoria.fire(s, "missile")
local indietro, rx, ry = false, nil, nil
for _ = 1, 4 do
	scoria.update(s, 1 / 60, st)
	local mx, my = mondo(mano("missile"), 0, 0)
	rx, ry = rx or mx, ry or my
	if (mx - sx) ^ 2 + (my - sy) ^ 2 < (mx0 - sx) ^ 2 + (my0 - sy) ^ 2 - 0.5 then indietro = true end
end
check(indietro, "rinculo: la mano torna indietro verso la spalla")
check(math.abs(angolo(math.atan2(my0 - ry, mx0 - rx) - 0.6)) < 0.02, "rinculo: la mano si sposta lungo l'asse dell'arma")

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
		if n.parent == v.braccio_a_img and n.img == "braccio" then braccio = n end
		if n.parent == v.testa and n.img == "testa" then testa = n end
	end
	check(braccio and math.abs(braccio.pos.x - (D.pezzi.braccio.x - 3) * k) < 1e-6
		and math.abs(braccio.pos.y - (D.pezzi.braccio.y + 2) * k) < 1e-6
		and math.abs(v.braccio_a.pos.x - (D.punti.spalle[1] + 3) * k) < 1e-6,
		"perni: il braccio gira attorno al perno spostato e da fermo resta dov'era")
	check(testa and math.abs(testa.pos.y - (D.pezzi.testa.y - 4) * k) < 1e-6
		and math.abs(v.cima.pos.y - (D.punti.cima[2] - 4) * k) < 1e-6,
		"perni: la testa e la fiammella restano dov'erano")
	package.loaded["battaglia.perni"] = nil
	package.loaded["battaglia.scoria"] = nil
	scoria = require "battaglia.scoria"
end

-- la spalla dell'arma spostata: l'arma gira attorno al punto nuovo e mirando
-- dritto resta dov'era
do
	local DA2 = require("battaglia.armi").armi
	local function punta(sc)
		local v = sc.new(vec(1, 0.2, 0.3, 1))
		sc.set_weapon(v, "missile")
		local st2 = { x = 100, y = 50, facing = 1, grounded = true, moving = 0, turno = true, aim = 0 }
		for _ = 1, 3 do sc.update(v, 1 / 60, st2) end
		v.x[1], v.x[2] = 1, 0
		sc.update(v, 0, st2)
		return v, mondo(v.armi.missile, DA2.missile.x, DA2.missile.y)
	end
	local _, x0, y0 = punta(scoria)
	package.loaded["battaglia.perni"] = { arma = { 6, -5 } }
	package.loaded["battaglia.scoria"] = nil
	local sc2 = require "battaglia.scoria"
	local v, x1, y1 = punta(sc2)
	local D = require "battaglia.diavoletto"
	check(math.abs(v.spalla.pos.x - (D.punti.spalla_arma[1] + 6) * v.k) < 1e-6,
		"perni: la spalla dell'arma si sposta")
	check(math.abs(x1 - x0) < 0.3 and math.abs(y1 - y0) < 0.3, "perni: l'arma mirando dritto resta dov'era")
	package.loaded["battaglia.perni"] = nil
	package.loaded["battaglia.scoria"] = nil
	scoria = require "battaglia.scoria"
end

-- i pezzi che le clip mostrano e tolgono, e le clip con l'arma in mano
do
	local A2 = require "battaglia.animazioni"
	local vecchie = { fermo = A2.fermo, fermo_arma = A2.fermo_arma }
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
	check(v.braccio_a.enabled and not v.braccio_a_img.enabled and v.manina_a.enabled
		and v.braccio_d_img.enabled and not v.manina_d.enabled and not v.ala.enabled
		and not v.coda[1][1].enabled and not v.coda[1][2].enabled and not v.testa.enabled and v.collo.enabled
		and not v.gamba_d.enabled and v.gamba_a.enabled and v.busto.enabled,
		"pezzi: la clip toglie braccio, testa (non la fiammella), gamba, ala e coda e mette la manina")
	local D = require "battaglia.diavoletto"
	local mx = (D.punti.spalle[1] + D.pezzi.braccio.x + 7) * v.k
	check(math.abs(v.manina_a.pos.x - mx) < 1e-6 and math.abs(math.rad(v.manina_a.euler.z) - 0.5) < 1e-6,
		"pezzi: la manina è libera, la clip la sposta e la gira")
	st2.turno = true
	for _ = 1, 3 do sc2.update(v, 1 / 60, st2) end
	check(v.ala.enabled and v.coda[1][1].enabled and not v.braccio_a.enabled and not v.mano_a.ossa[1].enabled
		and v.mano_a.pugno.enabled, "pezzi: di turno la clip con l'arma, il pugno sull'arma senza braccio")
	check(math.abs(math.rad(v.spalla.euler.z) - (-0.35 + 0.5)) < 0.05, "clip con l'arma: il canale arma gira l'arma a riposo")
	-- chi aspetta prende e posa l'arma a caso
	st2.turno = false
	v.arma_t = 1
	local presa, posata = false, false
	for _ = 1, 60 * 40 do
		sc2.update(v, 1 / 60, st2)
		if v.spalla.enabled then presa = true elseif presa then posata = true end
	end
	check(presa and posata, "attesa: chi non è di turno prende e posa l'arma")
	A2.fermo, A2.fermo_arma = vecchie.fermo, vecchie.fermo_arma
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
		for _ = 1, 3 do sc2.update(v, 1 / 60, st2) end
		return math.rad(v.spalla.euler.z)
	end
	local maglio0, missile0 = gira("mallet"), gira("missile")
	A2.fermo_arma_mallet = { durata = 1, ciclo = true, tracce = { arma = { 0, 1, 2 } } }
	local maglio, missile = gira("mallet"), gira("missile")
	check(maglio - maglio0 > 0.8 and math.abs(missile - missile0) < 0.05,
		"clip dell'arma: il Maglio usa fermo_arma_mallet, le altre fermo_arma")
	A2.fermo_arma_mallet = nil
	package.loaded["battaglia.scoria"] = nil
	scoria = require "battaglia.scoria"
	-- braccia libere: l'arma va nella mano del braccio davanti che pende,
	-- l'impugnatura sul pugno; niente braccia piegate sull'arma
	A2.fermo_arma_sword = { durata = 1, ciclo = true, tracce = { arma_libera = { 0, 1, 2 }, braccio_a = { 0, -0.8, 2 } } }
	package.loaded["battaglia.scoria"] = nil
	local sc3 = require "battaglia.scoria"
	local v = sc3.new(vec(1, 0.2, 0.3, 1))
	sc3.set_weapon(v, "sword")
	for _ = 1, 60 do sc3.update(v, 1 / 60, st2) end
	check(v.braccio_a.enabled and v.braccio_a_img.enabled and not v.mano_a.ossa[1].enabled and v.mano_a.pugno.enabled,
		"braccia libere: il braccio che pende tiene l'arma, niente braccia piegate")
	check(math.abs(v.spalla.pos.x - v.mano_a.pugno.pos.x) < 1e-6 and math.abs(v.spalla.pos.y - v.mano_a.pugno.pos.y) < 1e-6
		and math.abs(math.rad(v.mano_a.pugno.euler.z) - v.braccia[1]) < 1e-6,
		"braccia libere: l'arma è nel pugno e gira col braccio")
	sc3.update(v, 1 / 60, { x = 100, y = 50, facing = 1, grounded = true, moving = 0, turno = true, aim = 0.3 })
	check(v.mano_a.ossa[1].enabled and not v.braccio_a.enabled, "braccia libere: mirando le braccia tornano sull'arma")
	A2.fermo_arma_sword = nil
	package.loaded["battaglia.scoria"] = nil
	scoria = require "battaglia.scoria"
	local PR = require "battaglia.impugnature"
	for nome in pairs(require("battaglia.armi").armi) do
		check(PR[nome] ~= nil and #PR[nome] <= 2, nome .. ": ha le sue impugnature (al più due mani)")
	end
end

-- Pelli (battaglia/pelli.lua) ---------------------------------------------------

-- pelli finte: una testa nuova senza facce col colore della squadra, un elmo
-- sopra, una coda a segmenti, un braccio sull'arma nuovo (bordo e colore a parte)
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
PELLI.pelli.prova_corpo = { categoria = "corpo", pezzi = { omero = pz("o", "sostituisce"),
	omero_bordo = pz("ob", "sostituisce"), omero_dietro = pz("od", "sostituisce"),
	omero_dietro_bordo = pz("odb", "sostituisce") } }
local function immagini(da)
	local l = {}
	for i = da, #nodi do
		local n = nodi[i]
		if n.img then l[n.img] = (l[n.img] or 0) + 1 end
	end
	return l
end
check(immagini(1).omero_bordo and immagini(1).coda_1, "pelli: senza, il diavoletto di base")
local primo = #nodi + 1
local v = scoria.new(vec(1, 0.2, 0.3, 1), { "prova_elmo", "prova_testa", "prova_coda", "prova_corpo" })
local im = immagini(primo)
check(im.t == 1 and im.e == 1 and im.eb == 1 and not im.testa, "pelli: la testa sostituita, l'elmo sopra")
check(im.c1 == 1 and im.cb5 == 1 and not im.coda_1 and not im.coda_5_bordo
	and v.coda[1][1] ~= v.coda[1][2], "pelli: la coda nuova a segmenti, bordi e colori")
check(im.o == 1 and im.ob == 1 and im.od == 1 and im.odb == 1 and not im.omero_bordo and im.avambraccio_bordo == 2,
	"pelli: il braccio sull'arma nuovo, col suo bordo")
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
camera.salta(c, 100, 100, camera.tutta(c))
check(c.x == 960 and c.y == 540, "zoom mappa: si vede tutta la mappa, la camera non si sposta")
check(camera.tutta(c) == camera.LIVELLI[#camera.LIVELLI], "l'ultimo livello di zoom mostra tutta la mappa")

camera.salta(c, 640, 360, 2.2)
local px, py = camera.allo_schermo(c, 700, 400)
local wx, wy = camera.al_mondo(c, px, py)
check(math.abs(wx - 700) < 1e-9 and math.abs(wy - 400) < 1e-9, "da mondo a schermo e ritorno")
px, py = camera.allo_schermo(c, 640, 360)
check(px == 640 and py == 360, "il punto seguito sta al centro dello schermo")

camera.salta(c, 0, 0, 2.2)
px, py = camera.allo_schermo(c, 0, 0)
check(math.abs(px) < 1e-9 and math.abs(py) < 1e-9, "nell'angolo la camera non esce dalla mappa")

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

-- Tutorial a passi (battaglia/tutorial.lua) ------------------------------------------
do
	local tutorial = require "battaglia.tutorial"
	local t = tutorial.new()
	-- gioca input(tick) per al massimo n tick, passando gli eventi al tutorial
	local function gioca(g, n, input)
		for k = 1, n do
			g:step(input and input(k) or nil)
			for _, e in ipairs(g:pop_events()) do tutorial.evento(t, g, e) end
			if tutorial.fatto(t, g) then return true end
		end
		return false
	end
	local function spara(w, a) return { fire = { angle = a or math.rad(45), power = 0.7, weapon = w or "missile" } } end

	local g = tutorial.partita(t, 1)
	check(#g.order == 1 and g.robots[2] and math.abs(g.robots[2].x - g.robots[1].x) > 200,
		"tutorial: il bersaglio c'è ma non gioca")
	check(gioca(g, 600, function(k)
		if k <= 60 then return { right = true } end
		if k == 70 then return spara() end
	end), "tutorial 1: muoversi e sparare")

	tutorial.avanti(t)
	g = tutorial.partita(t, 1)
	check(not gioca(g, 2, function() return spara() end), "tutorial 2: sparare non basta")
	check(gioca(g, 900, function() if g.window > 0 then return { left = true } end end), "tutorial 2: al riparo dopo il colpo")

	tutorial.avanti(t)
	g = tutorial.partita(t, 1)
	check(math.abs(g.robots[2].x - g.robots[1].x) < 40, "tutorial 3: il bersaglio è vicino")
	check(gioca(g, 120, function(k) if k == 5 then return spara("sword", 0) end end), "tutorial 3: colpo di spada")

	tutorial.avanti(t)
	g = tutorial.partita(t, 1)
	check(gioca(g, 300, function(k)
		if k == 5 then return spara() end
		if k == 30 then return spara("sword", 0) end
	end), "tutorial 4: due attacchi nello stesso turno")

	tutorial.avanti(t)
	g = tutorial.partita(t, 1)
	check(g.robots[1].teleports_left == 0, "tutorial 5: si parte senza teletrasporti")
	check(gioca(g, 600, function(k)
		if k == 5 then return spara() end
		if k == 20 then return spara("teleport", math.rad(80)) end
	end), "tutorial 5: globo guadagnato e lanciato")

	tutorial.avanti(t)
	g = tutorial.partita(t, 1)
	tutorial.evento(t, g, { type = "sword_hit", robot = 1, target = 2 })
	check(not tutorial.fatto(t, g), "tutorial 6: il fendente da solo non è la combo")
	tutorial.evento(t, g, { type = "teleport", robot = 1 })
	tutorial.evento(t, g, { type = "sword_hit", robot = 1, target = 2 })
	check(tutorial.fatto(t, g), "tutorial 6: teletrasporto e fendente")
	check(not tutorial.avanti(t), "tutorial: sei passi")
end

if failures > 0 then
	print(failures .. " test falliti")
	os.exit(1)
end
print("tutti i test passati")
