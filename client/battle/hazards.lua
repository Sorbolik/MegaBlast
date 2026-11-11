-- The map hazards in battle (sim/hazards.lua, docs/pericoli_mappe.md): it only draws g.hz and
-- the map's data, the rules are in the simulation. The storm's arrow (which way the next gust
-- blows, all round long) is a pill of the HUD; the hail's shadows (where the stones will fall
-- at the end of the round) and the stones in flight are in the world. The mud is painted in
-- the map; the low gravity needs no drawing.
--
--   local o = hazards.new()                    -- all the nodes, hidden until a match has the hazard
--   hazards.nodes(o)                           -- the world nodes, to put in the "mondo" node
--   hazards.hud(o)                             -- the HUD root (or nil)
--   hazards.place(o, x, y)                     -- where the pill sits (the HUD's own coordinates)
--   hazards.update(o, g, clock)                -- every frame
--   hazards.gust(o)                            -- the "gust" event: the arrow flashes
-- The fire rain (Violenza) is the hail with orange stones; the false bridges (Frode) shine in
-- warning over the rectangle of the one that is about to fall (the crumbling is announced).

local config = require "sim.config"
local ui = require "ui.ui"
local T = require("lang.text").match

local M = {}

local SHADOW = vmath.vector4(0.04, 0.04, 0.05, 0.55)
local WARN = vmath.vector4(1, 0.82, 0.3, 0.9)
local ICE = vmath.vector4(0.86, 0.93, 0.98, 1)
local ICE_DARK = vmath.vector4(0.55, 0.65, 0.75, 1)
local PILL = vmath.vector4(0.06, 0.05, 0.09, 0.78)
local STORM = vmath.vector4(0.88, 0.37, 0.66, 1)   -- Lussuria's pink (docs/campagna_gironi.md)
local FIRE = vmath.vector4(1, 0.5, 0.16, 1)
local FIRE_LIGHT = vmath.vector4(1, 0.85, 0.4, 1)
local CHEVRONS = 3
local BRIDGES = 3

local function node(w, h, color, parent)
	local n = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(w, h, 0))
	gui.set_adjust_mode(n, gui.ADJUST_FIT)
	gui.set_color(n, color)
	if parent then gui.set_parent(n, parent) end
	return n
end

local P, S = vmath.vector3(), vmath.vector3()
local function pos(n, x, y)
	P.x, P.y = x, y
	gui.set_position(n, P)
end

-- a ">" of two strokes, pointing right
local function chevron(parent)
	local root = node(0, 0, vmath.vector4(1, 1, 1, 0), parent)
	for k, z in ipairs({ 42, -42 }) do
		local s = node(16, 4, STORM, root)
		pos(s, -3, k == 1 and 5 or -5)
		gui.set_euler(s, vmath.vector3(0, 0, -z))
	end
	return root
end

function M.new()
	local o = { marks = {}, stones = {}, flash = 0, bridges = {} }
	local h = config.HAIL
	for i = 1, math.max(h.count, config.FIRE_RAIN.count) do
		local root = node(0, 0, vmath.vector4(1, 1, 1, 1))
		gui.set_enabled(root, false)
		-- flat ellipses as wide as the blast: a dark shadow and a warning ring around it
		local w = h.blast.r * 3.2
		local shadow = ui.disc(0, 0, w, SHADOW, root)
		gui.set_size(shadow, vmath.vector3(w, w * 0.25, 0))
		local ring = ui.ring_node(0, 0, w * 1.2, 3, WARN, root)
		gui.set_size(ring, vmath.vector3(w * 1.2, w * 0.3, 0))
		o.marks[i] = { root = root, shadow = shadow, ring = ring }
		local stone = node(0, 0, vmath.vector4(1, 1, 1, 1))
		gui.set_enabled(stone, false)
		local trail = node(5, 70, vmath.vector4(0.86, 0.93, 0.98, 0.35), stone)
		pos(trail, 0, 44)
		local body = ui.disc(0, 0, h.r * 2.4, ICE_DARK, stone)
		local light = ui.disc(-2, 2, h.r * 1.4, ICE, stone)
		o.stones[i] = { root = stone, body = body, light = light }
	end
	for i = 1, BRIDGES do
		o.bridges[i] = node(0, 0, WARN)
		gui.set_enabled(o.bridges[i], false)
	end
	o.pill = node(0, 0, vmath.vector4(1, 1, 1, 1))
	gui.set_enabled(o.pill, false)
	node(176, 44, PILL, o.pill)
	o.label = ui.text(T.storm, -34, 0, 1.0, STORM, o.pill)
	o.chevrons = {}
	for i = 1, CHEVRONS do o.chevrons[i] = chevron(o.pill) end
	return o
