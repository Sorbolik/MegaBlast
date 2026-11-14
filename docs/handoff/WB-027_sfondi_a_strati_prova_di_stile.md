# WB-027 · Sfondi a strati dei menu: prova di stile

- **Stato:** APPROVATA (Claude, 2026-11-12: solo una prova di stile, quattro immagini, reversibile)
- **Data:** 2026-11-12
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-027`

## Obiettivo

Sergio (12 nov) ha scartato gli sfondi a linee di WB-023 e WB-025: «molto cheap», non coerenti
coi pezzi a fumetto di WB-022, senza profondità. Vuole sfondi «più premium», con profondità e
coerenti con la storia. Claude ha studiato come si fanno gli sfondi dei menu nei giochi mobile
e ha fatto dei bozzetti col codice (pagina https://claude.ai/artifact/8Vtj3sQas5mHQry8eD7Myo):
ogni menu è un posto della storia, fatto di tre piani e due luci. Questa scheda chiede a Codex
di **dipingere davvero quattro di quei bozzetti**, per vedere la mano finale prima di fare
tutte le schermate.

## Le regole dello sfondo (valgono per tutte le immagini)

| Regola | Perché |
|---|---|
| Tre piani: lontano, medio, vicino. Il lontano è il più chiaro e sfumato e prende il colore della luce; il vicino è quasi nero e fuori fuoco | è questo che dà profondità |
| **Nessun contorno nero** nello sfondo | il contorno a china è dei pulsanti e dei personaggi: se lo ha anche lo sfondo, litigano |
| Forme grandi e piatte, sfumature morbide, **pochissimi dettagli**: niente mattoni, crepe, venature, chiodi, texture | WB-020 è stata scartata perché «troppo dettagliata» |
| Tutto scuro e poco saturo; i colori accesi solo nelle due luci | l'arancio pieno e l'oro sono dei pulsanti |
| Due luci: la fornace calda **in basso a sinistra**, il gelo **in alto a destra** | l'identità del gioco, uguale in ogni schermata |
| Il caldo è fatto di forme tonde, il freddo di spigoli | regola approvata di «Filo di brace» |
| Il centro e la zona dei pulsanti restano lisci e calmi | sopra ci sono scritte e pulsanti |
| Niente personaggi, niente scritte, niente pulsanti | li mette il gioco |

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-027/riferimenti/R1_bozzetto_home_A.jpg` | bozzetto della home, strada A (dipinto a strati): composizione, luci e toni da rispettare |
| R2 | `art/WB-027/riferimenti/R2_bozzetto_home_B.jpg` | bozzetto della home, strada B (teatro di carta) |
| R3 | `art/WB-027/riferimenti/R3_bozzetto_armeria_A.jpg` | bozzetto dell'armeria, strada A |
| R4 | `art/WB-027/riferimenti/R4_bozzetto_campagna_A.jpg` | bozzetto della campagna, strada A |
| R5 | `art/WB-027/riferimenti/R5_home_con_interfaccia.jpg` | la home col diavoletto e i pulsanti sopra: fa vedere dove sta l'interfaccia e quanto deve restare calmo lo sfondo. **Non va ridisegnata** |

I bozzetti sono fatti col codice: dicono **dove** stanno le cose, le luci e i toni. La mano
(forme più belle, sfumature dipinte, aria) la mette Codex.

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Formato largo 16:9 (1672×941 o più), una variante.

