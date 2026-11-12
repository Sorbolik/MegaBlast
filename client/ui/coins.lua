-- The two coins drawn in code (Scaglie and Ossidiana, page "Scaglie e
-- Ossidiana", choices 1A and 12A): white layers of the ui atlas
-- (tools/grafica/monete.py) colored here, and the wallet pill at the top
-- right of the menus, with the coins flying into it (choice 10A, game-feel).
--
--   local coins = require "ui.coins"
--   coins.icon("scaglia" | "ossidiana", x, y, d, parent) -> node
--   local w = coins.wallet(scaglie, ossidiana, parent, x, y)  -- the pill (hidden until the first coin);
--   coins.set(w, scaglie, ossidiana)
--   coins.fly(w, kind, from, n, amount, on_arrive)  -- n coins from from (a vector3 in w's
--                                                    -- parent's space) carry amount into the pill;
--                                                    -- on_arrive(i) at each one (the sound)
--   coins.finish(w)                                  -- a tap: everything lands at once
--   coins.busy(w) -> true while coins are flying
--   coins.delete(w)
--   coins.format(n) -> "1.240"

local ui = require "ui.ui"
local kit = require "ui.kit"

local M = {}

local function c(r, g, b, a) return vmath.vector4(r, g, b, a or 1) end

M.COLOR = { scaglia = ui.C.GOLD, ossidiana = ui.C.OBSIDIAN }

-- the wallet pill: as tall as the queue's, the two balances side by side
-- the flight: one coin every GAP seconds, each FLIGHT long
M.GAP, M.FLIGHT = 0.04, 0.45

local function vec(x, y) return vmath.vector3(x, y, 0) end

function M.icon(kind, x, y, d, parent)
	local root = gui.new_box_node(vec(x, y), vec(0, 0))
	gui.set_visible(root, false)
	if parent then gui.set_parent(root, parent) end
	-- the pieces of the fucina atlas (the flake of gold, the gem), a bit taller
	-- than the old flat coin to weigh the same
	kit.piece({ node = root, ox = 0, oy = 0 }, kind == "scaglia" and "scaglia" or "gemma", 0, 0, d * 1.12)
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
	w.at = {}
	w.text = {}
	-- the wallet (ui/kit.lua): one dark strip to read, no
	-- frame and no shadow (it is not two buttons), a thin cut between the balances
	-- two small iron plates (ui/kit.lua), each balance in its room, its coin
	-- sticking out of the left end
	local g = { node = w.root, ox = 1110, oy = 44 }
	w.border = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_visible(w.border, false)
	gui.set_parent(w.border, w.root)
	w.room = {}
	for _, o in ipairs({ { "scaglia", 962, 112 }, { "ossidiana", 1084, 88 } }) do
		local kind, x, wide = o[1], o[2], o[3]
		local p = kit.plate(g, x, 25, wide, 38, kit.C.ROSE, { sk = 0 })
		w.at[kind] = vec(x + 12 - g.ox, 0)
		M.icon(kind, x + 12 - g.ox, 0, 30, w.root)
		local box = { x0 = x + 31, x1 = p.box.x1, y0 = p.box.y0, y1 = p.box.y1 }
		w.room[kind] = box.x1 - box.x0
		w.text[kind] = kit.text({ node = p.g.node, ox = p.g.ox, oy = p.g.oy, box = box }, "", x + 31, 51, 17, kit.C.SAND)
		w.scale = gui.get_scale(w.text[kind])
	end
	M.set(w, scaglie, ossidiana)
	return w
end

local function draw(w)
	gui.set_text(w.text.scaglia, M.format(w.shown.scaglie))
	gui.set_text(w.text.ossidiana, M.format(w.shown.ossidiana))
	-- a long balance shrinks: never past its plate
	for kind, n in pairs(w.text) do
		gui.set_scale(n, w.scale)
		local wide = kit.width(n)
		if wide > w.room[kind] then gui.set_scale(n, w.scale * (w.room[kind] / wide)) end
	end
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
