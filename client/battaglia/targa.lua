-- The plate above the Scoria in battle: the name, with no tag behind it, above a
-- thin steel blade with the health running in its groove, in the team color
-- (style C of card WB-011, "lama incisa", Sergio's choice of 3 Nov, with its
-- golden Crown). The images are cut by strumenti/grafica/targa.py from the
-- ChatGPT sheet; the font is the interface's (ui/ui.lua). Damage shows in two
-- steps: health drops at once, the lost piece stays white for a moment and then
-- wears away; the bar jolts and flashes. Below 30% health pulses. The shield,
-- if any, is a light stretch after the health.
--
--   local tt = targa.nuove(palette, name_list)  -- one plate per color, all together
--   targa.vita(t, vita, maximum, scudo)   -- when it changes (scudo may be missing)
--   targa.update(t, dt, x, y, scale, cam) -- every frame: x, y is the bottom center (in
--                                          the world); cam (battaglia/camera.lua) for the line
--   targa.scala(cam)                      -- the scale to give update: the plate stays
--                                          -- the same size on screen at every zoom
--   targa.set_enabled(t, on) / targa.nome(t, nome) / targa.colore(t, colore)
--   targa.stato(t, txt)                   -- the effects on it, under the bar ("" = nothing)
--   targa.announcement(t, txt)            -- a label that rises above the name and fades
--   targa.riga(t, txt)                    -- the missions' hint, above everything ("" = nothing)
--   targa.quip(t, txt)                    -- what the character says: a bubble that
--                                          -- stays a couple of seconds and fades
--   targa.posto(t, txt, crown)            -- the standings place left of the bar
--                                          -- ("" = nothing) and the Crown beside the name
--   targa.sopra(t)                        -- where the plate ends at the top (units at scale 1)
--
-- The iron arrow of whoever's turn it is (card WB-010, Sergio's choice of 2 Nov):
-- just one for the whole match, above the name, bobbing,
-- with the ember in the team color pulsing (brighter at the bottom).
--   local f = targa.arrow()               -- f.radice goes in the scene between the bars and the texts
--   targa.arrow_up(f, t)                  -- every frame, before targa.update: on t (nil = off)
--
-- Each plate has two roots, t.bars and t.texts, that move together. The GUI
-- draws nodes in the order they are in: whoever puts them in the scene puts
-- first the bars of all plates, then the arrow and then all the texts, so two
-- draw calls are enough for all of them: the battle atlas images (blade, health,
-- Crown, quip background and arrow: the rectangles use targa_bianco too), then
-- the font. We don't use GUI layers because they would draw the plates above
-- buttons and menus.

local ui = require "ui.ui"
local screen = require "ui.schermo"
local camera = require "battaglia.camera"

local M = {}

local max = math.max

