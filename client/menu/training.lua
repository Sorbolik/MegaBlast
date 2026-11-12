-- Training (the home's ALLENAMENTO door, Figma 16): a match without the net, on
-- one page: who is there (the bots of sim/bot.lua, or friends on the same
-- phone), the mode (against the bots the player is always the first robot; in
-- 2 vs 2 the teammate is a bot), the bots' level and the map. The lessons
-- live in the campaign (menu/campaign.lua, Chapter 0). Style in ui/ui.lua.
--
-- The map (Sergio, 3 Nov 2026: only here, the other modes keep a random map):
-- a row of cards, A CASO first, then the official maps of the
-- campaign circles in order. The maps of a circle not reached yet are dark
-- with the padlock; those of the first circle are always open. The
-- postcards are the "mappe" texture (tools/grafica/miniature_mappe.py).
--
--   local allenamento = require "menu.training"
--   local a = allenamento.new(scelta, stelle)  -- scelta = { modo, livello, mappa } (the last one); stelle = all stars taken
--   local fine = allenamento.on_input(a, action_id, action)
--     -- "indietro", { modo = ..., livello = ..., mappa = id or "caso", stesso = true on the same phone } to play, or nil
--   allenamento.destroy(a)
--   allenamento.open_maps(stelle)  -- the ids of the maps that can be played (A CASO picks among these)

local ui = require "ui.ui"
local kit = require "ui.kit"
local scoria = require "battle.scoria"
local profile_tabs = require "menu.profile_tabs"
local campaign = require "sim.campaign"
local maps = require "sim.maps"
local T = require("lang.text").training
local common = require("lang.text").common

local M = {}

local MODES_LIST = { { "1v1", common.modes["1v1"] }, { "2v2", common.modes["2v2"] }, { "ffa", common.modes.ffa } }
local LEVELS = { { "facile", T.levels.facile }, { "normale", T.levels.normale }, { "difficile", T.levels.difficile } }
local NAMES = {}
for _, t in ipairs(MODES_LIST) do NAMES[t[1]] = t[2] end
for _, t in ipairs(LEVELS) do NAMES[t[1]] = t[2] end

local KC = kit.C
-- the map cards in a row: at most VISIBLE, arrows for the others
local VISIBLE = 4

-- The maps of the chapters of sim/campaign.lua (the Addestramento's cortile,
-- then the circles girone_N), in order, each once: not the lesson arenas,
-- which are made for one exercise; then the maps of the circles whose levels are not
-- in the campaign yet (maps.CIRCLES), open
local MAPS = {}
do
	local seen = {}
	for _, cap in ipairs(campaign.CAPITOLI) do
		local n = cap.id == "addestramento" and 0 or tonumber(cap.id:match("^girone_(%d+)$"))
		for _, l in ipairs(n and cap.missioni or {}) do
			if l.mappa and not l.arena and not seen[l.mappa] then
				seen[l.mappa] = true
				MAPS[#MAPS + 1] = { id = l.mappa, girone = n, serve = cap.serve }
			end
		end
	end
	-- the circles' maps the campaign does not play yet: all open for now (sim/maps.lua CIRCLES)
	for _, id in ipairs(maps.CIRCLES) do
		if not seen[id] then
			seen[id] = true
			MAPS[#MAPS + 1] = { id = id, girone = 2, serve = 0 }
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

-- a map's card: its miniature cut to the corner, the name under it; closed,
-- dark under a padlock and how many stars open it
local function map_card(a, x, y, m)
	local g = a.kg
	if m.random then
		local on = a.scelta.mappa == "caso"
		local k = kit.card(g, x, y, 186, 130, on and KC.HOT or KC.ROSE, { sel = on })
		kit.text(k.g, "?", x + 93, y + 82, 64, KC.SAND, "middle")
		kit.text(k.g, T.random, x + 93, y + 116, 15, KC.SAND, "middle", 0.5)
		kit.zone(g, a.buttons, x, y, 186, 130, "mappa:caso")
		return
	end
	local open = is_open(m, a.stelle)
	local on = a.scelta.mappa == m.id
	local k = kit.card(g, x, y, 186, 130, on and KC.HOT or KC.ROSE, { sel = on, off = not open })
	local img = kit.card_picture(k, "mappe", 92, 16 / 9, open and 1 or 0.4)
	gui.play_flipbook(img, m.id)
	if open then
		kit.text(k.g, kit.upper(maps.get(m.id).name), x + 93, y + 116, 15, KC.SAND, "middle", 0.5)
		kit.zone(g, a.buttons, x, y, 186, 130, "mappa:" .. m.id)
	else
		ui.padlock(0, 65 - 4 - 46, 40, KC.MUTE, k.node)
		kit.text(k.g, kit.upper(common.opens_with:format(m.serve)), x + 93, y + 116, 11, KC.MUTE, "middle", 0.5)
	end
end

-- an arrow of the maps' row: two strokes and its zone
local function arrow(a, x, y, dir)
	local g = a.kg
	kit.line(g, x - 7 * dir, y - 14, x + 7 * dir, y, 5, KC.SAND)
	kit.line(g, x + 7 * dir, y, x - 7 * dir, y + 14, 5, KC.SAND)
	kit.zone(g, a.buttons, x - 24, y - 40, 48, 80, "scorri:" .. dir)
end

local function build(a)
	if a.radice then gui.delete_node(a.radice) end
	if a.head then kit.header_delete(a.head) end
	if a.right then gui.delete_node(a.right.node) end
	if a.low then gui.delete_node(a.low.node) end
	a.buttons = {}
	local sc = a.scelta
	-- the frame (ui/kit.lua): the title, the way back, the devil and what this place is
	a.head = kit.header(a.buttons, common.training, KC.MINT, "indietro", common.home)
	a.right = kit.anchor(1280, 720, gui.ANCHOR_RIGHT, gui.ANCHOR_BOTTOM)
	a.low = kit.anchor(0, 720, gui.ANCHOR_LEFT, gui.ANCHOR_BOTTOM)
	a.radice = ui.root()
	a.kg = { node = a.radice, ox = 0, oy = 720 }
	local g = a.kg
	profile_tabs.devil(a, T.offline)
	-- three choices, one under the other: who is there, the mode, the bots
	local same = sc.chi == "stesso"
	kit.choice(g, a.buttons, 440, 140, T.who, { { T.vs_bots, "chi:bot" }, { T.same_phone, "chi:stesso" } }, same and 2 or 1, 220)
	local modes, levels, mode_on, level_on = {}, {}, 1, 1
	for i, m in ipairs(MODES_LIST) do
		modes[i] = { m[2], "modo:" .. m[1] }
		if sc.modo == m[1] then mode_on = i end
	end
	for i, l in ipairs(LEVELS) do
		levels[i] = { l[2], "livello:" .. l[1] }
		if sc.livello == l[1] then level_on = i end
	end
	kit.choice(g, a.buttons, 440, 228, T.mode, modes, mode_on, 214)
	-- on the same phone there are no bots
	kit.choice(g, a.buttons, 440, 316, common.bot, levels, level_on, 160, same)
	-- the map: A CASO first, then the maps from the first visible one
	kit.text(g, T.map, 446, 394, 14, KC.MUTE, "start", 1.5)
	local cards = { { random = true } }
	for _, m in ipairs(MAPS) do cards[#cards + 1] = m end
	local first = math.max(1, math.min(a.da, #cards - VISIBLE + 1))
	a.da = first
	local last = math.min(#cards, first + VISIBLE - 1)
	for i = first, last do map_card(a, 440 + (i - first) * (206 + kit.air(0.25)), 406, cards[i]) end
	if first > 1 then arrow(a, 424, 471, -1) end
	if last < #cards then arrow(a, 1262 + 3 * kit.air(0.25), 471, 1) end
	-- the one action
	a.action = kit.action(a.right, common.play, 930, 560, 270, 84, { size = 54,
		sub = same and T.mode_same:format(NAMES[sc.modo]) or T.mode_and_bot:format(NAMES[sc.modo], NAMES[sc.livello]) })
	kit.button(a.buttons, a.action, "gioca", { main = true })
end

function M.new(choice, stars)
	local a = { scelta = choice, stelle = stars or 0, da = 1, colore = ui.C.SQUADRA[1], accent = KC.MINT }
	choice.chi = choice.chi or "bot"
	-- a map that has been closed (or removed) goes back to A CASO
	local ok = choice.mappa == "caso"
	for _, id in ipairs(M.open_maps(a.stelle)) do ok = ok or id == choice.mappa end
	if not ok then choice.mappa = "caso" end
	-- the chosen map in view
	for i, m in ipairs(MAPS) do
		if m.id == choice.mappa then a.da = math.max(1, i + 2 - VISIBLE) end
	end
	-- the game world darkened behind, the rays from the devil
	a.scene = kit.scene(profile_tabs.devil_x(), profile_tabs.DEVIL_Y, { accent = KC.MINT })
	build(a)
	return a
end

function M.update(a, dt)
	if a.figure then scoria.update(a.figure, dt, a.st) end
end

function M.on_input(a, action_id, action)
	local ui_action = ui.touch(a.buttons, action_id, action)
	if not ui_action then return nil end
	if ui_action == "indietro" then
		return "indietro"
	elseif ui_action == "gioca" then
		return { modo = a.scelta.modo, livello = a.scelta.livello, mappa = a.scelta.mappa, stesso = a.scelta.chi == "stesso" or nil }
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
	kit.header_delete(a.head)
	gui.delete_node(a.right.node)
	gui.delete_node(a.low.node)
	gui.delete_node(a.radice)
	kit.scene_drop(a.scene)
end

return M
