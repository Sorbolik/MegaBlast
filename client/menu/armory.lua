-- The SHOP (Sergio, 18 Nov: the ARMERIA went into the ZAINO, behind POTENZIA; the
-- home's door is now the Smith's shop, WB-080): the Smith's four offers (one per
-- slot, among the pieces you don't have, at the shop's price) and the ten pieces of
-- the day (at the full price); USA UN BUONO and COMPRA.
-- On the left the devil with its pieces labeled (the ware chosen tried on), on the
-- right the stats. Rebuilt at every tap.
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
local T = require("lang.text").armory
local TG = require("lang.text").gear_ui
local TP = require("lang.text").pieces
local common = require("lang.text").common

local M = {}

local KC = kit.C

local function copy(t)
	if type(t) ~= "table" then return t end
	local o = {}
	for k, v in pairs(t) do o[k] = copy(v) end
	return o
end

-- BOTTEGA ---------------------------------------------------------------------------

-- moves a text made at x = 0 to start at x
local function shift(n, x)
	local pos = gui.get_position(n)
	pos.x = pos.x + x
	gui.set_position(n, pos)
end

-- a ware w x h at (x, y): the piece in its slot frame (the same as in the ZAINO,
-- WB-078: no family line, Sergio 18 Nov), under it the family and the price
local function ware(a, x, y, w, h, set, slot, price, o)
	local g = a.mid
	local named = h >= 130
	local s = math.min(w, h - (named and 56 or 32))
	gear_ui.slot(g, x + (w - s) / 2, y, s, { set = set, slot = slot, sel = o.sel })
	if named then
		kit.text(g, equip.BY_ID[set].name, x + w / 2, y + s + 22, 17, KC.SAND, "middle")
	end
	local py = y + h - 28
	if o.owned then
		kit.text(g, kit.upper(T.yours), x + w / 2, py + 18, 18, KC.MUTE, "middle")
	elseif o.old and w >= 130 then
		-- old price, coin and new price as one group, centered under the frame
		local on = kit.text(g, coins.format(o.old), 0, py + 17, 16, KC.SAND)
		local nn = kit.text(g, coins.format(price), 0, py + 17, 18, KC.HOT)
		local ow, nw = kit.width(on), kit.width(nn)
		local left = x + (w - (ow + 10 + 24 + nw)) / 2
		shift(on, left)
		-- the stroke across it, as wide as the number (never deformed)
		kit.pic(g, "barrato", left + ow / 2 - 16, py + 5, 32, 32 * 34 / 78)
		kit.piece(g, "scaglia", left + ow + 20, py + 10, 20)
		shift(nn, left + ow + 10 + 24)
	else
		-- (a narrow offer: only the new price, hot; the badge says the discount)
		local nn = kit.text(g, coins.format(price), 0, py + 17, 18, o.old and KC.HOT or KC.SAND)
		local nw = kit.width(nn)
		local left = x + (w - (24 + nw)) / 2
		kit.piece(g, "scaglia", left + 10, py + 10, 20)
		shift(nn, left + 24)
	end
	if o.badge then
		kit.pic(g, "sconto", x + w - 72, y - 12, 80, 32)
		kit.text(g, o.badge, x + w - 32, y + 10, 18, KC.SAND, "middle")
	end
	if not o.owned then kit.zone(g, a.buttons, x, y, w, h, "merce:" .. set .. ":" .. slot) end
end

-- time until the shop changes: the day turns at wallet.DAY_HOUR in the morning
local function until_change()
	local t = os.date("*t", os.time() - wallet.DAY_HOUR * 3600)
	local left = (23 - t.hour) * 60 + (59 - t.min)
	return string.format("%dH %dM", math.floor(left / 60), left % 60)
end

