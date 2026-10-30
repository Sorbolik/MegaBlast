-- Il segnale sul bersaglio delle lezioni (sim/missioni.lua bersaglio): quattro
-- angoli rossi attorno a chi va colpito adesso, come un mirino agganciato, che
-- respirano. Diverso dalla luce gialla sui comandi: quella dice cosa usare,
-- questo chi colpire. Nel mondo, pochi nodi fatti una volta.
--
--   local s = segnale.new(mondo)        -- mondo: il nodo del mondo
--   s:mostra(x, y, alto, largo, clock)  -- a ogni frame: x, y i piedi; x nil: non c'è

local M = {}

-- misure in unità del mondo (il diavoletto è alto una ventina)
local BRACCIO, SPESSO, BORDO = 6, 1.6, 0.9
local MARGINE = 5
local ROSSO = vmath.vector4(1, 0.3, 0.22, 1)
local SCURO = vmath.vector4(0.1, 0.05, 0.07, 0.85)
local V = vmath.vector3()

local function box(w, h, colore, parent)
	local n = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(w, h, 0))
	gui.set_color(n, colore)
	gui.set_parent(n, parent)
	return n
end

-- un angolo: un tratto orizzontale e uno verticale che si toccano nel vertice,
-- col bordo scuro sotto perché si veda su ogni sfondo
local function angolo(parent, sx, sy)
	local a = { radice = box(0, 0, SCURO, parent), sx = sx, sy = sy }
	for _, colore in ipairs({ SCURO, ROSSO }) do
		local b = colore == SCURO and BORDO or 0
		local o = box(BRACCIO + 2 * b, SPESSO + 2 * b, colore, a.radice)
		gui.set_position(o, vmath.vector3(sx * (BRACCIO / 2 - SPESSO / 2), 0, 0))
		local v = box(SPESSO + 2 * b, BRACCIO + 2 * b, colore, a.radice)
		gui.set_position(v, vmath.vector3(0, sy * (BRACCIO / 2 - SPESSO / 2), 0))
	end
	return a
end

function M.new(mondo)
	local s = setmetatable({}, { __index = M })
	s.radice = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(0, 0, 0))
	gui.set_parent(s.radice, mondo)
	-- il vertice di ogni angolo guarda fuori, i bracci verso il centro
	s.angoli = {
		angolo(s.radice, 1, -1), angolo(s.radice, -1, -1),
		angolo(s.radice, 1, 1), angolo(s.radice, -1, 1),
	}
	gui.set_enabled(s.radice, false)
	return s
end

function M.mostra(s, x, y, alto, largo, clock)
	gui.set_enabled(s.radice, x ~= nil)
	if not x then return end
	V.x, V.y, V.z = x, y + alto / 2, 0
	gui.set_position(s.radice, V)
	-- respira: si stringe e si allarga di poco, due volte al secondo
	local d = MARGINE + 1.5 * (1 + math.sin((clock or 0) * 6))
	local mx, my = largo + d, alto / 2 + d
	for _, a in ipairs(s.angoli) do
		V.x, V.y = -a.sx * mx, -a.sy * my
		gui.set_position(a.radice, V)
	end
end

return M
