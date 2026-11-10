-- Armory: the player's 3 loadouts (docs/game_design_competitivo.md, tree rule
-- 4: free rebuild outside the match, 3 saved loadouts).
-- Two tabs:
--   PEZZI  the four pieces worn, their levels bought with Scaglie and the
--          step's scene (menu/pieces.lua), full-set bonus and variant B;
--   ALBERO the skill points in the three branches (sim/skills.lua).
-- On the right the resulting stats, compared to the base.
--
-- The screen is rebuilt from scratch at every tap: few nodes, only when
-- tapped, and no state to keep in sync.
--
-- Use: local a = armeria.new(profile) ; armeria.on_input(a, action_id, action) -> "indietro" or nil
--      armeria.destroy(a)

local ui = require "ui.ui"
local backdrop = require "ui.backdrop"
local game = require "sim.game"
local skills = require "sim.skills"
local equip = require "sim.gear"
local loadout = require "sim.loadout"
local profile = require "menu.profile"
local pieces = require "menu.pieces"
local coins = require "ui.coins"
local step_scene = require "ui.step_scene"
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

-- PEZZI tab: the pieces and their levels in Scaglie (menu/pieces.lua) -----------

local function sheet_pieces(a, parent)
	a.pieces.prof, a.pieces.buttons, a.pieces.w = a.prof, a.buttons, LEFT_W
	pieces.build(a.pieces, parent)
end

-- ALBERO tab -------------------------------------------------------------------

