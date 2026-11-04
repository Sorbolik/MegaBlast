-- The vignettes (Sergio, 3 Nov; the level plan:
-- https://claude.ai/artifact/12CRugbQCR2oB32LHt6aS2): no more writing above
-- the heads. Who speaks does it with their face, in comic style:
--   - the strip at the top, just under the points: a line of whoever guides
--     you that doesn't stop the game (what to do now, Ritenta, Brava). The
--     bots' comments are not here: plain text over their head (battle/plate.lua,
--     Sergio, 4 Nov);
--   - the big vignette: the game stops, the face, the line and a small
--     drawing that shows the move with the real devil; it explains a thing
--     BEFORE you do it. Only the button goes on, VAI! or AVANTI (or A): a tap
--     elsewhere does nothing (Sergio, 4 Nov: too easy to tap outside by
--     mistake); CHIUDI (or B) closes it. Without a drawing it is smaller.
-- The faces are cut from the chosen WB-012 sheets
-- (strumenti/ritratti/taglia.py -> "ritratti" texture, ui/portraits.atlas).
-- Client only: it doesn't touch the match.
--
--   local v = vignette.new()
--   v:say(chi, faccia, testo, nome, colore)  -- the strip (testo nil: it goes away)
--   v:ghost(behind)                       -- every frame: someone is behind the strip
--                                         -- (in vignette.STRIP), it goes see-through
--   local view = v:open(pages)            -- pages: { { chi, faccia, testo, disegno } }:
--                                         -- the big vignette (the battle keeps it as self.carta);
--                                         -- a page { tavola = mission id, titolo } is the
--                                         -- mission's illustration on a postcard with its title (WB-015)
--   view:premi(x, y) / view:pad(n)        -- a tap / a controller button: true when it is over
--   v:update(dt)                          -- every frame, also while the game is stopped
--   vignette.CHI.favilla                  -- name and color of who speaks

local ui = require "ui.ui"
local T = require("lang.text").vignette
local common = require("lang.text").common
local scoria = require "battle.scoria"
local ill = require "ui.illustrations"

local M = {}

local function c(r, g, b, a) return vmath.vector4(r, g, b, a or 1) end
-- comic colors: the parchment of the sheets and the ink of the outlines
local PAPER, INK, INK_SOFT = c(0.95, 0.88, 0.75), c(0.12, 0.07, 0.05), c(0.12, 0.07, 0.05, 0.55)
local BOX = c(0.10, 0.09, 0.12)
local GROUND, STEP = c(0.36, 0.37, 0.42), c(0.27, 0.28, 0.33)

-- who speaks: the name over the line and its color
M.CHI = {
	favilla = { nome = T.favilla, colore = c(0.28, 0.44, 0.56) },
	fabbro = { nome = T.fabbro, colore = c(0.72, 0.26, 0.16) },
	apprendista = { nome = T.apprendista, colore = c(0.72, 0.26, 0.16) },
}
M.FACCE = { calma = true, ride = true, spiega = true, sorpresa = true, preoccupata = true,
	arrabbiata = true, fiera = true, triste = true }

-- the strip: top center, 38 below the points board (room for the lines under
-- it, «+N PER PAREGGIARE» and the turn balance); the goal is right of the board
local STRIP_W, STRIP_H, STRIP_Y = 760, 96, 568
-- someone behind it (Sergio, 4 Nov: «capita troppo spesso di essere dietro le
-- etichette»): the strip stays where it is and goes see-through
local GHOST_A, GHOST_T = 0.25, 0.15
M.STRIP = { x0 = 640 - STRIP_W / 2, y0 = STRIP_Y - STRIP_H / 2, x1 = 640 + STRIP_W / 2, y1 = STRIP_Y + STRIP_H / 2 }
local FACE_S = 80
-- the mission's postcard (WB-015): the picture at 880 x 495 (16:9), the
-- parchment margin, the band with title and button. Straight: a tilted
-- quad would show steps on its edges (no antialiasing on rotated nodes)
local POST_W, POST_H, POST_M, POST_BAND, POST_Y = 880, 495, 18, 84, 12
-- the story's comic (menu/story.lua) uses the same postcard
M.POST = { h = POST_H, margin = POST_M, band = POST_BAND, y = POST_Y }
local BACKDROP = c(0.09, 0.07, 0.07)
-- the big vignette
local BIG_W, BIG_H = 980, 400
local BIG_FACE = 230
local DRAW_W, DRAW_H = 640, 262
local DRAW_K = 2.3   -- the drawing's devil, times its size in the match

