-- The PROFILO (character sheet, Sergio 31 Oct): it opens by tapping your own
-- devil in the home. Four tabs, one thing per tab:
--   SCHEDA       the big devil with its pieces labeled, the tag as others see
--                it ("COSÌ TI VEDONO"), each piece's next upgrade and the
--                ARMERIA; at the top the three loadouts (others see the active one)
--   SIGILLI      the three paths of points and their powers (menu/seals.lua)
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
--   local s = profilo_schede.new(prof, scheda, colore, replay_ok, numero)  -- scheda: "scheda" (default), "sigilli", "statistiche", "partite"
--                                                      -- replay_ok(numero): is there that match's replay?
--                                                      -- numero: the match to show in PARTITE
--   profilo_schede.update(s, dt)
--   profilo_schede.on_input(s, action_id, action) -> "indietro", "armeria", { rivedi = numero, da = tick } or nil
--   profilo_schede.destroy(s)

local ui = require "ui.ui"
local kit = require "ui.kit"
local coins = require "ui.coins"
local game = require "sim.game"
local score = require "battle.score"
local equip = require "sim.gear"
local maps = require "sim.maps"
local profile = require "menu.profile"
local milestones = require "menu.milestones"
local showcase = require "menu.showcase"
local seals = require "menu.seals"
local loadout = require "sim.loadout"
local tag = require "ui.tag_card"
local scoria = require "battle.scoria"
local T = require("lang.text").profile_tabs
local common = require("lang.text").common

local M = {}

local C = ui.C
local KC = kit.C
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

-- Where there is room at the sides (a screen wider than 16:9) the devil's
-- side goes left with the real edge, above its plate, and the rest breathes
-- (Sergio, 11 Nov: «spostalo più a sinistra dove c'è spazio, centrandolo
-- sempre coi raggi, dai più spazio alle cose»; the measures are kit.side,
-- kit.lean and kit.air). devil_x(): where the devil is, in
-- Figma coordinates
function M.devil_x() return 250 - kit.side() end
M.DEVIL_Y = 380    -- its height (the middle of its body)
-- a group like g, moved with the devil's side
function M.left_of(g)
	local n = box(-kit.side() + kit.lean(), 0, 0, 0, C.LIGHT, g.node)
	gui.set_visible(n, false)
	return { node = n, ox = g.ox, oy = g.oy }
end

-- The devil on the left and under it its plate, level and experience: on every
-- tab here and in the armory. s: prof, colore, radice, low. line: instead of
-- the profile's plate, a light one with this line (the training)
function M.devil(s, line)
	local p = s.prof
	-- (a little higher than its plate: Sergio, 11 Nov)
	-- the content leans toward the devil and its columns part (kit.air)
	local rp = gui.get_position(s.radice)
	rp.x = -kit.lean()
	gui.set_position(s.radice, rp)
	if s.kg then s.kg.air = true end
	local pose = box(M.devil_x() + kit.lean(), 126, 0, 0, C.LIGHT, s.radice)
	gui.set_visible(pose, false)
	s.figure = scoria.new(s.colore, scoria.PERSONAGGIO)
	s.st = { x = 0, y = 0, facing = 1, grounded = true, moving = 0, fermo = true }
	scoria.update(s.figure, 0, s.st)
	local k = 265 / game.DISEGNO_H
	gui.set_scale(pose, vmath.vector3(k, k, 1))
	local ground = ui.alone(0, 0, 230 / k, C.SHADOW, pose)
	gui.set_blend_mode(ground, gui.BLEND_ALPHA)
	gui.set_scale(ground, vmath.vector3(1, 0.14, 1))
	gui.set_parent(s.figure.root, pose)
	scoria.set_enabled(s.figure, true)
	if line then
		-- no profile here: a light plate that says what the place is
		local on_plate = kit.sand(s.low, 80, 630, 340, 62, s.accent or KC.STAR, { sk = 22 })
		kit.text(on_plate.g, line, 250, 668, 22, KC.INK, "middle", 1)
		return
	end
	local lv = (p.braci or 0) > 0 and T.level_braci:format(p.livello, p.braci) or T.level:format(p.livello)
	kit.nameplate(s.low, 80, 630, T.your_devil, lv .. " · " .. thousands(p.xp) .. "/" .. thousands(profile.xp_level(p.livello)),
		p.xp / profile.xp_level(p.livello), KC.PURPLE)
