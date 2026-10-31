-- La campagna: capitoli di missioni (sim/missioni.lua dice il formato e le fa
-- girare). Il Capitolo 0 è l'Addestramento, le lezioni: piccoli rompicapi che
-- insegnano una cosa sola e non si finiscono senza usarla. Poi i gironi: ogni
-- girone una mappa e una meccanica, chiuso dal suo custode (un bot con un
-- carattere, sim/bot.lua M.CARATTERI). Un capitolo si apre con le stelle prese
-- in quelli prima (serve). Scelte di Sergio del 29 ottobre 2026
-- (https://claude.ai/artifact/DaLXhFApbxLpa1reyPtenC).
--
-- Coordinate del mondo (1920 x 1080, y in alto). Le arene sono d'acciaio, così
-- i crateri non rompono il rompicapo. I numeri dei gironi (vita, turni, stelle)
-- li controlla il collaudo coi bot (strumenti/arena/collaudo.lua): la seconda
-- stella è alla mediana dei punti di vantaggio del bot normale che gioca al
-- posto tuo (Sergio, 31 ott: nei gironi i punti contano, i turni no).
-- Gli avversari dei gironi sono gradi (sim/bot.lua M.GRADI, da 1 a 10): la
-- Forgia sale dal 2 al 5 e il compagno della Battaglia è un 7 (Sergio, 30 ott).

local M = {}

local GIOCATORE = 1

local ADDESTRAMENTO = {
	-- le basi in un percorso solo (Sergio, 29 ott): cammini fino alla
	-- bandierina, salti sul gradino, prendi la cassa che cade col Lanciarune (e
	-- la sua scheda) e spari al bersaglio. Niente tempo e niente turni: se manchi,
	-- ritenti subito. Niente si vede prima di servire
	{
		id = "primi_passi",
		titolo = "Primi passi",
		scopo = "Cammina fino alla bandierina: {cammina}",
		evidenzia = "cammina",
		-- un gradino più alto di quello che si sale camminando, più basso del salto
		arena = { { 240, 0, 1440, 150 }, { 1100, 150, 580, 30 } },
		spawns = { { x = 480, from = 600 }, { x = 1560, from = 600 } },
		giocatori = { { team = 1 }, { team = 2, dummy = true } },
		vedi = { "missile" },
		senza_armi = true, senza_tempo = true,
		casse = { { dopo = 2, arma = "missile", x = 1260 } },
		stelle = {
			bonus = { conta = "mancati", al_massimo = 2, testo = "AL MASSIMO 2 TIRI A VUOTO" },
			bonus2 = { conta = "mancati", al_massimo = 0, testo = "AL PRIMO TIRO" },
		},
		obiettivo = {
			{ raggiungi = { x = 720, y = 150 }, bandiera = true, testo = "Raggiungi la bandierina" },
			{ raggiungi = { x = 1100, y = 180 }, testo = "Salta sul gradino" },
			{ prendi = "missile", testo = "Prendi la cassa" },
			{ colpisci = 2, con = "missile", testo = "Colpisci il bersaglio" },
		},
		righe = {
			{ testo = "Il gradino è troppo alto per camminarci sopra: {salta}", evidenzia = "salta",
				quando = { passo = 1 }, fino = { passo = 2 } },
			{ testo = "Una cassa cade dal cielo: prendila!", quando = { passo = 2 }, fino = { passo = 3 } },
			{ testo = "Colpisci il bersaglio: {mira}", evidenzia = "mira", quando = { passo = 3 } },
			-- mentre mira: come si annulla
			{ testo = "Più tiri lontano, più forte parte. Se cambi idea, {annulla}", evidenzia = "annulla",
				subito = true, quando = function(st) return st.passi[3] and st.toccati.mira end,
				fino = function(st, g) return st.toccati.annulla or g.used.primary end },
		},
	},
	-- Il turno (Sergio, 30 ott): il cronometro si vede da qui, e si usano solo
	-- il Lanciarune e la Lama, le armi di sempre. Attaccare presto dà i globi
	-- (il tempo si ferma prima di perderli), la Lama sul primo bersaglio, il
	-- globo porta sull'isola dal secondo, che cade al primo colpo: il secondo
	-- attacco non serve e si baratta con un globo, che riporta dal primo.
	-- Ogni passo si fa con quello che dice (solo), il resto è spento
	{
		id = "turno",
		titolo = "Il turno",
		scopo = "Il cronometro in basso è il tuo turno. Attacca presto: guadagni globi",
		evidenzia = "missile",
		-- la tua terra, il vuoto, e l'isola del secondo bersaglio
		arena = { { 300, 0, 600, 150 }, { 1200, 100, 320, 50 } },
		spawns = { { x = 600, from = 600 }, { x = 660, from = 600 }, { x = 1440, from = 600 } },
		giocatori = { { team = 1 }, { team = 2, dummy = true }, { team = 2, dummy = true } },
		-- quello sull'isola cade al primo colpo
		vita = { [3] = 10 },
		vedi = { "missile", "sword", "teleport", "tempo", "baratto" },
		globi = 0,
		schede = { { dopo = 1, arma = "sword" } },
		stelle = {
			bonus = { conta = "mancati", al_massimo = 2, testo = "AL MASSIMO 2 COLPI A VUOTO" },
			bonus2 = { conta = "mancati", al_massimo = 0, testo = "SENZA SBAGLIARE" },
		},
		obiettivo = {
			{ usa = "globi", globi = 2, solo = { "missile" }, testo = "Spara col Lanciarune: guadagni globi" },
			{ colpisci = 2, con = "sword", solo = { "sword" }, testo = "Secondo attacco: colpisci con la Lama" },
			{ raggiungi = { x = 1200, y = 150 }, solo = { "teleport" }, zoom = 2, testo = "Teletrasportati sull'isola" },
			{ colpisci = 3, solo = { "missile", "sword" }, testo = "Colpisci il bersaglio sull'isola" },
			{ usa = "baratto", solo = { "baratto" }, testo = "Baratta il secondo attacco con un globo" },
			{ colpisci = 2, solo = { "teleport", "missile", "sword" }, testo = "Torna dal primo bersaglio e colpiscilo" },
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
	-- Armi che ti muovono: le secondarie, una cassa per volta. Il Tonante
	-- (il rinculo sul primo pilastro), il Maglio (il rimbalzo sul secondo),
	-- l'Affondo sul bersaglio. Niente tempo: ogni tentativo torna subito
	{
		id = "spostano",
		titolo = "Armi che ti muovono",
		scopo = "Prendi la cassa: dentro c'è un'arma che ti sposta",
		-- il primo pilastro più alto del salto, il secondo più alto del rinculo
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
			bonus = { conta = "mancati", al_massimo = 3, testo = "AL MASSIMO 3 TENTATIVI A VUOTO" },
			bonus2 = { conta = "mancati", al_massimo = 0, testo = "SENZA SBAGLIARE" },
		},
		obiettivo = {
			{ prendi = "eagle", testo = "Prendi la cassa" },
			{ usa = "rinculo", testo = "Salta e spara col Tonante verso il basso" },
			{ raggiungi = { x = 1000, y = 260 }, testo = "Sali sul primo pilastro" },
			{ prendi = "mallet", testo = "Prendi la cassa" },
			{ usa = "rimbalzo", testo = "Salta e colpisci il pilastro col Maglio" },
			{ raggiungi = { x = 1160, y = 460 }, testo = "Sali sul secondo pilastro" },
			{ prendi = "lunge", testo = "Prendi la cassa" },
			{ colpisci = 2, con = "lunge", testo = "Colpisci il bersaglio con l'Affondo" },
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
	-- Rampino e paracadute (Sergio, 30 ott): niente casse, perché non si trovano
	-- lì; dopo qualche passo si apre la scheda e il tasto si accende. Il
	-- Rampino porta sulla piattaforma, col paracadute si scende oltre il vuoto,
	-- e di là la Lama sul bersaglio. Niente tempo
	{
		id = "attrezzi",
		titolo = "Rampino e paracadute",
		scopo = "Il bersaglio è dall'altra parte del vuoto. Vai sotto la piattaforma",
		-- la tua terra, la piattaforma che sporge sul vuoto, l'altra parte
		arena = { { 200, 0, 900, 150 }, { 900, 300, 320, 30 }, { 1360, 0, 560, 150 } },
		spawns = { { x = 640, from = 290 }, { x = 1520, from = 600 } },
		giocatori = { { team = 1 }, { team = 2, dummy = true } },
		vedi = { "sword" },
		senza_tempo = true,
		schede = { { dopo = 1, arma = "hook", dai = true }, { dopo = 3, arma = "parachute", dai = true } },
		stelle = {
			bonus = { conta = "mancati", al_massimo = 3, testo = "AL MASSIMO 3 TENTATIVI A VUOTO" },
			bonus2 = { conta = "mancati", al_massimo = 0, testo = "SENZA SBAGLIARE" },
		},
		obiettivo = {
			{ raggiungi = { x = 820, y = 150 }, bandiera = true, testo = "Vai sotto la piattaforma" },
			{ usa = "rampino", solo = { "hook" }, testo = "Aggancia il bordo col Rampino" },
			{ raggiungi = { x = 900, y = 330 }, testo = "Sali sulla piattaforma" },
			{ usa = "paracadute", solo = { "parachute" }, testo = "Salta nel vuoto e apri il paracadute" },
			{ raggiungi = { x = 1360, y = 150 }, solo = { "parachute" }, testo = "Atterra dall'altra parte" },
			{ colpisci = 2, con = "sword", solo = { "sword" }, testo = "Colpisci il bersaglio con la Lama" },
		},
		righe = {
			{ testo = "Il Rampino: toccalo, poi mira il bordo della piattaforma e lascia", evidenzia = "hook",
				quando = { passo = 1 }, fino = { tocca = "hook" } },
			{ testo = "Su un nemico, invece, il Rampino lo tira da te", quando = { passo = 3 } },
			{ testo = "Salta nel vuoto ({salta}) e in aria tocca il paracadute, fra gli OGGETTI",
				evidenzia = "parachute", ferma = false, quando = { passo = 3 }, fino = { evento = "parachute" } },
			{ testo = "Il paracadute è uno a partita: atterri piano e senza farti male", quando = { passo = 4 } },
		},
	},
	-- Punti e Corona: i punti si vedono da qui. Il Mantice butta nel vuoto
	-- (50 punti in più), il Pugno incrina l'armatura, e chi ha la Corona vale
	-- di più. Niente tempo
	{
		id = "punti",
		titolo = "Punti e Corona",
		scopo = "Prendi la cassa: dentro c'è un'arma che spinge",
		arena = { { 240, 0, 1440, 150 } },
		spawns = { { x = 520, from = 600 }, { x = 290, from = 600 }, { x = 1320, from = 600 }, { x = 1000, from = 600 } },
		giocatori = { { team = 1 }, { team = 2, dummy = true }, { team = 3, dummy = true }, { team = 4, dummy = true } },
		vedi = { "missile", "sword", "punti" },
		senza_tempo = true,
		-- il quarto bersaglio è primo in classifica: ha la Corona
		punti = { [2] = 40, [3] = 60, [4] = 200 },
		vita = { [2] = 100, [3] = 100, [4] = 60 },
		casse = { { dopo = 0, arma = "bellows", x = 600 }, { dopo = 2, arma = "punch", x = 760 } },
		stelle = {
			bonus = { conta = "mancati", al_massimo = 3, testo = "AL MASSIMO 3 TENTATIVI A VUOTO" },
			bonus2 = { conta = "mancati", al_massimo = 0, testo = "SENZA SBAGLIARE" },
		},
		obiettivo = {
			{ prendi = "bellows", testo = "Prendi la cassa" },
			{ abbatti = 2, come = "vuoto", testo = "Butta il bersaglio nel vuoto col Mantice" },
			{ prendi = "punch", testo = "Prendi la cassa" },
			{ colpisci = 4, con = "punch", testo = "Colpisci chi ha la Corona col Pugno" },
			{ abbatti = 4, testo = "Abbatti chi ha la Corona" },
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
	-- l'esame del capitolo: una prima vera partita, corta, che mette in pratica
	-- tutto (Sergio, 29 ott: l'ultima dell'Addestramento, non la prima)
	{
		id = "guidata",
		titolo = "Prima partita",
		scopo = "Trascina dal diavoletto per mirare, lascia per sparare",
		guidata = true,
		mappa = "forgia",
		giocatori = {
			-- niente scelta (Sergio, 30 ott): Lanciarune, Lama e Rampino; le altre
			-- armi, se vuoi, dalle casse, con la loro scheda
			{ team = 1 },
			{ team = 2, bot = 1, pick = "grenade", secondary = "mallet" },
		},
		-- partita corta: 3 minuti
		secondi = 180,
		-- il bot fa vedere nel suo turno quello che il giocatore farà nel turno dopo
		piani = { { due_attacchi = true }, { attacca_entro = 4, poi = "teletrasporto" } },
		obiettivo = function(st) return st.finita end,
		righe = {
			{ testo = "Hai 8 secondi: mettiti al riparo. Per saltare {salta}", evidenzia = "salta",
				quando = function(st, g) return st.turni == 1 and g.current == GIOCATORE and g.window > 0 end },
			{ testo = "Il bot fa due attacchi: una primaria e una secondaria", su = "bot",
				quando = function(st, g) return st.turni_bot == 1 and g.current ~= GIOCATORE end },
			{ testo = "Due attacchi a turno. Prima la primaria, a sinistra del cronometro: toccala",
				evidenzia = "primaria",
				quando = function(st, g) return st.turni == 2 and g.current == GIOCATORE end,
				fino = function(_, g) return g.used.primary end },
			{ testo = "Ora la secondaria, a destra del cronometro: toccala e colpisci", evidenzia = "secondaria",
				quando = function(st, g) return st.turni == 2 and g.current == GIOCATORE and g.used.primary end,
				fino = function(_, g) return g.used.secondary end },
			{ testo = "Ha attaccato subito: i secondi che avanzano diventano globi", su = "bot",
				quando = function(st, _, e) return st.turni_bot == 2 and e and e.type == "teleports" and e.robot ~= GIOCATORE end },
			{ testo = "Attacca presto: prima delle tacche viola sull'anello guadagni globi",
				quando = function(st, g) return st.turni == 3 and g.current == GIOCATORE end,
				fino = function(_, g) return g.used.primary or g.used.secondary end },
			{ testo = "Lancia un globo col tasto viola: arrivi dove cade", evidenzia = "teleport",
				quando = function(st, _, e) return st.turni == 3 and e and e.type == "teleports" and e.robot == GIOCATORE end,
				fino = { evento = "teleport" } },
			{ testo = "Passaci sopra per prenderla: dentro c'è un'arma o un oggetto",
				quando = { evento = "crate" }, fino = { evento = "crate_pick" } },
			{ testo = "Tocca in aria per il paracadute: uno a partita", evidenzia = "parachute", ferma = false,
				quando = function(_, g)
					local rb = g.robots[GIOCATORE]
					return g.current == GIOCATORE and not rb.grounded and rb.vy < -220 and rb.parachutes_left > 0
				end,
				fino = { evento = "parachute" } },
			{ testo = "Sei primo: chi ti colpisce prende i punti per 1,5",
				quando = function(_, g) return g:leader() == g.robots[GIOCATORE] end },
			{ testo = "Si rinasce subito, e il turno continua",
				quando = function(_, _, e) return e and e.type == "death" and e.robot == GIOCATORE end },
		},
	},
}

-- I girone: la Forgia. Due attacchi, globi dal tempo risparmiato, la spinta
-- nel vuoto; il custode è il Fabbro. Gli avversari sono bot veri.
local GIRONE_1 = {
	{
		id = "primo_sangue",
		titolo = "Primo sangue",
		scopo = "Abbatti il bot: un'arma a sinistra e una a destra del cronometro",
		mappa = "forgia",
		giocatori = { { team = 1 }, { team = 2, bot = 2 } },
		-- le armi che l'Addestramento non presenta si trovano nel girone (Claude)
		casse = { { dopo = 0, arma = "grenade", x = 620 } },
		turni = 7,
		stelle = { punti = 100, bonus = { conta = "morti", al_massimo = 0, testo = "SENZA MORIRE" } },
		obiettivo = { { abbatti = 2, testo = "Abbatti il bot" } },
		-- nei gironi i consigli mettono in luce il comando ma il gioco non si ferma
		righe = {
			{ testo = "Prima la primaria, a sinistra del cronometro", evidenzia = "primaria",
				quando = { turno = 2 }, fino = function(_, g) return g.used.primary end },
			{ testo = "Poi la secondaria, a destra", evidenzia = "secondaria",
				quando = function(st, g) return st.turni == 2 and g.current == GIOCATORE and g.used.primary end,
				fino = function(_, g) return g.used.secondary end },
		},
	},
	{
		id = "fuori_portata",
		titolo = "Fuori portata",
		scopo = "Il cecchino sta sull'isola. Attacca presto per avere i globi, poi raggiungilo",
		arena = { { 200, 0, 720, 150 }, { 1240, 120, 460, 50 } },
		spawns = { { x = 500, from = 600 }, { x = 1520, from = 600 } },
		giocatori = { { team = 1 }, { team = 2, bot = 2, carattere = "cecchino" } },
		globi = 0,
		vita = { [2] = 55 },
		turni = 6,
		stelle = { punti = 100, bonus = { conta = "teletrasporti", al_massimo = 1, testo = "CON UN SOLO GLOBO" } },
		obiettivo = {
			{ usa = "globi", testo = "Attacca presto: guadagna un globo" },
			{ abbatti = 2, con = "sword", testo = "Finisci il cecchino con la Lama" },
		},
		righe = {
			{ testo = "Ora il tasto viola: il globo ti porta dove cade", evidenzia = "teleport",
				quando = { evento = "teleports" }, fino = { evento = "teleport" } },
		},
		-- senza teletrasporto non ci si arriva
		collaudo = { senza = { teletrasporto = false } },
	},
	{
		id = "due_mani",
		titolo = "Due mani",
		scopo = "Il bot si rimette in sesto a ogni turno: serve la primaria e la Lama nello stesso turno",
		arena = { { 240, 0, 1440, 150 } },
		spawns = { { x = 760, from = 600 }, { x = 1160, from = 600 } },
		giocatori = { { team = 1 }, { team = 2, bot = 3 } },
		vita = { [2] = 46 },
		rigenera = { 2 },
		casse = { { dopo = 0, arma = "shards", x = 560 } },
		-- il bot che la prova fa sempre i due attacchi
		collaudo = { piano = { due_attacchi = true } },
		turni = 6,
		stelle = { punti = 110, bonus = { conta = "morti", al_massimo = 0, testo = "SENZA MORIRE" } },
		obiettivo = { { abbatti = 2, testo = "Abbatti il bot in un turno solo" } },
	},
	{
		id = "giu_dal_bordo",
		titolo = "Giù dal bordo",
		scopo = "I bersagli non si feriscono: buttali giù dai loro scogli",
		-- la tua piattaforma e tre scogli stretti sopra il vuoto
		arena = { { 760, 300, 400, 40 }, { 420, 420, 70, 24 }, { 1430, 420, 70, 24 }, { 925, 620, 70, 24 } },
		spawns = { { x = 960, from = 600 }, { x = 455, from = 600 }, { x = 1465, from = 600 }, { x = 960, from = 1000 } },
		-- tutto quello che spinge (Sergio, 29 ottobre 2026): il Cecchino, il Mantice
		-- e il Rampino, che dal bordo arriva agli scogli e li molla sopra il vuoto
		giocatori = {
			{ team = 1, pick = "sniper", secondary = "bellows" },
			{ team = 2, dummy = true }, { team = 2, dummy = true }, { team = 2, dummy = true },
		},
		vita = { [2] = 999, [3] = 999, [4] = 999 },
		turni = 5,
		stelle = { punti = 400, bonus = { conta = "morti", al_massimo = 0, testo = "SENZA CADERE" } },
		obiettivo = { { abbatti = "nemico", come = "vuoto", volte = 3, testo = "Butta giù tre bersagli" } },
		-- il bot che la prova cerca il vuoto
		collaudo = { carattere = "spingitore" },
	},
	{
		id = "il_codardo",
		titolo = "Il codardo",
		scopo = "Colpisce a ogni turno e scappa col globo nelle tane: stanalo col tuo",
		mappa = "forgia",
		giocatori = { { team = 1 }, { team = 2, bot = 4, carattere = "codardo", nome = "Il codardo" } },
		turni = 7,
		stelle = { punti = 130, bonus = { conta = "morti", al_massimo = 0, testo = "SENZA MORIRE" } },
		obiettivo = { { abbatti = 2, testo = "Abbatti il codardo" } },
	},
	{
		id = "il_fabbro",
		titolo = "Il Fabbro",
		scopo = "Il custode della Forgia: tanta vita e il Maglio. Buttarlo nel vuoto fa prima",
		mappa = "forgia",
		giocatori = {
			{ team = 1 },
			{ team = 2, bot = 5, carattere = "testa_calda", secondary = "mallet", nome = "Il Fabbro",
				battute = "fabbro" },
		},
		vita = { [2] = 240 },
		turni = 10,
		stelle = { punti = 20, bonus = { conta = "vuoto", almeno = 1, testo = "BUTTALO NEL VUOTO" } },
		obiettivo = { { abbatti = 2, testo = "Abbatti il Fabbro" } },
	},
	-- la fine del girone: una partita completa 2 contro 2, con un bot al tuo
	-- fianco, che mette insieme tutto quello del girone
	{
		id = "battaglia_forgia",
		titolo = "Battaglia della Forgia",
		scopo = "Una partita vera, 2 contro 2: tu e il tuo compagno contro il Fabbro e il cecchino",
		mappa = "forgia",
		-- la prima scelta delle armi, guidata, con le armi già viste (Sergio, 30 ott)
		draft = true,
		giocatori = {
			{ team = 1 },
			{ team = 2, bot = 5, carattere = "testa_calda", secondary = "mallet", nome = "Il Fabbro",
				battute = "fabbro" },
			{ team = 1, bot = 7, nome = "Compagno" },
			{ team = 2, bot = 2, carattere = "cecchino" },
		},
		-- niente limite di turni: si gioca fino alla fine del tempo
		stelle = { punti = 130, bonus = { conta = "abbattuti", almeno = 3, testo = "ABBATTINE 3" } },
		obiettivo = { { vinci = true, testo = "Vinci la partita con il tuo compagno" } },
	},
}

-- serve: le stelle (di tutti i capitoli) per aprire il capitolo
M.CAPITOLI = {
	{ id = "addestramento", titolo = "Addestramento", serve = 0, missioni = ADDESTRAMENTO, aspetta = true },
	{ id = "girone_1", titolo = "I girone: la Forgia", serve = 8, missioni = GIRONE_1 },
}

return M
