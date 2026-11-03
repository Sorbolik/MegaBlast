-- Screen proportions: nothing ever gets distorted.
--
-- The game is drawn at 1280 x 720 (16:9). Every GUI node is FIT: the same
-- scale in x and in y (the smaller of the two), centered. On a wider screen
-- (20:9 phone) there is spare room on the sides, on a taller one (4:3 tablet)
-- above and below. Game coordinates stay those of 1280 x 720 with the center
-- at (640, 360), but the real screen goes from x0 to x1 and from y0 to y1:
-- what sticks to an edge (sticks, buttons) goes there.
--
-- Taps (action.x, action.y) instead arrive stretched over 1280 x 720:
-- from_touch brings them back to game coordinates. gui.pick_node wants the
-- stretched ones. Never gui.ADJUST_STRETCH: it distorts (oval circles).

local M = { W = 1280, H = 720, kx = 1, ky = 1, x0 = 0, x1 = 1280, y0 = 0, y1 = 720 }

-- a background this big covers any screen (up to 4 times wider or taller)
M.FULL = 4

-- Reads the window again; true if the proportions changed
function M.aggiorna()
	local w, h = window.get_size()
	if w <= 0 or h <= 0 then return false end
	local sx, sy = w / M.W, h / M.H
	local u = math.min(sx, sy)
	local kx, ky = sx / u, sy / u
	if kx == M.kx and ky == M.ky then return false end
	M.kx, M.ky = kx, ky
	M.x0, M.x1 = M.W / 2 * (1 - kx), M.W / 2 * (1 + kx)
	M.y0, M.y1 = M.H / 2 * (1 - ky), M.H / 2 * (1 + ky)
	return true
end

-- real width and height of the screen, in game pixels
function M.largo() return M.x1 - M.x0 end
function M.alto() return M.y1 - M.y0 end

function M.from_touch(x, y)
	return M.W / 2 + (x - M.W / 2) * M.kx, M.H / 2 + (y - M.H / 2) * M.ky
end

function M.on_touch(x, y)
	return M.W / 2 + (x - M.W / 2) / M.kx, M.H / 2 + (y - M.H / 2) / M.ky
end

return M
