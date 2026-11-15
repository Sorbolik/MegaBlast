# WB-055 · Il Fabbro addosso all'apprendista: cuffia, corazza con spalline, stivali, mantello

- **Stato:** APPROVATA (Sergio, 15 nov: «Vai, inizia con quello che mi hai detto»)
- **Data:** 2026-11-15
- **Ramo della scheda:** `claude/project-thread-e8poye` · **Ramo delle immagini:** `design/WB-055`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-055` senza chiedere conferma (il repository è privato).

## Obiettivo

Per ora si vedono addosso solo i pezzi del Vuoto (WB-041, WB-042). Le altre quattro famiglie hanno
solo la tavola di stile di WB-019. Questa scheda è la **prova con una famiglia sola, il Fabbro**:
se viene bene, Corvo, Fornace e Leviatano la copiano.

Ogni pezzo si disegna **sul foglio dell'apprendista che veste, nella stessa posizione**, così si
ritaglia per differenza e calza senza metterlo a occhio. Due forme: base e forgiata (stessa
sagoma, con le finiture ciano). Rispetto al Vuoto, tutto in una volta:

- la **cuffia** (elmo) è **chiusa**: le corna e la fiamma sono pezzi a parte, messi sopra dal gioco;
- la **corazza** (il grembiule di cuoio) ha le **spalline**, sulla spalla di ogni braccio, anche di
  quelle col pugno. Nella tavola di stile non ci sono: qui sono una calotta di cuoio spesso con una
  cinghia chiara e una borchia d'ottone, come le cinghie del grembiule;
- gli **stivali** da lavoro, con la fibbia;
- il **mantello** di cuoio, largo e fatto per muoversi come quello del Vuoto (WB-032 B).

Il cuoio è volutamente più bruno e più scuro della pelle rossa del diavoletto, così il ritaglio
li distingue. Il martello sulla cuffia forgiata è d'ottone, non ciano (resoconto di WB-019).

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-055/riferimenti/R1_teste_senza_corna.png` | le nove teste senza corna (WB-039) |
| R2 | `art/WB-055/riferimenti/R2_corpo_collo_nudo.png` | il foglio del corpo (WB-037): fazzoletto, busto col collo nudo, coda, due braccia, due gambe, pugno |
| R3 | `art/WB-055/riferimenti/R3_pugni.png` | le due braccia col pugno chiuso (WB-037), per le armi |
| R4 | `art/WB-055/riferimenti/R4_fabbro.png` | la tavola scelta del Fabbro: a sinistra base, a destra forgiata |
| R5 | `art/WB-055/riferimenti/R5_stampino.png` | lo stampino: la casella `mantello` è la sagoma grigia fra busto e ala |
| R6 | `art/WB-055/riferimenti/R6_mantello_vuoto.png` | il mantello ampio del Vuoto (WB-032 B): la grandezza e il taglio largo da tenere, non lo stile |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Per teste, corpo e pugni si lavora SOPRA il foglio
indicato: stesso foglio, stessa misura, tutto il resto identico.

| Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|
| `art/WB-055/cuffia_base.png` | R1, R4 | come R1 | 2 |
| `art/WB-055/cuffia_forgiata.png` | R1, R4, `cuffia_base_N.png` scelta | come R1 | 1 |
| `art/WB-055/corpo_base.png` | R2, R4 | 1536×1024 | 2 |
| `art/WB-055/corpo_forgiata.png` | R2, R4, `corpo_base_N.png` scelto | 1536×1024 | 1 |
| `art/WB-055/pugni_base.png` | R3, `corpo_base_N.png` scelto | 1536×1024 | 1 |
| `art/WB-055/pugni_forgiata.png` | R3, `corpo_forgiata.png` | 1536×1024 | 1 |
| `art/WB-055/mantello_base.png` | R4, R5, R6 | 1536×1024 | 2 |
| `art/WB-055/mantello_forgiata.png` | R4, R5, `mantello_base_N.png` scelto | 1536×1024 | 1 |

Le varianti si chiamano `cuffia_base_1.png`, `cuffia_base_2.png` e così via. Per cuffia e corpo
Codex sceglie la base col resto del foglio più identico al riferimento e lo scrive nel `.txt`;
per il mantello sceglie quello più largo in fondo e con le pieghe più lunghe. Le forgiate e i
pugni partono dalla base scelta.

### `cuffia_base`

