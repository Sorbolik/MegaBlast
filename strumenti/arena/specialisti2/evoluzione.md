# Specialisti del bot del gioco

5 specialisti da 8 bot, livello difficile, modo tutti. Bravura: quanto in alto arriva in classifica, da 0 (ultimo) a 1 (primo), da tutte le partite giocate. Mestiere: quanto fa la sua specialità; la soglia sale finché il campione resta bravo. Esame: in quante partite a coppie il campione arriva più in alto del bot di oggi (50% vuol dire uguale).

## Gli specialisti

| specialista | mestiere | campione / soglia | bravura | esami | armi principali | cosa cambia |
|---|---|---|---|---|---|---|
| spingitore | uccisioni nel vuoto a partita | 1.39 / 1.39 | 0.540 | 53% 53% 52% 52% 57% 57% | punch 24%, missile 18%, sword 16% | paura di perdere vita ×2.7, cura del compagno ÷1.7, fatica a camminare ×2.1, voglia di globo 201 (oggi 100), riparo a piedi più che col globo 15 (oggi 3), voglia di buttare nel vuoto ×2.0, voglia di uccidere ÷1.8, gusto per le armi da lontano ÷2.0, gusto per il Mantice ×2.1, voglia di casse 60 (oggi 12), voglia di casse quando restano pochi colpi 13 (oggi 8) |
| acrobata | globi e Rampino a partita | 9.92 / 9.90 | 0.526 | 50% 51% 48% 52% 48% 48% | punch 20%, missile 20%, sword 13% | paura di perdere vita ÷8.9, cura del compagno ÷4.3, fatica a camminare ×1.5, voglia di globo 181 (oggi 100), riparo a piedi più che col globo -20 (oggi 3), gusto per il Mantice ×1.5, voglia di casse 57 (oggi 12), voglia di casse quando restano pochi colpi 0 (oggi 8) |
| cecchino | quota del danno fatto da lontano | 0.77 / 0.77 | 0.510 | 50% 50% 50% 53% 49% 50% | shards 25%, missile 19%, sniper 14% | paura di perdere vita ×4.0, cura del compagno ×3.7, paura di morire ÷2.0, voglia di globo 283 (oggi 100), riparo a piedi più che col globo 13 (oggi 3), voglia di buttare nel vuoto ×2.9, voglia di uccidere ÷1.8, voglia di fare danno ÷1.7, gusto per le armi da lontano ×1.7, gusto per il Mantice ×1.7, voglia di casse 28 (oggi 12), voglia di casse quando restano pochi colpi 23 (oggi 8) |
| picchiatore | quota del danno fatto da vicino | 0.64 / 0.64 | 0.539 | 54% 57% 55% 53% 53% 53% | punch 20%, lunge 18%, missile 17% | paura di perdere vita ÷3.1, paura di morire ÷4.3, fatica a camminare ×3.1, voglia di uccidere ÷1.6, gusto per le armi da vicino ×1.8, voglia di casse 21 (oggi 12) |
| sopravvissuto | morti a partita, al contrario | -3.41 / -3.40 | 0.511 | 57% 49% 47% 45% 48% 48% | missile 19%, punch 18%, mallet 17% | paura di perdere vita ×6.3, cura del compagno ÷2.8, fatica a camminare ×4.0, voglia di globo 298 (oggi 100), voglia di buttare nel vuoto ÷1.9, voglia di fare danno ÷2.0, gusto per il Mantice ÷1.7, voglia di casse quando restano pochi colpi 2 (oggi 8) |

## Scelte prese da sola quando non migliorava

- generazione 20: spingitore: muta di più (forza 0.16), perché 3 esami di fila sotto il suo migliore (53%)
- generazione 20: sopravvissuto: muta di più (forza 0.16), perché 3 esami di fila sotto il suo migliore (57%)
- generazione 25: acrobata: muta di più (forza 0.16), perché 3 esami di fila sotto il suo migliore (52%)
- generazione 25: picchiatore: muta di più (forza 0.16), perché 3 esami di fila sotto il suo migliore (57%)

## Generazioni

Per ogni specialista: bravura del campione e mestiere / soglia.

