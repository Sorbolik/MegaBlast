-- Scelta d'inizio partita (le regole sono in sim/draft.lua): tre file di carte,
-- le primarie (brace) sopra, le secondarie (acciaio) in mezzo e l'attrezzo del
-- turno sotto (già scelto quello dell'assetto). Le armi prese da un compagno
-- sono spente; allo scadere del tempo si prende la prima libera di ogni fila.
-- Sullo stesso telefono si sceglie a turno, una carta per fila. Online sceglie
-- solo chi gioca su questo telefono, finché il tempo non scade: le scelte vanno
-- al server, che rimanda a tutti il draft aggiornato (docs/server.md); nel 2
-- contro 2 un bottone propone lo scambio di tutte le scelte al compagno, e lo
-- scambio si fa quando lo propongono tutti e due.
-- Pannelli e testo dell'interfaccia minimale (ui/ui.lua).
--
--   local scelta = require "menu.scelta"
--   local s = scelta.new(icone, nomi, effetti)     -- icone (atlante armi), nomi e una riga sull'effetto per arma, nascosta
--   scelta.show(s, d, nomi_giocatori, colori)      -- sullo stesso telefono: d = draft.new(...)
--   local players = scelta.update(s, dt)           -- i giocatori per game.new, quando tutti hanno scelto (online nil)
--   scelta.on_input(s, action_id, action)
--   scelta.online(s, m, nomi, colori, invia)       -- online, a ogni messaggio draft del server;
--                                                  -- invia(msg) manda pick e swap
--   scelta.hide(s)

local config = require "sim.config"
local draft = require "sim.draft"
local game = require "sim.game"
local ui = require "ui.ui"
local schermo = require "ui.schermo"

local M = {}

local W, H = 1280, 720
local CARD_W, CARD_H, CARD_GAP = 220, 160, 40
-- le tre file: primarie, secondarie, attrezzi, col nome del gruppo a sinistra
local ROW_Y = { 165, -10, -185 }
local ROW_NAME = { "PRIMARIA", "SECONDARIA", "ATTREZZO" }
local BAR_W = 560
-- il bottone dello scambio col compagno, accanto alla barra del tempo (online, 2 contro 2)
local SCAMBIO_X, SCAMBIO_Y, SCAMBIO_W, SCAMBIO_H = 470, -300, 300, 48
local C = ui.C
local ROW_COLOR = { C.BRACE, C.ACCIAIO, C.LUCE }
local VELO = vmath.vector4(C.FONDO.x, C.FONDO.y, C.FONDO.z, 0.86)
-- carta di un'arma che non si può prendere (già presa da un compagno)
local SPENTA = vmath.vector4(C.PANNELLO.x, C.PANNELLO.y, C.PANNELLO.z, 0.35)
local TOUCH = hash("touch")

local function vec(x, y) return vmath.vector3(x, y, 0) end

local function nodo(x, y, w, h, colore, parent)
	local n = gui.new_box_node(vec(x, y), vec(w, h))
	gui.set_color(n, colore)
	if parent then gui.set_parent(n, parent) end
	return n
end

function M.new(icone, nomi, effetti)
	local s = { icone = icone, nomi = nomi, effetti = effetti, carte = {} }
	s.root = nodo(W / 2, H / 2, W * schermo.PIENO, H * schermo.PIENO, VELO)
	gui.set_adjust_mode(s.root, gui.ADJUST_FIT)
	s.titolo = ui.titolo("", 0, 312, 0.55, nil, s.root)
	s.sotto = ui.testo("Della primaria hai " .. config.DRAFT_SHOTS .. " colpi, la secondaria non finisce mai, l'attrezzo una volta per turno. Lanciarune e Lama li hai sempre.",
		0, 274, 0.6, nil, s.root)
	s.barra = ui.barra(0, -300, BAR_W, 6, C.LUCE, s.root)
	s.bottoni = {}
	s.scambio = ui.bottone(s.bottoni, SCAMBIO_X, SCAMBIO_Y, SCAMBIO_W, SCAMBIO_H, "", "scambio", { scala = 0.55 }, s.root)
	local x0 = -((config.DRAFT_OFFER - 1) * (CARD_W + CARD_GAP)) / 2
	local quante = { config.DRAFT_OFFER, config.DRAFT_OFFER, #game.DRAFT_TOOLS }
	for fila = 1, 3 do
		local nome_fila = ui.testo(ROW_NAME[fila], x0 - CARD_W / 2 - 70, ROW_Y[fila], 0.5, ROW_COLOR[fila], s.root)
		gui.set_pivot(nome_fila, gui.PIVOT_E)
		s.carte[fila] = {}
		-- ogni fila centrata
		local xf = -((quante[fila] - 1) * (CARD_W + CARD_GAP)) / 2
		for i = 1, quante[fila] do
			local c, bordo = ui.pannello(xf + (i - 1) * (CARD_W + CARD_GAP), ROW_Y[fila], CARD_W, CARD_H, s.root)
			local icona = gui.new_box_node(vec(0, 34), vec(76, 76))
			gui.set_texture(icona, "armi")
			gui.set_parent(icona, c)
			local nome = ui.testo("", 0, -16, 0.65, nil, c)
			-- l'effetto dell'arma in una riga (due se serve)
			local effetto = ui.testo("", 0, -42, 0.5, C.SPENTO, c)
			gui.set_line_break(effetto, true)
			-- larghezza della carta meno i margini, nella scala del testo (0,5 x 0,5)
			gui.set_size(effetto, vmath.vector3((CARD_W - 24) / 0.25, 100, 0))
			-- un segno del colore di chi l'ha presa, per ognuno
			local segni = {}
			for k = 1, 4 do
				segni[k] = nodo(-45 + (k - 1) * 30, -70, 22, 8, C.LUCE, c)
			end
			s.carte[fila][i] = { node = c, bordo = bordo, icona = icona, nome = nome, effetto = effetto,
				segni = segni, fila = fila }
		end
	end
	gui.set_enabled(s.root, false)
	gui.set_enabled(s.scambio, false)
	return s
end

-- Il prossimo che deve scegliere (chi non ha ancora tutte e due le armi), o nil
local function prossimo(s)
	for i = 1, #s.d.players do
		if not draft.done(s.d, i) then return i end
	end
end

-- Online, nel 2 contro 2: il compagno di chi gioca qui
local function compagno(s)
	local d = s.d
	for j, p in ipairs(d.players) do
		if j ~= s.chi and p.team == d.players[s.chi].team then return j end
	end
end

-- Il bottone dello scambio e il titolo, che dice se il compagno lo propone
local function aggiorna_scambio(s)
	local j = s.online and s.d.teams and compagno(s)
	gui.set_enabled(s.scambio, j ~= nil)
	if not j then return end
	local b = s.bottoni[1]
	local mio, suo = s.sw[s.chi] == j, s.sw[j] == s.chi
	gui.set_text(b.testo, suo and "ACCETTA LO SCAMBIO" or mio and "SCAMBIO PROPOSTO" or "SCAMBIA CON " .. s.giocatori[j]:upper())
	ui.scheda_attiva(b, suo or mio)
	if suo then
		gui.set_text(s.titolo, s.giocatori[j] .. " ti propone di scambiare le scelte")
		gui.set_color(s.titolo, s.colori[j])
	end
end

local function aggiorna(s)
	local d, chi = s.d, s.chi
	if chi then
		gui.set_text(s.titolo, (s.online and "Scegli" or s.giocatori[chi] .. ", scegli") .. " primaria, secondaria e attrezzo")
		gui.set_color(s.titolo, s.colori[chi])
	end
	aggiorna_scambio(s)
	for fila, carte in ipairs(s.carte) do
		local offer, picks = d.offer, d.picks
		if fila == 2 then offer, picks = d.offer2, d.picks2 end
		if fila == 3 then offer, picks = d.offer3, d.picks3 end
		for i, c in ipairs(carte) do
			local w = offer[i]
			gui.set_enabled(c.node, w ~= nil)
			if w then
				gui.play_flipbook(c.icona, s.icone[w])
				gui.set_text(c.nome, s.nomi[w])
				gui.set_text(c.effetto, s.effetti[w] or "")
				local libera = not chi or draft.valid(d, chi, w)
				-- nella fila dove ha già scelto, solo la sua carta resta accesa
				local altra = chi and picks[chi] and picks[chi] ~= w
				gui.set_color(c.node, libera and C.PANNELLO or SPENTA)
				gui.set_color(c.bordo, (libera and not altra) and ROW_COLOR[fila] or C.LINEA)
				local k = 0
				for j = 1, #d.players do
					if picks[j] == w then
						k = k + 1
						gui.set_enabled(c.segni[k], true)
						gui.set_color(c.segni[k], s.colori[j])
					end
				end
				for m = k + 1, #c.segni do gui.set_enabled(c.segni[m], false) end
			end
		end
	end
end

function M.show(s, d, giocatori, colori)
	s.d, s.giocatori, s.colori = d, giocatori, colori
	s.online = nil
	s.chi = prossimo(s)
	s.tempo = config.DRAFT_SECONDS
	s.fatto = nil
	gui.set_enabled(s.root, true)
	aggiorna(s)
end

local function vuoto(v) return v ~= "" and v or nil end

-- Online: m è il messaggio draft del server (ventagli, scelte di tutti, attrezzi
-- solo proposti, proposte di scambio, tick rimasti). Ne fa una copia dello stato
-- di sim/draft.lua, così le carte spente sono le stesse che il server rifiuta.
function M.online(s, m, giocatori, colori, invia)
	local d = { offer = m.offer, offer2 = m.offer2, offer3 = m.offer3, players = m.players,
		picks = {}, picks2 = {}, picks3 = {}, proposto = {}, teams = false }
	local viste = {}
	for i, p in ipairs(m.players) do
		d.picks[i], d.picks2[i], d.picks3[i] = vuoto(m.p[i]), vuoto(m.p2[i]), vuoto(m.p3[i])
		d.proposto[i] = m.pr and m.pr[i] or nil
		d.teams = d.teams or viste[p.team] ~= nil
		viste[p.team] = true
	end
	if not s.online then gui.set_enabled(s.root, true) end
	s.d, s.giocatori, s.colori = d, giocatori, colori
	s.online, s.invia, s.chi, s.fatto = true, invia, m.you, nil
	s.sw = m.sw or {}
	s.tempo = (m.left or 0) * game.DT
	aggiorna(s)
end

function M.hide(s)
	gui.set_enabled(s.root, false)
	s.d, s.online = nil, nil
end

local function scegli(s, w)
	if s.online then
		-- subito sulla copia, poi il server conferma col draft aggiornato
		if draft.pick(s.d, s.chi, w) then
			s.invia({ t = "pick", w = w })
			aggiorna(s)
		end
		return
	end
	if not (s.chi and draft.pick(s.d, s.chi, w)) then return end
	if draft.done(s.d, s.chi) then
		s.chi = prossimo(s)
		s.tempo = config.DRAFT_SECONDS
		-- un attimo per vedere l'ultima scelta prima di partire
		if not s.chi then s.fatto = 0.6 end
	end
	aggiorna(s)
end

function M.update(s, dt)
	if not s.d then return nil end
	if s.fatto then
		s.fatto = s.fatto - dt
		if s.fatto > 0 then return nil end
		gui.set_enabled(s.root, false)
		local players = draft.finish(s.d)
		s.d = nil
		return players
	end
	s.tempo = s.tempo - dt
	ui.barra_valore(s.barra, s.tempo / config.DRAFT_SECONDS)
	-- online allo scadere decide il server
	if s.online then return nil end
	if s.tempo <= 0 and s.chi then
		-- allo scadere la prima arma libera di ogni fila che manca
		local d, chi = s.d, s.chi
		if not d.picks[chi] then scegli(s, draft.first_free(d, chi, d.offer)) end
		if s.chi == chi and not d.picks2[chi] then scegli(s, draft.first_free(d, chi, d.offer2)) end
		if s.chi == chi and not d.picks3[chi] then scegli(s, draft.first_free(d, chi, d.offer3)) end
	end
	return nil
end

function M.on_input(s, action_id, action)
	if not s.d or s.fatto then return end
	if ui.tocco(s.bottoni, action_id, action) == "scambio" then
		-- proporre, ritirare la proposta o accettare quella del compagno
		local j = compagno(s)
		s.invia({ t = "swap", to = s.sw[s.chi] == j and 0 or j })
		return
	end
	if action_id ~= TOUCH or not action.pressed then return end
	for fila, carte in ipairs(s.carte) do
		local offer = ({ s.d.offer, s.d.offer2, s.d.offer3 })[fila]
		for i, c in ipairs(carte) do
			if offer[i] and gui.pick_node(c.node, action.x, action.y) then
				scegli(s, offer[i])
				return
			end
		end
	end
end

return M
