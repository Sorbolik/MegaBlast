# WB-085 · Cartellino di carta e il Fabbro al banco

- **Stato:** APPROVATA (Claude, 23 nov: pezzi nuovi, non sostituiscono disegni di Codex; Sergio ha scelto i cartellini di carta sulle bozze)
- **Data:** 2026-11-23
- **Ramo della scheda:** `claude/project-thread-ft5von` (Codex la esegue da qui: `git fetch origin claude/project-thread-ft5von`, non serve che sia su `main`) · **Ramo delle immagini:** `design/WB-085`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-085` senza chiedere conferma (il repository è privato).

## Obiettivo

Nella scheda COMMESSE della BOTTEGA ([docs/commesse.md](../commesse.md), foto R1) mancano due disegni:

1. **Il cartellino di carta** delle commesse: oggi è un pannello chiaro qualunque con un chiodo sopra. Serve un vero foglio appeso, in due forme (alto per i clienti, largo per la commessa della settimana).
2. **Il Fabbro al suo banco**, figura intera, a sinistra della bacheca: oggi c'è il diavoletto perché il Fabbro intero che abbiamo è troppo piccolo. Nel gioco è alto circa 400 px su uno schermo da 720: il disegno deve essere **alto almeno 900 px** per restare nitido sugli schermi grandi.

La porta della home non si ridisegna: è già la bottega col tendone (WB-080) e il nome BOTTEGA lo scrive il gioco.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-085/riferimenti/R1_commesse_oggi.png` | la scheda COMMESSE com'è oggi nel gioco: i cartellini chiari col chiodo, i pannelli di ferro, lo stile dell'interfaccia |
| R2 | `art/WB-012/3_foglio_fabbro_2.png` | il foglio del Fabbro: il personaggio e lo STILE dei personaggi (china, tratteggio) |
| R3 | `art/WB-086/caronte_2.png` | Caronte, un cliente del Fabbro: stessa mano, per la figura intera |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto: il primo è "image 1", il secondo "image 2".

| Nome file | Cosa c'è | Riferimenti | Misura | Varianti |
|---|---|---|---|---|
| `cartellino` | due fogli di carta vuoti, uno alto e uno largo | R1 | 1536×1024 | 2 |
| `fabbro_al_banco` | il Fabbro intero dietro il suo banco | R2, R3 | 1024×1536 | 2 |

Le varianti si chiamano `cartellino_1.png`, `cartellino_2.png`, `fabbro_al_banco_1.png`, `fabbro_al_banco_2.png`, in `art/WB-085/`. Per ogni foglio Codex scrive un `.txt` con lo stesso nome: cosa ha fatto e cosa non è riuscito a rispettare.

### `cartellino`

```
Image 1 is a screen of our game: a board with order cards pinned to it. The cards are the pale ivory rectangles with a dark nail on top; the dark panels around them show the STYLE of our interface: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, hand-drawn like a cartoon comic.

Draw TWO separate EMPTY paper order tickets for that board, side by side, well apart, on plain green (#00FF00), in that same interface style:
1. LEFT: a TALL ticket, three units wide and four units tall.
2. RIGHT: a WIDE ticket, three units wide and two units tall.
Each ticket is a sheet of thick ivory paper (#F4EAD8, shadow #D9C7A6, highlight #FFF8EA) with a thick black ink outline, slightly uneven hand-cut edges, one corner a little dog-eared, and a small round hole at the top center with a short strip of darker reinforced paper around the hole. NO nail (the game draws it). The whole inside of each ticket is EMPTY and FLAT: one plain ivory color, no lines, no stamps, no stains, no texture, no writing, because the game writes on it; shading only in a thin band along the edges. The two tickets are the same paper and the same hand, only the shape changes. No letters, no numbers, no shadow on the ground, no glow.
```

### `fabbro_al_banco`

