-- Settings (the wheel at the top right of the home, docs/impostazioni.md):
-- the aim mode, how you fire and dose power with the controller, and the
-- controller buttons in battle (Sergio, 30 Oct: "la rimappatura dei pulsanti
-- me la metti nelle impostazioni"). You pick a command (by tapping or with the
-- controller light and A), then press the new button: the command that had it
-- takes the one left free (controller.assign). Y on the lit row removes the
-- button; Start cancels and stays on the wheel; RIPRISTINA goes back to
-- Sergio's mapping. Everything is saved to the profile at once.
--
--   local impostazioni = require "menu.settings"
--   local s = impostazioni.new(p, ctrl)         -- p the profile, ctrl the controller (ui/controller.lua)
--   impostazioni.on_input(s, action_id, action) -- "indietro" or nil
--     (buttons arrive as ui.PAD with action.nome, the button pressed)
--   impostazioni.destroy(s)

local ui = require "ui.ui"
local backdrop = require "ui.backdrop"
local glyph = require "ui.glyph"
local controller = require "ui.controller"
local profile = require "menu.profile"
local T = require("lang.text").settings

local M = {}

local NAMES = T.commands
-- a setting with its values: { id, name, { { value, name }, ... } }
local function choice_of(id, values)
	local list = {}
	for i, v in ipairs(values) do list[i] = { v, T.values[v] } end
	return { id, T.choices[id], list }
end
-- the choices at the top, side by side (profilo.SETTINGS, docs/impostazioni.md)
local CHOICES = {
	choice_of("mira", { "lancetta", "mirino" }),
	choice_of("sparo", { "pressione", "rilascio" }),
	choice_of("potenza", { "levetta", "grilletto" }),
	choice_of("levette", { "destra", "sinistra" }),
}
-- the frame counter (ui/frames.lua, docs/prestazioni.md), at the top right
local FPS = choice_of("fps", { "spento", "acceso" })
-- the choice groups: distance between centers and width of each choice
local GROUP, CHOICE_W = 306, 145
-- two columns of commands
local ROW_W, ROW_H, ROW_STEP = 470, 48, 54
local COLUMNS = { 395, 885 }
local FIRST_ROW = 440

local function build(s)
	-- the controller light stays on the same button
	local lit = s.buttons and ui.lit_up(s.buttons)
	lit = lit and lit.ui_action
	if s.radice then gui.delete_node(s.radice) end
	s.buttons, s.glyphs = {}, {}
	s.radice = ui.root()
	local C = ui.C
	-- the header (ui.header): IMPOSTAZIONI, the pill's place, the FPS counter on the right
	ui.header_delete(s.head)
	s.head = ui.header(s.buttons, T.title, "indietro")

	local function choice(sc, cx, y, w, h, parent)
		ui.text(sc[2], cx, y + h / 2 + 18, 0.5, C.OFF, parent)
		local v = profile.setting(s.p, sc[1])
		for i, m in ipairs(sc[3]) do
			ui.tab(s.buttons, cx + (i - 1.5) * (w + 6), y, w, h, m[2], sc[1] .. ":" .. m[1], v == m[1], parent)
		end
	end
	for k, sc in ipairs(CHOICES) do
		choice(sc, 640 + (k - (#CHOICES + 1) / 2) * GROUP, ui.CONTENT_TOP - 56, CHOICE_W, 52, s.radice)
	end
	choice(FPS, -ui.EDGE - 121, -10, 118, 44, s.head.right)

	ui.text(T.controller_keys, 640, 488, 0.7, C.OFF, s.radice)
	local n = #controller.COMMANDS
	local per_column = math.ceil(n / 2)
	for i, cmd in ipairs(controller.COMMANDS) do
		local col = i <= per_column and 1 or 2
		local riga = (i - 1) % per_column
		local x, y = COLUMNS[col], FIRST_ROW - riga * ROW_STEP
		local gui_node = ui.button(s.buttons, x, y, ROW_W, ROW_H, "", "tasto:" .. cmd, nil, s.radice)
		local nome = ui.text(NAMES[cmd], -ROW_W / 2 + 22, 0, 0.8, C.TEXT, gui_node)
		gui.set_pivot(nome, gui.PIVOT_W)
		if s.attesa == cmd then
			local premi = ui.text(T.press_a_key, ROW_W / 2 - 22, 0, 0.7, C.BRACE, gui_node)
			gui.set_pivot(premi, gui.PIVOT_E)
			ui.sheet_active(s.buttons[#s.buttons], true)
		elseif controller.key_of(s.c, cmd) then
			local g = glyph.new(gui_node, 30)
			glyph.display(g, s.c, controller.key_of(s.c, cmd))
			gui.set_position(g.radice, vmath.vector3(ROW_W / 2 - 22 - glyph.width(g) / 2, 0, 0))
		else
			local nobody = ui.text(cmd == "salta" and T.stick_up:format(T.sides[controller.side("muove")]) or T.no_key, ROW_W / 2 - 22, 0, 0.6,
				C.OFF, gui_node)
			gui.set_pivot(nobody, gui.PIVOT_E)
		end
	end

	local riga = FIRST_ROW - per_column * ROW_STEP
	ui.button(s.buttons, COLUMNS[2] + ROW_W / 2 - 150, riga - 4, 300, 56, T.reset, "ripristina", nil, s.radice)
	local help = s.attesa and T.cancel:format(controller.name(s.c, "start"))
		or (s.c.connected and T.change_remove:format(controller.name(s.c, "a"), controller.name(s.c, "y"))
		or T.connect)
	local t = ui.text(help, COLUMNS[1] - ROW_W / 2, riga - 4, 0.62, C.OFF, s.radice)
	gui.set_pivot(t, gui.PIVOT_W)
	for _, b in ipairs(s.buttons) do
		if b.ui_action == lit then ui.light(s.buttons, b) end
	end
end

function M.new(p, c)
	local s = { p = p, c = c }
	controller.levette = profile.setting(p, "levette")
	s.fondo = backdrop.new("banco")
	build(s)
	return s
end

local function save(s)
	profile.set(s.p, "tasti", controller.to_save(s.c))
	profile.save(s.p)
end

function M.on_input(s, action_id, action)
	-- waiting for the new button: the controller's first button (not the sticks)
	if s.attesa and action_id == ui.PAD then
		if not (action.pressed and action.nome) or action.levetta then return nil end
		if action.nome ~= "start" and controller.assign(s.c, s.attesa, action.nome) then save(s) end
		s.attesa = nil
		build(s)
		return nil
	end
	-- Y on the lit row: the command is left without a button
	if action_id == ui.PAD and action.pressed and action.ui == "scheda" then
		local b = ui.lit_up(s.buttons)
		local cmd = b and b.ui_action:match("^tasto:(.*)$")
		if cmd then
			controller.remove(s.c, cmd)
			save(s)
			build(s)
		end
		return nil
	end
	local ui_action = ui.touch(s.buttons, action_id, action)
	if not ui_action then return nil end
	if ui_action == "indietro" then return "indietro" end
	if ui_action == "ripristina" then
		controller.base(s.c)
		save(s)
		s.attesa = nil
	else
		local kind, value = ui_action:match("^(%a+):(.*)$")
		if kind == "tasto" then
			s.attesa = s.attesa ~= value and value or nil
		else
			profile.set(s.p, kind, value)
			profile.save(s.p)
		end
	end
	controller.levette = profile.setting(s.p, "levette")
	build(s)
	return nil
end

function M.destroy(s)
	ui.header_delete(s.head)
	gui.delete_node(s.radice)
	gui.delete_node(s.fondo)
end

return M
