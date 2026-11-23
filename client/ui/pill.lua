-- The queue pill (Sergio, 3 Nov: "una bella proposta di design che ti ricordi
-- che sei in coda e che ti faccia capire anche quando si sta riempiendo e
-- quando stai per essere portato in partita"): while you stay in the online
-- queue outside the waiting room, one pill, the same everywhere (Sergio, 15 Nov:
-- «sempre quella nuova e sempre nella posizione nuova sotto la linea»; 17 Nov:
-- in a match too, and its text always inside it): the shell strip, a hot dot
-- that breathes and the text, as wide as what it says. Three places:
--   "low"   the home: under the thread, in the middle of the room between the
--           wheel and GIOCA, with the whole text (IN CODA, the mode, the time,
--           BOT TRA). Tapping it goes back to the room;
--   "foot"  every screen with the thread (the menus, the lineup, the draft, the
--           podium): under the thread a little left of the middle, short (the
--           time, BOT 13): on the right the action's line, on the left what the
--           screen writes there (kit.foot_text). Tapping it goes back to the room;
--   "head"  the podium (its steps come down into the band): short, at the top,
--           just left of the wallet. Tapping it goes back to the room;
--   "top"   a battle (no thread there): short, right of the gear, or at the
--           edge where there is no gear. It can't be tapped (the finger is playing).
-- When the queue is full it says PARTITA TROVATA · 3 and the dot breathes
-- faster; in a match a veil comes down with the count. It is created above
-- everything and raised again when a screen opens (pill.raise).
--
--   local pill = require "ui.pill"
--   local p = pill.new()
--   pill.show(p, on, kind, gear)       -- kind: "low", "foot", "head", "top"; gear: the node "top" sits next to
--   pill.set(p, text, short, hot)      -- text for "low", short for the others
--   pill.flash(p)                      -- someone arrived: a small jump
--   pill.found(p, n)                   -- the veil with PARTITA TROVATA and n (nil: no veil)
--   pill.hit(p, x, y) -> true          -- x, y as gui.pick_node wants them
--   pill.raise(p)                      -- above the nodes created after it
--   pill.update(p, dt)

local ui = require "ui.ui"
local kit = require "ui.kit"
local screen = require "ui.screen"
local T = require("lang.text").pill

local M = {}

local C = ui.C
local W, H = 1280, 720
local V = vmath.vector3()

-- the pill: its height, the top of the ones under the thread, its text; along it
-- the dot's middle, where the text starts and the room left after it (the text
-- stays in the shell's trough, between the two rivets)
-- In the menus (low and foot) it is threaded on the thread, in the middle of the
-- screen, the same on every screen (Sergio, 23 Nov, docs/ui-catalogo.md purpose 12):
-- a thin thread around it (kit.thread_chip's pieces), the dot breathing flat
local TALL, SIZE = 40, 17
local DOT_X, TEXT_X, END_PAD = 26, 42, 22
local MIN_W = 112
-- how wide each kind can get (past it the text shrinks)
local MAX_W = { low = 520, foot = 240, head = 174, top = 174 }
-- "head": its right end, 16 before the wallet (ui/coins.lua), on the header's line
local HEAD_X1 = 860

function M.new()
	local p = { t = 0, w = MIN_W }
	-- the root at the pill's left end, at half its height
	p.root = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(0, 0, 0))
	gui.set_visible(p.root, false)
	local g = { node = p.root, ox = 0, oy = 0 }
	p.back = kit.strip(g, "filo_fondo", 0, -TALL / 2, MIN_W, TALL)
	p.strip = kit.strip(g, "filo_bordo", 0, -TALL / 2, MIN_W, TALL)
	kit.tint(p.strip.parts, kit.C.HOT)
	p.ring = gui.new_box_node(vmath.vector3(DOT_X, 0, 0), vmath.vector3(20, 20, 0))
	gui.set_texture(p.ring, "ui")
	gui.play_flipbook(p.ring, "disco_p")
	gui.set_color(p.ring, kit.C.INK)
	gui.set_size(p.ring, vmath.vector3(16, 16, 0))
	gui.set_parent(p.ring, p.root)
	p.dot = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(11, 11, 0))
	gui.set_texture(p.dot, "ui")
	gui.play_flipbook(p.dot, "disco_p")
	gui.set_color(p.dot, kit.C.HOT)
	gui.set_parent(p.dot, p.ring)
	p.text = kit.text(g, "", TEXT_X, SIZE * 0.36, SIZE, kit.C.SAND, "start", 1)
	p.scale = gui.get_scale(p.text)
	-- the veil of a match found in a battle: dark, with the count in the middle
	p.veil = gui.new_box_node(vmath.vector3(W / 2, H / 2, 0), vmath.vector3(W * screen.FULL, H * screen.FULL, 0))
	gui.set_adjust_mode(p.veil, gui.ADJUST_FIT)
	gui.set_color(p.veil, vmath.vector4(0.04, 0.03, 0.05, 0.6))
	ui.title(T.found, 0, 90, 1.1, C.LIGHT, p.veil)
	p.count = ui.title("3", 0, 0, 2.2, C.TEXT, p.veil)
	ui.text(T.cancelled, 0, -80, 0.8, C.OFF, p.veil)
	gui.set_enabled(p.veil, false)
	gui.set_enabled(p.root, false)
	return p
