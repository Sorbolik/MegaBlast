# WB-016 · I fantocci: tre quarti, facce e pezzi sullo stampino

- **Stato:** APPROVATA
- **Data:** 2026-11-04
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-016`

## Obiettivo

Nel cortile e nella Forgia si tira ai fantocci (`dummy = true` in `client/sim/campaign.lua`): oggi
sono l'apprendista, e il giocatore non capisce al volo che è un bersaglio e non un nemico. Serve
un **fantoccio da allenamento** a pezzi sullo stampino, come l'apprendista (WB-009), Favilla
(WB-013) e il Fabbro (WB-014): un sacco di iuta imbottito di paglia, legato con la corda, con
due cornetti di legno (è il fantoccio dei diavoletti) e un bersaglio dipinto sulla pancia.
Così si muove, vola e cade con le stesse animazioni, e si vede subito che è finto.

Nel piano dei livelli (https://claude.ai/artifact/12CRugbQCR2oB32LHt6aS2) questa scheda era
chiamata «WB-014»: quel numero è andato al Fabbro, i fantocci sono WB-016.

## Due fasi, due comandi

- **Fase 1**, `esegui WB-016 fase 1`: immagini 1 e 2. Sergio sceglie il tre quarti; Claude lo
  salva in `art/WB-016/scelti/tre_quarti.png` (e le facce in `art/WB-016/scelti/facce.png`) su
  main.
- **Fase 2**, `esegui WB-016 fase 2`: immagini 3, 4 e 5, coi file scelti come riferimento.
- Codex esegue solo le righe della fase chiesta; se un riferimento della fase non c'è, si ferma.

## Cosa teniamo e cosa scartiamo

| Teniamo | Perché |
|---|---|
| **Lo stesso scheletro e la stessa altezza dell'apprendista**, testa grande, braccia e gambe | la sagoma dei colpi è uguale per tutti (`client/sim/body.lua`); con braccia e gambe si muove con le pose di tutti (colpito, volo, paracadute, sconfitta) |
| Sacco di iuta con cuciture a punti grandi, paglia che esce dal collo, dai polsi e dalle caviglie, corda legata in vita | si legge «finto» anche a 90 px |
| Due cornetti corti di legno sulla testa, legati con un giro di corda | è il fantoccio dei diavoletti: stessa sagoma della testa con le corna |
| Un bersaglio rosso e bianco dipinto sulla pancia | dice «tirami qui»; è grande e semplice, regge il ricalco |
| Facce cucite e dipinte (occhi a bottone, bocca a punti) che cambiano come quelle degli altri | le pose del gioco usano le nove teste: colpito, vittoria, sconfitta, ... |
| Tre quarti verso **destra**, tutti e due i piedi a destra; teste senza collo e col contorno chiuso | lezioni di WB-009 e WB-013 |

| Scartiamo | Perché |
|---|---|
| Il palo su cui sta infilato | in gioco salta e vola via quando lo colpisci: deve avere le gambe |
| Armi, scudi, pezzi d'armatura | non tira; le ali e la coda restano vuote (`--senza ala,coda`) |
| Il trama della iuta, i fili di paglia uno per uno | a misura di gioco sono rumore e il ricalco viene sporco: la iuta è un colore piatto con le cuciture, la paglia ciuffi a punta |
| Il colore della squadra | non è di nessuna squadra; la targa basta |
| Facce cattive o paurose | è un bersaglio buffo, non un nemico |
| Chiedere l'SVG a ChatGPT | si ricalca il disegno buono |

## La tavolozza (uguale in ogni prompt)

| Parte | Colore | Ombra |
|---|---|---|
| contorno, cuciture, occhi a bottone | nero `#000000` | |
| iuta | `#C9A36A` | `#A07F4C` |
| paglia | `#F0CF6A` | `#C9A642` |
| corda | `#8A6A3E` | `#6B4F2C` |
| legno (cornetti, zoccoli) | `#8B5A2B` | `#6A4220` |
| bersaglio | rosso `#C8452E`, bianco `#FFFFFF` | |
| lucina degli occhi, denti | `#FFFFFF` | |
| bocca dentro | `#5A1A10` | |
| sfondo | bianco `#FFFFFF` (fase 1), magenta `#FF00FF` (fase 2) | |

