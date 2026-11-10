-- The step of a piece (levels 10, 20 and 30; page "Scaglie e Ossidiana",
-- choice 11A): the one scene longer than 200 ms besides the home's unlocks,
-- once per step, skipped with a tap, back by itself. The screen darkens, the
-- piece rises in the middle, three hammer blows (a 4 px shake and eight
-- sparks each), at the third a white flash and the border takes the new
-- grade's color, then the words.
--
--   local scene = require "ui.step_scene"
--   local sc = scene.new(slot_name, set_name, level, on_blow)  -- on_blow(i): the sound
--   scene.update(sc, dt) -> true while it runs
--   scene.skip(sc)  -- a tap
--   scene.delete(sc)

local ui = require "ui.ui"
local screen = require "ui.screen"
local equip = require "sim.gear"
local T = require("lang.text").pieces

local M = {}

M.DARK, M.RISE, M.BLOW, M.FIRST = 0.15, 0.25, 0.3, 0.45
M.HOLD = 1.5   -- how long it stays after the last blow
local ROMAN = { "I", "II", "III", "IV" }
local W, H = 1280, 720

local function vec(x, y) return vmath.vector3(x, y, 0) end

function M.new(slot_name, set_name, level, on_blow)
	local tier = equip.tier(level)
	local sc = { t = 0, blows = 0, on_blow = on_blow, tier = tier, done = false }
	sc.root = gui.new_box_node(vec(W / 2, H / 2), vec(W * screen.FULL, H * screen.FULL))
	gui.set_adjust_mode(sc.root, gui.ADJUST_FIT)
	gui.set_color(sc.root, vmath.vector4(0, 0, 0, 0))
	gui.animate(sc.root, "color.w", 0.72, gui.EASING_OUTQUAD, M.DARK)
	-- the piece: a square in the old grade's color, it rises from below
	sc.piece, sc.edge = ui.pannello(0, -60, 220, 220, sc.root)
	gui.set_color(sc.edge, ui.C.GRADI[math.max(1, tier - 1)])
	ui.titolo(slot_name, 0, 18, 0.9, ui.C.TEXT, sc.piece)
	ui.testo(set_name, 0, -26, 0.8, ui.C.OFF, sc.piece)
	gui.set_scale(sc.piece, vmath.vector3(0.6, 0.6, 1))
	gui.animate(sc.piece, "position.y", 20, gui.EASING_OUTBACK, M.RISE, M.DARK)
	gui.animate(sc.piece, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, M.RISE, M.DARK)
	-- the words, lit after the third blow
	sc.title = ui.titolo(T.step_title:format(level), 0, 220, 1.4, ui.C.GOLD, sc.root)
	sc.name = ui.titolo(T.step_grade:format(slot_name, set_name, ROMAN[tier], T.grades[tier]), 0, -160, 0.8, ui.C.TEXT, sc.root)
	sc.note = ui.testo(level >= equip.LIVELLO_MAX and T.step_top or T.step_look, 0, -200, 0.7, ui.C.GRADI[tier], sc.root)
	ui.testo(T.skip, 0, -300, 0.55, ui.C.OFF, sc.root)
	for _, n in ipairs({ sc.title, sc.name, sc.note }) do gui.set_color(n, vmath.vector4(1, 1, 1, 0)) end
	sc.flash = gui.new_box_node(vec(0, 0), vec(W * screen.FULL, H * screen.FULL))
	gui.set_color(sc.flash, vmath.vector4(1, 1, 1, 0))
	gui.set_parent(sc.flash, sc.root)
	return sc
end

-- eight sparks from the piece's edges, in the grade's color
local function sparks(sc, color)
	for i = 1, 8 do
		local a = (i - 0.5) * math.pi / 4
		local s = ui.sagoma("forma", math.cos(a) * 130, 20 + math.sin(a) * 130, 22, 5, color, sc.root)
		gui.set_slice9(s, vmath.vector4(2, 2, 2, 2))
		gui.set_rotation(s, vmath.vector3(0, 0, math.deg(a)))
		gui.animate(s, "position", vec(math.cos(a) * 220, 20 + math.sin(a) * 220), gui.EASING_OUTQUAD, 0.28)
		gui.animate(s, "color.w", 0, gui.EASING_INQUAD, 0.28, 0, function() gui.delete_node(s) end)
	end
end

local function blow(sc)
	sc.blows = sc.blows + 1
	if sc.on_blow then sc.on_blow(sc.blows) end
	-- the shake: 4 px and back
	gui.set_position(sc.piece, vec(4, 20))
	gui.animate(sc.piece, "position.x", 0, gui.EASING_OUTELASTIC, 0.2)
	local last = sc.blows == 3
	sparks(sc, last and ui.C.GRADI[sc.tier] or ui.C.GOLD)
	if last then
		gui.set_color(sc.flash, vmath.vector4(1, 1, 1, 0.85))
		gui.animate(sc.flash, "color.w", 0, gui.EASING_OUTQUAD, 0.08)
		gui.set_color(sc.edge, ui.C.GRADI[sc.tier])
		gui.set_scale(sc.piece, vmath.vector3(1.12, 1.12, 1))
		gui.animate(sc.piece, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, 0.25)
		for _, n in ipairs({ sc.title, sc.name, sc.note }) do
			gui.animate(n, "color.w", 1, gui.EASING_OUTQUAD, 0.2)
		end
	end
end

function M.update(sc, dt)
	if sc.done then return false end
	sc.t = sc.t + dt
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
end

return M
