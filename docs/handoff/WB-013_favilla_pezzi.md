# WB-013 · Favilla: tre quarti, espressioni e pezzi sullo stampino

- **Stato:** APPROVATA
- **Data:** 2026-11-04
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-013`

## Obiettivo

Favilla entra nel campo (piano dei livelli, https://claude.ai/artifact/12CRugbQCR2oB32LHt6aS2,
approvato da Sergio): ti mostra le mosse nel cortile, gioca in squadra con te nella Forgia, è
l'avversaria del Duello. Serve il suo corpo a pezzi sullo **stampino**, come l'apprendista,
così si muove con le stesse animazioni. Segue la procedura dei personaggi
([PERSONAGGI.md](PERSONAGGI.md)) e parte dal set di prompt di WB-009, con le sue correzioni già
dentro. Il modello è il foglio di Favilla scelto in WB-012 (salopette e stivali, «quella con
le scarpe»).

Finché i pezzi non ci sono, nel gioco Favilla è l'apprendista con la fiamma bianco-azzurra
(scelta 1 del piano): questa scheda la sostituisce.

## Due fasi, due comandi

- **Fase 1**, `esegui WB-013 fase 1`: immagini 1 e 2. Sergio sceglie il tre quarti; Claude lo
  salva in `art/WB-013/scelti/tre_quarti.png` (e le espressioni in
  `art/WB-013/scelti/espressioni.png`) su main.
- **Fase 2**, `esegui WB-013 fase 2`: immagini 3, 4 e 5, coi file scelti come riferimento.
- Codex esegue solo le righe della fase chiesta; se un riferimento della fase non c'è, si ferma.

## Cosa teniamo e cosa scartiamo

| Teniamo | Perché |
|---|---|
| Lo stesso corpo dell'apprendista: piccola e tozza, testa grande, pelle rosso mattone, muso pergamena | è un'apprendista anche lei; stesso scheletro, stesse animazioni |
| La fiamma bianco-azzurra con le punte dorate al posto dei capelli, sempre della stessa forma | è lei: si riconosce da lontano, anche a 90 px |
| Corna corte color osso, orecchie a punta, ciglia, occhi gialli | il foglio di WB-012 |
| Camicia pergamena con le maniche arrotolate, salopette pergamena, bretelle marroni coi bottoni d'ottone, grembiulino di cuoio marrone, stivali marroni | il foglio scelto di WB-012 (Sergio: «quella con le scarpe») |
| Coda sottile con la punta del modello (R2): un cuore capovolto, la coda entra nell'incavo e la punta guarda in fuori | la sua sagoma; in WB-012 fase 2b, a forza di dire «cuore, non freccia», ChatGPT l'ha capovolto: qui si dice una volta, «come nell'immagine» |
| Tre quarti verso destra, tutti e due i piedi a destra | la vista dello stampino (lezione di WB-009) |

| Scartiamo | Perché |
|---|---|
| Tratteggi, texture, sfumature, bagliori della fiamma | a misura di gioco sono rumore e il ricalco in SVG viene sporco |
| Il colore della squadra su di lei | è un personaggio della storia, sempre uguale: la squadra la dice la targa (nome e barra nel colore della squadra). Si può aggiungere dopo, su un dettaglio, se in partita non si capisce |
| Le ali | sono equipaggiamento: il posto dell'ala resta vuoto |
| Le forme del manichino grigio | lo stampino dice solo dove va ogni pezzo e quanto è grande |
| Chiedere l'SVG a ChatGPT | si ricalca il disegno buono |

## La tavolozza (uguale in ogni prompt)

| Parte | Colore | Ombra |
|---|---|---|
| contorno, ciglia, pupille | nero `#000000` | |
| pelle | `#B8432A` | `#8E2F1C` |
| muso | `#F1DFB0` | `#D6BC86` |
| corna | `#EFE3C8` | `#C9B48E` |
| occhi | `#F2C45A`, lucina `#FFFFFF` | |
| bocca dentro | `#5A1A10`, denti `#FFFFFF`, lingua `#E0605A` | |
| fiamma | bianco `#FFFFFF`, azzurro `#BFE9FF`, punte dorate `#F2C45A` | azzurro scuro `#8CCFEF` |
| camicia e salopette | `#E6D2A6` | `#C4A977` |
| bretelle, grembiule | `#7A4A2A` | `#5A341C` |
| bottoni | `#D9A441` | |
| stivali | `#6B3F22` | `#4A2A15` |
| sfondo | bianco `#FFFFFF` (fase 1), magenta `#FF00FF` (fase 2) | |

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-012/scelti/favilla.png` | il foglio modello di Favilla scelto (figura intera e otto busti, stile fumetto) |
| R2 | `art/WB-012/riferimenti/R9_favilla_figura.png` | la sua figura intera ritagliata da R1: abiti, stivali, **coda a cuore** |
| R3 | `art/WB-009/scelti/tre_quarti_gamba.png` | l'apprendista nello stile pulito del gioco: il tratto, i colori piatti e le proporzioni da copiare |
| R4 | `art/WB-009/riferimenti/R2_stampino_ai.png` | lo stampino: dove va ogni pezzo (3072×2048) |
| R5 | `art/WB-009/riferimenti/R3_manichino.png` | come si attaccano i pezzi |
| R6 | `art/WB-013/scelti/tre_quarti.png` | il tre quarti scelto in fase 1 (c'è solo dopo) |
| R7 | `art/WB-013/scelti/espressioni.png` | le espressioni scelte in fase 1 (c'è solo dopo) |
| R8 | `art/WB-009/7_teste.png` | le nove teste dell'apprendista approvate: **solo il formato** da copiare (niente collo, contorno nero chiuso sotto il mento), non le facce |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto: il
primo è "image 1", il secondo "image 2" e così via. Sfondo **non** trasparente (eccezione ad
`AGENTS.md`): bianco pieno in fase 1, magenta pieno `#FF00FF` in fase 2, perché lo usa lo
strumento di taglio.

