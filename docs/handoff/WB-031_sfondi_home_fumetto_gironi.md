# WB-031 · Sfondi della home a fumetto per tutti i gironi

- **Stato:** IMPLEMENTATA (nel gioco con la PR dello sfondo del posto raggiunto) · prima APPROVATA (Sergio, 2026-11-13: «molto fighe, facciamole tutte con la prima versione»)
- **Data:** 2026-11-13
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-031`

## Obiettivo

La home mostra dietro al diavoletto il girone a cui è arrivato il giocatore (finita la campagna, sceglierà
lui). Sergio ha scelto lo stile **fumetto** di WB-030 (`sfondo_home_limbo_fumetto`, `sfondo_home_gola_fumetto`):
qui gli altri nove posti della campagna, nello stesso stile. Limbo e Gola ci sono già (WB-030).

Nota di Claude: sul telefono la home taglia circa il 10% per lato (e un po' sopra), e in WB-030 le statue di
Gola si vedevano a metà. Le masse principali vanno quindi **più verso il centro**, tra il 10% e il 40% della
larghezza da ogni bordo.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-031/riferimenti/R1_limbo_fumetto.jpg` | Limbo a fumetto, approvato: lo stile da copiare |
| R2 | `art/WB-031/riferimenti/R2_gola_fumetto.jpg` | Gola a fumetto, approvato: lo stile da copiare |
| R3 | `art/WB-031/riferimenti/R3_limbo_nella_home.jpg` | Limbo nella home con l'interfaccia sopra: quanto resta calmo il centro e quanto si taglia ai lati. **L'interfaccia non va ridisegnata** |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega R1, R2 e R3 in quest'ordine ("image 1", "image 2",
"image 3"). Formato 16:9, 1672×941 come WB-030 (o più grande, stessa forma), una variante.

| Nome file | Riferimenti | Posto |
|---|---|---|
| `sfondo_home_cortile` | R1, R2, R3 | cortile |
| `sfondo_home_forgia` | R1, R2, R3 | forgia |
| `sfondo_home_lussuria` | R1, R2, R3 | lussuria |
| `sfondo_home_avarizia` | R1, R2, R3 | avarizia |
| `sfondo_home_ira` | R1, R2, R3 | ira |
| `sfondo_home_eresia` | R1, R2, R3 | eresia |
| `sfondo_home_violenza` | R1, R2, R3 | violenza |
| `sfondo_home_frode` | R1, R2, R3 | frode |
| `sfondo_home_tradimento` | R1, R2, R3 | tradimento |

### `sfondo_home_cortile`

```
Images 1 and 2 are two APPROVED backgrounds for the home screen of a mobile game about little devils in Dante's hell (circle of Limbo and circle of Gluttony). Image 3 shows image 1 in use, with the game's comic-style interface on top (do not draw the interface). Paint a NEW background of exactly the same series, same style and same hand as images 1 and 2: flat comic-book illustration, thick near-black ink outlines, flat fills with at most 3 tones per shape, hard-edged shadow shapes, a banded sky with soft hard-edged light beams, a flat dark floor band with a thick ink line on top. Wide 16:9.

The place: THE COURTYARD (Antinferno, the training yard of the little devils' school): a sooty stone courtyard at the gates of hell, old walls and arches, wooden training posts and straw targets at the sides, a big gate in the distance, hanging lanterns. Palette: warm grey stone, ochre, brown, dull orange lantern light.

Composition rules, follow exactly: the whole CENTRE of the picture is empty and calm, with nothing in it that attracts the eye (a devil character stands there and four buttons sit at its sides). The big masses of the place (buildings, rocks, statues, trees) stand at the left and right sides and frame the centre, like in images 1 and 2. IMPORTANT: the phone crops about 10% from each side and a little from the top, so the main masses and every recognizable shape must sit between 10% and 40% of the width from each edge, NOT against the edges: the outer 10% on each side only continues the masses, nothing important there. The horizon floor line is at 86% of the height from the top; below it only a plain dark floor band. Keep contrast moderate so light text stays readable on top. No characters, no creatures that look alive, no text, no letters, no numbers, no interface, no frame, no signature.
```

