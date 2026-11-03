-- The transitions between screens (Sergio, 1 Nov), with a single veil over everything
-- (ui/passaggio.fp):
--   iris    between the home (or the menus) and the battle: the circle of old cartoons
--           closes on black, the scene changes, it opens again (150 + 150 ms)
--   slide   between menus: the old screen slides 7% to the left and fades
--           into the charcoal, the new one comes from the right (80 + 80 ms);
--           the other way round when going back
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

local M = {}

local W, H = 1280, 720
M.IRIS = 0.15           -- seconds to close, and to open again
M.SLIDE = 0.08          -- half of the slide
M.SHIFT = W * 0.07      -- how far a screen slides
M.HOLD_FRAMES = 3       -- frames with the screen covered after the scene change

function M.new()
	local n = gui.new_box_node(vmath.vector3(W / 2, H / 2, 0), vmath.vector3(W * screen.FULL, H * screen.FULL, 0))
	gui.set_adjust_mode(n, gui.ADJUST_FIT)
	gui.set_material(n, "passaggio")
	gui.set_enabled(n, false)
	return { nodo = n, colore = vmath.vector4(1, 0, 0, 0) }
end

function M.is_active(p)
	return p.n ~= nil
end

-- on top of everything, even of the nodes created just now
local function over_it(p)
	gui.move_above(p.nodo, nil)
end

local function begin(p, r, g, a)
	p.n = (p.n or 0) + 1
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
