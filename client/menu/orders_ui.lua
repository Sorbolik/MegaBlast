-- The COMMESSE tab of the BOTTEGA (the Smith's orders, docs/commesse.md; the
-- draft Sergio approved on 23 Nov: paper cards): the clients' cards pinned in
-- a row, under them the week's order and the Smith's own, on the right the
-- shelf with the materials and the fragments you hold, at the bottom CHIAMA UN
-- CLIENTE and CONSEGNA. With a test profile the PROVA button opens the test
-- bench in the Smith's place (menu/orders_bench.lua, test-only).
-- menu/armory.lua owns the screen and its groups; this draws into them.
--
--   orders_ui.board(a)            -- draws the tab (a: the armory's screen)
--   orders_ui.cmd(a, kind, x)     -- a tap of this tab; true if it was one
--   orders_ui.release(a)          -- gives back the pictures it loaded
--
-- The materials and the fragments are Codex's icons (WB-084: materiale_<id>,
-- frammento_<family>, 192 px squares in the fucina atlas). Until Codex draws
-- the clients (WB-086, WB-087) a client shows the miniature of its map.

local kit = require "ui.kit"
local coins = require "ui.coins"
local equip = require "sim.gear"
local orders = require "sim.orders"
local profile = require "menu.profile"
local illustrations = require "ui.illustrations"
local bench = require "menu.orders_bench"
local gear_ui = require "menu.gear_ui"
local T = require("lang.text").orders

local M = {}

local KC = kit.C
-- on the paper: ink for the words, a burnt brown for the headings, a green that reads on ivory
local PAPER_HEAD = vmath.vector4(0.66, 0.28, 0.05, 1)
local PAPER_MUTE = vmath.vector4(0.36, 0.3, 0.26, 1)
local READY_PAPER = vmath.vector4(0.1, 0.55, 0.34, 1)
local READY_IRON = vmath.vector4(0.24, 0.81, 0.56, 1)

-- The measures (Figma, 1280 x 720): one margin inside every card, one gap between them
local PAD = 14
local GAP = 14
local X0, Y0 = 432, 118
local CARD_W, CARD_H = 180, 236
local ROW2_Y = Y0 + CARD_H + 30
local ROW2_H = 590 - ROW2_Y
local WEEK_W = 300
local SMITH_W = 3 * CARD_W + 2 * GAP - WEEK_W - GAP

local MAP_OF = {}
for _, m in ipairs(orders.MATERIALS) do MAP_OF[m.id] = m.maps[1] end

-- the day the profile lives in (a test profile: the bench's made-up day)
local function day(a)
	return profile.today(a.prof)
end

-- A picture of a map's miniature filling the Figma box (cut to it, never
-- deformed), with an ink rim
local function mini(a, g, map, x, y, w, h)
	local tex, dim = illustrations.map_mini(map)
	if not tex then return end
	a.minis[#a.minis + 1] = map
	local cx, cy = x + w / 2 - g.ox, g.oy - (y + h / 2)
	kit.rect(g, x - 3, y - 3, w + 6, h + 6, KC.INK)
	local clip = gui.new_box_node(vmath.vector3(cx, cy, 0), vmath.vector3(w, h, 0))
	gui.set_adjust_mode(clip, gui.ADJUST_FIT)
	gui.set_clipping_mode(clip, gui.CLIPPING_MODE_STENCIL)
	gui.set_parent(clip, g.node)
	local iw, ih = w, h
	local ratio = dim.w / dim.h
	if iw / ih > ratio then ih = iw / ratio else iw = ih * ratio end
	local img = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(iw, ih, 0))
	gui.set_adjust_mode(img, gui.ADJUST_FIT)
	gui.set_texture(img, tex)
	gui.set_parent(img, clip)
end

-- a panel filling the Figma box, and the group to write on it
local function panel(g, x, y, w, h, name)
	local grp = kit.group(g, x + w / 2, y + h / 2)
	kit.panel(grp.node, w, h, name)
	return grp
