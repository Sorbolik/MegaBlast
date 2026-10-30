# Generazioni del bot del gioco

24 bot per generazione, livello difficile, modo tutti. Bravura: quanto in alto arriva in classifica, da 0 (ultimo) a 1 (primo). Esame: in quante delle stesse partite il campione arriva più in alto del bot di oggi (50% vuol dire uguale). Il migliore è in migliore.json.

## Esami

| gen | contro il bot di oggi | morti (lui / oggi) | globi (lui / oggi) | cosa cambia |
|---|---|---|---|---|
| 3 | 44% | 3.26 / 3.46 | 3.52 / 4.98 | cura del compagno ÷9.9, paura di morire ÷9.2, fatica a camminare ÷7.2, voglia di globo 280 (oggi 100), riparo a piedi più che col globo 30 (oggi 3), voglia di buttare nel vuoto ×3.0 |
| 6 | 47% | 3.27 / 3.46 | 3.55 / 4.98 | paura di morire ÷8.6, fatica a camminare ÷6.0, voglia di globo 344 (oggi 100), riparo a piedi più che col globo 37 (oggi 3), voglia di buttare nel vuoto ×2.6 |
| 9 | 42% | 3.29 / 3.40 | 5.46 / 5.42 | paura di perdere vita ×3.4, fatica a camminare ÷10.0, voglia di globo 313 (oggi 100), voglia di buttare nel vuoto ×2.7, voglia di fare danno ÷1.7 |
| 12 | 45% | 3.26 / 3.49 | 3.56 / 5.09 | paura di perdere vita ×1.7, cura del compagno ×5.0, paura di morire ÷5.8, fatica a camminare ÷2.9, voglia di globo 245 (oggi 100), riparo a piedi più che col globo 19 (oggi 3), voglia di buttare nel vuoto ×3.9, voglia di uccidere ×1.9 |
| 15 | 43% | 3.29 / 3.46 | 3.38 / 5.07 | paura di perdere vita ÷4.0, cura del compagno ×5.0, paura di morire ÷8.9, fatica a camminare ÷8.0, voglia di globo 272 (oggi 100), riparo a piedi più che col globo 31 (oggi 3), voglia di buttare nel vuoto ×1.9, voglia di uccidere ×2.5 |
| 18 | 45% | 3.24 / 3.42 | 3.35 / 5.04 | paura di perdere vita ×4.5, cura del compagno ×4.9, paura di morire ×2.2, fatica a camminare ÷2.7, voglia di globo 353 (oggi 100), riparo a piedi più che col globo 23 (oggi 3), voglia di buttare nel vuoto ×2.0, voglia di uccidere ÷1.7 |
| 21 | 45% | 3.40 / 3.56 | 3.17 / 5.25 | paura di perdere vita ×3.8, cura del compagno ÷1.7, paura di morire ÷5.0, riparo a piedi più che col globo 21 (oggi 3) |
| 24 | 43% | 3.29 / 3.45 | 3.31 / 5.11 | paura di perdere vita ×1.6, cura del compagno ÷10.0, paura di morire ÷2.7, fatica a camminare ÷1.9, voglia di globo 293 (oggi 100), riparo a piedi più che col globo 20 (oggi 3), voglia di buttare nel vuoto ×2.9, voglia di uccidere ×2.6 |

## Gli stili (il più bravo di ognuno)

| stile | bravura | gen | morti | nel vuoto | cosa cambia |
|---|---|---|---|---|---|
| colpisce · si sposta | 0.568 | 24 | 3.47 | 0.52 | paura di perdere vita ×1.6, cura del compagno ÷10.0, paura di morire ÷2.7, fatica a camminare ÷1.9, voglia di globo 293 (oggi 100), riparo a piedi più che col globo 20 (oggi 3), voglia di buttare nel vuoto ×2.9, voglia di uccidere ×2.6 |
| misto · si sposta | 0.567 | 25 | 3.47 | 0.74 | paura di perdere vita ÷12.0, cura del compagno ÷2.6, paura di morire ×3.5, fatica a camminare ÷4.5, voglia di globo 347 (oggi 100), riparo a piedi più che col globo 11 (oggi 3), voglia di buttare nel vuoto ×2.0 |
| colpisce · sempre in volo | 0.545 | 25 | 3.43 | 0.57 | paura di perdere vita ÷2.3, cura del compagno ÷5.3, paura di morire ÷12.0, fatica a camminare ÷8.3, voglia di globo 244 (oggi 100), voglia di buttare nel vuoto ×4.0, voglia di uccidere ×1.5 |
| misto · sempre in volo | 0.502 | 25 | 3.49 | 0.81 | paura di perdere vita ÷3.0, cura del compagno ×2.6, fatica a camminare ÷4.8, voglia di globo 299 (oggi 100), riparo a piedi più che col globo -5 (oggi 3), voglia di buttare nel vuoto ×2.7, voglia di uccidere ÷1.9 |

