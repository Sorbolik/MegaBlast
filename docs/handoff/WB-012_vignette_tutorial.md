# WB-012 · Vignette del tutorial: fogli modello e tavole

- **Stato:** fase 1 IMPLEMENTATA (fogli scelti in `art/WB-012/scelti/`); fase 2 APPROVATA (Sergio, 2026-11-03)
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
(si buttano via senza danni). Il 3 nov Sergio ha detto sì a tutte e dieci le scelte della proposta: la fase 2 si può eseguire.

## Cosa teniamo e cosa scartiamo

| Teniamo | Perché |
|---|---|
| Lo stile del trio `13_trio.png`: cartoon, contorno nero spesso, colori pieni, tratteggio leggero da incisione nelle ombre | lo ha chiesto Sergio per le vignette |
| L'apprendista di `R1b` (tre quarti del gioco), in due fogli: **senza fiammella** (lo standard di oggi) e **con la fiammella arancione** di `R1` | Sergio pensa di rimetterla in gioco, ma è la scelta 6 ancora aperta: i ritratti si ritagliano dal foglio, quindi servono tutti e due e Sergio tiene quello della sua scelta |
| Il fazzoletto **blu** dell'apprendista | nelle illustrazioni il colore della squadra non serve; blu come in `R1b` e nel trio |
| Favilla B di `11_favilla_B.png`: fiamma bianco-azzurra con punte dorate, corna corte, occhi gialli con ciglia, camicia e salopette color pergamena, bretelle di cuoio marrone coi bottoni d'ottone, grembiulino marrone, stivali marroni, coda a cuore | è la Favilla scelta da Sergio il 1 nov (scelta 7a) |
| Il Fabbro B di `9_fabbro_B.png`, la figura a sinistra: corna lunghe brune a costole che vanno di lato e in su con le punte verso dentro, baffoni bianchi, pancia-fornace con grata a cinque sbarre, comignolo sulla spalla che fuma, guantoni, grembiule di cuoio | è «B · La fornace», il preferito di Sergio (scelta 8) |

| Scartiamo | Perché |
|---|---|
| I dettagli dei personaggi del trio (Favilla con la gonnellina, Fabbro con corna ricce e senza guanti) | nel trio sono diversi dai fogli scelti: dal trio si prende solo lo stile |
| Generare ogni vignetta da zero | ogni immagine nuova cambia un po' il personaggio |
| Scritte, fumetti, numeri nelle immagini | il testo lo mette il gioco, così si cambia e si traduce |

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-009/riferimenti/R1_apprendista_concept.png` | concept dell'apprendista **con la fiammella**: si allega solo per `1_foglio_apprendista_fiamma`, e si guarda solo la fiammella |
| R1b | `art/WB-009/riferimenti/R1b_apprendista_senza_fiammella.png` | l'apprendista standard: forme, proporzioni, colori |
| R2 | `art/WB-009/scelti/espressioni.png` | le espressioni scelte dell'apprendista |
| R3 | `art/WB-008/13_trio.png` | lo stile delle vignette |
| R4 | `art/WB-008/11_favilla_B.png` | Favilla B |
| R5 | `art/WB-008/9_fabbro_B.png` | il Fabbro B, la fornace (figura a sinistra) |
| R6 | `art/WB-012/scelti/apprendista.png` | il foglio dell'apprendista scelto in fase 1, con o senza fiammella secondo la scelta 6 (c'è solo dopo) |
| R7 | `art/WB-012/scelti/favilla.png` | il foglio di Favilla scelto in fase 1 (c'è solo dopo) |
| R8 | `art/WB-012/scelti/fabbro.png` | il foglio del Fabbro scelto in fase 1 (c'è solo dopo) |
| R9 | `art/WB-012/riferimenti/R9_favilla_figura.png` | Favilla a figura intera ritagliata da R7: la **coda a cuore** (fase 2b) |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto: il
primo è "image 1", il secondo "image 2" e così via. Sfondo **non** trasparente (eccezione ad
`AGENTS.md`): pergamena piena, perché i ritagli si fanno su quella.

| Fase | Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|---|
| 1 | `1_foglio_apprendista` | R1b, R2, R3 | 1536×1536 (o 1024×1024) | 1 |
| 1 | `1_foglio_apprendista_fiamma` | R1b, R2, R3, R1 | 1536×1536 (o 1024×1024) | 1 |
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
| 2b | `4_arrivo_a` | R6, R7, R9, R3 | 1536×1024 | 2 |
| 2b | `5_fabbro_b` | R7, R9, R6, R3 | 1024×1024 | 2 |
| 2c | `5_fabbro_c` | R7, R6, R3 | 1024×1024 | 2 |

Codex esegue solo le righe della fase chiesta («esegui WB-012 fase 1», «fase 2», «fase 2b» o «fase 2c»). Se un
riferimento della fase non c'è, si ferma.

### `1_foglio_apprendista`

Lo standard di oggi, senza fiammella.

```
Image 1 is the main character of our game, a little blacksmith-apprentice imp, in three-quarter view facing right: it is the master reference. Image 2 shows his approved facial expressions. Image 3 shows the illustration style we want.

