-- Settings (the wheel at the top right of the home, docs/impostazioni.md):
-- the aim mode, how you fire and dose power with the controller, and the
-- controller buttons in battle (Sergio, 30 Oct: "la rimappatura dei pulsanti
-- me la metti nelle impostazioni"). You pick a command (by tapping or with the
-- controller light and A), then press the new button: the command that had it
-- takes the one left free (controller.assegna). Y on the lit row removes the
-- button; Start cancels and stays on the wheel; RIPRISTINA goes back to
-- Sergio's mapping. Everything is saved to the profile at once.
--
--   local impostazioni = require "menu.settings"
--   local s = impostazioni.new(p, ctrl)         -- p the profile, ctrl the controller (ui/controller.lua)
--   impostazioni.on_input(s, action_id, action) -- "indietro" or nil
--     (buttons arrive as ui.PAD with action.nome, the button pressed)
--   impostazioni.destroy(s)

local ui = require "ui.ui"
local glyph = require "ui.glyph"
local controller = require "ui.controller"
local profile = require "menu.profile"

local M = {}

local NAMES = {
	spara = "SPARA", salta = "SALTA", primaria = "PRIMARIA DOPO", secondaria = "SECONDARIA DOPO", teletrasporto = "TELETRASPORTO",
	rampino = "RAMPINO", paracadute = "PARACADUTE", oggetti = "OGGETTO DOPO", usa_oggetto = "USA L'OGGETTO",
	baratto = "BARATTO", zoom = "ZOOM",
}
-- the choices at the top, side by side (profilo.SETTINGS, docs/impostazioni.md)
local CHOICES = {
	{ "mira", "MIRA", { { "lancetta", "LANCETTA" }, { "mirino", "MIRINO" } } },
	{ "sparo", "SPARO COL CONTROLLER", { { "pressione", "PREMENDO" }, { "rilascio", "LASCIANDO" } } },
	{ "potenza", "POTENZA COL CONTROLLER", { { "levetta", "LEVETTA" }, { "grilletto", "GRILLETTO" } } },
	{ "levette", "LEVETTA CHE MUOVE", { { "destra", "DESTRA" }, { "sinistra", "SINISTRA" } } },
}
-- the frame counter (ui/frames.lua, docs/prestazioni.md), at the top right
local FPS = { "fps", "CONTATORE FPS", { { "spento", "SPENTO" }, { "acceso", "ACCESO" } } }
-- the choice groups: distance between centers and width of each choice
local GROUP, CHOICE_W = 312, 148
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
	s.radice = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(0, 0, 0))
	gui.set_visible(s.radice, false)
	local C = ui.C
	ui.indietro(s.buttons, "indietro", s.radice)
	ui.titolo("IMPOSTAZIONI", 640, 650, 1, C.TEXT, s.radice)

	local function choice(sc, cx, y, w)
		ui.testo(sc[2], cx, y + 44, 0.5, C.OFF, s.radice)
		local v = profile.setting(s.p, sc[1])
		for i, m in ipairs(sc[3]) do
			ui.scheda(s.buttons, cx + (i - 1.5) * (w + 6), y, w, 52, m[2], sc[1] .. ":" .. m[1], v == m[1], s.radice)
		end
	end
	for k, sc in ipairs(CHOICES) do
		choice(sc, 640 + (k - (#CHOICES + 1) / 2) * GROUP, 542, CHOICE_W)
	end
	choice(FPS, 1110, 628, 118)

	ui.testo("TASTI DEL CONTROLLER", 640, 488, 0.7, C.OFF, s.radice)
	local n = #controller.COMMANDS
	local per_column = math.ceil(n / 2)
	for i, cmd in ipairs(controller.COMMANDS) do
		local col = i <= per_column and 1 or 2
		local riga = (i - 1) % per_column
		local x, y = COLUMNS[col], FIRST_ROW - riga * ROW_STEP
		local gui_node = ui.button(s.buttons, x, y, ROW_W, ROW_H, "", "tasto:" .. cmd, nil, s.radice)
		local nome = ui.testo(NAMES[cmd], -ROW_W / 2 + 22, 0, 0.8, C.TEXT, gui_node)
		gui.set_pivot(nome, gui.PIVOT_W)
		if s.attesa == cmd then
			local premi = ui.testo("PREMI UN TASTO", ROW_W / 2 - 22, 0, 0.7, C.BRACE, gui_node)
			gui.set_pivot(premi, gui.PIVOT_E)
			ui.sheet_active(s.buttons[#s.buttons], true)
		elseif controller.key_of(s.c, cmd) then
			local g = glyph.new(gui_node, 30)
			glyph.display(g, s.c, controller.key_of(s.c, cmd))
			gui.set_position(g.radice, vmath.vector3(ROW_W / 2 - 22 - glyph.largo(g) / 2, 0, 0))
		else
			local nobody = ui.testo(cmd == "salta" and ("LEVETTA " .. string.upper(controller.lato("muove")) .. " IN SU") or "NESSUN TASTO", ROW_W / 2 - 22, 0, 0.6,
				C.OFF, gui_node)
			gui.set_pivot(nobody, gui.PIVOT_E)
		end
	end

	local riga = FIRST_ROW - per_column * ROW_STEP
	ui.button(s.buttons, COLUMNS[2] + ROW_W / 2 - 150, riga - 4, 300, 56, "RIPRISTINA", "ripristina", nil, s.radice)
	local help = s.attesa and (controller.nome(s.c, "start") .. " ANNULLA")
		or (s.c.connected and (controller.nome(s.c, "a") .. " CAMBIA IL TASTO, " .. controller.nome(s.c, "y") .. " LO TOGLIE")
		or "COLLEGA UN CONTROLLER PER CAMBIARE I TASTI")
	local t = ui.testo(help, COLUMNS[1] - ROW_W / 2, riga - 4, 0.62, C.OFF, s.radice)
	gui.set_pivot(t, gui.PIVOT_W)
	for _, b in ipairs(s.buttons) do
		if b.ui_action == lit then ui.luce(s.buttons, b) end
	end
end

function M.new(p, c)
	local s = { p = p, c = c }
	controller.levette = profile.setting(p, "levette")
	s.fondo = ui.sfondo()
	build(s)
	return s
end

local function save(s)
	profile.imposta(s.p, "tasti", controller.to_save(s.c))
	profile.salva(s.p)
end

function M.on_input(s, action_id, action)
	-- waiting for the new button: the controller's first button (not the sticks)
	if s.attesa and action_id == ui.PAD then
		if not (action.pressed and action.nome) or action.levetta then return nil end
		if action.nome ~= "start" and controller.assegna(s.c, s.attesa, action.nome) then save(s) end
		s.attesa = nil
		build(s)
		return nil
	end
	-- Y on the lit row: the command is left without a button
	if action_id == ui.PAD and action.pressed and action.ui == "scheda" then
		local b = ui.lit_up(s.buttons)
		local cmd = b and b.ui_action:match("^tasto:(.*)$")
		if cmd then
			controller.togli(s.c, cmd)
			save(s)
			build(s)
		end
		return nil
	end
	local ui_action = ui.tocco(s.buttons, action_id, action)
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
			profile.imposta(s.p, kind, value)
			profile.salva(s.p)
		end
	end
	controller.levette = profile.setting(s.p, "levette")
	build(s)
	return nil
end

function M.destroy(s)
	gui.delete_node(s.radice)
	gui.delete_node(s.fondo)
end

return M
