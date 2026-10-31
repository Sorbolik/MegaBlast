# Bot che imparano a gradiente

Rete [138, 256, 128, 1] (68609 pesi), 3000 partite per giro, livello difficile, modo tutti, TD(λ) 0.7, memoria 5 giri.

Esame: in quante delle stesse partite la rete del giro arriva più in alto del bot di oggi. Varianza spiegata: quanto la rete prevede il suo obiettivo (0 niente, 1 tutto) su esempi che non ha studiato. La rete con l'esame migliore è in migliore.json.

| giro | esame | varianza spiegata | esempi | morti (rete / oggi) | danno (rete / oggi) | teletrasporti (rete / oggi) |
|---|---|---|---|---|---|---|
| 0 | 19% | 0.25 | 117346 | 3.85 / 2.30 | 209 / 355 | 3.15 / 5.26 |
| 1 | 26% | 0.61 | 234604 | 3.91 / 2.43 | 223 / 348 | 3.39 / 5.19 |
| 2 | 28% | 0.57 | 350482 | 3.94 / 2.51 | 237 / 352 | 3.68 / 5.15 |
| 3 | 32% | 0.53 | 464850 | 3.87 / 2.59 | 242 / 347 | 3.81 / 5.24 |
| 4 | 32% | 0.51 | 577705 | 3.87 / 2.59 | 242 / 347 | 3.81 / 5.24 |

## Le mosse preferite dell'ultima rete all'esame

- missile: 431
- missile>lunge: 227
- missile>teleport: 212
- missile>bellows: 167
- missile+kill: 147
- missile>eagle: 146
