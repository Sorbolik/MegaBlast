-- Terreno distruttibile: una griglia di celle.
--   0 = vuoto, 1 = terra (si distrugge), 2 = acciaio (indistruttibile, es. tubi)
-- Ogni cella è CELL x CELL unità del mondo. L'origine è in basso a sinistra
-- e la y cresce verso l'alto, come in Defold.

local rng = require "sim.rng"

local M = {}
M.__index = M

M.EMPTY = 0
M.DIRT = 1
M.STEEL = 2

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

-- C'è terreno nel rettangolo di celle [cx0, cx1] x [cy0, cy1]? Come get, fuori
-- dalla griglia è vuoto. È il controllo più usato della simulazione (le
-- collisioni dei robot): legge data direttamente invece di chiamare get cella
-- per cella, molto più veloce sia in LuaJIT sia sul server (gopher-lua).
function M:any_solid(cx0, cx1, cy0, cy1)
	local w, data = self.w, self.data
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

-- C'è terreno (di qualsiasi tipo) nel punto del mondo (x, y)?
function M:solid(x, y)
	local c = self.cell
	return self:get(math.floor(x / c), math.floor(y / c)) ~= 0
end

-- Forme per disegnare le mappe (coordinate del mondo) ---------------------------

-- Riempie le celle il cui centro soddisfa inside(px, py), dentro il rettangolo dato.
local function fill(t, x0, y0, x1, y1, v, inside)
	local c = t.cell
	for cy = math.max(0, math.floor(y0 / c)), math.min(t.h - 1, math.floor(y1 / c)) do
		local py = (cy + 0.5) * c
		for cx = math.max(0, math.floor(x0 / c)), math.min(t.w - 1, math.floor(x1 / c)) do
			if inside((cx + 0.5) * c, py) then
				t.data[cy * t.w + cx + 1] = v
			end
		end
	end
end

function M:rect(x, y, w, h, v)
	fill(self, x, y, x + w, y + h, v, function() return true end)
end

function M:circle(x, y, r, v)
	local r2 = r * r
	fill(self, x - r, y - r, x + r, y + r, v, function(px, py)
		local dx, dy = px - x, py - y
		return dx * dx + dy * dy <= r2
	end)
end

-- Un "tubo": segmento da (x1, y1) a (x2, y2) con spessore r.
function M:capsule(x1, y1, x2, y2, r, v)
	local dx, dy = x2 - x1, y2 - y1
	local len2 = dx * dx + dy * dy
	local r2 = r * r
	fill(self, math.min(x1, x2) - r, math.min(y1, y2) - r, math.max(x1, x2) + r, math.max(y1, y2) + r, v,
		function(px, py)
			local k = len2 > 0 and math.max(0, math.min(1, ((px - x1) * dx + (py - y1) * dy) / len2)) or 0
			local qx, qy = x1 + dx * k - px, y1 + dy * k - py
			return qx * qx + qy * qy <= r2
		end)
end

-- Carica una maschera disegnata a mano: una stringa per riga dal basso, fatta di
-- tratti "carattere + lunghezza" (. vuoto, d terra, s acciaio). Vedi sim/mapdata.lua.
local CODES = { ["."] = 0, d = 1, s = 2 }

function M:load(rows)
	for cy = 0, math.min(#rows, self.h) - 1 do
		local cx = 0
		for ch, n in rows[cy + 1]:gmatch("([%.ds])(%d+)") do
			local v = CODES[ch]
			for _ = 1, tonumber(n) do
				self:set(cx, cy, v)
				cx = cx + 1
			end
		end
	end
end

-- Colline casuali con qualche grotta, a partire da un seed.
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
	for _ = 1, 3 do
		local x = r:range(0.15, 0.85) * w * self.cell
		local y = r:range(0.12, 0.25) * h * self.cell
		self:carve(x, y, r:range(20, 40))
	end
end

-- Scava un cerchio di raggio radius centrato in (x, y) (coordinate del mondo).
-- L'acciaio resta intatto. Restituisce le righe toccate (cy_min, cy_max).
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
			local i = cy * self.w + cx + 1
			if dx * dx + dy * dy <= r2 and self.data[i] == 1 then
				self.data[i] = 0
			end
		end
	end
	return cy0, cy1
end

-- Prima superficie sotto la quota y nella colonna x (o nil se non c'è niente).
function M:ground_below(x, y)
	local cx = math.floor(x / self.cell)
	local start = math.min(self.h - 1, math.floor(y / self.cell))
	for cy = start, 0, -1 do
		if self:get(cx, cy) ~= 0 and self:get(cx, cy + 1) == 0 then return (cy + 1) * self.cell end
	end
	return nil
end

-- Superficie più alta nella colonna x (o nil se vuota).
function M:surface_y(x)
	return self:ground_below(x, self.h * self.cell)
end

return M
