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

## Cosa teniamo e cosa scartiamo

| Teniamo | Perché |
|---|---|
| Diavoletto piccolo e tozzo, testa grande, pelle rosso mattone, pancia e muso pergamena | è A di WB-008, scelto da Sergio; si stacca da ogni fondo (prova a 90 px) |
| Corna corte color osso, orecchie a punta, occhi gialli, ghigno furbo | il carattere dell'apprendista; le corna servono alle sette crepe del purgatorio |
| Coda sottile con la punta a freccia | la sagoma del diavoletto; sullo stampino è la coda intera |
| Fazzoletto al collo = colore della squadra | dipinto in verde #00FF00, che `taglia.py` trasforma nel colore della squadra |
| Mani a quattro dita, piedi nudi a tre dita | come in A |
| Contorno nero spesso, che si assottiglia e sparisce nelle giunture | richiesta di Sergio: nessuna riga nera dove due pezzi si sovrappongono |
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
| R1 | `art/WB-008/1_protagonista_A.png` | l'apprendista scelto (concept): la figura in mezzo è di tre quarti |
| R2 | `art/WB-001/riferimenti/R2_stampino_ai.png` | lo stampino: dove sta ogni pezzo (3072×2048) |
| R3 | `art/WB-001/riferimenti/R3_manichino.png` | come si attaccano i pezzi |
| R4 | `art/WB-009/scelti/tre_quarti.png` | il tre quarti scelto in fase 1 (c'è solo dopo la fase 1) |
| R5 | `art/WB-009/scelti/espressioni.png` | le espressioni scelte in fase 1 (c'è solo dopo la fase 1) |

## Immagini da generare

Ogni prompt è completo e va usato così com'è, in inglese perché il generatore lo segue meglio.
Allega i riferimenti nell'ordine scritto: il primo è "image 1", il secondo "image 2" e così via.

| Fase | Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|---|
| 1 | `1_tre_quarti` | R1 | 1024×1536 verticale | 2 |
| 1 | `2_camminata` | R1 | 1536×1024 | 1 |
| 1 | `3_espressioni` | R1 | 1536×1536 (o 1024×1024) | 1 |
| 2 | `4_foglio_pezzi` | R4, R2, R3, R5 | 3:2 orizzontale, la più grande possibile (ideale 3072×2048, minimo 1536×1024) | 1 |
| 2 | `5_teste_extra` | R4, R5 | 1536×1024 | 1 |

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
- Thick, clean, closed pure-black #000000 outline around each head, thinner black lines only for inner details. The bottom end of the neck stub has NO black outline: the outline gets thinner as it reaches the stub's lower end and stops, and the skin color runs right to the edge.
- Use ONLY these colors: outline and pupils black #000000; skin #B8432A, skin shadow #8E2F1C; muzzle #F1DFB0, its shadow #D6BC86; horns #EFE3C8, their shadow #C9B48E; eyes #F2C45A with a small white #FFFFFF highlight; inside of mouth #5A1A10, teeth white #FFFFFF, tongue #E0605A.
- Flat pure white #FFFFFF background.
- No text, numbers, labels, arrows or signatures. Square format.
```

### `4_foglio_pezzi`

```
Image 1 is the main character of our game, a little blacksmith-apprentice imp, in a three-quarter view facing right. It is the EXACT model: copy his shapes, proportions, colors and flat style; do not reinterpret him. Image 4 is his approved expression sheet.

Image 2 is a layout sheet: 14 grey placeholder parts on a flat magenta #FF00FF background, in three rows. Use image 2 ONLY to know where each part goes on the sheet, roughly how big it is and where it attaches. Do NOT copy the grey parts' shapes, faces, visor, horns, wing, belt or flat grey style. Image 3 shows how the grey parts attach to each other.

Make the PARTS SHEET of the imp of image 1, cut apart like a paper puppet: same canvas as image 2, same flat magenta #FF00FF background, each part placed over its grey placeholder and about the same size. Nothing else may remain on the sheet: no grey placeholders, no labels, no text, no numbers, no shadows on the magenta. Every part is drawn as it looks in image 1 (three-quarter view facing right), COMPLETE even where other parts would hide it, and well separated from the other parts (no part touches another).

OUTLINE AND JOINTS, very important: every part has a thick, clean pure-black #000000 outline, EXCEPT at its joint ends, where it slides under or over another part. At a joint end the black outline gets gradually thinner as it approaches the end and disappears completely; the last stretch of the part is filled with its flat color right to the edge, rounded and full, with NO black line across it. Joint ends are: the bottom of each neck stub; the neck opening and the two shoulders of the torso; the top of each arm (shoulder end); the top of each leg (hip end); both ends of the upper arm and both ends of the forearm; the root of the tail (the end attached to the body). Everywhere else the outline stays thick and even.

The parts, left to right:
Row 1: four heads of the imp of image 1, facing right, each with a short neck stub at the bottom, the head outline, horns and ears IDENTICAL in all four, no flame on top: head 1 = expression 1 of image 4 (sly grin); head 2 = expression 2 (hit, eyes squeezed shut > <, jagged open mouth); head 3 = expression 3 (victory, happy closed eyes, big laughing mouth); head 4 = expression 4 (knocked out, spiral pupils, wavy mouth).
Row 2: the torso alone (no head, no arms, no legs): chest and round belly with the parchment-colored belly patch, with the neckerchief knotted around the neck painted in pure bright green #00FF00 shaded only with #00B400, round full shoulders and a round closed bottom; then NOTHING where the grey wing is (leave that spot empty magenta: he has no wings); then the WHOLE TAIL in one piece, following the curve of the grey tail: one smooth continuous tube, thick at the root and thinner towards the tip, ending in its arrowhead tip, with no breaks, seams or joints along it.
Row 3: the near arm and the far arm, each a straight arm hanging down from a round shoulder end and ending in an OPEN relaxed four-fingered hand, palm towards us; the near leg and the far leg, each a straight leg, round at the hip end, ending in a bare three-toed foot pointing right; the upper arm and the forearm, two short straight pieces of the arm with fully rounded, filled ends at both sides so they can overlap at the elbow and shoulder without a visible joint; one closed fist.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone listed below. No gradients, no textures, no hatching, no soft shading, no glow.
- Use ONLY these colors: outline and pupils black #000000; skin #B8432A, skin shadow #8E2F1C; belly and muzzle #F1DFB0, their shadow #D6BC86; horns and toenails #EFE3C8, their shadow #C9B48E; eyes #F2C45A with a small white #FFFFFF highlight; inside of mouth #5A1A10, teeth white #FFFFFF, tongue #E0605A; neckerchief #00FF00 with shadow #00B400.
- The bright green #00FF00 is used ONLY on the neckerchief, nowhere else.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- Landscape 3:2, as large as possible.
```

### `5_teste_extra`

```
Image 1 is the main character of our game, a little blacksmith-apprentice imp, in a three-quarter view facing right: copy his head exactly (shape, horns, ears, colors, flat style). Image 2 is his approved expression sheet: nine heads in a 3 by 3 grid.

Draw FIVE heads of him in a single row, left to right, all the same size, all facing right in three-quarter view, each with a short neck stub at the bottom, well apart from each other, the head outline, horns and ears IDENTICAL in all five, no flame on top. They are expressions 5 to 9 of image 2, copied exactly: 1) AIMING (focused, far eye squinting, tongue tip out of the corner of the mouth); 2) ANGRY (eyebrows in a V, clenched teeth); 3) DEFEATED (sad, eyes down, downturned mouth); 4) SCARED (wide eyes, tiny pupils, small open mouth); 5) TAUNT (wink and tongue out).

