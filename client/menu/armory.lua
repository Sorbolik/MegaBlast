-- Armory: the pieces of the player's loadouts (docs/game_design_competitivo.md:
-- free rebuild outside the match, 3 saved loadouts): the wardrobe with the
-- four pieces worn, their levels bought with Scaglie and the step's scene, the
-- shop of the day and the catalog (menu/pieces.lua). The Sigilli (the skill points) are in the
-- profile (menu/seals.lua, Sergio 10 Nov). On the right the resulting stats,
-- compared to the base.
--
-- The screen is rebuilt from scratch at every tap: few nodes, only when
-- tapped, and no state to keep in sync.
--
-- Use: local a = armeria.new(profile [, where the way back leads]) ; armeria.on_input(a, action_id, action) -> "indietro" or nil
--      armeria.destroy(a)

local ui = require "ui.ui"
local kit = require "ui.kit"
local scoria = require "battle.scoria"
local profile_tabs = require "menu.profile_tabs"
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

local KC = kit.C

-- stats shown on the right, in this order: name and how the value is written
M.STATISTICS = {
	{ "max_hp" }, { "walk_speed" }, { "jump_height" }, { "air_speed" },
	{ "teleport_ticks", "seconds" }, { "teleports" },
	{ "parachutes" }, { "air_jumps" },
	{ "fall_damage_mul", "percent" }, { "knockback_mul", "percent" }, { "blast_push", "percent" },
	{ "trap_radius" }, { "status_turns" },
	{ "burning_blasts", "yes_no" },
}
for _, s in ipairs(M.STATISTICS) do table.insert(s, 2, T.stats[s[1]]) end

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

-- Stats ------------------------------------------------------------------------

-- the column on the right: rows to read, the ones the pieces improve in mint
local function statistics(a)
	local g = a.kg
	local b = base()
	local st = loadout.stats(b, to_active(a), profile.levels(a.prof, to_active(a)))
	kit.heading(g, common.stats, 1030 + kit.air(), 112)
	local rows = {}
	for _, s in ipairs(M.STATISTICS) do
		if st[s[1]] ~= nil then rows[#rows + 1] = s end
	end
	-- closer together when they are many: the action is under them
	local step = math.min(38, 392 / math.max(1, #rows - 1))
	local h = math.min(30, step - 6)
	for i, s in ipairs(rows) do
		local k, nome, modo = s[1], s[2], s[3]
		local x, y = 1024 + kit.air() - (i - 1) * 3 * step / 38, 128 + (i - 1) * step
		local col, mark = KC.SAND, KC.PURPLE
		if b[k] ~= nil and st[k] ~= b[k] then
			local better = type(st[k]) ~= "number" or st[k] > b[k]
			-- for these, less is better
			if k == "teleport_ticks" or k == "fall_damage_mul" or k == "knockback_mul" then
				better = st[k] < b[k]
			end
			col = better and KC.MINT or KC.RED
			mark = col
		end
		kit.info(g, x, y, 222, h, mark)
		kit.text(g, kit.upper(nome), x + 18, y + h / 2 + 6, 12, KC.SAND, "start", 0.5)
		kit.text(g, kit.upper(value(st[k], modo)), x + 212, y + h / 2 + 6, 13, col, "end")
	end
end

-- Screen -----------------------------------------------------------------------

local function build(a)
	if a.radice then gui.delete_node(a.radice) end
	if a.head then kit.header_delete(a.head) end
	if a.right then gui.delete_node(a.right.node) end
	if a.low then gui.delete_node(a.low.node) end
	a.buttons = {}
	-- the frame of the devil's place (ui/kit.lua): the title, the way back at the
	-- bottom left, the wallet; the devil with its plate and the loadouts on the left
	a.head = kit.header(a.buttons, common.armory, KC.PURPLE, "indietro", a.from or common.home)
	a.wallet = coins.wallet(a.prof.scaglie, a.prof.ossidiana, kit.group(a.head.top_right, 1110, 44).node, 0, 0)
	a.right = kit.anchor(1280, 720, gui.ANCHOR_RIGHT, gui.ANCHOR_BOTTOM)
	a.low = kit.anchor(0, 720, gui.ANCHOR_LEFT, gui.ANCHOR_BOTTOM)
	a.radice = ui.root()
	a.kg = { node = a.radice, ox = 0, oy = 720 }
	profile_tabs.devil(a)
	profile_tabs.loadouts(a)
	a.pieces.prof, a.pieces.buttons, a.pieces.kg, a.pieces.right = a.prof, a.buttons, a.kg, a.right
	pieces.build(a.pieces)
	statistics(a)
end

function M.new(prof, from)
	local a = { prof = prof, pieces = {}, colore = ui.C.SQUADRA[1], from = from }
	-- the game world darkened behind, the rays from the devil, in its place's color
	a.back = kit.scene(profile_tabs.devil_x(), profile_tabs.DEVIL_Y, { accent = KC.PURPLE })
	build(a)
	return a
end

-- button actions: "kind:argument[:other]"
local function run_cmd(a, ui_action)
	local kind, x = ui_action:match("^(%a+):?([^:]*)")
	if kind == "assetto" then
		a.prof.is_active = tonumber(x)
	elseif kind == "pezzo" or kind == "indossa" or kind == "potenzia" or kind == "banco" or kind == "merce"
		or kind == "compra" or kind == "buono" then
		local _, step, bought = pieces.run(a.pieces, kind, x)
		if bought then sound.play("#scaglia") end
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
		end, a.colore)
		a.step = nil
	end
end

function M.update(a, dt)
	if a.figure then scoria.update(a.figure, dt, a.st) end
	if a.scene and not step_scene.update(a.scene, dt) then
		step_scene.delete(a.scene)
		a.scene = nil
	end
end

function M.on_input(a, action_id, action)
	-- the step's scene: a tap skips it
	if a.scene then
		if (action_id == ui.TOUCH or action_id == ui.PAD) and action.pressed then step_scene.skip(a.scene) end
		return nil
	end
	local ui_action = ui.touch(a.buttons, action_id, action)
	if ui_action == "indietro" then return "indietro" end
	if ui_action then run_cmd(a, ui_action) end
	return nil
end

function M.destroy(a)
	if a.scene then step_scene.delete(a.scene) end
	kit.header_delete(a.head)
	gui.delete_node(a.right.node)
	gui.delete_node(a.low.node)
	gui.delete_node(a.radice)
	kit.scene_drop(a.back)
end

return M
