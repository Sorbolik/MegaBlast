-- Fatto da strumenti/grafica/mappe_dipinte.py, non modificare a mano.
-- Le immagini dipinte (client/dipinti, una per densità dello schermo) e i numeri dello
-- sfondo: per ogni gruppo di piani dove sta nella scena di 1280 x 720 (y0 dall'alto, h),
-- quanto segue la camera e quanti pixel della scena scorre al secondo.
return {
	densita = { 1, 2 },
	giro = 2560,
	sfondi = {
		forgia = {
			foschia = { 0.239, 0.227, 0.290 },
			gruppi = {
				{ nome = "lontano", y0 = 68, h = 652, quanto = 0.1, scorre = 2.4 },
				{ nome = "medio", y0 = 267, h = 453, quanto = 0.3, scorre = 8.7 },
				{ nome = "vicino", y0 = 0, h = 720, quanto = 0.6, scorre = 16.7 },
			},
		},
	},
	-- le mappe con il terreno dipinto e il loro sfondo
	mappe = {
		pavimento = "forgia",
		fossa = "forgia",
		missione_primi_passi = "forgia",
		missione_turno = "forgia",
		missione_spostano = "forgia",
		missione_attrezzi = "forgia",
		missione_punti = "forgia",
		missione_fuori_portata = "forgia",
		missione_due_mani = "forgia",
		missione_giu_dal_bordo = "forgia",
	},
}
