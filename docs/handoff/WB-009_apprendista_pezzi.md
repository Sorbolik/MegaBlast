# WB-009 · L'apprendista: tre quarti, espressioni e pezzi sullo stampino

- **Stato:** APPROVATA
- **Data:** 2026-11-01
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-009`

## Obiettivo

Sergio ha scelto il protagonista **A, l'apprendista** della proposta WB-008
(https://claude.ai/artifact/JoPBZRtznYF3xGEao2pTXF). È il personaggio di tutti: ognuno lo
veste coi suoi pezzi di equipaggiamento, quindi deve essere un corpo base pulito e
leggibile. Questa scheda produce:

1. il modello di tre quarti verso destra, nello stile pulito del gioco (la vista con cui cammina);
2. la camminata di prova, per vedere che il tre quarti regge in movimento;
3. le espressioni;
4. il foglio dei pezzi sullo **stampino** (lo scheletro a ossa del diavoletto di inizio
   progetto, `strumenti/stampino/`), da tagliare con `taglia.py --allinea`;
5. le teste in più, per le espressioni che lo stampino non ha ancora.

Poi Claude ricalca i pezzi in **SVG** e da lì fa i PNG della misura giusta per ogni schermo
(vedi "Dopo le immagini").

È la prima scheda che segue la procedura standard dei personaggi, [PERSONAGGI.md](PERSONAGGI.md).
Favilla B (la fiamma bianca) si fa con le stesse regole, ma solo dopo che Sergio ha provato
l'apprendista animato nell'editor delle animazioni.

## Due fasi, due comandi

Il foglio dei pezzi deve copiare un tre quarti **approvato**, non uno qualsiasi: è la lezione
di WB-006 (prima il tre quarti, poi i pezzi).

- **Fase 1**, `esegui WB-009 fase 1`: immagini 1, 2 e 3. Sergio sceglie il tre quarti e le
  espressioni; Claude li salva in `art/WB-009/scelti/tre_quarti.png` e
  `art/WB-009/scelti/espressioni.png` su main.
- **Fase 2**, `esegui WB-009 fase 2`: immagini 4 e 5, coi due file scelti come riferimento.
- Codex esegue solo le righe della tabella della fase chiesta; se non le trova si ferma
  (il 2 novembre, senza questa scheda su main, aveva rifatto per conto suo ricalchi ed
  editor: lavoro di Claude, non integrato).
- **Fase 3**, `esegui WB-009 fase 3` (Sergio, 2026-11-02): immagini 6 e 7. Il 6 rifà il
  tre quarti con la gamba davanti girata a destra come quella dietro (così la gamba davanti
  dello stampino, che sta già lì, è coerente). Il 7 rifà tutte e nove le teste **senza collo
  e col contorno chiuso**, come se fossero ritagliate dal tre quarti. Sergio sceglie il tre
  quarti; Claude lo salva in `art/WB-009/scelti/tre_quarti_gamba.png` su main.
- **Fase 4**, `esegui WB-009 fase 4`: immagini 8 e 9, dal tre quarti nuovo. Il foglio della
  fase 2 si era allontanato dal tre quarti (busto a uovo con le spalline, gambe grosse, coda
  a U): l'8 rifà solo il corpo, copiato forma per forma; le teste sono quelle del 7. Il 9 sono
  le braccia con la mano chiusa, per le impugnature delle armi.

## Cosa teniamo e cosa scartiamo

| Teniamo | Perché |
|---|---|
| Diavoletto piccolo e tozzo, testa grande, pelle rosso mattone, pancia e muso pergamena | è A di WB-008, scelto da Sergio; si stacca da ogni fondo (prova a 90 px) |
| Corna corte color osso, orecchie a punta, occhi gialli, ghigno furbo | il carattere dell'apprendista; le corna servono alle sette crepe del purgatorio |
| Coda sottile con la punta a freccia | la sagoma del diavoletto; sullo stampino è la coda intera |
| Fazzoletto al collo = colore della squadra | dipinto in verde #00FF00, che `taglia.py` trasforma nel colore della squadra |
| Mani a quattro dita, piedi nudi a tre dita | come in A |
| Contorno nero spesso, che si assottiglia e sparisce nelle giunture | richiesta di Sergio: nessuna riga nera dove due pezzi si sovrappongono |
| Colore uniforme vicino alle giunture, soprattutto sulla pelle scoperta | richiesta di Sergio: due pezzi di pelle sovrapposti devono sembrare una cosa sola |
| Tre quarti verso destra | è la vista dello stampino e quella con cui cammina |

| Scartiamo | Perché |
|---|---|
| Tratteggi da incisione, texture, sfumature, macchie di fuliggine | a misura di gioco diventano rumore e il ricalco in SVG viene sporco: solo colori piatti |
| La fiammella nei pezzi | la disegna il gioco (si anima e cresce nel proprio turno), non va nelle teste |
| Le ali | sono un pezzo d'equipaggiamento (schiena): il posto dell'ala resta vuoto |
| Vestiti di qualunque tipo | si parte senza niente: i vestiti sono equipaggiamento |
| Le forme del manichino grigio | lo stampino dice solo dove va ogni pezzo e quanto è grande (lezione di WB-001) |
| Il foglio a pezzi liberi (P-007) | bocciato da Sergio una volta animato: si usa lo stampino |
| Il colore della squadra sul corpo o sulla fiammella | un corpo tinto sparisce nei gironi rossi; basta il fazzoletto |
| Chiedere a ChatGPT l'SVG direttamente | i vettoriali disegnati "a codice" vengono storti (come quelli di Claude): si ricalca il disegno buono |

## La tavolozza (uguale in ogni prompt)

Pochi colori piatti, così il ricalco in SVG è pulito e ogni colore diventa uno strato.

| Parte | Colore | Ombra |
|---|---|---|
| contorno | nero `#000000` | |
| pelle | `#B8432A` | `#8E2F1C` |
| pancia e muso | `#F1DFB0` | `#D6BC86` |
| corna, unghie | `#EFE3C8` | `#C9B48E` |
| occhi | `#F2C45A`, pupille `#000000`, lucina `#FFFFFF` | |
| bocca dentro | `#5A1A10`, denti `#FFFFFF`, lingua `#E0605A` | |
| fazzoletto (squadra) | `#00FF00` | `#00B400` |
| sfondo | bianco `#FFFFFF` (fase 1), magenta `#FF00FF` (fase 2) | |

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-009/riferimenti/R1_apprendista_concept.png` | l'apprendista scelto (concept): la figura in mezzo è di tre quarti |
| R2 | `art/WB-009/riferimenti/R2_stampino_ai.png` | lo stampino di oggi (12 posti, rifatto con `stampino.py` il 1 nov): dove sta ogni pezzo (3072×2048) |
| R3 | `art/WB-009/riferimenti/R3_manichino.png` | come si attaccano i pezzi |
| R4 | `art/WB-009/scelti/tre_quarti.png` | il tre quarti scelto in fase 1 (c'è solo dopo la fase 1) |
| R5 | `art/WB-009/scelti/espressioni.png` | le espressioni scelte in fase 1 (c'è solo dopo la fase 1) |
| R6 | `art/WB-009/scelti/mira.png` | la faccia della mira scelta da Sergio (5 del foglio): si tiene la faccia, il collo va stretto come nelle altre teste |
| R7 | `art/WB-009/scelti/tre_quarti_gamba.png` | il tre quarti con la gamba davanti girata a destra, scelto in fase 3 (c'è solo dopo la fase 3) |

## Immagini da generare

Ogni prompt è completo e va usato così com'è, in inglese perché il generatore lo segue meglio.
Allega i riferimenti nell'ordine scritto: il primo è "image 1", il secondo "image 2" e così via.

| Fase | Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|---|
| 1 | `1_tre_quarti` | R1 | 1024×1536 verticale | 2 |
| 1 | `2_camminata` | R1 | 1536×1024 | 1 |
| 1 | `3_espressioni` | R1 | 1536×1536 (o 1024×1024) | 1 |
| 2 | `4_foglio_pezzi` | R4, R2, R3, R5 | 3:2 orizzontale, la più grande possibile (ideale 3072×2048, minimo 1536×1024) | 1 |
| 2 | `5_teste_extra` | R4, R5, R6 | 1536×1024 | 1 |
| 3 | `6_tre_quarti` | R4 | 1024×1536 verticale | 2 |
| 3 | `7_teste` | R4, R5, R6 | 1536×1536 (o 1024×1024) | 1 |
| 4 | `8_corpo_fedele` | R7, R2, R3 | 3:2 orizzontale, la più grande possibile (minimo 1536×1024) | 1 |
| 4 | `9_braccia_chiuse` | R7, `art/WB-009/8_corpo_fedele.png` | 1536×1024 | 1 |

Sfondo **non** trasparente (eccezione alla regola di `AGENTS.md`): bianco pieno in fase 1,
magenta pieno `#FF00FF` in fase 2 perché lo usa lo strumento di taglio. Il verde `#00FF00`
non è uno sfondo: è il fazzoletto, e non va tolto.

