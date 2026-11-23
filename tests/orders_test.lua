-- The Smith's orders (sim/orders.lua, rules in docs/commesse.md): the opening,
-- materials, the board, feats, deliveries, trust, the call, the change, the
-- week's order, fragments as money. From the root:
--   luajit tests/orders_test.lua
package.path = "client/?.lua;" .. package.path

local orders = require "sim.orders"
local wallet = require "sim.wallet"
local equip = require "sim.gear"

local failures = 0
local function check(cond, msg)
	if cond then
		print("ok   " .. msg)
	else
		print("FAIL " .. msg)
		failures = failures + 1
	end
end

local function new()
	local p = wallet.init({ stelle = {} })
	orders.init(p)
	return p
end

-- a finished online match: gola, 2 vs 2, won, with another person
local function match(over)
	local s = { mappa = "gola", umani = 2, modo = "2v2", won = true, premi = 0, punti = 150, danno = 150,
		nel_vuoto = 1, casse = 0, teletrasporti = 0, squadra = { punti = 300, danno = 300, nel_vuoto = 1 } }
	for k, v in pairs(over or {}) do s[k] = v end
	return orders.clean(s, over and over.mvp)
end

local function row(rows, key)
	for _, r in ipairs(rows or {}) do
		if r.key == key then return r end
	end
end

local D1, D2, D3, D4 = "2026-11-23", "2026-11-24", "2026-11-25", "2026-11-26"

-- Days ---------------------------------------------------------------------------------
check(orders.day_number("1970-01-01") == 0 and orders.day_number("1970-01-02") == 1, "day numbers start at 1 Jan 1970")
check(orders.day_number(D2) - orders.day_number(D1) == 1, "the next day is one more")
check(orders.day_number("2027-01-01") - orders.day_number("2026-12-31") == 1, "over the year's end too")
check(orders.day_number("2028-03-01") - orders.day_number("2028-02-28") == 2, "and a leap year")
-- 23 Nov 2026 is a Monday
check(orders.week(orders.day_number("2026-11-22")) + 1 == orders.week(orders.day_number(D1)), "the week turns on Monday")
check(orders.week(orders.day_number(D1)) == orders.week(orders.day_number("2026-11-29")), "and holds until Sunday")
check(orders.day_number("oggi") == nil, "an unreadable day is nil")

