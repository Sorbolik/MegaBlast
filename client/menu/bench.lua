-- The Smith's bench: the card of one piece, the same in the ARMERIA (POTENZIA)
-- and in the ZAINO (a piece opened from the inventory: you upgrade it without
-- leaving, Sergio 18 Nov). On an iron panel the piece, its name and grade, its
-- level as thirty beads on a thread (ui/ingots.lua, the signature's slots at
-- 10 20 30), what it does now and
-- at the next level, its signature with what it really gives, the Proof; under
-- it the other pieces of its slot. In the footer ACCENDI LA FIRMA, the price
-- and +1 LIVELLO. Buying a level fills its bead with a blow; a step opens the
-- step's scene; lighting the signature makes it flare.
--
--   local bench = require "menu.bench"
--   bench.ingots(g, x, y, w, h, level, lit)       -- the beads of the level (ui/ingots.lua)
--   bench.draw(s, g, sel)                         -- the panel and the slot's other pieces
--   bench.footer(s, low2, right, sel)             -- the signature's plate, the price, +1 LIVELLO
--   bench.run(s, kind, sel) -> true               -- "potenzia" / "firma" (false: not the bench's)
--   bench.after(s)                                -- after the screen is built: the blow, the scene
--   bench.update(s, dt) / bench.input(s, action_id, action) -> true while the scene runs
--   bench.delete(s)
-- s: the screen (s.prof, s.buttons, s.colore); it keeps s.bench, s.scene;
-- s.just = "open" before bench.after brings the card in

local ui = require "ui.ui"
local kit = require "ui.kit"
local coins = require "ui.coins"
local equip = require "sim.gear"
local profile = require "menu.profile"
local wallet = require "sim.wallet"
local gear_ui = require "menu.gear_ui"
local step_scene = require "ui.step_scene"
local sign_light = require "ui.sign_light"
local T = require("lang.text").armory
local TP = require("lang.text").pieces

local M = {}

local KC = kit.C
local ingots = require "ui.ingots"
-- the effects on the left of the panel, the signature on the right
local RIGHT_COL = 316
-- the signature's texts in its own colour, the Ossidiana's violet (Sergio, 18 Nov)
local SIGN_INK = KC.PURPLE
local SIGN_TEXT = vmath.vector4(0.9, 0.84, 1, 1)
local SIGN_OFF = vmath.vector4(0.6, 0.52, 0.72, 1)
local SIGN_NAME_OFF = vmath.vector4(0.72, 0.62, 0.88, 1)
M.X, M.W = 430, 580

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

function M.draw(s, g, sel)
	local p = s.prof
	local x, w = M.X, M.W
	-- everything on one group, to bring it in as a whole
	g = kit.group(g, x + w / 2, 340)
	s.bench = { rows = {}, root = g.node, card = { g = g, x = x, y = 100, w = w, h = 344 } }
	kit.panel(kit.group(g, x + w / 2, 272).node, w, 344)
	if not sel then
		kit.text(g, kit.upper(T.nothing_here), x + w / 2, 260, 18, KC.MUTE, "middle", 1)
		return
	end
	local set, slot = sel[1], sel[2]
	local level = wallet.level(p, set, slot)
	local tier = equip.tier(level)
	local ig = kit.group(g, x + 28 + 75, 128 + 75)
	gear_ui.slot(ig, x + 28, 128, 150, { set = set, slot = slot })
	s.bench.icon = ig.node
	kit.text(g, gear_ui.name(set, slot), x + 200, 170, 32, KC.SAND)
	kit.text(g, kit.upper(T.grade:format(gear_ui.ROMAN[tier], TP.grades[tier])), x + 202, 203, 20, ui.C.GRADI[tier], "start", 1)
	local nxt = wallet.next(p, set, slot)
	s.bench.title = kit.text(g, nxt and T.level_to:format(level, nxt.level) or T.level_top:format(level), x + 202, 242, 23, KC.SAND)
	-- the level: thirty beads on a thread under the piece, the whole width of the
	-- card, the signature's slots at 10, 20 and 30
	local lit = wallet.sign(p, set, slot)
	s.bench.bar = M.ingots(g, x + 28, 290, w - 56, 30, level, lit)
	s.bench.gems = s.bench.bar.gems
	s.bench.level = level

	-- what it does now, and at the next level
	local now = equip.piece(set, slot, level, lit)
	local after = nxt and equip.piece(set, slot, nxt.level, lit)
	local y = 330
	-- each row: the stat's name in yellow, its value, and on the right only how
	-- much the next level changes it, green if better, red if worse (Sergio, 18 Nov)
	for i, e in ipairs(now) do
		if e.row ~= "sign" then
			local v, name = gear_ui.effect_parts(e)
			local n = fit(kit.text(g, name, x + 28, y + 17, 19, KC.HOT), 126)
			s.bench.rows[#s.bench.rows + 1] = n
			kit.text(g, v, x + 222, y + 17, 19, e.good >= 0 and KC.SAND or KC.RED, "end")
			if after and after[i] and after[i].good ~= e.good then
				local d = gear_ui.effect_parts(e, after[i])
				kit.text(g, d, x + RIGHT_COL - 24, y + 17, 19, after[i].good > e.good and KC.MINT or KC.RED, "end")
			end
			y = y + 28
		end
	end

	-- the signature: its name, its three grades as gems, and what it gives (at
	-- the grade lit; off: what it will give once lit)
	local rw = w - 40 - RIGHT_COL
	local rx = x + RIGHT_COL
	for _, e in ipairs(now) do
		if e.row == "sign" then
			local sg = equip.SIGNS[e.stat]
			local on = lit > 0
			-- FIRMA (or FIRMA SPENTA), its name, what it gives now, and what it
			-- gives at the next step (its studs sit on the bar)
			kit.text(g, kit.upper(on and T.sign or T.sign_off), rx, 340, 16, on and SIGN_INK or SIGN_OFF, "start", 1)
			local title = fit(kit.text(g, kit.upper(sg.name), rx, 362, 20, on and SIGN_INK or SIGN_NAME_OFF, "start", 0.5), rw)
			s.bench.sign, s.bench.lit, s.bench.desc = title, lit, {}
			s.bench.stat = e.stat
			local value = sign_value(e.stat, math.max(1, lit))
			local lines = kit.wrap(g, kit.upper(sg.desc:format(value)), 16, rw)
			local ink = on and SIGN_TEXT or SIGN_OFF
			local nxt_sign = lit < 3 and sg.desc:find("%%d") and (lit > 0)
			local max_lines = nxt_sign and 3 or 4
			for li = 1, math.min(max_lines, #lines) do
				s.bench.desc[li] = fit(kit.text(g, lines[li], rx, 382 + (li - 1) * 17, 16, ink, "start"), rw)
			end
			if nxt_sign then
				local ly = 382 + math.min(max_lines, #lines) * 17
				local step = equip.TIER_LEVELS[lit + 1]
				local line = level >= step and T.sign_next_now:format(sign_value(e.stat, lit + 1))
					or T.sign_next:format(step, sign_value(e.stat, lit + 1))
				fit(kit.text(g, kit.upper(line), rx, ly, 16, KC.OBSIDIAN, "start"), rw)
			end
		end
	end
	-- the Proof, beside the level
	if nxt and nxt.proof > 0 then
		fit(kit.text(g, kit.upper(TP.proof:format(nxt.proof_done, nxt.proof)), x + w - 28, 242, 16,
			nxt.proof_done >= nxt.proof and KC.MINT or KC.STEEL, "end", 0.5), 200)
	end

	-- the other pieces of that slot you have
	kit.text(g, T.others:format(T.plural[slot]), x, 474, 20, KC.SAND, "start", 1)
	local n = 0
	for _, f in ipairs(equip.SETS) do
		if wallet.owns(p, f.id, slot) and n < 6 then
			local cx = x + n * 100
			gear_ui.slot(g, cx, 494, 86, { set = f.id, slot = slot, level = wallet.level(p, f.id, slot),
				worn = profile.active_loadout(p).gear[slot] == f.id, sel = f.id == set })
			kit.zone(g, s.buttons, cx - 6, 484, 98, 104, "pezzo:" .. f.id .. ":" .. slot)
			n = n + 1
		end
	end
end

function M.footer(s, low2, right, sel)
	local p = s.prof
	if not sel then return end
	local set, slot = sel[1], sel[2]
	-- the signature is lit with Ossidiana, a grade for each step done (Sergio, 17 Nov)
	local sn = wallet.sign_next(p, set, slot)
	local can = sn and not sn.level and p.ossidiana >= sn.cost
	local note = not sn and T.sign_top or sn.level and T.sign_needs:format(sn.level)
		or T.sign_cost:format(sn.cost)
	local sb = kit.secondary(low2, T.light_sign, 430, 640, 270, 62, { icon = "gemma", sub = kit.upper(note), sub_color = KC.OBSIDIAN, off = not can })
	kit.button(s.buttons, sb, "firma", { spento = not can })

	-- the price and +1 LIVELLO: the price stuck to the button, on its left, with
	-- what it buys under it (Sergio, 18 Nov: alone in the middle it said nothing);
	-- why it can't be done, in place of that line
	local nxt = wallet.next(p, set, slot)
	if nxt then
		local ok = nxt.proof_done >= nxt.proof and p.scaglie >= nxt.cost
		local px = 910
		local num = kit.text(right, coins.format(nxt.cost), px, 668, 28, nxt.cost < (nxt.full_cost or nxt.cost) and KC.MINT or KC.SAND, "end")
		kit.piece(right, "scaglia", px - kit.width(num) - 22, 658, 34)
		local why = nxt.proof_done < nxt.proof and TP.proof_first or p.scaglie < nxt.cost
			and TP.missing:format(coins.format(nxt.cost - p.scaglie)) or nil
		kit.text(right, kit.upper(why or TP.price_for:format(nxt.level)), px, 692, 16, why and KC.RED or KC.MUTE, "end", 0.5)
		s.action = kit.action(right, TP.upgrade, 948, 628, 308, 80, { size = 44, off = not ok })
		kit.button(s.buttons, s.action, "potenzia", { main = true, spento = not ok })
	else
		s.action = kit.action(right, TP.upgrade, 948, 628, 308, 80, { size = 44, off = true, sub = kit.upper(TP.at_max) })
	end
end

-- +1 LIVELLO and ACCENDI LA FIRMA on the piece sel
function M.run(s, kind, sel)
	local p = s.prof
	if not sel or (kind ~= "potenzia" and kind ~= "firma") then return false end
	if kind == "potenzia" then
		local before = equip.tier(wallet.level(p, sel[1], sel[2]))
		local level = wallet.upgrade(p, sel[1], sel[2])
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
		if wallet.light(p, sel[1], sel[2]) then
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
		-- the card comes in from the right, over where the pieces were
		local at = gui.get_position(b.root)
		gui.set_position(b.root, at + vmath.vector3(70, 0, 0))
		gui.set_scale(b.root, vmath.vector3(0.94, 0.94, 1))
		gui.animate(b.root, "position", at, gui.EASING_OUTCUBIC, 0.22)
		gui.animate(b.root, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, 0.26)
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
		-- the three blows: the hammer, higher each time
		s.step.on_blow = function(i)
			sound.play("#martello", { speed = 0.85 + 0.12 * i })
		end
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