| gen | bot di oggi | spingitore | acrobata | cecchino | picchiatore | sopravvissuto |
|---|---|---|---|---|---|---|
| 1 | 0.493 | 0.533 (1.18 / 0.61) | 0.526 (8.17 / 8.09) | 0.538 (0.59 / 0.59) | 0.515 (0.56 / 0.37) | 0.509 (-3.56 / -3.59) |
| 2 | 0.505 | 0.532 (1.10 / 0.73) | 0.547 (8.27 / 8.13) | 0.540 (0.59 / 0.59) | 0.527 (0.55 / 0.41) | 0.507 (-3.49 / -3.56) |
| 3 | 0.505 | 0.523 (1.21 / 0.85) | 0.536 (8.24 / 8.16) | 0.547 (0.60 / 0.60) | 0.529 (0.57 / 0.45) | 0.528 (-3.57 / -3.56) |
| 4 | 0.564 | 0.527 (1.27 / 0.85) | 0.525 (8.16 / 8.16) | 0.540 (0.60 / 0.60) | 0.534 (0.57 / 0.45) | 0.509 (-3.57 / -3.56) |
| 5 | 0.522 | 0.537 (1.28 / 0.96) | 0.525 (8.17 / 8.16) | 0.537 (0.60 / 0.60) | 0.543 (0.57 / 0.48) | 0.530 (-3.55 / -3.56) |
| 6 | 0.514 | 0.541 (1.32 / 1.05) | 0.518 (8.20 / 8.17) | 0.536 (0.60 / 0.60) | 0.548 (0.62 / 0.52) | 0.534 (-3.61 / -3.56) |
| 7 | 0.501 | 0.548 (1.30 / 1.11) | 0.515 (8.21 / 8.18) | 0.531 (0.60 / 0.60) | 0.557 (0.61 / 0.54) | 0.506 (-3.53 / -3.55) |
| 8 | 0.524 | 0.556 (1.30 / 1.16) | 0.513 (8.19 / 8.18) | 0.525 (0.60 / 0.60) | 0.551 (0.61 / 0.56) | 0.508 (-3.50 / -3.54) |
| 9 | 0.487 | 0.556 (1.30 / 1.19) | 0.511 (9.65 / 8.55) | 0.524 (0.60 / 0.60) | 0.542 (0.62 / 0.57) | 0.525 (-3.56 / -3.54) |
| 10 | 0.503 | 0.550 (1.29 / 1.22) | 0.511 (9.49 / 8.78) | 0.519 (0.60 / 0.60) | 0.540 (0.62 / 0.58) | 0.505 (-3.52 / -3.54) |
| 11 | 0.463 | 0.544 (1.29 / 1.24) | 0.517 (9.45 / 8.95) | 0.516 (0.60 / 0.60) | 0.538 (0.61 / 0.59) | 0.499 (-3.54 / -3.54) |
| 12 | 0.551 | 0.536 (1.28 / 1.25) | 0.525 (9.78 / 8.95) | 0.511 (0.60 / 0.60) | 0.539 (0.61 / 0.60) | 0.511 (-3.48 / -3.54) |
| 13 | 0.499 | 0.536 (1.28 / 1.25) | 0.522 (9.45 / 9.08) | 0.507 (0.60 / 0.60) | 0.532 (0.61 / 0.60) | 0.512 (-3.51 / -3.53) |
| 14 | 0.463 | 0.540 (1.28 / 1.26) | 0.529 (9.51 / 9.18) | 0.506 (0.60 / 0.60) | 0.528 (0.61 / 0.60) | 0.520 (-3.53 / -3.53) |
| 15 | 0.466 | 0.544 (1.30 / 1.27) | 0.524 (9.52 / 9.27) | 0.510 (0.59 / 0.60) | 0.549 (0.61 / 0.61) | 0.504 (-3.49 / -3.52) |
| 16 | 0.516 | 0.553 (1.27 / 1.27) | 0.523 (9.54 / 9.34) | 0.517 (0.80 / 0.65) | 0.545 (0.64 / 0.61) | 0.515 (-3.55 / -3.52) |
| 17 | 0.490 | 0.541 (1.28 / 1.27) | 0.541 (9.30 / 9.34) | 0.497 (0.80 / 0.69) | 0.548 (0.63 / 0.62) | 0.494 (-3.52 / -3.52) |
| 18 | 0.516 | 0.540 (1.27 / 1.27) | 0.537 (9.38 / 9.35) | 0.505 (0.82 / 0.72) | 0.548 (0.63 / 0.62) | 0.487 (-3.49 / -3.52) |
| 19 | 0.498 | 0.541 (1.27 / 1.27) | 0.537 (9.39 / 9.36) | 0.504 (0.75 / 0.73) | 0.544 (0.64 / 0.63) | 0.488 (-3.56 / -3.52) |
| 20 | 0.595 | 0.540 (1.27 / 1.27) | 0.526 (9.38 / 9.36) | 0.501 (0.76 / 0.73) | 0.537 (0.64 / 0.63) | 0.523 (-3.51 / -3.52) |
| 21 | 0.478 | 0.537 (1.26 / 1.27) | 0.525 (9.60 / 9.42) | 0.499 (0.75 / 0.73) | 0.545 (0.64 / 0.63) | 0.495 (-3.47 / -3.51) |
| 22 | 0.509 | 0.541 (1.39 / 1.30) | 0.522 (9.58 / 9.46) | 0.522 (0.78 / 0.75) | 0.545 (0.64 / 0.63) | 0.500 (-3.36 / -3.47) |
| 23 | 0.497 | 0.535 (1.35 / 1.31) | 0.523 (9.58 / 9.49) | 0.534 (0.78 / 0.75) | 0.545 (0.64 / 0.63) | 0.491 (-3.45 / -3.46) |
| 24 | 0.445 | 0.531 (1.38 / 1.33) | 0.520 (9.57 / 9.51) | 0.535 (0.78 / 0.76) | 0.547 (0.64 / 0.64) | 0.498 (-3.35 / -3.44) |
| 25 | 0.508 | 0.536 (1.39 / 1.34) | 0.523 (9.55 / 9.52) | 0.533 (0.78 / 0.76) | 0.545 (0.64 / 0.64) | 0.509 (-3.37 / -3.42) |
| 26 | 0.504 | 0.541 (1.38 / 1.35) | 0.524 (10.05 / 9.65) | 0.524 (0.77 / 0.77) | 0.546 (0.64 / 0.64) | 0.513 (-3.38 / -3.41) |
| 27 | 0.493 | 0.542 (1.39 / 1.36) | 0.525 (9.95 / 9.73) | 0.522 (0.77 / 0.77) | 0.546 (0.64 / 0.64) | 0.521 (-3.40 / -3.41) |
| 28 | 0.489 | 0.537 (1.38 / 1.37) | 0.523 (10.02 / 9.80) | 0.523 (0.77 / 0.77) | 0.544 (0.64 / 0.64) | 0.518 (-3.39 / -3.40) |
| 29 | 0.517 | 0.535 (1.37 / 1.37) | 0.529 (9.93 / 9.83) | 0.515 (0.77 / 0.77) | 0.543 (0.64 / 0.64) | 0.517 (-3.40 / -3.40) |
| 30 | 0.459 | 0.537 (1.38 / 1.37) | 0.530 (9.91 / 9.85) | 0.516 (0.77 / 0.77) | 0.543 (0.64 / 0.64) | 0.513 (-3.39 / -3.40) |
| 31 | 0.488 | 0.542 (1.40 / 1.38) | 0.535 (9.91 / 9.87) | 0.515 (0.77 / 0.77) | 0.542 (0.64 / 0.64) | 0.511 (-3.41 / -3.40) |
| 32 | 0.530 | 0.532 (1.40 / 1.38) | 0.528 (9.91 / 9.88) | 0.513 (0.77 / 0.77) | 0.540 (0.64 / 0.64) | 0.506 (-3.43 / -3.40) |
| 33 | 0.462 | 0.531 (1.41 / 1.39) | 0.524 (9.92 / 9.89) | 0.512 (0.77 / 0.77) | 0.540 (0.64 / 0.64) | 0.507 (-3.39 / -3.40) |
| 34 | 0.526 | 0.540 (1.39 / 1.39) | 0.526 (9.92 / 9.90) | 0.510 (0.77 / 0.77) | 0.539 (0.64 / 0.64) | 0.511 (-3.41 / -3.40) |
