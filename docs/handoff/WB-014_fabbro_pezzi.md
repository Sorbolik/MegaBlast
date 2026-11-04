# WB-014 · Il Fabbro: tre quarti, espressioni e pezzi sullo stampino

- **Stato:** APPROVATA
- **Data:** 2026-11-04
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-014`

## Obiettivo

Il Fabbro è il custode della Forgia: lo affronti nella missione «Il Fabbro» e nella Battaglia
della Forgia (2 contro 2), e parla nella striscia delle vignette col suo ritratto. Oggi in
campo è l'apprendista col nome «Il Fabbro». Serve il suo corpo a pezzi sullo **stampino**, come
l'apprendista (WB-009) e Favilla (WB-013), così si muove con le stesse animazioni. Segue la
procedura dei personaggi ([PERSONAGGI.md](PERSONAGGI.md)) e copia la scheda di WB-013, con le
lezioni della sua fase 2 già dentro. Il modello è il foglio del Fabbro scelto in WB-012
(Fabbro B, la pancia-fornace).

Viene prima della PR 3 della Forgia (piano dei livelli,
https://claude.ai/artifact/12CRugbQCR2oB32LHt6aS2): la Forgia è il suo girone.

## Due fasi, due comandi

- **Fase 1**, `esegui WB-014 fase 1`: immagini 1 e 2. Sergio sceglie il tre quarti; Claude lo
  salva in `art/WB-014/scelti/tre_quarti.png` (e le espressioni in
  `art/WB-014/scelti/espressioni.png`) su main.
- **Fase 2**, `esegui WB-014 fase 2`: immagini 3, 4 e 5, coi file scelti come riferimento.
- Codex esegue solo le righe della fase chiesta; se un riferimento della fase non c'è, si ferma.

## Cosa teniamo e cosa scartiamo

| Teniamo | Perché |
|---|---|
| Il suo aspetto del foglio scelto (R1): pelle rosso scuro, corna lunghe brune a costole che vanno di lato e in su con le punte verso dentro, baffoni e sopracciglia bianchi, orecchie a punta, occhi gialli, fornace di ferro rivettata sul petto con la grata a cinque sbarre e il fuoco arancio, comignolo sulla spalla, guanti scuri, grembiule di cuoio, cinghie d'ottone | è lui: si riconosce da lontano dalle corna, dai baffi e dalla fornace accesa |
| **Lo stesso scheletro e la stessa altezza dell'apprendista**, ma più largo e pesante: spalle larghe, pancia-fornace grande, gambe corte e tozze | in gioco la sagoma per i colpi è uguale per tutti (`client/sim/body.lua`): se fosse più alto, si vedrebbe colpito dove non lo è. La stazza la dicono la larghezza e la fornace |
| Tre quarti verso **destra**, tutti e due i piedi a destra | la vista dello stampino (lezione di WB-009); nel foglio di WB-012 guarda a sinistra, qui si gira |
| Teste senza collo e col contorno chiuso, come le teste dell'apprendista (R8) | lezione di WB-013: il collo è del busto, la testa si taglia intera |
| Tutti e due gli stivali a destra nei pezzi | lezione di WB-013 |

| Scartiamo | Perché |
|---|---|
| Il martello in mano | in gioco tiene l'arma che usa (il Maglio è già un'arma del gioco) |
| Il fumo del comignolo | è fermo e a 90 px è una macchia; il comignolo resta |
| La coda e le ali | nel foglio non ha la coda; le ali sono equipaggiamento: i loro posti restano vuoti (`--senza ala,coda`) |
| Tratteggi, texture, sfumature, bagliore del fuoco | a misura di gioco sono rumore e il ricalco in SVG viene sporco |
| Il colore della squadra su di lui | è un personaggio della storia, sempre uguale: la squadra la dice la targa (come per Favilla) |
| Le forme del manichino grigio | lo stampino dice solo dove va ogni pezzo e quanto è grande |
| Chiedere l'SVG a ChatGPT | si ricalca il disegno buono |

## La tavolozza (uguale in ogni prompt)

| Parte | Colore | Ombra |
|---|---|---|
| contorno, pupille | nero `#000000` | |
| pelle | `#A8361F` | `#7A2414` |
| baffi e sopracciglia | `#F3EEDD` | `#CFC6AE` |
| corna | `#9A6A42` | `#6B4529` |
| occhi | `#F2C45A`, lucina `#FFFFFF` | |
| bocca dentro | `#5A1A10`, denti `#FFFFFF`, lingua `#E0605A` | |
| ferro (fornace, comignolo) | `#5C616B` | `#3E424A` |
| ottone (rivetti, cinghie, anelli) | `#C8913A` | `#9A6A24` |
| fuoco della grata | `#F28A2A`, cuore `#FFD15A` | |
| guanti e stivali | `#4A3A30` | `#2F241E` |
| grembiule | `#7A4A2A` | `#5A341C` |
| pantaloni | `#6B4A36` | `#4E3426` |
| sfondo | bianco `#FFFFFF` (fase 1), magenta `#FF00FF` (fase 2) | |

