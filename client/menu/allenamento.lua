-- Allenamento: partita sullo stesso telefono contro i bot (sim/bot.lua). Si
-- sceglie il modo (il giocatore è sempre il primo robot; nel 2 contro 2 il
-- compagno è un bot) e il livello dei bot, poi GIOCA. Stile in ui/ui.lua.
--
--   local allenamento = require "menu.allenamento"
--   local a = allenamento.new(scelta)        -- scelta = { modo = "1v1", livello = "normale" } (l'ultima)
--   local fine = allenamento.on_input(a, action_id, action)
--     -- "indietro", { modo = ..., livello = ... } per giocare, o nil
--   allenamento.distruggi(a)

local ui = require "ui.ui"

local M = {}

local MODI = { { "1v1", "1 CONTRO 1" }, { "2v2", "2 CONTRO 2" }, { "ffa", "TUTTI CONTRO TUTTI" } }
local LIVELLI = { { "facile", "FACILE" }, { "normale", "NORMALE" }, { "difficile", "DIFFICILE" } }

local function vec(x, y) return vmath.vector3(x, y, 0) end

local function costruisci(a)
	if a.radice then gui.delete_node(a.radice) end
	a.bottoni = {}
	a.radice = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_visible(a.radice, false)
	local c = ui.C
	ui.indietro(a.bottoni, "indietro", a.radice)
	ui.titolo("CONTRO I BOT", 640, 600, 1, c.TESTO, a.radice)
	ui.testo("MODO", 640, 500, 0.7, c.SPENTO, a.radice)
	for i, m in ipairs(MODI) do
		ui.scheda(a.bottoni, 640 + (i - 2) * 330, 440, 310, 64, m[2], "modo:" .. m[1], a.scelta.modo == m[1], a.radice)
	end
	ui.testo("BOT", 640, 340, 0.7, c.SPENTO, a.radice)
	for i, l in ipairs(LIVELLI) do
		ui.scheda(a.bottoni, 640 + (i - 2) * 250, 280, 230, 64, l[2], "livello:" .. l[1], a.scelta.livello == l[1], a.radice)
	end
	ui.bottone(a.bottoni, 640, 130, 340, 108, "GIOCA", "gioca", { principale = true }, a.radice)
end

function M.new(scelta)
	local a = { scelta = scelta }
	a.fondo = ui.sfondo()
	costruisci(a)
	return a
end

function M.on_input(a, action_id, action)
	local azione = ui.tocco(a.bottoni, action_id, action)
	if not azione then return nil end
	if azione == "indietro" then return "indietro" end
	if azione == "gioca" then return { modo = a.scelta.modo, livello = a.scelta.livello } end
	local tipo, valore = azione:match("^(%a+):(.*)$")
	a.scelta[tipo] = valore
	costruisci(a)
	return nil
end

function M.distruggi(a)
	gui.delete_node(a.radice)
	gui.delete_node(a.fondo)
end

return M
