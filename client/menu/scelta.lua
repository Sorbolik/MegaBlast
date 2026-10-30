-- Scelta d'inizio partita (le regole sono in sim/draft.lua; Sergio, 30 ott):
-- prima la primaria, poi la secondaria, una fila di carte alla volta. Le
-- scelte degli altri non si vedono e i doppioni vanno bene; il Rampino ce
-- l'hanno tutti. Sotto le carte le due scelte fatte: toccandone una si torna a
-- quella fila. Tenendo premuta una carta si apre la scheda dell'arma
-- (battaglia/scheda.lua), la stessa delle casse; un tocco la chiude. Col
-- controller la croce sposta la luce su carte, scelte e pulsanti, A sceglie, Y
-- apre la scheda e Start la rotellina (ui.tocco, ui/controller.lua).
-- Sullo stesso telefono si sceglie a turno, col tempo che aspetta chi legge
-- una scheda. Online sceglie solo chi gioca su questo telefono, finché il tempo
-- del server non scade: le scelte vanno al server (docs/server.md).
-- La prima scelta della campagna (guidata) non ha tempo, spiega di più e
-- finisce con GIOCA. La rotellina in alto a sinistra apre ESCI.
-- Pannelli e testo dell'interfaccia minimale (ui/ui.lua).
--
--   local scelta = require "menu.scelta"
--   local s = scelta.new(icone, nomi, effetti, comandi) -- icone (atlante armi), nomi e una riga sull'effetto per arma;
--                                                  -- comandi(): "telefono", "computer" o "controller" (per la scheda)
--   scelta.show(s, d, nomi_giocatori, colori, guidata) -- sullo stesso telefono: d = draft.new(...)
--   local players = scelta.update(s, dt)           -- i giocatori per game.new, quando tutti hanno scelto (online nil)
--   scelta.on_input(s, action_id, action)          -- "esci" se si tocca ESCI
--   scelta.online(s, m, nomi, colori, invia)       -- online, a ogni messaggio draft del server;
--                                                  -- invia(msg) manda le scelte
--   scelta.hide(s)

local config = require "sim.config"
local draft = require "sim.draft"
local game = require "sim.game"
local ui = require "ui.ui"
local controller = require "ui.controller"
local schermo = require "ui.schermo"
local scheda = require "battaglia.scheda"

local M = {}

local W, H = 1280, 720
local CARD_W, CARD_H, CARD_GAP = 280, 230, 40
local CARD_Y = 50
-- le due scelte fatte, sotto le carte
local SCELTA_W, SCELTA_H, SCELTA_Y = 300, 84, -175
local BAR_W = 560
local C = ui.C
local NOME_PASSO = { "PRIMARIA", "SECONDARIA" }
local COLORE_PASSO = { C.BRACE, C.ACCIAIO }
local VELO = vmath.vector4(C.FONDO.x, C.FONDO.y, C.FONDO.z, 0.86)
local TOUCH = hash("touch")
-- quanto tenere premuta una carta per aprire la sua scheda
local TIENI = 0.45

local function vec(x, y) return vmath.vector3(x, y, 0) end

local function nodo(x, y, w, h, colore, parent)
	local n = gui.new_box_node(vec(x, y), vec(w, h))
	gui.set_color(n, colore)
	if parent then gui.set_parent(n, parent) end
	return n
end

-- un testo che va a capo entro w
local function riga(t, y, scala, w, parent)
	local n = ui.testo(t, 0, y, scala, nil, parent)
	gui.set_line_break(n, true)
	gui.set_size(n, vmath.vector3(w / (scala * 0.5), 200, 0))
	return n
end

-- una carta (o una scelta fatta): pannello, icona, nome e una riga sotto
local function carta(x, y, w, h, icona_d, parent)
	local c, bordo = ui.pannello(x, y, w, h, parent)
	local icona = gui.new_box_node(vec(0, 0), vec(icona_d, icona_d))
	gui.set_texture(icona, "armi")
	gui.set_parent(icona, c)
	return { node = c, bordo = bordo, icona = icona }
end