Each head has a thick, clean pure-black #000000 outline, EXCEPT at the bottom of the neck stub: there the outline gets gradually thinner and disappears, and the skin color runs right to the edge, rounded and full, with no black line across it.

Rendering rules, very strict, because these heads will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone listed below. No gradients, no textures, no hatching, no soft shading, no glow.
- Use ONLY these colors: outline and pupils black #000000; skin #B8432A, skin shadow #8E2F1C; muzzle #F1DFB0, its shadow #D6BC86; horns #EFE3C8, their shadow #C9B48E; eyes #F2C45A with a small white #FFFFFF highlight; inside of mouth #5A1A10, teeth white #FFFFFF, tongue #E0605A.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the heads.
- No text, numbers, labels, arrows or signatures. Landscape 3:2.
```

## Criteri di accettazione

- [ ] è l'apprendista di R1: proporzioni, testa, corna, orecchie, coda a freccia, fazzoletto
- [ ] solo colori piatti della tavolozza, al massimo un'ombra netta per colore; niente tratteggi, texture, fuliggine
- [ ] contorno nero spesso e chiuso, tranne alle estremità delle giunture, dove si assottiglia e sparisce
- [ ] nessuna fiammella sulla testa, nessuna ala, nessun vestito oltre al fazzoletto
- [ ] il verde `#00FF00` solo sul fazzoletto
- [ ] tre quarti verso destra in tutte le immagini; nelle teste la sagoma è identica, cambia solo l'espressione
- [ ] fase 2: 13 pezzi sopra i posti di R2 (posto dell'ala vuoto), nessun manichino grigio rimasto, sfondo magenta pieno senza aloni
- [ ] coda intera, liscia, più spessa alla radice, punta a freccia in fondo
- [ ] nessuna scritta, numero o firma

## Dopo le immagini (lo fa Claude)

1. **Taglio.** `python3 strumenti/stampino/taglia.py art/WB-009/4_foglio_pezzi.png --nome apprendista --categoria personaggio --allinea --senza ala`:
   pezzi sullo scheletro, coda divisa in segmenti, fazzoletto nel colore della squadra.
2. **Vettoriale.** `strumenti/stampino/vettoriale.py` oggi ricalca solo il bianco e nero. Va
   esteso ai colori: ogni pixel va al colore più vicino della tavolozza qui sopra, ogni colore
   si ricalca con potrace in uno strato SVG, e gli strati si impilano dal fondo al contorno.
   Esce un SVG per pezzo, accanto al foglio. Scartato `vtracer`: raggruppa i colori da solo,
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

## Resoconto di Claude
