# WB-070 · I guanti: il quinto pezzo, per le cinque famiglie

- **Stato:** APPROVATA (Sergio, 18 nov: «sisi, preparala»)
- **Data:** 2026-11-18
- **Ramo della scheda:** `claude/project-thread-rc20kg` (eseguila da questo ramo: `git fetch origin claude/project-thread-rc20kg`) · **Ramo delle immagini:** `design/WB-070`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-070` senza chiedere conferma (il repository è privato).

## Obiettivo

Con l'economia del 17 nov ogni statistica deve venire da tante fonti (Sergio: «se necessario
aggiungiamo i guanti»). I **GUANTI** sono il quinto posto dell'equipaggiamento, dopo ELMO, CORAZZA,
MANTELLO e STIVALI: il loro mestiere è la **spinta dei colpi** (il più) e l'**Attacco** (il secondo).
Servono i guanti delle cinque famiglie, in due forme (base e forgiata), addosso all'apprendista e
come icone.

Come per gli altri pezzi addosso (WB-055…058), ogni guanto si disegna **sul foglio dell'apprendista
che veste, nella stessa posizione**, così si ritaglia per differenza e calza senza metterlo a occhio.
I fogli sono due: quello del corpo (le due braccia con la mano aperta) e quello delle due braccia col
pugno chiuso, che è la mano che tiene le armi. Il guanto copre **solo la mano e il polso**: la spalla
resta nuda, perché lì va la spallina della corazza.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-070/riferimenti/R1_corpo.png` | il foglio del corpo dell'apprendista (WB-037): in basso le due braccia con la mano aperta |
| R2 | `art/WB-070/riferimenti/R2_pugni.png` | le due braccia col pugno chiuso (WB-037): la mano che tiene le armi |
| R3 | `art/WB-070/riferimenti/R3_<famiglia>.png` | la tavola scelta di quella famiglia (WB-019): a sinistra base, a destra forgiata; solo per materiali e colori |
| R4 | `art/WB-070/riferimenti/R4_icona_esempio.png` | un'icona dell'inventario (WB-043): stile e misura delle icone |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Tutto va in `art/WB-070/`, ogni PNG col suo `.txt`
del prompt. Per corpo e pugni si lavora SOPRA il foglio indicato: stesso foglio, stessa misura,
tutto il resto identico.

