-- The player's profile on the phone: the rules are in sim/profile.lua (shared
-- with the server, plan of the guest profiles of 17 Nov), here what belongs to
-- the phone: the settings, the stat groups' names, the scenarios' sample
-- profiles, the end-game test profiles and the save (sys.save). The module
-- reads through to sim/profile.lua, so profile.mission, profile.record... are
-- the shared ones.

local rules = require "sim.profile"
local wallet = require "sim.wallet"
local progress = require "sim.progress"
local common = require("lang.text").common

local M = setmetatable({}, { __index = rules })


-- The settings and their defaults (docs/impostazioni.md)
-- (tasti: the remapped controller buttons, button -> command; nil is the default mapping, ui/controller.lua)
-- (sparo: with the controller the shot fires on pressing or on releasing the
-- button; potenza: with the controller it comes from the right stick or from
-- how far the trigger is pressed; vibrazione: all the phone's vibrations, main/phone.lua)
M.SETTINGS = { mira = "lancetta", sparo = "rilascio", potenza = "levetta", levette = "destra", fps = "spento",
	vibrazione = "accesa" }

function M.setting(p, lookup_key)
	local v = p and p.impostazioni and p.impostazioni[lookup_key]
	if v == nil then return M.SETTINGS[lookup_key] end
	return v
end

function M.set(p, lookup_key, value)
	p.impostazioni = p.impostazioni or {}
	p.impostazioni[lookup_key] = value
end
-- the stat groups' names (sim/profile.lua, GROUPS)
M.GROUP_NAMES = { ["2v2"] = common.modes["2v2"], ["1v1"] = common.modes["1v1"], torneo = common.tournament,
	campagna = common.campaign, ffa = common.modes.ffa, tutte = common.all }

-- scenari/vuoto_indossato.txt): the active loadout wears the five pieces of the Void,
-- or of another family (imposta prova_famiglia fabbro)
function M.sample_void(p, form, family)
	if (form or 0) <= 0 then return end
	family = family or "vuoto"
	local a = p.loadouts[p.is_active]
	a.gear = {}
	for _, sl in ipairs(require("sim.gear").SLOTS) do
		a.gear[sl.id] = family
		p.pezzi[family .. "_" .. sl.id] = form == 2 and 20 or 1
	end
end

