# WB-008 · Personaggi ripensati dalla campagna: protagonista, equipaggiamento, Fabbro, Favilla

- **Stato:** IMPLEMENTATA (immagini usate nel documento di proposta)
- **Data:** 2026-11-01
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-008`

## Obiettivo

Sergio vuole una proposta grafica nuova dei personaggi principali **partendo solo dal documento
della campagna** (https://claude.ai/artifact/2GwyRT7Q7b1XD86KXFNTCh), che è la bibbia del carattere
e della storia del gioco: il protagonista con le proposte per i pezzi di equipaggiamento, il Fabbro
e Favilla. Queste immagini servono a un documento di proposta, che Claude costruisce attorno a loro;
il gioco non cambia.

È una proposta libera: **non** deve somigliare al diavoletto attuale né ai personaggi in bianco e nero.
Se qualcosa qui sembra contraddire `DECISIONI.md` (per esempio la fiammella col colore della squadra
del 26 ottobre), è voluto: Sergio l'ha chiesto, non serve segnalarlo.

### Cosa prendono dal documento della campagna

- I diavoletti vivono nella **Forgia**, l'antinferno; tu e Favilla siete apprendisti del Fabbro.
- Il protagonista è un diavoletto piccolo: ha **le corna** (nel purgatorio sette crepe sulle corna si
  chiudono una alla volta) e **una fiammella** sua. I Malebranche, «diavoli come te, ma grossi e
  bugiardi», sono i bulli dei diavoletti.
- **Il Fabbro**: il primo custode, col Maglio; battuto, ti fa da guida come Virgilio fino al pozzo dei
  giganti, dove si ferma: «Il ghiaccio spegne il fuoco. Da qui vai da solo».
- **Favilla**: l'amica d'infanzia, la sua fiamma è **la più calda dell'inferno**. Lucifero, congelato
  nel Cocito, gliela beve per liberarsi; dopo è solo una scintilla, e nel purgatorio sale con te.
- Il tono: cartone, buffo e affettuoso, «niente supplizi crudi»; versi di Dante, cartigli di
  pergamena, fondo color mattone e brace.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-005/riferimenti/R1_favilla.png` | il disegno di Favilla di Sergio, quello che compare nel documento della campagna (solo per `favilla_A`) |

Tutte le altre immagini non hanno riferimenti: il prompt basta.

## Immagini da generare

Ogni prompt è completo e va usato così com'è. I prompt sono in inglese perché il generatore li segue meglio. Sfondo piatto color pergamena chiara, **non**
trasparente (eccezione alla regola di `AGENTS.md`: sono illustrazioni per un documento); solo `trio`
ha uno scenario.

| Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|
| `1_protagonista_A` | | 1536×1024 | 1 |
| `2_protagonista_B` | | 1536×1024 | 1 |
| `3_protagonista_C` | | 1536×1024 | 1 |
| `4_equip_pezzi` | | 1536×1024 | 1 |
| `5_equip_livelli` | | 1536×1024 | 1 |
| `6_equip_gironi` | | 1536×1024 | 1 |
| `7_equip_misto` | | 1536×1024 | 1 |
| `8_fabbro_A` | | 1536×1024 | 1 |
| `9_fabbro_B` | | 1536×1024 | 1 |
| `10_favilla_A` | R1 | 1536×1024 | 1 |
| `11_favilla_B` | | 1536×1024 | 1 |
| `12_favilla_stati` | | 1536×1024 | 1 |
| `13_trio` | | 1536×1024 | 1 |

### `1_protagonista_A`

