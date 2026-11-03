-- The transitions between screens (Sergio, 1 Nov), with a single veil over everything
-- (ui/passaggio.fp):
--   iris    between the home (or the menus) and the battle: the circle of old cartoons
--           closes on black, the scene changes, it opens again (150 + 150 ms)
--   slide   between menus: the old screen slides 7% to the left and fades
--           into the charcoal, the new one comes from the right (80 + 80 ms);
--           the other way round when going back
-- The iris has the logo in it (Sergio, 3 Nov: «quando si chiude finisce con quello e
-- quando si apre inizia con quello»): it is printed on the black, so the closing
-- circle uncovers it and the reopening one eats it from the center. No extra
-- time (Sergio: «non vorrei rinunciare alla velocità»): the logo fills the black
-- that is already there, the map loading's. It is an inverted stencil (a circle as big
-- as the hole, children visible only outside), moved together with the veil.
-- While a transition runs the game doesn't listen to taps (is_active).
-- After the scene change the veil stays closed HOLD_FRAMES more frames: the change
-- frame (paintings, mask, the new screen's nodes) is long, and often the one
-- after too, so the stutters fall while the screen is covered and the reopening
-- animation doesn't skip. Meanwhile the frame counter (ui/fotogrammi.lua) knows they are not seen.
--
--   local passaggio = require "ui.passaggio"
--   local p = passaggio.new()
--   passaggio.iris(p, change)                      -- change(): the new scene
--   passaggio.slider(p, old_ones, change, toward)  -- old_ones: the root nodes of the
--        current screen; change() returns the new one's; toward 1 forward, -1 back
--   passaggio.is_active(p)

local screen = require "ui.schermo"
local frames = require "ui.fotogrammi"
local ui = require "ui.ui"

local M = {}

local W, H = 1280, 720
M.IRIS = 0.15           -- seconds to close, and to open again
M.SLIDE = 0.08         -- half of the slide
M.SHIFT = W * 0.07      -- how far a screen slides
M.HOLD_FRAMES = 3        -- frames with the screen covered after the scene change
local CARD = vmath.vector4(0.94, 0.9, 0.82, 1)

-- the iris logo: for now the entry screen's (ui/ingresso.lua), Favilla's head
-- in the paper disc and the name
local function logo()
	local hole = gui.new_pie_node(vmath.vector3(W / 2, H / 2, 0), vmath.vector3(0, 0, 0))
	gui.set_adjust_mode(hole, gui.ADJUST_FIT)
	gui.set_perimeter_vertices(hole, 96)
	gui.set_clipping_mode(hole, gui.CLIPPING_MODE_STENCIL)
	gui.set_clipping_inverted(hole, true)
	gui.set_clipping_visible(hole, false)
	local disc = gui.new_box_node(vmath.vector3(0, 40, 0), vmath.vector3(230, 230, 0))
	gui.set_adjust_mode(disc, gui.ADJUST_FIT)
	gui.set_texture(disc, "ui")
	gui.play_flipbook(disc, "favilla")
	gui.set_color(disc, CARD)
	gui.set_parent(disc, hole)
	local name_node = ui.titolo("MEGABLAST", 0, -125, 1.2, ui.C.LIGHT, hole)
	gui.set_adjust_mode(name_node, gui.ADJUST_FIT)
	gui.set_enabled(hole, false)
	return hole
end

function M.new()
	local n = gui.new_box_node(vmath.vector3(W / 2, H / 2, 0), vmath.vector3(W * screen.FULL, H * screen.FULL, 0))
	gui.set_adjust_mode(n, gui.ADJUST_FIT)
	gui.set_material(n, "passaggio")
	gui.set_enabled(n, false)
	return { nodo = n, colore = vmath.vector4(1, 0, 0, 0), logo = logo(), hole = vmath.vector3() }
end

function M.is_active(p)
	return p.n ~= nil
end

-- on top of everything, even of the nodes created just now (the logo above the veil)
local function over_it(p)
	gui.move_above(p.nodo, nil)
	gui.move_above(p.logo, p.nodo)
end

local function begin(p, r, g, a)
	p.n = (p.n or 0) + 1
	-- a new transition starts from an uncovered screen (even if one was waiting)
	frames.covered = false
	local c = p.colore
	c.x, c.y, c.z, c.w = r, g, 0, a
	gui.set_color(p.nodo, c)
	gui.set_enabled(p.nodo, true)
	gui.cancel_animations(p.logo, "size")
	gui.set_enabled(p.logo, false)
	-- on top of everything, even of the screens created later
	over_it(p)
end

local function end_of(p)
	gui.set_enabled(p.nodo, false)
	gui.set_enabled(p.logo, false)
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

-- the logo's hole as big as the veil's (radius = color.x * 1000 pixels)
local function set_hole(p, x, easing)
	local d = x * 2000
	p.hole.x, p.hole.y = d, d
	if easing then
		gui.animate(p.logo, "size", p.hole, easing, M.IRIS)
	else
		gui.set_size(p.logo, p.hole)
	end
end

function M.iris(p, change)
	begin(p, 1, 0, 1)
	set_hole(p, 1)
	gui.set_enabled(p.logo, true)
	set_hole(p, 0, gui.EASING_INQUAD)
	gui.animate(p.nodo, "color.x", 0, gui.EASING_INQUAD, M.IRIS, 0, function()
		-- it reopens on a black screen three frames later (Sergio, 2 Nov: «qualche
		-- scatto in più ... nelle schermate di transizione»)
		covered(p, change, function()
			set_hole(p, 1, gui.EASING_OUTQUAD)
			gui.animate(p.nodo, "color.x", 1, gui.EASING_OUTQUAD, M.IRIS, 0, function() end_of(p) end)
		end)
	end)
end

-- moves the nodes by dx (with an animation lasting t) and returns where they were
local function move(nodes, dx, t, easing)
	local was = {}
	for i, n in ipairs(nodes) do
		local x = gui.get_position(n).x
		was[i] = x
		if t > 0 then
			gui.animate(n, "position.x", x + dx, easing, t)
		else
			local pos = gui.get_position(n)
			pos.x = x + dx
			gui.set_position(n, pos)
		end
	end
	return was
end

local function put_back(nodes, was)
	for i, n in ipairs(nodes) do
		gui.cancel_animations(n, "position.x")
		local pos = gui.get_position(n)
		pos.x = was[i]
		gui.set_position(n, pos)
	end
end

function M.slider(p, old_ones, change, toward)
	toward = toward or 1
	begin(p, 0, 1, 0)
	local was = move(old_ones, -toward * M.SHIFT, M.SLIDE, gui.EASING_INQUAD)
	gui.animate(p.nodo, "color.w", 1, gui.EASING_INQUAD, M.SLIDE, 0, function()
		-- the old nodes go back in place (the home is reused), then the scene changes
		put_back(old_ones, was)
		-- here too the new screen arrives three frames later, under the full veil
		covered(p, function()
			local news = change() or {}
			return { news, move(news, toward * M.SHIFT, 0) }
		end, function(n)
			for i, gui_node in ipairs(n[1]) do
				gui.animate(gui_node, "position.x", n[2][i], gui.EASING_OUTQUAD, M.SLIDE)
			end
			gui.animate(p.nodo, "color.w", 0, gui.EASING_OUTQUAD, M.SLIDE, 0, function()
				end_of(p)
			end)
		end)
	end)
end

return M
