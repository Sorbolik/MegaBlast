# WB-074 · Perle del livello e slot della firma

- **Stato:** APPROVATA (Sergio, 18 nov 12:47: «sì, falla fare a codex», «proviamole» sulle perle sul filo)
- **Data:** 2026-11-18
- **Ramo della scheda:** `claude/project-thread-echcwc` (Codex la esegue da qui: `git fetch origin claude/project-thread-echcwc`, non serve che sia su `main`) · **Ramo delle immagini:** `design/WB-074`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-074` senza chiedere conferma (il repository è privato).

## Obiettivo

Il livello di un pezzo (da 1 a 30) si mostra come trenta perline su un filo d'inchiostro. Al 10, al 20 e al 30 la perla grande è lo slot della firma: compare solo quando arrivi a quel livello, prima vuoto e poi con dentro la gemma dell'Ossidiana quando accendi la firma. Lo slot di oggi è disegnato a codice e Sergio lo trova povero: «mi sembra fatto da un bambino». Qui chiediamo a Codex le perline e lo slot nello stesso stile delle monete appena approvate (WB-072).

Sarà il modo ufficiale di mostrare gli upgrade in tutto il gioco (Sergio, 18 nov 12:48). Il filo d'inchiostro lo disegna il codice. La perla piena è grigio chiaro neutro perché il gioco la colora del grado (bronzo, argento, oro, brace). Nel gioco le perline sono alte da 10 a 24 px e lo slot da 20 a 48 px.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-074/riferimenti/R1_perle_bozza.png` | la bozza approvata: trenta perline sul filo, al 10, 20 e 30 la perla grande della firma |
| R2 | `art/WB-074/riferimenti/R2_monete_approvate.png` | le monete approvate di WB-072 (Ossidiana, Scaglia, buono): lo stile, il rilievo e la gemma dell'Ossidiana da riprendere |
| R3 | `art/WB-074/riferimenti/R3_stile.png` | un pulsante della home: lo stile della china |

## Immagini da generare

Il prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine: il primo è "image 1", il secondo "image 2" e così via.

| Nome file | Cosa c'è | Riferimenti | Misura | Varianti |
|---|---|---|---|---|
| `perle` | tre perline e tre slot della firma | R1, R2, R3 | 1536×1024 | 3 |

Le varianti si chiamano `perle_1.png`, `perle_2.png` e `perle_3.png`, in `art/WB-074/`. Per ogni foglio Codex scrive un `.txt` con lo stesso nome: cosa ha fatto e cosa non è riuscito a rispettare.

### `perle`

```
Image 1 is a sketch of how our game shows the level of a piece of equipment: thirty small beads on a thin black ink thread, and at levels 10, 20 and 30 a big bead that is the slot of the piece's signature, where a gem is set. Image 2 shows three approved coins of the same game: the OSSIDIANA (a faceted black and violet gem with a bright magenta rim), the SCAGLIA (an eight-sided gold coin with a flame carved into it) and the blacksmith's voucher (a round dark iron token with a hammer carved into it). Copy their style exactly: thick slightly irregular black ink outline, flat colors with one flat highlight and one flat shadow, real thickness and relief, details carved into the surface. Image 3 is a button of the same game and confirms the STYLE: like a cartoon comic, soft hand-drawn slightly crooked shapes, never sharp or spiky.

Draw SIX separate icons on plain green (#00FF00), in two rows, well apart from each other, no thread between them.
Top row, three SMALL BEADS, all exactly the same size (about 140 px wide), each a round bead seen from the front with a thick ink outline, one flat highlight at the top left and a darker band at the bottom right that shows it is round:
1. EMPTY BEAD: dark forged iron (#3A3340, highlight #5A5263, shadow #1E1A22).
2. FULL BEAD: neutral very light grey metal (#E6E6E6, highlight #FFFFFF, shadow #A8A8A8), no other color: the game tints it.
3. NEXT BEAD: glowing ember orange (#F26419, core #FFB703, highlight #FFE08A), hot as metal just taken from the fire.
Bottom row, three BIG SIGNATURE SLOTS, all exactly the same size (about 300 px wide, a bit more than twice the small beads), each a round thick token of dark forged iron (#3A3340, highlight #5A5263, side #1E1A22) with a raised rim:
4. EMPTY SLOT: in its face a hollow in the exact shape of the Ossidiana gem of image 2 (a diamond), CARVED INTO the iron like the flame and the hammer of image 2: a dark shadow band (#1E1A22 and black ink) along the upper left edge of the hollow, a thin light band (#5A5263) along its lower right edge, the bottom of the hollow very dark (#141017). It must look empty, waiting for its gem.
5. LIT SLOT: exactly the same token, with the Ossidiana gem of image 2 set inside the hollow, sitting deep in it, its magenta rim (#FF70D1) glowing softly inside the hollow only.
6. RED-HOT SLOT: exactly the same empty token as number 4, but red-hot as just forged: the iron glowing orange and yellow (#F26419, #FFB703, white core #FFF3B0 in the hollow), outline still black ink.
Each icon must read at 16 pixels for the beads and 32 pixels for the slots: one bold full silhouette, no thin details. No letters, no numbers, no thread, no shadow on the ground, no glow outside the ink.
```

