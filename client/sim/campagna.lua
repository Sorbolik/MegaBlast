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
-- stella è alla mediana dei turni del bot normale che gioca al posto tuo.

local M = {}

local GIOCATORE = 1

local ADDESTRAMENTO = {
	-- le basi, una cosa per lezione: camminare, saltare, sparare (Sergio, 29 ott)
	{
		id = "cammina",
		titolo = "Camminare",
		scopo = "Cammina fino al bersaglio: {cammina}",
		evidenzia = "cammina",
		arena = { { 240, 0, 1440, 150 } },
		-- il bersaglio vicino, che si veda già con la camera da vicino
		spawns = { { x = 760, from = 600 }, { x = 1120, from = 600 } },
		giocatori = { { team = 1 }, { team = 2, dummy = true } },
		-- niente armi né tasti: solo le levette
		vedi = {},
		turni = 3, stelle = { 2, 1 },
		obiettivo = { { raggiungi = { x = 1020, y = 150 }, testo = "Raggiungi il bersaglio" } },
	},
	{
		id = "salta",
		titolo = "Saltare",
		scopo = "Il gradino è troppo alto per camminarci sopra: {salta}",
		evidenzia = "salta",
		-- un gradino più alto di quello che si sale camminando, più basso del salto
		arena = { { 240, 0, 1440, 150 }, { 1000, 150, 680, 30 } },
		spawns = { { x = 640, from = 600 }, { x = 1400, from = 600 } },
		giocatori = { { team = 1 }, { team = 2, dummy = true } },
		vedi = {},
		turni = 3, stelle = { 2, 1 },
		obiettivo = { { raggiungi = { x = 1000, y = 180 }, testo = "Salta sul gradino" } },
		righe = {
			{ testo = "Cammina verso il gradino e salta quando ci sei vicino", quando = { tocca = "salta" },
				fino = { passo = 1 } },
		},
	},
	{
		id = "spara",
		titolo = "Sparare",
		scopo = "Colpisci il bersaglio col Lanciarune: {mira}",
		evidenzia = "mira",
		arena = { { 240, 0, 1440, 150 } },
		spawns = { { x = 700, from = 600 }, { x = 1000, from = 600 } },
		giocatori = { { team = 1 }, { team = 2, dummy = true } },
		vedi = { "missile" },
		turni = 3, stelle = { 2, 1 },
		obiettivo = { { colpisci = 2, con = "missile", testo = "Colpisci il bersaglio" } },
		righe = {
			-- mentre mira: come si annulla (il tempo aspetta che lo provi)
			{ testo = "Più tiri lontano, più forte parte. Se cambi idea, {annulla}", evidenzia = "annulla",
				subito = true, quando = { tocca = "mira" },
				fino = function(st, g) return st.toccati.annulla or g.used.primary end },
			{ testo = "Ora mira di nuovo e lascia: il colpo parte", quando = { tocca = "annulla" } },
		},
	},
	{
		id = "armi",
		titolo = "Armi e draft",
		scopo = "Colpisci il bersaglio con la primaria e con la secondaria che hai scelto",
		draft = true,
		arena = { { 240, 0, 1440, 150 } },
		spawns = { { x = 760, from = 600 }, { x = 1080, from = 600 } },
		giocatori = { { team = 1 }, { team = 2, dummy = true } },
		-- nell'HUD solo quello che serve
		vedi = { "primarie", "secondarie" },
		turni = 4, stelle = { 3, 2 },
		in_ordine = false,
		obiettivo = {
			{ colpisci = 2, con = "primaria", testo = "Colpisci con la primaria scelta" },
			{ colpisci = 2, con = "secondaria", testo = "Colpisci con la secondaria scelta" },
		},
		righe = {
			{ testo = "Prima la primaria che hai scelto, a sinistra del cronometro: toccala", evidenzia = "primaria",
				quando = { turno = 1 }, fino = { tocca = "primaria" } },
			{ testo = "Ora la secondaria, a destra del cronometro: toccala", evidenzia = "secondaria",
				quando = { passo = 1 }, fino = { tocca = "secondaria" } },
			{ testo = "Lanciarune e Lama ci sono sempre. La primaria scelta ha 2 colpi, la secondaria non finisce",
				quando = { turno = 2 } },
		},
	},
	{
		id = "globi",
		titolo = "Tempo e globi",
		scopo = "Attacca prima delle tacche viola: guadagni globi. Poi teletrasportati sull'isola",
		-- la tua terra, il vuoto, e l'isola del secondo bersaglio
		arena = { { 300, 0, 600, 150 }, { 1200, 100, 320, 50 } },
		spawns = { { x = 600, from = 600 }, { x = 800, from = 600 }, { x = 1380, from = 600 } },
		giocatori = { { team = 1 }, { team = 2, dummy = true }, { team = 2, dummy = true } },
		-- nell'HUD solo quello che serve
		vedi = { "missile", "sword", "teleport" },
		globi = 0,
		turni = 3, stelle = { 2, 1 },
		obiettivo = {
			{ usa = "globi", testo = "Attacca presto: guadagna un globo" },
			{ raggiungi = { x = 1200, y = 150 }, testo = "Teletrasportati sull'isola" },
			{ colpisci = 3, con = "sword", testo = "Colpisci il bersaglio con la Lama" },
		},
		righe = {
			{ testo = "Tocca il tasto viola, mira l'isola e lascia: arrivi dove cade il globo", evidenzia = "teleport",
				quando = { evento = "teleports" }, fino = { evento = "teleport" } },
			{ testo = "Ora la Lama: è la tua secondaria di sempre", quando = { passo = 2 } },
		},
	},
	{
		id = "tonante",
		titolo = "Il Tonante",
		scopo = "Salta ({salta}) e in aria spara col Tonante verso il basso: il rinculo ti porta sul pilastro",
		-- il pilastro è più basso di quello del Maglio (il rinculo porta su 110 px),
		-- ma più alto del salto
		arena = { { 300, 0, 1300, 150 }, { 1000, 150, 160, 110 } },
		spawns = { { x = 840, from = 600 }, { x = 1120, from = 1000 } },
		giocatori = { { team = 1, secondary = "eagle", tool = "wall" }, { team = 2, dummy = true } },
		-- nell'HUD solo quello che serve
		vedi = { "missile", "eagle" },
		globi = 0,
		turni = 3, stelle = { 2, 1 },
		obiettivo = {
			{ usa = "rinculo", testo = "Spara col Tonante in aria, verso il basso" },
			{ raggiungi = { x = 1000, y = 260 }, testo = "Sali sul pilastro" },
			{ colpisci = 2, testo = "Colpisci il bersaglio" },
		},
		righe = {
			{ testo = "Il Tonante è la tua secondaria: toccalo", evidenzia = "eagle",
				quando = { turno = 1 }, fino = { tocca = "eagle" } },
			{ testo = "Ora salta: {salta}", evidenzia = "salta", quando = { tocca = "eagle" }, fino = { tocca = "salta" } },
			{ testo = "In aria mira verso il basso e lascia: il rinculo ti porta su",
				quando = { tocca = "salta" }, fino = { passo = 1 } },
			{ testo = "Il rinculo ti spinge sempre dall'altra parte del colpo: verso il vuoto per tornare su",
				quando = { passo = 2 } },
		},
	},
	{
		id = "paracadute",
		titolo = "Il paracadute",
		scopo = "Salta dalla torre ({salta}) e apri il paracadute in aria: arriva al bersaglio",
		arena = { { 300, 0, 120, 560 }, { 760, 0, 640, 150 } },
		spawns = { { x = 360, from = 1000 }, { x = 1100, from = 600 } },
		giocatori = { { team = 1 }, { team = 2, dummy = true } },
		-- nell'HUD solo quello che serve
		vedi = { "missile", "parachute" },
		globi = 0,
		turni = 2, stelle = { 2, 1 },
		obiettivo = {
			{ usa = "paracadute", testo = "Salta e apri il paracadute" },
			{ raggiungi = { x = 760, y = 150 }, testo = "Atterra vicino al bersaglio" },
			{ colpisci = 2, testo = "Colpisci il bersaglio" },
		},
		-- uno a partita: se lo hai già usato e non sei arrivato, si ricomincia
		fallisce = { muori = true, esaurito = "paracadute" },
		righe = {
			{ testo = "Cammina fino al bordo e salta: {salta}", evidenzia = "salta",
				quando = { turno = 1 }, fino = { tocca = "salta" } },
			{ testo = "In aria tocca il paracadute, fra gli OGGETTI", evidenzia = "parachute", ferma = false,
				quando = { tocca = "salta" }, fino = { evento = "parachute" } },
			{ testo = "Tocca di nuovo per chiuderlo. È uno solo a partita", quando = { evento = "parachute" } },
		},
	},
	{
		id = "rampino",
		titolo = "Il Rampino",
		scopo = "Il bersaglio è in alto: aggancia il bordo col Rampino e ti arrampichi",
		-- una piattaforma sospesa, troppo alta per il salto
		arena = { { 300, 0, 1300, 150 }, { 1000, 300, 320, 30 } },
		spawns = { { x = 760, from = 290 }, { x = 1220, from = 1000 } },
		giocatori = { { team = 1, tool = "hook" }, { team = 2, dummy = true } },
		-- nell'HUD solo quello che serve
		vedi = { "hook", "sword" },
		globi = 0,
		turni = 2, stelle = { 2, 1 },
		obiettivo = {
			{ usa = "rampino", testo = "Aggancia il bordo col Rampino" },
			{ raggiungi = { x = 1000, y = 330 }, testo = "Sali sulla piattaforma" },
			{ colpisci = 2, con = "sword", testo = "Colpisci il bersaglio con la Lama" },
		},
		righe = {
			{ testo = "Il Rampino è a destra: toccalo, poi mira il bordo e lascia", evidenzia = "hook",
				quando = { turno = 1 }, fino = { tocca = "hook" } },
			{ testo = "Su un nemico invece lo tiri da te: buttalo giù e sono 50 punti in più", quando = { passo = 2 } },
		},
	},
	{
		id = "bastione",
		titolo = "Il Bastione",
		scopo = "La sporgenza è troppo alta: posa un blocco col Bastione e usalo come gradino",
		arena = { { 300, 0, 1300, 150 }, { 1060, 150, 540, 72 } },
		spawns = { { x = 760, from = 600 }, { x = 1300, from = 600 } },
		giocatori = { { team = 1, tool = "wall" }, { team = 2, dummy = true } },
		-- nell'HUD solo quello che serve
		vedi = { "wall", "sword" },
		globi = 0,
		turni = 3, stelle = { 2, 1 },
		obiettivo = {
			{ usa = "bastione", testo = "Posa un blocco col Bastione" },
			{ raggiungi = { x = 1060, y = 222 }, testo = "Sali sulla sporgenza" },
			{ colpisci = 2, con = "sword", testo = "Colpisci il bersaglio con la Lama" },
		},
		righe = {
			{ testo = "Il Bastione è a destra: toccalo, poi mira dove posarlo e lascia", evidenzia = "wall",
				quando = { turno = 1 }, fino = { tocca = "wall" } },
			{ testo = "Uno a turno, al massimo due in mappa. Ora la Lama", quando = { passo = 2 } },
		},
	},
	{
		id = "maglio",
		titolo = "Il Maglio",
		scopo = "Salta ({salta}) e colpisci il terreno col Maglio: rimbalzi in alto fino al bersaglio",
		arena = { { 300, 0, 1300, 150 }, { 1000, 150, 160, 200 } },
		spawns = { { x = 840, from = 600 }, { x = 1120, from = 1000 } },
		giocatori = { { team = 1, secondary = "mallet", tool = "wall" }, { team = 2, dummy = true } },
		-- nell'HUD solo quello che serve
		vedi = { "missile", "mallet" },
		globi = 0,
		turni = 3, stelle = { 2, 1 },
		obiettivo = {
			{ usa = "rimbalzo", testo = "Rimbalza col Maglio" },
			{ raggiungi = { x = 1000, y = 350 }, testo = "Sali sul pilastro" },
			{ colpisci = 2, testo = "Colpisci il bersaglio" },
		},
		righe = {
			{ testo = "Il Maglio è la tua secondaria: toccalo", evidenzia = "mallet",
				quando = { turno = 1 }, fino = { tocca = "mallet" } },
			{ testo = "Ora salta: {salta}", evidenzia = "salta", quando = { tocca = "mallet" }, fino = { tocca = "salta" } },
			{ testo = "In aria colpisci il terreno sotto di te: rimbalzi in alto",
				quando = { tocca = "salta" }, fino = { passo = 1 } },
			{ testo = "Ogni secondaria ti sposta: il Tonante spinge indietro, l'Affondo passa oltre", quando = { passo = 2 } },
		},
	},
	{
		id = "corona",
		titolo = "Punti e Corona",
		scopo = "Abbatti chi ha la Corona: i suoi colpi valgono 1,5 e in più 25 punti",
		arena = { { 240, 0, 1440, 150 } },
		spawns = { { x = 900, from = 600 }, { x = 560, from = 600 }, { x = 1320, from = 600 }, { x = 1120, from = 600 } },
		giocatori = { { team = 1 }, { team = 2, dummy = true }, { team = 3, dummy = true }, { team = 4, dummy = true } },
		-- nell'HUD solo quello che serve
		vedi = { "missile", "sword" },
		-- il terzo bersaglio è primo in classifica: ha la Corona. Sono già
		-- feriti, così un turno basta
		punti = { [2] = 60, [3] = 40, [4] = 200 },
		vita = { [2] = 50, [3] = 50, [4] = 50 },
		turni = 4, stelle = { 3, 2 },
		obiettivo = {
			{ abbatti = 4, testo = "Abbatti chi ha la Corona" },
		},
		righe = {
			{ testo = "Danno = punti. Abbattere vale 50, buttare nel vuoto altri 50", quando = { evento = "points" } },
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
			{ team = 1, pick = "grenade", secondary = "mallet", tool = "hook" },
			{ team = 2, bot = "tutorial", pick = "grenade", secondary = "mallet", tool = "hook" },
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
		giocatori = { { team = 1 }, { team = 2, bot = "facile" } },
		turni = 7,
		stelle = { turni = 3, bonus = { conta = "morti", al_massimo = 0, testo = "SENZA MORIRE" } },
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
		giocatori = { { team = 1 }, { team = 2, bot = "facile", carattere = "cecchino" } },
		globi = 0,
		vita = { [2] = 55 },
		turni = 6,
		stelle = { turni = 2, bonus = { conta = "teletrasporti", al_massimo = 1, testo = "CON UN SOLO GLOBO" } },
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
		giocatori = { { team = 1 }, { team = 2, bot = "facile" } },
		vita = { [2] = 46 },
		rigenera = { 2 },
		-- il bot che la prova fa sempre i due attacchi
		collaudo = { piano = { due_attacchi = true } },
		turni = 6,
		stelle = { turni = 1, bonus = { conta = "morti", al_massimo = 0, testo = "SENZA MORIRE" } },
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
			{ team = 1, pick = "sniper", secondary = "bellows", tool = "hook" },
			{ team = 2, dummy = true }, { team = 2, dummy = true }, { team = 2, dummy = true },
		},
		vita = { [2] = 999, [3] = 999, [4] = 999 },
		turni = 5,
		stelle = { turni = 3, bonus = { conta = "morti", al_massimo = 0, testo = "SENZA CADERE" } },
		obiettivo = { { abbatti = "nemico", come = "vuoto", volte = 3, testo = "Butta giù tre bersagli" } },
		-- il bot che la prova cerca il vuoto
		collaudo = { carattere = "spingitore" },
	},
	{
		id = "il_codardo",
		titolo = "Il codardo",
		scopo = "Colpisce a ogni turno e scappa col globo nelle tane: stanalo col tuo",
		mappa = "forgia",
		giocatori = { { team = 1 }, { team = 2, bot = "normale", carattere = "codardo", nome = "Il codardo" } },
		turni = 7,
		stelle = { turni = 3, bonus = { conta = "morti", al_massimo = 0, testo = "SENZA MORIRE" } },
		obiettivo = { { abbatti = 2, testo = "Abbatti il codardo" } },
	},
	{
		id = "il_fabbro",
		titolo = "Il Fabbro",
		scopo = "Il custode della Forgia: tanta vita e il Maglio. Buttarlo nel vuoto fa prima",
		mappa = "forgia",
		giocatori = {
			{ team = 1 },
			{ team = 2, bot = "normale", carattere = "testa_calda", secondary = "mallet", nome = "Il Fabbro",
				battute = "fabbro" },
		},
		vita = { [2] = 240 },
		turni = 10,
		stelle = { turni = 8, bonus = { conta = "vuoto", almeno = 1, testo = "BUTTALO NEL VUOTO" } },
		obiettivo = { { abbatti = 2, testo = "Abbatti il Fabbro" } },
	},
	-- la fine del girone: una partita completa 2 contro 2, con un bot al tuo
	-- fianco, che mette insieme tutto quello del girone
	{
		id = "battaglia_forgia",
		titolo = "Battaglia della Forgia",
		scopo = "Una partita vera, 2 contro 2: tu e il tuo compagno contro il Fabbro e il cecchino",
		mappa = "forgia",
		giocatori = {
			{ team = 1 },
			{ team = 2, bot = "normale", carattere = "testa_calda", secondary = "mallet", nome = "Il Fabbro",
				battute = "fabbro" },
			{ team = 1, bot = "normale", nome = "Compagno" },
			{ team = 2, bot = "facile", carattere = "cecchino" },
		},
		-- niente limite di turni: si gioca fino alla fine del tempo
		stelle = { bonus = { conta = "abbattuti", almeno = 3, testo = "ABBATTINE 3" },
			bonus2 = { conta = "morti", al_massimo = 1, testo = "AL MASSIMO UNA MORTE" } },
		obiettivo = { { vinci = true, testo = "Vinci la partita con il tuo compagno" } },
	},
}

-- serve: le stelle (di tutti i capitoli) per aprire il capitolo
M.CAPITOLI = {
	{ id = "addestramento", titolo = "Addestramento", serve = 0, missioni = ADDESTRAMENTO, aspetta = true },
	{ id = "girone_1", titolo = "I girone: la Forgia", serve = 8, missioni = GIRONE_1 },
}

return M
