-- The sky of the Limbo behind the home, at the hour of the phone (Sergio, 24 Nov: «questo
-- resti per la sera e poi ci siano le transizioni giorno/notte»): five moments with the
-- same composition, the same clouds and stars, each with its colours and what passes in
-- the air: MATTINA (6-11) the sun rising, the last stars going out, low mist, flocks of
-- birds and dandelion seeds going up; MEZZOGIORNO (11-15) the sun high on the right, a
-- hot-air balloon, pairs of birds, glinting pollen; POMERIGGIO (15-19) the sun going down,
-- leaves falling and turning, a kite, the birds flying back; SERA (19-22) the sky of 18 Nov
-- as it was; NOTTE (22-6) darker, brighter stars, the crescent moon. When the moment
-- changes, the sky passes to the next one in 3 seconds (Sergio: «la transizione in 3
-- secondi circa»); the sun and the moon follow the hour along their arc.
-- Everything is flat like the clouds (tools/grafica/cielo.py: white layers coloured
-- here, or flat colours), no glow. What moves is a function of one clock that never
-- restarts (ui/clock.lua), so leaving the home and coming back it is where it would be.
--
--   local sky = require "ui.limbo_sky"
--   local tick = sky.build(root, live, texture)    -- (ui/flat_backdrops.lua, theme "cielo")
--   sky.BASE                                       -- the evening's dark
--
-- In the simulator (tools/simula) "imposta prova_cielo H" stops the hour at H, and
-- "imposta prova_cielo giro" shows the five moments one after the other, 8 s each.

local screen = require "ui.screen"
local clock = require "ui.clock"

local M = {}

local function c(h)
	return vmath.vector4(tonumber(h:sub(1, 2), 16) / 255, tonumber(h:sub(3, 4), 16) / 255, tonumber(h:sub(5, 6), 16) / 255, 1)
end

-- the five moments: from which hour, the sky's colours (base, the clouds' contour, body
-- and shadow), how much the far clouds fade into the base, how much the stars show and
-- their three tints
local KEYS = {
	{ name = "mattina", from = 6, base = "3B2D4C", cont = "7A5C80", body = "4E3B60", sh = "453455", far = 0.8, stars = 0.35, tints = { "6E5A80", "5C4A70", "8E74A0" } },
	{ name = "mezzogiorno", from = 11, base = "2D4864", cont = "86A2C0", body = "5F7C9C", sh = "54708E", far = 0.85, stars = 0, tints = { "FFFFFF", "FFFFFF", "FFFFFF" } },
	{ name = "pomeriggio", from = 15, base = "5E3A34", cont = "A86C50", body = "7E4E40", sh = "704438", far = 0.82, stars = 0, tints = { "FFFFFF", "FFFFFF", "FFFFFF" } },
	{ name = "sera", from = 19, base = "0F0E1A", cont = "2B2744", body = "1B1929", sh = "161422", far = 0.72, stars = 1, tints = { "55497A", "3E3760", "6E5F96" } },
	{ name = "notte", from = 22, base = "05050B", cont = "1C1930", body = "0D0C17", sh = "0A0912", far = 0.6, stars = 1, tints = { "6E62A6", "5A5090", "9A8ED6" } },
}
for _, k in ipairs(KEYS) do
	for _, f in ipairs({ "base", "cont", "body", "sh" }) do k[f] = c(k[f]) end
	for i = 1, 3 do k.tints[i] = c(k.tints[i]) end
end
M.BASE = KEYS[4].base

local PASS = 3          -- seconds from one moment to the next
-- the sun's rim, body and band low on the horizon and high in the sky
local SUN_LOW = { c("F0B49A"), c("C9785F"), c("B66A55") }
local SUN_HIGH = { c("F7DE9A"), c("E8BE62"), c("D6A854") }

