# WB-068 · Oggetti: la Molla larga e bassa e la tagliola chiusa

- **Stato:** IMPLEMENTATA · era APPROVATA (Claude, 15 nov: Sergio vuole gli oggetti nello stesso stile delle armi; reversibile)
- **Data:** 2026-11-15
- **Ramo della scheda:** `claude/project-thread-wfha2a` (eseguila da questo ramo: `git fetch origin claude/project-thread-wfha2a` e leggi la scheda e i riferimenti da lì; non serve che sia su `main`) · **Ramo delle immagini:** `design/WB-068`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-068` senza chiedere conferma (il repository è privato).

## Obiettivo

Due disegni che mancano dopo WB-065, con forme che servono alla simulazione:
la **Molla** è larga 36 e alta circa 12 nel gioco (quella di WB-065 è alta e stretta e non ci sta), e la **tagliola chiusa** è quella che scatta su chi ci passa.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-068/riferimenti/R1_molla_e_tagliola_di_WB065.png` | la Molla e la tagliola aperta di WB-065: materiali, colori e stile da tenere |
| R2 | `art/WB-068/riferimenti/R2_stile_colori_piatti.png` | lo stile: colori piatti, contorno nero spesso (pezzi del Fornace, WB-057) |

## Immagini da generare

| Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|
| `molla_e_tagliola` | R1, R2 | 1536×1024 | 2 (`molla_e_tagliola_1`, `molla_e_tagliola_2`), ognuna col suo `.txt` del prompt in `art/WB-068/` |

### `molla_e_tagliola`

```
Image 1 shows two objects from our 2D comic game set in a cartoon hell (a spring pad and an open bear trap); image 2 shows the drawing style of the game. Draw two new objects with exactly the same materials, colours and style as image 1, side view, on one sheet:
1. Top half of the sheet, centred: a WIDE and LOW spring pad, about 1200 px wide and only 400 px tall (three times wider than tall): a long flat wooden base at the bottom, three or four short dark-iron zig-zag springs side by side standing on it, and a long brass top plate resting on the springs, as wide as the base; a small team-green triangle in the middle of the top plate.
2. Bottom half of the sheet, centred: the same bear trap of image 1 but SNAPPED SHUT, about 500 px wide and 450 px tall, seen from the side: the two half-moon iron jaws closed upward and meeting at the top, the light-iron teeth interlocked in the middle, the brass pivot at the bottom on a short dark-iron base.
Rendering rules, very strict, because every shape will be traced into vector layers:
- Same drawing style as image 2: thick closed pure black #000000 outline around every shape and between colour areas, chunky soft slightly asymmetric comic shapes.
- FLAT COLORS ONLY: every area is one solid colour, plus at most one hard-edged shadow shape in the darker tone of the same material. No gradients, no textures, no soft shading, no glow halos, no blur, no sparkles, no motion lines.
- Use ONLY these colours: dark iron #3B404B, iron #59606E, light iron #8F98A8; dark brass #A8761F, brass #D9A441; dark leather #4A3019, leather #6B4A2B, wood #8A5A33; team green #00FF00 with shadow #00B400 (only the triangle on the spring pad); white #FFFFFF; black #000000.
- Background: flat pure magenta #FF00FF everywhere, no halo around the objects, no ground shadow. The two objects never touch each other.
- No text, numbers, letters, labels, arrows or signatures.
```

## Criteri di accettazione

- [ ] la Molla è almeno tre volte più larga che alta, con la piastra d'ottone larga come la base
- [ ] la tagliola è chiusa, coi denti incastrati, ed è la stessa di R1
- [ ] colori piatti solo dalla lista, contorno nero chiuso e spesso
- [ ] magenta pulito, oggetti separati, nessuna scritta, nessun alone

---

## Decisione

(Claude) Approvata in autonomia il 15 nov: Sergio ha chiesto gli oggetti nello stesso stile e formato delle armi; solo immagini nuove.

## Consegna di Codex

## Resoconto di Claude

(18 nov) Scelto `molla_e_tagliola_1` (i denti della tagliola chiusa si incastrano meglio). Ricalcato (`art/armi/svg/`), tagliato in `art/armi/molla.png` e `tagliola_chiusa.png`, messo nel gioco da `tools/grafica/attrezzi.py`: la Molla è larga 39,2 come prima e bassa 9,8, la tagliola chiusa è larga 18.
- Il triangolo verde (Sergio, 18 nov): si stacca dalla piastra, si gira di lato e il gioco lo specchia verso dove la Molla lancia, nel colore della squadra (`attrezzo_molla_freccia`, `client/battle/items.lua`). Prende il posto della freccetta arancio a codice. Mentre la Molla vola non c'è.
- Tolti i disegni a vettori della Molla e della tagliola chiusa. Scenario `tools/simula/scenari/molla.txt`.

