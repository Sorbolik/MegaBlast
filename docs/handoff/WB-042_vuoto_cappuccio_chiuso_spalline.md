# WB-042 · Il Vuoto: cappuccio chiuso e spalline

- **Stato:** PROPOSTA
- **Data:** 2026-11-14
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-042`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-042` senza chiedere conferma (il repository è privato).

## Obiettivo

Le corna adesso sono un pezzo a parte, disegnato sopra l'elmo (14 nov). Così il cappuccio del
Vuoto (WB-041) non ha più bisogno dei buchi in alto, che si vedono: va **chiuso**, con la stessa
sagoma. Sergio vuole anche le **spalline** della corazza, sopra la spalla di ogni braccio, adatte
alle bende del Vuoto. Come in WB-041 ogni pezzo si disegna sul foglio che veste, nella stessa
posizione, così si ritaglia per differenza e calza senza metterlo a occhio.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-042/riferimenti/R1_teste_senza_corna.png` | le nove teste senza corna (WB-039) |
| R2 | `art/WB-042/riferimenti/R2_vuoto.png` | la tavola scelta del Vuoto: a sinistra base, a destra forgiata |
| R3 | `art/WB-042/riferimenti/R3_cappuccio_base.png` | il cappuccio base di WB-041 sulla prima testa (coi buchi) |
| R4 | `art/WB-042/riferimenti/R4_cappuccio_forgiata.png` | il cappuccio forgiato di WB-041 (coi buchi) |
| R5 | `art/WB-042/riferimenti/R5_corpo_base.png` | il foglio del corpo con corazza e stivali base di WB-041 |
| R6 | `art/WB-042/riferimenti/R6_corpo_forgiata.png` | il foglio del corpo con corazza e stivali forgiati di WB-041 |
| R7 | `art/WB-042/riferimenti/R7_pugni.png` | le due braccia col pugno chiuso (WB-037), per le armi |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Si lavora SOPRA il foglio indicato: stesso foglio,
stessa misura, tutto il resto identico.

| Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|
| `art/WB-042/cappuccio_base.png` | R3, R2 | come R3 | 1 |
| `art/WB-042/cappuccio_forgiata.png` | R4, R2 | come R4 | 1 |
| `art/WB-042/spalline_base.png` | R5, R2 | 1536×1024 | 2 |
| `art/WB-042/spalline_forgiata.png` | R6, R2, `spalline_base_N.png` scelto | 1536×1024 | 1 |
| `art/WB-042/pugni_spalline_base.png` | R7, `spalline_base_N.png` scelto | 1536×1024 | 1 |
| `art/WB-042/pugni_spalline_forgiata.png` | R7, `spalline_forgiata.png` | 1536×1024 | 1 |

Le varianti si chiamano `spalline_base_1.png`, `spalline_base_2.png`. Codex sceglie la base con il
resto del foglio più identico a R5 e lo scrive nel `.txt`; le forgiate e i pugni partono da quella.

### `cappuccio_base`

```
Image 1 is a sheet of nine heads of our character on flat magenta; the first head (top left) wears a dark indigo hood with three small round openings on top. Image 2 is the chosen armour set "Void" of our game (left: BASIC form).

Return image 1 again, the SAME sheet: every head exactly where it is, same size, same faces, same pixels, and the hood with exactly the same outline. Change only one thing: CLOSE the three small openings on top of the hood, filling them with the same indigo cloth, so the hood is one closed piece of cloth with a clean rounded top. Horns and the head flame will be drawn later on top of the hood as separate parts: draw no horns, no flame and no holes. The other eight heads do not change at all.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Cloth indigo #2B2147 with folds #1A1430, thick closed black #000000 outline like the heads.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `cappuccio_forgiata`

```
Image 1 is a sheet of nine heads of our character on flat magenta; the first head (top left) wears the FORGED indigo hood with the cyan eye emblem, a cyan trim around the face and a small opening on top. Image 2 is the chosen armour set "Void" (right: FORGED form).

Return image 1 again, the SAME sheet: every head exactly where it is, same size, same faces, same pixels, and the hood with exactly the same outline, emblem and trim. Change only one thing: CLOSE every opening on top of the hood, filling it with the same indigo cloth, so the hood is one closed piece of cloth with a clean rounded top. Draw no horns, no flame and no holes. The other eight heads do not change at all.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Cloth indigo #2B2147 with folds #1A1430, thick closed black #000000 outline, cyan #00FFFF trims, white #FFFFFF and black only inside the eye emblem.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `spalline_base`

```
Image 1 is a sheet of body parts of our character on flat magenta: the torso wears the BASIC "Void" armour (dark indigo bandages crossing over the chest, round cyan eye clasp), the legs wear indigo boots, and below there are two bare arms, the tail and a fist. Image 2 is the chosen armour set "Void" (left: BASIC form).

