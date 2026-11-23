-- The two currencies and the pieces' levels (Sergio, 10 Nov, page "Scaglie e
-- Ossidiana" https://claude.ai/artifact/S8PhASdh61MoRdK2QFLXXM, all choices A).
-- Scaglie (soft) are earned playing and buy the pieces' levels; Ossidiana
-- (hard) is rare and will buy only looks and tournament entries, never levels
-- or Scaglie. Pure Lua, in the shared rules (sim/) so that the server can run
-- the same sums as the phone (guest profiles, plan of 17 Nov); the profile
-- is sim/profile.lua; tested in tests/wallet_test.lua.
--
-- The profile's fields (added by M.init, so old saves keep working):
--   scaglie, ossidiana: the balance
--   pezzi[set_slot]: the level of a piece (missing: 1)
--   posseduti[set_slot]: the pieces owned (bought, from a voucher or a gift)
--   firme[set_slot]: how far the piece's signature is lit (0..3, missing: 0)
--   buoni: the Smith's vouchers not used yet (one piece of your choice)
--   regali[key]: the gifts already given (so each comes once)
--   prova[set_slot]: matches worn at the level below a step (the Proof)
--   giorno: the day of the last "first win of the day"
--   bot_giorno, bot_partite: the day and the paid matches against bots

local equip = require "sim.gear"
local milestones = require "sim.milestones"

local M = {}

