# WB-072 · Ossidiana, Scaglia e buono del Fabbro

- **Stato:** APPROVATA (Sergio, 18 nov 11:10: «per il resto vai con i consigliati», sul testo mostrato nella pagina delle proposte)
- **Data:** 2026-11-18
- **Ramo della scheda:** `claude/project-thread-echcwc` (Codex la esegue da qui: `git fetch origin claude/project-thread-echcwc`, non serve che sia su `main`) · **Ramo delle immagini:** `design/WB-072`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-072` senza chiedere conferma (il repository è privato).

## Obiettivo

Le monete di WB-071 non sono piaciute. Ogni icona prende la forma da una moneta e il rilievo dall'altra:

- **Ossidiana:** la gemma sfaccettata di oggi (R2, quella azzurra), ma col colore di quella di prima (R1 a destra): nera e viola col filo magenta.
- **Scaglia:** la forma di prima (R1 a sinistra, la scaglia a otto lati), col rilievo e la fiammella della moneta d'oro di oggi (R2).
- **Buono del Fabbro:** stesso stile e stessa misura delle due monete, senza cordino né targhetta (R4 è quello di oggi).

Il gioco le usa da 20 a 46 px: portafoglio, prezzi e pulsanti.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-072/riferimenti/R1_monete_iniziali.png` | le due monete com'erano all'inizio: a sinistra la scaglia a otto lati, a destra l'ossidiana nera col filo magenta |
| R2 | `art/WB-072/riferimenti/R2_monete_oggi.png` | le monete di oggi: la gemma azzurra sfaccettata e la moneta d'oro con la fiammella |
| R3 | `art/WB-072/riferimenti/R3_stile.png` | un pulsante della home: lo stile della china |
| R4 | `art/WB-072/riferimenti/R4_buono_oggi.png` | il buono del Fabbro di oggi, con la targhetta da togliere |
| R5 | `art/WB-072/riferimenti/R5_primo_giro.png` | il foglio `monete_2` del primo giro: forme e colori approvati |
| R6 | `art/WB-072/riferimenti/R6_fiamma_scavata.png` | la moneta d'oro di oggi: la fiammella sembra scavata dentro la moneta |

## Immagini da generare

Il prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine: il primo è "image 1", il secondo "image 2" e così via.

| Nome file | Cosa c'è | Riferimenti | Misura | Varianti |
|---|---|---|---|---|
| `monete` | Ossidiana, Scaglia e buono, uno accanto all'altro (primo giro, fatto) | R1, R2, R3, R4 | 1536×1024 | 3 |
| `scavate` | Scaglia e buono col disegno scavato (secondo giro) | R5, R6, R3 | 1536×1024 | 3 |

Le varianti si chiamano `monete_1.png`, `monete_2.png` e `monete_3.png`, in `art/WB-072/`. Per ogni foglio Codex scrive un `.txt` con lo stesso nome: cosa ha fatto e cosa non è riuscito a rispettare.

### `monete`

```
Image 1 shows the two currencies of our game as they were at the beginning: on the left the SCAGLIA, a gold flake with eight uneven sides, and on the right the OSSIDIANA, a dark obsidian shard with a bright magenta rim. Image 2 shows the same two currencies as they are today: a faceted light blue gem with strong 3D faces, and a thick gold coin with a raised rim and a little orange flame inside. Image 3 is a button of the same game and is the STYLE to copy exactly: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, soft hand-drawn slightly crooked shapes, like a cartoon comic. Image 4 is the voucher of the blacksmith we use today: a dark iron tag with an orange hammer and anvil and a red string; the tag shape and the string must go.

Draw THREE separate icons in a row, well apart, same visual size and same thickness, on plain green (#00FF00):
1. OSSIDIANA: the faceted gem of image 2, same diamond shape, same raised 3D faces, same light coming from the top left, but in the colors of the right icon of image 1: faces in near-black purples (#1A1220, #2E2140, #4A3366), a thin glowing magenta rim along the whole outline (#FF70D1), and one single pale pink highlight (#FFD6F2) on the top face.
2. SCAGLIA: the shape of the left icon of image 1 (a flake with eight uneven sides, a little crooked), with the thickness and relief of the gold coin of image 2: a raised rim, a darker side below that shows its thickness, and inside the same small orange flame (#F26419 with a #FFB703 core). Gold #FFB703, highlight #FFE08A, shadow #C77A06.
3. VOUCHER OF THE BLACKSMITH: a round, slightly crooked token of dark forged iron (#3A3340, highlight #5A5263, side #1E1A22), the same size and thickness as the other two, with the hammer on the anvil of image 4 raised on its face in orange (#F26419 and #FFB703). No string, no hole, no tag shape.
Each icon must read at 24 pixels: one bold full silhouette, no thin details. No letters, no numbers, no shadow on the ground, no glow outside the ink.
```

### `scavate` (secondo giro)

Sergio, 18 nov 11:17, sul primo giro: «va bene tutto, solo che mi piaceva il fatto che la
fiammella nella moneta desse l'idea di essere scavata nella moneta», «e anche nel buono del
fabbro voglio quell'effetto», «l'ossidiana va bene». Si rifanno solo Scaglia e buono; le varianti
si chiamano `scavate_1.png` e così via, in `art/WB-072/`.

