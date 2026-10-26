-- Fatto da strumenti/grafica/scoria.py, non modificare a mano.
-- Per ogni pezzo del diavoletto: centro (x, y) e misura (w, h) dell'immagine e
-- perno (px, py) attorno a cui gira, in unità del disegno (corpo 150 x 200, y verso
-- il basso, piedi a 200). La gamba ha il perno in (0, 0): la mette il codice sulle anche.
-- La coda è una catena: ogni segmento gira attorno al proprio perno.
return {
	testa = { x = 71.22, y = 49.28, w = 101.20, h = 118.40, px = 69.00, py = 97.00 },
	busto = { x = 59.16, y = 129.88, w = 84.00, h = 84.00, px = 69.00, py = 155.70 },
	gamba = { x = 3.71, y = 20.45, w = 47.20, h = 63.60, px = 0.00, py = 0.00 },
	fiammella = { x = 72.08, y = -5.47, w = 31.20, h = 51.20, px = 72.00, py = 13.00 },
	coda = {
		[1] = { x = 36.77, y = 150.86, w = 35.60, h = 24.40, px = 45.71, py = 148.95 },
		[2] = { x = 18.21, y = 146.98, w = 36.00, h = 32.40, px = 26.86, py = 153.54 },
		[3] = { x = 9.77, y = 134.94, w = 24.80, h = 38.00, px = 11.14, py = 142.54 },
		[4] = { x = 14.33, y = 115.82, w = 31.20, h = 34.00, px = 9.14, py = 123.14 },
		[5] = { x = 5.66, y = 87.36, w = 49.20, h = 59.60, px = 19.36, py = 106.16 },
	},
}
