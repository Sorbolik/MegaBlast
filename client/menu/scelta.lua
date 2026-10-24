-- Scelta d'inizio partita sullo stesso telefono (le regole sono in sim/draft.lua):
-- il ventaglio di armi, e a turno ogni giocatore tocca la sua. Le armi prese
-- da un compagno sono spente; allo scadere del tempo si prende la prima libera.
-- Pannelli e testo dell'interfaccia minimale (ui/ui.lua).
--
--   local scelta = require "menu.scelta"
--   local s = scelta.new(icone, nomi, effetti)     -- icone (o forme, oggetti.icona), nomi e una riga sull'effetto per arma, nascosta
--   scelta.show(s, d, nomi_giocatori, colori)      -- d = draft.new(...)
--   local players = scelta.update(s, dt)           -- i giocatori per game.new, quando tutti hanno scelto
--   scelta.on_input(s, action_id, action)

local config = require "sim.config"
local draft = require "sim.draft"
local ui = require "ui.ui"
local oggetti = require "battaglia.oggetti"

local M = {}

local W, H = 1280, 720
local CARD_W, CARD_H, CARD_GAP = 220, 260, 40
local BAR_W = 560
local C = ui.C
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
	s.root = nodo(W / 2, H / 2, W, H, VELO)
	gui.set_adjust_mode(s.root, gui.ADJUST_STRETCH)
	s.titolo = ui.titolo("", 0, 220, 0.55, nil, s.root)
	s.sotto = ui.testo("Di questa arma hai " .. config.DRAFT_SHOTS .. " colpo. Missile e Lama li hai sempre.", 0, 180, 0.65, nil, s.root)
	s.barra = ui.barra(0, -220, BAR_W, 6, C.LUCE, s.root)
	local x0 = -((config.DRAFT_OFFER - 1) * (CARD_W + CARD_GAP)) / 2
	for i = 1, config.DRAFT_OFFER do
		local c, bordo = ui.pannello(x0 + (i - 1) * (CARD_W + CARD_GAP), 0, CARD_W, CARD_H, s.root)
		local icona = gui.new_box_node(vec(0, 30), vec(120, 120))
		gui.set_texture(icona, "battaglia")
		gui.set_parent(icona, c)
		-- le armi senza immagine (il cecchino) hanno un'icona di forme, più grande
		local forma = nodo(0, 30, 0, 0, C.LUCE, c)
		gui.set_scale(forma, vmath.vector3(1.8, 1.8, 1))
		oggetti.icona("sniper", forma)
		local nome = ui.testo("", 0, -58, 0.65, nil, c)
		-- l'effetto dell'arma in una riga (due se serve)
		local effetto = ui.testo("", 0, -88, 0.55, C.SPENTO, c)
		gui.set_line_break(effetto, true)
		-- larghezza della carta meno i margini, nella scala del testo (0,55 x 0,5)
		gui.set_size(effetto, vmath.vector3((CARD_W - 24) / 0.275, 100, 0))
		-- un segno del colore di chi l'ha presa, per ognuno
		local segni = {}
		for k = 1, 4 do
			segni[k] = nodo(-45 + (k - 1) * 30, -118, 22, 8, C.LUCE, c)
		end
		s.carte[i] = { node = c, bordo = bordo, icona = icona, forma = forma, nome = nome, effetto = effetto, segni = segni }
	end
	gui.set_enabled(s.root, false)
	return s
end

-- Il prossimo che deve scegliere (chi non ha ancora scelto), o nil
local function prossimo(s)
	for i = 1, #s.d.players do
		if not s.d.picks[i] then return i end
	end
end

local function aggiorna(s)
	local d, chi = s.d, s.chi
	if chi then
		gui.set_text(s.titolo, s.giocatori[chi] .. ", scegli la tua arma")
		gui.set_color(s.titolo, s.colori[chi])
	end
	for i, c in ipairs(s.carte) do
		local w = d.offer[i]
		gui.set_enabled(c.node, w ~= nil)
		if w then
			gui.set_enabled(c.icona, s.icone[w] ~= nil)
			gui.set_enabled(c.forma, s.icone[w] == nil)
			if s.icone[w] then gui.play_flipbook(c.icona, s.icone[w]) end
			gui.set_text(c.nome, s.nomi[w])
			gui.set_text(c.effetto, s.effetti[w] or "")
			local libera = not chi or draft.valid(d, chi, w)
			gui.set_color(c.node, libera and C.PANNELLO or SPENTA)
			gui.set_color(c.bordo, libera and C.LUCE or C.LINEA)
			local k = 0
			for j = 1, #d.players do
				if d.picks[j] == w then
					k = k + 1
					gui.set_enabled(c.segni[k], true)
					gui.set_color(c.segni[k], s.colori[j])
				end
			end
			for m = k + 1, #c.segni do gui.set_enabled(c.segni[m], false) end
		end
	end
end

function M.show(s, d, giocatori, colori)
	s.d, s.giocatori, s.colori = d, giocatori, colori
	s.chi = prossimo(s)
	s.tempo = config.DRAFT_SECONDS
	s.fatto = nil
	gui.set_enabled(s.root, true)
	aggiorna(s)
end

local function scegli(s, w)
	if not (s.chi and draft.pick(s.d, s.chi, w)) then return end
	s.chi = prossimo(s)
	s.tempo = config.DRAFT_SECONDS
	-- un attimo per vedere l'ultima scelta prima di partire
	if not s.chi then s.fatto = 0.6 end
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
	if s.tempo <= 0 then
		-- allo scadere la prima arma libera
		for _, w in ipairs(s.d.offer) do
			if draft.valid(s.d, s.chi, w) then
				scegli(s, w)
				break
			end
		end
	end
	return nil
end

function M.on_input(s, action_id, action)
	if not s.d or s.fatto or action_id ~= TOUCH or not action.pressed then return end
	for i, c in ipairs(s.carte) do
		if s.d.offer[i] and gui.pick_node(c.node, action.x, action.y) then
			scegli(s, s.d.offer[i])
			return
		end
	end
end

return M
