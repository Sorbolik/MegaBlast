# WB-078 · Le cornici dei pezzi, il simbolo del tipo e il segno "indossato"

- **Stato:** APPROVATA (Sergio, 18 nov 15:56: «Approva»)
- **Data:** 2026-11-18
- **Ramo della scheda:** `claude/project-thread-rc20kg` (eseguila da questo ramo: `git fetch origin claude/project-thread-rc20kg`) · **Ramo delle immagini:** `design/WB-078`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-078` senza chiedere conferma (il repository è privato).

## Obiettivo

Sergio, 18 nov: le cornici dei pezzi nello zaino e in armeria (WB-044, R1) «sono veramente brutte e
scontornate male»: storte e sporche apposta, com'erano i primi disegni. Si rifanno **dritte e
pulite**, e in più ogni casella dice **che tipo di pezzo è** con un simbolino in alto a sinistra
(elmo, corazza, mantello, stivali, guanti) e **se è indossato** con una fascia in basso dove il
gioco scrive INDOSSATO (oggi è solo una spunta). Il pezzo scelto ha la cornice accesa.

Il gioco monta i pezzi uno sopra l'altro: cornice, icona del pezzo (R2, c'è già), linguetta col
simbolo, fascia, tondo del livello (c'è già). Per questo ogni immagine è un pezzo solo, vuoto.

## Come devono essere fatte

- **Dritte:** lati perfettamente dritti e paralleli, angoli tondi tutti uguali, forma simmetrica,
  contorno nero dello stesso spessore dappertutto. Niente lati ondulati, niente tratto tremolante.
- Colori pieni, una luce piatta e un'ombra piatta al massimo, niente sfumature, niente grana.
- Lo stesso ferro scuro quieto del pulsante secondario (R3), senza chiodi agli angoli.
- Ricalcabili in vettori: al massimo sei colori per immagine.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-078/riferimenti/R1_caselle_oggi.png` | le caselle di oggi nello zaino: da sostituire (storte, coi chiodi); servono per le proporzioni e per vedere icona, spunta e tondo del livello |
| R2 | `art/WB-078/riferimenti/R2_icona_stivali.png` | un'icona di un pezzo: lo spessore della china e lo stile dei simboli |
| R3 | `art/WB-078/riferimenti/R3_pulsante_secondario.png` | il pulsante secondario: il ferro scuro e pulito da riprendere |

## Immagini da generare

Dieci richieste separate. Ogni prompt è completo e va usato così com'è. I file vanno in
`art/WB-078/` col nome della tabella più `_1` e `_2`.

| Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|
| `cornice.png` | R1, R2, R3 | 1024×1024 | 2 |
| `cornice_scelta.png` | R1, R2, R3 | 1024×1024 | 2 |
| `cornice_vuota.png` | R1, R2, R3 | 1024×1024 | 2 |
| `linguetta.png` | R2, R3 | 1024×1024 | 2 |
| `fascia_indossato.png` | R2, R3 | 1024×1024 | 2 |
| `tipo_elmo.png` | R2 | 1024×1024 | 2 |
| `tipo_corazza.png` | R2 | 1024×1024 | 2 |
| `tipo_mantello.png` | R2 | 1024×1024 | 2 |
| `tipo_stivali.png` | R2 | 1024×1024 | 2 |
| `tipo_guanti.png` | R2 | 1024×1024 | 2 |

### `cornice`

```
Image 1 shows the inventory slots of our game as they are today: they must be REPLACED because their sides are wobbly and uneven. Image 2 is an item icon of our game (ink thickness and flat coloring to match). Image 3 is a button of our game: take its quiet dark iron material and its clean look.

Draw ONE empty square inventory slot frame for a comic-style mobile game, seen perfectly from the front. A square with rounded corners, all four corners identical, all four sides PERFECTLY STRAIGHT and parallel, perfectly symmetric. A dark iron rim (dark purple-grey, like image 3) about 7% of the side wide, with one thin flat lighter band along the top edge and one thin flat darker band along the bottom edge. Inside the rim a flat, empty, almost black panel (#15121A) with rounded corners. Thick pure black outline of constant thickness outside the rim and between rim and panel, ruler-straight, never wobbly, never hand-shaken.

No rivets, no screws, no nails, no scratches, no texture, no gradient, no glow, no icon inside, no text. Flat colors, at most six colors. Centered, filling about 88% of the image, on a flat pure magenta #FF00FF background.
```

