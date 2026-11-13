# WB-037 · L'apprendista scelto (WB-036 n. 2) a pezzi: corpo, teste, palpebre, pugni, fiamma

- **Stato:** APPROVATA (Sergio, 13 nov: «Ok, la 2, ritagliamo le parti con le tecniche che hanno funzionato l'ultima volta»)
- **Data:** 2026-11-13
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-037`

## Obiettivo

Fase 2 di [PERSONAGGI.md](PERSONAGGI.md) per l'apprendista scelto in WB-036 (variante 2, R1),
con gli stessi prompt che hanno funzionato in WB-009 (`8_corpo_fedele`, `7_teste`,
`9_braccia_chiuse`) e due fogli nuovi per la prova con Godot:

- **palpebre**: la testa di base tre volte, occhi aperti, socchiusi e chiusi, identica in tutto
  il resto, per un battito di ciglia pulito (si scambia il disegno, niente shader che sporca);
- **fiamma**: la fiammella da sola, dritta, come nel riferimento iniziale di Sergio (R6), che in
  Godot diventa una maglia continua piegata da una catena, come il mantello.

Poi Claude (fase 3): taglio, ricalco in **SVG coi colori esatti** della tavolozza, PNG esportati
grandi (almeno 8 pixel per unità del disegno, con mipmap) così restano puliti anche ingranditi
nell'editor; giunture con i pezzi che si sovrappongono (il contorno sparisce alle estremità).
Nessun pezzo viene messo a occhio: le posizioni vengono dallo stampino e dai perni.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-037/riferimenti/R1_tre_quarti_scelto.png` | l'apprendista scelto (WB-036 n. 2): il modello esatto |
| R2 | `art/WB-037/riferimenti/R2_stampino_ai.png` | lo stampino: posizione e misura dei pezzi (non le forme) |
| R3 | `art/WB-037/riferimenti/R3_manichino.png` | come si attaccano i pezzi |
| R4 | `art/WB-037/riferimenti/R4_espressioni.png` | le nove espressioni approvate |
| R5 | `art/WB-037/riferimenti/R5_mira.png` | la faccia della mira approvata |
| R6 | `art/WB-037/riferimenti/R6_fiamma_iniziale.png` | il riferimento iniziale di Sergio per la fiamma |

## Immagini da generare

| Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|
| `art/WB-037/corpo.png` | R1, R2, R3 | 1536×1024 | 2 |
| `art/WB-037/teste.png` | R1, R4, R5 | 1024×1024 | 2 |
| `art/WB-037/palpebre.png` | `teste_1.png`, R1 | 1536×1024 | 2 |
| `art/WB-037/pugni.png` | R1, `corpo_1.png` | 1536×1024 | 1 |
| `art/WB-037/fiamma.png` | R6, R1 | 1024×1024 | 2 |

Le varianti si chiamano `corpo_1.png`, `corpo_2.png` e così via. `palpebre` parte da
`teste_1.png`, `pugni` da `corpo_1.png`, appena generati.

### Regole comuni (in fondo a ogni prompt, così come sono)

```
Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone listed below. No gradients, no textures, no hatching, no soft shading, no glow.
- Use ONLY these colors: outline and pupils black #000000; skin #B8432A, skin shadow #8E2F1C; belly and muzzle #F1DFB0, their shadow #D6BC86; horns and toenails #EFE3C8, their shadow #C9B48E; eyes #F2C45A with a small white #FFFFFF highlight; inside of mouth #5A1A10, teeth white #FFFFFF, tongue #E0605A; flame #F07A1E and #FFD34A; neckerchief #00FF00 with shadow #00B400.
- The bright green #00FF00 is used ONLY on the neckerchief, nowhere else.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `corpo`

```
Image 1 is the main character of our game, a little blacksmith-apprentice imp, in a three-quarter view facing right. It is the EXACT model: every body part you draw must be COPIED from image 1, shape by shape, with the same proportions, the same thickness and the same contours. Do not invent, round off, fatten or simplify any part.

Image 2 is a layout sheet: grey placeholder parts on a flat magenta #FF00FF background, in three rows. Use image 2 ONLY to know where each part goes on the sheet and roughly how big it is. Do NOT copy the grey parts' shapes. Image 3 shows how the grey parts attach to each other.

Make the BODY PARTS SHEET of the imp of image 1, cut apart like a paper puppet, on the same canvas as image 2 with the same flat magenta #FF00FF background. Leave the WHOLE FIRST ROW EMPTY (pure magenta, no heads: the heads are done separately). Draw only these parts, each over its grey placeholder, well separated from each other, each COMPLETE even where other parts would hide it in image 1:
Row 2: the TORSO of image 1 without head, arms, legs and tail: the same shape as in image 1, with the same belly patch, the neckerchief knotted around the neck painted in pure bright green #00FF00 shaded only with #00B400, and a short neck stub on top. NO shoulder bumps and no stubby arms: at each shoulder the torso simply ends with a smooth, round, full edge of plain skin. Then NOTHING where the grey wing is (leave that spot empty magenta: he has no wings). Then the WHOLE TAIL of image 1 in one piece, with the same curve, the same thickness and the same arrowhead tip: one smooth continuous tube, thick at the root and thinner towards the tip, with no breaks, seams or joints along it.
Row 3: the near arm and the far arm, copied from image 1 (same slim shape, same relaxed hand), each straight and hanging down from a round shoulder end; the near leg and the far leg, copied from image 1 (same thigh and calf, same bare three-toed foot pointing right), each straight, round at the hip end; one closed four-fingered fist, the size of the hands in image 1 (a small round piece, outlined all around).

OUTLINE AND JOINTS, very important: every part has a thick, clean pure-black #000000 outline, EXCEPT at its joint ends. At a joint end the black outline gets gradually thinner and disappears completely; the last stretch of the part is filled with its flat color right to the edge, rounded and full, with NO black line across it. Joint ends are: the neck stub and the two shoulder edges of the torso; the top of each arm (shoulder end); the top of each leg (hip end); the root of the tail. The color near every joint end must be PERFECTLY UNIFORM plain skin #B8432A: no shadow, no highlight, no line, no color change in the last stretch before the joint, so that two overlapping parts of bare skin blend into one surface with no visible seam. Keep shadow shapes well away from the joint ends.

No head and no flame on this sheet. Landscape 3:2, as large as possible.
```
+ regole comuni.

### `teste`

```
Image 1 is the main character of our game, a little blacksmith-apprentice imp, in a three-quarter view facing right: copy his head exactly (shape, horns, ears, muzzle, colors, flat style). Image 2 is his approved expression sheet: nine heads in a 3 by 3 grid. Image 3 is the approved aiming face, cropped from image 2.

Draw NINE heads of him in a 3 by 3 grid, all the same size, all facing right in three-quarter view, well apart from each other, the head outline, horns and ears IDENTICAL in all nine, and NO FLAME on top (the flame is a separate piece): the top of the skull is plain smooth skin. They are the nine expressions of image 2, in the same order, copied exactly. Row 1: 1) SLY (his default confident closed-mouth grin, as in image 1), 2) HIT (eyes squeezed shut > <, jagged open mouth), 3) VICTORY (happy closed eyes, big laughing mouth). Row 2: 4) KNOCKED OUT (spiral pupils, wavy mouth, tongue slightly out), 5) AIMING (copy the face of image 3 exactly), 6) ANGRY (eyebrows in a V, clenched teeth). Row 3: 7) DEFEATED (sad, eyes down, downturned mouth), 8) SCARED (wide eyes, tiny pupils, small open mouth), 9) TAUNT (wink and tongue out).

