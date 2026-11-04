-- The player's profile on the phone: level, piece mastery, the 3 loadouts,
-- the stats with badges and the latest matches. Until the server keeps
-- accounts it is saved locally (sys.save); the logic is pure Lua and is tested.
--
-- Progression (docs/game_design_competitivo.md, "Più avanti: reward e
-- progressione"): every match gives experience (even when lost, more on the
-- podium); the level gives the tree points; playing with a piece raises its tier.
-- Scorie (the Forge's material) will come with the Forge.

local skills = require "sim.skills"
local loadout = require "sim.loadout"
local equip = require "sim.gear"
local milestones = require "menu.milestones"
local common = require("lang.text").common

local M = {}

-- the save's version: a save with another one is ignored and the profile
-- starts over (2: the code's names went to English, Sergio 2 Nov, choice 7b)
M.VERSION = 2

-- experience per place (1st, 2nd, 3rd, 4th) and per award
M.XP_PLACE = { 120, 80, 60, 50 }
M.XP_AWARD = 25
-- experience to go from level n to n + 1: XP_BASE + XP_STEP * (n - 1)
M.XP_BASE, M.XP_STEP = 100, 25

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

function M.imposta(p, lookup_key, value)
	p.impostazioni = p.impostazioni or {}
	p.impostazioni[lookup_key] = value
end

function M.nuovo()
	local p = { versione = M.VERSION, xp = 0, livello = 1, mastery = {}, loadouts = {}, is_active = 1, stelle = {}, failed_ones = {},
		armi = {}, impostazioni = {}, statistiche = {}, partite = {}, badge = {}, serie = 0, numero = 0,
		-- the story's chapters already seen (ui/story.lua)
		storia = {} }
	for i = 1, loadout.LOADOUTS do p.loadouts[i] = loadout.new() end
	return p
end

-- experience needed to go up from level n
function M.xp_level(n)
	return M.XP_BASE + M.XP_STEP * (n - 1)
end

function M.punti(p)
	return skills.points(p.livello)
end

-- tier of the pieces worn by a loadout: { mask = 1..3, ... }
function M.tier(p, a)
	local t = {}
	for _, s in ipairs(equip.SLOTS) do
		local set = a.gear[s.id]
		t[s.id] = set and equip.tier(p.mastery[set .. "_" .. s.id]) or 1
	end
	return t
end

function M.active_loadout(p)
	return p.loadouts[p.is_active]
end

-- End of match: place (1..4) and awards taken. Updates the profile and
-- returns what was gained { xp, level_before, livello }.
function M.match_end(p, spot, awards)
	local g = {
		xp = (M.XP_PLACE[spot] or M.XP_PLACE[#M.XP_PLACE]) + M.XP_AWARD * #(awards or {}),
		level_before = p.livello,
	}
	p.xp = p.xp + g.xp
	while p.xp >= M.xp_level(p.livello) do
		p.xp = p.xp - M.xp_level(p.livello)
		p.livello = p.livello + 1
	end
	g.livello = p.livello
	-- mastery: one more match for each piece worn
	local a = M.active_loadout(p)
	for _, s in ipairs(equip.SLOTS) do
		local set = a.gear[s.id]
		if set then
			local k = set .. "_" .. s.id
			p.mastery[k] = (p.mastery[k] or 0) + 1
		end
	end
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
function M.statistiche(p, cluster)
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
	return milestones.shown(M.statistiche(p, "tutte"), p.badge)
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
function M.registra(p, r)
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
function M.prova(p)
	p.livello, p.xp = 23, 410
	local a = p.loadouts[p.is_active]
	a.gear = { mask = "corvo", chest = "fornace", cloak = "corvo", legs = "leviatano" }
	a.tree = { jump = 2, walk = 1, air_jump = 1, hp = 1, teleport = 1, trap_wide = 2 }
	p.mastery.corvo_mask, p.mastery.fornace_chest, p.mastery.corvo_cloak, p.mastery.leviatano_legs = 24, 18, 11, 6
	p.statistiche["2v2"] = { partite = 48, vinte = 27, colpi = 310, a_segno = 190, danno = 14500, abbattuti = 60,
		nel_vuoto = 23, globi = 140, colpo_lungo = 1180, casse = 35, cadute = 12, morti = 30, serie = 4,
		armi = { missile = 5200, grenade = 3100, eagle = 2600, sword = 1800, mallet = 1300, shards = 500 } }
	p.statistiche["1v1"] = { partite = 9, vinte = 4, colpi = 60, a_segno = 31, danno = 2100, abbattuti = 8, globi = 20,
		colpo_lungo = 700, casse = 6, serie = 2, armi = { missile = 1200, sniper = 900 } }
	p.serie, p.badge = 1, { "colpo_lungo" }
	-- the campaign: the Training done, the Forge up to the Due mani (the board, scenari/bacheca.txt)
	for _, id in ipairs({ "primi_passi", "lanciarune", "turno", "tempo", "spostano", "attrezzi", "guidata" }) do
		p.stelle[id] = { true, id ~= "turno", id == "primi_passi" or id == "guidata" }
	end
	p.stelle.primo_sangue, p.stelle.fuori_portata = { true, true, false }, { true, false, false }
end

-- A match's replay file: one per slot, reused in rotation
function M.replay_place(number)
	return (number - 1) % M.MATCHES + 1
end

-- Campaign missions and lessons (sim/campaign.lua): for each one the three
-- stars { true, false, true }, each one once taken stays (even across
-- different matches)
function M.missione(p, id, stars)
	local picked = p.stelle[id] or { false, false, false }
	for i = 1, 3 do picked[i] = picked[i] or stars[i] == true end
	p.stelle[id] = picked
	p.failed_ones[id] = nil
end

-- A lost mission: from the third in a row the opponents ease off
-- (sim/missions.lua, help), without saying so
M.HELP_AFTER = 3
function M.fallita(p, id)
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
	if not ok or type(p) ~= "table" or p.versione ~= M.VERSION then return M.nuovo() end
	-- a field added to nuovo() later is missing from older saves of the same
	-- version: it starts empty, without resetting the profile
	for k, v in pairs(M.nuovo()) do
		if p[k] == nil then p[k] = v end
	end
	return p
end

function M.salva(p)
	sys.save(file(), p)
end

return M
