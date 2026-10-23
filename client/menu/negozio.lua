-- Negozio (docs/game_design_competitivo.md, "Negozio"): si vende l'aspetto.
-- Niente che dia forza in partita: quello che non è aspetto si ottiene comunque
-- giocando, comprarlo fa solo prima.
--
-- Si paga in Scorie, che si guadagnano in partita. Le gemme (soldi veri) non ci
-- sono ancora: gli oggetti in gemme si vedono ma non si comprano.
--
-- Uso: local n = negozio.new(profilo) ; negozio.on_input(n, action_id, action) -> "indietro" o nil
--      negozio.distruggi(n)

local ui = require "ui.ui"
local profilo = require "menu.profilo"

local M = {}

-- tipo: aspetto (si indossa) o scorciatoia (fa solo prima)
M.OGGETTI = {
	{ id = "nucleo_brace", nome = "NUCLEO DI BRACE", tipo = "aspetto", desc = "Occhio e Nucleo ardono più forte", scorie = 120 },
	{ id = "mantello_ossa", nome = "MANTELLO D'OSSA", tipo = "aspetto", desc = "Mantello con le ossa dei Titani", scorie = 200 },
	{ id = "scia_ombra", nome = "SCIA D'OMBRA", tipo = "aspetto", desc = "Il teletrasporto lascia fumo nero", scorie = 150 },
	{ id = "corona", nome = "CORONA DEL TITANO", tipo = "aspetto", desc = "Corna d'oro sulla maschera", gemme = 300 },
	{ id = "maestria", nome = "MAESTRIA RAPIDA", tipo = "scorciatoia", desc = "Le prossime 10 partite valgono doppio per il tier dei pezzi", gemme = 100 },
}

local function vec(x, y) return vmath.vector3(x, y, 0) end

local function costruisci(n)
	local c = ui.C
	if n.radice then gui.delete_node(n.radice) end
	n.bottoni = {}
	n.radice = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_visible(n.radice, false)
	ui.indietro(n.bottoni, "indietro", n.radice)
	ui.titolo("NEGOZIO", 220, 680, 1, c.TESTO, n.radice)
	ui.testo(string.format("%d Scorie", n.prof.scorie), 1150, 680, 0.9, c.BRACE, n.radice)
	ui.testo("Qui si compra solo l'aspetto: la forza si guadagna giocando", 640, 620, 0.7, c.SPENTO, n.radice)

	for i, o in ipairs(M.OGGETTI) do
		local x = 140 + (i - 1) * 250
		local pan = ui.pannello(x, 380, 230, 320, n.radice)
		ui.titolo(o.nome, 0, 125, 0.55, c.TESTO, pan)
		ui.testo(o.tipo == "aspetto" and "ASPETTO" or "FA SOLO PRIMA", 0, 98, 0.55, c.SPENTO, pan)
		local d = ui.testo(o.desc, 0, 20, 0.6, c.TESTO, pan)
		gui.set_line_break(d, true)
		gui.set_size(d, vmath.vector3(320, 120, 0))
		local preso = n.prof.comprati[o.id]
		if preso then
			ui.testo("TUO", 0, -110, 0.9, c.BRACE, pan)
		elseif o.scorie then
			local ok = n.prof.scorie >= o.scorie
			ui.bottone(n.bottoni, 0, -110, 190, 54, o.scorie .. " Scorie", "compra:" .. o.id,
				{ principale = ok, spento = not ok }, pan)
		else
			ui.bottone(n.bottoni, 0, -110, 190, 54, o.gemme .. " gemme", "", { spento = true }, pan)
			ui.testo("più avanti", 0, -148, 0.5, c.SPENTO, pan)
		end
	end
end

function M.new(prof)
	local n = { prof = prof }
	n.fondo = ui.sfondo()
	costruisci(n)
	return n
end

function M.on_input(n, action_id, action)
	local azione = ui.tocco(n.bottoni, action_id, action)
	if azione == "indietro" then return "indietro" end
	local id = azione and azione:match("^compra:(.+)$")
	if id then
		for _, o in ipairs(M.OGGETTI) do
			if o.id == id and o.scorie and n.prof.scorie >= o.scorie and not n.prof.comprati[id] then
				n.prof.scorie = n.prof.scorie - o.scorie
				n.prof.comprati[id] = true
				profilo.salva(n.prof)
				costruisci(n)
			end
		end
	end
	return nil
end

function M.distruggi(n)
	gui.delete_node(n.radice)
	gui.delete_node(n.fondo)
end

return M