local V3 = vmath.vector3()

local function vec(x, y) return vmath.vector3(x, y, 0) end

local function box(x, y, w, h, color, parent)
	local n = gui.new_box_node(vec(x, y), vec(w, h))
	gui.set_texture(n, "battaglia")
	gui.play_flipbook(n, "targa_bianco")
	gui.set_color(n, color)
	if parent then gui.set_parent(n, parent) end
	return n
end

-- the comic panel: parchment with an ink border
local function panel(x, y, w, h, parent)
	local n, b = ui.pannello(x, y, w, h, parent)
	gui.set_color(n, PAPER)
	gui.set_color(b, INK)
	gui.set_inherit_alpha(b, true) -- the strip goes see-through whole (M.ghost)
	return n
end

local function face(chi, faccia, x, y, s, parent)
	-- no black frame around the portrait (Sergio, 4 Nov): the box only holds it
	local frame = box(x, y, s + 8, s + 8, INK, parent)
	gui.set_visible(frame, false)
	local n = gui.new_box_node(vec(0, 0), vec(s, s))
	gui.set_texture(n, "ritratti")
	gui.set_parent(n, frame)
	return frame, n
end

local function set_face(n, chi, faccia)
	if not M.CHI[chi] then chi = "apprendista" end
	if not M.FACCE[faccia] then faccia = "calma" end
	gui.play_flipbook(n, chi .. "_" .. faccia)
end

-- ink text, left aligned, wrapping within w
local function ink(t, x, y, scale, color, w, parent)
	local n = gui.new_text_node(vec(x, y), t)
	gui.set_font(n, "titolo")
	gui.set_color(n, color)
	gui.set_outline(n, c(0, 0, 0, 0))
	gui.set_shadow(n, c(0, 0, 0, 0))
	V3.x, V3.y, V3.z = scale, scale, 1
	gui.set_scale(n, V3)
	gui.set_pivot(n, gui.PIVOT_NW)
	if w then
		gui.set_line_break(n, true)
		gui.set_size(n, vec(w / scale, 400))
	end
	gui.set_parent(n, parent)
	return n
end

local function who(chi, nome, colore)
	local d = M.CHI[chi] or M.CHI.apprendista
	return nome or d.nome, colore or d.colore
end

function M.new()
	local v = setmetatable({ line = nil }, { __index = M })
	-- the strip
	v.strip = panel(640, STRIP_Y, STRIP_W, STRIP_H)
	local fx = -STRIP_W / 2 + 12 + FACE_S / 2
	v.strip_frame, v.strip_face = face(nil, nil, fx, 0, FACE_S, v.strip)
	local tx = fx + FACE_S / 2 + 18
	v.strip_name = ink("", tx, STRIP_H / 2 - 10, 0.42, INK, nil, v.strip)
	v.strip_text = ink("", tx, STRIP_H / 2 - 34, 0.5, INK, STRIP_W / 2 - tx - 14, v.strip)
	for _, n in ipairs({ v.strip_frame, v.strip_face, v.strip_name, v.strip_text }) do
		gui.set_inherit_alpha(n, true)
	end
	gui.set_enabled(v.strip, false)
	return v
end

local function show_strip(v, s)
	-- under the big vignette the strip doesn't show: it would say the same line
	if not s or v.view then
		gui.set_enabled(v.strip, false)
		v.shown = nil
		v.behind = nil
		gui.cancel_animations(v.strip, "color.w")
		gui.set_color(v.strip, PAPER)
		return
	end
	if v.shown == s then return end
	v.shown = s
	set_face(v.strip_face, s.chi, s.faccia)
	local nome, colore = who(s.chi, s.nome, s.colore)
	gui.set_text(v.strip_name, nome)
	gui.set_color(v.strip_name, colore)
	gui.set_text(v.strip_text, s.testo)
	gui.set_enabled(v.strip, true)
	-- it comes in with a small drop
	gui.set_position(v.strip, vec(640, STRIP_Y + 16))
	gui.animate(v.strip, "position.y", STRIP_Y, gui.EASING_OUTBACK, 0.25)
end

-- The line of the moment (nil: nothing)
function M.say(v, chi, faccia, testo, nome, colore)
	if not testo or testo == "" then
		v.line = nil
	elseif not (v.line and v.line.testo == testo and v.line.chi == chi) then
		v.line = { chi = chi, faccia = faccia, testo = testo, nome = nome, colore = colore }
	end
	show_strip(v, v.line)
end

