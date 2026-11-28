-- The Limbo as a board game (Sergio, 28 Nov 2026, WB-101): the chapter of the
-- Limbo is not a grid of cards but its own slice (WB-026) seen big, with the
-- places of Dante's Limbo drawn by Codex on it, one for each level, joined by a
-- path of flat stones. The apprentice and the Smith are two board-game pawns
-- (figurines on a round base, never animated as characters): touching an open
-- place they go there on foot, stone by stone, with small wobbly hops, the
-- Smith one step behind. Touching the place where they stand plays its level.
-- A place opens when the level before it is won; a place whose level is still
-- to be written opens as IN ARRIVO and stops the way. The shortcuts of the
-- plan (secret door, ford, the Smith's shop) wait for Sergio's choices: the
-- shop is drawn, with no road to it yet.
--
--   local board = require "menu.limbo_board"
--   board.build(c, cap)          -- in the campaign's screen c (menu/campaign.lua)
--   board.touch(c, key)          -- a place touched: { missione = id, da } to play, or nil

local kit = require "ui.kit"
local screen = require "ui.screen"
local missions = require "sim.missions"
local PIECES = require "menu.board_pieces"
local T = require("lang.text").campaign

local M = {}

local KC = kit.C

-- the slice on the screen: its picture is 1340 x 410, shown SW wide with its top at Y0
local PIC_W = 1340
local SW, Y0 = 1160, 168
local K = SW / PIC_W
local X0 = 640 - SW / 2
-- a point of the slice's picture on the screen (Figma)
local function at(px, py) return X0 + px * K, Y0 + py * K end

-- how far apart the stones are, and how far from a place the path stops (screen pixels)
local GAP, PAD = 23, 28
-- one hop: its time, how high it goes (screen pixels), how much it leans
local HOP, LIFT, LEAN = 0.19, 11, 10
-- the Smith starts this many hops after the apprentice, and stands behind him
local FOLLOW = 1.6
local ME_OFF, SMITH_OFF = { 7, 2 }, { -18, -3 }

-- the places along the path, in the slice's picture pixels: where the pawns stand
-- (spot) and the drawing (art, its bottom middle at base, w wide on the screen,
-- the atlas piece lit once the level is won)
local PLACES = {
	{ key = "porta", spot = { 326, 230 }, art = "limbo_porta", base = { 280, 211 }, w = 84 },
	{ key = "leva", spot = { 168, 186 }, lever = { 86, 157 } },
	{ key = "muri", spot = { 397, 122 }, art = "limbo_castello", lit = "limbo_castello_acceso", base = { 397, 108 }, w = 200 },
	{ key = "ruscello", spot = { 774, 98 }, art = "limbo_ponte", base = { 774, 106 }, w = 86 },
	{ key = "spiriti", spot = { 1034, 120 }, art = "limbo_prato", base = { 1034, 122 }, w = 196 },
	{ key = "caronte", spot = { 1168, 202 }, art = "limbo_pontile", base = { 1236, 262 }, w = 190 },
	{ key = "scendi", spot = { 866, 250 }, art = "limbo_crepa", base = { 866, 384 }, w = 30 },
}
-- the Smith's shop, beside the castle: no road to it until the plan's shortcuts are chosen
local SHOP = { art = "limbo_bottega", base = { 606, 140 }, w = 70 }
-- the middle of the top face: the roads bend away from it, as if along the ring
local MID = { 670, 154 }

local function image(g, name, x, y, w, pivot)
	local m = PIECES[name]
	local h = w * m.h / m.w
	local n = gui.new_box_node(vmath.vector3(x - g.ox, g.oy - y, 0), vmath.vector3(w, h, 0))
	gui.set_texture(n, "tabellone")
	gui.play_flipbook(n, name)
	gui.set_pivot(n, pivot or gui.PIVOT_S)
	gui.set_parent(n, g.node)
	return n
end

-- the level of each place: the chapter's missions in order (the places after
-- the last one written have none)
local function levels(cap)
	local out = {}
	for i, p in ipairs(PLACES) do out[p.key] = cap.missioni[i] end
	return out
end

local function won(c, l) return l and (c.stelle[l.id] or {})[1] ~= nil end

-- open: the first, and every one after a won level
local function opened(c, lv, i)
	if i == 1 then return true end
	return won(c, lv[PLACES[i - 1].key])
end

local function index_of(key)
	for i, p in ipairs(PLACES) do if p.key == key then return i end end
