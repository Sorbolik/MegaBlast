-- The passage of the home's doors and of the ZAINO (Sergio, 14-15 Nov):
--   door   the button shoots toward its edge and brakes there; then the blade of
--          fire and ice of the menus (ui/transition.lua, temper) crosses the
--          screen and, under it, the new screen comes (Sergio, 15 Nov: the
--          sliding page didn't drag the backdrop, so it looked apart from it;
--          the blade covers everything). Arrived, the flat band of the door
--          (WB-049) stays on that edge: where you are. Back: the blade the
--          other way, and the button comes home from its edge
--   zaino  the ZAINO grows out of the apprentice and goes back into it
-- The new screen's top nodes are the ones kit.anchor and ui.root make while it
-- is open (kit.track): the ZAINO scales them.
--
--   local door_pass = require "ui.door_pass"
--   local dp = door_pass.new(passaggio)            -- passaggio: ui/transition.lua
--   door_pass.open(dp, home, id, change)           -- change(): makes the new screen
--   door_pass.close(dp, home, change)              -- change(): closes it, shows the home
--   door_pass.grow(dp, home, change, done)         -- the ZAINO
--   door_pass.shrink(dp, home, change, done)
--   door_pass.owns(dp)        -- a screen opened by a door or the apprentice: its way back is here
--   door_pass.drop(dp)        -- the screen went away by another way: the band with it
--   door_pass.is_active(dp)

local kit = require "ui.kit"
local screen = require "ui.screen"
local transition = require "ui.transition"
local home = require "menu.home"

local M = {}

-- the times: out to the edge, home again
M.OUT, M.IN = 0.30, 0.36
M.GROW, M.SHRINK = 0.42, 0.32
-- the edge's middle sits this far inside the screen's border
local EDGE = 17
local BAND_W = 48

local function vec(x, y) return vmath.vector3(x, y, 0) end

function M.new(passaggio)
	return { passaggio = passaggio }
end

function M.is_active(dp) return dp.busy == true end
function M.owns(dp) return dp.kind ~= nil end

-- the real offset of an anchored top node (ui/screen.lua): where it is drawn
-- minus its position
local function anchor_offset(n)
	local x, y = 0, 0
	local xa, ya = gui.get_xanchor(n), gui.get_yanchor(n)
	if xa == gui.ANCHOR_LEFT then x = screen.x0 elseif xa == gui.ANCHOR_RIGHT then x = screen.x1 - 1280 end
	if ya == gui.ANCHOR_BOTTOM then y = screen.y0 elseif ya == gui.ANCHOR_TOP then y = screen.y1 - 720 end
	return x, y
end

