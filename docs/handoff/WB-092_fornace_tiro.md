# WB-092 · La Fornace: sfondo, sporgenza, stampi, goccia, catene e secchio del Tiro nella Fucina

- **Stato:** APPROVATA (Claude, 24 nov: pezzi nuovi, non sostituiscono disegni di Codex; Sergio ha scelto Il Tiro nella Fucina sulla pagina delle bozze)
- **Data:** 2026-11-24
- **Ramo della scheda:** `claude/project-thread-ft5von` (Codex la esegue da qui: `git fetch origin claude/project-thread-ft5von`, non serve che sia su `main`) · **Ramo delle immagini:** `design/WB-092`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-092` senza chiedere conferma (il repository è privato).

## Obiettivo

La Fornace è il minigioco dove l'Ossidiana diventa Scaglie e frammenti ([docs/commesse.md](../commesse.md), sezione «La Fornace»): l'apprendista tira una goccia di Ossidiana fusa con la mira della battaglia negli stampi appesi al muro della fucina. Nella bozza (R1) stampi, goccia, catene e secchio sono segnaposto. Servono i disegni veri.

**Lo sfondo è dedicato** (Sergio, 24 nov): la fucina del Tiro è una piccola mappa (circa 1.700 × 900 unità del gioco) e la telecamera è quella della battaglia, che si allarga, si stringe e segue la goccia. Per questo lo sfondo è a **quattro piani** come quelli delle mappe (cielo, lontano, medio, vicino), che il gioco fa scorrere a velocità diverse. Le regole degli sfondi valgono anche qui: **nessun contorno nero** nei piani, forme grandi e piatte, pochi dettagli, tutto scuro e poco saturo, la luce calda della fornace in basso a sinistra e un filo di gelo in alto a destra, il centro calmo perché lì volano la goccia e i puntini. La sporgenza dell'apprendista e il pavimento invece sono del gioco come il terreno: quelli hanno il contorno a china.

Misure nel gioco (schermo 1280×720): uno stampo grande è largo circa 120 px, uno piccolo circa 80 px; la goccia circa 40 px; il secchio circa 140 px. Codex disegna **almeno al doppio** (stampo grande largo almeno 300 px nel foglio) perché resti nitido sugli schermi grandi.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-092/riferimenti/R1_bozza_tiro.png` | la bozza del minigioco: l'apprendista a sinistra, la traiettoria a puntini, gli stampi segnaposto sul muro |
| R2 | `art/WB-092/riferimenti/R2_bottega_oggi.png` | la BOTTEGA com'è oggi nel gioco: lo STILE dell'interfaccia e degli oggetti (contorno di china, colori piatti) |
| R3 | `art/WB-084/frammenti_1.png` | i frammenti delle cinque famiglie: lo stile degli oggetti piccoli e i colori delle famiglie |
| R4 | `art/WB-092/riferimenti/R4_muro_in_scala.png` | il muro in scala con la fisica vera: l'apprendista in basso a sinistra sulla sporgenza, gli stampi sparsi a destra fino in fondo, il secchio a terra. Dice DOVE stanno le cose, non come sono disegnate |
| R5 | `client/paintings/backgrounds/forgia_medio_2.png` | un piano di sfondo di una mappa della battaglia: la mano e i toni degli sfondi del gioco (niente contorno nero, forme grandi, pochi dettagli) |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto: il primo è "image 1", il secondo "image 2", il terzo "image 3".

