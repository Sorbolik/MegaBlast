-- Campaign (the home's CAMPAGNA button): the chapters of sim/campaign.lua in
-- tabs, the Training (the lessons) first. Each mission is a card with the
-- title, the stars taken and what it takes to get them all, so you know
-- beforehand how to do better. A chapter opens with everyone's stars
-- (chapter.serve): closed, it says how many are missing. Style in ui/ui.lua.
--
--   local campagna = require "menu.campagna"
--   local c = campagna.new(scelta, stelle)  -- scelta = { chapter } (the last one opened); stelle = id -> { true, false, true }
--   local fine = campagna.on_input(c, action_id, action)
--     -- "indietro", { missione = id } to play it, or nil
--   campagna.destroy(c)

local ui = require "ui.ui"
local payload = require "sim.campaign"
local missions = require "sim.missions"

local M = {}

-- the missions in three columns
local CARD_W, CARD_H, COLUMNS, STEP_Y = 360, 100, 3, 116

local function vec(x, y) return vmath.vector3(x, y, 0) end

local function total(stars)
	local n = 0
	for _, v in pairs(stars) do n = n + missions.quante(v) end
	return n
end

local function is_opened(c, cap)
	return total(c.stelle) >= cap.serve
end

-- each star lit for its own criterion: also the first and third yes and the second no
local function little_stars(picked, x, y, parent)
	for i = 1, 3 do
		ui.stella(x + (i - 2) * 28, y, 26, picked[i] and ui.GOLD or ui.C.LINE, parent)
	end
end

local function card_list(c, cap)
	for i, l in ipairs(cap.missioni) do
		local col, riga = (i - 1) % COLUMNS, math.floor((i - 1) / COLUMNS)
		local x, y = 640 + (col - 1) * (CARD_W + 24), 440 - riga * STEP_Y
		local n = ui.button(c.buttons, x, y, CARD_W, CARD_H, "", "missione:" .. l.id, nil, c.radice)
		local picked = c.stelle[l.id] or {}
		ui.testo(string.upper(l.titolo), 0, 26, 0.8, ui.C.TEXT, n)
		little_stars(picked, 0, -2, n)
		-- what is missing: the criteria of the unlit stars
		local cr, missing = missions.criteria(l), {}
		for i = 2, 3 do
			if not picked[i] then missing[#missing + 1] = cr[i] end
		end
		if #missing > 0 then ui.testo(table.concat(missing, "  -  "), 0, -32, 0.55, ui.C.OFF, n) end
	end
end

local function build(c)
	if c.radice then gui.delete_node(c.radice) end
	c.buttons = {}
	c.radice = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_visible(c.radice, false)
	local C = ui.C
	ui.indietro(c.buttons, "indietro", c.radice)
	ui.titolo("CAMPAGNA", 640, 640, 1, C.TEXT, c.radice)
	local n = #payload.CAPITOLI
	local w = math.min(420, math.floor(1100 / n) - 20)
	local chosen
	for i, cap in ipairs(payload.CAPITOLI) do
		local is_active = c.scelta.chapter == cap.id
		if is_active then chosen = cap end
		ui.scheda(c.buttons, 640 + (i - (n + 1) / 2) * (w + 20), 560, w, 56, string.upper(cap.titolo),
			"capitolo:" .. cap.id, is_active, c.radice)
	end
	if is_opened(c, chosen) then
		card_list(c, chosen)
	else
		local has_it = total(c.stelle)
		ui.testo("Si apre con " .. chosen.serve .. " stelle: ne hai " .. has_it, 640, 400, 1, C.TEXT, c.radice)
		ui.testo("Le stelle si prendono nelle missioni dei capitoli prima", 640, 350, 0.75, C.OFF, c.radice)
	end
end

function M.new(choice, stars)
	local c = { scelta = choice, stelle = stars or {} }
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
	if ui_action == "indietro" then return "indietro" end
	local kind, value = ui_action:match("^(%a+):(.*)$")
	if kind == "missione" then return { missione = value } end
	c.scelta.chapter = value
	build(c)
	return nil
end

function M.destroy(c)
	gui.delete_node(c.radice)
	gui.delete_node(c.fondo)
end

return M
