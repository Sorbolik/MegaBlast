# WB-010 · Indicatore del giocatore di turno (al posto della fiammella)

- **Stato:** APPROVATA
- **Data:** 2026-11-02
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-010`

## Obiettivo

Sergio (2 nov): «togli la fiammella, sia dalla home che in game, ci dobbiamo inventare un altro modo
per indicare il giocatore attivo, fammi delle proposte grafiche belle e pronte per essere integrate in
gioco, devono essere in linea con tutto il concept della campagna». Quattro proposte, ognuna con una
scena (l'apprendista con l'indicatore) e un foglio del solo oggetto su magenta, in blu (squadra 1,
`#3d7bff`) e oro (squadra 2, `#f2c45a`), pronto da tagliare. Con le immagini il thread della designer
costruisce la pagina delle proposte. Richiesta completa e opzioni scartate:
`/mnt/project-files/gabriella/indicatore_turno/richiesta_immagini.md`.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-009/riferimenti/R1_apprendista_concept.png` | l'apprendista, il personaggio di tutti |

## Immagini da generare

Ogni prompt è completo e va usato così com'è, allegando R1 come immagine 1. Le scene hanno lo sfondo
dipinto. I fogli hanno lo sfondo magenta pieno #FF00FF, un'eccezione alla regola di `AGENTS.md`
perché lo usa lo strumento di taglio.

| Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|
| `p1_anello_scena` | R1 | 1536×1024 | 1 |
| `p1_anello_foglio` | R1 | 1536×1024 | 1 |
| `p2_freccia_scena` | R1 | 1536×1024 | 1 |
| `p2_freccia_foglio` | R1 | 1536×1024 | 1 |
| `p3_sigillo_scena` | R1 | 1536×1024 | 1 |
| `p3_sigillo_foglio` | R1 | 1536×1024 | 1 |
| `p4_cartiglio_scena` | R1 | 1536×1024 | 1 |
| `p4_cartiglio_foglio` | R1 | 1536×1024 | 1 |

## Proposta 1 · Anello di brace (consigliata)

### `p1_anello_scena`

```
Image 1 is the main character of our game, a little blacksmith-apprentice imp. Copy him exactly (shapes, proportions, colours, horns, neckerchief, tail); do not reinterpret him.

A glowing ring of embers on the ground under the feet of the imp: a flat ellipse of hot coals and cracks in the floor, glowing in the team colour, small sparks rising from it. Seen slightly from above, like a forge floor heating up. The imp's feet stand inside the ring.

Scene: the imp of image 1, in three-quarter view facing right, standing in the middle of a flat painted brick platform of the Forge, in muted slate-blue bricks; behind, a dark muted slate-blue background with engraving hatching, darker and duller than the imp so that he stands out. The team colour in this scene is BLUE #3d7bff. Landscape 3:2.

Style: same as the MegaBlast apprentice imp reference (attached image 1): cartoon, thick black outline, flat cel colours with light Doré-style engraving hatching in the shadows. Campaign palette: brick red, parchment, ember orange, old gold, wrought iron grey. Hell of Dante seen as a forge. Clean shapes that read at 40 px on a phone. No text, no letters, no numbers.
```

### `p1_anello_foglio`

```
Image 1 is the main character of our game, a little blacksmith-apprentice imp: use it ONLY for the style and for the size of the object compared to him. Do not draw the imp.

The object: a glowing ring of embers, a flat ellipse of hot coals and cracks seen slightly from above, glowing in the team colour, small sparks rising from it. 4 frames per row of the glow pulsing: dim, medium, bright, medium; the sparks move up a little in each frame.

Sheet layout: solid flat magenta #FF00FF background, nothing else on it (no shadows on the magenta, no ground, no imp). Two rows, all frames the same size and evenly spaced, no frame touching another: top row = BLUE team version (#3d7bff), bottom row = GOLD team version (#f2c45a). Same object in both rows, only the team colour changes. Do not use magenta or pink anywhere on the object. Landscape 3:2.

