-- The SHOP (Sergio, 18 Nov: the ARMERIA went into the ZAINO, behind POTENZIA; the
-- home's door is now the Smith's shop, WB-080): the Smith's four offers (one per
-- slot, among the pieces you don't have, at the shop's price) and the ten pieces of
-- the day (at the full price), as the big piece cards with their rows and price
-- (menu/gear_ui.lua); USA UN BUONO and COMPRA. On the left the apprentice really
-- wearing the ware chosen, beside it the column of what you wear; on the right the
-- stats. Rebuilt at every tap.
--
--   local a = armeria.new(profile, from)
--   armeria.update(a, dt)
--   armeria.on_input(a, action_id, action) -> "indietro" or nil
--   armeria.destroy(a)

local ui = require "ui.ui"
local kit = require "ui.kit"
local coins = require "ui.coins"
local scoria = require "battle.scoria"
local equip = require "sim.gear"
local profile = require "menu.profile"
local wallet = require "sim.wallet"
local gear_ui = require "menu.gear_ui"
local outline = require "menu.outline"
local orders_ui = require "menu.orders_ui"
local forge_ui = require "menu.forge_ui"
local orders = require "sim.orders"
local card_list = require "menu.card_list"
local sheen = require "ui.sheen"
local T = require("lang.text").armory
local TG = require("lang.text").gear_ui
local TP = require("lang.text").pieces
local common = require("lang.text").common

local M = {}

local KC = kit.C
-- where the tabs start, as in the ZAINO
local TABS_X = 300

local function copy(t)
	if type(t) ~= "table" then return t end
	local o = {}
	for k, v in pairs(t) do o[k] = copy(v) end
	return o
end

-- BOTTEGA ---------------------------------------------------------------------------

-- time until the shop changes: the day turns at wallet.DAY_HOUR in the morning
local function until_change()
	local t = os.date("*t", os.time() - wallet.DAY_HOUR * 3600)
	local left = (23 - t.hour) * 60 + (59 - t.min)
	return string.format("%dH %dM", math.floor(left / 60), left % 60)
end

-- The wares as the big piece cards of the ZAINO, with their rows and their price
-- (Sergio, 27 Nov: in the shop the values are worth seeing), two in a row in a window
-- that scrolls (menu/card_list.lua): the Smith's offers first (hot price, the discount's
-- badge), then the pieces of the day (one you have: TUO, its gold line if you wear it).
-- A tap tries the ware on the apprentice, a second tap takes it off
local VIEW = { x = 418, y = 160, w = 612, h = 446 }
local COLS, TOP, GAP = { 430, 726 }, 176, 14
local TOK_X, TOK_Y, TOK_S, TOK_GAP = 336, 180, 66, 12

