# Bot che imparano a gradiente

Rete [135, 256, 128, 1] (67841 pesi), 3000 partite per giro, livello difficile, modo tutti, TD(λ) 0.7, memoria 5 giri.

Esame: in quante delle stesse partite la rete del giro arriva più in alto del bot di oggi. Varianza spiegata: quanto la rete prevede il suo obiettivo (0 niente, 1 tutto) su esempi che non ha studiato. La rete con l'esame migliore è in migliore.json.

| giro | esame | varianza spiegata | esempi | morti (rete / oggi) | danno (rete / oggi) | teletrasporti (rete / oggi) |
|---|---|---|---|---|---|---|
| 0 | 23% | 0.29 | 63448 | 3.58 / 2.60 | 233 / 331 | 3.98 / 5.21 |
| 1 | 34% | 0.48 | 126120 | 3.71 / 2.79 | 261 / 333 | 4.51 / 4.98 |
| 2 | 35% | 0.42 | 187646 | 3.67 / 2.84 | 260 / 335 | 4.58 / 5.03 |
| 3 | 29% | 0.39 | 249108 | 3.69 / 2.76 | 258 / 339 | 4.44 / 4.92 |

## Le mosse preferite dell'ultima rete all'esame

- missile: 296
- missile>lunge: 208
- missile>teleport: 184
- missile>bellows: 119
- missile>lunge>teleport: 109
- missile>eagle: 108
