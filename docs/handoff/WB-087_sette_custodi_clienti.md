# WB-087 · Gli altri sette custodi clienti

- **Stato:** APPROVATA (Sergio, 23 nov 14:55: «Mi piace Caronte, procedi»)
- **Data:** 2026-11-23
- **Ramo della scheda:** `claude/project-thread-ft5von` (Codex la esegue da qui: `git fetch origin claude/project-thread-ft5von`, non serve che sia su `main`) · **Ramo delle immagini:** `design/WB-087`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-087` senza chiedere conferma (il repository è privato).

## Obiettivo

Caronte (WB-086, variante 2) è piaciuto: gli altri sette custodi dei gironi, clienti del Fabbro nelle Commesse ([docs/commesse.md](../commesse.md)), si disegnano **uguali a lui**: stesso foglio (figura intera più tre busti: chiede, contento, fiero), stessa mano, stessi riquadri. Ogni custode porta il colore della sua famiglia.

Il gioco usa il busto sul cartellino (circa 150 px di larghezza) e più grande quando il cartellino si apre: i busti devono restare leggibili in piccolo e ognuno deve avere **una sagoma sua**, che non si confonde con gli altri.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-086/caronte_2.png` | il foglio di Caronte scelto da Sergio: il FOGLIO e lo STILE da copiare (quattro riquadri, china, tratteggio, pergamena) |
| R2 | `art/WB-012/3_foglio_fabbro_2.png` | il foglio del Fabbro: lo stesso mondo, per le proporzioni dei diavoli |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine: R1 è "image 1", R2 è "image 2".

| Nome file | Custode | Famiglia | Riferimenti | Misura | Varianti |
|---|---|---|---|---|---|
| `minosse` | Minosse | CORVO (azzurro acciaio) | R1, R2 | 1536×1024 | 2 |
| `cerbero` | Cerbero | FORNACE (arancione) | R1, R2 | 1536×1024 | 2 |
| `plutone` | Plutone | FABBRO (oro) | R1, R2 | 1536×1024 | 2 |
| `flegias` | Flegias | LEVIATANO (verde mare) | R1, R2 | 1536×1024 | 2 |
| `medusa` | Medusa | VUOTO (viola) | R1, R2 | 1536×1024 | 2 |
| `minotauro` | Minotauro | FORNACE (arancione) | R1, R2 | 1536×1024 | 2 |
| `malacoda` | Malacoda | CORVO (azzurro acciaio) | R1, R2 | 1536×1024 | 2 |

Le varianti si chiamano `<nome>_1.png` e `<nome>_2.png`, in `art/WB-087/` (quattordici fogli). Per ogni foglio Codex scrive un `.txt` con lo stesso nome: cosa ha fatto e cosa non è riuscito a rispettare.

### `minosse`

```
Image 1 is a character sheet of Charon, a character of our game: four panels in one row, a full figure and three busts with different expressions. It is the SHEET and the STYLE to copy exactly: the same four panels of the same size, thick slightly irregular black ink outline, short ink hatching for the shadows, flat warm colors, a pale parchment background in each panel, hand-drawn like a European comic. Image 2 is the character sheet of the Blacksmith of the same world: the same cartoon devil kind.

Draw a character sheet of a NEW character of the same world, in the same style and with the same four panels: MINOS, the judge at the gate of the second circle, who judges everyone who passes by coiling his tail. He or she is a customer of the Blacksmith: funny rather than scary. The character: a pompous, fussy old judge, round and short where Charon is tall and thin: a big belly, a double chin, a tiny pair of round spectacles on a short snout, two short thick horns curled like a ram's, and a VERY LONG snake-like tail that coils twice around his own waist like a belt, its tip shaped like a small hook. Skin dusty lilac grey (#9A8FA8, shadow #6A5F78). He wears a judge's robe, pale steel blue (#9EC4E0, highlight #D6E9F5, shadow #5F86A3), with a wide collar of black raven feathers, and a small crooked iron crown. Prop: he holds the hooked tip of his own tail in one hand like a judge's gavel.

Four panels on one sheet, same size, in one row:
1. FULL FIGURE: Minos sitting on a tall stone judge's seat, his tail hanging down in coils, seen from three quarters.
2. BUST, ASKING: he points at the viewer with the tip of his tail, the other hand open, one eyebrow raised over the spectacles, mouth closed and severe: "I need something from you".
3. BUST, PLEASED: a small satisfied closed-mouth smile, eyes half closed, he polishes his spectacles on the robe.
4. BUST, PROUD: chin up, eyes closed, a wide toothy smile, he holds the tip of his tail up like a raised gavel.
In the three busts the head, the horns, the clothes and the colors are IDENTICAL: only the expression and the hands change. The busts are framed like Charon's in image 1: head and shoulders, turned three quarters, filling the panel. Keep the whole silhouette (horns and prop included) inside each panel, with some margin on every side, the bottom too. No letters, no numbers, no speech balloons.
```