```
Image 1 is a sheet of three icons of our game: in the middle the SCAGLIA (a gold coin with eight uneven sides and a little flame) and on the right the VOUCHER OF THE BLACKSMITH (a round dark iron token with a hammer on an anvil). Their shapes, colors, outline and thickness are approved and must stay exactly the same. Image 2 is the gold coin we used before: its little flame looks CARVED INTO the coin, sunk below the surface, not stuck on top of it. Image 3 is a button of the same game and is the STYLE: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, soft hand-drawn slightly crooked shapes, like a cartoon comic.

Draw TWO separate icons side by side, well apart, same visual size, on plain green (#00FF00):
1. SCAGLIA: exactly the middle icon of image 1 (same eight-sided gold coin, same rim, same thickness), but the flame is ENGRAVED into its face like in image 2: a hollow in the shape of the flame, sunk into the gold. Inside the hollow the flame in orange (#F26419 with a #FFB703 core), lower than the surface; along the upper left edge of the hollow a dark shadow band (#C77A06 and black ink), along the lower right edge a thin light band (#FFE08A), so the cut looks deep. No flame sticking out above the surface.
2. VOUCHER OF THE BLACKSMITH: exactly the right icon of image 1 (same round dark iron token, same size and thickness), but the hammer on the anvil is ENGRAVED into the iron the same way: a hollow in the shape of the hammer and anvil, sunk into the face, with a dark shadow band (#1E1A22 and black ink) along its upper left edge and a thin light band (#5A5263) along its lower right edge; inside the hollow the hammer and anvil glow orange (#F26419 and #FFB703) like hot metal poured into a mold.
Each icon must read at 24 pixels: one bold full silhouette, no thin details. No letters, no numbers, no shadow on the ground, no glow outside the ink.
```

## Criteri di accettazione

- [x] contorno nero spesso, nessuna scritta, tre icone ben staccate sul verde
- [x] l'ossidiana ha la forma sfaccettata di oggi e i colori di prima (nera e viola, filo magenta)
- [x] la scaglia ha gli otto lati di prima, il rilievo e la fiammella dentro
- [x] il buono è un gettone di ferro senza cordino né targhetta, grande quanto le monete
- [x] tutte e tre si riconoscono a 24 px
- [x] secondo giro: fiammella e martello sembrano scavati dentro la moneta e il gettone, non appoggiati sopra

---

## Decisione

Sergio, 18 nov 10:40: «né l'ossidiano che ha prodotto, né le scaglie mi piacciono, mi piace l'idea della tridimensionalità dell'ossidiana "nuova", quella azzurra, ma vorrei il colore di quella vecchia, invece mi piace l'idea della fiammella dentro le scaglie nuove, ma la forma delle vecchie» e «sempre l'idea di tridimensionalità delle scaglie nuove». Poi: «rifacciamo anche i buoni del Fabbro, devono essere nello stesso concept e formato, senza la targhetta». Il testo è stato mostrato nella pagina delle proposte e approvato con «vai con i consigliati» (11:10). Numero assegnato dal coordinatore.

## Consegna di Codex

- Primo giro: `monete_1.png`, `monete_2.png`, `monete_3.png` con i `.txt` (Codex, ramo `design/WB-072`). Sergio, 11:17: l'Ossidiana va bene; Scaglia e buono si rifanno col disegno scavato (secondo giro, `scavate`).

- Secondo giro: `art/WB-072/scavate_1.png`, `scavate_2.png` e `scavate_3.png`, con i tre `.txt` omonimi. Un tentativo per variante con ImageGen integrato, prompt integrale e riferimenti R5, R6, R3 in ordine.

Verificati contorni spessi, separazione, assenza di scritte e riconoscibilità di fiammella, martello e incudine a 24 px. L'incisione è visibile a piena risoluzione dalla fascia scura sopra e dal bordo chiaro sotto. A 24 px la profondità si attenua, soprattutto sul buono. Le sagome riprendono R5 con piccole differenze di profilo e proporzioni. I fogli sono stati ridotti in proporzione e centrati su tela verde da 1536×1024. Il verde generato si discosta leggermente da #00FF00. Ritaglio e resa in gioco da verificare.

## Resoconto di Claude

- 18 nov: Sergio approva le monete («mi piacciono le monete prodotte dalla wb72»). Nel gioco:
  Ossidiana da `monete_2` (la sinistra), Scaglia e buono da `scavate_2` (scelta di Claude: la
  fiammella e il martello più scavati, e reggono a 24 px). Le taglia `tools/grafica/fucina.py`
  (`fai_monete`) nei pezzi `gemma`, `scaglia` e `buono`, alti uguali. Scartate `monete_1`,
  `monete_3`, `scavate_1` e `scavate_3` (restano nel ramo come storia). Simulazione OK
  (`zaino_scheda.txt`): portafoglio, prezzi e pulsanti secondari si leggono.
- [x] tutti i criteri rispettati; a 24 px l'incisione del buono si attenua ma martello e incudine si riconoscono.

