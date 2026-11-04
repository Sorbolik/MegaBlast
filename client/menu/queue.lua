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
--     -- "indietro", { coda = "2v2" | "1v1" | event id }, or nil
--   coda.destroy(c)

local ui = require "ui.ui"
local events = require "main.events"
local T = require("lang.text").queue
local common = require("lang.text").common

local M = {}

-- how many events with their own queue fit on the right (above the 1 vs 1)
local MAX_EVENTS = 2

local function vec(x, y) return vmath.vector3(x, y, 0) end

-- left-aligned text; w: wraps past that width
local function riga(t, x, y, scale, color, parent, w)
	local n = ui.testo(t, x, y, scale, color, parent)
	gui.set_pivot(n, w and gui.PIVOT_NW or gui.PIVOT_W)
	if w then
		gui.set_line_break(n, true)
		gui.set_size(n, vec(w / (scale * 0.5), 200))
	end
	return n
end

local function to_right(t, x, y, scale, color, parent)
	local n = ui.testo(t, x, y, scale, color, parent)
	gui.set_pivot(n, gui.PIVOT_E)
	return n
end

local function build(c)
	if c.radice then gui.delete_node(c.radice) end
	c.buttons = {}
	c.radice = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_visible(c.radice, false)
	local C = ui.C
	-- the arrow sits outside the root: only a node without a parent sticks to the edge
	if c.arrow then gui.delete_node(c.arrow) end
	c.arrow = ui.indietro(c.buttons, "indietro")
	ui.titolo(T.title, 640, 640, 1, C.TEXT, c.radice)

	-- the 2 vs 2: the big card, with the light border
	local W2, H2 = 640, 440
	local n = ui.button(c.buttons, 48 + W2 / 2, 300, W2, H2, "", "coda:2v2", { colore = C.LIGHT }, c.radice)
	local b = c.buttons[#c.buttons]
	b.riposo = C.LIGHT
	gui.set_color(b.bordo, C.LIGHT)
	local x0, y0 = -W2 / 2 + 36, H2 / 2 - 44
	riga(T.usual_match, x0, y0, 0.65, C.OFF, n)
	gui.set_pivot(ui.titolo(common.modes["2v2"], x0, y0 - 64, 1.1, C.LIGHT, n), gui.PIVOT_W)
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
	local x, w = 48 + W2 + 32 + (1280 - 48 * 2 - W2 - 32) / 2, 1280 - 48 * 2 - W2 - 32
	local y = 300 + H2 / 2
	for i, o in ipairs(events.with_queue()) do
		if i > MAX_EVENTS then break end
		local h = 150
		local e = ui.button(c.buttons, x, y - h / 2, w, h, "", "coda:" .. o.coda, nil, c.radice)
		gui.set_color(c.buttons[#c.buttons].bordo, C.BRACE)
		c.buttons[#c.buttons].riposo = C.BRACE
		local ex, ey = -w / 2 + 24, h / 2 - 26
		riga(T.event:format(events.queue_name(o.modo)), ex, ey, 0.6, C.BRACE, e)
		to_right(events.quando(o), w / 2 - 24, ey, 0.6, C.OFF, e)
		riga(o.nome, ex, ey - 40, 0.85, C.TEXT, e)
		if o.riga and o.riga ~= "" then riga(o.riga, ex, ey - 64, 0.6, C.OFF, e, w - 150) end
		to_right(common.play, w / 2 - 24, -h / 2 + 28, 0.9, C.BRACE, e)
		y = y - h - 20
	end
	local h1 = 90
	local u = ui.button(c.buttons, x, 300 - H2 / 2 + h1 / 2, w, h1, "", "coda:1v1", nil, c.radice)
	riga(common.modes["1v1"], -w / 2 + 24, 0, 0.85, C.TEXT, u)
	to_right(common.play, w / 2 - 24, 0, 0.9, C.OFF, u)
end

function M.new()
	local c = {}
	c.fondo = ui.sfondo()
	build(c)
	return c
end

-- again, with the events that just arrived from the server
function M.rebuild(x)
	build(x)
end

function M.on_input(c, action_id, action)
	local ui_action = ui.tocco(c.buttons, action_id, action)
	if not ui_action then return nil end
	if ui_action == "indietro" then return "indietro" end
	return { coda = ui_action:match("^coda:(.*)$") }
end

function M.destroy(c)
	gui.delete_node(c.radice)
	gui.delete_node(c.arrow)
	gui.delete_node(c.fondo)
end

return M
