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
-- at (0, 0) and y up. The wall has 12 moulds in fixed places; what each one
-- gives changes with the wall, three times a game day (at 5, 13 and 21 Italian
-- time: the key is "date#shift"). A filled mould stays full until the next wall.
--
-- The profile's field (added by M.init): fornace = { muro, pieni[slot], tiri,
-- lanci, centri, colate }: the wall of the last pour, the moulds filled on it,
-- the throws left, the throws and hits of the pour, the pours made.

local game = require "sim.game"
local equip = require "sim.gear"
local orders = require "sim.orders"

local M = {}

M.COST = 20              -- Ossidiana per pour
M.THROWS = 3             -- throws per pour
M.BONUS = 1              -- extra throws for a perfect pour (all hits)
M.MISS = 20              -- Scaglie for a drop that misses (it falls in the bucket)
M.MELT_IN, M.MELT_OUT = 4, 1   -- fragments of a family for one of another
M.MELT_SCAGLIE = 20      -- Scaglie for one fragment
M.SHIFT_HOURS = 8        -- a new wall every 8 hours of the game day (5, 13, 21)
M.FLOOR = -144           -- the forge's floor
M.DROP_R = 4             -- the drop's radius
M.MAX_TICKS = 900

-- The moulds: centre of the opening (x) and its rim (y), width, big or small,
-- chain length (drawn only) and the prize: Scaglie, or n fragments of a family
-- that changes with the wall. 255 Scaglie and 8 fragments per wall. The far
-- ones need 93-96% of the power.
local B, P = 78, 52
M.MOULDS = {
	{ x = 380, y = 26, w = B, scaglie = 15 },
	{ x = 520, y = 166, w = B, frammenti = 1, chain = 120 },
	{ x = 660, y = -64, w = B, scaglie = 20 },
	{ x = 780, y = 286, w = P, frammenti = 1, chain = 90 },
	{ x = 880, y = 66, w = B, scaglie = 30 },
	{ x = 960, y = 386, w = P, frammenti = 2, chain = 60 },
	{ x = 1060, y = 186, w = B, frammenti = 1, chain = 160 },
	{ x = 1160, y = -44, w = B, scaglie = 50 },
	{ x = 1220, y = 226, w = P, frammenti = 1, chain = 120 },
	{ x = 1290, y = 66, w = B, scaglie = 60 },
	{ x = 1420, y = 96, w = P, frammenti = 2, chain = 160 },
	{ x = 1450, y = -14, w = P, scaglie = 80 },
}
for i, m in ipairs(M.MOULDS) do
	m.slot = i
	m.inner = m.w * 0.36           -- half width of the opening
	m.depth = m.w * 0.78           -- from the rim to the bottom
end

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

-- The family of a fragment mould on a wall
function M.family(key, slot)
	return equip.SETS[hash(key, slot) % #equip.SETS + 1].id
end

-- The wall: the moulds with their prize ({ slot, x, y, w, scaglie | set + n })
function M.wall(key)
	local out = {}
	for i, m in ipairs(M.MOULDS) do
		local w = { slot = i, x = m.x, y = m.y, w = m.w, inner = m.inner, depth = m.depth, chain = m.chain,
			small = m.w < B, scaglie = m.scaglie }
		if m.frammenti then w.set, w.n = M.family(key, i), m.frammenti end
		out[i] = w
	end
	return out
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

-- The flight of a throw against the moulds (full: the slots already filled,
-- they are iron). Returns { esito = "stampo" | "ferro" | "secchio", slot, ticks }
-- and, when points is true, the drop's positions tick by tick (for drawing).
function M.fly(angle, power, full, points)
	full = full or {}
	local x, y, vx, vy = M.launch(angle, power)
	local g = game.GRAVITY * game.MISSILE_GRAVITY
	local path = points and { { x, y } } or nil
	for t = 1, M.MAX_TICKS do
		vy = vy - g * game.DT
		local nx, ny = x + vx * game.DT, y + vy * game.DT
		for _, m in ipairs(M.MOULDS) do
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
	p.ossidiana = p.ossidiana - M.COST
	if key ~= f.muro then f.muro, f.pieni = key, {} end
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
	local r = M.fly(angle, power, f.pieni)
	f.tiri, f.lanci = f.tiri - 1, f.lanci + 1
	if r.esito == "stampo" then
		local m = M.wall(f.muro)[r.slot]
		f.pieni[r.slot] = true
		f.centri = f.centri + 1
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
