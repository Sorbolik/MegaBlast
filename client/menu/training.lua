-- Training (the home's ALLENAMENTO door, Figma 16): a match without the net, on
-- one page against the bots of sim/bot.lua: the mode as the page's tabs (the
-- player is always the first robot; in 2 vs 2 the teammate is a bot), the
-- difficulty and the map. The lessons
-- live in the campaign (menu/campaign.lua, Chapter 0). Style in ui/ui.lua.
--
-- The map (Sergio, 3 Nov 2026: only here, the other modes keep a random map):
-- a row of cards that scrolls with the finger, A CASO first, then the official maps of the
-- campaign circles in order. The maps of a circle not reached yet are dark
-- with the padlock; those of the first circle are always open. The
-- postcards are the "mappe" texture (tools/grafica/miniature_mappe.py).
--
--   local allenamento = require "menu.training"
--   local a = allenamento.new(scelta, stelle)  -- scelta = { modo, livello, mappa } (the last one); stelle = all stars taken
--   local fine = allenamento.on_input(a, action_id, action)
--     -- "indietro", { modo = ..., livello = ..., mappa = id or "caso" } to play, or nil
--   allenamento.destroy(a)
--   allenamento.open_maps(stelle)  -- the ids of the maps that can be played (A CASO picks among these)

local ui = require "ui.ui"
local kit = require "ui.kit"
local scoria = require "battle.scoria"
local screen = require "ui.screen"
local devil_side = require "menu.devil_side"
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
-- the map cards: CW x CH with a PIC high postcard, MAP_STEP from one to the next
local CW, CH, PIC = 340, 240, 186
local MAP_STEP = 356
-- the cards start under the MAPPA label
local MAP_X = 446
-- the maps' window: it scrolls with the finger (Sergio, 24 Nov: no arrows), from
-- x to the screen's right border (w is set in build, ui/screen.lua)
local VIEW = { x = 430, y = 262, w = 850, h = CH + 20 }

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

-- a map card's zone counts only inside the window, and knows where it is in the row
local function in_strip(zone, a, x)
	zone.inside = a.clip
	zone.strip_x = x
end