local function shop(a)
	local p = a.prof
	local g = a.mid
	local x = 430
	local today = wallet.today()
	local act = profile.active_loadout(p)
	-- the Smith and his offers, one per slot
	kit.pic(g, "tondo_oro", x - 6, 92, 58, 58)
	local face = gui.new_pie_node(vmath.vector3(x + 23 - g.ox, g.oy - 121, 0), vmath.vector3(50, 50, 0))
	gui.set_clipping_mode(face, gui.CLIPPING_MODE_STENCIL)
	gui.set_parent(face, g.node)
	local img = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(56, 56, 0))
	gui.set_texture(img, "ritratti")
	gui.play_flipbook(img, "fabbro_calma")
	gui.set_parent(img, face)
	kit.text(g, T.offers, x + 60, 120, 26, KC.HOT, "start", 1)
	kit.text(g, kit.upper(T.change_in:format(until_change())), x + 62, 143, 18, KC.MUTE, "start", 0.5)

	a.list = card_list.new(g, VIEW, a.scroll)
	a.cards = {}
	local y = TOP
	local function place(items)
		for i, it in ipairs(items) do
			local cx, cy = COLS[(i - 1) % 2 + 1], y + math.floor((i - 1) / 2) * (gear_ui.CARD_H + GAP)
			local set, slot = it.set, it.slot
			local own = wallet.owns(p, set, slot)
			local sel = a.ware and a.ware[1] == set and a.ware[2] == slot and (a.ware[3] ~= nil) == it.offer
			local cg = card_list.item(a.list, cx, cy - 12, gear_ui.CARD_H + 12)
			local card = gear_ui.card(cg, cx, cy, { set = set, slot = slot, level = own and wallet.level(p, set, slot) or nil,
				lit = own and wallet.sign(p, set, slot) or 0, worn = own and act.gear[slot] == set, sel = sel, sheen = a.sheen,
				own = own, price = not own and { it.price, it.offer } or nil, badge = not own and it.badge or nil })
			if sel then gui.set_position(card.node, gui.get_position(card.node) + vmath.vector3(0, 5, 0)) end
			if not own then
				card_list.zone(a.list, a.buttons, cx, cy, gear_ui.CARD_W, gear_ui.CARD_H, "merce:" .. set .. ":" .. slot .. ":" .. (it.offer and 1 or 0))
			end
		end
		if #items > 0 then y = y + math.ceil(#items / 2) * (gear_ui.CARD_H + GAP) - GAP end
	end
	local offers, full, list = wallet.shop(p, today), wallet.PRICE_CATALOG, {}
	for _, sl in ipairs(equip.SLOTS) do
		local set = offers[sl.id]
		if set then
			local price = wallet.price(p, set, sl.id, true)
			list[#list + 1] = { set = set, slot = sl.id, price = price, offer = true,
				badge = "−" .. math.floor((1 - price / full) * 100 + 0.5) .. "%" }
		end
	end
	place(list)
	-- the pieces of the day, under their title
	local tg = card_list.item(a.list, x, y + 18, 34)
	kit.text(tg, T.day, x, y + 46, 22, KC.SAND, "start", 1)
	kit.text(tg, kit.upper(T.day_line), x + 226, y + 46, 17, KC.MUTE, "start", 0.5)
	y = y + 64 + 12
	list = {}
	for _, it in ipairs(wallet.day(today)) do
		list[#list + 1] = { set = it[1], slot = it[2], price = wallet.price(p, it[1], it[2], false), offer = false }
	end
	place(list)
	card_list.done(a.list, g, y)

	-- pay with a voucher, or with Scaglie
	local w = a.ware
	-- without the network nothing is bought (the server keeps the progress, choice 2A)
	local net = profile.can_spend()
	local usable = w and not wallet.owns(p, w[1], w[2]) and p.buoni > 0 and net
	local vb = kit.secondary(a.low2, T.use_voucher, 430, 640, 270, 62,
		{ icon = "buono", sub = kit.upper(T.you_have:format(p.buoni)), sub_color = KC.HOT_BOTTOM, off = not usable })
	kit.button(a.buttons, vb, "buono", { spento = not usable })
	-- or with its family's fragments, at the full price (docs/commesse.md): only once the Smith has called
	if p.commesse and p.commesse.aperta then
		local fcost = w and orders.in_fragments(wallet.price(p, w[1], w[2], false))
		local have = w and orders.fragments(p, w[1]) or 0
		local fok = w and not wallet.owns(p, w[1], w[2]) and have >= fcost and net
		local fb = kit.secondary(a.low, T.with_fragments, 150, 640, 262, 62, { icon = "frammento_" .. (w and w[1] or "fabbro"),
			sub = w and kit.upper(T.fragments_cost:format(fcost, have)) or kit.upper(T.pick_family), off = not fok })
		kit.button(a.buttons, fb, "frammenti", { spento = not fok })
	end
	local price = w and wallet.price(p, w[1], w[2], w[3])
	local ok = w and not wallet.owns(p, w[1], w[2]) and p.scaglie >= price and net
	local sub = not w and TP.pick_ware or (wallet.owns(p, w[1], w[2]) and TP.in_wardrobe) or (not net and TP.need_network)
		or (p.scaglie < price and TP.missing:format(coins.format(price - p.scaglie))) or TP.price_only:format(coins.format(price))
	a.action = kit.action(a.right, TP.buy, 948, 628, 308, 80, { icon = "scaglia", size = 46, off = not ok, sub = kit.upper(sub) })
	kit.button(a.buttons, a.action, "compra", { main = true, spento = not ok })
	return w
end

-- Screen ----------------------------------------------------------------------------

local GROUPS = { "left", "mid", "rt", "right", "low", "low2", "over", "mlow", "mright", "stop" }

local function build(a)
	if a.head then kit.header_delete(a.head) end
	for _, k in ipairs(GROUPS) do
		if a[k] then gui.delete_node(a[k].node) end
		a[k] = nil
	end
	-- (the list stays where it was scrolled)
	if a.list then a.scroll = a.list.scroll end
	a.buttons, a.figure, a.action, a.list, a.sheen = {}, nil, nil, nil, nil
	a.outline = nil
	orders_ui.release(a)
	local p = a.prof
	a.head = kit.header(a.buttons, common.shop, KC.PURPLE, "indietro", a.from or common.home)
	-- the three tabs, once the Smith has called: COMMESSE (his orders), FORNACE (the
	-- Forge, where Ossidiana is spent) and BANCO (the shop)
	-- (a test profile sees them at once: the test bench is in COMMESSE)
	local open = (p.commesse and p.commesse.aperta) or profile.test
	if not open then a.tab = "banco" end
	a.tab = a.tab or "commesse"
	if open then
		local at = { commesse = 1, fornace = 2, banco = 3 }
		kit.tabs(a.head.top_left, a.buttons, TABS_X, 28,
			{ { T.tab_orders, "scheda:commesse" }, { T.tab_forge, "scheda:fornace" }, { T.tab_bench, "scheda:banco" } },
			at[a.tab] or 1, KC.PURPLE, true)
		-- by COMMESSE, how many are ready (the word is smaller when another tab is open)
		local ready = orders_ui.news(p)
		if ready and ready > 0 then orders_ui.badge(a.head.top_left, TABS_X + (#T.tab_orders * 14 + 64) + 13 - (a.tab ~= "commesse" and 21 or 0), 28 + 26, ready) end
	end
	a.wallet = coins.wallet(p.scaglie or 0, p.ossidiana or 0, kit.group(a.head.top_right, 1110, 44).node, 0, 0)
	coins.vouchers(a.wallet, p.buoni or 0)
	a.left = kit.anchor(0, 0, gui.ANCHOR_LEFT)
	a.mid = kit.anchor(0, 0)
	a.rt = kit.anchor(1280, 0, gui.ANCHOR_RIGHT)
	a.right = kit.anchor(1280, 720, gui.ANCHOR_RIGHT, gui.ANCHOR_BOTTOM)
	a.low = kit.anchor(0, 720, gui.ANCHOR_LEFT, gui.ANCHOR_BOTTOM)
	a.low2 = kit.anchor(0, 720, nil, gui.ANCHOR_BOTTOM)
	if a.tab ~= "fornace" then forge_ui.release(a, true) end
	if a.tab ~= "banco" then a.look = nil end
	if a.tab == "commesse" then
		outline.off()
		orders_ui.board(a)
		return
	elseif a.tab == "fornace" then
		-- the Forge (docs/commesse.md "La Fornace"): the wall in vetrina, the throws
		outline.off()
		forge_ui.board(a)
		return
	end
	local act = profile.active_loadout(p)
	-- the ware chosen: really on the apprentice (Sergio, 27 Nov), lit in its slot's
	-- colour, in its place in the column of what you wear, in the stats
	local w = a.ware
	local try = w and not wallet.owns(p, w[1], w[2]) and { w[1], w[2] } or nil
	local gear, look = gear_ui.tried(a, act, try)
	gear_ui.devil(a, a.left, 215, 600, 395, look)
	gear_ui.light_try(a, try)
	a.sheen = sheen.new(a.mid, 330, 1050)
	gear_ui.tokens(a, a.left, act, try, TOK_X, TOK_Y, TOK_S, TOK_GAP, a.sheen)
	if try then
		kit.text(a.left, kit.upper(T.trying), 24, 184, 20, KC.HOT, "start", 0.5)
		kit.text(a.left, kit.upper(T.not_yours), 24, 206, 16, KC.SAND, "start", 0.5)
	end
	shop(a)
	gear_ui.swap_check(a, a.left, gear, 215, 600, 395, a.just == "bought")
	a.just = nil
	local a2
	if try then
		a2 = copy(act)
		a2.gear[try[2]] = try[1]
	end
	if a.sheet then
		-- all the stats over the middle: the bench and the column are hidden (and their taps)
		gui.set_enabled(a.mid.node, false)
		a.over = kit.anchor(0, 0)
		gear_ui.sheet(a, a.over, act, a2, TG.back_to_pieces)
	else
		gear_ui.stats_short(a, a.rt, 1040, 106, 210, act, a2)
	end
end

function M.new(prof, from)
	local a = { prof = prof, colore = ui.C.SQUADRA[1], from = from }
	a.back = kit.scene(250, 420, { accent = KC.PURPLE, bg = "negozio" })
	build(a)
	return a
end

local function run_cmd(a, ui_action)
	local kind, x = ui_action:match("^(%a+):?(.*)$")
	local p = a.prof
	local s1, s2 = x:match("^([^:]*):?(.*)$")
	if orders_ui.cmd(a, kind, x) or forge_ui.cmd(a, kind, x) then
		-- (a tap of the COMMESSE or of the FORNACE tab)
	elseif kind == "scheda" then
		a.tab, a.sheet, a.modal, a.scene, a.melt = x, nil, nil, nil, nil
	elseif kind == "foglio" then
		a.sheet = not a.sheet
	elseif kind == "merce" then
		-- an offer is bought at the shop's price; the day's pieces at the full one; a
		-- second tap takes it off the apprentice
		local set, slot, offer = x:match("^([^:]*):([^:]*):(%d)$")
		offer = offer == "1" and wallet.shop(p, wallet.today())[slot] == set
		local w = a.ware
		if w and w[1] == set and w[2] == slot and (w[3] ~= nil) == offer then
			a.ware = nil
		else
			a.ware = { set, slot, offer and wallet.today() or nil }
		end
	elseif kind == "gettone" then
		-- its place in the column: the ware tried there comes off
		if a.ware and a.ware[2] == x then a.ware = nil end
	elseif (kind == "compra" or kind == "frammenti" or kind == "buono") and a.ware then
		local w = a.ware
		local done
		if kind == "buono" then
			done = profile.act(p, { k = "buono", set = w[1], slot = w[2] })
		else
			done = profile.act(p, { k = "compra", set = w[1], slot = w[2], offer = kind == "compra" and w[3] ~= nil or nil,
				frammenti = kind == "frammenti" or nil })
			if done then sound.play("#scaglia") end
		end
		-- bought: it's yours, in the ZAINO (off the apprentice, the card says TUO)
		if done then a.ware, a.just = nil, "bought" end
	end
	build(a)
end

function M.update(a, dt)
	if a.figure then scoria.update(a.figure, dt, a.st) end
	sheen.update(a.sheen, dt)
	-- the delivery's scene: at the receipt the screen is made again, with its buttons
	if a.tab == "commesse" and orders_ui.update(a, dt) then build(a) end
	if a.tab == "fornace" and forge_ui.update(a, dt) then build(a) end
	if a.tab ~= "fornace" then forge_ui.warm(a) end
	if a.outline then outline.update(a.outline) end
end

function M.on_input(a, action_id, action)
	-- while the Forge plays, the finger is its own
	if forge_ui.input(a, action_id, action) then return nil end
	if a.tab == "banco" and not a.sheet and card_list.input(a.list, a.buttons, action_id, action) then return nil end
	local ui_action = ui.touch(a.buttons, action_id, action)
	if ui_action == "indietro" then
		-- (a window of the COMMESSE closes first)
		if not (a.modal or a.scene or a.melt) then return "indietro" end
		a.modal, a.scene, a.melt = nil, nil, nil
		build(a)
		return nil
	end
	if ui_action then run_cmd(a, ui_action) end
	-- POTENZIA on the delivery's receipt: the ZAINO (main/game.gui_script)
	local leave = a.leave
	a.leave = nil
	return leave
end

function M.destroy(a)
	outline.off()
	orders_ui.release(a)
	forge_ui.release(a)
	kit.header_delete(a.head)
	for _, k in ipairs(GROUPS) do
		if a[k] then gui.delete_node(a[k].node) end
	end
	kit.scene_drop(a.back)
end

return M
