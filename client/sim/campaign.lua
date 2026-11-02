-- The campaign: chapters of missions (sim/missions.lua defines the format and
-- runs them). Chapter 0 is the Addestramento, the lessons: small puzzles that
-- teach one thing only and can't be finished without using it. Then the
-- circles (gironi): each circle a map and a mechanic, closed by its keeper (a
-- bot with a personality, sim/bot.lua M.CARATTERI). A chapter opens with the
-- stars earned in the ones before (serve). Sergio's choices of 29 October 2026
-- (https://claude.ai/artifact/DaLXhFApbxLpa1reyPtenC).
--
-- World coordinates (1920 x 1080, y up). Arenas are steel, so craters don't
-- break the puzzle. The circle numbers (life, turns, stars) are checked by the
-- bot trial (strumenti/arena/collaudo.lua): the second star is at the median
-- point lead of the normal bot playing in your place (Sergio, 31 Oct: in the
-- circles points count, turns don't).
-- Circle opponents are grades (sim/bot.lua M.GRADI, 1 to 10): the Forgia goes
-- from 2 up to 5 and the ally in the Battaglia is a 7 (Sergio, 30 Oct).

local M = {}

local PLAYER = 1

local TRAINING = {
	-- the basics in a single course (Sergio, 29 Oct): walk to the flag, jump onto
	-- the step, take the crate that drops with the Lanciarune (and its card) and
	-- shoot the target. No timer and no turns: if you miss, you retry at once.
	-- Nothing shows up before it's needed
	{
		id = "primi_passi",
		titolo = "Primi passi",
		goal_text = "Cammina fino alla bandierina: {cammina}",
		evidenzia = "cammina",
		-- a step higher than you can walk up, lower than the jump
		arena = { { 240, 0, 1440, 150 }, { 1100, 150, 580, 30 } },
		spawns = { { x = 480, from = 600 }, { x = 1560, from = 600 } },
		giocatori = { { team = 1 }, { team = 2, dummy = true } },
		vedi = { "missile" },
		no_weapons = true, senza_tempo = true,
		casse = { { dopo = 2, arma = "missile", x = 1260 } },
		stelle = {
			bonus = { conta = "misses", at_most = 2, testo = "AL MASSIMO 2 TIRI A VUOTO" },
			bonus2 = { conta = "misses", at_most = 0, testo = "AL PRIMO TIRO" },
		},
		obiettivo = {
			{ reach = { x = 720, y = 150 }, bandiera = true, testo = "Raggiungi la bandierina" },
			{ reach = { x = 1100, y = 180 }, testo = "Salta sul gradino" },
			{ prendi = "missile", testo = "Prendi la cassa" },
			{ hit = 2, con = "missile", testo = "Colpisci il bersaglio" },
		},
		righe = {
			{ testo = "Il gradino è troppo alto per camminarci sopra: {salta}", evidenzia = "salta",
				quando = { passo = 1 }, fino = { passo = 2 } },
			{ testo = "Una cassa cade dal cielo: prendila!", quando = { passo = 2 }, fino = { passo = 3 } },
			{ testo = "Colpisci il bersaglio: {mira}", evidenzia = "mira", quando = { passo = 3 } },
			-- while aiming: how to cancel
			{ testo = "Più tiri lontano, più forte parte. Se cambi idea, {annulla}", evidenzia = "annulla",
				subito = true, quando = function(st) return st.steps_done[3] and st.touched_cmds.mira end,
				fino = function(st, g) return st.touched_cmds.annulla or g.used.primary end },
		},
	},
	-- The turn (Sergio, 30 Oct): the timer shows from here, and only the
	-- Lanciarune and the Lama are used, the always-available weapons. Attacking
	-- early gives orbs (time stops before you lose them), the Lama on the first
	-- target, the orb carries you to the island of the second, which falls at the
	-- first hit: the second attack isn't needed and is bartered for an orb, which
	-- brings you back to the first.
	-- Each step is done with what it says (only), the rest is disabled
	{
		id = "turno",
		titolo = "Il turno",
		goal_text = "Il cronometro in basso è il tuo turno. Attacca presto: guadagni globi",
		evidenzia = "missile",
		-- your ground, the gap, and the island of the second target
		arena = { { 300, 0, 600, 150 }, { 1200, 100, 320, 50 } },
		spawns = { { x = 600, from = 600 }, { x = 660, from = 600 }, { x = 1440, from = 600 } },
		giocatori = { { team = 1 }, { team = 2, dummy = true }, { team = 2, dummy = true } },
		-- the one on the island falls at the first hit
		vita = { [3] = 10 },
		vedi = { "missile", "sword", "teleport", "tempo", "baratto" },
		globi = 0,
		cards = { { dopo = 1, arma = "sword" } },
		stelle = {
			bonus = { conta = "misses", at_most = 2, testo = "AL MASSIMO 2 COLPI A VUOTO" },
			bonus2 = { conta = "misses", at_most = 0, testo = "SENZA SBAGLIARE" },
		},
		obiettivo = {
			{ usa = "globi", globi = 2, only = { "missile" }, testo = "Spara col Lanciarune: guadagni globi" },
			{ hit = 2, con = "sword", only = { "sword" }, testo = "Secondo attacco: colpisci con la Lama" },
			{ reach = { x = 1200, y = 150 }, only = { "teleport" }, zoom = 2, testo = "Teletrasportati sull'isola" },
			{ hit = 3, only = { "missile", "sword" }, testo = "Colpisci il bersaglio sull'isola" },
			{ usa = "baratto", only = { "baratto" }, testo = "Baratta il secondo attacco con un globo" },
			{ hit = 2, only = { "teleport", "missile", "sword" }, testo = "Torna dal primo bersaglio e colpiscilo" },
		},
		righe = {
			{ testo = "Secondo attacco, la Lama: {mira}", evidenzia = "sword",
				quando = { passo = 1 }, fino = { passo = 2 } },
			{ testo = "Tocca il tasto viola, mira l'isola e lascia: arrivi dove cade il globo", evidenzia = "teleport",
				quando = { passo = 2 }, fino = { evento = "teleport" } },
			{ testo = "Lanciarune e Lama non finiscono mai: le uniche armi coi colpi infiniti",
				quando = { evento = "teleport" } },
			{ testo = "Abbattuto: il secondo attacco non serve. Tocca le due frecce sopra il cronometro: diventa un globo",
				evidenzia = "baratto", quando = { passo = 4 }, fino = { passo = 5 } },
			{ testo = "Il prossimo turno torna col globo dal primo bersaglio e colpiscilo come vuoi",
				quando = { passo = 5 } },
		},
	},
	-- Weapons that move you: the secondaries, one crate at a time. The Tonante
	-- (kickback onto the first pillar), the Maglio (pogo onto the second), the
	-- Affondo on the target. No timer: each attempt restarts at once
	{
		id = "spostano",
		titolo = "Armi che ti muovono",
		goal_text = "Prendi la cassa: dentro c'è un'arma che ti sposta",
		-- the first pillar higher than the jump, the second higher than the kickback
		arena = { { 300, 0, 1300, 150 }, { 1000, 150, 160, 110 }, { 1160, 150, 300, 310 } },
		spawns = { { x = 640, from = 600 }, { x = 1400, from = 1000 } },
		giocatori = { { team = 1 }, { team = 2, dummy = true } },
		vedi = { "missile", "sword" },
		senza_tempo = true,
		casse = {
			{ dopo = 0, arma = "eagle", x = 760 },
			{ dopo = 3, arma = "mallet", x = 1080 },
			{ dopo = 6, arma = "lunge", x = 1240 },
		},
		stelle = {
			bonus = { conta = "misses", at_most = 3, testo = "AL MASSIMO 3 TENTATIVI A VUOTO" },
			bonus2 = { conta = "misses", at_most = 0, testo = "SENZA SBAGLIARE" },
		},
		obiettivo = {
			{ prendi = "eagle", testo = "Prendi la cassa" },
			{ usa = "kickback", testo = "Salta e spara col Tonante verso il basso" },
			{ reach = { x = 1000, y = 260 }, testo = "Sali sul primo pilastro" },
			{ prendi = "mallet", testo = "Prendi la cassa" },
			{ usa = "pogo", testo = "Salta e colpisci il pilastro col Maglio" },
			{ reach = { x = 1160, y = 460 }, testo = "Sali sul secondo pilastro" },
			{ prendi = "lunge", testo = "Prendi la cassa" },
			{ hit = 2, con = "lunge", testo = "Colpisci il bersaglio con l'Affondo" },
		},
		righe = {
			{ testo = "Il Tonante ha il rinculo: ti spinge dall'altra parte del colpo. Toccalo",
				evidenzia = "eagle", quando = { passo = 1 }, fino = { tocca = "eagle" } },
			{ testo = "Salta ({salta}) e in aria spara verso il basso: il rinculo ti porta su",
				evidenzia = "salta", quando = { tocca = "eagle" }, fino = { passo = 3 } },
			{ testo = "Colpisci il pilastro col Maglio: rimbalzi in alto. Saltando ({salta}) arrivi più su",
				evidenzia = "mallet", quando = { passo = 4 }, fino = { tocca = "mallet" } },
			{ testo = "L'Affondo è uno scatto: passa oltre chi hai davanti e lo colpisce", evidenzia = "lunge",
				quando = { passo = 7 }, fino = { tocca = "lunge" } },
			{ testo = "Una secondaria a partita, oltre alla Lama: la scegli all'inizio", quando = { passo = 8 } },
		},
	},
	-- Grapple and parachute (Sergio, 30 Oct): no crates, because they aren't found
	-- there; after a few steps the card opens and the button lights up. The
	-- grapple carries you onto the platform, with the parachute you go down past
	-- the gap, and over there the Lama on the target. No timer
	{
		id = "attrezzi",
		titolo = "Rampino e paracadute",
		goal_text = "Il bersaglio è dall'altra parte del vuoto. Vai sotto la piattaforma",
		-- your ground, the platform jutting over the gap, the other side
		arena = { { 200, 0, 900, 150 }, { 900, 300, 320, 30 }, { 1360, 0, 560, 150 } },
		spawns = { { x = 640, from = 290 }, { x = 1520, from = 600 } },
		giocatori = { { team = 1 }, { team = 2, dummy = true } },
		vedi = { "sword" },
		senza_tempo = true,
		cards = { { dopo = 1, arma = "hook", give = true }, { dopo = 3, arma = "parachute", give = true } },
		stelle = {
			bonus = { conta = "misses", at_most = 3, testo = "AL MASSIMO 3 TENTATIVI A VUOTO" },
			bonus2 = { conta = "misses", at_most = 0, testo = "SENZA SBAGLIARE" },
		},
		obiettivo = {
			{ reach = { x = 820, y = 150 }, bandiera = true, testo = "Vai sotto la piattaforma" },
			{ usa = "rampino", only = { "hook" }, testo = "Aggancia il bordo col Rampino" },
			{ reach = { x = 900, y = 330 }, testo = "Sali sulla piattaforma" },
			{ usa = "paracadute", only = { "parachute" }, testo = "Salta nel vuoto e apri il paracadute" },
			{ reach = { x = 1360, y = 150 }, only = { "parachute" }, testo = "Atterra dall'altra parte" },
			{ hit = 2, con = "sword", only = { "sword" }, testo = "Colpisci il bersaglio con la Lama" },
		},
		righe = {
			{ testo = "Il Rampino: toccalo, poi mira il bordo della piattaforma e lascia", evidenzia = "hook",
				quando = { passo = 1 }, fino = { tocca = "hook" } },
			{ testo = "Su un nemico, invece, il Rampino lo tira da te", quando = { passo = 3 } },
			{ testo = "Salta nel vuoto ({salta}) e in aria tocca il paracadute, fra gli OGGETTI",
				evidenzia = "parachute", stops = false, quando = { passo = 3 }, fino = { evento = "parachute" } },
			{ testo = "Il paracadute è uno a partita: atterri piano e senza farti male", quando = { passo = 4 } },
		},
	},
	-- Points and Crown: points show from here. The Mantice throws into the void
	-- (50 extra points), the Pugno cracks the armour, and whoever has the Crown
	-- is worth more. No timer
	{
		id = "punti",
		titolo = "Punti e Corona",
		goal_text = "Prendi la cassa: dentro c'è un'arma che spinge",
		arena = { { 240, 0, 1440, 150 } },
		spawns = { { x = 520, from = 600 }, { x = 290, from = 600 }, { x = 1320, from = 600 }, { x = 1000, from = 600 } },
		giocatori = { { team = 1 }, { team = 2, dummy = true }, { team = 3, dummy = true }, { team = 4, dummy = true } },
		vedi = { "missile", "sword", "punti" },
		senza_tempo = true,
		-- the fourth target is first in the standings: it has the Crown
		punti = { [2] = 40, [3] = 60, [4] = 200 },
		vita = { [2] = 100, [3] = 100, [4] = 60 },
		casse = { { dopo = 0, arma = "bellows", x = 600 }, { dopo = 2, arma = "punch", x = 760 } },
		stelle = {
			bonus = { conta = "misses", at_most = 3, testo = "AL MASSIMO 3 TENTATIVI A VUOTO" },
			bonus2 = { conta = "misses", at_most = 0, testo = "SENZA SBAGLIARE" },
		},
		obiettivo = {
			{ prendi = "bellows", testo = "Prendi la cassa" },
			{ down = 2, come = "vuoto", testo = "Butta il bersaglio nel vuoto col Mantice" },
			{ prendi = "punch", testo = "Prendi la cassa" },
			{ hit = 4, con = "punch", testo = "Colpisci chi ha la Corona col Pugno" },
			{ down = 4, testo = "Abbatti chi ha la Corona" },
		},
		righe = {
			{ testo = "Il Mantice spinge via chi hai davanti: buttalo giù dal bordo", evidenzia = "bellows",
				quando = { passo = 1 }, fino = { tocca = "bellows" } },
			{ testo = "Danno = punti. Abbattere vale 50, buttare nel vuoto altri 50", quando = { passo = 2 } },
			{ testo = "Chi ha la Corona è primo: i colpi su di lui valgono 1,5 e abbatterlo 25 in più",
				quando = { passo = 3 } },
			{ testo = "Il Pugno incrina l'armatura: il colpo dopo toglie di più", evidenzia = "punch",
				quando = { passo = 3 }, fino = { tocca = "punch" } },
		},
	},
	-- the chapter exam: a first real match, short, that puts everything into
	-- practice (Sergio, 29 Oct: the last of the Addestramento, not the first)
	{
		id = "guidata",
		titolo = "Prima partita",
		goal_text = "Trascina dal diavoletto per mirare, lascia per sparare",
		guidata = true,
		mappa = "pavimento",
		giocatori = {
			-- no draft (Sergio, 30 Oct): Lanciarune, Lama and Rampino; the other weapons,
			-- if you want them, from crates, with their card
			{ team = 1 },
			{ team = 2, bot = 1, pick = "grenade", secondary = "mallet" },
		},
		-- short match: 3 minutes
		secondi = 180,
		-- the bot shows in its turn what the player will do in the next turn
		plans = { { due_attacchi = true }, { attacca_entro = 4, poi = "teletrasporto" } },
		obiettivo = function(st) return st.finished end,
		righe = {
			{ testo = "Hai 8 secondi: mettiti al riparo. Per saltare {salta}", evidenzia = "salta",
				quando = function(st, g) return st.turni == 1 and g.current == PLAYER and g.window > 0 end },
			{ testo = "Il bot fa due attacchi: una primaria e una secondaria", su = "bot",
				quando = function(st, g) return st.bot_turns == 1 and g.current ~= PLAYER end },
			{ testo = "Due attacchi a turno. Prima la primaria, a sinistra del cronometro: toccala",
				evidenzia = "primaria",
				quando = function(st, g) return st.turni == 2 and g.current == PLAYER end,
				fino = function(_, g) return g.used.primary end },
			{ testo = "Ora la secondaria, a destra del cronometro: toccala e colpisci", evidenzia = "secondaria",
				quando = function(st, g) return st.turni == 2 and g.current == PLAYER and g.used.primary end,
				fino = function(_, g) return g.used.secondary end },
			{ testo = "Ha attaccato subito: i secondi che avanzano diventano globi", su = "bot",
				quando = function(st, _, e) return st.bot_turns == 2 and e and e.type == "teleports" and e.robot ~= PLAYER end },
			{ testo = "Attacca presto: prima delle tacche viola sull'anello guadagni globi",
				quando = function(st, g) return st.turni == 3 and g.current == PLAYER end,
				fino = function(_, g) return g.used.primary or g.used.secondary end },
			{ testo = "Lancia un globo col tasto viola: arrivi dove cade", evidenzia = "teleport",
				quando = function(st, _, e) return st.turni == 3 and e and e.type == "teleports" and e.robot == PLAYER end,
				fino = { evento = "teleport" } },
			{ testo = "Passaci sopra per prenderla: dentro c'è un'arma o un oggetto",
				quando = { evento = "crate" }, fino = { evento = "crate_pick" } },
			{ testo = "Tocca in aria per il paracadute: uno a partita", evidenzia = "parachute", stops = false,
				quando = function(_, g)
					local rb = g.robots[PLAYER]
					return g.current == PLAYER and not rb.grounded and rb.vy < -220 and rb.parachutes_left > 0
				end,
				fino = { evento = "parachute" } },
			{ testo = "Sei primo: chi ti colpisce prende i punti per 1,5",
				quando = function(_, g) return g:leader() == g.robots[PLAYER] end },
			{ testo = "Si rinasce subito, e il turno continua",
				quando = function(_, _, e) return e and e.type == "death" and e.robot == PLAYER end },
		},
	},
}

-- Circle I: the Forgia. Two attacks, orbs from saved time, pushing into the
-- void; the keeper is the Fabbro. Opponents are real bots.
local CIRCLE_1 = {
	{
		id = "primo_sangue",
		titolo = "Primo sangue",
		goal_text = "Abbatti il bot: un'arma a sinistra e una a destra del cronometro",
		mappa = "pavimento",
		giocatori = { { team = 1 }, { team = 2, bot = 2 } },
		-- the weapons the Addestramento doesn't introduce are found in the circle (Claude)
		casse = { { dopo = 0, arma = "grenade", x = 405 } },
		turni = 7,
		stelle = { punti = 110, bonus = { conta = "morti", at_most = 0, testo = "SENZA MORIRE" } },
		obiettivo = { { down = 2, testo = "Abbatti il bot" } },
		-- in the circles the hints highlight the control but the game doesn't stop
		righe = {
			{ testo = "Prima la primaria, a sinistra del cronometro", evidenzia = "primaria",
				quando = { turno = 2 }, fino = function(_, g) return g.used.primary end },
			{ testo = "Poi la secondaria, a destra", evidenzia = "secondaria",
				quando = function(st, g) return st.turni == 2 and g.current == PLAYER and g.used.primary end,
				fino = function(_, g) return g.used.secondary end },
		},
	},
	{
		id = "fuori_portata",
		titolo = "Fuori portata",
		goal_text = "Il cecchino sta sull'isola. Attacca presto per avere i globi, poi raggiungilo",
		arena = { { 200, 0, 720, 150 }, { 1240, 120, 460, 50 } },
		spawns = { { x = 500, from = 600 }, { x = 1520, from = 600 } },
		giocatori = { { team = 1 }, { team = 2, bot = 2, carattere = "cecchino" } },
		globi = 0,
		vita = { [2] = 55 },
		turni = 6,
		stelle = { punti = 100, bonus = { conta = "teletrasporti", at_most = 1, testo = "CON UN SOLO GLOBO" } },
		obiettivo = {
			{ usa = "globi", testo = "Attacca presto: guadagna un globo" },
			{ down = 2, con = "sword", testo = "Finisci il cecchino con la Lama" },
		},
		righe = {
			{ testo = "Ora il tasto viola: il globo ti porta dove cade", evidenzia = "teleport",
				quando = { evento = "teleports" }, fino = { evento = "teleport" } },
		},
		-- you can't get there without teleport
		collaudo = { senza = { teletrasporto = false } },
	},
	{
		id = "due_mani",
		titolo = "Due mani",
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
		-- the bot testing it looks for the void
		collaudo = { carattere = "spingitore" },
	},
	{
		id = "il_codardo",
		titolo = "Il codardo",
		goal_text = "Colpisce a ogni turno e scappa col globo nelle tane: stanalo col tuo",
		mappa = "pavimento",
		giocatori = { { team = 1 }, { team = 2, bot = 4, carattere = "codardo", nome = "Il codardo" } },
		turni = 7,
		stelle = { punti = 120, bonus = { conta = "morti", at_most = 0, testo = "SENZA MORIRE" } },
		obiettivo = { { down = 2, testo = "Abbatti il codardo" } },
	},
	{
		id = "il_fabbro",
		titolo = "Il Fabbro",
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
		goal_text = "Una partita vera, 2 contro 2: tu e il tuo compagno contro il Fabbro e il cecchino",
		mappa = "pavimento",
		-- the first weapon draft, guided, with the weapons already seen (Sergio, 30 Oct)
		draft = true,
		giocatori = {
			{ team = 1 },
			{ team = 2, bot = 5, carattere = "testa_calda", secondary = "mallet", nome = "Il Fabbro",
				battute = "fabbro" },
			{ team = 1, bot = 7, nome = "Compagno" },
			{ team = 2, bot = 2, carattere = "cecchino" },
		},
		-- no turn limit: play until time runs out
		stelle = { punti = 160, bonus = { conta = "abbattuti", at_least = 3, testo = "ABBATTINE 3" } },
		obiettivo = { { win = true, testo = "Vinci la partita con il tuo compagno" } },
	},
}

-- serve: the stars (from all chapters) needed to open the chapter
M.CAPITOLI = {
	{ id = "addestramento", titolo = "Addestramento", serve = 0, missioni = TRAINING, aspetta = true },
	{ id = "girone_1", titolo = "I girone: la Forgia", serve = 8, missioni = CIRCLE_1 },
}

return M
