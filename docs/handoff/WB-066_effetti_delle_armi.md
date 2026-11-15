# WB-066 · Effetti delle armi: sprite bianchi

- **Stato:** APPROVATA (Claude, 15 nov: Sergio ha chiesto di rifare la grafica di tutte le armi e ha detto «procedi»; reversibile)
- **Data:** 2026-11-15
- **Ramo della scheda:** `claude/project-thread-wfha2a` (eseguila da questo ramo: `git fetch origin claude/project-thread-wfha2a` e leggi la scheda e i riferimenti da lì; non serve che sia su `main`) · **Ramo delle immagini:** `design/WB-066`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-066` senza chiedere conferma (il repository è privato).
- **Pagina della proposta:** https://claude.ai/artifact/Eb3oSF1ydmrdgXRV1mnBHX (Armeria del Fabbro: idea, storia, sagoma e bozze di ogni arma)

## Obiettivo

Gli sprite delle «firme» delle armi e dei segni degli stati, **bianchi con il contorno nero**: il gioco li colora e li anima con le particelle di oggi (pochi nodi, 120 FPS). Vanno in un atlante solo.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-066/riferimenti/R1_bozze_effetti.png` | bozze degli effetti di alcune armi (solo per l'idea: qui servono le forme singole) |
| R2 | `art/WB-066/riferimenti/R2_stile_colori_piatti.png` | lo stile: colori piatti, contorno nero spesso (pezzi del Fornace, WB-057) |

## Regole comuni a tutti i fogli

- Ogni foglio è 1536×1024, con le varianti della tabella (`nome_1`, `nome_2`); ognuna col suo `.txt` del prompt in `art/WB-066/`.
- Allegare sempre **R1** (le bozze di Claude per quel foglio: dicono forma, idea, posizione e proporzioni; lo stile no) e **R2** (lo stile: colori piatti e contorno nero come i pezzi dei personaggi), in quest'ordine.
- Le armi in mano puntano **verso destra**, dritte in orizzontale, viste di lato, con l'impugnatura in basso come nella bozza. Niente mani né braccia: solo l'oggetto.
- Una sola fascia **verde #00FF00** per oggetto (è il colore della squadra, il gioco la ricolora): dove sta nella bozza.
- Il disegno deve restare chiaro rimpicciolito: niente dettagli più piccoli di un ventesimo dell'oggetto.

Qui gli oggetti non sono armi: niente fascia verde, niente orientamento a destra.

## Immagini da generare

Ogni prompt è completo e va usato così com'è.

| Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|
| `effetti` | R1_bozze_effetti, R2 | 1536×1024 | 2 |

### `effetti`

```
Image 1 shows rough effect sketches for a 2D comic game; image 2 shows the drawing style of the game.

Draw sixteen separate effect shapes in a 4 by 4 grid, each centred in a 384 by 256 px cell and about 180 px big, ALL filled with pure white #FFFFFF with a thick closed black outline (the game tints them), flat, no shading:
Row 1: (1) a carved angular rune sign inside a thin ring (not a letter); (2) a jagged comic impact star with eight points; (3) a crescent slash smear, thick in the middle and tapering at both ends; (4) a curly wind gust, three parallel curls.
Row 2: (5) a round puff of smoke, three bumps; (6) a ring of smoke, open in the middle; (7) a thin ring with small debris dots pointing inward toward the centre (a reverse explosion); (8) a pitch bubble, a dome with a small highlight cut-out.
Row 3: (9) a broken eggshell shard, curved, triangular; (10) a broken terracotta shard; (11) three small round droplets in a cluster; (12) a small rectangular paper confetti, slightly twisted.
Row 4: status signs: (13) a zig-zag crack with two branches; (14) a flat ash ring seen in perspective (an ellipse ring) with three tiny flakes above; (15) a small flame with two tongues; (16) a four-pointed sparkle.

Rendering rules, very strict, because every shape will be traced into vector layers:
- White #FFFFFF fill and black #000000 outline only; the only allowed extra is a hard-edged light grey #B7B0B8 shadow shape inside a shape.
- Background: flat pure magenta #FF00FF everywhere, no halo, shapes never touch each other.
- No text, numbers, letters, labels, arrows or signatures.
```

## Criteri di accettazione

- [ ] ogni oggetto del foglio c'è, nell'ordine e nella posizione della bozza R1, e si riconosce dalla sua sagoma
- [ ] colori piatti solo dalla lista, contorno nero chiuso e spesso, al massimo un'ombra netta per materiale
- [ ] una sola fascia verde #00FF00 per oggetto, dove la mette la bozza
- [ ] magenta pulito, oggetti separati, nessuna scritta, nessun alone o bagliore
- [ ] stesso stile di R2 (si deve vedere che sono dello stesso gioco dei personaggi)

---

## Decisione

(Claude) Approvata in autonomia il 15 nov: Sergio ha chiesto di ripensare la grafica di tutte le armi e di procedere; solo immagini nuove, il gioco cambia solo quando Claude le integra.

## Consegna di Codex

## Resoconto di Claude
