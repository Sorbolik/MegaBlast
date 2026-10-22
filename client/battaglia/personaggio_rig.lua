-- Generato da strumenti/grafica/personaggio_esporta.py da personaggio_rig.json: non modificare a mano.
-- Unità del rig (alto 128 dai piedi alle corna), y in giù nelle immagini.
return {
	bacino_y = 69.92, -- perno del bacino sopra i piedi, a riposo
	occhio = { pos = { 20.23, 15.99 }, size = { 4.27, 5.57 } }, -- nella testa
	riposo = { spalla_davanti = -8, gomito_davanti = 35, polso_davanti = 10, spalla_dietro = -4, gomito_dietro = 30, polso_dietro = 8, anca_davanti = 24, ginocchio_davanti = -20, caviglia_davanti = -4, anca_dietro = -28, ginocchio_dietro = -14, caviglia_dietro = 42 },
	ordine = { "spalla_dietro", "gomito_dietro", "polso_dietro", "spallaccio_dietro", "anca_dietro", "ginocchio_dietro", "caviglia_dietro", "bacino", "anca_davanti", "ginocchio_davanti", "caviglia_davanti", "busto", "nucleo", "collo", "testa", "spalla_davanti", "gomito_davanti", "polso_davanti", "spallaccio_davanti" },
	pezzi = {
		spalla_dietro = { genitore = "busto", img = "pg_braccio_dietro", perno = { 4.73, 3.05 }, aggancio = { 25.57, 11.45 }, size = { 14.27, 22.21 } },
		gomito_dietro = { genitore = "spalla_dietro", img = "pg_avambraccio_dietro", perno = { 3.66, 2.90 }, aggancio = { 11.91, 20.00 }, size = { 11.75, 24.42 } },
		polso_dietro = { genitore = "gomito_dietro", perno = { 5.65, 1.68 }, aggancio = { 9.08, 21.98 }, mani = {
			aperta = { img = "pg_mano_aperta_dietro", perno = { 5.65, 1.68 }, size = { 12.75, 16.18 } },
			artigli = { img = "pg_mano_artigli_dietro", perno = { 6.03, 1.68 }, size = { 14.58, 16.49 } },
			pugno = { img = "pg_pugno_dietro", perno = { 5.42, 1.83 }, size = { 12.67, 13.97 } },
		} },
		spallaccio_dietro = { genitore = "busto", img = "pg_spallaccio_dietro", perno = { 4.58, 4.58 }, aggancio = { 25.57, 11.45 }, size = { 10.30, 15.95 } },
		anca_dietro = { genitore = "bacino", img = "pg_coscia_b", perno = { 4.96, 3.05 }, aggancio = { 15.65, 10.30 }, size = { 12.82, 32.97 } },
		ginocchio_dietro = { genitore = "anca_dietro", img = "pg_stinco_b", perno = { 4.58, 2.90 }, aggancio = { 8.93, 30.38 }, size = { 15.65, 29.92 } },
		caviglia_dietro = { genitore = "ginocchio_dietro", img = "pg_piede_b", perno = { 7.63, 2.14 }, aggancio = { 12.06, 27.32 }, size = { 23.20, 22.06 }, suola = 19.54 },
		bacino = { img = "pg_bacino", perno = { 9.92, 9.16 }, size = { 22.13, 21.75 } },
		anca_davanti = { genitore = "bacino", img = "pg_coscia_a", perno = { 8.01, 3.05 }, aggancio = { 5.72, 10.30 }, size = { 14.50, 31.90 } },
		ginocchio_davanti = { genitore = "anca_davanti", img = "pg_stinco_a", perno = { 7.63, 2.90 }, aggancio = { 9.01, 29.39 }, size = { 11.83, 30.61 } },
		caviglia_davanti = { genitore = "ginocchio_davanti", img = "pg_piede", perno = { 6.11, 2.14 }, aggancio = { 7.17, 28.09 }, size = { 24.04, 21.83 }, suola = 19.31 },
		busto = { genitore = "bacino", img = "pg_busto", perno = { 19.46, 29.39 }, aggancio = { 10.30, 1.91 }, size = { 30.68, 31.83 } },
		nucleo = { genitore = "busto", img = "pg_nucleo", perno = { 2.29, 4.27 }, aggancio = { 20.53, 15.27 }, size = { 4.58, 8.55 } },
		collo = { genitore = "busto", img = "pg_collo", perno = { 9.54, 11.45 }, aggancio = { 17.17, 9.16 }, size = { 16.41, 16.49 } },
		testa = { genitore = "collo", img = "pg_testa_maschera", perno = { 14.12, 25.19 }, aggancio = { 9.54, 5.72 }, size = { 24.50, 32.44 } },
		spalla_davanti = { genitore = "busto", img = "pg_braccio_davanti", perno = { 4.58, 3.21 }, aggancio = { 6.11, 11.45 }, size = { 13.82, 23.20 } },
		gomito_davanti = { genitore = "spalla_davanti", img = "pg_avambraccio_davanti", perno = { 4.20, 2.90 }, aggancio = { 10.53, 20.61 }, size = { 12.75, 23.97 } },
		polso_davanti = { genitore = "gomito_davanti", perno = { 4.73, 1.68 }, aggancio = { 10.00, 21.52 }, mani = {
			aperta = { img = "pg_mano_aperta_davanti", perno = { 4.73, 1.68 }, size = { 12.75, 17.56 } },
			artigli = { img = "pg_mano_artigli_davanti", perno = { 4.43, 1.68 }, size = { 15.88, 16.56 } },
			pugno = { img = "pg_pugno_davanti", perno = { 5.42, 1.83 }, size = { 11.83, 13.97 } },
		} },
		spallaccio_davanti = { genitore = "busto", img = "pg_spallaccio_davanti", perno = { 4.96, 4.58 }, aggancio = { 6.11, 11.45 }, size = { 9.62, 15.19 } },
	},
}
