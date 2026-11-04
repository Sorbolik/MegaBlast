-- The story's comic (ui/story.lua): one panel at a time on the postcard of
-- the mission illustrations (the parchment card on an opaque backdrop,
-- battle/vignette.lua), each panel with its own shape (wide or square), and
-- its lines one balloon at a time in the calm corner of the panel. AVANTI (or
-- A) goes on; SALTA only when you have already read it (Sergio, 4 Nov: the
-- first time the story is watched whole). Client only.
--
--   local comic = require "menu.story"
--   local s = comic.new(pages, can_skip)   -- pages: ui/story.lua's pages
--   comic.on_input(s, action_id, action)   -- "fine" when it's over (or skipped)
--   comic.destroy(s)

local ui = require "ui.ui"
local ill = require "ui.illustrations"
local T = require("lang.text").story
local TV = require("lang.text").vignette
local common = require("lang.text").common

local M = {}

local function c(r, g, b, a) return vmath.vector4(r, g, b, a or 1) end
-- the comic's colors (the same as the vignettes)
local PAPER, INK, INK_SOFT = c(0.95, 0.88, 0.75), c(0.12, 0.07, 0.05), c(0.12, 0.07, 0.05, 0.4)
local CAPTION = c(0.95, 0.77, 0.35)
local BACKDROP = c(0.09, 0.07, 0.07)
-- the picture's height (as the missions' postcard), at most this wide; the
-- parchment margin and the band under it with the dots and the buttons
local PIC_H, PIC_MAX_W, MARGIN, BAND, CARD_Y = 495, 1100, 18, 84, 12
-- the balloon: at most this wide, its padding, its distance from the picture's edges
local BALLOON_W, BALLOON_PAD, BALLOON_GAP, TEXT_K = 430, 18, 22, 0.56

