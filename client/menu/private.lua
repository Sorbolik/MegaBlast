-- The private match (Sergio, 6 Nov: "una modalità partita privata [...] si
-- deve poter scegliere il livello dei bot, se contro o con, tutto quello che
-- serve per una lobby privata online"), from GIOCA ONLINE (menu/queue.lua).
-- First CREA UNA STANZA or a 4 digit code typed on the keypad; then the room
-- the server describes (server/private.go): its code, the mode, one card per
-- seat in its team's column, a person or a bot. Whoever created it (the
-- host) picks the mode, the bots' level (- +) and starts with VIA; everyone
-- can move to a bot's seat (QUI: so the team, with or against the bots).
-- The connection is game.gui_script's: this screen only draws and answers.
--
--   local p = private.new()
--   private.busy(p)               -- connecting: the keypad waits
--   private.stato(p, m)           -- the server's {"t":"privata",...}
--   private.errore(p, text)       -- back to the keypad, with the reason
--   local r = private.on_input(p, action_id, action)
--     -- "indietro", { privata = "nuova" | "4821" } (to connect),
--     -- { invia = msg } (to send to the server), or nil
--   private.destroy(p)

local ui = require "ui.ui"
local kit = require "ui.kit"
local scoria = require "battle.scoria"
local profile_tabs = require "menu.profile_tabs"
local T = require("lang.text").private
local common = require("lang.text").common
local TQ = require("lang.text").queue
local TM = require("lang.text").match
local bot = require "sim.bot"

local M = {}

M.DIGITS = 4
M.GRADE_MAX = #bot.GRADES
local MODES = { "1v1", "2v2", "ffa" }
local KC = kit.C

