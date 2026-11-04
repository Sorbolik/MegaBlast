# WB-015 · Le illustrazioni delle missioni della campagna

- **Stato:** IMPLEMENTATA (fase 1, senza c7)
- **Data:** 2026-11-04
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-015`

## Obiettivo

Sergio (4 nov): «le illustrazioni per la campagna». Nella CAMPAGNA ogni missione è una carta
col titolo, le stelle e cosa serve per prenderle, ma senza disegno: le carte si somigliano tutte.
Qui si fa **un'illustrazione per missione**, quattordici in tutto: le sette lezioni del cortile
e le sette missioni della Forgia (piano dei livelli,
https://claude.ai/artifact/12CRugbQCR2oB32LHt6aS2). Ognuna dice a colpo d'occhio cosa si fa
in quella missione, con i personaggi della storia nello stile delle tavole di WB-012.

Le illustrazioni vanno nelle carte della campagna (in alto, come una finestrella) e in grande
quando si apre la missione. Il montaggio lo fa Claude in una PR del client, con le foto a
Sergio prima del merge.

## Due fasi, due comandi

- **Fase 1**, `esegui WB-015 fase 1`: le sette del cortile (`c1` … `c7`).
- **Fase 2**, `esegui WB-015 fase 2`: le sette della Forgia (`f1` … `f7`). Si dà dopo che
  Claude ha guardato la fase 1 e, se serve, corretto i prompt qui.
- **Fase 1b**, `esegui WB-015 fase 1b`: solo `c7_duello` di nuovo, col prompt «c7_duello (fase 1b)»
  qui sotto (nella fase 1 Favilla aveva due code). Sovrascrive `art/WB-015/c7_duello.png`.
- Codex esegue solo le righe della fase chiesta; se un riferimento della fase non c'è, si ferma.

## Cosa teniamo e cosa scartiamo

| Teniamo | Perché |
|---|---|
| Lo stile delle tavole della storia (R4, l'arrivo nel cortile): fumetto, contorno nero spesso, colori pieni, un po' di tratteggio nelle ombre | le illustrazioni stanno accanto alle tavole: devono sembrare dello stesso libro |
| I personaggi copiati dai fogli scelti di WB-012 (R1 apprendista, R2 Favilla, R3 Fabbro) e la coda di Favilla della sua figura intera (R5) | sono i personaggi della storia; per la coda si dice una volta sola, «come nell'immagine» (lezione di WB-012 fase 2b) |
| Una scena sola per illustrazione, l'azione al centro, sfondo della Forgia (pietra, incudini, catene, lava, scintille) | sulla carta si vede piccola: deve leggersi anche a 300 px di larghezza |
| Formato 3:2, 1536×1024 | si ritaglia per la carta e si vede intera in grande; i bordi possono tagliarsi: niente di importante vicino ai bordi |

| Scartiamo | Perché |
|---|---|
| Scritte, numeri, titoli, fumetti | il titolo lo scrive il gioco, in tutte le lingue |
| Armi copiate dal gioco al pixel | qui conta la scena: armi riconoscibili per forma (il Lanciarune è un tubo-lanciarazzi con le rune, la Lama una spada corta) bastano |
| Il colore della squadra | nelle illustrazioni ognuno ha i suoi colori |

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-012/scelti/apprendista.png` | il foglio dell'apprendista scelto (con la fiammella, come nelle tavole) |
| R2 | `art/WB-012/scelti/favilla.png` | il foglio di Favilla scelto |
| R3 | `art/WB-012/scelti/fabbro.png` | il foglio del Fabbro scelto |
| R4 | `art/WB-012/4_arrivo_a.png` | una tavola della storia: lo stile da copiare |
| R5 | `art/WB-012/riferimenti/R9_favilla_figura.png` | Favilla a figura intera: la coda |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto: il
primo è "image 1", il secondo "image 2" e così via. Misura 1536×1024 per tutte, una variante
per immagine, sfondo della scena (non trasparente).

| Fase | Nome file | Riferimenti | Missione |
|---|---|---|---|
| 1 | `c1_stammi_dietro` | R1, R2, R5, R4 | 1 · Stammi dietro |
| 1 | `c2_lanciarune` | R1, R2, R5, R4 | 2 · Il mio vecchio Lanciarune |
| 1 | `c3_a_turno` | R1, R2, R5, R4 | 3 · A turno |
| 1 | `c4_tempo` | R1, R2, R5, R4 | 4 · Il tempo risparmiato |
| 1 | `c5_in_cima` | R1, R2, R5, R4 | 5 · Arriva in cima prima di me |
| 1 | `c6_burrone` | R1, R2, R5, R4 | 6 · Il burrone |
| 1 | `c7_duello` | R1, R2, R5, R4 | 7 · Duello con Favilla |
| 2 | `f1_in_due` | R1, R2, R5, R4 | 1 · In due (Primo sangue) |
| 2 | `f2_fuori_portata` | R1, R2, R5, R4 | 2 · Fuori portata |
| 2 | `f3_due_mani` | R1, R4 | 3 · Due mani |
| 2 | `f4_giu_dal_bordo` | R1, R4 | 4 · Giù dal bordo |
| 2 | `f5_codardo` | R1, R4 | 5 · Il codardo |
| 2 | `f6_fabbro` | R3, R1, R4 | 6 · Il Fabbro |
| 2 | `f7_battaglia` | R1, R2, R5, R3, R4 | 7 · Battaglia della Forgia |

