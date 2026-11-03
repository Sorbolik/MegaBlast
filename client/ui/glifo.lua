-- The controller button drawn as it is on the real controller (Sergio, 30
-- Oct): Xbox with the colored round A B X Y, PlayStation with the symbols
-- (cross, circle, square, triangle), Nintendo with the letters in their
-- places; the shoulders (LB, L1, ZL...), Start and Select in a pill, the d-pad
-- with the arm lit. Only shapes from ui.lua, no images.
--
--   local glifo = require "ui.glifo"
--   local g = glifo.new(parent)                 -- empty, d is the height (34)
--   glifo.display(g, controller, button_key, x, y) -- draws the button (nil: hides it)

local ui = require "ui.ui"
local controller = require "ui.controller"

local M = {}

M.D = 34

local function c(r, g, b) return vmath.vector4(r, g, b, 1) end
local XBOX = { a = c(0.42, 0.8, 0.3), b = c(0.95, 0.33, 0.3), x = c(0.3, 0.58, 1), y = c(1, 0.8, 0.2) }
local PS = { a = c(0.5, 0.72, 1), b = c(1, 0.42, 0.45), x = c(0.96, 0.58, 0.85), y = c(0.36, 0.88, 0.74) }
local GREY = c(0.4, 0.38, 0.4)
local FACE = { a = true, b = true, x = true, y = true }
local CROSS = { su = { 0, 1 }, giu = { 0, -1 }, sinistra = { -1, 0 }, destra = { 1, 0 } }

local V = vmath.vector3()

local function box(x, y, w, h, color, angle_deg, parent)
	local n = gui.new_box_node(vmath.vector3(x, y, 0), vmath.vector3(w, h, 0))
	gui.set_color(n, color)
	if angle_deg then gui.set_euler(n, vmath.vector3(0, 0, angle_deg)) end
	gui.set_parent(n, parent)
	return n
end

-- The PlayStation symbols, s wide, t thick
local SYMBOLS = {
	a = function(s, t, col, p)
		box(0, 0, s * 1.15, t, col, 45, p)
		box(0, 0, s * 1.15, t, col, -45, p)
	end,
	b = function(s, t, col, p)
		ui.ring_node(0, 0, s, t, col, p)
	end,
	x = function(s, t, col, p)
		local h = s * 0.42
		box(0, h, s * 0.84 + t, t, col, nil, p)
		box(0, -h, s * 0.84 + t, t, col, nil, p)
		box(h, 0, t, s * 0.84, col, nil, p)
		box(-h, 0, t, s * 0.84, col, nil, p)
	end,
	y = function(s, t, col, p)
		-- the three sides around the center: in the middle of each side, R / 2 from the center
		local side_of = s * 1.05
		local r = side_of / math.sqrt(3) / 2
		for _, a in ipairs({ { 270, 0 }, { 30, -60 }, { 150, 60 } }) do
			local q = math.rad(a[1])
			box(math.cos(q) * r, math.sin(q) * r - s * 0.06, side_of + t * 0.6, t, col, a[2], p)
		end
	end,
}

local function draw(r, family, button_key, d)
	local C = ui.C
	if FACE[button_key] then
		local col = family == "xbox" and XBOX[button_key] or family == "playstation" and PS[button_key] or C.LIGHT
		ui.disco(0, 0, d, C.PANEL, r)
		ui.ring_node(0, 0, d, 2, family == "nintendo" and C.LIGHT or col, r)
		if family == "playstation" then
			SYMBOLS[button_key](d * 0.44, math.max(2, d * 0.08), col, r)
		else
			ui.testo(controller.FAMILIES[family][button_key], 0, 1, d / 52, col, r)
		end
		return d
	end
	if CROSS[button_key] then
		-- the gray d-pad, with the button's arm lit
		local b, t = d * 0.7, d * 0.24
		ui.disco(0, 0, d, C.PANEL, r)
		ui.ring_node(0, 0, d, 2, C.LIGHT, r)
		box(0, 0, b, t, GREY, nil, r)
		box(0, 0, t, b, GREY, nil, r)
		local v = CROSS[button_key]
		local l = b * 0.42
		box(v[1] * (b - l) / 2, v[2] * (b - l) / 2, v[1] ~= 0 and l or t, v[2] ~= 0 and l or t, C.LIGHT, nil, r)
		return d
	end
	-- shoulders, Start and Select: a pill with the name
	local nome = controller.FAMILIES[family][button_key] or string.upper(button_key)
	local w = math.max(d, 12 + #nome * d * 0.42)
	local n = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(w, d * 0.82, 0))
	gui.set_texture(n, "ui")
	gui.play_flipbook(n, "forma")
	gui.set_slice9(n, vmath.vector4(16, 16, 16, 16))
	gui.set_color(n, C.PANEL)
	gui.set_parent(n, r)
	local border = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(w, d * 0.82, 0))
	gui.set_texture(border, "ui")
	gui.play_flipbook(border, "bordo")
	gui.set_slice9(border, vmath.vector4(16, 16, 16, 16))
	gui.set_color(border, C.LIGHT)
	gui.set_parent(border, r)
	ui.testo(nome, 0, 1, d / 44, C.TEXT, r)
	return w
end

function M.new(parent, d)
	local r = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(0, 0, 0))
	gui.set_visible(r, false)
	if parent then gui.set_parent(r, parent) end
	local g = { radice = r, d = d or M.D, children = nil, chi = nil, w = 0 }
	gui.set_enabled(r, false)
	return g
end

-- The width of the drawn button (to put it next to something)
function M.largo(g)
	return g.w
end

function M.display(g, ctrl, button_key, x, y)
	if not (ctrl and button_key) then
		if g.acceso then
			gui.set_enabled(g.radice, false)
			g.acceso = false
		end
		return
	end
	local who = ctrl.family .. ":" .. button_key
	if g.chi ~= who then
		g.chi = who
		if g.children then gui.delete_node(g.children) end
		g.children = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(0, 0, 0))
		gui.set_visible(g.children, false)
		gui.set_parent(g.children, g.radice)
		g.w = draw(g.children, ctrl.family, button_key, g.d)
	end
	if x and (g.x ~= x or g.y ~= y) then
		g.x, g.y = x, y
		V.x, V.y, V.z = x, y, 0
		gui.set_position(g.radice, V)
	end
	if not g.acceso then
		gui.set_enabled(g.radice, true)
		g.acceso = true
	end
end

return M
