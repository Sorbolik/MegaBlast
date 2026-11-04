-- The lineup (character sheet, Sergio 31 Oct): before the weapon draft
-- everyone's tags (ui/tag_card.lua), the teams facing each other. It is the
-- moment when there is time to look, and it matters: weapons are picked face
-- down, so knowing the other one has the double jump makes you pick better. It
-- lasts SECONDI (config.LINEUP_SECONDS) or until a tap. During the draft the
-- tags stay at the top in a strip: a tap on one opens it, another tap closes it.
--
--   local s = schieramento.new(vetrine, titolo)  -- vetrine: one per robot (menu/showcase.lua)
--   schieramento.update(s, dt) -> true when it is over (time or tap)
--   schieramento.on_input(s, action_id, action)
--   schieramento.destroy(s)
--
--   local st = schieramento.strip(vetrine)       -- the strip at the top during the draft (st.covers_corner:
--                                                -- it reaches over the wheel, menu/pick.lua under_strip)
--   schieramento.strip_touch(st, action_id, action) -> true if the tap was its own
--   schieramento.destroy(st)

local ui = require "ui.ui"
local screen = require "ui.screen"
local config = require "sim.config"
local tag = require "ui.tag_card"
local T = require("lang.text").lineup

local M = {}

local C = ui.C
local W, H = 1280, 720
local TOUCH = hash("touch")
local TOP = 616          -- where a tag starts
local STRIP_Y, STRIP_W, STRIP_H = 680, 284, 56

local function vec(x, y) return vmath.vector3(x, y, 0) end
local function with_alpha(c, a) return vmath.vector4(c.x, c.y, c.z, a) end

-- The tags' x: two teams on the sides of the center (in free-for-all in a
-- row). squads: each robot's team
function M.posti(squads)
	local n = #squads
	local teams = {}
	for _, t in ipairs(squads) do teams[t] = true end
	local how_many = 0
	for _ in pairs(teams) do how_many = how_many + 1 end
	local xs = {}
	if n == 2 then return { 640 - 175, 640 + 175 }, true end
	if n == 4 and how_many == 2 then
		-- first the first one's team, on the left; then the other, on the right
		local sx, dx = {}, {}
		for i, t in ipairs(squads) do
			if t == squads[1] then sx[#sx + 1] = i else dx[#dx + 1] = i end
		end
		local pos = { 163, 469, 811, 1117 }
		for k, i in ipairs(sx) do xs[i] = pos[k] end
		for k, i in ipairs(dx) do xs[i] = pos[2 + k] end
		return xs, true
	end
	local step = 306
	local x0 = 640 - (n - 1) * step / 2
	for i = 1, n do xs[i] = x0 + (i - 1) * step end
	return xs, false
end

function M.new(showcases, title)
	local s = { vetrine = showcases, card_list = {}, t = config.LINEUP_SECONDS }
	s.fondo = ui.sfondo()
	-- title and time stick to the real edges: only a node without a parent sticks
	local top_left = gui.new_box_node(vec(44, H - 34), vec(0, 0))
	gui.set_visible(top_left, false)
	gui.set_xanchor(top_left, gui.ANCHOR_LEFT)
	gui.set_yanchor(top_left, gui.ANCHOR_TOP)
	local t = ui.titolo(title, 0, 0, 0.75, C.LIGHT, top_left)
	gui.set_pivot(t, gui.PIVOT_W)
	local under = ui.testo(T.tap_to_pick, 2, -40, 0.75, C.OFF, top_left)
	gui.set_pivot(under, gui.PIVOT_W)
	local top_right = gui.new_box_node(vec(W - 44 - 115, H - 52), vec(0, 0))
	gui.set_visible(top_right, false)
	gui.set_xanchor(top_right, gui.ANCHOR_RIGHT)
	gui.set_yanchor(top_right, gui.ANCHOR_TOP)
	s.angoli = { top_left, top_right }
	s.radice = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_visible(s.radice, false)
	ui.pannello(0, 0, 230, 58, top_right)
	local armi = ui.testo(T.weapons_in, -24, 0, 0.85, C.OFF, top_right)
	gui.set_pivot(armi, gui.PIVOT_E)
	s.tally = ui.testo("", -12, 0, 0.95, C.LIGHT, top_right)
	gui.set_pivot(s.tally, gui.PIVOT_W)

	local squads = {}
	for i, v in ipairs(showcases) do squads[i] = v.squadra end
	local xs, vs = M.posti(squads)
	for i, v in ipairs(showcases) do
		v.verso = xs[i] < 640 and 1 or -1
		s.card_list[i] = tag.new(v, xs[i], TOP, { portrait = true, tu = v.tu }, s.radice)
	end
	if vs then
		ui.titolo(T.versus, 640, TOP - 260, 0.75, C.OFF, s.radice)
		-- a line in each team's color above its tags
		local per = {}
		for i, v in ipairs(showcases) do
			local p = per[v.squadra] or { min = 9999, max = -9999 }
			p.min, p.max = math.min(p.min, xs[i]), math.max(p.max, xs[i])
			per[v.squadra] = p
		end
		for team, p in pairs(per) do
			local w = p.max - p.min + tag.WIDE
			local n = gui.new_box_node(vec((p.min + p.max) / 2, TOP + 10), vec(w, 3))
			gui.set_color(n, C.SQUADRA[team] or C.LIGHT)
			gui.set_parent(n, s.radice)
		end
	end
	M.update(s, 0)
	return s
end

function M.update(s, dt)
	for _, c in ipairs(s.card_list or {}) do tag.update(c, dt) end
	if not s.t then return false end
	s.t = s.t - dt
	if s.tally then gui.set_text(s.tally, string.format("0:%02d", math.max(0, math.ceil(s.t)))) end
	return s.t <= 0 or s.touched
end

function M.on_input(s, action_id, action)
	if (action_id == TOUCH and action.released) or (action_id == ui.PAD and action.pressed) then
		s.touched = true
	end
end

-- The strip at the top during the draft: a small tag per robot
function M.strip(showcases)
	local st = { vetrine = showcases, mini = {} }
	st.radice = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_visible(st.radice, false)
	local squads = {}
	for i, v in ipairs(showcases) do squads[i] = v.squadra end
	local xs = M.posti(squads)
	for i, v in ipairs(showcases) do
		-- the draft's wheel (64 x 64 at 30 from the top left corner of the real
		-- screen) with ESCI next to it (160 wide): with four tags at 16:9 and at 20:9
		-- the strip reaches over it, at 4:3 it stays below
		if xs[i] - STRIP_W / 2 < screen.x0 + 30 + 64 + 12 + 160 + 8
			and STRIP_Y + STRIP_H / 2 > screen.y1 - 30 - 64 - 8 then
			st.covers_corner = true
		end
		local col = C.SQUADRA[v.squadra] or C.LIGHT
		local n, border = ui.pannello(xs[i], STRIP_Y, STRIP_W, STRIP_H, st.radice)
		gui.set_color(border, v.tu and col or with_alpha(col, 0.6))
		local sx = -STRIP_W / 2 + 12
		ui.ring_node(sx + 17, 0, 34, 2.5, col, n)
		ui.testo(v.livello and tostring(v.livello) or v.bot and T.bot or "–", sx + 17, 0, (v.livello or not v.bot) and 0.75 or 0.5, col, n)
		local nome = ui.titolo(v.nome or "?", sx + 42, 8, 0.4, C.LIGHT, n)
		gui.set_pivot(nome, gui.PIVOT_W)
		-- the four pieces in small: a little square with the tier border and the level
		for k, p in ipairs(v.pezzi or {}) do
			local x = sx + 50 + (k - 1) * 24
			local q = gui.new_box_node(vec(x, -12), vec(20, 20))
			gui.set_color(q, not p.set and with_alpha(C.LIGHT, 0.12) or p.tier >= 3 and C.GOLD or p.tier == 2 and C.STEEL
				or with_alpha(C.LIGHT, 0.5))
			gui.set_parent(q, n)
			local d = gui.new_box_node(vec(0, 0), vec(16, 16))
			gui.set_color(d, C.BOTTOM)
			gui.set_parent(d, q)
			if p.set then ui.testo(tostring(p.livello), 0, 0, 0.5, C.LIGHT, q) end
		end
		local bx = STRIP_W / 2 - 14
		for k = #(v.badge or {}), 1, -1 do
			tag.badge(v.badge[k], bx, -12, 18, n)
			bx = bx - 22
		end
		local abilities = #(v.abilities or {})
		if abilities > 0 then
			local t = ui.testo((abilities == 1 and T.power or T.powers):format(abilities), STRIP_W / 2 - 14, 10, 0.5, C.GOLD, n)
			gui.set_pivot(t, gui.PIVOT_E)
		end
		st.mini[i] = n
	end
	return st
