-- Collante tra il server Go e la simulazione: passa gli input al gioco e
-- prepara stato ed eventi come tabelle Lua semplici. Il JSON lo scrive il
-- server in Go (server/luajson.go), molto più in fretta di string.format qui.
local game = require "sim.game"
local maps = require "sim.maps"

local N = {}

-- Le mappe fisse si disegnano una volta sola per processo: le partite dopo
-- copiano le celle già pronte (server/terreno.go), invece di ridisegnarle
-- (più di 100 ms in gopher-lua).
for id, def in pairs(maps.maps) do
	if not def.seeded then
		local build = def.build
		def.build = function(t, seed)
			if not terrain_restore(t, id) then
				build(t, seed)
				terrain_store(t, id)
			end
		end
	end
end

function N.new(seed, map)
	local g = game.new(seed, map)
	g:pop_events()
	g.carves = {} -- scavi del terreno, per chi si riconnette
	return g
end

local WEAPONS = { missile = true, sword = true, teleport = true, grenade = true, shards = true, punch = true }

-- hold: il salto è ancora tenuto premuto (lasciandolo mentre si sale il salto è corto)
function N.step(g, left, right, jump, hold, angle, power, weapon)
	local fire = nil
	if angle then fire = { angle = angle, power = power, weapon = WEAPONS[weapon] and weapon or "missile" } end
	g:step({ left = left, right = right, jump = jump, hold = hold, fire = fire })
end

function N.current(g)
	return g.current
end

function N.over(g)
	return g.phase == "over"
end

function N.snapshot(g)
	local robots = {}
	for i, rb in ipairs(g.robots) do
		-- s: tick del fendente in corso (0 se il robot non sta colpendo), sd: sua direzione
		-- pu, pd: lo stesso per il Pugno del Titano; ag, as, ap: colpi di Uovo, Schegge e Pugno
		-- sb, pb: angolo di mira del fendente e del pugno (servono col modello "blastron")
		robots[i] = { x = rb.x, y = rb.y, hp = math.floor(rb.hp), f = rb.facing, d = rb.dead, g = rb.grounded,
			s = rb.swing or 0, sd = rb.swing_dir or 0, pu = rb.punch or 0, pd = rb.punch_dir or 0,
			sb = rb.swing_base or 0, pb = rb.punch_base or 0,
			ag = rb.ammo.grenade, as = rb.ammo.shards, ap = rb.ammo.punch }
	end
	-- k: "missile" o "grenade", fu: tick prima che l'Uovo scoppi
	local p = g.projectile and { x = g.projectile.x, y = g.projectile.y, k = g.projectile.kind, fu = g.projectile.fuse or 0 }
	-- o: i globi del teletrasporto in volo (i = numero del globo, per seguirlo tra uno stato e l'altro)
	local orbs = {}
	for i, ob in ipairs(g.orbs) do orbs[i] = { i = ob.id, x = ob.x, y = ob.y } end
	-- schegge in volo col loro posto nella raffica, casse (l'arma dentro resta segreta)
	local shards, crates = {}, {}
	for i = 1, game.SHARD_COUNT do
		local sh = g.shards[i]
		if sh then shards[#shards + 1] = { i = i, x = sh.x, y = sh.y } end
	end
	for _, c in ipairs(g.crates) do
		crates[#crates + 1] = { i = c.id, x = c.x, y = c.y, l = c.landed }
	end
	return { t = "state", phase = g.phase, cur = g.current, timer = g.timer, retreat = g.retreat, mt = g.match_left,
		r = robots, p = p, o = orbs, s = shards, c = crates }
end

-- Eventi dall'ultimo tick (una lista, vuota se non ne sono successi)
function N.events(g)
	local list = g:pop_events()
	for _, e in ipairs(list) do
		e.t = "ev"
		if e.type == "explosion" then g.carves[#g.carves + 1] = { e.x, e.y, e.r } end
	end
	return list
end

-- Gli scavi fatti finora: chi si riconnette li rifà sul suo terreno
function N.sync(g)
	return { t = "sync", x = g.carves }
end

return N
