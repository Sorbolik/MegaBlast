# WB-093 · La Fornace: il Mestolo per tirare e gli stampi in tutti i colori

- **Stato:** APPROVATA (Claude, 24 nov: pezzi nuovi, non sostituiscono disegni già nel gioco; Sergio ha scelto il Mestolo sulla pagina https://claude.ai/artifact/VH5MfXRYEn3TQMgoSCdKF2)
- **Data:** 2026-11-24
- **Ramo della scheda:** `claude/project-thread-ft5von` (Codex la esegue da qui: `git fetch origin claude/project-thread-ft5von`, non serve che sia su `main`) · **Ramo delle immagini:** `design/WB-093`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-093` senza chiedere conferma (il repository è privato).

## Obiettivo

Nella Fornace ([docs/commesse.md](../commesse.md), «La Fornace») l'apprendista tira la goccia di Ossidiana negli stampi con la mira della battaglia. Sergio ha scelto l'arma: **il Mestolo**, un mestolo da colata col manico lungo. Prima del tiro lo porta indietro sopra la testa, trema e lo frusta in avanti (R3). Il gioco lo fa girare attorno alla mano: serve disegnato **dritto e orizzontale**, con la coppa a destra.

Servono anche gli stampi di WB-092 (R1, quelli scelti) **in tutti i colori e in tutte e due le misure**: in WB-092 ogni colore c'era in una misura sola. Gli stampi nuovi devono essere **uguali** a quelli di R1, solo più grandi nel foglio: allo zoom più vicino della battaglia uno stampo grande è largo circa 170 px, quindi nel foglio serve largo **almeno 340 px**, e uno piccolo almeno 230 px.

Misure nel gioco: il mestolo è lungo circa 130 px a 1280×720 allo zoom più vicino. Nel foglio va lungo **almeno 1000 px**.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-093/riferimenti/R1_stampi_scelti.png` | gli stampi scelti di WB-092: forma, ferro, orecchie con l'anello, placca tonda, metallo fuso. Da copiare identici |
| R2 | `art/WB-093/riferimenti/R2_goccia_scelta.png` | la goccia di Ossidiana scelta di WB-092 (in alto a sinistra, la palla viola col cuore che brilla) |
| R3 | `art/WB-093/riferimenti/R3_mestolo_bozza.png` | la bozza animata: l'apprendista mira col mestolo, lo porta indietro sopra la testa, lo frusta in avanti. Il mestolo è un segnaposto: dice solo la forma e la grandezza rispetto all'apprendista |
| R4 | `art/WB-093/riferimenti/R4_armi_del_gioco.png` | le armi del gioco (maglio, cannone) e l'apprendista che mira: lo STILE delle armi (contorno di china, colori piatti, una luce e un'ombra piatte) |
| R5 | `art/WB-093/riferimenti/R5_muro_coi_premi.png` | il muro della fucina con gli stampi appesi e i premi sopra: dove finiscono gli stampi |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto: il primo è "image 1", il secondo "image 2", il terzo "image 3".

| Nome file | Cosa c'è | Riferimenti | Misura | Varianti |
|---|---|---|---|---|
| `mestolo` | il mestolo vuoto e il mestolo con la goccia, dritti | R4, R3, R2 | 1536×1024 | 2 |
| `stampi_grandi_vuoti` | sei stampi grandi vuoti, uno per colore | R1 | 1536×1024 | 2 |
| `stampi_grandi_pieni` | gli stessi sei, pieni di metallo fuso | R1 | 1536×1024 | 2 |
| `stampi_piccoli_vuoti` | sei stampi piccoli vuoti, uno per colore | R1 | 1536×1024 | 2 |
| `stampi_piccoli_pieni` | gli stessi sei, pieni di metallo fuso | R1 | 1536×1024 | 2 |

Le varianti si chiamano `mestolo_1.png`, `mestolo_2.png`, `stampi_grandi_vuoti_1.png` e così via, in `art/WB-093/`. Per ogni foglio Codex scrive un `.txt` con lo stesso nome: cosa ha fatto e cosa non è riuscito a rispettare.

### `mestolo`

```
Image 1 shows the STYLE of the weapons of our cartoon game and our little devil aiming with one: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, hand-drawn like a cartoon comic. Image 2 is a draft animation: the little devil throws a drop of molten obsidian with a long forge ladle, swinging it back over his head and whipping it forward; the ladle there is only a placeholder that shows the shape and the size compared to the devil. Image 3 shows the drop of molten obsidian of our game (top left, the dark violet ball with the glowing core).

Draw a blacksmith's casting LADLE, the weapon the devil throws with, in the style of image 1, on plain green (#00FF00), lying perfectly STRAIGHT and HORIZONTAL, the handle on the LEFT and the bowl on the RIGHT, seen from the side, as long as most of the image width (at least 1000 px):
- the handle: a long straight iron rod (#5D5560, highlight #8A8290), with a wooden grip at the left end (#7A4A2A) bound by two thin iron rings, a small ring at the very end;
- the bowl: a deep round cast-iron cup at the right end (#3A3238, highlight #5D5560), seen from the side and a little from above so its opening is visible, a short pouring lip on its right rim, two rivets where it joins the handle; the inside of the bowl is dark and hot, with a thin orange glow on the inner rim (#FF7A1A).
Draw it TWICE, one under the other, well apart: on top the ladle EMPTY; below the SAME ladle with the drop of image 3 sitting in the bowl (the drop is the same violet-black ball with the glowing magenta-orange cracks and the white highlight, half sunk in the bowl).
Nothing else: no devil, no hand, no motion lines, no letters, no shadow on the ground, no glow halo around the ladle.
```

