-- The PROFILO (Figma "RIORGANIZZAZIONE MENU · 14 nov", Consigliata/8 and /9;
-- Sergio, 14 Nov): it opens from the round at the top left of the home. The
-- title is your name, under it your level. Two tabs:
--   STATISTICHE         four big numbers (won, best streak, stars, lost), the
--                       mode as chips, the stats as rows with their badge
--                       (tapping a row puts its badge next to your name), on
--                       the right the damage per weapon
--   CRONOLOGIA PARTITE  the last matches as rows: outcome, mode and map, who was
--                       there (tapping a face shows their tag from that time),
--                       points, ranking (the server doesn't keep it yet: a
--                       placeholder), when, RIVEDI; tapping a row opens under
--                       it how it went lap by lap and its moments (a tap: the
--                       replay from there)
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
local maps = require "sim.maps"
local profile = require "menu.profile"
local milestones = require "menu.milestones"
local tag = require "ui.tag_card"
local T = require("lang.text").profile_tabs
local TH = require("lang.text").home
local common = require("lang.text").common

local M = {}

local C = ui.C
local KC = kit.C
local TOUCH = hash("touch")
local ROMAN = { "I", "II", "III", "IV" }
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
	-- four big numbers, each in its panel
	local big = {
		{ thousands(won), T.won, KC.HOT },
		{ thousands(st.serie or 0), T.best_streak, KC.SAND },
		{ thousands(profile.total_stars(p)), T.stars, KC.SAND },
		{ thousands(matches - won), T.lost, KC.STEEL },
	}
	for i, b in ipairs(big) do
		local x = 36 + (i - 1) * 200
		kit.panel(kit.group(g, x + 93, 172).node, 186, 112)
		kit.text(g, b[1], x + 93, 178, 44, b[3], "middle")
		kit.text(g, b[2], x + 93, 206, 14, KC.MUTE, "middle", 1)
	end
	-- which matches
	local list, active = {}, 1
	for i, gr in ipairs(MODES) do
		list[i] = { kit.upper(profile.GROUP_NAMES[gr]), "gruppo:" .. gr }
		if gr == s.gruppo then active = i end
	end
	require("menu.gear_ui").chips(s, g, 36, 240, list, active)

	-- the stats with their badges: the badge comes from the total of all modes
	local all = profile.statistics(p, "tutte")
	local picked = {}
	for _, id in ipairs(p.badge) do picked[id] = true end
	local step = 32
	for i, t in ipairs(milestones.WHITELIST) do
		local y = 288 + (i - 1) * step
		local tot = all[t.id] or 0
		local grade = t.thresholds and milestones.grade(t, tot) or 0
		local chosen = picked[t.id] and grade > 0
		kit.strip(g, chosen and "riga_oro" or "riga_scura", 36, y, 760, 29)
		local ink = chosen and KC.INK or KC.SAND
		kit.text(g, kit.upper(t.nome), 52, y + 21, 16, ink)
		kit.text(g, kit.upper(thousands(st[t.id] or 0) .. (t.unit and (" " .. t.unit) or "")), 640, y + 21, 18,
			chosen and KC.INK or KC.HOT, "end")
		if grade > 0 then
			-- the badge's plate (iron, bronze, silver, gold) with its grade
			kit.pic(g, "badge_" .. grade, 660, y + 1, 110, 110 * (grade == 4 and 90 or 68) / (grade == 4 and 273 or 268))
			kit.text(g, T.badge_pill:format(ROMAN[grade]), 715, y + 20, 13, grade >= 3 and KC.INK or KC.SAND, "middle", 0.5)
			kit.zone(g, s.buttons, 36, y - 2, 760, step, "badge:" .. t.id)
		elseif t.thresholds then
			local next_at = milestones.next(t, tot)
			kit.text(g, kit.upper(T.next_at:format(thousands(next_at))), 715, y + 20, 11, KC.MUTE, "middle", 0.5)
		end
	end
	kit.text(g, kit.upper(T.badge_hint:format(milestones.SHOWN)), 40, 288 + #milestones.WHITELIST * step + 12, 12, KC.MUTE, "start", 1)

	-- on the right, the damage per weapon
	local r = s.rt
	local x, w = 830, 426
	kit.panel(kit.group(r, x + w / 2, 351).node, w, 470)
	kit.text(r, T.damage_by_weapon, x + w / 2, 150, 20, KC.HOT, "middle", 1)
	local weapons = {}
	for id, n in pairs(st.armi or {}) do weapons[#weapons + 1] = { w = id, n = n } end
	table.sort(weapons, function(a, b)
		if a.n ~= b.n then return a.n > b.n end
		return a.w < b.w
	end)
	if #weapons == 0 then
		kit.text(r, kit.upper(T.nothing_yet), x + w / 2, 340, 14, KC.MUTE, "middle", 1)
	end
	local first = weapons[1] and weapons[1].n or 1
	for i, a in ipairs(weapons) do
		if i > 6 then break end
		local y = 186 + (i - 1) * 62
		kit.text(r, kit.upper(T.weapons[a.w] or a.w), x + 32, y + 16, 16, KC.SAND)
		kit.text(r, thousands(a.n), x + w - 32, y + 16, 16, KC.MUTE, "end")
		kit.strip(r, "riga_scura", x + 32, y + 24, w - 64, 18)
		kit.strip(r, game.SECONDARY[a.w] and "barra_gelo" or "barra_brace", x + 34, y + 26, math.max(18, (w - 68) * a.n / first), 14)
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
-- the rows the Figma shows (the profile keeps more, for the replays)
local ROWS = 6
-- the open match shows under its row how it went and its moments, without a box
-- of their own (Sergio, 15 Nov: the features stay, even where Figma has no room)
local DETAIL = 132
local BOTTOM = 598

-- the rope: your team's lead at every lap, in the box x..x+w, y..y+h
local function rope(g, values, x, y, w, h, my_own, another)
	local cy = y + h / 2
	local max = 50
	for _, v in ipairs(values) do max = math.max(max, math.abs(v)) end
	local n = #values
	local function point(i)
		return x + (n > 1 and (i - 1) * w / (n - 1) or w / 2), cy - values[i] / max * (h / 2 - 8)
	end
	for i = 2, n do
		local x1, y1 = point(i - 1)
		local x2, y2 = point(i)
		kit.line(g, x1, y1, x2, y2, 5, values[i] >= 0 and my_own or another)
	end
	for i = 1, n do
		local px, py = point(i)
		local d = ui.disc(px - g.ox, g.oy - py, i == n and 16 or 10, values[i] >= 0 and my_own or another, g.node)
		gui.set_blend_mode(d, gui.BLEND_ALPHA)
	end
end

-- under the open row: the rope on the left, the moments beside it
local function detail(s, g, pa, x, y, w)
	local me = (pa.giocatori or {})[pa.me or 1] or {}
	local my_own = C.SQUADRA[me.squadra or 1] or C.SQUADRA[1]
	local another = C.SQUADRA[2]
	for _, pl in ipairs(pa.giocatori or {}) do
		if pl.squadra ~= me.squadra then another = C.SQUADRA[pl.squadra] or another end
	end
	kit.text(g, kit.upper(T.round_by_round), x + 40, y + 22, 13, KC.MUTE, "start", 1)
	rope(g, pa.fune or { 0 }, x + 46, y + 32, 360, 86, my_own, another)
	local mx = x + 470
	local ok = s.replay_ok and s.replay_ok(pa.numero)
	local moments = pa.moments or {}
	kit.text(g, kit.upper(T.moments), mx, y + 22, 13, KC.MUTE, "start", 1)
	if #moments == 0 then kit.text(g, kit.upper(T.no_moments), mx, y + 62, 14, KC.MUTE, "start", 1) end
	local mw = math.min(300, (w - 470 - 40 - 2 * 16) / 3)
	for i, m in ipairs(moments) do
		if i > 3 then break end
		local px = mx + (i - 1) * (mw + 16)
		local pl = kit.card(g, px, y + 40, mw, 52, KC.ROSE, { off = not ok })
		fit(kit.text(pl.g, kit.upper(m.giro .. " · " .. m.testo), px + 20, y + 72, 15, ok and KC.SAND or KC.MUTE), mw - 36)
		kit.button(s.buttons, pl, "momento:" .. i, { spento = not ok })
	end
end

local function sheet_matches(s)
	local p = s.prof
	local g = s.left
	if #p.partite == 0 then
		kit.text(g, kit.upper(T.no_matches), 36, 160, 20, KC.MUTE, "start", 0.5)
		return
	end
	-- the row goes across the whole screen; the middle columns follow its room
	local w = screen.width() - 72
	local mid = (w - 1220) / 2
	local y = 112
	for i, pa in ipairs(p.partite) do
		if i > ROWS or y + 70 > BOTTOM then break end
		local x = 36
		local open = i == s.open
		local e = OUTCOME[pa.esito] or OUTCOME.P
		kit.panel(kit.group(g, x + w / 2, y + 35).node, w, 70, open and "pannello_caldo" or "pannello")
		-- the whole row opens and closes (under the faces and RIVEDI, which are their own)
		kit.zone(g, s.buttons, x, y, w, 70, "partita:" .. i)
		-- the cap on the left: ember if won, ice if not
		kit.pic(g, pa.esito == "V" and "bordino_brace" or "bordino_gelo", x - 10, y + 6, 58 * 88 / 140, 58)
		kit.text(g, e[1], x + 40, y + 34, 26, e[2])
		local map = maps.get(pa.mappa or "")
		fit(kit.text(g, kit.upper((profile.GROUP_NAMES[pa.gruppo] or pa.gruppo or "") .. (map and (" · " .. map.name) or "")),
			x + 41, y + 56, 13, KC.MUTE, "start", 0.5), 250)
		-- who was there
		for k, pl in ipairs(pa.giocatori or {}) do
			if k > 4 then break end
			local fx = x + 318 + mid * 0.4 + (k - 1) * 52
			score.face(g.node, fx - g.ox, g.oy - (y + 35), 46, C.SQUADRA[pl.squadra] or C.LIGHT, pl.look)
			kit.zone(g, s.buttons, fx - 26, y + 6, 52, 58, "giocatore:" .. i .. ":" .. k)
		end
		local px = x + 654 + mid
		kit.text(g, thousands(pa.punti and pa.punti[1] or 0), px, y + 38, 30, KC.SAND, "end")
		kit.text(g, kit.upper(T.points), px, y + 58, 12, KC.MUTE, "end", 1)
		-- the ranking: not kept yet (placeholder until the server has it)
		kit.text(g, "–", px + 30, y + 38, 24, KC.MUTE)
		kit.text(g, kit.upper(T.ranking), px + 30, y + 58, 12, KC.MUTE, "start", 1)
		kit.text(g, kit.upper(when(pa.quando)), x + 844 + mid * 1.4, y + 41, 16, KC.MUTE)
		-- RIVEDI, when the replay is on this phone
		local ok = s.replay_ok and s.replay_ok(pa.numero)
		local b = kit.plate(g, x + w - 168, y + 14, 140, 42, KC.HOT, { sk = 0, fill = KC.SAND })
		kit.text(b.g, common.replay, x + w - 98, y + 43, 20, ok and KC.INK or kit.with_alpha(KC.INK, 0.4), "middle")
		kit.button(s.buttons, b, "rivedi:" .. i, { spento = not ok })
		y = y + 80
		if open then
			detail(s, g, pa, x, y - 6, w)
			y = y + DETAIL
		end
	end
end

-- Screen ----------------------------------------------------------------------------

local function build(s)
	if s.head then kit.header_delete(s.head) end
	for _, k in ipairs({ "left", "rt", "veil_g" }) do
		if s[k] then gui.delete_node(s[k].node); s[k] = nil end
	end
	s.buttons = {}
	local p = s.prof
	-- the title is your name; a long one shrinks before the tabs
	s.head = kit.header(s.buttons, TH.player, KC.HOT, "indietro", common.home)
	local tw = kit.width(s.head.title[2])
	if tw > 262 then
		for _, n in ipairs(s.head.title) do gui.set_scale(n, gui.get_scale(n) * (262 / tw)) end
	end
	kit.text(s.head.top_left, kit.upper(T.level:format(p.livello or 1)), 36, 100, 15, KC.MUTE, "start", 1)
	s.wallet = coins.wallet(p.scaglie or 0, p.ossidiana or 0, kit.group(s.head.top_right, 1110, 44).node, 0, 0)
	kit.tabs(s.head.top_left, s.buttons, 320, 28, { { common.stats, "scheda:statistiche" }, { T.tab_matches, "scheda:partite" } },
		s.scheda == "partite" and 2 or 1, KC.PURPLE, true)
	s.left = kit.anchor(0, 0, gui.ANCHOR_LEFT)
	s.rt = kit.anchor(1280, 0, gui.ANCHOR_RIGHT)
	if s.scheda == "partite" then sheet_matches(s) else sheet_stats(s) end
	if s.aperto then
		-- a player's tag from a past match, on top of everything
		s.veil_g = kit.anchor(0, 0)
		kit.rect(s.veil_g, -2560, -1440, 1280 * 5, 720 * 5, kit.with_alpha(C.BOTTOM, 0.82))
		local v = s.aperto
		v.verso = 1
		s.carta = tag.new(v, 640, 360 + tag.TALL({ portrait = true }) / 2, { portrait = true, tu = v.tu }, s.veil_g.node)
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
	s.scene = kit.scene(250, 420, { accent = KC.PURPLE, bg = true })
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
	kit.header_delete(s.head)
	for _, k in ipairs({ "left", "rt", "veil_g" }) do
		if s[k] then gui.delete_node(s[k].node) end
	end
	kit.scene_drop(s.scene)
end

return M
