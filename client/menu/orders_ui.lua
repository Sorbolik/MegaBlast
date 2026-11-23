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
--   orders_ui.badge(g, cx, cy, n) -- the orange round with a number (n = 0: a dot)
--   orders_ui.news(p)             -- how many orders are ready, whether new ones wait
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
local screen = require "ui.screen"
local bench = require "menu.orders_bench"
local T = require("lang.text").orders
local delivery = require "menu.orders_delivery"

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

-- (defined further down, used by the board and its taps)
local smith_at_counter, find, modal, modal_cmd, deliver

-- the clients' busts (WB-086, WB-087): where the face is, from the top of the
-- bust (a fraction of its height), for the strip on the board's cards
local FACE = { caronte = 0.42, minosse = 0.3, cerbero = 0.24, plutone = 0.31, flegias = 0.29,
	medusa = 0.4, minotauro = 0.3, malacoda = 0.33 }

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

-- A client's bust (a JPEG loaded while it shows, ui/illustrations.lua) w x h
-- centered at (x, y) on a parent node; a.busts keeps it, to let it go (M.release)
local BUST_W, BUST_H = 366, 485
local function bust_node(a, parent, id, face, x, y, w, h)
	local tex = illustrations.client(id, face)
	if not tex then return end
	a.busts[#a.busts + 1] = { id, face }
	local n = gui.new_box_node(vmath.vector3(x, y, 0), vmath.vector3(w, h, 0))
	gui.set_adjust_mode(n, gui.ADJUST_FIT)
	gui.set_texture(n, tex)
	gui.set_parent(n, parent)
	return n
end
M.bust_node = bust_node

-- A strip of a client's bust (the face) filling the Figma box, cut to it, with an ink rim
local function face_strip(a, g, id, x, y, w, h)
	kit.rect(g, x - 3, y - 3, w + 6, h + 6, KC.INK)
	local cx, cy = x + w / 2, y + h / 2
	local clip = gui.new_box_node(vmath.vector3(cx - g.ox, g.oy - cy, 0), vmath.vector3(w, h, 0))
	gui.set_adjust_mode(clip, gui.ADJUST_FIT)
	gui.set_clipping_mode(clip, gui.CLIPPING_MODE_STENCIL)
	gui.set_parent(clip, g.node)
	-- the bust as wide as the strip, its face in the middle
	local bh = w * BUST_H / BUST_W
	local top = cy - FACE[id] * bh
	bust_node(a, clip, id, "chiede", 0, cy - top - bh / 2, w, bh)
end

-- a panel filling the Figma box, and the group to write on it
-- (name "carta": the paper of the tickets, WB-085)
local function panel(g, x, y, w, h, name)
	local grp = kit.group(g, x + w / 2, y + h / 2)
	if name == "carta" then kit.paper(grp.node, w, h) else kit.panel(grp.node, w, h, name) end
	return grp
end

-- the nail in a ticket's hole (kit.paper: its middle 10 under the top)
local function nail(g, x, y, w)
	kit.piece(g, "chiodo", x + w / 2, y + 10, 30)
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
	local c = panel(g, x, y, CARD_W, CARD_H, "carta")
	local ix, iw = x + PAD, CARD_W - 2 * PAD
	face_strip(a, c, o.cliente, ix + 3, y + PAD + 3 + 14, iw - 6, 42)
	nail(g, x, y, CARD_W)
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
	local c = panel(g, x, y, WEEK_W, ROW2_H, "carta")
	nail(g, x, y, WEEK_W)
	local ix, iw = x + PAD, WEEK_W - 2 * PAD
	-- (the title clear of the hole and its nail, in the middle of the top)
	fit(kit.text(c, T.week:format(kit.upper(T.clients[o.cliente])), ix, y + PAD + 40, 19, PAPER_HEAD, "start", 0.5), iw)
	family_tag(c, client.set, ix, y + PAD + 48)
	request_row(c, p, o, ix, y + 102, iw, KC.INK)
	request_row(c, p, o.poi, ix, y + 140, iw, KC.INK)
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
	{ "cliente", "bench_client" }, { "colpo", "bench_lucky" }, { "pezzi", "bench_pieces" }, { "capo", "bench_reset" } }
local BENCH_TEXT = { bench_won = T.bench_won, bench_lost = T.bench_lost, bench_day1 = T.bench_day1, bench_week = T.bench_week,
	bench_client = T.bench_client, bench_lucky = T.bench_lucky, bench_pieces = T.bench_pieces, bench_reset = T.bench_reset }