### `sfondo_home_forgia`

```
Images 1 and 2 are two APPROVED backgrounds for the home screen of a mobile game about little devils in Dante's hell (circle of Limbo and circle of Gluttony). Image 3 shows image 1 in use, with the game's comic-style interface on top (do not draw the interface). Paint a NEW background of exactly the same series, same style and same hand as images 1 and 2: flat comic-book illustration, thick near-black ink outlines, flat fills with at most 3 tones per shape, hard-edged shadow shapes, a banded sky with soft hard-edged light beams, a flat dark floor band with a thick ink line on top. Wide 16:9.

The place: THE FORGE (home of the little devils): a huge underground forge of the titans, giant anvils, chimneys and chains, rivers of molten metal glowing at the sides, iron beams and hanging cauldrons. Palette: deep brown-black #2a1410, rust #5a2a1a, molten orange #ff7a1a, warm gold #ffd27a.

Composition rules, follow exactly: the whole CENTRE of the picture is empty and calm, with nothing in it that attracts the eye (a devil character stands there and four buttons sit at its sides). The big masses of the place (buildings, rocks, statues, trees) stand at the left and right sides and frame the centre, like in images 1 and 2. IMPORTANT: the phone crops about 10% from each side and a little from the top, so the main masses and every recognizable shape must sit between 10% and 40% of the width from each edge, NOT against the edges: the outer 10% on each side only continues the masses, nothing important there. The horizon floor line is at 86% of the height from the top; below it only a plain dark floor band. Keep contrast moderate so light text stays readable on top. No characters, no creatures that look alive, no text, no letters, no numbers, no interface, no frame, no signature.
```

### `sfondo_home_lussuria`

```
Images 1 and 2 are two APPROVED backgrounds for the home screen of a mobile game about little devils in Dante's hell (circle of Limbo and circle of Gluttony). Image 3 shows image 1 in use, with the game's comic-style interface on top (do not draw the interface). Paint a NEW background of exactly the same series, same style and same hand as images 1 and 2: flat comic-book illustration, thick near-black ink outlines, flat fills with at most 3 tones per shape, hard-edged shadow shapes, a banded sky with soft hard-edged light beams, a flat dark floor band with a thick ink line on top. Wide 16:9.

The place: LUSSURIA, the second circle, the storm: broken zig-zag cliffs on both sides with indestructible steel spikes sticking out of the rock, purple storm clouds swirling, bolts of lightning, wind streaks. Palette: dark violet #1b1229, plum #4b2d6b, magenta glow #e05fa8, pale lilac #c9b8ff.

Composition rules, follow exactly: the whole CENTRE of the picture is empty and calm, with nothing in it that attracts the eye (a devil character stands there and four buttons sit at its sides). The big masses of the place (buildings, rocks, statues, trees) stand at the left and right sides and frame the centre, like in images 1 and 2. IMPORTANT: the phone crops about 10% from each side and a little from the top, so the main masses and every recognizable shape must sit between 10% and 40% of the width from each edge, NOT against the edges: the outer 10% on each side only continues the masses, nothing important there. The horizon floor line is at 86% of the height from the top; below it only a plain dark floor band. Keep contrast moderate so light text stays readable on top. No characters, no creatures that look alive, no text, no letters, no numbers, no interface, no frame, no signature.
```

### `sfondo_home_avarizia`