-- sizes in GUI units at scale 1. The health is W wide and H tall; the blade is
-- BLADE_H tall, starts FIRST before the health (the hilt) and ends AFTER it (the
-- tip), and the health sits BAR_UP above its center. The image has BLADE_PX pixels
-- per unit and stretches only between the BLADE_LEFT and BLADE_RIGHT edges
-- (pixels): sizes from strumenti/grafica/targa.py
local W = 36
local H, BLADE_H, FIRST, AFTER, BAR_UP = 2.59, 9, 8.44, 12.6, 0.39
local BLADE_PX, BLADE_LEFT, BLADE_RIGHT = 4, 47, 92
local BASE = BLADE_H / 2     -- from the bottom point of the plate to the center of the blade
local NAME_Y = BLADE_H / 2 + 6 -- center of the name above the blade
-- scale of the "titolo" font (scale 1 = about 40 px)
local NAME_SCALE, NUMBER_SCALE, STATE_SCALE, BANNER_SCALE = 0.25, 0.2, 0.18, 0.3
local STATE_Y, BANNER_Y, BANNER_RISE, BANNER_T = -(BLADE_H / 2 + 4), 22, 14, 1.4
-- The plate stays the same size on screen at every zoom (Sergio, 3 Nov: from
-- far away it must not be bigger than the character): scale ON_SCREEN / zoom
local ON_SCREEN = 0.85
-- the first one's Crown on the name's line, on the left (Sergio, 3 Nov, choice L1:
-- the plate stays low), CROWN_W wide and CROWN_H tall like the image (108 x 59)
local CROWN_W, CROWN_GAP = 13.5, 2
local CROWN_H = CROWN_W * 59 / 108
-- where the name ends at the top
local NAME_TOP = NAME_Y + 6
-- the iron arrow: ARROW_W wide (as tall as the image says), ARROW_GAP
-- above the name (in the node that jolts with a hit, like the name);
-- it bobs ARROW_BOB up and down every ARROW_T seconds
local ARROW_W = 18
local ARROW_GAP, ARROW_BOB, ARROW_T = 3, 1.5, 1.4
-- the missions' line: above the Crown and the rising announcements, wrapping
-- past ROW_W; ROW_SCALE big on screen at every zoom (about 22 px: with the
-- camera far away it doesn't shrink like the rest of the plate). It doesn't
-- leave the sides of the screen: with the robot near an edge it moves toward the center
local LINE_GAP, ROW_SCALE, ROW_W, ROW_SIDE = 13, 0.55, 1640, 16
-- and it doesn't climb up to the points and the goal at the top
-- (battaglia/punteggio.lua): with the robot high up it comes down, above the robot
local ROW_TOP = 130
-- the quip bubble: above the name, QUIP_SCALE big on screen at every zoom,
-- with the dark background around it (QUIP_BORDER px)
-- (QUIP_GAP above the name, or ARROW_ABOVE above the arrow)
local QUIP_GAP, QUIP_SCALE, QUIP_BORDER, QUIP_T = 2, 0.42, 8, 2.6
local ARROW_ABOVE = 2
local CLOUD = vmath.vector4(0.06, 0.05, 0.08, 0.82)

local TRAIL = ui.C.LIGHT
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
	local n = rect(t.dentro, -W / 2, BAR_UP, 0, H, color)
	gui.set_pivot(n, gui.PIVOT_W)
	return n
end

local function span(n, x, w)
	gui.set_enabled(n, w > 0.05)
	V.x, V.y, V.z = -W / 2 + x, BAR_UP, 0
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

function M.nuove(palette, name_list)
	local tt = {}
	-- first the bars of all plates
	for i, color in ipairs(palette) do
		local t = { colore = vmath.vector4(color.x, color.y, color.z, 1), hp_f = 1, trail_f = 1,
			shield_f = 0, max_f = 1, attesa = 0, colpo = 0, t = 0, banner_t = 0 }
		t.bars, t.dentro = root_node()
		-- the blade: it stretches only in the middle (slice9 in image pixels,
		-- which is why it is BLADE_PX times bigger and scaled down)
		local blade_w = FIRST + W + AFTER
		local blade = image(t.dentro, "targa_lama", (AFTER - FIRST) / 2, 0, blade_w * BLADE_PX, BLADE_H * BLADE_PX)
		gui.set_slice9(blade, vmath.vector4(BLADE_LEFT, 0, BLADE_RIGHT, 0))
		gui.set_scale(blade, vmath.vector3(1 / BLADE_PX, 1 / BLADE_PX, 1))
		t.trail = piece(t, TRAIL)
		t.scudo = piece(t, SHIELD)
		t.full = piece(t, color)
		t.crown = image(t.dentro, "targa_corona", 0, NAME_Y, CROWN_W, CROWN_H)
		gui.set_enabled(t.crown, false)
		-- the bubble background, with the shapes (outside the node that jolts)
		t.nuvola = rect(t.bars, 0, 0, 0, 0, CLOUD)
		gui.set_pivot(t.nuvola, gui.PIVOT_S)
		gui.set_enabled(t.nuvola, false)
		t.quip_t = 0
		tt[i] = t
	end
	-- then the texts
	for i, t in ipairs(tt) do
		t.texts, t.inside_texts = root_node()
		t.nome = txt(t.inside_texts, 0, NAME_Y, name_list[i] or "", NAME_SCALE, t.colore)
		t.numero = txt(t.inside_texts, W / 2 + AFTER + 2, 0, "", NUMBER_SCALE, ui.C.TEXT)
		gui.set_pivot(t.numero, gui.PIVOT_W)
		t.posto = txt(t.inside_texts, -W / 2 - FIRST - 2, 0, "", NUMBER_SCALE, ui.C.TEXT)
		gui.set_pivot(t.posto, gui.PIVOT_E)
		t.stato = txt(t.inside_texts, 0, STATE_Y, "", STATE_SCALE, ui.C.TEXT)
		t.announcement = txt(t.inside_texts, 0, BANNER_Y, "", BANNER_SCALE, ui.C.LIGHT)
		gui.set_enabled(t.announcement, false)
		t.riga = txt(t.texts, 0, 0, "", ROW_SCALE, ui.C.LIGHT)
		gui.set_pivot(t.riga, gui.PIVOT_S)
		gui.set_line_break(t.riga, true)
		gui.set_size(t.riga, vmath.vector3(ROW_W, 0, 0))
		t.row_text, t.row_h = "", 0
		t.quip = txt(t.texts, 0, 0, "", QUIP_SCALE, ui.C.TEXT)
		gui.set_pivot(t.quip, gui.PIVOT_S)
		gui.set_enabled(t.quip, false)
		M.vita(t, 1, 1)
		crown_spot(t)
	end
	return tt
end

function M.nome(t, nome)
	gui.set_text(t.nome, nome)
	crown_spot(t)
end

function M.scala(cam)
	return ON_SCREEN / cam.s
end

-- the team color (changes from one match to the next)
function M.colore(t, color)
	t.colore.x, t.colore.y, t.colore.z = color.x, color.y, color.z
	gui.set_color(t.nome, t.colore)
end

function M.stato(t, s)
	gui.set_text(t.stato, s)
end

function M.posto(t, s, crown)
	gui.set_text(t.posto, s)
	gui.set_enabled(t.crown, crown)
end

-- where the plate ends at the top, arrow included (units at scale 1, from the
-- bottom center): the quips and the line sit above it
function M.sopra(t)
	return max(NAME_TOP, t.arrow_top or 0)
end

function M.riga(t, s)
	if t.row_text == s then return end
	t.row_text = s
	gui.set_text(t.riga, s)
	local font = gui.get_font_resource(gui.get_font(t.riga))
	local m = s ~= "" and resource.get_text_metrics(font, s, { width = ROW_W, line_break = true })
	t.row_h, t.row_w = m and m.height or 0, m and m.width or 0
end

function M.quip(t, s)
	gui.set_text(t.quip, s)
	local font = gui.get_font_resource(gui.get_font(t.quip))
	local m = resource.get_text_metrics(font, s)
	t.quip_w, t.quip_h = m.width, m.height
	t.quip_t = QUIP_T
	gui.set_enabled(t.quip, true)
	gui.set_enabled(t.nuvola, true)
end

function M.announcement(t, s)
	gui.set_text(t.announcement, s)
	gui.set_enabled(t.announcement, true)
	t.banner_t = BANNER_T
end

function M.set_enabled(t, on)
	gui.set_enabled(t.bars, on)
	gui.set_enabled(t.texts, on)
end

-- health and shield in points; the bar counts up to maximum, or to health + shield if more
function M.vita(t, hp_value, maximum, shield)
	hp_value, shield = max(0, hp_value), max(0, shield or 0)
	local tot = max(maximum, hp_value + shield)
	local f = hp_value / tot
	if f < t.hp_f - 1e-6 then
		-- hit: the trail starts from where health was (if it wasn't already higher)
		t.trail_f = max(t.trail_f, t.hp_f)
		t.attesa = 0.45
		t.colpo = 1
	elseif f > t.trail_f then
		t.trail_f = f
	end
	t.hp_f, t.shield_f, t.max_f = f, shield / tot, maximum / tot
	gui.set_text(t.numero, tostring(math.floor(hp_value + 0.5)))
end

local arrow_update -- further down, with the arrow

function M.update(t, dt, x, y, scale, cam)
	t.t = t.t + dt
	t.x, t.y, t.scala = x, y, scale
	V.x, V.y, V.z = x, y, 0
	gui.set_position(t.bars, V)
	gui.set_position(t.texts, V)
	V.x, V.y, V.z = scale, scale, 1
	gui.set_scale(t.bars, V)
	gui.set_scale(t.texts, V)
	if cam then
		-- the world scale is cam.s: the line stays the same size on screen
		local k = ROW_SCALE / (scale * cam.s)
		V.x, V.y = k, k
		gui.set_scale(t.riga, V)
		local _, tetto = camera.to_world(cam, 0, screen.y1 - ROW_TOP - t.row_h * ROW_SCALE)
		local sx = camera.to_screen(cam, x, y)
		local half = (t.row_w or 0) * ROW_SCALE / 2 + ROW_SIDE
		local cx = math.max(screen.x0 + half, math.min(screen.x1 - half, sx))
		if screen.x1 - screen.x0 < 2 * half then cx = (screen.x0 + screen.x1) / 2 end
		V.x = (camera.to_world(cam, cx, 0) - x) / scale
		V.y = math.min(M.sopra(t) + LINE_GAP, (tetto - y) / scale)
		gui.set_position(t.riga, V)
	end

	-- the bubble: same size on screen, fades in the last half second
	if t.quip_t > 0 then
		t.quip_t = t.quip_t - dt
		local zoom = scale * (cam and cam.s or 1)
		local k, border = QUIP_SCALE / zoom, QUIP_BORDER / zoom
		V.x, V.y, V.z = k, k, 1
		gui.set_scale(t.quip, V)
		V.x, V.y, V.z = t.quip_w * k + 2 * border, t.quip_h * k + 2 * border, 0
		gui.set_size(t.nuvola, V)
		local y0 = M.sopra(t) + (t.arrow and ARROW_ABOVE or QUIP_GAP)
		V.x, V.y = 0, y0
		gui.set_position(t.nuvola, V)
		V.y = y0 + border
		gui.set_position(t.quip, V)
		local a = math.min(1, t.quip_t * 2)
		C.x, C.y, C.z, C.w = ui.C.TEXT.x, ui.C.TEXT.y, ui.C.TEXT.z, a
		gui.set_color(t.quip, C)
		C.x, C.y, C.z, C.w = CLOUD.x, CLOUD.y, CLOUD.z, CLOUD.w * a
		gui.set_color(t.nuvola, C)
		if t.quip_t <= 0 then
			gui.set_enabled(t.quip, false)
			gui.set_enabled(t.nuvola, false)
		end
	end

	-- the trail waits a moment and then wears down to the health
	if t.attesa > 0 then
		t.attesa = t.attesa - dt
	elseif t.trail_f > t.hp_f then
		t.trail_f = max(t.hp_f, t.trail_f - dt * 0.9)
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

-- the arrow: the iron, the white ember tinted with the team color, the white
-- core (strumenti/grafica/freccia.py), in the battle atlas. ARROW_W wide, as
-- tall as the image says (nothing gets deformed)
local function layer(r, nome)
	local n = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(0, 0, 0))
	gui.set_texture(n, "battaglia")
	gui.set_size_mode(n, gui.SIZE_MODE_AUTO)
	gui.play_flipbook(n, nome)
	local px = gui.get_size(n)
	gui.set_size_mode(n, gui.SIZE_MODE_MANUAL)
	gui.set_size(n, vmath.vector3(ARROW_W, ARROW_W * px.y / px.x, 0))
	gui.set_adjust_mode(n, gui.ADJUST_FIT)
	gui.set_parent(n, r)
	gui.set_inherit_alpha(n, true)
	return n
end

function M.arrow()
	local f = { t = 0 }
	f.radice = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(0, 0, 0))
	gui.set_visible(f.radice, false)
	gui.set_adjust_mode(f.radice, gui.ADJUST_FIT)
	f.ferro = layer(f.radice, "freccia_ferro")
	f.ember = layer(f.radice, "freccia_brace")
	f.cuore = layer(f.radice, "freccia_cuore")
	f.h = gui.get_size(f.ferro).y
	gui.set_enabled(f.radice, false)
	return f
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
	local is_lit = (1 - c) / 2
	V.x, V.y, V.z = t.x, t.y + (BASE + (arrow_base(f) + ARROW_BOB * c) * k) * t.scala, 0
	gui.set_position(f.radice, V)
	V.x, V.y, V.z = t.scala * k, t.scala * k, 1
	gui.set_scale(f.radice, V)
	local col = t.colore
	C.x, C.y, C.z, C.w = col.x, col.y, col.z, 0.55 + 0.45 * is_lit
	gui.set_color(f.ember, C)
	C.x, C.y, C.z, C.w = 1, 1, 1, 0.15 + 0.85 * is_lit * is_lit
	gui.set_color(f.cuore, C)
end

return M
