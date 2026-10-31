# Bot che imparano a gradiente

Rete [135, 256, 128, 1] (67841 pesi), 3000 partite per giro, livello difficile, modo tutti, TD(λ) 0.7, memoria 5 giri.

Esame: in quante delle stesse partite la rete del giro arriva più in alto del bot di oggi. Varianza spiegata: quanto la rete prevede il suo obiettivo (0 niente, 1 tutto) su esempi che non ha studiato. La rete con l'esame migliore è in migliore.json.

| giro | esame | varianza spiegata | esempi | morti (rete / oggi) | danno (rete / oggi) | teletrasporti (rete / oggi) |
|---|---|---|---|---|---|---|
| 0 | 9% | 0.31 | 58720 | 2.83 / 1.74 | 145 / 291 | 2.39 / 4.29 |
| 1 | 15% | 0.40 | 114442 | 2.76 / 1.81 | 156 / 287 | 2.40 / 4.14 |
| 2 | 8% | 0.39 | 168948 | 2.83 / 1.76 | 145 / 289 | 2.42 / 4.28 |

## Le mosse preferite dell'ultima rete all'esame

- missile: 291
- teleport: 241
- grenade: 129
- missile>teleport: 105
- missile+kill: 95
- teleport>missile: 84
