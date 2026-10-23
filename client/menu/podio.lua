-- Podio di fine partita: i gradini salgono, sopra ogni gradino la Scoria del
-- giocatore col colore della sua squadra, sul gradino posto, nome e punti
-- partita (calcolati dalla sim, g:results()). Sotto, i riconoscimenti
-- (sim/riconoscimenti.lua) e cosa si è guadagnato: esperienza, livello, Scorie.
--
-- Uso (dal gui_script):
--   local p = podio.new(results, giocatori, me, guadagno, prof)
--     results: g:results() della sim; giocatori[robot] = { nome, colore }
--     me: il robot di chi gioca su questo telefono online (nil in locale)
--     guadagno: profilo.fine_partita(...) di chi gioca su questo telefono, o nil; prof: il profilo
--   podio.update(p, dt) ; podio.on_input(p, action_id, action) -> "continua" o nil
--   podio.distruggi(p)

local ui = require "ui.ui"
local scoria = require "battaglia.scoria"
local game = require "sim.game"
local riconoscimenti = require "sim.riconoscimenti"
local profilo = require "menu.profilo"

local M = {}

-- gradini da sinistra a destra: 2°, 1°, 3°, 4°
M.ORDINE = { 2, 1, 3, 4 }
M.ALTEZZA = { 170, 125, 95, 70 }   -- altezza di ogni posto
M.LARGO, M.PASSO = 190, 205        -- larghezza dei gradini e distanza tra i centri
M.BASE_Y = 250                     -- dove poggiano i gradini
M.SCORIA_H = 110                   -- la Scoria sul gradino, in pixel
-- tempi dell'entrata: i gradini salgono uno dopo l'altro, poi i riconoscimenti
M.SALITA, M.RITARDO, M.PREMI = 0.45, 0.18, 1.0

local MODI = { ["1v1"] = "UNO CONTRO UNO", ["2v2"] = "DUE CONTRO DUE", ffa = "TUTTI CONTRO TUTTI" }

local function vec(x, y) return vmath.vector3(x, y, 0) end

