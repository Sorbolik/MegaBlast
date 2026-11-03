-- The events board (the home's EVENTI). On the left ORA: the running events,
-- one card each. On the right PROSSIMI: the two weeks, one day per box with a
-- small bar per event, and the upcoming ones in a row below. A tap on an event
-- opens the detail: what changes, where it is played, when it comes back, the
-- prizes and GIOCA (if running). No red numbers or windows on top: you just
-- look. Style in ui/ui.lua, events from main/events.lua (server/events.go).
--
--   local bacheca = require "menu.board"
--   local b = bacheca.new(nomi)   -- nomi: weapon -> name (battle/hud.lua)
--   local fine = bacheca.on_input(b, action_id, action)
--     -- "indietro", { coda = ... } to play, or nil
--   bacheca.destroy(b)

local ui = require "ui.ui"
local events = require "main.events"

local M = {}

local DAYS = { "dom", "lun", "mar", "mer", "gio", "ven", "sab" }
local MONTHS = { "gen", "feb", "mar", "apr", "mag", "giu", "lug", "ago", "set", "ott", "nov", "dic" }

local function vec(x, y) return vmath.vector3(x, y, 0) end

-- the color of each event kind
local function color(o)
	local C = ui.C
	return ({ mod = C.BRACE, torneo = ui.GOLD, sfida = C.STEEL, xp = C.MINT })[o.tipo] or C.LIGHT
end

local function riga(t, x, y, scale, col, parent, w)
	local n = ui.testo(t, x, y, scale, col, parent)
	gui.set_pivot(n, w and gui.PIVOT_NW or gui.PIVOT_W)
	if w then
		gui.set_line_break(n, true)
		gui.set_size(n, vec(w / (scale * 0.5), 300))
	end
	return n
end

local function to_right(t, x, y, scale, col, parent)
	local n = ui.testo(t, x, y, scale, col, parent)
	gui.set_pivot(n, gui.PIVOT_E)
	return n
end

-- "lun 16 nov"; with the time "lun 16 nov 10:00"
local function day_n(t, hour_of)
	local d = os.date("*t", t)
	local s = DAYS[d.wday] .. " " .. d.day .. " " .. MONTHS[d.month]
	if hour_of then s = s .. string.format(" %02d:%02d", d.hour, d.min) end
	return s
end

-- midnight of t's day
local function midnight(t)
	local d = os.date("*t", t)
	d.hour, d.min, d.sec = 0, 0, 0
	return os.time(d)
end

local function bar(x, y, w, h, col, parent)
	local n = gui.new_box_node(vec(x, y), vec(w, h))
	gui.set_color(n, col)
	gui.set_parent(n, parent)
	return n
end

-- ORA: the cards of the running events
local function hour_of(b, now)
	local C = ui.C
	riga("ORA", 48, 560, 0.6, C.OFF, b.radice)
	local list_of = events.in_progress(now)
	if #list_of == 0 then
		riga("Nessun evento in corso", 48, 500, 0.75, C.TEXT, b.radice)
		return
	end
	local w, h = 560, 128
	for i, o in ipairs(list_of) do
		if i > 3 then break end
		local y = 520 - (i - 1) * (h + 16) - h / 2
		local n = ui.button(b.buttons, 48 + w / 2, y, w, h, "", "evento:" .. o.id, nil, b.radice)
		local bt = b.buttons[#b.buttons]
		bt.riposo = color(o)
		gui.set_color(bt.bordo, bt.riposo)
		local x0, y0 = -w / 2 + 24, h / 2 - 26
		riga(events.tipo(o), x0, y0, 0.6, color(o), n)
		to_right(events.quando(o, now), w / 2 - 24, y0, 0.6, C.OFF, n)
		riga(o.nome, x0, y0 - 42, 0.95, C.TEXT, n)
		local where = o.coda == o.modo and ("conta nelle partite " .. events.queue_name(o.coda)) or ("coda sua · " .. events.queue_name(o.modo))
		riga(where, x0, -h / 2 + 24, 0.6, C.OFF, n)
	end
end

-- PROSSIMI: two weeks from Monday, then the upcoming ones in a row
local function upcoming(b, now)
	local C = ui.C
	local x0 = 680
	riga("PROSSIMI", x0, 560, 0.6, C.OFF, b.radice)
	local today = midnight(now)
	local wday = os.date("*t", today).wday
	-- this week's Monday (at noon: no surprises with daylight saving)
	local monday = today + 43200 - ((wday + 5) % 7) * 86400
	local cw, ch, gap = 76, 70, 4
	for s = 0, 1 do
		local y = 490 - s * (ch + 30)
		for g = 0, 6 do
			local t = midnight(monday + (s * 7 + g) * 86400)
			local end_of = midnight(t + 86400 + 43200)
			local x = x0 + g * (cw + gap) + cw / 2
			local n, border = ui.pannello(x, y, cw, ch, b.radice)
			if t == today then gui.set_color(border, C.LIGHT) end
			local d = os.date("*t", t)
			ui.testo((s == 0 and DAYS[d.wday] .. " " or "") .. d.day, 0, ch / 2 - 16, 0.55, t < today and C.OFF or C.TEXT, n)
			-- one small bar for each event of that day
			local k = 0
			for _, o in ipairs(events.lista) do
				if o.da < end_of and o.a > t and k < 3 then
					bar(0, ch / 2 - 38 - k * 10, cw - 16, 6, color(o), n)
					k = k + 1
				end
			end
		end
	end
	-- in a row: the upcoming ones starting (also those coming back)
	local y = 300
	local list_of = events.upcoming(now)
	if #list_of == 0 then riga("Niente in programma", x0, y, 0.65, C.OFF, b.radice) end
	for i, o in ipairs(list_of) do
		if i > 4 then break end
		local w, h = 7 * (cw + gap) - gap, 52
		local n = ui.button(b.buttons, x0 + w / 2, y - (i - 1) * (h + 10), w, h, "", "evento:" .. o.id, nil, b.radice)
		bar(-w / 2 + 14, 0, 8, h - 20, color(o), n)
		riga(o.nome, -w / 2 + 32, 0, 0.7, C.TEXT, n)
		to_right(day_n(o.da, true), w / 2 - 16, 0, 0.6, C.OFF, n)
	end
end

-- An event's detail
local function detail(b, o, now)
	local C = ui.C
	riga(events.tipo(o), 48, 590, 0.6, color(o), b.radice)
	riga(events.quando(o, now), 48 + 260, 590, 0.6, C.OFF, b.radice)
	gui.set_pivot(ui.titolo(o.nome, 48, 540, 0.9, C.LIGHT, b.radice), gui.PIVOT_W)
	if o.riga and o.riga ~= "" then riga(o.riga, 48, 500, 0.65, C.TEXT, b.radice, 640) end

	riga("COSA CAMBIA", 48, 410, 0.65, C.OFF, b.radice)
	for i, t in ipairs(events.what_changes(o, b.nomi)) do
		if i > 4 then break end
		local n = ui.pannello(48 + 300, 370 - (i - 1) * 52, 600, 44, b.radice)
		riga(t, -300 + 20, 0, 0.7, C.TEXT, n)
	end
	local when = day_n(o.da, true) .. "  fino a  " .. day_n(o.a, true)
	riga(when, 48, 130, 0.65, C.OFF, b.radice)
	if o.torna then riga("torna " .. day_n(o.torna), 48, 96, 0.65, C.OFF, b.radice) end

	-- on the right: the prizes (the server hands them out once there are accounts)
	local px, pw = 760, 472
	riga("PREMI", px, 590, 0.65, C.OFF, b.radice)
	local premi = type(o.premi) == "table" and o.premi or {}
	if #premi == 0 then riga("Solo per divertirsi", px, 550, 0.7, C.TEXT, b.radice) end
	for i, p in ipairs(premi) do
		if i > 5 then break end
		local n = ui.pannello(px + pw / 2, 550 - (i - 1) * 56, pw, 48, b.radice)
		riga(type(p) == "table" and (p.testo or "") or tostring(p), -pw / 2 + 20, 0, 0.7, C.TEXT, n)
		if type(p) == "table" and p.chi then to_right(p.chi, pw / 2 - 20, 0, 0.6, ui.GOLD, n) end
	end
	if o.da <= now then
		-- an event on a normal queue is played in that queue
		ui.button(b.buttons, 1280 - 48 - 170, 108, 340, 108, "GIOCA", "coda:" .. o.coda,
			{ main = true, colore = color(o) }, b.radice)
	end
end

local function find(id)
	for _, o in ipairs(events.lista) do
		if o.id == id then return o end
	end
end

local function build(b)
	if b.radice then gui.delete_node(b.radice) end
	b.buttons = {}
	b.radice = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_visible(b.radice, false)
	-- the arrow sits outside the root: only a node without a parent sticks to the edge
	if b.arrow then gui.delete_node(b.arrow) end
	b.arrow = ui.indietro(b.buttons, "indietro")
	local now = events.ora()
	local o = b.aperto and find(b.aperto)
	if o then
		detail(b, o, now)
		return
	end
	b.aperto = nil
	ui.titolo("EVENTI", 640, 640, 1, ui.C.TEXT, b.radice)
	if not events.loaded_ok then
		ui.testo("Il server non risponde: gli eventi tornano appena c'è la rete", 640, 400, 0.75, ui.C.OFF, b.radice)
		return
	end
	hour_of(b, now)
	upcoming(b, now)
end

function M.new(name_list)
	local b = { nomi = name_list, t = 0 }
	b.fondo = ui.sfondo()
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
	local ui_action = ui.tocco(b.buttons, action_id, action)
	if not ui_action then return nil end
	if ui_action == "indietro" then
		if not b.aperto then return "indietro" end
		b.aperto = nil
		build(b)
		return nil
	end
	local kind, value = ui_action:match("^(%a+):(.*)$")
	if kind == "coda" then return { coda = value } end
	b.aperto = value
	build(b)
	return nil
end

function M.destroy(b)
	gui.delete_node(b.radice)
	gui.delete_node(b.arrow)
	gui.delete_node(b.fondo)
end

return M
