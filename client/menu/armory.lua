-- Armory: the player's 3 loadouts (docs/game_design_competitivo.md, tree rule
-- 4: free rebuild outside the match, 3 saved loadouts).
-- Two tabs:
--   SET    a Titan set for each piece (sidegrade), tier from mastery,
--          full-set bonus and variant B with pieces at level 30;
--   ALBERO the skill points in the three branches (sim/skills.lua).
-- On the right the resulting stats, compared to the base.
--
-- The screen is rebuilt from scratch at every tap: few nodes, only when
-- tapped, and no state to keep in sync.
--
-- Use: local a = armeria.new(profile) ; armeria.on_input(a, action_id, action) -> "indietro" or nil
--      armeria.destroy(a)

local ui = require "ui.ui"
local game = require "sim.game"
local skills = require "sim.skills"
local equip = require "sim.gear"
local loadout = require "sim.loadout"
local profile = require "menu.profile"
local T = require("lang.text").armory

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

-- Stats ------------------------------------------------------------------------

local function statistics(a, parent)
	local c = ui.C
	local b = base()
	local st = loadout.stats(b, to_active(a), profile.tier(a.prof, to_active(a)))
	local pan = ui.pannello(1135, 330, 250, 560, parent)
	ui.titolo(T.stats_title, 0, 255, 0.6, c.TEXT, pan)
	local y = 215
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
			local n = ui.testo(nome, -110, y, 0.7, c.OFF, pan)
			gui.set_pivot(n, gui.PIVOT_W)
			local v = ui.testo(value(st[k], modo), 110, y, 0.75, col, pan)
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
		local y = 540 - (r - 1) * 92
		ui.testo(slot.name, 110, y, 0.8, c.TEXT, parent)
		for i, set in ipairs(equip.SETS) do
			local chosen = as.gear[slot.id] == set.id
			local x = 260 + (i - 1) * 138
			local t = equip.tier(a.prof.mastery[set.id .. "_" .. slot.id])
			ui.scheda(a.buttons, x, y + 8, 130, 46, set.name, "set:" .. slot.id .. ":" .. set.id, chosen, parent)
			ui.testo(T.tier:format(ROMAN[t]), x, y - 26, 0.55, chosen and c.BRACE or c.OFF, parent)
		end
		local piece = equip.BY_ID[as.gear[slot.id] or ""]
		local n = ui.testo(piece and effects(piece.pieces[slot.id]) or T.no_piece, 770, y, 0.6, c.OFF, parent)
		gui.set_pivot(n, gui.PIVOT_W)
	end

	-- full-set bonus, if that set has one
	local id, top = equip.full_set(as.gear, tiers)
	local set = id and equip.BY_ID[id]
	if not (set and set.bonus) then return end
	local pan = ui.pannello(510, 140, 940, 130, parent)
	ui.titolo(set.name .. " · " .. string.upper(set.style), -200, 38, 0.7, c.BRACE, pan)
	for i, v in ipairs({ "a", "b" }) do
		local y = 4 - (i - 1) * 40
		local ok = v == "a" or top
		ui.scheda(a.buttons, -420, y, 50, 34, string.upper(v), "variante:" .. v, as.variant == v and (v == "a" or top), pan)
		local txt = ok and set.bonus[v].desc or T.locked_bonus:format(set.bonus[v].desc, equip.LIVELLO_MAX)
		local n = ui.testo(txt, -380, y, 0.62, ok and c.TEXT or c.OFF, pan)
		gui.set_pivot(n, gui.PIVOT_W)
	end
end

-- ALBERO tab -------------------------------------------------------------------

