-- The devil: the character of the battle, the home and the podium. It is made
-- of vector-drawn pieces (strumenti/grafica/diavoletto.py ->
-- battle/devil.lua) animated here in code: no frames, so motion is
-- smooth at any frame rate and the atlas stays light. From the feet to the top
-- of the head it is as tall as the simulation's body (DISEGNO_H); horns and
-- tail stick out.
--
-- Used by the battle (game.gui_script), the home (menu/home.lua) and the podium:
--   local s = scoria.new(color, look)  -- look: the skins worn (battle/skins.lua)
--   local s = scoria.new(color, look, "missile")  -- only that weapon, for portraits
--                                  -- (tags, profile): about thirty fewer nodes
--   scoria.update(s, dt, stato)    -- every frame, no allocation
--   scoria.set_weapon(s, nome) / hit(s, dx) / fire(s, kind) / lunge(s) / die(s)
--   scoria.set_color(s, color)     -- the team changes from one match to the next
-- stato: x, y, facing, grounded, moving, aim (nil if not aiming), turno (it is their turn),
-- paracadute (hanging from the open parachute), vittoria (celebrates on the podium),
-- posa (a clip of battle/animations.lua played from the start, hands free: Favilla showing a move)
--
-- Pieces: head (with goggles and horns, in four faces), torso, two legs, two
-- arms (a single piece per arm, with the fist), the wing, the tail in segments,
-- the detached little hands and the parachute. Whoever's turn it is (or who
-- aims) holds the weapon: it turns around its pivot (aiming, it points where
-- you aim and the head looks there) and whoever grips it follows it. Aiming
-- (or hitting) the aim wins over everything except defeat: also in the air,
-- running or hit.
--
-- Motion is made of springs (squash and stretch, tilt, hit push, recoil, head,
-- tail) and of poses per state, which are keyframe clips
-- (battle/animations.lua, made with the editor
-- strumenti/animazioni/editor.html; sampled by battle/pose.lua) giving the
-- targets to the springs and limbs. The states, in order: defeat (falls
-- backward and fades), hit (white flash, hit face, arms up), parachute
-- (hanging from the straps, legs together swinging), air (the wing flaps, legs
-- tucked going up and forward going down: the sale and scende clips weighted by
-- speed), run (driven by the distance covered, fades into idle), victory (jumps
-- with arms up), idle (breathes; whoever's turn it isn't plays a random skit
-- now and then: naso, sbadiglio, guarda_coda). What depends on the game stays
-- in code: tilt and tail with speed, the parachute swing, the aim. Pushed or
-- dragged without input it doesn't run: it stays idle.
-- The skins (battle/skins.lua, drawn on the stencil: strumenti/stampino)
-- replace pieces or go on top of them, in the same joints: they move with the
-- same animations. A new head without its own faces makes all of them; a new
-- tail has separate border and color like the base one; the parts with the
-- team color have their own layer.
-- The pivots of all pieces (body, head, arms, little hands, legs, wing, tail)
-- are moved from the animation editor (battle/pivots.lua): it changes the
-- point the piece turns around, not where it sits at rest.
-- The clips also say which pieces are shown (head, torso, arms, legs, wing,
-- tail, weapon and the detached little hands, free pieces the clips move and
-- turn). With the weapon in hand the clips are the _arma ones (fermo_arma,
-- corsa_arma, aria_arma, sale_arma, scende_arma) and aiming while still the
-- mira clip; a weapon can have its own (fermo_arma_mallet, mira_mallet); if
-- one is missing the _arma one is used, then the one without a weapon. Grip,
-- pivot and shoulder of each weapon come from battle/grips.lua (also
-- from the editor). The clip with the biggest weight picks who grips the
-- weapon (held_by: an arm, which turns toward the grip, or a little hand,
-- which sits on it; by default the front arm) and the order of the pieces,
-- what is in front of what (layers). Whoever's turn it isn't randomly
-- alternates idle (with the skits) and idle with the weapon in hand.

local game = require "sim.game"
local D = require "battle.devil"
local FROM = require("battle.weapons").weapons
-- where the hook sits on the grapple launcher (HOOK_TIP of strumenti/grafica/armi.py)
local HOOK_TIP = 15.2
local pose = require "battle.pose"
local A = require "battle.animations"
local A_FAVILLA = require "battle.animations_favilla"
local SKINS = require "battle.skins"
local PIVOTS = require "battle.pivots"
local GRIPS = require "battle.grips"
local FLAME = require "battle.flame"

local M = {}

-- everyone's character (the skins worn), until the armory picks it
M.PERSONAGGIO = { "apprendista" }

local P, PT = D.pieces, D.points

-- where each spot turns in the idle body: the skeleton point plus the moved
-- pivot (battle/pivots.lua); the spot's pieces move the opposite way
local IDLE = { 0, 0 }
local function shift(spot) return PIVOTS[spot] or IDLE end
local function pivot(spot, x, y)
	local d = shift(spot)
	return { x + d[1], y + d[2] }
end
local J = {
	testa = pivot("testa", PT.collo[1], PT.collo[2]),
	braccio = pivot("braccio", PT.spalle[1], PT.spalle[2]),
	braccio_dietro = pivot("braccio_dietro", -PT.spalle[1], PT.spalle[2]),
	gamba = pivot("gamba", PT.anche[1], PT.anche[2]),
	gamba_dietro = pivot("gamba_dietro", -PT.anche[1], PT.anche[2]),
	ala = pivot("ala", PT.ala[1], PT.ala[2]),
	busto = pivot("busto", PT.bacino[1], PT.bacino[2]),
}
-- the tail: the root moves with the pivot, the segments the opposite way
-- (turned like the first segment at rest, so with the tail at rest they stay put)
local function tail_pivot(r1)
	local d = shift("coda")
	local c, sn = math.cos(r1), math.sin(r1)
	return d, { -(d[1] * c + d[2] * sn), -(-d[1] * sn + d[2] * c) }
end

local sin, cos, min, max, abs, pi, sqrt = math.sin, math.cos, math.min, math.max, math.abs, math.pi, math.sqrt
local atan2 = math.atan2 or math.atan
local DEG = 180 / pi

