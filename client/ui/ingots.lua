-- The three ingots of a piece (Sergio, 18 Nov, proposal C of the page "Proposte
-- zaino e scatto"): its thirty levels as three ingots of ten notches, the gem of
-- each signature grade at the end of the ingot that opens it. Used by the piece's
-- card (menu/bench.lua), the ZAINO's band and the step's scene (ui/step_scene.lua).
--
--   local ingots = require "ui.ingots"
--   local notches, gems, frames = ingots.draw(g, x, y, w, h, level, lit)

local ui = require "ui.ui"
local kit = require "ui.kit"
local equip = require "sim.gear"

local KC = kit.C
local M = {}

-- The three ingots of a piece (Sergio, 18 Nov, proposal C): the thirty levels as
-- three ingots of ten notches, w wide from (x, y), h tall. The notches reached in
-- the color of the piece's grade, the next one to buy in ember; a full ingot glows
-- with the color of the grade it opened, and at its end the gem of the signature
-- grade that step lets you light (lit: bright; not yet: dark). Returns the thirty
-- notches and the three gems
function M.draw(g, x, y, w, h, level, lit)
	local gap = h >= 24 and 10 or 5
	local iw = (w - 2 * gap) / 3
	local sk = math.max(2, math.floor(h * 0.16))
	local pad = h >= 24 and 5 or 3
	local gem_h = h - 2 * pad + 4
	local tier = equip.tier(level)
	local notches, gems, frames = {}, {}, {}
	for k = 1, 3 do
		local ix = x + (k - 1) * (iw + gap)
		local full = level >= k * 10
		kit.para(g, ix, y, iw, h, sk, KC.INK)
		frames[k] = kit.para(g, ix + 3, y + 3, iw - 6, h - 6, sk, full and kit.with_alpha(ui.C.GRADI[k + 1], 0.3) or KC.CARD_BOTTOM)
		-- ten notches, then room for the gem
		local room = iw - 2 * pad - gem_h - 2
		local pitch = room / 10
		local nw = math.max(2, pitch * 0.66)
		local nh = h - 2 * pad - 2
		for i = 1, 10 do
			local n = (k - 1) * 10 + i
			local color = n <= level and ui.C.GRADI[tier] or (n == level + 1 and KC.HOT_BOTTOM or KC.LINE)
			notches[n] = kit.para(g, ix + pad + sk / 2 + (i - 1) * pitch, y + pad + 1, nw, nh, math.max(1, math.floor(sk * 0.6)), color)
		end
		local gem = kit.piece(g, "gemma", ix + iw - pad - gem_h / 2, y + h / 2, gem_h)
		if k > (lit or 0) then gui.set_color(gem, vmath.vector4(0.3, 0.3, 0.36, full and 0.85 or 0.6)) end
		gems[k] = gem
	end
	return notches, gems, frames
end

return M
