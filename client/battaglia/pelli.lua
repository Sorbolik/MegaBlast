-- Fatto da strumenti/stampino/taglia.py, non modificare a mano.
-- Le pelli: i pezzi nuovi del diavoletto disegnati sullo stampino. Ogni pezzo
-- va in un posto dello scheletro (come i pezzi di battaglia/diavoletto.lua:
-- immagine, centro rispetto al perno, misura) e sostituisce il pezzo di base
-- o si disegna sopra. Una pelle per categoria; quelle sopra in ordine. Una
-- coda nuova ha le sue lunghezze e i suoi angoli a riposo (radianti).
return {
	sostituisce = { "personaggio", "testa", "corpo", "ali", "coda" },
	sopra = { "pantaloni", "maglia", "corazza", "guanti", "elmo" },
	pelli = {
		gabriella = { categoria = "personaggio", coda = { 19.4, 30.0, 30.4, 23.2, 25.1 }, coda_riposo = { 3.607, 3.008, 1.405, 0.679, 1.963 }, pezzi = {
			ala = { img = "gabriella_ala", tinta = nil, x = -18.8, y = 4.4, w = 52.6, h = 51.1, modo = "sostituisce" },
			braccio = { img = "gabriella_braccio", tinta = nil, x = 1.8, y = -24.6, w = 31.7, h = 69.4, modo = "sostituisce" },
			braccio_dietro = { img = "gabriella_braccio_dietro", tinta = nil, x = 1.8, y = -24.6, w = 31.7, h = 69.4, modo = "sostituisce" },
			busto = { img = "gabriella_busto", tinta = nil, x = 0.0, y = 12.5, w = 69.7, h = 103.4, modo = "sostituisce" },
			coda_1 = { img = "gabriella_coda_1", tinta = nil, x = 13.4, y = 0.5, w = 24.6, h = 7.4, modo = "sostituisce" },
			coda_1_bordo = { img = "gabriella_coda_1_bordo", tinta = nil, x = 11.1, y = 0.8, w = 29.1, h = 15.4, modo = "sostituisce" },
			coda_2 = { img = "gabriella_coda_2", tinta = nil, x = 13.6, y = 0.3, w = 40.0, h = 10.3, modo = "sostituisce" },
			coda_2_bordo = { img = "gabriella_coda_2_bordo", tinta = nil, x = 14.1, y = 0.7, w = 41.1, h = 18.0, modo = "sostituisce" },
			coda_3 = { img = "gabriella_coda_3", tinta = nil, x = 15.2, y = 1.9, w = 36.0, h = 13.7, modo = "sostituisce" },
			coda_3_bordo = { img = "gabriella_coda_3_bordo", tinta = nil, x = 13.4, y = 3.2, w = 43.1, h = 19.7, modo = "sostituisce" },
			coda_4 = { img = "gabriella_coda_4", tinta = nil, x = 11.6, y = -0.2, w = 32.3, h = 6.6, modo = "sostituisce" },
			coda_4_bordo = { img = "gabriella_coda_4_bordo", tinta = nil, x = 11.9, y = -1.5, w = 32.9, h = 13.1, modo = "sostituisce" },
			coda_5 = { img = "gabriella_coda_5", tinta = nil, x = 20.8, y = 4.5, w = 49.4, h = 24.3, modo = "sostituisce" },
			coda_5_bordo = { img = "gabriella_coda_5_bordo", tinta = nil, x = 24.1, y = 5.2, w = 58.9, h = 38.9, modo = "sostituisce" },
			gamba = { img = "gabriella_gamba", tinta = nil, x = 4.3, y = -33.9, w = 53.4, h = 90.6, modo = "sostituisce" },
			gamba_dietro = { img = "gabriella_gamba_dietro", tinta = nil, x = 4.6, y = -31.1, w = 58.0, h = 83.1, modo = "sostituisce" },
			pugno = { img = "gabriella_pugno", tinta = nil, x = 0.0, y = 0.0, w = 28.6, h = 30.9, modo = "sostituisce" },
			testa = { img = "gabriella_testa", tinta = nil, x = 6.4, y = 53.5, w = 122.9, h = 144.0, modo = "sostituisce" },
			testa_colpita = { img = "gabriella_testa_colpita", tinta = nil, x = 6.3, y = 53.5, w = 121.4, h = 144.0, modo = "sostituisce" },
			testa_felice = { img = "gabriella_testa_felice", tinta = nil, x = 6.3, y = 53.5, w = 120.3, h = 144.0, modo = "sostituisce" },
			testa_ko = { img = "gabriella_testa_ko", tinta = nil, x = 6.3, y = 53.5, w = 120.6, h = 144.0, modo = "sostituisce" },
		} },
		gabriella_squadra = { categoria = "personaggio", coda = { 17.6, 25.2, 28.1, 31.4, 25.7 }, coda_riposo = { 3.757, 3.277, 2.298, 1.191, 2.099 }, pezzi = {
			ala = { img = "gabriella_squadra_ala", tinta = nil, x = -17.4, y = 4.8, w = 48.6, h = 55.7, modo = "sostituisce" },
			braccio = { img = "gabriella_squadra_braccio", tinta = nil, x = 1.8, y = -24.7, w = 31.4, h = 69.7, modo = "sostituisce" },
			braccio_dietro = { img = "gabriella_squadra_braccio_dietro", tinta = nil, x = 1.8, y = -24.7, w = 31.4, h = 69.7, modo = "sostituisce" },
			busto = { img = "gabriella_squadra_busto", tinta = "gabriella_squadra_busto_tinta", x = 0.0, y = 12.2, w = 71.1, h = 101.4, modo = "sostituisce" },
			coda_1 = { img = "gabriella_squadra_coda_1", tinta = nil, x = 13.0, y = 0.1, w = 23.1, h = 8.3, modo = "sostituisce" },
			coda_1_bordo = { img = "gabriella_squadra_coda_1_bordo", tinta = nil, x = 10.8, y = 0.7, w = 27.7, h = 15.7, modo = "sostituisce" },
			coda_2 = { img = "gabriella_squadra_coda_2", tinta = nil, x = 12.0, y = 0.1, w = 38.6, h = 10.0, modo = "sostituisce" },
			coda_2_bordo = { img = "gabriella_squadra_coda_2_bordo", tinta = nil, x = 12.0, y = 0.9, w = 38.6, h = 17.1, modo = "sostituisce" },
			coda_3 = { img = "gabriella_squadra_coda_3", tinta = nil, x = 13.9, y = 1.5, w = 40.0, h = 14.0, modo = "sostituisce" },
			coda_3_bordo = { img = "gabriella_squadra_coda_3_bordo", tinta = nil, x = 11.8, y = 1.9, w = 44.9, h = 21.7, modo = "sostituisce" },
			coda_4 = { img = "gabriella_squadra_coda_4", tinta = nil, x = 15.4, y = -0.2, w = 43.4, h = 9.1, modo = "sostituisce" },
			coda_4_bordo = { img = "gabriella_squadra_coda_4_bordo", tinta = nil, x = 14.0, y = 1.0, w = 46.3, h = 15.4, modo = "sostituisce" },
			coda_5 = { img = "gabriella_squadra_coda_5", tinta = nil, x = 21.4, y = 3.2, w = 52.6, h = 32.3, modo = "sostituisce" },
			coda_5_bordo = { img = "gabriella_squadra_coda_5_bordo", tinta = nil, x = 24.1, y = 3.8, w = 62.6, h = 46.0, modo = "sostituisce" },
			gamba = { img = "gabriella_squadra_gamba", tinta = nil, x = 4.4, y = -33.1, w = 54.6, h = 88.3, modo = "sostituisce" },
			gamba_dietro = { img = "gabriella_squadra_gamba_dietro", tinta = nil, x = 4.6, y = -31.6, w = 57.4, h = 84.3, modo = "sostituisce" },
			pugno = { img = "gabriella_squadra_pugno", tinta = nil, x = 0.0, y = 0.0, w = 29.4, h = 30.0, modo = "sostituisce" },
			testa = { img = "gabriella_squadra_testa", tinta = nil, x = 6.3, y = 54.1, w = 121.7, h = 145.7, modo = "sostituisce" },
			testa_colpita = { img = "gabriella_squadra_testa_colpita", tinta = nil, x = 6.2, y = 54.2, w = 119.7, h = 146.0, modo = "sostituisce" },
			testa_felice = { img = "gabriella_squadra_testa_felice", tinta = nil, x = 6.3, y = 54.3, w = 121.7, h = 146.3, modo = "sostituisce" },
			testa_ko = { img = "gabriella_squadra_testa_ko", tinta = nil, x = 6.3, y = 54.6, w = 120.3, h = 146.9, modo = "sostituisce" },
		} },
	},
}