Il pezzo comune, uguale in ogni prompt, è già dentro ciascuno.

### `c1_stammi_dietro`

```
Image 1 is the model sheet of the apprentice imp, image 2 the model sheet of Favilla, image 3 Favilla's full figure (look at her tail there), image 4 the illustration style. Copy both characters EXACTLY from their sheets (shapes, colors, flame, clothes; Favilla's tail exactly as in image 3); do not redesign them.

A wide comic illustration: the stone courtyard of a hellish forge, anvils and chains, glowing lava cracks, sparks in the air, a big iron gate far away on the right. Favilla runs ahead to the right, looking back over her shoulder with a cheeky grin and waving him on; the apprentice runs after her, a little out of breath. Between them a high stone step that she has just jumped. Keep the action in the middle; nothing important near the edges. Style of image 4. No text, letters, numbers, speech balloons or signatures.
```

### `c2_lanciarune`

```
Image 1 is the model sheet of the apprentice imp, image 2 the model sheet of Favilla, image 3 Favilla's full figure (look at her tail there), image 4 the illustration style. Copy both characters EXACTLY from their sheets (shapes, colors, flame, clothes; Favilla's tail exactly as in image 3); do not redesign them.

A wide comic illustration in the training yard of a hellish forge. Favilla stands on a wooden balcony on the right and has just thrown down a wooden crate; the apprentice below has opened it and lifts out an old rune launcher (a short bronze tube carved with glowing runes), amazed. In the background two training dummies made of straw and iron bands on wooden poles. Keep the action in the middle; nothing important near the edges. Style of image 4. No text, letters, numbers, speech balloons or signatures.
```

### `c3_a_turno`

```
Image 1 is the model sheet of the apprentice imp, image 2 the model sheet of Favilla, image 3 Favilla's full figure (look at her tail there), image 4 the illustration style. Copy both characters EXACTLY from their sheets (shapes, colors, flame, clothes; Favilla's tail exactly as in image 3); do not redesign them.

A wide comic illustration in the training yard of a hellish forge. Two training dummies of straw and iron bands stand side by side. On the left Favilla shows how it is done: she has just fired a rune launcher at one dummy (a small blast of sparks and straw) and is already swinging a short sword at it, a double attack. The apprentice watches beside her, holding his own rune launcher and taking mental notes, ready for his turn. Keep the action in the middle; nothing important near the edges. Style of image 4. No text, letters, numbers, speech balloons or signatures.
```

### `c4_tempo`

```
Image 1 is the model sheet of the apprentice imp, image 2 the model sheet of Favilla, image 3 Favilla's full figure (look at her tail there), image 4 the illustration style. Copy both characters EXACTLY from their sheets (shapes, colors, flame, clothes; Favilla's tail exactly as in image 3); do not redesign them.

A wide comic illustration: a forge courtyard with a small rock island floating in the air on the right, a straw training dummy standing on it. The apprentice throws a glowing violet orb towards the island in a high arc. Favilla is already on the island, appearing in a swirl of violet light where her own orb landed, and waves at him. Keep the action in the middle; nothing important near the edges. Style of image 4. No text, letters, numbers, speech balloons or signatures.
```

### `c5_in_cima`

```
Image 1 is the model sheet of the apprentice imp, image 2 the model sheet of Favilla, image 3 Favilla's full figure (look at her tail there), image 4 the illustration style. Copy both characters EXACTLY from their sheets (shapes, colors, flame, clothes; Favilla's tail exactly as in image 3); do not redesign them.

A wide comic illustration inside the great chimney of a hellish forge: three tall stone pillars rising one higher than the other, smoke and sparks going up. A race to the top: Favilla, a little ahead, is blasted upwards by a burst of thunder under her feet, laughing; the apprentice, a pillar lower, leaps after her with determination. Keep the action in the middle; nothing important near the edges. Style of image 4. No text, letters, numbers, speech balloons or signatures.
```

### `c6_burrone`

