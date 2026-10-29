-- Fatto da strumenti/grafica/armi.py, non modificare a mano.
-- Le armi in unità del mondo: origine nella spalla (i colpi nel centro),
-- x avanti e y in su. Per ogni arma: immagine (tinta: le parti col colore
-- della squadra), centro (x, y) e misura (w, h) e dove vanno i pugni
-- (l'ultimo è sull'impugnatura).
return {
	armi = {
		missile = { img = "missile", tinta = "missile_tinta", x = 2.50, y = -0.75, w = 28.00, h = 14.50, mani = { { 8.6, -1.6 }, { 2.4, -4.0 } } },
		sniper = { img = "sniper", tinta = "sniper_tinta", x = 6.25, y = 0.00, w = 31.50, h = 13.00, mani = { { 12.0, -1.6 }, { 4.3, -2.6 } } },
		grenade = { img = "grenade", tinta = "grenade_tinta", x = 4.50, y = 3.25, w = 10.00, h = 15.50, mani = { { 2.8, 0.0 } } },
		shards = { img = "shards", tinta = "shards_tinta", x = 5.50, y = 0.00, w = 30.00, h = 15.00, mani = { { 10.4, -2.4 }, { 2.9, -3.4 } } },
		punch = { img = "punch", tinta = "punch_tinta", x = 5.00, y = 0.00, w = 17.00, h = 14.00, mani = {  } },
		sword = { img = "sword", tinta = "sword_tinta", x = 18.75, y = 0.00, w = 47.50, h = 14.00, mani = { { 2.0, 0.0 } } },
		teleport = { img = "teleport", tinta = "teleport_tinta", x = 5.00, y = 1.25, w = 11.00, h = 11.50, mani = { { 2.8, -0.6 } } },
		eagle = { img = "eagle", tinta = "eagle_tinta", x = 8.25, y = -1.00, w = 24.50, h = 15.00, mani = { { 1.6, -1.2 } } },
		hook = { img = "hook", tinta = "hook_tinta", x = 10.00, y = 0.00, w = 30.00, h = 15.00, mani = { { 9.0, -1.8 }, { 5.3, -2.6 } } },
		wall = { img = "wall", tinta = "wall_tinta", x = 6.50, y = 0.00, w = 15.00, h = 12.00, mani = { { 9.5, -3.4 }, { 3.5, -3.4 } } },
		mallet = { img = "mallet", tinta = "mallet_tinta", x = 20.25, y = -0.25, w = 52.50, h = 17.82, mani = { { 12.0, 0.0 }, { 6.5, 0.0 } } },
		lunge = { img = "lunge", tinta = "lunge_tinta", x = 16.50, y = 0.00, w = 52.00, h = 15.00, mani = { { 9.0, 0.0 }, { 2.0, 0.0 } } },
	},
	colpi = {
		razzo = { img = "razzo", tinta = "razzo_tinta", x = 0.00, y = 0.00, w = 20.80, h = 14.40 },
		palla = { img = "palla", tinta = "palla_tinta", x = 0.00, y = 0.00, w = 12.80, h = 12.80 },
		uovo = { img = "uovo", tinta = "uovo_tinta", x = 0.00, y = 0.00, w = 17.60, h = 24.00 },
		scheggia = { img = "scheggia", tinta = "scheggia_tinta", x = 0.40, y = 0.00, w = 15.20, h = 9.60 },
		globo = { img = "globo", tinta = "globo_tinta", x = 0.00, y = 0.00, w = 16.00, h = 16.00 },
	},
}
