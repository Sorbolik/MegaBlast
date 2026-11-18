-- The Smith's bench: the card of one piece, the same in the ARMERIA (POTENZIA)
-- and in the ZAINO (a piece opened from the inventory: you upgrade it without
-- leaving, Sergio 18 Nov). On an iron panel the piece, its name and grade, its
-- level as the thirty notches of the step's scene (ui/step_scene.lua: the big
-- ones at 10 20 30 in the color of the grade they open), what it does now and
-- at the next level, its signature with what it really gives, the Proof; under
-- it the other pieces of its slot. In the footer ACCENDI LA FIRMA, the price
-- and +1 LIVELLO. Buying a level fills its notch with a blow; a step opens the
-- step's scene; lighting the signature makes it flare.
--
--   local bench = require "menu.bench"
--   bench.notches(g, x, y, w, level, o)           -- the thirty notches (o.h: the big ones' height)
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
local wallet = require "menu.wallet"
local gear_ui = require "menu.gear_ui"
local step_scene = require "ui.step_scene"
local T = require("lang.text").armory
local TP = require("lang.text").pieces

local M = {}

local KC = kit.C
-- the effects on the left of the panel, the signature on the right
local RIGHT_COL = 312
M.X, M.W = 430, 580

-- a text never wider than max (a long one shrinks)
local function fit(n, max)
	local nw = kit.width(n)
	if nw > max then gui.set_scale(n, gui.get_scale(n) * (max / nw)) end
	return n
end

-- The thirty notches of a piece, w wide from (x, y) (the tops of the big ones):
-- the ones reached in the color of the piece's grade (as the step's scene leaves
-- them), the next one to buy in ember, the big ones still ahead in the color of
-- the grade they open, dimmed, with their level under them. Returns the notches
function M.notches(g, x, y, w, level, o)
	o = o or {}
	local big_h = o.h or 26
	local small_h = math.floor(big_h * 0.7)
	local pitch = w / equip.LIVELLO_MAX
	local nw = math.max(3, math.floor(pitch * 0.62))
	local sk = math.max(2, math.floor(nw * 0.4))
	local tier = equip.tier(level)
	local out = {}
	for i = 1, equip.LIVELLO_MAX do
		local big = i % 10 == 0
		local color
		if i <= level then
			color = ui.C.GRADI[tier]
		elseif i == level + 1 then
			color = KC.HOT
		elseif big then
			color = kit.with_alpha(ui.C.GRADI[equip.tier(i)], 0.45)
		else
			color = KC.LINE
		end
		local h = big and big_h or small_h
		out[i] = kit.para(g, x + (i - 1) * pitch, y + (big_h - h) / 2, nw, h, sk, color)
		if big and o.labels ~= false then
			kit.text(g, tostring(i), x + (i - 1) * pitch + (nw + sk) / 2, y + big_h + 20, 16,
				i <= level and ui.C.GRADI[tier] or KC.MUTE, "middle")
		end
	end
	return out
end

-- The three ingots of a piece (Sergio, 18 Nov, proposal C): the thirty levels as
-- three ingots of ten notches, w wide from (x, y), h tall. The notches reached in
-- the color of the piece's grade, the next one to buy in ember; a full ingot glows
-- with the color of the grade it opened, and at its end the gem of the signature
-- grade that step lets you light (lit: bright; not yet: dark). Returns the thirty
-- notches and the three gems
function M.ingots(g, x, y, w, h, level, lit)
	local gap = h >= 24 and 10 or 5
	local iw = (w - 2 * gap) / 3
	local sk = math.max(2, math.floor(h * 0.16))
	local pad = h >= 24 and 5 or 3
	local gem_h = h - 2 * pad + 4
	local tier = equip.tier(level)
	local notches, gems = {}, {}
	for k = 1, 3 do
		local ix = x + (k - 1) * (iw + gap)
		local full = level >= k * 10
		kit.para(g, ix, y, iw, h, sk, KC.INK)
		kit.para(g, ix + 3, y + 3, iw - 6, h - 6, sk, full and kit.with_alpha(ui.C.GRADI[k + 1], 0.3) or KC.CARD_BOTTOM)
		-- ten notches, then room for the gem
		local room = iw - 2 * pad - gem_h - 2
		local pitch = room / 10
		local nw = math.max(2, pitch * 0.66)
		local nh = h - 2 * pad - 2
		for i = 1, 10 do
			local n = (k - 1) * 10 + i
			local color = n <= level and ui.C.GRADI[tier] or (n == level + 1 and KC.HOT_BOTTOM or KC.LINE)
			notches[n] = kit.para(g, ix + pad + sk / 2 + (i - 1) * pitch, y + pad + 1, nw, nh, math.max(1, math.floor(sk * 0.6)), color)
		end
		local gem = kit.piece(g, "gemma", ix + iw - pad - gem_h / 2, y + h / 2, gem_h)
		if k > (lit or 0) then gui.set_color(gem, vmath.vector4(0.3, 0.3, 0.36, full and 0.85 or 0.6)) end
		gems[k] = gem
	end
	return notches, gems
