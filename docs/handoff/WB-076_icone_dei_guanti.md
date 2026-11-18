# WB-076 · Le icone dei guanti

- **Stato:** PROPOSTA (bozza: aspetta il sì di Sergio)
- **Data:** 2026-11-18
- **Ramo della scheda:** `claude/project-thread-rc20kg` (eseguila da questo ramo: `git fetch origin claude/project-thread-rc20kg`) · **Ramo delle immagini:** `design/WB-076`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-076` senza chiedere conferma (il repository è privato).

## Obiettivo

I guanti di WB-070 sono montati addosso, ma mancano le loro icone per zaino e armeria: in WB-070
erano un foglio solo con undici riferimenti, e il generatore ne accetta cinque. Qui ogni icona è
una richiesta a sé con due riferimenti: l'icona degli stivali della stessa famiglia e forma (lo
stile, la misura, i materiali già disegnati come icona) e il foglio dei pugni con quei guanti.
La sagoma dello slot vuoto c'è già (`art/WB-070/sagoma_vuota_guanti.png`).

## Riferimenti da allegare

Ogni richiesta ha i suoi due, scritti nella tabella e sopra il prompt:

| Codice | File | Cos'è |
|---|---|---|
| Image 1 | `art/WB-076/riferimenti/R_<famiglia>_<forma>_icona.png` | l'icona degli stivali di quella famiglia e forma (WB-043): stile e misura |
| Image 2 | `art/WB-070/<famiglia>_pugni_<base o forgiata>.png` | le due braccia a pugno chiuso con quei guanti (WB-070): materiali, colori, dettagli |

## Immagini da generare

Dieci richieste separate, una per icona. Ogni prompt è completo e va usato così com'è. I file
vanno in `art/WB-076/` col nome della tabella più `_1` e `_2`.

| Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|
| `ic_fabbro_guanti_base.png` | `art/WB-076/riferimenti/R_fabbro_base_icona.png`, `art/WB-070/fabbro_pugni_base.png` | 1024×1024 | 2 |
| `ic_fabbro_guanti_forgiato.png` | `art/WB-076/riferimenti/R_fabbro_forgiato_icona.png`, `art/WB-070/fabbro_pugni_forgiata.png` | 1024×1024 | 2 |
| `ic_corvo_guanti_base.png` | `art/WB-076/riferimenti/R_corvo_base_icona.png`, `art/WB-070/corvo_pugni_base.png` | 1024×1024 | 2 |
| `ic_corvo_guanti_forgiato.png` | `art/WB-076/riferimenti/R_corvo_forgiato_icona.png`, `art/WB-070/corvo_pugni_forgiata.png` | 1024×1024 | 2 |
| `ic_fornace_guanti_base.png` | `art/WB-076/riferimenti/R_fornace_base_icona.png`, `art/WB-070/fornace_pugni_base.png` | 1024×1024 | 2 |
| `ic_fornace_guanti_forgiato.png` | `art/WB-076/riferimenti/R_fornace_forgiato_icona.png`, `art/WB-070/fornace_pugni_forgiata.png` | 1024×1024 | 2 |
| `ic_leviatano_guanti_base.png` | `art/WB-076/riferimenti/R_leviatano_base_icona.png`, `art/WB-070/leviatano_pugni_base.png` | 1024×1024 | 2 |
| `ic_leviatano_guanti_forgiato.png` | `art/WB-076/riferimenti/R_leviatano_forgiato_icona.png`, `art/WB-070/leviatano_pugni_forgiata.png` | 1024×1024 | 2 |
| `ic_vuoto_guanti_base.png` | `art/WB-076/riferimenti/R_vuoto_base_icona.png`, `art/WB-070/vuoto_pugni_base.png` | 1024×1024 | 2 |
| `ic_vuoto_guanti_forgiato.png` | `art/WB-076/riferimenti/R_vuoto_forgiato_icona.png`, `art/WB-070/vuoto_pugni_forgiata.png` | 1024×1024 | 2 |

### `ic_fabbro_guanti_base`

Allegati, in quest'ordine: `art/WB-076/riferimenti/R_fabbro_base_icona.png`, `art/WB-070/fabbro_pugni_base.png`.

```
Image 1 is an inventory icon of our game: the boots of the Smith armour set, BASIC form, drawn alone, big, slightly tilted, flat colors with one flat shadow tone, thick pure black outline. Image 2 is a sheet with the two arms of our character with the fists closed, wearing the BASIC Smith gloves (brown leather with a lighter leather cuff and brass studs).

