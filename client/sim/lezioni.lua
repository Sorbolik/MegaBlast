-- Lezioni e partita guidata (schermata ALLENAMENTO, menu/allenamento.lua).
-- Ogni lezione è un piccolo rompicapo di meno di un minuto che insegna una
-- cosa sola e non si finisce senza usarla: l'obiettivo è scritto proprio
-- sull'uso della meccanica (es. "il bersaglio cade nel vuoto DOPO il
-- Rampino"). Tre stelle: fatta, fatta in pochi turni, fatta in meno ancora.
-- Sono dati, nello stesso formato che userà la campagna (docs/roadmap.md,
-- area 7). Lua puro: il gui_script mostra la riga e le stelle.
--
--   local r = lezioni.nuova("rampino")
--   local seed, mappa, opts = lezioni.partita(r)  -- per game.new (o replay.nuova)
--   lezioni.prepara(r, g)                         -- subito dopo, una volta
--   lezioni.evento(r, g, e, bots)                 -- per ogni evento della simulazione (bots: di replay.partita)
--   local esito = lezioni.tick(r, g)              -- a ogni tick: nil, "fatta" o "fallita"
--   local testo, chi = lezioni.riga(r)            -- il suggerimento da mostrare sopra il robot chi (o nil)
--   lezioni.stelle(r)                             -- 1..3 quando è fatta

local game = require "sim.game"
local maps = require "sim.maps"
local terrain = require "sim.terrain"

local M = {}

local STEEL = terrain.STEEL
local GIOCATORE = 1
-- secondi di una riga che non ha un "fino": poi sparisce da sola
local RIGA_SECONDI = 5

-- Quale arma ha appena usato chi: l'evento dell'attacco -> nome dell'arma
local ATTACCHI = {
	fire = "missile", grenade = "grenade", shards = "shards", punch = "punch", sniper = "sniper",
	swing = "sword", eagle = "eagle", mallet = "mallet", lunge = "lunge",
}
local PRIMARIE_CASSE = { grenade = true, shards = true, punch = true, sniper = true }
local SECONDARIE_SCELTE = { eagle = true, mallet = true, lunge = true }

-- Aiuti per gli obiettivi ----------------------------------------------------------

local function colpito(e, chi)
	return e and e.type == "damage" and e.robot == chi and e.amount > 0
end

-- in piedi sopra la quota y, oltre la x
local function sopra(g, x, y)
	local rb = g.robots[GIOCATORE]
	return not rb.dead and rb.grounded and rb.x >= x and rb.y >= y - 1
end

