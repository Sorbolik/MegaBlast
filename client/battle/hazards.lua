-- The map hazards in battle (sim/hazards.lua, docs/pericoli_mappe.md): it only draws g.hz and
-- the map's data, the rules are in the simulation. The storm's arrow (which way the next gust
-- blows, all round long) is a pill of the HUD; the hail's shadows (where the stones will fall
-- at the end of the round) and the stones in flight are in the world, like the boulders rolling
-- (Avarizia), the water with the line it will rise to (Ira) and the tombs' flames and lids
-- (Eresia). The mud is painted in the map; the low gravity needs no drawing.
--
--   local o = hazards.new()                    -- all the nodes, hidden until a match has the hazard
--   hazards.nodes(o)                           -- the world nodes, to put in the "mondo" node
--   hazards.hud(o)                             -- the HUD root (or nil)
--   hazards.place(o, x, y)                     -- where the pill sits (the HUD's own coordinates)
--   hazards.update(o, g, clock)                -- every frame
--   hazards.gust(o)                            -- the "gust" event: the arrow flashes

local config = require "sim.config"
local sim_hazards = require "sim.hazards"
local ui = require "ui.ui"
local T = require("lang.text").match

local M = {}

local SHADOW = vmath.vector4(0.04, 0.04, 0.05, 0.55)
local WARN = vmath.vector4(1, 0.82, 0.3, 0.9)
local ICE = vmath.vector4(0.86, 0.93, 0.98, 1)
local ICE_DARK = vmath.vector4(0.55, 0.65, 0.75, 1)
local PILL = vmath.vector4(0.06, 0.05, 0.09, 0.78)
local STORM = vmath.vector4(0.88, 0.37, 0.66, 1)   -- Lussuria's pink (docs/campagna_gironi.md)
local CHEVRONS = 3
local ROCK = vmath.vector4(0.55, 0.42, 0.22, 1)
local ROCK_EDGE = vmath.vector4(0.1, 0.06, 0.03, 1)
local ROCK_LIGHT = vmath.vector4(0.78, 0.62, 0.34, 1)
local WATER = vmath.vector4(0.09, 0.22, 0.24, 0.62)
local CREST = vmath.vector4(0.45, 0.78, 0.76, 0.9)
local LID = vmath.vector4(0.2, 0.09, 0.07, 1)
local FLAME = vmath.vector4(1, 0.55, 0.15, 0.9)
local FLAME_CORE = vmath.vector4(1, 0.82, 0.3, 0.95)
local ROCKS, TOMBS, FLAMES = 4, 4, 3
local WATER_W, WATER_DEPTH = 2400, 400

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
	local o = { marks = {}, stones = {}, flash = 0 }
	local h = config.HAIL
	for i = 1, h.count do
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
	-- the boulders: a dark disc with a light spot that turns with the way they roll
	o.rocks = {}
	for i = 1, ROCKS do
		local root = node(0, 0, vmath.vector4(1, 1, 1, 1))
		gui.set_enabled(root, false)
		local d = config.BOULDER.r * 2
		ui.disc(0, 0, d + 6, ROCK_EDGE, root)
		ui.disc(0, 0, d, ROCK, root)
		local spin = node(0, 0, vmath.vector4(1, 1, 1, 1), root)
		ui.disc(config.BOULDER.r * 0.4, config.BOULDER.r * 0.3, d * 0.3, ROCK_LIGHT, spin)
		ui.disc(-config.BOULDER.r * 0.35, -config.BOULDER.r * 0.4, d * 0.2, ROCK_LIGHT, spin)
		o.rocks[i] = { root = root, spin = spin }
	end
	-- the water, its bright crest and the line it will rise to
	o.water = node(0, 0, vmath.vector4(1, 1, 1, 1))
	gui.set_enabled(o.water, false)
	o.water_body = node(WATER_W, WATER_DEPTH, WATER, o.water)
	o.water_crest = node(WATER_W, 6, CREST, o.water)
	o.water_next = node(WATER_W, 3, WARN, o.water)
	-- the tombs: a lid when closed, flames when open
	o.tombs = {}
	for i = 1, TOMBS do
		local root = node(0, 0, vmath.vector4(1, 1, 1, 1))
		gui.set_enabled(root, false)
		local lid = node(10, 10, LID, root)
		local flames = {}
		for k = 1, FLAMES do
			local f = node(18, 18, FLAME, root)
			gui.set_euler(f, vmath.vector3(0, 0, 45))
			local core = node(9, 9, FLAME_CORE, f)
			flames[k] = { f = f, core = core }
		end
		o.tombs[i] = { root = root, lid = lid, flames = flames }
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
	for _, r in ipairs(o.rocks) do list[#list + 1] = r.root end
	list[#list + 1] = o.water
	for _, t in ipairs(o.tombs) do list[#list + 1] = t.root end
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
		for _, s in ipairs(o.stones) do gui.set_enabled(s.root, false) end
		gui.set_enabled(o.pill, kind == "wind")
		for _, r in ipairs(o.rocks) do gui.set_enabled(r.root, false) end
		for _, t in ipairs(o.tombs) do gui.set_enabled(t.root, false) end
		gui.set_enabled(o.water, kind == "water")
	end
	if kind == "hail" and hz then
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
	elseif kind == "boulders" and hz then
		for i, r in ipairs(o.rocks) do
			local b = hz.rocks[i]
			gui.set_enabled(r.root, b ~= nil)
			if b then
				pos(r.root, b.x, b.y + config.BOULDER.r)
				S.x, S.y, S.z = 0, 0, -b.x / config.BOULDER.r * 57.3
				gui.set_euler(r.spin, S)
			end
		end
	elseif kind == "water" and hz then
		-- the body goes from WATER_DEPTH under the map up to the surface; the dashed line is
		-- where the next rise will bring it
		local level = hz.level
		local w = (g.terrain.w - 2 * g.terrain.ox) * g.terrain.cell / 2
		pos(o.water_body, w, (level - WATER_DEPTH) / 2)
		S.x, S.y, S.z = WATER_W, level + WATER_DEPTH, 1
		gui.set_size(o.water_body, S)
		pos(o.water_crest, w, level + math.sin(clock * 2) * 2)
		gui.set_enabled(o.water_next, hz.rise == true)
		pos(o.water_next, w, level + config.WATER.step)
	elseif kind == "tombs" and hz then
		for i, t in ipairs(o.tombs) do
			local m = g.tombs[i]
			gui.set_enabled(t.root, m ~= nil)
			if m then
				local open = sim_hazards.tomb_open(hz, i)
				local cx, floor = (m[1] + m[2]) / 2, m[4] - 15
				pos(t.root, cx, floor)
				S.x, S.y, S.z = m[2] - m[1] + 24, 10, 1
				gui.set_size(t.lid, S)
				gui.set_enabled(t.lid, not open)
				for k, f in ipairs(t.flames) do
					gui.set_enabled(f.f, open)
					local u = (k - 2) * (m[2] - m[1]) / 3.5
					pos(f.f, u, 8 + 5 * math.sin(clock * 7 + k * 2))
				end
			end
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
