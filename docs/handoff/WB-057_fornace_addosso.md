# WB-057 · La Fornace addosso all'apprendista: elmo, corazza di ferro con spalline, stivali, mantello

- **Stato:** APPROVATA (Sergio, 15 nov: «Smazziamocele tutte»)
- **Data:** 2026-11-15
- **Ramo della scheda:** `claude/project-thread-e8poye` · **Ramo delle immagini:** `design/WB-057`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-057` senza chiedere conferma (il repository è privato).

## Obiettivo

Per ora si vedono addosso solo i pezzi del Vuoto (WB-041, WB-042). Questa scheda porta addosso
all'apprendista la famiglia **Fornace**, come WB-055 fa col Fabbro: stessi fogli, stesso metodo.

Ogni pezzo si disegna **sul foglio dell'apprendista che veste, nella stessa posizione**, così si
ritaglia per differenza e calza senza metterlo a occhio. Due forme: base e forgiata (stessa
sagoma, con le finiture in più). I pezzi:

- l'**elmo**: una calotta di ferro con la grata arancione e la fascia ciano. È **chiuso**: corna e fiamma sono pezzi a parte, messi sopra dal gioco; il comignolo della forgiata sta dietro, non in cima;
- la **corazza**: la piastra di ferro con la grata e le borchie ciano, con le **spalline**, sulla spalla di ogni braccio, anche di quelle col pugno: due piastre di ferro sovrapposte con una borchia ciano, come quelle che nella tavola spuntano dietro la spalla;
- gli **stivali** di ferro con la fascia ciano;
- il **mantello** a piastre di tela ferrata, largo e fatto per muoversi come quello del Vuoto (WB-032 B).

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-057/riferimenti/R1_teste_senza_corna.png` | le nove teste senza corna (WB-039) |
| R2 | `art/WB-057/riferimenti/R2_corpo_collo_nudo.png` | il foglio del corpo (WB-037): fazzoletto, busto col collo nudo, coda, due braccia, due gambe, pugno |
| R3 | `art/WB-057/riferimenti/R3_pugni.png` | le due braccia col pugno chiuso (WB-037), per le armi |
| R4 | `art/WB-057/riferimenti/R4_fornace.png` | la tavola scelta della famiglia: a sinistra base, a destra forgiata |
| R5 | `art/WB-057/riferimenti/R5_stampino.png` | lo stampino: la casella `mantello` è la sagoma grigia fra busto e ala |
| R6 | `art/WB-057/riferimenti/R6_mantello_vuoto.png` | il mantello ampio del Vuoto (WB-032 B): la grandezza e il taglio largo da tenere, non lo stile |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Per teste, corpo e pugni si lavora SOPRA il foglio
indicato: stesso foglio, stessa misura, tutto il resto identico.

| Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|
| `art/WB-057/elmo_base.png` | R1, R4 | come R1 | 2 |
| `art/WB-057/elmo_forgiata.png` | R1, R4, `elmo_base_N.png` scelta | come R1 | 1 |
| `art/WB-057/corpo_base.png` | R2, R4 | 1536×1024 | 2 |
| `art/WB-057/corpo_forgiata.png` | R2, R4, `corpo_base_N.png` scelto | 1536×1024 | 1 |
| `art/WB-057/pugni_base.png` | R3, `corpo_base_N.png` scelto | 1536×1024 | 1 |
| `art/WB-057/pugni_forgiata.png` | R3, `corpo_forgiata.png` | 1536×1024 | 1 |
| `art/WB-057/mantello_base.png` | R4, R5, R6 | 1536×1024 | 2 |
| `art/WB-057/mantello_forgiata.png` | R4, R5, `mantello_base_N.png` scelto | 1536×1024 | 1 |

Le varianti si chiamano `elmo_base_1.png`, `elmo_base_2.png` e così via. Per teste e corpo Codex
sceglie la base col resto del foglio più identico al riferimento e lo scrive nel `.txt`; per il
mantello sceglie quello più largo in fondo e con le pieghe più lunghe. Le forgiate e i pugni
partono dalla base scelta.

### `elmo_base`

