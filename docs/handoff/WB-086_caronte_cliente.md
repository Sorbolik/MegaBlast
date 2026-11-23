# WB-086 · Caronte, il primo cliente (prova di stile dei custodi)

- **Stato:** APPROVATA (Claude, 23 nov: è una prova di stile, non sostituisce niente; Sergio sceglie sulle immagini)
- **Data:** 2026-11-23
- **Ramo della scheda:** `claude/project-thread-ft5von` (Codex la esegue da qui: `git fetch origin claude/project-thread-ft5von`, non serve che sia su `main`) · **Ramo delle immagini:** `design/WB-086`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-086` senza chiedere conferma (il repository è privato).

## Obiettivo

Nelle Commesse del Fabbro ([docs/commesse.md](../commesse.md)) i custodi dei gironi diventano clienti: ognuno ha un cartellino in bacheca col suo ritratto e tre espressioni (chiede, contento, fiero). Caronte è il primo e fa da prova di stile: se piace, gli altri sette (WB-087) si disegnano uguale.

Caronte è il traghettatore dell'Acheronte, custode del Limbo: sta sulla barca in mezzo al fiume e colpisce col remo. La sua famiglia è il LEVIATANO (verde mare). Deve stare nello stesso mondo del Fabbro (R1): buffo e burbero, non pauroso.

Il gioco usa il busto a circa 120×90 px sul cartellino e più grande quando il cartellino si apre.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-012/3_foglio_fabbro_2.png` | il foglio del Fabbro: lo STILE da copiare (china, tratteggio, colori) e come è fatto un foglio: figura intera più busti con le espressioni |
| R2 | `client/assets/portraits/fabbro_calma.png` | un ritratto com'è nel gioco: inquadratura del busto |

## Immagini da generare

Il prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine: il primo è "image 1", il secondo "image 2".

| Nome file | Cosa c'è | Riferimenti | Misura | Varianti |
|---|---|---|---|---|
| `caronte` | figura intera più tre busti con le espressioni | R1, R2 | 1536×1024 | 3 |

Le varianti si chiamano `caronte_1.png`, `caronte_2.png` e `caronte_3.png`, in `art/WB-086/`. Per ogni foglio Codex scrive un `.txt` con lo stesso nome: cosa ha fatto e cosa non è riuscito a rispettare.

### `caronte`

```
Image 1 is a character sheet of the Blacksmith of our game, a cartoon devil: one full figure and several busts with different expressions. It is the STYLE to copy exactly: thick slightly irregular black ink outline, short ink hatching for the shadows, flat warm colors, a pale parchment background in each panel, hand-drawn like a European comic. Image 2 is one bust as it is framed in the game: head and shoulders, turned three quarters, filling the panel.

Draw a character sheet of a NEW character of the same world, in the same style and with the same kind of panels: CHARON, the ferryman of the river Acheron, guardian of Limbo. He is a customer of the Blacksmith: grumpy, stingy and proud, funny rather than scary, the same cartoon devil kind as the Blacksmith but OLD and LEAN where the Blacksmith is broad: a tall thin devil with a long hooked nose, sunken cheeks, small glowing yellow eyes under heavy brows, a long thin grey beard that ends in a wet point, two long horns that curve BACKWARD like the prow of a boat. Skin grey-green (#7FA39A, shadow #4F6F68). He wears a patched hooded ferryman cloak, dark sea green (#2F8F78, highlight #5CDBB8, shadow #1E5A4C), the hood down on his shoulders, tied with a wet rope, with one single big old bronze coin (#C9822A) hanging on his chest as a pendant. Over his shoulder he carries a long worn wooden OAR, its blade chipped.

Four panels on one sheet, same size, in one row:
1. FULL FIGURE: Charon standing in his small black boat, leaning on the oar, seen from three quarters.
2. BUST, ASKING: he stretches one bony open hand toward the viewer, palm up, one eyebrow raised, mouth closed and crooked: "I need something from you".
3. BUST, PLEASED: a small satisfied closed-mouth grin, eyes half closed, he holds the bronze coin of his pendant between two fingers and looks at it.
4. BUST, PROUD: chin up, eyes closed, a wide toothy smile, the oar planted next to him like a flag.
In the three busts the head, the horns, the beard, the cloak and the pendant are IDENTICAL: only the expression and the hands change. Keep the whole silhouette (horns and oar included) inside each panel, with some margin. No letters, no numbers, no speech balloons.
```

## Criteri di accettazione

- [ ] stessa mano del foglio del Fabbro (china spessa, tratteggio, colori piatti e caldi)
- [ ] si riconosce in piccolo: corna all'indietro, barba a punta, cappuccio verde mare, moneta al collo, remo
- [ ] nei tre busti il personaggio è lo stesso, cambia solo l'espressione
- [ ] buffo e burbero, non pauroso; nessuna scritta
- [ ] tutta la sagoma dentro il riquadro, con margine per il ritaglio

---

## Decisione

Approvata da Claude il 23 nov (prova di stile). Sergio sceglie la variante; da lì nasce WB-087 con gli altri sette custodi.

## Consegna di Codex

- `art/WB-086/caronte_1.png` e `caronte_1.txt` — tre tentativi, selezionato il secondo.
- `art/WB-086/caronte_2.png` e `caronte_2.txt` — tre tentativi, selezionato il terzo.
- `art/WB-086/caronte_3.png` e `caronte_3.txt` — tre tentativi, selezionato il secondo.

Prompt della scheda eseguito con ImageGen e i due riferimenti nell'ordine indicato. I tre fogli sono stati ridimensionati in proporzione e centrati su tela pergamena da 1536×1024, mantenendo i quattro riquadri in fila.

Verificati ordine dei riquadri, espressioni, presenza di corna, barba, mantello, moneta e remo, stile a china e tratteggio, assenza di testo. Le espressioni e gli accessori principali si distinguono anche nelle anteprime dei busti in riquadri da 120×90 px. Il disegno resta riconoscibile tra i busti, con leggere differenze nella sagoma di barba, cappuccio e toppe. Il bordo inferiore dei busti tronca il mantello e in alcuni riquadri il manico del remo. Nella variante 1 il manico della figura intera può sembrare un secondo attrezzo. Le note per ciascuna variante sono nei rispettivi `.txt`. La resa sul cartellino in gioco resta da verificare.

## Resoconto di Claude
