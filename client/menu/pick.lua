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
-- Panels and text from the minimal interface (ui/ui.lua).
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
local T = require("lang.text").pick
local common = require("lang.text").common

local M = {}

local W, H = 1280, 720
local CARD_W, CARD_H, CARD_GAP = 280, 230, 40
-- (at the top, above the title, the strip of tags: menu/lineup.lua)
local CARD_Y = 20
-- the two picks made, under the cards
local CHOICE_W, CHOICE_H, CHOICE_Y = 300, 84, -190
local BAR_W = 560
local C = ui.C
local NAME_STEP = T.step_names
local STEP_COLOR = { C.BRACE, C.STEEL }
local VEIL = vmath.vector4(C.BOTTOM.x, C.BOTTOM.y, C.BOTTOM.z, 0.86)
local TOUCH = hash("touch")
-- how long to hold a card to open its card
local HOLD = 0.45

local function vec(x, y) return vmath.vector3(x, y, 0) end

local function gui_node(x, y, w, h, color, parent)
	local n = gui.new_box_node(vec(x, y), vec(w, h))
	gui.set_color(n, color)
	if parent then gui.set_parent(n, parent) end
	return n
end

-- a text that wraps within w
local function riga(t, y, scale, w, parent)
	local n = ui.text(t, 0, y, scale, nil, parent)
	gui.set_line_break(n, true)
	gui.set_size(n, vmath.vector3(w / (scale * 0.5), 200, 0))
	return n
end

-- a card (or a pick made): panel, icon, name and a line below
local function paper(x, y, w, h, icon_d, parent)
	local c, border = ui.panel(x, y, w, h, parent)
	local icon_img = gui.new_box_node(vec(0, 0), vec(icon_d, icon_d))
	gui.set_texture(icon_img, "armi")
	gui.set_parent(icon_img, c)
	return { node = c, bordo = border, icon_img = icon_img }
end

