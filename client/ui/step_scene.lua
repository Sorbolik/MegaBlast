-- The step of a piece (levels 10, 20 and 30): the one long scene of the menus,
-- once per step, skipped with a tap, back by itself. Its screenplay was approved
-- by Sergio on 18 Nov on the page "Proposte zaino e scatto" (an animated preview
-- with the same times), with one change: only the piece, not the devil, and at
-- the explosion only its silhouette for a moment, then the piece as it is now.
--
--   0.00  the tap: the screen under it goes, the forge's painting dims
--   0.45  the charge: the piece comes to the middle and grows slowly, under it its
--         thirty beads (ui/ingots.lua), the step's slot not there yet; embers rise, the painting comes closer and trembles
--   1.30, 1.70, 2.02  three blows, closer and harder: a short freeze, a shake, an
--         ember flash over the whole painting, sparks, the level fills a third; the
--         signature's slot, not there before, is born as a dot and grows, red-hot
--   2.15  held: silence, almost dark, the embers stop, only the level white
--   2.75  the explosion: white flash, a shock ring, rays turning in the new grade's
--         color, the painting tinted with it, the beads take it in a wave, the
--         slot opens all, empty;
--         of the piece only its silhouette, black against the light
--   3.23  the silhouette cools into the piece as it is now (the forged one at 20)
--   3.25  SCATTO! falls from big and slams
--   3.65  what is new comes in, one line at a time; 4.20 CONTINUA rises
--
--   local scene = require "ui.step_scene"
--   local sc = scene.new({ slot_name =, set_name =, level =, lit =, icon_before =,
--     icon_after =, bg =, on_blow = function(i) end })
--   scene.update(sc, dt) -> true while it runs
--   scene.skip(sc)  -- a tap: to the reveal, then away
--   scene.delete(sc)

local ui = require "ui.ui"
local kit = require "ui.kit"
local screen = require "ui.screen"
local ingots = require "ui.ingots"
local equip = require "sim.gear"
local T = require("lang.text").pieces
local go_on = require("lang.text").podium.go_on

local M = {}

-- the beats (seconds)
M.CHARGE, M.SUSPENSE, M.BOOM, M.REVEAL, M.TITLE = 0.45, 2.15, 2.75, 3.23, 3.25
M.BLOWS = { { 1.30, 0.05, 0.42, 0.33 }, { 1.70, 0.07, 0.60, 0.50 }, { 2.02, 0.11, 0.80, 0.72 } } -- t, freeze, trauma, flash
M.ROWS, M.GO = { 3.65, 3.80, 3.95 }, 4.20
M.GROW = { 0.16, 0.42, 0.68 }  -- how big the step's slot is after each blow
M.HOLD = 7.0   -- it goes away by itself
local ROMAN = { "I", "II", "III", "IV" }
local W, H = 1280, 720
local KC = kit.C
-- the piece in the middle (game coordinates) and its size
local PX, PY, PS = 640, 400, 280
-- the bar under it (Figma)
local IX, IY, IW, IH = 340, 528, 600, 40

local function vec(x, y) return vmath.vector3(x, y, 0) end
local function clamp(x, a, b) return math.max(a or 0, math.min(b or 1, x)) end
local function seg(t, a, b) return clamp((t - a) / (b - a)) end
local function lerp(a, b, k) return a + (b - a) * k end
local function eo(k) return 1 - (1 - k) ^ 3 end
local function ob(k) local c = 1.9; k = k - 1; return 1 + (c + 1) * k ^ 3 + c * k * k end

-- a full screen box, over what was made before it
local function sheet(color, add)
	local n = gui.new_box_node(vec(W / 2, H / 2), vec(W * screen.FULL, H * screen.FULL))
	gui.set_color(n, color)
	if add then gui.set_blend_mode(n, gui.BLEND_ADD) end
	return n
end

-- a node's alpha, keeping its color
local function alpha(n, a)
	local c = gui.get_color(n)
	c.w = a
	gui.set_color(n, c)
end

local function soft(x, y, w, h, color, parent)
	local n = ui.sagoma("alone", x, y, w, h, color, parent)
	gui.set_blend_mode(n, gui.BLEND_ADD)
	return n
end

