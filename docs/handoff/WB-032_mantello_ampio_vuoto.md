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
| `art/WB-032/vuoto_base_A.png` | R1, R2, R3 | 1024×1024 | 1 |
| `art/WB-032/vuoto_base_B.png` | R1, R2, R3 | 1024×1024 | 1 |
| `art/WB-032/vuoto_forgiata_A.png` | R1, R2, R3, `vuoto_base_A.png` | 1024×1024 | 1 |
| `art/WB-032/vuoto_forgiata_B.png` | R1, R2, R3, `vuoto_base_B.png` | 1024×1024 | 1 |

### Prompt comune (cambiano solo FORMA e TAGLIO)

```
Image 1 is the chosen armour set of our game (left: BASIC form, right: FORGED form). Image 2 is our "stampino": a sheet with grey body parts on magenta; the grey trapezoid between the torso and the wing is the box "mantello". Image 3 shows our previous cape (middle right): it was too narrow and too stiff, do NOT copy its shape.

Draw ONE cape of the [FORMA] form of image 1, alone, BIG: it fills the whole square sheet, with only a thin margin of magenta (about 30 pixels) on every side. Its proportions are those of the box "mantello" of image 2 (about as tall as it is wide at the hem), but drawn much larger, with every line crisp and detailed at this size. Seen from the side, hanging straight down behind the shoulders as if the wearer stood still: the top edge is short, straight and horizontal, at the top right of the sheet (where it is tied to the shoulders), no hood, no collar roll, no clasp hanging over the edge. The cape gets much wider toward the bottom: at the hem it is about twice as wide as at the top, flaring out to the left (the back). [TAGLIO] Long folds run from the top edge all the way down to the hem, so the cloth can bend anywhere. Length: down to the knee of the wearer. No body, no arms, no shoulders, nothing else on the sheet.

Same rendering rules as image 1: flat colors, indigo #2B2147 cloth with darker #1A1430 folds, thick closed black outline, trims in pure cyan #00FFFF. Background: flat pure magenta #FF00FF everywhere outside the cape. Do not draw the box, crosses or labels. No text. Square 1:1.
```

FORMA e TAGLIO per ogni file:

- `vuoto_base_A`: FORMA = `BASIC`; TAGLIO = `A bell-shaped cape: the hem is one wide curve with short ragged tears and two or three deep notches.`
- `vuoto_base_B`: FORMA = `BASIC`; TAGLIO = `A cape torn into four or five long tatters in its lower third, each tatter ending in a point, of different lengths.`
- `vuoto_forgiata_A`: FORMA = `FORGED`, allegando anche `vuoto_base_A.png` («Image 4 is the basic cape: draw the same cape, forged: same outline, add the cyan eye emblem near the top and a thin cyan trim along the hem»); TAGLIO come `vuoto_base_A`.
- `vuoto_forgiata_B`: FORMA = `FORGED`, allegando anche `vuoto_base_B.png` (stessa frase, con «the basic cape» di B); TAGLIO come `vuoto_base_B`.

### Perché il foglio è quadrato e il mantello lo riempie (Sergio, 13 nov)

Il mantello deve essere alla qualità migliore su ogni schermo. Disegnato dentro la casella dello
stampino occupava circa 190×200 pixel del foglio di Codex: nel gioco veniva ingrandito e si vedeva
sgranato. Disegnato grande su tutto il foglio quadrato ha circa 950 pixel di altezza, cioè circa 6
pixel per unità del gioco, più di quanti ne servono sul telefono più grande. Claude lo porta (con `taglia.py`)
alla misura della casella (larga e alta come la casella per `GRANDE_MANTELLO`) e lo attacca dal bordo
in alto a destra, come prima: cambia solo la finezza.

## Criteri di accettazione

- [ ] un mantello solo per foglio quadrato, grande quanto il foglio (margine sottile), sfondo magenta pulito
- [ ] bordo in alto corto, dritto, in alto a destra del foglio; niente cappuccio né colletto
- [ ] in fondo largo circa il doppio che in alto, aperto verso sinistra (dietro)
- [ ] pieghe lunghe dall'alto al fondo; contorno nero chiuso e spesso; nessuna scritta
- [ ] la forgiata ha la stessa sagoma della base, con l'occhio e la finitura ciano

---

## Decisione

Approvata da Sergio il 13 nov (scelta «Pannello Mantello + nuovo disegno»). Claude porta la
scheda su `main`.

## Consegna di Codex

## Resoconto di Claude
