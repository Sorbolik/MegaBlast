# Specialisti del bot del gioco

5 specialisti da 8 bot, livello difficile, modo tutti. Bravura: quanto in alto arriva in classifica, da 0 (ultimo) a 1 (primo), da tutte le partite giocate. Mestiere: quanto fa la sua specialità; la soglia sale finché il campione resta bravo. Esame: in quante partite a coppie il campione arriva più in alto del bot di oggi (50% vuol dire uguale).

## Gli specialisti

| specialista | mestiere | campione / soglia | bravura | esami | armi principali | cosa cambia |
|---|---|---|---|---|---|---|
| spingitore | uccisioni nel vuoto a partita | 1.82 / 1.72 | 0.542 | 53% 53% 54% 56% 54% | missile 26%, punch 18%, mallet 9% | paura di morire ÷4.4, fatica a camminare ÷10.0, voglia di globo 310 (oggi 100), voglia di uccidere ÷1.7, gusto per il Mantice ×1.6 |
| acrobata | globi e Rampino a partita | 9.09 / 8.64 | 0.531 | 49% 49% 49% 52% 54% | mallet 24%, lunge 24%, missile 18% | paura di morire ÷4.0, fatica a camminare ÷3.3, voglia di globo 169 (oggi 100), riparo a piedi più che col globo -13 (oggi 3), voglia di uccidere ×1.7, voglia di fare danno ×1.7, gusto per le armi da vicino ×1.6, gusto per le armi da lontano ÷1.7 |
| cecchino | quota del danno fatto da lontano | 0.86 / 0.86 | 0.509 | 44% 44% 46% 44% 50% | missile 26%, shards 23%, eagle 16% | paura di perdere vita ÷7.5, paura di morire ×5.8, voglia di globo 322 (oggi 100), voglia di uccidere ÷2.0, gusto per le armi da vicino ÷1.7, gusto per le armi da lontano ×1.9, gusto per il Mantice ×3.0 |
| picchiatore | quota del danno fatto da vicino | 0.68 / 0.66 | 0.531 | 53% 55% 54% 54% 54% | lunge 25%, mallet 23%, missile 18% | paura di perdere vita ÷5.1, cura del compagno ×2.8, fatica a camminare ÷4.0, voglia di buttare nel vuoto ×1.9, voglia di uccidere ×1.6, gusto per le armi da vicino ×1.5, gusto per le armi da lontano ÷2.0 |
| sopravvissuto | morti a partita, al contrario | -3.33 / -3.35 | 0.486 | 50% 51% 49% 39% 46% | eagle 31%, missile 23%, shards 13% | paura di perdere vita ×2.5, cura del compagno ÷3.3, paura di morire ×5.5, fatica a camminare ÷7.2, riparo a piedi più che col globo -13 (oggi 3), voglia di buttare nel vuoto ÷1.6, voglia di fare danno ×1.9, gusto per il Mantice ÷1.7 |

## Scelte prese da sola quando non migliorava

- generazione 20: sopravvissuto: muta di più (forza 0.16), perché 3 esami di fila sotto il suo migliore (51%)
- generazione 25: picchiatore: muta di più (forza 0.16), perché 3 esami di fila sotto il suo migliore (55%)

## Generazioni

Per ogni specialista: bravura del campione e mestiere / soglia.

