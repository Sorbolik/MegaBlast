# WB-077 · Sfondo intero dei menu, sagome e fondo nella stessa mano

- **Stato:** APPROVATA (Sergio, 18 nov, 14:03: deluso dal ritaglio e dal fondo disegnato da Claude, che «si stacca troppo»; la versione tutta di Codex è una delle correzioni proposte)
- **Data:** 2026-11-18
- **Ramo della scheda:** `claude/project-thread-flvu6y` (Codex la esegue da lì, non serve che sia su `main`) · **Ramo delle immagini:** `design/WB-077`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-077` senza chiedere conferma (il repository è privato).

## Obiettivo

Con WB-073 Codex ha disegnato le sagome, ma il fondo con i raggi e il pavimento li ha aggiunti
Claude nel codice, con aloni e sfumature: si stacca dalle sagome, e il ritaglio ai piedi si vede.
Qui Codex disegna **lo sfondo intero** di ogni pagina, senza pezzi di Claude: le stesse sagome di
WB-073, il cielo a bande scure dietro e il pavimento lucido sotto, tutto nella stessa mano. Nel
gioco resta un'immagine sola per pagina.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-073/sagome_<pagina>.png` | le sagome approvate di quella pagina, da tenere identiche |
| R2 | `art/WB-077/riferimenti/R2_oggi_su_main.jpg` | come appare oggi nel gioco (bocciato: fondo e pavimento non sono della stessa mano) |
| R3 | `art/WB-077/riferimenti/R3_bande_piatte.jpg` | bozza piatta del centro a bande scure |
| R4 | `art/WB-077/riferimenti/R4_armeria_in_uso.jpg` | una schermata in uso, per vedere quanto copre l'interfaccia (**da non disegnare**) |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. PNG opaco, 1672×941, una variante.

| Nome file | Riferimenti | Pagina |
|---|---|---|
| `sfondo_home` | R1 `art/WB-073/sagome_home.png`, R2, R3, R4 | HOME |
| `sfondo_zaino` | R1 `art/WB-073/sagome_zaino.png`, R2, R3, R4 | ZAINO |
| `sfondo_armeria` | R1 `art/WB-073/sagome_armeria.png`, R2, R3, R4 | ARMERIA |
| `sfondo_profilo` | R1 `art/WB-073/sagome_profilo.png`, R2, R3, R4 | PROFILO |
| `sfondo_eventi` | R1 `art/WB-073/sagome_eventi.png`, R2, R3, R4 | EVENTI |
| `sfondo_gioca_online` | R1 `art/WB-073/sagome_gioca_online.png`, R2, R3, R4 | GIOCA ONLINE |
| `sfondo_campagna` | R1 `art/WB-073/sagome_campagna.png`, R2, R3, R4 | CAMPAGNA |
| `sfondo_allenamento` | R1 `art/WB-073/sagome_allenamento.png`, R2, R3, R4 | ALLENAMENTO |
| `sfondo_impostazioni` | R1 `art/WB-073/sagome_impostazioni.png`, R2, R3, R4 | IMPOSTAZIONI |

### `sfondo_home`

Allega come immagine 1 `art/WB-073/sagome_home.png`, poi R2, R3 e R4.

