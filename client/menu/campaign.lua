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

-- the card miniatures of the chapter shown, given back to the GPU
local function release_textures(c)
	for _, t in ipairs(c.textures or {}) do ill.release(t[1], t[2]) end
	c.textures = {}
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
	-- the frame (ui/kit.lua): CAMPAGNA written as the logo, the way back at the
	-- bottom left, the chapters as tabs on their rail
	c.head = kit.header(c.buttons, common.campaign, KC.HOT, "indietro", common.home)
	c.right = kit.anchor(1280, 720, gui.ANCHOR_RIGHT, gui.ANCHOR_BOTTOM)
	c.low = kit.anchor(0, 720, gui.ANCHOR_LEFT, gui.ANCHOR_BOTTOM)
	c.radice = ui.root()
	c.kg = { node = c.radice, ox = 0, oy = 720 }
	local g = c.kg
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
	-- the game world darkened behind, the rays from the chapter's guide
	c.scene = kit.scene(225, 360, {})
	build(c)
	return c
end

function M.on_input(c, action_id, action)
	local ui_action = ui.touch(c.buttons, action_id, action)
	if not ui_action then return nil end
	if ui_action == "indietro" or ui_action == "storia" then return ui_action end
	local kind, value = ui_action:match("^(%a+):(.*)$")
	if ui_action == "gioca" then return c.play and { missione = c.play, da = c.from[c.play] } or nil end
	if kind == "missione" then return { missione = value, da = c.from[value] } end
	c.scelta.chapter = value
	build(c)
	return nil
end

function M.destroy(c)
	kit.header_delete(c.head)
	gui.delete_node(c.right.node)
	gui.delete_node(c.low.node)
	gui.delete_node(c.radice)
	release_textures(c)
	for _, n in ipairs(c.scene.tops) do gui.delete_node(n) end
end

return M
