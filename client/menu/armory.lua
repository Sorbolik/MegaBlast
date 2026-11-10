-- Armory: the pieces of the player's loadouts (docs/game_design_competitivo.md:
-- free rebuild outside the match, 3 saved loadouts). A Titan set for each
-- piece (sidegrade), tier from mastery, full-set bonus and variant B with
-- pieces at level 30. The Sigilli (the skill points) are in the profile
-- (menu/seals.lua, Sergio 10 Nov). On the right the resulting stats,
-- compared to the base.
--
-- The screen is rebuilt from scratch at every tap: few nodes, only when
-- tapped, and no state to keep in sync.
--
-- Use: local a = armeria.new(profile) ; armeria.on_input(a, action_id, action) -> "indietro" or nil
--      armeria.destroy(a)

local ui = require "ui.ui"
local backdrop = require "ui.backdrop"
local game = require "sim.game"
local equip = require "sim.gear"
local loadout = require "sim.loadout"
local profile = require "menu.profile"
local T = require("lang.text").armory
local common = require("lang.text").common

local M = {}

-- stats shown on the right, in this order: name and how the value is written
M.STATISTICS = {
	{ "max_hp" }, { "walk_speed" }, { "jump_height" }, { "air_speed" },
	{ "teleport_ticks", "seconds" }, { "teleports" },
	{ "parachutes" }, { "air_jumps" },
	{ "fall_damage_mul", "percent" }, { "knockback_mul", "percent" },
	{ "trap_radius" }, { "status_turns" },
	{ "burning_blasts", "yes_no" },
}
for _, s in ipairs(M.STATISTICS) do table.insert(s, 2, T.stats[s[1]]) end
local ROMAN = { "I", "II", "III", "IV" }
local STAT_NAMES = {}
for _, s in ipairs(M.STATISTICS) do STAT_NAMES[s[1]] = string.lower(s[2]) end

local function vec(x, y) return vmath.vector3(x, y, 0) end

local function base()
	return game.base_stats()
end

local function value(v, modo)
	if type(v) ~= "number" then return v and T.yes or T.no end
	if modo == "seconds" then return T.seconds:format(v / 60) end
	if modo == "yes_no" then return v > 0 and T.yes or T.no end
	if modo == "percent" then return string.format("%d%%", math.floor(v * 100 + 0.5)) end
	if v % 1 ~= 0 then return string.format("%.1f", v) end
	return tostring(v)
end