end

-- the road from place i to place i + 1: a gentle curve away from the middle,
-- as stones GAP apart (screen points)
local function road(i)
	local a, b = PLACES[i].spot, PLACES[i + 1].spot
	local ax, ay = at(a[1], a[2])
	local bx, by = at(b[1], b[2])
	local mx, my = (ax + bx) / 2, (ay + by) / 2
	local cx, cy = at(MID[1], MID[2])
	local ox, oy = mx - cx, (my - cy) * 5.8
	local d = math.max(1, math.sqrt(ox * ox + oy * oy))
	local qx, qy = mx + ox / d * 46, my + oy / d * 16
	local function f(t)
		local u = 1 - t
		return u * u * ax + 2 * u * t * qx + t * t * bx, u * u * ay + 2 * u * t * qy + t * t * by
	end
	local N, pts, acc, len = 80, {}, { 0 }, 0
	local px, py = f(0)
	pts[1] = { px, py }
	for k = 1, N do
		local x, y = f(k / N)
		len = len + math.sqrt((x - px) * (x - px) + (y - py) * (y - py))
		pts[k + 1], acc[k + 1], px, py = { x, y }, len, x, y
	end
	local n = math.max(1, math.floor((len - 2 * PAD) / GAP + 0.5))
	local out, j = {}, 2
	for k = 0, n do
		local s = PAD + (len - 2 * PAD) * k / n
		while j < #acc and acc[j] < s do j = j + 1 end
		local u = (s - acc[j - 1]) / math.max(1e-6, acc[j] - acc[j - 1])
		out[#out + 1] = { pts[j - 1][1] + (pts[j][1] - pts[j - 1][1]) * u, pts[j - 1][2] + (pts[j][2] - pts[j - 1][2]) * u }
	end
	return out
end

-- ---------------------------------------------------------------- the pawns

local function pawn(g, name, w, x, y)
	local root = gui.new_box_node(vmath.vector3(x - g.ox, g.oy - y, 0), vmath.vector3(0, 0, 0))
	gui.set_color(root, vmath.vector4(1, 1, 1, 0))
	gui.set_inherit_alpha(root, false)
	gui.set_parent(root, g.node)
	local body = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(0, 0, 0))
	gui.set_color(body, vmath.vector4(1, 1, 1, 0))
	gui.set_inherit_alpha(body, false)
	gui.set_parent(body, root)
	local m = PIECES[name]
	local pic = gui.new_box_node(vmath.vector3(0, -4, 0), vmath.vector3(w, w * m.h / m.w, 0))
	gui.set_texture(pic, "tabellone")
	gui.play_flipbook(pic, name)
	gui.set_pivot(pic, gui.PIVOT_S)
	gui.set_inherit_alpha(pic, false)
	gui.set_parent(pic, body)
	return { root = root, body = body, pic = pic, x = x, y = y, g = g }
end

local function face(p, dx)
	if math.abs(dx) < 0.5 then return end
	local s = gui.get_scale(p.pic)
	gui.set_scale(p.pic, vmath.vector3(dx < 0 and -math.abs(s.x) or math.abs(s.x), s.y, 1))
end

-- one hop to (x, y): the pawn goes up and comes down leaning to one side, and
-- squashes a little on landing
local function hop(p, x, y, time, lift, side, done)
	face(p, x - p.x)
	p.x, p.y = x, y
	gui.animate(p.root, "position", vmath.vector3(x - p.g.ox, p.g.oy - y, 0), gui.EASING_INOUTSINE, time, 0, function()
		gui.set_scale(p.body, vmath.vector3(1.12, 0.86, 1))
		gui.animate(p.body, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, 0.2)
		done()
	end)
	gui.animate(p.body, "position.y", lift, gui.EASING_OUTSINE, time / 2, 0, function()
		gui.animate(p.body, "position.y", 0, gui.EASING_INSINE, time / 2)
	end)
	gui.animate(p.body, "euler.z", side * LEAN, gui.EASING_OUTSINE, time / 2, 0, function()
		gui.animate(p.body, "euler.z", 0, gui.EASING_INSINE, time / 2)
	end)
end

local function walk(p, pts, off, delay, done)
	local i = 0
	local function step()
		i = i + 1
		if i > #pts then return done() end
		local last = i == #pts
		local x, y = pts[i][1] + (last and off[1] or 0), pts[i][2] + (last and off[2] or 0)
		hop(p, x, y, last and HOP * 1.5 or HOP, last and LIFT * 1.7 or LIFT, i % 2 == 0 and 1 or -1, step)
	end
	if delay > 0 then
		gui.animate(p.body, "color.w", 0, gui.EASING_LINEAR, delay, 0, step)
	else
		step()
	end
