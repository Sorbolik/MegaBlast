# WB-043 · Icone dei pezzi per l'inventario e il buono del Fabbro

- **Stato:** APPROVATA (Claude, 14 nov: reversibile, serve a qualunque delle proposte dei menu)
- **Data:** 2026-11-14
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-043`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-043` senza chiedere conferma (il repository è privato).

## Obiettivo

Sergio (14 nov) vuole l'inventario a quadratini: in ogni quadratino l'immagine del pezzo, anche
nelle etichette dei pezzi indossati, nella bottega e nell'armeria. Servono quindi le **icone** di
tutti i pezzi: 5 famiglie × 4 posti (ELMO, CORAZZA, MANTELLO, STIVALI) × 2 forme (base e
forgiata) = 40 icone, tratte dalle tavole già scelte di WB-019 (stessi colori, stesse forme).
Servono anche l'icona del **buono del Fabbro** (va nel portafoglio, accanto a Scaglie e
Ossidiana) e quattro **sagome vuote** per un posto senza pezzo. Le bozze dei menu sono nella
pagina Figma «RIORGANIZZAZIONE MENU · 14 nov» e in R6, R7: lì le icone sono provvisorie (pezzi
del Vuoto ricolorati), queste le sostituiscono.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-019/scelti/fabbro.png` | tavola scelta della famiglia Fabbro (sinistra base, destra forgiata) |
| R2 | `art/WB-019/scelti/corvo.png` | tavola scelta del Corvo |
| R3 | `art/WB-019/scelti/fornace.png` | tavola scelta della Fornace |
| R4 | `art/WB-019/scelti/leviatano.png` | tavola scelta del Leviatano |
| R5 | `art/WB-019/scelti/vuoto.png` | tavola scelta del Vuoto |
| R6 | `art/WB-043/riferimenti/R6_inventario_bozza.jpg` | bozza dell'inventario: i quadratini dove vanno le icone |
| R7 | `art/WB-043/riferimenti/R7_bottega_bozza.jpg` | bozza della bottega: icone nelle carte e buono nel portafoglio |
| R8 | `client/assets/fucina/scaglia.png` | la moneta Scaglia del gioco: stile e misura del buono |

## Immagini da generare

Ogni prompt è completo e va usato così com'è.

| Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|
| `art/WB-043/icone_fabbro.png` | R1, R6 | 1536×1024 | 1 |
| `art/WB-043/icone_corvo.png` | R2, R6 | 1536×1024 | 1 |
| `art/WB-043/icone_fornace.png` | R3, R6 | 1536×1024 | 1 |
| `art/WB-043/icone_leviatano.png` | R4, R6 | 1536×1024 | 1 |
| `art/WB-043/icone_vuoto.png` | R5, R6 | 1536×1024 | 1 |
| `art/WB-043/buono.png` | R8, R7, R1 | 1024×1024 | 3 |
| `art/WB-043/sagome_vuote.png` | R6 | 1536×1024 | 1 |

Le varianti del buono si chiamano `buono_1.png`, `buono_2.png`, `buono_3.png`. Per ogni foglio
Codex scrive un `.txt` con lo stesso nome: cosa ha fatto e cosa non è riuscito a rispettare.

### `icone_<famiglia>` (uno per famiglia; nel prompt cambia solo il nome e il riferimento)

Per il Fabbro si allega R1, per il Corvo R2, per la Fornace R3, per il Leviatano R4, per il
Vuoto R5. Nel prompt `<FAMILY>` diventa FABBRO, CORVO, FORNACE, LEVIATANO o VUOTO.

```
Image 1 is the approved style sheet of the armour family "<FAMILY>" of our game: the same little devil wears the four pieces, on the LEFT in the BASIC form and on the RIGHT in the FORGED form. Image 2 is a mock-up of the game's inventory, where every piece is shown as an icon inside a dark square.

