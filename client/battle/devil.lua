-- Made by strumenti/grafica/diavoletto.py, do not edit by hand.
-- The devil in pieces, in drawing units (height from the feet to the top
-- of the head, y up, facing right). For each piece: image (tint: the part
-- in the team color), center (x, y) relative to its pivot and size (w, h).
-- The points say where the pivots go, from the center of the feet (cima
-- from the neck).
return {
	height = 200,
	px = 1.18,  -- image pixels per unit
	outline = 7.7,  -- outline thickness
	pieces = {
		testa = { img = "testa", tint = nil, x = 4.0, y = 60.0, w = 124, h = 148 },
		testa_colpita = { img = "testa_colpita", tint = nil, x = 4.0, y = 60.0, w = 124, h = 148 },
		testa_felice = { img = "testa_felice", tint = nil, x = 4.0, y = 60.0, w = 124, h = 148 },
		testa_ko = { img = "testa_ko", tint = nil, x = 4.0, y = 60.0, w = 124, h = 148 },
		busto = { img = "busto", tint = nil, x = 0.0, y = 11.0, w = 84, h = 94 },
		gamba = { img = "gamba", tint = nil, x = 4.0, y = -35.0, w = 60, h = 98 },
		gamba_dietro = { img = "gamba_dietro", tint = nil, x = 4.0, y = -35.0, w = 60, h = 98 },
		braccio = { img = "braccio", tint = nil, x = 2.0, y = -24.0, w = 40, h = 72 },
		braccio_dietro = { img = "braccio_dietro", tint = nil, x = 2.0, y = -24.0, w = 40, h = 72 },
		pugno = { img = "pugno", tint = nil, x = 0.0, y = 0.0, w = 32, h = 32 },
		ala = { img = "ala", tint = nil, x = -20.0, y = 4.0, w = 60, h = 56 },
		paracadute = { img = "paracadute", tint = "paracadute_tinta", x = 0.0, y = 2.0, w = 200, h = 324 },
		coda_1 = { img = "coda_1", tint = nil, x = 23.0, y = 0.0, w = 70, h = 56 },
		coda_1_bordo = { img = "coda_1_bordo", tint = nil, x = 23.0, y = 0.0, w = 70, h = 56 },
		coda_2 = { img = "coda_2", tint = nil, x = 23.0, y = 0.0, w = 70, h = 56 },
		coda_2_bordo = { img = "coda_2_bordo", tint = nil, x = 23.0, y = 0.0, w = 70, h = 56 },
		coda_3 = { img = "coda_3", tint = nil, x = 23.0, y = 0.0, w = 70, h = 56 },
		coda_3_bordo = { img = "coda_3_bordo", tint = nil, x = 23.0, y = 0.0, w = 70, h = 56 },
		coda_4 = { img = "coda_4", tint = nil, x = 23.0, y = 0.0, w = 70, h = 56 },
		coda_4_bordo = { img = "coda_4_bordo", tint = nil, x = 23.0, y = 0.0, w = 70, h = 56 },
		coda_5 = { img = "coda_5", tint = nil, x = 22.0, y = 0.0, w = 68, h = 56 },
		coda_5_bordo = { img = "coda_5_bordo", tint = nil, x = 22.0, y = 0.0, w = 68, h = 56 },
	},
	points = {
		collo = { 0, 122 },
		bacino = { 0, 76 },
		anche = { 12, 76 },
		spalle = { 32, 110 },
		ala = { -16, 116 },
		coda = { -10, 70 },
		cima = { 0, 82 },
	},
	tail = { 26, 26, 26, 26, 24 },  -- segment lengths
	tail_rest = { 3.491, 2.793, 2.094, 1.571, 1.134 },  -- rest angles
	chute_y = 262,  -- the parachute pivot, from the feet
}