end

-- a no: the apprentice shakes on the spot
local function nope(p)
	local n = 0
	local function swing()
		n = n + 1
		if n > 4 then return gui.animate(p.body, "euler.z", 0, gui.EASING_OUTSINE, 0.08) end
		gui.animate(p.body, "euler.z", (n % 2 == 0 and -1 or 1) * 10 * (1 - n / 6), gui.EASING_INOUTSINE, 0.08, 0, swing)
	end
	swing()
end

-- ---------------------------------------------------------------- the board

function M.build(c, cap)
	-- everything on one node: on a narrow screen (4:3) the board shrinks to stay whole
	local fit = math.min(1, (screen.width() - 40) / (SW + 40))
	local mid = Y0 + 205 * K
	local holder = gui.new_box_node(vmath.vector3(640 - c.kg.ox, c.kg.oy - mid, 0), vmath.vector3(0, 0, 0))
	-- (size 0: nothing of its own is drawn, its children are)
	gui.set_scale(holder, vmath.vector3(fit, fit, 1))
	gui.set_parent(holder, c.kg.node)
	local g = { node = holder, ox = 640, oy = mid }
	local lv = levels(cap)
	c.board = { cap = cap, lv = lv, locks = {} }
	-- the slice, seen big
	local sl = gui.new_box_node(vmath.vector3(640 - g.ox, g.oy - (Y0 + 205 * K), 0), vmath.vector3(SW, 410 * K, 0))
	gui.set_texture(sl, "fette")
	gui.play_flipbook(sl, "fetta_limbo")
	gui.set_parent(sl, g.node)
	-- the roads: lit as far as the places open
	for i = 1, #PLACES - 1 do
		local open = opened(c, lv, i + 1)
		for _, s in ipairs(road(i)) do
			local n = image(g, "pietra", s[1], s[2] + 4, 20)
			if not open then gui.set_color(n, vmath.vector4(1, 1, 1, 0.22)) end
		end
	end
	-- the places, from the back of the slice to the front (the nearer ones cover the farther)
	local order = {}
	for i, p in ipairs(PLACES) do order[i] = p end
	table.sort(order, function(a, b)
		local ay, by = (a.base or a.lever)[2], (b.base or b.lever)[2]
		if ay ~= by then return ay < by end
		return a.key < b.key
	end)
	local function shop()
		local x, y = at(SHOP.base[1], SHOP.base[2])
		gui.set_color(image(g, SHOP.art, x, y, SHOP.w), vmath.vector4(0.6, 0.6, 0.62, 1))
	end
	local shop_done = false
	for _, p in ipairs(order) do
		if not shop_done and (p.base or p.lever)[2] > SHOP.base[2] then shop(); shop_done = true end
		local i = index_of(p.key)
		local open = opened(c, lv, i)
		local dim = open and vmath.vector4(1, 1, 1, 1) or vmath.vector4(0.55, 0.55, 0.6, 1)
		if p.lever then
			-- the lever of WB-099, on its steel stud: pulled down once its level is won
			local x, y = at(p.lever[1], p.lever[2])
			local plate = gui.new_box_node(vmath.vector3(x - g.ox, g.oy - y, 0), vmath.vector3(30, 30, 0))
			gui.set_texture(plate, "battaglia")
			gui.play_flipbook(plate, "leva_piastra")
			gui.set_parent(plate, g.node)
			gui.set_color(plate, dim)
			local handle = gui.new_box_node(vmath.vector3(x - 4 - g.ox, g.oy - y, 0), vmath.vector3(45, 11, 0))
			gui.set_texture(handle, "battaglia")
			gui.play_flipbook(handle, "leva_manico")
			gui.set_pivot(handle, gui.PIVOT_W)
			gui.set_euler(handle, vmath.vector3(0, 0, won(c, lv[p.key]) and -35 or 35))
			gui.set_parent(handle, g.node)
			gui.set_color(handle, dim)
		else
			local x, y = at(p.base[1], p.base[2])
			local art = p.lit and won(c, lv[p.key]) and p.lit or p.art
			gui.set_color(image(g, art, x, y, p.w), dim)
		end
	end
	if not shop_done then shop() end
	-- the labels, the padlocks, the touch zones
	for i, p in ipairs(PLACES) do
		local x, y = at(p.spot[1], p.spot[2])
		local open = opened(c, lv, i)
		local l = lv[p.key]
		-- the levels numbered, the keeper and the way down by name
		local label = i <= 5 and T.board_place:format(i, T.board[p.key]) or T.board[p.key]
		kit.text(g, label, x, y + 24, 16, open and KC.SAND or KC.MUTE, "middle", 1)
		if l and open then
			-- the ember of the level: lit when won
			kit.piece(g, won(c, l) and "brace" or "brace_spenta", x + 26, y - 2, 18)
		end
		if not open then
			c.board.locks[p.key] = kit.piece(g, "lucchetto", x + 24, y - 30, 24)
		end
		kit.zone(g, c.buttons, x - 44, y - 64, 88, 92, "luogo:" .. p.key)
	end
	-- where the pawns stand: the place chosen last, or the level to play now
	local here = c.scelta.tavola
	if not (here and index_of(here) and opened(c, lv, index_of(here))) then
		here = PLACES[1].key
		for i, p in ipairs(PLACES) do
			if opened(c, lv, i) then here = p.key end
			if lv[p.key] and not won(c, lv[p.key]) then break end
			if not lv[p.key] then break end
		end
	end
	c.scelta.tavola = here
	local hx, hy = at(PLACES[index_of(here)].spot[1], PLACES[index_of(here)].spot[2])
	c.board.smith = pawn(g, "pedina_fabbro", 36, hx + SMITH_OFF[1], hy + SMITH_OFF[2])
	c.board.me = pawn(g, "pedina_apprendista", 31, hx + ME_OFF[1], hy + ME_OFF[2])
	face(c.board.smith, 1)
	-- what is here, at the bottom left over the thread, and GIOCA plays it
	g = c.kg
	local l = lv[here]
	local name = l and kit.upper(l.titolo) or T.board[here]
	kit.text(g, name, 60, 568, 24, KC.SAND, "start", 1)
	local sub
	if l then
		local count = #missions.criteria(l)
		sub = ("%s · %d / %d"):format(kit.upper(T.board[here]), missions.count(c.stelle[l.id] or {}), count)
	else
		sub = T.board_coming
	end
	kit.text(g, sub, 60, 596, 16, l and KC.MUTE or KC.ICE, "start", 1)
	c.play = l and l.id or nil
	c.from = c.from or {}
	if l then c.from[l.id] = { x = 640 + (hx - 640) * fit, y = 720 - (mid + (hy - mid) * fit) + gui.get_position(c.radice).y, w = 120, h = 68 } end
	return { id = c.play, sub = l and kit.upper(l.titolo) or T.board_coming, off = not l }
