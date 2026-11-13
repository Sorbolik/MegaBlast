# WB-039 · Le nove teste senza corna e le corna a parte (per elmi)

- **Stato:** APPROVATA (Sergio, 13 nov: «Ok, 1»)
- **Data:** 2026-11-13
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-039`

## Obiettivo

Nelle nove teste di WB-037 (`teste_1`, scelte) le corna sono dipinte attaccate al cranio, così un
elmo non le può togliere né far passare. Serve lo **stesso foglio senza corna** (cranio liscio
e chiuso dove stavano) e **le corna da sole**, nella stessa posizione: Claude le separa per
differenza, come il fazzoletto, e controlla in automatico che tutto combaci al pixel.
Ordine in gioco (dal fondo): cranio, faccia, elmo, corna, fiamma.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-039/riferimenti/R1_teste_scelte.png` | le nove teste scelte di WB-037: il foglio da modificare |
| R2 | `art/WB-039/riferimenti/R2_tre_quarti_scelto.png` | l'apprendista scelto, per le corna |

## Immagini da generare

| Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|
| `art/WB-039/teste_senza_corna.png` | R1, R2 | 1024×1024 | 2 |
| `art/WB-039/corna.png` | R1, R2 | 1024×1024 | 2 |

Le varianti si chiamano `teste_senza_corna_1.png`, `teste_senza_corna_2.png` e così via.

### Regole comuni (in fondo a ogni prompt, così come sono)

```
Rendering rules, very strict, because these parts will be traced into vector shapes and compared pixel by pixel with image 1:
- Keep EXACTLY the canvas, size and position of image 1: same 1024x1024 square, same 3 by 3 grid, every head in the same place and the same size as in image 1. Do not move, resize, recenter or redraw anything that is not asked.
- FLAT COLORS ONLY, the same as image 1: outline black #000000; skin #B8432A, skin shadow #8E2F1C; muzzle #F1DFB0, its shadow #D6BC86; horns #EFE3C8, their shadow #C9B48E; eyes #F2C45A with white #FFFFFF highlight; mouth #5A1A10, tongue #E0605A. No gradients, no textures, no glow.
- Background: flat pure magenta #FF00FF everywhere, with no halo.
- No text, numbers, labels, arrows or signatures.
```

### `teste_senza_corna`

```
Image 1 is a sheet of nine heads of our little devil, the main character of our game. Image 2 is the whole character.

Redraw image 1 EXACTLY, identical in every line, color and position, with ONE change: on all nine heads REMOVE THE TWO HORNS. Where each horn was, the top of the skull continues as plain smooth skin #B8432A, following the round shape of the skull, closed by the same thick black outline as the rest of the head, as if he had never had horns. No bumps, no holes, no stumps, no marks where the horns were. Everything else stays exactly as in image 1: the head outline, the ears, the faces, the eyes, the mouths, the shadows, the size and the position of every head on the canvas.
```
+ regole comuni.

### `corna`

```
Image 1 is a sheet of nine heads of our little devil, the main character of our game. Image 2 is the whole character.

Draw ONLY THE HORNS of the FIRST head of image 1 (top left), alone on the flat magenta background: the two horns exactly as in image 1, same shape, same size, same colors and shading, and in EXACTLY the same place on the canvas as in image 1, as if the head had been erased and only its horns were left. Nothing else on the canvas: no head, no ears, no face, no other heads.
Each horn continues a little further DOWN into where the skull was, about one fifth of its height, with its base rounded and full, so it can sit inside the skull. At this base the black outline gets gradually thinner and disappears completely: the bottom stretch of each horn is plain horn color #EFE3C8 right to the edge, with no black line across it and no shadow.
```
+ regole comuni.

## Criteri di accettazione

- [ ] `teste_senza_corna`: stesso foglio di R1, teste nella stessa posizione e misura, nessuna traccia delle corna, cranio liscio e chiuso dal contorno
- [ ] `corna`: solo le due corna della prima testa, nella posizione di R1, base che scende nel cranio senza contorno
- [ ] colori piatti della tavolozza, sfondo magenta pulito, nessuna scritta

---

## Decisione

Approvata da Sergio il 13 nov («Ok, 1»: testa senza corna fatta da Codex e controllata in automatico, così elmi e corna stanno su strati a parte).

## Consegna di Codex

- `art/WB-039/teste_senza_corna_1.png` e `art/WB-039/teste_senza_corna_2.png` — due fogli con tutte e nove le espressioni, senza corna e con il profilo superiore del cranio chiuso.
- `art/WB-039/corna_1.png` e `art/WB-039/corna_2.png` — due coppie isolate nell'angolo in alto a sinistra, con il bordo nero interrotto alla base. L'estensione delle basi dentro il cranio è breve, soprattutto sul corno destro, e l'ombra raggiunge la base in alcuni punti.
- Accanto a ciascun PNG c'è il TXT con il prompt originale, le regole comuni e i riferimenti nell'ordine R1, R2.

Eseguiti tre tentativi per ciascun prompt. Per le teste sono stati scelti i tentativi 1 e 2, per le corna i tentativi 1 e 3. Tutti i PNG consegnati sono RGB, 1024 × 1024, ridimensionati uniformemente dall'uscita del generatore (1254 × 1254).

Controllo visivo dei quattro PNG: griglia 3 × 3 nei fogli delle teste, due corna isolate nei fogli delle corna, sfondo magenta, nessuna scritta. Il magenta ha variazioni e la tavolozza non coincide esattamente con i valori richiesti. La griglia e la posizione delle corna sono vicine a R1. Il confronto con R1 nelle fasce delle facce, fuori dalle zone delle corna, ha rilevato differenze di pixel in entrambe le varianti (scarto mediano di 3 e 4 livelli sul canale con lo scarto maggiore, su 255). La corrispondenza al pixel resta da ottenere prima di usare la separazione per differenza.

## Resoconto di Claude