-- Scaglie for a finished match (choice 3A). One row per entry, with the same
-- keys as the receipt's lines (ui/receipt.lua)
M.MATCH = 10              -- even lost; who quits gets nothing
M.POINTS_EACH, M.POINTS_MAX = 25, 6   -- 1 every 25 points, at most 6
M.WIN, M.SECOND = 15, 8   -- the win (the team in 2 vs 2), 2nd in free for all
M.MVP = 5
M.AWARD, M.AWARDS_MAX = 3, 2
M.DAILY = 40              -- first win of the day (choice 7A)
-- campaign missions: the first time, a replay that beats your record of
-- points (a replay that doesn't pays nothing: replaying a one-minute lesson
-- in a row paid more than playing online, Sergio's plan of 17 Nov), each new star
M.MISSION, M.REPLAY, M.STAR = 15, 8, 5
-- training against bots: half (the experience too, menu/profile.lua), only the
-- first matches of the day
M.BOTS_DAY = 10

-- Ossidiana earned playing. The Scaglie reward playing, the Ossidiana
-- rewards winning (Sergio, 17 Nov: «rendiamola farmabile»): an online win,
-- the MVP, the first win of the day, each new star of the campaign; no cap.
M.OBS_WIN, M.OBS_MVP, M.OBS_DAILY = 1, 1, 5
M.OBS_STAR = 2
-- And at the milestones: a badge going up a grade (I..IV), every
-- LEVEL_EVERY levels of the devil, a finished chapter of the campaign
M.OBS_BADGE = { 5, 10, 20, 40 }
M.OBS_LEVEL, M.LEVEL_EVERY = 15, 5
M.OBS_CHAPTER = 30

function M.init(p)
	p.scaglie = p.scaglie or 0
	p.ossidiana = p.ossidiana or 0
	p.pezzi = p.pezzi or {}
	p.posseduti = p.posseduti or {}
	-- before 17 Nov a signature lit up with its piece's steps: those stay lit
	if not p.firme then
		p.firme = {}
		for k, l in pairs(p.pezzi) do p.firme[k] = equip.tier(l) - 1 end
	end
	p.buoni = p.buoni or 0
	p.regali = p.regali or {}
	p.prova = p.prova or {}
	p.giorno = p.giorno or ""
	p.bot_giorno = p.bot_giorno or ""
	p.bot_partite = p.bot_partite or 0
	return p
end

local function key(set, slot) return set .. "_" .. slot end
M.key = key

-- Pieces are bought and gifted, never earned in the campaign's order
-- (Sergio, 11 Nov, page "I Pezzi della Forgia", choices 22A-25A): the
-- BOTTEGA has a piece of the day per slot (among those you don't own), the
-- CATALOGO always has all of them for more; the Smith's hand lowers both.
-- Ossidiana never buys pieces. 20% lower since the gloves (Sergio, 19 Nov:
-- five pieces in the time of four); 50% higher since 23 Nov (the stronger
-- maximum and the longer road, sim/gear.lua).
M.PRICE_SHOP, M.PRICE_CATALOG = 4800, 7200

-- the Smith's vouchers and the gifts (choice 23A; fewer since 17 Nov, a
-- piece is worth much more now): the Battle of the Forge gives the Smith's
-- boots, the levels of VOUCHER_LEVELS give a voucher. GIFT_MISSIONS: campaign
-- levels by id, with the piece they give and/or the vouchers (the finale of
-- each girone: one voucher, to be added here as the girone arrives).
M.GIFT_MISSIONS = {
	{ id = "battaglia_forgia", piece = { "fabbro", "legs" } },
}
M.VOUCHER_LEVELS = { 50 }

function M.owns(p, set, slot)
	return p.posseduti[key(set, slot)] == true
end

-- A piece comes into the wardrobe at level 1 (or the level it already had)
local function give(p, set, slot)
	p.posseduti[key(set, slot)] = true
end

-- The pieces of the BOTTEGA on a day ("2026-11-11"): for each slot one piece
-- not owned, picked from the day (the same all day, on every phone); nil
-- where you own them all. Returns { mask = set id or nil, ... }
function M.shop(p, today)
	local h = 0
	for i = 1, #today do h = (h * 31 + today:byte(i)) % 1000003 end
	local out = {}
	for i, s in ipairs(equip.SLOTS) do
		local free = {}
		for _, f in ipairs(equip.SETS) do
			if not M.owns(p, f.id, s.id) then free[#free + 1] = f.id end
		end
		if #free > 0 then out[s.id] = free[(h + i * 7) % #free + 1] end
	end
	return out
end

-- The PEZZI DEL GIORNO of the BOTTEGA on a day (Figma, 14 Nov): DAY pieces
-- among all of them, owned or not (the same all day, on every phone), in the
-- families' order. Returns { { set, slot }, ... }
M.DAY = 10
function M.day(today)
	local h = 7
	for i = 1, #today do h = (h * 131 + today:byte(i)) % 1000003 end
	local all = {}
	for _, f in ipairs(equip.SETS) do
		for _, s in ipairs(equip.SLOTS) do all[#all + 1] = { f.id, s.id } end
	end
	-- a shuffle fixed by the day, then the first DAY back in order
	for i = #all, 2, -1 do
		h = (h * 16807 + 1) % 2147483647
		local j = h % i + 1
		all[i], all[j] = all[j], all[i]
	end
	local pick = {}
	for i = 1, math.min(M.DAY, #all) do pick[all[i][1] .. "_" .. all[i][2]] = true end
	local out = {}
	for _, f in ipairs(equip.SETS) do
		for _, s in ipairs(equip.SLOTS) do
			if pick[f.id .. "_" .. s.id] then out[#out + 1] = { f.id, s.id } end
		end
	end
	return out
end

-- price of a piece: in the BOTTEGA (shop = true) or in the CATALOGO, with
-- the Smith's hand when a piece of that family is at 30
function M.price(p, set, slot, shop)
	local c = shop and M.PRICE_SHOP or M.PRICE_CATALOG
	if M.smith_hand(p, set) then c = math.floor(c * equip.SMITH_HAND / 5 + 0.5) * 5 end
	return c
end

-- Buys a piece: from the BOTTEGA of today (shop = today's date) or from the
-- CATALOGO (shop = nil). Returns true, or nil and why ("owned", "shop", "scaglie")
function M.buy(p, set, slot, shop)
	if not equip.BY_ID[set] then return nil, "shop" end
	if M.owns(p, set, slot) then return nil, "owned" end
	if shop and M.shop(p, shop)[slot] ~= set then return nil, "shop" end
	local c = M.price(p, set, slot, shop ~= nil)
	if p.scaglie < c then return nil, "scaglie" end
	p.scaglie = p.scaglie - c
	give(p, set, slot)
	return true
end

-- Takes a piece with a voucher. Returns true, or nil and why ("owned", "voucher")
function M.use_voucher(p, set, slot)
	if not equip.BY_ID[set] then return nil, "voucher" end
	if M.owns(p, set, slot) then return nil, "owned" end
	if p.buoni < 1 then return nil, "voucher" end
	p.buoni = p.buoni - 1
	give(p, set, slot)
	return true
end

-- Gives the gifts earned and not yet given: stats = profile.statistics(p,
-- "tutte"), the devil's level, the campaign's stars (p.stelle). Returns the
-- rows { { key = "piece", set, slot } | { key = "voucher", why, id? } }
function M.gifts(p, stats, level)
	local rows = {}
	local function once(k, row, f)
		if p.regali[k] then return end
		p.regali[k] = true
		f()
		rows[#rows + 1] = row
	end
	for _, g in ipairs(M.GIFT_MISSIONS) do
		if p.stelle and p.stelle[g.id] and p.stelle[g.id][1] then
			local row = g.piece and { key = "piece", set = g.piece[1], slot = g.piece[2] }
				or { key = "voucher", why = "mission", id = g.id }
			once("missione_" .. g.id, row, function()
				if g.piece then give(p, g.piece[1], g.piece[2]) end
				p.buoni = p.buoni + (g.buoni or 0)
			end)
		end
	end
	for _, l in ipairs(M.VOUCHER_LEVELS) do
		if (level or 1) >= l then
			once("livello_" .. l, { key = "voucher", why = "level", level = l }, function() p.buoni = p.buoni + 1 end)
		end
	end
	return rows
end

-- Before the shop (11 Nov) every set could be worn by anyone: the pieces
-- already levelled stay owned (choice 20A), the others come off the loadouts
function M.migrate(p, loadouts)
	for k, l in pairs(p.pezzi) do
		if l > 1 then p.posseduti[k] = true end
	end
	for _, a in ipairs(loadouts or {}) do
		for _, s in ipairs(equip.SLOTS) do
			local set = a.gear[s.id]
			if set and not (equip.BY_ID[set] and M.owns(p, set, s.id)) then a.gear[s.id] = nil end
		end
	end
end

-- level of a piece (1 if never upgraded)
function M.level(p, set, slot)
	return p.pezzi[key(set, slot)] or 1
end

-- how far a piece's signature is lit: 0 (off) .. 3 (full), never past its steps
function M.sign(p, set, slot)
	return math.min(p.firme[key(set, slot)] or 0, equip.tier(M.level(p, set, slot)) - 1)
end

-- What lighting the signature one more grade asks: { grade, cost, level } (level:
-- the step the piece must have reached, nil when it has), or nil at the top
function M.sign_next(p, set, slot)
	local g = M.sign(p, set, slot) + 1
	if not equip.SIGN_COSTS[g] then return nil end
	local step = equip.TIER_LEVELS[g]
	return { grade = g, cost = equip.SIGN_COSTS[g], level = M.level(p, set, slot) < step and step or nil }
end

-- Lights the signature one more grade. Returns the grade, or nil and why
-- ("max", "level", "ossidiana")
function M.light(p, set, slot)
	local n = M.sign_next(p, set, slot)
	if not n then return nil, "max" end
	if n.level then return nil, "level" end
	if p.ossidiana < n.cost then return nil, "ossidiana" end
	p.ossidiana = p.ossidiana - n.cost
	p.firme[key(set, slot)] = n.grade
	return n.grade
end

-- the signatures lit of the pieces worn by a loadout: { mask = 0..3, ... }
function M.signs(p, a)
	local t = {}
	for _, s in ipairs(equip.SLOTS) do
		local set = a.gear[s.id]
		t[s.id] = set and M.sign(p, set, s.id) or 0
	end
	return t
end

-- the Smith's hand: a piece of that family already at the top
function M.smith_hand(p, set)
	for _, s in ipairs(equip.SLOTS) do
		if M.level(p, set, s.id) >= equip.LIVELLO_MAX then return true end
	end
	return false
end

-- What the next level of a piece asks:
-- { level, cost, full_cost, proof, proof_done } or nil at the top
-- (p.no_proof: the "da zero" test profile, no Proof to play, Sergio 18 Nov)
function M.next(p, set, slot)
	local l = M.level(p, set, slot) + 1
	if l > equip.LIVELLO_MAX then return nil end
	local hand = M.smith_hand(p, set)
	local proof = not p.no_proof and equip.proof(l) or 0
	return { level = l, cost = equip.cost(l, hand), full_cost = equip.cost(l), proof = proof,
		proof_done = math.min(proof, p.prova[key(set, slot)] or 0) }
end

-- Buy the next level. Returns the new level, or nil and why
-- ("max", "proof", "scaglie")
function M.upgrade(p, set, slot)
	local n = M.next(p, set, slot)
	if not n then return nil, "max" end
	if n.proof_done < n.proof then return nil, "proof" end
	if p.scaglie < n.cost then return nil, "scaglie" end
	p.scaglie = p.scaglie - n.cost
	p.pezzi[key(set, slot)] = n.level
	p.prova[key(set, slot)] = nil
	return n.level
end

-- the levels of the pieces worn by a loadout: { mask = 1..30, ... }
function M.levels(p, a)
	local t = {}
	for _, s in ipairs(equip.SLOTS) do
		local set = a.gear[s.id]
		t[s.id] = set and M.level(p, set, s.id) or 1
	end
	return t
end

-- the tiers of the pieces worn by a loadout: { mask = 1..4, ... }
function M.tiers(p, a)
	local t = {}
	for _, s in ipairs(equip.SLOTS) do
		local set = a.gear[s.id]
		t[s.id] = set and equip.tier(M.level(p, set, s.id)) or 1
	end
	return t
end

-- End of a match with the loadout a: the pieces worn one step below a step
-- count one more match for its Proof
function M.wear(p, a)
	for _, s in ipairs(equip.SLOTS) do
		local set = a.gear[s.id]
		if set then
			local k = key(set, s.id)
			if equip.proof(M.level(p, set, s.id) + 1) > 0 then p.prova[k] = (p.prova[k] or 0) + 1 end
		end
	end
end

-- Scaglie of a match: r = { points, won = true|false|nil, second, mvp,
-- awards = { ... }, bots = true (training or the same phone), quit = true }
-- (the r of profile.match_end); today: "2026-11-10".
-- Returns the rows { { key, scaglie } } (nothing when quit) and the Ossidiana
-- of the match ({ { key = "obs_match", ossidiana } }, only online), and does
-- not touch the profile except for the day of the bonus and the bots' count:
-- apply adds them.
-- whether a match against bots still pays today (it doesn't count it: match does)
function M.bots_pay(p, today)
	return p.bot_giorno ~= today or (p.bot_partite or 0) < M.BOTS_DAY
end

function M.match(p, r, today)
	if r.quit then return {}, {} end
	local half = 1
	if r.bots then
		if p.bot_giorno ~= today then p.bot_giorno, p.bot_partite = today, 0 end
		if p.bot_partite >= M.BOTS_DAY then return {}, {} end
		p.bot_partite = p.bot_partite + 1
		half = 0.5
	end
	local rows = {}
	local function add(k, n)
		n = math.floor(n * half + 0.5)
		if n > 0 then rows[#rows + 1] = { key = k, scaglie = n } end
	end
	add("match", M.MATCH)
	add("points", math.min(M.POINTS_MAX, math.floor((r.points or 0) / M.POINTS_EACH)))
	if r.won then add("win", M.WIN) elseif r.second then add("second", M.SECOND) end
	if r.mvp then add("mvp", M.MVP) end
	-- one row per award, like the receipt's lines
	for i = 1, math.min(M.AWARDS_MAX, #(r.awards or {})) do add("award", M.AWARD) end
	local ob = 0
	if not r.bots then
		if r.won then ob = ob + M.OBS_WIN end
		if r.mvp then ob = ob + M.OBS_MVP end
	end
	if r.won and not r.bots and p.giorno ~= today then
		p.giorno = today
		add("daily", M.DAILY)
		ob = ob + M.OBS_DAILY
	end
	return rows, ob > 0 and { { key = "obs_match", ossidiana = ob } } or {}
end

-- how many campaign chapters have all their missions done (the Ossidiana of
-- a finished chapter): chapters = sim/campaign.lua's CAPITOLI
function M.chapters_done(p, chapters)
	local n = 0
	for _, cap in ipairs(chapters) do
		local all = #cap.missioni > 0
		for _, l in ipairs(cap.missioni) do
			if not (p.stelle[l.id] and p.stelle[l.id][1]) then all = false end
		end
		if all then n = n + 1 end
	end
	return n
end

-- Scaglie of a campaign mission: the first time, the new stars, a replay
-- only when it beats the record of points (record). And the Ossidiana of the
-- new stars ({ { key = "obs_stars", ossidiana } })
function M.mission(first, new_stars, record)
	local rows = {}
	if first then
		rows[1] = { key = "done", scaglie = M.MISSION }
	elseif record or new_stars > 0 then
		rows[1] = { key = "replay", scaglie = M.REPLAY }
	end
	if new_stars > 0 then rows[#rows + 1] = { key = "stars", scaglie = M.STAR * new_stars, n = new_stars } end
	return rows, new_stars > 0 and { { key = "obs_stars", ossidiana = M.OBS_STAR * new_stars } } or {}
end

-- Ossidiana earned between two moments: the badges' grades before and after
-- (stats of TUTTE, menu/profile.lua) and the devil's level before and after.
-- Returns the rows { { key, ossidiana, id?, grade? } }
function M.obsidian(stats_before, stats_after, level_before, level_after)
	local rows = {}
	for _, s in ipairs(milestones.WHITELIST) do
		if s.thresholds then
			local g0, g1 = milestones.grade(s, stats_before[s.id] or 0), milestones.grade(s, stats_after[s.id] or 0)
			for g = g0 + 1, g1 do rows[#rows + 1] = { key = "badge", ossidiana = M.OBS_BADGE[g], id = s.id, grade = g } end
		end
	end
	local steps = math.floor(level_after / M.LEVEL_EVERY) - math.floor(level_before / M.LEVEL_EVERY)
	if steps > 0 then rows[#rows + 1] = { key = "level", ossidiana = M.OBS_LEVEL * steps } end
	return rows
end

-- a finished chapter of the campaign (once)
function M.chapter()
	return { { key = "chapter", ossidiana = M.OBS_CHAPTER } }
end

-- adds the rows to the profile; returns the totals
function M.apply(p, rows)
	local sc, ob = 0, 0
	for _, r in ipairs(rows) do
		sc, ob = sc + (r.scaglie or 0), ob + (r.ossidiana or 0)
	end
	p.scaglie, p.ossidiana = p.scaglie + sc, p.ossidiana + ob
	return sc, ob
end

-- the date for the first win of the day (local time of the phone)
function M.today()
	return os.date("%Y-%m-%d")
end

return M
