-- The home (main menu), as in the Figma "RIORGANIZZAZIONE MENU · 14 nov",
-- Consigliata/1 (Sergio, 14 Nov; docs/menu_nuovi_implementazione.md):
--   top left   the profile's round (face, name, level and its bar): it opens the PROFILO
--   top right  the wallet (ui/coins.lua)
--   middle     the apprentice on the forge-grate pedestal (WB-050 n.4), the small backpack
--              on its step (WB-048): the apprentice, the pedestal or the backpack open the
--              ZAINO. Three signs say it can be touched: now and then a light runs over the
--              pedestal and an ember glint over the apprentice; a tap makes it breathe
--   sides      the doors drawn by Codex (WB-046), the shield toward the screen's edge:
--              CAMPAGNA and ALLENAMENTO on the left, EVENTI and ARMERIA on the right
--   bottom     the settings' wheel on the left; GIOCA (online), the molten seal, on the right
-- STESSO TELEFONO is in ALLENAMENTO.
--
-- Use (from the gui_script, which has the textures and the titolo font):
--   local home = require "menu.home"
--   local h = home.new(colore)                  -- creates the nodes, hidden
--   home.show(h, without_veil) / home.hide(h)
--   home.arrive(h)                              -- the grand entrance (the logo's screen has gone)
--   home.update(h, dt)                          -- every frame while visible
--   local scelta = home.on_input(h, action_id, action)   -- "online", "campagna", "allenamento", "eventi",
--                                                        -- "armeria", "zaino" (the apprentice), "profilo" (the
--                                                        -- round), "impostazioni", ("local": scenarios only) or nil
--   home.wallet(h, scaglie, ossidiana, buoni)   -- the balance at the top right
--   home.events(h, riga)                        -- the line under EVENTI
--   home.profile(h, profilo)                    -- level, experience, the chapter on CAMPAGNA
--   home.queued(h, on)                          -- in the online queue (ui/pill.lua): GIOCA stays GIOCA and
--                                               -- takes you to the room (Sergio: a button never changes its job)
--                                               -- and the CAMPAGNA is off (a mission cut halfway loses its stars)

local game = require "sim.game"
local scoria = require "battle.scoria"
local score = require "battle.score"
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
local hex = kit.hex

-- The pedestal and the apprentice (the Figma's geometry, Sergio 14 Nov 23:55: the pedestal
-- does not cross the thread, everything keeps its room): PED_W wide, its foot on PED_BOTTOM,
-- the apprentice's feet at FEET, 380 tall like in the Figma
local PED_W = 300
local PED_H = PED_W * 266 / 601
local PED_BOTTOM = 598
local PED_TOP = PED_BOTTOM - PED_H
local PED_X = 640 - 0.37 * PED_W
local FEET = PED_TOP + 0.30 * PED_H
-- (the apprentice grew 18% on 14 Nov, #315: here it stays as tall as in the Figma)
local BODY_K = 338 / game.DISEGNO_H
local BAG = 46
-- the experience bar of the profile plate, full
local PLATE_BAR = 231

-- the doors: x, y, width, piece, side, color of the writing, size of the name
local DOORS = {
	campagna = { 22, 372, 396, "porta_campagna", -1, hex("2a1206"), 29 },
	allenamento = { 22, 494, 376, "porta_allenamento", -1, hex("1d1a20"), 24 },
	eventi = { 862, 372, 396, "porta_eventi", 1, hex("3a1a05"), 29 },
	armeria = { 882, 494, 376, "porta_armeria", 1, hex("f4ece1"), 29 },
}

local V = vmath.vector3()

-- A door's drawing with its name and a line under it, written in the room of
-- the drawing between the shield and the tip (left on the left, right on the
-- right), its top left at (x, y) of g
local function draw_door(g, id, x, y, name, sub)
	local o = DOORS[id]
	local p = kit.sign(g, o[4], x, y, o[3])
	local side, color = o[5], o[6]
	local b = p.box
	local cy = (b.y0 + b.y1) / 2
	local tx = side < 0 and b.x0 + 4 or b.x1 - 4
	local anchor = side < 0 and "start" or "end"
	local name_n = kit.text(p.g, name, tx, cy + o[7] * 0.28, o[7], color, anchor)
	local sub_n = kit.text(p.g, sub or "", tx, cy + o[7] * 0.28 + 20, 16, kit.with_alpha(color, 0.85), anchor, 1)
	return p, name_n, sub_n, tx, anchor
end

local function door(h, g, id, name)
	local o = DOORS[id]
	local p, name_n, sub_n, x, anchor = draw_door(g, id, o[1], o[2], name)
	local d = { p = p, side = o[5], color = o[6], id = id, name = name_n, sub = sub_n, x = x, anchor = anchor }
	d.b = kit.button(h.buttons, p, id)
	h.doors[#h.doors + 1] = d
	h.door_by_id[id] = d
	return d
end

-- A door's measures (ui/door_pass.lua): its drawing, its side, where it is in its
-- group (that sticks to its edge) and its middle's height
function M.door_info(h, id)
	local d = h.door_by_id[id]
	local o = DOORS[id]
	return { p = d.p, id = id, side = o[5], x = o[1], y = o[2], w = d.p.w, h = d.p.h, cy = o[2] + d.p.h / 2,
		name = gui.get_text(d.name), sub = gui.get_text(d.sub) }
end

-- the small line of a door: never past its room (a long one shrinks)
local function set_sub(d, txt)
	gui.set_text(d.sub, txt)
	local b = d.p.box
	kit.keep_in(d.sub, b, d.p.g, d.x, (b.y0 + b.y1) / 2 + 28, kit.MIN_TEXT, d.anchor)
end

function M.new(color)
	local h = { tops = {}, buttons = {}, doors = {}, door_by_id = {}, t = 0, colore = color, glint_at = 0.9 }

	h.scene = kit.scene(640, 350, { bg = "anelli" })

	-- the middle: the pedestal, the apprentice on it and the backpack, all one button
	local mid = kit.anchor(640, PED_BOTTOM, nil, gui.ANCHOR_BOTTOM)
	h.tops[#h.tops + 1] = mid.node
	h.mid = mid
	h.ped = kit.pic(mid, "pedana", PED_X, PED_TOP, PED_W, PED_H)
	-- the light that runs over the pedestal: a brighter copy seen through a moving slit
	h.slit = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(70, PED_H + 20, 0))
	gui.set_clipping_mode(h.slit, gui.CLIPPING_MODE_STENCIL)
	gui.set_clipping_visible(h.slit, false)
	gui.set_parent(h.slit, mid.node)
	h.ped_light = kit.pic({ node = h.slit, ox = 0, oy = 0 }, "pedana", PED_X - 640, PED_TOP - PED_BOTTOM, PED_W, PED_H)
	gui.set_blend_mode(h.ped_light, gui.BLEND_ADD)
	gui.set_color(h.ped_light, vmath.vector4(1, 0.72, 0.3, 0.45))
	gui.set_enabled(h.slit, false)
	-- the apprentice, its feet on the grate
	h.posa = gui.new_box_node(vmath.vector3(0, PED_BOTTOM - FEET, 0), vmath.vector3(0, 0, 0))
	gui.set_visible(h.posa, false)
	gui.set_parent(h.posa, mid.node)
	local body_shape = gui.new_box_node(vmath.vector3(0, 6, 0), vmath.vector3(0, 0, 0))
	gui.set_visible(body_shape, false)
	gui.set_parent(body_shape, h.posa)
	V.x, V.y, V.z = BODY_K, BODY_K, 1
	gui.set_scale(body_shape, V)
	h.body_shape = body_shape
	h.corpo, h.look, h.color = scoria.new(color, scoria.player), scoria.player, color
	gui.set_parent(h.corpo.root, body_shape)
	scoria.set_enabled(h.corpo, true)
	-- idle without a weapon, without skits (Sergio, 2 Nov)
	h.st = { x = 0, y = 0, facing = 1, grounded = true, moving = 0, fermo = true }
	h.glow = 0
	h.bag = kit.piece(mid, "zainetto", PED_X + 0.88 * PED_W, PED_TOP + 0.52 * PED_H - BAG / 2, BAG)
	local hy = FEET - 380 - 10
	h.hero = kit.zone(mid, h.buttons, PED_X - 10, hy, PED_W + 20, PED_BOTTOM + 6 - hy, "zaino")

	-- top left: the profile's round
	local tl = kit.anchor(0, 0, gui.ANCHOR_LEFT, gui.ANCHOR_TOP)
	h.tops[#h.tops + 1] = tl.node
	h.top_left = tl
	-- (Sergio, 17 Nov: bigger; the level stops before the shell's rivet)
	local x, y = 22, 20
	kit.strip(tl, "guscio", x + 41, y + 11, 388, 76)
	kit.piece(tl, "tondo_oro", x + 49, y + 49, 98)
	h.face_at = { x + 49, y + 49 }
	h.who = kit.text(tl, T.player, x + 111, y + 46, 30, C.SAND)
	h.level = kit.text(tl, "", x + 385, y + 45, 20, C.HOT, "end", 1)
	kit.strip(tl, "riga_scura", x + 111, y + 57, 274, 19)
	h.xp = kit.strip(tl, "barra_brace", x + 114, y + 60, 168, 13)
	kit.zone(tl, h.buttons, x, y, 430, 98, "profilo")

	-- the doors at the sides of the apprentice, each with its shape
	local left = kit.anchor(0, 360, gui.ANCHOR_LEFT)
	h.tops[#h.tops + 1] = left.node
	local right = kit.anchor(1280, 360, gui.ANCHOR_RIGHT)
	h.tops[#h.tops + 1] = right.node
	h.campaign = door(h, left, "campagna", common.campaign)
	h.training = door(h, left, "allenamento", common.training)
	set_sub(h.training, T.training_sub)
	h.events_door = door(h, right, "eventi", common.events)
	h.armory = door(h, right, "armeria", common.armory)
	set_sub(h.armory, T.armory_sub)

	-- under the thread: GIOCA on the right, the wheel on the left
	local br = kit.anchor(1280, 720, gui.ANCHOR_RIGHT, gui.ANCHOR_BOTTOM)
	h.tops[#h.tops + 1] = br.node
	h.play_g = br
	local gw = 420
	local gh = gw * 166 / 849
	h.play = kit.sign(br, "gioca_sigillo", W - 20 - gw, 664 - gh / 2, gw)
	local b = h.play.box
	local base = (b.y0 + b.y1) / 2 + 15
	kit.text(h.play.g, common.play, b.x0 + 10, base, 44, hex("1a0c04"))
	kit.text(h.play.g, T.play_sub, b.x0 + 150, base - 1, 20, hex("1a0c04", 0.85), "start", 1)
	h.play_b = kit.button(h.buttons, h.play, "online", { main = true })
	local bl = kit.anchor(0, 720, gui.ANCHOR_LEFT, gui.ANCHOR_BOTTOM)
	h.tops[#h.tops + 1] = bl.node
	h.low_left = bl
	kit.piece(bl, "ingranaggio", 63, 665, 66)
	kit.zone(bl, h.buttons, 0, kit.THREAD, 152, kit.BAND, "impostazioni")

	-- top right: the wallet's strip (ui/coins.lua, hidden until the first coin)
	local top_right = kit.anchor(1280, 0, gui.ANCHOR_RIGHT, gui.ANCHOR_TOP)
	h.tops[#h.tops + 1] = top_right.node
	h.top_right = top_right
	local wr = kit.group(top_right, 1110, 44)
	h.wallet = coins.wallet(0, 0, wr.node, 0, 0)

	-- black veil dissolving when the home appears
	h.veil = gui.new_box_node(vmath.vector3(W / 2, H / 2, 0), vmath.vector3(W * screen.FULL, H * screen.FULL, 0))
	gui.set_adjust_mode(h.veil, gui.ADJUST_FIT)
	gui.set_color(h.veil, vmath.vector4(0, 0, 0, 1))

	-- where every piece rests, for the entrance
	h.rest = {}
	for _, d in ipairs(h.doors) do h.rest[d.p.node] = gui.get_position(d.p.node) end
	for _, n in ipairs({ h.play.node, tl.node, top_right.node, h.posa, bl.node }) do h.rest[n] = gui.get_position(n) end
	-- what shakes at a thud: the sides (not the pieces that are arriving)
	h.shaken = { right.node, left.node, tl.node }

	-- STESSO TELEFONO is in ALLENAMENTO now; the scenarios of the simulator
	-- (tools/simula) still start their match from here, with a tap on the
	-- old place (now on ALLENAMENTO): an invisible zone, only there, last in
	-- the list (ui.touch looks from the last: it wins over the door under it)
	if sys.get_config_int("megablast.simula", 0) == 1 then
		local sim = kit.anchor(0, 360, gui.ANCHOR_LEFT)
		h.tops[#h.tops + 1] = sim.node
		kit.zone(sim, h.buttons, 190, 560, 64, 24, "local")
	end

	M.hide(h)
	return h
end

-- The two signs that the apprentice can be touched (Sergio, 14 Nov 23:40): a slow
-- light across the pedestal, then an ember glint down the apprentice
local function glint(h)
	-- the slit runs over the pedestal, the light copy stays still inside it (mid's space)
	local cx, cy = PED_X - 640 + PED_W / 2, PED_H / 2
	local from, to = PED_X - 640 - 40, PED_X - 640 + PED_W + 40
	gui.set_enabled(h.slit, true)
	gui.set_position(h.slit, vmath.vector3(from, cy, 0))
	gui.set_position(h.ped_light, vmath.vector3(cx - from, 0, 0))
	gui.animate(h.slit, "position.x", to, gui.EASING_INOUTSINE, 1.3, 0, function() gui.set_enabled(h.slit, false) end)
	gui.animate(h.ped_light, "position.x", cx - to, gui.EASING_INOUTSINE, 1.3)
	-- then a soft light on the apprentice, there and gone: its own hit flash
	-- (battle/flash.fp), barely (a copy seen through a slit had a hard edge and
	-- showed its pieces overlapping)
	h.glow_t = 0
end

-- The entrance. Every time: the doors fly in from their side one after the
-- other, the round and the wallet come down, GIOCA arrives from below. grand (when
-- the game opens): the thread draws itself, the apprentice drops from above onto the
-- pedestal and lands squashed with a thud, and GIOCA slams in with a thud
local function enter(h, wait, grand)
	local function from(node, dx, dy, delay, time, done)
		local p = h.rest[node]
		gui.cancel_animations(node, "position")
		gui.set_position(node, vmath.vector3(p.x + dx, p.y + dy, 0))
		gui.animate(node, "position", p, gui.EASING_OUTBACK, time or (grand and 0.4 or 0.28), wait + delay, done)
	end
	for i, d in ipairs(h.doors) do
		from(d.p.node, 620 * d.side, 0, (grand and 0.06 or 0.04) * (i - 1))
	end
	from(h.top_left.node, 0, 100, grand and 0.1 or 0)
	from(h.top_right.node, 0, 100, grand and 0.1 or 0)
	from(h.low_left.node, 0, -140, grand and 0.1 or 0)
	gui.cancel_animations(h.posa, "position")
	gui.cancel_animations(h.posa, "scale")
	if not grand then
		gui.set_position(h.posa, h.rest[h.posa])
		from(h.play.node, 0, -140, 0)
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
	from(h.play.node, 0, -160, 0.5, 0.36, function() kit.shake(h.shaken, 6) end)
end

-- The grand entrance, when the logo's screen (ui/entry.lua) uncovers the
-- home: under it nothing would be seen
function M.arrive(h)
	if h.is_visible then enter(h, 0, true) end
end

-- Where the ZAINO comes out of the apprentice: the middle of his body, on the screen
function M.apprentice_point(h)
	-- (its group sticks to the bottom: the real bottom is screen.y0)
	return 640, 720 - (FEET - 380 * 0.45) + screen.y0
end

-- The ZAINO went back into him: a small squash
function M.settle(h)
	gui.cancel_animations(h.posa, "scale")
	gui.set_scale(h.posa, vmath.vector3(1.01, 0.99, 1))
	gui.animate(h.posa, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTSINE, 0.22)
end

-- without_veil: you get here with a transition (ui/transition.lua), which already covers.
-- quiet: no entrance (a door's passage brought it back)
function M.show(h, without_veil, quiet)
	for _, n in ipairs(h.tops) do gui.set_enabled(n, true) end
	gui.set_enabled(h.slit, false)
	kit.scene_show(h.scene, true)
	-- the home is kept: the backdrop goes back under it
	kit.scene_place(h.scene, "below", h.tops[1])
	h.buttons.held_down = nil
	h.is_visible = true
	h.glint_at = h.t + 0.9
	-- under the black veil nothing would be seen: the pieces wait for it
	if not quiet then enter(h, without_veil and 0 or 0.2, false) end
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

-- The balance in the wallet (sim/wallet.lua)
function M.wallet(h, scaglie, ossidiana, buoni)
	coins.set(h.wallet, scaglie, ossidiana)
	coins.vouchers(h.wallet, buoni or 0)
end

-- The line under EVENTI (main/events.lua, home_line)
function M.events(h, txt)
	set_sub(h.events_door, kit.upper(txt or ""))
end

-- The face, level and experience in the round, the chapter you are in on CAMPAGNA
function M.profile(h, p)
	local profile = require "menu.profile"
	gui.set_text(h.level, T.level:format(p.livello or 1))
	local f = math.min(1, (p.xp or 0) / profile.xp_level(p.livello or 1))
	kit.strip_width(h.xp, math.max(18, PLATE_BAR * f))
	if h.face then gui.delete_node(h.face) end
	h.face = score.face(h.top_left.node, h.face_at[1], -h.face_at[2], 82, h.color, scoria.player)
	-- the first chapter with a mission still to win
	local stars = p.stelle or {}
	local chapter
	for _, cap in ipairs(campaign.CAPITOLI) do
		chapter = cap
		local done = 0
		for _, l in ipairs(cap.missioni) do
			if (stars[l.id] or {})[1] then done = done + 1 end
		end
		if done < #cap.missioni then break end
	end
	h.chapter = kit.upper(chapter.titolo)
	kit.reached(chapter.id)
	if not h.in_queue then set_sub(h.campaign, h.chapter) end
end

-- The apprentice at rest in his pose now, not after the springs' first frames
local function pose_now(h)
	for _ = 1, 30 do scoria.update(h.corpo, 1 / 30, h.st) end
end

-- The devil puts on the pieces of the active loadout of the profile p: they
-- become the look of whoever plays here (scoria.player), for every menu and
-- the offline battles
function M.wear(h, p)
	local profile = require "menu.profile"
	local a = profile.active_loadout(p)
	scoria.set_player(scoria.look_of(a.gear, profile.tier(p, a)))
	if h.look == scoria.player then return end
	h.look = scoria.player
	local parent = gui.get_parent(h.corpo.root)
	local enabled = gui.is_enabled(h.corpo.root)
	gui.delete_node(h.corpo.root)
	h.corpo = scoria.new(h.color, scoria.player)
	gui.set_parent(h.corpo.root, parent)
	scoria.set_enabled(h.corpo, enabled)
	-- posed at once: made while the home is hidden, it would show up raw (the
	-- weapon at its feet, the arms anyhow) under a door's passage
	pose_now(h)
	if h.face then
		gui.delete_node(h.face)
		h.face = score.face(h.top_left.node, h.face_at[1], -h.face_at[2], 82, h.color, scoria.player)
	end
end

function M.queued(h, on)
	h.in_queue = on
	h.campaign.b.spento = on or nil
	gui.set_color(h.campaign.name, on and kit.with_alpha(h.campaign.color, 0.5) or h.campaign.color)
	set_sub(h.campaign, on and kit.upper(T.leave_queue_first) or (h.chapter or ""))
end

function M.update(h, dt)
	-- (under a door's passage the home shows while it is not yet visible: the
	-- apprentice keeps breathing there too)
	if not h.is_visible and not h.under then return end
	h.t = h.t + dt
	if h.glow_t then
		h.glow_t = h.glow_t + dt
		local u = (h.glow_t - 0.6) / 0.8
		if u >= 1 then h.glow_t = nil end
		h.glow = (u > 0 and u < 1) and 0.2 * math.sin(math.pi * u) or 0
	end
	-- (scoria takes the flash down by dt * 6 and shows 0.85 * 1.5 of what is left)
	if h.glow > 0 then h.corpo.flash = h.glow / 1.275 + dt * 6 end
	scoria.update(h.corpo, dt, h.st)
	kit.scene_fit()
	if h.t >= h.glint_at then
		glint(h)
		h.glint_at = h.t + 5.5
	end
	-- a pressed door goes down
	local held = h.buttons.held_down
	if held ~= h.held then
		if h.held and h.held.piastra then kit.press(h.held.piastra, false) end
		if held and held.piastra then kit.press(held.piastra, true) end
		h.held = held
	end
end

-- The third sign: touched, the apprentice breathes, barely (Sergio, 14 Nov 23:55)
local function breathe(h)
	gui.cancel_animations(h.posa, "scale")
	gui.set_scale(h.posa, vmath.vector3(1, 1, 1))
	gui.animate(h.posa, "scale", vmath.vector3(1.015, 0.985, 1), gui.EASING_INOUTSINE, 0.1, 0, function()
		gui.animate(h.posa, "scale", vmath.vector3(0.995, 1.01, 1), gui.EASING_INOUTSINE, 0.11, 0, function()
			gui.animate(h.posa, "scale", vmath.vector3(1, 1, 1), gui.EASING_INOUTSINE, 0.11)
		end)
	end)
	gui.animate(h.bag, "euler.z", 2, gui.EASING_OUTSINE, 0.13, 0, nil, gui.PLAYBACK_ONCE_PINGPONG)
end

function M.on_input(h, action_id, action)
	if not h.is_visible then return nil end
	local choice = ui.touch(h.buttons, action_id, action)
	if choice == "zaino" then breathe(h) end
	return choice
end

return M