```
Draw the main character of a mobile video game set in Dante's Inferno, told as a funny, affectionate cartoon: a LITTLE IMP, A BLACKSMITH'S APPRENTICE.

The character: small and stocky, big head (about one third of his height), clever and stubborn, with a sly grin. Brick-red skin, parchment-colored belly and muzzle. Two short, sturdy bone-colored horns, curving slightly forward. Big yellow eyes with black pupils. A small orange flame burning on top of his head, between the horns. A long thin tail with an arrowhead tip. Four-fingered hands and bare feet with three stubby toes. A few soot smudges on his cheeks and hands. A LIGHT-BLUE neckerchief knotted around his neck (it is the team color, the only thing he always wears). Nothing else on him: no clothes, no armor.

Draw him three times, in a row from left to right, all the same size and well separated: 1) standing still, front view, hands on hips; 2) three-quarter view facing right, walking; 3) jumping to the right, holding a blacksmith's hammer bigger than his head, ready to strike.

The silhouette must read clearly even when the character is only 80 pixels tall: horns, flame and tail clearly separated from the body.

Style: cartoon illustration for a mobile video game, thick closed pure-black outline, flat solid colors with a single hard shadow (cel shading) and a few light antique-engraving hatch lines in the shadows, like the old engravings of Dante's Divine Comedy but in cartoon form. Warm palette: brick red #B8432A, parchment #F1DFB0, ember orange #FF8A3D, gold #F2C45A, burnt brown #2A160C. Flat light parchment background #F5EBD3, no scenery, no ground shadows. No text, numbers, labels, arrows or signatures anywhere. Landscape 3:2.
```

### `2_protagonista_B`

```
Draw the main character of a mobile video game set in Dante's Inferno, told as a funny, affectionate cartoon: a LITTLE IMP MADE OF BURNING COAL, a living ember that walked out of the forge.

The character: small and roundish, big head (about one third of his height), clever and stubborn, with a sly grin. The body is matte charcoal black-brown, with thin cracks glowing ember orange (on the chest, arms and knees). Two short glossy obsidian horns. Big, very bright white-and-yellow eyes standing out on the black. A small orange flame burning on top of his head, between the horns. A long thin tail whose arrowhead tip glows like an ember. Four-fingered hands and bare feet with three stubby toes. A LIGHT-BLUE neckerchief knotted around his neck (it is the team color, the only thing he always wears). Nothing else on him: no clothes, no armor.

Draw him three times, in a row from left to right, all the same size and well separated: 1) standing still, front view, hands on hips; 2) three-quarter view facing right, walking; 3) jumping to the right, holding a blacksmith's hammer bigger than his head, ready to strike.

The silhouette must read clearly even when the character is only 80 pixels tall: horns, flame and tail clearly separated from the body.

Style: cartoon illustration for a mobile video game, thick closed pure-black outline, flat solid colors with a single hard shadow (cel shading) and a few light antique-engraving hatch lines in the shadows, like the old engravings of Dante's Divine Comedy but in cartoon form. Warm palette: brick red #B8432A, parchment #F1DFB0, ember orange #FF8A3D, gold #F2C45A, burnt brown #2A160C. Flat light parchment background #F5EBD3, no scenery, no ground shadows. No text, numbers, labels, arrows or signatures anywhere. Landscape 3:2.
```

### `3_protagonista_C`

```
Draw the main character of a mobile video game set in Dante's Inferno, told as a funny, affectionate cartoon: a LITTLE IMP WITH HUGE HORNS, like a small stubborn ram.

The character: small, round and compact, big head (about one third of his height), clever and stubborn, with a sly grin. Dark red, almost burgundy skin, parchment-colored belly and muzzle. His main feature is TWO BIG RAM HORNS, curled in spirals on the sides of his head, bone-colored with raised ridges: almost as big as the head itself. Big yellow eyes with black pupils, bushy eyebrows. A small orange flame burning on top of his head, between the horns. A short thick tail ending in a pointed tuft. Four-fingered hands and small hooves instead of feet. A LIGHT-BLUE neckerchief knotted around his neck (it is the team color, the only thing he always wears). Nothing else on him: no clothes, no armor.

Draw him three times, in a row from left to right, all the same size and well separated: 1) standing still, front view, hands on hips; 2) three-quarter view facing right, walking; 3) jumping to the right, holding a blacksmith's hammer bigger than his head, ready to strike.

The silhouette must read clearly even when the character is only 80 pixels tall: horns, flame and tail clearly separated from the body.

Style: cartoon illustration for a mobile video game, thick closed pure-black outline, flat solid colors with a single hard shadow (cel shading) and a few light antique-engraving hatch lines in the shadows, like the old engravings of Dante's Divine Comedy but in cartoon form. Warm palette: brick red #B8432A, parchment #F1DFB0, ember orange #FF8A3D, gold #F2C45A, burnt brown #2A160C. Flat light parchment background #F5EBD3, no scenery, no ground shadows. No text, numbers, labels, arrows or signatures anywhere. Landscape 3:2.
```

