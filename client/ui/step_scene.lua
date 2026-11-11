-- The step of a piece (levels 10, 20 and 30; page "Scaglie e Ossidiana",
-- choice 11A): the one scene longer than 200 ms besides the home's unlocks,
-- once per step, skipped with a tap, back by itself. A dark sheet with the
-- rays (ui/kit.lua, Figma coordinates), SCATTO on a light plate with the piece
-- and its notches, the devil in the middle: three hammer blows (a 4 px shake
-- and eight sparks each), at the third a white flash, the notches take the
-- new grade's color and what is new comes in on the right.
--
--   local scene = require "ui.step_scene"
--   local sc = scene.new(slot_name, set_name, level, on_blow, color)  -- on_blow(i): the sound; color: the devil's
--   scene.update(sc, dt) -> true while it runs
--   scene.skip(sc)  -- a tap
--   scene.delete(sc)

local ui = require "ui.ui"
local kit = require "ui.kit"
local screen = require "ui.screen"
local scoria = require "battle.scoria"
local game = require "sim.game"
local equip = require "sim.gear"
local T = require("lang.text").pieces
local go_on = require("lang.text").podium.go_on

local M = {}

M.DARK, M.RISE, M.BLOW, M.FIRST = 0.15, 0.25, 0.3, 0.45
M.HOLD = 2.5   -- how long it stays after the last blow
local ROMAN = { "I", "II", "III", "IV" }
local W, H = 1280, 720
local KC = kit.C
-- where the devil stands (game coordinates) and where the sparks leave from
local FEET_X, FEET_Y, HEART_Y = 640, 118, 300

local function vec(x, y) return vmath.vector3(x, y, 0) end

