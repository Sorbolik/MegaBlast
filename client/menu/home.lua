-- The home (main menu), in the "Raggi" style (ui/kit.lua; Figma frame 01,
-- Sergio 10 Nov): behind it the painted Forge scrolling slowly, darkened
-- (battle/terrain.script), the rays around the apprentice standing in the
-- middle (tapping it, or its name plate below, opens IL TUO DIAVOLETTO), on
-- the left the doors that carry their progress (CAMPAGNA, ALLENAMENTO,
-- EVENTI) and STESSO TELEFONO, alone on the right the action: GIOCA (online).
--
-- Use (from the gui_script, which has the ui texture and the titolo font):
--   local home = require "menu.home"
--   local h = home.new(colore)                  -- creates the nodes, hidden
--   home.show(h, without_veil) / home.hide(h)
--   home.update(h, dt)                          -- every frame while visible
--   local scelta = home.on_input(h, action_id, action)   -- "online", "campagna", "allenamento", "local", "eventi",
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
-- the apprentice: feet at the Figma point (640, 600), about 540 px tall with the flame
local BODY_X, BODY_Y = 640, 600
local BODY_K = 380 / game.DISEGNO_H

local V = vmath.vector3()

-- A door: a dark plate with its name, a line under it and, on the right, the
-- notches of its progress, on the left the miniature of a map. hot: lit in the action's color (something is on now)
local function door(h, g, x, y, name, ui_action, map, hot)
	local p = kit.plate(g, x, y, 380, 88, hot and C.HOT or C.ROSE, { sk = 28, d = 10 })
	local d = { p = p, x = x, y = y, hot = hot, pips = {} }
	d.img = kit.thumb(p, "mappe", map, 68, hot and C.HOT_EDGE or C.ROSE)
	d.name = kit.text(p.g, name, x + 120, y + 40, 27, C.SAND)
	d.sub = kit.text(p.g, "", x + 120, y + 66, 14, hot and C.HOT_TOP or C.MUTE, "start", 1.5)
	d.b = kit.button(h.buttons, p, ui_action)
	h.doors[#h.doors + 1] = d
	return d
end

-- n notches on a door, the first lit ones in color (0: none)
local function set_pips(d, n, lit)
	for _, q in ipairs(d.pips) do gui.delete_node(q.node) end
	d.pips = n > 0 and kit.pips(d.p.g, d.x + 380 - 14 - n * 15, d.y + 52, n, lit, d.hot and C.HOT_EDGE or C.SAND) or {}
end

function M.new(color)
	local h = { tops = {}, buttons = {}, doors = {}, t = 0, colore = color }

	h.scene = kit.scene(BODY_X, 350)

	-- the apprentice, in the middle
	local mid = kit.anchor(BODY_X, BODY_Y)
	h.tops[#h.tops + 1] = mid.node
	h.posa = mid.node
	local ground = ui.alone(0, 0, 330, ui.C.SHADOW, mid.node)
	gui.set_blend_mode(ground, gui.BLEND_ALPHA)
	V.x, V.y, V.z = 1, 0.14, 1
	gui.set_scale(ground, V)
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
	local zone = gui.new_box_node(vmath.vector3(0, 230, 0), vmath.vector3(300, 460, 0))
	gui.set_visible(zone, false)
	gui.set_parent(zone, mid.node)
	h.buttons[#h.buttons + 1] = { nodo = zone, bordo = zone, ui_action = "profilo", colore = ui.C.LIGHT, riposo = ui.C.LIGHT }

	-- the name plate under the feet: level and experience
	local low = kit.anchor(640, 720, nil, gui.ANCHOR_BOTTOM)
	h.tops[#h.tops + 1] = low.node
	h.plate = kit.sand(low, 470, 630, 340, 62, C.HOT, { sk = 22 })
	kit.text(h.plate.g, T.your_devil, 506, 669, 22, C.INK)
	h.level = kit.text(h.plate.g, "", 800, 656, 18, kit.with_alpha(C.INK, 0.75), "end", 1)
	h.xp_g = h.plate.g
	kit.button(h.buttons, h.plate, "profilo")

	-- top left: the game's name, written as the logo
	local top_left = kit.anchor(0, 0, gui.ANCHOR_LEFT, gui.ANCHOR_TOP)
	h.tops[#h.tops + 1] = top_left.node
	h.logo_g = top_left
	h.logo = kit.title(top_left, common.game_name, C.HOT, 30, 62, 36)

	-- left: the doors, staggered, and STESSO TELEFONO under them
	local left = kit.anchor(0, 360, gui.ANCHOR_LEFT)
	h.tops[#h.tops + 1] = left.node
	h.campaign = door(h, left, 30, 226, common.campaign, "campagna", "cortile")
	h.training = door(h, left, 50, 330, common.training, "allenamento", "fossa")
	gui.set_text(h.training.sub, T.training_sub)
	h.events_door = door(h, left, 70, 434, common.events, "eventi", "pavimento", true)
	h.phone = kit.plate(left, 90, 548, 250, 48, C.ROSE, { sk = 14, d = 5 })
	kit.text(h.phone.g, T.same_phone, 222, 580, 18, kit.with_alpha(C.SAND, 0.9), "middle", 0.5)
	kit.button(h.buttons, h.phone, "local")

	-- right: the action, alone
	local right = kit.anchor(1280, 360, gui.ANCHOR_RIGHT)
	h.tops[#h.tops + 1] = right.node
	-- (in a group of its own: the plate, its glow and its tag arrive together)
	h.play_g = kit.group(right, 1036, 320)
	h.play = kit.action(h.play_g, common.play, 836, 250, 354, 140, { size = 104, sub = T.play_sub })
	h.play_b = kit.button(h.buttons, h.play, "online", { main = true })

	-- top right: the wallet's strip (ui/coins.lua, hidden until the
	-- first coin) and the settings wheel
	local top_right = kit.anchor(1280, 0, gui.ANCHOR_RIGHT, gui.ANCHOR_TOP)
	h.tops[#h.tops + 1] = top_right.node
	h.top_right = top_right
	local wr = kit.group(top_right, 1110, 44)
	h.wallet = coins.wallet(0, 0, wr.node, 0, 0)
	local wheel = kit.group(top_right, 1230, 44)
	gui.set_blend_mode(ui.disc(0, 0, 52, kit.with_alpha(C.INK, 0.8), wheel.node), gui.BLEND_ALPHA)
	ui.ring_node(0, 0, 52, 2.5, kit.with_alpha(C.SAND, 0.75), wheel.node)
	ui.sagoma("ingranaggio", 0, 0, 34, 34, C.SAND, wheel.node)
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
	for _, p in ipairs({ h.phone, h.play_g, h.plate, top_left, top_right, mid }) do h.rest[p.node] = gui.get_position(p.node) end
	-- what shakes at a thud: the sides (not the pieces that are arriving)
	h.shaken = { left.node, right.node, low.node }

	M.hide(h)
	return h
end

-- The entrance (the animated sheet, Sergio 11 Nov). Every time: the doors fly
-- in from the left one after the other and their notches pop one by one, the
-- name plate rises, the logo and the wallet come down, GIOCA arrives from the
-- right. grand (when the game opens): the rays grow, the apprentice drops from
-- above and lands squashed with a thud and sparks at its feet, and GIOCA slams
-- in with a flash
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
		from(d.p.node, -520, 0, at)
		for j, q in ipairs(d.pips) do kit.pop(q.node, wait + at + 0.3 + 0.07 * j, 0.2, 0.01) end
	end
	from(h.phone.node, -520, 0, 0.12, 0.28)
	from(h.plate.node, 0, -110, late + 0.1)
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
		kit.burst_at(h.posa, 14)
	end)
	from(h.play_g.node, 620, 0, 0.5, 0.36, function()
		kit.shake(h.shaken, 6)
		kit.flash(0.22)
		kit.burst_at(h.play.node, 16)
	end)
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
	enter(h, without_veil and kit.wait or 0.2, not without_veil)
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
	gui.set_text(h.events_door.sub, string.upper(txt or ""))
end

-- Level and experience on the name plate, the chapter you are in on CAMPAGNA
function M.profile(h, p)
	local profile = require "menu.profile"
	gui.set_text(h.level, T.level:format(p.livello or 1))
	if h.xp then gui.delete_node(h.xp.back.node); if h.xp.front then gui.delete_node(h.xp.front.node) end end
	local f = math.min(1, (p.xp or 0) / profile.xp_level(p.livello or 1))
	h.xp = kit.bar(h.xp_g, 646, 670, 150, 7, f, C.HOT_BOTTOM, C.SAND_SHADOW)
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
	if not h.in_queue then gui.set_text(h.campaign.sub, h.chapter) end
	set_pips(h.campaign, #chapter.missioni, done)
	for _, q in ipairs(h.campaign.pips) do gui.set_enabled(q.node, not h.in_queue) end
	gui.play_flipbook(h.campaign.img, chapter.id == "addestramento" and "cortile" or "pavimento")
end

function M.queued(h, on)
	h.in_queue = on
	h.campaign.b.spento = on or nil
	gui.set_color(h.campaign.name, on and C.MUTE or C.SAND)
	gui.set_text(h.campaign.sub, on and string.upper(T.leave_queue_first) or (h.chapter or ""))
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
