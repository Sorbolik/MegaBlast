-- Events in the game (client/main/eventi.lua): what's running, what counts for
-- which queue, the lines of the home and of the board. The real calendar is
-- tested by go test ./server/ (events_test.go).
--
--   luajit tests/events_test.lua

package.path = "client/?.lua;" .. package.path
local eventi = require "main.eventi"

local failures = 0
local function check(cond, msg)
	if cond then print("ok   " .. msg) else failures = failures + 1; print("FAIL " .. msg) end
end

local ORA = 1000000
eventi.caricato = true
eventi.lista = {
	{ id = "maglio-1", tipo = "mod", nome = "2V2 SOLO MAGLIO", da = ORA - 3600, a = ORA + 90000, coda = "maglio-1", modo = "2v2",
		regole = { armi = { "punch", "mallet" }, casse = 2 } },
	{ id = "torneo-1", tipo = "torneo", nome = "TORNEO 2V2", da = ORA - 60, a = ORA + 7200, coda = "2v2", modo = "2v2" },
	{ id = "xp-1", tipo = "xp", nome = "XP DOPPI", da = ORA + 2 * 86400, a = ORA + 3 * 86400, coda = "2v2", modo = "2v2" },
}

check(#eventi.in_corso(ORA) == 2 and #eventi.prossimi(ORA) == 1, "running and upcoming")
local su = eventi.su_coda("2v2", ORA)
check(#su == 1 and su[1].id == "torneo-1", "the Torneo counts for the 2v2 queue")
local cc = eventi.con_coda(ORA)
check(#cc == 1 and cc[1].id == "maglio-1", "the Maglio has its own queue")
check(eventi.riga_home(ORA) == "2 in corso", "home line with two events")
check(eventi.riga_home(ORA + 100000) == "il prossimo tra 20h 13m", "home line with no running events: " .. eventi.riga_home(ORA + 100000))
check(eventi.durata(90000) == "1g 1h" and eventi.durata(3000) == "50m" and eventi.durata(7200) == "2h", "durate")
check(eventi.quando(eventi.lista[2], ORA) == "finisce tra 2h", "when it ends")
local c = eventi.cosa_cambia(eventi.lista[1], { punch = "PUGNO", mallet = "MAGLIO" })
check(c[1] == "2 CONTRO 2" and c[2] == "Armi: PUGNO, MAGLIO" and c[3] == "Casse ogni 2 turni", "what changes: " .. table.concat(c, " | "))
check(eventi.cosa_cambia(eventi.lista[2])[1] == "Le partite normali 2 CONTRO 2", "the Torneo doesn't change the rules")
local torneo = { coda = "2v2", modo = "2v2", regole = { tetto = 15 } }
c = eventi.cosa_cambia(torneo)
check(c[1] == "Le partite normali 2 CONTRO 2" and c[2] == "Pezzi al massimo al livello 15", "the Torneo's cap: " .. table.concat(c, " | "))

if failures > 0 then
	print(failures .. " tests failed")
	os.exit(1)
end
print("all tests passed")
