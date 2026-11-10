-- Un livello come lo manda il GIOCA del Copione (scenario copione.txt): Stammi
-- dietro con un gradino in più, la partenza spostata e la prima riga cambiata
return {
	capitolo = "addestramento",
	dipinto = false,
	livello = {
		id = "primi_passi",
		titolo = "Stammi dietro",
		tipo = "corsa",
		goal_text = "Prova dal Copione: il gradino nuovo è a sinistra. {cammina}",
		highlight = "cammina",
		arena = { { 240, 0, 1440, 150 }, { 1100, 150, 580, 30 }, { 700, 150, 120, 60 } },
		spawns = { { x = 360, from = 600 }, { x = 300, from = 600 } },
		giocatori = { { team = 1 }, { team = 2, dummy = true } },
		nascosti = { 2 },
		vedi = {},
		no_weapons = true, without_time = true,
		obiettivo = {
			{ reach = { x = 1100, y = 180 }, testo = "Salta sul gradino" },
		},
	},
}
