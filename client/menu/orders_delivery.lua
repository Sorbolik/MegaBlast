-- The delivery of the Smith's orders (docs/commesse.md, "Consegna"): draft A,
-- at the Smith's counter, chosen by Sergio on 23 Nov («va bene A»). The prize is
-- already paid (profile.act) when it starts: the scene only shows it, and a tap
-- skips to the receipt.
--
--   0.00  the ticket leaves its nail and flies onto the counter; the Ossidiana
--         leaves the wallet and drops on the anvil
--   0.85, 1.18, 1.52  three blows (with CONSEGNA TUTTE one per ticket, quicker,
--         then a last one); the lucky strike makes the last one harder
--   +0.23 the client comes in from the right, happy (proud: the lucky strike, the
--         5th and every 10th pearl), says its line; the prize jumps off the anvil
--   +0.9  the paper receipt: what came, the pearls, OK and, when the fragments pay
--         a level of a piece of the family, POTENZIA (the ZAINO)
--
-- The blows are Gabriella's (docs/commesse.md): until her animation comes, the
-- Smith at the counter of WB-085 jolts at each one.
--
-- The scene is data (a.scene) that survives the screen being made again:
--   delivery.start(a, done)   -- done: { { order =, rows =, from = {x, y} }, ... }
--   delivery.draw(a, h)       -- from the board, over everything (h: orders_ui's helpers)
--   delivery.update(a, dt)    -- true when the screen must be made again (the receipt)
--   delivery.cmd(a, x)        -- "salta", "ok", "potenzia"

local kit = require "ui.kit"
local ui = require "ui.ui"
local coins = require "ui.coins"
local screen = require "ui.screen"
local orders = require "sim.orders"
local equip = require "sim.gear"
local T = require("lang.text").orders
local TP = require("lang.text").pieces

local M = {}

local KC = kit.C
local INK_MUTE = vmath.vector4(0.36, 0.3, 0.26, 1)
local PAPER_HEAD = vmath.vector4(0.66, 0.28, 0.05, 1)
local DARK = vmath.vector4(0.03, 0.02, 0.035, 0.5)

-- where things are (Figma, 1280 x 720): the Smith as the board draws him, his anvil,
-- the client's bust, its words, the receipt
local SMITH_X, SMITH_Y, SMITH_H = 215, 350, 500
local ANVIL_X, ANVIL_Y = 262, 428
local BUST_X, BUST_Y, BUST_W, BUST_H = 1036, 110, 180, 239
local SAY_X, SAY_Y, SAY_W, SAY_H = 520, 150, 480, 132
local REC_X, REC_Y, REC_W, REC_H = 500, 96, 500, 480

-- the beats of one delivery, and of several (one blow each, then a last one)
local ONE = { 0.85, 1.18, 1.52 }
local EACH, FIRST_BLOW = 0.5, 0.42
local FLY = 0.38
local REVEAL_AFTER, RECEIPT_AFTER = 0.23, 0.9

local function vec(x, y) return vmath.vector3(x, y, 0) end
local function clamp(x) return math.max(0, math.min(1, x)) end
local function seg(t, a, b) return clamp((t - a) / (b - a)) end
local function lerp(a, b, k) return a + (b - a) * k end
local function eo(k) return 1 - (1 - k) ^ 3 end
local function ob(k) local c = 1.7; k = k - 1; return 1 + (c + 1) * k ^ 3 + c * k * k end

-- the receipt's rows, added up over every ticket, in the order they are read
local ORDER = { scaglie = 1, fragments = 2, lucky = 3, gift = 4, trust = 5, voucher = 6, ossidiana = 7 }

local function sum_rows(done)
	local out, at = {}, {}
	for _, d in ipairs(done) do
		for _, r in ipairs(d.rows) do
			local k = r.key .. ":" .. (r.set or "") .. ":" .. (r.cliente or "")
			if at[k] then
				at[k].n = at[k].n + r.n
				at[k].total = r.total or at[k].total
			else
				at[k] = { key = r.key, set = r.set, cliente = r.cliente, n = r.n or 1, total = r.total }
				out[#out + 1] = at[k]
			end
		end
	end
	table.sort(out, function(a, b)
		if ORDER[a.key] ~= ORDER[b.key] then return ORDER[a.key] < ORDER[b.key] end
		return (a.set or "") .. (a.cliente or "") < (b.set or "") .. (b.cliente or "")
	end)
	return out
end

-- Starts the scene over the board: done holds what was just delivered
function M.start(a, done)
	if #done == 0 then return end
	local p = a.prof
	local s = { t = 0, done = done, rows = sum_rows(done), fired = {}, blows = {} }
	-- the blows: three for one ticket, one each and a last one for more
	if #done == 1 then
		s.blows = { ONE[1], ONE[2], ONE[3] }
	else
		for i = 1, #done do s.blows[i] = FIRST_BLOW + (i - 1) * EACH end
		s.blows[#done + 1] = s.blows[#done] + 0.36
	end
	s.reveal = s.blows[#s.blows] + REVEAL_AFTER
	s.receipt = s.reveal + RECEIPT_AFTER
	-- who comes to thank: the last client served (the Smith's own: nobody, he speaks)
	local cost, scaglie, proud = 0, 0, false
	for _, d in ipairs(done) do
		if d.order.cliente then s.client = d.order.cliente end
		for _, r in ipairs(d.rows) do
			if r.key == "ossidiana" then cost = cost - r.n end
			if r.key == "scaglie" then scaglie = scaglie + r.n end
			if r.key == "lucky" then s.lucky = true end
			if r.key == "gift" then proud = true end
			if r.key == "trust" and r.total - r.n < orders.TRUST_BONUS and r.total >= orders.TRUST_BONUS then proud = true end
		end
	end
	s.face = (s.lucky or proud) and "fiero" or "contento"
	s.cost, s.scaglie = cost, scaglie
	-- the family whose fragments came: POTENZIA when they pay a level of one of its pieces
	for _, r in ipairs(s.rows) do
		if r.key == "fragments" and not s.upgrade and orders.upgradable(p, r.set) then s.upgrade = r.set end
	end
	a.scene = s
	a.modal = nil
end

-- the moments that happen once (sounds, sparks, flights), when t passes them;
-- quiet: skipped to the receipt, nothing is heard or thrown
local function events(a, s, quiet)
	local n = s.n
	local function once(id, at)
		if s.t >= at and not s.fired[id] then s.fired[id] = true; return true end
	end
	for i in ipairs(s.done) do
		if once("gems" .. i, (#s.done == 1 and 0.12 or (i - 1) * EACH + 0.1)) and n and not quiet then
			local d = s.done[i]
			local c = 0
			for _, r in ipairs(d.rows) do if r.key == "ossidiana" then c = -r.n end end
			if c > 0 then
				sound.play("#scaglia", { speed = 0.8 })
				M.gems(n, c)
			end
		end
	end
	for i, at in ipairs(s.blows) do
		if once("blow" .. i, at) and n and not quiet then
			local last = i == #s.blows
			local hard = last and s.lucky
			sound.play("#martello", { speed = last and 0.85 or 1 + 0.08 * (i - 1) })
			if hard then sound.play("#scatto_boom") end
			M.sparks(n, n.ax, n.ay - 6, hard and 34 or (last and 18 or 12), hard and 330 or 200)
		end
	end
	if once("reveal", s.reveal) and n and not quiet then
		sound.play("#scaglia")
		-- the Scaglie into the wallet, from the anvil
		if s.scaglie > 0 and n.wallet then
			local from = screen.node_pos(n.anvil) - screen.node_pos(n.wallet_parent)
			coins.fly(n.wallet, "scaglia", vec(from.x, from.y), math.min(8, 3 + math.floor(s.scaglie / 60)), s.scaglie)
		end
	end
end

-- Gems leave the wallet and drop on the anvil
function M.gems(n, cost)
	if not n.wallet then return end
	coins.set(n.wallet, n.wallet.real.scaglie, n.wallet.real.ossidiana - cost)
	local parent = n.wallet_parent
	local to = screen.node_pos(n.anvil) - screen.node_pos(parent)
	local from = gui.get_position(n.wallet.root) + n.wallet.at.ossidiana
	for i = 1, math.min(6, math.max(1, math.ceil(cost / 10))) do
		local g = coins.icon("ossidiana", from.x, from.y, 34, parent)
		local delay = (i - 1) * 0.05
		gui.animate(g, "position.x", to.x + (i - 3) * 6, gui.EASING_OUTQUAD, 0.42, delay)
		gui.animate(g, "position.y", to.y + 6, gui.EASING_INQUAD, 0.42, delay, function() gui.delete_node(g) end)
	end
end

-- sparks from the anvil, up and out (as the step's scene, ui/step_scene.lua)
function M.sparks(n, x, y, count, speed)
	local g = n.g
	local cx, cy = x - g.ox, g.oy - y
	for i = 1, count do
		local ang = math.pi * (0.08 + 0.84 * math.random())
		local d = speed * (0.5 + 0.7 * math.random())
		local sp = ui.sagoma("forma", cx, cy, 16 + 10 * math.random(), 5, i % 3 == 0 and KC.SEAM or KC.HOT, g.node)
		gui.set_slice9(sp, vmath.vector4(2, 2, 2, 2))
		gui.set_rotation(sp, vmath.vector3(0, 0, math.deg(ang)))
		gui.animate(sp, "position", vec(cx + math.cos(ang) * d, cy + math.sin(ang) * d), gui.EASING_OUTQUAD, 0.42)
		gui.animate(sp, "color.w", 0, gui.EASING_INQUAD, 0.42, 0, function() gui.delete_node(sp) end)
	end
end

-- how hard it shakes at t, from the blows that decay
local function trauma(s, t)
	local k = 0
	for i, at in ipairs(s.blows) do
		if t >= at then
			local last = i == #s.blows
			k = k + (last and (s.lucky and 0.9 or 0.45) or 0.28) * math.exp(-(t - at) / 0.13)
		end
	end
	return clamp(k)
end

-- the Smith's jolt at t (until Gabriella's blows): up before a blow, down at it
local function jolt(s, t)
	local up, down = 0, 0
	for _, at in ipairs(s.blows) do
		up = up + (t < at and t > at - 0.16 and eo(seg(t, at - 0.16, at)) or 0)
		if t >= at then down = down + math.exp(-(t - at) / 0.09) end
	end
	return clamp(up), clamp(down)
end

-- Where everything is at t: the screen may be made again any moment, so all of it
-- comes from t
local function pose(a, s)
	local n, t = s.n, s.t
	if not n then return end
	local tr = trauma(s, t)
	local sh = tr * tr
	local ox, oy = 18 * sh * math.sin(t * 61), 12 * sh * math.sin(t * 77 + 1)
	gui.set_position(n.shake, vec(ox, oy))
	-- the Smith
	local up, down = jolt(s, t)
	local sx, sy = 1 + 0.015 * up + 0.03 * down, 1 + 0.02 * up - 0.045 * down
	gui.set_scale(n.smith, vmath.vector3(sx, sy, 1))
	gui.set_position(n.smith, n.smith_at + vec(0, -SMITH_H / 2 * (1 - sy) - 4 * down))
	-- the glow of the anvil at the blows
	local hot = 0
	for i, at in ipairs(s.blows) do
		if t >= at then hot = hot + (i == #s.blows and 1 or 0.6) * math.exp(-(t - at) / 0.16) end
	end
	gui.set_color(n.glow, kit.with_alpha(KC.HOT_BOTTOM, clamp(hot) * 0.85))
	-- the tickets: from their nail onto the counter, then flat under the hammer
	for i, c in ipairs(n.cards) do
		local t0 = #s.done == 1 and 0 or (i - 1) * EACH
		local k = eo(seg(t, t0, t0 + FLY))
		local first = s.blows[math.min(i, #s.blows)]
		local x, y = lerp(c.from.x, n.ax + 4, k), lerp(c.from.y, n.ay - 30, k) - 120 * math.sin(math.pi * k)
		gui.set_position(c.node, vec(x - n.g.ox, n.g.oy - y))
		local sc = lerp(1, 0.34, k)
		gui.set_scale(c.node, vmath.vector3(sc, sc, 1))
		gui.set_rotation(c.node, vmath.vector3(0, 0, lerp(0, -10, k) + 25 * math.sin(math.pi * k)))
		gui.set_enabled(c.node, t >= t0 and t < first + 0.05)
	end
	-- the client: from the right, with a bounce; its words beside it
	local r = s.reveal
	local bk = ob(seg(t, r, r + 0.4))
	gui.set_enabled(n.bust, t >= r)
	gui.set_position(n.bust, vec(lerp(1500, BUST_X + BUST_W / 2, bk) - n.g.ox, n.g.oy - (BUST_Y + BUST_H / 2)))
	local said = t >= r + 0.15 and t < s.receipt + 0.15
	gui.set_enabled(n.say.node, said)
	if said then
		local k = eo(seg(t, r + 0.15, r + 0.35))
		gui.set_scale(n.say.node, vmath.vector3(lerp(0.7, 1, k), lerp(0.7, 1, k), 1))
	end
	-- the prize off the anvil: it jumps, hangs, then goes into the receipt
	for i, f in ipairs(n.prize) do
		local k = seg(t, r + (i - 1) * 0.05, r + 0.45 + (i - 1) * 0.05)
		local fly = seg(t, s.receipt - 0.1, s.receipt + 0.2)
		gui.set_enabled(f.node, t >= r and fly < 1)
		local x = lerp(n.ax, f.x, eo(k))
		local y = n.ay - 20 - 150 * math.sin(math.pi * 0.5 * eo(k)) + 6 * math.sin((t - r) * 5 + i)
		x, y = lerp(x, REC_X + 60, eo(fly)), lerp(y, REC_Y + 160, eo(fly))
		gui.set_position(f.node, vec(x - n.g.ox, n.g.oy - y))
		local sc = lerp(0.2, 1, ob(seg(t, r, r + 0.3))) * (1 - fly)
		gui.set_scale(f.node, vmath.vector3(sc, sc, 1))
	end
	-- the receipt rises; OK comes up from under the band
	if n.receipt then
		local k = eo(seg(t, s.receipt, s.receipt + 0.35))
		gui.set_position(n.receipt, vec(0, -(1 - k) * 700))
		gui.set_enabled(n.receipt, t >= s.receipt)
	end
end

-- the words of whoever thanks: the client, or the Smith himself for his own order
local function words(s)
	if not s.client then return T.smith_done end
	return (s.face == "fiero" and T.proud or T.thanks)[s.client]
end

-- a receipt row: its icon, the words, the number at the right
local function row_of(s, r)
	local fam = r.set and equip.BY_ID[r.set] and (equip.BY_ID[r.set].name:sub(1, 1) .. equip.BY_ID[r.set].name:sub(2):lower())
	if r.key == "scaglie" then return "scaglia", T.r_scaglie, "+" .. coins.format(r.n) end
	if r.key == "fragments" then return "frammento_" .. r.set, T.r_fragments:format(fam), "+" .. r.n end
	if r.key == "lucky" then return "frammento_" .. r.set, T.r_lucky:format(fam), "+" .. r.n end
	if r.key == "gift" then return "frammento_" .. r.set, T.r_gift:format(T.clients[r.cliente], fam), "+" .. r.n end
	if r.key == "trust" then return "perla_piena", T.r_trust:format(T.clients[r.cliente]), "+" .. r.n end
	if r.key == "voucher" then return "buono", T.r_voucher, "+1" end
	if r.key == "ossidiana" then return "gemma", T.r_obsidian, tostring(r.n) end
end

-- The scene over the board (a.over is already made: the veil, the zone of its taps)
function M.draw(a, h)
	local s = a.scene
	local p = a.prof
	local n = { cards = {}, prize = {} }
	s.n = n
	-- everything under it darker than under a window; the scene's own wallet at the top right
	local huge = 1280 * screen.FULL
	kit.rect(a.over, 640 - huge / 2, 360 - huge / 2, huge, huge, DARK)
	-- a tap: straight to the receipt; on it only its own buttons
	kit.zone(a.over, a.buttons, 640 - huge / 2, 360 - huge / 2, huge, huge, s.t < s.receipt and "scena:salta" or "niente")
	n.shake = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_parent(n.shake, a.over.node)
	n.g = { node = n.shake, ox = a.over.ox, oy = a.over.oy }
	local g = n.g
	-- the Smith where the board has him (his group may sit left on a wide screen)
	local at = a.smith_node and screen.node_pos(a.smith_node)
	local sx, sy = SMITH_X, SMITH_Y
	if at then sx, sy = at.x, 720 - at.y end
	n.smith = kit.piece(g, "fabbro_al_banco", sx, sy, SMITH_H)
	n.smith_at = gui.get_position(n.smith)
	local ax, ay = ANVIL_X + (sx - SMITH_X), ANVIL_Y + (sy - SMITH_Y)
	n.ax, n.ay = ax, ay
	n.anvil = gui.new_box_node(vec(ax - g.ox, g.oy - ay), vec(0, 0))
	gui.set_parent(n.anvil, n.shake)
	n.glow = ui.sagoma("alone", ax - g.ox, g.oy - ay + 10, 220, 150, kit.with_alpha(KC.HOT_BOTTOM, 0), n.shake)
	gui.set_blend_mode(n.glow, gui.BLEND_ADD)
	-- the tickets in flight: the paper and the client's name
	for i, d in ipairs(s.done) do
		local grp = kit.group(g, d.from[1], d.from[2])
		kit.paper(grp.node, 180, 236)
		local who = d.order.cliente and kit.upper(T.clients[d.order.cliente]) or T.receipt_smith
		kit.text(grp, who, d.from[1], d.from[2] + 6, 22, KC.INK, "middle", 0.5)
		n.cards[i] = { node = grp.node, from = { x = d.from[1], y = d.from[2] } }
	end
	-- the client and its words (the Smith's own order: only the words)
	n.bust = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_parent(n.bust, n.shake)
	if s.client then
		local bg = { node = n.bust, ox = BUST_X + BUST_W / 2, oy = BUST_Y + BUST_H / 2 }
		kit.rect(bg, BUST_X - 4, BUST_Y - 4, BUST_W + 8, BUST_H + 8, KC.INK)
		h.bust_node(a, n.bust, s.client, s.face, 0, 0, BUST_W, BUST_H)
	end
	n.say = h.panel(g, SAY_X, SAY_Y, SAY_W, SAY_H, "carta")
	local sy0 = SAY_Y + 46
	if s.lucky then
		kit.heading(n.say, T.lucky_title, SAY_X + 24, SAY_Y + 40, PAPER_HEAD)
		sy0 = sy0 + 24
	end
	local lines = kit.wrap(n.say, words(s), 20, SAY_W - 48)
	for i = 1, math.min(s.lucky and 2 or 3, #lines) do
		h.fit(kit.text(n.say, lines[i], SAY_X + 24, sy0 + (i - 1) * 26, 20, KC.INK), SAY_W - 48)
	end
	-- the prize that jumps off the anvil: the Scaglie fly to the wallet, the fragments hang
	for _, r in ipairs(s.rows) do
		if (r.key == "fragments" or r.key == "lucky") and #n.prize < 4 then
			local x = ax + 60 + #n.prize * 70
			local grp = kit.group(g, x, ay)
			kit.piece(grp, "frammento_" .. r.set, x, ay, 72)
			n.prize[#n.prize + 1] = { node = grp.node, x = x }
		end
	end
	-- the receipt (hidden until its time)
	if s.t >= s.receipt then M.draw_receipt(a, h, s, n) end
	-- the wallet: before the prize while it plays, then as it is
	local tr = kit.anchor(1280, 0, gui.ANCHOR_RIGHT, gui.ANCHOR_TOP)
	a.stop = tr
	n.wallet_parent = kit.group(tr, 1110, 44).node
	local before = s.t < s.reveal
	local gems_gone = s.fired.gems1
	n.wallet = coins.wallet(p.scaglie - (before and s.scaglie or 0), p.ossidiana + (gems_gone and 0 or s.cost), n.wallet_parent, 0, 0)
	coins.vouchers(n.wallet, p.buoni or 0)
	pose(a, s)
end

-- The paper receipt: what came, and the way on
function M.draw_receipt(a, h, s, n)
	local p = a.prof
	local root = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_parent(root, n.shake)
	n.receipt = root
	local g = { node = root, ox = n.g.ox, oy = n.g.oy }
	-- as tall as what it says, in the middle of the room between the header and the band
	local list = {}
	for _, r in ipairs(s.rows) do
		local icon, label, value = row_of(s, r)
		if icon and #list < 8 then list[#list + 1] = { r = r, icon = icon, label = label, value = value } end
	end
	local trust = s.client and #s.done == 1 and p.commesse.clienti[s.client] and p.commesse.clienti[s.client].fiducia
	local x, w = REC_X + 28, REC_W - 56
	local next_lines = trust and kit.wrap(g, h.trust_next(s.client, trust), 16, w) or {}
	local up_lines = {}
	if s.upgrade then
		local fam = equip.BY_ID[s.upgrade].name
		up_lines = kit.wrap(g, T.upgrade_hint:format(fam:sub(1, 1) .. fam:sub(2):lower()), 18, w)
	end
	local tall = 128 + #list * 38 + (trust and 40 + math.min(2, #next_lines) * 19 or 0)
		+ (#up_lines > 0 and 14 + math.min(2, #up_lines) * 22 or 0) + 10
	local top = REC_Y + math.floor((REC_H - tall) / 2)
	local c = h.panel(g, REC_X, top, REC_W, tall, "carta")
	h.nail(g, REC_X, top, REC_W)
	local title = #s.done == 1 and T.delivered or T.delivered_many:format(#s.done)
	kit.text(c, title, x, top + 70, 34, KC.INK, "start", 1)
	local sub = {}
	for _, d in ipairs(s.done) do sub[#sub + 1] = d.order.cliente and T.clients[d.order.cliente] or T.receipt_smith end
	h.fit(kit.text(c, table.concat(sub, " · "), x, top + 98, 16, INK_MUTE), w)
	local y = top + 140
	for _, l in ipairs(list) do
		kit.piece(c, l.icon, x + 16, y - 7, l.r.key == "trust" and 24 or 30)
		h.fit(kit.text(c, l.label, x + 42, y, 20, KC.INK), w - 42 - 70)
		kit.text(c, l.value, x + w, y, 20, l.r.key == "ossidiana" and INK_MUTE or KC.INK, "end")
		y = y + 38
	end
	-- one client: its pearls, and what the next ones bring
	if trust then
		h.pearls(c, trust, x, y - 4, 22)
		for i = 1, math.min(2, #next_lines) do h.fit(kit.text(c, next_lines[i], x, y + 26 + (i - 1) * 19, 16, INK_MUTE), w) end
		y = y + 40 + math.min(2, #next_lines) * 19
	end
	for i = 1, math.min(2, #up_lines) do
		h.fit(kit.text(c, up_lines[i], x, y + 8 + (i - 1) * 22, 18, PAPER_HEAD), w)
	end
	-- the band: POTENZIA (when the fragments pay a level), OK
	if s.upgrade then
		local b = kit.secondary(a.mlow, TP.upgrade_here, 160, 640, 230, 62, {})
		kit.button(a.buttons, b, "scena:potenzia")
	end
	local ok = kit.action(a.mright, T.ok, 948, 628, 308, 80, { size = 42 })
	kit.button(a.buttons, ok, "scena:ok", { main = true })
end

-- Every frame: true when the receipt arrives (the screen is made again, with its buttons)
function M.update(a, dt)
	local s = a.scene
	if not s then return false end
	local was = s.t
	s.t = s.t + dt
	events(a, s, false)
	pose(a, s)
	return was < s.receipt and s.t >= s.receipt
end

-- A tap of the scene. Returns what the armory does next: nil, or "potenzia"
function M.cmd(a, x)
	local s = a.scene
	if not s then return nil end
	if x == "salta" then
		if s.t < s.receipt then
			s.t = s.receipt + 0.35
			events(a, s, true)
		end
	elseif x == "ok" then
		a.scene = nil
	elseif x == "potenzia" then
		a.scene = nil
		return "potenzia"
	end
end

return M
