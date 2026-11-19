# WB-081 · I guanti Corvo rifatti

- **Stato:** APPROVATA (Sergio, 19 nov: «approvo»)
- **Data:** 2026-11-19
- **Ramo della scheda:** `claude/project-thread-rc20kg` (eseguila da questo ramo: `git fetch origin claude/project-thread-rc20kg`) · **Ramo delle immagini:** `design/WB-081`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-081` senza chiedere conferma (il repository è privato).

## Obiettivo

I guanti Corvo di WB-070 non vanno (Sergio, 19 nov): in mano sembra che taglino le dita, perché
gli artigli neri sulla punta del pugno si leggono come tagli, e le piume quasi non si vedono. Anche
le due icone di WB-076 (base e forgiata) sono deboli. Si rifanno i quattro fogli del Corvo (mano
aperta e pugno, base e forgiata) senza artigli, con le dita intere e le piume sul dorso ben
leggibili, e poi le due icone da quei fogli. Le altre quattro famiglie restano come sono: sono il
riferimento di qualità (il Fabbro).

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-070/riferimenti/R1_corpo.png` | il foglio del corpo (WB-037): in basso le due braccia con la mano aperta, nude |
| R2 | `art/WB-070/riferimenti/R2_pugni.png` | le due braccia col pugno chiuso, nude (WB-037) |
| R3 | `art/WB-070/riferimenti/R3_corvo.png` | la tavola della famiglia Corvo (WB-019): solo per materiali e colori |
| R5 | `art/WB-070/fabbro_pugni_base.png` | i pugni coi guanti del Fabbro, approvati: esempio di come un guanto segue le dita |
| R6 | `art/WB-076/riferimenti/R_corvo_base_icona.png`, `R_corvo_forgiato_icona.png` | le icone degli stivali Corvo (WB-043): stile e misura delle icone |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Tutto in `art/WB-081/`, ogni PNG col suo `.txt`
del prompt. Per corpo e pugni si lavora SOPRA il foglio indicato: stesso foglio, stessa misura,
tutto il resto identico. Si fa prima `corvo_corpo_base` (2 varianti, Codex sceglie quella col
resto del foglio più identico a R1 e lo scrive nel `.txt`), poi le altre partono da quella.

