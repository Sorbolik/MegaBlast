# Specialisti del bot del gioco

5 specialisti da 8 bot, livello difficile, modo tutti. Bravura: quanto in alto arriva in classifica, da 0 (ultimo) a 1 (primo), da tutte le partite giocate. Mestiere: quanto fa la sua specialità; la soglia sale finché il campione resta bravo. Esame: in quante partite a coppie il campione arriva più in alto del bot di oggi (50% vuol dire uguale).

## Gli specialisti

| specialista | mestiere | campione / soglia | bravura | esami | armi principali | cosa cambia |
|---|---|---|---|---|---|---|
| spingitore | uccisioni nel vuoto a partita | 1.46 / 1.44 | 0.530 | 52% 53% 53% 53% 53% 54% 57% | punch 22%, missile 19%, sword 15% | paura di perdere vita ÷4.4, cura del compagno ×2.1, paura di morire ×3.3, fatica a camminare ×5.0, voglia di globo 314 (oggi 100), riparo a piedi più che col globo 13 (oggi 3), voglia di buttare nel vuoto ×2.1, gusto per le armi da lontano ÷1.7, voglia di casse 51 (oggi 12), voglia di casse quando restano pochi colpi 15 (oggi 8) |
| acrobata | globi e Rampino a partita | 9.60 / 9.56 | 0.526 | 46% 52% 50% 51% 50% 50% 48% | missile 22%, punch 20%, sword 15% | paura di perdere vita ×4.0, cura del compagno ×2.5, voglia di globo 171 (oggi 100), riparo a piedi più che col globo -4 (oggi 3), voglia di buttare nel vuoto ×3.2, voglia di uccidere ×1.8, gusto per le armi da vicino ×2.0, gusto per il Mantice ×2.5, voglia di casse 55 (oggi 12), voglia di casse quando restano pochi colpi 0 (oggi 8) |
| cecchino | quota del danno fatto da lontano | 0.76 / 0.76 | 0.508 | 47% 52% 49% 49% 51% 51% 51% | shards 23%, missile 19%, sniper 14% | paura di morire ÷7.1, fatica a camminare ÷2.4, voglia di globo 357 (oggi 100), riparo a piedi più che col globo 10 (oggi 3), voglia di casse quando restano pochi colpi 20 (oggi 8) |
| picchiatore | quota del danno fatto da vicino | 0.66 / 0.66 | 0.520 | 55% 50% 50% 50% 57% 56% 56% | punch 21%, mallet 17%, lunge 17% | cura del compagno ×5.0, fatica a camminare ×8.0, voglia di globo 244 (oggi 100), voglia di buttare nel vuoto ×2.2, voglia di uccidere ÷2.0, gusto per le armi da vicino ×1.9, voglia di casse 43 (oggi 12) |
| sopravvissuto | morti a partita, al contrario | -3.62 / -3.62 | 0.511 | 52% 52% 52% 53% 56% 52% 51% | punch 20%, missile 18%, lunge 16% | paura di perdere vita ×1.8, cura del compagno ×5.0, fatica a camminare ÷3.0, voglia di globo 360 (oggi 100), riparo a piedi più che col globo 29 (oggi 3), voglia di fare danno ×2.0, voglia di casse 21 (oggi 12), voglia di casse quando restano pochi colpi 19 (oggi 8) |

## Scelte prese da sola quando non migliorava

- generazione 20: spingitore: muta di più (forza 0.16), perché 3 esami di fila sotto il suo migliore (53%)
- generazione 20: picchiatore: muta di più (forza 0.16), perché 3 esami di fila sotto il suo migliore (55%)
- generazione 20: sopravvissuto: muta di più (forza 0.16), perché 3 esami di fila sotto il suo migliore (53%)
- generazione 25: acrobata: muta di più (forza 0.16), perché 3 esami di fila sotto il suo migliore (52%)
- generazione 25: cecchino: muta di più (forza 0.16), perché 3 esami di fila sotto il suo migliore (52%)

## Generazioni

Per ogni specialista: bravura del campione e mestiere / soglia.