| Fase | Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|---|
| 1 | `1_tre_quarti` | R2, R1, R3 | 1024×1536 verticale | 2 |
| 1 | `2_espressioni` | R1, R2, R3 | 1536×1536 (o 1024×1024) | 1 |
| 2 | `3_teste` | R6, R7, R8 | 1536×1536 (o 1024×1024) | 1 |
| 2 | `4_corpo` | R6, R4, R5 | 3:2 orizzontale, la più grande possibile (minimo 1536×1024) | 1 |
| 2 | `5_braccia_chiuse` | R6, `art/WB-013/4_corpo.png` | 1536×1024 | 1 |

### `1_tre_quarti`

```
Image 1 is Favilla, a character of our game, full figure: copy her EXACTLY (shapes, flame hair, horns, face, clothes, boots, tail). Image 2 is her model sheet: more views of the same character. Image 3 is another character of the same game, a little imp apprentice, drawn in the game's clean style: copy ONLY its rendering (flat colors, thick black outline), its body proportions and its three-quarter angle. Do not copy its face, horns, neckerchief or tail.

Favilla is a little imp girl, a senior apprentice at a hellish forge: small and stocky like image 3, big round head (about one third of her height), two short bone-colored horns, pointed ears, eyelashes, big yellow eyes with black pupils, a confident smile, brick-red skin with a parchment-colored muzzle. Instead of hair she has a big FLAME, white in the middle and light blue outside, with golden tips, rising up from her head, always the same shape. She wears a parchment-colored shirt with the sleeves rolled up to the elbows, parchment-colored overalls with the legs rolled up, brown shoulder straps with round brass buttons, a small brown leather apron, and brown boots. Her tail is long and thin, with the same tip as in image 1.

Draw her ONCE, full body, in a clean THREE-QUARTER VIEW FACING RIGHT, standing still in a neutral, relaxed pose: weight on both feet, legs slightly apart, BOTH FEET POINTING TO THE RIGHT, both arms hanging loosely a little away from the body with open relaxed four-fingered hands, the near arm and near leg (on the right of the picture) fully visible, the far arm and far leg (on the left) partly behind the body, the tail coming out from behind her lower back and curving up behind her on the left, fully visible from root to heart tip. The face is turned to the right in three-quarter view. No wings, no tools, nothing in her hands.

Rendering rules, very strict, because this drawing will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone listed below. No gradients, no textures, no hatching, no brush strokes, no soot, no noise, no soft shading, no glow (also no glow around the flame).
- Thick, clean, closed pure-black #000000 outline of even weight around the whole figure, with thinner black lines only for inner details (eyes, eyelashes, mouth, fingers, clothes folds, buttons).
- Use ONLY these colors: outline, eyelashes and pupils black #000000; skin #B8432A, skin shadow #8E2F1C; muzzle #F1DFB0, its shadow #D6BC86; horns #EFE3C8, their shadow #C9B48E; eyes #F2C45A with a small white #FFFFFF highlight; inside of mouth #5A1A10, teeth white #FFFFFF; flame white #FFFFFF and light blue #BFE9FF with golden tips #F2C45A, flame shadow #8CCFEF; shirt and overalls #E6D2A6, their shadow #C4A977; straps and apron #7A4A2A, their shadow #5A341C; buttons #D9A441; boots #6B3F22, their shadow #4A2A15.
- Flat pure white #FFFFFF background, no ground, no shadow on the ground, nothing else in the picture.
- No text, numbers, labels, arrows or signatures. Portrait format 2:3.
```

### `2_espressioni`

