-- The transitions between screens (Sergio, 1 Nov), with a single veil over everything
-- (ui/transition.fp):
--   iris    between the home (or the menus) and the battle: the circle of old cartoons
--           closes on black, the scene changes, it opens again (150 + 150 ms)
--   flame   into a campaign mission, after AVANTI on its postcard (Sergio, 4 Nov:
--           half a second of hype instead of crashing onto the map): on black
--           the map loads, then Favilla's flame (the entry's paper disc) flickers,
--           swells and bursts into sparks, and the hole opens on the map from it
--           (about 0.55 s after the load). A tap jumps to the burst
--   pieces  between menus (Sergio, 18 Nov, instead of the temper): the old pieces
--           go back to their edges, the backdrop changes in a flash, the new
--           pieces come in from their edges one after the other
-- While a transition runs the game doesn't listen to taps (is_active).
-- After the scene change the veil stays closed HOLD_FRAMES more frames: the change
-- frame (paintings, mask, the new screen's nodes) is long, and often the one
-- after too, so the stutters fall while the screen is covered and the reopening
-- animation doesn't skip. Meanwhile the frame counter (ui/frames.lua) knows they are not seen.
--
--   local passaggio = require "ui.transition"
--   local p = passaggio.new()
--   passaggio.iris(p, change)                      -- change(): the new scene
--   passaggio.flame(p, change, done)               -- done(): the map is uncovered
--   passaggio.skip(p)                              -- a tap during the flame
--   passaggio.pieces(p, change, old)               -- change() returns the new top nodes
--   passaggio.is_active(p)

local screen = require "ui.screen"
local ui = require "ui.ui"
local frames = require "ui.frames"

local M = {}

local W, H = 1280, 720
M.IRIS = 0.15           -- seconds to close, and to open again
M.HOLD_FRAMES = 3       -- frames with the screen covered after the scene change
-- the flame: it lights (from small, with a flicker), swells, bursts while the hole opens
M.FLAME_IN, M.FLAME_SWELL, M.FLAME_OPEN = 0.16, 0.14, 0.24
M.FLAME_D = 140         -- the disc's diameter
M.SPARKS = 10
local FLAME_CARD = vmath.vector4(0.94, 0.9, 0.82, 1)
local EMBER = vmath.vector4(1, 0.55, 0.16, 1)

function M.new()
	local n = gui.new_box_node(vmath.vector3(W / 2, H / 2, 0), vmath.vector3(W * screen.FULL, H * screen.FULL, 0))
	gui.set_adjust_mode(n, gui.ADJUST_FIT)
	gui.set_material(n, "passaggio")
	gui.set_enabled(n, false)
	return { nodo = n, colore = vmath.vector4(1, 0, 0, 0) }
end

-- the flame's nodes, made the first time it is used
local function flame_nodes(p)
	if p.flame then return p.flame end
	local f = { sparks = {} }
	f.nodo = gui.new_box_node(vmath.vector3(640, 360, 0), vmath.vector3(0, 0, 0))
	gui.set_visible(f.nodo, false)
	f.disco = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(M.FLAME_D, M.FLAME_D, 0))
	gui.set_texture(f.disco, "ui")
	gui.play_flipbook(f.disco, "favilla")
	gui.set_color(f.disco, FLAME_CARD)
	gui.set_parent(f.disco, f.nodo)
	for i = 1, M.SPARKS do f.sparks[i] = ui.disc(0, 0, 14, EMBER, f.nodo) end
	gui.set_enabled(f.nodo, false)
	p.flame = f
	return f
end

-- (while the new pieces come in, the new screen is there and listens already)
function M.is_active(p)
	return p.n ~= nil and not p.leaving
end

-- on top of everything, even of the nodes created just now
local function over_it(p)
	gui.move_above(p.nodo, nil)
end

local function begin(p, r, g, a)
	p.n = (p.n or 0) + 1
	p.leaving = nil
	-- a new transition starts from an uncovered screen (even if one was waiting)
	frames.covered = false
	local c = p.colore
	c.x, c.y, c.z, c.w = r, g, 0, a
	gui.set_color(p.nodo, c)
	gui.set_enabled(p.nodo, true)
	-- on top of everything, even of the screens created later
	over_it(p)
end

