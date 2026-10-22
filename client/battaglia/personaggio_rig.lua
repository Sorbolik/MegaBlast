-- Generato da strumenti/grafica/personaggio_esporta.py da personaggio_rig.json: non modificare a mano.
-- Unità del rig (alto 128 dai piedi alle corna), y in giù nelle immagini.
return {
	bacino_y = 70.19, -- perno del bacino sopra i piedi, a riposo
	occhio = { pos = { 20.13, 15.91 }, size = { 4.25, 5.55 } }, -- nella testa
	riposo = { spalla_davanti = -8, gomito_davanti = 35, polso_davanti = 10, spalla_dietro = -4, gomito_dietro = 30, polso_dietro = 8, anca_davanti = -7, ginocchio_davanti = -16, caviglia_davanti = 23, anca_dietro = 17, ginocchio_dietro = -20, caviglia_dietro = 3 },
	ordine = { "spalla_dietro", "gomito_dietro", "polso_dietro", "spallaccio_dietro", "anca_dietro", "ginocchio_dietro", "caviglia_dietro", "bacino", "anca_davanti", "ginocchio_davanti", "caviglia_davanti", "busto", "nucleo", "collo", "testa", "spalla_davanti", "gomito_davanti", "polso_davanti", "spallaccio_davanti" },
	pezzi = {
		spalla_dietro = { genitore = "busto", img = "pg_braccio_dietro", perno = { 4.71, 3.04 }, aggancio = { 25.45, 11.39 }, size = { 14.21, 22.11 } },
		gomito_dietro = { genitore = "spalla_dietro", img = "pg_avambraccio_dietro", perno = { 3.65, 2.89 }, aggancio = { 11.85, 19.90 }, size = { 11.70, 24.31 } },
		polso_dietro = { genitore = "gomito_dietro", perno = { 5.62, 1.67 }, aggancio = { 9.04, 21.88 }, mani = {
			aperta = { img = "pg_mano_aperta_dietro", perno = { 5.62, 1.67 }, size = { 12.69, 16.10 } },
			artigli = { img = "pg_mano_artigli_dietro", perno = { 6.00, 1.67 }, size = { 14.51, 16.41 } },
			pugno = { img = "pg_pugno_dietro", perno = { 5.39, 1.82 }, size = { 12.61, 13.90 } },
		} },
		spallaccio_dietro = { genitore = "busto", img = "pg_spallaccio_dietro", perno = { 4.56, 4.56 }, aggancio = { 25.45, 11.39 }, size = { 10.26, 15.88 } },
		anca_dietro = { genitore = "bacino", img = "pg_coscia_b", perno = { 4.94, 3.04 }, aggancio = { 15.57, 10.26 }, size = { 12.76, 32.82 } },
		ginocchio_dietro = { genitore = "anca_dietro", img = "pg_stinco_b", perno = { 4.56, 2.89 }, aggancio = { 8.89, 30.23 }, size = { 15.57, 29.78 } },
		caviglia_dietro = { genitore = "ginocchio_dietro", img = "pg_piede_b", perno = { 7.60, 2.13 }, aggancio = { 12.00, 27.20 }, size = { 23.09, 21.95 }, suola = 19.45 },
		bacino = { img = "pg_bacino", perno = { 9.88, 9.12 }, size = { 22.03, 21.65 } },
		anca_davanti = { genitore = "bacino", img = "pg_coscia_a", perno = { 7.98, 3.04 }, aggancio = { 5.70, 10.26 }, size = { 14.43, 31.75 } },
		ginocchio_davanti = { genitore = "anca_davanti", img = "pg_stinco_a", perno = { 7.60, 2.89 }, aggancio = { 8.96, 29.25 }, size = { 11.77, 30.46 } },
		caviglia_davanti = { genitore = "ginocchio_davanti", img = "pg_piede", perno = { 6.08, 2.13 }, aggancio = { 7.14, 27.95 }, size = { 23.93, 21.73 }, suola = 19.22 },
		busto = { genitore = "bacino", img = "pg_busto", perno = { 19.37, 29.25 }, aggancio = { 10.26, 1.90 }, size = { 30.54, 31.68 } },
		nucleo = { genitore = "busto", img = "pg_nucleo", perno = { 2.28, 4.25 }, aggancio = { 20.43, 15.19 }, size = { 4.56, 8.51 } },
		collo = { genitore = "busto", img = "pg_collo", perno = { 9.50, 11.39 }, aggancio = { 17.09, 9.12 }, size = { 16.33, 16.41 } },
		testa = { genitore = "collo", img = "pg_testa_maschera", perno = { 14.05, 25.07 }, aggancio = { 9.50, 5.70 }, size = { 24.38, 32.28 } },
		spalla_davanti = { genitore = "busto", img = "pg_braccio_davanti", perno = { 4.56, 3.19 }, aggancio = { 6.08, 11.39 }, size = { 13.75, 23.09 } },
		gomito_davanti = { genitore = "spalla_davanti", img = "pg_avambraccio_davanti", perno = { 4.18, 2.89 }, aggancio = { 10.48, 20.51 }, size = { 12.69, 23.85 } },
		polso_davanti = { genitore = "gomito_davanti", perno = { 4.71, 1.67 }, aggancio = { 9.95, 21.42 }, mani = {
			aperta = { img = "pg_mano_aperta_davanti", perno = { 4.71, 1.67 }, size = { 12.69, 17.47 } },
			artigli = { img = "pg_mano_artigli_davanti", perno = { 4.41, 1.67 }, size = { 15.80, 16.48 } },
			pugno = { img = "pg_pugno_davanti", perno = { 5.39, 1.82 }, size = { 11.77, 13.90 } },
		} },
		spallaccio_davanti = { genitore = "busto", img = "pg_spallaccio_davanti", perno = { 4.94, 4.56 }, aggancio = { 6.08, 11.39 }, size = { 9.57, 15.12 } },
	},
}
