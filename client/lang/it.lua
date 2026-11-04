-- The game's texts in Italian (lang/text.lua explains how they are used).
-- One group per screen or module, named like the file; %s and %d are where
-- the code puts names and numbers.

return {
	-- shared by many screens
	common = {
		play = "GIOCA",
		quit = "ESCI",
		next = "AVANTI",
		modes = { ["1v1"] = "1 CONTRO 1", ["2v2"] = "2 CONTRO 2", ffa = "TUTTI CONTRO TUTTI" },
		opens_with = "Si apre con %s stelle",
		campaign = "CAMPAGNA",
		events = "EVENTI",
		tournament = "TORNEO",
		all = "TUTTE",
	},

	-- menu/pick.lua: the weapon draft
	pick = {
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
		title = "ALLENAMENTO",
		mode = "MODO",
		bot = "BOT",
		levels = { facile = "FACILE", normale = "NORMALE", difficile = "DIFFICILE" },
		pick_map = "SCEGLI LA MAPPA",
		mode_and_bot = "%s  ·  BOT %s",
		random = "A CASO",
		circle = "GIRONE %s",
	},

	-- menu/podium.lua: the podium at the end of the match
	podium = {
		modes = { ["1v1"] = "UNO CONTRO UNO", ["2v2"] = "DUE CONTRO DUE", ffa = "TUTTI CONTRO TUTTI" },
		points = "%d punti",
		tie = "PAREGGIO",
		victory = "VITTORIA",
		defeat = "SCONFITTA",
		wins = "VINCE %s",
		level = "LIVELLO %d",
		xp = "+%d esperienza",
		skill_point = "nuovo punto abilità!",
		replay = "RIVEDI",
		go_on = "CONTINUA",
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
		no_event = "Nessun evento in corso",
		counts_in = "conta nelle partite %s",
		own_queue = "coda sua · %s",
		next = "PROSSIMI",
		nothing_planned = "Niente in programma",
		what_changes = "COSA CAMBIA",
		from_to = "%s  fino a  %s",
		back_on = "torna %s",
		prizes = "PREMI",
		just_for_fun = "Solo per divertirsi",
		offline = "Il server non risponde: gli eventi tornano appena c'è la rete",
	},

	-- menu/level_end.lua: the end of a campaign mission
	level_end = {
		done = "MISSIONE FATTA",
		lead = "Punti di vantaggio: %s",
		record_one = "il tuo record: %s stella",
		record = "il tuo record: %s stelle",
		retry = "RIPROVA",
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
		opens_with = "Si apre con %s stelle: ne hai %s",
		stars_hint = "Le stelle si prendono nelle missioni dei capitoli prima",
	},

	-- menu/lineup.lua: the line-up before the match
	lineup = {
		tap_to_pick = "TOCCA PER SCEGLIERE LE ARMI",
		weapons_in = "ARMI TRA",
		versus = "VS",
		bot = "BOT",
		power = "%s potere",
		powers = "%s poteri",
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
		title = "ARMERIA",
		tab_set = "SET",
		tab_tree = "ALBERO",
		loadout = "ASSETTO",
		stats_title = "STATISTICHE",
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
		tier = "tier %s",
		no_piece = "nessun pezzo",
		-- a set bonus not unlocked yet: the bonus, then the level the pieces need
		locked_bonus = "%s  (tutti i pezzi al livello %s)",
		point = "%s punto",
		points = "%s punti",
		points_spent = "PUNTI %d / %d",
		level = "livello %d",
		per_rank = "%s per grado",
		reset = "AZZERA",
	},


	-- menu/profile_tabs.lua: the profile's SCHEDA, STATISTICHE and PARTITE tabs
	profile_tabs = {
		tab_sheet = "SCHEDA",
		tab_stats = "STATISTICHE",
		tab_matches = "PARTITE",
		level = "LIV %s",
		xp = "%s / %s XP",
		bot = "BOT",
		-- SCHEDA
		you = "Tu",
		loadout = "ASSETTO",
		loadout_n = "ASSETTO %s",
		slot_level = "%s %s",
		slot_empty = "%s · VUOTO",
		how_others_see = "COSÌ TI VEDONO",
		next_steps = "PROSSIMI SCATTI",
		steps_hint = "ogni 10 livelli un aspetto nuovo, al 30 la variante B",
		-- "Maschera del Corvo": the piece, then the set
		piece_of = { default = "%s del %s", fornace = "%s della %s" },
		next_look = "al %s: aspetto %s",
		next_look_b = "al %s: aspetto %s e variante B",
		all_steps = "tutti gli scatti presi",
		no_piece = "nessun pezzo",
		pick_in_armory = "sceglilo nell'ARMERIA",
		armory = "ARMERIA",
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
		damage_hint = "quanto del tuo danno, arma per arma",
		nothing_yet = "ancora niente: gioca una partita",
		weapons = {
			missile = "Lanciarune", grenade = "Uovo", shards = "Schegge", punch = "Pugno", sniper = "Cecchino",
			sword = "Lama", eagle = "Tonante", mallet = "Maglio", lunge = "Affondo", bellows = "Mantice",
		},
		-- PARTITE (os.date formats)
		today = "oggi %H:%M",
		yesterday = "ieri %H:%M",
		outcome_won = "VINTA",
		outcome_lost = "PERSA",
		outcome_tie = "PARI",
		chart_end = "FINE",
		chart_round = "giro %s",
		last_matches = "LE ULTIME %s · I REPLAY DI QUELLE GIOCATE SU QUESTO TELEFONO",
		no_matches = "Nessuna partita ancora: gioca, e la ritrovi qui.",
		round_by_round = "COM'È ANDATA, GIRO PER GIRO",
		moments = "MOMENTI · TOCCA PER RIVEDERLO DA LÌ",
		no_moments = "nessun momento da ricordare",
		replay = "RIVEDI",
		replay_local_only = "replay solo delle partite su questo telefono",
		replay_missing = "replay non disponibile",
	},
}