```
Image 1 is the model sheet of Favilla, a character of our game: copy her head EXACTLY (head shape, flame hair, horns, ears, eyelashes, muzzle). Image 2 is her full figure. Image 3 is another character of the same game drawn in the game's clean style: copy ONLY its rendering (flat colors, thick black outline).

Draw an EXPRESSION SHEET: NINE copies of her head only (with a short neck stub, no body), all in three-quarter view facing right, all the same size, in a 3 by 3 grid, well apart from each other. The head outline, flame, horns and ears are IDENTICAL in all nine: only the eyes, eyebrows and mouth change (the ears may tilt slightly).
Row 1: 1) SLY: her default face, a confident closed-mouth smile, one eyebrow slightly raised; 2) HIT: just hit and in pain, eyes squeezed shut like > <, mouth open in a jagged shape; 3) VICTORY: eyes closed in happy upside-down arcs, big open laughing mouth showing teeth.
Row 2: 4) KNOCKED OUT: dizzy spiral pupils, wobbly wavy mouth, tongue slightly out; 5) AIMING: focused, near eye wide open and far eye squinting, lips pressed, tip of the tongue sticking out of the corner of the mouth; 6) ANGRY: eyebrows down in a V, teeth clenched in a snarl.
Row 3: 7) DEFEATED: sad, eyebrows up in the middle, eyes looking down, small downturned mouth; 8) SCARED: eyes wide with tiny pupils, mouth a small open oval, eyebrows high; 9) TAUNT: one eye closed in a wink, tongue sticking out cheekily.

Rendering rules, very strict, because these drawings will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone listed below. No gradients, no textures, no hatching, no soft shading, no glow.
- Thick, clean, closed pure-black #000000 outline around each head, thinner black lines only for inner details. The bottom end of the neck stub has NO black outline: the outline gets thinner as it reaches the stub's lower end and stops, and the skin color runs right to the edge. The skin near the bottom of the neck stub is PERFECTLY UNIFORM plain #B8432A: no shadow, no highlight, no line there.
- Use ONLY these colors: outline, eyelashes and pupils black #000000; skin #B8432A, skin shadow #8E2F1C; muzzle #F1DFB0, its shadow #D6BC86; horns #EFE3C8, their shadow #C9B48E; eyes #F2C45A with a small white #FFFFFF highlight; inside of mouth #5A1A10, teeth white #FFFFFF, tongue #E0605A; flame white #FFFFFF and light blue #BFE9FF with golden tips #F2C45A, flame shadow #8CCFEF.
- Flat pure white #FFFFFF background.
- No text, numbers, labels, arrows or signatures. Square format.
```

### `3_teste`

```
Image 1 is Favilla, a character of our game, in a three-quarter view facing right: copy her head exactly (shape, flame hair, horns, ears, eyelashes, muzzle, colors, flat style). Image 2 is her approved expression sheet: nine heads in a 3 by 3 grid. Image 3 is another character of the same game, a little imp apprentice: it shows ONLY the FORMAT to copy, nine heads cut out with no neck and a closed black outline under the chin. Do not copy its faces, horns or colors.

Draw NINE heads of her in a 3 by 3 grid, all the same size, all facing right in three-quarter view, well apart from each other, the head outline, flame, horns and ears IDENTICAL in all nine. They are the nine expressions of image 2, in the same order, copied exactly. Row 1: 1) SLY (her default confident closed-mouth smile), 2) HIT (eyes squeezed shut > <, jagged open mouth), 3) VICTORY (happy closed eyes, big laughing mouth). Row 2: 4) KNOCKED OUT (spiral pupils, wavy mouth, tongue slightly out), 5) AIMING (near eye wide open looking right, far eye squeezed, tongue tip out of the corner of the mouth), 6) ANGRY (eyebrows in a V, clenched teeth). Row 3: 7) DEFEATED (sad, eyes down, downturned mouth), 8) SCARED (wide eyes, tiny pupils, small open mouth), 9) TAUNT (wink and tongue out).

NO NECK AT ALL, very important: each head is drawn exactly as if it had been cut out of image 1 along the outline of the head. It ends at the chin and at the back of the jaw: nothing below them, no neck, no neck stub, no collar. The thick black #000000 outline is CLOSED all around each head, also under the chin, under the muzzle and under the back of the jaw, smooth and even, exactly like the heads of image 3. The neck stubs of image 2 must NOT appear. The flame stays whole on top of every head, inside the picture.

Rendering rules, very strict, because these heads will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone listed below. No gradients, no textures, no hatching, no soft shading, no glow.
- Use ONLY these colors: outline, eyelashes and pupils black #000000; skin #B8432A, skin shadow #8E2F1C; muzzle #F1DFB0, its shadow #D6BC86; horns #EFE3C8, their shadow #C9B48E; eyes #F2C45A with a small white #FFFFFF highlight; inside of mouth #5A1A10, teeth white #FFFFFF, tongue #E0605A; flame white #FFFFFF and light blue #BFE9FF with golden tips #F2C45A, flame shadow #8CCFEF.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the heads.
- No text, numbers, labels, arrows or signatures. Square format.
```

### `4_corpo`