-- Nothing in the strip (the match ends, a menu opens)
function M.quiet(v)
	v.line = nil
	show_strip(v, nil)
end

function M.update(v, dt)
	if v.view then v.view:animate(dt) end
end

-- every frame: true when someone is behind the strip (M.STRIP)
function M.ghost(v, behind)
	behind = v.shown and behind or false
	if behind == v.behind then return end
	v.behind = behind
	gui.animate(v.strip, "color.w", behind and GHOST_A or 1, gui.EASING_OUTQUAD, GHOST_T)
end

-- The drawings of the moves ----------------------------------------------------
-- A small stage in the big vignette: the real devil (battle/scoria.lua) does
-- the move in a loop. Units: the match's, the devil's feet at y = 0 on the
-- ground line; the stage is DRAW_W / DRAW_K wide.

local SW, SH = DRAW_W / DRAW_K, DRAW_H / DRAW_K
local FLOOR = -SH / 2 + 12

local function lerp(a, b, k) return a + (b - a) * k end
local function clamp(k) return math.max(0, math.min(1, k)) end
local function ease(k) k = clamp(k); return k * k * (3 - 2 * k) end

-- an arrow made of three bars, from (x1, y1) to (x2, y2)
local function arrow(d, x1, y1, x2, y2, color)
	local dx, dy = x2 - x1, y2 - y1
	local l = math.sqrt(dx * dx + dy * dy)
	local a = math.atan2(dy, dx)
	local shaft = box((x1 + x2) / 2, (y1 + y2) / 2, l, 2.4, color, d.stage)
	gui.set_rotation(shaft, vmath.vector3(0, 0, math.deg(a)))
	for _, s in ipairs({ 1, -1 }) do
		local h = box(0, 0, 8, 2.4, color, d.stage)
		local b = a + s * 2.5
		gui.set_position(h, vec(x2 + math.cos(b) * 3.6, y2 + math.sin(b) * 3.6))
		gui.set_rotation(h, vmath.vector3(0, 0, math.deg(b)))
	end
	return shaft
end

local function icon(d, weapon, x, y, s)
	local n = gui.new_box_node(vec(x, y), vec(s, s))
	gui.set_texture(n, "armi")
	gui.play_flipbook(n, weapon .. "_icona")
	gui.set_parent(n, d.stage)
	return n
end

-- the finger on the screen: a light disc with a ring
local function finger(d)
	local n = ui.disco(0, 0, 9, c(1, 1, 1, 0.35), d.stage)
	ui.ring_node(0, 0, 9, 1.2, c(1, 1, 1, 0.9), n)
	return n
end

local function dots(d, n, color)
	local list = {}
	for i = 1, n do list[i] = ui.disco(0, 0, 2.2, color, d.stage) end
	return list
end

-- the dots of a shot from (x, y) at angle a with speed s (units/s), under gravity
local function arc(list, x, y, a, s, upto)
	local vx, vy = math.cos(a) * s, math.sin(a) * s
	for i, n in ipairs(list) do
		local t = i * 0.07
		gui.set_position(n, vec(x + vx * t, y + vy * t - 0.5 * 160 * t * t))
		gui.set_enabled(n, not upto or i <= upto)
	end
end

local function at(n, x, y) gui.set_position(n, vec(x, y)) end
local function shown(n, on) gui.set_enabled(n, on) end

