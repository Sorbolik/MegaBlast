-- Tactical items in battle: placed traps and springboards, healing circles,
-- robots' shield and status effects, and the item icons in the bar. The
-- healing circle is vector-drawn (strumenti/grafica/cura.py, battle atlas);
-- the rest are shapes. The open parachute is drawn by the devil
-- (battle/scoria.lua).
--
--   local o = oggetti.new(colori)             -- colori[team]
--   oggetti.nodi(o)                            -- to put in the "mondo" node
--   oggetti.update(o, g, view, clock)          -- every frame, no allocation

local game = require "sim.game"
local config = require "sim.config"

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
	local n = gui.new_pie_node(vmath.vector3(0, 0, 0), vmath.vector3(d, d, 0))
	gui.set_adjust_mode(n, gui.ADJUST_FIT)
	gui.set_color(n, color)
	if parent then gui.set_parent(n, parent) end
	return n
end

local function pos(n, x, y)
	gui.set_position(n, vmath.vector3(x, y, 0))
end

-- Trap: a rhombus; springboard: a board on two legs
local function trap_name(r, parent)
	local n = gui_node(r * 1.2, r * 1.2, WHITE, parent)
	gui.set_euler(n, vmath.vector3(0, 0, 45))
	return n
end

local function springboard(hw, parent)
	local n = gui_node(hw * 2, 3, AMBER, parent)
	local a = gui_node(2, 5, AMBER, n)
	pos(a, -hw * 0.6, -4)
	local b = gui_node(2, 5, AMBER, n)
	pos(b, hw * 0.6, -4)
	return n
end

-- an image from the battle atlas, as big as in the world
local function image(nome, w, h, parent)
	local n = gui_node(w, h, OPAQUE, parent)
	gui.set_texture(n, "battaglia")
	gui.play_flipbook(n, nome)
	return n
end

-- Shield: a ring
local function ring_node(d, color, parent)
	local n = circle_shape(d, color, parent)
	gui.set_inner_radius(n, d * 0.42)
	return n
end

function M.new(palette)
	local o = { colori = palette, posed_ones = {}, cure = {}, shields = {}, flames = {}, frosts = {}, crepe = {},
		col = vmath.vector4(), size = vmath.vector3(), rot = vmath.vector3() }
	local h = game.DISEGNO_H
	for i = 1, config.MAX_PLACED do
		local root = gui_node(0, 0, WHITE)
		local t = trap_name(config.STATS.trap_radius, root)
		local b = springboard(config.TRAMPOLINE.half_w, root)
		gui.set_visible(root, false)
		gui.set_enabled(root, false)
		o.posed_ones[i] = { root = root, trap = t, tramp = b, id = nil }
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
		local s = ring_node(h * 1.9, WHITE)
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
	return o
end

-- The nodes to put in the world, in drawing order
function M.nodi(o)
	local list = {}
	for _, c in ipairs(o.cure) do list[#list + 1] = c.root end
	for _, p in ipairs(o.posed_ones) do list[#list + 1] = p.root end
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
				local c = o.colori[it.team]
				o.col.x, o.col.y, o.col.z = c.x, c.y, c.z
				o.col.w = it.armed and (0.6 + 0.4 * math.sin(clock * 6 + i)) or 0.35
				gui.set_color(p.trap, o.col)
				pos(p.root, it.x, it.y + it.r * 0.5)
			else
				pos(p.root, it.x, it.y + 6)
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
			o.col.x, o.col.y, o.col.z, o.col.w = c.x, c.y, c.z, 0.35 + 0.25 * rb.shield / config.SHIELD.hp
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
