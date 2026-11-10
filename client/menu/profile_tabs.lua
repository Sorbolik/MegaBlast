-- The PROFILO (character sheet, Sergio 31 Oct): it opens by tapping your own
-- devil in the home. Three tabs, one thing per tab:
--   SCHEDA       the big devil with its pieces labeled, the tag as others see
--                it ("COSÌ TI VEDONO"), each piece's next upgrade and the
--                ARMERIA; at the top the three loadouts (others see the active one)
--   STATISTICHE  four numbers at the top and each stat with its badge on the
--                same row (tapping it puts the badge next to the name); on the
--                right the damage per weapon. Filter by mode, from 2 vs 2
--   PARTITE      the last 10: how it went lap by lap, the moments (tapping one
--                starts the replay from there), who was there (tapping a player
--                shows their tag as it was that time) and RIVEDI
-- The history lives here and not in a home button: matches are your own
-- stuff, and from the podium RIVEDI goes straight to the replay (Sergio's
-- decision, 31 Oct). The screen is rebuilt at every tap, like the armory.
--
--   local s = profilo_schede.new(prof, scheda, colore, replay_ok, numero)  -- scheda: "scheda" (default), "statistiche", "partite"
--                                                      -- replay_ok(numero): is there that match's replay?
--                                                      -- numero: the match to show in PARTITE
--   profilo_schede.update(s, dt)
--   profilo_schede.on_input(s, action_id, action) -> "indietro", "armeria", { rivedi = numero, da = tick } or nil
--   profilo_schede.destroy(s)

local ui = require "ui.ui"
local backdrop = require "ui.backdrop"
local game = require "sim.game"
local equip = require "sim.gear"
local maps = require "sim.maps"
local profile = require "menu.profile"
local milestones = require "menu.milestones"
local showcase = require "menu.showcase"
local tag = require "ui.tag_card"
local scoria = require "battle.scoria"
local T = require("lang.text").profile_tabs
local common = require("lang.text").common

local M = {}

local C = ui.C
local W, H = 1280, 720
local TOUCH = hash("touch")
-- the content, under the header and the tabs (ui.header), to the bottom margin
local TOP = ui.BODY_TOP
local BODY_H = TOP - ui.EDGE
local BODY_Y = ui.EDGE + BODY_H / 2
local ROMAN = { "I", "II", "III", "IV" }

local function vec(x, y) return vmath.vector3(x, y, 0) end
local function with_alpha(c, a) return vmath.vector4(c.x, c.y, c.z, a) end

local function box(x, y, w, h, color, parent)
	local n = gui.new_box_node(vec(x, y), vec(w, h))
	gui.set_color(n, color)
	gui.set_parent(n, parent)
	return n
end

local function txt(t, x, y, scale, color, parent, pivot)
	local n = ui.text(t, x, y, scale, color, parent)
	if pivot then gui.set_pivot(n, pivot) end
	return n
end

local function title(t, x, y, scale, color, parent, pivot)
	local n = ui.title(t, x, y, scale, color, parent)
	if pivot then gui.set_pivot(n, pivot) end
	return n
end

