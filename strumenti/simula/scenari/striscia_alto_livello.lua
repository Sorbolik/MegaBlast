-- Livello di prova per la striscia in alto (scenario striscia_alto.txt): una riga corta
-- e una lunga di Favilla, subito, a tempo.
return {
	capitolo = "addestramento",
	dipinto = false,
	livello = {
		id = "striscia_alto",
		titolo = "Striscia",
		tipo = "bersagli",
		arena = { { 200, 0, 1500, 150 } },
		spawns = { { x = 600, from = 600 }, { x = 1200, from = 600 } },
		giocatori = { { team = 1 }, { team = 2, dummy = true } },
		vedi = { "missile" },
		without_time = true,
		obiettivo = { { hit = 2, con = "missile", testo = "Colpisci il fantoccio" } },
		righe = {
			{ testo = "Da qui contano i punti: danno uguale punti, abbattere vale 50, buttare nel vuoto altri 50. Guarda i miei, e poi prova anche tu a fare lo stesso!", secondi = 40, quando = { turno = 1, di_turno = "tu" } },
			{ testo = "Così, stammi dietro!", faccia = "ride", secondi = 3, quando = { turno = 1, di_turno = "tu" } },
		},
	},
}
