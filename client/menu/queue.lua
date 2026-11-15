-- GIOCA ONLINE (Figma "RIORGANIZZAZIONE MENU · 14 nov", Consigliata/6; Sergio,
-- 14 Nov): the home's GIOCA. On the left the usual 2 CONTRO 2, big, and under
-- it the STANZA PRIVATA; on the right the running events, each with its queue
-- (a modifier has its own, a Tournament counts in the 2 vs 2), and the next one
-- coming. GIOCA, the screen's action, starts the chosen queue: a match counts
-- for all the events of its queue. Events from main/events.lua.
--
--   local coda = require "menu.queue"
--   local c = coda.new()
--   local fine = coda.on_input(c, action_id, action)
--     -- "indietro", "privata" (menu/private.lua), { coda = "2v2" | event id }, or nil
--   coda.destroy(c)

local ui = require "ui.ui"
local kit = require "ui.kit"
local events = require "main.events"
local T = require("lang.text").queue
local common = require("lang.text").common

local M = {}

local KC = kit.C

-- how many running events fit on the right
local MAX_EVENTS = 2
-- each kind's icon (the modifiers, like the Maglio's, have the hammer)
local ICON = { mod = "ic_maglio", torneo = "ic_torneo" }

-- a text no wider than w: it shrinks (never deforms)
local function fit(n, w)
	local wide = kit.width(n)
	if wide > w then gui.set_scale(n, gui.get_scale(n) * (w / wide)) end
	return n
end

-- a queue to play: a card with its icon ih tall on the left, the name, a line
-- and an information under it, the arrow of what goes somewhere; a tap starts its
-- queue (Sergio, 15 Nov: the cards of before, not the iron plates, which are going)
local function card(c, g, x, y, w, h, o)
	local k = kit.card(g, x, y, w, h, KC.ROSE, { sel = o.hot })
	local f = k.g
	-- (no icon yet: the text starts where the icon would)
	local ih = o.ih
	if o.icon then kit.piece(f, o.icon, x + 34 + ih / 2, y + h / 2, ih) end
	local tx = o.icon and x + 62 + ih or x + 36
	local size = o.size
	local top = y + h / 2 - (size * 0.9 + (o.info and 44 or 22)) / 2 + size * 0.8
	fit(kit.text(f, o.name, tx, top, size, KC.SAND), x + w - 70 - tx)
	if o.sub then fit(kit.text(f, kit.upper(o.sub), tx + 2, top + 26, 15, KC.MUTE, "start", 0.5), x + w - 70 - tx) end
	if o.info then fit(kit.text(f, kit.upper(o.info), tx + 2, top + 50, 15, KC.HOT_TOP, "start", 0.5), x + w - 70 - tx) end
	kit.text(f, "›", x + w - 30, y + h / 2 + size * 0.45, size * 1.3, o.hot and KC.HOT or KC.SAND, "middle")
	kit.button(c.buttons, k, o.action)
end

local function build(c)
	if c.head then kit.header_delete(c.head) end
	for _, k in ipairs({ "left", "rt", "right" }) do
		if c[k] then gui.delete_node(c[k].node); c[k] = nil end
	end
	c.buttons = {}
	local now = events.now()
	c.head = kit.header(c.buttons, T.title, KC.HOT, "indietro", common.home)
	c.left = kit.anchor(0, 0, gui.ANCHOR_LEFT)
	c.rt = kit.anchor(1280, 0, gui.ANCHOR_RIGHT)
	c.right = kit.anchor(1280, 720, gui.ANCHOR_RIGHT, gui.ANCHOR_BOTTOM)

	-- the queues with their names, to say which one GIOCA starts
	local names = { ["2v2"] = common.modes["2v2"], ["1v1"] = common.modes["1v1"] }
	local running = {}
	for i, o in ipairs(events.in_progress(now)) do
		if i > MAX_EVENTS then break end
		running[#running + 1] = o
		if o.coda ~= o.modo then names[o.coda] = kit.upper(o.nome) end
	end
	if not names[c.sel] then c.sel = "2v2" end

	-- the usual 2 vs 2, with the events that count there too
	local also = {}
	for i, o in ipairs(events.on_queue("2v2", now)) do
		if i > 2 then break end
		also[i] = kit.upper(o.nome)
	end
	card(c, c.left, 36, 110, 700, 220, { hot = true, icon = "ic_2contro2", ih = 130, size = 52,
		name = common.modes["2v2"], sub = T.usual_match, info = #also > 0 and T.also_counts:format(table.concat(also, ", ")) or nil,
		action = "coda:2v2" })
	-- every online queue is here (Sergio): the 1 vs 1 too, still without its icon
	card(c, c.left, 36, 350, 340, 120, { size = 30, name = common.modes["1v1"], sub = T.duel_line,
		action = "coda:1v1" })
	card(c, c.left, 396, 350, 340, 120, { icon = "ic_stanza", ih = 52, size = 26, name = T.private, sub = T.private_short,
		action = "privata" })

	-- on the right: the running events and the next one
	if #running == 0 then
		kit.text(c.rt, kit.upper(T.no_event), 1006, 200, 16, KC.MUTE, "middle", 1)
	end
	for i, o in ipairs(running) do
		local own = o.coda ~= o.modo
		card(c, c.rt, 756, 110 + (i - 1) * 190, 500, 175, { icon = ICON[o.tipo] or "ic_notte",
			ih = 64, size = 30, name = kit.upper(o.nome), sub = T.event:format(events.when(o, now)),
			info = own and T.own_queue or T.counts_in:format(common.modes["2v2"]), action = "coda:" .. (own and o.coda or "2v2") })
	end
	local after = events.upcoming(now)[1]
	if after then
		kit.panel(kit.group(c.rt, 1006, 535).node, 500, 90)
		kit.piece(c.rt, "ic_notte", 802, 535, 50)
		fit(kit.text(c.rt, kit.upper(T.coming:format(events.when(after, now), after.nome)), 840, 541, 15, KC.MUTE, "start", 0.5), 340)
	end

	-- the one action: GIOCA starts the chosen queue
	c.action = kit.action(c.right, common.play, 948, 628, 308, 80, { size = 44, sub = names[c.sel] })
	kit.button(c.buttons, c.action, "cerca", { main = true })
end

function M.new()
	local c = { sel = "2v2" }
	c.scene = kit.scene(640, 420, { bg = true })
	build(c)
	return c
end

-- again, with the events that just arrived from the server
function M.rebuild(x)
	build(x)
end

function M.update(c, dt)
end

function M.on_input(c, action_id, action)
	local ui_action = ui.touch(c.buttons, action_id, action)
	if not ui_action then return nil end
	if ui_action == "indietro" or ui_action == "privata" then return ui_action end
	if ui_action == "cerca" then return { coda = c.sel } end
	local queue = ui_action:match("^coda:(.*)$")
	if queue then return { coda = queue } end
	return nil
end

function M.destroy(c)
	kit.header_delete(c.head)
	for _, k in ipairs({ "left", "rt", "right" }) do gui.delete_node(c[k].node) end
	kit.scene_drop(c.scene)
end

return M