Nota per il ricalco: corda e legno sono scuri ma non neri; la tavolozza di Claude avrà un
`righe_max` basso come quella di Favilla. La paglia gialla non deve finire fra gli occhi
(l'esclusione «altri gialli» di `vettoriale.py`).

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-009/scelti/tre_quarti_gamba.png` | l'apprendista nello stile pulito del gioco: il tratto, i colori piatti, l'altezza e lo scheletro da copiare |
| R2 | `art/WB-009/riferimenti/R2_stampino_ai.png` | lo stampino: dove va ogni pezzo (3072×2048) |
| R3 | `art/WB-009/riferimenti/R3_manichino.png` | come si attaccano i pezzi |
| R4 | `art/WB-009/7_teste.png` | le nove teste dell'apprendista: **solo il formato** (niente collo, contorno chiuso), non le facce |
| R5 | `art/WB-016/scelti/tre_quarti.png` | il tre quarti scelto in fase 1 (c'è solo dopo) |
| R6 | `art/WB-016/scelti/facce.png` | le facce scelte in fase 1 (c'è solo dopo) |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto: il
primo è "image 1", il secondo "image 2" e così via. Sfondo **non** trasparente (eccezione ad
`AGENTS.md`): bianco pieno in fase 1, magenta pieno `#FF00FF` in fase 2, perché lo usa lo
strumento di taglio.

| Fase | Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|---|
| 1 | `1_tre_quarti` | R1 | 1024×1536 verticale | 2 |
| 1 | `2_facce` | R1 | 1536×1536 (o 1024×1024) | 1 |
| 2 | `3_teste` | R5, R6, R4 | 1536×1536 (o 1024×1024) | 1 |
| 2 | `4_corpo` | R5, R2, R3 | 3:2 orizzontale, la più grande possibile (minimo 1536×1024) | 1 |
| 2 | `5_braccia_chiuse` | R5, `art/WB-016/4_corpo.png` | 1536×1024 | 1 |

### `1_tre_quarti`

```
Image 1 is a character of our game, a little imp apprentice, drawn in the game's clean style: copy ONLY its rendering (flat colors, thick black outline), its HEIGHT and body skeleton (big head about one third of the height, short body, arms and legs) and its three-quarter angle. Do not copy its face, horns, clothes, neckerchief or tail.

Draw a TRAINING DUMMY for little imps: a stuffed burlap sack puppet with exactly the height and skeleton of image 1. A round burlap head, a sack body, burlap arms and legs, all sewn together with big visible black cross stitches. Short tufts of straw stick out at the neck, at the wrists and at the ankles. A rope is tied around the waist with a knot. On top of the head, two SHORT wooden horns tied on with a loop of rope (it is a dummy shaped like an imp). A big simple painted target on the belly: a red ring, a white ring and a red dot. The hands are rounded burlap mittens with straw tufts at the wrists; the feet are small wooden blocks tied to the legs. The face is sewn and painted: two black button eyes with a small white highlight and a mouth of black stitches, a silly blank expression. It looks harmless and funny, not scary.

Draw it ONCE, full body, in a clean THREE-QUARTER VIEW FACING RIGHT, standing still in a neutral pose like image 1: legs slightly apart, BOTH FEET POINTING TO THE RIGHT, both arms hanging loosely a little away from the body, the near arm and near leg (on the right of the picture) fully visible, the far arm and far leg (on the left) partly behind the body. No pole, no stand, no weapons, no shield, no armour, no wings, no tail.

Rendering rules, very strict, because this drawing will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone listed below. No gradients, no textures, no burlap weave, no single straw strands, no hatching, no soft shading, no noise. Straw is drawn as a few clean pointed tufts.
- Thick, clean, closed pure-black #000000 outline of even weight around the whole figure, with thinner black lines only for inner details (stitches, button eyes, mouth, rope, target rings, horn grain).
- Use ONLY these colors: outline, stitches and button eyes black #000000; burlap #C9A36A, burlap shadow #A07F4C; straw #F0CF6A, straw shadow #C9A642; rope #8A6A3E, rope shadow #6B4F2C; wood of horns and feet #8B5A2B, wood shadow #6A4220; target red #C8452E and white #FFFFFF; eye highlight white #FFFFFF; inside of mouth #5A1A10.
- Flat pure white #FFFFFF background, no ground, no shadow on the ground, nothing else in the picture.
- No text, numbers, labels, arrows or signatures. Portrait format 2:3.
```

Le due varianti di `1_tre_quarti` vanno chieste insieme, nella stessa richiesta, come due
immagini separate; Sergio sceglie la sua.

### `2_facce`

```
Image 1 is a character of our game drawn in the game's clean style: copy ONLY its rendering (flat colors, thick black outline) and its three-quarter angle.

Draw an EXPRESSION SHEET of a TRAINING DUMMY head: a round stuffed burlap sack head with big black cross-stitched seams, a short tuft of straw at the bottom, and two SHORT wooden horns tied on top with a loop of rope. The face is sewn and painted: black button eyes with a small white highlight, a mouth of black stitches. NINE copies of this head only (with a short neck stub with the straw tuft, no body), all in three-quarter view facing RIGHT, all the same size, in a 3 by 3 grid, well apart from each other. The head outline, horns, rope loop and seams are IDENTICAL in all nine: only the eyes and the mouth change, always simple, sewn and funny, never scary.
Row 1: 1) BLANK: its default face, two round button eyes and a straight line of stitches; 2) HIT: the button eyes become two stitched crosses X X, the stitched mouth a zigzag; 3) VICTORY: eyes as happy upside-down stitched arcs, a big stitched smile.
Row 2: 4) KNOCKED OUT: one button eye hanging loose by a thread, the other an X, a wavy stitched mouth; 5) AIMING: one button eye bigger than the other, the mouth a small round O; 6) GRUMPY: eyebrows of two slanted stitches in a V, a flat stitched frown.
Row 3: 7) DEFEATED: eyes looking down, the stitched mouth sagging, a few straw strands drooping; 8) SURPRISED: very wide round button eyes, a small open oval mouth showing dark inside; 9) TEASING: one eye a stitched wink, a crooked stitched grin.

Rendering rules, very strict, because these drawings will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone listed below. No gradients, no textures, no burlap weave, no hatching, no soft shading.
- Thick, clean, closed pure-black #000000 outline around each head, thinner black lines only for inner details. The bottom end of the neck stub has NO black outline: the outline gets thinner as it reaches the stub's lower end and stops, and the burlap color runs right to the edge.
- Use ONLY these colors: outline, stitches and button eyes black #000000; burlap #C9A36A, burlap shadow #A07F4C; straw #F0CF6A, straw shadow #C9A642; rope #8A6A3E, rope shadow #6B4F2C; wood of horns #8B5A2B, wood shadow #6A4220; eye highlight white #FFFFFF; inside of mouth #5A1A10.
- Flat pure white #FFFFFF background.
- No text, numbers, labels, arrows or signatures. Square format.
```

### `3_teste`

```
Image 1 is a training dummy of our game, a stuffed burlap puppet with two short wooden horns, in a three-quarter view facing right: copy its head exactly (shape, seams, horns, rope loop, colors, flat style). Image 2 is its approved expression sheet: nine heads in a 3 by 3 grid. Image 3 is another character of the same game: it shows ONLY the FORMAT to copy, nine heads cut out with no neck and a closed black outline under the chin. Do not copy its faces, horns or colors.

Draw NINE heads of the dummy in a 3 by 3 grid, all the same size, all facing right in three-quarter view, well apart from each other, the head outline, horns, rope loop and seams IDENTICAL in all nine. They are the nine faces of image 2, in the same order, copied exactly. Row 1: 1) BLANK (button eyes, straight stitched mouth), 2) HIT (stitched X eyes, zigzag mouth), 3) VICTORY (happy stitched arcs, big stitched smile). Row 2: 4) KNOCKED OUT (one button eye hanging by a thread, one X, wavy mouth), 5) AIMING (one eye bigger, small O mouth), 6) GRUMPY (slanted stitch eyebrows in a V, flat frown). Row 3: 7) DEFEATED (eyes down, sagging mouth), 8) SURPRISED (very wide button eyes, small open oval mouth), 9) TEASING (stitched wink, crooked grin).

NO NECK AT ALL, very important: each head is drawn exactly as if it had been cut out of image 1 along the outline of the head. It ends at the bottom of the round sack head: nothing below it, no neck, no neck stub, no straw tuft at the bottom. The thick black #000000 outline is CLOSED all around each head, also underneath, smooth and even, exactly like the heads of image 3. The neck stubs of image 2 must NOT appear. The horns stay whole, inside the picture.

Rendering rules, very strict, because these heads will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone listed below. No gradients, no textures, no burlap weave, no hatching, no soft shading.
- Use ONLY these colors: outline, stitches and button eyes black #000000; burlap #C9A36A, burlap shadow #A07F4C; rope #8A6A3E, rope shadow #6B4F2C; wood of horns #8B5A2B, wood shadow #6A4220; eye highlight white #FFFFFF; inside of mouth #5A1A10.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the heads.
- No text, numbers, labels, arrows or signatures. Square format.
```

### `4_corpo`

```
Image 1 is a training dummy of our game, a stuffed burlap puppet, in a three-quarter view facing right. It is the EXACT model: every body part you draw must be COPIED from image 1, shape by shape, with the same proportions, the same thickness, the same seams and the same contours. Do not invent, round off, fatten or simplify any part.

Image 2 is a layout sheet: grey placeholder parts on a flat magenta #FF00FF background, in three rows. Use image 2 ONLY to know where each part goes on the sheet and roughly how big it is. Do NOT copy the grey parts' shapes. Image 3 shows how the grey parts attach to each other.

Make the BODY PARTS SHEET of the dummy of image 1, cut apart like a paper puppet, on the same canvas as image 2 with the same flat magenta #FF00FF background. Leave the WHOLE FIRST ROW EMPTY (pure magenta, no heads: the heads are already done). Draw only these parts, each over its grey placeholder, well separated from each other, each COMPLETE even where other parts would hide it in image 1:
Row 2: the TORSO of image 1 without head, arms and legs: the same sack shape as in image 1, with its cross-stitched seams, the painted red and white target on the belly, the rope tied around the waist with its knot, and a short neck stub of burlap on top (no straw tuft on the stub). NO stubby arms: at each shoulder the torso simply ends with a smooth, round, full edge of burlap. Then NOTHING where the grey wing is and NOTHING where the grey tail is (leave both spots empty magenta: it has no wings and no tail).
Row 3: the near arm and the far arm, copied from image 1 (burlap sleeve with a seam, a small straw tuft at the wrist, a rounded burlap mitten hand), each straight and hanging down from a round shoulder end; the near leg and the far leg, copied from image 1 (burlap leg with a seam, a small straw tuft at the ankle, a small wooden block foot tied with rope), each straight, round at the hip end, and BOTH FEET POINTING TO THE RIGHT in side view; one closed mitten fist, the size of the hands in image 1 (a small round piece, outlined all around).

OUTLINE AND JOINTS, very important: every part has a thick, clean pure-black #000000 outline, EXCEPT at its joint ends. At a joint end the black outline gets gradually thinner and disappears completely; the last stretch of the part is filled with its flat color right to the edge, rounded and full, with NO black line across it. Joint ends are: the neck stub and the two shoulder edges of the torso; the top of each arm (shoulder end); the top of each leg (hip end). The color near every joint end must be PERFECTLY UNIFORM plain burlap #C9A36A: no shadow, no seam, no stitch, no straw, no color change in the last stretch before the joint, so that two overlapping parts blend into one surface with no visible seam. Keep shadow shapes and stitches well away from the joint ends.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone listed below. No gradients, no textures, no burlap weave, no single straw strands, no hatching, no soft shading.
- Use ONLY these colors: outline and stitches black #000000; burlap #C9A36A, burlap shadow #A07F4C; straw #F0CF6A, straw shadow #C9A642; rope #8A6A3E, rope shadow #6B4F2C; wood #8B5A2B, wood shadow #6A4220; target red #C8452E and white #FFFFFF.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels or signatures. Landscape 3:2, as large as possible.
```

### `5_braccia_chiuse`

```
Image 1 is a training dummy of our game, a stuffed burlap puppet, in a three-quarter view facing right. Image 2 is its parts sheet: copy the arms of image 2 exactly (same length, thickness, seam, straw tuft, contour, colors and flat style).

Draw TWO ARMS of it side by side, left to right, the same size as the arms in image 2, well apart from each other, on a flat pure magenta #FF00FF background: 1) the NEAR arm, 2) the FAR arm. Each arm is straight and hangs down from a round shoulder end, exactly like in image 2, but the burlap mitten hand is CLOSED IN A ROUND FIST, as if squeezing something, with the thumb seam towards the right. The fist is the same size as the open hands of image 2.

OUTLINE AND JOINTS, very important: each arm has a thick, clean pure-black #000000 outline, EXCEPT at the shoulder end at the top: there the outline gets gradually thinner and disappears completely, and the burlap color runs right to the edge, rounded and full, with no black line across it. The burlap near the shoulder end is PERFECTLY UNIFORM plain #C9A36A: no shadow, no seam there, so the arm blends into the torso with no visible seam.

Rendering rules, very strict, because these arms will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no burlap weave, no hatching, no soft shading.
- Use ONLY these colors: outline and stitches black #000000; burlap #C9A36A, burlap shadow #A07F4C; straw #F0CF6A, straw shadow #C9A642.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the arms.
- No text, numbers, labels or signatures. Landscape 3:2.
```

## Criteri di accettazione

- [ ] si capisce subito che è un fantoccio: sacco di iuta cucito, paglia ai polsi, alle caviglie e al collo, corda in vita, bersaglio sulla pancia, cornetti di legno legati
- [ ] alto come l'apprendista di R1 (stesso scheletro), con braccia e gambe; niente palo
- [ ] tre quarti verso destra, tutti e due i piedi a destra; niente armi, ali, coda
- [ ] solo colori piatti della tavolozza, al massimo un'ombra netta per colore; niente trama della iuta né fili di paglia
- [ ] contorno nero spesso e chiuso, tranne alle estremità delle giunture, dove si assottiglia e sparisce; lì la iuta è uniforme, senza cuciture
- [ ] facce buffe, mai cattive; sagoma, corna e cuciture identiche nelle nove teste; fase 2: senza collo, contorno chiuso
- [ ] fase 2: 10 pezzi sopra i 12 posti di R2 (posti dell'ala e della coda vuoti), prima riga vuota, sfondo magenta pieno senza aloni
- [ ] nessun verde `#00FF00` (niente colore della squadra); nessuna scritta, numero o firma

## Dopo le immagini (lo fa Claude)

Come per Favilla (WB-013) e il Fabbro (WB-014):

1. Tavolozza `strumenti/stampino/tavolozze/fantoccio.json` coi colori qui sopra (con
   `macchie_min`, `macchie_ombra_min` e un `righe_max` basso per corda e legno).
2. Ricalco a strati con `vettoriale.py --tavolozza ...`, colori esatti, ritocchi in JSON se
   servono; i PNG solo dagli SVG; teste dal foglio `3_teste` senza collo.
3. Taglio: `taglia.py 4_corpo_col.png --nome fantoccio --categoria personaggio --allinea --senza
   ala,coda --teste 3_teste_col.png --tavolozza ...`, poi `--aggiungi --pugni
   5_braccia_chiuse_col.png`.
4. Nel gioco ogni robot con `dummy = true` veste da solo la pelle `fantoccio` (solo disegno: la
   simulazione non cambia). Editor ripubblicato.
5. Simulazione (scenari del cortile) e foto per Sergio.

---

## Decisione

Approvata da Claude, 2026-11-04: Sergio ha chiesto le schede per il resto della campagna; i
fantocci sono il bersaglio di quasi ogni lezione del cortile e oggi si confondono coi nemici.
Stessa procedura di WB-013 e WB-014; reversibile (il gioco non cambia finché non si tagliano).
Scelte di Claude: sacco di iuta con cornetti di legno e bersaglio sulla pancia, con gambe e
braccia (niente palo) perché deve volare e cadere con le pose di tutti; facce cucite buffe.

## Consegna di Codex

## Resoconto di Claude
