# WB-097 · La Fornace diventa il Banco degli Usurai: sfondo, usurai con le borse, argine, bancone del bottino

- **Stato:** APPROVATA (Claude, 26 nov: Sergio ha scelto l'ambientazione A «Il Banco degli Usurai» e il bottino «Il bancone che si piega»; pezzi nuovi, quelli di WB-092 restano nel repository finché questi non sono nel gioco)
- **Data:** 2026-11-26
- **Ramo della scheda:** `claude/project-thread-oh0dd6` (Codex la esegue da qui: `git fetch origin claude/project-thread-oh0dd6`, non serve che sia su `main`) · **Ramo delle immagini:** `design/WB-097`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-097` senza chiedere conferma (il repository è privato).

## Obiettivo

La Fornace ([docs/commesse.md](../commesse.md), sezione «La Fornace») cambia ambientazione, con le stesse regole (Sergio, 26 nov, scelte su https://claude.ai/artifact/7sCdLDNgtHNcUtSEG6aXyK e https://claude.ai/artifact/GVsg8dBpjKahkBfL7eQJbJ). Siamo nel **Sabbione** del settimo girone, sotto la pioggia di fuoco di Dante (Inf. XIV), fra gli **usurai** seduti sulla sabbia con la borsa al collo e lo stemma della famiglia (Inf. XVII). L'apprendista ci va a cambiare l'Ossidiana: la goccia fusa che cade in una borsa la paga l'usuraio.

- **Gli stampi diventano usurai con la borsa aperta verso il cielo.** Lo stemma sulla borsa ha il colore della famiglia (ferro per le Scaglie). Quelli alti stanno in cima a pinnacoli di roccia sottili, al posto delle catene.
- **Il secchio sparisce.** La goccia che manca le borse cade nella sabbia e diventa una perla di **vetro**, che finisce nel vaso a destra del bancone (vale 30, come oggi).
- **La sponda** a destra è una parete di roccia, e dietro cade il Flegetonte rosso.
- **Il pavimento è l'argine di pietra del fiume.** La faccia dell'argine è la fascia bassa: lì sta il **bancone del cambiavalute**, dove si ammucchia il bottino di tutto il muro e che si piega sempre di più. Al jackpot si spezza: **BANCAROTTA**.

**Gli usurai parlano** (Sergio, 26 nov): ogni tanto una battuta sopra la testa, come i bot in battaglia (quando li prendi, quando sbagli di poco, qualche volta mentre miri); per questo il foglio degli usurai pieni ha la bocca spalancata.

Le bozze R1, R2 e R3 sono mie e dicono solo DOVE stanno le cose e cosa sono, non come vanno disegnate.

Misure nel gioco (schermo 1280×720): un usuraio grande con la borsa è alto circa 90 px, uno piccolo circa 60 px; la faccia dell'argine è alta 120 px; il bancone è largo circa 1.050 px e alto 12 px; un mucchio grande di monete è largo circa 260 px. Codex disegna **almeno al doppio** (un usuraio grande è alto almeno 300 px nel foglio).

Regole degli sfondi (come WB-092): **nessun contorno nero** nei quattro piani, forme grandi e piatte, pochi dettagli, colori scuri e poco saturi, fuoco caldo in basso a sinistra e un filo di gelo in alto a destra, il centro calmo (lì volano la goccia e i puntini). Gli oggetti del gioco (usurai, argine, bancone, mucchi, vaso) hanno invece il contorno a china.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-097/riferimenti/R1_bozza_usurai.png` | la bozza della scena: l'apprendista a sinistra, gli usurai con le borse sulle dune e sui pinnacoli, la pioggia di fuoco, la parete col fiume a destra, l'argine in basso |
| R2 | `art/WB-097/riferimenti/R2_bozza_bancone.png` | la stessa scena col bancone del bottino nell'argine, a metà muro |
| R3 | `art/WB-097/riferimenti/R3_bozza_bancarotta.png` | il jackpot in tre tempi: il bancone piegato e crepato, l'asse spezzata col bottino che crolla, il banco nuovo |
| R4 | `client/paintings/backgrounds/forgia_medio_2.png` | un piano di sfondo di una mappa: la mano e i toni degli sfondi (niente contorno nero, forme grandi, pochi dettagli) |
| R5 | `art/WB-087/malacoda_2.png` | un personaggio del gioco: lo STILE dei personaggi (contorno di china, colori piatti, un'ombra e una luce piatte, cartone a fumetti) |
| R6 | `art/WB-084/frammenti_1.png` | i frammenti delle cinque famiglie: lo stile degli oggetti piccoli e i colori delle famiglie |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto: il primo è "image 1", il secondo "image 2", e così via.

| Nome file | Cosa c'è | Riferimenti | Misura | Varianti |
|---|---|---|---|---|
| `sabbione_cielo` | il cielo rosso del Sabbione con la pioggia di fuoco lontana | R1, R4 | 1536×1024 | 2 |
| `sabbione_lontano` | dune lontane e la cascata del Flegetonte | R1, R4 | 1536×1024 | 2 |
| `sabbione_medio` | rocce sui due lati, i fianchi della scena | R1, R4 | 1536×1024 | 2 |
| `sabbione_vicino` | dune vicine in basso e qualche falda di fuoco | R1, R4 | 1536×1024 | 2 |
| `usurai_vuoti` | sei usurai con la borsa aperta e vuota | R1, R5, R6 | 1536×1024 | 2 |
| `usurai_pieni` | gli stessi sei usurai con la borsa piena e la bocca aperta | R1, R5, R6 | 1536×1024 | 2 |
| `argine_e_pinnacolo` | la sporgenza, l'argine che si ripete, il pinnacolo che si ripete, la parete della sponda | R1, R5 | 1536×1024 | 2 |
| `bancone` | il bancone in pezzi, i cavalletti, l'asse spezzata, la crepa | R2, R3, R5 | 1536×1024 | 2 |
| `mucchi_e_vetro` | mucchi di monete e di frammenti, la goccia, la perla di vetro, il vaso, le falde di fuoco | R2, R5, R6 | 1536×1024 | 2 |

Le varianti si chiamano `usurai_vuoti_1.png`, `usurai_vuoti_2.png` e così via, in `art/WB-097/`. Per ogni foglio Codex scrive un `.txt` con lo stesso nome: cosa ha fatto e cosa non è riuscito a rispettare.

### `sabbione_cielo`

```
Image 1 is a rough draft of a minigame of our game: a little devil stands on a stone ledge at the bottom left and throws drops of molten metal into the open purses of greedy damned souls sitting on a burning desert of sand under a rain of fire; it only says WHERE things are. Image 2 is one background layer of our game: copy its HAND and its TONES exactly: no black outline at all, big simple flat shapes with soft gradients, very few details, dark and desaturated colors, bright colors only in the lights.

Paint the FARTHEST layer of that place, wide (3:2), filling the whole image edge to edge: the sky above an infernal desert, a deep dark red-brown at the top (#2B0F12) warming down to dusty orange near the bottom (#8C3D1C), lit from the BOTTOM LEFT by a warm orange glow and touched in the TOP RIGHT corner by a thin cold blue-white light. Very far away, small soft flakes of fire fall slowly and straight down like snow without wind, sparse, a little brighter (#E07A3A). The CENTER and the RIGHT half stay calm, because the game draws the targets and the flying drop there. No outlines, no characters, no ground, no letters, no frame.
```

### `sabbione_lontano`

```
Image 1 is a rough draft of a minigame of our game set on a burning desert of sand in hell under a rain of fire. Image 2 is one background layer of our game: copy its HAND and its TONES exactly: no black outline at all, big simple flat shapes with soft gradients, very few details, dark and desaturated colors.

Paint the FAR layer of that desert, wide (3:2), on plain green (#00FF00) above the shapes so it can be cut out: along the BOTTOM third, long low soft dunes of dark sand seen far away (#6E2E18 to #8C3D1C), a few tiny dark seated silhouettes of damned souls scattered on them, and on the far RIGHT a thin tall waterfall of a boiling red river (#B8321E with a brighter core #E8642A) falling from high cliffs that fade into the haze. The dunes are a little higher on the LEFT. Nothing in the top half except the green, apart from the waterfall on the right. No outlines, no letters, no frame.
```

### `sabbione_medio`

```
Image 1 is a rough draft of a minigame of our game set on a burning desert of sand in hell under a rain of fire. Image 2 is one background layer of our game: copy its HAND and its TONES exactly: no black outline at all, big simple flat shapes with soft gradients, few details, dark and desaturated colors.

Paint the MIDDLE layer of that desert, wide (3:2), on plain green (#00FF00) so it can be cut out: on the far LEFT a tall broken rock spire of dark red stone (#5A2A1C to #7C3A22) with the warm orange glow of the fire on its edge; on the far RIGHT the edge of a tall dark cliff with a red stream of boiling water running down it. A few dead branches of burnt shrubs at the bottom corners. The whole middle of the image, from left to right and from top to bottom, stays EMPTY green: the targets and the flight of the drop go there. No outlines, no characters, no letters.
```

### `sabbione_vicino`

```
Image 2 is one background layer of our game: copy its HAND exactly: no black outline at all, big simple flat shapes, very few details.

Paint the NEAREST layer of an infernal desert of burning sand, wide (3:2), on plain green (#00FF00) so it can be cut out: only near, dark, slightly blurred shapes along the BOTTOM edge and in the two bottom corners: the crest of a dune of dark orange sand (#7A3A1C), a half-buried broken coin chest on the left, a few scorched stones on the right, a thin rim of orange light on their edges, and four or five big blurred flakes of fire falling in front. They take at most the bottom fifth of the image, apart from the flakes. Everything else is green. No outlines, no characters, no letters.
```

### `usurai_vuoti`

```
Image 1 is a rough draft of a minigame of our cartoon game: a little devil throws drops of molten obsidian into the OPEN PURSES of greedy damned souls (usurers) sitting on a burning desert of sand; the usurers in the draft are placeholders. Image 2 shows the STYLE of our characters: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, hand-drawn like a cartoon comic, funny and expressive. Image 3 shows small objects in that style and the five family colors: gold, ice blue, fire orange, sea green, violet.

Draw SIX separate usurers on plain green (#00FF00), in two rows of three, well apart, each one whole and not touching the others. Each usurer is a skinny, hunched, greedy damned soul with grey-green skin (#8D8F86), sunken cheeks, big greedy yellow eyes fixed on the purse, a long nose, wrapped in a ragged hooded cloak; he SITS on a small mound of sand and holds up with both bony hands, in front of his chest, a big leather purse hanging from his neck on a cord. The purse is OPEN TOWARDS THE SKY: we see its round mouth from a little above, a dark EMPTY hollow, with a drawstring around it. On the front of each purse there is a small flat shield-shaped coat of arms, EMPTY and of one plain color, where the game will put an icon: from left to right, top row then bottom row, the shield is gold (#FFB703), ice blue (#8FD8F5), fire orange (#F26419), sea green (#5CDBB8), violet (#C49CFF), and plain iron grey (#8A8F98). The cloaks are all different dull colors (dark violet, dark slate blue, dark wine, dark olive, dark brown, dark grey). Three usurers are big and three are small (about two thirds of the big ones): big, small, big in the top row, small, big, small in the bottom row. Mouths closed, a sly greedy grin.
Nothing else in the image: no icons on the shields, no letters, no numbers, no coins outside the purse, no shadow on the ground, no glow halo.
```

### `usurai_pieni`

```
Image 1 is a rough draft of a minigame of our cartoon game: a little devil throws drops of molten obsidian into the open purses of greedy damned souls (usurers) sitting on a burning desert of sand. Image 2 shows the STYLE of our characters: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, hand-drawn like a cartoon comic, funny and expressive. Image 3 shows small objects in that style and the five family colors.

Draw the SAME SIX usurers as the previous sheet, in the same order, same size, same cloaks and same shield colors (gold, ice blue, fire orange, sea green, violet, iron grey), each one whole and well apart on plain green (#00FF00), in two rows of three. Now the purse is FULL: its mouth is filled to the brim with glowing molten metal, bright orange-yellow (#FFB703 and #FF7A1A) with one flat white-yellow highlight and a thin wisp of steam; the purse is a little swollen. Each usurer has his MOUTH WIDE OPEN as if shouting, eyebrows up, half outraged because the purse burns and half delighted because it is full; his hands still hold the purse.
Nothing else in the image: no icons on the shields, no letters, no numbers, no speech bubbles, no shadow on the ground, no glow halo.
```

### `argine_e_pinnacolo`

```
Image 1 is a rough draft of a minigame of our cartoon game set on a burning desert of sand in hell: a little devil stands on a stone block on the left, the floor is the stone embankment of a boiling river, some targets stand on top of thin rock pinnacles, a rock wall closes the right side. Image 2 shows the STYLE of our game: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, hand-drawn like a cartoon comic.

Draw four separate pieces on plain green (#00FF00), well apart, each whole:
1. THE LEDGE: a sturdy block of big square-cut stones, as wide as it is tall, where the little devil stands to throw, with a FLAT TOP and a thin warm orange rim of light on its left side. Stone #6C5A4E, shadow #3A2D26.
2. THE EMBANKMENT: a long strip of the stone embankment of a river, four times wider than tall: a FLAT TOP edge of dressed stone with a thin layer of orange sand on it, and below it the vertical FACE of the embankment made of big square stone blocks, darker towards the bottom (#6C5A4E to #2E241F). Its left and right ends are cut straight so the game can repeat it side by side seamlessly. The middle of the face is calm: the game puts a counter on it.
3. THE PINNACLE: one straight vertical piece of a thin rock column of dark red stone (#7C3A22, shadow #5C2614), about four times taller than wide, with cracks and ledges, its top and bottom cut flat so the game can stack pieces seamlessly; and next to it a separate TOP for it, a small flat rock platform where a seated figure can sit.
4. THE ROCK WALL: one straight vertical piece of a rough cliff of dark red rock (#5A2A1C), about three times taller than wide, top and bottom cut flat so the game can stack it; its LEFT face is smooth enough to bounce on.
Thick black ink outline on all, flat colors. No characters, no letters, no shadow on the ground, no glow halo.
```

### `bancone`

```
Image 1 is a rough draft of a minigame of our cartoon game: in the stone face of an embankment there is the long wooden counter of a medieval money changer, where the loot of the player piles up and makes the plank bend. Image 2 shows the end of the game: the plank cracks, then snaps in two in the middle and everything falls down ("bankruptcy", the broken bench). Image 3 shows the STYLE of our game: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, hand-drawn like a cartoon comic.

Draw these separate pieces on plain green (#00FF00), well apart, each whole:
1. THE PLANK, in three pieces so the game can build it as long as it wants and bend it: a LEFT END, a MIDDLE piece whose left and right ends are cut straight to repeat seamlessly, and a RIGHT END. A thick old plank of worn brown wood (#7A4B2A, highlight #A5785A, shadow #5A3218), seen from the front and a little from above so the TOP surface is visible, with iron nails and a few coin scratches. The plank is about twenty times longer than thick in total.
2. A TRESTLE: one wooden trestle leg in an A shape seen from the front, to hold the plank.
3. THE BROKEN PLANK: the same plank snapped in two, each half drawn separately, with jagged splintered wood at the broken end.
4. A CRACK: one dark jagged crack with a few small splinters, to put on top of the plank in the middle.
No coins, no characters, no letters, no shadow on the ground, no glow halo.
```

### `mucchi_e_vetro`

```
Image 1 is a rough draft of a minigame of our cartoon game: on the wooden counter of a money changer the player's loot piles up in heaps (one heap of gold coins and one heap of crystal fragments for each family color), and a glass jar holds the glass beads made by missed drops of molten metal that fell in the sand. Image 2 shows the STYLE of our game: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, hand-drawn like a cartoon comic. Image 3 shows the crystal fragments of our game and their style.

Draw these separate objects on plain green (#00FF00), well apart, each whole and with a FLAT BOTTOM edge so they can sit on a plank:
1. THREE HEAPS OF GOLD COINS, small, medium and big (the big one about three times wider than the small one): rounded mounds of flat gold coins (#F4B42A, highlight #FFD36A, rims #8A5A10), a few coins standing on their edge, one or two sliding down the side.
2. THREE HEAPS OF CRYSTAL FRAGMENTS, small, medium and big, all in WHITE and very light grey (#F2F2F2, shadow #C9C9C9) because the game colors them for each family: rounded mounds of small faceted crystals like the ones in image 3.
3. THE DROP: one round drop of molten obsidian, deep violet-black (#2A1438) with a hot glowing core (#FF70D0 and #FF7A1A) seen through cracks, one flat white highlight: round, and stretched in flight pointing right.
4. A GLASS BEAD: one small round bead of clear pale blue glass (#9FE3FF) with a white shine, the drop of metal cooled in the sand; and a small splash of sand and sparks where it lands.
5. THE JAR: a tall clear glass jar with a wooden lid, empty, seen from the front, its glass pale blue and almost transparent with two white shines.
6. THREE FLAKES OF FIRE: soft falling flame flakes, orange-yellow, like burning snowflakes, small, medium and big.
No letters, no numbers, no plank, no characters, no shadow on the ground, no glow halo.
```

## Criteri di accettazione

- [ ] sfondo: quattro piani dello stesso Sabbione, senza contorno nero, scuri, fuoco in basso a sinistra e gelo in alto a destra, il centro vuoto e calmo; lontano, medio e vicino si ritagliano dal verde
- [ ] usurai: sei usurai separati, stessi sei fra il foglio vuoto e quello pieno (stesso ordine, misura, mantello, colore dello stemma)
- [ ] usurai: la bocca della borsa è aperta verso il cielo e si vede da sopra; lo stemma è vuoto e di un colore solo
- [ ] usurai pieni: bocca dell'usuraio spalancata, metallo fuso fino all'orlo, niente fumetti
- [ ] un usuraio grande è alto almeno 300 px nel foglio
- [ ] argine, pinnacolo, parete e pezzo di mezzo del bancone si ripetono senza cuciture
- [ ] mucchi di frammenti bianchi (il gioco li colora), mucchi di monete in tre misure, fondo piatto
- [ ] contorno di china e colori piatti come R5 sugli oggetti, nessuna scritta, fondo verde pieno (si ritaglia) senza alone verde

---

## Decisione

Approvata da Claude il 26 nov: Sergio ha scelto l'ambientazione «Il Banco degli Usurai» (https://claude.ai/artifact/7sCdLDNgtHNcUtSEG6aXyK) e il bottino «Il bancone che si piega» (https://claude.ai/artifact/GVsg8dBpjKahkBfL7eQJbJ). Quando questi disegni saranno nel gioco, Claude toglie dal gioco e dall'atlante quelli di WB-092 e WB-095 che non servono più (fucina, stampi, secchio, catena, sponda).

## Consegna di Codex

In `art/WB-097/` sono consegnati i seguenti fogli e un `.txt` omonimo per ciascuno, con prompt originale, riferimenti nell'ordine e note.

- `sabbione_cielo_1.png`, `sabbione_cielo_2.png`, `sabbione_lontano_1.png`, `sabbione_lontano_2.png`, `sabbione_medio_1.png`, `sabbione_medio_2.png`, `sabbione_vicino_1.png`, `sabbione_vicino_2.png` — un tentativo ciascuno.
- `usurai_vuoti_1.png`, `usurai_vuoti_2.png` — un tentativo ciascuno.
- `usurai_pieni_1.png`, `usurai_pieni_2.png` — tre tentativi ciascuno, selezionato il primo.
- `argine_e_pinnacolo_1.png`, `argine_e_pinnacolo_2.png`, `bancone_1.png`, `bancone_2.png` — un tentativo ciascuno.
- `mucchi_e_vetro_1.png`, `mucchi_e_vetro_2.png` — tre tentativi ciascuno, selezionato il secondo.

Tutti i 18 PNG sono da 1536×1024. Per argine, bancone e bottino ho ridimensionato in proporzione e centrato i fogli su verde. Ho controllato visivamente i quattro piani di ciascuna variante, l'area centrale libera, la distribuzione degli oggetti, l'assenza di scritte e il colore degli stemmi. Nei due fogli vuoti gli usurai grandi superano i 300 px. I fogli pieni mantengono i sei colori e il metallo fuso, ma mostrano un personaggio simile a Malacoda, in piedi e di taglia uniforme. Il criterio dello stesso personaggio nelle due pose non è soddisfatto.

In entrambi i fogli del bottino la goccia è presente solo allungata, con coda a destra, e la perla è già dentro lo schizzo di sabbia. La misura e l'ordine dei mucchi sono leggibili. Il verde generato differisce da #00FF00. Non sono state verificate le giunzioni senza cuciture, lo scontorno finale o la resa in gioco.

## Resoconto di Claude

26 nov. Nel gioco sul ramo `claude/project-thread-oh0dd6` (PR #437), tagli e misure in `tools/grafica/fornace.py`.

- **Scelti**: `sabbione_cielo_2` (più fuoco in basso), `sabbione_lontano_1`, `sabbione_medio_1`, `usurai_vuoti_2` (le facce più cattive e le borse più leggibili), `argine_e_pinnacolo_2` (l'argine con la sabbia sopra, la parete senza fiume: il Flegetonte c'è già nel medio), `bancone_1`, `mucchi_e_vetro_2`.
- **Scartati**: `sabbione_vicino_1` e `_2` (il primo piano copriva la fascia bassa del bancone, e la pioggia di fuoco la fa il gioco con le falde di `mucchi_e_vetro`), e **tutti e due gli `usurai_pieni`**: sono un diavolo simile a Malacoda in piedi, non gli usurai del foglio vuoto. Per ora l'usuraio pagato è quello vuoto con la borsa piena della goccia di WB-092 (col premio sopra): funziona, ma la faccia arrabbiata e contenta manca.
- **Ritocchi miei**: il verde dei dipinti lontano e medio aveva una foschia verde sulla rupe: tolto con un'alfa morbida. Il foglio ha tre usurai grandi e tre piccoli ma ogni colore serve in tutte e due le misure: i grandi azzurro, verde e ferro sono i grandi viola, oro e arancio con lo stemma ridipinto (solo lo stemma, a tinta piatta). L'argine e la parete sono tagliati dentro il contorno per ripetersi senza righe; la parete si ripete capovolta un pezzo sì e uno no. La perla di vetro è tagliata fuori dallo schizzo giallo. Le assi spezzate sono più spesse delle intere: si usano solo le punte, alla misura dell'asse.
- **Misure nel gioco**: l'usuraio grande è largo circa 160 unità del mondo (circa 107 px a muro intero su 1280×720, 315 px nei fogli: mai ingranditi fino allo zoom 1,6 dei piccoli, che sono i grandi rimpiccioliti).
- **Fase 2 da fare** (sotto): rifare gli usurai pieni partendo dal foglio vuoto scelto.

## Fase 2 (26 nov): gli usurai pieni, da rifare

- **Stato:** SCARTATA (26 nov, Sergio: gli usurai sul muro fanno troppa confusione; le borse restano da sole, appese alle corde: vedi WB-098). Codex non la esegue.
- **Ramo delle immagini:** `design/WB-097` (stessa cartella `art/WB-097/`, nomi nuovi: non sovrascrive niente)

| Nome file | Cosa c'è | Riferimenti | Misura | Varianti |
|---|---|---|---|---|
| `usurai_pieni_bis` | gli stessi sei usurai di `usurai_vuoti_2` con la borsa piena e la bocca aperta | `art/WB-097/usurai_vuoti_2.png`, R5 | 1536×1024 | 2 |

### `usurai_pieni_bis`

```
Image 1 is a sheet of six usurers from our cartoon game: greedy damned souls in ragged hooded cloaks, sitting on a little mound of sand, holding up an open leather purse with a coat of arms on it. Image 2 shows the STYLE of our characters: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, hand-drawn like a cartoon comic.

Redraw EXACTLY THE SAME SIX USURERS OF IMAGE 1, each one in the same place of the sheet, at the same size, with the same pose, the same cloak color, the same skin, the same face, the same purse and the same shield color: copy them, do not invent new characters. Change only two things. First: the purse is now FULL, its open mouth filled to the brim with glowing molten metal, deep violet-black obsidian with bright orange-red cracks (like a ball of molten lava), with one flat white highlight; the purse is a little swollen. Second: each usurer has his MOUTH WIDE OPEN as if shouting, eyebrows up, half outraged because the purse burns and half delighted because it is full; his eyes still on the purse, his hands still on the purse. Plain green background (#00FF00), the six usurers well apart and whole, not touching.
Nothing else in the image: no icons on the shields, no letters, no numbers, no speech bubbles, no smoke clouds, no shadow on the ground, no glow halo.
```

Criteri: sono i sei usurai di image 1 (stessi mantelli e stemmi, stesso posto e misura), bocca spalancata, borsa piena di Ossidiana fusa viola e arancio (come la goccia del gioco), niente scritte, verde pieno.
