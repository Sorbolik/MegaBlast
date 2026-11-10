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
-- pool of burning pitch (Pozza di Pece): a dark flattened pool with flames flickering over it
local POOLS, FLAMES = 4, 8
local PITCH = vmath.vector4(0.09, 0.06, 0.05, 0.92)
local EMBER = vmath.vector4(1, 0.78, 0.2, 0.85)
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
	local n = ui.disc(0, 0, d, color, parent)
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
-- board on a spring, flat, with a chevron pointing the way it launches
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
	ui.ring(n, d, d * 0.08)
	return n
end

function M.new(palette)
	local o = { colori = palette, posed_ones = {}, cure = {}, pools = {}, shields = {}, flames = {}, frosts = {}, crepe = {},
		snaps = {}, snap_i = 0, locks = {},
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
	for i = 1, POOLS do
		local root = gui_node(0, 0, WHITE)
		gui.set_enabled(root, false)
		local base = circle_shape(2, PITCH, root)
		local fl = {}
		for j = 1, FLAMES do fl[j] = circle_shape(9, j % 2 == 0 and EMBER or FIRE, root) end
		o.pools[i] = { root = root, base = base, flames = fl }
	end
	for i = 1, game.MAX_PLAYERS do
		-- the shield: a bubble with hexagon mesh, in the team colour
		-- feet locked by a trap: the closed jaws at the ankles
		local lock = image("attrezzo_tagliola_chiusa", SNAP_W * 0.75, SNAP_H * 0.75)
		gui.set_enabled(lock, false)
		o.locks[i] = lock
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
function M.nodes(o)
	local list = {}
	for _, c in ipairs(o.cure) do list[#list + 1] = c.root end
	for _, p in ipairs(o.pools) do list[#list + 1] = p.root end
	for _, p in ipairs(o.posed_ones) do list[#list + 1] = p.root end
	for _, n in ipairs(o.snaps) do list[#list + 1] = n end
	for _, n in ipairs(o.locks) do list[#list + 1] = n end
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
	-- pools of pitch: the flattened pool and flames dancing over it
	for i, pl in ipairs(o.pools) do
		local pool = g.pools[i]
		gui.set_enabled(pl.root, pool ~= nil)
		if pool then
			pos(pl.root, pool.x, pool.y)
			o.size.x, o.size.y, o.size.z = pool.r, pool.r * 0.16, 1
			gui.set_scale(pl.base, o.size)
			for j, f in ipairs(pl.flames) do
				local k = (j - 0.5) / FLAMES * 2 - 1
				local h = 0.55 + 0.45 * math.abs(math.sin(clock * 7 + j * 1.9 + i))
				pos(f, k * pool.r * 0.9, 5 + h * 7)
				o.size.x, o.size.y, o.size.z = 0.6 + 0.3 * h, 1.2 + h * 1.5, 1
				gui.set_scale(f, o.size)
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
				-- the chevron points where it launches (none while in flight)
				local d = it.flying and 0 or (it.dir or 0)
				o.size.x, o.size.y, o.size.z = d < 0 and -1 or 1, 1, 1
				gui.set_scale(p.arrow, o.size)
				pos(p.arrow, d * MOLLA_W * 0.32, MOLLA_H * 0.5 + 4)
				gui.set_enabled(p.arrow, d ~= 0)
			end
		end
	end
	-- shield around the robot, trap on its feet
	for i = 1, game.MAX_PLAYERS do
		local rb, v = g.robots[i], view[i]
		local locked = rb ~= nil and not rb.dead and rb.trapped ~= nil
		gui.set_enabled(o.locks[i], locked)
		if locked then pos(o.locks[i], v.x, v.y + SNAP_DY * 0.5) end
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
