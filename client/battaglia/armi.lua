-- Fatto da strumenti/grafica/armi.py, non modificare a mano.
-- Le armi in unità del mondo (i colpi dal centro),
-- x avanti e y in su. Per ogni arma: immagine (tinta: le parti col colore
-- della squadra), centro (x, y) e misura (w, h). Dove le tiene la mano:
-- battaglia/impugnature.lua.
return {
	armi = {
		missile = { img = "missile", tinta = "missile_tinta", x = 2.50, y = -0.75, w = 28.00, h = 14.50 },
		sniper = { img = "sniper", tinta = "sniper_tinta", x = 6.25, y = 0.00, w = 31.50, h = 13.00 },
		grenade = { img = "grenade", tinta = "grenade_tinta", x = 4.50, y = 3.25, w = 10.00, h = 15.50 },
		shards = { img = "shards", tinta = "shards_tinta", x = 5.50, y = 0.00, w = 30.00, h = 15.00 },
		punch = { img = "punch", tinta = "punch_tinta", x = 5.00, y = 0.00, w = 17.00, h = 14.00 },
		sword = { img = "sword", tinta = "sword_tinta", x = 18.75, y = 0.00, w = 47.50, h = 14.00 },
		teleport = { img = "teleport", tinta = "teleport_tinta", x = 5.00, y = 1.25, w = 11.00, h = 11.50 },
		eagle = { img = "eagle", tinta = "eagle_tinta", x = 8.25, y = -1.00, w = 24.50, h = 15.00 },
		hook = { img = "hook", tinta = "hook_tinta", x = 10.00, y = 0.00, w = 30.00, h = 15.00 },
		mallet = { img = "mallet", tinta = "mallet_tinta", x = 20.25, y = -0.25, w = 52.50, h = 17.82 },
		lunge = { img = "lunge", tinta = "lunge_tinta", x = 16.50, y = 0.00, w = 52.00, h = 15.00 },
		bellows = { img = "bellows", tinta = "bellows_tinta", x = 6.25, y = 0.00, w = 28.50, h = 15.00 },
	},
	pezzi = {
		uncino = { img = "uncino", tinta = nil, x = 5.25, y = 0.00, w = 14.50, h = 16.00 },
	},
	colpi = {
		razzo = { img = "razzo", tinta = "razzo_tinta", x = 0.00, y = 0.00, w = 20.80, h = 14.40 },
		palla = { img = "palla", tinta = "palla_tinta", x = 0.00, y = 0.00, w = 12.80, h = 12.80 },
		uovo = { img = "uovo", tinta = "uovo_tinta", x = 0.00, y = 0.00, w = 17.60, h = 24.00 },
		scheggia = { img = "scheggia", tinta = "scheggia_tinta", x = 0.40, y = 0.00, w = 15.20, h = 9.60 },
		globo = { img = "globo", tinta = "globo_tinta", x = 0.00, y = 0.00, w = 16.00, h = 16.00 },
	},
}