### `cerbero`

```
Image 1 is a character sheet of Charon, a character of our game: four panels in one row, a full figure and three busts with different expressions. It is the SHEET and the STYLE to copy exactly: the same four panels of the same size, thick slightly irregular black ink outline, short ink hatching for the shadows, flat warm colors, a pale parchment background in each panel, hand-drawn like a European comic. Image 2 is the character sheet of the Blacksmith of the same world: the same cartoon devil kind.

Draw a character sheet of a NEW character of the same world, in the same style and with the same four panels: CERBERUS, the three-headed guard dog of the third circle, always hungry. He or she is a customer of the Blacksmith: funny rather than scary. The character: a huge fat cartoon mastiff with THREE heads on one body and small devil horns on each head: the left head is grumpy with a torn ear, the middle head is greedy with its tongue out, the right head is sleepy with droopy eyes. Fur dark muddy brown (#6B4A36, shadow #3F2A1E, belly #B88A5E), mud on the paws. Each head wears a studded collar, hot orange (#F26419, highlight #FFB703, shadow #A63A0B), and from the middle collar hangs a small glowing ember tag. Prop: between his front paws he keeps one enormous gnawed bone.

Four panels on one sheet, same size, in one row:
1. FULL FIGURE: Cerberus sitting like a guard dog in a muddy puddle, the bone between his paws, seen from three quarters.
2. BUST, ASKING: the three heads look at the viewer, the middle one holds an EMPTY food bowl in its mouth and offers it, the other two stare with big hungry eyes: "we need something from you".
3. BUST, PLEASED: the three heads with eyes half closed and small satisfied closed-mouth smiles, the middle one licking its lips.
4. BUST, PROUD: the three heads chin up, eyes closed, wide toothy smiles, the bone held high by the middle head like a trophy.
In the three busts the head, the horns, the clothes and the colors are IDENTICAL: only the expression and the hands change. The busts are framed like Charon's in image 1: head and shoulders, turned three quarters, filling the panel. Keep the whole silhouette (horns and prop included) inside each panel, with some margin on every side, the bottom too. No letters, no numbers, no speech balloons.
```

### `plutone`