```
Image 1 is a sheet of nine heads of our character on flat magenta (the same head with nine faces, no horns). Image 2 is the chosen armour set "Furnace" of our game: left the BASIC form, right the FORGED form.

Edit image 1 and return the SAME sheet: all nine heads stay exactly where they are, same size, same shapes, same faces, same pixels. Change only the FIRST head (top left): put on it the iron HELMET of the BASIC form of image 2: a round dome of grey iron that covers the top and the back of the head down to the brow, with a small orange grille of three vertical slots on the front and a cyan band along its lower edge. The face stays fully visible and unchanged; the pointed ears come out on the sides. It is ONE CLOSED piece with a clean rounded top: no holes, no openings. Horns and the head flame will be drawn later on top of it as separate parts: draw no horns and no flame. The other eight heads do not change at all.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Iron grey #5A5A62 with shadows #3C3C44, orange #F28A1E grilles, cyan #00FFFF trims and rivets, thick closed black #000000 outline like the other parts. The armour colours must be clearly different from the red skin.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `elmo_forgiata`

```
Image 1 is a sheet of nine heads of our character. Image 2 is the chosen armour set "Furnace" (right: FORGED form). Image 3 is image 1 with the basic headpiece already drawn on the first head.

Return image 3 again, the SAME sheet with every head exactly where it is and the same pixels, and change only the headpiece on the first head: make it the FORGED one of image 2, keeping the outline of image 3, plus: a short iron chimney with an orange grille and a cyan ring at its base, standing at the BACK of the dome (not on the top of the head, the top stays clean and round). It stays one closed piece: no holes, no horns, no flame. Nothing else on the sheet changes.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Iron grey #5A5A62 with shadows #3C3C44, orange #F28A1E grilles, cyan #00FFFF trims and rivets, thick closed black #000000 outline like the other parts.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `corpo_base`

```
Image 1 is a sheet of body parts of our character on flat magenta: the green neckerchief at the top, the torso with a bare neck in the middle, the tail, two arms, two legs and a fist below. Image 2 is the chosen armour set "Furnace" of our game: left the BASIC form, right the FORGED form.

Edit image 1 and return the SAME sheet: every part stays exactly where it is, same size, same shapes, same colors, same pixels. Change only these:
1. On the torso: the ARMOUR of the BASIC form of image 2: a breastplate of grey iron with rounded corners covering the chest and the belly, with an orange grille of three vertical slots in the middle and four round cyan rivets at its corners, held by two iron straps going up over the shoulders. The armour follows the outline of the torso exactly and leaves the bare neck stub free.
2. On the top of BOTH arms, over the shoulder: a SHOULDER PAD that belongs to this armour: two overlapping curved plates of the same grey iron, the upper one a little wider, with one round cyan rivet on the upper plate. The pad covers the rounded top of the arm and the upper part of the upper arm, follows the arm's outline and is a little wider than the arm; the rest of the arm, the hand and the fingers stay bare and unchanged. Both arms get the same pad.
3. On BOTH legs: the BOOTS of the BASIC form of image 2: heavy grey iron boots covering the feet and the lower part of the leg up to the middle of the shin, with a cyan band at the top. The toes are hidden inside the boots; the boots keep the shape of the foot.
The neckerchief, the tail and the fist do not change at all.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Iron grey #5A5A62 with shadows #3C3C44, orange #F28A1E grilles, cyan #00FFFF trims and rivets, thick closed black #000000 outline like the other parts. The armour colours must be clearly different from the red skin.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `corpo_forgiata`

```
Image 1 is a sheet of body parts of our character. Image 2 is the chosen armour set "Furnace" (right: FORGED form). Image 3 is image 1 with the basic armour on the torso, a shoulder pad on the top of both arms and the basic boots on both legs.

Return image 3 again, the SAME sheet with every part exactly where it is and the same pixels, and change only the armour, the two shoulder pads and the boots: make them the FORGED versions of image 2, keeping the outlines of image 3:
- armour: a wider orange grille with five slots;
- shoulder pads: a third smaller plate at the bottom and a thin cyan rim along the lowest plate, the same on both arms;
- boots: an iron toe cap with a cyan rim and two cyan rivets on each boot, like in image 2.
Nothing else on the sheet changes.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Iron grey #5A5A62 with shadows #3C3C44, orange #F28A1E grilles, cyan #00FFFF trims and rivets, thick closed black #000000 outline like the other parts.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `pugni_base`