```
Image 1 is the APPROVED pair of silhouettes for this menu screen of a mobile game about little devils in Dante's hell (you drew it, WB-073): keep EXACTLY these two silhouettes, same shapes, same place in the frame, same ink, same flat colors and rim lights; do not add or remove objects from them. Image 2 is how the game shows them today: the art director rejected it because the background behind and under the silhouettes was added by a programmer with soft glows and gradients and does not belong to the same drawing. Image 3 is a flat sketch of the wanted centre (dark comic banded rays). Image 4 shows a menu screen in use: the interface covers most of the screen and must stay the only lit, important thing (do not draw the interface).

Paint ONE complete, opaque background, 16:9, 1672x941, in which the two silhouettes, the sky behind them and the floor under them are ONE drawing by the same hand: flat comic-book illustration, thick near-black ink outlines, flat fills, NO gradients, NO glow, NO blur, NO soft edges, NO airbrush.

Behind the silhouettes: a very dark comic sky of flat radiating bands (like a sunburst) coming from behind the centre of the picture, slightly above the middle: about 22 bands alternating between two very close dark tones (#1B1620 and #221C28), with crisp edges, very low contrast, so it reads as depth and never as an object. Near the bottom left corner the dark gets a little warmer (a flat band of #2A1A18), near the top right a little colder (a flat band of #18202C), as flat shapes, not gradients.

The floor: a horizontal ink line at 85% of the height from the top, where both silhouettes stand; they must sit ON the floor naturally, with their bottoms resting on it (no straight cut across their shapes). Under the line a polished dark stone floor (#141117 to #0C0A0D in two or three flat bands) that reflects the two silhouettes upside down, very dark and flat, the reflection breaking into two or three flat horizontal strips as it goes down and disappearing before the bottom edge.

Keep the centre of the picture quiet: nothing there but the dark bands. The top left corner (left 25%, top 15%) stays empty and dark: the screen title goes there. No characters, no text, no letters, no numbers, no interface, no frame, no signature.
This one is for the menu screen HOME (the main menu).
```

### `sfondo_zaino`

Allega come immagine 1 `art/WB-073/sagome_zaino.png`, poi R2, R3 e R4.

```
Image 1 is the APPROVED pair of silhouettes for this menu screen of a mobile game about little devils in Dante's hell (you drew it, WB-073): keep EXACTLY these two silhouettes, same shapes, same place in the frame, same ink, same flat colors and rim lights; do not add or remove objects from them. Image 2 is how the game shows them today: the art director rejected it because the background behind and under the silhouettes was added by a programmer with soft glows and gradients and does not belong to the same drawing. Image 3 is a flat sketch of the wanted centre (dark comic banded rays). Image 4 shows a menu screen in use: the interface covers most of the screen and must stay the only lit, important thing (do not draw the interface).

Paint ONE complete, opaque background, 16:9, 1672x941, in which the two silhouettes, the sky behind them and the floor under them are ONE drawing by the same hand: flat comic-book illustration, thick near-black ink outlines, flat fills, NO gradients, NO glow, NO blur, NO soft edges, NO airbrush.

Behind the silhouettes: a very dark comic sky of flat radiating bands (like a sunburst) coming from behind the centre of the picture, slightly above the middle: about 22 bands alternating between two very close dark tones (#1B1620 and #221C28), with crisp edges, very low contrast, so it reads as depth and never as an object. Near the bottom left corner the dark gets a little warmer (a flat band of #2A1A18), near the top right a little colder (a flat band of #18202C), as flat shapes, not gradients.

The floor: a horizontal ink line at 85% of the height from the top, where both silhouettes stand; they must sit ON the floor naturally, with their bottoms resting on it (no straight cut across their shapes). Under the line a polished dark stone floor (#141117 to #0C0A0D in two or three flat bands) that reflects the two silhouettes upside down, very dark and flat, the reflection breaking into two or three flat horizontal strips as it goes down and disappearing before the bottom edge.

Keep the centre of the picture quiet: nothing there but the dark bands. The top left corner (left 25%, top 15%) stays empty and dark: the screen title goes there. No characters, no text, no letters, no numbers, no interface, no frame, no signature.
This one is for the menu screen ZAINO.
```

### `sfondo_armeria`

Allega come immagine 1 `art/WB-073/sagome_armeria.png`, poi R2, R3 e R4.