```
Image 1 is a character sheet of Charon, a character of our game: four panels in one row, a full figure and three busts with different expressions. It is the SHEET and the STYLE to copy exactly: the same four panels of the same size, thick slightly irregular black ink outline, short ink hatching for the shadows, flat warm colors, a pale parchment background in each panel, hand-drawn like a European comic. Image 2 is the character sheet of the Blacksmith of the same world: the same cartoon devil kind.

Draw a character sheet of a NEW character of the same world, in the same style and with the same four panels: PLUTUS, the guardian of the fourth circle, the demon of wealth who sits on a heap of gold and wants to be paid. He or she is a customer of the Blacksmith: funny rather than scary. The character: a fat, stingy, vain rich devil: a wide body with short arms, heavy cheeks, a small pointed black beard, a gold monocle on one eye, two short horns each capped with a gold tip, rings on every finger. Skin wine red (#A8473F, shadow #6F2A28). He wears a heavy robe, warm gold (#FFB703, highlight #FFE08A, shadow #C77A06), with a brown fur collar, and hugs a bulging leather money purse against his chest. Prop: he always clutches the money purse with one arm.

Four panels on one sheet, same size, in one row:
1. FULL FIGURE: Plutus sitting on a small heap of gold coins, hugging his purse, seen from three quarters.
2. BUST, ASKING: he stretches one ringed open hand toward the viewer, palm up, while pulling the purse away with the other arm, one eyebrow raised over the monocle, mouth closed and crooked: "I need something from you".
3. BUST, PLEASED: a small satisfied closed-mouth grin, eyes half closed, he bites a gold coin to test it.
4. BUST, PROUD: chin up, eyes closed, a wide toothy smile showing one gold tooth, the purse held up high in one hand.
In the three busts the head, the horns, the clothes and the colors are IDENTICAL: only the expression and the hands change. The busts are framed like Charon's in image 1: head and shoulders, turned three quarters, filling the panel. Keep the whole silhouette (horns and prop included) inside each panel, with some margin on every side, the bottom too. No letters, no numbers, no speech balloons.
```

### `flegias`

```
Image 1 is a character sheet of Charon, a character of our game: four panels in one row, a full figure and three busts with different expressions. It is the SHEET and the STYLE to copy exactly: the same four panels of the same size, thick slightly irregular black ink outline, short ink hatching for the shadows, flat warm colors, a pale parchment background in each panel, hand-drawn like a European comic. Image 2 is the character sheet of the Blacksmith of the same world: the same cartoon devil kind.

Draw a character sheet of a NEW character of the same world, in the same style and with the same four panels: PHLEGYAS, the furious boatman of the marsh of Styx in the fifth circle, who rams everything with his fast boat. He or she is a customer of the Blacksmith: funny rather than scary. The character: a YOUNG, strong, hot-tempered boatman, the opposite of old thin Charon: broad shoulders, a square jaw with a big underbite, thick angry eyebrows, a short flat nose, two short horns that point FORWARD like a ram prow, a red spiky tuft of hair. Skin brick orange (#C96A45, shadow #8A4129). He wears a sleeveless boatman vest, dark sea green (#2F8F78, highlight #5CDBB8, shadow #1E5A4C), a long sea green scarf flying behind his neck and a pair of round leather racing goggles pushed up on his forehead. Prop: he carries a short thick paddle with an iron tip, like a ram.

Four panels on one sheet, same size, in one row:
1. FULL FIGURE: Phlegyas standing on the pointed prow of a small fast black boat that cuts the marsh water, one foot on the prow, seen from three quarters.
2. BUST, ASKING: he leans forward and stretches one big open hand toward the viewer, palm up, impatient, one eyebrow raised, mouth closed and crooked: "I need something from you, quick".
3. BUST, PLEASED: a small satisfied closed-mouth grin, eyes half closed, arms crossed, the goggles pulled down on his eyes.
4. BUST, PROUD: chin up, eyes closed, a wide toothy smile, one fist raised, the paddle planted next to him like a flag.
In the three busts the head, the horns, the clothes and the colors are IDENTICAL: only the expression and the hands change. The busts are framed like Charon's in image 1: head and shoulders, turned three quarters, filling the panel. Keep the whole silhouette (horns and prop included) inside each panel, with some margin on every side, the bottom too. No letters, no numbers, no speech balloons.
```

### `medusa`

