-- The ARMERIA (Figma "RIORGANIZZAZIONE MENU · 14 nov", Consigliata/4 and /5;
-- Sergio, 14 Nov): the Smith's place, from the home's door. Two tabs:
--   POTENZIA  the piece chosen (on the devil or among the others of its slot):
--             its grade, its level with the bar and the steps at 10 20 30, what
--             it does now and at the next level, the next step, the Proof; the
--             other pieces of that slot you own; the price and POTENZIA
--   BOTTEGA   the Smith's four offers (one per slot, among the pieces you don't
--             have, at the shop's price) and the ten pieces of the day (at the
--             full price); USA UN BUONO and COMPRA
-- On the left the devil with its pieces labeled, on the right the stats.
-- Rebuilt at every tap; buying a step shows its scene (ui/step_scene.lua).
--
--   local a = armeria.new(profile, tab)        -- tab: "potenzia" (default) or "bottega"
--   armeria.update(a, dt)
--   armeria.on_input(a, action_id, action) -> "indietro" or nil
--   armeria.destroy(a)

local ui = require "ui.ui"
local kit = require "ui.kit"
local coins = require "ui.coins"
local scoria = require "battle.scoria"
local equip = require "sim.gear"
local profile = require "menu.profile"
local wallet = require "menu.wallet"
local gear_ui = require "menu.gear_ui"
local bench = require "menu.bench"
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

-- the piece chosen: { set, slot }; by default the one worn in the slot chosen
local function chosen(a)
	local g = profile.active_loadout(a.prof).gear
	if a.sel and wallet.owns(a.prof, a.sel[1], a.sel[2]) then return a.sel end
	local slot = a.slot or "mask"
	if g[slot] then return { g[slot], slot } end
	for _, f in ipairs(equip.SETS) do
		if wallet.owns(a.prof, f.id, slot) then return { f.id, slot } end
	end
	return nil
end

-- POTENZIA: the bench (menu/bench.lua), the same card the ZAINO opens --------------

local function upgrade(a)
	local sel = chosen(a)
	bench.draw(a, a.mid, sel)
	bench.footer(a, a.low2, a.right, sel)
	return sel
end

-- BOTTEGA ---------------------------------------------------------------------------

-- a ware w x h at (x, y): its picture, the family's line, slot and family, the price
local function ware(a, x, y, w, h, set, slot, price, o)
	local g = a.mid
	-- the chosen one: the warm panel
	kit.panel(kit.group(g, x + w / 2, y + h / 2).node, w, h, (o.hot or o.sel) and "pannello_caldo" or "pannello")
	local isz = h * 0.46
	kit.pic(g, gear_ui.icon(set, slot, 1), x + w / 2 - isz / 2, y + h * 0.05, isz, isz)
	kit.rect(g, x + 14, y + h * 0.53, w - 28, 4, gear_ui.color(set))
	if h >= 130 then
		kit.text(g, gear_ui.slot_of(slot).name, x + w / 2, y + h * 0.57 + 16, 18, KC.SAND, "middle")
		kit.text(g, equip.BY_ID[set].name, x + w / 2, y + h * 0.57 + 34, 16, gear_ui.color(set), "middle")
	else
		kit.text(g, equip.BY_ID[set].name, x + w / 2, y + h * 0.58 + 15, 17, gear_ui.color(set), "middle")
	end
	local py = y + h - 28
	if o.owned then
		kit.text(g, kit.upper(T.yours), x + w / 2, py + 18, 18, KC.MUTE, "middle")
	elseif o.old then
		local ow = kit.width(kit.text(g, coins.format(o.old), x + 14, py + 17, 16, KC.SAND))
		-- the stroke across it, as wide as the number (never deformed)
		kit.pic(g, "barrato", x + 14 + ow / 2 - 16, py + 5, 32, 32 * 34 / 78)
		kit.piece(g, "scaglia", x + w - 62, py + 10, 20)
		kit.text(g, coins.format(price), x + w - 50, py + 17, 18, KC.HOT)
	else
		kit.piece(g, "scaglia", x + w / 2 - 16, py + 10, 20)
		kit.text(g, coins.format(price), x + w / 2 - 4, py + 17, 18, KC.SAND)
	end
	if o.badge then
		kit.pic(g, "sconto", x + w - 66, y - 12, 80, 32)
		kit.text(g, o.badge, x + w - 26, y + 10, 18, KC.SAND, "middle")
	end
	if not o.owned then kit.zone(g, a.buttons, x, y, w, h, "merce:" .. set .. ":" .. slot) end
