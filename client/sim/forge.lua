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
-- at (0, 0) and y up. The wall has 12 moulds; a game day has three walls, one after
-- the other (the key is "date#n", n = 0, 1, 2), with the moulds in new places and
-- richer prizes. A filled mould stays full until the next wall.
--
-- The profile's field (added by M.init): fornace = { muro, pieni[slot], tiri,
-- lanci, centri, colate, fortunato, jackpot, rintocchi }: the wall of the last pour,
-- the moulds filled on it, the throws left, the throws and hits of the pour, the
-- pours made, the lucky mould of the wall, the full walls, the most knocks on the
-- moulds in one throw. (Old profiles may still have seme and senza: unused.)

local game = require "sim.game"
local equip = require "sim.gear"
local orders = require "sim.orders"

local M = {}

M.COST = 15              -- Ossidiana per pour (20 until 25 Nov: it gave no more than the Commesse)
M.THROWS = 3             -- throws per pour
M.BONUS = 1              -- extra throws for a perfect pour (all hits)
M.MISS = 30              -- Scaglie for every drop, in the bucket or in a mould (r.base) (Sergio, 25 Nov: «mettiamolo a 30 e lasciamolo sempre a 30», on every wall)
-- the jackpot (Sergio, 24 Nov: «se qualcuno riempie tutti quelli di un muro ha un premio
-- speciale»): every mould of a wall filled gives JACKPOT Scaglie, and the first time the
-- «Jackpot della Fornace» medal (p.fornace.jackpot counts them)
M.JACKPOT = 500
-- the jackpot of each wall of the day (Sergio, 25 Nov: «più bello che il Jackpot del
-- terzo muro ti dia 1000 che è un numero pieno»)
M.JACKPOTS = { 500, 750, 1000 }
-- the medals of the knocks (Sergio, 24 Nov: «una medaglia per aver fatto 6 rintocchi
-- sulle coppe e una per 10»): the drop knocking on the moulds' iron so many times in
-- one throw
M.KNOCKS = { 6, 8, 10 }
-- what a pour is worth on average, in Scaglie of value (a fragment = 60): measured
-- with a model player who aims with some error (25 Nov, 15 Ossidiana, MISS 30 on every
-- drop, first wall: 172 weak, 206 average and good, plus 5-9% of bank shots; the
-- third wall ~+25%; tools/economia/conti.lua reads it). The currencies thread asked
-- for at most 10 Scaglie per Ossidiana on average: Sergio chose ~14 («va bene così»)
M.AVERAGE = 220
-- the walls of a game day (Sergio, 25 Nov): three, the same for everyone, one after
-- the other: the second opens when the first is full, the third after the second;
-- a game day to go on (at 5 in the morning it starts again from the first). The
-- prizes grow with the wall, the jackpot too
M.WALLS = 3
M.LEVELS = { 1, 1.25, 1.5 }
-- the bank shots (Sergio, 25 Nov: «che sia sponda sul muro o che sia sui calderoni,
-- si deve incrementare il premio»): each knock on the moulds' iron before going in
-- adds KNOCK_BONUS of the mould's prize, the back wall doubles it, BANK_MAX at most
M.KNOCK_BONUS, M.WALL_BONUS, M.BANK_MAX = 0.5, 2, 3
M.MELT_IN, M.MELT_OUT = 4, 1   -- fragments of a family for one of another
M.MELT_SCAGLIE = 20      -- Scaglie for one fragment
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

-- The key of wall n (0, 1, 2) of a game day (wallet.today)
function M.key(today, n)
	return tostring(today) .. "#" .. math.max(0, math.min(M.WALLS - 1, tonumber(n) or 0))
end

-- the wall's number in its day (0, 1, 2) and its prizes' multiplier
function M.level(key)
	local n = tonumber(tostring(key):sub(12, 12)) or 0
	return n, M.LEVELS[n + 1] or 1
end

local function key_ok(key)
	return type(key) == "string" and key:match("^%d%d%d%d%-%d%d%-%d%d#[0-2]$") ~= nil
end

