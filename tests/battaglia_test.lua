-- Test del personaggio (battaglia/personaggio.lua) e della targa con nome e vita
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
	set_texture = function() end, play_flipbook = function() end,
	new_text_node = function(p, text) local n = nuovo(p); n.text = text; return n end,
	set_text = function(n, text) n.text = text end,
	set_size = function(n, v) n.size = copia(v) end,
	get_size = function(n) return n.size end,
	set_font = function() end, set_outline = function() end, set_pivot = function() end,
	set_slice9 = function() end, PIVOT_W = 3,
}

local game = require "sim.game"
local personaggio = require "battaglia.personaggio"
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

-- Personaggio --------------------------------------------------------------

local s = personaggio.new(vec(1, 0.2, 0.3, 1))
local st = { x = 100, y = 50, facing = 1, grounded = true, moving = 0 }
for _ = 1, 60 do personaggio.update(s, 1 / 60, st) end
check(tutto_finito(), "a riposo: valori finiti")

-- la mano è lo zero dell'arma, nel pugno del braccio davanti
local function mano(name) return s.armi[name] end

-- l'arma gira attorno alla spalla e la mano la segue: dalla spalla, la mano
-- sta nella direzione della mira, girati a destra o a sinistra
for _, name in ipairs({ "missile", "sword" }) do
	personaggio.set_weapon(s, name)
	for _, a in ipairs({ 0.4, -0.8, 2.3, math.pi - 0.2 }) do
		st.aim = a
		st.facing = math.cos(a) < 0 and -1 or 1
		for _ = 1, 30 do personaggio.update(s, 1 / 60, st) end
		local sx, sy = mondo(s.spalla, 0, 0)
		local mx, my = mondo(mano(name), 0, 0)
		local d = angolo(math.atan2(my - sy, mx - sx) - a)
		check(math.abs(d) < 0.02, string.format("%s mirando a %.1f: la mano è nella direzione della mira (scarto %.3f)", name, a, d))
	end
end

-- il rinculo sposta arma e mano lungo l'asse, senza staccarle dalla mira
personaggio.set_weapon(s, "missile")
st.aim, st.facing = 0.6, 1
for _ = 1, 30 do personaggio.update(s, 1 / 60, st) end
local sx, sy = mondo(s.spalla, 0, 0)
local mx0, my0 = mondo(mano("missile"), 0, 0)
personaggio.fire(s, "missile")
local indietro = false
for _ = 1, 4 do
	personaggio.update(s, 1 / 60, st)
	local mx, my = mondo(mano("missile"), 0, 0)
	if (mx - sx) ^ 2 + (my - sy) ^ 2 < (mx0 - sx) ^ 2 + (my0 - sy) ^ 2 - 0.5 then indietro = true end
end
check(indietro, "rinculo: la mano torna indietro verso la spalla")
sx, sy = mondo(s.spalla, 0, 0)
local mx, my = mondo(mano("missile"), 0, 0)
check(math.abs(angolo(math.atan2(my - sy, mx - sx) - 0.6)) < 0.02, "rinculo: la mano resta sull'asse dell'arma")

-- armi a due mani: il braccio dietro dalla sua spalla arriva alla seconda presa,
-- sull'asse dell'arma; con quelle a una mano resta nascosto
for _, name in ipairs({ "missile", "sword", "mallet" }) do
	personaggio.set_weapon(s, name)
	st.aim, st.facing = 0.3, 1
	for _ = 1, 30 do personaggio.update(s, 1 / 60, st) end
	local D = require "battaglia.diavolo"
	local fx, fy = mondo(s.spalla_dietro, D.braccio.presa * game.ROBOT_H / D.altezza, 0)
	local ax, ay = mondo(s.spalla, 0, 0)
	local d = math.abs((fx - ax) * math.sin(0.3) - (fy - ay) * math.cos(0.3))
	check(s.spalla_dietro.enabled and d < 0.05, string.format("%s: la mano dietro è sull'arma (a %.2f dall'asse)", name, d))
end
personaggio.set_weapon(s, "eagle")
personaggio.update(s, 1 / 60, st)
check(not s.spalla_dietro.enabled, "Tonante: il braccio dietro resta nascosto")

-- a terra il disegno scende sul terreno sotto il centro, al massimo un gradino
st.aim, st.y, st.suolo = nil, 50, 47
for _ = 1, 60 do personaggio.update(s, 1 / 60, st) end
check(math.abs(s.root.pos.y - 47) < 0.01, "piedi: il disegno poggia sul terreno sotto il centro")
st.suolo = 50 - game.MAX_CLIMB - 1
for _ = 1, 60 do personaggio.update(s, 1 / 60, st) end
check(math.abs(s.root.pos.y - 50) < 0.01, "piedi: più giù di un gradino resta dov'è")
st.suolo = nil

st.aim = nil
for _, name in ipairs({ "missile", "sword", "teleport", "grenade", "shards", "punch" }) do
	personaggio.set_weapon(s, name)
	for _ = 1, 10 do personaggio.update(s, 1 / 60, st) end
end
check(tutto_finito(), "tutte le armi a riposo: valori finiti")

-- salto e atterraggio
st.grounded = false
for i = 1, 30 do st.y = 50 + i * 3; personaggio.update(s, 1 / 60, st) end
for i = 1, 30 do st.y = 140 - i * 3; personaggio.update(s, 1 / 60, st) end
st.grounded = true
for _ = 1, 30 do personaggio.update(s, 1 / 120, st) end
check(tutto_finito(), "salto e atterraggio (anche a 120 Hz): valori finiti")

personaggio.hit(s)
personaggio.teleport(s)
for _ = 1, 30 do personaggio.update(s, 1 / 60, st) end
check(tutto_finito(), "colpo e teletrasporto: valori finiti")

personaggio.hit(s, 30)
personaggio.hit(s, -30)
for _ = 1, 10 do personaggio.update(s, 1 / 60, st) end
check(tutto_finito(), "colpi da destra e da sinistra: valori finiti")

personaggio.die(s)
personaggio.set_weapon(s, "sword")
check(not s.armi.sword.enabled, "morte: l'arma sparisce, anche cambiandola")
for _ = 1, 30 do personaggio.update(s, 1 / 60, st) end
check(tutto_finito() and s.root.enabled, "morte: il corpo c'è ancora")
for _ = 1, 120 do personaggio.update(s, 1 / 60, st) end
check(not s.root.enabled, "morte: poi il corpo sparisce")
personaggio.set_enabled(s, true)
check(s.root.enabled and not s.morte, "nuova partita: il corpo torna")
check(math.abs(game.ROBOT_H - s.h) < 1e-9, "il corpo è alto quanto quello della simulazione")

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

local c = camera.new(1280, 720)
camera.salta(c, 100, 100, 1)
check(c.x == 640 and c.y == 360, "zoom 1: si vede tutta la mappa, la camera non si sposta")

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
local a, b = camera.new(1280, 720), camera.new(1280, 720)
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
check(camera.zoom(c) == 1, "rotella indietro: si ferma su tutta la mappa")
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