```
Image 1 is the APPROVED pair of silhouettes for this menu screen of a mobile game about little devils in Dante's hell (you drew it, WB-073): keep EXACTLY these two silhouettes, same shapes, same place in the frame, same ink, same flat colors and rim lights; do not add or remove objects from them. Image 2 is how the game shows them today: the art director rejected it because the background behind and under the silhouettes was added by a programmer with soft glows and gradients and does not belong to the same drawing. Image 3 is a flat sketch of the wanted centre (dark comic banded rays). Image 4 shows a menu screen in use: the interface covers most of the screen and must stay the only lit, important thing (do not draw the interface).

Paint ONE complete, opaque background, 16:9, 1672x941, in which the two silhouettes, the sky behind them and the floor under them are ONE drawing by the same hand: flat comic-book illustration, thick near-black ink outlines, flat fills, NO gradients, NO glow, NO blur, NO soft edges, NO airbrush.

Behind the silhouettes: a very dark comic sky of flat radiating bands (like a sunburst) coming from behind the centre of the picture, slightly above the middle: about 22 bands alternating between two very close dark tones (#1B1620 and #221C28), with crisp edges, very low contrast, so it reads as depth and never as an object. Near the bottom left corner the dark gets a little warmer (a flat band of #2A1A18), near the top right a little colder (a flat band of #18202C), as flat shapes, not gradients.

The floor: a horizontal ink line at 85% of the height from the top, where both silhouettes stand; they must sit ON the floor naturally, with their bottoms resting on it (no straight cut across their shapes). Under the line a polished dark stone floor (#141117 to #0C0A0D in two or three flat bands) that reflects the two silhouettes upside down, very dark and flat, the reflection breaking into two or three flat horizontal strips as it goes down and disappearing before the bottom edge.

Keep the centre of the picture quiet: nothing there but the dark bands. The top left corner (left 25%, top 15%) stays empty and dark: the screen title goes there. No characters, no text, no letters, no numbers, no interface, no frame, no signature.
This one is for the menu screen ARMERIA.
```

### `sfondo_profilo`

Allega come immagine 1 `art/WB-073/sagome_profilo.png`, poi R2, R3 e R4.

```
Image 1 is the APPROVED pair of silhouettes for this menu screen of a mobile game about little devils in Dante's hell (you drew it, WB-073): keep EXACTLY these two silhouettes, same shapes, same place in the frame, same ink, same flat colors and rim lights; do not add or remove objects from them. Image 2 is how the game shows them today: the art director rejected it because the background behind and under the silhouettes was added by a programmer with soft glows and gradients and does not belong to the same drawing. Image 3 is a flat sketch of the wanted centre (dark comic banded rays). Image 4 shows a menu screen in use: the interface covers most of the screen and must stay the only lit, important thing (do not draw the interface).

Paint ONE complete, opaque background, 16:9, 1672x941, in which the two silhouettes, the sky behind them and the floor under them are ONE drawing by the same hand: flat comic-book illustration, thick near-black ink outlines, flat fills, NO gradients, NO glow, NO blur, NO soft edges, NO airbrush.

Behind the silhouettes: a very dark comic sky of flat radiating bands (like a sunburst) coming from behind the centre of the picture, slightly above the middle: about 22 bands alternating between two very close dark tones (#1B1620 and #221C28), with crisp edges, very low contrast, so it reads as depth and never as an object. Near the bottom left corner the dark gets a little warmer (a flat band of #2A1A18), near the top right a little colder (a flat band of #18202C), as flat shapes, not gradients.

The floor: a horizontal ink line at 85% of the height from the top, where both silhouettes stand; they must sit ON the floor naturally, with their bottoms resting on it (no straight cut across their shapes). Under the line a polished dark stone floor (#141117 to #0C0A0D in two or three flat bands) that reflects the two silhouettes upside down, very dark and flat, the reflection breaking into two or three flat horizontal strips as it goes down and disappearing before the bottom edge.

Keep the centre of the picture quiet: nothing there but the dark bands. The top left corner (left 25%, top 15%) stays empty and dark: the screen title goes there. No characters, no text, no letters, no numbers, no interface, no frame, no signature.
This one is for the menu screen PROFILO.
```

### `sfondo_eventi`

