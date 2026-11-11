-- Made by tools/grafica/mappe_dipinte.py, do not edit by hand.
-- The painted images (client/paintings, one per screen density) and the background
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
		cortile = {
			haze = { 0.239, 0.227, 0.290 },
			groups = {
				{ name = "lontano", y0 = 42, h = 678, parallax = 0.1, scroll = 0.0 },
				{ name = "medio", y0 = 54, h = 666, parallax = 0.3, scroll = 0.0 },
				{ name = "vicino", y0 = 558, h = 162, parallax = 0.6, scroll = 0.0 },
			},
		},
		limbo = {
			haze = { 0.655, 0.706, 0.675 },
			groups = {
				{ name = "lontano", y0 = 70, h = 650, parallax = 0.1, scroll = 2.1 },
				{ name = "medio", y0 = 388, h = 332, parallax = 0.3, scroll = 8.7 },
				{ name = "vicino", y0 = 489, h = 231, parallax = 0.6, scroll = 20.0 },
			},
		},
		lussuria = {
			haze = { 0.357, 0.290, 0.478 },
			groups = {
				{ name = "lontano", y0 = 22, h = 698, parallax = 0.1, scroll = 2.3 },
				{ name = "medio", y0 = 318, h = 402, parallax = 0.3, scroll = 7.5 },
				{ name = "vicino", y0 = 76, h = 644, parallax = 0.6, scroll = 16.4 },
			},
		},
		gola = {
			haze = { 0.420, 0.431, 0.361 },
			groups = {
				{ name = "lontano", y0 = 6, h = 714, parallax = 0.1, scroll = 2.2 },
				{ name = "medio", y0 = 0, h = 720, parallax = 0.3, scroll = 8.0 },
				{ name = "vicino", y0 = 529, h = 191, parallax = 0.6, scroll = 16.0 },
			},
		},
		violenza = {
			haze = { 0.306, 0.227, 0.298 },
			groups = {
				{ name = "lontano", y0 = 0, h = 720, parallax = 0.1, scroll = 2.5 },
				{ name = "medio", y0 = 308, h = 412, parallax = 0.3, scroll = 8.7 },
				{ name = "vicino", y0 = 0, h = 720, parallax = 0.6, scroll = 17.3 },
			},
		},
		frode = {
			haze = { 0.204, 0.224, 0.169 },
			groups = {
				{ name = "lontano", y0 = 10, h = 710, parallax = 0.1, scroll = 1.5 },
				{ name = "medio", y0 = 0, h = 720, parallax = 0.3, scroll = 7.3 },
				{ name = "vicino", y0 = 0, h = 720, parallax = 0.6, scroll = 17.3 },
			},
		},
		tradimento = {
			haze = { 0.243, 0.365, 0.471 },
			groups = {
				{ name = "lontano", y0 = 8, h = 712, parallax = 0.1, scroll = 2.1 },
				{ name = "medio", y0 = 388, h = 332, parallax = 0.3, scroll = 8.7 },
				{ name = "vicino", y0 = 0, h = 720, parallax = 0.6, scroll = 17.3 },
			},
		},
	},
	-- the maps with painted terrain and their background
	maps = {
		pavimento = "forgia",
		fossa = "forgia",
		limbo = "limbo",
		lussuria = "lussuria",
		gola = "gola",
		flegetonte = "violenza",
		sabbione = "violenza",
		malebolge = "frode",
		cocito = "tradimento",
		lucifero = "tradimento",
		cortile = "cortile",
		missione_primi_passi = "cortile",
		missione_lanciarune = "cortile",
		missione_turno = "cortile",
		missione_tempo = "cortile",
		missione_prima_sfida = "cortile",
		missione_attrezzi = "cortile",
		missione_spostano = "cortile",
		missione_sfida_burrone = "cortile",
		missione_fuori_portata = "forgia",
		missione_due_mani = "forgia",
		missione_giu_dal_bordo = "forgia",
	},
}