end

-- a place touched: walk there, play it, or say no
function M.touch(c, key)
	local b = c.board
	if not b or b.walking then return nil end
	local i, from = index_of(key), index_of(c.scelta.tavola)
	if not i then return nil end
	if not opened(c, b.lv, i) then
		nope(b.me)
		local lock = b.locks[key]
		if lock then
			gui.animate(lock, "euler.z", 16, gui.EASING_INOUTSINE, 0.1, 0, function()
				gui.animate(lock, "euler.z", 0, gui.EASING_OUTELASTIC, 0.4)
			end)
		end
		return nil
	end
	if i == from then
		local l = b.lv[key]
		if l then return { missione = l.id, da = c.from[l.id] } end
		nope(b.me)
		return nil
	end
	-- the stones from here to there, then the place itself
	local pts = {}
	local dir = i > from and 1 or -1
	for k = from, i - dir, dir do
		local r = road(math.min(k, k + dir))
		if dir < 0 then
			local rev = {}
			for j = #r, 1, -1 do rev[#rev + 1] = r[j] end
			r = rev
		end
		for _, s in ipairs(r) do pts[#pts + 1] = s end
		local x, y = at(PLACES[k + dir].spot[1], PLACES[k + dir].spot[2])
		pts[#pts + 1] = { x, y }
	end
	b.walking = true
	local left = 2
	local function arrived()
		left = left - 1
		if left > 0 then return end
		b.walking = false
		c.scelta.tavola = key
		c.rebuild(c)
	end
	walk(b.me, pts, ME_OFF, 0, arrived)
	walk(b.smith, pts, SMITH_OFF, HOP * FOLLOW, arrived)
	return nil
end

return M
