# WB-022 · Pezzi a fumetto dell'interfaccia «Filo di brace»

- **Stato:** APPROVATA (Sergio, 2026-11-12: «usa sempre codex per quello che non riesci a fare»)
- **Data:** 2026-11-12
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-022`

## Obiettivo

Sergio (12 nov) vuole l'interfaccia «meno neon, più fumetto», con forme morbide e non
simmetriche e «pulsanti diversi che rendano il concetto anche nella loro forma». La proposta
(https://claude.ai/artifact/2RBh8w9T56E7P9kFDd4HKA) li disegna col codice, ma le forme del
codice restano un po' rigide. Qui Codex **disegna a mano i pezzi**: il lingotto rovente
(l'azione principale), le piastre battute a martello (le porte), la scheggia di ghiaccio (quello
che è chiuso) e i pezzi piccoli. Senza scritte: le mette il gioco.

## Cosa teniamo e cosa scartiamo

| Teniamo | Perché |
|---|---|
| Contorno nero a china, spesso e un po' irregolare, colori pieni, al massimo una luce e un'ombra piatte | è lo stile del diavoletto (R3): i pulsanti devono sembrare disegnati dalla stessa mano |
| Forme morbide, storte, non simmetriche | richiesta di Sergio |
| Le sagome e i colori della proposta (R1, R2) | sono già state viste da Sergio |
| Pochissimi dettagli: una crepa, un'ammaccatura, un rivetto | minimalista, e sopra ci va il testo |

| Scartiamo | Perché |
|---|---|
| Texture, ruggine, sfumature morbide, riflessi realistici, 3D | lo stile di WB-020, scartato («troppo dettagliato») |
| Bagliori, aloni, effetto neon | li mette il gioco, ogni tanto |
| Scritte, numeri, icone sopra i pulsanti | il testo lo scrive il gioco |
| Ombre sullo sfondo | lo sfondo si toglie |

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-022/riferimenti/R1_stile_fumetto.png` | la home della proposta: sagome e colori di lingotto e piastre |
| R2 | `art/WB-022/riferimenti/R2_armeria_fumetto.png` | l'Armeria della proposta: piastra calda, scheggia di ghiaccio, pannello |
| R3 | `art/WB-012/scelti/apprendista.png` | il diavoletto: lo stile del contorno e dei colori |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto: il
primo è "image 1", il secondo "image 2" e così via. Sfondo verde pieno `#00FF00` (si toglie
dopo), una variante dove non è scritto altro.

| Nome file | Riferimenti | Formato | Varianti |
|---|---|---|---|
| `pezzo_lingotto` | R1, R3 | largo | 2 |
| `pezzo_piastre` | R1, R3 | quadrato | 1 |
| `pezzo_ghiaccio` | R2, R3 | largo | 1 |
| `pezzo_pannello` | R2, R3 | quadrato | 1 |
| `pezzo_piccoli` | R1, R2, R3 | quadrato | 1 |

### `pezzo_lingotto`

```
Image 1 is a mockup of a game menu: look at the big orange button (a red-hot ingot) for shape and colors. Image 2 shows the drawing style to copy: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow.

Draw ONE game button with no text: a red-hot iron ingot seen from the front and slightly from above, very wide (about three times wider than tall), hand-drawn, a bit crooked and not symmetric, with soft rounded corners. The front face is a flat warm gradient from molten gold (#FFB703) at the top to ember orange (#F26419) at the bottom; the thin top face is pale yellow (#FFE590). One small dent on an edge. The front face is clean and empty in the middle, because the game writes a word on it.

Thick black ink outline all around, cartoon comic style like image 2. No texture, no realistic reflections, no glow, no flames, no sparks, no shadow on the ground. No text, letters or numbers. Flat pure green background (#00FF00), the ingot centered with a green margin all around.
```

### `pezzo_piastre`

```
Image 1 is a mockup of a game menu: look at the three dark menu buttons on it (forged iron plates) for shapes and colors. Image 2 shows the drawing style to copy: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow.

Draw THREE separate game buttons with no text, stacked one above the other with green space between them. Each is a dark wrought-iron plate hammered by hand, wide (about four times wider than tall), a bit crooked, with soft corners, and each has a different silhouette:
1. the right end is cut like a blunt arrow tip pointing right;
2. a slanted plate, the left end cut at an angle, slightly thicker on one side;
3. a pennant: the right end is cut like a swallow tail (a V-shaped notch).
Color: dark iron (#2B2730) with one lighter flat highlight line along the top edge (#5D5664) and one small rivet at the left end. One or two hammer dents each. The middle of each plate is clean and empty, because the game writes on it.

Thick black ink outline, cartoon comic style like image 2. No texture, no rust, no realistic reflections, no glow, no shadow on the ground. No text, letters or numbers. Flat pure green background (#00FF00).
```

