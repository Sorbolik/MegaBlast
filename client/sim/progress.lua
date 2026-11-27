-- What changes the profile's progress, as actions (guest profiles, plan of
-- 17 Nov, PR 4: the server owns the progress). The phone never says "I
-- earned X": it says what it did ({ k = "compra", set, slot }, { k =
-- "partita", r, conta }...) and the same rules run here on the phone, at once
-- (what the player sees), and on the server (server/worker.lua, profile_do),
-- whose profile is the one that counts (main/account.lua takes it back).
-- Everything that comes in is checked like data from outside: an action that
-- doesn't fit the rules does nothing.
--
-- The matches played on the phone (partita, missione) carry their recipe:
-- the phone counts them at once with what it saw, the server only after
-- replaying them (sim/judge.lua, Sergio's choice of 19 Nov), with its own
-- numbers. The caps of DECLARED hold for both.

local profile = require "sim.profile"
local wallet = require "sim.wallet"
local equip = require "sim.gear"
local campaign = require "sim.campaign"
local orders = require "sim.orders"
local forge = require "sim.forge"

local M = {}

-- the most a declared match can bring: its points, awards, each stat
M.DECLARED = { points = 3000, awards = 3, stat = 20000 }

local SLOT = {}
for _, sl in ipairs(equip.SLOTS) do SLOT[sl.id] = true end

local function piece_ok(a)
	return type(a.set) == "string" and equip.BY_ID[a.set] ~= nil and SLOT[a.slot] == true
end

local LEVELS = {}
for _, cap in ipairs(campaign.CAPITOLI) do
	for _, l in ipairs(cap.missioni) do LEVELS[l.id] = true end
end

-- A match's summary for the rewards (profile.match_xp, wallet.match), cut to the caps
local function clean_match(r)
	if type(r) ~= "table" then return nil end
	local d = M.DECLARED
	local out = { points = type(r.points) == "number" and math.max(0, math.min(d.points, math.floor(r.points))) or 0,
		second = r.second == true or nil, mvp = r.mvp == true or nil, quit = r.quit == true or nil,
		online = r.online == true or nil, awards = {} }
	if r.won == true or r.won == false then out.won = r.won end
	for i = 1, math.min(d.awards, type(r.awards) == "table" and #r.awards or 0) do
		local a = r.awards[i]
		out.awards[i] = { name = type(a) == "table" and type(a.name) == "string" and a.name:sub(1, 40) or "" }
	end
	-- on the phone (training, same phone) half; online (only the server
	-- makes that action, server/worker.lua) the full price
	out.bots = not out.online
	return out
end

-- the stats of a declared match (sim/tally.lua finish: gruppo, valori, armi, won)
local function clean_tally(c)
	if type(c) ~= "table" then return nil end
	local vals = {}
	for k, n in pairs(type(c.valori) == "table" and c.valori or {}) do
		-- the match count, the wins and the streak come from add_stats
		if k ~= "partite" and k ~= "vinte" and k ~= "serie" then vals[k] = n end
	end
	vals.armi = c.armi
	local v = profile.clean_stats(c.gruppo, vals, M.DECLARED.stat)
	if not v then return nil end
	local armi = v.armi or {}
	v.armi = nil
	local out = { gruppo = c.gruppo, valori = v, armi = armi }
	if c.won == true or c.won == false then out.won = c.won end
	return out
end

-- Scaglie and Ossidiana of a match (sim/wallet.lua): the rows go to the
-- podium's receipt
local function match_coins(p, r, stats_before, gain, today)
	local rows, won = wallet.match(p, r, today)
	local obs = wallet.obsidian(stats_before, profile.statistics(p, "tutte"), gain.level_before, gain.livello)
	for _, row in ipairs(won) do table.insert(obs, 1, row) end
	wallet.apply(p, rows)
	wallet.apply(p, obs)
	local gifts = wallet.gifts(p, profile.statistics(p, "tutte"), p.livello)
	return { rows = rows, obsidian = obs, gifts = gifts }
end

-- Scaglie of a mission done, from its experience lines (profile.mission);
-- chapters: the chapters done before
local function mission_coins(p, gain, chapters)
	local first, new = false, 0
	for _, l in ipairs(gain.lines) do
		if l.key == "done" then first = true end
		if l.key == "stars" then new = l.n end
	end
	local rows, obs = wallet.mission(first, new, gain.record)
	-- Ossidiana: the new stars, every 5 levels of the devil, a chapter finished
	for _, row in ipairs(wallet.obsidian({}, {}, gain.level_before, gain.livello)) do obs[#obs + 1] = row end
	if wallet.chapters_done(p, campaign.CAPITOLI) > chapters then obs[#obs + 1] = wallet.chapter()[1] end
	wallet.apply(p, rows)
	wallet.apply(p, obs)
	local gifts = wallet.gifts(p, profile.statistics(p, "tutte"), p.livello)
	return { rows = rows, obsidian = obs, gifts = gifts }
end

local DO = {}

-- a finished match: r for the rewards, conta for the stats (both optional
-- but r); returns the gain (profile.match_end, with .coins)
function DO.partita(p, a, today)
	local r = clean_match(a.r)
	if not r then return nil, "partita" end
	local stats_before = profile.statistics(p, "tutte")
	local gain = profile.match_end(p, r, today)
	local c = clean_tally(a.conta)
	if c then profile.add_stats(p, c) end
	gain.coins = match_coins(p, r, stats_before, gain, today)
	-- the Smith's orders move only with the online matches (a.commesse: sim/orders.lua
	-- summary, made by the server): their rows go to the podium's receipt
	if r.online then
		local s = orders.clean(a.commesse, r.mvp)
		if s then gain.commesse = orders.match(p, s, today) end
	end
	return gain
end

-- a campaign mission done: its stars, the points made and, for a battle, its
-- stats (conta)
function DO.missione(p, a)
	if not LEVELS[a.id] or type(a.stars) ~= "table" then return nil, "missione" end
	local stars = { a.stars[1] == true, a.stars[2] == true, a.stars[3] == true }
	local made = type(a.made) == "number" and math.max(0, math.min(1e6, math.floor(a.made))) or nil
	local chapters = wallet.chapters_done(p, campaign.CAPITOLI)
	local gain = profile.mission(p, a.id, stars, made)
	local c = clean_tally(a.conta)
	if c then profile.add_stats(p, c) end
	gain.coins = mission_coins(p, gain, chapters)
	return gain
end

-- the stats of a campaign battle lost (a won one brings them with missione)
function DO.statistiche(p, a)
	local c = clean_tally(a.conta)
	if not c then return nil, "statistiche" end
	profile.add_stats(p, c)
	return true
end

-- the BOTTEGA's piece of today (offer: at its price) or the CATALOGO's
function DO.compra(p, a, today)
	if not piece_ok(a) then return nil, "shop" end
	if a.frammenti == true then return orders.buy(orders.init(p), a.set, a.slot) end
	return wallet.buy(p, a.set, a.slot, a.offer == true and today or nil)
end

function DO.buono(p, a)
	if not piece_ok(a) then return nil, "voucher" end
	return wallet.use_voucher(p, a.set, a.slot)
end

function DO.potenzia(p, a)
	if not piece_ok(a) then return nil, "max" end
	if a.frammenti == true then return orders.upgrade(orders.init(p), a.set, a.slot) end
	return wallet.upgrade(p, a.set, a.slot)
end

function DO.firma(p, a)
	if not piece_ok(a) then return nil, "max" end
	return wallet.light(p, a.set, a.slot)
end

-- The Smith's orders (sim/orders.lua, docs/commesse.md). Each one first tells
-- the board what day it is, so the phone and the server hang the same cards.
-- The day turns at 5 in the morning (wallet.today, accounts.go today).
-- bacheca: the board is looked at (the day's refill)
function DO.bacheca(p, a, today)
	orders.refresh(p, today)
	return true
end

-- consegna: order n is delivered (set: the family, for the Smith's own)
function DO.consegna(p, a, today)
	orders.refresh(p, today)
	if type(a.n) ~= "number" then return nil, "commessa" end
	local set = type(a.set) == "string" and equip.BY_ID[a.set] and a.set or nil
	return orders.deliver(p, a.n, set)
end

-- scambia: TRADE of a material (da) for one of another (a)
function DO.scambia(p, a, today)
	orders.refresh(p, today)
	if type(a.da) ~= "string" or type(a.a) ~= "string" then return nil, "materiale" end
	return orders.trade(p, a.da, a.a)
end

-- cambia: the day's free change of a client's card
function DO.cambia(p, a, today)
	orders.refresh(p, today)
	if type(a.n) ~= "number" then return nil, "commessa" end
	return orders.change(p, a.n, today)
end

-- chiama: a client is called for tomorrow
function DO.chiama(p, a, today)
	orders.refresh(p, today)
	if type(a.cliente) ~= "string" then return nil, "cliente" end
	return orders.call(p, a.cliente, today)
end

-- The Forge (sim/forge.lua, docs/commesse.md "La Fornace").
-- colata: a pour on the wall the phone sees (muro: "date#shift")
function DO.colata(p, a, today)
	return forge.pour(p, a.muro, today)
end

-- tiro: a throw of the pour (angolo in radians, forza 0..1); the result is
-- computed here, never said by the phone
function DO.tiro(p, a)
	return forge.throw(p, a.angolo, a.forza)
end

-- fondi: 4 fragments of da for 1 of a, or (no a) 1 of da for Scaglie
function DO.fondi(p, a)
	return forge.melt(p, a.da, a.a)
end

-- the ZAINO: the loadouts (pieces worn, Sigilli) and the active ones
function DO.zaino(p, a)
	profile.take_loadouts(p, a)
	wallet.migrate(p, p.loadouts)
	return true
end

-- Does action a on p (today: the date, for the day's counts, the BANCO and the
-- Smith's orders). Returns what its rule returns (nil and why when it can't)
function M.act(p, a, today)
	local f = type(a) == "table" and DO[a.k]
	if not f then return nil, "azione" end
	return f(p, a, today)
end

-- The ZAINO's action for p as it is now
function M.backpack(p)
	return { k = "zaino", loadouts = p.loadouts, is_active = p.is_active, seal_active = p.seal_active }
end

return M