-- The moulds. Every wall puts them in new places (Sergio, 24 Nov: «le posizioni
-- sempre randomiche ogni volta che il muro si rigenera»), drawn from the wall's key
-- only: the same wall for everyone (Sergio, 24 Nov: «uguale per tutti quanti, crea
-- più unione tra la gente»). 12 moulds, 6 of Scaglie
-- and 6 of fragments (255 Scaglie and 8 fragments): the farther it is, the more it
-- gives, the far ones are small. Each one: centre of the opening (x), its rim (y),
-- width, chain length (drawn only: the high ones hang).
-- (Sergio, 24 Nov: «allargare leggermente tutti i bersagli, giusto un pelo») the
-- moulds 6% wider than at first, drawing included
M.GROW = 1.06
local B, P = 78 * M.GROW, 52 * M.GROW
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

-- The walls' seed: the same for everyone (it was the player's own until 24 Nov)
M.SEED = 0
function M.seed() return M.SEED end

-- the days from 1970-01-01 of a date "YYYY-MM-DD" (the civil calendar, no clock)
local function day_number(date)
	local y, m, d = tostring(date):match("^(%d+)%-(%d+)%-(%d+)")
	y, m, d = tonumber(y), tonumber(m), tonumber(d)
	if not y then return 0 end
	if m <= 2 then y = y - 1 end
	local era = math.floor(y / 400)
	local yoe = y - era * 400
	local doy = math.floor((153 * (m + (m > 2 and -3 or 9)) + 2) / 5) + d - 1
	local doe = yoe * 365 + math.floor(yoe / 4) - math.floor(yoe / 100) + doy
	return era * 146097 + doe - 719468
end

-- the wall's number since 1970 (three a day)
function M.wall_number(key)
	return day_number(key:sub(1, 10)) * 3 + (tonumber(key:sub(12, 12)) or 0)
end

-- Is the wall lucky, and which mould? The same for everyone: one wall in every
-- LUCKY_CHANCE in a row, at a place drawn for that run (so two lucky walls are at
-- most 2 * LUCKY_CHANCE - 1 apart, within LUCKY_PITY)
function M.lucky_slot(key)
	if not key_ok(key) then return nil end
	local n = M.wall_number(key)
	local run = math.floor(n / M.LUCKY_CHANCE)
	if n % M.LUCKY_CHANCE == hash(run, "fortuna") % M.LUCKY_CHANCE then
		return hash(key, "quale") % #M.PRIZES + 1
	end
end

-- Is the wall mirrored (Sergio, 24 Nov: «ogni tanto il muro specchiato, con
-- l'apprendista dall'altro lato, a destra nel 50% dei casi»)? Only the drawing: the
-- rules see every wall from the left
function M.mirrored(key)
	return key_ok(key) and hash(key, "specchio") % 2 == 1
end

-- Can mould i of wall be hit with a direct throw (Sergio, 25 Nov: «devono essere
-- tutti raggiungibili senza rimbalzi»)? Tries the arcs from flat to high, each with
-- the power that lands on the opening's centre (y up: v^2 = g dx^2 / (2 cos^2 a (dx tan a - dy)))
function M.reachable(wall, i)
	local m = wall[i]
	local g = game.GRAVITY * game.MISSILE_GRAVITY
	for deg = 16, 82, 2 do
		local a = math.rad(deg)
		local x0, y0 = M.launch(a, 1)
		local dx, dy = m.x - x0, m.y - y0
		local d = dx * math.tan(a) - dy
		if dx > 0 and d > 0 then
			local c = math.cos(a)
			local v = math.sqrt(g * dx * dx / (2 * c * c * d))
			local power = v / game.MISSILE_SPEED
			if power >= 0.1 and power <= 1 then
				local r = M.fly(a, power, wall, {})
				if r.esito == "stampo" and r.slot == i and r.rimbalzi == 0 and r.sponde == 0 then return true end
			end
		end
	end
	return false
end

