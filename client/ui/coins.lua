-- The two coins drawn in code (Scaglie and Ossidiana, page "Scaglie e
-- Ossidiana", choices 1A and 12A): white layers of the ui atlas
-- (strumenti/grafica/monete.py) colored here, and the wallet pill at the top
-- right of the menus, with the coins flying into it (choice 10A, game-feel).
--
--   local coins = require "ui.coins"
--   coins.icon("scaglia" | "ossidiana", x, y, d, parent) -> node
--   local w = coins.wallet(scaglie, ossidiana, parent, x, y)  -- the pill (hidden until the first coin)
--   coins.set(w, scaglie, ossidiana)
--   coins.fly(w, kind, from, n, amount, on_arrive)  -- n coins from from (a vector3 in w's
--                                                    -- parent's space) carry amount into the pill;
--                                                    -- on_arrive(i) at each one (the sound)
--   coins.finish(w)                                  -- a tap: everything lands at once
--   coins.busy(w) -> true while coins are flying
--   coins.delete(w)
--   coins.format(n) -> "1.240"

local ui = require "ui.ui"

local M = {}

local function c(r, g, b, a) return vmath.vector4(r, g, b, a or 1) end

-- the layers of each coin, bottom to top, with their color
M.LAYERS = {
	scaglia = { { "sagoma", c(0.66, 0.45, 0.05) }, { "faccia", ui.C.GOLD }, { "luce", c(1, 0.95, 0.66) },
		{ "segno", c(0.66, 0.45, 0.05) } },
	ossidiana = { { "filo", ui.C.OBSIDIAN }, { "corpo", c(0.1, 0.07, 0.125) }, { "taglio_a", c(0.29, 0.2, 0.39) },
		{ "taglio_b", c(0.17, 0.12, 0.24) }, { "luce", c(1, 0.84, 0.95) } },
}
M.COLOR = { scaglia = ui.C.GOLD, ossidiana = ui.C.OBSIDIAN }

-- the wallet pill: as tall as the queue's, the two balances side by side
M.W, M.H = 250, 52
local ICON = 30
-- the flight: one coin every GAP seconds, each FLIGHT long
M.GAP, M.FLIGHT = 0.04, 0.45

local function vec(x, y) return vmath.vector3(x, y, 0) end

function M.icon(kind, x, y, d, parent)
	local root = gui.new_box_node(vec(x, y), vec(0, 0))
	gui.set_visible(root, false)
	if parent then gui.set_parent(root, parent) end
	local small = d <= 48 and "_p" or ""
	for _, l in ipairs(M.LAYERS[kind]) do
		ui.sagoma("moneta_" .. kind .. "_" .. l[1] .. small, 0, 0, d, d, l[2], root)
	end
	return root
end

-- 1240 -> "1.240"
function M.format(n)
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1."):reverse()
	return (out:gsub("^%.", ""))
end

function M.wallet(scaglie, ossidiana, parent, x, y)
	local w = { shown = { scaglie = scaglie, ossidiana = ossidiana }, real = { scaglie = scaglie, ossidiana = ossidiana },
		flights = {}, t = 0 }
	w.root = gui.new_box_node(vec(x, y), vec(0, 0))
	gui.set_visible(w.root, false)
	if parent then gui.set_parent(w.root, parent) end
	w.panel, w.border = ui.pannello(0, 0, M.W, M.H, w.root, "pillola")
	w.at = {}
	w.at.scaglia = vec(-M.W / 2 + 30, 0)
	w.at.ossidiana = vec(M.W / 2 - 100, 0)
	M.icon("scaglia", w.at.scaglia.x, 0, ICON, w.root)
	M.icon("ossidiana", w.at.ossidiana.x, 0, ICON, w.root)
	w.text = {}
	w.text.scaglia = ui.titolo("", w.at.scaglia.x + 24, 0, 0.6, ui.C.TEXT, w.root)
	w.text.ossidiana = ui.titolo("", w.at.ossidiana.x + 24, 0, 0.6, ui.C.TEXT, w.root)
	for _, n in pairs(w.text) do gui.set_pivot(n, gui.PIVOT_W) end
	M.set(w, scaglie, ossidiana)
	return w
end

local function draw(w)
	gui.set_text(w.text.scaglia, M.format(w.shown.scaglie))
	gui.set_text(w.text.ossidiana, M.format(w.shown.ossidiana))
	-- the pill appears with the first coin earned (it is also the way to the shop)
	gui.set_enabled(w.root, w.real.scaglie > 0 or w.real.ossidiana > 0)
end

function M.set(w, scaglie, ossidiana)
	w.real.scaglie, w.real.ossidiana = scaglie, ossidiana
	w.shown.scaglie, w.shown.ossidiana = scaglie, ossidiana
	draw(w)
end

-- the pill swells and its border lights up in the coin's color
local function bump(w, kind)
	gui.cancel_animations(w.root, "scale")
	gui.set_scale(w.root, vmath.vector3(1.06, 1.06, 1))
	gui.animate(w.root, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTQUAD, 0.16)
	gui.cancel_animations(w.border, "color")
	gui.set_color(w.border, M.COLOR[kind == "scaglie" and "scaglia" or "ossidiana"])
	gui.animate(w.border, "color", ui.C.LINE, gui.EASING_INQUAD, 0.5)
end

local function land(w, f, i)
	if f.landed[i] then return end
	f.landed[i] = true
	local part = math.floor(f.amount * i / f.n) - math.floor(f.amount * (i - 1) / f.n)
	w.shown[f.field] = w.shown[f.field] + part
	if f.nodes[i] then gui.delete_node(f.nodes[i]); f.nodes[i] = nil end
	draw(w)
	bump(w, f.field)
	if f.on_arrive then f.on_arrive(i) end
end

-- kind: "scaglia" or "ossidiana"; from: where they start, in the pill's
-- parent's coordinates (the pill sits at its root's position there)
function M.fly(w, kind, from, n, amount, on_arrive)
	local field = kind == "scaglia" and "scaglie" or "ossidiana"
	w.real[field] = w.real[field] + amount
	local f = { field = field, n = n, amount = amount, nodes = {}, landed = {}, on_arrive = on_arrive, t = 0 }
	local pos = gui.get_position(w.root)
	local to = pos + w.at[kind]
	local slow = kind == "ossidiana" and 1.6 or 1
	for i = 1, n do
		local node = M.icon(kind, from.x, from.y, kind == "ossidiana" and 44 or 26, gui.get_parent(w.root))
		gui.set_scale(node, vmath.vector3(0.01, 0.01, 1))
		local delay = (i - 1) * M.GAP
		-- a pop where it is born, then an arc: x eases out and y eases in
		gui.animate(node, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, 0.12, delay)
		gui.animate(node, "position.x", to.x, gui.EASING_OUTQUAD, M.FLIGHT * slow, delay + 0.08)
		gui.animate(node, "position.y", to.y, gui.EASING_INQUAD, M.FLIGHT * slow, delay + 0.08, function()
			land(w, f, i)
		end)
		f.nodes[i] = node
	end
	w.flights[#w.flights + 1] = f
	gui.set_enabled(w.root, true)
end

-- everything lands at once (a tap, or the screen closing)
function M.finish(w)
	for _, f in ipairs(w.flights) do
		for i = 1, f.n do
			if not f.landed[i] then
				f.landed[i] = true
				if f.nodes[i] then gui.delete_node(f.nodes[i]); f.nodes[i] = nil end
			end
		end
	end
	w.flights = {}
	w.shown.scaglie, w.shown.ossidiana = w.real.scaglie, w.real.ossidiana
	draw(w)
end

function M.busy(w)
	for _, f in ipairs(w.flights) do
		for i = 1, f.n do
			if not f.landed[i] then return true end
		end
	end
	return false
end

function M.delete(w)
	M.finish(w)
	gui.delete_node(w.root)
end

return M
