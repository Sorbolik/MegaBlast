# WB-058 · Il Leviatano addosso all'apprendista: elmo di scaglie, corazza con spalline, stivali, mantello

- **Stato:** IMPLEMENTATA, APPROVATA (Sergio, 15 nov: «Smazziamocele tutte»)
- **Data:** 2026-11-15
- **Ramo della scheda:** `claude/project-thread-e8poye` · **Ramo delle immagini:** `design/WB-058`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-058` senza chiedere conferma (il repository è privato).

## Obiettivo

Per ora si vedono addosso solo i pezzi del Vuoto (WB-041, WB-042). Questa scheda porta addosso
all'apprendista la famiglia **Leviatano**, come WB-055 fa col Fabbro: stessi fogli, stesso metodo.

Ogni pezzo si disegna **sul foglio dell'apprendista che veste, nella stessa posizione**, così si
ritaglia per differenza e calza senza metterlo a occhio. Due forme: base e forgiata (stessa
sagoma, con le finiture in più). I pezzi:

- l'**elmo** di scaglie con la finitura ciano intorno al viso. È **chiuso**: corna e fiamma sono pezzi a parte, messi sopra dal gioco; la pinna sta dietro, non in cima;
- la **corazza**: il collare e il ventre di scaglie, con le **spalline**, sulla spalla di ogni braccio, anche di quelle col pugno: una calotta di tre file di scaglie col bordo ciano, come il collare;
- gli **stivali** di scaglie con la fascia ciano e la pinna sul tallone;
- il **mantello** a membrana di pinna con le nervature ciano, largo e fatto per muoversi come quello del Vuoto (WB-032 B).

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-058/riferimenti/R1_teste_senza_corna.png` | le nove teste senza corna (WB-039) |
| R2 | `art/WB-058/riferimenti/R2_corpo_collo_nudo.png` | il foglio del corpo (WB-037): fazzoletto, busto col collo nudo, coda, due braccia, due gambe, pugno |
| R3 | `art/WB-058/riferimenti/R3_pugni.png` | le due braccia col pugno chiuso (WB-037), per le armi |
| R4 | `art/WB-058/riferimenti/R4_leviatano.png` | la tavola scelta della famiglia: a sinistra base, a destra forgiata |
| R5 | `art/WB-058/riferimenti/R5_stampino.png` | lo stampino: la casella `mantello` è la sagoma grigia fra busto e ala |
| R6 | `art/WB-058/riferimenti/R6_mantello_vuoto.png` | il mantello ampio del Vuoto (WB-032 B): la grandezza e il taglio largo da tenere, non lo stile |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Per teste, corpo e pugni si lavora SOPRA il foglio
indicato: stesso foglio, stessa misura, tutto il resto identico.

| Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|
| `art/WB-058/elmo_base.png` | R1, R4 | come R1 | 2 |
| `art/WB-058/elmo_forgiata.png` | R1, R4, `elmo_base_N.png` scelta | come R1 | 1 |
| `art/WB-058/corpo_base.png` | R2, R4 | 1536×1024 | 2 |
| `art/WB-058/corpo_forgiata.png` | R2, R4, `corpo_base_N.png` scelto | 1536×1024 | 1 |
| `art/WB-058/pugni_base.png` | R3, `corpo_base_N.png` scelto | 1536×1024 | 1 |
| `art/WB-058/pugni_forgiata.png` | R3, `corpo_forgiata.png` | 1536×1024 | 1 |
| `art/WB-058/mantello_base.png` | R4, R5, R6 | 1536×1024 | 2 |
| `art/WB-058/mantello_forgiata.png` | R4, R5, `mantello_base_N.png` scelto | 1536×1024 | 1 |

Le varianti si chiamano `elmo_base_1.png`, `elmo_base_2.png` e così via. Per teste e corpo Codex
sceglie la base col resto del foglio più identico al riferimento e lo scrive nel `.txt`; per il
mantello sceglie quello più largo in fondo e con le pieghe più lunghe. Le forgiate e i pugni
partono dalla base scelta.

### `elmo_base`

```
Image 1 is a sheet of nine heads of our character on flat magenta (the same head with nine faces, no horns). Image 2 is the chosen armour set "Leviathan" of our game: left the BASIC form, right the FORGED form.

Edit image 1 and return the SAME sheet: all nine heads stay exactly where they are, same size, same shapes, same faces, same pixels. Change only the FIRST head (top left): put on it the scale HELMET of the BASIC form of image 2: a snug helmet of teal fish scales that covers the top, the back and the sides of the head and frames the face, with a thin cyan trim along its edge around the face and a small light green fin at the BACK of the helmet (not on the top of the head, the top stays clean and round). The face stays fully visible and unchanged; the pointed ears come out on the sides. It is ONE CLOSED piece with a clean rounded top: no holes, no openings. Horns and the head flame will be drawn later on top of it as separate parts: draw no horns and no flame. The other eight heads do not change at all.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Scales teal #2F7F74 with shadows #1F5A54, light sea green #8FD8BE for the belly scales, the fins and the cape membrane, cyan #00FFFF trims, thick closed black #000000 outline like the other parts. The armour colours must be clearly different from the red skin.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `elmo_forgiata`

```
Image 1 is a sheet of nine heads of our character. Image 2 is the chosen armour set "Leviathan" (right: FORGED form). Image 3 is image 1 with the basic headpiece already drawn on the first head.

