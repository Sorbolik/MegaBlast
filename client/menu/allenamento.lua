-- Training (the home's ALLENAMENTO button): a match on the same phone against
-- the bots (sim/bot.lua), with the mode (the player is always the first robot;
-- in 2 vs 2 the teammate is a bot) and the level. The lessons live in the
-- campaign (menu/campagna.lua, Chapter 0). Style in ui/ui.lua.
--
--   local allenamento = require "menu.allenamento"
--   local a = allenamento.new(scelta)  -- scelta = { modo, livello } (the last one)
--   local fine = allenamento.on_input(a, action_id, action)
--     -- "indietro", { modo = ..., livello = ... } to play against the bots, or nil
--   allenamento.destroy(a)

local ui = require "ui.ui"

local M = {}

local MODES_LIST = { { "1v1", "1 CONTRO 1" }, { "2v2", "2 CONTRO 2" }, { "ffa", "TUTTI CONTRO TUTTI" } }
local LEVELS = { { "facile", "FACILE" }, { "normale", "NORMALE" }, { "difficile", "DIFFICILE" } }

local function vec(x, y) return vmath.vector3(x, y, 0) end

local function build(a)
	if a.radice then gui.delete_node(a.radice) end
	a.buttons = {}
	a.radice = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_visible(a.radice, false)
	local c = ui.C
	ui.indietro(a.buttons, "indietro", a.radice)
	ui.titolo("ALLENAMENTO", 640, 640, 1, c.TEXT, a.radice)
	ui.testo("MODO", 640, 520, 0.7, c.OFF, a.radice)
	for i, m in ipairs(MODES_LIST) do
		ui.scheda(a.buttons, 640 + (i - 2) * 330, 460, 310, 64, m[2], "modo:" .. m[1], a.scelta.modo == m[1], a.radice)
	end
	ui.testo("BOT", 640, 360, 0.7, c.OFF, a.radice)
	for i, l in ipairs(LEVELS) do
		ui.scheda(a.buttons, 640 + (i - 2) * 250, 300, 230, 64, l[2], "livello:" .. l[1], a.scelta.livello == l[1], a.radice)
	end
	ui.button(a.buttons, 640, 140, 340, 108, "GIOCA", "gioca", { main = true }, a.radice)
end

function M.new(choice)
	local a = { scelta = choice }
	a.fondo = ui.sfondo()
	build(a)
	return a
end

function M.on_input(a, action_id, action)
	local ui_action = ui.tocco(a.buttons, action_id, action)
	if not ui_action then return nil end
	if ui_action == "indietro" then return "indietro" end
	if ui_action == "gioca" then return { modo = a.scelta.modo, livello = a.scelta.livello } end
	local kind, value = ui_action:match("^(%a+):(.*)$")
	a.scelta[kind] = value
	build(a)
	return nil
end

function M.destroy(a)
	gui.delete_node(a.radice)
	gui.delete_node(a.fondo)
end

return M
