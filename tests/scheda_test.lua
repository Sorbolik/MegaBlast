-- Character sheet tests: badges and stats (menu/milestones.lua,
-- menu/profile.lua), the tags' showcases (menu/showcase.lua), the end-of-match
-- count (menu/tally.lua) and the replay (sim/replay.lua). From the root:
--   luajit tests/scheda_test.lua
package.path = "client/?.lua;" .. package.path

local milestones = require "menu.milestones"
local profile = require "menu.profile"
local showcase = require "menu.showcase"
local count = require "menu.tally"
local replay = require "sim.replay"
local game = require "sim.game"
local equip = require "sim.gear"

local failures = 0
local function check(cond, msg)
	if cond then
		print("ok   " .. msg)
	else
		print("FAIL " .. msg)
		failures = failures + 1
	end
end

-- Badges -----------------------------------------------------------------------
local aim_name = milestones.BY_ID.a_segno
check(milestones.grade(aim_name, 9) == 0 and milestones.grade(aim_name, 10) == 1 and milestones.grade(aim_name, 10000) == 4,
	"badge: one grade per threshold")
local threshold, f = milestones.next(aim_name, 55)
check(threshold == 100 and math.abs(f - 0.5) < 1e-9, "badge: the next threshold and how far it is from the previous one")
check(milestones.next(aim_name, 20000) == nil, "badge: after the last threshold there is no next one")
local taken = milestones.earned({ a_segno = 150, globi = 12, casse = 120, cadute = 999 })
check(#taken == 3 and taken[1].id == "a_segno" and taken[2].id == "casse" and taken[3].id == "globi",
	"badge: from the highest grade, same grade in list order; falls give no badge")
local m = milestones.shown({ a_segno = 150, globi = 12, casse = 120, vinte = 10 }, { "vinte", "danno" })
check(#m == milestones.SHOWN and m[1].id == "vinte" and m[2].id == "a_segno",
	"badge: the chosen ones first (if earned), then the highest, at most three")
check(milestones.valid({ id = "globi", grado = 2 }) and not milestones.valid({ id = "globi", grado = 5 })
	and not milestones.valid({ id = "cadute", grado = 1 }) and not milestones.valid({ id = "x", grado = 1 }),
	"badge: those arriving from outside are checked")

-- Profile: registra, stats, choose_badge ----------------------------------------
local p = profile.new()
local function play_match(cluster, won, values)
	return { gruppo = cluster, won = won, valori = values, armi = { missile = 100 },
		partita = { gruppo = cluster, esito = won and "V" or "S", punti = { 1, 0 }, giocatori = {}, moments = {} } }
end
for i = 1, 12 do profile.record(p, play_match(i % 2 == 0 and "2v2" or "1v1", i > 9, { a_segno = 3, colpo_lungo = i * 100 })) end
check(#p.partite == profile.MATCHES and p.partite[1].numero == 12 and p.partite[profile.MATCHES].numero == 3,
	"profile: the latest matches are kept, the newest on top")
local two = profile.statistics(p, "2v2")
check(two.partite == 6 and two.a_segno == 18 and two.colpo_lungo == 1200 and two.vinte == 2,
	"profile: stats add up per mode, the record is the max")
local all_f = profile.statistics(p, "tutte")
check(all_f.partite == 12 and all_f.a_segno == 36 and all_f.colpo_lungo == 1200 and all_f.armi.missile == 1200,
	"profile: TUTTE sums the modes (and the damage per weapon), the record stays the max")
check(p.serie == 3 and all_f.serie == 3, "profile: the win streak")
check(profile.replay_place(1) == 1 and profile.replay_place(11) == 1 and profile.replay_place(12) == 2,
	"profile: replay files are reused in rotation")