### `4_equip_pezzi`

```
Draw a sheet of equipment pieces for a small, stocky imp (big head with two short horns, thin tail with an arrowhead tip), the hero of a cartoon video game set in Dante's Inferno. The imp is an apprentice in the devils' Forge and starts with nothing: these are his FIRST pieces, scrounged from the forge's scraps, funny and makeshift.

Six separate pieces, no character, front view, in two rows of three, well apart from each other, each one fully enclosed by the black outline:
1) HEAD: a dented little iron saucepan used as a helmet, with two holes for the horns to poke through;
2) TORSO: a scorched leather apron with a sewn-on patch, tied with a rope;
3) HANDS: two thick leather oven mitts, too big;
4) FEET: two rough iron clogs tied on with string;
5) TAIL: an iron thimble used as a tip cover on the end of the tail, with a short piece of tail inside it;
6) BACK: a pair of small wings made of sackcloth sewn onto a frame of sticks, with visible stitching.

Materials must read clearly: dark blue-grey iron, brown leather, beige canvas, string.

Style: cartoon illustration for a mobile video game, thick closed pure-black outline, flat solid colors with a single hard shadow (cel shading) and a few light antique-engraving hatch lines in the shadows, like the old engravings of Dante's Divine Comedy but in cartoon form. Warm palette: brick red #B8432A, parchment #F1DFB0, ember orange #FF8A3D, gold #F2C45A, burnt brown #2A160C. Flat light parchment background #F5EBD3, no ground shadows. No text, numbers, labels, arrows or signatures anywhere. Landscape 3:2.
```

### `5_equip_livelli`

```
Draw the hero of a cartoon video game set in Dante's Inferno: a small blacksmith-apprentice imp, short and stocky, big head, brick-red skin with parchment-colored belly and muzzle, two short bone-colored horns, big yellow eyes, a small orange flame burning on top of his head between the horns, a thin tail with an arrowhead tip, a light-blue neckerchief knotted around his neck.

Draw him FOUR times, in a row from left to right, front view, all the same size and well separated, always in the same proud pose. He wears the same set of six pieces (helmet, chest armor, gloves, boots, tail tip, wings on his back), which gets better at each step. The shape of every piece stays recognizable from one figure to the next: only the material and the details change.
1) SCRAP: a dented saucepan as a helmet, a scorched leather apron, oven mitts, iron clogs tied with string, a thimble on the tail, little sackcloth wings.
2) WROUGHT IRON: the same pieces remade properly in dark iron with rivets and brass trim; the helmet has two rings for the horns; the wings have an iron frame.
3) EMBER: the same iron with joints and edges glowing ember orange, small flames rising from the shoulders and the tail tip; the wings are leather with red-hot ribs.
4) GLORY: the same pieces in black iron and gold, with spiral engravings and a fire gem on the chest; the helmet has a crest of flames; the wings are large and full of flame.
The light-blue neckerchief is always visible at the neck. The face is always uncovered.

Style: cartoon illustration for a mobile video game, thick closed pure-black outline, flat solid colors with a single hard shadow (cel shading) and a few light antique-engraving hatch lines in the shadows, like the old engravings of Dante's Divine Comedy but in cartoon form. Warm palette: brick red #B8432A, parchment #F1DFB0, ember orange #FF8A3D, gold #F2C45A, burnt brown #2A160C. Flat light parchment background #F5EBD3, no scenery, no ground shadows. No text, numbers, labels, arrows or signatures anywhere. Landscape 3:2.
```

