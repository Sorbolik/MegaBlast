# WB-012 · Vignette del tutorial: fogli modello e tavole

- **Stato:** APPROVATA solo la fase 1 (Claude, 2026-11-03); fase 2 PROPOSTA, aspetta le scelte di Sergio
- **Data:** 2026-11-03
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-012`

## Obiettivo

Sergio vuole togliere le righe sopra le teste nel tutorial: ogni cosa importante si spiega
con una vignetta a fumetto, prima di farla. Nel cortile della Forgia ti allena **Favilla**,
l'apprendista anziana; poi arriva **il Fabbro**, il maestro. Proposta completa (scelte
numerate, mockup, battute): https://claude.ai/artifact/JwGUbbN17jKuKKRSqooTSP .

Il rischio grande è che il personaggio cambi da un'immagine all'altra (è già successo con la
fiammella). Per questo:

1. **Fase 1**: un **foglio modello** per personaggio, nello stile del trio di WB-008: una
   figura intera e otto busti con le espressioni delle vignette. Sergio li approva. I ritratti
   delle vignette sono **ritagli** di questi fogli e non si rigenerano mai.
2. **Fase 2**: le **tavole** della storia (arrivo, il Fabbro, il rapimento), un riquadro per
   immagine, con i tre fogli approvati allegati. Il testo lo scrive il gioco: nelle immagini
   niente scritte.

I fogli della fase 1 servono qualunque interfaccia Sergio scelga, quindi Claude li approva
(si buttano via senza danni). La fase 2 aspetta le scelte 1, 6, 7 e 8 della proposta.

## Cosa teniamo e cosa scartiamo

| Teniamo | Perché |
|---|---|
| Lo stile del trio `13_trio.png`: cartoon, contorno nero spesso, colori pieni, tratteggio leggero da incisione nelle ombre | lo ha chiesto Sergio per le vignette |
| L'apprendista di `R1b` (tre quarti del gioco) con **la fiammella arancione** di `R1` | Sergio pensa di rimetterla in gioco (scelta 6 della proposta; se dice no, si toglie dal prompt prima della fase 2) |
| Il fazzoletto **blu** dell'apprendista | nelle illustrazioni il colore della squadra non serve; blu come in `R1b` e nel trio |
| Favilla B di `11_favilla_B.png`: fiamma bianco-azzurra con punte dorate, corna corte, occhi gialli con ciglia, camicia pergamena con maniche arrotolate, salopette e grembiule marroni, stivali, coda a cuore | è la Favilla scelta da Sergio il 1 nov (scelta 7a) |
| Il Fabbro B di `9_fabbro_B.png`, la figura a sinistra: corna lunghe brune all'indietro, baffoni bianchi, pancia-fornace con grata a cinque sbarre, comignolo sulla spalla che fuma, guantoni, grembiule di cuoio | è «B · La fornace», il preferito di Sergio (scelta 8) |

| Scartiamo | Perché |
|---|---|
| I dettagli dei personaggi del trio (Favilla con la gonnellina, Fabbro con corna ricce e senza guanti) | nel trio sono diversi dai fogli scelti: dal trio si prende solo lo stile |
| Generare ogni vignetta da zero | ogni immagine nuova cambia un po' il personaggio |
| Scritte, fumetti, numeri nelle immagini | il testo lo mette il gioco, così si cambia e si traduce |

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-009/riferimenti/R1_apprendista_concept.png` | concept dell'apprendista **con la fiammella**: si guarda solo la fiammella |
| R1b | `art/WB-009/riferimenti/R1b_apprendista_senza_fiammella.png` | l'apprendista standard: forme, proporzioni, colori |
| R2 | `art/WB-009/scelti/espressioni.png` | le espressioni scelte dell'apprendista |
| R3 | `art/WB-008/13_trio.png` | lo stile delle vignette |
| R4 | `art/WB-008/11_favilla_B.png` | Favilla B |
| R5 | `art/WB-008/9_fabbro_B.png` | il Fabbro B, la fornace (figura a sinistra) |
| R6 | `art/WB-012/scelti/apprendista.png` | il foglio dell'apprendista scelto in fase 1 (c'è solo dopo) |
| R7 | `art/WB-012/scelti/favilla.png` | il foglio di Favilla scelto in fase 1 (c'è solo dopo) |
| R8 | `art/WB-012/scelti/fabbro.png` | il foglio del Fabbro scelto in fase 1 (c'è solo dopo) |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto: il
primo è "image 1", il secondo "image 2" e così via. Sfondo **non** trasparente (eccezione ad
`AGENTS.md`): pergamena piena, perché i ritagli si fanno su quella.

| Fase | Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|---|
| 1 | `1_foglio_apprendista` | R1b, R1, R2, R3 | 1536×1536 (o 1024×1024) | 2 |
| 1 | `2_foglio_favilla` | R4, R3 | 1536×1536 (o 1024×1024) | 2 |
| 1 | `3_foglio_fabbro` | R5, R3 | 1536×1536 (o 1024×1024) | 2 |
| 2 | `4_arrivo_a` | R6, R7, R3 | 1536×1024 | 1 |
| 2 | `4_arrivo_b` | R6, R3 | 1024×1024 | 1 |
| 2 | `4_arrivo_c` | R7, R3 | 1024×1024 | 1 |
| 2 | `5_fabbro_a` | R8, R6, R3 | 1536×1024 | 1 |
| 2 | `5_fabbro_b` | R7, R6, R3 | 1024×1024 | 1 |
| 2 | `6_rapimento_a` | R7, R6, R3 | 1536×1024 | 1 |
| 2 | `6_rapimento_b` | R7, R3 | 1024×1024 | 1 |
| 2 | `6_rapimento_c` | R8, R6, R3 | 1536×1024 | 1 |

Codex esegue solo le righe della fase chiesta («esegui WB-012 fase 1» o «fase 2»). Se un
riferimento della fase non c'è, si ferma.

### `1_foglio_apprendista`

```
Image 1 is the main character of our game, a little blacksmith-apprentice imp (three-quarter view, the middle figure is the master reference). Image 2 is his original concept: look at it ONLY for the small orange flame on top of his head, between the horns. Image 3 shows his approved facial expressions. Image 4 shows the illustration style we want.

Draw a CHARACTER MODEL SHEET of this exact character, as a 3 by 3 grid of equal square cells on a plain flat parchment background (#F3E7CF), with a thin clear gap between cells and nothing else in the picture.
- Top-left cell: the full body, standing, three-quarter view facing right, relaxed, arms loose.
- The other eight cells: head-and-shoulders BUSTS, all the same size and framing (head and top of the chest, the neckerchief visible), all in three-quarter view facing right, with these expressions in reading order: 1) calm sly smile, 2) laughing with mouth open, 3) explaining: one hand raised with the index finger up, 4) surprised, wide eyes, small open mouth, 5) worried, brows up, 6) angry, teeth clenched, 7) proud and cocky, chin up, 8) sad, eyes down.

Keep EXACTLY his design from image 1 in every cell: small and stocky, big round head, two short bone-colored horns, pointed ears, big yellow eyes with black pupils, brick-red skin, parchment-colored belly and muzzle, four-fingered hands, bare three-toed feet, a long thin tail with an arrowhead tip, a BLUE neckerchief knotted at the neck. ADD the small orange flame of image 2 on top of his head, between the horns, the same in every cell. Same proportions, same colors, same face in all nine cells: only the expression changes.

Style as in image 4: cartoon illustration, thick black outline, flat cel colors, light engraving-like hatching only in the shadows. No background scenery, no props, no other characters. No text, numbers, labels, speech balloons or signatures.
```

### `2_foglio_favilla`

```
Image 1 is Favilla, a character of our game: a young she-devil, the senior blacksmith apprentice. The LEFT figure (front view, hands on hips) is the master reference. Image 2 shows the illustration style we want (Favilla also appears there, but her clothes there are NOT the reference: use the clothes of image 1).

Draw a CHARACTER MODEL SHEET of this exact character, as a 3 by 3 grid of equal square cells on a plain flat parchment background (#F3E7CF), with a thin clear gap between cells and nothing else in the picture.
- Top-left cell: the full body, standing, three-quarter view facing right, one hand on the hip.
- The other eight cells: head-and-shoulders BUSTS, all the same size and framing (the whole flame hair visible, head and top of the chest), all in three-quarter view facing right, with these expressions in reading order: 1) friendly confident smile, 2) laughing with mouth open, 3) explaining: one hand raised with the index finger up, 4) surprised, wide eyes, 5) worried, brows up, 6) angry, 7) proud and cocky, a wink, 8) scared, reaching out.

Keep EXACTLY her design from image 1 in every cell: red skin, a big flame for hair that is white in the middle and light blue at the edges with a few golden tips, two short bone-colored horns, pointed ears, big yellow eyes with lashes, small pink nose, a lighter muzzle; cream shirt with rolled-up sleeves, brown apron-overalls with brass buttons, brown boots, a thin tail with a heart-shaped tip. Same proportions, same colors, same face in all nine cells: only the expression changes. Her flame hair has the same shape and size in every cell.

Style as in image 2: cartoon illustration, thick black outline, flat cel colors, light engraving-like hatching only in the shadows. No background scenery, no props, no other characters. No text, numbers, labels, speech balloons or signatures.
```

### `3_foglio_fabbro`

```
Image 1 is the Blacksmith (il Fabbro), a character of our game: a huge old devil blacksmith with a furnace in his belly. The LEFT figure (front view, hammer on the shoulder) is the master reference. Image 2 shows the illustration style we want (a blacksmith also appears there, but his horns and hands there are NOT the reference: use image 1).

Draw a CHARACTER MODEL SHEET of this exact character, as a 3 by 3 grid of equal square cells on a plain flat parchment background (#F3E7CF), with a thin clear gap between cells and nothing else in the picture.
- Top-left cell: the full body, standing, three-quarter view facing LEFT, the big hammer resting on its head on the ground beside him.
- The other eight cells: head-and-shoulders BUSTS, all the same size and framing (horns, head, shoulders and the top of the furnace grate), all in three-quarter view facing LEFT, with these expressions in reading order: 1) stern, calm, 2) approving half smile under the moustache, 3) explaining: one gloved hand raised with the index finger up, 4) surprised, brows up, 5) worried, 6) angry, shouting, 7) proud, arms crossed, 8) grim and sad, the furnace glowing low.

Keep EXACTLY his design from image 1 in every cell: dark red skin, long brown horns sweeping back and up, big white moustache and bushy eyebrows, pointed ears, yellow eyes; a riveted iron chest-furnace with a barred grate of five bars showing orange fire, a smoking chimney on his shoulder, heavy dark gloves, leather apron, brass straps. Same proportions, same colors, same face in all nine cells: only the expression changes.

Style as in image 2: cartoon illustration, thick black outline, flat cel colors, light engraving-like hatching only in the shadows. No background scenery, no other characters. No text, numbers, labels, speech balloons or signatures.
```

### `4_arrivo_a`

```
Image 1 is the model sheet of the apprentice imp, image 2 the model sheet of Favilla, image 3 the illustration style. Copy both characters EXACTLY from their sheets (shapes, colors, flame, clothes, tail); do not redesign them.

A wide comic panel: the courtyard of a hellish forge at its gate, chains, anvils, glowing lava cracks, sparks in the air. On the left the apprentice imp has just arrived, a small bundle tied to a stick over his shoulder, looking up. On the right Favilla is landing in front of him after jumping down from a balcony, knees bent, one hand on the ground, grinning, her white-blue flame hair streaming up. Leave the top-right quarter of the picture calm (dark wall) for a speech balloon the game adds. Style of image 3. No text, letters, speech balloons or signatures.
```

### `4_arrivo_b`

```
Image 1 is the model sheet of the apprentice imp, image 2 the illustration style. Copy him EXACTLY from his sheet.

A square comic close-up of the apprentice imp, head and shoulders, three-quarter view facing right, indignant: puffed cheeks, frowning, a fist raised. Dark forge background with sparks, slightly blurred. Leave the lower third calm for a speech balloon the game adds. Style of image 2. No text, letters, speech balloons or signatures.
```

### `4_arrivo_c`

```
Image 1 is the model sheet of Favilla, image 2 the illustration style. Copy her EXACTLY from her sheet.

A square comic close-up of Favilla, head and shoulders, three-quarter view facing left, smug and amused, pointing with her thumb over her shoulder toward the forge. Dark forge background with sparks, slightly blurred. Leave the lower third calm for a speech balloon the game adds. Style of image 2. No text, letters, speech balloons or signatures.
```

### `5_fabbro_a`

```
Image 1 is the model sheet of the Blacksmith, image 2 the model sheet of the apprentice imp, image 3 the illustration style. Copy both EXACTLY from their sheets.

A wide comic panel seen from low, inside the forge: the huge Blacksmith towers on the left, arms crossed, the furnace in his belly glowing bright, smoke from his shoulder chimney, looking down sternly. The tiny apprentice imp stands on the right, looking up at him, a bit intimidated but trying to look brave. Leave the top-right quarter calm for a speech balloon the game adds. Style of image 3. No text, letters, speech balloons or signatures.
```

### `5_fabbro_b`

```
Image 1 is the model sheet of Favilla, image 2 the model sheet of the apprentice imp, image 3 the illustration style. Copy both EXACTLY from their sheets.

A square comic panel: Favilla leans toward the apprentice imp and whispers behind her hand with a mischievous grin; he listens, eyes turned toward her. Dark forge background, blurred. Leave the top third calm for a speech balloon the game adds. Style of image 3. No text, letters, speech balloons or signatures.
```

### `6_rapimento_a`

```
Image 1 is the model sheet of Favilla, image 2 the model sheet of the apprentice imp, image 3 the illustration style. Copy both EXACTLY from their sheets.

A wide dramatic comic panel in the forge arena: the stone floor has cracked open between the two characters, cold blue-white light and frost pour out of the crack. A gigantic claw made of ice comes out of the crack and grabs Favilla around the waist; she screams and reaches out. On the left the apprentice imp runs toward her, arm stretched out. The warm orange of the forge is turning cold blue around the crack. Style of image 3. No text, letters, speech balloons or signatures.
```

### `6_rapimento_b`

```
Image 1 is the model sheet of Favilla, image 2 the illustration style. Copy her EXACTLY from her sheet.

A square comic panel seen from above, looking down into a deep dark icy chasm: far below, small, Favilla is being dragged down by the ice claw, her white-blue flame hair trailing up like a comet tail, the only light in the darkness. Frost on the edges of the picture. Style of image 2. No text, letters, speech balloons or signatures.
```

### `6_rapimento_c`

```
Image 1 is the model sheet of the Blacksmith, image 2 the model sheet of the apprentice imp, image 3 the illustration style. Copy both EXACTLY from their sheets.

A wide quiet comic panel: the Blacksmith and the apprentice imp kneel at the edge of a jagged hole in the forge floor, looking down into it. Frost on the Blacksmith's moustache and gloves, the furnace in his belly glowing low and dim; the apprentice clenches his fists, determined. Cold blue light rises from the hole, the forge around is dark. Leave the top quarter calm for a speech balloon the game adds. Style of image 3. No text, letters, speech balloons or signatures.
```

## Criteri di accettazione

- [ ] nessuna scritta, numero, fumetto o firma
- [ ] fase 1: griglia 3 × 3 pulita, celle uguali, sfondo pergamena piatto senza oggetti
- [ ] fase 1: lo stesso personaggio in tutte e nove le celle (proporzioni, colori, faccia); cambia solo l'espressione
- [ ] apprendista: due corna corte color osso, orecchie a punta, occhi gialli, pelle rosso mattone con pancia e muso pergamena, fazzoletto **blu**, coda sottile a freccia, piedi a tre dita, **fiammella arancione** fra le corna (se Sergio dice no alla scelta 6, la fiammella si toglie prima della fase 2)
- [ ] Favilla: fiamma bianco-azzurra con punte dorate sempre della stessa forma, corna corte, ciglia, camicia pergamena, salopette e grembiule marroni, stivali, coda a cuore
- [ ] Fabbro: corna lunghe brune all'indietro, baffoni bianchi, grata a **cinque** sbarre col fuoco, comignolo sulla spalla, guantoni scuri, grembiule di cuoio
- [ ] fase 2: i personaggi uguali ai fogli scelti; se uno cambia (corna, fiamma, vestiti, coda) l'immagine si scarta
- [ ] stile del trio: contorno nero spesso, colori pieni, tratteggio leggero solo nelle ombre

## Dopo le immagini

- Fase 1: Sergio sceglie una variante per foglio; Claude le salva in `art/WB-012/scelti/`
  (`apprendista.png`, `favilla.png`, `fabbro.png`) e taglia i busti in ritratti quadrati.
- Fase 2: Claude guarda ogni riquadro contro la lista, scarta quelli con difetti, e li monta
  nelle tavole del gioco.

---

## Decisione

Fase 1 approvata da Claude il 2026-11-03 (reversibile: serve a qualunque interfaccia).
Fase 2 aspetta le scelte di Sergio sulla proposta.

## Consegna di Codex

## Resoconto di Claude
