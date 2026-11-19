-- Guest profiles (plan of 17 Nov, PR 3): the import of the phone's progress
-- (sim/profile.lua, import: the caps and the checks) and the profile as text
-- (sim/replay.lua, write/read; main/account.lua, text). From the root:
--   luajit tests/guest_test.lua
package.path = "client/?.lua;" .. package.path

local profile = require "sim.profile"
local replay = require "sim.replay"
local account = require "main.account"

local failures = 0
local function check(cond, msg)
	if cond then
		print("ok   " .. msg)
	else
		print("FAIL " .. msg)
		failures = failures + 1
	end
end

local function same(a, b)
	if type(a) ~= type(b) then return false end
	if type(a) ~= "table" then return a == b end
	for k, v in pairs(a) do if not same(v, b[k]) then return false end end
	for k in pairs(b) do if a[k] == nil then return false end end
	return true
end

-- a profile that has played: it goes to text and comes back the same
local p = profile.new()
p.livello, p.xp, p.scaglie, p.ossidiana, p.buoni = 23, 410, 12400, 350, 2
p.pezzi.corvo_mask, p.posseduti.corvo_mask, p.firme.corvo_mask = 24, true, 2
p.posseduti.fornace_chest, p.pezzi.fornace_chest = true, 19
p.loadouts[1].gear = { mask = "corvo", chest = "fornace" }
p.loadouts[1].tree = { wings = 12, armor = 6, pick = { wings = { 2, 1 } } }
p.stelle.primi_passi = { true, false, true }
p.point_records.primi_passi = 312
p.statistiche["2v2"] = { partite = 48, vinte = 27, danno = 14500, armi = { missile = 5200 } }
p.armi.missile = true
p.impostazioni.mira = "dito"
p.partite[1] = { numero = 1, esito = "V" }
local text = replay.write(p)
check(same(replay.read(text), p), "a profile goes to text and comes back the same")
check(replay.read("{") == nil and replay.read("os.exit()") == nil and replay.read("12") == nil, "a text that isn't a table is nil")

-- what the phone sends: without the last matches and the settings
local sent = replay.read(account.text(p))
check(sent.partite == nil and sent.impostazioni == nil and sent.scaglie == 12400, "the phone sends neither its matches nor its settings")

-- the import keeps what fits the caps
local q = profile.import(sent)
check(q.livello == 23 and q.xp == 410 and q.scaglie == 12400 and q.ossidiana == 200 and q.buoni == 2, "import: level and Scaglie as they are, Ossidiana at 200")
check(q.pezzi.corvo_mask == 20 and q.firme.corvo_mask == 2 and q.pezzi.fornace_chest == 19, "import: pieces at most at 20, signatures within the step")
check(q.loadouts[1].gear.mask == "corvo" and q.loadouts[1].tree.wings == 12 and q.loadouts[1].tree.pick.wings[1] == 2, "import: the loadout and its Sigilli")
check(same(q.stelle.primi_passi, { true, false, true }) and q.point_records.primi_passi == 312, "import: the campaign's stars and records")
check(q.statistiche["2v2"].vinte == 27 and q.statistiche["2v2"].armi.missile == 5200, "import: the stats")
check(q.partite[1] == nil and next(q.impostazioni) == nil, "import: nothing of the phone's own")

-- over the caps, impossible or foreign data
local big = profile.import({ livello = 50, xp = 1e9, scaglie = 999999, ossidiana = -5, buoni = 99,
	pezzi = { corvo_mask = 30, nessuno_mask = 9 }, posseduti = { corvo_mask = true, fornace_chest = "si" },
	firme = { corvo_mask = 3 }, stelle = { primi_passi = { true, "x" }, inventata = { true, true, true } },
	armi = { missile = true, bazooka_finto = true }, statistiche = { ["2v2"] = { danno = -1, colpi = 1.5, vinte = 3 } },
	loadouts = { { gear = { mask = "corvo", chest = "fornace" }, tree = { wings = 25, armor = 25, forge = 25 } }, "x" },
	is_active = 3, badge = { "colpo_lungo", "cadute", "boh" } })