-- The opening --------------------------------------------------------------------------
local p = new()
for i = 1, orders.OPEN_AFTER - 1 do
	local rows = orders.match(p, match({ umani = 1 }), D1)
	check(#rows == 0 and not p.commesse.aperta, "match " .. i .. ": still closed, nothing drops")
end
check(orders.materials(p, "grandine") == 0, "no materials before the Smith calls")
local rows = orders.match(p, match({ umani = 1 }), D1)
check(row(rows, "open") and p.commesse.aperta, "after " .. orders.OPEN_AFTER .. " online matches the Smith calls (even alone with bots)")
local first = p.commesse.fabbro
local _, ready = orders.progress(p, first)
check(first and ready and orders.cost(first) == 0, "his first order is already done and free")
check(orders.deliver(p, first.n) == nil, "the Smith's order wants a family")
check(orders.deliver(p, first.n, "nessuna") == nil, "a real one")
local got = orders.deliver(p, first.n, "corvo", false)
check(got and row(got, "scaglie").n == orders.SIZES.fabbro.scaglie and orders.fragments(p, "corvo") == 1,
	"delivered: his Scaglie and a fragment of the family picked")
check(not row(got, "ossidiana") and p.ossidiana == 0, "the first costs nothing")
check(p.commesse.fabbro.n ~= first.n and orders.cost(p.commesse.fabbro) == 20, "his order starts again at once, at 20 Ossidiana")
_, ready = orders.progress(p, p.commesse.fabbro)
check(not ready, "and from zero")

-- Materials and the rule of the people ---------------------------------------------------
rows = orders.match(p, match({ umani = 1 }), D1)
check(#rows == 0 and orders.materials(p, "grandine") == 0, "alone with bots: no materials, no progress")
rows = orders.match(p, match({ won = false }), D1)
check(row(rows, "material").n == orders.DROP and orders.materials(p, "grandine") == 2, "a lost match with a person: 2 of the map's material")
rows = orders.match(p, match(), D1)
check(row(rows, "material").n == orders.DROP_WIN and orders.materials(p, "grandine") == 5, "a won one: 3")
_, ready = orders.progress(p, p.commesse.fabbro)
check(ready, "and the Smith's order (2 matches) is ready")
check(orders.ready_count(p) == 1, "one order ready")
check(orders.deliver(p, p.commesse.fabbro.n, "fornace") == nil, "but without Ossidiana it stays there")
p.ossidiana = 20
got = orders.deliver(p, p.commesse.fabbro.n, "fornace", false)
check(got and row(got, "ossidiana").n == -20 and p.ossidiana == 0, "with 20 Ossidiana it goes")
orders.match(p, match({ mappa = "pavimento" }), D1)
check(orders.materials(p, "scoria") == 3, "the Forge's maps give the Scoria")
orders.match(p, match({ mappa = "mappa_che_non_esiste" }), D1)
check(true, "a map without a material drops nothing")
p.commesse.materiali.grandine = 98
orders.match(p, match(), D1)
check(orders.materials(p, "grandine") == orders.MATERIAL_MAX, "never more than 99 of a material")

-- The swap -----------------------------------------------------------------------------
p.commesse.materiali.grandine = 7
check(orders.trade(p, "grandine", "stige") and orders.materials(p, "grandine") == 4 and orders.materials(p, "stige") == 1,
	"the swap: 3 for 1")
check(orders.trade(p, "grandine", "grandine") == nil and orders.trade(p, "grandine", "oro") == nil, "not with itself, not with nothing")
p.commesse.materiali.grandine = 2
check(orders.trade(p, "grandine", "stige") == nil, "not with fewer than 3")

-- Clients: the welcome order ---------------------------------------------------------------
p = new()
orders.open(p)
orders.refresh(p, D1)
check(orders.places(p) == 0 and #p.commesse.bacheca == 0, "without clients: only the Smith")
check(orders.add_client(p, "cerbero") and not orders.add_client(p, "cerbero") and not orders.add_client(p, "nessuno"),
	"a client arrives once")
orders.refresh(p, D1)
check(orders.places(p) == 1 and #p.commesse.bacheca == 1, "one client, one place")
local w = p.commesse.bacheca[1]
check(w.taglia == "benvenuto" and w.cliente == "cerbero" and w.materiale == "grandine" and orders.cost(w) == 0,
	"its welcome order is up at once: its own material, free")
check(orders.change(p, w.n, D1) == nil, "a welcome order can't be torn")
_, ready = orders.progress(p, w)
check(not ready, "not ready without the material")
check(orders.deliver(p, w.n) == nil, "and it can't be delivered")
p.commesse.materiali.grandine, p.commesse.materiali.scoria = 3, 1
local prog
prog, ready = orders.progress(p, w)
check(ready and prog[1].done == 4, "3 of its material and 1 Scoria make 4")
local vouchers = p.buoni
got = orders.deliver(p, w.n, nil, false)
check(got and row(got, "voucher") and p.buoni == vouchers + 1, "the welcome order gives the Smith's voucher")
check(orders.materials(p, "grandine") == 0 and orders.materials(p, "scoria") == 0, "its own material goes first, then the Scoria")
check(orders.fragments(p, "fornace") == 1 and orders.trust(p, "cerbero") == 1, "a fragment of the client's family and a pearl of trust")
check(#p.commesse.bacheca == 0, "the place is free")
orders.refresh(p, D1)
check(#p.commesse.bacheca == 0, "and stays free until the morning")
orders.refresh(p, D2)
check(#p.commesse.bacheca == 1 and p.commesse.bacheca[1].cliente == "cerbero" and p.commesse.bacheca[1].taglia ~= "benvenuto",
	"the next day a new order of the client")

-- the client from the campaign: its level must be won
p = new()
orders.open(p)
p.stelle.caronte = { false, false, false }
orders.refresh(p, D1)
check(not p.commesse.clienti.caronte, "a custode's level not won brings nobody")
p.stelle.caronte = { true, false, false }
orders.refresh(p, D1)
check(p.commesse.clienti.caronte and p.commesse.bacheca[1].cliente == "caronte", "the first win brings the client, no stars needed")

-- Places grow with the clients -------------------------------------------------------------
p = new()
orders.open(p)
for i, c in ipairs(orders.CLIENTS) do
	orders.add_client(p, c.id)
	local want = i >= 6 and 3 or i >= 3 and 2 or 1
	check(orders.places(p) == want, i .. " clients: " .. want .. " places")
end
orders.refresh(p, D1)
check(#p.commesse.bacheca == 3, "three places filled")
local seen, twice = {}, false
for _, o in ipairs(p.commesse.bacheca) do
	if seen[o.cliente] then twice = true end
	seen[o.cliente] = true
end
check(not twice, "never two orders of the same client")
check(#p.commesse.attesa == 5, "the other welcome orders wait for a place")
check(p.commesse.settimana and p.commesse.settimana.taglia == "settimana" and orders.cost(p.commesse.settimana) == 100,
	"from three clients the week's order, 100 Ossidiana")

-- Feats: the team's numbers in 2 vs 2 ---------------------------------------------------------
p = new()
orders.open(p)
orders.add_client(p, "cerbero")
p.commesse.clienti.cerbero.benvenuto = true
p.commesse.attesa = {}
p.commesse.giorno = D1
p.commesse.bacheca[1] = { n = 900, cliente = "cerbero", taglia = "piccola", impresa = "nel_vuoto", quanti = 3, fatti = 0 }
local o = p.commesse.bacheca[1]
orders.match(p, match({ nel_vuoto = 0, squadra = { punti = 300, danno = 300, nel_vuoto = 1 } }), D1)
check(o.fatti == 1, "in 2 vs 2 the mate's enemy thrown down counts: 1 of 3")
rows = orders.match(p, match({ nel_vuoto = 1, squadra = { punti = 300, danno = 300, nel_vuoto = 1 } }), D1)
check(o.fatti == 2 and row(rows, "order").done == 2 and row(rows, "order").asked == 3, "2 of 3, and the receipt says so")
_, ready = orders.progress(p, o)
check(not ready, "not ready at 2 of 3")
rows = orders.match(p, match({ modo = "ffa", nel_vuoto = 1, squadra = false }), D1)
check(o.fatti == 3 and row(rows, "order").ready, "outside 2 vs 2 your own number: 3 of 3, ready")
orders.match(p, match({ nel_vuoto = 5 }), D1)
check(o.fatti == 3, "a done order doesn't go past what it asks")
check(orders.deliver(p, o.n) == nil, "20 Ossidiana to deliver it")
p.ossidiana = 50
got = orders.deliver(p, o.n, nil, false)
check(got and p.ossidiana == 30 and row(got, "scaglie").n == 80 and row(got, "fragments").n == 1 and row(got, "fragments").set == "fornace",
	"a small order: 20 Ossidiana for 80 Scaglie and a fragment of the client's family")

-- each feat counts what it says
local function gain(feat, s)
	local q = new()
	orders.open(q)
	q.commesse.giorno = D1
	q.commesse.fabbro = { n = 1, taglia = "fabbro", impresa = feat, quanti = 99999, fatti = 0 }
	orders.match(q, s, D1)
	return q.commesse.fabbro.fatti
end
check(gain("partite", match({ won = false })) == 1, "partite: one a match, even lost")
check(gain("vinte", match()) == 1 and gain("vinte", match({ won = false })) == 0, "vinte: the wins")
check(gain("vinte_2v2", match()) == 1 and gain("vinte_2v2", match({ modo = "ffa" })) == 0, "vinte_2v2: only in 2 vs 2")
check(gain("punti", match()) == 300 and gain("punti", match({ modo = "ffa", squadra = false })) == 150, "punti: the team's in 2 vs 2, yours elsewhere")
check(gain("danno", match()) == 300, "danno: the team's")
check(gain("mvp", match({ mvp = true })) == 1 and gain("mvp", match()) == 0, "mvp: the best on the field")
check(gain("casse", match({ casse = 2 })) == 2 and gain("teletrasporti", match({ teletrasporti = 3 })) == 3, "casse and teletrasporti: yours")
check(gain("premi", match({ premi = 2 })) == 2, "premi: the awards of the match's end")
check(orders.clean({ punti = 1e9, nel_vuoto = -4, danno = 0 / 0, umani = 2 }).punti == 3000, "numbers from outside are cut")
check(orders.clean("ciao") == nil, "and what isn't a summary is nothing")
for id, f in pairs(orders.FEATS) do
	check(#f.amounts == 2 and f.amounts[1] < f.amounts[2], "feat " .. id .. ": a small and a medium amount")
end
for _, c in ipairs(orders.CLIENTS) do
	local ok = equip.BY_ID[c.set] ~= nil and orders.MATERIAL_OF ~= nil
	for _, f in ipairs(c.feats) do ok = ok and orders.FEATS[f] ~= nil end
	local mat = false
	for _, m in ipairs(orders.MATERIALS) do mat = mat or m.id == c.material end
	check(ok and mat, "client " .. c.id .. ": a real family, material and feats")
end
do
	local maps = require "sim.maps"
	local all = true
	for _, id in ipairs(maps.ROTATION) do all = all and orders.MATERIAL_OF[id] ~= nil end
	check(all, "every map of the online rotation has its material")
end

-- Trust ----------------------------------------------------------------------------------
p = new()
orders.open(p)
orders.add_client(p, "minosse")
p.commesse.attesa = {}
p.commesse.giorno = D1
p.ossidiana = 100000
local function deliver_small(lucky)
	p.commesse.bacheca[1] = { n = 5000 + p.commesse.consegne, cliente = "minosse", taglia = "piccola", impresa = "partite", quanti = 1, fatti = 1 }
	return orders.deliver(p, p.commesse.bacheca[1].n, nil, lucky or false)
end
for i = 1, 5 do got = deliver_small() end
check(orders.trust(p, "minosse") == 5 and row(got, "fragments").n == 1, "the fifth delivery still pays 1 fragment")
got = deliver_small()
check(row(got, "fragments").n == 2, "from 5 of trust one more fragment, for ever")
local before = orders.fragments(p, "corvo")
got = deliver_small(true)
check(row(got, "lucky").n == 2 and orders.fragments(p, "corvo") == before + 4, "a lucky strike doubles the fragments")
for i = 8, 9 do deliver_small() end
before = orders.fragments(p, "corvo")
got = deliver_small()
check(orders.trust(p, "minosse") == 10 and row(got, "gift").n == orders.TRUST_GIFT and row(got, "gift").card
	and orders.fragments(p, "corvo") == before + 2 + 30, "at 10 of trust the gift: 30 fragments and the client's card")
for i = 11, 19 do got = deliver_small() end
check(not row(got, "gift"), "nothing more until the next lap")
got = deliver_small()
check(orders.trust(p, "minosse") == 20 and row(got, "gift").n == orders.TRUST_GIFT_AGAIN and not row(got, "gift").card,
	"every other 10 a smaller gift, for ever")
p.commesse.clienti.minosse.fiducia = 999
got = deliver_small()
check(row(got, "trust").total == 1000 and row(got, "gift"), "trust never stops: 1,000 at the hundredth lap")
p.commesse.clienti.minosse.fiducia = 8
p.commesse.settimana = { n = 7000, cliente = "minosse", taglia = "settimana", settimana = 1, impresa = "partite", quanti = 1, fatti = 1 }
got = orders.deliver(p, 7000, nil, false)
check(orders.trust(p, "minosse") == 11 and row(got, "trust").n == 3 and row(got, "gift"), "the week's order is worth 3 pearls and can cross a lap")
check(p.commesse.settimana == nil, "and it leaves its place")

-- the lucky strike: about one delivery in eight
do
	local q = new()
	orders.open(q)
	local n = 0
	for i = 1, 800 do
		q.commesse.consegne, q.commesse.n = i, i * 3
		if orders.lucky(q) then n = n + 1 end
	end
	check(n > 60 and n < 140, "the lucky strike comes about once in eight (" .. n .. " of 800)")
end

-- The call -------------------------------------------------------------------------------
p = new()
orders.open(p)
for _, id in ipairs({ "caronte", "minosse", "cerbero" }) do
	orders.add_client(p, id)
	p.commesse.clienti[id].benvenuto = true
end
p.commesse.attesa = {}
orders.refresh(p, D1)
check(#p.commesse.bacheca == 2, "three clients, two places")
check(orders.call(p, "nessuno", D1) == nil, "only a client of yours can be called")
-- empty the board, call Minosse for tomorrow
p.commesse.bacheca = {}
check(orders.call(p, "minosse", D1), "Monday: call Minosse")
orders.refresh(p, D1)
check(#p.commesse.bacheca == 0, "the same day nothing new arrives")
orders.refresh(p, D2)
check(p.commesse.bacheca[1].cliente == "minosse", "Tuesday: Minosse is on the board")
check(orders.can_call(p, "minosse", D2) == false and orders.call(p, "minosse", D2) == nil, "Tuesday he can't be called again")
check(orders.call(p, "cerbero", D2), "so Cerbero is called")
p.commesse.bacheca = {}
orders.refresh(p, D3)
check(p.commesse.bacheca[1].cliente == "cerbero", "Wednesday: Cerbero is on the board")
check(orders.can_call(p, "minosse", D3) and orders.call(p, "minosse", D3), "and Minosse can be called again")
-- a full board: the called client waits for a free place
p.commesse.bacheca = { { n = 1, cliente = "caronte", taglia = "piccola", impresa = "partite", quanti = 9, fatti = 0 },
	{ n = 2, cliente = "cerbero", taglia = "piccola", impresa = "partite", quanti = 9, fatti = 0 } }
orders.refresh(p, D4)
check(#p.commesse.bacheca == 2 and p.commesse.chiamato and p.commesse.chiamato.cliente == "minosse", "with a full board the called client waits")
table.remove(p.commesse.bacheca, 1)
orders.refresh(p, "2026-11-27")
check(p.commesse.bacheca[2].cliente == "minosse" and p.commesse.chiamato == nil, "and takes the first place that frees")

-- The change -----------------------------------------------------------------------------
p = new()
orders.open(p)
for _, id in ipairs({ "caronte", "minosse", "cerbero", "plutone" }) do
	orders.add_client(p, id)
	p.commesse.clienti[id].benvenuto = true
end
p.commesse.attesa = {}
orders.refresh(p, D1)
local old = p.commesse.bacheca[1]
local other = p.commesse.bacheca[2].cliente
check(orders.can_change(p, D1), "the day's change is there")
local new_order = orders.change(p, old.n, D1)
check(new_order and new_order.n ~= old.n and new_order.cliente ~= old.cliente and new_order.cliente ~= other,
	"a torn card: another client's order, not one already on the board")
check(not orders.can_change(p, D1) and orders.change(p, new_order.n, D1) == nil, "only once a day")
check(orders.can_change(p, D2), "tomorrow again")
check(orders.change(p, p.commesse.settimana.n, D2) == nil and orders.change(p, p.commesse.fabbro.n, D2) == nil,
	"the week's and the Smith's can't be torn")
-- with one client only: another request of the same client
p = new()
orders.open(p)
orders.add_client(p, "cerbero")
p.commesse.attesa = {}
orders.refresh(p, D1)
old = p.commesse.bacheca[1]
new_order = orders.change(p, old.n, D1)
check(new_order and new_order.cliente == "cerbero" and (new_order.impresa ~= old.impresa or new_order.materiale ~= old.materiale
	or new_order.quanti ~= old.quanti), "with one client: another request of the same")

-- Daily orders never expire; the week's does ----------------------------------------------------
p = new()
orders.open(p)
for _, id in ipairs({ "caronte", "minosse", "cerbero" }) do
	orders.add_client(p, id)
	p.commesse.clienti[id].benvenuto = true
end
p.commesse.attesa = {}
orders.refresh(p, D1)
local a, b = p.commesse.bacheca[1].n, p.commesse.bacheca[2].n
local wk = p.commesse.settimana
orders.refresh(p, "2026-11-28")
check(p.commesse.bacheca[1].n == a and p.commesse.bacheca[2].n == b, "five days later the same orders are there")
check(p.commesse.settimana == wk, "the week's too, on Saturday")
orders.refresh(p, "2026-11-30")
check(p.commesse.settimana and p.commesse.settimana ~= wk and p.commesse.bacheca[1].n == a, "on Monday the week's order turns, the others stay")
-- a delivered week's order doesn't come back in the same week
wk = p.commesse.settimana
wk.quanti, wk.materiale, wk.impresa, wk.fatti, wk.poi = 1, nil, "partite", 1, nil
p.ossidiana = 100
got = orders.deliver(p, wk.n, nil, false)
check(got and row(got, "scaglie").n == 360 and row(got, "fragments").n == 6 and p.ossidiana == 0, "the week's order: 100 Ossidiana for 360 Scaglie and 6 fragments")
orders.refresh(p, "2026-12-01")
check(p.commesse.settimana == nil, "delivered, it doesn't come back this week")
orders.refresh(p, "2026-12-07")
check(p.commesse.settimana ~= nil, "the next Monday a new one")
-- the week's order asks two things
p = new()
orders.open(p)
for _, id in ipairs({ "caronte", "minosse", "cerbero" }) do orders.add_client(p, id) end
p.commesse.attesa = {}
orders.refresh(p, D1)
wk = p.commesse.settimana
prog, ready = orders.progress(p, wk)
check(#prog == 2 and wk.materiale and wk.poi.impresa and not ready, "the week's order asks materials and a feat")
p.commesse.materiali[wk.materiale] = 15
_, ready = orders.progress(p, wk)
check(not ready, "the materials alone aren't enough")
wk.poi.fatti = wk.poi.quanti
_, ready = orders.progress(p, wk)
check(ready, "both: ready")

-- The same draws on the phone and on the server ---------------------------------------------------
do
	local function board()
		local q = new()
		orders.open(q)
		for _, c in ipairs(orders.CLIENTS) do
			orders.add_client(q, c.id)
			q.commesse.clienti[c.id].benvenuto = true
		end
		q.commesse.attesa = {}
		orders.refresh(q, D1)
		orders.refresh(q, D2)
		local t = {}
		for _, o in ipairs(orders.orders(q)) do t[#t + 1] = (o.cliente or "fabbro") .. (o.impresa or o.materiale) .. o.quanti end
		return table.concat(t, ",")
	end
	check(board() == board(), "the same profile on the same day draws the same board")
end

-- Fragments as money -------------------------------------------------------------------------
p = new()
check(orders.fragment_value() == wallet.PRICE_CATALOG / orders.PIECE_FRAGMENTS, "a fragment is a 120th of a piece of the Catalogo")
check(orders.in_fragments(wallet.PRICE_CATALOG) == 120 and orders.in_fragments(1) == 1, "prices in fragments, at least one")
check(orders.buy(p, "corvo", "mask") == nil, "no fragments, no piece")
p.commesse.frammenti.corvo = 120
p.commesse.frammenti.fornace = 500
check(orders.buy(p, "corvo", "mask") and wallet.owns(p, "corvo", "mask") and orders.fragments(p, "corvo") == 0,
	"120 fragments of the family buy a piece")
check(orders.buy(p, "corvo", "mask") == nil, "not twice")
check(orders.upgrade(p, "corvo", "mask") == nil, "its level wants fragments of the same family")
check(orders.fragments(p, "fornace") == 500, "the other families' fragments don't pay it")
p.commesse.frammenti.corvo = 10
local need = orders.level_cost(p, "corvo", "mask")
check(need == orders.in_fragments(equip.cost(2)), "level 2 in fragments: its price in Scaglie turned into fragments")
check(orders.upgrade(p, "corvo", "mask") == 2 and orders.fragments(p, "corvo") == 10 - need and p.scaglie == 0,
	"fragments pay the level, the Scaglie stay")
-- the Proof of a step holds with fragments too
p.pezzi.corvo_mask = 9
p.commesse.frammenti.corvo = 9999
local _, why = orders.upgrade(p, "corvo", "mask")
check(why == "proof", "the step still wants its Proof")
p.no_proof = true
check(orders.upgrade(p, "corvo", "mask") == 10, "with the Proof done the step is paid in fragments")
p.pezzi.corvo_mask = equip.LIVELLO_MAX
_, why = orders.upgrade(p, "corvo", "mask")
check(why == "max" and orders.level_cost(p, "corvo", "mask") == nil, "nothing past the top")

-- The exchange rate ---------------------------------------------------------------------------
do
	local v = orders.fragment_value()
	local function rate(s) return (s.scaglie + s.frammenti * v) / s.cost end
	check(rate(orders.SIZES.piccola) == 6 and rate(orders.SIZES.media) == 6 and rate(orders.SIZES.settimana) == 6,
		"the clients' orders pay 6 Scaglie of value per Ossidiana")
	check(rate(orders.SIZES.fabbro) == 5, "the Smith's pays 5")
end

-- Through the profile's actions (sim/progress.lua): what the phone and the server do
do
	local progress = require "sim.progress"
	local profile = require "sim.profile"
	local D = "2026-11-23"
	local p = wallet.init(profile.new and profile.new() or { stelle = {} })
	local function online(over)
		local s = { mappa = "gola", umani = 2, modo = "2v2", won = true, premi = 0, punti = 150, danno = 150,
			nel_vuoto = 1, casse = 0, teletrasporti = 0, squadra = { punti = 300, danno = 300, nel_vuoto = 1 } }
		for k, v in pairs(over or {}) do s[k] = v end
		return { k = "partita", r = { points = 150, won = s.won, online = true, awards = {} }, commesse = s }
	end
	local gain
	for _ = 1, orders.OPEN_AFTER do gain = progress.act(p, online(), D) end
	check(gain and gain.commesse and gain.commesse[1] and gain.commesse[1].key == "open",
		"the fifth online match opens the bottega, and the receipt says so")
	check(p.commesse.fabbro ~= nil, "the Smith's first order hangs")
	-- a match declared by the phone (not online) moves nothing
	local before = p.commesse.online
	local g2 = progress.act(p, { k = "partita", r = { points = 150, won = true, awards = {} }, commesse = online().commesse }, D)
	check(g2 and g2.commesse == nil and orders.materials(p, "grandine") == 0, "a match on the phone doesn't move the orders")
	gain = progress.act(p, online(), D)
	check(orders.materials(p, "grandine") == orders.DROP_WIN, "an online match won drops the map's material")
	-- the Smith's order: free and ready the first time, a family must be picked
	local o = p.commesse.fabbro
	check(progress.act(p, { k = "consegna", n = o.n }, D) == nil, "the Smith's order wants a family")
	check(progress.act(p, { k = "consegna", n = o.n, set = "inventata" }, D) == nil, "a real one")
	local rows = progress.act(p, { k = "consegna", n = o.n, set = "corvo" }, D)
	check(rows and orders.fragments(p, "corvo") >= 1, "delivered through the action: fragments of the family picked")
	check(progress.act(p, { k = "consegna", n = o.n, set = "corvo" }, D) == nil, "never twice")
	check(progress.act(p, { k = "consegna", n = "x" }, D) == nil and progress.act(p, { k = "cambia" }, D) == nil
		and progress.act(p, { k = "chiama", cliente = 3 }, D) == nil and progress.act(p, { k = "scambia", da = "grandine" }, D) == nil,
		"actions with junk do nothing")
	check(progress.act(p, { k = "scambia", da = "grandine", a = "pece" }, D) == true and orders.materials(p, "pece") == 1,
		"the swap through the action")
	check(progress.act(p, { k = "bacheca" }, D) == true, "looking at the board is an action too")
	-- fragments as money
	p.commesse.frammenti.fornace = 500
	check(progress.act(p, { k = "compra", set = "fornace", slot = "nessuno", frammenti = true }, D) == nil
		and orders.fragments(p, "fornace") == 500, "a piece that doesn't exist can't be bought")
	local slot = equip.SLOTS[1].id
	check(progress.act(p, { k = "compra", set = "fornace", slot = slot, frammenti = true }, D) == true
		and orders.fragments(p, "fornace") == 500 - orders.PIECE_FRAGMENTS and wallet.owns(p, "fornace", slot),
		"a piece bought with fragments through the action")
	local scaglie = p.scaglie
	local lv = progress.act(p, { k = "potenzia", set = "fornace", slot = slot, frammenti = true }, D)
	check(lv == 2 and p.scaglie == scaglie, "a level bought with fragments leaves the Scaglie alone")
	-- the profile with its orders survives the trip to the server and back
	local text = require "sim.replay"
	local back = text.read(text.write(p))
	check(back and back.commesse and back.commesse.frammenti.fornace == orders.fragments(p, "fornace")
		and #orders.orders(back) == #orders.orders(p), "the orders travel with the profile")
end

if failures > 0 then
	print(failures .. " FAILED")
	os.exit(1)
end
print("orders: all ok")