### `6_equip_gironi`

```
Draw a sheet of eight equipment pieces for a small, stocky imp (big head with two short horns, thin tail with an arrowhead tip), the hero of a cartoon video game set in Dante's Inferno. Each piece is a trophy: the Blacksmith forges it from what the imp takes away from the guardian of one circle of Hell. Funny tone, never macabre.

Eight separate pieces, no character, front view, in two rows of four, well apart from each other, each one fully enclosed by the black outline:
1) CERBERUS HELMET: a dark leather helmet with three little dog snouts on the front, pointed ears, and a studded collar as its rim;
2) PLUTUS ARMOR: a chest armor made of overlapping gold coins like scales, with a button shaped like a little money bag;
3) MINOS TAIL TIP: a tail tip shaped like a coiled serpent's tail, dark green and gold;
4) HARPY WINGS: two ruffled grey-violet feathered wings with small claws at the tips;
5) MINOTAUR HOOVES: two heavy boots shaped like bull hooves, iron and brown fur;
6) GAUNTLETS OF DIS: two red-hot iron gloves with smoking knuckles;
7) PITCH CLOAK: a short glossy black sticky cloak dripping in drops, with a hood with two points like the horns of the Malebranche devils;
8) COCYTUS CROWN: a crown of pale blue ice with crystal spikes and two rings for the horns.

Each piece has the color of its circle, but they all belong together.

Style: cartoon illustration for a mobile video game, thick closed pure-black outline, flat solid colors with a single hard shadow (cel shading) and a few light antique-engraving hatch lines in the shadows, like the old engravings of Dante's Divine Comedy but in cartoon form. Warm palette: brick red #B8432A, parchment #F1DFB0, ember orange #FF8A3D, gold #F2C45A, burnt brown #2A160C, ice blue #BFE9FF. Flat light parchment background #F5EBD3, no ground shadows. No text, numbers, labels, arrows or signatures anywhere. Landscape 3:2.
```

### `7_equip_misto`

```
Draw the hero of a cartoon video game set in Dante's Inferno: a small blacksmith-apprentice imp, short and stocky, big head, brick-red skin with parchment-colored belly and muzzle, two short bone-colored horns, big yellow eyes, a small orange flame burning on top of his head between the horns, a thin tail with an arrowhead tip, a light-blue neckerchief knotted around his neck.

Draw him THREE times, in a row from left to right, all the same size and well separated, to show that the pieces can be mixed freely:
1) WITH NOTHING: only the light-blue neckerchief, a bit embarrassed, covering his belly with his hands.
2) MIXED: a dented saucepan as a helmet with the horns poking through the holes, a chest armor of overlapping gold coins like scales, two leather oven mitts, two wrought-iron boots with rivets, no wings, a thimble on the tail tip. Happy and a bit goofy.
3) ALL TROPHIES: a pale blue ice crown with crystal spikes, a short dripping black pitch cloak, two red-hot iron gauntlets with smoking knuckles, two bull-hoof boots, a coiled serpent-tail tip, two ruffled grey-violet feathered wings. Proud, in a hero pose.
The face is always uncovered and the light-blue neckerchief always visible.

Style: cartoon illustration for a mobile video game, thick closed pure-black outline, flat solid colors with a single hard shadow (cel shading) and a few light antique-engraving hatch lines in the shadows, like the old engravings of Dante's Divine Comedy but in cartoon form. Warm palette: brick red #B8432A, parchment #F1DFB0, ember orange #FF8A3D, gold #F2C45A, burnt brown #2A160C, ice blue #BFE9FF. Flat light parchment background #F5EBD3, no scenery, no ground shadows. No text, numbers, labels, arrows or signatures anywhere. Landscape 3:2.
```

### `8_fabbro_A`

