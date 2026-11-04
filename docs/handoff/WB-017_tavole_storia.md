# WB-017 · Le tavole nuove della storia della campagna

- **Stato:** APPROVATA (Claude, 2026-11-04: Sergio ha scelto la proposta B; il 4 nov ha detto sì agli stivali, quindi anche la fase 2)
- **Data:** 2026-11-04
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-017`

## Obiettivo

Sergio (4 nov): «voglio la storia, almeno all'ingresso della campagna la prima volta», con
le vignette illustrate una dopo l'altra e i dialoghi. Ha scelto la proposta B
(https://claude.ai/artifact/MRGtRcTEyXSAYEZP7kWgF8): la storia è un fumetto in cinque
capitoli, uno per ogni svolta. Otto tavole ci sono già (WB-012: l'arrivo, il Fabbro, il
rapimento); qui si fanno le **cinque che mancano**. Le frasi le scrive il gioco nei fumetti,
nello spazio calmo di ogni tavola: nelle immagini niente scritte.

| Capitolo | Quando | Tavole |
|---|---|---|
| 1 · Prologo | la prima volta che apri la CAMPAGNA | **`s_viaggio`**, poi `4_arrivo_a`, `4_arrivo_b`, `4_arrivo_c`, `5_fabbro_a`, `5_fabbro_c_1` |
| 2 · La Forgia si apre | vinto il Duello con Favilla | **`s_forgia_aperta`** |
| 3 · Insieme | prima della Battaglia della Forgia | **`s_insieme`** |
| 4 · Il regalo | vinta la Battaglia, prima del rapimento: si apre l'ARMERIA | **`s_regalo`** (fase 2) |
| 5 · Il rapimento | vinta la Battaglia: si apre la mappa dei gironi | `6_rapimento_a`, `6_rapimento_b`, `6_rapimento_c`, **`s_ghiaccio`** |

## Due fasi, due comandi

- **Fase 1**, `esegui WB-017 fase 1`: `s_viaggio`, `s_forgia_aperta`, `s_insieme`, `s_ghiaccio`.
- **Fase 2**, `esegui WB-017 fase 2`: `s_regalo`, il Fabbro che regala gli stivali (Sergio, 4 nov:
  «gli stivali vanno bene»). Si può dare insieme alla fase 1.
- Codex esegue solo le righe della fase chiesta; se un riferimento della fase non c'è, si ferma.

## Cosa teniamo e cosa scartiamo

| Teniamo | Perché |
|---|---|
| Lo stile delle tavole di WB-012 (R4): fumetto, contorno nero spesso, colori pieni, tratteggio leggero nelle ombre | le tavole nuove si leggono in fila con quelle vecchie |
| I personaggi copiati dai fogli scelti (R1, R2, R3) e la coda di Favilla dalla sua figura (R5), detta una volta sola | lezione di WB-012 fase 2b: insistere sulla coda la capovolge |
| Uno spazio calmo (muro scuro, cielo) in un angolo per i fumetti | il testo lo mette il gioco |
| Lucifero mai mostrato: solo due occhi nel buio | non è ancora disegnato; lo spoiler è dove sta Favilla, non chi l'ha presa |

| Scartiamo | Perché |
|---|---|
| Scritte, fumetti, numeri, firme | il testo lo scrive il gioco, in tutte le lingue |
| Il martello in mano al Fabbro | scelta di WB-014: niente martello, niente fumo, niente coda |

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-012/scelti/apprendista.png` | il foglio dell'apprendista scelto (con la fiammella) |
| R2 | `art/WB-012/scelti/favilla.png` | il foglio di Favilla scelto |
| R3 | `art/WB-012/scelti/fabbro.png` | il foglio del Fabbro scelto |
| R4 | `art/WB-012/4_arrivo_a.png` | una tavola della storia: lo stile da copiare |
| R5 | `art/WB-012/riferimenti/R9_favilla_figura.png` | Favilla a figura intera: la coda |
| R6 | `art/WB-012/6_rapimento_b.png` | il baratro di ghiaccio, per `s_ghiaccio` |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto: il
primo è "image 1", il secondo "image 2" e così via. Misura 1536×1024, una variante per
immagine, sfondo della scena (non trasparente).

