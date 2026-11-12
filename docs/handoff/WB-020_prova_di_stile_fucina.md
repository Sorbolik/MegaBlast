# WB-020 · Prova di stile dell'interfaccia «Fucina contro Abisso»

- **Stato:** SCARTATA (Sergio, 2026-11-12, visti i bozzetti: «è troppo dettagliato come stile»; l'identità resta, lo stile diventa a linee: WB-021)
- **Data:** 2026-11-12
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-020`

## Obiettivo

Sergio (12 nov) vuole rifare tutta l'interfaccia dei menu: non più forme piatte e raggi, ma
menu che sono **pezzi della fucina** (ferro battuto, lingotti che si arroventano, pergamena,
cuoio), col caldo della Forgia contro il gelo del fondo dell'inferno. Prima di produrre i
pezzi veri (WB-021) e le scene (WB-022) servono **tre schermate finte intere** per decidere
lo stile: home, ARMERIA, mappa dei gironi. Sono bozzetti: non entrano nel gioco.

## Cosa teniamo e cosa scartiamo

| Teniamo | Perché |
|---|---|
| La disposizione dei menu di oggi (R1, R2, R3): dove stanno porte, diavoletto, azione principale, monete, rotellina, tasto indietro | la struttura è decisa (10 nov): cambia la pelle, non dove stanno le cose |
| I personaggi dei fogli scelti (R4, R5), il contorno nero spesso e i colori pieni delle tavole (R6) | i menu devono sembrare lo stesso mondo della storia |
| Una sola azione principale per schermata, la più calda e luminosa (ferro incandescente) | regola dell'interfaccia: si deve capire subito cosa premere |
| Tavolozza: fuliggine `#121013`, ferro `#262329`, acciaio `#4A4550`, pergamena `#D9C5A0`, brace `#B8291C`, arancione `#F26419`, oro fuso `#FFB703`, scintilla `#FFF3B0`, abisso `#0F2537`, ciano `#38B6FF`, brina `#CAF0F8`, testo avorio `#F4ECE1` | la proposta scelta da Sergio |
| Forme forgiate: angoli tagliati a 45°, lingotti rastremati, rivetti, bulloni esagonali | niente cerchi perfetti né angoli arrotondati moderni |

| Scartiamo | Perché |
|---|---|
| Raggi, forme piatte inclinate, giallo pieno, sfondo blu notte | è l'interfaccia di oggi, quella che si cambia |
| Ferro fotografico, 3D, riflessi realistici, ruggine sporca dappertutto | deve restare un fumetto leggibile su un telefono |
| Testi piccoli e fitti, decorazioni sopra le scritte | le scritte le mette il gioco e devono leggersi a colpo d'occhio |
| HUD di battaglia | si fa dopo i menu, con una scheda sua |

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-020/riferimenti/R1_home_oggi.png` | la home di oggi: copiare la **disposizione**, non lo stile |
| R2 | `art/WB-020/riferimenti/R2_armeria_oggi.png` | l'ARMERIA di oggi: disposizione |
| R3 | `art/WB-020/riferimenti/R3_gironi_oggi.png` | la mappa dei gironi di oggi: cosa c'è sullo schermo |
| R4 | `art/WB-012/scelti/apprendista.png` | il foglio dell'apprendista (il diavoletto del giocatore) |
| R5 | `art/WB-012/scelti/fabbro.png` | il foglio del Fabbro |
| R6 | `art/WB-017/s_forgia_aperta.png` | una tavola della storia: lo stile del disegno e la Forgia |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto: il
primo è "image 1", il secondo "image 2" e così via. Formato largo 16:9 (1672×941 va bene),
sfondo della scena (non trasparente). **Qui le scritte ci vogliono**: solo quelle elencate
nel prompt, in maiuscolo, scritte giuste.

| Nome file | Riferimenti | Varianti |
|---|---|---|
| `stile_home` | R1, R4, R5, R6 | 2 |
| `stile_armeria` | R2, R4, R6 | 1 |
| `stile_gironi` | R3, R6 | 1 |

### `stile_home`

```
Image 1 is a screenshot of the current main menu of a mobile game: keep its LAYOUT (what is where) but NOT its flat graphic style. Image 2 is the model sheet of the player's little devil, image 3 the model sheet of the Blacksmith: copy both characters EXACTLY from their sheets, do not redesign them; the Blacksmith holds a hammer here. Image 4 shows the illustration style and the forge.

A full-screen UI mockup, 16:9 landscape, of the main menu of a 2D cartoon game set in a hellish forge. The menu is part of the forge itself (diegetic UI). Comic style of image 4: thick slightly irregular black ink outlines, flat saturated colors, light hatching in shadows, no photorealism, no 3D render.

Background: the inside of the forge, dark soot and slate stone (#121013, #262329), warm light from a furnace. On the far left, small and in the background, the Blacksmith stands at his anvil seen from behind three-quarter, hammer raised, sparks flying from the anvil across the screen. A few embers float upward.

Center: the little devil of image 2 standing, big, same pose and place as in image 1, lit warm from the forge.

Left column, as in image 1: three menu buttons that are dark wrought-iron ingots (tapered bars with corners chiselled at 45 degrees, one rivet at each end) hanging from short chains, stacked vertically, with ivory engraved capital letters: "CAMPAGNA", "ALLENAMENTO", "EVENTI". Below them a thinner nailed iron tag: "STESSO TELEFONO".

Right, as in image 1: one much bigger ingot, the main action, glowing red-hot (orange #F26419 to molten gold #FFB703 with a white-hot core, heat shimmer and tiny sparks), with big dark engraved letters "GIOCA". Under it a small dark iron tag: "2 CONTRO 2".

Bottom center: a riveted iron name plate with a strip of burnt parchment: "SORBO" and "LIV 23".
Top left: the game logo "MEGABLAST" as letters branded by fire into dark metal. Top right: two small riveted iron plates with a coin icon "1240" and a gem icon "35", and a hexagonal bolt head with a gear symbol.

All text ivory (#F4ECE1) or dark on hot metal, clean and perfectly readable, only the words listed here, nothing else written. Nothing perfectly round, no modern rounded rectangles, no gradients like a phone app. Keep wide calm dark areas; do not clutter.
```

### `stile_armeria`

```
Image 1 is a screenshot of the current armory screen of a mobile game: keep its LAYOUT (what is where) but NOT its flat graphic style. Image 2 is the model sheet of the player's little devil: copy him EXACTLY, do not redesign him. Image 3 shows the illustration style.

A full-screen UI mockup, 16:9 landscape, of the armory screen of a 2D cartoon game set in a hellish forge. The screen is the Blacksmith's workbench (diegetic UI). Comic style of image 3: thick slightly irregular black ink outlines, flat saturated colors, light hatching, no photorealism, no 3D render.

Background: a dark soot-stained workbench of wood and lava stone, with tongs, a hammer and white chalk sketches near the edges, dark and calm (#121013, #262329), warm glow from the left.

Left-center: the little devil of image 2 standing, big, as in image 1.

Next to him, as in image 1: four stacked equipment slots made of wrought-iron plates with chiselled 45-degree corners and rivets, each with a small ivory label and a big name: "ELMO CORVO", "CORAZZA FORNACE", "MANTELLO CORVO", "STIVALI LEVIATANO"; the first one is selected and its edge glows hot orange.

Right: a card of burnt parchment (#D9C5A0) with scorched curled corners nailed on a dark iron plate, like a technical blueprint: title "ELMO CORVO" in dark charcoal ink, a charcoal sketch of a crow-shaped helmet, and a short list of stats written in ink with small iron-tube bars filled with glowing lava: "VITA", "CORSA", "SALTO".

Top: three leather-and-metal bookmark tabs: "ARMADIO" (lit), "BOTTEGA", "CATALOGO". Top left the title "ARMERIA" branded by fire into metal. Top right two small riveted plates with a coin icon "1240" and a gem icon "35".
Bottom right: one big red-hot glowing ingot, the main action, with dark engraved letters "POTENZIA". Bottom left: a small hexagonal bolt head with a back arrow, and a riveted name plate "SORBO LIV 23".

All text clean and perfectly readable, only the words listed here. Nothing perfectly round, no modern rounded rectangles. Keep calm dark areas between the elements.
```

### `stile_gironi`

```
Image 1 is a screenshot of the current campaign map of a mobile game (the circles of hell, one below the other): keep WHAT is on screen but NOT its flat graphic style. Image 2 shows the illustration style.

A full-screen UI mockup, 16:9 landscape, of the campaign map of a 2D cartoon game: the descent through the nine circles of Dante's hell, drawn in ink on a long old parchment scroll lying on a dark soot table (diegetic UI). Comic style of image 2: thick slightly irregular black ink outlines, flat colors, light hatching, no photorealism.

The scroll shows hell as a funnel seen in section: wide rings at the top, narrower going down. The top of the parchment is warm: burnt edges, soot stains, orange glow, a small drawing of a forge. Going down the parchment gets colder: blue shadows, then frost, torn edges and cyan ice crystals (#38B6FF, #CAF0F8) at the very bottom, where a small figure is frozen in a block of ice.

The second ring is the open one: it is drawn larger and brighter, with a path of five round-ish hammered iron studs joined by an ink line; three studs are done (gold, with small stars under them), the fourth is the current one and holds a tiny burning anvil that melts the frost around it, the last is a small crown. The rings below are greyed out, each with a small iron padlock. Ring names in ink capitals next to the rings: "LIMBO", "LUSSURIA", "GOLA".

Top left: the title "LUSSURIA" branded by fire into a dark iron plate. Top right two small riveted iron plates with a coin icon "1240" and a gem icon "35".
Bottom center: a small card of parchment nailed on iron: "4 · SPINGI COL VENTO". Bottom right: one big red-hot glowing iron ingot, the main action, with dark engraved letters "GIOCA". Bottom left: a small hexagonal bolt head with a back arrow.

All text clean and perfectly readable, only the words listed here. No modern rounded rectangles. Keep the table around the scroll dark and calm.
```

## Criteri di accettazione

- [ ] la disposizione è quella dei riferimenti: stesse cose negli stessi posti
- [ ] l'azione principale (lingotto incandescente) è la cosa più luminosa dello schermo
- [ ] contorno a inchiostro e colori pieni come le tavole: niente ferro fotografico o 3D
- [ ] apprendista e Fabbro sono quelli dei fogli
- [ ] le scritte sono solo quelle chieste, giuste e leggibili
- [ ] sfondi scuri e calmi: le scritte chiare si leggono dappertutto

## Dopo le immagini (lo fa Claude)

Le fa vedere a Sergio, che sceglie lo stile (o dice cosa cambiare). Da quello scelto nascono
WB-021 (i pezzi: lastre, lingotti, targhette, bulloni, pergamene, linguette, barre, icone, in
ferro spento con la maschera della parte che si accende) e WB-022 (le scene a strati), con i
loro limiti: peso (l'APK deve stare sotto i 50 MB), 120 FPS, bordi lisci su ogni schermo.
Il Figma dell'interfaccia si aggiorna con lo stile scelto.

---

## Decisione

Approvata da Sergio il 12 nov 2026 («Sì» al piano: prova di stile prima, HUD dopo i menu,
font scolpito solo nei titoli).

## Consegna di Codex

## Resoconto di Claude

Bozzetti consegnati sul ramo `design/WB-020` (8b84b07c), fedeli alla scheda. Sergio (12 nov): «mi piace
l'idea perché adesso ha un'identità, ma è troppo dettagliato [...] molto più minimalista», con linee
che ogni tanto pulsano, fuoco e ghiaccio in ogni schermata e Codex solo per i disegni veri. Niente
entra nel gioco; il ramo non si porta su main. Si continua con «Filo di brace» e WB-021.
