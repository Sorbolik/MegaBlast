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
local step_scene = require "ui.step_scene"
local T = require("lang.text").armory
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

-- POTENZIA --------------------------------------------------------------------------

-- a text never wider than max (a long one shrinks)
local function fit(n, max)
	local nw = kit.width(n)
	if nw > max then gui.set_scale(n, gui.get_scale(n) * (max / nw)) end
	return n
end

-- the effects on the left of the panel, the next step and the signature on the right
local RIGHT_COL = 312

local function upgrade(a)
	local p = a.prof
	local g = a.mid
	local sel = chosen(a)
	local x, w = 430, 580
	kit.panel(kit.group(g, x + w / 2, 272).node, w, 344)
	if not sel then
		kit.text(g, kit.upper(T.nothing_here), x + w / 2, 260, 18, KC.MUTE, "middle", 1)
		return
	end
	local set, slot = sel[1], sel[2]
	local level = wallet.level(p, set, slot)
	local tier = equip.tier(level)
	gear_ui.slot(g, x + 28, 128, 150, { set = set, slot = slot })
	kit.text(g, gear_ui.name(set, slot), x + 200, 156, 32, KC.SAND)
	kit.text(g, kit.upper(T.grade:format(gear_ui.ROMAN[tier], TP.grades[tier])), x + 202, 187, 20, KC.HOT, "start", 1)
	local nxt = wallet.next(p, set, slot)
	kit.text(g, nxt and T.level_to:format(level, nxt.level) or T.level_top:format(level), x + 202, 222, 23, KC.SAND)
	-- the level's bar with its steps
	kit.strip(g, "riga_scura", x + 202, 234, 340, 24)
	kit.strip(g, "barra_brace", x + 205, 237, math.max(24, 334 * level / equip.LIVELLO_MAX), 18)
	for _, t in ipairs(equip.TIER_LEVELS) do
		local tx = x + 202 + 340 * t / equip.LIVELLO_MAX
		kit.pic(g, "tacca", tx - 12, 228, 24, 22)
		kit.text(g, tostring(t), tx, 284, 17, KC.MUTE, "middle")
	end
	-- what it does now, and at the next level
	local now = equip.piece(set, slot, level)
	local after = nxt and equip.piece(set, slot, nxt.level)
	local y = 308
	for i, e in ipairs(now) do
		if e.row ~= "sign" then
			local col = e.good >= 0 and KC.MINT or KC.RED
			fit(kit.text(g, gear_ui.effect(e), x + 28, y + 17, 21, col), 200)
			if after and after[i] and after[i].good ~= e.good then
				kit.text(g, "› " .. gear_ui.effect(after[i]):match("^(%S+)"), x + RIGHT_COL - 8, y + 17, 18, KC.HOT, "end")
			end
			y = y + 30
		end
	end
	-- the next step and the Proof
	local step = equip.next_tier(level)
	local line
	if step then
		line = T.next_step:format(step, gear_ui.ROMAN[equip.tier(step)], TP.grades[equip.tier(step)])
	else
		line = T.all_steps
	end
	local rw = w - 28 - RIGHT_COL
	-- (on two lines at the " · ", to stay big enough for a phone)
	local cut = line:find(" · ", 1, true)
	local ry = 326
	for _, part in ipairs(cut and { line:sub(1, cut - 1), line:sub(cut + 4) } or { line }) do
		fit(kit.text(g, kit.upper(part), x + RIGHT_COL, ry, 18, KC.MUTE, "start", 0.5), rw)
		ry = ry + 26
	end
	ry = ry + 6
	for _, e in ipairs(now) do
		if e.row == "sign" then
			local sg = equip.SIGNS[e.stat]
			local on = e.good > 0
			fit(kit.text(g, kit.upper((on and T.sign or T.sign_off):format(sg.name)), x + RIGHT_COL, ry, 18,
				on and KC.HOT_TOP or KC.MUTE, "start", 0.5), rw)
		end
	end
	if nxt and nxt.proof > 0 then
		fit(kit.text(g, kit.upper(TP.proof:format(nxt.proof_done, nxt.proof)), x + RIGHT_COL, ry + 30, 18, KC.STEEL, "start", 0.5), rw)
	end

	-- the other pieces of that slot you have
	local slot_name = gear_ui.slot_of(slot).name
	kit.text(g, T.others:format(slot_name), x, 474, 20, KC.SAND, "start", 1)
	kit.text(g, kit.upper(T.tap_one), x + w, 474, 17, KC.MUTE, "end", 0.5)
	local n = 0
	for _, f in ipairs(equip.SETS) do
		if wallet.owns(p, f.id, slot) and n < 6 then
			local cx = x + n * 100
			gear_ui.slot(g, cx, 494, 86, { set = f.id, slot = slot, level = wallet.level(p, f.id, slot),
				worn = profile.active_loadout(p).gear[slot] == f.id, sel = f.id == set })
			kit.zone(g, a.buttons, cx - 6, 484, 98, 104, "pezzo:" .. f.id .. ":" .. slot)
			n = n + 1
		end
	end

	-- the price and POTENZIA
	if nxt then
		local ok = nxt.proof_done >= nxt.proof and p.scaglie >= nxt.cost
		kit.piece(a.low2, "scaglia", 717, 657, 34)
		kit.text(a.low2, coins.format(nxt.cost), 740, 666, 28, nxt.cost < (nxt.full_cost or nxt.cost) and KC.MINT or KC.SAND)
		kit.text(a.low2, TP.price_unit, 741, 690, 16, KC.MUTE, "start", 1)
		local why = nxt.proof_done < nxt.proof and TP.proof_first or p.scaglie < nxt.cost
			and TP.missing:format(coins.format(nxt.cost - p.scaglie)) or nil
		a.action = kit.action(a.right, TP.upgrade, 948, 628, 308, 80, { size = 44, off = not ok, sub = why and kit.upper(why) or nil })
		kit.button(a.buttons, a.action, "potenzia", { main = true, spento = not ok })
	else
		a.action = kit.action(a.right, TP.upgrade, 948, 628, 308, 80, { size = 44, off = true, sub = kit.upper(TP.at_max) })
	end
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
	kit.text(g, kit.upper(T.day_line:format(wallet.DAY)), x + 226, 358, 17, KC.MUTE, "start", 0.5)
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

