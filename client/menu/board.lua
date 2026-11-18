-- EVENTI (Figma "RIORGANIZZAZIONE MENU · 14 nov", Consigliata/7; Sergio, 14 Nov):
-- the home's EVENTI. A tab for each running event; for the one chosen:
--   on the left   the podium of the first three
--   in the middle the world ranking up to the 100th and your neighbours
--   on the right  your event (when it ends, where you are, the prize) and
--                 CALENDARIO; GIOCA plays it
-- The server doesn't keep the ranking yet: podium and ranking are placeholders
-- until it does. CALENDARIO opens the events coming, one per row; a tap on
-- one (or on your event) opens its detail: what changes, when, the prizes.
-- Events from main/events.lua (server/events.go).
--
--   local bacheca = require "menu.board"
--   local b = bacheca.new(nomi)   -- nomi: weapon -> name (battle/hud.lua)
--   local fine = bacheca.on_input(b, action_id, action)
--     -- "indietro", { coda = ... } to play, or nil
--   bacheca.destroy(b)

local ui = require "ui.ui"
local kit = require "ui.kit"
local events = require "main.events"
local T = require("lang.text").board
local common = require("lang.text").common

local M = {}

local KC = kit.C

-- the color of each event kind
local function color(o)
	return ({ mod = KC.RED, torneo = KC.HOT, sfida = KC.STEEL, xp = KC.MINT })[o.tipo] or KC.SAND
end

-- a text no wider than w: it shrinks (never deforms)
local function fit(n, w)
	local wide = kit.width(n)
	if wide > w then gui.set_scale(n, gui.get_scale(n) * (w / wide)) end
	return n
end

-- "lun 16 nov"; with the time "lun 16 nov 10:00"
local function day_n(t, hour_of)
	local d = os.date("*t", t)
	local s = T.date:format(T.days[d.wday], d.day, T.months[d.month])
	if hour_of then s = s .. string.format(" %02d:%02d", d.hour, d.min) end
	return s
end

local function where(o)
	return o.coda == o.modo and T.counts_in:format(events.queue_name(o.coda)) or T.own_queue:format(events.queue_name(o.modo))
end

local function find(id)
	for _, o in ipairs(events.lista) do
		if o.id == id then return o end
	end
end

-- THE BOARD ----------------------------------------------------------------------------

-- the podium (placeholder: nobody on it until the server keeps the ranking)
local PODIUM = { { 1, 236, 210, "podio_1", "tondo_oro" }, { 2, 70, 176, "podio_2", "tondo_ferro" }, { 3, 402, 152, "podio_3", "tondo_ferro" } }

local function podium(b)
	local g = b.left
	local base = 586
	for _, p in ipairs(PODIUM) do
		local n, x, ph = p[1], p[2], p[3]
		local w = 150
		kit.pic(g, p[4], x, base - ph, w, ph)
		-- the place in the dark of the stand, under its cap
		kit.text(g, n .. "°", x + w / 2, base - ph + 36 + (ph - 36) * 0.42, n == 1 and 54 or 44, n == 1 and KC.HOT or KC.SAND, "middle")
		kit.text(g, "–", x + w / 2, base - 26, 18, KC.MUTE, "middle")
		local ring = n == 1 and 104 or 92
		kit.pic(g, p[5], x + w / 2 - ring / 2, base - ph - ring - 34, ring, ring)
		kit.text(g, "?", x + w / 2, base - ph - ring / 2 - 34 + 16, 40, kit.with_alpha(KC.SAND, 0.35), "middle")
		kit.text(g, "–", x + w / 2, base - ph - 10, 16, KC.MUTE, "middle")
		if n == 1 then kit.piece(g, "corona", x + w / 2, base - ph - ring - 52, 50) end
	end
end

-- the world ranking (placeholder)
local function ranking(b)
	local g = b.mid
	local x, w = 620, 400
	kit.panel(kit.group(g, x + w / 2, 345).node, w, 490)
	kit.text(g, T.ranking, x + w / 2, 132, 16, KC.HOT, "middle", 1)
	for i, line in ipairs(T.ranking_soon) do
		kit.text(g, kit.upper(line), x + w / 2, 300 + (i - 1) * 24, 16, KC.MUTE, "middle", 0.5)
	end
end

