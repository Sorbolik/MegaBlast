-- Tactical items in battle: placed traps and springboards, healing circles,
-- robots' shield and status effects, and the item icons in the bar. The
-- healing circle (strumenti/grafica/cura.py), traps, springboards and the
-- shield bubble (strumenti/grafica/attrezzi.py) are vector-drawn in the battle
-- atlas; the status effects are shapes. The open parachute is drawn by the
-- devil (battle/scoria.lua).
--
--   local o = oggetti.new(colori)             -- colori[team]
--   oggetti.nodi(o)                            -- to put in the "mondo" node
--   oggetti.update(o, g, view, clock)          -- every frame, no allocation
--   oggetti.snap(o, x, y)                      -- a trap snapped shut there

local game = require "sim.game"
local config = require "sim.config"
local ui = require "ui.ui"

local M = {}

local AMBER = vmath.vector4(1, 0.72, 0.25, 1)
local WHITE = vmath.vector4(1, 1, 1, 0.9)
local OPAQUE = vmath.vector4(1, 1, 1, 1)
-- status effects: flame on the head, cold ring at the feet, crack on the chest
local FIRE = vmath.vector4(1, 0.45, 0.1, 0.7)
local FROST = vmath.vector4(0.45, 0.8, 1, 0.8)
local CRACK = vmath.vector4(1, 1, 1, 0.75)
-- healing circle: a stone ring on the ground with glowing runes (cura.py, 6
-- pixels per unit), a heart floating above and sparks rising
local HEAL_PX = 6
local SPARKS = 3

local function gui_node(w, h, color, parent)
	local n = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(w, h, 0))
	gui.set_adjust_mode(n, gui.ADJUST_FIT)
	gui.set_color(n, color)
	if parent then gui.set_parent(n, parent) end
	return n
end

local function circle_shape(d, color, parent)
	local n = ui.disco(0, 0, d, color, parent)
	gui.set_adjust_mode(n, gui.ADJUST_FIT)
	return n
end

-- one vector for every position: no new vector3 each frame (OPT-001 B2)
local P = vmath.vector3()
local function pos(n, x, y)
	P.x, P.y = x, y
	gui.set_position(n, P)
end

-- an image from the battle atlas, as big as in the world
local function image(nome, w, h, parent)
	local n = gui_node(w, h, OPAQUE, parent)
	gui.set_texture(n, "battaglia")
	gui.play_flipbook(n, nome)
	return n
end

-- Trap: the open jaw trap lying on the ground (strumenti/grafica/attrezzi.py),
-- with its plate lit in the team colour; springboard: the Molla, a padded
-- board on a spring, leaning the way it launches, with a chevron pointing there
local TRAP_W, TRAP_H, TRAP_DY = 28, 8.6, 2.7
local MOLLA_W, MOLLA_H, MOLLA_DY = 39.2, 15.4, 6.1
local SNAP_W, SNAP_H, SNAP_DY = 20.8, 16.6, 6.7
local SNAPS = 2

local function trap_name(parent)
	local n = image("attrezzo_tagliola", TRAP_W, TRAP_H, parent)
	local light = image("attrezzo_tagliola_luce", TRAP_W, TRAP_H, n)
	return n, light
end

local function springboard(parent)
	local n = image("attrezzo_molla", MOLLA_W, MOLLA_H, parent)
	local arrow = gui_node(0, 0, AMBER, n)
	for k, z in ipairs({ 40, -40 }) do
		local s = gui_node(7, 2, AMBER, arrow)
		pos(s, 0, k == 1 and 2 or -2)
		gui.set_euler(s, vmath.vector3(0, 0, -z))
	end
	return n, arrow
end

-- Shield: a ring
local function ring_node(d, color, parent)
	local n = circle_shape(d, color, parent)
	ui.anello(n, d, d * 0.08)
	return n
end