| Nome file | Cosa c'è | Riferimenti | Misura | Varianti |
|---|---|---|---|---|
| `fucina_cielo` | il fondo della fucina: la parete lontana con la luce | R4, R5 | 1536×1024 | 2 |
| `fucina_lontano` | fornaci e camini lontani | R4, R5 | 1536×1024 | 2 |
| `fucina_medio` | travi, ganci e il calderone appeso, sui lati | R4, R5 | 1536×1024 | 2 |
| `fucina_vicino` | ombre vicine in basso e sui bordi | R4, R5 | 1536×1024 | 2 |
| `sporgenza` | la sporgenza dell'apprendista e un pezzo di pavimento | R1, R2 | 1536×1024 | 2 |
| `stampi` | sei stampi vuoti e sei pieni di metallo fuso | R1, R2, R3 | 1536×1024 | 2 |
| `goccia_e_secchio` | la goccia di Ossidiana fusa, due schizzi, il secchio, un pezzo di catena | R1, R2 | 1536×1024 | 2 |

Le varianti si chiamano `stampi_1.png`, `stampi_2.png`, `goccia_e_secchio_1.png`, `goccia_e_secchio_2.png`, in `art/WB-092/`. Per ogni foglio Codex scrive un `.txt` con lo stesso nome: cosa ha fatto e cosa non è riuscito a rispettare.

### `fucina_cielo`

```
Image 1 shows the layout of a minigame of our game: a little devil stands on a ledge at the bottom left and throws drops of molten metal into casting moulds hanging all over the right part of a big forge room; it only says WHERE things are. Image 2 is one background layer of our game: copy its HAND and its TONES exactly: no black outline at all, big simple flat shapes with soft gradients, very few details, dark and desaturated colors, bright colors only in the lights.

Paint the FARTHEST layer of the background of that forge room, wide (3:2), filling the whole image edge to edge: the far back wall of a huge dark infernal forge hall, a deep dark warm brown-violet (#1E1219 to #3A2224), lit from the BOTTOM LEFT by the warm orange glow of a great furnace (the glow only, the furnace is in another layer) and touched in the TOP RIGHT corner by a thin cold blue-white light falling from a high cracked window of ice. Big soft shapes only: the curve of a vault, the hint of tall arches. The CENTER and the RIGHT half stay calm and dark, because the game draws moulds, chains and the flying drop there. No outlines, no characters, no objects, no letters, no frame.
```

### `fucina_lontano`

```
Image 1 shows the layout of a minigame of our game: a little devil stands on a ledge at the bottom left and throws drops of molten metal into casting moulds hanging all over the right part of a big forge room. Image 2 is one background layer of our game: copy its HAND and its TONES exactly: no black outline at all, big simple flat shapes with soft gradients, very few details, dark and desaturated colors.

Paint the FAR layer of that forge room, wide (3:2), on plain green (#00FF00) above and around the shapes so it can be cut out: along the BOTTOM edge, a low skyline of distant furnaces, chimneys and big bellows seen as soft dark silhouettes (#2A1A1E to #4A2A26), with two or three small glowing furnace mouths in warm orange; the shapes are taller on the LEFT (the hot side) and lower on the right. Nothing in the top two thirds except the green. No outlines, no characters, no letters, no frame.
```

### `fucina_medio`

```
Image 1 shows the layout of a minigame of our game: a little devil stands on a ledge at the bottom left and throws drops of molten metal into casting moulds hanging all over the right part of a big forge room. Image 2 is one background layer of our game: copy its HAND and its TONES exactly: no black outline at all, big simple flat shapes with soft gradients, few details, dark and desaturated colors.

Paint the MIDDLE layer of that forge room, wide (3:2), on plain green (#00FF00) so it can be cut out: big dark wooden and iron ceiling beams crossing the TOP edge, with a few empty iron hooks hanging from them (the game hangs the moulds and chains itself); on the far LEFT a tall pillar of brick and iron with the warm glow of the furnace on it; on the far RIGHT the edge of a big hanging cauldron and a pulley. The whole middle of the image, from left to right and from the beams down to the bottom, stays EMPTY green: the flight of the drop goes there. No outlines, no moulds, no characters, no letters.
```

### `fucina_vicino`