```
Image 1 is Favilla, a character of our game, in a three-quarter view facing right. It is the EXACT model: every body part you draw must be COPIED from image 1, shape by shape, with the same proportions, the same thickness, the same clothes and the same contours. Do not invent, round off, fatten or simplify any part.

Image 2 is a layout sheet: grey placeholder parts on a flat magenta #FF00FF background, in three rows. Use image 2 ONLY to know where each part goes on the sheet and roughly how big it is. Do NOT copy the grey parts' shapes. Image 3 shows how the grey parts attach to each other.

Make the BODY PARTS SHEET of Favilla of image 1, cut apart like a paper puppet, on the same canvas as image 2 with the same flat magenta #FF00FF background. Leave the WHOLE FIRST ROW EMPTY (pure magenta, no heads: the heads are already done). Draw only these parts, each over its grey placeholder, well separated from each other, each COMPLETE even where other parts would hide it in image 1:
Row 2: the TORSO of image 1 without head, arms, legs and tail: the same shape as in image 1, with her parchment shirt, the top of the overalls, the brown straps with the brass buttons and the small leather apron, and a short neck stub of skin on top. NO shoulder bumps and no stubby arms: at each shoulder the torso simply ends with a smooth, round, full edge of shirt. Then NOTHING where the grey wing is (leave that spot empty magenta: she has no wings). Then the WHOLE TAIL of image 1 in one piece, with the same curve, the same thickness and the same tip: one smooth continuous tube, thick at the root and thinner towards the tip, with no breaks, seams or joints along it.
Row 3: the near arm and the far arm, copied from image 1 (rolled-up shirt sleeve at the top, bare red forearm, same open relaxed four-fingered hand), each straight and hanging down from a round shoulder end; the near leg and the far leg, copied from image 1 (rolled-up parchment overalls leg, brown boot), each straight, round at the hip end, and BOTH BOOTS POINTING TO THE RIGHT in side view, like the near boot of image 1 (in image 1 the far boot turns towards the viewer: here it must point right like the other); one closed four-fingered fist, the size of the hands in image 1 (a small round piece, outlined all around).

OUTLINE AND JOINTS, very important: every part has a thick, clean pure-black #000000 outline, EXCEPT at its joint ends. At a joint end the black outline gets gradually thinner and disappears completely; the last stretch of the part is filled with its flat color right to the edge, rounded and full, with NO black line across it. Joint ends are: the neck stub and the two shoulder edges of the torso; the top of each arm (shoulder end); the top of each leg (hip end); the root of the tail. The color near every joint end must be PERFECTLY UNIFORM: plain shirt #E6D2A6 at the shoulders and at the top of the arms, plain overalls #E6D2A6 at the hips and at the top of the legs, plain skin #B8432A at the neck stub and at the root of the tail. No shadow, no highlight, no fold, no line, no color change in the last stretch before the joint, so that two overlapping parts blend into one surface with no visible seam. Keep shadow shapes well away from the joint ends.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone listed below. No gradients, no textures, no hatching, no soft shading, no glow.
- Use ONLY these colors: outline black #000000; skin #B8432A, skin shadow #8E2F1C; shirt and overalls #E6D2A6, their shadow #C4A977; straps and apron #7A4A2A, their shadow #5A341C; buttons #D9A441; boots #6B3F22, their shadow #4A2A15.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels or signatures. Landscape 3:2, as large as possible.
```

### `5_braccia_chiuse`

```
Image 1 is Favilla, a character of our game, in a three-quarter view facing right. Image 2 is her parts sheet: copy the arms of image 2 exactly (same length, thickness, rolled-up sleeve, contour, colors and flat style).

Draw TWO ARMS of her side by side, left to right, the same size as the arms in image 2, well apart from each other, on a flat pure magenta #FF00FF background: 1) the NEAR arm, 2) the FAR arm. Each arm is straight and hangs down from a round shoulder end, exactly like in image 2, but the hand is CLOSED IN A FIST as if gripping the handle of a tool: four fingers curled, the thumb wrapped over them, the knuckles towards the right. The fist is the same size as the open hands of image 2.

OUTLINE AND JOINTS, very important: each arm has a thick, clean pure-black #000000 outline, EXCEPT at the shoulder end at the top: there the outline gets gradually thinner and disappears completely, and the shirt color runs right to the edge, rounded and full, with no black line across it. The shirt near the shoulder end is PERFECTLY UNIFORM plain #E6D2A6: no shadow, no fold, no line there, so the arm blends into the torso with no visible seam. Keep shadow shapes well away from the shoulder end.

Rendering rules, very strict, because these arms will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no hatching, no soft shading, no glow.
- Use ONLY these colors: outline black #000000; skin #B8432A, skin shadow #8E2F1C; shirt #E6D2A6, its shadow #C4A977.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the arms.
- No text, numbers, labels or signatures. Landscape 3:2.
```

## Criteri di accettazione

