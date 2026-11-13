# WB-019 · Le famiglie dei pezzi: Fabbro, Corvo, Fornace, Leviatano, Vuoto

- **Stato:** APPROVATA (Sergio, 11 nov: scelte 1-25 della pagina «I Pezzi della Forgia»)
- **Data:** 2026-11-10
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-019`

## Obiettivo

Il diavoletto porta quattro pezzi (ELMO, CORAZZA, STIVALI, MANTELLO) di cinque famiglie. Ogni
pezzo ha due disegni: la **forma base** (livelli 1-19) e la **forma forgiata** (dal 20). I gradi
(bronzo, argento, oro, brace) li fa il gioco tingendo le **finiture** disegnate nel colore chiave
ciano `#00FFFF`; il bagliore della brace al 30 è disegnato dal codice. Proposta e sagome
segnaposto: https://claude.ai/artifact/F5TiCLHXAqgPe7XUBi138A (pagina «I Pezzi della Forgia»).

> **11 nov sera (Sergio):** le famiglie non sono più legate ai gironi: stanno tutte nel negozio da subito (scelta 24A). La fase 1 resta sulle cinque famiglie descritte qui (Fabbro, Corvo, Fornace, Leviatano, Vuoto); le nuove arrivano una ogni due mesi.

## Due fasi, due comandi

- **Fase 1**, `esegui WB-019 fase 1`: cinque tavole di stile, una per famiglia (immagini 1-5).
  Sergio sceglie, Claude salva le scelte in `art/WB-019/scelti/<famiglia>.png` su main.
- **Fase 2**, `esegui WB-019 fase 2 <famiglia>`: due fogli sullo stampino per la famiglia
  (base e forgiata). Lo stampino ha la casella `mantello` (fra busto e ala, 12 nov): il
  mantello si disegna intero e il gioco lo piega lungo una catena simulata (13 nov); gli
  stivali vanno nelle caselle `gamba` e `gamba_dietro` (categoria `stivali`).
- Codex esegue solo la fase chiesta; se un riferimento non c'è, si ferma.

## Cosa teniamo e cosa scartiamo

