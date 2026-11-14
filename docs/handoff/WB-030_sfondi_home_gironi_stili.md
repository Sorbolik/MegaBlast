# WB-030 · Sfondi della home per i gironi: tre stili a fumetto da scegliere

- **Stato:** APPROVATA (Claude, 2026-11-13, immagini di prova reversibili; Sergio ha chiesto di farli fare a Codex, tutti e 3: «così decido»)
- **Data:** 2026-11-13
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-030`

## Obiettivo

Sergio vuole provare come la home mostri il girone a cui è arrivato (Limbo, Gola, ...), ma lo sfondo
dipinto morbido non si lega ai pulsanti col contorno nero da fumetto. Tre stili da confrontare, ciascuno
su **Limbo** e **Gola** (6 immagini), così decide:

1. **Fumetto**: sagome piatte con contorno spesso, colori pieni, come l'interfaccia.
2. **Porta**: un grande portale rotondo a cerchi dietro il diavoletto (aureola), raggi netti, sagome ai lati.
3. **Retino**: puntini da stampa a fumetto, sagome scure con contorno, centro vuoto.

Le bozze R1-R3 le ha fatte Claude al volo con il codice: servono solo per la **composizione**
(orizzonte all'86%, centro vuoto, masse ai lati). Il disegno finale lo fa Codex, molto più curato.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-030/riferimenti/R1_limbo_fumetto_bozza.jpg` | bozza dello stile Fumetto |
| R2 | `art/WB-030/riferimenti/R2_limbo_porta_bozza.jpg` | bozza dello stile Porta |
| R3 | `art/WB-030/riferimenti/R3_limbo_retino_bozza.jpg` | bozza dello stile Retino |
| R4 | `art/WB-030/riferimenti/R4_porta_con_interfaccia.jpg` | la bozza Porta con l'interfaccia vera sopra: quanto deve restare calmo il centro. **L'interfaccia non va ridisegnata** |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega il riferimento indicato (come "image N") e R4 come
"image 4". Formato 16:9, 2560×1440 se possibile (almeno 1672×941), una variante.

| Nome file | Riferimenti | Stile · girone |
|---|---|---|
| `sfondo_home_limbo_fumetto` | R1 + R4 | comic · girone limbo |
| `sfondo_home_limbo_porta` | R2 + R4 | gate · girone limbo |
| `sfondo_home_limbo_retino` | R3 + R4 | halftone · girone limbo |
| `sfondo_home_gola_fumetto` | R1 + R4 | comic · girone gola |
| `sfondo_home_gola_porta` | R2 + R4 | gate · girone gola |
| `sfondo_home_gola_retino` | R3 + R4 | halftone · girone gola |

### `sfondo_home_limbo_fumetto`

```
Image 1 is a rough layout sketch (NOT the final look) of a background for the home screen of a mobile game about little devils in Dante's hell; image 4 shows such a background in use with the game's comic-style interface on top (do not draw the interface). Paint a NEW, polished, finished background for the circle of hell below, wide 16:9, in this style: COMIC (flat shapes with a thick ink outline).

The circle: LIMBO, the first circle: a pale, quiet city of tall gothic spires and thin towers in a sage-green twilight, a few tiny warm lit windows. Palette: sage greens, grey-teal, dark green-black, cream light.

Flat, comic-book illustration, exactly the language of the game's interface (thick near-black ink outlines, flat fills with at most 3 tones per shape, hard-edged shadow shapes, NO gradients except a banded sky). The scene is a layered skyline: three rows of buildings/rocks drawn as flat outlined silhouettes, nearest darkest and tallest at the left and right edges, getting lower and lighter toward the middle where the picture is almost empty. Faint hard-edged beams of light in the sky. A flat dark floor band with a thick ink line on its top edge. Draw it like a polished hand-inked comic background, much more refined than image 1 (image 1 is only a rough layout sketch).

Composition rules, follow exactly: the whole CENTRE of the picture is empty, calm and dark-to-mid in tone, with nothing in it that attracts the eye (a devil character stands there and four buttons sit at its sides). All the interest is in the masses at the left and right edges, which frame the centre. The horizon floor line is at 86% of the height from the top; below it only a plain dark floor band. Keep contrast moderate so light text stays readable on top. No characters, no creatures that look alive, no text, no letters, no numbers, no interface, no frame, no signature.
```

### `sfondo_home_limbo_porta`