-- the hour now, from 0 to 24 (the simulator can stop it or turn it)
local test = sys.get_config_string("megablast.prova_cielo", "")
local function hour(t)
	if test == "giro" then
		local k = KEYS[math.floor(t / 8) % #KEYS + 1]
		return (k.from + 2) % 24
	elseif tonumber(test) then
		return tonumber(test)
	end
	local d = os.date("*t")
	return d.hour + d.min / 60 + d.sec / 3600
end

local function moment_at(h)
	local found = KEYS[#KEYS]
	for _, k in ipairs(KEYS) do
		if h >= k.from then found = k end
	end
	return found
end

-- which moment shows and which it is coming from (for the whole game: the home made
-- again goes on with the passage where it was)
local shown = {}

local function mix(a, b, k, out)
	out = out or vmath.vector4()
	out.x, out.y, out.z, out.w = a.x + (b.x - a.x) * k, a.y + (b.y - a.y) * k, a.z + (b.z - a.z) * k, 1
	return out
end

-- the sky's state at time t: colours mixed between the two moments, and how much of each
local P = { w = {}, tints = { vmath.vector4(), vmath.vector4(), vmath.vector4() }, base = vmath.vector4(), cont = vmath.vector4(),
	body = vmath.vector4(), sh = vmath.vector4() }
local function state(t)
	local h = hour(t)
	local to = moment_at(h)
	if shown.to ~= to then
		shown.from, shown.at = shown.to or to, shown.to and t or -PASS
		shown.to = to
	end
	local k = math.min(1, math.max(0, (t - shown.at) / PASS))
	k = k * k * (3 - 2 * k)
	local a, b = shown.from, shown.to
	for _, key in ipairs(KEYS) do P.w[key.name] = 0 end
	P.w[a.name] = P.w[a.name] + 1 - k
	P.w[b.name] = P.w[b.name] + k
	for _, f in ipairs({ "base", "cont", "body", "sh" }) do mix(a[f], b[f], k, P[f]) end
	for i = 1, 3 do mix(a.tints[i], b.tints[i], k, P.tints[i]) end
	P.far = a.far + (b.far - a.far) * k
	P.stars = a.stars + (b.stars - a.stars) * k
	P.hour = h
	return P
end

-- a number from 0 to 1 for (a, b, c), always the same
local function hash(a, b, c3)
	local x = math.sin(a * 127.1 + b * 311.7 + c3 * 74.7) * 43758.5453
	return x - math.floor(x)
end

-- a fixed sequence of numbers from 0 to 1
local function sequence(seed)
	local x = seed
	return function()
		x = (x * 1103515245 + 12345) % 2147483648
		return x / 2147483648
	end
end

local AWAY = vmath.vector3(0, -999, 0)
local V = vmath.vector3()
local COL = vmath.vector4()

-- a group of nodes that fades and switches off as a whole
local function group(parent)
	local n = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(0, 0, 0))
	gui.set_visible(n, false)
	gui.set_parent(n, parent)
	gui.set_inherit_alpha(n, true)
	return n
end

-- shows the group at alpha a; false when there is nothing to see
local function fade(g, a)
	if a <= 0.005 then
		gui.set_enabled(g, false)
		return false
	end
	gui.set_enabled(g, true)
	COL.x, COL.y, COL.z, COL.w = 1, 1, 1, math.min(1, a)
	gui.set_color(g, COL)
	return true
end

local function put(n, x, y)
	V.x, V.y, V.z = x, y, 0
	gui.set_position(n, V)
end

function M.build(root, live, texture)
	-- a picture of the backdrops' folder (drawn at twice the size it is shown at)
	local function pic(name, parent, color)
		local id, w, h = texture(name)
		local n = gui.new_box_node(vmath.vector3(0, -999, 0), vmath.vector3((w or 0) / 2, (h or 0) / 2, 0))
		if id then gui.set_texture(n, id) end
		gui.set_parent(n, parent)
		gui.set_inherit_alpha(n, true)
		if color then gui.set_color(n, color) end
		return n
	end
	local clip = gui.get_parent(root)

	-- the sun and the moon, behind everything
	local sun_g = group(root)
	local sun = { pic("sole_bordo", sun_g), pic("sole_corpo", sun_g), pic("sole_fascia", sun_g) }
	local moon_g = group(root)
	local moon = { pic("luna_bordo", moon_g, c("B8B0DC")), pic("luna_corpo", moon_g, c("8A82B4")) }

	-- the cloud lanes: { far, turn in seconds }; one cloud at a time on each, it waits a
	-- random while in its turn, then crosses at its own speed. Each cloud is three layers
	local shapes = {}
	for i = 1, 6 do
		local _, w, h = texture("nuvola_" .. i .. "_bordo")
		local body, shadow = texture("nuvola_" .. i .. "_corpo"), texture("nuvola_" .. i .. "_ombra")
		if w and body and shadow then
			shapes[#shapes + 1] = { "nuvola_" .. i .. "_bordo", "nuvola_" .. i .. "_corpo", "nuvola_" .. i .. "_ombra", w = w / 2, h = h / 2 }
		end
	end
	local LANES = { { false, 95 }, { false, 120 }, { false, 140 }, { true, 170 }, { true, 210 }, { true, 250 } }
	local lanes = {}
	local function crossing(i, l, turn, half)
		local cr = { shape = shapes[1 + math.floor(hash(i, turn, 2) * #shapes) % #shapes] }
		cr.k = l.near and 0.7 + hash(i, turn, 3) * 0.45 or 0.4 + hash(i, turn, 3) * 0.25
		cr.w = cr.shape.w * cr.k
		cr.path = 2 * half + cr.w + 20
		local speed = l.near and 9 + hash(i, turn, 4) * 8 or 4 + hash(i, turn, 4) * 4
		-- it waits at most what leaves it the time to cross in its turn
		cr.cross = math.min(cr.path / speed, l.turn * 0.95)
		cr.start = hash(i, turn, 5) * (l.turn - cr.cross)
		cr.y = 300 + hash(i, turn, 6) * 480
		cr.flip = hash(i, turn, 7) < 0.5 and -1 or 1
		return cr
	end
	local function lane(i)
		local near, turn = not LANES[i][1], LANES[i][2]
		local l = { near = near, turn = turn, shift = M.shifts[i] }
		-- where each lane is in its turn, fixed for the whole game: the first near and
		-- far ones are half way across when the home first shows
		if not l.shift then
			l.shift = hash(i, 0, 1) * turn
			if shapes[1] and (i == 1 or i == 4) then
				local cr = crossing(i, l, 0, screen.width() / 2)
				l.shift = cr.start + cr.cross * (i == 1 and 0.55 or 0.3) - clock.now()
			end
			M.shifts[i] = l.shift
		end
		if shapes[1] then
			l.n = group(root)
			l.layers = {}
			for j = 1, 3 do
				local n = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(shapes[1].w, shapes[1].h, 0))
				gui.set_parent(n, l.n)
				gui.set_inherit_alpha(n, true)
				l.layers[j] = n
			end
		end
		lanes[i] = l
	end
	-- the far clouds first, under the stars
	for i = 1, #LANES do if LANES[i][1] then lane(i) end end

	-- the stars, small four-pointed, twinkling and drifting left, and the falling star
	local star_g = group(root)
	local stars = {}
	do
		local r = sequence(9)
		for i = 1, 110 do
			stars[i] = { pic("stella", star_g), x = -900 + r() * 1800, y = 140 + r() * 760, s = 8 + r() * 18, ph = r() * 6.28, sp = 0.4 + r() * 0.8, k = i % 3 + 1 }
		end
	end
	local streak = gui.new_box_node(vmath.vector3(0, -999, 0), vmath.vector3(140, 2, 0))
	gui.set_parent(streak, star_g)
	gui.set_inherit_alpha(streak, true)
	gui.set_rotation(streak, vmath.vector3(0, 0, -30))

	-- the morning's mist, the noon's balloon and the afternoon's kite, behind the near clouds
	local mist_g = group(root)
	local mist = {}
	for i = 1, 4 do mist[i] = pic("foschia_" .. (i % 2 + 1), mist_g) end
	local balloon_g = group(root)
	local balloon = pic("mongolfiera", balloon_g)
	local kite_g = group(root)
	local string_n = gui.new_box_node(vmath.vector3(0, -999, 0), vmath.vector3(1.6, 1, 0))
	gui.set_parent(string_n, kite_g)
	gui.set_inherit_alpha(string_n, true)
	local bows = {}
	for i = 1, 3 do bows[i] = pic("fiocco", kite_g) end
	local kite = pic("aquilone", kite_g)

	-- the near clouds
	for i = 1, #LANES do if not LANES[i][1] then lane(i) end end

	-- in front: the birds (three flocks), the seeds, the pollen, the leaves
	local flocks = {}
	for f = 1, 3 do
		local g = group(root)
		local birds = {}
		for i = 1, 6 do birds[i] = pic("uccello_1", g) end
		flocks[f] = { g = g, birds = birds }
	end
	local seed_g = group(root)
	local seeds = {}
	for i = 1, 16 do seeds[i] = pic("seme", seed_g) end
	local mote_g = group(root)
	local motes = {}
	for i = 1, 34 do motes[i] = pic("punto", mote_g, c("FFECAA")) end
	local leaf_g = group(root)
	local leaves = {}
	for i = 1, 12 do leaves[i] = pic("foglia_" .. (i % 3 + 1), leaf_g) end

	local bird_tex = {}
	for i = 1, 3 do bird_tex[i] = texture("uccello_" .. i) end
	local bird_col = vmath.vector4()
	local mist_col = vmath.vector4()
	local string_col = vmath.vector4()
	local white = vmath.vector4(1, 1, 1, 1)
	local far = { vmath.vector4(), vmath.vector4(), vmath.vector4() }
	local scale = vmath.vector3()
	local rot = vmath.vector3()

	-- a flock crossing every period seconds: n0 to n0 + 2 birds in a V
	local function flock(fl, t, period, n0, seed, dir, ybase, half)
		local k = math.floor(t / period)
		local q = t / period - k
		local n = n0 + math.floor(hash(k, seed, 1) * 3)
		local y0 = ybase - hash(k, seed, 2) * 140
		local x0 = dir < 0 and half + 120 - q * (2 * half + 400) or -half - 120 + q * (2 * half + 400)
		for i, b in ipairs(fl.birds) do
			if i > n then
				gui.set_position(b, AWAY)
			else
				local row, side = math.ceil((i - 1) / 2), (i - 1) % 2 == 1 and 1 or -1
				put(b, x0 - dir * row * 34, y0 - side * row * 18 + math.sin(t * 1.3 + i) * 3)
				local pose = math.sin(t * 9 + i * 1.7)
				gui.set_texture(b, bird_tex[pose > 0.35 and 1 or pose < -0.35 and 3 or 2])
				local s = (11 + hash(i, k, seed) * 4) / 13
				V.x, V.y, V.z = s, s, 1
				gui.set_scale(b, V)
				gui.set_color(b, bird_col)
			end
		end
	end

	local function place(t)
		local p = state(t)
		local w, h = p.w, p.hour
		local half = screen.width() / 2
		gui.set_color(clip, p.base)

		-- the sun from 6 to 19, the moon from 22 to 6: at their highest they stand right
		-- of the apprentice, never behind him
		local day = w.mattina + w.mezzogiorno + w.pomeriggio
		local fs = (h - 6) / 13
		if fade(sun_g, (fs > 0 and fs < 1) and day or 0) then
			local e = math.sin(math.pi * fs)
			local x = fs < 0.5 and -580 + 1680 * fs or 260 + 640 * (fs - 0.5)
			for j = 1, 3 do gui.set_color(sun[j], mix(SUN_LOW[j], SUN_HIGH[j], e, COL)) end
			for _, n in ipairs(sun) do put(n, x, 180 + 440 * e) end
		end
		local fm = ((h - 22) % 24) / 8
		if fade(moon_g, fm < 1 and w.notte or 0) then
			local e = math.sin(math.pi * fm)
			local x = fm < 0.5 and -580 + 1680 * fm or 260 + 640 * (fm - 0.5)
			for _, n in ipairs(moon) do put(n, x, 180 + 420 * e) end
		end

		-- the clouds: the far ones fade into the base
		mix(p.base, p.cont, p.far, far[1]); mix(p.base, p.body, p.far, far[2]); mix(p.base, p.sh, p.far, far[3])
		local near_cols = { p.cont, p.body, p.sh }
		for i, l in ipairs(lanes) do
			if l.n then
				local turn = math.floor((t + l.shift) / l.turn)
				local cr = crossing(i, l, turn, half)
				local q = ((t + l.shift) - turn * l.turn - cr.start) / cr.cross
				if q < 0 or q > 1 then
					gui.set_position(l.n, AWAY)
				else
					local cols = l.near and near_cols or far
					V.x, V.y, V.z = cr.shape.w, cr.shape.h, 0
					for j = 1, 3 do
						local n = l.layers[j]
						gui.set_texture(n, cr.shape[j])
						gui.set_size(n, V)
						gui.set_color(n, cols[j])
					end
					put(l.n, half + cr.w / 2 + 10 - q * cr.path, cr.y)
					scale.x, scale.y, scale.z = cr.flip * cr.k, cr.k, 1
					gui.set_scale(l.n, scale)
				end
			end
		end

		-- the stars
		if fade(star_g, p.stars) then
			for _, e in ipairs(stars) do
				local x = (e.x + 900 - t * 6) % 1800 - 900
				put(e[1], x, e.y)
				local s = e.s * (0.6 + 0.4 * math.sin(t * e.sp + e.ph))
				V.x, V.y, V.z = s, s, 0
				gui.set_size(e[1], V)
				gui.set_color(e[1], p.tints[e.k])
			end
			local q = (t % 7) / 1.2
			if q <= 1 then
				local k = math.floor(t / 7)
				put(streak, -500 + (k * 389) % 900 + q * 420, 800 - q * 240)
				mix(p.tints[3], white, 0.2, COL)
				COL.w = math.sin(q * math.pi)
				gui.set_color(streak, COL)
			else
				gui.set_position(streak, AWAY)
			end
		end

		-- the morning's mist: long flat strips sliding low
		if fade(mist_g, w.mattina * 0.9) then
			mix(p.base, p.cont, 0.9, mist_col)
			for i, n in ipairs(mist) do
				local mw = i % 2 == 1 and 520 or 360
				local x = (hash(i, 3, 9) * 2000 + t * (6 + i * 3)) % (2 * half + mw + 200) - half - mw / 2 - 100
				put(n, x, 320 - (i - 1) * 52 - hash(i, 4, 9) * 20)
				gui.set_color(n, mist_col)
			end
		end

		-- noon's balloon, crossing slowly from the right every 80 s
		if fade(balloon_g, w.mezzogiorno) then
			local k = math.floor(t / 80)
			local q = (t % 80) / 80
			put(balloon, half + 80 - q * (2 * half + 160), 720 - 172 - hash(k, 1, 3) * 80 + math.sin(t * 0.6) * 8)
		end

		-- the afternoon's kite, swaying, its string down behind the doors
		if fade(kite_g, w.pomeriggio) then
			local x, y = 395 + math.sin(t * 0.5) * 26, 600 + math.sin(t * 0.8) * 14
			put(kite, x, y)
			V.x, V.y, V.z = 0, 0, math.deg(math.sin(t * 0.9) * 0.18)
			gui.set_rotation(kite, V)
			local x1, y1 = x + 120, 112
			local dx, dy = x1 - x, y1 - (y - 34)
			put(string_n, (x + x1) / 2, (y - 34 + y1) / 2)
			V.x, V.y, V.z = 1.6, math.sqrt(dx * dx + dy * dy), 0
			gui.set_size(string_n, V)
			V.x, V.y, V.z = 0, 0, math.deg(math.atan2(dy, dx)) - 90
			gui.set_rotation(string_n, V)
			mix(p.cont, white, 0.2, string_col)
			gui.set_color(string_n, string_col)
			for i, n in ipairs(bows) do
				put(n, x - 16 * i + math.sin(t * 3 + 2 * i) * 7, y - 34 - 24 * i)
			end
		end

		-- the birds: in the morning flocks to the left, at noon pairs, in the afternoon back
		mix(p.sh, vmath.vector4(0, 0, 0, 1), 0.45, bird_col)
		if fade(flocks[1].g, math.min(1, w.mattina * 1.4)) then flock(flocks[1], t, 19, 4, 1, -1, 630, half) end
		if fade(flocks[2].g, math.min(1, w.mezzogiorno * 1.4)) then flock(flocks[2], t + 7, 13, 1, 2, -1, 650, half) end
		if fade(flocks[3].g, math.min(1, w.pomeriggio * 1.4)) then flock(flocks[3], t + 3, 17, 3, 3, 1, 610, half) end

		-- dandelion seeds going up in the morning
		if fade(seed_g, math.min(1, w.mattina * 1.3)) then
			for i, n in ipairs(seeds) do
				local per = 22 + hash(i, 1, 4) * 14
				local q = ((t + hash(i, 2, 4) * per) % per) / per
				put(n, -half + hash(i, 3, 4) * 2 * half + q * 160 + math.sin(t * 0.9 + i) * 18, 90 + q * 700)
				V.x, V.y, V.z = 0, 0, math.deg(math.sin(t * 1.4 + i) * 0.4)
				gui.set_rotation(n, V)
			end
		end

		-- noon's pollen: tiny drifting motes that glint
		if fade(mote_g, w.mezzogiorno) then
			for i, n in ipairs(motes) do
				local x = (hash(i, 1, 7) * 1500 - t * (5 + hash(i, 2, 7) * 6)) % 1500 - 750
				put(n, x, 640 - hash(i, 3, 7) * 500 + math.sin(t * 0.7 + i) * 10)
				COL.x, COL.y, COL.z = 1, 0.925, 0.667
				COL.w = 0.4 + 0.6 * math.max(0, math.sin(t * (1 + hash(i, 4, 7)) + i))
				gui.set_color(n, COL)
			end
		end

		-- the afternoon's leaves, falling and turning
		if fade(leaf_g, math.min(1, w.pomeriggio * 1.3)) then
			for i, n in ipairs(leaves) do
				local per = 16 + hash(i, 1, 5) * 10
				local q = ((t + hash(i, 2, 5) * per) % per) / per
				put(n, half + 60 - q * (500 + hash(i, 3, 5) * 500) - hash(i, 4, 5) * 700 + math.sin(t * 1.6 + i) * 30, 750 - q * 700)
				rot.x, rot.y, rot.z = 0, 0, math.deg(t * (1 + hash(i, 6, 5)) + i)
				gui.set_rotation(n, rot)
				V.x, V.y, V.z = 1, 0.55 + 0.45 * math.sin(t * 2 + i), 1
				gui.set_scale(n, V)
			end
		end
	end

	place(clock.now())
	if not live then return end
	return function()
		place(clock.now())
	end
end

-- where each cloud lane is in its turn, fixed for the whole game
M.shifts = {}

return M
