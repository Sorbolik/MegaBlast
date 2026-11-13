# WB-036 · L'apprendista intero, rifatto per Godot (fase 1)

- **Stato:** APPROVATA (Sergio, 13 nov: «io li rifarei tutti i pezzi»)
- **Data:** 2026-11-13
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-036`

## Obiettivo

Per la prova con Godot l'apprendista si rifà tutto, con la procedura di
[PERSONAGGI.md](PERSONAGGI.md), senza scorciatoie: prima **l'apprendista intero** nel tre quarti
approvato (questa scheda), Sergio sceglie; poi i pezzi ricalcati da quello sullo stampino
(fase 2, scheda successiva) e le teste con le espressioni. Nessun pezzo viene montato a occhio
(lezione di WB-033).

Una sola cosa nuova rispetto a R1: **la fiammella esce da una fessura appena percettibile, quasi solo una linea** (Sergio, 13 nov), in cima alla testa, come
nella prima generazione (R2). La fessura segue **l'asse della testa**: corre lungo la linea di
mezzo del cranio, inclinata come è inclinata la testa nel tre quarti, non dritta rispetto al
foglio (Sergio, 13 nov, su WB-035). La fiamma è parte della testa e la segue.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-009/riferimenti/R1b_apprendista_senza_fiammella.png` | l'apprendista approvato, tre quarti verso destra: il modello |
| R2 | `art/WB-035/riferimenti/R2_fessura_prima_generazione.png` | la prima generazione: la fiamma esce da una fessura sul cranio |

## Immagini da generare

| Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|
| `art/WB-036/tre_quarti.png` | R1, R2 | 1024×1536 | 4 |

Le varianti si chiamano `tre_quarti_1.png` … `tre_quarti_4.png`.

### `tre_quarti`

```
Image 1 is the main character of our game, a little blacksmith-apprentice imp, in a three-quarter view facing right. It is the EXACT model: redraw him as he is, with the same head, face, horns, ears, neckerchief, torso, belly patch, arms, hands, legs, tail, proportions, contours, colors and flat style, standing and facing right, both feet pointing to the right.

Add ONE thing: his head flame, coming out of a SLIT in his skull, like in image 2 (the first drawing of the character). The slit is BARELY VISIBLE, almost just a line: a single thin dark crease on the skin with only a hair-thin glow of yellow inside, no open hole, no torn edges, no wound. It starts at the top of the skull, between the horns, and runs DOWN THE MIDDLE OF HIS HEAD toward his forehead, for about one sixth of the head's height. IMPORTANT: the slit follows the head's own axis. In the three-quarter view the head is turned and tilted, so the slit lies along the center line of the skull and is tilted exactly like the head (like the parting of hair on his own head), NOT straight up and down on the page. The flame (orange #F07A1E with yellow #FFD34A inside and a thick black outline, about as tall as his head without the horns, leaning slightly back) grows out of the top end of that line: its narrow bottom touches the skull right there, so the flame is clearly part of his head, not a fire floating above it.

Pose for the rig: arms hanging slightly away from the body, not touching it, hands in loose fists; legs slightly apart; tail free behind him, not crossing the legs. Nothing overlaps more than needed.

Rendering rules, very strict, because this drawing will be traced and cut into pieces:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone listed below. No gradients, no textures, no hatching, no brush strokes, no soft shading, no glow (also none around the flame).
- Thick, clean, closed pure-black #000000 outline of even weight around the whole figure, with thinner black lines only for inner details.
- Use ONLY these colors: outline and pupils black #000000; skin #B8432A, skin shadow #8E2F1C; belly and muzzle #F1DFB0, their shadow #D6BC86; horns and toenails #EFE3C8, their shadow #C9B48E; eyes #F2C45A with a small white #FFFFFF highlight; inside of mouth #5A1A10, teeth white #FFFFFF; flame #F07A1E and #FFD34A, the inside of the slit #FFD34A; neckerchief pure bright green #00FF00 with shadow #00B400 (only on the neckerchief).
- Flat pure white #FFFFFF background, no ground, no shadow on the ground.
- No text, numbers, labels, arrows or signatures. Portrait format 2:3.
```

## Criteri di accettazione

- [ ] lo stesso apprendista di R1: proporzioni, forme, colori della tavolozza, contorno nero spesso
- [ ] fessura appena percettibile, quasi solo una linea (Sergio, 13 nov), lungo l'asse della testa (inclinata con la testa, non dritta sul foglio)
- [ ] la fiamma esce dalla cima della fessura, attaccata alla testa
- [ ] braccia staccate dal corpo, gambe un po' aperte, coda libera; piedi a destra
- [ ] sfondo bianco pieno, colori piatti, nessuna scritta

---

## Decisione

Approvata da Sergio il 13 nov («io li rifarei tutti i pezzi»). Dopo la scelta di Sergio fra le
quattro varianti, Claude scrive la fase 2 (pezzi sullo stampino e nove teste) copiando da quella.

## Consegna di Codex

### 2026-11-13

Quattro PNG originali da 1024 × 1536 px in `art/WB-036/`, con
prompt integrale e riferimenti R1 e R2 nei TXT omonimi. Ho usato
imagegen dopo il pull e l'aggiornamento del ramo alla scheda
`de964d8b`, che chiede la fessura appena percettibile. Le prove
del prompt precedente sono state escluse.

| File | Tentativi con il prompt aggiornato | Tentativo consegnato |
|---|---:|---:|
| `tre_quarti_1` | 3 | 3 |
| `tre_quarti_2` | 3 | 2 |
| `tre_quarti_3` | 3 | 1 |
| `tre_quarti_4` | 3 | 3 |

Ho controllato figura intera, fiamma attaccata alla testa, fessura
sottile e inclinata, fazzoletto verde, sfondo chiaro, contorno scuro
e assenza di scritte. Le quattro varianti sono simili. Come in R1,
il piede vicino resta più frontale dell'altro. La radice della coda
passa dietro il braccio vicino e alcune dita restano distese.
Sfondo e campiture mostrano lievi variazioni rispetto ai valori
RGB esatti. Il taglio dei pezzi e la resa nel rig restano da verificare.

## Resoconto di Claude