local GROUPS = { "left", "mid", "rt", "right", "low", "low2" }

local function build(a)
	if a.head then kit.header_delete(a.head) end
	for _, k in ipairs(GROUPS) do
		if a[k] then gui.delete_node(a[k].node) end
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
	local try, focus
	if a.tab == "bottega" then
		local w = shop(a)
		-- the ware chosen: tried on the devil
		if w then try, focus = { w[1], w[2] }, w[2] end
	else
		local sel = upgrade(a)
		focus = sel and sel[2]
	end
	gear_ui.worn(a, a.left, act, 250, 600, 360, 36, { 130, 248, 366, 484 }, 72, focus, try)
	local a2
	if try and act.gear[try[2]] ~= try[1] then
		a2 = copy(act)
		a2.gear[try[2]] = try[1]
	end
	gear_ui.stats(a, a.rt, 1040, 106, 210, act, a2)
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
		a.tab = x
	elseif kind == "posto" then
		a.slot, a.sel = x, nil
	elseif kind == "pezzo" then
		a.sel, a.slot = { s1, s2 }, s2
	elseif kind == "potenzia" then
		local sel = chosen(a)
		if sel then
			local before = equip.tier(wallet.level(p, sel[1], sel[2]))
			local level = wallet.upgrade(p, sel[1], sel[2])
			if level then
				sound.play("#scaglia")
				if equip.tier(level) > before then a.step = { gear_ui.slot_of(sel[2]).name, equip.BY_ID[sel[1]].name, level } end
			end
		end
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
	if a.step then
		a.scene = step_scene.new(a.step[1], a.step[2], a.step[3], function()
			sound.play("#martello", { speed = 0.9 + 0.1 * math.random() })
		end, a.colore)
		a.step = nil
	end
end

function M.update(a, dt)
	if a.figure then scoria.update(a.figure, dt, a.st) end
	if a.scene and not step_scene.update(a.scene, dt) then
		step_scene.delete(a.scene)
		a.scene = nil
	end
end

function M.on_input(a, action_id, action)
	-- the step's scene: a tap skips it
	if a.scene then
		if (action_id == ui.TOUCH or action_id == ui.PAD) and action.pressed then step_scene.skip(a.scene) end
		return nil
	end
	local ui_action = ui.touch(a.buttons, action_id, action)
	if ui_action == "indietro" then return "indietro" end
	if ui_action then run_cmd(a, ui_action) end
	return nil
end

function M.destroy(a)
	if a.scene then step_scene.delete(a.scene) end
	kit.header_delete(a.head)
	for _, k in ipairs(GROUPS) do
		if a[k] then gui.delete_node(a[k].node) end
	end
	kit.scene_drop(a.back)
end

return M
