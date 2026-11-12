# WB-028 · Sfondi dei menu: solo grandi masse, come quello dei gironi

- **Stato:** APPROVATA (Claude, 2026-11-12, sulle parole di Sergio qui sotto; sono immagini di prova, reversibile)
- **Data:** 2026-11-12
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-028`

## Obiettivo

Sergio ha visto le quattro prove di WB-027 sotto i pulsanti veri (12 nov): «nella home il centro
di attenzione diventa quell'incudine al centro così, forse voglio meno dettagli, un po' come lo
sfondo della campagna dei gironi, è molto bello quello». Quindi lo sfondo dei gironi
(`sfondo_campagna_A` di WB-027) diventa **il modello**: solo grandi masse ai lati, nessun
oggetto, centro vuoto. Questa scheda rifà la home e l'armeria così e fa le altre schermate.
Subito dopo ha aggiunto: «le cose devono quasi incorniciare gli elementi com'è lì»: le masse
fanno da **cornice** al diavoletto e ai pulsanti, come le pareti del pozzo intorno all'imbuto.

## Cosa teniamo e cosa scartiamo

| Teniamo | Perché |
|---|---|
| La mano di R1: masse grandi e morbide, due piani per lato, bordo di luce sottile, primo piano scuro e sfocato negli angoli in basso | «è molto bello quello» (Sergio) |
| Caldo e forme tonde in basso a sinistra, gelo e spigoli in alto a destra | l'identità del gioco in ogni schermata |
| Centro vuoto, scuro e calmo | sopra ci sono il diavoletto, le scritte e i pulsanti |
| Ogni schermata un posto della storia, detto solo dalla **forma delle masse** | ogni schermata la sua identità, senza oggetti |

| Scartiamo | Perché |
|---|---|
| Oggetti e attrezzi (incudine, martelli, tenaglie, barile, vapore) | attirano l'occhio: «il centro di attenzione diventa quell'incudine» |
| Cristalli molto chiari in alto a destra | dietro le piastre della home disturbavano (nota di Claude e di Codex su WB-027) |
| Puntini e scintille dipinti | la vita la mette il gioco (braci e fiocchi lenti) |
| La strada B, a sagome di carta | più affollata; il modello scelto è della strada A |

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-028/riferimenti/R1_sfondo_campagna.jpg` | lo sfondo dei gironi di WB-027, approvato: **la mano e la quantità di dettagli da copiare** |
| R2 | `art/WB-028/riferimenti/R2_campagna_con_interfaccia.jpg` | lo stesso sfondo con l'interfaccia sopra: fa vedere quanto deve restare calmo. **L'interfaccia non va ridisegnata** |

`art/WB-028/riferimenti/R3_home_troppi_oggetti.jpg` è la home di WB-027 da **non** rifare
(incudine al centro, attrezzi, cristalli troppo chiari): serve solo a chi legge, non va allegata.

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega sempre R1 e R2 in quest'ordine
("image 1", "image 2"). Formato largo 16:9 (1672×941 o più), una variante.

| Nome file | Schermata | Posto |
|---|---|---|
| `sfondo_home` | HOME | la soglia della Forgia |
| `sfondo_armeria` | ARMERIA | la fucina del Fabbro |
| `sfondo_allenamento` | ALLENAMENTO | il Cortile |
| `sfondo_eventi` | EVENTI | la piazza delle feste |
| `sfondo_gioca` | GIOCA | il cancello dell’arena |
| `sfondo_diavoletto` | DIAVOLETTO | lo specchio |
| `sfondo_impostazioni` | IMPOSTAZIONI | il retrobottega |
| `sfondo_podio` | PODIO | la vittoria |

### `sfondo_home`

