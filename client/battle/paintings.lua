-- Made by strumenti/grafica/mappe_dipinte.py, do not edit by hand.
-- The painted images (client/dipinti, one per screen density) and the background
-- numbers: for each group of planes where it sits in the 1280 x 720 scene (y0 from
-- the top, h), how much it follows the camera (parallax) and how many scene pixels
-- it scrolls per second.
return {
	densities = { 1, 2 },
	wrap = 2560,
	backgrounds = {
		forgia = {
			haze = { 0.239, 0.227, 0.290 },
			groups = {
				{ name = "lontano", y0 = 68, h = 652, parallax = 0.1, scroll = 2.4 },
				{ name = "medio", y0 = 267, h = 453, parallax = 0.3, scroll = 8.7 },
				{ name = "vicino", y0 = 0, h = 720, parallax = 0.6, scroll = 16.7 },
			},
		},
	},
	-- the maps with painted terrain and their background
	maps = {
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
