# WB-035 · La fessura in cima alla testa è verticale

- **Stato:** APPROVATA (Sergio, 13 nov: «va bene, ma la fessura deve essere verticale, com'era nella prima generazione»)
- **Data:** 2026-11-13
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-035`

## Obiettivo

WB-034 va bene, ma lo squarcio in cima alla testa è orizzontale. Nella prima generazione
dell'apprendista (R2) la fiamma esce da una **fessura verticale**: una piega stretta che scende
dalla cima del cranio verso la fronte, in mezzo fra le corna. Si rifanno le due teste di
WB-034 (variante 1) con la fessura verticale; tutto il resto resta identico, nella stessa
posizione e misura, perché Claude ricava gli strati del viso per differenza.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-035/riferimenti/R1_testa_nuda_WB-034.png` | la testa senza faccia di WB-034 (variante 1): da tenere identica |
| R2 | `art/WB-035/riferimenti/R2_fessura_prima_generazione.png` | la prima generazione: la fiamma esce da una fessura verticale |
| R3 | `art/WB-035/riferimenti/R3_testa_fiamma_WB-034.png` | la testa con la fiammella di WB-034 (variante 1): la fiamma da tenere |

## Immagini da generare

| Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|
| `art/WB-035/testa_nuda.png` | R1, R2 | 1024×1024 | 2 |
| `art/WB-035/testa_fiamma.png` | `testa_nuda_1.png`, R3, R2 | 1024×1024 | 2 |

Le varianti si chiamano `testa_nuda_1.png`, `testa_nuda_2.png`, `testa_fiamma_1.png`,
`testa_fiamma_2.png`. `testa_fiamma` parte da `testa_nuda_1.png` appena generata.

### `testa_nuda`

```
Image 1 is the head of our little devil "Apprendista" without a face, on a flat magenta background, with a small horizontal glowing rip on top of the skull. Image 2 is the first drawing of the same character: look at the top of his head, the flame comes out of a VERTICAL slit, a narrow crease that runs down from the top of the skull toward the forehead, between the horns.

Redraw image 1 EXACTLY: same head, horns, ears, muzzle, nose, colors, thick black outline, flat rendering, and the SAME SIZE and SAME POSITION on the canvas, pixel for pixel, so the two images can be laid one over the other. Only one change: replace the horizontal rip with a VERTICAL slit like image 2: a narrow opening that starts at the very top of the skull, between the horns, and runs straight down toward the forehead for about one fifth of the head's height, with a thin black outline and glowing orange-yellow inside, wider at the top where the flame will come out and closing to a point at the bottom. No horizontal rip any more.

No face (no eyes, no eyebrows, no mouth), no flame, no neck. Background: flat pure magenta #FF00FF everywhere outside the head. No text, no labels. Square 1024x1024.
```

### `testa_fiamma`

```
Image 1 is the head of our little devil "Apprendista" with a narrow vertical glowing slit on top of the skull. Image 2 is the same head with his flame, drawn with an older horizontal rip. Image 3 is the first drawing of the character: the flame grows out of the vertical slit.

Redraw image 1 EXACTLY, same size, same position on the canvas, pixel for pixel, and add the flame of image 2 (same shape, colors and black outline) growing OUT of the top of the vertical slit, as in image 3: the bottom of the flame sits inside the wide top of the slit, so the flame is clearly part of his skull, not a fire floating above it. Nothing else changes.

Background: flat pure magenta #FF00FF everywhere outside the head and the flame. No text, no labels. Square 1024x1024.
```

## Criteri di accettazione

- [ ] testa identica a R1, stessa posizione e misura
- [ ] fessura verticale stretta dalla cima del cranio verso la fronte, accesa dentro, come R2; niente squarcio orizzontale
- [ ] `testa_fiamma`: la fiamma di R3 esce dalla cima della fessura
- [ ] sfondo magenta pulito, nessuna scritta

---

## Decisione

Approvata da Sergio il 13 nov (correzione di WB-034).

## Consegna di Codex

## Resoconto di Claude
