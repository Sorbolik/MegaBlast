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
local T = require("lang.text").lobby

local M = {}

local C = ui.C
local TOP = 548          -- where a tag starts
local STEP = 306
M.TIP_EVERY = 8
M.BOT_SHOWN = 15
M.TIPS = T.tips

local function vec(x, y) return vmath.vector3(x, y, 0) end
local function with_alpha(c, a) return vmath.vector4(c.x, c.y, c.z, a) end

local function places(n)
	local xs = {}
	for i = 1, n do xs[i] = 640 + (i - (n + 1) / 2) * STEP end
	return xs
end

-- An empty place: the tag's outline, faint, with a ring that breathes
local function empty_place(x, parent)
	local h = tag.TALL()
	local root, border = ui.pannello(x, TOP - h / 2, tag.WIDE, h, parent)
	gui.set_color(root, with_alpha(C.PANEL, 0.55))
	gui.set_color(border, with_alpha(C.LINE, 0.5))
	local ring = ui.ring_node(0, 30, 64, 3, with_alpha(C.LIGHT, 0.35), root)
	local label = ui.testo(T.coming, 0, -30, 0.8, C.OFF, root)
	return { root = root, ring = ring, label = label }
end

function M.new(of, title, parent_below)
	local s = { of = of, t = 0, tip_t = 0, tip_i = 1, card_list = {}, empty = {}, n = 0 }
	s.radice = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_visible(s.radice, false)
	-- the gear and its wheel stay above the room
	if parent_below then gui.move_below(s.radice, parent_below) end
	s.testa = gui.new_box_node(vec(640, 640), vec(0, 0))
	gui.set_visible(s.testa, false)
	gui.set_parent(s.testa, s.radice)
	ui.titolo(T.searching, 0, 22, 0.75, C.LIGHT, s.testa)
	s.riga = ui.testo("", 0, -22, 0.85, C.OFF, s.testa)
	s.xs = places(of)
	local w = 980
	ui.pannello(640, 110, w, 52, s.radice)
	s.tip = ui.testo(M.TIPS[1], 640, 110, 0.8, C.TEXT, s.radice)
	s.buttons = {}
	s.back = ui.button(s.buttons, 440, 44, 380, 52, T.back_to_menus, "menu", { scala = 0.72 }, s.radice)
	s.exit = ui.button(s.buttons, 860, 44, 380, 52, T.leave_queue, "esci", { scala = 0.72 }, s.radice)
	s.title = title
	M.update(s, 0)
	return s
end

-- Rebuilds the places: few nodes and rare (one join or leave), the simplest way
function M.giocatori(s, showcases)
	for _, c in ipairs(s.card_list) do tag.destroy(c) end
	for _, e in ipairs(s.empty) do gui.delete_node(e.root) end
	s.card_list, s.empty = {}, {}
	for i = 1, s.of do
		local v = showcases[i]
		if v then
			local c = tag.new(v, s.xs[i], TOP, { tu = v.tu }, s.radice)
			s.card_list[#s.card_list + 1] = c
			-- whoever just arrived comes in with a small jump
			if i > s.n then
				gui.set_scale(c.root, vec(0.9, 0.9))
				gui.animate(c.root, "scale", vec(1, 1), gui.EASING_OUTBACK, 0.25)
			end
		else
			s.empty[#s.empty + 1] = empty_place(s.xs[i], s.radice)
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
	-- the empty rings breathe, all together
	local a = 0.25 + 0.2 * (0.5 + 0.5 * math.sin(s.t * 3))
	for _, e in ipairs(s.empty) do gui.set_color(e.ring, with_alpha(C.LIGHT, a)) end
	for _, c in ipairs(s.card_list) do tag.update(c, dt) end
	s.tip_t = s.tip_t + dt
	if s.tip_t >= M.TIP_EVERY then
		s.tip_t = 0
		s.tip_i = s.tip_i % #M.TIPS + 1
		gui.set_text(s.tip, M.TIPS[s.tip_i])
		gui.set_color(s.tip, with_alpha(C.TEXT, 0))
		gui.animate(s.tip, "color.w", 1, gui.EASING_OUTQUAD, 0.3)
	end
end

function M.wheel_open(s, open)
	gui.set_enabled(s.testa, not open)
end

function M.destroy(s)
	if s.radice then gui.delete_node(s.radice) end
	s.radice = nil
end

return M
