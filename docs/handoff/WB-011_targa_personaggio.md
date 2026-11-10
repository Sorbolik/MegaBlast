# WB-011 · Targa del personaggio: vita, nome e Corona

- **Stato:** APPROVATA
- **Data:** 2026-11-03
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-011`

## Obiettivo

Sergio (3 nov) vuole rifare gli elementi sopra i personaggi (barra della vita, nome, Corona, freccia
di chi è di turno): minimali, in linea con la storia del gioco (l'inferno di Dante visto come una
forgia), messi nei punti giusti e mai più grandi del personaggio. Tre stili da confrontare. Per ogni
stile ci sono due immagini:
- una scena con l'apprendista e la sua targa sopra la testa;
- un foglio con i pezzi su magenta, pronto da tagliare.

La freccia di ferro (WB-010) resta com'è e fa da riferimento. Il nome lo scrive il gioco col suo
font, quindi nelle immagini non c'è nessuna scritta. Le proposte con gli schemi sono nella pagina
della designer.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-009/riferimenti/R1b_apprendista_senza_fiammella.png` | l'apprendista senza fiammella, il personaggio di tutti |
| R2 | `art/WB-010/p2_freccia_scena.png` | la freccia di ferro di chi è di turno, già scelta |

## Immagini da generare

Ogni prompt è completo e va usato così com'è, allegando R1 come immagine 1 e, nelle scene, R2 come
immagine 2. Le scene hanno lo sfondo dipinto. I fogli hanno lo sfondo magenta pieno #FF00FF
(un'eccezione alla regola di `AGENTS.md`), perché lo usa lo strumento di taglio.

| Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|
| `a_ferro_scena` | R1, R2 | 1536×1024 | 1 |
| `a_ferro_foglio` | R1 | 1536×1024 | 1 |
| `b_catena_scena` | R1, R2 | 1536×1024 | 1 |
| `b_catena_foglio` | R1 | 1536×1024 | 1 |
| `c_lama_scena` | R1, R2 | 1536×1024 | 1 |
| `c_lama_foglio` | R1 | 1536×1024 | 1 |

## Stile A · Ferro e brace

### `a_ferro_scena`

```
Image 1 is the main character of our game, a little blacksmith-apprentice imp. Copy him exactly (shapes, proportions, colours, horns, neckerchief, tail); do not reinterpret him. He has NO flame on his head: do not add one. His neckerchief is BLUE #3d7bff. Image 2 is the small wrought-iron arrow that already marks the active player in our game: copy it exactly, only smaller.

Life bar: a thin straight wrought-iron rail with one rivet at each end, about eight times longer than tall. Inside the rail a glowing ember strip in the team colour fills 70% of it from the left; the empty 30% on the right is cooled dark iron with a faint red glow. Crown (only the first in the ranking has it): a tiny iron crown with three old-gold tips, placed on the LEFT of the name slot, on the same line, not above it.

Scene: the imp of image 1 small in the picture (about one quarter of the image height), three-quarter view facing right, standing in the middle of a flat painted brick platform of the Forge in muted slate-blue bricks; behind, a dark muted slate-blue background with engraving hatching, darker and duller than the imp. Above his head, close to his horns, his minimal game HUD, stacked from top to bottom: the arrow of image 2, then the name line, then the life bar. The whole HUD is narrower than the imp's body and its total height is less than half of the imp's height: the imp must stay by far the most visible thing. Where the name goes, draw only a short empty slot (the game writes the name with its own font). The team colour of this scene is BLUE #3d7bff. Landscape 3:2.

Style: same as the MegaBlast apprentice imp reference (attached image 1): cartoon, thick black outline, flat cel colours with light Doré-style engraving hatching in the shadows. Campaign palette: brick red, parchment, ember orange, old gold, wrought iron grey. Hell of Dante seen as a forge. Clean shapes that read at 20 px tall on a phone. No text, no letters, no numbers anywhere.
```

### `a_ferro_foglio`

```
Image 1 is the main character of our game, a little blacksmith-apprentice imp: use it ONLY for the style. Do not draw the imp.

The objects: the parts of a minimal life bar for a mobile game HUD. Life bar: a thin straight wrought-iron rail with one rivet at each end, about eight times longer than tall. Inside the rail a glowing ember strip in the team colour fills 70% of it from the left; the empty 30% on the right is cooled dark iron with a faint red glow.

Pieces, top to bottom: 1) the empty life bar rail, long and straight, with the rivets, its middle part perfectly uniform so it can be stretched; 2) the ember strip alone, glowing WHITE-HOT and neutral (white and pale cream only, no team colour, the game tints it); 3) the same strip cooled down (dark iron with a faint red glow); 4) the tiny iron crown with old-gold tips, big on the sheet.

Sheet layout: solid flat magenta #FF00FF background, nothing else on it (no shadows on the magenta, no ground). Every piece alone, well separated from the others, drawn straight and flat, seen exactly from the front. Do not use magenta or pink anywhere on the pieces. Landscape 3:2.

Style: same as the MegaBlast apprentice imp reference (attached image 1): cartoon, thick black outline, flat cel colours with light Doré-style engraving hatching in the shadows. Campaign palette: brick red, parchment, ember orange, old gold, wrought iron grey. Hell of Dante seen as a forge. Clean shapes that read at 20 px tall on a phone. No text, no letters, no numbers anywhere.
```

## Stile B · Catena di vita

### `b_catena_scena`

```
Image 1 is the main character of our game, a little blacksmith-apprentice imp. Copy him exactly (shapes, proportions, colours, horns, neckerchief, tail); do not reinterpret him. He has NO flame on his head: do not add one. His neckerchief is BLUE #3d7bff. Image 2 is the small wrought-iron arrow that already marks the active player in our game: copy it exactly, only smaller.

Life bar: a short horizontal chain of five small hammered iron links touching each other, about eight times longer than tall. The links are lit from inside by a glowing ember in the team colour: the first three and a half links glow, the last one and a half are cold, dark and slightly cracked. Crown (only the first in the ranking has it): a tiny ring of chain with three old-gold spikes, placed on the LEFT of the name slot, on the same line, not above it.

Scene: the imp of image 1 small in the picture (about one quarter of the image height), three-quarter view facing right, standing in the middle of a flat painted brick platform of the Forge in muted slate-blue bricks; behind, a dark muted slate-blue background with engraving hatching, darker and duller than the imp. Above his head, close to his horns, his minimal game HUD, stacked from top to bottom: the arrow of image 2, then the name line, then the life bar. The whole HUD is narrower than the imp's body and its total height is less than half of the imp's height: the imp must stay by far the most visible thing. Where the name goes, draw only a short empty slot (the game writes the name with its own font). The team colour of this scene is BLUE #3d7bff. Landscape 3:2.

Style: same as the MegaBlast apprentice imp reference (attached image 1): cartoon, thick black outline, flat cel colours with light Doré-style engraving hatching in the shadows. Campaign palette: brick red, parchment, ember orange, old gold, wrought iron grey. Hell of Dante seen as a forge. Clean shapes that read at 20 px tall on a phone. No text, no letters, no numbers anywhere.
```

### `b_catena_foglio`

```
Image 1 is the main character of our game, a little blacksmith-apprentice imp: use it ONLY for the style. Do not draw the imp.

The objects: the parts of a minimal life bar for a mobile game HUD. Life bar: a short horizontal chain of five small hammered iron links touching each other, about eight times longer than tall. The links are lit from inside by a glowing ember in the team colour: the first three and a half links glow, the last one and a half are cold, dark and slightly cracked.

Pieces, top to bottom: 1) one chain link, lit, with the ember inside glowing WHITE-HOT and neutral (white and pale cream only, no team colour, the game tints it); 2) the same link cold, dark and slightly cracked; 3) the same link half lit (left half glowing, right half cold); 4) the tiny chain-ring crown with old-gold spikes, big on the sheet.

Sheet layout: solid flat magenta #FF00FF background, nothing else on it (no shadows on the magenta, no ground). Every piece alone, well separated from the others, drawn straight and flat, seen exactly from the front. Do not use magenta or pink anywhere on the pieces. Landscape 3:2.

Style: same as the MegaBlast apprentice imp reference (attached image 1): cartoon, thick black outline, flat cel colours with light Doré-style engraving hatching in the shadows. Campaign palette: brick red, parchment, ember orange, old gold, wrought iron grey. Hell of Dante seen as a forge. Clean shapes that read at 20 px tall on a phone. No text, no letters, no numbers anywhere.
```

## Stile C · Lama incisa

### `c_lama_scena`

```
Image 1 is the main character of our game, a little blacksmith-apprentice imp. Copy him exactly (shapes, proportions, colours, horns, neckerchief, tail); do not reinterpret him. He has NO flame on his head: do not add one. His neckerchief is BLUE #3d7bff. Image 2 is the small wrought-iron arrow that already marks the active player in our game: copy it exactly, only smaller.

Life bar: a very thin flat blade of dark steel, sharp at the right end, about twelve times longer than tall, with an engraved groove along it; the groove is filled with a glowing line of molten metal in the team colour for 70% of its length from the left, the rest of the groove is empty and dark. It is the most minimal of the three: one thin line. Crown (only the first in the ranking has it): a tiny flat old-gold crown made of three small engraved points, placed on the LEFT of the name slot, on the same line, not above it.

Scene: the imp of image 1 small in the picture (about one quarter of the image height), three-quarter view facing right, standing in the middle of a flat painted brick platform of the Forge in muted slate-blue bricks; behind, a dark muted slate-blue background with engraving hatching, darker and duller than the imp. Above his head, close to his horns, his minimal game HUD, stacked from top to bottom: the arrow of image 2, then the name line, then the life bar. The whole HUD is narrower than the imp's body and its total height is less than half of the imp's height: the imp must stay by far the most visible thing. Where the name goes, draw only a short empty slot (the game writes the name with its own font). The team colour of this scene is BLUE #3d7bff. Landscape 3:2.

Style: same as the MegaBlast apprentice imp reference (attached image 1): cartoon, thick black outline, flat cel colours with light Doré-style engraving hatching in the shadows. Campaign palette: brick red, parchment, ember orange, old gold, wrought iron grey. Hell of Dante seen as a forge. Clean shapes that read at 20 px tall on a phone. No text, no letters, no numbers anywhere.
```

### `c_lama_foglio`

```
Image 1 is the main character of our game, a little blacksmith-apprentice imp: use it ONLY for the style. Do not draw the imp.

The objects: the parts of a minimal life bar for a mobile game HUD. Life bar: a very thin flat blade of dark steel, sharp at the right end, about twelve times longer than tall, with an engraved groove along it; the groove is filled with a glowing line of molten metal in the team colour for 70% of its length from the left, the rest of the groove is empty and dark. It is the most minimal of the three: one thin line.

Pieces, top to bottom: 1) the empty steel blade with the dark engraved groove, long and straight, its middle part perfectly uniform so it can be stretched; 2) the glowing molten line alone, WHITE-HOT and neutral (white and pale cream only, no team colour, the game tints it); 3) the tiny flat old-gold crown, big on the sheet.

Sheet layout: solid flat magenta #FF00FF background, nothing else on it (no shadows on the magenta, no ground). Every piece alone, well separated from the others, drawn straight and flat, seen exactly from the front. Do not use magenta or pink anywhere on the pieces. Landscape 3:2.

Style: same as the MegaBlast apprentice imp reference (attached image 1): cartoon, thick black outline, flat cel colours with light Doré-style engraving hatching in the shadows. Campaign palette: brick red, parchment, ember orange, old gold, wrought iron grey. Hell of Dante seen as a forge. Clean shapes that read at 20 px tall on a phone. No text, no letters, no numbers anywhere.
```

## Criteri di accettazione

- [ ] l'apprendista è quello di R1 (forme, colori, corna, fazzoletto), senza fiammella
- [ ] la targa è più stretta del personaggio e alta meno della sua metà: il personaggio spicca più di tutto
- [ ] la Corona sta sulla stessa riga del nome, a sinistra, e non sopra
- [ ] nessuna scritta, lettera o numero
- [ ] fogli: magenta pieno, pezzi staccati e dritti, la brace o la riga accesa in bianco neutro

---

## Decisione

Approvata da Claude il 2026-11-03. È una scelta reversibile: sono immagini di proposta e il gioco
non cambia finché Sergio non sceglie.

Opzioni scartate senza immagine:
- la vita in numeri e basta: si legge male di colpo, mentre una barra si capisce con un'occhiata;
- la vita come anello sotto i piedi: sui crateri e sui bordi si perde, e copre il terreno dove si cammina;
- i cuori o le icone a pezzi: non sono della storia del gioco, e con 100 di vita la precisione si perde.


## Consegna di Codex

2026-11-03 · Generazione eseguita; risultati di proposta con difetti residui, non tutti i criteri di accettazione sono soddisfatti. Nessuna integrazione nel gioco.

### File consegnati

In `art/WB-011/`, ciascuno con il proprio `.txt` contenente il prompt originale e i riferimenti nell'ordine richiesto:

| File PNG | Tentativi eseguiti | Tentativo consegnato |
|---|---:|---:|
| `a_ferro_scena.png` | 3 | 1 |
| `a_ferro_foglio.png` | 1 | 1 |
| `b_catena_scena.png` | 3 | 2 |
| `b_catena_foglio.png` | 3 | 1 |
| `c_lama_scena.png` | 3 | 2 |
| `c_lama_foglio.png` | 1 | 1 |

### Controlli e limiti

- Usati esattamente i sei prompt della scheda; R1 allegato per primo, R2 per secondo nelle scene. Sfondo dipinto nelle scene, magenta nei fogli. Nessun ritocco, ricalco o taglio.
- Guardati tutti i tentativi. Verificati formato PNG, misura 1536×1024, assenza visibile di scritte, pezzi separati nei fogli, contorni neri, coda e corna intere, assenza di fiammella sulla testa e corona a sinistra della riga del nome nelle scene.
- **Scene, proporzioni non conformi:** il personaggio resta circa il 44–60% dell'altezza dell'immagine anziché circa il 25%. La targa supera la larghezza del torso, pur rimanendo più stretta della sagoma completa. I tentativi successivi non hanno risolto questi vincoli. R1 è riconoscibile ma non è una copia geometrica esatta.
- **A scena:** la vita resta arancione invece del blu #3d7bff in tutti e tre i tentativi. Il primo è consegnato come proposta di forma, non come risultato conforme al colore richiesto.
- **B scena:** selezionato il secondo tentativo, con cinque maglie e luce blu; il primo e il terzo presentavano luce arancione. Il riempimento è approssimato, non verificato al pixel.
- **B foglio:** nei tre tentativi persistono giallo/arancione attorno alla brace e sulla metà accesa; il bianco neutro non è rispettato pienamente. Consegnato il primo, senza la catena extra introdotta dal secondo e con meno arancione del terzo. La corona del foglio ha cinque punte, diversa dalle tre della scena.
- **A foglio:** la striscia chiara ha tratteggi dorati alle estremità; non è interamente neutra. La guida risulta più allungata del rapporto indicativo 8:1.
- **C:** luce blu nella scena; foglio con lama, linea chiara e corona separati. Anche la lama del foglio è più allungata del rapporto indicativo 12:1.
- **Fogli, sfondo non esatto:** appare magenta ma gli angoli campionati variano (R 237–247, G 12–36, B 234–243), quindi non è il pieno #FF00FF richiesto. Non certificati gli aloni al taglio; necessario riesame prima del taglio automatico. Nessuna correzione esterna delle immagini.
- Non verificati nel gioco: leggibilità a 20 px, tintura del materiale, taglio e stiramento delle barre. I criteri della scheda restano non spuntati per la revisione di Claude e Sergio.
- Segnalazione documentale: DECISIONI.md (2026-10-26) descrive ancora la fiammella sopra la testa, mentre questa scheda prescrive esplicitamente R1 senza fiammella. Le immagini seguono il prompt approvato senza modificare le decisioni.

## Resoconto di Claude

2026-11-03 · Guardate tutte e sei le immagini (pagina delle proposte, sezione 6). Nessuna è da
rifare per la scelta: i difetti stanno nei colori delle scene (A arancione) e nei pezzi che il gioco non usa.

- **Scelta di Sergio: C, con la sua Corona**, e il nome senza targhetta sopra la vita. Claude
  consigliava A (più vicina alla freccia di ferro); B scartata perché da lontano la vita si legge a
  scatti di 20.
- **Integrati** da `c_lama_foglio.png` con `tools/grafica/targa.py`: la lama (manico, un pezzetto
  di mezzo senza graffi che il gioco allunga, la punta) e la Corona. La riga chiara del foglio non
  serve: la vita è un rettangolo tinto dentro la scanalatura, che si accorcia senza deformare punte
  tonde. Il magenta non pieno si toglie come per la freccia; nessun alone visibile.
- **Non usati**: le scene (sono di prova), i fogli A e B. In `art/WB-011/` restano solo i file di C;
  gli altri sono sul ramo `design/WB-011`.
- Provata nel simulatore a ogni zoom e a 2x (come sul telefono), con la Corona su Oro nella lezione dei punti.

- [x] la targa è più stretta del personaggio e alta meno della sua metà
- [x] la Corona sta sulla stessa riga del nome, a sinistra
- [x] nessuna scritta nelle immagini
- [x] pezzi staccati e dritti; la riga accesa (non usata) in bianco

2026-11-03, più tardi · Sergio ha chiesto una targa ancora più semplice: la lama non si usa più (la vita è una riga piena). Della scheda resta nel gioco la Corona d'oro.