```
Image 1 is a sheet of nine heads of our character on flat magenta (the same head with nine faces, no horns). Image 2 is the chosen armour set "Smith" of our game: left the BASIC form, right the FORGED form.

Edit image 1 and return the SAME sheet: all nine heads stay exactly where they are, same size, same shapes, same faces, same pixels. Change only the FIRST head (top left): put on it the leather CAP of the BASIC form of image 2: a snug blacksmith's skullcap of thick brown leather that covers the top and the back of the head down to the brow, with a leather band around it and the round brass work goggles with amber lenses pushed up on the forehead, held by their strap. The face stays fully visible and unchanged; the pointed ears come out below the cap on the sides. The cap is ONE CLOSED piece with a clean rounded top: no holes, no openings. Horns and the head flame will be drawn later on top of the cap as separate parts: draw no horns and no flame. The other eight heads do not change at all.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Leather dark brown #6B4A2B with folds #4A3019, lighter straps #C89255, brass #D9A441, amber lenses #F2B92C, thick closed black #000000 outline like the heads. The leather must be clearly browner and darker than the red skin.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `cuffia_forgiata`

```
Image 1 is a sheet of nine heads of our character. Image 2 is the chosen armour set "Smith" (right: FORGED form). Image 3 is image 1 with the basic leather cap already drawn on the first head.

Return image 3 again, the SAME sheet with every head exactly where it is and the same pixels, and change only the cap on the first head: make it the FORGED cap of image 2, with exactly the same outline as in image 3, plus: a small brass hammer emblem on the top front of the cap, above the goggles, and a thin pure cyan #00FFFF trim along the band of the cap and around the rims of the goggles. The cap stays one closed piece: no holes, no horns, no flame. Nothing else on the sheet changes.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Leather dark brown #6B4A2B with folds #4A3019, lighter straps #C89255, brass #D9A441 (the hammer too), amber lenses #F2B92C, cyan #00FFFF trims, thick closed black #000000 outline.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `corpo_base`

```
Image 1 is a sheet of body parts of our character on flat magenta: the green neckerchief at the top, the torso with a bare neck in the middle, the tail, two arms, two legs and a fist below. Image 2 is the chosen armour set "Smith" of our game: left the BASIC form, right the FORGED form.

Edit image 1 and return the SAME sheet: every part stays exactly where it is, same size, same shapes, same colors, same pixels. Change only these:
1. On the torso: the ARMOUR of the BASIC form of image 2, a blacksmith's apron of thick brown leather that covers the chest and the belly down to the bottom of the torso, with two lighter leather straps crossing in an X on the chest and going up over the shoulders. The apron follows the outline of the torso exactly and leaves the bare neck stub free.
2. On the top of BOTH arms, over the shoulder: a SHOULDER PAD that belongs to this armour: a rounded cap of the same thick brown leather, in two overlapping layers, with one lighter leather strap across it and one round brass rivet. The pad covers the rounded top of the arm and the upper part of the upper arm, follows the arm's outline and is a little wider than the arm; the rest of the arm, the hand and the fingers stay bare and unchanged. Both arms get the same pad.
3. On BOTH legs: the BOOTS of the BASIC form of image 2, sturdy brown leather work boots covering the feet and the lower part of the leg up to the middle of the shin, with a leather strap and one square cyan buckle on the front. The toes are hidden inside the boots; the boots keep the shape of the foot.
The neckerchief, the tail and the fist do not change at all.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Leather dark brown #6B4A2B with folds #4A3019, lighter straps #C89255, brass #D9A441, cyan #00FFFF only on the boot buckles, thick closed black #000000 outline like the other parts. The leather must be clearly browner and darker than the red skin.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `corpo_forgiata`

```
Image 1 is a sheet of body parts of our character. Image 2 is the chosen armour set "Smith" (right: FORGED form). Image 3 is image 1 with the basic leather apron on the torso, a leather shoulder pad on the top of both arms and the basic boots on both legs.

Return image 3 again, the SAME sheet with every part exactly where it is and the same pixels, and change only the apron, the two shoulder pads and the boots: make them the FORGED versions of image 2, with exactly the same outlines as in image 3:
- apron: round cyan rivets at the ends of the crossing straps and at the corners of the apron, like in image 2;
- shoulder pads: a brass rim plate along the lower edge of each pad and two round cyan rivets on it, the same on both arms;
- boots: a second strap with a second square cyan buckle, like in image 2.
Nothing else on the sheet changes.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Leather dark brown #6B4A2B with folds #4A3019, lighter straps #C89255, brass #D9A441, cyan #00FFFF rivets and buckles, thick closed black #000000 outline.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `pugni_base`