function M.new(slot_name, set_name, level, on_blow, color)
	local tier = equip.tier(level)
	local sc = { t = 0, blows = 0, on_blow = on_blow, tier = tier, done = false, new = {}, notches = {}, level = level }
	sc.back = gui.new_box_node(vec(W / 2, H / 2), vec(W * screen.FULL, H * screen.FULL))
	gui.set_color(sc.back, vmath.vector4(KC.INK.x, KC.INK.y, KC.INK.z, 0))
	gui.animate(sc.back, "color.w", 0.92, gui.EASING_OUTQUAD, M.DARK)
	sc.scene = kit.scene(640, 350, { halo = 520, sparks = 60, accent = KC.PURPLE })
	sc.root = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_visible(sc.root, false)
	local g = { node = sc.root, ox = 0, oy = 720 }
	-- the devil rises in the middle
	sc.piece = gui.new_box_node(vec(FEET_X, FEET_Y - 60), vec(0, 0))
	gui.set_visible(sc.piece, false)
	gui.set_parent(sc.piece, sc.root)
	sc.figure = scoria.new(color or ui.C.SQUADRA[1], scoria.PERSONAGGIO)
	sc.st = { x = 0, y = 0, facing = 1, grounded = true, moving = 0, fermo = true }
	scoria.update(sc.figure, 0, sc.st)
	local k = 300 / game.DISEGNO_H
	sc.k = k
	gui.set_scale(sc.piece, vmath.vector3(k * 0.6, k * 0.6, 1))
	gui.set_parent(sc.figure.root, sc.piece)
	scoria.set_enabled(sc.figure, true)
	gui.animate(sc.piece, "position.y", FEET_Y, gui.EASING_OUTBACK, M.RISE, M.DARK)
	gui.animate(sc.piece, "scale", vmath.vector3(k, k, 1), gui.EASING_OUTBACK, M.RISE, M.DARK)
	-- what happened on a light plate, the piece under it and its notches (still in the old grade's color)
	kit.sand(g, 30, 36, 330, 104, KC.PURPLE, { sk = 34, d = 14 })
	local head = kit.text(g, T.step_title, 64, 116, 74, KC.INK)
	local wide = kit.width(head)
	if wide > 280 then
		local s = gui.get_scale(head)
		gui.set_scale(head, vec(s.x * 280 / wide, s.y * 280 / wide))
	end
	kit.info(g, 60, 156, 330, 36, ui.C.GRADI[tier])
	local what = kit.text(g, kit.upper(slot_name .. " · " .. set_name), 225, 181, 16, KC.SAND, "middle", 1)
	wide = kit.width(what)
	if wide > 290 then
		local s = gui.get_scale(what)
		gui.set_scale(what, vec(s.x * 290 / wide, s.y * 290 / wide))
	end
	local before = ui.C.GRADI[math.max(1, tier - 1)]
	for i = 1, equip.LIVELLO_MAX do
		local big = i % 10 == 0
		sc.notches[i] = kit.para(g, 70 + (i - 1) * 10, big and 222 or 226, 7, big and 26 or 18, 3, i <= level and before or KC.LINE)
	end
	-- what is new, on the right: it comes in after the third blow
	sc.label = kit.text(g, T.step_new, 890, 236, 14, KC.HOT_TOP, "start", 1.5)
	gui.set_color(sc.label, vmath.vector4(KC.HOT_TOP.x, KC.HOT_TOP.y, KC.HOT_TOP.z, 0))
	local rows = {
		{ T.step_grade:format(ROMAN[tier], kit.upper(T.grades[tier])), ui.C.GRADI[tier] },
		{ kit.upper(level >= equip.LIVELLO_MAX and T.step_top or T.step_look), KC.PURPLE },
	}
	for i, r in ipairs(rows) do
		local x, y = 880 - (i - 1) * 6, 250 + (i - 1) * 62
		local h = kit.group(g, x + 160, y + 24)
		kit.info(h, x, y, 320, 48, r[2])
		local t = kit.text(h, r[1], x + 28, y + 32, 20, KC.SAND)
		wide = kit.width(t)
		if wide > 276 then
			local s = gui.get_scale(t)
			gui.set_scale(t, vec(s.x * 276 / wide, s.y * 276 / wide))
		end
		gui.set_scale(h.node, vec(0.01, 0.01))
		sc.new[i] = h.node
	end
	-- the way on (a tap anywhere does the same)
	sc.right = kit.anchor(1280, 720, gui.ANCHOR_RIGHT, gui.ANCHOR_BOTTOM)
	kit.action(sc.right, go_on, 930, 560, 270, 84, { size = 44 })
	sc.flash = gui.new_box_node(vec(W / 2, H / 2), vec(W * screen.FULL, H * screen.FULL))
	gui.set_color(sc.flash, vmath.vector4(1, 1, 1, 0))
	return sc
end

-- eight sparks from around the devil, in the grade's color
local function sparks(sc, color)
	for i = 1, 8 do
		local a = (i - 0.5) * math.pi / 4
		local s = ui.sagoma("forma", FEET_X + math.cos(a) * 170, HEART_Y + math.sin(a) * 170, 22, 5, color, sc.root)
		gui.set_slice9(s, vmath.vector4(2, 2, 2, 2))
		gui.set_rotation(s, vmath.vector3(0, 0, math.deg(a)))
		gui.animate(s, "position", vec(FEET_X + math.cos(a) * 270, HEART_Y + math.sin(a) * 270), gui.EASING_OUTQUAD, 0.28)
		gui.animate(s, "color.w", 0, gui.EASING_INQUAD, 0.28, 0, function() gui.delete_node(s) end)
	end
end

local function blow(sc)
	sc.blows = sc.blows + 1
	if sc.on_blow then sc.on_blow(sc.blows) end
	-- the shake: 4 px and back
	gui.cancel_animations(sc.piece, "position")
	gui.set_position(sc.piece, vec(FEET_X + 4, FEET_Y))
	gui.animate(sc.piece, "position.x", FEET_X, gui.EASING_OUTELASTIC, 0.2)
	local last = sc.blows == 3
	sparks(sc, last and ui.C.GRADI[sc.tier] or ui.C.GOLD)
	if last then
		gui.set_color(sc.flash, vmath.vector4(1, 1, 1, 0.85))
		gui.animate(sc.flash, "color.w", 0, gui.EASING_OUTQUAD, 0.08)
		for i = 1, sc.level do kit.tint(sc.notches[i].parts, ui.C.GRADI[sc.tier]) end
		local k = sc.k
		gui.cancel_animations(sc.piece, "scale")
		gui.set_scale(sc.piece, vmath.vector3(k * 1.12, k * 1.12, 1))
		gui.animate(sc.piece, "scale", vmath.vector3(k, k, 1), gui.EASING_OUTBACK, 0.25)
		gui.animate(sc.label, "color.w", 1, gui.EASING_OUTQUAD, 0.2)
		for i, n in ipairs(sc.new) do
			gui.animate(n, "scale", vec(1, 1), gui.EASING_OUTBACK, 0.25, 0.08 * i)
		end
	end
end

function M.update(sc, dt)
	if sc.done then return false end
	sc.t = sc.t + dt
	scoria.update(sc.figure, dt, sc.st)
	while sc.blows < 3 and sc.t >= M.FIRST + sc.blows * M.BLOW do blow(sc) end
	if sc.t >= M.FIRST + 2 * M.BLOW + M.HOLD then sc.done = true end
	return not sc.done
end

function M.skip(sc)
	if sc.blows < 3 then
		sc.t = M.FIRST + 2 * M.BLOW
		while sc.blows < 3 do blow(sc) end
	else
		sc.done = true
	end
end

function M.delete(sc)
	gui.delete_node(sc.root)
	gui.delete_node(sc.right.node)
	gui.delete_node(sc.flash)
	for _, n in ipairs(sc.scene.tops) do gui.delete_node(n) end
	gui.delete_node(sc.back)
end

return M
