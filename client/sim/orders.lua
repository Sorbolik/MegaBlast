-- The Smith's orders, "Le Commesse del Fabbro" (Sergio, 23 Nov; rules in
-- docs/commesse.md, page https://claude.ai/artifact/MKh9TW93vC3V4FzKYdrsiW).
-- The custodi of the gironi become clients; an order is done playing online,
-- delivered paying Ossidiana, and pays Scaglie and the fragments of the
-- client's family, which buy pieces and their levels.
--
-- Pure Lua in the shared rules (sim/), like sim/wallet.lua: the phone and the
-- server (sim/progress.lua) run the same sums. It never reads the clock and
-- doesn't know what a match is: it is told "a match ended with these
-- numbers" (M.match) and "today is this day" (M.refresh). There is no "if
-- testing" in here: the test bench (menu) feeds it made-up matches and days
-- through the same doors. Tested in tests/orders_test.lua.
--
-- The profile's field p.commesse (ids and keys stay Italian: saved data):
--   aperta: the Smith called (after OPEN_AFTER online matches)
--   online: online matches counted before it opened
--   materiali[id], frammenti[set]: what you hold
--   clienti[id] = { fiducia = deliveries, benvenuto = true once its welcome order is delivered }
--   attesa = { client ids whose welcome order waits for a free place }
--   bacheca = { order, ... } the clients' places
--   settimana = order or nil, fabbro = order or nil
--   giorno, cambio: the day of the last refill and of the last swap
--   chiamato = { cliente, giorno } the client called for tomorrow, chiamata = the last call
--   n: orders made so far, consegne: deliveries made so far (the draws' counters)
-- An order: { n, cliente | nil (the Smith), taglia, materiale | impresa, quanti,
--   fatti (feats only; materials are counted from what you hold), poi = { second
--   request of the week's order }, settimana = week number (the week's order) }

local equip = require "sim.gear"
local wallet = require "sim.wallet"
local milestones = require "sim.milestones"

local M = {}

-- The numbers to tune ---------------------------------------------------------------

-- the bottega opens after this many online matches
M.OPEN_AFTER = 5
-- materials and feats count only with this many people in the match (you included)
M.MIN_HUMANS = 2
-- materials of a finished online match, and of a won one
M.DROP, M.DROP_WIN = 2, 3
M.MATERIAL_MAX = 99
-- the swap: this many of one for one of another
M.TRADE = 3
-- the clients' places by how many clients you have
M.PLACES = { { 6, 3 }, { 3, 2 }, { 1, 1 } }
-- the week's order from this many clients
M.WEEK_CLIENTS = 3

-- Sizes: Ossidiana to pay, Scaglie and fragments paid (the exchange rate: 6
-- Scaglie of value per Ossidiana from the clients, 5 from the Smith; a
-- fragment is worth a 120th of a piece of the Catalogo), pearls of trust
M.SIZES = {
	benvenuto = { cost = 0, scaglie = 80, frammenti = 1, pearls = 1, voucher = true },
	piccola = { cost = 20, scaglie = 80, frammenti = 1, pearls = 1 },
	media = { cost = 40, scaglie = 160, frammenti = 2, pearls = 1 },
	settimana = { cost = 100, scaglie = 360, frammenti = 6, pearls = 3 },
	fabbro = { cost = 20, scaglie = 60, frammenti = 1, pearls = 0 },
}
-- how many fragments make a piece of the Catalogo
M.PIECE_FRAGMENTS = 120
-- the lucky strike: one delivery in this many doubles the fragments
M.LUCKY_EVERY = 8
-- trust: from TRUST_BONUS deliveries one more fragment per order, at
-- TRUST_GIFT a gift of fragments (once), then a smaller one every TRUST_LAP
M.TRUST_BONUS, M.TRUST_LAP = 5, 10
M.TRUST_GIFT, M.TRUST_GIFT_AGAIN = 30, 10

-- The materials: one per map of the online rotation (sim/maps.lua ROTATION);
-- the two maps of the Forge give the Scoria, worth any material
M.JOLLY = "scoria"
M.MATERIALS = {
	{ id = "scoria", maps = { "pavimento", "fossa" } },
	{ id = "piuma", maps = { "limbo" } },
	{ id = "vento", maps = { "lussuria" } },
	{ id = "grandine", maps = { "gola" } },
	{ id = "scheggia", maps = { "avarizia" } },
	{ id = "stige", maps = { "ira" } },
	{ id = "tomba", maps = { "eresia" } },
	{ id = "sangue", maps = { "flegetonte" } },
	{ id = "sabbia", maps = { "sabbione" } },
	{ id = "pece", maps = { "malebolge" } },
	{ id = "ghiaccio", maps = { "cocito" } },
}
M.MATERIAL_OF = {}
local MATERIAL = {}
for _, m in ipairs(M.MATERIALS) do
	MATERIAL[m.id] = m
	for _, map in ipairs(m.maps) do M.MATERIAL_OF[map] = m.id end
end

-- The feats: numbers the match's end already counts (sim/tally.lua,
-- game:results). team: in 2 vs 2 the team's number counts. green: they agree
-- with winning (good in tournaments too); the others are harmless.
-- amounts: for a small and a medium order, and for the week's
M.FEATS = {
	partite = { green = true, amounts = { 4, 8 }, welcome = 3 },
	vinte = { green = true, amounts = { 2, 4 } },
	vinte_2v2 = { green = true, amounts = { 2, 3 }, week = 5 },
	punti = { green = true, team = true, amounts = { 1000, 2000 }, week = 5000 },
	nel_vuoto = { green = true, team = true, amounts = { 3, 6 }, week = 12 },
	danno = { green = true, team = true, amounts = { 800, 1800 }, week = 4000 },
	mvp = { green = true, amounts = { 1, 2 } },
	casse = { amounts = { 4, 8 } },
	teletrasporti = { amounts = { 6, 12 } },
	premi = { amounts = { 2, 4 } },
}
-- materials asked: welcome, small, medium, the week's
M.MATERIAL_AMOUNTS = { benvenuto = 4, piccola = 6, media = 12, settimana = 15 }