-- the screen's top nodes still alive
local function alive(list)
	local out = {}
	for _, n in ipairs(list or {}) do
		if pcall(gui.get_position, n) then out[#out + 1] = n end
	end
	return out
end

-- The flat band of the door down the whole edge (x: its middle, in the game's coordinates)
local function edge(dp, id, x)
	-- (not kit.anchor: it would count as one of the screen's nodes)
	local rn = gui.new_box_node(vec(0, 720), vec(0, 0))
	gui.set_visible(rn, false)
	local g = { node = rn, ox = 0, oy = 0 }
	local band = "banda_" .. id
	local m = kit.PIECES[band]
	local tile = BAND_W * m.h / m.w
	local y = 720 - screen.y1 - 30
	while y < 720 - screen.y0 + 30 do
		kit.pic(g, band, x - BAND_W / 2, y, BAND_W, tile)
		y = y + tile - 2
	end
	dp.edge = rn
end

local function drop_edge(dp)
	if dp.edge then gui.delete_node(dp.edge) end
	dp.edge = nil
end

-- DOORS ---------------------------------------------------------------------------

-- the door: its node, where it rests, how far it goes to put its shield on its edge
local function measure(h, id)
	local d = home.door_info(h, id)
	local ox = d.side < 0 and screen.x0 or screen.x1 - 1280
	local shield = d.side < 0 and 0.15 or 0.85   -- the shield's middle, along it
	d.edge_x = d.side < 0 and screen.x0 + EDGE or screen.x1 - EDGE
	d.dx = d.edge_x - (d.x + ox + shield * d.w)
	d.node = d.p.node
	d.rest = gui.get_position(d.node)
	return d
end

function M.open(dp, h, id, change)
	dp.busy = true
	local d = measure(h, id)
	-- 1. the button shoots to its edge and brakes
	gui.animate(d.node, "position.x", d.rest.x + d.dx, gui.EASING_OUTCUBIC, M.OUT, 0, function()
		-- 2. the blade crosses the screen from the door's side; under it the new screen
		transition.temper(dp.passaggio, function()
			kit.enter_begin(0)
			kit.track_begin()
			change()
			kit.enter_end()
			gui.set_position(d.node, d.rest)
			dp.kind, dp.door = "door", id
			edge(dp, id, d.edge_x)
			dp.busy = false
		end, -d.side)
	end)
end

function M.close(dp, h, change)
	if dp.kind == "zaino" then return M.shrink(dp, h, change) end
	dp.busy = true
	local d = measure(h, dp.door)
	kit.track_end()
	-- the blade the other way; under it the home, the button on its edge comes home
	transition.temper(dp.passaggio, function()
		change()
		drop_edge(dp)
		gui.set_position(d.node, vec(d.rest.x + d.dx, d.rest.y))
		gui.animate(d.node, "position.x", d.rest.x, gui.EASING_INOUTCUBIC, M.IN, 0.2, function()
			dp.kind, dp.busy = nil, false
		end)
	end, d.side)
end

-- the screen went another way (a mission, a match): the band goes with it
function M.drop(dp)
	if dp.busy then return end
	drop_edge(dp)
	kit.track_end()
	dp.kind = nil
end

-- ZAINO -------------------------------------------------------------------------

-- every top node scaled by k around the point (px, py) of the screen
local function around(nodes, k, px, py)
	for _, n in ipairs(nodes) do
		local p = gui.get_position(n)
		local ax, ay = anchor_offset(n)
		local rx, ry = p.x + ax, p.y + ay
		gui.set_position(n, vec(px + (rx - px) * k - ax, py + (ry - py) * k - ay))
		gui.set_scale(n, vmath.vector3(k, k, 1))
	end
end

-- from where they are now to scale `to` of their places `rest` (taken at scale 1)
local function grow_to(nodes, rest, px, py, to, easing, t, done)
	local left = #nodes
	if left == 0 then if done then done() end return end
	for i, n in ipairs(nodes) do
		local ax, ay = anchor_offset(n)
		local rx, ry = rest[i].x + ax, rest[i].y + ay
		local target = vec(px + (rx - px) * to - ax, py + (ry - py) * to - ay)
		gui.animate(n, "position", target, easing, t)
		gui.animate(n, "scale", vmath.vector3(to, to, 1), easing, t, 0, function()
			left = left - 1
			if left == 0 and done then done() end
		end)
	end
end

local function places(nodes)
	local rest = {}
	for i, n in ipairs(nodes) do rest[i] = gui.get_position(n) end
	return rest
end

function M.grow(dp, h, change, done)
	dp.busy = true
	-- the apprentice breathes first (menu/home.lua), then the ZAINO comes out of him
	timer.delay(0.3, false, function()
		local px, py = home.apprentice_point(h)
		kit.track_begin()
		change()
		dp.kind = "zaino"
		local page = alive(kit.tracked())
		local rest = places(page)
		around(page, 0.12, px, py)
		timer.delay(0.03, false, function()
			grow_to(page, rest, px, py, 1, gui.EASING_OUTBACK, M.GROW, function()
				dp.busy = false
				if done then done() end
			end)
		end)
	end)
end

function M.shrink(dp, h, change, done)
	dp.busy = true
	local px, py = home.apprentice_point(h)
	local page = alive(kit.tracked())
	kit.track_end()
	grow_to(page, places(page), px, py, 0.12, gui.EASING_INCUBIC, M.SHRINK, function()
		change()
		home.settle(h)
		dp.kind, dp.busy = nil, false
		if done then done() end
	end)
end

return M
