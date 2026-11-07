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
	-- https://claude.ai/artifact/12CRugbQCR2oB32LHt6aS2; redone 6 Nov, the overview
	-- https://claude.ai/artifact/UsfnsDYJBp7fuEiorbLKUP): six short lessons with
	-- Favilla and three short matches against her (the sfide) with only what you
	-- already know. Every new move has four beats: she explains it (a big
	-- vignette), she does it (her path, or the turn passes to her: insegna,
	-- dimostra), you do it (the step with nuova = true), she says bravo (a line
	-- with her face, or the lesson's bravo). At most two new moves per lesson; the
	-- sfide explain nothing. No stars: «Fatta» and, where there's a real
	-- challenge, her optional medal. Nothing shows up before it's needed.
	-- 1 · Stammi dietro: walk after her, jump the step, reach her at the gate.
	-- Favilla the puppet on her path (guida). The medal: the spark above the step,
	-- taken only holding the jump to the end
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
			{ reach = { x = 900, y = 150 }, nuova = true, testo = "Stai dietro a Favilla" },
			{ reach = { x = 1100, y = 180 }, nuova = true, testo = "Salta sul gradino" },
			{ reach = { x = 1460, y = 180 }, testo = "Raggiungi Favilla al cancello" },
		},
		righe = {
			{ testo = "Così, stammi dietro!", faccia = "ride", secondi = 2, quando = { passo = 1 } },
			{ testo = "Il gradino è troppo alto per camminarci sopra: {salta}", mostra = "grande", highlight = "salta",
				quando = { passo = 1 }, fino = { passo = 2 } },
			{ testo = "Saltato, bravo! Vedi la scintilla lassù? Tieni premuto il salto fino in fondo e prendila!",
				faccia = "ride", quando = { passo = 2 }, fino = { evento = "spark" } },
			{ testo = "Presa! Più tieni premuto, più salti in alto", faccia = "fiera", quando = { evento = "spark" } },
		},
		bravo = "Eccoti al cancello: sei veloce!",
	},
	-- 2 · Il mio vecchio Lanciarune: the crate she throws down; she shoots the near
	-- target from the ledge, then you; then the far one by her. No medal
	{
		id = "lanciarune",
		titolo = "Il mio vecchio Lanciarune",
		tipo = "bersagli",
		goal_text = "Ti butto giù il mio vecchio Lanciarune: prendilo!",
		arena = { { 240, 0, 1440, 150 }, { 1300, 150, 380, 80 } },
		spawns = { { x = 480, from = 600 }, { x = 860, from = 600 }, { x = 1580, from = 600 }, { x = 1400, from = 600 } },
		giocatori = { { team = 1 }, { team = 2, dummy = true }, { team = 2, dummy = true },
			{ team = 1, insegna = true, nome = "Favilla", pelle = "favilla" } },
		vedi = { "missile" },
		no_weapons = true, without_time = true,
		casse = { { dopo = 0, arma = "missile", x = 640 } },
		-- she shows the shot on the near target, from the ledge
		dimostra = {
			{ quando = { passo = 1 }, mosse = {
				{ dice = "Guarda: miro e lascio andare!" },
				{ arma = "missile", angolo = 160, potenza = 0.6 },
				{ posa = "vittoria", secondi = 1 },
			} },
		},
		obiettivo = {
			{ prendi = "missile", testo = "Prendi la cassa" },
			{ hit = 2, con = "missile", nuova = true, testo = "Colpisci il fantoccio vicino" },
			{ hit = 3, con = "missile", testo = "Colpisci il fantoccio sul ballatoio" },
		},
		righe = {
			{ testo = "Si mira così, guarda me! Poi tocca a te: {mira}",
				mostra = "grande", highlight = "mira", quando = { passo = 1 } },
			-- while aiming: how to cancel
			{ testo = "Più tiri lontano, più forte parte. Se cambi idea, {annulla}", highlight = "annulla",
				subito = true, quando = { passo = 1, tocca = "mira" },
				fino = { uno = { { tocca = "annulla" }, { usato = "primaria" } } } },
			{ testo = "Bel colpo! Ora quello quassù, vicino a me", faccia = "ride", quando = { passo = 2 } },
		},
		bravo = "Due su due: hai la mano ferma!",
	},
	-- 3 · A turno: the timer shows from here. She plays a whole turn first (the
	-- Lanciarune, the Lama, then behind the low wall), then you: two attacks,
	-- then take cover (the 8 seconds after the first attack). No medal
	{
		id = "turno",
		titolo = "A turno",
		tipo = "bersagli",
		goal_text = "Qui si gioca a turni: il cronometro in basso indica il tempo rimanente. In un turno hai due attacchi, uno con un'arma primaria ed uno con la secondaria. Guarda me!",
		highlight = "missile",
		arena = {
			{ 150, 0, 1450, 150 },
			{ 1090, 150, 20, 180 },
		},
		spawns = {
			{ x = 970, from = 620 },
			{ x = 760, from = 590 },
			{ x = 580, from = 620 },
		},
		giocatori = {
			{ team = 1, stats = { teleports = 1, time_orbs = 0 } },
			{ team = 2, dummy = true },
			{ team = 1, nome = "Favilla", pelle = "favilla", insegna = true },
		},
		vedi = { "missile", "sword", "teleport", "tempo" },
		globi = 1,
		cards = { { dopo = 1, arma = "sword" } },
		dimostra = {
			{ mosse = {
				{ dice = "Primo attacco: il Lanciarune" },
				{ arma = "missile", angolo = 22, potenza = 0.4 },
				{ cammina = 700 },
				{ dice = "Secondo: la Lama" },
				{ arma = "sword", angolo = -12, potenza = 0.1 },
			} },
			{ quando = { passo = 3 }, mosse = {
				{ cammina = 700 },
				{ arma = "teleport", angolo = 60, potenza = 0.6 },
				{ cammina = 1215 },
				{ dice = "Ti aspetto dall'altro lato!" },
			} },
		},
		obiettivo = {
			{ hit = 2, con = "missile", only = { "missile" }, testo = "Colpisci il fantoccio col Lanciarune" },
			{ hit = 2, con = "sword", only = { "sword" }, nuova = true, testo = "Secondo attacco: colpiscilo con la Lama" },
			{ reach = { x = 1020, y = 150 }, only = { "sword" }, zoom = 2, testo = "Mettiti al riparo dietro il muretto" },
			{ reach = { x = 1120, y = 150 }, only = { "teleport" }, nuova = true, testo = "Raggiungi Favilla oltre il muretto" },
		},
		righe = {
			{ testo = "Ora prova tu!", quando = { evento = "demo_end" } },
			{ highlight = "sword", testo = "Ora il secondo attacco: vai vicino e colpiscilo con la Spada",
				quando = { passo = 1 }, fino = { passo = 2 } },
			{ testo = "Due colpi in un turno, così si fa!", faccia = "ride", secondi = 2, quando = { passo = 2 } },
			{ testo = "Dopo l'attacco restano pochi secondi: mettiti al riparo dietro quel muro!",
				quando = { passo = 2 }, fino = { passo = 3 } },
			{ mostra = "grande", highlight = "teleport", faccia = "ride", quando = { passo = 3 },
				testo = "Come dici? Impossibile? Grazie all'ultima trovata del Fabbro ci si arriva in un attimo. Riceverai dei globi teletrasporto ogni volta che risparmi tempo. Ti mostro come si usano, guarda me!" },
		},
		bravo = "Al sicuro. Così si gioca un turno!",
	},
	-- I globi: attacking early gives orbs, and an orb carries you where it
	-- falls. She attacks at once and throws hers onto the island, then you; there
	-- the target falls at the first hit. The medal: two orbs in one turn
	{
		id = "tempo",
		titolo = "I globi",
		tipo = "bersagli",
		goal_text = "Attacca presto: i secondi che avanzano diventano un globo. Col tasto viola lo lanci e arrivi dove cade. Guarda me!",
		highlight = "missile",
		arena = { { 300, 0, 600, 150 }, { 1200, 100, 320, 50 } },
		spawns = { { x = 600, from = 600 }, { x = 660, from = 600 }, { x = 1350, from = 610 }, { x = 820, from = 600 } },
		giocatori = {
			{ team = 1 },
			{ team = 2, dummy = true },
			{ team = 2, dummy = true },
			{ team = 1, nome = "Favilla", pelle = "favilla", insegna = true },
		},
		vita = { [3] = 10 },
		vedi = { "teleport", "tempo", "missile", "sword" },
		globi = 0,
		medaglia = { testo = "DUE GLOBI IN UN TURNO", at_least = 2, conta = "globi_turno" },
		obiettivo = {
			{
				globi = 1,
				usa = "globi",
				only = { "missile" },
				testo = "Spara presto col Lanciarune: guadagni un globo",
				zoom = 3,
			},
			{
				reach = { x = 1200, y = 150 },
				only = { "teleport" },
				zoom = 2,
				nuova = true,
				testo = "Lancia il globo sull'isola",
			},
			{ hit = 3, only = { "missile", "sword" }, testo = "Colpisci il fantoccio sull'isola" },
		},
		righe = {
			{
				highlight = "teleport",
				testo = "Ora il tasto viola: mira l'isola e lascia, arrivi dove cade il globo",
				quando = { passo = 1 },
				fino = { evento = "teleport" },
			},
			{ secondi = 2, testo = "Eccoti! Ora finiscilo", faccia = "ride", quando = { passo = 2 } },
		},
		dimostra = {
			{
				mosse = {
					{ dice = "Attacco subito..." },
					{ arma = "missile", angolo = 180, potenza = 0.4 },
					{ dice = "...globo! E lo lancio sull'isola" },
					{ arma = "teleport", angolo = 46, potenza = 0.55 },
					{ cammina = 1390 },
					{ arma = "sword", angolo = 179, potenza = 0.1 },
					{ dice = "Ora tu!" },
				},
			},
		},
		bravo = "Così si usano i globi!",
	},
	-- Prima sfida: a short match against Favilla with only what you know (Sergio,
	-- 6 Nov: battles in between, to take the moves in hand). Lanciarune and Lama,
	-- no orbs, no tools, no crates; two minutes, down her once. Nothing explained
	{
		id = "prima_sfida",
		titolo = "Prima sfida",
		tipo = "duello",
		goal_text = "Una sfida veloce, con quello che sai: Lanciarune e Lama. Abbattimi una volta!",
		mappa = "cortile",
		giocatori = {
			{ team = 1 },
			{ team = 2, bot = 1, nome = "Favilla", battute = "favilla", pelle = "favilla",
				stats = { parachutes = 0, teleports = 0, time_orbs = 0 } },
		},
		vedi = { "primarie", "teleport", "tempo", "missile", "sword" },
		regole = { crate_every = 1000 },
		obiettivo = { { down = 2, testo = "Abbatti Favilla" } },
		righe = {
			{ testo = "Tocca a me! Primo attacco e secondo, poi mi riparo", quando = { turno_altri = 1, di_turno = "altri" } },
			{ testo = "Si rinasce subito, e il turno continua", quando = { evento = "death", di = "tu" } },
		},
	},
	-- 4 · Il burrone. Grapple and parachute (Sergio, 30 Oct): no crates, because
	-- they aren't found there. She hooks the platform first, then you; she jumps
	-- off and glides across, then you. No timer
	{
		id = "attrezzi",
		titolo = "Il burrone",
		tipo = "corsa",
		goal_text = "Il Rampino ce l'hai sempre: toccalo, mira il bordo della piattaforma e lascia. Guarda me!",
		highlight = "hook",
		-- your ground, the platform jutting over the gap, the other side
		arena = { { 200, 0, 900, 150 }, { 900, 300, 320, 30 }, { 1360, 0, 560, 150 } },
		spawns = { { x = 640, from = 290 }, { x = 760, from = 290 } },
		giocatori = { { team = 1 }, { team = 1, insegna = true, nome = "Favilla", pelle = "favilla" } },
		vedi = {},
		without_time = true,
		cards = { { dopo = 0, arma = "hook", give = true }, { dopo = 2, arma = "parachute", give = true } },
		dimostra = {
			{ mosse = {
				{ cammina = 850 },
				{ arma = "hook", angolo = 70 },
				{ dice = "Su! Ora tu" },
			} },
			{ quando = { passo = 2 }, mosse = {
				{ dice = "Guarda: mi butto e apro" },
				{ cammina = 1100 },
				{ cammina = 1300 },
				{ arma = "parachute", verso = "destra" },
				{ cammina = 1480 },
				{ dice = "Ora tu!" },
			} },
		},
		-- the medal: across without ever falling into the gap
		medaglia = { conta = "morti", at_most = 0, testo = "PIEDI ASCIUTTI" },
		obiettivo = {
			{ usa = "rampino", only = { "hook" }, testo = "Aggancia il bordo col Rampino" },
			{ reach = { x = 900, y = 330 }, nuova = true, testo = "Sali sulla piattaforma" },
			{ usa = "paracadute", only = { "parachute" }, testo = "Salta nel vuoto e apri il paracadute" },
			{ reach = { x = 1360, y = 150 }, only = { "parachute" }, nuova = true, testo = "Atterra dall'altra parte" },
		},
		righe = {
			{ testo = "Visto? Il Rampino ti porta su", faccia = "ride", secondi = 2, quando = { passo = 2 } },
			{ testo = "Salta nel vuoto ({salta}) e in aria tocca il paracadute: atterri piano. Guarda me!",
				mostra = "grande", highlight = "parachute", stops = false, quando = { passo = 2 } },
		},
		bravo = "Piano piano, senza un graffio. Il paracadute è uno a partita: usalo bene",
	},
	-- 5 · Arriva in cima: two of the secondaries that move you, one crate at a
	-- time (the Affondo comes in the Forgia). She climbs her own lane on the left
	-- with the real weapon first, then you. No timer
	{
		id = "spostano",
		titolo = "Le secondarie",
		tipo = "corsa",
		goal_text = "Arriviamo in cima! Prendi la cassa: dentro troverai un'arma secondaria che ti darà la possibilità di riuscirci",
		-- the first pillar higher than the jump, the second higher than the kickback;
		-- on the left Favilla's lane, two pillars of the same heights (the second
		-- wider: her bounce carries her a bit further)
		arena = { { 230, 0, 1370, 150 }, { 1000, 150, 160, 110 }, { 1160, 150, 300, 310 },
			{ 330, 150, 50, 110 }, { 230, 150, 100, 310 } },
		spawns = { { x = 640, from = 600 }, { x = 470, from = 600 } },
		giocatori = { { team = 1 }, { team = 1, insegna = true, nome = "Favilla", pelle = "favilla" } },
		vedi = {},
		without_time = true,
		casse = {
			{ dopo = 0, arma = "eagle", x = 760 },
			{ dopo = 3, arma = "mallet", x = 1080 },
		},
		dimostra = {
			{ quando = { passo = 1 }, mosse = {
				{ cammina = 420 },
				{ salta = "su", in_aria = true },
				{ arma = "eagle", angolo = 300, subito = true },
				{ dice = "Su! Ora tu" },
			} },
			{ quando = { passo = 4 }, mosse = {
				{ cammina = 350 },
				{ salta = "su", in_aria = true },
				{ arma = "mallet", angolo = 270, subito = true, verso = "sinistra", fino_a = 325 },
				{ posa = "vittoria", secondi = 1 },
			} },
		},
		medaglia = { conta = "misses", at_most = 0, testo = "SENZA SBAGLIARE UN COLPO" },
		obiettivo = {
			{ prendi = "eagle", testo = "Prendi la cassa" },
			{ usa = "kickback", testo = "Salta e spara col Tonante verso il basso" },
			{ reach = { x = 1000, y = 260 }, nuova = true, testo = "Sali sul primo pilastro" },
			{ prendi = "mallet", testo = "Prendi la cassa" },
			{ usa = "pogo", testo = "Salta e colpisci il pilastro col Maglio" },
			{ reach = { x = 1160, y = 460 }, nuova = true, testo = "Sali in cima" },
		},
		righe = {
			{ testo = "Il Tonante ha il rinculo: salta ({salta}) e in aria spara verso il basso, ti spinge in alto. Guarda me!",
				mostra = "grande", highlight = "eagle", quando = { passo = 1 }, fino = { passo = 2 } },
			{ testo = "Su! Adesso il Maglio", faccia = "ride", secondi = 2, quando = { passo = 3 } },
			{ testo = "Il Maglio: salta e colpisci il pilastro sotto di te, rimbalzi in alto. Guarda me!",
				mostra = "grande", highlight = "mallet", quando = { passo = 4 }, fino = { passo = 5 } },
		},
		bravo = "Sei arrivato in cima!",
	},
	-- Sfida sul burrone: the second short match, on a map with gaps where the
	-- tools count: Rampino, parachute and the Tonante next to the Lama. No orbs,
	-- no crates. She uses the Maglio. Down her once
	{
		id = "sfida_burrone",
		titolo = "Sfida sul burrone",
		tipo = "duello",
		goal_text = "Un'altra sfida, sopra il burrone: hai il Rampino, il paracadute e il Tonante. Abbattimi una volta!",
		guidata = true,
		-- two banks and the platform in the middle, over the lava
		arena = { { 200, 0, 700, 150 }, { 1020, 260, 300, 30 }, { 1440, 0, 480, 150 } },
		spawns = { { x = 500, from = 600 }, { x = 1680, from = 600 } },
		regole = { crate_every = 1000 },
		giocatori = {
			{ team = 1, secondary = "eagle" },
			{ team = 2, bot = 1, secondary = "mallet", nome = "Favilla", battute = "favilla", pelle = "favilla",
				stats = { teleports = 0, time_orbs = 0 } },
		},
		vedi = { "primarie", "secondarie", "hook", "parachute", "tempo" },
		secondi = 150,
		al_tempo = "abbattimenti",
		obiettivo = { { down = 2, testo = "Abbatti Favilla" } },
		righe = {
			{ testo = "Si rinasce subito, e il turno continua", quando = { evento = "death", di = "tu" } },
		},
	},
	-- Duello con Favilla, the third sfida and the chapter exam: a first real match,
	-- short, with everything (Sergio, 29 Oct: the last of the Addestramento). No
	-- explanations any more (6 Nov): she plays and comments. You win by downing
	-- her twice; no points (they come in the Forgia). The medal: without being downed
	{
		id = "guidata",
		titolo = "Duello con Favilla",
		tipo = "duello",
		goal_text = "Duello! Fammi vedere cosa hai imparato: abbattimi due volte",
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
			{ testo = "Guarda: due attacchi, una primaria e una secondaria",
				quando = { turno_altri = 1, di_turno = "altri" } },
			{ testo = "Ho attaccato subito: i secondi che avanzano diventano globi",
				quando = { turno_altri = 2, evento = "teleports", di = "altri" } },
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
		-- the points come in here, the first match where they count (the overview of
		-- 6 Nov; the two attacks are known from the cortile): Favilla's turn shows
		-- them, then yours. In the circles the game never stops: strip only
		righe = {
			{ testo = "Da qui contano i punti: danno = punti, abbattere vale 50, buttare nel vuoto altri 50. Guarda i miei!",
				quando = { turno = 1, di_turno = "tu" } },
			{ testo = "Eccoli, i tuoi primi punti!", faccia = "ride", secondi = 2, quando = { evento = "points", di = "tu" } },
			{ testo = "Hai la Corona: sei primo. I colpi su chi è primo valgono 1,5 e abbatterlo 25 in più",
				quando = { corona = "tu" } },
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
		-- the baratto comes in here (from the cortile, 6 Nov), where it's needed:
		-- one orb isn't enough to reach the sniper
		righe = {
			{ testo = "Un globo non basta? Tocca le due frecce sopra il cronometro: il secondo attacco diventa un globo",
				highlight = "baratto", quando = { evento = "teleports", di = "tu" },
				fino = { uno = { { evento = "swap" }, { usato = "secondaria" } } } },
			{ testo = "Ecco un globo in più!", faccia = "ride", secondi = 2, quando = { evento = "swap", di = "tu" } },
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
		-- the Affondo comes here, with its card (it left the cortile, 6 Nov)
		casse = { { dopo = 0, arma = "shards", x = 560 }, { dopo = 0, arma = "lunge", x = 1360 } },
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
		-- the void, with what pushes (the points are told in the first mission)
		righe = {
			{ testo = "Chi cade nel vuoto è abbattuto subito. Il Mantice spinge via, il Rampino tira verso di te: buttali giù!",
				quando = { turno = 1, di_turno = "tu" } },
			{ testo = "Giù! Ne restano meno", faccia = "ride", secondi = 2, quando = { evento = "death", di = "altri" } },
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
