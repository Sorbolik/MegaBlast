-- Proporzioni dello schermo: niente si deforma mai.
--
-- Il gioco è disegnato su 1280 x 720 (16:9). Ogni nodo della GUI è FIT: la
-- stessa scala in x e in y (la più piccola delle due), centrato. Su uno schermo
-- più largo (telefono 20:9) avanza spazio ai lati, su uno più alto (tablet 4:3)
-- sopra e sotto. Le coordinate del gioco restano quelle di 1280 x 720 con il
-- centro in (640, 360), ma lo schermo vero va da x0 a x1 e da y0 a y1: quello
-- che sta attaccato a un bordo (levette, pulsanti) si mette lì.
--
-- I tocchi (action.x, action.y) arrivano invece stirati su 1280 x 720: da_tocco
-- li riporta alle coordinate del gioco. gui.pick_node vuole quelli stirati.
-- Mai gui.ADJUST_STRETCH: deforma (cerchi ovali).

local M = { W = 1280, H = 720, kx = 1, ky = 1, x0 = 0, x1 = 1280, y0 = 0, y1 = 720 }

-- un fondo grande così copre ogni schermo (fino a 4 volte più largo o più alto)
M.PIENO = 4

-- Rilegge la finestra; true se le proporzioni sono cambiate
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

-- larghezza e altezza vere dello schermo, in pixel del gioco
function M.largo() return M.x1 - M.x0 end
function M.alto() return M.y1 - M.y0 end

function M.da_tocco(x, y)
	return M.W / 2 + (x - M.W / 2) * M.kx, M.H / 2 + (y - M.H / 2) * M.ky
end

function M.a_tocco(x, y)
	return M.W / 2 + (x - M.W / 2) / M.kx, M.H / 2 + (y - M.H / 2) / M.ky
end

return M
