-- Impostazioni (la rotellina in alto a destra della home, docs/impostazioni.md):
-- il modo della mira e i tasti del controller in battaglia (Sergio, 30 ott:
-- "la rimappatura dei pulsanti me la metti nelle impostazioni"). Si sceglie un
-- comando (col tocco o con la luce del controller e A), poi si preme il tasto
-- nuovo: il comando che lo aveva prende quello lasciato libero
-- (controller.assegna). Start annulla e resta alla rotellina; RIPRISTINA torna
-- alla mappatura di Sergio. Tutto si salva subito nel profilo.
--
--   local impostazioni = require "menu.impostazioni"
--   local s = impostazioni.new(p, ctrl)         -- p il profilo, ctrl il controller (ui/controller.lua)
--   impostazioni.on_input(s, action_id, action) -- "indietro" o nil
--     (i tasti arrivano come ui.PAD con action.nome, il tasto premuto)
--   impostazioni.distruggi(s)

local ui = require "ui.ui"
local glifo = require "ui.glifo"
local controller = require "ui.controller"
local profilo = require "menu.profilo"

local M = {}

local NOMI = {
	spara = "SPARA", primaria = "PRIMARIA DOPO", secondaria = "SECONDARIA DOPO", teletrasporto = "TELETRASPORTO",
	rampino = "RAMPINO", paracadute = "PARACADUTE", oggetti = "OGGETTO DOPO", usa_oggetto = "USA L'OGGETTO",
	baratto = "BARATTO", zoom = "ZOOM",
}
local MIRE = { { "lancetta", "LANCETTA" }, { "mirino", "MIRINO" } }
-- due colonne di comandi
local RIGA_W, RIGA_H, RIGA_PASSO = 470, 56, 64
local COLONNE = { 395, 885 }
local PRIMA_RIGA = 410

local function costruisci(s)
	if s.radice then gui.delete_node(s.radice) end
	s.bottoni, s.glifi = {}, {}
	s.radice = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(0, 0, 0))
	gui.set_visible(s.radice, false)
	local C = ui.C
	ui.indietro(s.bottoni, "indietro", s.radice)
	ui.titolo("IMPOSTAZIONI", 640, 650, 1, C.TESTO, s.radice)

	ui.testo("MIRA", 640, 572, 0.7, C.SPENTO, s.radice)
	local mira = profilo.impostazione(s.p, "mira")
	for i, m in ipairs(MIRE) do
		ui.scheda(s.bottoni, 640 + (i - 1.5) * 270, 520, 250, 60, m[2], "mira:" .. m[1], mira == m[1], s.radice)
	end

	ui.testo("TASTI DEL CONTROLLER", 640, 466, 0.7, C.SPENTO, s.radice)
	local n = #controller.COMANDI
	local per_colonna = math.ceil(n / 2)
	for i, cmd in ipairs(controller.COMANDI) do
		local col = i <= per_colonna and 1 or 2
		local riga = (i - 1) % per_colonna
		local x, y = COLONNE[col], PRIMA_RIGA - riga * RIGA_PASSO
		local nodo = ui.bottone(s.bottoni, x, y, RIGA_W, RIGA_H, "", "tasto:" .. cmd, nil, s.radice)
		local nome = ui.testo(NOMI[cmd], -RIGA_W / 2 + 22, 0, 0.8, C.TESTO, nodo)
		gui.set_pivot(nome, gui.PIVOT_W)
		if s.attesa == cmd then
			local premi = ui.testo("PREMI UN TASTO", RIGA_W / 2 - 22, 0, 0.7, C.BRACE, nodo)
			gui.set_pivot(premi, gui.PIVOT_E)
			ui.scheda_attiva(s.bottoni[#s.bottoni], true)
		else
			local g = glifo.new(nodo, 32)
			glifo.mostra(g, s.c, controller.tasto_di(s.c, cmd))
			gui.set_position(g.radice, vmath.vector3(RIGA_W / 2 - 22 - glifo.largo(g) / 2, 0, 0))
		end
	end

	local riga = PRIMA_RIGA - per_colonna * RIGA_PASSO
	ui.bottone(s.bottoni, COLONNE[2] + RIGA_W / 2 - 150, riga - 6, 300, 60, "RIPRISTINA", "ripristina", nil, s.radice)
	local aiuto = s.attesa and (controller.nome(s.c, "start") .. " ANNULLA")
		or (s.c.connesso and "SCEGLI UN COMANDO, POI PREMI IL TASTO NUOVO"
		or "COLLEGA UN CONTROLLER PER CAMBIARE I TASTI")
	local t = ui.testo(aiuto, COLONNE[1] - RIGA_W / 2, riga - 6, 0.62, C.SPENTO, s.radice)
	gui.set_pivot(t, gui.PIVOT_W)
	ui.riaccendi(s.bottoni)
end

function M.new(p, c)
	local s = { p = p, c = c }
	s.fondo = ui.sfondo()
	costruisci(s)
	return s
end

local function salva(s)
	profilo.imposta(s.p, "tasti", controller.da_salvare(s.c))
	profilo.salva(s.p)
end

function M.on_input(s, action_id, action)
	-- in attesa del tasto nuovo: il primo tasto del controller (non le levette)
	if s.attesa and action_id == ui.PAD then
		if not (action.pressed and action.nome) or action.levetta then return nil end
		if action.nome ~= "start" and controller.assegna(s.c, s.attesa, action.nome) then salva(s) end
		s.attesa = nil
		costruisci(s)
		return nil
	end
	local azione = ui.tocco(s.bottoni, action_id, action)
	if not azione then return nil end
	if azione == "indietro" then return "indietro" end
	if azione == "ripristina" then
		controller.base(s.c)
		salva(s)
		s.attesa = nil
	else
		local tipo, valore = azione:match("^(%a+):(.*)$")
		if tipo == "mira" then
			profilo.imposta(s.p, "mira", valore)
			profilo.salva(s.p)
		elseif tipo == "tasto" then
			s.attesa = s.attesa ~= valore and valore or nil
		end
	end
	costruisci(s)
	return nil
end

function M.distruggi(s)
	gui.delete_node(s.radice)
	gui.delete_node(s.fondo)
end

return M