| gen | bot di oggi | spingitore | acrobata | cecchino | picchiatore | sopravvissuto |
|---|---|---|---|---|---|---|
| 1 | 0.495 | 0.524 (1.31 / 0.71) | 0.520 (8.11 / 7.95) | 0.512 (0.77 / 0.65) | 0.510 (0.57 / 0.37) | 0.523 (-3.70 / -3.73) |
| 2 | 0.541 | 0.534 (1.28 / 0.85) | 0.529 (7.98 / 7.96) | 0.522 (0.78 / 0.69) | 0.515 (0.55 / 0.37) | 0.528 (-3.65 / -3.71) |
| 3 | 0.481 | 0.553 (1.36 / 0.98) | 0.525 (7.99 / 7.97) | 0.517 (0.76 / 0.70) | 0.516 (0.60 / 0.42) | 0.531 (-3.73 / -3.71) |
| 4 | 0.509 | 0.550 (1.39 / 1.08) | 0.504 (9.79 / 8.43) | 0.520 (0.74 / 0.71) | 0.522 (0.58 / 0.46) | 0.513 (-3.69 / -3.70) |
| 5 | 0.466 | 0.548 (1.41 / 1.16) | 0.503 (9.48 / 8.69) | 0.530 (0.76 / 0.73) | 0.521 (0.58 / 0.49) | 0.503 (-3.68 / -3.70) |
| 6 | 0.479 | 0.544 (1.40 / 1.22) | 0.514 (9.51 / 8.89) | 0.532 (0.74 / 0.73) | 0.524 (0.64 / 0.53) | 0.505 (-3.65 / -3.68) |
| 7 | 0.476 | 0.543 (1.38 / 1.26) | 0.513 (9.26 / 8.98) | 0.524 (0.76 / 0.74) | 0.529 (0.63 / 0.56) | 0.498 (-3.69 / -3.68) |
| 8 | 0.520 | 0.544 (1.37 / 1.29) | 0.518 (9.24 / 9.05) | 0.527 (0.74 / 0.74) | 0.542 (0.62 / 0.57) | 0.505 (-3.69 / -3.68) |
| 9 | 0.467 | 0.546 (1.36 / 1.31) | 0.514 (9.39 / 9.13) | 0.524 (0.74 / 0.74) | 0.533 (0.62 / 0.58) | 0.515 (-3.66 / -3.68) |
| 10 | 0.486 | 0.546 (1.36 / 1.32) | 0.509 (9.37 / 9.19) | 0.518 (0.73 / 0.74) | 0.528 (0.62 / 0.59) | 0.508 (-3.67 / -3.68) |
| 11 | 0.474 | 0.546 (1.37 / 1.33) | 0.519 (9.35 / 9.23) | 0.520 (0.73 / 0.74) | 0.525 (0.62 / 0.60) | 0.511 (-3.72 / -3.68) |
| 12 | 0.513 | 0.548 (1.38 / 1.35) | 0.517 (9.44 / 9.29) | 0.523 (0.75 / 0.74) | 0.534 (0.62 / 0.60) | 0.504 (-3.70 / -3.68) |
| 13 | 0.529 | 0.550 (1.37 / 1.35) | 0.517 (9.43 / 9.32) | 0.525 (0.76 / 0.75) | 0.530 (0.62 / 0.61) | 0.513 (-3.68 / -3.68) |
| 14 | 0.433 | 0.547 (1.38 / 1.36) | 0.511 (9.37 / 9.33) | 0.519 (0.76 / 0.75) | 0.531 (0.62 / 0.61) | 0.534 (-3.75 / -3.68) |
| 15 | 0.505 | 0.543 (1.37 / 1.36) | 0.523 (9.35 / 9.34) | 0.519 (0.76 / 0.75) | 0.528 (0.62 / 0.61) | 0.514 (-3.67 / -3.68) |
| 16 | 0.522 | 0.541 (1.36 / 1.36) | 0.511 (9.42 / 9.36) | 0.526 (0.76 / 0.75) | 0.539 (0.62 / 0.62) | 0.507 (-3.74 / -3.68) |
| 17 | 0.507 | 0.542 (1.37 / 1.36) | 0.517 (9.40 / 9.37) | 0.526 (0.76 / 0.75) | 0.538 (0.61 / 0.62) | 0.506 (-3.73 / -3.68) |
| 18 | 0.512 | 0.540 (1.36 / 1.36) | 0.514 (9.35 / 9.37) | 0.525 (0.76 / 0.76) | 0.522 (0.62 / 0.62) | 0.506 (-3.74 / -3.68) |
| 19 | 0.527 | 0.540 (1.36 / 1.36) | 0.523 (9.36 / 9.37) | 0.525 (0.76 / 0.76) | 0.521 (0.62 / 0.62) | 0.510 (-3.66 / -3.67) |
| 20 | 0.499 | 0.541 (1.35 / 1.36) | 0.513 (9.31 / 9.37) | 0.526 (0.76 / 0.76) | 0.521 (0.62 / 0.62) | 0.521 (-3.68 / -3.67) |
| 21 | 0.465 | 0.541 (1.35 / 1.36) | 0.508 (9.66 / 9.44) | 0.523 (0.76 / 0.76) | 0.519 (0.62 / 0.62) | 0.507 (-3.64 / -3.66) |
| 22 | 0.471 | 0.542 (1.35 / 1.36) | 0.516 (9.51 / 9.46) | 0.525 (0.76 / 0.76) | 0.517 (0.63 / 0.62) | 0.534 (-3.68 / -3.66) |
| 23 | 0.513 | 0.541 (1.35 / 1.36) | 0.529 (9.61 / 9.50) | 0.522 (0.76 / 0.76) | 0.516 (0.62 / 0.62) | 0.528 (-3.69 / -3.66) |
| 24 | 0.484 | 0.543 (1.35 / 1.36) | 0.534 (9.60 / 9.52) | 0.519 (0.76 / 0.76) | 0.516 (0.62 / 0.62) | 0.527 (-3.71 / -3.66) |
| 25 | 0.490 | 0.542 (1.36 / 1.36) | 0.534 (9.57 / 9.53) | 0.525 (0.76 / 0.76) | 0.513 (0.62 / 0.62) | 0.521 (-3.69 / -3.66) |
| 26 | 0.489 | 0.540 (1.35 / 1.36) | 0.522 (9.57 / 9.54) | 0.523 (0.76 / 0.76) | 0.525 (0.66 / 0.63) | 0.519 (-3.65 / -3.66) |
| 27 | 0.537 | 0.530 (1.41 / 1.38) | 0.526 (9.54 / 9.54) | 0.524 (0.76 / 0.76) | 0.518 (0.66 / 0.64) | 0.526 (-3.65 / -3.66) |
| 28 | 0.479 | 0.528 (1.40 / 1.38) | 0.530 (9.53 / 9.54) | 0.519 (0.76 / 0.76) | 0.519 (0.66 / 0.64) | 0.536 (-3.69 / -3.66) |
| 29 | 0.462 | 0.528 (1.39 / 1.38) | 0.527 (9.52 / 9.54) | 0.516 (0.76 / 0.76) | 0.516 (0.67 / 0.65) | 0.539 (-3.68 / -3.66) |
| 30 | 0.467 | 0.518 (1.38 / 1.38) | 0.525 (9.53 / 9.54) | 0.515 (0.76 / 0.76) | 0.527 (0.66 / 0.65) | 0.520 (-3.66 / -3.66) |
| 31 | 0.462 | 0.510 (1.39 / 1.39) | 0.526 (9.54 / 9.54) | 0.516 (0.76 / 0.76) | 0.531 (0.66 / 0.66) | 0.531 (-3.66 / -3.66) |
| 32 | 0.445 | 0.539 (1.52 / 1.42) | 0.521 (9.55 / 9.54) | 0.512 (0.76 / 0.76) | 0.527 (0.66 / 0.66) | 0.524 (-3.61 / -3.65) |
| 33 | 0.447 | 0.543 (1.45 / 1.43) | 0.519 (9.56 / 9.55) | 0.510 (0.76 / 0.76) | 0.521 (0.66 / 0.66) | 0.517 (-3.52 / -3.62) |
| 34 | 0.533 | 0.538 (1.47 / 1.44) | 0.517 (9.56 / 9.55) | 0.507 (0.76 / 0.76) | 0.527 (0.66 / 0.66) | 0.521 (-3.61 / -3.62) |
| 35 | 0.470 | 0.530 (1.46 / 1.44) | 0.526 (9.60 / 9.56) | 0.508 (0.76 / 0.76) | 0.520 (0.66 / 0.66) | 0.511 (-3.62 / -3.62) |