```
Image 2 is a rough layout sketch (NOT the final look) of a background for the home screen of a mobile game about little devils in Dante's hell; image 4 shows such a background in use with the game's comic-style interface on top (do not draw the interface). Paint a NEW, polished, finished background for the circle of hell below, wide 16:9, in this style: GATE (a glowing round gate behind the devil).

The circle: LIMBO, the first circle: a pale, quiet city of tall gothic spires and thin towers in a sage-green twilight, a few tiny warm lit windows. Palette: sage greens, grey-teal, dark green-black, cream light.

Flat comic-book illustration in the language of the game's interface (thick near-black ink outlines, flat fills, hard-edged shadows). In the exact middle, partly hidden by the horizon, a huge round gate or portal made of 4-5 concentric flat rings, the inner ones glowing pale, with ink between the rings, like a halo: a character will stand in front of it, so keep it simple, no details inside the rings. Hard-edged wedge rays spread from it into a banded sky. Skylines of outlined silhouettes at the left and right edges frame it, tall at the edges and low near the middle. A flat dark floor band with a thick ink line on top. Make it a polished hand-inked comic background, much more refined than image 2 (image 2 is only a rough layout sketch).

Composition rules, follow exactly: the whole CENTRE of the picture is empty, calm and dark-to-mid in tone, with nothing in it that attracts the eye (a devil character stands there and four buttons sit at its sides). All the interest is in the masses at the left and right edges, which frame the centre. The horizon floor line is at 86% of the height from the top; below it only a plain dark floor band. Keep contrast moderate so light text stays readable on top. No characters, no creatures that look alive, no text, no letters, no numbers, no interface, no frame, no signature.
```

### `sfondo_home_limbo_retino`

```
Image 3 is a rough layout sketch (NOT the final look) of a background for the home screen of a mobile game about little devils in Dante's hell; image 4 shows such a background in use with the game's comic-style interface on top (do not draw the interface). Paint a NEW, polished, finished background for the circle of hell below, wide 16:9, in this style: HALFTONE (comic printing dots).

The circle: LIMBO, the first circle: a pale, quiet city of tall gothic spires and thin towers in a sage-green twilight, a few tiny warm lit windows. Palette: sage greens, grey-teal, dark green-black, cream light.

Comic-book printed look: flat colours with visible halftone (Ben-Day) dots, in 2-3 inks on a dark ground. The sky is made of coarse halftone dots, dense and bright near the left and right edges and near the horizon, thinning to empty dark ground in the middle top. Skylines of flat dark silhouettes with a thick ink outline and a light dot-rim on their edges, tall at the left and right edges and low near the middle. A flat dark floor band with a thick ink line on top. Polished and clean, dots perfectly regular, much more refined than image 3 (image 3 is only a rough layout sketch).

Composition rules, follow exactly: the whole CENTRE of the picture is empty, calm and dark-to-mid in tone, with nothing in it that attracts the eye (a devil character stands there and four buttons sit at its sides). All the interest is in the masses at the left and right edges, which frame the centre. The horizon floor line is at 86% of the height from the top; below it only a plain dark floor band. Keep contrast moderate so light text stays readable on top. No characters, no creatures that look alive, no text, no letters, no numbers, no interface, no frame, no signature.
```

### `sfondo_home_gola_fumetto`

```
Image 1 is a rough layout sketch (NOT the final look) of a background for the home screen of a mobile game about little devils in Dante's hell; image 4 shows such a background in use with the game's comic-style interface on top (do not draw the interface). Paint a NEW, polished, finished background for the circle of hell below, wide 16:9, in this style: COMIC (flat shapes with a thick ink outline).

The circle: GOLA, the third circle: a rain-soaked swamp-cave under a low dark ceiling, big three-headed hound statues of dark stone half sunk in mud, heavy diagonal rain strokes, hanging stalactites. Palette: cold slate blue, bruised violet-grey, dark mud brown, a hint of dull orange from the left.

Flat, comic-book illustration, exactly the language of the game's interface (thick near-black ink outlines, flat fills with at most 3 tones per shape, hard-edged shadow shapes, NO gradients except a banded sky). The scene is a layered skyline: three rows of buildings/rocks drawn as flat outlined silhouettes, nearest darkest and tallest at the left and right edges, getting lower and lighter toward the middle where the picture is almost empty. Faint hard-edged beams of light in the sky. A flat dark floor band with a thick ink line on its top edge. Draw it like a polished hand-inked comic background, much more refined than image 1 (image 1 is only a rough layout sketch).

Composition rules, follow exactly: the whole CENTRE of the picture is empty, calm and dark-to-mid in tone, with nothing in it that attracts the eye (a devil character stands there and four buttons sit at its sides). All the interest is in the masses at the left and right edges, which frame the centre. The horizon floor line is at 86% of the height from the top; below it only a plain dark floor band. Keep contrast moderate so light text stays readable on top. No characters, no creatures that look alive, no text, no letters, no numbers, no interface, no frame, no signature.
```