### `1_tre_quarti`

```
Image 1 shows the main character of our game, a little blacksmith-apprentice imp, three times. The MIDDLE figure is a three-quarter view facing right: that is the view we need. Image 1 is the only reference for his shapes and proportions: small and stocky, big round head (about one third of his height), two short bone-colored horns curving slightly forward, pointed ears, big yellow eyes with black pupils, a sly closed-mouth grin, brick-red skin with a parchment-colored belly and muzzle, four-fingered hands, bare feet with three stubby toes, a long thin tail with an arrowhead tip, a neckerchief knotted around his neck. Keep his character; change only the rendering, as described below.

Draw him ONCE, full body, in a clean THREE-QUARTER VIEW FACING RIGHT, standing still in a neutral, relaxed pose: weight on both feet, legs slightly apart, both arms hanging loosely a little away from the body with open relaxed hands, the near arm and near leg (on the right of the picture) fully visible, the far arm and far leg (on the left) partly behind the body, the tail coming out from behind his lower back and curving up behind him on the left, fully visible from root to tip. The face is turned to the right in three-quarter view: the far eye is a bit narrower than the near eye. Do NOT draw any flame on his head and no wings: the game adds the flame itself. He wears nothing but the neckerchief.

Rendering rules, very strict, because this drawing will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone listed below. No gradients, no textures, no hatching, no brush strokes, no soot, no noise, no soft shading, no glow.
- Thick, clean, closed pure-black #000000 outline of even weight around the whole figure, with thinner black lines only for inner details (eyes, mouth, fingers, belly edge).
- Use ONLY these colors: outline and pupils black #000000; skin #B8432A, skin shadow #8E2F1C; belly and muzzle #F1DFB0, their shadow #D6BC86; horns and toenails #EFE3C8, their shadow #C9B48E; eyes #F2C45A with a small white #FFFFFF highlight; inside of mouth #5A1A10, teeth white #FFFFFF; neckerchief pure bright green #00FF00 with shadow #00B400 (the green is the team color: use it ONLY on the neckerchief).
- Flat pure white #FFFFFF background, no ground, no shadow on the ground, nothing else in the picture.
- No text, numbers, labels, arrows or signatures. Portrait format 2:3.
```

### `2_camminata`