## Criteri di accettazione

- [ ] contorno nero spesso, nessuna scritta, sei icone ben staccate sul verde
- [ ] le tre perline sono uguali di misura e di forma, la piena è grigia neutra (si colora nel gioco)
- [ ] i tre slot sono uguali di misura e di forma; lo scavo a gemma sembra davvero scavato, come la fiammella della Scaglia
- [ ] lo slot acceso ha la gemma dell'Ossidiana di WB-072 dentro lo scavo
- [ ] si riconoscono a 16 px (perline) e a 32 px (slot)

---

## Decisione

Sergio, 18 nov 12:18 sullo slot disegnato a codice: «mi sembra fatto da un bambino». 12:19: il punto di partenza dell'animazione era decentrato e il prossimo livello sembrava un pallino (corretti). 12:47: «sì, falla fare a codex, comunque così è un po' meglio, ma non ci siamo comunque, forse era meglio che facessi le perle sul filo, proviamole». 12:48: «quello che esce fuori da qui, va riportato dappertutto, sarà il modo ufficiale di vedere gli upgrade». Numero assegnato dal coordinatore.

## Consegna di Codex

- `art/WB-074/perle_1.png` e `perle_1.txt` · 1 tentativo.
- `art/WB-074/perle_2.png` e `perle_2.txt` · 1 tentativo.
- `art/WB-074/perle_3.png` e `perle_3.txt` · 1 tentativo.

ImageGen integrato con il prompt integrale e i riferimenti R1–R3 in ordine. I fogli sono stati ridotti in proporzione e centrati su una tela verde da 1536×1024 per avvicinare le larghezze delle icone a 140 e 300 px. Le icone della stessa fila presentano piccole variazioni di sagoma e misura. Il verde generato presenta lievi scostamenti da #00FF00 e alcune superfici hanno sfumature leggere.

Verificati sei elementi separati per foglio, contorno scuro spesso, ordine richiesto, assenza di scritte e filo, perlina piena grigia a vista e Ossidiana con bordo magenta nello slot acceso. Le perline si distinguono a 16 px, gli slot a 32 px. Lo scavo è visibile per contrasto fra bordo e fondo. Ritaglio, colorazione per grado e resa nel gioco da verificare.

## Resoconto di Claude

- 18 nov: nel gioco il foglio `perle_2` (scelta di Claude: lo scavo a gemma più netto dei tre). Lo taglia `fai_perle` in `tools/grafica/fucina.py` nei pezzi `perla_vuota`, `perla_piena` (grigia, il gioco la colora del grado), `perla_prossima`, `slot_vuoto`, `slot_acceso` e `slot_rovente`; li usa `client/ui/ingots.lua` (scheda, zaino, scatto, accendi la firma). Ogni slot ha il suo posto nella fila, le perline non ci vanno sotto (Sergio, 13:14). `perle_1` e `perle_3` restano solo nel ramo `design/WB-074`. Simulazione OK (`zaino_scheda.txt`, `scatto.txt`).
