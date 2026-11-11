-- The pieces of the armory (Figma 08): the four pieces worn as cards, the
-- chosen one with its 30 levels, the Proof, the variant, the sets to wear, and
-- as the screen's action POTENZIA in Scaglie (page "Scaglie e Ossidiana",
-- choices 4A-6A). Pure layout with ui/kit.lua, so the screen that hosts it
-- (menu/armory.lua) keeps its frame and stats. Rebuilt at every tap.
--
--   local pieces = require "menu.pieces"
--   pieces.build(s)  -- s = { prof, buttons, kg (the kit group), right (the action's anchor), slot = "mask" }
--   pieces.run(s, kind, arg) -> handled, step  -- step: { slot, set, level } when a step was bought
--
-- Actions on the buttons: "pezzo:<slot>", "indossa:<set>", "potenzia", "variante:a|b".

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

local function active(s) return profile.active_loadout(s.prof) end

-- a level's grade color: bronze, silver, gold, ember
local function grade_color(level)
	return ui.C.GRADI[equip.tier(level)]
end

-- "+3% salto, -2 vita" from the stat names of the armory
local function effects(list_of)
	local t = {}
	for _, e in ipairs(list_of) do
		local n = e.add or e.mul
		local v = e.add and string.format("%+g", n) or string.format("%+d%%", math.floor((n - 1) * 100 + 0.5))
		t[#t + 1] = v .. " " .. (TA.stats[e.stat] or e.stat)
	end
	return table.concat(t, ", ")
end

-- the four pieces worn: one card each, staggered; the chosen one lit
local function slots(s)
	local a = active(s)
	for i, slot in ipairs(equip.SLOTS) do
		local x, y = 440 + (i - 1) * 10, 112 + (i - 1) * 84
		local set = a.gear[slot.id]
		local level = set and wallet.level(s.prof, set, slot.id)
		local full = level == equip.LIVELLO_MAX
		local k = kit.card(s.kg, x, y, 220, 70, full and KC.STAR or KC.ROSE, { sel = s.slot == slot.id })
		kit.text(k.g, slot.name, x + 30, y + 25, 12, KC.MUTE, "start", 1.5)
		kit.text(k.g, set and equip.BY_ID[set].name or kit.upper(T.empty), x + 26, y + 54, 24, set and KC.SAND or KC.MUTE)
		if set then kit.text(k.g, tostring(level), x + 206, y + 44, 26, full and KC.STAR or KC.SAND, "end") end
		kit.zone(s.kg, s.buttons, x, y - 6, 220, 82, "pezzo:" .. slot.id)
	end
end

-- the chosen piece: name, level, effects, the 30 notches, the next level
local function detail(s)
	local g = s.kg
	local a = active(s)
	local slot = equip.SLOTS[1]
	for _, sl in ipairs(equip.SLOTS) do if sl.id == s.slot then slot = sl end end
	local set = a.gear[slot.id]
	local act = { label = T.upgrade, off = true }
	if not set then
		kit.text(g, slot.name, 716, 138, 34, KC.MUTE)
		kit.text(g, kit.upper(T.choose:format(slot.name)), 718, 162, 12, KC.MUTE, "start", 1.2)
		act.sub = kit.upper(T.empty)
		return act
	end
	local info = equip.BY_ID[set]
	local level = wallet.level(s.prof, set, slot.id)
	local name = kit.text(g, T.piece:format(slot.name, info.name), 716, 138, 34, KC.SAND)
	-- a long name shrinks: the stats column starts right after
	local wide = kit.width(name)
	if wide > 268 then gui.set_scale(name, gui.get_scale(name) * (268 / wide)) end
	kit.text(g, kit.upper(T.grade:format(ROMAN[equip.tier(level)], T.grades[equip.tier(level)], effects(info.pieces[slot.id]))),
		718, 162, 12, KC.MUTE, "start", 1.2)
	for l = 1, equip.LIVELLO_MAX do
		local big = equip.PROOF[l] ~= nil
		kit.para(g, 716 + (l - 1) * 7.6, big and 176 or 180, 5, big and 24 or 16, 3, l <= level and grade_color(level) or KC.TRACK)
	end
	kit.text(g, T.of_max:format(level, equip.LIVELLO_MAX), 950, 196, 15, grade_color(level))

	-- the next level: what it is, the Proof if it is a step, the price on the action
	local n = wallet.next(s.prof, set, slot.id)
	if not n then
		kit.text(g, T.at_max, 718, 224, 12, KC.HOT_TOP, "start", 1.2)
		act.sub = T.at_max
	else
		local step = n.proof > 0
		kit.text(g, kit.upper(step and T.next_step:format(n.level, ROMAN[equip.tier(n.level)], T.grades[equip.tier(n.level)])
			or T.next_level:format(n.level)), 718, 224, 12, step and KC.HOT_TOP or KC.MUTE, "start", 1.2)
		local ready = n.proof_done >= n.proof
		local enough = s.prof.scaglie >= n.cost
		if step then
			kit.info(g, 716, 244, 270, 54, KC.PURPLE)
			kit.text(g, T.proof_name, 740, 266, 12, KC.MUTE, "start", 1.5)
			kit.text(g, kit.upper(T.proof:format(n.proof_done, n.proof)), 738, 286, 11, KC.SAND, "start", 0.5)
			kit.bar(g, 880, 258, 90, 8, math.min(1, n.proof_done / n.proof), KC.MINT)
		elseif n.cost < n.full_cost then
			kit.info(g, 716, 244, 270, 54, KC.HOT)
			kit.text(g, T.smith_name, 740, 266, 12, KC.MUTE, "start", 1.5)
			kit.text(g, kit.upper(T.smith_hand:format(coins.format(n.full_cost))), 738, 286, 11, KC.SAND, "start", 0.5)
		end
		act.off = not (ready and enough)
		act.sub = not ready and kit.upper(T.proof_first) or not enough and kit.upper(T.missing:format(coins.format(n.cost - s.prof.scaglie)))
			or T.price:format(coins.format(n.cost), n.level)
	end

	-- the set bonus with all four pieces, variant B with all of them at 30
	local id, top_all = equip.full_set(a.gear, wallet.tiers(s.prof, a))
	local bonus = id and equip.BY_ID[id].bonus
	if bonus then
		kit.text(g, T.variant, 718, 330, 12, KC.MUTE, "start", 1.5)
		for i, v in ipairs({ "a", "b" }) do
			local x = 790 + (i - 1) * 62
			local ok = v == "a" or top_all
			local on = a.variant == v and ok
			if on then kit.para(g, x, 310, 48, 36, 10, KC.SAND) end
			kit.text(g, string.upper(v), x + 28, 335, 18, on and KC.INK or kit.with_alpha(KC.SAND, ok and 0.85 or 0.4), "middle")
			kit.zone(g, s.buttons, x, 304, 58, 48, "variante:" .. v)
		end
		if not top_all then kit.text(g, T.at_level:format(equip.LIVELLO_MAX), 912, 334, 11, KC.MUTE, "start", 1) end
		local v = (a.variant == "b" and top_all) and "b" or "a"
		kit.text(g, kit.upper(T.set_bonus:format(equip.BY_ID[id].name) .. ": " .. bonus[v].desc), 712, 512, 11, KC.MUTE, "start", 1)
	end
	return act
end

-- the sets for the chosen slot: a choice, tap to wear (tap again: take off)
local function others(s)
	local g = s.kg
	local a = active(s)
	kit.text(g, T.others, 718, 378, 12, KC.MUTE, "start", 1.5)
	for i, set in ipairs(equip.SETS) do
		local col, line = (i - 1) % 2, math.floor((i - 1) / 2)
		local x, y = 716 + col * 140 - line * 6, 390 + line * 52
		local level = wallet.level(s.prof, set.id, s.slot)
		local on = a.gear[s.slot] == set.id
		if on then kit.para(g, x, y, 126, 40, 12, KC.SAND) end
		kit.text(g, T.set_level:format(set.name, level), x + 68, y + 27, 14, on and KC.INK or kit.with_alpha(KC.SAND, 0.85), "middle")
		kit.zone(g, s.buttons, x, y - 6, 138, 52, "indossa:" .. set.id)
	end
end

function M.build(s)
	s.slot = s.slot or equip.SLOTS[1].id
	slots(s)
	local act = detail(s)
	others(s)
	-- the one action: POTENZIA, with the price under it (or what is missing)
	s.action = kit.action(s.right, act.label, 930, 560, 270, 84, { size = 44, off = act.off, sub = act.sub })
	kit.button(s.buttons, s.action, "potenzia", { main = true, spento = act.off })
end

function M.run(s, kind, arg)
	local a = active(s)
	if kind == "pezzo" then
		s.slot = arg
	elseif kind == "indossa" then
		a.gear[s.slot] = a.gear[s.slot] ~= arg and arg or nil
	elseif kind == "variante" then
		local _, top = equip.full_set(a.gear, wallet.tiers(s.prof, a))
		if arg == "a" or top then a.variant = arg end
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
