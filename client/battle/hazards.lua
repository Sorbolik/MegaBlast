-- The map hazards in battle (sim/hazards.lua, docs/pericoli_mappe.md): it only draws g.hz and
-- the map's data, the rules are in the simulation. The storm's arrow (which way the next gust
-- blows, all round long) is a pill of the HUD; the hail's shadows (where the stones will fall
-- at the end of the round) and the stones in flight are in the world, like the boulders rolling
-- (Avarizia), the water with the line it will rise to (Ira) and the tombs' flames and lids
-- (Eresia). The mud is painted in the map. The Limbo's lever: below.
--
--   local o = hazards.new()                    -- all the nodes, hidden until a match has the hazard
--   hazards.nodes(o)                           -- the world nodes, to put in the "mondo" node
--   hazards.hud(o)                             -- the HUD root (or nil)
--   hazards.place(o, x, y)                     -- where the pill sits (the HUD's own coordinates)
--   hazards.update(o, g, clock)                -- every frame
--   hazards.gust(o)                            -- the "gust" event: the arrow flashes
-- The fire rain (Violenza) is the hail with orange stones; the false bridges (Frode) shine in
-- warning over the rectangle of the one that is about to fall (the crumbling is announced).
-- The lever (Limbo) sits on its steel stud: a plate with the hinge and the handle, which snaps to
-- the other side at every flip (Codex's drawings, WB-099); during the second of stopped time a
-- ring with an arrow marks where each robot will land. At the flip the whole map turns half a turn
-- (spin) and the lever flies from its old stud to the new one.
--   hazards.painting(g)                        -- the map's painting: the Limbo upside down has its own
--   hazards.turned(g)                          -- is the Limbo's map turned half a turn (the background too)
--   hazards.flip(o, e, clock)                  -- the "flip" event: the turn and the lever's flight start
--   local a = hazards.spin(o, clock)           -- how much the world is still turned back (radians, 0: still)

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
local FIRE = vmath.vector4(1, 0.5, 0.16, 1)
local FIRE_LIGHT = vmath.vector4(1, 0.85, 0.4, 1)
local CHEVRONS = 3
local BRIDGES = 3
local ROCK = vmath.vector4(0.55, 0.42, 0.22, 1)
local ROCK_EDGE = vmath.vector4(0.1, 0.06, 0.03, 1)
local ROCK_LIGHT = vmath.vector4(0.78, 0.62, 0.34, 1)
local WATER = vmath.vector4(0.09, 0.22, 0.24, 0.62)
local CREST = vmath.vector4(0.45, 0.78, 0.76, 0.9)
local LID = vmath.vector4(0.2, 0.09, 0.07, 1)
local FLAME = vmath.vector4(1, 0.55, 0.15, 0.9)
local FLAME_CORE = vmath.vector4(1, 0.82, 0.3, 0.95)
local ROCKS, TOMBS, FLAMES = 4, 4, 3
-- the lever's drawings in the world (Codex, WB-099; numbers printed by tools/grafica/leva.py): the
-- plate as wide as the stud, the handle with the middle of its eye eye_x, eye_y from its top left
local LEVER_ART = { plate_w = 45, plate_h = 45.4, handle_w = 67.5, handle_h = 17.0, eye_x = 6.1, eye_y = 8.4 }
-- after the flip (Sergio, 27 Nov): the map turns half a turn around the middle of the screen in SPIN
-- seconds (game.gui_script turns the world and the background with M.spin), then the lever leaves
-- its old stud and flies in FLY seconds to the new one, while everyone still hangs in stopped time
local SPIN, FLY, FLY_ARC = 0.7, 0.55, 140
local LANDING = vmath.vector4(1, 0.88, 0.5, 0.95)
local LEVER_TILT = config.LEVER.tilt
local MAX_ROBOTS = 4
local WATER_W, WATER_DEPTH = 2400, 400

local function node(w, h, color, parent)
	local n = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(w, h, 0))
	gui.set_adjust_mode(n, gui.ADJUST_FIT)
	gui.set_color(n, color)
	if parent then gui.set_parent(n, parent) end
	return n
end

local P, S = vmath.vector3(), vmath.vector3()

-- an image of the battle atlas, as big as in the world
local function image(name, w, h, parent)
	local n = node(w, h, vmath.vector4(1, 1, 1, 1), parent)
	gui.set_texture(n, "battaglia")
	gui.play_flipbook(n, name)
	return n
end
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
	-- the lever (WB-099, tools/grafica/leva.py): the handle turns around its eye on the hinge, the
	-- plate sits over it on the stud
	o.lever = node(0, 0, vmath.vector4(1, 1, 1, 1))
	gui.set_enabled(o.lever, false)
	o.handle = node(0, 0, vmath.vector4(1, 1, 1, 1), o.lever)
	local handle = image("leva_manico", LEVER_ART.handle_w, LEVER_ART.handle_h, o.handle)
	pos(handle, LEVER_ART.handle_w / 2 - LEVER_ART.eye_x, LEVER_ART.eye_y - LEVER_ART.handle_h / 2)
	image("leva_piastra", LEVER_ART.plate_w, LEVER_ART.plate_h, o.lever)
	o.tilt = LEVER_TILT
	-- where each one lands while time is stopped: a ring on the ground and an arrow above it
	o.landing = {}
	for i = 1, MAX_ROBOTS do
		local root = node(0, 0, vmath.vector4(1, 1, 1, 1))
		gui.set_enabled(root, false)
		local ring = ui.ring_node(0, 0, 44, 4, LANDING, root)
		gui.set_size(ring, vmath.vector3(44, 14, 0))
		local arrow = node(14, 14, LANDING, root)
		gui.set_euler(arrow, vmath.vector3(0, 0, 45))
		pos(arrow, 0, 22)
		local shaft = node(5, 22, LANDING, root)
		pos(shaft, 0, 36)
		o.landing[i] = { root = root, arrow = arrow, shaft = shaft }
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
	for _, r in ipairs(o.rocks) do list[#list + 1] = r.root end
	list[#list + 1] = o.water
	for _, t in ipairs(o.tombs) do list[#list + 1] = t.root end
	list[#list + 1] = o.lever
	for _, l in ipairs(o.landing) do list[#list + 1] = l.root end
	return list
end

local function ease(t)
	return t < 0.5 and 2 * t * t or 1 - (2 - 2 * t) * (2 - 2 * t) / 2
end

function M.flip(o, e, clock)
	o.flip_clock, o.from = clock, e.from
end

function M.spin(o, clock)
	local t = o.flip_clock and (clock - o.flip_clock) / SPIN or 1
	if t >= 1 then return 0 end
	return -math.pi * (1 - ease(math.max(t, 0)))
end

function M.hud(o)
	return o.pill
end

function M.place(o, x, y)
	if o.pill then pos(o.pill, x, y) end
end

-- The terrain painting to show (client/paintings/maps): the map's, or its upside down one
-- is the map turned half a turn (the Limbo's lever)? The background turns with it
function M.turned(g)
	return g.hazard == "lever" and g.hz ~= nil and g.hz.flip == 1
end

function M.painting(g)
	if g.hazard == "lever" and g.hz and g.hz.flip == 1 then return g.map .. "_sotto" end
	return g.map
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
		for _, r in ipairs(o.rocks) do gui.set_enabled(r.root, false) end
		for _, t in ipairs(o.tombs) do gui.set_enabled(t.root, false) end
		gui.set_enabled(o.water, kind == "water")
		gui.set_enabled(o.lever, kind == "lever")
		for _, l in ipairs(o.landing) do gui.set_enabled(l.root, false) end
	end
	if kind == "lever" and hz then
		-- the handle leans to one side of its face, and snaps to the other at every flip
		local x, y, dx, dy = sim_hazards.lever_spot(g, hz, hz.at)
		local want = hz.n % 2 == 0 and LEVER_TILT or -LEVER_TILT
		local angle = math.atan2(dy, dx) + want
		local t = o.flip_clock and hz.freeze > 0 and clock - o.flip_clock or nil
		if t and o.from and o.from >= 1 and t < SPIN + FLY then
			-- just flipped: the lever is on its old stud (turned with the map), then flies to the new one
			local fx, fy, fdx, fdy = sim_hazards.lever_spot(g, hz, o.from)
			local a0 = math.atan2(fdy, fdx) - want
			local k = ease(math.max(0, t - SPIN) / FLY)
			local a1 = angle + 2 * math.pi
			x, y = fx + (x - fx) * k, fy + (y - fy) * k + math.sin(math.pi * k) * FLY_ARC
			angle = a0 + (a1 - a0) * k
			o.tilt = want
		else
			o.tilt = o.tilt + (want - o.tilt) * 0.35
			angle = math.atan2(dy, dx) + o.tilt
		end
		pos(o.lever, x, y)
		S.x, S.y, S.z = 0, 0, math.deg(angle)
		gui.set_euler(o.handle, S)
		for i, l in ipairs(o.landing) do
			local ly = hz.freeze > 0 and hz.ly[i] or -1
			local rb = g.robots[i]
			local on = ly >= 0 and rb ~= nil and not rb.dead
			gui.set_enabled(l.root, on)
			if on then
				pos(l.root, hz.lx[i], ly)
				pos(l.arrow, 0, 22 + 5 * math.sin(clock * 9))
				pos(l.shaft, 0, 36 + 5 * math.sin(clock * 9))
			end
		end
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