-- a piece of screen you can tap without drawing anything (rows, moments, players)
local function zone(s, x, y, w, h, ui_action, parent)
	local n = box(x, y, w, h, C.LIGHT, parent)
	gui.set_visible(n, false)
	s.buttons[#s.buttons + 1] = { nodo = n, bordo = n, ui_action = ui_action, colore = with_alpha(C.LIGHT, 0), riposo = with_alpha(C.LIGHT, 0) }
	return n
end

local function thousands(n)
	local s = tostring(math.floor(n + 0.5))
	local out = s:reverse():gsub("(%d%d%d)", "%1."):reverse()
	return (out:gsub("^%.", ""))
end

local function piece_name(set, slot)
	local nome = slot.name:sub(1, 1) .. slot.name:sub(2):lower()
	local s = equip.BY_ID[set]
	local n = s.name:sub(1, 1) .. s.name:sub(2):lower()
	return (T.piece_of[set] or T.piece_of.default):format(nome, n)
end

-- SCHEDA tab ------------------------------------------------------------------------

local function sheet_sheet(s, parent)
	local p = s.prof
	local v = showcase.from_profile(p, common.you, 1, T.loadout_n:format(p.is_active))
	v.tu = true
	local col = s.colore
	txt(T.loadout, ui.EDGE, TOP - 12, 0.7, C.OFF, parent, gui.PIVOT_W)
	for i = 1, #p.loadouts do
		ui.tab(s.buttons, ui.EDGE + 21 + (i - 1) * 50, TOP - 50, 42, 42, tostring(i), "assetto:" .. i, p.is_active == i, parent)
	end
	-- the big devil
	local pose = box(245, 62, 0, 0, C.LIGHT, parent)
	gui.set_visible(pose, false)
	s.figure = scoria.new(col, scoria.PERSONAGGIO, "missile")
	-- always with the weapon in hand (as in the proposals), not its turn
	s.figure.holding_weapon, s.figure.weapon_t = true, math.huge
	s.st = { x = 0, y = 0, facing = 1, grounded = true, moving = 0, turno = false }
	scoria.update(s.figure, 0, s.st)
	-- 330 tall up to the head
	local k = 330 / game.DISEGNO_H
	gui.set_scale(pose, vmath.vector3(k, k, 1))
	ui.alone(0, 200 / k, 560 / k, with_alpha(col, 0.2), pose)
	local ground = ui.alone(0, 0, 300 / k, C.SHADOW, pose)
	gui.set_blend_mode(ground, gui.BLEND_ALPHA)
	gui.set_scale(ground, vmath.vector3(1, 0.16, 1))
	gui.set_parent(s.figure.root, pose)
	scoria.set_enabled(s.figure, true)
	-- the labeled pieces: mask and chest on the right, cloak on the left, legs at the bottom
	local calls = { mask = { 290, 1 }, chest = { 170, 1 }, cloak = { 215, -1 }, legs = { 100, 1 } }
	for i, slot in ipairs(equip.SLOTS) do
		local r = calls[slot.id]
		local pz = v.pezzi[i]
		local label = pz.set and T.slot_level:format(slot.name, pz.livello) or T.slot_empty:format(slot.name)
		local lx = r[2] > 0 and 468 or 40
		txt(label, lx, r[1] + 12, 0.75, pz.set and C.LIGHT or C.OFF, parent, gui.PIVOT_W)
		box(r[2] > 0 and 365 or 100, r[1], r[2] > 0 and 190 or 120, 2, C.LINE, parent)
	end
	-- how others see you
	txt(T.how_others_see, 590, TOP - 12, 0.7, C.GOLD, parent, gui.PIVOT_W)
	tag.new(v, 590 + tag.WIDE / 2, TOP - 30, { tu = true }, parent)
	-- each piece's next upgrades: the column on the right, from the content's
	-- top to the bottom margin
	local pan = ui.panel(W - ui.EDGE - 168, BODY_Y, 336, BODY_H, parent)
	title(T.next_steps, -146, BODY_H / 2 - 28, 0.55, C.LIGHT, pan, gui.PIVOT_W)
	txt(T.steps_hint, -146, BODY_H / 2 - 56, 0.55, C.OFF, pan, gui.PIVOT_W)
	for i, slot in ipairs(equip.SLOTS) do
		local pz = v.pezzi[i]
		local y = BODY_H / 2 - 110 - (i - 1) * 82
		tag.piece(pz, 1, -132, y, 56, pan)
		txt(slot.name, -94, y + 24, 0.5, C.OFF, pan, gui.PIVOT_W)
		if pz.set then
			txt(piece_name(pz.set, slot), -94, y + 4, 0.72, C.LIGHT, pan, gui.PIVOT_W)
			local next_one = equip.next_tier(pz.livello)
			local b = ui.bar(-94 + 116, y - 16, 232, 8, C.GOLD, pan)
			if next_one then
				local first_one = 0
				for _, sc in ipairs(equip.TIER_LEVELS) do if sc < next_one then first_one = sc end end
				ui.bar_value(b, (pz.livello - first_one) / (next_one - first_one))
				local tier = equip.tier(next_one)
				local what = (tier >= equip.TIERS and T.next_look_b or T.next_look):format(next_one, ROMAN[tier])
				txt(what, -94, y - 34, 0.55, C.GOLD, pan, gui.PIVOT_W)
			else
				ui.bar_value(b, 1)
				txt(T.all_steps, -94, y - 34, 0.55, C.GOLD, pan, gui.PIVOT_W)
			end
		else
			txt(T.no_piece, -94, y + 4, 0.72, C.OFF, pan, gui.PIVOT_W)
			txt(T.pick_in_armory, -94, y - 18, 0.55, C.OFF, pan, gui.PIVOT_W)
		end
	end
	ui.button(s.buttons, 0, -BODY_H / 2 + 40, 296, 56, common.armory, "armeria", nil, pan)
end

-- STATISTICHE tab -------------------------------------------------------------------

local function sheet_stats(s, parent)
	local p = s.prof
	local x = ui.EDGE
	for _, g in ipairs(profile.GROUPS) do
		local nome = profile.GROUP_NAMES[g]
		local w = 24 + #nome * 11
		ui.tab(s.buttons, x + w / 2, TOP - 20, w, 40, nome, "gruppo:" .. g, s.gruppo == g, parent)
		x = x + w + 8
	end
	local st = profile.statistics(p, s.gruppo)
	local matches = st.partite or 0
	local numbers = {
		{ thousands(matches), T.matches },
		{ matches > 0 and (math.floor((st.vinte or 0) * 100 / matches + 0.5) .. "%") or "–", T.won },
		{ (st.colpi or 0) > 0 and (math.floor((st.a_segno or 0) * 100 / st.colpi + 0.5) .. "%") or "–", T.accuracy },
		{ tostring(st.serie or 0), T.best_streak },
	}
	for i, n in ipairs(numbers) do
		local nx = ui.EDGE + (i - 1) * 150
		title(n[1], nx, TOP - 72, 1, C.LIGHT, parent, gui.PIVOT_W)
		txt(n[2], nx + 2, TOP - 104, 0.55, C.OFF, parent, gui.PIVOT_W)
	end
	txt(T.badge_hint:format(milestones.SHOWN), W - ui.EDGE, TOP - 104, 0.55,
		C.OFF, parent, gui.PIVOT_E)

	-- the stats with their badges
	local all_f = profile.statistics(p, "tutte")
	local picked_ones = {}
	for _, id in ipairs(p.badge) do picked_ones[id] = true end
	-- the two panels from under the numbers to the bottom margin
	local ph = TOP - 130 - ui.EDGE
	local pan = ui.panel(ui.EDGE + 400, ui.EDGE + ph / 2, 800, ph, parent)
	for i, t in ipairs(milestones.WHITELIST) do
		local y = ph / 2 - 25 - (i - 1) * 40
		local val = st[t.id] or 0
		if i > 1 then box(0, y + 20, 760, 1.5, with_alpha(C.LIGHT, 0.1), pan) end
		txt(t.nome, -380, y, 0.8, C.TEXT, pan, gui.PIVOT_W)
		txt(thousands(val) .. (t.unit and (" " .. t.unit) or ""), -110, y, 0.8, C.LIGHT, pan, gui.PIVOT_E)
		if t.thresholds then
			-- the badge comes from the total of all modes
			local tot = all_f[t.id] or 0
			local g = milestones.grade(t, tot)
			if g > 0 then
				tag.badge({ id = t.id, grado = g }, -80, y, 28, pan)
				zone(s, -80, y + 0, 760, 38, "badge:" .. t.id, pan)
			end
			local next_f, how_much = milestones.next(t, tot)
			local b = ui.bar(70, y, 220, 8, C.GOLD, pan)
			ui.bar_value(b, how_much)
			local dx = picked_ones[t.id] and g > 0 and T.next_to_name or
				(next_f and T.next_at:format(thousands(next_f)) or T.badge_grade:format(t.badge, ROMAN[g]))
			txt(dx, 380, y, 0.55, picked_ones[t.id] and g > 0 and C.GOLD or C.OFF, pan, gui.PIVOT_E)
		else
			txt(T.no_badge, 380, y, 0.55, C.OFF, pan, gui.PIVOT_E)
		end
	end

	-- the damage per weapon
	local dan = ui.panel(W - ui.EDGE - 198, ui.EDGE + ph / 2, 396, ph, parent)
	title(T.damage_by_weapon, -176, ph / 2 - 28, 0.55, C.LIGHT, dan, gui.PIVOT_W)
	txt(T.damage_hint, -176, ph / 2 - 54, 0.55, C.OFF, dan, gui.PIVOT_W)
	local armi, tot = {}, 0
	for w, n in pairs(st.armi or {}) do
		armi[#armi + 1] = { w = w, n = n }
		tot = tot + n
	end
	table.sort(armi, function(a, b)
		if a.n ~= b.n then return a.n > b.n end
		return a.w < b.w
	end)
	if #armi == 0 then txt(T.nothing_yet, -176, ph / 2 - 100, 0.7, C.OFF, dan, gui.PIVOT_W) end
	local first = armi[1] and armi[1].n or 1
	for i, a in ipairs(armi) do
		if i > 7 then break end
		local y = ph / 2 - 95 - (i - 1) * 40
		txt(T.weapons[a.w] or a.w, -176, y, 0.8, C.TEXT, dan, gui.PIVOT_W)
		local b = ui.bar(40, y, 160, 12, game.SECONDARY[a.w] and C.STEEL or C.BRACE, dan)
		ui.bar_value(b, a.n / first)
		txt(math.floor(a.n * 100 / tot + 0.5) .. "%", 176, y, 0.8, C.LIGHT, dan, gui.PIVOT_E)
	end
end

-- PARTITE tab -----------------------------------------------------------------------

local function when(t)
	if not t then return "" end
	local hour_of = os.time()
	local today = os.date("*t", hour_of)
	local d = os.date("*t", t)
	if d.year == today.year and d.yday == today.yday then return os.date(T.today, t) end
	if d.year == today.year and d.yday == today.yday - 1 then return os.date(T.yesterday, t) end
	return os.date("%d/%m %H:%M", t)
end

local OUTCOME = { V = { T.outcome_won, C.MINT }, S = { T.outcome_lost, C.BRACE }, P = { T.outcome_tie, C.LIGHT } }

local function face_icon(v, x, y, d, parent)
	local col = C.SQUADRA[v.squadra] or C.LIGHT
	ui.disc(x, y, d, C.BOTTOM, parent)
	local img = require("battle.skins").skins.apprendista.pieces.testa
	local k = (d * 1.1) / img.h
	local n = box(x, y - d * 0.08, img.w * k, img.h * k, vmath.vector4(1, 1, 1, 1), parent)
	gui.set_texture(n, "diavoletto")
	gui.play_flipbook(n, img.img)
	ui.ring_node(x, y, d, 2.5, col, parent)
end

-- the rope: your team's lead at every lap
local function rope(values, cx, cy, w, h, parent, my_own, another)
	box(cx, cy + h / 4, w, h / 2, with_alpha(my_own, 0.07), parent)
	box(cx, cy - h / 4, w, h / 2, with_alpha(another, 0.07), parent)
	box(cx, cy, w, 1.5, with_alpha(C.LIGHT, 0.35), parent)
	local max = 50
	for _, v in ipairs(values) do max = math.max(max, math.abs(v)) end
	local n = #values
	local function point(i)
		local px = cx - w / 2 + (n > 1 and (i - 1) * w / (n - 1) or w / 2)
		return px, cy + values[i] / max * (h / 2 - 8)
	end
	for i = 2, n do
		local x1, y1 = point(i - 1)
		local x2, y2 = point(i)
		local dx, dy = x2 - x1, y2 - y1
		local seg = box((x1 + x2) / 2, (y1 + y2) / 2, math.sqrt(dx * dx + dy * dy), 3, C.LIGHT, parent)
		gui.set_euler(seg, vmath.vector3(0, 0, math.deg(math.atan2(dy, dx))))
	end
	for i = 1, n do
		local x, y = point(i)
		ui.disc(x, y, i == n and 13 or 9, values[i] >= 0 and my_own or another, parent)
		if i > 1 then
			txt(i == n and T.chart_end or T.chart_round:format(i - 1), x, cy - h / 2 - 12, 0.45, C.OFF, parent)
		end
	end
	txt("+" .. thousands(max), cx - w / 2 - 8, cy + h / 2 - 10, 0.45, my_own, parent, gui.PIVOT_E)
	txt("−" .. thousands(max), cx - w / 2 - 8, cy - h / 2 + 10, 0.45, another, parent, gui.PIVOT_E)
end

local function sheet_matches(s, parent)
	local p = s.prof
	txt(T.last_matches:format(profile.MATCHES), ui.EDGE, TOP - 12, 0.6, C.OFF,
		parent, gui.PIVOT_W)
	if #p.partite == 0 then
		txt(T.no_matches, 640, 360, 1, C.OFF, parent)
		return
	end
	s.scelta = math.min(s.scelta or 1, #p.partite)
	for i, pa in ipairs(p.partite) do
		local y = TOP - 54 - (i - 1) * 46
		local e = OUTCOME[pa.esito] or OUTCOME.P
		local sel = i == s.scelta
		local riga = box(ui.EDGE + 270, y, 540, 42, sel and with_alpha(C.LIGHT, 0.06) or with_alpha(C.LIGHT, 0), parent)
		if sel then
			local f, bo = ui.panel(0, 0, 540, 42, riga)
			gui.set_color(f, with_alpha(C.BOTTOM, 0))
			gui.set_color(bo, C.LIGHT)
		end
		box(-266, 0, 6, 38, e[2], riga)
		title(e[1], -252, 0, 0.5, e[2], riga, gui.PIVOT_W)
		local map_name = maps.get(pa.mappa or "")
		txt((map_name and map_name.name or "?") .. " · " .. (profile.GROUP_NAMES[pa.gruppo] or pa.gruppo or ""), -150, 9, 0.62,
			C.LIGHT, riga, gui.PIVOT_W)
		txt(when(pa.quando), -150, -12, 0.5, C.OFF, riga, gui.PIVOT_W)
		for k, g in ipairs(pa.giocatori or {}) do
			if k > 4 then break end
			face_icon(g, 120 + (k - 1) * 30, 0, 26, riga)
		end
		local diff = (pa.punti[1] or 0) - (pa.punti[2] or 0)
		txt((diff > 0 and "+" or diff < 0 and "−" or "") .. thousands(math.abs(diff)), 258, 0, 0.75, C.LIGHT, riga, gui.PIVOT_E)
		zone(s, ui.EDGE + 270, y, 540, 42, "partita:" .. i, parent)
	end

	-- the chosen match
	local pa = p.partite[s.scelta]
	local pan = ui.panel(W - ui.EDGE - 328, BODY_Y, 656, BODY_H, parent)
	local top = BODY_H / 2
	local e = OUTCOME[pa.esito] or OUTCOME.P
	local my_own = C.SQUADRA[(pa.giocatori[pa.me or 1] or {}).squadra or 1] or C.SQUADRA[1]
	local another = C.SQUADRA[2]
	for _, g in ipairs(pa.giocatori or {}) do
		if g.squadra ~= (pa.giocatori[pa.me or 1] or {}).squadra then another = C.SQUADRA[g.squadra] or another end
	end
	title(e[1], -306, top - 28, 0.75, e[2], pan, gui.PIVOT_W)
	local map_name = maps.get(pa.mappa or "")
	txt((map_name and map_name.name or "?") .. " · " .. (profile.GROUP_NAMES[pa.modo] or profile.GROUP_NAMES[pa.gruppo] or ""),
		-180, top - 32, 0.8, C.LIGHT, pan, gui.PIVOT_W)
	local pt = title(thousands(pa.punti[2] or 0), 306, top - 28, 0.6, another, pan, gui.PIVOT_E)
	local wpt = resource.get_text_metrics(gui.get_font_resource(gui.get_font(pt)), gui.get_text(pt)).width * 0.6
	txt("–", 306 - wpt - 12, top - 28, 0.8, C.OFF, pan)
	title(thousands(pa.punti[1] or 0), 306 - wpt - 24, top - 28, 0.6, my_own, pan, gui.PIVOT_E)
	txt(T.round_by_round, -306, top - 62, 0.55, C.OFF, pan, gui.PIVOT_W)
	rope(pa.fune or { 0 }, 20, top - 150, 560, 130, pan, my_own, another)
	txt(T.moments, -306, -6, 0.55, C.OFF, pan, gui.PIVOT_W)
	local ok = s.replay_ok and s.replay_ok(pa.numero)
	local moments = pa.moments or {}
	if #moments == 0 then txt(T.no_moments, -306, -36, 0.65, C.OFF, pan, gui.PIVOT_W) end
	for i, m in ipairs(moments) do
		if i > 4 then break end
		local mx = -156 + ((i - 1) % 2) * 316
		local my = -38 - math.floor((i - 1) / 2) * 44
		local c, border = ui.panel(mx, my, 304, 40, pan)
		if not ok then gui.set_color(border, with_alpha(C.LIGHT, 0.12)) end
		txt(m.giro, -140, 0, 0.5, C.OFF, c, gui.PIVOT_W)
		txt(m.testo, -84, 0, 0.6, ok and C.TEXT or C.OFF, c, gui.PIVOT_W)
		if ok then
			s.buttons[#s.buttons + 1] = { nodo = c, bordo = border, ui_action = "momento:" .. i, colore = C.LIGHT,
				riposo = gui.get_color(border) }
		end
	end
	-- who was there: tapping them, their tag from that time
	for k, g in ipairs(pa.giocatori or {}) do
		if k > 4 then break end
		local gx = -296 + (k - 1) * 150
		face_icon(g, gx + 20, -146, 40, pan)
		txt(g.nome or "?", gx + 46, -138, 0.55, C.TEXT, pan, gui.PIVOT_W)
		txt(g.livello and T.level:format(g.livello) or (g.bot and common.bot or ""), gx + 46, -156, 0.45, C.OFF, pan,
			gui.PIVOT_W)
		zone(s, gx + 60, -146, 140, 46, "giocatore:" .. k, pan)
	end
	if ok then
		ui.button(s.buttons, 210, -top + 40, 200, 58, common.replay, "rivedi", { main = true, colore = my_own }, pan)
	else
		txt(pa.online and T.replay_local_only or T.replay_missing,
			306, -top + 40, 0.6, C.OFF, pan, gui.PIVOT_E)
	end
end

-- Screen ----------------------------------------------------------------------------

local function build(s)
	if s.radice then gui.delete_node(s.radice) end
	ui.header_delete(s.head)
	s.buttons, s.figure = {}, nil
	local p = s.prof
	-- the header (ui.header), before the root so the open tag's veil covers it:
	-- PROFILO, the pill's place, level and experience on the right
	s.head = ui.header(s.buttons, T.title, "indietro")
	local active = s.scheda == "statistiche" and 2 or s.scheda == "partite" and 3 or 1
	ui.header_tabs(s.head, s.buttons, { { T.tab_sheet, "scheda:scheda", 150 },
		{ common.stats, "scheda:statistiche", 206 }, { T.tab_matches, "scheda:partite", 150 } }, active)
	local dx = s.head.right
	title(T.level:format(p.livello), -ui.EDGE, 14, 0.55, C.LIGHT, dx, gui.PIVOT_E)
	local b = ui.bar(-ui.EDGE - 130, -8, 260, 8, s.colore, dx)
	ui.bar_value(b, p.xp / profile.xp_level(p.livello))
	txt(T.xp:format(thousands(p.xp), thousands(profile.xp_level(p.livello))), -ui.EDGE, -24, 0.5, C.OFF, dx, gui.PIVOT_E)
	s.radice = ui.root()
	if s.scheda == "statistiche" then
		sheet_stats(s, s.radice)
	elseif s.scheda == "partite" then
		sheet_matches(s, s.radice)
	else
		sheet_sheet(s, s.radice)
	end
	if s.aperto then
		-- a player's tag from a past match, on top of everything
		s.veil = box(W / 2, H / 2, W * 4, H * 4, with_alpha(C.BOTTOM, 0.82), s.radice)
		local v = s.aperto
		v.verso = 1
		s.carta = tag.new(v, W / 2, 360 + tag.TALL({ portrait = true }) / 2, { portrait = true, tu = v.tu }, s.radice)
	else
		s.carta = nil
	end
end

function M.new(prof, card, color, replay_ok, number)
	local s = { prof = prof, scheda = card or "scheda", colore = color or C.SQUADRA[1], replay_ok = replay_ok }
	-- the stats start from the last match's mode (from 2 vs 2 if there is none)
	local last_one = prof.partite[1] and prof.partite[1].gruppo or "2v2"
	s.gruppo = "tutte"
	for _, g in ipairs(profile.GROUPS) do
		if g == last_one then s.gruppo = g end
	end
	-- numero: the match to show in the PARTITE tab (coming back from a replay)
	for i, pa in ipairs(prof.partite) do
		if pa.numero == number then s.scelta = i end
	end
	s.fondo = backdrop.new("camerino")
	build(s)
	return s
end

function M.update(s, dt)
	if s.figure then scoria.update(s.figure, dt, s.st) end
	if s.carta then tag.update(s.carta, dt) end
end

local function run_cmd(s, ui_action)
	local kind, x = ui_action:match("^(%a+):?(.*)$")
	local p = s.prof
	if kind == "scheda" then
		s.scheda = x
	elseif kind == "assetto" then
		p.is_active = tonumber(x)
		profile.save(p)
	elseif kind == "gruppo" then
		s.gruppo = x
	elseif kind == "badge" then
		profile.choose_badge(p, x)
		profile.save(p)
	elseif kind == "partita" then
		s.scelta = tonumber(x)
	elseif kind == "giocatore" then
		local pa = p.partite[s.scelta or 1]
		s.aperto = pa and pa.giocatori[tonumber(x)]
	elseif kind == "momento" then
		local pa = p.partite[s.scelta or 1]
		local m = pa and pa.moments[tonumber(x)]
		-- a moment earlier, to see how it got there
		if m then return { rivedi = pa.numero, da = math.max(0, m.t - 180) } end
	elseif kind == "rivedi" then
		local pa = p.partite[s.scelta or 1]
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
	if ui_action == "indietro" or ui_action == "armeria" then return ui_action end
	if ui_action then return run_cmd(s, ui_action) end
	return nil
end

function M.destroy(s)
	ui.header_delete(s.head)
	gui.delete_node(s.radice)
	gui.delete_node(s.fondo)
end

return M
