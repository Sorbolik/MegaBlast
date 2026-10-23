-- Collante tra il server Go e la simulazione: passa gli input al gioco
-- e trasforma stato ed eventi in JSON da inviare ai client.
local game = require "sim.game"

local N = {}

function N.new(seed, map)
	local g = game.new(seed, map)
	g:pop_events()
	return g
end

-- hold: il salto è ancora tenuto premuto (lasciandolo mentre si sale il salto è corto)
function N.step(g, left, right, jump, hold, angle, power, weapon)
	local fire = nil
	if angle then fire = { angle = angle, power = power, weapon = game.WEAPONS[weapon] and weapon or "missile" } end
	g:step({ left = left, right = right, jump = jump, hold = hold, fire = fire })
end

function N.current(g)
	return g.current
end

function N.over(g)
	return g.phase == "over"
end

-- JSON di una tabella: chiavi in ordine, le tabelle con [1] diventano liste
-- (i risultati della partita nell'evento "over" sono annidati)
local encode
local function value(v)
	if type(v) == "number" then
		return v == math.floor(v) and string.format("%d", v) or string.format("%.2f", v)
	elseif type(v) == "boolean" then
		return tostring(v)
	elseif type(v) == "table" then
		if v[1] ~= nil then
			local items = {}
			for i, x in ipairs(v) do items[i] = value(x) end
			return "[" .. table.concat(items, ",") .. "]"
		end
		return encode(v)
	end
	return string.format("%q", tostring(v))
end

encode = function(t)
	local keys = {}
	for k in pairs(t) do keys[#keys + 1] = k end
	table.sort(keys)
	local parts = {}
	for _, k in ipairs(keys) do parts[#parts + 1] = string.format("%q:%s", k, value(t[k])) end
	return "{" .. table.concat(parts, ",") .. "}"
end

function N.snapshot(g)
	local robots = {}
	for i, rb in ipairs(g.robots) do
		-- s: tick del fendente in corso (0 se il robot non sta colpendo), sd: sua direzione
		-- pu, pd: lo stesso per il Pugno del Titano; ag, as, ap: colpi di Uovo, Schegge e Pugno
		-- sb, pb: angolo di mira del fendente e del pugno (servono col modello "blastron")
		-- n: Nucleo, ft: teletrasporti gratis rimasti, mh: vita massima, tu: turni giocati, pt: punti
		-- ak, ad, am: trappole, scudi e trampolini; sh: scudo rimasto; pa: paracadute (1 pronto, 2 aperto);
		-- fp: paracadute gratis
		robots[i] = encode({ x = rb.x, y = rb.y, hp = math.floor(rb.hp), f = rb.facing, d = rb.dead, g = rb.grounded,
			n = rb.nucleo, ft = rb.free_teleports, mh = rb.max_hp, tu = rb.turns, pt = math.floor(rb.points + 0.5),
			ak = rb.ammo.trap, ad = rb.ammo.shield, am = rb.ammo.trampoline, sh = rb.shield or 0, fp = rb.free_parachutes,
			pa = rb.parachute == "armed" and 1 or (rb.parachute == "open" and 2 or 0),
			s = rb.swing or 0, sd = rb.swing_dir or 0, pu = rb.punch or 0, pd = rb.punch_dir or 0,
			sb = rb.swing_base or 0, pb = rb.punch_base or 0,
			ag = rb.ammo.grenade, as = rb.ammo.shards, ap = rb.ammo.punch })
	end
	local p = "null"
	-- k: "missile" o "grenade", fu: tick prima che l'Uovo scoppi
	if g.projectile then p = encode({ x = g.projectile.x, y = g.projectile.y, k = g.projectile.kind, fu = g.projectile.fuse or 0 }) end
	-- o: i globi del teletrasporto in volo (i = numero del globo, per seguirlo tra uno stato e l'altro)
	local orbs = {}
	for i, ob in ipairs(g.orbs) do orbs[i] = encode({ i = ob.id, x = ob.x, y = ob.y }) end
	-- schegge in volo col loro posto nella raffica, casse (l'arma dentro resta segreta)
	local shards, crates = {}, {}
	for i = 1, game.SHARD_COUNT do
		local sh = g.shards[i]
		if sh then shards[#shards + 1] = encode({ i = i, x = sh.x, y = sh.y }) end
	end
	for _, c in ipairs(g.crates) do
		crates[#crates + 1] = encode({ i = c.id, x = c.x, y = c.y, l = c.landed })
	end
	-- pl: trappole e trampolini posati (k: tipo, a: armata, tm: squadra, r: mezza larghezza)
	local placed = {}
	for i, o in ipairs(g.placed) do
		placed[i] = encode({ i = o.id, k = o.kind, x = o.x, y = o.y, a = o.armed, tm = o.team, r = o.r })
	end
	-- win: tick rimasti per il secondo attacco; u: attacchi fatti (1 arma, 2 spada); tp: teletrasporti del turno
	local used = (g.used.weapon and 1 or 0) + (g.used.sword and 2 or 0)
	return string.format('{"t":"state","phase":%q,"cur":%d,"timer":%d,"win":%d,"retreat":%d,"u":%d,"tp":%d,"mt":%d,"r":[%s],"p":%s,"o":[%s],"s":[%s],"c":[%s],"pl":[%s]}',
		g.phase, g.current, g.timer, g.window, g.retreat, used, g.teleports, g.match_left, table.concat(robots, ","), p, table.concat(orbs, ","),
		table.concat(shards, ","), table.concat(crates, ","), table.concat(placed, ","))
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