Allega come immagine 1 `art/WB-073/sagome_eventi.png`, poi R2, R3 e R4.

```
Image 1 is the APPROVED pair of silhouettes for this menu screen of a mobile game about little devils in Dante's hell (you drew it, WB-073): keep EXACTLY these two silhouettes, same shapes, same place in the frame, same ink, same flat colors and rim lights; do not add or remove objects from them. Image 2 is how the game shows them today: the art director rejected it because the background behind and under the silhouettes was added by a programmer with soft glows and gradients and does not belong to the same drawing. Image 3 is a flat sketch of the wanted centre (dark comic banded rays). Image 4 shows a menu screen in use: the interface covers most of the screen and must stay the only lit, important thing (do not draw the interface).

Paint ONE complete, opaque background, 16:9, 1672x941, in which the two silhouettes, the sky behind them and the floor under them are ONE drawing by the same hand: flat comic-book illustration, thick near-black ink outlines, flat fills, NO gradients, NO glow, NO blur, NO soft edges, NO airbrush.

Behind the silhouettes: a very dark comic sky of flat radiating bands (like a sunburst) coming from behind the centre of the picture, slightly above the middle: about 22 bands alternating between two very close dark tones (#1B1620 and #221C28), with crisp edges, very low contrast, so it reads as depth and never as an object. Near the bottom left corner the dark gets a little warmer (a flat band of #2A1A18), near the top right a little colder (a flat band of #18202C), as flat shapes, not gradients.

The floor: a horizontal ink line at 85% of the height from the top, where both silhouettes stand; they must sit ON the floor naturally, with their bottoms resting on it (no straight cut across their shapes). Under the line a polished dark stone floor (#141117 to #0C0A0D in two or three flat bands) that reflects the two silhouettes upside down, very dark and flat, the reflection breaking into two or three flat horizontal strips as it goes down and disappearing before the bottom edge.

Keep the centre of the picture quiet: nothing there but the dark bands. The top left corner (left 25%, top 15%) stays empty and dark: the screen title goes there. No characters, no text, no letters, no numbers, no interface, no frame, no signature.
This one is for the menu screen EVENTI. The torch flame of the left silhouette sits in the title corner: keep the brazier but draw it unlit, as a dark flat shape.
```

### `sfondo_gioca_online`

Allega come immagine 1 `art/WB-073/sagome_gioca_online.png`, poi R2, R3 e R4.

```
Image 1 is the APPROVED pair of silhouettes for this menu screen of a mobile game about little devils in Dante's hell (you drew it, WB-073): keep EXACTLY these two silhouettes, same shapes, same place in the frame, same ink, same flat colors and rim lights; do not add or remove objects from them. Image 2 is how the game shows them today: the art director rejected it because the background behind and under the silhouettes was added by a programmer with soft glows and gradients and does not belong to the same drawing. Image 3 is a flat sketch of the wanted centre (dark comic banded rays). Image 4 shows a menu screen in use: the interface covers most of the screen and must stay the only lit, important thing (do not draw the interface).

Paint ONE complete, opaque background, 16:9, 1672x941, in which the two silhouettes, the sky behind them and the floor under them are ONE drawing by the same hand: flat comic-book illustration, thick near-black ink outlines, flat fills, NO gradients, NO glow, NO blur, NO soft edges, NO airbrush.

Behind the silhouettes: a very dark comic sky of flat radiating bands (like a sunburst) coming from behind the centre of the picture, slightly above the middle: about 22 bands alternating between two very close dark tones (#1B1620 and #221C28), with crisp edges, very low contrast, so it reads as depth and never as an object. Near the bottom left corner the dark gets a little warmer (a flat band of #2A1A18), near the top right a little colder (a flat band of #18202C), as flat shapes, not gradients.

The floor: a horizontal ink line at 85% of the height from the top, where both silhouettes stand; they must sit ON the floor naturally, with their bottoms resting on it (no straight cut across their shapes). Under the line a polished dark stone floor (#141117 to #0C0A0D in two or three flat bands) that reflects the two silhouettes upside down, very dark and flat, the reflection breaking into two or three flat horizontal strips as it goes down and disappearing before the bottom edge.

Keep the centre of the picture quiet: nothing there but the dark bands. The top left corner (left 25%, top 15%) stays empty and dark: the screen title goes there. No characters, no text, no letters, no numbers, no interface, no frame, no signature.
This one is for the menu screen GIOCA ONLINE.
```