local function shop(a)
	local p = a.prof
	local g = a.mid
	local x = 430
	local today = wallet.today()
	-- the Smith and his offers, one per slot (five since the gloves: in the
	-- columns of the pieces of the day)
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
	local offers = wallet.shop(p, today)
	local full = wallet.PRICE_CATALOG
	local i = 0
	for _, sl in ipairs(equip.SLOTS) do
		local set = offers[sl.id]
		if set then
			local price = wallet.price(p, set, sl.id, true)
			local off = math.floor((1 - price / full) * 100 + 0.5)
			ware(a, x + i * 117, 166, 109, 154, set, sl.id, price, { hot = true, old = full, badge = "−" .. off .. "%",
				sel = a.ware and a.ware[1] == set and a.ware[2] == sl.id and a.ware[3] })
			i = i + 1
		end
	end
	-- the pieces of the day
	kit.text(g, T.day, x, 358, 22, KC.SAND, "start", 1)
	kit.text(g, kit.upper(T.day_line), x + 226, 358, 17, KC.MUTE, "start", 0.5)
	for k, it in ipairs(wallet.day(today)) do
		local set, slot = it[1], it[2]
		ware(a, x + ((k - 1) % 5) * 117, 372 + math.floor((k - 1) / 5) * 118, 109, 110, set, slot, wallet.price(p, set, slot, false),
			{ owned = wallet.owns(p, set, slot), sel = a.ware and a.ware[1] == set and a.ware[2] == slot and not a.ware[3] })
	end
	-- pay with a voucher, or with Scaglie
	local w = a.ware
	-- without the network nothing is bought (the server keeps the progress, choice 2A)
	local net = profile.can_spend()
	local usable = w and not wallet.owns(p, w[1], w[2]) and p.buoni > 0 and net
	local vb = kit.secondary(a.low2, T.use_voucher, 430, 640, 270, 62,
		{ icon = "buono", sub = kit.upper(T.you_have:format(p.buoni)), sub_color = KC.HOT_BOTTOM, off = not usable })
	kit.button(a.buttons, vb, "buono", { spento = not usable })
	local price = w and wallet.price(p, w[1], w[2], w[3])
	local ok = w and not wallet.owns(p, w[1], w[2]) and p.scaglie >= price and net
	local sub = not w and TP.pick_ware or (wallet.owns(p, w[1], w[2]) and TP.in_wardrobe) or (not net and TP.need_network)
		or (p.scaglie < price and TP.missing:format(coins.format(price - p.scaglie))) or TP.price_only:format(coins.format(price))
	a.action = kit.action(a.right, TP.buy, 948, 628, 308, 80, { size = 46, off = not ok, sub = kit.upper(sub) })
	kit.button(a.buttons, a.action, "compra", { main = true, spento = not ok })
	return w
end

-- Screen ----------------------------------------------------------------------------

local GROUPS = { "left", "mid", "rt", "right", "low", "low2", "over" }

local function build(a)
	if a.head then kit.header_delete(a.head) end
	for _, k in ipairs(GROUPS) do
		if a[k] then gui.delete_node(a[k].node) end
		a[k] = nil
	end
	a.buttons, a.figure, a.action = {}, nil, nil
	a.outline = nil
	local p = a.prof
	a.head = kit.header(a.buttons, common.shop, KC.PURPLE, "indietro", a.from or common.home)
	a.wallet = coins.wallet(p.scaglie or 0, p.ossidiana or 0, kit.group(a.head.top_right, 1110, 44).node, 0, 0)
	coins.vouchers(a.wallet, p.buoni or 0)
	a.left = kit.anchor(0, 0, gui.ANCHOR_LEFT)
	a.mid = kit.anchor(0, 0)
	a.rt = kit.anchor(1280, 0, gui.ANCHOR_RIGHT)
	a.right = kit.anchor(1280, 720, gui.ANCHOR_RIGHT, gui.ANCHOR_BOTTOM)
	a.low = kit.anchor(0, 720, gui.ANCHOR_LEFT, gui.ANCHOR_BOTTOM)
	a.low2 = kit.anchor(0, 720, nil, gui.ANCHOR_BOTTOM)
	local act = profile.active_loadout(p)
	gear_ui.devil(a, a.left, 215, 600, 395)
	local try, focus
	local w = shop(a)
	-- the ware chosen: tried on the devil
	if w then try, focus = { w[1], w[2] }, w[2] end
	gear_ui.worn(a, a.left, act, 215, 600, 395, 36, { 130, 248, 366, 484 }, 72, focus, try, true)
	local a2
	if try and act.gear[try[2]] ~= try[1] then
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
	if kind == "foglio" then
		a.sheet = not a.sheet
	elseif kind == "merce" then
		-- an offer is bought at the shop's price; the day's pieces at the full one
		local offer = wallet.shop(p, wallet.today())[s2] == s1
		a.ware = { s1, s2, offer and wallet.today() or nil }
	elseif kind == "compra" and a.ware then
		if profile.act(p, { k = "compra", set = a.ware[1], slot = a.ware[2], offer = a.ware[3] ~= nil }) then sound.play("#scaglia") end
	elseif kind == "buono" and a.ware then
		profile.act(p, { k = "buono", set = a.ware[1], slot = a.ware[2] })
	end
	build(a)
end

function M.update(a, dt)
	if a.figure then scoria.update(a.figure, dt, a.st) end
	if a.outline then outline.update(a.outline) end
end

function M.on_input(a, action_id, action)
	local ui_action = ui.touch(a.buttons, action_id, action)
	if ui_action == "indietro" then return "indietro" end
	if ui_action then run_cmd(a, ui_action) end
	return nil
end

function M.destroy(a)
	outline.off()
	kit.header_delete(a.head)
	for _, k in ipairs(GROUPS) do
		if a[k] then gui.delete_node(a[k].node) end
	end
	kit.scene_drop(a.back)
end

return M
