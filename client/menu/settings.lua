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
-- IL MIO PROFILO (top right, Sergio, 19 Nov: step 6 of the guest profiles) turns
-- the right panel into the profile's: its name and the recovery code to write
-- down (NUOVO CODICE: another, the old one stops working), and HO GIÀ UN
-- PROFILO: the code typed on a keypad of its letters (the controller and the
-- web too, no system keyboard), RECUPERA brings that profile to this phone.
--
--   local s = impostazioni.new(p, ctrl, acc)    -- p the profile, ctrl the controller (ui/controller.lua),
--                                               -- acc main/account.lua (identity, code, recover; nil: none)
--   impostazioni.on_input(s, action_id, action) -- "indietro" or nil
--     (buttons arrive as ui.PAD with action.nome, the button pressed)
--   impostazioni.destroy(s)

local ui = require "ui.ui"
local glyph = require "ui.glyph"
local controller = require "ui.controller"
local profile = require "menu.profile"
local kit = require "ui.kit"
local T = require("lang.text").settings
local common = require("lang.text").common

local M = {}

local NAMES = T.commands
-- a setting with its values: { id, name, { { value, name }, ... } }
local function choice_of(id, values)
	local list = {}
	for i, v in ipairs(values) do list[i] = { v, T.values[v] } end
	return { id, T.choices[id], list }
end
-- the choices on the left, one under the other (profilo.SETTINGS,
-- docs/impostazioni.md); the last is the frame counter (ui/frames.lua, docs/prestazioni.md)
local CHOICES = {
	choice_of("mira", { "lancetta", "mirino" }),
	choice_of("sparo", { "pressione", "rilascio" }),
	choice_of("potenza", { "levetta", "grilletto" }),
	choice_of("levette", { "sinistra", "destra" }),
	choice_of("fps", { "spento", "acceso" }),
	-- the end-game test profile (menu/profile.lua, endgame): its own save
	choice_of("profilo", { "vero", "prova" }),
	-- (its third value on a row of its own: three do not fit at 16 px)
	choice_of("profilo_zero", { "risorse" }),
}
local KC = kit.C
-- the grid: the names of the choices NAME_W wide on the left, then their values;
-- the controller's commands on a panel like the choices' (Sergio, 17 Nov), its
-- title and its help line inside: two columns of cards KEY_W wide from KEYS_X,
-- KEY_GAP apart, a row every KEY_ROW
local NAME_W = 196
-- (a row every ROW: seven rows above the bottom line)
local ROW = 66
local PANEL_Y, PANEL_H = 108, #CHOICES * ROW + 6
local KEYS_PANEL_X, KEYS_PANEL_W = 608, 640
local KEYS_X, KEY_W, KEY_H, KEY_GAP = KEYS_PANEL_X + 16, 298, 54, 12
local KEYS_Y, KEY_ROW = 154, 62
-- the profile's panel: the inner width (two key cards and their gap), the
-- recovery code's letters (server/recovery.go) on a keypad of PAD_COLS columns
local INNER_W = 2 * KEY_W + KEY_GAP
local LETTERS = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"
local CODE_LEN = 12
local PAD_COLS, PAD_GAP = 7, 6
local PAD_W = (INNER_W - (PAD_COLS - 1) * PAD_GAP) / PAD_COLS
local PAD_H, PAD_ROW = 40, 46