local function end_of(p)
	p.leaving = nil
	gui.set_enabled(p.nodo, false)
	frames.covered = false
	p.n = nil
end

-- With the screen covered: changes the scene, then reopens (reopen) after HOLD_FRAMES frames
local function covered(p, change, reopen)
	frames.covered = true
	local news = change()
	over_it(p)
	local k = p.n
	local function after_step(frame)
		-- if another transition started meanwhile, that one closes it
		if p.n ~= k then return end
		-- the new screen sometimes creates nodes in the following frames too (the HUD)
		over_it(p)
		if frame > 0 then
			timer.delay(0, false, function() after_step(frame - 1) end)
		else
			frames.covered = false
			reopen(news)
		end
	end
	after_step(M.HOLD_FRAMES)
end

function M.iris(p, change)
	begin(p, 1, 0, 1)
	gui.animate(p.nodo, "color.x", 0, gui.EASING_INQUAD, M.IRIS, 0, function()
		-- it reopens on a black screen three frames later (Sergio, 2 Nov: «qualche
		-- scatto in più ... nelle schermate di transizione»)
		covered(p, change, function()
			gui.animate(p.nodo, "color.x", 1, gui.EASING_OUTQUAD, M.IRIS, 0, function() end_of(p) end)
		end)
	end)
end

local function burst(p, k, done)
	local f = p.flame
	if p.n ~= k or f.burst then return end
	f.burst = true
	gui.cancel_animations(f.disco, "scale")
	gui.cancel_animations(f.disco, "color.w")
	gui.animate(f.disco, "scale", vmath.vector3(2.4, 2.4, 1), gui.EASING_OUTQUAD, M.FLAME_OPEN * 0.8)
	gui.animate(f.disco, "color.w", 0, gui.EASING_OUTQUAD, M.FLAME_OPEN * 0.8)
	for i, s in ipairs(f.sparks) do
		local a = (i - 1) / M.SPARKS * 2 * math.pi + 0.3
		local r = 260 + (i % 3) * 90
		gui.set_enabled(s, true)
		gui.set_position(s, vmath.vector3(0, 0, 0))
		gui.set_scale(s, vmath.vector3(1, 1, 1))
		gui.set_color(s, EMBER)
		gui.animate(s, "position", vmath.vector3(math.cos(a) * r, math.sin(a) * r, 0), gui.EASING_OUTCUBIC, M.FLAME_OPEN * 1.6)
		gui.animate(s, "scale", vmath.vector3(0.3, 0.3, 1), gui.EASING_OUTQUAD, M.FLAME_OPEN * 1.6)
		gui.animate(s, "color.w", 0, gui.EASING_INQUAD, M.FLAME_OPEN * 1.6)
	end
	-- the hole starts at the disc's edge
	local c = p.colore
	c.x = M.FLAME_D * 0.6 / 1000
	gui.set_color(p.nodo, c)
	gui.animate(p.nodo, "color.x", 1, gui.EASING_INQUAD, M.FLAME_OPEN, 0, function()
		end_of(p)
		gui.set_enabled(f.nodo, false)
		p.on_skip = nil
		if done then done() end
	end)
end

function M.flame(p, change, done)
	local f = flame_nodes(p)
	begin(p, 0, 0, 1)
	local k = p.n
	f.burst = nil
	gui.set_enabled(f.nodo, false)
	covered(p, change, function()
		gui.set_enabled(f.nodo, true)
		gui.move_above(f.nodo, nil)
		for _, s in ipairs(f.sparks) do gui.set_enabled(s, false) end
		gui.set_scale(f.disco, vmath.vector3(0.3, 0.3, 1))
		local col = gui.get_color(f.disco)
		col.w = 0
		gui.set_color(f.disco, col)
		-- it lights with a flicker, then swells
		gui.animate(f.disco, "color.w", 1, gui.EASING_OUTQUAD, M.FLAME_IN * 0.5, 0, function()
			if f.burst then return end
			gui.animate(f.disco, "color.w", 0.7, gui.EASING_LINEAR, 0.04, 0, nil, gui.PLAYBACK_ONCE_PINGPONG)
		end)
		gui.animate(f.disco, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, M.FLAME_IN, 0, function()
			if f.burst then return end
			gui.animate(f.disco, "scale", vmath.vector3(1.25, 1.25, 1), gui.EASING_INOUTQUAD, M.FLAME_SWELL, 0, function()
				burst(p, k, done)
			end)
		end)
		p.on_skip = function() burst(p, k, done) end
	end)