```
Image 2 is one background layer of our game: copy its HAND exactly: no black outline at all, big simple flat shapes, very few details. 

Paint the NEAREST layer of a dark infernal forge room, wide (3:2), on plain green (#00FF00) so it can be cut out: only near, almost black, slightly blurred shapes along the BOTTOM edge and in the two bottom corners: an anvil on the left, a heap of coal and tongs, a wooden crate on the right, a few warm sparks and a thin rim of orange light on their edges. They take at most the bottom fifth of the image. Everything else is green. No outlines, no characters, no letters.
```

### `sporgenza`

```
Image 1 is a draft of a minigame of our cartoon game: a little devil stands on a ledge at the bottom left of a forge and throws drops of molten metal. Image 2 shows the STYLE of our game: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, hand-drawn like a cartoon comic.

Draw two separate pieces on plain green (#00FF00), well apart, each whole:
1. THE LEDGE: a sturdy block where the little devil stands to throw, as wide as it is tall: a stack of big dark stone bricks and riveted iron plates (#3A2A24, #5D4A40, iron #3A3238), with a FLAT TOP surface (the devil stands on it) and a thin warm orange rim of light on its left side.
2. THE FLOOR: a long low strip of the forge floor, four times wider than tall, dark stone slabs with a few iron grates glowing faintly orange, a FLAT TOP edge; its left and right ends are cut straight so the game can repeat it side by side.
Thick black ink outline on both, flat colors. No characters, no letters, no shadow on the ground, no glow halo.
```

### `stampi`

```
Image 1 is a draft of a minigame of our cartoon game: a little devil throws a drop of molten obsidian into casting moulds hanging on the wall of a blacksmith's forge; the moulds in the draft are placeholders. Image 2 shows the STYLE of our game: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, hand-drawn like a cartoon comic. Image 3 shows small objects in that style and the five family colors: gold, ice blue, fire orange, sea green, violet.

Draw TWELVE separate casting moulds on plain green (#00FF00), in two rows of six, well apart from each other, each one whole and not touching the others:
- TOP ROW, six EMPTY moulds: open cast-iron casting cups seen from the front and a little from above, so the opening is visible as a dark empty hollow. Dark iron (#3A3238, highlight #5D5560) with a thick black ink outline, a rounded bottom, two small iron ears on the top edge with a ring each (to hang them on a chain). Each mould has a small flat round plate on its front, EMPTY and one plain color, where the game will put an icon: from left to right the plate is gold (#FFB703), ice blue (#8FD8F5), fire orange (#F26419), sea green (#5CDBB8), violet (#C49CFF), and plain iron (#5D5560). Three moulds are big and three are small (about two thirds of the big ones): big, small, big, small, big, small.
- BOTTOM ROW, the SAME six moulds in the same order and size, now FULL: the hollow is filled to the brim with glowing molten metal, bright orange-yellow (#FFB703 and #FF7A1A) with one flat white-yellow highlight, a thin wisp of steam, a little drip running down one side. Same outline, same plate colors.
Nothing else in the image: no chains, no wall, no icons on the plates, no letters, no numbers, no shadow on the ground, no glow halo around the moulds.
```

### `goccia_e_secchio`

```
Image 1 is a draft of a minigame of our cartoon game: a little devil throws a drop of molten obsidian into casting moulds hanging on the wall of a forge. Image 2 shows the STYLE of our game: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, hand-drawn like a cartoon comic.

Draw these separate objects on plain green (#00FF00), well apart from each other, each one whole and not touching the others:
1. THE DROP: one round drop of molten obsidian, deep violet-black (#2A1438) with a hot magenta-orange glowing core (#FF70D0 and #FF7A1A) seen through cracks, one flat white highlight, a thick black ink outline. Draw it three times in a row: round, stretched in flight (pointing right, with a short tail), squashed flat at impact.
2. TWO SPLASHES: two small splashes of molten metal, orange-yellow drops flying outwards in a crown shape, one small and one big, flat colors and black outline.
3. THE BUCKET: a battered old iron bucket full of cooled grey slag and a few lumps, seen from the front, dented, with a bent handle, big enough to be a target on the floor; it is where missed drops fall.
4. A CHAIN: one straight vertical piece of iron chain of about twelve links, dark iron with black outline, to be repeated by the game; the top and bottom links are cut flat so that pieces join seamlessly.
No letters, no numbers, no wall, no floor, no shadow on the ground, no glow halo.
```

