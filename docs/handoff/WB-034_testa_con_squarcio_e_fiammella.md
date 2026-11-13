# WB-034 · Testa di oggi senza faccia, con lo squarcio e la fiammella

- **Stato:** APPROVATA (Sergio, 13 nov: «sì, riscrivila»)
- **Data:** 2026-11-13
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-034`

## Obiettivo

Prova con Godot (repository `megablast-godot`): l'apprendista resta quello di oggi, cambia
solo la faccia, che diventa a strati e recita. Il primo tentativo (WB-033, pezzi sciolti
montati da Claude a occhio) è scartato: non tornava con l'apprendista approvato.

Questa volta niente pezzi sciolti. Codex ridisegna **la testa di oggi**, identica e **nella
stessa posizione e misura** del riferimento R1, solo senza faccia e con un piccolo squarcio
acceso in cima. Poi la stessa testa con la fiammella che esce dallo squarcio (Sergio, 13 nov:
la fiammella non è mai staccata dalla testa e segue il movimento). Claude ricava gli strati
del viso per differenza fra le nove teste approvate (R2) e la testa senza faccia: nessun
pezzo viene messo a occhio.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-034/riferimenti/R1_testa_guida.png` | la testa di oggi (WB-009, la prima delle nove), 1024×1024: posizione e misura da tenere uguali |
| R2 | `art/WB-009/7_teste.png` | le nove espressioni approvate (stessa testa) |
| R3 | `art/WB-018/riferimenti/R1_apprendista_concept.png` | l'apprendista con la fiammella: forma e colori della fiamma |

## Immagini da generare

| Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|
| `art/WB-034/testa_nuda.png` | R1, R2 | 1024×1024 | 2 |
| `art/WB-034/testa_fiamma.png` | `testa_nuda_1.png`, R3 | 1024×1024 | 2 |

Le varianti si chiamano `testa_nuda_1.png`, `testa_nuda_2.png`, `testa_fiamma_1.png`,
`testa_fiamma_2.png`. `testa_fiamma` parte da `testa_nuda_1.png` appena generata.

### `testa_nuda`

```
Image 1 is the head of our little devil "Apprendista" on a flat magenta background. Image 2 shows the same head with his nine expressions. Redraw image 1 EXACTLY: same head, same horns, same ears, same muzzle, same nose, same colors, same thick black outline, same flat rendering, and above all the SAME SIZE and the SAME POSITION on the canvas, pixel for pixel, so the two images can be laid one over the other.

Only two changes:
1. Remove the face: NO eyes, NO eyebrows, NO mouth line. Where they were, paint the skin and the cream muzzle as if they had never been there, with the same flat colors. Keep the nose and the inner ear lines.
2. On the top of the skull, between the horns, add a SMALL TORN OPENING in the skin: a little rip about one sixth of the head wide, with ragged edges and glowing orange-yellow inside. This is where his flame comes out.

No flame, no neck, no body. Background: flat pure magenta #FF00FF everywhere outside the head, like image 1. No text, no labels. Square 1024x1024.
```

### `testa_fiamma`

```
Image 1 is the head of our little devil "Apprendista" with a small glowing torn opening on top of the skull. Image 2 shows the same character with his head flame. Redraw image 1 EXACTLY, same size, same position on the canvas, pixel for pixel, and add his flame coming OUT of the torn opening: orange and yellow like image 2, with a thick black outline, about as tall as the head without the horns, leaning slightly back. The bottom of the flame is narrow and ragged and sits INSIDE the rip, so the flame clearly grows out of his skull and is part of him, not a separate fire floating above the head. Nothing else changes.

Background: flat pure magenta #FF00FF everywhere outside the head and the flame. No text, no labels. Square 1024x1024.
```

## Criteri di accettazione

- [ ] la testa è quella di R1, nella stessa posizione e misura (sovrapposte combaciano)
- [ ] `testa_nuda`: niente occhi, sopracciglia e bocca; naso e orecchie come in R1
- [ ] piccolo squarcio acceso in cima, fra le corna
- [ ] `testa_fiamma`: uguale a `testa_nuda_1`, con la fiammella che esce dallo squarcio
- [ ] sfondo magenta pulito, contorno nero spesso, nessuna scritta

---

## Decisione

Riscritta e approvata da Sergio il 13 nov («sì, riscrivila»), al posto della prima versione
che chiedeva pezzi sciolti.

## Consegna di Codex

## Resoconto di Claude
