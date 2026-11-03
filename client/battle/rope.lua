-- The Grapple's rope as drawn: a steel wire in pieces with the hook at the
-- tip (strumenti/grafica/armi.py). It flies straight from the hand to the hook
-- while it stretches, stays taut while it pulls, fades when it lets go; if the
-- hook catches nothing, hook and wire fall together (point rope, Verlet) and
-- dissolve. Graphics only: the Grapple's physics is in sim/game.lua.
--
--   local f = fune.nuova(K)           -- K: wire thickness (world units per 1.5)
--   fune.nodi(f)                      -- the nodes to put in the world
--   fune.dritta(f, x0, y0, x1, y1)    -- from the hand (x0, y0) to the hook (x1, y1)
--   fune.sfuma(f)                     -- taut and letting go: vanishes in a moment
--   fune.cade(f, x0, y0, x1, y1)      -- a miss: falls with the wire
--   fune.update(f, dt, is_solid)      -- the fall (is_solid(x, y): there is terrain there); false once no longer visible
--   f.stato: nil (not visible), "dritta", "sfuma", "cade"

local HOOK = require("battle.weapons").pezzi.uncino

local M = {}

local PIECES = 12        -- wire pieces
local GRAVITY_K = 900     -- of the fall, in world units per second²
local STAYS = 0.35      -- seconds before it starts to dissolve
local FADES = 0.5    -- seconds to dissolve
local BLEND = 0.25
local STEEL = vmath.vector4(0.6, 0.63, 0.67, 1)
-- the hook in flight, a bit bigger than in the barrel: it must be readable
local BIG = 1.25

local V3 = vmath.vector3(0, 0, 0)
local EUL = vmath.vector3(0, 0, 0)

local function fit(n)
	gui.set_adjust_mode(n, gui.ADJUST_FIT)
	return n
end

function M.nuova(k)
	local f = { pezzi = {}, x = {}, y = {}, px = {}, py = {}, t = 0, spessore = 1.5 * k, col = vmath.vector4(STEEL),
		col_img = vmath.vector4(1, 1, 1, 1) }
	for i = 1, PIECES do
		local n = fit(gui.new_box_node(V3, V3))
		gui.set_color(n, f.col)
		gui.set_enabled(n, false)
		f.pezzi[i] = n
	end
	local u = HOOK
	-- the hook's pivot is the ring (the drawing's origin), where the wire arrives
	f.uncino = fit(gui.new_box_node(V3, V3))
	gui.set_visible(f.uncino, false)
	gui.set_enabled(f.uncino, false)
	local img = fit(gui.new_box_node(vmath.vector3(u.x * BIG, u.y * BIG, 0), vmath.vector3(u.w * BIG, u.h * BIG, 0)))
	gui.set_texture(img, "armi")
	gui.play_flipbook(img, u.img)
	gui.set_parent(img, f.uncino)
	f.img = img
	for i = 0, PIECES do f.x[i], f.y[i], f.px[i], f.py[i] = 0, 0, 0, 0 end
	return f
end

