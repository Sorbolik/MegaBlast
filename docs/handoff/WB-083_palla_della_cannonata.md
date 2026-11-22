# WB-083 · La palla della Cannonata

- **Stato:** APPROVATA (Claude, 22 nov: è reversibile; la trasformazione l'ha scelta Sergio, proposta 2 "Entra nel cannone")
- **Data:** 2026-11-22
- **Ramo della scheda:** `claude/project-thread-5t5thg` (eseguila da questo ramo: `git fetch origin claude/project-thread-5t5thg`) · **Ramo delle immagini:** `design/WB-083`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-083` senza chiedere conferma (il repository è privato).

## Obiettivo

Con la Cannonata il diavoletto salta dentro il suo cannone e viene sparato: in volo diventa una
palla di ferro (anteprima scelta da Sergio: https://claude.ai/artifact/VM4s5mkDWYW7pbuv5yZwXY,
proposta 2). Dietro la palla il gioco disegna la testa vera del personaggio, così corna e fiamma
spuntano sopra e gli occhi si vedono da una **feritoia** che attraversa la palla. All'arrivo la
palla si spacca in **due mezzi gusci** e il diavoletto salta fuori. Servono quindi la palla con
la feritoia vuota e i due gusci. Il cannone grande a terra non serve: si esporta più grande da
`art/armi/cannon.png`, che è già ad alta risoluzione.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/armi/cannon_icona.png` | l'icona della Cannonata: la palla nera con le corna, materiale e colori da seguire |
| R2 | `art/armi/cannon.png` | il cannone che tiene in mano (WB-064): stile del contorno e fascia verde della squadra |
| R3 | `art/armi/fx_guscio.png` | il segno del guscio rotto (WB-066): forma del bordo spaccato |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Tutto in `art/WB-083/`, ogni PNG col suo `.txt`
del prompt. Si fa prima `palla_feritoia` (2 varianti: Codex sceglie quella con la feritoia più
pulita e lo scrive nel `.txt`), poi `palla_gusci` parte da quella scelta.

| Nome file | Riferimenti (in quest'ordine) | Misura | Varianti |
|---|---|---|---|
| `palla_feritoia.png` | R1, R2 | 1024×1024 | 2 |
| `palla_gusci.png` | `palla_feritoia_N.png` scelto, R3 | 1536×1024 | 1 |

In tutto 3 immagini.

### `palla_feritoia`

Allegati: R1, R2.

```
Image 1 is the icon of a weapon of our 2D comic game: a round black cannonball with devil horns and a face. Image 2 is the hand cannon of the same game: look at its thick black outline and at its pure green team band.

Draw ONE cannonball alone, seen from the front, in exactly the drawing style and the materials of image 1, but WITHOUT horns and WITHOUT any face: no eyes, no mouth, no grin. It is a heavy round iron ball, a perfect circle about 700 px wide, centered in the square image.
Across the ball runs a horizontal VISOR SLIT, like the slit of a knight's helmet: a straight horizontal opening with rounded ends, about 70% of the ball's width and about 13% of the ball's height, its center slightly above the center of the ball. The slit is a HOLE: inside it there is only flat pure magenta #FF00FF, exactly like the background, nothing else (no eyes, no darkness, no inner wall). The slit has its own thick closed black outline, like a cut in the iron.
Below the slit, a straight horizontal band around the ball, about 9% of the ball's height, in pure green #00FF00 with a hard shadow part in #00B400 (the team color, like the band of image 2), with its black outline; the band follows the roundness of the ball with a slight curve.
One single hard-edged highlight shape on the upper left, like the highlight of image 1. Three or four small round rivets along the top edge of the slit.

Rendering rules, very strict, because every shape will be traced into vector layers:
- Thick closed pure black #000000 outline around every shape and between color areas, the same weight as image 1 relative to the size.
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow, no blur, no sparkles, no motion lines.
- Use ONLY these colors: pitch #2E2433, pitch sheen #5E4870, dark pitch shadow #1E1724; team band pure green #00FF00 with shadow #00B400; black #000000.
- Background: flat pure magenta #FF00FF everywhere, no halo around the ball, no ground shadow.
- No text, numbers, letters, labels, arrows or signatures.
```

### `palla_gusci`

Allegati: `palla_feritoia_N.png` scelto, R3.

```
Image 1 is a cannonball of our 2D comic game, with a horizontal visor slit (the magenta inside the slit is a hole) and a green team band. Image 2 is a broken eggshell sign of the same game: look at its jagged broken edge.

Draw the SAME cannonball of image 1 BROKEN IN TWO HALVES, as if it just cracked open from the inside: on the left the TOP HALF, on the right the BOTTOM HALF, side by side, separated by a wide gap of magenta, both seen from the front, both the same size as in image 1 (about 700 px wide each, scale the image so both fit).
The ball breaks along a jagged zigzag line with four or five big teeth, like the edge of image 2, running across the ball just below the green band. The top half keeps the visor slit (still a magenta hole), the rivets, the highlight and the green band; the bottom half is the plain lower part of the ball. Where each half is broken, show the inside of the thick iron shell as a dark pitch #1E1724 strip along the jagged edge, with its black outline. Each half is one closed piece with its own thick black outline all around: nothing else on the sheet.

Rendering rules, very strict, because every shape will be traced into vector layers:
- Exactly the drawing style, colors, outline weight and highlight of image 1.
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow, no blur, no sparkles, no motion lines, no flying debris.
- Use ONLY these colors: pitch #2E2433, pitch sheen #5E4870, dark pitch shadow #1E1724; team band pure green #00FF00 with shadow #00B400; black #000000.
- Background: flat pure magenta #FF00FF everywhere, no halo around the pieces, no ground shadow. The two halves never touch.
- No text, numbers, letters, labels, arrows or signatures.
```

## Criteri di accettazione

- [ ] la palla è un cerchio pieno, senza corna e senza faccia, nello stile e nei colori dell'icona R1
- [ ] la feritoia è un buco pulito: dentro solo magenta piatto, bordo nero chiuso, estremità tonde
- [ ] una sola fascia verde #00FF00 (con ombra #00B400) sotto la feritoia
- [ ] i due gusci sono la stessa palla spaccata lungo una linea a denti, ognuno chiuso dal suo contorno, staccati fra loro
- [ ] colori piatti solo dalla lista, contorno nero puro e spesso, fondo magenta piatto, nessuna scritta

---

## Decisione

Approvata da Claude il 22 nov (scheda reversibile); la trasformazione l'ha scelta Sergio.

## Consegna di Codex

## Resoconto di Claude