```
Draw THE BLACKSMITH, a character of a cartoon video game set in Dante's Inferno: the old devil who runs the little imps' Forge and teaches the apprentices. Gruff outside, kind inside: he is their first opponent and then their guide, like Virgil for Dante.

The character: a HUGE old devil, almost three times as tall as a little imp, extremely broad shoulders and arms as thick as anvils, short bowed legs. Dark red skin marked by spark scars. One whole horn and one broken halfway. A long, bushy ash-grey beard with a few glowing embers smoking in it. Enormous eyebrows, small sly eyes, big nose. A heavy leather apron full of burns and patches, iron wristbands, blacksmith goggles pushed up on his forehead. On his shoulder he carries a giant MAUL, with an iron head as big as a barrel and a leather-wrapped wooden handle.

Draw him three times, in a row from left to right, all the same size and well separated: 1) standing still, front view, maul on his shoulder, serious; 2) three-quarter view facing right, slamming the maul on the ground (ready to fight); 3) three-quarter view facing left, laughing with a hand on his belly, the maul resting on the ground.

Style: cartoon illustration for a mobile video game, thick closed pure-black outline, flat solid colors with a single hard shadow (cel shading) and a few light antique-engraving hatch lines in the shadows, like the old engravings of Dante's Divine Comedy but in cartoon form. Warm palette: brick red #B8432A, parchment #F1DFB0, ember orange #FF8A3D, gold #F2C45A, burnt brown #2A160C. Flat light parchment background #F5EBD3, no scenery, no ground shadows. No text, numbers, labels, arrows or signatures anywhere. Landscape 3:2.
```

### `9_fabbro_B`

```
Draw THE BLACKSMITH, a character of a cartoon video game set in Dante's Inferno: the old devil who runs the little imps' Forge and teaches the apprentices. Gruff outside, kind inside: he is their first opponent and then their guide, like Virgil for Dante. His fire is his life: that is why, when he reaches the frozen lake, he cannot go any further.

The character: a HUGE old devil, almost three times as tall as a little imp, shaped like a stove: his torso is a black iron FURNACE with a grated hatch on the belly, inside which a bright orange fire burns; a short chimney on his back puffs smoke. Thick dark-red arms, with huge soot-blackened hands. Short, sturdy legs. A head that is small compared to the body, with two long horns swept back, grey handlebar mustache, bushy eyebrows, small kind eyes. A leather apron under the furnace, iron wristbands. On his shoulder he carries a giant MAUL, with an iron head as big as a barrel and a leather-wrapped wooden handle.

Draw him three times, in a row from left to right, all the same size and well separated: 1) standing still, front view, maul on his shoulder, the belly fire burning bright; 2) three-quarter view facing right, slamming the maul on the ground (ready to fight), flames bursting out of the grate; 3) front view, standing on an edge of pale blue ice, frost on his mustache and the belly fire almost out, sad but determined.

Style: cartoon illustration for a mobile video game, thick closed pure-black outline, flat solid colors with a single hard shadow (cel shading) and a few light antique-engraving hatch lines in the shadows, like the old engravings of Dante's Divine Comedy but in cartoon form. Warm palette: brick red #B8432A, parchment #F1DFB0, ember orange #FF8A3D, gold #F2C45A, burnt brown #2A160C, ice blue #BFE9FF. Flat light parchment background #F5EBD3, no scenery and no ground shadows (only the ice edge under the third figure). No text, numbers, labels, arrows or signatures anywhere. Landscape 3:2.
```

### `10_favilla_A`

