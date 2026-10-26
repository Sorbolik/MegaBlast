-- Fatto da strumenti/grafica/scoria.py, non modificare a mano.
-- Per ogni pezzo del diavoletto: centro (x, y) e misura (w, h) dell'immagine e
-- perno (px, py) attorno a cui gira, in unità del disegno (corpo 150 x 200, y verso
-- il basso, piedi a 200). La gamba ha il perno in (0, 0): la mette il codice sulle anche.
-- La coda è una catena: ogni segmento gira attorno al proprio perno.
return {
	testa = { x = 71.22, y = 35.28, w = 96.00, h = 113.60, px = 69.00, py = 83.00 },
	busto = { x = 59.16, y = 115.88, w = 78.80, h = 78.80, px = 69.00, py = 141.70 },
	gamba = { x = 5.18, y = 26.73, w = 52.80, h = 74.00, px = 0.00, py = 0.00 },
	fiammella = { x = 72.08, y = -19.47, w = 26.00, h = 46.40, px = 72.00, py = -1.00 },
	coda = {
		[1] = { x = 36.77, y = 136.86, w = 30.40, h = 19.20, px = 45.71, py = 134.95 },
		[2] = { x = 18.21, y = 132.98, w = 30.80, h = 27.20, px = 26.86, py = 139.54 },
		[3] = { x = 9.77, y = 120.94, w = 19.60, h = 32.80, px = 11.14, py = 128.54 },
		[4] = { x = 14.33, y = 101.82, w = 26.00, h = 28.80, px = 9.14, py = 109.14 },
		[5] = { x = 5.66, y = 73.36, w = 44.00, h = 54.40, px = 19.36, py = 92.16 },
	},
}