-- who speaks: name and color (the vignettes' ones, plus the voice from the dark)
local WHO = {
	favilla = { TV.favilla, c(0.28, 0.44, 0.56) },
	fabbro = { TV.fabbro, c(0.72, 0.26, 0.16) },
	apprendista = { TV.apprendista, c(0.72, 0.26, 0.16) },
	voce = { T.voice, c(0.30, 0.55, 0.75) },
}

local function vec(x, y) return vmath.vector3(x, y, 0) end

local function box(x, y, w, h, color, parent)
	local n = gui.new_box_node(vec(x, y), vec(w, h))
	gui.set_color(n, color)
	if parent then gui.set_parent(n, parent) end
	return n
end

-- ink text, left aligned from its top left corner, wrapping within w
local function ink(t, x, y, scale, color, w, parent)
	local n = gui.new_text_node(vec(x, y), t)
	gui.set_font(n, "titolo")
	gui.set_color(n, color)
	gui.set_outline(n, c(0, 0, 0, 0))
	gui.set_shadow(n, c(0, 0, 0, 0))
	gui.set_scale(n, vmath.vector3(scale, scale, 1))
	gui.set_pivot(n, gui.PIVOT_NW)
	if w then
		gui.set_line_break(n, true)
		gui.set_size(n, vec(w / scale, 600))
	end
	gui.set_parent(n, parent)
	return n
end

-- how tall a text wraps within w (in screen pixels)
local function height_of(n, w, scale)
	local m = resource.get_text_metrics(gui.get_font_resource(gui.get_font(n)), gui.get_text(n),
		{ width = w / scale, line_break = true })
	return m.height * scale
end

-- the picture of the page: its texture, the card sized to its shape
local function show_picture(s, pg)
	if s.img then ill.story_release(s.img) end
	s.img = nil
	local tex, size = ill.story(pg.img)
	if not tex then return end
	s.img = pg.img
	local w = math.min(PIC_MAX_W, math.floor(PIC_H * size.w / size.h + 0.5))
	s.pic_w = w
	gui.set_texture(s.pic, tex)
	gui.set_size(s.pic, vec(w, PIC_H))
	gui.set_size(s.frame, vec(w + 6, PIC_H + 6))
	local card_w = w + 2 * MARGIN
	gui.set_size(s.card, vec(card_w, MARGIN + PIC_H + BAND))
	gui.set_size(s.card_line, vec(card_w, MARGIN + PIC_H + BAND))
	gui.set_size(s.shadow, vec(card_w, MARGIN + PIC_H + BAND))
	-- the buttons at the band's ends, the dots in the middle
	local by = -(MARGIN + PIC_H + BAND) / 2 + BAND / 2
	gui.set_position(s.next_btn, vec(card_w / 2 - MARGIN - 110, by))
	if s.skip_btn then gui.set_position(s.skip_btn, vec(-card_w / 2 + MARGIN + 80, by)) end
	-- the dots between SALTA (or the edge) and AVANTI: on a square panel the band is short
	local left = -card_w / 2 + MARGIN + (s.skip_btn and 160 or 0)
	local right = card_w / 2 - MARGIN - 220
	gui.set_position(s.dots_root, vec((left + right) / 2, by))
end

-- the balloon of the line: in the page's calm corner, over the picture
local function show_line(s)
	local pg = s.pages[s.page]
	local line = pg.lines[s.line]
	if s.balloon then gui.delete_node(s.balloon) end
	s.balloon = nil
	if not line then return end
	local caption = line.chi == "didascalia"
	local who = WHO[line.chi] or WHO.apprendista
	local inner = BALLOON_W - 2 * BALLOON_PAD
	s.balloon = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_visible(s.balloon, false)
	gui.set_parent(s.balloon, s.pic)
	local name_h = caption and 0 or 30
	local text = ink(line.testo, 0, 0, TEXT_K, INK, inner, s.balloon)
	local th = height_of(text, inner, TEXT_K)
	local bh = th + name_h + 2 * BALLOON_PAD
	-- where: the corner of the page (the picture's center is 0, 0)
	local hw, hh = s.pic_w / 2, PIC_H / 2
	local x, y
	local where = pg.where or "t"
	if where == "tl" then x, y = -hw + BALLOON_GAP + BALLOON_W / 2, hh - BALLOON_GAP - bh / 2
	elseif where == "tr" then x, y = hw - BALLOON_GAP - BALLOON_W / 2, hh - BALLOON_GAP - bh / 2
	elseif where == "b" then x, y = 0, -hh + BALLOON_GAP + bh / 2
	else x, y = 0, hh - BALLOON_GAP - bh / 2 end
	gui.set_position(s.balloon, vec(x, y))
	-- the ink outline, the paper (the caption box is yellow and square)
	box(0, 0, BALLOON_W + 6, bh + 6, INK, s.balloon)
	local paper = box(0, 0, BALLOON_W, bh, caption and CAPTION or PAPER, s.balloon)
	if not caption then
		local name = ink(who[1], -BALLOON_W / 2 + BALLOON_PAD, bh / 2 - BALLOON_PAD, 0.42, who[2], nil, paper)
		gui.set_parent(name, paper)
	end
	gui.set_parent(text, paper)
	gui.set_position(text, vec(-BALLOON_W / 2 + BALLOON_PAD, bh / 2 - BALLOON_PAD - name_h))
	-- it pops in
	gui.set_scale(s.balloon, vmath.vector3(0.85, 0.85, 1))
	gui.animate(s.balloon, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, 0.18)
	local last = s.page == #s.pages and s.line >= #pg.lines
	gui.set_text(s.next_text, last and TV.go or common.next)
end

local function show_page(s)
	local pg = s.pages[s.page]
	show_picture(s, pg)
	s.line = 1
	for k, n in ipairs(s.dots) do gui.set_color(n, k == s.page and INK or INK_SOFT) end
	show_line(s)
end

function M.new(pages, can_skip)
	local s = { pages = pages, page = 1, line = 1, buttons = {}, dots = {} }
	s.fondo = box(640, 360, 1280 * 4, 720 * 4, BACKDROP)
	s.radice = gui.new_box_node(vec(640, 360 + CARD_Y), vec(0, 0))
	gui.set_visible(s.radice, false)
	s.shadow = box(10, -12, 100, 100, c(0, 0, 0, 0.45), s.radice)
	s.card, s.card_line = ui.pannello(0, 0, 100, 100, s.radice)
	gui.set_color(s.card, PAPER)
	gui.set_color(s.card_line, INK)
	local iy = (MARGIN + PIC_H + BAND) / 2 - MARGIN - PIC_H / 2
	s.frame = box(0, iy, 100, PIC_H + 6, INK, s.card)
	s.pic = gui.new_box_node(vec(0, iy), vec(100, PIC_H))
	gui.set_adjust_mode(s.pic, gui.ADJUST_FIT)
	gui.set_parent(s.pic, s.card)
	local by = -(MARGIN + PIC_H + BAND) / 2 + BAND / 2
	s.next_btn = ui.button(s.buttons, 0, by, 220, 56, "", "avanti", { main = true }, s.card)
	s.next_text = ink("", 0, 0, 0.7, ui.C.TEXT, nil, s.next_btn)
	gui.set_pivot(s.next_text, gui.PIVOT_CENTER)
	if can_skip then
		s.skip_btn = ui.button(s.buttons, 0, by, 160, 56, T.skip, "salta", nil, s.card)
	end
	-- one dot per page, when there is more than one
	s.dots_root = gui.new_box_node(vec(0, by), vec(0, 0))
	gui.set_visible(s.dots_root, false)
	gui.set_parent(s.dots_root, s.card)
	if #pages > 1 then
		local step = math.min(18, 90 / (#pages - 1))
		for k = 1, #pages do
			s.dots[k] = ui.disco((k - (#pages + 1) / 2) * step, 0, math.min(10, step - 3), INK_SOFT, s.dots_root)
		end
	end
	show_page(s)
	-- the light on AVANTI for the controller
	ui.luce(s.buttons, s.buttons[1])
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
	local what = ui.tocco(s.buttons, action_id, action)
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
	gui.delete_node(s.fondo)
end

return M
