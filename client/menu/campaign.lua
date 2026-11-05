-- Campaign (the home's CAMPAGNA button): the chapters of sim/campaign.lua in
-- tabs, the Training (the lessons) first. Each chapter is the board of the
-- Forge: its missions pinned as postcards with the illustration
-- (ui/illustrations.lua), the title and the stars taken, the final as the
-- wide strip at the bottom. A chapter opens with everyone's stars
-- (chapter.serve): closed, it says how many are missing. Style in ui/ui.lua.
--
--   local campagna = require "menu.campaign"
--   local c = campagna.new(scelta, stelle, storia)  -- scelta = { chapter } (the last one opened); stelle = id -> { true, false, true };
--     storia: some of the story was seen (ui/story.lua): LA STORIA, top right, reads it again
--   local fine = campagna.on_input(c, action_id, action)
--     -- "indietro", { missione = id, da } to play it (da: where its picture is), "storia", or nil
--   campagna.destroy(c)

local ui = require "ui.ui"
local payload = require "sim.campaign"
local missions = require "sim.missions"
local ill = require "ui.illustrations"
local T = require("lang.text").campaign
local TS = require("lang.text").story
local common = require("lang.text").common

local M = {}

-- The board of the Forge (Sergio, 4 Nov, «me gusta»): the chapter's
-- challenges pinned on a wooden board as parchment postcards, three a row,
-- the illustration filling the card and title and stars on the band under
-- it; the next one to do framed in gold; the chapter's final as the wide
-- strip at the bottom, with a piece of its story panel. Sized so it fits on
-- 4:3 too (960 wide)
local CARD_W, PIC_W, PIC_H, BAND, GAP_X, GAP_Y, BOARD_PAD = 280, 268, 151, 34, 14, 12, 14
local CARD_H, COLUMNS = 6 + PIC_H + BAND, 3
-- the board's width with its frame (the tabs over it are as wide)
local BOARD_OUTER = COLUMNS * CARD_W + (COLUMNS - 1) * GAP_X + 2 * BOARD_PAD + 12
local FINAL_H, FINAL_PIC_W, FINAL_PIC_H = 56, 260, 44
local function c4(r, g, b, a) return vmath.vector4(r, g, b, a or 1) end
local PAPER, INK, INK_SOFT = c4(0.95, 0.88, 0.75), c4(0.12, 0.07, 0.05), c4(0.12, 0.07, 0.05, 0.22)
local WOOD, WOOD_DARK, PLANK = c4(0.29, 0.17, 0.09), c4(0.17, 0.10, 0.05), c4(0.23, 0.13, 0.07)
local NAIL, NAIL_LIGHT, EMPTY = c4(0.20, 0.20, 0.22), c4(0.62, 0.62, 0.66), c4(0.16, 0.10, 0.07)
local GOLD_INK = c4(0.72, 0.50, 0.08)

-- a text no wider than w: it shrinks (never deforms)
local function fit(n, w)
	local width = resource.get_text_metrics(gui.get_font_resource(gui.get_font(n)), gui.get_text(n)).width * gui.get_scale(n).x
	if width > w then gui.set_scale(n, gui.get_scale(n) * (w / width)) end
	return n
end

local function vec(x, y) return vmath.vector3(x, y, 0) end

local function total(stars)
	local n = 0
	for _, v in pairs(stars) do n = n + missions.quante(v) end
	return n
end

local function is_opened(c, cap)
	return total(c.stelle) >= cap.serve
end

-- each star lit for its own criterion: also the first and third yes and the
-- second no. The cortile: «Fatta» and Favilla's medal (or «Fatta» alone).
-- Right aligned at x
local function little_stars(picked, count, medal, x, y, parent)
	for i = 1, count do
		local draw = medal and i == 2 and ui.medaglia or ui.stella
		local lit = medal and i == 2 and ui.MEDAL or ui.GOLD
		draw(x - (count - i) * 22 - 10, y, 20, picked[i] and lit or INK_SOFT, parent)
	end
end

local function box(x, y, w, h, color, parent)
	local n = gui.new_box_node(vec(x, y), vec(w, h))
	gui.set_color(n, color)
	gui.set_adjust_mode(n, gui.ADJUST_FIT)
	gui.set_parent(n, parent)
	return n
end

-- ink text on the parchment, its left end at x
local function ink(t, x, y, scale, color, parent)
	local n = ui.testo(t, x, y, scale, color or INK, parent)
	gui.set_pivot(n, gui.PIVOT_W)
	gui.set_outline(n, c4(0, 0, 0, 0))
	gui.set_shadow(n, c4(0, 0, 0, 0))
	return n
end

-- a nail at the top of a card
local function nail(x, y, parent)
	ui.disco(x, y, 18, NAIL, parent)
	ui.disco(x - 3, y + 3, 7, NAIL_LIGHT, parent)
end

-- a card of the board (a button: tap and controller light), parchment with
-- the ink border; the picture (or its empty place) at x, y on the card
local function card(c, l, x, y, w, h, kind, pic_x, pic_y, pic_w, pic_h)
	local n = ui.button(c.buttons, x, y, w, h, "", "missione:" .. l.id, nil, c.board)
	local b = c.buttons[#c.buttons]
	gui.set_color(n, PAPER)
	b.riposo = INK
	gui.set_color(b.bordo, INK)
	box(pic_x, pic_y, pic_w + 4, pic_h + 4, INK, n)
	local tex = ill.texture(l.id, kind)
	if tex then
		c.textures[#c.textures + 1] = { l.id, kind }
		local t = box(pic_x, pic_y, pic_w, pic_h, c4(1, 1, 1), n)
		gui.set_texture(t, tex)
		-- where the picture is on the screen: the postcard zooms from here (ui/postcard.lua)
		local bp = gui.get_position(c.board)
		c.from[l.id] = { x = bp.x + x + pic_x, y = bp.y + y + pic_y + gui.get_position(c.radice).y, w = pic_w, h = pic_h }
	else
		box(pic_x, pic_y, pic_w, pic_h, EMPTY, n)
	end
	return n
end

-- the stars, or NUOVA on the next one to do, right aligned at x
local function state(c, l, is_next, x, y, n)
	if is_next then
		local t = ui.testo(T.new, x, y, 0.62, GOLD_INK, n)
		gui.set_pivot(t, gui.PIVOT_E)
		gui.set_outline(t, c4(0, 0, 0, 0))
		gui.set_shadow(t, c4(0, 0, 0, 0))
		return t
	end
	little_stars(c.stelle[l.id] or {}, #missions.criteria(l), l.medaglia ~= nil, x, y, n)
end

-- the gold frame of the next one, behind its card
local function gold(x, y, w, h, parent)
	box(x, y, w + 10, h + 10, ui.GOLD, parent)
end

local function card_list(c, cap)
	local list = cap.missioni
	-- the final: the chapter's last mission; the others pinned on the board
	local final = #list > 1 and list[#list] or nil
	local pinned = #list - (final and 1 or 0)
	local rows = math.ceil(pinned / COLUMNS)
	local inner_w = COLUMNS * CARD_W + (COLUMNS - 1) * GAP_X
	local board_w = inner_w + 2 * BOARD_PAD
	local board_h = 2 * BOARD_PAD + rows * CARD_H + (rows - 1) * GAP_Y + (final and GAP_Y + FINAL_H or 0)
	local top = ui.BODY_TOP - 6
	-- the board: dark frame, the wood, its planks
	c.board = box(640, top - board_h / 2, board_w + 12, board_h + 12, WOOD_DARK, c.radice)
	box(0, 0, board_w, board_h, WOOD, c.board)
	for py = board_h / 2 - 58, -board_h / 2 + 10, -58 do box(0, py, board_w, 3, PLANK, c.board) end
	-- the next one to do: the first without «Fatta»
	local next_id
	for _, l in ipairs(list) do
		if not (c.stelle[l.id] or {})[1] then next_id = l.id; break end
	end
	local y0 = board_h / 2 - BOARD_PAD
	for i = 1, pinned do
		local l = list[i]
		local col, row = (i - 1) % COLUMNS, math.floor((i - 1) / COLUMNS)
		local x = -inner_w / 2 + CARD_W / 2 + col * (CARD_W + GAP_X)
		local y = y0 - CARD_H / 2 - row * (CARD_H + GAP_Y)
		if l.id == next_id then gold(x, y, CARD_W, CARD_H, c.board) end
		local n = card(c, l, x, y, CARD_W, CARD_H, "carta", 0, CARD_H / 2 - 6 - PIC_H / 2, PIC_W, PIC_H)
		local by = -CARD_H / 2 + BAND / 2 + 1
		local title = ink(string.upper(l.titolo), -CARD_W / 2 + 12, by, 0.62, INK, n)
		fit(title, CARD_W - 24 - (l.id == next_id and 70 or 26 * #missions.criteria(l)))
		state(c, l, l.id == next_id, CARD_W / 2 - 12, by, n)
		nail(x, y + CARD_H / 2 - 2, c.board)
	end
	if final then
		local y = -board_h / 2 + BOARD_PAD + FINAL_H / 2
		if final.id == next_id then gold(0, y, inner_w, FINAL_H, c.board) end
		local px = -inner_w / 2 + 6 + FINAL_PIC_W / 2
		local n = card(c, final, 0, y, inner_w, FINAL_H, "finale", px, 0, FINAL_PIC_W, FINAL_PIC_H)
		local tx = px + FINAL_PIC_W / 2 + 22
		fit(ink(T.final:format(string.upper(final.titolo)), tx, 0, 0.8, INK, n), inner_w / 2 - tx - 120)
		state(c, final, final.id == next_id, inner_w / 2 - 16, 0, n)
		nail(-inner_w / 2 + 8, y + FINAL_H / 2 - 2, c.board)
		nail(inner_w / 2 - 8, y + FINAL_H / 2 - 2, c.board)
	end
end

-- the card illustrations of the chapter shown, given back to the GPU
local function release_textures(c)
	for _, t in ipairs(c.textures or {}) do ill.release(t[1], t[2]) end
	c.textures = {}
end

local function build(c)
	if c.radice then gui.delete_node(c.radice) end
	release_textures(c)
	c.buttons = {}
	c.radice = ui.radice()
	c.from = {}
	local C = ui.C
	-- the header (ui.header): CAMPAGNA, the pill's place, the chapters as tabs under it
	ui.header_delete(c.head)
	c.head = ui.header(c.buttons, common.campaign, "indietro")
	if c.storia then ui.button(c.buttons, -ui.EDGE - 110, 0, 220, 64, TS.read_again, "storia", nil, c.head.right) end
	-- the chapters' tabs as wide as the board, over it (Sergio, 4 Nov)
	local n = #payload.CAPITOLI
	local w = math.floor((BOARD_OUTER - 12 * (n - 1)) / n)
	local chosen, tabs, active = nil, {}, 1
	for i, cap in ipairs(payload.CAPITOLI) do
		if c.scelta.chapter == cap.id then chosen, active = cap, i end
		tabs[i] = { string.upper(cap.titolo), "capitolo:" .. cap.id, w }
	end
	ui.header_tabs(c.head, c.buttons, tabs, active, 640 - BOARD_OUTER / 2)
	if is_opened(c, chosen) then
		card_list(c, chosen)
	else
		local has_it = total(c.stelle)
		ui.testo(T.opens_with:format(chosen.serve, has_it), 640, 400, 1, C.TEXT, c.radice)
		ui.testo(T.stars_hint, 640, 350, 0.75, C.OFF, c.radice)
	end
end

function M.new(choice, stars, story)
	local c = { scelta = choice, stelle = stars or {}, storia = story }
	-- the first time, the last chapter opened
	if not choice.chapter then
		for _, cap in ipairs(payload.CAPITOLI) do
			if is_opened(c, cap) then choice.chapter = cap.id end
		end
	end
	c.fondo = ui.sfondo()
	build(c)
	return c
end

function M.on_input(c, action_id, action)
	local ui_action = ui.tocco(c.buttons, action_id, action)
	if not ui_action then return nil end
	if ui_action == "indietro" or ui_action == "storia" then return ui_action end
	local kind, value = ui_action:match("^(%a+):(.*)$")
	if kind == "missione" then return { missione = value, da = c.from[value] } end
	c.scelta.chapter = value
	build(c)
	return nil
end

function M.destroy(c)
	ui.header_delete(c.head)
	gui.delete_node(c.radice)
	release_textures(c)
	gui.delete_node(c.fondo)
end

return M
