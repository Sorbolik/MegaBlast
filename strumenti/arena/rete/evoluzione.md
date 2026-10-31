# Bot che imparano a gradiente

Rete [137, 256, 128, 1] (68353 pesi), 3000 partite per giro, livello difficile, modo tutti, TD(λ) 0.7, memoria 5 giri.

Esame: in quante delle stesse partite la rete del giro arriva più in alto del bot di oggi. Varianza spiegata: quanto la rete prevede il suo obiettivo (0 niente, 1 tutto) su esempi che non ha studiato. La rete con l'esame migliore è in migliore.json.

| giro | esame | varianza spiegata | esempi | morti (rete / oggi) | danno (rete / oggi) | teletrasporti (rete / oggi) |
|---|---|---|---|---|---|---|
| 0 | 28% | 0.22 | 64666 | 3.85 / 2.50 | 236 / 344 | 3.39 / 5.05 |
| 1 | 32% | 0.43 | 129698 | 3.83 / 2.57 | 240 / 347 | 3.52 / 5.35 |
| 2 | 32% | 0.41 | 193894 | 3.69 / 2.68 | 246 / 344 | 4.01 / 5.15 |
| 3 | 40% | 0.40 | 257854 | 3.78 / 2.71 | 250 / 347 | 3.87 / 5.31 |
| 4 | 33% | 0.39 | 321776 | 3.90 / 2.69 | 249 / 346 | 3.80 / 5.14 |
| 5 | 37% | 0.37 | 320904 | 3.85 / 2.65 | 246 / 345 | 3.79 / 5.24 |

## Le mosse preferite dell'ultima rete all'esame

- missile: 440
- missile>lunge: 236
- missile>teleport: 201
- missile+kill: 155
- missile>bellows: 143
- missile>eagle: 113
