-- Armory: the pieces of the player's loadouts (docs/game_design_competitivo.md:
-- free rebuild outside the match, 3 saved loadouts): the four pieces worn,
-- their levels bought with Scaglie and the step's scene (menu/pieces.lua),
-- full-set bonus and variant B. The Sigilli (the skill points) are in the
-- profile (menu/seals.lua, Sergio 10 Nov). On the right the resulting stats,
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

-- Screen -----------------------------------------------------------------------

local function build(a)
	if a.radice then gui.delete_node(a.radice) end
	ui.header_delete(a.head)
	a.buttons = {}
	local c = ui.C
	-- the header (ui.header): ARMERIA, the pill's place, the wallet on the right
	-- (ui/coins.lua); the loadouts in the tabs' row, over the stats
	a.head = ui.header(a.buttons, common.armory, "indietro")
	ui.header_tabs(a.head, a.buttons, {})
	for i = 1, loadout.LOADOUTS do
		if loadout.open(i, a.prof.livello) then
			ui.tab(a.buttons, 1280 - ui.EDGE - 26 - (loadout.LOADOUTS - i) * 64, ui.TABS_Y, 52, 48, tostring(i), "assetto:" .. i,
				a.prof.is_active == i, a.head.tabs)
		end
	end
	local n = ui.text(T.loadout, 1280 - ui.EDGE - 16 - loadout.LOADOUTS * 64, ui.TABS_Y, 0.7, c.OFF, a.head.tabs)
	gui.set_pivot(n, gui.PIVOT_E)
	a.wallet = coins.wallet(a.prof.scaglie, a.prof.ossidiana, a.head.right, -ui.EDGE - coins.W / 2, 0)
	a.radice = ui.root()
	sheet_pieces(a, a.radice)
	statistics(a, a.radice)
end

function M.new(prof)
	local a = { prof = prof, pieces = {} }
	a.fondo = backdrop.new("fucina")
	build(a)
	return a
end

-- button actions: "kind:argument[:other]"
local function run_cmd(a, ui_action)
	local kind, x = ui_action:match("^(%a+):?([^:]*)")
	if kind == "assetto" then
		a.prof.is_active = tonumber(x)
	elseif kind == "pezzo" or kind == "indossa" or kind == "variante" or kind == "potenzia" then
		local _, step = pieces.run(a.pieces, kind, x)
		-- a step bought: its scene, with the hammer's blows
		if step then
			local set = equip.BY_ID[step.set]
			local slot_name = ""
			for _, sl in ipairs(equip.SLOTS) do if sl.id == step.slot then slot_name = sl.name end end
			a.step = { slot_name, set.name, step.level }
		elseif kind == "potenzia" then
			sound.play("#scaglia")
		end
	end
	profile.save(a.prof)
	build(a)
	-- the scene goes above the rebuilt screen
	if a.step then
		a.scene = step_scene.new(a.step[1], a.step[2], a.step[3], function()
			sound.play("#martello", { speed = 0.9 + 0.1 * math.random() })
		end)
		a.step = nil
	end
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