-- the second devil, the target (blue, like the lessons' dummies)
local function target(d, x)
	d.st2 = { x = x, y = FLOOR, facing = -1, grounded = true, moving = 0, fermo = true }
	d.s2 = scoria.new(ui.C.SQUADRA[2], scoria.PERSONAGGIO, "sword")
	scoria.empty_hands(d.s2, true)
	gui.set_parent(d.s2.root, d.stage)
	scoria.set_enabled(d.s2, true)
end

local function ground(d, x0, x1, y)
	y = y or FLOOR
	box((x0 + x1) / 2, y - 6, x1 - x0, 12, GROUND, d.stage)
end

-- the drawings: build (the stage) and frame (t: seconds in the loop)
local DRAW = {}

DRAW.cammina = { loop = 4, build = function(d)
	ground(d, -SW / 2, SW / 2)
	arrow(d, -14, 46, -40, 46, ui.C.LIGHT)
	arrow(d, 14, 46, 40, 46, ui.C.LIGHT)
end, frame = function(d, t)
	local x = 70 * math.sin(t / 4 * 2 * math.pi)
	local dir = math.cos(t / 4 * 2 * math.pi) >= 0 and 1 or -1
	d.st.x, d.st.facing, d.st.moving = x, dir, dir
end }

DRAW.salta = { loop = 3, build = function(d)
	ground(d, -SW / 2, 20)
	box(SW / 4 + 10, FLOOR, SW / 2 - 20, 40, STEP, d.stage)
	d.arc = dots(d, 9, c(1, 1, 1, 0.45))
	arc(d.arc, -30, FLOOR + 20, 1.05, 150)
end, frame = function(d, t)
	local st = d.st
	st.facing = 1
	if t < 0.8 then
		st.x, st.y, st.grounded, st.moving = lerp(-90, -40, t / 0.8), FLOOR, true, 1
	elseif t < 1.6 then
		local k = (t - 0.8) / 0.8
		st.x = lerp(-40, 40, k)
		st.y = lerp(FLOOR, FLOOR + 20, k) + 140 * k * (1 - k)
		st.grounded, st.moving = false, 1
	else
		st.x, st.y, st.grounded, st.moving = 40, FLOOR + 20, true, 0
	end
end }

-- aiming and firing: the finger drags from the devil toward the target, the
-- dots of the shot appear, letting go it leaves
local function aim_draw(weapon, opts)
	opts = opts or {}
	return { loop = 3.4, build = function(d)
		ground(d, -SW / 2, SW / 2)
		target(d, 80)
		d.weapon = weapon
		d.finger = finger(d)
		d.arc = dots(d, 14, c(1, 1, 1, 0.5))
		d.shot = ui.disco(0, 0, 5, ui.C.BRACE, d.stage)
		if opts.annulla then
			d.cross = gui.new_text_node(vec(0, 0), "X")
			gui.set_font(d.cross, "titolo")
			gui.set_color(d.cross, ui.C.BRACE)
			gui.set_scale(d.cross, vmath.vector3(0.3, 0.3, 1))
			gui.set_parent(d.cross, d.stage)
		end
	end, frame = function(d, t)
		local st = d.st
		st.x, st.facing, st.turno = -70, 1, true
		local ox, oy = -70, FLOOR + 20
		local a, power = 0.55, 1
		if t < 0.4 then
			st.aim = nil
			shown(d.finger, false)
			for _, n in ipairs(d.arc) do shown(n, false) end
			shown(d.shot, false)
			if d.cross then shown(d.cross, false) end
			d.fired = false
		elseif t < 1.8 then
			-- the drag: the finger goes from the devil outward, the aim follows it
			local k = ease((t - 0.4) / 1.0)
			power = lerp(0.3, 1, k)
			st.aim = a
			shown(d.finger, true)
			at(d.finger, ox + math.cos(a) * 46 * power, oy + math.sin(a) * 46 * power)
			arc(d.arc, ox, oy, a, 112 + 40 * power, 14)
		elseif opts.annulla then
			-- cancel: the finger goes back to the devil, nothing leaves
			local k = ease((t - 1.8) / 0.6)
			at(d.finger, lerp(ox + math.cos(a) * 46, ox, k), lerp(oy + math.sin(a) * 46, oy, k))
			arc(d.arc, ox, oy, a, 152, math.floor(14 * (1 - k)))
			if k >= 1 then
				st.aim = nil
				shown(d.cross, true)
				at(d.cross, ox, oy + 16)
			end
		else
			-- let go: the shot flies along the dots, the target is hit
			shown(d.finger, false)
			for _, n in ipairs(d.arc) do shown(n, false) end
			if not d.fired then
				d.fired = true
				scoria.fire(d.s, weapon)
			end
			st.aim = a
			local tt = t - 1.8
			local vx, vy = math.cos(a) * 152, math.sin(a) * 152
			local x, y = ox + vx * tt, oy + vy * tt - 80 * tt * tt
			if x < d.st2.x then
				shown(d.shot, true)
				at(d.shot, x, y)
			elseif gui.is_enabled(d.shot) then
				shown(d.shot, false)
				scoria.hit(d.s2, 1)
			end
		end
	end }
end

-- close weapons: walk up and strike
local function strike_draw(weapon)
	return { loop = 3, build = function(d)
		ground(d, -SW / 2, SW / 2)
		target(d, 30)
		d.weapon = weapon
	end, frame = function(d, t)
		local st = d.st
		st.facing, st.turno = 1, true
		if t < 1 then
			st.x, st.moving, st.aim, d.done = lerp(-80, -8, ease(t)), 1, nil, false
		else
			st.x, st.moving, st.aim = -8, 0, 0.2
			if t > 1.4 and not d.done then
				d.done = true
				scoria.fire(d.s, weapon)
				if weapon == "lunge" then scoria.lunge(d.s) end
				scoria.hit(d.s2, 1)
			end
			if weapon == "lunge" and t > 1.4 then st.x = lerp(-8, 60, ease((t - 1.4) / 0.3)) end
		end
	end }
end

DRAW.mira = aim_draw("missile")
DRAW.primaria = aim_draw("missile")
DRAW.missile = aim_draw("missile")
DRAW.annulla = aim_draw("missile", { annulla = true })
DRAW.sword = strike_draw("sword")
DRAW.secondaria = strike_draw("sword")
DRAW.punch = strike_draw("punch")
DRAW.lunge = strike_draw("lunge")

-- the Tonante: you fire down behind you, the recoil throws you up and away
DRAW.eagle = { loop = 3, build = function(d)
	ground(d, -SW / 2, SW / 2)
	d.weapon = "eagle"
	arrow(d, -30, FLOOR + 20, -55, FLOOR + 6, ui.C.BRACE)
	arrow(d, 0, FLOOR + 50, 40, FLOOR + 70, ui.C.STEEL)
end, frame = function(d, t)
	local st = d.st
	st.facing, st.turno = 1, true
	if t < 1 then
		st.x, st.y, st.grounded, st.aim, d.done = -20, FLOOR, true, -2.6, false
	else
		if not d.done then d.done = true; scoria.fire(d.s, "eagle") end
		local k = clamp((t - 1) / 1.4)
		st.x = lerp(-20, 70, k)
		st.y = FLOOR + 60 * math.sin(k * math.pi)
		st.grounded = k >= 1
		st.aim = k < 1 and -2.6 or nil
	end
end }

-- the Maglio: the blow on the ground bounces you up
DRAW.mallet = { loop = 3, build = function(d)
	ground(d, -SW / 2, SW / 2)
	d.weapon = "mallet"
	arrow(d, 10, FLOOR + 50, 10, FLOOR + 80, ui.C.STEEL)
end, frame = function(d, t)
	local st = d.st
	st.facing, st.turno, st.x = 1, true, -10
	if t < 1 then
		st.y, st.grounded, st.aim, d.done = FLOOR, true, -0.6, false
	else
		if not d.done then d.done = true; scoria.fire(d.s, "mallet") end
		local k = clamp((t - 1) / 1.2)
		st.y = FLOOR + 62 * math.sin(k * math.pi)
		st.grounded, st.aim = k >= 1, nil
	end
end }

-- the Mantice: the blow pushes whoever is in front off the edge
DRAW.bellows = { loop = 3, build = function(d)
	ground(d, -SW / 2, 50)
	target(d, 30)
	d.weapon = "bellows"
	arrow(d, -10, FLOOR + 30, 20, FLOOR + 30, ui.C.STEEL)
end, frame = function(d, t)
	local st, s2 = d.st, d.st2
	st.x, st.facing, st.turno, st.aim = -30, 1, true, 0
	if t < 1 then
		s2.x, s2.y, s2.grounded, d.done = 30, FLOOR, true, false
	else
		if not d.done then d.done = true; scoria.fire(d.s, "bellows"); scoria.hit(d.s2, 1) end
		local k = clamp((t - 1) / 1.2)
		s2.x = lerp(30, 100, k)
		s2.y = FLOOR + 14 * math.sin(math.min(k, 0.5) * math.pi) - (k > 0.55 and 160 * (k - 0.55) ^ 2 * 4 or 0)
		s2.grounded = false
	end
end }

-- the orb: it flies along the arc, you appear where it lands
DRAW.teleport = { loop = 3.2, build = function(d)
	ground(d, -SW / 2, -10)
	ground(d, 50, SW / 2, FLOOR + 30)
	d.orb = icon(d, "teleport", 0, 0, 14)
	d.arc = dots(d, 12, c(0.77, 0.61, 1, 0.6))
	arc(d.arc, -60, FLOOR + 20, 0.9, 150, 12)
end, frame = function(d, t)
	local st = d.st
	st.facing = 1
	if t < 0.6 then
		st.x, st.y, st.aim, st.turno = -60, FLOOR, 0.9, true
		shown(d.orb, false)
		gui.set_enabled(d.s.root, true)
	elseif t < 1.6 then
		st.aim = nil
		local tt = (t - 0.6) * 1.0
		local vx, vy = math.cos(0.9) * 150, math.sin(0.9) * 150
		shown(d.orb, true)
		local x, y = -60 + vx * tt, FLOOR + 20 + vy * tt - 80 * tt * tt
		at(d.orb, x, math.max(y, FLOOR + 38))
		gui.set_enabled(d.s.root, false)
	else
		shown(d.orb, false)
		gui.set_enabled(d.s.root, true)
		st.x, st.y = 82, FLOOR + 30
	end
end }

-- the barter: the second attack you don't need becomes an orb
DRAW.baratto = { loop = 2.4, build = function(d)
	ground(d, -SW / 2, SW / 2)
	d.st.x, d.st.facing = -80, 1
	d.a = icon(d, "sword", -22, 10, 22)
	arrow(d, -6, 10, 10, 10, ui.C.LIGHT)
	d.b = icon(d, "teleport", 28, 10, 22)
end, frame = function(d, t)
	local k = 1 + 0.12 * math.max(0, math.sin(t / 2.4 * 2 * math.pi))
	gui.set_scale(d.b, vmath.vector3(k, k, 1))
	gui.set_color(d.a, c(1, 1, 1, t > 1.2 and 0.35 or 1))
end }

-- the Rampino: the hook catches the ledge and pulls you up
DRAW.hook = { loop = 3, build = function(d)
	ground(d, -SW / 2, SW / 2)
	box(50, 0, 80, 10, STEP, d.stage)
	d.weapon = "hook"
	d.rope = box(0, 0, 1, 1.6, ui.C.LIGHT, d.stage)
end, frame = function(d, t)
	local st = d.st
	st.facing, st.turno, st.x = 1, true, -20
	local hx, hy = 20, -2
	if t < 0.8 then
		st.y, st.grounded, st.aim = FLOOR, true, 0.9
		shown(d.rope, false)
	else
		local k = ease((t - 0.8) / 1.2)
		st.x = lerp(-20, 22, k)
		st.y = lerp(FLOOR, 5, k)
		st.grounded, st.aim = k >= 1, k < 1 and 0.9 or nil
		local x0, y0 = st.x + 4, st.y + 20
		local dx, dy = hx - x0, hy - y0
		local l = math.sqrt(dx * dx + dy * dy)
		shown(d.rope, k < 1 and l > 2)
		at(d.rope, (x0 + hx) / 2, (y0 + hy) / 2)
		gui.set_size(d.rope, vec(l, 1.6, 0))
		gui.set_rotation(d.rope, vmath.vector3(0, 0, math.deg(math.atan2(dy, dx))))
	end
end }

-- the parachute: in the air you open it and come down slowly
DRAW.parachute = { loop = 3.4, build = function(d)
	ground(d, -SW / 2, SW / 2)
end, frame = function(d, t)
	local st = d.st
	st.facing, st.x = 1, lerp(-40, 30, clamp(t / 3))
	local top = SH / 2 - 44
	if t < 0.5 then
		st.y, st.grounded, st.paracadute = lerp(top + 20, top, t / 0.5), false, false
	elseif t < 2.8 then
		st.y = lerp(top, FLOOR, clamp((t - 0.5) / 2.3))
		st.grounded, st.paracadute = st.y <= FLOOR, true
	else
		st.y, st.grounded, st.paracadute = FLOOR, true, false
	end
end }

-- their names, in order (for whoever shows them all: scenari/vignette.txt)
M.DRAWINGS = {}
for name in pairs(DRAW) do M.DRAWINGS[#M.DRAWINGS + 1] = name end
table.sort(M.DRAWINGS)

-- The big vignette --------------------------------------------------------------

local View = {}
View.__index = View

local function build_drawing(view, name)
	local spec = DRAW[name]
	if view.drawing then
		gui.delete_node(view.drawing.clip)
		view.drawing = nil
	end
	if not spec then return end
	local d = { spec = spec, t = 0 }
	d.clip = box(view.draw_x, view.draw_y, DRAW_W, DRAW_H, BOX, view.paper)
	gui.set_clipping_mode(d.clip, gui.CLIPPING_MODE_STENCIL)
	d.stage = gui.new_box_node(vec(0, 0), vec(1, 1))
	gui.set_visible(d.stage, false)
	gui.set_parent(d.stage, d.clip)
	V3.x, V3.y, V3.z = DRAW_K, DRAW_K, 1
	gui.set_scale(d.stage, V3)
	d.st = { x = -60, y = FLOOR, facing = 1, grounded = true, moving = 0 }
	spec.build(d)
	d.s = scoria.new(ui.C.SQUADRA[1], scoria.PERSONAGGIO, d.weapon)
	if not d.weapon then scoria.empty_hands(d.s, true) end
	gui.set_parent(d.s.root, d.stage)
	scoria.set_enabled(d.s, true)
	view.drawing = d
end

local show_page
-- a tavola page without its illustration: straight to the next page
local function advance_past(view)
	if view.i < #view.pages then
		view.i = view.i + 1
		return show_page(view)
	end
end

function show_page(view)
	local p = view.pages[view.i]
	local last = view.i == #view.pages
	local on_tav = p.tavola ~= nil and view.tav ~= nil
	if view.tav then
		gui.set_enabled(view.tav, on_tav)
		gui.set_enabled(view.paper, not on_tav)
	end
	if on_tav then
		gui.set_text(view.tav_title, string.upper(p.titolo or ""))
		gui.set_text(view.tav_next_text, last and T.go or common.next)
		return
	end
	if p.tavola then return advance_past(view) end
	set_face(view.face, p.chi, p.faccia or "spiega")
	local nome, colore = who(p.chi, p.nome, p.colore)
	gui.set_text(view.name, nome)
	gui.set_color(view.name, colore)
	gui.set_text(view.text, p.testo)
	build_drawing(view, p.disegno)
	gui.set_text(view.next_text, last and T.go or common.next)
	-- the dots count the pages of the vignette, not the illustration before them
	local shift = view.pages[1].tavola and 1 or 0
	for k, n in ipairs(view.dots) do gui.set_color(n, k == view.i - shift and INK or INK_SOFT) end
end

function M.open(v, pages, pad)
	local view = setmetatable({ pages = pages, i = 1, dots = {}, owner = v }, View)
	view.radice = gui.new_box_node(vec(640, 360), vec(0, 0))
	local veil = gui.new_box_node(vec(0, 0), vec(1280 * 4, 720 * 4))
	gui.set_color(veil, c(0, 0, 0, 0.6))
	gui.set_parent(veil, view.radice)
	-- the mission's illustration as a postcard (Sergio, 4 Nov: smaller, well
	-- packaged, and nothing of the map behind): an opaque backdrop on the whole
	-- screen, the parchment card with its shadow, the picture
	-- in an ink frame, the title and the button on the card's bottom band.
	-- The page of the story before the explanation
	for _, pg in ipairs(pages) do
		local tex = pg.tavola and ill.texture(pg.tavola, "tavola")
		if tex then
			view.tavola = pg.tavola
			view.tav = gui.new_box_node(vec(0, 0), vec(0, 0))
			gui.set_parent(view.tav, view.radice)
			local back = gui.new_box_node(vec(0, 0), vec(1280 * 4, 720 * 4))
			gui.set_color(back, BACKDROP)
			gui.set_parent(back, view.tav)
			local card_h = POST_M + POST_H + POST_BAND
			local shadow = box(10, POST_Y - 12, POST_W + 2 * POST_M, card_h, c(0, 0, 0, 0.45), view.tav)
			local card = panel(0, POST_Y, POST_W + 2 * POST_M, card_h, view.tav)
			local iy = card_h / 2 - POST_M - POST_H / 2
			box(0, iy, POST_W + 6, POST_H + 6, INK, card)
			local pic = gui.new_box_node(vec(0, iy), vec(POST_W, POST_H))
			gui.set_texture(pic, tex)
			gui.set_adjust_mode(pic, gui.ADJUST_FIT)
			gui.set_parent(pic, card)
			local by = -card_h / 2 + POST_BAND / 2
			view.tav_title = ui.titolo("", -POST_W / 2, by, 0.9, INK, card)
			gui.set_outline(view.tav_title, c(0, 0, 0, 0))
			gui.set_pivot(view.tav_title, gui.PIVOT_W)
			view.tav_next = box(POST_W / 2 - 110, by, 220, 56, INK, card)
			view.tav_next_text = gui.new_text_node(vec(0, 0), "")
			gui.set_font(view.tav_next_text, "titolo")
			gui.set_color(view.tav_next_text, PAPER)
			gui.set_scale(view.tav_next_text, vmath.vector3(0.7, 0.7, 1))
			gui.set_parent(view.tav_next_text, view.tav_next)
			break
		end
	end
	-- without a drawing the vignette is only the face and the line: smaller
	local drawn = false
	for _, pg in ipairs(pages) do if pg.disegno and DRAW[pg.disegno] then drawn = true end end
	local bw, bh, bf = drawn and BIG_W or 820, drawn and BIG_H or 250, drawn and BIG_FACE or 150
	view.paper = panel(0, 10, bw, bh, view.radice)
	local left = -bw / 2 + 28 + bf / 2
	local fy = bh / 2 - 28 - bf / 2
	view.frame, view.face = face(nil, nil, left, fy, bf, view.paper)
	view.name = ink("", left - bf / 2, fy - bf / 2 - 14, 0.6, INK, nil, view.paper)
	local rx = left + bf / 2 + 28
	local rw = bw / 2 - rx - 28
	view.text = ink("", rx, bh / 2 - 26, drawn and 0.62 or 0.8, INK, rw, view.paper)
	view.draw_x, view.draw_y = rx + rw / 2, -bh / 2 + 28 + DRAW_H / 2
	-- the buttons (Sergio, 4 Nov: no empty space): with a drawing AVANTI goes
	-- under the face, and CHIUDI with the page dots between the name and it;
	-- without one AVANTI is bottom right and CHIUDI on its left. CHIUDI only
	-- with more pages (one page closes with VAI!; not SALTA, which in the jump
	-- vignette would read as the jump)
	local by = -bh / 2 + 44
	local sx, sy, dx, dy
	-- the dots closer together when there are many (RILEGGI)
	local step = math.min(18, 140 / math.max(1, #pages - 1))
	if drawn then
		view.next = box(left, by, bf, 56, INK, view.paper)
		sx, sy = left - bf / 2 + 60, by + 44
		dx, dy = left + bf / 2 - 5 - (#pages - 1) * step, sy
	else
		view.next = box(bw / 2 - 28 - 110, by, 220, 56, INK, view.paper)
		sx, sy = bw / 2 - 28 - 220 - 100, by
		dx, dy = rx + 9, by
	end
	view.skip = box(sx, sy, 160, 40, c(0, 0, 0, 0), view.paper)
	ink(pad and T.close_pad or T.close, -60, 12, 0.55, INK_SOFT, nil, view.skip)
	-- CHIUDI with more pages, not counting the illustration's
	local real = 0
	for _, pg in ipairs(pages) do if not pg.tavola then real = real + 1 end end
	gui.set_enabled(view.skip, real > 1)
	view.next_text = gui.new_text_node(vec(0, 0), "")
	gui.set_font(view.next_text, "titolo")
	gui.set_color(view.next_text, PAPER)
	gui.set_scale(view.next_text, vmath.vector3(0.7, 0.7, 1))
	gui.set_parent(view.next_text, view.next)
	if pad then
		local a = ink("A", -96, 14, 0.5, PAPER, nil, view.next)
		gui.set_pivot(a, gui.PIVOT_NW)
	end
	-- the page dots, when there is more than one
	if real > 1 then
		for k = 1, real do
			view.dots[k] = ui.disco(dx + (k - 1) * step, dy, math.min(9, step - 2), INK_SOFT, view.paper)
		end
	end
	show_page(view)
	gui.set_scale(view.paper, vmath.vector3(0.7, 0.7, 1))
	gui.animate(view.paper, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, 0.3)
	v.view = view
	show_strip(v, nil)
	return view
end

function View.animate(view, dt)
	local d = view.drawing
	if not d then return end
	d.t = (d.t + dt) % d.spec.loop
	if d.t < dt then
		-- the loop starts over: the devils back as they were
		scoria.reset(d.s)
		if d.s2 then scoria.reset(d.s2) end
	end
	d.spec.frame(d, d.t)
	scoria.update(d.s, dt, d.st)
	if d.s2 then scoria.update(d.s2, dt, d.st2) end
end

local function advance(view)
	if view.i >= #view.pages then return true end
	view.i = view.i + 1
	show_page(view)
	return false
end

-- A tap: on CHIUDI it closes, on the button it goes on, elsewhere nothing
-- (true: it's over)
function View.premi(view, x, y)
	if view.tav and gui.is_enabled(view.tav) then
		return gui.pick_node(view.tav_next, x, y) and advance(view) or false
	end
	if gui.is_enabled(view.skip) and gui.pick_node(view.skip, x, y) then return true end
	if gui.pick_node(view.next, x, y) then return advance(view) end
	return false
end

-- A controller button: A goes on, B closes
function View.pad(view, n)
	if n == "b" then return true end
	if n == "a" then return advance(view) end
	return false
end

function View.close_view(view)
	gui.delete_node(view.radice)
	if view.tavola then ill.release(view.tavola, "tavola") end
	if view.owner.view == view then view.owner.view = nil end
	if view.owner.line then show_strip(view.owner, view.owner.line) end
end

return M