| Nome file | Riferimenti (in quest'ordine) | Cos'è |
|---|---|---|
| `sfondo_home_A` | R1, R5 | la soglia della Forgia, dipinta a strati |
| `sfondo_home_B` | R2, R5 | la stessa scena, a sagome di carta |
| `sfondo_armeria_A` | R3, R5 | il banco del Fabbro |
| `sfondo_campagna_A` | R4, R5 | l'orlo del pozzo |

### `sfondo_home_A`

```
Image 1 is a rough code-made sketch of a background for the main menu of a mobile game about little devils in Dante's hell. Image 2 shows the same background in use, with the character and the comic-style buttons on top: it is there only to show where the interface sits and how quiet the background must be. Do NOT draw the character, the buttons, the line or any text.

Paint a finished, premium version of the background in image 1, wide 16:9, keeping its composition, its two light sources and its dark tonal range. The place: the threshold of an underground forge. On the far left, partly off-screen, the round arched mouth of a furnace glowing soft orange-yellow, the only warm light. Under a dark ceiling two blacksmith tools (a hammer and a pair of tongs) hang on chains as small soft silhouettes. Near the middle, on the floor, the dark silhouette of an anvil with a thin warm rim light on its left side. On the right the vault of the cave is broken open: cold pale-blue light comes from the top-right corner, with icicles hanging from above, ice spires rising from below in the distance, and a few big translucent ice crystals growing in from the top-right corner. The ice is invading the forge.

Style: stylized 2D game background made of three depth planes with atmospheric perspective. Far plane: the lightest, soft-edged, tinted by the light behind it (dull orange on the left, dull blue on the right). Middle plane: darker simple silhouettes with a thin rim of light. Near plane: almost black, out-of-focus shapes at the bottom-left corner (a round pile of coal) and at the corners on the right (a sharp ice shard), framing the picture. Big flat shapes with smooth soft gradients, like a modern mobile game lobby background. NO black outlines, no ink lines, no hatching. Very little detail: no bricks, no cracks, no rivets, no surface texture, no noise. Warm shapes are round, cold shapes are sharp and angular.

Colours: overall dark and desaturated (soot brown-black, deep navy), brightness only near the two lights; the centre of the picture is the darkest and calmest area. A flat dark floor band along the bottom fifth with a faint warm pool of light on the left and a faint cold one on the right. A soft dark vignette at the edges.

No characters, no creatures, no text, no letters, no numbers, no interface, no frame, no signature.
```

### `sfondo_home_B`

```
Image 1 is a rough code-made sketch of a background for the main menu of a mobile game about little devils in Dante's hell. Image 2 shows a similar background in use, with the character and the comic-style buttons on top: it is there only to show where the interface sits and how quiet the background must be. Do NOT draw the character, the buttons, the line or any text.

Paint a finished, premium version of the background in image 1, wide 16:9, keeping its composition, its two light sources and its dark tonal range. The place: the threshold of an underground forge. On the far left, partly off-screen, the round arched mouth of a furnace glowing orange-yellow, the only warm light. Under a dark ceiling two blacksmith tools (a hammer and a pair of tongs) hang on chains. Near the middle, on the floor, the silhouette of an anvil. On the right the vault of the cave is broken open: cold pale-blue light comes from the top-right corner, with icicles hanging from above, ice spires rising from below, and a few big ice crystals growing in from the top-right corner. The ice is invading the forge.

Style: a layered cut-paper theatre (paper diorama). Every depth plane is a crisp flat silhouette cut out of dark coloured paper, stacked one in front of the other; each layer casts a soft drop shadow on the layer behind it and has a thin bright edge where the light hits it (warm orange on the left, pale blue on the right). Far layers are lighter and tinted by the light, near layers are almost black. Flat colours with only gentle gradients. NO black outlines, no ink lines, no hatching. Very little detail: no bricks, no cracks, no rivets, no surface texture apart from a very faint paper grain. Warm shapes are round, cold shapes are sharp and angular.

Colours: overall dark and desaturated (soot brown-black, deep navy), brightness only near the two lights; the centre of the picture is the darkest and calmest area. A flat dark floor band along the bottom fifth. A soft dark vignette at the edges.

No characters, no creatures, no text, no letters, no numbers, no interface, no frame, no signature.
```

### `sfondo_armeria_A`

```
Image 1 is a rough code-made sketch of a background for the armory screen of a mobile game about little devils in Dante's hell. Image 2 shows a sister background of the same game in use, with the character and the comic-style buttons on top: it is there only to show how quiet the background must be under the interface. Do NOT draw the character, the buttons, the line or any text.

Paint a finished, premium version of the background in image 1, wide 16:9, keeping its composition, its two light sources and its dark tonal range. The place: the blacksmith's workbench wall in an underground forge. On the far left, partly off-screen, the round arched mouth of a furnace glowing soft orange-yellow, the only warm light. Above it a long rack with five blacksmith tools hanging (hammers and tongs) as small soft silhouettes. Right of the centre, on the floor, a round quenching barrel with pale cold steam rising from it. On the right, cold pale-blue light comes from the top-right corner, with icicles hanging from above, a few ice spires in the far right and one big translucent ice crystal growing in from the top-right corner.

Style: stylized 2D game background made of three depth planes with atmospheric perspective. Far plane: the lightest, soft-edged, tinted by the light behind it (dull orange on the left, dull blue on the right). Middle plane: darker simple silhouettes with a thin rim of light. Near plane: almost black, out-of-focus shapes at the bottom-left corner (a round pile of coal) and at the bottom-right corner (a sharp ice shard), framing the picture. Big flat shapes with smooth soft gradients, like a modern mobile game lobby background. NO black outlines, no ink lines, no hatching. Very little detail: no bricks, no cracks, no rivets, no surface texture, no noise. Warm shapes are round, cold shapes are sharp and angular.

Colours: overall dark and desaturated (soot brown-black, deep navy), brightness only near the two lights; the centre and the whole right half under the top edge are dark and calm, because a big panel and a list of buttons sit there. A flat dark floor band along the bottom fifth. A soft dark vignette at the edges.

No characters, no creatures, no text, no letters, no numbers, no interface, no frame, no signature.
```

### `sfondo_campagna_A`

```
Image 1 is a rough code-made sketch of a background for the campaign map screen of a mobile game about little devils in Dante's hell. Image 2 shows a sister background of the same game in use, with the character and the comic-style buttons on top: it is there only to show how quiet the background must be under the interface. Do NOT draw the character, the buttons, the line or any text.

Paint a finished, premium version of the background in image 1, wide 16:9, keeping its composition, its two light sources and its dark tonal range. The place: the rim of the great pit of hell, seen from inside, looking down. The walls of the pit come in from both sides as stepped terraces that get closer to each other toward the bottom, leaving the whole centre of the picture empty and dark (a big map is drawn there by the game). The left wall is warm rock made of soft rounded terraces, lit from the bottom-left corner by a dull orange glow. The right wall is ice made of sharp angular terraces, lit from the top-right corner by cold pale-blue light, with a few icicles hanging from the top edge. Two planes of terraces on each side: the far ones lighter and hazier, the nearer ones darker.

Style: stylized 2D game background made of three depth planes with atmospheric perspective. Far plane: the lightest, soft-edged, tinted by the light behind it. Middle plane: darker simple silhouettes with a thin rim of light. Near plane: almost black, out-of-focus shapes at the bottom-left corner (round rock) and at the bottom-right corner (a sharp ice shard), framing the picture. Big flat shapes with smooth soft gradients, like a modern mobile game lobby background. NO black outlines, no ink lines, no hatching. Very little detail: no bricks, no cracks, no surface texture, no noise.

Colours: overall dark and desaturated (soot brown-black, deep navy), brightness only near the two lights; the centre column of the picture is the darkest and calmest area, fading to black toward the bottom. A soft dark vignette at the edges.

No characters, no creatures, no text, no letters, no numbers, no interface, no frame, no signature.
```

## Criteri di accettazione

- [ ] si leggono tre piani: lontano chiaro e sfumato, medio scuro, vicino quasi nero e fuori fuoco
- [ ] nessun contorno nero, nessuna texture, pochi dettagli (non deve sembrare WB-020)
- [ ] luce calda in basso a sinistra, luce fredda in alto a destra
- [ ] il centro e le zone dei pulsanti (R5) sono scure e lisce
- [ ] niente personaggi, scritte, pulsanti, cornici
- [ ] `sfondo_home_A` e `sfondo_home_B` hanno la stessa scena e si distinguono a colpo d'occhio per lo stile

## Dopo le immagini (lo fa Claude)

Le mette nella pagina delle proposte sotto i pulsanti veri, al posto dei bozzetti, e Sergio
sceglie la strada. Solo dopo la scelta si fa la scheda di tutte le schermate, con i piani
consegnati separati (lontano, medio, vicino) per farli scorrere uno sull'altro nel gioco.

---

## Decisione

Approvata da Claude il 12 nov 2026: è una prova di stile di quattro immagini, non entra nel
gioco e non decide niente al posto di Sergio. La strada (A dipinto a strati, B teatro di
carta, C solo luce fatta col codice) la sceglie Sergio.

## Consegna di Codex

## Resoconto di Claude

### 2026-11-12

Consegna di Codex sul ramo `design/WB-027` (`76518351`): quattro immagini, tutte buone e senza
difetti (tre piani leggibili, nessun contorno, luci al posto giusto, niente scritte o
personaggi). Messe nella pagina delle proposte sotto l'interfaccia vera
(https://claude.ai/artifact/8Vtj3sQas5mHQry8eD7Myo, foto in
`/mnt/project-files/sfondi_premium/codex_wb027.jpg`). Niente è entrato nel gioco.

Verdetto di Sergio: `sfondo_campagna_A` «è molto bello», è il modello da seguire. Nella home
«il centro di attenzione diventa quell'incudine»: vuole meno dettagli. Quindi `sfondo_home_A`,
`sfondo_home_B` e `sfondo_armeria_A` non si usano; si rifanno senza oggetti con WB-028.
Non verificato: i dipinti nel gioco vero e su schermi 20:9 e 4:3.

