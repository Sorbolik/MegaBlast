-- Missioni: le lezioni (Capitolo 0) e i gironi della campagna (sim/campaign.lua),
-- tutte nello stesso formato. Una missione è una partita vera con un obiettivo
-- scritto come dati: pochi verbi (sotto) invece di codice, così un giorno le
-- manda il server e servono anche al rompicapo del giorno (docs/roadmap.md,
-- area 3). Lua puro: il gui_script mostra la riga, l'obiettivo e le stelle.
--
--   local r = missioni.nuova("attrezzi")
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
--   local i = missioni.bersaglio(r)                 -- nelle lezioni, il robot da colpire adesso (o nil)
--   local w = missioni.scheda(r)                    -- la scheda d'arma da aprire adesso (una volta), o nil
--   local z = missioni.zoom(r)                      -- il livello della camera che il passo vuole (una volta), o nil
--   local testo, chi = missioni.riga(r)             -- il suggerimento da mostrare sopra il robot chi (o nil)
--   local testo = missioni.obiettivo(r)             -- l'obiettivo che resta, sempre in vista (o nil)
--   missioni.stelle(r)                              -- { true, false, true }: ogni stella col suo criterio
--   missioni.quante(stelle)                         -- quante sono accese
--   missioni.criteri(l)                             -- cosa serve per ogni stella: { "FATTA", "CON 60 PUNTI DI VANTAGGIO", ... }
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
--     dal tempo; "parachute"; "tempo": il cronometro; "punti": i punteggi; "baratto": il secondo
--     attacco scambiato con un teletrasporto): il
--     resto non c'è nemmeno. L'interfaccia si scopre a poco a poco (Sergio, 29 ott):
--     senza vedi si vede tutto, con vedi il cronometro e i punti solo se ci sono.
--     Senza "punti" i punti non ci sono proprio (Sergio, 31 ott: distraggono
--     dall'esercizio): nessuno ne fa, niente Corona.
--     Un'arma raccolta da una cassa si vede da lì in poi
--   senza_armi: il giocatore parte senza armi, finché non trova il Lanciarune in una cassa
--   casse = { { dopo = 2, arma = "missile", x = 1250 }, ... }: fatto il passo dopo
--     (0: subito), quella cassa cade lì (la scheda di un'arma nuova ferma il gioco:
--     battaglia/scheda.lua). Nelle lezioni un'arma a colpi trovata lì torna quando la si può riusare
--   schede = { { dopo = 1, arma = "sword", dai = true } }: fatto il passo dopo si apre
--     la scheda di quell'arma; dai: e la si ha, senza cassa (Sergio, 30 ott: il
--     Rampino e il paracadute non si trovano nelle casse)
--   senza_tempo: niente tempo e niente turni, il turno è tuo finché non finisci.
--     Finito un attacco (o il Rampino) si riusa subito; se non ha
--     colpito nessuno né fatto un passo, "Ritenta" (conta "mancati"). Sergio, 29 ott:
--     in una lezione non si aspetta mai un turno per riprovare. Il paracadute
--     trovato torna appena sei a terra
--   Nelle lezioni (non nella Prima partita) la prossima azione è quasi forzata
--   (Sergio, 30 ott): si usa solo quello che il passo dice (solo, sotto); se il
--   tempo sta per finire si ferma a un secondo finché non lo fai; un colpo a
--   vuoto si ridà subito (con tempo: si torna dove eri quando hai colpito);
--   chi cade rinasce com'era all'ultimo passo fatto, globi compresi (i bersagli
--   dove sono partiti; quello abbattuto che non serve più a nessun passo resta
--   giù); se il passo si fa solo coi globi e non ne hai più, Ritenta e torni com'eri.
--   Le schede (sotto) si aprono quando il colpo del passo è arrivato
--   regole: altre opts di game.new; secondi: durata della partita; globi: con
--     quanti teletrasporti parte il giocatore; vita, punti = { [robot] = n } all'inizio;
--     rigenera = { robot, ... }: a ogni turno tornano con la vita piena
--   obiettivo: i passi (sotto), in ordine se non c'è in_ordine = false
--   la missione fallisce se la partita finisce prima
--   turni: oltre questi turni del giocatore si ricomincia
--   stelle = { punti = 60, bonus = { conta = "morti", al_massimo = 0, testo = "SENZA MORIRE" } }
--     (la seconda con almeno quei punti di vantaggio sugli avversari alla fine:
--     i gironi, dove i punti contano; Sergio, 31 ott: non più i turni) oppure
--     { bonus = { ... }, bonus2 = { ... } } (due bonus: le lezioni)
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
-- I passi dell'obiettivo (testo: come si legge nella riga dell'obiettivo). In
-- più, nelle lezioni: solo = { "sword", "teleport", "baratto", "primaria", ... }:
-- finché il passo manca si usa solo quello; zoom = 2: la camera si allarga a
-- quel livello (battaglia/camera.lua); globi = 2 (con usa = "globi"): il
-- tempo si ferma dove si prendono ancora quei globi
--   { usa = "globi" | "rampino" | "rimbalzo" | "rinculo" | "paracadute" | "baratto" }
--   { raggiungi = { x = 1200, y = 150 }, bandiera = true }   in piedi sopra quella
--                                           quota, oltre quella x (bandiera: lì c'è la bandierina a scacchi)
--   { prendi = "missile" }                  raccogli la cassa con quell'arma
--   { colpisci = 2, con = "sword" | "primaria" | "secondaria" | un'arma }
--   { abbatti = 2 | "nemico", come = "vuoto", con = arma, volte = 3 }
--   { vinci = true }                        la partita finisce e la tua squadra ha vinto
-- Altri verbi (sopravvivi, proteggi...) entrano con le missioni che li usano.
-- I conteggi per i bonus delle stelle: morti, teletrasporti, vuoto (uccisioni
-- ambientali tue), abbattuti, danni (presi da te), mancati (senza_tempo), globi (guadagnati).

local game = require "sim.game"
local config = require "sim.config"
local maps = require "sim.maps"
local terrain = require "sim.terrain"
local campaign = require "sim.campaign"

local M = {}

local STEEL = terrain.STEEL
M.GIOCATORE = 1
local PLAYER = M.GIOCATORE
-- secondi di una riga che non ha un "fino": poi sparisce da sola
local LINE_SECONDS = 5
-- senza_tempo: un attacco è finito quando niente vola e il giocatore è fermo da tanti tick
local MISS_TICK = 45
-- la scheda di un'arma si apre questi tick dopo che il colpo del passo è arrivato
local CARD_DELAY = 24
-- da quanto sopra il terreno cadono le casse delle missioni
local CRATE_ABOVE = 280
-- la terza stella della Prima partita: vinta con almeno tanti punti di vantaggio
local GUIDED_POINTS = 100
local RETRY_TEXT = "Ritenta! Prendi confidenza con i comandi, prenditi il tuo tempo: {mira}"

-- Quale arma ha appena usato chi: l'evento dell'attacco -> nome dell'arma
local ATTACKS = {
	fire = "missile", grenade = "grenade", shards = "shards", punch = "punch", sniper = "sniper",
	swing = "sword", eagle = "eagle", mallet = "mallet", lunge = "lunge", bellows = "bellows",
}
-- gli eventi del giocatore che consumano l'attacco o il Rampino del turno
local ATTEMPTS = { hook_shot = true }
for k in pairs(ATTACKS) do ATTEMPTS[k] = true end
local CATEGORIES = {
	primaria = { grenade = true, shards = true, punch = true, sniper = true },
	secondaria = { eagle = true, mallet = true, lunge = true, bellows = true },
}
-- usa: l'evento del giocatore che dice che la meccanica è stata usata
local USES = {
	globi = function(e) return e.type == "teleports" and e.amount > 0 end,
	rampino = function(e) return e.type == "hook" and e.anchor end,
	pogo = function(e) return e.type == "mallet_hit" and e.bounce end,
	-- il Tonante sparato in aria: il rinculo porta via
	kickback = function(e, st) return e.type == "eagle" and not st.on_ground end,
	paracadute = function(e) return e.type == "parachute" end,
	baratto = function(e) return e.type == "swap" end,
}

-- solo = { ... } di un passo -> la funzione che dice se un comando si può usare
-- (game.permesso). Camminare e saltare si può sempre
local function allowed_fn(only)
	local ok = {}
	for _, w in ipairs(only) do ok[w == "baratto" and "swap" or w] = true end
	return function(w)
		if ok[w] then return true end
		if game.SECONDARY[w] then return ok.secondaria == true end
		return ok.primaria == true and not game.TOOLS[w] and w ~= "teleport" and w ~= "swap"
	end
end

-- Le missioni, per id e per capitolo --------------------------------------------------

local PER_ID, NEXT_ID = {}, {}
for _, cap in ipairs(campaign.CAPITOLI) do
	for i, l in ipairs(cap.missioni) do
		assert(not PER_ID[l.id], "missione doppia: " .. l.id)
		PER_ID[l.id] = l
		l.capitolo = cap.id
		-- nelle lezioni il tempo aspetta che tocchi i comandi (capitolo.aspetta)
		l.aspetta = cap.aspetta
		-- la prossima azione quasi forzata: le lezioni, non la Prima partita
		l.riprova = l.aspetta and not l.guidata
		if type(l.obiettivo) == "table" then
			for _, p in ipairs(l.obiettivo) do
				if p.solo then p.permesso = allowed_fn(p.solo) end
			end
		end
		NEXT_ID[l.id] = cap.missioni[i + 1] and cap.missioni[i + 1].id
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
	return NEXT_ID[id]
end

-- Quello che la missione fa vedere nell'HUD (l.vedi; senza, tutto)
local function category(w)
	if game.SECONDARY[w] then return "secondarie" end
	if game.TOOLS[w] or w == "teleport" then return nil end
	return "primarie"
end

-- Il comando toccato (cosa) è quello che la riga suggerisce (att)?
local function matches_hint(att, what)
	if att == what then return true end
	if not what or not game.WEAPONS[what] then return false end
	if att == "secondaria" then return game.SECONDARY[what] == true end
	if att == "primaria" then return not game.SECONDARY[what] and not game.TOOLS[what] end
	return false
end

-- In questo turno il giocatore ha già toccato quel comando (o uno della categoria)?
local function touched_cmd(st, att)
	for what in pairs(st.touched_cmds) do
		if matches_hint(att, what) then return true end
	end
	return false
end

function M.vede(r, w)
	local l = r and r.l
	if not l or not l.vedi then return true end
	if r.prese and r.prese[w] then return true end
	local c = category(w)
	for _, v in ipairs(l.vedi) do
		if v == w or v == c then return true end
	end
	return false
end

-- Lo stato di una missione in corso
function M.nuova(id)
	local l = assert(PER_ID[id], "missione sconosciuta: " .. tostring(id))
	return { l = l, st = { turni = 0, turni_bot = 0, passi = {}, volte = {}, conta = {}, touched_cmds = {} },
		viste = {}, prese = {}, cadute = {}, aperte = {}, waits = {}, schede = {}, giu = {}, riga = nil, esito = nil }
end

-- seme, mappa e opzioni di game.new. picks: i giocatori usciti dal draft
-- (menu/scelta.lua), per le missioni che lo fanno fare
-- l'aiuto silenzioso: i bot scendono di due gradi (sim/bot.lua M.GRADI) e partono con meno vita
local HELP_HP = 0.75

function M.partita(r, seed, picks, aiuto)
	local l = r.l
	local players = {}
	r.aiuto = aiuto
	for i, p in ipairs(l.giocatori) do
		local q = {}
		for k, v in pairs(p) do
			if k ~= "nome" and k ~= "battute" then q[k] = v end
		end
		if aiuto and q.bot then q.bot = math.max(1, q.bot - 2) end
		if picks and picks[i] then
			q.pick, q.secondary = picks[i].pick, picks[i].secondary
		end
		players[i] = q
	end
	if l.globi or l.vedi then
		local st = {}
		for k, v in pairs(players[PLAYER].stats or {}) do st[k] = v end
		st.teleports = l.globi or st.teleports
		-- quello che la lezione non mostra non c'è: niente globi (nemmeno dal
		-- tempo), niente paracadute
		if not M.vede(r, "teleport") then st.teleports, st.time_orbs = 0, 0 end
		if not M.vede(r, "parachute") then st.parachutes = 0 end
		players[PLAYER].stats = st
	end
	local opts = { players = players }
	for k, v in pairs(l.regole or {}) do opts[k] = v end
	-- senza casse: le missioni non cambiano col caso
	if not l.guidata and not opts.crate_every then opts.crate_every = 1000 end
	-- nelle lezioni niente cerchi di cura che spuntano a caso (Sergio, 29 ott)
	if l.aspetta then opts.heals = false end
	-- e niente punti dove la lezione non ne parla (Sergio, 31 ott)
	if not M.vede(r, "punti") then opts.score = false end
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
			if p.bot then rb.hp = math.floor(rb.hp * HELP_HP); rb.max_hp = rb.hp end
		end
	end
	for i, v in pairs(l.punti or {}) do g.robots[i].points = v end
	-- chi parte coi punti della missione ha già la Corona (di solito arriva dopo
	-- SCORE.crown_rounds giri): la lezione Punti e Corona la fa colpire subito
	if l.punti then g.round = math.max(g.round, (g.score.crown_rounds or 0) + 1) end
	if l.no_weapons then g.robots[PLAYER].disarmed = true end
	g:pop_events()
	if g.current == PLAYER then st.turni = 1 else st.turni_bot = 1 end
	r.coda = {}
	r.riga = nil
	if l.aspetta then r.attesa, r.fermo = true, { timer = g.timer, window = g.window, match = g.match_left } end
	if l.senza_tempo then r.senza = { timer = g.timer, match = g.match_left } end
	-- lo scopo finché non si fa la prima cosa
	-- (nelle lezioni lascia il posto ai suggerimenti appena tocchi i comandi)
	if l.goal_text then
		r.coda[1] = { testo = l.goal_text, yields = l.aspetta, evidenzia = l.evidenzia,
			fino = function(_, g2) return g2.used.primary or g2.used.secondary or g2.used.tool end }
	end
end

-- I passi -----------------------------------------------------------------------------

local function enemies_list(g, a, b)
	return g.robots[a].team ~= g.robots[b].team
end

-- I punti della squadra del giocatore meno quelli della squadra avversaria più avanti
local function lead(g)
	local team_points_of = {}
	for _, rb in ipairs(g.robots) do team_points_of[rb.team] = (team_points_of[rb.team] or 0) + rb.points end
	local my_team, others = g.robots[PLAYER].team, nil
	for t = 1, #g.robots do
		if t ~= my_team and team_points_of[t] and (not others or team_points_of[t] > others) then others = team_points_of[t] end
	end
	return team_points_of[my_team] - (others or 0)
end

local function target(g, wanted, robot)
	if wanted == "nemico" then return enemies_list(g, PLAYER, robot) end
	return wanted == robot
end

local function weapon_ok(with_weapon, weapon_name)
	if not with_weapon then return true end
	if CATEGORIES[with_weapon] then return CATEGORIES[with_weapon][weapon_name] == true end
	return with_weapon == weapon_name
end

-- in piedi sopra la quota y, oltre la x
local function over_it(g, x, y)
	local rb = g.robots[PLAYER]
	return not rb.dead and rb.grounded and rb.x >= x and rb.y >= y - 1
end

-- Il passo p è fatto adesso? e = nil: il controllo a ogni tick
local function step_done(p, i, st, g, e)
	if p.usa then
		return e ~= nil and e.robot == PLAYER and USES[p.usa](e, st)
	elseif p.reach then
		return over_it(g, p.reach.x, p.reach.y)
	elseif p.hit then
		return e ~= nil and e.type == "damage" and e.amount > 0 and target(g, p.hit, e.robot)
			and weapon_ok(p.con, st.arma)
	elseif p.prendi then
		return e ~= nil and e.type == "crate_pick" and e.robot == PLAYER and e.weapon == p.prendi
	elseif p.win then
		return e ~= nil and e.type == "over" and e.winner == g.robots[PLAYER].team
	elseif p.down then
		if e and e.type == "death" and e.by == PLAYER and target(g, p.down, e.robot)
			and (p.come ~= "vuoto" or e.env) and weapon_ok(p.con, st.arma) then
			st.volte[i] = (st.volte[i] or 0) + 1
			return st.volte[i] >= (p.volte or 1)
		end
		return false
	end
	error("passo sconosciuto")
end

-- obiettivo fatto? Segna i passi che si chiudono con e
local function goal(l, st, g, e)
	if type(l.obiettivo) == "function" then return l.obiettivo(st, g, e) end
	local all_done = true
	for i, p in ipairs(l.obiettivo) do
		if not st.passi[i] then
			if step_done(p, i, st, g, e) then
				st.passi[i] = true
			else
				all_done = false
				if l.in_order ~= false then return false end
			end
		end
	end
	return all_done
end

-- Quanti passi sono fatti
local function steps_count(st)
	local n = 0
	for _ in pairs(st.passi) do n = n + 1 end
	return n
end

-- Il primo passo che manca (o nil)
local function next_one(l, st)
	if type(l.obiettivo) ~= "table" then return nil end
	for i, p in ipairs(l.obiettivo) do
		if not st.passi[i] then return i, p end
	end
end

-- Quando di una riga: funzione, o dati
local function when(q, st, g, e)
	if type(q) == "function" then return q(st, g, e) end
	if q.evento then
		return e ~= nil and e.type == q.evento and (e.robot == nil or e.robot == PLAYER)
	elseif q.passo then
		return st.passi[q.passo] == true
	elseif q.turno then
		return st.turni == q.turno
	elseif q.tocca then
		return touched_cmd(st, q.tocca)
	end
	return false
end

-- Una riga alla volta: quella nuova aspetta che l'altra sia fatta o scaduta
-- (o che cominci un altro turno).
-- Senza "fino" resta RIGA_SECONDI, con "fino" al massimo il doppio.
-- Una riga che evidenzia un comando, nelle lezioni, ferma il tempo finché non
-- lo tocchi (se non lo hai già toccato in questo turno).
local function show_line(r, line)
	r.riga, r.line_until, r.line_yields = line.testo, line.fino, line.yields
	r.line_on = line.su == "bot" and 2 or PLAYER
	r.riga_t = (line.fino and 2 or 1) * LINE_SECONDS * 60
	r.luce = line.evidenzia
	r.attende = nil
	local e = line.evidenzia
	if e and r.l.aspetta and line.ferma ~= false and not touched_cmd(r.st, e) then
		r.attesa, r.attende = true, e
	end
end

-- La riga se ne va: se aspettava un comando, il tempo riparte
local function clear_line(r)
	if r.attende then r.attesa, r.attende, r.fermo = false, nil, nil end
	r.riga, r.riga_t, r.luce, r.line_yields = nil, nil, nil, nil
end

-- e = nil: il controllo a ogni tick
local function check_event(r, g, e)
	local l, st = r.l, r.st
	if r.esito then return end
	if goal(l, st, g, e) then
		r.esito = "fatta"
		-- i suggerimenti non servono più (c'è "Fatta!")
		clear_line(r)
		return
	end
	if r.riga and r.line_until and when(r.line_until, st, g, e) then clear_line(r) end
	-- un turno nuovo: le righe del turno prima non servono più
	if e and e.type == "turn" then clear_line(r); r.coda = {} end
	for i, line in ipairs(l.righe or {}) do
		if not r.viste[i] and when(line.quando, st, g, e) then
			r.viste[i] = true
			if line.subito then
				clear_line(r)
				table.insert(r.coda, 1, line)
			else
				r.coda[#r.coda + 1] = line
			end
		end
	end
	-- lo scopo di una lezione, letto (hai toccato i comandi), lascia il posto
	if r.riga and r.line_yields and not r.attesa and #r.coda > 0 then clear_line(r) end
	if not r.riga and #r.coda > 0 then show_line(r, table.remove(r.coda, 1)) end
end

local function count(st, k)
	st.conta[k] = (st.conta[k] or 0) + 1
end

-- Quanto è avanti l'obiettivo: i passi fatti e le volte contate
local function forward(st)
	local n = steps_count(st)
	for _, v in pairs(st.volte) do n = n + v end
	return n
end

-- Manca un passo da abbattere?
local function needs_down(l, st)
	for i, p in ipairs(l.obiettivo) do
		if not st.passi[i] and p.down then return true end
	end
	return false
end

-- Un passo che manca deve ancora colpire o abbattere quel robot? (per "nemico",
-- solo se non resta nessun altro nemico in piedi)
local function needs(l, st, g, robot)
	for i, p in ipairs(l.obiettivo) do
		local who_hit = not st.passi[i] and (p.hit or p.down)
		if who_hit == robot then return true end
		if who_hit == "nemico" then
			local others = false
			for j, rb in ipairs(g.robots) do
				if j ~= robot and not rb.dead and enemies_list(g, PLAYER, j) then others = true end
			end
			if not others then return true end
		end
	end
	return false
end

-- Lezioni: torna com'eri all'ultimo passo fatto (r.salvo): dove eri e i globi
-- che avevi, così un globo sprecato non lascia senza la mossa che serve
local function restore_snapshot(r, g)
	local rb, s = g.robots[PLAYER], r.salvo
	if not rb.dead then rb.x, rb.y, rb.vx, rb.vy = s.x, s.y, 0, 0 end
	rb.teleports_left = math.max(rb.teleports_left, s.globi)
	if r.st.turni == s.turno then g.teleports = math.min(g.teleports, s.thrown) end
end

function M.evento(r, g, e, bots)
	local l, st = r.l, r.st
	if ATTACKS[e.type] and e.robot == PLAYER then
		st.arma = ATTACKS[e.type]
	end
	-- lezioni: un tentativo, finché non è finito; serve se colpisce qualcuno o fa un passo
	if l.riprova and ATTEMPTS[e.type] and e.robot == PLAYER and e.v ~= 0 and not r.shot then
		local rb = g.robots[PLAYER]
		r.shot = { t = 0, passi = steps_count(st), tipo = e.type, x = rb.x, y = rb.y }
	end
	if e.type == "damage" and e.amount > 0 and r.shot and e.robot ~= PLAYER then r.shot.preso = true end
	if e.type == "crate_pick" and e.robot == PLAYER then r.prese[e.weapon] = true end
	if e.type == "turn" then
		if e.robot == PLAYER then st.turni = st.turni + 1 else st.turni_bot = st.turni_bot + 1 end
		st.touched_cmds = {}
		-- il bot di turno fa vedere quello che il giocatore farà dopo (sim/bot.lua, b.piano)
		local b = bots and bots[e.robot]
		if b then b.piano = l.piani and l.piani[st.turni_bot] or nil end
		for _, i in ipairs(l.regrow or {}) do
			local rb = g.robots[i]
			if not rb.dead then rb.hp = rb.max_hp end
		end
		-- oltre i turni della missione si ricomincia
		if l.turni and st.turni > l.turni and not r.esito then r.esito = "fallita" end
	elseif e.type == "teleport" and e.robot == PLAYER then
		count(st, "teletrasporti")
	elseif e.type == "teleports" and e.robot == PLAYER then
		st.conta.globi = (st.conta.globi or 0) + e.amount
	elseif e.type == "respawn" and l.riprova and e.robot == PLAYER and r.salvo then
		-- nelle lezioni chi gioca rinasce com'era all'ultimo passo fatto, globi compresi
		restore_snapshot(r, g)
	elseif e.type == "respawn" and l.riprova and l.spawns and l.spawns[e.robot] then
		-- nelle lezioni si rinasce dove si è partiti, non in un posto a caso
		-- dell'arena (un bersaglio a caso finirebbe in mezzo alla strada)
		local rb, sp = g.robots[e.robot], l.spawns[e.robot]
		rb.x, rb.y = sp.x, g.terrain:ground_below(sp.x, sp.from) or rb.y
	elseif e.type == "damage" and e.robot == PLAYER then
		st.conta.danni = (st.conta.danni or 0) + e.amount
	elseif e.type == "death" then
		if e.robot == PLAYER then count(st, "morti") end
		if e.by == PLAYER and enemies_list(g, PLAYER, e.robot) then
			count(st, "abbattuti")
			if e.env then count(st, "vuoto") end
		end
	elseif e.type == "over" then
		st.finished, st.vinta = true, e.winner == g.robots[PLAYER].team
	end
	if e.type == "points" or e.type == "over" then st.distacco = lead(g) end
	local first_one = forward(st)
	check_event(r, g, e)
	-- lezioni e bersagli fermi: abbattuto da te, se non serve più resta giù
	-- (Sergio, 30 ott: l'isola del Il turno, i bersagli di Giù dal bordo). Se
	-- c'è da abbattere, solo se è contato (buttato nel vuoto): se no torna al suo posto
	local frozen = l.giocatori[e.robot] and l.giocatori[e.robot].dummy
	if e.type == "death" and (l.riprova or frozen) and e.by == PLAYER and e.robot ~= PLAYER
		and not needs(l, st, g, e.robot) and (forward(st) > first_one or not needs_down(l, st)) then
		r.giu[e.robot] = true
	end
	if r.esito then return end
	-- lezioni: a ogni tuo turno e quando rinasci l'obiettivo si riscrive e il
	-- tempo aspetta che tocchi i comandi, così c'è il tempo di leggere
	if l.aspetta and e.robot == PLAYER and (e.type == "turn" or e.type == "respawn") then
		r.attesa, r.fermo = true, { timer = g.timer, window = g.window, match = g.match_left }
		local testo = l.goal_text
		local i, p = next_one(l, st)
		if i and i > 1 then testo = p.testo end
		-- (se il turno non ha già la sua riga da dire)
		if testo and not r.riga then show_line(r, { testo = testo, yields = true }) end
	end
	if e.type == "over" and not l.guidata then
		r.esito = "fallita"
	end
end

-- Il giocatore ha toccato i comandi (cosa: l'arma scelta, "salta", "mira",
-- "annulla" o nil): il tempo riparte, ma se la riga aspetta un comando solo
-- quando tocchi quello
function M.tocca(r, what)
	if not r then return end
	if what then r.st.touched_cmds[what] = true end
	if r.attende then
		if not matches_hint(r.attende, what) then return end
		-- fatto: la luce si spegne, la riga resta finché serve
		r.attende, r.luce = nil, nil
	end
	r.attesa, r.fermo = false, nil
end

-- Il comando da mettere in luce, finché la sua riga è in vista
function M.evidenzia(r)
	return r.riga and r.luce or nil
end

-- senza_tempo: il tempo non passa e il turno non finisce
local function senza_tempo(r, g)
	local f = r.senza
	g.timer, g.match_left, g.window = f.timer, f.match, 0
	local rb = g.robots[PLAYER]
	-- il paracadute trovato torna appena sei a terra: si riprova quanto serve
	if r.prese.parachute and rb.grounded and not rb.parachute and rb.parachutes_left == 0 then
		rb.parachutes_left = 1
	end
end

-- Lezioni: finito un tentativo, senza tempo si riusa tutto; se non è servito a
-- niente, Ritenta (e col tempo quel colpo torna, e tu dov'eri quando l'hai tirato)
local function attempt_over(r, g)
	local t = r.shot
	if not t or r.esito then return end
	local rb = g.robots[PLAYER]
	local frozen = not (g.projectile or g:shards_flying() or #g.orbs > 0) and (rb.dead or rb.grounded
		and not (rb.hooked or rb.hook_shot or rb.swing or rb.punch or rb.lunge or rb.mallet or rb.recoil))
	t.t = frozen and t.t + 1 or 0
	if t.t < MISS_TICK then return end
	r.shot = nil
	local missed = not t.preso and steps_count(r.st) == t.passi
	if r.l.senza_tempo then
		g.used.primary, g.used.secondary, g.used.tool = false, false, false
	elseif missed then
		if not ATTACKS[t.tipo] then
			g.used.tool = false
		elseif game.SECONDARY[ATTACKS[t.tipo]] then
			g.used.secondary = false
		else
			g.used.primary = false
		end
		if not (g.used.primary or g.used.secondary) then g.window = 0 end
		if not rb.dead then rb.x, rb.y, rb.vx, rb.vy = t.x, t.y, 0, 0 end
	end
	if missed then
		count(r.st, "misses")
		clear_line(r)
		show_line(r, { testo = RETRY_TEXT })
	end
end

-- Lezioni: fatto un passo, a terra e fermo, chi gioca si segna com'è (r.salvo:
-- ci torna se cade o resta senza la mossa che serve). Se il passo si fa solo
-- coi globi e non ce ne sono più, Ritenta e torna com'era
local function hold_still(r, g, p)
	local rb = g.robots[PLAYER]
	local flying = g.projectile or g:shards_flying() or #g.orbs > 0
	if rb.dead or not rb.grounded or flying then
		r.stuck_ticks = 0
		return
	end
	local n = steps_count(r.st)
	if not r.salvo or r.salvo.passi ~= n then
		r.salvo = { passi = n, x = rb.x, y = rb.y, globi = rb.teleports_left, thrown = g.teleports, turno = r.st.turni }
	end
	local without = p and p.permesso and p.permesso("teleport") and not g:can_use("teleport")
	if without then
		for w in pairs(game.WEAPONS) do
			if not (w == "teleport" or w == "swap" or game.TOOLS[w]) and p.permesso(w) then without = false end
		end
	end
	r.stuck_ticks = without and (r.stuck_ticks or 0) + 1 or 0
	if r.stuck_ticks >= MISS_TICK then
		r.stuck_ticks = 0
		restore_snapshot(r, g)
		count(r.st, "misses")
		clear_line(r)
		show_line(r, { testo = RETRY_TEXT })
	end
end

-- Il passo p si può fare adesso? (uno dei comandi che dice si può usare; per
-- colpire, un attacco: col solo globo il turno va avanti)
local function allowed(g, p)
	if not p.permesso then return false end
	local hit_def = p.hit or p.down
	for w in pairs(game.WEAPONS) do
		local attack = not (w == "teleport" or w == "swap" or game.TOOLS[w])
		if p.permesso(w) and (attack or not hit_def) and g:can_use(w) then return true end
	end
	return false
end

-- Lezioni col tempo: finché il passo da fare si può fare (o un colpo è in
-- volo) il tempo non scende sotto un secondo; per i globi, non oltre quelli
local function hold_clock(r, g, p)
	if not (r.shot or allowed(g, p)) then return end
	local minimum = 60
	if p.usa == "globi" and p.globi then
		local thresholds = {}
		for i, v in ipairs(config.TELEPORT_SOGLIE) do thresholds[i] = v end
		table.sort(thresholds)
		-- (due tick di margine: il colpo parte il tick dopo)
		minimum = game.TURN_TICKS - thresholds[#thresholds - p.globi + 1] * 60 + 2
	end
	if g.timer < minimum then g.timer = minimum end
	if g.window > 0 and g.window < 60 then g.window = 60 end
end

-- Il robot da colpire o abbattere nel passo da fare (il segnale sopra di lui), o nil
function M.bersaglio(r)
	if not r or r.esito or not r.l.riprova then return nil end
	local _, p = next_one(r.l, r.st)
	return p and (p.hit or p.down) or nil
end

-- La bandierina a scacchi del passo da fare (raggiungi con bandiera), o nil
function M.bandiera(r)
	local _, p = next_one(r.l, r.st)
	if p and p.reach and p.bandiera then return p.reach.x, p.reach.y end
end

function M.tick(r, g)
	local l, st = r.l, r.st
	if l.senza_tempo and g.current == PLAYER then senza_tempo(r, g) end
	local _, p = next_one(l, st)
	-- si usa solo quello che il passo dice (lezione finita: tutto)
	g.permesso = not r.esito and p and p.permesso or nil
	if l.riprova and g.current == PLAYER then
		attempt_over(r, g)
		if p and not l.senza_tempo and not r.esito then hold_clock(r, g, p) end
		hold_still(r, g, p)
	end
	-- i bersagli che restano giù spariscono quando rinascerebbero
	for i, rb in ipairs(g.robots) do
		if r.giu[i] and rb.dead and rb.respawn_in and rb.respawn_in <= 1 then
			r.giu[i] = nil
			local in_order_now = false
			for _, o in ipairs(g.order) do in_order_now = in_order_now or o == i end
			if in_order_now then
				g:remove(i)
			else
				-- i bersagli fermi non hanno turni: spariscono e basta
				rb.gone, rb.respawn_in = true, nil
				g:emit({ type = "gone", robot = i })
			end
		end
	end
	-- le schede delle armi che arrivano senza cassa: quando il colpo che ha
	-- fatto il passo è arrivato, e un attimo dopo
	local flying = g.projectile or g.burst or g:shards_flying() or #g.orbs > 0
	for i, c in ipairs(l.schede or {}) do
		if not r.aperte[i] and (c.dopo == 0 or st.passi[c.dopo]) then
			-- (se niente vola, subito)
			r.waits[i] = flying and 0 or (r.waits[i] or CARD_DELAY - 1) + 1
		end
		if not r.aperte[i] and (r.waits[i] or 0) >= CARD_DELAY then
			r.aperte[i] = true
			if c.dai then
				game.dai(g.robots[PLAYER], c.arma)
				r.prese[c.arma] = true
			end
			r.schede[#r.schede + 1] = c.arma
		end
	end
	-- le casse della missione cadono, fatto il loro passo
	for i, c in ipairs(l.casse or {}) do
		if not r.cadute[i] and (c.dopo == 0 or st.passi[c.dopo]) then
			r.cadute[i] = g:spawn_crate(c.arma, c.x) or true
			-- parte poco sopra il terreno: la si aspetta un paio di secondi, non dieci
			local cr, gy = r.cadute[i], g.terrain:ground_below(c.x, game.WORLD_H - 1)
			if cr ~= true and gy then cr.y = math.min(cr.y, gy + CRATE_ABOVE) end
		end
	end
	-- lezioni: un'arma a colpi trovata in una cassa torna appena puoi
	-- riattaccare, si riprova quanto serve (nei gironi la cassa è un colpo solo)
	local rb = g.robots[PLAYER]
	for _, c in ipairs(l.riprova and l.casse or {}) do
		local n = rb.ammo[c.arma]
		local used_up = game.SECONDARY[c.arma] and g.used.secondary or g.used.primary
		if n == 0 and r.prese[c.arma] and not used_up then rb.ammo[c.arma] = 1 end
	end
	-- lezioni: finché non tocchi i comandi il tempo del turno e della partita è fermo
	if r.attesa and g.current == PLAYER then
		r.fermo = r.fermo or { timer = g.timer, window = g.window, match = g.match_left }
		local f = r.fermo
		g.timer, g.window, g.match_left = f.timer, f.window, f.match
	end
	check_event(r, g, nil)
	-- a terra o no prima degli eventi del prossimo tick (il Tonante stacca da terra)
	st.on_ground = g.robots[PLAYER].grounded
	if r.riga_t and not r.attesa then
		r.riga_t = r.riga_t - 1
		if r.riga_t <= 0 then clear_line(r) end
	end
	return r.esito
end

-- La scheda d'arma da aprire (missione.schede), una volta
function M.scheda(r)
	return r and table.remove(r.schede, 1)
end

-- Il livello della camera che vuole il passo da fare (zoom), una volta per passo
function M.zoom(r)
	if not r then return nil end
	local i, p = next_one(r.l, r.st)
	if p and p.zoom and r.zoomed ~= i then
		r.zoomed = i
		return p.zoom
	end
end

-- La riga da mostrare e sopra chi (il robot), o nil
function M.riga(r)
	return r.riga, r.line_on
end

-- L'obiettivo sempre in vista: il passo che manca, col numero se sono più d'uno
function M.obiettivo(r)
	local l = r.l
	local i, p = next_one(l, r.st)
	if not i or r.esito then return nil end
	local n = #l.obiettivo
	return n > 1 and (i .. "/" .. n .. "  " .. p.testo) or p.testo
end

local function lead_text(n)
	return "CON " .. n .. " PUNTI DI VANTAGGIO"
end

-- Cosa serve per ogni stella
function M.criteri(l)
	if l.guidata then return { "FINITA", "VINTA", lead_text(GUIDED_POINTS) } end
	local s = l.stelle
	if s.bonus2 then return { "FATTA", s.bonus.testo, s.bonus2.testo } end
	return { "FATTA", lead_text(s.punti), s.bonus.testo }
end

-- I punti di vantaggio a fine missione (nil dove i punti non ci sono)
function M.vantaggio(r)
	local l = r.l
	if l.guidata or (l.stelle and l.stelle.punti) then return math.floor((r.st.distacco or 0) + 0.5) end
end

local function bonus(b, st)
	local n = st.conta[b.conta] or 0
	if b.at_most then return n <= b.at_most end
	return n >= b.almeno
end

-- Stelle: una per averla fatta, poi i punti di vantaggio e il bonus (o due
-- bonus). Ognuna vale da sola: si può avere la terza senza la seconda. Nella
-- partita guidata: finita, vinta, vinta con 100 punti di vantaggio.
function M.stelle(r)
	if r.esito ~= "fatta" then return { false, false, false } end
	local l, st = r.l, r.st
	local d = st.distacco or 0
	if l.guidata then
		return { true, st.vinta == true, st.vinta == true and d >= GUIDED_POINTS }
	end
	local s = l.stelle
	if s.bonus2 then return { true, bonus(s.bonus, st), bonus(s.bonus2, st) } end
	return { true, d >= s.punti, bonus(s.bonus, st) }
end

function M.quante(stars)
	local n = 0
	for i = 1, 3 do
		if stars[i] then n = n + 1 end
	end
	return n
end

return M
