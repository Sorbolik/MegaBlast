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
local TOP = 164

local function active(s) return profile.active_loadout(s.prof) end

local function slot_of(id)
	for _, sl in ipairs(equip.SLOTS) do if sl.id == id then return sl end end
	return equip.SLOTS[1]
end

-- a level's grade color: bronze, silver, gold, ember
local function grade_color(level)
	return ui.C.GRADI[equip.tier(level)]
end

-- "+2,4% salto, -2% corsa": what the piece really does to the stat (the
-- stats where less is better go down with a plus)
local function effect(e)
	local info = equip.STATS[e.stat]
	local name = string.lower(TA.stats[e.stat] or e.stat)
	if info.hp then return string.format("%+d %s", e.good, name) end
	local v = (info.less and -e.good or e.good) * 100
	local t = string.format("%+.1f%%", v):gsub("%.0%%", "%%"):gsub("%.", ",")
	return t .. " " .. name
end

local function effects(list_of)
	local t = {}
	for _, e in ipairs(list_of) do t[#t + 1] = effect(e) end
	return table.concat(t, ", ")
end

-- a family's pair bonus, written like the pieces' effects
local function pair_text(f)
	return effect({ stat = f.pair.stat, good = f.pair.hp or f.pair.pct })
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
		local x, y = 440 + (i - 1) * 10, TOP + (i - 1) * 76
		local set = a.gear[slot.id]
		local level = set and wallet.level(s.prof, set, slot.id)
		local full = level == equip.LIVELLO_MAX
		local k = kit.card(s.kg, x, y, 220, 64, full and KC.STAR or KC.ROSE, { sel = s.slot == slot.id })
		kit.text(k.g, slot.name, x + 30, y + 22, 12, KC.MUTE, "start", 1.5)
		kit.text(k.g, set and equip.BY_ID[set].name or kit.upper(T.empty), x + 26, y + 50, 22, set and KC.SAND or KC.MUTE)
		if set then kit.text(k.g, tostring(level), x + 206, y + 42, 24, full and KC.STAR or KC.SAND, "end") end
		kit.zone(s.kg, s.buttons, x, y - 6, 220, 76, "pezzo:" .. slot.id)
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
		kit.text(g, slot.name, 716, TOP + 26, 34, KC.MUTE)
		kit.text(g, kit.upper(T.choose:format(slot.name)), 718, TOP + 50, 12, KC.MUTE, "start", 1.2)
		act.sub = kit.upper(T.empty)
		return act
	end
	local level = wallet.level(s.prof, set, slot.id)
	local name = kit.text(g, piece_name(set, slot.id), 716, TOP + 26, 32, KC.SAND)
	-- a long name shrinks
	local wide = kit.width(name)
	if wide > 268 then gui.set_scale(name, gui.get_scale(name) * (268 / wide)) end
	kit.text(g, kit.upper(T.grade:format(ROMAN[equip.tier(level)], T.grades[equip.tier(level)],
		effects(equip.piece(set, slot.id, level)))), 718, TOP + 50, 11, KC.MUTE, "start", 1)
	for l = 1, equip.LIVELLO_MAX do
		local big = equip.PROOF[l] ~= nil
		kit.para(g, 716 + (l - 1) * 7.6, TOP + (big and 62 or 66), 5, big and 24 or 16, 3, l <= level and grade_color(level) or KC.TRACK)
	end
	kit.text(g, T.of_max:format(level, equip.LIVELLO_MAX), 950, TOP + 82, 15, grade_color(level))

	-- the next level: what it is, the Proof if it is a step, the price on the action
	local n = wallet.next(s.prof, set, slot.id)
	if not n then
		kit.text(g, T.at_max, 718, TOP + 108, 12, KC.HOT_TOP, "start", 1.2)
		act.sub = T.at_max
	else
		local step = n.proof > 0
		kit.text(g, kit.upper(step and T.next_step:format(n.level, ROMAN[equip.tier(n.level)], T.grades[equip.tier(n.level)])
			or T.next_level:format(n.level)), 718, TOP + 108, 12, step and KC.HOT_TOP or KC.MUTE, "start", 1.2)
		local ready = n.proof_done >= n.proof
		local enough = s.prof.scaglie >= n.cost
		if step then
			kit.info(g, 716, TOP + 120, 270, 50, KC.PURPLE)
			kit.text(g, T.proof_name, 740, TOP + 140, 12, KC.MUTE, "start", 1.5)
			kit.text(g, kit.upper(T.proof:format(n.proof_done, n.proof)), 738, TOP + 160, 11, KC.SAND, "start", 0.5)
			kit.bar(g, 880, TOP + 132, 90, 8, math.min(1, n.proof_done / n.proof), KC.MINT)
		elseif n.cost < n.full_cost then
			kit.info(g, 716, TOP + 120, 270, 50, KC.HOT)
			kit.text(g, T.smith_name, 740, TOP + 140, 12, KC.MUTE, "start", 1.5)
			kit.text(g, kit.upper(T.smith_hand:format(coins.format(n.full_cost))), 738, TOP + 160, 11, KC.SAND, "start", 0.5)
		end
		act.off = not (ready and enough)
		act.sub = not ready and kit.upper(T.proof_first) or not enough and kit.upper(T.missing:format(coins.format(n.cost - s.prof.scaglie)))
			or T.price:format(coins.format(n.cost), n.level)
	end

	-- the family: two gold pieces give its bonus, four its style (next update)
	local f = equip.BY_ID[set]
	local on = false
	for _, id in ipairs(equip.pairs_on(a.gear, wallet.levels(s.prof, a))) do on = on or id == set end
	kit.text(g, kit.upper(T.family:format(f.name, pair_text(f))), 718, TOP + 194, 11, on and KC.MINT or KC.MUTE, "start", 1)
	kit.text(g, kit.upper(T.style_soon), 718, TOP + 212, 11, KC.MUTE, "start", 1)
	return act
end

-- the owned pieces for the chosen slot: tap to wear (tap again: take off)
local function wardrobe(s)
	local g = s.kg
	local a = active(s)
	kit.text(g, T.others, 718, TOP + 244, 12, KC.MUTE, "start", 1.5)
	local i = 0
	for _, set in ipairs(equip.SETS) do
		if wallet.owns(s.prof, set.id, s.slot) then
			i = i + 1
			local col, line = (i - 1) % 2, math.floor((i - 1) / 2)
			local x, y = 716 + col * 140 - line * 6, TOP + 256 + line * 44
			local level = wallet.level(s.prof, set.id, s.slot)
			local on = a.gear[s.slot] == set.id
			if on then kit.light(g, x, y, 126, 36, 12) end
			kit.text(g, T.set_level:format(set.name, level), x + 68, y + 25, 14, on and KC.INK or kit.with_alpha(KC.SAND, 0.85), "middle")
			kit.zone(g, s.buttons, x, y - 4, 138, 44, "indossa:" .. set.id)
		end
	end
	if i == 0 then kit.text(g, kit.upper(T.none_owned), 718, TOP + 272, 11, KC.HOT_TOP, "start", 1) end
end

-- BOTTEGA and CATALOGO -----------------------------------------------------------

-- the chosen ware's line: its effects at level 1, and how to take it
local function ware_info(s, y)
	local g = s.kg
	local w = s.ware
	if not w then
		kit.text(g, kit.upper(T.pick_ware), 444, y + 20, 12, KC.MUTE, "start", 1.2)
		return
	end
	kit.info(g, 440, y, 546, 54, KC.HOT)
	kit.text(g, piece_name(w.set, w.slot), 462, y + 24, 18, KC.SAND)
	kit.text(g, kit.upper(T.at_level_1:format(effects(equip.piece(w.set, w.slot, 1)))), 462, y + 44, 11, KC.MUTE, "start", 1)
end

-- the Smith's vouchers: how many, and (in the CATALOGO, a ware chosen and not
-- owned) the button that uses one
local function vouchers(s, y, usable)
	local g = s.kg
	local n = s.prof.buoni or 0
	if n <= 0 then return end
	local x = 440
	kit.info(g, x, y, 546, 44, KC.STAR)
	kit.text(g, kit.upper(T.vouchers:format(n) .. (usable and "" or T.voucher_hint)), x + 22, y + 28, 13, KC.SAND, "start", 1.2)
	if usable then
		kit.light(g, x + 360, y + 6, 170, 32, 10)
		kit.text(g, T.use_voucher, x + 445, y + 28, 14, KC.INK, "middle")
		kit.zone(g, s.buttons, x + 354, y, 182, 44, "buono")
	end