Nota per il ricalco: guanti, stivali e ferro sono scuri ma non neri; la tavolozza di Claude
avrà un `righe_max` basso come quella di Favilla, così non diventano contorno.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-012/scelti/fabbro.png` | il foglio modello del Fabbro scelto (figura intera e otto busti, verso sinistra) |
| R2 | `art/WB-008/9_fabbro_B.png` | il Fabbro B, la fornace (figura a sinistra) |
| R3 | `art/WB-009/scelti/tre_quarti_gamba.png` | l'apprendista nello stile pulito del gioco: il tratto, i colori piatti, l'altezza e lo scheletro da copiare |
| R4 | `art/WB-009/riferimenti/R2_stampino_ai.png` | lo stampino: dove va ogni pezzo (3072×2048) |
| R5 | `art/WB-009/riferimenti/R3_manichino.png` | come si attaccano i pezzi |
| R6 | `art/WB-014/scelti/tre_quarti.png` | il tre quarti scelto in fase 1 (c'è solo dopo) |
| R7 | `art/WB-014/scelti/espressioni.png` | le espressioni scelte in fase 1 (c'è solo dopo) |
| R8 | `art/WB-009/7_teste.png` | le nove teste dell'apprendista approvate: **solo il formato** da copiare (niente collo, contorno nero chiuso sotto il mento), non le facce |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto: il
primo è "image 1", il secondo "image 2" e così via. Sfondo **non** trasparente (eccezione ad
`AGENTS.md`): bianco pieno in fase 1, magenta pieno `#FF00FF` in fase 2, perché lo usa lo
strumento di taglio.

| Fase | Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|---|
| 1 | `1_tre_quarti` | R1, R2, R3 | 1024×1536 verticale | 2 |
| 1 | `2_espressioni` | R1, R6 se c'è già, altrimenti R2, R3 | 1536×1536 (o 1024×1024) | 1 |
| 2 | `3_teste` | R6, R7, R8 | 1536×1536 (o 1024×1024) | 1 |
| 2 | `4_corpo` | R6, R4, R5 | 3:2 orizzontale, la più grande possibile (minimo 1536×1024) | 1 |
| 2 | `5_braccia_chiuse` | R6, `art/WB-014/4_corpo.png` | 1536×1024 | 1 |

