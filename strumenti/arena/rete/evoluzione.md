# Bot che imparano a gradiente

Rete [138, 256, 128, 1] (68609 pesi), 3000 partite per giro, livello difficile, modo tutti, TD(λ) 0.7, memoria 5 giri.

Esame: in quante delle stesse partite la rete del giro arriva più in alto del bot di oggi. Varianza spiegata: quanto la rete prevede il suo obiettivo (0 niente, 1 tutto) su esempi che non ha studiato. La rete con l'esame migliore è in migliore.json.

| giro | esame | varianza spiegata | esempi | morti (rete / oggi) | danno (rete / oggi) | teletrasporti (rete / oggi) |
|---|---|---|---|---|---|---|
| 0 | 28% | 0.25 | 112469 | 3.83 / 2.92 | 277 / 359 | 6.02 / 5.28 |
| 1 | 27% | 0.56 | 222487 | 3.89 / 2.90 | 277 / 364 | 5.87 / 5.32 |
| 2 | 32% | 0.55 | 337800 | 3.85 / 2.94 | 280 / 362 | 6.06 / 5.27 |
| 3 | 32% | 0.52 | 457049 | 3.80 / 2.98 | 280 / 357 | 6.26 / 5.45 |
| 4 | 32% | 0.50 | 575871 | 3.80 / 2.98 | 280 / 357 | 6.26 / 5.45 |
| 5 | 32% | 0.50 | 582204 | 3.77 / 2.96 | 275 / 357 | 6.22 / 5.31 |
| 6 | 30% | 0.53 | 597331 | 3.77 / 3.03 | 291 / 351 | 4.85 / 5.49 |
| 7 | 36% | 0.53 | 604951 | 3.51 / 2.91 | 282 / 328 | 5.31 / 5.23 |
| 8 | 48% | 0.53 | 608503 | 3.69 / 3.23 | 315 / 331 | 5.98 / 5.34 |
| 9 | 44% | 0.54 | 612665 | 3.66 / 3.25 | 313 / 330 | 5.96 / 5.30 |
| 10 | 48% | 0.55 | 616563 | 3.63 / 3.31 | 321 / 331 | 6.14 / 5.38 |
| 11 | 48% | 0.56 | 614384 | 3.63 / 3.31 | 321 / 331 | 6.14 / 5.38 |

## Le mosse preferite dell'ultima rete all'esame

- missile>teleport: 588
- missile: 409
- missile>teleport+kill: 337
- missile+kill: 168
- missile>hook: 122
- missile>teleport>sword>teleport: 82
