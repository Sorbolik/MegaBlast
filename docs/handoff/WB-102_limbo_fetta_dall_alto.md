# WB-102 · Il Limbo rifatto a tema, visto quasi dall'alto

- **Stato:** APPROVATA (Claude, 28 nov 2026: Sergio «Ok, ora ci siamo … vorrei predisporre il disegno con codex, oltre che con i riferimenti delle posizioni delle cose interattive da mettere sopra, anche in maniera che ci venga semplice fare un bell'highlight pulito dei bordi … procedi». Sono solo immagini nuove: si possono rifare)
- **Data:** 2026-11-28
- **Ramo della scheda:** `claude/project-thread-t9n34l` (Codex la esegue da qui: `git fetch origin claude/project-thread-t9n34l`, non serve che sia su `main`) · **Ramo delle immagini:** `design/WB-102`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-102` senza chiedere conferma (il repository è privato).

## Obiettivo

Nella mappa dei gironi, il girone che scorre in primo piano si inclina e si vede **quasi dall'alto**; scorrendo oltre torna
schiacciato, visto di lato (prova: https://claude.ai/artifact/MkpvzhZH9VgeFx8G3S22us). Per farlo il gioco ha bisogno del
Limbo in **due pezzi separati**:

1. la **faccia di sopra**, disegnata vista dall'alto: il gioco la schiaccia in verticale quando il girone si allontana;
2. la **parete davanti**, una striscia di roccia che il gioco piega sotto il bordo e di cui mostra più o meno altezza
   (la taglia, non la stira).

Sulla faccia c'è la **strada disegnata** del percorso (R2): sopra il gioco mette il tratteggio, i pallini dei livelli, i
nomi, le bandierine e le pedine. Il bordo della faccia è un'ellisse pulita con un contorno nero uniforme: così il gioco
accende il bordo (luce del colore del girone) quando il girone è in primo piano, senza scontornare niente a mano.

Serve anche la pedina del **Fabbro vero della storia** (R4: corna, baffi, petto a fornace col camino, martello): quella di
WB-101 era l'apprendista vestito da Fabbro.

## Cosa teniamo e cosa scartiamo

| Teniamo | Perché |
|---|---|
| Lo stile della fetta del Limbo (R1): china spessa, colori pieni, una luce e un'ombra piatte | è lo stile dei gironi |
| L'ellisse e le strade esattamente come R2 | ci vanno sopra pallini e tratteggio del gioco |
| La pedina dell'apprendista di WB-101 (R5) | è buona; serve solo come modello di pedina |

| Scartiamo | Perché |
|---|---|
| Cose alte in piedi sulla faccia (torri, alberi alti, castelli, personaggi) | quando il girone si allontana la faccia viene schiacciata e le cose alte si deformerebbero; i luoghi alti (porta, castello, ponte, Caronte) restano ritagli a parte di WB-101 |
| Qualsiasi cosa che esce dall'ellisse o la copre | il bordo deve restare una sagoma chiusa e pulita |
| Ombre, bagliori, nebbia fuori dalla fetta | rovinerebbero lo scontorno e la luce del bordo |
| Scritte, numeri, pallini, tratteggi, segni dei livelli | li mette il gioco |

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-102/riferimenti/R1_fetta_limbo.png` | la fetta del Limbo di oggi, vista di lato: lo **stile** e i colori da copiare |
| R2 | `art/WB-102/riferimenti/R2_strade_dall_alto.png` | la faccia vista dall'alto con le strade: **forma, misura e posizione esatte** dell'ellisse e delle strade |
| R3 | `art/WB-102/riferimenti/R3_posizioni.png` | lo stesso con i punti fucsia dove il gioco mette i livelli (1-5, B = bottega, C = Caronte): **solo per capire**, i punti non si disegnano |
| R4 | `art/WB-102/riferimenti/R4_fabbro_della_storia.png` | il Fabbro della storia (riquadro in alto a sinistra, a figura intera) |
| R5 | `art/WB-102/riferimenti/R5_pedina_apprendista.png` | la pedina dell'apprendista già nel gioco: il modello di pedina |

Nel gioco: i punti 1-5 sono La porta, La leva, Sette muri, Ruscello, Spiriti magni; B è la Bottega (bonus); C è Caronte.
La strada larga marrone è il percorso principale; le due strade strette blu sono scorciatoie (la porta segreta da 2 a 4,
il guado da 4 a C); il ramo corto da 3 a B porta alla bottega.

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto: il primo è "image 1", il secondo
"image 2", e così via. Sfondo verde pieno `#00FF00`.

| Nome file | Riferimenti | Misura | Varianti | Cos'è |
|---|---|---|---|---|
| `limbo_faccia` | R1, R2, R3 | 1536×1024 | 2 | la faccia di sopra del Limbo vista dall'alto, con le strade |
| `limbo_parete` | R1 | 1536×1024 | 1 | la striscia di roccia della parete, ripetibile a destra e sinistra |
| `pedina_fabbro` | R5, R4 | 1024×1024 | 2 | la pedina del Fabbro della storia |

### `limbo_faccia`

```
Image 1 is the STYLE to copy: the Limbo circle of the game, a slice of rock seen from the side. Copy its thick slightly irregular black ink outline, flat colors with one flat highlight and one flat shadow, soft crooked hand-drawn shapes, cartoon comic style, and its palette: slate green ground #55665E, darker green #3E4C46, very dark green #1D2522, pale stone #D9CFA8 with flat shadow #A99F7E.
Image 2 gives the EXACT SHAPE, SIZE AND POSITION to keep: a flat oval seen almost from straight above, and the roads on it. Draw the oval exactly where it is in image 2, same width, same height, same center, on a flat pure green background (#00FF00).
Draw the TOP FACE of the Limbo circle seen almost from straight above, as a themed board game map: ground of grey-green grass and pale dusty earth, a few flat patches of stone pavement, small flat tufts of grass, a few flat round stones lying on the ground, all FLAT on the ground.
The ROADS of image 2 must be there, in exactly the same place and with the same curves: the wide main road as a path of packed pale-brown earth #8A7656 with a darker edge #5E5038 and a thick black outline, the two narrow roads as narrow trails of grey-blue flat stones #5E6E78, the short branch near the top-left as a narrow earth trail. Keep the middle of every road plain and clear, with no stones, cracks or marks on it, because the game draws a dotted line along the middle of each road.
Image 3 is the same map with pink dots where the game places the levels, ONLY to understand the places: do NOT draw the pink dots, numbers or letters. Around those places draw only flat ground marks: at 1 a small flat square of paving stones; at 2 a flat round stone plate; at 3 a flat oval ring of a dry moat; at 4 a small blue stream #2F7F9A with light wave strokes #7CC4DC that starts from a small spring and ends in a small pond, both well inside the oval, passing under the main road; at 5 a flat oval patch of brighter green meadow #6F8F5A; at C, near the right end, a flat patch of dark teal water #2F7F9A (the shore of the river Acheron) well inside the oval; at B a small flat clearing of earth.
NOTHING STANDS UP on the face: no towers, no walls, no trees, no buildings, no people, no bridges, no boats; everything is drawn flat on the ground as seen from above.
The EDGE: the oval is closed by a band of pale stone #D9CFA8 all around, like the rim of image 1, and outside of it one single thick UNIFORM black ink outline, the same thickness all around, smooth and clean. Nothing crosses, overlaps or sticks out of the oval: no grass, stones, water or roads on or over the edge. No shadow, glow, mist or dust outside the oval: outside is only flat pure green #00FF00.
No text, letters, numbers, dots, arrows or symbols. No texture, no soft gradients, no realistic lighting, no glow.
```

### `limbo_parete`

```
Image 1 is the STYLE to copy: the Limbo circle of the game, a slice of rock seen from the side. Copy its thick slightly irregular black ink outline, flat colors with one flat highlight and one flat shadow, cartoon comic style, and the colors of its rock wall: very dark green-grey #1D2522, #2A3430 and #3E4C46.
Draw ONLY a long horizontal band of that rock wall, seen straight from the front, filling the whole width of the picture from the left border to the right border, about 340 pixels tall, centered vertically. It is made of big simple rock blocks and vertical cracks, darker at the bottom and a bit lighter at the top. The top edge of the band is one straight horizontal thick black line. The bottom edge is a thick black line with a few big round irregular lumps of rock hanging a little.
The band must REPEAT SEAMLESSLY: the left border and the right border must match exactly, so that the band can be placed many times side by side without any visible joint. Nothing else: no grass, no roads, no light on top.
Above and below the band only flat pure green (#00FF00). No text, letters, numbers or symbols. No texture, no soft gradients, no realistic lighting, no glow, no cast shadow.
```

### `pedina_fabbro`

```
Image 1 is a BOARD GAME PAWN of the game: a small chunky painted figurine of the apprentice devil standing still on a round flat pawn base. Copy exactly its style, its size on the picture, its pose (standing still and straight, front three-quarter view facing slightly to the right), its round base seen from a bit above, its thick black ink outline and its flat cartoon colors.
Image 2 is the Smith (il Fabbro) of the story: use ONLY the full-body figure in the top-left panel. Draw HIM as a board game pawn like image 1: a chunky painted figurine of this exact character, simplified into round soft volumes, recognizable even very small: big curved ringed brown horns, red skin, white bushy eyebrows and a huge curled white moustache, small yellow eyes, the iron chest shaped like a furnace with a barred window showing orange flames, the short black chimney on his shoulder (no smoke), brown leather apron, thick brown gloves, short sturdy legs with dark boots. He holds his big square hammer upright beside him, its head resting on the base. Calm proud face. Standing still, like a carved and painted piece, not alive: no action pose, no motion.
He stands on the same kind of round flat pawn base as image 1, painted brass #C8902E with a lighter top #FFE08A. He is about one and a half times as tall and wider than the apprentice pawn of image 1.
Only this one pawn. Flat pure green background (#00FF00), the pawn centered with a wide green margin all around, nothing cut by the border. No text, letters, numbers or symbols. No texture, no soft gradients, no realistic lighting, no glow, no cast shadow.
```

## Criteri di accettazione

- [ ] `limbo_faccia`: ellisse con forma, misura e centro di R2; strade al loro posto con le stesse curve, il centro libero
- [ ] `limbo_faccia`: tutto piatto sul terreno, niente di alto in piedi; i punti di R3 non disegnati
- [ ] `limbo_faccia`: bordo chiuso, contorno nero uniforme e liscio, niente che lo attraversa o ne esce, niente ombre o bagliori fuori; fuori solo verde
- [ ] `limbo_parete`: la striscia si ripete a destra e sinistra senza giunta visibile; bordo di sopra dritto
- [ ] `pedina_fabbro`: riconoscibile come il Fabbro di R4 (corna, baffi, petto a fornace, camino, martello) anche alta 70 px; stessa pedina di R5 per stile e base
- [ ] stile di R1: china spessa, colori pieni, nessuna scritta, nessuna sfumatura

---

## Decisione

Approvata da Claude il 28 nov 2026 su indicazione di Sergio (vedi Stato): immagini nuove, reversibili.

## Consegna di Codex

_(la scrive Codex)_

## Resoconto di Claude

_(lo scrive Claude dopo aver guardato le immagini)_
