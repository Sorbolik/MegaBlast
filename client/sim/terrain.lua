-- Destructible terrain: a grid of cells.
--   0 = empty, 1 = dirt (destructible), 2 = steel (indestructible)
-- Each cell is CELL x CELL world units. The origin is bottom left and y grows
-- upwards, as in Defold. The grid has ox extra columns on each side of the map
-- (world x from -ox * cell): cell column cx of the world sits at data index
-- cx + ox, so the platforms that jut out of the map sides (Sergio, 9 Nov) live
-- at negative x and every other coordinate stays as it was.

local M = {}
M.__index = M

M.EMPTY = 0
M.DIRT = 1
M.STEEL = 2

function M.new(w, h, cell, ox)
	local t = setmetatable({ w = w, h = h, cell = cell, ox = ox or 0, data = {} }, M)
	for i = 1, w * h do t.data[i] = 0 end
	return t
end

-- Value of cell (cx, cy). Outside the grid it is always empty.
function M:get(cx, cy)
	cx = cx + self.ox
	if cx < 0 or cy < 0 or cx >= self.w or cy >= self.h then return 0 end
	return self.data[cy * self.w + cx + 1]
end

function M:set(cx, cy, v)
	cx = cx + self.ox
	if cx < 0 or cy < 0 or cx >= self.w or cy >= self.h then return end
	self.data[cy * self.w + cx + 1] = v
end

-- Is there terrain in the cell rectangle [cx0, cx1] x [cy0, cy1]? Like get,
-- outside the grid is empty. It is the most used check of the simulation
-- (robot collisions): it reads data directly instead of calling get cell by
-- cell, much faster both in LuaJIT and on the server (gopher-lua).
function M:any_solid(cx0, cx1, cy0, cy1)
	local w, data = self.w, self.data
	cx0, cx1 = cx0 + self.ox, cx1 + self.ox
	if cx0 < 0 then cx0 = 0 end
	if cy0 < 0 then cy0 = 0 end
	if cx1 > w - 1 then cx1 = w - 1 end
	if cy1 > self.h - 1 then cy1 = self.h - 1 end
	for cy = cy0, cy1 do
		local row = cy * w + 1
		for i = row + cx0, row + cx1 do
			if data[i] ~= 0 then return true end
		end
	end
	return false
end

-- Is there terrain (of any kind) at the world point (x, y)?
function M:solid(x, y)
	local c = self.cell
	return self:get(math.floor(x / c), math.floor(y / c)) ~= 0
end

-- Shapes to draw maps (world coordinates) ---------------------------------------

-- Fills with v the cells whose center is inside the rectangle (the mission
-- arenas, sim/missions.lua).
function M:rect(x, y, w, h, v)
	local c = self.cell
	local ox = self.ox
	for cy = math.max(0, math.floor(y / c)), math.min(self.h - 1, math.floor((y + h) / c)) do
		for cx = math.max(-ox, math.floor(x / c)), math.min(self.w - ox - 1, math.floor((x + w) / c)) do
			self.data[cy * self.w + cx + ox + 1] = v
		end
	end
end

-- Loads a hand-drawn mask: one string per row from the bottom, made of
-- "character + length" runs (. empty, d dirt, s steel). See sim/mapdata.lua.
local CODES = { ["."] = 0, d = 1, s = 2 }

function M:load(rows)
	for cy = 0, math.min(#rows, self.h) - 1 do
		local cx = -self.ox
		for ch, n in rows[cy + 1]:gmatch("([%.ds])(%d+)") do
			local v = CODES[ch]
			for _ = 1, tonumber(n) do
				self:set(cx, cy, v)
				cx = cx + 1
			end
		end
	end
end

-- Carves a circle of radius radius centered at (x, y) (world coordinates).
-- Steel stays intact. Returns the rows touched (cy_min, cy_max).
function M:carve(x, y, radius)
	local c = self.cell
	local ox = self.ox
	local cx0 = math.max(-ox, math.floor((x - radius) / c))
	local cx1 = math.min(self.w - ox - 1, math.floor((x + radius) / c))
	local cy0 = math.max(0, math.floor((y - radius) / c))
	local cy1 = math.min(self.h - 1, math.floor((y + radius) / c))
	local r2 = radius * radius
	for cy = cy0, cy1 do
		local dy = (cy + 0.5) * c - y
		for cx = cx0, cx1 do
			local dx = (cx + 0.5) * c - x
			local i = cy * self.w + cx + ox + 1
			if dx * dx + dy * dy <= r2 and self.data[i] == 1 then
				self.data[i] = 0
			end
		end
	end
	return cy0, cy1
end

-- First surface below height y in column x (or nil if there is nothing).
function M:ground_below(x, y)
	local cx = math.floor(x / self.cell)
	local start = math.min(self.h - 1, math.floor(y / self.cell))
	for cy = start, 0, -1 do
		if self:get(cx, cy) ~= 0 and self:get(cx, cy + 1) == 0 then return (cy + 1) * self.cell end
	end
	return nil
end

-- Highest surface in column x (or nil if empty).
function M:surface_y(x)
	return self:ground_below(x, self.h * self.cell)
end

return M