function M.new(palette)
	local o = { colori = palette, posed_ones = {}, cure = {}, shields = {}, flames = {}, frosts = {}, crepe = {},
		snaps = {}, snap_i = 0,
		col = vmath.vector4(), size = vmath.vector3(), rot = vmath.vector3() }
	local h = game.DISEGNO_H
	for i = 1, config.MAX_PLACED do
		local root = gui_node(0, 0, WHITE)
		local t, light = trap_name(root)
		local b, arrow = springboard(root)
		gui.set_visible(root, false)
		gui.set_enabled(root, false)
		o.posed_ones[i] = { root = root, trap = t, light = light, tramp = b, arrow = arrow, id = nil }
	end
	for i = 1, config.HEAL.max do
		local root = gui_node(0, 0, OPAQUE)
		gui.set_visible(root, false)
		local a = image("cura_anello", 336 / HEAL_PX, 124 / HEAL_PX, root)
		local sparks = {}
		for j = 1, SPARKS do sparks[j] = image("cura_scintilla", 8, 8, root) end
		local heart = image("cura_cuore", 20, 21, root)
		gui.set_enabled(root, false)
		o.cure[i] = { root = root, ring_node = a, cuore = heart, sparks = sparks }
	end
	for i = 1, game.MAX_PLAYERS do
		-- the shield: a bubble with hexagon mesh, in the team colour
		local s = image("attrezzo_bolla", h * 1.9, h * 1.9)
		gui.set_enabled(s, false)
		o.shields[i] = s
		local f = circle_shape(h * 0.5, FIRE)
		gui.set_enabled(f, false)
		o.flames[i] = f
		local ge = ring_node(h * 1.4, FROST)
		gui.set_scale(ge, vmath.vector3(1, 0.3, 1))
		gui.set_enabled(ge, false)
		o.frosts[i] = ge
		local c = gui_node(0, 0, CRACK)
		gui.set_euler(gui_node(2, h * 0.7, CRACK, c), vmath.vector3(0, 0, 30))
		gui.set_euler(gui_node(2, h * 0.5, CRACK, c), vmath.vector3(0, 0, -40))
		gui.set_enabled(c, false)
		o.crepe[i] = c
	end
	-- the trap that snaps shut (it disappears from the simulation at once)
	for i = 1, SNAPS do
		local n = image("attrezzo_tagliola_chiusa", SNAP_W, SNAP_H)
		gui.set_enabled(n, false)
		o.snaps[i] = n
	end
	return o
end

local function hide(n) gui.set_enabled(n, false) end

-- A trap snapped at (x, y): the closed jaws pop up, stay a moment and fade
function M.snap(o, x, y)
	o.snap_i = o.snap_i % SNAPS + 1
	local n = o.snaps[o.snap_i]
	gui.cancel_animations(n)
	gui.set_enabled(n, true)
	pos(n, x, y + SNAP_DY)
	gui.set_color(n, OPAQUE)
	gui.set_scale(n, vmath.vector3(0.5, 0.5, 1))
	gui.animate(n, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, 0.18)
	gui.animate(n, "color.w", 0, gui.EASING_INQUAD, 0.5, 0.7, hide)
end

