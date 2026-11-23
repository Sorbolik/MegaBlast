-- The test bench of the Smith's orders (docs/commesse.md, "Come si prova"):
-- what the BANCO DI PROVA panel of the settings and the simulator do to a
-- TEST profile to see every state without playing or waiting. Test-only: at
-- the release this file and its panel go away, and nothing in sim/orders.lua
-- knows about it (it goes through the same doors as the real game: "a match
-- ended", "today is this day"). The bench's own notes live in
-- p.commesse.prova = { giorni = days moved ahead, partite = made-up matches }.
-- Pure Lua (tests/orders_test.lua).

local orders = require "sim.orders"
local maps = require "sim.maps"

local M = {}

local function notes(p)
	orders.init(p)
	local c = p.commesse
	c.prova = c.prova or { giorni = 0, partite = 0 }
	return c.prova
end

-- a day number -> "2026-11-23" (the reverse of orders.day_number)
function M.date(day)
	local z = day + 719468
	local era = math.floor(z / 146097)
	local doe = z - era * 146097
	local yoe = math.floor((doe - math.floor(doe / 1460) + math.floor(doe / 36524) - math.floor(doe / 146096)) / 365)
	local doy = doe - (365 * yoe + math.floor(yoe / 4) - math.floor(yoe / 100))
	local mp = math.floor((5 * doy + 2) / 153)
	local d = doy - math.floor((153 * mp + 2) / 5) + 1
	local m = mp < 10 and mp + 3 or mp - 9
	local y = yoe + era * 400 + (m <= 2 and 1 or 0)
	return string.format("%04d-%02d-%02d", y, m, d)
end

-- The day the test profile lives in: the real one plus the days moved ahead.
-- The screens of the orders ask this instead of the real date when the
-- profile is a test one
function M.today(p, real)
	return M.date(orders.day_number(real) + notes(p).giorni)
end

-- "A day passes" (n: 1, or 7 for a week): the board refills
function M.days(p, real, n)
	local t = notes(p)
	t.giorni = t.giorni + (n or 1)
	orders.refresh(p, M.today(p, real))
	return M.today(p, real)
end

-- "A made-up online match ends": with a mate, on the next map of the rotation
-- (so every material drops in turn), with fair numbers. won: nil = yes.
-- Returns the receipt's rows, like a real one
function M.match(p, real, won)
	local t = notes(p)
	t.partite = t.partite + 1
	local map = maps.ROTATION[(t.partite - 1) % #maps.ROTATION + 1]
	if won == nil then won = true end
	local s = orders.clean({ mappa = map, umani = 2, modo = "2v2", won = won, premi = t.partite % 3 == 0 and 1 or 0,
		punti = 140, danno = 140, nel_vuoto = 1, casse = 1, teletrasporti = 1,
		squadra = { punti = 260, danno = 260, nel_vuoto = 2 } }, t.partite % 4 == 0)
	return orders.match(p, s, M.today(p, real))
end

-- "A client arrives": the next custode you don't have. Returns its id, nil when all are here
function M.client(p, real)
	notes(p)
	for _, cl in ipairs(orders.CLIENTS) do
		if orders.add_client(p, cl.id) then
			orders.refresh(p, M.today(p, real))
			return cl.id
		end
	end
end

-- "The next delivery is a lucky strike": moves the draw's counter up to one
function M.lucky(p)
	notes(p)
	local c = p.commesse
	for _ = 1, 10 * orders.LUCKY_EVERY do
		if orders.lucky(p) then return true end
		c.consegne = c.consegne + 1
	end
	return orders.lucky(p)
end

-- "The pieces go back to the shop": the test profile no longer owns these
-- pieces (wallet keys), so the BANCO shows their prices again
function M.give_back(p, keys)
	for _, k in ipairs(keys) do p.posseduti[k] = nil end
end

-- "Start over": the orders as on a new profile (the first time: the Smith calls
-- after the fifth match)
function M.reset(p)
	p.commesse = nil
	notes(p)
	return p
end

-- The END OF THE GAME test profile: the bottega open, every client, and a bit
-- of everything to look at: a welcome order waiting, an order ready, one half
-- done, the week's at its second request, trust below and beyond the first
-- lap, full and empty shelves. Only where the orders never opened: what you
-- do on the bench afterwards stays.
local TRUST = { caronte = 12, minosse = 9, cerbero = 5, plutone = 4, flegias = 1, minotauro = 23, malacoda = 1 }
local FRAGMENTS = { fabbro = 130, corvo = 64, fornace = 12, leviatano = 250, vuoto = 3 }

function M.fill(p, real)
	notes(p)
	local c = p.commesse
	if c.aperta then return false end
	orders.open(p)
	for _, cl in ipairs(orders.CLIENTS) do
		orders.add_client(p, cl.id)
		if TRUST[cl.id] then c.clienti[cl.id].fiducia, c.clienti[cl.id].benvenuto = TRUST[cl.id], true end
	end
	-- only Medusa's welcome order still waits
	c.attesa = { "medusa" }
	for set, n in pairs(FRAGMENTS) do c.frammenti[set] = n end
	for i, m in ipairs(orders.MATERIALS) do c.materiali[m.id] = ({ 0, 2, 5, 99, 1, 14 })[i % 6 + 1] end
	c.materiali[orders.JOLLY] = 0
	orders.refresh(p, M.today(p, real))
	-- the feats asked: the first one done, the others at two thirds
	local first = true
	for _, o in ipairs(orders.orders(p)) do
		for _, r in ipairs({ o, o.poi }) do
			if r.impresa then
				r.fatti = first and r.quanti or math.floor(r.quanti * 2 / 3)
				first = false
			end
		end
	end
	return true
end

return M
