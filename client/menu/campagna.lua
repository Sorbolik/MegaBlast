-- Campagna (bottone CAMPAGNA della home): i capitoli di sim/campagna.lua in
-- schede, l'Addestramento (le lezioni) per primo. Ogni missione è una carta col
-- titolo, le stelle prese e cosa serve per averle tutte, così si sa prima
-- come fare meglio. Un capitolo si apre con le stelle di tutti (capitolo.serve):
-- chiuso, dice quante ne mancano. Stile in ui/ui.lua.
--
--   local campagna = require "menu.campagna"
--   local c = campagna.new(scelta, stelle)  -- scelta = { capitolo } (l'ultimo aperto); stelle = id -> { true, false, true }
--   local fine = campagna.on_input(c, action_id, action)
--     -- "indietro", { missione = id } per giocarla, o nil
--   campagna.distruggi(c)

local ui = require "ui.ui"
local dati = require "sim.campagna"
local missioni = require "sim.missioni"

local M = {}

-- le missioni in tre colonne
local CARTA_W, CARTA_H, COLONNE, PASSO_Y = 360, 100, 3, 116

local function vec(x, y) return vmath.vector3(x, y, 0) end

local function totale(stelle)
	local n = 0
	for _, v in pairs(stelle) do n = n + missioni.quante(v) end
	return n
end

local function aperto(c, cap)
	return totale(c.stelle) >= cap.serve
end

-- ogni stella accesa per il suo criterio: anche la prima e la terza sì e la seconda no
local function stelline(prese, x, y, parent)
	for i = 1, 3 do
		ui.stella(x + (i - 2) * 28, y, 26, prese[i] and ui.ORO or ui.C.LINEA, parent)
	end
end

local function carte(c, cap)
	for i, l in ipairs(cap.missioni) do
		local col, riga = (i - 1) % COLONNE, math.floor((i - 1) / COLONNE)
		local x, y = 640 + (col - 1) * (CARTA_W + 24), 440 - riga * PASSO_Y
		local n = ui.bottone(c.bottoni, x, y, CARTA_W, CARTA_H, "", "missione:" .. l.id, nil, c.radice)
		local prese = c.stelle[l.id] or {}
		ui.testo(string.upper(l.titolo), 0, 26, 0.8, ui.C.TESTO, n)
		stelline(prese, 0, -2, n)
		-- cosa manca: i criteri delle stelle spente
		local cr, manca = missioni.criteri(l), {}
		for i = 2, 3 do
			if not prese[i] then manca[#manca + 1] = cr[i] end
		end
		if #manca > 0 then ui.testo(table.concat(manca, "  -  "), 0, -32, 0.55, ui.C.SPENTO, n) end
	end
end

local function costruisci(c)
	if c.radice then gui.delete_node(c.radice) end
	c.bottoni = {}
	c.radice = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_visible(c.radice, false)
	local C = ui.C
	ui.indietro(c.bottoni, "indietro", c.radice)
	ui.titolo("CAMPAGNA", 640, 640, 1, C.TESTO, c.radice)
	local n = #dati.CAPITOLI
	local w = math.min(420, math.floor(1100 / n) - 20)
	local scelto
	for i, cap in ipairs(dati.CAPITOLI) do
		local attivo = c.scelta.capitolo == cap.id
		if attivo then scelto = cap end
		ui.scheda(c.bottoni, 640 + (i - (n + 1) / 2) * (w + 20), 560, w, 56, string.upper(cap.titolo),
			"capitolo:" .. cap.id, attivo, c.radice)
	end
	if aperto(c, scelto) then
		carte(c, scelto)
	else
		local hai = totale(c.stelle)
		ui.testo("Si apre con " .. scelto.serve .. " stelle: ne hai " .. hai, 640, 400, 1, C.TESTO, c.radice)
		ui.testo("Le stelle si prendono nelle missioni dei capitoli prima", 640, 350, 0.75, C.SPENTO, c.radice)
	end
end

function M.new(scelta, stelle)
	local c = { scelta = scelta, stelle = stelle or {} }
	-- la prima volta l'ultimo capitolo aperto
	if not scelta.capitolo then
		for _, cap in ipairs(dati.CAPITOLI) do
			if aperto(c, cap) then scelta.capitolo = cap.id end
		end
	end
	c.fondo = ui.sfondo()
	costruisci(c)
	return c
end

function M.on_input(c, action_id, action)
	local azione = ui.tocco(c.bottoni, action_id, action)
	if not azione then return nil end
	if azione == "indietro" then return "indietro" end
	local tipo, valore = azione:match("^(%a+):(.*)$")
	if tipo == "missione" then return { missione = valore } end
	c.scelta.capitolo = valore
	costruisci(c)
	return nil
end

function M.distruggi(c)
	gui.delete_node(c.radice)
	gui.delete_node(c.fondo)
end

return M
