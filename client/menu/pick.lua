-- Match-start draft (the rules are in sim/draft.lua; Sergio, 30 Oct): first
-- the primary, then the secondary, one row of cards at a time. The others'
-- picks are hidden and duplicates are fine; everyone has the Grapple. Under
-- the cards the two picks made: tapping one goes back to that row. Holding a
-- card down opens the weapon's card (battle/card.lua), the same as for
-- crates; a tap closes it. With the controller the d-pad moves the light over
-- cards, picks and buttons, A picks, Y opens the card and Start the wheel
-- (ui.touch, ui/controller.lua).
-- On the same phone players pick in turn, with the timer waiting for whoever
-- reads a card. Online only whoever plays on this phone picks, until the
-- server's time runs out: the picks go to the server (docs/server.md).
-- The campaign's first draft (guided) has no timer, explains more and ends
-- with GIOCA. The wheel at the top left opens ESCI.
-- Drawn with the kit (ui/kit.lua, Figma coordinates): on the left your two
-- picks and what everyone has, with your devil; the cards in the middle; at the
-- bottom right PRONTO, dark until both are picked. The view is rebuilt at every
-- pick (few nodes, rare).
--
--   local scelta = require "menu.pick"
--   local s = scelta.new(icons, nomi, effects, commands) -- icons (weapons atlas), names and a line on each weapon's effect;
--                                                  -- commands(): "telefono", "computer" or "controller" (for the card)
--   scelta.show(s, d, player_names, colori, guidata) -- on the same phone: d = draft.new(...)
--   local players = scelta.update(s, dt)           -- the players for game.new, once everyone has picked (online nil)
--   scelta.on_input(s, action_id, action)          -- "esci" if ESCI is tapped
--   scelta.online(s, m, nomi, colori, send)        -- online, at every draft message from the server;
--                                                  -- send(msg) sends the picks
--   scelta.hide(s)
--   scelta.when_closing(s, fn)                     -- fn() when the draft closes

local config = require "sim.config"
local draft = require "sim.draft"
local game = require "sim.game"
local ui = require "ui.ui"
local controller = require "ui.controller"
local screen = require "ui.screen"
local card = require "battle.card"
local kit = require "ui.kit"
local scoria = require "battle.scoria"
local T = require("lang.text").pick
local common = require("lang.text").common

local M = {}

local W, H = 1280, 720
local KC = kit.C
local NAME_STEP = T.step_names
local STEP_COLOR = { KC.HOT, KC.STEEL }
local VEIL = vmath.vector4(KC.INK.x, KC.INK.y, KC.INK.z, 0.9)
local TOUCH = hash("touch")
-- how long to hold a card to open its card
local HOLD = 0.45
local CARD_W, CARD_H = 238, 330
-- what everyone has, always: the base primary, the blade, the grapple
local EVERYONE = { "missile", "sword", "hook" }

local function vec(x, y) return vmath.vector3(x, y, 0) end
local function with_alpha(c, a) return vmath.vector4(c.x, c.y, c.z, a) end

local function gui_node(x, y, w, h, color, parent)
	local n = gui.new_box_node(vec(x, y), vec(w, h))
	gui.set_color(n, color)
	if parent then gui.set_parent(n, parent) end
	return n
end

-- a weapon's picture, d wide, centered at (x, y) of the group
local function icon(s, g, w, x, y, d)
	local n = gui_node(x - g.ox, g.oy - y, d, d, vmath.vector4(1, 1, 1, 1), g.node)
	gui.set_texture(n, "armi")
	gui.play_flipbook(n, s.icons[w])
	return n
end

-- a text that never gets wider than `wide`
local function fit(n, wide)
	local w = kit.width(n)
	if w > wide then
		local sc = gui.get_scale(n)
		gui.set_scale(n, vec(sc.x * wide / w, sc.y * wide / w))
	end
	return n
end

-- a text that wraps within `wide`, from its top left corner
local function wrapped(g, t, x, y, size, color, wide)
	local n = kit.text(g, t, x, y, size, color)
	gui.set_pivot(n, gui.PIVOT_NW)
	gui.set_line_break(n, true)
	gui.set_size(n, vmath.vector3(wide / gui.get_scale(n).x, 200, 0))
	return n
end

