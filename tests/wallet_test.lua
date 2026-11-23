-- Scaglie and Ossidiana (sim/wallet.lua): earnings, the pieces' levels, the
-- Proof of the steps and the Smith's hand. From the root:
--   luajit tests/wallet_test.lua
package.path = "client/?.lua;" .. package.path

local wallet = require "sim.wallet"
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
check(sum(win) == 10 + 5 + 15 + 5 + 6 + 40 and win[#win].key == "daily" and win[#win - 1].key == "award", "the first win of the day: all the rows and +40")
-- the Ossidiana rewards winning: an online win, the MVP, the first win of the day; none against bots
local _, won_ob = wallet.match(wallet.init({}), { points = 148, won = true, mvp = true }, "2026-11-10")
check(sum(won_ob, "ossidiana") == wallet.OBS_WIN + wallet.OBS_MVP + wallet.OBS_DAILY, "Ossidiana of a first win as MVP: 1 + 1 + 5")
check(#select(2, wallet.match(p, { points = 80, won = false }, "2026-11-10")) == 0
	and #select(2, wallet.match(wallet.init({}), { points = 80, won = true, mvp = true, bots = true }, "2026-11-10")) == 0,
	"no Ossidiana for a lost match, nor against bots")
local again = wallet.match(p, { points = 148, won = true }, "2026-11-10")
check(sum(again) == 30, "the second win of the day has no bonus")
check(sum((wallet.match(p, { points = 148, won = true }, "2026-11-11"))) == 70, "the next day the bonus comes back")
check(sum((wallet.match(p, { points = 1000, won = false, second = true }))) == 10 + 6 + 8, "points at most 6, the 2nd in free for all +8")
check(#wallet.match(p, { points = 200, won = true, quit = true }, "2026-11-12") == 0, "who quits gets nothing")
local bots = wallet.match(p, { points = 150, won = true, bots = true }, "2026-11-12")
check(sum(bots) == 5 + 3 + 8 and p.giorno == "2026-11-11", "against bots: half, and no first win of the day")
for _ = 2, wallet.BOTS_DAY do wallet.match(p, { points = 0, won = false, bots = true }, "2026-11-12") end
check(#wallet.match(p, { points = 150, won = true, bots = true }, "2026-11-12") == 0, "against bots only the first 10 of the day pay")
check(sum((wallet.match(p, { points = 0, won = false, bots = true }, "2026-11-13"))) == 5, "the next day bots pay again")
check(sum((wallet.mission(true, 2))) == 25 and sum((wallet.mission(false, 0, true))) == 8 and sum((wallet.mission(false, 1))) == 13,
	"missions: 15 the first time, 8 a replay with a new record, 5 per new star")
check(#wallet.mission(false, 0) == 0, "a replay that beats nothing pays nothing")
check(sum(select(2, wallet.mission(true, 2)), "ossidiana") == 2 * wallet.OBS_STAR and #select(2, wallet.mission(true, 0)) == 0,
	"Ossidiana: 2 for each new star")

local obs = wallet.obsidian({ a_segno = 9, vinte = 99 }, { a_segno = 120, vinte = 100 }, 9, 16)
check(sum(obs, "ossidiana") == 5 + 10 + 10 + 2 * 15, "Ossidiana: badge grades I and II, one more grade, two times 5 levels")
check(sum(wallet.obsidian({}, {}, 3, 4), "ossidiana") == 0, "no badge and no fifth level: no Ossidiana")

local sc, ob = wallet.apply(p, { { scaglie = 30 }, { ossidiana = 5 } })
check(sc == 30 and ob == 5 and p.ossidiana == 5, "apply adds to the balance")

-- The chapters --------------------------------
local q = wallet.init({ stelle = { a = { true }, b = { false } } })
local chapters = { { missioni = { { id = "a" } } }, { missioni = { { id = "a" }, { id = "b" } } } }
check(wallet.chapters_done(q, chapters) == 1, "chapters: done when every mission is")

-- Levels ----------------------------------------------------------------------------
p = wallet.init({})
p.scaglie = 10000
for _ = 2, 9 do wallet.upgrade(p, "corvo", "mask") end
check(wallet.level(p, "corvo", "mask") == 9 and p.scaglie == 10000 - 1180, "levels 2..9 cost 1,180")
local lv, why = wallet.upgrade(p, "corvo", "mask")
check(lv == nil and why == "proof", "the step 10 waits for the Proof")
p.no_proof = true
check(wallet.next(p, "corvo", "mask").proof == 0, "the \"da zero\" test profile has no Proof to play")
p.no_proof = nil
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
local n = wallet.next(p, "corvo", "chest")
check(n.cost == 40 and n.full_cost == 60, "the Smith's hand: the other Corvo pieces cost 30% less")
check(wallet.next(p, "vuoto", "mask").cost == 60, "only in the same family")
local whole = 0
for l = 2, equip.LIVELLO_MAX do whole = whole + equip.cost(l) end
check(whole == 63160 and equip.cost(10) + 1180 == 2530, "a piece at 30 costs 63,160 Scaglie, the first step 2,530")

-- Signatures: lit with Ossidiana, one grade per step of the piece ------------------
p = wallet.init({})
p.pezzi.corvo_mask = 9
check(wallet.sign(p, "corvo", "mask") == 0 and wallet.sign_next(p, "corvo", "mask").level == 10
	and select(2, wallet.light(p, "corvo", "mask")) == "level", "the signature waits for the step 10")
p.pezzi.corvo_mask = 12
check(select(2, wallet.light(p, "corvo", "mask")) == "ossidiana", "without Ossidiana it stays off")
p.ossidiana = 300
check(wallet.light(p, "corvo", "mask") == 1 and p.ossidiana == 300 - equip.SIGN_COSTS[1] and wallet.sign(p, "corvo", "mask") == 1,
	"lit for 240 Ossidiana")
check(wallet.sign_next(p, "corvo", "mask").grade == 2 and wallet.sign_next(p, "corvo", "mask").level == 20, "the next grade waits for the step 20")
p.pezzi.corvo_mask, p.firme.corvo_mask = 30, 3
check(wallet.sign_next(p, "corvo", "mask") == nil and select(2, wallet.light(p, "corvo", "mask")) == "max", "full: nothing more")
check(wallet.signs(p, { gear = { mask = "corvo", chest = "fornace" } }).mask == 3
	and wallet.signs(p, { gear = { mask = "corvo", chest = "fornace" } }).chest == 0, "the signatures of the pieces worn")
check(equip.piece("corvo", "mask", 30, 0)[5].good == 0 and equip.piece("corvo", "mask", 30, 1)[5].good == equip.SIGNS.sig_high.max / 2
	and equip.piece("corvo", "mask", 30)[5].good == equip.SIGNS.sig_high.max, "a signature is worth what is lit; the bots' follow the level")
-- old saves: the signatures that were lit by the steps stay lit
local old = wallet.init({ pezzi = { corvo_mask = 21, vuoto_chest = 5 } })
check(wallet.sign(old, "corvo", "mask") == 2 and wallet.sign(old, "vuoto", "chest") == 0, "old saves keep the signatures they had")

-- The shop and the gifts (page "I Pezzi della Forgia", choices 22A-25A) --------------
p = wallet.init({})
check(not wallet.owns(p, "fabbro", "legs") and p.buoni == 0, "a new player owns nothing")
local today = wallet.shop(p, "2026-11-11")
local four = 0
for _, s in ipairs(equip.SLOTS) do if today[s.id] then four = four + 1 end end
check(four == #equip.SLOTS, "the BOTTEGA: a piece of the day per slot")
local same = wallet.shop(p, "2026-11-11")
check(same.mask == today.mask and same.legs == today.legs, "the same pieces all day")
local differ = false
for d = 12, 20 do differ = differ or wallet.shop(p, "2026-11-" .. d).mask ~= today.mask end
check(differ, "other days, other pieces")
check(select(2, wallet.buy(p, today.mask, "mask", "2026-11-11")) == "scaglie", "without Scaglie nothing is bought")
p.scaglie = 20000
check(wallet.buy(p, today.mask, "mask", "2026-11-11") and wallet.owns(p, today.mask, "mask") and p.scaglie == 15200,
	"bought in the BOTTEGA for 4,800")
check(wallet.shop(p, "2026-11-11").mask ~= today.mask, "a piece owned leaves the BOTTEGA")
local other
for _, f in ipairs(equip.SETS) do
	if not other and not wallet.owns(p, f.id, "mask") and wallet.shop(p, "2026-11-11").mask ~= f.id then other = f.id end
end
check(select(2, wallet.buy(p, other, "mask", "2026-11-11")) == "shop", "the BOTTEGA sells only the pieces of the day")
check(wallet.buy(p, other, "mask") and p.scaglie == 8000, "a piece of the catalogue costs 7,200")
check(select(2, wallet.buy(p, other, "mask")) == "owned", "a piece is bought once")
p.pezzi[other .. "_mask"] = equip.LIVELLO_MAX
local third
for _, f in ipairs(equip.SETS) do if not third and f.id ~= other then third = f.id end end
check(wallet.price(p, other, "chest", true) == 3360 and wallet.price(p, other, "gloves") == 5040
	and wallet.price(p, third, "mask") == 7200, "the Smith's hand lowers the prices of that family")
check(select(2, wallet.use_voucher(p, "fornace", "chest")) == "voucher", "no voucher, no free piece")
-- gifts: once each
p.stelle = { il_fabbro = { true } }
local rows = wallet.gifts(p, {}, 1)
check(#rows == 1 and rows[1].key == "piece" and wallet.owns(p, "fabbro", "legs"), "Forge 6, the Smith beaten: his boots")
check(#wallet.gifts(p, {}, 1) == 0, "a gift comes once")
p.stelle.battaglia_forgia = { true }
rows = wallet.gifts(p, {}, 1)
check(#rows == 1 and rows[1].key == "voucher" and p.buoni == 1, "the Battle of the Forge: the Smith's voucher")
p.buoni = 0
-- a save from before 23 Nov: the Battle gave the boots, now it gives the voucher (once), no boots row
local old = wallet.init({})
old.posseduti.fabbro_legs, old.regali.missione_battaglia_forgia = true, true
old.stelle = { il_fabbro = { true }, battaglia_forgia = { true } }
rows = wallet.gifts(old, {}, 1)
check(#rows == 1 and rows[1].key == "voucher" and old.buoni == 1, "old saves: the voucher, not the boots again")
check(#wallet.gifts(p, { a_segno = 10000 }, 49) == 0 and p.buoni == 0, "no voucher for a badge nor before level 50")
check(#wallet.gifts(p, { a_segno = 10000 }, 50) == 1 and p.buoni == 1, "level 50: a voucher")
check(wallet.use_voucher(p, "fornace", "chest") and wallet.owns(p, "fornace", "chest") and p.buoni == 0, "a voucher: a piece of your choice")
-- before the shop: the levelled pieces stay, the others come off
local m = wallet.init({ pezzi = { corvo_mask = 5, vuoto_chest = 1 } })
local lo = { { gear = { mask = "corvo", chest = "vuoto", legs = "drago" } } }
wallet.migrate(m, lo)
check(wallet.owns(m, "corvo", "mask") and not wallet.owns(m, "vuoto", "chest") and lo[1].gear.mask == "corvo"
	and lo[1].gear.chest == nil and lo[1].gear.legs == nil, "old saves: levelled pieces stay, the others come off")

if failures > 0 then
	print(failures .. " FAIL")
	os.exit(1)
end
print("all ok")