Return image 3 again, the SAME sheet with every head exactly where it is and the same pixels, and change only the headpiece on the first head: make it the FORGED one of image 2, keeping the outline of image 3, plus: the fin at the back becomes taller and jagged, with a cyan rim (still at the back, not on the top of the head). It stays one closed piece: no holes, no horns, no flame. Nothing else on the sheet changes.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Scales teal #2F7F74 with shadows #1F5A54, light sea green #8FD8BE for the belly scales, the fins and the cape membrane, cyan #00FFFF trims, thick closed black #000000 outline like the other parts.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `corpo_base`

```
Image 1 is a sheet of body parts of our character on flat magenta: the green neckerchief at the top, the torso with a bare neck in the middle, the tail, two arms, two legs and a fist below. Image 2 is the chosen armour set "Leviathan" of our game: left the BASIC form, right the FORGED form.

Edit image 1 and return the SAME sheet: every part stays exactly where it is, same size, same shapes, same colors, same pixels. Change only these:
1. On the torso: the ARMOUR of the BASIC form of image 2: a scale armour: a collar of teal scales around the base of the neck with a cyan rim and a round cyan clasp in the middle, and rows of large light sea green scales covering the chest and the belly, with teal scales on the sides. The armour follows the outline of the torso exactly and leaves the bare neck stub free.
2. On the top of BOTH arms, over the shoulder: a SHOULDER PAD that belongs to this armour: a rounded cap of three rows of teal fish scales, with a thin cyan rim along its lower edge. The pad covers the rounded top of the arm and the upper part of the upper arm, follows the arm's outline and is a little wider than the arm; the rest of the arm, the hand and the fingers stay bare and unchanged. Both arms get the same pad.
3. On BOTH legs: the BOOTS of the BASIC form of image 2: teal scale boots covering the feet and the lower part of the leg up to the middle of the shin, with a cyan band at the top and a small light green fin at the heel. The toes are hidden inside the boots; the boots keep the shape of the foot.
The neckerchief, the tail and the fist do not change at all.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Scales teal #2F7F74 with shadows #1F5A54, light sea green #8FD8BE for the belly scales, the fins and the cape membrane, cyan #00FFFF trims, thick closed black #000000 outline like the other parts. The armour colours must be clearly different from the red skin.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `corpo_forgiata`

```
Image 1 is a sheet of body parts of our character. Image 2 is the chosen armour set "Leviathan" (right: FORGED form). Image 3 is image 1 with the basic armour on the torso, a shoulder pad on the top of both arms and the basic boots on both legs.

Return image 3 again, the SAME sheet with every part exactly where it is and the same pixels, and change only the armour, the two shoulder pads and the boots: make them the FORGED versions of image 2, keeping the outlines of image 3:
- armour: three small cyan diamonds in a column down the middle of the chest, like in image 2;
- shoulder pads: a small jagged light green fin with a cyan rim standing on the top of each pad, the same on both arms;
- boots: a larger jagged fin with a cyan rim at the heel of each boot, like in image 2.
Nothing else on the sheet changes.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Scales teal #2F7F74 with shadows #1F5A54, light sea green #8FD8BE for the belly scales, the fins and the cape membrane, cyan #00FFFF trims, thick closed black #000000 outline like the other parts.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `pugni_base`

```
Image 1 is a sheet with two arms of our character with a closed fist, on flat magenta. Image 2 is a sheet of the same character where both bare arms wear a teal scale shoulder pad.

Edit image 1 and return the SAME sheet: both arms exactly where they are, same size, same shapes, same pixels. Change only the top of each arm: put on it the SAME shoulder pad as on the arms of image 2, same shape, same details, same colours, same size relative to the arm, over the shoulder. The rest of each arm and the fist stay bare and unchanged.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Scales teal #2F7F74 with shadows #1F5A54, light sea green #8FD8BE for the belly scales, the fins and the cape membrane, cyan #00FFFF trims, thick closed black #000000 outline like the other parts.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `pugni_forgiata`

```
Image 1 is a sheet with two arms of our character with a closed fist, on flat magenta. Image 2 is a sheet of the same character where both arms wear the FORGED scale shoulder pad with a small cyan-rimmed fin.

Edit image 1 and return the SAME sheet: both arms exactly where they are, same size, same shapes, same pixels. Change only the top of each arm: put on it the SAME forged shoulder pad as on the arms of image 2, same shape, same details, same colours, same size relative to the arm. The rest of each arm and the fist stay bare and unchanged.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Scales teal #2F7F74 with shadows #1F5A54, light sea green #8FD8BE for the belly scales, the fins and the cape membrane, cyan #00FFFF trims, thick closed black #000000 outline like the other parts.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `mantello_base`

