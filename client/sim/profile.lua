-- The player's profile: level, experience, the pieces' levels (sim/wallet.lua),
-- the 3 loadouts, the stats with badges, the latest matches and the campaign's
-- stars. Pure Lua, in the shared rules so the server can run the same sums
-- as the phone (guest profiles, plan of 17 Nov); the phone saves it and keeps
-- its settings in menu/profile.lua; tested in tests/scheda_test.lua.
--
-- Progression (docs/game_design_competitivo.md, "Più avanti: reward e
-- progressione"; numbers from the Sigilli proposal, Sergio 10 Nov): every match
-- gives experience, more for points, the win and the MVP; every level up to
-- skills.LEVEL_MAX gives a point of the Sigilli, after it the bar goes on and
-- gives braci (only a sign next to the level); playing with a piece raises its tier.

local skills = require "sim.skills"
local loadout = require "sim.loadout"
local milestones = require "sim.milestones"
local wallet = require "sim.wallet"
local equip = require "sim.gear"

local M = {}

-- the save's version: a save with another one is ignored and the profile
-- starts over (2: the code's names went to English, Sergio 2 Nov, choice 7b)
M.VERSION = 2

-- experience of a match: played, half the points (at most points_max), win
-- (in free for all the 2nd takes second), MVP, each award
M.XP = { match = 40, points_share = 0.5, points_max = 120, win = 60, second = 30, mvp = 40, award = 15 }
-- of a campaign level: the first time it's done, each new star, played again with nothing new
M.XP_MISSION = { done = 40, star = 60, replay = 20 }
-- experience to go from level n to n + 1: XP_BASE + XP_STEP * (n - 1)
-- (Sergio, 17 Nov: a strong player makes about 2,800 an hour; light at the
-- start: level 2 after three matches. 23 Nov: half as much again, level 50
-- in about 370 hours: the road to the maximum got longer everywhere)
M.XP_BASE, M.XP_STEP = 600, 850
M.LEVEL_MAX = skills.LEVEL_MAX

function M.new()
	local p = { versione = M.VERSION, xp = 0, livello = 1, braci = 0, loadouts = {}, is_active = 1, seal_active = 1, stelle = {}, failed_ones = {}, point_records = {},
		armi = {}, impostazioni = {}, statistiche = {}, partite = {}, badge = {}, serie = 0, numero = 0,
		-- the story's chapters already seen (ui/story.lua)
		storia = {} }
	for i = 1, loadout.LOADOUTS do p.loadouts[i] = loadout.new() end
	-- Scaglie, Ossidiana and the pieces' levels (sim/wallet.lua)
	return wallet.init(p)
end

-- experience needed to go up from level n (after the last, the same as the last: one brace)
function M.xp_level(n)
	return M.XP_BASE + M.XP_STEP * (math.min(n, M.LEVEL_MAX) - 1)
end

function M.points(p)
	return skills.points(p.livello)
end

-- tier of the pieces worn by a loadout: { mask = 1..4, ... }, from their levels
function M.tier(p, a)
	return wallet.tiers(p, a)
end

-- levels of the pieces worn by a loadout: { mask = 1..30, ... } (sim/loadout.lua's stats)
function M.levels(p, a)
	return wallet.levels(p, a)
end

-- the stats the loadout a plays with: Sigilli, level, pieces and their signatures lit
function M.stats(p, a, base)
	return loadout.stats(base, a, wallet.levels(p, a), p.livello, wallet.signs(p, a))
end

-- The loadout that goes into a match: the pieces of the active loadout
-- (is_active) and the Sigilli of the active Sigilli's loadout (seal_active):
-- the ZAINO keeps them apart (Sergio, 14 Nov). Same tables, so changing its
-- gear or its tree changes the saved loadouts
function M.active_loadout(p)
	local g = p.loadouts[p.is_active]
	local s = p.loadouts[p.seal_active or p.is_active] or g
	if s == g then return g end
	return { gear = g.gear, tree = s.tree, variant = g.variant }
end

-- What a player shows of themselves online (the card: level, badges and the
-- pieces worn, an empty slot set ""; menu/showcase.lua reads it) and what they
-- wear, for their robot's stats (sim/loadout.lua net_clean: the Sigilli, the
-- pieces with their levels lv and signatures lit sg, the level liv). The
-- server makes them from its own profile (server/accounts.go)
function M.showcase(p)
	local bdg = {}
	for _, b in ipairs(M.badge(p)) do bdg[#bdg + 1] = { id = b.id, grado = b.grado } end
	-- (no badges, no bdg: the empty table would be an object in JSON)
	local a = M.active_loadout(p)
	local pz = {}
	for i, s in ipairs(equip.SLOTS) do
		local set = a.gear[s.id]
		pz[i] = { set = set or "", liv = set and wallet.level(p, set, s.id) or 0 }
	end
	return { liv = p.livello, bdg = #bdg > 0 and bdg or nil, pz = pz }
end

function M.equip(p)
	local a = M.active_loadout(p)
	return loadout.net_clean({ tree = a.tree, gear = a.gear, variant = a.variant, liv = p.livello,
		lv = wallet.levels(p, a), sg = wallet.signs(p, a) })
end

-- Adds the experience lines { { key, xp, ... } } to the profile and returns
-- the gain: { lines, xp = total, level_before, livello, braci_before, braci }
local function add_xp(p, lines)
	local g = { lines = lines, xp = 0, level_before = p.livello, braci_before = p.braci or 0 }
	for _, l in ipairs(lines) do g.xp = g.xp + l.xp end
	p.xp = p.xp + g.xp
	p.braci = p.braci or 0
	while p.xp >= M.xp_level(p.livello) do
		p.xp = p.xp - M.xp_level(p.livello)
		if p.livello < M.LEVEL_MAX then p.livello = p.livello + 1 else p.braci = p.braci + 1 end
	end
	g.livello, g.braci = p.livello, p.braci
	return g
end

-- The experience of a match, line by line. r = { points, won = true | false |
-- nil (tie), second = true (2nd in free for all), mvp = true, awards = { award } }
-- Against bots or on the same phone (r.bots) the experience is like the
-- Scaglie (Sergio, 17 Nov): half, and only the first wallet.BOTS_DAY matches
-- of the day (paid = false: that day's are over, nothing).
function M.match_xp(r, paid)
	local x = M.XP
	if r.bots and paid == false then return { { key = "bots_over", xp = 0 } } end
	local lines = { { key = "match", xp = x.match } }
	local pts = math.max(0, math.floor((r.points or 0) + 0.5))
	if pts > 0 then
		lines[#lines + 1] = { key = "points", n = pts, xp = math.min(x.points_max, math.floor(pts * x.points_share + 0.5)) }
	end
	if r.won then lines[#lines + 1] = { key = "win", xp = x.win }
	elseif r.second then lines[#lines + 1] = { key = "second", xp = x.second } end
	if r.mvp then lines[#lines + 1] = { key = "mvp", xp = x.mvp } end
	for _, a in ipairs(r.awards or {}) do lines[#lines + 1] = { key = "award", name = a.name, xp = x.award } end
	if r.bots then
		for _, l in ipairs(lines) do l.xp = math.floor(l.xp / 2 + 0.5) end
	end
	return lines
end

-- End of match (see match_xp). Updates the profile and returns the gain (add_xp).
-- today ("2026-11-17"): for the day's count of the matches against bots, which
-- wallet.match moves on after this
function M.match_end(p, r, today)
	local g = add_xp(p, M.match_xp(r, not r.bots or wallet.bots_pay(p, today)))
	-- the Proof of the steps: one more match for each piece worn
	wallet.wear(p, M.active_loadout(p))
	return g
end

-- Stats, badges and matches (character sheet, Sergio 31 Oct) -------------------

-- The stat groups, like the filters of the STATISTICHE tab. TUTTE isn't
-- saved: it is summed (records with the max)
-- the matches that are kept (with the replays of those played on this phone)
M.MATCHES = 10

-- The values of a group ({} if missing); "tutte" sums them
function M.statistics(p, cluster)
	if cluster ~= "tutte" then return p.statistiche[cluster] or {} end
	local tot = {}
	for _, g in pairs(p.statistiche) do
		for k, v in pairs(g) do
			if type(v) == "number" then
				local s = milestones.BY_ID[k]
				if (s and s.record) or k == "serie" then
					tot[k] = math.max(tot[k] or 0, v)
				else
					tot[k] = (tot[k] or 0) + v
				end
			elseif type(v) == "table" then
				-- the damage per weapon
				tot[k] = tot[k] or {}
				for w, n in pairs(v) do tot[k][w] = (tot[k][w] or 0) + n end
			end
		end
	end
	return tot
end

-- The badges next to the name: the chosen ones, then the highest (menu/milestones.lua)
function M.badge(p)
	return milestones.shown(M.statistics(p, "tutte"), p.badge)
end

-- Tap a badge on the sheet: if it is among the chosen ones it is removed,
-- otherwise it goes in front (at most traguardi.SHOWN)
function M.choose_badge(p, id)
	for i, b in ipairs(p.badge) do
		if b == id then
			table.remove(p.badge, i)
			return false
		end
	end
	table.insert(p.badge, 1, id)
	while #p.badge > milestones.SHOWN do table.remove(p.badge) end
	return true
end

-- End of match: r is the summary from sim/tally.lua (gruppo, valori, armi,
-- won). Adds the stats to the group and keeps the win streak (the server's
-- part: sim/progress.lua)
function M.add_stats(p, r)
	local g = p.statistiche[r.gruppo] or {}
	p.statistiche[r.gruppo] = g
	for k, v in pairs(r.valori or {}) do
		local s = milestones.BY_ID[k]
		if s and s.record then g[k] = math.max(g[k] or 0, v) else g[k] = (g[k] or 0) + v end
	end
	g.partite = (g.partite or 0) + 1
	if r.won then
		g.vinte = (g.vinte or 0) + 1
		p.serie = p.serie + 1
	elseif r.won == false then
		p.serie = 0
	end
	g.serie = math.max(g.serie or 0, p.serie)
	g.armi = g.armi or {}
	for w, n in pairs(r.armi or {}) do g.armi[w] = (g.armi[w] or 0) + n end
end

-- The match (r.partita of sim/tally.lua) at the top of the phone's list (the
-- oldest drop out), with its number (for the replay file). Returns it
function M.keep_match(p, play_match)
	p.numero = p.numero + 1
	play_match.numero = p.numero
	table.insert(p.partite, 1, play_match)
	while #p.partite > M.MATCHES do table.remove(p.partite) end
	return play_match
end

-- Only in the scenarios (imposta prova_vuoto 1 base, 2 forged at gold,
-- A match's replay file: one per slot, reused in rotation
function M.replay_place(number)
	return (number - 1) % M.MATCHES + 1
end

-- Campaign missions and lessons (sim/campaign.lua): for each one the three
-- stars { true, false, true }: saves them (each one once taken stays, even
-- across different matches) and returns the experience gained (add_xp):
-- XP_MISSION.done the first time, star for each new star, replay if nothing is new
-- made: the points the player made in this run, where they count
-- (sim/missions.lua, points): the best one stays as the level's record
-- (Sergio, 14 Nov: in points, not stars; past three stars you play against your own points)
function M.mission(p, id, stars, made)
	p.point_records = p.point_records or {}
	local before = p.point_records[id]
	if made and (not before or made > before) then p.point_records[id] = made end
	local picked = p.stelle[id] or { false, false, false }
	local first = not picked[1]
	local new = 0
	for i = 1, 3 do
		if stars[i] == true and not picked[i] then new = new + 1 end
		picked[i] = picked[i] or stars[i] == true
	end
	p.stelle[id] = picked
	p.failed_ones[id] = nil
	local x, lines = M.XP_MISSION, {}
	if first then lines[#lines + 1] = { key = "done", xp = x.done } end
	if new > 0 then lines[#lines + 1] = { key = "stars", n = new, xp = x.star * new } end
	-- a replay counts only when it beats the record of points
	local record = made ~= nil and before ~= nil and made > before
	if #lines == 0 then lines[1] = { key = record and "replay" or "replay_plain", xp = record and x.replay or 0 } end
	local gain = add_xp(p, lines)
	gain.record_before = before
	gain.record = record
	return gain
end

-- The most points made on a level, nil if never counted
function M.points_record(p, id)
	return p.point_records and p.point_records[id]
end

-- A lost mission: from the third in a row the opponents ease off
-- (sim/missions.lua, help), without saying so
M.HELP_AFTER = 3
function M.failed(p, id)
	p.failed_ones[id] = (p.failed_ones[id] or 0) + 1
end

function M.help(p, id)
	return (p.failed_ones[id] or 0) >= M.HELP_AFTER
end

-- All the stars taken (they open the campaign chapters)
function M.total_stars(p)
	local n = 0
	for _, v in pairs(p.stelle) do
		for i = 1, 3 do
			if v[i] then n = n + 1 end
		end
	end
	return n
end

-- The Training basics (sim/campaign.lua): whoever hasn't finished them all is
-- a new player, and GIOCA takes them to the first one missing (Claude, 29 Oct:
-- before, the First match, which is now the chapter's final exam). Today they
-- are a single path, Primi passi (Sergio, 29 Oct)
local BASES = { "primi_passi" }

function M.first_lesson(p)
	for _, id in ipairs(BASES) do
		if not (p.stelle[id] and p.stelle[id][1]) then return id end
	end
	return nil
end

function M.new_player(p)
	return M.first_lesson(p) ~= nil
end

-- A weapon found (battle/card.lua): true only the first time, then it
-- stays seen (its card no longer pops up outside the lessons)
function M.new_weapon(p, w)
	if p.armi[w] then return false end
	p.armi[w] = true
	return true
end

-- The weapons the player has already seen: those found in crates and those
-- the finished missions gave them. The campaign's weapon draft offers only
-- these (Sergio, 30 Oct)
function M.weapons_seen(p)
	local seen_weapons = {}
	for w in pairs(p.armi) do seen_weapons[w] = true end
	for _, cap in ipairs(require("sim.campaign").CAPITOLI) do
		for _, l in ipairs(cap.missioni) do
			local my_own = l.giocatori and l.giocatori[1]
			if my_own and p.stelle[l.id] and p.stelle[l.id][1] then
				for _, w in ipairs({ my_own.pick or "", my_own.secondary or "" }) do seen_weapons[w] = true end
			end
		end
	end
	return seen_weapons
end


-- An older save of the same version brought up to date: fields added to new()
-- later start empty, the old ones are dropped or converted (the gifts already
-- earned are given). The phone does it at every load, the server on import.
function M.upgrade(p)
	for k, v in pairs(M.new()) do
		if p[k] == nil then p[k] = v end
	end
	-- the matches per piece of before the Scaglie (10 Nov): the levels start from 1
	p.mastery = nil
	-- the records of lead points (#318, 14 Nov): now the record is the points made
	p.lead_records = nil
	-- before the shop (11 Nov): the levelled pieces stay, the others come off
	wallet.migrate(p, p.loadouts)
	-- the gifts already earned (the Smith's boots, the vouchers)
	wallet.gifts(p, M.statistics(p, "tutte"), p.livello)
	-- the old skill tree (nodes, before the Sigilli of 10 Nov): it starts empty,
	-- the level stays (at most the new maximum)
	for _, a in ipairs(p.loadouts) do
		if not skills.valid(a.tree or {}, math.huge) then a.tree = {} end
	end
	p.livello = math.min(p.livello, M.LEVEL_MAX)
	return p
end

-- Guest profiles (plan of 17 Nov, choice 1A): the progress a phone already
-- has goes to the server once, cut to these caps. Only what the server keeps
-- comes along (the last matches, their replays and the settings stay on the
-- phone); everything is checked like data from outside: what doesn't fit
-- the rules is dropped, the rest stays.
M.IMPORT = { level = 30, scaglie = 30000, ossidiana = 200, piece = 20, vouchers = 10 }

local function whole(v, lo, hi)
	return type(v) == "number" and v % 1 == 0 and v >= lo and v <= hi
end

local function name_ok(k)
	return type(k) == "string" and #k <= 40 and k:match("^[%w_]+$") ~= nil
end

-- a plain copy of a Sigilli tree (numbers and the picks), nil if it isn't one
local function tree_copy(t)
	if type(t) ~= "table" then return nil end
	local out = {}
	for k, v in pairs(t) do
		if k == "pick" and type(v) == "table" then
			out.pick = {}
			for path, list in pairs(v) do
				if type(list) ~= "table" then return nil end
				local l = {}
				for i, w in pairs(list) do l[i] = w end
				out.pick[path] = l
			end
		elseif type(v) == "number" then
			out[k] = v
		else
			return nil
		end
	end
	return out
end

-- A stat group from outside (an import, a match declared by the phone):
-- whole numbers of the known entries, at most top each, and the damage per
-- weapon. nil if the group can't be one
function M.clean_stats(g, vals, top)
	if not name_ok(g) or g == "tutte" or type(vals) ~= "table" then return nil end
	local known = {}
	for _, st in ipairs(milestones.WHITELIST) do known[st.id] = true end
	for _, k in ipairs(milestones.OTHERS) do known[k] = true end
	known.vinte = true
	local weapons = require("sim.game").WEAPONS
	local out = {}
	for k, v in pairs(vals) do
		if known[k] and whole(v, 0, top) then out[k] = v end
	end
	if type(vals.armi) == "table" then
		out.armi = {}
		for w, n in pairs(vals.armi) do
			if weapons[w] and whole(n, 0, top) then out.armi[w] = n end
		end
	end
	return out
end

-- The loadouts and the active ones from outside (an import, the ZAINO of the
-- phone): Sigilli within the points of p's level, pieces of sets that exist
-- (the worn ones must also be owned: wallet.migrate, in upgrade)
function M.take_loadouts(p, src)
	local points = skills.points(p.livello)
	for i = 1, loadout.LOADOUTS do
		local a = type(src.loadouts) == "table" and src.loadouts[i]
		if type(a) == "table" then
			local l = p.loadouts[i]
			local tree = tree_copy(a.tree)
			if tree and skills.valid(tree, points) then l.tree = tree end
			l.variant = a.variant == "b" and "b" or "a"
			-- (a can be l itself: the phone's own ZAINO)
			local gear = {}
			if type(a.gear) == "table" then
				for _, sl in ipairs(equip.SLOTS) do
					local set = a.gear[sl.id]
					if type(set) == "string" and equip.BY_ID[set] then gear[sl.id] = set end
				end
			end
			l.gear = gear
		end
	end
	for _, k in ipairs({ "is_active", "seal_active" }) do
		if whole(src[k], 1, loadout.LOADOUTS) and loadout.open(src[k], p.livello) then p[k] = src[k] end
	end
end

function M.import(src)
	local p = M.new()
	if type(src) ~= "table" then return p end
	local cap = M.IMPORT
	p.livello = whole(src.livello, 1, math.huge) and math.min(src.livello, cap.level) or 1
	if type(src.xp) == "number" and src.xp >= 0 then
		p.xp = math.min(math.floor(src.xp), M.xp_level(p.livello) - 1)
	end
	if p.livello >= M.LEVEL_MAX and whole(src.braci, 0, 1e6) then p.braci = src.braci end
	p.scaglie = whole(src.scaglie, 0, math.huge) and math.min(src.scaglie, cap.scaglie) or 0
	p.ossidiana = whole(src.ossidiana, 0, math.huge) and math.min(src.ossidiana, cap.ossidiana) or 0
	p.buoni = whole(src.buoni, 0, math.huge) and math.min(src.buoni, cap.vouchers) or 0
	-- the pieces: owned, levels (at most cap.piece), signatures within their step, the Proof
	for _, f in ipairs(equip.SETS) do
		for _, sl in ipairs(equip.SLOTS) do
			local k = wallet.key(f.id, sl.id)
			if type(src.posseduti) == "table" and src.posseduti[k] == true then p.posseduti[k] = true end
			local l = type(src.pezzi) == "table" and src.pezzi[k]
			if whole(l, 1, math.huge) then p.pezzi[k] = math.min(l, cap.piece) end
			local sg = type(src.firme) == "table" and src.firme[k]
			if whole(sg, 0, #equip.SIGN_COSTS) then
				p.firme[k] = math.min(sg, equip.tier(p.pezzi[k] or 1) - 1)
			end
			local pr = type(src.prova) == "table" and src.prova[k]
			if whole(pr, 0, 100) then p.prova[k] = pr end
		end
	end
	if type(src.regali) == "table" then
		for k, v in pairs(src.regali) do
			if v == true and name_ok(k) then p.regali[k] = true end
		end
	end
	for _, k in ipairs({ "giorno", "bot_giorno" }) do
		if type(src[k]) == "string" and src[k]:match("^%d%d%d%d%-%d%d%-%d%d$") then p[k] = src[k] end
	end
	if whole(src.bot_partite, 0, wallet.BOTS_DAY) then p.bot_partite = src.bot_partite end
	-- the campaign: stars and records of the levels that exist
	local levels = {}
	for _, cap_ in ipairs(require("sim.campaign").CAPITOLI) do
		for _, l in ipairs(cap_.missioni) do levels[l.id] = true end
	end
	for id in pairs(levels) do
		local st = type(src.stelle) == "table" and src.stelle[id]
		if type(st) == "table" then p.stelle[id] = { st[1] == true, st[2] == true, st[3] == true } end
		local rec = type(src.point_records) == "table" and src.point_records[id]
		if type(rec) == "number" and rec >= 0 and rec < 1e6 then p.point_records[id] = math.floor(rec) end
		local f = type(src.failed_ones) == "table" and src.failed_ones[id]
		if whole(f, 0, 1000) then p.failed_ones[id] = f end
	end
	local weapons = require("sim.game").WEAPONS
	if type(src.armi) == "table" then
		for w, v in pairs(src.armi) do
			if v == true and weapons[w] then p.armi[w] = true end
		end
	end
	if type(src.storia) == "table" then
		for ch, v in pairs(src.storia) do
			if v == true and name_ok(ch) then p.storia[ch] = true end
		end
	end
	-- the stats: whole numbers of the known entries, the damage per weapon
	if type(src.statistiche) == "table" then
		for g, vals in pairs(src.statistiche) do
			local out = M.clean_stats(g, vals, 1e9)
			if out then p.statistiche[g] = out end
		end
	end
	if whole(src.serie, 0, 1e6) then p.serie = src.serie end
	if whole(src.numero, 0, 1e9) then p.numero = src.numero end
	if type(src.badge) == "table" then
		for _, id in ipairs(src.badge) do
			local st = milestones.BY_ID[id]
			if st and st.thresholds and #p.badge < milestones.SHOWN then p.badge[#p.badge + 1] = id end
		end
	end
	-- the loadouts: Sigilli within the points of the imported level
	M.take_loadouts(p, src)
	-- the worn pieces must be owned, the gifts already earned are given
	return M.upgrade(p)
end

return M
