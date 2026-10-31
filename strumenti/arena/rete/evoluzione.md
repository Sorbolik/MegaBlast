# Bot che imparano a gradiente

Rete [138, 256, 128, 1] (68609 pesi), 3000 partite per giro, livello difficile, modo tutti, TD(λ) 0.7, memoria 5 giri.

Esame: in quante delle stesse partite la rete del giro arriva più in alto del bot di oggi. Varianza spiegata: quanto la rete prevede il suo obiettivo (0 niente, 1 tutto) su esempi che non ha studiato. La rete con l'esame migliore è in migliore.json.

| giro | esame | varianza spiegata | esempi | morti (rete / oggi) | danno (rete / oggi) | teletrasporti (rete / oggi) |
|---|---|---|---|---|---|---|
| 0 | 31% | 0.26 | 112469 | 3.77 / 2.94 | 274 / 360 | 6.12 / 5.33 |
| 1 | 32% | 0.57 | 221866 | 3.83 / 2.85 | 276 / 362 | 6.12 / 5.34 |
| 2 | 36% | 0.57 | 337387 | 3.84 / 2.99 | 280 / 361 | 6.27 / 5.19 |
| 3 | 35% | 0.56 | 456668 | 3.79 / 2.98 | 279 / 355 | 6.55 / 5.10 |

## Le mosse preferite dell'ultima rete all'esame

- missile>teleport: 267
- missile>lunge: 236
- missile: 174
- missile>teleport+kill: 142
- missile>lunge>teleport: 124
- missile+kill: 102