local function bench_panel(a, g)
	local p = a.prof
	local x, y, w, h = 24, 96, 380, 494
	local c = panel(g, x, y, w, h, "pannello")
	local ix, iw = x + PAD, w - 2 * PAD
	kit.text(c, T.bench_title, ix, y + PAD + 18, 22, KC.HOT, "start", 1)
	fit(kit.text(c, T.bench_day:format((day(a):gsub("(%d+)-(%d+)-(%d+)", "%3/%2/%1"))), ix, y + PAD + 40, 16, KC.MUTE, "start", 0.5), iw)
	for i, b in ipairs(BENCH) do
		local by = y + 70 + (i - 1) * 49
		local plate = kit.card(c, ix, by, iw, 42, KC.ROSE)
		kit.text(plate.g, BENCH_TEXT[b[2]], ix + iw / 2, by + 28, 18, KC.SAND, "middle", 0.5)
		kit.button(a.buttons, plate, "prova:" .. b[1])
	end
	local t = p.commesse.prova or { partite = 0 }
	fit(kit.text(c, T.bench_state:format(t.partite or 0, #orders.clients(p), p.commesse.consegne or 0), ix, y + h - PAD - 2, 16, KC.MUTE, "start", 0.5), iw)
end

-- The Smith at his counter (WB-085), on the left of the board: 500 tall (drawn at 1000)
smith_at_counter = function(a, g)
	a.smith_node = kit.piece(g, "fabbro_al_banco", 215, 350, 500)
end

-- Windows over the board (the drafts Sergio approved on 23 Nov: 6 the open
-- card, 7 the swap, 8 the family of the Smith's order, 9 the clients' book).
-- a.modal = { k = "carta" | "scambio" | "famiglia" | "libro", n = the order,
-- sel = what is chosen }. They draw into a.over (the middle) and into their own
-- band, a.mlow and a.mright, made after the veil so they are not under it

local RED = vmath.vector4(0.72, 0.16, 0.1, 1)
local PAPER = vmath.vector4(0.957, 0.918, 0.847, 1)
local VEIL = vmath.vector4(0.03, 0.02, 0.035, 0.72)
find = function(p, n)
	for _, o in ipairs(orders.orders(p)) do
		if o.n == n then return o end
	end
end

-- a name with only its first letter big: "LEVIATANO" -> "Leviatano"
local function proper(t)
	return t:sub(1, 1) .. t:sub(2):lower()
end

-- a client's picture filling the Figma box, with an ink rim: its bust (asking)
-- or, until Codex draws it, the miniature of its map
local function portrait(a, g, id, x, y, w, h)
	if FACE[id] then
		kit.rect(g, x - 3, y - 3, w + 6, h + 6, KC.INK)
		bust_node(a, g.node, id, "chiede", x + w / 2 - g.ox, g.oy - (y + h / 2), h * BUST_W / BUST_H, h)
	else
		mini(a, g, MAP_OF[orders.CLIENT[id].material], x, y, w, h)
	end
end

-- the pearls of trust in a row: the lap's (10), the next one lit
local function pearls(g, trust, x, y, d)
	local lap = trust == 0 and 0 or (trust - 1) % orders.TRUST_LAP + 1
	for i = 1, orders.TRUST_LAP do
		local name = i <= lap and "perla_piena" or (i == lap + 1 and "perla_prossima" or "perla_vuota")
		kit.piece(g, name, x + (i - 0.5) * d, y, d - 2)
	end
end

-- what the next pearls bring: "Ancora 2 e ..." (for the book and the open card)
local function trust_next(id, trust)
	local set = proper(equip.BY_ID[orders.CLIENT[id].set].name)
	local function n_pearls(n) return (n == 1 and T.pearl or T.pearls):format(n) end
	if trust < orders.TRUST_BONUS then return T.trust_bonus:format(n_pearls(orders.TRUST_BONUS - trust)) end
	local lap = orders.TRUST_LAP - trust % orders.TRUST_LAP
	return T.trust_gift:format(n_pearls(lap), trust < orders.TRUST_LAP and orders.TRUST_GIFT or orders.TRUST_GIFT_AGAIN, set)
end

-- the veil over everything, a tap on it closes; the window's own groups
local function window(a, base)
	-- (the board's buttons go: only the header's stay, and the window's)
	for i = #a.buttons, base + 1, -1 do a.buttons[i] = nil end
	for _, k in ipairs({ "low", "low2", "right" }) do gui.set_enabled(a[k].node, false) end
	a.over = kit.anchor(0, 0)
	local huge = 1280 * screen.FULL
	kit.rect(a.over, 640 - huge / 2, 360 - huge / 2, huge, huge, VEIL)
	kit.zone(a.over, a.buttons, 640 - huge / 2, 360 - huge / 2, huge, huge, "modale:chiudi")
	a.mlow = kit.anchor(0, 720, gui.ANCHOR_LEFT, gui.ANCHOR_BOTTOM)
	a.mright = kit.anchor(1280, 720, gui.ANCHOR_RIGHT, gui.ANCHOR_BOTTOM)
end

-- what the delivery's scene borrows from the board (menu/orders_delivery.lua)
local HELP = { panel = function(...) return panel(...) end, nail = nail, fit = fit, pearls = pearls,
	trust_next = trust_next, bust_node = function(...) return M.bust_node(...) end }

-- the window's sheet: paper or iron, the nail on the paper, and a zone that keeps its taps
local function sheet(a, x, y, w, h, paper)
	local c = panel(a.over, x, y, w, h, paper and "carta" or "pannello")
	if paper then nail(a.over, x, y, w) end
	kit.zone(a.over, a.buttons, x, y, w, h, "niente")
	return c
end

local function back_button(a)
	local b = kit.secondary(a.mlow, T.back, 160, 640, 214, 62, { icon = "az_torna" })
	kit.button(a.buttons, b, "modale:indietro")
end

-- one request of the open card: its icon, the words, the bar and the count
local function big_request(c, p, r, x, y, w)
	local tx = x
	if r.materiale then
		kit.piece(c, "materiale_" .. r.materiale, x + 18, y + 16, 38)
		tx = x + 46
	end
	fit(kit.text(c, request_text(r), tx, y + 26, 22, KC.INK), x + w - tx)
	local have, asked = orders.progress(p, { materiale = r.materiale, impresa = r.impresa, quanti = r.quanti, fatti = r.fatti })[1].done, r.quanti
	local cn = kit.text(c, T.progress:format(coins.format(have), coins.format(asked)), x + w, y + 62, 18, KC.INK, "end")
	kit.bar(c, x + 4, y + 50, w - kit.width(cn) - 22, 10, have / asked, have >= asked and KC.MINT or KC.HOT)
	return asked - have
end

-- Draft 6: the open card. On the left the client and its trust, on the right
-- what it says, asks and pays; under it CAMBIA, SCAMBIA and CONSEGNA
local function open_card(a, o)
	local p = a.prof
	local id = o.cliente
	local client = orders.CLIENT[id]
	local X, Y, W, H = 300, 96, 680, 470
	local c = sheet(a, X, Y, W, H, true)
	local lx, top = X + 28, Y + 34
	portrait(a, c, id, lx, top, 180, 240)
	local trust = orders.trust(p, id)
	kit.heading(c, T.trust:format(trust), lx, top + 270, PAPER_HEAD)
	pearls(c, trust, lx, top + 290, 18)
	local lines = kit.wrap(c, trust_next(id, trust), 16, 180)
	for i = 1, math.min(3, #lines) do fit(kit.text(c, lines[i], lx, top + 318 + (i - 1) * 19, 16, PAPER_MUTE), 180) end

	local rx, rw = X + 236, W - 236 - 28
	fit(kit.text(c, kit.upper(T.clients[id]), rx, top + 24, 34, KC.INK, "start", 1), rw - 140)
	family_tag(c, client.set, rx + rw - 120, top + 4)
	local y = top + 44
	local said = kit.wrap(c, T.lines[id], 18, rw)
	for i = 1, math.min(3, #said) do
		fit(kit.text(c, said[i], rx, y + i * 22, 18, KC.INK), rw)
	end
	-- each request a block 74 tall: the words, the bar, the count
	y = y + math.min(3, #said) * 22 + 32
	kit.heading(c, T.asks, rx, y, PAPER_HEAD)
	local missing = big_request(c, p, o, rx, y + 8, rw)
	if o.poi then big_request(c, p, o.poi, rx, y + 78, rw) end
	y = y + (o.poi and 152 or 82) + 30
	-- the prize: Scaglie, the fragments of its family (one more from 5 pearls), the voucher
	local size = orders.SIZES[o.taglia]
	local frags = size.frammenti + (trust >= orders.TRUST_BONUS and 1 or 0)
	kit.heading(c, T.prize, rx, y, PAPER_HEAD)
	local py = y + 30
	kit.piece(c, "scaglia", rx + 14, py - 7, 28)
	local sn = kit.text(c, coins.format(size.scaglie), rx + 34, py, 22, KC.INK)
	local fx = rx + 34 + kit.width(sn) + 24
	kit.piece(c, "frammento_" .. client.set, fx + 14, py - 7, 30)
	local fnn = kit.text(c, tostring(frags), fx + 34, py, 22, KC.INK)
	local wx = fx + 34 + kit.width(fnn) + 8
	local fw = kit.text(c, (frags == 1 and T.fragment or T.fragments):format(proper(equip.BY_ID[client.set].name)), wx, py, 16, PAPER_MUTE)
	if size.voucher then kit.piece(c, "buono", wx + kit.width(fw) + 22, py - 7, 28) end
	-- where it comes from (a material: the map it drops on)
	if not o.poi then
		local hint = o.materiale and T.drops:format(T.drop_place[o.materiale]) or T.feat_hint
		local hl = kit.wrap(c, hint, 16, rw)
		for i = 1, math.min(2, #hl) do fit(kit.text(c, hl[i], rx, py + 30 + i * 19, 16, PAPER_MUTE), rw) end
	end
	-- at the bottom: ready and its cost, or what is still missing
	local _, ready = orders.progress(p, o)
	local cost = orders.cost(o)
	local by = Y + H - 26
	if ready then
		local right = X + W - 28
		if cost > 0 then
			local cn = kit.text(c, T.cost_upper:format(cost), right - 26, by, 18, KC.INK, "end")
			kit.piece(c, "gemma", right - 10, by - 6, 22)
			kit.text(c, T.ready .. " · ", right - 26 - kit.width(cn), by, 18, READY_PAPER, "end", 0.5)
		else
			kit.text(c, T.ready .. " · " .. T.free, right, by, 18, READY_PAPER, "end", 0.5)
		end
	else
		-- (the week's two requests are not counted together: it only says it is not ready)
		kit.text(c, o.poi and T.not_ready or (missing == 1 and T.missing_one or T.missing):format(missing), X + W - 28, by, 18, RED, "end", 0.5)
	end

	-- the band: CAMBIA (free once a day, never the welcome or the week's), SCAMBIA, CONSEGNA
	local today = day(a)
	local on_board = false
	for _, b in ipairs(p.commesse.bacheca) do on_board = on_board or b == o end
	local can_change = on_board and o.taglia ~= "benvenuto" and orders.can_change(p, today)
	local change_sub = not (on_board and o.taglia ~= "benvenuto") and T.change_never
		or (can_change and T.change_free or T.change_tomorrow)
	local cb = kit.secondary(a.mlow, T.change, 160, 640, 214, 62, { icon = "az_cambia", off = not can_change, sub = change_sub })
	kit.button(a.buttons, cb, "cambia", { spento = not can_change })
	local mat = o.materiale or (o.poi and o.poi.materiale)
	local sb = kit.secondary(a.mlow, T.swap, 390, 640, 214, 62, { icon = "az_scambia", off = not mat, sub = mat and T.swap_sub or T.swap_none })
	kit.button(a.buttons, sb, "scambia", { spento = not mat })
	local can = ready and p.ossidiana >= cost and profile.can_spend()
	local act = kit.action(a.mright, T.deliver, 948, 628, 308, 80, { icon = "az_consegna", size = 42, off = not can })
	kit.button(a.buttons, act, "consegnala", { main = true, spento = not can })
end

-- Draft 7: the swap, three of a material for one of the asked one
local function swap(a, o)
	local p = a.prof
	local mat = o.materiale or o.poi.materiale
	local X, Y, W, H = 340, 140, 600, 410
	local c = sheet(a, X, Y, W, H, false)
	local ix, iw = X + 24, W - 48
	fit(kit.text(c, T.swap_title:format(kit.upper(T.material_one[mat])), ix, Y + 46, 24, KC.HOT, "start", 1), iw)
	local lines = kit.wrap(c, T.swap_line:format(orders.TRADE, T.material_one[mat]), 16, iw)
	for i = 1, math.min(2, #lines) do kit.text(c, lines[i], ix, Y + 52 + i * 20, 16, KC.MUTE) end
	local full = orders.materials(p, mat) >= orders.MATERIAL_MAX
	local i = 0
	for _, m in ipairs(orders.MATERIALS) do
		if m.id ~= mat then
			local col, row = i % 5, math.floor(i / 5)
			local cx, cy = ix + 4 + col * 108 + 52, Y + 150 + row * 100
			local n = orders.materials(p, m.id)
			local usable = m.id ~= orders.JOLLY and n >= orders.TRADE and not full
			if a.modal.sel == m.id then kit.panel(kit.group(c, cx, cy + 12).node, 92, 96, "pannello_caldo") end
			local icon = kit.piece(c, "materiale_" .. m.id, cx, cy, 56)
			if not usable then gui.set_color(icon, vmath.vector4(1, 1, 1, 0.35)) end
			kit.text(c, tostring(n), cx, cy + 50, 18, usable and KC.SAND or KC.MUTE, "middle")
			if usable then kit.zone(a.over, a.buttons, cx - 50, cy - 40, 100, 96, "dai:" .. m.id) end
			i = i + 1
		end
	end
	-- the trade, as it would be
	local sel = a.modal.sel
	local ty = Y + H - 30
	if sel then
		kit.piece(c, "materiale_" .. sel, ix + 20, ty - 8, 40)
		kit.text(c, tostring(orders.TRADE), ix + 46, ty, 22, KC.SAND)
		kit.text(c, "›", ix + 76, ty, 26, KC.HOT)
		kit.piece(c, "materiale_" .. mat, ix + 120, ty - 8, 40)
		kit.text(c, "1", ix + 146, ty, 22, KC.SAND)
	else
		kit.text(c, full and T.swap_full or T.swap_pick, ix, ty, 18, KC.MUTE, "start", 0.5)
	end
	kit.text(c, T.you_have:format(orders.materials(p, mat)), X + W - 24, ty, 16, KC.MUTE, "end", 1)
	back_button(a)
	local can = sel and orders.materials(p, sel) >= orders.TRADE and not full
	local act = kit.action(a.mright, T.swap, 948, 628, 308, 80, { icon = "az_scambia", size = 42, off = not can })
	kit.button(a.buttons, act, "baratta", { main = true, spento = not can })
end

-- Draft 8: the Smith's order, for which family
local function family(a, o)
	local p = a.prof
	local _, ready = orders.progress(p, o)
	local X, Y, W, H = 290, 150, 700, 380
	local c = sheet(a, X, Y, W, H, false)
	local ix, iw = X + 24, W - 48
	fit(kit.text(c, ready and T.smith_ready or T.smith, ix, Y + 46, 24, KC.HOT, "start", 1), iw)
	kit.text(c, T.family_line, ix, Y + 72, 16, KC.MUTE)
	local sel = a.modal.sel
	for i, f in ipairs(equip.SETS) do
		local cx, cy = ix + (i - 0.5) * (iw / 5), Y + 160
		if sel == f.id then kit.panel(kit.group(c, cx, cy + 28).node, 118, 158, "pannello_caldo") end
		kit.piece(c, "frammento_" .. f.id, cx, cy, 84)
		kit.text(c, f.name, cx, cy + 70, 18, KC.SAND, "middle", 0.5)
		kit.text(c, T.you_have:format(coins.format(orders.fragments(p, f.id))), cx, cy + 92, 16, KC.MUTE, "middle", 0.5)
		kit.zone(a.over, a.buttons, cx - 59, cy - 52, 118, 158, "famiglia:" .. f.id)
	end
	-- the prize of the family chosen, and how far the order is
	local size = orders.SIZES[o.taglia]
	local py = Y + H - 30
	kit.heading(c, T.prize, ix, py, KC.HOT_TOP)
	local px = ix + 90
	kit.piece(c, "scaglia", px + 14, py - 7, 28)
	local sn = kit.text(c, coins.format(size.scaglie), px + 34, py, 22, KC.SAND)
	local fx = px + 34 + kit.width(sn) + 24
	kit.piece(c, "frammento_" .. (sel or "fabbro"), fx + 14, py - 7, 30)
	local fnn = kit.text(c, tostring(size.frammenti), fx + 34, py, 22, KC.SAND)
	if sel then
		kit.text(c, T.fragment:format(proper(equip.BY_ID[sel].name)), fx + 42 + kit.width(fnn), py, 16, KC.MUTE)
	end
	local prog = orders.progress(p, o)
	local cost = orders.cost(o)
	local right = X + W - 24
	if not ready then
		kit.text(c, (prog[1].asked - prog[1].done == 1 and T.missing_one or T.missing):format(prog[1].asked - prog[1].done), right, py, 18, KC.ROSE, "end", 0.5)
	elseif cost > 0 then
		local cn = kit.text(c, T.cost_upper:format(cost), right - 26, py, 18, KC.SAND, "end")
		kit.piece(c, "gemma", right - 10, py - 6, 22)
		kit.text(c, T.ready .. " · ", right - 26 - kit.width(cn), py, 18, READY_IRON, "end", 0.5)
	else
		kit.text(c, T.ready .. " · " .. T.free, right, py, 18, READY_IRON, "end", 0.5)
	end
	back_button(a)
	local can = ready and sel ~= nil and p.ossidiana >= cost and profile.can_spend()
	local act = kit.action(a.mright, T.deliver, 948, 628, 308, 80, { icon = "az_consegna", size = 42, off = not can })
	kit.button(a.buttons, act, "consegnala", { main = true, spento = not can })
end

-- Draft 9: the clients' book, and from here the call
local function book(a)
	local p = a.prof
	local X, Y, W, H = 190, 92, 900, 470
	local c = sheet(a, X, Y, W, H, true)
	local ix = X + 28
	kit.text(c, T.book_title, ix, Y + 62, 34, KC.INK, "start", 1)
	local lines = kit.wrap(c, T.book_line, 16, 400)
	for i = 1, math.min(2, #lines) do kit.text(c, lines[i], X + W - 28 - 400, Y + 40 + i * 19, 16, PAPER_MUTE) end
	local list = orders.clients(p)
	local sel = a.modal.sel
	for i, cl in ipairs(list) do
		local x, y = ix + ((i - 1) % 3) * 284, Y + 86 + math.floor((i - 1) / 3) * 104
		if cl.id == sel then
			kit.rect(c, x - 6, y - 6, 270, 104, PAPER_HEAD)
			kit.rect(c, x - 3, y - 3, 264, 98, PAPER)
		end
		portrait(a, c, cl.id, x, y, 70, 92)
		fit(kit.text(c, kit.upper(T.clients[cl.id]), x + 84, y + 20, 20, KC.INK, "start", 0.5), 170)
		family_tag(c, cl.set, x + 84, y + 30)
		pearls(c, orders.trust(p, cl.id), x + 84, y + 76, 16)
		kit.zone(a.over, a.buttons, x - 6, y - 6, 270, 104, "cliente:" .. cl.id)
	end
	local today = day(a)
	local by = Y + H - 26
	if sel then
		local trust = orders.trust(p, sel)
		fit(kit.text(c, T.book_detail:format(T.clients[sel], trust, trust_next(sel, trust)), ix, by - 24, 16, PAPER_MUTE), W - 56)
		local called = p.commesse.chiamato
		local now = orders.day_number(today)
		local line, color
		if not orders.can_call(p, sel, today) then
			line, color = T.call_yesterday:format(T.clients[sel]), RED
		elseif called and called.cliente == sel and called.giorno == now then
			line, color = T.call_done:format(T.clients[sel]), READY_PAPER
		else
			line, color = T.call_when:format(T.clients[sel]), PAPER_HEAD
		end
		fit(kit.text(c, line, ix, by, 18, color, "start", 0.5), W - 56)
	else
		kit.text(c, T.book_none, ix, by, 18, PAPER_MUTE)
	end
	back_button(a)
	local called = p.commesse.chiamato
	local done = sel and called and called.cliente == sel and called.giorno == orders.day_number(today)
	local can = sel ~= nil and not done and orders.can_call(p, sel, today)
	local act = kit.action(a.mright, T.call_short, 948, 628, 308, 80, { icon = "az_chiama", size = 42, off = not can })
	kit.button(a.buttons, act, "chiama", { main = true, spento = not can })
end

modal = function(a, base)
	local m = a.modal
	local o = m.n and find(a.prof, m.n)
	if m.k ~= "libro" and not o then
		a.modal = nil
		return
	end
	window(a, base)
	if m.k == "carta" then open_card(a, o)
	elseif m.k == "scambio" then swap(a, o)
	elseif m.k == "famiglia" then family(a, o)
	else book(a) end
end

-- A tap inside a window. Returns true if it was one
modal_cmd = function(a, kind, x)
	local p = a.prof
	local m = a.modal
	if kind == "cambia" then
		local new = profile.act(p, { k = "cambia", n = m.n })
		if new then m.n = new.n end
	elseif kind == "scambia" then
		a.modal = { k = "scambio", n = m.n }
	elseif kind == "dai" or kind == "famiglia" or kind == "cliente" then
		m.sel = x
	elseif kind == "baratta" then
		local o = find(p, m.n)
		local mat = o and (o.materiale or (o.poi and o.poi.materiale))
		if mat and m.sel and profile.act(p, { k = "scambia", da = m.sel, a = mat }) then sound.play("#scaglia") end
		if m.sel and orders.materials(p, m.sel) < orders.TRADE then m.sel = nil end
	elseif kind == "consegnala" then
		deliver(a, { { n = m.n, set = m.k == "famiglia" and m.sel or nil } }, true)
	elseif kind == "chiama" then
		if m.sel then profile.act(p, { k = "chiama", cliente = m.sel }) end
	else
		return false
	end
	return true
end

-- The round that calls you to the orders: orange with ink around, the number
-- of those ready inside (n = 0: smaller, no number: something new waits)
function M.badge(g, cx, cy, n)
	local d = n > 0 and 28 or 16
	kit.dot(g, cx, cy, d + 6, KC.INK)
	kit.dot(g, cx, cy, d, KC.HOT)
	if n > 0 then kit.text(g, tostring(n), cx, cy + 7, 20, KC.INK, "middle") end
end

-- How many orders are ready to deliver, and whether the day's new ones are
-- still to see (the board not opened today). nil: the Smith has not called yet
function M.news(p)
	if not (p.commesse and p.commesse.aperta) then return nil end
	return orders.ready_count(p), p.commesse.giorno ~= profile.today(p)
end

-- Draws the tab into the armory's groups (a.left, a.mid, a.rt, a.low, a.low2, a.right)
function M.board(a)
	local p = a.prof
	-- (the buttons before the board's: the header's, kept under a window)
	local base = #a.buttons
	a.minis = a.minis or {}
	a.busts = a.busts or {}
	orders.init(p)
	if not p.commesse.aperta then
		-- (test profiles only: the Smith has not called yet, the bench makes the matches)
		if a.bench then bench_panel(a, a.left) else smith_at_counter(a, a.left) end
		local n = kit.text(a.mid, T.closed:format(orders.OPEN_AFTER, p.commesse.online, orders.OPEN_AFTER), 716, 330, 22, KC.MUTE, "middle", 0.5)
		fit(n, 560)
		local pb = kit.secondary(a.low, T.bench, 160, 640, 230, 62, { icon = "az_prova" })
		kit.button(a.buttons, pb, "prova:apri")
		return
	end
	-- the day's refill goes through the profile's door, so the server follows
	if p.commesse.giorno ~= day(a) or #p.commesse.attesa > 0 then profile.act(p, { k = "bacheca" }) end
	local g = a.mid
	local c = p.commesse
	-- on the left the Smith at his counter (WB-085), or the test bench in his place
	a.smith_node = nil
	if a.bench then bench_panel(a, a.left) else smith_at_counter(a, a.left) end
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
		local pb = kit.secondary(a.low, T.bench, 160, 640, 230, 62, { icon = "az_prova" })
		kit.button(a.buttons, pb, "prova:apri")
	end
	-- the call: it opens the clients' book, where you call them (Sergio, 23 Nov: one button)
	local none = #orders.clients(p) == 0
	local cb = kit.secondary(a.low2, T.call, 430, 640, 270, 62, { icon = "az_chiama", off = none })
	kit.button(a.buttons, cb, "libro", { spento = none })
	local ready, cost = 0, 0
	for _, o in ipairs(orders.orders(p)) do
		local _, ok = orders.progress(p, o)
		-- (the Smith's own asks a family: it is delivered from its card)
		if ok and o.cliente then ready, cost = ready + 1, cost + orders.cost(o) end
	end
	-- only the Smith's ready (the first time it is the only one): CONSEGNA opens its family choice
	local _, smith = orders.progress(p, c.fabbro)
	local net = profile.can_spend()
	local can = (ready > 0 and p.ossidiana >= cost or ready == 0 and smith) and net
	local sub = ready == 0 and (smith and T.smith_short or T.none_ready) or (not net and T.need_network)
		or (p.ossidiana < cost and T.missing_obsidian:format(cost - p.ossidiana))
		or ((ready == 1 and T.ready_one or T.ready_many:format(ready)) .. " · " .. T.cost:format(cost))
	a.action = kit.action(a.right, T.deliver, 948, 628, 308, 80, { icon = "az_consegna", size = 42, off = not can, sub = kit.upper(sub) })
	kit.button(a.buttons, a.action, "consegna", { main = true, spento = not can })
	if a.scene then
		window(a, base)
		delivery.draw(a, HELP)
	elseif a.modal then
		modal(a, base)
	end
end

-- Where an order's ticket hangs on the board (its middle, Figma), for its flight to the counter
local function card_at(p, o)
	local c = p.commesse
	for i, b in ipairs(c.bacheca) do
		if b == o then return { X0 + (i - 1) * (CARD_W + GAP) + CARD_W / 2, Y0 + CARD_H / 2 } end
	end
	if o == c.settimana then return { X0 + WEEK_W / 2, ROW2_Y + ROW2_H / 2 } end
	return { X0 + (c.settimana and WEEK_W + GAP or 0) + SMITH_W / 2, ROW2_Y + ROW2_H / 2 }
end

-- Delivers orders (n, the Smith's family) and starts the scene with what came.
-- from_window: the ticket flies from the open window, not from the board
deliver = function(a, list, from_window)
	local p = a.prof
	local done = {}
	for _, it in ipairs(list) do
		local o = find(p, it.n)
		local from = from_window and { 640, 330 } or (o and card_at(p, o))
		local rows = o and profile.act(p, { k = "consegna", n = it.n, set = it.set })
		if rows then done[#done + 1] = { order = o, rows = rows, from = from } end
	end
	delivery.start(a, done)
	return #done > 0
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
		elseif x == "pezzi" then
			-- the BANCO's pieces of the day go back to the shop, to see their prices
			local wallet = require "sim.wallet"
			local keys = {}
			for _, it in ipairs(wallet.day(real)) do keys[#keys + 1] = wallet.key(it[1], it[2]) end
			bench.give_back(p, keys)
		elseif x == "capo" then
			bench.reset(p)
		end
		profile.save(p)
		return true
	elseif kind == "consegna" then
		-- every client's order that is ready, the oldest first, while the Ossidiana lasts
		-- (none, and the Smith's is: its family choice)
		local list = {}
		for _, o in ipairs(orders.orders(p)) do
			local _, ok = orders.progress(p, o)
			if ok and o.cliente then list[#list + 1] = o.n end
		end
		table.sort(list)
		if #list == 0 and p.commesse.fabbro then
			a.modal = { k = "famiglia", n = p.commesse.fabbro.n }
			return true
		end
		local them = {}
		for _, n in ipairs(list) do them[#them + 1] = { n = n } end
		deliver(a, them, false)
		return true
	elseif kind == "scena" then
		a.leave = delivery.cmd(a, x)
		return true
	elseif kind == "cartellino" then
		local o = find(p, tonumber(x))
		if o then a.modal = { k = o == p.commesse.fabbro and "famiglia" or "carta", n = o.n } end
		return true
	elseif kind == "libro" then
		local list = orders.clients(p)
		a.modal = { k = "libro", sel = list[1] and list[1].id }
		return true
	elseif kind == "modale" then
		-- outside the window, or INDIETRO: the swap goes back to its card, the rest closes
		if a.modal and a.modal.k == "scambio" then a.modal = { k = "carta", n = a.modal.n } else a.modal = nil end
		return true
	elseif kind == "niente" then
		return true
	end
	return a.modal ~= nil and modal_cmd(a, kind, x) or false
end

-- Gives back the miniatures loaded for the tab
-- Every frame (the delivery's scene): true when the screen must be made again
function M.update(a, dt)
	return delivery.update(a, dt)
end

function M.release(a)
	for _, id in ipairs(a.minis or {}) do illustrations.map_mini_release(id) end
	a.minis = {}
	for _, b in ipairs(a.busts or {}) do illustrations.client_release(b[1], b[2]) end
	a.busts = {}
end

return M
