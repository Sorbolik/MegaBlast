# Specialisti del bot del gioco

5 specialisti da 8 bot, livello difficile, modo tutti. Bravura: quanto in alto arriva in classifica, da 0 (ultimo) a 1 (primo), da tutte le partite giocate. Mestiere: quanto fa la sua specialità; la soglia sale finché il campione resta bravo. Esame: in quante partite a coppie il campione arriva più in alto del bot di oggi (50% vuol dire uguale).

## Gli specialisti

| specialista | mestiere | campione / soglia | bravura | esami | armi principali | cosa cambia |
|---|---|---|---|---|---|---|
| spingitore | uccisioni nel vuoto a partita | 1.77 / 1.75 | 0.521 | 53% 53% 54% 56% 54% 54% | missile 24%, punch 19%, mallet 10% | paura di perdere vita ÷3.0, cura del compagno ×3.2, paura di morire ÷1.8, fatica a camminare ÷10.0, voglia di globo 295 (oggi 100), riparo a piedi più che col globo 15 (oggi 3), voglia di buttare nel vuoto ×1.7, voglia di fare danno ×1.6, gusto per le armi da lontano ÷1.7 |
| acrobata | globi e Rampino a partita | 9.83 / 9.07 | 0.516 | 49% 49% 49% 52% 54% 48% | lunge 24%, mallet 21%, missile 18% | paura di perdere vita ×2.3, paura di morire ÷4.2, fatica a camminare ÷2.6, riparo a piedi più che col globo -13 (oggi 3), voglia di fare danno ×1.7, gusto per le armi da lontano ÷1.8 |
| cecchino | quota del danno fatto da lontano | 0.87 / 0.87 | 0.507 | 44% 44% 46% 44% 50% 46% | missile 24%, shards 21%, eagle 17% | paura di perdere vita ×8.3, cura del compagno ÷2.5, paura di morire ×5.7, fatica a camminare ÷7.2, voglia di globo 400 (oggi 100), riparo a piedi più che col globo 17 (oggi 3), voglia di buttare nel vuoto ×3.1, voglia di uccidere ÷2.0, voglia di fare danno ÷1.5, gusto per le armi da vicino ÷2.0, gusto per il Mantice ×3.0 |
| picchiatore | quota del danno fatto da vicino | 0.69 / 0.68 | 0.525 | 53% 55% 54% 54% 54% 54% | lunge 26%, mallet 24%, missile 18% | paura di perdere vita ÷6.9, cura del compagno ÷1.6, fatica a camminare ÷2.2, voglia di globo 327 (oggi 100), riparo a piedi più che col globo -20 (oggi 3), voglia di buttare nel vuoto ×1.6, voglia di fare danno ×2.0, gusto per le armi da vicino ×2.3, gusto per le armi da lontano ÷2.0 |
| sopravvissuto | morti a partita, al contrario | -3.24 / -3.32 | 0.472 | 50% 51% 49% 39% 46% 43% | eagle 29%, missile 23%, shards 17% | paura di perdere vita ×2.0, cura del compagno ×5.0, paura di morire ×1.6, voglia di globo 274 (oggi 100), riparo a piedi più che col globo 11 (oggi 3), voglia di buttare nel vuoto ×2.7, voglia di uccidere ÷1.6, gusto per le armi da vicino ÷1.5, gusto per il Mantice ÷2.0 |

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
| 26 | 0.493 | 0.544 (1.79 / 1.74) | 0.524 (9.02 / 8.73) | 0.509 (0.86 / 0.86) | 0.528 (0.67 / 0.66) | 0.469 (-3.28 / -3.35) |
| 27 | 0.529 | 0.538 (1.77 / 1.75) | 0.519 (8.73 / 8.73) | 0.510 (0.87 / 0.86) | 0.531 (0.68 / 0.67) | 0.513 (-3.41 / -3.35) |
| 28 | 0.431 | 0.529 (1.73 / 1.75) | 0.526 (8.90 / 8.77) | 0.516 (0.87 / 0.87) | 0.524 (0.68 / 0.67) | 0.505 (-3.37 / -3.35) |
| 29 | 0.515 | 0.521 (1.74 / 1.75) | 0.522 (8.93 / 8.81) | 0.511 (0.87 / 0.87) | 0.525 (0.67 / 0.67) | 0.503 (-3.35 / -3.35) |
| 30 | 0.479 | 0.521 (1.77 / 1.75) | 0.516 (9.83 / 9.07) | 0.507 (0.87 / 0.87) | 0.525 (0.69 / 0.68) | 0.472 (-3.24 / -3.32) |
