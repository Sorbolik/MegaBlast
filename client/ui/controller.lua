-- Controller (gamepad) over Bluetooth or USB: Xbox, PlayStation and generic,
-- on Android phones, on the computer and in the browser. Only the button
-- reading lives here, without GUI nodes, so it is tested with luajit
-- (tests/battaglia_test.lua); what each button does is decided by
-- game.gui_script (docs/controller.md).
--
-- The controllers Defold knows (/builtins/input/default.gamepads) arrive as
-- pad_* actions of input/game.input_binding. Those it doesn't know only give
-- the raw action pad_grezzo: on Android and in the browser the buttons have
-- the same order for everyone (Android numbers them from the standard codes,
-- the browser follows the "standard gamepad"), so we read them from there.
--
--   local controller = require "ui.controller"
--   local c = controller.new(fix)                -- fix: sys.get_sys_info().system_name
--   local ev = controller.input(c, action_id, action)
--   -- nil: not a controller action. Otherwise the list of buttons that
--   -- change: { nome = "a", held_down = true } (held_down false: released); nome
--   -- "a" "b" "x" "y" "lb" "rb" "lt" "rt" "start" "select", the d-pad "su" "giu"
--   -- "sinistra" "destra" and the left stick pushed past halfway, like the d-pad
--   -- but with levetta = true. ui = the same thing for the menus (ui.tocco).
--   c.sx, c.dx                                    -- the sticks: { x, y }, y up, length at most 1
--   c.giu[nome]                                   -- is the button held?
--   controller.comando(c, button_key) / key_of(c, comando) -- the battle mapping (c.tasti)
--   controller.assegna(c, comando, button_key)    -- from the settings: the two commands swap buttons
--   controller.usa(c, keys) / to_save(c) / base(c) -- the profile's mapping, to save, Sergio's one
--   controller.nome(c, button_key)                -- what it is called on this controller ("A", "CROCE", "ZR"...)
--   controller.name_of(comando)                   -- the name of a command's button, on the controller in use
--   c.family                                      -- "xbox", "playstation" or "nintendo" (from the controller's name)
--   c.connected                                   -- there is (or has been) a controller
--   c.su                                          -- -1 where vertical axes arrive flipped (Android)
--   c.valore.lt, c.valore.rt                      -- how far the triggers are pressed (0..1)
--   controller.togli(c, comando)                  -- the command is left without a button

local T = require("lang.text").controller

local M = {}

-- half of a stick: { stick, axis, sign }
local AXES = {
	pad_sx_sinistra = { "sx", "x", -1 }, pad_sx_destra = { "sx", "x", 1 },
	pad_sx_su = { "sx", "y", 1 }, pad_sx_giu = { "sx", "y", -1 },
	pad_dx_sinistra = { "dx", "x", -1 }, pad_dx_destra = { "dx", "x", 1 },
	pad_dx_su = { "dx", "y", 1 }, pad_dx_giu = { "dx", "y", -1 },
}
local KEYS_LIST = { pad_a = "a", pad_b = "b", pad_x = "x", pad_y = "y", pad_lb = "lb", pad_rb = "rb",
	pad_lt = "lt", pad_rt = "rt", pad_start = "start", pad_select = "select",
	pad_su = "su", pad_giu = "giu", pad_sinistra = "sinistra", pad_destra = "destra" }
-- for the menus (ui.tocco): the d-pad and the stick move the light, A
-- confirms, B goes back, Y opens the card (instead of the long press), Start the menu
M.UI = { su = "su", giu = "giu", sinistra = "sinistra", destra = "destra", a = "conferma", b = "indietro",
	y = "scheda", start = "menu" }
-- In battle: button -> command, the default mapping (Sergio, 30 Oct). The
-- buttons are named after their place on the controller, as on Xbox: a is the
-- bottom one, b on the right, x on the left, y at the top. The sticks are
-- fixed and work as on the phone: the left one walks and, pushed up, jumps;
-- the right one aims (direction and power). Start always opens the wheel;
-- everything else is changed from the IMPOSTAZIONI (menu/settings.lua),
-- which save c.tasti in the profile.
M.BATTLE = {
	lb = "primaria",        -- the next primary, cycling
	rb = "secondaria",      -- the next secondary, cycling
	rt = "spara",           -- with the right stick's aim
	a = "teletrasporto",
	x = "rampino",
	y = "paracadute",
	lt = "oggetti",         -- the next item in the OGGETTI column, cycling
	giu = "usa_oggetto",    -- uses the lit one (d-pad down)
	b = "baratto",          -- skips the second attack (+1 teleport)
	start = "rotellina",
	select = "zoom",
}
-- the commands that can be changed, in the settings' order, and the buttons
-- that can be given. Jump has no button by default (you jump with the stick);
-- with a button the left stick stops jumping (Sergio, 30 Oct).
M.COMMANDS = { "spara", "salta", "primaria", "secondaria", "teletrasporto", "rampino", "paracadute", "oggetti",
	"usa_oggetto", "baratto", "zoom" }
M.FREE = { a = true, b = true, x = true, y = true, lb = true, rb = true, lt = true, rt = true, select = true,
	su = true, giu = true, sinistra = true, destra = true }

-- The controller's family, from the name the system gives: buttons are named
-- (and drawn) as on the real buttons. Nintendo has A on the right and B at
-- the bottom: same place, another name.
M.FAMILIES = T.families
M.CROSS = T.cross
-- (in this order: "Xbox Wireless Controller" is Xbox, a bare "Wireless
-- Controller" is the name Android gives the DualSense and the DualShock)
local RECOGNIZE = {
	{ "xbox", { "xbox", "x%-box", "xinput", "microsoft", "045e" } },
	{ "nintendo", { "nintendo", "switch", "joy%-con", "pro controller", "057e" } },
	{ "playstation", { "playstation", "dualsense", "dualshock", "sony", "wireless controller", "054c" } },
}
function M.family(nome)
	nome = string.lower(nome or "")
	for _, f in ipairs(RECOGNIZE) do
		for _, word in ipairs(f[2]) do
			if nome:find(word) then return f[1] end
		end
	end
	-- the others: with the Xbox names, the most common
	return "xbox"
end
-- the left stick counts as the d-pad past this push (and comes back below RETURN_T)
local PUSH_K, RETURN_T = 0.6, 0.4
-- analog triggers: pressed past half travel, released only below 20%.
-- Without this margin a trigger held around half travel flickered between
-- pressed and released, and a single press fired twice (first one weapon,
-- then the next one: Sergio, 30 Oct)
local TRIGGER, TRIGGER_BACK = 0.5, 0.2
local function held_down(c, nome, v)
	if nome == "lt" or nome == "rt" then return v > (c.giu[nome] and TRIGGER_BACK or TRIGGER) end
	return v > 0.5
end
-- dead zone of unknown controllers (for known ones Defold sets it)
local DEAD = 0.2
-- On Android a PlayStation controller shows up as three controllers: the
-- controller, the touchpad ("Wireless Controller Touchpad", which Defold knows
-- and translates with the controller's axes) and the motion sensors ("...
-- Motion Sensors", unknown: it comes from the raw ones). Their axes wrote on
-- the real controller's sticks and the aim jumped for a moment (Sergio, 30
-- Oct, "intorno ai 35 gradi"). These never count.
local FAKES = { "touchpad", "motion", "sensor", "accel", "gyro" }
local function fake(nome)
	nome = string.lower(nome or "")
	for _, word in ipairs(FAKES) do
		if nome:find(word) then return true end
	end
	return false
end

-- Unknown controllers: the button and axis numbers (from 0) in the raw
-- action. Android: the same as the Xbox and PlayStation controllers in
-- default.gamepads (axes 0-1 left stick, 2-3 right, 4-5 triggers, 6-7 the
-- d-pad; the d-pad also as buttons 11-14). Browser: the standard gamepad.
local RAW_LIST = {
	Android = { tasti = { a = 0, b = 1, x = 3, y = 6, lb = 4, rb = 5, start = 15, select = 16,
		su = 11, giu = 12, sinistra = 13, destra = 14 },
		axes = { sx = { 0, 1 }, dx = { 2, 3 }, lt = 4, rt = 5, cross = { 6, 7 } } },
	HTML5 = { tasti = { a = 0, b = 1, x = 2, y = 3, lb = 4, rb = 5, lt = 6, rt = 7, select = 8, start = 9,
		su = 12, giu = 13, sinistra = 14, destra = 15 },
		axes = { sx = { 0, 1 }, dx = { 2, 3 } } },
}

local RAW, CONNECTED = hash("pad_grezzo"), hash("pad_connesso")
local ACTIONS = {}
for nome, v in pairs(AXES) do ACTIONS[hash(nome)] = v end
local NAMES = {}
for nome, v in pairs(KEYS_LIST) do NAMES[hash(nome)] = v end

-- On Android the sticks arrive with the vertical axis flipped (tested by
-- Sergio with the phone, 30 Oct): down is up, for known and raw controllers
local UPSIDE_DOWN = { Android = true }

function M.new(fix)
	local c = { sx = { x = 0, y = 0 }, dx = { x = 0, y = 0 }, giu = {}, halves = {}, unknown = {},
		crude = { sx = { x = 0, y = 0 }, dx = { x = 0, y = 0 } },
		raw_ones = RAW_LIST[fix], ev = {}, finti = {}, su = UPSIDE_DOWN[fix] and -1 or 1, family = "xbox", tasti = {},
		valore = { lt = 0, rt = 0 } }
	for t, cmd in pairs(M.BATTLE) do c.tasti[t] = cmd end
	return c
end

function M.command(c, button_key)
	return c.tasti[button_key]
end

-- A command's button (nil if it has none), in a fixed order
local ORDER = { "a", "b", "x", "y", "lb", "rb", "lt", "rt", "start", "select", "su", "giu", "sinistra", "destra" }
function M.key_of(c, command)
	for _, t in ipairs(ORDER) do
		if c.tasti[t] == command then return t end
	end
end

-- Gives the button to the command; the command that had it takes the button
-- left free or, if the command had none, the first button nobody uses (the
-- d-pad, by default), so putting Jump on A doesn't take away the teleport
function M.assign(c, command, button_key)
	if not M.FREE[button_key] then return false end
	local first_one, another = M.key_of(c, command), c.tasti[button_key]
	if first_one then c.tasti[first_one] = nil end
	c.tasti[button_key] = command
	if another and another ~= command then
		local where = first_one
		for _, t in ipairs(ORDER) do
			if not where and M.FREE[t] and not c.tasti[t] then where = t end
		end
		if where then c.tasti[where] = another end
	end
	return true
end

-- Removes the command's button (Y in the settings): it is left without
function M.remove(c, command)
	local t = M.key_of(c, command)
	if t and M.FREE[t] then c.tasti[t] = nil end
end

-- The mapping saved in the profile (button -> command): it is taken if every
-- command is a real command, on a free button, only once (a command may also
-- have no buttons); Start stays on the wheel
local REAL_ONES = {}
for _, cmd in ipairs(M.COMMANDS) do REAL_ONES[cmd] = true end
function M.use(c, keys)
	if type(keys) ~= "table" then return false end
	local seen = {}
	for t, cmd in pairs(keys) do
		if not M.FREE[t] or not REAL_ONES[cmd] or seen[cmd] then return false end
		seen[cmd] = true
	end
	c.tasti = { start = "rotellina" }
	for t, cmd in pairs(keys) do c.tasti[t] = cmd end
	return true
end

-- To save in the profile: without Start
function M.to_save(c)
	local t = {}
	for button_key, cmd in pairs(c.tasti) do
		if button_key ~= "start" then t[button_key] = cmd end
	end
	return t
end

function M.base(c)
	c.tasti = {}
	for t, cmd in pairs(M.BATTLE) do c.tasti[t] = cmd end
end

function M.name(c, button_key)
	return M.CROSS[button_key] or M.FAMILIES[c.family][button_key] or string.upper(button_key or "")
end

-- The controller in use, for the labels of the cards and of the weapon draft
-- (game.gui_script puts it here): the name of a command's button
M.current_value = nil
function M.name_of(command)
	local c = M.current_value
	if not c then return "" end
	return M.name(c, M.UI_FIXED[command] or M.key_of(c, command))
end
-- Which stick moves (the "levette" setting: "destra", by default, or
-- "sinistra"; game.gui_script puts it here) and the side of each use, "dx" or "sx"
M.levette = "destra"
function M.side(use)
	return ((M.levette == "destra") == (use == "muove")) and "dx" or "sx"
end
-- the menus' fixed buttons
M.UI_FIXED = { scheda = "y", conferma = "a", indietro = "b" }

local function evento(c, nome, held_down, stick)
	if (c.giu[nome] or false) == held_down then return end
	c.connected = true
	c.giu[nome] = held_down or nil
	c.ev[#c.ev + 1] = { nome = nome, held_down = held_down, levetta = stick, ui = M.UI[nome] }
end

-- The left stick pushed past PUSH_K acts as a d-pad (for the menus and the items)
local DIRECTIONS = { { "sinistra", "x", -1 }, { "destra", "x", 1 }, { "su", "y", 1 }, { "giu", "y", -1 } }
local function stick_cross(c)
	for _, d in ipairs(DIRECTIONS) do
		local v = c.sx[d[2]] * d[3]
		local nome = "levetta_" .. d[1]
		if v > PUSH_K and not c.giu[nome] then
			c.giu[nome] = true
			c.ev[#c.ev + 1] = { nome = d[1], held_down = true, levetta = true, ui = d[1] }
		elseif v < RETURN_T and c.giu[nome] then
			c.giu[nome] = nil
		end
	end
end

-- a stick from two raw axes (y down, su: -1 if it arrives flipped), with the dead zone
local function raw_stick(l, axes, i, above)
	local x, y = axes[i[1] + 1] or 0, -(axes[i[2] + 1] or 0) * above
	if x * x + y * y < DEAD * DEAD then x, y = 0, 0 end
	l.x, l.y = x, y
end

local function raw(c, action)
	local g = c.raw_ones
	local keys, axes = action.gamepad_buttons or {}, action.gamepad_axis or {}
	raw_stick(c.sx, axes, g.axes.sx, c.su)
	raw_stick(c.dx, axes, g.axes.dx, c.su)
	local cross = g.axes.cross
	local cx, cy = cross and (axes[cross[1] + 1] or 0) or 0, cross and (axes[cross[2] + 1] or 0) or 0
	-- the d-pad as a hat: 1 up, 2 right, 4 down, 8 left
	local hat = (action.gamepad_hats or {})[1] or 0
	local bit = function(b) return math.floor(hat / b) % 2 == 1 end
	for nome, i in pairs(g.tasti) do
		local fell = held_down(c, nome, keys[i + 1] or 0)
		if nome == "su" then fell = fell or cy < -0.5 or bit(1)
		elseif nome == "giu" then fell = fell or cy > 0.5 or bit(4)
		elseif nome == "sinistra" then fell = fell or cx < -0.5 or bit(8)
		elseif nome == "destra" then fell = fell or cx > 0.5 or bit(2) end
		evento(c, nome, fell)
	end
	for _, nome in ipairs({ "lt", "rt" }) do
		if g.axes[nome] then
			c.valore[nome] = math.max(0, axes[g.axes[nome] + 1] or 0)
			evento(c, nome, held_down(c, nome, c.valore[nome]))
		elseif g.tasti[nome] then
			c.valore[nome] = keys[g.tasti[nome] + 1] or 0
		end
	end
end

-- The controller the sticks count from; changing it the sticks restart from rest
local function is_active(c, g)
	if c.is_active == g then return end
	c.is_active = g
	for k in pairs(c.halves) do c.halves[k] = nil end
	-- buttons held on the other controller don't stay down
	for k in pairs(c.giu) do
		if not k:find("^levetta_") then c.giu[k] = nil end
	end
	for _, l in ipairs({ c.sx, c.dx, c.crude.sx, c.crude.dx }) do l.x, l.y = 0, 0 end
end

-- The order of events matters (the simulation tries them one by one): raw
-- buttons are sorted by name
local function sort_by(a, b) return a.nome < b.nome end

function M.input(c, action_id, action)
	if not action_id then return nil end
	local ev = c.ev
	for i = #ev, 1, -1 do ev[i] = nil end
	local axis = ACTIONS[action_id]
	local nome = NAMES[action_id]
	-- a controller read from the raw ones: its translated actions don't count (a
	-- single source per controller, otherwise the two readings alternate)
	local g = action.gamepad or 0
	if c.finti[g] or ((axis or nome) and c.unknown[g]) then return ev end
	-- the sticks count from one controller only: the one that pressed a button
	-- last (or the first that moves)
	if nome and action.pressed then is_active(c, g) end
	-- released buttons count only from the controller in use
	if nome and c.is_active and c.is_active ~= g then return ev end
	if axis and c.is_active ~= g then
		if c.is_active then return ev end
		is_active(c, g)
	end
	if axis then
		-- only action.value counts: Defold sets released when the value drops below
		-- 0.9 (the "pressed" threshold), not when it goes back to zero. Reading it as
		-- "released" zeroed for a frame the side of the stick dropping below 0.9:
		-- rotating the stick fully pushed, the aim always jumped to the same angle,
		-- different for each controller (Sergio, 30 Oct: 34° and 27°, right and
		-- left). The return to zero arrives by itself with value 0 (Defold sends the
		-- changing axis at 0 too).
		c.halves[action_id] = action.value or 0
		local l, r = c[axis[1]], c.crude[axis[1]]
		local more, minus
		for id, a in pairs(ACTIONS) do
			if a[1] == axis[1] and a[2] == axis[2] then
				if a[3] > 0 then more = c.halves[id] or 0 else minus = c.halves[id] or 0 end
			end
		end
		r[axis[2]] = ((more or 0) - (minus or 0)) * (axis[2] == "y" and c.su or 1)
		local m = math.max(1, math.sqrt(r.x * r.x + r.y * r.y))
		l.x, l.y = r.x / m, r.y / m
		if axis[1] == "sx" then stick_cross(c) end
	elseif nome then
		-- as for the sticks: the real value, not released (which for a trigger
		-- arrives as soon as it drops below 0.9: there we took it as released, the
		-- shot fired, and right after, still past half travel, it was pressed again
		-- and the next weapon fired too, the one that equips itself)
		local v = action.value or (action.released and 0 or 1)
		if c.valore[nome] then c.valore[nome] = v end
		evento(c, nome, held_down(c, nome, v))
	elseif action_id == CONNECTED then
		-- a controller Defold doesn't know: we read it from the raw action
		c.unknown[g] = action.gamepad_unknown or nil
		if fake(action.gamepad_name) then
			c.finti[g] = true
			return ev
		end
		c.family = M.family(action.gamepad_name)
		c.connected = true
		return ev
	elseif action_id == RAW then
		if not (c.raw_ones and c.unknown[g]) then return ev end
		for _, v in pairs(action.gamepad_buttons or {}) do
			if v > 0.5 then is_active(c, g) end
		end
		if c.is_active ~= g then
			if c.is_active then return ev end
			is_active(c, g)
		end
		raw(c, action)
		stick_cross(c)
		table.sort(ev, sort_by)
	else
		return nil
	end
	return ev
end

-- Is the stick pushed? (to know whether the controller is in use)
function M.pushed(l, threshold)
	return l.x * l.x + l.y * l.y > (threshold or 0.3) ^ 2
end

return M
