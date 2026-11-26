# WB-098 · La Fornace: le borse appese alle corde, chiuse col sigillo, la trave dei conti, l'usuraio del banco

- **Stato:** IN PARTE SCARTATA (Sergio, 26 nov: «i calderoni di prima mi piacevano di più»: le borse aperte e chiuse e la corda escono dal gioco, tornano gli stampi di WB-093; restano la trave coi cordini e l'usuraio del banco). Prima IMPLEMENTATA (Claude, 26 nov: nel gioco sul ramo `claude/project-thread-oh0dd6`, PR #437; approvata su anteprima di Sergio https://claude.ai/artifact/FtpmtRZabnAmpyvbGpq1n8 , «Mi piace l’anteprima»)
- **Data:** 2026-11-26
- **Ramo della scheda:** `claude/project-thread-oh0dd6` (Codex la esegue da qui: `git fetch origin claude/project-thread-oh0dd6`, non serve che sia su `main`) · **Ramo delle immagini:** `design/WB-098`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-098` senza chiedere conferma (il repository è privato).

## Obiettivo

Gli usurai seduti sul muro della Fornace (WB-097) facevano troppa confusione (Sergio, 26 nov). Restano il Sabbione, l'argine, il bancone e la parete di roccia di WB-097; cambiano gli stampi:

- **Gli stampi sono solo le borse degli usurai**, con lo stemma della famiglia, **appese a corde** che salgono a una trave in alto (niente pinnacoli né piedistalli). La corda prende la borsa con un nodo a V sull'orlo.
- **Una borsa presa si chiude**: la bocca raccolta in un ciuffo, legata stretta con la corda e chiusa da un **sigillo di ceralacca rossa** sul nodo; al centro del sigillo il gioco mette l'icona del premio.
- **In alto, la trave dei conti**: una trave di legno lungo tutto il muro, con pioli di ferro a passo fisso e da ogni piolo un **cordino annodato** (i nodi contano i debiti), lungo o corto a turno. Dà riferimenti per mirare senza essere una griglia.
- **Un solo usuraio**, seduto accanto al bancone del bottino, parla ogni tanto e brontola quando paga.

Le bozze R1 e R3 sono mie, fatte coi pezzi del gioco: dicono DOVE stanno le cose e cosa sono. La borsa di R2 è ritagliata da `usurai_vuoti_2` e la chiusura è un mio schizzo: va ridisegnata bene nello stesso stile.

Misure nel gioco (schermo 1280×720): una borsa è larga circa 50 px (le piccole 35); la trave è alta 20 px; un cordino è lungo da 30 a 70 px; l'usuraio del banco è alto circa 150 px. Codex disegna **almeno al triplo** (una borsa larga almeno 200 px nel foglio, l'usuraio alto almeno 450 px).

Tutti i pezzi hanno il contorno a china, come gli usurai di WB-097, su verde pieno #00FF00 per il ritaglio, ben separati.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-098/riferimenti/R1_anteprima_muro.png` | l'anteprima approvata: borse appese, trave dei conti in alto, bancone con l'usuraio a destra |
| R2 | `art/WB-098/riferimenti/R2_borsa_aperta_e_chiusa.png` | la borsa da prendere (aperta) e la borsa presa (chiusa e sigillata): la chiusura è uno schizzo |
| R3 | `art/WB-098/riferimenti/R3_anteprima_incassa.png` | fine colata: le monete volano dal bancone al portafoglio, l'usuraio brontola |
| R4 | `art/WB-097/usurai_vuoti_2.png` | gli usurai di WB-097: lo STILE e le borse da copiare (forma, cuoio, cordone, stemma) |
| R5 | `art/WB-084/frammenti_1.png` | i colori delle famiglie |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto: il primo è "image 1", il secondo "image 2", e così via.

| Nome file | Cosa c'è | Riferimenti | Misura | Varianti |
|---|---|---|---|---|
| `borse_aperte` | sei borse appese, aperte, vuote, con la V di corda | R1, R2, R4, R5 | 1536×1024 | 2 |
| `borse_chiuse` | le stesse sei borse chiuse, legate e sigillate | R2, R4, R5 | 1536×1024 | 2 |
| `trave_e_corde` | la trave a pezzi, il piolo, la corda che si ripete, i cordini annodati | R1, R4 | 1536×1024 | 2 |
| `usuraio_del_banco` | l'usuraio seduto accanto al bancone, in tre facce | R1, R3, R4 | 1536×1024 | 2 |

Le varianti si chiamano `borse_aperte_1.png`, `borse_aperte_2.png` e così via, in `art/WB-098/`. Per ogni foglio Codex scrive un `.txt` con lo stesso nome: cosa ha fatto e cosa non è riuscito a rispettare.

### `borse_aperte`

```
Image 1 is a draft of a minigame of our cartoon game: leather purses of usurers hang from ropes in a burning desert of hell, and a little devil throws drops of molten metal into their open mouths; it only says WHERE things are. Image 2, on the left, is one purse cut from our art: the shape to keep. Image 3 shows our usurers and their purses: copy EXACTLY that STYLE: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, hand-drawn like a cartoon comic. Image 4 shows the five family colors.

Draw SIX separate leather purses on plain green (#00FF00), in two rows of three, well apart, each one whole, all the SAME size and shape, about 230 px wide. Each is a round fat purse of worn brown leather (#84492A, highlight #B06834, shadow #5E3018) like the ones in image 3, hanging: its round MOUTH is OPEN TOWARDS THE SKY and we see it from a little above, a dark EMPTY hollow (#120806) with a thick rolled leather rim and a drawstring cord around the neck. From two opposite points of the rim, left and right, two short pieces of thick rope (#D6A062, shadow #A06C3A) rise and meet in a small knot above the middle of the mouth, making a V; the rope stops just above the knot, cut clean and straight (the game continues it). No hands, no neck cord, no person. On the front of each purse a small flat shield-shaped coat of arms, EMPTY and of one plain color: from left to right, top row then bottom row, gold (#FFB703), ice blue (#8FD8F5), fire orange (#F26419), sea green (#5CDBB8), violet (#C49CFF), plain iron grey (#8A8F98).
Nothing else: no icons on the shields, no letters, no coins, no shadow on the ground, no glow halo.
```

### `borse_chiuse`

```
Image 1 shows on the left an open purse of our game and on the right a rough sketch of the same purse once it is taken: CLOSED, tied and sealed. Image 2 shows our usurers and their purses: copy EXACTLY that STYLE: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, hand-drawn like a cartoon comic. Image 3 shows the five family colors.

Draw the SAME SIX purses as the open ones (round fat purses of worn brown leather #84492A, the same size, about 230 px wide, the same flat shield coat of arms on the front: gold #FFB703, ice blue #8FD8F5, fire orange #F26419, sea green #5CDBB8, violet #C49CFF, iron grey #8A8F98, in this order, top row then bottom row), on plain green (#00FF00), well apart, each whole. Now each purse is CLOSED and a little fuller: its mouth is gathered up into a puckered leather tuft with soft folds, tied tight at the neck with several turns of thick rope (#D6A062), and on the knot sits a big round RED WAX SEAL (#B0221C, shadow #78120F) with wavy squashed edges and an EMPTY flat round center a little darker, where the game will put an icon. The rope goes up from the knot and stops a little above it, cut clean and straight (the game continues it). It must read at a glance as "taken, closed, done", very different from the open one but clearly the same purse.
Nothing else: no icons in the seal, no letters, no coins, no shadow on the ground, no glow halo.
```

### `trave_e_corde`

```
Image 1 is a draft of a minigame of our cartoon game: at the top of the screen a long wooden beam crosses the whole scene; from iron pegs at a regular step hang short knotted cords, long and short in turn, and some longer ropes go down to hold leather purses. Image 2 shows the STYLE of our game: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, hand-drawn like a cartoon comic.

Draw these separate pieces on plain green (#00FF00), well apart, each whole:
1. THE BEAM, in three pieces: a LEFT END wedged into a lump of dark red rock (#5A2A1C), a MIDDLE piece whose left and right ends are cut straight so the game can repeat it seamlessly, and a RIGHT END wedged into rock too. An old squared wooden beam of dark brown wood (#6A3F22, highlight #94603A, shadow #43250F), seen from the front, about ten times longer than tall, with iron nails and a few notches carved like tally marks.
2. THE PEG: one small black iron peg with a ring, seen from the front, to put under the beam.
3. THE ROPE: one straight vertical piece of thick twisted rope (#D6A062, shadow #A06C3A), about twelve times longer than thick, its top and bottom cut straight so the game can stack it seamlessly.
4. FOUR TALLY CORDS: short thin cords hanging straight down, each with knots at a regular step and a small tassel at the end: two short (three knots) and two long (five knots); one short and one long have a red tassel (#B0221C), the others a natural rope tassel. Their top is cut straight (they hang from the peg).
No characters, no purses, no letters, no shadow on the ground, no glow halo.
```

### `usuraio_del_banco`

```
Image 1 is a draft of a minigame of our cartoon game: at the bottom right, next to the long wooden counter where the player's loot piles up, sits one usurer who keeps the accounts and talks to the player now and then. Image 2 shows the end of the session: the coins fly from the counter to the player's wallet and the usurer grumbles. Image 3 shows our usurers: copy EXACTLY that character and STYLE: a skinny, hunched, greedy damned soul with grey-green skin (#8D8F86), sunken cheeks, big greedy yellow eyes, a long nose, wrapped in a ragged hooded cloak (dark grey-brown #4A3A30), thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, cartoon comic.

Draw the SAME usurer THREE times on plain green (#00FF00), side by side, well apart, each whole, same size (about 480 px tall) and same pose: he SITS on a small wooden stool, seen three quarters, turned towards the LEFT (where the counter is), one bony hand on a small open account book on his knees and a quill in the other. No purse in his hands. Three faces:
1. QUIET: mouth closed, a sly greedy grin, eyes on the counter.
2. TALKING: mouth wide open as if saying a line, one finger raised.
3. PAYING: grumpy and sorry, eyebrows down, lower lip out, the hand with the quill thrown up in despair.
Nothing else: no counter, no coins, no letters, no speech bubbles, no shadow on the ground, no glow halo.
```

## Criteri di accettazione

- [ ] borse: sei borse separate, stessa forma e misura, nessuna mano o persona; bocca aperta verso il cielo vista da sopra; V di corda con nodo sopra la bocca, tagliata dritta
- [ ] borse chiuse: le stesse sei, stesso stemma; ciuffo legato e sigillo rosso col centro vuoto; si capiscono "prese" a colpo d'occhio
- [ ] trave: il pezzo di mezzo si ripete senza righe; la corda si impila senza righe
- [ ] usuraio: lo stesso nelle tre facce (posa, misura, mantello), girato a sinistra, seduto
- [ ] nessuna scritta, nessun alone, verde pieno attorno

Approvata da Claude il 26 nov: Sergio ha approvato l'anteprima. Quando questi disegni saranno nel gioco, Claude toglie dal gioco e dall'atlante gli usurai e i pinnacoli di WB-097 che non servono più.

## Consegna di Codex

- `art/WB-098/borse_aperte_1.png` e `borse_aperte_2.png`, con i rispettivi `.txt` — un tentativo per variante.
- `art/WB-098/borse_chiuse_1.png` e `borse_chiuse_2.png`, con i rispettivi `.txt` — un tentativo per variante.
- `art/WB-098/trave_e_corde_1.png` e `trave_e_corde_2.png`, con i rispettivi `.txt` — tre tentativi per la prima variante, selezionato il terzo, un tentativo per la seconda.
- `art/WB-098/usuraio_del_banco_1.png` e `usuraio_del_banco_2.png`, con i rispettivi `.txt` — un tentativo per variante.

Otto PNG da 1536×1024, con i prompt originali eseguiti in ImageGen e i riferimenti nell'ordine indicato. I fogli delle borse hanno la misura nativa richiesta. Travi e usurai sono stati ridimensionati in proporzione e centrati su verde. Per gli usurai ho ritagliato soltanto il verde ai lati per mantenere tutte le pose sopra i 450 px.

Controllati numero, separazione e ordine degli stemmi. Le borse aperte hanno cavità visibile e tiranti a V. Quelle chiuse hanno ciuffo e sigillo rosso vuoto. Le sagome delle borse sono larghe circa 307–337 px, oltre circa 230 px indicati nel prompt, con lievi differenze tra gli stati. In entrambi i fogli si riconoscono le tre espressioni dell'usuraio seduto rivolto a sinistra. I quattro cordini di ogni variante hanno tre o cinque nodi. Il fondo si discosta da #00FF00 esatto. I bordi neri di alcuni pezzi possono lasciare una riga alla giunzione. La ripetizione effettiva della trave e della corda e la resa in gioco restano da verificare.

## Resoconto di Claude

26 nov. Nel gioco sul ramo `claude/project-thread-oh0dd6` (PR #437), tagli e misure in `tools/grafica/fornace.py` (`fai_wb098`).

- **Scelti**: `borse_aperte_1` (la V di corda e la bocca più leggibili), `borse_chiuse_1` (stessa forma delle aperte, sigillo grande), `trave_e_corde_2` (nodi più puliti, piolo ad anello), `usuraio_del_banco_1` (la faccia di chi paga è disperata; nella 2 fa la linguaccia).
- **Tagli**: la bocca della borsa si trova da sola (il buio dentro l'orlo, poi l'orlo fino al contorno), così come il punto da cui esce la corda e il mezzo della ceralacca; la borsa chiusa si mette con la pancia allineata a quella aperta. Il pezzo di mezzo della trave e la corda sono tagliati dentro il contorno ai capi: si ripetono senza righe (controllato nelle foto del simulatore).
- **Misure nel gioco**: una sola misura per colore (le borse piccole sono le grandi rimpicciolite, mai ingrandito un disegno); la trave alta 30 unità del mondo a y = 530, un cordino ogni 95; l'usuraio del banco alto 225 in fondo al bancone.
- **Tolti**: gli usurai e i pinnacoli di WB-097 e la goccia grande di WB-092 (gioco, atlante, tagli).
