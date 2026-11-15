-- The passage of the home's doors and of the ZAINO (Sergio, 14-15 Nov):
--   door   the button shoots toward its edge and brakes there; then, coming
--          back, it drags the new screen in with it, backdrop and all, over
--          the home that stays still under it (Sergio, 15 Nov: «vorrei
--          semplicemente che si portasse l'altra pagina con sé»). The page's
--          edge is a thin orange line, the button rides on it pulling and goes
--          out over the screen's border just as the line gets there; the line
--          stays on that edge: where you are. Back: the button rides the line pushing the page out, the
--          home under it; it stops on its place with a small bounce and the
--          page goes on to the edge
--   zaino  the ZAINO grows out of the apprentice and goes back into it
-- The new screen's top nodes are the ones kit.anchor and ui.root make while it
-- is open (kit.track): the doors drag them, the ZAINO scales them.
--
--   local door_pass = require "ui.door_pass"
--   local dp = door_pass.new()
--   door_pass.open(dp, home, id, change)           -- change(): makes the new screen
--   door_pass.close(dp, home, change)              -- change(): closes it, shows the home
--   door_pass.grow(dp, home, change, done)         -- the ZAINO
--   door_pass.shrink(dp, home, change, done)
--   door_pass.owns(dp)        -- a screen opened by a door or the apprentice: its way back is here
--   door_pass.drop(dp)        -- the screen went away by another way: the line with it
--   door_pass.is_active(dp)

local kit = require "ui.kit"
local screen = require "ui.screen"
local home = require "menu.home"

local M = {}

-- the times: out to the edge, across (forward and back), home again; the
-- button slipping off the line and back on it
M.OUT, M.ACROSS, M.ACROSS_BACK, M.IN, M.SLIP = 0.30, 0.62, 0.52, 0.36, 0.14
M.GROW, M.SHRINK = 0.42, 0.32
-- back home, the button's bounce toward its edge as it stops on its place
M.BOUNCE = 14
-- forward, the part of the drag before the button starts going out with the line
M.LEAVE = 0.5
-- the shield's middle sits this far inside the screen's border
local EDGE = 17
-- the line: its ink and its orange core
local LINE, CORE = 12, 6

local function vec(x, y) return vmath.vector3(x, y, 0) end

function M.new()
	return {}
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

-- every node moved by `by` along x, over t seconds; done on a timer, not on the
-- nodes' callbacks: a screen that animates one of its own nodes' position under
-- the slide (the story opened by the CAMPAGNA) cancels that callback, and the
-- passage would stay busy for ever, with every touch swallowed
local function slide(nodes, by, easing, t, done)
	for _, n in ipairs(nodes) do
		local p = gui.get_position(n)
		gui.animate(n, "position.x", p.x + by, easing, t)
	end
	if done then
		if #nodes == 0 then done() else timer.delay(t, false, done) end
	end
end

local function shift(nodes, by)
	for _, n in ipairs(nodes) do
		local p = gui.get_position(n)
		gui.set_position(n, vec(p.x + by, p.y))
	end
end

local function join(...)
	local out = {}
	for _, l in ipairs({ ... }) do
		for _, n in ipairs(l) do out[#out + 1] = n end
	end
	return out
end

-- The page's edge: a thin orange line down the whole screen (x: its middle).
-- With M.EDGE "tempra" (tried on 15 Nov; Sergio, 11:16: the doors keep the line
-- alone, the temper everywhere else) while it drags it is a narrow blade of the temper (WB-051, ui/transition.lua): the
-- red-hot edge in front (dir: the side it faces, 1 right), the iron, the frost
-- behind; arrived, the blade fades and the line stays
-- (not kit.anchor: it would count as one of the screen's nodes)
M.EDGE = "linea"
local TALL = 720 * 2
local blade = {}   -- line -> its blade
local function column(parent, name, x, w)
	local m = kit.PIECES[name]
	local h = w * m.h / m.w
	local y = -TALL / 2
	while y < TALL / 2 do
		local n = gui.new_box_node(vec(x, y + h / 2), vec(w, h + 1))
		gui.set_texture(n, "fucina")
		gui.play_flipbook(n, name)
		gui.set_parent(n, parent)
		gui.set_inherit_alpha(n, true)
		y = y + h
	end
end

local function line(x, dir)
	local n = gui.new_box_node(vec(x, 360), vec(LINE, 720 * screen.FULL))
	gui.set_color(n, kit.C.INK)
	local core = gui.new_box_node(vec(0, 0), vec(CORE, 720 * screen.FULL))
	gui.set_color(core, kit.C.HOT)
	gui.set_parent(core, n)
	if M.EDGE == "tempra" then
		local b = gui.new_box_node(vec(0, 0), vec(0, 0))
		gui.set_visible(b, false)
		gui.set_parent(b, n)
		gui.set_scale(b, vmath.vector3(dir, 1, 1))
		column(b, "lama_gelo", -66, 36)
		column(b, "lama_corpo", -30, 60)
		column(b, "lama_fuoco", 14, 40)
		blade[n] = b
	end
	return n
end

-- the blade of a line: shown (alpha 1) or faded (0), over t seconds
local function blade_to(n, a, t)
	local b = n and blade[n]
	if not b then return end
	gui.cancel_animations(b, "color.w")
	gui.animate(b, "color.w", a, gui.EASING_OUTQUAD, t)
end

local function drop_line(dp)
	if dp.line then
		blade[dp.line] = nil
		gui.delete_node(dp.line)
	end
	dp.line = nil
end

-- the button over everything while it drags: a top node just where its own is
local function ride(d)
	local parent = gui.get_parent(d.node)
	local r = gui.new_box_node(gui.get_position(parent), vec(0, 0))
	gui.set_visible(r, false)
	gui.set_xanchor(r, gui.get_xanchor(parent))
	gui.set_yanchor(r, gui.get_yanchor(parent))
	gui.set_parent(d.node, r)
	gui.move_above(r, nil)
	d.parent, d.rider = parent, r
end

local function unride(d)
	gui.set_parent(d.node, d.parent)
	gui.delete_node(d.rider)
	gui.set_position(d.node, d.rest)
end

local function home_on(h, on)
	h.under = on
	for _, n in ipairs(h.tops) do gui.set_enabled(n, on) end
	gui.set_enabled(h.slit, false)
end

-- DOORS ---------------------------------------------------------------------------

-- the door: its node, where it rests, how far it goes to put its shield on its
-- edge; where the line ends (the other side) and how far the page travels
local function measure(h, id)
	local d = home.door_info(h, id)
	local ox = d.side < 0 and screen.x0 or screen.x1 - 1280
	local shield = d.side < 0 and 0.15 or 0.85   -- the shield's middle, along it
	d.edge_x = d.side < 0 and screen.x0 + EDGE or screen.x1 - EDGE
	d.dx = d.edge_x - (d.x + ox + shield * d.w)
	d.node = d.p.node
	d.rest = gui.get_position(d.node)
	d.line_x = d.side < 0 and screen.x1 - LINE / 2 or screen.x0 + LINE / 2
	-- the page starts with its edge on the shield
	d.p0 = d.edge_x - d.line_x
	-- off the line, out of the screen
	d.off = -d.side * (d.w * 0.2 + 30)
	return d
end

function M.open(dp, h, id, change)
	dp.busy = true
	local d = measure(h, id)
	-- 1. the button shoots to its edge and brakes
	gui.animate(d.node, "position.x", d.rest.x + d.dx, gui.EASING_OUTCUBIC, M.OUT, 0, function()
		-- 2. the new screen, made out of sight with its backdrop, its edge on the shield;
		-- the home stays under it, with a copy of the backdrop
		local still = kit.scene_copy(h.scene)
		kit.track_begin()
		change()
		dp.kind, dp.door = "door", id
		home_on(h, true)
		kit.scene_cut(true)
		dp.line = line(d.line_x, -d.side)
		local page = join(alive(kit.tracked()), kit.scene_tops(), { dp.line })
		shift(page, d.p0)
		ride(d)
		-- (a moment for the frame that made the screen, a long one)
		timer.delay(0.03, false, function()
			-- 3. the button drags it across, and in the last stretch it goes out
			-- over the screen's border with the line (Sergio, 15 Nov: it must not
			-- come off the edge, «lo dovrebbe accompagnare fino alla fine»)
			gui.animate(d.node, "position.x", d.rest.x + d.dx + d.off, gui.EASING_INOUTQUAD,
				M.ACROSS * (1 - M.LEAVE), M.ACROSS * M.LEAVE)
			slide(join(page, { d.rider }), -d.p0, gui.EASING_INOUTCUBIC, M.ACROSS, function()
				home_on(h, false)
				kit.scene_cut(false)
				kit.scene_copy_drop(still)
				blade_to(dp.line, 0, 0.3)
				-- 4. the line stays; the button, out of sight, goes back home
				unride(d)
				dp.busy = false
			end)
		end)
	end)
end

-- when INOUTCUBIC gets to the fraction f of its way (0..1)
local function reach(f)
	f = math.max(0, math.min(1, f))
	if f < 0.5 then return (f / 4) ^ (1 / 3) end
	return 1 - (2 * (1 - f)) ^ (1 / 3) / 2
end

function M.close(dp, h, change)
	if dp.kind == "zaino" then return M.shrink(dp, h, change) end
	dp.busy = true
	local d = measure(h, dp.door)
	local page = alive(kit.tracked())
	kit.track_end()
	local tops = kit.scene_tops()
	-- 1. the home comes back under the screen, the button back on the line
	local still = kit.scene_copy(h.scene)
	home_on(h, true)
	kit.scene_cut(true)
	if not dp.line then dp.line = line(d.line_x, -d.side) end
	blade_to(dp.line, 1, M.SLIP)
	ride(d)
	gui.set_position(d.node, vec(d.rest.x + d.dx - d.p0 + d.off, d.rest.y))
	-- (out of an animation's callback: started there, some animations of the
	-- same frame would start a frame late, and the backdrop would lag the page)
	gui.animate(d.node, "position.x", d.rest.x + d.dx - d.p0, gui.EASING_OUTQUAD, M.SLIP, 0, function() timer.delay(0, false, function()
		-- 2. it pushes the screen out toward its edge, the home under it; the
		-- button stops on its place (Sergio, 15 Nov: «quando arriva al suo
		-- posto resta lì») with a small bounce, the page goes on to the edge
		local left = 2
		local function done()
			left = left - 1
			if left > 0 then return end
			unride(d)
			dp.kind, dp.busy = nil, false
		end
		slide(join(page, tops, { dp.line }), d.p0, gui.EASING_INOUTCUBIC, M.ACROSS_BACK, function()
			-- (all in one frame: the backdrop back in its place under the home)
			shift(tops, -d.p0)
			kit.scene_cut(false)
			change()
			kit.scene_copy_drop(still)
			drop_line(dp)
			done()
		end)
		-- the button rides the line just as far as its place
		gui.animate(d.node, "position.x", d.rest.x + d.dx, gui.EASING_INOUTCUBIC, M.ACROSS_BACK)
		timer.delay(M.ACROSS_BACK * reach(1 - d.dx / d.p0), false, function()
			gui.cancel_animations(d.node, "position.x")
			gui.animate(d.node, "position.x", d.rest.x + d.side * M.BOUNCE, gui.EASING_OUTQUAD, 0.10, 0, function()
				gui.animate(d.node, "position.x", d.rest.x, gui.EASING_INOUTQUAD, 0.20, 0, done)
			end)
		end)
	end) end)
end

-- the screen went another way (a mission, a match): the line goes with it
function M.drop(dp)
	if dp.busy then return end
	drop_line(dp)
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
