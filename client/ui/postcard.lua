-- The mission's postcard (Sergio, 4 Nov; 6 Nov: the miniature of the map
-- instead of a painting, and kept, it is needed going from one mission
-- straight to the next): before a campaign mission the miniature of its map
-- opens in front of the menu on a leaning light plate, with the label of its
-- kind (the first time you meet that kind, also the line that says what it
-- is), the mission's name at the top, its stars with what each one takes, and
-- GIOCA. It is only a zoom on the card you tapped: the map is not loaded yet,
-- it loads after GIOCA, under the entry's flame (ui/transition.lua, flame).
-- Drawn with ui/kit.lua (Figma coordinates) on an opaque backdrop with the rays.
--
--   local postcard = require "ui.postcard"
--   local p = postcard.open(id, titolo, from, tipo, line, o)  -- from: { x, y, w, h } the picture
--        -- on the card you tapped (it zooms from there); tipo: the mission's kind
--        -- (ui/level_types.lua); line: what that kind is, or nil;
--        -- o: { criteria = { "FATTA", ... }, stars = { true, false, ... } } what you already took
--   postcard.press(p, x, y)  -- "avanti" on GIOCA, "indietro" on the plate at the bottom left, or nil
--   postcard.pad(p, n)       -- controller: "a" avanti, "b" indietro
--   postcard.leave(p, done)  -- GIOCA: it shrinks into the middle, the backdrop goes black
--   postcard.back(p, done)   -- INDIETRO: it zooms back onto the card
--   postcard.destroy(p)

local ui = require "ui.ui"
local kit = require "ui.kit"
local ill = require "ui.illustrations"
local types = require "ui.level_types"
local common = require("lang.text").common
local T = require("lang.text").level_end

local M = {}

local KC = kit.C
local function vec(x, y) return vmath.vector3(x, y, 0) end

-- the light plate and the picture in it (the picture leans like the plate)
M.POST = { x = 70, y = 130, w = 640, h = 380, sk = 26, pic_w = 612, pic_h = 356, pic_sk = 24 }
local P = M.POST
-- the middle of the plate: the zoom turns around it
local CX, CY = P.x + (P.w + P.sk) / 2, P.y + P.h / 2
M.ZOOM, M.LEAVE = 0.22, 0.17

-- where the plate is (its middle) and how big, for the picture to cover from
local function placed(from)
	local k = from.w / P.pic_w
	return vec(from.x, from.y), vmath.vector3(k, k, 1)
end

-- the picture cut to the slant: a band as tall as the picture, a leaning box in it
local function picture(parent, tex)
	local w, h, sk = P.pic_w, P.pic_h, P.pic_sk
	local band = gui.new_box_node(vec(0, 0), vec(w + sk, h))
	gui.set_clipping_mode(band, gui.CLIPPING_MODE_STENCIL)
	gui.set_clipping_visible(band, false)
	gui.set_parent(band, parent)
	local lean = math.atan2(sk, h)
	local cut = gui.new_box_node(vec(0, 0), vec(w * math.cos(lean), h / math.cos(lean) + sk + 2 * w * math.sin(lean)))
	gui.set_clipping_mode(cut, gui.CLIPPING_MODE_STENCIL)
	gui.set_clipping_visible(cut, false)
	gui.set_rotation(cut, vmath.vector3(0, 0, -math.deg(lean)))
	gui.set_parent(cut, band)
	local tall = math.max(h, (w + sk) * 9 / 16) + 4
	local img = gui.new_box_node(vec(0, 0), vec(tall * 16 / 9, tall))
	if tex then gui.set_texture(img, tex) else gui.set_color(img, KC.CARD_BOTTOM) end
	gui.set_rotation(img, vmath.vector3(0, 0, math.deg(lean)))
	gui.set_parent(img, cut)
end