### `cornice_scelta`

```
Image 1 shows the inventory slots of our game as they are today (the orange one is the selected slot): they must be REPLACED because their sides are wobbly and uneven. Image 2 is an item icon of our game (ink thickness and flat coloring to match). Image 3 is a button of our game: take its clean look.

Draw ONE empty square inventory slot frame for a comic-style mobile game, seen perfectly from the front: the SELECTED slot. A square with rounded corners, all four corners identical, all four sides PERFECTLY STRAIGHT and parallel, perfectly symmetric. A glowing-hot rim in ember orange (#F2600E) about 7% of the side wide, with one thin flat yellow band (#FFC21A) along the top edge and one thin flat darker red-orange band along the bottom edge. Inside the rim a flat, empty, almost black panel (#15121A) with rounded corners. Thick pure black outline of constant thickness outside the rim and between rim and panel, ruler-straight, never wobbly, never hand-shaken.

No rivets, no screws, no nails, no flames coming out, no scratches, no texture, no gradient, no glow, no icon inside, no text. Flat colors, at most six colors. Centered, filling about 88% of the image, on a flat pure magenta #FF00FF background.
```

### `cornice_vuota`

```
Image 1 shows the inventory slots of our game as they are today: they must be REPLACED because their sides are wobbly and uneven. Image 2 is an item icon of our game (ink thickness and flat coloring to match). Image 3 is a button of our game: take its clean look.

Draw ONE empty square inventory slot frame for a comic-style mobile game, seen perfectly from the front: the slot with NOTHING in it, quieter than a normal slot. A square with rounded corners, all four corners identical, all four sides PERFECTLY STRAIGHT and parallel, perfectly symmetric. A thin cold grey-violet rim (#4A4352) about 4% of the side wide, one flat color. Inside the rim a flat, empty, dark panel (#1E1A24) with rounded corners. Thick pure black outline of constant thickness outside the rim and between rim and panel, ruler-straight, never wobbly, never hand-shaken.

No rivets, no screws, no nails, no scratches, no texture, no gradient, no glow, no icon inside, no text. Flat colors, at most four colors. Centered, filling about 88% of the image, on a flat pure magenta #FF00FF background.
```

### `linguetta`

```
Image 1 is an item icon of our game (ink thickness and flat coloring to match). Image 2 is a button of our game: take its quiet dark iron material and its clean look.

Draw ONE small empty corner tab for a comic-style mobile game interface, seen perfectly from the front: the little plate that sits on the TOP-LEFT corner of an inventory slot and will hold a tiny symbol (the game adds the symbol, do not draw it). Shape: a square whose top-left corner is rounded with a big radius, whose bottom-right corner is rounded with a small radius, and whose other two corners are sharp. All sides PERFECTLY STRAIGHT. Flat dark iron fill (dark purple-grey, like image 2) with one thin flat lighter band along the top edge. Thick pure black outline of constant thickness, ruler-straight, never wobbly.

Completely empty inside: no symbol, no icon, no text, no rivets, no texture, no gradient, no glow. Flat colors, at most four colors. Centered, filling about 70% of the image, on a flat pure magenta #FF00FF background.
```

### `fascia_indossato`

```
Image 1 is an item icon of our game (ink thickness and flat coloring to match). Image 2 is a button of our game: take its clean look.

Draw ONE small empty horizontal label band for a comic-style mobile game interface, seen perfectly from the front: the strip that lies across the BOTTOM of an inventory slot when the item is equipped (the game writes the word on it, do not write anything). Shape: a wide flat rectangle about four times as wide as tall, with the two TOP corners sharp and the two BOTTOM corners slightly rounded. All sides PERFECTLY STRAIGHT and parallel. Flat fill in warm gold (#F5C417) with one thin flat darker amber band along the bottom edge. Thick pure black outline of constant thickness, ruler-straight, never wobbly.

Completely empty: no text, no letters, no check mark, no icon, no rivets, no texture, no gradient, no glow. Flat colors, at most four colors. Centered, filling about 85% of the image width, on a flat pure magenta #FF00FF background.
```

