-- The Forge (la Fornace, docs/commesse.md "La Fornace: Il Tiro nella Fucina",
-- Sergio's choice of 24 Nov): the only place where Ossidiana becomes Scaglie
-- and fragments. A pour (colata) costs Ossidiana and gives throws; each throw is
-- a drop of molten Ossidiana thrown with the battle's aim (angle and power, the
-- battle's missile physics without upgrades) at the moulds on the wall.
-- Pure rules, run the same on the phone (what the player sees at once) and on
-- the server (sim/progress.lua actions, server/worker.lua profile_do): the
-- phone only says the angle and the power, the result is computed here.
--
-- The world is the forge's, in the battle's units, with the apprentice's feet
-- at (0, 0) and y up. The wall has 12 moulds; a new wall comes three times a game
-- day (at 5, 13 and 21 Italian time: the key is "date#shift"), with the moulds in
-- new places. A filled mould stays full until the next wall.
--
-- The profile's field (added by M.init): fornace = { muro, pieni[slot], tiri,
-- lanci, centri, colate, seme, fortunato, senza }: the wall of the last pour, the
-- moulds filled on it, the throws left, the throws and hits of the pour, the
-- pours made, the seed of the player's walls, the lucky mould of the wall, the
-- walls since the last lucky one.

local game = require "sim.game"
local equip = require "sim.gear"
local orders = require "sim.orders"

local M = {}

M.COST = 20              -- Ossidiana per pour
M.THROWS = 3             -- throws per pour
M.BONUS = 1              -- extra throws for a perfect pour (all hits)
M.MISS = 20              -- Scaglie for a drop that misses (it falls in the bucket)
-- what a pour is worth on average, in Scaglie of value (a fragment = 60): the
-- design's aim, ~0.8x to 1.2x from worst to best (tools/economia/conti.lua)
M.AVERAGE = 130
M.MELT_IN, M.MELT_OUT = 4, 1   -- fragments of a family for one of another
M.MELT_SCAGLIE = 20      -- Scaglie for one fragment
M.SHIFT_HOURS = 8        -- a new wall every 8 hours of the game day (5, 13, 21)
M.FLOOR = -144           -- the forge's floor
M.DROP_R = 4             -- the drop's radius
M.MAX_TICKS = 900

local function hash(...)
	local h = 7
	for _, v in ipairs({ ... }) do
		local s = tostring(v)
		for i = 1, #s do h = (h * 131 + s:byte(i)) % 1000003 end
		h = (h * 31 + 17) % 1000003
	end
	return h
end

-- The wall's key for a game day (wallet.today) and the hour of the game day
-- (0..23, 0 is 5 in the morning)
function M.key(today, hour)
	local shift = math.max(0, math.min(2, math.floor((tonumber(hour) or 0) / M.SHIFT_HOURS)))
	return tostring(today) .. "#" .. shift
end

local function key_ok(key)
	return type(key) == "string" and key:match("^%d%d%d%d%-%d%d%-%d%d#[0-2]$") ~= nil
end

-- The moulds. Every wall puts them in new places (Sergio, 24 Nov: «le posizioni
-- sempre randomiche ogni volta che il muro si rigenera»), drawn from the wall's key
-- and the player's own seed, so each player has his walls. 12 moulds, 6 of Scaglie
-- and 6 of fragments (255 Scaglie and 8 fragments): the farther it is, the more it
-- gives, the far ones are small. Each one: centre of the opening (x), its rim (y),
-- width, chain length (drawn only: the high ones hang).
local B, P = 78, 52
M.PRIZES = {   -- from the nearest to the farthest
	{ w = B, scaglie = 15 }, { w = B, frammenti = 1 }, { w = B, scaglie = 20 }, { w = P, frammenti = 1 },
	{ w = B, scaglie = 30 }, { w = P, frammenti = 2 }, { w = B, frammenti = 1 }, { w = B, scaglie = 50 },
	{ w = P, frammenti = 1 }, { w = B, scaglie = 60 }, { w = P, frammenti = 2 }, { w = P, scaglie = 80 },
}
-- the places a mould can take: a grid with a little shake, never on the bucket
M.SPOTS_X = { 320, 1460, 60 }
M.SPOTS_Y = { -70, 10, 90, 170, 250, 330 }
M.SPOT_GAP = 120         -- the least distance between two moulds (their labels too)
M.BUCKET_X = 1010
M.CEILING = 470          -- where the chains hang from
M.COLUMN = 30            -- two moulds are never closer than this side by side
-- the arc at full power: y <= TOP - x^2 / REACH (v^2 / 2g and 2v^2 / g)
local V, GR = game.MISSILE_SPEED, game.GRAVITY * game.MISSILE_GRAVITY
M.TOP, M.REACH = V * V / (2 * GR), 2 * V * V / GR
M.REACH_ROOM = 70
-- the lucky mould (Sergio, 24 Nov): now and then a wall has one that gives double,
-- about one wall in LUCKY_CHANCE and for sure within LUCKY_PITY walls
M.LUCKY_CHANCE, M.LUCKY_PITY = 8, 15

