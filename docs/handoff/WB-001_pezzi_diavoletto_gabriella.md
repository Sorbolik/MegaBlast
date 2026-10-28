# WB-001 · Pezzi del diavoletto di Gabriella sullo stampino

- **Stato:** APPROVATA
- **Data:** 2026-10-28
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-001`

## Obiettivo

Rimettere nel gioco il diavoletto di Gabriella **così com'è disegnato** (R1: forme,
proporzioni, faccia, colori, stile dipinto e contorno nero), smontato nei pezzi dello
stampino (regole in `strumenti/stampino/README.md` della PR #55), così si monta sullo
scheletro e si muove con le animazioni che ci sono già. Lo stampino dice solo **dove** va
ogni pezzo e quanto è grande, non com'è fatto.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-001/riferimenti/R1_diavoletto_gabriella.png` | il diavoletto di Gabriella col contorno nero: è **il** modello, da copiare |
| R2 | `art/WB-001/riferimenti/R2_stampino_ai.png` | lo stampino: dove sta ogni pezzo sul foglio (3072×2048) |
| R3 | `art/WB-001/riferimenti/R3_manichino.png` | come si attaccano i pezzi fra loro |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega R1, R2 e R3 in quest'ordine.
Sono due fogli: uguali, tranne la canottiera, che nel secondo è del colore della squadra.

| Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|
| `foglio_rosso` | R1, R2, R3 | 3:2 orizzontale, la più grande che puoi (ideale 3072×2048, minimo 1536×1024) | 1 |
| `foglio_squadra` | R1, R2, R3 | come sopra | 1 |

Eccezione alla regola dello sfondo trasparente di `AGENTS.md`: qui lo sfondo resta **magenta
pieno #FF00FF**, come R2, perché lo strumento di taglio lo usa. Il verde #00FF00 qui non è
uno sfondo: nel secondo foglio segna la canottiera da tingere, e non va tolto.

Attenzione: il risultato deve sembrare **tagliato dal disegno di R1**, non dal manichino
grigio. Se i pezzi vengono semplificati, piatti o con le forme del manichino, è un difetto:
rigenera.

### `foglio_rosso`

```
Image 1 is the character: a small devil drawn by our artist. Copy HIM exactly: his proportions, his head shape, horns, black wraparound visor with glowing eyes, eyebrows, smile, skin colour, red tank top, black belt with buckle and hanging strap, baggy red trousers, brown shoes, dark grey bat wing, red tail with three-pronged trident tip, his thick black outline and his painted shading and texture. Image 1 is the only reference for how everything looks.

Image 2 is a layout sheet: 14 grey placeholder parts on a flat magenta (#FF00FF) background, in three rows. Use image 2 ONLY to know where each part goes on the sheet, roughly how big it is and where it attaches. Do NOT copy the grey parts' shapes, proportions, flat style or simple faces. Image 3 shows how the grey parts attach to each other.

Make a parts sheet of the devil of image 1, cut apart like a paper puppet: same canvas as image 2, same flat magenta #FF00FF background, each part placed over its grey placeholder, about the same size, and nothing else on the sheet (no grey placeholders left, no labels, no text, no shadows on the background, no flame). Every part is drawn as it looks in image 1 (3/4 view facing right), closed on all sides with the thick black outline, with no cut or missing edges.

The parts, left to right:
Row 1, four heads of the devil of image 1, facing right as in image 1, each with a short neck stub at the bottom: head 1 exactly as in image 1 (small smile); head 2 hit (eyes wide, small round open mouth); head 3 happy (big wide grin); head 4 knocked out (eyes as two short flat lines behind the visor, wavy mouth). Only the expression changes.
Row 2: the torso alone (red tank top with the belt, buckle and hanging strap, no head, no arms, no legs, no wing), with round closed shoulders and a closed bottom edge; the wing alone, as in image 1; the whole tail alone in one piece, as in image 1 with its trident tip, bent to follow the curve of the grey tail, one smooth continuous tube with no breaks, seams or joints.
Row 3: the near arm and the far arm, each hanging straight down from a round shoulder with the hand of image 1 at the bottom; the near leg and the far leg, each a baggy red trouser leg with its brown shoe, round and closed at the top; the upper arm and the forearm, two short pieces of the arm of image 1 with fully rounded, filled ends so they can overlap at the elbow without a visible joint; one closed fist.

Do not use any bright green anywhere.
```