function M.new(o)
	local level, tier = o.level, equip.tier(o.level)
	local sc = { t = 0, o = o, level = level, tier = tier, color = ui.C.GRADI[tier], before = ui.C.GRADI[math.max(1, tier - 1)],
		done = false, rows = {}, fired = {}, ember_t = 0, base = {} }
	-- its own copy of the screen's painting, above everything (ui/kit.lua, over)
	sc.scene = kit.scene(640, 350, { over = true, bg = o.bg })
	sc.painting = sc.scene.painting
	if sc.painting then
		sc.base.pos, sc.base.size, sc.base.color = gui.get_position(sc.painting), gui.get_size(sc.painting), gui.get_color(sc.painting)
	end
	sc.hot = sheet(kit.with_alpha(KC.HOT_BOTTOM, 0), true)
	sc.tint = sheet(kit.with_alpha(sc.color, 0), true)
	sc.dark = sheet(kit.with_alpha(KC.INK, 0))
	-- the rays, turning behind the piece
	sc.rays = gui.new_box_node(vec(PX, PY), vec(0, 0))
	sc.ray = {}
	for i = 1, 12 do
		local r = soft(0, 0, 1500, 70, kit.with_alpha(sc.color, 0), sc.rays)
		gui.set_rotation(r, vmath.vector3(0, 0, i * 15))
		sc.ray[i] = r
	end
	gui.set_scale(sc.rays, vmath.vector3(0.3, 0.3, 1))
	sc.glow = soft(PX, PY, 520, 520, kit.with_alpha(KC.HOT_BOTTOM, 0), nil)
	sc.ring = ui.sagoma("anello_050", PX, PY, 220, 220, kit.with_alpha(KC.SEAM, 0), nil)
	sc.root = gui.new_box_node(vec(0, 0), vec(0, 0))
	local g = { node = sc.root, ox = 0, oy = 720 }
	-- the piece: as it was; at the explosion as it is now
	sc.piece = gui.new_box_node(vec(PX, PY), vec(0, 0))
	gui.set_parent(sc.piece, sc.root)
	local pg = { node = sc.piece, ox = PX, oy = 720 - PY }
	sc.icon_before = kit.pic(pg, o.icon_before, PX - PS / 2, 720 - PY - PS / 2, PS, PS)
	sc.icon_after = kit.pic(pg, o.icon_after, PX - PS / 2, 720 - PY - PS / 2, PS, PS)
	gui.set_enabled(sc.icon_after, false)
	sc.hot_icon = kit.pic(pg, o.icon_after, PX - PS / 2, 720 - PY - PS / 2, PS, PS)
	gui.set_blend_mode(sc.hot_icon, gui.BLEND_ADD)
	gui.set_enabled(sc.hot_icon, false)
	-- the bar of the level, the step still to forge
	sc.ingots = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_parent(sc.ingots, sc.root)
	sc.bar = ingots.draw({ node = sc.ingots, ox = 0, oy = 720 }, IX, IY, IW, IH, level - 1, o.lit or 0, math.floor(level / 10))
	-- the step is the slot: the next level under it does not show
	if sc.bar.next then gui.set_enabled(sc.bar.next, false) end
	local at = gui.get_position(sc.bar.node)
	-- the step's slot is not there yet: it is born at the first blow as a dot, grows
	-- at each blow, glowing hotter, and opens at the explosion (Sergio, 18 Nov)
	sc.stud = sc.bar.studs[math.floor(level / 10)]
	sc.stud_hot = sc.bar.hot[math.floor(level / 10)]
	if sc.stud then at = gui.get_position(sc.bar.node) + gui.get_position(sc.stud) end
	sc.step_at = vec(at.x, at.y)
	-- SCATTO! and what is new
	sc.title = kit.text(g, T.step_title, 640, 118, 120, sc.color, "middle")
	alpha(sc.title, 0)
	sc.title_scale = gui.get_scale(sc.title)
	local lines = {
		{ kit.upper(T.step_grade:format(ROMAN[tier], kit.upper(T.grades[tier]))), sc.color },
		{ kit.upper(o.slot_name .. " · " .. o.set_name), KC.SAND },
		{ kit.upper(level >= equip.LIVELLO_MAX and T.step_top or tier == 2 and T.step_sign_on or T.step_look), KC.SAND },
	}
	for i, l in ipairs(lines) do
		local n = kit.text(g, l[1], 846, 270 + (i - 1) * 46, i == 1 and 28 or 22, l[2], "start")
		local wide = kit.width(n)
		if wide > 400 then local s = gui.get_scale(n); gui.set_scale(n, vec(s.x * 400 / wide, s.y * 400 / wide)) end
		alpha(n, 0)
		sc.rows[i] = { node = n, scale = gui.get_scale(n), pos = gui.get_position(n) }
	end
	-- the way on (a tap anywhere does the same)
	sc.right = kit.anchor(1280, 720, gui.ANCHOR_RIGHT, gui.ANCHOR_BOTTOM)
	kit.action(sc.right, go_on, 930, 560, 270, 84, { size = 44 })
	sc.go_pos = gui.get_position(sc.right.node)
	gui.set_position(sc.right.node, sc.go_pos - vec(0, 200))
	sc.flash = sheet(vmath.vector4(1, 1, 1, 0))
	return sc
