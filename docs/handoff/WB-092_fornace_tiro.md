# WB-092 · La Fornace: stampi, goccia, catene e secchio del Tiro nella Fucina

- **Stato:** APPROVATA (Claude, 24 nov: pezzi nuovi, non sostituiscono disegni di Codex; Sergio ha scelto Il Tiro nella Fucina sulla pagina delle bozze)
- **Data:** 2026-11-24
- **Ramo della scheda:** `claude/project-thread-ft5von` (Codex la esegue da qui: `git fetch origin claude/project-thread-ft5von`, non serve che sia su `main`) · **Ramo delle immagini:** `design/WB-092`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-092` senza chiedere conferma (il repository è privato).

## Obiettivo

La Fornace è il minigioco dove l'Ossidiana diventa Scaglie e frammenti ([docs/commesse.md](../commesse.md), sezione «La Fornace»): l'apprendista tira una goccia di Ossidiana fusa con la mira della battaglia negli stampi appesi al muro della fucina. Nella bozza (R1) stampi, goccia, catene e secchio sono segnaposto. Servono i disegni veri.

Misure nel gioco (schermo 1280×720): uno stampo grande è largo circa 120 px, uno piccolo circa 80 px; la goccia circa 40 px; il secchio circa 140 px. Codex disegna **almeno al doppio** (stampo grande largo almeno 300 px nel foglio) perché resti nitido sugli schermi grandi.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-092/riferimenti/R1_bozza_tiro.png` | la bozza del minigioco: l'apprendista a sinistra, la traiettoria a puntini, gli stampi segnaposto sul muro |
| R2 | `art/WB-092/riferimenti/R2_bottega_oggi.png` | la BOTTEGA com'è oggi nel gioco: lo STILE dell'interfaccia e degli oggetti (contorno di china, colori piatti) |
| R3 | `art/WB-084/frammenti_1.png` | i frammenti delle cinque famiglie: lo stile degli oggetti piccoli e i colori delle famiglie |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto: il primo è "image 1", il secondo "image 2", il terzo "image 3".

| Nome file | Cosa c'è | Riferimenti | Misura | Varianti |
|---|---|---|---|---|
| `stampi` | sei stampi vuoti e sei pieni di metallo fuso | R1, R2, R3 | 1536×1024 | 2 |
| `goccia_e_secchio` | la goccia di Ossidiana fusa, due schizzi, il secchio, un pezzo di catena | R1, R2 | 1536×1024 | 2 |

Le varianti si chiamano `stampi_1.png`, `stampi_2.png`, `goccia_e_secchio_1.png`, `goccia_e_secchio_2.png`, in `art/WB-092/`. Per ogni foglio Codex scrive un `.txt` con lo stesso nome: cosa ha fatto e cosa non è riuscito a rispettare.

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

- [ ] stampi: dodici stampi separati, sei vuoti sopra e sei pieni sotto, stesso ordine e stessa misura fra le due righe
- [ ] stampi: la placca davanti è vuota e di un colore solo (il gioco ci mette l'icona), coi colori delle cinque famiglie e uno di ferro
- [ ] stampi: lo stampo grande è largo almeno 300 px nel foglio
- [ ] goccia: tre pose (tonda, in volo, schiacciata), viola scuro col cuore che brilla, contorno di china
- [ ] catena: pezzo dritto che si ripete senza cuciture
- [ ] contorno di china e colori piatti come R2, nessuna scritta, fondo verde pieno (si ritaglia)

---

## Decisione

Approvata da Claude il 24 nov: pezzi nuovi per la Fornace, niente di Codex viene sostituito. Sergio ha scelto il minigioco sulla pagina https://claude.ai/artifact/JSm7FyZ8HkhchARfBT8LTU .

## Consegna di Codex

## Resoconto di Claude