-- "+3 salto, -2 vita": a piece's effects in short
local function effects(list_of)
	local t = {}
	for _, e in ipairs(list_of) do
		local n = e.add or e.mul
		local s = e.add and string.format("%+g", n) or string.format("%+d%%", math.floor((n - 1) * 100 + 0.5))
		t[#t + 1] = s .. " " .. (STAT_NAMES[e.stat] or e.stat)
	end
	return table.concat(t, ", ")
end

local function to_active(a) return profile.active_loadout(a.prof) end

-- the content left of the stats column: from the left margin to 30 before it
local LEFT_W = 1280 - 2 * ui.EDGE - 250 - 30
local LEFT_X = ui.EDGE + LEFT_W / 2

-- Stats ------------------------------------------------------------------------

local function statistics(a, parent)
	local c = ui.C
	local b = base()
	local st = loadout.stats(b, to_active(a), profile.tier(a.prof, to_active(a)))
	-- the column on the right, from the content's top to the bottom margin
	local h = ui.BODY_TOP - ui.EDGE
	local pan = ui.panel(1280 - ui.EDGE - 125, ui.EDGE + h / 2, 250, h, parent)
	ui.title(common.stats, 0, h / 2 - 28, 0.6, c.TEXT, pan)
	local y = h / 2 - 70
	for _, s in ipairs(M.STATISTICS) do
		local k, nome, modo = s[1], s[2], s[3]
		if st[k] ~= nil then
			local diff = b[k] ~= nil and st[k] ~= b[k]
			local col = c.OFF
			if diff then
				local better = type(st[k]) ~= "number" or st[k] > b[k]
				-- for these, less is better
				if k == "teleport_ticks" or k == "fall_damage_mul" or k == "knockback_mul" then
					better = st[k] < b[k]
				end
				col = better and c.BRACE or c.TEXT
			end
			local n = ui.text(nome, -110, y, 0.7, c.OFF, pan)
			gui.set_pivot(n, gui.PIVOT_W)
			local v = ui.text(value(st[k], modo), 110, y, 0.75, col, pan)
			gui.set_pivot(v, gui.PIVOT_E)
			y = y - 30
		end
	end
end

-- SET tab ----------------------------------------------------------------------

local function sheet_set(a, parent)
	local c = ui.C
	local as = to_active(a)
	local tiers = profile.tier(a.prof, as)
	for r, slot in ipairs(equip.SLOTS) do
		-- the first row's buttons start at the content's top
		local y = ui.BODY_TOP - 31 - (r - 1) * 88
		local label = ui.text(slot.name, ui.EDGE, y, 0.8, c.TEXT, parent)
		gui.set_pivot(label, gui.PIVOT_W)
		for i, set in ipairs(equip.SETS) do
			local chosen = as.gear[slot.id] == set.id
			local x = 260 + (i - 1) * 138
			local t = equip.tier(a.prof.mastery[set.id .. "_" .. slot.id])
			ui.tab(a.buttons, x, y + 8, 130, 46, set.name, "set:" .. slot.id .. ":" .. set.id, chosen, parent)
			ui.text(T.tier:format(ROMAN[t]), x, y - 26, 0.55, chosen and c.BRACE or c.OFF, parent)
		end
		local piece = equip.BY_ID[as.gear[slot.id] or ""]
		local n = ui.text(piece and effects(piece.pieces[slot.id]) or T.no_piece, 770, y, 0.6, c.OFF, parent)
		gui.set_pivot(n, gui.PIVOT_W)
	end

	-- full-set bonus, if that set has one
	local id, top = equip.full_set(as.gear, tiers)
	local set = id and equip.BY_ID[id]
	if not (set and set.bonus) then return end
	local pan = ui.panel(LEFT_X, ui.EDGE + 65, LEFT_W, 130, parent)
	ui.title(set.name .. " · " .. string.upper(set.style), -200, 38, 0.7, c.BRACE, pan)
	for i, v in ipairs({ "a", "b" }) do
		local y = 4 - (i - 1) * 40
		local ok = v == "a" or top
		ui.tab(a.buttons, -420, y, 50, 34, string.upper(v), "variante:" .. v, as.variant == v and (v == "a" or top), pan)
		local txt = ok and set.bonus[v].desc or T.locked_bonus:format(set.bonus[v].desc, equip.LIVELLO_MAX)
		local n = ui.text(txt, -380, y, 0.62, ok and c.TEXT or c.OFF, pan)
		gui.set_pivot(n, gui.PIVOT_W)
	end
end

-- Screen -----------------------------------------------------------------------

local function build(a)
	if a.radice then gui.delete_node(a.radice) end
	ui.header_delete(a.head)
	a.buttons = {}
	local c = ui.C
	-- the header (ui.header): ARMERIA, the pill's place, the loadouts on the right
	a.head = ui.header(a.buttons, common.armory, "indietro")
	for i = 1, loadout.LOADOUTS do
		if loadout.open(i, a.prof.livello) then
			ui.tab(a.buttons, -ui.EDGE - 26 - (loadout.LOADOUTS - i) * 64, 0, 52, 48, tostring(i), "assetto:" .. i,
				a.prof.is_active == i, a.head.right)
		end
	end
	local n = ui.text(T.loadout, -ui.EDGE - 16 - loadout.LOADOUTS * 64, 0, 0.7, c.OFF, a.head.right)
	gui.set_pivot(n, gui.PIVOT_E)
	a.radice = ui.root()
	sheet_set(a, a.radice)
	statistics(a, a.radice)
end

function M.new(prof)
	local a = { prof = prof }
	a.fondo = backdrop.new("fucina")
	build(a)
	return a
end

-- button actions: "kind:argument[:other]"
local function run_cmd(a, ui_action)
	local kind, x, y = ui_action:match("^(%a+):?([^:]*):?(.*)$")
	local as = to_active(a)
	if kind == "assetto" then
		a.prof.is_active = tonumber(x)
	elseif kind == "set" then
		-- tapping the set already chosen removes it
		as.gear[x] = as.gear[x] ~= y and y or nil
	elseif kind == "variante" then
		local _, top = equip.full_set(as.gear, profile.tier(a.prof, as))
		if x == "a" or top then as.variant = x end
	end
	profile.save(a.prof)
	build(a)
end

function M.on_input(a, action_id, action)
	local ui_action = ui.touch(a.buttons, action_id, action)
	if ui_action == "indietro" then return "indietro" end
	if ui_action then run_cmd(a, ui_action) end
	return nil
end

function M.destroy(a)
	ui.header_delete(a.head)
	gui.delete_node(a.radice)
	gui.delete_node(a.fondo)
end

return M
