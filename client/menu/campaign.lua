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
		kit.piece({ node = k.node, ox = 0, oy = 0 }, "lucchetto", 0, -(h / 2 - 4 - ih / 2), math.min(50, ih * 0.55))
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
		local x, y = 440 + col * (w + 20) - row * 10, 180 + row * (h + 20)
		local is_new = l.id == next_id
		local k = card(c, l, x, y, w, h, h - 46, "carta", not unlocked and "locked" or is_new and "new" or "open")
		local count = #missions.criteria(l)
		local d = cols == 3 and 16 or 13
		local room = w - 30 - (is_new and 62 or unlocked and count * d * 1.2 + 6 or 0)
		fit(kit.text(k.g, kit.upper(l.titolo), x + 18, y + h - 22, cols == 3 and 19 or 15, unlocked and KC.SAND or KC.MUTE), room)
		if is_new and unlocked then
			kit.text(k.g, T.new, x + w - 10, y + h - 22, 13, KC.HOT_TOP, "end", 1)
		elseif unlocked then
			little_stars(k.g, c.stelle[l.id] or {}, count, l.medaglia ~= nil, x + w - 4 - count * d * 1.2, y + h - 27, d)
		end
	end
	if final then
		local unlocked = is_mission_unlocked(c, list, #list)
		local rows = math.ceil(pinned / cols)
		local fy, fw = 180 + rows * (h + 20), cols == 3 and 520 or 480
		local is_new = final.id == next_id
		local k = kit.card(g, 420, fy, fw, 56, is_new and unlocked and KC.HOT or unlocked and KC.STAR or KC.LINE, { sel = is_new and unlocked })
		fit(kit.text(k.g, T.final:format(kit.upper(final.titolo)), 446, fy + 35, 17, unlocked and KC.SAND or KC.MUTE), fw - 130)
		if not unlocked then
			kit.piece({ node = k.node, ox = 0, oy = 0 }, "lucchetto", fw / 2 - 40, 0, 34)
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
	local p = kit.sand(g, 60, 180, 330, 400, KC.HOT, { sk = 20 })
	local pic = gui.new_box_node(vmath.vector3(4, 35, 0), vmath.vector3(306, 306, 0))
	gui.set_texture(pic, "ritratti")
	gui.play_flipbook(pic, who .. (who == "favilla" and "_spiega" or "_calma"))
	gui.set_parent(pic, p.face_node)
	kit.text(g, TV[who], 90, 558, 28, KC.INK)
	local done, got = 0, 0
	for _, l in ipairs(cap.missioni) do
		local st = c.stelle[l.id] or {}
		if st[1] then done = done + 1 end
		got = got + missions.count(st)
	end
	local on_plate = kit.sand(c.low, kit.PLATE_X, kit.PLATE_Y, 340, 62, KC.STAR, { sk = 22 })
	kit.text(on_plate.g, T.progress:format(done, #cap.missioni, got), kit.PLATE_X + 170, kit.PLATE_Y + 38, 19, KC.INK, "middle", 0.5)
end

-- ---------------------------------------------------------------- the map

-- After the kidnapping (the last chapter done) the campaign is the way down
-- through hell (Sergio, 10-12 Nov): the nine circles as nine slices drawn by
-- Codex (WB-026, ui/slices.lua), each with its own look, stacked from the Limbo
-- down to Favilla in the ice. All nine are always there and whole: only the
-- circles reached are lit (Sergio, 11 Nov), the next one has its padlock and
-- says what opens it, the ones under it are dark but still themselves. The map
-- looks at one circle at a time, the big one: touching another, dragging up
-- and down or touching its mark on the rail (right) the stack slides there.
-- The levels are placeholders for now (lang, campaign.rings): five and the keeper.
local SLICES = require "ui.slices"
local RING_LEVELS = 5
-- the circle you are on (the levels are still to come: always the first)
local RING_AT = 1
local LAST = #SLICES
-- the slice looked at is SLICE_W wide on the screen (about half its picture:
-- sharp on a screen twice as dense), the others SMALL of it
local SLICE_W, SMALL = 700, 0.66
-- where the slice looked at is (Figma), how much of a slice the one above
-- covers, how long the stack takes to slide
local MAP_X, LOOK_Y, COVER, LOOK_TIME = 640, 310, 0.2, 0.3
-- how dark a closed circle is: the next one, and the ones under it
local NEXT_DIM, OFF_DIM = 0.78, 0.56
-- a drag this long (pixels of the 720 high screen) moves the stack
local DRAG = 60
-- the plate of the story shown at the bottom of it all
local PRISON = "s_ghiaccio"
-- the accent of each circle: its name on the rail and on the slice
local RING_ACCENT = {
	kit.hex("d9cfa8"), kit.hex("ff5fa8"), kit.hex("a9a08c"), kit.hex("d4a94a"), kit.hex("5fb8a8"),
	kit.hex("e0763a"), kit.hex("e04a4a"), kit.hex("b8b04a"), kit.hex("8fd0f0"),
}

local function slice_h(i) return SLICE_W * SLICES[i].h / SLICES[i].w end

-- where every slice is when the map looks at `look`: { y (Figma, its middle), k (its scale) }
local function layout(look)
	local out = {}
	out[look] = { y = LOOK_Y, k = 1 }
	for i = look + 1, LAST do
		local up = out[i - 1]
		out[i] = { k = SMALL, y = up.y + (slice_h(i - 1) * up.k + slice_h(i) * SMALL) / 2 * (1 - COVER) }
	end
	for i = look - 1, 1, -1 do
		local down = out[i + 1]
		out[i] = { k = SMALL, y = down.y - (slice_h(i + 1) * down.k + slice_h(i) * SMALL) / 2 * (1 - COVER) }
	end
	return out
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

-- a slice: its picture, its name on the front, the padlock if closed, the
-- levels along the top if it is yours. Everything is its child: it slides and
-- grows with it
local function slice(c, i, at, from)
	local g = c.kg
	local h = slice_h(i)
	local n = gui.new_box_node(vmath.vector3(MAP_X - g.ox, g.oy - at.y, 0), vmath.vector3(SLICE_W, h, 0))
	gui.set_texture(n, "fette")
	gui.play_flipbook(n, SLICES[i].image)
	gui.set_parent(n, g.node)
	local closed = i > RING_AT
	local dim = not closed and 1 or i == RING_AT + 1 and NEXT_DIM or OFF_DIM
	gui.set_color(n, vmath.vector4(dim, dim, dim, 1))
	gui.set_scale(n, vmath.vector3(at.k, at.k, 1))
	local sg = { node = n, ox = 0, oy = 0 }
	local r = T.rings[i]
	kit.text(sg, T.ring_name:format(r[1], r[2]), 0, h * 0.36, 22, closed and KC.MUTE or RING_ACCENT[i], "middle", 1.5)
	if closed then
		-- the padlock inside, on the right; the next one says what opens it
		local lock = kit.piece(sg, "lucchetto", SLICE_W * 0.36, h * 0.12, i == RING_AT + 1 and 46 or 38)
		if i > RING_AT + 1 then gui.set_color(lock, vmath.vector4(0.6, 0.6, 0.66, 1)) end
		if i == RING_AT + 1 then
			kit.text(sg, T.ring_opens:format(T.rings[RING_AT][3]), 0, -h * 0.1, 17, KC.SAND, "middle", 1)
		end
	else
		-- the levels along the top face: the one to play burns, the keeper last
		for k = 1, RING_LEVELS + 1 do
			local t = (k - 1) / RING_LEVELS
			local x = (t - 0.5) * SLICE_W * 0.6
			local y = -h * 0.2 + math.sin(t * math.pi) * h * 0.08
			local keeper = k > RING_LEVELS
			if k == 1 then
				kit.piece(sg, "fiamma", x, y - 14, 54)
			else
				kit.piece(sg, "brace_spenta", x, y, keeper and 46 or 30)
			end
			if keeper then
				kit.piece(sg, "corona", x, y - 30, 20)
				kit.text(sg, r[3], x, y + 42, 14, KC.SAND, "middle", 1)
			end
		end
	end
	kit.zone(sg, c.buttons, -SLICE_W * 0.46, -h / 2, SLICE_W * 0.92, h, "girone:" .. i)
	if from and (from.y ~= at.y or from.k ~= at.k) then
		gui.set_position(n, vmath.vector3(MAP_X - g.ox, g.oy - from.y, 0))
		gui.set_scale(n, vmath.vector3(from.k, from.k, 1))
		gui.animate(n, "position", vmath.vector3(MAP_X - g.ox, g.oy - at.y, 0), gui.EASING_OUTCUBIC, LOOK_TIME)
		gui.animate(n, "scale", vmath.vector3(at.k, at.k, 1), gui.EASING_OUTCUBIC, LOOK_TIME)
	end
	return n
end

-- a small block of the left column: a small label in its color and its lines
local function note(g, y, color, label, lines)
	kit.text(g, label, 34, y, 15, color, "start", 1.5)
	for i, line in ipairs(lines) do
		fit(kit.text(g, line, 34, y + i * 26 + 2, i == 1 and 22 or 16, i == 1 and KC.SAND or KC.MUTE, "start", 0.5), 250)
	end
end

local function build_map(c)
	local g = c.kg
	local look = math.max(1, math.min(LAST, c.scelta.look or RING_AT))
	local from = c.look_from or look
	c.scelta.look, c.look_from = look, nil
	local r = T.rings[look]
	-- the circle looked at gives the screen its name and its color
	c.head = kit.header(c.buttons, r[2], RING_ACCENT[look], "indietro", common.home)
	local at, was = layout(look), layout(from)
	-- from the bottom up: each slice covers the back of the one under it; the
	-- one looked at over its neighbours
	-- (made last, not moved up afterwards: a child sent to the top with
	-- gui.move_above(node, nil) is no longer deleted with its parent, and the
	-- slice stayed on the home; Sergio, 12 Nov)
	for i = LAST, 1, -1 do
		if i ~= look then slice(c, i, at[i], was[i]) end
	end
	slice(c, look, at[look], was[look])
	-- under the last one: Favilla in the ice, the plate of the kidnapping (Sergio, 11 Nov)
	if look == LAST then
		local tex, size = ill.story(PRISON)
		local k = kit.card(g, MAP_X - 150, 426, 300, 176, KC.STEEL, {})
		if tex then
			c.prison = true
			kit.card_picture(k, tex, 168, size.w / size.h, 1)
		end
		kit.pop(k.node, from == look and 0.15 or LOOK_TIME)
	end
	-- on the left, under the name: where it is, its hazard, its keeper
	local tl = c.head.top_left
	local state = look == RING_AT and T.ring_here or look == RING_AT + 1 and T.ring_opens:format(T.rings[RING_AT][3]) or T.ring_closed
	kit.text(tl, T.ring_title:format(r[1], state), 34, 108, 16, KC.MUTE, "start", 1.5)
	note(tl, 170, KC.ICE, T.hazard, { r[4], r[5] })
	note(tl, 280, KC.HOT, T.keeper, { r[3] })
	-- the top floor, at the bottom left on the thread: the two chapters done
	local x = 168
	for _, cap in ipairs({ payload.CAPITOLI[1], payload.CAPITOLI[2] }) do
		local name = cap == payload.CAPITOLI[1] and T.cortile or kit.upper(cap.titolo)
		local p = kit.plate(c.low, x, 632, 230, 68, KC.ROSE, { sk = 0 })
		local b = p.box
		local mid = (b.y0 + b.y1) / 2
		local label = kit.text(p.g, name, b.x0, mid + 7, 19, KC.SAND, "start", 0.5)
		local got, all = chapter_stars(c, cap)
		local count = kit.text(p.g, T.ring_stars:format(got, all), b.x1, mid + 6, 15, KC.MUTE, "end", 0.5)
		ui.star(b.x1 - kit.width(count) - 14 - p.g.ox, p.g.oy - mid, 18, KC.STAR, p.g.node)
		fit(label, b.x1 - b.x0 - kit.width(count) - 34)
		kit.button(c.buttons, p, "capitolo:" .. cap.id)
		x = x + 240
	end
	-- (over the stack: the lower slices pass behind them)
	gui.move_above(c.low.node, c.radice)
	-- the rail, on the right: the nine circles at a glance, each one a way there
	local tr = c.head.top_right
	local top, step = 128, 54
	for i = 1, LAST do
		local y = top + (i - 1) * step
		local closed = i > RING_AT
		kit.text(tr, T.rings[i][1], 1186, y + 7, i == look and 22 or 17, i == look and KC.SAND or closed and KC.MUTE or RING_ACCENT[i], "end", 1)
		local mark = kit.piece(tr, closed and "lucchetto" or "brace", 1224, y, i == look and 46 or 34)
		if closed and i ~= look then gui.set_color(mark, vmath.vector4(0.6, 0.6, 0.68, 1)) end
		kit.zone(tr, c.buttons, 1120, y - step / 2, 160, step, "girone:" .. i)
	end
	c.play = nil
	c.action = kit.action(c.right, common.play, 930, 572, 270, 84, { size = 54, sub = T.coming_sub:format(T.rings[RING_AT][2]), off = true })
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
	-- after the kidnapping: the map of the circles, or (from the top floor) the
	-- board of a chapter, which goes back to the map
	local map = funnel_on(c)
	local on_map = map and c.scelta.view ~= "board"
	-- the backdrop
	kit.scene_focus(c.scene, on_map and 540 or 225, 360)
	c.on_map = on_map
	if on_map then return build_map(c) end
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
		local p = kit.plate(g, tabs_end + 30, 104, 190, 58, KC.ROSE, { sk = 0, d = 4, piece = "piastrina" })
		kit.text(p.g, TS.read_again, tabs_end + 30 + 95, 140, 19, KC.SAND, "middle", 0.5)
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
		kit.piece(g, "lucchetto", 820, 310, 96)
		kit.text(g, kit.upper(T.locked:format(prev and prev.titolo or payload.CAPITOLI[1].titolo)), 820, 404, 22, KC.SAND, "middle", 0.5)
		kit.text(g, kit.upper(T.done_count:format(done, tot)), 820, 436, 16, KC.MUTE, "middle", 1)
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
	c.scene = kit.scene(funnel_on(c) and choice.view ~= "board" and 540 or 225, 360, { bg = true })
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
			if look ~= c.scelta.look and look >= 1 and look <= LAST then
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
		-- another circle calls the stack there (its levels are still to come)
		local i = tonumber(value)
		if i == c.scelta.look then return nil end
		c.look_from, c.scelta.look = c.scelta.look, i
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
