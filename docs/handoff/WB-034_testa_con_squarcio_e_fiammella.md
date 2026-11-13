# WB-034 · Testa dell'apprendista con lo squarcio e la fiammella

- **Stato:** APPROVATA (Claude, 13 nov: completa WB-033 come chiesto da Sergio)
- **Data:** 2026-11-13
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-034`

## Obiettivo

Codex ha eseguito WB-033 prima della correzione di Sergio sulla fiammella, quindi i fogli
`testa` non hanno lo squarcio in cima alla testa né la fiammella. Questa scheda rifà solo la
testa: la stessa di `art/WB-033/testa_2.png` (che va bene), con un piccolo squarcio acceso in
cima e la fiammella a parte, con la base larga come lo squarcio, così esce dalla testa e non
galleggia sopra (Sergio, 13 nov). In Godot la fiammella è una catena simulata che segue il
movimento, con la radice ferma nello squarcio.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-033/testa_2.png` (ramo `design/WB-033`) | la testa di WB-033 da tenere uguale |
| R2 | `art/WB-018/riferimenti/R1_apprendista_concept.png` | l'apprendista con la fiammella: forma e colori della fiamma |

## Immagini da generare

| Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|
| `art/WB-034/testa.png` | R1, R2 | 1536×1024 | 2 |

Le varianti si chiamano `testa_1.png` e `testa_2.png`.

### `testa`

```
Image 1 is a sheet of head pieces of our little devil "Apprendista": a head base, two horns, two ears and a squashed head base. Image 2 shows the same character with his head flame. Redraw the sheet of image 1 EXACTLY the same (same pieces, same shapes, same colors, same thick black outline, same layout and scale), with two changes:

1. On the top of BOTH head bases (the normal one and the squashed one), between where the horns go, add a SMALL TORN OPENING in the skin: a little rip about one fifth of the head wide, with ragged edges, glowing orange-yellow inside. This is where his flame comes out.
2. Add one more piece, the FLAME: his head flame as in image 2, alone, upright, orange and yellow with a thick black outline, about as tall as the head base. Its bottom is narrow and ragged and has exactly the width and shape of the torn opening, so that placed on it the flame grows OUT of the rip in the skull and is clearly part of him, not a separate fire floating on his head. Keep it separated from the other pieces by at least 40 pixels.

No face on the heads (no eyes, no eyebrows, no mouth). No shading gradients. Background: flat pure magenta #FF00FF everywhere outside the pieces. No text, no labels. Landscape 3:2.
```

## Criteri di accettazione

- [ ] pezzi uguali a R1 (testa, corna, orecchie, testa schiacciata), stesso contorno nero
- [ ] su entrambe le teste un piccolo squarcio acceso in cima, fra le corna
- [ ] la fiammella a parte, con la base stretta e frastagliata larga come lo squarcio
- [ ] sfondo magenta pulito, nessuna scritta

---

## Decisione

Approvata da Claude il 13 nov: completa WB-033 con la regola di Sergio sulla fiammella, è reversibile.

## Consegna di Codex

## Resoconto di Claude