end

-- a text that must stay w wide: shrunk if longer (never under the smallest size)
local function fit(n, w)
	local tw = kit.width(n)
	if tw > w then
		gui.set_scale(n, gui.get_scale(n) * (w / tw))
		kit.check_small(n)
	end
	return n
end

-- what a request asks, in words: "6 Piume del Limbo", "Butta 3 nemici nel vuoto"
local function request_text(r)
	if r.materiale then return T.request_material:format(r.quanti, T.materials[r.materiale]) end
	return T.feats[r.impresa]:format(coins.format(r.quanti))
end

-- a family's small tag: its name on its color, ink around
local function family_tag(g, set, x, y)
	local f = equip.BY_ID[set]
	local n = kit.text(g, f.name, x + 7, y + 15, 16, KC.INK, "start", 0.5)
	local w = kit.width(n) + 14
	local c = f.color
	local col = vmath.vector4(tonumber(c:sub(1, 2), 16) / 255, tonumber(c:sub(3, 4), 16) / 255, tonumber(c:sub(5, 6), 16) / 255, 1)
	gui.delete_node(n)
	kit.rect(g, x, y, w, 20, KC.INK)
	kit.rect(g, x + 2, y + 2, w - 4, 16, col)
	kit.text(g, f.name, x + 7, y + 15, 16, KC.INK, "start", 0.5)
	return w
end