```
Image 1 shows the main character of our game, a little blacksmith-apprentice imp; the MIDDLE figure is a three-quarter view facing right. Keep exactly his shapes and proportions: small and stocky, big round head (about one third of his height), two short bone-colored horns, pointed ears, big yellow eyes, sly grin, brick-red skin with a parchment-colored belly and muzzle, four-fingered hands, bare three-toed feet, a long thin tail with an arrowhead tip, a neckerchief.

Draw a WALK CYCLE of him walking to the right, in three-quarter view facing right, as FOUR separate figures in a row from left to right, all the same size, well apart, feet on the same invisible ground line: 1) contact: near leg forward with the heel touching the ground, far leg back, arms swinging opposite to the legs; 2) passing: weight on the near leg, the far leg lifting and passing beside it, body slightly higher; 3) contact with the other leg: far leg forward, near leg back, arms swinging the other way; 4) passing on the other leg. The tail sways a little behind him. Cheerful, bouncy, a bit cocky. No flame on his head, no wings; he wears nothing but the neckerchief.

Rendering rules, very strict, because these drawings will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone listed below. No gradients, no textures, no hatching, no brush strokes, no soot, no soft shading, no glow.
- Thick, clean, closed pure-black #000000 outline around each figure, thinner black lines only for inner details.
- Use ONLY these colors: outline and pupils black #000000; skin #B8432A, skin shadow #8E2F1C; belly and muzzle #F1DFB0, their shadow #D6BC86; horns and toenails #EFE3C8, their shadow #C9B48E; eyes #F2C45A with a small white #FFFFFF highlight; inside of mouth #5A1A10, teeth white #FFFFFF; neckerchief pure bright green #00FF00 with shadow #00B400 (only on the neckerchief).
- Flat pure white #FFFFFF background, no ground, no shadows on the ground.
- No text, numbers, labels, arrows or signatures. Landscape 3:2.
```

### `3_espressioni`

```
Image 1 shows the main character of our game, a little blacksmith-apprentice imp; the MIDDLE figure is a three-quarter view facing right. Keep exactly his head: big and round, two short bone-colored horns curving slightly forward, pointed ears, big yellow eyes with black pupils, brick-red skin, parchment-colored muzzle.

Draw an EXPRESSION SHEET: NINE copies of his head only (with a short neck stub, no body), all in three-quarter view facing right, all the same size, in a 3 by 3 grid, well apart from each other. The head outline, horns and ears are IDENTICAL in all nine: only the eyes, eyebrows and mouth change (the ears may tilt slightly). No flame on the head.
Row 1: 1) SLY: his default face, a confident closed-mouth grin, one eyebrow slightly raised; 2) HIT: just hit and in pain, eyes squeezed shut like > <, mouth open in a jagged shape; 3) VICTORY: eyes closed in happy upside-down arcs, big open laughing mouth showing teeth.
Row 2: 4) KNOCKED OUT: dizzy spiral pupils, wobbly wavy mouth, tongue slightly out; 5) AIMING: focused, near eye wide open and far eye squinting, lips pressed, tip of the tongue sticking out of the corner of the mouth; 6) ANGRY: eyebrows down in a V, teeth clenched in a snarl.
Row 3: 7) DEFEATED: sad, eyebrows up in the middle, eyes looking down, small downturned mouth; 8) SCARED: eyes wide with tiny pupils, mouth a small open oval, eyebrows high; 9) TAUNT: one eye closed in a wink, tongue sticking out cheekily.

Rendering rules, very strict, because these drawings will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone listed below. No gradients, no textures, no hatching, no soft shading, no glow.
- Thick, clean, closed pure-black #000000 outline around each head, thinner black lines only for inner details. The bottom end of the neck stub has NO black outline: the outline gets thinner as it reaches the stub's lower end and stops, and the skin color runs right to the edge. The skin near the bottom of the neck stub is PERFECTLY UNIFORM plain #B8432A: no shadow, no highlight, no line there.
- Use ONLY these colors: outline and pupils black #000000; skin #B8432A, skin shadow #8E2F1C; muzzle #F1DFB0, its shadow #D6BC86; horns #EFE3C8, their shadow #C9B48E; eyes #F2C45A with a small white #FFFFFF highlight; inside of mouth #5A1A10, teeth white #FFFFFF, tongue #E0605A.
- Flat pure white #FFFFFF background.
- No text, numbers, labels, arrows or signatures. Square format.
```

### `4_foglio_pezzi`

