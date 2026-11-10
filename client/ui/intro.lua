-- The opening shot of a campaign level (Sergio, 9 Nov: a moment of suspense
-- before the level, starting from the farthest-in zoom): black bars, the
-- camera starts on your devil at the nearest zoom, holds a beat, pulls back
-- to show the whole level with its title in the bottom bar, the bars go away,
-- the interface comes in and the camera settles on the play zoom. Only then
-- Favilla speaks. A tap skips to the end. The game is paused meanwhile.
--
--   local p = intro.new()
--   intro.start(p, "STAMMI DIETRO")      -- on the first frame of the level
--   local k, holding = intro.update(p, dt) -- k: 0..1 how far the camera has pulled back;
--                                        -- holding: false from when the game is released
--                                        -- (the bars still slide out for 0.25 s)
--   intro.skip(p)                        -- a tap: straight to the end
--   intro.active(p)

local screen = require "ui.screen"
local ui = require "ui.ui"

local M = {}

M.BAR = 96          -- height of each bar (a seventh of the screen)
M.HOLD = 0.7        -- on you, at the nearest zoom
M.PULL = 1.2        -- the camera pulls back
M.STAY = 0.4        -- the whole level, with the title
M.OUT = 0.25        -- the bars go away
M.TOTAL = M.HOLD + M.PULL + M.STAY
local GOLD = vmath.vector4(1, 0.82, 0.48, 1)

function M.new()
	return { t = nil }
end

local function bar(top)
	local n = gui.new_box_node(vmath.vector3(640, 0, 0), vmath.vector3(1280 * screen.FULL, M.BAR, 0))
	gui.set_color(n, vmath.vector4(0, 0, 0, 1))
	return n
end

local function place(p, out)
	-- `out` 0: the bars in their place; 1: past the edge of the screen
	local d = out * M.BAR
	gui.set_position(p.top, vmath.vector3(640, screen.y1 - M.BAR / 2 + d, 0))
	gui.set_position(p.bot, vmath.vector3(640, screen.y0 + M.BAR / 2 - d, 0))
end

function M.start(p, title)
	if not p.top then
		p.top, p.bot = bar(true), bar(false)
		p.title = ui.title("", 640, 0, 0.7, GOLD)
	end
	p.t = 0
	gui.set_enabled(p.top, true)
	gui.set_enabled(p.bot, true)
	gui.set_text(p.title, title or "")
	gui.set_color(p.title, vmath.vector4(1, 0.82, 0.48, 0))
	gui.set_enabled(p.title, true)
	place(p, 0)
	gui.move_above(p.top, nil)
	gui.move_above(p.bot, nil)
	gui.move_above(p.title, nil)
end

function M.active(p)
	return p.t ~= nil
end

function M.skip(p)
	if p.t and p.t < M.TOTAL then p.t = M.TOTAL end
end

local function ease(k)
	return k * k * (3 - 2 * k)
end

-- k: how much the camera has pulled back (0 on you, 1 on the whole level);
-- the second value is true while the game is still held (until the bars start to go)
function M.update(p, dt)
	if not p.t then return 1, false end
	p.t = p.t + dt
	local k = math.min(math.max((p.t - M.HOLD) / M.PULL, 0), 1)
	-- the title in the bottom bar, once the level is mostly in view
	local a = math.min(math.max((k - 0.6) / 0.4, 0), 1)
	if p.t >= M.TOTAL then a = 1 - math.min((p.t - M.TOTAL) / (M.OUT * 0.5), 1) end
	gui.set_color(p.title, vmath.vector4(1, 0.82, 0.48, a))
	gui.set_position(p.title, vmath.vector3(640, screen.y0 + M.BAR / 2, 0))
	if p.t >= M.TOTAL then
		local out = math.min((p.t - M.TOTAL) / M.OUT, 1)
		place(p, ease(out))
		if out >= 1 then
			gui.set_enabled(p.top, false)
			gui.set_enabled(p.bot, false)
			gui.set_enabled(p.title, false)
			p.t = nil
		end
		return 1, false
	end
	return ease(k), true
end

return M