### `sfondo_campagna`

Allega come immagine 1 `art/WB-073/sagome_campagna.png`, poi R2, R3 e R4.

```
Image 1 is the APPROVED pair of silhouettes for this menu screen of a mobile game about little devils in Dante's hell (you drew it, WB-073): keep EXACTLY these two silhouettes, same shapes, same place in the frame, same ink, same flat colors and rim lights; do not add or remove objects from them. Image 2 is how the game shows them today: the art director rejected it because the background behind and under the silhouettes was added by a programmer with soft glows and gradients and does not belong to the same drawing. Image 3 is a flat sketch of the wanted centre (dark comic banded rays). Image 4 shows a menu screen in use: the interface covers most of the screen and must stay the only lit, important thing (do not draw the interface).

Paint ONE complete, opaque background, 16:9, 1672x941, in which the two silhouettes, the sky behind them and the floor under them are ONE drawing by the same hand: flat comic-book illustration, thick near-black ink outlines, flat fills, NO gradients, NO glow, NO blur, NO soft edges, NO airbrush.

Behind the silhouettes: a very dark comic sky of flat radiating bands (like a sunburst) coming from behind the centre of the picture, slightly above the middle: about 22 bands alternating between two very close dark tones (#1B1620 and #221C28), with crisp edges, very low contrast, so it reads as depth and never as an object. Near the bottom left corner the dark gets a little warmer (a flat band of #2A1A18), near the top right a little colder (a flat band of #18202C), as flat shapes, not gradients.

The floor: a horizontal ink line at 85% of the height from the top, where both silhouettes stand; they must sit ON the floor naturally, with their bottoms resting on it (no straight cut across their shapes). Under the line a polished dark stone floor (#141117 to #0C0A0D in two or three flat bands) that reflects the two silhouettes upside down, very dark and flat, the reflection breaking into two or three flat horizontal strips as it goes down and disappearing before the bottom edge.

Keep the centre of the picture quiet: nothing there but the dark bands. The top left corner (left 25%, top 15%) stays empty and dark: the screen title goes there. No characters, no text, no letters, no numbers, no interface, no frame, no signature.
This one is for the menu screen CAMPAGNA.
```

### `sfondo_allenamento`

Allega come immagine 1 `art/WB-073/sagome_allenamento.png`, poi R2, R3 e R4.

```
Image 1 is the APPROVED pair of silhouettes for this menu screen of a mobile game about little devils in Dante's hell (you drew it, WB-073): keep EXACTLY these two silhouettes, same shapes, same place in the frame, same ink, same flat colors and rim lights; do not add or remove objects from them. Image 2 is how the game shows them today: the art director rejected it because the background behind and under the silhouettes was added by a programmer with soft glows and gradients and does not belong to the same drawing. Image 3 is a flat sketch of the wanted centre (dark comic banded rays). Image 4 shows a menu screen in use: the interface covers most of the screen and must stay the only lit, important thing (do not draw the interface).

Paint ONE complete, opaque background, 16:9, 1672x941, in which the two silhouettes, the sky behind them and the floor under them are ONE drawing by the same hand: flat comic-book illustration, thick near-black ink outlines, flat fills, NO gradients, NO glow, NO blur, NO soft edges, NO airbrush.

Behind the silhouettes: a very dark comic sky of flat radiating bands (like a sunburst) coming from behind the centre of the picture, slightly above the middle: about 22 bands alternating between two very close dark tones (#1B1620 and #221C28), with crisp edges, very low contrast, so it reads as depth and never as an object. Near the bottom left corner the dark gets a little warmer (a flat band of #2A1A18), near the top right a little colder (a flat band of #18202C), as flat shapes, not gradients.

The floor: a horizontal ink line at 85% of the height from the top, where both silhouettes stand; they must sit ON the floor naturally, with their bottoms resting on it (no straight cut across their shapes). Under the line a polished dark stone floor (#141117 to #0C0A0D in two or three flat bands) that reflects the two silhouettes upside down, very dark and flat, the reflection breaking into two or three flat horizontal strips as it goes down and disappearing before the bottom edge.

Keep the centre of the picture quiet: nothing there but the dark bands. The top left corner (left 25%, top 15%) stays empty and dark: the screen title goes there. No characters, no text, no letters, no numbers, no interface, no frame, no signature.
This one is for the menu screen ALLENAMENTO.
```

