-- Test della Scoria (battaglia/scoria.lua) con un finto gui, e della
-- camera (battaglia/camera.lua). Dalla radice del repository:
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
	set_visible = function() end, set_color = function() end, set_adjust_mode = function() end,
	set_inherit_alpha = function() end, set_perimeter_vertices = function() end,
	set_texture = function() end, play_flipbook = function() end,
}

local game = require "sim.game"
local scoria = require "battaglia.scoria"
local camera = require "battaglia.camera"

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
local st = { x = 100, y = 50, facing = 1, grounded = true, moving = 0 }
for _ = 1, 60 do scoria.update(s, 1 / 60, st) end
check(tutto_finito(), "a riposo: valori finiti")

-- la mano è l'ultimo nodo dell'arma
local function mano(name)
	local m
	for _, n in ipairs(nodi) do
		if n.parent == s.armi[name] then m = n end
	end
	return m
end

-- l'arma gira attorno alla spalla e la mano la segue: dalla spalla, la mano
-- sta nella direzione della mira, girati a destra o a sinistra
for _, name in ipairs({ "missile", "sword" }) do
	scoria.set_weapon(s, name)
	for _, a in ipairs({ 0.4, -0.8, 2.3, math.pi - 0.2 }) do
		st.aim = a
		st.facing = math.cos(a) < 0 and -1 or 1
		for _ = 1, 30 do scoria.update(s, 1 / 60, st) end
		local sx, sy = mondo(s.spalla, 0, 0)
		local mx, my = mondo(mano(name), 0, 0)
		local d = angolo(math.atan2(my - sy, mx - sx) - a)
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
local indietro = false
for _ = 1, 4 do
	scoria.update(s, 1 / 60, st)
	local mx, my = mondo(mano("missile"), 0, 0)
	if (mx - sx) ^ 2 + (my - sy) ^ 2 < (mx0 - sx) ^ 2 + (my0 - sy) ^ 2 - 0.5 then indietro = true end
end
check(indietro, "rinculo: la mano torna indietro verso la spalla")
sx, sy = mondo(s.spalla, 0, 0)
local mx, my = mondo(mano("missile"), 0, 0)
check(math.abs(angolo(math.atan2(my - sy, mx - sx) - 0.6)) < 0.02, "rinculo: la mano resta sull'asse dell'arma")

st.aim = nil
for _, name in ipairs({ "missile", "sword", "teleport", "grenade", "shards", "punch" }) do
	scoria.set_weapon(s, name)
	for _ = 1, 10 do scoria.update(s, 1 / 60, st) end
end
check(tutto_finito(), "tutte le armi a riposo: valori finiti")

-- salto e atterraggio: schiaccia e allunga senza esplodere
st.grounded = false
for i = 1, 30 do st.y = 50 + i * 3; scoria.update(s, 1 / 60, st) end
for i = 1, 30 do st.y = 140 - i * 3; scoria.update(s, 1 / 60, st) end
st.grounded = true
for _ = 1, 30 do scoria.update(s, 1 / 120, st) end
check(tutto_finito(), "salto e atterraggio (anche a 120 Hz): valori finiti")

scoria.hit(s)
scoria.teleport(s)
for _ = 1, 30 do scoria.update(s, 1 / 60, st) end
check(tutto_finito(), "colpo e teletrasporto: valori finiti")

scoria.die(s)
for _ = 1, 60 do scoria.update(s, 1 / 60, st) end
check(not s.root.enabled, "morte: il corpo sparisce")
scoria.set_enabled(s, true)
check(s.root.enabled and not s.morte, "nuova partita: il corpo torna")
check(math.abs(game.ROBOT_H - s.h) < 1e-9, "il corpo è alto quanto quello della simulazione")

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

camera.cambia(c, 5)
check(camera.zoom(c) == 1, "rotella indietro: si ferma su tutta la mappa")
camera.cambia(c, -5)
check(camera.zoom(c) == camera.LIVELLI[1], "rotella avanti: si ferma sul più vicino")
camera.prossimo(c); camera.prossimo(c); camera.prossimo(c)
check(c.livello == 1, "il pulsante gira: vicino, medio, mappa, vicino")

if failures > 0 then
	print(failures .. " test falliti")
	os.exit(1)
end
print("tutti i test passati")