-- CREA UNA STANZA on the left, the keypad for a code on the right (Figma 19)
local function build_choice(c)
	local g = c.kg
	profile_tabs.devil(c, T.title_short)
	kit.info(g, 440, 130, 380, 300, KC.PURPLE)
	kit.text(g, T.new_room_over, 478, 166, 12, KC.HOT_TOP, "start", 1.5)
	kit.text(g, T.new_room, 474, 208, 32, KC.SAND)
	for i, line in ipairs(T.new_room_lines) do
		kit.text(g, line, 470 - (i - 1) * 2, 248 + (i - 1) * 26, 15, KC.MUTE)
	end
	local p = kit.sand(g, 630, 366, 150, 46, KC.HOT, { sk = 12, d = 6 })
	kit.text(p.g, T.create, 712, 398, 24, KC.INK, "middle")
	kit.button(c.buttons, p, "crea", { spento = c.busy })
	if c.msg then kit.text(g, kit.upper(c.msg), 444, 460, 13, c.busy and KC.MUTE or KC.HOT_TOP, "start", 0.5) end

	-- the code: four boxes, then the keypad
	kit.heading(g, T.have_code, 900, 146)
	for i = 1, M.DIGITS do
		local x = 892 + (i - 1) * 84
		kit.info(g, x, 160, 70, 70, (i == #c.code + 1 and not c.busy) and KC.SAND or KC.PURPLE)
		kit.text(g, c.code:sub(i, i), x + 40, 210, 40, KC.SAND, "middle")
	end
	local keys = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "canc", "0" }
	for i, k in ipairs(keys) do
		local col, row = (i - 1) % 3, math.floor((i - 1) / 3)
		local x, y = 900 + col * 108 - row * 8, 254 + row * 62
		local off = c.busy or (k == "canc" and #c.code == 0) or (#k == 1 and #c.code >= M.DIGITS)
		local pl = kit.plate(g, x, y, 94, 50, off and KC.LINE or KC.ROSE, { sk = 12, d = 5 })
		kit.text(pl.g, k == "canc" and T.delete or k, x + 53, y + 35, k == "canc" and 16 or 26, off and KC.MUTE or KC.SAND, "middle")
		kit.button(c.buttons, pl, k == "canc" and "canc" or "n:" .. k, { spento = off })
	end
	-- the one action: ENTRA, when the code is whole
	local missing = M.DIGITS - #c.code
	local off = c.busy or missing > 0
	c.action = kit.action(c.right, T.join, 930, 560, 270, 84, { size = 54, off = off,
		sub = missing > 0 and (missing == 1 and T.missing_one or T.missing:format(missing)) or nil })
	kit.button(c.buttons, c.action, "entra", { main = true, spento = off })
end

-- One seat: a card in its team's colour, who sits there and, for a bot, its
-- level with - + (the host) and QUI (whoever wants that seat)
local function seat(c, i, s, x, y)
	local room = c.room
	local col = ui.C.SQUADRA[s.team] or KC.SAND
	local k = kit.card(c.kg, x, y, 350, 96, col)
	if s.bot then
		kit.text(k.g, T.bot, x + 34, y + 42, 28, KC.SAND)
		kit.text(k.g, T.bot_level:format(s.bot, M.GRADE_MAX), x + 32, y + 66, 13, KC.MUTE, "start", 1)
		if room.host == room.you then
			kit.stepper(k.g, c.buttons, x + 150, y + 30, "meno:" .. i, "piu:" .. i, s.bot <= 1, s.bot >= M.GRADE_MAX, s.bot)
		end
		kit.round(k.g, c.buttons, x + 312, y + 48, T.here, "posto:" .. i)
	else
		local v = type(s.vetrina) == "table" and s.vetrina or {}
		kit.text(k.g, i == room.you and common.you:upper() or T.player, x + 34, y + 42, 28, KC.SAND)
		if tonumber(v.liv) then kit.text(k.g, T.level:format(v.liv), x + 32, y + 66, 13, KC.MUTE, "start", 1) end
		if i == room.host then kit.text(k.g, T.host, x + 32, y + 84, 10, KC.HOT_TOP, "start", 1) end
	end
end

-- The room (Figma 20): the code on a light plate and the mode on the left,
-- the teams in columns, VIA as the screen's action
local function build_room(c)
	local g, room = c.kg, c.room
	local host = room.host == room.you
	kit.sand(g, 60, 120, 330, 120, KC.HOT, { sk = 30, d = 12 })
	kit.text(g, T.code, 96, 150, 14, KC.INK, "start", 2)
	kit.text(g, room.code or "", 92, 222, 78, KC.INK)
	local opts, on = {}, 1
	for i, m in ipairs(MODES) do
		opts[i] = { T.modes_short[m], "modo:" .. m }
		if room.mode == m then on = i end
	end
	if host then
		kit.choice(g, c.buttons, 60, 300, T.mode, opts, on, 104)
	else
		kit.text(g, T.mode, 66, 290, 14, KC.MUTE, "start", 1.5)
		kit.text(g, common.modes[room.mode] or "", 66, 328, 22, KC.SAND)
	end
	kit.text(g, T.new_room_lines[3], 66, 400, 15, KC.MUTE)
	kit.text(g, T.new_room_lines[4], 64, 424, 15, KC.MUTE)

	-- the teams in team order, two columns; the seats of a team one under the other
	local seats = type(room.posti) == "table" and room.posti or {}
	local teams, by_team, bots = {}, {}, 0
	for i, s in ipairs(seats) do
		if not by_team[s.team] then
			by_team[s.team] = {}
			teams[#teams + 1] = s.team
		end
		local list = by_team[s.team]
		list[#list + 1] = i
		if s.bot then bots = bots + 1 end
	end
	table.sort(teams)
	local row_y = 146
	for k, team in ipairs(teams) do
		local col = (k - 1) % 2
		local x0 = 470 + col * 400
		local list = by_team[team]
		kit.text(g, kit.upper(TM.team_names[team] or ""), x0 + 8, row_y, 22, ui.C.SQUADRA[team] or KC.SAND, "start", 1)
		for j, i in ipairs(list) do
			seat(c, i, seats[i], x0 - (j - 1) * 10, row_y + 14 + (j - 1) * 112)
		end
		if col == 1 or k == #teams then row_y = row_y + 30 + #list * 112 end
	end
	if #teams == 2 then kit.text(g, T.versus, 846, 148, 18, KC.MUTE, "middle", 1) end

	local sub = host and T.go_sub:format(common.modes[room.mode] or "", bots) or T.wait_host
	c.action = kit.action(c.right, T.go, 930, 560, 270, 84, { size = 60, off = not host, sub = kit.upper(sub) })
	kit.button(c.buttons, c.action, "via", { main = true, spento = not host })
end

local function build(c)
	if c.radice then gui.delete_node(c.radice) end
	if c.head then kit.header_delete(c.head) end
	if c.right then gui.delete_node(c.right.node) end
	if c.low then gui.delete_node(c.low.node) end
	c.buttons, c.figure = {}, nil
	c.head = kit.header(c.buttons, T.title, KC.HOT, "indietro", TQ.title)
	c.right = kit.anchor(1280, 720, gui.ANCHOR_RIGHT, gui.ANCHOR_BOTTOM)
	c.low = kit.anchor(0, 720, gui.ANCHOR_LEFT, gui.ANCHOR_BOTTOM)
	c.radice = ui.root()
	c.kg = { node = c.radice, ox = 0, oy = 720 }
	if c.room then build_room(c) else build_choice(c) end
end

function M.new()
	local c = { code = "", colore = ui.C.SQUADRA[1], accent = KC.HOT }
	-- the game world darkened behind, the rays
	c.scene = kit.scene(250, 360, {})
	build(c)
	return c
end

function M.busy(c)
	c.busy, c.msg = true, T.connecting
	build(c)
end

function M.status(c, m)
	c.busy, c.msg, c.room = nil, nil, m
	build(c)
end

function M.error(c, text)
	c.busy, c.msg, c.room = nil, text, nil
	build(c)
end

function M.update(c, dt)
	if c.figure then scoria.update(c.figure, dt, c.st) end
end

function M.on_input(c, action_id, action)
	local a = ui.touch(c.buttons, action_id, action)
	if not a then return nil end
	if a == "indietro" then return "indietro" end
	if c.busy then return nil end
	local digit = a:match("^n:(%d)$")
	local cmd, i = a:match("^(%a+):(%d+)$")
	i = tonumber(i)
	local s = i and c.room and c.room.posti and c.room.posti[i]
	if digit and #c.code < M.DIGITS then
		c.code, c.msg = c.code .. digit, nil
		build(c)
	elseif a == "canc" then
		c.code, c.msg = c.code:sub(1, -2), nil
		build(c)
	elseif a == "crea" then
		return { privata = "nuova" }
	elseif a == "entra" and #c.code == M.DIGITS then
		return { privata = c.code }
	elseif a == "via" then
		return { invia = { t = "via" } }
	elseif a:match("^modo:") then
		return { invia = { t = "modo", mode = a:sub(6) } }
	elseif cmd == "posto" then
		return { invia = { t = "posto", i = i } }
	elseif s and s.bot and (cmd == "meno" or cmd == "piu") then
		local g = math.max(1, math.min(M.GRADE_MAX, s.bot + (cmd == "piu" and 1 or -1)))
		return { invia = { t = "bot", i = i, g = g } }
	end
	return nil
end

function M.destroy(c)
	kit.header_delete(c.head)
	gui.delete_node(c.right.node)
	gui.delete_node(c.low.node)
	gui.delete_node(c.radice)
	kit.scene_drop(c.scene)
end

return M
