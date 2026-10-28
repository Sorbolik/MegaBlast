-- Il corpo del diavoletto nella simulazione (profilo di fisica "blastron"), in
-- pixel del mondo misurati dal centro dei piedi. Lo scrive l'editor delle
-- animazioni (strumenti/animazioni), ma è fisica: cambiarlo cambia il gioco per
-- tutti, server compreso, non il disegno (che è alto game.DISEGNO_H).
return {
	-- la capsula per camminare: terreno, spinte fra robot, casse, chi sta sopra a chi
	cammina = { largo = 29.4, alto = 39.2 },
	-- il cerchio dei colpi: proiettili, esplosioni, spada, pugno, affondo, globi
	colpi = { raggio = 20.49, centro = 19.6 },
}
