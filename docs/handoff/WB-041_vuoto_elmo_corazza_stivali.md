# WB-041 · Il Vuoto addosso all'apprendista nuovo: cappuccio, corazza, stivali

- **Stato:** PROPOSTA
- **Data:** 2026-11-13
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-041`

## Obiettivo

Sergio vuole vedere i pezzi addosso all'apprendista (13 nov). Il mantello del Vuoto c'è già
(WB-032 B, colletto WB-038). Mancano il **cappuccio** (elmo), la **corazza** (le bende incrociate)
e gli **stivali**, nelle due forme di WB-019 (base e forgiata). Ogni pezzo si disegna **sul
foglio dell'apprendista nuovo**, sopra il pezzo che veste, nella stessa posizione: il cappuccio
sulle teste senza corna di WB-039, corazza e stivali sul foglio del corpo di WB-037. Così ogni
pezzo si ritaglia per differenza e calza senza metterlo a occhio. Le corna (WB-039) stanno sopra il
cappuccio, come nella tavola del Vuoto; la fiamma esce dal cappuccio fra le corna.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-041/riferimenti/R1_corpo_collo_nudo.png` | il foglio del corpo di WB-037 (`corpo_1`): busto col collo nudo, braccia, gambe, coda, pugno |
| R2 | `art/WB-041/riferimenti/R2_teste_senza_corna.png` | le nove teste senza corna di WB-039 |
| R3 | `art/WB-019/scelti/vuoto.png` | la tavola scelta del Vuoto: a sinistra base, a destra forgiata |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Si lavora SOPRA R1 o R2: stesso foglio, stessa misura.

| Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|
| `art/WB-041/cappuccio_base.png` | R2, R3 | 1024×1024 | 2 |
| `art/WB-041/cappuccio_forgiata.png` | R2, R3, `cappuccio_base_N.png` scelto | 1024×1024 | 1 |
| `art/WB-041/corpo_base.png` | R1, R3 | 1536×1024 | 2 |
| `art/WB-041/corpo_forgiata.png` | R1, R3, `corpo_base_N.png` scelto | 1536×1024 | 1 |

Le varianti si chiamano `cappuccio_base_1.png`, `cappuccio_base_2.png` e così via. Le forgiate
partono dalla base migliore (Codex sceglie quella con i pezzi sotto più identici a R1 o R2 e lo
scrive nel `.txt`).

### `cappuccio_base`

```
Image 1 is a sheet of nine heads of our character on flat magenta (the same head with nine faces, no horns). Image 2 is the chosen armour set "Void" of our game: left the BASIC form, right the FORGED form.

Edit image 1 and return the SAME sheet: all nine heads stay exactly where they are, same size, same shapes, same faces, same pixels. Change only the FIRST head (top left): put on it the HOOD of the BASIC form of image 2. The hood covers the top and the back of the head and frames the face, which stays fully visible and unchanged; the pointed ears come out of the hood on the sides. On top of the hood, where the horns of image 2 come out, leave two small round openings and a third small opening in the middle between them (horns and the head flame will be drawn later on top of the hood, as separate parts): draw no horns and no flame. The other eight heads do not change at all.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Cloth indigo #2B2147 with folds #1A1430, thick closed black #000000 outline like the heads.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `cappuccio_forgiata`

```
Image 1 is a sheet of nine heads of our character. Image 2 is the chosen armour set "Void" (right: FORGED form). Image 3 is image 1 with the basic hood already drawn on the first head.

Return image 3 again, the SAME sheet with every head exactly where it is and the same pixels, and change only the hood on the first head: make it the FORGED hood of image 2, with the same outline and the same openings as in image 3, plus the cyan eye emblem on the front of the hood and a thin pure cyan #00FFFF trim along its edge around the face. Nothing else on the sheet changes. No horns, no flame.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Cloth indigo #2B2147 with folds #1A1430, thick closed black #000000 outline, cyan #00FFFF trims, white #FFFFFF and black only inside the eye emblem.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `corpo_base`

```
Image 1 is a sheet of body parts of our character on flat magenta: the green neckerchief at the top, the torso with a bare neck in the middle, the tail, two arms, two legs and a fist below. Image 2 is the chosen armour set "Void" of our game: left the BASIC form, right the FORGED form.

Edit image 1 and return the SAME sheet: every part stays exactly where it is, same size, same shapes, same colors, same pixels. Change only these:
1. On the torso: the ARMOUR of the BASIC form of image 2, the dark indigo bandages wrapped across the chest and the belly in crossing diagonal bands, with the round cyan eye clasp in the middle of the chest. The armour follows the outline of the torso exactly and leaves the bare neck stub free; the belly colour shows only where the bandages leave small gaps.
2. On BOTH legs: the BOOTS of the BASIC form of image 2, dark indigo, covering the feet and the lower part of the leg up to the middle of the shin, with a cyan band at the top. The toes are hidden inside the boots; the boots keep the shape of the foot.
The neckerchief, the arms, the tail and the fist do not change at all.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Cloth indigo #2B2147 with folds #1A1430, thick closed black #000000 outline like the other parts, cyan #00FFFF trims, white #FFFFFF and black only inside the eye clasp.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `corpo_forgiata`

```
Image 1 is a sheet of body parts of our character. Image 2 is the chosen armour set "Void" (right: FORGED form). Image 3 is image 1 with the basic armour on the torso and the basic boots on both legs.

Return image 3 again, the SAME sheet with every part exactly where it is and the same pixels, and change only the armour and the boots: make them the FORGED armour and boots of image 2, with the same outlines as in image 3: on the armour add the two pointed cyan shoulder edges of image 2 at the top of the torso and a thin cyan trim along the bandages; on the boots a double cyan band with the round cyan studs of image 2. Nothing else on the sheet changes.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Cloth indigo #2B2147 with folds #1A1430, thick closed black #000000 outline, cyan #00FFFF trims, white #FFFFFF and black only inside the eye clasp.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

## Criteri di accettazione

- [ ] ogni foglio è R1 o R2 identico (stessi pezzi, stesse posizioni, stessa misura) tranne i pezzi del Vuoto
- [ ] il cappuccio solo sulla prima testa, faccia intera e uguale, orecchie fuori, tre aperture in alto, niente corna né fiamma
- [ ] la corazza segue il busto e lascia libero il collo; gli stivali su tutte e due le gambe, con la forma del piede
- [ ] colori piatti, contorno nero chiuso e spesso, magenta pulito, nessuna scritta
- [ ] le forgiate hanno le stesse sagome delle basi, con le finiture ciano

---

## Decisione

In attesa di Sergio.

## Consegna di Codex

## Resoconto di Claude
