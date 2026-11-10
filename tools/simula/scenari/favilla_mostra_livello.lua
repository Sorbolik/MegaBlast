-- Un livello di prova per Favilla che mostra le mosse (scenario favilla_mostra.txt):
-- scende dal ballatoio col paracadute, spara al fantoccio, poi ti aspetta e
-- usa il Rampino per tornare su
return {
	capitolo = "addestramento",
	dipinto = false,
	livello = {
		id = "favilla_mostra",
		titolo = "Guarda e ripeti",
		tipo = "bersagli",
		arena = { { 200, 0, 1500, 150 }, { 240, 150, 420, 300 } },
		spawns = { { x = 1150, from = 600 }, { x = 1580, from = 600 }, { x = 500, from = 800 } },
		giocatori = { { team = 1 }, { team = 2, dummy = true },
			{ team = 1, insegna = true, nome = "Favilla", pelle = "favilla" } },
		vedi = { "missile" },
		without_time = true,
		dimostra = {
			{ mosse = {
				{ dice = "Guarda come si fa!" },
				{ cammina = 720 },
				{ arma = "parachute" },
				{ arma = "missile", angolo = 30, potenza = 0.7 },
				{ posa = "vittoria", secondi = 1.5 },
			} },
			{ quando = { vicino = 200 }, mosse = {
				{ dice = "E col Rampino si risale!" },
				{ cammina = 720 },
				{ arma = "hook", angolo = 105 },
			} },
		},
		obiettivo = { { hit = 2, con = "missile", testo = "Colpisci il fantoccio come Favilla" } },
		righe = { { testo = "Ora prova tu: {mira}", quando = { evento = "demo_end" } } },
	},
}
