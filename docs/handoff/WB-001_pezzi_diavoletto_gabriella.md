# WB-001 · Pezzi del diavoletto di Gabriella sullo stampino

- **Stato:** PROPOSTA (in attesa dello stampino definitivo: coda a segmenti, gomito, colore della squadra)
- **Data:** 2026-10-28
- **Ramo della scheda:** `claude/project-thread-gdvhtm` · **Ramo delle immagini:** `design/WB-001`

## Obiettivo

Rimettere nel gioco il diavoletto dipinto di Gabriella, ma con il contorno nero puro e
spesso, come pelle `personaggio` dello stampino: tutti i pezzi ridisegnati nelle caselle del
manichino, così si montano sullo scheletro e si muovono con le animazioni che ci sono già.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-001/riferimenti/R1_stampino_ai.png` | lo stampino: 14 caselle col manichino grigio su magenta (3072×2048) |
| R2 | `art/WB-001/riferimenti/R2_manichino.png` | il manichino montato: come stanno insieme i pezzi |
| R3 | `art/WB-001/riferimenti/R3_diavoletto_gabriella.png` | il diavoletto di Gabriella: colori, vestiti, faccia |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega R1, R2 e R3 in quest'ordine.

| Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|
| `foglio_gabriella` | R1, R2, R3 | 3:2 orizzontale, la più grande che puoi (ideale 3072×2048, minimo 1536×1024) | 2 |

Eccezione alla regola dello sfondo trasparente di `AGENTS.md`: qui lo sfondo resta **magenta
pieno #FF00FF**, come R1, perché lo strumento di taglio lo usa.

### `foglio_gabriella`

```
Image 1 is a parts template sheet for a 2D cut-out game character: 14 grey mannequin parts on a flat magenta (#FF00FF) background, in three rows. Image 2 shows the same grey parts assembled into the full character, so you can see how they fit together. Image 3 is the character to recreate: a small devil.

Redraw image 1 exactly: same canvas, same flat magenta #FF00FF background, the same 14 parts in the same positions, the same sizes, the same angles and the same silhouettes as the grey parts, but painted as the devil of image 3. Each part stays separate and in its own place; do not add, merge, move, resize or rotate any part, and do not add anything else to the sheet (no labels, no text, no shadows on the background, no flame).

The parts, left to right:
Row 1, four heads, all facing right like the grey ones: round beige-grey head with two curved dark brown horns, black wraparound visor across the eyes with two glowing white-yellow eyes, small dark eyebrows, short neck stub at the bottom like the grey one. Head 1: small closed smile. Head 2 (hit): eyes wide, small round open mouth. Head 3 (happy): big wide grin. Head 4 (knocked out): eyes as two short flat lines, wavy mouth.
Row 2: the torso with a red sleeveless tank top, black belt with a silver square buckle and the black strap hanging down, exactly the grey torso shape with round shoulders; one dark grey bat wing with the same shape and angle as the grey wing; the whole tail in dark red-brown, same curve as the grey tail, ending in a three-pronged trident tip.
Row 3: two hanging arms (beige-grey skin, closed fist at the bottom), two legs (baggy red trousers ending in a dark brown shoe, same shape as the grey legs), the upper arm and the forearm (short beige-grey capsules, rounded ends), and one round closed fist.

Style: clean 2D cartoon game art, flat colours with one simple soft shade (darker below, lighter above), THICK PURE BLACK outline around every part, as thick as the grey outline of image 1. No paper texture, no grain, no hatching, no brush strokes, no white or light rim outside the black outline, no brown outline. Keep the colours, clothes and face of image 3, but the shapes and positions of image 1.
```

## Criteri di accettazione

- [ ] 14 pezzi, uno per casella, nelle stesse posizioni di R1; nient'altro sul foglio
- [ ] sfondo magenta pieno, senza aloni o ombre
- [ ] contorno nero puro e spesso su ogni pezzo, nessun bordo chiaro fuori dal nero
- [ ] quattro teste con le quattro espressioni, tutte rivolte a destra
- [ ] coda intera con la punta a tridente, ala singola, pugno tondo
- [ ] nessuna scritta

---

## Decisione

Approvata da Claude, 2026-10-28: scelta reversibile (sono solo immagini da generare, il
gioco non cambia finché non le integro). Sergio può ribaltarla.

Rimessa in PROPOSTA da Claude, 2026-10-28: lo stampino sta cambiando (coda a segmenti,
gomito, colore della squadra). Si riapprova con i riferimenti e il prompt aggiornati, per
non spendere i limiti del Plus su un foglio vecchio.

## Consegna di Codex

## Resoconto di Claude

Taglio previsto: `python3 strumenti/stampino/taglia.py art/WB-001/foglio_gabriella_N.png --nome gabriella --categoria personaggio --allinea`
(dal ramo della PR #55), poi prova nell'editor e nella simulazione.
