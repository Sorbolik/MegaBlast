-- Le armi in mano, fatte nell'editor delle animazioni (strumenti/animazioni).
-- Per ogni arma:
--   presa: dove la tiene chi la impugna (la clip sceglie chi: un braccio, che
--          gira verso la presa, o una manina, che ci sta sopra);
--   perno: il punto dell'arma attorno a cui gira (mirando e con "Arma, gira");
--   spalla: dove sta il perno nel corpo, in unità del disegno dai piedi.
-- presa e perno in unità del mondo dall'origine dell'arma, x verso dove punta e
-- y in su.
return {
	missile = { presa = { 1.6, -5.6 }, perno = { -8.9, -0.5 }, spalla = { 14.6, 137.3 } },
	sniper = { presa = { 4.2, -3.3 }, perno = { -6, -1.4 }, spalla = { 34.3, 138.8 } },
	grenade = { presa = { 3.9, 0.9 }, perno = { -6, 1.5 }, spalla = { 44.7, 131.5 } },
	shards = { presa = { 2.2, -2.6 }, perno = { -5.1, -1.1 }, spalla = { 39.2, 122.9 } },
	punch = { presa = { 0, 0 }, perno = { -9.3, 0 }, spalla = { 32, 110 } },
	sword = { presa = { 2.3, -0.8 }, perno = { -5.8, 1 }, spalla = { 29.3, 106.9 } },
	teleport = { presa = { 2.8, -0.6 }, perno = { -6.5, -0.6 }, spalla = { 32, 110 } },
	eagle = { presa = { 1.6, -1.2 }, perno = { -7.7, -1.2 }, spalla = { 32, 110 } },
	hook = { presa = { 5.3, -2.6 }, perno = { -4, -2.6 }, spalla = { 32, 110 } },
	wall = { presa = { 3.5, -3.4 }, perno = { -5.8, -3.4 }, spalla = { 32, 110 } },
	mallet = { presa = { 6.5, 0 }, perno = { -2.8, 0 }, spalla = { 32, 110 } },
	lunge = { presa = { 2, 0 }, perno = { -7.3, 0 }, spalla = { 32, 110 } },
}
