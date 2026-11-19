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
function M.update()
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
function M.width() return M.x1 - M.x0 end
function M.height() return M.y1 - M.y0 end

function M.from_touch(x, y)
	return M.W / 2 + (x - M.W / 2) * M.kx, M.H / 2 + (y - M.H / 2) * M.ky
end

-- Where a node is, in game coordinates (those of a node without parent).
-- gui.get_screen_position gives window pixels: on a phone (2712 x 1220) they
-- are not the game's 1280 x 720, and an effect put there flies off the screen.
function M.node_pos(node)
	local p = gui.get_screen_position(node)
	local w, h = window.get_size()
	if w <= 0 or h <= 0 then return p end
	local u = math.min(w / M.W, h / M.H)
	return vmath.vector3(M.W / 2 + (p.x - w / 2) / u, M.H / 2 + (p.y - h / 2) / u, 0)
end

function M.on_touch(x, y)
	return M.W / 2 + (x - M.W / 2) / M.kx, M.H / 2 + (y - M.H / 2) / M.ky
end

return M
