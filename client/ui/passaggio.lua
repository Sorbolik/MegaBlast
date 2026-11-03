-- I passaggi tra le schermate (Sergio, 1 nov), con un solo velo sopra tutto
-- (ui/passaggio.fp):
--   iride   tra la home (o i menu) e la battaglia: il cerchio dei vecchi cartoni
--           si chiude sul nero, la scena cambia, si riapre (150 + 150 ms)
--   scivolo tra i menu: la schermata vecchia scivola del 7% a sinistra e si
--           spegne nel carbone, la nuova arriva da destra (80 + 80 ms);
--           tornando indietro al contrario
-- Mentre un passaggio è in corso il gioco non ascolta i tocchi (attivo).
--
--   local passaggio = require "ui.passaggio"
--   local p = passaggio.new()
--   passaggio.iride(p, cambia)                     -- cambia(): la scena nuova
--   passaggio.scivolo(p, vecchi, cambia, verso)    -- vecchi: i nodi radice della
--        schermata di adesso; cambia() rende quelli della nuova; verso 1 avanti, -1 indietro
--   passaggio.attivo(p)

local schermo = require "ui.schermo"

local M = {}

local W, H = 1280, 720
M.IRIDE = 0.15           -- secondi per chiudere, e per riaprire
M.SCIVOLO = 0.08         -- metà dello scivolo
M.SPOSTA = W * 0.07      -- quanto scivola una schermata

function M.new()
	local n = gui.new_box_node(vmath.vector3(W / 2, H / 2, 0), vmath.vector3(W * schermo.PIENO, H * schermo.PIENO, 0))
	gui.set_adjust_mode(n, gui.ADJUST_FIT)
	gui.set_material(n, "passaggio")
	gui.set_enabled(n, false)
	return { nodo = n, colore = vmath.vector4(1, 0, 0, 0) }
end

function M.attivo(p)
	return p.n ~= nil
end

local function inizia(p, r, g, a)
	p.n = (p.n or 0) + 1
	local c = p.colore
	c.x, c.y, c.z, c.w = r, g, 0, a
	gui.set_color(p.nodo, c)
	gui.set_enabled(p.nodo, true)
	-- sopra a tutto, anche alle schermate create dopo
	gui.move_above(p.nodo, nil)
end

local function fine(p)
	gui.set_enabled(p.nodo, false)
	p.n = nil
end

function M.iride(p, cambia)
	inizia(p, 1, 0, 1)
	gui.animate(p.nodo, "color.x", 0, gui.EASING_INQUAD, M.IRIDE, 0, function()
		cambia()
		gui.move_above(p.nodo, nil)
		-- si riapre tre frame dopo, a schermo nero: cambiando mappa il frame del
		-- cambio (dipinto e maschera nuovi) è lungo, e spesso anche quello dopo (la
		-- GPU carica le texture nuove). Così gli scatti cadono sul nero e non
		-- sull'animazione (Sergio, 2 nov: «qualche scatto in più ... nelle
		-- schermate di transizione»)
		local k = p.n
		local function dopo(frame)
			-- se nel frattempo è partito un altro passaggio, lo chiude lui
			if p.n ~= k then return end
			if frame > 0 then
				timer.delay(0, false, function() dopo(frame - 1) end)
			else
				gui.animate(p.nodo, "color.x", 1, gui.EASING_OUTQUAD, M.IRIDE, 0, function() fine(p) end)
			end
		end
		dopo(3)
	end)
end

-- sposta i nodi di dx (con un'animazione di durata t) e rende dove stavano
local function sposta(nodi, dx, t, easing)
	local da = {}
	for i, n in ipairs(nodi) do
		local x = gui.get_position(n).x
		da[i] = x
		if t > 0 then
			gui.animate(n, "position.x", x + dx, easing, t)
		else
			local pos = gui.get_position(n)
			pos.x = x + dx
			gui.set_position(n, pos)
		end
	end
	return da
end

local function rimetti(nodi, da)
	for i, n in ipairs(nodi) do
		gui.cancel_animations(n, "position.x")
		local pos = gui.get_position(n)
		pos.x = da[i]
		gui.set_position(n, pos)
	end
end

function M.scivolo(p, vecchi, cambia, verso)
	verso = verso or 1
	inizia(p, 0, 1, 0)
	local da = sposta(vecchi, -verso * M.SPOSTA, M.SCIVOLO, gui.EASING_INQUAD)
	gui.animate(p.nodo, "color.w", 1, gui.EASING_INQUAD, M.SCIVOLO, 0, function()
		-- i nodi vecchi tornano a posto (la home si riusa), poi la scena cambia
		rimetti(vecchi, da)
		local nuovi = cambia() or {}
		gui.move_above(p.nodo, nil)
		local arrivo = sposta(nuovi, verso * M.SPOSTA, 0)
		for i, n in ipairs(nuovi) do
			gui.animate(n, "position.x", arrivo[i], gui.EASING_OUTQUAD, M.SCIVOLO)
		end
		gui.animate(p.nodo, "color.w", 0, gui.EASING_OUTQUAD, M.SCIVOLO, 0, function()
			fine(p)
		end)
	end)
end

return M
