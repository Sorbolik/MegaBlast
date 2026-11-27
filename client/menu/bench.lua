-- POTENZIA (Sergio, 27 Nov): the window of one piece, opened in the ZAINO by holding
-- its card (the controller: Y). It comes out of the card over a dark veil: on the left
-- the piece as a small card with its +N, its name and grade, its level as thirty beads
-- on a thread (ui/ingots.lua, the signature's slots at 10 20 30), its signature with
-- what it really gives and ACCENDI LA FIRMA; on the right what it does now and at the
-- next level, the Proof, and how to pay: one +1 LIVELLO, in Scaglie or in the fragments
-- of its family (PAGA CON, the choice over it). Beside the X, what you have of both.
-- Buying a level fills its bead with a blow; a step opens the step's scene; lighting the
-- signature makes it flare. The X, the veil or the arrow close it.
--
--   local bench = require "menu.bench"
--   bench.ingots(g, x, y, w, h, level, lit)       -- the beads of the level (ui/ingots.lua)
--   bench.window(s, g, sel)                       -- the window of the piece sel = { set, slot }
--   bench.run(s, kind, sel) -> true               -- "potenzia" / "firma" / "frammenti" (false: not the bench's)
--                                                 -- s.pay: "frammenti" pays in fragments (PAGA CON)
--   bench.after(s)                                -- after the screen is built: the opening, the blow, the scene
--   bench.update(s, dt) / bench.input(s, action_id, action) -> true while the scene runs
--   bench.delete(s)
-- s: the screen (s.prof, s.buttons, s.colore); it keeps s.bench, s.scene;
-- s.just = "open" (and s.window_from, the card's screen position) before bench.after
-- brings the window in

local ui = require "ui.ui"
local kit = require "ui.kit"
local coins = require "ui.coins"
local screen = require "ui.screen"
local equip = require "sim.gear"
local profile = require "menu.profile"
local wallet = require "sim.wallet"
local gear_ui = require "menu.gear_ui"
local step_scene = require "ui.step_scene"
local sign_light = require "ui.sign_light"
local orders = require "sim.orders"
local T = require("lang.text").armory
local TP = require("lang.text").pieces

local M = {}

local KC = kit.C
local ingots = require "ui.ingots"
-- the signature's texts in its own colour, the Ossidiana's violet (Sergio, 18 Nov)
local SIGN_INK = KC.PURPLE
local SIGN_TEXT = vmath.vector4(0.9, 0.84, 1, 1)
local SIGN_OFF = vmath.vector4(0.6, 0.52, 0.72, 1)
local SIGN_NAME_OFF = vmath.vector4(0.72, 0.62, 0.88, 1)
local VEIL = vmath.vector4(0.03, 0.02, 0.04, 0.84)
local FILL = vmath.vector4(0.106, 0.082, 0.125, 1)
-- the window (Figma), its left column and its right one
local WX, WY, WW, WH = 150, 46, 980, 600
local LX, LW = WX + 36, 360
-- the signature's words: under the beads, up to the rows' middle
local SW = 560
local RX, RR = WX + 470, WX + WW - 36
-- the name, grade and level beside the piece: up to well before the rows
local NAME_W = RX - 56 - (LX + 168)

-- a text never wider than max (a long one shrinks)
local function fit(n, max)
	local nw = kit.width(n)
	if nw > max then gui.set_scale(n, gui.get_scale(n) * (max / nw)) end
	return n
end

M.ingots = ingots.draw

-- "+6%": a signature's value written as its description wants it
local function sign_value(stat, grade)
	local sg = equip.SIGNS[stat]
	return math.floor(sg.max * equip.SIGN_TIERS[grade + 1] * 100 + 0.5)
end

-- the signature under the beads: its name, what it gives, ACCENDI LA FIRMA
local function signature(s, g, now, level, lit, set, slot)
	local p = s.prof
	local b = s.bench
	local net = profile.can_spend()
	for _, e in ipairs(now) do
		if e.row == "sign" then
			local sg = equip.SIGNS[e.stat]
			local on = lit > 0
			kit.text(g, kit.upper(on and T.sign or T.sign_off), LX, WY + 404, 16, on and SIGN_INK or SIGN_OFF, "start", 1)
			b.sign = fit(kit.text(g, kit.upper(sg.name), LX, WY + 428, 20, on and SIGN_INK or SIGN_NAME_OFF, "start", 0.5), SW)
			b.lit, b.desc, b.stat = lit, {}, e.stat
			local lines = kit.wrap(g, kit.upper(sg.desc:format(sign_value(e.stat, math.max(1, lit)))), 16, SW)
			local ink = on and SIGN_TEXT or SIGN_OFF
			local nxt_sign = lit < 3 and sg.desc:find("%%d") and lit > 0
			local max_lines = nxt_sign and 2 or 3
			for li = 1, math.min(max_lines, #lines) do
				b.desc[li] = fit(kit.text(g, lines[li], LX, WY + 450 + (li - 1) * 18, 16, ink, "start"), SW)
			end
			if nxt_sign then
				local step = equip.TIER_LEVELS[lit + 1]
				local line = level >= step and T.sign_next_now:format(sign_value(e.stat, lit + 1))
					or T.sign_next:format(step, sign_value(e.stat, lit + 1))
				fit(kit.text(g, kit.upper(line), LX, WY + 450 + math.min(max_lines, #lines) * 18, 16, KC.OBSIDIAN, "start"), SW)
			end
		end
	end
	-- the signature is lit with Ossidiana, a grade for each step done (Sergio, 17 Nov)
	local sn = wallet.sign_next(p, set, slot)
	local can = sn and not sn.level and p.ossidiana >= sn.cost and net
	local note = not sn and T.sign_top or sn.level and T.sign_needs:format(sn.level)
		or not net and TP.need_network or T.sign_cost:format(sn.cost)
	local sb = kit.secondary(g, T.light_sign, LX, WY + WH - 36 - 62, 280, 62,
		{ icon = "gemma", sub = kit.upper(note), sub_color = KC.OBSIDIAN, off = not can })
	kit.button(s.buttons, sb, "firma", { spento = not can })
end

-- a balance on the wallet's small iron plate (ui/coins.lua): its coin sticking out of
-- the left end, the number in its room
local function balance(g, icon, x, y, w, n)
	local pl = kit.plate(g, x, y, w, 44, KC.ROSE, { sk = 0 })
	kit.piece(g, icon, x + 14, y + 22, 38)
	fit(kit.text({ node = pl.g.node, ox = pl.g.ox, oy = pl.g.oy, box = pl.box }, coins.format(n), x + 38, y + 31, 22, KC.SAND), w - 50)
end

-- the X that closes (Sergio, 27 Nov): no slab, the buttons' relief (tools/grafica/fucina.py,
-- croce); the finger on it brings it down onto its shadow
local function close_x(s, g, cx, cy)
	local z = kit.zone(g, s.buttons, cx - 34, cy - 34, 68, 68, "chiudi")
	local n = kit.piece(g, "croce", cx, cy + 3, 53)
	z.on_press = function(down) gui.play_flipbook(n, down and "croce_premuta" or "croce") end
end

function M.window(s, g, sel)
	local p = s.prof
	local set, slot = sel[1], sel[2]
	local level = wallet.level(p, set, slot)
	local tier = equip.tier(level)
	local lit = wallet.sign(p, set, slot)
	local nxt = wallet.next(p, set, slot)
	local net = profile.can_spend()
	-- the veil over the screen (a tap on it closes), then the window (its taps its own)
	local fw, fh = 1280 * screen.FULL, 720 * screen.FULL
	local veil = kit.rect(g, 640 - fw / 2, 360 - fh / 2, fw, fh, VEIL)
	kit.zone(g, s.buttons, 640 - fw / 2, 360 - fh / 2, fw, fh, "chiudi")
	local wg = kit.group(g, WX + WW / 2, WY + WH / 2)
	s.bench = { rows = {}, root = wg.node, veil = veil, card = { g = wg, x = WX, y = WY, w = WW, h = WH } }
	local b = s.bench
	kit.rect(wg, WX + 4, WY + 4, WW - 8, WH - 8, FILL)
	kit.card(wg, WX, WY, WW, WH)
	kit.zone(wg, s.buttons, WX, WY, WW, WH, "finestra")
	kit.text(wg, TP.upgrade_here, LX, WY + 58, 34, KC.HOT, "start", 1)
	-- what you have to pay with, always in sight beside the X (Sergio, 27 Nov): the
	-- Scaglie and the fragments of the piece's family, on the wallet's plates
	local have = p.commesse and orders.fragments(p, set) or 0
	local xr = RR - 4
	local fx = xr - 46 - 18 - 104
	balance(wg, "frammento_" .. set, fx, WY + 26, 104, have)
	balance(wg, "scaglia", fx - 12 - 156, WY + 26, 156, p.scaglie)
	close_x(s, wg, xr - 23, WY + 50)

	-- the piece, its name, grade and level, the beads
	local mini = gear_ui.mini(wg, LX, WY + 82, 150, { set = set, slot = slot, level = level, sel = true })
	b.icon = mini.node
	fit(kit.text(wg, gear_ui.name(set, slot), LX + 168, WY + 136, 26, KC.SAND), NAME_W)
	fit(kit.text(wg, kit.upper(T.grade:format(gear_ui.ROMAN[tier], TP.grades[tier])), LX + 168, WY + 164, 17, ui.C.GRADI[tier], "start", 1), NAME_W)
	b.title = fit(kit.text(wg, nxt and T.level_to:format(level, nxt.level) or T.level_top:format(level), LX + 168, WY + 200, 21, KC.SAND), NAME_W)
	if nxt and nxt.proof > 0 then
		fit(kit.text(wg, kit.upper(TP.proof:format(nxt.proof_done, nxt.proof)), LX + 168, WY + 224, 16,
			nxt.proof_done >= nxt.proof and KC.MINT or KC.STEEL, "start", 0.5), NAME_W)
	end
	b.bar = M.ingots(wg, LX, WY + 336, RR - LX, 34, level, lit)
	b.gems, b.level = b.bar.gems, level
	local now = equip.piece(set, slot, level, lit)
	signature(s, wg, now, level, lit, set, slot)

	-- what it does now, and at the next level: green if better, red if worse
	local after = nxt and equip.piece(set, slot, nxt.level, lit)
	kit.text(wg, kit.upper(nxt and T.at_level:format(nxt.level) or TP.at_max), RX, WY + 106, 20, KC.SAND, "start", 1)
	local y = WY + 150
	for i, e in ipairs(now) do
		if e.row ~= "sign" then
			local v, name = gear_ui.effect_parts(e)
			b.rows[#b.rows + 1] = fit(kit.text(wg, name, RX, y, 20, KC.HOT), 230)
			local to = after and after[i] and after[i].good ~= e.good and after[i]
			kit.text(wg, v, to and RR - 150 or RR, y, 20, e.good >= 0 and KC.SAND or KC.RED, "end")
			if to then
				kit.text(wg, "›", RR - 128, y, 20, KC.MUTE, "middle")
				b.rows[#b.rows + 1] = kit.text(wg, gear_ui.effect_parts(to), RR, y, 22, to.good > e.good and KC.MINT or KC.RED, "end")
			end
			y = y + 36
		end
	end

	-- how to pay (Sergio, 27 Nov, choice C): one +1 LIVELLO, and over it the coin it is
	-- paid with, Scaglie or the family's fragments (the Smith's orders, docs/commesse.md):
	-- two ways of doing the same thing, the signature's button apart on the left
	local by = WY + WH - 36 - 62
	if nxt then
		local frag = s.pay == "frammenti"
		kit.choice(wg, s.buttons, RR - 316, by - 70, T.pay_with,
			{ { T.pay_scaglie, "paga:scaglie" }, { T.pay_fragments, "paga:frammenti" } }, frag and 2 or 1, 158)
		local proof = nxt.proof_done >= nxt.proof
		local ok, why
		if frag then
			local fcost = orders.level_cost(p, set, slot)
			ok = p.commesse and p.commesse.aperta and have >= fcost and proof and net
			why = not proof and TP.proof_first or not (p.commesse and p.commesse.aperta) and T.fragments_closed
				or have < fcost and T.fragments_missing:format(fcost - have) or not net and TP.need_network or nil
			why = why or T.fragments_price:format(fcost)
		else
			ok = proof and p.scaglie >= nxt.cost and net
			why = not proof and TP.proof_first or p.scaglie < nxt.cost
				and TP.missing:format(coins.format(nxt.cost - p.scaglie)) or not net and TP.need_network
				or TP.price_only:format(coins.format(nxt.cost))
		end
		s.action = kit.secondary(wg, TP.upgrade, RR - 290, by, 290, 62, { main = true, size = 30, icon = "az_potenzia",
			sub = kit.upper(why), off = not ok })
		kit.button(s.buttons, s.action, frag and "frammenti" or "potenzia", { main = true, spento = not ok })
	else
		s.action = kit.secondary(wg, TP.upgrade, RR - 290, by, 290, 62, { main = true, size = 30, icon = "az_potenzia", off = true, sub = kit.upper(TP.at_max) })
	end
end

-- +1 LIVELLO and ACCENDI LA FIRMA on the piece sel
function M.run(s, kind, sel)
	local p = s.prof
	if not sel or (kind ~= "potenzia" and kind ~= "firma" and kind ~= "frammenti") then return false end
	if kind == "potenzia" or kind == "frammenti" then
		local before = equip.tier(wallet.level(p, sel[1], sel[2]))
		local level = profile.act(p, { k = "potenzia", set = sel[1], slot = sel[2], frammenti = kind == "frammenti" or nil })
		if level then
			sound.play("#scaglia")
			if equip.tier(level) > before then
				s.step = { slot_name = gear_ui.slot_of(sel[2]).name, set_name = equip.BY_ID[sel[1]].name, level = level,
					lit = wallet.sign(p, sel[1], sel[2]), icon_before = gear_ui.icon(sel[1], sel[2], level - 1),
					icon_after = gear_ui.icon(sel[1], sel[2], level), bg = s.back and s.back.opt.bg }
			else
				s.just = "level"
			end
		end
	else
		local sn = wallet.sign_next(p, sel[1], sel[2])
		if profile.act(p, { k = "firma", set = sel[1], slot = sel[2] }) then
			sound.play("#martello")
			s.just, s.sign_cost = "sign", sn and sn.cost
		end
	end
	return true
end

-- a node goes big and comes back (the blow of the hammer)
local function pop(n, k, t, delay)
	local sc = gui.get_scale(n)
	gui.set_scale(n, sc * k)
	gui.animate(n, "scale", sc, gui.EASING_OUTBACK, t or 0.3, delay or 0)
end

-- n sparks out of a node, in color, d far (the blow of the hammer on the anvil)
local function sparks(node, color, n, d)
	local parent, at = gui.get_parent(node), gui.get_position(node)
	for i = 1, n do
		local a = (i - 0.5) * 2 * math.pi / n + 0.3
		local sp = ui.sagoma("forma", at.x + math.cos(a) * 6, at.y + math.sin(a) * 6, 12, 4, color, parent)
		gui.set_slice9(sp, vmath.vector4(2, 2, 2, 2))
		gui.set_rotation(sp, vmath.vector3(0, 0, math.deg(a)))
		gui.animate(sp, "position", at + vmath.vector3(math.cos(a) * d, math.sin(a) * d, 0), gui.EASING_OUTQUAD, 0.3)
		gui.animate(sp, "color.w", 0, gui.EASING_INQUAD, 0.3, 0, function() gui.delete_node(sp) end)
	end
end

-- after the screen is rebuilt: what just happened shows
function M.after(s)
	local b = s.bench
	if s.just == "level" and b and b.level then
		-- the notch just bought comes down like a blow, white, then the grade's color;
		-- the piece jumps; the numbers that grew flicker
		local bar = b.bar
		local color = ui.C.GRADI[equip.tier(b.level)]
		if bar then
			-- the bead just bought: white hot with a blow, then the grade's color; the
			-- next one lights up in ember (a slot is not a bead: the step's scene has it)
			local n = bar.beads[b.level]
			local f = n
			if n and f then
				gui.set_color(f, KC.SEAM)
				gui.animate(f, "color", color, gui.EASING_OUTQUAD, 0.4, 0.15)
				pop(n, 2.2, 0.35)
				sparks(n, color, 8, 34)
			end
			if bar.next then pop(bar.next, 1.6, 0.3, 0.2) end
		end
		-- the piece takes the blow: squashed, then back
		if b.icon then
			gui.set_scale(b.icon, vmath.vector3(1.12, 0.88, 1))
			gui.animate(b.icon, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTELASTIC, 0.5, 0.12)
		end
		if b.title then pop(b.title, 1.15, 0.3, 0.12) end
		for i, r in ipairs(b.rows) do pop(r, 1.15, 0.25, 0.12 + 0.05 * i) end
	elseif s.just == "open" and b and b.root then
		-- the window comes out of the card the finger held: small where the card was,
		-- it grows over the veil, lands with a blow and sparks; the beads light one by one
		local at = gui.get_position(b.root)
		if s.window_from then
			gui.set_screen_position(b.root, s.window_from)
			gui.set_position(b.root, gui.get_position(b.root))
		end
		gui.set_scale(b.root, vmath.vector3(0.22, 0.22, 1))
		gui.animate(b.root, "position", at, gui.EASING_OUTCUBIC, 0.3)
		gui.animate(b.root, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, 0.36, 0, function()
			if b.icon then
				kit.burst_at(b.icon, 18, KC.HOT)
				pop(b.icon, 1.18, 0.3)
			end
			kit.shake({ b.root }, 6)
		end)
		if b.veil then
			local c = gui.get_color(b.veil)
			gui.set_color(b.veil, vmath.vector4(c.x, c.y, c.z, 0))
			gui.animate(b.veil, "color.w", c.w, gui.EASING_OUTQUAD, 0.25)
		end
		if b.bar then
			for i = 1, b.level or 0 do
				local n = b.bar.beads[i]
				if n then pop(n, 1.8, 0.18, 0.36 + i * 0.025) end
			end
		end
	elseif s.just == "sign" and b and b.bar and b.lit and b.lit > 0 then
		-- the gem flies from the balance into its stud, ice (ui/sign_light.lua)
		if s.light then sign_light.delete(s.light) end
		s.light = sign_light.new({ bar = b.bar, lit = b.lit, wallet = s.wallet, cost = s.sign_cost,
			icon = b.icon, name = b.sign, lines = b.desc, card = b.card,
			from = b.lit > 1 and sign_value(b.stat, b.lit - 1) or 0, to = sign_value(b.stat, b.lit) })
		s.light_bench = b
	end
	s.just = nil
	if s.step then
		s.scene = step_scene.new(s.step)
		s.step = nil
	end
end

function M.update(s, dt)
	if s.light then
		-- the screen made again under it: what was left of it goes
		if s.light_bench ~= s.bench or not sign_light.update(s.light, dt) then
			if s.light_bench == s.bench then sign_light.finish(s.light) end
			sign_light.delete(s.light)
			s.light = nil
		end
	end
	if s.scene and not step_scene.update(s.scene, dt) then
		step_scene.delete(s.scene)
		s.scene = nil
	end
end

-- the step's scene: a tap skips it
function M.input(s, action_id, action)
	if not s.scene then return false end
	if (action_id == ui.TOUCH or action_id == ui.PAD) and action.pressed then step_scene.skip(s.scene) end
	return true
end

function M.delete(s)
	if s.scene then step_scene.delete(s.scene) end
	s.scene = nil
	if s.light then sign_light.delete(s.light) end
	s.light = nil
end

return M
