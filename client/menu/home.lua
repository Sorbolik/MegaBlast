-- The home (main menu), in the "Fucina contro Abisso" style (ui/kit.lua; Home C,
-- Sergio 12 Nov): the apprentice big on the left, in the warm, standing on the
-- thread (tapping it, or its name plate under its feet, opens IL TUO
-- DIAVOLETTO); on the right, under the thumb, the doors in a column, each a
-- plate with its own shape (CAMPAGNA, ALLENAMENTO, EVENTI), and under them the
-- action: GIOCA (online), the red-hot ingot. STESSO TELEFONO is in ALLENAMENTO.
--
-- Use (from the gui_script, which has the ui texture and the titolo font):
--   local home = require "menu.home"
--   local h = home.new(colore)                  -- creates the nodes, hidden
--   home.show(h, without_veil) / home.hide(h)
--   home.arrive(h)                              -- the grand entrance (the logo's screen has gone)
--   home.update(h, dt)                          -- every frame while visible
--   local scelta = home.on_input(h, action_id, action)   -- "online", "campagna", "allenamento", "eventi", ("local": scenarios only)
--                                                        -- "impostazioni", "profilo" (the devil or its plate) or nil
--   home.wallet(h, scaglie, ossidiana)          -- the balance in the pill at the top right
--   home.events(h, riga)                        -- the line under EVENTI
--   home.profile(h, profilo)                    -- level, experience and campaign progress on the plates
--   home.queued(h, on)                          -- in the online queue (ui/pill.lua): GIOCA stays GIOCA and
--                                               -- takes you to the room (Sergio: a button never changes its job)
--                                               -- and the CAMPAGNA is off (a mission cut halfway loses its stars)

local game = require "sim.game"
local scoria = require "battle.scoria"
local ui = require "ui.ui"
local kit = require "ui.kit"
local screen = require "ui.screen"
local coins = require "ui.coins"
local campaign = require "sim.campaign"
local T = require("lang.text").home
local common = require("lang.text").common

local M = {}

local W, H = 1280, 720
local C = kit.C
-- the apprentice: feet on the thread, at the Figma point (330, 661)
local BODY_X, BODY_Y = 330, 661
local BODY_K = 400 / game.DISEGNO_H
local DOOR_W, DOOR_H = 384, 82

local V = vmath.vector3()

-- A door: a plate with its own shape (piece), its name, a line under it and,
-- on the right, the notches of its progress. hot: warm (something is on now)
local function door(h, g, x, y, name, ui_action, piece, hot)
	local p = kit.plate(g, x, y, DOOR_W, DOOR_H, hot and C.HOT or C.ROSE, { sk = 0, piece = not hot and piece or nil })
	local d = { p = p, x = x, y = y, hot = hot, pips = {} }
	-- the name and its line where this plate has room (ui/kit.lua): each door
	-- its own place, not lined up with the others
	local b = p.box
	local tall = b.y1 - b.y0
	d.name = kit.text(p.g, name, b.x0 + 2, b.y0 + tall * 0.6, tall * 0.62, C.SAND)
	d.sub = kit.text(p.g, "", b.x0 + 3, b.y1 - 1, tall * 0.27, hot and C.HOT_TOP or C.MUTE, "start", 1.5)
	d.b = kit.button(h.buttons, p, ui_action)
	h.doors[#h.doors + 1] = d
	return d
end

-- the small line of a door: never past its room (a long one shrinks)
local function set_sub(d, txt)
	gui.set_text(d.sub, txt)
	d.sub_scale = d.sub_scale or gui.get_scale(d.sub)
	gui.set_scale(d.sub, d.sub_scale)
	local room = d.p.box.x1 - d.p.box.x0 - 6 - #d.pips * 15
	local w = kit.width(d.sub)
	if w > room then gui.set_scale(d.sub, d.sub_scale * (room / w)) end
end

-- n notches on a door, the first lit ones in color (0: none)
local function set_pips(d, n, lit)
	for _, q in ipairs(d.pips) do gui.delete_node(q.node) end
	d.pips = n > 0 and kit.pips(d.p.g, d.p.box.x1 - 8 - n * 15, d.p.box.y1 - 12, n, lit, d.hot and C.HOT_EDGE or C.SAND) or {}
end

function M.new(color)
	local h = { tops = {}, buttons = {}, doors = {}, t = 0, colore = color }

	h.scene = kit.scene(BODY_X, 350, { bg = "home" })

	-- the apprentice, on the left, its feet on the thread
	local mid = kit.anchor(BODY_X, BODY_Y, nil, gui.ANCHOR_BOTTOM)
	h.tops[#h.tops + 1] = mid.node
	h.posa = mid.node
	local body_shape = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(0, 0, 0))
	gui.set_visible(body_shape, false)
	gui.set_parent(body_shape, mid.node)
	V.x, V.y, V.z = BODY_K, BODY_K, 1
	gui.set_scale(body_shape, V)
	h.corpo = scoria.new(color, scoria.PERSONAGGIO)
	gui.set_parent(h.corpo.root, body_shape)
	scoria.set_enabled(h.corpo, true)
	-- idle without a weapon, without skits (Sergio, 2 Nov)
	h.st = { x = 0, y = 0, facing = 1, grounded = true, moving = 0, fermo = true }
	-- tapping the devil opens its place: an invisible zone over it
	local zone = gui.new_box_node(vmath.vector3(0, 250, 0), vmath.vector3(330, 500, 0))
	gui.set_visible(zone, false)
	gui.set_parent(zone, mid.node)
	h.buttons[#h.buttons + 1] = { nodo = zone, bordo = zone, ui_action = "profilo", colore = ui.C.LIGHT, riposo = ui.C.LIGHT }

	-- the name plate under its feet, below the thread: level and experience
	h.plate = kit.sand(mid, 180, 668, 300, 46, C.HOT, { sk = 0 })
	kit.text(h.plate.g, T.your_devil, 204, 698, 18, C.INK)
	h.level = kit.text(h.plate.g, "", 462, 690, 14, kit.with_alpha(C.INK, 0.75), "end", 1)
	h.xp_g = h.plate.g
	kit.button(h.buttons, h.plate, "profilo")

	-- top left: the game's name, written as the logo
	local top_left = kit.anchor(0, 0, gui.ANCHOR_LEFT, gui.ANCHOR_TOP)
	h.tops[#h.tops + 1] = top_left.node
	h.logo_g = top_left
	h.logo = kit.title(top_left, common.game_name, C.HOT, 30, 62, 36)

	-- right: the doors in a column, each with its shape, and the action under them
	local right = kit.anchor(1280, 360, gui.ANCHOR_RIGHT)
	h.tops[#h.tops + 1] = right.node
	h.campaign = door(h, right, 846, 100, common.campaign, "campagna", "piastra_freccia")
	h.training = door(h, right, 856, 190, common.training, "allenamento", "piastra_storta")
	set_sub(h.training, T.training_sub)
	h.events_door = door(h, right, 846, 280, common.events, "eventi", "piastra_stendardo", true)
	-- (in a group of its own: the ingot and its line arrive together)
	h.play_g = kit.group(right, 1030, 460)
	h.play = kit.action(h.play_g, common.play, 816, 380, 380, 160, { size = 96, sub = T.play_sub })
	h.play_b = kit.button(h.buttons, h.play, "online", { main = true })

	-- STESSO TELEFONO is in ALLENAMENTO now; the scenarios of the simulator
	-- (tools/simula) still start their match from here, with a tap on the
	-- old place: an invisible zone, only there
	if sys.get_config_int("megablast.simula", 0) == 1 then
		local sim = kit.anchor(0, 360, gui.ANCHOR_LEFT)
		h.tops[#h.tops + 1] = sim.node
		kit.zone(sim, h.buttons, 190, 560, 64, 24, "local")
	end

	-- top right: the wallet's strip (ui/coins.lua, hidden until the
	-- first coin) and the settings wheel
	local top_right = kit.anchor(1280, 0, gui.ANCHOR_RIGHT, gui.ANCHOR_TOP)
	h.tops[#h.tops + 1] = top_right.node
	h.top_right = top_right
	local wr = kit.group(top_right, 1110, 44)
	h.wallet = coins.wallet(0, 0, wr.node, 0, 0)
	local wheel = kit.group(top_right, 1230, 44)
	-- the wheel on a lump of cold iron
	kit.piece({ node = wheel.node, ox = 0, oy = 0 }, "brace_spenta", 0, 0, 56)
	ui.sagoma("ingranaggio", 0, 1, 30, 30, C.SAND, wheel.node)
	local wz = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(72, 72, 0))
	gui.set_visible(wz, false)
	gui.set_parent(wz, wheel.node)
	h.buttons[#h.buttons + 1] = { nodo = wz, bordo = wz, ui_action = "impostazioni", colore = ui.C.LIGHT, riposo = ui.C.LIGHT }

	-- black veil dissolving when the home appears
	h.veil = gui.new_box_node(vmath.vector3(W / 2, H / 2, 0), vmath.vector3(W * screen.FULL, H * screen.FULL, 0))
	gui.set_adjust_mode(h.veil, gui.ADJUST_FIT)
	gui.set_color(h.veil, vmath.vector4(0, 0, 0, 1))

	-- where every piece rests, for the entrance
	h.rest = {}
	for _, d in ipairs(h.doors) do h.rest[d.p.node] = gui.get_position(d.p.node) end
	for _, p in ipairs({ h.play_g, top_left, top_right, mid }) do h.rest[p.node] = gui.get_position(p.node) end
	-- what shakes at a thud: the sides (not the pieces that are arriving)
	h.shaken = { right.node, top_left.node }

	M.hide(h)
	return h
end

-- The entrance. Every time: the doors fly in from the right one after the
-- other and their notches pop one by one, the logo and the wallet come down, GIOCA arrives from the right. grand (when the game opens):
-- the thread draws itself, the apprentice drops from above and lands squashed
-- with a thud, and GIOCA slams in with a thud
local function enter(h, wait, grand)
	local function from(node, dx, dy, delay, time, done)
		local p = h.rest[node]
		gui.cancel_animations(node, "position")
		gui.set_position(node, vmath.vector3(p.x + dx, p.y + dy, 0))
		gui.animate(node, "position", p, gui.EASING_OUTBACK, time or (grand and 0.4 or 0.28), wait + delay, done)
	end
	-- coming back from a menu everything is there at once: a tap must find it
	local late = 0
	for i, d in ipairs(h.doors) do
		local at = late + (grand and 0.06 or 0.04) * (i - 1)
		from(d.p.node, 620, 0, at)
		for j, q in ipairs(d.pips) do kit.pop(q.node, wait + at + 0.3 + 0.07 * j, 0.2, 0.01) end
	end
	from(h.logo_g.node, 0, 100, grand and 0.1 or 0)
	from(h.top_right.node, 0, 100, grand and 0.1 or 0)
	gui.cancel_animations(h.posa, "position")
	gui.cancel_animations(h.posa, "scale")
	if not grand then
		gui.set_position(h.posa, h.rest[h.posa])
		from(h.play_g.node, 620, 0, 0)
		kit.pop(h.posa, wait + 0.02, 0.36, 0.9)
		return
	end
	kit.scene_enter(wait)
	-- the apprentice: stretched while it falls, squashed when it lands
	local p = h.rest[h.posa]
	gui.set_position(h.posa, vmath.vector3(p.x, p.y + 760, 0))
	gui.set_scale(h.posa, vmath.vector3(0.9, 1.15, 1))
	gui.animate(h.posa, "position", p, gui.EASING_INQUAD, 0.3, wait + 0.2, function()
		gui.set_scale(h.posa, vmath.vector3(1.1, 0.86, 1))
		gui.animate(h.posa, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, 0.32)
		kit.shake(h.shaken, 7)
	end)
	-- (no sparks here: Sergio, 11 Nov, «sembrano fuochi d'artificio, toglile»)
	from(h.play_g.node, 620, 0, 0.5, 0.36, function() kit.shake(h.shaken, 6) end)
end

-- The grand entrance, when the logo's screen (ui/entry.lua) uncovers the
-- home: under it nothing would be seen
function M.arrive(h)
	if h.is_visible then enter(h, 0, true) end
end

-- without_veil: you get here with a transition (ui/transition.lua), which already covers
function M.show(h, without_veil)
	for _, n in ipairs(h.tops) do gui.set_enabled(n, true) end
	kit.scene_show(h.scene, true)
	-- the home is kept: the backdrop goes back under it
	kit.scene_place(h.scene, "below", h.tops[1])
	h.buttons.held_down = nil
	h.is_visible = true
	-- under the black veil nothing would be seen: the pieces wait for it
	enter(h, without_veil and kit.wait or 0.2, false)
	if without_veil then
		gui.cancel_animations(h.veil, "color.w")
		gui.set_enabled(h.veil, false)
		return
	end
	gui.set_enabled(h.veil, true)
	gui.set_color(h.veil, vmath.vector4(0, 0, 0, 1))
	gui.animate(h.veil, "color.w", 0, gui.EASING_OUTQUAD, 0.35, 0, function()
		gui.set_enabled(h.veil, false)
	end)
end

function M.hide(h)
	for _, n in ipairs(h.tops) do gui.set_enabled(n, false) end
	kit.scene_show(h.scene, false)
	gui.cancel_animations(h.veil, "color.w")
	gui.set_enabled(h.veil, false)
	h.is_visible = false
end

-- The balance in the wallet pill (menu/wallet.lua)
function M.wallet(h, scaglie, ossidiana)
	coins.set(h.wallet, scaglie, ossidiana)
end

-- The line under EVENTI (main/events.lua, home_line)
function M.events(h, txt)
	set_sub(h.events_door, string.upper(txt or ""))
end

-- Level and experience on the name plate, the chapter you are in on CAMPAGNA
function M.profile(h, p)
	local profile = require "menu.profile"
	gui.set_text(h.level, T.level:format(p.livello or 1))
	if h.xp then gui.delete_node(h.xp.back.node); if h.xp.front then gui.delete_node(h.xp.front.node) end end
	local f = math.min(1, (p.xp or 0) / profile.xp_level(p.livello or 1))
	h.xp = kit.bar(h.xp_g, 330, 698, 130, 5, f, C.HOT_BOTTOM, C.SAND_SHADOW)
	-- the first chapter with a mission still to win, and how far you are in it
	local stars = p.stelle or {}
	local chapter, done
	for _, cap in ipairs(campaign.CAPITOLI) do
		chapter, done = cap, 0
		for _, l in ipairs(cap.missioni) do
			if (stars[l.id] or {})[1] then done = done + 1 end
		end
		if done < #cap.missioni then break end
	end
	h.chapter = string.upper(chapter.titolo)
	if not h.in_queue then set_sub(h.campaign, h.chapter) end
	set_pips(h.campaign, #chapter.missioni, done)
	for _, q in ipairs(h.campaign.pips) do gui.set_enabled(q.node, not h.in_queue) end
end

function M.queued(h, on)
	h.in_queue = on
	h.campaign.b.spento = on or nil
	gui.set_color(h.campaign.name, on and C.MUTE or C.SAND)
	set_sub(h.campaign, on and string.upper(T.leave_queue_first) or (h.chapter or ""))
	-- the long line takes the notches' place
	for _, q in ipairs(h.campaign.pips) do gui.set_enabled(q.node, not on) end
end

function M.update(h, dt)
	if not h.is_visible then return end
	h.t = h.t + dt
	scoria.update(h.corpo, dt, h.st)
	kit.scene_fit()
	-- a pressed plate goes down onto its shadow
	local held = h.buttons.held_down
	if held ~= h.held then
		if h.held and h.held.piastra then kit.press(h.held.piastra, false) end
		if held and held.piastra then kit.press(held.piastra, true) end
		h.held = held
	end
end

function M.on_input(h, action_id, action)
	if not h.is_visible then return nil end
	local choice = ui.touch(h.buttons, action_id, action)
	if choice then
		-- the apprentice leans toward what you touched
		gui.cancel_animations(h.posa, "rotation.z")
		gui.set_rotation(h.posa, vmath.vector3(0, 0, 0))
		gui.animate(h.posa, "rotation.z", (action.x or 640) < 640 and 5 or -5, gui.EASING_OUTSINE, 0.26, 0, nil, gui.PLAYBACK_ONCE_PINGPONG)
	end
	return choice
end

return M
