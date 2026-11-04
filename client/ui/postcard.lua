-- The mission's postcard (WB-015 illustrations; Sergio, 4 Nov): before a
-- campaign mission its illustration opens in front of the menu as a postcard,
-- with the title and AVANTI. It is only a zoom on the card you tapped: the map
-- is not loaded yet, it loads after AVANTI, under the entry's flame
-- (ui/transition.lua, flame). Parchment card with its shadow, the picture in
-- an ink frame, the title and the button on the bottom band, an opaque
-- backdrop (nothing behind shows). Straight: a tilted quad would show steps on
-- its edges (no antialiasing on rotated nodes).
--
--   local postcard = require "ui.postcard"
--   local p = postcard.open(id, titolo, from)  -- nil without an illustration; from:
--        -- { x, y, w, h } the picture on the card you tapped (it zooms from there)
--   postcard.premi(p, x, y)  -- "avanti" on the button, "indietro" outside the card, or nil
--   postcard.pad(p, n)       -- controller: "a" avanti, "b" indietro
--   postcard.leave(p, done)  -- AVANTI: it shrinks into the middle, the backdrop goes black
--   postcard.back(p, done)   -- INDIETRO: it zooms back onto the card
--   postcard.destroy(p)

local ui = require "ui.ui"
local ill = require "ui.illustrations"
local common = require("lang.text").common

local M = {}

local function c(r, g, b, a) return vmath.vector4(r, g, b, a or 1) end
local function vec(x, y) return vmath.vector3(x, y, 0) end

local PAPER, INK = c(0.95, 0.88, 0.75), c(0.12, 0.07, 0.05)
local BACKDROP = c(0.09, 0.07, 0.07)
-- the picture 880 x 495 at its size, the parchment margin, the band with
-- title and button; y: how far above the middle of the screen
M.POST = { w = 880, h = 495, margin = 18, band = 84, y = 12 }
local P = M.POST
local CARD_W, CARD_H = P.w + 2 * P.margin, P.margin + P.h + P.band
-- the picture's middle, from the card's middle
local PIC_Y = CARD_H / 2 - P.margin - P.h / 2
M.ZOOM, M.LEAVE = 0.22, 0.17

local function box(x, y, w, h, color, parent)
	local n = gui.new_box_node(vec(x, y), vec(w, h))
	gui.set_texture(n, "battaglia")
	gui.play_flipbook(n, "targa_bianco")
	gui.set_color(n, color)
	if parent then gui.set_parent(n, parent) end
	return n
end

-- where the card is (its middle) and how big, for the picture to cover from
local function placed(from)
	local k = from.w / P.w
	return vec(from.x, from.y - PIC_Y * k), vmath.vector3(k, k, 1)
end

function M.open(id, titolo, from)
	local tex = ill.texture(id, "tavola")
	if not tex then return nil end
	local p = { id = id, from = from }
	p.radice = gui.new_box_node(vec(640, 360), vec(0, 0))
	gui.set_visible(p.radice, false)
	p.back = gui.new_box_node(vec(0, 0), vec(1280 * 4, 720 * 4))
	gui.set_color(p.back, BACKDROP)
	gui.set_parent(p.back, p.radice)
	p.card = gui.new_box_node(vec(0, P.y), vec(0, 0))
	gui.set_visible(p.card, false)
	gui.set_parent(p.card, p.radice)
	box(10, -12, CARD_W, CARD_H, c(0, 0, 0, 0.45), p.card)
	local paper, border = ui.pannello(0, 0, CARD_W, CARD_H, p.card)
	gui.set_color(paper, PAPER)
	gui.set_color(border, INK)
	p.paper = paper
	box(0, PIC_Y, P.w + 6, P.h + 6, INK, paper)
	local pic = gui.new_box_node(vec(0, PIC_Y), vec(P.w, P.h))
	gui.set_texture(pic, tex)
	gui.set_adjust_mode(pic, gui.ADJUST_FIT)
	gui.set_parent(pic, paper)
	local by = -CARD_H / 2 + P.band / 2
	local title = ui.titolo(string.upper(titolo or ""), -P.w / 2, by, 0.9, INK, paper)
	gui.set_outline(title, c(0, 0, 0, 0))
	gui.set_pivot(title, gui.PIVOT_W)
	p.next = box(P.w / 2 - 110, by, 220, 56, INK, paper)
	local t = gui.new_text_node(vec(0, 0), common.next)
	gui.set_font(t, "titolo")
	gui.set_color(t, PAPER)
	gui.set_scale(t, vmath.vector3(0.7, 0.7, 1))
	gui.set_parent(t, p.next)
	-- the zoom from the card you tapped (from the middle, small, without one)
	local pos, scale = vec(0, P.y), vmath.vector3(1, 1, 1)
	if from then
		pos, scale = placed(from)
		pos.x, pos.y = pos.x - 640, pos.y - 360
		gui.set_position(p.card, pos)
		gui.set_scale(p.card, scale)
	else
		gui.set_scale(p.card, vmath.vector3(0.85, 0.85, 1))
	end
	gui.animate(p.card, "position", vec(0, P.y), gui.EASING_OUTCUBIC, M.ZOOM)
	gui.animate(p.card, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTCUBIC, M.ZOOM)
	local bc = gui.get_color(p.back)
	bc.w = 0
	gui.set_color(p.back, bc)
	gui.animate(p.back, "color.w", 1, gui.EASING_OUTQUAD, M.ZOOM)
	return p
end

function M.premi(p, x, y)
	if p.going then return nil end
	if gui.pick_node(p.next, x, y) then return "avanti" end
	if not gui.pick_node(p.paper, x, y) then return "indietro" end
	return nil
end

function M.pad(p, n)
	if p.going then return nil end
	if n == "a" then return "avanti" end
	if n == "b" then return "indietro" end
	return nil
end

-- AVANTI: the card closes into a point in the middle and the backdrop goes
-- black, like the entry's veil (ui/transition.lua) that takes its place
function M.leave(p, done)
	p.going = true
	gui.cancel_animations(p.card, "position")
	gui.cancel_animations(p.card, "scale")
	gui.animate(p.card, "position", vec(0, 0), gui.EASING_INQUAD, M.LEAVE)
	gui.animate(p.card, "scale", vmath.vector3(0.04, 0.04, 1), gui.EASING_INQUAD, M.LEAVE)
	gui.animate(p.back, "color", c(0, 0, 0, 1), gui.EASING_INQUAD, M.LEAVE, 0, done)
end

-- INDIETRO: back onto the card it came from (or it fades in the middle)
function M.back(p, done)
	p.going = true
	local pos, scale = vec(0, P.y), vmath.vector3(0.85, 0.85, 1)
	if p.from then
		pos, scale = placed(p.from)
		pos.x, pos.y = pos.x - 640, pos.y - 360
	end
	gui.animate(p.card, "position", pos, gui.EASING_INCUBIC, M.ZOOM * 0.8)
	gui.animate(p.card, "scale", scale, gui.EASING_INCUBIC, M.ZOOM * 0.8)
	gui.animate(p.back, "color.w", 0, gui.EASING_INQUAD, M.ZOOM * 0.8, 0, done)
end

function M.destroy(p)
	gui.delete_node(p.radice)
	ill.release(p.id, "tavola")
end

return M