end

function M.nodes(o)
	local list = {}
	for _, m in ipairs(o.marks) do list[#list + 1] = m.root end
	for _, s in ipairs(o.stones) do list[#list + 1] = s.root end
	for _, b in ipairs(o.bridges) do list[#list + 1] = b end
	return list
end

function M.hud(o)
	return o.pill
end

function M.place(o, x, y)
	if o.pill then pos(o.pill, x, y) end
end

function M.gust(o)
	o.flash = 1
end

function M.update(o, g, clock)
	local hz = g.hz
	local kind = g.hazard
	if o.kind ~= kind then
		-- another match: everything hidden, then only what its map has
		o.kind = kind
		for _, m in ipairs(o.marks) do gui.set_enabled(m.root, false) end
		for _, s in ipairs(o.stones) do
			gui.set_enabled(s.root, false)
			gui.set_color(s.body, kind == "fire_rain" and FIRE or ICE_DARK)
			gui.set_color(s.light, kind == "fire_rain" and FIRE_LIGHT or ICE)
		end
		for _, b in ipairs(o.bridges) do gui.set_enabled(b, false) end
		gui.set_enabled(o.pill, kind == "wind")
	end
	if kind == "bridges" and hz then
		-- the bridge that crumbles pulses over its rectangle until it falls
		for i, n in ipairs(o.bridges) do
			local b, t = g.bridges[i], hz.t[i]
			gui.set_enabled(n, b ~= nil and t ~= nil and t > 0)
			if b and t and t > 0 then
				pos(n, (b[1] + b[2]) / 2, (b[3] + b[4]) / 2)
				gui.set_size(n, vmath.vector3(b[2] - b[1], b[4] - b[3] + 6, 0))
				gui.set_color(n, vmath.vector4(1, 0.6, 0.2, 0.35 + 0.35 * math.abs(math.sin(clock * (4 + (150 - t) / 15)))))
			end
		end
	end
	if (kind == "hail" or kind == "fire_rain") and hz then
		local h = config.HAIL
		-- the shadows on the ground where the stones will fall, pulsing; the stones with a trail
		for i, m in ipairs(o.marks) do
			local x = hz.marks[i]
			gui.set_enabled(m.root, x ~= nil)
			if x then
				local y = g.terrain:ground_below(x, g.terrain.h * g.terrain.cell - 1) or 0
				pos(m.root, x, y)
				local pulse = 1 + 0.08 * math.sin(clock * 5 + i)
				S.x, S.y, S.z = pulse, pulse, 1
				gui.set_scale(m.shadow, S)
				gui.set_scale(m.ring, S)
			end
		end
		for i, s in ipairs(o.stones) do
			local st = hz.stones[i]
			gui.set_enabled(s.root, st ~= nil)
			if st then pos(s.root, st.x, st.y) end
		end
	elseif kind == "wind" and hz then
		-- the chevrons run the way of the next gust; they flash after one
		local dir = hz.dir
		o.flash = math.max(0, o.flash - 0.02)
		S.x, S.y, S.z = dir, 1, 1
		for i, c in ipairs(o.chevrons) do
			local u = (clock * 0.9 + i / CHEVRONS) % 1
			pos(c, 36 + dir * (u - 0.5) * 70, 0)
			gui.set_scale(c, S)
		end
		S.x, S.y = 1 + o.flash * 0.25, 1 + o.flash * 0.25
		gui.set_scale(o.pill, S)
	end
end

return M