-- the last line of a card, on its bottom margin: how far it is, then the cost
local function foot(g, x, y, w, o, prog, ready, paper)
	local ink = paper and KC.INK or KC.SAND
	local n
	if ready then
		n = kit.text(g, T.ready, x, y, 18, paper and READY_PAPER or READY_IRON, "start", 0.5)
	else
		local last = prog[#prog]
		n = kit.text(g, T.progress:format(coins.format(last.done), coins.format(last.asked)), x, y, 18, ink)
	end
	local cost = orders.cost(o)
	local right = x + w
	if cost > 0 then
		local cn = kit.text(g, tostring(cost), right, y, 18, ink, "end")
		kit.piece(g, "gemma", right - kit.width(cn) - 13, y - 6, 20)
	else
		-- free; the welcome order also brings the Smith's voucher
		local voucher = orders.SIZES[o.taglia].voucher
		if voucher then kit.piece(g, "buono", right - 10, y - 6, 20) end
		-- (on a narrow card that is ready the voucher alone says it: PRONTA needs the room)
		if not (ready and voucher) then kit.text(g, T.free, right - (voucher and 26 or 0), y, 18, ink, "end") end
	end
	return n
end

-- A client's card, pinned: the picture, the name, the family, what it asks, how far it is
local function client_card(a, g, o, x, y)
	local p = a.prof
	local client = orders.CLIENT[o.cliente]
	local c = panel(g, x, y, CARD_W, CARD_H, "pannello_chiaro")
	kit.piece(g, "chiodo", x + CARD_W / 2, y - 2, 30)
	local ix, iw = x + PAD, CARD_W - 2 * PAD
	mini(a, c, MAP_OF[client.material], ix + 3, y + PAD + 3, iw - 6, 56)
	fit(kit.text(c, kit.upper(T.clients[o.cliente]), ix, y + 100, 21, KC.INK, "start", 0.5), iw)
	family_tag(c, client.set, ix, y + 108)
	local words = (o.taglia == "benvenuto" and T.welcome .. " " or "") .. request_text(o)
	-- a material asked: its icon on the right of the words
	local tw = iw
	if o.materiale then
		kit.piece(c, "materiale_" .. o.materiale, ix + iw - 17, y + 157, 34)
		tw = iw - 40
	end
	local lines = kit.wrap(c, words, 16, tw)
	for i = 1, math.min(2, #lines) do
		fit(kit.text(c, lines[i], ix, y + 132 + i * 18, 16, KC.INK), tw)
	end
	local prog, ready = orders.progress(p, o)
	kit.bar(c, ix + 4, y + 180, iw - 8, 8, prog[1].done / prog[1].asked, ready and KC.MINT or KC.HOT)
	foot(c, ix, y + CARD_H - PAD - 2, iw, o, prog, ready, true)
	kit.zone(g, a.buttons, x, y, CARD_W, CARD_H, "cartellino:" .. o.n)
end

-- an empty place: the pin and when the next card comes
local function empty_place(g, x, y)
	local c = panel(g, x, y, CARD_W, CARD_H, "pannello")
	kit.piece(g, "chiodo", x + CARD_W / 2, y - 2, 30)
	kit.text(c, T.empty_place, x + CARD_W / 2, y + CARD_H / 2 - 6, 18, KC.MUTE, "middle", 0.5)
	kit.text(c, T.empty_when, x + CARD_W / 2, y + CARD_H / 2 + 16, 16, KC.MUTE, "middle", 0.5)
end

-- one request with its bar, in a wide card: the words, under them the bar and the count
local function request_row(g, p, r, x, y, w, ink)
	local have, asked
	if r.materiale then
		have = math.min(orders.materials(p, r.materiale) + (r.materiale ~= orders.JOLLY and orders.materials(p, orders.JOLLY) or 0), r.quanti)
		asked = r.quanti
	else
		have, asked = math.min(r.fatti or 0, r.quanti), r.quanti
	end
	fit(kit.text(g, request_text(r), x, y, 16, ink), w)
	-- under the words the bar, and on its right how far it is
	local cn = kit.text(g, T.progress:format(coins.format(have), coins.format(asked)), x + w, y + 20, 16, ink, "end")
	kit.bar(g, x + 4, y + 10, w - kit.width(cn) - 18, 8, have / asked, have >= asked and KC.MINT or KC.HOT)
end

-- the week's order: two requests, it ends on Sunday
local function week_card(a, g, o, x, y)
	local p = a.prof
	local client = orders.CLIENT[o.cliente]
	local c = panel(g, x, y, WEEK_W, ROW2_H, "pannello_chiaro")
	local ix, iw = x + PAD, WEEK_W - 2 * PAD
	fit(kit.text(c, T.week:format(kit.upper(T.clients[o.cliente])), ix, y + PAD + 18, 19, PAPER_HEAD, "start", 0.5), iw)
	family_tag(c, client.set, ix, y + PAD + 26)
	request_row(c, p, o, ix, y + 86, iw, KC.INK)
	request_row(c, p, o.poi, ix, y + 124, iw, KC.INK)
	local prog, ready = orders.progress(p, o)
	local n = foot(c, ix, y + ROW2_H - PAD - 2, iw, o, prog, ready, true)
	if not ready then
		gui.set_text(n, T.week_ends)
		gui.set_color(n, PAPER_MUTE)
	end
	kit.zone(g, a.buttons, x, y, WEEK_W, ROW2_H, "cartellino:" .. o.n)
end

-- the Smith's own order: always open, in his iron
local function smith_card(a, g, o, x, y)
	local p = a.prof
	local c = panel(g, x, y, SMITH_W, ROW2_H, "pannello")
	local ix, iw = x + PAD, SMITH_W - 2 * PAD
	fit(kit.text(c, T.smith, ix, y + PAD + 18, 19, KC.HOT, "start", 0.5), iw)
	local prog, ready = orders.progress(p, o)
	request_row(c, p, o, ix, y + 64, iw, KC.SAND)
	local lines = kit.wrap(c, T.smith_line, 16, iw)
	for i = 1, math.min(2, #lines) do kit.text(c, lines[i], ix, y + 92 + i * 18, 16, KC.MUTE) end
	-- (how far it is stands by its bar: the foot says only when it is ready)
	local n = foot(c, ix, y + ROW2_H - PAD - 2, iw, o, prog, ready, false)
	if not ready then gui.set_text(n, "") end
	kit.zone(g, a.buttons, x, y, SMITH_W, ROW2_H, "cartellino:" .. o.n)
end

-- The shelf: what you hold, the materials in a grid and the fragments by family
local function shelf(a, g)
	local p = a.prof
	local x, y, w, h = 1028, 96, 236, 494
	local c = panel(g, x, y, w, h, "pannello")
	local ix, iw = x + PAD, w - 2 * PAD
	kit.text(c, T.shelf, ix, y + PAD + 18, 22, KC.HOT, "start", 1)
	kit.heading(c, T.shelf_materials, ix, y + 62, KC.MUTE)
	local cols, cell = 4, iw / 4
	for i, m in ipairs(orders.MATERIALS) do
		local col, row = (i - 1) % cols, math.floor((i - 1) / cols)
		local mx, my = ix + col * cell + cell / 2, y + 90 + row * 62
		local n = orders.materials(p, m.id)
		local icon = kit.piece(c, "materiale_" .. m.id, mx, my, 40)
		if n == 0 then gui.set_color(icon, vmath.vector4(1, 1, 1, 0.35)) end
		kit.text(c, tostring(n), mx, my + 38, 16, n > 0 and KC.SAND or KC.MUTE, "middle")
	end
	local fy = y + 90 + 3 * 62 + 14
	kit.heading(c, T.shelf_fragments, ix, fy, KC.MUTE)
	for i, f in ipairs(equip.SETS) do
		local ry = fy + 6 + (i - 1) * 32
		kit.piece(c, "frammento_" .. f.id, ix + 14, ry + 16, 30)
		kit.text(c, f.name, ix + 36, ry + 22, 17, KC.SAND, "start", 0.5)
		local n = orders.fragments(p, f.id)
		kit.text(c, coins.format(n), ix + iw, ry + 22, 18, n > 0 and KC.SAND or KC.MUTE, "end")
	end
end

-- The test bench, in the Smith's place: every state without playing or waiting
local BENCH = { { "vinta", "bench_won" }, { "persa", "bench_lost" }, { "giorno", "bench_day1" }, { "settimana", "bench_week" },
	{ "cliente", "bench_client" }, { "colpo", "bench_lucky" }, { "capo", "bench_reset" } }
local BENCH_TEXT = { bench_won = T.bench_won, bench_lost = T.bench_lost, bench_day1 = T.bench_day1, bench_week = T.bench_week,
	bench_client = T.bench_client, bench_lucky = T.bench_lucky, bench_reset = T.bench_reset }

local function bench_panel(a, g)
	local p = a.prof
	local x, y, w, h = 24, 96, 380, 494
	local c = panel(g, x, y, w, h, "pannello")
	local ix, iw = x + PAD, w - 2 * PAD
	kit.text(c, T.bench_title, ix, y + PAD + 18, 22, KC.HOT, "start", 1)
	fit(kit.text(c, T.bench_day:format((day(a):gsub("(%d+)-(%d+)-(%d+)", "%3/%2/%1"))), ix, y + PAD + 40, 16, KC.MUTE, "start", 0.5), iw)
	for i, b in ipairs(BENCH) do
		local by = y + 70 + (i - 1) * 54
		local plate = kit.card(c, ix, by, iw, 46, KC.ROSE)
		kit.text(plate.g, BENCH_TEXT[b[2]], ix + iw / 2, by + 30, 18, KC.SAND, "middle", 0.5)
		kit.button(a.buttons, plate, "prova:" .. b[1])
	end
	local t = p.commesse.prova or { partite = 0 }
	fit(kit.text(c, T.bench_state:format(t.partite or 0, #orders.clients(p), p.commesse.consegne or 0), ix, y + h - PAD - 2, 16, KC.MUTE, "start", 0.5), iw)
end

-- Draws the tab into the armory's groups (a.left, a.mid, a.rt, a.low, a.low2, a.right)
function M.board(a)
	local p = a.prof
	a.minis = a.minis or {}
	orders.refresh(p, day(a))
	local g = a.mid
	local c = p.commesse
	-- on the left the devil, as in the BANCO (the Smith at his counter waits for his drawing)
	if a.bench then bench_panel(a, a.left) else gear_ui.devil(a, a.left, 215, 600, 395) end
	-- the clients' places: as many as you have earned, always three columns
	local places = orders.places(p)
	for i = 1, 3 do
		local x = X0 + (i - 1) * (CARD_W + GAP)
		local o = c.bacheca[i]
		if o then client_card(a, g, o, x, Y0) elseif i <= places then empty_place(g, x, Y0) end
	end
	local sx = X0
	if c.settimana then
		week_card(a, g, c.settimana, X0, ROW2_Y)
		sx = X0 + WEEK_W + GAP
	end
	if c.fabbro then smith_card(a, g, c.fabbro, sx, ROW2_Y) end
	shelf(a, a.rt)
	-- the band: the bench (test profiles), the call, what is ready and its cost, CONSEGNA
	if profile.test then
		local pb = kit.secondary(a.low, T.bench, 160, 640, 230, 62, {})
		kit.button(a.buttons, pb, "prova:apri")
	end
	local cb = kit.secondary(a.low2, T.call, 430, 640, 270, 62, { off = true })
	kit.button(a.buttons, cb, "chiama", { spento = true })
	local ready, cost = 0, 0
	for _, o in ipairs(orders.orders(p)) do
		local _, ok = orders.progress(p, o)
		-- (the Smith's own asks a family: it is delivered from its card)
		if ok and o.cliente then ready, cost = ready + 1, cost + orders.cost(o) end
	end
	local net = profile.can_spend()
	local can = ready > 0 and p.ossidiana >= cost and net
	local sub = ready == 0 and T.none_ready or (not net and T.need_network)
		or (p.ossidiana < cost and T.missing_obsidian:format(cost - p.ossidiana))
		or ((ready == 1 and T.ready_one or T.ready_many:format(ready)) .. " · " .. T.cost:format(cost))
	a.action = kit.action(a.right, T.deliver, 948, 628, 308, 80, { size = 42, off = not can, sub = kit.upper(sub) })
	kit.button(a.buttons, a.action, "consegna", { main = true, spento = not can })
end

-- A tap of this tab (kind, x: the action's two halves). Returns true if it was one of its own
function M.cmd(a, kind, x)
	local p = a.prof
	if kind == "prova" then
		local real = require("sim.wallet").today()
		if x == "apri" then
			a.bench = not a.bench
		elseif x == "vinta" or x == "persa" then
			bench.match(p, real, x == "vinta")
		elseif x == "giorno" or x == "settimana" then
			bench.days(p, real, x == "giorno" and 1 or 7)
		elseif x == "cliente" then
			bench.client(p, real)
		elseif x == "colpo" then
			bench.lucky(p)
		elseif x == "capo" then
			bench.reset(p)
		end
		profile.save(p)
		return true
	elseif kind == "consegna" then
		-- every client's order that is ready, the oldest first, while the Ossidiana lasts
		local list = {}
		for _, o in ipairs(orders.orders(p)) do
			local _, ok = orders.progress(p, o)
			if ok and o.cliente then list[#list + 1] = o.n end
		end
		table.sort(list)
		local done = 0
		for _, n in ipairs(list) do
			if profile.act(p, { k = "consegna", n = n }) then done = done + 1 end
		end
		if done > 0 then sound.play("#scaglia") end
		return true
	elseif kind == "cartellino" or kind == "chiama" then
		-- (the open card and the call: their drafts are still to be approved)
		return true
	end
	return false
end

-- Gives back the miniatures loaded for the tab
function M.release(a)
	for _, id in ipairs(a.minis or {}) do illustrations.map_mini_release(id) end
	a.minis = {}
end

return M
