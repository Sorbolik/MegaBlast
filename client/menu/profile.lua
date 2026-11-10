-- The player's profile on the phone: level, the pieces' levels, the 3 loadouts,
-- the stats with badges and the latest matches. Until the server keeps
-- accounts it is saved locally (sys.save); the logic is pure Lua and is tested.
--
-- Progression (docs/game_design_competitivo.md, "Più avanti: reward e
-- progressione"; numbers from the Sigilli proposal, Sergio 10 Nov): every match
-- gives experience, more for points, the win and the MVP; every level up to
-- skills.LEVEL_MAX gives a point of the Sigilli, after it the bar goes on and
-- gives braci (only a sign next to the level); playing with a piece raises its tier.
-- Scorie (the Forge's material) will come with the Forge.

local skills = require "sim.skills"
local loadout = require "sim.loadout"
local milestones = require "menu.milestones"
local wallet = require "menu.wallet"
local common = require("lang.text").common

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
M.XP_BASE, M.XP_STEP = 150, 25
M.LEVEL_MAX = skills.LEVEL_MAX

-- The settings and their defaults (docs/impostazioni.md)
-- (tasti: the remapped controller buttons, button -> command; nil is the default mapping, ui/controller.lua)
-- (sparo: with the controller the shot fires on pressing or on releasing the
-- button; potenza: with the controller it comes from the right stick or from
-- how far the trigger is pressed)
M.SETTINGS = { mira = "lancetta", sparo = "rilascio", potenza = "levetta", levette = "destra", fps = "spento" }

function M.setting(p, lookup_key)
	local v = p and p.impostazioni and p.impostazioni[lookup_key]
	if v == nil then return M.SETTINGS[lookup_key] end
	return v
end

function M.set(p, lookup_key, value)
	p.impostazioni = p.impostazioni or {}
	p.impostazioni[lookup_key] = value
end

function M.new()
	local p = { versione = M.VERSION, xp = 0, livello = 1, braci = 0, loadouts = {}, is_active = 1, stelle = {}, failed_ones = {},
		armi = {}, impostazioni = {}, statistiche = {}, partite = {}, badge = {}, serie = 0, numero = 0,
		-- the story's chapters already seen (ui/story.lua)
		storia = {} }
	for i = 1, loadout.LOADOUTS do p.loadouts[i] = loadout.new() end
	-- Scaglie, Ossidiana and the pieces' levels (menu/wallet.lua)
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

function M.active_loadout(p)
	return p.loadouts[p.is_active]
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
function M.match_xp(r)
	local x = M.XP
	local lines = { { key = "match", xp = x.match } }
	local pts = math.max(0, math.floor((r.points or 0) + 0.5))
	if pts > 0 then
		lines[#lines + 1] = { key = "points", n = pts, xp = math.min(x.points_max, math.floor(pts * x.points_share + 0.5)) }
	end
	if r.won then lines[#lines + 1] = { key = "win", xp = x.win }
	elseif r.second then lines[#lines + 1] = { key = "second", xp = x.second } end
	if r.mvp then lines[#lines + 1] = { key = "mvp", xp = x.mvp } end
	for _, a in ipairs(r.awards or {}) do lines[#lines + 1] = { key = "award", name = a.name, xp = x.award } end
	return lines
end

-- End of match (see match_xp). Updates the profile and returns the gain (add_xp).
function M.match_end(p, r)
	local g = add_xp(p, M.match_xp(r))
	-- the Proof of the steps: one more match for each piece worn
	wallet.wear(p, M.active_loadout(p))
	return g
end

-- Stats, badges and matches (character sheet, Sergio 31 Oct) -------------------

-- The stat groups, like the filters of the STATISTICHE tab. TUTTE isn't
-- saved: it is summed (records with the max)
M.GROUPS = { "2v2", "1v1", "torneo", "campagna", "tutte" }
M.GROUP_NAMES = { ["2v2"] = common.modes["2v2"], ["1v1"] = common.modes["1v1"], torneo = common.tournament,
	campagna = common.campaign, ffa = common.modes.ffa, tutte = common.all }
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

-- End of match: r is the summary from menu/tally.lua (gruppo, valori, armi,
-- won, partita). Adds the stats to the group, keeps the win streak and puts
-- the match at the top of the list (the oldest drop out). Returns the saved
-- match, with its number (for the replay file).
function M.record(p, r)
	local g = p.statistiche[r.gruppo] or {}
	p.statistiche[r.gruppo] = g
	for k, v in pairs(r.valori) do
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
	p.numero = p.numero + 1
	local play_match = r.partita
	play_match.numero = p.numero
	table.insert(p.partite, 1, play_match)
	while #p.partite > M.MATCHES do table.remove(p.partite) end
	return play_match
end

-- Only in the scenarios (imposta prova_profilo 1, scenari/scheda.txt): a
-- profile that has already played, to see pieces, powers, badges, stats and
-- the campaign's stars
function M.sample(p, near_level_up)
	p.livello, p.xp = 23, near_level_up and M.xp_level(23) - 20 or 410
	local a = p.loadouts[p.is_active]
	a.gear = { mask = "corvo", chest = "fornace", cloak = "corvo", legs = "leviatano" }
	a.tree = { wings = 12, armor = 6, forge = 3, pick = { wings = { 2, 1 }, armor = { 1 } } }
	p.pezzi.corvo_mask, p.pezzi.fornace_chest, p.pezzi.corvo_cloak, p.pezzi.leviatano_legs = 24, 19, 9, 30
	p.prova.corvo_cloak, p.prova.fornace_chest = 2, 5
	p.scaglie, p.ossidiana = 1240, 35
	p.statistiche["2v2"] = { partite = 48, vinte = 27, colpi = 310, a_segno = 190, danno = 14500, abbattuti = 60,
		nel_vuoto = 23, globi = 140, colpo_lungo = 1180, casse = 35, cadute = 12, morti = 30, serie = 4,
		armi = { missile = 5200, grenade = 3100, eagle = 2600, sword = 1800, mallet = 1300, shards = 500 } }
	p.statistiche["1v1"] = { partite = 9, vinte = 4, colpi = 60, a_segno = 31, danno = 2100, abbattuti = 8, globi = 20,
		colpo_lungo = 700, casse = 6, serie = 2, armi = { missile = 1200, sniper = 900 } }
	p.serie, p.badge = 1, { "colpo_lungo" }
	-- the campaign: the Training done, the Forge up to the Due mani (the board, scenari/bacheca.txt)
	for _, id in ipairs({ "primi_passi", "lanciarune", "turno", "prima_sfida", "attrezzi", "spostano", "sfida_burrone", "tempo", "guidata" }) do
		p.stelle[id] = { true, id ~= "turno", id == "primi_passi" or id == "guidata" }
	end
	p.stelle.primo_sangue, p.stelle.fuori_portata = { true, true, false }, { true, false, false }
end

-- A match's replay file: one per slot, reused in rotation
function M.replay_place(number)
	return (number - 1) % M.MATCHES + 1
end

-- Campaign missions and lessons (sim/campaign.lua): for each one the three
-- stars { true, false, true }: saves them (each one once taken stays, even
-- across different matches) and returns the experience gained (add_xp):
-- XP_MISSION.done the first time, star for each new star, replay if nothing is new
function M.mission(p, id, stars)
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
	if #lines == 0 then lines[1] = { key = "replay", xp = x.replay } end
	return add_xp(p, lines)
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

-- Saving -------------------------------------------------------------------------

local function file()
	return sys.get_save_file("megablast", "profilo")
end

function M.load_up()
	local ok, p = pcall(sys.load, file())
	if not ok or type(p) ~= "table" or p.versione ~= M.VERSION then return M.new() end
	-- a field added to nuovo() later is missing from older saves of the same
	-- version: it starts empty, without resetting the profile
	for k, v in pairs(M.new()) do
		if p[k] == nil then p[k] = v end
	end
	-- the matches per piece of before the Scaglie (10 Nov): the levels start from 1
	p.mastery = nil
	-- the old skill tree (nodes, before the Sigilli of 10 Nov): it starts empty,
	-- the level stays (at most the new maximum)
	for _, a in ipairs(p.loadouts) do
		if not skills.valid(a.tree or {}, math.huge) then a.tree = {} end
	end
	p.livello = math.min(p.livello, M.LEVEL_MAX)
	return p
end

function M.save(p)
	sys.save(file(), p)
end

return M