| Nome file | Riferimenti (in quest'ordine) | Misura | Varianti |
|---|---|---|---|
| `fabbro_corpo_base.png` | R1, R3_fabbro | come R1 | 2 |
| `fabbro_corpo_forgiata.png` | `fabbro_corpo_base_N.png` scelto, R3_fabbro | come R1 | 1 |
| `fabbro_pugni_base.png` | R2, `fabbro_corpo_base_N.png` scelto | 1536×1024 | 1 |
| `fabbro_pugni_forgiata.png` | `fabbro_pugni_base.png`, `fabbro_corpo_forgiata.png` | 1536×1024 | 1 |
| `corvo_corpo_base.png` | R1, R3_corvo | come R1 | 2 |
| `corvo_corpo_forgiata.png` | `corvo_corpo_base_N.png` scelto, R3_corvo | come R1 | 1 |
| `corvo_pugni_base.png` | R2, `corvo_corpo_base_N.png` scelto | 1536×1024 | 1 |
| `corvo_pugni_forgiata.png` | `corvo_pugni_base.png`, `corvo_corpo_forgiata.png` | 1536×1024 | 1 |
| `fornace_corpo_base.png` | R1, R3_fornace | come R1 | 2 |
| `fornace_corpo_forgiata.png` | `fornace_corpo_base_N.png` scelto, R3_fornace | come R1 | 1 |
| `fornace_pugni_base.png` | R2, `fornace_corpo_base_N.png` scelto | 1536×1024 | 1 |
| `fornace_pugni_forgiata.png` | `fornace_pugni_base.png`, `fornace_corpo_forgiata.png` | 1536×1024 | 1 |
| `leviatano_corpo_base.png` | R1, R3_leviatano | come R1 | 2 |
| `leviatano_corpo_forgiata.png` | `leviatano_corpo_base_N.png` scelto, R3_leviatano | come R1 | 1 |
| `leviatano_pugni_base.png` | R2, `leviatano_corpo_base_N.png` scelto | 1536×1024 | 1 |
| `leviatano_pugni_forgiata.png` | `leviatano_pugni_base.png`, `leviatano_corpo_forgiata.png` | 1536×1024 | 1 |
| `vuoto_corpo_base.png` | R1, R3_vuoto | come R1 | 2 |
| `vuoto_corpo_forgiata.png` | `vuoto_corpo_base_N.png` scelto, R3_vuoto | come R1 | 1 |
| `vuoto_pugni_base.png` | R2, `vuoto_corpo_base_N.png` scelto | 1536×1024 | 1 |
| `vuoto_pugni_forgiata.png` | `vuoto_pugni_base.png`, `vuoto_corpo_forgiata.png` | 1536×1024 | 1 |
| `icone_guanti.png` | R4, i cinque `<famiglia>_pugni_base.png` e `<famiglia>_pugni_forgiata.png` | 1536×1024 | 1 |
| `sagoma_vuota_guanti.png` | R4 | 1024×1024 | 1 |

Le varianti si chiamano `fabbro_corpo_base_1.png`, `fabbro_corpo_base_2.png`. Codex sceglie la base
col resto del foglio più identico a R1 e lo scrive nel `.txt`; forgiate e pugni partono da quella.
In tutto 27 immagini. I guanti delle famiglie:

- **Fabbro**: cuoio scuro col risvolto chiaro e una borchia d'ottone; forgiata: fascia d'ottone con due borchie ciano e piastra sulle nocche.
- **Corvo**: piume ardesia col filo ciano al polso e artigli corti; forgiata: tre piume a ventaglio sul polso.
- **Fornace**: piastre di ferro grigio con la fascia ciano e una borchia; forgiata: la grata arancione sul dorso.
- **Leviatano**: squame verde acqua con la fascia ciano; forgiata: una pinna chiara sul polso.
- **Vuoto**: bende viola scuro con la fascia ciano; forgiata: l'occhio ciano sul dorso.

### `fabbro_corpo_base`

```
Image 1 is a sheet with the body parts of our character on flat magenta: among them two arms with an open hand. Image 2 is the chosen armour set "Smith" of our game: left the BASIC form, right the FORGED form. Use image 2 only for materials and colors.

Edit image 1 and return the SAME sheet: every part stays exactly where it is, same size, same shapes, same pixels. Change ONLY the hand and the wrist of the two arms with the open hand: put a GLOVE on each hand. The gloves are thick blacksmith work gloves of dark brown leather #6B4A2B with a wide turned-up cuff of lighter leather #C89255 around the wrist and one small round brass #D9A441 stud on the back of the hand. Each glove covers the whole hand, fingers and thumb included, and ends at the wrist with its cuff; it follows the shape of the hand exactly and is only slightly thicker than it. The forearm above the cuff, the elbow, the upper arm and the shoulder stay bare red skin, unchanged. Do NOT add anything else: no sleeves, no shoulder pads, no armour on the arm, nothing on the other parts of the sheet.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Thick closed pure black #000000 outline, the same weight as the outline of the arms.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `fabbro_corpo_forgiata`

```
Image 1 is a sheet with the body parts of our character on flat magenta; the two arms with an open hand wear the BASIC gloves of the set "Smith". Image 2 is that armour set: left the BASIC form, right the FORGED form. Use image 2 only for materials and colors.

Edit image 1 and return the SAME sheet: every part stays exactly where it is, same size, same shapes, same pixels. Change ONLY the two gloves, into their FORGED form: the same gloves, plus a brass #D9A441 band around the cuff with two round cyan #19E6E6 rivets and a brass plate over the knuckles. Same glove shape, same size, same place: only the finishing touches are added. The arms above the cuff stay bare and unchanged. Do NOT add anything else.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Thick closed pure black #000000 outline, the same weight as the outline of the arms.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `fabbro_pugni_base`

```
Image 1 is a sheet with two arms of our character with a closed fist, on flat magenta. Image 2 is another sheet of the same character where the two arms with an open hand wear gloves.

Edit image 1 and return the SAME sheet: both arms exactly where they are, same size, same shapes. Change ONLY the fist and the wrist of each arm: put on each fist the SAME glove of image 2, closed into a fist: thick blacksmith work gloves of dark brown leather #6B4A2B with a wide turned-up cuff of lighter leather #C89255 around the wrist and one small round brass #D9A441 stud on the back of the hand. The glove covers the whole fist, fingers and thumb included, keeps the same finger lines of the fist of image 1 and ends at the wrist with its cuff. The forearm above the cuff, the upper arm and the shoulder stay bare red skin, unchanged. Do NOT add anything else: no sleeves, no shoulder pads.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Thick closed pure black #000000 outline, the same weight as the outline of the arms.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `fabbro_pugni_forgiata`

```
Image 1 is a sheet with two arms of our character with a closed fist wearing the BASIC gloves of the set "Smith", on flat magenta. Image 2 is another sheet of the same character where the two arms with an open hand wear the FORGED form of those gloves.

Edit image 1 and return the SAME sheet: both arms exactly where they are, same size, same shapes. Change ONLY the two gloves, into their FORGED form like in image 2: the same gloves, plus a brass #D9A441 band around the cuff with two round cyan #19E6E6 rivets and a brass plate over the knuckles. Same glove shape, same size, same place: only the finishing touches are added. The arms above the cuff stay bare and unchanged. Do NOT add anything else.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Thick closed pure black #000000 outline, the same weight as the outline of the arms.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `corvo_corpo_base`

```
Image 1 is a sheet with the body parts of our character on flat magenta: among them two arms with an open hand. Image 2 is the chosen armour set "Crow" of our game: left the BASIC form, right the FORGED form. Use image 2 only for materials and colors.

Edit image 1 and return the SAME sheet: every part stays exactly where it is, same size, same shapes, same pixels. Change ONLY the hand and the wrist of the two arms with the open hand: put a GLOVE on each hand. The gloves are snug gloves of dark slate #3A4252 feathers, like the feathers of the chest piece of image 2, with a thin cyan #19E6E6 trim around the wrist and short black claw tips on the fingers. Each glove covers the whole hand, fingers and thumb included, and ends at the wrist with its cuff; it follows the shape of the hand exactly and is only slightly thicker than it. The forearm above the cuff, the elbow, the upper arm and the shoulder stay bare red skin, unchanged. Do NOT add anything else: no sleeves, no shoulder pads, no armour on the arm, nothing on the other parts of the sheet.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Thick closed pure black #000000 outline, the same weight as the outline of the arms.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `corvo_corpo_forgiata`

```
Image 1 is a sheet with the body parts of our character on flat magenta; the two arms with an open hand wear the BASIC gloves of the set "Crow". Image 2 is that armour set: left the BASIC form, right the FORGED form. Use image 2 only for materials and colors.

Edit image 1 and return the SAME sheet: every part stays exactly where it is, same size, same shapes, same pixels. Change ONLY the two gloves, into their FORGED form: the same gloves, plus a cuff of three short pointed slate feathers fanning out from the wrist and a second cyan trim line. Same glove shape, same size, same place: only the finishing touches are added. The arms above the cuff stay bare and unchanged. Do NOT add anything else.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Thick closed pure black #000000 outline, the same weight as the outline of the arms.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `corvo_pugni_base`

```
Image 1 is a sheet with two arms of our character with a closed fist, on flat magenta. Image 2 is another sheet of the same character where the two arms with an open hand wear gloves.

Edit image 1 and return the SAME sheet: both arms exactly where they are, same size, same shapes. Change ONLY the fist and the wrist of each arm: put on each fist the SAME glove of image 2, closed into a fist: snug gloves of dark slate #3A4252 feathers, like the feathers of the chest piece of image 2, with a thin cyan #19E6E6 trim around the wrist and short black claw tips on the fingers. The glove covers the whole fist, fingers and thumb included, keeps the same finger lines of the fist of image 1 and ends at the wrist with its cuff. The forearm above the cuff, the upper arm and the shoulder stay bare red skin, unchanged. Do NOT add anything else: no sleeves, no shoulder pads.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Thick closed pure black #000000 outline, the same weight as the outline of the arms.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `corvo_pugni_forgiata`

```
Image 1 is a sheet with two arms of our character with a closed fist wearing the BASIC gloves of the set "Crow", on flat magenta. Image 2 is another sheet of the same character where the two arms with an open hand wear the FORGED form of those gloves.

Edit image 1 and return the SAME sheet: both arms exactly where they are, same size, same shapes. Change ONLY the two gloves, into their FORGED form like in image 2: the same gloves, plus a cuff of three short pointed slate feathers fanning out from the wrist and a second cyan trim line. Same glove shape, same size, same place: only the finishing touches are added. The arms above the cuff stay bare and unchanged. Do NOT add anything else.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Thick closed pure black #000000 outline, the same weight as the outline of the arms.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `fornace_corpo_base`

```
Image 1 is a sheet with the body parts of our character on flat magenta: among them two arms with an open hand. Image 2 is the chosen armour set "Furnace" of our game: left the BASIC form, right the FORGED form. Use image 2 only for materials and colors.

Edit image 1 and return the SAME sheet: every part stays exactly where it is, same size, same shapes, same pixels. Change ONLY the hand and the wrist of the two arms with the open hand: put a GLOVE on each hand. The gloves are heavy riveted gauntlets of dark iron grey #55585F plates, like the chest plate of image 2, with a cyan #19E6E6 band around the wrist and one round cyan rivet on the back of the hand. Each glove covers the whole hand, fingers and thumb included, and ends at the wrist with its cuff; it follows the shape of the hand exactly and is only slightly thicker than it. The forearm above the cuff, the elbow, the upper arm and the shoulder stay bare red skin, unchanged. Do NOT add anything else: no sleeves, no shoulder pads, no armour on the arm, nothing on the other parts of the sheet.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Thick closed pure black #000000 outline, the same weight as the outline of the arms.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `fornace_corpo_forgiata`

```
Image 1 is a sheet with the body parts of our character on flat magenta; the two arms with an open hand wear the BASIC gloves of the set "Furnace". Image 2 is that armour set: left the BASIC form, right the FORGED form. Use image 2 only for materials and colors.

Edit image 1 and return the SAME sheet: every part stays exactly where it is, same size, same shapes, same pixels. Change ONLY the two gloves, into their FORGED form: the same gauntlets, plus a small orange #F5820A grille of three vertical bars on the back of the hand (like the grille on the chest) and a second cyan rivet. Same glove shape, same size, same place: only the finishing touches are added. The arms above the cuff stay bare and unchanged. Do NOT add anything else.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Thick closed pure black #000000 outline, the same weight as the outline of the arms.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `fornace_pugni_base`

```
Image 1 is a sheet with two arms of our character with a closed fist, on flat magenta. Image 2 is another sheet of the same character where the two arms with an open hand wear gloves.

Edit image 1 and return the SAME sheet: both arms exactly where they are, same size, same shapes. Change ONLY the fist and the wrist of each arm: put on each fist the SAME glove of image 2, closed into a fist: heavy riveted gauntlets of dark iron grey #55585F plates, like the chest plate of image 2, with a cyan #19E6E6 band around the wrist and one round cyan rivet on the back of the hand. The glove covers the whole fist, fingers and thumb included, keeps the same finger lines of the fist of image 1 and ends at the wrist with its cuff. The forearm above the cuff, the upper arm and the shoulder stay bare red skin, unchanged. Do NOT add anything else: no sleeves, no shoulder pads.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Thick closed pure black #000000 outline, the same weight as the outline of the arms.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `fornace_pugni_forgiata`

```
Image 1 is a sheet with two arms of our character with a closed fist wearing the BASIC gloves of the set "Furnace", on flat magenta. Image 2 is another sheet of the same character where the two arms with an open hand wear the FORGED form of those gloves.

Edit image 1 and return the SAME sheet: both arms exactly where they are, same size, same shapes. Change ONLY the two gloves, into their FORGED form like in image 2: the same gauntlets, plus a small orange #F5820A grille of three vertical bars on the back of the hand (like the grille on the chest) and a second cyan rivet. Same glove shape, same size, same place: only the finishing touches are added. The arms above the cuff stay bare and unchanged. Do NOT add anything else.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Thick closed pure black #000000 outline, the same weight as the outline of the arms.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `leviatano_corpo_base`

```
Image 1 is a sheet with the body parts of our character on flat magenta: among them two arms with an open hand. Image 2 is the chosen armour set "Leviathan" of our game: left the BASIC form, right the FORGED form. Use image 2 only for materials and colors.

Edit image 1 and return the SAME sheet: every part stays exactly where it is, same size, same shapes, same pixels. Change ONLY the hand and the wrist of the two arms with the open hand: put a GLOVE on each hand. The gloves are gloves of teal green #2F8F82 round fish scales, like the boots of image 2, with a cyan #19E6E6 band around the wrist. Each glove covers the whole hand, fingers and thumb included, and ends at the wrist with its cuff; it follows the shape of the hand exactly and is only slightly thicker than it. The forearm above the cuff, the elbow, the upper arm and the shoulder stay bare red skin, unchanged. Do NOT add anything else: no sleeves, no shoulder pads, no armour on the arm, nothing on the other parts of the sheet.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Thick closed pure black #000000 outline, the same weight as the outline of the arms.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `leviatano_corpo_forgiata`

```
Image 1 is a sheet with the body parts of our character on flat magenta; the two arms with an open hand wear the BASIC gloves of the set "Leviathan". Image 2 is that armour set: left the BASIC form, right the FORGED form. Use image 2 only for materials and colors.

Edit image 1 and return the SAME sheet: every part stays exactly where it is, same size, same shapes, same pixels. Change ONLY the two gloves, into their FORGED form: the same gloves, plus a small pale aqua #9FE6CF fin with a cyan edge sticking out from the outer side of the wrist, like the fins on the forged boots. Same glove shape, same size, same place: only the finishing touches are added. The arms above the cuff stay bare and unchanged. Do NOT add anything else.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Thick closed pure black #000000 outline, the same weight as the outline of the arms.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `leviatano_pugni_base`

```
Image 1 is a sheet with two arms of our character with a closed fist, on flat magenta. Image 2 is another sheet of the same character where the two arms with an open hand wear gloves.

Edit image 1 and return the SAME sheet: both arms exactly where they are, same size, same shapes. Change ONLY the fist and the wrist of each arm: put on each fist the SAME glove of image 2, closed into a fist: gloves of teal green #2F8F82 round fish scales, like the boots of image 2, with a cyan #19E6E6 band around the wrist. The glove covers the whole fist, fingers and thumb included, keeps the same finger lines of the fist of image 1 and ends at the wrist with its cuff. The forearm above the cuff, the upper arm and the shoulder stay bare red skin, unchanged. Do NOT add anything else: no sleeves, no shoulder pads.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Thick closed pure black #000000 outline, the same weight as the outline of the arms.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `leviatano_pugni_forgiata`

```
Image 1 is a sheet with two arms of our character with a closed fist wearing the BASIC gloves of the set "Leviathan", on flat magenta. Image 2 is another sheet of the same character where the two arms with an open hand wear the FORGED form of those gloves.

Edit image 1 and return the SAME sheet: both arms exactly where they are, same size, same shapes. Change ONLY the two gloves, into their FORGED form like in image 2: the same gloves, plus a small pale aqua #9FE6CF fin with a cyan edge sticking out from the outer side of the wrist, like the fins on the forged boots. Same glove shape, same size, same place: only the finishing touches are added. The arms above the cuff stay bare and unchanged. Do NOT add anything else.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Thick closed pure black #000000 outline, the same weight as the outline of the arms.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `vuoto_corpo_base`

```
Image 1 is a sheet with the body parts of our character on flat magenta: among them two arms with an open hand. Image 2 is the chosen armour set "Void" of our game: left the BASIC form, right the FORGED form. Use image 2 only for materials and colors.

Edit image 1 and return the SAME sheet: every part stays exactly where it is, same size, same shapes, same pixels. Change ONLY the hand and the wrist of the two arms with the open hand: put a GLOVE on each hand. The gloves are wrappings of dark purple #2E1F47 cloth bands wound around the hand and the wrist, like the bands on the chest of image 2, with a cyan #19E6E6 band around the wrist. Each glove covers the whole hand, fingers and thumb included, and ends at the wrist with its cuff; it follows the shape of the hand exactly and is only slightly thicker than it. The forearm above the cuff, the elbow, the upper arm and the shoulder stay bare red skin, unchanged. Do NOT add anything else: no sleeves, no shoulder pads, no armour on the arm, nothing on the other parts of the sheet.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Thick closed pure black #000000 outline, the same weight as the outline of the arms.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `vuoto_corpo_forgiata`

```
Image 1 is a sheet with the body parts of our character on flat magenta; the two arms with an open hand wear the BASIC gloves of the set "Void". Image 2 is that armour set: left the BASIC form, right the FORGED form. Use image 2 only for materials and colors.

Edit image 1 and return the SAME sheet: every part stays exactly where it is, same size, same shapes, same pixels. Change ONLY the two gloves, into their FORGED form: the same wrappings, plus a small cyan ring with a white eye and a black slit pupil on the back of the hand, like the eye brooch of image 2. Same glove shape, same size, same place: only the finishing touches are added. The arms above the cuff stay bare and unchanged. Do NOT add anything else.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Thick closed pure black #000000 outline, the same weight as the outline of the arms.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `vuoto_pugni_base`

```
Image 1 is a sheet with two arms of our character with a closed fist, on flat magenta. Image 2 is another sheet of the same character where the two arms with an open hand wear gloves.

Edit image 1 and return the SAME sheet: both arms exactly where they are, same size, same shapes. Change ONLY the fist and the wrist of each arm: put on each fist the SAME glove of image 2, closed into a fist: wrappings of dark purple #2E1F47 cloth bands wound around the hand and the wrist, like the bands on the chest of image 2, with a cyan #19E6E6 band around the wrist. The glove covers the whole fist, fingers and thumb included, keeps the same finger lines of the fist of image 1 and ends at the wrist with its cuff. The forearm above the cuff, the upper arm and the shoulder stay bare red skin, unchanged. Do NOT add anything else: no sleeves, no shoulder pads.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Thick closed pure black #000000 outline, the same weight as the outline of the arms.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `vuoto_pugni_forgiata`

```
Image 1 is a sheet with two arms of our character with a closed fist wearing the BASIC gloves of the set "Void", on flat magenta. Image 2 is another sheet of the same character where the two arms with an open hand wear the FORGED form of those gloves.

Edit image 1 and return the SAME sheet: both arms exactly where they are, same size, same shapes. Change ONLY the two gloves, into their FORGED form like in image 2: the same wrappings, plus a small cyan ring with a white eye and a black slit pupil on the back of the hand, like the eye brooch of image 2. Same glove shape, same size, same place: only the finishing touches are added. The arms above the cuff stay bare and unchanged. Do NOT add anything else.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Thick closed pure black #000000 outline, the same weight as the outline of the arms.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `icone_guanti`

```
Image 1 is an inventory icon of our game: one piece of equipment drawn alone, big, slightly tilted, flat colors, thick black outline. The other images are sheets with two gloved fists of our character: five armour sets (Smith, Crow, Furnace, Leviathan, Void), each in its BASIC and its FORGED form.

Draw ONE sheet of ten inventory icons in the style of image 1, in a grid of 5 columns and 2 rows on flat magenta, evenly spaced, none touching another. Each icon is a PAIR OF GLOVES alone, without the arm: the two gloves side by side, slightly overlapping, fingers up, cuffs down, slightly tilted, filling its cell. Top row, left to right: the BASIC gloves of Smith, Crow, Furnace, Leviathan, Void. Bottom row, in the same order: their FORGED forms. Each pair has exactly the materials, colors and details of the gloves of its sheet.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Thick closed pure black #000000 outline, the same weight as the outline of the arms.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `sagoma_vuota_guanti`

```
Image 1 is an inventory icon of our game. Draw the EMPTY SLOT silhouette for gloves, for a square inventory cell: a pair of plain gloves side by side, fingers up, cuffs down, slightly tilted, as ONE flat shape in mid grey #5A5A64 with a thick closed darker grey #3A3A42 outline and one line between the two gloves; no details, no colors, no highlights. Centered, filling about 70% of the image.

- FLAT COLORS ONLY, no gradients, no textures, no glow.
- Background: flat pure magenta #FF00FF everywhere, with no halo.
- No text, numbers, labels, arrows or signatures.
```

## Criteri di accettazione

- [ ] corpo e pugni: il foglio è il riferimento identico (stesse parti, stesse posizioni, stessa misura) tranne mani e polsi
- [ ] il guanto copre solo mano e polso: avambraccio, gomito e spalla restano pelle nuda; niente maniche né spalline
- [ ] il guanto segue la forma della mano (non più grosso di qualche pixel): deve stare sotto le impugnature delle armi di adesso
- [ ] il pugno guantato ha le stesse linee delle dita del pugno di R2
- [ ] base e forgiata hanno la stessa sagoma; la forgiata aggiunge solo le finiture
- [ ] ogni famiglia si riconosce dal materiale e dai colori della sua tavola
- [ ] icone: dieci coppie di guanti nell'ordine chiesto, nessuna tocca l'altra
- [ ] colori piatti, contorno nero chiuso e spesso, magenta pulito, nessuna scritta

---

## Decisione

Approvata da Sergio il 18 nov («sisi, preparala»). Scelte di Claude: il mestiere dei guanti (più:
spinta dei colpi; secondo: Attacco); il guanto copre solo mano e polso, così non tocca le spalline
delle corazze e le impugnature delle armi restano quelle di adesso; l'aspetto dei guanti di ogni
famiglia, tratto dai materiali della sua tavola; base e forgiata come gli altri pezzi addosso.
Il codice del quinto posto (simulazione, zaino, armeria, cartellino) si fa dopo, quando arrivano i disegni.

## Consegna di Codex

Generati e controllati 26 PNG in `art/WB-070/`, ciascuno al primo tentativo e accompagnato dal `.txt` omonimo con prompt e riferimenti.

- Fabbro: `fabbro_corpo_base_1`, `fabbro_corpo_base_2`, `fabbro_corpo_forgiata`, `fabbro_pugni_base`, `fabbro_pugni_forgiata`. Variante base scelta: **2**.
- Corvo: `corvo_corpo_base_1`, `corvo_corpo_base_2`, `corvo_corpo_forgiata`, `corvo_pugni_base`, `corvo_pugni_forgiata`. Variante base scelta: **1**.
- Fornace: `fornace_corpo_base_1`, `fornace_corpo_base_2`, `fornace_corpo_forgiata`, `fornace_pugni_base`, `fornace_pugni_forgiata`. Variante base scelta: **1**.
- Leviatano: `leviatano_corpo_base_1`, `leviatano_corpo_base_2`, `leviatano_corpo_forgiata`, `leviatano_pugni_base`, `leviatano_pugni_forgiata`. Variante base scelta: **2**.
- Vuoto: `vuoto_corpo_base_1`, `vuoto_corpo_base_2`, `vuoto_corpo_forgiata`, `vuoto_pugni_base`, `vuoto_pugni_forgiata`. Variante base scelta: **2**.
- Slot vuoto: `sagoma_vuota_guanti`.

Controllati disposizione dei pezzi, copertura dei guanti, pelle scoperta sopra i polsini, contorni, sfondo e assenza di scritte o tagli. I 25 fogli del personaggio sono 1536×1024. La sagoma quadrata è 1254×1254 rispetto ai 1024×1024 richiesti.

Per le basi ho scelto la variante con l’errore RGB medio assoluto più basso rispetto a R1 sui pixel in primo piano fuori da mani e polsi. Tutte le varianti differiscono da R1 anche fuori da quelle zone. Lo sfondo appare magenta uniforme a vista. Nessun angolo in alto a sinistra campionato restituisce il valore esatto `#FF00FF`.

Alcuni pugni differiscono da R2 nelle linee delle dita. Le finiture forgiate di Corvo e Leviatano modificano localmente la sagoma. Le piume del Corvo base sono poco marcate e le placche del Fornace base risultano semplificate. La compatibilità con le impugnature in gioco resta da verificare.

`icone_guanti` è bloccata prima della generazione. La scheda prescrive 11 riferimenti separati (R4 e dieci fogli di pugni) e il generatore ne accetta al massimo cinque per richiesta.

## Resoconto di Claude

18 nov. Guardati tutti i 25 fogli e la sagoma: nessuno scartato.

- **Tenuti e montati:** per ogni famiglia `corpo_base` (Fabbro la **1**, non la 2 scelta da Codex:
  nella 2 il cuoio della mano aperta è più scuro di quello del pugno e il ricalco lo macchiava;
  Corvo 1, Fornace 1, Leviatano 2, Vuoto 2), `corpo_forgiata`, `pugni_base`, `pugni_forgiata`.
  Ricette `tools/stampino/addosso/<famiglia>_guanti.json`, pelli `guanti_<famiglia>` e
  `guanti_<famiglia>_forgiato` (categoria `guanti`: mano aperta e pugno, davanti e dietro).
- **Strumento:** `addosso.py` taglia anche i guanti (quello che della mano resta scoperto sotto
  il polsino diventa guanto) e con `--prova` salva ogni pezzo grande da solo.
- **Verificato:** `tutti.sh` OK; scenari `guanti_<famiglia>.txt` e `guanti_<famiglia>_forgiato.txt`
  (fermo e in corsa con l'arma in pugno): i guanti stanno sulle mani, non coprono le spalline e
  l'arma resta impugnata bene.
- **Nel gioco dal 19 nov** (quinto posto, PR dei guanti); prima li indossava solo la prova (`imposta prova_guanti`, tolta); il quinto
  posto (statistiche, firme, zaino, armeria) aspetta le scelte di Sergio.
- **Icone:** Codex non le ha generate (troppi riferimenti). Provate ricavandole dai pugni
  ritagliati: troppo grezze accanto alle icone degli altri pezzi, scartate. Serve una scheda
  nuova con un'icona per richiesta.
- **Sagoma vuota:** tenuta da parte, si ritaglia insieme alle icone.