local function sheet_tree(a, parent)
	local c = ui.C
	local tree = to_active(a).tree
	local punti = profile.points(a.prof)
	-- branch columns in the space left of the stats
	local step = math.min(440, LEFT_W / #skills.BRANCHES)
	for b, tree_branch in ipairs(skills.BRANCHES) do
		local x = LEFT_X + (b - (#skills.BRANCHES + 1) / 2) * step
		ui.title(tree_branch.name, x, ui.BODY_TOP - 12, 0.7, c.TEXT, parent)
		ui.text(T.points:format(skills.spent(tree, tree_branch.id)), x, ui.BODY_TOP - 38, 0.6, c.OFF, parent)
		-- nodes per row
		local lines = {}
		for _, n in ipairs(skills.NODES) do
			if n.branch == tree_branch.id then
				lines[n.row] = lines[n.row] or {}
				table.insert(lines[n.row], n)
			end
		end
		for r, list_of in ipairs(lines) do
			local y = ui.BODY_TOP - 95 - (r - 1) * 100
			for i, gui_node in ipairs(list_of) do
				local nx = x + (i - (#list_of + 1) / 2) * 156
				local degrees = tree[gui_node.id] or 0
				local ok = degrees > 0 or skills.can_add(tree, gui_node.id, punti)
				local btn = ui.tab(a.buttons, nx, y, 150, 80, "", "nodo:" .. gui_node.id, degrees > 0, parent)
				local col = ok and c.TEXT or c.OFF
				ui.text(gui_node.name, 0, 22, 0.75, col, btn)
				ui.text(string.format("%d / %d", degrees, gui_node.ranks), 0, -4, 1.3, degrees > 0 and c.BRACE or col, btn)
				ui.text((gui_node.cost == 1 and T.point or T.points):format(gui_node.cost), 0, -28, 0.8, c.OFF, btn)
				if degrees > 0 and skills.can_remove(tree, gui_node.id) then
					ui.button(a.buttons, 62, -26, 26, 26, "-", "togli:" .. gui_node.id, nil, btn)
				end
			end
		end
	end
	-- at the bottom: points, chosen node, rebuild
	local pan = ui.panel(LEFT_X, ui.EDGE + 45, LEFT_W, 90, parent)
	ui.text(T.points_spent:format(skills.spent(tree), punti), -360, 18, 0.9, c.BRACE, pan)
	ui.text(T.level:format(a.prof.livello), -360, -14, 0.55, c.OFF, pan)
	local gui_node = skills.BY_ID[a.ultimo or ""]
	if gui_node then
		ui.text(gui_node.name, 30, 18, 0.75, c.TEXT, pan)
		ui.text(T.per_rank:format(gui_node.desc), 30, -12, 0.6, c.OFF, pan)
	end
	ui.button(a.buttons, 380, 0, 140, 50, T.reset, "azzera", nil, pan)
end

-- Screen -----------------------------------------------------------------------

local function build(a)
	if a.radice then gui.delete_node(a.radice) end
	ui.header_delete(a.head)
	a.buttons = {}
	local c = ui.C
	-- the header (ui.header): ARMERIA, the pill's place, the wallet on the right
	-- (ui/coins.lua); the loadouts in the tabs' row, over the stats
	a.head = ui.header(a.buttons, common.armory, "indietro")
	ui.header_tabs(a.head, a.buttons, { { T.tab_set, "scheda:set", 150 }, { T.tab_tree, "scheda:albero", 150 } },
		a.scheda == "set" and 1 or 2)
	for i = 1, loadout.LOADOUTS do
		ui.tab(a.buttons, 1280 - ui.EDGE - 26 - (loadout.LOADOUTS - i) * 64, ui.TABS_Y, 52, 48, tostring(i), "assetto:" .. i,
			a.prof.is_active == i, a.head.tabs)
	end
	local n = ui.text(T.loadout, 1280 - ui.EDGE - 16 - loadout.LOADOUTS * 64, ui.TABS_Y, 0.7, c.OFF, a.head.tabs)
	gui.set_pivot(n, gui.PIVOT_E)
	a.wallet = coins.wallet(a.prof.scaglie, a.prof.ossidiana, a.head.right, -ui.EDGE - coins.W / 2, 0)
	a.radice = ui.root()
	if a.scheda == "set" then sheet_pieces(a, a.radice) else sheet_tree(a, a.radice) end
	statistics(a, a.radice)
end

function M.new(prof)
	local a = { prof = prof, scheda = "set", pieces = {} }
	a.fondo = backdrop.new("fucina")
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
	elseif kind == "pezzo" or kind == "indossa" or kind == "variante" or kind == "potenzia" then
		local _, step = pieces.run(a.pieces, kind, x)
		-- a step bought: its scene, with the hammer's blows
		if step then
			local set = equip.BY_ID[step.set]
			local slot_name = ""
			for _, sl in ipairs(equip.SLOTS) do if sl.id == step.slot then slot_name = sl.name end end
			a.scene = step_scene.new(slot_name, set.name, step.level, function()
				sound.play("#martello", { speed = 0.9 + 0.1 * math.random() })
			end)
		elseif kind == "potenzia" then
			sound.play("#scaglia")
		end
	elseif kind == "nodo" then
		a.ultimo = x
		if skills.can_add(as.tree, x, profile.points(a.prof)) then as.tree[x] = (as.tree[x] or 0) + 1 end
	elseif kind == "togli" then
		a.ultimo = x
		if skills.can_remove(as.tree, x) then
			as.tree[x] = as.tree[x] - 1
			if as.tree[x] == 0 then as.tree[x] = nil end
		end
	elseif kind == "azzera" then
		as.tree = {}
	end
	profile.save(a.prof)
	build(a)
end

function M.update(a, dt)
	if a.scene and not step_scene.update(a.scene, dt) then
		step_scene.delete(a.scene)
		a.scene = nil
	end
end

function M.on_input(a, action_id, action)
	-- the step's scene: a tap skips it
	if a.scene then
		if action_id == ui.TOUCH and action.pressed then step_scene.skip(a.scene) end
		return nil
	end
	local ui_action = ui.touch(a.buttons, action_id, action)
	if ui_action == "indietro" then return "indietro" end
	if ui_action then run_cmd(a, ui_action) end
	return nil
end

function M.destroy(a)
	if a.scene then step_scene.delete(a.scene) end
	ui.header_delete(a.head)
	gui.delete_node(a.radice)
	gui.delete_node(a.fondo)
end

return M
