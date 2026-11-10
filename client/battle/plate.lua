-- The plate above the Scoria in battle: the name, with no tag behind it, above a
-- plain bar of health in the team color on a dark background, and the golden
-- Crown of card WB-011 (Sergio, 3 Nov: «ancora più minimali e leggibili ... hanno
-- un livello di dettaglio che fa perdere il focus dal personaggio»; the steel
-- blade of the same day is gone). The Crown is cut by strumenti/grafica/targa.py
-- from the ChatGPT sheet; the font is the interface's (ui/ui.lua). Damage shows in two
-- steps: health drops at once, the lost piece turns white, grows with every
-- consecutive hit and wears away gradually once the hits stop; the bar jolts. Below 30% health pulses. The shield,
-- if any, is a light stretch after the health.
--
--   local tt = targa.nuove(palette, name_list)  -- one plate per color, all together
--   targa.vita(t, vita, maximum, scudo)   -- when it changes (scudo may be missing)
--   targa.update(t, dt, x, y, scale)      -- every frame: x, y is the bottom center (in
--                                          the world)
--   targa.scala(cam)                      -- the scale to give update: the plate stays
--                                          -- the same size on screen at every zoom
--   targa.set_enabled(t, on) / targa.nome(t, nome) / targa.colore(t, colore)
--   targa.stato(t, txt)                   -- the effects on it, under the bar ("" = nothing)
--   targa.announcement(t, txt)            -- a label that rises above the name and fades
--   targa.battuta(t, txt, strong)         -- a bot's comment over its head for a while
--                                          (Sergio, 4 Nov: plain text, no strip); it
--                                          doesn't cover one just said unless strong
--   targa.posto(t, txt, crown)            -- the standings place left of the bar
--                                          -- ("" = nothing) and the Crown beside the name
--   targa.sopra(t)                        -- where the plate ends at the top (units at scale 1)
--
-- The arrow of whoever's turn it is: a solid V in the team color with a dark
-- border (Sergio, 3 Nov, instead of the iron arrow of card WB-010), just one for
-- the whole match, above the name, bobbing.
--   local f = targa.arrow()               -- f.radice goes in the scene between the bars and the texts
--   targa.arrow_up(f, t)                  -- every frame, before targa.update: on t (nil = off)
--   targa.arrow_color(f, color)           -- the V's color (the arrows above the points)
--
-- Each plate has two roots, t.bars and t.texts, that move together. The GUI
-- draws nodes in the order they are in: whoever puts them in the scene puts
-- first the bars of all plates, then the arrow and then all the texts, so two
-- draw calls are enough for all of them: the battle atlas images (health, Crown
-- and arrow: the rectangles are targa_bianco tinted), then
-- the font. We don't use GUI layers because they would draw the plates above
-- buttons and menus.

local ui = require "ui.ui"

local M = {}

local max = math.max