Draw a CHARACTER MODEL SHEET of this exact character, as a 3 by 3 grid of equal square cells on a plain flat parchment background (#F3E7CF), with a thin clear gap between cells and nothing else in the picture.
- Top-left cell: the full body, standing, three-quarter view facing right, relaxed, arms loose.
- The other eight cells: head-and-shoulders BUSTS, all the same size and framing (head and top of the chest, the neckerchief visible), all in three-quarter view facing right, with these expressions in reading order: 1) calm sly smile, 2) laughing with mouth open, 3) explaining: one hand raised with the index finger up, 4) surprised, wide eyes, small open mouth, 5) worried, brows up, 6) angry, teeth clenched, 7) proud and cocky, chin up, 8) sad, eyes down.

Keep EXACTLY his design from image 1 in every cell: small and stocky, big round head, two short bone-colored horns, pointed ears, big yellow eyes with black pupils, brick-red skin, parchment-colored belly and muzzle, four-fingered hands, bare three-toed feet, a long thin tail with an arrowhead tip, a BLUE neckerchief knotted at the neck. He has NO flame on his head and no wings. Same proportions, same colors, same face in all nine cells: only the expression changes.

Use ONLY these colors: outline and pupils black #000000; skin #B8432A, skin shadow #8E2F1C; belly and muzzle #F1DFB0, their shadow #D6BC86; horns and toenails #EFE3C8, their shadow #C9B48E; eyes #F2C45A with a small white #FFFFFF highlight; inside of mouth #5A1A10, teeth white #FFFFFF, tongue #E0605A; neckerchief blue #6AA8C4, its shadow #487088.

Style as in image 3: cartoon illustration, thick black outline, flat cel colors, light engraving-like hatching only in the shadows. No background scenery, no props, no other characters. No text, numbers, labels, speech balloons or signatures.
```

### `1_foglio_apprendista_fiamma`

Lo stesso foglio con la fiammella, per la scelta 6.

```
Image 1 is the main character of our game, a little blacksmith-apprentice imp, in three-quarter view facing right: it is the master reference. Image 2 shows his approved facial expressions. Image 3 shows the illustration style we want. Image 4 is his original concept: look at it ONLY for the small orange flame on top of his head, between the horns.

Draw a CHARACTER MODEL SHEET of this exact character, as a 3 by 3 grid of equal square cells on a plain flat parchment background (#F3E7CF), with a thin clear gap between cells and nothing else in the picture.
- Top-left cell: the full body, standing, three-quarter view facing right, relaxed, arms loose.
- The other eight cells: head-and-shoulders BUSTS, all the same size and framing (head and top of the chest, the neckerchief visible), all in three-quarter view facing right, with these expressions in reading order: 1) calm sly smile, 2) laughing with mouth open, 3) explaining: one hand raised with the index finger up, 4) surprised, wide eyes, small open mouth, 5) worried, brows up, 6) angry, teeth clenched, 7) proud and cocky, chin up, 8) sad, eyes down.