-- The clients: the custodi of the gironi, in the campaign's order. level: the
-- campaign level (sim/levels.lua id) whose first win brings the client; until
-- that level exists the client doesn't arrive in a real profile. set: the
-- family of the fragments; material: the one of its map; feats: its taste
-- (the first is the week's)
M.CLIENTS = {
	{ id = "caronte", level = "caronte", set = "leviatano", material = "piuma", feats = { "nel_vuoto", "partite" } },
	{ id = "minosse", level = "minosse", set = "corvo", material = "vento", feats = { "vinte_2v2", "teletrasporti", "vinte" } },
	{ id = "cerbero", level = "cerbero", set = "fornace", material = "grandine", feats = { "danno", "nel_vuoto" } },
	{ id = "plutone", level = "plutone", set = "fabbro", material = "scheggia", feats = { "punti", "premi" } },
	{ id = "flegias", level = "flegias", set = "leviatano", material = "stige", feats = { "vinte_2v2", "danno" } },
	{ id = "medusa", level = "medusa", set = "vuoto", material = "tomba", feats = { "punti", "casse", "teletrasporti" } },
	{ id = "minotauro", level = "minotauro", set = "fornace", material = "sangue", feats = { "danno", "mvp" } },
	{ id = "malacoda", level = "malacoda", set = "corvo", material = "pece", feats = { "nel_vuoto", "casse", "punti" } },
}
M.CLIENT = {}
for i, c in ipairs(M.CLIENTS) do
	c.i = i
	M.CLIENT[c.id] = c
	milestones.CLIENTS[c.id] = true
end
-- the Smith's own order: always open, redone at once, the family is yours to pick
M.SMITH = { impresa = "partite", quanti = 2 }

-- Days ------------------------------------------------------------------------------

-- "2026-11-23" -> a day number (days from 1 Jan 1970; 0 was a Thursday), nil if unreadable
function M.day_number(today)
	local y, m, d = tostring(today):match("^(%d+)-(%d+)-(%d+)$")
	y, m, d = tonumber(y), tonumber(m), tonumber(d)
	if not y then return nil end
	if m <= 2 then y, m = y - 1, m + 12 end
	local era = math.floor(y / 400)
	local yoe = y - era * 400
	local doy = math.floor((153 * (m - 3) + 2) / 5) + d - 1
	local doe = yoe * 365 + math.floor(yoe / 4) - math.floor(yoe / 100) + doy
	return era * 146097 + doe - 719468
end

-- the week of a day number, Monday to Sunday
function M.week(day)
	return math.floor((day + 3) / 7)
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

-- The profile ------------------------------------------------------------------------

function M.init(p)
	local c = p.commesse or {}
	p.commesse = c
	c.online = c.online or 0
	c.materiali = c.materiali or {}
	c.frammenti = c.frammenti or {}
	c.clienti = c.clienti or {}
	c.attesa = c.attesa or {}
	c.bacheca = c.bacheca or {}
	c.giorno = c.giorno or ""
	c.cambio = c.cambio or ""
	c.n = c.n or 0
	c.consegne = c.consegne or 0
	return p
end

-- The clients' badges (Sergio, 23 Nov): at TRUST_LAP pearls a client gives its own
-- badge for the sheet, next to the stats' ones (sim/milestones.lua shown); its grade is
-- the metal of the trust's thread (1 bronze ... 4 ember, the pieces' grades).
M.BADGE = "cl_"
function M.badge_grade(trust)
	return math.min(4, math.floor((trust - 1) / M.TRUST_LAP) + 1)
