-- Map hazards: what a map does by itself, besides the robots' weapons. A map
-- (sim/maps.lua) asks for them with plain data:
--   gravity = 0.55                   the gravity of the whole match, times the usual one
--   mud = { { x0, x1, y0, y1 } }     world rectangles: a robot standing on the ground inside one is slowed
--   blood = { { x0, x1, y0, y1 } }   the same, but it sets the robot alight (status burn)
--   hazard = "wind" | "hail" | "fire_rain" | "bridges" | "ice" | "boulders" | "water" | "tombs"
--                                    a hazard of the rounds (KINDS below)
--   bridges = { { x0, x1, y0, y1 } } (hazard "bridges") the false bridges: the world rectangle of each
--   ice = true | { rects }           (hazard "ice") where it slides: everywhere, or in these rectangles
--   wings = true                     (hazard "ice") the end of the round pushes everyone away from the centre
--   rocks = { { x, dir } }           boulders: where one starts at the end of each round, and the way it rolls
--   water = { y }                    the starting level of the rising water (world y)
--   tombs = { { x0, x1, y0, y1 } }   the tombs, world rectangles; the ones that are open burn whoever is in
-- The state of a hazard of the rounds lives only in g.hz, a table of numbers and
-- lists: the server sends it as it is (state field "hz", server/net.lua) and the
-- client copies it back, so whoever draws it (battle/hazards.lua) reads g.hz and
-- the map, never the rules. Everything random uses the match generator, so
-- server and client draw the same.
--
-- To add a hazard of the rounds: a table in KINDS with
--   setup(g, hz)      the match starts (g.hz = {} is passed to fill)
--   round_end(g, hz)  the last turn of a round is over, the robots have settled and
--                     the next turn has not started yet
--   tick(g, hz)       every tick (also in the bot's tries, where hz is nil: it does not see it)
--   busy(g, hz)       true while something is still in the air: the turn does not end under it
--   risk(g, hz)       (optional) returns f(rb): the hit points that robot would lose if it were left
--                     where it is until the next round end (M.DEATH or more: it dies there). It is
--                     how the bots (sim/bot.lua) see the hazard: they read nothing else of it
-- and name it in a map. Its numbers go in config.lua, its drawing in
-- battle/hazards.lua, its field in server/net.lua (hz needs nothing more).
-- Details and the three of the first circles: docs/pericoli_mappe.md.

local C = require "sim.config"

local M = {}

-- Three x on solid ground, not too close to each other
local function pick_columns(g, count, margin, gap)
	local width, list = g.terrain.cell * (g.terrain.w - 2 * g.terrain.ox), {}
	for _ = 1, count do
		local x
		for _ = 1, 20 do
			x = math.floor(margin + g.rng:next() * (width - 2 * margin))
			local ok = g.terrain:ground_below(x, g.terrain.h * g.terrain.cell - 1) ~= nil
			for _, o in ipairs(list) do
				if math.abs(o - x) < gap then ok = false end
			end
			if ok then break end
		end
		list[#list + 1] = x
	end
	table.sort(list)
	return list
end


-- What a risk function answers for a place that surely kills
M.DEATH = 1000

-- Would a push of dist units that way (a gust, the wings, a slide) leave a robot standing at
-- x, y over the void? It stops at a wall, like g:shove
local function pushed_off(g, x, y, dir, dist)
	local t, cell = g.terrain, g.terrain.cell
	for _ = 1, math.floor(dist / cell) do
		if t:solid(x + dir * cell, y + 30) then break end
		x = x + dir * cell
	end
	local gb = t:ground_below(x, y + 12)
	return gb == nil or y - gb > 300
end

local function map_middle(g)
	return g.terrain.cell * (g.terrain.w - 2 * g.terrain.ox) / 2
end

local KINDS = {}

-- The storm (Lussuria, Sergio's "eccezione al niente vento"): hz.dir (1 right, -1
-- left) is the way the next gust blows, shown all round long; when the round ends
-- the gust moves every robot (not the shots) a step that way, stopping at walls
KINDS.wind = {
	setup = function(g, hz)
		hz.dir = g.rng:next() < 0.5 and -1 or 1
	end,
	round_end = function(g, hz)
		local dir, list = hz.dir, {}
		for _, rb in ipairs(g.robots) do
			if not rb.dead and not rb.gone and not rb.trapped then list[#list + 1] = rb end
		end
		-- the ones downwind first, so nobody is blocked by the one in front of them
		table.sort(list, function(a, b)
			if a.x ~= b.x then return a.x * dir > b.x * dir end
			return a.id < b.id
		end)
		for _, rb in ipairs(list) do
			for _ = 1, C.WIND.step / g.terrain.cell do
				if not g:shove(rb, dir * g.terrain.cell) then break end
			end
		end
		g:emit({ type = "gust", dir = dir })
		hz.dir = g.rng:next() < 0.5 and -1 or 1
	end,
	risk = function(g, hz)
		return function(rb)
			return pushed_off(g, rb.x, rb.y, hz.dir, C.WIND.step) and M.DEATH or 0
		end
	end,
}

-- The hail (Gola): hz.marks are the places where the stones will fall when the round
-- ends (a shadow shows them all round long); hz.stones the ones falling now, each
-- blows up on the first terrain or robot it meets. The fire rain (Violenza) is the same
-- with its own numbers (C.FIRE_RAIN) and the blast sets alight (weapon "fire_rain").
local function hail_kind(cfg, weapon, fire)
	local function new_marks(g)
		return pick_columns(g, cfg.count, cfg.margin, cfg.gap)
	end
	return {
		setup = function(g, hz)
			hz.marks, hz.stones = new_marks(g), {}
		end,
		round_end = function(g, hz)
			for _, x in ipairs(hz.marks) do
				hz.stones[#hz.stones + 1] = { x = x, y = g.terrain.h * g.terrain.cell + cfg.r * 2 }
			end
			hz.marks = new_marks(g)
			g:emit({ type = "hail", fire = fire })
		end,
		tick = function(g, hz)
			local stones, cell = hz.stones, g.terrain.cell
			local i = 1
			while i <= #stones do
				local s, hit = stones[i], false
				local dy = cfg.speed / 60
				for _ = 1, math.ceil(dy / cell) do
					s.y = s.y - dy / math.ceil(dy / cell)
					if g.terrain:solid(s.x, s.y - cfg.r) then hit = true end
					for _, rb in ipairs(g.robots) do
						if not rb.dead and g.hurt_at(rb, s.x, s.y, cfg.r) then hit = true end
					end
					if hit then break end
				end
				if hit then
					table.remove(stones, i)
					g:explode(s.x, s.y, nil, cfg.blast, weapon)
				else
					i = i + 1
				end
			end
		end,
		busy = function(g, hz)
			return #hz.stones > 0
		end,
		-- the stones that will fall (marks) and the ones falling (stones): each lands on the first
		-- terrain of its column, the damage falls off with the distance from there
		risk = function(g, hz)
			local t, top = g.terrain, g.terrain.h * g.terrain.cell - 1
			local impacts = {}
			for _, x in ipairs(hz.marks) do
				impacts[#impacts + 1] = { x = x, y = (t:ground_below(x, top) or 0) + cfg.r }
			end
			for _, s in ipairs(hz.stones) do
				impacts[#impacts + 1] = { x = s.x, y = (t:ground_below(s.x, s.y) or 0) + cfg.r }
			end
			local B = cfg.blast
			return function(rb)
				local hp = 0
				for _, m in ipairs(impacts) do
					local dx, dy = rb.x - m.x, rb.y + g.HURT_Y - m.y
					local d = math.sqrt(dx * dx + dy * dy)
					if d < B.damage_r then
						hp = hp + B.damage_min + (B.damage - B.damage_min) * (1 - d / B.damage_r)
						if fire then hp = hp + C.STATUS.burn.damage end
					end
				end
				return hp
			end
		end,
	}
end

KINDS.hail = hail_kind(C.HAIL, nil, false)
KINDS.fire_rain = hail_kind(C.FIRE_RAIN, "fire_rain", true)

-- The false bridges (Frode): hz.t[i] is the ticks left before bridge i falls (0 = quiet, -1 =
-- fallen), hz.solid[i] how many cells it had. It starts to crumble when a robot stands on it
-- or when something has taken cells off it (a shot); the fall carves its rectangle out,
-- in small circles ("carve" events: the client digs the same circles).
local function bridge_cells(g, b)
	local c, n = g.terrain.cell, 0
	for cy = math.floor(b[3] / c), math.floor((b[4] - 1) / c) do
		for cx = math.floor(b[1] / c), math.floor((b[2] - 1) / c) do
			if g.terrain:get(cx, cy) ~= 0 then n = n + 1 end
		end
	end
	return n
end

local function bridge_stood(g, b)
	for _, rb in ipairs(g.robots) do
		if rb.grounded and not rb.dead and rb.x >= b[1] and rb.x <= b[2] and rb.y >= b[4] - 2 and rb.y <= b[4] + 6 then return true end
	end
	return false
end

KINDS.bridges = {
	setup = function(g, hz)
		hz.t, hz.solid = {}, {}
		for i, b in ipairs(g.bridges) do
			hz.t[i], hz.solid[i] = 0, bridge_cells(g, b)
		end
	end,
	tick = function(g, hz)
		for i, b in ipairs(g.bridges) do
			local t = hz.t[i]
			if t == 0 then
				if bridge_stood(g, b) or bridge_cells(g, b) < hz.solid[i] then
					hz.t[i] = C.BRIDGE.delay
					g:emit({ type = "bridge_shaking", bridge = i })
				end
			elseif t > 0 then
				if t > 1 then
					hz.t[i] = t - 1
				else
					hz.t[i] = -1
					-- two rows of small circles, together a bit taller than the bridge (its underside is
					-- toothed): the client digs the same circles
					local r = 9
					for _, y in ipairs({ b[3] - 1, b[4] - 6 }) do
						local x = b[1] + r * 0.5
						while x < b[2] - r * 0.4 do
							local r0, r1 = g.terrain:carve(x, y, r)
							g:emit({ type = "carve", x = x, y = y, r = r, row_min = r0, row_max = r1 })
							x = x + r
						end
					end
					g:emit({ type = "collapse", bridge = i })
				end
			end
		end
	end,
	-- whoever ends the turn on a bridge that still stands falls with it
	risk = function(g, hz)
		return function(rb)
			for i, b in ipairs(g.bridges) do
				if hz.t[i] >= 0 and rb.x >= b[1] and rb.x <= b[2] and rb.y >= b[4] - 20 and rb.y <= b[4] + 20 then
					return M.DEATH
				end
			end
			return 0
		end
	end,
}

-- The ice (Tradimento): whoever is on the ground on it and stops walking keeps sliding
-- (hz.vel[robot], world units per tick, shrinking; hz.prev[robot] where it was last tick, to
-- tell walking from sliding). A wall or another robot stops the slide.
-- With g.wings (Lucifero's six wings) the end of every round also pushes everyone away from
-- the middle of the map, a step, stopping at walls: that is the wind of the storm but outward.
local function on_ice(g, rb)
	if g.ice == true then return true end
	for _, m in ipairs(g.ice) do
		if rb.x >= m[1] and rb.x <= m[2] and rb.y >= m[3] and rb.y <= m[4] then return true end
	end
	return false
end

KINDS.ice = {
	setup = function(g, hz)
		hz.vel, hz.prev = {}, {}
		for i, rb in ipairs(g.robots) do hz.vel[i], hz.prev[i] = 0, rb.x end
	end,
	tick = function(g, hz)
		local I = C.ICE
		for i, rb in ipairs(g.robots) do
			local v = 0
			if rb.grounded and not rb.dead and not rb.gone and not rb.trapped and on_ice(g, rb) then
				local dx = rb.x - hz.prev[i]
				if math.abs(dx) > I.max * 1.3 then
					v = 0   -- carried by something else (the Rampino, a blast, a teleport), not walking
				elseif math.abs(dx) > 0.01 then
					v = dx
				else
					v = hz.vel[i] * I.decay
				end
				if math.abs(v) < I.min then v = 0 end
				if v ~= 0 and not g:shove(rb, v) then v = 0 end
			end
			hz.vel[i], hz.prev[i] = v, rb.x
		end
	end,
	round_end = function(g, hz)
		if not g.wings then return end
		local mid, list = g.terrain.cell * (g.terrain.w - 2 * g.terrain.ox) / 2, {}
		for _, rb in ipairs(g.robots) do
			if not rb.dead and not rb.gone and not rb.trapped then list[#list + 1] = rb end
		end
		-- the outermost first, so nobody is blocked by the one in front of them
		table.sort(list, function(a, b)
			local da, db = math.abs(a.x - mid), math.abs(b.x - mid)
			if da ~= db then return da > db end
			return a.id < b.id
		end)
		for _, rb in ipairs(list) do
			local dir = rb.x < mid and -1 or 1
			for _ = 1, C.WIND.step / g.terrain.cell do
				if not g:shove(rb, dir * g.terrain.cell) then break end
			end
			hz.prev[rb.id] = rb.x
		end
		g:emit({ type = "wings" })
	end,
	-- the slide of a robot that stops (it keeps going the way it faces) and the wings' push
	risk = function(g, hz)
		local I = C.ICE
		local slide = I.max / (1 - I.decay)
		local mid = map_middle(g)
		return function(rb)
			if on_ice(g, rb) and pushed_off(g, rb.x, rb.y, rb.facing or 1, slide) then return M.DEATH end
			if g.wings and pushed_off(g, rb.x, rb.y, rb.x < mid and -1 or 1, C.WIND.step) then return M.DEATH end
			return 0
		end
	end,
}

-- The boulders (Avarizia): hz.rocks are the ones rolling now, each { x, y, dir, v, hit }
-- (hit: the robots it has already hurt). They start on the map's rocks at the end of a
-- round, follow the ground (faster downhill, slower uphill and on the flat) and crumble
-- when they stop, fall into a gap or meet a wall. Nothing is left on the terrain: the
-- server only sends the dug craters, so a hazard never adds ground.
-- One tick of the rock's way along the ground; true if it is over (a gap, a wall, too slow)
local function roll_on(g, b, r)
	local cell = g.terrain.cell
	local steps = math.max(1, math.ceil(r.v / 60 / cell))
	for _ = 1, steps do
		r.x = r.x + r.dir * r.v / 60 / steps
		local gy = g.terrain:ground_below(r.x, r.y + b.climb * 2)
		if not gy then return true end
		local rise = gy - r.y
		if rise > b.climb then return true end
		r.y = gy
		r.v = math.min(b.vmax, r.v - rise * b.accel / math.max(r.v, 40) - b.fric / 60 / steps)
		if r.v < b.stop then return true end
	end
	return false
end

local function roll(g, hz, b, i)
	local r, cell = hz.rocks[i], g.terrain.cell
	if roll_on(g, b, r) then return true end
	for _, rb in ipairs(g.robots) do
		if not rb.dead and not rb.gone and g.hurt_at(rb, r.x, r.y + b.r, b.r) then
			local seen = false
			for _, id in ipairs(r.hit) do seen = seen or id == rb.id end
			if not seen then
				r.hit[#r.hit + 1] = rb.id
				g:hurt(rb, b.damage, nil, "boulder")
				for _ = 1, b.shove / cell do
					if not g:shove(rb, r.dir * cell) then break end
				end
			end
		end
	end
	return false
end

KINDS.boulders = {
	setup = function(g, hz)
		hz.rocks = {}
	end,
	round_end = function(g, hz)
		for _, s in ipairs(g.rocks) do
			local y = g.terrain:ground_below(s.x, g.terrain.h * g.terrain.cell - 1) or 0
			hz.rocks[#hz.rocks + 1] = { x = s.x, y = y, dir = s.dir, v = C.BOULDER.v0, hit = {} }
		end
		g:emit({ type = "boulders" })
	end,
	tick = function(g, hz)
		local i = 1
		while i <= #hz.rocks do
			if roll(g, hz, C.BOULDER, i) then
				table.remove(hz.rocks, i)
			else
				i = i + 1
			end
		end
	end,
	busy = function(g, hz)
		return #hz.rocks > 0
	end,
	-- the way the rocks rolling and the ones that will start at the next round end would
	-- take, tried on their own (no robots): a sample of places every few ticks
	risk = function(g, hz)
		local B, path = C.BOULDER, {}
		local function follow(r)
			local n = 0
			while n < 1200 and not roll_on(g, B, r) do
				n = n + 1
				if n % 6 == 0 then path[#path + 1] = { r.x, r.y } end
			end
		end
		for _, r in ipairs(hz.rocks) do follow({ x = r.x, y = r.y, dir = r.dir, v = r.v }) end
		for _, s in ipairs(g.rocks) do
			local y = g.terrain:ground_below(s.x, g.terrain.h * g.terrain.cell - 1) or 0
			follow({ x = s.x, y = y, dir = s.dir, v = B.v0 })
		end
		local reach = B.r + g.HURT_R
		return function(rb)
			for _, p in ipairs(path) do
				if math.abs(rb.x - p[1]) < reach and math.abs(rb.y - p[2]) < B.r * 2 then return B.damage end
			end
			return 0
		end
	end,
}

-- The rising water (Ira): hz.level is the surface (world y); from the round C.WATER.from it
-- goes up by C.WATER.step at the end of every round, hz.rise says whether it will at the
-- next one (the surface to come is shown). Whoever is under it drowns.
KINDS.water = {
	setup = function(g, hz)
		hz.level = g.water.y
		hz.rise = g.round + 1 >= C.WATER.from
	end,
	round_end = function(g, hz)
		if g.round >= C.WATER.from then
			hz.level = hz.level + C.WATER.step
			g:emit({ type = "water", level = hz.level })
		end
		hz.rise = g.round + 1 >= C.WATER.from
	end,
	tick = function(g, hz)
		for _, rb in ipairs(g.robots) do
			if not rb.dead and not rb.gone and rb.y < hz.level then g:kill(rb, "fell") end
		end
	end,
	-- under the surface of the next rise a robot drowns; within one more step of it it will have to climb
	risk = function(g, hz)
		local level = hz.level + (hz.rise and C.WATER.step or 0)
		return function(rb)
			if rb.y < level then return M.DEATH end
			if rb.y < level + C.WATER.step then return 8 end
			return 0
		end
	end,
}

-- The tombs (Eresia): they open and close in turns, hz.phase 0 or 1 says which half is
-- open (tomb i is open when (i + phase) is even). Whoever is in an open one is set alight.
local function tomb_open(hz, i)
	return (i + hz.phase) % 2 == 0
end
M.tomb_open = tomb_open

KINDS.tombs = {
	setup = function(g, hz)
		hz.phase = 0
	end,
	round_end = function(g, hz)
		hz.phase = 1 - hz.phase
		g:emit({ type = "tombs" })
	end,
	tick = function(g, hz)
		for i, t in ipairs(g.tombs) do
			if tomb_open(hz, i) then
				for _, rb in ipairs(g.robots) do
					if not rb.dead and not rb.gone and not rb.status.burn
						and rb.x >= t[1] and rb.x <= t[2] and rb.y >= t[3] and rb.y <= t[4] then
						g:add_status(rb, "burn")
					end
				end
			end
		end
	end,
	-- a tomb burns whoever is in it: now if it is open, from the next round if it is closed
	risk = function(g, hz)
		return function(rb)
			for _, t in ipairs(g.tombs) do
				if rb.x >= t[1] and rb.x <= t[2] and rb.y >= t[3] and rb.y <= t[4] then return C.STATUS.burn.damage end
			end
			return 0
		end
	end,
}

function M.setup(g, map)
	g.gravity = g.gravity * (map.gravity or 1)
	g.mud, g.blood = map.mud, map.blood
	g.bridges, g.ice, g.wings = map.bridges, map.ice, map.wings
	g.rocks, g.water, g.tombs = map.rocks, map.water, map.tombs
	g.hazard = map.hazard
	if map.hazard then
		g.hz = {}
		KINDS[map.hazard].setup(g, g.hz)
	end
end

-- Whoever stands in the mud is slowed, whoever stands in the blood is set alight (until the
-- end of their next turn, like any status): once on entering, the status is not given again
-- while they have it
local ZONES = { { "mud", "slow" }, { "blood", "burn" } }

local function zones(g)
	for _, rb in ipairs(g.robots) do
		if rb.grounded and not rb.dead then
			for _, z in ipairs(ZONES) do
				local list = g[z[1]]
				if list and not rb.status[z[2]] then
					for _, m in ipairs(list) do
						if rb.x >= m[1] and rb.x <= m[2] and rb.y >= m[3] and rb.y <= m[4] then
							g:add_status(rb, z[2])
							break
						end
					end
				end
			end
		end
	end
end

function M.tick(g)
	if g.mud or g.blood then zones(g) end
	local hz = g.hz
	if hz then
		local k = KINDS[g.hazard]
		if k.tick then k.tick(g, hz) end
	end
end

function M.round_end(g)
	local hz = g.hz
	if hz then
		local k = KINDS[g.hazard]
		if k.round_end then k.round_end(g, hz) end
	end
end

-- The risk function of the match's hazard (see KINDS), or nil if the map has none: for the bots
function M.risk(g)
	local hz = g.hz
	local k = hz and KINDS[g.hazard]
	return k and k.risk and k.risk(g, hz) or nil
end

function M.busy(g)
	local hz = g.hz
	local k = hz and KINDS[g.hazard]
	return k and k.busy and k.busy(g, hz) or false
end

return M