Keep EXACTLY his design from image 1 in every cell: small and stocky, big round head, two short bone-colored horns, pointed ears, big yellow eyes with black pupils, brick-red skin, parchment-colored belly and muzzle, four-fingered hands, bare three-toed feet, a long thin tail with an arrowhead tip, a BLUE neckerchief knotted at the neck. ADD the small orange flame of image 4 on top of his head, between the horns, the same shape and size in every cell. Same proportions, same colors, same face in all nine cells: only the expression changes.

Use ONLY these colors: outline and pupils black #000000; skin #B8432A, skin shadow #8E2F1C; belly and muzzle #F1DFB0, their shadow #D6BC86; horns and toenails #EFE3C8, their shadow #C9B48E; eyes #F2C45A with a small white #FFFFFF highlight; inside of mouth #5A1A10, teeth white #FFFFFF, tongue #E0605A; neckerchief blue #6AA8C4, its shadow #487088.

Style as in image 3: cartoon illustration, thick black outline, flat cel colors, light engraving-like hatching only in the shadows. No background scenery, no props, no other characters. No text, numbers, labels, speech balloons or signatures.
```

### `2_foglio_favilla`

```
Image 1 is Favilla, a character of our game: a young she-devil, the senior blacksmith apprentice. The LEFT figure (front view, hands on hips) is the master reference. Image 2 shows the illustration style we want (Favilla also appears there, but her clothes there are NOT the reference: use the clothes of image 1).

Draw a CHARACTER MODEL SHEET of this exact character, as a 3 by 3 grid of equal square cells on a plain flat parchment background (#F3E7CF), with a thin clear gap between cells and nothing else in the picture.
- Top-left cell: the full body, standing, three-quarter view facing right, one hand on the hip.
- The other eight cells: head-and-shoulders BUSTS, all the same size and framing (the whole flame hair visible, head and top of the chest), all in three-quarter view facing right, with these expressions in reading order: 1) friendly confident smile, 2) laughing with mouth open, 3) explaining: one hand raised with the index finger up, 4) surprised, wide eyes, 5) worried, brows up, 6) angry, 7) proud and cocky, a wink, 8) scared, reaching out.

Keep EXACTLY her design from image 1 in every cell: red skin, a big flame for hair that is white in the middle and light blue at the edges with a few golden tips, two short bone-colored horns, pointed ears, big yellow eyes with lashes, small pink nose, a lighter muzzle; parchment shirt with rolled-up sleeves and matching parchment bib overalls, brown leather suspenders with brass buttons, small brown leather apron, brown boots, a thin tail with a heart-shaped tip. Colors: skin #B8432A, muzzle #F1DFB0, flame hair white #FFFFFF and light blue #BFE9FF with golden tips #F2C45A, eyes #F2C45A, black #000000 outline. Same proportions, same colors, same face in all nine cells: only the expression changes. Her flame hair has the same shape and size in every cell.

Style as in image 2: cartoon illustration, thick black outline, flat cel colors, light engraving-like hatching only in the shadows. No background scenery, no props, no other characters. No text, numbers, labels, speech balloons or signatures.
```

### `3_foglio_fabbro`

```
Image 1 is the Blacksmith (il Fabbro), a character of our game: a huge old devil blacksmith with a furnace in his belly. The LEFT figure (front view, hammer on the shoulder) is the master reference. Image 2 shows the illustration style we want (a blacksmith also appears there, but his horns and hands there are NOT the reference: use image 1).

Draw a CHARACTER MODEL SHEET of this exact character, as a 3 by 3 grid of equal square cells on a plain flat parchment background (#F3E7CF), with a thin clear gap between cells and nothing else in the picture.
- Top-left cell: the full body, standing, three-quarter view facing LEFT, the big hammer resting on its head on the ground beside him.
- The other eight cells: head-and-shoulders BUSTS, all the same size and framing (horns, head, shoulders and the top of the furnace grate), all in three-quarter view facing LEFT, with these expressions in reading order: 1) stern, calm, 2) approving half smile under the moustache, 3) explaining: one gloved hand raised with the index finger up, 4) surprised, brows up, 5) worried, 6) angry, shouting, 7) proud, arms crossed, 8) grim and sad, the furnace glowing low.