end

-- { { id = "cl_caronte", grado }, ... } in the clients' order
function M.badges(p)
	local out = {}
	local c = p.commesse
	if not c then return out end
	for _, cl in ipairs(M.CLIENTS) do
		local t = c.clienti[cl.id] and c.clienti[cl.id].fiducia or 0
		if t >= M.TRUST_LAP then out[#out + 1] = { id = M.BADGE .. cl.id, grado = M.badge_grade(t) } end
	end
	return out
end

function M.materials(p, id) return p.commesse.materiali[id] or 0 end
function M.fragments(p, set) return p.commesse.frammenti[set] or 0 end
function M.trust(p, id) return p.commesse.clienti[id] and p.commesse.clienti[id].fiducia or 0 end

local function add_material(p, id, n)
	local t = p.commesse.materiali
	t[id] = math.max(0, math.min(M.MATERIAL_MAX, (t[id] or 0) + n))
end

local function add_fragments(p, set, n)
	local t = p.commesse.frammenti
	t[set] = (t[set] or 0) + n
end

-- the clients you have, in the campaign's order
function M.clients(p)
	local out = {}
	for _, c in ipairs(M.CLIENTS) do
		if p.commesse.clienti[c.id] then out[#out + 1] = c end
	end
	return out
end

-- how many places for the clients' orders
function M.places(p)
	local n = #M.clients(p)
	for _, row in ipairs(M.PLACES) do
		if n >= row[1] then return row[2] end
	end
	return 0
end

-- Orders -----------------------------------------------------------------------------

local function new_order(p, o)
	local c = p.commesse
	c.n = c.n + 1
	o.n = c.n
	if o.impresa then o.fatti = o.fatti or 0 end
	return o
end

local function smith_order(p, done)
	return new_order(p, { taglia = "fabbro", impresa = M.SMITH.impresa, quanti = M.SMITH.quanti,
		fatti = done and M.SMITH.quanti or 0, gratis = done or nil })
end

local function welcome_order(p, client)
	return new_order(p, { cliente = client.id, taglia = "benvenuto", materiale = client.material,
		quanti = M.MATERIAL_AMOUNTS.benvenuto })
end

-- a client's order of the day: drawn from the day and the orders' counter (the
-- same on the phone and on the server)
local function daily_order(p, client, today)
	local h = hash(today, p.commesse.n, client.id)
	local size = h % 2 == 0 and "piccola" or "media"
	local idx = size == "piccola" and 1 or 2
	if math.floor(h / 2) % 2 == 0 then
		return new_order(p, { cliente = client.id, taglia = size, materiale = client.material,
			quanti = M.MATERIAL_AMOUNTS[size] })
	end
	local feat = client.feats[math.floor(h / 4) % #client.feats + 1]
	return new_order(p, { cliente = client.id, taglia = size, impresa = feat, quanti = M.FEATS[feat].amounts[idx] })
end

local function week_order(p, client, week)
	local feat = client.feats[1]
	return new_order(p, { cliente = client.id, taglia = "settimana", settimana = week, materiale = client.material,
		quanti = M.MATERIAL_AMOUNTS.settimana, poi = { impresa = feat, quanti = M.FEATS[feat].week or M.FEATS[feat].amounts[2], fatti = 0 } })
end

local function on_board(p, id)
	for _, o in ipairs(p.commesse.bacheca) do
		if o.cliente == id then return true end
	end
	return false
end

-- the clients that may get a new place: yours, not already on the board
local function free_clients(p, except)
	local out = {}
	for _, c in ipairs(M.clients(p)) do
		if not on_board(p, c.id) and c.id ~= except then out[#out + 1] = c end
	end
	return out
end

-- fills the empty places: first the welcome orders waiting, then the client
-- called on an earlier day, then a draw
local function fill(p, today, day)
	local c = p.commesse
	local places = M.places(p)
	while #c.bacheca < places do
		local order
		for i, id in ipairs(c.attesa) do
			if not on_board(p, id) then
				table.remove(c.attesa, i)
				order = welcome_order(p, M.CLIENT[id])
				break
			end
		end
		if not order and c.chiamato and day > c.chiamato.giorno and not on_board(p, c.chiamato.cliente)
			and c.clienti[c.chiamato.cliente] then
			order = daily_order(p, M.CLIENT[c.chiamato.cliente], today)
			c.chiamato = nil
		end
		if not order then
			local free = free_clients(p, c.chiamato and c.chiamato.cliente)
			if #free == 0 then break end
			order = daily_order(p, free[hash(today, c.n, #c.bacheca) % #free + 1], today)
		end
		c.bacheca[#c.bacheca + 1] = order
	end
end

-- Opens the bottega: the Smith's first order, already done and free
function M.open(p)
	local c = p.commesse
	if c.aperta then return false end
	c.aperta = true
	c.fabbro = smith_order(p, true)
	return true
end

-- A client arrives (the first win on its custode; the test bench calls this
-- too). Its welcome order takes a place as soon as one is free. Returns true
-- if it is new
function M.add_client(p, id)
	local c = p.commesse
	if not M.CLIENT[id] or c.clienti[id] then return false end
	c.clienti[id] = { fiducia = 0 }
	c.attesa[#c.attesa + 1] = id
	return true
end

-- The clients whose campaign level is won arrive (p.stelle, sim/profile.lua)
local function clients_from_campaign(p)
	for _, cl in ipairs(M.CLIENTS) do
		local s = p.stelle and p.stelle[cl.level]
		if s and s[1] then M.add_client(p, cl.id) end
	end
end

-- "Today is this day": the clients won in the campaign arrive, and when the
-- day has changed the empty places fill and the week's order turns. To call
-- before reading or changing the board. Returns true if something changed
function M.refresh(p, today)
	M.init(p)
	local c = p.commesse
	local day = M.day_number(today)
	if not day or not c.aperta then return false end
	local before = c.n
	clients_from_campaign(p)
	-- a welcome order never waits for the morning
	local waiting = #c.attesa > 0
	if c.giorno ~= today or waiting then
		if c.giorno ~= today then
			c.giorno = today
			local week = M.week(day)
			if c.settimana and c.settimana.settimana ~= week then c.settimana = nil end
			local mine = M.clients(p)
			if not c.settimana and #mine >= M.WEEK_CLIENTS and c.fatta_settimana ~= week then
				c.settimana = week_order(p, mine[hash("settimana", week) % #mine + 1], week)
			end
			fill(p, today, day)
		else
			-- only the welcome orders, into the free places
			local places = M.places(p)
			local i = 1
			while #c.bacheca < places and i <= #c.attesa do
				if not on_board(p, c.attesa[i]) then
					c.bacheca[#c.bacheca + 1] = welcome_order(p, M.CLIENT[table.remove(c.attesa, i)])
				else
					i = i + 1
				end
			end
		end
	end
	return c.n ~= before
end

-- every order on the board: the clients', the week's, the Smith's
function M.orders(p)
	local c = p.commesse
	local out = {}
	for _, o in ipairs(c.bacheca) do out[#out + 1] = o end
	if c.settimana then out[#out + 1] = c.settimana end
	if c.fabbro then out[#out + 1] = c.fabbro end
	return out
end

local function find(p, n)
	for _, o in ipairs(M.orders(p)) do
		if o.n == n then return o end
	end
end
M.find = find

-- how far a request is: done, asked. Materials are counted from what you
-- hold (the Scoria is worth any)
local function request_progress(p, r)
	if r.materiale then
		local have = M.materials(p, r.materiale)
		if r.materiale ~= M.JOLLY then have = have + M.materials(p, M.JOLLY) end
		return math.min(have, r.quanti), r.quanti
	end
	return math.min(r.fatti or 0, r.quanti), r.quanti
end

-- An order's progress: { { done, asked }, ... } (two rows for the week's) and
-- whether it is ready to deliver
function M.progress(p, o)
	local rows, ready = {}, true
	for _, r in ipairs({ o, o.poi }) do
		local done, asked = request_progress(p, r)
		rows[#rows + 1] = { done = done, asked = asked }
		if done < asked then ready = false end
	end
	return rows, ready
end

-- what an order costs and whose fragments it pays (set: nil for the Smith's,
-- picked at the delivery)
function M.cost(o)
	if o.gratis then return 0 end
	return M.SIZES[o.taglia].cost
end

function M.ready_count(p)
	local n = 0
	for _, o in ipairs(M.orders(p)) do
		local _, ready = M.progress(p, o)
		if ready then n = n + 1 end
	end
	return n
end

-- A match ended ------------------------------------------------------------------------

-- The numbers of a finished match for one player, from game:results() (res),
-- for M.match: the same on the server (worker.lua prizes) and on the phone.
-- me: the robot; map: the map's id; humans: the people in the match; awards:
-- how many end-of-match awards; own: the player's stats (sim/tally.lua valori)
function M.summary(res, me, map, humans, awards, own)
	local mine
	for _, v in ipairs(res.ranking) do
		if v.robot == me then mine = v end
	end
	if not mine then return nil end
	local team = { punti = 0, danno = 0, nel_vuoto = 0 }
	for _, v in ipairs(res.ranking) do
		if v.team == mine.team then
			team.punti = team.punti + (v.points or 0)
			team.danno = team.danno + (v.damage or 0)
			team.nel_vuoto = team.nel_vuoto + (v.env_kills or 0)
		end
	end
	local won = nil
	if res.winner then won = res.winner == mine.team end
	own = own or {}
	return { mappa = map, umani = humans, modo = res.mode, won = won, premi = awards or 0,
		punti = mine.points or 0, danno = mine.damage or 0, nel_vuoto = mine.env_kills or 0,
		casse = own.casse or mine.crates or 0, teletrasporti = own.teletrasporti or mine.teleports or 0,
		squadra = res.mode == "2v2" and team or nil }
end

local function whole(v, top)
	if type(v) ~= "number" or v ~= v then return 0 end
	return math.max(0, math.min(top, math.floor(v)))
end

-- A summary from outside, cut to what can be true (sim/progress.lua)
function M.clean(s, mvp)
	if type(s) ~= "table" then return nil end
	local out = { mappa = type(s.mappa) == "string" and s.mappa or nil, umani = whole(s.umani, 8),
		modo = type(s.modo) == "string" and s.modo:sub(1, 12) or nil, premi = whole(s.premi, 3), mvp = mvp == true,
		punti = whole(s.punti, 3000), danno = whole(s.danno, 20000), nel_vuoto = whole(s.nel_vuoto, 100),
		casse = whole(s.casse, 100), teletrasporti = whole(s.teletrasporti, 100) }
	if s.won == true or s.won == false then out.won = s.won end
	if type(s.squadra) == "table" then
		out.squadra = { punti = whole(s.squadra.punti, 6000), danno = whole(s.squadra.danno, 40000),
			nel_vuoto = whole(s.squadra.nel_vuoto, 200) }
	end
	return out
end

-- how much a match adds to a feat
local function feat_gain(s, feat)
	local f = M.FEATS[feat]
	if f.team and s.squadra then return s.squadra[feat] or 0 end
	if feat == "partite" then return 1 end
	if feat == "vinte" then return s.won and 1 or 0 end
	if feat == "vinte_2v2" then return (s.won and s.modo == "2v2") and 1 or 0 end
	if feat == "mvp" then return s.mvp and 1 or 0 end
	return s[feat] or 0
end

-- "An online match ended with these numbers" (s: M.summary, cleaned). Counts
-- it towards the opening; once open, drops the map's materials and moves
-- every order on the board. Returns the rows for the podium's receipt:
-- { { key = "open" } | { key = "material", id, n } | { key = "order", n, cliente,
--   done, asked, ready } }
function M.match(p, s, today)
	M.init(p)
	local c = p.commesse
	local rows = {}
	if not s then return rows end
	if not c.aperta then
		c.online = c.online + 1
		if c.online >= M.OPEN_AFTER then
			M.open(p)
			M.refresh(p, today)
			rows[#rows + 1] = { key = "open" }
		end
		return rows
	end
	M.refresh(p, today)
	if (s.umani or 0) < M.MIN_HUMANS then return rows end
	local before = {}
	for _, o in ipairs(M.orders(p)) do
		local _, ready = M.progress(p, o)
		before[o.n] = ready
	end
	local mat = s.mappa and M.MATERIAL_OF[s.mappa]
	if mat then
		local had = M.materials(p, mat)
		add_material(p, mat, s.won and M.DROP_WIN or M.DROP)
		local got = M.materials(p, mat) - had
		if got > 0 then rows[#rows + 1] = { key = "material", id = mat, n = got } end
	end
	for _, o in ipairs(M.orders(p)) do
		for _, r in ipairs({ o, o.poi }) do
			if r.impresa then r.fatti = math.min(r.quanti, (r.fatti or 0) + feat_gain(s, r.impresa)) end
		end
		local prog, ready = M.progress(p, o)
		local moved = ready ~= before[o.n]
		for _, r in ipairs({ o, o.poi }) do
			if r.impresa and feat_gain(s, r.impresa) > 0 then moved = true end
			if r.materiale and mat and (r.materiale == mat or mat == M.JOLLY) then moved = true end
		end
		if moved then
			local last = prog[#prog]
			rows[#rows + 1] = { key = "order", n = o.n, cliente = o.cliente, done = last.done, asked = last.asked,
				ready = ready and not before[o.n] or nil }
		end
	end
	return rows
end

-- The swap, the call, the change of a card ----------------------------------------------

-- TRADE of one material for one of another. Returns true, or nil and why
function M.trade(p, from, to)
	if not MATERIAL[from] or not MATERIAL[to] or from == to then return nil, "materiale" end
	if M.materials(p, from) < M.TRADE then return nil, "pochi" end
	if M.materials(p, to) >= M.MATERIAL_MAX then return nil, "pieno" end
	add_material(p, from, -M.TRADE)
	add_material(p, to, 1)
	return true
end

-- whether the day's free change is still there
function M.can_change(p, today) return p.commesse.cambio ~= today end

-- Tears a client's card (order n) and hangs another: once a day, never a
-- welcome order, the week's or the Smith's. Returns the new order, or nil and why
function M.change(p, n, today)
	M.refresh(p, today)
	local c = p.commesse
	if not M.can_change(p, today) then return nil, "oggi" end
	for i, o in ipairs(c.bacheca) do
		if o.n == n then
			if o.taglia == "benvenuto" then return nil, "benvenuto" end
			local free = free_clients(p, o.cliente)
			-- with one client only, another request of the same
			local client = #free > 0 and free[hash(today, c.n, "cambio") % #free + 1] or M.CLIENT[o.cliente]
			c.cambio = today
			-- another request, not the same one again
			local new
			for _ = 1, 6 do
				new = daily_order(p, client, today)
				if new.cliente ~= o.cliente or new.impresa ~= o.impresa or new.materiale ~= o.materiale
					or new.quanti ~= o.quanti then break end
			end
			c.bacheca[i] = new
			return new
		end
	end
	return nil, "commessa"
end

-- whether a client can be called today: never the one of yesterday's call
function M.can_call(p, id, today)
	local c = p.commesse
	local day = M.day_number(today)
	if not day or not c.clienti[id] then return false end
	local last = c.chiamata
	return not (last and last.cliente == id and day - last.giorno == 1)
end

-- Calls a client: from tomorrow one of its orders takes the first free place.
-- One call a day stands (a new one replaces it). Returns true, or nil and why
function M.call(p, id, today)
	local c = p.commesse
	local day = M.day_number(today)
	if not day or not c.clienti[id] then return nil, "cliente" end
	if not M.can_call(p, id, today) then return nil, "ieri" end
	c.chiamato = { cliente = id, giorno = day }
	-- a second call on the same day replaces the first: only one counts
	c.chiamata = { cliente = id, giorno = day }
	return true
end

-- The delivery ------------------------------------------------------------------------

-- whether the next delivery is a lucky strike: one in LUCKY_EVERY, drawn from
-- the profile's own counters (deliveries and orders made), the same on the
-- phone and on the server
function M.lucky(p)
	local c = p.commesse
	return hash("colpo", c.consegne, c.n) % M.LUCKY_EVERY == 0
end

local function take_materials(p, id, n)
	local own = math.min(n, M.materials(p, id))
	add_material(p, id, -own)
	if n > own then add_material(p, M.JOLLY, -(n - own)) end
end

-- Delivers order n. set: the family of the fragments, for the Smith's order
-- (the clients' is theirs). lucky: nil the draw, true/false to fix it (the
-- test bench; sim/progress.lua never passes it). Returns the rows for the
-- receipt, or nil and why ("commessa", "pronta", "famiglia", "ossidiana"):
-- { { key = "ossidiana", n = -cost } | { key = "scaglie", n } |
--   { key = "fragments", set, n } | { key = "lucky", set, n } |
--   { key = "trust", cliente, n, total } | { key = "gift", set, n, cliente } |
--   { key = "voucher" } }
function M.deliver(p, n, set, lucky)
	local c = p.commesse
	local o = find(p, n)
	if not o then return nil, "commessa" end
	local _, ready = M.progress(p, o)
	if not ready then return nil, "pronta" end
	local client = o.cliente and M.CLIENT[o.cliente]
	local family = client and client.set or set
	if not family or not equip.BY_ID[family] then return nil, "famiglia" end
	local cost = M.cost(o)
	if p.ossidiana < cost then return nil, "ossidiana" end

	local size = M.SIZES[o.taglia]
	local rows = {}
	p.ossidiana = p.ossidiana - cost
	if cost > 0 then rows[#rows + 1] = { key = "ossidiana", n = -cost } end
	for _, r in ipairs({ o, o.poi }) do
		if r.materiale then take_materials(p, r.materiale, r.quanti) end
	end
	p.scaglie = p.scaglie + size.scaglie
	rows[#rows + 1] = { key = "scaglie", n = size.scaglie }

	-- (drawn before this delivery is counted: the bench's "next one" is this one)
	if lucky == nil then lucky = M.lucky(p) end
	c.consegne = c.consegne + 1
	local trust = client and c.clienti[client.id]
	local frags = size.frammenti
	if trust and trust.fiducia >= M.TRUST_BONUS then frags = frags + 1 end
	add_fragments(p, family, frags)
	rows[#rows + 1] = { key = "fragments", set = family, n = frags }
	if lucky then
		add_fragments(p, family, frags)
		rows[#rows + 1] = { key = "lucky", set = family, n = frags }
	end
	if trust then
		local was = trust.fiducia
		trust.fiducia = was + size.pearls
		rows[#rows + 1] = { key = "trust", cliente = client.id, n = size.pearls, total = trust.fiducia }
		-- the gifts of every lap crossed (the week's order can cross one)
		for lap = math.floor(was / M.TRUST_LAP) + 1, math.floor(trust.fiducia / M.TRUST_LAP) do
			local gift = lap == 1 and M.TRUST_GIFT or M.TRUST_GIFT_AGAIN
			add_fragments(p, family, gift)
			rows[#rows + 1] = { key = "gift", set = family, n = gift, cliente = client.id, card = lap == 1 or nil }
		end
	end
	if size.voucher then
		p.buoni = (p.buoni or 0) + 1
		trust.benvenuto = true
		rows[#rows + 1] = { key = "voucher" }
	end

	-- the place is free; the Smith's order starts again at once
	if o == c.fabbro then
		c.fabbro = smith_order(p)
	elseif o == c.settimana then
		c.fatta_settimana = o.settimana
		c.settimana = nil
	else
		for i, b in ipairs(c.bacheca) do
			if b == o then
				table.remove(c.bacheca, i)
				break
			end
		end
	end
	return rows
end

-- Fragments as money ------------------------------------------------------------------

-- Scaglie a fragment is worth, on the pieces of its family
function M.fragment_value()
	return wallet.PRICE_CATALOG / M.PIECE_FRAGMENTS
end

-- a price in Scaglie as fragments (at least one)
function M.in_fragments(scaglie)
	return math.max(1, math.floor(scaglie / M.fragment_value() + 0.5))
end

-- Buys a piece of the Catalogo with its family's fragments. Returns true, or
-- nil and why ("shop", "owned", "frammenti")
function M.buy(p, set, slot)
	if not equip.BY_ID[set] then return nil, "shop" end
	if wallet.owns(p, set, slot) then return nil, "owned" end
	local cost = M.in_fragments(wallet.price(p, set, slot, false))
	if M.fragments(p, set) < cost then return nil, "frammenti" end
	add_fragments(p, set, -cost)
	p.posseduti[wallet.key(set, slot)] = true
	return true
end

-- what the next level of a piece asks in fragments (nil at the top)
function M.level_cost(p, set, slot)
	local n = wallet.next(p, set, slot)
	return n and M.in_fragments(n.cost)
end

-- The first piece of a family (gear.SLOTS order) whose next level its fragments
-- pay now (owned, Proof done): its slot, or nil. The delivery's receipt shows
-- POTENZIA for it
function M.upgradable(p, set)
	for _, s in ipairs(equip.SLOTS) do
		if wallet.owns(p, set, s.id) then
			local n = wallet.next(p, set, s.id)
			if n and n.proof_done >= n.proof and M.fragments(p, set) >= M.in_fragments(n.cost) then return s.id end
		end
	end
end

-- Buys the next level of a piece with its family's fragments (the Proof of a
-- step holds as with the Scaglie). Returns the new level, or nil and why
-- ("max", "proof", "frammenti")
function M.upgrade(p, set, slot)
	local n = wallet.next(p, set, slot)
	if not n then return nil, "max" end
	if n.proof_done < n.proof then return nil, "proof" end
	local cost = M.in_fragments(n.cost)
	if M.fragments(p, set) < cost then return nil, "frammenti" end
	add_fragments(p, set, -cost)
	local k = wallet.key(set, slot)
	p.pezzi[k] = n.level
	p.prova[k] = nil
	return n.level
end

return M
