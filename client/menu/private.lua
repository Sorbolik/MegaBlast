-- The private match (Sergio, 6 Nov: "una modalità partita privata [...] si
-- deve poter scegliere il livello dei bot, se contro o con, tutto quello che
-- serve per una lobby privata online"), from DOVE GIOCHI? (menu/queue.lua).
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
local backdrop = require "ui.backdrop"
local T = require("lang.text").private
local common = require("lang.text").common
local TM = require("lang.text").match
local bot = require "sim.bot"

local M = {}

M.DIGITS = 4
M.GRADE_MAX = #bot.GRADES
local MODES = { { "2v2", 210 }, { "1v1", 210 }, { "ffa", 320 } }

local function vec(x, y) return vmath.vector3(x, y, 0) end

local function riga(t, x, y, scale, color, parent)
	local n = ui.text(t, x, y, scale, color, parent)
	gui.set_pivot(n, gui.PIVOT_W)
	return n
end

local function to_right(t, x, y, scale, color, parent)
	local n = ui.text(t, x, y, scale, color, parent)
	gui.set_pivot(n, gui.PIVOT_E)
	return n
end

-- CREA UNA STANZA on the left, the keypad for a code on the right
local function build_choice(c)
	local C = ui.C
	local W, H = 560, 440
	local CY = ui.CONTENT_TOP - H / 2
	local n = ui.button(c.buttons, ui.EDGE + W / 2, CY, W, H, "", "crea", { spento = c.busy }, c.radice)
	local b = c.buttons[#c.buttons]
	b.riposo = C.LIGHT
	gui.set_color(b.bordo, C.LIGHT)
	local x0, y0 = -W / 2 + 36, H / 2 - 44
	riga(T.new_room_over, x0, y0, 0.65, C.OFF, n)
	gui.set_pivot(ui.title(T.new_room, x0, y0 - 64, 0.95, C.LIGHT, n), gui.PIVOT_W)
	for i, line in ipairs(T.new_room_lines) do
		riga(line, x0, y0 - 130 - (i - 1) * 40, 0.7, C.TEXT, n)
	end
	to_right(T.create, W / 2 - 36, -H / 2 + 44, 1.3, C.LIGHT, n)

	-- the code: four boxes, then the keypad
	local x = ui.EDGE + W + 32 + (1280 - ui.EDGE * 2 - W - 32) / 2
	ui.text(T.have_code, x, ui.CONTENT_TOP - 20, 0.7, C.OFF, c.radice)
	for i = 1, M.DIGITS do
		local bx = x + (i - (M.DIGITS + 1) / 2) * 92
		local box, border = ui.panel(bx, 505, 80, 84, c.radice)
		if i == #c.code + 1 and not c.busy then gui.set_color(border, C.LIGHT) end
		ui.title(c.code:sub(i, i), 0, 0, 1.1, C.LIGHT, box)
	end
	local keys = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "canc", "0", "entra" }
	for i, k in ipairs(keys) do
		local col, row = (i - 1) % 3, math.floor((i - 1) / 3)
		local kx, ky = x + (col - 1) * 166, 412 - row * 76
		local label = k == "canc" and T.delete or k == "entra" and T.join or k
		local off = c.busy or (k == "entra" and #c.code < M.DIGITS) or (k == "canc" and #c.code == 0)
			or (#k == 1 and #c.code >= M.DIGITS)
		ui.button(c.buttons, kx, ky, 150, 64, label, k == "canc" and "canc" or k == "entra" and "entra" or "n:" .. k,
			{ spento = off, scala = #k == 1 and 1.1 or 0.8 }, c.radice)
	end
	if c.msg then ui.text(c.msg, 640, 100, 0.8, c.busy and C.OFF or C.BRACE, c.radice) end
end

-- One seat: the team's notch, who sits there and, for a bot, its level with
-- - + (the host) and QUI (whoever wants that seat)
local function seat(c, i, s, x, y, w, h)
	local C, room = ui.C, c.room
	local n = ui.panel(x, y, w, h, c.radice)
	local col = C.SQUADRA[s.team] or C.LIGHT
	local notch = gui.new_box_node(vec(-w / 2 + 12, 0), vec(5, h - 30))
	gui.set_color(notch, col)
	gui.set_parent(notch, n)
	local x0, top = -w / 2 + 30, h / 2 - 32
	if s.bot then
		riga(T.bot, x0, top, 0.9, C.TEXT, n)
		riga(T.bot_level:format(s.bot, M.GRADE_MAX), x0, top - 38, 0.7, C.OFF, n)
		local by = -h / 2 + 36
		if room.host == room.you then
			ui.button(c.buttons, x + x0 + 28, y + by, 56, 48, "-", "meno:" .. i, { spento = s.bot <= 1, scala = 1.1 }, c.radice)
			ui.button(c.buttons, x + x0 + 96, y + by, 56, 48, "+", "piu:" .. i, { spento = s.bot >= M.GRADE_MAX, scala = 1.1 }, c.radice)
		end
		-- narrow cards (all against all): QUI on its own row, above - +
		local qx, qy = x + w / 2 - 18 - 70, y + by
		if w < 420 then qx, qy = x + x0 + 70, y + by + 60 end
		ui.button(c.buttons, qx, qy, 140, 48, T.here, "posto:" .. i, { scala = 0.75 }, c.radice)
	else
		local v = type(s.vetrina) == "table" and s.vetrina or {}
		riga(i == room.you and common.you:upper() or T.player, x0, top, 0.9, i == room.you and C.LIGHT or C.TEXT, n)
		if tonumber(v.liv) then riga(T.level:format(v.liv), x0, top - 38, 0.7, C.OFF, n) end
		if i == room.host then riga(T.host, x0, -h / 2 + 36, 0.65, C.GOLD, n) end
	end
end

-- The room: code and mode on top, the teams in columns, VIA at the bottom
local function build_room(c)
	local C, room = ui.C, c.room
	local host = room.host == room.you
	local top = ui.CONTENT_TOP - 30
	riga(T.code, ui.EDGE, top + 2, 0.7, C.OFF, c.radice)
	gui.set_pivot(ui.title(room.code or "", ui.EDGE + 120, top, 1.1, C.LIGHT, c.radice), gui.PIVOT_W)
	if host then
		local x = 1280 - ui.EDGE
		for k = #MODES, 1, -1 do
			local m, w = MODES[k][1], MODES[k][2]
			ui.tab(c.buttons, x - w / 2, top, w, 48, common.modes[m], "modo:" .. m, room.mode == m, c.radice)
			gui.set_scale(c.buttons[#c.buttons].testo, vec(0.6, 0.6))
			x = x - w - 12
		end
	else
		to_right(common.modes[room.mode] or "", 1280 - ui.EDGE, top, 0.85, C.TEXT, c.radice)
	end

	-- the teams' columns, in team order; the seats of a team one under the other
	local seats = type(room.posti) == "table" and room.posti or {}
	local teams, by_team = {}, {}
	for i, s in ipairs(seats) do
		if not by_team[s.team] then
			by_team[s.team] = {}
			teams[#teams + 1] = s.team
		end
		local list = by_team[s.team]
		list[#list + 1] = i
	end
	table.sort(teams)
	local gap = 20
	local w = (1280 - ui.EDGE * 2 - (#teams - 1) * gap) / math.max(1, #teams)
	local y0, y1 = 520, 190
	for k, team in ipairs(teams) do
		local x = ui.EDGE + w / 2 + (k - 1) * (w + gap)
		local name = TM.team_names[team] or ""
		ui.text(name:upper(), x, y0, 0.75, C.SQUADRA[team] or C.TEXT, c.radice)
		local list = by_team[team]
		local h = math.min(300, (y0 - 30 - y1 - (#list - 1) * 14) / #list)
		for j, i in ipairs(list) do
			seat(c, i, seats[i], x, y0 - 30 - h / 2 - (j - 1) * (h + 14), w, h)
		end
	end

	if host then
		ui.button(c.buttons, 1280 - ui.EDGE - 160, 80, 320, 76, T.go, "via", { main = true }, c.radice)
		riga(T.host_hint, ui.EDGE, 80, 0.7, C.OFF, c.radice)
	else
		riga(T.wait_host, ui.EDGE, 80, 0.75, C.OFF, c.radice)
	end
end

local function build(c)
	if c.radice then gui.delete_node(c.radice) end
	c.buttons = {}
	c.radice = ui.root()
	ui.header_delete(c.head)
	c.head = ui.header(c.buttons, T.title, "indietro")
	if c.room then build_room(c) else build_choice(c) end
end

function M.new()
	local c = { code = "" }
	c.fondo = backdrop.new("arena")
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
	gui.delete_node(c.radice)
	ui.header_delete(c.head)
	gui.delete_node(c.fondo)
end

return M
