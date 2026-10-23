-- Camera della battaglia: guarda un punto del mondo con uno zoom, e lo insegue
-- con una molla esponenziale (uguale a 60, 90 o 120 Hz). Non esce mai dalla
-- mappa: con lo zoom 1 si vede tutta.
--
-- Lua puro: game.gui_script la applica al nodo "mondo" della GUI e alla vista
-- del render (terreno). Da schermo a mondo: x = (sx - tx) / s.
--
--   local c = camera.new(1280, 720)
--   camera.segui(c, dt, x, y, zoom, veloce)   -- a ogni frame
--   local tx, ty = camera.spostamento(c)      -- schermo = mondo * c.s + t

local M = {}

-- livelli di zoom che si scelgono col pulsante, la rotella o il tasto Z
M.LIVELLI = { 2.2, 1.5, 1 }
M.NOMI = { "VICINO", "MEDIO", "MAPPA" }

-- quanto in fretta la camera raggiunge il punto (1/s): più alto = più rigida
local SEGUI, SEGUI_VELOCE, ZOOM = 5, 9, 6

local function limita(c)
	local hw, hh = c.w / (2 * c.s), c.h / (2 * c.s)
	c.x = math.min(math.max(c.x, hw), c.w - hw)
	c.y = math.min(math.max(c.y, hh), c.h - hh)
end

function M.new(w, h)
	local c = { w = w, h = h, x = w / 2, y = h / 2, s = 1, livello = 1 }
	return c
end

-- Va subito sul punto, senza inseguirlo (inizio partita, menu)
function M.salta(c, x, y, s)
	c.x, c.y, c.s = x, y, s
	limita(c)
end

-- veloce: per i colpi in volo, che altrimenti scappano dallo schermo
function M.segui(c, dt, x, y, s, veloce)
	c.s = c.s + (s - c.s) * (1 - math.exp(-dt * ZOOM))
	local k = 1 - math.exp(-dt * (veloce and SEGUI_VELOCE or SEGUI))
	c.x = c.x + (x - c.x) * k
	c.y = c.y + (y - c.y) * k
	limita(c)
end

function M.spostamento(c)
	return c.w / 2 - c.x * c.s, c.h / 2 - c.y * c.s
end

function M.al_mondo(c, sx, sy)
	local tx, ty = M.spostamento(c)
	return (sx - tx) / c.s, (sy - ty) / c.s
end

function M.allo_schermo(c, x, y)
	local tx, ty = M.spostamento(c)
	return x * c.s + tx, y * c.s + ty
end

function M.zoom(c)
	return M.LIVELLI[c.livello]
end

-- passo +1 = più lontano, -1 = più vicino
function M.cambia(c, passo)
	c.livello = math.min(#M.LIVELLI, math.max(1, c.livello + passo))
end

-- il pulsante gira: vicino, medio, mappa, vicino...
function M.prossimo(c)
	c.livello = c.livello % #M.LIVELLI + 1
end

return M