```
Images 1 and 2 are two APPROVED backgrounds for the home screen of a mobile game about little devils in Dante's hell (circle of Limbo and circle of Gluttony). Image 3 shows image 1 in use, with the game's comic-style interface on top (do not draw the interface). Paint a NEW background of exactly the same series, same style and same hand as images 1 and 2: flat comic-book illustration, thick near-black ink outlines, flat fills with at most 3 tones per shape, hard-edged shadow shapes, a banded sky with soft hard-edged light beams, a flat dark floor band with a thick ink line on top. Wide 16:9.

The place: AVARIZIA, the fourth circle, the boulders: a V-shaped valley with two long slopes, huge round boulders resting on the tops at both sides, gold coins scattered and piled on the slopes, a big throne of gold far away barely visible. Palette: dark brown #22180c, earth #6e4a22, gold #e8b84a, old bronze #a7782d.

Composition rules, follow exactly: the whole CENTRE of the picture is empty and calm, with nothing in it that attracts the eye (a devil character stands there and four buttons sit at its sides). The big masses of the place (buildings, rocks, statues, trees) stand at the left and right sides and frame the centre, like in images 1 and 2. IMPORTANT: the phone crops about 10% from each side and a little from the top, so the main masses and every recognizable shape must sit between 10% and 40% of the width from each edge, NOT against the edges: the outer 10% on each side only continues the masses, nothing important there. The horizon floor line is at 86% of the height from the top; below it only a plain dark floor band. Keep contrast moderate so light text stays readable on top. No characters, no creatures that look alive, no text, no letters, no numbers, no interface, no frame, no signature.
```

### `sfondo_home_ira`

```
Images 1 and 2 are two APPROVED backgrounds for the home screen of a mobile game about little devils in Dante's hell (circle of Limbo and circle of Gluttony). Image 3 shows image 1 in use, with the game's comic-style interface on top (do not draw the interface). Paint a NEW background of exactly the same series, same style and same hand as images 1 and 2: flat comic-book illustration, thick near-black ink outlines, flat fills with at most 3 tones per shape, hard-edged shadow shapes, a banded sky with soft hard-edged light beams, a flat dark floor band with a thick ink line on top. Wide 16:9.

The place: IRA, the fifth circle, the Styx swamp: little islands in a dark swamp, two tall watch-towers with burning torches at the sides, the red walls of the city of Dis on the horizon, reeds and dead trunks. Palette: black-teal #0d1a1c, swamp green #23484a, muddy cyan #4f8b8a, red of the walls #e0532f.

Composition rules, follow exactly: the whole CENTRE of the picture is empty and calm, with nothing in it that attracts the eye (a devil character stands there and four buttons sit at its sides). The big masses of the place (buildings, rocks, statues, trees) stand at the left and right sides and frame the centre, like in images 1 and 2. IMPORTANT: the phone crops about 10% from each side and a little from the top, so the main masses and every recognizable shape must sit between 10% and 40% of the width from each edge, NOT against the edges: the outer 10% on each side only continues the masses, nothing important there. The horizon floor line is at 86% of the height from the top; below it only a plain dark floor band. Keep contrast moderate so light text stays readable on top. No characters, no creatures that look alive, no text, no letters, no numbers, no interface, no frame, no signature.
```

### `sfondo_home_eresia`

```
Images 1 and 2 are two APPROVED backgrounds for the home screen of a mobile game about little devils in Dante's hell (circle of Limbo and circle of Gluttony). Image 3 shows image 1 in use, with the game's comic-style interface on top (do not draw the interface). Paint a NEW background of exactly the same series, same style and same hand as images 1 and 2: flat comic-book illustration, thick near-black ink outlines, flat fills with at most 3 tones per shape, hard-edged shadow shapes, a banded sky with soft hard-edged light beams, a flat dark floor band with a thick ink line on top. Wide 16:9.

The place: ERESIA, the sixth circle, the city of Dis: inside the iron walls, rows of open stone tombs with flames coming out, tall iron towers with rivets, a red-hot iron gate glowing in the distance. Palette: near black #170b09, dark red-brown #3b1712, flame orange #ff5a1f, yellow fire #ffcc33.

Composition rules, follow exactly: the whole CENTRE of the picture is empty and calm, with nothing in it that attracts the eye (a devil character stands there and four buttons sit at its sides). The big masses of the place (buildings, rocks, statues, trees) stand at the left and right sides and frame the centre, like in images 1 and 2. IMPORTANT: the phone crops about 10% from each side and a little from the top, so the main masses and every recognizable shape must sit between 10% and 40% of the width from each edge, NOT against the edges: the outer 10% on each side only continues the masses, nothing important there. The horizon floor line is at 86% of the height from the top; below it only a plain dark floor band. Keep contrast moderate so light text stays readable on top. No characters, no creatures that look alive, no text, no letters, no numbers, no interface, no frame, no signature.
```