function M.new(icons, name_list, effects, commands)
	local s = { icons = icons, nomi = name_list, effects = effects, commands = commands, card_list = {}, scelte = {} }
	-- what the controller light goes on: cards, picks made and buttons
	s.luce = {}
	-- a dark sheet, the backdrop on it (while the draft is open) and then the rest
	s.veil = gui_node(W / 2, H / 2, W * screen.FULL, H * screen.FULL, VEIL)
	s.root = gui_node(W / 2, H / 2, 0, 0, VEIL)
	gui.set_visible(s.root, false)
	gui.set_adjust_mode(s.root, gui.ADJUST_FIT)
	s.g = { node = s.root, ox = W / 2, oy = H / 2 }
	-- what sticks to the real edges: the name, the plate that says what to do, PRONTO
	s.tl = kit.anchor(0, 0, gui.ANCHOR_LEFT, gui.ANCHOR_TOP)
	s.low = kit.anchor(0, 720, gui.ANCHOR_LEFT, gui.ANCHOR_BOTTOM)
	s.right = kit.anchor(1280, 720, gui.ANCHOR_RIGHT, gui.ANCHOR_BOTTOM)
	kit.title(s.tl, T.title, KC.HOT, 112, 76)
	-- the wheel: a tap opens ESCI next to it, another closes it again
	s.fixed = {}
	s.rotellina = ui.settings_button(s.fixed, "rotellina")
	s.esci = ui.button(s.fixed, 32 + 12 + 80, 0, 160, 64, common.quit, "esci", nil, s.rotellina)
	s.buttons = {}
	s.tops = { s.veil, s.root, s.tl.node, s.low.node, s.right.node, s.rotellina }
	for _, n in ipairs(s.tops) do gui.set_enabled(n, false) end
	return s
end

-- The fan and the picks of the step (1 primaries, 2 secondaries)
local function lane(d, step)
	if step == 1 then return d.offer, d.picks end
	return d.offer2, d.picks2
end

-- The first step missing for chi (3: done); empty fans are skipped
local function missing(d, who)
	for step = 1, 2 do
		local offer, picks = lane(d, step)
		if #offer > 0 and not picks[who] then return step end
	end
	return 3
end

-- The next one who has to pick on the same phone, or nil
local function next_one(s)
	for i = 1, #s.d.players do
		if not draft.done(s.d, i) then return i end
	end
end

local function shots_text(n) return (n == 1 and T.shot or T.shots):format(n) end