```
Image 1 is a sheet with two arms of our character with a closed fist, on flat magenta. Image 2 is a sheet of the same character where both bare arms wear a grey iron shoulder pad.

Edit image 1 and return the SAME sheet: both arms exactly where they are, same size, same shapes, same pixels. Change only the top of each arm: put on it the SAME shoulder pad as on the arms of image 2, same shape, same details, same colours, same size relative to the arm, over the shoulder. The rest of each arm and the fist stay bare and unchanged.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Iron grey #5A5A62 with shadows #3C3C44, orange #F28A1E grilles, cyan #00FFFF trims and rivets, thick closed black #000000 outline like the other parts.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `pugni_forgiata`

```
Image 1 is a sheet with two arms of our character with a closed fist, on flat magenta. Image 2 is a sheet of the same character where both arms wear the FORGED iron shoulder pad with three plates and a cyan rim.

Edit image 1 and return the SAME sheet: both arms exactly where they are, same size, same shapes, same pixels. Change only the top of each arm: put on it the SAME forged shoulder pad as on the arms of image 2, same shape, same details, same colours, same size relative to the arm. The rest of each arm and the fist stay bare and unchanged.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Iron grey #5A5A62 with shadows #3C3C44, orange #F28A1E grilles, cyan #00FFFF trims and rivets, thick closed black #000000 outline like the other parts.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `mantello_base`

```
Image 1 is the chosen armour set "Furnace" of our game (left: BASIC form, right: FORGED form). Image 2 is our "stampino": a sheet with grey body parts on magenta; the grey trapezoid between the torso and the wing is the box "mantello". Image 3 is a cape of another set of our game: keep its SIZE on the sheet, its wide flare and its long folds, but NOT its style or its colours.

Draw ONE cape of the BASIC form of image 1, alone, as large on the sheet as the cape of image 3: a cape of heavy iron-grey cloth made of four or five overlapping horizontal bands, like furnace plates. Seen from the side, hanging straight down behind the shoulders as if the wearer stood still: the top edge is short, straight and horizontal, at the top right (where it is tied to the shoulders), no hood, no collar roll, no clasp hanging over the edge. The cape gets much wider toward the bottom: at the hem it is about twice as wide as at the top, flaring out to the left (the back). The hem is one clean, slightly wavy line, not torn. Long folds or lines run from the top edge all the way down to the hem, so the cape can bend anywhere. Length: down to the knee of the wearer. No body, no arms, no shoulders, nothing else on the sheet.

Same rendering rules as image 1: flat colors, thick closed black outline. Iron grey #5A5A62 with shadows #3C3C44, orange #F28A1E grilles, cyan #00FFFF trims and rivets, nothing else. Background: flat pure magenta #FF00FF everywhere outside the cape. Do not draw the box, crosses or labels. No text. Landscape 3:2.
```

### `mantello_forgiata`

```
Image 1 is the chosen armour set "Furnace" of our game (right: FORGED form). Image 2 is our "stampino". Image 3 is the basic cape of this set, alone on magenta.

Return image 3 again: the same cape, same position, same size, the same outline and folds. Change only this: make it the FORGED cape of image 1: an orange band along the hem, like in image 1. Nothing else changes. No body, nothing else on the sheet.

Same rendering rules: flat colors, thick closed black outline. Iron grey #5A5A62 with shadows #3C3C44, orange #F28A1E grilles, cyan #00FFFF trims and rivets, nothing else. Background: flat pure magenta #FF00FF everywhere outside the cape. No text. Landscape 3:2.
```

## Criteri di accettazione

- [ ] ogni foglio di teste, corpo e pugni è il suo riferimento identico (stessi pezzi, stesse posizioni, stessa misura) tranne i pezzi della famiglia
- [ ] l'elmo solo sulla prima testa, chiuso in cima: niente buchi, corna o fiamma; faccia intera e uguale, orecchie fuori
- [ ] la corazza segue il busto e lascia libero il collo; gli stivali su tutte e due le gambe
- [ ] le spalline in cima a tutte e due le braccia (anche quelle col pugno), uguali, un po' più larghe del braccio; mano e dita nude e uguali
- [ ] il mantello è uno solo per foglio, grande come R6, bordo in alto corto e dritto a destra, largo in fondo
- [ ] ferro grigio, grate arancioni; colori piatti, contorno nero chiuso e spesso, magenta pulito, nessuna scritta
- [ ] le forgiate hanno le stesse sagome delle basi, con le finiture in più

---

## Decisione

Approvata da Sergio il 15 nov («Smazziamocele tutte»). (Claude) Spalline della Fornace: due piastre di ferro sovrapposte con una borchia ciano; forgiate con una terza piastra e il bordo ciano. Il comignolo dell'elmo forgiato va dietro, perché in cima ci sono le corna e la fiamma.

## Consegna di Codex

## Resoconto di Claude