```
Image 1 is an approved background of a mobile game about little devils in Dante's hell (the campaign map screen). Image 2 shows it in use, with the game's comic-style interface on top. Paint a NEW background of the same family for another screen of the same game, wide 16:9, by the same hand as image 1: same painting style, same softness, same dark tonal range, same two lights, same amount of detail.

The place: the threshold of an underground forge, where the warm cave of the forge opens onto the frozen abyss. On the left, a huge rounded rock arch, like the side of a furnace mouth, comes in from the left edge and from the top, with the orange glow behind it low on the left. On the right, the vault is broken: a wall of big ice slabs and a few icicles come in from the right edge and from the top-right corner. Along the bottom fifth, a flat dark floor band, very plain, with a faint warm reflection on the left and a faint cold one on the right. A character will stand on the left third and a column of buttons on the right third, so both areas must be plain behind them.

Rules taken from image 1, to follow exactly: the picture is made ONLY of a few very big simple masses coming in from the left and right edges; there are NO objects, no props, no tools, no furniture, nothing standing alone in the middle. The whole centre of the picture is empty, dark and calm, with nothing that attracts the eye. The masses work as a FRAME around the interface, exactly as in image 2 where the terraces frame the map: they hug the edges of the picture and their inner contours open around the area where the character and the buttons will sit, leading the eye toward them and never competing with them. Warm light glows dull orange from the bottom-left corner and the masses on the left are soft and rounded; cold pale-blue light comes from the top-right corner and the masses on the right are ice, sharp and angular. Two depth planes on each side (the far one lighter and hazier, the nearer one darker, with a thin rim of light on its edge) plus an almost black, out-of-focus shape in the bottom-left corner (round rock) and one in the bottom-right corner (ice shard). The ice near the top-right corner must stay dim: no bright white crystals, nothing brighter than in image 1.

Stylized 2D game background with atmospheric perspective, big flat shapes with smooth soft gradients. NO black outlines, no ink lines, no hatching, no bricks, no cracks, no surface texture, no noise, no floating sparks or dots. Overall dark and desaturated (soot brown-black, deep navy). A soft dark vignette at the edges.

No characters, no creatures, no text, no letters, no numbers, no interface, no frame, no signature. Do not draw the interface of image 2.
```

### `sfondo_armeria`

```
Image 1 is an approved background of a mobile game about little devils in Dante's hell (the campaign map screen). Image 2 shows it in use, with the game's comic-style interface on top. Paint a NEW background of the same family for another screen of the same game, wide 16:9, by the same hand as image 1: same painting style, same softness, same dark tonal range, same two lights, same amount of detail.

The place: deep inside the forge. On the left, a big rounded chimney hood and a rounded furnace wall come in from the left edge, with the orange glow under the hood, low on the left. On the right, a tall flat wall of ice slabs comes in from the right edge, with a few icicles at the top. Along the bottom fifth, a flat dark floor band. A list and a big panel cover the centre and the right, so everything except the two edges must be plain and dark.

Rules taken from image 1, to follow exactly: the picture is made ONLY of a few very big simple masses coming in from the left and right edges; there are NO objects, no props, no tools, no furniture, nothing standing alone in the middle. The whole centre of the picture is empty, dark and calm, with nothing that attracts the eye. The masses work as a FRAME around the interface, exactly as in image 2 where the terraces frame the map: they hug the edges of the picture and their inner contours open around the area where the character and the buttons will sit, leading the eye toward them and never competing with them. Warm light glows dull orange from the bottom-left corner and the masses on the left are soft and rounded; cold pale-blue light comes from the top-right corner and the masses on the right are ice, sharp and angular. Two depth planes on each side (the far one lighter and hazier, the nearer one darker, with a thin rim of light on its edge) plus an almost black, out-of-focus shape in the bottom-left corner (round rock) and one in the bottom-right corner (ice shard). The ice near the top-right corner must stay dim: no bright white crystals, nothing brighter than in image 1.

Stylized 2D game background with atmospheric perspective, big flat shapes with smooth soft gradients. NO black outlines, no ink lines, no hatching, no bricks, no cracks, no surface texture, no noise, no floating sparks or dots. Overall dark and desaturated (soot brown-black, deep navy). A soft dark vignette at the edges.

No characters, no creatures, no text, no letters, no numbers, no interface, no frame, no signature. Do not draw the interface of image 2.
```

### `sfondo_allenamento`

