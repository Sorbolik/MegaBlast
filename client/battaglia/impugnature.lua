-- Le armi in mano, fatte nell'editor delle animazioni (strumenti/animazioni).
-- Per ogni arma:
--   presa: dove la tiene chi la impugna (la clip sceglie chi: un braccio, che
--          gira verso la presa, o una manina, che ci sta sopra);
--   perno: il punto dell'arma attorno a cui gira (mirando e con "Arma, gira");
--   spalla: dove sta il perno nel corpo, in unità del disegno dai piedi.
-- presa e perno in unità del mondo dall'origine dell'arma, x verso dove punta e
-- y in su.
return {
	missile = { presa = { 1.8, -4.9 }, perno = { -8.4, -0.4 }, spalla = { 31.4, 118.4 } },
	sniper = { presa = { 4.3, -2.9 }, perno = { -7.6, -0.8 }, spalla = { 14.1, 111.5 } },
	grenade = { presa = { 4.8, 2.4 }, perno = { -2.7, -7.9 }, spalla = { -13.8, 111.5 } },
	shards = { presa = { 2.9, -3.4 }, perno = { -9.5, -0.8 }, spalla = { -16.5, 115.3 } },
	punch = { presa = { 0, 0 }, perno = { -9.3, 0 }, spalla = { 32, 110 } },
	sword = { presa = { 2, 0 }, perno = { -10.1, 0.4 }, spalla = { 28.2, 115.8 } },
	teleport = { presa = { 2.8, -0.6 }, perno = { -6.5, -0.6 }, spalla = { 32, 110 } },
	eagle = { presa = { 1.6, -1.2 }, perno = { -7.7, -1.2 }, spalla = { 32, 110 } },
	hook = { presa = { 5.3, -2.6 }, perno = { -4, -2.6 }, spalla = { 32, 110 } },
	mallet = { presa = { 6.5, 0 }, perno = { -2.8, 0 }, spalla = { 32, 110 } },
	lunge = { presa = { 2, 0 }, perno = { -7.3, 0 }, spalla = { 32, 110 } },
	bellows = { presa = { -1.5, 0 }, perno = { -10.8, 0 }, spalla = { 32, 110 } },
}
