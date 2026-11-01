# Bot che imparano a gradiente

Rete [138, 256, 128, 1] (68609 pesi), 3000 partite per giro, livello difficile, modo tutti, TD(λ) 0.7, memoria 5 giri.

Esame: in quante delle stesse partite la rete del giro arriva più in alto del bot di oggi. Varianza spiegata: quanto la rete prevede il suo obiettivo (0 niente, 1 tutto) su esempi che non ha studiato. La rete con l'esame migliore è in migliore.json.

| giro | esame | varianza spiegata | esempi | morti (rete / oggi) | danno (rete / oggi) | teletrasporti (rete / oggi) |
|---|---|---|---|---|---|---|
| 0 | 40% | 0.22 | 106311 | 3.85 / 3.43 | 310 / 350 | 6.66 / 6.04 |
| 1 | 45% | 0.50 | 213292 | 3.86 / 3.44 | 317 / 342 | 6.44 / 5.91 |
| 2 | 39% | 0.53 | 325837 | 3.89 / 3.49 | 316 / 346 | 6.42 / 6.05 |
| 3 | 42% | 0.53 | 443900 | 3.88 / 3.46 | 315 / 343 | 6.30 / 6.00 |
| 4 | 44% | 0.53 | 562100 | 3.75 / 3.45 | 320 / 333 | 6.39 / 6.02 |
| 5 | 45% | 0.53 | 573457 | 3.76 / 3.46 | 317 / 335 | 6.36 / 6.12 |

## Le mosse preferite dell'ultima rete all'esame

- missile>teleport: 349
- missile>teleport+kill: 304
- missile: 165
- missile+kill: 119
- missile>hook: 111
- teleport>missile>teleport: 65
