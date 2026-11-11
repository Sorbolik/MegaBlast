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
				["4_arrivo_c"] = { { "favilla", "Ah sì? Io sono Favilla, l'apprendista più vecchia. Il più forte, qui, è chi mi sta dietro." } },
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
					{ "didascalia", "Gli stivali sono nell'ARMERIA." },
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
					{ "fabbro", "Lucifero. È finita giù, in fondo all'inferno. Ti ci porto io, un girone alla volta." },
				},
				s_ghiaccio = { { "didascalia", "In fondo all'ultimo girone, nel ghiaccio, Favilla aspetta." } },
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
		starts_at_time = "SI PARTE A FINE TEMPO",
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
		ready = "Pronto",
		ready_guided = "Il Rampino ce l'hai sempre. Nelle altre partite la scelta ha un tempo; qui no. "
			.. "Tocca una scelta per cambiarla, o GIOCA.",
		ready_text = "Il Rampino ce l'hai sempre. Tocca una scelta per cambiarla.",
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
		xp = "XP",
		lines = { match = "Partita", win = "Vittoria", second = "Secondo posto", mvp = "MVP",
			done = "Prima volta", replay = "Rigiocata", daily = "Prima vittoria di oggi",
			level = "Ogni 5 livelli", chapter = "Capitolo finito" },
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
		now = "ORA",
		plate = "OGNI SETTIMANA",
		no_event = "Nessun evento in corso",
		counts_in = "conta nelle partite %s",
		own_queue = "coda sua · %s",
		next = "PROSSIMI · DUE SETTIMANE",
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
		lead = "Punti di vantaggio: %s",
		record_one = "il tuo record: %s stella",
		record = "il tuo record: %s stelle",
	},

	-- menu/tally.lua: the moments of the match, in the profile's history
	tally = {
		final = "finale",
		round = "giro %s",
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
		-- the map of the circles (after the kidnapping, Sergio 11 Nov): the Cortile
		-- and the Forge on the top floor, then the circle you are on and the next,
		-- closed: nothing under it. The circles are placeholders until their levels are written:
		-- { numeral, name, keeper }
		rings = {
			{ "I", "LIMBO", "CARONTE" }, { "II", "LUSSURIA", "MINOSSE" }, { "III", "GOLA", "CERBERO" },
			{ "IV", "AVARIZIA", "PLUTONE" }, { "V", "IRA", "FLEGIÀS" }, { "VI", "ERESIA", "MEDUSA" },
			{ "VII", "VIOLENZA", "MINOTAURO" }, { "VIII", "FRODE", "MALACODA" }, { "IX", "TRADIMENTO", "LUCIFERO" },
		},
		ring_name = "%s · %s",
		ring_locked = "%s · %s · SI APRE BATTENDO %s",
		ring_stars = "%d / %d",
		ring_sub = "GIRONE · %s",
		tap_ring = "TOCCA IL GIRONE PER ENTRARCI",
		coming = "IN ARRIVO",
		coming_line = "I LIVELLI DI QUESTO GIRONE ARRIVANO PRESTO",
		coming_sub = "%s · IN ARRIVO",
		rings_back = "GIRONI",
		cortile = "IL CORTILE",
		fabbro_line = { "«Ti ci porto io,", "un girone alla volta.»" },
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
		custode_line = "Il guardiano del girone. Battilo e si scende.",
	},

	-- menu/lineup.lua: the line-up before the match
	lineup = {
		tap_to_pick = "TOCCA PER SCEGLIERE LE ARMI",
		weapons = "ARMI",
		weapons_in = "ARMI TRA %d:%02d",
		versus = "VS",
	},


	-- menu/settings.lua: IMPOSTAZIONI
	settings = {
		title = "IMPOSTAZIONI",
		-- the settings at the top (profile.SETTINGS) and their values
		choices = {
			mira = "MIRA", sparo = "SPARO COL CONTROLLER", potenza = "POTENZA COL CONTROLLER",
			levette = "LEVETTA CHE MUOVE", fps = "CONTATORE FPS",
		},
		values = {
			lancetta = "LANCETTA", mirino = "MIRINO", pressione = "PREMENDO", rilascio = "LASCIANDO",
			levetta = "LEVETTA", grilletto = "GRILLETTO", destra = "DESTRA", sinistra = "SINISTRA",
			spento = "SPENTO", acceso = "ACCESO",
		},
		-- the controller's commands (controller.COMMANDS)
		commands = {
			spara = "SPARA", salta = "SALTA", primaria = "PRIMARIA DOPO", secondaria = "SECONDARIA DOPO",
			teletrasporto = "TELETRASPORTO", rampino = "RAMPINO", paracadute = "PARACADUTE",
			oggetti = "OGGETTO DOPO", usa_oggetto = "USA L'OGGETTO", baratto = "BARATTO", zoom = "ZOOM",
		},
		controller_keys = "TASTI DEL CONTROLLER",
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
	},

	-- menu/armory.lua: ARMERIA, gear sets and the skill tree
	armory = {
		-- the stats on the right (the effects of the pieces use them in lowercase)
		stats = {
			max_hp = "Vita", walk_speed = "Corsa", jump_height = "Salto", air_speed = "In aria",
			teleport_ticks = "Teletrasporto", teleports = "Teletrasporti", parachutes = "Paracadute",
			air_jumps = "Salti in aria", fall_damage_mul = "Danno da caduta", knockback_mul = "Spinta subita",
			trap_radius = "Raggio trappole", status_turns = "Turni degli effetti", burning_blasts = "Colpi brucianti",
		},
		yes = "sì",
		no = "no",
		seconds = "%.1f s",
	},


	-- menu/pieces.lua and ui/step_scene.lua: the pieces' levels in Scaglie
	pieces = {
		empty = "nessuno",
		-- no piece in the chosen slot (the slot in lowercase)
		choose = "scegli qui sotto cosa indossare: %s",
		-- slot and set: "ELMO · CORVO"
		piece = "%s · %s",
		of_max = "%d / %d",
		-- grade in roman numbers, its name, the piece's effects
		grade = "grado %s · %s · %s",
		grades = { "bronzo", "argento", "oro", "brace" },
		at_max = "AL MASSIMO",
		next_level = "LIVELLO %d",
		next_step = "SCATTO %d · GRADO %s, %s",
		-- the Proof of a step: matches played wearing the piece
		proof_name = "PROVA",
		proof = "%d / %d partite col pezzo addosso",
		proof_first = "prima la prova",
		-- on the action: the price and the level it buys
		price = "%s SCAGLIE · LIVELLO %d",
		variant = "VARIANTE",
		at_level = "AL %d",
		upgrade = "POTENZIA",
		missing = "mancano %s",
		-- the Smith's hand, with the full price
		smith_name = "MANO DEL FABBRO",
		smith_hand = "costa il 30%% in meno (era %s)",
		set_bonus = "BONUS DEL SET %s",
		others = "INDOSSA IL SET",
		set_level = "%s · %d",
		step_title = "SCATTO!",
		step_new = "NUOVO",
		-- the grade in roman numbers, its name
		step_grade = "GRADO %s · %s",
		step_look = "Aspetto nuovo",
		step_top = "Al massimo: verso la variante B",
	},

	-- menu/profile_tabs.lua: the profile's SCHEDA, STATISTICHE and PARTITE tabs
	profile_tabs = {
		title = "IL TUO DIAVOLETTO",
		your_devil = "DIAVOLETTO",
		no_piece_short = "VUOTO",
		loadout_locked = "%s: LIV %s",
		tab_sheet = "SCHEDA",
		tab_seals = "SIGILLI",
		tab_matches = "PARTITE",
		level = "LIV %s",
		level_braci = "LIV %s · %s BRACI",
		-- SCHEDA
		loadout = "ASSETTO",
		loadout_n = "ASSETTO %s",
		how_others_see = "COSÌ TI VEDONO",
		next_steps = "PROSSIMI SCATTI",
		-- "Maschera del Corvo": the piece, then the set
		piece_of = { default = "%s del %s", fornace = "%s della %s" },
		next_look = "al %s: aspetto %s",
		next_look_b = "al %s: aspetto %s e variante B",
		all_steps = "tutti gli scatti presi",
		pick_in_armory = "sceglilo nell'ARMERIA",
		-- STATISTICHE
		matches = "PARTITE",
		won = "VINTE",
		accuracy = "PRECISIONE",
		best_streak = "SERIE MIGLIORE",
		badge_hint = "tocca un badge per metterlo accanto al tuo nome (al massimo %s)",
		next_to_name = "ACCANTO AL NOME",
		next_at = "prossimo a %s",
		badge_grade = "%s %s",
		no_badge = "senza badge",
		damage_by_weapon = "DANNO PER ARMA",
		nothing_yet = "ancora niente: gioca una partita",
		weapons = {
			missile = "Lanciarune", grenade = "Uovo", shards = "Schegge", punch = "Pugno", sniper = "Cecchino",
			sword = "Lama", eagle = "Tonante", mallet = "Maglio", lunge = "Affondo", bellows = "Mantice",
			boomerang = "Falcetto", tar = "Pece", drill = "Trapano", magnet = "Calamita", cannon = "Cannonata", petard = "Petardo",
		},
		-- PARTITE (os.date formats)
		today = "oggi %H:%M",
		yesterday = "ieri %H:%M",
		outcome_won = "VINTA",
		outcome_lost = "PERSA",
		outcome_tie = "PARI",
		no_matches = "Nessuna partita ancora: gioca, e la ritrovi qui.",
		round_by_round = "COM'È ANDATA, GIRO PER GIRO",
		moments = "MOMENTI · TOCCA PER RIVEDERLO DA LÌ",
		no_moments = "nessun momento da ricordare",
		replay_local_only = "replay solo delle partite su questo telefono",
		replay_missing = "replay non disponibile",
	},


	-- menu/seals.lua: the profile's SIGILLI tab (the paths of sim/skills.lua)
	seals = {
		points_of = "/ %s PUNTI",
		free = "%s LIBERI",
		reset = "AZZERA",
		-- a closed loadout: its number and the level that opens it
		of = "%s / %s",
		threshold = "%s · SOGLIA %s",
		taken = "potere preso",
		choose_now = "scegli il potere",
		missing_one = "manca %s punto",
		missing = "mancano %s punti",
		-- points the threshold needs, free points: not enough
		missing_free = "servono %s punti, liberi %s",
		bring_here = "PORTA QUI",
		in_match = "IN PARTITA",
		nothing = "ancora niente: metti un punto con +",
		no_power = "nessun potere ancora",
	},

	-- menu/home.lua: the home
	home = {
		leave_queue_first = "esci dalla coda per giocarla",
		same_phone = "STESSO TELEFONO",
		your_devil = "DIAVOLETTO",
		level = "LIV %d",
		play_sub = "2 CONTRO 2",
		training_sub = "CONTRO I BOT",
	},

	-- menu/queue.lua: GIOCA ONLINE, the queues online
	queue = {
		title = "GIOCA ONLINE",
		online = "IN RETE",
		search = "CERCA",
		usual_match = "LA PARTITA DI SEMPRE",
		also_counts = "CONTA ANCHE PER: %s",
		event = "EVENTO · %s",
		private = "PARTITA PRIVATA",
		private_line = "Una stanza con un codice: amici e bot dove vuoi tu",
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
		delete = "CANCELLA",
		join = "ENTRA",
		connecting = "Mi collego...",
		code = "CODICE",
		bot = "BOT",
		bot_level = "LIVELLO %d DI %d",
		player = "GIOCATORE",
		level = "LIVELLO %d",
		host = "HA CREATO LA STANZA",
		here = "QUI",
		go = "VIA",
		wait_host = "aspetta chi ha creato la stanza",
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
			boomerang = "FALCETTO", tar = "POZZA DI PECE", drill = "TRAPANO", magnet = "CALAMITA", cannon = "CANNONATA", petard = "PETARDO",
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
			turno = { "Tocca a me: copritemi!", "Guarda come si fa!" },
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
			magnet = "Tira verso un punto davanti a te tutti i robot vicini",
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
		next_in = "il prossimo tra %s",
		none_planned = "nessuno in programma",
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
			drill = "il Trapano", magnet = "la Calamita", cannon = "la Cannonata", petard = "il Petardo", hook = "il Rampino", janus = "il Giano", parachute = "un Paracadute",
			trap = "una Trappola", shield = "uno Scudo", trampoline = "un Trampolino" },
		-- the weapons in the match-start draft, and their effect (no accents)
		draft_names = { grenade = "Uovo di Fiamma", shards = "Sciame di Schegge", punch = "Pugno del Titano",
			sniper = "Cecchino", eagle = "Tonante", mallet = "Maglio", lunge = "Affondo", bellows = "Mantice", hook = "Rampino",
			boomerang = "Falcetto", tar = "Pozza di Pece", drill = "Trapano", magnet = "Calamita", cannon = "Cannonata", petard = "Petardo" },
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
			magnet = "Tira a un punto davanti a te chi e vicino",
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
		opponent_away = "L'avversario ha perso la connessione...",
		opponent_back = "L'avversario è tornato",
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