```
Image 1 is the main character of our game, a little blacksmith-apprentice imp, in a three-quarter view facing right. It is the EXACT model: copy his shapes, proportions, colors and flat style; do not reinterpret him. Image 4 is his approved expression sheet.

Image 2 is a layout sheet: 12 grey placeholder parts on a flat magenta #FF00FF background, in three rows. Use image 2 ONLY to know where each part goes on the sheet, roughly how big it is and where it attaches. Do NOT copy the grey parts' shapes, faces, visor, horns, wing, belt or flat grey style. Image 3 shows how the grey parts attach to each other.

Make the PARTS SHEET of the imp of image 1, cut apart like a paper puppet: same canvas as image 2, same flat magenta #FF00FF background, each part placed over its grey placeholder and about the same size. Nothing else may remain on the sheet: no grey placeholders, no labels, no text, no numbers, no shadows on the magenta. Every part is drawn as it looks in image 1 (three-quarter view facing right), COMPLETE even where other parts would hide it, and well separated from the other parts (no part touches another).

OUTLINE AND JOINTS, very important: every part has a thick, clean pure-black #000000 outline, EXCEPT at its joint ends, where it slides under or over another part. At a joint end the black outline gets gradually thinner as it approaches the end and disappears completely; the last stretch of the part is filled with its flat color right to the edge, rounded and full, with NO black line across it. Joint ends are: the bottom of each neck stub; the neck opening and the two shoulders of the torso; the top of each arm (shoulder end); the top of each leg (hip end); the root of the tail (the end attached to the body). Everywhere else the outline stays thick and even. The color near every joint end must be PERFECTLY UNIFORM: plain base color only (skin #B8432A on bare skin), with no shadow shape, no highlight, no line and no color change in the last stretch before the joint, so that two overlapping parts of bare skin blend into one continuous surface with no visible seam. Keep any shadow shapes well away from the joint ends.

The parts, left to right:
Row 1: four heads of the imp of image 1, facing right, each with a short neck stub at the bottom, the head outline, horns and ears IDENTICAL in all four, no flame on top: head 1 = expression 1 of image 4 (sly grin); head 2 = expression 2 (hit, eyes squeezed shut > <, jagged open mouth); head 3 = expression 3 (victory, happy closed eyes, big laughing mouth); head 4 = expression 4 (knocked out, spiral pupils, wavy mouth).
Row 2: the torso alone (no head, no arms, no legs): chest and round belly with the parchment-colored belly patch, with the neckerchief knotted around the neck painted in pure bright green #00FF00 shaded only with #00B400, round full shoulders and a round closed bottom; then NOTHING where the grey wing is (leave that spot empty magenta: he has no wings); then the WHOLE TAIL in one piece, following the curve of the grey tail: one smooth continuous tube, thick at the root and thinner towards the tip, ending in its arrowhead tip, with no breaks, seams or joints along it.
Row 3: the near arm and the far arm, each a straight arm hanging down from a round shoulder end and ending in an OPEN relaxed four-fingered hand, palm towards us; the near leg and the far leg, each a straight leg, round at the hip end, ending in a bare three-toed foot pointing right; one closed four-fingered fist (a small round piece, outlined all around).

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone listed below. No gradients, no textures, no hatching, no soft shading, no glow.
- Use ONLY these colors: outline and pupils black #000000; skin #B8432A, skin shadow #8E2F1C; belly and muzzle #F1DFB0, their shadow #D6BC86; horns and toenails #EFE3C8, their shadow #C9B48E; eyes #F2C45A with a small white #FFFFFF highlight; inside of mouth #5A1A10, teeth white #FFFFFF, tongue #E0605A; neckerchief #00FF00 with shadow #00B400.
- The bright green #00FF00 is used ONLY on the neckerchief, nowhere else.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- Landscape 3:2, as large as possible.
```

### `5_teste_extra`

```
Image 1 is the main character of our game, a little blacksmith-apprentice imp, in a three-quarter view facing right: copy his head exactly (shape, horns, ears, colors, flat style). Image 2 is his approved expression sheet: nine heads in a 3 by 3 grid. Image 3 is the approved aiming face, cropped from image 2.

Draw FIVE heads of him in a single row, left to right, all the same size, all facing right in three-quarter view, each with a short neck stub at the bottom, well apart from each other, the head outline, horns and ears IDENTICAL in all five, no flame on top. They are expressions 5 to 9 of image 2, copied exactly: 1) AIMING: copy the face of image 3 exactly (yellow near eye looking right, far eye squeezed in a wink, tongue tip out of the corner of the mouth), but NOT its neck: in image 3 the neck is too wide; make the neck stub as NARROW as the necks of the other heads in image 2, the same width as the other four heads of this row; 2) ANGRY (eyebrows in a V, clenched teeth); 3) DEFEATED (sad, eyes down, downturned mouth); 4) SCARED (wide eyes, tiny pupils, small open mouth); 5) TAUNT (wink and tongue out).

Each head has a thick, clean pure-black #000000 outline, EXCEPT at the bottom of the neck stub: there the outline gets gradually thinner and disappears, and the skin color runs right to the edge, rounded and full, with no black line across it. The skin near the bottom of the neck stub is PERFECTLY UNIFORM plain #B8432A: no shadow, no highlight, no line there, so the neck blends into the torso with no visible seam.

Rendering rules, very strict, because these heads will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone listed below. No gradients, no textures, no hatching, no soft shading, no glow.
- Use ONLY these colors: outline and pupils black #000000; skin #B8432A, skin shadow #8E2F1C; muzzle #F1DFB0, its shadow #D6BC86; horns #EFE3C8, their shadow #C9B48E; eyes #F2C45A with a small white #FFFFFF highlight; inside of mouth #5A1A10, teeth white #FFFFFF, tongue #E0605A.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the heads.
- No text, numbers, labels, arrows or signatures. Landscape 3:2.
```

### `6_tre_quarti`

```
Image 1 is the main character of our game, a little blacksmith-apprentice imp, in a three-quarter view facing right. It is the EXACT model: redraw image 1 as it is, with the same head, face, horns, ears, neckerchief, torso, belly patch, arms, hands, tail, proportions, contours, colors and flat style, in the same pose and the same place on the canvas.

Change ONE thing only: the leg on the LEFT of the picture. In image 1 its foot points to the left. Turn that leg so that its foot points to the RIGHT, exactly like the foot of the other leg (the one on the right of the picture): same direction, same three-quarter angle, same shape of the foot and of the three toes, so that both feet point to the right like a figure standing and facing right. The leg keeps its length, thickness and position under the body; only its knee and foot turn to the right. Everything else stays exactly as in image 1.

Rendering rules, very strict, because this drawing will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone listed below. No gradients, no textures, no hatching, no brush strokes, no soot, no noise, no soft shading, no glow.
- Thick, clean, closed pure-black #000000 outline of even weight around the whole figure, with thinner black lines only for inner details.
- Use ONLY these colors: outline and pupils black #000000; skin #B8432A, skin shadow #8E2F1C; belly and muzzle #F1DFB0, their shadow #D6BC86; horns and toenails #EFE3C8, their shadow #C9B48E; eyes #F2C45A with a small white #FFFFFF highlight; inside of mouth #5A1A10, teeth white #FFFFFF; neckerchief pure bright green #00FF00 with shadow #00B400 (only on the neckerchief).
- Flat pure white #FFFFFF background, no ground, no shadow on the ground, no glow around the figure.
- No text, numbers, labels, arrows or signatures. Portrait format 2:3.
```