end

-- time until the shop changes (midnight)
local function until_midnight()
	local t = os.date("*t")
	local left = (23 - t.hour) * 60 + (59 - t.min)
	return string.format("%dH %dM", math.floor(left / 60), left % 60)
end

local function shop(a)
	local p = a.prof
	local g = a.mid
	local x = 430
	local today = wallet.today()
	-- the Smith and his four offers
	kit.pic(g, "tondo_oro", x - 6, 92, 58, 58)
	local face = gui.new_pie_node(vmath.vector3(x + 23 - g.ox, g.oy - 121, 0), vmath.vector3(50, 50, 0))
	gui.set_clipping_mode(face, gui.CLIPPING_MODE_STENCIL)
	gui.set_parent(face, g.node)
	local img = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(56, 56, 0))
	gui.set_texture(img, "ritratti")
	gui.play_flipbook(img, "fabbro_calma")
	gui.set_parent(img, face)
	kit.text(g, T.offers, x + 60, 120, 26, KC.HOT, "start", 1)
	kit.text(g, kit.upper(T.change_in:format(until_midnight())), x + 62, 143, 18, KC.MUTE, "start", 0.5)
	local offers = wallet.shop(p, today)
	local full = wallet.PRICE_CATALOG
	local i = 0
	for _, sl in ipairs(equip.SLOTS) do
		local set = offers[sl.id]
		if set then
			local price = wallet.price(p, sl.id, true)
			local off = math.floor((1 - price / full) * 100 + 0.5)
			ware(a, x + i * 148, 160, 136, 166, set, sl.id, price, { hot = true, old = full, badge = "−" .. off .. "%",
				sel = a.ware and a.ware[1] == set and a.ware[2] == sl.id and a.ware[3] })
			i = i + 1
		end
	end
	-- the pieces of the day
	kit.text(g, T.day, x, 358, 22, KC.SAND, "start", 1)
	kit.text(g, kit.upper(T.day_line), x + 226, 358, 17, KC.MUTE, "start", 0.5)
	for k, it in ipairs(wallet.day(today)) do
		local set, slot = it[1], it[2]
		ware(a, x + ((k - 1) % 5) * 117, 372 + math.floor((k - 1) / 5) * 118, 109, 110, set, slot, wallet.price(p, slot, false),
			{ owned = wallet.owns(p, set, slot), sel = a.ware and a.ware[1] == set and a.ware[2] == slot and not a.ware[3] })
	end
	-- pay with a voucher, or with Scaglie
	local w = a.ware
	local usable = w and not wallet.owns(p, w[1], w[2]) and p.buoni > 0
	local vb = kit.plate(a.low2, 430, 638, 260, 64, KC.HOT, { sk = 0, fill = KC.SAND })
	kit.piece(a.low2, "buono", 473, 669, 46)
	kit.text(vb.g, T.use_voucher, 502, 668, 22, usable and KC.INK or kit.with_alpha(KC.INK, 0.45))
	kit.text(vb.g, kit.upper(T.you_have:format(p.buoni)), 504, 690, 17, kit.with_alpha(KC.INK, 0.75), "start", 0.5)
	kit.button(a.buttons, vb, "buono", { spento = not usable })
	local price = w and wallet.price(p, w[2], w[3])
	local ok = w and not wallet.owns(p, w[1], w[2]) and p.scaglie >= price
	local sub = not w and TP.pick_ware or (wallet.owns(p, w[1], w[2]) and TP.in_wardrobe)
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
	local p = a.prof
	a.head = kit.header(a.buttons, common.armory, KC.PURPLE, "indietro", a.from or common.home)
	a.wallet = coins.wallet(p.scaglie or 0, p.ossidiana or 0, kit.group(a.head.top_right, 1110, 44).node, 0, 0)
	coins.vouchers(a.wallet, p.buoni or 0)
	kit.tabs(a.head.top_left, a.buttons, 290, 28, { { T.tab_upgrade, "banco:potenzia" }, { T.tab_shop, "banco:bottega" } },
		a.tab == "bottega" and 2 or 1, KC.PURPLE, true)
	a.left = kit.anchor(0, 0, gui.ANCHOR_LEFT)
	a.mid = kit.anchor(0, 0)
	a.rt = kit.anchor(1280, 0, gui.ANCHOR_RIGHT)
	a.right = kit.anchor(1280, 720, gui.ANCHOR_RIGHT, gui.ANCHOR_BOTTOM)
	a.low = kit.anchor(0, 720, gui.ANCHOR_LEFT, gui.ANCHOR_BOTTOM)
	a.low2 = kit.anchor(0, 720, nil, gui.ANCHOR_BOTTOM)
	local act = profile.active_loadout(p)
	gear_ui.devil(a, a.left, 250, 600, 360)
	local try, focus, up
	if a.tab == "bottega" then
		local w = shop(a)
		-- the ware chosen: tried on the devil
		if w then try, focus = { w[1], w[2] }, w[2] end
	else
		local sel = upgrade(a)
		focus = sel and sel[2]
		-- the piece one level up: the column says what +1 LIVELLO changes
		-- (Sergio, 15 Nov 22:48: the stats wherever the gear changes)
		local nxt = sel and wallet.next(p, sel[1], sel[2])
		if nxt then up = { sel[1], sel[2], nxt.level } end
	end
	gear_ui.worn(a, a.left, act, 250, 600, 360, 36, { 130, 248, 366, 484 }, 72, focus, try)
	local a2
	if try and act.gear[try[2]] ~= try[1] then
		a2 = copy(act)
		a2.gear[try[2]] = try[1]
	elseif up and act.gear[up[2]] == up[1] then
		a2 = copy(act)
		a2.levels = wallet.levels(p, act)
		a2.levels[up[2]] = up[3]
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

