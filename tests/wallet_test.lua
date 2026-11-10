-- Scaglie and Ossidiana (menu/wallet.lua): earnings, the pieces' levels, the
-- Proof of the steps and the Smith's hand. From the root:
--   luajit tests/wallet_test.lua
package.path = "client/?.lua;" .. package.path

local wallet = require "menu.wallet"
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

local function sum(rows, field)
	local n = 0
	for _, r in ipairs(rows) do n = n + (r[field or "scaglie"] or 0) end
	return n
end

-- Earnings ------------------------------------------------------------------------
local p = wallet.init({})
check(p.scaglie == 0 and p.ossidiana == 0 and wallet.level(p, "corvo", "mask") == 1, "a new wallet is empty, pieces at 1")
local lost = wallet.match(p, { points = 80, won = false }, "2026-11-10")
check(sum(lost) == 13, "a lost match with 80 points: 10 + 3")
local win = wallet.match(p, { points = 148, won = true, mvp = true, awards = { {}, {}, {} } }, "2026-11-10")
check(sum(win) == 10 + 5 + 15 + 5 + 6 + 40 and win[#win].key == "daily", "the first win of the day: all the rows and +40")
local again = wallet.match(p, { points = 148, won = true }, "2026-11-10")
check(sum(again) == 30, "the second win of the day has no bonus")
check(sum(wallet.match(p, { points = 148, won = true }, "2026-11-11")) == 70, "the next day the bonus comes back")
check(sum(wallet.match(p, { points = 1000, won = false, second = true })) == 10 + 6 + 8, "points at most 6, the 2nd in free for all +8")
check(#wallet.match(p, { points = 200, won = true, quit = true }, "2026-11-12") == 0, "who quits gets nothing")
local bots = wallet.match(p, { points = 150, won = true, bots = true }, "2026-11-12")
check(sum(bots) == 5 + 3 + 8 and p.giorno == "2026-11-11", "against bots: half, and no first win of the day")
for _ = 2, wallet.BOTS_DAY do wallet.match(p, { points = 0, won = false, bots = true }, "2026-11-12") end
check(#wallet.match(p, { points = 150, won = true, bots = true }, "2026-11-12") == 0, "against bots only the first 10 of the day pay")
check(sum(wallet.match(p, { points = 0, won = false, bots = true }, "2026-11-13")) == 5, "the next day bots pay again")
check(sum(wallet.mission(true, 2)) == 25 and sum(wallet.mission(false, 0)) == 8 and sum(wallet.mission(false, 1)) == 13,
	"missions: 15 the first time, 8 a replay, 5 per new star")

local obs = wallet.obsidian({ a_segno = 9, vinte = 99 }, { a_segno = 120, vinte = 100 }, 9, 16)
check(sum(obs, "ossidiana") == 5 + 10 + 10 + 2 * 15, "Ossidiana: badge grades I and II, one more grade, two times 5 levels")
check(sum(wallet.obsidian({}, {}, 3, 4), "ossidiana") == 0, "no badge and no fifth level: no Ossidiana")

local sc, ob = wallet.apply(p, { { scaglie = 30 }, { ossidiana = 5 } })
check(sc == 30 and ob == 5 and p.ossidiana == 5, "apply adds to the balance")

-- The match seen from this phone, and the chapters --------------------------------
local res = { mode = "2v2", winner = 2, ranking = { { robot = 3, team = 2, place = 1, points = 90 },
	{ robot = 4, team = 2, place = 1, points = 40 }, { robot = 1, team = 1, place = 2, points = 150 },
	{ robot = 2, team = 1, place = 2, points = 10 } } }
local r1 = wallet.result(res, 1, { {} }, true)
check(r1.won == false and r1.mvp and r1.points == 150 and not r1.bots, "result: lost, but the MVP of the match")
local r3 = wallet.result(res, 3, {}, false)
check(r3.won == true and not r3.mvp and r3.bots, "result: won, not the MVP, against bots")
res.winner = nil
check(wallet.result(res, 3, {}, true).won == nil, "result: a tie is neither won nor lost")
local ffa = { mode = "ffa", winner = 1, ranking = { { robot = 2, team = 1, place = 1, points = 50 }, { robot = 1, team = 2, place = 2, points = 30 } } }
check(wallet.result(ffa, 1, {}, true).second, "result: 2nd in free for all")
local q = wallet.init({ stelle = { a = { true }, b = { false } } })
local chapters = { { missioni = { { id = "a" } } }, { missioni = { { id = "a" }, { id = "b" } } } }
check(wallet.chapters_done(q, chapters) == 1, "chapters: done when every mission is")

-- Levels ----------------------------------------------------------------------------
p = wallet.init({})
p.scaglie = 10000
for _ = 2, 9 do wallet.upgrade(p, "corvo", "mask") end
check(wallet.level(p, "corvo", "mask") == 9 and p.scaglie == 10000 - 260, "levels 2..9 cost 260")
local lv, why = wallet.upgrade(p, "corvo", "mask")
check(lv == nil and why == "proof", "the step 10 waits for the Proof")
local a = { gear = { mask = "corvo", chest = "fornace" } }
for _ = 1, 3 do wallet.wear(p, a) end
check(wallet.next(p, "corvo", "mask").proof_done == 3 and p.prova.fornace_chest == nil,
	"the Proof counts only the pieces one level below a step")
check(wallet.upgrade(p, "corvo", "mask") == 10 and p.prova.corvo_mask == nil, "with the Proof the step is bought")
check(wallet.tiers(p, a).mask == 2 and wallet.tiers(p, a).chest == 1, "tiers from the levels")
p.scaglie = 0
check(select(2, wallet.upgrade(p, "corvo", "mask")) == "scaglie", "without Scaglie nothing is bought")
p.pezzi.corvo_mask = equip.LIVELLO_MAX
check(select(2, wallet.upgrade(p, "corvo", "mask")) == "max", "at 30 there is nothing more")
local n = wallet.next(p, "vuoto", "mask")
check(n.cost == 10 and n.full_cost == 15, "the Smith's hand: other helmets cost 30% less")
check(wallet.next(p, "vuoto", "chest").cost == 15, "only in the same slot")

if failures > 0 then
	print(failures .. " FAIL")
	os.exit(1)
end
print("all ok")