local SHADOW = vmath.vector4(0, 0, 0, 0.35)
local WHITE = vmath.vector4(1, 1, 1, 1)
-- how white the hit flash is at most (1 all white)
local FLASH = 0.85

-- springs: position, velocity, stiffness, damping
local SQ, LEAN, SHOVE, KICK, HEAD, TAIL = 1, 2, 3, 4, 5, 6
local SPRING_W = { 16, 10, 12, 18, 11, 7 }
local SPRING_Z = { 0.3, 0.45, 0.5, 0.45, 0.28, 0.25 }

-- the devil's height from the feet to the top of the head, to put the plate above
local HEAD_TOP = (PT.collo[2] + PT.cima[2]) * game.DISEGNO_H / D.height
function M.altezza()
	return HEAD_TOP
end

-- the top of the head image, horns and flame included (they stick out above
-- altezza): the plate goes above this, so up close it never covers them
function M.cima(s)
	return s.cima
end

-- a step: the distance the body covers while a leg makes a full swing, in
-- character heights
local STEP = 0.9
-- the head looks where you aim, up to this angle (radians) up and down
local HEAD_UP, HEAD_DOWN = 0.45, 0.3
-- defeat: after the fall (the clip) it fades in this time
local FADES = 0.6
-- idle, whoever's turn it isn't plays a random skit now and then: between one
-- and the next from PAUSE_FROM to PAUSE_FROM + PAUSE_TO seconds (math.random:
-- graphics only, the simulation has its own generator)
local PAUSE_FROM, PAUSE_TO = 3, 6
-- whoever's turn it isn't randomly takes and puts down the weapon: holds it
-- (or not) from WEAPON_FROM to WEAPON_FROM + WEAPON_TO seconds
local WEAPON_FROM, WEAPON_TO = 4, 8
-- the speed at which it leaves the ground when jumping
local JUMP_V = sqrt(2 * game.GRAVITY * game.base_stats().jump_height)

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
local function size(node, w, h)
	V.x, V.y, V.z = w, h, 0
	gui.set_size(node, V)
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
local function circle_shape(parent, x, y, d, color)
	local n = setup(gui.new_pie_node(vmath.vector3(x, y, 0), vmath.vector3(d, d, 0)), parent, color)
	-- enough sides to stay round even when big, in the home; the soft disc
	-- of the ui atlas draws the edge (ui.disco: a bare polygon shows steps)
	gui.set_perimeter_vertices(n, 32)
	gui.set_texture(n, "ui")
	gui.play_flipbook(n, "disco")
	return n
end
-- a joint: an empty node at (x, y) that the child pieces turn around
local function joint(parent, x, y)
	local n = box(parent, 0, 0, 0, 0)
	pos(n, x, y)
	gui.set_visible(n, false)
	return n