```
Image 1 is a sheet with two arms of our character with a closed fist, on flat magenta. Image 2 is a sheet of the same character where both bare arms wear a brown leather shoulder pad.

Edit image 1 and return the SAME sheet: both arms exactly where they are, same size, same shapes, same pixels. Change only the top of each arm: put on it the SAME shoulder pad as on the arms of image 2, same shape, same layers, same strap and rivet, same colours, same size relative to the arm, over the shoulder. The rest of each arm and the fist stay bare and unchanged.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Leather dark brown #6B4A2B with folds #4A3019, lighter strap #C89255, brass #D9A441, thick closed black #000000 outline like the arms.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `pugni_forgiata`

```
Image 1 is a sheet with two arms of our character with a closed fist, on flat magenta. Image 2 is a sheet of the same character where both arms wear the FORGED leather shoulder pad with a brass rim plate and cyan rivets.

Edit image 1 and return the SAME sheet: both arms exactly where they are, same size, same shapes, same pixels. Change only the top of each arm: put on it the SAME forged shoulder pad as on the arms of image 2, same shape, same brass rim, same cyan rivets, same size relative to the arm. The rest of each arm and the fist stay bare and unchanged.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Leather dark brown #6B4A2B with folds #4A3019, lighter strap #C89255, brass #D9A441, cyan #00FFFF rivets, thick closed black #000000 outline like the arms.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `mantello_base`

```
Image 1 is the chosen armour set "Smith" of our game (left: BASIC form, right: FORGED form). Image 2 is our "stampino": a sheet with grey body parts on magenta; the grey trapezoid between the torso and the wing is the box "mantello". Image 3 is a cape of another set of our game: keep its SIZE on the sheet, its wide flare and its long folds, but NOT its style, its colours or its torn hem.

Draw ONE cape of the BASIC form of image 1, alone, as large on the sheet as the cape of image 3: a blacksmith's cape of heavy brown leather. Seen from the side, hanging straight down behind the shoulders as if the wearer stood still: the top edge is short, straight and horizontal, at the top right (where it is tied to the shoulders), no hood, no collar roll, no clasp hanging over the edge. The cape gets much wider toward the bottom: at the hem it is about twice as wide as at the top, flaring out to the left (the back). The hem is one clean, slightly wavy line with a stitched leather border, not torn. Long folds run from the top edge all the way down to the hem, so the leather can bend anywhere. Length: down to the knee of the wearer. No body, no arms, no shoulders, nothing else on the sheet.

Same rendering rules as image 1: flat colors, leather dark brown #6B4A2B with darker #4A3019 folds, lighter border #C89255, thick closed black outline. Background: flat pure magenta #FF00FF everywhere outside the cape. Do not draw the box, crosses or labels. No text. Landscape 3:2.
```

### `mantello_forgiata`

```
Image 1 is the chosen armour set "Smith" of our game (right: FORGED form). Image 2 is our "stampino". Image 3 is the basic leather cape of this set, alone on magenta.

Return image 3 again: the same cape, same position, same size, exactly the same outline and folds. Change only this: make it the FORGED cape of image 1: along the hem add a brass band with a row of round pure cyan #00FFFF rivets, like in image 1. Nothing else changes. No body, nothing else on the sheet.

Same rendering rules: flat colors, leather dark brown #6B4A2B with darker #4A3019 folds, lighter border #C89255, brass #D9A441, cyan #00FFFF rivets, thick closed black outline. Background: flat pure magenta #FF00FF everywhere outside the cape. No text. Landscape 3:2.
```

## Criteri di accettazione

- [ ] ogni foglio di teste, corpo e pugni è il suo riferimento identico (stessi pezzi, stesse posizioni, stessa misura) tranne i pezzi del Fabbro
- [ ] la cuffia solo sulla prima testa, chiusa: niente buchi, corna o fiamma; faccia intera e uguale, orecchie fuori
- [ ] il grembiule segue il busto e lascia libero il collo; gli stivali su tutte e due le gambe, con la forma del piede
- [ ] le spalline in cima a tutte e due le braccia (anche quelle col pugno), uguali, un po' più larghe del braccio; mano e dita nude e uguali
- [ ] il mantello è uno solo per foglio, grande come R6, bordo in alto corto e dritto a destra, largo in fondo, pieghe lunghe, orlo intero
- [ ] cuoio bruno ben distinto dalla pelle rossa; colori piatti, contorno nero chiuso e spesso, magenta pulito, nessuna scritta
- [ ] le forgiate hanno le stesse sagome delle basi, con le finiture ciano e l'ottone

---

## Decisione

Approvata da Sergio il 15 nov («Vai, inizia con quello che mi hai detto»). (Claude) Spalline del
Fabbro: calotta di cuoio a due strati con cinghia chiara e borchia d'ottone; forgiate con bordo
d'ottone e borchie ciano. Cuoio più bruno della tavola di stile, per distinguerlo dalla pelle.

## Consegna di Codex

## Resoconto di Claude
