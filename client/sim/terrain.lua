-- Terreno distruttibile: una griglia di celle piene (1) o vuote (0).
-- Ogni cella è CELL x CELL unità del mondo. L'origine è in basso a sinistra
-- e la y cresce verso l'alto, come in Defold.

local rng = require "sim.rng"

local M = {}
M.__index = M

function M.new(w, h, cell)
	local t = setmetatable({ w = w, h = h, cell = cell, data = {} }, M)
	for i = 1, w * h do t.data[i] = 0 end
	return t
end

-- Valore della cella (cx, cy). Fuori dalla griglia è sempre vuoto.
function M:get(cx, cy)
	if cx < 0 or cy < 0 or cx >= self.w or cy >= self.h then return 0 end
	return self.data[cy * self.w + cx + 1]
end

function M:set(cx, cy, v)
	if cx < 0 or cy < 0 or cx >= self.w or cy >= self.h then return end
	self.data[cy * self.w + cx + 1] = v
end

-- C'è terreno nel punto del mondo (x, y)?
function M:solid(x, y)
	local c = self.cell
	return self:get(math.floor(x / c), math.floor(y / c)) == 1
end

-- Genera colline con qualche grotta a partire da un seed.
function M:generate(seed)
	local r = rng.new(seed)
	local w, h = self.w, self.h
	local waves = {}
	for i = 1, 4 do
		waves[i] = { amp = r:range(0.03, 0.12) / i, freq = r:range(1, 3) * i, phase = r:range(0, 6.283) }
	end
	for cx = 0, w - 1 do
		local u = cx / w
		local height = 0.38
		for i = 1, #waves do
			local wv = waves[i]
			height = height + wv.amp * math.sin(u * wv.freq * 6.283 + wv.phase)
		end
		local top = math.floor(height * h)
		for cy = 0, top do self:set(cx, cy, 1) end
	end
	-- Qualche grotta per rendere la mappa più interessante
	for _ = 1, 3 do
		local x = r:range(0.15, 0.85) * w * self.cell
		local y = r:range(0.12, 0.25) * h * self.cell
		self:carve(x, y, r:range(20, 40))
	end
end

-- Scava un cerchio vuoto di raggio radius centrato in (x, y) (coordinate del mondo).
-- Restituisce le righe di celle toccate (cy_min, cy_max) per ridisegnare solo quelle.
function M:carve(x, y, radius)
	local c = self.cell
	local cx0 = math.max(0, math.floor((x - radius) / c))
	local cx1 = math.min(self.w - 1, math.floor((x + radius) / c))
	local cy0 = math.max(0, math.floor((y - radius) / c))
	local cy1 = math.min(self.h - 1, math.floor((y + radius) / c))
	local r2 = radius * radius
	for cy = cy0, cy1 do
		local dy = (cy + 0.5) * c - y
		for cx = cx0, cx1 do
			local dx = (cx + 0.5) * c - x
			if dx * dx + dy * dy <= r2 then
				self.data[cy * self.w + cx + 1] = 0
			end
		end
	end
	return cy0, cy1
end

-- Altezza della superficie più alta nella colonna del mondo x (o nil se vuota).
function M:surface_y(x)
	local cx = math.floor(x / self.cell)
	for cy = self.h - 1, 0, -1 do
		if self:get(cx, cy) == 1 then return (cy + 1) * self.cell end
	end
	return nil
end

return M
