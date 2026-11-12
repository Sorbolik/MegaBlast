-- End of a level: a campaign mission or a lesson (sim/missions.lua). One
-- screen, no popups: the level's name, the stars taken lighting up one after
-- the other (with the tick rising in pitch, like the points in a match) and
-- under each one what it takes to get it, so you see how to do better. Below:
-- RIPROVA and CAMPAGNA (the list) at the left, AVANTI at the right (the next
-- level; if it was the last, it goes to the list). Drawn with ui/kit.lua.
--
--   local level_end = require "menu.level_end"
--   local f = level_end.new({ titolo = "Il Rampino", stelle = { true, true, false },
--     criteria = { "FATTA", "CON 100 PUNTI DI VANTAGGIO", "SENZA MORIRE" }, vantaggio = 85, record = 3, avanti = true }, sound)
--     stelle: which ones it took (each with its criterion); criteria: what each
--     one takes (missions.criteria); vantaggio: the lead points made (nil where
--     points don't count: the lessons); record: how many stars the mission
--     already had; medaglia: the second is Favilla's medal (the cortile);
--     avanti: there is a next level; sound(v): the tick, v = speed (pitch);
--     gain: profile.missione's experience and coins (the receipt on the right, ui/receipt.lua), prof: the profile;
--     coin(kind, i): the sound of a coin landing in the wallet pill; xp(i, n, level_up): a spark landing in the bar
--   fine_livello.update(f, dt)
--   fine_livello.on_input(f, action_id, action) -> "riprova", "avanti", "indietro", "sigilli" or nil
--   fine_livello.destroy(f)

local ui = require "ui.ui"
local kit = require "ui.kit"
local scoria = require "battle.scoria"
local game = require "sim.game"
local receipt = require "ui.receipt"
local T = require("lang.text").level_end
local common = require("lang.text").common

local M = {}

local KC = kit.C
-- when each star lights up (seconds from opening) and how long the pop lasts
M.RHYTHM, M.FIRST, M.SHOT = 0.3, 0.25, 0.18

local function vec(x, y) return vmath.vector3(x, y, 0) end

function M.new(o, sound)
	local f = { buttons = {}, t = 0, sound = sound, coin = o.coin, lit_ones = 0, prese = {} }
	local n = 0
	f.scene = kit.scene(640, 360, { dim = 0.72 })
	f.radice = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_visible(f.radice, false)
	local g = { node = f.radice, ox = 0, oy = 720 }
	-- the devil in the middle: he cheers if it went well
	local pose = gui.new_box_node(vec(640, 720 - 636), vec(0, 0))
	gui.set_visible(pose, false)
	gui.set_parent(pose, f.radice)
	f.figure = scoria.new(ui.C.SQUADRA[1], scoria.PERSONAGGIO)
	f.st = { x = 0, y = 0, facing = 1, grounded = true, moving = 0, turno = true, vittoria = not o.fallita, fermo = o.fallita }
	scoria.update(f.figure, 0, f.st)
	local k = 300 / game.DISEGNO_H
	gui.set_scale(pose, vmath.vector3(k, k, 1))
	gui.set_parent(f.figure.root, pose)
	scoria.set_enabled(f.figure, true)
	-- how it went on a light plate, under it the level's name
	local on_plate = kit.sand(g, 30, 36, 560, 110, KC.HOT, { sk = 34, d = 14 })
	local head = kit.text(on_plate.g, o.fallita and T.failed or T.done, 66, 116, 70, KC.INK)
	local wide = kit.width(head)
	if wide > 506 then
		local sc = gui.get_scale(head)
		gui.set_scale(head, vec(sc.x * 506 / wide, sc.y * 506 / wide))
	end
	kit.info(g, 70, 160, 300, 36, KC.HOT)
	local name = kit.text(g, kit.upper(o.titolo), 220, 185, 17, KC.SAND, "middle", 1)
	wide = kit.width(name)
	if wide > 270 then
		local sc = gui.get_scale(name)
		gui.set_scale(name, vec(sc.x * 270 / wide, sc.y * 270 / wide))
	end
	local criteria = o.criteria
	-- three stars; in the cortile «Fatta» and Favilla's medal, or «Fatta» alone
	local count = #criteria
	for i = 1, count do
		local big = count == 3 and i == 2
		local r = big and 50 or 42
		local x, y = 130 + (i - 1) * 130, 720 - (278 - (big and 14 or 0))
		local medal = o.medaglia and i == 2
		local draw = medal and ui.medal or ui.star
		-- below, the unlit star on its shadow; above, the golden one lighting up with its halo
		draw(x + 4, y - 5, r * 2, KC.INK, f.radice)
		draw(x, y, r * 2, KC.LINE, f.radice)
		local s = { lato = r * 2 }
		if o.stelle[i] then
			n = n + 1
			f.prese[n] = s
			local glow = medal and vmath.vector4(0.55, 0.81, 0.94, 0) or vmath.vector4(1, 0.8, 0.25, 0)
			s.alone = ui.alone(x, y, r * 4.4, glow, f.radice)
			s.nodo = draw(x, y, r * 2, medal and ui.MEDAL or KC.STAR, f.radice)
			gui.set_scale(s.nodo, vec(0, 0))
		end
		local what = kit.text(g, criteria[i], x, 720 - y + r + 26, 12, o.stelle[i] and KC.SAND or KC.MUTE, "middle", 1)
		wide = kit.width(what)
		if wide > 124 then
			local sc = gui.get_scale(what)
			gui.set_scale(what, vec(sc.x * 124 / wide, sc.y * 124 / wide))
		end
	end
	local under = o.vantaggio and T.lead:format(o.vantaggio) or ""
	if o.record and o.record > n then
		local record = (o.record == 1 and T.record_one or T.record):format(o.record)
		under = under == "" and record or under .. "  -  " .. record
	end
	kit.text(g, kit.upper(under), 86, 400, 13, KC.MUTE, "start", 1.5)
	-- at the bottom left what else you can do, at the right the way on
	f.low = kit.anchor(0, 720, gui.ANCHOR_LEFT, gui.ANCHOR_BOTTOM)
	f.right = kit.anchor(1280, 720, gui.ANCHOR_RIGHT, gui.ANCHOR_BOTTOM)
	local again = kit.plate(f.low, 60, 612, 170, 52, KC.PURPLE, { sk = 14, d = 6 })
	kit.text(again.g, common.retry, 152, 646, 20, KC.SAND, "middle", 0.9)
	kit.button(f.buttons, again, "riprova")
	if o.avanti then
		local list = kit.plate(f.low, 250, 612, 190, 52, KC.PURPLE, { sk = 14, d = 6 })
		kit.text(list.g, common.campaign, 352, 646, 20, KC.SAND, "middle", 0.9)
		kit.button(f.buttons, list, "indietro")
	end
	local label = o.avanti and common.next or common.campaign
	local go = kit.action(f.right, label, 930, 560, 270, 84, { size = #label > 6 and 40 or 50 })
	kit.button(f.buttons, go, "avanti", { main = true })
	if o.gain then f.receipt = receipt.new(o.gain, o.prof, 170, f.buttons, f.radice) end
	return f
end

-- the stars taken light up one at a time: they grow past their size and come
-- back, the halo lights up and settles
function M.update(f, dt)
	f.t = f.t + dt
	scoria.update(f.figure, dt, f.st)
	if f.receipt then receipt.update(f.receipt, dt, f.sound and function(i) f.sound(1 + 0.08 * i) end, f.coin, f.xp) end
	local i = f.lit_ones + 1
	if i > #f.prese or f.t < M.FIRST + (i - 1) * M.RHYTHM then return end
	f.lit_ones = i
	local s = f.prese[i]
	gui.animate(s.nodo, "scale", vec(1, 1), gui.EASING_OUTBACK, M.SHOT)
	gui.animate(s.alone, "color.w", 0.7, gui.EASING_OUTQUAD, M.SHOT * 0.5, 0, function()
		gui.animate(s.alone, "color.w", 0.3, gui.EASING_INOUTQUAD, 0.5)
	end)
	if f.sound then f.sound(1 + 0.15 * (i - 1)) end
end

function M.on_input(f, action_id, action)
	local ui_action = ui.touch(f.buttons, action_id, action)
	-- a tap elsewhere while the receipt counts or the coins fly: everything at once
	if not ui_action and f.receipt and action.pressed and action_id == ui.TOUCH then receipt.skip(f.receipt) end
	return ui_action
end

function M.destroy(f)
	if f.receipt then receipt.delete(f.receipt) end
	gui.delete_node(f.radice)
	gui.delete_node(f.low.node)
	gui.delete_node(f.right.node)
	kit.scene_drop(f.scene)
end

return M