```
Image 1 is an approved background of a mobile game about little devils in Dante's hell (the campaign map screen). Image 2 shows it in use, with the game's comic-style interface on top. Paint a NEW background of the same family for another screen of the same game, wide 16:9, by the same hand as image 1: same painting style, same softness, same dark tonal range, same two lights, same amount of detail.

The place: a training courtyard under an open dark sky. On the left, a low rounded courtyard wall with three soft rounded battlements comes in from the left edge, lit from below by the orange glow. On the right, a broken wall of the same height, frozen, with sharp angular breaks and ice on top, comes in from the right edge. The walls stay in the lower half and at the sides; the centre and the upper part are open, empty dark sky. Along the bottom fifth, a flat dark floor band.

Rules taken from image 1, to follow exactly: the picture is made ONLY of a few very big simple masses coming in from the left and right edges; there are NO objects, no props, no tools, no furniture, nothing standing alone in the middle. The whole centre of the picture is empty, dark and calm, with nothing that attracts the eye. The masses work as a FRAME around the interface, exactly as in image 2 where the terraces frame the map: they hug the edges of the picture and their inner contours open around the area where the character and the buttons will sit, leading the eye toward them and never competing with them. Warm light glows dull orange from the bottom-left corner and the masses on the left are soft and rounded; cold pale-blue light comes from the top-right corner and the masses on the right are ice, sharp and angular. Two depth planes on each side (the far one lighter and hazier, the nearer one darker, with a thin rim of light on its edge) plus an almost black, out-of-focus shape in the bottom-left corner (round rock) and one in the bottom-right corner (ice shard). The ice near the top-right corner must stay dim: no bright white crystals, nothing brighter than in image 1.

Stylized 2D game background with atmospheric perspective, big flat shapes with smooth soft gradients. NO black outlines, no ink lines, no hatching, no bricks, no cracks, no surface texture, no noise, no floating sparks or dots. Overall dark and desaturated (soot brown-black, deep navy). A soft dark vignette at the edges.

No characters, no creatures, no text, no letters, no numbers, no interface, no frame, no signature. Do not draw the interface of image 2.
```

### `sfondo_eventi`

```
Image 1 is an approved background of a mobile game about little devils in Dante's hell (the campaign map screen). Image 2 shows it in use, with the game's comic-style interface on top. Paint a NEW background of the same family for another screen of the same game, wide 16:9, by the same hand as image 1: same painting style, same softness, same dark tonal range, same two lights, same amount of detail.

The place: a festival square in the underworld. From the top-left corner, three or four big soft drapes of heavy cloth hang down in rounded folds, lit warm from below. From the top-right corner, a row of long sharp icicles of different lengths hangs down like angular pennants. Below them, low at the two sides only, the dim rounded shape of a tent on the left and a sharp ice spire on the right. The centre is empty. Along the bottom fifth, a flat dark floor band.

Rules taken from image 1, to follow exactly: the picture is made ONLY of a few very big simple masses coming in from the left and right edges; there are NO objects, no props, no tools, no furniture, nothing standing alone in the middle. The whole centre of the picture is empty, dark and calm, with nothing that attracts the eye. The masses work as a FRAME around the interface, exactly as in image 2 where the terraces frame the map: they hug the edges of the picture and their inner contours open around the area where the character and the buttons will sit, leading the eye toward them and never competing with them. Warm light glows dull orange from the bottom-left corner and the masses on the left are soft and rounded; cold pale-blue light comes from the top-right corner and the masses on the right are ice, sharp and angular. Two depth planes on each side (the far one lighter and hazier, the nearer one darker, with a thin rim of light on its edge) plus an almost black, out-of-focus shape in the bottom-left corner (round rock) and one in the bottom-right corner (ice shard). The ice near the top-right corner must stay dim: no bright white crystals, nothing brighter than in image 1.

Stylized 2D game background with atmospheric perspective, big flat shapes with smooth soft gradients. NO black outlines, no ink lines, no hatching, no bricks, no cracks, no surface texture, no noise, no floating sparks or dots. Overall dark and desaturated (soot brown-black, deep navy). A soft dark vignette at the edges.

No characters, no creatures, no text, no letters, no numbers, no interface, no frame, no signature. Do not draw the interface of image 2.
```

### `sfondo_gioca`

```
Image 1 is an approved background of a mobile game about little devils in Dante's hell (the campaign map screen). Image 2 shows it in use, with the game's comic-style interface on top. Paint a NEW background of the same family for another screen of the same game, wide 16:9, by the same hand as image 1: same painting style, same softness, same dark tonal range, same two lights, same amount of detail.

The place: the two gates of an arena facing each other. On the left edge, a massive rounded tower with a round arched gate glowing dull orange from inside. On the right edge, a massive sharp angular tower of ice with a pointed gate glowing dim pale blue from inside. Between them, the whole centre is an empty dark arena with a plain floor band along the bottom fifth. The two sides mirror each other in size.

Rules taken from image 1, to follow exactly: the picture is made ONLY of a few very big simple masses coming in from the left and right edges; there are NO objects, no props, no tools, no furniture, nothing standing alone in the middle. The whole centre of the picture is empty, dark and calm, with nothing that attracts the eye. The masses work as a FRAME around the interface, exactly as in image 2 where the terraces frame the map: they hug the edges of the picture and their inner contours open around the area where the character and the buttons will sit, leading the eye toward them and never competing with them. Warm light glows dull orange from the bottom-left corner and the masses on the left are soft and rounded; cold pale-blue light comes from the top-right corner and the masses on the right are ice, sharp and angular. Two depth planes on each side (the far one lighter and hazier, the nearer one darker, with a thin rim of light on its edge) plus an almost black, out-of-focus shape in the bottom-left corner (round rock) and one in the bottom-right corner (ice shard). The ice near the top-right corner must stay dim: no bright white crystals, nothing brighter than in image 1.

Stylized 2D game background with atmospheric perspective, big flat shapes with smooth soft gradients. NO black outlines, no ink lines, no hatching, no bricks, no cracks, no surface texture, no noise, no floating sparks or dots. Overall dark and desaturated (soot brown-black, deep navy). A soft dark vignette at the edges.

No characters, no creatures, no text, no letters, no numbers, no interface, no frame, no signature. Do not draw the interface of image 2.
```