```
Image 1 is the model sheet of the apprentice imp, image 2 the model sheet of Favilla, image 3 Favilla's full figure (look at her tail there), image 4 the illustration style. Copy both characters EXACTLY from their sheets (shapes, colors, flame, clothes; Favilla's tail exactly as in image 3); do not redesign them.

A wide comic illustration: a deep chasm at the edge of the forge courtyard, glowing lava far below. Favilla glides down into it under a small round patched parachute, relaxed, one hand waving. The apprentice, on the edge, throws a grappling hook with a chain towards a ledge on the far side, a little nervous. Keep the action in the middle; nothing important near the edges. Style of image 4. No text, letters, numbers, speech balloons or signatures.
```

### `c7_duello`

```
Image 1 is the model sheet of the apprentice imp, image 2 the model sheet of Favilla, image 3 Favilla's full figure (look at her tail there), image 4 the illustration style. Copy both characters EXACTLY from their sheets (shapes, colors, flame, clothes; Favilla's tail exactly as in image 3); do not redesign them.

A wide comic illustration on the iron floor of a hellish forge hall, pillars and glowing furnaces behind. A friendly duel: the apprentice on the left and Favilla on the right face each other, a few steps apart, each holding a rune launcher, ready. Favilla grins and beckons him with two fingers; the apprentice is determined. Keep the action in the middle; nothing important near the edges. Style of image 4. No text, letters, numbers, speech balloons or signatures.
```

### `f1_in_due`

```
Image 1 is the model sheet of the apprentice imp, image 2 the model sheet of Favilla, image 3 Favilla's full figure (look at her tail there), image 4 the illustration style. Copy both characters EXACTLY from their sheets (shapes, colors, flame, clothes; Favilla's tail exactly as in image 3); do not redesign them.

A wide comic illustration on the iron floor of a hellish forge hall. The apprentice and Favilla stand back to back, a team, each with a rune launcher, against two rival imp apprentices in plain grey work clothes who are coming at them from both sides. Sparks, a little smoke. Keep the action in the middle; nothing important near the edges. Style of image 4. No text, letters, numbers, speech balloons or signatures.
```

### `f2_fuori_portata`

```
Image 1 is the model sheet of the apprentice imp, image 2 the model sheet of Favilla, image 3 Favilla's full figure (look at her tail there), image 4 the illustration style. Copy both characters EXACTLY from their sheets (shapes, colors, flame, clothes; Favilla's tail exactly as in image 3); do not redesign them.

A wide comic illustration: a rock island floating high on the right, and on it a smug sniper imp in a grey hood aiming a long rifle down. Below on the left, on the ground, the apprentice holds a glowing violet orb ready to throw towards the island, and Favilla points up at the sniper. Keep the action in the middle; nothing important near the edges. Style of image 4. No text, letters, numbers, speech balloons or signatures.
```

### `f3_due_mani`

```
Image 1 is the model sheet of the apprentice imp, image 2 the illustration style. Copy him EXACTLY from his sheet; do not redesign him.

A wide comic illustration on the iron floor of a hellish forge hall. The apprentice in a heroic pose holds a rune launcher in one hand, smoking after a shot, and a short sword raised in the other, ready for the second attack. In front of him a tough rival imp in grey work clothes is patching himself up with a bandage, annoyed. Keep the action in the middle; nothing important near the edges. Style of image 2. No text, letters, numbers, speech balloons or signatures.
```

### `f4_giu_dal_bordo`

```
Image 1 is the model sheet of the apprentice imp, image 2 the illustration style. Copy him EXACTLY from his sheet; do not redesign him.

A wide comic illustration: narrow rock spikes over a dark void with glowing lava far below. On each rock stands a training dummy of straw and iron bands. The apprentice, on a ledge, pumps a big leather blacksmith's bellows and a strong gust of air knocks one dummy off its rock, straw flying. Keep the action in the middle; nothing important near the edges. Style of image 2. No text, letters, numbers, speech balloons or signatures.
```

### `f5_codardo`

```
Image 1 is the model sheet of the apprentice imp, image 2 the illustration style. Copy him EXACTLY from his sheet; do not redesign him.

A wide comic illustration on the floor of a hellish forge, with small burrows dug into a stone wall. A cowardly little imp in grey work clothes peeks out of a burrow, sweating, ready to throw a violet orb to flee again. The apprentice, in the foreground, tiptoes towards the burrow holding his own violet orb, with a cunning grin. Keep the action in the middle; nothing important near the edges. Style of image 2. No text, letters, numbers, speech balloons or signatures.
```

### `f6_fabbro`

