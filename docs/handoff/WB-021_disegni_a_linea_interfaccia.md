# WB-021 · Disegni a linea per l'interfaccia «Filo di brace»

- **Stato:** APPROVATA (Sergio, 2026-11-12: «se ti serve qualcosa da codex fai una scheda»)
- **Data:** 2026-11-12
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-021`

## Obiettivo

Sergio ha scartato lo stile dipinto di WB-020 («troppo dettagliato») e ha scelto un'interfaccia
**minimalista a linee**: pulsanti, pannelli, luci e mappa li disegna il gioco col codice
(proposta https://claude.ai/artifact/2RBh8w9T56E7P9kFDd4HKA). A Codex restano solo i **disegni
veri**, quelli che il codice non sa fare: quattro disegni **a sola linea**, bianchi su nero,
che il gioco colora (caldo o freddo) e mette dietro i menu, molto tenui.

## Cosa teniamo e cosa scartiamo

| Teniamo | Perché |
|---|---|
| Solo linee: bianco puro `#FFFFFF` su nero puro `#000000`, spessore costante | il gioco usa il bianco come trasparenza e ci mette il colore e la luce |
| Poche linee, forme chiuse e semplici, come un'insegna al neon o un'incisione | deve stare dietro le scritte senza disturbare |
| I personaggi riconoscibili dalla sagoma (R2, R3) | sono il Fabbro e Favilla, non figure qualsiasi |

| Scartiamo | Perché |
|---|---|
| Riempimenti, grigi, sfumature, tratteggi, ombre, texture | lo stile di WB-020, scartato |
| Colori | li mette il gioco |
| Scritte, numeri, cornici, firme | il testo lo scrive il gioco |

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-021/riferimenti/R1_stile_linee.png` | una schermata della proposta: lo stile delle linee (incudine, arco, ghiaccioli) |
| R2 | `art/WB-012/scelti/fabbro.png` | il foglio del Fabbro |
| R3 | `art/WB-012/scelti/favilla.png` | il foglio di Favilla |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto: il
primo è "image 1", il secondo "image 2". Sfondo nero pieno (non trasparente, niente chroma).

| Nome file | Riferimenti | Formato | Varianti |
|---|---|---|---|
| `linea_fabbro` | R1, R2 | quadrato | 2 |
| `linea_fucina` | R1 | largo 16:9 | 1 |
| `linea_ghiaccio` | R1 | largo 16:9 | 1 |
| `linea_favilla` | R1, R3 | quadrato | 2 |

### `linea_fabbro`

```
Image 1 shows the line style to follow (the thin outline drawings in the background: anvil, arch, icicles). Image 2 is the model sheet of the Blacksmith: keep his silhouette recognizable (huge square body, horns, big moustache, apron, the furnace grate in his belly), but redraw him with very few lines.

A minimalist single-line drawing: the Blacksmith seen in three-quarter view, standing at an anvil, right arm raised holding a hammer about to strike, left hand holding a piece of metal on the anvil with tongs. Three or four small sparks as tiny lines at the anvil.