### `pezzo_ghiaccio`

```
Image 1 is a mockup of a game screen: look at the blue button shaped like a shard of ice for shape and colors. Image 2 shows the drawing style to copy: thick slightly irregular ink outline, flat colors, one flat highlight and one flat shadow.

Draw ONE game button with no text: a wide flat shard of ice (about four times wider than tall), angular and irregular like a broken piece of a frozen lake, not symmetric. Color: deep night blue inside (#10283A) with a lighter flat facet along the top (#1C4460), outline in bright glacial cyan (#38B6FF) drawn thick like ink, one thin pale crack line (#CAF0F8) near the right end. The middle is clean and empty, because the game writes on it.

Cartoon comic style like image 2. No texture, no realistic reflections, no glow, no snow, no shadow on the ground. No text, letters or numbers. Flat pure green background (#00FF00), the shard centered with a green margin all around.
```

### `pezzo_pannello`

```
Image 1 is a mockup of a game screen: look at the big dark panel on the right that holds the stats. Image 2 shows the drawing style to copy: thick slightly irregular black ink outline, flat colors.

Draw ONE empty game panel with no text: a big slab of dark slate, almost square, hand-drawn, slightly crooked with soft corners, one small chip missing from one corner. Flat color (#1E1A22) with one lighter flat highlight line along the top edge (#3A3540) and a small rivet in each corner. The inside is completely clean and empty, because the game writes on it.

Thick black ink outline, cartoon comic style like image 2. No texture, no realistic reflections, no glow, no shadow on the ground. No text, letters or numbers. Flat pure green background (#00FF00), the panel centered with a green margin all around.
```

### `pezzo_piccoli`

```
Image 1 and image 2 are mockups of a game menu: look at the small pieces (money plates at the top right, back button at the bottom left, the small ember and flame markers). Image 3 shows the drawing style to copy: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow.

Draw a sheet of EIGHT separate small game pieces with no text, arranged in a grid of 4 columns and 2 rows with wide green space between them, all hand-drawn, a bit crooked and not symmetric:
1. a small dark iron plate, twice as wide as tall (#2B2730);
2. a dark iron plate shaped like a blunt arrow pointing left (a back button);
3. a glowing ember: a small rounded irregular lump, gold (#FFB703) with an orange shadow;
4. a small flame, gold with an orange core, simple teardrop shape leaning to one side;
5. a cold ember: the same lump as 3 but dark grey (#3A3540);
6. a small padlock carved from ice: night blue (#10283A) with cyan outline (#38B6FF);
7. a gold coin with a small flame stamped on it;
8. a cyan ice gem, simple diamond shape with two facets.

Thick black ink outline (cyan outline only on piece 6), cartoon comic style like image 3. No texture, no realistic reflections, no glow, no shadow on the ground. No text, letters or numbers. Flat pure green background (#00FF00).
```

## Criteri di accettazione

- [ ] contorno a china spesso, colori pieni: nessuna texture, sfumatura morbida o bagliore
- [ ] forme morbide e storte, non simmetriche
- [ ] il centro di ogni pulsante è pulito: ci si può scrivere sopra
- [ ] sfondo verde pieno, nessuna ombra sopra
- [ ] in `pezzo_piastre` le tre sagome sono diverse fra loro e ben separate; in `pezzo_piccoli` gli otto pezzi sono separati
- [ ] nessuna scritta o numero

## Dopo le immagini (lo fa Claude)

Toglie il verde, ritaglia i pezzi, li prova nella pagina della proposta al posto delle forme
fatte col codice e li fa vedere a Sergio accanto alla versione di solo codice. Nel gioco i
pezzi vanno in un atlante solo, piccoli e compressi (l'APK resta sotto i 50 MB), con i bordi
lisci su ogni schermo; gli effetti (fiammella, luccichio, scintilla sul filo) restano di codice.

---

## Decisione

Approvata da Claude il 12 nov 2026 su indicazione di Sergio («usa sempre codex per quello che
non riesci a fare»): reversibile, i pezzi si provano nella proposta prima che nel gioco.

## Consegna di Codex

## Resoconto di Claude