-- Only in the scenarios (imposta prova_profilo 1, scenari/scheda.txt): a
-- profile that has already played, to see pieces, powers, badges, stats and
-- the campaign's stars
function M.sample(p, near_level_up, campaign_done, all_pieces)
	p.livello, p.xp = 23, near_level_up and M.xp_level(23) - 20 or 410
	local a = p.loadouts[p.is_active]
	a.gear = { mask = "corvo", chest = "fornace", cloak = "corvo", legs = "leviatano" }
	a.tree = { wings = 12, armor = 6, forge = 3, pick = { wings = { 2, 1 }, armor = { 1 } } }
	p.pezzi.corvo_mask, p.pezzi.fornace_chest, p.pezzi.corvo_cloak, p.pezzi.leviatano_legs = 24, 19, 9, 30
	for _, k in ipairs({ "corvo_mask", "fornace_chest", "corvo_cloak", "leviatano_legs", "fabbro_legs", "vuoto_mask" }) do
		p.posseduti[k] = true
	end
	-- prova_profilo 4: every piece, to see the grid of the ZAINO scroll (scenari/zaino_griglia.txt)
	if all_pieces then
		for _, f in ipairs(require("sim.gear").SETS) do
			for _, sl in ipairs(require("sim.gear").SLOTS) do p.posseduti[f.id .. "_" .. sl.id] = true end
		end
	end
	p.buoni = 2
	p.prova.corvo_cloak, p.prova.fornace_chest = 2, 5
	p.scaglie, p.ossidiana = 12400, 350
	-- the helmet's signature lit at its first grade: the second can be lit
	p.firme.corvo_mask = 1
	p.statistiche["2v2"] = { partite = 48, vinte = 27, colpi = 310, a_segno = 190, danno = 14500, abbattuti = 60,
		nel_vuoto = 23, globi = 140, colpo_lungo = 1180, casse = 35, cadute = 12, morti = 30, serie = 4,
		armi = { missile = 5200, grenade = 3100, eagle = 2600, sword = 1800, mallet = 1300, shards = 500 } }
	p.statistiche["1v1"] = { partite = 9, vinte = 4, colpi = 60, a_segno = 31, danno = 2100, abbattuti = 8, globi = 20,
		colpo_lungo = 700, casse = 6, serie = 2, armi = { missile = 1200, sniper = 900 } }
	p.serie, p.badge = 1, { "colpo_lungo" }
	-- the history (CRONOLOGIA PARTITE, scenari/profilo.txt)
	local now = os.time()
	for i, m in ipairs({ { "V", "2v2", "forgia", 612, 0 }, { "S", "2v2", "limbo", 288, 1 }, { "V", "1v1", "gola", 540, 2 },
		{ "V", "2v2", "ira", 701, 26 }, { "S", "torneo", "eresia", 199, 30 }, { "V", "2v2", "avarizia", 466, 60 } }) do
		p.numero = p.numero + 1
		p.partite[i] = { numero = p.numero, esito = m[1], gruppo = m[2], mappa = m[3], punti = { m[4], 400 }, quando = now - m[5] * 3600,
			me = 1, giocatori = { { nome = "TU", squadra = 1 }, { nome = "FAVILLA", squadra = 1 }, { nome = "BRACE", squadra = 2 },
				{ nome = "ZOLFO", squadra = 2 } } }
	end
	-- how the last one went, lap by lap, and its moments (the open row of the history);
	-- shown as a match that can be rewatched (the gold rounds), though its file isn't there
	p.partite[1].replay = true
	p.partite[1].fune = { 0, 40, 25, -30, -10, 60, 110, 90, 140, 180, 212 }
	p.partite[1].moments = { { giro = 3, testo = "colpo lungo su BRACE", t = 2400 },
		{ giro = 6, testo = "ZOLFO nel vuoto", t = 5200 }, { giro = 10, testo = "il colpo finale", t = 9100 } }
	-- the campaign: the Training done, the Forge up to the Due mani (the board, scenari/bacheca.txt)
	for _, id in ipairs({ "primi_passi", "lanciarune", "turno", "prima_sfida", "attrezzi", "spostano", "sfida_burrone", "tempo", "guidata" }) do
		p.stelle[id] = { true, id ~= "turno", id == "primi_passi" or id == "guidata" }
	end
	p.stelle.primo_sangue, p.stelle.fuori_portata = { true, true, false }, { true, false, false }
	p.point_records = { primo_sangue = 312, fuori_portata = 96 }
	-- prova_profilo 3: the Forge done too, the map of the circles (scenari/gironi.txt)
	if campaign_done then
		for _, cap in ipairs(require("sim.campaign").CAPITOLI) do
			for _, l in ipairs(cap.missioni) do p.stelle[l.id] = p.stelle[l.id] or { true, true, false } end
		end
	end
end

-- Saving -------------------------------------------------------------------------

-- The end-game test profile (Sergio, 14 Nov: "voglio provare l'end game",
-- to tune the top of the progression and then go back down): a second save,
-- picked in the settings, that never touches the real one. Online it changes
-- nothing: the server plays everyone with the base stats.
-- (false: the real profile; "prova": the end game; "risorse": every resource
-- and no upgrade, below)
M.test = false
-- the balance it always has (topped up at every load)
M.TEST_COINS = 999999
M.TEST_VOUCHERS = 99