Style: same as the MegaBlast apprentice imp reference (attached image 1): cartoon, thick black outline, flat cel colours with light Doré-style engraving hatching in the shadows. Campaign palette: brick red, parchment, ember orange, old gold, wrought iron grey. Hell of Dante seen as a forge. Clean shapes that read at 40 px on a phone. No text, no letters, no numbers.
```

## Proposta 2 · Freccia di ferro battuto

### `p2_freccia_scena`

```
Image 1 is the main character of our game, a little blacksmith-apprentice imp. Copy him exactly (shapes, proportions, colours, horns, neckerchief, tail); do not reinterpret him.

A small wrought-iron arrowhead / chevron floating above the imp's head, pointing down at him, hammered metal with rivets, an ember glow inside a slot in the middle in the team colour.

Scene: the imp of image 1, in three-quarter view facing right, standing in the middle of a flat painted brick platform of the Forge, in muted slate-blue bricks; behind, a dark muted slate-blue background with engraving hatching, darker and duller than the imp so that he stands out. The team colour in this scene is BLUE #3d7bff. Landscape 3:2.

Style: same as the MegaBlast apprentice imp reference (attached image 1): cartoon, thick black outline, flat cel colours with light Doré-style engraving hatching in the shadows. Campaign palette: brick red, parchment, ember orange, old gold, wrought iron grey. Hell of Dante seen as a forge. Clean shapes that read at 40 px on a phone. No text, no letters, no numbers.
```

### `p2_freccia_foglio`

```
Image 1 is the main character of our game, a little blacksmith-apprentice imp: use it ONLY for the style and for the size of the object compared to him. Do not draw the imp.

The object: a small wrought-iron arrowhead / chevron pointing down, hammered metal with rivets, an ember glow inside a slot in the middle in the team colour. 4 frames per row of the arrow bobbing up and down and glowing: high and dim, middle and bright, low and brightest, middle and bright.

Sheet layout: solid flat magenta #FF00FF background, nothing else on it (no shadows on the magenta, no ground, no imp). Two rows, all frames the same size and evenly spaced, no frame touching another: top row = BLUE team version (#3d7bff), bottom row = GOLD team version (#f2c45a). Same object in both rows, only the team colour changes. Do not use magenta or pink anywhere on the object. Landscape 3:2.

Style: same as the MegaBlast apprentice imp reference (attached image 1): cartoon, thick black outline, flat cel colours with light Doré-style engraving hatching in the shadows. Campaign palette: brick red, parchment, ember orange, old gold, wrought iron grey. Hell of Dante seen as a forge. Clean shapes that read at 40 px on a phone. No text, no letters, no numbers.
```

## Proposta 3 · Sigillo del girone

### `p3_sigillo_scena`

```
Image 1 is the main character of our game, a little blacksmith-apprentice imp. Copy him exactly (shapes, proportions, colours, horns, neckerchief, tail); do not reinterpret him.

A circular infernal sigil drawn in glowing lines on the ground under the imp: concentric circles like Dante's circles of hell, with nine small notches around the outer ring, glowing in the team colour, seen slightly from above as a flat ellipse. The imp's feet stand in the centre.

Scene: the imp of image 1, in three-quarter view facing right, standing in the middle of a flat painted brick platform of the Forge, in muted slate-blue bricks; behind, a dark muted slate-blue background with engraving hatching, darker and duller than the imp so that he stands out. The team colour in this scene is BLUE #3d7bff. Landscape 3:2.

Style: same as the MegaBlast apprentice imp reference (attached image 1): cartoon, thick black outline, flat cel colours with light Doré-style engraving hatching in the shadows. Campaign palette: brick red, parchment, ember orange, old gold, wrought iron grey. Hell of Dante seen as a forge. Clean shapes that read at 40 px on a phone. No text, no letters, no numbers.
```

### `p3_sigillo_foglio`

```
Image 1 is the main character of our game, a little blacksmith-apprentice imp: use it ONLY for the style and for the size of the object compared to him. Do not draw the imp.

