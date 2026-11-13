# WB-033 · Apprendista fatto per piegarsi (prova con Godot)

- **Stato:** APPROVATA (Sergio, 13 nov)
- **Data:** 2026-11-13
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-033`

## Obiettivo

Nella prova con Godot (repository `megablast-godot`) l'apprendista è fatto di maglie piegate
dalle ossa. I pezzi di oggi sono tagliati per stare rigidi: braccia e gambe spezzate al
gomito e al ginocchio, faccia disegnata dentro la testa. Piegati, mostrano le cuciture e la
faccia non può recitare. Serve lo stesso apprendista, stesso stile e stessi colori, ridisegnato
a pezzi pensati per piegarsi e per le espressioni: braccia e gambe intere e dritte, busto con
la pancia, testa senza faccia, e la faccia a strati (occhi, pupille, sopracciglia, bocche). La fiammella esce da un piccolo squarcio
in cima alla testa, come nelle prime generazioni di apprendista, Favilla e Fabbro: è un pezzo a
parte solo per seguire il movimento (una catena simulata), ma resta attaccata alla testa.
È la fase 2 del piano «Apprendista rifatto in Godot» (https://claude.ai/artifact/FuyRsi18ViZeokoeZYeYRw).

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-009/riferimenti/R1b_apprendista_senza_fiammella.png` | l'apprendista approvato, tre quarti verso destra: forme, colori, contorno |
| R2 | `art/WB-012/scelti/apprendista.png` | le 9 espressioni approvate: occhi, sopracciglia e bocche da copiare |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Tre fogli, sfondo magenta pieno, pezzi staccati
fra loro di almeno 40 pixel (Claude li ritaglia uno per uno).

| Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|
| `art/WB-033/corpo.png` | R1 | 1536×1024 | 2 |
| `art/WB-033/testa.png` | R1, R2 | 1536×1024 | 2 |
| `art/WB-033/viso.png` | R1, R2 | 1536×1024 | 2 |

Le varianti si chiamano `corpo_1.png`, `corpo_2.png` e così via.

### `corpo`

```
Image 1 is our approved character, the little devil "Apprendista", in three-quarter view facing right. Redraw the SAME character, same proportions, same colors, same thick black outline, same flat cartoon rendering, but cut into separate pieces made to be bent by a 2D skeleton (cut-out animation with mesh deformation). Lay the pieces out on one sheet, separated from each other by at least 40 pixels, all at the same scale as each other, nothing overlapping:

1. TORSO: chest, belly and hips in ONE piece, the cream belly patch included, no arms, no legs, no head, no scarf. The top ends in a short neck stub; the shoulders and the hips are rounded domes, so the arms and legs can rotate on them without gaps.
2. SCARF: the blue scarf with its knot, alone.
3. FRONT ARM: the whole arm in ONE piece, from the shoulder to the closed fist, hanging perfectly straight down, the elbow in the middle. The arm keeps the same width along its length and has NO line, crease or seam at the elbow, so it can bend smoothly anywhere. The top is a rounded dome.
4. BACK ARM: the same, for the arm on the far side (slightly darker red, as in image 1).
5. FRONT LEG: the whole leg in ONE piece, from the hip to the foot with its cream toes, perfectly straight, the knee in the middle, same width along its length, NO line or seam at the knee. The top is a rounded dome.
6. BACK LEG: the same, for the far leg (slightly darker red).
7. TAIL: the whole tail in ONE piece, drawn almost straight (a gentle curve), thicker at the root, ending with the arrow tip.

No head on this sheet. No shading gradients: one flat color per area plus at most one hard-edged shadow. Background: flat pure magenta #FF00FF everywhere outside the pieces. No text, no labels, no numbers. Landscape 3:2.
```

### `testa`

```
Image 1 is our approved character, the little devil "Apprendista", three-quarter view facing right. Image 2 shows his approved facial expressions. Redraw his HEAD, same shape, colors, thick black outline and flat rendering, split into separate pieces for a 2D rig, on one sheet, pieces separated by at least 40 pixels, all at the same scale:

1. HEAD BASE: the head with the cream muzzle area, but with NO eyes, NO eyebrows and NO mouth: the face is bare skin, ready for the face layers to be drawn on top. No horns, no ears on this piece. On the top of the skull, between where the horns go, a SMALL TORN OPENING in the skin, like a little rip about one fifth of the head wide, with ragged edges and glowing orange-yellow inside: this is where his flame comes out.
2. NEAR HORN and FAR HORN: the two horns, each alone, with a flat base where they meet the skull.
3. NEAR EAR and FAR EAR: the two pointed ears, each alone, with a rounded base.
4. The same HEAD BASE again, but squashed: 15% shorter and 10% wider (for the landing squash), no horns, no ears, no face, with the same torn opening on top.
5. FLAME: his head flame alone, upright, orange and yellow with a black outline, as tall as the head base. Its bottom is narrow and ragged and has exactly the width and shape of the torn opening of piece 1, so that placed on it the flame grows OUT of the rip in the skull and is clearly part of him, not a separate fire floating on his head.

No scarf, no body. No shading gradients. Background: flat pure magenta #FF00FF everywhere outside the pieces. No text, no labels. Landscape 3:2.
```

### `viso`

```
Image 1 is our approved character, the little devil "Apprendista". Image 2 shows his approved facial expressions: copy their style exactly. Draw ONLY the face layers, as separate pieces for a 2D rig, on one sheet, in a neat grid, pieces separated by at least 40 pixels, all at the same scale, as big as they would be on the head of image 1 drawn 900 pixels tall:

Row 1, EYES: the near eye and the far eye as in image 1, yellow, each in two pieces: the EYE WHITE (the yellow eye shape with its black outline, empty, no pupil) and the PUPIL (the black pupil with its white highlight, alone). So four pieces.
Row 2, EYEBROWS: five pairs of black eyebrows, each pair side by side: calm, angry (down toward the nose), surprised (high and round), worried (up toward the middle), sly (one up, one down).
Row 3 and 4, MOUTHS: eight mouths in the same style, each alone, drawn on a cream patch the color of the muzzle so the edges blend: calm smile, big open laugh with tongue, angry clenched teeth, surprised small "o", sad, worried wavy line, sly half smile, shouting wide open.

No head, no face outline around the pieces. No shading gradients. Background: flat pure magenta #FF00FF everywhere outside the pieces. No text, no labels. Landscape 3:2.
```

## Criteri di accettazione

- [ ] stesso apprendista di R1: proporzioni, colori, contorno nero spesso; sfondo magenta pulito
- [ ] braccia e gambe intere, dritte, larghe uguali, senza segni al gomito e al ginocchio
- [ ] spalle e anche a cupola; busto con la pancia in un pezzo solo
- [ ] testa senza occhi, sopracciglia e bocca; corna e orecchie a parte
- [ ] in cima alla testa un piccolo squarcio acceso; la fiammella a parte, con la base larga come lo squarcio, così esce dalla testa e non galleggia sopra (Sergio, 13 nov)
- [ ] pezzi del viso nello stile di R2, staccati, nessuna scritta

---

## Decisione

Approvata da Sergio il 13 nov (scelta «Approvata»). Claude porta la scheda su `main`.

## Consegna di Codex

## Resoconto di Claude
