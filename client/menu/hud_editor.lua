-- IMPOSTAZIONI > DISPOSIZIONE TASTI (Sergio, 21 Nov; sketch in the HUD
-- previews): the match stands still with every group of buttons in a dashed
-- frame. A tap picks a group (orange corners, "trascina per spostare"), the
-- finger drags it, the bar at the top gives its GRANDEZZA. RIPRISTINA puts
-- everything back where the game puts it, FATTO saves (game.gui_script).
-- The data and how it is applied: battle/hud_layout.lua.
--
--   local e = editor.new({ layout = L, boxes = function() ... end, changed = function() ... end })
--     boxes(): unit -> { on, x0, y0, x1, y1 } in game coordinates
--   editor.update(e)                       -- every frame
--   editor.on_input(e, action_id, action)  -- "fatto" when done
--   editor.destroy(e)

local ui = require "ui.ui"
local kit = require "ui.kit"
local screen = require "ui.screen"
local layout = require "battle.hud_layout"
local T = require("lang.text").hud_editor

local M = {}

local KC = kit.C
local BAND = 72               -- the band at the top
local DASH, GAP, LINE = 10, 6, 2
local PAD = 6                 -- the frame around a group
local SLIDER_W, SLIDER_KY = 400, 112   -- the size bar (y from the top of the screen)
local KNOB = 28
local STEP = 0.1              -- a tap on - or +
local WHITE = vmath.vector4(1, 1, 1, 0.7)
local ORANGE = ui.C.BRACE
local DARK = vmath.vector4(0.03, 0.03, 0.05, 0.94)

local vec = vmath.vector3

local function box(x, y, w, h, color, parent)
	local n = gui.new_box_node(vec(x, y, 0), vec(w, h, 0))
	gui.set_adjust_mode(n, gui.ADJUST_FIT)
	gui.set_color(n, color)
	if parent then gui.set_parent(n, parent) end
	return n
end

-- the y of the root's children for a point at game height y
local function local_y(y)
	return y - (screen.y1 - 720)
end

-- A frame: dashes when it is just there, a line with four corners when picked
local function frame_draw(e, f, b, picked)
	local x0, y0, x1, y1 = b[1] - PAD, b[2] - PAD, b[3] + PAD, b[4] + PAD
	local n = 0
	local function piece(x, y, w, h, color)
		n = n + 1
		local d = f.pieces[n]
		if not d then
			d = box(0, 0, 1, 1, WHITE, e.frames_root)
			f.pieces[n] = d
		end
		gui.set_enabled(d, true)
		gui.set_position(d, vec(x, local_y(y), 0))
		gui.set_size(d, vec(w, h, 0))
		gui.set_color(d, color)
	end
	if picked then
		local t = LINE + 1
		piece((x0 + x1) / 2, y0, x1 - x0 + t, t, ORANGE)
		piece((x0 + x1) / 2, y1, x1 - x0 + t, t, ORANGE)
		piece(x0, (y0 + y1) / 2, t, y1 - y0 + t, ORANGE)
		piece(x1, (y0 + y1) / 2, t, y1 - y0 + t, ORANGE)
	else
		for x = x0, x1 - DASH, DASH + GAP do
			piece(x + DASH / 2, y0, DASH, LINE, WHITE)
			piece(x + DASH / 2, y1, DASH, LINE, WHITE)
		end
		for y = y0, y1 - DASH, DASH + GAP do
			piece(x0, y + DASH / 2, LINE, DASH, WHITE)
			piece(x1, y + DASH / 2, LINE, DASH, WHITE)
		end
	end
	for i = n + 1, #f.pieces do gui.set_enabled(f.pieces[i], false) end
	-- the corners
	for i, c in ipairs(f.corners) do
		gui.set_enabled(c, picked)
		if picked then
			gui.set_position(c, vec(i % 2 == 1 and x0 or x1, local_y(i <= 2 and y0 or y1), 0))
		end
	end
end

local function slider_x0()
	return 640 - SLIDER_W / 2
end

local function show_size(e)
	local u = e.sel
	gui.set_enabled(e.size_root, u ~= nil)
	gui.set_enabled(e.pick_hint, u == nil)
	gui.set_enabled(e.drag_hint, u ~= nil)
	if not u then return end
	local s = e.L[u].s
	gui.set_text(e.size_label, string.format(T.size, T.units[u]))
	local f = (s - layout.MIN) / (layout.MAX - layout.MIN)
	kit.bar_fill(e.bar, f)
	gui.set_position(e.knob, vec(slider_x0() + f * SLIDER_W, 720 - SLIDER_KY, 0))
end

