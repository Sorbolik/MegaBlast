-- La bandierina a scacchi delle lezioni (sim/missioni.lua, raggiungi con
-- bandiera): un'asta e un drappo a scacchi bianchi e neri che sventola, nel
-- mondo, dove devi arrivare. Pochi nodi fatti una volta.
--
--   local b = bandiera.new(mondo, sotto)   -- mondo: il nodo del mondo; sotto: il nodo da tenere davanti
--   b:mostra(x, y, clock)                  -- a ogni frame; x nil: non c'è

local M = {}

-- misure in unità del mondo (il diavoletto è alto una ventina)
local ASTA_H, ASTA_W = 38, 1.6
local COLONNE, RIGHE, LATO = 6, 4, 3
local BIANCO = vmath.vector4(0.95, 0.93, 0.9, 1)
local NERO = vmath.vector4(0.08, 0.07, 0.09, 1)
local ASTA = vmath.vector4(0.62, 0.58, 0.55, 1)
local V = vmath.vector3()
local EULER = vmath.vector3()

local function box(x, y, w, h, colore, parent)
	local n = gui.new_box_node(vmath.vector3(x, y, 0), vmath.vector3(w, h, 0))
	gui.set_color(n, colore)
	gui.set_parent(n, parent)
	return n
end

function M.new(mondo, sotto)
	local b = setmetatable({}, { __index = M })
	b.radice = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(0, 0, 0))
	gui.set_parent(b.radice, mondo)
	if sotto then gui.move_below(b.radice, sotto) end
	box(0, ASTA_H / 2, ASTA_W, ASTA_H, ASTA, b.radice)
	-- il drappo gira attorno all'attacco in cima all'asta
	b.drappo = box(ASTA_W / 2, ASTA_H - RIGHE * LATO / 2, 0, 0, BIANCO, b.radice)
	for i = 0, COLONNE - 1 do
		for j = 0, RIGHE - 1 do
			box((i + 0.5) * LATO, (j + 0.5 - RIGHE / 2) * LATO, LATO, LATO, (i + j) % 2 == 0 and NERO or BIANCO, b.drappo)
		end
	end
	gui.set_enabled(b.radice, false)
	return b
end

function M.mostra(b, x, y, clock)
	gui.set_enabled(b.radice, x ~= nil)
	if not x then return end
	V.x, V.y, V.z = x, y, 0
	gui.set_position(b.radice, V)
	EULER.z = math.sin((clock or 0) * 3) * 6
	gui.set_euler(b.drappo, EULER)
end

return M