| Nome file | Riferimenti (in quest'ordine) | Misura | Varianti |
|---|---|---|---|
| `corvo_corpo_base.png` | R1, R3 | come R1 | 2 |
| `corvo_corpo_forgiata.png` | `corvo_corpo_base_N.png` scelto, R3 | come R1 | 1 |
| `corvo_pugni_base.png` | R2, `corvo_corpo_base_N.png` scelto, R5 | 1536×1024 | 2 |
| `corvo_pugni_forgiata.png` | `corvo_pugni_base_N.png` scelto, `corvo_corpo_forgiata.png` | 1536×1024 | 1 |
| `ic_corvo_guanti_base.png` | R6 base, `corvo_pugni_base_N.png` scelto | 1024×1024 | 2 |
| `ic_corvo_guanti_forgiato.png` | R6 forgiato, `corvo_pugni_forgiata.png` | 1024×1024 | 2 |

In tutto 10 immagini.

### `corvo_corpo_base`

Allegati: R1, R3.

```
Image 1 is a sheet with the body parts of our character on flat magenta: among them two arms with an open hand. Image 2 is the chosen armour set "Crow" of our game: left the BASIC form, right the FORGED form. Use image 2 only for materials and colors.

Edit image 1 and return the SAME sheet: every part stays exactly where it is, same size, same shapes, same pixels. Change ONLY the hand and the wrist of the two arms with the open hand: put a GLOVE on each hand. The gloves are snug gloves of dark slate #3A4252 with a lighter slate #5A6478 shadow-free top, with clearly drawn overlapping feather shapes on the BACK of the hand only (three or four rounded feathers, like the feathers of the chest piece of image 2), and a thin cyan #19E6E6 trim around the wrist. NO claws, NO talons, NO pointed tips and NO black marks on the fingers: every finger is a whole rounded glove finger, as thick as the bare finger it covers, its tip round and closed by the outline. Every finger and the thumb are clearly separated by one clean black line, like the fingers of the bare hand. Each glove covers the whole hand, fingers and thumb included, and ends at the wrist with its cuff; it follows the shape of the hand exactly and is only slightly thicker than it. The forearm above the cuff, the elbow, the upper arm and the shoulder stay bare red skin, unchanged. Do NOT add anything else: no sleeves, no shoulder pads, no armour on the arm, nothing on the other parts of the sheet.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Thick closed pure black #000000 outline, the same weight as the outline of the arms.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `corvo_corpo_forgiata`

Allegati: `corvo_corpo_base_N.png` scelto, R3.

```
Image 1 is a sheet with the body parts of our character on flat magenta; the two arms with an open hand wear the BASIC gloves of the set "Crow". Image 2 is that armour set: left the BASIC form, right the FORGED form. Use image 2 only for materials and colors.

Edit image 1 and return the SAME sheet: every part stays exactly where it is, same size, same shapes, same pixels. Change ONLY the two gloves, into their FORGED form: the same gloves, plus a cuff of three short rounded slate feathers fanning out from the wrist toward the elbow, and a second cyan trim line. The fingers stay exactly as they are: whole, rounded, no claws, no pointed tips. Same glove shape, same size, same place: only the finishing touches are added. The arms above the cuff stay bare and unchanged. Do NOT add anything else.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Thick closed pure black #000000 outline, the same weight as the outline of the arms.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `corvo_pugni_base`

Allegati: R2, `corvo_corpo_base_N.png` scelto, R5.

```
Image 1 is a sheet with two arms of our character with a closed fist, on flat magenta. Image 2 is another sheet of the same character where the two arms with an open hand wear gloves. Image 3 is the same fists wearing the gloves of another set: use it ONLY as an example of how a glove follows the closed fingers (the finger rolls stay round and whole, separated by clean lines); do not copy its materials.

Edit image 1 and return the SAME sheet: both arms exactly where they are, same size, same shapes. Change ONLY the fist and the wrist of each arm: put on each fist the SAME glove of image 2, closed into a fist: snug gloves of dark slate #3A4252 with a lighter slate #5A6478 shadow-free top, with clearly drawn overlapping feather shapes on the BACK of the hand only (three or four rounded feathers, like the feathers of the chest piece of image 2), and a thin cyan #19E6E6 trim around the wrist. NO claws, NO talons, NO pointed tips and NO black marks on the fingers: every finger is a whole rounded glove finger, as thick as the bare finger it covers, its tip round and closed by the outline. Every finger and the thumb are clearly separated by one clean black line, like the fingers of the bare hand. The glove covers the whole fist, fingers and thumb included, keeps the same finger lines of the fist of image 1 (four round finger rolls and the thumb over them) and ends at the wrist with its cuff. Nothing sticks out below or in front of the fist. The forearm above the cuff, the upper arm and the shoulder stay bare red skin, unchanged. Do NOT add anything else: no sleeves, no shoulder pads.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Thick closed pure black #000000 outline, the same weight as the outline of the arms.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `corvo_pugni_forgiata`

Allegati: `corvo_pugni_base_N.png` scelto, `corvo_corpo_forgiata.png`.

```
Image 1 is a sheet with two arms of our character with a closed fist wearing the BASIC gloves of the set "Crow", on flat magenta. Image 2 is another sheet of the same character where the two arms with an open hand wear the FORGED form of those gloves.

Edit image 1 and return the SAME sheet: both arms exactly where they are, same size, same shapes. Change ONLY the two gloves, into their FORGED form like in image 2: the same gloves, plus a cuff of three short rounded slate feathers fanning out from the wrist toward the elbow and a second cyan trim line. The fist and its fingers stay exactly as they are: whole, round, no claws, no pointed tips. Same glove shape, same size, same place: only the finishing touches are added. The arms above the cuff stay bare and unchanged. Do NOT add anything else.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Thick closed pure black #000000 outline, the same weight as the outline of the arms.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `ic_corvo_guanti_base`

Allegati: `art/WB-076/riferimenti/R_corvo_base_icona.png`, `corvo_pugni_base_N.png` scelto.

```
Image 1 is an inventory icon of our game: the boots of the Crow armour set, BASIC form, drawn alone, big, slightly tilted, flat colors with one flat shadow tone, thick pure black outline. Image 2 is a sheet with the two arms of our character with the fists closed, wearing the BASIC Crow gloves (dark slate with feathers on the back of the hand and a cyan trim at the wrist).

Draw ONE inventory icon in exactly the style of image 1: the PAIR OF GLOVES of image 2 alone, without arms and without hands inside, as two empty gloves side by side, slightly overlapping, open with the fingers up and slightly curled, cuffs down, slightly tilted like the boots of image 1. Show the BACK of the gloves so the feathers read clearly: three or four big rounded overlapping feathers on each back, in the lighter slate #5A6478 over the dark slate #3A4252, each with its black outline. Fingers whole and rounded, no claws, no pointed tips. The cyan #19E6E6 trim at each cuff. Same outline thickness and same amount of detail as image 1: bold, simple and readable when small.

Centered, filling about 80% of a square image, on a flat pure magenta #FF00FF background. No text, no frame, no ground shadow, no glow, no gradient, no red skin.
```

### `ic_corvo_guanti_forgiato`

Allegati: `art/WB-076/riferimenti/R_corvo_forgiato_icona.png`, `corvo_pugni_forgiata.png`.

```
Image 1 is an inventory icon of our game: the boots of the Crow armour set, FORGED form, drawn alone, big, slightly tilted, flat colors with one flat shadow tone, thick pure black outline. Image 2 is a sheet with the two arms of our character with the fists closed, wearing the FORGED Crow gloves (dark slate with feathers on the back of the hand, a cuff of three feathers fanning from the wrist and two cyan trims).

Draw ONE inventory icon in exactly the style of image 1: the PAIR OF GLOVES of image 2 alone, without arms and without hands inside, as two empty gloves side by side, slightly overlapping, open with the fingers up and slightly curled, cuffs down, slightly tilted like the boots of image 1. Show the BACK of the gloves so the feathers read clearly: three or four big rounded overlapping feathers on each back, in the lighter slate #5A6478 over the dark slate #3A4252, each with its black outline, and at each cuff the fan of three longer feathers with the two cyan #19E6E6 trims. It must look clearly richer than the basic gloves, with the same silhouette. Fingers whole and rounded, no claws, no pointed tips. Same outline thickness and same amount of detail as image 1: bold, simple and readable when small.

Centered, filling about 80% of a square image, on a flat pure magenta #FF00FF background. No text, no frame, no ground shadow, no glow, no gradient, no red skin.
```

## Criteri di accettazione

- [ ] nessun artiglio, punta o segno nero sulle dita: dita e pollice interi, tondi, separati da una linea pulita
- [ ] le piume sul dorso si leggono anche piccole; la forgiata ha in più il ventaglio di piume al polso e il secondo filo ciano
- [ ] nei fogli tutto il resto identico a R1 e R2: stessi pezzi, stesso posto, braccio nudo sopra il polsino
- [ ] colori piatti, contorno nero puro e spesso, fondo magenta piatto, nessuna scritta
- [ ] icone nello stile di quelle degli stivali Corvo, base e forgiata ben distinte

---

## Decisione

Approvata da Sergio il 19 nov.

## Consegna di Codex
Eseguita il 19 novembre 2026 sul ramo design/WB-081, creato da origin/claude/project-thread-rc20kg (215d284d). Generazione con ImageGen integrato, prompt usati integralmente senza modifiche e riferimenti nell'ordine della tabella.

Consegnati in art/WB-081/, ciascuno col proprio .txt:
- corvo_corpo_base_1.png e corvo_corpo_base_2.png (1536 x 1024, un tentativo ciascuno).
- corvo_corpo_forgiata.png (1536 x 1024, tre tentativi, selezionato il terzo).
- corvo_pugni_base_1.png e corvo_pugni_base_2.png (1536 x 1024, un tentativo ciascuno).
- corvo_pugni_forgiata.png (1536 x 1024, un tentativo).
- ic_corvo_guanti_base_1.png e ic_corvo_guanti_base_2.png (1254 x 1254, tre tentativi ciascuno; selezionati rispettivamente il terzo e il secondo).
- ic_corvo_guanti_forgiato_1.png e ic_corvo_guanti_forgiato_2.png (1254 x 1254, tre tentativi ciascuno, selezionati i terzi).

Scelte per i riferimenti successivi: corvo_corpo_base_2, per piume piu leggibili e minore variazione fuori dai guanti rispetto alla variante 1; corvo_pugni_base_1, per dita separate e piume leggibili. Scelte riportate anche nei TXT. Confronto numerico fuori da due rettangoli che contengono mani e polsi: rispetto a R1 risultano modificati 1.522.695 pixel nella variante corpo 1 e 1.496.138 nella variante 2 (include minime variazioni cromatiche dello sfondo). La disposizione appare conservata, ma il requisito degli stessi pixel NON e soddisfatto.

Controllati visivamente tutti i 20 risultati generati: dita arrotondate senza artigli, piume sul dorso, braccia nude sopra il polsino, parti complete senza tagli al bordo, nessuna scritta; base e forgiata distinguibili per ventaglio e doppio bordo ciano. PNG originali, senza ritocco, compositing, ricalco o ridimensionamento; fondo magenta mantenuto come richiesto.

Difformita residue da sottoporre a Claude: restano sfumature/variazioni cromatiche nonostante il divieto; nei polsini forgiati il generatore introduce anche viola e un ventaglio con piu di tre piume; la forma delle piume sul dorso varia fra base e forgiata. Le quattro icone misurano 1254 x 1254 invece di 1024 x 1024. La conservazione esatta dei pixel fuori dai guanti non e ottenuta; non certificati colori esadecimali, uniformita numerica del magenta, sagome e posizioni identiche al pixel. Nelle icone alcune dita si sovrappongono: da verificare la lettura alla misura effettiva nel gioco. Nessuna prova nel gioco o integrazione eseguita. Criteri di accettazione lasciati a Claude, senza spuntarli.
## Resoconto di Claude