function M.open(id, titolo, from, tipo, line, o)
	o = o or {}
	local tex = ill.texture(id, "tavola")
	local p = { id = id, from = from, tex = tex, tops = {} }
	local function top(n)
		p.tops[#p.tops + 1] = n
		return n
	end
	p.back = top(gui.new_box_node(vec(640, 360), vec(1280 * 4, 720 * 4)))
	gui.set_color(p.back, vmath.vector4(KC.INK.x, KC.INK.y, KC.INK.z, 0))
	gui.animate(p.back, "color.w", 1, gui.EASING_OUTQUAD, M.ZOOM)
	p.scene = kit.scene(390, 330, { halo = 460 })
	-- everything but the plate: it comes in when the zoom is over
	p.radice = top(gui.new_box_node(vec(0, 0), vec(0, 0)))
	gui.set_visible(p.radice, false)
	local g = { node = p.radice, ox = 0, oy = 720 }
	p.buttons = {}
	p.head = kit.header(p.buttons, kit.upper(titolo or ""), KC.HOT, "indietro", common.campaign)
	if line and types.color(tipo) then
		local t = kit.text(g, kit.upper(line), 82, 604, 15, KC.MUTE, "start", 0.8)
		local wide = kit.width(t)
		if wide > 700 then
			local sc = gui.get_scale(t)
			gui.set_scale(t, vec(sc.x * 700 / wide, sc.y * 700 / wide))
		end
	end
	-- the stars: what each one takes, lit if you already have it
	local n = 0
	for i, what in ipairs(o.criteria or {}) do
		local x = 886 + (i - 1) * 112
		local got = o.stars and o.stars[i]
		if got then n = n + 1 end
		ui.star(x, 720 - 478, 44, got and KC.STAR or KC.LINE, p.radice)
		local t = kit.text(g, what, x, 522, 12, KC.MUTE, "middle", 1)
		local wide = kit.width(t)
		if wide > 106 then
			local sc = gui.get_scale(t)
			gui.set_scale(t, vec(sc.x * 106 / wide, sc.y * 106 / wide))
		end
	end
	if n > 0 then
		kit.text(g, kit.upper((n == 1 and T.record_one or T.record):format(n)), 1000, 566, 13, KC.MUTE, "middle", 1.5)
	end
	p.right = kit.anchor(1280, 360, gui.ANCHOR_RIGHT)
	top(p.right.node)
	p.go_plate = kit.action(p.right, common.play, 836, 230, 354, 140, { size = 104 })
	p.next = p.go_plate.node
	-- the plate with the picture, in a node of its own: the zoom from the card you tapped
	p.card = top(gui.new_box_node(vec(CX, 720 - CY), vec(0, 0)))
	gui.set_visible(p.card, false)
	local cg = { node = p.card, ox = CX, oy = CY }
	local plate = kit.plate(cg, P.x, P.y, P.w, P.h, KC.HOT, { sk = P.sk, fill = KC.SAND, d = 12 })
	p.paper = plate.node
	picture(p.card, tex)
	types.label(tipo, -P.pic_w / 2 + 14, P.pic_h / 2 - 34, 40, p.card)
	-- black over everything when it leaves
	p.veil = top(gui.new_box_node(vec(640, 360), vec(1280 * 4, 720 * 4)))
	gui.set_color(p.veil, vmath.vector4(0, 0, 0, 0))
	gui.set_enabled(p.veil, false)

	local pos, scale = vec(CX, 720 - CY), vmath.vector3(1, 1, 1)
	if from then
		local at, k = placed(from)
		gui.set_position(p.card, at)
		gui.set_scale(p.card, k)
	else
		gui.set_scale(p.card, vmath.vector3(0.85, 0.85, 1))
	end
	gui.animate(p.card, "position", pos, gui.EASING_OUTCUBIC, M.ZOOM)
	gui.animate(p.card, "scale", scale, gui.EASING_OUTCUBIC, M.ZOOM)
	kit.pop(p.right.node, M.ZOOM * 0.6, 0.25)
	return p
end

-- everything around the plate goes away at once
local function alone(p)
	gui.set_enabled(p.radice, false)
	gui.set_enabled(p.right.node, false)
	for _, n in ipairs(p.head.tops) do gui.set_enabled(n, false) end
end

function M.press(p, x, y)
	if p.going then return nil end
	if gui.pick_node(p.next, x, y) then return "avanti" end
	if gui.pick_node(p.buttons[1].nodo, x, y) then return "indietro" end
	return nil
end

function M.pad(p, n)
	if p.going then return nil end
	if n == "a" then return "avanti" end
	if n == "b" then return "indietro" end
	return nil
end

-- GIOCA: the plate closes into a point in the middle and everything goes
-- black, like the entry's veil (ui/transition.lua) that takes its place
function M.leave(p, done)
	p.going = true
	gui.cancel_animations(p.card, "position")
	gui.cancel_animations(p.card, "scale")
	gui.animate(p.card, "position", vec(640, 360), gui.EASING_INQUAD, M.LEAVE)
	gui.animate(p.card, "scale", vmath.vector3(0.04, 0.04, 1), gui.EASING_INQUAD, M.LEAVE)
	gui.set_enabled(p.veil, true)
	gui.animate(p.veil, "color.w", 1, gui.EASING_INQUAD, M.LEAVE, 0, done)
end

-- INDIETRO: back onto the card it came from (or it fades in the middle)
function M.back(p, done)
	p.going = true
	alone(p)
	kit.scene_show(p.scene, false)
	local pos, scale = vec(CX, 720 - CY), vmath.vector3(0.85, 0.85, 1)
	if p.from then pos, scale = placed(p.from) end
	gui.animate(p.card, "position", pos, gui.EASING_INCUBIC, M.ZOOM * 0.8)
	gui.animate(p.card, "scale", scale, gui.EASING_INCUBIC, M.ZOOM * 0.8)
	gui.animate(p.back, "color.w", 0, gui.EASING_INQUAD, M.ZOOM * 0.8, 0, done)
end

function M.destroy(p)
	for _, n in ipairs(p.tops) do gui.delete_node(n) end
	for _, n in ipairs(p.scene.tops) do gui.delete_node(n) end
	kit.header_delete(p.head)
	if p.tex then ill.release(p.id, "tavola") end
end

return M