```
Image 1 is a character sheet of Charon, a character of our game: four panels in one row, a full figure and three busts with different expressions. It is the SHEET and the STYLE to copy exactly: the same four panels of the same size, thick slightly irregular black ink outline, short ink hatching for the shadows, flat warm colors, a pale parchment background in each panel, hand-drawn like a European comic. Image 2 is the character sheet of the Blacksmith of the same world: the same cartoon devil kind.

Draw a character sheet of a NEW character of the same world, in the same style and with the same four panels: MEDUSA, the gorgon who watches from the towers of the city of Dis in the sixth circle and turns to stone whoever she looks at. He or she is a customer of the Blacksmith: funny rather than scary. The character: an elegant, vain, sharp-tongued old lady devil with living SNAKES instead of hair (seven or eight small funny snakes, each with its own little face), a long neck, a thin pointed chin, and two small horns among the snakes. Because her look turns people to stone she ALWAYS wears a pair of big round smoked dark glasses: her eyes are never seen. Skin pale stone grey (#B9B4C4, shadow #7F7A8E). She wears a high-collared shawl, violet (#C49CFF, highlight #E6D6FF, shadow #7A52B8), closed by a brooch shaped like a small spiral. Prop: she holds a small hand mirror with a violet handle.

Four panels on one sheet, same size, in one row:
1. FULL FIGURE: Medusa standing on a broken stone tomb lid, one hand on her hip, the mirror in the other, seen from three quarters.
2. BUST, ASKING: she stretches one thin open hand toward the viewer, palm up, her head tilted, one eyebrow raised above the dark glasses, mouth closed and crooked, the snakes all looking at the viewer: "I need something from you".
3. BUST, PLEASED: a small satisfied closed-mouth smile, she looks at herself in the hand mirror, the snakes relaxed and smiling.
4. BUST, PROUD: chin up, a wide toothy smile, one hand lifting the dark glasses just a little above her nose WITHOUT showing her eyes, the snakes standing straight up and proud.
In the three busts the head, the horns, the clothes and the colors are IDENTICAL: only the expression and the hands change. The busts are framed like Charon's in image 1: head and shoulders, turned three quarters, filling the panel. Keep the whole silhouette (horns and prop included) inside each panel, with some margin on every side, the bottom too. No letters, no numbers, no speech balloons.
```

### `minotauro`

```
Image 1 is a character sheet of Charon, a character of our game: four panels in one row, a full figure and three busts with different expressions. It is the SHEET and the STYLE to copy exactly: the same four panels of the same size, thick slightly irregular black ink outline, short ink hatching for the shadows, flat warm colors, a pale parchment background in each panel, hand-drawn like a European comic. Image 2 is the character sheet of the Blacksmith of the same world: the same cartoon devil kind.

Draw a character sheet of a NEW character of the same world, in the same style and with the same four panels: THE MINOTAUR, the bull-headed guardian of the seventh circle, who charges in a straight line and crashes into walls. He or she is a customer of the Blacksmith: funny rather than scary. The character: a huge, strong, not very clever bull-man: a massive bull head with a wide wet nose, a big brass nose ring, small angry eyes, two thick horns that point forward, one horn chipped, and a round BUMP on his forehead covered by a crossed plaster (he keeps hitting walls). Very broad shoulders, small waist. Fur dark red-brown (#7A3B2E, shadow #4A1F19, muzzle #C99A7A). He wears a leather wrestler harness with a big round buckle, hot orange (#F26419, highlight #FFB703, shadow #A63A0B), and orange wrist wraps. Prop: he carries a broken piece of stone wall under one arm, like a trophy.

Four panels on one sheet, same size, in one row:
1. FULL FIGURE: the Minotaur standing on the edge of a rocky landslide, head lowered, pawing the ground, ready to charge, seen from three quarters.
2. BUST, ASKING: he stretches one enormous open hand toward the viewer, palm up, clumsy, one eyebrow raised, nostrils puffing two small clouds, mouth closed and crooked: "I need something from you".
3. BUST, PLEASED: a small satisfied closed-mouth grin, eyes half closed, he scratches the bump on his forehead with one finger.
4. BUST, PROUD: chin up, eyes closed, a wide toothy smile, flexing one arm, the piece of wall held up in the other hand like a cup.
In the three busts the head, the horns, the clothes and the colors are IDENTICAL: only the expression and the hands change. The busts are framed like Charon's in image 1: head and shoulders, turned three quarters, filling the panel. Keep the whole silhouette (horns and prop included) inside each panel, with some margin on every side, the bottom too. No letters, no numbers, no speech balloons.
```

