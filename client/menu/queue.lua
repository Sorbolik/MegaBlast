-- GIOCA ONLINE (the home's GIOCA, Figma 18): the online match queues as cards
-- to choose. The big one is the usual 2 vs 2, with the events that count
-- there too (Tournament, Challenge, XP: "conta anche per"); under it the events
-- with a queue of their own (the modifiers, server/events.go), the 1 vs 1 and
-- the way to the private match. CERCA, the screen's action, starts the chosen
-- queue: a match counts for all the events of its queue. Events from main/events.lua.
--
--   local coda = require "menu.queue"
--   local c = coda.new()
--   local fine = coda.on_input(c, action_id, action)
--     -- "indietro", "privata" (menu/private.lua), { coda = "2v2" | "1v1" | event id }, or nil
--   coda.destroy(c)

local ui = require "ui.ui"
local kit = require "ui.kit"
local scoria = require "battle.scoria"
local profile_tabs = require "menu.profile_tabs"
local events = require "main.events"
local T = require("lang.text").queue
local common = require("lang.text").common

local M = {}

local KC = kit.C

-- how many events with their own queue fit (above the 1 vs 1)
local MAX_EVENTS = 2

-- a row to choose: a card with its name and a line under it; over: the small
-- line above the name (an event's)
local function row(c, x, y, id, name, sub, over)
	local g = c.kg
	local on = c.sel == id
	local k = kit.card(g, x, y, 460, 84, on and KC.HOT or over and KC.STAR or KC.ROSE, { sel = on })
	if over then kit.text(k.g, over, x + 30, y + 26, 13, KC.HOT, "start", 1.5) end
	local n = kit.text(k.g, name, x + 28, y + (over and 54 or sub and 42 or 54), over and 24 or 30, KC.SAND)
	local wide = kit.width(n)
	if wide > 400 then gui.set_scale(n, gui.get_scale(n) * (400 / wide)) end
	if sub then kit.text(k.g, kit.upper(sub), x + 28, y + (over and 74 or 66), 13, KC.MUTE, "start", 0.5) end
	kit.zone(g, c.buttons, x, y, 460, 84, id == "privata" and "privata" or ("scegli:" .. id))
end

local function build(c)
	if c.radice then gui.delete_node(c.radice) end
	if c.head then kit.header_delete(c.head) end
	if c.right then gui.delete_node(c.right.node) end
	if c.low then gui.delete_node(c.low.node) end
	c.buttons = {}
	-- the frame (ui/kit.lua): the title, the way back, the devil
	c.head = kit.header(c.buttons, T.title, KC.HOT, "indietro", common.home)
	c.right = kit.anchor(1280, 720, gui.ANCHOR_RIGHT, gui.ANCHOR_BOTTOM)
	c.low = kit.anchor(0, 720, gui.ANCHOR_LEFT, gui.ANCHOR_BOTTOM)
	c.radice = ui.root()
	c.kg = { node = c.radice, ox = 0, oy = 720 }
	local g = c.kg
	profile_tabs.devil(c, T.online)

	-- the queues with their names, to say which one CERCA starts
	local names = { ["2v2"] = common.modes["2v2"], ["1v1"] = common.modes["1v1"] }
	local own = {}
	for i, o in ipairs(events.with_queue()) do
		if i > MAX_EVENTS then break end
		own[#own + 1] = o
		names[o.coda] = kit.upper(o.nome)
	end
	if not names[c.sel] then c.sel = "2v2" end

	-- the usual 2 vs 2: the big card, with the events that count there too
	local on = c.sel == "2v2"
	local k = kit.card(g, 440, 120, 460, 150, on and KC.HOT or KC.ROSE, { sel = on })
	local clip = gui.new_box_node(vmath.vector3(-230 + 8 + 78, 0, 0), vmath.vector3(156, 134, 0))
	gui.set_clipping_mode(clip, gui.CLIPPING_MODE_STENCIL)
	gui.set_clipping_visible(clip, false)
	gui.set_parent(clip, k.node)
	local img = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(134 * 16 / 9, 134, 0))
	gui.set_texture(img, "mappe")
	gui.play_flipbook(img, c.map or "cortile")
	gui.set_parent(img, clip)
	kit.text(k.g, T.usual_match, 626, 166, 14, KC.HOT_TOP, "start", 1.5)
	kit.text(k.g, common.modes["2v2"], 622, 216, 46, KC.SAND)
	local also = {}
	for i, o in ipairs(events.on_queue("2v2")) do
		if i > 2 then break end
		also[i] = kit.upper(o.nome)
	end
	if #also > 0 then
		local n = kit.text(k.g, T.also_counts:format(table.concat(also, ", ")), 624, 246, 14, KC.MUTE, "start", 1)
		local wide = kit.width(n)
		if wide > 250 then gui.set_scale(n, gui.get_scale(n) * (250 / wide)) end
	end
	kit.zone(g, c.buttons, 440, 120, 460, 150, "scegli:2v2")

	-- under it, staggered: the events with their own queue, the 1 vs 1, the private match
	local rows = #own + 2
	local step = rows <= 3 and 100 or 76
	local i = 0
	for _, o in ipairs(own) do
		row(c, 450 + i * 10, 288 + i * step, o.coda, kit.upper(o.nome), events.when(o), T.event:format(events.queue_name(o.modo)))
		i = i + 1
	end
	row(c, 450 + i * 10, 288 + i * step, "1v1", common.modes["1v1"])
	i = i + 1
	row(c, 450 + i * 10, 288 + i * step, "privata", T.private, T.private_line)

	-- the one action: CERCA starts the chosen queue
	c.action = kit.action(c.right, T.search, 930, 560, 270, 84, { size = 54, sub = names[c.sel] })
	kit.button(c.buttons, c.action, "cerca", { main = true })
end

function M.new()
	local c = { sel = "2v2", colore = ui.C.SQUADRA[1], accent = KC.HOT }
	-- the backdrop (ui/kit.lua)
	c.scene = kit.scene(profile_tabs.devil_x(), profile_tabs.DEVIL_Y, { bg = true })
	build(c)
	return c
end

-- again, with the events that just arrived from the server
function M.rebuild(x)
	build(x)
end

function M.update(c, dt)
	if c.figure then scoria.update(c.figure, dt, c.st) end
end

function M.on_input(c, action_id, action)
	local ui_action = ui.touch(c.buttons, action_id, action)
	if not ui_action then return nil end
	if ui_action == "indietro" or ui_action == "privata" then return ui_action end
	if ui_action == "cerca" then return { coda = c.sel } end
	c.sel = ui_action:match("^scegli:(.*)$") or c.sel
	build(c)
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