### `sfondo_home_violenza`

```
Images 1 and 2 are two APPROVED backgrounds for the home screen of a mobile game about little devils in Dante's hell (circle of Limbo and circle of Gluttony). Image 3 shows image 1 in use, with the game's comic-style interface on top (do not draw the interface). Paint a NEW background of exactly the same series, same style and same hand as images 1 and 2: flat comic-book illustration, thick near-black ink outlines, flat fills with at most 3 tones per shape, hard-edged shadow shapes, a banded sky with soft hard-edged light beams, a flat dark floor band with a thick ink line on top. Wide 16:9.

The place: VIOLENZA, the seventh circle: on one side a river of boiling red blood and a forest of dry twisted dead trees with broken branches, on the other side a flat desert under a rain of small fire flakes. Palette: black-red #1a090c, blood red #8e1b22, ash grey-violet #6b6274, sand orange #f2a65a.

Composition rules, follow exactly: the whole CENTRE of the picture is empty and calm, with nothing in it that attracts the eye (a devil character stands there and four buttons sit at its sides). The big masses of the place (buildings, rocks, statues, trees) stand at the left and right sides and frame the centre, like in images 1 and 2. IMPORTANT: the phone crops about 10% from each side and a little from the top, so the main masses and every recognizable shape must sit between 10% and 40% of the width from each edge, NOT against the edges: the outer 10% on each side only continues the masses, nothing important there. The horizon floor line is at 86% of the height from the top; below it only a plain dark floor band. Keep contrast moderate so light text stays readable on top. No characters, no creatures that look alive, no text, no letters, no numbers, no interface, no frame, no signature.
```

### `sfondo_home_frode`

```
Images 1 and 2 are two APPROVED backgrounds for the home screen of a mobile game about little devils in Dante's hell (circle of Limbo and circle of Gluttony). Image 3 shows image 1 in use, with the game's comic-style interface on top (do not draw the interface). Paint a NEW background of exactly the same series, same style and same hand as images 1 and 2: flat comic-book illustration, thick near-black ink outlines, flat fills with at most 3 tones per shape, hard-edged shadow shapes, a banded sky with soft hard-edged light beams, a flat dark floor band with a thick ink line on top. Wide 16:9.

The place: FRODE, the eighth circle, the Malebolge: deep stone ditches in terraces with big stone arch bridges over them, some bridges cracked and broken, black pitch boiling at the bottom, big horned devils' silhouettes carved in the rock. Palette: black #101112, grey stone #3a3d40, sick green #9fbf3f, orange glow #ff8a2a.

Composition rules, follow exactly: the whole CENTRE of the picture is empty and calm, with nothing in it that attracts the eye (a devil character stands there and four buttons sit at its sides). The big masses of the place (buildings, rocks, statues, trees) stand at the left and right sides and frame the centre, like in images 1 and 2. IMPORTANT: the phone crops about 10% from each side and a little from the top, so the main masses and every recognizable shape must sit between 10% and 40% of the width from each edge, NOT against the edges: the outer 10% on each side only continues the masses, nothing important there. The horizon floor line is at 86% of the height from the top; below it only a plain dark floor band. Keep contrast moderate so light text stays readable on top. No characters, no creatures that look alive, no text, no letters, no numbers, no interface, no frame, no signature.
```

### `sfondo_home_tradimento`