### `foglio_squadra`

```
Image 1 is the character: a small devil drawn by our artist. Copy HIM exactly: his proportions, his head shape, horns, black wraparound visor with glowing eyes, eyebrows, smile, skin colour, black belt with buckle and hanging strap, baggy red trousers, brown shoes, dark grey bat wing, red tail with three-pronged trident tip, his thick black outline and his painted shading and texture. The only change: his tank top is painted in pure bright green #00FF00, shaded only with darker tones of the same pure green. Image 1 is the only reference for how everything looks.

Image 2 is a layout sheet: 14 grey placeholder parts on a flat magenta (#FF00FF) background, in three rows. Use image 2 ONLY to know where each part goes on the sheet, roughly how big it is and where it attaches. Do NOT copy the grey parts' shapes, proportions, flat style or simple faces. Image 3 shows how the grey parts attach to each other.

Make a parts sheet of the devil of image 1, cut apart like a paper puppet: same canvas as image 2, same flat magenta #FF00FF background, each part placed over its grey placeholder, about the same size, and nothing else on the sheet (no grey placeholders left, no labels, no text, no shadows on the background, no flame). Every part is drawn as it looks in image 1 (3/4 view facing right), closed on all sides with the thick black outline, with no cut or missing edges.

The parts, left to right:
Row 1, four heads of the devil of image 1, facing right as in image 1, each with a short neck stub at the bottom: head 1 exactly as in image 1 (small smile); head 2 hit (eyes wide, small round open mouth); head 3 happy (big wide grin); head 4 knocked out (eyes as two short flat lines behind the visor, wavy mouth). Only the expression changes.
Row 2: the torso alone (bright green #00FF00 tank top with the black belt, buckle and hanging strap, no head, no arms, no legs, no wing), with round closed shoulders and a closed bottom edge; the wing alone, as in image 1; the whole tail alone in one piece, as in image 1 with its trident tip, bent to follow the curve of the grey tail, one smooth continuous tube with no breaks, seams or joints.
Row 3: the near arm and the far arm, each hanging straight down from a round shoulder with the hand of image 1 at the bottom; the near leg and the far leg, each a baggy red trouser leg with its brown shoe, round and closed at the top; the upper arm and the forearm, two short pieces of the arm of image 1 with fully rounded, filled ends so they can overlap at the elbow without a visible joint; one closed fist.

The bright green #00FF00 is used ONLY for the tank top, nowhere else.
```

## Criteri di accettazione

- [ ] ogni pezzo sembra tagliato dal disegno di R1 (forme, faccia, colori, stile dipinto), non dal manichino
- [ ] 14 pezzi, uno per casella, sopra i posti di R2; nient'altro sul foglio, nessun manichino grigio rimasto
- [ ] sfondo magenta pieno, senza aloni o ombre
- [ ] contorno nero spesso e chiuso su ogni pezzo
- [ ] quattro teste con le quattro espressioni, tutte rivolte a destra
- [ ] coda intera, continua, senza giunture, con la punta a tridente; ala singola; pugno chiuso
- [ ] omero e avambraccio con le estremità tonde e piene
- [ ] verde acceso solo sulla canottiera del `foglio_squadra`, da nessun'altra parte
- [ ] nessuna scritta

---

## Decisione

Approvata da Claude, 2026-10-28: scelta reversibile (sono solo immagini da generare, il
gioco non cambia finché non le integro). Sergio può ribaltarla.

Rimessa in PROPOSTA da Claude, 2026-10-28: lo stampino stava cambiando. Riapprovata da Claude
lo stesso giorno con lo stampino definitivo (commit eb4e24b della PR #55).

Riscritta da Claude, 2026-10-28 10:10, su richiesta di Sergio: il primo giro di Codex copiava
le forme del manichino (il diavoletto a vettori). Ora il modello è il disegno di Gabriella
col contorno nero (R1, mandato da Sergio) e lo stampino serve solo per le posizioni. Due fogli
per scegliere: canottiera rossa come nel disegno, oppure del colore della squadra.

## Consegna di Codex

## Resoconto di Claude

Taglio previsto, dal ramo della PR #55:
`python3 strumenti/stampino/taglia.py art/WB-001/foglio_rosso.png --nome gabriella --categoria personaggio --allinea`
(e `foglio_squadra.png` con `--nome gabriella_squadra`), poi prova nell'editor e nella simulazione.