-- sizes in GUI units at scale 1: the health is W wide and H tall, on a dark
-- background BORDER wider on each side
local W, H, BORDER = 40, 5, 1
local BASE = H / 2 + BORDER   -- from the bottom point of the plate to the center of the bar
local NAME_Y = BASE + 6.5     -- center of the name above the bar
local BAR_BG = vmath.vector4(0.04, 0.03, 0.05, 0.9)
-- scale of the "titolo" font (scale 1 = about 40 px)
local NAME_SCALE, NUMBER_SCALE, STATE_SCALE, BANNER_SCALE = 0.25, 0.2, 0.18, 0.3
local STATE_Y, BANNER_Y, BANNER_RISE, BANNER_T = -(BASE + 4), 22, 14, 1.4
-- a bot's comment: above the turn arrow, for QUIP_T seconds (the last
-- QUIP_FADE fading); a new one covers it only after QUIP_KEEP seconds
local QUIP_Y, QUIP_SCALE, QUIP_T, QUIP_FADE, QUIP_KEEP = 42, 0.38, 2.6, 0.4, 0.8
-- The plate stays the same size on screen at every zoom (Sergio, 3 Nov: from
-- far away it must not be bigger than the character): scale ON_SCREEN / zoom
-- (0.85 until Sergio found it «ancora un po' piccolo», 3 Nov)
local ON_SCREEN = 1.1
-- the first one's Crown on the name's line, on the left (Sergio, 3 Nov, choice L1:
-- the plate stays low), CROWN_W wide and CROWN_H tall like the image (108 x 59)
local CROWN_W, CROWN_GAP = 13.5, 2
local CROWN_H = CROWN_W * 59 / 108
-- where the name ends at the top
local NAME_TOP = NAME_Y + 6
-- the arrow: a V ARROW_W wide and ARROW_H tall (two bars at 45 degrees, the
-- dark border ARROW_EDGE thicker), ARROW_GAP above the name (in the node that
-- jolts with a hit, like the name); it bobs ARROW_BOB up and down every ARROW_T seconds
local ARROW_W, ARROW_H, ARROW_BAR, ARROW_LEN, ARROW_EDGE = 18, 12, 3.5, 11, 3
local ARROW_GAP, ARROW_BOB, ARROW_T = 3, 1.5, 1.4

-- the lost health: pure white from the first instant (Sergio, 9 Nov), it stays
-- TRAIL_WAIT seconds after the last hit (each new hit restarts the wait and
-- widens the white piece), then drains at TRAIL_SPEED of the bar per second
local TRAIL = vmath.vector4(1, 1, 1, 1)
local TRAIL_WAIT, TRAIL_SPEED = 0.7, 0.5
local SHIELD = vmath.vector4(0.75, 0.86, 1, 1)

local V = vmath.vector3(0, 0, 0)
local C = vmath.vector4(1, 1, 1, 1)

-- an image from the battle atlas, w x h big
local function image(parent, nome, x, y, w, h)
	local n = gui.new_box_node(vmath.vector3(x, y, 0), vmath.vector3(w, h, 0))
	gui.set_texture(n, "battaglia")
	gui.play_flipbook(n, nome)
	gui.set_adjust_mode(n, gui.ADJUST_FIT)
	gui.set_parent(n, parent)
	gui.set_inherit_alpha(n, true)
	return n
end

-- a filled rectangle: targa_bianco tinted (so it stays in the images' draw call)
local function rect(parent, x, y, w, h, color)
	local n = image(parent, "targa_bianco", x, y, w, h)
	gui.set_color(n, color)
	return n
end

local function txt(parent, x, y, s, scale, color)
	local n = gui.new_text_node(vmath.vector3(x, y, 0), s)
	gui.set_parent(n, parent)
	gui.set_inherit_alpha(n, true)
	gui.set_font(n, "titolo")
	gui.set_color(n, color)
	gui.set_outline(n, ui.C.SHADOW)
	gui.set_scale(n, vmath.vector3(scale, scale, 1))
	return n
end

-- a piece of the bar: starts at the left edge, w wide (from x)
local function piece(t, color)
	local n = rect(t.dentro, -W / 2, 0, 0, H, color)
	gui.set_pivot(n, gui.PIVOT_W)
	return n
end

local function span(n, x, w)
	gui.set_enabled(n, w > 0.05)
	V.x, V.y, V.z = -W / 2 + x, 0, 0
	gui.set_position(n, V)
	V.x, V.y = w, H
	gui.set_size(n, V)
end

-- an invisible root node following the Scoria, holding the node that jolts
local function root_node()
	local r = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(0, 0, 0))
	gui.set_visible(r, false)
	gui.set_adjust_mode(r, gui.ADJUST_FIT)
	local d = gui.new_box_node(vmath.vector3(0, BASE, 0), vmath.vector3(0, 0, 0))
	gui.set_parent(d, r)
	gui.set_inherit_alpha(d, true)
	gui.set_visible(d, false)
	return r, d
end

-- the Crown left of the name: it depends on how wide it is
local function crown_spot(t)
	local font = gui.get_font_resource(gui.get_font(t.nome))
	local w = resource.get_text_metrics(font, gui.get_text(t.nome)).width * NAME_SCALE
	V.x, V.y, V.z = -w / 2 - CROWN_GAP - CROWN_W / 2, NAME_Y, 0
	gui.set_position(t.crown, V)
end

function M.create(palette, name_list)
	local tt = {}
	-- first the bars of all plates
	for i, color in ipairs(palette) do
		local t = { colore = vmath.vector4(color.x, color.y, color.z, 1), hp_f = 1, trail_f = 1,
			shield_f = 0, max_f = 1, attesa = 0, colpo = 0, t = 0, banner_t = 0 }
		t.bars, t.dentro = root_node()
		rect(t.dentro, 0, 0, W + 2 * BORDER, H + 2 * BORDER, BAR_BG)
		t.trail = piece(t, TRAIL)
		t.scudo = piece(t, SHIELD)
		t.full = piece(t, color)
		t.crown = image(t.dentro, "targa_corona", 0, NAME_Y, CROWN_W, CROWN_H)
		gui.set_enabled(t.crown, false)
		tt[i] = t
	end
	-- then the texts
	for i, t in ipairs(tt) do
		t.texts, t.inside_texts = root_node()
		t.nome = txt(t.inside_texts, 0, NAME_Y, name_list[i] or "", NAME_SCALE, t.colore)
		t.numero = txt(t.inside_texts, W / 2 + BORDER + 3, 0, "", NUMBER_SCALE, ui.C.TEXT)
		gui.set_pivot(t.numero, gui.PIVOT_W)
		t.posto = txt(t.inside_texts, -W / 2 - BORDER - 3, 0, "", NUMBER_SCALE, ui.C.TEXT)
		gui.set_pivot(t.posto, gui.PIVOT_E)
		t.stato = txt(t.inside_texts, 0, STATE_Y, "", STATE_SCALE, ui.C.TEXT)
		t.announcement = txt(t.inside_texts, 0, BANNER_Y, "", BANNER_SCALE, ui.C.LIGHT)
		gui.set_enabled(t.announcement, false)
		t.quip = txt(t.inside_texts, 0, QUIP_Y, "", QUIP_SCALE, ui.C.LIGHT)
		gui.set_enabled(t.quip, false)
		t.quip_t = 0
		M.hp(t, 1, 1)
		crown_spot(t)
	end
	return tt
end

function M.name(t, nome)
	gui.set_text(t.nome, nome)
	crown_spot(t)
end

function M.scale(cam)
	return ON_SCREEN / cam.s
end

-- the team color (changes from one match to the next)
function M.color(t, color)
	t.colore.x, t.colore.y, t.colore.z = color.x, color.y, color.z
	gui.set_color(t.nome, t.colore)
end

function M.status(t, s)
	gui.set_text(t.stato, s)
end

function M.rank(t, s, crown)
	gui.set_text(t.posto, s)
	gui.set_enabled(t.crown, crown)
end

-- where the plate ends at the top, arrow included (units at scale 1, from the
-- bottom center): the marker of the turn sits above it
function M.above(t)
	return max(NAME_TOP, t.arrow_top or 0)
end

function M.announcement(t, s)
	gui.set_text(t.announcement, s)
	gui.set_enabled(t.announcement, true)
	t.banner_t = BANNER_T
end

function M.quip(t, s, strong)
	if t.quip_t > QUIP_T - QUIP_KEEP and not strong then return end
	gui.set_text(t.quip, s)
	gui.set_enabled(t.quip, true)
	t.quip_t = QUIP_T
end

function M.set_enabled(t, on)
	gui.set_enabled(t.bars, on)
	gui.set_enabled(t.texts, on)
end

-- health and shield in points; the bar counts up to maximum, or to health + shield if more
function M.hp(t, hp_value, maximum, shield)
	hp_value, shield = max(0, hp_value), max(0, shield or 0)
	local tot = max(maximum, hp_value + shield)
	local f = hp_value / tot
	if f < t.hp_f - 1e-6 then
		-- hit: the trail starts from where health was (if it wasn't already higher)
		t.trail_f = max(t.trail_f, t.hp_f)
		t.attesa = TRAIL_WAIT
		t.colpo = 1
	elseif f > t.trail_f then
		t.trail_f = f
	end
	t.hp_f, t.shield_f, t.max_f = f, shield / tot, maximum / tot
	gui.set_text(t.numero, tostring(math.floor(hp_value + 0.5)))
end

local arrow_update -- further down, with the arrow

function M.update(t, dt, x, y, scale)
	t.t = t.t + dt
	t.x, t.y, t.scala = x, y, scale
	V.x, V.y, V.z = x, y, 0
	gui.set_position(t.bars, V)
	gui.set_position(t.texts, V)
	V.x, V.y, V.z = scale, scale, 1
	gui.set_scale(t.bars, V)
	gui.set_scale(t.texts, V)
	-- the trail waits a moment and then wears down to the health
	if t.attesa > 0 then
		t.attesa = t.attesa - dt
	elseif t.trail_f > t.hp_f then
		t.trail_f = max(t.hp_f, t.trail_f - dt * TRAIL_SPEED)
	end
	-- jolt of the hit
	t.colpo = max(0, t.colpo - dt * 5)
	local k = 1 + 0.25 * t.colpo
	V.x, V.y, V.z = k, k, 1
	gui.set_scale(t.dentro, V)
	gui.set_scale(t.inside_texts, V)
	if t.arrow then arrow_update(t.arrow, t, dt, k) end

	-- the announcement rises and fades
	if t.banner_t > 0 then
		t.banner_t = t.banner_t - dt
		local f = 1 - max(0, t.banner_t) / BANNER_T
		V.x, V.y, V.z = 0, BANNER_Y + BANNER_RISE * f, 0
		gui.set_position(t.announcement, V)
		C.x, C.y, C.z, C.w = ui.C.LIGHT.x, ui.C.LIGHT.y, ui.C.LIGHT.z, math.min(1, 3 * (1 - f))
		gui.set_color(t.announcement, C)
		if t.banner_t <= 0 then gui.set_enabled(t.announcement, false) end
	end

	-- the comment stays, then fades
	if t.quip_t > 0 then
		t.quip_t = t.quip_t - dt
		C.x, C.y, C.z, C.w = ui.C.LIGHT.x, ui.C.LIGHT.y, ui.C.LIGHT.z, math.min(1, max(0, t.quip_t) / QUIP_FADE)
		gui.set_color(t.quip, C)
		if t.quip_t <= 0 then gui.set_enabled(t.quip, false) end
	end

	span(t.trail, 0, W * t.trail_f)
	span(t.full, 0, W * t.hp_f)
	span(t.scudo, W * t.hp_f, W * t.shield_f)

	-- health color: white on a hit, pulsing when low
	local white = t.colpo
	if t.hp_f > 0 and t.hp_f < 0.3 * t.max_f then
		white = max(white, 0.3 + 0.3 * math.sin(t.t * 9))
	end
	local c = t.colore
	C.x, C.y, C.z, C.w = c.x + (1 - c.x) * white, c.y + (1 - c.y) * white, c.z + (1 - c.z) * white, 1
	gui.set_color(t.full, C)
end

-- the arrow: two bars of targa_bianco at 45 degrees in a V, first the dark
-- border (thicker and longer) and then the team color on top; ARROW_W wide
local ARROW_SIDE = ARROW_W * 0.18  -- how far each bar's center is from the middle

local function arrow_bars(f, thick, len, color, list)
	for _, side in ipairs({ -1, 1 }) do
		local n = rect(f.radice, side * ARROW_SIDE, 0, thick, len, color)
		gui.set_euler(n, vmath.vector3(0, 0, -side * 45))
		if list then list[#list + 1] = n end
	end
end

function M.arrow()
	local f = { t = 0, w = ARROW_W, h = ARROW_H, color_nodes = {} }
	f.radice = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(0, 0, 0))
	gui.set_visible(f.radice, false)
	gui.set_adjust_mode(f.radice, gui.ADJUST_FIT)
	arrow_bars(f, ARROW_BAR + ARROW_EDGE, ARROW_LEN + ARROW_EDGE, BAR_BG)
	arrow_bars(f, ARROW_BAR, ARROW_LEN, ui.C.LIGHT, f.color_nodes)
	gui.set_enabled(f.radice, false)
	return f
end

function M.arrow_color(f, color)
	for _, n in ipairs(f.color_nodes) do gui.set_color(n, color) end
end

-- the arrow's center above the name (in the node that jolts)
local function arrow_base(f)
	return NAME_TOP + ARROW_GAP + f.h / 2
end

-- the arrow goes on t (the plate of whoever's turn it is, nil = nobody): before
-- targa.update, which puts it in place, so the tag and the quips already know it
function M.arrow_up(f, t)
	if f.su ~= t then
		if f.su then f.su.arrow, f.su.arrow_top = nil, nil end
		f.su = t
		gui.set_enabled(f.radice, t ~= nil)
	end
	if not t then return end
	t.arrow = f
	t.arrow_top = BASE + arrow_base(f) + f.h / 2 + ARROW_BOB
end

-- in targa.update, with the hit's jolt (k) like the name and the Crown. At the
-- top it bobs gently with the ember dim, at the bottom it is lit
arrow_update = function(f, t, dt, k)
	f.t = (f.t + dt) % ARROW_T
	local c = math.cos(f.t / ARROW_T * 2 * math.pi)
	V.x, V.y, V.z = t.x, t.y + (BASE + (arrow_base(f) + ARROW_BOB * c) * k) * t.scala, 0
	gui.set_position(f.radice, V)
	V.x, V.y, V.z = t.scala * k, t.scala * k, 1
	gui.set_scale(f.radice, V)
	M.arrow_color(f, t.colore)
end

return M
