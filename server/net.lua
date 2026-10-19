-- Collante tra il server Go e la simulazione: passa gli input al gioco
-- e trasforma stato ed eventi in JSON da inviare ai client.
local game = require "sim.game"

local N = {}

function N.new(seed)
	local g = game.new(seed)
	g:pop_events()
	return g
end

function N.step(g, left, right, jump, angle, power)
	local fire = nil
	if angle then fire = { angle = angle, power = power } end
	g:step({ left = left, right = right, jump = jump, fire = fire })
end

function N.current(g)
	return g.current
end

function N.over(g)
	return g.phase == "over"
end

local function encode(t)
	local keys = {}
	for k in pairs(t) do keys[#keys + 1] = k end
	table.sort(keys)
	local parts = {}
	for _, k in ipairs(keys) do
		local v = t[k]
		local s
		if type(v) == "number" then
			s = v == math.floor(v) and string.format("%d", v) or string.format("%.2f", v)
		elseif type(v) == "boolean" then
			s = tostring(v)
		else
			s = string.format("%q", tostring(v))
		end
		parts[#parts + 1] = string.format("%q:%s", k, s)
	end
	return "{" .. table.concat(parts, ",") .. "}"
end

function N.snapshot(g)
	local robots = {}
	for i, rb in ipairs(g.robots) do
		robots[i] = encode({ x = rb.x, y = rb.y, hp = math.floor(rb.hp), f = rb.facing, d = rb.dead, g = rb.grounded })
	end
	local p = "null"
	if g.projectile then p = encode({ x = g.projectile.x, y = g.projectile.y }) end
	return string.format('{"t":"state","phase":%q,"cur":%d,"timer":%d,"wind":%d,"r":[%s],"p":%s}',
		g.phase, g.current, g.timer, g.wind, table.concat(robots, ","), p)
end

-- Eventi accumulati dall'ultimo tick, uno per riga.
function N.events(g)
	local out = {}
	for _, e in ipairs(g:pop_events()) do
		e.t = "ev"
		out[#out + 1] = encode(e)
	end
	return table.concat(out, "\n")
end

return N