### `tipo_elmo`

```
Image 1 is an item icon of our game: match its thick pure black outline and flat coloring.

Draw ONE tiny category symbol for a comic-style mobile game interface: a HELMET, a simple round closed helmet seen from the front with a horizontal eye slit and nothing else. It must read at 20 pixels: one bold simple silhouette, no small details. Fill: one flat light sand color (#EAD9B0) with one flat slightly darker shadow tone on one side. Thick pure black outline of constant thickness, clean and smooth.

No horns, no plume, no face, no text, no frame, no background shape, no gradient, no glow. At most four colors. Centered, filling about 75% of the image, on a flat pure magenta #FF00FF background.
```

### `tipo_corazza`

```
Image 1 is an item icon of our game: match its thick pure black outline and flat coloring.

Draw ONE tiny category symbol for a comic-style mobile game interface: a CHEST ARMOUR, a simple breastplate seen from the front (neck opening on top, two short shoulder caps, narrower at the waist) and nothing else. It must read at 20 pixels: one bold simple silhouette, no small details. Fill: one flat light sand color (#EAD9B0) with one flat slightly darker shadow tone on one side. Thick pure black outline of constant thickness, clean and smooth.

No arms, no body inside, no emblem, no text, no frame, no background shape, no gradient, no glow. At most four colors. Centered, filling about 75% of the image, on a flat pure magenta #FF00FF background.
```

### `tipo_mantello`

```
Image 1 is an item icon of our game: match its thick pure black outline and flat coloring.

Draw ONE tiny category symbol for a comic-style mobile game interface: a short CAPE, seen from the back, hanging from a small collar on top and widening down to a hem with three soft points, and nothing else. It must read at 20 pixels: one bold simple silhouette, no small details. Fill: one flat light sand color (#EAD9B0) with one flat slightly darker shadow tone on one side. Thick pure black outline of constant thickness, clean and smooth.

No body, no hood, no emblem, no text, no frame, no background shape, no gradient, no glow. At most four colors. Centered, filling about 75% of the image, on a flat pure magenta #FF00FF background.
```

### `tipo_stivali`

```
Image 1 is an item icon of our game: match its thick pure black outline and flat coloring.

Draw ONE tiny category symbol for a comic-style mobile game interface: ONE BOOT seen from the side, toe pointing right, a short sturdy boot with a thick sole and a folded cuff, and nothing else. It must read at 20 pixels: one bold simple silhouette, no small details. Fill: one flat light sand color (#EAD9B0) with one flat slightly darker shadow tone on one side. Thick pure black outline of constant thickness, clean and smooth.

No leg, no buckles, no laces, no text, no frame, no background shape, no gradient, no glow. At most four colors. Centered, filling about 75% of the image, on a flat pure magenta #FF00FF background.
```

### `tipo_guanti`

```
Image 1 is an item icon of our game: match its thick pure black outline and flat coloring.

Draw ONE tiny category symbol for a comic-style mobile game interface: ONE GLOVE, an empty gauntlet closed as a fist seen from the side with a short flared cuff, and nothing else. It must read at 20 pixels: one bold simple silhouette, no small details. Fill: one flat light sand color (#EAD9B0) with one flat slightly darker shadow tone on one side. Thick pure black outline of constant thickness, clean and smooth.

No arm, no studs, no text, no frame, no background shape, no gradient, no glow. At most four colors. Centered, filling about 75% of the image, on a flat pure magenta #FF00FF background.
```

## Criteri di accettazione

- [ ] sfondo magenta pieno, contorno nero puro e spesso, nessuna scritta
- [ ] cornici: lati dritti e paralleli, quattro angoli uguali, simmetriche, niente chiodi
- [ ] le tre cornici hanno la stessa forma e la stessa misura (si scambiano senza che la casella salti)
- [ ] linguetta e fascia vuote; i cinque simboli si riconoscono piccoli (20 pixel) e sono della stessa mano
- [ ] colori pieni, niente sfumature né grana

---

## Decisione

Approvata da Sergio il 18 nov alle 15:56 («Approva»).

## Consegna di Codex

## Resoconto di Claude