end

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
	s.bench = { notches = {}, rows = {}, root = g.node }
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
	kit.text(g, gear_ui.name(set, slot), x + 200, 156, 32, KC.SAND)
	kit.text(g, kit.upper(T.grade:format(gear_ui.ROMAN[tier], TP.grades[tier])), x + 202, 187, 20, ui.C.GRADI[tier], "start", 1)
	local nxt = wallet.next(p, set, slot)
	s.bench.title = kit.text(g, nxt and T.level_to:format(level, nxt.level) or T.level_top:format(level), x + 202, 222, 23, KC.SAND)
	-- the level: three ingots of ten notches, the signature's gems at their ends
	local lit = wallet.sign(p, set, slot)
	s.bench.notches, s.bench.gems = M.ingots(g, x + 200, 238, 352, 32, level, lit)
	s.bench.level = level

	-- what it does now, and at the next level
	local now = equip.piece(set, slot, level, lit)
	local after = nxt and equip.piece(set, slot, nxt.level, lit)
	local y = 308
	for i, e in ipairs(now) do
		if e.row ~= "sign" then
			local col = e.good >= 0 and KC.MINT or KC.RED
			local n = fit(kit.text(g, gear_ui.effect(e), x + 28, y + 17, 21, col), 200)
			s.bench.rows[#s.bench.rows + 1] = n
			if after and after[i] and after[i].good ~= e.good then
				kit.text(g, "› " .. gear_ui.effect(after[i]):match("^(%S+)"), x + RIGHT_COL - 8, y + 17, 18, KC.HOT, "end")
			end
			y = y + 30
		end
	end

	-- the signature: its name, its three grades as gems, and what it gives (at
	-- the grade lit; off: what it will give once lit)
	local rw = w - 28 - RIGHT_COL
	local rx = x + RIGHT_COL
	for _, e in ipairs(now) do
		if e.row == "sign" then
			local sg = equip.SIGNS[e.stat]
			local on = lit > 0
			-- FIRMA (or FIRMA SPENTA), its name, what it gives now, and what it
			-- gives at the next step (its gems sit at the ends of the ingots)
			kit.text(g, kit.upper(on and T.sign or T.sign_off), rx, 322, 16, on and KC.HOT_TOP or KC.MUTE, "start", 1)
			local title = fit(kit.text(g, kit.upper(sg.name), rx, 346, 20, on and KC.HOT_TOP or KC.SAND, "start", 0.5), rw)
			s.bench.sign, s.bench.lit, s.bench.desc = title, lit, {}
			local value = sign_value(e.stat, math.max(1, lit))
			local lines = kit.wrap(g, kit.upper(sg.desc:format(value)), 16, rw)
			local ink = on and KC.SAND or KC.MUTE
			local nxt_sign = lit < 3 and sg.desc:find("%%d") and (lit > 0)
			local max_lines = nxt_sign and 3 or 4
			for li = 1, math.min(max_lines, #lines) do
				s.bench.desc[li] = fit(kit.text(g, lines[li], rx, 369 + (li - 1) * 19, 16, ink, "start"), rw)
			end
			if nxt_sign then
				local ly = 369 + math.min(max_lines, #lines) * 19
				local step = equip.TIER_LEVELS[lit + 1]
				local line = level >= step and T.sign_next_now:format(sign_value(e.stat, lit + 1))
					or T.sign_next:format(step, sign_value(e.stat, lit + 1))
				fit(kit.text(g, kit.upper(line), rx, ly, 16, KC.HOT, "start"), rw)
			end
		end
	end
	-- the Proof, beside the level
	if nxt and nxt.proof > 0 then
		fit(kit.text(g, kit.upper(TP.proof:format(nxt.proof_done, nxt.proof)), x + w - 28, 222, 16,
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
	local sb = kit.secondary(low2, T.light_sign, 430, 640, 270, 62, { icon = "gemma", sub = kit.upper(note), off = not can })
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
				s.step = { gear_ui.slot_of(sel[2]).name, equip.BY_ID[sel[1]].name, level }
			else
				s.just = "level"
			end
		end
	elseif wallet.light(p, sel[1], sel[2]) then
		sound.play("#martello")
		s.just = "sign"
	end
	return true
end

-- a node goes big and comes back (the blow of the hammer)
local function pop(n, k, t, delay)
	local sc = gui.get_scale(n)
	gui.set_scale(n, sc * k)
	gui.animate(n, "scale", sc, gui.EASING_OUTBACK, t or 0.3, delay or 0)
end

-- a short white flash on a notch, then its color
local function flash(parts, color, delay)
	kit.tint(parts, vmath.vector4(1, 1, 1, 1))
	for _, n in ipairs(parts) do
		gui.animate(n, "color", color, gui.EASING_OUTQUAD, 0.35, delay or 0)
	end
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
		local n = b.notches[b.level]
		local color = ui.C.GRADI[equip.tier(b.level)]
		if n then
			-- it falls from above, white hot, and cools to the grade's color
			local at = gui.get_position(n.node)
			gui.set_position(n.node, at + vmath.vector3(0, 40, 0))
			gui.animate(n.node, "position", at, gui.EASING_INQUAD, 0.12, 0, function()
				sparks(n.node, color, 8, 34)
				pop(n.node, 1.7, 0.3)
			end)
			flash(n.parts, color, 0.12)
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
	elseif s.just == "sign" and b and b.gems then
		-- the gem just lit bursts, the others answer; the signature's words light up
		for k, gem in ipairs(b.gems) do
			if k == b.lit then
				sparks(gem, KC.ICE, 10, 40)
				pop(gem, 2.4, 0.45)
			else
				pop(gem, 1.3, 0.3, 0.1)
			end
		end
		if b.sign then pop(b.sign, 1.25, 0.35) end
		for i, l in ipairs(b.desc or {}) do
			gui.set_color(l, vmath.vector4(1, 1, 1, 1))
			gui.animate(l, "color", KC.SAND, gui.EASING_OUTQUAD, 0.5, 0.05 * i)
		end
	end
	s.just = nil
	if s.step then
		s.scene = step_scene.new(s.step[1], s.step[2], s.step[3], function()
			sound.play("#martello", { speed = 0.9 + 0.1 * math.random() })
		end, s.colore)
		s.step = nil
	end
end

function M.update(s, dt)
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
end

return M