| Teniamo | Perché |
|---|---|
| L'apprendista di WB-009 (R1) come corpo: stessa altezza, scheletro, faccia e colori | i pezzi si mettono **sopra** il diavoletto; la pelle resta quella del giocatore |
| Una sagoma per famiglia che si legge a 90 px (becco, grata, pinna, cappuccio, occhialoni) | in partita il diavoletto è piccolo: la famiglia si riconosce dalla forma, non dai dettagli |
| Finiture (bordi, rivetti, fibbie, punte) in ciano pieno `#00FFFF` | il gioco le tinge col colore del grado; il ciano non va usato per altro |
| Il verde acceso `#00FF00` dove il pezzo prende il colore della squadra (al massimo un'area per pezzo) | come la fiammella e la canotta |
| Due forme: la forgiata ha **la stessa sagoma** della base più un ornamento (cresta, punte, piume in più) | lo scatto 20 si vede, ma il pezzo resta lui |

| Scartiamo | Perché |
|---|---|
| Armi o oggetti in mano | le mani reggono le armi del gioco |
| Pezzi che coprono gli occhi o la bocca | le espressioni devono restare leggibili |
| Mantelli lunghi fino ai piedi | coprirebbero la coda e le gambe nella corsa; il mantello arriva al ginocchio, al massimo poco sotto |
| Mantello a pezzi o a strisce | Sergio (12-13 nov) vuole i mantelli liberi, che seguono la fisica di chi si muove: si disegna intero, il gioco lo piega tutto lungo una catena simulata (salti, rinculo, colpi) |
| Gradienti, texture, bagliori, scintille | il bagliore della brace lo fa il codice; il ricalco in SVG vuole colori piatti |
| Bronzo, argento e oro dipinti | il grado è il ciano tinto dal gioco |

## La tavolozza delle famiglie

| Famiglia | Colore principale | Ombra | Secondo colore | Sagoma da leggere |
|---|---|---|---|---|
| FABBRO (equilibrio) | cuoio `#7A4A2A` | `#5A341C` | lenti degli occhialoni `#F2C45A` | cuffia con occhialoni, grembiule, stivali con fibbia |
| CORVO (aria) | piuma nera-blu `#262A3A` | `#171A26` | viola `#8E6CC8` | becco, piume a punta, artigli, mantello a piume |
| FORNACE (territorio) | ferro `#5C616B` | `#3E424A` | fuoco `#F28A2A`, cuore `#FFD15A` | grata sulla faccia, stufa rivettata, scarponi di ghisa |
| LEVIATANO (resistenza) | squama verde mare `#2F7F7A` | `#1F5955` | ventre `#9ED9C8` | pinna in testa, squame ad archi, pinne ai piedi, membrana |
| VUOTO (inganno) | indaco `#2B2147` | `#1A1430` | buio `#0D0A18`, occhi `#E8E4FF` | cappuccio col viso al buio, fascia con un occhio, punte sottili, mantello strappato |

Contorno nero `#000000` spesso come quello di R1; finiture ciano `#00FFFF`; sfondo bianco
`#FFFFFF` in fase 1, magenta `#FF00FF` in fase 2.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-009/scelti/tre_quarti.png` | l'apprendista nello stile del gioco: corpo, altezza, tratto e colori |
| R2 | `art/WB-019/riferimenti/R2_stampino_ai.png` | lo stampino con l'apprendista in grigio e la casella del mantello: dove va ogni pezzo (3072×2048, 12 nov) |
| R3 | `art/WB-019/riferimenti/R3_manichino.png` | l'apprendista montato: come si attaccano i pezzi (12 nov) |
| R4 | `art/WB-019/riferimenti/sagome.png` | le sagome segnaposto della pagina (esportate da Claude l'11 nov) |
| R5 | `art/WB-019/scelti/<famiglia>.png` | la tavola scelta in fase 1 (c'è solo dopo) |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto.

| Fase | Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|---|
| 1 | `1_fabbro` | R1, R4 | 1536×1024 orizzontale | 2 |
| 1 | `2_corvo` | R1, R4 | 1536×1024 | 2 |
| 1 | `3_fornace` | R1, R4 | 1536×1024 | 2 |
| 1 | `4_leviatano` | R1, R4 | 1536×1024 | 2 |
| 1 | `5_vuoto` | R1, R4 | 1536×1024 | 2 |
| 2 | `<famiglia>_base` | R5, R2, R3 | 3:2, la più grande possibile (minimo 1536×1024) | 1 |
| 2 | `<famiglia>_forgiata` | R5, R2, R3, `art/WB-019/<famiglia>_base.png` | come sopra | 1 |

### Fase 1, il prompt comune (cambia solo il blocco FAMIGLIA)

```
Image 1 is the little imp apprentice of our game, drawn in the game's clean style: copy EXACTLY his body, height, skeleton, face, skin colors, horns, tail, wings and his three-quarter angle facing right. Image 2 is a rough grey placeholder sketch of the armour set: use it ONLY for which parts exist and their silhouette idea, NOT for style or colors.

Draw the SAME apprentice TWICE side by side on one landscape picture, both full body, in a clean THREE-QUARTER VIEW FACING RIGHT, standing in a neutral relaxed pose, both feet pointing right, arms hanging loosely a little away from the body, nothing in his hands. On the LEFT he wears the four armour pieces of the set in their BASIC form; on the RIGHT he wears the same four pieces in their FORGED form: exactly the same silhouettes plus one extra ornament on each piece (described below), so it is clearly the same set, more precious.

The four pieces are worn OVER his body and never hide his eyes or mouth: a HELMET on the head (the horns stay visible, they pass through or over it), a CHEST ARMOUR on the torso, a pair of BOOTS on the lower legs and feet, a short CAPE hanging from the shoulders down to the knees, behind the body and in front of the wings (the wings stay visible above the cape).

[FAMIGLIA]

Rendering rules, very strict, because this drawing will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color plus at most one hard-edged shadow shape in the darker tone listed. No gradients, textures, hatching, noise, soft shading, glow or sparkles.
- Thick, clean, closed pure-black #000000 outline of even weight around each figure and each piece, thinner black lines only for inner details.
- TRIMS: every edge band, rivet, buckle, clasp and tip of the armour is painted in pure flat cyan #00FFFF (the game recolors it bronze, silver or gold). Use cyan for nothing else.
- Keep the apprentice's own skin and face colors exactly as in image 1.
- Flat pure white #FFFFFF background, no ground, no ground shadow, nothing else.
- No text, numbers, labels, arrows or signatures. Landscape 3:2.
```

**Blocchi FAMIGLIA** (si incolla al posto di `[FAMIGLIA]`):

- **FABBRO** · `The BLACKSMITH set, sturdy workshop gear. Main color leather #7A4A2A, shadow #5A341C, goggle lenses #F2C45A. HELMET: a rounded leather cap with big round goggles pushed up on the forehead. CHEST: a leather apron with two crossed straps. BOOTS: short leather boots with a big buckle. CAPE: a short leather cape with a square hem. Forged ornament: a small brass hammer badge on the cap, rivets along the apron, a second buckle on each boot, a riveted hem on the cape.`
- **CORVO** · `The RAVEN set, light and airborne. Main color blue-black feathers #262A3A, shadow #171A26, accent violet #8E6CC8. HELMET: a raven skull-mask on the top of the head with a long pointed beak pointing forward over the forehead (not over the face). CHEST: overlapping pointed feathers like scales. BOOTS: slim boots ending in three claw toes. CAPE: a cape made of long pointed feathers with a jagged hem. Forged ornament: a crest of three long feathers on the helmet, violet feather tips on chest and cape, a spur on each boot.`
- **FORNACE** · `The FURNACE set, heavy cast iron. Main color iron #5C616B, shadow #3E424A, fire #F28A2A with core #FFD15A. HELMET: a round iron helmet with a small barred grate on the forehead showing flat orange fire (the face stays uncovered). CHEST: a riveted stove-like breastplate with a barred grate showing fire. BOOTS: heavy square cast-iron boots. CAPE: a short heavy cape of iron plates hanging like chains. Forged ornament: a short chimney on the helmet, a bigger grate on the chest, iron toe caps, glowing orange edge on the cape hem (flat color, no glow).`
- **LEVIATANO** · `The LEVIATHAN set, sea monster scales. Main color sea green scales #2F7F7A, shadow #1F5955, belly #9ED9C8. HELMET: a scaled cap with a tall fin crest running from front to back between the horns. CHEST: armour of round overlapping scales with a pale belly plate. BOOTS: scaled boots with a small fin on the heel. CAPE: a wavy membrane cape like a fish fin, with thin ribs. Forged ornament: a taller jagged fin crest, a spine row on the chest, bigger heel fins, longer ribs with spiky tips on the cape.`
- **VUOTO** · `The VOID set, sneaky and dark. Main color indigo #2B2147, shadow #1A1430, deep dark #0D0A18, eye light #E8E4FF. HELMET: a hood over the head with the horns poking out, the face in shadow but the eyes and mouth still clearly visible. CHEST: a dark wrap with a round clasp shaped like a single open eye. BOOTS: thin pointed boots. CAPE: a ragged torn cape with uneven strips. Forged ornament: a second smaller eye on the hood, pointed shoulder tips, a ring on each boot, more and longer strips on the cape.`

### Fase 2, `<famiglia>_base` e `<famiglia>_forgiata`

```
Image 1 is the chosen armour set of our game worn by the apprentice (left figure: basic form, right figure: forged form). Image 2 is our "stampino": a sheet of boxes on a magenta background, each box holds one grey body part with a red cross for its pivot. Image 3 shows how the parts attach.

Redraw ONLY the armour pieces of the [BASIC|FORGED] form of image 1, separated, each in its own box of image 2, at the same size and position as the grey part in that box, so it fits exactly over it: the HELMET in the box "testa" (over the head, no face, no neck), the CHEST ARMOUR in the box "busto", the BOOT in the boxes "gamba" and "gamba_dietro" (only the lower leg and foot, both pointing right), the whole CAPE in the box "mantello" (seen from the side, hanging straight down behind the shoulders, its top edge on the red cross, one single piece with a ragged or shaped hem). Draw ONLY the armour, never the body, the face, the arms or the grey part.

Same rendering rules as image 1: flat colors, thick closed black outline, trims in pure cyan #00FFFF. Background: flat pure magenta #FF00FF everywhere outside the pieces. Keep the box layout of image 2 but do not draw the boxes, crosses or labels. No text. Landscape 3:2.
```

## Criteri di accettazione

- [ ] la famiglia si riconosce dalla sagoma con la figura ridotta a 90 px di altezza
- [ ] occhi e bocca liberi; corna, ali e coda visibili
- [ ] finiture tutte in ciano pieno, nessun altro ciano nel disegno
- [ ] la forma forgiata ha la stessa sagoma della base più l'ornamento
- [ ] colori piatti, contorno nero chiuso, sfondo pieno (bianco in fase 1, magenta in fase 2), nessuna scritta

---

## Decisione

Sergio, 12 nov («vai» sulle tavole consigliate da Claude): FABBRO 1, CORVO 2, FORNACE 1,
LEVIATANO 1, VUOTO 2, salvate in `art/WB-019/scelti/<famiglia>.png`. Stesso giorno: i mantelli
si muovono liberi seguendo la fisica di chi si sposta (solo grafica, come la coda): in fase 2 il
mantello si disegna intero nella casella `mantello` dello stampino (le altre non si spostano).
13 nov: le strisce sono sostituite da una catena simulata che piega tutto il disegno (shader). Comandi del ritaglio: `--categoria mantello` per il
mantello, `--categoria stivali` per gli stivali (sopra le gambe), `elmo` e `corazza` come sempre.

## Consegna di Codex

### Fase 1 · 2026-11-12

Generata da `main` aggiornato (`1abbf890`) sul ramo `design/WB-019`. Per ogni
variante ho usato il generatore integrato con il prompt comune e il blocco famiglia
integrali, allegando R1 e R4 in quest'ordine. Le tavole mostrano la forma base a
sinistra e la forgiata a destra.

File in `art/WB-019/`. Ogni nome indica un PNG originale da 1536 × 1024 e
un TXT omonimo con il prompt effettivo e i riferimenti.

| File | Tentativi | Tentativo consegnato |
|---|---:|---:|
| `1_fabbro_1` | 3 | 2 |
| `1_fabbro_2` | 3 | 3 |
| `2_corvo_1` | 3 | 3 |
| `2_corvo_2` | 3 | 2 |
| `3_fornace_1` | 3 | 1 |
| `3_fornace_2` | 3 | 3 |
| `4_leviatano_1` | 3 | 3 |
| `4_leviatano_2` | 3 | 1 |
| `5_vuoto_1` | 3 | 3 |
| `5_vuoto_2` | 3 | 2 |

**Verifiche.** Ho controllato tutte le generazioni e confrontato le tavole
selezionate anche con ciascuna figura ridotta a 90 px di altezza. A quella
scala si distinguono occhialoni, becco, grata, pinna e cappuccio. Le tavole
selezionate hanno due figure intere, con mani libere, quattro pezzi, occhi,
bocca, corna e coda visibili. Ho controllato la presenza degli ornamenti della
forma forgiata, il contorno scuro, lo sfondo chiaro e l'assenza di scritte.

**Scostamenti.** R1 mostra corna e coda, ma nessuna ala da copiare. Solo
`3_fornace_1` rende visibile un'ala stilizzata dietro ciascuna figura.
In varie tavole il piede più vicino punta verso l'osservatore. Alcuni mantelli
scendono oltre il ginocchio, soprattutto nel Corvo e nel Vuoto forgiato.
In `4_leviatano_2` si vedono le dita in punta agli stivali. Le forme base e
forgiata sono riconoscibili come lo stesso set, con variazioni nelle sagome
oltre agli ornamenti, soprattutto su mantelli e copricapi.

Il generatore ha prodotto lievi variazioni di tono. Nella fascia superiore
delle dieci tavole il colore più frequente è RGB (254, 254, 254), a fronte del
bianco `#FFFFFF` richiesto. Le finiture appaiono ciano, con valori RGB
variabili. In `1_fabbro_2` non c'è alcun pixel esattamente `#00FFFF`.
Il martello del Fabbro è ciano nelle tavole scelte. Il blocco famiglia lo
chiede in ottone, mentre la scheda prescrive il ciano per le finiture.
Il Corvo mantiene punte viola sulle piume forgiate, come chiede il blocco
famiglia.

Le tavole sono proposte di stile per la scelta di Sergio. La corrispondenza
esatta delle tavolozze e la chiusura di ogni contorno restano da verificare.
Ricalco, adattamento allo stampino e resa in gioco restano da verificare.

### Fase 2 · Vuoto · 2026-11-13

Generati con ImageGen `art/WB-019/vuoto_base.png` e `art/WB-019/vuoto_forgiata.png`, entrambi 1536 × 1024. I TXT omonimi contengono il prompt comune con BASIC o FORGED e i riferimenti in ordine. Per il forgiato ho allegato anche il PNG base consegnato. Tre tentativi per foglio. Ho scelto il primo di ciascuno per la coerenza delle sagome e perché il mantello forgiato è il più corto dei tre tentativi.

Verificati a vista i cinque pezzi separati, i due stivali rivolti a destra, il mantello intero e gli ornamenti del forgiato. Lo stampino è rispettato solo in parte. Busto e soprattutto mantello sono spostati. I cappucci includono le corna e il vano del viso è scuro pieno. Le finiture sono ciano a vista e il fondo è magenta. Restano da verificare i valori esatti dei colori, l'allineamento ai perni, la visibilità di occhi e bocca e la lunghezza del mantello dopo il montaggio. Il riferimento R2 mostra le sagome grigie su magenta, senza i riquadri e le croci rosse descritti nel prompt.

## Resoconto di Claude

### Fase 1 · 12 nov

Guardate tutte e dieci le tavole: pulite, famiglie riconoscibili, la forgiata è lo stesso pezzo con
l'ornamento. Scelte: `1_fabbro_1` (martello sulla cuffia leggibile; la 2 quasi uguale),
`2_corvo_2` (cresta viola più leggibile da piccolo), `3_fornace_1` (l'unica con l'ala visibile),
`4_leviatano_1` (nella 2 le dita escono dalla punta degli stivali), `5_vuoto_2` (occhio sul
cappuccio forgiato più chiaro). Da correggere in fase 2: il martello del Fabbro va in ottone, non
ciano; i mantelli di Corvo e Vuoto forgiati sotto il ginocchio si accorciano un poco; le finiture
si portano al ciano esatto `#00FFFF` al ritaglio. Prima della fase 2: casella `mantello` nello
stampino e categoria `stivali` (Claude, fatto il 12 nov).

### Fase 2 · Vuoto · 13 nov

Preso dal ramo `design/WB-019` (651323e). Per ora nel gioco va solo il mantello, base e forgiato:
`mantello_vuoto` e `mantello_vuoto_forgiato`, piegati dalla catena simulata (#298). Codex l'ha
disegnato fuori dalla casella, quindi l'ho ritagliato a mano dal foglio (fondo magenta tolto) e
rimesso nella casella `mantello` con l'attacco sulla croce
(`art/WB-019/vuoto_*_mantello_stampino.png`, poi `taglia.py --categoria mantello`). Sull'apprendista restava quasi
nascosto dietro il corpo, così `taglia.py` ora fa i mantelli 1,35 volte la casella: ora arriva poco sopra il ginocchio.
Scenario `mantello.txt`. Il 13 nov questo mantello stretto è stato sostituito dal mantello ampio di WB-032; i due fogli rimessi nella casella sono stati tolti, i disegni di Codex restano.

Restano fuori cappuccio, corazza e stivali. Il cappuccio copre tutto il viso (vano nero pieno) e ha
le corna dentro. Va deciso col passo 2 della roadmap dei pezzi (corna su un livello sopra l'elmo,
viso visibile) prima di ritagliarlo.
