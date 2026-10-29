-- Allenamento (bottone ALLENAMENTO della home): due schede. LEZIONI: la prima
-- partita guidata e le lezioni (sim/lezioni.lua), ognuna con le sue stelle.
-- CONTRO I BOT: partita sullo stesso telefono contro i bot (sim/bot.lua), col
-- modo (il giocatore è sempre il primo robot; nel 2 contro 2 il compagno è un
-- bot) e il livello. Niente bottone "tutorial" a parte nella home: chi gioca da
-- tanto qui trova l'allenamento, chi è nuovo le lezioni. Stile in ui/ui.lua.
--
--   local allenamento = require "menu.allenamento"
--   local a = allenamento.new(scelta, stelle)  -- scelta = { modo, livello, scheda } (l'ultima); stelle = id -> 0..3
--   local fine = allenamento.on_input(a, action_id, action)
--     -- "indietro", { modo = ..., livello = ... } per giocare contro i bot,
--     -- { lezione = id } per una lezione, o nil
--   allenamento.distruggi(a)

local ui = require "ui.ui"
local lezioni = require "sim.lezioni"

local M = {}

local MODI = { { "1v1", "1 CONTRO 1" }, { "2v2", "2 CONTRO 2" }, { "ffa", "TUTTI CONTRO TUTTI" } }
local LIVELLI = { { "facile", "FACILE" }, { "normale", "NORMALE" }, { "difficile", "DIFFICILE" } }
-- le lezioni in tre colonne
local CARTA_W, CARTA_H, COLONNE = 360, 92, 3

local function vec(x, y) return vmath.vector3(x, y, 0) end

local function stelle(n, x, y, parent)
	for i = 1, 3 do
		ui.stella(x + (i - 2) * 28, y, 26, i <= n and ui.ORO or ui.C.LINEA, parent)
	end
end

local function lezioni_scheda(a)
	for i, l in ipairs(lezioni.LISTA) do
		local col, riga = (i - 1) % COLONNE, math.floor((i - 1) / COLONNE)
		local x, y = 640 + (col - 1) * (CARTA_W + 24), 410 - riga * (CARTA_H + 20)
		local n = ui.bottone(a.bottoni, x, y, CARTA_W, CARTA_H, "", "lezione:" .. l.id, nil, a.radice)
		ui.testo(string.upper(l.titolo), 0, 14, 0.8, ui.C.TESTO, n)
		stelle(a.stelle[l.id] or 0, 0, -22, n)
	end
end

local function bot_scheda(a)
	local c = ui.C
	ui.testo("MODO", 640, 470, 0.7, c.SPENTO, a.radice)
	for i, m in ipairs(MODI) do
		ui.scheda(a.bottoni, 640 + (i - 2) * 330, 410, 310, 64, m[2], "modo:" .. m[1], a.scelta.modo == m[1], a.radice)
	end
	ui.testo("BOT", 640, 320, 0.7, c.SPENTO, a.radice)
	for i, l in ipairs(LIVELLI) do
		ui.scheda(a.bottoni, 640 + (i - 2) * 250, 260, 230, 64, l[2], "livello:" .. l[1], a.scelta.livello == l[1], a.radice)
	end
	ui.bottone(a.bottoni, 640, 120, 340, 108, "GIOCA", "gioca", { principale = true }, a.radice)
end

local function costruisci(a)
	if a.radice then gui.delete_node(a.radice) end
	a.bottoni = {}
	a.radice = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_visible(a.radice, false)
	ui.indietro(a.bottoni, "indietro", a.radice)
	ui.titolo("ALLENAMENTO", 640, 640, 1, ui.C.TESTO, a.radice)
	ui.scheda(a.bottoni, 520, 560, 220, 56, "LEZIONI", "scheda:lezioni", a.scelta.scheda == "lezioni", a.radice)
	ui.scheda(a.bottoni, 760, 560, 220, 56, "CONTRO I BOT", "scheda:bot", a.scelta.scheda == "bot", a.radice)
	if a.scelta.scheda == "lezioni" then lezioni_scheda(a) else bot_scheda(a) end
end

function M.new(scelta, voti)
	local a = { scelta = scelta, stelle = voti or {} }
	-- la prima volta le lezioni, poi l'ultima scheda aperta; finché ce n'è una da
	-- fare si torna lì
	if not scelta.scheda then
		local da_fare = false
		for _, l in ipairs(lezioni.LISTA) do
			if (a.stelle[l.id] or 0) == 0 then da_fare = true end
		end
		scelta.scheda = da_fare and "lezioni" or "bot"
	end
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
	if tipo == "lezione" then return { lezione = valore } end
	a.scelta[tipo] = valore
	costruisci(a)
	return nil
end

function M.distruggi(a)
	gui.delete_node(a.radice)
	gui.delete_node(a.fondo)
end

return M