## Scelte prese da sola quando non migliorava

- generazione 18: mutano di più (forza 0.16), perché 4 esami di fila sotto il migliore (47%)

## Generazioni

| gen | campione | stile | media | bot di oggi | morti | danno | armi principali |
|---|---|---|---|---|---|---|---|
| 1 | 0.599 | colpisce · si sposta | 0.499 | 0.517 | 3.27 | 305 | missile 25%, teleport 25%, hook 8% |
| 2 | 0.557 | colpisce · si sposta | 0.502 | 0.517 | 3.42 | 300 | teleport 25%, missile 23%, hook 8% |
| 3 | 0.554 | colpisce · si sposta | 0.500 | 0.471 | 3.58 | 324 | teleport 24%, missile 23%, eagle 10% |
| 4 | 0.580 | misto · si sposta | 0.500 | 0.522 | 3.58 | 306 | missile 24%, teleport 24%, eagle 8% |
| 5 | 0.549 | colpisce · si sposta | 0.497 | 0.460 | 3.45 | 316 | teleport 24%, missile 23%, hook 8% |
| 6 | 0.568 | colpisce · si sposta | 0.501 | 0.529 | 3.34 | 296 | teleport 25%, missile 23%, eagle 10% |
| 7 | 0.547 | colpisce · sempre in volo | 0.500 | 0.511 | 3.28 | 304 | teleport 45%, missile 19%, eagle 6% |
| 8 | 0.559 | colpisce · si sposta | 0.497 | 0.524 | 3.65 | 312 | teleport 24%, missile 22%, hook 9% |
| 9 | 0.561 | colpisce · sempre in volo | 0.498 | 0.537 | 3.33 | 306 | teleport 33%, missile 23%, eagle 7% |
| 10 | 0.565 | colpisce · si sposta | 0.496 | 0.524 | 3.55 | 308 | missile 23%, teleport 23%, hook 9% |
| 11 | 0.583 | misto · si sposta | 0.500 | 0.556 | 3.42 | 304 | teleport 25%, missile 22%, eagle 9% |
| 12 | 0.538 | misto · si sposta | 0.499 | 0.567 | 3.43 | 292 | teleport 24%, missile 23%, hook 9% |
| 13 | 0.570 | colpisce · si sposta | 0.498 | 0.532 | 3.38 | 318 | teleport 24%, missile 23%, hook 9% |
| 14 | 0.576 | colpisce · si sposta | 0.500 | 0.494 | 3.53 | 318 | missile 23%, teleport 22%, hook 10% |
| 15 | 0.540 | colpisce · si sposta | 0.500 | 0.433 | 3.36 | 306 | missile 26%, teleport 24%, eagle 8% |
| 16 | 0.545 | colpisce · si sposta | 0.500 | 0.481 | 3.26 | 297 | missile 25%, teleport 22%, hook 11% |
| 17 | 0.544 | misto · sempre in volo | 0.502 | 0.454 | 3.43 | 312 | teleport 44%, missile 18%, eagle 6% |
| 18 | 0.547 | misto · si sposta | 0.503 | 0.488 | 3.32 | 295 | missile 26%, teleport 22%, hook 8% |
| 19 | 0.602 | colpisce · si sposta | 0.499 | 0.505 | 3.29 | 310 | missile 24%, teleport 22%, lunge 9% |
| 20 | 0.575 | misto · si sposta | 0.504 | 0.483 | 3.41 | 292 | teleport 24%, missile 24%, hook 9% |
| 21 | 0.554 | colpisce · si sposta | 0.496 | 0.495 | 3.41 | 326 | missile 23%, teleport 22%, hook 9% |
| 22 | 0.547 | colpisce · si sposta | 0.496 | 0.487 | 3.49 | 317 | missile 25%, teleport 22%, hook 9% |
| 23 | 0.556 | colpisce · si sposta | 0.502 | 0.470 | 3.40 | 291 | missile 25%, teleport 23%, hook 8% |
| 24 | 0.568 | colpisce · si sposta | 0.500 | 0.491 | 3.47 | 311 | missile 24%, teleport 23%, hook 8% |
| 25 | 0.567 | misto · si sposta | 0.500 | 0.569 | 3.47 | 304 | teleport 25%, missile 25%, hook 8% |