### `stampi_grandi_vuoti`

```
Image 1 shows the casting moulds of our cartoon game: copy them EXACTLY, same shape, same dark iron, same thick black ink outline, same two little ears with a ring on the top edge, same flat round plate on the front, same flat highlight and flat shadow. Only the size and the plate colors change.

Draw SIX separate BIG EMPTY moulds exactly like the big empty moulds of the top row of image 1, on plain green (#00FF00), in two rows of three, well apart from each other, each one whole and not touching the others, each one as big as possible in its place (at least 340 px wide). The opening is a dark empty hollow. The round plate on the front is EMPTY and one plain flat color: top row from left to right gold (#FFB703), ice blue (#8FD8F5), fire orange (#F26419); bottom row from left to right sea green (#5CDBB8), violet (#C49CFF), plain iron (#5D5560). All six moulds are identical except the plate color.
Nothing else: no chains, no wall, no icons on the plates, no letters, no numbers, no shadow on the ground, no glow halo.
```

### `stampi_grandi_pieni`

```
Image 1 shows the casting moulds of our cartoon game: copy them EXACTLY, same shape, same dark iron, same thick black ink outline, same two little ears with a ring on the top edge, same flat round plate on the front, same flat highlight and flat shadow. Only the size and the plate colors change.

Draw SIX separate BIG FULL moulds exactly like the big full moulds of the bottom row of image 1, on plain green (#00FF00), in two rows of three, well apart from each other, each one whole and not touching the others, each one as big as possible in its place (at least 340 px wide). The hollow is filled to the brim with glowing molten metal, bright orange-yellow (#FFB703 and #FF7A1A) with one flat white-yellow highlight, a thin wisp of steam, a little drip running down one side, like image 1. The round plate on the front is EMPTY and one plain flat color: top row from left to right gold (#FFB703), ice blue (#8FD8F5), fire orange (#F26419); bottom row from left to right sea green (#5CDBB8), violet (#C49CFF), plain iron (#5D5560). All six moulds are identical except the plate color.
Nothing else: no chains, no wall, no icons on the plates, no letters, no numbers, no shadow on the ground, no glow halo.
```

### `stampi_piccoli_vuoti`

```
Image 1 shows the casting moulds of our cartoon game: copy them EXACTLY, same shape, same dark iron, same thick black ink outline, same two little ears with a ring on the top edge, same flat round plate on the front, same flat highlight and flat shadow. Only the size and the plate colors change.

Draw SIX separate SMALL EMPTY moulds exactly like the small empty moulds of the top row of image 1 (they are a bit lower and rounder than the big ones), on plain green (#00FF00), in two rows of three, well apart from each other, each one whole and not touching the others, each one as big as possible in its place (at least 300 px wide). The opening is a dark empty hollow. The round plate on the front is EMPTY and one plain flat color: top row from left to right gold (#FFB703), ice blue (#8FD8F5), fire orange (#F26419); bottom row from left to right sea green (#5CDBB8), violet (#C49CFF), plain iron (#5D5560). All six moulds are identical except the plate color.
Nothing else: no chains, no wall, no icons on the plates, no letters, no numbers, no shadow on the ground, no glow halo.
```

### `stampi_piccoli_pieni`

```
Image 1 shows the casting moulds of our cartoon game: copy them EXACTLY, same shape, same dark iron, same thick black ink outline, same two little ears with a ring on the top edge, same flat round plate on the front, same flat highlight and flat shadow. Only the size and the plate colors change.

Draw SIX separate SMALL FULL moulds exactly like the small full moulds of the bottom row of image 1 (they are a bit lower and rounder than the big ones), on plain green (#00FF00), in two rows of three, well apart from each other, each one whole and not touching the others, each one as big as possible in its place (at least 300 px wide). The hollow is filled to the brim with glowing molten metal, bright orange-yellow (#FFB703 and #FF7A1A) with one flat white-yellow highlight, a thin wisp of steam, a little drip running down one side, like image 1. The round plate on the front is EMPTY and one plain flat color: top row from left to right gold (#FFB703), ice blue (#8FD8F5), fire orange (#F26419); bottom row from left to right sea green (#5CDBB8), violet (#C49CFF), plain iron (#5D5560). All six moulds are identical except the plate color.
Nothing else: no chains, no wall, no icons on the plates, no letters, no numbers, no shadow on the ground, no glow halo.
```

## Criteri di accettazione

- [ ] mestolo: dritto e orizzontale, manico a sinistra e coppa a destra, lungo almeno 1000 px, contorno di china e colori piatti come R4
- [ ] mestolo: due volte, vuoto e con la goccia di R2 nella coppa, identici per il resto
- [ ] stampi: identici a quelli di R1 (forma, ferro, orecchie, placca), solo più grandi
- [ ] stampi: sei per foglio, tre per riga, separati, la placca vuota del colore giusto nell'ordine scritto
- [ ] stampi grandi larghi almeno 340 px, piccoli almeno 300 px
- [ ] pieni: stesso ordine e stessi colori dei vuoti, metallo fuso fino all'orlo, un filo di vapore
- [ ] nessuna scritta, nessun alone, fondo verde pieno (si ritaglia)

---

## Decisione

Approvata da Claude il 24 nov: Sergio ha scelto il Mestolo («va bene la consigliata») sulla pagina https://claude.ai/artifact/VH5MfXRYEn3TQMgoSCdKF2 ; gli stampi in tutti i colori servono perché in WB-092 ogni colore c'era in una misura sola.

## Consegna di Codex

## Resoconto di Claude