```
Image 1 is the chosen armour set "Leviathan" of our game (left: BASIC form, right: FORGED form). Image 2 is our "stampino": a sheet with grey body parts on magenta; the grey trapezoid between the torso and the wing is the box "mantello". Image 3 is a cape of another set of our game: keep its SIZE on the sheet, its wide flare and its long folds, but NOT its style or its colours.

Draw ONE cape of the BASIC form of image 1, alone, as large on the sheet as the cape of image 3: a cape like the membrane of a great fin, light sea green with four or five thin cyan ribs running from the top edge down to the hem. Seen from the side, hanging straight down behind the shoulders as if the wearer stood still: the top edge is short, straight and horizontal, at the top right (where it is tied to the shoulders), no hood, no collar roll, no clasp hanging over the edge. The cape gets much wider toward the bottom: at the hem it is about twice as wide as at the top, flaring out to the left (the back). The hem is scalloped between the ribs, like a fin, with soft rounded points. Long folds or lines run from the top edge all the way down to the hem, so the cape can bend anywhere. Length: down to the knee of the wearer. No body, no arms, no shoulders, nothing else on the sheet.

Same rendering rules as image 1: flat colors, thick closed black outline. Scales teal #2F7F74 with shadows #1F5A54, light sea green #8FD8BE for the belly scales, the fins and the cape membrane, cyan #00FFFF trims, nothing else. Background: flat pure magenta #FF00FF everywhere outside the cape. Do not draw the box, crosses or labels. No text. Landscape 3:2.
```

### `mantello_forgiata`

```
Image 1 is the chosen armour set "Leviathan" of our game (right: FORGED form). Image 2 is our "stampino". Image 3 is the basic cape of this set, alone on magenta.

Return image 3 again: the same cape, same position, same size, the same outline and folds. Change only this: make it the FORGED cape of image 1: the ribs end in small sharp cyan spikes that stick out below the hem, like in image 1. Nothing else changes. No body, nothing else on the sheet.

Same rendering rules: flat colors, thick closed black outline. Scales teal #2F7F74 with shadows #1F5A54, light sea green #8FD8BE for the belly scales, the fins and the cape membrane, cyan #00FFFF trims, nothing else. Background: flat pure magenta #FF00FF everywhere outside the cape. No text. Landscape 3:2.
```

## Criteri di accettazione

- [ ] ogni foglio di teste, corpo e pugni è il suo riferimento identico (stessi pezzi, stesse posizioni, stessa misura) tranne i pezzi della famiglia
- [ ] l'elmo solo sulla prima testa, chiuso in cima: niente buchi, corna o fiamma; pinna dietro, faccia intera e uguale, orecchie fuori
- [ ] la corazza segue il busto e lascia libero il collo; gli stivali su tutte e due le gambe
- [ ] le spalline in cima a tutte e due le braccia (anche quelle col pugno), uguali, un po' più larghe del braccio; mano e dita nude e uguali
- [ ] il mantello è uno solo per foglio, grande come R6, bordo in alto corto e dritto a destra, largo in fondo
- [ ] scaglie verde mare; colori piatti, contorno nero chiuso e spesso, magenta pulito, nessuna scritta
- [ ] le forgiate hanno le stesse sagome delle basi, con le finiture in più

---

## Decisione

Approvata da Sergio il 15 nov («Smazziamocele tutte»). (Claude) Spalline del Leviatano: calotta di tre file di scaglie col bordo ciano; forgiate con una piccola pinna. La pinna dell'elmo va dietro, perché in cima ci sono le corna e la fiamma.

## Consegna di Codex

## Resoconto di Claude

15 nov. Guardati gli undici fogli di `design/WB-058`: tutti buoni, nessuno scartato.

- **Tenuti:** `elmo_base_1`, `elmo_forgiata`, `corpo_base_1`, `corpo_forgiata`, `pugni_base`,
  `pugni_forgiata`, `mantello_base_1`, `mantello_forgiata`. Riserve: le varianti `_2`.
- **Colori:** la tavolozza `apprendista_leviatano.json` segue quelli disegnati da Codex (squame #2E8478 con la loro ombra, verde chiaro #90DCBC, ciano).
- **Ritocchi dello strumento:** sul braccio col pugno Codex ha fatto la spallina un filo più stretta
  del braccio; `addosso.py` chiude col contorno quello che resterebbe scoperto sopra l'orlo.
- **Nel gioco:** pelli `elmo_leviatano`, `corazza_leviatano`, `stivali_leviatano`, `mantello_leviatano` (e `_forgiato`), con
  `tools/stampino/addosso.py tools/stampino/addosso/leviatano.json` e `taglia.py --mantello-px 7.2`; i
  pezzi del Leviatano indossati le mettono addosso. Scenari `leviatano_indossato.txt` e `leviatano_indossato_forgiato.txt`.