-- Fills p as the end game: the devil at the last level (the Sigilli's points
-- all to spend), every piece owned at the last level, the whole campaign done
-- with the three stars, every weapon seen, the story already read, the wallet
-- full. The caps come from sim/skills.lua and sim/gear.lua, so they follow them.
function M.endgame(p, fresh)
	local equip = require "sim.gear"
	p.livello, p.xp = M.LEVEL_MAX, 0
	for _, f in ipairs(equip.SETS) do
		for _, s in ipairs(equip.SLOTS) do
			local k = wallet.key(f.id, s.id)
			p.posseduti[k] = true
			if not fresh then p.pezzi[k], p.prova[k], p.firme[k] = equip.LIVELLO_MAX, nil, #equip.SIGN_COSTS end
		end
	end
	for _, cap in ipairs(require("sim.campaign").CAPITOLI) do
		for _, l in ipairs(cap.missioni) do p.stelle[l.id] = { true, true, true } end
	end
	for _, ch in ipairs(require("ui.story").CHAPTERS) do p.storia[ch.id] = true end
	for w in pairs(require("sim.game").WEAPONS) do p.armi[w] = true end
	-- the gifts count as given, so they don't pop up
	wallet.gifts(p, M.statistics(p, "tutte"), p.livello)
	p.scaglie, p.ossidiana, p.buoni = M.TEST_COINS, M.TEST_COINS, M.TEST_VOUCHERS
	return p
end

-- The test profile with every resource and no upgrade (Sergio, 17 Nov: "voglio
-- vedere come si uppa"): the full wallet, every piece owned at level 1 with its
-- signature off, the last level with no Sigilli point spent, everything open,
-- and the Proof's matches counted as played (Sergio, 18 Nov: wallet.next).
-- It starts over every time it is picked in the settings; a load only tops
-- the wallet up, so what was upgraded stays until then.
function M.resources(p)
	p.no_proof = true
	return M.endgame(p, true)
end

local function file()
	return sys.get_save_file("megablast", M.test == "risorse" and "profilo_risorse" or M.test and "profilo_prova" or "profilo")
end

-- which profile the phone uses: its own small file, outside both profiles
local function choice_file()
	return sys.get_save_file("megablast", "profilo_scelto")
end

-- false, "prova" or "risorse"
function M.test_chosen()
	local ok, t = pcall(sys.load, choice_file())
	if not ok or type(t) ~= "table" then return false end
	return t.quale == "risorse" and "risorse" or t.prova == true and "prova"
end

-- Switches to the test profile (on = true) or back to the real one. p (the
-- profile in use) is refilled in place, so whoever holds it sees the other
-- one; the settings (aim, controller buttons...) belong to the phone and
-- come along.
function M.choose_test(p, on)
	if on == true then on = "prova" end
	on = on or false
	-- (picking the resources one again starts it over)
	if on == M.test and on ~= "risorse" then return p end
	M.save(p)
	local settings = p.impostazioni
	sys.save(choice_file(), { prova = on == "prova", quale = on or nil })
	local other
	if on == "risorse" then
		-- picked again: it starts over
		M.test = on
		other = M.resources(M.new())
	else
		other = M.load_up()
	end
	for k in pairs(p) do p[k] = nil end
	for k, v in pairs(other) do p[k] = v end
	p.impostazioni = settings
	M.save(p)
	return p
end

function M.load_up()
	M.test = M.test_chosen()
	local ok, p = pcall(sys.load, file())
	if not ok or type(p) ~= "table" or p.versione ~= M.VERSION then
		p = M.new()
		return M.test == "risorse" and M.resources(p) or M.test and M.endgame(p) or p
	end
	-- an older save of the same version: brought up to date without resetting it
	rules.upgrade(p)
	-- the test profile: everything at the top again (new pieces, new missions, coins spent)
	if M.test == "risorse" then M.resources(p) elseif M.test then M.endgame(p) end
	return p
end

function M.save(p)
	sys.save(file(), p)
end

-- What changes the progress goes through here (sim/progress.lua): done at
-- once on the phone and saved, then, when it worked, on_act(p, a) sends it to
-- the server, whose profile counts (game.gui_script, main/account.lua).
-- Returns what the action returns, then nil and the number on_act gave it (the
-- receipt waits for the server's word on it). here: only on the phone (an
-- online match: the server counts it itself)
function M.act(p, a, here)
	local r, why = progress.act(p, a, wallet.today())
	M.save(p)
	local n
	if r and M.on_act and not here then n = M.on_act(p, a) end
	return r, why, n
end

-- Whether the Armeria can spend now: only with the network (choice 2A of the
-- plan); game.gui_script asks main/account.lua
M.can_spend = function() return true end

return M