-- How easy each mould of a wall is (Sergio, 24 Nov: a mould with others in front of
-- it in the drop's way, or a low one where the dots stop high, is harder even when it
-- is not the farthest): of EASE_A x EASE_P throws over every angle and power, how many
-- end in it (bounces too). Returns { [slot] = count }
M.EASE_A, M.EASE_P = 30, 20
function M.ease(wall)
	local n = {}
	for _, m in ipairs(wall) do n[m.slot] = 0 end
	for i = 0, M.EASE_A - 1 do
		local a = math.rad(2 + 84 * (i + 0.5) / M.EASE_A)
		for j = 0, M.EASE_P - 1 do
			local r = M.fly(a, 0.1 + 0.9 * (j + 0.5) / M.EASE_P, wall, {})
			if r.esito == "stampo" then n[r.slot] = n[r.slot] + 1 end
		end
	end
	return n
end

-- The prizes by how hard the moulds really are: the sizes stay (the far ones small),
-- the Scaglie moulds swap their amounts and the fragment ones their counts so the
-- harder one always gives more (same totals per wall)
function M.by_ease(wall)
	local n = M.ease(wall)
	local function hardest_last(a, b)
		if n[a.slot] ~= n[b.slot] then return n[a.slot] > n[b.slot] end
		return a.slot < b.slot
	end
	for _, field in ipairs({ "scaglie", "n" }) do
		local ms, vals = {}, {}
		for _, m in ipairs(wall) do
			if m[field] then ms[#ms + 1] = m; vals[#vals + 1] = m[field] end
		end
		table.sort(vals)
		table.sort(ms, hardest_last)
		for i, m in ipairs(ms) do m[field] = vals[i] end
	end
	for _, m in ipairs(wall) do m.ease = n[m.slot] end
end

-- The wall of key for seed (lucky: the slot of the double mould, or nil):
-- { { slot, x, y, w, inner, depth, chain, small, scaglie | set + n, lucky } }
local LAYOUTS, LAYOUTS_N = {}, 0
local NONE_LIST = {}
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
	-- still be hit (a mould can cover another from the drop's way); then, with the
	-- moulds' true sizes, each one must still be hit directly: a spot that isn't is
	-- left out and the wall picked again
	local banned, out = {}, nil
	for _ = 1, 12 do
		local picked = {}
		for _, sp in ipairs(spots) do
			local ok = not banned[sp]
			for _, q in ipairs(ok and picked or NONE_LIST) do
				-- apart, and never one over the other
				local dx, dy = sp.x - q.x, sp.y - q.y
				if dx * dx + dy * dy < M.SPOT_GAP * M.SPOT_GAP or math.abs(sp.x - q.x) < M.COLUMN then ok = false; break end
			end
			if ok then
				picked[#picked + 1] = sp
				local probe = {}
				for i, q in ipairs(picked) do probe[i] = { slot = i, x = q.x, y = q.y, w = B, inner = B * 0.36, depth = B * 0.78 } end
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
		out = {}
		for i, sp in ipairs(picked) do
			local pz = M.PRIZES[i]
			local m = { slot = i, x = sp.x, y = sp.y, w = pz.w, inner = pz.w * 0.36, depth = pz.w * 0.78,
				small = pz.w < B, scaglie = pz.scaglie, lucky = lucky == i or nil, spot = sp }
			if sp.y > 100 then m.chain = M.CEILING - sp.y end
			if pz.frammenti then m.set, m.n = equip.SETS[hash(seed, key, i, "famiglia") % #equip.SETS + 1].id, pz.frammenti end
			out[i] = m
		end
		local bad
		for i = 1, #out do
			if not M.reachable(out, i) then bad = out[i].spot; break end
		end
		out.box = nil
		for _, m in ipairs(out) do m.spot, m.irons, m.lidded = nil, nil, nil end
		if not bad then break end
		banned[bad] = true
	end
	M.by_ease(out)
	-- the second and third wall of the day: every prize times the wall's multiplier
	-- (Scaglie to the nearest 5; the fragments' total rounded, the extra ones to the
	-- hardest fragment moulds)
	local _, mult = M.level(key)
	if mult ~= 1 then
		local frs, total = {}, 0
		for _, m in ipairs(out) do
			if m.scaglie then
				m.scaglie = math.floor(m.scaglie * mult / 5 + 0.5) * 5
			else
				frs[#frs + 1] = m
				total = total + m.n
			end
		end
		local extra = math.floor(total * mult + 0.5) - total
		table.sort(frs, function(a, b)
			if a.ease ~= b.ease then return a.ease < b.ease end
			return a.slot < b.slot
		end)
		for i = 1, extra do
			local m = frs[(i - 1) % #frs + 1]
			m.n = m.n + 1
		end
	end
	for _, m in ipairs(out) do
		if m.lucky then
			if m.scaglie then m.scaglie = m.scaglie * 2 else m.n = m.n * 2 end
		end
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
	return M.layout(key, M.SEED, M.lucky_slot(key))
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

-- The drop is a ball (Sergio, 24 Nov: «se la colata prende un bordo e rimbalza, deve
-- poter arrivare in un altro contenitore più in basso, finché non tocca terra è
-- valido»): it bounces off the moulds' iron and counts until it touches the floor.
-- Each mould is a round belly (a circle under the rim, as wide as the mould) and two
-- round rim lips beside the opening; a full mould is closed by its metal at the rim.
M.BOUNCE = 0.5           -- of the speed into the iron, what comes back
M.SLIDE = 0.92           -- of the speed along the iron, what stays at each bounce
M.BELLY = 0.4            -- the belly's radius, of the mould's width (its top at the rim, its bottom at the drawing's)
M.LIP = 0.07             -- the rim lips' radius, of the mould's width
M.STILL = 90             -- ticks almost still (resting on a lip): it drips down, a miss
-- The catch (Sergio, 24 Nov, on https://claude.ai/artifact/Gjq7oJAtJP1yXvLshSxXAa: «al 30%»):
-- the line that takes the drop sits on top of the rim lips and covers the opening and
-- CATCH of the lips plus the drop (0 = up to the lips, 1 = all of them and the drop's
-- radius): a drop coming down on the inner part of a lip falls in, on the outer part
-- it bounces out
M.CATCH = 0.3

-- The lid of a full mould (Sergio, 24 Nov: «l'hitbox del coperchio un pochino più
-- coerente col coperchio»): the drawn lid's dome (WB-094, client/menu/forge_ui.lua
-- seal: 1.02 of the mould wide, from 0.11 under the rim to 0.48 over it) as a circle
M.LID_R, M.LID_Y = 0.54, -0.08

-- The back wall (Sergio, 24 Nov: «in fondo a destra un muro, ad un po' di distanza
-- dall'ultimo vaso, raggiungibile col tiro, fa rimbalzare la palla con un toc, come
-- se sbattesse su della plastica»): a wall from the floor up, at BACK_X (the farthest
-- moulds end by 1510; at full power the drop gets there at about -50)
M.BACK_X = 1640
-- the push up (Sergio, 25 Nov: «quasi un booster verso l'alto ... con l'angolo
-- invertito e sempre verso l'alto»; numbers chosen on the test page): the drop goes
-- back with BACK_PUSH of its speed, at the angle it came (rising or falling), but
-- always upward, between BACK_MIN and BACK_MAX degrees
M.BACK_PUSH, M.BACK_MIN, M.BACK_MAX = 0.75, 30, 85

-- where the drop is taken by mould m: the line's height and half width
function M.catch(m)
	local lip = m.w * M.LIP
	return m.y + lip + M.DROP_R * 0.5, m.inner + M.CATCH * (2 * lip + M.DROP_R)
end

-- the round iron of mould m: { cx, cy, r } (closed: with its lid on)
local function irons(m, closed)
	local k = closed and "lidded" or "irons"
	local out = m[k]
	if not out then
		local lip = m.w * M.LIP
		out = {
			{ m.x, m.y - m.w * M.BELLY, m.w * M.BELLY },
			{ m.x - m.inner - lip, m.y, lip },
			{ m.x + m.inner + lip, m.y, lip },
		}
		if closed then out[4] = { m.x, m.y + m.w * M.LID_Y, m.w * M.LID_R } end
		m[k] = out
	end
	return out
end

-- the drop at (x, y) going (vx, vy) against a circle: pushed out and bounced
-- (nil when it doesn't touch)
local function bounce(c, x, y, vx, vy)
	local dx, dy = x - c[1], y - c[2]
	local rr = c[3] + M.DROP_R
	local d2 = dx * dx + dy * dy
	if d2 >= rr * rr or d2 == 0 then return nil end
	local d = math.sqrt(d2)
	local nx, ny = dx / d, dy / d
	local vn = vx * nx + vy * ny
	x, y = c[1] + nx * rr, c[2] + ny * rr
	local hard = vn < -30
	if vn < 0 then
		local tx, ty = vx - vn * nx, vy - vn * ny
		vx = tx * M.SLIDE - vn * M.BOUNCE * nx
		vy = ty * M.SLIDE - vn * M.BOUNCE * ny
	end
	return x, y, vx, vy, hard
end

-- The flight of a throw against the moulds of a wall (full: the slots already
-- filled, closed by their lid). Returns { esito = "stampo" | "secchio", slot, ticks,
-- rimbalzi (the knocks on the moulds' iron: the «rintocchi»), sponde (on the back
-- wall) } and, when points is true, the drop's positions tick by tick (for drawing)
-- and the ticks of the bounces (path.hits, and path.walls for the back wall).
-- upto (drawing only): stop after so many ticks (the aim's dots need only the
-- start: the whole flight every frame of the aim was ~900 tables a frame)
local NONE = {}
function M.fly(angle, power, wall, full, points, upto)
	full = full or {}
	local x, y, vx, vy = M.launch(angle, power)
	local g = game.GRAVITY * game.MISSILE_GRAVITY
	local path = points and { { x, y }, hits = {}, walls = {} } or nil
	local hits, still, walls = 0, 0, 0
	-- (a mould's iron and opening are all within 2 widths of its mouth: the far ones
	-- are skipped, and the whole wall when the drop is far from all of them; same
	-- result, faster)
	local box = wall.box
	if not box then
		box = { math.huge, -math.huge, math.huge, -math.huge }
		for _, m in ipairs(wall) do
			box[1], box[2] = math.min(box[1], m.x - 2 * m.w), math.max(box[2], m.x + 2 * m.w)
			box[3], box[4] = math.min(box[3], m.y - 2 * m.w), math.max(box[4], m.y + 2 * m.w)
		end
		wall.box = box
	end
	local dt, abs = game.DT, math.abs
	for t = 1, upto or M.MAX_TICKS do
		vy = vy - g * dt
		local nx, ny = x + vx * dt, y + vy * dt
		local hit = false
		local reach = abs(vx * dt) + abs(vy * dt) + M.DROP_R
		local any = nx > box[1] - reach and nx < box[2] + reach and ny > box[3] - reach and ny < box[4] + reach
		for _, m in ipairs(any and wall or NONE) do
			local near = math.abs(nx - m.x) < 2 * m.w + reach and math.abs(ny - m.y) < 2 * m.w + reach
			-- through the opening, going down: in (a full one has its lid on)
			local closed = full[m.slot]
			if near and not closed then
				local ly, half = M.catch(m)
				if y >= ly and ny < ly then
					local cx = x + (nx - x) * (y - ly) / (y - ny)
					if math.abs(cx - m.x) <= half then
						if path then path[#path + 1] = { cx, ly } end
						return { esito = "stampo", slot = m.slot, ticks = t, rimbalzi = hits, sponde = walls }, path
					end
				end
			end
			if near then
				for _, c in ipairs(irons(m, closed)) do
					local bx, by, bvx, bvy, hard = bounce(c, nx, ny, vx, vy)
					if bx then
						nx, ny, vx, vy = bx, by, bvx, bvy
						if hard then hit = true end
					end
				end
			end
		end
		if hit then
			hits = hits + 1
			if path then path.hits[#path.hits + 1] = t end
		end
		-- the back wall: back with a toc
		if nx + M.DROP_R > M.BACK_X and vx > 0 then
			local sp = math.sqrt(vx * vx + vy * vy) * M.BACK_PUSH
			local up = math.max(math.rad(M.BACK_MIN), math.min(math.rad(M.BACK_MAX), math.atan2(math.abs(vy), math.abs(vx))))
			nx, vx, vy = M.BACK_X - M.DROP_R, -math.cos(up) * sp, math.sin(up) * sp
			walls = walls + 1
			if path then path.walls[#path.walls + 1] = t end
		end
		-- resting on a lip: it drips down on the outside
		if vx * vx + vy * vy < 400 then still = still + 1 else still = 0 end
		x, y = nx, ny
		if path then path[#path + 1] = { x, y } end
		if y - M.DROP_R < M.FLOOR or x < -400 or still > M.STILL then
			return { esito = "secchio", ticks = t, rimbalzi = hits, sponde = walls }, path
		end
	end
	return { esito = "secchio", ticks = M.MAX_TICKS, rimbalzi = hits, sponde = walls }, path
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
	f.jackpot = f.jackpot or 0
	f.rintocchi = f.rintocchi or 0
	return p
end

-- Every mould of the wall key filled: the wall is done and can't be poured on
-- again (Sergio, 25 Nov)
function M.full(p, key)
	M.init(p)
	local f = p.fornace
	if key ~= f.muro then return false end
	for _, m in ipairs(M.wall(p, key)) do
		if not f.pieni[m.slot] then return false end
	end
	return true
end

-- The wall p is on today: the one of its last pour, or the next one of the day
-- when that is full (the third stays, full, until 5 in the morning), or the first
function M.current(p, today)
	M.init(p)
	local f = p.fornace
	if f.muro:sub(1, 10) ~= tostring(today) or not key_ok(f.muro) then return M.key(today, 0) end
	local n = M.level(f.muro)
	if f.tiri <= 0 and n < M.WALLS - 1 and M.full(p, f.muro) then return M.key(today, n + 1) end
	return f.muro
end

-- A pour on the wall key (the phone says which wall it sees: it must be the one
-- p is on today, so a wall can't be filled again by going back to it, nor one
-- skipped). The throws of a pour stay on its wall even if the day changes meanwhile.
function M.pour(p, key, today)
	M.init(p)
	local f = p.fornace
	if f.tiri > 0 then return nil, "colata" end
	if not key_ok(key) or key ~= M.current(p, today) then return nil, "muro" end
	if M.full(p, key) then return nil, "pieno" end
	if (p.ossidiana or 0) < M.COST then return nil, "ossidiana" end
	if key ~= f.muro then
		f.fortunato = M.lucky_slot(key)
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
	local wall = M.wall(p, f.muro)
	local r = M.fly(angle, power, wall, f.pieni)
	f.tiri, f.lanci = f.tiri - 1, f.lanci + 1
	if r.esito == "stampo" then
		local m = wall[r.slot]
		f.pieni[r.slot] = true
		f.centri = f.centri + 1
		r.lucky = m.lucky
		-- the bank shot: the knocks and the back wall raise the prize
		local bank = (1 + M.KNOCK_BONUS * r.rimbalzi) * (r.sponde > 0 and M.WALL_BONUS or 1)
		bank = math.min(M.BANK_MAX, bank)
		if bank > 1 then r.sponda = bank end
		if m.scaglie then
			r.scaglie = math.floor(m.scaglie * bank)
		else
			r.set, r.n = m.set, math.floor(m.n * bank)
			orders.init(p)
			p.commesse.frammenti[m.set] = (p.commesse.frammenti[m.set] or 0) + m.n
		end
		-- the consolation is paid on every throw, a hit too (Sergio, 25 Nov: «non voglio
		-- penalizzare chi fa centro non dandogli qualcosa che avrebbe comunque»)
		r.base = M.MISS
		p.scaglie = (p.scaglie or 0) + M.MISS
	else
		r.scaglie = M.MISS
	end
	if r.scaglie then p.scaglie = (p.scaglie or 0) + r.scaglie end
	-- the knocks' medals, the first time
	for _, k in ipairs(M.KNOCKS) do
		if r.rimbalzi >= k and f.rintocchi < k then r.knocks = k end
	end
	f.rintocchi = math.max(f.rintocchi, r.rimbalzi)
	if r.esito == "stampo" then
		local all = true
		for _, m in ipairs(wall) do if not f.pieni[m.slot] then all = false; break end end
		if all then
			f.jackpot = f.jackpot + 1
			r.jackpot, r.medal = M.JACKPOTS[M.level(f.muro) + 1] or M.JACKPOT, f.jackpot == 1 or nil
			p.scaglie = (p.scaglie or 0) + r.jackpot
			-- the jackpot closes the pour, even with throws left (Sergio, 25 Nov)
			f.tiri = 0
			return r
		end
	end
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
