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

print(failures == 0 and "OK" or (failures .. " FAIL"))
os.exit(failures == 0 and 0 or 1)
