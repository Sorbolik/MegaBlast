-- Campaign (the home's CAMPAGNA button): the chapters of sim/campaign.lua in
-- tabs, the Training (the lessons) first. Each chapter is the board of the
-- Forge: its missions pinned as postcards with the miniature of their map
-- (ui/illustrations.lua) and the label of their kind (ui/level_types.lua),
-- the title and the stars taken, the final as the wide strip at the bottom. A chapter opens with everyone's stars
-- (chapter.serve): closed, it says how many are missing. Style in ui/ui.lua.
--
--   local campagna = require "menu.campaign"
--   local c = campagna.new(scelta, stelle, storia)  -- scelta = { chapter } (the last one opened); stelle = id -> { true, false, true };
--     storia: some of the story was seen (ui/story.lua): LA STORIA, top right, reads it again
--   local fine = campagna.on_input(c, action_id, action)
--     -- "indietro", { missione = id, da } to play it (da: where its picture is), "storia", or nil
--   campagna.destroy(c)

local ui = require "ui.ui"
local kit = require "ui.kit"
local payload = require "sim.campaign"
local missions = require "sim.missions"
local ill = require "ui.illustrations"
local types = require "ui.level_types"
local T = require("lang.text").campaign
local TS = require("lang.text").story
local common = require("lang.text").common
local TV = require("lang.text").vignette

local M = {}

local KC = kit.C

-- a text no wider than w: it shrinks (never deforms)
local function fit(n, w)
	local width = kit.width(n)
	if width > w then gui.set_scale(n, gui.get_scale(n) * (w / width)) end
	return n
end

local function total(stars)
	local n = 0
	for _, v in pairs(stars) do n = n + missions.count(v) end
	return n
end

local function chapter_completed(c, cap)
	if not cap then return false end
	for _, l in ipairs(cap.missioni) do
		if not (c.stelle[l.id] or {})[1] then return false end
	end
	return true
end

local function is_opened(c, cap)
	if cap == payload.CAPITOLI[1] then return true end
	local prev
	for _, cp in ipairs(payload.CAPITOLI) do
		if cp == cap then break end
		prev = cp
	end
	if prev and not chapter_completed(c, prev) then return false end
	return total(c.stelle) >= (cap.serve or 0)
end

local function is_mission_unlocked(c, list, i)
	if i == 1 then return true end
	local prev = list[i - 1]
	return (c.stelle[prev.id] or {})[1] ~= nil
end

-- each star lit for its own criterion: also the first and third yes and the
-- second no. The cortile: «Fatta» and Favilla's medal (or «Fatta» alone).
-- The first at the Figma point (x, y)
local function little_stars(g, picked, count, medal, x, y, d)
	for i = 1, count do
		local draw = medal and i == 2 and ui.medal or ui.star
		local lit = medal and i == 2 and ui.MEDAL or KC.HOT
		draw(x + (i - 1) * d * 1.2 - g.ox, g.oy - y, d, picked[i] and lit or KC.LINE, g.node)
	end
end

-- a mission's card (ui/kit.lua): the frame in its kind's colour, the miniature
-- of its map cut to the card's corner, the kind's label, the name; closed, it
-- is dark under a padlock. ih: how tall the picture is
local function card(c, l, x, y, w, h, ih, kind, state)
	local g = c.kg
	local locked = state == "locked"
	local col = state == "new" and KC.HOT or locked and KC.LINE or types.color(l.tipo) or KC.ROSE
	local k = kit.card(g, x, y, w, h, col, { sel = state == "new" })
	local tex, size = ill.texture(l.id, kind)
	if tex then
		c.textures[#c.textures + 1] = { l.id, kind }
		kit.card_picture(k, tex, ih, size and size.w / size.h, locked and 0.45 or 1)
	end
	local kd = types.KINDS[l.tipo]
	if kd then kit.label(k.g, x + 16, y + 12, kd.name, locked and KC.MUTE or kd.color, true) end
	if locked then
		ui.padlock(0, h / 2 - 4 - ih / 2, math.min(46, ih * 0.5), KC.MUTE, k.node)
	else
		kit.zone(g, c.buttons, x, y, w, h, "missione:" .. l.id)
	end
	-- where the picture is on the screen: the postcard zooms from here (ui/postcard.lua)
	c.from[l.id] = { x = x + w / 2, y = 720 - (y + 4 + ih / 2) + gui.get_position(c.radice).y, w = w - 8, h = ih }
	return k
end

local function card_list(c, cap)
	local g = c.kg
	local list = cap.missioni
	-- the final: the chapter's last mission; the others as cards, staggered
	local final = #list > 1 and list[#list] or nil
	local pinned = #list - (final and 1 or 0)
	local cols = pinned > 6 and 4 or 3
	local w, h = cols == 3 and 246 or 184, cols == 3 and 150 or 140
	-- the next one to do: the first without «Fatta»
	local next_id
	for _, l in ipairs(list) do
		if not (c.stelle[l.id] or {})[1] then next_id = l.id; break end
	end
	c.next_id = next_id
	for i = 1, pinned do
		local l = list[i]
		local unlocked = is_mission_unlocked(c, list, i)
		local col, row = (i - 1) % cols, math.floor((i - 1) / cols)
		local x, y = 440 + col * (w + 20) - row * 10, 166 + row * (h + 22)
		local is_new = l.id == next_id
		local k = card(c, l, x, y, w, h, h - 46, "carta", not unlocked and "locked" or is_new and "new" or "open")
		local count = #missions.criteria(l)
		local d = cols == 3 and 16 or 13
		local room = w - 30 - (is_new and 62 or unlocked and count * d * 1.2 + 6 or 0)
		fit(kit.text(k.g, kit.upper(l.titolo), x + 18, y + h - 22, cols == 3 and 17 or 13, unlocked and KC.SAND or KC.MUTE), room)
		if is_new and unlocked then
			kit.text(k.g, T.new, x + w - 10, y + h - 22, 13, KC.HOT_TOP, "end", 1)
		elseif unlocked then
			little_stars(k.g, c.stelle[l.id] or {}, count, l.medaglia ~= nil, x + w - 4 - count * d * 1.2, y + h - 27, d)
		end
	end
	if final then
		local unlocked = is_mission_unlocked(c, list, #list)
		local rows = math.ceil(pinned / cols)
		local fy, fw = 166 + rows * (h + 22), cols == 3 and 520 or 480
		local is_new = final.id == next_id
		local k = kit.card(g, 420, fy, fw, 56, is_new and unlocked and KC.HOT or unlocked and KC.STAR or KC.LINE, { sel = is_new and unlocked })
		fit(kit.text(k.g, T.final:format(kit.upper(final.titolo)), 446, fy + 35, 17, unlocked and KC.SAND or KC.MUTE), fw - 130)
		if not unlocked then
			ui.padlock(fw / 2 - 40, 0, 30, KC.MUTE, k.node)
		elseif is_new then
			kit.text(k.g, T.new, 420 + fw - 24, fy + 34, 13, KC.HOT_TOP, "end", 1)
		else
			local count = #missions.criteria(final)
			little_stars(k.g, c.stelle[final.id] or {}, count, final.medaglia ~= nil, 420 + fw - 30 - count * 20, fy + 28, 17)
		end
		if unlocked then kit.zone(g, c.buttons, 420, fy, fw, 56, "missione:" .. final.id) end
		c.from[final.id] = { x = 420 + fw / 2, y = 720 - (fy + 28) + gui.get_position(c.radice).y, w = fw, h = 56 }
	end
end

-- who guides the chapter, on the left: the portrait on a light plate, and
-- under it how far you are
local function guide(c, cap)
	local g = c.kg
	local who = cap == payload.CAPITOLI[1] and "favilla" or "fabbro"
	local p = kit.sand(g, 60, 170, 330, 400, KC.HOT, { sk = 20 })
	local pic = gui.new_box_node(vmath.vector3(4, 35, 0), vmath.vector3(306, 306, 0))
	gui.set_texture(pic, "ritratti")
	gui.play_flipbook(pic, who .. (who == "favilla" and "_spiega" or "_calma"))
	gui.set_parent(pic, p.face_node)
	kit.text(g, TV[who], 90, 548, 26, KC.INK)
	local done, got = 0, 0
	for _, l in ipairs(cap.missioni) do
		local st = c.stelle[l.id] or {}
		if st[1] then done = done + 1 end
		got = got + missions.count(st)
	end
	kit.sand(c.low, 80, 630, 340, 62, KC.STAR, { sk = 22 })
	kit.text(c.low, T.progress:format(done, #cap.missioni, got), 250, 668, 18, KC.INK, "middle", 0.5)
end

-- ---------------------------------------------------------------- the map

-- After the kidnapping (the last chapter done) the campaign is the funnel of
-- hell (Sergio, 10-11 Nov): on the top floor the Cortile (the antinferno) and
-- the Forge, under it the nine circles, smaller and smaller, down to Favilla.
-- Only the circles reached open (Sergio, 11 Nov): the next one has its padlock,
-- the ones under it are off. The map looks at one circle at a time, always as
-- wide (the ones at the bottom would be too small to touch): touching another
-- circle, or dragging up and down, the camera goes there. The circles are placeholders for now: names and
-- keepers (lang, campaign.rings), five levels and the keeper each.
-- { top, side }: the colors of each floor
local FLOOR = { kit.hex("3d2c20"), kit.hex("8b4f2b") }
local RING_COLORS = {
	{ kit.hex("27352f"), kit.hex("3f5f55") }, { kit.hex("3a1f4a"), kit.hex("7d3c9c") }, { kit.hex("302a1a"), kit.hex("5a4c22") },
	{ kit.hex("3d3212"), kit.hex("8a6c1e") }, { kit.hex("401818"), kit.hex("8c2c26") }, { kit.hex("3a2414"), kit.hex("a85c1e") },
	{ kit.hex("3c1220"), kit.hex("8e2038") }, { kit.hex("1a2636"), kit.hex("2f5078") }, { kit.hex("26384a"), kit.hex("6aa2c4") },
}
local RING_LEVELS = 5
-- the circle you are on (the levels are still to come: always the first)
local RING_AT = 1
-- the rings on the map: their widths, from the first down
local RING_W = { 744, 610, 490, 390, 305, 235, 180, 135, 100 }
-- how far a circle goes toward the dark: the next one, and the ones under it
local NEXT_DIM, OFF_DIM = 0.3, 0.72
-- the circle the map looks at: how wide on the screen and where (Figma y), and
-- how long the camera takes to get to another one
local LOOK_W, LOOK_Y, LOOK_TIME = 744, 312, 0.28
-- a drag this long (pixels of the 720 high screen) moves the camera
local DRAG = 60
-- the plate of the story shown at the bottom of the funnel
local PRISON = "s_ghiaccio"
local RING_H, RING_THICK = 0.105, 0.045
local MAP_X = 520

local function toward_ink(col, k)
	local i = KC.INK
	return vmath.vector4(col.x + (i.x - col.x) * k, col.y + (i.y - col.y) * k, col.z + (i.z - col.z) * k, 1)
end

local function ellipse(g, cx, cy, w, h, color)
	-- a box with an image, not a pie node (its polygon has no antialiasing).
	-- The flat ones have their own images, drawn already flat and in three
	-- sizes: a round disc pulled eight times wider shows steps on the curves
	-- (Sergio, 11 Nov), and the atlas has no mipmaps
	local n = gui.new_box_node(vmath.vector3(cx - g.ox, g.oy - cy, 0), vmath.vector3(w, h, 0))
	gui.set_texture(n, "ui")
	local image = "disco_p"
	if w > 48 then
		-- g.k: the scale of the group (the map), the size it shows at
		local shown = w * (g.k or 1)
		image = h > w * 0.2 and "ellisse_a" or shown >= 560 and "ellisse_g" or shown >= 230 and "ellisse_m" or "ellisse_p"
	end
	gui.play_flipbook(n, image)
	gui.set_color(n, color)
	gui.set_parent(n, g.node)
	return n
end

-- a floor of the funnel: a disc w wide seen from above (h), thick, with its
-- hole. outline: a sand rim (the one you are on)
local function floor(g, cx, cy, w, h, thick, colors, outline)
	ellipse(g, cx, cy + thick, w, h, colors[2])
	-- as wide as the ellipse in its image (a pixel of margin each side)
	kit.rect(g, cx - w / 2 + w * 0.0008, cy, w * 0.9984, thick, colors[2])
	if outline then ellipse(g, cx, cy, w + 8, h + 8, KC.SAND) end
	ellipse(g, cx, cy, w, h, colors[1])
	ellipse(g, cx, cy - h * 0.04, w * 0.56, h * 0.5, KC.INK)
end

local function funnel_on(c)
	for _, cap in ipairs(payload.CAPITOLI) do
		if not chapter_completed(c, cap) then return false end
	end
	return true
end

local function chapter_stars(c, cap)
	local got, all = 0, 0
	for _, l in ipairs(cap.missioni) do
		local n = #missions.criteria(l)
		for k = 1, n do
			if (c.stelle[l.id] or {})[k] then got = got + 1 end
		end
		all = all + n
	end
	return got, all
end

-- the points of a ring's levels along its front arc: n of them, the keeper last
local function arc(cx, cy, w, h, n)
	local out = {}
	for k = 1, n do
		local a = math.rad(160 - (k - 1) / (n - 1) * 140)
		out[k] = { cx + w / 2 * 0.76 * math.cos(a), cy + h / 2 * 0.76 * math.sin(a) }
	end
	return out
end

-- the Figma y of each ring's top face on the whole funnel
local RING_Y = {}
do
	local y = LOOK_Y
	for i, w in ipairs(RING_W) do
		RING_Y[i] = y
		if RING_W[i + 1] then y = y + w * RING_THICK + RING_W[i + 1] * RING_H * 0.55 end
	end
end

local function build_map(c)
	local g = c.kg
	c.head = kit.header(c.buttons, common.campaign, KC.HOT, "indietro", common.home)
	local last = #RING_W
	local look = math.max(1, math.min(last, c.scelta.look or RING_AT))
	local from = c.look_from or look
	c.scelta.look, c.look_from = look, nil
	-- the funnel in its own group, scaled around the ring looked at
	local scale = LOOK_W / RING_W[look]
	local m = gui.new_box_node(vmath.vector3(MAP_X, 720 - LOOK_Y, 0), vmath.vector3(1, 1, 0))
	gui.set_visible(m, false)
	gui.set_parent(m, g.node)
	gui.set_scale(m, vmath.vector3(scale, scale, 1))
	local mg = { node = m, ox = MAP_X, oy = RING_Y[look], k = scale }
	-- where a ring is on the screen, and how wide
	local function on_screen(i)
		return LOOK_Y + (RING_Y[i] - RING_Y[look]) * scale, RING_W[i] * scale
	end
	-- Favilla, at the bottom of it all
	local fy = RING_Y[last] + 24
	local halo = ui.disc(0, RING_Y[look] - fy, 150, kit.with_alpha(KC.STEEL, 0.28), m)
	gui.play_flipbook(halo, "alone")
	gui.set_blend_mode(halo, gui.BLEND_ADD)
	gui.animate(halo, "color.w", 0.12, gui.EASING_INOUTSINE, 1.8, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
	ui.disc(0, RING_Y[look] - fy, 9, KC.STAR, m)
	-- from the bottom up: each floor covers the back of the one under it. Above
	-- the ring looked at only the one before it (or the top floor)
	for i = last, math.max(1, look - 1), -1 do
		local w = RING_W[i]
		local col = RING_COLORS[i]
		if i > RING_AT then
			local k = i == RING_AT + 1 and NEXT_DIM or OFF_DIM
			col = { toward_ink(col[1], k + 0.1), toward_ink(col[2], k) }
		end
		floor(mg, MAP_X, RING_Y[i], w, w * RING_H, w * RING_THICK, col, i == look)
		-- the front of the ring, the part the one above leaves in sight
		local top = RING_Y[i] - w * RING_H / 2
		if i > look - 1 and i > 1 then top = RING_Y[i - 1] + RING_W[i - 1] * (RING_H / 2 + RING_THICK) end
		kit.zone(mg, c.buttons, MAP_X - w / 2, top, w, RING_Y[i] + w * (RING_H / 2 + RING_THICK) - top, "girone:" .. i)
	end
	if look == 1 then floor(mg, MAP_X, 208, 860, 96, 52, FLOOR, false) end
	-- names and padlocks: not scaled, in their own group (hidden while the camera moves)
	local lab = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(1, 1, 0))
	gui.set_visible(lab, false)
	gui.set_parent(lab, g.node)
	local lg = { node = lab, ox = g.ox, oy = g.oy }
	if from ~= look then
		-- the camera comes from the ring it was looking at
		local s0 = LOOK_W / RING_W[from]
		gui.set_scale(m, vmath.vector3(s0, s0, 1))
		gui.set_position(m, vmath.vector3(MAP_X, 720 - LOOK_Y + (RING_Y[look] - RING_Y[from]) * s0, 0))
		gui.set_enabled(lab, false)
		gui.animate(m, "scale", vmath.vector3(scale, scale, 1), gui.EASING_OUTCUBIC, LOOK_TIME)
		gui.animate(m, "position", vmath.vector3(MAP_X, 720 - LOOK_Y, 0), gui.EASING_OUTCUBIC, LOOK_TIME, 0, function()
			gui.set_enabled(lab, true)
		end)
	end
	-- the ring looked at: its name on a plate; yours has its levels as dots
	local r = T.rings[look]
	local at = T.rings[RING_AT]
	if look == RING_AT then
		for k, pt in ipairs(arc(MAP_X, LOOK_Y, LOOK_W, LOOK_W * RING_H, RING_LEVELS + 1)) do
			ellipse(lg, pt[1], pt[2] - 4, 12, 9, k == 1 and KC.HOT or kit.with_alpha(KC.SAND, 0.35))
		end
	end
	local pc = RING_COLORS[look][2]
	local p = kit.sand(lg, MAP_X - 118, LOOK_Y + 30, 236, 34, look > RING_AT and toward_ink(pc, 0.4) or pc, { sk = 10, d = 5 })
	kit.text(p.g, T.ring_name:format(r[1], r[2]), MAP_X, LOOK_Y + 54, 18, KC.INK, "middle", 1)
	if from == look then kit.pop(p.node, 0.25) end
	-- the closed ones: a padlock inside, on the right; the next one says what opens it
	for i = math.max(RING_AT + 1, look - 1), last do
		local y, w = on_screen(i)
		if w >= 180 and y < 600 then
			local d = math.max(14, math.min(26, w * 0.036))
			ui.padlock(MAP_X + w * 0.43 - g.ox, g.oy - (y + w * RING_H * 0.3), d, i == RING_AT + 1 and KC.SAND or KC.MUTE, lab)
		end
		if i == RING_AT + 1 and i <= look + 1 then
			local line = i == look and T.ring_opens:format(at[3]) or T.ring_locked:format(T.rings[i][1], T.rings[i][2], at[3])
			kit.text(lg, line, MAP_X, i == look and LOOK_Y + LOOK_W * (RING_H / 2 + RING_THICK) + 20 or y + w * RING_H * 0.42, 10, KC.SAND, "middle", 1)
		end
	end
	local fsy = LOOK_Y + (fy - RING_Y[look]) * scale
	if look == last then
		-- at the very bottom: Favilla in the ice, the plate of the kidnapping (Sergio, 11 Nov)
		local tex, size = ill.story(PRISON)
		local k = kit.card(lg, MAP_X - 160, 404, 320, 188, KC.STEEL, {})
		if tex then
			c.prison = true
			kit.card_picture(k, tex, 180, size.w / size.h, 1)
		end
		kit.pop(k.node, from == look and 0.15 or 0)
	elseif fsy < 610 then
		kit.text(lg, TV.favilla, MAP_X, fsy + 22, 9, kit.with_alpha(KC.STEEL, 0.8), "middle", 2)
	end
	-- the top floor: the two chapters done, each with the picture of its place
	local places = { { payload.CAPITOLI[1], T.cortile, 390 }, { payload.CAPITOLI[2], kit.upper(payload.CAPITOLI[2].titolo), 690 } }
	if look > 1 then places = {} end
	for _, pl in ipairs(places) do
		local cap, x = pl[1], pl[3]
		local first = cap.missioni[#cap.missioni]
		local tex, size = ill.texture(first.id, "carta")
		local k = kit.card(g, x - 84, 98, 168, 96, KC.SAND, {})
		if tex then
			c.textures[#c.textures + 1] = { first.id, "carta" }
			kit.card_picture(k, tex, 88, size and size.w / size.h, 1)
		end
		kit.text(g, pl[2], x, 222, 16, KC.SAND, "middle", 1)
		local got, all = chapter_stars(c, cap)
		ui.star(x - 26 - g.ox, g.oy - 237, 13, KC.STAR, g.node)
		kit.text(g, T.ring_stars:format(got, all), x - 12, 242, 11, KC.MUTE, "start", 1)
		kit.zone(g, c.buttons, x - 100, 90, 200, 160, "capitolo:" .. cap.id)
		kit.arrive(k.node, 0, 30, 0.05, 0.3)
	end
	-- who takes you down, top right
	local tr = c.head.top_right
	local k = kit.card(tr, 1010, 104, 230, 84, KC.ROSE, {})
	local pic = gui.new_box_node(vmath.vector3(-74, 0, 0), vmath.vector3(70, 70, 0))
	gui.set_texture(pic, "ritratti")
	gui.play_flipbook(pic, "fabbro_calma")
	gui.set_parent(pic, k.node)
	kit.text(k.g, TV.fabbro, 1100, 132, 11, KC.SAND, "start", 1)
	kit.text(k.g, T.fabbro_line[1], 1100, 150, 10, KC.MUTE)
	kit.text(k.g, T.fabbro_line[2], 1100, 164, 10, KC.MUTE)
	kit.text(c.right, T.tap_ring, 1090, 470, 10, KC.MUTE, "middle", 1)
	c.play = nil
	c.action = kit.action(c.right, common.play, 930, 560, 270, 84, { size = 54, sub = T.coming_sub:format(at[2]), off = true })
	kit.button(c.buttons, c.action, "gioca", { main = true, spento = true })
end

-- a circle opened: the ring wide, its levels along the front, the keeper last
local function build_ring(c, i)
	local g = c.kg
	local r = T.rings[i]
	local col = RING_COLORS[i]
	c.head = kit.header(c.buttons, r[2], col[2], "mappa", T.rings_back)
	local tl = c.head.top_left
	kit.text(tl, r[1], 30, 114, 20, col[2], "start", 1)
	kit.text(tl, T.ring_sub:format(T.coming), 30 + 16 + #r[1] * 12, 114, 11, KC.MUTE, "start", 1)
	local cx, cy, w, h = 560, 370, 1080, 300
	floor(g, cx, cy, w, h, 60, col, true)
	-- the circle under it, down in the hole: closed
	local under = T.rings[i + 1]
	if under then
		ellipse(g, cx, cy + 34, 420, 62, toward_ink(RING_COLORS[i + 1][2], 0.6))
		ellipse(g, cx, cy + 36, 210, 30, KC.INK)
		ui.padlock(cx - g.ox, g.oy - (cy + 22), 22, KC.MUTE, g.node)
		kit.text(g, T.ring_name:format(under[1], under[2]), cx, cy + 60, 10, KC.MUTE, "middle", 1)
	end
	local pts = arc(cx, cy, w, h, RING_LEVELS + 1)
	for k = 1, #pts - 1 do
		kit.line(g, pts[k][1], pts[k][2], pts[k + 1][1], pts[k + 1][2], 3, kit.with_alpha(KC.SAND, 0.18))
	end
	for k, pt in ipairs(pts) do
		local keeper = k == #pts
		local d = keeper and 54 or 36
		local n = gui.new_box_node(vmath.vector3(pt[1] - g.ox, g.oy - pt[2], 0), vmath.vector3(d, d, 0))
		gui.set_visible(n, false)
		gui.set_parent(n, g.node)
		ui.disc(0, 0, d, keeper and KC.STEEL or KC.LINE, n)
		ui.disc(0, 0, d - 6, KC.INK, n)
		local ng = { node = n, ox = pt[1], oy = pt[2] }
		if keeper then
			ui.padlock(0, 0, 20, KC.STEEL, n)
			kit.text(g, r[3], pt[1], pt[2] - 38, 11, KC.MUTE, "middle", 1)
		else
			kit.text(ng, tostring(k), pt[1], pt[2] + 5, 14, KC.MUTE, "middle")
		end
		kit.pop(n, 0.05 * k)
	end
	local k = kit.card(g, 250, 556, 560, 96, KC.LINE, {})
	kit.text(k.g, T.coming, 280, 596, 22, KC.SAND, "start", 1)
	kit.text(k.g, T.coming_line, 280, 624, 11, KC.MUTE, "start", 1)
	c.play = nil
	c.action = kit.action(c.right, common.play, 930, 560, 270, 84, { size = 54, sub = T.coming_sub:format(r[2]), off = true })
	kit.button(c.buttons, c.action, "gioca", { main = true, spento = true })
end

-- the card miniatures of the chapter shown, given back to the GPU
local function release_textures(c)
	for _, t in ipairs(c.textures or {}) do ill.release(t[1], t[2]) end
	c.textures = {}
	if c.prison then ill.story_release(PRISON) end
	c.prison = nil
end

local function build(c)
	if c.radice then gui.delete_node(c.radice) end
	if c.head then kit.header_delete(c.head) end
	if c.right then gui.delete_node(c.right.node) end
	if c.low then gui.delete_node(c.low.node) end
	release_textures(c)
	c.buttons = {}
	c.from = {}
	c.next_id = nil
	c.right = kit.anchor(1280, 720, gui.ANCHOR_RIGHT, gui.ANCHOR_BOTTOM)
	c.low = kit.anchor(0, 720, gui.ANCHOR_LEFT, gui.ANCHOR_BOTTOM)
	c.radice = ui.root()
	c.kg = { node = c.radice, ox = 0, oy = 720 }
	local g = c.kg
	-- after the kidnapping: the map of the circles, a circle opened, or (from
	-- the top floor) the board of a chapter, which goes back to the map
	local map = funnel_on(c)
	local on_map = map and c.scelta.view ~= "board"
	-- the backdrop
	kit.scene_focus(c.scene, on_map and 540 or 225, 360)
	c.on_map = on_map and type(c.scelta.view) ~= "number"
	if on_map then
		if type(c.scelta.view) == "number" then return build_ring(c, c.scelta.view) end
		return build_map(c)
	end
	-- the frame (ui/kit.lua): CAMPAGNA written as the logo, the way back at the
	-- bottom left, the chapters as tabs on their rail
	c.head = kit.header(c.buttons, common.campaign, KC.HOT, map and "mappa" or "indietro", map and T.rings_back or common.home)
	local chosen, active = nil, 1
	for i, cap in ipairs(payload.CAPITOLI) do
		if c.scelta.chapter == cap.id then chosen, active = cap, i end
	end
	chosen = chosen or payload.CAPITOLI[1]
	local tabs = {}
	for i, cap in ipairs(payload.CAPITOLI) do
		tabs[i] = { kit.upper(cap.titolo), "capitolo:" .. cap.id }
	end
	local tabs_end = kit.tabs(g, c.buttons, 440, 104, tabs, active, KC.HOT)
	-- the story seen so far, to read again: a small plate after the tabs
	if c.storia then
		local p = kit.plate(g, tabs_end + 40, 104, 150, 36, KC.ROSE, { sk = 10, d = 4 })
		kit.text(p.g, TS.read_again, tabs_end + 40 + 80, 128, 14, KC.SAND, "middle", 0.5)
		kit.button(c.buttons, p, "storia")
	end
	guide(c, chosen)
	local act = { off = true }
	if is_opened(c, chosen) then
		card_list(c, chosen)
		-- the one action: the next mission to do (all done: the final again)
		local list = chosen.missioni
		local id = c.next_id or list[#list].id
		local name = ""
		for _, l in ipairs(list) do if l.id == id then name = kit.upper(l.titolo) end end
		act = { id = id, sub = c.next_id and T.play_new:format(name) or T.replay_final }
	else
		local prev
		for _, cp in ipairs(payload.CAPITOLI) do
			if cp == chosen then break end
			prev = cp
		end
		local done, tot = 0, prev and #prev.missioni or 0
		if prev then
			for _, l in ipairs(prev.missioni) do
				if (c.stelle[l.id] or {})[1] then done = done + 1 end
			end
		end
		ui.padlock(820, 720 - 300, 64, KC.MUTE, c.radice)
		kit.text(g, kit.upper(T.locked:format(prev and prev.titolo or payload.CAPITOLI[1].titolo)), 820, 380, 16, KC.SAND, "middle", 0.5)
		kit.text(g, kit.upper(T.done_count:format(done, tot)), 820, 408, 12, KC.MUTE, "middle", 1)
		act.sub = kit.upper(T.done_count:format(done, tot))
	end
	c.play = act.id
	c.action = kit.action(c.right, common.play, 930, 560, 270, 84, { size = 54, sub = act.sub, off = act.off })
	kit.button(c.buttons, c.action, "gioca", { main = true, spento = act.off })
end

function M.new(choice, stars, story)
	local c = { scelta = choice, stelle = stars or {}, storia = story }
	-- the first time, the last chapter opened
	if not choice.chapter then
		for _, cap in ipairs(payload.CAPITOLI) do
			if is_opened(c, cap) then choice.chapter = cap.id end
		end
	end
	-- the backdrop (ui/kit.lua)
	c.scene = kit.scene(funnel_on(c) and choice.view ~= "board" and 540 or 225, 360, {})
	build(c)
	return c
end

function M.on_input(c, action_id, action)
	-- on the map a drag up or down moves the camera one ring
	if action_id == ui.TOUCH and c.on_map then
		if action.pressed then
			c.drag_y = action.y
		elseif action.released and c.drag_y then
			local dy = action.y - c.drag_y
			c.drag_y = nil
			local look = c.scelta.look + (dy > DRAG and 1 or dy < -DRAG and -1 or 0)
			if look ~= c.scelta.look and look >= 1 and look <= #RING_W then
				c.look_from, c.scelta.look = c.scelta.look, look
				build(c)
				return nil
			end
		end
	end
	local ui_action = ui.touch(c.buttons, action_id, action)
	if not ui_action then return nil end
	if ui_action == "indietro" or ui_action == "storia" then return ui_action end
	local kind, value = ui_action:match("^(%a+):(.*)$")
	if ui_action == "gioca" then return c.play and { missione = c.play, da = c.from[c.play] } or nil end
	if kind == "missione" then return { missione = value, da = c.from[value] } end
	if ui_action == "mappa" then
		c.scelta.view = nil
	elseif kind == "girone" then
		-- the ring the map looks at opens (if reached); another one calls the camera
		local i = tonumber(value)
		if i ~= c.scelta.look then
			c.look_from, c.scelta.look = c.scelta.look, i
		elseif i <= RING_AT then
			c.scelta.view = i
		else
			return nil
		end
	else
		c.scelta.chapter = value
		if funnel_on(c) then c.scelta.view = "board" end
	end
	build(c)
	return nil
end

function M.destroy(c)
	kit.header_delete(c.head)
	gui.delete_node(c.right.node)
	gui.delete_node(c.low.node)
	gui.delete_node(c.radice)
	release_textures(c)
	kit.scene_drop(c.scene)
end

return M