-- your event, on the right
local function yours(b, o, now)
	local g = b.rt
	local x, w = 1040, 216
	kit.panel(kit.group(g, x + w / 2, 250).node, w, 300, "pannello_caldo")
	fit(kit.text(g, kit.upper(o.nome), x + w / 2, 140, 22, KC.HOT, "middle"), w - 28)
	kit.text(g, T.ends_in, x + w / 2, 176, 16, KC.MUTE, "middle", 1)
	kit.text(g, kit.upper(events.duration(o.a - now)), x + w / 2, 210, 30, KC.SAND, "middle")
	kit.text(g, T.top, x + w / 2, 248, 16, KC.MUTE, "middle", 1)
	-- where you are: the server doesn't keep it yet
	kit.text(g, "–", x + w / 2, 290, 40, KC.HOT, "middle")
	kit.text(g, T.prize, x + w / 2, 332, 16, KC.MUTE, "middle", 1)
	local first = type(o.premi) == "table" and o.premi[1]
	local prize = first and (type(first) == "table" and (first.testo or "") or tostring(first)) or T.just_for_fun
	kit.piece(g, "medaglia", x + 40, 362, 40)
	fit(kit.text(g, kit.upper(prize), x + 66, 368, 16, KC.SAND), w - 84)
	-- a tap: its detail
	kit.zone(g, b.buttons, x, 100, w, 300, "evento:" .. o.id)
end

local function calendar_button(b)
	local g = b.rt
	local p = kit.secondary(g, T.calendar, 1040, 424, 216, 62, { icon = "ic_calendario" })
	kit.button(b.buttons, p, "calendario")
end