check(big.livello == 30 and big.xp == profile.xp_level(30) - 1 and big.scaglie == 20000, "caps: level 30, experience within the level, 20,000 Scaglie")
check(big.ossidiana == 0 and big.buoni == 10, "caps: negative Ossidiana is 0, at most 10 vouchers")
check(big.pezzi.corvo_mask == 20 and big.pezzi.nessuno_mask == nil and big.firme.corvo_mask == 2, "caps: piece at 20, unknown pieces dropped")
check(big.posseduti.fornace_chest == nil and big.loadouts[1].gear.chest == nil and big.loadouts[1].gear.mask == "corvo", "only owned pieces are worn")
check(next(big.loadouts[1].tree) == nil, "Sigilli beyond the points of the level: the tree starts empty")
check(same(big.stelle.primi_passi, { true, false, false }) and big.stelle.inventata == nil, "stars only of real levels, only true counts")
check(big.armi.missile and not big.armi.bazooka_finto, "only real weapons")
check(big.statistiche["2v2"].danno == nil and big.statistiche["2v2"].colpi == nil and big.statistiche["2v2"].vinte == 3, "stats: only whole numbers not below zero")
check(big.is_active == 3 and #big.badge == 1, "the active loadout open at level 30, only badges that exist")
check(profile.import("x").livello == 1 and profile.import(nil).scaglie == 0, "something that isn't a profile: a new one")

-- The actions (sim/progress.lua): the same rules on the phone and on the server
do
	local progress = require "sim.progress"
	local today = "2026-11-19"
	local a = profile.new()
	a.scaglie = 5000
	check(progress.act(a, { k = "compra", set = "corvo", slot = "mask" }, today) and a.scaglie == 200 and a.posseduti.corvo_mask,
		"compra: from the CATALOGO at its price")
	check(not progress.act(a, { k = "compra", set = "corvo", slot = "mask" }, today), "compra: a piece owned isn't bought again")
	check(not progress.act(a, { k = "compra", set = "nessuno", slot = "mask" }, today) and not progress.act(a, { k = "boh" }, today),
		"an unknown piece or action does nothing")
	a.loadouts[1].gear = { mask = "corvo", chest = "fornace" }
	progress.act(a, progress.backpack(a), today)
	check(a.loadouts[1].gear.mask == "corvo" and a.loadouts[1].gear.chest == nil, "zaino: only owned pieces are worn")
	local g = progress.act(a, { k = "partita", r = { points = 1e9, won = true, awards = { {}, {}, {}, {}, {} } },
		conta = { gruppo = "2v2", valori = { danno = 1e9, colpi = 12, partite = 50 }, armi = { missile = 300 }, won = true } }, today)
	check(#g.lines == 6 and a.statistiche["2v2"].colpi == 12 and a.statistiche["2v2"].danno == nil and a.statistiche["2v2"].partite == 1,
		"partita: points, awards and stats within the caps")
	check(a.bot_partite == 1, "partita: on the phone it counts as one against the bots")
	check(progress.act(a, { k = "missione", id = "primi_passi", stars = { true, true, false }, made = 300 }, today).xp > 0
		and not progress.act(a, { k = "missione", id = "inventata", stars = { true } }, today), "missione: only real levels")
end

-- The phone and the server: the identity, the actions in their queue, the server's profile
do
	local asked, files = {}, {}
	http = { request = function(url, _, cb, _, body) asked[#asked + 1] = { url = url, cb = cb, body = body } end }
	sys = { get_save_file = function(_, name) return name end,
		load = function(f) if files[f] then return files[f] end error("none") end,
		save = function(f, t) files[f] = t return true end, get_sys_info = function() return {} end }
	json = { decode = function(t) return t end }
	local test = true
	local ph = profile.new()
	ph.impostazioni.mira = "dito"
	ph.scaglie = 9000
	account.start("ws://host/ws", ph, function() return test end, function() end)
	account.send(ph, { k = "compra", set = "corvo", slot = "mask" })
	check(#asked == 0, "test profile: nothing goes to the server")
	test = false
	require("sim.progress").act(ph, { k = "compra", set = "corvo", slot = "mask" }, "2026-11-19")
	account.send(ph, { k = "compra", set = "corvo", slot = "mask" })
	check(#asked == 1 and asked[1].url:find("^http://host/profilo/nuovo") and replay.read(asked[1].body).posseduti.corvo_mask,
		"back on the real one: the identity, bringing the profile")
	local sp = profile.import(replay.read(asked[1].body))
	sp.scaglie = 4000
	asked[1].cb(nil, nil, { status = 200, response = { id = 7, chiave = "k", profilo = replay.write(sp) } })
	check(ph.scaglie == 4000 and ph.impostazioni.mira == "dito" and account.identity().id == 7 and account.online(),
		"the server's profile takes the place of the phone's, the settings stay")
	ph.pezzi.corvo_mask = nil
	require("sim.progress").act(ph, { k = "potenzia", set = "corvo", slot = "mask" }, "2026-11-19")
	account.send(ph, { k = "potenzia", set = "corvo", slot = "mask" })
	account.send(ph, { k = "potenzia", set = "corvo", slot = "mask" })
	local sent2 = replay.read(asked[2].body)
	check(#asked == 2 and asked[2].url:find("^http://host/profilo/fai") and #sent2.azioni == 1 and sent2.azioni[1].n == 1,
		"an action goes at once, the next one waits for the answer")
	sp.scaglie = 3000
	asked[2].cb(nil, nil, { status = 200, response = { rev = 2, ultima = 1, profilo = replay.write(sp) } })
	check(ph.scaglie < 3000 and ph.pezzi.corvo_mask == 2, "what the server hasn't seen is done again on its profile")
	check(#asked == 3 and #replay.read(asked[3].body).azioni == 1 and replay.read(asked[3].body).azioni[1].n == 2,
		"then it goes to the server")
	asked[3].cb(nil, nil, { status = 0 })
	check(not account.online() and #files.azioni.list == 1, "without the network the action waits in its file")

	-- the recovery code: asked once, then kept with the identity
	local got
	account.code(false, function(c) got = c end)
	check(#asked == 4 and asked[4].url:find("^http://host/profilo/codice"), "the code: asked to the server")
	asked[4].cb(nil, nil, { status = 200, response = { codice = "ABCD-EFGH-JKMN" } })
	got = nil
	account.code(false, function(c) got = c end)
	check(got == "ABCD-EFGH-JKMN" and #asked == 4, "then read from the identity")
	-- «Ho già un profilo»: a wrong code, then the right one (the queue of the profile left goes)
	local ok, why
	account.recover("zzzz", function(a, b) ok, why = a, b end)
	asked[5].cb(nil, nil, { status = 404 })
	check(ok == false and why == "codice", "a wrong code: nothing changes")
	sp.scaglie = 777
	account.recover("pqrs tuvw xyz2", function(a, b) ok, why = a, b end)
	asked[6].cb(nil, nil, { status = 200, response = { id = 9, chiave = "k2", ultima = 40, profilo = replay.write(sp) } })
	check(ok and ph.scaglie == 777 and account.identity().id == 9 and account.identity().codice == "PQRS-TUVW-XYZ2"
		and #files.azioni.list == 0 and files.azioni.n == 40, "the right code: that profile, numbered after the server's actions")
	http, sys, json = nil, nil, nil
end

print(failures == 0 and "OK" or (failures .. " FAIL"))
os.exit(failures == 0 and 0 or 1)
