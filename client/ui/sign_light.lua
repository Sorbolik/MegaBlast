-- Lighting a piece's signature (Sergio, 18 Nov, section 5 of the page "Proposte
-- zaino e scatto", approved: «mi sta bene l'animazione di accendi la firma, vorrei
-- che ci fosse anche l'immagine dell'oggetto dentro»). A short moment of ice (the
-- step is fire), about a second and a half; it does not stop the screen.
--
--      0  the tap: the Ossidiana's balance flashes, −cost jumps under it
--   80-520  a gem flies in an arc from the balance into the stud of its grade
--    520  ice: the stud lights, ice cracks run along the bar, a blue ring grows;
--         the piece's image flares with frost and jumps
--  560-950  a blue wave runs over the card, left to right
--  700-1150  the signature's name lights up letter by letter
--  950-1400  its value counts up and jumps at the end; the cracks melt
--
--   local sign_light = require "ui.sign_light"
--   local sl = sign_light.new({ bar =, lit =, wallet =, cost =, icon =, name =,
--     lines =, from =, to =, card = { g =, x =, y =, w =, h = } })
--   sign_light.update(sl, dt) -> true while it runs
--   sign_light.delete(sl)

local ui = require "ui.ui"
local kit = require "ui.kit"
local coins = require "ui.coins"
local T = require("lang.text").armory

local M = {}
local KC = kit.C

M.FLY, M.HIT, M.WAVE, M.NAME, M.COUNT, M.END = 0.08, 0.52, 0.56, 0.70, 0.95, 1.6
local FROST = vmath.vector4(0.79, 0.94, 0.97, 1)

local function vec(x, y) return vmath.vector3(x, y, 0) end
local function clamp(x) return math.max(0, math.min(1, x)) end
local function seg(t, a, b) return clamp((t - a) / (b - a)) end
local function eo(k) return 1 - (1 - k) ^ 3 end

local function alpha(n, a)
	local c = gui.get_color(n)
	c.w = a
	gui.set_color(n, c)
end

local function pop(n, k, t, delay)
	local sc = gui.get_scale(n)
	gui.set_scale(n, sc * k)
	gui.animate(n, "scale", sc, gui.EASING_OUTBACK, t or 0.3, delay or 0)
end