end

local function shop(s)
	local g = s.kg
	local today = wallet.today()
	local wares = wallet.shop(s.prof, today)
	for i, slot in ipairs(equip.SLOTS) do
		local col, line = (i - 1) % 2, math.floor((i - 1) / 2)
		local x, y = 440 + col * 280 - line * 8, TOP + line * 136
		local set = wares[slot.id]
		local sel = s.ware and set and s.ware.set == set and s.ware.slot == slot.id
		local k = kit.card(s.kg, x, y, 266, 120, set and KC.ROSE or KC.LINE, { sel = sel, off = not set })
		kit.text(k.g, slot.name, x + 22, y + 26, 12, KC.MUTE, "start", 1.5)
		if set then
			kit.text(k.g, equip.BY_ID[set].name, x + 20, y + 62, 28, KC.SAND)
			local price = wallet.price(s.prof, slot.id, true)
			kit.text(k.g, kit.upper(T.price_only:format(coins.format(price))), x + 22, y + 96, 12,
				price < wallet.PRICE_SHOP and KC.MINT or KC.SAND, "start", 1)
			kit.zone(s.kg, s.buttons, x, y - 6, 266, 132, "merce:" .. set .. "_" .. slot.id)
		else
			kit.text(k.g, kit.upper(T.all_owned), x + 22, y + 62, 13, KC.MUTE, "start", 1)
		end
	end
	kit.text(g, kit.upper(T.shop_today), 444, TOP + 274, 11, KC.MUTE, "start", 1.2)
	ware_info(s, TOP + 286)
	vouchers(s, TOP + 350, false)
