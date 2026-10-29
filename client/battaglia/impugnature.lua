-- Le armi in mano, fatte nell'editor delle animazioni (strumenti/animazioni).
-- Per ogni arma:
--   presa: dove la tiene chi la impugna (la clip sceglie chi: un braccio, che
--          gira verso la presa, o una manina, che ci sta sopra);
--   perno: il punto dell'arma attorno a cui gira (mirando e con "Arma, gira");
--   spalla: dove sta il perno nel corpo, in unità del disegno dai piedi.
-- presa e perno in unità del mondo dall'origine dell'arma, x verso dove punta e
-- y in su.
return {
	missile = { presa = { 2.4, -4 }, perno = { -6.9, -4 }, spalla = { 32, 110 } },
	sniper = { presa = { 4.3, -2.6 }, perno = { -5, -2.6 }, spalla = { 32, 110 } },
	grenade = { presa = { 2.8, 0 }, perno = { -6.5, 0 }, spalla = { 32, 110 } },
	shards = { presa = { 2.9, -3.4 }, perno = { -6.4, -3.4 }, spalla = { 32, 110 } },
	punch = { presa = { 0, 0 }, perno = { -9.3, 0 }, spalla = { 32, 110 } },
	sword = { presa = { 2, 0 }, perno = { -7.3, 0 }, spalla = { 32, 110 } },
	teleport = { presa = { 2.8, -0.6 }, perno = { -6.5, -0.6 }, spalla = { 32, 110 } },
	eagle = { presa = { 1.6, -1.2 }, perno = { -7.7, -1.2 }, spalla = { 32, 110 } },
	hook = { presa = { 5.3, -2.6 }, perno = { -4, -2.6 }, spalla = { 32, 110 } },
	wall = { presa = { 3.5, -3.4 }, perno = { -5.8, -3.4 }, spalla = { 32, 110 } },
	mallet = { presa = { 6.5, 0 }, perno = { -2.8, 0 }, spalla = { 32, 110 } },
	lunge = { presa = { 2, 0 }, perno = { -7.3, 0 }, spalla = { 32, 110 } },
}