profile.choose_badge(p, "globi")
profile.choose_badge(p, "casse")
profile.choose_badge(p, "vinte")
profile.choose_badge(p, "danno")
check(#p.badge == 3 and p.badge[1] == "danno" and p.badge[3] == "casse", "profile: at most three badges are chosen, the last one in front")
check(profile.choose_badge(p, "danno") == false and p.badge[1] == "vinte", "profile: tapping a chosen badge removes it")

-- Showcase -------------------------------------------------------------------------
local q = profile.new()
local a = profile.active_loadout(q)
for _, s in ipairs(equip.SLOTS) do a.gear[s.id] = "corvo" end
q.pezzi["corvo_" .. equip.SLOTS[1].id] = 25
local v = showcase.from_profile(q, "Rosso", 1, "TU")
check(v.pezzi[1].livello == 25 and v.pezzi[1].tier == 3 and v.pezzi[2].livello == 1,
	"showcase: each piece with its level and the upgrade tier at 10, 20, 30")
check(#v.abilities >= 1 and v.abilities[1] == "doppio salto", "showcase: the full set gives its power")
local lines = showcase.rows(v)
check(#lines == 4 and lines[1].nome == "VITA", "showcase: four bars, health first")
local base = showcase.rows(showcase.simple("Blu", 2, "AVVERSARIO"))
check(base[2].valore == "=" and base[2].offset == 0, "showcase: without pieces the bars sit in the center")
local st = game.base_stats()
st.jump_height = st.jump_height * 1.06
local r6 = showcase.rows(showcase.with_stats(showcase.simple("Blu", 2, ""), st))
check(r6[2].valore == "+6%" and math.abs(r6[2].offset - 0.6) < 1e-6, "showcase: +6% and the offset in tenths of SCALE")
local net = showcase.from_net({ liv = 1e9, bdg = { { id = "globi", grado = 2 }, { id = "boh", grado = 1 }, "x" } }, "Blu", 2, "")
check(net.livello == 999 and #net.badge == 1 and net.badge[1].id == "globi", "showcase: the one arriving online is checked")
local pr = showcase.for_net(p)
check(pr.liv == p.livello and #(pr.bdg or {}) <= milestones.SHOWN, "showcase: level and badges go with the greeting")
check(showcase.for_net(profile.new()).bdg == nil, "showcase: no badges, no bdg (in JSON it would be an object)")

-- Count and replay on a real match: two bots, replayed the same ----------------
local r = replay.new(7, "pavimento", { players = { { team = 1, bot = "normale" }, { team = 2, bot = "normale" } } })
local g, bots = replay.match(r)
local c = count.new(g, 1, { "Rosso", "Blu" })
while g.phase ~= "over" and g.tick < 60 * 60 * 3 do
	local inp = replay.input(r, g, bots)
	if inp.fire and g.current == 1 then count.shot(c, g, inp.fire.weapon) end
	g:step(inp)
	replay.after(r, g)
	for _, e in ipairs(g:pop_events()) do count.event(c, g, e) end
	count.tick(c, g)
end
local end_of = count.finish(c, g, g:results(), { gruppo = "1v1", mappa = g.map, quando = 0, giocatori = {} })
check(end_of.valori.colpi > 0 and end_of.valori.a_segno <= end_of.valori.colpi, "count: shots and shots on target")
local weapon_damage = 0
for _, n in pairs(end_of.armi) do weapon_damage = weapon_damage + n end
check(weapon_damage <= end_of.valori.danno + 1 and weapon_damage >= end_of.valori.danno * 0.5,
	"count: the damage per weapon is within the standings damage (" .. weapon_damage .. " su " .. end_of.valori.danno .. ")")
check(#end_of.partita.fune >= 2 and end_of.partita.esito:match("^[VSP]$"), "count: the rope lap by lap and the outcome")
local ok, tick = replay.verify(r, g.tick)
check(ok, "replay: the match replayed from the recipe comes back the same" .. (ok and "" or (" (diverges at tick " .. tostring(tick) .. ")")))
-- the reader replays the keys as it recorded them: also a duration changed by hand
local r2 = replay.new(3, "pavimento", { players = { { team = 1 }, { team = 2, bot = "normale" } } })
local g2, b2 = replay.match(r2)
r2.durata = 600
g2.match_left = r2.durata
local moves = { [5] = { right = true }, [40] = { left = true }, [80] = { fire = { weapon = "missile", angle = 0.6, power = 0.7 } } }
while g2.phase ~= "over" and g2.tick < 900 do
	local inp = replay.input(r2, g2, b2, moves[g2.tick] or {})
	g2:step(inp)
	replay.after(r2, g2)
	g2:pop_events()
end
local g3, b3 = replay.match(r2)
check(g3.match_left == 600, "replay: the changed duration (in the scenarios) comes back in the replay too")
local l = replay.reader(r2)
while g3.tick < g2.tick and g3.phase ~= "over" do g3:step(replay.read_step(l, g3, b3)) end
check(g3:fingerprint() == g2:fingerprint(), "replay: replaying the keys reaches the same state")

if failures > 0 then
	print(failures .. " tests failed")
	os.exit(1)
end
print("all tests passed")