```
Images 1 and 2 are two APPROVED backgrounds for the home screen of a mobile game about little devils in Dante's hell (circle of Limbo and circle of Gluttony). Image 3 shows image 1 in use, with the game's comic-style interface on top (do not draw the interface). Paint a NEW background of exactly the same series, same style and same hand as images 1 and 2: flat comic-book illustration, thick near-black ink outlines, flat fills with at most 3 tones per shape, hard-edged shadow shapes, a banded sky with soft hard-edged light beams, a flat dark floor band with a thick ink line on top. Wide 16:9.

The place: TRADIMENTO, the ninth circle, the frozen lake of Cocytus: wide flat slabs of cracked ice, big ice shards and frozen pillars at the sides, faint faces of souls under the ice surface (decoration only), a dark well in the far distance. Palette: deep navy #0a1424, ice blue #1f4e79, pale ice #bfe9ff, a tiny accent of red #d4202a.

Composition rules, follow exactly: the whole CENTRE of the picture is empty and calm, with nothing in it that attracts the eye (a devil character stands there and four buttons sit at its sides). The big masses of the place (buildings, rocks, statues, trees) stand at the left and right sides and frame the centre, like in images 1 and 2. IMPORTANT: the phone crops about 10% from each side and a little from the top, so the main masses and every recognizable shape must sit between 10% and 40% of the width from each edge, NOT against the edges: the outer 10% on each side only continues the masses, nothing important there. The horizon floor line is at 86% of the height from the top; below it only a plain dark floor band. Keep contrast moderate so light text stays readable on top. No characters, no creatures that look alive, no text, no letters, no numbers, no interface, no frame, no signature.
```

## Criteri di accettazione

- [ ] stesso stile di R1 e R2: contorno nero spesso, colori piatti, cielo a bande
- [ ] centro vuoto e calmo; masse principali tra il 10% e il 40% della larghezza da ogni bordo
- [ ] orizzonte a circa l'86% dell'altezza, sotto solo una fascia piatta scura
- [ ] i colori del girone (quelli del prompt)
- [ ] nessun testo, personaggio vivo, cornice o interfaccia

---

## Decisione

Approvata da Sergio il 2026-11-13 (stile fumetto di WB-030 per tutti i gironi).

## Consegna di Codex

### 2026-11-13

Nove sfondi PNG RGB da 1672 × 941 px, generati con imagegen da `main`
aggiornato (`5696ce47`). Ogni tentativo ha usato il prompt integrale
e R1, R2, R3 nell'ordine indicato. In `art/WB-031/` ogni PNG è
affiancato da un TXT omonimo con il prompt e i riferimenti.

| File | Tentativi | Tentativo consegnato |
|---|---:|---:|
| `sfondo_home_cortile` | 3 | 2 |
| `sfondo_home_forgia` | 3 | 3 |
| `sfondo_home_lussuria` | 3 | 1 |
| `sfondo_home_avarizia` | 3 | 3 |
| `sfondo_home_ira` | 3 | 3 |
| `sfondo_home_eresia` | 3 | 2 |
| `sfondo_home_violenza` | 3 | 2 |
| `sfondo_home_frode` | 3 | 2 |
| `sfondo_home_tradimento` | 3 | 1 |

Ho verificato contorni scuri, campiture, cieli a bande, palette
distinguibili, fascia scura con linea vicina all'86% dell'altezza e
assenza di scritte, personaggi vivi, cornici e interfaccia.

Ho confrontato le prove anche con un ritaglio di simulazione del 10%
per lato e del 3% in alto. La scena resta riconoscibile in ogni
sfondo, ma la fascia laterale richiesta è rispettata solo in parte.
Il ritaglio intacca soprattutto i massi di Avarizia, i rilievi di
Frode, le torri di Ira ed Eresia e gli alberi di Violenza. Nel
Cortile il portone e in Eresia il cancello illuminato si leggono
ancora al centro, come elementi lontani. Anche il trono di Avarizia
e il pozzo di Tradimento restano visibili in lontananza.

La resa con l'interfaccia sovrapposta e il ritaglio effettivo del
telefono restano da verificare nel gioco.


## Resoconto di Claude

Tutte e nove buone, nessuna scartata (Claude, 13 nov). Nel gioco come `client/paintings/backdrops/<posto>.jpg`
(`tools/grafica/fucina.py`, con Limbo e Gola a fumetto di WB-030), dietro a ogni schermata secondo il posto
raggiunto (`kit.reached`). Verificato: `simula.py` con ogni posto nella home e in ALLENAMENTO (foto
`home_luoghi.jpg` nei file del progetto), `tutti.sh` OK. Non verificato: schermi 20:9 e 4:3.
