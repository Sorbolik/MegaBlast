-- Map hazards: what a map does by itself, besides the robots' weapons. A map
-- (sim/maps.lua) asks for them with plain data:
--   gravity = 0.55                   the gravity of the whole match, times the usual one
--   mud = { { x0, x1, y0, y1 } }     world rectangles: a robot standing on the ground inside one is slowed
--   hazard = "wind" | "hail"         a hazard of the rounds (KINDS below)
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
}

-- The hail (Gola): hz.marks are the places where the stones will fall when the round
-- ends (a shadow shows them all round long); hz.stones the ones falling now, each
-- blows up on the first terrain or robot it meets
local function new_marks(g)
	local h = C.HAIL
	return pick_columns(g, h.count, h.margin, h.gap)
end

KINDS.hail = {
	setup = function(g, hz)
		hz.marks, hz.stones = new_marks(g), {}
	end,
	round_end = function(g, hz)
		for _, x in ipairs(hz.marks) do
			hz.stones[#hz.stones + 1] = { x = x, y = g.terrain.h * g.terrain.cell + C.HAIL.r * 2 }
		end
		hz.marks = new_marks(g)
		g:emit({ type = "hail" })
	end,
	tick = function(g, hz)
		local h, stones, cell = C.HAIL, hz.stones, g.terrain.cell
		local i = 1
		while i <= #stones do
			local s, hit = stones[i], false
			local dy = h.speed / 60
			for _ = 1, math.ceil(dy / cell) do
				s.y = s.y - dy / math.ceil(dy / cell)
				if g.terrain:solid(s.x, s.y - h.r) then hit = true end
				for _, rb in ipairs(g.robots) do
					if not rb.dead and g.hurt_at(rb, s.x, s.y, h.r) then hit = true end
				end
				if hit then break end
			end
			if hit then
				table.remove(stones, i)
				g:explode(s.x, s.y, nil, h.blast)
			else
				i = i + 1
			end
		end
	end,
	busy = function(g, hz)
		return #hz.stones > 0
	end,
}

function M.setup(g, map)
	g.gravity = g.gravity * (map.gravity or 1)
	g.mud = map.mud
	g.hazard = map.hazard
	if map.hazard then
		g.hz = {}
		KINDS[map.hazard].setup(g, g.hz)
	end
end

-- Whoever stands in the mud is slowed (until the end of their next turn, like any
-- slow): once on entering, the status is not given again while they have it
local function mud(g)
	for _, rb in ipairs(g.robots) do
		if rb.grounded and not rb.dead and not rb.status.slow then
			for _, m in ipairs(g.mud) do
				if rb.x >= m[1] and rb.x <= m[2] and rb.y >= m[3] and rb.y <= m[4] then
					g:add_status(rb, "slow")
					break
				end
			end
		end
	end
end

function M.tick(g)
	if g.mud then mud(g) end
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

function M.busy(g)
	local hz = g.hz
	local k = hz and KINDS[g.hazard]
	return k and k.busy and k.busy(g, hz) or false
end

return M