-- the typed letters as the code is shown, in groups of four; the empty places as dots
local function shown(typed)
	local out = {}
	for i = 1, CODE_LEN do
		out[#out + 1] = i <= #typed and typed:sub(i, i) or "·"
		if i % 4 == 0 and i < CODE_LEN then out[#out + 1] = "-" end
	end
	return table.concat(out)
end

-- a text that must stay inside room pixels: smaller if it doesn't
local function fit(t, room)
	local wide = kit.width(t)
	if wide > room then
		local sc = gui.get_scale(t)
		gui.set_scale(t, vmath.vector3(sc.x * room / wide, sc.y * room / wide, 1))
	end
	return t
end

-- The right panel as the profile's: its name and code, or the keypad
local function profile_panel(s, g)
	local x, top = KEYS_X, PANEL_Y
	local bottom_line = PANEL_Y + PANEL_H - 24
	local acc = s.acc
	local test = profile.test ~= nil and profile.test ~= false
	if s.view == "mio" then
		kit.text(g, T.my_profile, x, top + 32, 17, KC.HOT_TOP, "start", 1.5)
		local id = acc and acc.identity()
		fit(kit.text(g, id and id.nome and id.nome:upper() or T.no_profile, x, top + 86, 30, KC.SAND, "start", 1), INNER_W)
		kit.text(g, T.code_label, x, top + 132, 16, KC.MUTE, "start", 1)
		local card = kit.card(g, x, top + 146, INNER_W, 70, KC.PURPLE)
		local what, color = s.code, KC.SAND
		if test then
			what, color = T.code_test, KC.MUTE
		elseif not what then
			what, color = s.code_why == "rete" and T.need_network or T.code_asking, KC.MUTE
		end
		local big = s.code ~= nil and not test
		fit(kit.text(card.g, what, x + INNER_W / 2, top + 146 + (big and 47 or 42), big and 36 or 20, color, "middle",
			big and 4 or 1), INNER_W - 40)
		kit.text(g, T.code_help, x, top + 248, 16, KC.MUTE, "start", 1)
		fit(kit.text(g, T.code_help2, x, top + 270, 16, KC.MUTE, "start", 1), INNER_W)
		local off = test or not acc
		local again = kit.secondary(g, T.new_code, x, top + 300, KEY_W, KEY_H, { off = off })
		if not off then kit.button(s.buttons, again, "profilo_mio:nuovo") end
		local have = kit.secondary(g, T.have_profile, x + KEY_W + KEY_GAP, top + 300, KEY_W, KEY_H, { off = off })
		if not off then kit.button(s.buttons, have, "profilo_mio:recupera") end
		fit(kit.text(g, T.code_old, x, bottom_line, 16, KC.MUTE, "start", 1), INNER_W)
		return
	end
	-- HO GIÀ UN PROFILO: the code typed on the keypad
	kit.text(g, T.have_profile, x, top + 32, 17, KC.HOT_TOP, "start", 1.5)
	local card = kit.card(g, x, top + 46, INNER_W, 58, KC.PURPLE, { sel = #s.typed < CODE_LEN })
	kit.text(card.g, shown(s.typed), x + INNER_W / 2, top + 46 + 40, 32, KC.SAND, "middle", 4)
	-- (31 letters: four rows of seven, then three and CANCELLA as wide as the rest of the row)
	for i = 1, #LETTERS + 1 do
		local col, row = (i - 1) % PAD_COLS, math.floor((i - 1) / PAD_COLS)
		local kx, ky = x + col * (PAD_W + PAD_GAP), top + 118 + row * PAD_ROW
		local letter = LETTERS:sub(i, i)
		local kw = letter ~= "" and PAD_W or x + INNER_W - kx
		local full = #s.typed >= CODE_LEN
		local off = letter ~= "" and full or letter == "" and #s.typed == 0
		local key = kit.card(g, kx, ky, kw, PAD_H, KC.PURPLE, { off = off })
		if letter ~= "" then
			kit.text(key.g, letter, kx + PAD_W / 2, ky + 31, 22, off and KC.MUTE or KC.SAND, "middle", 1)
		else
			-- the last key takes the last letter away
			kit.text(key.g, T.delete, kx + kw / 2, ky + 30, 18, off and KC.MUTE or KC.SAND, "middle", 1)
		end
		if not off then kit.button(s.buttons, key, "lettera:" .. (letter ~= "" and letter or "via")) end
	end
	local by = top + 118 + 4 * PAD_ROW + PAD_H + 16
	local cancel = kit.secondary(g, T.cancel_recover, x, by, KEY_W, KEY_H)
	kit.button(s.buttons, cancel, "profilo_mio:annulla")
	local ready = #s.typed == CODE_LEN and not s.asking
	local go = kit.secondary(g, T.recover, x + KEY_W + KEY_GAP, by, KEY_W, KEY_H, { off = not ready })
	if ready then kit.button(s.buttons, go, "profilo_mio:vai") end
	local line, color = T.recover_help, KC.MUTE
	if s.asking then
		line, color = T.recovering, KC.HOT_TOP
	elseif s.recover_why then
		line, color = T.recover_errors[s.recover_why] or T.need_network, KC.RED
	end
	fit(kit.text(g, line, x, bottom_line, 16, color, "start", 1), INNER_W)
end

local function build(s)
	-- the controller light stays on the same button
	local lit = s.buttons and ui.lit_up(s.buttons)
	lit = lit and lit.ui_action
	if s.radice then gui.delete_node(s.radice) end
	if s.head then kit.header_delete(s.head) end
	s.buttons, s.glyphs = {}, {}
	s.head = kit.header(s.buttons, T.title, KC.STEEL, "indietro", common.home)
	s.radice = ui.root()
	local g = { node = s.radice, ox = 0, oy = 720 }
	-- IL MIO PROFILO above the right panel, at its right edge (on 20:9 too); on
	-- the profile's panel the same place goes back to the controller's buttons
	local top_w = 300
	local swap = kit.secondary(g, s.view and T.controller_keys or T.my_profile,
		KEYS_PANEL_X + KEYS_PANEL_W - top_w, 36, top_w, KEY_H)
	kit.button(s.buttons, swap, "profilo_mio:scambia")

	-- the choices on an iron panel: their names are read on it, not on the painting
	kit.panel(kit.group(g, 32 + (NAME_W + 12 + 340 + 16) / 2, PANEL_Y + PANEL_H / 2).node,
		NAME_W + 12 + 340 + 16, PANEL_H)
	for i, sc in ipairs(CHOICES) do
		local v = profile.setting(s.p, sc[1])
		if sc[1] == "profilo" or sc[1] == "profilo_zero" then v = profile.test or "vero" end
		local opts, on = {}, sc[1]:find("^profilo") and 0 or 1
		for k, m in ipairs(sc[3]) do
			opts[k] = { m[2], (sc[1] == "profilo_zero" and "profilo" or sc[1]) .. ":" .. m[1] }
			if v == m[1] then on = k end
		end
		-- a row each on one grid (Sergio, 15 Nov: every text in its place, never under a
		-- button): the name on the left, on two lines when it is long, its values on the right
		local y = 114 + (i - 1) * ROW
		local name, second = sc[2], nil
		local probe = kit.text(g, name, 48, y + 35, 16, KC.SAND, "start", 1)
		if kit.width(probe) > NAME_W then
			gui.delete_node(probe)
			local cut = name:find(" ", math.floor(#name / 2) - 3, true) or name:find(" ", 1, true)
			name, second = name:sub(1, cut - 1), name:sub(cut + 1)
			kit.text(g, name, 48, y + 25, 16, KC.SAND, "start", 1)
			kit.text(g, second, 48, y + 45, 16, KC.SAND, "start", 1)
		end
		kit.choice(g, s.buttons, 48 + NAME_W + 8, y, "", opts, on, 170)
	end

	-- the controller's buttons: two columns of commands on their panel
	kit.panel(kit.group(g, KEYS_PANEL_X + KEYS_PANEL_W / 2, PANEL_Y + PANEL_H / 2).node, KEYS_PANEL_W, PANEL_H)
	if s.view then
		profile_panel(s, g)
		for _, b in ipairs(s.buttons) do
			if b.ui_action == lit then ui.light(s.buttons, b) end
		end
		return
	end
	kit.text(g, T.controller_keys, KEYS_X, PANEL_Y + 32, 17, KC.HOT_TOP, "start", 1.5)
	local n = #controller.COMMANDS
	local per_column = math.ceil(n / 2)
	for i, cmd in ipairs(controller.COMMANDS) do
		local col = i <= per_column and 0 or 1
		local row = (i - 1) % per_column
		local x, y = KEYS_X + col * (KEY_W + KEY_GAP), KEYS_Y + row * KEY_ROW
		local cur = s.attesa == cmd
		local k = kit.card(g, x, y, KEY_W, KEY_H, cur and KC.HOT or KC.PURPLE, { sel = cur })
		kit.text(k.g, NAMES[cmd], x + 20, y + 34, 19, KC.SAND)
		if cur then
			kit.text(k.g, T.press_a_key, x + KEY_W - 20, y + 33, 16, KC.HOT_TOP, "end", 1)
		elseif controller.key_of(s.c, cmd) then
			local gl = glyph.new(k.node, 36)
			glyph.display(gl, s.c, controller.key_of(s.c, cmd))
			gui.set_position(gl.radice, vmath.vector3(KEY_W / 2 - 20 - glyph.width(gl) / 2, 0, 0))
		else
			kit.text(k.g, cmd == "salta" and T.stick_up:format(T.sides[controller.side("muove")]) or T.no_key,
				x + KEY_W - 20, y + 33, 16, KC.MUTE, "end", 1)
		end
		kit.button(s.buttons, k, "tasto:" .. cmd)
	end

	local help = s.attesa and T.cancel:format(controller.name(s.c, "start"))
		or (s.c.connected and T.change_remove:format(controller.name(s.c, "a"), controller.name(s.c, "y"))
		or T.connect)
	local t = kit.text(g, help, KEYS_X, PANEL_Y + PANEL_H - 24, 16, KC.MUTE, "start", 1)
	local wide, room = kit.width(t), 2 * KEY_W + KEY_GAP
	if wide > room then
		local sc = gui.get_scale(t)
		gui.set_scale(t, vmath.vector3(sc.x * room / wide, sc.y * room / wide, 1))
	end
	-- (where the second column ends)
	local rx, ry = KEYS_X + KEY_W + KEY_GAP, KEYS_Y + (per_column - 1) * KEY_ROW
	local reset = kit.plate(g, rx, ry - 1, KEY_W, KEY_H + 2, KC.ROSE, { sk = 0, d = 6, piece = "piastrina" })
	kit.text(reset.g, T.reset, rx + KEY_W / 2, ry + 35, 21, KC.SAND, "middle", 0.5)
	kit.button(s.buttons, reset, "ripristina")
	for _, b in ipairs(s.buttons) do
		if b.ui_action == lit then ui.light(s.buttons, b) end
	end
end

function M.new(p, c, acc)
	local s = { p = p, c = c, acc = acc, typed = "" }
	controller.levette = profile.setting(p, "levette")
	s.scene = kit.scene(200, 400, { halo = 300, accent = KC.STEEL, bg = "banco" })
	-- which build this is, small on the bottom band at the right edge (Sergio, 18 Nov):
	-- the commit the Actions write in the build settings (apk.yml, tools/web/build.sh),
	-- none on a build made by hand in the editor
	s.version = kit.anchor(1280, 720, gui.ANCHOR_RIGHT, gui.ANCHOR_BOTTOM)
	local version = sys.get_config_string("megablast.version", "")
	kit.text(s.version, version == "" and T.version_local
		or (sys.get_config_int("megablast.test", 0) == 1 and T.version_test or T.version):format(version),
		1280 - 40, 713, 16, KC.MUTE, "end", 1)
	build(s)
	return s
end

-- the recovery code of the profile in use, from the server when fresh
local function ask_code(s, fresh)
	if not s.acc or (profile.test ~= nil and profile.test ~= false) then return end
	if fresh then s.code = nil end
	s.code_why = nil
	s.acc.code(fresh, function(code, why)
		if s.gone then return end
		s.code, s.code_why = code or s.code, why
		build(s)
	end)
end

-- IL MIO PROFILO's buttons and the keypad's letters
local function profile_action(s, mine, letter)
	if letter == "via" then
		s.typed = s.typed:sub(1, -2)
	elseif letter then
		if #s.typed < CODE_LEN then s.typed = s.typed .. letter end
	end
	if letter then
		s.recover_why = nil
		return
	end
	if mine == "scambia" then
		s.view = not s.view and "mio" or nil
		s.attesa = nil
		if s.view then ask_code(s, false) end
	elseif mine == "nuovo" then
		ask_code(s, true)
	elseif mine == "recupera" then
		s.view, s.typed, s.recover_why = "recupera", "", nil
	elseif mine == "annulla" then
		s.view = "mio"
	elseif mine == "vai" and s.acc and #s.typed == CODE_LEN and not s.asking then
		s.asking, s.recover_why = true, nil
		s.acc.recover(s.typed, function(ok, why)
			if s.gone then return end
			s.asking = false
			if ok then
				-- the profile of the code is this phone's now: its name and code
				s.view, s.typed, s.code = "mio", "", nil
				ask_code(s, false)
			else
				s.recover_why = why
			end
			build(s)
		end)
	end
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
	local mine = ui_action:match("^profilo_mio:(.*)$")
	local letter = ui_action:match("^lettera:(.*)$")
	if mine or letter then
		profile_action(s, mine, letter)
		build(s)
		return nil
	end
	if ui_action == "ripristina" then
		controller.base(s.c)
		save(s)
		s.attesa = nil
	else
		local kind, value = ui_action:match("^(%a+):(.*)$")
		if kind == "tasto" then
			s.attesa = s.attesa ~= value and value or nil
		elseif kind == "profilo" then
			profile.choose_test(s.p, value ~= "vero" and value)
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
	s.gone = true
	kit.header_delete(s.head)
	gui.delete_node(s.radice)
	gui.delete_node(s.version.node)
	kit.scene_drop(s.scene)
end

return M