Pure white lines (#FFFFFF) of one constant medium thickness on a pure black background (#000000). Outline only: no fills, no gray, no shading, no hatching, no texture, no gradients, no glow. As few lines as possible, clean closed shapes, like a neon sign or a simple engraving. The whole figure inside the picture with a black margin all around. No text, letters, numbers, frame or signature.
```

### `linea_fucina`

```
Image 1 shows the line style to follow (the thin outline drawings in the background: anvil, arch, icicles).

A minimalist single-line drawing, wide 16:9: the inside of a blacksmith's forge. On the LEFT half only: a big stone arch with a furnace mouth and three simple flames inside, a bellows next to it, two chains with hooks hanging from the top, a few tools (hammer, tongs) hanging on the wall, a few brick outlines. The RIGHT half of the picture stays completely empty and black.

Pure white lines (#FFFFFF) of one constant medium thickness on a pure black background (#000000). Outline only: no fills, no gray, no shading, no hatching, no texture, no gradients, no glow. As few lines as possible, clean simple shapes, like a neon sign or a simple engraving. No characters. No text, letters, numbers, frame or signature.
```

### `linea_ghiaccio`

```
Image 1 shows the line style to follow (the thin outline drawings in the background: anvil, arch, icicles).

A minimalist single-line drawing, wide 16:9: a frozen cave at the bottom of hell. On the RIGHT half only: sharp stalactites of ice hanging from the top, a cluster of tall angular ice crystals rising from the ground, a cracked frozen lake drawn with three or four broken lines, a few tiny diamond-shaped snow specks. The LEFT half of the picture stays completely empty and black.

Pure white lines (#FFFFFF) of one constant medium thickness on a pure black background (#000000). Outline only: no fills, no gray, no shading, no hatching, no texture, no gradients, no glow. As few lines as possible, straight angular shapes, like a neon sign or a simple engraving. No characters. No text, letters, numbers, frame or signature.
```

### `linea_favilla`

```
Image 1 shows the line style to follow (the thin outline drawings in the background: anvil, arch, icicles). Image 2 is the model sheet of Favilla: keep her silhouette recognizable (small imp girl, flame hair, overalls, boots, tail), but redraw her with very few lines.

A minimalist single-line drawing: Favilla trapped inside a big angular block of ice, standing still with her eyes closed and her hands together on her chest. The ice block is a simple faceted crystal drawn with straight lines around her, with two or three facet lines.

Pure white lines (#FFFFFF) of one constant medium thickness on a pure black background (#000000). Outline only: no fills, no gray, no shading, no hatching, no texture, no gradients, no glow. As few lines as possible, like a neon sign or a simple engraving. The whole crystal inside the picture with a black margin all around. No text, letters, numbers, frame or signature.
```

## Criteri di accettazione

- [ ] solo bianco e nero: nessun grigio, riempimento, tratteggio o sfumatura
- [ ] spessore della linea costante e simile nei quattro disegni
- [ ] poche linee: si capisce cos'è anche piccolo e tenue
- [ ] Fabbro e Favilla riconoscibili dalla sagoma
- [ ] `linea_fucina` ha la metà destra vuota, `linea_ghiaccio` la metà sinistra vuota
- [ ] nessuna scritta, numero, cornice o firma

## Dopo le immagini (lo fa Claude)

Trasforma il bianco in trasparenza, li rimpicciolisce e li comprime (un solo canale: pesano
pochissimo, l'APK resta sotto i 50 MB), li mette dietro i menu colorati di caldo e di freddo e
li fa vedere a Sergio nella pagina della proposta prima di metterli nel gioco.

---

## Decisione

Approvata da Claude il 12 nov 2026 su richiesta di Sergio («se ti serve qualcosa da codex fai
una scheda»): scheda reversibile, i disegni si provano nella proposta prima che nel gioco.

## Consegna di Codex

Sei disegni generati con ImageGen dai prompt integrali della scheda. Accanto a ogni PNG, il TXT omonimo contiene il prompt e i riferimenti nell'ordine allegato.

| File in `art/WB-021/` | Tentativi | Controllo visivo |
|---|---:|---|
| `linea_fabbro_1.png` e `linea_fabbro_1.txt` | 3 | Figura intera, martello alzato, tenaglie, incudine e tre scintille. Ciminiera con fumo. |
| `linea_fabbro_2.png` e `linea_fabbro_2.txt` | 3 | Figura intera, martello alzato, tenaglie, incudine e tre scintille. Ciminiera senza fumo. |
| `linea_fucina.png` e `linea_fucina.txt` | 1 | Arco, tre fiamme, mantice, catene e utensili. Metà destra interamente nera. |
| `linea_ghiaccio.png` e `linea_ghiaccio.txt` | 1 | Stalattiti, cristalli, crepe e tre rombi pieni. Metà sinistra interamente nera. |
| `linea_favilla_1.png` e `linea_favilla_1.txt` | 2 | Cristallo intero con tre facce delineate, occhi chiusi e mani sul petto. |
| `linea_favilla_2.png` e `linea_favilla_2.txt` | 1 | Cristallo intero con due facce delineate, occhi chiusi e mani sul petto. |

Esportati in nero e bianco puro con soglia al 50% per eliminare i grigi del generatore. Il Fabbro è uscito a 1312 × 1199 anche al terzo tentativo. Aggiunto solo margine nero sopra e sotto per ottenere 1312 × 1312 senza deformare o tagliare il disegno. Favilla è a 1254 × 1254 e le due scene a 1672 × 941. Verificati i margini dei personaggi e, a livello di pixel, le metà nere delle scene.

A vista non ci sono scritte, numeri, cornici o firme. Restano piccoli dettagli pieni (rivetti, sopracciglia o palpebre e rombi di neve), differenze locali di spessore e la punta della coda di Favilla più appuntita rispetto a R3. La leggibilità in piccolo e a bassa opacità resta da verificare nei menu.

## Resoconto di Claude
