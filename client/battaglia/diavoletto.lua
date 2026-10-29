-- Fatto da strumenti/grafica/diavoletto.py, non modificare a mano.
-- Il diavoletto a pezzi, in unità del disegno (ALTEZZA dai piedi alla cima
-- della testa, y verso l'alto, guarda a destra). Per ogni pezzo: immagine
-- (tinta: la parte col colore della squadra), centro (x, y) rispetto al suo
-- perno e misura (w, h). I punti dicono dove vanno i perni, dal centro dei
-- piedi (la cima dal collo).
return {
	altezza = 200,
	px = 1.18,  -- pixel delle immagini per unità
	bordo = 7.7,  -- spessore del contorno
	pezzi = {
		testa = { img = "testa", tinta = nil, x = 4.0, y = 60.0, w = 124, h = 148 },
		testa_colpita = { img = "testa_colpita", tinta = nil, x = 4.0, y = 60.0, w = 124, h = 148 },
		testa_felice = { img = "testa_felice", tinta = nil, x = 4.0, y = 60.0, w = 124, h = 148 },
		testa_ko = { img = "testa_ko", tinta = nil, x = 4.0, y = 60.0, w = 124, h = 148 },
		busto = { img = "busto", tinta = nil, x = 0.0, y = 11.0, w = 84, h = 94 },
		gamba = { img = "gamba", tinta = nil, x = 4.0, y = -35.0, w = 60, h = 98 },
		gamba_dietro = { img = "gamba_dietro", tinta = nil, x = 4.0, y = -35.0, w = 60, h = 98 },
		braccio = { img = "braccio", tinta = nil, x = 2.0, y = -24.0, w = 40, h = 72 },
		braccio_dietro = { img = "braccio_dietro", tinta = nil, x = 2.0, y = -24.0, w = 40, h = 72 },
		pugno = { img = "pugno", tinta = nil, x = 0.0, y = 0.0, w = 32, h = 32 },
		ala = { img = "ala", tinta = nil, x = -20.0, y = 4.0, w = 60, h = 56 },
		paracadute = { img = "paracadute", tinta = "paracadute_tinta", x = 0.0, y = 2.0, w = 200, h = 324 },
		coda_1 = { img = "coda_1", tinta = nil, x = 23.0, y = 0.0, w = 70, h = 56 },
		coda_1_bordo = { img = "coda_1_bordo", tinta = nil, x = 23.0, y = 0.0, w = 70, h = 56 },
		coda_2 = { img = "coda_2", tinta = nil, x = 23.0, y = 0.0, w = 70, h = 56 },
		coda_2_bordo = { img = "coda_2_bordo", tinta = nil, x = 23.0, y = 0.0, w = 70, h = 56 },
		coda_3 = { img = "coda_3", tinta = nil, x = 23.0, y = 0.0, w = 70, h = 56 },
		coda_3_bordo = { img = "coda_3_bordo", tinta = nil, x = 23.0, y = 0.0, w = 70, h = 56 },
		coda_4 = { img = "coda_4", tinta = nil, x = 23.0, y = 0.0, w = 70, h = 56 },
		coda_4_bordo = { img = "coda_4_bordo", tinta = nil, x = 23.0, y = 0.0, w = 70, h = 56 },
		coda_5 = { img = "coda_5", tinta = nil, x = 22.0, y = 0.0, w = 68, h = 56 },
		coda_5_bordo = { img = "coda_5_bordo", tinta = nil, x = 22.0, y = 0.0, w = 68, h = 56 },
		fiammella = { img = "fiammella", tinta = "fiammella_tinta", x = 0.0, y = 30.0, w = 36.2, h = 76 },
	},
	punti = {
		collo = { 0, 122 },
		bacino = { 0, 76 },
		anche = { 12, 76 },
		spalle = { 32, 110 },
		ala = { -16, 116 },
		coda = { -10, 70 },
		cima = { 0, 82 },
	},
	coda = { 26, 26, 26, 26, 24 },  -- lunghezza dei segmenti
	coda_riposo = { 3.491, 2.793, 2.094, 1.571, 1.134 },  -- angoli a riposo
	paracadute_y = 262,  -- il perno del paracadute, dai piedi
}