### `7_teste`

```
Image 1 is the main character of our game, a little blacksmith-apprentice imp, in a three-quarter view facing right: copy his head exactly (shape, horns, ears, muzzle, colors, flat style). Image 2 is his approved expression sheet: nine heads in a 3 by 3 grid. Image 3 is the approved aiming face, cropped from image 2.

Draw NINE heads of him in a 3 by 3 grid, all the same size, all facing right in three-quarter view, well apart from each other, the head outline, horns and ears IDENTICAL in all nine, no flame on top. They are the nine expressions of image 2, in the same order, copied exactly. Row 1: 1) SLY (his default confident closed-mouth grin), 2) HIT (eyes squeezed shut > <, jagged open mouth), 3) VICTORY (happy closed eyes, big laughing mouth). Row 2: 4) KNOCKED OUT (spiral pupils, wavy mouth, tongue slightly out), 5) AIMING (copy the face of image 3 exactly: yellow near eye looking right, far eye squeezed, tongue tip out of the corner of the mouth), 6) ANGRY (eyebrows in a V, clenched teeth). Row 3: 7) DEFEATED (sad, eyes down, downturned mouth), 8) SCARED (wide eyes, tiny pupils, small open mouth), 9) TAUNT (wink and tongue out).

NO NECK AT ALL, very important: each head is drawn exactly as if it had been cut out of image 1 along the outline of the head. It ends at the chin and at the back of the jaw: nothing below them, no neck, no neck stub, no neckerchief. The thick black #000000 outline is CLOSED all around each head, also under the chin, under the muzzle and under the back of the jaw, smooth and even, following the round shape of the head in image 1.

Rendering rules, very strict, because these heads will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone listed below. No gradients, no textures, no hatching, no soft shading, no glow.
- Use ONLY these colors: outline and pupils black #000000; skin #B8432A, skin shadow #8E2F1C; muzzle #F1DFB0, its shadow #D6BC86; horns #EFE3C8, their shadow #C9B48E; eyes #F2C45A with a small white #FFFFFF highlight; inside of mouth #5A1A10, teeth white #FFFFFF, tongue #E0605A.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the heads.
- No text, numbers, labels, arrows or signatures. Square format.
```

### `8_corpo_fedele`

```
Image 1 is the main character of our game, a little blacksmith-apprentice imp, in a three-quarter view facing right. It is the EXACT model: every body part you draw must be COPIED from image 1, shape by shape, with the same proportions, the same thickness and the same contours. Do not invent, round off, fatten or simplify any part.

Image 2 is a layout sheet: grey placeholder parts on a flat magenta #FF00FF background, in three rows. Use image 2 ONLY to know where each part goes on the sheet and roughly how big it is. Do NOT copy the grey parts' shapes. Image 3 shows how the grey parts attach to each other.

Make the BODY PARTS SHEET of the imp of image 1, cut apart like a paper puppet, on the same canvas as image 2 with the same flat magenta #FF00FF background. Leave the WHOLE FIRST ROW EMPTY (pure magenta, no heads: the heads are already done). Draw only these parts, each over its grey placeholder, well separated from each other, each COMPLETE even where other parts would hide it in image 1:
Row 2: the TORSO of image 1 without head, arms, legs and tail: the same pear shape as in image 1, narrow at the chest and wider at the round belly, with the same parchment-colored belly patch, the neckerchief knotted around the neck painted in pure bright green #00FF00 shaded only with #00B400, and a short neck stub on top. NO shoulder bumps and no stubby arms: at each shoulder the torso simply ends with a smooth, round, full edge of plain skin. Then NOTHING where the grey wing is (leave that spot empty magenta: he has no wings). Then the WHOLE TAIL of image 1 in one piece, with the same S curve, the same thickness and the same arrowhead tip: one smooth continuous tube, thick at the root and thinner towards the tip, with no breaks, seams or joints along it.
Row 3: the near arm and the far arm, copied from image 1 (same slim shape, same open relaxed four-fingered hand), each straight and hanging down from a round shoulder end; the near leg and the far leg, copied from image 1 (same slim thigh and calf, same bare three-toed foot pointing right), each straight, round at the hip end; one closed four-fingered fist, the size of the hands in image 1 (a small round piece, outlined all around).

OUTLINE AND JOINTS, very important: every part has a thick, clean pure-black #000000 outline, EXCEPT at its joint ends. At a joint end the black outline gets gradually thinner and disappears completely; the last stretch of the part is filled with its flat color right to the edge, rounded and full, with NO black line across it. Joint ends are: the neck stub and the two shoulder edges of the torso; the top of each arm (shoulder end); the top of each leg (hip end); the root of the tail. The color near every joint end must be PERFECTLY UNIFORM plain skin #B8432A: no shadow, no highlight, no line, no color change in the last stretch before the joint, so that two overlapping parts of bare skin blend into one surface with no visible seam. Keep shadow shapes well away from the joint ends.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone listed below. No gradients, no textures, no hatching, no soft shading, no glow.
- Use ONLY these colors: outline black #000000; skin #B8432A, skin shadow #8E2F1C; belly #F1DFB0, its shadow #D6BC86; toenails #EFE3C8, their shadow #C9B48E; neckerchief #00FF00 with shadow #00B400.
- The bright green #00FF00 is used ONLY on the neckerchief, nowhere else.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels or signatures. Landscape 3:2, as large as possible.
```

### `9_braccia_chiuse`

