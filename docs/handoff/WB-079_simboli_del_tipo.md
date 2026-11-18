# WB-079 · I simboli del tipo, rifatti

- **Stato:** APPROVATA (Sergio, 18 nov 18:49: «facciamoli rifare tutti, anche quello dell'elmo sembra uno stop»)
- **Data:** 2026-11-18
- **Ramo della scheda:** `claude/project-thread-rc20kg` (eseguila da questo ramo: `git fetch origin claude/project-thread-rc20kg`) · **Ramo delle immagini:** `design/WB-079`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-079` senza chiedere conferma (il repository è privato).

## Obiettivo

Le cornici, la linguetta e la fascia di WB-078 vanno bene; i cinque simboli del tipo no: sono troppo
generici (l'elmo sembra un cartello di stop, la corazza una maglietta, il mantello una gonna). Si
rifanno tutti e cinque partendo dalle icone dei **nostri** pezzi, così si riconoscono subito: l'elmo
con le due corna, la corazza con le spalline, il mantello che vola. Stessa misura, stesso colore
sabbia e stesso contorno dei simboli di WB-078, perché vanno nella stessa linguetta.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R_elmo_nostro | `art/WB-079/riferimenti/R_elmo_nostro.png` | un nostro elmo (Fornace) |
| R_corazza_nostra | `art/WB-079/riferimenti/R_corazza_nostra.png` | una nostra corazza (Fabbro) |
| R_mantello_nostro | `art/WB-079/riferimenti/R_mantello_nostro.png` | un nostro mantello (Corvo) |
| R_stivali_nostri | `art/WB-079/riferimenti/R_stivali_nostri.png` | i nostri stivali (Fabbro) |
| R_guanti_nostri | `art/WB-079/riferimenti/R_guanti_nostri.png` | le braccia a pugno coi guanti del Fabbro (WB-070) |
| R_simboli_da_rifare | `art/WB-079/riferimenti/R_simboli_da_rifare.png` | la griglia con i simboli di WB-078, da sostituire |

## Immagini da generare

Cinque richieste separate. Ogni prompt è completo e va usato così com'è. I file vanno in
`art/WB-079/` col nome della tabella più `_1` e `_2`.

| Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|
| `tipo_elmo.png` | `art/WB-079/riferimenti/R_elmo_nostro.png`, `art/WB-079/riferimenti/R_simboli_da_rifare.png` | 1024×1024 | 2 |
| `tipo_corazza.png` | `art/WB-079/riferimenti/R_corazza_nostra.png`, `art/WB-079/riferimenti/R_simboli_da_rifare.png` | 1024×1024 | 2 |
| `tipo_mantello.png` | `art/WB-079/riferimenti/R_mantello_nostro.png`, `art/WB-079/riferimenti/R_simboli_da_rifare.png` | 1024×1024 | 2 |
| `tipo_stivali.png` | `art/WB-079/riferimenti/R_stivali_nostri.png`, `art/WB-079/riferimenti/R_simboli_da_rifare.png` | 1024×1024 | 2 |
| `tipo_guanti.png` | `art/WB-079/riferimenti/R_guanti_nostri.png`, `art/WB-079/riferimenti/R_simboli_da_rifare.png` | 1024×1024 | 2 |

### `tipo_elmo`

Allegati, in quest'ordine: `art/WB-079/riferimenti/R_elmo_nostro.png`, `art/WB-079/riferimenti/R_simboli_da_rifare.png`.

```
Image 1 is the HELMET of our game (image 1, one of our real helmets). Image 2 shows our inventory grid with the category symbols in the top-left tabs: those symbols are TOO GENERIC and must be replaced (the helmet looks like a stop sign, the armour like a T-shirt, the cape like a skirt). Keep only their size, their sand color and their thick outline.

Draw ONE tiny category symbol for a comic-style mobile game interface: a game HELMET seen in three-quarter view (turned slightly to the right), so it reads as a 3D object and not as a flat sign: a rounded dome, a clear visor brow jutting forward over a dark eye opening, a cheek guard going down the side, and TWO SHORT CURVED DEVIL HORNS on top, one on each side. The two horns are what makes it ours and unmistakable.

It must read at 20 pixels inside a small dark tab: one bold silhouette with at most two or three big inner shapes, no small details. Fill: one flat light sand color (#EAD9B0) with one flat darker sand shadow tone (#C9AE7C) on one side. Thick pure black outline of constant thickness, clean and smooth, the same weight as the outline of image 1.

No text, no frame, no background shape, no gradient, no glow, no other objects. At most four colors. Centered, filling about 80% of the image, on a flat pure magenta #FF00FF background.
```

### `tipo_corazza`

Allegati, in quest'ordine: `art/WB-079/riferimenti/R_corazza_nostra.png`, `art/WB-079/riferimenti/R_simboli_da_rifare.png`.

```
Image 1 is the CHEST ARMOUR of our game (image 1, one of our real armours). Image 2 shows our inventory grid with the category symbols in the top-left tabs: those symbols are TOO GENERIC and must be replaced (the helmet looks like a stop sign, the armour like a T-shirt, the cape like a skirt). Keep only their size, their sand color and their thick outline.

Draw ONE tiny category symbol for a comic-style mobile game interface: a game BREASTPLATE seen from the front, clearly made of metal and not of cloth: a hard rounded chest plate with a vertical ridge in the middle, TWO BIG ROUND SHOULDER PADS (pauldrons) standing out wider than the chest on both sides, and a belt band across the bottom. No sleeves: it must never look like a T-shirt.

It must read at 20 pixels inside a small dark tab: one bold silhouette with at most two or three big inner shapes, no small details. Fill: one flat light sand color (#EAD9B0) with one flat darker sand shadow tone (#C9AE7C) on one side. Thick pure black outline of constant thickness, clean and smooth, the same weight as the outline of image 1.

No text, no frame, no background shape, no gradient, no glow, no other objects. At most four colors. Centered, filling about 80% of the image, on a flat pure magenta #FF00FF background.
```

### `tipo_mantello`

Allegati, in quest'ordine: `art/WB-079/riferimenti/R_mantello_nostro.png`, `art/WB-079/riferimenti/R_simboli_da_rifare.png`.

```
Image 1 is the CAPE of our game (image 1, one of our real capes). Image 2 shows our inventory grid with the category symbols in the top-left tabs: those symbols are TOO GENERIC and must be replaced (the helmet looks like a stop sign, the armour like a T-shirt, the cape like a skirt). Keep only their size, their sand color and their thick outline.

Draw ONE tiny category symbol for a comic-style mobile game interface: a game CAPE seen in three-quarter view, blowing to one side in the wind: a round clasp at the collar on top, the cape falling from it and curling back so that a part of the darker inside lining shows, a hem with two or three soft points. It must clearly be a cloak hanging from the shoulders and flowing, never a skirt or a bell.

It must read at 20 pixels inside a small dark tab: one bold silhouette with at most two or three big inner shapes, no small details. Fill: one flat light sand color (#EAD9B0) with one flat darker sand shadow tone (#C9AE7C) on one side. Thick pure black outline of constant thickness, clean and smooth, the same weight as the outline of image 1.

No text, no frame, no background shape, no gradient, no glow, no other objects. At most four colors. Centered, filling about 80% of the image, on a flat pure magenta #FF00FF background.
```

### `tipo_stivali`

Allegati, in quest'ordine: `art/WB-079/riferimenti/R_stivali_nostri.png`, `art/WB-079/riferimenti/R_simboli_da_rifare.png`.

```
Image 1 is the BOOTS of our game (image 1, our real boots). Image 2 shows our inventory grid with the category symbols in the top-left tabs: those symbols are TOO GENERIC and must be replaced (the helmet looks like a stop sign, the armour like a T-shirt, the cape like a skirt). Keep only their size, their sand color and their thick outline.

Draw ONE tiny category symbol for a comic-style mobile game interface: ONE armoured game BOOT seen from the side, toe pointing right: a sturdy boot with a thick sole, a metal toe cap, and a metal shin plate on the front of the leg part with a folded top cuff. Bold and chunky.

It must read at 20 pixels inside a small dark tab: one bold silhouette with at most two or three big inner shapes, no small details. Fill: one flat light sand color (#EAD9B0) with one flat darker sand shadow tone (#C9AE7C) on one side. Thick pure black outline of constant thickness, clean and smooth, the same weight as the outline of image 1.

No text, no frame, no background shape, no gradient, no glow, no other objects. At most four colors. Centered, filling about 80% of the image, on a flat pure magenta #FF00FF background.
```

### `tipo_guanti`

Allegati, in quest'ordine: `art/WB-079/riferimenti/R_guanti_nostri.png`, `art/WB-079/riferimenti/R_simboli_da_rifare.png`.

```
Image 1 is the GLOVES of our game (image 1: the arms of our character with fists, wearing our real gloves). Image 2 shows our inventory grid with the category symbols in the top-left tabs: those symbols are TOO GENERIC and must be replaced (the helmet looks like a stop sign, the armour like a T-shirt, the cape like a skirt). Keep only their size, their sand color and their thick outline.

Draw ONE tiny category symbol for a comic-style mobile game interface: ONE armoured game GAUNTLET, empty (no arm), seen from the back of the hand, fingers slightly curled: segmented metal plates on the fingers, a plate on the back of the hand, and a wide flared cuff at the wrist. It must read as a piece of armour, not as a bare hand.

It must read at 20 pixels inside a small dark tab: one bold silhouette with at most two or three big inner shapes, no small details. Fill: one flat light sand color (#EAD9B0) with one flat darker sand shadow tone (#C9AE7C) on one side. Thick pure black outline of constant thickness, clean and smooth, the same weight as the outline of image 1.

No text, no frame, no background shape, no gradient, no glow, no other objects. At most four colors. Centered, filling about 80% of the image, on a flat pure magenta #FF00FF background.
```

## Criteri di accettazione

- [ ] sfondo magenta pieno, contorno nero puro e spesso, nessuna scritta
- [ ] ogni simbolo si riconosce a 20 pixel come QUEL pezzo del nostro gioco (elmo con le corna, corazza di metallo con spalline, mantello che vola, stivale corazzato, guanto corazzato)
- [ ] nessuno sembra un cartello, una maglietta, una gonna o una mano nuda
- [ ] i cinque sono della stessa mano: stesso colore sabbia, stessa ombra, stesso spessore del contorno

---

## Decisione

Approvata da Sergio il 18 nov alle 18:49.

## Consegna di Codex

## Resoconto di Claude