function M.new(icone, nomi, effetti, comandi)
	local s = { icone = icone, nomi = nomi, effetti = effetti, comandi = comandi, carte = {}, scelte = {} }
	-- quello su cui va la luce del controller: carte, scelte fatte e pulsanti
	s.luce = {}
	s.root = nodo(W / 2, H / 2, W * schermo.PIENO, H * schermo.PIENO, VELO)
	gui.set_adjust_mode(s.root, gui.ADJUST_FIT)
	s.titolo = ui.titolo("", 0, 312, 0.55, nil, s.root)
	s.sotto = riga("", 255, 0.6, 1000, s.root)
	for i = 1, config.DRAFT_OFFER do
		local c = carta(0, CARD_Y, CARD_W, CARD_H, 96, s.root)
		gui.set_position(c.icona, vec(0, 40))
		c.nome = ui.testo("", 0, -32, 0.7, nil, c.node)
		c.effetto = riga("", -70, 0.5, CARD_W - 24, c.node)
		gui.set_color(c.effetto, C.SPENTO)
		s.carte[i] = c
		c.colore, c.azione, c.nodo = C.LUCE, "carta:" .. i, c.node
		s.luce[#s.luce + 1] = c
	end
	for passo = 1, 2 do
		local x = (passo - 1.5) * (SCELTA_W + 30)
		local c = carta(x, SCELTA_Y, SCELTA_W, SCELTA_H, 56, s.root)
		gui.set_position(c.icona, vec(-SCELTA_W / 2 + 46, 0))
		local tipo = ui.testo(NOME_PASSO[passo], -SCELTA_W / 2 + 90, 16, 0.5, COLORE_PASSO[passo], c.node)
		gui.set_pivot(tipo, gui.PIVOT_W)
		c.nome = ui.testo("", -SCELTA_W / 2 + 90, -14, 0.65, nil, c.node)
		gui.set_pivot(c.nome, gui.PIVOT_W)
		s.scelte[passo] = c
		c.colore, c.azione, c.nodo = C.LUCE, "scelta:" .. passo, c.node
		s.luce[#s.luce + 1] = c
	end
	s.bottoni = {}
	s.gioca = ui.bottone(s.bottoni, 0, -290, 300, 70, "GIOCA", "gioca", { principale = true }, s.root)
	s.barra = ui.barra(0, -300, BAR_W, 6, C.LUCE, s.root)
	-- la rotellina: un tocco apre ESCI accanto, un altro la richiude
	s.rotellina = ui.impostazioni(s.bottoni, "rotellina")
	s.esci = ui.bottone(s.bottoni, 32 + 12 + 80, 0, 160, 64, "ESCI", "esci", nil, s.rotellina)
	for _, b in ipairs(s.bottoni) do s.luce[#s.luce + 1] = b end
	gui.set_enabled(s.root, false)
	gui.set_enabled(s.rotellina, false)
	return s
end

-- Il ventaglio e le scelte del passo (1 primarie, 2 secondarie)
local function fila(d, passo)
	if passo == 1 then return d.offer, d.picks end
	return d.offer2, d.picks2
end

-- Il primo passo che manca a chi (3: ha finito); i ventagli vuoti si saltano
local function manca(d, chi)
	for passo = 1, 2 do
		local offer, picks = fila(d, passo)
		if #offer > 0 and not picks[chi] then return passo end
	end
	return 3
end

-- Il prossimo che deve scegliere sullo stesso telefono, o nil
local function prossimo(s)
	for i = 1, #s.d.players do
		if not draft.done(s.d, i) then return i end
	end
end

-- Titolo e righe sotto, secondo il passo e se la scelta è guidata
local function testi(s)
	local p, guida = s.passo, s.guidata
	local chi = s.online and "" or (#s.giocatori > 1 and not s.guidata and s.giocatori[s.chi] .. ", " or "")
	local titolo, sotto
	if p == 1 then
		titolo = chi .. "scegli la primaria"
		sotto = guida and "Prima di ogni partita scegli due armi in più, una per tipo; quelle degli altri non le vedi. "
			.. "La primaria ha " .. config.DRAFT_SHOTS .. " colpi a partita, e il Lanciarune ce l'hai sempre. "
			.. "Tieni premuta una carta per vedere la sua scheda."
			or "Ne hai " .. config.DRAFT_SHOTS .. " colpi; il Lanciarune ce l'hai sempre. Tieni premuta una carta per la sua scheda."
	elseif p == 2 then
		titolo = chi .. "scegli la secondaria"
		sotto = guida and "La secondaria non finisce mai, e la Lama ce l'hai sempre: questa è in più. Tieni premuta una carta per la sua scheda."
			or "Non finisce mai; la Lama ce l'hai sempre."
	else
		titolo = "Pronto"
		sotto = guida and "Il Rampino ce l'hai sempre. Nelle altre partite la scelta ha un tempo; qui no. "
			.. "Tocca una scelta per cambiarla, o GIOCA."
			or "Il Rampino ce l'hai sempre. Tocca una scelta per cambiarla."
	end
	-- col controller la scheda si apre con Y, e si sceglie con la croce
	if s.comandi and s.comandi() == "controller" then
		sotto = sotto:gsub("Tieni premuta una carta", "Premi " .. controller.nome_di("scheda") .. " su una carta")
			:gsub("Tocca una scelta", "Torna su una scelta")
	end
	gui.set_text(s.titolo, (titolo:gsub("^%l", string.upper)))
	gui.set_color(s.titolo, s.online and C.LUCE or s.colori[s.chi] or C.LUCE)
	gui.set_text(s.sotto, sotto)
end

local function aggiorna(s)
	local d, chi = s.d, s.chi
	testi(s)
	local offer, picks = fila(d, math.min(s.passo, 2))
	local x0 = -((#offer - 1) * (CARD_W + CARD_GAP)) / 2
	for i, c in ipairs(s.carte) do
		local w = s.passo <= 2 and offer[i]
		gui.set_enabled(c.node, w and true or false)
		if w then
			gui.set_position(c.node, vec(x0 + (i - 1) * (CARD_W + CARD_GAP), CARD_Y))
			gui.play_flipbook(c.icona, s.icone[w])
			gui.set_text(c.nome, s.nomi[w])
			gui.set_text(c.effetto, s.effetti[w] or "")
			c.riposo = picks[chi] == w and C.LUCE or COLORE_PASSO[s.passo]
			gui.set_color(c.bordo, c.riposo)
		end
	end
	for passo, c in ipairs(s.scelte) do
		local of, pk = fila(d, passo)
		local w = pk[chi]
		gui.set_enabled(c.node, #of > 0)
		gui.set_enabled(c.icona, w ~= nil)
		if w then gui.play_flipbook(c.icona, s.icone[w]) end
		gui.set_text(c.nome, w and s.nomi[w] or "...")
		c.riposo = passo == s.passo and C.LUCE or w and COLORE_PASSO[passo] or C.LINEA
		gui.set_color(c.bordo, c.riposo)
	end
	gui.set_enabled(s.gioca, s.guidata and s.passo == 3)
	gui.set_enabled(s.barra.nodo, not s.guidata)
	ui.riaccendi(s.luce)
end

-- La scheda aperta col tocco lungo, se c'è, si chiude
local function chiudi_scheda(s)
	if s.carta then s.carta:chiudi() end
	s.carta, s.premuta = nil, nil
end

local function apri(s)
	gui.set_enabled(s.root, true)
	gui.set_enabled(s.rotellina, true)
	gui.set_enabled(s.esci, false)
	s.fatto = nil
	aggiorna(s)
end

function M.show(s, d, giocatori, colori, guidata)
	s.d, s.giocatori, s.colori, s.guidata = d, giocatori, colori, guidata
	s.online = nil
	s.chi = prossimo(s)
	s.passo = s.chi and manca(d, s.chi) or 3
	s.tempo = config.DRAFT_SECONDS
	apri(s)
end

local function vuoto(v) return v ~= "" and v or nil end

-- Online: m è il messaggio draft del server (ventagli, le nostre scelte, tick
-- rimasti). Ne fa una copia dello stato di sim/draft.lua per chi gioca qui.
function M.online(s, m, giocatori, colori, invia)
	local d = { offer = m.offer, offer2 = m.offer2, players = m.players, picks = {}, picks2 = {} }
	d.picks[m.you], d.picks2[m.you] = vuoto(m.p), vuoto(m.p2)
	local primo = not s.online
	s.d, s.giocatori, s.colori, s.guidata = d, giocatori, colori, nil
	s.online, s.invia, s.chi = true, invia, m.you
	s.tempo = (m.left or 0) * game.DT
	if primo then
		s.passo = manca(d, s.chi)
		apri(s)
	else
		aggiorna(s)
	end
end

function M.hide(s)
	chiudi_scheda(s)
	gui.set_enabled(s.root, false)
	gui.set_enabled(s.rotellina, false)
	s.d, s.online = nil, nil
end

local function scegli(s, w)
	if not (s.chi and draft.pick(s.d, s.chi, w)) then return end
	if s.online then s.invia({ t = "pick", w = w }) end
	s.passo = manca(s.d, s.chi)
	if s.passo == 3 and not s.online and not s.guidata then
		-- sullo stesso telefono, finito uno tocca al prossimo
		local dopo = prossimo(s)
		if dopo then
			s.chi, s.passo, s.tempo = dopo, manca(s.d, dopo), config.DRAFT_SECONDS
		else
			-- un attimo per vedere l'ultima scelta prima di partire
			s.fatto = 0.6
		end
	end
	aggiorna(s)
end

local function finisci(s)
	chiudi_scheda(s)
	gui.set_enabled(s.root, false)
	gui.set_enabled(s.rotellina, false)
	local players = draft.finish(s.d)
	s.d = nil
	return players
end

function M.update(s, dt)
	if not s.d then return nil end
	if s.fatto then
		s.fatto = s.fatto - dt
		if s.fatto > 0 then return nil end
		return finisci(s)
	end
	-- tenuta abbastanza: la scheda dell'arma, e la carta non si sceglie
	if s.premuta then
		s.premuta.t = s.premuta.t + dt
		if s.premuta.t >= TIENI then
			s.carta = scheda.apri(s.premuta.w, s.comandi and s.comandi(), true)
			s.premuta = nil
		end
	end
	-- la scelta guidata non ha tempo; sullo stesso telefono il tempo aspetta chi legge la scheda
	if s.guidata or (s.carta and not s.online) then return nil end
	s.tempo = s.tempo - dt
	ui.barra_valore(s.barra, s.tempo / config.DRAFT_SECONDS)
	-- online allo scadere decide il server
	if s.online then return nil end
	if s.tempo <= 0 and s.chi then
		-- allo scadere la prima arma di ogni fila che manca
		local chi = s.chi
		while s.chi == chi and not s.fatto and s.passo <= 2 do
			scegli(s, (fila(s.d, s.passo))[1])
		end
	end
	return nil
end

-- Col controller (action_id ui.PAD): la luce, A, Y per la scheda, Start la rotellina
local function controller(s, action)
	if not action.pressed then return end
	if s.carta then
		chiudi_scheda(s)
		return
	end
	local u = action.ui
	if u == "menu" or (u == "indietro" and gui.is_enabled(s.esci)) then
		gui.set_enabled(s.esci, u == "menu" and not gui.is_enabled(s.esci))
		if gui.is_enabled(s.esci) then ui.luce(s.luce, s.bottoni[#s.bottoni]) end
		return
	end
	local acceso = ui.illuminato(s.luce)
	local azione
	if u == "scheda" then
		azione = acceso and acceso.azione
	else
		azione = ui.tocco(s.luce, ui.PAD, action)
	end
	if not azione then return end
	local tipo, i = azione:match("^(%a+):(%d)$")
	i = tonumber(i)
	if azione == "esci" then
		return "esci"
	elseif azione == "rotellina" then
		gui.set_enabled(s.esci, not gui.is_enabled(s.esci))
	elseif azione == "gioca" then
		s.fatto = 0
	elseif tipo == "carta" and s.passo <= 2 then
		local w = fila(s.d, s.passo)[i]
		if w and u == "scheda" then
			s.carta = scheda.apri(w, s.comandi and s.comandi(), true)
		elseif w then
			scegli(s, w)
		end
	elseif tipo == "scelta" and u ~= "scheda" then
		s.passo = i
		aggiorna(s)
	end
end

function M.on_input(s, action_id, action)
	if not s.d or s.fatto then return end
	if action_id == ui.PAD then return controller(s, action) end
	if action_id ~= TOUCH then return end
	-- la scheda aperta: un tocco qualsiasi la chiude
	if s.carta then
		if action.pressed then chiudi_scheda(s) end
		return
	end
	local azione = ui.tocco(s.bottoni, action_id, action)
	if azione == "rotellina" then
		gui.set_enabled(s.esci, not gui.is_enabled(s.esci))
		return
	elseif azione == "esci" then
		return "esci"
	elseif azione == "gioca" then
		s.fatto = 0
		return
	end
	-- la carta si sceglie quando si lascia, se non è stata tenuta per la scheda
	if action.released then
		local p = s.premuta
		s.premuta = nil
		if p then scegli(s, p.w) end
		return
	end
	if not action.pressed or s.bottoni.premuto then return end
	gui.set_enabled(s.esci, false)
	if s.passo <= 2 then
		local offer = fila(s.d, s.passo)
		for i, c in ipairs(s.carte) do
			if offer[i] and gui.pick_node(c.node, action.x, action.y) then
				s.premuta = { w = offer[i], t = 0 }
				return
			end
		end
	end
	-- una scelta fatta: si torna a quella fila
	for passo, c in ipairs(s.scelte) do
		if gui.is_enabled(c.node) and gui.pick_node(c.node, action.x, action.y) then
			s.passo = passo
			aggiorna(s)
			return
		end
	end
end

return M