```
Image 1 is the main character of our game, a little blacksmith-apprentice imp, in a three-quarter view facing right. Image 2 is his parts sheet: copy the arms of image 2 exactly (same length, thickness, contour, colors and flat style).

Draw TWO ARMS of him side by side, left to right, the same size as the arms in image 2, well apart from each other, on a flat pure magenta #FF00FF background: 1) the NEAR arm, 2) the FAR arm. Each arm is straight and hangs down from a round shoulder end, exactly like in image 2, but the hand is CLOSED IN A FIST as if gripping the handle of a tool: four fingers curled, the thumb wrapped over them, the knuckles towards the right. The fist is the same size as the open hands of image 2.

OUTLINE AND JOINTS, very important: each arm has a thick, clean pure-black #000000 outline, EXCEPT at the shoulder end at the top: there the outline gets gradually thinner and disappears completely, and the skin runs right to the edge, rounded and full, with no black line across it. The skin near the shoulder end is PERFECTLY UNIFORM plain #B8432A: no shadow, no highlight, no line there, so the arm blends into the torso with no visible seam. Keep shadow shapes well away from the shoulder end.

Rendering rules, very strict, because these arms will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no hatching, no soft shading, no glow.
- Use ONLY these colors: outline black #000000; skin #B8432A, skin shadow #8E2F1C.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the arms.
- No text, numbers, labels or signatures. Landscape 3:2.
```

## Criteri di accettazione

