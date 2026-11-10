-- The PEZZI sheet: the four pieces worn, the chosen one with its 30 levels and
-- the POTENZIA button in Scaglie (page "Scaglie e Ossidiana", choices 4A-6A
-- and the drawn screen "Potenziare un pezzo"). Pure layout on a parent, so the
-- screen that hosts it (today ARMERIA, menu/armory.lua) keeps its header and
-- stats. The screen is rebuilt at every tap, like the armory.
--
--   local pieces = require "menu.pieces"
--   pieces.build(s, parent)  -- s = { prof, buttons, slot = "mask", w = width of the sheet }
--   pieces.run(s, kind, arg) -> handled, step  -- step: { slot, set, level } when a step was bought
--
-- Actions on the buttons: "pezzo:<slot>", "indossa:<set>", "potenzia", "variante:a|b".

local ui = require "ui.ui"
local coins = require "ui.coins"
local equip = require "sim.gear"
local profile = require "menu.profile"
local wallet = require "menu.wallet"
local T = require("lang.text").pieces
local TA = require("lang.text").armory

local M = {}

local CARD_W, CARD_H, CARD_GAP = 210, 92, 12
local ROMAN = { "I", "II", "III", "IV" }

local function vec(x, y) return vmath.vector3(x, y, 0) end
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
		t[#t + 1] = v .. " " .. string.lower(TA.stats[e.stat] or e.stat)
	end
	return table.concat(t, ", ")
end

-- a diamond of the steps: the rounded square turned 45 degrees (its edges are
-- the image's, no steps)
local function diamond(x, y, d, fill, edge, parent)
	local n = ui.sagoma("forma", x, y, d, d, fill, parent)
	gui.set_slice9(n, vmath.vector4(d / 4, d / 4, d / 4, d / 4))
	gui.set_rotation(n, vmath.vector3(0, 0, 45))
	if edge then
		local b = ui.sagoma("bordo", 0, 0, d, d, edge, n)
		gui.set_slice9(b, vmath.vector4(d / 4, d / 4, d / 4, d / 4))
	end
	return n
end

-- the four slots on the left, each with the piece worn and its level
local function slots(s, parent)
	local a = active(s)
	for i, slot in ipairs(equip.SLOTS) do
		local y = ui.BODY_TOP - CARD_H / 2 - (i - 1) * (CARD_H + CARD_GAP)
		local set = a.gear[slot.id]
		local level = set and wallet.level(s.prof, set, slot.id)
		local n = ui.tab(s.buttons, ui.EDGE + CARD_W / 2, y, CARD_W, CARD_H, "", "pezzo:" .. slot.id, s.slot == slot.id, parent)
		local b = s.buttons[#s.buttons]
		if set then
			b.riposo = s.slot == slot.id and ui.C.LIGHT or grade_color(level)
			gui.set_color(b.bordo, b.riposo)
		end
		local t = ui.text(slot.name, -CARD_W / 2 + 16, 24, 0.55, ui.C.OFF, n)
		gui.set_pivot(t, gui.PIVOT_W)
		t = ui.title(set and equip.BY_ID[set].name or T.empty, -CARD_W / 2 + 16, 0, 0.6, set and ui.C.TEXT or ui.C.OFF, n)
		gui.set_pivot(t, gui.PIVOT_W)
		if set then
			t = ui.text(T.level:format(level), -CARD_W / 2 + 16, -26, 0.6, grade_color(level), n)
			gui.set_pivot(t, gui.PIVOT_W)
		end
	end
end

-- the 30 levels: a notch per level, a diamond at each step
local function track(level, x0, w, y, parent)
	for l = 1, equip.LIVELLO_MAX do
		local x = x0 + (l - 1) * w / (equip.LIVELLO_MAX - 1)
		local on = l <= level
		local step = equip.PROOF[l]
		if step then
			diamond(x, y, 24, on and grade_color(l) or ui.C.BOTTOM, on and grade_color(l) or ui.C.LINE, parent)
			ui.text(tostring(l), x, y - 26, 0.5, ui.C.OFF, parent)
		else
			ui.sagoma(nil, x, y, 8, 14, on and grade_color(level) or ui.C.LINE, parent)
		end
	end
end

-- the chosen piece: name, level, effects, track, next level and the button
local function detail(s, parent)
	local a = active(s)
	local slot = equip.SLOTS[1]
	for _, sl in ipairs(equip.SLOTS) do if sl.id == s.slot then slot = sl end end
	local set = a.gear[slot.id]
	local x0 = ui.EDGE + CARD_W + 24
	local w = s.w - CARD_W - 24
	local h = 4 * CARD_H + 3 * CARD_GAP
	local pan = ui.panel(x0 + w / 2, ui.BODY_TOP - h / 2, w, h, parent)
	local left, top = -w / 2 + 20, h / 2
	if not set then
		ui.text(T.choose:format(string.lower(slot.name)), 0, 0, 0.8, ui.C.OFF, pan)
		return
	end
	local info = equip.BY_ID[set]
	local level = wallet.level(s.prof, set, slot.id)
	local t = ui.title(T.piece:format(slot.name, info.name), left, top - 32, 0.75, ui.C.TEXT, pan)
	gui.set_pivot(t, gui.PIVOT_W)
	t = ui.title(T.of_max:format(level, equip.LIVELLO_MAX), w / 2 - 20, top - 32, 0.85, grade_color(level), pan)
	gui.set_pivot(t, gui.PIVOT_E)
	t = ui.text(T.grade:format(ROMAN[equip.tier(level)], T.grades[equip.tier(level)], effects(info.pieces[slot.id])),
		left, top - 64, 0.6, grade_color(level), pan)
	gui.set_pivot(t, gui.PIVOT_W)
	track(level, left + 10, w - 60, top - 108, pan)

	-- the next level
	local n = wallet.next(s.prof, set, slot.id)
	local y = top - 200
	if not n then
		t = ui.title(T.at_max, left, y, 0.7, ui.C.BRACE, pan)
		gui.set_pivot(t, gui.PIVOT_W)
	else
		local step = n.proof > 0
		t = ui.text(step and T.next_step:format(n.level, ROMAN[equip.tier(n.level)], T.grades[equip.tier(n.level)])
			or T.next_level:format(n.level), left, y + 26, 0.6, step and ui.C.GOLD or ui.C.OFF, pan)
		gui.set_pivot(t, gui.PIVOT_W)
		local ready = n.proof_done >= n.proof
		local enough = s.prof.scaglie >= n.cost
		if step and not ready then
			-- the Proof: matches still to play wearing the piece
			t = ui.text(T.proof:format(n.proof_done, n.proof), left, y - 8, 0.65, ui.C.TEXT, pan)
			gui.set_pivot(t, gui.PIVOT_W)
			local bar = ui.bar(left + 150, y - 36, 300, 8, ui.C.GOLD, pan)
			ui.bar_value(bar, n.proof_done / n.proof)
		else
			local bw = 260
			local b = ui.button(s.buttons, left + bw / 2, y - 22, bw, 60, "", "potenzia", { spento = not enough }, pan)
			ui.title(T.upgrade, -28, 0, 0.7, enough and ui.C.TEXT or ui.C.OFF, b)
			coins.icon("scaglia", 62, 0, 28, b)
			t = ui.title(coins.format(n.cost), 80, 0, 0.7, enough and ui.C.GOLD or ui.C.OFF, b)
			gui.set_pivot(t, gui.PIVOT_W)
			if not enough then
				t = ui.text(T.missing:format(coins.format(n.cost - s.prof.scaglie)), left + bw + 20, y - 22, 0.6, ui.C.OFF, pan)
				gui.set_pivot(t, gui.PIVOT_W)
			end
		end
		if n.cost < n.full_cost then
			t = ui.text(T.smith_hand:format(coins.format(n.full_cost)), left, y - 70, 0.55, ui.C.OFF, pan)
			gui.set_pivot(t, gui.PIVOT_W)
		end
	end

	-- the set bonus with all four pieces, variant B with all of them at 30
	local id, top_all = equip.full_set(a.gear, wallet.tiers(s.prof, a))
	local bonus = id and equip.BY_ID[id].bonus
	if bonus then
		local by = -h / 2 + 62
		t = ui.title(T.set_bonus:format(equip.BY_ID[id].name), left, by + 30, 0.55, ui.C.BRACE, pan)
		gui.set_pivot(t, gui.PIVOT_W)
		for i, v in ipairs({ "a", "b" }) do
			local yy = by - (i - 1) * 36
			local ok = v == "a" or top_all
			ui.tab(s.buttons, left + 22, yy - 4, 44, 32, string.upper(v), "variante:" .. v, a.variant == v and ok, pan)
			t = ui.text(ok and bonus[v].desc or TA.locked_bonus:format(bonus[v].desc, equip.LIVELLO_MAX), left + 56, yy - 4, 0.55,
				ok and ui.C.TEXT or ui.C.OFF, pan)
			gui.set_pivot(t, gui.PIVOT_W)
		end
	end
end

-- at the bottom, the sets for the chosen slot: tap to wear (tap again: take off)
local function others(s, parent)
	local a = active(s)
	local slot = s.slot
	local y = ui.EDGE + 30
	local x = ui.EDGE
	local t = ui.text(T.others, x, y, 0.6, ui.C.OFF, parent)
	gui.set_pivot(t, gui.PIVOT_W)
	x = x + 130
	local bw = (s.w - 130 - 3 * 10) / #equip.SETS
	for _, set in ipairs(equip.SETS) do
		local level = wallet.level(s.prof, set.id, slot)
		ui.tab(s.buttons, x + bw / 2, y, bw, 48, T.set_level:format(set.name, level), "indossa:" .. set.id,
			a.gear[slot] == set.id, parent)
		x = x + bw + 10
	end
end

function M.build(s, parent)
	s.slot = s.slot or equip.SLOTS[1].id
	slots(s, parent)
	detail(s, parent)
	others(s, parent)
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
