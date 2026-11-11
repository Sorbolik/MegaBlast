-- The story's comic (ui/story.lua): one panel at a time on a leaning light
-- plate over a dark backdrop (ui/kit.lua, Figma coordinates), each panel with
-- its own shape (wide or square), and its lines one balloon at a time in the
-- calm corner of the panel. AVANTI (or A) goes on; SALTA only when you have
-- already read it (Sergio, 4 Nov: the first time the story is watched whole).
-- Client only.
--
--   local comic = require "menu.story"
--   local s = comic.new(pages, can_skip)   -- pages: ui/story.lua's pages
--   comic.on_input(s, action_id, action)   -- "fine" when it's over (or skipped)
--   comic.destroy(s)

local ui = require "ui.ui"
local kit = require "ui.kit"
local ill = require "ui.illustrations"
local T = require("lang.text").story
local TV = require("lang.text").vignette
local common = require("lang.text").common

local M = {}

local KC = kit.C
local function c(r, g, b, a) return vmath.vector4(r, g, b, a or 1) end
-- the picture: its middle, how tall, at most how wide, how much it leans; the
-- light margin around it
local CX, CY, PIC_H, PIC_MAX_W, PIC_SK, MARGIN = 640, 330, 536, 1002, 28, 14
-- the balloon: at most this wide, its padding, its distance from the picture's edges
local BALLOON_W, BALLOON_PAD, BALLOON_GAP, TEXT_SIZE = 520, 18, 30, 19