| Fase | Nome file | Riferimenti | Capitolo |
|---|---|---|---|
| 1 | `s_viaggio` | R1, R4 | 1 · Prologo |
| 1 | `s_forgia_aperta` | R3, R1, R4 | 2 · La Forgia si apre |
| 1 | `s_insieme` | R1, R2, R5, R4 | 4 · Insieme |
| 1 | `s_ghiaccio` | R2, R5, R6, R4 | 5 · Il rapimento |
| 2 | `s_regalo` | R3, R1, R4 | 3 · Il regalo |

### `s_viaggio`

```
Image 1 is the model sheet of the apprentice imp, image 2 the illustration style. Copy him EXACTLY from his sheet (shapes, colors, flame on his head, blue neckerchief, tail); do not redesign him.

A wide comic panel, the opening of the story: a rocky path winding down a dark volcanic slope at dusk, red sky with ash. Far below and in the middle of the picture, the hellish Forge glows: a big stone and iron building with chimneys, lava light pouring from its gate. In the foreground on the left, seen from behind three-quarter, the small apprentice imp walks down the path with a little bundle tied to a stick over his shoulder, looking toward the Forge, excited. Leave the top-left quarter of the picture calm (dark red sky) for a speech balloon the game adds. Style of image 2. No text, letters, numbers, speech balloons or signatures.
```

### `s_forgia_aperta`

```
Image 1 is the model sheet of the Blacksmith, image 2 the model sheet of the apprentice imp, image 3 the illustration style. Copy both EXACTLY from their sheets; the Blacksmith has NO hammer in his hands.

A wide comic panel: inside the courtyard of the hellish forge, the huge Blacksmith pushes open a giant iron double gate with both gloved hands; through the opening pours bright orange light from the great forge hall beyond, with anvils, chains and rivers of molten metal. The small apprentice imp stands in the light in front of the gate, amazed, mouth open, his shadow long behind him. Leave the top-right quarter calm (dark wall) for a speech balloon the game adds. Style of image 3. No text, letters, numbers, speech balloons or signatures.
```

### `s_insieme`

```
Image 1 is the model sheet of the apprentice imp, image 2 the model sheet of Favilla, image 3 Favilla's full figure (look at her tail there), image 4 the illustration style. Copy both characters EXACTLY from their sheets (shapes, colors, flames, clothes; Favilla's tail exactly as in image 3); do not redesign them.

A wide comic panel before the big battle: in the middle of a stone arena inside the hellish forge, the apprentice imp and Favilla stand back to back, ready to fight, both grinning with determination, fists up. Sparks fly around them, lava light from below, the arena walls dark. Keep them in the middle; leave the top-left quarter calm (dark wall) for a speech balloon the game adds. Style of image 4. No text, letters, numbers, speech balloons or signatures.
```

### `s_ghiaccio`

```
Image 1 is the model sheet of Favilla, image 2 Favilla's full figure (look at her tail there), image 3 the icy chasm where she fell, image 4 the illustration style. Copy Favilla EXACTLY from her sheet; do not redesign her.

A wide dark comic panel, the very bottom of hell: a frozen lake of blue-black ice in a huge dark cave. In the middle, Favilla is trapped inside a big clear block of ice, eyes closed, her white-blue flame hair frozen still but still glowing softly: she is the only warm light in the picture. Far behind her, in the deep darkness, only two enormous glowing eyes are visible, nothing else of the creature they belong to: no body, no face, no horns. Frost on the edges of the picture, cold and silent. Leave the top quarter calm (darkness) for a caption the game adds. Style of image 4. No text, letters, numbers, speech balloons or signatures.
```

### `s_regalo` (fase 2)

```
Image 1 is the model sheet of the Blacksmith, image 2 the model sheet of the apprentice imp, image 3 the illustration style. Copy both EXACTLY from their sheets; the Blacksmith has NO hammer.

A wide warm comic panel inside the forge: the huge Blacksmith kneels down on one knee to be closer to the small apprentice imp and holds out to him, in his big gloved hands, a pair of small sturdy boots made of dark brown leather with iron toe caps and a brass buckle, still warm from the forge with a few sparks around them. The apprentice, barefoot as always, looks at the boots with wide happy eyes and both hands raised in surprise. The Blacksmith gives a proud half smile under his moustache. Leave the top-right quarter calm (dark wall) for a speech balloon the game adds. Style of image 3. No text, letters, numbers, speech balloons or signatures.
```

## Criteri di accettazione

