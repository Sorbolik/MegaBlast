-- Campaign (the home's CAMPAGNA button): the chapters of sim/campaign.lua in
-- tabs, the Training (the lessons) first. Each mission is a card with the
-- title, the stars taken and what it takes to get them all, so you know
-- beforehand how to do better, and its illustration (ui/illustrations.lua). A chapter opens with everyone's stars
-- (chapter.serve): closed, it says how many are missing. Style in ui/ui.lua.
--
--   local campagna = require "menu.campaign"
--   local c = campagna.new(scelta, stelle, storia)  -- scelta = { chapter } (the last one opened); stelle = id -> { true, false, true };
--     storia: some of the story was seen (ui/story.lua): LA STORIA, top right, reads it again
--   local fine = campagna.on_input(c, action_id, action)
--     -- "indietro", { missione = id } to play it, "storia", or nil
--   campagna.destroy(c)

local ui = require "ui.ui"
local payload = require "sim.campaign"
local missions = require "sim.missions"
local ill = require "ui.illustrations"
local T = require("lang.text").campaign
local TS = require("lang.text").story
local common = require("lang.text").common

local M = {}

-- the missions in three columns
local CARD_W, CARD_H, COLUMNS, STEP_Y = 360, 100, 3, 116
-- the illustration's window on the left of the card (WB-015, 16:9), and the
-- column of title and stars on its right
local THUMB_W, THUMB_H, PAD = 148, 83, 9

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
-- second no. The cortile: «Fatta» and Favilla's medal (or «Fatta» alone)
local function little_stars(picked, count, medal, x, y, parent)
	for i = 1, count do
		local draw = medal and i == 2 and ui.medaglia or ui.stella
		local lit = medal and i == 2 and ui.MEDAL or ui.GOLD
		draw(x + (i - (count + 1) / 2) * 28, y, 26, picked[i] and lit or ui.C.LINE, parent)
	end
end

local function card_list(c, cap)
	for i, l in ipairs(cap.missioni) do
		local col, riga = (i - 1) % COLUMNS, math.floor((i - 1) / COLUMNS)
		local x, y = 640 + (col - 1) * (CARD_W + 24), ui.BODY_TOP - CARD_H / 2 - riga * STEP_Y
		local n = ui.button(c.buttons, x, y, CARD_W, CARD_H, "", "missione:" .. l.id, nil, c.radice)
		local picked = c.stelle[l.id] or {}
		-- with its illustration the texts go in the column on its right
		local cx, cw = 0, CARD_W - 2 * PAD
		local tex = ill.texture(l.id, "carta")
		if tex then
			c.textures[#c.textures + 1] = l.id
			local t = gui.new_box_node(vec(-CARD_W / 2 + PAD + THUMB_W / 2, 0), vec(THUMB_W, THUMB_H))
			gui.set_texture(t, tex)
			gui.set_adjust_mode(t, gui.ADJUST_FIT)
			gui.set_parent(t, n)
			cw = CARD_W - THUMB_W - 3 * PAD
			cx = CARD_W / 2 - PAD - cw / 2
		end
		fit(ui.testo(string.upper(l.titolo), cx, 26, 0.8, ui.C.TEXT, n), cw)
		local cr, missing = missions.criteria(l), {}
		little_stars(picked, #cr, l.medaglia ~= nil, cx, -2, n)
		-- what is missing: the criteria of the unlit stars
		for i = 2, #cr do
			if not picked[i] then missing[#missing + 1] = cr[i] end
		end
		if #missing > 0 then fit(ui.testo(table.concat(missing, "  -  "), cx, -32, 0.55, ui.C.OFF, n), cw) end
	end
end

-- the card illustrations of the chapter shown, given back to the GPU
local function release_textures(c)
	for _, id in ipairs(c.textures or {}) do ill.release(id, "carta") end
	c.textures = {}
end

local function build(c)
	if c.radice then gui.delete_node(c.radice) end
	release_textures(c)
	c.buttons = {}
	c.radice = ui.radice()
	local C = ui.C
	-- the header (ui.header): CAMPAGNA, the pill's place, the chapters as tabs under it
	ui.header_delete(c.head)
	c.head = ui.header(c.buttons, common.campaign, "indietro")
	if c.storia then ui.button(c.buttons, -ui.EDGE - 110, 0, 220, 64, TS.read_again, "storia", nil, c.head.right) end
	local n = #payload.CAPITOLI
	local w = math.min(420, math.floor(1100 / n) - 20)
	local chosen, tabs, active = nil, {}, 1
	for i, cap in ipairs(payload.CAPITOLI) do
		if c.scelta.chapter == cap.id then chosen, active = cap, i end
		tabs[i] = { string.upper(cap.titolo), "capitolo:" .. cap.id, w }
	end
	ui.header_tabs(c.head, c.buttons, tabs, active)
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
	if kind == "missione" then return { missione = value } end
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