-- who speaks: name and color (the vignettes' ones, plus the voice from the dark)
local WHO = {
	favilla = { TV.favilla, c(0.28, 0.44, 0.56) },
	fabbro = { TV.fabbro, c(0.72, 0.26, 0.16) },
	apprendista = { TV.apprendista, c(0.72, 0.26, 0.16) },
	voce = { T.voice, c(0.30, 0.55, 0.75) },
}

local function vec(x, y) return vmath.vector3(x, y, 0) end

-- how tall a text wraps within w (in screen pixels)
local function height_of(n, w)
	local scale = gui.get_scale(n).x
	local m = resource.get_text_metrics(gui.get_font_resource(gui.get_font(n)), gui.get_text(n),
		{ width = w / scale, line_break = true })
	return m.height * scale
end

-- the picture of the page on its plate, sized to its shape
local function show_picture(s, pg)
	if s.img then ill.story_release(s.img) end
	s.img = nil
	if s.sheet then gui.delete_node(s.sheet) end
	s.sheet = gui.new_box_node(vec(CX, 720 - CY), vec(0, 0))
	gui.set_visible(s.sheet, false)
	gui.set_parent(s.sheet, s.radice)
	s.g = { node = s.sheet, ox = CX, oy = CY }
	local tex, size = ill.story(pg.img)
	local ratio = tex and size.w / size.h or 16 / 9
	if tex then s.img = pg.img end
	local w = math.min(PIC_MAX_W, math.floor(PIC_H * ratio + 0.5))
	s.pic_w = w
	local pw, ph = w + 2 * MARGIN, PIC_H + 2 * MARGIN - 4
	kit.plate(s.g, CX - (pw + 30) / 2, CY - ph / 2, pw, ph, KC.HOT, { sk = 30, fill = KC.SAND, d = 14 })
	kit.picture(s.sheet, tex, w, PIC_H, PIC_SK, ratio)
	s.balloon = nil
	kit.pop(s.sheet, 0, 0.22, 0.96)
end

-- the balloon of the line: in the page's calm corner, over the picture
local function show_line(s)
	local pg = s.pages[s.page]
	local line = pg.lines[s.line]
	if s.balloon then gui.delete_node(s.balloon) end
	s.balloon = nil
	if line then
		local caption = line.chi == "didascalia"
		local who = WHO[line.chi] or WHO.apprendista
		local wide = math.min(BALLOON_W, s.pic_w - 2 * BALLOON_GAP - 20)
		local inner = wide - 2 * BALLOON_PAD - 30
		local name_h = caption and 0 or 26
		-- the text first, to know how tall the balloon is
		local probe = kit.text(s.g, line.testo, 0, 0, TEXT_SIZE, KC.INK)
		local th = height_of(probe, inner)
		gui.delete_node(probe)
		local bh = th + name_h + 2 * BALLOON_PAD
		-- where: the corner of the page
		local hw, hh = s.pic_w / 2, PIC_H / 2
		local where = pg.where or "t"
		local x = where == "tl" and CX - hw + BALLOON_GAP or where == "tr" and CX + hw - BALLOON_GAP - wide - 18 or CX - (wide + 18) / 2
		local y = where == "b" and CY + hh - BALLOON_GAP - bh or CY - hh + BALLOON_GAP
		local b = kit.group(s.g, x + wide / 2, y + bh / 2)
		s.balloon = b.node
		if caption then
			kit.plate(b, x, y, wide, bh, KC.INK, { sk = 18, fill = KC.HOT })
		else
			kit.sand(b, x, y, wide, bh, KC.HOT, { sk = 18 })
			kit.text(b, kit.upper(who[1]), x + 36, y + BALLOON_PAD + 12, 14, who[2], "start", 1.5)
		end
		local text = kit.text(b, line.testo, x + 32, y + BALLOON_PAD + name_h, TEXT_SIZE, KC.INK)
		gui.set_pivot(text, gui.PIVOT_NW)
		gui.set_position(text, vec(x + 32 - b.ox, b.oy - (y + BALLOON_PAD + name_h)))
		gui.set_line_break(text, true)
		gui.set_size(text, vec(inner / gui.get_scale(text).x, 600))
		-- it pops in
		kit.pop(s.balloon, 0, 0.18, 0.85)
	end
	local last = s.page == #s.pages and s.line >= #pg.lines
	gui.set_text(s.next_text, last and TV.go or common.next)
end

local function show_page(s)
	local pg = s.pages[s.page]
	show_picture(s, pg)
	s.line = 1
	for k, n in ipairs(s.dots) do kit.tint(n.parts, k == s.page and KC.SAND or KC.LINE) end
	show_line(s)
end

function M.new(pages, can_skip)
	local s = { pages = pages, page = 1, line = 1, buttons = {}, dots = {} }
	s.fondo = gui.new_box_node(vec(640, 360), vec(1280 * 4, 720 * 4))
	gui.set_color(s.fondo, KC.INK)
	s.radice = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_visible(s.radice, false)
	local g = { node = s.radice, ox = 0, oy = 720 }
	-- one notch per page, when there is more than one
	if #pages > 1 then
		local x0 = 640 - (#pages * 26 - 10) / 2
		for k = 1, #pages do s.dots[k] = kit.para(g, x0 + (k - 1) * 26, 650, 16, 12, 5, KC.LINE) end
	end
	s.low = kit.anchor(0, 720, gui.ANCHOR_LEFT, gui.ANCHOR_BOTTOM)
	s.right = kit.anchor(1280, 720, gui.ANCHOR_RIGHT, gui.ANCHOR_BOTTOM)
	local go = kit.action(s.right, common.next, 930, 610, 270, 76, { size = 50 })
	s.next_text = go.label
	kit.button(s.buttons, go, "avanti", { main = true })
	if can_skip then
		local skip = kit.plate(s.low, 60, 636, 150, 48, KC.PURPLE, { sk = 14, d = 5 })
		kit.text(skip.g, T.skip, 142, 668, 20, KC.SAND, "middle", 0.85)
		kit.button(s.buttons, skip, "salta")
	end
	show_page(s)
	-- the light on AVANTI for the controller
	ui.light(s.buttons, s.buttons[1])
	return s
end

-- the next balloon, or the next page; true when the story is over
local function advance(s)
	local pg = s.pages[s.page]
	if s.line < #pg.lines then
		s.line = s.line + 1
		show_line(s)
		return false
	end
	if s.page >= #s.pages then return true end
	s.page = s.page + 1
	show_page(s)
	return false
end

function M.on_input(s, action_id, action)
	local what = ui.touch(s.buttons, action_id, action)
	if what == "avanti" then
		return advance(s) and "fine" or nil
	elseif what == "salta" then
		return "fine"
	end
	return nil
end

function M.destroy(s)
	if s.img then ill.story_release(s.img) end
	gui.delete_node(s.radice)
	gui.delete_node(s.low.node)
	gui.delete_node(s.right.node)
	gui.delete_node(s.fondo)
end

return M