local function sheet_tree(a, parent)
	local c = ui.C
	local tree = to_active(a).tree
	local punti = profile.punti(a.prof)
	-- branch columns in the space left of the stats
	local step = math.min(440, 990 / #skills.BRANCHES)
	for b, tree_branch in ipairs(skills.BRANCHES) do
		local x = 510 + (b - (#skills.BRANCHES + 1) / 2) * step
		ui.titolo(tree_branch.name, x, 575, 0.7, c.TEXT, parent)
		ui.testo(T.points:format(skills.spent(tree, tree_branch.id)), x, 548, 0.6, c.OFF, parent)
		-- nodes per row
		local lines = {}
		for _, n in ipairs(skills.NODES) do
			if n.branch == tree_branch.id then
				lines[n.row] = lines[n.row] or {}
				table.insert(lines[n.row], n)
			end
		end
		for r, list_of in ipairs(lines) do
			local y = 490 - (r - 1) * 100
			for i, gui_node in ipairs(list_of) do
				local nx = x + (i - (#list_of + 1) / 2) * 156
				local degrees = tree[gui_node.id] or 0
				local ok = degrees > 0 or skills.can_add(tree, gui_node.id, punti)
				local btn = ui.scheda(a.buttons, nx, y, 150, 80, "", "nodo:" .. gui_node.id, degrees > 0, parent)
				local col = ok and c.TEXT or c.OFF
				ui.testo(gui_node.name, 0, 22, 0.75, col, btn)
				ui.testo(string.format("%d / %d", degrees, gui_node.ranks), 0, -4, 1.3, degrees > 0 and c.BRACE or col, btn)
				ui.testo((gui_node.cost == 1 and T.point or T.points):format(gui_node.cost), 0, -28, 0.8, c.OFF, btn)
				if degrees > 0 and skills.can_remove(tree, gui_node.id) then
					ui.button(a.buttons, 62, -26, 26, 26, "-", "togli:" .. gui_node.id, nil, btn)
				end
			end
		end
	end
	-- at the bottom: points, chosen node, rebuild
	local pan = ui.pannello(510, 70, 940, 90, parent)
	ui.testo(T.points_spent:format(skills.spent(tree), punti), -360, 18, 0.9, c.BRACE, pan)
	ui.testo(T.level:format(a.prof.livello), -360, -14, 0.55, c.OFF, pan)
	local gui_node = skills.BY_ID[a.ultimo or ""]
	if gui_node then
		ui.testo(gui_node.name, 30, 18, 0.75, c.TEXT, pan)
		ui.testo(T.per_rank:format(gui_node.desc), 30, -12, 0.6, c.OFF, pan)
	end
	ui.button(a.buttons, 380, 0, 140, 50, T.reset, "azzera", nil, pan)
end

-- Screen -----------------------------------------------------------------------

local function build(a)
	if a.radice then gui.delete_node(a.radice) end
	a.buttons = {}
	a.radice = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_visible(a.radice, false)
	local c = ui.C
	ui.indietro(a.buttons, "indietro", a.radice)
	ui.titolo(T.title, 220, 680, 1, c.TEXT, a.radice)
	ui.scheda(a.buttons, 470, 622, 150, 48, T.tab_set, "scheda:set", a.scheda == "set", a.radice)
	ui.scheda(a.buttons, 630, 622, 150, 48, T.tab_tree, "scheda:albero", a.scheda == "albero", a.radice)
	ui.testo(T.loadout, 900, 680, 0.7, c.OFF, a.radice)
	for i = 1, loadout.LOADOUTS do
		ui.scheda(a.buttons, 940 + i * 70, 680, 60, 48, tostring(i), "assetto:" .. i, a.prof.is_active == i, a.radice)
	end
	if a.scheda == "set" then sheet_set(a, a.radice) else sheet_tree(a, a.radice) end
	statistics(a, a.radice)
end

function M.new(prof)
	local a = { prof = prof, scheda = "set" }
	a.fondo = ui.sfondo()
	build(a)
	return a
end

-- button actions: "kind:argument[:other]"
local function run_cmd(a, ui_action)
	local kind, x, y = ui_action:match("^(%a+):?([^:]*):?(.*)$")
	local as = to_active(a)
	if kind == "scheda" then
		a.scheda = x
	elseif kind == "assetto" then
		a.prof.is_active = tonumber(x)
	elseif kind == "set" then
		-- tapping the set already chosen removes it
		as.gear[x] = as.gear[x] ~= y and y or nil
	elseif kind == "variante" then
		local _, top = equip.full_set(as.gear, profile.tier(a.prof, as))
		if x == "a" or top then as.variant = x end
	elseif kind == "nodo" then
		a.ultimo = x
		if skills.can_add(as.tree, x, profile.punti(a.prof)) then as.tree[x] = (as.tree[x] or 0) + 1 end
	elseif kind == "togli" then
		a.ultimo = x
		if skills.can_remove(as.tree, x) then
			as.tree[x] = as.tree[x] - 1
			if as.tree[x] == 0 then as.tree[x] = nil end
		end
	elseif kind == "azzera" then
		as.tree = {}
	end
	profile.salva(a.prof)
	build(a)
end

function M.on_input(a, action_id, action)
	local ui_action = ui.tocco(a.buttons, action_id, action)
	if ui_action == "indietro" then return "indietro" end
	if ui_action then run_cmd(a, ui_action) end
	return nil
end

function M.destroy(a)
	gui.delete_node(a.radice)
	gui.delete_node(a.fondo)
end

return M