| gen | bot di oggi | spingitore | acrobata | cecchino | picchiatore | sopravvissuto |
|---|---|---|---|---|---|---|
| 1 | 0.546 | 0.531 (1.72 / 0.83) | 0.533 (8.30 / 7.13) | 0.524 (0.87 / 0.65) | 0.524 (0.42 / 0.30) | 0.524 (-3.46 / -3.45) |
| 2 | 0.465 | 0.533 (1.68 / 1.04) | 0.531 (8.13 / 7.38) | 0.505 (0.87 / 0.71) | 0.520 (0.44 / 0.33) | 0.522 (-3.44 / -3.45) |
| 3 | 0.580 | 0.536 (1.70 / 1.04) | 0.527 (8.06 / 7.38) | 0.503 (0.87 / 0.71) | 0.520 (0.49 / 0.33) | 0.523 (-3.42 / -3.45) |
| 4 | 0.509 | 0.531 (1.68 / 1.20) | 0.527 (7.89 / 7.51) | 0.503 (0.88 / 0.75) | 0.518 (0.50 / 0.37) | 0.522 (-3.46 / -3.45) |
| 5 | 0.514 | 0.522 (1.66 / 1.31) | 0.530 (7.86 / 7.60) | 0.500 (0.89 / 0.79) | 0.515 (0.50 / 0.40) | 0.522 (-3.46 / -3.45) |
| 6 | 0.479 | 0.536 (1.52 / 1.37) | 0.526 (7.82 / 7.65) | 0.512 (0.85 / 0.80) | 0.527 (0.67 / 0.47) | 0.519 (-3.42 / -3.44) |
| 7 | 0.495 | 0.521 (1.65 / 1.44) | 0.527 (7.82 / 7.70) | 0.519 (0.87 / 0.82) | 0.534 (0.52 / 0.48) | 0.525 (-3.41 / -3.43) |
| 8 | 0.522 | 0.521 (1.64 / 1.49) | 0.526 (7.81 / 7.72) | 0.517 (0.86 / 0.83) | 0.529 (0.50 / 0.49) | 0.522 (-3.48 / -3.43) |
| 9 | 0.461 | 0.523 (1.62 / 1.52) | 0.525 (7.79 / 7.74) | 0.514 (0.86 / 0.84) | 0.532 (0.65 / 0.53) | 0.514 (-3.41 / -3.43) |
| 10 | 0.505 | 0.524 (1.61 / 1.54) | 0.522 (7.78 / 7.75) | 0.519 (0.86 / 0.84) | 0.528 (0.66 / 0.56) | 0.513 (-3.33 / -3.40) |
| 11 | 0.496 | 0.521 (1.62 / 1.56) | 0.519 (7.78 / 7.76) | 0.515 (0.86 / 0.84) | 0.520 (0.65 / 0.58) | 0.517 (-3.40 / -3.40) |
| 12 | 0.551 | 0.522 (1.62 / 1.56) | 0.518 (7.76 / 7.76) | 0.525 (0.85 / 0.84) | 0.530 (0.67 / 0.58) | 0.507 (-3.42 / -3.40) |
| 13 | 0.484 | 0.528 (1.61 / 1.57) | 0.517 (7.74 / 7.76) | 0.519 (0.87 / 0.85) | 0.521 (0.67 / 0.61) | 0.511 (-3.40 / -3.40) |
| 14 | 0.508 | 0.525 (1.60 / 1.58) | 0.516 (7.75 / 7.76) | 0.515 (0.87 / 0.86) | 0.517 (0.66 / 0.62) | 0.503 (-3.40 / -3.40) |
| 15 | 0.497 | 0.524 (1.58 / 1.58) | 0.512 (7.74 / 7.76) | 0.507 (0.86 / 0.86) | 0.536 (0.69 / 0.64) | 0.499 (-3.35 / -3.39) |
| 16 | 0.522 | 0.533 (1.61 / 1.59) | 0.517 (7.98 / 7.81) | 0.506 (0.86 / 0.86) | 0.535 (0.66 / 0.64) | 0.522 (-3.37 / -3.39) |
| 17 | 0.536 | 0.539 (1.66 / 1.61) | 0.512 (8.15 / 7.81) | 0.513 (0.87 / 0.86) | 0.542 (0.65 / 0.64) | 0.504 (-3.45 / -3.39) |
| 18 | 0.453 | 0.547 (1.69 / 1.63) | 0.517 (8.08 / 7.88) | 0.520 (0.87 / 0.86) | 0.538 (0.66 / 0.65) | 0.501 (-3.41 / -3.39) |
| 19 | 0.545 | 0.540 (1.63 / 1.63) | 0.512 (8.67 / 7.88) | 0.529 (0.86 / 0.86) | 0.543 (0.67 / 0.65) | 0.505 (-3.38 / -3.39) |
| 20 | 0.500 | 0.513 (1.63 / 1.63) | 0.527 (8.65 / 8.07) | 0.526 (0.86 / 0.86) | 0.538 (0.66 / 0.65) | 0.497 (-3.26 / -3.35) |
| 21 | 0.553 | 0.537 (1.60 / 1.63) | 0.529 (8.67 / 8.07) | 0.524 (0.87 / 0.86) | 0.538 (0.66 / 0.66) | 0.492 (-3.36 / -3.35) |
| 22 | 0.494 | 0.521 (1.70 / 1.65) | 0.529 (8.67 / 8.22) | 0.521 (0.87 / 0.86) | 0.535 (0.66 / 0.66) | 0.504 (-3.38 / -3.35) |
| 23 | 0.497 | 0.516 (1.63 / 1.65) | 0.527 (8.57 / 8.31) | 0.519 (0.87 / 0.86) | 0.536 (0.66 / 0.66) | 0.499 (-3.39 / -3.35) |
| 24 | 0.540 | 0.529 (1.82 / 1.69) | 0.532 (9.02 / 8.49) | 0.518 (0.86 / 0.86) | 0.535 (0.66 / 0.66) | 0.492 (-3.42 / -3.35) |
| 25 | 0.478 | 0.542 (1.82 / 1.72) | 0.531 (9.09 / 8.64) | 0.509 (0.86 / 0.86) | 0.531 (0.68 / 0.66) | 0.486 (-3.33 / -3.35) |
