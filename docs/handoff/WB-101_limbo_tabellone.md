# WB-101 · Il Limbo come tabellone: le pedine e i luoghi sulla fetta

- **Stato:** IMPLEMENTATA (28 nov, PR #449). APPROVATA (Sergio, 28 nov 2026: «per i personaggi voglio una loro versione in pedina, non voglio che si muovano con le animazioni, per il resto va bene la A, non c'è bisogno che sia in movimento o che sia troppo complesso, e i disegni di codex basta che siano semplici e nello stile del cerchio proprio del girone, vai»)
- **Data:** 2026-11-28
- **Ramo della scheda:** `claude/project-thread-t9n34l` (Codex la esegue da qui: `git fetch origin claude/project-thread-t9n34l`, non serve che sia su `main`) · **Ramo delle immagini:** `design/WB-101`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-101` senza chiedere conferma (il repository è privato).

## Obiettivo

La mappa della campagna diventa un gioco da tavolo **sulla fetta del Limbo di oggi** (`fetta_limbo`, WB-026): l'apprendista
e il Fabbro sono due **pedine** che camminano a saltelli su un sentiero di pietre, da un luogo all'altro del girone. Ogni
livello è un luogo del Limbo di Dante, piccolo e semplice, nello stile della fetta. La proposta scelta da Sergio è la «1 · I
luoghi» della pagina https://claude.ai/artifact/2VcsQ5zvCwDQNqS1hnhSGF (R4): ferma, senza animazioni dei luoghi.

Le pedine **non sono animate**: sono figurine dipinte su una base tonda, come i pezzi di un gioco da tavolo. Il gioco le
fa solo saltellare intere da una pietra all'altra.

## Cosa teniamo e cosa scartiamo

| Teniamo | Perché |
|---|---|
| La fetta del Limbo di oggi (R1), vista, colori, china | Sergio: «nello stile del cerchio proprio del girone» |
| Luoghi piccoli e semplici, forme grandi | nel gioco sono larghi da 60 a 200 px |
| La leva di WB-099 (R5) per il livello 2 | c'è già |
| Le braci della fucina (`brace`, `brace_spenta`) come segno del livello vinto | ci sono già |

| Scartiamo | Perché |
|---|---|
| Personaggi animati, pose d'azione | Sergio: «una loro versione in pedina» |
| Anime che vagano, nebbia, fumo, cose che si muovono | Sergio: «non c'è bisogno che sia in movimento» |
| Scritte, numeri, lucchetti, sentieri disegnati | li mette il gioco |
| Sfumature, bagliori, texture, 3D | non è lo stile della fetta |

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-101/riferimenti/R1_fetta_limbo.png` | la fetta del Limbo nel gioco: lo stile da copiare |
| R2 | `art/WB-101/riferimenti/R2_apprendista.png` | l'apprendista come è nel gioco |
| R3 | `art/WB-101/riferimenti/R3_fabbro.png` | il Fabbro come è nel gioco |
| R4 | `art/WB-101/riferimenti/R4_proposta_approvata.jpg` | la proposta approvata con i luoghi segnaposto: solo per capire cosa sono e dove stanno, **non** per lo stile |
| R5 | `art/WB-101/riferimenti/R5_leva_piastra.png` | la leva di WB-099, già fatta |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto: il primo è "image 1", il secondo
"image 2", il terzo "image 3". Sfondo verde pieno `#00FF00`. Tutti i luoghi nella stessa vista della fetta (davanti e un po'
dall'alto) e con lo stesso contorno nero spesso.

| Nome file | Riferimenti | Misura | Varianti | Cos'è |
|---|---|---|---|---|
| `pedina_apprendista` | R1, R2 | 1024×1024 | 2 | la pedina dell'apprendista, alta circa 60 px nel gioco |
| `pedina_fabbro` | R1, R3 | 1024×1024 | 2 | la pedina del Fabbro, un po' più grande |
| `limbo_porta` | R1 | 1024×1024 | 1 | livello 1 · La porta (circa 80 px) |
| `limbo_castello` | R1 | 1536×1024 | 1 | livello 3 · I sette muri (circa 200 px) |
| `limbo_castello_acceso` | R1 + l'immagine appena fatta di `limbo_castello` | 1536×1024 | 1 | lo stesso castello con le finestre accese, quando vinci il 3 |
| `limbo_bottega` | R1 | 1024×1024 | 1 | la bottega del Fabbro (circa 70 px) |
| `limbo_ponte` | R1 | 1024×1024 | 1 | livello 4 · Il ruscello (circa 80 px) |
| `limbo_prato` | R1 | 1536×1024 | 1 | livello 5 · Gli spiriti magni (circa 200 px) |
| `limbo_pontile` | R1 | 1536×1024 | 1 | Caronte, nella tacca a destra della fetta (circa 180 px) |
| `limbo_pietre` | R1 | 1536×1024 | 1 | le pietre del sentiero: normale, porta segreta, medaglia (circa 18 px) |
| `limbo_crepa` | R1 | 1024×1024 | 1 | la crepa per scendere, sul bordo davanti (circa 50 px) |

### `pedina_apprendista`

```
Image 1 shows the style and the point of view. Image 2 is the apprentice devil of the game. Draw him as a BOARD GAME PAWN: a small chunky painted figurine of this exact character, like a toy piece of a board game, simplified into round soft volumes: big head with the two small horns and the little flame on top, big yellow eyes, red skin, cream belly, red scarf, short legs, the tail curled close to the body. He stands still and straight, arms down along the body, calm smile, like a carved and painted piece, not alive: no action pose, no motion, no running. He stands on a round flat pawn base, a thick disc seen from a bit above, painted dark red #7E1F16 with a lighter red top #C0392B. Front three-quarter view, facing slightly to the right. Same thick black ink outline and flat cartoon colors as image 1 and image 2. Only this one pawn. 
```

### `pedina_fabbro`

```
Image 1 shows the style and the point of view. Image 3 is the Smith (il Fabbro) of the game, a devil with big horns, goggles on the forehead, leather apron, heavy gloves and boots. Draw him as a BOARD GAME PAWN: a small chunky painted figurine of this exact character, like a toy piece of a board game, simplified into round soft volumes: big head with the big curved horns, the goggles, the little flame on top, red skin, brown leather apron and gloves, sturdy boots. He stands still and straight, arms down along the body, calm confident face, like a carved and painted piece, not alive: no action pose, no motion, no tools in hand. He stands on a round flat pawn base, a thick disc seen from a bit above, painted brass #C8902E with a lighter top #FFE08A. Front three-quarter view, facing slightly to the right. He is a bit taller and wider than the apprentice pawn. Same thick black ink outline and flat cartoon colors as image 1 and image 3. Only this one pawn. 
```

### `limbo_porta`

```
Image 1 is the STYLE to copy: the Limbo slice of the game. Thick slightly irregular black ink outline, flat colors with one flat highlight and one flat shadow, soft crooked hand-drawn shapes, cartoon comic style. Same palette as image 1: pale stone #D9CFA8 with flat shadow #A99F7E, slate green #55665E, very dark green #1D2522. Same point of view as the slice: seen from the front and a bit above. Draw ONE small stone gate of the Limbo: a round arch of pale stone blocks, wider than tall, with a dark empty doorway, a plain stone plate on top of the arch (empty, no writing), and two short wooden torch poles, one on each side, each with a small flat orange flame. Keep it simple and almost abstract, with big clear shapes: in the game it is shown small, about 60 to 160 pixels wide, so no small details and no thin lines. Thick black ink outline. No texture, no soft gradients, no realistic lighting, no glow, no cast shadow on the ground. No text, letters, numbers or symbols. Flat pure green background (#00FF00), the object centered with a wide green margin all around, nothing cut by the border of the picture.
```

### `limbo_castello`

```
Image 1 is the STYLE to copy: the Limbo slice of the game. Thick slightly irregular black ink outline, flat colors with one flat highlight and one flat shadow, soft crooked hand-drawn shapes, cartoon comic style. Same palette as image 1: pale stone #D9CFA8 with flat shadow #A99F7E, slate green #55665E, very dark green #1D2522. Same point of view as the slice: seen from the front and a bit above. Draw ONE small noble castle of the Limbo seen from a bit above: seven low concentric oval rings of pale stone walls, one inside the other like a stepped cake, each ring with a few simple square battlements on its front, and in the middle a small keep with three simple towers with pointed slate-green roofs and one small dark window each. Low and wide, about twice as wide as tall. Keep it simple and almost abstract, with big clear shapes: in the game it is shown small, about 60 to 160 pixels wide, so no small details and no thin lines. Thick black ink outline. No texture, no soft gradients, no realistic lighting, no glow, no cast shadow on the ground. No text, letters, numbers or symbols. Flat pure green background (#00FF00), the object centered with a wide green margin all around, nothing cut by the border of the picture.
```

### `limbo_castello_acceso`

```
Image 1 is the STYLE to copy: the Limbo slice of the game. Thick slightly irregular black ink outline, flat colors with one flat highlight and one flat shadow, soft crooked hand-drawn shapes, cartoon comic style. Same palette as image 1: pale stone #D9CFA8 with flat shadow #A99F7E, slate green #55665E, very dark green #1D2522. Same point of view as the slice: seen from the front and a bit above. Draw exactly the same castle as the previous picture (seven low concentric oval rings of pale stone walls with battlements, a small keep with three towers with pointed slate-green roofs), but now the three small windows are lit warm yellow #FFD24A. Keep it simple and almost abstract, with big clear shapes: in the game it is shown small, about 60 to 160 pixels wide, so no small details and no thin lines. Thick black ink outline. No texture, no soft gradients, no realistic lighting, no glow, no cast shadow on the ground. No text, letters, numbers or symbols. Flat pure green background (#00FF00), the object centered with a wide green margin all around, nothing cut by the border of the picture.
```

### `limbo_bottega`

```
Image 1 is the STYLE to copy: the Limbo slice of the game. Thick slightly irregular black ink outline, flat colors with one flat highlight and one flat shadow, soft crooked hand-drawn shapes, cartoon comic style. Same palette as image 1: pale stone #D9CFA8 with flat shadow #A99F7E, slate green #55665E, very dark green #1D2522. Same point of view as the slice: seen from the front and a bit above. Draw ONE tiny workshop hut of a blacksmith: a small square house of brown-grey planks #7A6A52, a dark brown pointed roof #5A3A2A, a short stone chimney on the roof, a dark doorway, and a small iron anvil sign hanging beside the door. Cozy and crooked. Keep it simple and almost abstract, with big clear shapes: in the game it is shown small, about 60 to 160 pixels wide, so no small details and no thin lines. Thick black ink outline. No texture, no soft gradients, no realistic lighting, no glow, no cast shadow on the ground. No text, letters, numbers or symbols. Flat pure green background (#00FF00), the object centered with a wide green margin all around, nothing cut by the border of the picture.
```

### `limbo_ponte`

```
Image 1 is the STYLE to copy: the Limbo slice of the game. Thick slightly irregular black ink outline, flat colors with one flat highlight and one flat shadow, soft crooked hand-drawn shapes, cartoon comic style. Same palette as image 1: pale stone #D9CFA8 with flat shadow #A99F7E, slate green #55665E, very dark green #1D2522. Same point of view as the slice: seen from the front and a bit above. Draw ONE small arched wooden footbridge, seen from the front and a bit above, crossing from left to right: brown planks #8A5A32 with darker shadow #5C3A1E, a simple handrail on the back side, short posts. No water, no ground, only the bridge. Keep it simple and almost abstract, with big clear shapes: in the game it is shown small, about 60 to 160 pixels wide, so no small details and no thin lines. Thick black ink outline. No texture, no soft gradients, no realistic lighting, no glow, no cast shadow on the ground. No text, letters, numbers or symbols. Flat pure green background (#00FF00), the object centered with a wide green margin all around, nothing cut by the border of the picture.
```

### `limbo_prato`

```
Image 1 is the STYLE to copy: the Limbo slice of the game. Thick slightly irregular black ink outline, flat colors with one flat highlight and one flat shadow, soft crooked hand-drawn shapes, cartoon comic style. Same palette as image 1: pale stone #D9CFA8 with flat shadow #A99F7E, slate green #55665E, very dark green #1D2522. Same point of view as the slice: seen from the front and a bit above. Draw ONE flat oval patch of fresh green meadow lying on the ground, seen from a bit above, much wider than tall: flat green #6F8F5A with darker tufts of grass #4F6B3F drawn as small simple zigzags, and three small pale grey-blue round stones arranged in a half circle on it, like seats. Nothing standing up. Keep it simple and almost abstract, with big clear shapes: in the game it is shown small, about 60 to 160 pixels wide, so no small details and no thin lines. Thick black ink outline. No texture, no soft gradients, no realistic lighting, no glow, no cast shadow on the ground. No text, letters, numbers or symbols. Flat pure green background (#00FF00), the object centered with a wide green margin all around, nothing cut by the border of the picture.
```

### `limbo_pontile`

```
Image 1 is the STYLE to copy: the Limbo slice of the game. Thick slightly irregular black ink outline, flat colors with one flat highlight and one flat shadow, soft crooked hand-drawn shapes, cartoon comic style. Same palette as image 1: pale stone #D9CFA8 with flat shadow #A99F7E, slate green #55665E, very dark green #1D2522. Same point of view as the slice: seen from the front and a bit above. Draw ONE small piece of the dark river Acheron with its jetty: a flat irregular patch of dark teal water #2F7F9A with two or three simple light wave strokes #7CC4DC, a short wooden jetty of planks on posts coming in from the left, and a small dark wooden boat on the water with a tall thin hooded ferryman (Charon) standing in it, all in dark purple-grey #2A2430 with only two tiny yellow dots as eyes in the hood, holding a long oar. Simple silhouette, not scary. Keep it simple and almost abstract, with big clear shapes: in the game it is shown small, about 60 to 160 pixels wide, so no small details and no thin lines. Thick black ink outline. No texture, no soft gradients, no realistic lighting, no glow, no cast shadow on the ground. No text, letters, numbers or symbols. Flat pure green background (#00FF00), the object centered with a wide green margin all around, nothing cut by the border of the picture.
```

### `limbo_pietre`

```
Image 1 is the STYLE to copy: the Limbo slice of the game. Thick slightly irregular black ink outline, flat colors with one flat highlight and one flat shadow, soft crooked hand-drawn shapes, cartoon comic style. Same palette as image 1: pale stone #D9CFA8 with flat shadow #A99F7E, slate green #55665E, very dark green #1D2522. Same point of view as the slice: seen from the front and a bit above. Draw THREE flat oval stepping stones for a board game path, in a row with wide green space between them, each seen from a bit above, much wider than tall, with a thick black outline and a thin darker band on its front side to show thickness: the first pale stone #EFE3C4, the second ice blue #38B6FF, the third gold #FFB703. All three exactly the same size and shape. Keep it simple and almost abstract, with big clear shapes: in the game it is shown small, about 60 to 160 pixels wide, so no small details and no thin lines. Thick black ink outline. No texture, no soft gradients, no realistic lighting, no glow, no cast shadow on the ground. No text, letters, numbers or symbols. Flat pure green background (#00FF00), the object centered with a wide green margin all around, nothing cut by the border of the picture.
```

### `limbo_crepa`

```
Image 1 is the STYLE to copy: the Limbo slice of the game. Thick slightly irregular black ink outline, flat colors with one flat highlight and one flat shadow, soft crooked hand-drawn shapes, cartoon comic style. Same palette as image 1: pale stone #D9CFA8 with flat shadow #A99F7E, slate green #55665E, very dark green #1D2522. Same point of view as the slice: seen from the front and a bit above. Draw ONE crack opening in a dark stone wall, seen from the front: a jagged vertical crack, taller than wide, very dark #1A1F1D inside, with a thin warm orange glow line #FF9A2A deep inside it, as if fire is far below. Only the crack shape, no wall around it. Keep it simple and almost abstract, with big clear shapes: in the game it is shown small, about 60 to 160 pixels wide, so no small details and no thin lines. Thick black ink outline. No texture, no soft gradients, no realistic lighting, no glow, no cast shadow on the ground. No text, letters, numbers or symbols. Flat pure green background (#00FF00), the object centered with a wide green margin all around, nothing cut by the border of the picture.
```

## Criteri di accettazione

- [ ] stesso stile della fetta (R1): contorno nero spesso e storto, colori pieni, una luce e un'ombra piatte
- [ ] le pedine sono figurine ferme su una base tonda, riconoscibili come l'apprendista e il Fabbro anche alte 60 px
- [ ] i luoghi si leggono da piccoli: forme grandi, niente linee sottili
- [ ] nessuna scritta, numero o simbolo; nessun bagliore o sfumatura
- [ ] sfondo verde pieno, niente tagliato dal bordo

---

## Decisione

Approvata da Sergio il 28 nov 2026 (proposta A, pedine al posto dei personaggi animati, disegni semplici nello stile della fetta).

## Consegna di Codex

In `art/WB-101/` sono stati pubblicati 13 PNG con i rispettivi `.txt` (prompt originali, riferimenti e note):

- `pedina_apprendista_1.png`, `pedina_apprendista_2.png`, `pedina_fabbro_1.png`, `pedina_fabbro_2.png`.
- `limbo_porta.png`, `limbo_castello.png`, `limbo_castello_acceso.png`, `limbo_bottega.png`, `limbo_ponte.png`, `limbo_prato.png`, `limbo_pontile.png`, `limbo_pietre.png`, `limbo_crepa.png`.

Un tentativo per immagine, salvo l'apprendista 2 (tre tentativi, selezionato il terzo per le corna visibili). I PNG rispettano le dimensioni della tabella. Le pedine sono state generate su trasparente, ridimensionate in proporzione e composte su verde #00FF00. Gli altri PNG sono stati adattati in proporzione dove necessario. Il loro verde generato differisce leggermente da #00FF00. Nel prompt del Fabbro «Image 3» indica R3, allegato come seconda immagine secondo la tabella.

Controllati margini e leggibilità nelle anteprime ridotte. Le quattro pedine sono ferme su basi tonde, i luoghi sono interi e privi di scritte. Per il castello acceso ho allegato R1 e l'uscita originale del castello spento. Le tre finestre passano da scuro a giallo, con lievi differenze di sagoma e campiture tra i due PNG. Lo scontorno, l'allineamento dei due castelli e la resa sulla fetta in gioco restano da verificare.

## Resoconto di Claude

Tutte le immagini sono buone e sono nel gioco (28 nov): scontorno pulito, nessun bordo verde, i due
castelli combaciano. Delle pedine ho preso la variante 1 di tutte e due (nella 1 corna e occhialoni
sono più netti). `tools/grafica/tabellone.py` le taglia al doppio della misura sullo schermo (mai
ingrandite) nell'atlante `client/menu/tabellone.atlas` (con le mipmap) e scrive le misure in
`client/menu/board_pieces.lua`. Il tabellone è `client/menu/limbo_board.lua`: la fetta di WB-085,
i luoghi al loro posto, il sentiero di pietre fra un luogo e l'altro (velate fin dove è chiuso), il castello si accende quando vinci i Sette muri; le pedine saltellano da un luogo
all'altro, il Fabbro un passo dietro. Non usate: le varianti 2 delle pedine; la pietra azzurra e quella d'oro restano in `art/` per le scorciatoie e le medaglie. Manca il ruscello sotto
il ponte (il ponte sta sul terreno): se serve, una scheda piccola dopo.
