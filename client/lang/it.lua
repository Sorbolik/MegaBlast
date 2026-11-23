-- The game's texts in Italian (lang/text.lua explains how they are used).
-- One group per screen or module, named like the file; %s and %d are where
-- the code puts names and numbers.

return {
	-- shared by many screens
	common = {
		game_name = "MEGABLAST",
		play = "GIOCA",
		quit = "ESCI",
		next = "AVANTI",
		modes = { ["1v1"] = "1 CONTRO 1", ["2v2"] = "2 CONTRO 2", ffa = "TUTTI CONTRO TUTTI" },
		opens_with = "Si apre con %s stelle",
		campaign = "CAMPAGNA",
		events = "EVENTI",
		tournament = "TORNEO",
		all = "TUTTE",
		you = "Tu",
		home = "HOME",
		retry = "RIPROVA",
		-- the sticks' sides, in a sentence
		stick_side = { dx = "di destra", sx = "di sinistra" },
		bot = "BOT",
		training = "ALLENAMENTO",
		armory = "ARMERIA",
		-- the Smith's shop, the home's door that was ARMERIA (18 Nov)
		shop = "BOTTEGA",
		stats = "STATISTICHE",
		replay = "RIVEDI",
	},

	-- battle/vignette.lua: who speaks and the buttons of the big vignette
	vignette = {
		favilla = "FAVILLA",
		-- battle/favilla.lua: her name above her head in the cortile
		favilla_name = "Favilla",
		fabbro = "IL FABBRO",
		apprendista = "APPRENDISTA",
		go = "VAI!",
		close = "CHIUDI",
		close_pad = "B  CHIUDI",
	},

	-- menu/story.lua and ui/story.lua: the campaign's story, a comic in chapters.
	-- Each panel (its image id) has its balloons in order: { who, line };
	-- who: favilla, fabbro, apprendista, voce (from the dark) or didascalia (the caption box)
	story = {
		skip = "SALTA",
		read_again = "LA STORIA",
		voice = "???",
		chapters = {
			prologo = {
				s_viaggio = {
					{ "didascalia", "Sull'orlo dell'inferno c'è la Forgia, dove nascono le armi dei diavoli." },
					{ "apprendista", "Eccola! Il Fabbro prende un solo apprendista all'anno. Stavolta tocca a me." },
				},
				["4_arrivo_a"] = { { "favilla", "Ehi, nuovo! Sei tu quello che vuole fare il fabbro?" } },
				["4_arrivo_b"] = { { "apprendista", "Sì! E diventerò il più forte di tutti." } },
				["4_arrivo_c"] = { { "favilla", "Ah sì? Io sono Favilla, l'apprendista più grande. Il più forte, qui, è chi mi sta dietro." } },
				["5_fabbro_a"] = {
					{ "fabbro", "Un altro. Favilla, insegnagli tu. Se impara, lo voglio nella Forgia." },
					{ "apprendista", "(...è enorme.)" },
				},
				["5_fabbro_c_1"] = { { "favilla", "Psst. Brontola, ma la sua fornace tiene caldo tutto l'inferno. Vieni, ti faccio vedere il cortile!" } },
			},
			forgia_aperta = {
				s_forgia_aperta = {
					{ "fabbro", "Hai battuto Favilla. Non succede spesso." },
					{ "fabbro", "Benvenuto nella Forgia, ragazzo. Qui si combatte davvero." },
				},
			},
			regalo = {
				s_regalo = {
					{ "fabbro", "Te li sei guadagnati. Mettili, laggiù il pavimento brucia." },
					{ "didascalia", "Gli stivali sono nel tuo ZAINO. E ora si apre la BOTTEGA." },
				},
			},
			insieme = {
				s_insieme = { { "favilla", "Io e te, insieme. Fammi vedere cosa ti ho insegnato!" } },
			},
			rapimento = {
				["6_rapimento_a"] = {
					{ "voce", "La fiamma più calda dell'inferno adesso è mia." },
					{ "favilla", "Aiutami!" },
				},
				["6_rapimento_b"] = { { "didascalia", "Giù, sempre più giù, fino in fondo all'inferno." } },
				["6_rapimento_c"] = {
					{ "apprendista", "Chi era?!" },
					{ "fabbro", "Lucifero. L'ha portata in fondo all'inferno. Ti accompagno io, un girone alla volta, finché il fuoco regge." },
				},
				s_ghiaccio = { { "didascalia", "In fondo all'ultimo girone, nel ghiaccio, Lucifero le ruba il calore per liberarsi. Favilla aspetta te." } },
			},
		},
	},

	-- menu/pick.lua: the weapon draft
	pick = {
		title = "ARMI",
		yours = "LE TUE ARMI",
		everyone = "LE HANNO TUTTI",
		shots_label = "COLPI",
		chosen = "SCELTA",
		time = "TEMPO",
		ready_action = "PRONTO",
		missing_two = "MANCANO 2 ARMI",
		missing_one = "MANCA LA %s",
		starts_all_ready = "TUTTI PRONTI, SI PARTE",
		waiting = "ASPETTI GLI ALTRI",
		step_names = { "PRIMARIA", "SECONDARIA" },
		shot = "%s colpo",
		shots = "%s colpi",
		pick_primary = "scegli la primaria",
		primary_guided = "Prima di ogni partita scegli due armi in più, una per tipo; quelle degli altri non le vedi. "
			.. "La primaria ha %s a partita, e il Lanciarune ce l'hai sempre. "
			.. "Tieni premuta una carta per vedere la sua scheda.",
		primary = "Ne hai %s; il Lanciarune ce l'hai sempre. Tieni premuta una carta per la sua scheda.",
		pick_secondary = "scegli la secondaria",
		secondary_guided = "La secondaria ha %s: ogni volta che colpisci un nemico "
			.. "con la Lama, che ce l'hai sempre, te ne torna uno. Tieni premuta una carta per la sua scheda.",
		secondary = "Ne hai %s; colpendo un nemico con la Lama te ne torna uno.",
		press_ready = "premi PRONTO",
		press_play = "premi GIOCA",
		ready_guided = "Il Rampino ce l'hai sempre. Online la scelta ha un tempo; qui no. "
			.. "Tocca una scelta per cambiarla, o GIOCA.",
		ready_text = "Il Rampino ce l'hai sempre. Tocca una scelta per cambiarla, poi PRONTO.",
		-- with the controller the first becomes the second (%s = the card's button)
		hold_card = "Tieni premuta una carta",
		press_on_card = "Premi %s su una carta",
		tap_pick = "Tocca una scelta",
		back_to_pick = "Torna su una scelta",
	},

	-- menu/training.lua: ALLENAMENTO, mode and bots, then the map
	training = {
		mode = "MODO",
		levels = { facile = "FACILE", normale = "NORMALE", difficile = "DIFFICILE" },
		who = "CHI C'È",
		vs_bots = "CONTRO I BOT",
		same_phone = "STESSO TELEFONO",
		offline = "SENZA RETE",
		map = "MAPPA",
		mode_and_bot = "%s · BOT %s",
		mode_same = "%s · STESSO TELEFONO",
		random = "A CASO",
	},

	-- menu/podium.lua: the podium at the end of the match
	podium = {
		modes = { ["1v1"] = "UNO CONTRO UNO", ["2v2"] = "DUE CONTRO DUE", ffa = "TUTTI CONTRO TUTTI" },
		tie = "PAREGGIO",
		victory = "VITTORIA",
		defeat = "SCONFITTA",
		wins = "VINCE %s",
		mvp = "MVP",
		go_on = "CONTINUA",
	},

	-- ui/receipt.lua: what a match or a level gave, line by line
	receipt = {
		title = "GUADAGNI",
		-- what the server said of them (Sergio, 19 Nov: proposal A)
		verdict = { wait = "IN ATTESA DEL SERVER…", ok = "CONFERMATI", bad = "PARTITA NON VALIDA" },
		xp = "XP",
		lines = { match = "Partita", win = "Vittoria", second = "Secondo posto", mvp = "MVP",
			done = "Prima volta", bots_over = "Allenamento di oggi finito", replay = "Record battuto", replay_plain = "Rigiocata senza record", daily = "Prima vittoria di oggi",
			level = "Ogni 5 livelli", chapter = "Capitolo finito",
			obs_match = "Ossidiana della vittoria", obs_stars = "Ossidiana delle stelle" },
		points_line = "Punti %s",
		award = "Premio %s",
		stars = "Stelle nuove ×%s",
		-- a badge going up a grade: its name and the grade
		badge = "%s %s",
		plus = "+%s",
		total = "TOTALE",
		level = "LIVELLO %s",
		level_up = "SALI AL LIVELLO %s",
		seal_point = "+%s punto da mettere nei Sigilli",
		seal_points = "+%s punti da mettere nei Sigilli",
		place_points = "METTI I PUNTI",
		brace = "+%s brace accanto al livello",
		braci = "+%s braci accanto al livello",
		-- the gifts (sim/wallet.lua): a piece (slot and family), a voucher
		gift_piece = "In regalo: %s del %s",
		gift_voucher = "Un buono del Fabbro",
	},

	-- menu/milestones.lua: the stats (by id) and their badges
	milestones = {
		names = {
			nel_vuoto = "Abbattuti nel vuoto", abbattuti = "Abbattuti", a_segno = "Colpi a segno",
			danno = "Danno fatto", globi = "Globi guadagnati", colpo_lungo = "Colpo più lungo",
			casse = "Casse aperte", vinte = "Partite vinte", cadute = "Cadute",
		},
		badges = {
			nel_vuoto = "BECCHINO", abbattuti = "CACCIATORE", a_segno = "MIRA", danno = "MARTELLO",
			globi = "FULMINE", colpo_lungo = "LONTANO", casse = "PREDONE", vinte = "VINCITORE",
		},
	},


	-- menu/board.lua: the EVENTI board
	board = {
		days = { "dom", "lun", "mar", "mer", "gio", "ven", "sab" },
		months = { "gen", "feb", "mar", "apr", "mag", "giu", "lug", "ago", "set", "ott", "nov", "dic" },
		-- "lun 16 nov": day of the week, day, month
		date = "%s %s %s",
		no_event = "Nessun evento in corso",
		-- the next event: its name, when it starts
		next_one = "Il prossimo: %s · %s",
		counts_in = "conta nelle partite %s",
		own_queue = "coda sua · %s",
		-- the world ranking (the server doesn't keep it yet: one line per row)
		ranking = "CLASSIFICA MONDIALE",
		ranking_soon = { "la classifica mondiale arriva", "quando il server la terrà:", "qui i primi 100 e i tuoi vicini" },
		-- your event
		ends_in = "FINISCE TRA",
		top = "SEI NEI PRIMI",
		prize = "PREMIO A FINE EVENTO",
		calendar = "CALENDARIO",
		nothing_planned = "Niente in programma",
		what_changes = "COSA CAMBIA",
		from_to = "%s fino a %s",
		back_on = "torna %s",
		prizes = "PREMI",
		just_for_fun = "Solo per divertirsi",
		offline = "Il server non risponde: gli eventi tornano appena c'è la rete",
	},


	-- menu/level_end.lua: the end of a campaign mission
	level_end = {
		done = "MISSIONE FATTA",
		failed = "MISSIONE NON RIUSCITA",
		points = "Punti fatti: %s",
		-- the record of points on this level (Sergio, 14 Nov: in points, not stars)
		record_points = "RECORD · %s PUNTI",
		record_new = "NUOVO RECORD · %s PUNTI",
		record_beat = "RECORD · %s PUNTI · BATTILO",
	},

	-- sim/tally.lua: the moments of the match, in the profile's history
	tally = {
		long_shot = "Colpo da %d px su %s",
		you_drop = "Butti nel vuoto %s",
		you_kill = "Abbatti %s",
		drops_you = "%s ti butta nel vuoto",
		kills_you = "%s ti abbatte",
		double_points = "Ultimo giro a punti doppi",
	},

	-- menu/showcase.lua: the character's bars
	showcase = {
		health = "VITA",
		jump = "SALTO",
		run = "CORSA",
		air = "ARIA",
	},

	-- menu/campaign.lua: CAMPAGNA, chapters and missions
	campaign = {
		-- a chapter still locked: the one before must be finished (Sergio, 7 Nov)
		locked = "Si sblocca completando tutte le missioni di %s",
		done_count = "Missioni completate: %s / %s",
		-- the board (Sergio, 4 Nov): the next challenge, and the chapter's final strip
		new = "NUOVA",
		final = "FINALE · %s",
		-- under the guide: missions done of the chapter's, stars taken
		progress = "%d DI %d MISSIONI · %d STELLE",
		-- under GIOCA: the next mission, or the final again
		play_new = "%s · NUOVA",
		replay_final = "RIGIOCA IL FINALE",
		-- on a mission card: its record of points
		record = "RECORD %s",
		-- the map of the circles (after the kidnapping, Sergio 11 Nov): the Cortile
		-- and the Forge on the top floor, the nine circles going down to Favilla
		-- (only the ones reached open). The circles are placeholders until their levels are written:
		-- { numeral, name, keeper, hazard, what it does }
		rings = {
			{ "I", "LIMBO", "CARONTE", "GRAVITÀ RIDOTTA", "SALTI E COLPI VOLANO PIÙ LONTANO" },
			{ "II", "LUSSURIA", "MINOSSE", "LA BUFERA", "A FINE GIRO SPOSTA TUTTI DI UN PASSO" },
			{ "III", "GOLA", "CERBERO", "LA GRANDINE", "CADE DOVE L'OMBRA L'ANNUNCIA" },
			{ "IV", "AVARIZIA", "PLUTONE", "I MASSI", "ROTOLANO DAI PENDII VERSO IL CENTRO" },
			{ "V", "IRA", "FLEGIÀS", "L'ACQUA SALE", "DAL TERZO GIRO, UN GRADINO PER GIRO" },
			{ "VI", "ERESIA", "MEDUSA", "LE ARCHE", "APERTE BRUCIANO, CHIUSE RIPARANO" },
			{ "VII", "VIOLENZA", "MINOTAURO", "SANGUE E FUOCO", "IL SANGUE BRUCIA, SUL SABBIONE PIOVE FUOCO" },
			{ "VIII", "FRODE", "MALACODA", "PONTI FALSI E PECE", "GLI ARCHI CROLLANO, LA PECE INCOLLA" },
			{ "IX", "TRADIMENTO", "LUCIFERO", "IL GHIACCIO", "SI SCIVOLA, E LE ESPLOSIONI LO ROMPONO" },
		},
		ring_title = "GIRONE %s · %s",
		ring_here = "SEI QUI",
		ring_closed = "CHIUSO",
		hazard = "PERICOLO",
		keeper = "CUSTODE",
		ring_name = "%s · %s",
		ring_stars = "%d / %d",
		ring_opens = "SI APRE BATTENDO %s",
		coming_sub = "%s · IN ARRIVO",
		rings_back = "GIRONI",
		cortile = "IL CORTILE",
	},

	-- ui/level_types.lua: what kind of level a mission is (Sergio, 6 Nov), on its
	-- card and its postcard; the line says it the first time you meet the kind
	level_types = {
		corsa = "CORSA",
		bersagli = "BERSAGLI",
		duello = "DUELLO",
		squadra = "SQUADRA",
		orda = "ORDA",
		resistenza = "RESISTENZA",
		bottino = "BOTTINO",
		custode = "CUSTODE",
		corsa_line = "Arriva dove ti dico: la bandierina, il cancello, la cima.",
		bersagli_line = "Fantocci da colpire o buttare giù, coi colpi che hai.",
		duello_line = "Tu contro uno solo.",
		squadra_line = "Due contro due: chi ti sta accanto gioca con te.",
		orda_line = "Tu da solo contro tre.",
		resistenza_line = "Resisti fino all'ultimo giro.",
		bottino_line = "Prendi più del tuo avversario.",
		custode_line = "Il guardiano del capitolo: battilo e si va avanti.",
	},

	-- menu/lineup.lua: the line-up before the match
	lineup = {
		tap_to_pick = "TOCCA PER SCEGLIERE LE ARMI",
		weapons = "ARMI",
		weapons_in = "ARMI TRA %d:%02d",
		versus = "VS",
	},


	-- menu/settings.lua: IMPOSTAZIONI
	-- IMPOSTAZIONI > DISPOSIZIONE TASTI: the HUD's buttons moved and resized (menu/hud_editor.lua)
	hud_editor = {
		title = "DISPOSIZIONE TASTI",
		reset = "RIPRISTINA",
		done = "FATTO",
		-- %s: the group touched
		size = "GRANDEZZA: %s",
		pick = "TOCCA UN TASTO PER SPOSTARLO O CAMBIARNE LA GRANDEZZA",
		drag = "trascina per spostare",
		units = {
			primarie = "ARMI PRIMARIE", secondarie = "ARMI SECONDARIE", cronometro = "TEMPO DEL TURNO",
			teletrasporto = "TELETRASPORTO", attrezzi = "RAMPINO E GIANO", oggetti = "OGGETTI", zoom = "ZOOM",
		},
	},
	settings = {
		title = "IMPOSTAZIONI",
		-- the settings at the top (profile.SETTINGS) and their values
		choices = {
			mira = "MIRA", sparo = "SPARO COL CONTROLLER", potenza = "POTENZA COL CONTROLLER",
			levette = "LEVETTA CHE MUOVE", vibrazione = "VIBRAZIONE", fps = "CONTATORE FPS", profilo = "PROFILO", profilo_zero = "PROFILO DI PROVA",
		},
		values = {
			lancetta = "LANCETTA", mirino = "MIRINO", pressione = "PREMENDO", rilascio = "LASCIANDO",
			levetta = "LEVETTA", grilletto = "GRILLETTO", destra = "DESTRA", sinistra = "SINISTRA",
			spento = "SPENTO", acceso = "ACCESO", spenta = "SPENTA", accesa = "ACCESA", vero = "IL MIO", prova = "FINE GIOCO", risorse = "DA ZERO",
		},
		-- the controller's commands (controller.COMMANDS)
		commands = {
			spara = "SPARA", salta = "SALTA", primaria = "PRIMARIA DOPO", secondaria = "SECONDARIA DOPO",
			teletrasporto = "TELETRASPORTO", rampino = "RAMPINO", paracadute = "PARACADUTE",
			oggetti = "OGGETTO DOPO", usa_oggetto = "USA L'OGGETTO", baratto = "BARATTO", zoom = "ZOOM",
		},
		controller_keys = "TASTI DEL CONTROLLER",
		-- the button that opens the HUD's layout (menu/hud_editor.lua)
		layout = "DISPOSIZIONE TASTI",
		-- IL MIO PROFILO: the name, the recovery code, HO GIÀ UN PROFILO (step 6 of the guest profiles)
		my_profile = "IL MIO PROFILO",
		no_profile = "SENZA PROFILO SUL SERVER",
		code_label = "CODICE PER RITROVARLO",
		code_asking = "CHIEDO IL CODICE AL SERVER…",
		code_test = "IL PROFILO DI PROVA NON VA SUL SERVER",
		need_network = "SERVE LA RETE",
		code_help = "SEGNATELO: SU UN TELEFONO NUOVO",
		code_help2 = "LO SCRIVI IN \"HO GIÀ UN PROFILO\" E IL PROFILO TORNA",
		code_old = "CON UN CODICE NUOVO QUELLO VECCHIO SMETTE DI VALERE",
		new_code = "NUOVO CODICE",
		have_profile = "HO GIÀ UN PROFILO",
		write_code = "SCRIVI IL CODICE",
		tap_code = "TOCCA IL CODICE PER APRIRE LA TASTIERA",
		cancel_recover = "ANNULLA",
		recover = "RECUPERA",
		recover_help = "IL PROFILO DI QUESTO TELEFONO VIENE SOSTITUITO DA QUELLO DEL CODICE",
		recovering = "CERCO IL PROFILO…",
		recover_errors = { codice = "CODICE SBAGLIATO", tentativi = "TROPPI TENTATIVI: RIPROVA FRA UN'ORA", rete = "SERVE LA RETE" },
		press_a_key = "PREMI UN TASTO",
		-- jumping with the stick that moves (%s: sides)
		stick_up = "LEVETTA %s IN SU",
		sides = { dx = "DX", sx = "SX" },
		no_key = "NESSUN TASTO",
		reset = "RIPRISTINA",
		-- %s: the controller's buttons
		cancel = "%s ANNULLA",
		change_remove = "%s CAMBIA IL TASTO, %s LO TOGLIE",
		connect = "COLLEGA UN CONTROLLER PER CAMBIARE I TASTI",
		-- the build's commit (%s, as in the Telegram caption); a branch's test APK, a local build
		version = "VERSIONE %s",
		version_test = "VERSIONE %s · PROVA, NON È MAIN",
		version_local = "VERSIONE LOCALE",
	},

	-- menu/armory.lua (the SHOP) and menu/bench.lua (the ARMERIA in the ZAINO)
	armory = {
		-- the two tabs of the BOTTEGA: the Smith's orders and the shop
		tab_orders = "COMMESSE", tab_bench = "BANCO",
		-- the stats on the right (the effects of the pieces use them in lowercase)
		stats = {
			attack = "Attacco", defense = "Difesa",
			max_hp = "Vita", walk_speed = "Corsa", jump_height = "Salto", air_speed = "In aria",
			teleport_ticks = "Teletrasporto", teleports = "Teletrasporti", parachutes = "Paracadute",
			air_jumps = "Salti in aria", fall_damage_mul = "Danno da caduta", knockback_mul = "Spinta subita",
			trap_radius = "Raggio trappole", status_turns = "Turni degli effetti", burning_blasts = "Colpi brucianti",
			blast_push = "Spinta dei colpi",
		},
		yes = "sì",
		no = "no",
		seconds = "%.1f s",
		-- POTENZIA: no piece in the chosen slot
		nothing_here = "niente qui: prendilo in bottega",
		-- grade in roman numbers, its name
		grade = "GRADO %s · %s",
		level_to = "LIVELLO %d › %d",
		level_top = "LIVELLO %d · AL MASSIMO",
		-- the signature (how far it is lit: the gems beside it; under it its name and
		-- what it gives); it is lit with Ossidiana, a grade for each step done
		sign = "firma",
		sign_off = "firma spenta",
		-- what the signature gives once the next step is lit: the step, the value
		sign_next = "al %d: %d%%",
		-- the same when the step is already done: lighting it gives that
		sign_next_now = "accendila: %d%%",
		-- the Ossidiana spent lighting it, jumping under the balance
		sign_spent = "−%s",
		light_sign = "ACCENDI LA FIRMA",
		-- the next level paid with the family's fragments (the Smith's orders): what it costs, how many you hold
		with_fragments = "COI FRAMMENTI", fragments_cost = "Costa %d · ne hai %d", pick_family = "Scegli un pezzo",
		sign_cost = "%d ossidiana",
		sign_needs = "dallo scatto %d",
		sign_top = "al massimo",
		-- the other pieces of the slot (the slot in uppercase)
		others = "I TUOI %s",
		-- the slots in the plural
		plural = { mask = "ELMI", chest = "CORAZZE", cloak = "MANTELLI", legs = "STIVALI", gloves = "GUANTI" },
		-- the SHOP
		yours = "tuo",
		offers = "OFFERTE DEL FABBRO",
		-- the time until the day turns (5 in the morning)
		change_in = "cambiano tra %s",
		day = "PEZZI DEL GIORNO",
		day_line = "cambiano domani",
		use_voucher = "USA UN BUONO",
		you_have = "ne hai %d",
	},
	-- menu/orders_ui.lua: the COMMESSE tab of the BOTTEGA (docs/commesse.md)
	orders = {
		clients = { caronte = "Caronte", minosse = "Minosse", cerbero = "Cerbero", plutone = "Plutone",
			flegias = "Flegiàs", medusa = "Medusa", minotauro = "Minotauro", malacoda = "Malacoda" },
		-- the materials, as a request names them: "6 Piume del Limbo"
		materials = { scoria = "Scorie", piuma = "Piume del Limbo", vento = "Venti in bottiglia", grandine = "Chicchi di grandine",
			scheggia = "Schegge di masso", stige = "Acque dello Stige", tomba = "Polveri di tomba", sangue = "Sangue bollente",
			sabbia = "Sabbie roventi", pece = "Pece", ghiaccio = "Ghiacci di Cocito" },
		request_material = "%d %s",
		-- the feats (%s: how many)
		feats = { partite = "Gioca %s partite online", vinte = "Vinci %s partite online", vinte_2v2 = "Vinci %s partite 2 contro 2",
			punti = "Fate %s punti di squadra", nel_vuoto = "Buttate %s nemici nel vuoto", danno = "Fate %s danni di squadra",
			mvp = "Sii il migliore in campo %s volte", casse = "Apri %s casse", teletrasporti = "Teletrasportati %s volte",
			premi = "Prendi %s premi di fine partita" },
		ready = "PRONTA",
		progress = "%s su %s",
		free = "GRATIS",
		welcome = "Benvenuto!",
		empty_place = "POSTO LIBERO",
		empty_when = "Domani alle 5",
		week = "DELLA SETTIMANA · %s",
		week_ends = "Scade domenica",
		smith = "LA COMMESSA DEL FABBRO",
		smith_line = "Sempre aperta, la famiglia la scegli tu.",
		shelf = "SCAFFALE",
		shelf_materials = "MATERIALI",
		shelf_fragments = "FRAMMENTI",
		call = "CHIAMA UN CLIENTE",
		deliver = "CONSEGNA",
		none_ready = "Niente di pronto",
		smith_short = "Quella del Fabbro",
		need_network = "Serve la rete",
		missing_obsidian = "Ti mancano %d",
		ready_one = "1 pronta",
		ready_many = "%d pronte",
		cost = "costa %d",
		-- ui/receipt.lua: the orders' part of the podium's receipt
		receipt_title = "COMMESSE",
		receipt_smith = "Il Fabbro",
		receipt_open = "Il Fabbro ti aspetta in bottega",
		-- the test bench (test profiles only: menu/orders_bench.lua)
		closed = "Il Fabbro ti chiama dopo %d partite online: fatte %d su %d",
		bench = "PROVA",
		bench_title = "BANCO DI PROVA",
		bench_day = "GIORNO FINTO: %s",
		bench_won = "PARTITA FINTA VINTA",
		bench_lost = "PARTITA FINTA PERSA",
		bench_day1 = "PASSA UN GIORNO",
		bench_week = "PASSA UNA SETTIMANA",
		bench_client = "ARRIVA UN CLIENTE",
		bench_lucky = "PROSSIMO COLPO BUONO",
		bench_pieces = "RIDAI I PEZZI DEL BANCO",
		bench_reset = "RICOMINCIA DA CAPO",
		bench_state = "%d PARTITE FINTE · %d CLIENTI · %d CONSEGNE",
		-- the windows over the board (menu/orders_ui.lua): the open card
		back = "INDIETRO",
		-- what each client says when it asks (to review with Sergio)
		lines = {
			caronte = "«Le anime mi pagano una moneta. Tu portami quello che chiedo: il remo non si muove da solo.»",
			minosse = "«Giudico tutti, ogni giorno. Portami quello che chiedo e stavolta ti giudico bene.»",
			cerbero = "«Tre teste, tre fami. Sbrigati, che la terza morde.»",
			plutone = "«Ogni cosa ha un prezzo, e il mio lo conosci. Portamelo tutto.»",
			flegias = "«Ti porto io dall'altra parte della palude. Prima però portami il mio carico.»",
			medusa = "«Guardami pure, ma solo dopo avermi portato quello che chiedo.»",
			minotauro = "«Il labirinto è lungo e io ho fame. Muoviti.»",
			malacoda = "«Io e i miei diavoli abbiamo un lavoretto per te. Niente scherzi.»",
		},
		trust = "FIDUCIA · %d",
		pearl = "%d perla",
		pearls = "%d perle",
		trust_bonus = "Ancora %s e le sue commesse danno un frammento in più.",
		trust_gift = "Ancora %s e ti regala %d frammenti %s.",
		asks = "CHIEDE",
		prize = "PREMIO",
		fragment = "frammento %s",
		fragments = "frammenti %s",
		-- where a material drops: "Cade giocando online nel Limbo, ..."
		drops = "Cade giocando online %s, con almeno un'altra persona.",
		drop_place = { scoria = "nella Forgia", piuma = "nel Limbo", vento = "nella Lussuria", grandine = "nella Gola",
			scheggia = "nell'Avarizia", stige = "nell'Ira", tomba = "nell'Eresia", sangue = "nel Flegetonte",
			sabbia = "nel Sabbione", pece = "nelle Malebolge", ghiaccio = "nel Cocito" },
		feat_hint = "Conta in ogni partita online con almeno un'altra persona.",
		cost_upper = "COSTA %d",
		missing = "NE MANCANO %d",
		missing_one = "NE MANCA %d",
		not_ready = "NON ANCORA PRONTA",
		change = "CAMBIA",
		change_free = "GRATIS, UNA AL GIORNO",
		change_tomorrow = "DI NUOVO DOMANI",
		change_never = "QUESTA NON SI CAMBIA",
		swap = "SCAMBIA",
		swap_sub = "3 MATERIALI PER 1",
		swap_none = "CHIEDE UN'IMPRESA",
		-- the swap
		material_one = { scoria = "Scoria", piuma = "Piuma del Limbo", vento = "Vento in bottiglia", grandine = "Chicco di grandine",
			scheggia = "Scheggia di masso", stige = "Acqua dello Stige", tomba = "Polvere di tomba", sangue = "Sangue bollente",
			sabbia = "Sabbia rovente", pece = "Pece", ghiaccio = "Ghiaccio di Cocito" },
		swap_title = "TRE PER UNO · %s",
		swap_line = "Scegli cosa dare: ne dai %d e prendi 1 %s. La Scoria non si scambia: vale già per tutto.",
		swap_pick = "Scegli cosa dare",
		swap_full = "Ne hai già 99",
		you_have = "NE HAI %s",
		-- the Smith's order: the family
		smith_ready = "LA COMMESSA DEL FABBRO È PRONTA",
		family_line = "Il Fabbro lavora per chi vuoi tu: scegli la famiglia dei frammenti.",
		-- the clients' book
		book_title = "I TUOI CLIENTI",
		book_line = "Una perla per ogni consegna. A 5 perle un frammento in più, a 10 trenta frammenti.",
		book_detail = "%s, fiducia %d. %s",
		book_none = "Nessun cliente ancora: arrivano battendo i custodi dei gironi.",
		call_short = "CHIAMA",
		call_when = "Domani alle 5 trovi una commessa di %s.",
		call_done = "Chiamato: domani alle 5 arriva %s.",
		call_yesterday = "%s è venuto ieri: chiamalo domani.",
		-- the delivery (menu/orders_delivery.lua): what the client says, happy and proud
		-- (the lucky strike, the 5th and every 10th pearl); drafts to review with Sergio
		thanks = {
			caronte = "«Bel lavoro. Con questo il remo non si impenna più.»",
			minosse = "«Sentenza: lavoro ben fatto. Puoi andare.»",
			cerbero = "«Tutte e tre le teste approvano. Per oggi niente morsi.»",
			plutone = "«Pagato il giusto, consegnato il giusto. Così mi piace.»",
			flegias = "«Carico a bordo. Oggi la palude sembra più leggera.»",
			medusa = "«Perfetto. Quasi quasi ti guardo negli occhi.»",
			minotauro = "«Buono. Il labirinto sembra già più corto.»",
			malacoda = "«I miei diavoli sono contenti. E io pure, per una volta.»",
		},
		proud = {
			caronte = "«Tanta roba! Ti meriti un passaggio gratis. Quasi.»",
			minosse = "«Lavoro eccellente. Il mio giudizio: il migliore.»",
			cerbero = "«Tre teste, tre volte grazie. Che colpo!»",
			plutone = "«Più di quanto ho pagato? Allora sei un genio, o un pazzo.»",
			flegias = "«Che colpo! Lo racconterò a tutta la palude.»",
			medusa = "«Mi hai lasciata di sasso. E di solito lo faccio io.»",
			minotauro = "«Che forza! Adesso sì che corro nel labirinto.»",
			malacoda = "«Questo sì che è un lavoro da diavoli. Bravo.»",
		},
		smith_done = "«Fatto. La prossima la batto ancora più forte.»",
		lucky_title = "COLPO BUONO",
		delivered = "CONSEGNATA",
		delivered_many = "%d CONSEGNATE",
		r_scaglie = "Scaglie",
		r_fragments = "Frammenti %s",
		r_lucky = "Colpo buono: frammenti %s doppi",
		r_gift = "Regalo di %s: frammenti %s",
		r_trust = "Fiducia di %s",
		r_voucher = "Buono del Fabbro",
		r_obsidian = "Ossidiana al Fabbro",
		upgrade_hint = "I frammenti %s bastano per un livello: tocca POTENZIA.",
		ok = "OK",
	},


	-- menu/armory.lua and ui/step_scene.lua: the pieces' levels in Scaglie
	pieces = {
		grades = { "bronzo", "argento", "oro", "brace" },
		at_max = "AL MASSIMO",
		proof = "%d / %d partite col pezzo addosso",
		proof_first = "prima la prova",
		-- (not POTENZIA: that is the tab already, Sergio 15 Nov)
		upgrade = "+1 LIVELLO",
		-- in the ZAINO: opens the piece's card, with +1 LIVELLO
		upgrade_here = "POTENZIA",
		missing = "mancano %s",
		-- without the network the Armeria can be looked at, not used (the server keeps the progress)
		need_network = "serve la rete",
		pick_ware = "tocca un pezzo",
		in_wardrobe = "ce l'hai già",
		buy = "COMPRA",
		price_only = "%s SCAGLIE",
		-- the price of +1 LIVELLO, beside it: what it buys
		price_for = "per il livello %d",
		step_title = "SCATTO!",
		-- the grade in roman numbers, its name
		step_grade = "GRADO %s · %s",
		step_look = "Aspetto nuovo, firma da rafforzare",
		-- the step 10: the piece's signature can be lit (with Ossidiana)
		step_sign_on = "Aspetto nuovo, firma da accendere",
		step_top = "Al massimo: tutto al pieno",
	},

	-- menu/profile_tabs.lua: the PROFILO's STATISTICHE and CRONOLOGIA PARTITE tabs
	profile_tabs = {
		tab_matches = "CRONOLOGIA PARTITE",
		round_by_round = "COM'È ANDATA, GIRO PER GIRO",
		round_by_round_tap = "COM'È ANDATA, GIRO PER GIRO · TOCCA UN NUMERO PER RIVEDERE DA LÌ",
		history_hint = "le ultime %s partite · tocca una partita per vedere com'è andata",
		vs = "VS",
		no_moments = "nessun momento da ricordare",
		-- STATISTICHE: the four big numbers
		won = "VITTORIE",
		best_streak = "DI FILA",
		stars = "STELLE",
		lost = "SCONFITTE",
		badge_hint = "tocca un record con la medaglia per metterla accanto al tuo nome (al massimo %s)",
		-- the player's card on the left
		level_short = "LIV %s",
		xp = "%s / %s XP",
		next_to_name = "ACCANTO AL TUO NOME",
		won_share = "%s%% delle partite vinte",
		-- the modes, short, as chips
		mode_short = { tutte = "TUTTE", ["2v2"] = "2V2", ["1v1"] = "1V1", torneo = "TORNEO", campagna = "CAMPAGNA" },
		damage_by_weapon = "DANNO PER ARMA",
		legend_primary = "PRIMARIE", legend_secondary = "SECONDARIE",
		nothing_yet = "ancora niente: gioca una partita",
		weapons = {
			missile = "Lanciarune", grenade = "Uovo", shards = "Schegge", punch = "Pugno", sniper = "Cecchino",
			sword = "Lama", eagle = "Tonante", mallet = "Maglio", lunge = "Affondo", bellows = "Mantice",
			boomerang = "Falcetto", tar = "Pece", drill = "Trapano", vortex = "Voragine", cannon = "Cannonata", petard = "Petardo",
		},
		-- CRONOLOGIA PARTITE (os.date formats)
		today = "oggi %H:%M",
		yesterday = "ieri %H:%M",
		outcome_won = "VITTORIA",
		outcome_lost = "SCONFITTA",
		outcome_tie = "PAREGGIO",
		points = "PUNTI",
		no_matches = "Nessuna partita ancora: gioca, e la ritrovi qui.",
	},



	-- menu/home.lua: the home
	home = {
		leave_queue_first = "esci dalla coda",
		-- in the profile's round: the name, until the online accounts give one (placeholder)
		player = "APPRENDISTA",
		-- the level, alone in the banner's gold coin
		level = "%d",
		play_sub = "ONLINE",
		training_sub = "CONTRO I BOT",
		armory_sub = "IL FABBRO",
		-- on the BOTTEGA's door, the Smith's orders ready to deliver
		orders_ready_one = "1 PRONTA", orders_ready = "%d PRONTE",
	},

	-- menu/gear_ui.lua: what the ZAINO and the ARMERIA share
	gear_ui = {
		-- slot and family: "ELMO · CORVO"
		piece = "%s · %s",
		stats = "STATISTICHE",
		-- the column of the stats shows only what changes; this opens all of them
		see_all = "VEDI TUTTE ›",
		-- the colors of the bars: where the points come from
		parts = { "BASE", "LIVELLO", "PEZZI", "SIGILLI" },
		-- the piece chosen changes nothing / your pieces leave everything as at the start
		no_change = "non cambia niente",
		all_base = "tutte come all'inizio",
		-- the sheet of all the stats: back to the pieces
		back_to_pieces = "TORNA AI PEZZI",
		-- a loadout still closed: from which level
		loadout_locked = "DAL LIV %d",
		-- the band at the bottom of the slot of a piece you wear
		worn = "INDOSSATO",
	},

	-- menu/backpack.lua: the ZAINO (from the apprentice), INVENTARIO and SIGILLI
	backpack = {
		title = "ZAINO",
		tab_inventory = "INVENTARIO",
		tab_seals = "SIGILLI",
		loadout = "ASSETTO",
		seal_loadout = "ASSETTO SIGILLI",
		all = "TUTTI",
		nothing = "nessun pezzo qui: li trovi in armeria",
		-- under the piece chosen: level, grade and what it does
		piece_line = "liv %d · grado %s %s",
		wear = "INDOSSA",
		-- under POTENZIA: the level now and the next one
		up_line = "liv %d › %d",
		-- the Sigilli: the points still to spend (a flame each) and those used
		free = "PUNTI LIBERI",
		used = "%d / %d USATI",
		-- under the points of a path: what one point gives, and all of them now
		per_point = "1 PUNTO: %s · ORA %s",
		of = "%d / %d",
		save = "SALVA",
		saved = "salvato",
		-- the Sigilli: a step and its two powers (the chosen one and the other)
		step = "%s · gradino %d",
		other = "l'altra scelta: %s · %s",
		to_choose = "scegli uno dei due",
		pick_hint = "tocca un potere sotto un gradino per sceglierlo",
		-- the stats' sheet of the Sigilli: its way back
		back_to_seals = "TORNA AI SIGILLI",
	},

	-- menu/queue.lua: GIOCA ONLINE, the queues online
	queue = {
		title = "GIOCA ONLINE",
		usual_match = "La modalità di sempre",
		also_counts = "conta anche per: %s",
		-- a running event: when it ends
		event = "evento · %s",
		own_queue = "coda sua",
		counts_in = "conta nel %s",
		no_event = "Nessun evento in corso",
		private = "STANZA PRIVATA",
		private_short = "Con un codice",
		duel_line = "Tu contro uno",
	},


	-- menu/private.lua: the private match (from GIOCA ONLINE)
	private = {
		title = "PARTITA PRIVATA",
		title_short = "CON UN CODICE",
		mode = "MODO",
		modes_short = { ["1v1"] = "1 C 1", ["2v2"] = "2 C 2", ffa = "TUTTI" },
		versus = "VS",
		missing = "MANCANO %d CIFRE",
		missing_one = "MANCA 1 CIFRA",
		-- under VIA: the mode and how many bots
		go_sub = "%s · %d BOT",
		new_room_over = "CON GLI AMICI O CONTRO I BOT",
		new_room = "CREA UNA STANZA",
		new_room_lines = {
			"Scegli la modalità e il livello dei bot,",
			"chi gioca con chi e chi contro chi.",
			"Poi dai il codice agli amici:",
			"entrano al posto di un bot.",
		},
		create = "CREA",
		have_code = "HAI UN CODICE?",
		delete = "CANC",
		join = "ENTRA",
		connecting = "Mi collego...",
		code = "CODICE",
		bot = "BOT",
		bot_level = "LIVELLO %d DI %d",
		bot_level_short = "LIVELLO",
		player = "GIOCATORE",
		level = "LIVELLO %d",
		host = "HA CREATO LA STANZA",
		here = "QUI",
		go = "VIA",
		wait_host = "aspetta chi ha creato la stanza",
		-- after a match, whoever still looks at its results (VIA waits for them)
		on_podium = "AI RISULTATI",
		wait_podium = "aspetta chi guarda i risultati",
	},

	-- menu/lobby.lua: the waiting room online
	lobby = {
		-- one every few seconds under the cards
		tips = {
			"Il tempo che avanzi nel turno ti dà globi per il teletrasporto",
			"Le armi si scelgono coperte: guarda i cartellini degli altri",
			"La secondaria ha due colpi: un colpo di Lama te ne ridà uno",
			"I punti sono la vita che togli agli avversari",
			"Fuori dal tuo turno tocca la targa di un avversario per vedere il suo cartellino",
			"Il Rampino ce l'hanno tutti: chi sta in alto colpisce meglio",
		},
		coming = "IN ARRIVO",
		tip = "CONSIGLIO",
		searching = "CERCO GIOCATORI",
		back_to_menus = "TORNA AI MENU · RESTI IN CODA",
		leave_queue = "ESCI DALLA CODA",
		-- the line at the top: the queue's name, players, time, bots
		title_sep = "%s  ·  ",
		status = "%s%d SU %d  ·  %d:%02d%s",
		bots_in = "  ·  BOT TRA %d s",
		bots_coming = "  ·  ARRIVANO I BOT",
	},

	-- ui/pill.lua and game.gui_script: the queue's pill outside the waiting room
	pill = {
		in_queue = "IN CODA · %s · %d:%02d",
		bots_in = " · BOT TRA %d s",
		bots_coming = " · ARRIVANO I BOT",
		found = "PARTITA TROVATA",
		found_n = "PARTITA TROVATA · %s",
		cancelled = "questa partita contro i bot si annulla",
		lost = "CODA PERSA · TOCCA PER RIENTRARE",
		-- the chip in a match (only head, dots and this)
		short_lost = "PERSA",
		short_bots = "BOT %d",
	},


	-- ui/controller.lua: the controller's buttons, by family, as written on them
	controller = {
		families = {
			xbox = { a = "A", b = "B", x = "X", y = "Y", lb = "LB", rb = "RB", lt = "LT", rt = "RT", start = "MENU", select = "VISTA" },
			playstation = { a = "X", b = "CERCHIO", x = "QUADRATO", y = "TRIANGOLO", lb = "L1", rb = "R1", lt = "L2", rt = "R2",
				start = "OPTIONS", select = "CREATE" },
			nintendo = { a = "B", b = "A", x = "Y", y = "X", lb = "L", rb = "R", lt = "ZL", rt = "ZR", start = "+", select = "-" },
		},
		cross = { su = "CROCE SU", giu = "CROCE GIÙ", sinistra = "CROCE SX", destra = "CROCE DX" },
	},

	-- ui/tag_card.lua: the player's tag
	tag_card = {
		-- the three Sigilli, short (skills.PATHS order)
		branches = { "ALI", "COR", "FUC" },
		no_power = "nessun potere",
		orb = "%s globo",
		orbs = "%s globi",
		parachutes = "%s paracad.",
		air_jumps = "%s in aria",
		tree = "SIGILLI · %s PUNTI",
	},

	-- ui/frames.lua: the frame counter's line at the top (IMPOSTAZIONI > CONTATORE FPS)
	frames = {
		row = "%.0f FPS  PEGGIORE %.0f MS  99%% SOTTO %.0f  SCATTI %d/MIN",
		last = "  ULTIMO: %s",
		-- online: the longest wait between two states from the server in the last 10 s
		net = "  RETE %.0f MS",
	},


	-- battle/hud.lua: the HUD in battle
	hud = {
		-- the weapons' names (on the tag, the card, crates)
		weapons = {
			missile = "LANCIARUNE", grenade = "UOVO DI FIAMMA", shards = "SCIAME DI SCHEGGE", punch = "PUGNO DEL TITANO",
			sniper = "CECCHINO", sword = "LAMA", eagle = "TONANTE", mallet = "MAGLIO", lunge = "AFFONDO", bellows = "MANTICE",
			boomerang = "FALCETTO", tar = "POZZA DI PECE", drill = "TRAPANO", vortex = "VORAGINE", cannon = "CANNONATA", petard = "PETARDO",
			hook = "RAMPINO", janus = "GIANO", teleport = "TELETRASPORTO", parachute = "PARACADUTE", trampoline = "TRAMPOLINO",
		},
		-- the turn's phases on the clock
		second_attack = "SECONDO!",
		take_cover = "RIPARATI",
		-- why a button is off: always two plain words
		not_now = "NON ORA",
		no_orbs = "GLOBI ESAURITI",
		used_m = "GIÀ USATO",
		used_f = "GIÀ USATA",
		no_ammo = "MUNIZIONI ESAURITE",
		-- the swap button's two lines
		swap_1 = "BARATTA IL SECONDO ATTACCO",
		swap_2 = "CON UN TELETRASPORTO",
	},

	-- battle/score.lua: the score at the top
	score = {
		last_round_soon = "TRA POCO: ULTIMO GIRO ×2",
		last_round = "ULTIMO GIRO",
		double_points = "OGNI PUNTO VALE DOPPIO",
		doubled = " ×2",
		turn_of = "Turno di %s  %s",
		get_ready = "PREPARATI",
		turn_row = "TURNO:",
		to_tie = "+%d PER PAREGGIARE",
		-- the gap under your token
		tied_first = "pari col 1°",
		ahead = "+%d sul 2°",
		behind = "%d dal 1°",
	},

	-- battle/guide.lua: the gestures of the guided match; {muove} and {mira} are the sticks' sides
	guide = {
		keys = {
			computer = { cammina = "A   D", salta = "SPAZIO" },
			controller = { cammina = "LEVETTA {muove}", salta = "{muove} IN SU", mira = "LEVETTA {mira}", annulla = "{mira} AL CENTRO" },
		},
	},

	-- battle/quips.lua: what the campaign characters say; the moments are ids (turno, colpisce, colpito, scappa, abbatte, muore)
	quips = {
		by_character = {
		codardo = {
			turno = { "Un colpo e via!", "Non guardarmi così...", "Stavolta non mi prendi!" },
			colpisce = { "Preso! E ora scappo!", "Questo era gratis!", "Colpito e sparito!" },
			colpito = { "Ahia! Non vale!", "Non in faccia!", "Mammaaa!" },
			scappa = { "Prendimi, se ci riesci!", "Ciao ciao!", "Qui non mi trovi!", "Troppo lento!" },
			abbatte = { "Ah ah! Ti ho fregato!", "Chi è il codardo adesso?" },
			muore = { "Tornerò... di nascosto!", "Non era il mio giorno..." },
		},
		testa_calda = {
			turno = { "Arrivo!", "Ora ti spacco!", "Fatti sotto!" },
			colpisce = { "Prendi questa!", "BOOM!" },
			colpito = { "Tutto qui?", "Non sento niente!" },
			abbatte = { "Troppo facile!", "Il prossimo!" },
			muore = { "Rivincita! Subito!", "Non è finita!" },
		},
		cecchino = {
			turno = { "Respira... mira...", "Un colpo solo." },
			colpisce = { "Centro.", "Bersaglio colpito." },
			colpito = { "Questo non era previsto.", "Mi hai trovato..." },
			abbatte = { "Pulito.", "Niente di personale." },
			muore = { "Ricarico e torno.", "Ottima mira. La tua." },
		},
		spingitore = {
			turno = { "Il vuoto ti chiama!", "Che bel bordo..." },
			colpisce = { "Giù di sotto!", "Attento al bordo!" },
			colpito = { "Spingi spingi...", "Ehi, piano!" },
			abbatte = { "Il vuoto ti saluta!", "Volo libero!" },
			muore = { "Ma chi mi ha spinto?" },
		},
		-- the duel of the cortile: she trains you, even when she beats you
		favilla = {
			turno = { "Tocca a me, nuovo!", "Guarda e impara!", "Stavolta miro meglio!" },
			colpisce = { "Preso! Stai attento!", "Questo te lo ricordi!" },
			colpito = { "Ahi! Bel colpo!", "Ehi, così si fa!" },
			scappa = { "Di qua, lumaca!", "Prendimi!" },
			abbatte = { "Rialzati, su!", "Uno a zero per me!" },
			muore = { "Ahia! Bel colpo, apprendista!", "Va bene, va bene: torno subito!" },
		},
		-- Favilla at your side in the Forgia
		favilla_compagna = {
			turno = { "Tocca a me: coprimi!", "Guarda come si fa!" },
			colpisce = { "Preso!", "Uno a zero per noi!" },
			colpito = { "Ahi! Occhio a dove miri!", "Mi hanno presa!" },
			scappa = { "Di qua!", "Arrivo!" },
			abbatte = { "Giù! Avanti il prossimo!", "Bel lavoro di squadra!" },
			muore = { "Torno subito, tienili tu!", "Ahia! Vendicami!" },
		},
		fabbro = {
			turno = { "Il ferro si batte finché è caldo!", "Sull'incudine!" },
			colpisce = { "Martellata!", "Senti il Maglio?" },
			colpito = { "Graffi.", "Il ferro non si piega!" },
			abbatte = { "Un altro per la fornace!", "Forgiato!" },
			muore = { "La Forgia non si spegne...", "Tornerò più duro!" },
		},
		},
	},

	-- battle/card.lua: the card of a new weapon
	card = {
		-- the label at the top of each kind, and the name of its third bar
		kinds = { primaria = "PRIMARIA", secondaria = "SECONDARIA", movimento = "MOVIMENTO", oggetto = "OGGETTO" },
		third_bar = { primaria = "Area", secondaria = "Spinta" },
		bars = { "Danno", "Gittata" },
		ok = "OK",
		-- what each weapon does
		what = {
			missile = "Spara una runa che esplode dove tocca: fa danno a chi è vicino e scava il terreno",
			grenade = "Un uovo che rimbalza e scoppia dopo 5 secondi: cratere grande",
			shards = "Una raffica di 8 schegge: rallenta chi colpisce",
			punch = "Un montante da vicino: lancia in alto e incrina l'armatura",
			sniper = "Parte veloce e cala a poco a poco; rimbalza e sbalza chi colpisce",
			sword = "Sempre con te: un colpo da vicino",
			eagle = "Un colpo dritto e subito; il rinculo ti spinge dall'altra parte",
			mallet = "Un colpo ad arco dove miri; quando sbatte su qualcosa o qualcuno rimbalzi in alto",
			lunge = "Uno scatto che passa oltre chi hai davanti e lo colpisce",
			bellows = "Il soffio della forgia: spinge via chi hai davanti",
			boomerang = "Una falce che va, gira e torna: colpisce due volte, al ritorno incrina l'armatura",
			tar = "Un fiasco che lascia una pozza di pece: chi ci sta brucia, per due turni",
			drill = "Scava una galleria nel terreno e scoppia dall'altra parte: rallenta",
			vortex = "Una sfera nera: dove scoppia apre un buco grande e tira dentro chi e vicino",
			cannon = "Ti lanci come una palla di cannone: chi trovi sulla strada prende l'urto",
			petard = "Una bomba che rimbalza e spinge via, senza scavare",
			hook = "Aggancia un bordo e ti arrampichi; su un nemico, lo tiri da te",
			janus = "La moneta a due facce: il primo che tocca, amico o nemico, si scambia di posto con te",
			parachute = "Aprilo in aria: scendi piano e atterri senza farti male",
			trap = "Posala a terra: chi ci passa resta coi piedi bloccati fino alla fine del suo turno",
			shield = "Ti ripara dai colpi fino al tuo prossimo turno",
			trampoline = "Lancialo: chi ci salta sopra vola lontano dalla parte della freccia",
		},
		-- how to use it, with the controls you have (%s: the buttons)
		parachute_pad = "In aria premi %s",
		item_pad = "Sceglilo fra gli OGGETTI con %s e usalo con %s",
		item_pad_air = "In aria sceglilo fra gli OGGETTI con %s e usalo con %s",
		item_touch = "Toccalo fra gli OGGETTI",
		item_touch_air = "In aria toccalo fra gli OGGETTI",
		aim_pad = "Muovi la levetta %s per sistemare la traiettoria, usa %s per far partire il colpo",
		aim_phone = "Sposta l'analogico di destra per sistemare la traiettoria, rilascialo per far partire il colpo",
		aim_computer = "Trascina dal diavoletto per sistemare la traiettoria, lascia per far partire il colpo",
	},

	-- main/events.lua: the events in words
	events = {
		-- durations: 2g 3h, 3h 20m, 12m
		days_hours = "%dg %dh",
		days = "%dg",
		hours_minutes = "%dh %dm",
		hours = "%dh",
		minutes = "%dm",
		starts_in = "comincia tra %s",
		ends_in = "finisce tra %s",
		-- the line under EVENTI in the home
		no_net = "senza rete",
		running = "%d in corso",
		next_in = "tra %s",
		none_planned = "niente in arrivo",
		kinds = { mod = "MODIFICATORE", torneo = "TORNEO", sfida = "SFIDA", xp = "XP" },
		-- the rules in words, one per line
		weapons = "Armi: %s",
		crate_every_turn = "Una cassa a ogni turno",
		crates_every = "Casse ogni %d turni",
		no_heals = "Niente cure",
		same_level = "Tutti allo stesso livello",
		other_points = "Punti diversi",
		normal_matches = "Le partite normali %s",
		normal_rules = "Regole normali",
		level_cap = "Pezzi al massimo al livello %d",
	},

	-- main/game.gui_script: the match (messages, announcements, gear wheel, draft, lessons)
	match = {
		-- the teams; a player's name is the team's, with a number if there are two
		team_names = { "Rosso", "Blu", "Verde", "Oro" },
		-- after a local bot's name (taken off again on the cards)
		bot_suffix = " (bot)",
		-- the server's errors (server/room.go), then the line that closes them
		server_errors = {
			version = "C'è una versione nuova di MegaBlast:\naggiorna il gioco",
			expired = "La partita è finita",
			draining = "Il server si sta aggiornando,\nriprova tra poco",
			evento = "L'evento è appena finito",
			codice = "Nessuna stanza con questo codice",
			piena = "La stanza è piena",
			partita = "La stanza sta giocando:\nriprova a fine partita",
		},
		server_error = "Errore del server",
		back_to_menu = "%s\nTocca per tornare al menu",
		-- status effects: the shout over the robot and the name under its health (no accents: the font lacks them)
		status_shout = { burn = "BRUCIA!", slow = "RALLENTATO!", cracked = "ARMATURA INCRINATA!" },
		status_name = { burn = "BRUCIA", slow = "LENTO", cracked = "INCRINATO" },
		-- "Rosso trova ..." when a crate opens
		weapon_found = { missile = "il Lanciarune", grenade = "l'Uovo di Fiamma", shards = "lo Sciame di Schegge",
			punch = "il Pugno del Titano", sniper = "il Cecchino", eagle = "il Tonante", mallet = "il Maglio",
			lunge = "l'Affondo", bellows = "il Mantice", boomerang = "il Falcetto", tar = "la Pozza di Pece",
			drill = "il Trapano", vortex = "la Voragine", cannon = "la Cannonata", petard = "il Petardo", hook = "il Rampino", janus = "il Giano", parachute = "un Paracadute",
			trap = "una Trappola", shield = "uno Scudo", trampoline = "un Trampolino" },
		-- the weapons in the match-start draft, and their effect (no accents)
		draft_names = { grenade = "Uovo di Fiamma", shards = "Sciame di Schegge", punch = "Pugno del Titano",
			sniper = "Cecchino", eagle = "Tonante", mallet = "Maglio", lunge = "Affondo", bellows = "Mantice", hook = "Rampino",
			boomerang = "Falcetto", tar = "Pozza di Pece", drill = "Trapano", vortex = "Voragine", cannon = "Cannonata", petard = "Petardo" },
		draft_effects = {
			grenade = "Rimbalza e scoppia dopo 5 s: cratere grande",
			shards = "Raffica di 8 schegge: rallenta",
			punch = "Montante da vicino: lancia in alto e incrina l'armatura",
			sniper = "Parte veloce e cala a poco a poco; rimbalza come una palla e sbalza dove andava",
			eagle = "Colpo dritto e subito; il rinculo ti spinge dall'altra parte",
			mallet = "Colpo ad arco dove miri; quando sbatte su qualcosa o qualcuno rimbalzi in alto",
			lunge = "Scatto che passa oltre chi hai davanti e lo colpisce",
			bellows = "Soffio della forgia: spinge via chi hai davanti",
			boomerang = "Va, gira e torna: colpisce due volte e al ritorno incrina l'armatura",
			tar = "Pozza di pece che brucia chi ci sta, per due turni",
			drill = "Scava una galleria e scoppia dall'altra parte: rallenta",
			vortex = "Apre un buco grande e tira dentro chi e vicino",
			cannon = "Ti lanci in aria: chi trovi sulla strada prende l'urto",
			petard = "Bomba che rimbalza e spinge via, senza scavare",
			hook = "Tira a te il nemico (da lontano lo molla a meta strada), o ti porta sulla piattaforma colpita",
		},
		go = "VIA!",
		your_turn = "IL TUO TURNO",
		turn_of = "TURNO DI: %s",
		-- the gear wheel
		quit_match = "ESCI DALLA PARTITA",
		quit_search = "ESCI DALLA RICERCA",
		aim = "MIRA",
		aim_mode = "MIRA: %s",
		-- the lessons' vignettes, again (battle/vignette.lua)
		reread = "RILEGGI",
		cancel = "ANNULLA",
		items = "OGGETTI",
		-- Grapple and Janus: one of the two per turn (the copper number between them)
		per_turn = "PER TURNO",
		-- entry and waiting room
		loading_events = "Prendo gli eventi dal server...",
		in_queue = "In coda",
		player = "Giocatore",
		connecting = "Mi collego al server...",
		waiting = "Connesso, in attesa...",
		reconnecting = "Connessione persa, mi riconnetto...",
		connection_lost = "Connessione persa",
		no_websocket = "Manca l'estensione WebSocket\nIn Defold: Project > Fetch Libraries",
		-- under each player's card at the start
		roles = { you = "TU", dummy = "BERSAGLIO", mate = "COMPAGNO", opponent = "AVVERSARIO" },
		card_note = "tocca di nuovo e si chiude · il tempo corre",
		-- the messages of the match
		swap = "%s scambia il secondo attacco: +1 teletrasporto",
		-- the Sigilli's powers that fire in a match (sim/skills.lua)
		phoenix = "FENICE! %s esplode",
		last_stand = "ULTIMO RESPIRO! %s resta in piedi",
		orb_time = "SCIA D'OMBRA: %s ha %s secondi in più",
		orbs_one = "%s +%d teletrasporto",
		orbs_many = "%s +%d teletrasporti",
		trapped = "%s finisce in una trappola: piedi bloccati!",
		hooked = "AGGANCIATO!",
		swapped = "SCAMBIO!",
		snapped = "STRAPPO!",
		blown = "SOFFIATO VIA!",
		bounce = "RIMBALZO!",
		knocked = "SBALZATO!",
		parachute = "Paracadute aperto!",
		heal_circle = "Un cerchio di cura: chi ci finisce il turno dentro si cura",
		crate = "Una cassa cade dal cielo!",
		item_drop = "Cade dal cielo %s: chi lo tocca lo prende!",
		-- the map hazards (battle/hazards.lua): the storm's pill and the messages at the end of the round
		storm = "BUFERA",
		gust = "Una raffica di bufera!",
		hail = "Arriva la grandine!",
		boulders = "Rotolano i massi!",
		water = "L'acqua sale!",
		tombs = "Le tombe cambiano!",
		fire_rain = "Piove fuoco!",
		bridge_shaking = "Un ponte trema: corri!",
		collapse = "Il ponte crolla!",
		wings = "Le ali di Lucifero spingono tutti ai bordi!",
		you_found = "%s hai trovato %s!",
		found = "%s trova %s!",
		you_die_alone = "Muori da solo",
		dies_alone = "%s muore da solo",
		dies_alone_given = "%s! %d, +%d a %s",
		dies_alone_penalty = "%s! %d",
		pushes_off = "%s butta giù %s!",
		eliminates = "%s elimina %s!",
		points = " +%d",
		you_won = "Hai vinto!",
		you_lost = "Hai perso!",
		draw = "Pareggio!",
		team_wins = "Vince %s!",
		time_up = "Tempo scaduto!\n%s",
		back_in = "Di nuovo in partita!",
		you_are = "Sei %s",
		opponent_away = "Connessione persa: un bot gioca al suo posto",
		opponent_back = "L'avversario è tornato",
		stand_in = "Un bot finisce il tuo turno, poi tocca a te",
		someone = "Un giocatore",
		left = "%s è uscito",
		opponent_left = "L'avversario è uscito",
		last_round = "×2 ULTIMO GIRO",
		aim_cancelled = "Mira annullata",
		-- the campaign missions
		mission_done = "Fatta!",
		mission_retry = "Riprova",
		-- replays
		replay_gone = "Questo replay non si può più rivedere",
		replay_banner = "REPLAY · TOCCA PER USCIRE",
		replay_broken = "Il replay non torna più: il gioco è cambiato",
		-- {salta}, {annulla}, {cammina}, {mira} in the lessons' lines (sim/missions.lua)
		gestures = {
			telefono = { salta = "spingi in su la levetta di sinistra", annulla = "tocca la metà destra dello schermo",
				cammina = "sposta di lato la levetta di sinistra",
				mira = "sposta l'analogico di destra per sistemare la traiettoria, rilascialo per far partire il colpo" },
			computer = { salta = "premi la barra spaziatrice", annulla = "riporta il mouse sul diavoletto e lascia",
				cammina = "tieni premuto A o D (o le frecce)",
				mira = "trascina dal diavoletto per sistemare la traiettoria, lascia per far partire il colpo" },
		},
		-- with the controller, with its buttons and sticks (%s: the stick's side, then the button)
		pad_aim_trigger = "muovi la levetta %s per la direzione, premi %s per la potenza e lascialo per far partire il colpo",
		pad_aim_release = "muovi la levetta %s per sistemare la traiettoria, premi e lascia %s per far partire il colpo",
		pad_aim_press = "muovi la levetta %s per sistemare la traiettoria, premi %s per far partire il colpo",
		pad_jump_button = "premi %s",
		pad_jump_stick = "spingi in su la levetta %s",
		pad_walk = "sposta di lato la levetta %s",
		pad_cancel = "riporta al centro la levetta %s",
	},
}
