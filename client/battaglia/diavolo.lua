-- Fatto da strumenti/grafica/diavolo.py, non modificare a mano.
-- Il diavoletto in pixel della base: origine fra i piedi, y verso l'alto.
-- Per ogni fotogramma: immagine, centro (x, y) e misura (w, h); dx, dy
-- è quanto si è spostato il busto rispetto alla base (le spalle lo seguono).
return {
	altezza = 880.0,  -- dalla cima della testa ai piedi
	spalla = { -6.1, 462.0 },
	spalla_dietro = { 105.9, 462.0 },
	fiammella = { 47.9, 907.0 },
	braccio = { w = 296.0, h = 87.0, x = 112.2, y = -0.7, presa = 214.2, angolo = -0.0032 },
	animazioni = {
		guardia = { fps = 12, giro = true,
			{ img = "guardia_1", x = -62.1, y = 525.0, w = 602.0, h = 1054.0, dx = 0.0, dy = 0.0 },
		},
	},
}
