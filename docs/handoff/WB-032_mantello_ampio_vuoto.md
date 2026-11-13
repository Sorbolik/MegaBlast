# WB-032 · Mantello ampio del Vuoto, fatto per muoversi

- **Stato:** APPROVATA (Sergio, 13 nov: «Pannello Mantello + nuovo disegno»)
- **Data:** 2026-11-13
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-032`

## Obiettivo

Il mantello del Vuoto di WB-019 è stretto, visto di lato e pensato per stare fermo. Nel gioco
pende da una catena simulata e uno shader lo piega tutto (`client/battle/cloth.lua`,
`client/battle/cape.fp`), così resta quasi nascosto dietro l'apprendista. Serve un mantello
disegnato per muoversi: più ampio verso il fondo, con pieghe lunghe dall'alto in basso, un orlo
strappato che si apre, il bordo in alto corto e dritto sull'attacco. Sergio sceglie fra due
varianti per ogni forma, base e forgiata. Lo stesso disegno serve anche alla prova con Godot,
per un confronto alla pari.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-019/scelti/vuoto.png` | la tavola scelta del Vuoto: colori e stile (a sinistra base, a destra forgiata) |
| R2 | `art/WB-019/riferimenti/R2_stampino_ai.png` | lo stampino: la casella `mantello` è la sagoma grigia fra busto e ala |
| R3 | `art/WB-019/vuoto_base.png` | il mantello di prima (a destra in mezzo; sul ramo `design/WB-019` se non è ancora su main): da NON rifare così, troppo stretto |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Un foglio per immagine, con un mantello solo.

| Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|
| `art/WB-032/vuoto_base_A.png` | R1, R2, R3 | 1536×1024 | 1 |
| `art/WB-032/vuoto_base_B.png` | R1, R2, R3 | 1536×1024 | 1 |
| `art/WB-032/vuoto_forgiata_A.png` | R1, R2, R3, `vuoto_base_A.png` | 1536×1024 | 1 |
| `art/WB-032/vuoto_forgiata_B.png` | R1, R2, R3, `vuoto_base_B.png` | 1536×1024 | 1 |

### Prompt comune (cambiano solo FORMA e TAGLIO)

```
Image 1 is the chosen armour set of our game (left: BASIC form, right: FORGED form). Image 2 is our "stampino": a sheet with grey body parts on magenta; the grey trapezoid between the torso and the wing is the box "mantello". Image 3 shows our previous cape (middle right): it was too narrow and too stiff, do NOT copy its shape.

Draw ONE cape of the [FORMA] form of image 1, alone, exactly inside the box "mantello" of image 2 and filling it completely (same position, the cape may go a little beyond its bottom and its left side). Seen from the side, hanging straight down behind the shoulders as if the wearer stood still: the top edge is short, straight and horizontal, at the top right corner of the box (where it is tied to the shoulders), no hood, no collar roll, no clasp hanging over the edge. The cape gets much wider toward the bottom: at the hem it is about twice as wide as at the top, flaring out to the left (the back). [TAGLIO] Long folds run from the top edge all the way down to the hem, so the cloth can bend anywhere. Length: down to the knee of the wearer. No body, no arms, no shoulders, nothing else on the sheet.

Same rendering rules as image 1: flat colors, indigo #2B2147 cloth with darker #1A1430 folds, thick closed black outline, trims in pure cyan #00FFFF. Background: flat pure magenta #FF00FF everywhere outside the cape. Do not draw the box, crosses or labels. No text. Landscape 3:2.
```

FORMA e TAGLIO per ogni file:

- `vuoto_base_A`: FORMA = `BASIC`; TAGLIO = `A bell-shaped cape: the hem is one wide curve with short ragged tears and two or three deep notches.`
- `vuoto_base_B`: FORMA = `BASIC`; TAGLIO = `A cape torn into four or five long tatters in its lower third, each tatter ending in a point, of different lengths.`
- `vuoto_forgiata_A`: FORMA = `FORGED`, allegando anche `vuoto_base_A.png` («Image 4 is the basic cape: draw the same cape, forged: same outline, add the cyan eye emblem near the top and a thin cyan trim along the hem»); TAGLIO come `vuoto_base_A`.
- `vuoto_forgiata_B`: FORMA = `FORGED`, allegando anche `vuoto_base_B.png` (stessa frase, con «the basic cape» di B); TAGLIO come `vuoto_base_B`.

## Criteri di accettazione

- [ ] un mantello solo per foglio, nella casella `mantello` dello stampino, sfondo magenta pulito
- [ ] bordo in alto corto, dritto, in alto a destra della casella; niente cappuccio né colletto
- [ ] in fondo largo circa il doppio che in alto, aperto verso sinistra (dietro)
- [ ] pieghe lunghe dall'alto al fondo; contorno nero chiuso e spesso; nessuna scritta
- [ ] la forgiata ha la stessa sagoma della base, con l'occhio e la finitura ciano

---

## Decisione

Approvata da Sergio il 13 nov (scelta «Pannello Mantello + nuovo disegno»). Claude porta la
scheda su `main`.

## Consegna di Codex

### 2026-11-13

Quattro PNG RGB originali da 1536 × 1024 px in `art/WB-032/`, con
prompt e riferimenti nei TXT omonimi. Generati con imagegen da `main`
aggiornato (`90da680e`). R3 proviene da `origin/design/WB-019`.

| File | Tentativi | Tentativo consegnato |
|---|---:|---:|
| `vuoto_base_A` | 3 | 1 |
| `vuoto_base_B` | 3 | 1 |
| `vuoto_forgiata_A` | 3 | 3 |
| `vuoto_forgiata_B` | 3 | 3 |

Ho controllato che ciascun foglio contenga un solo mantello, con attacco
corto e orizzontale, apertura a sinistra, pieghe lunghe, contorno scuro
chiuso e nessuna scritta. A ha l'orlo a campana con intagli e B ha lembi
più lunghi. Le forgiate hanno l'occhio e l'orlo ciano.

**Scostamenti.** I mantelli consegnati sono più grandi della casella
e l'attacco è spostato rispetto allo stampino. Due tentativi di base A
più vicini alla casella includevano anche le sagome grigie dello
stampino. Ho selezionato i fogli con il mantello isolato. Le sagome
forgiate sono simili alle basi, con differenze lungo l'orlo e una
variazione di larghezza più evidente nella coppia A. Il magenta e il
ciano presentano variazioni RGB rispetto ai valori esatti richiesti.
L'allineamento e la resa in movimento in Defold e Godot restano da
verificare.

## Resoconto di Claude
