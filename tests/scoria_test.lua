-- Test del personaggio (battaglia/scoria.lua) con un finto gui: crea i nodi,
-- passa per tutte le animazioni e controlla che le giunture abbiano valori
-- sensati e che i piedi restino a terra. Dalla radice del repository:
--   luajit tests/scoria_test.lua
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
	BLEND_ADD = 1, ADJUST_STRETCH = 2,
	new_box_node = nuovo,
	set_parent = function(n, p) n.parent = p end,
	set_position = function(n, v) n.pos = copia(v) end,
	set_euler = function(n, v) n.euler = copia(v) end,
	set_scale = function(n, v) n.scale = copia(v) end,
	set_enabled = function(n, on) n.enabled = on end,
	set_visible = function() end, set_texture = function() end, play_flipbook = function() end,
	set_blend_mode = function() end, set_color = function() end, set_adjust_mode = function() end,
	set_inherit_alpha = function() end,
}

local scoria = require "battaglia.scoria"
local RIG = require "battaglia.personaggio_rig"

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
	return x, y
end

local function finito(v) return v == v and v > -1e6 and v < 1e6 end
local function tutto_finito()
	for _, n in ipairs(nodi) do
		if not (finito(n.pos.x) and finito(n.pos.y) and finito(n.euler.z) and finito(n.scale.x)) then return false end
	end
	return true
end

-- altezza della suola di un piede sopra i piedi del rig
local function suola(s, lato)
	local _, y = mondo(s["caviglia_" .. lato], 0, -RIG.pezzi["caviglia_" .. lato].suola)
	return y
end

local s = scoria.new(vec(1, 0.3, 0.3, 1))
local st = { x = 0, y = 0, facing = 1, grounded = true, moving = 0 }
local dt = 1 / 60
local function passi(n, f)
	for i = 1, n do
		if f then f(i) end
		scoria.update(s, dt, st)
	end
end

passi(120)
check(tutto_finito(), "riposo: valori finiti")
check(math.abs(suola(s, "davanti") + 3) < 1.5 and math.abs(suola(s, "dietro") + 3) < 1.5,
	string.format("riposo: piedi a terra (%.2f, %.2f)", suola(s, "davanti"), suola(s, "dietro")))

-- camminata: un piede si alza, l'altro resta giù
local alto, basso = -1e9, 1e9
st.moving = 50
passi(90, function()
	local a, b = suola(s, "davanti"), suola(s, "dietro")
	alto, basso = math.max(alto, a, b), math.min(basso, math.min(a, b))
end)
check(tutto_finito(), "camminata: valori finiti")
check(alto > 2 and basso < 0, string.format("camminata: i piedi si alzano (%.1f) e tornano a terra (%.1f)", alto, basso))
st.moving = 0

-- salto e atterraggio
st.grounded = false
passi(30, function(i) st.y = st.y + 2 end)
passi(30, function(i) st.y = st.y - 2 end)
st.grounded = true
passi(60)
check(tutto_finito(), "salto e atterraggio: valori finiti")

-- mira e colpi con tutte le armi, girato dalle due parti
for _, w in ipairs({ "missile", "sword", "teleport", "punch", "grenade", "shards" }) do
	scoria.set_weapon(s, w)
	for _, face in ipairs({ 1, -1 }) do
		st.facing = face
		passi(40, function(i) st.aim = math.rad(205 - i * 6) end)
		st.aim = nil
		scoria.fire(s, w == "missile" and "missile" or (w == "shards" and "shards" or "throw"))
		passi(40)
	end
	check(tutto_finito(), "arma " .. w .. ": valori finiti")
end

-- la spada mirando punta esattamente dove dice la mira
scoria.set_weapon(s, "sword")
st.facing = 1
for _, deg in ipairs({ 205, 120, 45, -35 }) do
	st.aim = math.rad(deg)
	passi(60)
	local g = s.armi_dietro
	local x0, y0 = mondo(g, 0, 0)
	local x1, y1 = mondo(g, 10, 0)
	local a = math.deg(math.atan2(y1 - y0, x1 - x0))
	local d = (a - deg + 180) % 360 - 180
	check(math.abs(d) < 1, string.format("spada a %d°: la lama punta a %.1f°", deg, a))
end
st.aim = nil

-- espressioni, colpo, teletrasporto
for _, e in ipairs({ "mira", "paura", "poca_vita", "vittoria", "colpito", "neutro" }) do
	st.expression = e
	scoria.hit(s)
	passi(30)
	check(tutto_finito(), "espressione " .. e .. ": valori finiti")
end
scoria.teleport(s)
passi(30)
check(tutto_finito(), "teletrasporto: valori finiti")

-- morte: dopo un po' il personaggio si spegne, una nuova partita lo riaccende
scoria.die(s)
passi(90)
check(s.root.enabled == false, "morte: il personaggio sparisce")
scoria.set_enabled(s, true)
passi(10)
check(s.root.enabled and not s.morte, "nuova partita: il personaggio torna")

if failures > 0 then
	print(failures .. " test falliti")
	os.exit(1)
end
print("tutti i test passati")