In fase 1 `2_espressioni` si allega R1, R2, R3 (R6 non c'è ancora).

### `1_tre_quarti`

```
Image 1 is the Blacksmith (il Fabbro), a character of our game: copy him EXACTLY (long ridged brown horns curving out sideways and up with the tips turning inward, big white moustache and bushy eyebrows, pointed ears, yellow eyes, dark red skin, riveted iron chest-furnace with a barred grate of five bars showing orange fire, a short chimney on his shoulder, dark gloves, leather apron, brass straps). Image 2 shows the same character again. Image 3 is another character of the same game, a little imp apprentice, drawn in the game's clean style: copy ONLY its rendering (flat colors, thick black outline), its HEIGHT and body skeleton, and its three-quarter angle. Do not copy its face, horns, neckerchief or tail.

The Fabbro is an old devil blacksmith. In our game every character has the SAME height and skeleton as image 3, so draw him exactly as tall as image 3, with a big head (about one third of his height), but much BROADER and HEAVIER: wide shoulders, a big round furnace belly that fills his chest, thick arms, short stocky legs. Same face, horns, moustache and furnace as image 1.

Draw him ONCE, full body, in a clean THREE-QUARTER VIEW FACING RIGHT (image 1 faces left: here he faces right), standing still in a neutral, relaxed pose: weight on both feet, legs slightly apart, BOTH FEET POINTING TO THE RIGHT, both arms hanging loosely a little away from the body with open relaxed gloved four-fingered hands, the near arm and near leg (on the right of the picture) fully visible, the far arm and far leg (on the left) partly behind the body. The face is turned to the right in three-quarter view. No hammer, no tools, nothing in his hands, no smoke from the chimney, no tail, no wings.

Rendering rules, very strict, because this drawing will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone listed below. No gradients, no textures, no hatching, no brush strokes, no soot, no noise, no soft shading, no glow (also no glow around the fire).
- Thick, clean, closed pure-black #000000 outline of even weight around the whole figure, with thinner black lines only for inner details (eyes, eyebrows, moustache, mouth, fingers, horn ridges, rivets, grate bars, apron folds).
- Use ONLY these colors: outline and pupils black #000000; skin #A8361F, skin shadow #7A2414; moustache and eyebrows #F3EEDD, their shadow #CFC6AE; horns #9A6A42, their shadow #6B4529; eyes #F2C45A with a small white #FFFFFF highlight; inside of mouth #5A1A10, teeth white #FFFFFF, tongue #E0605A; iron of the furnace and chimney #5C616B, its shadow #3E424A; brass rivets, straps and rings #C8913A, their shadow #9A6A24; fire in the grate #F28A2A with a brighter core #FFD15A; gloves and boots #4A3A30, their shadow #2F241E; apron #7A4A2A, its shadow #5A341C; trousers #6B4A36, their shadow #4E3426.
- Flat pure white #FFFFFF background, no ground, no shadow on the ground, nothing else in the picture.
- No text, numbers, labels, arrows or signatures. Portrait format 2:3.
```

### `2_espressioni`

```
Image 1 is the model sheet of the Fabbro, a character of our game: copy his head EXACTLY (head shape, long ridged horns with the tips turning inward, white moustache and bushy eyebrows, pointed ears, yellow eyes). Image 2 is his full figure. Image 3 is another character of the same game drawn in the game's clean style: copy ONLY its rendering (flat colors, thick black outline).

Draw an EXPRESSION SHEET: NINE copies of his head only (with a short neck stub, no body, no chimney), all in three-quarter view facing RIGHT, all the same size, in a 3 by 3 grid, well apart from each other. The head outline, horns, ears and the shape of the moustache are IDENTICAL in all nine: only the eyes, eyebrows, mouth and the lift of the moustache change.
Row 1: 1) STERN: his default face, calm and severe, a slight half smile under the moustache; 2) HIT: just hit and in pain, eyes squeezed shut like > <, mouth open in a jagged shape under the moustache; 3) VICTORY: eyes closed in happy upside-down arcs, big open laughing mouth showing teeth, moustache lifted.
Row 2: 4) KNOCKED OUT: dizzy spiral pupils, wobbly wavy mouth, tongue slightly out; 5) AIMING: focused, near eye wide open and far eye squinting, eyebrows low, lips pressed; 6) ANGRY: eyebrows down in a V, shouting with teeth showing.
Row 3: 7) DEFEATED: grim and sad, eyebrows up in the middle, eyes looking down, moustache drooping; 8) SCARED: eyes wide with tiny pupils, mouth a small open oval, eyebrows high; 9) TAUNT: one eye closed in a wink, a cheeky grin under the moustache.

Rendering rules, very strict, because these drawings will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone listed below. No gradients, no textures, no hatching, no soft shading, no glow.
- Thick, clean, closed pure-black #000000 outline around each head, thinner black lines only for inner details. The bottom end of the neck stub has NO black outline: the outline gets thinner as it reaches the stub's lower end and stops, and the skin color runs right to the edge.
- Use ONLY these colors: outline and pupils black #000000; skin #A8361F, skin shadow #7A2414; moustache and eyebrows #F3EEDD, their shadow #CFC6AE; horns #9A6A42, their shadow #6B4529; eyes #F2C45A with a small white #FFFFFF highlight; inside of mouth #5A1A10, teeth white #FFFFFF, tongue #E0605A.
- Flat pure white #FFFFFF background.
- No text, numbers, labels, arrows or signatures. Square format.
```

### `3_teste`

```
Image 1 is the Fabbro, a character of our game, in a three-quarter view facing right: copy his head exactly (shape, horns, ears, moustache, eyebrows, colors, flat style). Image 2 is his approved expression sheet: nine heads in a 3 by 3 grid. Image 3 is another character of the same game, a little imp apprentice: it shows ONLY the FORMAT to copy, nine heads cut out with no neck and a closed black outline under the chin. Do not copy its faces, horns or colors.

Draw NINE heads of him in a 3 by 3 grid, all the same size, all facing right in three-quarter view, well apart from each other, the head outline, horns, ears and moustache shape IDENTICAL in all nine. They are the nine expressions of image 2, in the same order, copied exactly. Row 1: 1) STERN (calm, severe, slight half smile), 2) HIT (eyes squeezed shut > <, jagged open mouth), 3) VICTORY (happy closed eyes, big laughing mouth). Row 2: 4) KNOCKED OUT (spiral pupils, wavy mouth, tongue slightly out), 5) AIMING (near eye wide open looking right, far eye squinting, lips pressed), 6) ANGRY (eyebrows in a V, shouting with teeth). Row 3: 7) DEFEATED (sad, eyes down, moustache drooping), 8) SCARED (wide eyes, tiny pupils, small open mouth), 9) TAUNT (wink and cheeky grin).

NO NECK AT ALL, very important: each head is drawn exactly as if it had been cut out of image 1 along the outline of the head. It ends at the chin, under the moustache and at the back of the jaw: nothing below them, no neck, no neck stub, no collar, no chimney. The thick black #000000 outline is CLOSED all around each head, also under the chin and under the back of the jaw, smooth and even, exactly like the heads of image 3. The neck stubs of image 2 must NOT appear. The horns stay whole, inside the picture.

Rendering rules, very strict, because these heads will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone listed below. No gradients, no textures, no hatching, no soft shading, no glow.
- Use ONLY these colors: outline and pupils black #000000; skin #A8361F, skin shadow #7A2414; moustache and eyebrows #F3EEDD, their shadow #CFC6AE; horns #9A6A42, their shadow #6B4529; eyes #F2C45A with a small white #FFFFFF highlight; inside of mouth #5A1A10, teeth white #FFFFFF, tongue #E0605A.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the heads.
- No text, numbers, labels, arrows or signatures. Square format.
```

### `4_corpo`

```
Image 1 is the Fabbro, a character of our game, in a three-quarter view facing right. It is the EXACT model: every body part you draw must be COPIED from image 1, shape by shape, with the same proportions, the same thickness, the same clothes and the same contours. Do not invent, round off, fatten or simplify any part.

Image 2 is a layout sheet: grey placeholder parts on a flat magenta #FF00FF background, in three rows. Use image 2 ONLY to know where each part goes on the sheet and roughly how big it is. Do NOT copy the grey parts' shapes. Image 3 shows how the grey parts attach to each other.

Make the BODY PARTS SHEET of the Fabbro of image 1, cut apart like a paper puppet, on the same canvas as image 2 with the same flat magenta #FF00FF background. Leave the WHOLE FIRST ROW EMPTY (pure magenta, no heads: the heads are already done). Draw only these parts, each over its grey placeholder, well separated from each other, each COMPLETE even where other parts would hide it in image 1:
Row 2: the TORSO of image 1 without head, arms and legs: the same shape as in image 1, with the riveted iron furnace and its barred grate with the orange fire, the brass straps, the leather apron, the short chimney on the shoulder (no smoke), and a short neck stub of skin on top. NO stubby arms: at each shoulder the torso simply ends with a smooth, round, full edge of skin. Then NOTHING where the grey wing is and NOTHING where the grey tail is (leave both spots empty magenta: he has no wings and no tail).
Row 3: the near arm and the far arm, copied from image 1 (thick bare red arm, brass band if there is one, heavy dark glove with an open relaxed four-fingered hand), each straight and hanging down from a round shoulder end; the near leg and the far leg, copied from image 1 (short stocky trouser leg, dark boot), each straight, round at the hip end, and BOTH BOOTS POINTING TO THE RIGHT in side view; one closed four-fingered gloved fist, the size of the hands in image 1 (a small round piece, outlined all around).

OUTLINE AND JOINTS, very important: every part has a thick, clean pure-black #000000 outline, EXCEPT at its joint ends. At a joint end the black outline gets gradually thinner and disappears completely; the last stretch of the part is filled with its flat color right to the edge, rounded and full, with NO black line across it. Joint ends are: the neck stub and the two shoulder edges of the torso; the top of each arm (shoulder end); the top of each leg (hip end). The color near every joint end must be PERFECTLY UNIFORM: plain skin #A8361F at the neck stub, at the shoulders and at the top of the arms, plain trousers #6B4A36 at the hips and at the top of the legs. No shadow, no highlight, no fold, no line, no color change in the last stretch before the joint, so that two overlapping parts blend into one surface with no visible seam. Keep shadow shapes well away from the joint ends.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone listed below. No gradients, no textures, no hatching, no soft shading, no glow.
- Use ONLY these colors: outline black #000000; skin #A8361F, skin shadow #7A2414; iron #5C616B, its shadow #3E424A; brass #C8913A, its shadow #9A6A24; fire #F28A2A with a brighter core #FFD15A; gloves and boots #4A3A30, their shadow #2F241E; apron #7A4A2A, its shadow #5A341C; trousers #6B4A36, their shadow #4E3426.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels or signatures. Landscape 3:2, as large as possible.
```

### `5_braccia_chiuse`

```
Image 1 is the Fabbro, a character of our game, in a three-quarter view facing right. Image 2 is his parts sheet: copy the arms of image 2 exactly (same length, thickness, glove, contour, colors and flat style).

Draw TWO ARMS of him side by side, left to right, the same size as the arms in image 2, well apart from each other, on a flat pure magenta #FF00FF background: 1) the NEAR arm, 2) the FAR arm. Each arm is straight and hangs down from a round shoulder end, exactly like in image 2, but the gloved hand is CLOSED IN A FIST as if gripping the handle of a tool: four fingers curled, the thumb wrapped over them, the knuckles towards the right. The fist is the same size as the open hands of image 2.

OUTLINE AND JOINTS, very important: each arm has a thick, clean pure-black #000000 outline, EXCEPT at the shoulder end at the top: there the outline gets gradually thinner and disappears completely, and the skin color runs right to the edge, rounded and full, with no black line across it. The skin near the shoulder end is PERFECTLY UNIFORM plain #A8361F: no shadow, no line there, so the arm blends into the torso with no visible seam.

Rendering rules, very strict, because these arms will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no hatching, no soft shading, no glow.
- Use ONLY these colors: outline black #000000; skin #A8361F, skin shadow #7A2414; brass #C8913A, its shadow #9A6A24; gloves #4A3A30, their shadow #2F241E.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the arms.
- No text, numbers, labels or signatures. Landscape 3:2.
```

## Criteri di accettazione

- [ ] è il Fabbro di R1: corna lunghe brune a costole con le punte verso dentro, baffoni bianchi, fornace con la grata a cinque sbarre e il fuoco, comignolo, guanti, grembiule
- [ ] alto come l'apprendista di R3 (stesso scheletro), ma più largo e pesante
- [ ] tre quarti verso destra, tutti e due i piedi a destra; niente martello, fumo, coda, ali
- [ ] solo colori piatti della tavolozza, al massimo un'ombra netta per colore; niente tratteggi, texture, bagliori
- [ ] contorno nero spesso e chiuso, tranne alle estremità delle giunture, dove si assottiglia e sparisce
- [ ] vicino alle giunture il colore è uniforme (pelle o pantaloni pieni)
- [ ] nelle teste la sagoma, le corna e i baffi sono identici, cambia solo l'espressione; fase 2: senza collo, contorno chiuso
- [ ] fase 2: 10 pezzi sopra i 12 posti di R4 (posti dell'ala e della coda vuoti), prima riga vuota, sfondo magenta pieno senza aloni
- [ ] nessun verde `#00FF00` (niente colore della squadra)
- [ ] nessuna scritta, numero o firma

## Dopo le immagini (lo fa Claude)

Come per Favilla (WB-013, «Dopo le immagini» e il resoconto della fase 2), con tutte le
tecniche di WB-009:

1. Tavolozza `strumenti/stampino/tavolozze/fabbro.json` coi colori qui sopra (con
   `macchie_min`, `macchie_ombra_min` e un `righe_max` basso per guanti, stivali e ferro).
2. Ricalco a strati con `vettoriale.py --tavolozza ... [--senza ...]`: nel foglio delle teste
   niente ferro, ottone, fuoco, guanti, grembiule, pantaloni; nel corpo niente baffi, corna,
   occhi, bocca.
3. Colori esatti in ogni SVG; ritocchi a mano in un JSON accanto all'SVG se servono.
4. I PNG solo dagli SVG; teste dal foglio `3_teste` senza collo.
5. Taglio: `taglia.py 4_corpo_col.png --nome fabbro --categoria personaggio --allinea --senza
   ala,coda --teste 3_teste_col.png --tavolozza ...`, poi `--aggiungi --pugni
   5_braccia_chiuse_col.png`.
6. Editor ripubblicato; nel gioco il Fabbro veste la pelle `fabbro` (campo `pelle` della
   missione, come Favilla nel Duello) nella missione «Il Fabbro» e nella Battaglia della Forgia.
7. Simulazione e foto per Sergio.

---

## Decisione

Approvata da Claude, 2026-11-04: è il personaggio che serve prima della PR 3 della Forgia (il
suo girone), con la stessa procedura di WB-013, che ha funzionato al primo giro della fase 2;
reversibile (il gioco non cambia finché non si tagliano). Scelte di Claude: alto come gli altri
(la sagoma dei colpi è uguale per tutti) e la stazza nella larghezza; niente martello in mano,
niente fumo, niente coda; tavolozza presa dal foglio scelto di WB-012 in colori piatti.

## Consegna di Codex

## Resoconto di Claude