end

-- Where it sits: under the thread (stuck to the real bottom, like it), or at
-- the top left, right of the gear (which may move)
function M.place(p)
	if p.kind == "top" then
		V.x = p.gear and ui.TITLE_X or ui.EDGE
		V.y = p.gear and gui.get_position(p.gear).y or ui.HEAD_Y
	elseif p.kind == "head" then
		V.x, V.y = HEAD_X1 - p.w, H - 44
	else
		-- on the thread, in the middle of the screen: the thread is stuck to the real
		-- bottom edge (ui/screen.lua, y1), so the pill too
		V.x = W / 2 - p.w / 2
		V.y = (H - screen.y1) + (H - kit.THREAD)
	end
	V.z = 0
	gui.set_position(p.root, V)
end

-- The pill as wide as its text. The width is taken with every digit as a 0:
-- the time goes on and the pill stays still
local function fit(p)
	local text = (p.kind == "low" and p.long_text or p.short_text) or ""
	local shape = text:gsub("%d", "0")
	gui.set_text(p.text, text)
	if shape == p.shape and p.kind == p.fit_kind then return end
	p.shape, p.fit_kind = shape, p.kind
	gui.set_scale(p.text, p.scale)
	gui.set_text(p.text, shape)
	local wide = kit.width(p.text)
	gui.set_text(p.text, text)
	local w = math.max(MIN_W, math.min(MAX_W[p.kind] or MIN_W, TEXT_X + wide + END_PAD))
	local room = w - TEXT_X - END_PAD
	if wide > room then gui.set_scale(p.text, p.scale * (room / wide)); kit.check_small(p.text) end
	if w ~= p.w then
		kit.strip_width(p.back, w)
		kit.strip_width(p.strip, w)
		p.w = w
	end
	M.place(p)
end

function M.show(p, on, kind, gear)
	gui.set_enabled(p.root, on)
	if not on then
		gui.set_enabled(p.veil, false)
		return
	end
	p.gear = gear
	if kind ~= p.kind then
		p.kind = kind
		gui.set_xanchor(p.root, kind == "top" and gui.ANCHOR_LEFT or kind == "head" and gui.ANCHOR_RIGHT or gui.ANCHOR_NONE)
		gui.set_yanchor(p.root, (kind == "top" or kind == "head") and gui.ANCHOR_TOP or gui.ANCHOR_NONE)
		fit(p)
	end
	M.place(p)
	M.raise(p)
end

function M.set(p, text, short, hot)
	p.long_text, p.short_text, p.hot = text, short, hot
	if p.kind then fit(p) end
end

function M.flash(p)
	gui.cancel_animations(p.root, "scale")
	V.x, V.y, V.z = 1.12, 1.12, 1
	gui.set_scale(p.root, V)
	V.x, V.y = 1, 1
	gui.animate(p.root, "scale", V, gui.EASING_OUTBACK, 0.3)
end

function M.found(p, n)
	gui.set_enabled(p.veil, n ~= nil)
	if n then gui.set_text(p.count, tostring(n)) end
end

function M.hit(p, x, y)
	if not gui.is_enabled(p.root) or p.kind == "top" then return false end
	for _, n in ipairs(p.strip.parts) do
		if gui.pick_node(n, x, y) then return true end
	end
	return false
end

function M.raise(p)
	gui.move_above(p.veil, nil)
	gui.move_above(p.root, nil)
end

function M.update(p, dt)
	if not gui.is_enabled(p.root) then return end
	p.t = p.t + dt
	if p.kind == "top" and p.gear then M.place(p) end
	-- the hot dot breathes; the full queue faster
	local a = 0.55 + 0.45 * math.sin(p.t * (p.hot and 8 or 3))
	gui.set_color(p.dot, vmath.vector4(kit.C.HOT.x, kit.C.HOT.y, kit.C.HOT.z, a))
end

return M