- [ ] è l'apprendista di R1: proporzioni, testa, corna, orecchie, coda a freccia, fazzoletto
- [ ] solo colori piatti della tavolozza, al massimo un'ombra netta per colore; niente tratteggi, texture, fuliggine
- [ ] contorno nero spesso e chiuso, tranne alle estremità delle giunture, dove si assottiglia e sparisce
- [ ] vicino alle giunture il colore è uniforme (pelle `#B8432A` piena): niente ombre, luci o righe, così due pezzi di pelle sovrapposti sembrano una cosa sola
- [ ] nessuna fiammella sulla testa, nessuna ala, nessun vestito oltre al fazzoletto
- [ ] il verde `#00FF00` solo sul fazzoletto
- [ ] tre quarti verso destra in tutte le immagini; nelle teste la sagoma è identica, cambia solo l'espressione
- [ ] fase 2: 11 pezzi sopra i 12 posti di R2 (posto dell'ala vuoto), nessun manichino grigio rimasto, sfondo magenta pieno senza aloni
- [ ] coda intera, liscia, più spessa alla radice, punta a freccia in fondo
- [ ] nessuna scritta, numero o firma
- [ ] fase 3: tre quarti identico a R4 tranne la gamba a sinistra, col piede girato a destra come l'altro
- [ ] fase 3: nove teste senza collo, contorno nero chiuso tutto intorno (anche sotto il mento), sagoma identica
- [ ] fase 4: busto a pera come nel tre quarti, senza spalline; gambe, braccia e coda copiate dal tre quarti; prima riga vuota
- [ ] fase 4: braccia col pugno chiuso, lunghe e grosse come quelle aperte, spalla senza contorno

## Dopo le immagini (lo fa Claude)

1. **Taglio.** `python3 strumenti/stampino/taglia.py art/WB-009/4_foglio_pezzi.png --nome apprendista --categoria personaggio --allinea --senza ala`:
   pezzi sullo scheletro, coda divisa in segmenti, fazzoletto nel colore della squadra.
2. **Vettoriale.** `strumenti/stampino/vettoriale.py` oggi ricalca solo il bianco e nero. Va
   esteso ai colori: ogni pixel va al colore più vicino della tavolozza qui sopra, ogni colore
   si ricalca con potrace in uno strato SVG, e gli strati si impilano dal fondo al contorno.
   Esce un SVG per pezzo, accanto al foglio. **Colori giusti ovunque (Sergio, 2026-11-02:
   «è troppo importante»):** negli SVG finali ogni riempimento è esattamente un codice della
   tavolozza, in tutti i pezzi e in tutte le teste, nessuna sfumatura rimasta da ChatGPT; uno
   script lo controlla e fallisce se trova un colore fuori tavolozza. I PNG si fanno solo da
   questi SVG. Scartato `vtracer`: raggruppa i colori da solo,
   li sposta dalla tavolozza e fa più nodi.
3. **PNG per ogni schermo.** Dagli SVG si fanno i PNG alla densità che serve (per esempio
   1×, 2× e 3× della misura del gioco, decisa con lo schermo vero); il gioco carica quella
   giusta. È codice nuovo, da fare in una PR a parte.
4. **Teste in più.** Lo stampino oggi ha quattro teste (normale, colpita, felice, ko). Le
   cinque di `5_teste_extra` (mira, arrabbiato, sconfitto, paura, provocazione) servono alle
   clip e alla scheda personaggio: aggiungere i posti è codice, in una PR a parte.
5. Prova nell'editor delle animazioni e in simulazione, foto nel resoconto.

Nel gioco, oggi, la fiammella ha il colore della squadra. Con il fazzoletto la squadra si vede
già, quindi la fiammella può tornare arancione: anche questa è una PR a parte.

---

## Decisione

Approvata da Claude, 2026-11-01: scelta reversibile (immagini da generare; il gioco non cambia
finché non si tagliano). Richiesta da Sergio nel thread "Ripensare i personaggi dalla
campagna": «concentriamoci su di loro ad uno ad uno, voglio che mi fai gli script da mandare a
chat dei pezzi di A, l'apprendista».

## Consegna di Codex

### Fase 1 · 2026-11-01

Eseguita dal `main` aggiornato, sul ramo `design/WB-009`. Generatore immagini usato con
R1 come unico riferimento, prompt inglesi della scheda copiati integralmente, senza
aggiunte o modifiche, sfondo non trasparente. Nessuna immagine della fase 2 generata;
nessun file in `scelti/` creato. La scelta del modello resta a Sergio.

| File consegnato | Misura effettiva | Tentativi | Esito |
|---|---|---|---|
| `art/WB-009/1_tre_quarti_1.png` | 1024×1536 | 3, consegnato il terzo | prova visiva, non conforme a tutti i criteri |
| `art/WB-009/1_tre_quarti_2.png` | 1024×1536 | 3, consegnato il terzo | prova visiva, non conforme a tutti i criteri |
| `art/WB-009/2_camminata.png` | 1536×1024 | 3, consegnato il terzo | ciclo non conforme: contatti ripetuti |
| `art/WB-009/3_espressioni.png` | 1254×1254 | 3, conservato il primo, più regolare | nove espressioni presenti, non conforme a tutti i criteri |

Accanto a ogni PNG c'è l'omonimo `.txt` con il prompt esatto e il riferimento usato.
Sono stati guardati tutti i risultati prima della copia nei file di consegna; nessun
ritocco, ricalco, ricampionamento o correzione della tavolozza applicato. I tentativi
successivi hanno mantenuto i difetti descritti sotto; raggiunto il limite di tre per
ciascun file, la consegna conserva le prove per revisione senza dichiararle approvate.

**Controlli visivi eseguiti.** Figure intere e distanziate, coda con punta presente e
non tagliata, contorno scuro spesso, tre quarti rivolto verso destra, fazzoletto verde
solo sul corpo; nessuna fiammella, ala, altro vestito, scritta, firma o numero.
Le nove espressioni sono nell'ordine richiesto e riconoscibili. Dimensioni e PNG RGB
senza trasparenza controllati leggendo i file.

**Problemi rimasti / criteri non soddisfatti.**

- Tutti i risultati mostrano leggere sfumature e variazioni di colore nelle aree che
  dovevano essere piatte. La tavolozza esadecimale non è rispettata in modo esatto;
  anche lo sfondo è quasi bianco, non bianco pieno: per esempio gli angoli superiori
  sinistri dei quattro PNG sono rispettivamente RGB (254,253,255), (253,255,255),
  (254,253,255), (253,253,253). Non sono pronti per il ricalco tecnico così come sono.
- Nei tre quarti la testa risulta più grande del terzo dell'altezza richiesto e
  la disposizione degli arti vicino/lontano non segue precisamente quella del prompt.
  La radice della coda è nascosta dal corpo: continuità visibile, attacco non verificabile.
- Nella camminata le pose 1 e 3 ripetono la stessa gamba avanti e le pose 2 e 4 sono
  molto simili: manca l'alternanza completa richiesta. I tre tentativi non l'hanno risolta.
- Nel foglio delle espressioni sagome, corna e orecchie variano leggermente fra le teste;
  i colli hanno ombra e linee laterali che non si assottigliano a sufficienza.
  Non è soddisfatto il requisito del fondo del collo uniforme in #B8432A.
- Il generatore ha restituito le espressioni a 1254×1254, formato quadrato ma diverso
  dalle due misure richieste (1536×1536 oppure 1024×1024). File originale conservato.

**Non verificato.** Nessun taglio, SVG, montaggio sullo scheletro o prova animata nel gioco:
sono le fasi successive affidate a Claude. Nessuna accettazione attribuita a Sergio.
La scheda approvata aggiorna il protagonista rispetto alle vecchie decisioni sul
personaggio con occhiali; la decisione del 2026-11-01 conferma l'apprendista, quindi
non è stato aggiunto alcun accessorio del vecchio diavoletto.

### Fase 2 · 2026-11-02

Eseguita dalla scheda APPROVATA aggiornata su `main` (a766e81), riportata nel ramo
`design/WB-009` conservando la consegna della fase 1. Usati i file scelti da Sergio,
compreso R6 per la mira; nessun riferimento scelto modificato.

| File | Riferimenti, nell'ordine passato al generatore | Misura effettiva | Tentativi |
|---|---|---|---|
| `art/WB-009/4_foglio_pezzi.png` | R4, R2, R3, R5 | 1536×1024 | 3, consegnato il terzo |
| `art/WB-009/5_teste_extra.png` | R4, R5, R6 | 1536×1024 | 3, consegnato il terzo |

Accanto ai PNG sono consegnati `4_foglio_pezzi.txt` e `5_teste_extra.txt`, con i prompt
integrali della scheda e i percorsi dei riferimenti in ordine. Verificato automaticamente
che i prompt salvati coincidano esattamente con i blocchi inglesi; usati senza aggiunte
anche nelle rigenerazioni. Sfondo non trasparente. File originali copiati dal generatore,
senza ritocchi, ricampionamento, rimozione del magenta o correzioni a codice.

**Controlli eseguiti.** Guardati tutti e tre i tentativi per ciascuna immagine.
Nel foglio sono presenti 11 pezzi separati in tre righe: quattro teste, busto e coda
con il posto dell'ala vuoto, due braccia, due gambe e un pugno. Nessun manichino grigio,
fiammella, ala, testo, numero o firma. Coda continua con punta a freccia, non tagliata.
Verde visibile soltanto sul fazzoletto. Cinque teste extra in una fila, rivolte a destra,
con mira, rabbia, sconfitta, paura e provocazione nell'ordine richiesto. La mira mantiene
occhio lontano chiuso, occhio vicino giallo e punta della lingua; il collo appare di
larghezza simile agli altri quattro, non quello largo di R6. Dimensioni e RGB senza
trasparenza verificati nei PNG.

**Difetti rimasti dopo il limite di tre tentativi: consegna per revisione, non piena
conformità tecnica.**

- Nel foglio la coda segue una U, con radice a sinistra e punta in alto a destra:
  non segue la curva/orientamento della coda di R2. Anche posizioni e ingombri dei
  pezzi non coincidono precisamente con lo stampino: non è verificata la tagliabilità.
- Busto e arti conservano ombre e/o contorno vicino ad alcune giunture; nei colli
  di entrambi i fogli resta ombra e le linee laterali arrivano troppo in basso.
  Non è raggiunto il requisito di pelle uniforme #B8432A e contorno che sparisce
  completamente nelle zone di sovrapposizione.
- Leggere sfumature, variazioni di colore e differenze fra sagome di teste/corna
  persistono; nessuna identità geometrica o fedeltà esadecimale dichiarata.
- Sfondo visivamente magenta, ma non #FF00FF uniforme. Gli angoli superiore sinistro
  e inferiore destro sono rispettivamente RGB (243,12,242) e (242,30,241) nel foglio,
  (242,12,243) e (244,30,242) nelle teste extra: il fondo richiede attenzione al taglio.
- Il foglio esce a 1536×1024: soddisfa il minimo della scheda, non l'ideale 3072×2048.

La scheda aggiornata affida a Claude il ripristino dei colori esatti nel ricalco SVG,
con controllo della tavolozza su tutti i pezzi e tutte le teste. Questa consegna non
sostituisce quel controllo e non dichiara risolti i difetti geometrici o delle giunture.
Nessun taglio, ricalco, montaggio sullo scheletro, test di animazione o integrazione nel
gioco eseguito: sono le fasi successive di Claude. Nessuna accettazione attribuita a Sergio.
Nessuna contraddizione nuova con le decisioni lette. Nessuna PR aperta o unione verso main.

## Resoconto di Claude

### Fase 1 · scelte di Sergio (2026-11-02)

- **Tre quarti:** `art/WB-009/scelti/tre_quarti.png`, una generazione fatta da Sergio (1024×1536), diversa dalle due consegnate. È R4 della fase 2.
- **Espressioni:** `art/WB-009/scelti/espressioni.png`, il foglio consegnato (`3_espressioni.png`), tutte e nove; la faccia della mira (5) è quella del foglio, ritagliata a parte in `art/WB-009/scelti/mira.png`. È R5 della fase 2.
- **Camminata:** difettosa (pose 1 e 3 uguali, 2 e 4 uguali) ma era solo una prova: non si rifà.
- Colori non esatti della tavolozza (leggere sfumature): li riporta alla tavolozza il ricalco in SVG.
- **Mira, collo da stringere** (Sergio): la faccia di `mira.png` resta, ma il collo è più largo di quello delle altre teste. `5_teste_extra` la ridisegna con R6 come riferimento e il collo stretto come nel foglio.

Fase 2 pronta: `esegui WB-009 fase 2`.


### Fase 2 · primo taglio (2026-11-02)

Guardati `4_foglio_pezzi.png` e `5_teste_extra.png`.

- **Buoni:** 11 pezzi separati, ala vuota, verde solo sul fazzoletto, coda intera con la
  freccia. Cima di braccia e gambe e fondo dei colli senza contorno nero, come chiesto.
  Nelle teste extra la mira ha la faccia scelta e il collo stretto come le altre.
- **Difetti visibili:** il busto ha le spalle contornate di nero (con il braccio davanti
  non si vede; dietro, sul braccio lontano, sì); ombre vicino ad alcune giunture (lato del
  busto, colli); colori sfumati e fuori tavolozza; fondo magenta non uniforme; foglio a
  1536×1024 invece di 3072×2048; la coda è a U (il taglio la segue lo stesso).
- **Taglio:** `taglia.py art/WB-009/4_foglio_pezzi.png --nome apprendista --categoria personaggio
  --allinea --senza ala,collo --facce art/WB-009/5_teste_extra.png` monta tutti i pezzi e le
  nove teste (le cinque in più alte quanto la testa, sul suo perno); `collo` toglie il
  moncherino del collo a tutte le teste, come ha chiesto Sergio (il collo è del busto); la pelle si prova con
  `imposta prova_pelli apprendista` (scenario `strumenti/simula/scenari/apprendista.txt`,
  foto in `art/WB-009/prova_simulazione.png`): fermo, corsa, salto, mira e Lama tengono.
  Nel gioco di tutti non cambia niente finché la pelle non diventa il personaggio di base.
- **Editor delle animazioni** ripubblicato (versione 26) con la pelle `apprendista` e le
  nove facce nella riga "Faccia": Sergio la prova lì. Il diavoletto di base, che le cinque
  facce nuove non le ha, mette la testa normale.
- **Ancora da fare,** dopo la prova di Sergio: ricalco in SVG coi colori esatti della
  tavolozza (controllo che fallisce sui colori fuori tavolozza), PNG per ogni schermo,
  poi nell'editor lo zoom sugli SVG e i pezzi da specchiare (Sergio). Il pugno e le
  spalle dietro si giudicano nella prova.

### Fase 2 · ricalco in SVG coi colori esatti (2026-11-02)

- `strumenti/stampino/vettoriale.py --tavolozza strumenti/stampino/tavolozze/apprendista.json`
  ricalca i due fogli in `art/WB-009/svg/4_foglio_pezzi.svg` e `5_teste_extra.svg`: un
  strato per colore, solo i 13 codici della tavolozza (controllo con `--controlla`, si ferma
  su ogni colore fuori). Crema e corna, quasi uguali, si scelgono per macchia: dentro la pelle
  è crema (muso, pancia), se sporge è corna (corna, unghie). Le righe sottili scure diventano
  nere, i fili di un colore prendono quello vicino.
- Ritocchi a mano in `art/WB-009/svg/4_foglio_pezzi_ritocchi.json` (Sergio): il busto senza
  il nero sulle spalline, dove si attaccano le braccia.
- Il taglio parte dai PNG fatti dagli SVG: `taglia.py simulazione/4_col.png --nome apprendista
  --categoria personaggio --allinea --senza ala,collo --facce simulazione/5_col.png`. Il collo
  si taglia sotto il contorno del mento, senza i pezzi neri del collo.
- Ancora da fare: fase 3 (corpo fedele al tre quarti, braccia col pugno chiuso), poi l'editor
  con gli SVG dei pezzi (zoom, specchio) e i PNG per ogni schermo.