end

-- SCHEDA tab ------------------------------------------------------------------------

-- the loadouts (SCHEDA and SIGILLI): a choice, the sand blade behind the active
-- one; a closed one says from which level
function M.loadouts(s)
	local p = s.prof
	local g = M.left_of(s.kg)
	kit.text(g, T.loadout, 46, 112, 14, KC.MUTE, "start", 1.5)
	local n = 0
	for i = 1, #p.loadouts do
		if loadout.open(i, p.livello) then
			local x = 40 + n * 54
			if p.is_active == i then kit.para(g, x, 125, 46, 34, 10, KC.SAND) end
			kit.text(g, tostring(i), x + 27, 148, 18, p.is_active == i and KC.INK or KC.MUTE, "middle")
			kit.zone(g, s.buttons, x, 118, 54, 48, "assetto:" .. i)
			n = n + 1
		end
	end
	kit.rect(g, 40, 160, math.max(1, n) * 54, 2, kit.with_alpha(KC.SAND, 0.2))
	for i = 1, #p.loadouts do
		if not loadout.open(i, p.livello) then
			kit.text(g, T.loadout_locked:format(i, loadout.LOADOUT_LEVELS[i]), 40 + n * 54 + 10, 148, 11, KC.MUTE, "start", 1)
			break
		end
	end
end

local function sheet_sheet(s, parent)
	local p = s.prof
	local g = s.kg
	local v = showcase.from_profile(p, common.you, 1, T.loadout_n:format(p.is_active))
	v.tu = true
	-- the pieces worn: one card each, staggered
	for i, slot in ipairs(equip.SLOTS) do
		local pz = v.pezzi[i]
		local x, y = 440 + (i - 1) * 12, 176 + (i - 1) * 84
		local full = pz.set and equip.next_tier(pz.livello) == nil
		local k = kit.card(g, x, y, 236, 70, full and KC.STAR or KC.ROSE)
		kit.text(k.g, slot.name, x + 30, y + 25, 12, KC.MUTE, "start", 1.5)
		if pz.set then
			kit.text(k.g, equip.BY_ID[pz.set].name, x + 26, y + 54, 24, KC.SAND)
			kit.text(k.g, tostring(pz.livello), x + 222, y + 34, 24, full and KC.STAR or KC.SAND, "end")
			kit.pips(k.g, x + 222 - 45, y + 44, 3, equip.tier(pz.livello) - 1, KC.SAND)
		else
			kit.text(k.g, T.no_piece_short, x + 26, y + 54, 24, KC.MUTE)
		end
	end
	-- how others see you (ui/tag_card.lua)
	local mid = 726 + kit.air(0.5)
	kit.heading(g, T.how_others_see, mid + 10, 168)
	tag.new(v, mid + tag.WIDE / 2, 720 - 180, { tu = true }, parent)
	-- the next upgrade of each piece: rows to read
	local last = 1034 + kit.air()
	kit.heading(g, T.next_steps, last + 6, 168)
	for i, slot in ipairs(equip.SLOTS) do
		local pz = v.pezzi[i]
		local y, x = 184 + (i - 1) * 76, last - (i - 1) * 5
		local next_one = pz.set and equip.next_tier(pz.livello)
		kit.info(g, x, y, 216, 62, (pz.set and not next_one) and KC.STAR or KC.ROSE)
		if pz.set then
			kit.text(g, string.upper(piece_name(pz.set, slot)), x + 22, y + 24, 14, KC.SAND)
			local f, what = 1, T.all_steps
			if next_one then
				local first_one = 0
				for _, sc in ipairs(equip.TIER_LEVELS) do if sc < next_one then first_one = sc end end
				f = (pz.livello - first_one) / (next_one - first_one)
				local tier = equip.tier(next_one)
				what = (tier >= equip.TIERS and T.next_look_b or T.next_look):format(next_one, ROMAN[tier])
			end
			kit.text(g, string.upper(what), x + 22, y + 41, 10, KC.MUTE, "start", 1)
			kit.bar(g, x + 20, y + 48, 180, 6, f, KC.STAR)
		else
			kit.text(g, slot.name, x + 22, y + 24, 14, KC.MUTE)
			kit.text(g, string.upper(T.pick_in_armory), x + 22, y + 41, 10, KC.MUTE, "start", 1)
		end
	end
	-- the one action: the armory
	s.action = kit.action(s.right, common.armory, 930, 560, 270, 84, { size = 50 })
	kit.button(s.buttons, s.action, "armeria", { main = true })
