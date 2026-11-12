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
--   local st = schieramento.strip(vetrine)       -- the strip at the top during the draft
--   schieramento.strip_touch(st, action_id, action) -> true if the tap was its own
--   schieramento.destroy(st)

local ui = require "ui.ui"
local screen = require "ui.screen"
local config = require "sim.config"
local tag = require "ui.tag_card"
local kit = require "ui.kit"
local T = require("lang.text").lineup
local NO_POWER = require("lang.text").tag_card.no_power
local common = require("lang.text").common

local M = {}

local C = ui.C
local W, H = 1280, 720
local TOUCH = hash("touch")
local KC = kit.C
local TAG_W, TAG_H = 236, 340

local function vec(x, y) return vmath.vector3(x, y, 0) end
local function with_alpha(c, a) return vmath.vector4(c.x, c.y, c.z, a) end

-- The tags' x: two teams on the sides of the center (in free-for-all in a
-- row). squads: each robot's team
function M.seats(squads)
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

-- Where the short tags stand, in the same order as the strip's places: two
-- and two around the VS, or in a row
local SHORT = { [2] = { 380, 900 }, [4] = { 174, 418, 838, 1082 } }

function M.new(showcases, title)
	local s = { vetrine = showcases, card_list = {}, t = config.LINEUP_SECONDS }
	local squads = {}
	for i, v in ipairs(showcases) do squads[i] = v.squadra end
	local xs, vs = M.seats(squads)
	-- a dark sheet over the draft, and the backdrop on it
	s.scene = kit.scene(640, 360, { dim = 0.72 })
	-- the match's name on a light plate that comes out of the real left edge
	local top_left = kit.anchor(0, 0, gui.ANCHOR_LEFT, gui.ANCHOR_TOP)
	kit.sand(top_left, -20, 30, 330, 58, KC.HOT, { sk = 22 })
	local name = kit.text(top_left, title, 40, 71, 32, KC.INK)
	local wide = kit.width(name)
	if wide > 270 then
		local sc = gui.get_scale(name)
		gui.set_scale(name, vec(sc.x * 270 / wide, sc.y * 270 / wide))
	end
	local low = kit.anchor(0, 720, gui.ANCHOR_LEFT, gui.ANCHOR_BOTTOM)
	kit.text(low, T.tap_to_pick, 80, 640, 15, KC.MUTE, "start", 1.5)
	local right = kit.anchor(1280, 720, gui.ANCHOR_RIGHT, gui.ANCHOR_BOTTOM)
	local go = kit.action(right, T.weapons, 930, 560, 270, 84, { size = 54, sub = T.weapons_in:format(0, 0) })
	s.tally = go.sub
	s.angoli = { top_left.node, low.node, right.node }
	s.radice = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_visible(s.radice, false)
	local g = { node = s.radice, ox = 0, oy = 720 }

	-- the tags: from left to right one up and one down
	local order = {}
	for i = 1, #showcases do order[i] = i end
	table.sort(order, function(a, b) return xs[a] < xs[b] or (xs[a] == xs[b] and a < b) end)
	local short = vs and SHORT[#order]
	for rank, i in ipairs(order) do
		local v = showcases[i]
		if short then xs[i] = short[rank] else xs[i] = 640 + (rank - (#order + 1) / 2) * 246 end
		v.verso = xs[i] < 640 and 1 or -1
		local power = (v.abilities or {})[1]
		s.card_list[i] = tag.small(g, v, xs[i] - TAG_W / 2, 150 + ((rank - 1) % 2) * 26, TAG_W, TAG_H,
			{ sel = v.tu, role = power or NO_POWER })
		kit.pop(s.card_list[i].root, 0.05 + rank * 0.07, 0.25)
	end
	if vs then
		kit.text(g, T.versus, 634, 360, 84, KC.SAND, "middle")
		kit.text(g, T.versus, 630, 356, 84, KC.HOT, "middle")
	end
	M.update(s, 0)
	return s
end

function M.update(s, dt)
	for _, c in ipairs(s.card_list or {}) do tag.update(c, dt) end
	if not s.t then return false end
	s.t = s.t - dt
	local left = math.max(0, math.ceil(s.t))
	if s.tally then gui.set_text(s.tally, T.weapons_in:format(math.floor(left / 60), left % 60)) end
	return s.t <= 0 or s.touched
end

function M.on_input(s, action_id, action)
	if (action_id == TOUCH and action.released) or (action_id == ui.PAD and action.pressed) then
		s.touched = true
	end
end

-- The strip at the top during the draft: a small plate per robot, its name on
-- the team's color, the two teams apart
function M.strip(showcases)
	local st = { vetrine = showcases, mini = {} }
	st.radice = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_visible(st.radice, false)
	local g = { node = st.radice, ox = 0, oy = 720 }
	local squads = {}
	for i, v in ipairs(showcases) do squads[i] = v.squadra end
	local xs, vs = M.seats(squads)
	local order = {}
	for i = 1, #showcases do order[i] = i end
	table.sort(order, function(a, b) return xs[a] < xs[b] or (xs[a] == xs[b] and a < b) end)
	for rank, i in ipairs(order) do
		local v = showcases[i]
		local x = 330 + (rank - 1) * 170 + (vs and rank > #order / 2 and 40 or 0)
		st.mini[i] = kit.rect(g, x, 26, 150, 38, with_alpha(KC.INK, 0.5))
		kit.rect(g, x, 26, 5, 38, C.SQUADRA[v.squadra] or C.LIGHT)
		local name = kit.text(g, kit.upper(v.nome or "?"), x + 22, 52, 16, KC.SAND)
		local wide = kit.width(name)
		if wide > 118 then
			local sc = gui.get_scale(name)
			gui.set_scale(name, vec(sc.x * 118 / wide, sc.y * 118 / wide))
		end
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
	if s.scene then kit.scene_drop(s.scene) end
	s.scene = nil
	s.radice, s.aperto = nil, nil
end

return M
