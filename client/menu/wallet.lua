-- The two currencies and the pieces' levels (Sergio, 10 Nov, page "Scaglie e
-- Ossidiana" https://claude.ai/artifact/S8PhASdh61MoRdK2QFLXXM, all choices A).
-- Scaglie (soft) are earned playing and buy the pieces' levels; Ossidiana
-- (hard) is rare and will buy only looks and tournament entries, never levels
-- or Scaglie. Pure Lua, on the profile of the phone (menu/profile.lua) until
-- the progression goes on the server; tested in tests/wallet_test.lua.
--
-- The profile's fields (added by M.init, so old saves keep working):
--   scaglie, ossidiana: the balance
--   pezzi[set_slot]: the level of a piece (missing: 1)
--   prova[set_slot]: matches worn at the level below a step (the Proof)
--   giorno: the day of the last "first win of the day"
--   bot_giorno, bot_partite: the day and the paid matches against bots

local equip = require "sim.gear"
local milestones = require "menu.milestones"

local M = {}

-- Scaglie for a finished match (choice 3A). One row per entry, with the same
-- keys as the receipt's lines (ui/receipt.lua)
M.MATCH = 10              -- even lost; who quits gets nothing
M.POINTS_EACH, M.POINTS_MAX = 25, 6   -- 1 every 25 points, at most 6
M.WIN, M.SECOND = 15, 8   -- the win (the team in 2 vs 2), 2nd in free for all
M.MVP = 5
M.AWARD, M.AWARDS_MAX = 3, 2
M.DAILY = 40              -- first win of the day (choice 7A)
-- campaign missions: the first time, a replay, each new star
M.MISSION, M.REPLAY, M.STAR = 15, 8, 5
-- training against bots: half, only the first matches of the day
M.BOTS_DAY = 10

-- Ossidiana earned playing: a badge going up a grade (I..IV), every
-- LEVEL_EVERY levels of the devil, a finished chapter of the campaign
M.OBS_BADGE = { 5, 10, 20, 40 }
M.OBS_LEVEL, M.LEVEL_EVERY = 15, 5
M.OBS_CHAPTER = 30

function M.init(p)
	p.scaglie = p.scaglie or 0
	p.ossidiana = p.ossidiana or 0
	p.pezzi = p.pezzi or {}
	p.prova = p.prova or {}
	p.giorno = p.giorno or ""
	p.bot_giorno = p.bot_giorno or ""
	p.bot_partite = p.bot_partite or 0
	return p
end

local function key(set, slot) return set .. "_" .. slot end

-- level of a piece (1 if never upgraded)
function M.level(p, set, slot)
	return p.pezzi[key(set, slot)] or 1
end

-- the Smith's hand: a piece of that slot already at the top
function M.smith_hand(p, slot)
	for _, s in ipairs(equip.SETS) do
		if M.level(p, s.id, slot) >= equip.LIVELLO_MAX then return true end
	end
	return false
end

-- What the next level of a piece asks:
-- { level, cost, full_cost, proof, proof_done } or nil at the top
function M.next(p, set, slot)
	local l = M.level(p, set, slot) + 1
	if l > equip.LIVELLO_MAX then return nil end
	local hand = M.smith_hand(p, slot)
	return { level = l, cost = equip.cost(l, hand), full_cost = equip.cost(l), proof = equip.proof(l),
		proof_done = math.min(equip.proof(l), p.prova[key(set, slot)] or 0) }
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
-- awards = { ... }, bots = true (training) , quit = true }; today: "2026-11-10".
-- Returns the rows { { key, scaglie } } (nothing when quit) and does not touch
-- the profile except for the day of the bonus and the bots' count: apply
-- adds them.
function M.match(p, r, today)
	if r.quit then return {} end
	local half = 1
	if r.bots then
		if p.bot_giorno ~= today then p.bot_giorno, p.bot_partite = today, 0 end
		if p.bot_partite >= M.BOTS_DAY then return {} end
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
	add("award", M.AWARD * math.min(M.AWARDS_MAX, #(r.awards or {})))
	if r.won and not r.bots and p.giorno ~= today then
		p.giorno = today
		add("daily", M.DAILY)
	end
	return rows
end

-- The match seen by whoever plays on this phone, for M.match: res is the
-- sim's g:results() ({ mode, winner, ranking = { { robot, team, place, points } } }),
-- me their robot, awards those they took; online: an online match (otherwise
-- against bots or on the same phone: half, like the training).
-- The MVP: the most points of all, even in the losing team (first in the
-- ranking on a tie).
function M.result(res, me, awards, online)
	local r = { awards = awards or {}, bots = not online }
	local mine, best
	for _, v in ipairs(res.ranking) do
		if v.robot == me then mine = v end
		if not best or (v.points or 0) > (best.points or 0) then best = v end
	end
	if not mine then return r end
	r.points = mine.points or 0
	if res.winner ~= nil then r.won = res.winner == mine.team end
	r.second = res.mode == "ffa" and mine.place == 2 or nil
	r.mvp = best == mine and r.points > 0 or nil
	return r
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

-- Scaglie of a campaign mission: first time (or a replay) and the new stars
function M.mission(first, new_stars)
	local rows = { { key = first and "done" or "replay", scaglie = first and M.MISSION or M.REPLAY } }
	if new_stars > 0 then rows[2] = { key = "stars", scaglie = M.STAR * new_stars, n = new_stars } end
	return rows
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
