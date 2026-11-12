-- The events board (the home's EVENTI). On the left ORA: the running events,
-- one card each. On the right PROSSIMI: the two weeks, one day per box with a
-- small bar per event, and the upcoming ones in a row below. A tap on an event
-- opens the detail: what changes, where it is played, when it comes back, the
-- prizes and GIOCA (if running). No red numbers or windows on top: you just
-- look. GIOCA, the screen's action, plays the event shown. Style in ui/kit.lua, events from main/events.lua (server/events.go).
--
--   local bacheca = require "menu.board"
--   local b = bacheca.new(nomi)   -- nomi: weapon -> name (battle/hud.lua)
--   local fine = bacheca.on_input(b, action_id, action)
--     -- "indietro", { coda = ... } to play, or nil
--   bacheca.destroy(b)

local ui = require "ui.ui"
local kit = require "ui.kit"
local scoria = require "battle.scoria"
local profile_tabs = require "menu.profile_tabs"
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

-- midnight of t's day
local function midnight(t)
	local d = os.date("*t", t)
	d.hour, d.min, d.sec = 0, 0, 0
	return os.time(d)
end

local function where(o)
	return o.coda == o.modo and T.counts_in:format(events.queue_name(o.coda)) or T.own_queue:format(events.queue_name(o.modo))
end

-- ORA: the cards of the running events, staggered; the first is the one GIOCA plays
local function hour_of(b, now)
	local g = b.kg
	kit.heading(g, T.now, 446, 150)
	local list_of = events.in_progress(now)
	if #list_of == 0 then
		kit.text(g, kit.upper(T.no_event), 446, 196, 14, KC.MUTE, "start", 0.5)
		return nil
	end
	for i, o in ipairs(list_of) do
		if i > 3 then break end
		local x, y = 440 + (i - 1) * 14, 170 + (i - 1) * 124
		local k = kit.card(g, x, y, 380, 104, color(o), { sel = i == 1 })
		kit.text(k.g, kit.upper(events.kind(o)), x + 34, y + 28, 11, color(o), "start", 1.5)
		kit.text(k.g, kit.upper(events.when(o, now)), x + 356, y + 28, 11, KC.MUTE, "end", 1)
		fit(kit.text(k.g, kit.upper(o.nome), x + 30, y + 64, 26, KC.SAND), 330)
		kit.text(k.g, kit.upper(where(o)), x + 28, y + 86, 11, KC.MUTE, "start", 1)
		kit.zone(g, b.buttons, x, y, 380, 104, "evento:" .. o.id)
	end
	return list_of[1]
end

-- PROSSIMI: two weeks from Monday, then the upcoming ones in a row
local function upcoming(b, now)
	local g = b.kg
	kit.heading(g, T.next, 880 + kit.air(), 150)
	local today = midnight(now)
	local wday = os.date("*t", today).wday
	-- this week's Monday (at noon: no surprises with daylight saving)
	local monday = today + 43200 - ((wday + 5) % 7) * 86400
	for i = 0, 13 do
		local col, row = i % 7, math.floor(i / 7)
		local x, y = 876 + kit.air() + col * 52 - row * 4, 164 + row * 58
		local t = midnight(monday + i * 86400)
		local end_of = midnight(t + 86400 + 43200)
		local k = kit.card(g, x, y, 44, 46, KC.ROSE, { sel = t == today, off = t < today })
		kit.text(k.g, tostring(os.date("*t", t).day), x + 22, y + 22, 14, t < today and KC.MUTE or KC.SAND, "middle")
		-- one small bar for each event of that day
		local n = 0
		for _, o in ipairs(events.lista) do
			if o.da < end_of and o.a > t and n < 2 then
				kit.para(k.g, x + 7, y + 30 + n * 6, 28, 4, 2, color(o))
				n = n + 1
			end
		end
	end
	-- in a row: the upcoming ones starting (also those coming back)
	local list_of = events.upcoming(now)
	if #list_of == 0 then kit.text(g, kit.upper(T.nothing_planned), 880 + kit.air(), 326, 12, KC.MUTE, "start", 1) end
	for i, o in ipairs(list_of) do
		if i > 4 then break end
		local x, y = 870 + kit.air() - (i - 1) * 4, 300 + (i - 1) * 50
		kit.info(g, x, y, 370, 38, color(o))
		fit(kit.text(g, kit.upper(o.nome), x + 24, y + 25, 13, KC.SAND), 210)
		kit.text(g, kit.upper(day_n(o.da, true)), x + 360, y + 25, 11, KC.MUTE, "end", 1)
		kit.zone(g, b.buttons, x, y - 6, 370, 50, "evento:" .. o.id)
	end
end

-- An event's detail (Figma 22)
local function detail(b, o, now)
	local g = b.kg
	local lab = kit.label(g, 444, 118, kit.upper(events.kind(o)), color(o))
	kit.text(g, kit.upper(events.when(o, now)), 444 + 16 + kit.width(lab) + 30, 134, 12, KC.MUTE, "start", 1.5)
	fit(kit.text(g, kit.upper(o.nome), 440, 196, 54, KC.SAND), 780)
	if o.riga and o.riga ~= "" then fit(kit.text(g, o.riga, 442, 226, 16, KC.MUTE), 780) end
	kit.heading(g, T.what_changes, 446, 270)
	local n = 0
	for i, t in ipairs(events.what_changes(o, b.nomi)) do
		if i > 4 then break end
		local x, y = 440 + (i - 1) * 10, 284 + (i - 1) * 52
		kit.info(g, x, y, 400, 40, KC.PURPLE)
		fit(kit.text(g, kit.upper(t), x + 26, y + 27, 14, KC.SAND), 360)
		n = i
	end
	local when = T.from_to:format(day_n(o.da, true), day_n(o.a, true))
	if o.torna then when = when .. " · " .. T.back_on:format(day_n(o.torna)) end
	kit.text(g, kit.upper(when), 446, 284 + n * 52 + 22, 11, KC.MUTE, "start", 1)

	-- on the right: the prizes (the server hands them out once there are accounts)
	kit.heading(g, T.prizes, 926 + kit.air(), 270)
	local premi = type(o.premi) == "table" and o.premi or {}
	if #premi == 0 then kit.text(g, kit.upper(T.just_for_fun), 926 + kit.air(), 306, 12, KC.MUTE, "start", 1) end
	for i, p in ipairs(premi) do
		if i > 4 then break end
		local x, y = 920 + kit.air() - (i - 1) * 5, 284 + (i - 1) * 52
		local who = type(p) == "table" and p.chi
		kit.info(g, x, y, 310, 40, who and KC.HOT or KC.PURPLE)
		fit(kit.text(g, kit.upper(type(p) == "table" and (p.testo or "") or tostring(p)), x + 26, y + 27, 14, KC.SAND), who and 190 or 270)
		if who then kit.text(g, kit.upper(who), x + 300, y + 27, 11, KC.HOT_TOP, "end", 1) end
	end
	-- an event on a normal queue is played in that queue
	return o.da <= now and o or nil
end

local function find(id)
	for _, o in ipairs(events.lista) do
		if o.id == id then return o end
	end
end

local function build(b)
	if b.radice then gui.delete_node(b.radice) end
	if b.head then kit.header_delete(b.head) end
	if b.right then gui.delete_node(b.right.node) end
	if b.low then gui.delete_node(b.low.node) end
	b.buttons = {}
	local now = events.now()
	local o = b.aperto and find(b.aperto)
	if not o then b.aperto = nil end
	-- the frame (ui/kit.lua): the title, the way back (from a detail, to the board), the devil
	b.head = kit.header(b.buttons, common.events, KC.HOT, "indietro", o and common.events or common.home)
	b.right = kit.anchor(1280, 720, gui.ANCHOR_RIGHT, gui.ANCHOR_BOTTOM)
	b.low = kit.anchor(0, 720, gui.ANCHOR_LEFT, gui.ANCHOR_BOTTOM)
	b.radice = ui.root()
	b.kg = { node = b.radice, ox = 0, oy = 720 }
	profile_tabs.devil(b, T.plate)
	local play
	if o then
		play = detail(b, o, now)
	elseif not events.loaded_ok then
		kit.text(b.kg, kit.upper(T.offline), 446, 196, 13, KC.MUTE, "start", 0.5)
	else
		play = hour_of(b, now)
		upcoming(b, now)
	end
	-- the one action: GIOCA, the event shown (on the board, the first running)
	b.play = play and play.coda
	local sub = play and (o and kit.upper(where(play)) or kit.upper(play.nome)) or kit.upper(T.no_event)
	b.action = kit.action(b.right, common.play, 930, 560, 270, 84, { size = 54, off = not play, sub = sub })
	kit.button(b.buttons, b.action, "gioca", { main = true, spento = not play })
end

function M.new(name_list)
	local b = { nomi = name_list, t = 0, colore = ui.C.SQUADRA[1], accent = KC.HOT }
	-- the backdrop (ui/kit.lua)
	b.scene = kit.scene(profile_tabs.devil_x(), profile_tabs.DEVIL_Y, {})
	build(b)
	return b
end

-- every half minute it is redone (times go down, an event starts)
function M.update(b, dt)
	if b.figure then scoria.update(b.figure, dt, b.st) end
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
		if not b.aperto then return "indietro" end
		b.aperto = nil
		build(b)
		return nil
	end
	if ui_action == "gioca" then return b.play and { coda = b.play } or nil end
	local kind, value = ui_action:match("^(%a+):(.*)$")
	b.aperto = value
	build(b)
	return nil
end

function M.destroy(b)
	kit.header_delete(b.head)
	gui.delete_node(b.right.node)
	gui.delete_node(b.low.node)
	gui.delete_node(b.radice)
	kit.scene_drop(b.scene)
end

return M