- [ ] i personaggi sono quelli dei fogli: apprendista con la fiammella e il fazzoletto blu, Favilla con la fiamma bianco-azzurra, salopette e stivali, la coda come in R5; il Fabbro con la fornace a cinque sbarre e senza martello
- [ ] in `s_ghiaccio` di Lucifero si vedono solo i due occhi
- [ ] in `s_regalo` gli stivali sono semplici (cuoio, punta di ferro, una fibbia) e l'apprendista è scalzo
- [ ] l'angolo calmo per i fumetti c'è
- [ ] stile delle tavole (R4), nessuna scritta, numero, fumetto o firma
- [ ] 1536×1024

## Dopo le immagini (lo fa Claude)

Guarda ogni tavola (coda di Favilla, mani, personaggi giusti) e scarta quelle con difetti; per
le scartate corregge il prompt qui e chiede una fase «b». Le buone vanno fra le tavole della
storia del gioco con le loro frasi, poi la simulazione e le foto a Sergio.

---

## Decisione

Approvata da Claude il 4 nov 2026: Sergio ha scelto la proposta B («vanno bene tutte le
decisioni»). Fase 2 approvata da Sergio lo stesso giorno: «gli stivali vanno bene».

## Consegna di Codex

### Fase 1 · 2026-11-04

Eseguita da `main` aggiornato (`7741cc4`), ramo `design/WB-017`.
Generazione con `image_gen` integrato, prompt integrali invariati e riferimenti
nell'ordine prescritto; sfondi delle scene, non trasparenti. Fase 2 non eseguita.

File in `art/WB-017/`, ciascuno con PNG e TXT contenente prompt e riferimenti:

| Nome | Tentativi | Selezione |
|---|---|---|
| `s_viaggio` | 1 | primo |
| `s_forgia_aperta` | 3 | secondo |
| `s_insieme` | 1 | primo |
| `s_ghiaccio` | 1 | primo |

Guardate tutte le immagini prima del salvataggio: personaggi e abiti, fiamme,
mani e arti, code senza tagli o duplicazioni visibili, contorni neri, assenza
di scritte, numeri, fumetti e firme; spazio calmo negli angoli richiesti.
Nel ghiaccio Favilla ha gli occhi chiusi ed è intera dentro il blocco; della
creatura si vedono soltanto i due occhi, senza corpo, volto o corna.

Per la Forgia, il primo tentativo aveva una posa poco coerente con le mani
sulle due ante. Il secondo corregge la posa; fatto un terzo per il dubbio sul
conteggio delle sbarre, ma una mano non raggiunge l'anta. Consegnato il secondo,
il migliore per la scena richiesta. **La fornace sembra avere quattro sbarre
interne anziché cinque: criterio non confermato, da rivedere da Claude.**
Il Fabbro è senza martello e senza coda visibile, ma conserva il fumo del
foglio R3: discrepanza con «niente fumo» di DECISIONI.md (WB-014). Il prompt
prescrive la copia esatta del foglio e non esclude il fumo: non l'ho modificato.

**Formato non conforme:** tutti e quattro i PNG originali sono **1672×941**,
verificati sui file, anziché 1536×1024. Lo strumento non espone un parametro
dimensioni; non aggiunte istruzioni ai prompt né applicati ritagli o deformazioni.
Non verificati il montaggio dei fumetti, la resa nel client e sul telefono,
né l'identità pixel per pixel rispetto ai fogli. Revisione e integrazione a Claude.

## Resoconto di Claude

### Fase 1 · 2026-11-04

Tenute tutte e quattro e messe nel gioco (#214): `s_viaggio` apre il Prologo, `s_forgia_aperta`
e `s_insieme` sono i loro capitoli, `s_ghiaccio` chiude il rapimento. 1672 × 941 va bene: è la
misura delle altre tavole e la cartolina della storia segue la forma della tavola, quindi niente
ritagli. Gli angoli calmi tengono i fumetti senza coprire facce (foto del simulatore, scenari
`storia*.txt`). Note accettate: in `s_insieme` sono fianco a fianco più che schiena a schiena
(la battuta «Io e te, insieme» va bene lo stesso); in `s_forgia_aperta` il fumo della fornace è
quello del foglio R3, ed è il Fabbro del foglio, mentre «niente fumo» vale per i pezzi dello
stampino di WB-014; le sbarre della fornace sono quattro, non si notano. Fase 2 (`s_regalo`) da
eseguire (Claude).