-- The player's seed for his walls (fixed at his first pour)
function M.seed(p)
	local f = p.fornace
	return f and f.seme or hash(p.nome or "", p.livello or 1, p.xp or 0)
end

-- Is the next new wall lucky, and which mould (from the counter of walls without)?
local function lucky_slot(seed, key, without)
	if without + 1 >= M.LUCKY_PITY or hash(seed, key, "fortuna") % M.LUCKY_CHANCE == 0 then
		return hash(seed, key, "quale") % #M.PRIZES + 1
	end
end

-- Can mould i of wall be hit? Tries the arcs from flat to high, each with the
-- power that lands on the opening's centre (y up: v^2 = g dx^2 / (2 cos^2 a (dx tan a - dy)))
function M.reachable(wall, i)
	local m = wall[i]
	local g = game.GRAVITY * game.MISSILE_GRAVITY
	for deg = 16, 82, 3 do
		local a = math.rad(deg)
		local x0, y0 = M.launch(a, 1)
		local dx, dy = m.x - x0, m.y - y0
		local d = dx * math.tan(a) - dy
		if dx > 0 and d > 0 then
			local v = math.sqrt(g * dx * dx / (2 * math.cos(a) ^ 2 * d))
			local power = v / game.MISSILE_SPEED
			if power >= 0.1 and power <= 1 then
				local r = M.fly(a, power, wall, {})
				if r.esito == "stampo" and r.slot == i then return true end
			end
		end
	end
	return false
end