end

-- a tap during the flame: straight to the burst (only once the map is there)
function M.skip(p)
	if p.on_skip then p.on_skip() end
end

-- Between two menus (Sergio, 18 Nov, proposal 2 of
-- https://claude.ai/artifact/AhCahtSiA6MHKeQXHP7bmf, instead of the temper):
-- nothing crosses the screen. The old screen's pieces go back to their edges,
-- the backdrop changes in a flash, the new screen's pieces come in from their
-- edges one after the other (the top, the left, the right, the middle, the
-- bottom). A piece is a top node of the screen (kit.anchor, ui.root): its
-- anchor, or where it is, says its edge.
--   old         the old screen's top nodes (they are put back where they were)
--   change()    makes the new screen and returns its top nodes
M.OUT, M.FADE, M.IN, M.STAGGER = 0.16, 0.14, 0.30, 0.045
-- how far a piece starts from its place, toward its edge
local AWAY = { top = { 0, 170 }, bottom = { 0, -190 }, left = { -380, 0 }, right = { 380, 0 }, middle = { 0, -50 } }
local ORDER = { top = 0, left = 1, right = 2, middle = 3, bottom = 4 }

local function edge_of(n)
	local p = gui.get_position(n)
	local xa, ya = gui.get_xanchor(n), gui.get_yanchor(n)
	if ya == gui.ANCHOR_TOP or p.y > 640 then return "top" end
	if ya == gui.ANCHOR_BOTTOM or p.y < 90 then return "bottom" end
	if xa == gui.ANCHOR_LEFT or p.x < 400 then return "left" end
	if xa == gui.ANCHOR_RIGHT or p.x > 880 then return "right" end
	return "middle"
end

local function alive(list)
	local out = {}
	for _, n in ipairs(list or {}) do
		if pcall(gui.get_position, n) then out[#out + 1] = n end
	end
	return out
end

function M.pieces(p, change, old)
	local kit = require "ui.kit"
	begin(p, 0, 1, 0)
	local k = p.n
	-- 1. the old pieces go to their edges, fast
	old = alive(old)
	local rest = {}
	for i, n in ipairs(old) do
		local e = edge_of(n)
		local a = AWAY[e]
		rest[i] = gui.get_position(n)
		gui.cancel_animations(n, "position")
		gui.animate(n, "position", rest[i] + vmath.vector3(a[1], a[2], 0), gui.EASING_INQUAD, M.OUT)
	end
	timer.delay(M.OUT * 0.7, false, function()
		if p.n ~= k then return end
		-- (put back where they were: the home's stay, hidden)
		for i, n in ipairs(alive(old)) do
			gui.cancel_animations(n, "position")
			if rest[i] then gui.set_position(n, rest[i]) end
		end
		-- 2. a still copy of the old backdrop over the new one fades out
		local still = kit.scene_still()
		local news = alive(change())
		kit.scene_still_fade(still, M.FADE)
		-- 3. the new pieces, at their edges, come in one after the other (two frames
		-- later: the frame that made the screen is long, the motion would skip)
		local from = {}
		for i, n in ipairs(news) do
			local e = edge_of(n)
			local a = AWAY[e]
			local at = gui.get_position(n)
			from[i] = { at = at, e = e }
			gui.cancel_animations(n, "position")
			gui.set_position(n, at + vmath.vector3(a[1], a[2], 0))
			if e == "middle" then gui.set_scale(n, vmath.vector3(0.94, 0.94, 1)) end
		end
		over_it(p)
		timer.delay(0, false, function() timer.delay(0, false, function()
			if p.n ~= k then return end
			p.leaving = true
			local last = 0
			for i, n in ipairs(alive(news)) do
				local f = from[i]
				local d = ORDER[f.e] * M.STAGGER
				last = math.max(last, d)
				gui.animate(n, "position", f.at, gui.EASING_OUTBACK, M.IN, d)
				if f.e == "middle" then gui.animate(n, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, M.IN, d) end
			end
			timer.delay(last + M.IN, false, function()
				if p.n == k then end_of(p) end
			end)
		end) end)
	end)
end

return M
