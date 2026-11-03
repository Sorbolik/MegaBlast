-- Training (the home's ALLENAMENTO button): a match on the same phone against
-- the bots (sim/bot.lua), with the mode (the player is always the first robot;
-- in 2 vs 2 the teammate is a bot), the level and then the map. The lessons
-- live in the campaign (menu/campaign.lua, Chapter 0). Style in ui/ui.lua.
--
-- The map (Sergio, 3 Nov 2026: only here, the other modes keep a random map):
-- a second page of postcards, A CASO first, then the official maps of the
-- campaign circles in order. The maps of a circle not reached yet are dark
-- with the padlock; those of the first circle are always open. The
-- postcards are the "mappe" texture (strumenti/grafica/miniature_mappe.py).
--
--   local allenamento = require "menu.training"
--   local a = allenamento.new(scelta, stelle)  -- scelta = { modo, livello, mappa } (the last one); stelle = all stars taken
--   local fine = allenamento.on_input(a, action_id, action)
--     -- "indietro", { modo = ..., livello = ..., mappa = id or "caso" } to play against the bots, or nil
--   allenamento.destroy(a)
--   allenamento.open_maps(stelle)  -- the ids of the maps that can be played (A CASO picks among these)

local ui = require "ui.ui"
local campaign = require "sim.campaign"
local maps = require "sim.maps"

local M = {}

local MODES_LIST = { { "1v1", "1 CONTRO 1" }, { "2v2", "2 CONTRO 2" }, { "ffa", "TUTTI CONTRO TUTTI" } }
local LEVELS = { { "facile", "FACILE" }, { "normale", "NORMALE" }, { "difficile", "DIFFICILE" } }
local NAMES = {}
for _, t in ipairs(MODES_LIST) do NAMES[t[1]] = t[2] end
for _, t in ipairs(LEVELS) do NAMES[t[1]] = t[2] end

-- the postcards: A CASO is narrower; at most VISIBLE in a row, arrows for the others
local CARD_W, CARD_H, RANDOM_W, GAP, VISIBLE = 378, 240, 260, 28, 3
local IMG_W, IMG_H = 366, 206
local CARDS_Y = 380

local function vec(x, y) return vmath.vector3(x, y, 0) end

-- The maps of the circles (the chapters girone_N of sim/campaign.lua), in
-- order, each once: not the lesson arenas, which are made for one exercise
local MAPS = {}
do
	local seen = {}
	for _, cap in ipairs(campaign.CAPITOLI) do
		local n = tonumber(cap.id:match("^girone_(%d+)$"))
		for _, l in ipairs(n and cap.missioni or {}) do
			if l.mappa and not l.arena and not seen[l.mappa] then
				seen[l.mappa] = true
				MAPS[#MAPS + 1] = { id = l.mappa, girone = n, serve = cap.serve }
			end
		end
	end
end

local function is_open(m, stars)
	return m.girone == 1 or stars >= m.serve
end

function M.open_maps(stars)
	local list = {}
	for _, m in ipairs(MAPS) do
		if is_open(m, stars) then list[#list + 1] = m.id end
	end
	return list
end

local function postcard(a, x, m)
	local open = is_open(m, a.stelle)
	local n = ui.button(a.buttons, x, CARDS_Y, CARD_W, CARD_H, "", "mappa:" .. m.id, { spento = not open }, a.radice)
	local b = a.buttons[#a.buttons]
	ui.sheet_active(b, a.scelta.mappa == m.id)
	local img = gui.new_box_node(vec(0, (CARD_H - IMG_H) / 2 - 6), vec(IMG_W, IMG_H))
	gui.set_texture(img, "mappe")
	gui.play_flipbook(img, m.id)
	gui.set_parent(img, n)
	gui.move_below(img, b.bordo)
	if not open then gui.set_color(img, vmath.vector4(0.22, 0.2, 0.24, 1)) end
	local name = ui.testo(maps.get(m.id).name, -CARD_W / 2 + 16, -CARD_H / 2 + 22, 0.85, open and ui.C.TEXT or ui.C.OFF, n)
	gui.set_pivot(name, gui.PIVOT_W)
	local circle = ui.testo("GIRONE " .. m.girone, -CARD_W / 2 + 18, CARD_H / 2 - 24, 0.55, ui.C.GOLD, n)
	gui.set_pivot(circle, gui.PIVOT_W)
	if not open then
		ui.testo("Si apre con " .. m.serve .. " stelle", 0, 18, 0.8, ui.C.TEXT, n)
	end
end

local function build_maps(a)
	ui.titolo("SCEGLI LA MAPPA", 640, 640, 1, ui.C.TEXT, a.radice)
	ui.testo(NAMES[a.scelta.modo] .. "  ·  BOT " .. NAMES[a.scelta.livello], 640, 584, 0.6, ui.C.OFF, a.radice)
	-- the row: A CASO and the maps from the first visible one
	local cards = { { random = true } }
	for _, m in ipairs(MAPS) do cards[#cards + 1] = m end
	local first = math.max(1, math.min(a.da, #cards - VISIBLE + 1))
	a.da = first
	local last = math.min(#cards, first + VISIBLE - 1)
	local w = 0
	for i = first, last do w = w + (cards[i].random and RANDOM_W or CARD_W) + (i > first and GAP or 0) end
	local x = 640 - w / 2
	for i = first, last do
		local c = cards[i]
		local cw = c.random and RANDOM_W or CARD_W
		if c.random then
			local n = ui.button(a.buttons, x + cw / 2, CARDS_Y, cw, CARD_H, "", "mappa:caso", nil, a.radice)
			ui.sheet_active(a.buttons[#a.buttons], a.scelta.mappa == "caso")
			ui.titolo("?", 0, 22, 2.2, ui.C.LIGHT, n)
			ui.testo("A CASO", 0, -CARD_H / 2 + 22, 0.85, ui.C.TEXT, n)
		else
			postcard(a, x + cw / 2, c)
		end
		x = x + cw + GAP
	end
	if first > 1 then ui.button(a.buttons, 40, CARDS_Y, 56, 120, "<", "scorri:-1", nil, a.radice) end
	if last < #cards then ui.button(a.buttons, 1240, CARDS_Y, 56, 120, ">", "scorri:1", nil, a.radice) end
	ui.button(a.buttons, 640, 140, 340, 108, "GIOCA", "gioca", { main = true }, a.radice)
end

local function build_mode(a)
	local c = ui.C
	ui.titolo("ALLENAMENTO", 640, 640, 1, c.TEXT, a.radice)
	ui.testo("MODO", 640, 520, 0.7, c.OFF, a.radice)
	for i, m in ipairs(MODES_LIST) do
		ui.scheda(a.buttons, 640 + (i - 2) * 330, 460, 310, 64, m[2], "modo:" .. m[1], a.scelta.modo == m[1], a.radice)
	end
	ui.testo("BOT", 640, 360, 0.7, c.OFF, a.radice)
	for i, l in ipairs(LEVELS) do
		ui.scheda(a.buttons, 640 + (i - 2) * 250, 300, 230, 64, l[2], "livello:" .. l[1], a.scelta.livello == l[1], a.radice)
	end
	ui.button(a.buttons, 640, 140, 340, 108, "AVANTI", "avanti", { main = true }, a.radice)
end

local function build(a)
	if a.radice then gui.delete_node(a.radice) end
	a.buttons = {}
	a.radice = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_visible(a.radice, false)
	ui.indietro(a.buttons, "indietro", a.radice)
	if a.pagina == "mappa" then build_maps(a) else build_mode(a) end
end

function M.new(choice, stars)
	local a = { scelta = choice, stelle = stars or 0, pagina = "modo", da = 1 }
	-- a map that has been closed (or removed) goes back to A CASO
	local ok = choice.mappa == "caso"
	for _, id in ipairs(M.open_maps(a.stelle)) do ok = ok or id == choice.mappa end
	if not ok then choice.mappa = "caso" end
	-- the chosen map in view
	for i, m in ipairs(MAPS) do
		if m.id == choice.mappa then a.da = math.max(1, i + 2 - VISIBLE) end
	end
	a.fondo = ui.sfondo()
	build(a)
	return a
end

function M.on_input(a, action_id, action)
	local ui_action = ui.tocco(a.buttons, action_id, action)
	if not ui_action then return nil end
	if ui_action == "indietro" then
		if a.pagina == "modo" then return "indietro" end
		a.pagina = "modo"
	elseif ui_action == "avanti" then
		a.pagina = "mappa"
	elseif ui_action == "gioca" then
		return { modo = a.scelta.modo, livello = a.scelta.livello, mappa = a.scelta.mappa }
	else
		local kind, value = ui_action:match("^(%a+):(.*)$")
		if kind == "scorri" then
			a.da = a.da + tonumber(value)
		else
			a.scelta[kind] = value
		end
	end
	build(a)
	return nil
end

function M.destroy(a)
	gui.delete_node(a.radice)
	gui.delete_node(a.fondo)
end

return M
