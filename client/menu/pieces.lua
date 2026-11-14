-- The pieces of the armory (page "I Pezzi della Forgia", choices 21A-25A):
-- three tabs on the same frame.
--   ARMADIO: the four pieces worn as cards, the chosen one with its 30 levels,
--     the Proof, its plus and minus, its family's bonus, the owned pieces of
--     that slot to wear; the screen's action is POTENZIA in Scaglie.
--   BOTTEGA: four pieces of the day, one per slot, among those you don't own;
--     the action is COMPRA.
--   CATALOGO: every piece of every family, always, for more; the Smith's
--     vouchers take one for free.
-- Pure layout with ui/kit.lua, so the screen that hosts it (menu/armory.lua)
-- keeps its frame and stats. Rebuilt at every tap.
--
--   local pieces = require "menu.pieces"
--   pieces.build(s)  -- s = { prof, buttons, kg (the kit group), right (the action's anchor), slot = "mask" }
--   pieces.run(s, kind, arg) -> handled, step  -- step: { slot, set, level } when a step was bought
--
-- Actions on the buttons: "banco:armadio|bottega|catalogo", "pezzo:<slot>",
-- "indossa:<set>", "potenzia", "merce:<set>_<slot>", "compra", "buono".

local ui = require "ui.ui"
local kit = require "ui.kit"
local coins = require "ui.coins"
local equip = require "sim.gear"
local profile = require "menu.profile"
local wallet = require "menu.wallet"
local T = require("lang.text").pieces
local TA = require("lang.text").armory

local M = {}

local KC = kit.C
local ROMAN = { "I", "II", "III", "IV" }
-- where the tabs' content starts
local TOP = 176

local function active(s) return profile.active_loadout(s.prof) end

local function slot_of(id)
	for _, sl in ipairs(equip.SLOTS) do if sl.id == id then return sl end end
	return equip.SLOTS[1]
end

-- a level's grade color: bronze, silver, gold, ember
local function grade_color(level)
	return ui.C.GRADI[equip.tier(level)]
end

-- "+10 attacco, +2,4% salto, -8% corsa": what the piece really does to the
-- stat (the stats where less is better go down with a plus; life, Attack
-- and Defense in points)
local function effect(e)
	local info = equip.STATS[e.stat]
	local name = string.lower(TA.stats[e.stat] or e.stat)
	if info.points then return string.format("%+d %s", math.floor(e.good * 100 + 0.5), name) end
	local v = (info.less and -e.good or e.good) * 100
	local t = string.format("%+.1f%%", v):gsub("%.0%%", "%%"):gsub("%.", ",")
	return t .. " " .. name
end

-- the rows of a piece but its signature, in one line
local function effects(list_of)
	local t = {}
	for _, e in ipairs(list_of) do
		if e.row ~= "sign" then t[#t + 1] = effect(e) end
	end
	return table.concat(t, ", ")
end

-- the signature of a piece: its name and what it does now (or, below the
-- step 10, what it will do there)
local function sign_text(list_of)
	for _, e in ipairs(list_of) do
		if e.row == "sign" then
			local sg = equip.SIGNS[e.stat]
			local on = e.good > 0
			local what = sg.desc:format(math.floor((on and e.good or sg.max * equip.SIGN_TIERS[2]) * 100 + 0.5))
			return (on and T.sign or T.sign_off):format(sg.name, what)
		end
	end
	return ""
end

-- The placeholder of a piece until it is drawn (equip.SETS[].art): a round
-- iron with the slot's letter in the family's color
local function emblem(g, set, slot, cx, cy, d)
	local f = equip.BY_ID[set]
	kit.piece(g, "tondo_ferro", cx, cy, d)
	kit.text(g, string.sub(slot_of(slot).name, 1, 1), cx, cy + d * 0.18, d * 0.5, kit.hex(f.color), "middle")
end

-- a family's pair bonus, written like the pieces' effects
local function pair_text(f)
	return effect({ stat = f.pair.stat, good = f.pair.share })
end

-- the piece's name: "ELMO · CORVO"
local function piece_name(set, slot)
	return T.piece:format(slot_of(slot).name, equip.BY_ID[set].name)
end

-- ARMADIO ----------------------------------------------------------------------

-- the four pieces worn: one card each, staggered; the chosen one lit
local function slots(s)
	local a = active(s)
	for i, slot in ipairs(equip.SLOTS) do
		local x, y = 440 + (i - 1) * 8, TOP + (i - 1) * 105
		local set = a.gear[slot.id]
		local level = set and wallet.level(s.prof, set, slot.id)
		local full = level == equip.LIVELLO_MAX
		local k = kit.card(s.kg, x, y, 250, 94, full and KC.STAR or KC.ROSE, { sel = s.slot == slot.id })
		kit.text(k.g, slot.name, x + 26, y + 32, 15, KC.MUTE, "start", 1.5)
		local nm = kit.text(k.g, set and equip.BY_ID[set].name or kit.upper(T.empty), x + 24, y + 68, 27, set and KC.SAND or KC.MUTE)
		if set then
			local wide = kit.width(nm)
			if wide > 120 then gui.set_scale(nm, gui.get_scale(nm) * (120 / wide)) end
			emblem(k.g, set, slot.id, x + 170, y + 47, 44)
			kit.text(k.g, tostring(level), x + 230, y + 58, 30, full and KC.STAR or KC.SAND, "end")
		end
		kit.zone(s.kg, s.buttons, x, y - 5, 250, 105, "pezzo:" .. slot.id)
	end
end

-- the chosen piece: name, level, effects, the 30 notches, the next level
local function detail(s)
	local g = s.kg
	local a = active(s)
	local slot = slot_of(s.slot)
	local set = a.gear[slot.id]
	local act = { label = T.upgrade, off = true }
	if not set then
		kit.text(g, slot.name, 730, TOP + 34, 36, KC.MUTE)
		kit.text(g, kit.upper(T.choose:format(slot.name)), 732, TOP + 62, 15, KC.MUTE, "start", 1.2)
		act.sub = kit.upper(T.empty)
		return act
	end
	local level = wallet.level(s.prof, set, slot.id)
	local name = kit.text(g, piece_name(set, slot.id), 730, TOP + 34, 36, KC.SAND)
	-- a long name shrinks
	local wide = kit.width(name)
	if wide > 290 then gui.set_scale(name, gui.get_scale(name) * (290 / wide)) end
	kit.text(g, kit.upper(T.grade:format(ROMAN[equip.tier(level)], T.grades[equip.tier(level)])), 732, TOP + 60, 14, KC.MUTE, "start", 0.5)
	-- the rows: main, secondaries, minus
	local rows = kit.text(g, kit.upper(effects(equip.piece(set, slot.id, level))), 732, TOP + 114, 15, KC.SAND, "start", 0.5)
	wide = kit.width(rows)
	if wide > 290 then gui.set_scale(rows, gui.get_scale(rows) * (290 / wide)) end
	-- the levels: one bar, and the number beside it
	kit.bar(g, 734, TOP + 78, 200, 14, level / equip.LIVELLO_MAX, grade_color(level))
	kit.text(g, T.of_max:format(level, equip.LIVELLO_MAX), 1020, TOP + 93, 20, grade_color(level), "end")

	-- the next level: what it is, the Proof if it is a step, the price on the action
	local n = wallet.next(s.prof, set, slot.id)
	if not n then
		kit.text(g, T.at_max, 732, TOP + 144, 15, KC.HOT_TOP, "start", 1.2)
		act.sub = T.at_max
	else
		local step = n.proof > 0
		kit.text(g, kit.upper(step and T.next_step:format(n.level, ROMAN[equip.tier(n.level)], T.grades[equip.tier(n.level)])
			or T.next_level:format(n.level)), 732, TOP + 144, 15, step and KC.HOT_TOP or KC.MUTE, "start", 1)
		local ready = n.proof_done >= n.proof
		local enough = s.prof.scaglie >= n.cost
		if step then
			kit.text(g, T.proof_name, 732, TOP + 166, 14, KC.MUTE, "start", 1.5)
			kit.text(g, kit.upper(T.proof:format(n.proof_done, n.proof)), 732, TOP + 184, 14, KC.SAND, "start", 0.5)
			kit.bar(g, 900, TOP + 155, 110, 10, math.min(1, n.proof_done / n.proof), KC.MINT)
		elseif n.cost < n.full_cost then
			kit.text(g, T.smith_name, 732, TOP + 166, 14, KC.MUTE, "start", 1.5)
			kit.text(g, kit.upper(T.smith_hand:format(coins.format(n.full_cost))), 732, TOP + 184, 14, KC.SAND, "start", 0.5)
		end
		act.off = not (ready and enough)
		act.sub = not ready and kit.upper(T.proof_first) or not enough and kit.upper(T.missing:format(coins.format(n.cost - s.prof.scaglie)))
			or T.price:format(coins.format(n.cost), n.level)
	end

	-- the family: two gold pieces give its bonus, four its style (next update)
	local f = equip.BY_ID[set]
	local on = false
	for _, id in ipairs(equip.pairs_on(a.gear, wallet.levels(s.prof, a))) do on = on or id == set end
	local fam = kit.text(g, kit.upper(T.family:format(f.name, pair_text(f))), 732, TOP + 208, 14, on and KC.MINT or KC.MUTE, "start", 0.5)
	wide = kit.width(fam)
	if wide > 290 then gui.set_scale(fam, gui.get_scale(fam) * (290 / wide)) end
	local sig = kit.text(g, kit.upper(sign_text(equip.piece(set, slot.id, level))), 732, TOP + 230, 14,
		equip.tier(level) > 1 and KC.HOT_TOP or KC.MUTE, "start", 0.5)
	wide = kit.width(sig)
	if wide > 290 then gui.set_scale(sig, gui.get_scale(sig) * (290 / wide)) end
	return act
end

-- the owned pieces for the chosen slot: tap to wear (tap again: take off)
local function wardrobe(s)
	local g = s.kg
	local a = active(s)
	kit.text(g, T.others, 732, TOP + 262, 15, KC.MUTE, "start", 1.5)
	local i = 0
	for _, set in ipairs(equip.SETS) do
		if wallet.owns(s.prof, set.id, s.slot) then
			i = i + 1
			local col, line = (i - 1) % 2, math.floor((i - 1) / 2)
			local x, y = 726 + col * 152, TOP + 274 + line * 50
			local level = wallet.level(s.prof, set.id, s.slot)
			local on = a.gear[s.slot] == set.id
			if on then kit.light(g, x, y, 138, 40, 0) end
			kit.text(g, T.set_level:format(set.name, level), x + 73, y + 29, 16, on and KC.INK or kit.with_alpha(KC.SAND, 0.85), "middle")
			kit.zone(g, s.buttons, x, y - 4, 150, 50, "indossa:" .. set.id)
		end
	end
	if i == 0 then kit.text(g, kit.upper(T.none_owned), 732, TOP + 292, 14, KC.HOT_TOP, "start", 1) end
end

-- BOTTEGA and CATALOGO -----------------------------------------------------------

-- the chosen ware's line: its effects at level 1, and how to take it
local function ware_info(s, y)
	local g = s.kg
	local w = s.ware
	if not w then
		kit.text(g, kit.upper(T.pick_ware), 444, y + 24, 15, KC.MUTE, "start", 1.2)
		return
	end
	kit.text(g, piece_name(w.set, w.slot), 444, y + 24, 22, KC.SAND)
	local rows = equip.piece(w.set, w.slot, 1)
	local line = kit.text(g, kit.upper(T.at_level_1:format(effects(rows))), 444, y + 46, 14, KC.MUTE, "start", 0.5)
	local wide = kit.width(line)
	if wide > 540 then gui.set_scale(line, gui.get_scale(line) * (540 / wide)) end
	local sig = kit.text(g, kit.upper(sign_text(rows)), 444, y + 64, 13, KC.HOT_TOP, "start", 0.5)
	wide = kit.width(sig)
	if wide > 540 then gui.set_scale(sig, gui.get_scale(sig) * (540 / wide)) end
end

-- the Smith's vouchers: how many, and (in the CATALOGO, a ware chosen and not
-- owned) the button that uses one
local function vouchers(s, y, usable)
	local g = s.kg
	local n = s.prof.buoni or 0
	if n <= 0 then return end
	local x = 440
	kit.text(g, kit.upper(T.vouchers:format(n) .. (usable and "" or T.voucher_hint)), x + 4, y + 30, 14, KC.STAR, "start", 1)
	if usable then
		kit.light(g, x + 360, y, 190, 46, 0)
		kit.text(g, T.use_voucher, x + 455, y + 31, 18, KC.INK, "middle")
		kit.zone(g, s.buttons, x + 354, y - 4, 202, 54, "buono")
	end
end

local function shop(s)
	local g = s.kg
	local today = wallet.today()
	local wares = wallet.shop(s.prof, today)
	for i, slot in ipairs(equip.SLOTS) do
		local col, line = (i - 1) % 2, math.floor((i - 1) / 2)
		local x, y = 440 + col * 290, TOP + line * 134
		local set = wares[slot.id]
		local sel = s.ware and set and s.ware.set == set and s.ware.slot == slot.id
		local k = kit.card(s.kg, x, y, 276, 122, set and KC.ROSE or KC.LINE, { sel = sel, off = not set })
		kit.text(k.g, slot.name, x + 24, y + 32, 15, KC.MUTE, "start", 1.5)
		if set then
			kit.text(k.g, equip.BY_ID[set].name, x + 22, y + 68, 30, KC.SAND)
			emblem(k.g, set, slot.id, x + 236, y + 40, 52)
			local price = wallet.price(s.prof, slot.id, true)
			kit.text(k.g, kit.upper(T.price_only:format(coins.format(price))), x + 24, y + 100, 16,
				price < wallet.PRICE_SHOP and KC.MINT or KC.SAND, "start", 1)
			kit.zone(s.kg, s.buttons, x, y - 6, 276, 134, "merce:" .. set .. "_" .. slot.id)
		else
			kit.text(k.g, kit.upper(T.all_owned), x + 24, y + 68, 16, KC.MUTE, "start", 1)
		end
	end
	kit.text(g, kit.upper(T.shop_today), 444, TOP + 282, 13, KC.MUTE, "start", 1)
	ware_info(s, TOP + 296)
	vouchers(s, TOP + 362, false)
end

local function catalog(s)
	local g = s.kg
	for r, f in ipairs(equip.SETS) do
		for c, slot in ipairs(equip.SLOTS) do
			local x, y = 440 + (c - 1) * 146, TOP + (r - 1) * 58
			local own = wallet.owns(s.prof, f.id, slot.id)
			local sel = s.ware and s.ware.set == f.id and s.ware.slot == slot.id
			if sel then kit.light(g, x, y, 134, 52, 0) end
			local ink = sel and KC.INK or own and KC.MINT or KC.SAND
			kit.text(g, f.name, x + 16, y + 26, 18, ink)
			kit.text(g, own and T.owned:format(slot.name, wallet.level(s.prof, f.id, slot.id)) or slot.name,
				x + 16, y + 44, 12, sel and KC.INK or KC.MUTE, "start", 0.5)
			kit.zone(g, s.buttons, x, y - 3, 146, 58, "merce:" .. f.id .. "_" .. slot.id)
		end
	end
	ware_info(s, TOP + 296)
	local w = s.ware
	vouchers(s, TOP + 362, w and not wallet.owns(s.prof, w.set, w.slot))
end

-- the action of the shop's tabs: COMPRA with the price, or what is missing
local function buy_action(s)
	local w = s.ware
	local act = { label = T.buy, off = true }
	if not w then
		act.sub = kit.upper(T.pick_ware)
		return act
	end
	if wallet.owns(s.prof, w.set, w.slot) then
		act.sub = kit.upper(T.in_wardrobe)
		return act
	end
	local price = wallet.price(s.prof, w.slot, s.tab == "bottega")
	act.off = s.prof.scaglie < price
	act.sub = act.off and kit.upper(T.missing:format(coins.format(price - s.prof.scaglie)))
		or T.price_only:format(coins.format(price))
	return act
end

function M.build(s)
	s.slot = s.slot or equip.SLOTS[1].id
	s.tab = s.tab or "armadio"
	local tabs = { { T.tab_wardrobe, "banco:armadio" }, { T.tab_shop, "banco:bottega" }, { T.tab_catalog, "banco:catalogo" } }
	local on = s.tab == "bottega" and 2 or s.tab == "catalogo" and 3 or 1
	kit.tabs(s.kg, s.buttons, 440, 100, tabs, on, KC.PURPLE)
	local act
	if s.tab == "armadio" then
		slots(s)
		act = detail(s)
		wardrobe(s)
	else
		if s.tab == "bottega" then shop(s) else catalog(s) end
		act = buy_action(s)
	end
	-- the one action: POTENZIA or COMPRA, with the price under it (or what is missing)
	local verb = s.tab == "armadio" and "potenzia" or "compra"
	s.action = kit.action(s.right, act.label, 930, 560, 270, 84, { size = 44, off = act.off, sub = act.sub })
	kit.button(s.buttons, s.action, verb, { main = true, spento = act.off })
end

-- a piece just taken goes on at once if its slot is empty
local function wear_new(s, set, slot)
	local a = active(s)
	if not a.gear[slot] then a.gear[slot] = set end
end

function M.run(s, kind, arg)
	local a = active(s)
	if kind == "banco" then
		s.tab, s.ware = arg, nil
	elseif kind == "pezzo" then
		s.slot = arg
	elseif kind == "indossa" then
		if wallet.owns(s.prof, arg, s.slot) then a.gear[s.slot] = a.gear[s.slot] ~= arg and arg or nil end
	elseif kind == "merce" then
		local set, slot = arg:match("^(%a+)_(%a+)$")
		if set and equip.BY_ID[set] then s.ware = { set = set, slot = slot } end
	elseif kind == "compra" then
		local w = s.ware
		if w and wallet.buy(s.prof, w.set, w.slot, s.tab == "bottega" and wallet.today() or nil) then
			wear_new(s, w.set, w.slot)
			s.slot, s.tab, s.ware = w.slot, "armadio", nil
			return true, nil, true
		end
	elseif kind == "buono" then
		local w = s.ware
		if w and wallet.use_voucher(s.prof, w.set, w.slot) then
			wear_new(s, w.set, w.slot)
			s.slot, s.tab, s.ware = w.slot, "armadio", nil
			return true, nil, true
		end
	elseif kind == "potenzia" then
		local set = a.gear[s.slot]
		local level = set and wallet.upgrade(s.prof, set, s.slot)
		if level and equip.PROOF[level] then
			return true, { slot = s.slot, set = set, level = level }
		end
	else
		return false
	end
	return true
end

return M