Keep EXACTLY his design from image 1 in every cell: dark red skin, long ridged brown horns curving out sideways and up with the tips turning inward, big white moustache and bushy eyebrows, pointed ears, yellow eyes; a riveted iron chest-furnace with a barred grate of five bars showing orange fire, a smoking chimney on his shoulder, heavy dark gloves, leather apron, brass straps. Same proportions, same colors, same face in all nine cells: only the expression changes.

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

### Fase 2b · `4_arrivo_a` (rifatta)

In fase 2 la coda di Favilla è uscita a freccia in tutti i tentativi. Qui c'è in più R9, la sua
figura intera, e la coda si dice due volte. Due varianti; se la coda resta a freccia, scartala
come prima.

```
Image 1 is the model sheet of the apprentice imp, image 2 the model sheet of Favilla, image 3 Favilla's full figure, image 4 the illustration style. Copy both characters EXACTLY from their sheets (shapes, colors, flame, clothes); do not redesign them.

IMPORTANT, the tails: the apprentice's tail ends in a small pointed arrow tip; Favilla's tail ends in a HEART shape, exactly as in image 3 (a rounded heart, two lobes, NOT an arrow, NOT a spade). Show Favilla's tail clearly, curling behind her.

A wide comic panel: the courtyard of a hellish forge at its gate, chains, anvils, glowing lava cracks, sparks in the air. On the left the apprentice imp has just arrived, a small bundle tied to a stick over his shoulder, looking up. On the right Favilla is landing in front of him after jumping down from a balcony, knees bent, one hand on the ground, grinning, her white-blue flame hair streaming up. Leave the top-right quarter of the picture calm (dark wall) for a speech balloon the game adds. Style of image 4. No text, letters, speech balloons or signatures.
```

### Fase 2b · `5_fabbro_b` (rifatta)

In fase 2: coda a freccia e un martello in mano all'apprendista. Due varianti.

```
Image 1 is the model sheet of Favilla, image 2 Favilla's full figure, image 3 the model sheet of the apprentice imp, image 4 the illustration style. Copy both EXACTLY from their sheets.

IMPORTANT, the tails: Favilla's tail ends in a HEART shape, exactly as in image 2 (a rounded heart, two lobes, NOT an arrow, NOT a spade); the apprentice's tail ends in a small pointed arrow tip. Both hands of the apprentice are EMPTY: no hammer, no tool, nothing in his hands.

A square comic panel: Favilla leans toward the apprentice imp and whispers behind her hand with a mischievous grin; he listens, eyes turned toward her, hands empty at his sides. Dark forge background, blurred. Leave the top third calm for a speech balloon the game adds. Style of image 4. No text, letters, speech balloons or signatures.
```

### Fase 2c · `5_fabbro_c` (il bisbiglio, di nuovo)

In fase 2b il cuore della coda è uscito capovolto rispetto al modello: nel modello la coda entra
nell'incavo fra i lobi e la punta guarda in fuori. Era colpa del prompt, che insisteva troppo
sulla coda. Qui torna il prompt della fase 2, con le mani vuote e la coda detta in una riga
sola, senza enfasi. Due varianti. Non scartare per la coda se somiglia al foglio: decide Claude.