end
-- a drawn piece (p of devil.lua), k world units per drawing unit, in the
-- parent joint moved opposite to pivot d; with the hit flash if it isn't
-- tinted (or if flash_fx)
-- a live flame piece (battle/flame.lua): its own texture, bent by the fiamma
-- material; the update gives it time and flash through its color. False if
-- the image isn't a live one
local function live(s, n, p, x, y, k)
	local key = FLAME.texture(p.img)
	if not key then return false end
	local ox, oy, w, h = FLAME.frame(p.img, p)
	gui.set_texture(n, key)
	gui.set_material(n, "fiamma")
	pos(n, x + ox * k, y + oy * k)
	size(n, w * k, h * k)
	if not s.fire[n] then s.fire_nodes[#s.fire_nodes + 1] = n end
	s.fire[n] = p.img
	return true
end
local function piece(s, parent, p, k, flash_fx, d)
	d = d or IDLE
	local x, y = (p.x - d[1]) * k, (p.y - d[2]) * k
	local n = box(parent, x, y, p.w * k, p.h * k)
	if live(s, n, p, x, y, k) then return n end
	gui.set_texture(n, "diavoletto")
	gui.play_flipbook(n, p.img)
	if p.tint then
		local t = box(parent, x, y, p.w * k, p.h * k)
		gui.set_texture(t, "diavoletto")
		gui.set_material(t, "pezzi")
		gui.play_flipbook(t, p.tint)
		s.tinte[#s.tinte + 1] = t
	end
	if flash_fx or not p.tint then
		gui.set_material(n, "lampo")
		s.flashes[#s.flashes + 1] = n
	else
		gui.set_material(n, "pezzi")
	end
	return n
end

-- the faces: a new head without its own faces makes those too. The base devil
-- doesn't have the last five (WB-009): it uses the normal head
local FACES = { "testa", "testa_colpita", "testa_felice", "testa_ko",
	"testa_mira", "testa_arrabbiata", "testa_sconfitta", "testa_paura", "testa_provocazione" }

-- The pieces of each spot wearing the skins of look (names from
-- battle/skins.lua, one per category): per spot, the pieces from the bottom.
-- The first is the base one or the one replacing it, then those on top, in
-- category order. Also returns the tail: segment lengths and rest angles, base
-- or from the skin that changed it.
local function dress(look)
	local per = {}
	for i = 1, #(look or {}) do
		local skin = SKINS.skins[look[i]]
		assert(skin, "pelle sconosciuta: " .. tostring(look[i]))
		per[skin.category] = skin
	end
	local V = {}
	local function layers(spot)
		V[spot] = V[spot] or { P[spot] or (spot:sub(1, 6) == "testa_" and P.testa) or false }
		return V[spot]
	end
	local function put(spot, p)
		local l = layers(spot)
		if p.mode == "replace" then l[1] = p else l[#l + 1] = p end
	end
	-- the tail: lengths, rest angles and where the root sits relative to the
	-- drawing's one (the skin may have moved it)
	local coda = { l = D.tail, riposo = D.tail_rest, radice = IDLE }
	for _, categories in ipairs({ SKINS.replace, SKINS.over }) do
		for _, c in ipairs(categories) do
			local pz = per[c] and per[c].pieces
			if per[c] and per[c].tail then
				coda = { l = per[c].tail, riposo = per[c].tail_rest, radice = per[c].tail_root or IDLE }
			end
			if pz then
				for spot, p in pairs(pz) do put(spot, p) end
				for i = 2, #FACES do
					if pz.testa and not pz[FACES[i]] then put(FACES[i], pz.testa) end
				end
			end
		end
	end
	return layers, coda
end

-- The pieces of the head of whoever wears look, from the bottom (the head, then
-- the helmet): the turn-order faces draw them (battle/score.lua)
function M.head_pieces(look)
	local out = {}
	for _, p in ipairs(dress(look)("testa")) do
		if p then out[#out + 1] = p end
	end
	return out
end

-- the pieces of a spot (dress) in the parent joint
local function dresses(s, parent, spot, k)
	for _, p in ipairs(s.strati(spot)) do
		if p then piece(s, parent, p, k, true, shift(spot)) end
	end
end


-- The detached little hands (the fist): free pieces on the shape; at rest they
-- sit where the hanging arms end (drawing units), the clips turn and move them
local function steady_hand(spot, x)
	local b, pu = P[spot], P.pugno
	return { x + b.x, PT.spalle[2] + b.y - b.h / 2 + pu.h * 0.4 }
end
local HAND_FRONT, HAND_BACK = steady_hand("braccio", PT.spalle[1]), steady_hand("braccio_dietro", -PT.spalle[1])
-- the little hands' pivot: at rest they turn there (the pieces move the opposite way)
local HAND = shift("pugno")
-- the hand of the hanging arm seen from the shoulder, to turn it toward the grip
local TOWARD_A = atan2(HAND_FRONT[2] - J.braccio[2], HAND_FRONT[1] - J.braccio[1])
local TOWARD_D = atan2(HAND_BACK[2] - J.braccio_dietro[2], HAND_BACK[1] - J.braccio_dietro[1])

-- The layers: the pieces from the back, what is in front of what. A clip can
-- have its own order (layers), otherwise this one
local LEVELS = { "coda", "ala", "braccio_d", "manina_d", "gamba_d", "gamba_a", "busto", "testa", "arma",
	"braccio_a", "manina_a" }
local function little_hand(s, point, k)
	local g = joint(s.forma, (point[1] + shift("pugno")[1]) * k, (point[2] + shift("pugno")[2]) * k)
	dresses(s, g, "pugno", k)
	return g
end

-- shows or hides a node, only when it changes
local function visible(s, n, on)
	if s.vis[n] ~= on then
		s.vis[n] = on
		gui.set_enabled(n, on)
	end
end

-- The weapons in hand: rest angle (radians) around the pivot, 0 facing
-- forward. Images and sizes are in battle/weapons.lua
-- (strumenti/grafica/armi.py), grip, pivot and shoulder in battle/grips.lua
local ARMI = {
	missile = -0.35, sniper = -0.3, sword = -1.9, teleport = -0.5, grenade = -0.5, shards = -0.3,
	punch = -0.9, eagle = -0.6, hook = -0.4, bellows = -0.3,
	boomerang = -0.5, tar = -0.5, drill = -0.3, magnet = -0.4, cannon = -0.3, petard = -0.5,
	mallet = 2,  -- on the shoulder: as long as it is, pointing down it would go into the terrain
	lunge = 1.3,  -- straight up: pointing down it would go into the terrain
}
-- the recoil at most (world units per 200)
local GRIP = 20

-- an image from the weapons atlas, sizes in world units
-- the weapon: in the hand of whoever's turn it is or who aims (and of whoever
-- waits, now and then), with the pivot on the weapon's shoulder
-- (battle/grips.lua, plus the clip) and turned by s.weapon_a; the
-- recoil pushes it back along its axis. Returns where the grip is in the
-- shape (drawing units), for whoever grips it
local WEAPON0 = { grip = IDLE, pivot = IDLE, shoulder = PT.spalle }
local function weapon_in_hand(s, po, in_hand, lx, q)
	if not in_hand then return 0, 0 end
	local g = GRIPS[s.chosen_weapon] or WEAPON0
	local ax, ay = g.shoulder[1] + po.arma_x, g.shoulder[2] + po.arma_y
	pos(s.presa, ax * s.k, ay * s.k)
	scale(s.presa, 1 / lx, 1 / q)
	rot(s.giro, s.weapon_a)
	local ox = -min(s.x[KICK] * s.w * 0.6, GRIP * s.h / 200 / game.CORPO * 0.8)
	-- the weapon can be enlarged (scale, from the editor): grip and pivot stay in
	-- units of the image as it is, and the image grows around the pivot
	local sc = g.scale or 1
	pos(s.armi[s.chosen_weapon], ox - g.pivot[1] * sc, -g.pivot[2] * sc)
	local dx, dy = (g.grip[1] - g.pivot[1]) * sc + ox, (g.grip[2] - g.pivot[2]) * sc
	local c, sn = cos(s.weapon_a), sin(s.weapon_a)
	return ax + (dx * c - dy * sn) / s.k / lx, ay + (dx * sn + dy * c) / s.k / q
end

-- puts the pieces in the clip's order (from the back), only when it changes;
-- those the clip doesn't name go on top, in the usual order. Each piece goes
-- above the previous one, among siblings (children of forma): with
-- move_above(n, nil) Defold detaches it from the parent and the character vanishes
local function levels(s, l)
	if s.z_order == l then return end
	s.z_order = l
	local steps_count, first_one = {}, nil
	local function above(nome)
		local nodes = s.level_nodes[nome]
		if steps_count[nome] or not nodes then return end
		steps_count[nome] = true
		for i = 1, #nodes do
			if first_one then gui.move_above(nodes[i], first_one) end
			first_one = nodes[i]
		end
	end
	for i = 1, #l do above(l[i]) end
	for i = 1, #LEVELS do above(LEVELS[i]) end
end

local function weapon_figure(parent, img, x, y, w, h)
	local n = box(parent, x, y, w, h)
	gui.set_texture(n, "armi")
	gui.set_material(n, "pezzi")
	gui.play_flipbook(n, img)
	return n
end

-- the weapons are world-sized, not body-sized (game.CORPO): the image, above
-- the parts with the team color. The front arm's hand holds it.
local function weapon_name(s, name, color)
	local a = FROM[name]
	local g = joint(s.giro, 0, 0)
	weapon_figure(g, a.img, a.x, a.y, a.w, a.h)
	if a.tint then
		s.weapon_tints[#s.weapon_tints + 1] = setup(weapon_figure(g, a.tint, a.x, a.y, a.w, a.h), nil, color)
	end
	-- the Grapple's hook in the barrel: a piece of its own, it vanishes when it flies off
	if name == "hook" then
		local u = require("battle.weapons").pieces.uncino
		s.uncino = weapon_figure(g, u.img, HOOK_TIP + u.x, u.y, u.w, u.h)
	end
	gui.set_enabled(g, false)
	s.armi[name] = g
end

-- The hook is in the barrel (on) or has left with the wire
function M.uncino(s, on)
	if s.hook_on ~= on then
		s.hook_on = on
		gui.set_enabled(s.uncino, on)
	end
end

-- the clips with the weapon in hand, for each weapon: first the one just for
-- it (fermo_arma_mallet, mira_mallet), then the _arma one, then the one without a weapon.
-- Computed per character since each character has their own animation set.
local function make_armed(anim)
	local armed = {}
	for name in pairs(FROM) do
		local function with_weapon(nome)
			return anim[nome .. "_arma_" .. name] or anim[nome .. "_arma"] or anim[nome]
		end
		armed[name] = {
			fermo = with_weapon("fermo"),
			corsa = with_weapon("corsa"),
			aria = with_weapon("aria"),
			sale = with_weapon("sale"),
			scende = with_weapon("scende"),
			mira = anim["mira_" .. name] or anim.mira,
		}
	end
	return armed
end

local ANIMAZIONI_PERSONAGGIO = {
	apprendista = { A = A, armed = make_armed(A) },
	favilla = { A = A_FAVILLA, armed = make_armed(A_FAVILLA) },
}

function M.new(color, look, weapon_only)
	local H = game.DISEGNO_H
	-- three quarters of the height wide, like the starting capsule (sim/body.lua)
	local Wd = H * 0.75
	local k = H / D.height
	local char_name = "apprendista"
	if look then
		for _, name in ipairs(look) do
			if ANIMAZIONI_PERSONAGGIO[name] then
				char_name = name
				break
			end
		end
	end
	local anim_data = ANIMAZIONI_PERSONAGGIO[char_name] or ANIMAZIONI_PERSONAGGIO.apprendista
	local s = { color = color, h = H, w = Wd, k = k, armi = {}, tinte = {}, weapon_tints = {}, flashes = {},
		fire = {}, fire_nodes = {}, fire_col = vmath.vector4(1, 1, 1, 1), white = 0,
		personaggio = char_name, A = anim_data.A, armed = anim_data.armed,
		teste = {}, heads_t = {}, facce = {}, vis = {},
		x = {}, v = {}, goal = {}, coda = {}, coda_a = {},
		-- this frame's pose from the clips and the angles (radians) of the hanging
		-- arms and legs, which chase it
		posa = pose.nuova(), braccia = { 0, 0 }, gambe = { 0, 0 } }
	s.strati, s.tail_shape = dress(look)
	s.root = joint(nil, 0, 0)
	gui.set_adjust_mode(s.root, gui.ADJUST_FIT)
	s.alpha = vmath.vector4(1, 1, 1, 1)
	s.flash_col = vmath.vector4(1, 1, 1, 1)

	s.ombra = circle_shape(s.root, 0, 0, Wd * 1.3, SHADOW)
	scale(s.ombra, 1, 0.22)
	-- the parachute, behind everything: swings around the point where the lines meet
	s.para = joint(s.root, 0, D.chute_y * k)
	piece(s, s.para, P.paracadute, k)
	gui.set_enabled(s.para, false)
	-- corpo: tilt and push; forma: squash and stretch. The weapon sits on corpo
	-- and not on forma, so squashing doesn't skew the aim
	s.corpo = joint(s.root, 0, 0)
	s.forma = joint(s.corpo, 0, 0)

	-- from the back: the tail (all the borders first, then all the colors: so the
	-- segments merge into a single tail), the wing, the back arm, the legs, the
	-- torso, the head, the weapon, the front arm
	s.tail_pivot, s.coda_dentro = tail_pivot(s.tail_shape.riposo[1])
	-- the tail's root: the drawing's one, moved by the skin and the pivot
	local rc = s.tail_shape.radice
	s.tail_base = { PT.coda[1] + rc[1] + s.tail_pivot[1], PT.coda[2] + rc[2] + s.tail_pivot[2] }
	for layer = 1, 2 do
		local parent_node, x, y = s.forma, s.tail_base[1] * k, s.tail_base[2] * k
		for i = 1, #s.tail_shape.l do
			parent_node = joint(parent_node, x, y)
			s.coda[i] = s.coda[i] or {}
			s.coda[i][layer] = parent_node
			if i == 1 then parent_node = joint(parent_node, s.coda_dentro[1] * k, s.coda_dentro[2] * k) end
			dresses(s, parent_node, "coda_" .. i .. (layer == 1 and "_bordo" or ""), k)
			x, y = s.tail_shape.l[i] * k, 0
		end
	end
	s.ala = joint(s.forma, J.ala[1] * k, J.ala[2] * k)
	dresses(s, s.ala, "ala", k)
	s.braccio_d = joint(s.forma, J.braccio_dietro[1] * k, J.braccio_dietro[2] * k)
	dresses(s, s.braccio_d, "braccio_dietro", k)
	s.manina_d = little_hand(s, HAND_BACK, k)
	s.gamba_d = joint(s.forma, J.gamba_dietro[1] * k, J.gamba_dietro[2] * k)
	dresses(s, s.gamba_d, "gamba_dietro", k)
	s.gamba_a = joint(s.forma, J.gamba[1] * k, J.gamba[2] * k)
	dresses(s, s.gamba_a, "gamba", k)
	s.busto = joint(s.forma, J.busto[1] * k, J.busto[2] * k)
	dresses(s, s.busto, "busto", k)
	s.collo = joint(s.forma, J.testa[1] * k, J.testa[2] * k)
	-- the head in its own joint (the clips remove it)
	s.testa = joint(s.collo, 0, 0)
	-- the head: as many pieces as the face with the most layers, each with its own
	-- team-color layer; faccia() changes them
	local layers = 0
	for _, f in ipairs(FACES) do
		s.facce[f] = s.strati(f)
		layers = max(layers, #s.facce[f])
	end
	local head = s.facce.testa[1]
	s.cima = (PT.collo[2] + head.y + head.h / 2) * k
	for i = 1, layers do
		s.teste[i] = piece(s, s.testa, s.facce.testa[i] or s.facce.testa[1], k, true, shift("testa"))
		s.heads_t[i] = box(s.testa, 0, 0, 0, 0)
		gui.set_texture(s.heads_t[i], "diavoletto")
		gui.set_material(s.heads_t[i], "pezzi")
		s.tinte[#s.tinte + 1] = s.heads_t[i]
	end
	s.fiamma = joint(s.collo, PT.cima[1] * k, PT.cima[2] * k)
	dresses(s, s.fiamma, "fiamma", k)
	-- the plate goes above the flame too (it breathes up to 9% taller, battle/flame.fp)
	for _, p in ipairs(s.strati("fiamma")) do
		if p then s.cima = max(s.cima, (PT.collo[2] + PT.cima[2] + p.y + p.h * 0.59) * k) end
	end
	-- and above where the idle clip holds the head (each character lifts it its own way)
	local lift = s.A.fermo and s.A.fermo.tracks.testa_y
	if lift then s.cima = s.cima + lift[2] * k end
	-- the weapon: above the body and the head, below the front arm. The grip sits
	-- on the weapon's shoulder and undoes the shape's squash, the inner turn turns
	-- the weapon around the pivot (turned and then squashed it would skew)
	s.presa = joint(s.forma, 0, 0)
	s.giro = joint(s.presa, 0, 0)
	if weapon_only then
		weapon_name(s, weapon_only, color)
	else
		for name in pairs(ARMI) do weapon_name(s, name, color) end
	end
	s.braccio_a = joint(s.forma, J.braccio[1] * k, J.braccio[2] * k)
	dresses(s, s.braccio_a, "braccio", k)
	s.manina_a = little_hand(s, HAND_FRONT, k)
	-- the nodes of each layer, in the order they were made (LEVELS)
	s.level_nodes = { coda = { s.coda[1][1], s.coda[1][2] }, ala = { s.ala }, braccio_d = { s.braccio_d },
		manina_d = { s.manina_d }, gamba_d = { s.gamba_d }, gamba_a = { s.gamba_a }, busto = { s.busto },
		testa = { s.collo }, arma = { s.presa }, braccio_a = { s.braccio_a }, manina_a = { s.manina_a } }
	s.z_order = LEVELS
	M.set_weapon(s, weapon_only or "missile")

	M.set_color(s, color, true)
	M.reset(s)
	return s
end

-- Repaints parachute and weapons with another team's color
function M.set_color(s, color, force)
	if s.color == color and not force then return end
	s.color = color
	C.x, C.y, C.z, C.w = color.x, color.y, color.z, 1
	for _, n in ipairs(s.tinte) do gui.set_color(n, C) end
	for _, n in ipairs(s.weapon_tints) do gui.set_color(n, C) end
end

-- the hit flash: the pieces turn white, fading. The lampo material does it
-- (battle/flash.fp): the color's green says how white
local function flash_fx(s, q)
	s.white = FLASH * q
	local c = s.flash_col
	c.y = 1 - FLASH * q
	for i = 1, #s.flashes do gui.set_color(s.flashes[i], c) end
end

local function face_img(s, nome)
	if s.faccia ~= nome then
		s.faccia = nome
		local f, k, d = s.facce[nome], s.k, shift("testa")
		for i = 1, #s.teste do
			local n, t, p = s.teste[i], s.heads_t[i], f[i]
			gui.set_enabled(n, p ~= nil)
			gui.set_enabled(t, p ~= nil and p.tint ~= nil)
			if p and s.fire[n] then
				live(s, n, p, (p.x - d[1]) * k, (p.y - d[2]) * k, k)
			elseif p then
				gui.play_flipbook(n, p.img)
				pos(n, (p.x - d[1]) * k, (p.y - d[2]) * k)
				size(n, p.w * k, p.h * k)
				if p.tint then
					gui.play_flipbook(t, p.tint)
					pos(t, (p.x - d[1]) * k, (p.y - d[2]) * k)
					size(t, p.w * k, p.h * k)
				end
			end
		end
	end
end

function M.reset(s)
	for i = 1, #SPRING_W do s.x[i], s.v[i], s.goal[i] = 0, 0, 0 end
	s.x[SQ] = 1
	s.t = math.random() * 10
	s.ui_action, s.action_t = nil, 0
	s.vy, s.vx, s.last_x, s.last_y, s.ground = 0, 0, nil, nil, true
	s.passo, s.cammina, s.swing = 0, 0, 0
	for i = 1, 2 do s.braccia[i], s.gambe[i] = 0, 0 end
	local rest = s.tail_shape.riposo
	for i = 1, #rest do s.coda_a[i] = rest[i] - (i > 1 and rest[i - 1] or 0) end
	s.flash = 0
	s.morte, s.morto = nil, nil
	s.skit, s.skit_t, s.n_skits = nil, 0, 0
	s.paused = PAUSE_FROM + PAUSE_TO * math.random()
	s.alpha.w = 1
	gui.set_color(s.root, s.alpha)
	rot(s.corpo, 0)
	scale(s.forma, 1, 1)
	flash_fx(s, 0)
	face_img(s, "testa")
	if s.chosen_weapon then gui.set_enabled(s.armi[s.chosen_weapon], not s.vuote) end
	s.holding_weapon, s.weapon_t = false, WEAPON_FROM + WEAPON_TO * math.random()
	s.weapon_a = 0
	s.face = 1
end

function M.set_enabled(s, on)
	if on and s.morte then M.reset(s) end
	gui.set_enabled(s.root, on)
end

local function springs(s, dt)
	local x, v, goal = s.x, s.v, s.goal
	local n = max(1, math.ceil(dt * 120))
	local h = dt / n
	for _ = 1, n do
		for i = 1, #SPRING_W do
			local w, z = SPRING_W[i], SPRING_Z[i]
			v[i] = v[i] + (w * w * (goal[i] - x[i]) - 2 * z * w * v[i]) * h
			x[i] = x[i] + v[i] * h
		end
	end
end

-- The waiting skits: non-looping clips, a random one now and then
local SKITS = { "naso", "sbadiglio", "guarda_coda" }

-- whoever's turn it isn't randomly takes and puts down the weapon (never in
-- the middle of a skit); with the weapon in hand no skits
local function waiting(s, dt)
	s.weapon_t = s.weapon_t - dt
	if s.weapon_t <= 0 and not s.skit then
		s.holding_weapon, s.weapon_t = not s.holding_weapon, WEAPON_FROM + WEAPON_TO * math.random()
	end
	if s.holding_weapon then return pose.aggiungi(s.posa, s.armed[s.chosen_weapon].fermo, s.t, 1) end
	if s.skit then
		local sc = s.A[s.skit]
		s.skit_t = s.skit_t + dt
		if s.skit_t < sc.duration then return pose.aggiungi(s.posa, sc, s.skit_t, 1) end
		s.skit, s.paused = nil, PAUSE_FROM + PAUSE_TO * math.random()
	end
	s.paused = s.paused - dt
	if s.paused <= 0 then
		s.skit, s.skit_t = SKITS[math.random(#SKITS)], 0
		s.n_skits = s.n_skits + 1
	end
	pose.aggiungi(s.posa, s.A.fermo, s.t, 1)
end

-- the tail: a wave starting at the back and reaching the tip, plus the TAIL
-- spring (it lags behind running, whips when jumping and when a hit lands).
-- Each segment chases its angle a bit more slowly than the previous one: so
-- the motion reaches the tip late
-- turn_around: the whole tail turns by this much around its root (the coda_gira channel)
local function coda(s, dt, turn_around)
	local base, r = s.x[TAIL], s.tail_shape.riposo
	local first_one = 0
	for i = 1, #s.coda_a do
		local rest = r[i] - first_one
		first_one = r[i]
		local a = rest + (base + sin(s.t * 2.6 - i * 0.8) * 0.05) * (0.5 + 0.1 * i)
		s.coda_a[i] = s.coda_a[i] + (a - s.coda_a[i]) * min(1, dt * (18 - 2.5 * i))
		local g = i == 1 and turn_around or 0
		rot(s.coda[i][1], s.coda_a[i] + g)
		rot(s.coda[i][2], s.coda_a[i] + g)
	end
end

-- Defeat: the weapon drops, it falls backward with X eyes (the sconfitta
-- clip), then fades. The terrain below may be gone (the crater), so nothing
-- stays resting: everything fades
local function death(s, dt)
	local t = s.morte + dt
	s.morte = t
	pose.aggiungi(s.posa, s.A.sconfitta, t, 1)
	s.alpha.w = max(0, 1 - max(0, t - s.A.sconfitta.duration - 0.3) / FADES)
	gui.set_color(s.root, s.alpha)
	if s.alpha.w == 0 then
		s.morto = true
		gui.set_enabled(s.root, false)
	end
end

function M.update(s, dt, st)
	if s.morto then return end
	dt = min(dt, 1 / 20)
	s.t = s.t + dt
	local face = st.facing
	s.face = face
	scale(s.root, face, 1)
	pos(s.root, st.x, st.y)

	if s.last_y then
		local vy = (st.y - s.last_y) / max(dt, 1e-4)
		s.vy = s.vy + (vy - s.vy) * min(1, dt * 14)
		local vx = (st.x - s.last_x) / max(dt, 1e-4) * face
		if abs(vx) < 20 * s.h then s.vx = s.vx + (vx - s.vx) * min(1, dt * 8) end
	end
	local dx = s.last_x and abs(st.x - s.last_x) or 0
	s.last_x, s.last_y = st.x, st.y
	local ground = st.grounded

	-- steps: count the distance covered on the ground (not teleports)
	local runs = ground and st.moving ~= 0 and dx < s.h and not s.morte
	if runs then s.passo = (s.passo + dx / (STEP * s.h) * 2 * pi) % (2 * pi) end
	s.cammina = s.cammina + ((runs and 1 or 0) - s.cammina) * min(1, dt * 10)

	-- landing and takeoff: squash and stretch, the head nods, the tail whips
	if ground and not s.ground and s.vy < -40 then
		s.v[SQ] = s.v[SQ] - min(7, -s.vy / 40)
		s.v[HEAD] = s.v[HEAD] - min(4, -s.vy / 80)
		s.v[TAIL] = s.v[TAIL] - min(3, -s.vy / 100)
	elseif not ground and s.ground and s.vy > 20 then
		s.v[SQ] = s.v[SQ] + 4
		s.v[TAIL] = s.v[TAIL] + 2
	end
	s.ground = ground
	if s.ui_action then s.action_t = s.action_t + dt end

	-- the aim, toward where it faces
	local a = 0
	if st.aim then a = face > 0 and st.aim or pi - st.aim end
	if a > pi then a = a - 2 * pi end
	local para = st.paracadute and not ground and not s.morte
	-- whoever's turn it is (or who aims) holds the weapon, whoever waits now and
	-- then; dead, on the podium and hanging from the parachute (hands on the
	-- straps) no
	-- st.fermo: only idle, without weapon and without skits (the home)
	if st.turno or st.aim ~= nil or st.fermo then s.holding_weapon = false end
	-- st.posa: a clip played once from the start (Favilla showing a move,
	-- sim/missions.lua dimostra), hands free
	local posing = st.posa and s.A[st.posa]
	if st.posa ~= s.posa_name then s.posa_name, s.posa_t = st.posa, 0 end
	if posing then s.posa_t = s.posa_t + dt end
	local in_hand = (st.turno or st.aim ~= nil or s.holding_weapon) and not s.morte and not st.vittoria and not para and not posing
	local aim_name = st.aim ~= nil and not s.morte and not para
	-- the clips: with the weapon in hand the _arma ones, aiming while still mira
	-- (the weapon's own if any)
	local armed = s.armed[s.chosen_weapon]
	local clip = in_hand and armed or s.A
	local frozen = aim_name and armed.mira or clip.fermo

	-- the state's pose, from the clips; on top, what depends on the game: tilt
	-- and tail with speed, the aim
	local po = s.posa
	pose.azzera(po)
	local forward = st.moving * face
	local lean = -0.22 * max(-1, min(1, forward / 70)) * s.cammina
	local sq = 0
	-- running the tail moves away from the body, backward, and comes back when
	-- stopping; in the air it follows the velocity
	local cd = 0.2 * max(-1, min(1, forward / 70)) * s.cammina
	if not ground then cd = cd + max(-0.2, min(0.2, s.vy / 900)) end
	gui.set_enabled(s.para, para)

	if s.morte then
		death(s, dt)
	elseif s.ui_action == "colpito" and s.action_t < s.A.colpito.duration then
		-- hit: hit face, arms up (if they don't hold the weapon)
		pose.aggiungi(po, s.A.colpito, s.action_t, 1)
	elseif para then
		-- hanging from the straps; parachute and body swing against the velocity
		s.swing = s.swing + (-max(-0.35, min(0.35, s.vx / 400)) - s.swing) * min(1, dt * 4)
		pose.aggiungi(po, s.A.paracadute, s.t, 1)
		rot(s.para, s.swing * 0.6)
		lean = s.swing * 0.5
	elseif not ground then
		-- in the air: going up the sale pose, going down the scende one, and it
		-- stretches with speed
		local above = max(-1, min(1, s.vy / JUMP_V))
		pose.aggiungi(po, clip.aria, s.t, 1)
		pose.aggiungi(po, clip.sale, 0, above)
		pose.aggiungi(po, clip.scende, 0, -above)
		sq = min(0.2, abs(s.vy) / 900)
	elseif runs or s.cammina > 0.05 then
		-- the run: one loop of the clip per step, fading into idle
		local c = s.cammina
		pose.aggiungi(po, frozen, s.t, 1 - c)
		pose.aggiungi(po, clip.corsa, s.passo / (2 * pi) * clip.corsa.duration, c)
	elseif st.vittoria then
		pose.aggiungi(po, s.A.vittoria, s.t, 1)
	elseif posing then
		pose.aggiungi(po, posing, s.posa_t, 1)
	elseif not st.turno and not aim_name and not st.fermo then
		-- idle, not their turn: a skit now and then
		waiting(s, dt)
	else
		pose.aggiungi(po, frozen, s.t, 1)
	end
	-- aiming, the head looks where you aim
	local head = po.testa
	if aim_name then head = max(-HEAD_DOWN, min(HEAD_UP, a * 0.5)) end
	if not s.morte then
		s.goal[SQ], s.goal[LEAN], s.goal[HEAD], s.goal[TAIL] = po.schiaccia + sq, lean, head, cd + po.coda
	else
		s.goal[SQ], s.goal[LEAN], s.goal[HEAD], s.goal[TAIL] = 1, 0, head, 0
	end
	face_img(s, po.face_name or "testa")
	springs(s, dt)

	local q = max(0.4, s.x[SQ])
	local lx = 1 + (1 - q) * 0.8
	-- the head doesn't squash (the drawing's details would look skewed): it goes
	-- down and up with the torso
	scale(s.forma, lx, q)
	rot(s.corpo, s.x[LEAN] + po.corpo)
	pos(s.corpo, -s.x[SHOVE] * s.w + po.corpo_x * s.k, po.salto * s.k)
	scale(s.ombra, 1 + (1 - q) * 0.5, 0.22)

	-- arms and legs chase the pose (so states blend gently); the legs lift in the steps
	local follow = min(1, dt * 16)
	s.braccia[1] = s.braccia[1] + (po.braccio_a - s.braccia[1]) * follow
	s.braccia[2] = s.braccia[2] + (po.braccio_d - s.braccia[2]) * follow
	-- the weapon turns around its pivot: aiming toward the aim, otherwise at rest
	-- plus the clip
	if in_hand and aim_name then
		s.weapon_a = a - s.x[LEAN] - po.corpo
	else
		s.weapon_a = s.weapon_a + (ARMI[s.chosen_weapon] + po.arma - s.weapon_a) * follow
	end
	local who_hit = in_hand and po.mostra_arma > 0.5 and (po.clip and po.clip.held_by or "braccio_a")
	local hx, hy = weapon_in_hand(s, po, in_hand, lx, q)
	-- whoever grips it follows it: the arm turns toward the grip, the little hand sits on it
	if who_hit == "braccio_a" then
		s.braccia[1] = atan2(hy - J.braccio[2] - po.braccio_a_y, hx - J.braccio[1] - po.braccio_a_x) - TOWARD_A
	elseif who_hit == "braccio_d" then
		s.braccia[2] = atan2(hy - J.braccio_dietro[2] - po.braccio_d_y, hx - J.braccio_dietro[1] - po.braccio_d_x) - TOWARD_D
	end
	s.gambe[1] = s.gambe[1] + (po.gamba_a - s.gambe[1]) * follow
	s.gambe[2] = s.gambe[2] + (po.gamba_d - s.gambe[2]) * follow
	rot(s.braccio_a, s.braccia[1])
	rot(s.braccio_d, s.braccia[2])
	rot(s.gamba_a, s.gambe[1])
	rot(s.gamba_d, s.gambe[2])
	pos(s.gamba_a, (J.gamba[1] + po.gamba_a_x) * s.k, (J.gamba[2] + po.alza_a) * s.k)
	pos(s.gamba_d, (J.gamba_dietro[1] + po.gamba_d_x) * s.k, (J.gamba_dietro[2] + po.alza_d) * s.k)
	pos(s.braccio_a, (J.braccio[1] + po.braccio_a_x) * s.k, (J.braccio[2] + po.braccio_a_y) * s.k)
	pos(s.braccio_d, (J.braccio_dietro[1] + po.braccio_d_x) * s.k, (J.braccio_dietro[2] + po.braccio_d_y) * s.k)
	pos(s.ala, (J.ala[1] + po.ala_x) * s.k, (J.ala[2] + po.ala_y) * s.k)
	if who_hit == "manina_a" then
		pos(s.manina_a, hx * s.k, hy * s.k)
		rot(s.manina_a, s.weapon_a + po.manina_a)
	else
		pos(s.manina_a, (HAND_FRONT[1] + HAND[1] + po.manina_a_x) * s.k, (HAND_FRONT[2] + HAND[2] + po.manina_a_y) * s.k)
		rot(s.manina_a, po.manina_a)
	end
	if who_hit == "manina_d" then
		pos(s.manina_d, hx * s.k, hy * s.k)
		rot(s.manina_d, s.weapon_a + po.manina_d)
	else
		pos(s.manina_d, (HAND_BACK[1] + HAND[1] + po.manina_d_x) * s.k, (HAND_BACK[2] + HAND[2] + po.manina_d_y) * s.k)
		rot(s.manina_d, po.manina_d)
	end
	rot(s.ala, po.ala)
	pos(s.busto, (J.busto[1] + po.busto_x) * s.k, (J.busto[2] + po.busto_y) * s.k)
	rot(s.busto, po.busto)
	local rc = s.tail_base
	pos(s.coda[1][1], (rc[1] + po.coda_x) * s.k, (rc[2] + po.coda_y) * s.k)
	pos(s.coda[1][2], (rc[1] + po.coda_x) * s.k, (rc[2] + po.coda_y) * s.k)
	coda(s, dt, po.coda_gira)
	pos(s.collo, (J.testa[1] + po.testa_x) * s.k, (J.testa[2] + po.testa_y) * s.k)
	rot(s.collo, s.x[HEAD])
	scale(s.collo, 1 / lx, 1 / q)
	pos(s.fiamma, (PT.cima[1] + (po.fiamma_x or 0)) * s.k, (PT.cima[2] + (po.fiamma_y or 0)) * s.k)
	rot(s.fiamma, po.fiamma or 0)
	local sqf = po.fiamma_schiaccia or 1
	local fx = (po.fiamma_scala_x or 1) / sqf
	local fy = (po.fiamma_scala_y or 1) * sqf
	scale(s.fiamma, fx, fy)

	-- white hit flash
	if s.flash > 0 then
		s.flash = max(0, s.flash - dt * 6)
		flash_fx(s, min(1, s.flash * 1.5))
	end
	-- the live flames: their time and the flash
	for i = 1, #s.fire_nodes do
		local n = s.fire_nodes[i]
		gui.set_color(n, FLAME.color(s.fire_col, s.t, s.fire[n], s.white))
	end

	visible(s, s.presa, in_hand and po.mostra_arma > 0.5)
	levels(s, po.clip and po.clip.layers or LEVELS)
	-- the pieces the clip shows or removes: the arms, the little hands, the head,
	-- the torso, the legs, the wing, the tail
	visible(s, s.braccio_a, po.mostra_braccio_a > 0.5)
	visible(s, s.manina_a, po.mostra_manina_a > 0.5)
	visible(s, s.braccio_d, po.mostra_braccio_d > 0.5)
	visible(s, s.manina_d, po.mostra_manina_d > 0.5)
	visible(s, s.ala, po.mostra_ala > 0.5)
	visible(s, s.testa, po.mostra_testa > 0.5)
	visible(s, s.fiamma, (po.mostra_fiamma or 1) > 0.5)
	visible(s, s.busto, po.mostra_busto > 0.5)
	visible(s, s.gamba_a, po.mostra_gamba_a > 0.5)
	visible(s, s.gamba_d, po.mostra_gamba_d > 0.5)
	visible(s, s.coda[1][1], po.mostra_coda > 0.5)
	visible(s, s.coda[1][2], po.mostra_coda > 0.5)
end

function M.set_weapon(s, name)
	if s.chosen_weapon == name or not s.armi[name] then return end
	if s.chosen_weapon then gui.set_enabled(s.armi[s.chosen_weapon], false) end
	s.chosen_weapon = name
	local sc = GRIPS[name] and GRIPS[name].scale or 1
	scale(s.armi[name], sc, sc)
	-- dead, the weapon is gone
	gui.set_enabled(s.armi[name], not s.morte and not s.vuote)
end

-- Empty-handed (at the start of the first lesson it has no weapons): the weapon isn't shown
function M.empty_hands(s, si)
	if s.vuote == si then return end
	s.vuote = si
	if s.chosen_weapon then gui.set_enabled(s.armi[s.chosen_weapon], not s.morte and not si) end
end

-- Hit taken: white flash, push and tilt in the hit direction (dx: toward where
-- it pushes, in the world; without it, from the front), squash, head snapping,
-- tail whipping
function M.hit(s, dx)
	if s.morte then return end
	local d = (dx and dx ~= 0) and (dx > 0 and 1 or -1) * s.face or -1
	s.flash = 1
	s.v[SHOVE] = s.v[SHOVE] - 9 * d
	s.v[SQ] = s.v[SQ] - 4
	s.v[LEAN] = s.v[LEAN] - 5 * d
	s.v[HEAD] = s.v[HEAD] - 8 * d
	s.v[TAIL] = s.v[TAIL] + 4 * d
	s.ui_action, s.action_t = "colpito", 0
end

-- Shot fired: the weapon recoils along its axis (the body neither bends nor
-- squashes: it would move the hand off the aim), head and tail snap
function M.fire(s, kind)
	local k = kind == "shards" and 0.5 or 1
	s.v[KICK] = s.v[KICK] + 14 * k
	s.v[HEAD] = s.v[HEAD] + 3 * k
	s.v[TAIL] = s.v[TAIL] - 1.5 * k
end

-- Lunge dash: stretches forward and bends
function M.lunge(s)
	s.v[SQ] = s.v[SQ] + 6
	s.v[LEAN] = s.v[LEAN] + 8
	s.v[HEAD] = s.v[HEAD] + 4
	s.v[TAIL] = s.v[TAIL] - 3
end

-- Defeat: the weapon drops, it falls backward and fades
function M.die(s)
	if s.morte then return end
	s.morte = 0
	s.flash = 0
	s.ui_action = nil
	flash_fx(s, 0)
	face_img(s, "testa_ko")
	gui.set_enabled(s.para, false)
end

return M
