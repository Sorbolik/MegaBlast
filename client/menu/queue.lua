-- Where do you play? (the home's GIOCA): the online match queue. On the left
-- the big one, the usual 2 vs 2, with the events that count there too
-- (Tournament, Challenge, XP: "conta anche per"); on the right the events with
-- a queue of their own (the modifiers, server/events.go) and, small, the
-- 1 vs 1. The player only picks the queue: a match counts for all the events
-- of its queue. Style in ui/ui.lua, events from main/events.lua.
--
--   local coda = require "menu.queue"
--   local c = coda.new()
--   local fine = coda.on_input(c, action_id, action)
--     -- "indietro", "privata" (menu/private.lua), { coda = "2v2" | "1v1" | event id }, or nil
--   coda.destroy(c)

local ui = require "ui.ui"
local backdrop = require "ui.backdrop"
local events = require "main.events"
local T = require("lang.text").queue
local common = require("lang.text").common

local M = {}

-- how many events with their own queue fit on the right (above the 1 vs 1)
local MAX_EVENTS = 2

local function vec(x, y) return vmath.vector3(x, y, 0) end

-- left-aligned text; w: wraps past that width
local function riga(t, x, y, scale, color, parent, w)
	local n = ui.text(t, x, y, scale, color, parent)
	gui.set_pivot(n, w and gui.PIVOT_NW or gui.PIVOT_W)
	if w then
		gui.set_line_break(n, true)
		gui.set_size(n, vec(w / (scale * 0.5), 200))
	end
	return n
end

local function to_right(t, x, y, scale, color, parent)
	local n = ui.text(t, x, y, scale, color, parent)
	gui.set_pivot(n, gui.PIVOT_E)
	return n
end

local function build(c)
	if c.radice then gui.delete_node(c.radice) end
	c.buttons = {}
	c.radice = ui.root()
	local C = ui.C
	-- the header (ui.header): the title and the pill's place
	ui.header_delete(c.head)
	c.head = ui.header(c.buttons, T.title, "indietro")

	-- the 2 vs 2: the big card, with the light border
	local W2, H2 = 640, 440
	-- from the first row under the header (ui.header) down
	local CY = ui.CONTENT_TOP - H2 / 2
	local n = ui.button(c.buttons, ui.EDGE + W2 / 2, CY, W2, H2, "", "coda:2v2", { colore = C.LIGHT }, c.radice)
	local b = c.buttons[#c.buttons]
	b.riposo = C.LIGHT
	gui.set_color(b.bordo, C.LIGHT)
	local x0, y0 = -W2 / 2 + 36, H2 / 2 - 44
	riga(T.usual_match, x0, y0, 0.65, C.OFF, n)
	gui.set_pivot(ui.title(common.modes["2v2"], x0, y0 - 64, 1.1, C.LIGHT, n), gui.PIVOT_W)
	local also = events.on_queue("2v2")
	if #also > 0 then
		riga(T.also_counts, x0, y0 - 140, 0.65, C.OFF, n)
		for i, o in ipairs(also) do
			if i > 3 then break end
			riga(o.nome, x0, y0 - 140 - i * 44, 0.75, C.TEXT, n)
		end
	end
	to_right(common.play, W2 / 2 - 36, -H2 / 2 + 44, 1.3, C.LIGHT, n)

	-- on the right: the events with their own queue, then the 1 vs 1
	local x, w = ui.EDGE + W2 + 32 + (1280 - ui.EDGE * 2 - W2 - 32) / 2, 1280 - ui.EDGE * 2 - W2 - 32
	local y = CY + H2 / 2
	for i, o in ipairs(events.with_queue()) do
		if i > MAX_EVENTS then break end
		local h = 150
		local e = ui.button(c.buttons, x, y - h / 2, w, h, "", "coda:" .. o.coda, nil, c.radice)
		gui.set_color(c.buttons[#c.buttons].bordo, C.BRACE)
		c.buttons[#c.buttons].riposo = C.BRACE
		local ex, ey = -w / 2 + 24, h / 2 - 26
		riga(T.event:format(events.queue_name(o.modo)), ex, ey, 0.6, C.BRACE, e)
		to_right(events.when(o), w / 2 - 24, ey, 0.6, C.OFF, e)
		riga(o.nome, ex, ey - 40, 0.85, C.TEXT, e)
		if o.riga and o.riga ~= "" then riga(o.riga, ex, ey - 64, 0.6, C.OFF, e, w - 150) end
		to_right(common.play, w / 2 - 24, -h / 2 + 28, 0.9, C.BRACE, e)
		y = y - h - 20
	end
	local h1 = 90
	local u = ui.button(c.buttons, x, CY - H2 / 2 + h1 / 2, w, h1, "", "coda:1v1", nil, c.radice)
	riga(common.modes["1v1"], -w / 2 + 24, 0, 0.85, C.TEXT, u)
	to_right(common.play, w / 2 - 24, 0, 0.9, C.OFF, u)

	-- under everything, across: the private match (Sergio, 6 Nov; menu/private.lua)
	local wp, hp = 1280 - ui.EDGE * 2, 76
	local yp = CY - H2 / 2 - 24 - hp / 2
	local pv = ui.button(c.buttons, 640, yp, wp, hp, "", "privata", nil, c.radice)
	riga(T.private, -wp / 2 + 24, 0, 0.85, C.TEXT, pv)
	riga(T.private_line, -wp / 2 + 330, 0, 0.7, C.OFF, pv)
	to_right(common.play, wp / 2 - 24, 0, 0.9, C.OFF, pv)
end

function M.new()
	local c = {}
	c.fondo = backdrop.new("arena")
	build(c)
	return c
end

-- again, with the events that just arrived from the server
function M.rebuild(x)
	build(x)
end

function M.on_input(c, action_id, action)
	local ui_action = ui.touch(c.buttons, action_id, action)
	if not ui_action then return nil end
	if ui_action == "indietro" or ui_action == "privata" then return ui_action end
	return { coda = ui_action:match("^coda:(.*)$") }
end

function M.destroy(c)
	gui.delete_node(c.radice)
	ui.header_delete(c.head)
	gui.delete_node(c.fondo)
end

return M
