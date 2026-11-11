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
				{ name = "lontano", y0 = 70, h = 650, parallax = 0.1, scroll = 2.2 },
				{ name = "medio", y0 = 343, h = 377, parallax = 0.3, scroll = 8.0 },
				{ name = "vicino", y0 = 518, h = 202, parallax = 0.6, scroll = 18.7 },
			},
		},
		lussuria = {
			haze = { 0.357, 0.290, 0.478 },
			groups = {
				{ name = "lontano", y0 = 0, h = 720, parallax = 0.1, scroll = 2.4 },
				{ name = "medio", y0 = 48, h = 672, parallax = 0.3, scroll = 8.0 },
				{ name = "vicino", y0 = 95, h = 625, parallax = 0.6, scroll = 18.7 },
			},
		},
		gola = {
			haze = { 0.420, 0.431, 0.361 },
			groups = {
				{ name = "lontano", y0 = 0, h = 720, parallax = 0.1, scroll = 2.8 },
				{ name = "medio", y0 = 0, h = 720, parallax = 0.3, scroll = 8.5 },
				{ name = "vicino", y0 = 0, h = 720, parallax = 0.6, scroll = 18.7 },
			},
		},
		avarizia = {
			haze = { 0.416, 0.345, 0.220 },
			groups = {
				{ name = "lontano", y0 = 42, h = 678, parallax = 0.1, scroll = 2.5 },
				{ name = "medio", y0 = 0, h = 720, parallax = 0.3, scroll = 8.5 },
				{ name = "vicino", y0 = 538, h = 182, parallax = 0.6, scroll = 18.7 },
			},
		},
		ira = {
			haze = { 0.184, 0.310, 0.322 },
			groups = {
				{ name = "lontano", y0 = 0, h = 720, parallax = 0.1, scroll = 2.4 },
				{ name = "medio", y0 = 398, h = 322, parallax = 0.3, scroll = 8.0 },
				{ name = "vicino", y0 = 538, h = 182, parallax = 0.6, scroll = 18.7 },
			},
		},
		eresia = {
			haze = { 0.227, 0.227, 0.290 },
			groups = {
				{ name = "lontano", y0 = 0, h = 720, parallax = 0.1, scroll = 2.5 },
				{ name = "medio", y0 = 438, h = 282, parallax = 0.3, scroll = 8.5 },
				{ name = "vicino", y0 = 538, h = 182, parallax = 0.6, scroll = 18.7 },
			},
		},
		violenza = {
			haze = { 0.306, 0.227, 0.298 },
			groups = {
				{ name = "lontano", y0 = 0, h = 720, parallax = 0.1, scroll = 2.5 },
				{ name = "medio", y0 = 228, h = 463, parallax = 0.3, scroll = 8.5 },
				{ name = "vicino", y0 = 538, h = 182, parallax = 0.6, scroll = 18.7 },
			},
		},
		frode = {
			haze = { 0.204, 0.224, 0.169 },
			groups = {
				{ name = "lontano", y0 = 6, h = 714, parallax = 0.1, scroll = 2.7 },
				{ name = "medio", y0 = 0, h = 643, parallax = 0.3, scroll = 9.1 },
				{ name = "vicino", y0 = 538, h = 182, parallax = 0.6, scroll = 18.7 },
			},
		},
		tradimento = {
			haze = { 0.243, 0.365, 0.471 },
			groups = {
				{ name = "lontano", y0 = 0, h = 720, parallax = 0.1, scroll = 2.5 },
				{ name = "medio", y0 = 385, h = 335, parallax = 0.3, scroll = 8.5 },
				{ name = "vicino", y0 = 558, h = 162, parallax = 0.6, scroll = 18.7 },
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
		avarizia = "avarizia",
		ira = "ira",
		eresia = "eresia",
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