The object: a circular infernal sigil of glowing lines, concentric circles like Dante's circles of hell with nine small notches around the outer ring, glowing in the team colour, seen slightly from above as a flat ellipse. 4 frames per row of the sigil slowly rotating: the notches move a little clockwise in each frame, the glow stays the same.

Sheet layout: solid flat magenta #FF00FF background, nothing else on it (no shadows on the magenta, no ground, no imp). Two rows, all frames the same size and evenly spaced, no frame touching another: top row = BLUE team version (#3d7bff), bottom row = GOLD team version (#f2c45a). Same object in both rows, only the team colour changes. Do not use magenta or pink anywhere on the object. Landscape 3:2.

Style: same as the MegaBlast apprentice imp reference (attached image 1): cartoon, thick black outline, flat cel colours with light Doré-style engraving hatching in the shadows. Campaign palette: brick red, parchment, ember orange, old gold, wrought iron grey. Hell of Dante seen as a forge. Clean shapes that read at 40 px on a phone. No text, no letters, no numbers.
```

## Proposta 4 · Cartiglio

### `p4_cartiglio_scena`

```
Image 1 is the main character of our game, a little blacksmith-apprentice imp. Copy him exactly (shapes, proportions, colours, horns, neckerchief, tail); do not reinterpret him.

A small parchment scroll ribbon floating above the imp's head, unrolled, with a team-colour wax seal on its left end, completely blank (no text, no symbols on the parchment).

Scene: the imp of image 1, in three-quarter view facing right, standing in the middle of a flat painted brick platform of the Forge, in muted slate-blue bricks; behind, a dark muted slate-blue background with engraving hatching, darker and duller than the imp so that he stands out. The team colour in this scene is BLUE #3d7bff. Landscape 3:2.

Style: same as the MegaBlast apprentice imp reference (attached image 1): cartoon, thick black outline, flat cel colours with light Doré-style engraving hatching in the shadows. Campaign palette: brick red, parchment, ember orange, old gold, wrought iron grey. Hell of Dante seen as a forge. Clean shapes that read at 40 px on a phone. No text, no letters, no numbers.
```

### `p4_cartiglio_foglio`

```
Image 1 is the main character of our game, a little blacksmith-apprentice imp: use it ONLY for the style and for the size of the object compared to him. Do not draw the imp.

The object: a small parchment scroll ribbon with a team-colour wax seal on its left end, completely blank (no text, no symbols on the parchment). 3 frames per row: rolled up, half unrolled, fully unrolled.

Sheet layout: solid flat magenta #FF00FF background, nothing else on it (no shadows on the magenta, no ground, no imp). Two rows, all frames the same size and evenly spaced, no frame touching another: top row = BLUE team version (#3d7bff), bottom row = GOLD team version (#f2c45a). Same object in both rows, only the team colour changes. Do not use magenta or pink anywhere on the object. Landscape 3:2.

Style: same as the MegaBlast apprentice imp reference (attached image 1): cartoon, thick black outline, flat cel colours with light Doré-style engraving hatching in the shadows. Campaign palette: brick red, parchment, ember orange, old gold, wrought iron grey. Hell of Dante seen as a forge. Clean shapes that read at 40 px on a phone. No text, no letters, no numbers.
```

## Criteri di accettazione

- [ ] l'apprendista è quello di R1 (forme, colori, corna, fazzoletto), non reinterpretato
- [ ] l'indicatore si legge subito ed è nel colore della squadra
- [ ] nella scena il personaggio spicca più dello sfondo
- [ ] fogli: magenta pieno, fotogrammi staccati e della stessa grandezza, riga blu sopra e oro sotto
- [ ] niente magenta o rosa sull'oggetto; nessuna scritta o numero

---

## Decisione

Approvata da Claude, 2026-11-02. È una scelta reversibile: sono immagini di proposta e il gioco non
cambia finché Sergio non sceglie. Le opzioni scartate senza immagine (alone, occhio di bue, gli altri
sbiaditi, un'altra fiammella) sono nella richiesta della designer.