## Criteri di accettazione

- [ ] sfondo: quattro piani della stessa stanza, senza contorno nero, scuri, luce calda in basso a sinistra e fredda in alto a destra, il centro vuoto e calmo
- [ ] sfondo: lontano, medio e vicino si ritagliano dal verde; il cielo riempie tutta l'immagine
- [ ] sporgenza: piano di sopra piatto, contorno a china; il pavimento si ripete senza cuciture
- [ ] stampi: dodici stampi separati, sei vuoti sopra e sei pieni sotto, stesso ordine e stessa misura fra le due righe
- [ ] stampi: la placca davanti è vuota e di un colore solo (il gioco ci mette l'icona), coi colori delle cinque famiglie e uno di ferro
- [ ] stampi: lo stampo grande è largo almeno 300 px nel foglio
- [ ] goccia: tre pose (tonda, in volo, schiacciata), viola scuro col cuore che brilla, contorno di china
- [ ] catena: pezzo dritto che si ripete senza cuciture
- [ ] contorno di china e colori piatti come R2, nessuna scritta, fondo verde pieno (si ritaglia)

---

## Decisione

Approvata da Claude il 24 nov (sfondo dedicato aggiunto su richiesta di Sergio): pezzi nuovi per la Fornace, niente di Codex viene sostituito. Sergio ha scelto il minigioco sulla pagina https://claude.ai/artifact/JSm7FyZ8HkhchARfBT8LTU .

## Consegna di Codex

- `art/WB-092/fucina_cielo_1.png`, `fucina_cielo_2.png`, `fucina_lontano_1.png`, `fucina_lontano_2.png`, `fucina_medio_1.png`, `fucina_medio_2.png`, `fucina_vicino_1.png`, `fucina_vicino_2.png` — un tentativo ciascuno.
- `art/WB-092/sporgenza_1.png` e `sporgenza_2.png` — tre tentativi ciascuna, selezionati il secondo e il terzo rispettivamente.
- `art/WB-092/stampi_1.png` e `stampi_2.png` — tre tentativi ciascuno, selezionato il terzo.
- `art/WB-092/goccia_e_secchio_1.png` e `goccia_e_secchio_2.png` — due tentativi per la prima variante, selezionato il secondo; un tentativo per la seconda.

Quattordici PNG da 1536×1024 e altrettanti `.txt` con prompt originali, riferimenti in ordine e note per variante. Gli otto piani hanno la misura nativa richiesta. I sei fogli di oggetti sono stati ridimensionati in proporzione e centrati su tela verde.

Verificati entrambi gli insiemi di quattro piani in sovrapposizione statica. Il centro rimane calmo, con luce arancione in basso a sinistra e fredda in alto a destra. I camini più alti risalgono oltre il terzo inferiore. I fondi verdi sono vicini a #00FF00 e si discostano dal valore esatto.

Le sporgenze hanno il piano superiore piatto. Le strisce di pavimento sono più lunghe del rapporto 4:1. I fogli degli stampi contengono dodici pezzi separati con le placche nell'ordine richiesto, con piccoli segni e riflessi su alcune placche. Gli stampi grandi vuoti misurano circa 252–258 px al contorno, sotto il minimo di 300 px. I due fogli degli effetti hanno le tre pose della goccia, gli schizzi, il secchio e la catena separati. Restano da verificare la ripetizione senza cuciture di pavimento e catena e la resa durante il movimento della telecamera in gioco.

## Resoconto di Claude
