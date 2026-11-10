-- The kinds of level (Sergio, 6 Nov): each mission of sim/levels.lua says
-- what it is (tipo) and the CAMPAGNA shows it, instead of a painting, as a
-- small label in the kind's pastel colour with its icon and name in dark ink,
-- on the card's miniature (menu/campaign.lua) and on the postcard before the
-- mission (ui/postcard.lua). The eight kinds are the hell's types of the
-- campaign plan: corsa, bersagli, duello, squadra, orda, resistenza, bottino,
-- custode. The icons are white shapes of the ui atlas (tipo_<kind>, made by
-- strumenti/grafica/icone_tipi.py), inked by the code. Only shown: the rules
-- never read the kind.
--
--   local types = require "ui.level_types"
--   local n = types.label(tipo, x, y, size, parent)   -- the label, its left end at x (nil without a kind)
--   types.color(tipo)                                 -- the kind's colour (the frame of its picture)
--   types.line(tipo)                                  -- the line that says what the kind is
--   types.first_time(id, stars)                       -- no other mission of its kind done yet

local ui = require "ui.ui"
local payload = require "sim.campaign"
local T = require("lang.text").level_types

local M = {}

local function hex(s)
	return vmath.vector4(tonumber(s:sub(1, 2), 16) / 255, tonumber(s:sub(3, 4), 16) / 255, tonumber(s:sub(5, 6), 16) / 255, 1)
end

-- the pastels of the hell's table (Sergio: «mi piacevano quelli»); BOTTINO
-- silver, the yellow of raccolta was too close to BERSAGLI's
M.KINDS = {
	corsa = { color = hex("8FE3B0"), name = T.corsa, line = T.corsa_line },
	bersagli = { color = hex("F2D36B"), name = T.bersagli, line = T.bersagli_line },
	duello = { color = hex("FFB27A"), name = T.duello, line = T.duello_line },
	squadra = { color = hex("C8A8FF"), name = T.squadra, line = T.squadra_line },
	orda = { color = hex("FF8F8F"), name = T.orda, line = T.orda_line },
	resistenza = { color = hex("9FE6E0"), name = T.resistenza, line = T.resistenza_line },
	bottino = { color = hex("E6E6E6"), name = T.bottino, line = T.bottino_line },
	custode = { color = hex("FF5A3C"), name = T.custode, line = T.custode_line },
}
M.INK = hex("24140B")
local SHADOW = vmath.vector4(0, 0, 0, 0.35)

function M.color(tipo)
	local k = M.KINDS[tipo]
	return k and k.color
end

function M.line(tipo)
	local k = M.KINDS[tipo]
	return k and k.line
end

-- the label: a rounded box of the kind's colour with its shadow, the icon and
-- the name. size is its height (24 on the cards, 48 on the postcard): drawn at
-- 48 and scaled, so the rounded corners shrink with it (the 9-slice keeps
-- them at their pixels). The left end at x, the middle at y. Returns the
-- label's node (its width: gui.get_size(n).x * size / 48)
local H = 48
function M.label(tipo, x, y, size, parent)
	local k = M.KINDS[tipo]
	if not k then return nil end
	local n = gui.new_box_node(vmath.vector3(x, y, 0), vmath.vector3(0, 0, 0))
	gui.set_color(n, vmath.vector4(1, 1, 1, 0))
	gui.set_adjust_mode(n, gui.ADJUST_FIT)
	gui.set_scale(n, vmath.vector3(size / H, size / H, 1))
	if parent then gui.set_parent(n, parent) end
	local t = ui.text(k.name, 0, 0, 1, M.INK)
	gui.set_outline(t, vmath.vector4(0, 0, 0, 0))
	gui.set_shadow(t, vmath.vector4(0, 0, 0, 0))
	local tw = resource.get_text_metrics(gui.get_font_resource(gui.get_font(t)), k.name).width * gui.get_scale(t).x
	local icon = 36
	local w = 10 + icon + 10 + tw + 16
	gui.set_size(n, vmath.vector3(w, H, 0))
	ui.sagoma("forma", w / 2 + 4, -4, w, H, SHADOW, n)
	local box = ui.sagoma("forma", w / 2, 0, w, H, k.color, n)
	ui.sagoma(icon * size / H <= 40 and "tipo_" .. tipo .. "_p" or "tipo_" .. tipo, -w / 2 + 10 + icon / 2, 0, icon, icon, M.INK, box)
	gui.set_parent(t, box)
	gui.set_pivot(t, gui.PIVOT_W)
	gui.set_position(t, vmath.vector3(-w / 2 + 20 + icon, -2, 0))
	return n
end

-- the first mission of its kind you meet: none of the others of the same kind
-- has «Fatta» yet
function M.first_time(id, stars)
	local tipo
	for _, cap in ipairs(payload.CAPITOLI) do
		for _, l in ipairs(cap.missioni) do
			if l.id == id then tipo = l.tipo end
		end
	end
	if not tipo then return false end
	for _, cap in ipairs(payload.CAPITOLI) do
		for _, l in ipairs(cap.missioni) do
			if l.tipo == tipo and l.id ~= id and ((stars or {})[l.id] or {})[1] then return false end
		end
	end
	return true
end

return M
