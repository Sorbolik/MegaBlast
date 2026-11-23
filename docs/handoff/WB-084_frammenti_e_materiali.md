# WB-084 · Frammenti di famiglia e materiali delle commesse

- **Stato:** APPROVATA (Claude, 23 nov: sono icone nuove, non sostituiscono niente; Sergio sceglie sulle immagini)
- **Data:** 2026-11-23
- **Ramo della scheda:** `claude/project-thread-ft5von` (Codex la esegue da qui: `git fetch origin claude/project-thread-ft5von`, non serve che sia su `main`) · **Ramo delle immagini:** `design/WB-084`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-084` senza chiedere conferma (il repository è privato).

## Obiettivo

Le Commesse del Fabbro ([docs/commesse.md](../commesse.md)) portano due cose nuove da tenere in mano:

- **i frammenti di famiglia**, cinque (Fabbro, Corvo, Fornace, Leviatano, Vuoto): pagano i pezzi e i livelli della loro famiglia, quindi stanno accanto ai prezzi come le monete;
- **i materiali**, undici: uno per mappa online più la Scoria, che vale per tutti. Stanno sui cartellini delle commesse, sullo scaffale della bottega e sullo scontrino del podio.

Il gioco le usa da 24 a 56 px, accanto a Scaglia e Ossidiana (WB-072): stessa mano, stesso spessore.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-072/scavate_2.png` | Scaglia e buono del Fabbro di oggi: misura, spessore e rilievo da copiare |
| R2 | `art/WB-072/riferimenti/R3_stile.png` | un pulsante della home: lo stile della china |
| R3 | `art/WB-072/monete_2.png` | l'Ossidiana di oggi (a sinistra): come sono fatte le facce di una pietra |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine: il primo è "image 1", il secondo "image 2" e così via.

| Nome file | Cosa c'è | Riferimenti | Misura | Varianti |
|---|---|---|---|---|
| `frammenti` | i cinque frammenti di famiglia in fila | R1, R2, R3 | 1536×1024 | 3 |
| `materiali_a` | Scoria, Piuma, Vento, Grandine, Scheggia, Stige | R1, R2 | 1536×1024 | 3 |
| `materiali_b` | Tomba, Sangue, Sabbia, Pece, Ghiaccio | R1, R2 | 1536×1024 | 3 |

Le varianti si chiamano `frammenti_1.png`, `frammenti_2.png`, `frammenti_3.png` e così via, in `art/WB-084/`. Per ogni foglio Codex scrive un `.txt` con lo stesso nome: cosa ha fatto e cosa non è riuscito a rispettare.

### `frammenti`

```
Image 1 shows two currency icons of our game (a gold eight-sided coin and a round dark iron token): copy their visual size, their thickness and their relief. Image 2 is a button of the same game and is the STYLE to copy exactly: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, soft hand-drawn slightly crooked shapes, like a cartoon comic. Image 3 shows, on the left, a faceted dark gem: this is how we draw the flat faces of a stone.

Draw FIVE separate icons in one row, well apart, all the same visual size, on plain green (#00FF00). Each one is a FRAGMENT: a broken piece of forged armor plate, a chunky irregular shard with three or four flat faces and one clearly broken, jagged edge, thick like the coins of image 1. All five have the SAME kind of silhouette (a shard, a little taller than wide) but each one is broken differently, and each has its own color and one small symbol ENGRAVED into its biggest face (a hollow sunk into the metal, darker along its upper left edge, lighter along its lower right edge):
1. SMITH: warm gold metal (#FFB703, highlight #FFE08A, shadow #C77A06). Engraved symbol: a small hammer.
2. RAVEN: pale steel blue metal (#9EC4E0, highlight #D6E9F5, shadow #5F86A3). Engraved symbol: a single feather.
3. FURNACE: hot orange metal (#F26419, highlight #FFB703, shadow #A63A0B). Engraved symbol: a small flame.
4. LEVIATHAN: sea green metal (#5CDBB8, highlight #B8F2E2, shadow #2F8F78). Engraved symbol: a fish scale shaped like a drop, or a small wave.
5. VOID: violet metal (#C49CFF, highlight #E6D6FF, shadow #7A52B8). Engraved symbol: a small spiral.
Each icon must read at 24 pixels: one bold full silhouette, no thin details, the symbol large and simple. No letters, no numbers, no shadow on the ground, no glow outside the ink, no sparkles.
```