Draw ONE inventory icon in exactly the style of image 1: the PAIR OF GLOVES of image 2 alone, without arms and without hands inside, as two empty gloves side by side, slightly overlapping, fingers up and slightly curled, cuffs down, slightly tilted like the boots of image 1. The gloves have exactly the materials, colors and details of the gloves in image 2 (cuff, rings, studs, plates, scales, fins, eye: whatever image 2 shows, nothing more). Same outline thickness and same amount of detail as image 1.

Centered, filling about 80% of a square image, on a flat pure magenta #FF00FF background. No text, no frame, no ground shadow, no glow, no gradient, no red skin.
```

### `ic_fabbro_guanti_forgiato`

Allegati, in quest'ordine: `art/WB-076/riferimenti/R_fabbro_forgiato_icona.png`, `art/WB-070/fabbro_pugni_forgiata.png`.

```
Image 1 is an inventory icon of our game: the boots of the Smith armour set, FORGED form, drawn alone, big, slightly tilted, flat colors with one flat shadow tone, thick pure black outline. Image 2 is a sheet with the two arms of our character with the fists closed, wearing the FORGED Smith gloves (brown leather with a lighter leather cuff and brass studs).

Draw ONE inventory icon in exactly the style of image 1: the PAIR OF GLOVES of image 2 alone, without arms and without hands inside, as two empty gloves side by side, slightly overlapping, fingers up and slightly curled, cuffs down, slightly tilted like the boots of image 1. The gloves have exactly the materials, colors and details of the gloves in image 2 (cuff, rings, studs, plates, scales, fins, eye: whatever image 2 shows, nothing more). Same outline thickness and same amount of detail as image 1.

Centered, filling about 80% of a square image, on a flat pure magenta #FF00FF background. No text, no frame, no ground shadow, no glow, no gradient, no red skin.
```

### `ic_corvo_guanti_base`

Allegati, in quest'ordine: `art/WB-076/riferimenti/R_corvo_base_icona.png`, `art/WB-070/corvo_pugni_base.png`.

```
Image 1 is an inventory icon of our game: the boots of the Crow armour set, BASIC form, drawn alone, big, slightly tilted, flat colors with one flat shadow tone, thick pure black outline. Image 2 is a sheet with the two arms of our character with the fists closed, wearing the BASIC Crow gloves (dark blue-grey cloth with a cyan ring at the wrist).

Draw ONE inventory icon in exactly the style of image 1: the PAIR OF GLOVES of image 2 alone, without arms and without hands inside, as two empty gloves side by side, slightly overlapping, fingers up and slightly curled, cuffs down, slightly tilted like the boots of image 1. The gloves have exactly the materials, colors and details of the gloves in image 2 (cuff, rings, studs, plates, scales, fins, eye: whatever image 2 shows, nothing more). Same outline thickness and same amount of detail as image 1.

Centered, filling about 80% of a square image, on a flat pure magenta #FF00FF background. No text, no frame, no ground shadow, no glow, no gradient, no red skin.
```

### `ic_corvo_guanti_forgiato`

Allegati, in quest'ordine: `art/WB-076/riferimenti/R_corvo_forgiato_icona.png`, `art/WB-070/corvo_pugni_forgiata.png`.

```
Image 1 is an inventory icon of our game: the boots of the Crow armour set, FORGED form, drawn alone, big, slightly tilted, flat colors with one flat shadow tone, thick pure black outline. Image 2 is a sheet with the two arms of our character with the fists closed, wearing the FORGED Crow gloves (dark blue-grey cloth with a cyan ring at the wrist).

