# WB-025 · Uno sfondo per ogni schermata («Filo di brace»)

- **Stato:** APPROVATA (Sergio, 2026-11-12: «vorrei che ogni schermata avesse la sua identità, quindi con il suo sfondo diverso»)
- **Data:** 2026-11-12
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-025`

## Obiettivo

La home ha lo sfondo «calore e cristallo» (WB-023): onde di calore a pennello in basso a
sinistra, facce di cristallo in alto a destra. Sergio vuole che **ogni schermata abbia il suo
sfondo**. La regola resta la stessa dappertutto, così il gioco ha un'identità sola: **il caldo
sta in basso a sinistra ed è fatto di curve morbide, il freddo sta in alto a destra ed è fatto
di tratti dritti e spigoli**. Cambia il disegno: ogni schermata ha il suo motivo, legato a
quello che ci si fa. Il gioco poi li colora, li tiene tenui e li fa respirare.

## Cosa teniamo e cosa scartiamo

| Teniamo | Perché |
|---|---|
| La mano di WB-023 (R1, R2): pennellata a china spessa, un po' irregolare, che si assottiglia in punta | tutti gli sfondi devono sembrare fratelli |
| Caldo a sinistra dal basso (curve), freddo a destra dall'alto (spigoli), centro vuoto | la regola dell'identità; e il gioco colora le due metà separatamente |
| Bianco `#FFFFFF` su nero `#000000`, pochi tratti grandi | il colore e la trasparenza li mette il gioco; sopra ci sono pulsanti e scritte |
| Un motivo diverso per schermata, quasi astratto | «ogni schermata la sua identità» |

| Scartiamo | Perché |
|---|---|
| Oggetti, personaggi, simboli riconoscibili | «quasi astratti» (Sergio) |
| Raggi che partono dal centro | era l'interfaccia di prima, che ha stancato |
| Riempimenti, grigi, sfumature, texture, bagliori | già scartati |
| Tratti che passano nell'altra metà o al centro | le due metà si colorano separate e al centro ci sono i contenuti |

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-025/riferimenti/R1_calore.png` | lo sfondo caldo della home (WB-023): la mano da copiare, tratti morbidi |
| R2 | `art/WB-025/riferimenti/R2_cristallo.png` | lo sfondo freddo della home (WB-023): la mano da copiare, tratti dritti |
| R3 | `art/WB-025/riferimenti/R3_home_con_sfondo.png` | la home con i due sfondi colorati e tenui: come vengono usati |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega sempre R1, R2, R3 in quest'ordine
("image 1", "image 2", "image 3"). Formato largo 16:9, sfondo nero pieno, una variante.

| Nome file | Schermata | Motivo |
|---|---|---|
| `sfondo_armeria` | ARMERIA | il colpo di martello e la tempra |
| `sfondo_campagna` | CAMPAGNA (gironi) | la discesa |
| `sfondo_allenamento` | ALLENAMENTO | il bersaglio e i fendenti |
| `sfondo_eventi` | EVENTI | gli stendardi |
| `sfondo_gioca` | GIOCA ONLINE (coda e stanza) | lo scontro |
| `sfondo_diavoletto` | DIAVOLETTO (profilo) | il ricciolo e lo specchio |
| `sfondo_impostazioni` | IMPOSTAZIONI | le manopole e le tacche |
| `sfondo_podio` | PODIO e fine partita | la festa |

### `sfondo_armeria`

```
Image 1 and image 2 are two abstract background drawings already used in a game menu (image 3 shows them in use, tinted orange and blue, very faint behind the buttons): heat as soft round strokes in the bottom-left corner, ice as straight angular strokes in the top-right corner. Draw a NEW background of the same family for another screen of the same game, wide 16:9, with BOTH parts in the same picture: a warm motif made only of soft curved strokes that stays inside the LEFT half and grows from the bottom-left corner, and a cold motif made only of straight strokes and hard corners that stays inside the RIGHT half and grows from the top-right corner. Each motif reaches at most the middle of the picture.