### `materiali_a`

```
Image 1 shows two currency icons of our game (a gold eight-sided coin and a round dark iron token): copy their visual size, their thickness and their relief. Image 2 is a button of the same game and is the STYLE to copy exactly: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, soft hand-drawn slightly crooked shapes, like a cartoon comic.

Draw SIX separate icons in two rows of three, well apart, all the same visual size, on plain green (#00FF00). They are crafting materials picked up in the circles of a cartoon hell; each is one chunky object with a bold silhouette, very different from the others in shape AND in color:
1. SLAG: a lumpy nugget of forge slag, dark grey iron (#3A3340, highlight #5A5263) with two glowing orange cracks (#F26419, #FFB703). It is the "wild card" material: make it look the most precious of the six.
2. FEATHER OF LIMBO: one soft pale feather, a little curled, ash white (#E8E4DA) with a grey-lilac shadow (#A9A3B8).
3. BOTTLED WIND: a small round glass bottle with a cork, and inside it a white-pink swirl of wind (#FFD6E8, #FF8FB8); the glass is pale blue (#CFE8F5).
4. HAILSTONE: one big rough ball of dirty ice, off-white and pale blue (#E6F1F5, shadow #8FB3C2), with two flat facets.
5. BOULDER SHARD: a sharp splinter of rock with a vein of gold in it, brown-grey stone (#8A7A66, shadow #54483B), gold vein #FFB703.
6. WATER OF THE STYX: one fat drop of murky swamp water, dark green (#3F6B4A, highlight #7FB38A), with a single bubble inside.
Each icon must read at 24 pixels: one bold full silhouette, no thin details. No letters, no numbers, no shadow on the ground, no glow outside the ink, no sparkles.
```

### `materiali_b`

```
Image 1 shows two currency icons of our game (a gold eight-sided coin and a round dark iron token): copy their visual size, their thickness and their relief. Image 2 is a button of the same game and is the STYLE to copy exactly: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, soft hand-drawn slightly crooked shapes, like a cartoon comic.

Draw FIVE separate icons in one row, well apart, all the same visual size, on plain green (#00FF00). They are crafting materials picked up in the circles of a cartoon hell; each is one chunky object with a bold silhouette, very different from the others in shape AND in color:
1. TOMB DUST: a small heap of grey-violet dust (#8E86A3, shadow #5B546E) with a tiny cracked piece of gravestone sticking out of it.
2. BOILING BLOOD: one fat drop of bright red liquid (#D62839, highlight #FF7A85, shadow #8C1420) with two round bubbles popping on top.
3. BURNING SAND: a small cone-shaped heap of sand, yellow-orange (#F2B84B, shadow #C9822A), with three glowing embers (#F26419) in it.
4. PITCH: a thick black sticky blob dripping down (#1E1A22, highlight #4A3F57), glossy, with one long drip.
5. ICE OF COCYTUS: a sharp crystal of deep blue ice (#4FA8E0, highlight #CFEFFF, shadow #2A5F9E), with three or four flat faces.
Each icon must read at 24 pixels: one bold full silhouette, no thin details. No letters, no numbers, no shadow on the ground, no glow outside the ink, no sparkles.
```

## Criteri di accettazione

- [ ] contorno nero spesso e un po' storto, colori piatti, nessuna scritta, icone ben staccate sul verde
- [ ] i cinque frammenti sono la stessa cosa (una scheggia di piastra) in cinque colori, e si distinguono anche in bianco e nero dal simbolo inciso
- [ ] gli undici materiali si distinguono a 24 px l'uno dall'altro e dalle monete (Scaglia, Ossidiana, buono)
- [ ] stessa misura visiva e stesso spessore delle monete di R1
- [ ] nessun bagliore fuori dalla china, nessuna ombra a terra

---

## Decisione

Approvata da Claude il 23 nov (icone nuove, niente da sostituire). Sergio sceglie le varianti sulle immagini.

## Consegna di Codex

## Resoconto di Claude