local function board(b, now)
	local running = events.in_progress(now)
	local o = find(b.ev or "")
	if not (o and o.da <= now and now < o.a) then o = running[1] end
	b.ev = o and o.id
	if #running > 1 then
		local tabs = {}
		for i, r in ipairs(running) do
			if i > 3 then break end
			tabs[#tabs + 1] = { kit.upper(r.nome), "scheda:" .. r.id }
		end
		local active = 1
		for i, r in ipairs(running) do if r == o then active = i end end
		kit.tabs(b.head.top_left, b.buttons, 270, 28, tabs, active, KC.HOT, true)
	end
	calendar_button(b)
	if not o then
		kit.text(b.mid, kit.upper(T.no_event), 640, 300, 22, KC.MUTE, "middle", 0.5)
		local after = events.upcoming(now)[1]
		if after then
			fit(kit.text(b.mid, kit.upper(T.next_one:format(after.nome, events.when(after, now))), 640, 336, 16, KC.SAND, "middle", 0.5), 760)
		end
		return nil
	end
	podium(b)
	ranking(b)
	yours(b, o, now)
	return o
end

-- CALENDARIO: the events running and coming, one per row --------------------------------

local function calendar(b, now)
	local g = b.mid
	kit.heading(g, T.calendar, 330, 128)
	local list = {}
	for _, o in ipairs(events.in_progress(now)) do list[#list + 1] = o end
	for _, o in ipairs(events.upcoming(now)) do list[#list + 1] = o end
	if #list == 0 then kit.text(g, kit.upper(T.nothing_planned), 330, 176, 16, KC.MUTE, "start", 1) end
	for i, o in ipairs(list) do
		if i > 6 then break end
		local x, y = 330, 144 + (i - 1) * 76
		local on = o.da <= now
		kit.panel(kit.group(g, x + 310, y + 34).node, 620, 68, on and "pannello_caldo" or "pannello")
		kit.text(g, kit.upper(events.kind(o)), x + 24, y + 26, 16, color(o), "start", 1.5)
		fit(kit.text(g, kit.upper(o.nome), x + 24, y + 54, 22, KC.SAND), 360)
		kit.text(g, kit.upper(on and events.when(o, now) or day_n(o.da, true)), x + 596, y + 42, 16, on and KC.HOT_TOP or KC.MUTE, "end", 0.5)
		kit.zone(g, b.buttons, x, y, 620, 68, "evento:" .. o.id)
	end
end

-- An event's detail
local function detail(b, o, now)
	local g = b.mid
	local x0, x1 = 240, 760
	kit.panel(kit.group(g, 640, 340).node, 880, 500)
	local lab = kit.label(g, x0 + 4, 126, kit.upper(events.kind(o)), color(o))
	kit.text(g, kit.upper(events.when(o, now)), x0 + 4 + kit.width(lab) + 24, 144, 16, KC.MUTE, "start", 1)
	fit(kit.text(g, kit.upper(o.nome), x0, 204, 54, KC.SAND), 800)
	if o.riga and o.riga ~= "" then fit(kit.text(g, o.riga, x0 + 2, 236, 20, KC.MUTE), 800) end
	kit.heading(g, T.what_changes, x0 + 4, 280)
	local n = 0
	for i, t in ipairs(events.what_changes(o, b.nomi)) do
		if i > 4 then break end
		fit(kit.text(g, kit.upper(t), x0 + 4, 294 + (i - 1) * 48 + 30, 19, KC.SAND), 460)
		n = i
	end
	local when = T.from_to:format(day_n(o.da, true), day_n(o.a, true))
	if o.torna then when = when .. " · " .. T.back_on:format(day_n(o.torna)) end
	fit(kit.text(g, kit.upper(when), x0 + 4, 294 + n * 48 + 34, 16, KC.MUTE, "start", 0.5), 460)
	-- on the right: the prizes (the server hands them out once there are accounts)
	kit.heading(g, T.prizes, x1, 280)
	local premi = type(o.premi) == "table" and o.premi or {}
	if #premi == 0 then kit.text(g, kit.upper(T.just_for_fun), x1, 322, 16, KC.MUTE, "start", 1) end
	for i, p in ipairs(premi) do
		if i > 4 then break end
		local y = 294 + (i - 1) * 48
		local who = type(p) == "table" and p.chi
		fit(kit.text(g, kit.upper(type(p) == "table" and (p.testo or "") or tostring(p)), x1, y + 30, 19, KC.SAND), who and 200 or 300)
		if who then kit.text(g, kit.upper(who), x1 + 310, y + 29, 16, KC.HOT_TOP, "end", 0.5) end
	end
	-- an event on a normal queue is played in that queue
	return o.da <= now and o or nil
end

-- Screen ----------------------------------------------------------------------------

local GROUPS = { "left", "mid", "rt", "right" }

local function build(b)
	if b.head then kit.header_delete(b.head) end
	for _, k in ipairs(GROUPS) do
		if b[k] then gui.delete_node(b[k].node); b[k] = nil end
	end
	b.buttons = {}
	local now = events.now()
	local o = b.aperto and find(b.aperto)
	if not o then b.aperto = nil end
	-- the way back: from a detail to where it was opened, from the calendar to the board
	local back = (o or b.view == "calendario") and common.events or common.home
	b.head = kit.header(b.buttons, common.events, KC.HOT, "indietro", back)
	b.left = kit.anchor(0, 0, gui.ANCHOR_LEFT)
	b.mid = kit.anchor(0, 0)
	b.rt = kit.anchor(1280, 0, gui.ANCHOR_RIGHT)
	b.right = kit.anchor(1280, 720, gui.ANCHOR_RIGHT, gui.ANCHOR_BOTTOM)
	local play
	if o then
		play = detail(b, o, now)
	elseif not events.loaded_ok then
		kit.text(b.mid, kit.upper(T.offline), 640, 300, 18, KC.MUTE, "middle", 0.5)
	elseif b.view == "calendario" then
		calendar(b, now)
		-- GIOCA still plays the event chosen on the board
		local ev = find(b.ev or "")
		play = ev and ev.da <= now and now < ev.a and ev or events.in_progress(now)[1]
	else
		play = board(b, now)
	end
	-- the one action: GIOCA, the event shown
	b.play = play and play.coda
	local sub = play and (o and kit.upper(where(play)) or kit.upper(play.nome)) or kit.upper(T.no_event)
	b.action = kit.action(b.right, common.play, 948, 628, 308, 80, { size = 44, off = not play, sub = sub })
	kit.button(b.buttons, b.action, "gioca", { main = true, spento = not play })
end

function M.new(name_list)
	local b = { nomi = name_list, t = 0 }
	b.scene = kit.scene(640, 420, { bg = "stendardi" })
	build(b)
	return b
end

-- every half minute it is redone (times go down, an event starts)
function M.update(b, dt)
	b.t = b.t + dt
	if b.t >= 30 then
		b.t = 0
		build(b)
	end
end

-- again, with the events that just arrived from the server
function M.rebuild(x)
	build(x)
end

function M.on_input(b, action_id, action)
	local ui_action = ui.touch(b.buttons, action_id, action)
	if not ui_action then return nil end
	if ui_action == "indietro" then
		if b.aperto then
			b.aperto = nil
		elseif b.view then
			b.view = nil
		else
			return "indietro"
		end
		build(b)
		return nil
	end
	if ui_action == "gioca" then return b.play and { coda = b.play } or nil end
	if ui_action == "calendario" then
		b.view = "calendario"
	else
		local kind, value = ui_action:match("^(%a+):(.*)$")
		if kind == "scheda" then b.ev = value else b.aperto = value end
	end
	build(b)
	return nil
end

function M.destroy(b)
	kit.header_delete(b.head)
	for _, k in ipairs(GROUPS) do gui.delete_node(b[k].node) end
	kit.scene_drop(b.scene)
end

return M
