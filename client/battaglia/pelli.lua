-- Fatto da strumenti/stampino/taglia.py, non modificare a mano.
-- Le pelli: i pezzi nuovi del diavoletto disegnati sullo stampino. Ogni pezzo
-- va in un posto dello scheletro (come i pezzi di battaglia/diavoletto.lua:
-- immagine, centro rispetto al perno, misura) e sostituisce il pezzo di base
-- o si disegna sopra. Una pelle per categoria; quelle sopra in ordine.
return {
	sostituisce = { "personaggio", "testa", "corpo", "ali", "coda" },
	sopra = { "pantaloni", "maglia", "corazza", "guanti", "elmo" },
	pelli = {
	},
}
