# WB-075 · Riquadro del profilo in home e barra dell'esperienza

- **Stato:** IMPLEMENTATA (Sergio, 18 nov 13:58: «fammele vedere tutte con codex, voglio vedere l'anteprima finale»)
- **Data:** 2026-11-18
- **Ramo della scheda:** `claude/project-thread-43o6uf` (Codex la esegue da qui: `git fetch origin claude/project-thread-43o6uf`, non serve che sia su `main`) · **Ramo delle immagini:** `design/WB-075`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-075` senza chiedere conferma (il repository è privato).

## Obiettivo

In alto a sinistra della home c'è il riquadro del profilo: il tondo con la faccia, il nome APPRENDISTA, LIV 50 e la barra dell'esperienza. Sergio lo trova scomposto: tre cornici una dentro l'altra, un rivetto che sembra un pomello, la barra storta che non si allinea con niente (R2). Claude ha fatto quattro bozze coi pezzi di oggi (R1, dall'alto: A medaglione col sigillo, B una piastra sola, C filo di brace, D stendardo forgiato). Sergio vuole vederle tutte disegnate da Codex, e vuole anche una **barra dell'esperienza nuova, dritta**.

Codex disegna solo i pezzi, **senza scritte e senza faccia**: il nome, il numero del livello e la testa li mette il gioco. Con questi pezzi Claude compone le quattro anteprime finali col carattere e la faccia veri. Il centro del tondo resta un disco scuro vuoto. Le parti lunghe (piastre, barra, stendardo) devono avere il tratto centrale **dritto e uguale** per tutta la lunghezza, perché il gioco lo allunga.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-075/riferimenti/R1_bozze_ABCD.png` | le quattro bozze di Claude, dall'alto A, B, C, D: composizione e proporzioni |
| R2 | `art/WB-075/riferimenti/R2_oggi.png` | il riquadro di oggi, quello da NON rifare (cornici sovrapposte, barra storta) |
| R3 | `art/WB-075/riferimenti/R3_monete_approvate.png` | le monete approvate di WB-072: stile, rilievo, dettagli scavati |
| R4 | `art/WB-075/riferimenti/R4_stile.png` | un pulsante della home: lo stile della china |
| R5 | `art/WB-075/riferimenti/R5_pezzi_oggi.png` | l'anello d'oro e il sigillo del livello di oggi: colori da tenere |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine indicato: il primo è "image 1", il secondo "image 2" e così via. Sfondo verde pieno #00FF00 per tutti.

| Nome file | Cosa c'è | Riferimenti | Misura | Varianti |
|---|---|---|---|---|
| `barra` | barra dell'esperienza nuova: incavo, riempimento, punta | R2, R3, R4 | 1536×1024 | 2 |
| `anello` | anello d'oro del ritratto e sigillo del livello (proposte A, B, C) | R1, R3, R4, R5 | 1536×1024 | 1 |
| `piastra` | una sola piastra di ferro, senza rivetti (proposta B) | R1, R2, R3, R4 | 1536×1024 | 1 |
| `tizzone` | filo di brace: tizzone acceso e capi del filo (proposta C) | R1, R3, R4 | 1536×1024 | 1 |
| `stendardo` | anello e stendardo in un pezzo unico, con moneta (proposta D) | R1, R3, R4, R5 | 1536×1024 | 2 |

Le varianti si chiamano `barra_1.png`, `barra_2.png`, `stendardo_1.png`, `stendardo_2.png`; le altre `anello.png`, `piastra.png`, `tizzone.png`, tutte in `art/WB-075/`. Per ogni foglio Codex scrive un `.txt` con lo stesso nome: cosa ha fatto e cosa non è riuscito a rispettare.

### `barra`

Riferimenti: R2, R3, R4.

```
Image 1 shows the experience bar our game uses today in the player's profile: it is crooked, wobbly and uneven, and we want a NEW one that is perfectly straight. Image 2 shows approved coins of the same game and image 3 a button of the same game: copy their style exactly, a cartoon comic look with a thick slightly irregular black ink outline, flat colors with one flat highlight and one flat shadow, real thickness and relief.

Draw on plain green (#00FF00) three separate horizontal pieces, one above the other, well apart, all exactly the same length (about 1300 px) and perfectly straight and horizontal:
1. EMPTY GROOVE (about 70 px tall): a channel carved into dark forged iron, rounded ends like a capsule. Outer thick black ink outline, a thin lighter iron lip along the bottom edge (#5A5263), the inside of the channel very dark (#1A161D) with a darker shadow band along its top inner edge, as if the channel were really cut into the metal. The middle part must be EXACTLY the same all along its length: no scratches, no rivets, no bends, so the game can stretch it.
2. MOLTEN FILL (about 46 px tall, so it fits inside the groove with an even margin): molten gold and ember metal, core #FFB703, lower half #F26419, one straight thin bright highlight line along the top (#FFE08A), thick black ink outline, rounded left end and flat cut right end. Uniform along its length, no bubbles or patterns that would repeat visibly when stretched.
3. HOT TIP (about 70 px tall, about 70 px wide): the leading end of the molten fill, a short rounded cap glowing white-yellow (#FFF3B0 core, #FFB703 edge) with a few very small sparks just around it, still with the black ink outline. It sits at the right end of the fill to show where your experience has arrived.
No letters, no numbers, no frame around everything, no shadow on the ground, no glow outside the ink except the small sparks of piece 3.
```

### `anello`

Riferimenti: R1, R3, R4, R5.

```
Image 1 shows four sketches of the player's profile banner of our game. Image 2 shows approved coins of the same game and image 3 a button of the same game: copy their style exactly, a cartoon comic look with a thick slightly irregular black ink outline, flat colors with one flat highlight and one flat shadow, real thickness and relief, details carved into the surface. Image 4 shows the gold ring and the gold level seal we use today: keep their colors (gold #FFB703, orange #F26419) but draw them new and better.

Draw on plain green (#00FF00) two separate pieces, well apart:
1. PORTRAIT RING (about 600 px wide): a thick round ring of polished gold with real thickness, a raised outer rim and an inner bevel, four small dark iron rivets evenly spaced on it. The centre is a perfectly round flat very dark disc (#1A161D) taking about 72 percent of the width: it must be EMPTY, the game puts the player's face there. The ring is perfectly circular and the same thickness all around.
2. LEVEL SEAL (about 240 px wide): a round thick gold coin like a wax seal, a raised rim, a flat smooth face in the middle with nothing on it (the game writes the level number there), a small notch or two on the rim so it reads as a seal. It will be placed on the lower right of the ring, so its outline must be clean and bold.
No letters, no numbers, no face, no shadow on the ground, no glow outside the ink.
```

### `piastra`

Riferimenti: R1, R2, R3, R4.

```
Image 1 shows four sketches of the player's profile banner of our game: the second one from the top is a round portrait ring with ONE dark iron plate coming out from behind it, with the player's name and level on the top line and the experience bar under them. Image 2 is today's banner, which is messy: three frames inside each other, a lonely rivet on the right, nothing lines up. We want the opposite: ONE clean plate. Image 3 shows approved coins of the same game and image 4 a button of the same game: copy their style exactly, a cartoon comic look with a thick slightly irregular black ink outline, flat colors with one flat highlight and one flat shadow, real thickness and relief.

Draw on plain green (#00FF00) one single long horizontal plate of dark wrought iron (#2E2833, top highlight #5A5263, bottom side #17131A), about 1400 px long and 250 px tall, with real thickness: a flat front face and a visible lower edge. The left end is simple and square (it goes behind the round portrait). The right end is cut slightly slanted with a soft rounded corner. NO rivets, NO knobs, NO inner frame, NO recess: only one plate with one outline. The middle part must be EXACTLY the same all along its length (no scratches, no bends) so the game can stretch it. One subtle forged hammer-mark texture only near the two ends is allowed.
No letters, no numbers, no bar, no shadow on the ground, no glow outside the ink.
```

### `tizzone`

Riferimenti: R1, R3, R4.

```
Image 1 shows four sketches of the player's profile banner of our game: the third one from the top shows the experience as a thin black ink thread that is lit like an ember from the left up to the point where the player has arrived, with a small glowing ember at that point. Image 2 shows approved coins of the same game and image 3 a button of the same game: copy their style exactly, a cartoon comic look with a thick slightly irregular black ink outline, flat colors with one flat highlight and one flat shadow, real relief.

Draw on plain green (#00FF00) three separate pieces, well apart:
1. EMBER (about 260 px wide): a small glowing lump of burning coal, rounded and chunky, core white-yellow (#FFF3B0), body #FFB703, edges #F26419, a few dark cracks carved in it, thick black ink outline, with a short soft flame licking upward from it.
2. LIT THREAD (about 1300 px long, about 28 px tall, perfectly straight): a thin ink-outlined rod of glowing ember metal, #F26419 with a thin #FFE08A line along the top, exactly the same all along its length.
3. DARK THREAD (same size as piece 2, perfectly straight): the same rod cold and dark (#3A3340 with a thin #5A5263 line along the top), exactly the same all along its length.
No letters, no numbers, no shadow on the ground, no glow outside the ink except a small warm halo around the ember.
```

### `stendardo`

Riferimenti: R1, R3, R4, R5.

```
Image 1 shows four sketches of the player's profile banner of our game: the fourth one from the top (at the bottom) is a round gold portrait ring with a dark iron banner with a swallowtail end coming out of it, the experience bar carved into the banner and the level in a gold coin near the swallowtail. We want this as ONE single forged piece: ring and banner are made together, nothing laid on top of anything else. Image 2 shows approved coins of the same game and image 3 a button of the same game: copy their style exactly, a cartoon comic look with a thick slightly irregular black ink outline, flat colors with one flat highlight and one flat shadow, real thickness and relief, details carved into the surface. Image 4 shows the gold ring and gold level seal used today: keep their gold colors (#FFB703, #F26419).

Draw on plain green (#00FF00), well apart:
1. THE BANNER, one piece about 1450 px long and 330 px tall: on the left a thick polished gold ring (about 330 px wide) with a raised rim and four small dark rivets, its centre a perfectly round flat EMPTY very dark disc (#1A161D, about 72 percent of the ring): the game puts the face there. From the right side of the ring a dark wrought iron banner (#2E2833, highlight #5A5263, side #17131A) runs to the right, vertically centred on the ring and about 55 percent of its height, joined to the ring as if forged together (the ring overlaps the banner's start, with one shared ink outline, no gap). The banner ends with a swallowtail cut. Carved into the banner: a long straight horizontal groove in its lower half (the game puts the experience fill in it), very dark inside (#1A161D) with a shadow band along its top inner edge, starting about 30 px after the ring and ending about 70 px before a round socket; near the swallowtail a round socket carved into the iron for the level coin. The upper half of the banner stays flat and empty (the game writes the name there). The banner between ring and socket must be EXACTLY the same all along its length.
2. LEVEL COIN (about 210 px wide, so it fits the socket): a round thick gold coin, raised rim, flat smooth empty face (the game writes the number).
No letters, no numbers, no face, no shadow on the ground, no glow outside the ink.
```

## Criteri di accettazione

- [ ] contorno nero spesso, nessuna scritta, nessun numero, nessuna faccia; pezzi ben staccati sul verde
- [ ] barra, piastra, filo e stendardo perfettamente dritti, con il tratto centrale uguale per tutta la lunghezza
- [ ] il centro dell'anello è un disco scuro vuoto e perfettamente rotondo
- [ ] nessuna cornice dentro un'altra cornice, nessun rivetto isolato a destra
- [ ] stesso stile delle monete WB-072

---

## Decisione

Sergio, 18 nov 13:34 sul riquadro di oggi: «tutta scomposta, non lineare, ci sono cose che sembrano sovrapposte, molto brutta, fammi delle proposte anche con codex se serve». 13:58, viste le bozze A-D (https://claude.ai/artifact/6BUykPA6j1pzZW9iQmRVCg): «fammele vedere tutte con codex, voglio vedere l'anteprima finale comunque la D mi potrebbe interessare, ma anche la barra di progressione va rifatta, è tutta storta». Numero assegnato dal coordinatore.

## Consegna di Codex

ImageGen integrato con i prompt integrali e i riferimenti nell'ordine della scheda. Sette PNG da 1536×1024 su verde. I fogli nativi più larghi sono stati ridotti in proporzione e centrati. Il verde generato varia leggermente rispetto a #00FF00 e alcune superfici hanno leggere sfumature.

| Foglio e prompt | Tentativi | Tentativo scelto | Verifica visiva |
|---|---:|---:|---|
| `art/WB-075/barra_1.png` e `barra_1.txt` | 1 | 1 | Incavo, riempimento e punta destra separati. Incavo e riempimento quasi rettilinei ma di lunghezza e spessore diversi da quelli indicati. |
| `art/WB-075/barra_2.png` e `barra_2.txt` | 2 | 2 | Incavo e riempimento rettilinei a vista, punta destra separata. Incavo e riempimento hanno lunghezze leggermente diverse e sono più spessi del previsto. |
| `art/WB-075/anello.png` e `anello.txt` | 1 | 1 | Disco scuro vuoto e quattro rivetti. Sigillo separato con due tacche, più grande in proporzione rispetto alla scheda. |
| `art/WB-075/piastra.png` e `piastra.txt` | 3 | 2 | Piastra unica, liscia al centro, priva di rivetti. Il bordo centrale resta leggermente ondulato. |
| `art/WB-075/tizzone.png` e `tizzone.txt` | 1 | 1 | Tizzone e due fili separati. Fili quasi rettilinei. Alone caldo sul verde intorno al tizzone, da gestire al ritaglio. |
| `art/WB-075/stendardo_1.png` e `stendardo_1.txt` | 3 | 3 | Incavo XP e coda di rondine visibili. La moneta è già nell'incavo e manca come pezzo separato. Bordo centrale con lievi variazioni. |
| `art/WB-075/stendardo_2.png` e `stendardo_2.txt` | 3 | 2 | Incavo XP e coda di rondine visibili. La moneta è già nell'incavo e manca come pezzo separato. Bordo centrale con lievi variazioni. |

Verificati i contorni scuri, i dischi del ritratto vuoti e l'assenza di scritte, numeri e volti. Nelle due varianti dello stendardo tutti e tre i tentativi hanno rappresentato la moneta nell'incavo. Ritaglio, allungamento nel gioco e composizione delle quattro anteprime da verificare.

## Resoconto di Claude

- 18 nov: Sergio sceglie lo stendardo D1 («facciamo la d1, ma con il numero del livello centrato»; della punta della barra: «o metti bene la capocchia, oppure lasci senza, non ne capisco il senso»). Nel gioco `stendardo_1` intero (`stendardo`, 805×224, a schermo alto 112) e il riempimento dritto di `barra_2` senza la punta (`barra_stendardo`, capi corti, così con poca esperienza resta corta): li taglia `fai_stendardo` in `tools/grafica/fucina.py`. `client/menu/home.lua` mette faccia, nome, barra e numero nei punti misurati sul disegno (`BANNER`); il numero è al centro della moneta, avorio con il contorno d'inchiostro. Tolti dalla home guscio, tondo, riga scura e barra di brace (restano dove li usano altre schermate). Non usati: `anello`, `piastra`, `tizzone`, `barra_1`, `stendardo_2` (restano nel ramo). Simulazione OK (scenario `riquadro_profilo.txt`), `tutti.sh` OK. Foto: `docs/handoff/img/WB-075_bozza_e_gioco.jpg` (livello 50 e barra al 42% messi a mano solo per la foto).

