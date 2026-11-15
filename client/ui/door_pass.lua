-- The passage of the home's doors and of the ZAINO (Figma "RIORGANIZZAZIONE MENU ·
-- 14 nov", the approved trial https://claude.ai/artifact/NUZURUfk3Gt2eaFpnN7roq;
-- Sergio, 14 Nov):
--   door   the button shoots toward its edge and brakes as its shield reaches
--          it; the reversal is the slowest moment; then, speeding up, the whole
--          button is the tab of the new screen and drags it across, on the band
--          drawn by Codex (WB-049) with its clamp, shedding its trail of bits,
--          while the home goes out on the other side. Arrived, the tab stays on
--          the screen's edge: where you are. Back: the other way round
--   zaino  the ZAINO grows out of the apprentice and goes back into it
-- The backdrop is the same for the home and the screens (ui/kit.lua): it stays.
-- The new screen's top nodes are the ones kit.anchor and ui.root make while it
-- is open (kit.track).
--
--   local door_pass = require "ui.door_pass"
--   local dp = door_pass.new()
--   door_pass.open(dp, home, id, change, done)     -- change(): makes the new screen
--   door_pass.close(dp, home, change, done)        -- change(): closes it, shows the home
--   door_pass.grow(dp, home, change, done)         -- the ZAINO
--   door_pass.shrink(dp, home, change, done)
--   door_pass.owns(dp)        -- a screen opened by a door or the apprentice: its way back is here
--   door_pass.drop(dp)        -- the screen went away by another way: the tab with it
--   door_pass.update(dp, dt)  -- the trail
--   door_pass.is_active(dp)

local kit = require "ui.kit"
local ui = require "ui.ui"
local screen = require "ui.screen"
local home = require "menu.home"

local M = {}

-- the times: out to the edge, across (forward), across (back), home again
M.OUT, M.ACROSS, M.ACROSS_BACK, M.IN = 0.30, 0.64, 0.52, 0.36
M.GROW, M.SHRINK = 0.42, 0.32
-- the edge sits this far past the screen's border (the shield's middle on it)
local EDGE = 17
local BAND_W = 48
-- the bits each door sheds (scia_*, WB-049)
local TRAIL = {
	campagna = { "brace", "scintilla", "fiamma", "ricciolo" },
	allenamento = { "ferro", "cuoio", "paglia", "acciaio" },
	eventi = { "stella", "moneta", "nastro", "oro" },
	armeria = { "ghiaccio", "fiocco", "cristallo", "gelo" },
}
local EVERY = 0.038   -- a bit every so often while the edge moves

local function vec(x, y) return vmath.vector3(x, y, 0) end

function M.new()
	return { bits = {}, t = 0 }
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

-- every top node moved by `by` along x, over t seconds
local function slide(nodes, by, easing, t, done)
	local left = #nodes
	if left == 0 then if done then done() end return end
	for _, n in ipairs(nodes) do
		local p = gui.get_position(n)
		gui.animate(n, "position.x", p.x + by, easing, t, 0, function()
			left = left - 1
			if left == 0 and done then done() end
		end)
	end
end

local function shift(nodes, by)
	for _, n in ipairs(nodes) do
		local p = gui.get_position(n)
		gui.set_position(n, vec(p.x + by, p.y))
	end
end

