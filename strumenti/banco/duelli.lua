-- Weapon duels: bot against bot, one weapon each (plus the Lama everyone has), in pairs.
-- From the repository root:
--   luajit strumenti/banco/duelli.lua A B [--coppie N] [--livello normale] [--mappa pavimento]
--       -> one line:  A B vittorie_A vittorie_B pareggi punti_A punti_B partite
--   luajit strumenti/banco/duelli.lua --tabella file     -- the table from those lines
-- Each pair is the same match (seed, map) twice with the weapons swapped between robot 1 and 2,
-- so who starts first and the map cancel out: A against A gives exactly 50%.
-- Controlled conditions (not the real game, which has crates and a draft): 1v1, no crates, the
-- weapon with 99 shots (so primaries don't run out), only the Lama besides it. It says which weapon
-- wins when the bot can use it, not how the weapon fares in a real match. The recipe does not
-- contain the ammo: matches can't be replayed from it. Use duelli.sh for all the pairs on all cores.
package.path = "client/?.lua;" .. package.path
local game = require "sim.game"
local config = require "sim.config"
local maps = require "sim.maps"
local rng = require "sim.rng"
local replay = require "sim.replay"

local opt, pos = { coppie = 10, livello = "normale" }, {}
do
	local i = 1
	while arg[i] do
		local k = arg[i]:match("^%-%-(.+)")
		if k then opt[k] = tonumber(arg[i + 1]) or arg[i + 1]; i = i + 2 else pos[#pos + 1] = arg[i]; i = i + 1 end
	end
end

local SHOTS = 99
-- --ritocchi file.lua: function(config, game) that changes the numbers (try a retune without touching the game)
if opt.ritocchi then dofile(opt.ritocchi)(config, game) end

-- Two pure kits, to balance the free weapons against each other: "lama" (only the Lama) and
-- "missilino" (only the missile). Every other kit keeps the free weapons (missile, Lama, teleport).
local PURE = { lama = { sword = true, teleport = true }, missilino = { missile = true, teleport = true } }
local has_weapon = game.has_weapon
game.has_weapon = function(rb, weapon)
	local kit = rb.kit
	if kit and game.FREE_WEAPONS[weapon] and not kit[weapon] then return false end
	return has_weapon(rb, weapon)
end

-- the weapons: Lama, secondaries, primaries
local function all_weapons()
	local list = { "sword", "lama", "missilino" }
	for _, w in ipairs(game.DRAFT_SECONDARIES) do list[#list + 1] = w end
	for _, w in ipairs(game.CRATE_WEAPONS) do list[#list + 1] = w end
	return list
end

local function match(j, w1, w2)
	local seme = (j * 48271) % 2147483647
	local mappa = opt.mappa or maps.pick(seme)
	local players = {}
	for i, p in ipairs(config.MODES["1v1"]) do players[i] = { team = p.team, bot = opt.livello } end
	local r = replay.nuova(seme, mappa, { players = players })
	local g, bots = replay.partita(r)
	g.crate_every, g.crate_chance = 1e9, nil
	for i, w in ipairs({ w1, w2 }) do
		local rb = g.robots[i]
		for k in pairs(rb.ammo) do rb.ammo[k] = 0 end
		rb.secondary = nil
		rb.kit = PURE[w]
		if PURE[w] then
			-- nothing else
		elseif w ~= "sword" then
			if game.SECONDARY[w] then rb.secondary = w end
			rb.ammo[w] = SHOTS
		end
	end
	while g.phase ~= "over" do
		g:step(replay.input(r, g, bots))
		replay.dopo(r, g)
		g:pop_events()
	end
	local res = g:results()
	return res.winner, g.robots[1].team, g.robots[2].team, g.robots[1].points, g.robots[2].points
end

if opt.tabella then
	-- lines "A B wa wb pareggi pa pb n" -> matrix of A's win rate (wins + half the draws)
	local names, seen, cell = {}, {}, {}
	for line in io.lines(opt.tabella) do
		local a, b, wa, wb, d, pa, pb, n = line:match("^(%S+) (%S+) (%S+) (%S+) (%S+) (%S+) (%S+) (%S+)$")
		if a then
			for _, w in ipairs({ a, b }) do if not seen[w] then seen[w] = true; names[#names + 1] = w end end
			cell[a .. " " .. b] = { wa = tonumber(wa), wb = tonumber(wb), d = tonumber(d), pa = tonumber(pa), pb = tonumber(pb), n = tonumber(n) }
		end
	end
	local function rate(a, b)
		local c = cell[a .. " " .. b]
		if c then return (c.wa + c.d / 2) / c.n, c.n end
		c = cell[b .. " " .. a]
		if c then return (c.wb + c.d / 2) / c.n, c.n end
	end
	local rows = {}
	for _, a in ipairs(names) do
		local sum, cnt = 0, 0
		for _, b in ipairs(names) do
			if a ~= b then
				local x = rate(a, b)
				if x then sum, cnt = sum + x, cnt + 1 end
			end
		end
		rows[#rows + 1] = { a = a, m = cnt > 0 and sum / cnt or 0 }
	end
	table.sort(rows, function(x, y) if x.m ~= y.m then return x.m > y.m end return x.a < y.a end)
	print("| Arma | Vittorie medie contro le altre |")
	print("|---|---|")
	for _, r in ipairs(rows) do print(string.format("| %s | %.0f%% |", r.a, r.m * 100)) end
	print("")
	local head = "| vs |"
	local sep = "|---|"
	for _, r in ipairs(rows) do head = head .. " " .. r.a .. " |"; sep = sep .. "---|" end
	print(head); print(sep)
	for _, ra in ipairs(rows) do
		local line = "| " .. ra.a .. " |"
		for _, rb in ipairs(rows) do
			local x = ra.a ~= rb.a and rate(ra.a, rb.a)
			line = line .. (x and string.format(" %.0f |", x * 100) or " - |")
		end
		print(line)
	end
	return
end

if #pos == 0 then
	for _, w in ipairs(all_weapons()) do print(w) end
	return
end
local a, b = pos[1], pos[2] or pos[1]
local wa, wb, d, pa, pb, n = 0, 0, 0, 0, 0, 0
for j = 1, opt.coppie do
	for side = 1, 2 do
		local w1, w2 = a, b
		if side == 2 then w1, w2 = b, a end
		local winner, t1, t2, p1, p2 = match(j, w1, w2)
		local ta, tb, qa, qb = t1, t2, p1, p2
		if side == 2 then ta, tb, qa, qb = t2, t1, p2, p1 end
		pa, pb, n = pa + qa, pb + qb, n + 1
		if winner == ta then wa = wa + 1 elseif winner == tb then wb = wb + 1 else d = d + 1 end
	end
end
print(string.format("%s %s %d %d %d %.0f %.0f %d", a, b, wa, wb, d, pa / n, pb / n, n))
