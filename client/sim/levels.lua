-- The levels of the campaign, chapter by chapter: all data, the script of
-- each level (sim/missions.lua defines the format and runs it). The Copione
-- (strumenti/copione, the campaign's dashboard) shows them, edits them and
-- writes them back here: nothing in here may be a function (strumenti/copione/
-- controlla.lua checks it), so a level can travel as JSON to the web build
-- and be played before it is saved.
--
-- Chapter 0 is the Addestramento, the lessons: small puzzles that
-- teach one thing only and can't be finished without using it. Then the
-- circles (gironi): each circle a map and a mechanic, closed by its keeper (a
-- bot with a personality, sim/bot.lua M.PERSONALITIES). A chapter opens with the
-- stars earned in the ones before (serve). Sergio's choices of 29 October 2026
-- (https://claude.ai/artifact/DaLXhFApbxLpa1reyPtenC).
--
-- World coordinates (1920 x 1080, y up). Arenas are steel, so craters don't
-- break the puzzle. The circle numbers (life, turns, stars) are checked by the
-- bot trial (strumenti/arena/collaudo.lua): the second star is at the median
-- point lead of the normal bot playing in your place (Sergio, 31 Oct: in the
-- circles points count, turns don't).
-- Circle opponents are grades (sim/bot.lua M.GRADES, 1 to 10): the Forgia goes
-- from 2 up to 5 (Sergio, 30 Oct); Favilla, your ally, is a 3 in the first
-- two missions (level plan, 3 Nov) and a 5 in the Battaglia.

local M = {}

M.addestramento = {
	-- The cortile of the Forgia (Sergio, 3 Nov: the level plan
	-- https://claude.ai/artifact/12CRugbQCR2oB32LHt6aS2): seven short lessons
	-- with Favilla, who trains you. No stars: «Fatta» and, where there's a real
	-- challenge, her optional medal. Favilla is a puppet (guida): she runs and
	-- jumps along a path and is never hit. Nothing shows up before it's needed.
	-- 1 · Stammi dietro: walk after her, jump the step, reach her at the gate.
	-- The medal: the spark above the step, taken only holding the jump to the end
	{
		id = "primi_passi",
		titolo = "Stammi dietro",
		tipo = "corsa",
		goal_text = "Stammi dietro, nuovo! Ti aspetto al cancello: {cammina}",
		highlight = "cammina",
		-- a step higher than you can walk up, lower than the jump
		arena = { { 240, 0, 1440, 150 }, { 1100, 150, 580, 30 } },
		spawns = { { x = 480, from = 600 }, { x = 300, from = 600 } },
		-- the game wants two robots: the second isn't there (nascosti)
		giocatori = { { team = 1 }, { team = 2, dummy = true } },
		nascosti = { 2 },
		vedi = {},
		no_weapons = true, without_time = true,
		-- she runs ahead at your pace, waits at the step, then at the gate
		guida = { parte = 0, percorso = {
			{ x = 560, y = 150, t = 0 }, { x = 560, y = 150, t = 1.5 }, { x = 1040, y = 150, t = 13.9 },
			{ x = 1140, y = 180, t = 14.6, salto = 25 }, { x = 1520, y = 180, t = 24.4 },
		} },
		-- your body touches it at the top of a full jump from the step (feet up to ~223),
		-- not at the top of a short one (~208) (the held jump, JUMP_CUT; sim/missions.lua)
		scintilla = { x = 1300, y = 268 },
		medaglia = { conta = "scintille", at_least = 1, testo = "LA SCINTILLA" },
		obiettivo = {
			{ reach = { x = 900, y = 150 }, testo = "Stai dietro a Favilla" },
			{ reach = { x = 1100, y = 180 }, testo = "Salta sul gradino" },
			{ reach = { x = 1460, y = 180 }, testo = "Raggiungi Favilla al cancello" },
		},
		righe = {
			{ testo = "Il gradino è troppo alto per camminarci sopra: {salta}", mostra = "grande", highlight = "salta",
				quando = { passo = 1 }, fino = { passo = 2 } },
			{ testo = "Vedi la scintilla lassù? Tieni premuto il salto fino in fondo e prendila!",
				quando = { passo = 2 }, fino = { evento = "spark" } },
			{ testo = "Presa! Più tieni premuto, più salti in alto", faccia = "fiera", quando = { evento = "spark" } },
		},
	},
	-- 2 · Il mio vecchio Lanciarune: the crate she throws down, the near target
	-- and the far one on the ledge, where she waits. No medal: no real challenge
	{
		id = "lanciarune",
		titolo = "Il mio vecchio Lanciarune",
		tipo = "bersagli",
		goal_text = "Ti butto giù il mio vecchio Lanciarune: prendilo!",
		arena = { { 240, 0, 1440, 150 }, { 1300, 150, 380, 80 } },
		spawns = { { x = 480, from = 600 }, { x = 860, from = 600 }, { x = 1580, from = 600 } },
		giocatori = { { team = 1 }, { team = 2, dummy = true }, { team = 2, dummy = true } },
		vedi = { "missile" },
		no_weapons = true, without_time = true,
		guida = { parte = 0, percorso = { { x = 1400, y = 230, t = 0 } } },
		casse = { { dopo = 0, arma = "missile", x = 640 } },
		obiettivo = {
			{ prendi = "missile", testo = "Prendi la cassa" },
			{ hit = 2, con = "missile", testo = "Colpisci il fantoccio vicino" },
			{ hit = 3, con = "missile", testo = "Colpisci il fantoccio sul ballatoio" },
		},
		righe = {
			{ testo = "Colpisci il fantoccio: {mira}", mostra = "grande", highlight = "mira", quando = { passo = 1 } },
			-- while aiming: how to cancel
			{ testo = "Più tiri lontano, più forte parte. Se cambi idea, {annulla}", highlight = "annulla",
				subito = true, quando = { passo = 1, tocca = "mira" },
				fino = { uno = { { tocca = "annulla" }, { usato = "primaria" } } } },
			{ testo = "Bel colpo! Ora quello quassù, vicino a me", faccia = "ride", quando = { passo = 2 } },
		},
	},
	-- 3 · A turno: the timer shows from here, and the Lama. Two attacks in a turn:
	-- the Lanciarune, then the Lama on the same target. No medal
	{
		id = "turno",
		titolo = "A turno",
		tipo = "bersagli",
		goal_text = "Qui si gioca a turno: il cronometro in basso è il tuo. Colpisci il fantoccio",
		highlight = "missile",
		arena = { { 300, 0, 1300, 150 } },
		spawns = { { x = 600, from = 600 }, { x = 900, from = 600 } },
		giocatori = { { team = 1 }, { team = 2, dummy = true } },
		vedi = { "missile", "sword", "tempo" },
		globi = 0,
		guida = { parte = 0, percorso = { { x = 420, y = 150, t = 0 } } },
		cards = { { dopo = 1, arma = "sword" } },
		obiettivo = {
			{ hit = 2, con = "missile", only = { "missile" }, testo = "Colpisci il fantoccio col Lanciarune" },
			{ hit = 2, con = "sword", only = { "sword" }, testo = "Secondo attacco: colpiscilo con la Lama" },
		},
		righe = {
			{ testo = "Due attacchi a turno! Il secondo è la Lama: vai vicino e {mira}", mostra = "grande", highlight = "sword",
				quando = { passo = 1 }, fino = { passo = 2 } },
		},
	},
	-- 4 · Il tempo risparmiato: attacking early gives orbs (time stops before you
	-- lose the first), the orb carries you to the island, whose target falls at
	-- the first hit; the second attack isn't needed and is bartered for an orb,
	-- which brings you back. The medal: two orbs in one turn
	{
		id = "tempo",
		titolo = "Il tempo risparmiato",
		tipo = "bersagli",
		goal_text = "Attacca presto: i secondi che avanzano diventano globi",
		highlight = "missile",
		-- your ground, the gap, and the island of the second target
		arena = { { 300, 0, 600, 150 }, { 1200, 100, 320, 50 } },
		spawns = { { x = 600, from = 600 }, { x = 660, from = 600 }, { x = 1440, from = 600 } },
		giocatori = { { team = 1 }, { team = 2, dummy = true }, { team = 2, dummy = true } },
		-- the one on the island falls at the first hit
		vita = { [3] = 10 },
		vedi = { "missile", "sword", "teleport", "tempo", "baratto" },
		globi = 0,
		guida = { parte = 0, percorso = { { x = 420, y = 150, t = 0 } } },
		medaglia = { conta = "globi_turno", at_least = 2, testo = "DUE GLOBI IN UN TURNO" },
		obiettivo = {
			{ usa = "globi", globi = 1, only = { "missile" }, testo = "Spara presto col Lanciarune: guadagni globi" },
			{ reach = { x = 1200, y = 150 }, only = { "teleport" }, zoom = 2, testo = "Teletrasportati sull'isola" },
			{ hit = 3, only = { "missile" }, testo = "Colpisci il fantoccio sull'isola" },
			{ usa = "baratto", only = { "baratto" }, testo = "Baratta il secondo attacco con un globo" },
			{ hit = 2, only = { "teleport", "missile", "sword" }, testo = "Torna dal primo fantoccio e colpiscilo" },
		},
		righe = {
			{ testo = "Tocca il tasto viola, mira l'isola e lascia: arrivi dove cade il globo", mostra = "grande", highlight = "teleport",
				quando = { passo = 1 }, fino = { evento = "teleport" } },
			{ testo = "Lanciarune e Lama non finiscono mai: le uniche armi coi colpi infiniti",
				quando = { evento = "teleport" } },
			{ testo = "Abbattuto: il secondo attacco non serve. Tocca le due frecce sopra il cronometro: diventa un globo", mostra = "grande",
				highlight = "baratto", quando = { passo = 3 }, fino = { passo = 4 } },
			{ testo = "Il prossimo turno torna col globo dal primo fantoccio e colpiscilo come vuoi",
				quando = { passo = 4 } },
		},
	},
	-- 5 · Arriva in cima prima di me: the secondaries, one crate at a time. The
	-- Tonante (kickback onto the first pillar), the Maglio (pogo onto the second),
	-- the Affondo on the target. No timer: each attempt restarts at once. Favilla
	-- climbs her own lane on the left from the first crate: the medal is finishing
	-- before she gets to the top
	{
		id = "spostano",
		titolo = "Arriva in cima prima di me",
		tipo = "corsa",
		goal_text = "Una gara: arriva in cima prima di me! Prendi la cassa, dentro c'è un'arma che ti sposta",
		-- the first pillar higher than the jump, the second higher than the kickback;
		-- on the left Favilla's lane, two pillars of the same heights
		arena = { { 300, 0, 1300, 150 }, { 1000, 150, 160, 110 }, { 1160, 150, 300, 310 },
			{ 330, 150, 50, 110 }, { 300, 150, 30, 310 } },
		spawns = { { x = 640, from = 600 }, { x = 1400, from = 1000 } },
		giocatori = { { team = 1 }, { team = 2, dummy = true } },
		vedi = { "missile", "sword" },
		without_time = true,
		casse = {
			{ dopo = 0, arma = "eagle", x = 760 },
			{ dopo = 3, arma = "mallet", x = 1080 },
			{ dopo = 6, arma = "lunge", x = 1240 },
		},
		-- her pace: at the top 32 seconds after your first crate (vignettes stop the clock)
		guida = { parte = 1, gara = true, percorso = {
			{ x = 430, y = 150, t = 0 }, { x = 430, y = 150, t = 12 }, { x = 355, y = 260, t = 14, salto = 40 },
			{ x = 355, y = 260, t = 30 }, { x = 315, y = 460, t = 32.5, salto = 60 },
		} },
		medaglia = { conta = "prima", at_least = 1, testo = "PRIMA DI FAVILLA" },
		obiettivo = {
			{ prendi = "eagle", testo = "Prendi la cassa" },
			{ usa = "kickback", testo = "Salta e spara col Tonante verso il basso" },
			{ reach = { x = 1000, y = 260 }, testo = "Sali sul primo pilastro" },
			{ prendi = "mallet", testo = "Prendi la cassa" },
			{ usa = "pogo", testo = "Salta e colpisci il pilastro col Maglio" },
			{ reach = { x = 1160, y = 460 }, testo = "Sali sul secondo pilastro" },
			{ prendi = "lunge", testo = "Prendi la cassa" },
			{ hit = 2, con = "lunge", testo = "Colpisci il fantoccio con l'Affondo" },
		},
		righe = {
			{ testo = "Il Tonante ha il rinculo: ti spinge dall'altra parte del colpo. Toccalo", mostra = "grande",
				highlight = "eagle", quando = { passo = 1 }, fino = { tocca = "eagle" } },
			{ testo = "Salta ({salta}) e in aria spara verso il basso: il rinculo ti porta su", mostra = "grande",
				highlight = "salta", quando = { tocca = "eagle" }, fino = { passo = 3 } },
			{ testo = "Colpisci il pilastro col Maglio: rimbalzi in alto. Saltando ({salta}) arrivi più su", mostra = "grande",
				highlight = "mallet", quando = { passo = 4 }, fino = { tocca = "mallet" } },
			{ testo = "L'Affondo è uno scatto: passa oltre chi hai davanti e lo colpisce", mostra = "grande", highlight = "lunge",
				quando = { passo = 7 }, fino = { tocca = "lunge" } },
			{ testo = "Una secondaria a partita, oltre alla Lama: la scegli all'inizio", quando = { passo = 8 } },
			{ testo = "Già in cima? Mi hai battuta!", faccia = "sorpresa",
				quando = { conta = "prima", almeno = 1 } },
		},
	},
	-- 6 · Il burrone. Grapple and parachute (Sergio, 30 Oct): no crates, because they aren't found
	-- there; after a few steps the card opens and the button lights up. The
	-- grapple carries you onto the platform, with the parachute you go down past
	-- the gap, and over there the Lama on the target. No timer
	{
		id = "attrezzi",
		titolo = "Il burrone",
		tipo = "corsa",
		goal_text = "Ti aspetto dall'altra parte del burrone! Vai sotto la piattaforma",
		-- your ground, the platform jutting over the gap, the other side
		arena = { { 200, 0, 900, 150 }, { 900, 300, 320, 30 }, { 1360, 0, 560, 150 } },
		spawns = { { x = 640, from = 290 }, { x = 1520, from = 600 } },
		giocatori = { { team = 1 }, { team = 2, dummy = true } },
		vedi = { "sword" },
		without_time = true,
		cards = { { dopo = 1, arma = "hook", give = true }, { dopo = 3, arma = "parachute", give = true } },
		guida = { parte = 0, percorso = { { x = 1700, y = 150, t = 0 } } },
		-- the medal: across without ever falling into the gap
		medaglia = { conta = "morti", at_most = 0, testo = "PIEDI ASCIUTTI" },
		obiettivo = {
			{ reach = { x = 820, y = 150 }, flag = true, testo = "Vai sotto la piattaforma" },
			{ usa = "rampino", only = { "hook" }, testo = "Aggancia il bordo col Rampino" },
			{ reach = { x = 900, y = 330 }, testo = "Sali sulla piattaforma" },
			{ usa = "paracadute", only = { "parachute" }, testo = "Salta nel vuoto e apri il paracadute" },
			{ reach = { x = 1360, y = 150 }, only = { "parachute" }, testo = "Atterra dall'altra parte" },
			{ hit = 2, con = "sword", only = { "sword" }, testo = "Colpisci il fantoccio con la Lama" },
		},
		righe = {
			{ testo = "Il Rampino: toccalo, poi mira il bordo della piattaforma e lascia", mostra = "grande", highlight = "hook",
				quando = { passo = 1 }, fino = { tocca = "hook" } },
			{ testo = "Su un nemico, invece, il Rampino lo tira da te", quando = { passo = 3 } },
			{ testo = "Salta nel vuoto ({salta}) e in aria tocca il paracadute, fra gli OGGETTI",
				highlight = "parachute", stops = false, quando = { passo = 3 }, fino = { evento = "parachute" } },
			{ testo = "Il paracadute è uno a partita: atterri piano e senza farti male", quando = { passo = 4 } },
		},
	},
	-- 7 · Duello con Favilla, the chapter exam: a first real match, short, that
	-- puts everything into practice (Sergio, 29 Oct: the last of the
	-- Addestramento). You win by downing her twice; no points (they come in the
	-- Forgia). The medal: without being downed
	{
		id = "guidata",
		titolo = "Duello con Favilla",
		tipo = "duello",
		goal_text = "Duello! Abbattimi due volte. Trascina dal diavoletto per mirare, lascia per sparare",
		guidata = true,
		mappa = "cortile",
		giocatori = {
			-- no draft (Sergio, 30 Oct): Lanciarune, Lama and Rampino; the other weapons,
			-- if you want them, from crates, with their card
			{ team = 1 },
			{ team = 2, bot = 1, pick = "grenade", secondary = "mallet", nome = "Favilla", battute = "favilla", pelle = "favilla" },
		},
		vedi = { "primarie", "secondarie", "teleport", "parachute", "tempo", "baratto", "hook" },
		-- short match: 3 minutes; when time runs out the one who downed the other
		-- more wins, and on a tie Favilla gives it to you (level plan)
		secondi = 180,
		al_tempo = "abbattimenti",
		-- the bot shows in its turn what the player will do in the next turn
		plans = { { due_attacchi = true }, { attacca_entro = 4, poi = "teletrasporto" } },
		medaglia = { conta = "morti", at_most = 0, testo = "INTOCCABILE" },
		obiettivo = { { down = 2, times = 2, testo = "Abbatti Favilla due volte" } },
		righe = {
			{ testo = "Hai 8 secondi: mettiti al riparo. Per saltare {salta}", mostra = "grande", highlight = "salta",
				quando = { turno = 1, di_turno = "tu", finestra = true } },
			{ testo = "Guarda: due attacchi, una primaria e una secondaria",
				quando = { turno_altri = 1, di_turno = "altri" } },
			{ testo = "Due attacchi a turno. Prima la primaria, a sinistra del cronometro: toccala", mostra = "grande",
				highlight = "primaria",
				quando = { turno = 2, di_turno = "tu" },
				fino = { usato = "primaria" } },
			{ testo = "Ora la secondaria, a destra del cronometro: toccala e colpisci", mostra = "grande", highlight = "secondaria",
				quando = { turno = 2, di_turno = "tu", usato = "primaria" },
				fino = { usato = "secondaria" } },
			{ testo = "Ho attaccato subito: i secondi che avanzano diventano globi",
				quando = { turno_altri = 2, evento = "teleports", di = "altri" } },
			{ testo = "Attacca presto: prima delle tacche viola sull'anello guadagni globi",
				quando = { turno = 3, di_turno = "tu" },
				fino = { uno = { { usato = "primaria" }, { usato = "secondaria" } } } },
			{ testo = "Lancia un globo col tasto viola: arrivi dove cade", mostra = "grande", highlight = "teleport",
				quando = { turno = 3, evento = "teleports", di = "tu" },
				fino = { evento = "teleport" } },
			{ testo = "Passaci sopra per prenderla: dentro c'è un'arma o un oggetto",
				quando = { evento = "crate" }, fino = { evento = "crate_pick" } },
			{ testo = "Tocca in aria per il paracadute: uno a partita", highlight = "parachute", stops = false,
				quando = { di_turno = "tu", in_caduta = true },
				fino = { evento = "parachute" } },
			{ testo = "Si rinasce subito, e il turno continua",
				quando = { evento = "death", di = "tu" } },
		},
	},
}

-- Circle I: the Forgia. Two attacks, orbs from saved time, pushing into the
-- void; the keeper is the Fabbro. Opponents are real bots.
M.girone_1 = {
	{
		id = "primo_sangue",
		titolo = "Primo sangue",
		tipo = "squadra",
		goal_text = "Abbatti il bot: un'arma a sinistra e una a destra del cronometro",
		mappa = "pavimento",
		-- 2 v 2 with Favilla from the first mission (level plan): two apprentices,
		-- grades 2 and 1
		giocatori = { { team = 1 }, { team = 2, bot = 2 }, { team = 1, bot = 3, nome = "Favilla", battute = "favilla_compagna", pelle = "favilla" }, { team = 2, bot = 1 } },
		-- the weapons the Addestramento doesn't introduce are found in the circle (Claude)
		-- the second apprentice is half-done: Favilla is a 3, two full bots would
		-- be too much for the first mission (collaudo)
		vita = { [4] = 50 },
		casse = { { dopo = 0, arma = "grenade", x = 405 } },
		turni = 7,
		-- ★★ at the median lead of the normal bot in 2 v 2 (collaudo, 4 Nov)
		stelle = { punti = 280, bonus = { conta = "morti", at_most = 0, testo = "SENZA MORIRE" } },
		obiettivo = { { down = 2, testo = "Abbatti il bot" } },
		-- in the circles the hints highlight the control but the game doesn't stop
		righe = {
			{ testo = "Prima la primaria, a sinistra del cronometro", highlight = "primaria",
				quando = { turno = 2 }, fino = { usato = "primaria" } },
			{ testo = "Poi la secondaria, a destra", highlight = "secondaria",
				quando = { turno = 2, di_turno = "tu", usato = "primaria" },
				fino = { usato = "secondaria" } },
		},
	},
	{
		id = "fuori_portata",
		titolo = "Fuori portata",
		tipo = "squadra",
		goal_text = "Il cecchino sta sull'isola. Attacca presto per avere i globi, poi raggiungilo",
		arena = { { 200, 0, 720, 150 }, { 1240, 120, 460, 50 } },
		spawns = { { x = 500, from = 600 }, { x = 1520, from = 600 }, { x = 320, from = 600 }, { x = 1330, from = 600 } },
		-- 2 v 2 with Favilla: the sniper and an apprentice on the island (an enemy
		-- on the ground would draw all the shots, collaudo)
		giocatori = { { team = 1 }, { team = 2, bot = 2, carattere = "cecchino" }, { team = 1, bot = 3, nome = "Favilla", battute = "favilla_compagna", pelle = "favilla" }, { team = 2, bot = 1 } },
		globi = 0,
		-- Favilla can knock the sniper into the void: it comes back on its island
		al_posto = true,
		vita = { [2] = 55, [4] = 50 },
		turni = 6,
		stelle = { punti = 290, bonus = { conta = "teletrasporti", at_most = 1, testo = "CON UN SOLO GLOBO" } },
		obiettivo = {
			{ usa = "globi", testo = "Attacca presto: guadagna un globo" },
			{ down = 2, con = "sword", testo = "Finisci il cecchino con la Lama" },
		},
		righe = {
			{ testo = "Ora il tasto viola: il globo ti porta dove cade", highlight = "teleport",
				quando = { evento = "teleports" }, fino = { evento = "teleport" } },
		},
		-- you can't get there without teleport
		collaudo = { senza = { teletrasporto = false } },
	},
	{
		id = "due_mani",
		titolo = "Due mani",
		tipo = "duello",
		goal_text = "Il bot si rimette in sesto a ogni turno: serve la primaria e la Lama nello stesso turno",
		arena = { { 240, 0, 1440, 150 } },
		spawns = { { x = 760, from = 600 }, { x = 1160, from = 600 } },
		giocatori = { { team = 1 }, { team = 2, bot = 3 } },
		vita = { [2] = 46 },
		regrow = { 2 },
		casse = { { dopo = 0, arma = "shards", x = 560 } },
		-- the bot testing it always does both attacks
		collaudo = { piano = { due_attacchi = true } },
		turni = 6,
		stelle = { punti = 110, bonus = { conta = "morti", at_most = 0, testo = "SENZA MORIRE" } },
		obiettivo = { { down = 2, testo = "Abbatti il bot in un turno solo" } },
	},
	{
		id = "giu_dal_bordo",
		titolo = "Giù dal bordo",
		tipo = "bersagli",
		goal_text = "I bersagli non si feriscono: buttali giù dai loro scogli",
		-- your platform and three narrow rocks over the void
		arena = { { 760, 300, 400, 40 }, { 420, 420, 70, 24 }, { 1430, 420, 70, 24 }, { 925, 620, 70, 24 } },
		spawns = { { x = 960, from = 600 }, { x = 455, from = 600 }, { x = 1465, from = 600 }, { x = 960, from = 1000 } },
		-- everything that pushes (Sergio, 29 October 2026): the Cecchino, the Mantice
		-- and the Rampino, which reaches the rocks from the edge and drops them over the void
		giocatori = {
			{ team = 1, pick = "sniper", secondary = "bellows" },
			{ team = 2, dummy = true }, { team = 2, dummy = true }, { team = 2, dummy = true },
		},
		vita = { [2] = 999, [3] = 999, [4] = 999 },
		turni = 5,
		stelle = { punti = 400, bonus = { conta = "morti", at_most = 0, testo = "SENZA CADERE" } },
		obiettivo = { { down = "nemico", come = "vuoto", times = 3, testo = "Butta giù tre bersagli" } },
		-- the points explained here, with the first void (level plan: the Punti e
		-- Corona lesson moved from the cortile into the Forgia)
		righe = {
			{ testo = "Qui contano i punti: danno = punti, abbattere vale 50, buttare nel vuoto altri 50",
				quando = { turno = 1, di_turno = "tu" } },
			{ testo = "Hai la Corona: sei primo. I colpi su chi è primo valgono 1,5 e abbatterlo 25 in più",
				quando = { corona = "tu" } },
		},
		-- the bot testing it looks for the void
		collaudo = { carattere = "spingitore" },
	},
	{
		id = "il_codardo",
		titolo = "Il codardo",
		tipo = "duello",
		goal_text = "Colpisce a ogni turno e scappa col globo nelle tane: stanalo col tuo",
		mappa = "pavimento",
		giocatori = { { team = 1 }, { team = 2, bot = 4, carattere = "codardo", nome = "Il codardo" } },
		-- the Pugno, which cracks the armour, comes in the crate (it was taught in
		-- the cortile's Punti e Corona lesson, now gone)
		casse = { { dopo = 0, arma = "punch", x = 405 } },
		righe = {
			{ testo = "Il Pugno incrina l'armatura: il colpo dopo toglie di più", highlight = "punch",
				quando = { evento = "crate_pick", di = "tu", arma = "punch" },
				fino = { tocca = "punch" } },
		},
		turni = 7,
		stelle = { punti = 120, bonus = { conta = "morti", at_most = 0, testo = "SENZA MORIRE" } },
		obiettivo = { { down = 2, testo = "Abbatti il codardo" } },
	},
	{
		id = "il_fabbro",
		titolo = "Il Fabbro",
		tipo = "custode",
		goal_text = "Il custode della Forgia: tanta vita e il Maglio. Buttarlo nella fossa di lava fa prima",
		-- the lava pit in the middle of the floor: that's where you throw them (Sergio, 2 Nov)
		mappa = "fossa",
		giocatori = {
			{ team = 1 },
			{ team = 2, bot = 5, carattere = "testa_calda", secondary = "mallet", nome = "Il Fabbro",
				battute = "fabbro" },
		},
		vita = { [2] = 240 },
		turni = 10,
		stelle = { punti = 10, bonus = { conta = "vuoto", at_least = 1, testo = "BUTTALO NELLA FOSSA" } },
		obiettivo = { { down = 2, testo = "Abbatti il Fabbro" } },
	},
	-- the end of the circle: a full 2 v 2 match, with a bot at your side, that
	-- puts together everything in the circle
	{
		id = "battaglia_forgia",
		titolo = "Battaglia della Forgia",
		tipo = "squadra",
		goal_text = "Una partita vera, 2 contro 2: tu e Favilla contro il Fabbro e il cecchino",
		mappa = "pavimento",
		-- the first weapon draft, guided, with the weapons already seen (Sergio, 30 Oct)
		draft = true,
		giocatori = {
			{ team = 1 },
			{ team = 2, bot = 5, carattere = "testa_calda", secondary = "mallet", nome = "Il Fabbro",
				battute = "fabbro" },
			-- Favilla at your side (level plan: no more the nameless «Compagno»);
			-- here she has grown to a 5, like the Fabbro (collaudo: a 3 loses half)
			{ team = 1, bot = 5, nome = "Favilla", battute = "favilla_compagna", pelle = "favilla" },
			{ team = 2, bot = 2, carattere = "cecchino" },
		},
		-- no turn limit: play until time runs out
		stelle = { punti = 215, bonus = { conta = "abbattuti", at_least = 3, testo = "ABBATTINE 3" } },
		obiettivo = { { win = true, testo = "Vinci la partita con Favilla" } },
	},
}

return M