function M.new(prof, tab, from)
	local a = { prof = prof, tab = tab or "potenzia", colore = ui.C.SQUADRA[1], from = from }
	a.back = kit.scene(250, 420, { accent = KC.PURPLE, bg = "armeria" })
	build(a)
	return a
end

local function run_cmd(a, ui_action)
	local kind, x = ui_action:match("^(%a+):?(.*)$")
	local p = a.prof
	local s1, s2 = x:match("^([^:]*):?(.*)$")
	if kind == "banco" then
		a.tab, a.sheet = x, nil
	elseif kind == "foglio" then
		a.sheet = not a.sheet
	elseif kind == "posto" then
		a.slot, a.sel, a.sheet = x, nil, nil
	elseif kind == "pezzo" then
		a.sel, a.slot = { s1, s2 }, s2
	elseif kind == "potenzia" or kind == "firma" then
		bench.run(a, kind, chosen(a))
	elseif kind == "merce" then
		-- an offer is bought at the shop's price; the day's pieces at the full one
		local offer = wallet.shop(p, wallet.today())[s2] == s1
		a.ware = { s1, s2, offer and wallet.today() or nil }
	elseif kind == "compra" and a.ware then
		if wallet.buy(p, a.ware[1], a.ware[2], a.ware[3]) then sound.play("#scaglia") end
	elseif kind == "buono" and a.ware then
		wallet.use_voucher(p, a.ware[1], a.ware[2])
	end
	profile.save(p)
	build(a)
	bench.after(a)
end

function M.update(a, dt)
	if a.figure then scoria.update(a.figure, dt, a.st) end
	bench.update(a, dt)
end

function M.on_input(a, action_id, action)
	-- the step's scene: a tap skips it
	if bench.input(a, action_id, action) then return nil end
	local ui_action = ui.touch(a.buttons, action_id, action)
	if ui_action == "indietro" then return "indietro" end
	if ui_action then run_cmd(a, ui_action) end
	return nil
end

function M.destroy(a)
	bench.delete(a)
	kit.header_delete(a.head)
	for _, k in ipairs(GROUPS) do
		if a[k] then gui.delete_node(a[k].node) end
	end
	kit.scene_drop(a.back)
end

return M
