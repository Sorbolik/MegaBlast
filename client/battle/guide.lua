-- The lesson guide (sim/missions.lua, highlight): a yellow ring pulsing on
-- the control to touch and, for gestures, a finger doing them. On the phone
-- the finger pushes the left stick sideways (walk) or up (jump), pushes the
-- right stick toward the target (aim) or taps the right half of the screen
-- while aiming (cancel); on the computer the keys pulse (A D, SPACE), with a
-- controller the sticks. A few nodes made once: every frame they only move.
--
--   local gd = guida.new()                          -- after the HUD, so it sits on top
--   gd:aggiorna(cosa, where, commands, pads)        -- every frame; cosa nil: nothing
--   gd.gesture(cosa)                                -- a gesture (jump, aim...), not a button
--     where = { x, y, d }: the control to circle (or nil); pads = { muovi, mira }:
--     the centers of the sticks; commands: "telefono" (finger gestures),
--     "computer" or "controller" (the keys)

local ui = require "ui.ui"
local controller = require "ui.controller"
local T = require("lang.text").guide

local M = {}

local YELLOW = vmath.vector4(1, 0.82, 0.25, 1)
local FINGER = vmath.vector4(1, 1, 1, 0.9)
local WAVE = vmath.vector4(1, 1, 1, 0.85)
-- how far the finger goes on the stick, and where it taps to cancel
local RUN = 95
local CANCEL = { x = 960, y = 400 }
-- finger gestures: on which stick, toward where, and the arrow
local GESTURES = {
	cammina = { pad = "muovi", dx = 1, dy = 0, arrow = ">" },
	salta = { pad = "muovi", dx = 0, dy = 1, arrow = "^" },
	mira = { pad = "mira", dx = 0.7, dy = 0.7 },
}
-- on the computer and with a controller, the keys
local KEYS_LIST = T.keys
local V = vmath.vector3(0, 0, 0)

local function pos(n, x, y)
	V.x, V.y, V.z = x, y, 0
	gui.set_position(n, V)
end

function M.new()
	local gd = setmetatable({ cosa = nil }, { __index = M })
	gd.ring_node = ui.ring_node(0, 0, 100, 7, YELLOW)
	gd.finger = ui.disco(0, 0, 48, FINGER)
	gd.wave = ui.ring_node(0, 0, 48, 5, WAVE)
	gd.arrow = ui.titolo("^", 0, 0, 1.6, YELLOW)
	gd.tasto = ui.pannello(0, 0, 170, 58)
	gd.key_label = ui.titolo("", 0, 2, 0.75, ui.C.LIGHT, gd.tasto)
	for _, n in ipairs({ gd.ring_node, gd.finger, gd.wave, gd.arrow, gd.tasto }) do gui.set_enabled(n, false) end
	return gd
end

-- Restarts the animation loop: changes only when the control changes
local function soul(gd, what, commands, pads)
	local phone, keys = commands == "telefono", KEYS_LIST[commands] or {}
	for _, n in ipairs({ gd.ring_node, gd.finger, gd.wave, gd.arrow, gd.tasto }) do
		gui.cancel_animations(n)
		gui.set_scale(n, vmath.vector3(1, 1, 1))
	end
	gui.animate(gd.ring_node, "scale", vmath.vector3(1.22, 1.22, 1), gui.EASING_INOUTSINE, 0.55, 0, nil,
		gui.PLAYBACK_LOOP_PINGPONG)
	gui.set_color(gd.finger, FINGER)
	gui.set_color(gd.wave, WAVE)
	local gesture = GESTURES[what]
	if gesture and phone then
		-- the finger starts at the stick's center and goes toward the gesture, in a loop
		local p = pads[gesture.pad]
		local x, y = p.x + gesture.dx * RUN, p.y + gesture.dy * RUN
		pos(gd.finger, p.x, p.y)
		gui.animate(gd.finger, "position", vmath.vector3(x, y, 0), gui.EASING_OUTQUAD, 0.8, 0.2, nil,
			gui.PLAYBACK_LOOP_FORWARD)
		gui.animate(gd.finger, "color.w", 0, gui.EASING_INQUAD, 0.8, 0.2, nil, gui.PLAYBACK_LOOP_FORWARD)
		if gesture.arrow then
			gui.set_text(gd.arrow, gesture.arrow)
			pos(gd.arrow, x + gesture.dx * 40, y + gesture.dy * 40)
			gui.animate(gd.arrow, "scale", vmath.vector3(1.3, 1.3, 1), gui.EASING_INOUTSINE, 0.5, 0, nil,
				gui.PLAYBACK_LOOP_PINGPONG)
		end
	elseif what == "annulla" and phone then
		-- a tap on the right half: the finger and the wave spreading out
		pos(gd.finger, CANCEL.x, CANCEL.y)
		pos(gd.wave, CANCEL.x, CANCEL.y)
		gui.animate(gd.wave, "scale", vmath.vector3(2.6, 2.6, 1), gui.EASING_OUTQUAD, 0.9, 0, nil,
			gui.PLAYBACK_LOOP_FORWARD)
		gui.animate(gd.wave, "color.w", 0, gui.EASING_OUTQUAD, 0.9, 0, nil, gui.PLAYBACK_LOOP_FORWARD)
	elseif keys[what] then
		-- with jump on a key (settings) that key is shown
		local jump_name = commands == "controller" and what == "salta" and controller.name_of("salta") or ""
		local sides = { muove = string.upper(controller.lato("muove")), mira = string.upper(controller.lato("mira")) }
		gui.set_text(gd.key_label, jump_name ~= "" and jump_name or (keys[what]:gsub("{(%a+)}", sides)))
		pos(gd.tasto, pads.muovi.x, pads.muovi.y)
		gui.animate(gd.tasto, "scale", vmath.vector3(1.12, 1.12, 1), gui.EASING_INOUTSINE, 0.45, 0, nil,
			gui.PLAYBACK_LOOP_PINGPONG)
	end
end

-- Is it a gesture (or a key), not a button to circle?
function M.gesture(what)
	return GESTURES[what] ~= nil or what == "annulla"
end

function M.aggiorna(gd, what, where, commands, pads)
	local lookup_key = what and (what .. commands) or nil
	local phone, keys = commands == "telefono", KEYS_LIST[commands] or {}
	if lookup_key ~= gd.cosa then
		gd.cosa = lookup_key
		local gesture = GESTURES[what]
		gui.set_enabled(gd.finger, phone and (gesture ~= nil or what == "annulla"))
		gui.set_enabled(gd.wave, what == "annulla" and phone)
		gui.set_enabled(gd.arrow, phone and gesture ~= nil and gesture.arrow ~= nil)
		gui.set_enabled(gd.tasto, keys[what] ~= nil)
		if what then soul(gd, what, commands, pads) end
	end
	gui.set_enabled(gd.ring_node, where ~= nil)
	if where then
		pos(gd.ring_node, where.x, where.y)
		local d = where.d + 26
		V.x, V.y, V.z = d, d, 0
		gui.set_size(gd.ring_node, V)
		gui.set_inner_radius(gd.ring_node, d / 2 - 7)
	end
end

return M
