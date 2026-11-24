-- The PROFILO (Figma "RIORGANIZZAZIONE MENU · 14 nov", Consigliata/8 and /9;
-- Sergio, 14 Nov): it opens from the round at the top left of the home. The
-- title is your name, under it your level. Two tabs:
--   STATISTICHE         (the approved board, WB-067 R1) on the left the player's
--                       card: level in a ring of experience, the medals next to
--                       your name, won/lost bar, best streak and stars; in the
--                       middle the mode as chips and the records as cards in two
--                       columns with their icon and medal (tapping one puts it next to
--                       your name); on the right the damage per weapon
--   CRONOLOGIA PARTITE  (WB-067 R2) the last matches as rows: the ribbon with the
--                       outcome, mode and map, the map's miniature, the teams
--                       (tapping a face shows their tag from that time), points,
--                       when, the round RIVEDI; tapping a row opens under it how
--                       it went lap by lap with its moments as numbers on the
--                       line (a tap: the replay from there)
-- The pieces and the Sigilli are in the ZAINO (menu/backpack.lua). Rebuilt at
-- every tap, like the armory.
--
--   local s = profile_tabs.new(prof, tab, color, replay_ok, number)  -- tab: "statistiche" (default) or "partite"
--                                                      -- replay_ok(number): is there that match's replay?
--   profile_tabs.update(s, dt)
--   profile_tabs.on_input(s, action_id, action) -> "indietro", { rivedi = number, da = tick } or nil
--   profile_tabs.destroy(s)

local ui = require "ui.ui"
local kit = require "ui.kit"
local coins = require "ui.coins"
local screen = require "ui.screen"
local game = require "sim.game"
local score = require "battle.score"
local scoria = require "battle.scoria"
local ill = require "ui.illustrations"
local maps = require "sim.maps"
local profile = require "menu.profile"
local milestones = require "menu.milestones"
local tag = require "ui.tag_card"
local orders = require "sim.orders"
local TO = require("lang.text").orders
local T = require("lang.text").profile_tabs
local TH = require("lang.text").home
local common = require("lang.text").common

local M = {}

local C = ui.C
local KC = kit.C
local TOUCH = hash("touch")
local ROMAN = { "I", "II", "III", "IV" }
local MEDALS = { "medaglia_bronzo", "medaglia_argento", "medaglia_oro", "medaglia_oro" }
local GOLD = kit.hex("ffc83d")
-- the modes of the stats, as the Figma's chips (all of them first)
local MODES = { "tutte", "2v2", "1v1", "torneo", "campagna" }

local function thousands(n)
	local s = tostring(math.floor(n or 0))
	local out = s:reverse():gsub("(%d%d%d)", "%1."):reverse()
	return (out:gsub("^%.", ""))
end

-- a text never wider than max (a long one shrinks)
local function fit(n, max)
	local nw = kit.width(n)
	if nw > max then gui.set_scale(n, gui.get_scale(n) * (max / nw)) end
	return n
end

-- STATISTICHE ------------------------------------------------------------------------