### `sfondo_diavoletto`

```
Image 1 is an approved background of a mobile game about little devils in Dante's hell (the campaign map screen). Image 2 shows it in use, with the game's comic-style interface on top. Paint a NEW background of the same family for another screen of the same game, wide 16:9, by the same hand as image 1: same painting style, same softness, same dark tonal range, same two lights, same amount of detail.

The place: a dressing niche. On the left, a big heavy curtain in soft rounded folds comes in from the left edge and from the top, lit warm from below. On the right, tall flat facets of ice like the edge of a frozen mirror come in from the right edge. In the centre there is only a very soft, very dim tall halo of light on the back wall, like a quiet niche, with no shape inside it: a character will stand there. Along the bottom fifth, a flat dark floor band.

Rules taken from image 1, to follow exactly: the picture is made ONLY of a few very big simple masses coming in from the left and right edges; there are NO objects, no props, no tools, no furniture, nothing standing alone in the middle. The whole centre of the picture is empty, dark and calm, with nothing that attracts the eye. The masses work as a FRAME around the interface, exactly as in image 2 where the terraces frame the map: they hug the edges of the picture and their inner contours open around the area where the character and the buttons will sit, leading the eye toward them and never competing with them. Warm light glows dull orange from the bottom-left corner and the masses on the left are soft and rounded; cold pale-blue light comes from the top-right corner and the masses on the right are ice, sharp and angular. Two depth planes on each side (the far one lighter and hazier, the nearer one darker, with a thin rim of light on its edge) plus an almost black, out-of-focus shape in the bottom-left corner (round rock) and one in the bottom-right corner (ice shard). The ice near the top-right corner must stay dim: no bright white crystals, nothing brighter than in image 1.

Stylized 2D game background with atmospheric perspective, big flat shapes with smooth soft gradients. NO black outlines, no ink lines, no hatching, no bricks, no cracks, no surface texture, no noise, no floating sparks or dots. Overall dark and desaturated (soot brown-black, deep navy). A soft dark vignette at the edges.

No characters, no creatures, no text, no letters, no numbers, no interface, no frame, no signature. Do not draw the interface of image 2.
```

### `sfondo_impostazioni`

```
Image 1 is an approved background of a mobile game about little devils in Dante's hell (the campaign map screen). Image 2 shows it in use, with the game's comic-style interface on top. Paint a NEW background of the same family for another screen of the same game, wide 16:9, by the same hand as image 1: same painting style, same softness, same dark tonal range, same two lights, same amount of detail.

The place: the back room of the forge. From the bottom-left corner rises one enormous rounded wheel, so big that only a quarter of it is inside the picture, a plain dark disc with a soft warm rim of light and no teeth, no spokes and no details. From the top-right corner come two or three long straight rails of ice, like big rulers, crossing each other at sharp angles. The centre is empty. Along the bottom fifth, a flat dark floor band.

Rules taken from image 1, to follow exactly: the picture is made ONLY of a few very big simple masses coming in from the left and right edges; there are NO objects, no props, no tools, no furniture, nothing standing alone in the middle. The whole centre of the picture is empty, dark and calm, with nothing that attracts the eye. The masses work as a FRAME around the interface, exactly as in image 2 where the terraces frame the map: they hug the edges of the picture and their inner contours open around the area where the character and the buttons will sit, leading the eye toward them and never competing with them. Warm light glows dull orange from the bottom-left corner and the masses on the left are soft and rounded; cold pale-blue light comes from the top-right corner and the masses on the right are ice, sharp and angular. Two depth planes on each side (the far one lighter and hazier, the nearer one darker, with a thin rim of light on its edge) plus an almost black, out-of-focus shape in the bottom-left corner (round rock) and one in the bottom-right corner (ice shard). The ice near the top-right corner must stay dim: no bright white crystals, nothing brighter than in image 1.

Stylized 2D game background with atmospheric perspective, big flat shapes with smooth soft gradients. NO black outlines, no ink lines, no hatching, no bricks, no cracks, no surface texture, no noise, no floating sparks or dots. Overall dark and desaturated (soot brown-black, deep navy). A soft dark vignette at the edges.

No characters, no creatures, no text, no letters, no numbers, no interface, no frame, no signature. Do not draw the interface of image 2.
```