```
Image 1 is the model sheet of Favilla, image 2 the model sheet of the apprentice imp, image 3 the illustration style. Copy both EXACTLY from their sheets, tails included.

A square comic panel: Favilla leans toward the apprentice imp and whispers behind her hand with a mischievous grin; he listens, eyes turned toward her, both hands empty at his sides. Dark forge background, blurred. Leave the top third calm for a speech balloon the game adds. Style of image 3. No text, letters, speech balloons or signatures.
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
- [ ] apprendista: due corna corte color osso, orecchie a punta, occhi gialli, pelle rosso mattone con pancia e muso pergamena, fazzoletto **blu**, coda sottile a freccia, piedi a tre dita; i colori della tavolozza di WB-009; nessuna fiammella nel foglio standard, **fiammella arancione** fra le corna, uguale in ogni cella, nel foglio `_fiamma`
- [ ] Favilla: fiamma bianco-azzurra con punte dorate sempre della stessa forma, corna corte, ciglia, camicia e salopette pergamena, bretelle marroni coi bottoni d'ottone, grembiulino marrone, stivali, coda a cuore
- [ ] Fabbro: corna lunghe brune di lato e in su con le punte verso dentro, baffoni bianchi, grata a **cinque** sbarre col fuoco, comignolo sulla spalla, guantoni scuri, grembiule di cuoio
- [ ] fase 2: i personaggi uguali ai fogli scelti; se uno cambia (corna, fiamma, vestiti, coda) l'immagine si scarta
- [ ] stile del trio: contorno nero spesso, colori pieni, tratteggio leggero solo nelle ombre

## Dopo le immagini

- Fase 1: Sergio sceglie una variante per foglio (per l'apprendista, con o senza fiammella: è la scelta 6); Claude le salva in `art/WB-012/scelti/`
  (`apprendista.png`, `favilla.png`, `fabbro.png`) e taglia i busti in ritratti quadrati.
- Fase 2: Claude guarda ogni riquadro contro la lista, scarta quelli con difetti, e li monta
  nelle tavole del gioco.

---

## Decisione

Fase 1 approvata da Claude il 2026-11-03 (reversibile: serve a qualunque interfaccia).
Fase 2 approvata da Sergio il 2026-11-03 («sì a tutte»): apprendista con la fiammella, Favilla con salopette e stivali («quella con le scarpe»), Fabbro B.
Fase 2b (le due scene scartate, rifatte con la coda a cuore detta meglio) approvata da Claude il 2026-11-04: è la stessa richiesta della fase 2, con un riferimento in più.
Fase 2c (solo il bisbiglio, prompt della fase 2 con le mani vuote) approvata da Claude il 2026-11-04 dopo la nota di Sergio: non far concentrare il generatore sulla coda.

## Consegna di Codex


2026-11-03 · **Fase 1 generata**, dal `main` aggiornato al commit `726b776`, sul ramo `design/WB-012`. Solo le righe di fase 1; nessuna tavola di fase 2, nessun ritaglio o integrazione nel gioco.

### File

In `art/WB-012/`, sei PNG e sei `.txt` con prompt integrale e riferimenti nell'ordine richiesto:

| File | Misura effettiva | Tentativi |
|---|---|---:|
| `1_foglio_apprendista.png` | 1254×1254 | 1 |
| `1_foglio_apprendista_fiamma.png` | 1254×1254 | 1 |
| `2_foglio_favilla_1.png` | 1219×1290 | 1 |
| `2_foglio_favilla_2.png` | 1199×1312 | 1 |
| `3_foglio_fabbro_1.png` | 1218×1291 | 1 |
| `3_foglio_fabbro_2.png` | 1216×1293 | 2 |

### Controlli e problemi

- Eseguiti i quattro prompt esattamente come scritti, ripetuti per le due varianti richieste di Favilla e Fabbro; riferimenti originali allegati in ordine. Sfondo opaco pergamena, come richiesto.
- Guardata ogni generazione: nove celle, figura intera in alto a sinistra e otto busti, ordine delle espressioni, nessuna scritta/fumetto/firma, fazzoletto blu dell'apprendista, assenza della fiamma nel foglio standard e presenza arancione nel foglio `_fiamma`, abiti di Favilla, coda a cuore, guanti/comignolo/fornace del Fabbro.
- Scartato il primo tentativo della seconda variante del Fabbro: aveva un martello aggiuntivo sopra la testa. Il secondo elimina il difetto; è quello consegnato.
- **Dimensioni non conformi:** il generatore ha restituito le misure native riportate sopra, anziché 1536×1536 o 1024×1024. Favilla e Fabbro non sono perfettamente quadrati e le celle non sono quadrati esatti. Consegnati gli originali senza ridimensionarli o deformarli e senza cambiare i prompt.
- **Uniformità da rivedere:** forma della fiamma, corna e inquadratura variano leggermente fra i busti. Il tratteggio è più presente di quello leggero richiesto. Lo sfondo presenta una lieve variazione tonale anziché un colore piatto certificato #F3E7CF; la tavolozza non è verificata al pixel.
- Favilla: nella prima variante l'occhiolino della posa fiera non è netto; la seconda lo rappresenta chiaramente. La silhouette della fiamma non è identica in tutte le celle.
- Fabbro: corna e orientamento non sono una copia geometrica esatta del riferimento. Il numero di sbarre visibili varia con inquadratura, bordo e braccia incrociate: non certificata la grata identica a cinque sbarre in ogni cella. Nella posa fiera le braccia coprono parte della fornace, nella posa triste il fuoco è attenuato.
- Nessun elemento appare tagliato accidentalmente sul bordo esterno; i busti sono tagliati al torace come previsto. Verificati apertura e integrità dei sei PNG e corrispondenza testuale dei prompt con la scheda.
- Non verificati: ritaglio automatico, resa nel gioco e approvazione dei modelli da parte di Sergio. I criteri di accettazione restano non spuntati per la revisione; non si dichiarano tutti soddisfatti.
- La variante con fiammella è solo la proposta espressamente prevista qui per la scelta 6: non modifica lo standard senza fiammella deciso il 2 novembre.


### Fase 2 · Consegna di Codex

Eseguita la fase 2 approvata sulla scheda di `main` al commit `6d4b94f`, conservando la consegna della fase 1 e il resoconto di Claude. Usati solo i prompt delle otto righe di fase 2, senza modifiche, con i fogli scelti R6/R7/R8 e R3 nell'ordine indicato.

Otto immagini generate: **sei da revisione e due scartate**. Gli scarti sono conservati soltanto in `art/WB-012/scartati/fase2/`, non fra i file proposti per l'integrazione. Ogni PNG ha accanto il `.txt` con prompt e riferimenti.

| File relativo ad `art/WB-012/` | Misura effettiva | Tentativi completati | Esito |
|---|---|---:|---|
| `scartati/fase2/4_arrivo_a.png` | 1672×941 | 3 | SCARTATA |
| `4_arrivo_b.png` | 1254×1254 | 1 | da revisione |
| `4_arrivo_c.png` | 1254×1254 | 2 | da revisione |
| `5_fabbro_a.png` | 1672×941 | 1 | da revisione |
| `scartati/fase2/5_fabbro_b.png` | 1254×1254 | 3 | SCARTATA |
| `6_rapimento_a.png` | 1536×1024 | 1 | da revisione |
| `6_rapimento_b.png` | 1254×1254 | 3 | da revisione |
| `6_rapimento_c.png` | 1536×1024 | 1 | da revisione |

#### Controlli ed esiti

- Guardata ogni immagine generata e confrontata con i fogli scelti. Nessuna scritta, lettera, fumetto o firma visibile. Controllati fiamme, corna, fazzoletto, abiti, code, guanti, comignolo, pose e spazio per il testo. Nessun ritocco, specchiatura, ridimensionamento o integrazione nel gioco.
- **4_arrivo_a SCARTATA:** in tutti e tre i tentativi Favilla ha la coda a freccia invece che a cuore. Conservato il terzo solo come testimonianza del problema; manca una scena di arrivo conforme. L'arrivo, l'atterraggio, gli abiti e il muro scuro in alto a destra sono presenti.
- **4_arrivo_b:** apprendista indignato, pugno alzato, fazzoletto blu e fiammella arancione. Lo spazio calmo in basso è più vicino a un quarto che al terzo richiesto; da verificare col testo effettivo.
- **4_arrivo_c:** scartato il primo tentativo perché guardava a destra; il secondo guarda a sinistra e indica la forgia col pollice. Cornice inferiore calma presente; la fiamma ha una silhouette non identica al modello.
- **5_fabbro_a:** Fabbro grande a sinistra e apprendista piccolo a destra, fornace accesa, braccia incrociate, spazio scuro in alto a destra. La forma delle corna e la fornace non sono copie geometriche esatte; verificare nella revisione il numero delle sbarre e le parti dei guanti nascoste dalle braccia.
- **5_fabbro_b SCARTATA:** in tutti e tre i tentativi Favilla ha la coda a freccia invece che a cuore. Compare inoltre un martello in mano all'apprendista non richiesto dalla scena. Conservato il terzo soltanto come scarto; manca una scena del bisbiglio conforme.
- **6_rapimento_a:** presa di ghiaccio intorno alla vita, Favilla con coda a cuore, salopette e stivali, apprendista che corre da sinistra. Il passaggio da arancione a blu è leggibile; non certificata l'identità esatta delle proporzioni rispetto ai modelli.
- **6_rapimento_b:** primi due tentativi con punta della coda non conforme; scelto il terzo, con coda a cuore. Vista nel baratro, ghiaccio ai bordi e fiamma a scia presenti. La presa si sposta verso la gamba/stivale rispetto alla presa alla vita della scena precedente: continuità da rivedere.
- **6_rapimento_c:** entrambi inginocchiati al bordo, pugni dell'apprendista serrati, brina su baffi e guanti, fornace attenuata, luce blu e spazio calmo in alto presenti. Forma delle corna del Fabbro e volto variano rispetto al foglio: da revisione, non dichiarata identità esatta.
- **Misure non tutte conformi:** salvati gli originali nelle dimensioni native della tabella. I primi tre panoramici e i quadrati non rispettano esattamente 1536×1024 / 1024×1024. Nessuna deformazione per forzare le misure.
- Il paragrafo generale della scheda indica pergamena, ma i prompt specifici della fase 2 chiedono forgia e baratro: eseguiti esattamente quei prompt, con sfondi dipinti opachi. Segnalata l'incoerenza senza modificare la scheda altrui.
- Non verificati: impaginazione coi fumetti effettivi, leggibilità su telefono, continuità nel montaggio e resa nel gioco. I criteri restano non spuntati. I sei risultati da revisione non equivalgono a un'approvazione finale; i due scarti non vanno integrati.
- Una chiamata per `6_rapimento_b` è stata interrotta senza produrre un file; non conteggiata fra i tre tentativi completati.

### Fase 2b · Consegna di Codex

2026-11-04 · Eseguita la fase 2b approvata, da `main` aggiornato al commit `9121389`, sul ramo `design/WB-012`. Usato il generatore integrato imagegen, con i due prompt integrali invariati e i quattro riferimenti allegati nell'ordine della tabella. Due varianti per scena; nessuna modifica alle immagini precedenti.

| File in `art/WB-012/` | Misura effettiva | Tentativi | Esito |
|---|---|---:|---|
| `4_arrivo_a_1.png` e `4_arrivo_a_1.txt` | 1672×941 | 1 | da revisione |
| `4_arrivo_a_2.png` e `4_arrivo_a_2.txt` | 1672×941 | 1 | da revisione |
| `5_fabbro_b_1.png` e `5_fabbro_b_1.txt` | 1254×1254 | 1 | da revisione |
| `5_fabbro_b_2.png` e `5_fabbro_b_2.txt` | 1254×1254 | 1 | da revisione |

- Guardate tutte e quattro le generazioni prima del salvataggio: Favilla ha una punta della coda a cuore con due lobi arrotondati, l'apprendista una punta a freccia. Nelle scene del bisbiglio entrambe le mani dell'apprendista sono visibili, vuote e ai fianchi; nessun martello o utensile.
- Controllati: nessuna scritta, fumetto o firma visibile; contorni neri, corna, fazzoletto blu, fiammella arancione, fiamma bianco-azzurra con punte dorate, abiti pergamena, grembiulino e stivali di Favilla. Nessun pezzo accidentalmente tagliato sul bordo o giuntura evidente. Nell'arrivo: fagotto, atterraggio con ginocchia piegate e mano a terra, coda visibile dietro Favilla, muro scuro in alto a destra. Nel bisbiglio: mano alla bocca, sorriso malizioso, sguardo dell'apprendista verso Favilla e spazio calmo superiore.
- Nessuna rigenerazione necessaria. Conservati gli originali opachi, senza ritocchi, ritagli o ridimensionamenti. Gli sfondi della forgia seguono i prompt e il chiarimento di Claude nel resoconto.
- **Misure non conformi:** il generatore restituisce 1672×941 anziché 1536×1024 per l'arrivo e 1254×1254 anziché 1024×1024 per il bisbiglio. File lasciati nelle dimensioni native.
- Proporzioni, volto e silhouette della fiamma presentano le variazioni del disegno generativo: non certificata una copia geometrica esatta dei modelli, né la tavolozza al pixel. Il tratteggio dello scenario è più ricco di quello leggero richiesto nelle ombre. La decisione generale del 2 novembre toglie la fiammella dal gioco; qui si segue la scelta successiva del 3 novembre, esplicitamente approvata per le vignette.
- Verificati intestazioni PNG, dimensioni e corrispondenza testuale dei prompt salvati con quelli della fase 2b. Non verificati montaggio, fumetti effettivi, resa su telefono o nel gioco. Criteri lasciati non spuntati per la revisione di Claude e Sergio.

## Resoconto di Claude

Fase 1 (2026-11-03). Guardati i sei fogli di Codex (518c3c2): tutti tengono il personaggio
uguale da una cella all'altra, nessun difetto che obbliga a rigenerare.

| Scelto | File | Perché |
|---|---|---|
| apprendista | `scelti/apprendista.png` = `1_foglio_apprendista_fiamma.png` | Sergio: sì alla fiammella (scelta 6) |
| Favilla | `scelti/favilla.png` = `2_foglio_favilla_2.png` | fiamma più costante, occhiolino netto (nella 1 non si capisce) |
| Fabbro | `scelti/fabbro.png` = `3_foglio_fabbro_2.png` | grata, guanti e comignolo come R5, fornace spenta nella posa triste |

Da sistemare quando c'è da rigenerare (solo quel busto): nell'apprendista «preoccupato» e
«triste» si somigliano; nel Fabbro «serio» e «approva» quasi uguali. Celle non esattamente
quadrate (misure native del generatore): per i ritagli non conta. Colori non misurati al pixel
(servono per gli SVG, non per le vignette). I ritratti si ritagliano nella PR del codice.

Fase 2 (2026-11-04). Guardate le sei tavole di Codex (39f3496) e le due scartate. Le sei
tengono i personaggi; si montano nella PR della storia. Da tenere d'occhio al montaggio:
`6_rapimento_b` prende Favilla per lo stivale e non per la vita come `6_rapimento_a` (si legge
come lo stesso artiglio che la trascina giù: va bene); in `4_arrivo_b` lo spazio calmo è un
quarto, il fumetto sarà più basso. D'accordo con gli scarti di Codex: in `4_arrivo_a` la coda
di Favilla finisce a freccia, in `5_fabbro_b` anche, più un martello non chiesto. Si rifanno
nella fase 2b, con R9 (la sua figura intera) e la coda detta due volte. L'incoerenza segnalata
da Codex (pergamena nel paragrafo generale, forgia nei prompt) è voluta: la pergamena vale per
i fogli della fase 1, le tavole hanno lo sfondo della scena.

Fase 2b (2026-11-04). Guardate le quattro varianti di Codex (7439813). ~~Scelte `4_arrivo_a_1` e
`5_fabbro_b_1`.~~ Scartate tutte e quattro (Sergio): il cuore della coda è capovolto, la coda entra
dalla punta e i lobi stanno in fuori, mentre nel modello (R9) la coda entra nell'incavo e la punta
guarda in fuori. Colpa del prompt («a cuore, NON a freccia»). Riguardate con questo occhio anche
le tavole: in `6_rapimento_a` e `6_rapimento_b` la coda è giusta. E si salva lo scarto della fase 2
`4_arrivo_a` (tornato da `scartati/fase2/` in `art/WB-012/`): la punta è un po' aguzza ma è quella del modello, la tavola
torna buona (Claude, su indicazione di Sergio: «qualche coda di prima si salva»). Il bisbiglio di
fase 2 resta scartato per il martello: si rifà nella fase 2c, col prompt della fase 2 e le mani
vuote, senza insistere sulla coda. Le quattro varianti della 2b vanno in `scartati/fase2b/`.