end

-- sparks from (x, y) (game coordinates), up and out
local function sparks(sc, x, y, n, color, speed, all_round)
	for i = 1, n do
		local a = all_round and (i / n) * 2 * math.pi or math.pi * (0.1 + 0.8 * math.random())
		local d = speed * (0.6 + 0.6 * math.random())
		local s = ui.sagoma("forma", x, y, 18 + 10 * math.random(), 5, i % 3 == 0 and KC.SEAM or color, sc.root)
		gui.set_slice9(s, vmath.vector4(2, 2, 2, 2))
		gui.set_rotation(s, vmath.vector3(0, 0, math.deg(a)))
		gui.animate(s, "position", vec(x + math.cos(a) * d, y + math.sin(a) * d), gui.EASING_OUTQUAD, 0.45)
		gui.animate(s, "color.w", 0, gui.EASING_INQUAD, 0.45, 0, function() gui.delete_node(s) end)
	end
end

-- an ember rising from the bottom
local function ember(sc, color)
	local x = 200 + 880 * math.random()
	local s = ui.sagoma("forma", x, -10, 4, 11, color, sc.root)
	gui.set_slice9(s, vmath.vector4(1, 1, 1, 1))
	gui.set_rotation(s, vmath.vector3(0, 0, 20 * (math.random() - 0.5)))
	local life = 1.4 + math.random()
	gui.animate(s, "position", vec(x + 60 * (math.random() - 0.5), 560 + 120 * math.random()), gui.EASING_LINEAR, life)
	gui.animate(s, "color.w", 0, gui.EASING_INQUAD, life, 0, function() gui.delete_node(s) end)
end

-- how much it shakes at t (0..1), from the blows that decay
local function trauma(t)
	local s = 0
	if t > M.CHARGE and t < M.SUSPENSE then s = s + 0.12 + 0.1 * seg(t, M.CHARGE, M.SUSPENSE) end
	for _, b in ipairs(M.BLOWS) do if t >= b[1] then s = s + b[3] * math.exp(-(t - b[1]) / 0.17) end end
	if t >= M.BOOM then s = s + 0.95 * math.exp(-(t - M.BOOM) / 0.26) end
	if t >= M.TITLE + 0.14 then s = s + 0.4 * math.exp(-(t - M.TITLE - 0.14) / 0.15) end
	return clamp(s)
end

-- the moments that happen once (sounds, sparks, the wave), when t passes them
local function events(sc, t, quiet)
	local function once(id, at)
		if t >= at and not sc.fired[id] then sc.fired[id] = true; return true end
	end
	local sx, sy = sc.step_at.x, sc.step_at.y
	for i, b in ipairs(M.BLOWS) do
		if once("blow" .. i, b[1]) then
			if not quiet and sc.o.on_blow then sc.o.on_blow(i) end
			sparks(sc, sx, sy, ({ 10, 16, 26 })[i], KC.HOT, 120 + 50 * i)
		end
	end
	if once("boom", M.BOOM) then
		if not quiet then sound.play("#boom", { gain = 1, speed = 0.8 }) end
		sparks(sc, PX, PY, 36, sc.color, 520, true)
		gui.set_enabled(sc.icon_before, false)
		gui.set_enabled(sc.icon_after, true)
		-- the wave: the metal flows again from the left, in the new grade's color
		sc.bar.set(sc.level - 1, KC.SEAM)
		sc.bar.set(sc.level, sc.color, 0.45, 0.06)
		local stud = sc.stud
		if stud then
			gui.set_enabled(stud, true)
			gui.set_scale(stud, vmath.vector3(M.GROW[3], M.GROW[3], 1))
			gui.set_enabled(sc.stud_hot, false)
			gui.animate(stud, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, 0.3, 0, function()
				gui.animate(stud, "scale", vmath.vector3(1.15, 1.15, 1), gui.EASING_INOUTSINE, 0.5, 0.3, nil, gui.PLAYBACK_LOOP_PINGPONG)
			end)
		end
	end
	if once("reveal", M.REVEAL) then
		gui.set_enabled(sc.hot_icon, true)
		sparks(sc, PX, PY, 14, KC.SEAM, 260, true)
	end
	if once("title", M.TITLE + 0.14) and not quiet then sound.play("#martello", { speed = 0.7 }) end
	for i, at in ipairs(M.ROWS) do
		if once("row" .. i, at) and not quiet then sound.play("#scaglia", { speed = 1 + 0.15 * i }) end
	end
