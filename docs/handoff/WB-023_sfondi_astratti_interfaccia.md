# WB-023 · Sfondi quasi astratti dell'interfaccia «Filo di brace»

- **Stato:** APPROVATA (Claude, 2026-11-12, su indicazione di Sergio: «usa sempre codex per quello che non riesci a fare»)
- **Data:** 2026-11-12
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-023`

## Obiettivo

Sergio (12 nov), visti i pezzi di WB-022: «siamo molto più vicini», ma per lo sfondo vuole
disegni «un po' meno descrittivi, quasi astratti, le linee che ricordano quelle nuove che
abbiamo appena disegnato». Le figure di WB-021 (Fabbro, fornace) raccontano troppo. Qui Codex
disegna a mano **quattro motivi astratti** di fuoco e di gelo, col tratto dei pezzi di WB-022.
Tre prove fatte col codice sono nella proposta (https://claude.ai/artifact/2RBh8w9T56E7P9kFDd4HKA).

## Due fasi

Sergio (12 nov, viste le tre prove) ha scelto **«calore e cristallo»**.

- **Fase 1**, `esegui WB-023 fase 1`: `astratto_calore` e `astratto_cristallo`. È quella che serve.
- **Fase 2**, solo se Sergio la chiede: `astratto_fuoco`, `astratto_gelo`, `astratto_linea`, `astratto_vortice`.
- Codex esegue solo le righe della fase chiesta.

## Cosa teniamo e cosa scartiamo

| Teniamo | Perché |
|---|---|
| Il tratto dei pezzi (R3): pennellata morbida a china, un po' irregolare, che si assottiglia in punta | lo sfondo deve sembrare della stessa mano dei pulsanti |
| Solo bianco `#FFFFFF` su nero `#000000` | il gioco colora (caldo o freddo) e tiene tenue |
| Pochissimi segni, grandi, con molto vuoto | sopra ci vanno pulsanti e scritte |
| Fuoco = curve morbide; gelo = segni dritti e spigolosi | il dualismo si legge dalla forma, anche senza colore |

| Scartiamo | Perché |
|---|---|
| Oggetti e personaggi riconoscibili (fornace, incudine, catene, montagne, case) | «meno descrittivi, quasi astratti» |
| Riempimenti, grigi, sfumature, tratteggi, texture | li abbiamo già scartati |
| Scritte, cornici, firme | il testo lo scrive il gioco |

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-023/riferimenti/R1_lingue_e_schegge.png` | prova col codice: curve di fuoco a sinistra, schegge a destra (l'idea, non il tratto) |
| R2 | `art/WB-023/riferimenti/R2_una_linea.png` | prova col codice: una linea sola, morbida a sinistra e spigolosa a destra |
| R3 | `art/WB-023/riferimenti/R3_tratto_dei_pezzi.png` | i pezzi di WB-022: il tratto da copiare |
| R4 | `art/WB-023/riferimenti/R4_calore_e_cristallo.png` | prova col codice scelta da Sergio: onde di calore in basso a sinistra, facce di cristallo in alto a destra |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto: il
primo è "image 1", il secondo "image 2". Formato largo 16:9, sfondo nero pieno.

| Fase | Nome file | Riferimenti | Varianti |
|---|---|---|---|
| 1 | `astratto_calore` | R4, R3 | 2 |
| 1 | `astratto_cristallo` | R4, R3 | 2 |
| 2 | `astratto_fuoco` | R1, R3 | 2 |
| 2 | `astratto_gelo` | R1, R3 | 2 |
| 2 | `astratto_linea` | R2, R3 | 2 |
| 2 | `astratto_vortice` | R3 | 1 |

### `astratto_calore` (fase 1)

```
Image 1 is a game menu mockup: look only at the faint orange curved lines in the background that spread from the bottom-left corner like ripples; that is the idea, drawn too stiffly. Image 2 shows the brush line to copy: the thick, soft, slightly irregular hand-drawn ink outline of those cartoon iron plates.

An almost abstract drawing, wide 16:9: waves of heat spreading from the BOTTOM-LEFT corner. Five big loose brush strokes, each one a quarter of a circle centered on the bottom-left corner, one outside the other like ripples, the smallest near the corner and the biggest reaching about the middle of the picture. The arcs are soft and wobbly like hot air, not perfect circles; each is drawn by hand in one gesture, thicker in the middle and tapering at both ends, and the outer arcs are thinner and more broken than the inner ones. Two or three tiny dots like sparks between them. Nothing else: the right half and the top of the picture stay completely empty and black. It must not look like a sun, a radar, a rainbow or sound waves.