### `malacoda`

```
Image 1 is a character sheet of Charon, a character of our game: four panels in one row, a full figure and three busts with different expressions. It is the SHEET and the STYLE to copy exactly: the same four panels of the same size, thick slightly irregular black ink outline, short ink hatching for the shadows, flat warm colors, a pale parchment background in each panel, hand-drawn like a European comic. Image 2 is the character sheet of the Blacksmith of the same world: the same cartoon devil kind.

Draw a character sheet of a NEW character of the same world, in the same style and with the same four panels: MALACODA, the chief of the Malebranche devils who guard the boiling pitch in the eighth circle; a smooth liar: half of what he says is false. He or she is a customer of the Blacksmith: funny rather than scary. The character: a lean, sly, charming trickster devil with a sharp foxy face, a long thin pointed nose, a thin curled black moustache, narrow clever eyes, two thin horns that curl outward, two small bat wings on his back and a long forked TAIL that is always raised behind him in the shape of a question mark. Skin dark crimson (#8E2F3A, shadow #5A1B24), hands and tail tip black as if dipped in pitch. He wears a short cape of black raven feathers over a waistcoat, pale steel blue (#9EC4E0, highlight #D6E9F5, shadow #5F86A3). Prop: he carries a long pole that ends in an iron HOOK.

Four panels on one sheet, same size, in one row:
1. FULL FIGURE: Malacoda standing on a rock in the middle of a pool of black pitch, leaning on his hooked pole, a small bow to the viewer, seen from three quarters.
2. BUST, ASKING: he stretches one open hand toward the viewer, palm up, with a too-friendly closed-mouth crooked smile and one eyebrow raised, while the other hand is hidden behind his back with two fingers crossed, visible to us: "I need something from you".
3. BUST, PLEASED: a small satisfied closed-mouth grin, eyes half closed, he twirls the tip of his moustache with two fingers.
4. BUST, PROUD: chin up, eyes closed, a wide toothy smile, one hand on his chest, the hooked pole planted next to him like a flag.
In the three busts the head, the horns, the clothes and the colors are IDENTICAL: only the expression and the hands change. The busts are framed like Charon's in image 1: head and shoulders, turned three quarters, filling the panel. Keep the whole silhouette (horns and prop included) inside each panel, with some margin on every side, the bottom too. No letters, no numbers, no speech balloons.
```

## Criteri di accettazione

- [ ] stesso foglio di Caronte: quattro riquadri in fila, figura intera e tre busti (chiede, contento, fiero)
- [ ] stessa mano (china spessa, tratteggio, colori piatti e caldi, pergamena)
- [ ] ogni custode si riconosce in piccolo dalla sagoma e dal colore della famiglia, e non si confonde con gli altri sette
- [ ] nei tre busti il personaggio è lo stesso, cambia solo l'espressione
- [ ] buffi, non paurosi (Medusa non mostra mai gli occhi); nessuna scritta
- [ ] tutta la sagoma dentro il riquadro, con margine anche in basso (in WB-086 il mantello era tagliato sotto)

---

## Decisione

Approvata: Sergio, 23 nov 14:55 («Mi piace Caronte, procedi»), sulla variante 2 di WB-086. I sette custodi sono disegni nuovi, non sostituiscono niente. Sergio sceglie le varianti sulle immagini.

## Consegna di Codex

## Resoconto di Claude