### `sfondo_podio`

```
Image 1 is an approved background of a mobile game about little devils in Dante's hell (the campaign map screen). Image 2 shows it in use, with the game's comic-style interface on top. Paint a NEW background of the same family for another screen of the same game, wide 16:9, by the same hand as image 1: same painting style, same softness, same dark tonal range, same two lights, same amount of detail.

The place: the winners' spot. On the left, soft rounded rock masses come in from the left edge, lit by the orange glow. On the right, sharp ice masses come in from the right edge. From the top, in the centre, two very soft and very dim shafts of pale warm light fall on the floor, wide and blurred, the only thing in the centre: the winners will stand there. Along the bottom fifth, a flat dark floor band with a faint pool of light in the middle.

Rules taken from image 1, to follow exactly: the picture is made ONLY of a few very big simple masses coming in from the left and right edges; there are NO objects, no props, no tools, no furniture, nothing standing alone in the middle. The whole centre of the picture is empty, dark and calm, with nothing that attracts the eye. The masses work as a FRAME around the interface, exactly as in image 2 where the terraces frame the map: they hug the edges of the picture and their inner contours open around the area where the character and the buttons will sit, leading the eye toward them and never competing with them. Warm light glows dull orange from the bottom-left corner and the masses on the left are soft and rounded; cold pale-blue light comes from the top-right corner and the masses on the right are ice, sharp and angular. Two depth planes on each side (the far one lighter and hazier, the nearer one darker, with a thin rim of light on its edge) plus an almost black, out-of-focus shape in the bottom-left corner (round rock) and one in the bottom-right corner (ice shard). The ice near the top-right corner must stay dim: no bright white crystals, nothing brighter than in image 1.

Stylized 2D game background with atmospheric perspective, big flat shapes with smooth soft gradients. NO black outlines, no ink lines, no hatching, no bricks, no cracks, no surface texture, no noise, no floating sparks or dots. Overall dark and desaturated (soot brown-black, deep navy). A soft dark vignette at the edges.

No characters, no creatures, no text, no letters, no numbers, no interface, no frame, no signature. Do not draw the interface of image 2.
```

## Criteri di accettazione

- [ ] sembra dipinta dalla stessa mano di R1, con la stessa quantità di dettagli (non di più)
- [ ] nessun oggetto: solo grandi masse che entrano dai lati
- [ ] il centro è vuoto, scuro e calmo; niente attira l'occhio
- [ ] le masse incorniciano la zona dell'interfaccia, come in R2
- [ ] luce calda in basso a sinistra con forme tonde, luce fredda in alto a destra con spigoli
- [ ] il gelo in alto a destra non è più chiaro che in R1
- [ ] nessun contorno nero, texture, puntino, personaggio, scritta o cornice
- [ ] le otto schermate si distinguono fra loro dalla forma delle masse

## Dopo le immagini (lo fa Claude)

Le mette nella pagina delle proposte (https://claude.ai/artifact/8Vtj3sQas5mHQry8eD7Myo) sotto
l'interfaccia vera di ogni schermata e Sergio guarda. Quelle approvate passano al thread
dell'interfaccia, che le aggancia nel gioco insieme allo sfondo dei gironi di WB-027.

---

## Decisione

Approvata da Claude il 12 nov 2026 sulle parole di Sergio riportate sopra. Scelte di Claude:
lo sfondo dei gironi come unico modello di stile; niente oggetti in nessuna schermata, i posti
si riconoscono dalla forma delle masse; si fanno subito tutte le schermate (non solo la home)
per risparmiare un giro; un'immagine sola per schermata, senza piani separati (si valuterà
dopo se serve il movimento). Scartato: tenere l'incudine più piccola o spostata di lato.

## Consegna di Codex

## Resoconto di Claude