NO NECK AT ALL, very important: each head is drawn exactly as if it had been cut out of image 1 along the outline of the head. It ends at the chin and at the back of the jaw: nothing below them, no neck, no neck stub, no neckerchief. The thick black #000000 outline is CLOSED all around each head, also under the chin, under the muzzle and under the back of the jaw, smooth and even, following the round shape of the head in image 1.

Square format.
```
+ regole comuni.

### `palpebre`

```
Image 1 is a sheet of nine heads of our little devil; the FIRST one (top left, SLY) is his default face. Image 2 is the whole character for reference.

Draw the first head of image 1 THREE times in a row, left to right, all the same size, well apart from each other, IDENTICAL in everything (outline, horns, ears, muzzle, mouth, colors, position of every line) except the eyes:
1) eyes OPEN, exactly as in image 1;
2) eyes HALF CLOSED: the upper eyelids, in skin color #B8432A with a thin black lash line on their lower edge, come down over the top half of both eyes; the pupils are still visible below them, in the same place;
3) eyes CLOSED: the upper eyelids cover both eyes completely, leaving only a gently curved black line where each eye closes, in the lower part of the eye shape; the eye outline stays the same.
No neck, outline closed all around each head, no flame.

Landscape 3:2.
```
+ regole comuni.

### `pugni`

```
Image 1 is the main character of our game, a little blacksmith-apprentice imp, in a three-quarter view facing right. Image 2 is his parts sheet: copy the arms of image 2 exactly (same length, thickness, contour, colors and flat style).

