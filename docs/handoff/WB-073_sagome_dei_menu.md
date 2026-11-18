# WB-073 · Sagome dei menu, una per pagina

- **Stato:** IMPLEMENTATA (era APPROVATA; Sergio, 18 nov, 11:02: «proviamo la C»; 11:03: «vorrei una diversa per ogni pagina»; le proposte su https://claude.ai/artifact/DCwXT2kmBrf535D67MBu4f)
- **Data:** 2026-11-18
- **Ramo della scheda:** `claude/project-thread-flvu6y` (Codex la esegue da lì, non serve che sia su `main`) · **Ramo delle immagini:** `design/WB-073`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-073` senza chiedere conferma (il repository è privato).

## Obiettivo

I dipinti di WB-053 dietro i menu sono troppo ricchi: tolgono visibilità e importanza ai pulsanti
(Sergio, 18 nov). Sergio sceglie la direzione C · Sagome: dietro ogni pagina solo due grandi masse
scure ai lati, contorno d'inchiostro e un filo di luce sul bordo, il centro vuoto. Ogni pagina ha le
sue sagome, che fanno riconoscere il luogo solo dal contorno. Il fondo scuro, le due luci che
respirano, le braci e il colore di ogni pagina li fa il codice: a Codex servono solo le sagome, su
fondo trasparente. Scartata per sempre la B (dipinto sfocato): già provata, fuori stile, poco carattere.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-073/riferimenti/R1_bozza_sagome.jpg` | la bozza di Claude della direzione approvata (sopra EVENTI senza interfaccia, sotto la home): la disposizione, **non** le forme sfocate |
| R2 | `art/WB-073/riferimenti/R2_stile_campagna.jpg` | lo sfondo della campagna (WB-053): solo la mano e l'inchiostro |
| R3 | `art/WB-073/riferimenti/R3_armeria_in_uso.jpg` | l'ARMERIA di oggi: quanto copre l'interfaccia. **L'interfaccia non va ridisegnata** |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega R1, R2 e R3 in quest'ordine. 1672×941 (16:9),
PNG trasparente, una variante.

| Nome file | Riferimenti | Pagina |
|---|---|---|
| `sagome_home` | R1, R2, R3 | HOME |
| `sagome_zaino` | R1, R2, R3 | ZAINO |
| `sagome_armeria` | R1, R2, R3 | ARMERIA |
| `sagome_profilo` | R1, R2, R3 | PROFILO |
| `sagome_eventi` | R1, R2, R3 | EVENTI |
| `sagome_gioca_online` | R1, R2, R3 | GIOCA ONLINE |
| `sagome_campagna` | R1, R2, R3 | CAMPAGNA |
| `sagome_allenamento` | R1, R2, R3 | ALLENAMENTO |
| `sagome_impostazioni` | R1, R2, R3 | IMPOSTAZIONI |

### `sagome_home`

```
Image 1 is the APPROVED direction for the new menu backgrounds of a mobile game about little devils in Dante's hell: two big dark SILHOUETTE masses framing the screen from the sides, a calm empty centre (top: a screen without interface; bottom: the home screen with its interface on top). Image 1 is only a rough sketch by the art director: keep its layout, darkness and calm, NOT its blurry shapes. Image 2 is an approved background of the same game: use it ONLY for the hand, the thick near-black ink outlines and the kind of shapes of the place; do NOT copy its details, objects or colors. Image 3 shows a menu screen in use: the interface covers most of the screen and must stay the only lit, important thing (do not draw the interface).

Paint ONE wide 16:9 image (1672x941) on a fully TRANSPARENT background (if you need a key color, use flat pure #00FF00 and remove it cleanly, no green fringe): only two silhouette masses, nothing else.

Style of the masses, follow exactly: flat comic-book silhouettes, almost black (#0C0A0D) with thick near-black ink outlines (#050405), smooth confident curves, NO small details, NO textures, NO gradients, NO blur, NO soft edges, NO glow, NO objects floating in the middle. Each mass has two flat layers: in front the near-black silhouette, a little behind and inward a second flat silhouette slightly lighter (left one dark warm brown #3A2219, right one dark slate blue #1A2A3A) that gives depth. Along the inner edge of each front mass (the edge facing the centre of the screen) a thin flat rim of light, 6-10 px, hard edged: warm orange #F26419 on the left mass, icy blue #38B6FF on the right mass. The place must be recognizable ONLY from the outline of the silhouettes, like a shadow theatre.

Composition, follow exactly: the LEFT mass rises from the bottom-left corner (fire side), the RIGHT mass hangs from the top-right corner and runs down the right edge (ice side: its outline carries a few big icicles and frost crust, Lucifer's ice entering the place). Both masses touch their edges of the picture and reach inward at most 25% of the width; the middle 50% of the picture, and everything above the left mass and below the right mass, stays completely empty and transparent. The phone may crop about 10% from each side: the recognizable part of each outline sits between 8% and 25% of the width from its edge. The floor line is at 83% of the height from the top: the left mass stands on it and simply continues down to the bottom edge (that part will be covered). No characters, no creatures, no text, no letters, no numbers, no interface, no frame, no signature.

This one is for the menu screen HOME (the threshold of the Forge, the main menu). The two silhouettes, each one a different shape from every other screen of the game: LEFT: the silhouette of a big forge chimney with a stack of stone blocks and an anvil on a stump at its foot, a few rising sparks shapes frozen in the outline. RIGHT: a hanging chain hoist with a big crucible bucket, a wooden gallows beam, all crusted with ice and icicles.
```

### `sagome_zaino`

```
Image 1 is the APPROVED direction for the new menu backgrounds of a mobile game about little devils in Dante's hell: two big dark SILHOUETTE masses framing the screen from the sides, a calm empty centre (top: a screen without interface; bottom: the home screen with its interface on top). Image 1 is only a rough sketch by the art director: keep its layout, darkness and calm, NOT its blurry shapes. Image 2 is an approved background of the same game: use it ONLY for the hand, the thick near-black ink outlines and the kind of shapes of the place; do NOT copy its details, objects or colors. Image 3 shows a menu screen in use: the interface covers most of the screen and must stay the only lit, important thing (do not draw the interface).

Paint ONE wide 16:9 image (1672x941) on a fully TRANSPARENT background (if you need a key color, use flat pure #00FF00 and remove it cleanly, no green fringe): only two silhouette masses, nothing else.

Style of the masses, follow exactly: flat comic-book silhouettes, almost black (#0C0A0D) with thick near-black ink outlines (#050405), smooth confident curves, NO small details, NO textures, NO gradients, NO blur, NO soft edges, NO glow, NO objects floating in the middle. Each mass has two flat layers: in front the near-black silhouette, a little behind and inward a second flat silhouette slightly lighter (left one dark warm brown #3A2219, right one dark slate blue #1A2A3A) that gives depth. Along the inner edge of each front mass (the edge facing the centre of the screen) a thin flat rim of light, 6-10 px, hard edged: warm orange #F26419 on the left mass, icy blue #38B6FF on the right mass. The place must be recognizable ONLY from the outline of the silhouettes, like a shadow theatre.

Composition, follow exactly: the LEFT mass rises from the bottom-left corner (fire side), the RIGHT mass hangs from the top-right corner and runs down the right edge (ice side: its outline carries a few big icicles and frost crust, Lucifer's ice entering the place). Both masses touch their edges of the picture and reach inward at most 25% of the width; the middle 50% of the picture, and everything above the left mass and below the right mass, stays completely empty and transparent. The phone may crop about 10% from each side: the recognizable part of each outline sits between 8% and 25% of the width from its edge. The floor line is at 83% of the height from the top: the left mass stands on it and simply continues down to the bottom edge (that part will be covered). No characters, no creatures, no text, no letters, no numbers, no interface, no frame, no signature.

This one is for the menu screen ZAINO (the apprentice's backpack and gear). The two silhouettes, each one a different shape from every other screen of the game: LEFT: the rock nook of the apprentice's den: a curved rock wall with a wooden shelf and two jars, iron hooks with one hanging strap, a small oil lamp on a ledge. RIGHT: a rock overhang with a few hanging straps and a rolled blanket on a peg, frozen and dripping with icicles.
```

### `sagome_armeria`

```
Image 1 is the APPROVED direction for the new menu backgrounds of a mobile game about little devils in Dante's hell: two big dark SILHOUETTE masses framing the screen from the sides, a calm empty centre (top: a screen without interface; bottom: the home screen with its interface on top). Image 1 is only a rough sketch by the art director: keep its layout, darkness and calm, NOT its blurry shapes. Image 2 is an approved background of the same game: use it ONLY for the hand, the thick near-black ink outlines and the kind of shapes of the place; do NOT copy its details, objects or colors. Image 3 shows a menu screen in use: the interface covers most of the screen and must stay the only lit, important thing (do not draw the interface).

Paint ONE wide 16:9 image (1672x941) on a fully TRANSPARENT background (if you need a key color, use flat pure #00FF00 and remove it cleanly, no green fringe): only two silhouette masses, nothing else.

Style of the masses, follow exactly: flat comic-book silhouettes, almost black (#0C0A0D) with thick near-black ink outlines (#050405), smooth confident curves, NO small details, NO textures, NO gradients, NO blur, NO soft edges, NO glow, NO objects floating in the middle. Each mass has two flat layers: in front the near-black silhouette, a little behind and inward a second flat silhouette slightly lighter (left one dark warm brown #3A2219, right one dark slate blue #1A2A3A) that gives depth. Along the inner edge of each front mass (the edge facing the centre of the screen) a thin flat rim of light, 6-10 px, hard edged: warm orange #F26419 on the left mass, icy blue #38B6FF on the right mass. The place must be recognizable ONLY from the outline of the silhouettes, like a shadow theatre.

Composition, follow exactly: the LEFT mass rises from the bottom-left corner (fire side), the RIGHT mass hangs from the top-right corner and runs down the right edge (ice side: its outline carries a few big icicles and frost crust, Lucifer's ice entering the place). Both masses touch their edges of the picture and reach inward at most 25% of the width; the middle 50% of the picture, and everything above the left mass and below the right mass, stays completely empty and transparent. The phone may crop about 10% from each side: the recognizable part of each outline sits between 8% and 25% of the width from its edge. The floor line is at 83% of the height from the top: the left mass stands on it and simply continues down to the bottom edge (that part will be covered). No characters, no creatures, no text, no letters, no numbers, no interface, no frame, no signature.

This one is for the menu screen ARMERIA (upgrading and buying gear at the Smith). The two silhouettes, each one a different shape from every other screen of the game: LEFT: the smith's workshop: a squat brick furnace with its hood, a big anvil, a rack of hammers and tongs on the wall. RIGHT: a leaning stack of metal sheets and a hanging chain with a hook, all covered with frost and big icicles.
```

### `sagome_profilo`

```
Image 1 is the APPROVED direction for the new menu backgrounds of a mobile game about little devils in Dante's hell: two big dark SILHOUETTE masses framing the screen from the sides, a calm empty centre (top: a screen without interface; bottom: the home screen with its interface on top). Image 1 is only a rough sketch by the art director: keep its layout, darkness and calm, NOT its blurry shapes. Image 2 is an approved background of the same game: use it ONLY for the hand, the thick near-black ink outlines and the kind of shapes of the place; do NOT copy its details, objects or colors. Image 3 shows a menu screen in use: the interface covers most of the screen and must stay the only lit, important thing (do not draw the interface).

Paint ONE wide 16:9 image (1672x941) on a fully TRANSPARENT background (if you need a key color, use flat pure #00FF00 and remove it cleanly, no green fringe): only two silhouette masses, nothing else.

Style of the masses, follow exactly: flat comic-book silhouettes, almost black (#0C0A0D) with thick near-black ink outlines (#050405), smooth confident curves, NO small details, NO textures, NO gradients, NO blur, NO soft edges, NO glow, NO objects floating in the middle. Each mass has two flat layers: in front the near-black silhouette, a little behind and inward a second flat silhouette slightly lighter (left one dark warm brown #3A2219, right one dark slate blue #1A2A3A) that gives depth. Along the inner edge of each front mass (the edge facing the centre of the screen) a thin flat rim of light, 6-10 px, hard edged: warm orange #F26419 on the left mass, icy blue #38B6FF on the right mass. The place must be recognizable ONLY from the outline of the silhouettes, like a shadow theatre.

Composition, follow exactly: the LEFT mass rises from the bottom-left corner (fire side), the RIGHT mass hangs from the top-right corner and runs down the right edge (ice side: its outline carries a few big icicles and frost crust, Lucifer's ice entering the place). Both masses touch their edges of the picture and reach inward at most 25% of the width; the middle 50% of the picture, and everything above the left mass and below the right mass, stays completely empty and transparent. The phone may crop about 10% from each side: the recognizable part of each outline sits between 8% and 25% of the width from its edge. The floor line is at 83% of the height from the top: the left mass stands on it and simply continues down to the bottom edge (that part will be covered). No characters, no creatures, no text, no letters, no numbers, no interface, no frame, no signature.

This one is for the menu screen PROFILO (player statistics and match history). The two silhouettes, each one a different shape from every other screen of the game: LEFT: the hall of memories: a stone column with a torn banner hanging from a pole and a little trophy cup on a stone shelf. RIGHT: a broken stone arch with a long torn banner hanging down and a cracked shield on a hook, frozen with icicles.
```

### `sagome_eventi`

```
Image 1 is the APPROVED direction for the new menu backgrounds of a mobile game about little devils in Dante's hell: two big dark SILHOUETTE masses framing the screen from the sides, a calm empty centre (top: a screen without interface; bottom: the home screen with its interface on top). Image 1 is only a rough sketch by the art director: keep its layout, darkness and calm, NOT its blurry shapes. Image 2 is an approved background of the same game: use it ONLY for the hand, the thick near-black ink outlines and the kind of shapes of the place; do NOT copy its details, objects or colors. Image 3 shows a menu screen in use: the interface covers most of the screen and must stay the only lit, important thing (do not draw the interface).

Paint ONE wide 16:9 image (1672x941) on a fully TRANSPARENT background (if you need a key color, use flat pure #00FF00 and remove it cleanly, no green fringe): only two silhouette masses, nothing else.

Style of the masses, follow exactly: flat comic-book silhouettes, almost black (#0C0A0D) with thick near-black ink outlines (#050405), smooth confident curves, NO small details, NO textures, NO gradients, NO blur, NO soft edges, NO glow, NO objects floating in the middle. Each mass has two flat layers: in front the near-black silhouette, a little behind and inward a second flat silhouette slightly lighter (left one dark warm brown #3A2219, right one dark slate blue #1A2A3A) that gives depth. Along the inner edge of each front mass (the edge facing the centre of the screen) a thin flat rim of light, 6-10 px, hard edged: warm orange #F26419 on the left mass, icy blue #38B6FF on the right mass. The place must be recognizable ONLY from the outline of the silhouettes, like a shadow theatre.

Composition, follow exactly: the LEFT mass rises from the bottom-left corner (fire side), the RIGHT mass hangs from the top-right corner and runs down the right edge (ice side: its outline carries a few big icicles and frost crust, Lucifer's ice entering the place). Both masses touch their edges of the picture and reach inward at most 25% of the width; the middle 50% of the picture, and everything above the left mass and below the right mass, stays completely empty and transparent. The phone may crop about 10% from each side: the recognizable part of each outline sits between 8% and 25% of the width from its edge. The floor line is at 83% of the height from the top: the left mass stands on it and simply continues down to the bottom edge (that part will be covered). No characters, no creatures, no text, no letters, no numbers, no interface, no frame, no signature.

This one is for the menu screen EVENTI (global ranking and events calendar). The two silhouettes, each one a different shape from every other screen of the game: LEFT: the arena stands: a tall stone pillar with a big brazier bowl on top and a long pennant on a pole, the stepped tiers of seats going down. RIGHT: stepped stone tiers seen from below with two flag poles and pennants, crusted with ice and icicles hanging from the tiers.
```

### `sagome_gioca_online`

```
Image 1 is the APPROVED direction for the new menu backgrounds of a mobile game about little devils in Dante's hell: two big dark SILHOUETTE masses framing the screen from the sides, a calm empty centre (top: a screen without interface; bottom: the home screen with its interface on top). Image 1 is only a rough sketch by the art director: keep its layout, darkness and calm, NOT its blurry shapes. Image 2 is an approved background of the same game: use it ONLY for the hand, the thick near-black ink outlines and the kind of shapes of the place; do NOT copy its details, objects or colors. Image 3 shows a menu screen in use: the interface covers most of the screen and must stay the only lit, important thing (do not draw the interface).

Paint ONE wide 16:9 image (1672x941) on a fully TRANSPARENT background (if you need a key color, use flat pure #00FF00 and remove it cleanly, no green fringe): only two silhouette masses, nothing else.

Style of the masses, follow exactly: flat comic-book silhouettes, almost black (#0C0A0D) with thick near-black ink outlines (#050405), smooth confident curves, NO small details, NO textures, NO gradients, NO blur, NO soft edges, NO glow, NO objects floating in the middle. Each mass has two flat layers: in front the near-black silhouette, a little behind and inward a second flat silhouette slightly lighter (left one dark warm brown #3A2219, right one dark slate blue #1A2A3A) that gives depth. Along the inner edge of each front mass (the edge facing the centre of the screen) a thin flat rim of light, 6-10 px, hard edged: warm orange #F26419 on the left mass, icy blue #38B6FF on the right mass. The place must be recognizable ONLY from the outline of the silhouettes, like a shadow theatre.

Composition, follow exactly: the LEFT mass rises from the bottom-left corner (fire side), the RIGHT mass hangs from the top-right corner and runs down the right edge (ice side: its outline carries a few big icicles and frost crust, Lucifer's ice entering the place). Both masses touch their edges of the picture and reach inward at most 25% of the width; the middle 50% of the picture, and everything above the left mass and below the right mass, stays completely empty and transparent. The phone may crop about 10% from each side: the recognizable part of each outline sits between 8% and 25% of the width from its edge. The floor line is at 83% of the height from the top: the left mass stands on it and simply continues down to the bottom edge (that part will be covered). No characters, no creatures, no text, no letters, no numbers, no interface, no frame, no signature.

This one is for the menu screen GIOCA ONLINE (choosing an online queue). The two silhouettes, each one a different shape from every other screen of the game: LEFT: the crossroads of gates: a tall pointed stone gate with steps in front and a hanging chain with a torch bowl. RIGHT: a second pointed gate tower seen from the side, a chain hanging from it, all frozen with big icicles.
```

### `sagome_campagna`

```
Image 1 is the APPROVED direction for the new menu backgrounds of a mobile game about little devils in Dante's hell: two big dark SILHOUETTE masses framing the screen from the sides, a calm empty centre (top: a screen without interface; bottom: the home screen with its interface on top). Image 1 is only a rough sketch by the art director: keep its layout, darkness and calm, NOT its blurry shapes. Image 2 is an approved background of the same game: use it ONLY for the hand, the thick near-black ink outlines and the kind of shapes of the place; do NOT copy its details, objects or colors. Image 3 shows a menu screen in use: the interface covers most of the screen and must stay the only lit, important thing (do not draw the interface).

Paint ONE wide 16:9 image (1672x941) on a fully TRANSPARENT background (if you need a key color, use flat pure #00FF00 and remove it cleanly, no green fringe): only two silhouette masses, nothing else.

Style of the masses, follow exactly: flat comic-book silhouettes, almost black (#0C0A0D) with thick near-black ink outlines (#050405), smooth confident curves, NO small details, NO textures, NO gradients, NO blur, NO soft edges, NO glow, NO objects floating in the middle. Each mass has two flat layers: in front the near-black silhouette, a little behind and inward a second flat silhouette slightly lighter (left one dark warm brown #3A2219, right one dark slate blue #1A2A3A) that gives depth. Along the inner edge of each front mass (the edge facing the centre of the screen) a thin flat rim of light, 6-10 px, hard edged: warm orange #F26419 on the left mass, icy blue #38B6FF on the right mass. The place must be recognizable ONLY from the outline of the silhouettes, like a shadow theatre.

Composition, follow exactly: the LEFT mass rises from the bottom-left corner (fire side), the RIGHT mass hangs from the top-right corner and runs down the right edge (ice side: its outline carries a few big icicles and frost crust, Lucifer's ice entering the place). Both masses touch their edges of the picture and reach inward at most 25% of the width; the middle 50% of the picture, and everything above the left mass and below the right mass, stays completely empty and transparent. The phone may crop about 10% from each side: the recognizable part of each outline sits between 8% and 25% of the width from its edge. The floor line is at 83% of the height from the top: the left mass stands on it and simply continues down to the bottom edge (that part will be covered). No characters, no creatures, no text, no letters, no numbers, no interface, no frame, no signature.

This one is for the menu screen CAMPAGNA (choosing the next campaign mission). The two silhouettes, each one a different shape from every other screen of the game: LEFT: the edge of the abyss: a rocky ledge with a stairway carved in the rock going down and a chain railing on short posts. RIGHT: a crooked wooden signpost on a rock spur hanging over the pit, crusted with ice and icicles.
```

### `sagome_allenamento`

```
Image 1 is the APPROVED direction for the new menu backgrounds of a mobile game about little devils in Dante's hell: two big dark SILHOUETTE masses framing the screen from the sides, a calm empty centre (top: a screen without interface; bottom: the home screen with its interface on top). Image 1 is only a rough sketch by the art director: keep its layout, darkness and calm, NOT its blurry shapes. Image 2 is an approved background of the same game: use it ONLY for the hand, the thick near-black ink outlines and the kind of shapes of the place; do NOT copy its details, objects or colors. Image 3 shows a menu screen in use: the interface covers most of the screen and must stay the only lit, important thing (do not draw the interface).

Paint ONE wide 16:9 image (1672x941) on a fully TRANSPARENT background (if you need a key color, use flat pure #00FF00 and remove it cleanly, no green fringe): only two silhouette masses, nothing else.

Style of the masses, follow exactly: flat comic-book silhouettes, almost black (#0C0A0D) with thick near-black ink outlines (#050405), smooth confident curves, NO small details, NO textures, NO gradients, NO blur, NO soft edges, NO glow, NO objects floating in the middle. Each mass has two flat layers: in front the near-black silhouette, a little behind and inward a second flat silhouette slightly lighter (left one dark warm brown #3A2219, right one dark slate blue #1A2A3A) that gives depth. Along the inner edge of each front mass (the edge facing the centre of the screen) a thin flat rim of light, 6-10 px, hard edged: warm orange #F26419 on the left mass, icy blue #38B6FF on the right mass. The place must be recognizable ONLY from the outline of the silhouettes, like a shadow theatre.

Composition, follow exactly: the LEFT mass rises from the bottom-left corner (fire side), the RIGHT mass hangs from the top-right corner and runs down the right edge (ice side: its outline carries a few big icicles and frost crust, Lucifer's ice entering the place). Both masses touch their edges of the picture and reach inward at most 25% of the width; the middle 50% of the picture, and everything above the left mass and below the right mass, stays completely empty and transparent. The phone may crop about 10% from each side: the recognizable part of each outline sits between 8% and 25% of the width from its edge. The floor line is at 83% of the height from the top: the left mass stands on it and simply continues down to the bottom edge (that part will be covered). No characters, no creatures, no text, no letters, no numbers, no interface, no frame, no signature.

This one is for the menu screen ALLENAMENTO (training matches against bots). The two silhouettes, each one a different shape from every other screen of the game: LEFT: the training yard: a wooden post with a hanging lantern, a barrel with practice spears and swords sticking out, a sandbag. RIGHT: a straw dummy on a pole and a round target on a post in front of a palisade of pointed stakes, frozen with icicles.
```

### `sagome_impostazioni`

```
Image 1 is the APPROVED direction for the new menu backgrounds of a mobile game about little devils in Dante's hell: two big dark SILHOUETTE masses framing the screen from the sides, a calm empty centre (top: a screen without interface; bottom: the home screen with its interface on top). Image 1 is only a rough sketch by the art director: keep its layout, darkness and calm, NOT its blurry shapes. Image 2 is an approved background of the same game: use it ONLY for the hand, the thick near-black ink outlines and the kind of shapes of the place; do NOT copy its details, objects or colors. Image 3 shows a menu screen in use: the interface covers most of the screen and must stay the only lit, important thing (do not draw the interface).

Paint ONE wide 16:9 image (1672x941) on a fully TRANSPARENT background (if you need a key color, use flat pure #00FF00 and remove it cleanly, no green fringe): only two silhouette masses, nothing else.

Style of the masses, follow exactly: flat comic-book silhouettes, almost black (#0C0A0D) with thick near-black ink outlines (#050405), smooth confident curves, NO small details, NO textures, NO gradients, NO blur, NO soft edges, NO glow, NO objects floating in the middle. Each mass has two flat layers: in front the near-black silhouette, a little behind and inward a second flat silhouette slightly lighter (left one dark warm brown #3A2219, right one dark slate blue #1A2A3A) that gives depth. Along the inner edge of each front mass (the edge facing the centre of the screen) a thin flat rim of light, 6-10 px, hard edged: warm orange #F26419 on the left mass, icy blue #38B6FF on the right mass. The place must be recognizable ONLY from the outline of the silhouettes, like a shadow theatre.

Composition, follow exactly: the LEFT mass rises from the bottom-left corner (fire side), the RIGHT mass hangs from the top-right corner and runs down the right edge (ice side: its outline carries a few big icicles and frost crust, Lucifer's ice entering the place). Both masses touch their edges of the picture and reach inward at most 25% of the width; the middle 50% of the picture, and everything above the left mass and below the right mass, stays completely empty and transparent. The phone may crop about 10% from each side: the recognizable part of each outline sits between 8% and 25% of the width from its edge. The floor line is at 83% of the height from the top: the left mass stands on it and simply continues down to the bottom edge (that part will be covered). No characters, no creatures, no text, no letters, no numbers, no interface, no frame, no signature.

This one is for the menu screen IMPOSTAZIONI (game settings). The two silhouettes, each one a different shape from every other screen of the game: LEFT: the tool bench: a sturdy workbench with a vise, a lantern on a wall bracket, a few wrenches hanging. RIGHT: big cogwheels and a pipe with a valve wheel coming down from the top right, a lever box, all crusted with frost and icicles.
```

## Criteri di accettazione

- [ ] fondo trasparente pulito, senza alone verde
- [ ] solo due masse: a sinistra dal basso (fuoco), a destra dall'alto (ghiaccio con ghiaccioli)
- [ ] sagome piatte quasi nere, contorno d'inchiostro, seconda sagoma più chiara dietro, filo di luce arancio a sinistra e azzurro a destra sul bordo interno
- [ ] niente sfumature, sfocature, bagliori, texture o dettagli piccoli; nessun taglio netto a metà forma
- [ ] ogni massa entra al massimo del 25% della larghezza, il centro è vuoto
- [ ] le nove pagine hanno sagome diverse e il luogo si riconosce dal contorno
- [ ] niente personaggi, scritte, interfaccia, cornici o firme

## Dopo le immagini (lo fa Claude)

- Guarda ogni sagoma sotto la sua pagina vera nel simulatore (16:9, 20:9 e 4:3) e scarta quelle che coprono o disturbano i pulsanti.
- Nel gioco: fondo scuro col colore della pagina, le due luci che respirano (7 s), poche braci e scaglie di gelo, le sagome sopra; i dipinti `menu_*.jpg` se ne vanno. Prima, foto affiancate a Sergio.

## Decisione

Reversibile (solo immagini in un ramo): approvata su richiesta di Sergio (18 nov).

## Consegna di Codex

ImageGen integrato con i nove prompt integrali, riferimenti R1–R3 in ordine e trasparenza diretta. I nove PNG originali misurano 1672×941 px.

| File | Tentativi | Tentativo scelto | Ingresso delle masse sopra la quota del pavimento, sinistra / destra | Fascia inferiore sulla mezzeria |
|---|---:|---:|---:|---:|
| `art/WB-073/sagome_home.png` e `sagome_home.txt` | 3 | 3 | 27% / 24% | 48 px |
| `art/WB-073/sagome_zaino.png` e `sagome_zaino.txt` | 3 | 2 | 27% / 34% | 65 px |
| `art/WB-073/sagome_armeria.png` e `sagome_armeria.txt` | 3 | 1 | 32% / 24% | 57 px |
| `art/WB-073/sagome_profilo.png` e `sagome_profilo.txt` | 3 | 1 | 24% / 27% | 0 px |
| `art/WB-073/sagome_eventi.png` e `sagome_eventi.txt` | 3 | 2 | 33% / 28% | 63 px |
| `art/WB-073/sagome_gioca_online.png` e `sagome_gioca_online.txt` | 3 | 3 | 25% / 26% | 96 px |
| `art/WB-073/sagome_campagna.png` e `sagome_campagna.txt` | 3 | 3 | 32% / 23% | 12 px |
| `art/WB-073/sagome_allenamento.png` e `sagome_allenamento.txt` | 3 | 3 | 28% / 29% | 96 px |
| `art/WB-073/sagome_impostazioni.png` e `sagome_impostazioni.txt` | 3 | 1 | 28% / 27% | 26 px |

Verificati il canale alpha, i soggetti delle nove pagine, i bordi arancio e azzurri e l'assenza di interfaccia, scritte e firme. La mezzeria è libera per tutta l'altezza nel Profilo. Nelle altre otto pagine una fascia scura unisce le masse in basso. In ogni PNG almeno una massa supera il 25% già sopra la quota del pavimento (83% dell'altezza) e il lato ghiaccio raggiunge il bordo inferiore. Alcuni profili hanno dettagli interni e filetti più spessi del richiesto. Le misure della tabella usano alpha pari o superiore a 128 e sono arrotondate. Ritagli e sovrapposizione alle schermate nel simulatore da verificare.

## Resoconto di Claude
