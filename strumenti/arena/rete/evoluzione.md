# Bot che imparano a gradiente

Rete [138, 256, 128, 1] (68609 pesi), 3000 partite per giro, livello difficile, modo tutti, TD(λ) 0.7, memoria 5 giri.

Esame: in quante delle stesse partite la rete del giro arriva più in alto del bot di oggi. Varianza spiegata: quanto la rete prevede il suo obiettivo (0 niente, 1 tutto) su esempi che non ha studiato. La rete con l'esame migliore è in migliore.json.

| giro | esame | varianza spiegata | esempi | morti (rete / oggi) | danno (rete / oggi) | teletrasporti (rete / oggi) |
|---|---|---|---|---|---|---|
| 0 | 40% | 0.22 | 106311 | 3.85 / 3.43 | 310 / 350 | 6.66 / 6.04 |
| 1 | 45% | 0.50 | 213292 | 3.86 / 3.44 | 317 / 342 | 6.44 / 5.91 |

## Le mosse preferite dell'ultima rete all'esame

- missile>teleport: 390
- missile>teleport+kill: 300
- missile: 205
- missile+kill: 125
- missile>hook: 74
- teleport>missile>teleport: 73