### `sfondo_impostazioni`

Allega come immagine 1 `art/WB-073/sagome_impostazioni.png`, poi R2, R3 e R4.

```
Image 1 is the APPROVED pair of silhouettes for this menu screen of a mobile game about little devils in Dante's hell (you drew it, WB-073): keep EXACTLY these two silhouettes, same shapes, same place in the frame, same ink, same flat colors and rim lights; do not add or remove objects from them. Image 2 is how the game shows them today: the art director rejected it because the background behind and under the silhouettes was added by a programmer with soft glows and gradients and does not belong to the same drawing. Image 3 is a flat sketch of the wanted centre (dark comic banded rays). Image 4 shows a menu screen in use: the interface covers most of the screen and must stay the only lit, important thing (do not draw the interface).

Paint ONE complete, opaque background, 16:9, 1672x941, in which the two silhouettes, the sky behind them and the floor under them are ONE drawing by the same hand: flat comic-book illustration, thick near-black ink outlines, flat fills, NO gradients, NO glow, NO blur, NO soft edges, NO airbrush.

Behind the silhouettes: a very dark comic sky of flat radiating bands (like a sunburst) coming from behind the centre of the picture, slightly above the middle: about 22 bands alternating between two very close dark tones (#1B1620 and #221C28), with crisp edges, very low contrast, so it reads as depth and never as an object. Near the bottom left corner the dark gets a little warmer (a flat band of #2A1A18), near the top right a little colder (a flat band of #18202C), as flat shapes, not gradients.

The floor: a horizontal ink line at 85% of the height from the top, where both silhouettes stand; they must sit ON the floor naturally, with their bottoms resting on it (no straight cut across their shapes). Under the line a polished dark stone floor (#141117 to #0C0A0D in two or three flat bands) that reflects the two silhouettes upside down, very dark and flat, the reflection breaking into two or three flat horizontal strips as it goes down and disappearing before the bottom edge.

Keep the centre of the picture quiet: nothing there but the dark bands. The top left corner (left 25%, top 15%) stays empty and dark: the screen title goes there. No characters, no text, no letters, no numbers, no interface, no frame, no signature.
This one is for the menu screen IMPOSTAZIONI.
```

## Criteri di accettazione

- [ ] le sagome sono le stesse di WB-073 (forme, posto, colori)
- [ ] sagome, cielo e pavimento sono un unico disegno piatto a fumetto: niente sfumature, aloni o sfocature
- [ ] le sagome poggiano sul pavimento senza tagli dritti, e la linea del pavimento è all'85%
- [ ] il cielo a bande è scuro e a basso contrasto, e il centro è calmo
- [ ] il riflesso sul pavimento è scuro, piatto e sparisce prima del bordo
- [ ] l'angolo del titolo, in alto a sinistra, è vuoto
- [ ] niente personaggi, scritte, interfaccia, cornici o firme

## Decisione

Reversibile (solo immagini in un ramo): approvata da Claude su richiesta di Sergio (18 nov).

## Consegna di Codex

## Resoconto di Claude