end

-- STATISTICHE tab -------------------------------------------------------------------

local function sheet_stats(s)
	local p = s.prof
	local g = s.kg
	-- which matches: a choice, the sand blade behind the active one
	local cx = 440
	for _, gr in ipairs(profile.GROUPS) do
		local nome = kit.upper(profile.GROUP_NAMES[gr])
		local w = #nome * 10 + 34
		local on = s.gruppo == gr
		if on then kit.para(g, cx, 164, w, 32, 10, KC.SAND) end
		kit.text(g, nome, cx + w / 2 + 4, 186, 14, on and KC.INK or kit.with_alpha(KC.SAND, 0.8), "middle")
		kit.zone(g, s.buttons, cx, 158, w + 10, 44, "gruppo:" .. gr)
		cx = cx + w + 12
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
		local x, y = 440 + (i - 1) * 128, 214
		kit.info(g, x, y, 112, 78, i == 2 and KC.HOT or KC.PURPLE)
		kit.text(g, n[1], x + 62, y + 44, 34, KC.SAND, "middle")
		kit.text(g, n[2], x + 60, y + 64, 10, KC.MUTE, "middle", 1)
	end

	-- the stats with their badges: the badge comes from the total of all modes
	local all_f = profile.statistics(p, "tutte")
	local picked_ones = {}
	for _, id in ipairs(p.badge) do picked_ones[id] = true end
	for i, t in ipairs(milestones.WHITELIST) do
		local x, y = 440 + (i - 1) * 4, 312 + (i - 1) * 36
		local val = st[t.id] or 0
		local tot = all_f[t.id] or 0
		local grade = t.thresholds and milestones.grade(t, tot) or 0
		local k = kit.card(g, x, y, 500, 30, grade > 0 and C.GRADI[grade] or KC.LINE)
		kit.text(k.g, kit.upper(t.nome), x + 22, y + 21, 13, KC.SAND)
		kit.text(k.g, kit.upper(thousands(val) .. (t.unit and (" " .. t.unit) or "")), x + 250, y + 21, 14, KC.SAND, "end")
		if t.thresholds then
			if grade > 0 then
				tag.badge({ id = t.id, grado = grade }, x + 274, 720 - (y + 15), 27, s.radice)
				kit.zone(g, s.buttons, x, y - 3, 500, 36, "badge:" .. t.id)
			end
			local next_f, how_much = milestones.next(t, tot)
			kit.bar(k.g, x + 296, y + 11, 96, 8, how_much or 1, KC.HOT)
			local chosen = picked_ones[t.id] and grade > 0
			local dx = chosen and T.next_to_name or
				(next_f and T.next_at:format(thousands(next_f)) or T.badge_grade:format(t.badge, ROMAN[grade]))
			kit.text(k.g, kit.upper(dx), x + 488, y + 20, 9, chosen and KC.HOT_TOP or KC.MUTE, "end", 1)
		else
			kit.text(k.g, kit.upper(T.no_badge), x + 488, y + 20, 9, KC.MUTE, "end", 1)
		end
	end
	kit.text(g, kit.upper(T.badge_hint:format(milestones.SHOWN)), 444 + #milestones.WHITELIST * 4,
		312 + #milestones.WHITELIST * 36 + 14, 11, KC.MUTE, "start", 1)

	-- the damage per weapon: rows to read
	local wx = 1000 + kit.air()
	kit.heading(g, T.damage_by_weapon, wx + 10, 226)
	local armi, tot = {}, 0
	for w, n in pairs(st.armi or {}) do
		armi[#armi + 1] = { w = w, n = n }
		tot = tot + n
	end
	table.sort(armi, function(a, b)
		if a.n ~= b.n then return a.n > b.n end
		return a.w < b.w
	end)
	if #armi == 0 then kit.text(g, kit.upper(T.nothing_yet), wx + 10, 262, 11, KC.MUTE, "start", 1) end
	local first = armi[1] and armi[1].n or 1
	for i, a in ipairs(armi) do
		if i > 7 then break end
		local x, y = wx - (i - 1) * 4, 242 + (i - 1) * 48
		local c = game.SECONDARY[a.w] and KC.STEEL or KC.HOT
		kit.info(g, x, y, 240, 38, c)
		kit.text(g, kit.upper(T.weapons[a.w] or a.w), x + 22, y + 26, 14, KC.SAND)
		kit.bar(g, x + 122, y + 16, 64, 9, a.n / first, c)
		kit.text(g, math.floor(a.n * 100 / tot + 0.5) .. "%", x + 232, y + 27, 14, KC.SAND, "end")
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

local OUTCOME = { V = { T.outcome_won, KC.HOT }, S = { T.outcome_lost, KC.PURPLE }, P = { T.outcome_tie, KC.STEEL } }

-- the rope: your team's lead at every lap, in the box x..x+w, y..y+h
local function rope(g, values, x, y, w, h, my_own, another)
	local cy = y + h / 2
	kit.rect(g, x, cy - 1, w, 2, kit.with_alpha(KC.SAND, 0.25))
	local max = 50
	for _, v in ipairs(values) do max = math.max(max, math.abs(v)) end
	local n = #values
	local function point(i)
		return x + (n > 1 and (i - 1) * w / (n - 1) or w / 2), cy - values[i] / max * (h / 2 - 10)
	end
	for i = 2, n do
		local x1, y1 = point(i - 1)
		local x2, y2 = point(i)
		kit.line(g, x1, y1, x2, y2, 5, values[i] >= 0 and my_own or another)
	end
	for i = 1, n do
		local px, py = point(i)
		local d = ui.disc(px, 720 - py, i == n and 14 or 9, values[i] >= 0 and my_own or another, g.node)
		gui.set_blend_mode(d, gui.BLEND_ALPHA)
	end
end

local function sheet_matches(s)
	local p = s.prof
	local g = s.kg
	if #p.partite == 0 then
		kit.text(g, kit.upper(T.no_matches), 440, 200, 14, KC.MUTE, "start", 0.5)
		return
	end
	s.scelta = math.min(s.scelta or 1, #p.partite)
	-- the last matches: one card each, staggered; closer together when they are many
	local n = #p.partite
	local step = math.min(76, 456 / math.max(1, n - 1))
	local h = math.min(62, step - 8)
	for i, pa in ipairs(p.partite) do
		local x, y = 440 + (i - 1) * 8 * step / 76, 172 + (i - 1) * step
		local e = OUTCOME[pa.esito] or OUTCOME.P
		local k = kit.card(g, x, y, 300, h, e[2], { sel = i == s.scelta })
		kit.text(k.g, e[1], x + 28, y + h / 2 + 7, math.min(24, h * 0.5), pa.esito == "S" and KC.MUTE or KC.SAND)
		local map_name = maps.get(pa.mappa or "")
		kit.text(k.g, kit.upper(profile.GROUP_NAMES[pa.gruppo] or pa.gruppo or ""), x + 272, y + h / 2 - 4, 13, KC.SAND, "end", 1)
		kit.text(k.g, kit.upper((map_name and (map_name.name .. " · ") or "") .. when(pa.quando)), x + 288, y + h / 2 + 15, 11,
			KC.MUTE, "end", 1)
		kit.zone(g, s.buttons, x, y - 4, 300, step, "partita:" .. i)
	end

	-- the chosen match: how it went
	local pa = p.partite[s.scelta]
	local me = pa.giocatori[pa.me or 1] or {}
	local my_own = C.SQUADRA[me.squadra or 1] or C.SQUADRA[1]
	local another = C.SQUADRA[2]
	for _, pl in ipairs(pa.giocatori or {}) do
		if pl.squadra ~= me.squadra then another = C.SQUADRA[pl.squadra] or another end
	end
	kit.heading(g, T.round_by_round, 810, 186)
	kit.info(g, 800, 198, 440, 190, KC.PURPLE)
	rope(g, pa.fune or { 0 }, 836, 216, 330, 154, my_own, another)
	kit.text(g, thousands(pa.punti[1] or 0), 1228, 282, 22, my_own, "end")
	kit.text(g, thousands(pa.punti[2] or 0), 1228, 320, 22, another, "end")
	-- the moments: a tap and you see it again from there
	local ok = s.replay_ok and s.replay_ok(pa.numero)
	local moments = pa.moments or {}
	kit.heading(g, T.moments, 806, 424)
	if #moments == 0 then kit.text(g, kit.upper(T.no_moments), 806, 462, 11, KC.MUTE, "start", 1) end
	for i, m in ipairs(moments) do
		if i > 3 then break end
		local x, y = 800 - (i - 1) * 4, 438 + (i - 1) * 46
		local pl = kit.plate(g, x, y, 300, 36, ok and KC.ROSE or KC.LINE, { sk = 10, d = 4 })
		kit.text(pl.g, kit.upper(m.giro .. " · " .. m.testo), x + 24, y + 24, 14, ok and KC.SAND or KC.MUTE)
		if ok then kit.button(s.buttons, pl, "momento:" .. i) end
	end
	-- who was there: tapping them, their tag from that time
	for k, pl in ipairs(pa.giocatori or {}) do
		if k > 4 then break end
		local y = 446 + (k - 1) * 30
		score.face(s.radice, 1134, 720 - y, 24, C.SQUADRA[pl.squadra] or C.LIGHT, pl.look)
		kit.text(g, kit.upper(pl.nome or "?"), 1152, y + 5, 12, KC.SAND, "start", 0.5)
		kit.zone(g, s.buttons, 1118, y - 15, 130, 30, "giocatore:" .. k)
	end
	-- the one action: see it again
	s.action = kit.action(s.right, common.replay, 930, 560, 270, 84, { size = 54, off = not ok,
		sub = not ok and kit.upper(pa.online and T.replay_local_only or T.replay_missing) or nil })
	kit.button(s.buttons, s.action, "rivedi", { main = true, spento = not ok })
end

-- Screen ----------------------------------------------------------------------------

local function build(s)
	if s.radice then gui.delete_node(s.radice) end
	if s.head then kit.header_delete(s.head) end
	if s.right then gui.delete_node(s.right.node) end
	if s.low then gui.delete_node(s.low.node) end
	s.buttons, s.figure, s.action = {}, nil, nil
	local p = s.prof
	-- the frame of the devil's place (ui/kit.lua): the title written as the
	-- logo, the way back at the bottom left, the wallet, the tabs on their rail
	s.head = kit.header(s.buttons, T.title, KC.PURPLE, "indietro", common.home)
	s.wallet = coins.wallet(p.scaglie or 0, p.ossidiana or 0, kit.group(s.head.top_right, 1110, 44).node, 0, 0)
	s.right = kit.anchor(1280, 720, gui.ANCHOR_RIGHT, gui.ANCHOR_BOTTOM)
	s.low = kit.anchor(0, 720, gui.ANCHOR_LEFT, gui.ANCHOR_BOTTOM)
	local active = s.scheda == "sigilli" and 2 or s.scheda == "statistiche" and 3 or s.scheda == "partite" and 4 or 1
	s.radice = ui.root()
	s.kg = { node = s.radice, ox = 0, oy = 720 }
	kit.tabs(s.kg, s.buttons, 440, 104, { { T.tab_sheet, "scheda:scheda" }, { T.tab_seals, "scheda:sigilli" },
		{ common.stats, "scheda:statistiche" }, { T.tab_matches, "scheda:partite" } }, active, KC.PURPLE)
	M.devil(s)
	if s.scheda == "scheda" or s.scheda == "sigilli" then M.loadouts(s) end
	if s.scheda == "sigilli" then
		seals.build(s)
	elseif s.scheda == "statistiche" then
		sheet_stats(s)
	elseif s.scheda == "partite" then
		sheet_matches(s)
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
	-- the backdrop (ui/kit.lua)
	s.scene = kit.scene(M.devil_x(), M.DEVIL_Y, { accent = KC.PURPLE })
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
	if seals.run(s, kind, x) then
		-- the SIGILLI's actions (menu/seals.lua)
	elseif kind == "scheda" then
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
	kit.header_delete(s.head)
	gui.delete_node(s.right.node)
	gui.delete_node(s.low.node)
	gui.delete_node(s.radice)
	kit.scene_drop(s.scene)
end

return M