Draw ONE inventory icon in exactly the style of image 1: the PAIR OF GLOVES of image 2 alone, without arms and without hands inside, as two empty gloves side by side, slightly overlapping, fingers up and slightly curled, cuffs down, slightly tilted like the boots of image 1. The gloves have exactly the materials, colors and details of the gloves in image 2 (cuff, rings, studs, plates, scales, fins, eye: whatever image 2 shows, nothing more). Same outline thickness and same amount of detail as image 1.

Centered, filling about 80% of a square image, on a flat pure magenta #FF00FF background. No text, no frame, no ground shadow, no glow, no gradient, no red skin.
```

### `ic_fornace_guanti_base`

Allegati, in quest'ordine: `art/WB-076/riferimenti/R_fornace_base_icona.png`, `art/WB-070/fornace_pugni_base.png`.

```
Image 1 is an inventory icon of our game: the boots of the Furnace armour set, BASIC form, drawn alone, big, slightly tilted, flat colors with one flat shadow tone, thick pure black outline. Image 2 is a sheet with the two arms of our character with the fists closed, wearing the BASIC Furnace gloves (grey iron plates with a cyan ring at the wrist).

Draw ONE inventory icon in exactly the style of image 1: the PAIR OF GLOVES of image 2 alone, without arms and without hands inside, as two empty gloves side by side, slightly overlapping, fingers up and slightly curled, cuffs down, slightly tilted like the boots of image 1. The gloves have exactly the materials, colors and details of the gloves in image 2 (cuff, rings, studs, plates, scales, fins, eye: whatever image 2 shows, nothing more). Same outline thickness and same amount of detail as image 1.

Centered, filling about 80% of a square image, on a flat pure magenta #FF00FF background. No text, no frame, no ground shadow, no glow, no gradient, no red skin.
```

### `ic_fornace_guanti_forgiato`

Allegati, in quest'ordine: `art/WB-076/riferimenti/R_fornace_forgiato_icona.png`, `art/WB-070/fornace_pugni_forgiata.png`.

```
Image 1 is an inventory icon of our game: the boots of the Furnace armour set, FORGED form, drawn alone, big, slightly tilted, flat colors with one flat shadow tone, thick pure black outline. Image 2 is a sheet with the two arms of our character with the fists closed, wearing the FORGED Furnace gloves (grey iron plates with a cyan ring at the wrist).

Draw ONE inventory icon in exactly the style of image 1: the PAIR OF GLOVES of image 2 alone, without arms and without hands inside, as two empty gloves side by side, slightly overlapping, fingers up and slightly curled, cuffs down, slightly tilted like the boots of image 1. The gloves have exactly the materials, colors and details of the gloves in image 2 (cuff, rings, studs, plates, scales, fins, eye: whatever image 2 shows, nothing more). Same outline thickness and same amount of detail as image 1.

Centered, filling about 80% of a square image, on a flat pure magenta #FF00FF background. No text, no frame, no ground shadow, no glow, no gradient, no red skin.
```

### `ic_leviatano_guanti_base`

Allegati, in quest'ordine: `art/WB-076/riferimenti/R_leviatano_base_icona.png`, `art/WB-070/leviatano_pugni_base.png`.

```
Image 1 is an inventory icon of our game: the boots of the Leviathan armour set, BASIC form, drawn alone, big, slightly tilted, flat colors with one flat shadow tone, thick pure black outline. Image 2 is a sheet with the two arms of our character with the fists closed, wearing the BASIC Leviathan gloves (teal sea-green scales with a cyan ring at the wrist).

Draw ONE inventory icon in exactly the style of image 1: the PAIR OF GLOVES of image 2 alone, without arms and without hands inside, as two empty gloves side by side, slightly overlapping, fingers up and slightly curled, cuffs down, slightly tilted like the boots of image 1. The gloves have exactly the materials, colors and details of the gloves in image 2 (cuff, rings, studs, plates, scales, fins, eye: whatever image 2 shows, nothing more). Same outline thickness and same amount of detail as image 1.