end

local function draw(sc, t)
	local tr = trauma(t)
	local sh = tr * tr
	local ox = 26 * sh * math.sin(t * 61) + 10 * sh * math.sin(t * 130)
	local oy = 18 * sh * math.sin(t * 77 + 1)
	-- the painting: it dims, comes closer, shakes; at the explosion it lights up
	local bright = lerp(1, 0.35, eo(seg(t, 0, 0.45)))
	if t > M.SUSPENSE then bright = lerp(0.35, 0.14, seg(t, M.SUSPENSE, M.SUSPENSE + 0.25)) end
	if t >= M.BOOM then bright = lerp(1, 0.8, eo(seg(t, M.BOOM, M.BOOM + 0.7))) end
	local zoom = 1 + 0.06 * eo(seg(t, M.CHARGE, M.BOOM)) - (t >= M.BOOM and 0.04 * eo(seg(t, M.BOOM, M.BOOM + 0.5)) or 0)
	if sc.painting then
		local c = sc.base.color
		gui.set_color(sc.painting, vmath.vector4(c.x * bright, c.y * bright, c.z * bright, 1))
		gui.set_size(sc.painting, sc.base.size * zoom)
		gui.set_position(sc.painting, sc.base.pos + vec(ox, oy))
	else
		alpha(sc.dark, (1 - bright) * 0.9)
	end
	local hot = 0
	for _, b in ipairs(M.BLOWS) do if t >= b[1] then hot = hot + b[4] * math.exp(-(t - b[1]) / 0.11) end end
	if t >= M.BOOM then hot = hot + 0.6 * math.exp(-(t - M.BOOM) / 0.4) end
	alpha(sc.hot, clamp(hot * 0.5))
	alpha(sc.tint, t >= M.BOOM and 0.22 * eo(seg(t, M.BOOM, M.BOOM + 0.3)) or 0)
	alpha(sc.flash, t >= M.BOOM and math.exp(-(t - M.BOOM) / 0.09) or 0)
	-- rays, ring, the light behind the piece
	local ra = t >= M.BOOM and 0.5 * eo(seg(t, M.BOOM, M.BOOM + 0.25)) or 0
	for _, r in ipairs(sc.ray) do alpha(r, ra) end
	local rs = t >= M.BOOM and lerp(0.3, 1, eo(seg(t, M.BOOM, M.BOOM + 0.4))) or 0.3
	gui.set_scale(sc.rays, vmath.vector3(rs, rs, 1))
	gui.set_rotation(sc.rays, vmath.vector3(0, 0, (t - M.BOOM) * 18))
	local rp = seg(t, M.BOOM, M.BOOM + 0.52)
	alpha(sc.ring, (t >= M.BOOM and rp < 1) and (1 - rp) or 0)
	gui.set_scale(sc.ring, vmath.vector3(0.3 + 6 * eo(rp), 0.3 + 6 * eo(rp), 1))
	local glow = t < M.SUSPENSE and 0.25 * seg(t, M.CHARGE, M.SUSPENSE) or (t < M.BOOM and 0.12 or lerp(1, 0.45, seg(t, M.BOOM, M.REVEAL + 0.6)))
	gui.set_color(sc.glow, kit.with_alpha(t >= M.BOOM and sc.color or KC.HOT_BOTTOM, glow))
	-- the piece: to the middle, it grows, takes the blows; at the explosion only its silhouette
	local ds = lerp(0.85, 1.05, eo(seg(t, M.CHARGE, 1.25)))
	for _, b in ipairs(M.BLOWS) do
		if t >= b[1] then ds = ds - (t < b[1] + b[2] and 0.08 or 0.08 * math.exp(-(t - b[1] - b[2]) / 0.09)) end
	end
	if t > M.SUSPENSE and t < M.BOOM then ds = ds + 0.03 * seg(t, M.SUSPENSE, M.BOOM) end
	if t >= M.BOOM and t < M.REVEAL then ds = lerp(1.4, 1.12, ob(seg(t, M.BOOM, M.BOOM + 0.3))) end
	if t >= M.REVEAL then ds = lerp(1.28, 1.1, ob(seg(t, M.REVEAL, M.REVEAL + 0.38))) end
	local dx = lerp(130, 0, eo(seg(t, 0.3, 0.9)))
	gui.set_position(sc.piece, vec(PX + dx + ox * 0.4, PY + oy * 0.4))
	gui.set_scale(sc.piece, vmath.vector3(ds, ds, 1))
	local pb = t < M.BOOM and lerp(1, 0.6, seg(t, 0, 0.45)) or 1
	gui.set_color(sc.icon_before, vmath.vector4(pb, pb, pb, 1))
	if t >= M.BOOM then
		local k = t < M.REVEAL and 0 or eo(seg(t, M.REVEAL, M.REVEAL + 0.2))
		gui.set_color(sc.icon_after, vmath.vector4(k, k, k, 1))
		alpha(sc.hot_icon, t < M.REVEAL and 0 or math.exp(-(t - M.REVEAL) / 0.18))
	end
	-- the bar: it comes up; the step's slot grows at each blow
	local na = eo(seg(t, M.CHARGE, 0.7))
	gui.set_position(sc.ingots, vec(ox * 0.6, oy * 0.6 - (1 - na) * 40))
	if t < M.BOOM then
		local beat = 0
		if t > M.CHARGE then
			local rate = lerp(1.6, 4.5, seg(t, M.CHARGE, M.SUSPENSE))
			beat = math.max(0, math.sin(t * rate * math.pi)) ^ 6
		end
		if sc.stud then
			-- nothing, a dot, bigger, almost all: each blow makes it grow with a kick
			local grow = 0
			for i, b in ipairs(M.BLOWS) do
				if t >= b[1] then
					local from = M.GROW[i - 1] or 0
					grow = lerp(from, M.GROW[i], eo(seg(t, b[1], b[1] + 0.12)))
					if t < b[1] + 0.06 then grow = grow + 0.12 end
				end
			end
			gui.set_enabled(sc.stud, grow > 0)
			grow = grow * (1 + 0.08 * beat)
			gui.set_scale(sc.stud, vmath.vector3(grow, grow, 1))
			-- red-hot while it grows
			gui.set_enabled(sc.stud_hot, true)
		end
	end
	-- SCATTO! falls and slams; the lines come in; CONTINUA rises
	local tp = seg(t, M.TITLE, M.TITLE + 0.14)
	alpha(sc.title, t >= M.TITLE and 1 or 0)
	local ts = t < M.TITLE + 0.14 and lerp(3.2, 1, tp * tp) or 1 + 0.08 * math.exp(-(t - M.TITLE - 0.14) / 0.08)
	gui.set_scale(sc.title, sc.title_scale * ts)
	gui.set_rotation(sc.title, vmath.vector3(0, 0, 4))
	for i, r in ipairs(sc.rows) do
		local p = eo(seg(t, M.ROWS[i], M.ROWS[i] + 0.22))
		alpha(r.node, p)
		gui.set_position(r.node, r.pos + vec((1 - p) * 60, 0))
		gui.set_scale(r.node, r.scale * (1 + 0.15 * (1 - p)))
	end
	local cp = ob(seg(t, M.GO, M.GO + 0.35))
	gui.set_position(sc.right.node, sc.go_pos - vec(0, (1 - cp) * 200))
	gui.set_position(sc.root, vec(ox * 0.3, oy * 0.3))