```
Image 1 is Sergio's black-and-white drawing of Favilla: take from it ONLY the idea of the head (a black flame curled at the top, with big eyes) and of the outfit (dark dress with a light skirt, light gloves). Do not copy the black-and-white style.

Draw FAVILLA, a character of a cartoon video game set in Dante's Inferno: a little she-imp, an apprentice in the devils' Forge, the hero's childhood friend. Her flame is the hottest in all of Hell. She is brave, cheerful and clever.

The character: as small as a little imp, big head (about one third of her height). Her head is a teardrop of dark flame, black-brown with an edge glowing ember orange, with a curl of flame twisted at the top. Huge bright eyes with eyelashes, ember-colored cheeks. Two short little horns. A dark little dress with a parchment-colored skirt, parchment-colored gloves, dark little shoes. A thin tail with a heart-shaped tip.

Draw her three times, in a row from left to right, all the same size and well separated: 1) standing still, front view, waving her hand; 2) three-quarter view facing right, running; 3) front view, angry, with the flame curl rising higher and brighter.

Style: cartoon illustration for a mobile video game, thick closed pure-black outline, flat solid colors with a single hard shadow (cel shading) and a few light antique-engraving hatch lines in the shadows, like the old engravings of Dante's Divine Comedy but in cartoon form. Warm palette: brick red #B8432A, parchment #F1DFB0, ember orange #FF8A3D, gold #F2C45A, burnt brown #2A160C. Flat light parchment background #F5EBD3, no scenery, no ground shadows. No text, numbers, labels, arrows or signatures anywhere. Landscape 3:2.
```

### `11_favilla_B`

```
Draw FAVILLA, a character of a cartoon video game set in Dante's Inferno: a little she-imp, an apprentice in the devils' Forge, the hero's childhood friend. Her flame is the hottest in all of Hell, and that is why it is NOT orange like everyone else's: it is white and blue, like the hottest fire. She is brave, cheerful and clever.

The character: as small as a little imp, big head (about one third of her height), brick-red skin with a parchment-colored muzzle, two short little horns. Instead of hair, a big LIVING FLAME that starts at her forehead and rises like a ponytail: white in the center, pale blue at the edges, with a few golden tips. Big yellow eyes with eyelashes, a confident smile. A parchment-colored canvas apprentice jumpsuit with rolled-up sleeves, a small leather apron, little brown boots. A thin tail with a heart-shaped tip.

Draw her three times, in a row from left to right, all the same size and well separated: 1) standing still, front view, hands on hips; 2) three-quarter view facing right, running, with the flame streaming behind her; 3) front view, holding a small ball of white-blue fire on her palm and looking at it.

Style: cartoon illustration for a mobile video game, thick closed pure-black outline, flat solid colors with a single hard shadow (cel shading) and a few light antique-engraving hatch lines in the shadows, like the old engravings of Dante's Divine Comedy but in cartoon form. Warm palette: brick red #B8432A, parchment #F1DFB0, ember orange #FF8A3D, gold #F2C45A, burnt brown #2A160C, and for her flame white #FFFFFF and pale blue #BFE9FF. Flat light parchment background #F5EBD3, no scenery, no ground shadows. No text, numbers, labels, arrows or signatures anywhere. Landscape 3:2.
```

### `12_favilla_stati`

```
Draw FAVILLA, a character of a cartoon video game set in Dante's Inferno: a little she-imp, big head, brick-red skin with a parchment-colored muzzle, two short little horns, big yellow eyes with eyelashes, a parchment-colored apprentice jumpsuit with rolled-up sleeves, a small leather apron, little brown boots, a thin tail with a heart-shaped tip. Instead of hair she has a white and blue LIVING FLAME, the hottest fire in Hell.

Tell her story in THREE figures, in a row from left to right, all the same size and well separated, front view:
1) FULL: the white-blue flame is big, tall and bright; she is laughing.
2) STOLEN: she is locked in a round cage of pale blue ice; her flame is being pulled upward in a long white-blue thread coming out between the bars; the flame on her head is small; she is tired but has her fists clenched, still stubborn.
3) SPARK: free, no cage, but only a tiny orange spark is left on her head; she is sad but smiling, one hand shielding the spark.

Tender tone, never dark or scary.

Style: cartoon illustration for a mobile video game, thick closed pure-black outline, flat solid colors with a single hard shadow (cel shading) and a few light antique-engraving hatch lines in the shadows, like the old engravings of Dante's Divine Comedy but in cartoon form. Warm palette: brick red #B8432A, parchment #F1DFB0, ember orange #FF8A3D, gold #F2C45A, burnt brown #2A160C, ice blue #BFE9FF, and for her flame white #FFFFFF and pale blue #BFE9FF. Flat light parchment background #F5EBD3, no scenery, no ground shadows. No text, numbers, labels, arrows or signatures anywhere. Landscape 3:2.
```