function M.new(icons, name_list, effects, commands)
	local s = { icons = icons, nomi = name_list, effects = effects, commands = commands, card_list = {}, scelte = {} }
	-- what the controller light goes on: cards, picks made and buttons
	s.luce = {}
	s.root = gui_node(W / 2, H / 2, W * screen.FULL, H * screen.FULL, VEIL)
	gui.set_adjust_mode(s.root, gui.ADJUST_FIT)
	s.titolo = ui.title("", 0, 232, 0.55, nil, s.root)
	s.sotto = riga("", 192, 0.6, 1000, s.root)
	for i = 1, config.DRAFT_OFFER do
		local c = paper(0, CARD_Y, CARD_W, CARD_H, 96, s.root)
		gui.set_position(c.icon_img, vec(0, 40))
		c.nome = ui.text("", 0, -32, 0.7, nil, c.node)
		c.effect = riga("", -70, 0.5, CARD_W - 24, c.node)
		gui.set_color(c.effect, C.OFF)
		s.card_list[i] = c
		c.colore, c.ui_action, c.nodo = C.LIGHT, "carta:" .. i, c.node
		s.luce[#s.luce + 1] = c
	end
	for step = 1, 2 do
		local x = (step - 1.5) * (CHOICE_W + 30)
		local c = paper(x, CHOICE_Y, CHOICE_W, CHOICE_H, 56, s.root)
		gui.set_position(c.icon_img, vec(-CHOICE_W / 2 + 46, 0))
		local kind = ui.text(NAME_STEP[step], -CHOICE_W / 2 + 90, 16, 0.5, STEP_COLOR[step], c.node)
		gui.set_pivot(kind, gui.PIVOT_W)
		c.nome = ui.text("", -CHOICE_W / 2 + 90, -14, 0.65, nil, c.node)
		gui.set_pivot(c.nome, gui.PIVOT_W)
		s.scelte[step] = c
		c.colore, c.ui_action, c.nodo = C.LIGHT, "scelta:" .. step, c.node
		s.luce[#s.luce + 1] = c
	end
	s.buttons = {}
	s.gioca = ui.button(s.buttons, 0, -290, 300, 70, common.play, "gioca", { main = true }, s.root)
	s.bar = ui.bar(0, -300, BAR_W, 6, C.LIGHT, s.root)
	-- the wheel: a tap opens ESCI next to it, another closes it again
	s.rotellina = ui.settings_button(s.buttons, "rotellina")
	s.esci = ui.button(s.buttons, 32 + 12 + 80, 0, 160, 64, common.quit, "esci", nil, s.rotellina)
	for _, b in ipairs(s.buttons) do s.luce[#s.luce + 1] = b end
	gui.set_enabled(s.root, false)
	gui.set_enabled(s.rotellina, false)
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
	gui.set_text(s.titolo, (title:gsub("^%l", string.upper)))
	gui.set_color(s.titolo, s.online and C.LIGHT or s.colori[s.chi] or C.LIGHT)
	gui.set_text(s.sotto, under)
end

local function refresh(s)
	local d, who = s.d, s.chi
	texts(s)
	local offer, picks = lane(d, math.min(s.passo, 2))
	local x0 = -((#offer - 1) * (CARD_W + CARD_GAP)) / 2
	for i, c in ipairs(s.card_list) do
		local w = s.passo <= 2 and offer[i]
		gui.set_enabled(c.node, w and true or false)
		if w then
			gui.set_position(c.node, vec(x0 + (i - 1) * (CARD_W + CARD_GAP), CARD_Y))
			gui.play_flipbook(c.icon_img, s.icons[w])
			gui.set_text(c.nome, s.nomi[w])
			gui.set_text(c.effect, s.effects[w] or "")
			c.riposo = picks[who] == w and C.LIGHT or STEP_COLOR[s.passo]
			gui.set_color(c.bordo, c.riposo)
		end
	end
	for step, c in ipairs(s.scelte) do
		local of, pk = lane(d, step)
		local w = pk[who]
		gui.set_enabled(c.node, #of > 0)
		gui.set_enabled(c.icon_img, w ~= nil)
		if w then gui.play_flipbook(c.icon_img, s.icons[w]) end
		gui.set_text(c.nome, w and s.nomi[w] or "...")
		c.riposo = step == s.passo and C.LIGHT or w and STEP_COLOR[step] or C.LINE
		gui.set_color(c.bordo, c.riposo)
	end
	gui.set_enabled(s.gioca, s.guidata and s.passo == 3)
	gui.set_enabled(s.bar.nodo, not s.guidata)
	ui.relight(s.luce)
end

-- The card opened with the long press, if any, closes
local function close_sheet(s)
	if s.carta then s.carta:close_view() end
	s.carta, s.pressed_f = nil, nil
end

-- The wheel under the strip of tags (menu/lineup.lua), which in 2 vs 2
-- goes from edge to edge; true below, false in its own place
function M.under_strip(s, under)
	local p = gui.get_position(s.rotellina)
	p.y = under and 720 - 30 - 32 - 50 or 720 - 30 - 32
	gui.set_position(s.rotellina, p)
end

local function open_view(s)
	M.under_strip(s, false)
	gui.set_enabled(s.root, true)
	gui.set_enabled(s.rotellina, true)
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
	gui.set_enabled(s.root, false)
	gui.set_enabled(s.rotellina, false)
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
	gui.set_enabled(s.root, false)
	gui.set_enabled(s.rotellina, false)
	local players = draft.finish(s.d)
	s.d = nil
	return players
end

function M.update(s, dt)
	if not s.d then return nil end
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
	ui.bar_value(s.bar, s.tempo / config.DRAFT_SECONDS)
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
		if gui.is_enabled(s.esci) then ui.light(s.luce, s.buttons[#s.buttons]) end
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
		local offer = lane(s.d, s.passo)
		for i, c in ipairs(s.card_list) do
			if offer[i] and gui.pick_node(c.node, action.x, action.y) then
				s.pressed_f = { w = offer[i], t = 0 }
				return
			end
		end
	end
	-- a pick made: back to that row
	for step, c in ipairs(s.scelte) do
		if gui.is_enabled(c.node) and gui.pick_node(c.node, action.x, action.y) then
			s.passo = step
			refresh(s)
			return
		end
	end
end

return M