end

function M.update(sc, dt)
	if sc.done then return false end
	local was = sc.t
	sc.t = sc.t + dt
	local t = sc.t
	-- embers: more and more while it charges, still while it waits, many after
	if t > M.CHARGE and (t < M.SUSPENSE or t > M.BOOM) then
		sc.ember_t = sc.ember_t + dt * (t < M.BOOM and lerp(6, 30, seg(t, M.CHARGE, M.SUSPENSE)) or 20)
		while sc.ember_t >= 1 do
			sc.ember_t = sc.ember_t - 1
			ember(sc, t >= M.BOOM and math.random() < 0.4 and sc.color or (math.random() < 0.7 and KC.HOT or KC.HOT_BOTTOM))
		end
	end
	events(sc, t, sc.quiet)
	draw(sc, t)
	if t >= M.HOLD then sc.done = true end
	return not sc.done
end

-- a tap: straight to the end of the reveal; there, away
function M.skip(sc)
	if sc.t < M.GO + 0.35 then
		sc.t = M.GO + 0.35
		sc.quiet = true
		events(sc, sc.t, true)
		sc.quiet = false
		draw(sc, sc.t)
	else
		sc.done = true
	end
end

function M.delete(sc)
	for _, n in ipairs({ sc.root, sc.right.node, sc.flash, sc.hot, sc.tint, sc.dark, sc.rays, sc.glow, sc.ring }) do
		gui.delete_node(n)
	end
	kit.scene_drop(sc.scene)
end

return M