Draw TWO ARMS of him side by side, left to right, the same size as the arms in image 2, well apart from each other, on a flat pure magenta #FF00FF background: 1) the NEAR arm, 2) the FAR arm. Each arm is straight and hangs down from a round shoulder end, exactly like in image 2, but the hand is CLOSED IN A FIST as if gripping the handle of a tool: four fingers curled, the thumb wrapped over them, the knuckles towards the right. The fist is the same size as the hands of image 2.

OUTLINE AND JOINTS, very important: each arm has a thick, clean pure-black #000000 outline, EXCEPT at the shoulder end at the top: there the outline gets gradually thinner and disappears completely, and the skin runs right to the edge, rounded and full, with no black line across it. The skin near the shoulder end is PERFECTLY UNIFORM plain #B8432A: no shadow, no highlight, no line there, so the arm blends into the torso with no visible seam. Keep shadow shapes well away from the shoulder end.

Landscape 3:2.
```
+ regole comuni.

### `fiamma`

```
Image 1 is our original reference for the head flame of our little devil. Image 2 is the whole character with his flame. Draw ONLY THE FLAME, alone, large, in the middle of the canvas: copy the flame of image 1 exactly (same shape, same tongues, same orange #F07A1E outside and yellow #FFD34A inside, same thick black #000000 outline), standing STRAIGHT UP, not leaning, as tall as about two thirds of the canvas. Its bottom is narrow and closed with the black outline, rounded, as if cut where it touches the skull. No head, no horns, nothing else.

Square 1024x1024.
```
+ regole comuni.

## Criteri di accettazione

- [ ] ogni pezzo copiato forma per forma da R1, nella casella giusta dello stampino
- [ ] contorno nero spesso, che sparisce alle estremità delle giunture; pelle uniforme lì
- [ ] busto senza spalline, coda intera senza giunture, piedi a destra
- [ ] nove teste senza collo e senza fiamma, contorno chiuso, identiche tranne la faccia
- [ ] palpebre: tre teste identiche tranne gli occhi (aperti, socchiusi, chiusi)
- [ ] fiamma dritta e da sola, uguale a R6, base stretta e chiusa
- [ ] colori piatti della tavolozza, sfondo magenta pulito, nessuna scritta

---

## Decisione

Approvata da Sergio il 13 nov (scelta la variante 2 di WB-036, «ritagliamo le parti con le
tecniche che hanno funzionato l'ultima volta»).

## Consegna di Codex

## Resoconto di Claude