-- Una cassa dal cielo nel punto x, con dentro arma (le lezioni non le lasciano al caso)
local function cassa(g, x, arma)
	g.crate_id = g.crate_id + 1
	local c = { id = g.crate_id, x = x, y = game.WORLD_H + 20, vy = 0, landed = false, weapon = arma }
	g.crates[#g.crates + 1] = c
	g:emit({ type = "crate", id = c.id, x = x, y = g.terrain:ground_below(x, game.WORLD_H) or 0 })
end

-- Le lezioni -----------------------------------------------------------------------
-- id, titolo, scopo (la prima riga, finché non è fatta), terreno e spawns (la
-- mappa della lezione: prima il giocatore, poi i bersagli) oppure mappa,
-- giocatori (opts.players di game.new), opzioni (altre opts), turni (oltre
-- questi turni del giocatore si ricomincia), stelle (turni per la seconda e la
-- terza stella), inizio(st, g), obiettivo(st, g, e) (e = nil a ogni tick),
-- fallita(st, g), righe { testo, quando(st, g, e), fino(st, g, e) }.
-- Coordinate del mondo (1920 x 1080, y in alto); il pavimento è d'acciaio, così
-- i crateri non rompono il rompicapo.

local function pavimento(t, x, w, h)
	t:rect(x, 0, w, h, STEEL)
end

M.LISTA = {
	{
		id = "guidata",
		titolo = "Prima partita",
		scopo = "Trascina dal diavoletto per mirare, lascia per sparare",
		guidata = true,
		mappa = "forgia",
		giocatori = {
			{ team = 1, pick = "grenade", secondary = "mallet", tool = "hook" },
			{ team = 2, bot = "tutorial", pick = "grenade", secondary = "mallet", tool = "hook" },
		},
		-- partita corta: 3 minuti
		secondi = 180,
		-- il bot fa vedere nel suo turno quello che il giocatore farà nel turno dopo
		piani = { { due_attacchi = true }, { attacca_entro = 4, poi = "teletrasporto" } },
		obiettivo = function(st) return st.finita end,
		righe = {
			{ testo = "Hai 8 secondi: mettiti al riparo",
				quando = function(st, g) return st.turni == 1 and g.current == GIOCATORE and g.window > 0 end },
			{ testo = "Il bot fa due attacchi: una primaria e una secondaria", su = "bot",
				quando = function(st, g) return st.turni_bot == 1 and g.current ~= GIOCATORE end },
			{ testo = "Due attacchi a turno: un'arma a sinistra e una a destra del cronometro",
				quando = function(st, g) return st.turni == 2 and g.current == GIOCATORE end,
				fino = function(_, g) return g.used.primary and g.used.secondary end },
			{ testo = "Ha attaccato subito: i secondi che avanzano diventano globi", su = "bot",
				quando = function(st, _, e) return st.turni_bot == 2 and e and e.type == "teleports" and e.robot ~= GIOCATORE end },
			{ testo = "Attacca presto: ogni 10 secondi che avanzano, un globo",
				quando = function(st, g) return st.turni == 3 and g.current == GIOCATORE end,
				fino = function(_, g) return g.used.primary or g.used.secondary end },
			{ testo = "Lancia un globo col tasto viola: arrivi dove cade",
				quando = function(st, g, e) return st.turni == 3 and e and e.type == "teleports" and e.robot == GIOCATORE end,
				fino = function(_, _, e) return e and e.type == "teleport" and e.robot == GIOCATORE end },
			{ testo = "Una cassa! Passaci sopra per prendere quello che c'e dentro",
				quando = function(_, _, e) return e and e.type == "crate" end,
				fino = function(_, _, e) return e and e.type == "crate_pick" end },
			{ testo = "Tocca in aria per il paracadute: uno a partita",
				quando = function(_, g)
					local rb = g.robots[GIOCATORE]
					return g.current == GIOCATORE and not rb.grounded and rb.vy < -220 and rb.parachutes_left > 0
				end,
				fino = function(_, _, e) return e and e.type == "parachute" end },
			{ testo = "Sei primo: chi ti colpisce prende i punti per 1,5",
				quando = function(_, g) return g:leader() == g.robots[GIOCATORE] end },
			{ testo = "Si rinasce subito, e il turno continua",
				quando = function(_, _, e) return e and e.type == "death" and e.robot == GIOCATORE end },
			{ testo = "Fermati nel cerchio alla fine di un turno: ti cura",
				quando = function(_, _, e) return e and e.type == "heal_spawn" end },
		},
	},
	{
		id = "armi",
		titolo = "Armi e draft",
		scopo = "Colpisci il bersaglio con la primaria e con la secondaria che hai scelto",
		draft = true,
		terreno = function(t) pavimento(t, 240, 1440, 150) end,
		spawns = { { x = 760, from = 600 }, { x = 1080, from = 600 } },
		giocatori = { { team = 1 }, { team = 2, dummy = true } },
		turni = 4, stelle = { 3, 2 },
		obiettivo = function(st, _, e)
			if colpito(e, 2) then
				if PRIMARIE_CASSE[st.arma] then st.primaria = true end
				if SECONDARIE_SCELTE[st.arma] then st.secondaria = true end
			end
			return st.primaria and st.secondaria
		end,
		righe = {
			{ testo = "Lanciarune e Lama ci sono sempre. La primaria scelta ha 2 colpi, la secondaria non finisce",
				quando = function(st) return st.turni == 2 end },
		},
	},
	{
		id = "globi",
		titolo = "Tempo e globi",
		scopo = "Attacca entro 5 secondi: guadagni globi. Poi teletrasportati sull'isola",
		-- la tua terra, il vuoto, e l'isola del secondo bersaglio
		terreno = function(t)
			pavimento(t, 300, 600, 150)
			t:rect(1200, 100, 320, 50, STEEL)
		end,
		spawns = { { x = 600, from = 600 }, { x = 800, from = 600 }, { x = 1380, from = 600 } },
		giocatori = { { team = 1, stats = { teleports = 0 } }, { team = 2, dummy = true }, { team = 2, dummy = true } },
		turni = 3, stelle = { 2, 1 },
		obiettivo = function(st, g, e)
			if e and e.type == "teleports" and e.robot == GIOCATORE then st.globi = true end
			if st.globi and sopra(g, 1200, 150) then st.isola = true end
			return st.isola and e ~= nil and e.type == "sword_hit" and e.target == 3
		end,
		righe = {
			{ testo = "Tocca il tasto viola, mira l'isola e lascia: arrivi dove cade il globo",
				quando = function(_, _, e) return e and e.type == "teleports" and e.robot == GIOCATORE end,
				fino = function(_, _, e) return e and e.type == "teleport" end },
			{ testo = "Ora la Lama: e la tua secondaria di sempre",
				quando = function(st) return st.isola end },
		},
	},
	{
		id = "casse",
		titolo = "Le casse",
		scopo = "Prendi la cassa che cade e colpisci il bersaglio con quello che c'e dentro",
		terreno = function(t) pavimento(t, 240, 1440, 150) end,
		spawns = { { x = 640, from = 600 }, { x = 1180, from = 600 } },
		giocatori = { { team = 1 }, { team = 2, dummy = true } },
		-- nelle partite vere una cassa ogni 3 turni dal 4°; qui al secondo turno
		opzioni = { crate_every = 1000 },
		turni = 4, stelle = { 3, 2 },
		obiettivo = function(st, g, e)
			if e and e.type == "turn" and st.turni == 2 and not st.cassa then
				st.cassa = true
				cassa(g, 820, "grenade")
			end
			return colpito(e, 2) and st.arma == "grenade"
		end,
		righe = {
			{ testo = "Ogni 3 turni cade una cassa: dentro c'e un'arma o un oggetto a sorpresa",
				quando = function(st) return st.turni == 1 end },
			{ testo = "La cassa e tua: la Granata e nella barra a sinistra",
				quando = function(_, _, e) return e and e.type == "crate_pick" end },
		},
	},
	{
		id = "paracadute",
		titolo = "Il paracadute",
		scopo = "Salta dalla torre e apri il paracadute in aria: arriva al bersaglio",
		terreno = function(t)
			pavimento(t, 300, 120, 560)
			t:rect(760, 0, 640, 150, STEEL)
		end,
		spawns = { { x = 360, from = 1000 }, { x = 1100, from = 600 } },
		giocatori = { { team = 1, stats = { teleports = 0 } }, { team = 2, dummy = true } },
		turni = 2, stelle = { 2, 1 },
		obiettivo = function(st, g, e)
			if e and e.type == "parachute" and e.robot == GIOCATORE then st.aperto = true end
			if st.aperto and sopra(g, 760, 150) then st.arrivato = true end
			return st.arrivato and colpito(e, 2)
		end,
		-- uno a partita: se lo hai già usato e non sei arrivato, si ricomincia
		fallita = function(st, g)
			local rb = g.robots[GIOCATORE]
			return not st.arrivato and (rb.dead or (rb.grounded and st.aperto and rb.parachutes_left == 0 and not sopra(g, 760, 150)))
		end,
		righe = {
			{ testo = "Tocca di nuovo per chiuderlo. E uno solo a partita",
				quando = function(_, _, e) return e and e.type == "parachute" and e.robot == GIOCATORE end },
		},
	},
	{
		id = "rampino",
		titolo = "Il Rampino",
		scopo = "Il bersaglio e in alto: aggancia il bordo col Rampino e ti arrampichi",
		-- una piattaforma sospesa, troppo alta per il salto
		terreno = function(t)
			pavimento(t, 300, 1300, 150)
			t:rect(1000, 300, 320, 30, STEEL)
		end,
		spawns = { { x = 760, from = 290 }, { x = 1220, from = 1000 } },
		giocatori = { { team = 1, tool = "hook", stats = { teleports = 0 } }, { team = 2, dummy = true } },
		turni = 2, stelle = { 2, 1 },
		obiettivo = function(st, g, e)
			if e and e.type == "hook" and e.robot == GIOCATORE and e.anchor then st.aggancio = true end
			if st.aggancio and sopra(g, 1000, 330) then st.sopra = true end
			return st.sopra and e ~= nil and e.type == "sword_hit" and e.target == 2
		end,
		righe = {
			{ testo = "Su un nemico invece lo tiri da te: buttalo giu e sono 50 punti in piu",
				quando = function(st) return st.sopra end },
		},
	},
	{
		id = "bastione",
		titolo = "Il Bastione",
		scopo = "La sporgenza e troppo alta: posa un blocco col Bastione e usalo come gradino",
		terreno = function(t)
			pavimento(t, 300, 1300, 150)
			t:rect(1060, 150, 540, 72, STEEL)
		end,
		spawns = { { x = 760, from = 600 }, { x = 1300, from = 600 } },
		giocatori = { { team = 1, tool = "wall", stats = { teleports = 0 } }, { team = 2, dummy = true } },
		turni = 3, stelle = { 2, 1 },
		obiettivo = function(st, g, e)
			if e and e.type == "wall" and e.robot == GIOCATORE and e.v == 1 then st.blocco = true end
			if st.blocco and sopra(g, 1060, 222) then st.sopra = true end
			return st.sopra and e ~= nil and e.type == "sword_hit" and e.target == 2
		end,
		righe = {
			{ testo = "Uno a turno, al massimo due in mappa. Ora la Lama",
				quando = function(st) return st.sopra end },
		},
	},
	{
		id = "maglio",
		titolo = "Il Maglio",
		scopo = "Salta e colpisci il terreno col Maglio: rimbalzi in alto fino al bersaglio",
		terreno = function(t)
			pavimento(t, 300, 1300, 150)
			t:rect(1000, 150, 160, 200, STEEL)
		end,
		spawns = { { x = 840, from = 600 }, { x = 1120, from = 1000 } },
		giocatori = { { team = 1, secondary = "mallet", tool = "wall", stats = { teleports = 0 } }, { team = 2, dummy = true } },
		turni = 3, stelle = { 2, 1 },
		obiettivo = function(st, g, e)
			if e and e.type == "mallet_hit" and e.robot == GIOCATORE and e.bounce then st.rimbalzo = true end
			if st.rimbalzo and sopra(g, 1000, 350) then st.sopra = true end
			return st.sopra and colpito(e, 2)
		end,
		righe = {
			{ testo = "Ogni secondaria ti sposta: il Tonante spinge indietro, l'Affondo passa oltre",
				quando = function(st) return st.sopra end },
		},
	},
	{
		id = "corona",
		titolo = "Punti e Corona",
		scopo = "Abbatti chi ha la Corona: i suoi colpi valgono 1,5 e in piu 25 punti",
		terreno = function(t) pavimento(t, 240, 1440, 150) end,
		spawns = { { x = 900, from = 600 }, { x = 560, from = 600 }, { x = 1320, from = 600 }, { x = 1120, from = 600 } },
		giocatori = { { team = 1 }, { team = 2, dummy = true }, { team = 3, dummy = true }, { team = 4, dummy = true } },
		turni = 4, stelle = { 3, 2 },
		inizio = function(_, g)
			-- il terzo bersaglio è primo in classifica: ha la Corona. Sono già
			-- feriti, così un turno basta
			g.robots[4].points = 200
			g.robots[2].points, g.robots[3].points = 60, 40
			for i = 2, 4 do g.robots[i].hp = 30 end
		end,
		obiettivo = function(_, _, e)
			return e ~= nil and e.type == "death" and e.robot == 4 and e.by == GIOCATORE
		end,
		righe = {
			{ testo = "Danno = punti. Abbattere vale 50, buttare nel vuoto altri 50",
				quando = function(_, _, e) return e and e.type == "points" and e.robot == GIOCATORE end },
		},
	},
}

local PER_ID = {}
for _, l in ipairs(M.LISTA) do
	PER_ID[l.id] = l
	if l.terreno then
		l.mappa = "lezione_" .. l.id
		maps.registra(l.mappa, { name = l.titolo, spawns = l.spawns, build = function(t) l.terreno(t) end })
	end
end

function M.trova(id)
	return PER_ID[id]
end

-- Lo stato di una lezione in corso
function M.nuova(id)
	local l = assert(PER_ID[id], "lezione sconosciuta: " .. tostring(id))
	return { l = l, st = { turni = 0, turni_bot = 0 }, viste = {}, riga = nil, esito = nil }
end

-- seme, mappa e opzioni di game.new. picks: i giocatori usciti dal draft
-- (menu/scelta.lua), per le lezioni che lo fanno fare
function M.partita(r, seed, picks)
	local l = r.l
	local players = {}
	for i, p in ipairs(l.giocatori) do
		local q = {}
		for k, v in pairs(p) do q[k] = v end
		if picks and picks[i] then
			q.pick, q.secondary, q.tool = picks[i].pick, picks[i].secondary, picks[i].tool or q.tool
		end
		players[i] = q
	end
	local opts = { players = players }
	for k, v in pairs(l.opzioni or {}) do opts[k] = v end
	-- senza bot né casse: le lezioni non cambiano col caso
	if not l.guidata and not opts.crate_every then opts.crate_every = 1000 end
	return seed or 1, l.mappa, opts
end

-- Dopo game.new: tempo della partita, ritocchi della lezione, la prima riga.
-- Gli eventi dell'inizio (il primo turno) li conta qui e li scarta.
function M.prepara(r, g)
	local l, st = r.l, r.st
	if l.secondi then g.match_left = l.secondi * 60 end
	if l.inizio then l.inizio(st, g) end
	g:pop_events()
	if g.current == GIOCATORE then st.turni = 1 else st.turni_bot = 1 end
	r.coda = {}
	-- lo scopo finché non si fa la prima cosa
	r.riga = nil
	r.coda[1] = { testo = l.scopo, fino = function(_, g2) return g2.used.primary or g2.used.secondary or g2.used.tool end }
end

-- Una riga alla volta: quella nuova aspetta che l'altra sia fatta o scaduta
-- (o che cominci un altro turno).
-- Senza "fino" resta RIGA_SECONDI, con "fino" al massimo il doppio.
local function mostra(r, riga)
	r.riga, r.riga_fino = riga.testo, riga.fino
	r.riga_su = riga.su == "bot" and 2 or GIOCATORE
	r.riga_t = (riga.fino and 2 or 1) * RIGA_SECONDI * 60
end

-- e = nil: il controllo a ogni tick
local function controlla(r, g, e)
	local l, st = r.l, r.st
	if r.esito then return end
	if l.obiettivo(st, g, e) then
		r.esito = "fatta"
		return
	end
	if r.riga and r.riga_fino and r.riga_fino(st, g, e) then r.riga = nil end
	-- un turno nuovo: le righe del turno prima non servono più
	if e and e.type == "turn" then r.riga, r.coda = nil, {} end
	for i, riga in ipairs(l.righe or {}) do
		if not r.viste[i] and riga.quando(st, g, e) then
			r.viste[i] = true
			r.coda[#r.coda + 1] = riga
		end
	end
	if not r.riga and #r.coda > 0 then mostra(r, table.remove(r.coda, 1)) end
end

function M.evento(r, g, e, bots)
	local st = r.st
	if ATTACCHI[e.type] and e.robot == GIOCATORE then st.arma = ATTACCHI[e.type] end
	if e.type == "turn" then
		if e.robot == GIOCATORE then st.turni = st.turni + 1 else st.turni_bot = st.turni_bot + 1 end
		-- il bot di turno fa vedere quello che il giocatore farà dopo (sim/bot.lua, b.piano)
		local b = bots and bots[e.robot]
		if b then b.piano = r.l.piani and r.l.piani[st.turni_bot] or nil end
		-- oltre i turni della lezione si ricomincia
		local l = r.l
		if l.turni and st.turni > l.turni and not r.esito then r.esito = "fallita" end
	elseif e.type == "over" then
		st.finita, st.vinta = true, e.winner == g.robots[GIOCATORE].team
		local me, altri = g.robots[GIOCATORE].points, 0
		for i, rb in ipairs(g.robots) do
			if i ~= GIOCATORE then altri = math.max(altri, rb.points) end
		end
		st.distacco = me - altri
	end
	controlla(r, g, e)
end

function M.tick(r, g)
	local l, st = r.l, r.st
	-- primo turno della partita guidata: il cronometro aspetta il primo colpo
	if l.guidata and st.turni == 1 and g.current == GIOCATORE and g.phase == "aim"
		and not g.used.primary and not g.used.secondary then
		g.timer = game.TURN_TICKS
	end
	controlla(r, g, nil)
	if not r.esito and l.fallita and l.fallita(st, g) then r.esito = "fallita" end
	if r.riga_t then
		r.riga_t = r.riga_t - 1
		if r.riga_t <= 0 then r.riga, r.riga_t = nil, nil end
	end
	return r.esito
end

-- La riga da mostrare e sopra chi (il robot), o nil
function M.riga(r)
	return r.riga, r.riga_su
end

-- Stelle: una per averla fatta, due e tre se in pochi turni. Nella partita
-- guidata: finita, vinta, vinta con almeno 100 punti di distacco.
function M.stelle(r)
	if r.esito ~= "fatta" then return 0 end
	local l, st = r.l, r.st
	if l.guidata then
		if not st.vinta then return 1 end
		return st.distacco >= 100 and 3 or 2
	end
	if st.turni <= l.stelle[2] then return 3 end
	if st.turni <= l.stelle[1] then return 2 end
	return 1
end

return M
