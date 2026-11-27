-- A window of piece cards that scrolls (the ZAINO's pieces, the BOTTEGA's wares): the
-- cards are cut at its edges (stencil), the rows that leave it fade, their zones work
-- only inside it; a drag inside it or the mouse wheel moves them (a drag is not a tap),
-- a thin track on the right says how much there is.
--
--   local L = card_list.new(g, view, scroll)        view = { x, y, w, h } (Figma); scroll: where it was
--   local cg = card_list.item(L, x, y, h)           a group for one card (Figma coords), y..y+h tall
--   card_list.zone(L, buttons, x, y, w, h, action)  a tap zone of a card, only inside the window
--   card_list.done(L, g, bottom)                    after the cards: bottom = the last card's bottom
--   card_list.input(L, buttons, action_id, action) -> true when it took the touch
--   L.scroll                                        to keep when the screen is built again

local ui = require "ui.ui"
local kit = require "ui.kit"

local M = {}

local KC = kit.C
local WHEEL_UP, WHEEL_DOWN, WHEEL_STEP = hash("zoom_avanti"), hash("zoom_indietro"), 60

function M.new(g, view, scroll)
	local clip = gui.new_box_node(vmath.vector3(view.x + view.w / 2 - g.ox, g.oy - (view.y + view.h / 2), 0),
		vmath.vector3(view.w, view.h, 0))
	gui.set_parent(clip, g.node)
	gui.set_clipping_mode(clip, gui.CLIPPING_MODE_STENCIL)
	gui.set_clipping_visible(clip, false)
	gui.set_adjust_mode(clip, gui.ADJUST_FIT)
	local v = { node = clip, ox = view.x + view.w / 2, oy = view.y + view.h / 2 }
	local L = { view = view, clip = clip, items = {}, scroll = scroll or 0 }
	L.g = kit.group(v, v.ox, v.oy)
	return L
end

function M.item(L, x, y, h)
	local cg = kit.group(L.g, x, y)
	gui.set_inherit_alpha(cg.node, true)
	L.items[#L.items + 1] = { g = cg, y = y, h = h }
	return cg
end

function M.zone(L, buttons, x, y, w, h, action)
	local b = kit.zone(L.g, buttons, x, y, w, h, action)
	b.inside = L.clip
	return b
end

-- the rows that leave the window at the top or the bottom fade out (the list goes on)
local function fade(L)
	local v = L.view
	for _, c in ipairs(L.items) do
		local top = c.y - L.scroll
		local a = 1
		if top + c.h > v.y + v.h then a = math.max(0.15, math.min(1, (v.y + v.h - top) / c.h)) end
		if top < v.y then a = math.max(0.15, math.min(1, (top + c.h - v.y) / c.h)) end
		gui.set_alpha(c.g.node, a)
	end
	if L.thumb then
		local max = L.max
		local len = math.max(24, v.h * v.h / (v.h + max))
		local y0 = (max > 0 and (L.scroll / max) * (v.h - 24 - len) or 0)
		gui.set_position(L.thumb.node, vmath.vector3(0, -y0, 0))
	end
end

local function move(L, to)
	L.scroll = math.max(0, math.min(L.max, to))
	gui.set_position(L.g.node, vmath.vector3(0, L.scroll, 0))
	fade(L)
end

function M.done(L, g, bottom)
	local v = L.view
	-- everything in a card fades with its row
	for _, c in ipairs(L.items) do
		for _, n in pairs(gui.get_tree(c.g.node)) do gui.set_inherit_alpha(n, true) end
	end
	L.max = math.max(0, bottom + 12 - (v.y + v.h))
	-- (a few pixels more than the window: it doesn't scroll for that)
	if L.max < 14 then L.max = 0 end
	L.scroll = math.max(0, math.min(L.scroll, L.max))
	gui.set_position(L.g.node, vmath.vector3(0, L.scroll, 0))
	-- a thin track on the right of the window, when there is more than it shows
	L.thumb = nil
	if L.max > 0 then
		local tx = v.x + v.w - 6
		kit.line(g, tx, v.y + 12, tx, v.y + v.h - 12, 6, KC.INK)
		local len = math.max(24, v.h * v.h / (v.h + L.max))
		L.thumb = kit.group(g, 0, 0)
		kit.line(L.thumb, tx, v.y + 12, tx, v.y + 12 + len, 6, KC.STEEL)
	end
	fade(L)
end

function M.input(L, buttons, action_id, action)
	if not L then return false end
	-- on a desktop the mouse wheel scrolls, as in a browser
	if action_id == WHEEL_UP or action_id == WHEEL_DOWN then
		if L.max > 0 and action.pressed then move(L, L.scroll + (action_id == WHEEL_UP and -WHEEL_STEP or WHEEL_STEP)) end
		return L.max > 0
	end
	if action_id ~= ui.TOUCH then return false end
	if action.pressed then
		L.drag = nil
		if L.max > 0 and gui.pick_node(L.clip, action.x, action.y) then
			L.drag = { y = action.y, from = L.scroll, moved = false }
		end
		return false
	end
	local d = L.drag
	if not d then return false end
	if action.released then
		L.drag = nil
		return d.moved
	end
	local dy = action.y - d.y
	if not d.moved and math.abs(dy) > 10 then
		d.moved = true
		local b = buttons.held_down
		if b then gui.set_scale(b.nodo, vmath.vector3(1, 1, 1)) end
		buttons.held_down = nil
	end
	-- the list follows the finger
	if d.moved then move(L, d.from + dy) end
	return d.moved
end

return M