-- The wall of key for seed (lucky: the slot of the double mould, or nil):
-- { { slot, x, y, w, inner, depth, chain, small, scaglie | set + n, lucky } }
local LAYOUTS, LAYOUTS_N = {}, 0
function M.layout(key, seed, lucky)
	local id = tostring(key) .. "|" .. tostring(seed) .. "|" .. tostring(lucky)
	if LAYOUTS[id] then return LAYOUTS[id] end
	-- the spots in the wall's own order
	local spots = {}
	for x = M.SPOTS_X[1], M.SPOTS_X[2], M.SPOTS_X[3] do
		for _, y in ipairs(M.SPOTS_Y) do
			local sx = x + hash(seed, key, x, y, "x") % 41 - 20
			local sy = y + hash(seed, key, x, y, "y") % 41 - 20
			-- never on the bucket, always within reach (the top of the arc at full power,
			-- with some room: the farthest need almost all the power)
			local reach = M.TOP - sx * sx / M.REACH - M.REACH_ROOM
			if not (math.abs(sx - M.BUCKET_X) < 125 and sy < 30) and sy <= reach then
				spots[#spots + 1] = { x = sx, y = sy, k = hash(seed, key, x, y) }
			end
		end
	end
	table.sort(spots, function(a, b) if a.k ~= b.k then return a.k < b.k end return a.x < b.x end)
	-- picked one by one; a spot is taken only if it and all the ones before can
	-- still be hit (a mould can cover another from the drop's way)
	local picked = {}
	for _, sp in ipairs(spots) do
		local ok = true
		for _, q in ipairs(picked) do
			-- apart, and never one over the other
			if (sp.x - q.x) ^ 2 + (sp.y - q.y) ^ 2 < M.SPOT_GAP ^ 2 or math.abs(sp.x - q.x) < M.COLUMN then ok = false; break end
		end
		if ok then
			picked[#picked + 1] = sp
			local probe = {}
			for i, q in ipairs(picked) do probe[i] = { slot = i, x = q.x, y = q.y, w = B, inner = P * 0.36, depth = B * 0.78 } end
			for i = 1, #picked do
				if not M.reachable(probe, i) then ok = false; break end
			end
			if not ok then picked[#picked] = nil end
		end
		if #picked == #M.PRIZES then break end
	end
	-- the farther (and higher), the richer
	table.sort(picked, function(a, b)
		local da, db = a.x + 0.6 * a.y, b.x + 0.6 * b.y
		if da ~= db then return da < db end
		return a.x < b.x
	end)
	local out = {}
	for i, sp in ipairs(picked) do
		local pz = M.PRIZES[i]
		local m = { slot = i, x = sp.x, y = sp.y, w = pz.w, inner = pz.w * 0.36, depth = pz.w * 0.78,
			small = pz.w < B, scaglie = pz.scaglie, lucky = lucky == i or nil }
		if sp.y > 100 then m.chain = M.CEILING - sp.y end
		if pz.frammenti then m.set, m.n = equip.SETS[hash(seed, key, i, "famiglia") % #equip.SETS + 1].id, pz.frammenti end
		if m.lucky then
			if m.scaglie then m.scaglie = m.scaglie * 2 else m.n = m.n * 2 end
		end
		out[i] = m
	end
	-- (a few walls kept: the same one is asked at every throw and every frame)
	if LAYOUTS_N > 16 then LAYOUTS, LAYOUTS_N = {}, 0 end
	LAYOUTS[id], LAYOUTS_N = out, LAYOUTS_N + 1
	return out
end

-- The wall p sees for key: the one of its pour if it is the same key, else the
-- next new one (what a pour on key would hang)
function M.wall(p, key)
	M.init(p)
	local f = p.fornace
	if key == f.muro then return M.layout(key, M.seed(p), f.fortunato) end
	return M.layout(key, M.seed(p), lucky_slot(M.seed(p), key, f.senza))
end

-- What is still on the wall for key: Scaglie, fragments by family, moulds left
function M.left(p, key)
	local f = p.fornace
	local full = key == f.muro and f.pieni or {}
	local sc, fr, n = 0, {}, 0
	for i, m in ipairs(M.wall(p, key)) do
		if not full[i] then
			n = n + 1
			if m.scaglie then sc = sc + m.scaglie else fr[m.set] = (fr[m.set] or 0) + m.n end
		end
	end
	return sc, fr, n
end

-- Where the drop starts and how fast (the battle's missile, sim/game.lua)
function M.launch(angle, power)
	local speed = game.MISSILE_SPEED * math.max(0.1, math.min(1, power))
	return math.cos(angle) * game.MUZZLE, game.DISEGNO_H / 2 + math.sin(angle) * game.MUZZLE,
		math.cos(angle) * speed, math.sin(angle) * speed
end

-- Is (x, y) inside the iron of mould m (its body below the rim, or the rim's
-- edges beside the opening)?
local function in_iron(m, x, y)
	local dx = math.abs(x - m.x)
	if dx > m.w / 2 + M.DROP_R then return false end
	if y > m.y + M.DROP_R or y < m.y - m.depth then return false end
	return dx > m.inner or y < m.y - M.DROP_R
end

-- The flight of a throw against the moulds of a wall (full: the slots already
-- filled, they are iron). Returns { esito = "stampo" | "ferro" | "secchio", slot,
-- ticks } and, when points is true, the drop's positions tick by tick (for drawing).
function M.fly(angle, power, wall, full, points)
	full = full or {}
	local x, y, vx, vy = M.launch(angle, power)
	local g = game.GRAVITY * game.MISSILE_GRAVITY
	local path = points and { { x, y } } or nil
	for t = 1, M.MAX_TICKS do
		vy = vy - g * game.DT
		local nx, ny = x + vx * game.DT, y + vy * game.DT
		for _, m in ipairs(wall) do
			-- through the opening, going down
			if not full[m.slot] and y >= m.y and ny < m.y then
				local cx = x + (nx - x) * (y - m.y) / (y - ny)
				if math.abs(cx - m.x) <= m.inner - M.DROP_R * 0.5 then
					if path then path[#path + 1] = { cx, m.y } end
					return { esito = "stampo", slot = m.slot, ticks = t }, path
				end
			end
			if in_iron(m, nx, ny) or (full[m.slot] and math.abs(nx - m.x) <= m.w / 2 and ny <= m.y and ny >= m.y - m.depth) then
				if path then path[#path + 1] = { nx, ny } end
				return { esito = "ferro", slot = m.slot, ticks = t }, path
			end
		end
		x, y = nx, ny
		if path then path[#path + 1] = { x, y } end
		if y < M.FLOOR or x < -400 or x > 2000 then return { esito = "secchio", ticks = t }, path end
	end
	return { esito = "secchio", ticks = M.MAX_TICKS }, path
end

-- The profile --------------------------------------------------------------------------

function M.init(p)
	local f = p.fornace or {}
	p.fornace = f
	f.muro = f.muro or ""
	f.pieni = f.pieni or {}
	f.tiri = f.tiri or 0
	f.lanci = f.lanci or 0
	f.centri = f.centri or 0
	f.colate = f.colate or 0
	f.senza = f.senza or 0
	return p
end

-- A pour on the wall key (the phone says which wall it sees: it must be of
-- today and never older than the last one, so a wall can't be filled again by
-- going back to it). The throws of a pour stay on its wall even if the wall
-- changes meanwhile.
function M.pour(p, key, today)
	M.init(p)
	local f = p.fornace
	if f.tiri > 0 then return nil, "colata" end
	if not key_ok(key) or key:sub(1, 10) ~= tostring(today) or key < f.muro then return nil, "muro" end
	if (p.ossidiana or 0) < M.COST then return nil, "ossidiana" end
	if key ~= f.muro then
		f.seme = M.seed(p)
		f.fortunato = lucky_slot(f.seme, key, f.senza)
		f.senza = f.fortunato and 0 or f.senza + 1
		f.muro, f.pieni = key, {}
	end
	p.ossidiana = p.ossidiana - M.COST
	f.tiri, f.lanci, f.centri = M.THROWS, 0, 0
	f.colate = f.colate + 1
	return true
end

-- A throw of the pour: angle (radians) and power (0..1). Returns the result
-- ({ esito, slot, scaglie | set + n, bonus }).
function M.throw(p, angle, power)
	M.init(p)
	local f = p.fornace
	if f.tiri <= 0 then return nil, "tiri" end
	if type(angle) ~= "number" or type(power) ~= "number" or angle ~= angle or power ~= power then return nil, "tiro" end
	local wall = M.layout(f.muro, f.seme, f.fortunato)
	local r = M.fly(angle, power, wall, f.pieni)
	f.tiri, f.lanci = f.tiri - 1, f.lanci + 1
	if r.esito == "stampo" then
		local m = wall[r.slot]
		f.pieni[r.slot] = true
		f.centri = f.centri + 1
		r.lucky = m.lucky
		if m.scaglie then
			r.scaglie = m.scaglie
		else
			r.set, r.n = m.set, m.n
			orders.init(p)
			p.commesse.frammenti[m.set] = (p.commesse.frammenti[m.set] or 0) + m.n
		end
	else
		r.scaglie = M.MISS
	end
	if r.scaglie then p.scaglie = (p.scaglie or 0) + r.scaglie end
	if f.lanci == M.THROWS and f.centri == M.THROWS then
		f.tiri = f.tiri + M.BONUS
		r.bonus = M.BONUS
	end
	return r
end

-- Melting fragments: MELT_IN of family da for MELT_OUT of family a, or (a nil)
-- one of da for MELT_SCAGLIE Scaglie
function M.melt(p, da, a)
	orders.init(p)
	local fr = p.commesse.frammenti
	if type(da) ~= "string" or not equip.BY_ID[da] then return nil, "famiglia" end
	if a == nil then
		if (fr[da] or 0) < 1 then return nil, "frammenti" end
		fr[da] = fr[da] - 1
		p.scaglie = (p.scaglie or 0) + M.MELT_SCAGLIE
		return { scaglie = M.MELT_SCAGLIE }
	end
	if type(a) ~= "string" or not equip.BY_ID[a] or a == da then return nil, "famiglia" end
	if (fr[da] or 0) < M.MELT_IN then return nil, "frammenti" end
	fr[da] = fr[da] - M.MELT_IN
	fr[a] = (fr[a] or 0) + M.MELT_OUT
	return { set = a, n = M.MELT_OUT }
end

return M
