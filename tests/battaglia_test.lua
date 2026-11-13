-- Tests of the Scoria (battle/scoria.lua) and of the plate with name and
-- health (battle/plate.lua) with a fake gui, and of the camera
-- (battle/camera.lua). From the repository root:
--   luajit tests/battaglia_test.lua
package.path = "client/?.lua;" .. package.path

-- fake vmath and gui: every node remembers position, rotation, scale and parent
local function vec(x, y, z, w) return { x = x or 0, y = y or 0, z = z or 0, w = w } end
vmath = { vector3 = vec, vector4 = vec }
hash = function(s) return "#" .. s end
local nodes = {}
local fraction = 0
local ordering = 0
local function new_one(p, s)
	ordering = ordering + 1
	local n = { pos = vec(p.x, p.y), euler = vec(), scale = vec(1, 1, 1), size = s, enabled = true, ordine = ordering }
	nodes[#nodes + 1] = n
	return n
end
local function copy(v) return vec(v.x, v.y, v.z, v.w) end
gui = {
	ADJUST_STRETCH = 2,
	new_box_node = new_one, new_pie_node = new_one,
	set_parent = function(n, p) n.parent = p end,
	set_position = function(n, v) n.pos = copy(v) end,
	set_euler = function(n, v) n.euler = copy(v) end,
	set_scale = function(n, v) n.scale = copy(v) end,
	set_enabled = function(n, on) n.enabled = on end,
	set_visible = function(n, on) n.invisible = not on end, set_color = function() end, set_adjust_mode = function() end,
	set_inherit_alpha = function() end, set_perimeter_vertices = function() end, set_fill_angle = function() end, set_inner_radius = function() end,
	set_texture = function() end, play_flipbook = function(n, img) n.img = img end, set_material = function() end,
	new_text_node = function(p, text) local n = new_one(p); n.text = text; return n end,
	set_text = function(n, text) n.text = text end,
	get_text = function(n) return n.text end,
	get_font = function() return "titolo" end, get_font_resource = function() return "titolo" end,
	set_size = function(n, v) n.size = copy(v) end,
	get_size = function(n) return n.size end,
	set_font = function() end, set_outline = function() end, set_pivot = function() end, set_line_break = function() end,
	set_slice9 = function() end, PIVOT_W = 3, PIVOT_E = 7, PIVOT_S = 5, PIVOT_N = 1,
	set_outer_bounds = function() end, PIEBOUNDS_ELLIPSE = 1, ADJUST_FIT = 0,
	-- the order among siblings: move_above(n, r) puts it right above r, with nil on top of all
	move_above = function(n, r)
		if r then
			assert(n.parent == r.parent, "gui.move_above: i nodi devono avere lo stesso genitore")
			fraction = fraction + 1e-4; n.ordine = r.ordine + fraction
		else
			ordering = ordering + 1; n.ordine = ordering
		end
	end,
}

-- the text sizes: 20 wide per letter, 40 tall
resource = { get_text_metrics = function(_, txt) return { width = 20 * #txt, height = 40 } end }

local game = require "sim.game"
-- the pivots moved in the editor (battle/pivots.lua) are Sergio's data and
-- change: here the mechanics are tested with still pivots, and the tests that
-- move them set their own
package.loaded["battle.pivots"] = {}
local scoria = require "battle.scoria"
local camera = require "battle.camera"
local plate = require "battle.plate"

local failures = 0
local function check(cond, msg)
	if cond then
		print("ok   " .. msg)
	else
		print("FAIL " .. msg)
		failures = failures + 1
	end
end

-- position in the root's frame of a local point of node n
local function world(n, x, y)
	while n.parent do
		local a = math.rad(n.euler.z)
		x, y = x * n.scale.x, y * n.scale.y
		x, y = x * math.cos(a) - y * math.sin(a), x * math.sin(a) + y * math.cos(a)
		x, y = x + n.pos.x, y + n.pos.y
		n = n.parent
	end
	-- the root: scale (facing) and position
	x, y = x * n.scale.x, y * n.scale.y
	return x + n.pos.x, y + n.pos.y
end

local function is_finished(v) return v == v and v > -1e6 and v < 1e6 end
local function everything_done()
	for _, n in ipairs(nodes) do
		if not (is_finished(n.pos.x) and is_finished(n.pos.y) and is_finished(n.euler.z) and is_finished(n.scale.x)) then return false end
	end
	return true
end

local function angle_deg(a) return (a + math.pi) % (2 * math.pi) - math.pi end

-- Scoria -------------------------------------------------------------------

local s = scoria.new(vec(1, 0.2, 0.3, 1))
local st = { x = 100, y = 50, facing = 1, grounded = true, moving = 0, turno = true }
for _ = 1, 60 do scoria.update(s, 1 / 60, st) end
check(everything_done(), "at rest: finite values")

-- grip, pivot and shoulder of each weapon (battle/grips.lua)
local GRIPS = require "battle.grips"
local D0 = require "battle.devil"
-- whoever grips the weapon (the clip says who) holds it: the little hand sits
-- on the grip, the arm points toward the grip (it reaches it only if the grip
-- is as far from the shoulder as the arm is long, and clips can move the shoulder)
local function holds(v, name)
	local g = GRIPS[name]
	local gx, gy = world(v.armi[name], g.grip[1], g.grip[2])
	local who = v.posa.clip and v.posa.clip.held_by or "braccio_a"
	if who:find("^manina") then
		local mx, my = world(v[who], 0, 0)
		return math.abs(gx - mx) < 0.5 and math.abs(gy - my) < 0.5, who
	elseif who:find("^braccio") then
		local pz = D0.pieces[who == "braccio_a" and "braccio" or "braccio_dietro"]
		local jx, jy = world(v[who], 0, 0)
		local hx, hy = world(v[who], pz.x * v.k, (pz.y - pz.h / 2 + D0.pieces.pugno.h * 0.4) * v.k)
		return math.abs(angle_deg(math.atan2(hy - jy, hx - jx) - math.atan2(gy - jy, gx - jx))) < 0.02, who
	end
	return true, who
end
-- the weapon's direction in the world
local function weapon_facing(v, name)
	local x0, y0 = world(v.armi[name], 0, 0)
	local x1, y1 = world(v.armi[name], 1, 0)
	return math.atan2(y1 - y0, x1 - x0)
end

-- aiming, the front arm points where you aim and the weapon extends it: the
-- weapon goes in the aim direction, the grip in the hand, facing right or left
for _, name in ipairs({ "missile", "sword", "mallet" }) do
	scoria.set_weapon(s, name)
	for _, a in ipairs({ 0.4, -0.8, 2.3, math.pi - 0.2 }) do
		st.aim = a
		st.facing = math.cos(a) < 0 and -1 or 1
		for _ = 1, 30 do scoria.update(s, 1 / 60, st) end
		local d = angle_deg(weapon_facing(s, name) - a)
		check(math.abs(d) < 0.02, string.format("%s aiming at %.1f: the weapon points where you aim (off by %.3f)", name, a, d))
		local ok, who = holds(s, name)
		check(ok, string.format("%s aiming at %.1f: %s holds the grip", name, a, who))
	end
end

-- the recoil moves the weapon back along its axis, without leaving the aim
scoria.set_weapon(s, "missile")
st.aim, st.facing = 0.6, 1
for _ = 1, 30 do scoria.update(s, 1 / 60, st) end
local mx0, my0 = world(s.armi.missile, 0, 0)
scoria.fire(s, "missile")
scoria.update(s, 1 / 60, st)
local mx, my = world(s.armi.missile, 0, 0)
check((mx - mx0) ^ 2 + (my - my0) ^ 2 > 0.25, "recoil: the weapon goes back")
check(math.abs(angle_deg(math.atan2(my0 - my, mx0 - mx) - 0.6)) < 0.02, "recoil: the weapon moves along its axis")

st.aim = nil
-- in a fixed order: pairs changes order from one run to the next and, if the
-- last one were the Blade, the death check below wouldn't change it
local name_list = {}
for name in pairs(require("battle.weapons").weapons) do name_list[#name_list + 1] = name end
table.sort(name_list)
for _, name in ipairs(name_list) do
	check(s.armi[name] ~= nil, name .. ": the drawing is in the hand")
	scoria.set_weapon(s, name)
	for _ = 1, 10 do scoria.update(s, 1 / 60, st) end
end
check(everything_done(), "all weapons at rest: finite values")

-- jump and landing: the jump frames without blowing up
st.grounded = false
for i = 1, 30 do st.y = 50 + i * 3; scoria.update(s, 1 / 60, st) end
for i = 1, 30 do st.y = 140 - i * 3; scoria.update(s, 1 / 60, st) end
st.grounded = true
for _ = 1, 30 do scoria.update(s, 1 / 120, st) end
check(everything_done(), "jump and landing (also at 120 Hz): finite values")

scoria.hit(s)
for _ = 1, 30 do scoria.update(s, 1 / 60, st) end
check(everything_done(), "hit: finite values")

-- waiting: idle, and sooner or later a random skit that ends
st.turno = false
for _ = 1, 60 * 30 do scoria.update(s, 1 / 60, st) end
check(s.n_skits > 0, "waiting: at least one skit in 30 seconds")
check(everything_done(), "waiting and skits: finite values")
st.turno = true

scoria.hit(s, 30)
scoria.hit(s, -30)
for _ = 1, 10 do scoria.update(s, 1 / 60, st) end
check(everything_done(), "hits from the right and from the left: finite values")

scoria.die(s)
scoria.set_weapon(s, "sword")
check(not s.armi.sword.enabled, "death: the weapon vanishes, even when changing it")
for _ = 1, 30 do scoria.update(s, 1 / 60, st) end
check(everything_done() and s.root.enabled, "death: the body falls and is still there")
for _ = 1, 200 do scoria.update(s, 1 / 60, st) end
check(not s.root.enabled, "death: then the body vanishes")
scoria.set_enabled(s, true)
check(s.root.enabled and not s.morte, "new match: the body comes back")
check(math.abs(game.DISEGNO_H - s.h) < 1e-9, "the body is as tall as the drawing (DISEGNO_H)")

-- Poses (battle/pose.lua) and clips (battle/animations.lua) --------------

local pose = require "battle.pose"
local A = require "battle.animations"
local function near(a, b) return math.abs(a - b) < 1e-6 end
local clip = { duration = 1, loop = true, tracks = { testa = { 0, 0, 0, 0.5, 1, 1, 0.75, 2, 2 } },
	face = { 0.2, "testa_felice", 0.6, "testa_ko" } }
local tr = clip.tracks.testa
check(near(pose.value(tr, 0, 1, true), 0) and near(pose.value(tr, 0.5, 1, true), 1),
	"poses: on the keys the key's value")
check(near(pose.value(tr, 0.625, 1, true), 1.5), "poses: linear curve halfway")
check(near(pose.value(tr, 0.9, 1, true), 2), "poses: step curve holds the value")
local p = pose.new()
pose.add(p, clip, 3.5, 0.5)
check(near(p.testa, 0.5) and near(p.schiaccia, 1) and near(p.braccio_a, 0),
	"poses: looping, time wraps, the weight scales, missing channels stay neutral")
check(p.face_name == "testa_felice", "poses: the face steps")
pose.reset(p)
pose.add(p, clip, 0.1, 1)
check(p.face_name == "testa_ko", "poses: before the first face, looping, the last one")
local end_of = { duration = 1, loop = false, tracks = { corpo = { 0, 0, 0, 1, 2, 0 } } }
check(near(pose.value(end_of.tracks.corpo, 0.5, 1, false), 1) and near(pose.value(end_of.tracks.corpo, 1, 1, false), 2),
	"poses: a non-looping clip starts and arrives gently and stops at the end")
local name_list = {}
for _, c in ipairs(pose.CHANNELS) do name_list[c] = true end
local good_ones = true
for nome, c in pairs(A) do
	if not (c.duration > 0) then good_ones = false; print("     " .. nome .. ": duration") end
	for channel, tr in pairs(c.tracks) do
		if not name_list[channel] or #tr % 3 ~= 0 or #tr == 0 then good_ones = false; print("     " .. nome .. "." .. channel) end
		for k = 1, #tr - 3, 3 do
			if tr[k + 3] < tr[k] or tr[k] < 0 or tr[k + 3] > c.duration then good_ones = false; print("     " .. nome .. "." .. channel .. ": times") end
		end
	end
end
check(good_ones, "animations: known channels, keys in order within the duration")
for _, nome in ipairs({ "fermo", "corsa", "aria", "sale", "scende", "paracadute", "colpito", "vittoria",
	"sconfitta", "naso", "sbadiglio", "guarda_coda", "fermo_arma", "corsa_arma", "aria_arma", "sale_arma",
	"scende_arma", "mira" }) do
	check(A[nome] ~= nil, "animations: there is the clip " .. nome)
end
local A_fav = require "battle.animations_favilla"
for _, nome in ipairs({ "fermo", "corsa", "aria", "sale", "scende", "paracadute", "colpito", "vittoria",
	"sconfitta", "naso", "sbadiglio", "guarda_coda", "fermo_arma", "corsa_arma", "aria_arma", "sale_arma",
	"scende_arma", "mira" }) do
	check(A_fav[nome] ~= nil, "favilla animations: there is the clip " .. nome)
end
local rig_ap = scoria.new(vec(1, 0.2, 0.3, 1), { "apprendista" })
local rig_fav = scoria.new(vec(0.5, 0.8, 0.9, 1), { "favilla" })
check(rig_ap.personaggio == "apprendista" and rig_ap.A == A, "scoria: apprendista uses default animations")
check(rig_fav.personaggio == "favilla" and rig_fav.A == A_fav, "scoria: favilla uses character-specific animations")

-- the pieces' forward-back and up-down moves
do
	local A2 = require "battle.animations"
	local old_f = A2.fermo
	A2.fermo = { duration = 1, loop = true, tracks = { testa_x = { 0, 10, 0 }, braccio_d_y = { 0, -8, 0 }, coda_x = { 0, 5, 0 } } }
	local v = scoria.new(vec(1, 0.2, 0.3, 1))
	local st2 = { x = 100, y = 50, facing = 1, grounded = true, moving = 0 }
	for _ = 1, 5 do scoria.update(v, 1 / 60, st2) end
	local D = require "battle.devil"
	local k = v.k
	check(math.abs(v.collo.pos.x - (D.points.collo[1] + 10) * k) < 1e-6
		and math.abs(v.braccio_d.pos.y - (D.points.spalle[2] - 8) * k) < 1e-6
		and math.abs(v.coda[1][2].pos.x - (D.points.coda[1] + 5) * k) < 1e-6,
		"poses: head, arm and tail move with the x and y channels")
	A2.fermo = old_f
end

-- the pivots moved in the editor (battle/pivots.lua): the joint moves, the
-- pieces the opposite way, so at rest they stay where they are
do
	local D = require "battle.devil"
	package.loaded["battle.pivots"] = { braccio = { 3, -2 }, testa = { 1, 4 } }
	package.loaded["battle.scoria"] = nil
	local sc2 = require "battle.scoria"
	local v = sc2.new(vec(1, 0.2, 0.3, 1))
	sc2.update(v, 1 / 60, { x = 100, y = 50, facing = 1, grounded = true, moving = 0 })
	local k = v.k
	local arm, head
	for _, n in ipairs(nodes) do
		if n.parent == v.braccio_a and n.img == "braccio" then arm = n end
		if n.parent == v.testa and n.img == "testa" then head = n end
	end
	check(arm and math.abs(arm.pos.x - (D.pieces.braccio.x - 3) * k) < 1e-6
		and math.abs(arm.pos.y - (D.pieces.braccio.y + 2) * k) < 1e-6
		and math.abs(v.braccio_a.pos.x - (D.points.spalle[1] + 3 + v.posa.braccio_a_x) * k) < 1e-6,
		"pivots: the arm turns around the moved pivot and at rest stays where it was")
	check(head and math.abs(head.pos.y - (D.pieces.testa.y - 4) * k) < 1e-6,
		"pivots: the head stays where it was")
	package.loaded["battle.pivots"] = {}
	package.loaded["battle.scoria"] = nil
	scoria = require "battle.scoria"
end

-- the pivots of torso, tail and little hands: at rest the pieces stay where
-- they are, the torso turns around its pivot
do
	local function pieces_of(pivots)
		package.loaded["battle.pivots"] = pivots
		package.loaded["battle.scoria"] = nil
		local sc2 = require "battle.scoria"
		local from_pt = #nodes
		local v = sc2.new(vec(1, 0.2, 0.3, 1))
		sc2.update(v, 1 / 60, { x = 100, y = 50, facing = 1, grounded = true, moving = 0 })
		local found_ones = {}
		for i = from_pt + 1, #nodes do
			local n = nodes[i]
			if n.img and not found_ones[n.img] then found_ones[n.img] = n end
		end
		return v, found_ones
	end
	-- at rest: a still clip, so a turned torso in the real fermo doesn't count
	local A2 = require "battle.animations"
	local old_fermo = A2.fermo
	A2.fermo = { duration = 1, loop = true, tracks = {} }
	local v0, p0 = pieces_of({})
	local v1, p1 = pieces_of({ busto = { 3, 20 }, coda = { 2, -3 }, pugno = { 1, 1 } })
	A2.fermo = old_fermo
	local still_ones = true
	for _, img in ipairs({ "busto", "coda_1", "coda_3", "pugno", "testa", "gamba" }) do
		local x0, y0 = world(p0[img], 0, 0)
		local x1, y1 = world(p1[img], 0, 0)
		if not (p0[img] and math.abs(x0 - x1) < 0.5 and math.abs(y0 - y1) < 0.5) then still_ones = false; print(img, x0, y0, x1, y1) end
	end
	check(still_ones, "pivots: torso, tail and little hands moved, at rest the pieces stay where they were")
	local px, py = world(v1.busto, 0, 0)
	local PT = D0.points
	local gx, gy = world(v1.forma, (PT.bacino[1] + 3 + v1.posa.busto_x) * v1.k, (PT.bacino[2] + 20 + v1.posa.busto_y) * v1.k)
	check(math.abs(px - gx) < 1e-6 and math.abs(py - gy) < 1e-6, "pivots: the torso turns around its pivot")
	package.loaded["battle.pivots"] = {}
	package.loaded["battle.scoria"] = nil
	scoria = require "battle.scoria"
end

-- the front arm's pivot moved: the weapon stays in the hand (with an aim that
-- moves nothing and the front arm gripping)
do
	local A2 = require "battle.animations"
	local old_f = A2.mira_missile
	A2.mira_missile = { duration = 1, loop = true, tracks = {} }
	-- a grip as far from the shoulder as the arm is long (the real one is moved
	-- by Sergio in the editor)
	local real_grip = GRIPS.missile
	GRIPS.missile = { grip = { 2.4, -4 }, pivot = { -6.9, -4 }, shoulder = { 32, 110 } }
	package.loaded["battle.pivots"] = { braccio = { 3, -2 } }
	package.loaded["battle.scoria"] = nil
	local sc2 = require "battle.scoria"
	local v = sc2.new(vec(1, 0.2, 0.3, 1))
	sc2.set_weapon(v, "missile")
	for _ = 1, 30 do sc2.update(v, 1 / 60, { x = 100, y = 50, facing = 1, grounded = true, moving = 0, turno = true, aim = 0.3 }) end
	local g = GRIPS.missile
	local gx, gy = world(v.armi.missile, g.grip[1], g.grip[2])
	local px, py = world(v.braccio_a, 0, 0)
	local b, pu = D0.pieces.braccio, D0.pieces.pugno
	local hx, hy = world(v.braccio_a, (b.x - 3) * v.k, (b.y + 2 - b.h / 2 + pu.h * 0.4) * v.k)
	check(math.abs(gx - hx) < 0.5 and math.abs(gy - hy) < 0.5 and px ~= gx, "pivots: with the arm's pivot moved the weapon stays in the hand")
	A2.mira_missile = old_f
	GRIPS.missile = real_grip
	package.loaded["battle.pivots"] = {}
	package.loaded["battle.scoria"] = nil
	scoria = require "battle.scoria"
end

-- the pieces the clips show and remove, and the clips with the weapon in hand
do
	local A2 = require "battle.animations"
	local old_fs = { fermo = A2.fermo, fermo_arma = A2.fermo_arma, fermo_arma_missile = A2.fermo_arma_missile }
	A2.fermo_arma_missile = nil
	A2.fermo = { duration = 1, loop = true, tracks = { mostra_braccio_a = { 0, 0, 2 }, mostra_manina_a = { 0, 1, 2 },
		manina_a_x = { 0, 7, 2 }, manina_a = { 0, 0.5, 2 }, mostra_ala = { 0, 0, 2 }, mostra_coda = { 0, 0, 2 },
		mostra_testa = { 0, 0, 2 }, mostra_gamba_d = { 0, 0, 2 } } }
	A2.fermo_arma = { duration = 1, loop = true, tracks = { mostra_braccio_a = { 0, 0, 2 }, arma = { 0, 0.5, 2 } } }
	package.loaded["battle.scoria"] = nil
	local sc2 = require "battle.scoria"
	local v = sc2.new(vec(1, 0.2, 0.3, 1))
	local st2 = { x = 100, y = 50, facing = 1, grounded = true, moving = 0, turno = false }
	v.weapon_t = 100
	for _ = 1, 3 do sc2.update(v, 1 / 60, st2) end
	check(not v.braccio_a.enabled and v.manina_a.enabled
		and v.braccio_d.enabled and not v.manina_d.enabled and not v.ala.enabled
		and not v.coda[1][1].enabled and not v.coda[1][2].enabled and not v.testa.enabled and v.collo.enabled
		and not v.gamba_d.enabled and v.gamba_a.enabled and v.busto.enabled,
		"pieces: the clip removes arm, head, leg, wing and tail and adds the little hand")
	local D = require "battle.devil"
	local mx = (D.points.spalle[1] + D.pieces.braccio.x + 7) * v.k
	check(math.abs(v.manina_a.pos.x - mx) < 1e-6 and math.abs(math.rad(v.manina_a.euler.z) - 0.5) < 1e-6,
		"pieces: the little hand is free, the clip moves and turns it")
	st2.turno = true
	for _ = 1, 30 do sc2.update(v, 1 / 60, st2) end
	check(v.ala.enabled and v.coda[1][1].enabled and not v.braccio_a.enabled and v.presa.enabled,
		"pieces: on its turn the clip with the weapon, the weapon without the arm")
	check(math.abs(math.rad(v.giro.euler.z) - (-0.35 + 0.5)) < 0.05,
		"clip with the weapon: the arma channel turns the weapon around the pivot")
	-- whoever waits randomly takes and puts down the weapon
	st2.turno = false
	v.weapon_t = 1
	local grip, posed = false, false
	for _ = 1, 60 * 40 do
		sc2.update(v, 1 / 60, st2)
		if v.presa.enabled then grip = true elseif grip then posed = true end
	end
	check(grip and posed, "waiting: whoever's turn it isn't takes and puts down the weapon")
	A2.fermo, A2.fermo_arma, A2.fermo_arma_missile = old_fs.fermo, old_fs.fermo_arma, old_fs.fermo_arma_missile
	package.loaded["battle.scoria"] = nil
	scoria = require "battle.scoria"
end

-- the clips for one weapon only (fermo_arma_mallet) and each weapon's grips
do
	local A2 = require "battle.animations"
	local st2 = { x = 100, y = 50, facing = 1, grounded = true, moving = 0, turno = true }
	local function turn_around(nome)
		package.loaded["battle.scoria"] = nil
		local sc2 = require "battle.scoria"
		local v = sc2.new(vec(1, 0.2, 0.3, 1))
		sc2.set_weapon(v, nome)
		for _ = 1, 30 do sc2.update(v, 1 / 60, st2) end
		return math.rad(v.giro.euler.z)
	end
	-- two Mallet clips one radian apart: the Mallet follows them, the Missile doesn't
	A2.fermo_arma_mallet = { duration = 1, loop = true, tracks = { arma = { 0, 0, 2 } } }
	local mallet0, missile0 = turn_around("mallet"), turn_around("missile")
	A2.fermo_arma_mallet = { duration = 1, loop = true, tracks = { arma = { 0, 1, 2 } } }
	local mallet, missile = turn_around("mallet"), turn_around("missile")
	check(math.abs(mallet - mallet0 - 1) < 0.05 and math.abs(missile - missile0) < 0.05,
		"weapon clip: the Mallet uses fermo_arma_mallet, the others fermo_arma")
	A2.fermo_arma_mallet = nil
	package.loaded["battle.scoria"] = nil
	scoria = require "battle.scoria"
	-- the weapon is a piece like the others: the clip removes it (mostra_arma)
	A2.fermo_arma_sword = { duration = 1, loop = true, tracks = { mostra_arma = { 0, 0, 2 } } }
	package.loaded["battle.scoria"] = nil
	local sc3 = require "battle.scoria"
	local v = sc3.new(vec(1, 0.2, 0.3, 1))
	sc3.set_weapon(v, "sword")
	for _ = 1, 3 do sc3.update(v, 1 / 60, st2) end
	check(not v.presa.enabled and v.braccio_a.enabled, "pieces: the clip removes the weapon, the arm stays")
	A2.fermo_arma_sword = nil
	package.loaded["battle.scoria"] = nil
	scoria = require "battle.scoria"
	local PR = require "battle.grips"
	for nome in pairs(require("battle.weapons").weapons) do
		local g = PR[nome]
		check(g ~= nil and #g.grip == 2 and #g.pivot == 2 and #g.shoulder == 2, nome .. ": has grip, pivot and shoulder")
	end

	-- the clip picks who grips the weapon; the weapon turns around the pivot,
	-- which sits on the weapon's shoulder (plus the clip's arma_x and arma_y)
	local function try_it(traces, grips, levels)
		A2.fermo_arma_sword = { duration = 1, loop = true, tracks = traces, held_by = grips, layers = levels }
		package.loaded["battle.scoria"] = nil
		local sc = require "battle.scoria"
		local v = sc.new(vec(1, 0.2, 0.3, 1))
		sc.set_weapon(v, "sword")
		for _ = 1, 60 do sc.update(v, 1 / 60, st2) end
		v.x[1], v.x[2] = 1, 0
		sc.update(v, 0, st2)
		return v
	end
	local g = PR.sword
	local function neighbors(ax, ay, bx, by) return math.abs(ax - bx) < 0.3 and math.abs(ay - by) < 0.3 end
	local function pivot(v) return world(v.armi.sword, g.pivot[1], g.pivot[2]) end
	local v1 = try_it({ arma = { 0, 0.3, 2 } }, "manina_d")
	local mx, my = world(v1.manina_d, 0, 0)
	check(neighbors(mx, my, world(v1.armi.sword, g.grip[1], g.grip[2])), "back little hand grips: the little hand sits on the grip")
	local v2 = try_it({ arma = { 0, 1.2, 2 } }, "manina_d")
	local p1x, p1y = pivot(v1)
	local p2x, p2y = pivot(v2)
	check(neighbors(p1x, p1y, p2x, p2y), "pivot: turning the weapon the pivot stays still")
	local sx, sy = world(v2.forma, g.shoulder[1] * v2.k, g.shoulder[2] * v2.k)
	check(neighbors(p2x, p2y, sx, sy), "pivot: it sits on the weapon's shoulder")
	local v3 = try_it({ arma_x = { 0, 10, 2 } }, "manina_d")
	local p3x, p3y = pivot(v3)
	sx, sy = world(v3.forma, (g.shoulder[1] + 10) * v3.k, g.shoulder[2] * v3.k)
	check(neighbors(p3x, p3y, sx, sy), "pivot: arma_x moves it")
	-- the back arm turns toward the grip (it reaches it if the grip is as far
	-- from its shoulder as the arm is long)
	local v4 = try_it({}, "braccio_d")
	local b, pu = D0.pieces.braccio_dietro, D0.pieces.pugno
	local jx, jy = world(v4.braccio_d, 0, 0)
	local hx, hy = world(v4.braccio_d, b.x * v4.k, (b.y - b.h / 2 + pu.h * 0.4) * v4.k)
	local gx, gy = world(v4.armi.sword, g.grip[1], g.grip[2])
	check(math.abs(angle_deg(math.atan2(hy - jy, hx - jx) - math.atan2(gy - jy, gx - jx))) < 0.01,
		"back arm grips: the arm points toward the grip")
	-- the clip's layers: the front arm under the torso, the weapon at the back
	local v5 = try_it({}, nil, { "arma", "coda", "ala", "braccio_d", "manina_d", "gamba_d", "gamba_a", "braccio_a",
		"busto", "testa", "manina_a" })
	check(v5.presa.ordine < v5.coda[1][1].ordine and v5.braccio_a.ordine < v5.busto.ordine
		and v5.busto.ordine < v5.collo.ordine, "layers: the clip picks what is in front")
	A2.fermo_arma_sword = nil
	package.loaded["battle.scoria"] = nil
	scoria = require "battle.scoria"
end

-- Skins (battle/skins.lua) ---------------------------------------------------

-- fake skins: a new head without faces with the team color, a helmet on top,
-- a segmented tail, new arms
local SKINS = require "battle.skins"
local function pz(img, mode, tint) return { img = img, tint = tint, x = 1, y = 2, w = 30, h = 40, mode = mode } end
SKINS.skins.prova_testa = { category = "testa", pieces = { testa = pz("t", "replace", "t_tinta") } }
SKINS.skins.prova_elmo = { category = "elmo", pieces = { testa = pz("e", "over"), busto = pz("eb", "over") } }
local coda = {}
for i = 1, 5 do
	coda["coda_" .. i] = pz("c" .. i, "replace")
	coda["coda_" .. i .. "_bordo"] = pz("cb" .. i, "replace")
end
SKINS.skins.prova_coda = { category = "coda", pieces = coda, tail = { 11, 12, 13, 14, 15 },
	tail_rest = { 2.5, 2.4, 2.3, 2.2, 2.1 }, tail_root = { 3, -4 } }
SKINS.skins.prova_corpo = { category = "corpo", pieces = { braccio = pz("br", "replace"),
	braccio_dietro = pz("bd", "replace") } }
local function images(from_pt)
	local l = {}
	for i = from_pt, #nodes do
		local n = nodes[i]
		if n.img then l[n.img] = (l[n.img] or 0) + 1 end
	end
	return l
end
check(images(1).braccio and images(1).coda_1, "skins: without them, the base devil")
local first = #nodes + 1
local v = scoria.new(vec(1, 0.2, 0.3, 1), { "prova_elmo", "prova_testa", "prova_coda", "prova_corpo" })
local im = images(first)
check(im.t == 1 and im.e == 1 and im.eb == 1 and not im.testa, "skins: the head replaced, the helmet on top")
check(im.c1 == 1 and im.cb5 == 1 and not im.coda_1 and not im.coda_5_bordo
	and v.coda[1][1] ~= v.coda[1][2], "skins: the new segmented tail, borders and colors")
check(v.tail_shape.l[1] == 11 and v.tail_shape.riposo[5] == 2.1 and v.tail_shape.radice[2] == -4,
	"skins: the new tail brings its lengths, rest angles and root")
local ap = scoria.new(vec(1, 0.2, 0.3, 1), { "apprendista" })
check(ap.tail_shape.l == SKINS.skins.apprendista.tail and ap.tail_shape.riposo == SKINS.skins.apprendista.tail_rest,
	"skins: the apprentice's tail has its own shape, not the base one")
check(im.br == 1 and im.bd == 1 and not im.braccio and not im.braccio_dietro, "skins: the new arms, one per side")
check(v.teste[2].parent == v.testa and v.teste[1].img == "t" and v.teste[2].img == "e", "skins: the helmet sits on the head")
check(v.heads_t[1].enabled and v.heads_t[1].img == "t_tinta" and not v.heads_t[2].enabled,
	"skins: the team color on the new head, under the helmet")
st = { x = 100, y = 50, facing = 1, grounded = true, moving = 0, turno = true }
for _ = 1, 30 do scoria.update(v, 1 / 60, st) end
scoria.hit(v, 1)
for _ = 1, 10 do scoria.update(v, 1 / 60, st) end
check(v.faccia == "testa_colpita" and v.teste[1].img == "t" and v.teste[2].enabled and v.teste[2].img == "e",
	"skins: hit, the new head also makes the hit face, the helmet stays")
scoria.die(v)
for _ = 1, 60 do scoria.update(v, 1 / 60, st) end
check(everything_done(), "skins: animated, finite values")
for nome in pairs(SKINS.skins) do
	if nome:sub(1, 6) == "prova_" then SKINS.skins[nome] = nil end
end

-- Plate ------------------------------------------------------------------------

local first = #nodes + 1
local tt = plate.create({ vec(1, 0.2, 0.3, 1), vec(0.2, 0.5, 1, 1) }, { "Rosso", "Blu" })
local first_text, last_shape = math.huge, 0
for k = first, #nodes do
	if nodes[k].text then first_text = math.min(first_text, k)
	elseif not nodes[k].invisible then last_shape = k end
end
check(last_shape < first_text, "plates: first all the bars, then all the texts (two draw calls)")
local t = tt[1]
plate.hp(t, 100, 100)
plate.update(t, 1 / 60, 0, 0, 1)
local full_f = t.full.size.x
plate.hp(t, 60, 100)
plate.update(t, 1 / 60, 0, 0, 1)
check(t.numero.text == "60", "plate: the number is the health")
check(math.abs(t.full.size.x - full_f * 0.6) < 0.5, "plate: health drops at once")
check(math.abs(t.trail.size.x - full_f) < 0.5, "plate: the lost piece stays a moment")
for _ = 1, 120 do plate.update(t, 1 / 60, 0, 0, 1) end
check(math.abs(t.trail.size.x - t.full.size.x) < 0.5, "plate: then it wears down to the health")
plate.hp(t, 50, 100)
for _ = 1, 30 do plate.update(t, 1 / 60, 0, 0, 1) end
plate.hp(t, 30, 100)
plate.update(t, 1 / 60, 0, 0, 1)
check(math.abs(t.trail.size.x - full_f * 0.6) < 0.5, "plate: consecutive hits widen the white piece")
for _ = 1, 120 do plate.update(t, 1 / 60, 0, 0, 1) end
plate.hp(t, 60, 100)
plate.hp(t, 60, 100, 20)
plate.update(t, 1 / 60, 0, 0, 1)
check(t.scudo.enabled and math.abs(t.scudo.pos.x - t.full.pos.x - t.full.size.x) < 0.5,
	"plate: the shield starts where health ends")
plate.hp(t, 100, 100, 50)
plate.update(t, 1 / 60, 0, 0, 1)
check(t.full.size.x + t.scudo.size.x <= full_f + 0.5, "plate: health plus shield fit in the frame")
plate.hp(t, 0, 100)
plate.update(t, 1 / 60, 0, 0, 1)
check(not t.full.enabled and everything_done(), "plate: at zero health vanishes, finite values")

-- Camera -----------------------------------------------------------------------

local c = camera.new(1280, 720, 1920, 1080)
-- the continuous zoom: 0 the farthest zoom (the whole play space), 1 NEAR
camera.drag(c, 0)
check(math.abs(camera.zoom(c) - camera.whole(c)) < 1e-9, "zoom at 0: the whole play space")
camera.drag(c, 1)
check(math.abs(camera.zoom(c) - camera.NEAR) < 1e-9, "zoom at 1: the nearest")
camera.drag(c, 0.5)
local z5 = camera.zoom(c)
check(z5 > camera.whole(c) and z5 < camera.NEAR, "zoom at half: in between")
camera.step(c, 0.1)
check(camera.zoom(c) > z5, "a step forward zooms in")
camera.drag(c, 7)
check(c.f == 1, "the zoom doesn't go past the nearest")
camera.level(c, 2)
check(math.abs(camera.zoom(c) - 1) < 1e-9, "the old MEDIO level is zoom 1")
camera.drag(c, 0.6)
camera.toggle(c)
check(c.f == 0, "a tap on the button: the farthest zoom")
camera.toggle(c)
check(math.abs(c.f - 0.6) < 1e-9, "another tap: back to the zoom from before")
camera.widen(c, 3)
check(c.f == 0, "a mission that wants to see everything widens the zoom")

-- the play space measured on the terrain: the floor under a platform counts
-- too, and above the highest one it leaves the room asked for
do
	local terrain = require("sim.terrain").new(100, 60, 3)
	for cx = 0, 99 do terrain:set(cx, 9, 1) end       -- the floor: surface at y 30
	for cx = 20, 79 do terrain:set(cx, 39, 1) end     -- a platform above: at y 120
	local m = camera.new(1280, 720, 300, 180)
	camera.from_terrain(m, terrain, 50)
	check(m.space and m.space.y0 < 30 and m.space.y0 > 10, "the space starts below the lowest floor")
	check(math.abs(m.space.y1 - 170) < 1e-9, "and reaches the room asked for above the highest platform")
end

-- the play space: at the farthest zoom it all fits between the HUD at the
-- bottom, the one at the top and the sides, and no character is in the center
camera.space(c, 0, 230, 1920, 960)
check(camera.whole(c) > camera.whole(c, true), "the play space is closer than the whole map")
camera.drag(c, 0)
camera.jump(c, 300, 300, camera.zoom(c))
for _ = 1, 600 do camera.follow(c, 1 / 60, 300, 300, camera.zoom(c)) end
local sx0, bottom = camera.to_screen(c, 0, 230)
local sx1, top = camera.to_screen(c, 1920, 960)
check(sx0 >= camera.LATO - 0.5 and sx1 <= 1280 - camera.LATO + 0.5 and bottom >= camera.BELOW - 0.5
	and top <= 720 - camera.ABOVE + 0.5, "farthest zoom: the whole play space fits between the HUD")
check(math.abs(sx0 + sx1 - 1280) < 1, "farthest zoom: the play space in the center, not the character")
-- at the farthest zoom a character in a crater below the play space stays on screen
for _ = 1, 600 do camera.follow(c, 1 / 60, 900, 120, camera.zoom(c)) end
local _, fell = camera.to_screen(c, 900, 120)
check(fell >= camera.BELOW - 0.5, "farthest zoom: whoever is below the play space doesn't end up under the HUD")

camera.drag(c, 1)
camera.jump(c, 640, 360, 2.2)
local px, py = camera.to_screen(c, 700, 400)
local wx, wy = camera.to_world(c, px, py)
check(math.abs(wx - 700) < 1e-9 and math.abs(wy - 400) < 1e-9, "from world to screen and back")
px, py = camera.to_screen(c, 640, 360)
check(px == 640 and py == 360, "the followed point is at the center of the screen")
-- even in the corner of the map the character stays in the center (the background shows beyond it)
for _ = 1, 600 do camera.follow(c, 1 / 60, 0, 0, 2.2) end
px, py = camera.to_screen(c, 0, 0)
check(math.abs(px - 640) < 0.5 and math.abs(py - 360) < 0.5, "in the corner the character stays in the center")

-- 20:9 phone (ui/screen.lua): the real screen goes from x = -160 to 1440
local l = camera.new(1280, 720, 1920, 1080)
camera.viewport(l, -160, 0, 1440, 720)
camera.jump(l, 1000, 500, 1)
px, py = camera.to_screen(l, 1000, 500)
check(px == 640 and py == 360, "wide screen: the followed point is in the center")
camera.space(l, 0, 230, 1920, 960)
check(camera.whole(l) > camera.whole(c), "wide screen: the farthest zoom is closer")
-- 4:3 tablet: the real screen goes from y = -120 to 840: the width decides
local t43 = camera.new(1280, 720, 1920, 1080)
camera.viewport(t43, 0, -120, 1280, 840)
check(math.abs(camera.whole(t43, true) - (1280 - 2 * camera.LATO) / 1920) < 1e-9,
	"tablet: the whole map as wide as the screen minus the sides")

-- following doesn't depend on the screen's frame rate
local a, b = camera.new(1280, 720, 1920, 1080), camera.new(1280, 720, 1920, 1080)
camera.jump(a, 400, 300, 2.2)
camera.jump(b, 400, 300, 2.2)
for _ = 1, 30 do camera.follow(a, 1 / 60, 800, 420, 2.2) end
for _ = 1, 60 do camera.follow(b, 1 / 120, 800, 420, 2.2) end
check(math.abs(a.x - b.x) < 0.01 and math.abs(a.y - b.y) < 0.01,
	string.format("at 60 and 120 Hz the camera reaches the same point (%.2f, %.2f)", a.x - b.x, a.y - b.y))
for _ = 1, 300 do camera.follow(a, 1 / 60, 800, 420, 1.5) end
check(math.abs(a.x - 800) < 0.5 and math.abs(a.s - 1.5) < 0.01, "the camera reaches the point and the zoom")

-- framing the shooter and the shot: close up both stay on screen (above the
-- HUD) while the shot flies away, and when they are close the zoom doesn't change
local function inside(cam, x, y)
	local sx, sy = camera.to_screen(cam, x, y)
	return sx >= 0 and sx <= cam.w and sy >= 150 and sy <= cam.h
end
local q = camera.new(1280, 720, 1920, 1080)
camera.jump(q, 300, 400, 2.2)
local all_inside = true
for i = 1, 90 do
	camera.frame_on(q, 1 / 60, 300, 400, 300 + i * 16, 400 + i * 5, 2.2)
	all_inside = all_inside and inside(q, 300, 400) and inside(q, 300 + i * 16, 400 + i * 5)
end
check(all_inside, "framing: shooter and shot always stay on screen")
check(q.s < 2.2 and q.s >= camera.whole(q), "framing: it zooms out, but not beyond the farthest zoom")
for _ = 1, 600 do camera.frame_on(q, 1 / 60, 300, 400, 330, 410, 2.2) end
check(math.abs(q.s - 2.2) < 0.01, "framing: with the shot close it goes back to the chosen zoom")
local q2 = camera.new(1280, 720, 1920, 1080)
camera.jump(q2, 300, 400, 2.2)
for _ = 1, 60 do camera.frame_on(q2, 1 / 60, 300, 400, 1700, 900, 2.2) end
local q3 = camera.new(1280, 720, 1920, 1080)
camera.jump(q3, 300, 400, 2.2)
for _ = 1, 120 do camera.frame_on(q3, 1 / 120, 300, 400, 1700, 900, 2.2) end
check(math.abs(q2.s - q3.s) < 0.01 and math.abs(q2.x - q3.x) < 0.5,
	"framing: the same at 60 and 120 Hz")

-- the shake: starts in the hit direction, is the same at 60 and 120 Hz and dies out
camera.shake(a, 1, 0, 20)
camera.shake(b, 1, 0, 20)
local ox = camera.shake_frame(a, 0)
check(math.abs(ox - 20) < 1e-9, "shake: the screen starts pushed in the hit direction")
for _ = 1, 6 do ox = camera.shake_frame(a, 1 / 60) end
local ox2
for _ = 1, 12 do ox2 = camera.shake_frame(b, 1 / 120) end
check(math.abs(ox - ox2) < 1e-6, "shake: the same at 60 and 120 Hz")
camera.shake(a, 0, 1, 5)
check(a.sc_x == 1, "shake: a weaker one doesn't cancel the running one")
for _ = 1, 60 do ox = camera.shake_frame(a, 1 / 60) end
check(ox == 0, "shake: after a moment it stops")

-- The aim (battle/aim.lua): degrees equal right and left, power ticks,
-- dots at the same distance and tip on the last point
local aim_name = require "battle.aim"
check(aim_name.degrees(math.rad(40)) == 40 and aim_name.degrees(math.rad(140)) == 40, "aim: 40° right and left")
check(aim_name.degrees(math.rad(-30)) == -30 and aim_name.degrees(math.rad(-150)) == -30, "aim: pointing down the degrees are negative")
check(aim_name.degrees(math.rad(90)) == 90, "aim: straight up 90°")
check(aim_name.notch(0.94) == 18 and aim_name.notch(0.95) == 19 and aim_name.notch(1) == 20, "aim: one tick every 5%")
local segment = {}
for i = 1, 4 do segment[i] = { x = 40 * i, y = 0 } end
local out = {}
local k = aim_name.lay_dots(segment, 4, 15, 40, out)
check(k == 11 and out[1].x == 7.5 and math.abs(out[2].x - out[1].x - 15) < 1e-9 and out[k].x <= 160,
	"aim: one dot every 15 from the muzzle to the end")
k = aim_name.lay_dots(segment, 4, 1, 40, out)
check(k <= 40 and k >= 38, "aim: no more than 40 dots, they spread out")
local m = aim_name.new()
check(#m.nodi == 2 * aim_name.POINTS + 5 + aim_name.RINGS and m.sign, "aim: dots, line, reticle, gauge, tip, rings and tag")
aim_name.needle(m, 0, 0, 0, 2, 0.94, vec(1, 0, 0, 1))
aim_name.tag(m, 0, 0, 0, 2, 40, 0.94)
check(m.c.gradi == 40 and m.c.p == 94 and m.c.radice.scale.x == 0.5 and m.c.radice.pos.x > 50,
	"aim: degrees and power past the gauge's tip, the same size at every zoom")
aim_name.crosshair(m, 100, 50, 0, 2, 0.5, vec(1, 0, 0, 1))
check(m.mir.enabled and m.mir.scale.x == 0.5 and math.abs(m.mir.pos.x - (100 + aim_name.RETICLE_D / 2)) < 1e-9 and m.mir.pos.y == 50,
	"aim: the reticle at a fixed on-screen distance in the aim direction")
check(m.segments[2].enabled and m.segments[2].pos.x == 100 and m.segments[2].size.x < aim_name.RETICLE_D / 2, "aim: the line from the muzzle to the reticle")
aim_name.needle(m, 100, 50, math.rad(30), 2, 0.5, vec(1, 0, 0, 1))
check(m.lanc.enabled and not m.mir.enabled and not m.segments[2].enabled and math.abs(m.lanc.euler.z - 30) < 1e-6 and m.lanc.scale.x == 0.5,
	"aim: the gauge turned like the aim takes the reticle's place")
aim_name.tip(m, 100, 50, math.pi, 2, vec(1, 0, 0, 1))
check(m.punta.enabled and not m.lanc.enabled and not m.c.radice.enabled and m.punta.pos.x < 100 and m.punta.scale.x == 0.5,
	"aim: close-range weapons only have the tip, without gauge or tag")
aim_name.targets(m, { { x = 10, y = 20 }, { x = 30, y = 40 } }, 2, 2, vec(1, 0, 0, 1))
check(m.anelli[1].enabled and m.anelli[2].enabled and not m.anelli[3].enabled and m.anelli[2].pos.x == 30,
	"aim: a ring at the feet of each target")
aim_name.clear(m)
check(not m.lanc.enabled and not m.mir.enabled and not m.c.radice.enabled and not m.segments[2].enabled
	and not m.punta.enabled and not m.anelli[1].enabled, "aim: via turns everything off")

-- Controller (ui/controller.lua): actions as Defold sends them
local controller = require "ui.controller"
local c = controller.new("Android")
check(controller.input(c, hash("touch"), { pressed = true }) == nil, "controller: the touch isn't its own")
local ev = controller.input(c, hash("pad_a"), { pressed = true, value = 1 })
check(#ev == 1 and ev[1].nome == "a" and ev[1].held_down and ev[1].ui == "conferma" and c.giu.a, "controller: A pressed, confirms in the menus")
ev = controller.input(c, hash("pad_a"), { value = 1 })
check(#ev == 0, "controller: A held doesn't repeat")
ev = controller.input(c, hash("pad_a"), { released = true, value = 0 })
check(#ev == 1 and not ev[1].held_down and not c.giu.a, "controller: A released")
ev = controller.input(c, hash("pad_rt"), { value = 0.3 })
check(#ev == 0, "controller: the trigger at a third doesn't fire")
ev = controller.input(c, hash("pad_rt"), { value = 0.8 })
check(#ev == 1 and ev[1].nome == "rt", "controller: the trigger past halfway does")
controller.input(c, hash("pad_dx_destra"), { value = 0.6 })
controller.input(c, hash("pad_dx_su"), { value = 0.8 })
check(math.abs(c.dx.x - 0.6) < 1e-9 and math.abs(c.dx.y + 0.8) < 1e-9, "controller: on Android vertical axes arrive flipped and get straightened")
local pc = controller.new("Windows")
controller.input(pc, hash("pad_dx_su"), { value = 0.8 })
check(math.abs(pc.dx.y - 0.8) < 1e-9, "controller: on the computer the right stick, y up")
controller.input(c, hash("pad_dx_su"), { value = 1 })
controller.input(c, hash("pad_dx_destra"), { value = 1 })
check(math.abs(c.dx.x ^ 2 + c.dx.y ^ 2 - 1) < 1e-9, "controller: diagonally the stick doesn't go past 1")
controller.input(c, hash("pad_dx_destra"), { released = true, value = 0 })
check(c.dx.x == 0 and c.dx.y == -1, "controller: one axis released, the other stays")
ev = controller.input(c, hash("pad_sx_sinistra"), { value = 0.9 })
check(#ev == 1 and ev[1].nome == "sinistra" and ev[1].levetta and ev[1].ui == "sinistra", "controller: the left stick acts as a d-pad in the menus")
ev = controller.input(c, hash("pad_sx_sinistra"), { value = 0.95 })
check(#ev == 0, "controller: only once until it comes back")
controller.input(c, hash("pad_sx_sinistra"), { released = true, value = 0 })
ev = controller.input(c, hash("pad_sx_sinistra"), { value = 0.9 })
check(#ev == 1, "controller: back at the center, again")
-- a controller Defold doesn't know: from the raw action, with Android's numbers
controller.input(c, hash("pad_connesso"), { gamepad = 1, gamepad_unknown = true })
ev = controller.input(c, hash("pad_grezzo"), { gamepad = 2, gamepad_buttons = { 1 } })
check(#ev == 0, "controller: the raw action of a known controller doesn't count")
local keys = {}
for i = 1, 20 do keys[i] = 0 end
keys[1], keys[7] = 1, 1
ev = controller.input(c, hash("pad_grezzo"), { gamepad = 1, gamepad_buttons = keys,
	gamepad_axis = { 0.1, 0, 0.5, -0.5, 0, 1, 0, -1 } })
local name_list = {}
for _, e in ipairs(ev) do name_list[#name_list + 1] = e.nome end
check(table.concat(name_list, " ") == "a rt su y", "unknown controller: A, Y, d-pad up and RT (pressed on this controller: the previous one no longer counts), in name order")
check(c.sx.x == 0 and math.abs(c.dx.x - 0.5) < 1e-9 and math.abs(c.dx.y + 0.5) < 1e-9, "unknown controller: dead zone and right stick, flipped on Android")
check(controller.new("Darwin").raw_ones == nil, "controller: on the computer raw actions aren't read")
ev = controller.input(c, hash("pad_a"), { gamepad = 1, pressed = true, value = 1 })
check(#ev == 0, "controller: a controller read from raw actions doesn't count translated too (a single source)")
-- on Android the PlayStation is also "Touchpad" and "Motion Sensors": they
-- don't count (they wrote on the sticks and the aim jumped)
local ps = controller.new("Android")
controller.input(ps, hash("pad_connesso"), { gamepad = 0, gamepad_name = "Wireless Controller" })
controller.input(ps, hash("pad_connesso"), { gamepad = 1, gamepad_name = "Wireless Controller Touchpad" })
controller.input(ps, hash("pad_connesso"), { gamepad = 2, gamepad_name = "Wireless Controller Motion Sensors", gamepad_unknown = true })
check(ps.family == "playstation", "controller: the touchpad doesn't change the controller in use")
controller.input(ps, hash("pad_dx_destra"), { gamepad = 0, value = 0.8 })
controller.input(ps, hash("pad_dx_destra"), { gamepad = 1, value = 0.1 })
controller.input(ps, hash("pad_dx_destra"), { gamepad = 1, released = true, value = 0 })
controller.input(ps, hash("pad_grezzo"), { gamepad = 2, gamepad_buttons = {}, gamepad_axis = { 0, 0, 0, 0 } })
check(math.abs(ps.dx.x - 0.8) < 1e-9, "controller: touchpad and sensors don't touch the sticks")
-- two controllers: the sticks count from the one that pressed a button last
controller.input(ps, hash("pad_dx_destra"), { gamepad = 3, value = 0.3 })
check(math.abs(ps.dx.x - 0.8) < 1e-9, "controller: another controller's sticks don't count")
controller.input(ps, hash("pad_a"), { gamepad = 3, pressed = true, value = 1 })
controller.input(ps, hash("pad_dx_destra"), { gamepad = 3, value = 0.3 })
check(math.abs(ps.dx.x - 0.3) < 1e-9, "controller: once a button is pressed, its own count")
-- the trigger shaking around half travel isn't pressed twice (Sergio: one
-- press also fired the next weapon)
local tr = controller.new("Android")
local function rt(v, gp)
	local e = controller.input(tr, hash("pad_rt"), { gamepad = gp or 0, value = v, released = v == 0, pressed = v > 0 and not tr.giu.rt })
	local n = {}
	for _, x in ipairs(e) do n[#n + 1] = (x.held_down and "+" or "-") .. x.nome end
	return table.concat(n, " ")
end
local seq = { rt(0.8), rt(0.45), rt(0.6), rt(0.3), rt(0.55), rt(0.1), rt(0) }
check(table.concat(seq, ",") == "+rt,,,,,-rt,", "controller: the trigger is pressed past halfway and released below 20%")
rt(0.9)
check(rt(0, 1) == "" and tr.giu.rt, "controller: another controller doesn't release this one's trigger")
-- Defold sets released when a value drops below 0.9, not when it goes back to
-- zero: it doesn't mean released (Sergio: the aim always jumped to the same
-- angle and one press fired twice)
local dv = controller.new("Android")
controller.input(dv, hash("pad_dx_destra"), { value = 1, pressed = true })
controller.input(dv, hash("pad_dx_su"), { value = 0.3 })
controller.input(dv, hash("pad_dx_destra"), { value = 0.85, released = true })
check(math.abs(dv.dx.x - 0.85) < 1e-9, "controller: the stick below 0.9 doesn't go back to zero (the aim doesn't jump)")
controller.input(dv, hash("pad_dx_destra"), { value = 0 })
check(dv.dx.x == 0, "controller: back at zero, zero")
local function rt2(v, extra)
	local a = { value = v }
	for k, x in pairs(extra or {}) do a[k] = x end
	local e = controller.input(dv, hash("pad_rt"), a)
	local n = {}
	for _, x in ipairs(e) do n[#n + 1] = (x.held_down and "+" or "-") .. x.nome end
	return table.concat(n, " ")
end
local seq2 = { rt2(0.6), rt2(1, { pressed = true }), rt2(0.85, { released = true }), rt2(0.6), rt2(0.3), rt2(0.1), rt2(0) }
check(table.concat(seq2, ",") == "+rt,,,,,-rt,", "controller: the trigger coming back up is released only once, below 20%")
-- the settings: the buttons to change (menu/settings.lua)
local m = controller.new("Windows")
check(controller.assign(m, "spara", "b") and m.tasti.b == "spara" and m.tasti.rt == "baratto",
	"controller: SPARA on B, the swap takes RT")
check(not controller.assign(m, "spara", "start") and m.tasti.start == "rotellina", "controller: Start stays on the wheel")
local saved_ones = controller.to_save(m)
check(saved_ones.start == nil and saved_ones.b == "spara", "controller: saved without Start")
local m2 = controller.new("Windows")
check(controller.use(m2, saved_ones) and m2.tasti.b == "spara" and m2.tasti.start == "rotellina", "controller: the saved mapping is taken back")
check(controller.use(m2, { a = "spara" }) and m2.tasti.a == "spara" and controller.key_of(m2, "baratto") == nil,
	"controller: a mapping with commands without a button is taken")
check(not controller.use(m2, { a = "vola" }) and not controller.use(m2, { a = "spara", b = "spara" }),
	"controller: unknown or duplicate commands are not")
controller.base(m2)
check(controller.key_of(m2, "salta") == nil, "controller: by default you jump with the stick")
check(controller.assign(m2, "salta", "a") and m2.tasti.a == "salta" and m2.tasti.su == "teletrasporto",
	"controller: SALTA on A, the teleport goes to the first free button (d-pad up)")
controller.remove(m2, "teletrasporto")
check(controller.key_of(m2, "teletrasporto") == nil and m2.tasti.su == nil, "controller: Y removes the button")
controller.remove(m2, "rotellina")
check(m2.tasti.start == "rotellina", "controller: Start can't be removed")
local mv = controller.new("Windows")
controller.input(mv, hash("pad_rt"), { value = 0.3 })
check(math.abs(mv.valore.rt - 0.3) < 1e-9, "controller: how far the trigger is pressed")
controller.input(mv, hash("pad_rt"), { released = true, value = 0 })
check(mv.valore.rt == 0, "controller: trigger released")
controller.base(m2)
check(m2.tasti.rt == "spara" and m2.tasti.b == "baratto", "controller: RIPRISTINA goes back to Sergio's")
check(controller.family("Sony Interactive Entertainment Wireless Controller") == "playstation"
	and controller.family("Nintendo Switch Pro Controller") == "nintendo"
	and controller.family("Xbox Wireless Controller") == "xbox" and controller.family("Wireless Controller") == "playstation" and controller.family("8BitDo SN30") == "xbox",
	"controller: the family from the name")
m2.family = "nintendo"
check(controller.name(m2, "a") == "B" and controller.name(m2, "rt") == "ZR" and controller.name(m2, "giu") == "CROCE GIÙ",
	"controller: on Nintendo the bottom button is called B")

if failures > 0 then
	print(failures .. " tests failed")
	os.exit(1)
end
print("all tests passed")
