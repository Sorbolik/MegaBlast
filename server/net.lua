-- Collante tra il server Go e la simulazione: passa gli input al gioco
-- e trasforma stato ed eventi in JSON da inviare ai client.
local game = require "sim.game"

local N = {}

function N.new(seed, map)
	local g = game.new(seed, map)
	g:pop_events()
	return g
end

local WEAPONS = { missile = true, sword = true, teleport = true, grenade = true, shards = true, punch = true }

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
		-- pu, pd: lo stesso per il Pugno del Titano; ag, as, ap: colpi di Uovo, Schegge e Pugno
		robots[i] = encode({ x = rb.x, y = rb.y, hp = math.floor(rb.hp), f = rb.facing, d = rb.dead, g = rb.grounded,
			s = rb.swing or 0, sd = rb.swing_dir or 0, pu = rb.punch or 0, pd = rb.punch_dir or 0,
			ag = rb.ammo.grenade, as = rb.ammo.shards, ap = rb.ammo.punch })
	end
	local p, o = "null", "null"
	-- k: "missile" o "grenade", fu: tick prima che l'Uovo scoppi
	if g.projectile then p = encode({ x = g.projectile.x, y = g.projectile.y, k = g.projectile.kind, fu = g.projectile.fuse or 0 }) end
	if g.orb then o = encode({ x = g.orb.x, y = g.orb.y }) end
	-- schegge in volo col loro posto nella raffica, casse (l'arma dentro resta segreta)
	local shards, crates = {}, {}
	for i = 1, game.SHARD_COUNT do
		local sh = g.shards[i]
		if sh then shards[#shards + 1] = encode({ i = i, x = sh.x, y = sh.y }) end
	end
	for _, c in ipairs(g.crates) do
		crates[#crates + 1] = encode({ i = c.id, x = c.x, y = c.y, l = c.landed })
	end
	return string.format('{"t":"state","phase":%q,"cur":%d,"timer":%d,"retreat":%d,"mt":%d,"r":[%s],"p":%s,"o":%s,"s":[%s],"c":[%s]}',
		g.phase, g.current, g.timer, g.retreat, g.match_left, table.concat(robots, ","), p, o,
		table.concat(shards, ","), table.concat(crates, ","))
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