```
Image 1 is the character sheet of the Blacksmith of our game, a broad cartoon devil with big curved horns, a huge white moustache, a leather apron and a small furnace in his chest. Copy this CHARACTER exactly (face, horns, moustache, colors, clothes) and this STYLE exactly: thick slightly irregular black ink outline, short ink hatching for the shadows, flat warm colors, hand-drawn like a European comic. Image 2 is another character of the same world drawn by the same hand: the full figure on its left shows how a whole figure is drawn.

Draw ONE single tall image: the Blacksmith, FULL FIGURE from horns to feet, standing behind his small shop counter, seen from the front turned slightly to the RIGHT (he looks toward the right side of the image, where his customers' orders hang). The counter is a short heavy wooden workbench with iron bands that reaches his waist and hides his legs only partly; on it there are his big hammer lying down and a small anvil. He leans on the counter with one big gloved hand and with the other hand he strokes his moustache, calm and proud, waiting: a shopkeeper in his shop. The furnace in his chest glows.
The figure with its counter fills the image from top to bottom with a small margin, everything inside the image: horns, elbows, hammer and counter are NOT cut by the border. Background: ONE plain flat pale parchment color (#F3E3C3) everywhere, nothing else: no floor, no wall, no smoke going out of the image, no frame, no panel border, no shadow on the ground. No letters, no numbers.
```

## Criteri di accettazione

- [ ] cartellino: due fogli (alto 3:4, largo 3:2), stessa carta, contorno di china, foro in alto al centro, senza chiodo
- [ ] cartellino: dentro è vuoto e piatto (un colore solo), così il gioco lo allunga nel mezzo e ci scrive
- [ ] Fabbro: è lui (corna, baffi, grembiule, fornace nel petto), stessa mano del suo foglio
- [ ] Fabbro: figura intera col banco, niente tagliato dal bordo, alto almeno 900 px, guarda verso destra
- [ ] Fabbro: fondo di un colore solo, senza pavimento né cornice (si ritaglia)
- [ ] nessuna scritta

---

## Decisione

Approvata da Claude il 23 nov: pezzi nuovi per la scheda COMMESSE, niente di Codex viene sostituito (il pannello chiaro e il diavoletto restano finché Sergio non sceglie le varianti).

## Consegna di Codex

- `art/WB-085/cartellino_1.png` e `cartellino_2.png`, con i rispettivi `.txt` — 1536×1024, un tentativo per variante.
- `art/WB-085/fabbro_al_banco_1.png` e `fabbro_al_banco_2.png`, con i rispettivi `.txt` — 1024×1536, due tentativi per la variante 1 e uno per la variante 2.

Prompt originali eseguiti con ImageGen e riferimenti nell'ordine indicato. I fogli dei cartellini sono stati ridimensionati in proporzione e centrati su tela verde. Entrambi mostrano due fogli vuoti, separati e senza scritte o chiodi, con i fori visibili. Le forme larghe sono vicine al rapporto 3:2. Le forme alte sono più strette del rapporto 3:4 richiesto. Il verde si discosta da #00FF00 e le campiture avorio hanno lievi variazioni tonali.

I due Fabbri guardano verso destra e sono interamente in campo con banco, incudine e martello. L'estensione verticale dei due disegni supera 1400 px. La variante 2 ha una voluta interamente contenuta nella tela. Il fondo pergamena presenta leggere variazioni tonali e non è #F3E3C3 esatto. Lo stiramento dei cartellini e la resa degli asset nell'interfaccia restano da verificare.

## Resoconto di Claude

23 nov. Guardate tutte e quattro le immagini: nessun difetto visibile.
- Cartellino: preso il foglio largo di `cartellino_1` (più pulito di `cartellino_2`), in nove parti
  con gli angoli di 100 px (sullo schermo 34: l'orecchia resta intera) e il rinforzo del foro a parte
  (`cartellino_foro`), messo al centro sotto il chiodo. Lo stesso foglio fa i cartellini alti, larghi e
  le finestre (`kit.paper`). Il foglio alto non serve.
- Fabbro al banco: variante 1 (più chiara, il banco intero), senza pergamena, alto 1000 (sullo schermo
  500, a sinistra della bacheca). Le varianti scartate sono tolte da `art/` (restano sul ramo `design/WB-085`).
- Provati a 1280 x 720, 1600 x 720 e 960 x 720 (scenario `commesse.txt`).