Draw an ICON SHEET of this family's eight pieces, alone, without the devil: a grid of 4 columns and 2 rows on flat magenta.
- Columns, left to right: HELMET, CHEST ARMOUR, CAPE, BOOTS.
- Top row: the BASIC form of each piece, exactly as on the left of image 1. Bottom row: the FORGED form, exactly as on the right of image 1.
- Each piece is the SAME object as in image 1 (same shapes, colors, cyan #00FFFF trims, details), shown alone as a game item icon, three-quarter view, slightly from the front, centered in its cell and filling about 80% of it. Nothing of the devil: no head, horns, skin, face, arms or legs inside or around the pieces (the helmet is empty inside, the boots are a pair seen together, the cape hangs open as a short cloak, the chest armour is seen as a worn breastplate without a body).
- All eight pieces at the same scale feeling, so they read as one set; leave a clear magenta gap of at least 60 pixels between cells.

Rendering rules, very strict, because the icons will be cut out and shown small:
- Same comic style as image 1: thick closed black #000000 outline, flat colors, at most one hard-edged shadow shape per area. No gradients, no glow, no textures, no soft shading.
- Keep the cyan #00FFFF trims exactly cyan: the game tints them by grade.
- Background: flat pure magenta #FF00FF everywhere, no halo around the pieces, no shadow on the ground.
- No text, numbers, labels, frames, squares or signatures.
```

### `buono`

```
Image 1 is the "Scaglia" coin of our game (style and size reference). Image 2 is a mock-up of the shop, where the voucher sits in the wallet at the top right next to the coins. Image 3 shows the armour of the Smith (Fabbro) family.

Draw ONE icon: the "Smith's voucher", a small forged iron token that the old Smith gives to the player and that buys any armour piece. It is a thick rectangular iron tag with rounded corners, slightly tilted, with a hole at one end and a short loop of red cord through it; on the face a hammer-and-anvil mark stamped in glowing molten gold #FFB703 with a darker ember #F26419 edge. It must read clearly at 40 pixels next to the coin of image 1, with the same thickness of outline and the same comic look, and it must not look like a coin (no round shape) and not like a medal.

Rendering rules, very strict:
- Comic style like image 1: thick closed black #000000 outline, flat colors, at most one hard-edged shadow shape per area. No gradients, no glow, no textures.
- Iron in #4A4550 with darker #262329 shadow, cord #FF3B4E.
- Centered, filling about 80% of the square canvas.
- Background: flat pure magenta #FF00FF everywhere, no halo, no ground shadow.
- No text, numbers or signatures.
```

### `sagome_vuote`

```
Image 1 is a mock-up of the game's inventory: dark squares that hold the icon of each armour piece.

Draw an icon sheet of four EMPTY SLOT silhouettes, in a row, left to right: HELMET, CHEST ARMOUR, CAPE, BOOTS. Each one is a simple, generic, flat silhouette of that kind of piece (not any specific family), filled with a single steel grey #4A4550 with a slightly lighter inner shape #5A5560, and a thick closed black #000000 outline; it is shown in a slot when nothing is worn there, so it must look quiet and clearly "empty". Same three-quarter view and size for all four, centered in four equal cells with wide magenta gaps between them.

Rendering rules, very strict:
- Flat colors only, no gradients, no glow, no textures, no soft shading.
- Background: flat pure magenta #FF00FF everywhere, no halo, no ground shadow.
- No text, numbers, labels, frames or signatures.
```

## Criteri di accettazione

- [ ] ogni pezzo è lo stesso della tavola scelta di WB-019 (forme, colori, finiture ciano), riconoscibile anche a 64 pixel
- [ ] nessuna parte del diavoletto (pelle, corna, facce, mani, piedi) dentro o attorno ai pezzi
- [ ] le finiture sono ciano puro `#00FFFF` (il gioco le tinge per grado)
- [ ] sfondo magenta pulito, contorno nero puro e spesso, nessuna scritta
- [ ] il buono non sembra una moneta né una medaglia e si legge a 40 pixel accanto alla Scaglia
- [ ] le sagome vuote sono chiaramente "vuote" e non di una famiglia

---

## Decisione

Approvata da Claude il 14 nov (reversibile: sono solo immagini). Sergio sceglie il layout dei
menu fra le proposte del Figma; le icone servono a tutte.

## Consegna di Codex

## Resoconto di Claude