Pure white brush strokes (#FFFFFF) on a pure black background (#000000). Hand-drawn comic ink line like image 2: soft, confident, a bit uneven. No fills, no gray, no shading, no hatching, no texture, no glow. No text, letters, numbers, frame or signature.
```

### `astratto_cristallo` (fase 1)

```
Image 1 is a game menu mockup: look only at the faint blue angular lines in the background that spread from the top-right corner like the facets of a crystal; that is the idea, drawn too stiffly. Image 2 shows the brush line to copy: the thick, slightly irregular hand-drawn ink outline of those cartoon iron plates.

An almost abstract drawing, wide 16:9: facets of ice spreading from the TOP-RIGHT corner. Four big brush strokes, each one a broken angular line made of three or four straight segments, going around the top-right corner one outside the other like the growth rings of a crystal, the smallest near the corner and the biggest reaching about the middle of the picture. Straight segments and hard corners only, no curves; each stroke drawn by hand in fast straight movements, ending in sharp points, the outer ones thinner. Two or three tiny diamond-shaped specks between them. Nothing else: the left half and the bottom of the picture stay completely empty and black. It must not look like a spider web, a snowflake, a star or a mountain.

Pure white brush strokes (#FFFFFF) on a pure black background (#000000). Hand-drawn comic ink line like image 2, but with straight strokes and hard corners. No fills, no gray, no shading, no hatching, no texture, no glow. No text, letters, numbers, frame or signature.
```

### `astratto_fuoco` (fase 2)

```
Image 1 is a game menu mockup: look only at the faint orange curved lines in the background on the left; that is the idea, drawn too stiffly. Image 2 shows the brush line to copy: the thick, soft, slightly irregular hand-drawn ink outline of those cartoon iron plates.

An almost abstract drawing, wide 16:9: on the LEFT third only, four or five big loose brush strokes that rise from the bottom edge like tongues of fire: long soft S-shaped curves of different heights, leaning and overlapping a little, each stroke thicker at the base and tapering to a point. Two or three tiny dots like sparks above them. It must suggest heat and flame without drawing a realistic fire, a fireplace or any object. The rest of the picture stays completely empty and black.

Pure white brush strokes (#FFFFFF) on a pure black background (#000000). Hand-drawn comic ink line like image 2: soft, confident, a bit uneven. No fills, no gray, no shading, no hatching, no texture, no glow. Very few strokes, a lot of empty space. No text, letters, numbers, frame or signature.
```

### `astratto_gelo` (fase 2)

```
Image 1 is a game menu mockup: look only at the faint blue angular lines in the background on the right; that is the idea, drawn too stiffly. Image 2 shows the brush line to copy: the thick, slightly irregular hand-drawn ink outline of those cartoon iron plates.

An almost abstract drawing, wide 16:9: on the RIGHT third only, five or six big straight brush strokes like shards of ice: long sharp V shapes and broken angular lines hanging down from the top edge and a few rising from the bottom, of different lengths, crossing a little, each stroke drawn by hand in one fast straight movement and ending in a sharp point. Two or three tiny diamond-shaped specks near them. It must suggest cold and ice without drawing realistic icicles, mountains, snowflakes or any object. The rest of the picture stays completely empty and black.

Pure white brush strokes (#FFFFFF) on a pure black background (#000000). Hand-drawn comic ink line like image 2, but with straight strokes and hard corners. No fills, no gray, no shading, no hatching, no texture, no glow. Very few strokes, a lot of empty space. No text, letters, numbers, frame or signature.
```

### `astratto_linea` (fase 2)

```
Image 1 is a game menu mockup: look only at the faint line in the background that runs across the whole screen, soft and wavy on the left and jagged on the right; that is the idea, drawn too stiffly. Image 2 shows the brush line to copy: the thick, soft, slightly irregular hand-drawn ink outline of those cartoon iron plates.

An almost abstract drawing, wide 16:9: ONE single continuous brush line that crosses the whole picture from the left edge to the right edge, in the lower half. On the left it moves in slow soft round waves, like heat or smoke; around the middle it changes; on the right it becomes a sharp jagged zigzag with tall pointed peaks, like broken ice. One line only, drawn by hand in one gesture, thicker in the curves and thinner at the points. Above it, one much thinner and shorter echo of the same line. Nothing else. It must not look like a landscape, mountains, a heartbeat monitor or a chart.

Pure white brush strokes (#FFFFFF) on a pure black background (#000000). Hand-drawn comic ink line like image 2. No fills, no gray, no shading, no hatching, no texture, no glow. No text, letters, numbers, frame or signature.
```

### `astratto_vortice` (fase 2)

```
Image 1 shows the brush line to copy: the thick, soft, slightly irregular hand-drawn ink outline of those cartoon iron plates.

An almost abstract drawing, wide 16:9: a few big loose brush strokes that suggest a funnel going down, seen from the side: five or six wide flat ovals drawn by hand, one under the other, each smaller than the one above, not closed and not perfect, like quick circular gestures of a brush. The top ovals are soft and round; going down the strokes become more broken and angular, and the last one at the bottom is a small sharp diamond. A lot of empty black space on both sides. It must not look like a tornado, a spring or a target.

Pure white brush strokes (#FFFFFF) on a pure black background (#000000). Hand-drawn comic ink line like image 1. No fills, no gray, no shading, no hatching, no texture, no glow. Very few strokes. No text, letters, numbers, frame or signature.
```

## Criteri di accettazione

- [ ] solo bianco e nero, nessun riempimento, grigio o texture
- [ ] tratto a pennello come i pezzi di WB-022: morbido, un po' irregolare, che si assottiglia
- [ ] non si riconoscono oggetti: solo fuoco (curve) e gelo (spigoli)
- [ ] pochi segni e molto vuoto; `astratto_calore` dall'angolo in basso a sinistra, `astratto_cristallo` dall'angolo in alto a destra (fase 2: `astratto_fuoco` solo a sinistra, `astratto_gelo` solo a destra)
- [ ] nessuna scritta, cornice o firma

## Dopo le immagini (lo fa Claude)

Bianco in trasparenza, colore caldo o freddo, e li prova nella pagina della proposta al posto
delle tre prove fatte col codice; `astratto_vortice` dietro la mappa dei gironi. Sergio sceglie.

---

## Decisione

Approvata da Claude il 12 nov 2026 (Sergio: «usa sempre codex per quello che non riesci a
fare»): reversibile, si prova nella proposta prima che nel gioco.

## Consegna di Codex

## Resoconto di Claude