### `13_trio`

```
Draw the cover of a cartoon video game set in Dante's Inferno: the three main characters together in the devils' Forge, before the adventure begins. Funny, affectionate tone.

On the left THE BLACKSMITH: a huge old devil, almost three times as tall as the other two, shaped like a stove: his torso is a black iron furnace with a grated hatch on the belly where an orange fire burns; a short chimney puffing smoke from his back; thick dark-red arms; a small head with two long horns swept back, grey handlebar mustache; a leather apron; a giant maul resting on the ground. Smiling under his mustache, arms crossed.
In the center THE HERO: a small blacksmith-apprentice imp, short and stocky, big head, brick-red skin with parchment-colored belly and muzzle, two short bone-colored horns, big yellow eyes, a small orange flame burning on top of his head between the horns, a thin tail with an arrowhead tip, a light-blue neckerchief knotted around his neck, nothing else on him. He holds a blacksmith's hammer bigger than his head, sly grin.
On the right FAVILLA: a little she-imp as small as him, brick-red skin with a parchment-colored muzzle, two short little horns, big yellow eyes with eyelashes, a big white-and-blue living flame instead of hair, a parchment-colored apprentice jumpsuit with rolled-up sleeves, a small leather apron, a tail with a heart-shaped tip. She elbows him and laughs.

Behind them, simple and darker than the characters, the Forge: an anvil, the orange glow of a furnace, hanging chains and tools, sparks. The background must be dark and muted, the characters bright and crisp: they must stand out strongly from the background.

Style: cartoon illustration for a mobile video game, thick closed pure-black outline, flat solid colors with a single hard shadow (cel shading) and a few light antique-engraving hatch lines in the shadows, like the old engravings of Dante's Divine Comedy but in cartoon form. Warm palette: brick red #B8432A, parchment #F1DFB0, ember orange #FF8A3D, gold #F2C45A, burnt brown #2A160C, and for Favilla's flame white and pale blue #BFE9FF. No text, numbers, labels, arrows or signatures anywhere. Landscape 3:2.
```

## Criteri di accettazione

- [ ] stesso stile in tutte le immagini: cartone, contorno nero spesso e chiuso, colori piatti, una sola ombra netta
- [ ] il protagonista è piccolo, ha corna, fiammella, coda e fazzoletto azzurro; nessun vestito dove il prompt non lo chiede
- [ ] nei fogli dei pezzi ogni pezzo è staccato e intero, nessuno tagliato dal bordo
- [ ] in `5_equip_livelli` la forma di ogni pezzo si riconosce dalla prima alla quarta figura
- [ ] la fiamma di Favilla B è bianca e azzurra, non arancione
- [ ] nessuna scritta, numero, freccia o firma; niente di cruento

---

## Decisione

Approvata da Claude, 2026-11-01: scelta reversibile (immagini per un documento di proposta, il gioco
non cambia). Richiesta da Sergio nel thread "Ripensare i personaggi dalla campagna": «mi fai una
proposta grafica dei personaggi ... come se non conoscessi niente del gioco oltre al documento della
campagna ... se ti serve chat per produrre delle immagini fai i prompt per lui tramite git e poi li
eseguo».

## Consegna di Codex

Eseguita il 2026-11-01 con lo strumento image_gen. Prompt usati integralmente e senza modifiche; R1 allegato soltanto a 10_favilla_A. Sfondo non trasparente come richiesto.

### File consegnati

