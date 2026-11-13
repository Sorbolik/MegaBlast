# WB-040 · Le palpebre sulle teste senza corna (battito degli occhi)

- **Stato:** APPROVATA (Sergio, 13 nov: «Sì, scheda WB-040»)
- **Data:** 2026-11-13
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-040`

## Obiettivo

Il battito degli occhi in Godot scambia il disegno degli occhi: aperti, socchiusi, chiusi. Le
teste di `palpebre` di WB-037 non combaciano con le nove teste scelte (sono più larghe), quindi
servono le palpebre disegnate **sullo stesso foglio** delle teste senza corna (WB-039, variante
2), come la modifica di WB-039 che ha lasciato tutto fermo al pixel. Claude prende solo la zona
degli occhi e controlla in automatico che il resto sia identico.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-040/riferimenti/R1_teste_senza_corna.png` | le nove teste senza corna scelte (WB-039 n. 2): il foglio da modificare |

## Immagini da generare

| Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|
| `art/WB-040/occhi_socchiusi.png` | R1 | 1024×1024 | 2 |
| `art/WB-040/occhi_chiusi.png` | R1 | 1024×1024 | 2 |

Le varianti si chiamano `occhi_socchiusi_1.png`, `occhi_socchiusi_2.png` e così via.

### Regole comuni (in fondo a ogni prompt, così come sono)

```
Rendering rules, very strict, because these heads will be compared pixel by pixel with image 1:
- Keep EXACTLY the canvas, size and position of image 1: same 1024x1024 square, same 3 by 3 grid, every head in the same place and the same size as in image 1. Do not move, resize, recenter or redraw anything that is not asked: the head outline, ears, muzzle, mouth, eyebrows, wrinkles and shadows stay identical, line by line.
- Change ONLY the eyes of these heads: 1 (top left), 5 (center), 6 (middle right), 7 (bottom left), 8 (bottom center), 9 (bottom right). Heads 2, 3 and 4 stay exactly as they are (their eyes are already shut or spiral). On heads 5 and 9 an eye that is already winking stays as it is: change only the open eye.
- FLAT COLORS ONLY, the same as image 1: outline black #000000; skin #B8432A, skin shadow #8E2F1C; muzzle #F1DFB0, its shadow #D6BC86; eyes #F2C45A with white #FFFFFF highlight; mouth #5A1A10, tongue #E0605A. No gradients, no textures, no glow.
- Background: flat pure magenta #FF00FF everywhere, with no halo.
- No text, numbers, labels, arrows or signatures.
```

### `occhi_socchiusi`

```
Image 1 is a sheet of nine heads of our little devil, the main character of our game, without horns.

Redraw image 1 EXACTLY, with ONE change on the heads listed below: the eyes are HALF CLOSED, as in the middle of a blink. The upper eyelid, in skin color #B8432A, comes down over the top half of each open eye, with a thin black lash line along its lower edge; the bottom half of the eye is still visible, with the pupil in the same place, cut by the eyelid. The outline of the eye stays exactly where it is.
```
+ regole comuni.

### `occhi_chiusi`

```
Image 1 is a sheet of nine heads of our little devil, the main character of our game, without horns.

Redraw image 1 EXACTLY, with ONE change on the heads listed below: the eyes are CLOSED, as at the bottom of a blink. The upper eyelid, in skin color #B8432A, covers each open eye completely: inside the eye shape there is only skin, and a gently curved black line where the eye closes, in the lower part of the eye shape. No yellow and no pupil left visible. Nothing outside the eye shapes changes.
```
+ regole comuni.

## Criteri di accettazione

- [ ] stesso foglio di R1: fuori dagli occhi niente cambia (controllo al pixel)
- [ ] socchiusi: palpebra a metà, pupilla visibile sotto; chiusi: solo la riga curva
- [ ] teste 2, 3, 4 identiche; l'occhio già strizzato delle teste 5 e 9 uguale
- [ ] colori piatti, sfondo magenta pulito, nessuna scritta

---

## Decisione

Approvata da Sergio il 13 nov (scheda di scelta in thread: «Sì, scheda WB-040»).

## Consegna di Codex

Quattro varianti per revisione. Ciascuna ha richiesto tre tentativi con lo stesso prompt e con R1 come riferimento.

| Variante | Immagine | Prompt e riferimento | Pixel diversi da R1 fuori dai riquadri degli occhi |
|---|---|---|---:|
| Socchiusi 1 | `art/WB-040/occhi_socchiusi_1.png` | `occhi_socchiusi_1.txt` | 967.048 su 977.965 |
| Socchiusi 2 | `art/WB-040/occhi_socchiusi_2.png` | `occhi_socchiusi_2.txt` | 951.209 su 977.965 |
| Chiusi 1 | `art/WB-040/occhi_chiusi_1.png` | `occhi_chiusi_1.txt` | 967.499 su 977.965 |
| Chiusi 2 | `art/WB-040/occhi_chiusi_2.png` | `occhi_chiusi_2.txt` | 963.925 su 977.965 |

- Verifica visiva delle nove teste, delle palpebre, dello sfondo magenta e dell'assenza di scritte. I PNG generati erano 1254×1254 e sono stati ridimensionati a 1024×1024 per la consegna.
- Il confronto RGB usa sei riquadri che comprendono gli occhi da modificare. Anche fuori da questi riquadri cambiano molti pixel, compresi quelli delle teste 2, 3 e 4. Lo sfondo non è magenta puro e l'identità degli occhi già strizzati non è stata verificata separatamente. Il criterio di identità al pixel risulta fallito in ogni variante.
- Integrazione e prova in Godot non eseguite.

## Resoconto di Claude
