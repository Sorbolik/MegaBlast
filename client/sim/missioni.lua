-- Missioni: le lezioni (Capitolo 0) e i gironi della campagna (sim/campagna.lua),
-- tutte nello stesso formato. Una missione è una partita vera con un obiettivo
-- scritto come dati: pochi verbi (sotto) invece di codice, così un giorno le
-- manda il server e servono anche al rompicapo del giorno (docs/roadmap.md,
-- area 3). Lua puro: il gui_script mostra la riga, l'obiettivo e le stelle.
--
--   local r = missioni.nuova("rampino")
--   local seed, mappa, opts = missioni.partita(r, seed, picks, aiuto)  -- per game.new (o replay.nuova);
--                                                   aiuto: dopo tante perse, avversari più morbidi
--   missioni.prepara(r, g)                          -- subito dopo, una volta
--   missioni.evento(r, g, e, bots)                  -- per ogni evento della simulazione (bots: di replay.partita)
--   local esito = missioni.tick(r, g)               -- a ogni tick: nil, "fatta" o "fallita"
--   missioni.tocca(r, cosa)                         -- il giocatore ha toccato i comandi (lezioni: parte il tempo; r nil: niente);
--                                                   cosa: l'arma scelta, "salta", "mira", "annulla" o nil
--   local cosa = missioni.evidenzia(r)              -- il comando da mettere in luce (o nil)
--   missioni.vede(r, arma)                          -- quell'arma (o "teleport", "parachute", "tempo",
--                                                   "punti") si vede nell'HUD? (r nil: tutto)
--   local x, y = missioni.bandiera(r)               -- dove sta la bandierina a scacchi (o nil)
--   local testo, chi = missioni.riga(r)             -- il suggerimento da mostrare sopra il robot chi (o nil)
--   local testo = missioni.obiettivo(r)             -- l'obiettivo che resta, sempre in vista (o nil)
--   missioni.stelle(r)                              -- { true, false, true }: ogni stella col suo criterio
--   missioni.quante(stelle)                         -- quante sono accese
--   missioni.criteri(l)                             -- cosa serve per ogni stella: { "FATTA", "IN 2 TURNI", ... }
--   missioni.dopo(id)                               -- la missione che viene dopo nel capitolo (nil dopo l'ultima)
--
-- Una missione (campi, tutti dati salvo dove si dice):
--   id, titolo, scopo (la prima riga, finché non si fa la prima cosa), evidenzia
--     (il comando che lo scopo mette in luce, come nelle righe sotto)
--   mappa (una mappa del gioco) oppure arena = { { x, y, w, h }, ... } (rettangoli
--     d'acciaio: i crateri non rompono il rompicapo) e spawns (prima il giocatore)
--   giocatori: opts.players di game.new (team, bot = livello, carattere, dummy, pick,
--     secondary, tool, stats); nome: come si chiama quel robot (i custodi);
--     battute: chi parla per lui (battaglia/battute.lua; senza, il suo carattere)
--   vedi = { "missile", "eagle", ... }: le lezioni mostrano solo quello che serve
--     ("primarie", "secondarie": tutte quelle che hai; "teleport": il tasto e i globi
--     dal tempo; "parachute"; "tempo": il cronometro; "punti": i punteggi): il
--     resto non c'è nemmeno. L'interfaccia si scopre a poco a poco (Sergio, 29 ott):
--     senza vedi si vede tutto, con vedi il cronometro e i punti solo se ci sono.
--     Un'arma raccolta da una cassa si vede da lì in poi
--   senza_armi: il giocatore parte senza armi, finché non trova il Lanciarune in una cassa
--   cassa = { dopo = 2, arma = "missile", x = 1250 }: fatto il passo dopo, quella
--     cassa cade lì (nelle lezioni la sua scheda ferma il gioco: battaglia/scheda.lua)
--   senza_tempo: niente tempo e niente turni, il turno è tuo finché non finisci.
--     Finito un attacco (o il Rampino, il Bastione) si riusa subito; se non ha
--     colpito nessuno né fatto un passo, "Ritenta" (conta "mancati"). Sergio, 29 ott:
--     in una lezione non si aspetta mai un turno per riprovare
--   regole: altre opts di game.new; secondi: durata della partita; globi: con
--     quanti teletrasporti parte il giocatore; vita, punti = { [robot] = n } all'inizio;
--     rigenera = { robot, ... }: a ogni turno tornano con la vita piena
--   obiettivo: i passi (sotto), in ordine se non c'è in_ordine = false
--   fallisce = { muori = true, esaurito = "paracadute" } (e sempre se la partita finisce prima)
--   turni: oltre questi turni del giocatore si ricomincia
--   stelle = { 3, 2 } (turni per la seconda e la terza) oppure
--     { turni = 3, bonus = { conta = "morti", al_massimo = 0, testo = "SENZA MORIRE" } } oppure
--     { bonus = { ... }, bonus2 = { ... } } (due bonus, senza turni: le partite vere)
--   collaudo = { carattere, piano, senza }: come la prova strumenti/arena/collaudo.lua
--   righe = { { testo, quando, fino, su = "bot", evidenzia, ferma, subito } }: quando
--     e fino sono { evento = "crate_pick" }, { passo = 2 } (fatto il passo 2),
--     { turno = 2 }, { tocca = "mira" } (il giocatore ha toccato quello, in questo
--     turno) oppure funzioni(st, g, e) per i casi che i dati non dicono (la partita
--     guidata). evidenzia: il comando che la riga suggerisce ("primaria",
--     "secondaria", un'arma, "teleport", "cammina", "salta", "mira", "annulla"): l'HUD lo mette in
--     luce e, nelle lezioni, il tempo resta fermo finché non lo tocchi (ferma =
--     false: solo la luce, per le righe che arrivano in aria). Nei gironi la luce
--     c'è ma il gioco non si ferma mai. subito: la riga prende il posto di quella
--     che c'è (la mira è già cominciata)
--
-- I passi dell'obiettivo (testo: come si legge nella riga dell'obiettivo):
--   { usa = "globi" | "rampino" | "bastione" | "rimbalzo" | "rinculo" | "paracadute" }
--   { raggiungi = { x = 1200, y = 150 }, bandiera = true }   in piedi sopra quella
--                                           quota, oltre quella x (bandiera: lì c'è la bandierina a scacchi)
--   { prendi = "missile" }                  raccogli la cassa con quell'arma
--   { colpisci = 2, con = "sword" | "primaria" | "secondaria" | un'arma }
--   { abbatti = 2 | "nemico", come = "vuoto", con = arma, volte = 3 }
--   { vinci = true }                        la partita finisce e la tua squadra ha vinto
-- Altri verbi (sopravvivi, proteggi...) entrano con le missioni che li usano.
-- I conteggi per i bonus delle stelle: morti, teletrasporti, vuoto (uccisioni
-- ambientali tue), abbattuti, danni (presi da te), mancati (senza_tempo).

local game = require "sim.game"
local maps = require "sim.maps"
local terrain = require "sim.terrain"
local campagna = require "sim.campagna"

local M = {}

local STEEL = terrain.STEEL
M.GIOCATORE = 1
local GIOCATORE = M.GIOCATORE
-- secondi di una riga che non ha un "fino": poi sparisce da sola
local RIGA_SECONDI = 5
-- senza_tempo: un attacco è finito quando niente vola e il giocatore è fermo da tanti tick
local MANCATO_TICK = 45
local RITENTA = "Ritenta! Prendi confidenza con i comandi, prenditi il tuo tempo: {mira}"

-- Quale arma ha appena usato chi: l'evento dell'attacco -> nome dell'arma
local ATTACCHI = {
	fire = "missile", grenade = "grenade", shards = "shards", punch = "punch", sniper = "sniper",
	swing = "sword", eagle = "eagle", mallet = "mallet", lunge = "lunge", bellows = "bellows",
}
-- gli eventi del giocatore che consumano l'attacco o l'attrezzo del turno
local TENTATIVI = { hook_shot = true, wall = true }
for k in pairs(ATTACCHI) do TENTATIVI[k] = true end
local CATEGORIE = {
	primaria = { grenade = true, shards = true, punch = true, sniper = true },
	secondaria = { eagle = true, mallet = true, lunge = true, bellows = true },
}
-- usa: l'evento del giocatore che dice che la meccanica è stata usata
local USA = {
	globi = function(e) return e.type == "teleports" and e.amount > 0 end,
	rampino = function(e) return e.type == "hook" and e.anchor end,
	bastione = function(e) return e.type == "wall" and e.v == 1 end,
	rimbalzo = function(e) return e.type == "mallet_hit" and e.bounce end,
	-- il Tonante sparato in aria: il rinculo porta via
	rinculo = function(e, st) return e.type == "eagle" and not st.a_terra end,
	paracadute = function(e) return e.type == "parachute" end,
}

-- Le missioni, per id e per capitolo --------------------------------------------------

local PER_ID, DOPO = {}, {}
for _, cap in ipairs(campagna.CAPITOLI) do
	for i, l in ipairs(cap.missioni) do
		assert(not PER_ID[l.id], "missione doppia: " .. l.id)
		PER_ID[l.id] = l
		l.capitolo = cap.id
		-- nelle lezioni il tempo aspetta che tocchi i comandi (capitolo.aspetta)
		l.aspetta = cap.aspetta
		DOPO[l.id] = cap.missioni[i + 1] and cap.missioni[i + 1].id
		if l.arena then
			l.mappa = "missione_" .. l.id
			maps.registra(l.mappa, { name = l.titolo, spawns = l.spawns, build = function(t)
				for _, q in ipairs(l.arena) do t:rect(q[1], q[2], q[3], q[4], STEEL) end
			end })
		end
	end
end

function M.trova(id)
	return PER_ID[id]
end

function M.dopo(id)
	return DOPO[id]
end

-- Quello che la missione fa vedere nell'HUD (l.vedi; senza, tutto)
local function categoria(w)
	if game.SECONDARY[w] then return "secondarie" end
	if game.TOOLS[w] or w == "teleport" then return nil end
	return "primarie"
end

-- Il comando toccato (cosa) è quello che la riga suggerisce (att)?
local function combacia(att, cosa)
	if att == cosa then return true end
	if not cosa or not game.WEAPONS[cosa] then return false end
	if att == "secondaria" then return game.SECONDARY[cosa] == true end
	if att == "primaria" then return not game.SECONDARY[cosa] and not game.TOOLS[cosa] end
	return false
end

-- In questo turno il giocatore ha già toccato quel comando (o uno della categoria)?
local function toccato(st, att)
	for cosa in pairs(st.toccati) do
		if combacia(att, cosa) then return true end
	end
	return false
end

function M.vede(r, w)
	local l = r and r.l
	if not l or not l.vedi then return true end
	if r.prese and r.prese[w] then return true end
	local c = categoria(w)
	for _, v in ipairs(l.vedi) do
		if v == w or v == c then return true end
	end
	return false
end

-- Lo stato di una missione in corso
function M.nuova(id)
	local l = assert(PER_ID[id], "missione sconosciuta: " .. tostring(id))
	return { l = l, st = { turni = 0, turni_bot = 0, passi = {}, volte = {}, conta = {}, toccati = {} },
		viste = {}, prese = {}, riga = nil, esito = nil }
end

-- seme, mappa e opzioni di game.new. picks: i giocatori usciti dal draft
-- (menu/scelta.lua), per le missioni che lo fanno fare
-- l'aiuto silenzioso: i bot scendono di un livello e partono con meno vita
local PIU_FACILE = { difficile = "normale", normale = "facile", facile = "facile" }
local AIUTO_VITA = 0.75

function M.partita(r, seed, picks, aiuto)
	local l = r.l
	local players = {}
	r.aiuto = aiuto
	for i, p in ipairs(l.giocatori) do
		local q = {}
		for k, v in pairs(p) do
			if k ~= "nome" and k ~= "battute" then q[k] = v end
		end
		if aiuto and q.bot then q.bot = PIU_FACILE[q.bot] end
		if picks and picks[i] then
			q.pick, q.secondary, q.tool = picks[i].pick, picks[i].secondary, picks[i].tool or q.tool
		end
		players[i] = q
	end
	if l.globi or l.vedi then
		local st = {}
		for k, v in pairs(players[GIOCATORE].stats or {}) do st[k] = v end
		st.teleports = l.globi or st.teleports
		-- quello che la lezione non mostra non c'è: niente globi (nemmeno dal
		-- tempo), niente paracadute
		if not M.vede(r, "teleport") then st.teleports, st.time_orbs = 0, 0 end
		if not M.vede(r, "parachute") then st.parachutes = 0 end
		players[GIOCATORE].stats = st
	end
	local opts = { players = players }
	for k, v in pairs(l.regole or {}) do opts[k] = v end
	-- senza casse: le missioni non cambiano col caso
	if not l.guidata and not opts.crate_every then opts.crate_every = 1000 end
	-- nelle lezioni niente cerchi di cura che spuntano a caso (Sergio, 29 ott)
	if l.aspetta then opts.heals = false end
	return seed or 1, l.mappa, opts
end

-- Dopo game.new: tempo della partita, vita e punti d'inizio, la prima riga.
-- Gli eventi dell'inizio (il primo turno) li conta qui e li scarta.
function M.prepara(r, g)
	local l, st = r.l, r.st
	if l.secondi then g.match_left = l.secondi * 60 end
	-- la vita della missione è anche quella piena: rigenera torna lì, non a 150
	for i, v in pairs(l.vita or {}) do
		g.robots[i].hp, g.robots[i].max_hp = v, v
	end
	if r.aiuto then
		for i, p in ipairs(l.giocatori) do
			-- anche la vita piena: la barra resta piena, non si vede
			local rb = g.robots[i]
			if p.bot then rb.hp = math.floor(rb.hp * AIUTO_VITA); rb.max_hp = rb.hp end
		end
	end
	for i, v in pairs(l.punti or {}) do g.robots[i].points = v end
	if l.senza_armi then g.robots[GIOCATORE].disarmed = true end
	g:pop_events()
	if g.current == GIOCATORE then st.turni = 1 else st.turni_bot = 1 end
	r.coda = {}
	r.riga = nil
	if l.aspetta then r.attesa, r.fermo = true, { timer = g.timer, window = g.window, match = g.match_left } end
	if l.senza_tempo then r.senza = { timer = g.timer, match = g.match_left } end
	-- lo scopo finché non si fa la prima cosa
	-- (nelle lezioni lascia il posto ai suggerimenti appena tocchi i comandi)
	if l.scopo then
		r.coda[1] = { testo = l.scopo, cede = l.aspetta, evidenzia = l.evidenzia,
			fino = function(_, g2) return g2.used.primary or g2.used.secondary or g2.used.tool end }
	end
end

-- I passi -----------------------------------------------------------------------------

local function nemici(g, a, b)
	return g.robots[a].team ~= g.robots[b].team
end

local function bersaglio(g, voluto, robot)
	if voluto == "nemico" then return nemici(g, GIOCATORE, robot) end
	return voluto == robot
end

local function arma_ok(con, arma)
	if not con then return true end
	if CATEGORIE[con] then return CATEGORIE[con][arma] == true end
	return con == arma
end

-- in piedi sopra la quota y, oltre la x
local function sopra(g, x, y)
	local rb = g.robots[GIOCATORE]
	return not rb.dead and rb.grounded and rb.x >= x and rb.y >= y - 1
end

-- Il passo p è fatto adesso? e = nil: il controllo a ogni tick
local function passo_fatto(p, i, st, g, e)
	if p.usa then
		return e ~= nil and e.robot == GIOCATORE and USA[p.usa](e, st)
	elseif p.raggiungi then
		return sopra(g, p.raggiungi.x, p.raggiungi.y)
	elseif p.colpisci then
		return e ~= nil and e.type == "damage" and e.amount > 0 and bersaglio(g, p.colpisci, e.robot)
			and arma_ok(p.con, st.arma)
	elseif p.prendi then
		return e ~= nil and e.type == "crate_pick" and e.robot == GIOCATORE and e.weapon == p.prendi
	elseif p.vinci then
		return e ~= nil and e.type == "over" and e.winner == g.robots[GIOCATORE].team
	elseif p.abbatti then
		if e and e.type == "death" and e.by == GIOCATORE and bersaglio(g, p.abbatti, e.robot)
			and (p.come ~= "vuoto" or e.env) and arma_ok(p.con, st.arma) then
			st.volte[i] = (st.volte[i] or 0) + 1
			return st.volte[i] >= (p.volte or 1)
		end
		return false
	end
	error("passo sconosciuto")
end

-- obiettivo fatto? Segna i passi che si chiudono con e
local function obiettivo(l, st, g, e)
	if type(l.obiettivo) == "function" then return l.obiettivo(st, g, e) end
	local tutti = true
	for i, p in ipairs(l.obiettivo) do
		if not st.passi[i] then
			if passo_fatto(p, i, st, g, e) then
				st.passi[i] = true
			else
				tutti = false
				if l.in_ordine ~= false then return false end
			end
		end
	end
	return tutti
end

-- Quanti passi sono fatti
local function fatti(st)
	local n = 0
	for _ in pairs(st.passi) do n = n + 1 end
	return n
end

-- Il primo passo che manca (o nil)
local function prossimo(l, st)
	if type(l.obiettivo) ~= "table" then return nil end
	for i, p in ipairs(l.obiettivo) do
		if not st.passi[i] then return i, p end
	end
end

-- Quando di una riga: funzione, o dati
local function quando(q, st, g, e)
	if type(q) == "function" then return q(st, g, e) end
	if q.evento then
		return e ~= nil and e.type == q.evento and (e.robot == nil or e.robot == GIOCATORE)
	elseif q.passo then
		return st.passi[q.passo] == true
	elseif q.turno then
		return st.turni == q.turno
	elseif q.tocca then
		return toccato(st, q.tocca)
	end
	return false
end

-- Una riga alla volta: quella nuova aspetta che l'altra sia fatta o scaduta
-- (o che cominci un altro turno).
-- Senza "fino" resta RIGA_SECONDI, con "fino" al massimo il doppio.
-- Una riga che evidenzia un comando, nelle lezioni, ferma il tempo finché non
-- lo tocchi (se non lo hai già toccato in questo turno).
local function mostra(r, riga)
	r.riga, r.riga_fino, r.riga_cede = riga.testo, riga.fino, riga.cede
	r.riga_su = riga.su == "bot" and 2 or GIOCATORE
	r.riga_t = (riga.fino and 2 or 1) * RIGA_SECONDI * 60
	r.luce = riga.evidenzia
	r.attende = nil
	local e = riga.evidenzia
	if e and r.l.aspetta and riga.ferma ~= false and not toccato(r.st, e) then
		r.attesa, r.attende = true, e
	end
end

-- La riga se ne va: se aspettava un comando, il tempo riparte
local function togli(r)
	if r.attende then r.attesa, r.attende, r.fermo = false, nil, nil end
	r.riga, r.riga_t, r.luce, r.riga_cede = nil, nil, nil, nil
end

-- e = nil: il controllo a ogni tick
local function controlla(r, g, e)
	local l, st = r.l, r.st
	if r.esito then return end
	if obiettivo(l, st, g, e) then
		r.esito = "fatta"
		-- i suggerimenti non servono più (c'è "Fatta!")
		togli(r)
		return
	end
	if r.riga and r.riga_fino and quando(r.riga_fino, st, g, e) then togli(r) end
	-- un turno nuovo: le righe del turno prima non servono più
	if e and e.type == "turn" then togli(r); r.coda = {} end
	for i, riga in ipairs(l.righe or {}) do
		if not r.viste[i] and quando(riga.quando, st, g, e) then
			r.viste[i] = true
			if riga.subito then
				togli(r)
				table.insert(r.coda, 1, riga)
			else
				r.coda[#r.coda + 1] = riga
			end
		end
	end
	-- lo scopo di una lezione, letto (hai toccato i comandi), lascia il posto
	if r.riga and r.riga_cede and not r.attesa and #r.coda > 0 then togli(r) end
	if not r.riga and #r.coda > 0 then mostra(r, table.remove(r.coda, 1)) end
end

local function conta(st, k)
	st.conta[k] = (st.conta[k] or 0) + 1
end

function M.evento(r, g, e, bots)
	local l, st = r.l, r.st
	if ATTACCHI[e.type] and e.robot == GIOCATORE then
		st.arma = ATTACCHI[e.type]
	end
	-- senza_tempo: un tentativo, finché non è finito; serve se colpisce qualcuno o fa un passo
	if l.senza_tempo and TENTATIVI[e.type] and e.robot == GIOCATORE and e.v ~= 0 and not r.tiro then
		r.tiro = { t = 0, passi = fatti(st) }
	end
	if e.type == "damage" and e.amount > 0 and r.tiro and e.robot ~= GIOCATORE then r.tiro.preso = true end
	if e.type == "crate_pick" and e.robot == GIOCATORE then r.prese[e.weapon] = true end
	if e.type == "turn" then
		if e.robot == GIOCATORE then st.turni = st.turni + 1 else st.turni_bot = st.turni_bot + 1 end
		st.toccati = {}
		-- il bot di turno fa vedere quello che il giocatore farà dopo (sim/bot.lua, b.piano)
		local b = bots and bots[e.robot]
		if b then b.piano = l.piani and l.piani[st.turni_bot] or nil end
		for _, i in ipairs(l.rigenera or {}) do
			local rb = g.robots[i]
			if not rb.dead then rb.hp = rb.max_hp end
		end
		-- oltre i turni della missione si ricomincia
		if l.turni and st.turni > l.turni and not r.esito then r.esito = "fallita" end
	elseif e.type == "teleport" and e.robot == GIOCATORE then
		conta(st, "teletrasporti")
	elseif e.type == "damage" and e.robot == GIOCATORE then
		st.conta.danni = (st.conta.danni or 0) + e.amount
	elseif e.type == "death" then
		if e.robot == GIOCATORE then conta(st, "morti") end
		if e.by == GIOCATORE and nemici(g, GIOCATORE, e.robot) then
			conta(st, "abbattuti")
			if e.env then conta(st, "vuoto") end
		end
	elseif e.type == "over" then
		st.finita, st.vinta = true, e.winner == g.robots[GIOCATORE].team
		local me, altri = g.robots[GIOCATORE].points, 0
		for i, rb in ipairs(g.robots) do
			if i ~= GIOCATORE then altri = math.max(altri, rb.points) end
		end
		st.distacco = me - altri
	end
	controlla(r, g, e)
	if r.esito then return end
	-- lezioni: a ogni tuo turno e quando rinasci l'obiettivo si riscrive e il
	-- tempo aspetta che tocchi i comandi, così c'è il tempo di leggere
	if l.aspetta and e.robot == GIOCATORE and (e.type == "turn" or e.type == "respawn") then
		r.attesa, r.fermo = true, { timer = g.timer, window = g.window, match = g.match_left }
		local testo = l.scopo
		local i, p = prossimo(l, st)
		if i and i > 1 then testo = p.testo end
		-- (se il turno non ha già la sua riga da dire)
		if testo and not r.riga then mostra(r, { testo = testo, cede = true }) end
	end
	local f = l.fallisce or {}
	if (f.muori and e.type == "death" and e.robot == GIOCATORE) or (e.type == "over" and not l.guidata) then
		r.esito = "fallita"
	end
end

-- Il giocatore ha toccato i comandi (cosa: l'arma scelta, "salta", "mira",
-- "annulla" o nil): il tempo riparte, ma se la riga aspetta un comando solo
-- quando tocchi quello
function M.tocca(r, cosa)
	if not r then return end
	if cosa then r.st.toccati[cosa] = true end
	if r.attende then
		if not combacia(r.attende, cosa) then return end
		-- fatto: la luce si spegne, la riga resta finché serve
		r.attende, r.luce = nil, nil
	end
	r.attesa, r.fermo = false, nil
end

-- Il comando da mettere in luce, finché la sua riga è in vista
function M.evidenzia(r)
	return r.riga and r.luce or nil
end

-- senza_tempo: il tempo non passa e il turno non finisce. Finito un
-- tentativo si riusa tutto; se non è servito a niente, Ritenta
local function senza_tempo(r, g)
	local f = r.senza
	g.timer, g.match_left, g.window = f.timer, f.match, 0
	local t = r.tiro
	if not t or r.esito then return end
	local rb = g.robots[GIOCATORE]
	local fermo = not (g.projectile or g:shards_flying() or #g.orbs > 0) and (rb.dead or rb.grounded
		and not (rb.hooked or rb.hook_shot or rb.swing or rb.punch or rb.lunge or rb.mallet or rb.recoil))
	t.t = fermo and t.t + 1 or 0
	if t.t < MANCATO_TICK then return end
	r.tiro = nil
	g.used.primary, g.used.secondary, g.used.tool = false, false, false
	if not t.preso and fatti(r.st) == t.passi then
		conta(r.st, "mancati")
		togli(r)
		mostra(r, { testo = RITENTA })
	end
end

-- La bandierina a scacchi del passo da fare (raggiungi con bandiera), o nil
function M.bandiera(r)
	local _, p = prossimo(r.l, r.st)
	if p and p.raggiungi and p.bandiera then return p.raggiungi.x, p.raggiungi.y end
end

function M.tick(r, g)
	local l, st = r.l, r.st
	if l.senza_tempo and g.current == GIOCATORE then senza_tempo(r, g) end
	-- la cassa della lezione cade, fatto il suo passo
	local c = l.cassa
	if c and not r.cassa and st.passi[c.dopo] then r.cassa = g:spawn_crate(c.arma, c.x) or true end
	-- lezioni: finché non tocchi i comandi il tempo del turno e della partita è fermo
	if r.attesa and g.current == GIOCATORE then
		r.fermo = r.fermo or { timer = g.timer, window = g.window, match = g.match_left }
		local f = r.fermo
		g.timer, g.window, g.match_left = f.timer, f.window, f.match
	end
	controlla(r, g, nil)
	-- a terra o no prima degli eventi del prossimo tick (il Tonante stacca da terra)
	st.a_terra = g.robots[GIOCATORE].grounded
	-- esaurito: la risorsa è finita, sei a terra e il posto da raggiungere no
	local f = l.fallisce
	if not r.esito and f and f.esaurito == "paracadute" then
		local rb = g.robots[GIOCATORE]
		local _, p = prossimo(l, st)
		if rb.grounded and rb.parachutes_left == 0 and p and p.raggiungi then r.esito = "fallita" end
	end
	if r.riga_t and not r.attesa then
		r.riga_t = r.riga_t - 1
		if r.riga_t <= 0 then togli(r) end
	end
	return r.esito
end

-- La riga da mostrare e sopra chi (il robot), o nil
function M.riga(r)
	return r.riga, r.riga_su
end

-- L'obiettivo sempre in vista: il passo che manca, col numero se sono più d'uno
function M.obiettivo(r)
	local l = r.l
	local i, p = prossimo(l, r.st)
	if not i or r.esito then return nil end
	local n = #l.obiettivo
	return n > 1 and (i .. "/" .. n .. "  " .. p.testo) or p.testo
end

local function turni(n)
	return "IN " .. n .. (n == 1 and " TURNO" or " TURNI")
end

-- Cosa serve per ogni stella
function M.criteri(l)
	if l.guidata then return { "FINITA", "VINTA", "CON 100 PUNTI DI VANTAGGIO" } end
	local s = l.stelle
	if s.bonus2 then return { "FATTA", s.bonus.testo, s.bonus2.testo } end
	if s.bonus then return { "FATTA", turni(s.turni), s.bonus.testo } end
	return { "FATTA", turni(s[1]), turni(s[2]) }
end

local function bonus(b, st)
	local n = st.conta[b.conta] or 0
	if b.al_massimo then return n <= b.al_massimo end
	return n >= b.almeno
end

-- Stelle: una per averla fatta, poi i turni e il bonus (o due soglie di
-- turni). Nella partita guidata: finita, vinta, vinta con 100 punti di distacco.
function M.stelle(r)
	if r.esito ~= "fatta" then return { false, false, false } end
	local l, st = r.l, r.st
	if l.guidata then
		return { true, st.vinta == true, st.vinta == true and st.distacco >= 100 }
	end
	local s = l.stelle
	if s.bonus2 then return { true, bonus(s.bonus, st), bonus(s.bonus2, st) } end
	if s.bonus then
		-- il bonus vale da solo: si può avere la terza senza la seconda
		return { true, st.turni <= s.turni, bonus(s.bonus, st) }
	end
	return { true, st.turni <= s[1], st.turni <= s[2] }
end

function M.quante(stelle)
	local n = 0
	for i = 1, 3 do
		if stelle[i] then n = n + 1 end
	end
	return n
end

return M
