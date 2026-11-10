-- End of a level: a campaign mission or a lesson (sim/missions.lua). One
-- screen, no popups: the level's name, the stars taken lighting up one after
-- the other (with the tick rising in pitch, like the points in a match) and
-- under each one what it takes to get it, so you see how to do better. Below:
-- RIPROVA and AVANTI (the next level, or the list if it was the last); the
-- arrow goes back to the list.
--
--   local level_end = require "menu.level_end"
--   local f = level_end.new({ titolo = "Il Rampino", stelle = { true, true, false },
--     criteria = { "FATTA", "CON 100 PUNTI DI VANTAGGIO", "SENZA MORIRE" }, vantaggio = 85, record = 3, avanti = true }, sound)
--     stelle: which ones it took (each with its criterion); criteria: what each
--     one takes (missions.criteria); vantaggio: the lead points made (nil where
--     points don't count: the lessons); record: how many stars the mission
--     already had; medaglia: the second is Favilla's medal (the cortile);
--     avanti: there is a next level; sound(v): the tick, v = speed (pitch);
--     gain: profile.missione's experience (the receipt on the right, ui/receipt.lua), prof: the profile
--   fine_livello.update(f, dt)
--   fine_livello.on_input(f, action_id, action) -> "riprova", "avanti", "indietro", "sigilli" or nil
--   fine_livello.destroy(f)

local ui = require "ui.ui"
local backdrop = require "ui.backdrop"
local receipt = require "ui.receipt"
local T = require("lang.text").level_end
local common = require("lang.text").common

local M = {}

-- the stars: side, distance between centers, the middle one bigger and higher
M.LATO, M.STEP, M.Y = 116, 190, 400
-- when each star lights up (seconds from opening) and how long the pop lasts
M.RHYTHM, M.FIRST, M.SHOT = 0.3, 0.25, 0.18

local function vec(x, y) return vmath.vector3(x, y, 0) end

function M.new(o, sound)
	local f = { buttons = {}, t = 0, sound = sound, lit_ones = 0, prese = {} }
	local n = 0
	f.fondo = backdrop.new("legno")
	f.radice = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_visible(f.radice, false)
	local c = ui.C
	ui.back(f.buttons, "indietro", f.radice)
	-- with the receipt on the right, the stars move to the left
	local cx = o.gain and 440 or 640
	ui.text(o.fallita and T.failed or T.done, cx, 640, 0.8, c.OFF, f.radice)
	ui.title(string.upper(o.titolo), cx, 585, 1, c.LIGHT, f.radice)
	local criteria = o.criteria
	-- three stars; in the cortile «Fatta» and Favilla's medal, or «Fatta» alone
	local count = #criteria
	for i = 1, count do
		local big = count == 3 and i == 2 and 1.2 or 1
		local x, y = cx + (i - (count + 1) / 2) * M.STEP, M.Y + (big > 1 and 18 or 0)
		local side_of = M.LATO * big
		local medal = o.medaglia and i == 2
		local draw = medal and ui.medal or ui.star
		-- below, the unlit star; above, the golden one lighting up with its halo
		draw(x, y, side_of, c.LINE, f.radice)
		local s = { lato = side_of }
		if o.stelle[i] then
			n = n + 1
			f.prese[n] = s
			local glow = medal and vmath.vector4(0.55, 0.81, 0.94, 0) or vmath.vector4(1, 0.8, 0.25, 0)
			s.alone = ui.alone(x, y, side_of * 2.2, glow, f.radice)
			s.nodo = draw(x, y, side_of, medal and ui.MEDAL or ui.GOLD, f.radice)
			gui.set_scale(s.nodo, vec(0, 0))
		end
		ui.text(criteria[i], x, M.Y - 100, 0.75, o.stelle[i] and c.TEXT or c.OFF, f.radice)
	end
	local under = o.vantaggio and T.lead:format(o.vantaggio) or ""
	if o.record and o.record > n then
		local record = (o.record == 1 and T.record_one or T.record):format(o.record)
		under = under == "" and record or under .. "  -  " .. record
	end
	ui.text(under, cx, 232, 0.8, c.OFF, f.radice)
	local bw = o.gain and 260 or 300
	ui.button(f.buttons, cx - bw / 2 - 20, 110, bw, 96, common.retry, "riprova", nil, f.radice)
	ui.button(f.buttons, cx + bw / 2 + 20, 110, bw, 96, o.avanti and common.next or common.campaign, "avanti",
		{ main = true }, f.radice)
	if o.gain then f.receipt = receipt.new(o.gain, o.prof, 1040, 676, f.buttons, f.radice) end
	return f
end

-- the stars taken light up one at a time: they grow past their size and come
-- back, the halo lights up and settles
function M.update(f, dt)
	f.t = f.t + dt
	if f.receipt then receipt.update(f.receipt, dt, f.sound and function(i) f.sound(1 + 0.08 * i) end) end
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
	return ui.touch(f.buttons, action_id, action)
end

function M.destroy(f)
	gui.delete_node(f.radice)
	gui.delete_node(f.fondo)
end

return M