function M.new(api)
	local e = { api = api, L = api.layout, buttons = {}, frames = {}, seen = {} }
	e.root = ui.root()
	-- the frames under everything else of the editor
	e.frames_root = box(0, 0, 0, 0, WHITE, e.root)
	local g = { node = e.root, ox = 0, oy = 720 }
	local x0, x1 = screen.x0, screen.x1
	box((x0 + x1) / 2, 720 - BAND / 2, x1 - x0, BAND, DARK, e.root)
	box((x0 + x1) / 2, 720 - BAND, x1 - x0, LINE, ORANGE, e.root)
	kit.text(g, T.title, x0 + 24, 47, 30, KC.SAND, "start")
	local done = kit.action(g, T.done, x1 - 24 - 220, 8, 220, 56)
	kit.button(e.buttons, done, "fatto")
	local reset = kit.secondary(g, T.reset, x1 - 24 - 220 - 20 - 230, 10, 230, 52)
	kit.button(e.buttons, reset, "ripristina")
	-- the size bar, for the picked group
	e.size_root = box(0, 0, 0, 0, WHITE, e.root)
	gui.set_visible(e.size_root, false)
	local sg = { node = e.size_root, ox = 0, oy = 720 }
	e.size_label = kit.text(sg, "", 640, SLIDER_KY - 18, 20, KC.SAND, "middle")
	kit.text(sg, "-", slider_x0() - 30, SLIDER_KY + 10, 30, KC.SAND, "middle")
	kit.text(sg, "+", slider_x0() + SLIDER_W + 30, SLIDER_KY + 10, 30, KC.SAND, "middle")
	e.bar = kit.bar(sg, slider_x0(), SLIDER_KY - 5, SLIDER_W, 10, 0.5, KC.HOT)
	e.knob = ui.disc(0, 0, KNOB, ORANGE, e.size_root)
	gui.set_adjust_mode(e.knob, gui.ADJUST_FIT)
	e.pick_hint = kit.text(g, T.pick, 640, SLIDER_KY, 20, KC.SAND, "middle")
	-- "trascina per spostare", above the picked group (made at 0, 0: moved by its offset)
	e.drag_hint = kit.text(g, T.drag, 0, 0, 16, KC.SAND, "middle")
	e.drag_at = gui.get_position(e.drag_hint)
	for _, u in ipairs(layout.UNITS) do
		local f = { pieces = {}, corners = {} }
		for i = 1, 4 do
			f.corners[i] = ui.disc(0, 0, 14, ORANGE, e.frames_root)
			gui.set_adjust_mode(f.corners[i], gui.ADJUST_FIT)
		end
		e.frames[u] = f
	end
	show_size(e)
	M.update(e)
	return e
end

function M.update(e)
	local all = e.api.boxes()
	for _, u in ipairs(layout.UNITS) do
		local b, f = all[u], e.frames[u]
		local picked = e.sel == u
		local key = b.on and (b[1] .. ":" .. b[2] .. ":" .. b[3] .. ":" .. b[4] .. (picked and "*" or "")) or ""
		if e.seen[u] ~= key then
			e.seen[u] = key
			if b.on then
				frame_draw(e, f, b, picked)
			else
				for _, d in ipairs(f.pieces) do gui.set_enabled(d, false) end
				for _, c in ipairs(f.corners) do gui.set_enabled(c, false) end
			end
			if picked and b.on then
				gui.set_position(e.drag_hint, vec(e.drag_at.x + (b[1] + b[3]) / 2,
					e.drag_at.y + local_y(b[4] + PAD + 10) - 720, 0))
			end
		end
	end
	e.boxes = all
end

-- the smallest group under the finger
local function pick(e, x, y)
	local best, area = nil, math.huge
	for _, u in ipairs(layout.UNITS) do
		local b = e.boxes and e.boxes[u]
		if b and b.on and x >= b[1] - PAD - 8 and x <= b[3] + PAD + 8 and y >= b[2] - PAD - 8 and y <= b[4] + PAD + 8 then
			local a = (b[3] - b[1]) * (b[4] - b[2])
			if a < area then best, area = u, a end
		end
	end
	return best
end

local function set_size(e, s)
	local v = e.L[e.sel]
	s = layout.clamp(math.floor(s * 20 + 0.5) / 20)
	if v.s == s then return end
	v.s = s
	e.api.changed()
	show_size(e)
end

function M.on_input(e, action_id, action)
	local hit = ui.touch(e.buttons, action_id, action)
	if hit == "fatto" then return "fatto" end
	if hit == "ripristina" then
		layout.reset(e.L)
		e.api.changed()
		show_size(e)
		return nil
	end
	if action_id ~= ui.TOUCH or e.buttons.held_down then return nil end
	local x, y = screen.from_touch(action.x, action.y)
	if action.pressed then
		local sy = screen.y1 - SLIDER_KY
		local sx0 = slider_x0()
		-- the size bar (with - and + at its ends)
		if e.sel and math.abs(y - sy) < 26 and x > sx0 - 56 and x < sx0 + SLIDER_W + 56 then
			if x < sx0 - 10 then
				set_size(e, e.L[e.sel].s - STEP)
			elseif x > sx0 + SLIDER_W + 10 then
				set_size(e, e.L[e.sel].s + STEP)
			else
				e.drag = "size"
				set_size(e, layout.MIN + (x - sx0) / SLIDER_W * (layout.MAX - layout.MIN))
			end
			return nil
		end
		-- (the band at the top is not a place for the buttons)
		if y > screen.y1 - BAND then return nil end
		local u = pick(e, x, y)
		e.sel = u
		show_size(e)
		if u then
			local b, v = e.boxes[u], e.L[u]
			e.drag = "move"
			e.from_x, e.from_y, e.ox, e.oy = x, y, v.x, v.y
			-- the group's center stays on the screen, under the band
			e.cx, e.cy = (b[1] + b[3]) / 2, (b[2] + b[4]) / 2
		end
	elseif action.released then
		e.drag = nil
	elseif e.drag == "size" then
		set_size(e, layout.MIN + (x - slider_x0()) / SLIDER_W * (layout.MAX - layout.MIN))
	elseif e.drag == "move" then
		local v = e.L[e.sel]
		local dx = math.max(screen.x0 + 30, math.min(screen.x1 - 30, e.cx + x - e.from_x)) - e.cx
		local dy = math.max(screen.y0 + 30, math.min(screen.y1 - BAND - 30, e.cy + y - e.from_y)) - e.cy
		if v.x ~= e.ox + dx or v.y ~= e.oy + dy then
			v.x, v.y = e.ox + dx, e.oy + dy
			e.api.changed()
		end
	end
	return nil
end

function M.destroy(e)
	gui.delete_node(e.root)
end

return M