-- The edge: the band down the whole screen, the clamp at the shield's height
-- and the button itself, its shield on the band (the tab). x: the edge's
-- middle, in the game's coordinates
local function edge(dp, d, x)
	-- (not kit.anchor: it would count as one of the screen's nodes)
	local rn = gui.new_box_node(vec(0, 720), vec(0, 0))
	gui.set_visible(rn, false)
	local root = { node = rn, ox = 0, oy = 0 }
	local g = kit.group(root, x, d.cy)
	local band = "banda_" .. d.id
	local m = kit.PIECES[band]
	local tile = BAND_W * m.h / m.w
	local top, bottom = 720 - screen.y1 - 30, 720 - screen.y0 + 30
	local y = top
	while y < bottom do
		kit.pic(g, band, x - BAND_W / 2, y, BAND_W, tile)
		y = y + tile - 2
	end
	-- the button, its shield on the band
	local tab = home.door_copy(g, d.id, x - d.shield * d.w, d.y, d.name, d.sub)
	-- the clamp over the band, around the shield (mirrored on the right)
	local ch = d.h * 0.86
	local clamp = kit.pic(g, "attacco_scudo", x - ch * 109 / 170 / 2, d.cy - ch / 2, ch * 109 / 170, ch)
	if d.side > 0 then gui.set_scale(clamp, vmath.vector3(-1, 1, 1)) end
	dp.edge = { root = root, g = g, tab = tab, x = x }
end

local function drop_edge(dp)
	if dp.edge then gui.delete_node(dp.edge.root.node) end
	dp.edge = nil
end

-- the trail: bits from the edge, flying the other way and fading
local function shed(dp, d, dir)
	dp.shedding = { d = d, dir = dir, next = 0 }
end

function M.update(dp, dt)
	dp.t = dp.t + dt
	local s = dp.shedding
	if s and dp.edge and dp.t >= s.next then
		s.next = dp.t + EVERY
		s.n = (s.n or 0) + 1
		local x = gui.get_position(dp.edge.g.node).x
		if x > screen.x0 - 40 and x < screen.x1 + 40 then
			local kind = TRAIL[s.d.id][(s.n - 1) % 4 + 1]
			local size = 22 + math.random() * 20
			local y = s.d.cy + (math.random() - 0.5) * 150
			local n = kit.pic({ node = dp.edge.root.node, ox = 0, oy = 0 }, "scia_" .. kind, x - size / 2, y - size / 2, size, size)
			local p = gui.get_position(n)
			local to = vec(p.x - s.dir * (50 + math.random() * 90), p.y + (math.random() - 0.5) * 60)
			local t = 0.42 + math.random() * 0.2
			gui.animate(n, "position", to, gui.EASING_OUTCUBIC, t)
			gui.animate(n, "euler.z", (math.random() - 0.5) * 160, gui.EASING_OUTCUBIC, t)
			gui.animate(n, "scale", vmath.vector3(0.4, 0.4, 1), gui.EASING_OUTCUBIC, t)
			gui.animate(n, "color.w", 0, gui.EASING_INQUAD, t, 0, function() gui.delete_node(n) end)
		end
	end
end

-- DOORS ---------------------------------------------------------------------------

-- the door's measures, in the game's coordinates (its group sticks to its edge)
local function measure(h, id)
	local d = home.door_info(h, id)
	local ox = d.side < 0 and screen.x0 or screen.x1 - 1280
	d.gx = d.x + ox                          -- where its left end is on the screen
	d.shield = d.side < 0 and 0.15 or 0.85   -- the shield's middle, along it
	return d
end

function M.open(dp, h, id, change, done)
	dp.busy = true
	local d = measure(h, id)
	local node = d.p.node
	local rest = gui.get_position(node)
	-- 1. the button shoots to its edge and brakes
	local to = d.side < 0 and screen.x0 + EDGE or screen.x1 - EDGE
	local dx = to - (d.gx + d.shield * d.w)
	gui.animate(node, "position.x", rest.x + dx, gui.EASING_OUTCUBIC, M.OUT, 0, function()
		-- 2. the reversal: the new screen, made out of sight, comes in dragged by its tab
		local W = screen.width()
		local p0 = d.side < 0 and -W or W
		kit.track_begin()
		change()
		dp.kind, dp.door, dp.p0 = "door", id, p0
		local page = alive(kit.tracked())
		shift(page, p0)
		kit.scene_bottom()
		-- the home stays a moment longer, to go out the other side; its button is the tab now
		home.peek(h, true)
		gui.set_position(node, rest)
		gui.set_enabled(node, false)
		edge(dp, d, to)
		-- (a moment for the frame that made the screen, a long one)
		timer.delay(0.03, false, function()
			slide(page, -p0, gui.EASING_INOUTCUBIC, M.ACROSS)
			slide(h.tops, -p0, gui.EASING_INOUTCUBIC, M.ACROSS)
			shed(dp, d, p0 < 0 and 1 or -1)
			slide({ dp.edge.g.node }, -p0, gui.EASING_INOUTCUBIC, M.ACROSS, function()
				dp.shedding = nil
				-- the home goes, back where it was for next time
				home.peek(h, false)
				shift(h.tops, p0)
				gui.set_enabled(node, true)
				dp.busy = false
				if done then done() end
			end)
		end)
	end)
end

function M.close(dp, h, change, done)
	if dp.kind == "zaino" then return M.shrink(dp, h, change, done) end
	dp.busy = true
	local d = measure(h, dp.door)
	local p0 = dp.p0
	local page = alive(kit.tracked())
	kit.track_end()
	-- 1. the tab pulls the screen back toward its edge, braking; the home comes back
	home.peek(h, true)
	kit.scene_bottom()
	shift(h.tops, -p0)
	local node = d.p.node
	local rest = gui.get_position(node)
	local to = d.side < 0 and screen.x0 + EDGE or screen.x1 - EDGE
	local dx = to - (d.gx + d.shield * d.w)
	gui.set_enabled(node, false)
	if not dp.edge then
		edge(dp, d, to)
		shift({ dp.edge.g.node }, -p0)
	end
	slide(page, p0, gui.EASING_OUTCUBIC, M.ACROSS_BACK)
	slide(h.tops, p0, gui.EASING_OUTCUBIC, M.ACROSS_BACK)
	shed(dp, d, p0 < 0 and -1 or 1)
	slide({ dp.edge.g.node }, p0, gui.EASING_OUTCUBIC, M.ACROSS_BACK, function()
		dp.shedding = nil
		-- 2. the reversal: the tab is a button again and comes home, speeding up
		change()
		drop_edge(dp)
		gui.set_enabled(node, true)
		gui.set_position(node, vec(rest.x + dx, rest.y))
		gui.animate(node, "position.x", rest.x, gui.EASING_INOUTCUBIC, M.IN, 0, function()
			dp.kind, dp.busy = nil, false
			if done then done() end
		end)
	end)
end

-- the screen went another way (a mission, a match): the tab goes with it
function M.drop(dp)
	if dp.busy then return end
	drop_edge(dp)
	kit.track_end()
	dp.kind, dp.shedding = nil, nil
end

-- the edge is there while its screen is open; on rebuilds it stays on top
function M.raise(dp)
	if dp.edge then gui.move_above(dp.edge.root.node, nil) end
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