-- Title and lines below, by step and by whether the draft is guided
local function texts(s)
	local p, guide = s.passo, s.guidata
	local who = s.online and "" or (#s.giocatori > 1 and not s.guidata and s.giocatori[s.chi] .. ", " or "")
	local title, under
	if p == 1 then
		title = who .. T.pick_primary
		under = (guide and T.primary_guided or T.primary):format(shots_text(config.DRAFT_SHOTS))
	elseif p == 2 then
		title = who .. T.pick_secondary
		under = (guide and T.secondary_guided or T.secondary):format(shots_text(config.SECONDARY_SHOTS.draft))
	else
		title = T.ready
		under = guide and T.ready_guided or T.ready_text
	end
	-- with the controller the card opens with Y, and you pick with the d-pad
	if s.commands and s.commands() == "controller" then
		under = under:gsub(T.hold_card, T.press_on_card:format(controller.name_of("scheda")))
			:gsub(T.tap_pick, T.back_to_pick)
	end
	return kit.upper(title), under
end

-- the timer's bar, f from 0 to 1: its lit part shrinks toward the left
local function bar_value(s, f)
	local b = s.bar
	if not b then return end
	f = math.max(0, math.min(1, f))
	gui.set_enabled(b.front.node, f > 0.01)
	gui.set_scale(b.front.node, vec(math.max(f, 0.01), 1))
	gui.set_position(b.front.node, vec(b.x0 - b.wide * (1 - f) / 2, b.y0))
	local left = math.max(0, math.ceil(s.tempo))
	gui.set_text(s.clock, string.format("%d:%02d", math.floor(left / 60), left % 60))
end

-- Rebuilds what is seen: the picks on the left, the cards, the time, PRONTO
local function refresh(s)
	local d, who = s.d, s.chi
	local lit = ui.lit_up(s.luce)
	lit = lit and lit.ui_action
	for _, n in ipairs(s.view or {}) do gui.delete_node(n) end
	s.view, s.luce, s.card_list, s.scelte, s.buttons, s.bar = {}, {}, {}, {}, {}, nil
	local function sub(group)
		local n = gui_node(0, 0, 0, 0, KC.INK, group.node)
		gui.set_visible(n, false)
		s.view[#s.view + 1] = n
		return { node = n, ox = group.ox, oy = group.oy }
	end
	local g, low, right = sub(s.g), sub(s.low), sub(s.right)
	local title, under = texts(s)
	local color = s.colori[who] or ui.C.SQUADRA[1]

	-- your devil, behind the picks
	local pose = gui_node(250 - g.ox, 104 - (720 - g.oy), 0, 0, KC.INK, g.node)
	gui.set_visible(pose, false)
	s.figure = scoria.new(color, scoria.PERSONAGGIO)
	s.st = { x = 0, y = 0, facing = 1, grounded = true, moving = 0, fermo = true }
	scoria.update(s.figure, 0, s.st)
	local k = 265 / game.DISEGNO_H
	gui.set_scale(pose, vmath.vector3(k, k, 1))
	local ground = ui.alone(0, 0, 230 / k, with_alpha(KC.INK, 0.6), pose)
	gui.set_scale(ground, vmath.vector3(1, 0.14, 1))
	gui.set_parent(s.figure.root, pose)
	scoria.set_enabled(s.figure, true)

	-- the two picks: a tap goes back to that row
	kit.text(g, T.yours, 44, 128, 14, KC.MUTE, "start", 1.5)
	local missing_n, first_missing = 0, nil
	for step = 1, 2 do
		local of, pk = lane(d, step)
		if #of > 0 then
			local w = pk[who]
			if not w then missing_n, first_missing = missing_n + 1, first_missing or step end
			local x, y = 40 + (step - 1) * 8, 140 + (step - 1) * 86
			local c = kit.card(g, x, y, 150, 72, w and STEP_COLOR[step] or KC.LINE, { sel = step == s.passo })
			kit.text(c.g, NAME_STEP[step], x + 26, y + 22, 10, KC.MUTE, "start", 1.5)
			if w then
				icon(s, c.g, w, x + 50, y + 46, 44)
				fit(kit.text(c.g, kit.upper(s.nomi[w]), x + 142, y + 62, 11, KC.SAND, "end", 0.5), 66)
			else
				kit.text(c.g, "?", x + 82, y + 58, 34, KC.MUTE, "middle")
			end
			kit.button(s.luce, c, "scelta:" .. step)
			s.scelte[step] = c
		end
	end
	kit.text(g, T.everyone, 52, 340, 11, KC.MUTE, "start", 1.5)
	for i, w in ipairs(EVERYONE) do
		local x, y = 44 - (i - 1) * 4, 350 + (i - 1) * 56
		kit.info(g, x, y, 96, 46, KC.PURPLE)
		icon(s, g, w, x + 50, y + 23, 40)
	end
	local on_plate = kit.sand(low, 80, 630, 340, 62, KC.HOT, { sk = 22 })
	fit(kit.text(on_plate.g, title, 250, 668, 22, KC.INK, "middle", 0.5), 290)

	-- the cards of the row (with both picked, the last row stays)
	local shown = math.min(s.passo, 2)
	if #(lane(d, shown)) == 0 then shown = 1 end
	local offer, picks = lane(d, shown)
	local shots = shown == 1 and config.DRAFT_SHOTS or config.SECONDARY_SHOTS.draft
	wrapped(g, under, 446, s.guidata and 84 or 106, 13, KC.MUTE, 760)
	for i, w in ipairs(offer) do
		local sel = picks[who] == w
		local x, y = 440 + (i - 1) * 256, 150 - (sel and 8 or 0)
		local col = STEP_COLOR[shown]
		local c = kit.card(g, x, y, CARD_W, CARD_H, col, { sel = sel })
		kit.rect(c.g, x + 12, y + 12, CARD_W - 24, 152, with_alpha(KC.INK, 0.55))
		icon(s, c.g, w, x + CARD_W / 2, y + 88, 124)
		fit(kit.text(c.g, kit.upper(s.nomi[w]), x + 24, y + 208, 30, KC.SAND), CARD_W - 48)
		wrapped(c.g, s.effects[w] or "", x + 22, y + 220, 13, KC.MUTE, CARD_W - 44)
		kit.text(c.g, T.shots_label, x + 14, y + CARD_H - 22, 10, KC.MUTE, "start", 1.5)
		kit.pips(c.g, x + 62, y + CARD_H - 36, shots, shots, col)
		if sel then
			kit.para(c.g, x + CARD_W - 92, y + CARD_H - 44, 84, 28, 8, KC.SAND)
			kit.text(c.g, T.chosen, x + CARD_W - 46, y + CARD_H - 24, 13, KC.INK, "middle", 1)
		end
		kit.button(s.luce, c, "carta:" .. i)
		c.w = w
		s.card_list[i] = c
	end
	s.shown = shown

	-- the time that is left (the guided draft has none)
	if not s.guidata then
		kit.text(g, T.time, 446, 524, 12, KC.MUTE, "start", 1.5)
		s.bar = kit.bar(g, 504, 512, 360, 12, 1, KC.HOT)
		local at = gui.get_position(s.bar.front.node)
		s.bar.x0, s.bar.y0, s.bar.wide = at.x, at.y, 360
		s.clock = kit.text(g, "", 880, 524, 16, KC.SAND)
		bar_value(s, s.tempo / config.DRAFT_SECONDS)
	end

	-- PRONTO: dark while a weapon is missing. Only the guided draft waits for
	-- its tap; the others start by themselves (same phone) or with the server's time
	local opt = { size = 54 }
	if missing_n > 0 then
		opt.off = true
		opt.sub = missing_n > 1 and T.missing_two or T.missing_one:format(NAME_STEP[first_missing])
	elseif s.online then
		opt.sub = T.starts_at_time
	end
	local go = kit.action(right, s.guidata and common.play or T.ready_action, 930, 560, 270, 84, opt)
	if s.guidata and missing_n == 0 then
		s.gioca = kit.button(s.buttons, go, "gioca", { main = true })
	end
	for _, b in ipairs(s.fixed) do s.buttons[#s.buttons + 1] = b end
	for _, b in ipairs(s.buttons) do s.luce[#s.luce + 1] = b end
	if lit then
		for _, b in ipairs(s.luce) do
			if b.ui_action == lit then ui.light(s.luce, b) end
		end
	end
end

-- The card opened with the long press, if any, closes
local function close_sheet(s)
	if s.carta then s.carta:close_view() end
	s.carta, s.pressed_f = nil, nil
end

-- the backdrop, just above the dark sheet and under everything else
local function scene_on(s, on)
	if s.scene then
		kit.scene_drop(s.scene)
		s.scene = nil
	end
	if not on then return end
	s.scene = kit.scene(250, 360, { bg = "gioca" })
	kit.scene_place(s.scene, "above", s.veil)
end

local function show_all(s, on)
	for _, n in ipairs(s.tops) do gui.set_enabled(n, on) end
	scene_on(s, on)
end

local function open_view(s)
	show_all(s, true)
	gui.set_enabled(s.esci, false)
	s.fatto = nil
	refresh(s)
end

function M.show(s, d, giocatori, palette, guided)
	s.d, s.giocatori, s.colori, s.guidata = d, giocatori, palette, guided
	s.online = nil
	s.chi = next_one(s)
	s.passo = s.chi and missing(d, s.chi) or 3
	s.tempo = config.DRAFT_SECONDS
	open_view(s)
end

local function empty(v) return v ~= "" and v or nil end

-- Online: m is the server's draft message (fans, our picks, ticks left). It
-- makes a copy of sim/draft.lua's state for whoever plays here.
function M.online(s, m, giocatori, palette, send)
	local d = { offer = m.offer, offer2 = m.offer2, players = m.players, picks = {}, picks2 = {} }
	d.picks[m.you], d.picks2[m.you] = empty(m.p), empty(m.p2)
	local first = not s.online
	s.d, s.giocatori, s.colori, s.guidata = d, giocatori, palette, nil
	s.online, s.send, s.chi = true, send, m.you
	s.tempo = (m.left or 0) * game.DT
	if first then
		s.passo = missing(d, s.chi)
		open_view(s)
	else
		refresh(s)
	end
end

-- fn() when the draft closes (finished, hidden, leaving): the lineup and its
-- strip go away with it
function M.when_closing(s, fn)
	s.closing = fn
end

local function closed(s)
	if s.closing then s.closing() end
end

function M.hide(s)
	closed(s)
	close_sheet(s)
	show_all(s, false)
	s.d, s.online = nil, nil
end

local function choose(s, w)
	if not (s.chi and draft.pick(s.d, s.chi, w)) then return end
	if s.online then s.send({ t = "pick", w = w }) end
	s.passo = missing(s.d, s.chi)
	if s.passo == 3 and not s.online and not s.guidata then
		-- on the same phone, when one finishes it's the next one's turn
		local after_step = next_one(s)
		if after_step then
			s.chi, s.passo, s.tempo = after_step, missing(s.d, after_step), config.DRAFT_SECONDS
		else
			-- a moment to see the last pick before starting
			s.fatto = 0.6
		end
	end
	refresh(s)
end

local function wrap_up(s)
	closed(s)
	close_sheet(s)
	show_all(s, false)
	local players = draft.finish(s.d)
	s.d = nil
	return players
end

function M.update(s, dt)
	if not s.d then return nil end
	if s.figure then scoria.update(s.figure, dt, s.st) end
	if s.fatto then
		s.fatto = s.fatto - dt
		if s.fatto > 0 then return nil end
		return wrap_up(s)
	end
	-- held long enough: the weapon's card, and the card isn't picked
	if s.pressed_f then
		s.pressed_f.t = s.pressed_f.t + dt
		if s.pressed_f.t >= HOLD then
			s.carta = card.open_view(s.pressed_f.w, s.commands and s.commands())
			s.pressed_f = nil
		end
	end
	-- the guided draft has no timer; on the same phone the timer waits for whoever reads the card
	if s.guidata or (s.carta and not s.online) then return nil end
	s.tempo = s.tempo - dt
	bar_value(s, s.tempo / config.DRAFT_SECONDS)
	-- online, when time runs out the server decides
	if s.online then return nil end
	if s.tempo <= 0 and s.chi then
		-- when time runs out, the first weapon of each missing row
		local who = s.chi
		while s.chi == who and not s.fatto and s.passo <= 2 do
			choose(s, (lane(s.d, s.passo))[1])
		end
	end
	return nil
end

-- With the controller (action_id ui.PAD): the light, A, Y for the card, Start the wheel
local function controller(s, action)
	if not action.pressed then return end
	if s.carta then
		close_sheet(s)
		return
	end
	local u = action.ui
	if u == "menu" or (u == "indietro" and gui.is_enabled(s.esci)) then
		gui.set_enabled(s.esci, u == "menu" and not gui.is_enabled(s.esci))
		if gui.is_enabled(s.esci) then ui.light(s.luce, s.fixed[#s.fixed]) end
		return
	end
	local lit = ui.lit_up(s.luce)
	local ui_action
	if u == "scheda" then
		ui_action = lit and lit.ui_action
	else
		ui_action = ui.touch(s.luce, ui.PAD, action)
	end
	if not ui_action then return end
	local kind, i = ui_action:match("^(%a+):(%d)$")
	i = tonumber(i)
	if ui_action == "esci" then
		return "esci"
	elseif ui_action == "rotellina" then
		gui.set_enabled(s.esci, not gui.is_enabled(s.esci))
	elseif ui_action == "gioca" then
		s.fatto = 0
	elseif kind == "carta" and s.passo <= 2 then
		local w = lane(s.d, s.passo)[i]
		if w and u == "scheda" then
			s.carta = card.open_view(w, s.commands and s.commands())
		elseif w then
			choose(s, w)
		end
	elseif kind == "scelta" and u ~= "scheda" then
		s.passo = i
		refresh(s)
	end
end

function M.on_input(s, action_id, action)
	if not s.d or s.fatto then return end
	if action_id == ui.PAD then return controller(s, action) end
	if action_id ~= TOUCH then return end
	-- the card is open: any tap closes it
	if s.carta then
		if action.pressed then close_sheet(s) end
		return
	end
	local ui_action = ui.touch(s.buttons, action_id, action)
	if ui_action == "rotellina" then
		gui.set_enabled(s.esci, not gui.is_enabled(s.esci))
		return
	elseif ui_action == "esci" then
		return "esci"
	elseif ui_action == "gioca" then
		s.fatto = 0
		return
	end
	-- the card is picked on release, if it wasn't held for the card
	if action.released then
		local p = s.pressed_f
		s.pressed_f = nil
		if p then choose(s, p.w) end
		return
	end
	if not action.pressed or s.buttons.held_down then return end
	gui.set_enabled(s.esci, false)
	if s.passo <= 2 then
		for _, c in ipairs(s.card_list) do
			if gui.pick_node(c.node, action.x, action.y) then
				s.pressed_f = { w = c.w, t = 0 }
				return
			end
		end
	end
	-- a pick made: back to that row
	for step, c in pairs(s.scelte) do
		if gui.pick_node(c.node, action.x, action.y) then
			s.passo = step
			refresh(s)
			return
		end
	end
end

return M
