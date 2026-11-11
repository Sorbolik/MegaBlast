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
  (base e forgiata). Parte solo quando lo stampino ha le caselle `stivali` e `mantello`
  (lavoro di Claude su `tools/stampino/`, prima della fase 2).
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
| Mantelli lunghi fino ai piedi | coprirebbero la coda e le gambe nella corsa; il mantello arriva al ginocchio |
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
| R2 | `art/WB-009/riferimenti/R2_stampino_ai.png` | lo stampino: dove va ogni pezzo (3072×2048) |
| R3 | `art/WB-009/riferimenti/R3_manichino.png` | come si attaccano i pezzi |
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

Redraw ONLY the armour pieces of the [BASIC|FORGED] form of image 1, separated, each in its own box of image 2, at the same size and position as the grey part in that box, so it fits exactly over it: the HELMET in the box "testa" (over the head, no face, no neck), the CHEST ARMOUR in the box "busto", the BOOT in the boxes "gamba" and "gamba_dietro" (only the lower leg and foot, both pointing right), the CAPE in the box "mantello" (hanging straight, its top edge on the pivot cross). Draw ONLY the armour, never the body, the face, the arms or the grey part.

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

## Consegna di Codex

## Resoconto di Claude
