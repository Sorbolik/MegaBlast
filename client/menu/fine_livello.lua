-- Fine di un livello: una missione della campagna o una lezione (sim/missioni.lua). Una schermata, niente popup: il
-- nome del livello, le stelle prese che si accendono una dopo l'altra (col tic
-- che sale di tono, come i punti in partita) e sotto ognuna cosa serve per
-- prenderla, così si capisce come fare meglio. Sotto: RIPROVA e AVANTI (il
-- livello dopo, o la lista se era l'ultimo); la freccia torna alla lista.
--
--   local fine_livello = require "menu.fine_livello"
--   local f = fine_livello.new({ titolo = "Il Rampino", stelle = { true, true, false },
--     criteri = { "FATTA", "IN 2 TURNI", "IN 1 TURNO" }, turni = 2, record = 3, avanti = true }, suono)
--     stelle: quali ha preso (ognuna col suo criterio); criteri: cosa serve per
--     ognuna (missioni.criteri); turni: quanti ne sono serviti; record: quante
--     stelle aveva già la missione;
--     avanti: c'è un livello dopo; suono(v): il tic, v = velocità (tono)
--   fine_livello.update(f, dt)
--   fine_livello.on_input(f, action_id, action) -> "riprova", "avanti", "indietro" o nil
--   fine_livello.distruggi(f)

local ui = require "ui.ui"

local M = {}

-- le stelle: lato, distanza tra i centri, quella in mezzo più grande e più alta
M.LATO, M.PASSO, M.Y = 116, 190, 400
-- quando si accende ogni stella (secondi dall'apertura) e quanto dura il colpo
M.RITMO, M.PRIMA, M.COLPO = 0.3, 0.25, 0.18

local function vec(x, y) return vmath.vector3(x, y, 0) end
local function turni(n) return n .. (n == 1 and " turno" or " turni") end

function M.new(o, suono)
	local f = { bottoni = {}, t = 0, suono = suono, accese = 0, prese = {} }
	local n = 0
	f.fondo = ui.sfondo()
	f.radice = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_visible(f.radice, false)
	local c = ui.C
	ui.indietro(f.bottoni, "indietro", f.radice)
	ui.testo("MISSIONE FATTA", 640, 640, 0.8, c.SPENTO, f.radice)
	ui.titolo(string.upper(o.titolo), 640, 585, 1, c.LUCE, f.radice)
	local criteri = o.criteri
	for i = 1, 3 do
		local grande = i == 2 and 1.2 or 1
		local x, y = 640 + (i - 2) * M.PASSO, M.Y + (i == 2 and 18 or 0)
		local lato = M.LATO * grande
		-- sotto, la stella spenta; sopra, quella d'oro che si accende col suo alone
		ui.stella(x, y, lato, c.LINEA, f.radice)
		local s = { lato = lato }
		if o.stelle[i] then
			n = n + 1
			f.prese[n] = s
			s.alone = ui.alone(x, y, lato * 2.2, vmath.vector4(1, 0.8, 0.25, 0), f.radice)
			s.nodo = ui.stella(x, y, lato, ui.ORO, f.radice)
			gui.set_scale(s.nodo, vec(0, 0))
		end
		ui.testo(criteri[i], x, M.Y - 100, 0.75, o.stelle[i] and c.TESTO or c.SPENTO, f.radice)
	end
	local sotto = "Fatta in " .. turni(o.turni)
	if o.record and o.record > n then
		sotto = sotto .. "  -  il tuo record: " .. o.record .. (o.record == 1 and " stella" or " stelle")
	end
	ui.testo(sotto, 640, 232, 0.8, c.SPENTO, f.radice)
	ui.bottone(f.bottoni, 640 - 180, 110, 300, 96, "RIPROVA", "riprova", nil, f.radice)
	ui.bottone(f.bottoni, 640 + 180, 110, 300, 96, o.avanti and "AVANTI" or "CAMPAGNA", "avanti",
		{ principale = true }, f.radice)
	return f
end

-- le stelle prese si accendono una alla volta: crescono oltre la misura e
-- tornano, l'alone si accende e si quieta
function M.update(f, dt)
	f.t = f.t + dt
	local i = f.accese + 1
	if i > #f.prese or f.t < M.PRIMA + (i - 1) * M.RITMO then return end
	f.accese = i
	local s = f.prese[i]
	gui.animate(s.nodo, "scale", vec(1, 1), gui.EASING_OUTBACK, M.COLPO)
	gui.animate(s.alone, "color.w", 0.7, gui.EASING_OUTQUAD, M.COLPO * 0.5, 0, function()
		gui.animate(s.alone, "color.w", 0.3, gui.EASING_INOUTQUAD, 0.5)
	end)
	if f.suono then f.suono(1 + 0.15 * (i - 1)) end
end

function M.on_input(f, action_id, action)
	return ui.tocco(f.bottoni, action_id, action)
end

function M.distruggi(f)
	gui.delete_node(f.radice)
	gui.delete_node(f.fondo)
end

return M
