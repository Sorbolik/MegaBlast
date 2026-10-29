-- Le impugnature delle armi, fatte nell'editor delle animazioni
-- (strumenti/animazioni): per ogni arma dove vanno i pugni, in unità del mondo
-- attorno alla spalla dell'arma, x verso dove si mira e y in su. Con due mani
-- la prima è sulla canna e l'ultima sull'impugnatura; con una sola la tiene il
-- braccio davanti; senza mani (il Pugno è un guanto) il braccio arriva alla
-- spalla dell'arma.
return {
	missile = { { 8.6, -1.6 }, { 2.4, -4 } },
	sniper = { { 12, -1.6 }, { 4.3, -2.6 } },
	grenade = { { 2.8, 0 } },
	shards = { { 10.4, -2.4 }, { 2.9, -3.4 } },
	punch = {},
	sword = { { 2, 0 } },
	teleport = { { 2.8, -0.6 } },
	eagle = { { 1.6, -1.2 } },
	hook = { { 9, -1.8 }, { 5.3, -2.6 } },
	wall = { { 9.5, -3.4 }, { 3.5, -3.4 } },
	mallet = { { 12, 0 }, { 6.5, 0 } },
	lunge = { { 9, 0 }, { 2, 0 } },
}
