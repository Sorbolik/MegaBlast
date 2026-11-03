-- The home (main menu): behind it the painted Forge background scrolling
-- slowly (drawn by the terrain mesh, battle/terrain.script; Sergio 2 Nov),
-- the apprentice standing still without a weapon with the Core's glow behind
-- (tapping it opens the PROFILO), the game's name and only the buttons needed
-- today: GIOCA (online match), CAMPAGNA, ALLENAMENTO, STESSO TELEFONO, ARMERIA,
-- EVENTI and, at the top right, the IMPOSTAZIONI wheel (menu/settings.lua).
-- New screens add their button here once they exist (style in ui/ui.lua).
--
-- Use (from the gui_script, which has the ui texture and the titolo font):
--   local home = require "menu.home"
--   local h = home.new(colore)                  -- creates the nodes, hidden
--   home.show(h, without_veil) / home.hide(h)
--   home.update(h, dt)                          -- every frame while visible
--   local scelta = home.on_input(h, action_id, action)   -- "online", "campagna", "allenamento", "local", "armeria", "eventi",
--                                                        -- "impostazioni", "profilo" (tapping the devil) or nil
--   home.eventi(h, riga)                        -- the line under EVENTI

local game = require "sim.game"
local scoria = require "battle.scoria"
local ui = require "ui.ui"
local screen = require "ui.screen"

local M = {}

local W, H = 1280, 720
-- the Scoria (game.DISEGNO_H tall) about 220 px tall, feet here
local BODY_X, BODY_Y = 400, 200
local BODY_K = 220 / game.DISEGNO_H

local V = vmath.vector3()

local function empty(x, y, parent)
	local n = gui.new_box_node(vmath.vector3(x, y, 0), vmath.vector3(0, 0, 0))
	gui.set_visible(n, false)
	if parent then gui.set_parent(n, parent) end
	return n
end

-- group stuck to a screen edge
local function angle_deg(h, x, y, xa, ya)
	local n = empty(x, y)
	gui.set_xanchor(n, xa)
	gui.set_yanchor(n, ya)
	h.tops[#h.tops + 1] = n
	return n
end

function M.new(color)
	local h = { tops = {}, buttons = {}, t = 0, colore = color }

	-- the Core's glow behind the Scoria, breathing
	h.posa = empty(BODY_X, BODY_Y)
	h.tops[#h.tops + 1] = h.posa
	h.luce = ui.alone(0, 110, 620, color, h.posa)
	-- a veil of shadow under the feet: the ground that isn't there
	local ground = ui.alone(0, 0, 260, ui.C.SHADOW, h.posa)
	gui.set_blend_mode(ground, gui.BLEND_ALPHA)
	V.x, V.y, V.z = 1, 0.16, 1
	gui.set_scale(ground, V)
	local body_shape = empty(0, 0, h.posa)
	V.x, V.y, V.z = BODY_K, BODY_K, 1
	gui.set_scale(body_shape, V)
	h.corpo = scoria.new(color, scoria.PERSONAGGIO)
	gui.set_parent(h.corpo.root, body_shape)
	scoria.set_enabled(h.corpo, true)
	-- idle without a weapon, without skits (Sergio, 2 Nov)
	h.st = { x = 0, y = 0, facing = 1, grounded = true, moving = 0, fermo = true }
	-- tapping the devil opens the profile (menu/profile_tabs.lua): an invisible
	-- zone over it, and a discreet label under the feet
	local zone = gui.new_box_node(vmath.vector3(BODY_X, BODY_Y + 120, 0), vmath.vector3(260, 320, 0))
	gui.set_visible(zone, false)
	h.tops[#h.tops + 1] = zone
	h.buttons[#h.buttons + 1] = { nodo = zone, bordo = zone, ui_action = "profilo", colore = ui.C.LIGHT, riposo = ui.C.LIGHT }
	local label = ui.testo("IL TUO PROFILO", 0, -34, 0.7, ui.C.TEXT, h.posa)
	-- on the painted background the label with a dark outline
	gui.set_outline(label, ui.C.SHADOW)
	gui.set_inherit_alpha(label, true)

	-- the name at the top left
	local top_left = angle_deg(h, 48, H - 56, gui.ANCHOR_LEFT, gui.ANCHOR_TOP)
	local nome = ui.titolo("MEGABLAST", 0, 0, 1.3, ui.C.LIGHT, top_left)
	gui.set_pivot(nome, gui.PIVOT_W)

	-- bottom right: the matches
	local dx = angle_deg(h, W - 48 - 170, 48, gui.ANCHOR_RIGHT, gui.ANCHOR_BOTTOM)
	ui.button(h.buttons, 0, 344, 340, 72, "CAMPAGNA", "campagna", nil, dx)
	ui.button(h.buttons, 0, 256, 340, 72, "ALLENAMENTO", "allenamento", nil, dx)
	ui.button(h.buttons, 0, 168, 340, 72, "STESSO TELEFONO", "local", nil, dx)
	ui.button(h.buttons, 0, 60, 340, 108, "GIOCA", "online", { main = true, colore = color }, dx)

	-- bottom left: loadouts, tree and sets
	local sx = angle_deg(h, 48 + 120, 48, gui.ANCHOR_LEFT, gui.ANCHOR_BOTTOM)
	ui.button(h.buttons, 0, 60, 240, 72, "ARMERIA", "armeria", nil, sx)
	-- above: the EVENTI (menu/board.lua), with what is happening now below
	local ev = ui.button(h.buttons, 0, 160, 240, 96, "", "eventi", nil, sx)
	ui.testo("EVENTI", 0, 14, 0.9, ui.C.TEXT, ev)
	h.events_row = ui.testo("", 0, -22, 0.55, ui.C.OFF, ev)

	-- top right: the settings
	h.tops[#h.tops + 1] = ui.impostazioni(h.buttons, "impostazioni", nil, true)

	-- black veil dissolving when the home appears
	h.veil = gui.new_box_node(vmath.vector3(W / 2, H / 2, 0), vmath.vector3(W * screen.FULL, H * screen.FULL, 0))
	gui.set_adjust_mode(h.veil, gui.ADJUST_FIT)
	gui.set_color(h.veil, vmath.vector4(0, 0, 0, 1))

	M.hide(h)
	return h
end

-- without_veil: you get here with a transition (ui/transition.lua), which already covers
function M.show(h, without_veil)
	for _, n in ipairs(h.tops) do gui.set_enabled(n, true) end
	h.buttons.held_down = nil
	h.is_visible = true
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
	h.is_visible = true
end

function M.hide(h)
	for _, n in ipairs(h.tops) do gui.set_enabled(n, false) end
	gui.cancel_animations(h.veil, "color.w")
	gui.set_enabled(h.veil, false)
	h.is_visible = false
end

-- The line under EVENTI (main/events.lua, home_line)
function M.eventi(h, txt)
	gui.set_text(h.events_row, txt)
end

function M.update(h, dt)
	if not h.is_visible then return end
	h.t = h.t + dt
	scoria.update(h.corpo, dt, h.st)
	local c = h.colore
	gui.set_color(h.luce, vmath.vector4(c.x, c.y, c.z, 0.22 + 0.08 * math.sin(h.t * 1.7)))
end

function M.on_input(h, action_id, action)
	if not h.is_visible then return nil end
	return ui.tocco(h.buttons, action_id, action)
end

return M
