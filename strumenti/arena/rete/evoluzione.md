# Bot che imparano a gradiente

Rete [138, 256, 128, 1] (68609 pesi), 3000 partite per giro, livello difficile, modo tutti, TD(λ) 0.7, memoria 5 giri.

Esame: in quante delle stesse partite la rete del giro arriva più in alto del bot di oggi. Varianza spiegata: quanto la rete prevede il suo obiettivo (0 niente, 1 tutto) su esempi che non ha studiato. La rete con l'esame migliore è in migliore.json.

| giro | esame | varianza spiegata | esempi | morti (rete / oggi) | danno (rete / oggi) | teletrasporti (rete / oggi) |
|---|---|---|---|---|---|---|
| 0 | 28% | 0.25 | 112469 | 3.83 / 2.92 | 277 / 359 | 6.02 / 5.28 |
| 1 | 27% | 0.56 | 222487 | 3.89 / 2.90 | 277 / 364 | 5.87 / 5.32 |
| 2 | 32% | 0.55 | 337800 | 3.85 / 2.94 | 280 / 362 | 6.06 / 5.27 |
| 3 | 32% | 0.52 | 457049 | 3.80 / 2.98 | 280 / 357 | 6.26 / 5.45 |

## Le mosse preferite dell'ultima rete all'esame

- missile>teleport: 280
- missile>lunge: 270
- missile: 199
- missile>lunge>teleport: 196
- missile>teleport+kill: 136
- missile>bellows>teleport: 110
