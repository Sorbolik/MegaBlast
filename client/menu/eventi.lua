-- Calendario degli eventi (docs/game_design_competitivo.md, "Eventi"): invece
-- delle stagioni si sa in anticipo cosa c'è nei prossimi giorni, per esempio il
-- Torneo del fine settimana con premi a fasce di classifica.
--
-- Il calendario ripete gli eventi di ogni settimana (EVENTI qui sotto). Quando
-- il server terrà gli eventi li manderà lui con la stessa forma.
--
-- Uso: local e = eventi.new(os.time()) ; eventi.on_input(e, action_id, action) -> "indietro" o nil
--      eventi.distruggi(e)

local ui = require "ui.ui"

local M = {}

-- giorno: 1 domenica ... 7 sabato (come os.date("*t").wday); ore di inizio e fine
M.EVENTI = {
	{ giorno = 4, dalle = 18, alle = 23, nome = "NOTTE DELLE CASSE", modo = "Tutti contro tutti",
		desc = "Una cassa a ogni turno", premi = { { "a tutti", "doppie Scorie" } } },
	{ giorno = 7, dalle = 15, alle = 22, nome = "TORNEO DEL TITANO", modo = "Torneo, 1 contro 1",
		desc = "Tutti con i punti abilità al massimo: conta solo l'assetto",
		premi = { { "1-100", "aspetto del Torneo e un pezzo di set" }, { "101-300", "aspetto del Torneo" } } },
	{ giorno = 1, dalle = 15, alle = 21, nome = "SFIDA DELLE COPPIE", modo = "Torneo, 2 contro 2",
		desc = "Coppie fisse per tutto il giorno",
		premi = { { "1-50", "stendardo della coppia" }, { "51-200", "500 Scorie" } } },
}
M.GIORNI_VISTI = 14
local NOMI_GIORNO = { "DOM", "LUN", "MAR", "MER", "GIO", "VEN", "SAB" }

local function vec(x, y) return vmath.vector3(x, y, 0) end

-- le prossime occorrenze a partire da adesso, in ordine: { evento, data, in_corso }
function M.prossimi(adesso)
	local lista = {}
	local oggi = os.date("*t", adesso)
	for d = 0, M.GIORNI_VISTI - 1 do
		local t = os.date("*t", os.time({ year = oggi.year, month = oggi.month, day = oggi.day + d, hour = 12 }))
		for _, ev in ipairs(M.EVENTI) do
			if ev.giorno == t.wday then
				local fine = os.time({ year = t.year, month = t.month, day = t.day, hour = ev.alle })
				local inizio = os.time({ year = t.year, month = t.month, day = t.day, hour = ev.dalle })
				if fine > adesso then
					lista[#lista + 1] = { evento = ev, data = t, in_corso = inizio <= adesso }
				end
			end
		end
	end
	return lista
end

function M.new(adesso)
	local c = ui.C
	local e = { bottoni = {} }
	e.fondo = ui.sfondo()
	e.radice = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_visible(e.radice, false)
	ui.indietro(e.bottoni, "indietro", e.radice)
	ui.titolo("EVENTI", 220, 680, 1, c.TESTO, e.radice)
	ui.testo("Ogni settimana, sempre gli stessi giorni: organizzati per il prossimo", 760, 680, 0.65, c.SPENTO, e.radice)

	for i, voce in ipairs(M.prossimi(adesso)) do
		if i > 5 then break end
		local ev, t = voce.evento, voce.data
		local y = 590 - (i - 1) * 112
		local pan = ui.pannello(640, y, 1180, 100, e.radice)
		if voce.in_corso then
			local filo = ui.pannello(-588, 0, 4, 100, pan)
			gui.set_color(filo, c.BRACE)
		end
		ui.titolo(NOMI_GIORNO[t.wday], -530, 14, 0.8, voce.in_corso and c.BRACE or c.TESTO, pan)
		ui.testo(string.format("%d/%d", t.day, t.month), -530, -18, 0.7, c.SPENTO, pan)
		local n = ui.titolo(ev.nome, -460, 22, 0.75, c.TESTO, pan)
		gui.set_pivot(n, gui.PIVOT_W)
		n = ui.testo(string.format("%s · dalle %d alle %d%s", ev.modo, ev.dalle, ev.alle,
			voce.in_corso and " · IN CORSO" or ""), -460, -6, 0.65, voce.in_corso and c.BRACE or c.SPENTO, pan)
		gui.set_pivot(n, gui.PIVOT_W)
		n = ui.testo(ev.desc, -460, -30, 0.6, c.SPENTO, pan)
		gui.set_pivot(n, gui.PIVOT_W)
		-- premi a fasce
		for j, p in ipairs(ev.premi) do
			local py = 18 - (j - 1) * 34
			n = ui.testo(p[1], 170, py, 0.65, c.BRACE, pan)
			gui.set_pivot(n, gui.PIVOT_E)
			n = ui.testo(p[2], 185, py, 0.6, c.TESTO, pan)
			gui.set_pivot(n, gui.PIVOT_W)
		end
	end
	return e
end

function M.on_input(e, action_id, action)
	return ui.tocco(e.bottoni, action_id, action)
end

function M.distruggi(e)
	gui.delete_node(e.radice)
	gui.delete_node(e.fondo)
end

return M