local function gradino(p, x, voce, i)
	local c = ui.C
	local g = p.giocatori[voce.robot] or { nome = "?", colore = c.TESTO }
	local h = M.ALTEZZA[voce.place] or M.ALTEZZA[#M.ALTEZZA]
	-- il gradino cresce dal basso: pivot in basso e scala verticale animata
	local blocco = ui.pannello(x, M.BASE_Y, M.LARGO, h, p.radice)
	gui.set_pivot(blocco, gui.PIVOT_S)
	local filo = ui.pannello(0, h, M.LARGO, 4, blocco)
	gui.set_color(filo, g.colore)
	ui.titolo(tostring(voce.place), 0, h - 42, 1.3, voce.place == 1 and c.BRACE or c.TESTO, blocco)
	ui.testo(g.nome, 0, h - 82, 1, g.colore, blocco)
	ui.testo(string.format("%d punti", voce.points or 0), 0, h - 106, 0.8, c.SPENTO, blocco)
	gui.set_scale(blocco, vmath.vector3(1, 0.01, 1))
	local ritardo = (i - 1) * M.RITARDO
	gui.animate(blocco, "scale.y", 1, gui.EASING_OUTBACK, M.SALITA, ritardo)

	-- la Scoria cade sul gradino quando è salito
	local posa = gui.new_box_node(vec(x, M.BASE_Y + h + 260), vec(0, 0))
	gui.set_visible(posa, false)
	gui.set_parent(posa, p.radice)
	local k = M.SCORIA_H / game.ROBOT_H
	gui.set_scale(posa, vmath.vector3(k, k, 1))
	gui.animate(posa, "position.y", M.BASE_Y + h, gui.EASING_INQUAD, 0.3, ritardo + M.SALITA * 0.7)
	local s = scoria.new(g.colore)
	gui.set_parent(s.root, posa)
	scoria.set_enabled(s, true)
	scoria.set_weapon(s, nil)
	p.scorie[#p.scorie + 1] = { s = s, posa = posa,
		st = { x = 0, y = 0, facing = x < 640 and 1 or -1, grounded = true, moving = 0 } }
end

local function titolo(p, results, primo)
	local c = ui.C
	local g = p.giocatori[primo.robot] or { nome = "?", colore = c.TESTO }
	local scritta
	if p.me then
		scritta = primo.robot == p.me and "VITTORIA" or "SCONFITTA"
		if results.mode == "2v2" then
			for _, v in ipairs(results.ranking) do
				if v.robot == p.me and v.team == primo.team then scritta = "VITTORIA" end
			end
		end
	else
		scritta = "VINCE " .. string.upper(g.nome)
	end
	ui.titolo(scritta, 640, 660, 1.4, p.me and (scritta == "VITTORIA" and c.BRACE or c.TESTO) or g.colore, p.radice)
	ui.testo(MODI[results.mode] or "", 640, 618, 0.8, c.SPENTO, p.radice)
end

-- carta di un riconoscimento: nome, chi l'ha preso, perché
local function premio(p, x, y, voce, i)
	local c = ui.C
	local g = p.giocatori[voce.robot] or { nome = "?", colore = c.TESTO }
	local n = ui.pannello(x, y, 230, 92, p.radice)
	local filo = ui.pannello(-113, 0, 4, 92, n)
	gui.set_color(filo, g.colore)
	ui.titolo(voce.award.name, 0, 24, 0.7, c.BRACE, n)
	ui.testo(g.nome, 0, -2, 0.9, g.colore, n)
	ui.testo(voce.award.desc, 0, -26, 0.6, c.SPENTO, n)
	gui.set_scale(n, vmath.vector3(0.01, 0.01, 1))
	gui.animate(n, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, 0.3, M.PREMI + i * 0.12)
end

-- esperienza, livello e Scorie guadagnati da chi gioca su questo telefono
local function guadagno(p, g, prof)
	local c = ui.C
	local n = ui.pannello(1065, 105, 330, 120, p.radice)
	ui.testo(string.format("LIVELLO %d", g.livello), -80, 34, 1, g.livello > g.livello_prima and c.BRACE or c.TESTO, n)
	ui.testo(string.format("+%d esperienza", g.xp), 70, 34, 0.8, c.TESTO, n)
	local b = ui.barra(0, 4, 290, 12, c.BRACE, n)
	ui.barra_valore(b, 0)
	p.barra, p.barra_fine = b, prof.xp / profilo.xp_livello(prof.livello)
	ui.testo(string.format("+%d Scorie  ·  %d in tutto", g.scorie, prof.scorie), 0, -30, 0.8, c.SPENTO, n)
	if g.livello > g.livello_prima then
		ui.testo("nuovo punto abilità!", 0, -48, 0.7, c.BRACE, n)
	end
end

function M.new(results, giocatori, me, guadagno_mio, prof)
	local p = { giocatori = giocatori, me = me, scorie = {}, bottoni = {}, t = 0 }
	-- sfondo stirato su tutto lo schermo, il resto in un gruppo che si adatta (FIT)
	p.fondo = ui.sfondo()
	p.radice = gui.new_box_node(vec(0, 0), vec(0, 0))
	gui.set_visible(p.radice, false)
	local ranking = results.ranking
	titolo(p, results, ranking[1])

	-- gradini nell'ordine 2°, 1°, 3°, 4°, centrati per quanti sono
	local fila = {}
	for _, posto in ipairs(M.ORDINE) do
		for _, v in ipairs(ranking) do
			if v.place == posto and #fila < #ranking then fila[#fila + 1] = v end
		end
	end
	local x0 = 640 - (#fila - 1) * M.PASSO / 2
	for i, v in ipairs(fila) do
		-- salgono in ordine di posto: prima il 4°, per ultimo il 1°
		gradino(p, x0 + (i - 1) * M.PASSO, v, #ranking - v.place + 1)
	end

	-- riconoscimenti in basso a sinistra
	local _, lista = riconoscimenti.assign(ranking)
	for i, voce in ipairs(lista) do
		if i > 4 then break end
		premio(p, 135 + ((i - 1) % 2) * 240, 155 - math.floor((i - 1) / 2) * 100, voce, i)
	end

	if guadagno_mio then guadagno(p, guadagno_mio, prof) end
	ui.bottone(p.bottoni, 1065, 205, 330, 60, "CONTINUA", "continua", { principale = true }, p.radice)
	return p
end

function M.update(p, dt)
	p.t = p.t + dt
	for _, s in ipairs(p.scorie) do scoria.update(s.s, dt, s.st) end
	if p.barra and p.t > M.PREMI then
		ui.barra_valore(p.barra, math.min(p.barra_fine, (p.t - M.PREMI) * 0.8))
	end
end

function M.on_input(p, action_id, action)
	return ui.tocco(p.bottoni, action_id, action)
end

function M.distruggi(p)
	gui.delete_node(p.radice)
	gui.delete_node(p.fondo)
end

return M