- `art/WB-008/1_protagonista_A.png` e `1_protagonista_A.txt` — 1 tentativi.
- `art/WB-008/2_protagonista_B.png` e `2_protagonista_B.txt` — 1 tentativi.
- `art/WB-008/3_protagonista_C.png` e `3_protagonista_C.txt` — 1 tentativi.
- `art/WB-008/4_equip_pezzi.png` e `4_equip_pezzi.txt` — 3 tentativi.
- `art/WB-008/5_equip_livelli.png` e `5_equip_livelli.txt` — 3 tentativi.
- `art/WB-008/6_equip_gironi.png` e `6_equip_gironi.txt` — 1 tentativi.
- `art/WB-008/7_equip_misto.png` e `7_equip_misto.txt` — 1 tentativi.
- `art/WB-008/8_fabbro_A.png` e `8_fabbro_A.txt` — 1 tentativi.
- `art/WB-008/9_fabbro_B.png` e `9_fabbro_B.txt` — 2 tentativi.
- `art/WB-008/10_favilla_A.png` e `10_favilla_A.txt` — 1 tentativi.
- `art/WB-008/11_favilla_B.png` e `11_favilla_B.txt` — 1 tentativi.
- `art/WB-008/12_favilla_stati.png` e `12_favilla_stati.txt` — 3 tentativi.
- `art/WB-008/13_trio.png` e `13_trio.txt` — 1 tentativi.

### Controlli e limiti

- Ispezionate visivamente tutte le tavole: personaggi, code e pezzi, margini, assenza di scritte e contenuti cruenti. Fiamma di Favilla B bianca e azzurra; fazzoletto del protagonista azzurro. Progressione dell'equipaggiamento riconoscibile.
- 4_equip_pezzi: dopo tre tentativi l'elmo presenta corna rosse anziché soltanto fori vuoti. Consegnato con difformità esplicita; richiede revisione di Claude.
- 12_favilla_stati: dopo tre tentativi il filo di fiamma della figura centrale continua oltre il bordo superiore. La figura centrale è accovacciata e la scintilla finale è più grande del richiesto. Consegnato con difformità esplicite.
- Il generatore ha introdotto texture, tratteggi e alcune sfumature: colori e sfondo non sono rigorosamente piatti; la testa dei piccoli è spesso più grande di un terzo dell'altezza. La stretta uniformità stilistica resta da approvare.
- Non verificata la leggibilità mediante una prova a 80 pixel né l'integrazione nel gioco (sono proposte per un documento).
- Consegna effettuata tramite connettore GitHub, costruendo il commit da main aggiornato: la shell non poteva connettersi al proxy per git pull/push. Nessuna PR e nessun merge.


## Resoconto di Claude

2026-11-01. Guardate tutte e 13 le tavole: tutte usate nel documento di proposta
https://claude.ai/artifact/JoPBZRtznYF3xGEao2pTXF (le immagini come JPG ridotti, insieme alla pagina).
Nessuna è scartata, perché ognuna serve a confrontare le proposte. I difetti sono scritti nel documento:

- `13_trio`: il protagonista ha gli zoccoli (quelli della proposta C) e il muso più lungo che in A; il fondo è più acceso di quanto chiesto.
- `4_equip_pezzi`: il pentolino ha corna rosse attaccate invece dei buchi per le corna.
- `7_equip_misto`: il puntale della coda nella terza figura è un serpente con la testa.
- `12_favilla_stati`: il filo di fiamma esce dal bordo in alto; nella gabbia Favilla è accovacciata.
- Tutte: più texture e sfumature del chiesto, teste più grandi di un terzo dell'altezza. Per i pezzi del gioco serve uno stile più pulito.

Prova di leggibilità fatta da Claude: la prima posa di protagonisti A, B, C e Favilla A, B ridotta a 90 pixel
sui colori di Forgia, Cocito e Limbo. A, C e Favilla B si leggono; B e Favilla A si perdono sui fondi scuri.
Il gioco non cambia: niente simulazione. Non verificato: niente, oltre alla prova a misura di gioco, è stato provato nel gioco.

