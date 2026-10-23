-- Scelta d'inizio partita sullo stesso telefono (le regole sono in sim/draft.lua):
-- il ventaglio di armi, e a turno ogni giocatore tocca la sua. Le armi prese
-- da un compagno sono spente; allo scadere del tempo si prende la prima libera.
-- Solo forme e testo disegnati da codice.
--
--   local scelta = require "menu.scelta"
--   local s = scelta.new(icone, nomi)              -- icone e nomi per arma, nascosta
--   scelta.show(s, d, nomi_giocatori, colori)      -- d = draft.new(...)
--   local players = scelta.update(s, dt)           -- i giocatori per game.new, quando tutti hanno scelto
--   scelta.on_input(s, action_id, action)

local ui = require "ui.ui"
local config = require "sim.config"
local draft = require "sim.draft"

local M = {}

local W, H = 1280, 720
local CARD_W, CARD_H, CARD_GAP = 220, 260, 40
local BAR_W = 560
local FONDO = vmath.vector4(0.03, 0.03, 0.05, 0.86)
local CARTA = vmath.vector4(0.12, 0.12, 0.15, 0.95)
local SPENTA = vmath.vector4(0.12, 0.12, 0.15, 0.35)
local BIANCO = vmath.vector4(1, 1, 1, 1)
local TOUCH = hash("touch")

local function vec(x, y) return vmath.vector3(x, y, 0) end

local function nodo(x, y, w, h, colore, parent)
	local n = gui.new_box_node(vec(x, y), vec(w, h))
	gui.set_color(n, colore)
	if parent then gui.set_parent(n, parent) end
	return n
end

-- testo dell'interfaccia minimale (ui/ui.lua)
local function testo(t, x, y, scala, parent)
	return ui.testo(t, x, y, scala, BIANCO, parent)
end

function M.new(icone, nomi)
	local s = { icone = icone, nomi = nomi, carte = {} }
	s.root = nodo(W / 2, H / 2, W, H, FONDO)
	gui.set_adjust_mode(s.root, gui.ADJUST_STRETCH)
	s.titolo = testo("", 0, 220, 1.4, s.root)
	s.sotto = testo("Di questa arma hai " .. config.DRAFT_SHOTS .. " colpo. Missile e Lama li hai sempre.", 0, 180, 0.8, s.root)
	nodo(0, -220, BAR_W, 6, SPENTA, s.root)
	s.barra = nodo(-BAR_W / 2, -220, BAR_W, 6, BIANCO, s.root)
	gui.set_pivot(s.barra, gui.PIVOT_W)
	local x0 = -((config.DRAFT_OFFER - 1) * (CARD_W + CARD_GAP)) / 2
	for i = 1, config.DRAFT_OFFER do
		local c = nodo(x0 + (i - 1) * (CARD_W + CARD_GAP), 0, CARD_W, CARD_H, CARTA, s.root)
		local icona = gui.new_box_node(vec(0, 30), vec(120, 120))
		gui.set_texture(icona, "battaglia")
		gui.set_parent(icona, c)
		local nome = testo("", 0, -70, 0.8, c)
		-- un segno del colore di chi l'ha presa, per ognuno
		local segni = {}
		for k = 1, 4 do
			segni[k] = nodo(-45 + (k - 1) * 30, -105, 22, 8, BIANCO, c)
		end
		s.carte[i] = { node = c, icona = icona, nome = nome, segni = segni }
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
			gui.play_flipbook(c.icona, s.icone[w])
			gui.set_text(c.nome, s.nomi[w])
			gui.set_color(c.node, (not chi or draft.valid(d, chi, w)) and CARTA or SPENTA)
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
	gui.set_size(s.barra, vec(BAR_W * math.max(0, s.tempo) / config.DRAFT_SECONDS, 6))
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
