# WB-053 · Uno sfondo per ogni schermata dei menu

- **Stato:** APPROVATA (Sergio, 15 nov: «dobbiamo trovare degli sfondi adatti ad ogni schermata, facciamoli fare a codex»; 10:17: «ok le suggerite», le proposte su https://claude.ai/artifact/3XLwcgQ67H9jBacc16g2JD)
- **Data:** 2026-11-15
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-053`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-053` senza chiedere conferma (il repository è privato).

## Obiettivo

Fra le schermate passa la tempra di fuoco e ghiaccio: la lama copre lo schermo e sotto cambia la
pagina. Oggi però tutti i menu mostrano lo stesso quadro (il posto raggiunto nella campagna), e la
schermata sembra un pannello appoggiato sopra. Sergio vuole uno sfondo **suo** per ogni schermata:
qui gli otto menu; la home resta col posto raggiunto nella campagna (WB-031).

Scelte di Sergio (15 nov, le consigliate della pagina di proposte): ZAINO la tana dell'apprendista,
ARMERIA la bottega del Fabbro, PROFILO la sala dei ricordi, EVENTI le gradinate dell'arena, GIOCA
ONLINE il crocevia delle porte, CAMPAGNA il bordo dell'abisso, ALLENAMENTO il cortile dei manichini,
IMPOSTAZIONI il banco degli attrezzi.

Nota di Claude: a differenza della home, nei menu l'interfaccia copre quasi tutto (R3): lo sfondo
deve restare scuro e calmo dappertutto, con le forme riconoscibili ai lati e in alto.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-053/riferimenti/R1_limbo_fumetto.jpg` | Limbo a fumetto (WB-030), approvato: lo stile |
| R2 | `art/WB-053/riferimenti/R2_forgia_fumetto.png` | Forgia a fumetto (WB-031), approvata: lo stile |
| R3 | `art/WB-053/riferimenti/R3_zaino_in_uso.png` | lo ZAINO sul telefono: quanto copre l'interfaccia. **L'interfaccia non va ridisegnata** |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega R1, R2 e R3 in quest'ordine. Formato 16:9,
1672×941 come WB-031 (o più grande, stessa forma), una variante.

| Nome file | Riferimenti | Schermata |
|---|---|---|
| `sfondo_menu_zaino` | R1, R2, R3 | ZAINO |
| `sfondo_menu_armeria` | R1, R2, R3 | ARMERIA |
| `sfondo_menu_profilo` | R1, R2, R3 | PROFILO |
| `sfondo_menu_eventi` | R1, R2, R3 | EVENTI |
| `sfondo_menu_gioca_online` | R1, R2, R3 | GIOCA ONLINE |
| `sfondo_menu_campagna` | R1, R2, R3 | CAMPAGNA |
| `sfondo_menu_allenamento` | R1, R2, R3 | ALLENAMENTO |
| `sfondo_menu_impostazioni` | R1, R2, R3 | IMPOSTAZIONI |

### `sfondo_menu_zaino`

```
Images 1 and 2 are two APPROVED backgrounds of a mobile game about little devils in Dante's hell (the circle of Limbo and the Forge). Image 3 shows a menu screen of the same game in use, with its comic-style interface on top (do not draw the interface). Paint a NEW background of exactly the same series, same style and same hand as images 1 and 2: flat comic-book illustration, thick near-black ink outlines, flat fills with at most 3 tones per shape, hard-edged shadow shapes, soft hard-edged light beams, a flat dark floor band with a thick ink line on top. Wide 16:9.

This background is for the menu screen ZAINO (the apprentice's backpack and gear). The place: THE APPRENTICE'S DEN: a cosy nook carved in dark rock, iron hooks on the walls with a few hanging empty belts and straps, an open wooden chest, a straw bed, a small oil lamp, a shelf with jars. Palette: dark warm brown rock, straw ochre, small orange lamp light, a cold blue crack of light at the top right.

Composition rules, follow exactly: this is a MENU background, the interface covers most of it (a column of item slots on the left, panels and grids in the middle, a column of numbers on the right, a bar at the bottom), so the whole picture stays DARK and CALM with moderate contrast, like image 3 behind its interface: light text and icons must stay readable anywhere on it. The recognizable shapes of the place stand at the left and right sides and along the top, the middle third is a quiet darker area with nothing that attracts the eye. The phone crops about 10% from each side and a little from the top, so every recognizable shape sits between 10% and 40% of the width from each edge, NOT against the edges. Fire and warm light at the bottom left, ice and cold light at the top right. The floor line is at 83% of the height from the top; below it only a plain dark floor band. No characters, no creatures that look alive, no text, no letters, no numbers, no interface, no frame, no signature.
```
### `sfondo_menu_armeria`

```
Images 1 and 2 are two APPROVED backgrounds of a mobile game about little devils in Dante's hell (the circle of Limbo and the Forge). Image 3 shows a menu screen of the same game in use, with its comic-style interface on top (do not draw the interface). Paint a NEW background of exactly the same series, same style and same hand as images 1 and 2: flat comic-book illustration, thick near-black ink outlines, flat fills with at most 3 tones per shape, hard-edged shadow shapes, soft hard-edged light beams, a flat dark floor band with a thick ink line on top. Wide 16:9.

This background is for the menu screen ARMERIA (upgrading and buying gear). The place: INSIDE THE SMITH'S WORKSHOP: a big anvil on a stump, racks of hammers and tongs, a leather bellows, a glowing brazier of embers, metal sheets leaning on the walls, sparks frozen in the air. Palette: soot black, rust, glowing orange embers, cold steel blue at the top right.

Composition rules, follow exactly: this is a MENU background, the interface covers most of it (a column of item slots on the left, panels and grids in the middle, a column of numbers on the right, a bar at the bottom), so the whole picture stays DARK and CALM with moderate contrast, like image 3 behind its interface: light text and icons must stay readable anywhere on it. The recognizable shapes of the place stand at the left and right sides and along the top, the middle third is a quiet darker area with nothing that attracts the eye. The phone crops about 10% from each side and a little from the top, so every recognizable shape sits between 10% and 40% of the width from each edge, NOT against the edges. Fire and warm light at the bottom left, ice and cold light at the top right. The floor line is at 83% of the height from the top; below it only a plain dark floor band. No characters, no creatures that look alive, no text, no letters, no numbers, no interface, no frame, no signature.
```
### `sfondo_menu_profilo`

```
Images 1 and 2 are two APPROVED backgrounds of a mobile game about little devils in Dante's hell (the circle of Limbo and the Forge). Image 3 shows a menu screen of the same game in use, with its comic-style interface on top (do not draw the interface). Paint a NEW background of exactly the same series, same style and same hand as images 1 and 2: flat comic-book illustration, thick near-black ink outlines, flat fills with at most 3 tones per shape, hard-edged shadow shapes, soft hard-edged light beams, a flat dark floor band with a thick ink line on top. Wide 16:9.

This background is for the menu screen PROFILO (the player's statistics and match history). The place: THE HALL OF MEMORIES: a stone hall with torn battle banners hanging from the ceiling, small trophies on stone shelves, tally marks scratched into the walls, a cracked shield and a broken horn on display. Palette: dark purple-grey stone, faded red and gold banners, warm torch light at the bottom left, cold pale light at the top right.

Composition rules, follow exactly: this is a MENU background, the interface covers most of it (a column of item slots on the left, panels and grids in the middle, a column of numbers on the right, a bar at the bottom), so the whole picture stays DARK and CALM with moderate contrast, like image 3 behind its interface: light text and icons must stay readable anywhere on it. The recognizable shapes of the place stand at the left and right sides and along the top, the middle third is a quiet darker area with nothing that attracts the eye. The phone crops about 10% from each side and a little from the top, so every recognizable shape sits between 10% and 40% of the width from each edge, NOT against the edges. Fire and warm light at the bottom left, ice and cold light at the top right. The floor line is at 83% of the height from the top; below it only a plain dark floor band. No characters, no creatures that look alive, no text, no letters, no numbers, no interface, no frame, no signature.
```
### `sfondo_menu_eventi`

```
Images 1 and 2 are two APPROVED backgrounds of a mobile game about little devils in Dante's hell (the circle of Limbo and the Forge). Image 3 shows a menu screen of the same game in use, with its comic-style interface on top (do not draw the interface). Paint a NEW background of exactly the same series, same style and same hand as images 1 and 2: flat comic-book illustration, thick near-black ink outlines, flat fills with at most 3 tones per shape, hard-edged shadow shapes, soft hard-edged light beams, a flat dark floor band with a thick ink line on top. Wide 16:9.

This background is for the menu screen EVENTI (global ranking and the events calendar). The place: THE ARENA STANDS seen from the sand: tiers of stone seats rising on both sides, pennants and flags on poles, big braziers on the stands, a royal box with a crown-shaped canopy far away, empty sand in the middle. Palette: sandstone, gold, red pennants, orange brazier light, an icy blue sky at the top right.

Composition rules, follow exactly: this is a MENU background, the interface covers most of it (a column of item slots on the left, panels and grids in the middle, a column of numbers on the right, a bar at the bottom), so the whole picture stays DARK and CALM with moderate contrast, like image 3 behind its interface: light text and icons must stay readable anywhere on it. The recognizable shapes of the place stand at the left and right sides and along the top, the middle third is a quiet darker area with nothing that attracts the eye. The phone crops about 10% from each side and a little from the top, so every recognizable shape sits between 10% and 40% of the width from each edge, NOT against the edges. Fire and warm light at the bottom left, ice and cold light at the top right. The floor line is at 83% of the height from the top; below it only a plain dark floor band. No characters, no creatures that look alive, no text, no letters, no numbers, no interface, no frame, no signature.
```
### `sfondo_menu_gioca_online`

```
Images 1 and 2 are two APPROVED backgrounds of a mobile game about little devils in Dante's hell (the circle of Limbo and the Forge). Image 3 shows a menu screen of the same game in use, with its comic-style interface on top (do not draw the interface). Paint a NEW background of exactly the same series, same style and same hand as images 1 and 2: flat comic-book illustration, thick near-black ink outlines, flat fills with at most 3 tones per shape, hard-edged shadow shapes, soft hard-edged light beams, a flat dark floor band with a thick ink line on top. Wide 16:9.

This background is for the menu screen GIOCA ONLINE (choosing an online queue). The place: THE CROSSROADS OF GATES: a round stone plaza ringed by several tall stone gates, each gate glowing with a different light (orange, blue, gold, purple) from the places beyond, chains and torches between them. Palette: dark slate stone, the colored glows kept soft, warm at the bottom left, cold at the top right.

Composition rules, follow exactly: this is a MENU background, the interface covers most of it (a column of item slots on the left, panels and grids in the middle, a column of numbers on the right, a bar at the bottom), so the whole picture stays DARK and CALM with moderate contrast, like image 3 behind its interface: light text and icons must stay readable anywhere on it. The recognizable shapes of the place stand at the left and right sides and along the top, the middle third is a quiet darker area with nothing that attracts the eye. The phone crops about 10% from each side and a little from the top, so every recognizable shape sits between 10% and 40% of the width from each edge, NOT against the edges. Fire and warm light at the bottom left, ice and cold light at the top right. The floor line is at 83% of the height from the top; below it only a plain dark floor band. No characters, no creatures that look alive, no text, no letters, no numbers, no interface, no frame, no signature.
```
### `sfondo_menu_campagna`

```
Images 1 and 2 are two APPROVED backgrounds of a mobile game about little devils in Dante's hell (the circle of Limbo and the Forge). Image 3 shows a menu screen of the same game in use, with its comic-style interface on top (do not draw the interface). Paint a NEW background of exactly the same series, same style and same hand as images 1 and 2: flat comic-book illustration, thick near-black ink outlines, flat fills with at most 3 tones per shape, hard-edged shadow shapes, soft hard-edged light beams, a flat dark floor band with a thick ink line on top. Wide 16:9.

This background is for the menu screen CAMPAGNA (choosing the next campaign mission). The place: THE EDGE OF THE ABYSS: a rocky ledge over a huge pit, a spiral stairway carved in the rock going down into the dark, tiny lights of the circles of hell far below, a crooked signpost and chains along the path. Palette: dark brown rock, deep red glow from below, gold lights, cold blue mist at the top right.

Composition rules, follow exactly: this is a MENU background, the interface covers most of it (a column of item slots on the left, panels and grids in the middle, a column of numbers on the right, a bar at the bottom), so the whole picture stays DARK and CALM with moderate contrast, like image 3 behind its interface: light text and icons must stay readable anywhere on it. The recognizable shapes of the place stand at the left and right sides and along the top, the middle third is a quiet darker area with nothing that attracts the eye. The phone crops about 10% from each side and a little from the top, so every recognizable shape sits between 10% and 40% of the width from each edge, NOT against the edges. Fire and warm light at the bottom left, ice and cold light at the top right. The floor line is at 83% of the height from the top; below it only a plain dark floor band. No characters, no creatures that look alive, no text, no letters, no numbers, no interface, no frame, no signature.
```
### `sfondo_menu_allenamento`

```
Images 1 and 2 are two APPROVED backgrounds of a mobile game about little devils in Dante's hell (the circle of Limbo and the Forge). Image 3 shows a menu screen of the same game in use, with its comic-style interface on top (do not draw the interface). Paint a NEW background of exactly the same series, same style and same hand as images 1 and 2: flat comic-book illustration, thick near-black ink outlines, flat fills with at most 3 tones per shape, hard-edged shadow shapes, soft hard-edged light beams, a flat dark floor band with a thick ink line on top. Wide 16:9.

This background is for the menu screen ALLENAMENTO (training matches against bots). The place: THE TRAINING YARD: a fenced yard of beaten earth, straw dummies and round targets on posts, sandbags, a wooden palisade, practice weapons in a barrel, a lantern on a pole. Palette: warm earth, straw ochre, weathered wood, orange lantern light, cold dusk blue at the top right.

Composition rules, follow exactly: this is a MENU background, the interface covers most of it (a column of item slots on the left, panels and grids in the middle, a column of numbers on the right, a bar at the bottom), so the whole picture stays DARK and CALM with moderate contrast, like image 3 behind its interface: light text and icons must stay readable anywhere on it. The recognizable shapes of the place stand at the left and right sides and along the top, the middle third is a quiet darker area with nothing that attracts the eye. The phone crops about 10% from each side and a little from the top, so every recognizable shape sits between 10% and 40% of the width from each edge, NOT against the edges. Fire and warm light at the bottom left, ice and cold light at the top right. The floor line is at 83% of the height from the top; below it only a plain dark floor band. No characters, no creatures that look alive, no text, no letters, no numbers, no interface, no frame, no signature.
```
### `sfondo_menu_impostazioni`

```
Images 1 and 2 are two APPROVED backgrounds of a mobile game about little devils in Dante's hell (the circle of Limbo and the Forge). Image 3 shows a menu screen of the same game in use, with its comic-style interface on top (do not draw the interface). Paint a NEW background of exactly the same series, same style and same hand as images 1 and 2: flat comic-book illustration, thick near-black ink outlines, flat fills with at most 3 tones per shape, hard-edged shadow shapes, soft hard-edged light beams, a flat dark floor band with a thick ink line on top. Wide 16:9.

This background is for the menu screen IMPOSTAZIONI (the game settings). The place: THE TOOL BENCH: a sturdy workbench against a stone wall, big cogwheels and levers on the wall, wrenches and keys hanging on nails, pipes with small valves, a lantern. Palette: dark iron grey, brass, warm lantern light at the bottom left, cold blue steel at the top right.

Composition rules, follow exactly: this is a MENU background, the interface covers most of it (a column of item slots on the left, panels and grids in the middle, a column of numbers on the right, a bar at the bottom), so the whole picture stays DARK and CALM with moderate contrast, like image 3 behind its interface: light text and icons must stay readable anywhere on it. The recognizable shapes of the place stand at the left and right sides and along the top, the middle third is a quiet darker area with nothing that attracts the eye. The phone crops about 10% from each side and a little from the top, so every recognizable shape sits between 10% and 40% of the width from each edge, NOT against the edges. Fire and warm light at the bottom left, ice and cold light at the top right. The floor line is at 83% of the height from the top; below it only a plain dark floor band. No characters, no creatures that look alive, no text, no letters, no numbers, no interface, no frame, no signature.
```

## Criteri di accettazione

- [ ] stesso stile e stessa mano di R1 e R2
- [ ] scuro e calmo dappertutto, il terzo centrale senza niente che attiri l'occhio
- [ ] forme riconoscibili tra il 10% e il 40% da ogni bordo, niente contro i bordi
- [ ] fuoco in basso a sinistra, ghiaccio in alto a destra
- [ ] niente personaggi, scritte, interfaccia, cornici o firme

## Dopo le immagini (lo fa Claude)

- Guarda ogni sfondo sotto la sua schermata vera nel simulatore (16:9, 20:9 e 4:3) e scarta quelli
  che rendono difficili i testi.
- Nel gioco ogni menu passa il suo sfondo a `kit.scene` al posto del posto della campagna; la home
  resta com'è. Gli sfondi cambiano sotto la tempra, insieme alla pagina.

## Decisione

Reversibile (solo immagini in un ramo): approvata su richiesta di Sergio.
