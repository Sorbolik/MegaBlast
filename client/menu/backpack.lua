-- The ZAINO (Figma "RIORGANIZZAZIONE MENU · 14 nov", Consigliata/2 and /3;
-- Sergio, 14 Nov): it opens from the apprentice in the home. Two tabs:
--   INVENTARIO  on the left the loadouts and the apprentice, beside it the column of
--               what you wear (small piece cards); in the middle every piece you
--               own as a big card with its rows (two in a row, the list scrolls),
--               filtered by slot; on the right the stats (with "a → b" for the piece
--               tried on); at the bottom how it works and INDOSSA. Holding a card
--               opens POTENZIA (menu/bench.lua)
--   SIGILLI     the loadouts of the Sigilli (apart from the pieces'), the three
--               paths as rows of pips with a round at each threshold, the open
--               one's forks and their two powers under them; on the right the
--               short column of the stats (VEDI TUTTE: the sheet); SALVA
-- Rebuilt at every tap, like the armory.
--
--   local s = zaino.new(prof, tab, color)        -- tab: "inventario" (default) or "sigilli"
--   zaino.update(s, dt)
--   zaino.on_input(s, action_id, action) -> "indietro" or nil
--   zaino.destroy(s)

local ui = require "ui.ui"
local kit = require "ui.kit"
local coins = require "ui.coins"
local screen = require "ui.screen"
local equip = require "sim.gear"
local skills = require "sim.skills"
local scoria = require "battle.scoria"
local profile = require "menu.profile"
local wallet = require "sim.wallet"
local progress = require "sim.progress"
local gear_ui = require "menu.gear_ui"
local outline = require "menu.outline"
local bench = require "menu.bench"
local card_list = require "menu.card_list"
local sheen = require "ui.sheen"
local T = require("lang.text").backpack
local TG = require("lang.text").gear_ui
local TP = require("lang.text").pieces
local common = require("lang.text").common

local M = {}

local KC = kit.C
-- the paths of the Sigilli: their color (Figma: movement ice, defense mint, arsenal ember)
local PATH_COLOR = { wings = KC.STEEL, armor = KC.MINT, forge = KC.HOT_BOTTOM }

local function copy(t)
	if type(t) ~= "table" then return t end
	local o = {}
	for k, v in pairs(t) do o[k] = copy(v) end
	return o
end

local function same(a, b)
	if type(a) ~= "table" or type(b) ~= "table" then return a == b end
	for k, v in pairs(a) do if not same(v, b[k]) then return false end end
	for k, v in pairs(b) do if a[k] == nil then return false end end
	return true
end

-- the pieces you own, family after family, slot after slot (the filters on)
local function owned(s)
	local out = {}
	for _, f in ipairs(equip.SETS) do
		for _, sl in ipairs(equip.SLOTS) do
			if wallet.owns(s.prof, f.id, sl.id) and (not s.slot or s.slot == sl.id) then
				out[#out + 1] = { f.id, sl.id }
			end
		end
	end
	return out
end

-- INVENTARIO ------------------------------------------------------------------------

-- The pieces as big cards with their rows inside (Sergio, 27 Nov), two in a row in a
-- window that scrolls (menu/card_list.lua): the ones you wear first, under them a gold
-- line, then the others. No piece is chosen when you come in: a tap tries one on (the
-- apprentice wears it, its stats compared), a second tap takes it off; holding it
-- opens POTENZIA (menu/bench.lua, the window); INDOSSA keeps it on.
local VIEW = { x = 418, y = 146, w = 612, h = 460 }
local COLS, TOP, GAP = { 430, 726 }, 152, 10
-- how long a finger stays on a card to open POTENZIA (seconds)
local HOLD = 0.52
-- the column of what you wear: x, the first top, the size, the gap (choice B)
local TOK_X, TOK_Y, TOK_S, TOK_GAP = 336, 180, 66, 12

local function same_piece(a, b) return a and b and a[1] == b[1] and a[2] == b[2] end

local function inventory(s)
	local p = s.prof
	local a = profile.active_loadout(p)
	gear_ui.loadouts(s, s.left, 36, 96, p.is_active, "assetto", T.loadout)
	-- the piece tried on: on the apprentice, in its place in the column, in the stats
	local try = s.sel and a.gear[s.sel[2]] ~= s.sel[1] and s.sel or nil
	local gear, look = gear_ui.tried(s, a, try)
	s.gear_on = gear
	gear_ui.devil(s, s.left, 215, 600, 395, look)
	gear_ui.light_try(s, try)
	s.sheen = sheen.new(s.mid, 330, 1050)
	s.tokens = gear_ui.tokens(s, s.left, a, try, TOK_X, TOK_Y, TOK_S, TOK_GAP, s.sheen)
	if try then
		kit.text(s.left, kit.upper(T.trying), 24, 184, 20, KC.HOT, "start", 0.5)
		kit.text(s.left, kit.upper(T.trying_line), 24, 206, 16, KC.SAND, "start", 0.5)
	end
	local a2
	if try then
		a2 = copy(a)
		a2.gear[try[2]] = try[1]
	end
	local g = s.mid
	if s.sheet then
		gear_ui.sheet(s, g, a, a2, TG.back_to_pieces)
	else
		-- the filters: the slots as the symbols of their type (Sergio, 19 Nov)
		local list = { { T.all, "filtro:" } }
		for _, sl in ipairs(equip.SLOTS) do list[#list + 1] = { sl.name, "filtro:" .. sl.id, slot = sl.id } end
		local active = 1
		for i, sl in ipairs(equip.SLOTS) do if s.slot == sl.id then active = i + 1 end end
		gear_ui.chips(s, g, 430, 100, list, active, 578)

		local worn, others = {}, {}
		for _, it in ipairs(owned(s)) do
			if a.gear[it[2]] == it[1] then worn[#worn + 1] = it else others[#others + 1] = it end
		end
		s.list = card_list.new(g, VIEW, s.scroll)
		s.cards = {}
		local y = TOP
		local function place(items)
			for i, it in ipairs(items) do
				local x, cy = COLS[(i - 1) % 2 + 1], y + math.floor((i - 1) / 2) * (gear_ui.CARD_H + GAP)
				local set, slot = it[1], it[2]
				local level = wallet.level(p, set, slot)
				local cg = card_list.item(s.list, x, cy, gear_ui.CARD_H)
				local card, icon = gear_ui.card(cg, x, cy, { set = set, slot = slot, level = level, lit = wallet.sign(p, set, slot),
					worn = a.gear[slot] == set, sel = same_piece(s.sel, it), sheen = s.sheen })
				if same_piece(s.sel, it) then gui.set_position(card.node, gui.get_position(card.node) + vmath.vector3(0, 5, 0)) end
				local action = "pezzo:" .. set .. ":" .. slot
				card_list.zone(s.list, s.buttons, x, cy, gear_ui.CARD_W, gear_ui.CARD_H, action)
				s.cards[action] = { node = card.node, icon = icon }
			end
			if #items > 0 then y = y + math.ceil(#items / 2) * (gear_ui.CARD_H + GAP) - GAP end
		end
		place(worn)
		if #worn > 0 and #others > 0 then
			-- the gold line under what you wear, a dot at each end
			local ly = y + 12
			local lg = card_list.item(s.list, COLS[1], ly - 4, 8)
			kit.line(lg, COLS[1], ly, COLS[2] + gear_ui.CARD_W, ly, 2, KC.HOT)
			kit.dot(lg, COLS[1], ly, 8, KC.HOT)
			kit.dot(lg, COLS[2] + gear_ui.CARD_W, ly, 8, KC.HOT)
			y = ly + 2 + 12
		elseif #worn > 0 then
			y = y + GAP
		end
		place(others)
		if #worn + #others == 0 then
			kit.text(g, kit.upper(T.nothing), VIEW.x + VIEW.w / 2, 300, 18, KC.MUTE, "middle", 1)
		end
		card_list.done(s.list, g, y)
		gear_ui.stats_short(s, s.rt, 1040, 106, 210, a, a2)
	end

	-- at the bottom: how it works, and INDOSSA (lit only with a piece tried on)
	local room = screen.width() - (1280 - 980) - 24 - 140
	kit.foot_text(s.low, T.hint_try, 140, 652, 21, KC.SAND, room)
	kit.foot_text(s.low, T.hint_hold, 140, 680, 17, KC.MUTE, room)
	s.action = kit.action(s.right, T.wear, 980, 628, 276, 80, { icon = "az_indossa", size = 44, off = not try })
	kit.button(s.buttons, s.action, "indossa", { main = true, spento = not try })
	-- POTENZIA: the window over everything, its buttons the only ones
	if s.modal then
		s.buttons = {}
		s.over = kit.anchor(640, 360)
		bench.window(s, s.over, s.modal)
	end
end

-- SIGILLI ---------------------------------------------------------------------------

-- The Sigilli as in the proposal chosen by Sergio (15 Nov 22:48, "Sigilli A col
-- bivio"): the three paths as rows with − and +, a narrow pip for every point
-- (the board's shape) and what one point gives; under them the open path runs
-- left to right, and at every step it forks: up to one power, down to the other,
-- the fire only in the branch chosen. Pieces of WB-062; the branches are drawn
-- here (Codex's ones are too wide for five steps in a row).
-- Sergio, 16 Nov: a row is chosen by a tap anywhere on it; the pips are only to
-- look at (a point goes in or out with + and − alone); every fifth pip is the
-- round of its step, with the same number as in the fork under; on the right the
-- short column of the stats (the same of the inventory), which shows what the
-- points not saved yet change (VEDI TUTTE: the sheet). The block goes from the
-- apprentice to the stats: wider on a wide phone.
local SEAL_X = 312                  -- the left of the block, from the left edge
local STATS_W = 210                 -- the column of the stats (as in the inventory)
local BLOCK_MAX = 900
local ROW_Y, ROW_H = 146, 68
local LINE_Y = 478
local STEP_DISC = 26

-- a branch of the fork: from the node up (or down) and right to the power,
-- an ink line with the color inside, round at the bends
local function branch(g, x0, y0, y1, x1, color)
	for _, w in ipairs({ { 14, KC.INK }, { 8, color } }) do
		kit.line(g, x0, y0, x0, y1, w[1], w[2])
		kit.line(g, x0, y1, x1, y1, w[1], w[2])
		kit.dot(g, x0, y1, w[1], w[2])
	end
end

-- "+4.8%": what the points of a path give now (the end of its description)
local function gain(path, n)
	local tail = path.per_point_desc:match("(%S*%%s%S*)$") or "+%s"
	local v = string.format("%.1f", n * path.shown):gsub("%.0$", "")
	return tail:format(v)
end

-- a text never wider than max (a long one shrinks)
local function fit(n, max)
	local nw = kit.width(n)
	if nw > max then gui.set_scale(n, gui.get_scale(n) * (max / nw)) end
	return n
end

local function seals_tab(s)
	local p = s.prof
	local t = s.draft
	gear_ui.loadouts(s, s.left, 36, 96, p.seal_active or p.is_active, "sigilli", T.seal_loadout)
	gear_ui.devil(s, s.left, 176, 600, 330)
	local a = profile.active_loadout(p)
	local changed = not same(t, a.tree)
	local a2 = changed and { gear = a.gear, tree = t, variant = a.variant } or nil
	local pts = skills.points(p.livello)
	local free = pts - skills.spent(t)
	if s.sheet then
		gear_ui.sheet(s, s.mid, a, a2, T.back_to_seals)
	else
		-- the block, in the left edge's coordinates: from the apprentice to the stats
		local g = s.left
		local wide = screen.width()
		local room = wide - STATS_W - 2 * gear_ui.STAT_PAD - 24 - SEAL_X
		local bw = math.min(room, BLOCK_MAX)
		local x0 = SEAL_X + (room - bw) / 2
		kit.panel(kit.group(g, x0 + bw / 2, 345).node, bw, 514)
		gear_ui.stats_short(s, s.rt, 1040, 106, STATS_W, a, a2)
		-- the free points, a flame each (spent: the grey flame), and how many are used
		local title = kit.text(g, T.free, x0 + 18, 126, 24, KC.HOT, "start", 1)
		local fx = x0 + 18 + kit.width(title) + 12
		for i = 1, math.min(free, 8) do
			kit.piece(g, "punto_libero", fx + (i - 1) * 26 + 11, 116, 30)
		end
		if free > 8 then kit.text(g, "+" .. (free - 8), fx + 8 * 26 + 4, 126, 20, KC.HOT, "start") end
		if free == 0 then kit.piece(g, "punto_speso", fx + 11, 116, 30) end
		kit.text(g, T.used:format(skills.spent(t), pts), fx + math.max(1, math.min(free, 8)) * 26 + (free > 8 and 40 or 10), 125, 18, KC.MUTE, "start")

		-- the three paths
		local open_path = s.path or skills.to_choose(t) or skills.PATHS[1].id
		local minus_x, plus_x = x0 + 160, x0 + bw - 36
		local pip_x, pip_end = x0 + 192, x0 + bw - 70
		-- the pips as big as the row lets them (the board's: 13 wide, 4 apart), the
		-- room left over after each step's round
		local room_p = pip_end - pip_x
		local pw, gap, disc
		for try = 15, 8, -1 do
			pw, gap = try, math.max(3, math.floor(try * 0.32))
			disc = math.max(STEP_DISC, math.floor(try * 24 / 13) + 2)
			if 20 * pw + skills.STEPS * disc + 24 * gap <= room_p then break end
		end
		local ph = pw * 24 / 13
		local after = math.max(0, math.min(18, math.floor((room_p - 20 * pw - skills.STEPS * disc - 24 * gap) / (skills.STEPS - 1))))
		for i, path in ipairs(skills.PATHS) do
			local color = PATH_COLOR[path.id] or KC.SAND
			local y = ROW_Y + (i - 1) * ROW_H
			local on = path.id == open_path
			local v = skills.spent(t, path.id)
			if on then kit.card(g, x0 + 6, y, bw - 12, 62, KC.ROSE, { sel = true }) end
			-- a tap anywhere on the row opens its path (− and +, made after, stay their own)
			kit.zone(g, s.buttons, x0 + 6, y, bw - 12, 62, "via:" .. path.id)
			kit.text(g, path.name, x0 + 22, y + 26, 24, on and color or kit.with_alpha(color, 0.75), "start", 1)
			kit.text(g, T.of:format(v, skills.PATH_MAX), x0 + 22, y + 52, 18, KC.SAND, "start")
			-- − and +: one point at a time, the only way to move a point
			local can_less, can_more = skills.can_remove(t, path.id), skills.can_add(t, path.id, pts)
			kit.piece(g, can_less and "tasto_meno" or "tasto_meno_spento", minus_x, y + 24, 44)
			kit.zone(g, s.buttons, minus_x - 27, y - 2, 54, 58, "meno:" .. path.id)
			kit.piece(g, can_more and "tasto_piu" or "tasto_piu_spento", plus_x, y + 24, 44)
			kit.zone(g, s.buttons, plus_x - 28, y - 2, 60, 58, "piu:" .. path.id)
			-- a pip for every point; the fifth, the tenth... are the round of their
			-- step, with its number: there the path forks
			local px = pip_x
			for k = 1, skills.PATH_MAX do
				local got = k <= v
				if k % skills.STEP == 0 then
					kit.piece(g, got and "bivio_nodo_acceso" or "bivio_nodo_spento", px + disc / 2, y + 17, disc)
					kit.text(g, tostring(k), px + disc / 2, y + 23, 16, got and KC.INK or KC.SAND, "middle")
					px = px + disc + gap + after
				else
					local pip = kit.piece(g, "tacca_sigillo", px + pw / 2, y + 17, ph)
					gui.set_color(pip, got and color or KC.TRACK)
					px = px + pw + gap
				end
			end
			fit(kit.text(g, kit.upper(T.per_point:format(path.per_point_desc:format(gain(path, 1):match("[%d.]+")), gain(path, v))),
				pip_x, y + 52, 16, KC.MUTE, "start", 0.5), plus_x - 28 - pip_x)
		end

		-- the open path: its steps and their two powers
		local path = skills.BY_ID[open_path]
		local v = skills.spent(t, path.id)
		local step_w = (bw - 24) / skills.STEPS
		local card_w = step_w - 38
		local rail = x0 + 6
		local node_x = function(k) return x0 + 28 + (k - 1) * step_w end
		-- the rail of the points: iron all along, lit as far as the points go
		local last = node_x(skills.STEPS)
		kit.strip(g, "bivio_binario_spento", rail, LINE_Y - 10, last - rail, 20)
		local lit = math.min(last, rail + (node_x(1) - rail) * math.min(v, skills.STEP) / skills.STEP
			+ math.max(0, v - skills.STEP) / skills.STEP * step_w)
		if v > 0 then kit.strip(g, "bivio_binario_acceso", rail, LINE_Y - 10, math.max(30, lit - rail), 20) end
		for k = 1, skills.STEPS do
			local cx = node_x(k)
			local got = v >= k * skills.STEP
			local pick = skills.pick(t, path.id, k)
			local card_x = cx + 22
			for which = 1, 2 do
				local chosen = got and pick == which
				local cy = which == 1 and 416 or 540
				branch(g, cx, LINE_Y + (which == 1 and -12 or 12), cy, card_x + 8,
					chosen and KC.HOT_BOTTOM or got and KC.LINE or kit.hex("2b2530"))
				local look = chosen and "acceso" or got and "spento" or "chiuso"
				kit.drawn_plate(g, "bivio_piastra_" .. look, card_x, cy - 44, card_w, 88)
				local ink = chosen and KC.INK or got and (pick and kit.with_alpha(KC.SAND, 0.75) or KC.HOT_TOP)
					or kit.with_alpha(KC.MUTE, 0.8)
				-- the power's name, on the lines it takes to stay inside its plate
				local inside = card_w - (card_w > 120 and 28 or 16)
				local lines = kit.wrap(g, kit.upper(path.steps[k][which].name), 17, inside)
				local ty = cy + 6 - (#lines - 1) * 9.5
				for li, line in ipairs(lines) do
					fit(kit.text(g, line, card_x + card_w / 2, ty + (li - 1) * 19, 17, ink, "middle"), inside)
				end
				if got then kit.zone(g, s.buttons, card_x, cy - 44, card_w, 88, "potere:" .. path.id .. ":" .. k .. ":" .. which) end
			end
			kit.piece(g, got and "bivio_nodo_acceso" or "bivio_nodo_spento", cx, LINE_Y, 40)
			kit.text(g, tostring(k * skills.STEP), cx, LINE_Y + 7, 18, got and KC.INK or KC.SAND, "middle")
			if got and not pick then
				-- a step reached and not chosen yet
				local d = ui.disc(cx + 18 - g.ox, g.oy - (LINE_Y - 18), 20, KC.RED, g.node)
				gui.set_blend_mode(d, gui.BLEND_ALPHA)
				kit.text(g, "!", cx + 18, LINE_Y - 11, 16, KC.SAND, "middle")
			end
		end
	end
	-- at the bottom: the power you touched (or the first to choose), and the other one
	local fp, fk, fw = s.focus and s.focus[1], s.focus and s.focus[2], s.focus and s.focus[3]
	if not fp then fp, fk = skills.to_choose(t) end
	local fpath = fp and skills.BY_ID[fp]
	local room = 800
	if fpath then
		local pick = fw or skills.pick(t, fp, fk)
		local two = fpath.steps[fk]
		if pick then
			local other = two[3 - pick]
			-- (in the queue the lines go on two, left of the pill: all a little higher)
			local q = kit.in_queue and -10 or 0
			kit.text(s.low, kit.upper(two[pick].name), 140, 648 + q, 26, KC.SAND)
			local lines = kit.foot_text(s.low, kit.upper(T.step:format(fpath.name, fk * skills.STEP)) .. " · " .. kit.upper(two[pick].desc), 140, 676 + q, 18, KC.HOT_TOP, room, 0.5)
			kit.foot_text(s.low, kit.upper(T.other:format(other.name, other.desc)), 140, (#lines > 1 and 712 or 700) + q, 17, KC.MUTE, room, 0.5)
		else
			kit.foot_text(s.low, kit.upper(T.step:format(fpath.name, fk * skills.STEP)) .. " · " .. kit.upper(T.to_choose), 140, 660, 22, KC.HOT_TOP, room)
			kit.foot_text(s.low, kit.upper(two[1].name .. " · " .. two[1].desc .. "   /   " .. two[2].name .. " · " .. two[2].desc), 140, 690, 17, KC.MUTE, room, 0.5)
		end
	else
		kit.foot_text(s.low, kit.upper(T.pick_hint), 140, 674, 19, KC.MUTE, room, 0.5)
	end
	s.action = kit.action(s.right, T.save, 980, 628, 276, 80, { icon = "az_salva", size = 48, off = not changed, sub = not changed and kit.upper(T.saved) or nil })
	kit.button(s.buttons, s.action, "salva", { main = true, spento = not changed })
end

-- Screen ----------------------------------------------------------------------------

local TABS_X = 300
local GROUPS = { "left", "mid", "rt", "right", "low", "low2", "over" }

local function build(s)
	if s.head then kit.header_delete(s.head) end
	for _, k in ipairs(GROUPS) do
		if s[k] then gui.delete_node(s[k].node) end
		s[k] = nil
	end
	-- (the list stays where it was scrolled)
	if s.list then s.scroll = s.list.scroll end
	s.buttons, s.figure, s.action, s.list, s.cards, s.tokens, s.sheen = {}, nil, nil, nil, nil, nil, nil
	s.outline, s.pose = nil, nil
	local p = s.prof
	s.head = kit.header(s.buttons, T.title, KC.PURPLE, "indietro", common.home)
	s.wallet = coins.wallet(p.scaglie or 0, p.ossidiana or 0, kit.group(s.head.top_right, 1110, 44).node, 0, 0)
	coins.vouchers(s.wallet, p.buoni or 0)
	kit.tabs(s.head.top_left, s.buttons, TABS_X, 28, { { T.tab_inventory, "scheda:inventario" }, { T.tab_seals, "scheda:sigilli" } },
		s.tab == "sigilli" and 2 or 1, KC.PURPLE, true)

	-- the left column sticks to the left edge, the stats to the right one, the rest in the middle
	s.left = kit.anchor(0, 0, gui.ANCHOR_LEFT)
	s.mid = kit.anchor(0, 0)
	s.rt = kit.anchor(1280, 0, gui.ANCHOR_RIGHT)
	s.right = kit.anchor(1280, 720, gui.ANCHOR_RIGHT, gui.ANCHOR_BOTTOM)
	s.low = kit.anchor(0, 720, gui.ANCHOR_LEFT, gui.ANCHOR_BOTTOM)
	s.low2 = kit.anchor(0, 720, nil, gui.ANCHOR_BOTTOM)
	if s.tab == "sigilli" then
		seals_tab(s)
	else
		inventory(s)
	end
	-- a piece changed on the apprentice: it shows
	gear_ui.swap_check(s, s.left, s.tab ~= "sigilli" and s.gear_on or nil, 215, 600, 395, s.just == "worn")
end

function M.new(prof, tab, color)
	local s = { prof = prof, tab = tab or "inventario", colore = color or ui.C.SQUADRA[1] }
	s.draft = copy(profile.active_loadout(prof).tree or {})
	s.back = kit.scene(250, 420, { accent = KC.PURPLE, bg = "camerino" })
	build(s)
	return s
end

-- what you wear shows at once on the apprentice here (and in every menu after)
local function dress(p)
	local a = profile.active_loadout(p)
	scoria.set_player(scoria.look_of(a.gear, profile.tier(p, a)))
end

-- POTENZIA opens over the screen, from the card (bench.after brings it in)
local function open_window(s, set, slot)
	local c = s.cards and s.cards["pezzo:" .. set .. ":" .. slot]
	s.window_from = c and gui.get_screen_position(c.node) or nil
	s.sel, s.modal, s.sheet, s.just = { set, slot }, { set, slot }, nil, "open"
	build(s)
	bench.after(s)
end

function M.update(s, dt)
	if s.figure then scoria.update(s.figure, dt, s.st) end
	if s.outline then outline.update(s.outline) end
	sheen.update(s.sheen, dt)
	bench.update(s, dt)
	-- a finger kept on a card: it sinks a little, then POTENZIA opens
	local b = s.buttons and s.buttons.held_down
	local held = b and not s.modal and b.ui_action and b.ui_action:match("^pezzo:") and b or nil
	if held ~= s.held then
		if s.held and s.cards and s.cards[s.held.ui_action] then
			gui.animate(s.cards[s.held.ui_action].node, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, 0.15)
		end
		s.held, s.held_t = held, 0
	end
	if held then
		s.held_t = s.held_t + dt
		local c = s.cards and s.cards[held.ui_action]
		local k = math.min(1, s.held_t / HOLD)
		if c then gui.set_scale(c.node, vmath.vector3(1 - 0.06 * k, 1 - 0.06 * k, 1)) end
		if s.held_t >= HOLD then
			s.buttons.held_down, s.held = nil, nil
			local set, slot = held.ui_action:match("^pezzo:([^:]*):(.*)$")
			open_window(s, set, slot)
		end
	end
end

local function run_cmd(s, ui_action)
	local kind, x = ui_action:match("^(%a+):?(.*)$")
	local p = s.prof
	local a, b = x:match("^([^:]*):?(.*)$")
	if kind == "scheda" then
		s.tab, s.sheet, s.sel, s.modal = x, nil, nil, nil
		s.draft = copy(profile.active_loadout(p).tree or {})
	elseif kind == "assetto" then
		p.is_active = tonumber(x)
		profile.act(p, progress.backpack(p))
		dress(p)
	elseif kind == "sigilli" then
		p.seal_active = tonumber(x)
		profile.act(p, progress.backpack(p))
		s.draft = copy(profile.active_loadout(p).tree or {})
	elseif kind == "filtro" then
		s.slot = x ~= "" and x or nil
		if s.list then s.list.scroll = 0 end
		s.scroll = 0
	elseif kind == "pezzo" then
		-- a tap tries it on, a second tap takes it off (Sergio, 26 Nov)
		s.sel = not same_piece(s.sel, { a, b }) and { a, b } or nil
	elseif kind == "gettone" then
		-- a place of the column: the piece tried there goes back to the one you wear
		if s.sel and s.sel[2] == x then s.sel = nil end
	elseif kind == "chiudi" then
		s.modal = nil
	elseif kind == "potenzia" or kind == "firma" or kind == "frammenti" then
		bench.run(s, kind, s.modal)
		-- a worn piece that reaches gold changes look on the apprentice at once
		dress(p)
	elseif kind == "indossa" and s.sel then
		profile.active_loadout(p).gear[s.sel[2]] = s.sel[1]
		profile.act(p, progress.backpack(p))
		dress(p)
		s.sel, s.just = nil, "worn"
	elseif kind == "via" then
		s.path = x
	elseif kind == "meno" or kind == "piu" then
		-- one point at a time (Sergio, 15 Nov: the points one by one)
		s.path = x
		skills.move(s.draft, x, kind == "piu" and 1 or -1, skills.points(p.livello))
	elseif kind == "potere" then
		-- a power under a step: it becomes that step's choice
		local k, which = b:match("^(%d+):(%d)$")
		k, which = tonumber(k), tonumber(which)
		if k and which then
			skills.choose(s.draft, a, k, which)
			s.focus = { a, k, which }
		end
	elseif kind == "foglio" then
		s.sheet = not s.sheet
	elseif kind == "salva" then
		local live = profile.active_loadout(p).tree
		for key in pairs(live) do live[key] = nil end
		for key, v in pairs(copy(s.draft)) do live[key] = v end
		profile.act(p, progress.backpack(p))
	end
	build(s)
	bench.after(s)
	s.just = nil
end

function M.on_input(s, action_id, action)
	if bench.input(s, action_id, action) then return nil end
	if not s.modal and card_list.input(s.list, s.buttons, action_id, action) then return nil end
	-- the controller: Y on a card opens POTENZIA (the long press of the finger)
	if action_id == ui.PAD and action.pressed and action.ui == "scheda" and not s.modal then
		local b = ui.lit_up(s.buttons)
		local set, slot = b and b.ui_action and b.ui_action:match("^pezzo:([^:]*):(.*)$")
		if set then open_window(s, set, slot) end
		return nil
	end
	local ui_action = ui.touch(s.buttons, action_id, action)
	-- the arrow closes POTENZIA first
	if s.modal and ui_action == "indietro" then ui_action = "chiudi" end
	-- (a tap on the window, not on its buttons)
	if ui_action == "finestra" then return nil end
	if ui_action == "indietro" then return ui_action end
	if ui_action then return run_cmd(s, ui_action) end
	return nil
end

function M.destroy(s)
	outline.off()
	bench.delete(s)
	kit.header_delete(s.head)
	for _, k in ipairs(GROUPS) do
		if s[k] then gui.delete_node(s[k].node) end
	end
	kit.scene_drop(s.back)
end

return M