function M.nodi(f)
	local out = {}
	for i = 1, PIECES do out[i] = f.pezzi[i] end
	out[#out + 1] = f.uncino
	return out
end

local function alpha(f, a)
	f.col.w = a
	for i = 1, PIECES do gui.set_color(f.pezzi[i], f.col) end
	f.col_img.w = a
	gui.set_color(f.img, f.col_img)
end

local function display(f, on)
	if f.on == on then return end
	f.on = on
	for i = 1, PIECES do gui.set_enabled(f.pezzi[i], on) end
	gui.set_enabled(f.uncino, on)
end

-- draws the wire from points x[0..PIECES], y[...] and the hook at the tip
local function draw(f)
	for i = 1, PIECES do
		local x0, y0, x1, y1 = f.x[i - 1], f.y[i - 1], f.x[i], f.y[i]
		local dx, dy = x1 - x0, y1 - y0
		local n = f.pezzi[i]
		V3.x, V3.y = (x0 + x1) / 2, (y0 + y1) / 2
		gui.set_position(n, V3)
		-- a wire of pieces: each one a bit longer, so the joints don't show
		V3.x, V3.y = math.sqrt(dx * dx + dy * dy) + f.spessore * 0.5, f.spessore
		gui.set_size(n, V3)
		EUL.z = math.deg(math.atan2(dy, dx))
		gui.set_euler(n, EUL)
	end
	local n = PIECES
	V3.x, V3.y = f.x[n], f.y[n]
	gui.set_position(f.uncino, V3)
	EUL.z = math.deg(math.atan2(f.y[n] - f.y[n - 1], f.x[n] - f.x[n - 1]))
	gui.set_euler(f.uncino, EUL)
end

local function straight_ones(f, x0, y0, x1, y1)
	for i = 0, PIECES do
		f.x[i], f.y[i] = x0 + (x1 - x0) * i / PIECES, y0 + (y1 - y0) * i / PIECES
	end
end

function M.dritta(f, x0, y0, x1, y1)
	f.stato = "dritta"
	alpha(f, 1)
	display(f, true)
	-- taut: the hook doesn't turn if the rope is very short
	if (x1 - x0) ^ 2 + (y1 - y0) ^ 2 < 1 then x0 = x1 - 1 end
	straight_ones(f, x0, y0, x1, y1)
	draw(f)
end

function M.sfuma(f)
	if f.stato ~= "dritta" then return end
	f.stato, f.t = "sfuma", 0
end

-- The hook caught nothing: wire and hook fall together, the tip (heavier)
-- keeps going a little in the direction it was flying
function M.cade(f, x0, y0, x1, y1)
	f.stato, f.t = "cade", 0
	alpha(f, 1)
	display(f, true)
	straight_ones(f, x0, y0, x1, y1)
	local d = math.sqrt((x1 - x0) ^ 2 + (y1 - y0) ^ 2)
	f.lungo = d / PIECES
	local ux, uy = d > 0 and (x1 - x0) / d or 0, d > 0 and (y1 - y0) / d or 0
	-- initial speed (in previous points): forward, more toward the tip
	for i = 0, PIECES do
		local v = 3 * i / PIECES
		f.px[i], f.py[i] = f.x[i] - ux * v, f.y[i] - uy * v
	end
	draw(f)
end

function M.update(f, dt, is_solid)
	if not f.stato then return false end
	if f.stato == "dritta" then return true end
	f.t = f.t + dt
	if f.stato == "sfuma" then
		local a = 1 - f.t / BLEND
		if a <= 0 then
			f.stato = nil
			display(f, false)
			return false
		end
		alpha(f, a)
		return true
	end
	-- falls: Verlet with gravity, then the length of each piece
	local g = GRAVITY_K * dt * dt
	for i = 0, PIECES do
		local x, y = f.x[i], f.y[i]
		f.x[i], f.y[i] = x + (x - f.px[i]) * 0.99, y + (y - f.py[i]) * 0.99 - g
		f.px[i], f.py[i] = x, y
	end
	for _ = 1, 3 do
		for i = 1, PIECES do
			local dx, dy = f.x[i] - f.x[i - 1], f.y[i] - f.y[i - 1]
			local d = math.sqrt(dx * dx + dy * dy)
			if d > 0 then
				local c = (d - f.lungo) / d * 0.5
				f.x[i - 1], f.y[i - 1] = f.x[i - 1] + dx * c, f.y[i - 1] + dy * c
				f.x[i], f.y[i] = f.x[i] - dx * c, f.y[i] - dy * c
			end
		end
	end
	-- on the terrain the wire rests: the point that goes in stays where it was
	for i = 0, PIECES do
		if is_solid(f.x[i], f.y[i]) then f.x[i], f.y[i] = f.px[i], f.py[i] end
	end
	draw(f)
	if f.t > STAYS then
		local a = 1 - (f.t - STAYS) / FADES
		if a <= 0 then
			f.stato = nil
			display(f, false)
			return false
		end
		alpha(f, a)
	end
	return true
end

return M
