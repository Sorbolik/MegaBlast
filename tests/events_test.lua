-- Events in the game (client/main/eventi.lua): what's running, what counts for
-- which queue, the lines of the home and of the board. The real calendar is
-- tested by go test ./server/ (events_test.go).
--
--   luajit tests/events_test.lua

package.path = "client/?.lua;" .. package.path
local events = require "main.eventi"

local failures = 0
local function check(cond, msg)
	if cond then print("ok   " .. msg) else failures = failures + 1; print("FAIL " .. msg) end
end

local NOW = 1000000
events.loaded_ok = true
events.lista = {
	{ id = "maglio-1", tipo = "mod", nome = "2V2 SOLO MAGLIO", da = NOW - 3600, a = NOW + 90000, coda = "maglio-1", modo = "2v2",
		regole = { armi = { "punch", "mallet" }, casse = 2 } },
	{ id = "torneo-1", tipo = "torneo", nome = "TORNEO 2V2", da = NOW - 60, a = NOW + 7200, coda = "2v2", modo = "2v2" },
	{ id = "xp-1", tipo = "xp", nome = "XP DOPPI", da = NOW + 2 * 86400, a = NOW + 3 * 86400, coda = "2v2", modo = "2v2" },
}

check(#events.in_progress(NOW) == 2 and #events.upcoming(NOW) == 1, "running and upcoming")
local above = events.on_queue("2v2", NOW)
check(#above == 1 and above[1].id == "torneo-1", "the Torneo counts for the 2v2 queue")
local cc = events.with_queue(NOW)
check(#cc == 1 and cc[1].id == "maglio-1", "the Maglio has its own queue")
check(events.home_line(NOW) == "2 in corso", "home line with two events")
check(events.home_line(NOW + 100000) == "il prossimo tra 20h 13m", "home line with no running events: " .. events.home_line(NOW + 100000))
check(events.durata(90000) == "1g 1h" and events.durata(3000) == "50m" and events.durata(7200) == "2h", "durate")
check(events.quando(events.lista[2], NOW) == "finisce tra 2h", "when it ends")
local c = events.what_changes(events.lista[1], { punch = "PUGNO", mallet = "MAGLIO" })
check(c[1] == "2 CONTRO 2" and c[2] == "Armi: PUGNO, MAGLIO" and c[3] == "Casse ogni 2 turni", "what changes: " .. table.concat(c, " | "))
check(events.what_changes(events.lista[2])[1] == "Le partite normali 2 CONTRO 2", "the Torneo doesn't change the rules")
local tournament = { coda = "2v2", modo = "2v2", regole = { tetto = 15 } }
c = events.what_changes(tournament)
check(c[1] == "Le partite normali 2 CONTRO 2" and c[2] == "Pezzi al massimo al livello 15", "the Torneo's cap: " .. table.concat(c, " | "))

if failures > 0 then
	print(failures .. " tests failed")
	os.exit(1)
end
print("all tests passed")