-- The nodes to put in the world, in drawing order
function M.nodi(o)
	local list = {}
	for _, c in ipairs(o.cure) do list[#list + 1] = c.root end
	for _, p in ipairs(o.posed_ones) do list[#list + 1] = p.root end
	for _, n in ipairs(o.snaps) do list[#list + 1] = n end
	for _, n in ipairs(o.shields) do list[#list + 1] = n end
	for _, n in ipairs(o.frosts) do list[#list + 1] = n end
	for _, n in ipairs(o.crepe) do list[#list + 1] = n end
	for _, n in ipairs(o.flames) do list[#list + 1] = n end
	return list
end


function M.update(o, g, view, clock)
	-- healing circles: the ring pulses, the heart floats and sways, the
	-- sparks rise from the ring and fade
	for i, c in ipairs(o.cure) do
		local h = g.heals[i]
		gui.set_enabled(c.root, h ~= nil)
		if h then
			pos(c.root, h.x, h.y)
			local p = 1 + 0.04 * math.sin(clock * 2.5 + i)
			o.size.x, o.size.y = p, p
			o.size.z = 1
			gui.set_scale(c.ring_node, o.size)
			pos(c.cuore, 0, 18 + 3 * math.sin(clock * 2.2 + i))
			o.rot.z = 8 * math.sin(clock * 1.7 + i)
			gui.set_euler(c.cuore, o.rot)
			for j, sc in ipairs(c.sparks) do
				local u = (clock * 0.45 + j / SPARKS + i * 0.37) % 1
				local a = math.sin(u * math.pi)
				pos(sc, math.sin(j * 2.1 + i) * 16 + math.sin(clock * 2 + j) * 2, 2 + u * 30)
				o.col.x, o.col.y, o.col.z, o.col.w = 1, 1, 1, a
				gui.set_color(sc, o.col)
				o.size.x, o.size.y = 0.5 + 0.6 * a, 0.5 + 0.6 * a
				gui.set_scale(sc, o.size)
			end
		end
	end
	-- traps (in the team color, they blink when armed) and springboards
	for i, p in ipairs(o.posed_ones) do
		local it = g.placed[i]
		gui.set_enabled(p.root, it ~= nil)
		if it then
			gui.set_enabled(p.trap, it.kind == "trap")
			gui.set_enabled(p.tramp, it.kind == "trampoline")
			if it.kind == "trap" then
				-- not armed yet: grey plate; armed: the plate glows in the team colour
				local c = o.colori[it.team]
				if it.armed then
					o.col.x, o.col.y, o.col.z, o.col.w = c.x, c.y, c.z, 0.75 + 0.25 * math.sin(clock * 6 + i)
				else
					o.col.x, o.col.y, o.col.z, o.col.w = 0.5, 0.5, 0.5, 0.8
				end
				gui.set_color(p.light, o.col)
				pos(p.root, it.x, it.y + TRAP_DY)
			else
				pos(p.root, it.x, it.y + MOLLA_DY)
				-- leaning towards where it launches; in flight it spins flat
				local d = it.flying and 0 or (it.dir or 0)
				o.rot.z = -16 * d
				gui.set_euler(p.tramp, o.rot)
				o.size.x, o.size.y, o.size.z = d < 0 and -1 or 1, 1, 1
				gui.set_scale(p.arrow, o.size)
				pos(p.arrow, d * MOLLA_W * 0.32, MOLLA_H * 0.5 + 4)
				gui.set_enabled(p.arrow, d ~= 0)
			end
		end
	end
	-- shield around the robot
	for i = 1, game.MAX_PLAYERS do
		local rb, v = g.robots[i], view[i]
		local shield = rb ~= nil and not rb.dead and rb.shield ~= nil
		gui.set_enabled(o.shields[i], shield)
		if shield then
			local c = o.colori[rb.team]
			o.col.x, o.col.y, o.col.z, o.col.w = c.x, c.y, c.z, 0.3 + 0.3 * rb.shield / config.SHIELD.hp
				+ 0.05 * math.sin(clock * 3 + i)
			gui.set_color(o.shields[i], o.col)
			pos(o.shields[i], v.x, v.y + game.DISEGNO_H / 2)
		end
		-- status effects
		local st = rb ~= nil and not rb.dead and rb.status or nil
		local burn, slow, cracked = st and st.burn, st and st.slow, st and st.cracked
		gui.set_enabled(o.flames[i], burn ~= nil)
		if burn then
			-- the flame flickers
			local d = game.DISEGNO_H * (0.32 + 0.06 * math.sin(clock * 17 + i * 2))
			o.size.x, o.size.y = d, d * 1.3
			gui.set_size(o.flames[i], o.size)
			pos(o.flames[i], v.x, v.y + game.DISEGNO_H * 1.05)
		end
		gui.set_enabled(o.frosts[i], slow ~= nil)
		if slow then pos(o.frosts[i], v.x, v.y + 1) end
		gui.set_enabled(o.crepe[i], cracked ~= nil)
		if cracked then pos(o.crepe[i], v.x, v.y + game.DISEGNO_H * 0.55) end
	end
end

return M