end

-- A tap on the strip: opens the tag tapped; with the tag open any tap closes
-- it. true if the tap belonged to the strip
function M.strip_touch(st, action_id, action)
	if action_id ~= TOUCH or not st.radice then return false end
	if st.aperto then
		if action.pressed then
			tag.destroy(st.aperto)
			gui.delete_node(st.veil)
			st.aperto, st.veil = nil, nil
			st.eats = true
		end
		return true
	end
	if st.eats then
		-- the finger that closed the tag: its release is ours too
		if action.released then st.eats = nil end
		return true
	end
	if not action.pressed then return false end
	for i, n in ipairs(st.mini) do
		if gui.pick_node(n, action.x, action.y) then
			st.veil = gui.new_box_node(vec(W / 2, H / 2), vec(W * screen.FULL, H * screen.FULL))
			gui.set_color(st.veil, with_alpha(C.BOTTOM, 0.8))
			gui.set_parent(st.veil, st.radice)
			local v = st.vetrine[i]
			v.verso = 1
			st.aperto = tag.new(v, W / 2, 360 + tag.TALL({ portrait = true }) / 2, { portrait = true, tu = v.tu }, st.radice)
			st.eats = true
			return true
		end
	end
	return false
end

function M.update_strip(st, dt)
	if st.aperto then tag.update(st.aperto, dt) end
end

function M.destroy(s)
	for _, n in ipairs(s.angoli or {}) do gui.delete_node(n) end
	s.angoli = nil
	if s.radice then gui.delete_node(s.radice) end
	if s.fondo then gui.delete_node(s.fondo) end
	s.radice, s.fondo, s.aperto = nil, nil, nil
end

return M