### `sfondo_home_gola_porta`

```
Image 2 is a rough layout sketch (NOT the final look) of a background for the home screen of a mobile game about little devils in Dante's hell; image 4 shows such a background in use with the game's comic-style interface on top (do not draw the interface). Paint a NEW, polished, finished background for the circle of hell below, wide 16:9, in this style: GATE (a glowing round gate behind the devil).

The circle: GOLA, the third circle: a rain-soaked swamp-cave under a low dark ceiling, big three-headed hound statues of dark stone half sunk in mud, heavy diagonal rain strokes, hanging stalactites. Palette: cold slate blue, bruised violet-grey, dark mud brown, a hint of dull orange from the left.

Flat comic-book illustration in the language of the game's interface (thick near-black ink outlines, flat fills, hard-edged shadows). In the exact middle, partly hidden by the horizon, a huge round gate or portal made of 4-5 concentric flat rings, the inner ones glowing pale, with ink between the rings, like a halo: a character will stand in front of it, so keep it simple, no details inside the rings. Hard-edged wedge rays spread from it into a banded sky. Skylines of outlined silhouettes at the left and right edges frame it, tall at the edges and low near the middle. A flat dark floor band with a thick ink line on top. Make it a polished hand-inked comic background, much more refined than image 2 (image 2 is only a rough layout sketch).

Composition rules, follow exactly: the whole CENTRE of the picture is empty, calm and dark-to-mid in tone, with nothing in it that attracts the eye (a devil character stands there and four buttons sit at its sides). All the interest is in the masses at the left and right edges, which frame the centre. The horizon floor line is at 86% of the height from the top; below it only a plain dark floor band. Keep contrast moderate so light text stays readable on top. No characters, no creatures that look alive, no text, no letters, no numbers, no interface, no frame, no signature.
```

### `sfondo_home_gola_retino`

```
Image 3 is a rough layout sketch (NOT the final look) of a background for the home screen of a mobile game about little devils in Dante's hell; image 4 shows such a background in use with the game's comic-style interface on top (do not draw the interface). Paint a NEW, polished, finished background for the circle of hell below, wide 16:9, in this style: HALFTONE (comic printing dots).

The circle: GOLA, the third circle: a rain-soaked swamp-cave under a low dark ceiling, big three-headed hound statues of dark stone half sunk in mud, heavy diagonal rain strokes, hanging stalactites. Palette: cold slate blue, bruised violet-grey, dark mud brown, a hint of dull orange from the left.

Comic-book printed look: flat colours with visible halftone (Ben-Day) dots, in 2-3 inks on a dark ground. The sky is made of coarse halftone dots, dense and bright near the left and right edges and near the horizon, thinning to empty dark ground in the middle top. Skylines of flat dark silhouettes with a thick ink outline and a light dot-rim on their edges, tall at the left and right edges and low near the middle. A flat dark floor band with a thick ink line on top. Polished and clean, dots perfectly regular, much more refined than image 3 (image 3 is only a rough layout sketch).

Composition rules, follow exactly: the whole CENTRE of the picture is empty, calm and dark-to-mid in tone, with nothing in it that attracts the eye (a devil character stands there and four buttons sit at its sides). All the interest is in the masses at the left and right edges, which frame the centre. The horizon floor line is at 86% of the height from the top; below it only a plain dark floor band. Keep contrast moderate so light text stays readable on top. No characters, no creatures that look alive, no text, no letters, no numbers, no interface, no frame, no signature.
```

## Criteri di accettazione

- [ ] centro vuoto e calmo, niente oggetti soli in mezzo
- [ ] orizzonte a circa l'86% dell'altezza, sotto solo una fascia piatta scura
- [ ] contorno nero spesso e colori piatti (Fumetto e Porta) o puntini regolari (Retino): lo stesso linguaggio dei pulsanti
- [ ] nessun testo, personaggio, cornice o interfaccia
- [ ] contrasto moderato: il testo chiaro sopra si legge

---

## Decisione

Approvata da Claude il 2026-11-13 su richiesta di Sergio («faglieli fare a Codex, tutti e 3»): immagini di prova, reversibili.

## Consegna di Codex

## Resoconto di Claude
