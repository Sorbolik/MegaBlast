-- The flat backdrops of the menus (Sergio, 18 Nov: the style of the first
-- backgrounds of 5 Nov, flat dark shapes made in code, no painted image, no
-- halo): the colonnade behind the campaign, the rings widening from the podium
-- behind the home. They end on the thread: under it the footer is plain dark.
-- Coordinates: x from the middle of the 1280 frame, y from its bottom (the
-- parent is stuck to the real bottom of the screen, like the thread)
--
--   local flat = require "ui.flat_backdrops"
--   if flat.has(name) then local root = flat.make(name, parent, thread_y, live) end
--   (live false: a still copy, nothing moves)

local screen = require "ui.screen"

local M = {}

local function c(h)
	return vmath.vector4(tonumber(h:sub(1, 2), 16) / 255, tonumber(h:sub(3, 4), 16) / 255, tonumber(h:sub(5, 6), 16) / 255, 1)
end

local function box(x, y, w, h, color, parent)
	local n = gui.new_box_node(vmath.vector3(x, y, 0), vmath.vector3(w, h, 0))
	gui.set_color(n, color)
	gui.set_parent(n, parent)
	gui.set_inherit_alpha(n, true)
	return n
end

-- how far the shapes go: 2 frames each way (20:9, 4:3, foldables)
local HALF_W, TOP = 1280, 720 * 2.5

local THEMES = {}

-- CAMPAGNA: the colonnade of the noble castle of the Limbo, grey sage in the
-- eternal dusk: fluted columns 150 wide every 300, a capital and a base each
THEMES.colonnato = {
	base = c("121714"),
	build = function(root)
		local shaft, flute, block = c("161E19"), c("121915"), c("1A231D")
		for x = -60 - 4 * 300, HALF_W + 300, 300 do
			local cx = x + 75 - 640
			box(cx, TOP / 2, 150, TOP, shaft, root)
			for f = 1, 5 do box(x + f * 25 + 1.5 - 640, TOP / 2, 3, TOP, flute, root) end
			box(cx, 720 - 83, 186, 26, block, root)
			box(cx, 720 - 575, 186, 30, block, root)
		end
	end,
}

-- HOME: flat rings born under the podium, widening slowly like a wave
-- (Sergio, 18 Nov: «niente sfarfallamenti»). Every STEP_T seconds each ring has
-- grown to where the next one was and the colors move one ring out: on that
-- frame every ring goes back one place and takes the color its inner
-- neighbour had, so the picture is the same and the loop has no jump
local GAP, STEP_T, RINGS = 220, 6, 26
local CX, CY = 0, 160
THEMES.anelli = {
	base = c("110F18"),
	build = function(root, live)
		local colors = { c("1C1826"), c("17141F") }
		local rings = {}
		-- the biggest first (under), the smallest last (over)
		for i = RINGS - 1, 0, -1 do
			local n = gui.new_pie_node(vmath.vector3(CX, CY, 0), vmath.vector3(0, 0, 0))
			gui.set_outer_bounds(n, gui.PIEBOUNDS_ELLIPSE)
			gui.set_perimeter_vertices(n, 160)
			gui.set_parent(n, root)
			gui.set_inherit_alpha(n, true)
			rings[i] = n
		end
		local size = vmath.vector3(0, 0, 0)
		local function place(t)
			local steps = math.floor(t / STEP_T)
			local p = t / STEP_T - steps
			for i = 0, RINGS - 1 do
				size.x = GAP * (i + p)
				size.y = size.x
				gui.set_size(rings[i], size)
				gui.set_color(rings[i], colors[(i + steps) % 2 + 1])
			end
		end
		-- a still copy stops where a live one would be at 3 s
		place(3)
		if not live then return end
		local t = 3
		return function(dt)
			t = (t + dt) % (STEP_T * 2)
			place(t)
		end
	end,
}

-- CAMPAGNA DEI GIRONI: the two walls of the chasm, flat jagged rock at the
-- sides, the middle empty and dark (bozza G3). The wall is an image of flat
-- shapes (tools/grafica/voragine.py: the polygons have smooth edges there),
-- stuck to the real left edge, and the same mirrored on the right
local WALL_W, WALL_H = 300, 972
local textures = {}

local function texture(name)
	if textures[name] then return textures[name] end
	local data = sys.load_resource("/paintings/backdrops/" .. name .. ".png")
	local img = data and image.load(data)
	if img and gui.new_texture(name, img.width, img.height, img.type, img.buffer) then
		textures[name] = name
	end
	return textures[name]
end

THEMES.voragine = {
	base = c("130E10"),
	build = function(root)
		local id = texture("piatto_voragine")
		if not id then return end
		local half = screen.width() / 2
		-- from the thread up, 360 above the frame for the tall screens
		local y = 720 - 612 + WALL_H / 2
		for _, side in ipairs({ -1, 1 }) do
			local n = gui.new_box_node(vmath.vector3(side * (half - WALL_W / 2), y, 0), vmath.vector3(WALL_W, WALL_H, 0))
			gui.set_texture(n, id)
			gui.set_scale(n, vmath.vector3(-side, 1, 1))
			gui.set_parent(n, root)
			gui.set_inherit_alpha(n, true)
		end
	end,
	-- it sticks to the real edges: made again when the screen's width changes
	wide = true,
}

-- whether the theme must be made again when the screen's width changes
function M.follows_width(name)
	return THEMES[name] ~= nil and THEMES[name].wide == true
end

function M.has(name)
	return type(name) == "string" and THEMES[name] ~= nil
end

-- The theme's nodes under parent, ending on the thread (thread_y from the
-- bottom of the frame): under it the plain dark of the footer
function M.make(name, parent, thread_y, footer, live)
	local t = THEMES[name]
	local root = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(0, 0, 0))
	gui.set_visible(root, false)
	gui.set_parent(root, parent)
	-- the theme's own dark, a stencil so nothing of it goes under the thread
	local clip = gui.new_box_node(vmath.vector3(0, (thread_y + TOP) / 2, 0), vmath.vector3(HALF_W * 4, TOP - thread_y, 0))
	gui.set_color(clip, t.base)
	gui.set_clipping_mode(clip, gui.CLIPPING_MODE_STENCIL)
	gui.set_parent(clip, root)
	gui.set_inherit_alpha(clip, true)
	local inner = gui.new_box_node(vmath.vector3(0, -(thread_y + TOP) / 2, 0), vmath.vector3(0, 0, 0))
	gui.set_visible(inner, false)
	gui.set_parent(inner, clip)
	gui.set_inherit_alpha(inner, true)
	local tick = t.build(inner, live)
	-- the footer: plain dark from the thread down past the real bottom
	box(0, thread_y - 360, HALF_W * 4, 720, footer, root)
	-- what moves runs every frame while the theme lives: M.drop stops it, and
	-- it stops by itself once its nodes are deleted (a copy of the backdrop)
	local timer_id
	if tick then
		timer_id = timer.delay(0, true, function(_, h, dt)
			if pcall(gui.get_position, root) then tick(dt) else timer.cancel(h) end
		end)
	end
	return root, timer_id
end

-- Removes a theme made by M.make
function M.drop(root, timer_id)
	if timer_id then timer.cancel(timer_id) end
	if root then gui.delete_node(root) end
end

return M
