-- Collante tra il server Go e la simulazione: passa gli input al gioco
-- e trasforma stato ed eventi in JSON da inviare ai client.
local game = require "sim.game"

local N = {}

function N.new(seed, map)
	local g = game.new(seed, map)
	g:pop_events()
	return g
end

local WEAPONS = { missile = true, sword = true, teleport = true }

function N.step(g, left, right, jump, angle, power, weapon)
	local fire = nil
	if angle then fire = { angle = angle, power = power, weapon = WEAPONS[weapon] and weapon or "missile" } end
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
		-- s: tick del fendente in corso (0 se il robot non sta colpendo), sd: sua direzione
		robots[i] = encode({ x = rb.x, y = rb.y, hp = math.floor(rb.hp), f = rb.facing, d = rb.dead, g = rb.grounded,
			s = rb.swing or 0, sd = rb.swing_dir or 0 })
	end
	local p, o = "null", "null"
	if g.projectile then p = encode({ x = g.projectile.x, y = g.projectile.y }) end
	if g.orb then o = encode({ x = g.orb.x, y = g.orb.y }) end
	return string.format('{"t":"state","phase":%q,"cur":%d,"timer":%d,"retreat":%d,"r":[%s],"p":%s,"o":%s,"ou":%s}',
		g.phase, g.current, g.timer, g.retreat, table.concat(robots, ","), p, o, tostring(g.orb_used))
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
