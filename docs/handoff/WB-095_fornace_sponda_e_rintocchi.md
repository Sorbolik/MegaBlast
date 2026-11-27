# WB-095 · La Fornace: la sponda in fondo e le medaglie dei rintocchi

- **Stato:** IMPLEMENTATA (prima: APPROVATA da Claude il 24 nov sulle richieste di Sergio)
- **Data:** 2026-11-24
- **Ramo della scheda:** `claude/project-thread-ft5von` (Codex la esegue da qui: `git fetch origin claude/project-thread-ft5von`, non serve che sia su `main`) · **Ramo delle immagini:** `design/WB-095`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-095` senza chiedere conferma (il repository è privato).

## Obiettivo

Nella Fornace ([docs/commesse.md](../commesse.md), «La Fornace») la goccia di Ossidiana si tira negli stampi appesi al muro.
- **La sponda:** in fondo a destra, dopo l'ultimo stampo, c'è un muro che rimanda indietro la goccia con un «toc», come una sponda di gomma. Ora nel gioco è un segnaposto (le sporgenze di ferro impilate, R3 a destra).
- **Le medaglie dei rintocchi:** un «rintocco» è un colpo della goccia sul ferro degli stampi nello stesso tiro. Si vince una medaglia la prima volta che un tiro fa 6 rintocchi e un'altra a 10.

Misure nel gioco: la sponda allo zoom più vicino è alta quasi tutto lo schermo (circa 700 px) e larga circa 150 px: nel foglio va alta **almeno 1400 px**. Le medaglie stanno in un disco di 128 px: nel foglio almeno 400 px.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-095/riferimenti/R1_medaglia_jackpot.png` | la medaglia del jackpot della Fornace (WB-094): le due medaglie nuove sono della stessa famiglia |
| R2 | `art/WB-095/riferimenti/R2_stampi.png` | gli stampi del muro, il ferro e il contorno |
| R3 | `art/WB-095/riferimenti/R3_fondo_del_muro.png` | il muro nel gioco: a destra la colonna di ferro segnaposto dove va la sponda |
| R4 | `art/WB-095/riferimenti/R4_sporgenza.png` | il ferro rivettato della Fornace (la sporgenza dove sta l'apprendista) |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto: il primo è "image 1", il secondo "image 2", il terzo "image 3".

| Nome file | Cosa c'è | Riferimenti | Misura | Varianti |
|---|---|---|---|---|
| `sponda` | la sponda di gomma in fondo al muro | R3, R4, R2 | 1024×1536 | 2 |
| `medaglie_rintocchi` | la medaglia dei 6 rintocchi e quella dei 10 | R1, R2 | 1536×1024 | 2 |

Le varianti si chiamano `sponda_1.png`, `sponda_2.png` e così via, in `art/WB-095/`. Per ogni foglio Codex scrive un `.txt` con lo stesso nome: cosa ha fatto e cosa non è riuscito a rispettare.

### `sponda`

```
Image 1 is a screenshot of the forge of our cartoon game: on the right edge there is a tall placeholder column of stacked iron pieces; it must be replaced. Image 2 shows the riveted iron of the forge (thick slightly irregular black ink outline, flat colors, one flat highlight, one flat shadow). Image 3 shows the casting moulds of the same forge.

Draw ONE tall BUMPER WALL for the right end of the forge, in the style of images 2 and 3, on plain green (#00FF00), centered, as TALL as the image (at least 1400 px) and about one fifth as wide as tall, seen straight from the front:
- a tall frame of riveted dark iron (#3A3238, highlight #5D5560) standing on the floor, with a heavy foot at the bottom and a cap at the top;
- on its LEFT face, facing the moulds, a thick soft BUMPER of dark red rubber (#8E2B2B, highlight #C2493F) running from bottom to top, bulging a little, made of four or five stacked rounded cushions held by iron straps, so it clearly bounces a ball back;
- a few dents and scratches on the rubber, one small soot stain.
Nothing else: no moulds, no chains, no floor, no letters, no numbers, no shadow on the ground, no glow.
```

### `medaglie_rintocchi`

```
Image 1 shows the jackpot medal of the forge of our cartoon game: a round gold medal with a raised studded rim and a drawing in relief in the middle, thick slightly irregular black ink outline, flat colors, one flat highlight. Image 2 shows the iron casting moulds of the same forge.

Draw TWO MEDALS of the same family as image 1, on plain green (#00FF00), side by side and well apart, each as big as almost half the image (at least 600 px wide), round, with the same raised studded rim as image 1. In the middle of each, in relief: a drop of molten obsidian (violet-black with glowing magenta-orange cracks) bouncing between iron moulds like those of image 2, its path drawn as a zigzag line of small sparks, and at every bounce a small starburst of short gold rays, like a bell being rung.
- on the LEFT the medal of 6 bounces: BRONZE (#C77A3A, highlight #E9A66B, shadow #8A4B1F), the zigzag with SIX bounces;
- on the RIGHT the medal of 10 bounces: SILVER-WHITE (#D9DEE8, highlight #FFFFFF, shadow #8B93A3) with a violet obsidian inlay on the rim, the zigzag with TEN bounces, a bigger and brighter starburst.
Nothing else: no ribbon, no letters, no numbers, no shadow on the ground, no glow halo around the medals.
```

## Criteri di accettazione

- [ ] sponda: una sola, alta almeno 1400 px, ferro rivettato come R4, gomma rossa a cuscini sul lato sinistro
- [ ] medaglie: due, bronzo (6) a sinistra e argento (10) a destra, stesso bordo con le borchie della medaglia del jackpot
- [ ] medaglie: la goccia che rimbalza fra gli stampi, 6 e 10 rimbalzi che si contano
- [ ] nessuna scritta, nessun numero, nessun alone, fondo verde pieno (si ritaglia)

---

## Decisione

Approvata da Claude il 24 nov sulle richieste di Sergio nella stessa giornata. Finché le immagini non ci sono il gioco usa il segnaposto per la sponda e le medaglie dei rintocchi non compaiono nel profilo (la regola le conta già).

## Consegna di Codex

- `art/WB-095/sponda_1.png` e `sponda_2.png`, con i rispettivi `.txt` — 1024×1536, un tentativo per variante.
- `art/WB-095/medaglie_rintocchi_1.png` e `medaglie_rintocchi_2.png`, con i rispettivi `.txt` — 1536×1024, un tentativo per la prima variante e due per la seconda, selezionato il secondo.

Prompt originali eseguiti con ImageGen e riferimenti nell'ordine indicato. I quattro PNG sono stati ridimensionati in proporzione e centrati su tela verde.

Le sponde sono intere, senza terreno o scritte, con ferro rivettato e gomma rossa sul lato sinistro. Sono alte circa 1479 e 1493 px. Le sagome sono larghe circa un terzo dell'altezza rispetto al quinto previsto. In entrambi i fogli delle medaglie, il bronzo è a sinistra e l'argento a destra. Ho verificato visivamente i 6 e 10 stampi lungo le traiettorie e larghezze di 717–731 px. Il fondo verde si discosta da #00FF00. La resa sul muro e la leggibilità delle medaglie a 128 px nel profilo restano da verificare.

## Resoconto di Claude

25 nov, Claude. I quattro fogli sono puliti. Ho scelto:
- `sponda_2`: cinque cuscini con le cinghie, si legge meglio come gomma che rimbalza;
- `medaglie_rintocchi_1`: in diagonale, si legge meglio piccola; l'argento ha l'intarsio di Ossidiana chiesto (nella 2 non c'è).

Le ha ritagliate `tools/grafica/fornace.py` nell'atlante `fornace`, al doppio della misura sullo schermo e mai ingrandite. La sponda è in tre pezzi: il piede e due tratti (cuscino e cinghia) che si impilano fino in cima alla vista, con la gomma sulla riga dove la goccia rimbalza. Le medaglie sono anche nell'atlante `fucina` (128 px, `tools/grafica/fucina.py`), come badge del profilo. Sergio ha chiesto anche quella degli 8 rintocchi: scheda WB-096.