Centered, filling about 80% of a square image, on a flat pure magenta #FF00FF background. No text, no frame, no ground shadow, no glow, no gradient, no red skin.
```

### `ic_leviatano_guanti_forgiato`

Allegati, in quest'ordine: `art/WB-076/riferimenti/R_leviatano_forgiato_icona.png`, `art/WB-070/leviatano_pugni_forgiata.png`.

```
Image 1 is an inventory icon of our game: the boots of the Leviathan armour set, FORGED form, drawn alone, big, slightly tilted, flat colors with one flat shadow tone, thick pure black outline. Image 2 is a sheet with the two arms of our character with the fists closed, wearing the FORGED Leviathan gloves (teal sea-green scales with a cyan ring at the wrist).

Draw ONE inventory icon in exactly the style of image 1: the PAIR OF GLOVES of image 2 alone, without arms and without hands inside, as two empty gloves side by side, slightly overlapping, fingers up and slightly curled, cuffs down, slightly tilted like the boots of image 1. The gloves have exactly the materials, colors and details of the gloves in image 2 (cuff, rings, studs, plates, scales, fins, eye: whatever image 2 shows, nothing more). Same outline thickness and same amount of detail as image 1.

Centered, filling about 80% of a square image, on a flat pure magenta #FF00FF background. No text, no frame, no ground shadow, no glow, no gradient, no red skin.
```

### `ic_vuoto_guanti_base`

Allegati, in quest'ordine: `art/WB-076/riferimenti/R_vuoto_base_icona.png`, `art/WB-070/vuoto_pugni_base.png`.

```
Image 1 is an inventory icon of our game: the boots of the Void armour set, BASIC form, drawn alone, big, slightly tilted, flat colors with one flat shadow tone, thick pure black outline. Image 2 is a sheet with the two arms of our character with the fists closed, wearing the BASIC Void gloves (dark violet wrapped bandages with a cyan ring at the wrist).

Draw ONE inventory icon in exactly the style of image 1: the PAIR OF GLOVES of image 2 alone, without arms and without hands inside, as two empty gloves side by side, slightly overlapping, fingers up and slightly curled, cuffs down, slightly tilted like the boots of image 1. The gloves have exactly the materials, colors and details of the gloves in image 2 (cuff, rings, studs, plates, scales, fins, eye: whatever image 2 shows, nothing more). Same outline thickness and same amount of detail as image 1.

Centered, filling about 80% of a square image, on a flat pure magenta #FF00FF background. No text, no frame, no ground shadow, no glow, no gradient, no red skin.
```

### `ic_vuoto_guanti_forgiato`

Allegati, in quest'ordine: `art/WB-076/riferimenti/R_vuoto_forgiato_icona.png`, `art/WB-070/vuoto_pugni_forgiata.png`.

```
Image 1 is an inventory icon of our game: the boots of the Void armour set, FORGED form, drawn alone, big, slightly tilted, flat colors with one flat shadow tone, thick pure black outline. Image 2 is a sheet with the two arms of our character with the fists closed, wearing the FORGED Void gloves (dark violet wrapped bandages with a cyan ring at the wrist).

Draw ONE inventory icon in exactly the style of image 1: the PAIR OF GLOVES of image 2 alone, without arms and without hands inside, as two empty gloves side by side, slightly overlapping, fingers up and slightly curled, cuffs down, slightly tilted like the boots of image 1. The gloves have exactly the materials, colors and details of the gloves in image 2 (cuff, rings, studs, plates, scales, fins, eye: whatever image 2 shows, nothing more). Same outline thickness and same amount of detail as image 1.

Centered, filling about 80% of a square image, on a flat pure magenta #FF00FF background. No text, no frame, no ground shadow, no glow, no gradient, no red skin.
```

## Criteri di accettazione

- [ ] una coppia di guanti sola, senza braccia né pelle rossa, dita in su e polsini in giù
- [ ] stessi materiali, colori e dettagli dei guanti del foglio dei pugni (base e forgiata si distinguono)
- [ ] stile dell'icona degli stivali: colori piatti, contorno nero puro e spesso, stessa grandezza nel quadrato
- [ ] fondo magenta piatto, nessuna scritta, cornice, ombra a terra o bagliore

---

## Decisione

(aspetta Sergio)

## Consegna di Codex

## Resoconto di Claude