local function sheet_stats(s)
	local p = s.prof
	local g = s.left
	local st = profile.statistics(p, s.gruppo)
	local matches, won = st.partite or 0, st.vinte or 0
	local all = profile.statistics(p, "tutte")
	local picked = {}
	for _, id in ipairs(p.badge) do picked[id] = true end

	-- on the left, the player's card (the approved board, WB-067 R1)
	kit.panel(kit.group(g, 180, 344).node, 296, 492)
	-- the level: your face in a ring that fills with the experience
	local need = profile.xp_level(p.livello or 1)
	local f = math.max(0, math.min(1, (p.xp or 0) / need))
	local rx, ry, rr = 100, 168, 47
	kit.dot(g, rx, ry, 108, KC.INK)
	kit.dot(g, rx, ry, 94, kit.with_alpha(KC.STEEL, 0.25))
	local steps = 64
	for i = 0, math.floor(steps * f + 0.5) - 1 do
		local a = math.pi / 2 - (i / steps) * 2 * math.pi
		kit.dot(g, rx + rr * math.cos(a), ry - rr * math.sin(a), 11, KC.HOT)
	end
	kit.dot(g, rx, ry, 82, KC.INK)
	score.face(g.node, rx - g.ox, g.oy - ry, 76, s.colore, scoria.player)
	kit.text(g, T.level_short:format(p.livello or 1), 164, 164, 30, KC.SAND)
	fit(kit.text(g, T.xp:format(thousands(p.xp or 0), thousands(need)), 164, 190, 16, KC.MUTE, "start", 0.4), 148)
	-- the medals next to your name: the chosen ones, then an empty place
	kit.text(g, T.next_to_name, 50, 250, 16, KC.HOT, "start", 0.6)
	-- (the clients' badges too: sim/orders.lua badges)
	local client_grade = {}
	for _, b in ipairs(orders.badges(p)) do client_grade[b.id] = b.grado end
	local shown = {}
	for _, id in ipairs(p.badge) do
		local t = milestones.BY_ID[id]
		local grade = t and t.thresholds and milestones.grade(t, all[id] or 0) or client_grade[id] or 0
		if grade > 0 and #shown < milestones.SHOWN then shown[#shown + 1] = { id = id, t = t, grade = grade } end
	end
	for i = 1, milestones.SHOWN do
		local x = 50 + (i - 1) * 88
		local b = shown[i]
		if b then
			kit.card(g, x, 264, 76, 80, KC.ROSE, { sel = true })
			if b.t then
				kit.piece(g, MEDALS[b.grade], x + 38, 292, 36)
				kit.text(g, ROMAN[b.grade], x + 38, 298, 16, KC.INK, "middle")
				fit(kit.text(g, b.t.badge, x + 38, 332, 16, KC.SAND, "middle", 0.3), 64)
			else
				tag.badge({ id = b.id, grado = b.grade }, x + 38 - g.ox, g.oy - 298, 40, g.node)
				local cl = b.id:sub(#orders.BADGE + 1)
				local name = b.id == orders.JACKPOT_BADGE and T.jackpot_badge or kit.upper(TO.clients[cl])
				fit(kit.text(g, name, x + 38, 332, 16, KC.SAND, "middle", 0.3), 64)
			end
			kit.zone(g, s.buttons, x, 264, 76, 80, "badge:" .. b.id)
		else
			kit.card(g, x, 264, 76, 80, KC.ROSE, { off = true })
			kit.text(g, "+", x + 38, 316, 34, KC.MUTE, "middle")
		end
	end
	-- won and lost: one bar, ember and ice
	kit.text(g, kit.upper(thousands(won) .. " " .. T.won), 50, 390, 18, KC.HOT, "start", 0.4)
	kit.text(g, kit.upper(thousands(matches - won) .. " " .. T.lost), 310, 390, 18, KC.STEEL, "end", 0.4)
	-- (the bar of every bar: kit.bar_parts, the home's groove and strip)
	local wf = matches > 0 and won / matches or 0
	local parts = {}
	if won > 0 then parts[#parts + 1] = { 0, math.max(16, 256 * wf), KC.HOT } end
	if matches > won then parts[#parts + 1] = { won > 0 and math.max(16, 256 * wf) or 0, 256, KC.ICE } end
	kit.bar_parts(g, 52, 404, 256, 16, parts)
	kit.text(g, kit.upper(T.won_share:format(math.floor(wf * 100 + 0.5))), 180, 448, 16, KC.MUTE, "middle", 0.4)
	-- best streak and stars
	for i, b in ipairs({ { thousands(st.serie or 0), T.best_streak, KC.HOT }, { thousands(profile.total_stars(p)), T.stars, KC.SAND } }) do
		local x = 50 + (i - 1) * 138
		kit.card(g, x, 470, 122, 100, KC.ROSE)
		kit.text(g, b[1], x + 61, 526, 38, b[3], "middle")
		kit.text(g, b[2], x + 61, 554, 16, KC.MUTE, "middle", 0.6)
	end

	-- in the middle: which matches, then the records as cards in two columns
	local list, active = {}, 1
	for i, gr in ipairs(MODES) do
		list[i] = { T.mode_short[gr] or kit.upper(profile.GROUP_NAMES[gr]), "gruppo:" .. gr }
		if gr == s.gruppo then active = i end
	end
	-- as wide as the two columns of cards under them
	require("menu.gear_ui").chips(s, g, 350, 98, list, active, 2 * 218 + 14)
	local cw, ch = 218, 70
	for i, t in ipairs(milestones.WHITELIST) do
		local x = 350 + ((i - 1) % 2) * (cw + 14)
		local y = 160 + math.floor((i - 1) / 2) * (ch + 12)
		local tot = all[t.id] or 0
		local grade = t.thresholds and milestones.grade(t, tot) or 0
		local chosen = picked[t.id] and grade > 0
		kit.card(g, x, y, cw, ch, KC.ROSE, { sel = chosen })
		-- its icon (WB-069), drawn by Codex: what the record is, at a glance
		kit.piece(g, "record_" .. t.id, x + 32, y + ch / 2, 48)
		local num = kit.upper(thousands(st[t.id] or 0) .. (t.unit and (" " .. t.unit) or ""))
		local n = fit(kit.text(g, num, x + 60, y + 34, 24, KC.HOT), 120)
		fit(kit.text(g, kit.upper(t.nome), x + 60, y + 57, 16, KC.SAND, "start", 0.3), cw - 72)
		if grade > 0 then
			-- the medal on the corner (WB-067: bronze, silver, gold; the fourth gold too)
			kit.piece(g, MEDALS[grade], x + cw - 16, y + 14, 34)
			kit.text(g, ROMAN[grade], x + cw - 16, y + 20, 16, KC.INK, "middle")
			kit.zone(g, s.buttons, x, y, cw, ch, "badge:" .. t.id)
		elseif t.thresholds then
			-- not yet: the empty medal, and how far the first one is
			kit.piece(g, "medaglia_vuota", x + cw - 16, y + 14, 34)
			local nw = kit.width(n)
			fit(kit.text(g, "/ " .. thousands(milestones.next(t, tot)), x + 66 + nw, y + 34, 16, KC.MUTE, "start", 0.3),
				math.max(10, cw - 102 - nw))
		end
	end
	-- the clients' badges (Sergio, 23 Nov: chosen here like the others), in the place
	-- after the records: a row of up to four, two rows from five
	if p.commesse and p.commesse.aperta then
		local i = #milestones.WHITELIST
		local x = 350 + (i % 2) * (cw + 14)
		local y = 160 + math.floor(i / 2) * (ch + 12)
		local list = orders.badges(p)
		kit.card(g, x, y, cw, ch, KC.ROSE, { off = #list == 0 })
		if #list == 0 then
			local lines = kit.wrap(g, T.clients_none, 16, cw - 24)
			for k = 1, math.min(2, #lines) do kit.text(g, lines[k], x + cw / 2, y + 30 + (k - 1) * 20, 16, KC.MUTE, "middle", 0.3) end
		else
			-- up to four: a row and under it the name, like the records'; from five, two rows
			local two = #list > 4
			local d = two and 26 or 34
			local label = #list == 1 and list[1].id == orders.JACKPOT_BADGE and T.jackpot_badge_long or T.clients_badges
			if not two then fit(kit.text(g, label, x + 14, y + 57, 16, KC.SAND, "start", 0.3), cw - 28) end
			for k, b in ipairs(list) do
				local col, row = (k - 1) % 4, two and math.floor((k - 1) / 4) or 0
				local bx = x + 14 + d / 2 + col * ((cw - 28 - d) / 3)
				local by = y + (two and 22 + row * 32 or 26)
				-- (the jackpot's is already a gold medal: no gold disc behind it, Sergio 24 Nov)
				if picked[b.id] and b.id ~= orders.JACKPOT_BADGE then kit.dot(g, bx, by, d + 10, GOLD) end
				tag.badge(b, bx - g.ox, g.oy - by, d, g.node)
				kit.zone(g, s.buttons, bx - (d + 8) / 2, by - (d + 8) / 2, d + 8, d + 8, "badge:" .. b.id)
			end
		end
	end
	-- how the medals work: at the foot, where there is room to read it
	kit.foot_text(s.low, kit.upper(T.badge_hint:format(milestones.SHOWN)), 140, 674, 19, KC.MUTE, 1080, 0.5)

	-- on the right, the damage per weapon, each with its picture
	local r = s.rt
	local x, w = 822, 426
	kit.panel(kit.group(r, x + w / 2, 344).node, w, 492)
	kit.text(r, T.damage_by_weapon, x + 24, 140, 22, KC.HOT, "start", 1)
	-- what the two colours of the bars say (Sergio, 17 Nov)
	local lx = x + 24
	for _, l in ipairs({ { KC.HOT, T.legend_primary }, { KC.ICE, T.legend_secondary } }) do
		kit.bar(r, lx + 2, 157, 26, 10, 1, l[1])
		lx = lx + 38
		lx = lx + kit.width(kit.text(r, l[2], lx, 168, 16, KC.MUTE, "start", 0.3)) + 22
	end
	local weapons = {}
	for id, n in pairs(st.armi or {}) do weapons[#weapons + 1] = { w = id, n = n } end
	table.sort(weapons, function(a, b)
		if a.n ~= b.n then return a.n > b.n end
		return a.w < b.w
	end)
	if #weapons == 0 then
		kit.text(r, kit.upper(T.nothing_yet), x + w / 2, 340, 19, KC.MUTE, "middle", 0.6)
	end
	local first = weapons[1] and weapons[1].n or 1
	for i, a in ipairs(weapons) do
		if i > 7 then break end
		local y = 186 + (i - 1) * 56
		kit.dot(r, x + 42, y + 22, 46, KC.INK)
		local ic = gui.new_box_node(vmath.vector3(x + 42 - r.ox, r.oy - (y + 22), 0), vmath.vector3(40, 40, 0))
		gui.set_parent(ic, r.node)
		gui.set_texture(ic, "armi")
		gui.play_flipbook(ic, a.w .. "_icona")
		fit(kit.text(r, kit.upper(T.weapons[a.w] or a.w), x + 76, y + 14, 18, KC.SAND), 220)
		kit.text(r, thousands(a.n), x + w - 24, y + 14, 18, KC.MUTE, "end")
		kit.bar(r, x + 80, y + 26, w - 108, 14, a.n / first, game.SECONDARY[a.w] and KC.ICE or KC.HOT)
	end
end

-- CRONOLOGIA PARTITE -----------------------------------------------------------------

local function when(t)
	if not t then return "" end
	local today = os.date("*t")
	local d = os.date("*t", t)
	if d.year == today.year and d.yday == today.yday then return os.date(T.today, t) end
	if d.year == today.year and d.yday == today.yday - 1 then return os.date(T.yesterday, t) end
	return os.date("%d/%m", t)
end

local OUTCOME = { V = { T.outcome_won, KC.HOT }, S = { T.outcome_lost, KC.STEEL }, P = { T.outcome_tie, KC.SAND } }
-- the rows the board shows (the profile keeps more, for the replays)
local ROWS = 6
local RH = 84
-- the open match grows under its row: how it went lap by lap, its moments on the
-- line as numbers (the approved board, WB-067 R2)
local DETAIL = 182
local BOTTOM = 598
-- the moments shown on the line (the match keeps more)
local SHOWN = 4

-- the rope: your team's lead at every lap, in the box x..x+w, y..y+h; the zero
-- line dashed. Returns where lap i is (i can be between two laps)
local function rope(g, values, x, y, w, h, my_own, another)
	local cy = y + h / 2
	local max = 50
	for _, v in ipairs(values) do max = math.max(max, math.abs(v)) end
	local n = #values
	local function point(i)
		i = math.max(1, math.min(n, i))
		local a = math.floor(i)
		local b = math.min(n, a + 1)
		local v = values[a] + (values[b] - values[a]) * (i - a)
		return x + (n > 1 and (i - 1) * w / (n - 1) or w / 2), cy - v / max * (h / 2 - 8)
	end
	for i = 2, n do
		local x1, y1 = point(i - 1)
		local x2, y2 = point(i)
		kit.line(g, x1, y1, x2, y2, 9, KC.INK)
		kit.line(g, x1, y1, x2, y2, 5, values[i] >= 0 and my_own or another)
	end
	-- the zero line, dashed, with a gap where a moment's words cross it
	local function zero(holes)
		for dx = 0, w - 12, 24 do
			local free = true
			for _, h in ipairs(holes) do
				if x + dx + 12 > h[1] and x + dx < h[2] then free = false end
			end
			if free then kit.line(g, x + dx, cy, x + dx + 12, cy, 2, kit.with_alpha(KC.MUTE, 0.5)) end
		end
	end
	return point, zero, cy
end

-- the lap of a moment as a number (the matches saved before 16 Nov have its
-- words, "GIRO 3" or "ULTIMO GIRO": the number in them, or the last lap)
local function lap_of(m, laps)
	local r = tonumber(m.giro) or tonumber(tostring(m.giro or ""):match("%d+")) or laps
	return math.max(1, math.min(laps, r))
end

-- under the open row: the rope across the row, the moments as numbers on it
-- (the approved board: a gold round with the lap's number on the line, its
-- words right under it; a tap replays from there)
local function detail(s, g, pa, x, y, w)
	local my_own = KC.HOT
	local another = KC.STEEL
	local ok = s.replay_ok and s.replay_ok(pa.numero)
	local values = pa.fune or { 0 }
	local laps = math.max(1, #values - 1)
	local moments = {}
	for i, m in ipairs(pa.moments or {}) do
		if i > SHOWN then break end
		moments[i] = { i = i, lap = lap_of(m, laps), testo = m.testo or "" }
	end
	fit(kit.text(g, kit.upper(#moments > 0 and T.round_by_round_tap or T.round_by_round), x + 32, y + 22, 16, KC.MUTE, "start", 0.5),
		w - 64)
	local point, zero, cy = rope(g, values, x + 48, y + 46, w - 112, 84, my_own, another)
	-- the moments of the same lap side by side inside it
	local in_lap, seen = {}, {}
	for _, m in ipairs(moments) do in_lap[m.lap] = (in_lap[m.lap] or 0) + 1 end
	local holes, right = {}, {}
	for _, m in ipairs(moments) do
		seen[m.lap] = (seen[m.lap] or 0) + 1
		local px, py = point(m.lap + seen[m.lap] / (in_lap[m.lap] + 1))
		kit.dot(g, px, py, 36, KC.INK)
		kit.dot(g, px, py, 30, ok and GOLD or KC.MUTE)
		kit.text(g, tostring(m.lap), px, py + 6, 16, KC.INK, "middle")
		-- the moment's words right under its number, on two lines if long, never
		-- over the words of the moment before
		local ly = py + 38
		local lines = kit.wrap(g, kit.upper(m.testo), 16, 140)
		local nodes, half = {}, 0
		for li, line in ipairs(lines) do
			nodes[li] = fit(kit.text(g, line, px, ly + (li - 1) * 18, 16, ok and KC.SAND or KC.MUTE, "middle", 0.3), 200)
			half = math.max(half, kit.width(nodes[li]) / 2)
		end
		local lx = math.max(x + 32 + half, math.min(x + w - 32 - half, px))
		local bottom = ly + (#lines - 1) * 18
		for _, r in ipairs(right) do
			if ly - 16 < r[3] + 6 and bottom > r[2] - 22 and lx - half < r[1] + 12 then lx = math.min(x + w - 32 - half, r[1] + 12 + half) end
		end
		right[#right + 1] = { lx + half, ly, bottom }
		for li, n in ipairs(nodes) do
			local at = gui.get_position(n)
			at.x = lx - g.ox
			gui.set_position(n, at)
			local base = ly + (li - 1) * 18
			if cy > base - 14 and cy < base + 4 then
				local hw = kit.width(n) / 2 + 8
				holes[#holes + 1] = { lx - hw, lx + hw }
			end
		end
		if ok then
			kit.zone(g, s.buttons, px - 28, py - 28, 56, 56, "momento:" .. m.i)
			kit.zone(g, s.buttons, lx - half - 6, ly - 20, 2 * half + 12, bottom - ly + 28, "momento:" .. m.i)
		end
	end
	zero(holes)
	if #moments == 0 then kit.text(g, kit.upper(T.no_moments), x + w / 2, y + 172, 16, KC.MUTE, "middle", 0.5) end
end

local function sheet_matches(s)
	local p = s.prof
	local g = s.left
	if #p.partite == 0 then
		kit.text(g, kit.upper(T.no_matches), 36, 160, 20, KC.MUTE, "start", 0.5)
		return
	end
	kit.foot_text(s.low, kit.upper(T.history_hint:format(profile.MATCHES)), 140, 674, 19, KC.MUTE, 1080, 0.5)
	-- the row goes across the whole screen; the middle columns follow its room
	local w = screen.width() - 72
	local mid = (w - 1208) / 2
	local y = 96
	for i, pa in ipairs(p.partite) do
		if i > ROWS or y + RH > BOTTOM then break end
		local x = 36
		local open = i == s.open
		local e = OUTCOME[pa.esito] or OUTCOME.P
		local h = open and RH + DETAIL or RH
		kit.card(g, x, y, w, h, KC.ROSE, { sel = open })
		-- the whole row opens and closes (under the faces and RIVEDI, which are their own)
		kit.zone(g, s.buttons, x, y, w, RH, "partita:" .. i)
		-- the head of the row: the ribbon (WB-067), ember if won, ice if not, the word on it
		kit.strip(g, pa.esito == "V" and "nastro_vittoria" or "nastro_sconfitta", x - 8, y, 196, RH)
		fit(kit.text(g, e[1], x + 12, y + RH / 2 + 10, 26, KC.INK), 140)
		-- mode and map
		local map = maps.get(pa.mappa or "")
		fit(kit.text(g, kit.upper(profile.GROUP_NAMES[pa.gruppo] or pa.gruppo or ""), x + 200, y + 36, 20, KC.SAND), 180)
		fit(kit.text(g, kit.upper(map and map.name or ""), x + 200, y + 62, 16, KC.MUTE, "start", 0.4), 180)
		-- the map's miniature
		local tex = pa.mappa and ill.map_mini(pa.mappa)
		if tex then
			s.minis[#s.minis + 1] = pa.mappa
			local mx = x + 392 + mid * 0.3
			kit.rect(g, mx - 3, y + 11, 116, 62, KC.INK)
			local n = gui.new_box_node(vmath.vector3(mx + 55 - g.ox, g.oy - (y + RH / 2), 0), vmath.vector3(110, 56, 0))
			gui.set_parent(n, g.node)
			gui.set_texture(n, tex)
		end
		-- who was there: your team, VS, the others
		local mine = (pa.giocatori or {})[pa.me or 1] or {}
		local sides = { {}, {} }
		for k, pl in ipairs(pa.giocatori or {}) do
			if k > 4 then break end
			local side = pl.squadra == mine.squadra and sides[1] or sides[2]
			side[#side + 1] = k
		end
		local fx = x + 546 + mid * 0.6
		for si, side in ipairs(sides) do
			if si == 2 then
				kit.text(g, T.vs, fx + 14, y + RH / 2 + 7, 18, KC.MUTE, "middle", 0.5)
				fx = fx + 34
			end
			for _, k in ipairs(side) do
				local pl = pa.giocatori[k]
				score.face(g.node, fx + 22 - g.ox, g.oy - (y + RH / 2), 46, C.SQUADRA[pl.squadra] or C.LIGHT, pl.look)
				kit.zone(g, s.buttons, fx, y + 10, 46, RH - 20, "giocatore:" .. i .. ":" .. k)
				fx = fx + 50
			end
		end
		local px = x + 826 + mid
		kit.text(g, thousands(pa.punti and pa.punti[1] or 0), px, y + 42, 32, KC.SAND)
		kit.text(g, kit.upper(T.points), px, y + 66, 16, KC.MUTE, "start", 0.6)
		kit.text(g, kit.upper(when(pa.quando)), x + 946 + mid * 1.4, y + RH / 2 + 7, 18, KC.MUTE, "start", 0.5)
		-- RIVEDI: the round play button (WB-067); grey when the replay isn't on this phone
		local ok = s.replay_ok and s.replay_ok(pa.numero)
		local b = kit.piece(g, ok and "rivedi" or "rivedi_premuto", x + w - 52, y + RH / 2, 66)
		if not ok then gui.set_color(b, vmath.vector4(0.55, 0.55, 0.55, 0.7)) end
		kit.button(s.buttons, { node = b }, "rivedi:" .. i, { spento = not ok })
		if open then detail(s, g, pa, x, y + RH - 8, w) end
		y = y + h + 14
	end
end


-- Screen ----------------------------------------------------------------------------

local function build(s)
	if s.head then kit.header_delete(s.head) end
	for _, k in ipairs({ "left", "rt", "low", "veil_g" }) do
		if s[k] then gui.delete_node(s[k].node); s[k] = nil end
	end
	s.buttons = {}
	for _, m in ipairs(s.minis or {}) do ill.map_mini_release(m) end
	s.minis = {}
	local p = s.prof
	-- the title is your name; a long one shrinks before the tabs
	s.head = kit.header(s.buttons, TH.player, KC.HOT, "indietro", common.home)
	local tw = kit.width(s.head.title[2])
	if tw > 262 then
		for _, n in ipairs(s.head.title) do gui.set_scale(n, gui.get_scale(n) * (262 / tw)) end
	end
	s.wallet = coins.wallet(p.scaglie or 0, p.ossidiana or 0, kit.group(s.head.top_right, 1110, 44).node, 0, 0)
	kit.tabs(s.head.top_left, s.buttons, 320, 28, { { common.stats, "scheda:statistiche" }, { T.tab_matches, "scheda:partite" } },
		s.scheda == "partite" and 2 or 1, KC.PURPLE, true)
	s.left = kit.anchor(0, 0, gui.ANCHOR_LEFT)
	s.rt = kit.anchor(1280, 0, gui.ANCHOR_RIGHT)
	s.low = kit.anchor(0, 720, gui.ANCHOR_LEFT, gui.ANCHOR_BOTTOM)
	if s.scheda == "partite" then sheet_matches(s) else sheet_stats(s) end
	if s.aperto then
		-- a player's tag from a past match, on top of everything
		s.veil_g = kit.anchor(0, 0)
		kit.rect(s.veil_g, -2560, -1440, 1280 * 5, 720 * 5, kit.with_alpha(C.BOTTOM, 0.82))
		local v = s.aperto
		v.verso = 1
		s.carta = tag.new(v, 640, tag.TOP({ portrait = true }), { portrait = true, tu = v.tu }, s.veil_g.node)
	else
		s.carta = nil
	end
end

function M.new(prof, tab, color, replay_ok)
	local s = { prof = prof, scheda = tab == "partite" and "partite" or "statistiche", colore = color or C.SQUADRA[1],
		replay_ok = replay_ok, open = 1 }
	-- the stats start from the last match's mode (all of them if there is none)
	local last = prof.partite[1] and prof.partite[1].gruppo
	s.gruppo = "tutte"
	for _, g in ipairs(MODES) do
		if g == last then s.gruppo = g end
	end
	s.scene = kit.scene(250, 420, { accent = KC.PURPLE, bg = "camerino" })
	build(s)
	return s
end

function M.update(s, dt)
	if s.carta then tag.update(s.carta, dt) end
end

local function run_cmd(s, ui_action)
	local kind, x = ui_action:match("^(%a+):?(.*)$")
	local p = s.prof
	if kind == "scheda" then
		s.scheda = x
	elseif kind == "gruppo" then
		s.gruppo = x
	elseif kind == "badge" then
		profile.choose_badge(p, x)
		profile.save(p)
	elseif kind == "giocatore" then
		local i, k = x:match("(%d+):(%d+)")
		local pa = p.partite[tonumber(i)]
		s.aperto = pa and pa.giocatori[tonumber(k)]
	elseif kind == "partita" then
		local i = tonumber(x)
		s.open = s.open ~= i and i or nil
	elseif kind == "momento" then
		local pa = p.partite[s.open or 1]
		local m = pa and (pa.moments or {})[tonumber(x)]
		-- a moment earlier, to see how it got there
		if m then return { rivedi = pa.numero, da = math.max(0, m.t - 180) } end
	elseif kind == "rivedi" then
		local pa = p.partite[tonumber(x)]
		if pa then return { rivedi = pa.numero, da = 0 } end
	end
	build(s)
end

function M.on_input(s, action_id, action)
	-- the tag is open: any tap closes it
	if s.aperto then
		if (action_id == TOUCH and action.pressed) or (action_id == ui.PAD and action.pressed) then
			s.aperto = nil
			build(s)
		end
		return nil
	end
	local ui_action = ui.touch(s.buttons, action_id, action)
	if ui_action == "indietro" then return ui_action end
	if ui_action then return run_cmd(s, ui_action) end
	return nil
end

function M.destroy(s)
	for _, m in ipairs(s.minis or {}) do ill.map_mini_release(m) end
	kit.header_delete(s.head)
	for _, k in ipairs({ "left", "rt", "low", "veil_g" }) do
		if s[k] then gui.delete_node(s[k].node) end
	end
	kit.scene_drop(s.scene)
end

return M
