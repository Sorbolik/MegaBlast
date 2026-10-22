-- Generato da strumenti/grafica/personaggio_esporta.py da personaggio_rig.json: non modificare a mano.
-- Unità del rig (alto 128 dai piedi alle corna), y in giù nelle immagini.
return {
	bacino_y = 68.28, -- perno del bacino sopra i piedi, a riposo
	occhio = { pos = { 20.80, 16.40 }, size = { 4.39, 5.81 } }, -- nella testa
	riposo = { spalla_davanti = -8, gomito_davanti = 35, polso_davanti = 10, spalla_dietro = -4, gomito_dietro = 30, polso_dietro = 8, anca_davanti = 45, ginocchio_davanti = -80, caviglia_davanti = 35, anca_dietro = 25, ginocchio_dietro = -70, caviglia_dietro = 45 },
	ordine = { "spalla_dietro", "gomito_dietro", "polso_dietro", "spallaccio_dietro", "anca_dietro", "ginocchio_dietro", "caviglia_dietro", "bacino", "anca_davanti", "ginocchio_davanti", "caviglia_davanti", "busto", "nucleo", "collo", "testa", "spalla_davanti", "gomito_davanti", "polso_davanti", "spallaccio_davanti" },
	pezzi = {
		spalla_dietro = { genitore = "busto", img = "pg_braccio_dietro", perno = { 4.87, 3.14 }, aggancio = { 26.29, 11.77 }, size = { 14.68, 22.84 } },
		gomito_dietro = { genitore = "spalla_dietro", img = "pg_avambraccio_dietro", perno = { 3.77, 2.98 }, aggancio = { 12.24, 20.56 }, size = { 12.09, 25.11 } },
		polso_dietro = { genitore = "gomito_dietro", perno = { 5.81, 1.73 }, aggancio = { 9.34, 22.60 }, mani = {
			aperta = { img = "pg_mano_aperta_dietro", perno = { 5.81, 1.73 }, size = { 13.11, 16.64 } },
			artigli = { img = "pg_mano_artigli_dietro", perno = { 6.20, 1.73 }, size = { 14.99, 16.95 } },
			pugno = { img = "pg_pugno_dietro", perno = { 5.57, 1.88 }, size = { 13.03, 14.36 } },
		} },
		spallaccio_dietro = { genitore = "busto", img = "pg_spallaccio_dietro", perno = { 4.71, 4.71 }, aggancio = { 26.29, 11.77 }, size = { 10.59, 16.40 } },
		anca_dietro = { genitore = "bacino", img = "pg_coscia_b", perno = { 5.10, 3.14 }, aggancio = { 16.09, 10.59 }, size = { 13.18, 33.90 } },
		ginocchio_dietro = { genitore = "anca_dietro", img = "pg_stinco_b", perno = { 4.71, 2.98 }, aggancio = { 9.18, 31.23 }, size = { 16.09, 30.76 } },
		caviglia_dietro = { genitore = "ginocchio_dietro", img = "pg_piede_b", perno = { 7.85, 2.20 }, aggancio = { 12.40, 28.10 }, size = { 23.86, 22.68 }, suola = 20.09 },
		bacino = { img = "pg_bacino", perno = { 10.20, 9.42 }, size = { 22.76, 22.37 } },
		anca_davanti = { genitore = "bacino", img = "pg_coscia_a", perno = { 8.24, 3.14 }, aggancio = { 5.89, 10.59 }, size = { 14.91, 32.80 } },
		ginocchio_davanti = { genitore = "anca_davanti", img = "pg_stinco_a", perno = { 7.85, 2.98 }, aggancio = { 9.26, 30.21 }, size = { 12.16, 31.47 } },
		caviglia_davanti = { genitore = "ginocchio_davanti", img = "pg_piede", perno = { 6.28, 2.20 }, aggancio = { 7.38, 28.88 }, size = { 24.72, 22.45 }, suola = 19.86 },
		busto = { genitore = "bacino", img = "pg_busto", perno = { 20.01, 30.21 }, aggancio = { 10.59, 1.96 }, size = { 31.55, 32.73 } },
		nucleo = { genitore = "busto", img = "pg_nucleo", perno = { 2.35, 4.39 }, aggancio = { 21.11, 15.70 }, size = { 4.71, 8.79 } },
		collo = { genitore = "busto", img = "pg_collo", perno = { 9.81, 11.77 }, aggancio = { 17.66, 9.42 }, size = { 16.87, 16.95 } },
		testa = { genitore = "collo", img = "pg_testa_maschera", perno = { 14.52, 25.90 }, aggancio = { 9.81, 5.89 }, size = { 25.19, 33.35 } },
		spalla_davanti = { genitore = "busto", img = "pg_braccio_davanti", perno = { 4.71, 3.30 }, aggancio = { 6.28, 11.77 }, size = { 14.20, 23.86 } },
		gomito_davanti = { genitore = "spalla_davanti", img = "pg_avambraccio_davanti", perno = { 4.32, 2.98 }, aggancio = { 10.83, 21.19 }, size = { 13.11, 24.64 } },
		polso_davanti = { genitore = "gomito_davanti", perno = { 4.87, 1.73 }, aggancio = { 10.28, 22.13 }, mani = {
			aperta = { img = "pg_mano_aperta_davanti", perno = { 4.87, 1.73 }, size = { 13.11, 18.05 } },
			artigli = { img = "pg_mano_artigli_davanti", perno = { 4.55, 1.73 }, size = { 16.32, 17.03 } },
			pugno = { img = "pg_pugno_davanti", perno = { 5.57, 1.88 }, size = { 12.16, 14.36 } },
		} },
		spallaccio_davanti = { genitore = "busto", img = "pg_spallaccio_davanti", perno = { 5.10, 4.71 }, aggancio = { 6.28, 11.77 }, size = { 9.89, 15.62 } },
	},
}
