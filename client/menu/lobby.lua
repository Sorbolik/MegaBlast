-- The waiting room (Sergio, 3 Nov: "mi piace la proposta dei cartellini"):
-- while the server looks for the other players, one place per player of the
-- match. Yours shows your tag at once; the others light up one at a time as
-- they join the queue (level and badges, from the server's "wait"), the empty
-- ones wait with "IN ARRIVO". Above, what you are looking for, how many there
-- are and the time that passes; below, a tip that changes every TIP_EVERY
-- seconds. When the queue is full the lineup takes over (menu/lineup.lua).
-- If nobody else arrives, after the server's BotAfter (25 s, lobby.go) bots
-- fill the empty places: the line counts it down (BOT TRA N s). ESCI DALLA
-- CODA, at the bottom, leaves the queue (like the gear's ESCI DALLA RICERCA).
--
--   local s = sala.new(of, titolo, parent_below)  -- of: players of the match; parent_below: the
--                                                 -- gear, which stays above (its wheel too)
--   sala.giocatori(s, vetrine) -> true if someone new arrived (vetrine: menu/showcase.lua, in queue order)
--   sala.bot_in(s, secs)                         -- the bots arrive in secs seconds (nil: no bots, events)
--   sala.exit_hit(s, x, y) -> "esci" on ESCI DALLA CODA, "menu" on TORNA AI MENU (the queue
--                                stays alive: ui/pill.lua), nil elsewhere (x, y as gui.pick_node wants them)
--   sala.since(s, secs)                          -- the queue started secs seconds ago (back from the menus)
--   sala.update(s, dt)
--   sala.wheel_open(s, open)                     -- the gear's wheel covers the title: it hides it
--   sala.destroy(s)

local ui = require "ui.ui"
local tag = require "ui.tag_card"
local kit = require "ui.kit"
local game = require "sim.game"
local T = require("lang.text").lobby

local M = {}

M.TIP_EVERY = 8
M.BOT_SHOWN = 15
M.TIPS = T.tips
local KC = kit.C
local TEAMS = ui.C.SQUADRA
local TIP_WIDE = 566
local TAG_W, TAG_H = 230, 330
local EMPTY_W, EMPTY_H = 220, 300

local function vec(x, y) return vmath.vector3(x, y, 0) end
local function with_alpha(c, a) return vmath.vector4(c.x, c.y, c.z, a) end

-- Where each place starts (its left side): four as drawn, a different number in a row at the center
local function places(n)
	local xs = {}
	local x0 = n == 4 and 100 or 640 - (n * 244 + 26) / 2
	for i = 1, n do xs[i] = i == 1 and x0 or x0 + 26 + (i - 1) * 244 end
	return xs
end

-- the place's color: the first half of the queue on one side, the rest on the other
local function side(s, i)
	return TEAMS[i <= math.ceil(s.of / 2) and 1 or 2]
end

-- the tip never leaves its row: a long one shrinks
local function fit_tip(s)
	gui.set_scale(s.tip, s.tip_scale)
	local wide = kit.width(s.tip)
	if wide > TIP_WIDE then gui.set_scale(s.tip, s.tip_scale * (TIP_WIDE / wide)) end
end

-- An empty place: a dim card with the shadow of who will come and three
-- notches that light up in turn
local function empty_place(s, i)
	local x, y = s.xs[i], 290 + ((i - 1) % 2) * 14
	local k = kit.card(s.g, x, y, EMPTY_W, EMPTY_H, side(s, i), { sk = 16, off = true })
	local scoria = require "battle.scoria"
	local pose = gui.new_box_node(vec(4, EMPTY_H / 2 - 236), vec(0, 0))
	gui.set_color(pose, vmath.vector4(0, 0, 0, 0.16))
	gui.set_parent(pose, k.node)
	local figure = scoria.new(vmath.vector4(0, 0, 0, 1), scoria.PERSONAGGIO)
	scoria.update(figure, 0, { x = 0, y = 0, facing = 1, grounded = true, moving = 0, fermo = true })
	local sc = 128 / game.DISEGNO_H
	gui.set_scale(pose, vmath.vector3(sc, sc, 1))
	gui.set_parent(figure.root, pose)
	scoria.set_enabled(figure, true)
	kit.text(k.g, T.coming, x + 118, y + 270, 18, KC.MUTE, "middle", 1.5)
	return { root = k.node, pips = kit.pips(k.g, x + 96, y + 26, 3, 0, KC.SAND) }
end

function M.new(of, title, parent_below)
	local s = { of = of, t = 0, tip_t = 0, tip_i = 1, card_list = {}, empty = {}, n = 0 }
	s.radice = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_visible(s.radice, false)
	-- the gear and its wheel stay above the room
	if parent_below then gui.move_below(s.radice, parent_below) end
	-- the rays behind everything, in the color of the online game
	s.scene = kit.scene(640, 380, { accent = KC.RED })
	kit.scene_place(s.scene, "below", s.radice)
	local g = { node = s.radice, ox = 0, oy = 720 }
	s.g = g
	-- what you are doing on a light plate, and under it how it is going
	s.testa = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_visible(s.testa, false)
	gui.set_parent(s.testa, s.radice)
	local tg = { node = s.testa, ox = 0, oy = 720 }
	kit.sand(tg, 60, 120, 470, 84, KC.RED, { sk = 26, d = 12 })
	kit.text(tg, T.searching, 92, 178, 48, KC.INK)
	kit.info(tg, 90, 222, 440, 38, KC.HOT)
	s.riga = kit.text(tg, "", 114, 248, 17, KC.SAND, "start", 1)
	-- the screen's name, next to the gear (it sticks to the real corner like it)
	s.top = kit.anchor(0, 0, gui.ANCHOR_LEFT, gui.ANCHOR_TOP)
	gui.move_above(s.top.node, s.radice)
	kit.title(s.top, require("lang.text").queue.title, KC.RED, 112, 76)
	s.xs = places(of)
	-- the tip: a row to read, next to the plate
	kit.info(g, 600, 120, 620, 70, KC.PURPLE)
	kit.text(g, T.tip, 632, 146, 12, KC.HOT_TOP, "start", 1.5)
	s.tip = kit.text(g, M.TIPS[1], 630, 172, 16, KC.SAND)
	s.tip_scale = gui.get_scale(s.tip)
	fit_tip(s)
	s.buttons = {}
	local back = kit.plate(g, 640, 620, 330, 52, KC.ROSE, { sk = 14, d = 6 })
	kit.text(back.g, T.back_to_menus, 640 + 172, 620 + 32, 16, KC.SAND, "middle", 0.5)
	kit.button(s.buttons, back, "menu")
	local exit = kit.plate(g, 1000, 620, 230, 52, KC.ROSE, { sk = 14, d = 6 })
	kit.text(exit.g, T.leave_queue, 1000 + 122, 620 + 32, 16, KC.SAND, "middle", 0.5)
	kit.button(s.buttons, exit, "esci")
	s.back, s.exit = back.node, exit.node
	s.title = title
	M.update(s, 0)
	return s
end

-- Rebuilds the places: few nodes and rare (one join or leave), the simplest way
function M.players(s, showcases)
	for _, c in ipairs(s.card_list) do tag.destroy(c) end
	for _, e in ipairs(s.empty) do gui.delete_node(e.root) end
	s.card_list, s.empty = {}, {}
	for i = 1, s.of do
		local v = showcases[i]
		if v then
			local c = tag.small(s.g, v, s.xs[i], 290, TAG_W, TAG_H, { color = side(s, i), sel = false })
			s.card_list[#s.card_list + 1] = c
			-- whoever just arrived comes in with a small jump
			if i > s.n then
				gui.set_scale(c.root, vec(0.9, 0.9))
				gui.animate(c.root, "scale", vec(1, 1), gui.EASING_OUTBACK, 0.25)
			end
		else
			s.empty[#s.empty + 1] = empty_place(s, i)
		end
	end
	local arrived = #showcases > s.n and s.n > 0
	s.n = math.min(#showcases, s.of)
	M.update(s, 0)
	return arrived
end

function M.bot_in(s, secs)
	s.bot_left = tonumber(secs)
end

function M.exit_hit(s, x, y)
	if gui.pick_node(s.exit, x, y) then return "esci" end
	if gui.pick_node(s.back, x, y) then return "menu" end
	return nil
end

function M.since(s, secs)
	s.t = secs or 0
end

function M.update(s, dt)
	s.t = s.t + dt
	local secs = math.floor(s.t)
	local bots = ""
	if s.bot_left and s.n < s.of then
		s.bot_left = math.max(0, s.bot_left - dt)
		-- the count shows only in the last BOT_SHOWN seconds, so at first it doesn't scare
		if s.bot_left <= M.BOT_SHOWN then
			bots = s.bot_left > 0 and T.bots_in:format(math.ceil(s.bot_left)) or T.bots_coming
		end
	end
	gui.set_text(s.riga, T.status:format(s.title ~= "" and T.title_sep:format(s.title) or "",
		s.n, s.of, math.floor(secs / 60), secs % 60, bots))
	-- the notches of the empty places light up one after the other
	local lit = math.floor(s.t * 2) % 4
	for _, e in ipairs(s.empty) do
		for i, n in ipairs(e.pips) do kit.tint(n.parts, i <= lit and KC.SAND or KC.LINE) end
	end
	for _, c in ipairs(s.card_list) do tag.update(c, dt) end
	s.tip_t = s.tip_t + dt
	if s.tip_t >= M.TIP_EVERY then
		s.tip_t = 0
		s.tip_i = s.tip_i % #M.TIPS + 1
		gui.set_text(s.tip, M.TIPS[s.tip_i])
		fit_tip(s)
		gui.set_color(s.tip, with_alpha(KC.SAND, 0))
		gui.animate(s.tip, "color.w", 1, gui.EASING_OUTQUAD, 0.3)
	end
end

function M.wheel_open(s, open)
	gui.set_enabled(s.testa, not open)
	gui.set_enabled(s.top.node, not open)
end

function M.destroy(s)
	if s.radice then gui.delete_node(s.radice) end
	if s.scene then kit.scene_drop(s.scene) end
	s.scene = nil
	if s.top then gui.delete_node(s.top.node) end
	s.top = nil
	s.radice = nil
end

return M