Theme of this screen: the armory, where gear is forged. Warm motif: the burst of a hammer blow: from one point near the bottom-left corner, seven or eight short curved strokes of different lengths fly outward like a splash of sparks, with three or four tiny dots at their ends. Cold motif: quenching: five or six long straight parallel strokes falling diagonally from the top-right corner like blades or cold rain, of different lengths, two of them broken in the middle by a sharp angle.

Pure white brush strokes (#FFFFFF) on a pure black background (#000000), by the same hand as images 1 and 2: thick, confident, slightly uneven ink strokes that taper at the ends. No fills, no gray, no shading, no hatching, no texture, no glow. Few big strokes and a lot of empty black space; the middle of the picture stays completely empty. Nothing recognizable as a real object, character, building or symbol. No text, letters, numbers, frame or signature.
```

### `sfondo_campagna`

```
Image 1 and image 2 are two abstract background drawings already used in a game menu (image 3 shows them in use, tinted orange and blue, very faint behind the buttons): heat as soft round strokes in the bottom-left corner, ice as straight angular strokes in the top-right corner. Draw a NEW background of the same family for another screen of the same game, wide 16:9, with BOTH parts in the same picture: a warm motif made only of soft curved strokes that stays inside the LEFT half and grows from the bottom-left corner, and a cold motif made only of straight strokes and hard corners that stays inside the RIGHT half and grows from the top-right corner. Each motif reaches at most the middle of the picture.

Theme of this screen: the descent into the underworld. Warm motif: three or four long soft strokes that fall from the top of the left half and curl at the end like thick slow drops or hanging roots of fire, each ending in a small curl. Cold motif: four or five straight sharp spikes rising from the bottom of the right half like broken stalagmites, of different heights, leaning a little, two of them crossed by a short straight crack.

Pure white brush strokes (#FFFFFF) on a pure black background (#000000), by the same hand as images 1 and 2: thick, confident, slightly uneven ink strokes that taper at the ends. No fills, no gray, no shading, no hatching, no texture, no glow. Few big strokes and a lot of empty black space; the middle of the picture stays completely empty. Nothing recognizable as a real object, character, building or symbol. No text, letters, numbers, frame or signature.
```

### `sfondo_allenamento`

```
Image 1 and image 2 are two abstract background drawings already used in a game menu (image 3 shows them in use, tinted orange and blue, very faint behind the buttons): heat as soft round strokes in the bottom-left corner, ice as straight angular strokes in the top-right corner. Draw a NEW background of the same family for another screen of the same game, wide 16:9, with BOTH parts in the same picture: a warm motif made only of soft curved strokes that stays inside the LEFT half and grows from the bottom-left corner, and a cold motif made only of straight strokes and hard corners that stays inside the RIGHT half and grows from the top-right corner. Each motif reaches at most the middle of the picture.

Theme of this screen: training. Warm motif: three loose incomplete rings one inside the other, like a target painted fast with a brush, placed low on the left, each ring open in a different place, with one small dot in the center. Cold motif: three long straight slashes crossing each other in the top-right, like sword cuts, each ending in a very sharp point, with two tiny diamond specks near the crossing.

Pure white brush strokes (#FFFFFF) on a pure black background (#000000), by the same hand as images 1 and 2: thick, confident, slightly uneven ink strokes that taper at the ends. No fills, no gray, no shading, no hatching, no texture, no glow. Few big strokes and a lot of empty black space; the middle of the picture stays completely empty. Nothing recognizable as a real object, character, building or symbol. No text, letters, numbers, frame or signature.
```

### `sfondo_eventi`

```
Image 1 and image 2 are two abstract background drawings already used in a game menu (image 3 shows them in use, tinted orange and blue, very faint behind the buttons): heat as soft round strokes in the bottom-left corner, ice as straight angular strokes in the top-right corner. Draw a NEW background of the same family for another screen of the same game, wide 16:9, with BOTH parts in the same picture: a warm motif made only of soft curved strokes that stays inside the LEFT half and grows from the bottom-left corner, and a cold motif made only of straight strokes and hard corners that stays inside the RIGHT half and grows from the top-right corner. Each motif reaches at most the middle of the picture.

Theme of this screen: festivals and special events. Warm motif: three long wavy ribbons rising from the bottom-left like banners moving in hot air, each a single soft S-shaped stroke that gets thinner toward the top, with two tiny dots above them. Cold motif: a row of four or five sharp triangles of different sizes hanging from the top edge on the right like angular pennants, each drawn with two straight strokes that meet in a point.

Pure white brush strokes (#FFFFFF) on a pure black background (#000000), by the same hand as images 1 and 2: thick, confident, slightly uneven ink strokes that taper at the ends. No fills, no gray, no shading, no hatching, no texture, no glow. Few big strokes and a lot of empty black space; the middle of the picture stays completely empty. Nothing recognizable as a real object, character, building or symbol. No text, letters, numbers, frame or signature.
```

### `sfondo_gioca`

```
Image 1 and image 2 are two abstract background drawings already used in a game menu (image 3 shows them in use, tinted orange and blue, very faint behind the buttons): heat as soft round strokes in the bottom-left corner, ice as straight angular strokes in the top-right corner. Draw a NEW background of the same family for another screen of the same game, wide 16:9, with BOTH parts in the same picture: a warm motif made only of soft curved strokes that stays inside the LEFT half and grows from the bottom-left corner, and a cold motif made only of straight strokes and hard corners that stays inside the RIGHT half and grows from the top-right corner. Each motif reaches at most the middle of the picture.

Theme of this screen: two sides about to clash. Warm motif: three big curved swooshes that start at the left edge and sweep toward the center like a wave of fire charging to the right, the longest one in the middle. Cold motif: four straight spears that start at the right edge and point toward the center, slightly fanned, of different lengths, each ending in a sharp arrow-like tip. The two motifs face each other but do not touch: the center stays empty.

Pure white brush strokes (#FFFFFF) on a pure black background (#000000), by the same hand as images 1 and 2: thick, confident, slightly uneven ink strokes that taper at the ends. No fills, no gray, no shading, no hatching, no texture, no glow. Few big strokes and a lot of empty black space; the middle of the picture stays completely empty. Nothing recognizable as a real object, character, building or symbol. No text, letters, numbers, frame or signature.
```

### `sfondo_diavoletto`

```
Image 1 and image 2 are two abstract background drawings already used in a game menu (image 3 shows them in use, tinted orange and blue, very faint behind the buttons): heat as soft round strokes in the bottom-left corner, ice as straight angular strokes in the top-right corner. Draw a NEW background of the same family for another screen of the same game, wide 16:9, with BOTH parts in the same picture: a warm motif made only of soft curved strokes that stays inside the LEFT half and grows from the bottom-left corner, and a cold motif made only of straight strokes and hard corners that stays inside the RIGHT half and grows from the top-right corner. Each motif reaches at most the middle of the picture.

Theme of this screen: the player's own little devil. Warm motif: two or three playful curls in the bottom-left, like a tail with a pointed tip and a small spiral of smoke, each a single soft stroke ending in a curl. Cold motif: three or four tall narrow diamond outlines in the top-right, like the facets of a broken mirror, of different sizes, slightly tilted, one of them left open on one side.

Pure white brush strokes (#FFFFFF) on a pure black background (#000000), by the same hand as images 1 and 2: thick, confident, slightly uneven ink strokes that taper at the ends. No fills, no gray, no shading, no hatching, no texture, no glow. Few big strokes and a lot of empty black space; the middle of the picture stays completely empty. Nothing recognizable as a real object, character, building or symbol. No text, letters, numbers, frame or signature.
```

### `sfondo_impostazioni`

```
Image 1 and image 2 are two abstract background drawings already used in a game menu (image 3 shows them in use, tinted orange and blue, very faint behind the buttons): heat as soft round strokes in the bottom-left corner, ice as straight angular strokes in the top-right corner. Draw a NEW background of the same family for another screen of the same game, wide 16:9, with BOTH parts in the same picture: a warm motif made only of soft curved strokes that stays inside the LEFT half and grows from the bottom-left corner, and a cold motif made only of straight strokes and hard corners that stays inside the RIGHT half and grows from the top-right corner. Each motif reaches at most the middle of the picture.

Theme of this screen: settings and controls. Warm motif: two partial circles of different sizes in the bottom-left, like round dials drawn fast, each three quarters closed, with four or five short soft ticks around the bigger one. Cold motif: a long straight stroke in the top-right with a series of short straight ticks of different lengths along it, like the notches of a ruler carved in ice, and one sharp corner where the stroke turns.

Pure white brush strokes (#FFFFFF) on a pure black background (#000000), by the same hand as images 1 and 2: thick, confident, slightly uneven ink strokes that taper at the ends. No fills, no gray, no shading, no hatching, no texture, no glow. Few big strokes and a lot of empty black space; the middle of the picture stays completely empty. Nothing recognizable as a real object, character, building or symbol. No text, letters, numbers, frame or signature.
```

### `sfondo_podio`

```
Image 1 and image 2 are two abstract background drawings already used in a game menu (image 3 shows them in use, tinted orange and blue, very faint behind the buttons): heat as soft round strokes in the bottom-left corner, ice as straight angular strokes in the top-right corner. Draw a NEW background of the same family for another screen of the same game, wide 16:9, with BOTH parts in the same picture: a warm motif made only of soft curved strokes that stays inside the LEFT half and grows from the bottom-left corner, and a cold motif made only of straight strokes and hard corners that stays inside the RIGHT half and grows from the top-right corner. Each motif reaches at most the middle of the picture.

Theme of this screen: the end of a match and the winners. Warm motif: three arcs that shoot up from the bottom-left and fall open like the trails of small fireworks, each ending in three tiny short strokes. Cold motif: seven or eight small diamond shapes of different sizes scattered in the top-right like falling flakes of ice, two of them with a short straight trail above.

Pure white brush strokes (#FFFFFF) on a pure black background (#000000), by the same hand as images 1 and 2: thick, confident, slightly uneven ink strokes that taper at the ends. No fills, no gray, no shading, no hatching, no texture, no glow. Few big strokes and a lot of empty black space; the middle of the picture stays completely empty. Nothing recognizable as a real object, character, building or symbol. No text, letters, numbers, frame or signature.
```

## Criteri di accettazione

- [ ] solo bianco e nero, nessun riempimento, grigio o texture
- [ ] la stessa mano di R1 e R2: pennellata spessa che si assottiglia
- [ ] il motivo caldo è tutto nella metà sinistra e fatto di curve; il freddo tutto nella metà destra e fatto di tratti dritti
- [ ] il centro è vuoto
- [ ] quasi astratto: non si riconoscono oggetti o simboli veri
- [ ] gli otto sfondi sono diversi fra loro a colpo d'occhio
- [ ] nessuna scritta, cornice o firma

## Dopo le immagini (lo fa Claude)

Bianco in trasparenza, metà sinistra calda e metà destra fredda, e li prova nella pagina della
proposta, ognuno sulla sua schermata, con lo stesso respiro della home (un'onda che passa ogni
tanto sul caldo, un riflesso sul freddo). Sergio guarda e sceglie. Nel gioco pesano poco: un
canale solo, compressi.

---

## Decisione

Approvata da Sergio il 12 nov 2026 («ogni schermata avesse la sua identità, quindi con il suo
sfondo diverso»). I motivi li ha scelti Claude, uno per schermata, legati a quello che ci si fa:
si cambiano rigenerando una riga.

## Consegna di Codex

## Resoconto di Claude
