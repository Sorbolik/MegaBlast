# WB-094 · La Fornace: il coperchio dello stampo preso, la fiammata e la medaglia del jackpot

- **Stato:** APPROVATA (Claude, 24 nov: pezzi nuovi scelti da Sergio sulla pagina https://claude.ai/artifact/LcTuEFuH5XKmmmeDPgtGN2, «ok le consigliate»; non sostituiscono disegni già nel gioco)
- **Data:** 2026-11-24
- **Ramo della scheda:** `claude/project-thread-ft5von` (Codex la esegue da qui: `git fetch origin claude/project-thread-ft5von`, non serve che sia su `main`) · **Ramo delle immagini:** `design/WB-094`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-094` senza chiedere conferma (il repository è privato).

## Obiettivo

Nella Fornace ([docs/commesse.md](../commesse.md), «La Fornace») la goccia di Ossidiana entra negli stampi appesi al muro. Sergio ha scelto (pagina delle bozze, R2):
- **la fiammata** quando la goccia entra: dalla bocca dello stampo sale una colonna di fuoco di Ossidiana;
- **il coperchio sigillato** per lo stampo già preso: un coperchio di ferro scende e chiude la bocca, sopra il gioco mette l'icona del premio preso;
- **la medaglia «Jackpot della Fornace»**, che si vince la prima volta che si riempiono tutti i 12 stampi di un muro.

Lo stampo pieno di metallo fuso di WB-093 non si usa più: la goccia rimbalza come una biglia e la «melma» che riempie non regge (Sergio, 24 nov).

Misure nel gioco: allo zoom più vicino uno stampo grande è largo circa 180 px, uno piccolo 120 px. Il coperchio grande va largo nel foglio **almeno 400 px**, il piccolo almeno 280 px. La colonna di fuoco è alta circa 3 volte lo stampo: nel foglio ogni fotogramma va alto **almeno 700 px**. La medaglia sta in un disco di 128 px: nel foglio almeno 400 px.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-094/riferimenti/R1_stampi_vuoti.png` | gli stampi grandi vuoti di WB-093, quelli nel gioco: il coperchio deve calzare sulla loro bocca, con lo stesso ferro e lo stesso contorno |
| R2 | `art/WB-094/riferimenti/R2_bozze_animate.png` | le bozze scelte da Sergio: in alto al centro la fiammata (colonna di fuoco dalla bocca), in basso a sinistra il coperchio sigillato. Sono segnaposti disegnati da Claude: dicono solo l'idea e le proporzioni |
| R3 | `art/WB-094/riferimenti/R3_goccia.png` | la goccia di Ossidiana del gioco (la palla viola-nera con le crepe magenta-arancio): i colori del fuoco di Ossidiana |
| R4 | `art/WB-094/riferimenti/R4_medaglia_di_un_cliente.png` | la medaglia di un cliente nel gioco: lo stile delle medaglie del profilo (disegno al centro di un disco, contorno di china) |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto: il primo è "image 1", il secondo "image 2", il terzo "image 3".

| Nome file | Cosa c'è | Riferimenti | Misura | Varianti |
|---|---|---|---|---|
| `coperchi` | il coperchio grande e il coperchio piccolo | R1, R2 | 1536×1024 | 2 |
| `fiammata` | quattro fotogrammi della colonna di fuoco | R2, R3 | 1536×1024 | 2 |
| `medaglia_jackpot` | la medaglia del jackpot | R4, R1, R3 | 1024×1024 | 2 |

Le varianti si chiamano `coperchi_1.png`, `coperchi_2.png` e così via, in `art/WB-094/`. Per ogni foglio Codex scrive un `.txt` con lo stesso nome: cosa ha fatto e cosa non è riuscito a rispettare.

### `coperchi`

```
Image 1 shows the casting moulds of our cartoon game: dark cast iron, thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, two little ears with a ring on the top edge. Image 2 is a rough draft: on the bottom left an iron LID closes the mouth of a mould that has been filled (the draft lid is only a placeholder for the idea and the size).

Draw TWO iron LIDS for the moulds of image 1, in the same style as image 1, on plain green (#00FF00), side by side and well apart: on the left a BIG lid as wide as the mouth of the big moulds of image 1 plus a little (at least 400 px wide), on the right a SMALL lid two thirds as wide (at least 280 px wide). Each lid is seen from the front and a little from above, exactly the angle of the moulds of image 1, so it can sit on their mouth:
- a flat round cast-iron lid (#3A3238, highlight #5D5560), a thick rim all around, its top slightly domed;
- in the middle of the top a flat round EMPTY boss, a little lighter (#4A4248), where the game will put an icon;
- four small rivets around the boss;
- along the lower edge, where the lid meets the mould, a thin glowing seam of molten metal, bright orange (#FF7A1A) with a yellow core (#FFB703), as if the lid was just sealed on the hot metal;
- the two lids are identical except the size.
Nothing else: no mould under them, no handle, no icons, no letters, no numbers, no shadow on the ground, no glow halo outside the seam.
```

### `fiammata`

```
Image 1 is a rough draft: in the top middle a column of fire bursts up from the mouth of a mould when a drop of molten obsidian falls in (the draft fire is only a placeholder for the idea and the size). Image 2 shows the drop of molten obsidian of our cartoon game: a violet-black ball with glowing magenta-orange cracks; its colors are the colors of this fire.

Draw FOUR frames of a short burst of OBSIDIAN FIRE shooting straight UP, in the style of a cartoon comic (thick slightly irregular black ink outline, flat colors, flat highlights), on plain green (#00FF00), side by side from left to right, each frame in its own quarter of the image, each frame as TALL as the image (at least 700 px) and about a third as wide as tall, all four with the same BASE: a flat narrow mouth at the bottom center of each quarter, as wide as a quarter of its frame, where the fire comes out.
- frame 1: the fire just bursts out, a short fat tongue of flame, one third of the height;
- frame 2: a tall column at full height, narrow at the base and wider at the top, with curling tongues on the sides;
- frame 3: the column at full height breaking up at the top into flying tongues and sparks;
- frame 4: the column falling back, only the lower half left, thin and broken, a few sparks.
The fire is white-yellow at its core (#FFF1C2), then bright orange (#FF7A1A) and gold (#FFB703), with violet and magenta tongues and edges (#C24BFF, #FF3DA5) like the cracks of the drop of image 2. A few round sparks in the same colors around it.
Nothing else: no mould, no ground, no smoke clouds, no letters, no glow halo, no background color other than the green.
```

### `medaglia_jackpot`

```
Image 1 shows a medal of our cartoon game: a drawing in the middle of a round disc, thick slightly irregular black ink outline, flat colors, one flat highlight. Image 2 shows the casting moulds of the forge of our game. Image 3 shows the drop of molten obsidian of our game.

Draw the JACKPOT MEDAL of the forge, in the style of image 1, on plain green (#00FF00), centered, as big as most of the image (at least 700 px wide): a round GOLD medal (#FFB703, highlight #FFE08A, shadow #C98A00) with a thick raised rim and a ring of small round studs on the rim; in the middle, in relief, ONE mould like the moulds of image 2, seen from the front, overflowing with the violet obsidian fire of image 3, with three little drops jumping out of it and a starburst of short gold rays behind it, like a slot-machine jackpot.
Nothing else: no ribbon, no letters, no numbers, no shadow on the ground, no glow halo around the medal.
```

## Criteri di accettazione

- [ ] coperchi: due, grande e piccolo, identici tranne la misura, stesso ferro e stesso contorno degli stampi di R1, visti dalla stessa angolazione
- [ ] coperchi: il cerchio al centro vuoto (nessuna icona), la cucitura di metallo fuso solo sul bordo in basso
- [ ] fiammata: quattro fotogrammi in fila, stessa base al centro in basso, colori del fuoco di Ossidiana (giallo-arancio al centro, viola e magenta ai bordi)
- [ ] fiammata: ogni fotogramma alto almeno 700 px
- [ ] medaglia: oro, uno stampo al centro che trabocca di fuoco viola, raggi dietro, nessuna scritta
- [ ] nessuna scritta, nessun alone, fondo verde pieno (si ritaglia)

---

## Decisione

Approvata da Claude il 24 nov: Sergio ha scelto la fiammata, il coperchio sigillato e il jackpot con la medaglia («ok le consigliate», decisione «Medaglia + 500 Scaglie») sulla pagina https://claude.ai/artifact/LcTuEFuH5XKmmmeDPgtGN2 . Finché le immagini non ci sono il gioco usa segnaposti.

## Consegna di Codex

- `art/WB-094/coperchi_1.png` e `coperchi_2.png`, con i rispettivi `.txt` — 1536×1024, un tentativo per variante.
- `art/WB-094/fiammata_1.png` e `fiammata_2.png`, con i rispettivi `.txt` — 1536×1024, un tentativo per la prima variante e tre per la seconda (selezionato il terzo).
- `art/WB-094/medaglia_jackpot_1.png` e `medaglia_jackpot_2.png`, con i rispettivi `.txt` — 1024×1024, un tentativo per variante.

Prompt originali eseguiti con ImageGen e riferimenti nell'ordine indicato. R4 è il ritratto di una cliente, anche se la scheda lo descrive come esempio di medaglia su disco. È stato allegato come indicato. Ho ridimensionato coperchi e fiammate in proporzione e centrato i fogli su verde. Per le medaglie ho ritagliato solo il verde laterale.

Controllati numero, separazione, assenza di scritte e misure. I coperchi hanno il centro vuoto e la cucitura luminosa in basso, con larghezze sopra 400 e 280 px rispettivamente. Le medaglie superano 700 px di larghezza. Le fiammate hanno quattro pose con basi allineate. I fotogrammi centrali a piena altezza misurano circa 869–941 px. Apertura e chiusura sono più corte secondo il prompt e non raggiungono il criterio di 700 px per ogni sagoma. Nella seconda variante, le pose occupano solo la parte centrale della larghezza della tela. Il fondo è verde, con scostamenti da #00FF00. Restano da verificare l'accoppiamento dei coperchi agli stampi e la resa in gioco della sequenza.

## Resoconto di Claude