- [ ] è la Favilla di R1 e R2: fiamma bianco-azzurra con le punte dorate, corna, ciglia, abiti, stivali
- [ ] punta della coda come nel modello (cuore capovolto: la coda entra fra i lobi, la punta in fuori); se è un cuore dritto o una freccia sottile decide Claude
- [ ] solo colori piatti della tavolozza, al massimo un'ombra netta per colore; niente tratteggi, texture, bagliori
- [ ] contorno nero spesso e chiuso, tranne alle estremità delle giunture, dove si assottiglia e sparisce
- [ ] vicino alle giunture il colore è uniforme (camicia, salopette o pelle piena)
- [ ] proporzioni dell'apprendista di R3 (stesso scheletro), tre quarti verso destra, tutti e due i piedi a destra
- [ ] nelle teste la sagoma e la fiamma sono identiche, cambia solo l'espressione; fase 2: senza collo, contorno chiuso
- [ ] fase 2: 11 pezzi sopra i 12 posti di R4 (posto dell'ala vuoto), prima riga vuota, sfondo magenta pieno senza aloni
- [ ] nessun verde `#00FF00` (niente colore della squadra), nessuna ala, niente in mano
- [ ] nessuna scritta, numero o firma

## Dopo le immagini (lo fa Claude)

Come per l'apprendista ([PERSONAGGI.md](PERSONAGGI.md), "Dopo le immagini"), con **tutte** le
tecniche di WB-009 (Sergio, 2026-11-04: «ricordiamoci tutte le tecniche di trasformazione in
vettoriale e di resa di qualità usate per l'apprendista»):

1. **Tavolozza** `strumenti/stampino/tavolozze/favilla.json` coi colori qui sopra.
2. **Ricalco a strati, non a codice:** `vettoriale.py --tavolozza ... FOGLIO.png FOGLIO.svg
   FOGLIO_col.png [RITOCCHI.json]`. Ogni pixel va al colore più vicino della tavolozza e ogni
   colore si ricalca con potrace in uno strato; gli strati si impilano dal fondo al contorno.
   Niente `vtracer` (sposta i colori e fa più nodi), niente SVG chiesti a ChatGPT.
3. **Colori esatti ovunque** («è troppo importante», 2 nov): negli SVG ogni riempimento è un
   codice della tavolozza. Il controllo si ferma su ogni colore fuori.
4. **Colori vicini scelti per macchia,** come crema e corna dell'apprendista. Qui sono tre:
   muso `#F1DFB0`, corna `#EFE3C8` e camicia/salopette `#E6D2A6`. Il muso sta dentro la pelle
   della faccia, le corna sporgono dalla testa, la camicia sta sul corpo. Allo stesso modo il
   bianco della fiamma, i denti e la lucina degli occhi si distinguono per posto. Se servono,
   regole nuove in `vettoriale.py`.
5. **Righe sottili:** le righe scure sottili diventano nere; i fili di un colore prendono
   quello vicino.
6. **Ritocchi a mano** in un JSON accanto all'SVG (poligoni col colore da mettere), per gli
   errori di ChatGPT. Per esempio il nero alle spalle o un'ombra vicino a una giuntura (con
   l'apprendista: le spalline del busto).
7. **I PNG si fanno solo dagli SVG** (`_col.png`) e il taglio parte da lì.
8. **Teste senza collo dal foglio `3_teste`:** `taglia.py --teste 3_teste_col.png`. Niente
   taglio del collo a script: il collo è del busto.
9. **Taglio** `taglia.py 4_corpo_col.png --nome favilla --categoria personaggio --allinea
   --senza ala --teste 3_teste_col.png --tavolozza ...`, poi `--aggiungi --pugni
   5_braccia_chiuse_col.png`. I pugni si portano all'altezza delle braccia aperte.
   Ogni disegno è una versione numerata (busto_1, testa_colpita_1…) e nell'editor si sceglie
   quale va in scena. La coda è divisa in segmenti, ognuno col suo SVG (bordo e colore).
10. **Editor** ripubblicato coi pezzi in SVG; Sergio la prova animata (specchio, perni,
    radice della coda tornano con "Manda a Claude" e `taglia.py --ritocchi`).
11. **Simulazione** con `imposta prova_pelli favilla` e foto. Nel gioco prende il posto della
    Favilla provvisoria (l'apprendista col nome azzurro) nel cortile, nella Forgia e nel
    Duello.

---

## Decisione

Approvata da Claude, 2026-11-04: è il passo «WB-013, i pezzi di Favilla sullo stampino» del
piano dei livelli approvato da Sergio il 3 novembre («d'accordo con tutto»); reversibile (il
gioco non cambia finché non si tagliano). Scelta di Claude: niente colore della squadra su
Favilla (la targa basta); se in partita non si capisce di che squadra è, si aggiunge su un
dettaglio.

## Consegna di Codex

Fase 1: due esecuzioni sul ramo `design/WB-013` (`cb7fb8b`, `9d3514f`), tutte e due scartate
da Codex: secondo lui le sfumature, il corpo un po' più slanciato dell'apprendista e lo stivale
lontano girato verso chi guarda erano difetti.

### Fase 1 · 2026-11-04

Eseguita la sola fase 1 approvata, da `main` al commit `fbc3c4a`, sul ramo `design/WB-013`. Generatore integrato imagegen; prompt integrali invariati e riferimenti allegati nell'ordine della tabella. Nessun intervento su fase 2, ricalco, taglio o gioco.

**Tre risultati non conformi**, conservati solo come scarti documentati in `art/WB-013/scartati/fase1/`; non sono modelli approvati da usare per la fase 2. Ogni PNG ha il `.txt` con prompt integrale e riferimenti.

| File nella cartella degli scarti | Misura effettiva | Tentativi completati | Esito |
|---|---|---:|---|
| `1_tre_quarti_1.png`, `1_tre_quarti_1.txt` | 1024×1536 | 3 | SCARTATA |
| `1_tre_quarti_2.png`, `1_tre_quarti_2.txt` | 1024×1536 | 3 | SCARTATA |
| `2_espressioni.png`, `2_espressioni.txt` | 1254×1254 | 3 | SCARTATA |

- Guardate tutte le generazioni. Per ogni risultato conservato il terzo tentativo, senza ritocchi, ridimensionamenti o modifiche al prompt. I tentativi precedenti mostravano gli stessi problemi di sfumature; una chiamata del secondo tre quarti è stata interrotta dall'utente, senza risultato mostrato, e non è conteggiata fra i tre tentativi completati.
- **Tre quarti:** presenti fiamma bianco-azzurra con punte dorate, corna, ciglia, muso pergamena, camicia e salopette, grembiule, stivali, mani aperte vuote e coda intera. Assenti ali, utensili, colore di squadra, testo e firma. Nessun pezzo tagliato dal bordo. La punta della coda somiglia al modello, con attacco nell'incavo e punta in fuori: la valutazione finale della forma spetta a Claude.
- **Difetti persistenti dei tre quarti:** sfumature su pelle, fiamma e abiti, più toni e riflessi oltre alle ombre nette ammesse; figura più slanciata del corpo tozzo di R3; il piede a sinistra nell'immagine resta quasi frontale anziché puntare chiaramente a destra. La gerarchia arto vicino/lontano non è una copia affidabile della vista richiesta. Non soddisfano i vincoli per il ricalco.
- **Espressioni:** nove teste separate in griglia 3×3, verso destra, nell'ordine richiesto: sorriso, colpita, vittoria, stordita, mira, rabbia, sconfitta, paura, linguaccia. Nessun corpo, testo o firma; fiamme intere dentro il foglio. Restano sfumature, ombre sul moncone del collo e bordi neri laterali che arrivano al fondo anziché sparire gradualmente. Il collo non è uniforme come richiesto; sagoma e fiamma variano leggermente tra le teste. Non conforme anche dopo tre tentativi.
- **Dimensioni:** tre quarti conformi a 1024×1536; espressioni native a 1254×1254 anziché 1536×1536 o 1024×1024. Sfondo visivamente bianco opaco; non certificato #FFFFFF uniforme al pixel, né esattezza della tavolozza o nero #000000 su tutti i contorni.
- Verificate intestazioni e dimensioni dei PNG e corrispondenza integrale dei prompt salvati con la scheda. Non verificati ricalco SVG, taglio, giunture animate, leggibilità a 90 px o resa nel gioco. Criteri lasciati non spuntati. Mancano risultati conformi da scegliere: raggiunto il limite di tre tentativi per ciascuna immagine.
- La riga del 4 novembre in `DECISIONI.md` dice coda detta due volte, mentre i prompt approvati della scheda la richiamano una volta come il modello: segnalata la differenza, eseguiti i prompt senza modificarli.

### Fase 1 · Seconda esecuzione richiesta da Sergio

2026-11-04 · Riletto `main` aggiornato a `d50b7ea`: scheda APPROVATA, prompt e riferimenti della fase 1 invariati. Aggiornato `design/WB-013` con main preservando la consegna precedente. Nuova esecuzione con imagegen integrato, prompt integrali invariati e riferimenti nell'ordine della tabella.

Nove generazioni completate: tre tentativi per ciascuno dei tre risultati richiesti. Guardate tutte; conservato il terzo tentativo di ogni risultato, senza sovrascrivere gli scarti della prima esecuzione. **Anche questa esecuzione non produce risultati conformi.**

| File in `art/WB-013/scartati/fase1_ripetizione2/` | Misura effettiva | Tentativi | Esito |
|---|---|---:|---|
| `1_tre_quarti_1.png` e `1_tre_quarti_1.txt` | 1024×1536 | 3 | SCARTATA |
| `1_tre_quarti_2.png` e `1_tre_quarti_2.txt` | 1024×1536 | 3 | SCARTATA |
| `2_espressioni.png` e `2_espressioni.txt` | 1254×1254 | 3 | SCARTATA |

- Tre quarti: figura intera verso destra, coda visibile con punta simile al modello, fiamma bianco-azzurra e oro, abiti pergamena, grembiule, stivali e mani vuote. Nessuna ala, scritta, firma, utensile o colore di squadra. Restano sfumature su pelle, fiamma e vestiti; corpo più slanciato di R3 e stivale a sinistra quasi frontale. Non rispettano tutti i vincoli di colori piatti e posa. Per la forma della punta della coda resta la valutazione di Claude prevista nella scheda.
- Espressioni: nove teste separate, in griglia 3×3 e nell'ordine richiesto, fiamme intere, nessun testo o firma. Il primo tentativo aveva anche tratteggi; il terzo conserva sfumature e ombre sul collo, bordi laterali neri fino alla base e variazioni di sagoma/fiamma. Il collo non è uniforme e il bordo non si assottiglia come richiesto. Misura nativa 1254×1254 non prevista dalla tabella.
- Controllati visivamente bordi, parti mancanti e tagli accidentali: nessun difetto macroscopico di quel tipo nei file conservati. Verificati intestazioni PNG, dimensioni e corrispondenza integrale dei prompt nei `.txt`. Originali opachi senza ritocchi, ricalchi, ritagli o ridimensionamenti.
- Non certificati tavolozza, nero e bianco esatti al pixel; non verificati ricalco SVG, giunture animate, leggibilità a 90 px o resa nel gioco. Nessuna fase 2 eseguita. Criteri non spuntati e nessun modello conforme proposto per la scelta.

### Fase 2 · Consegna di Codex

2026-11-04 · Eseguita la fase 2 dalla scheda APPROVATA di `main` al commit `c4331fb`, con R6/R7 scelti e R8 aggiunto per il formato delle teste. Generatore integrato imagegen; tre prompt integrali invariati, riferimenti nell'ordine della tabella. `4_corpo.png` generato e salvato prima di allegarlo alle braccia chiuse.

| File in `art/WB-013/` | Misura effettiva | Tentativi | Esito |
|---|---|---:|---|
| `3_teste.png` e `3_teste.txt` | 1254×1254 | 1 | da revisione |
| `4_corpo.png` e `4_corpo.txt` | 1536×1024 | 1 | da revisione |
| `5_braccia_chiuse.png` e `5_braccia_chiuse.txt` | 1536×1024 | 1 | da revisione |

- Guardate tutte e tre le immagini prima del salvataggio. Nessuna scritta, firma, ala, utensile o parte accidentalmente tagliata dal bordo. Sfondo magenta opaco; nessun ritocco, ricalco, ridimensionamento o taglio effettuato da Codex.
- **Teste:** nove teste separate in griglia 3×3, verso destra, senza collo o moncone, contorno nero chiuso sotto mento e mandibola. Espressioni nell'ordine richiesto, fiamme intere. Sagoma, fiamma e dettagli non sono geometricamente identici fra le celle. Misura nativa 1254×1254 invece di 1536×1536 o 1024×1024.
- **Corpo:** prima riga vuota, torso e coda nella seconda, posto dell'ala vuoto; due braccia aperte, due gambe e pugno separato nella terza. Entrambi gli stivali puntano a destra. Coda continua, con punta simile a R6. Posizioni coerenti con i posti dello stampino, ma canvas a 1536×1024 anziché 3072×2048 di R4: soddisfa il minimo, non replica la risoluzione del riferimento. Non verificato l'allineamento esatto dei perni.
- **Giunture del corpo:** apici di braccia, gambe e radice della coda con aperture del contorno; restano bordi neri ai lati e ombre vicine ad alcune estremità. Spalle del torso arrotondate, ancora sporgenti, con nero e ombre da rivedere; colore non certificato uniforme in tutte le aree di sovrapposizione. Segnalato per il passaggio di ricalco e ritocchi descritto nella scheda.
- **Braccia chiuse:** due braccia complete affiancate, maniche arrotolate, pugni chiusi e nocche rivolte a destra. Apici delle spalle senza linea trasversale, con nero che termina lateralmente; restano sfumature sulle maniche e sugli avambracci. Le due sagome sono molto simili: distinzione vicino/lontano e dimensione rispetto alle braccia del corpo da verificare nel montaggio. Non certificate quattro dita anatomicamente distinguibili in ogni pugno.
- Presenti sfumature e toni intermedi: consegnati gli originali alla revisione, seguendo il chiarimento di Claude sulle scelte di Sergio (le sfumature si eliminano nel ricalco a tavolozza fissa e le giunture si ritoccano nel passaggio successivo). Nessuna dichiarazione che tutti i vincoli di colori piatti e giunture siano soddisfatti. Nessuna rigenerazione per questi aspetti già demandati al ricalco.
- Verificate intestazioni PNG, dimensioni e corrispondenza integrale dei prompt nei `.txt`. Non certificati #FF00FF uniforme, contorni #000000 e tavolozza al pixel; non verificati ricalco, taglio, perni, giunture animate, leggibilità a 90 px o resa nel gioco. Criteri lasciati non spuntati per Claude e Sergio.
- Merge della scheda: conservati integralmente sia il riepilogo di Claude sia le precedenti consegne di Codex nella sezione di consegna; il resoconto e i prompt di Claude restano quelli aggiornati su main.

## Resoconto di Claude

### Fase 1 · scelte di Sergio (2026-11-04)

- **Tre quarti: A**, cioè `scartati/fase1/1_tre_quarti_1.png` del ramo `design/WB-013`.
  Pagina delle scelte: https://claude.ai/artifact/KN8ENwzwfcznhMJhBV2jNd. Salvato in
  `art/WB-013/scelti/tre_quarti.png` (R6).
  - Le sfumature spariscono nel ricalco coi colori fissi.
  - Lo stivale lontano, girato verso chi guarda, si corregge nei pezzi: `4_corpo` chiede tutti
    e due gli stivali a destra.
  - Il corpo un po' più slanciato dell'apprendista va bene a Sergio.
  - La coda è giusta: cuore capovolto come nel modello.
- **Espressioni:** il foglio dello stesso giro, `scartati/fase1/2_espressioni.png`, salvato in
  `art/WB-013/scelti/espressioni.png` (R7). È una scelta di Claude: i due fogli sono quasi
  uguali e questo è dello stesso giro del tre quarti.
- **Teste senza collo e col contorno chiuso** (Sergio): `3_teste` le rifà come le nove teste
  dell'apprendista, con quelle (R8) come esempio del formato.
- Fase 2 pronta: `esegui WB-013 fase 2`.

### Fase 2 · revisione e taglio (2026-11-04)

Guardati i tre fogli di `b535f6d`: **tutti e tre buoni**, nessuno scartato.

- **Teste:** le nove espressioni giuste, nell'ordine giusto, senza collo e col contorno chiuso.
  La fiamma cambia appena da una testa all'altra (i fogli non sono identici al pixel): cambiando
  faccia si vede un piccolo guizzo della fiamma, che per una fiamma va bene. Tenute.
- **Corpo:** busto, coda, braccia, gambe e pugno ai loro posti; stivali tutti e due a destra; la
  coda col cuore capovolto come nel modello. Le spalle del busto sporgono un po' (sono le maniche
  a sbuffo): coperte dal braccio davanti, quella dietro sta sotto il braccio dietro. Nessun
  ritocco a mano per ora: si vede nelle foto e si decide con Sergio nell'editor.
- **Braccia chiuse:** due braccia col pugno quasi uguali (davanti e dietro): vanno bene, nel gioco
  quello dietro si scurisce.
- **Sfumature e granelli** ovunque (pelle, camicia, stivali): li toglie il ricalco.

Ricalco (`vettoriale.py`, tavolozza `strumenti/stampino/tavolozze/favilla.json`), con quattro
regole nuove, tutte nella tavolozza o nella riga di comando, così l'apprendista resta com'è:

1. `--senza`: i colori che in un foglio non ci sono. Nel foglio delle teste niente camicia,
   bretelle, bottoni, stivali; nel corpo niente muso, corna, fiamma, occhi, bocca, bianco. Così i
   toni del muso non diventano camicia e quelli della camicia non diventano muso o corna.
2. `macchie_min` 300 e `macchie_ombra_min` 1500 (pixel del foglio largo 3072): le macchioline
   prendono il colore intorno, mai il nero. Senza, gli stivali e la coda erano a chiazze.
3. `righe_max` 80: i marroni scuri degli stivali e dell'ombra delle bretelle non diventano righe
   nere (lo facevano con la soglia dell'apprendista, 110).
4. Un giallo della tavolozza che non è l'occhio (bottoni, punte della fiamma) resta suo.

**Colori degli stivali cambiati** (scelta di Claude): ChatGPT li ha disegnati più chiari della
scheda (circa `#8A5028`); con `#6B3F22` diventavano una macchia scura. Ora `#8A5228`, ombra
`#6B3F22`.

Taglio: `taglia.py` come scritto sopra (`--teste`, poi `--aggiungi --pugni`). Pelle `favilla`:
busto, braccia (aperte e col pugno), gambe, coda in cinque segmenti, pugno e nove facce, ognuno
col suo SVG in `strumenti/stampino/pelli/svg/`; gli SVG dei fogli in `art/WB-013/svg/`. Trovato
e corretto un errore di `taglia.py`: rifacendo la pelle `favilla` cancellava anche i file di
`favilla_1` e `favilla_2` (le pelli a pezzi liberi), che cominciano con lo stesso nome.

Nel gioco: Favilla veste i suoi pezzi nel cortile (la comparsa) e nel Duello (il robot
avversario, con `pelle = "favilla"` nella missione: solo disegno, la simulazione non cambia). Il
nome azzurro sopra la testa resta. Editor ripubblicato (versione 43) con la pelle `favilla`:
https://claude.ai/artifact/YJeMenvfJLGmto89yAbKJ5 . Scenari `favilla.txt` (fermo, corsa,
salto, mira, rinculo) e `favilla_duello.txt`.