```
Image 1 is the model sheet of the Fabbro, the old devil blacksmith, image 2 the model sheet of the apprentice imp, image 3 the illustration style. Copy both characters EXACTLY from their sheets (the Fabbro's long ridged horns, white moustache, iron chest-furnace with five bars, chimney, gloves, apron); do not redesign them.

A wide comic illustration: a lava pit in the middle of the forge floor, its glow lighting everything from below. On the far side the huge Fabbro stands with his big hammer on his shoulder, stern, the fire roaring in his chest-furnace. On the near side the small apprentice faces him bravely, rune launcher in his hands, the lava pit between them. Keep the action in the middle; nothing important near the edges. Style of image 3. No text, letters, numbers, speech balloons or signatures.
```

### `f7_battaglia`

```
Image 1 is the model sheet of the apprentice imp, image 2 the model sheet of Favilla, image 3 Favilla's full figure (look at her tail there), image 4 the model sheet of the Fabbro, image 5 the illustration style. Copy all three characters EXACTLY from their sheets (Favilla's tail exactly as in image 3); do not redesign them.

A wide comic illustration, the great battle of the forge: on the left the apprentice and Favilla charge side by side; on the right the huge Fabbro with his big hammer and, beside him, a sniper imp in a grey hood with a long rifle. Explosions of sparks, chains, anvils and lava light all around. Keep the action in the middle; nothing important near the edges. Style of image 5. No text, letters, numbers, speech balloons or signatures.
```

### `c7_duello` (fase 1b)

Riferimenti R1, R2, R5, R4, come nella fase 1.

```
Image 1 is the model sheet of the apprentice imp, image 2 the model sheet of Favilla, image 3 Favilla's full figure (look at her tail there), image 4 the illustration style. Copy both characters EXACTLY from their sheets (shapes, colors, flame, clothes; Favilla's tail exactly as in image 3); do not redesign them.

A wide comic illustration on the iron floor of a hellish forge hall, pillars and glowing furnaces behind. A friendly duel: the apprentice on the left and Favilla on the right face each other, a few steps apart, each holding a rune launcher, ready. Favilla grins and beckons him with two fingers; the apprentice is determined. Keep the action in the middle; nothing important near the edges. Style of image 4. No text, letters, numbers, speech balloons or signatures.

Very important: each character has exactly ONE tail. Favilla has ONE single tail, coming out from her lower back and curving behind her to the right; nothing else behind her looks like a tail. The apprentice has ONE single tail too.
```

## Criteri di accettazione

- [ ] i personaggi sono quelli dei fogli: apprendista con la fiammella, Favilla con la fiamma bianco-azzurra, salopette e stivali, la coda come in R5; il Fabbro con la fornace a cinque sbarre
- [ ] ogni illustrazione dice cosa si fa nella missione, con l'azione al centro e niente di importante sui bordi
- [ ] stile delle tavole (R4), sfondo della Forgia
- [ ] nessuna scritta, numero, fumetto o firma
- [ ] 1536×1024

## Dopo le immagini (lo fa Claude)

Guarda ogni illustrazione (coda di Favilla, mani, personaggi giusti) e scarta quelle con
difetti; per le scartate corregge il prompt qui e chiede una fase «b». Le buone: ritaglio per
la carta e versione grande in `client/assets/` (PNG compressi, sotto il limite di memoria del
telefono), carte della campagna con la finestrella, foto a Sergio prima della PR.

---

## Decisione

Approvata da Claude, 2026-11-04, su richiesta di Sergio («le illustrazioni per la
campagna»); reversibile (il gioco non cambia finché non si montano). Scelte di Claude: una per
missione (quattordici), stile delle tavole di WB-012, in due fasi per correggere i prompt dopo
le prime sette; come si vedono nella carta lo propone Claude con le foto.

## Consegna di Codex

- Fase 1: ramo `design/WB-015`, commit `b644b94` (sette PNG 1672×941 con i loro `.txt`).

## Resoconto di Claude

Fase 1 (2026-11-04): tenute `c1`–`c6`, senza difetti visibili. Scartata `c7_duello`: Favilla ha
due code (una dietro la schiena, una a destra); il prompt della fase 1b lo dice esplicitamente.
Scelta di Claude: nelle illustrazioni i fantocci sono spaventapasseri di paglia sul palo, in
gioco saranno il sacco con le gambe di WB-016 (in gioco volano via); si tengono così, il palo
nella scena va bene. Integrazione: Sergio ha scelto «carta e apertura». `python3 strumenti/grafica/illustrazioni.py` fa i JPEG in `client/paintings/missions/` (1672 × 941 e 320 × 180); finestrella sulla carta, cartolina col titolo su fondo pieno prima della vignetta che spiega (`client/ui/illustrations.lua`, `battle/vignette.lua`). Scenari `illustrazioni.txt` e `illustrazioni_tavola.txt` (anche 1600 × 720 e 960 × 720).