-- the row at this scroll (clamped)
local function scroll_to(a, scroll)
	a.scroll = math.max(0, math.min(a.scroll_max, scroll))
	gui.set_position(a.strip.node, vmath.vector3(-a.scroll, 0, 0))
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
		local k = kit.card(g, x, y, CW, CH, on and KC.HOT or KC.ROSE, { sel = on })
		kit.text(k.g, "?", x + CW / 2, y + 108, 84, KC.SAND, "middle")
		kit.text(k.g, T.random, x + CW / 2, y + CH - 16, 16, KC.SAND, "middle", 0.5)
		in_strip(kit.zone(g, a.buttons, x, y, CW, CH, "mappa:caso"), a, x)
		return
	end
	local open = is_open(m, a.stelle)
	local on = a.scelta.mappa == m.id
	local k = kit.card(g, x, y, CW, CH, on and KC.HOT or KC.ROSE, { sel = on, off = not open })
	local img = kit.card_picture(k, "mappe", PIC, 16 / 9, open and 1 or 0.4)
	gui.play_flipbook(img, m.id)
	if open then
		kit.text(k.g, kit.upper(maps.get(m.id).name), x + CW / 2, y + CH - 16, 16, KC.SAND, "middle", 0.5)
		in_strip(kit.zone(g, a.buttons, x, y, CW, CH, "mappa:" .. m.id), a, x)
	else
		kit.piece({ node = k.node, ox = 0, oy = 0 }, "lucchetto", 0, -(CH / 2 - 4 - PIC / 2), 52)
		kit.text(k.g, kit.upper(common.opens_with:format(m.serve)), x + CW / 2, y + CH - 16, 16, KC.MUTE, "middle", 0.5)
	end
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
	devil_side.devil(a, T.offline)
	local modes, levels, mode_on, level_on = {}, {}, 1, 1
	for i, m in ipairs(MODES_LIST) do
		modes[i] = { m[2], "modo:" .. m[1] }
		if sc.modo == m[1] then mode_on = i end
	end
	for i, l in ipairs(LEVELS) do
		levels[i] = { l[2], "livello:" .. l[1] }
		if sc.livello == l[1] then level_on = i end
	end
	-- the modes are the page's tabs, beside the title (Sergio, 24 Nov)
	kit.tabs(a.head.top_left, a.buttons, 420, 28, modes, mode_on, KC.MINT, true)
	kit.choice(g, a.buttons, MAP_X - 6, 150, T.difficulty, levels, level_on, 180)
	-- the maps: A CASO first, in a window that scrolls
	kit.text(g, T.map, MAP_X, 252, 16, KC.MUTE, "start", 1.5)
	local cards = { { random = true } }
	for _, m in ipairs(MAPS) do cards[#cards + 1] = m end
	VIEW.w = screen.x1 - VIEW.x
	local clip = gui.new_box_node(vmath.vector3(VIEW.x + VIEW.w / 2 - g.ox, g.oy - (VIEW.y + VIEW.h / 2), 0), vmath.vector3(VIEW.w, VIEW.h, 0))
	gui.set_parent(clip, g.node)
	gui.set_clipping_mode(clip, gui.CLIPPING_MODE_STENCIL)
	gui.set_clipping_visible(clip, false)
	gui.set_adjust_mode(clip, gui.ADJUST_FIT)
	a.clip = clip
	local view = { node = clip, ox = VIEW.x + VIEW.w / 2, oy = VIEW.y + VIEW.h / 2 }
	a.strip = kit.group(view, view.ox, view.oy)
	a.scroll_max = math.max(0, MAP_X - VIEW.x + (#cards - 1) * MAP_STEP + CW + 20 - VIEW.w)
	scroll_to(a, a.scroll or 0)
	local mg = a.kg
	a.kg = a.strip
	for i = 1, #cards do map_card(a, MAP_X + (i - 1) * MAP_STEP, VIEW.y + 10, cards[i]) end
	a.kg = mg
	-- the one action
	a.action = kit.action(a.right, common.play, 930, 560, 270, 84, { icon = "az_gioca", size = 54,
		sub = T.mode_and_bot:format(NAMES[sc.modo], NAMES[sc.livello]) })
	kit.button(a.buttons, a.action, "gioca", { main = true })
end

function M.new(choice, stars)
	local a = { scelta = choice, stelle = stars or 0, colore = ui.C.SQUADRA[1], accent = KC.MINT }
	-- a map that has been closed (or removed) goes back to A CASO
	local ok = choice.mappa == "caso"
	for _, id in ipairs(M.open_maps(a.stelle)) do ok = ok or id == choice.mappa end
	if not ok then choice.mappa = "caso" end
	-- the chosen map in view (A CASO is the first card)
	for i, m in ipairs(MAPS) do
		if m.id == choice.mappa then a.scroll = MAP_X - VIEW.x + i * MAP_STEP + CW + 20 - VIEW.w end
	end
	-- the backdrop (ui/kit.lua)
	a.scene = kit.scene(devil_side.x(), devil_side.Y, { accent = KC.MINT, bg = "campo" })
	build(a)
	return a
end

function M.update(a, dt)
	if a.figure then scoria.update(a.figure, dt, a.st) end
	-- the controller's light on a map card out of the window brings it in view
	local b = a.buttons.luce
	if b and b.strip_x and b ~= a.seen then
		a.seen = b
		local left = b.strip_x - a.scroll - VIEW.x
		if left < 16 then scroll_to(a, a.scroll + left - 16)
		elseif left + CW > VIEW.w - 16 then scroll_to(a, a.scroll + left + CW - VIEW.w + 16) end
	end
end

-- a drag in the maps' window moves the row (and is not a tap on a map)
local WHEEL_UP, WHEEL_DOWN, WHEEL_STEP = hash("zoom_avanti"), hash("zoom_indietro"), 120

local function drag(a, action_id, action)
	-- on a desktop the mouse wheel scrolls the row too
	if (action_id == WHEEL_UP or action_id == WHEEL_DOWN) and (a.scroll_max or 0) > 0 then
		if action.pressed then scroll_to(a, a.scroll + (action_id == WHEEL_UP and -WHEEL_STEP or WHEEL_STEP)) end
		return true
	end
	if action_id ~= ui.TOUCH or not a.clip or (a.scroll_max or 0) <= 0 then return false end
	if action.pressed then
		a.drag = gui.pick_node(a.clip, action.x, action.y) and { x = action.x, from = a.scroll, moved = false } or nil
		return false
	end
	local d = a.drag
	if not d then return false end
	if action.released then
		a.drag = nil
		return d.moved
	end
	local dx = action.x - d.x
	if not d.moved and math.abs(dx) > 10 then
		d.moved = true
		local b = a.buttons.held_down
		if b then gui.set_scale(b.nodo, vmath.vector3(1, 1, 1)) end
		a.buttons.held_down = nil
	end
	if d.moved then
		scroll_to(a, d.from - dx)
	end
	return d.moved
end

function M.on_input(a, action_id, action)
	if drag(a, action_id, action) then return nil end
	local ui_action = ui.touch(a.buttons, action_id, action)
	if not ui_action then return nil end
	if ui_action == "indietro" then
		return "indietro"
	elseif ui_action == "gioca" then
		return { modo = a.scelta.modo, livello = a.scelta.livello, mappa = a.scelta.mappa }
	else
		local kind, value = ui_action:match("^(%a+):(.*)$")
		a.scelta[kind] = value
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