end

local function catalog(s)
	local g = s.kg
	for r, f in ipairs(equip.SETS) do
		for c, slot in ipairs(equip.SLOTS) do
			local x, y = 440 + (c - 1) * 138 - (r - 1) * 4, TOP + (r - 1) * 52
			local own = wallet.owns(s.prof, f.id, slot.id)
			local sel = s.ware and s.ware.set == f.id and s.ware.slot == slot.id
			if sel then kit.light(g, x, y, 130, 44, 10)
			else kit.info(g, x, y, 130, 44, own and KC.MINT or KC.ROSE) end
			local ink = sel and KC.INK or own and KC.MINT or KC.SAND
			kit.text(g, f.name, x + 16, y + 22, 14, ink)
			kit.text(g, own and T.owned:format(slot.name, wallet.level(s.prof, f.id, slot.id)) or slot.name,
				x + 16, y + 38, 10, sel and KC.INK or KC.MUTE, "start", 1)
			kit.zone(g, s.buttons, x, y - 3, 136, 50, "merce:" .. f.id .. "_" .. slot.id)
		end
	end
	ware_info(s, TOP + 266)
	local w = s.ware
	vouchers(s, TOP + 330, w and not wallet.owns(s.prof, w.set, w.slot))
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
	kit.tabs(s.kg, s.buttons, 440, 104, tabs, on, KC.PURPLE)
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
