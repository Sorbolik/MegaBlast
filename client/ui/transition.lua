-- The transitions between screens (Sergio, 1 Nov), with a single veil over everything
-- (ui/transition.fp):
--   iris    between the home (or the menus) and the battle: the circle of old cartoons
--           closes on black, the scene changes, it opens again (150 + 150 ms)
--   flame   into a campaign mission, after AVANTI on its postcard (Sergio, 4 Nov:
--           half a second of hype instead of crashing onto the map): on black
--           the map loads, then Favilla's flame (the entry's paper disc) flickers,
--           swells and bursts into sparks, and the hole opens on the map from it
--           (about 0.55 s after the load). A tap jumps to the burst
--   tent    between menus: a slanted yellow panel with a sand edge crosses the
--           screen in front of everything (240 + 300 ms) and behind it the scene
--           changes; from the other side when going back
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
--   passaggio.tent(p, change, toward)              -- toward 1 forward, -1 back
--   passaggio.is_active(p)

local screen = require "ui.screen"
local ui = require "ui.ui"
local frames = require "ui.frames"

local M = {}

local W, H = 1280, 720
M.IRIS = 0.15           -- seconds to close, and to open again
M.TENT_IN, M.TENT_OUT = 0.24, 0.3   -- the tent covers the screen, then leaves
M.HOLD_FRAMES = 3       -- frames with the screen covered after the scene change
-- the flame: it lights (from small, with a flicker), swells, bursts while the hole opens
M.FLAME_IN, M.FLAME_SWELL, M.FLAME_OPEN = 0.16, 0.14, 0.24
M.FLAME_D = 140         -- the disc's diameter
M.SPARKS = 10
local FLAME_CARD = vmath.vector4(0.94, 0.9, 0.82, 1)
local EMBER = vmath.vector4(1, 0.55, 0.16, 1)
local TENT = vmath.vector4(1, 0.74, 0.1, 1)             -- #ffbd1a, the action's yellow (ui/kit.lua)
local TENT_EDGE = vmath.vector4(0.96, 0.89, 0.75, 1)    -- sand
local TENT_DARK = vmath.vector4(0.09, 0.043, 0.047, 0.55)

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

-- (while the tent leaves, the new screen is there and listens already)
function M.is_active(p)
	return p.n ~= nil and not p.leaving
end

-- on top of everything, even of the nodes created just now
local function over_it(p)
	gui.move_above(p.nodo, nil)
	if p.tent and gui.is_enabled(p.tent.nodo) then gui.move_above(p.tent.nodo, nil) end
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

local TENT_W = 2100     -- covers the widest screen, slanted
-- the tent's nodes, made the first time it is used: a slanted panel in the
-- action's color with a sand edge on both sides and a dark line inside
local function tent_nodes(p)
	if p.tent then return p.tent end
	local t = {}
	t.nodo = gui.new_box_node(vmath.vector3(W / 2, H / 2, 0), vmath.vector3(0, 0, 0))
	gui.set_visible(t.nodo, false)
	gui.set_adjust_mode(t.nodo, gui.ADJUST_FIT)
	local tall = H * 2.2
	local function band(x, w, color)
		local n = gui.new_box_node(vmath.vector3(x, 0, 0), vmath.vector3(w, tall, 0))
		gui.set_color(n, color)
		gui.set_parent(n, t.nodo)
		return n
	end
	-- wide enough for every screen (the real one may be wider than 1280)
	local wide = TENT_W
	band(0, wide, TENT)
	for _, side in ipairs({ -1, 1 }) do
		band(side * (wide / 2 - 70), 14, TENT_DARK)
		band(side * (wide / 2 + 13), 26, TENT_EDGE)
	end
	gui.set_rotation(t.nodo, vmath.vector3(0, 0, -14))
	gui.set_enabled(t.nodo, false)
	p.tent = t
	return t
end

-- Between two menus (Sergio, 11 Nov: «transizioni fighe, soprattutto questa con
-- l'overlay che passa davanti»): the tent crosses the screen, and behind it the
-- scene changes. toward 1: from left to right; -1 (going back): the other way
function M.tent(p, change, toward)
	toward = toward or 1
	local t = tent_nodes(p)
	begin(p, 0, 1, 0)
	gui.set_enabled(t.nodo, true)
	gui.move_above(t.nodo, nil)
	gui.cancel_animations(t.nodo, "position.x")
	local pos = gui.get_position(t.nodo)
	local far = TENT_W / 2 + screen.width() / 2 + 240
	pos.x = W / 2 - toward * far
	gui.set_position(t.nodo, pos)
	gui.animate(t.nodo, "position.x", W / 2, gui.EASING_INSINE, M.TENT_IN, 0, function()
		covered(p, change, function()
			local k = p.n
			p.leaving = true
			gui.animate(t.nodo, "position.x", W / 2 + toward * far, gui.EASING_OUTSINE, M.TENT_OUT, 0, function()
				gui.set_enabled(t.nodo, false)
				-- (unless another transition started meanwhile: that one ends it)
				if p.n == k then end_of(p) end
			end)
		end)
	end)
end

return M