Edit image 1 and return the SAME sheet: every part exactly where it is, same size, same shapes, same pixels. Change only the TWO ARMS: on the top of each arm, over the shoulder, draw a SHOULDER PAD that belongs to this armour: a rounded cap of the same dark indigo bandages, wrapped around the top of the upper arm in two or three overlapping bands, with a thin cyan edge at the bottom of the pad. The pad covers the rounded top of the arm and the upper part of the upper arm, follows the arm's outline and is a little wider than the arm; the rest of the arm, the hand and the fingers stay bare and unchanged. Both arms get the same pad. The torso, the boots, the neckerchief, the tail and the fist do not change at all.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Cloth indigo #2B2147 with folds #1A1430, thick closed black #000000 outline like the other parts, cyan #00FFFF trims.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `spalline_forgiata`

```
Image 1 is a sheet of body parts of our character on flat magenta, wearing the FORGED "Void" armour on the torso and forged boots. Image 2 is the chosen armour set "Void" (right: FORGED form). Image 3 is the same sheet in the basic form, with indigo shoulder pads drawn on the top of both arms.

Edit image 1 and return the SAME sheet: every part exactly where it is, same size, same shapes, same pixels. Change only the TWO ARMS: on the top of each arm draw the FORGED version of the shoulder pad of image 3, with the same outline as in image 3, plus the forged details of image 2: a pointed cyan edge at the top of the pad, like the pointed cyan shoulder edges of the forged torso, and a thin cyan trim along the bands. Both arms get the same pad; the rest of each arm stays bare and unchanged. Nothing else on the sheet changes.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Cloth indigo #2B2147 with folds #1A1430, thick closed black #000000 outline, cyan #00FFFF trims.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `pugni_spalline_base`

```
Image 1 is a sheet with two arms of our character with a closed fist, on flat magenta. Image 2 is a sheet of the same character where both bare arms wear a dark indigo shoulder pad.

Edit image 1 and return the SAME sheet: both arms exactly where they are, same size, same shapes, same pixels. Change only the top of each arm: put on it the SAME shoulder pad as on the arms of image 2, same shape, same bands, same colours, same size relative to the arm, over the shoulder. The rest of each arm and the fist stay bare and unchanged.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Cloth indigo #2B2147 with folds #1A1430, thick closed black #000000 outline like the arms, cyan #00FFFF trims.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `pugni_spalline_forgiata`

```
Image 1 is a sheet with two arms of our character with a closed fist, on flat magenta. Image 2 is a sheet of the same character where both arms wear the FORGED indigo shoulder pad with pointed cyan edge.

Edit image 1 and return the SAME sheet: both arms exactly where they are, same size, same shapes, same pixels. Change only the top of each arm: put on it the SAME forged shoulder pad as on the arms of image 2, same shape, same bands, same cyan details, same size relative to the arm. The rest of each arm and the fist stay bare and unchanged.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Cloth indigo #2B2147 with folds #1A1430, thick closed black #000000 outline like the arms, cyan #00FFFF trims.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

## Criteri di accettazione

- [ ] ogni foglio è il suo riferimento identico (stessi pezzi, stesse posizioni, stessa misura) tranne il pezzo da cambiare
- [ ] il cappuccio ha la stessa sagoma di WB-041 ed è chiuso: niente buchi, niente corna, niente fiamma
- [ ] le spalline stanno in cima a tutte e due le braccia (anche quelle col pugno), uguali, un po' più larghe del braccio; mano e dita nude e uguali
- [ ] colori piatti, contorno nero chiuso e spesso, magenta pulito, nessuna scritta
- [ ] le forgiate hanno le stesse sagome delle basi, con le finiture ciano

---

## Decisione

In attesa del via di Sergio.

## Consegna di Codex

## Resoconto di Claude
