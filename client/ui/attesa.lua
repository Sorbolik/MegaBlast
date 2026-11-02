-- La fiammella d'attesa (Sergio, 1 nov): quando il gioco aspetta davvero
-- qualcosa (la connessione, gli avversari, la riconnessione) al centro dello
-- schermo arde la testa di Favilla nel suo disco di carta, con una riga sotto.
-- Compare solo se l'attesa dura più di DOPO secondi (le attese brevi non si
-- vedono) e, se compare, resta almeno ALMENO secondi (niente lampeggi).
--
--   local attesa = require "ui.attesa"
--   local a = attesa.new()
--   attesa.mostra(a, "In attesa di un avversario...")
--   attesa.via(a)
--   attesa.update(a, dt)

local ui = require "ui.ui"

local M = {}

M.DOPO = 0.3
M.ALMENO = 0.4
local CARTA = vmath.vector4(0.94, 0.9, 0.82, 1)
local V = vmath.vector3()

function M.new()
	local a = { t = 0 }
	a.nodo = gui.new_box_node(vmath.vector3(640, 380, 0), vmath.vector3(0, 0, 0))
	gui.set_visible(a.nodo, false)
	a.alone = ui.alone(0, 0, 300, ui.C.BRACE, a.nodo)
	a.disco = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(120, 120, 0))
	gui.set_texture(a.disco, "ui")
	gui.play_flipbook(a.disco, "favilla")
	gui.set_color(a.disco, CARTA)
	gui.set_parent(a.disco, a.nodo)
	a.riga = ui.testo("", 0, -100, 0.8, ui.C.TESTO, a.nodo)
	gui.set_enabled(a.nodo, false)
	return a
end

function M.mostra(a, testo)
	gui.set_text(a.riga, testo)
	if not a.chiesta then
		a.chiesta, a.t, a.visto = true, 0, nil
	end
	a.chiudi = nil
end

function M.via(a)
	if not a.chiesta then return end
	if a.visto and a.visto < M.ALMENO then
		a.chiudi = true
		return
	end
	a.chiesta, a.visto, a.chiudi = nil, nil, nil
	gui.set_enabled(a.nodo, false)
end

function M.update(a, dt)
	if not a.chiesta then return end
	a.t = a.t + dt
	if not a.visto and a.t >= M.DOPO then
		a.visto = 0
		gui.set_enabled(a.nodo, true)
		gui.move_above(a.nodo, nil)
	end
	if not a.visto then return end
	a.visto = a.visto + dt
	if a.chiudi and a.visto >= M.ALMENO then
		M.via(a)
		return
	end
	-- arde: respira veloce, la brace pulsa
	local k = 1 + 0.035 * math.sin(a.t * 7)
	V.x, V.y, V.z = k, k, 1
	gui.set_scale(a.disco, V)
	local c = ui.C.BRACE
	gui.set_color(a.alone, vmath.vector4(c.x, c.y, c.z, 0.28 + 0.1 * math.sin(a.t * 4.3)))
end

return M
