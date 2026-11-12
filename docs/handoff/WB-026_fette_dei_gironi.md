# WB-026 · Una fetta per ogni girone

- **Stato:** APPROVATA (Sergio, 2026-11-12: «mancano un po' di fette per la campagna dei gironi? molte hanno perso la loro identità»; e prima: «usa sempre codex per quello che non riesci a fare»)
- **Data:** 2026-11-12
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-026`

## Obiettivo

Con WB-024 la mappa della campagna è diventata un imbuto di fette, ma le fette erano quattro
(calda, pietra, ghiaccio, aperta) e la pagina di prova le ripeteva: sette gironi su nove erano
uguali. Sergio vuole che **ogni girone abbia la sua fetta**, riconoscibile dal colore e da due
o tre segni del suo pericolo (i colori e i pericoli sono quelli di `docs/campagna_gironi.md`).

Ogni fetta si disegna **una volta sola**, nella vista di `fetta_aperta` di WB-024 (R1): il
gioco la mostra grande quando è il girone aperto e più piccola nella pila, la scurisce e ci
mette il lucchetto di ghiaccio quando è chiusa. Il gioco non la deforma mai.

## Cosa teniamo e cosa scartiamo

| Teniamo | Perché |
|---|---|
| Forma, vista e stile di `fetta_aperta` (R1) e dei pezzi di WB-022 (R2, R3) | è lo stile approvato: china, colori pieni, forme morbide e storte |
| Il centro della faccia di sopra pulito | il gioco ci mette il percorso dei livelli e i nomi |
| Pochi segni, sul bordo: due o tre per fetta | «quasi astratto» (Sergio): si deve capire il girone, non raccontarlo |
| I colori di ogni girone | l'identità di ogni girone parte dal colore |
| L'ultima fetta di ghiaccio, spigolosa | il fuoco in alto e il ghiaccio in fondo restano |

| Scartiamo | Perché |
|---|---|
| Personaggi, dannati, custodi, facce, edifici grandi | niente figure; e niente nudi |
| Texture, sfumature morbide, bagliori, 3D | stile di WB-020, scartato |
| Scritte, numeri, lucchetti, segnalini, percorsi | li mette il gioco |
| Segni in mezzo alla faccia di sopra | lì scrive il gioco |

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-026/riferimenti/R1_fetta_aperta.png` | la fetta aperta di WB-024: forma, vista e stile da copiare |
| R2 | `art/WB-026/riferimenti/R2_piastre.png` | le piastre di WB-022: lo stile |
| R3 | `art/WB-026/riferimenti/R3_lingotto.png` | il lingotto di WB-022: lo stile |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto: il
primo è "image 1", il secondo "image 2", il terzo "image 3". Sfondo verde pieno `#00FF00`.
Tutte le nove fette devono avere la stessa vista e più o meno la stessa grandezza nel foglio.

| Nome file | Girone | Segni | Riferimenti | Formato | Varianti |
|---|---|---|---|---|---|
| `fetta_limbo` | I · Limbo | gravità ridotta, il castello: merli bassi sul bordo dietro, due sassi sospesi | R1, R2, R3 | largo | 1 |
| `fetta_lussuria` | II · Lussuria | la bufera: bordo spazzato dal vento, due o tre riccioli di vento, uno spuntone | R1, R2, R3 | largo | 1 |
| `fetta_gola` | III · Gola | la piova e la grandine: fango che cola dal bordo, tre chicchi di grandine | R1, R2, R3 | largo | 1 |
| `fetta_avarizia` | IV · Avarizia | i massi: due massi tondi sul bordo, una vena d'oro | R1, R2, R3 | largo | 1 |
| `fetta_ira` | V · Ira | la palude che sale: acqua a metà bordo, bolle, una canna rossa | R1, R2, R3 | largo | 1 |
| `fetta_eresia` | VI · Eresia | le arche di Dite: tre tombe aperte con la fiammella sul bordo dietro | R1, R2, R3 | largo | 1 |
| `fetta_violenza` | VII · Violenza | sangue, selva, sabbia: due tronchi secchi a sinistra, sabbia con fiammelle a destra | R1, R2, R3 | largo | 1 |
| `fetta_frode` | VIII · Frode | le Malebolge: due fossi coi ponticelli (uno crepato), pece che cola | R1, R2, R3 | largo | 1 |
| `fetta_tradimento` | IX · Tradimento | il Cocito: ghiaccio spigoloso, crepa, ghiaccioli, un punto rosso intrappolato | R1, R2, R3 | largo | 1 |

### `fetta_limbo`

```
Image 1 is the piece to copy for SHAPE, POINT OF VIEW and STYLE: one big thick slice, like a slab cut from a big round cake, seen from the front and from a bit above, with a large clean oval top face and a thick front edge. Images 2 and 3 show more pieces in the same style: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, like a cartoon.

Draw ONE slice exactly like image 1 (same view, same proportions, about three times wider than tall, hand-drawn, a bit crooked, soft irregular edge), but made of pale castle stone, with its own identity. Colors, flat: top face #55665E, front edge #1D2522 with one darker flat shadow band at the bottom, a thin line of #D9CFA8 where the top face meets the edge. Along the back rim of the top face, three or four low rounded battlement blocks of a small castle wall, simple cubes. Two small pebbles floating just above the left edge, weightless.

Keep it simple and almost abstract: only the few signs described, small, placed on the rim and on the front edge. The middle of the top face stays completely clean and empty, because the game draws a path with markers on it.

Thick black ink outline, cartoon comic style. No characters, no people, no faces, no big buildings. No texture, no soft gradients, no realistic lighting, no glow, no shadow on the ground. No text, letters, numbers or symbols. Flat pure green background (#00FF00), the slice centered with a green margin all around, nothing cut by the border of the picture.
```

### `fetta_lussuria`

```
Image 1 is the piece to copy for SHAPE, POINT OF VIEW and STYLE: one big thick slice, like a slab cut from a big round cake, seen from the front and from a bit above, with a large clean oval top face and a thick front edge. Images 2 and 3 show more pieces in the same style: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, like a cartoon.

Draw ONE slice exactly like image 1 (same view, same proportions, about three times wider than tall, hand-drawn, a bit crooked, soft irregular edge), but made of violet storm rock, with its own identity. Colors, flat: top face #4B2D6B, front edge #1B1229 with one darker flat shadow band at the bottom, a thin line of #E05FA8 where the top face meets the edge. The slice is shaped by wind: the edge is swept to one side, with two or three long soft curled wind streaks (#C9B8FF) leaving the right end, and one steel spike sticking out of the left rim.

Keep it simple and almost abstract: only the few signs described, small, placed on the rim and on the front edge. The middle of the top face stays completely clean and empty, because the game draws a path with markers on it.

Thick black ink outline, cartoon comic style. No characters, no people, no faces, no big buildings. No texture, no soft gradients, no realistic lighting, no glow, no shadow on the ground. No text, letters, numbers or symbols. Flat pure green background (#00FF00), the slice centered with a green margin all around, nothing cut by the border of the picture.
```

### `fetta_gola`

```
Image 1 is the piece to copy for SHAPE, POINT OF VIEW and STYLE: one big thick slice, like a slab cut from a big round cake, seen from the front and from a bit above, with a large clean oval top face and a thick front edge. Images 2 and 3 show more pieces in the same style: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, like a cartoon.

Draw ONE slice exactly like image 1 (same view, same proportions, about three times wider than tall, hand-drawn, a bit crooked, soft irregular edge), but made of muddy olive ground, with its own identity. Colors, flat: top face #4A4931, front edge #1A1D1A with one darker flat shadow band at the bottom, a thin line of #9AA36A where the top face meets the edge. Thick mud drips down the front edge in three or four soft rounded drops, and three big pale hailstones (#D8DDE0) sit half sunk along the left and right rim.

Keep it simple and almost abstract: only the few signs described, small, placed on the rim and on the front edge. The middle of the top face stays completely clean and empty, because the game draws a path with markers on it.

Thick black ink outline, cartoon comic style. No characters, no people, no faces, no big buildings. No texture, no soft gradients, no realistic lighting, no glow, no shadow on the ground. No text, letters, numbers or symbols. Flat pure green background (#00FF00), the slice centered with a green margin all around, nothing cut by the border of the picture.
```

### `fetta_avarizia`

```
Image 1 is the piece to copy for SHAPE, POINT OF VIEW and STYLE: one big thick slice, like a slab cut from a big round cake, seen from the front and from a bit above, with a large clean oval top face and a thick front edge. Images 2 and 3 show more pieces in the same style: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, like a cartoon.

Draw ONE slice exactly like image 1 (same view, same proportions, about three times wider than tall, hand-drawn, a bit crooked, soft irregular edge), but made of brown rock with gold, with its own identity. Colors, flat: top face #6E4A22, front edge #22180C with one darker flat shadow band at the bottom, a thin line of #E8B84A where the top face meets the edge. Two big round boulders rest on the rim, one on the far left and one on the far right, and a thin vein of gold runs across the front edge.

Keep it simple and almost abstract: only the few signs described, small, placed on the rim and on the front edge. The middle of the top face stays completely clean and empty, because the game draws a path with markers on it.

Thick black ink outline, cartoon comic style. No characters, no people, no faces, no big buildings. No texture, no soft gradients, no realistic lighting, no glow, no shadow on the ground. No text, letters, numbers or symbols. Flat pure green background (#00FF00), the slice centered with a green margin all around, nothing cut by the border of the picture.
```

### `fetta_ira`

```
Image 1 is the piece to copy for SHAPE, POINT OF VIEW and STYLE: one big thick slice, like a slab cut from a big round cake, seen from the front and from a bit above, with a large clean oval top face and a thick front edge. Images 2 and 3 show more pieces in the same style: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, like a cartoon.

Draw ONE slice exactly like image 1 (same view, same proportions, about three times wider than tall, hand-drawn, a bit crooked, soft irregular edge), but made of dark teal swamp, with its own identity. Colors, flat: top face #23484A, front edge #0D1A1C with one darker flat shadow band at the bottom, a thin line of #4F8B8A where the top face meets the edge. The front edge is under water up to half its height: a flat teal water line with two or three soft waves crosses it, and three bubbles rise on the right. One small angry red-orange reed (#E0532F) on the left rim.

Keep it simple and almost abstract: only the few signs described, small, placed on the rim and on the front edge. The middle of the top face stays completely clean and empty, because the game draws a path with markers on it.

Thick black ink outline, cartoon comic style. No characters, no people, no faces, no big buildings. No texture, no soft gradients, no realistic lighting, no glow, no shadow on the ground. No text, letters, numbers or symbols. Flat pure green background (#00FF00), the slice centered with a green margin all around, nothing cut by the border of the picture.
```

### `fetta_eresia`

```
Image 1 is the piece to copy for SHAPE, POINT OF VIEW and STYLE: one big thick slice, like a slab cut from a big round cake, seen from the front and from a bit above, with a large clean oval top face and a thick front edge. Images 2 and 3 show more pieces in the same style: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, like a cartoon.

Draw ONE slice exactly like image 1 (same view, same proportions, about three times wider than tall, hand-drawn, a bit crooked, soft irregular edge), but made of burnt red city stone, with its own identity. Colors, flat: top face #3B1712, front edge #170B09 with one darker flat shadow band at the bottom, a thin line of #FF5A1F where the top face meets the edge. Along the back rim, three small open stone tombs like little boxes with their lids ajar, each with a small flat flame (#FFCC33) coming out. A row of four small square notches on the front edge like city wall slits.

Keep it simple and almost abstract: only the few signs described, small, placed on the rim and on the front edge. The middle of the top face stays completely clean and empty, because the game draws a path with markers on it.

Thick black ink outline, cartoon comic style. No characters, no people, no faces, no big buildings. No texture, no soft gradients, no realistic lighting, no glow, no shadow on the ground. No text, letters, numbers or symbols. Flat pure green background (#00FF00), the slice centered with a green margin all around, nothing cut by the border of the picture.
```

### `fetta_violenza`

```
Image 1 is the piece to copy for SHAPE, POINT OF VIEW and STYLE: one big thick slice, like a slab cut from a big round cake, seen from the front and from a bit above, with a large clean oval top face and a thick front edge. Images 2 and 3 show more pieces in the same style: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, like a cartoon.

Draw ONE slice exactly like image 1 (same view, same proportions, about three times wider than tall, hand-drawn, a bit crooked, soft irregular edge), but made of blood red and sand, with its own identity. Colors, flat: top face #8E1B22, front edge #1A090C with one darker flat shadow band at the bottom, a thin line of #F2A65A where the top face meets the edge. The left third of the top face rim is edged with two bare broken dead tree stumps (#6B6274), the right third of the rim is sandy (#F2A65A) with two small flames on it; a thin red stream drips once over the front edge.

Keep it simple and almost abstract: only the few signs described, small, placed on the rim and on the front edge. The middle of the top face stays completely clean and empty, because the game draws a path with markers on it.

Thick black ink outline, cartoon comic style. No characters, no people, no faces, no big buildings. No texture, no soft gradients, no realistic lighting, no glow, no shadow on the ground. No text, letters, numbers or symbols. Flat pure green background (#00FF00), the slice centered with a green margin all around, nothing cut by the border of the picture.
```

### `fetta_frode`

```
Image 1 is the piece to copy for SHAPE, POINT OF VIEW and STYLE: one big thick slice, like a slab cut from a big round cake, seen from the front and from a bit above, with a large clean oval top face and a thick front edge. Images 2 and 3 show more pieces in the same style: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, like a cartoon.

Draw ONE slice exactly like image 1 (same view, same proportions, about three times wider than tall, hand-drawn, a bit crooked, soft irregular edge), but made of grey-black cracked rock, with its own identity. Colors, flat: top face #3A3D40, front edge #101112 with one darker flat shadow band at the bottom, a thin line of #9FBF3F where the top face meets the edge. The slice is cut by two deep narrow ditches that cross the front edge like notches, each bridged by a small stone arch; one arch is cracked in the middle. Sticky black pitch with a sickly green shine (#9FBF3F) drips from one ditch.

Keep it simple and almost abstract: only the few signs described, small, placed on the rim and on the front edge. The middle of the top face stays completely clean and empty, because the game draws a path with markers on it.

Thick black ink outline, cartoon comic style. No characters, no people, no faces, no big buildings. No texture, no soft gradients, no realistic lighting, no glow, no shadow on the ground. No text, letters, numbers or symbols. Flat pure green background (#00FF00), the slice centered with a green margin all around, nothing cut by the border of the picture.
```

### `fetta_tradimento`

```
Image 1 is the piece to copy for SHAPE, POINT OF VIEW and STYLE: one big thick slice, like a slab cut from a big round cake, seen from the front and from a bit above, with a large clean oval top face and a thick front edge. Images 2 and 3 show more pieces in the same style: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, like a cartoon.

Draw ONE slice exactly like image 1 (same view, same proportions, about three times wider than tall, hand-drawn, a bit crooked, soft irregular edge), but made of ice of a frozen lake, with its own identity. Colors, flat: top face #1F4E79, front edge #0A1424 with one darker flat shadow band at the bottom, a thin line of #BFE9FF where the top face meets the edge. This slice is ICE, angular: the outline is made of straight segments and hard corners instead of soft curves. One long crack across the front edge, four short icicles hanging under it, a pale frost line on the rim. One single tiny red spot (#D4202A) frozen inside the front edge, like something trapped in the ice.

Keep it simple and almost abstract: only the few signs described, small, placed on the rim and on the front edge. The middle of the top face stays completely clean and empty, because the game draws a path with markers on it.

Thick black ink outline, cartoon comic style. No characters, no people, no faces, no big buildings. No texture, no soft gradients, no realistic lighting, no glow, no shadow on the ground. No text, letters, numbers or symbols. Flat pure green background (#00FF00), the slice centered with a green margin all around, nothing cut by the border of the picture.
```

## Criteri di accettazione

- [ ] nove fette, ognuna diversa dalle altre a colpo d'occhio (colore e segni)
- [ ] stessa vista e stesse proporzioni di R1 per tutte
- [ ] contorno a china e colori pieni come i pezzi di WB-022: niente texture, sfumature morbide o bagliori
- [ ] il centro della faccia di sopra è pulito; i segni stanno sul bordo
- [ ] nessun personaggio, faccia, scritta o numero; sfondo verde pieno senza ombre; niente tagliato dal bordo

## Dopo le immagini (lo fa Claude)

Toglie il verde, mette le nove fette nella mappa della pagina della proposta
(https://claude.ai/artifact/2RBh8w9T56E7P9kFDd4HKA) al posto di quelle ripetute, controlla che
i nomi si leggano e la fa vedere a Sergio. Le quattro fette di WB-024 restano come riserva.

---

## Decisione

Approvata: è reversibile e Sergio ha chiesto le fette mancanti il 12 nov 2026.

## Consegna di Codex

## Resoconto di Claude

Guardate le nove fette (12 nov): tutte buone, ognuna riconoscibile, centro pulito. Nel gioco: atlante `fette` (1340 px di larghezza, 256 colori: 244 KB in tutto), `client/ui/slices.lua`, e la mappa dei gironi di `client/menu/campaign.lua` (la pila che scorre, tutte intere, quella guardata grande).