-- n chips of ice out of p (root coordinates), d far
local function chips(sl, p, n, d, color)
	for i = 1, n do
		local a = (i - 0.5) * 2 * math.pi / n + 0.4
		local r = d * (0.6 + 0.4 * ((i * 7) % 5) / 4)
		local c = ui.sagoma("forma", p.x, p.y, 14, 5, color, nil)
		gui.set_slice9(c, vmath.vector4(2, 2, 2, 2))
		gui.set_rotation(c, vmath.vector3(0, 0, math.deg(a)))
		gui.animate(c, "position", p + vec(math.cos(a) * r, math.sin(a) * r), gui.EASING_OUTQUAD, 0.4)
		gui.animate(c, "color.w", 0, gui.EASING_INQUAD, 0.4, 0, function() gui.delete_node(c) end)
		sl.nodes[#sl.nodes + 1] = c
	end
end

function M.new(o)
	local sl = { o = o, t = 0, nodes = {}, fired = {} }
	local stud = o.bar.studs[o.lit]
	sl.lit = o.bar.lit_parts[o.lit] or {}
	sl.to = gui.get_screen_position(stud)
	-- the stud is dark until the gem arrives
	for _, n in ipairs(sl.lit) do gui.set_enabled(n, false) end
	-- the balance flashes, −cost under it
	local w = o.wallet
	if w and w.icons and w.icons.ossidiana then
		sl.from = gui.get_screen_position(w.icons.ossidiana)
		local tx = w.text.ossidiana
		gui.set_color(tx, KC.OBSIDIAN)
		gui.animate(tx, "color", KC.SAND, gui.EASING_OUTQUAD, 0.5, 0.15)
		pop(tx, 1.3, 0.3)
		if o.cost then
			-- over everything, under the balance
			local m = kit.text({ node = nil, ox = 0, oy = 0 }, T.sign_spent:format(coins.format(o.cost)), sl.from.x + 34, -(sl.from.y - 58), 30, KC.OBSIDIAN, "middle")
			gui.animate(m, "position.y", gui.get_position(m).y - 24, gui.EASING_OUTQUAD, 0.9)
			gui.animate(m, "color.w", 0, gui.EASING_INQUAD, 0.4, 0.6)
			sl.nodes[#sl.nodes + 1] = m
		end
	else
		sl.from = sl.to + vec(260, 300)
	end
	-- the gem that flies
	sl.gem = coins.icon("ossidiana", sl.from.x, sl.from.y, 52, nil)
	gui.set_scale(sl.gem, vmath.vector3(0.01, 0.01, 1))
	gui.animate(sl.gem, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, 0.1)
	sl.nodes[#sl.nodes + 1] = sl.gem
	sl.glow = ui.sagoma("alone", sl.from.x, sl.from.y, 90, 90, kit.with_alpha(KC.OBSIDIAN, 0.6), nil)
	gui.set_blend_mode(sl.glow, gui.BLEND_ADD)
	sl.nodes[#sl.nodes + 1] = sl.glow
	-- the wave over the card, the frost on the piece, the ring, the cracks (hidden)
	local c = o.card
	local cy = c.g.oy - (c.y + c.h / 2)
	sl.wave = ui.sagoma("alone", c.x - c.g.ox, cy, 200, c.h, kit.with_alpha(FROST, 0), c.g.node)
	gui.set_blend_mode(sl.wave, gui.BLEND_ADD)
	sl.wave_x0, sl.wave_x1 = c.x - c.g.ox, c.x + c.w - c.g.ox
	sl.nodes[#sl.nodes + 1] = sl.wave
	if o.icon then
		sl.frost = ui.sagoma("alone", 0, 0, 320, 320, kit.with_alpha(FROST, 0), o.icon)
		gui.set_blend_mode(sl.frost, gui.BLEND_ADD)
		sl.nodes[#sl.nodes + 1] = sl.frost
	end
	sl.ring = ui.sagoma("anello_050", sl.to.x, sl.to.y, 60, 60, kit.with_alpha(FROST, 0), nil)
	sl.nodes[#sl.nodes + 1] = sl.ring
	sl.cracks = {}
	for i = 1, 6 do
		local a = ({ 8, 172, -14, 194, 30, 150 })[i]
		local len = ({ 120, 110, 70, 64, 40, 36 })[i]
		local r = math.rad(a)
		local n = ui.sagoma("forma", sl.to.x + math.cos(r) * len / 2, sl.to.y + math.sin(r) * len / 2, len, 4, kit.with_alpha(FROST, 0), nil)
		gui.set_slice9(n, vmath.vector4(1, 1, 1, 1))
		gui.set_rotation(n, vmath.vector3(0, 0, a))
		sl.cracks[i] = n
		sl.nodes[#sl.nodes + 1] = n
	end
	-- the name: a grey copy under it, the lit letters come over it one by one
	if o.name then
		sl.name_text = gui.get_text(o.name)
		sl.name_grey = gui.clone(o.name)
		gui.set_color(sl.name_grey, KC.MUTE)
		gui.move_below(sl.name_grey, o.name)
		sl.nodes[#sl.nodes + 1] = sl.name_grey
		gui.set_text(o.name, "")
		sl.name_color = gui.get_color(o.name)
	end
	-- the lines with the value: they count from the old one
	sl.count = {}
	for _, l in ipairs(o.lines or {}) do
		local txt = gui.get_text(l)
		local at = txt:find(tostring(o.to) .. "%", 1, true)
		if at then sl.count[#sl.count + 1] = { node = l, text = txt, at = at } end
	end
	M.update(sl, 0)
	return sl
end

local function set_count(sl, v)
	local s = tostring(sl.o.to)
	for _, c in ipairs(sl.count) do
		gui.set_text(c.node, c.text:sub(1, c.at - 1) .. tostring(v) .. c.text:sub(c.at + #s))
	end
end

function M.update(sl, dt)
	sl.t = sl.t + dt
	local t = sl.t
	local function once(id, at)
		if t >= at and not sl.fired[id] then sl.fired[id] = true; return true end
	end
	-- the flight: x eases out, y eases in, it shrinks entering
	if t < M.HIT then
		local k = seg(t, M.FLY, M.HIT)
		local x = sl.from.x + (sl.to.x - sl.from.x) * (1 - (1 - k) ^ 2)
		local y = sl.from.y + (sl.to.y - sl.from.y) * k * k + math.sin(k * math.pi) * 60
		gui.set_position(sl.gem, vec(x, y))
		gui.set_position(sl.glow, vec(x, y))
		if k > 0.6 then
			local s = 1 - 0.5 * (k - 0.6) / 0.4
			gui.set_scale(sl.gem, vmath.vector3(s, s, 1))
		end
		-- a trail of frost
		if k > 0 and math.floor(t * 40) ~= sl.trail then
			sl.trail = math.floor(t * 40)
			local d = ui.sagoma("alone", x, y, 22, 22, kit.with_alpha(FROST, 0.8), nil)
			gui.set_blend_mode(d, gui.BLEND_ADD)
			gui.animate(d, "color.w", 0, gui.EASING_OUTQUAD, 0.3, 0, function() gui.delete_node(d) end)
			gui.animate(d, "scale", vmath.vector3(0.2, 0.2, 1), gui.EASING_INQUAD, 0.3)
			sl.nodes[#sl.nodes + 1] = d
		end
	end
	if once("hit", M.HIT) then
		gui.set_enabled(sl.gem, false)
		gui.set_enabled(sl.glow, false)
		for _, n in ipairs(sl.lit) do gui.set_enabled(n, true) end
		pop(sl.o.bar.studs[sl.o.lit], 2.2, 0.45)
		chips(sl, sl.to, 12, 70, FROST)
		chips(sl, sl.to, 6, 40, KC.OBSIDIAN)
		sound.play("#xp", { speed = 1.6 })
		sound.play("#livello", { speed = 1.5, gain = 0.6 })
		-- the piece takes the frost
		if sl.o.icon then pop(sl.o.icon, 1.18, 0.5) end
	end
	-- the ring and the cracks
	local rk = seg(t, M.HIT, M.HIT + 0.45)
	alpha(sl.ring, (t >= M.HIT and rk < 1) and (1 - rk) or 0)
	local rs = 1 + 5 * eo(rk)
	gui.set_scale(sl.ring, vmath.vector3(rs, rs, 1))
	local ca = t < M.HIT and 0 or (t < 1.2 and 0.9 or 0.9 * (1 - seg(t, 1.2, 1.5)))
	for i, n in ipairs(sl.cracks) do
		local grow = eo(seg(t, M.HIT + (i - 1) * 0.02, M.HIT + 0.12 + (i - 1) * 0.02))
		alpha(n, ca)
		gui.set_scale(n, vmath.vector3(grow, 1, 1))
	end
	if sl.frost then
		alpha(sl.frost, t >= M.HIT and 0.95 * math.exp(-(t - M.HIT) / 0.45) or 0)
	end
	-- the wave
	local wk = seg(t, M.WAVE, M.WAVE + 0.39)
	alpha(sl.wave, (t >= M.WAVE and wk < 1) and 0.55 * math.sin(wk * math.pi) or 0)
	gui.set_position(sl.wave, vec(sl.wave_x0 + (sl.wave_x1 - sl.wave_x0) * eo(wk), gui.get_position(sl.wave).y))
	-- the name, letter by letter (the frost first, then its own color)
	if sl.name_text and t >= M.NAME then
		local nk = seg(t, M.NAME, M.NAME + 0.45)
		local len = #sl.name_text
		local shown = math.floor(nk * len + 0.5)
		-- never cut a letter of more than one byte in half
		while shown < len and shown > 0 and sl.name_text:byte(shown + 1) >= 0x80 and sl.name_text:byte(shown + 1) < 0xC0 do
			shown = shown + 1
		end
		gui.set_text(sl.o.name, sl.name_text:sub(1, shown))
		if nk < 1 then
			gui.set_color(sl.o.name, FROST)
		elseif once("name", M.NAME + 0.45) then
			gui.set_enabled(sl.name_grey, false)
			gui.animate(sl.o.name, "color", sl.name_color, gui.EASING_OUTQUAD, 0.4)
			pop(sl.o.name, 1.2, 0.3)
		end
	end
	-- the value counts up, then jumps
	if #sl.count > 0 then
		local vk = seg(t, M.COUNT, M.COUNT + 0.4)
		set_count(sl, math.floor(sl.o.from + (sl.o.to - sl.o.from) * eo(vk) + 0.5))
		if once("value", M.COUNT + 0.4) then
			for _, c in ipairs(sl.count) do
				gui.set_color(c.node, FROST)
				gui.animate(c.node, "color", KC.SAND, gui.EASING_OUTQUAD, 0.5, 0.1)
				pop(c.node, 1.2, 0.3)
			end
			sound.play("#scaglia", { speed = 1.4 })
		end
	end
	return t < M.END
end

-- the end at once: everything where it stays
function M.finish(sl)
	sl.t = M.END
	M.update(sl, 0)
	for _, n in ipairs(sl.lit) do gui.set_enabled(n, true) end
	if sl.name_text then
		gui.set_text(sl.o.name, sl.name_text)
		gui.set_color(sl.o.name, sl.name_color)
	end
	set_count(sl, sl.o.to)
end

function M.delete(sl)
	for _, n in ipairs(sl.nodes) do
		pcall(gui.delete_node, n)
	end
	sl.nodes = {}
end

return M
