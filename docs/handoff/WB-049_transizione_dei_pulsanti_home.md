# WB-049 · I pezzi della transizione dei pulsanti della home

- **Stato:** APPROVATA (Sergio, 14 nov 23:16: «facciamoci fare per bene da codex gli elementi che servono per la transizione e facciamola bella pulita»)
- **Data:** 2026-11-14
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-049`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-049` senza chiedere conferma (il repository è privato).

## Obiettivo

I quattro pulsanti nuovi della home (WB-046) hanno lo scudo verso il bordo dello schermo:
CAMPAGNA e ALLENAMENTO a sinistra, EVENTI e ARMERIA a destra. Quando lo tocchi (Sergio, 14 nov):
il pulsante scivola di poco verso il suo bordo, lo scudo arriva al bordo e da lì **trascina la
schermata** che apri attraverso lo schermo fino all'altro lato; tornando alla home fa lo stesso
al contrario. La prova animata di Claude è su https://claude.ai/artifact/NUZURUfk3Gt2eaFpnN7roq
(R2 è un fotogramma).

Aggiornato (Sergio, 23:29): tutto il pulsante, coda compresa, resta attaccato al bordo della
schermata come una linguetta che la trascina; la banda è il bordo su cui sta lo scudo.

Nella prova lo scudo è montato su una banda verticale piatta (il bordo della schermata che
arriva): è un segnaposto. Servono:

1. **le quattro bande del bordo**, una per pulsante, alte quanto lo schermo, con l'attacco dove
   si monta lo scudo;
2. **le schegge della scia**: poche scintille, schegge di ghiaccio, lampi d'oro e trucioli che
   si staccano dal bordo mentre corre (il gioco ne fa partire 3 o 4, piccole e veloci).

## Come devono essere fatti

- Stile dei pulsanti di WB-046 (R1): china spessa, colori pieni, una luce e un'ombra piatte,
  forme morbide un po' storte. Ricalcabili in vettori (al massimo cinque colori per pezzo, niente
  più sottile della china), così Claude li ricalca in SVG e li esporta a ogni misura.
- Le bande si allungano solo in altezza: in alto e in basso le punte, il mezzo liscio e uguale
  (tre parti), e l'attacco dello scudo come pezzo a parte.
- Le schegge sono piccole forme piene, staccate una dall'altra.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-049/riferimenti/R1_porta_campagna.png` | il pulsante CAMPAGNA di WB-046: stile, colori, scudo |
| R1b | `art/WB-049/riferimenti/R1b_porta_armeria.png` | il pulsante ARMERIA con lo scudo a destra |
| R2 | `art/WB-049/riferimenti/R2_prova_transizione.png` | fotogramma della prova: la banda segnaposto con lo scudo |
| R3 | `art/WB-022/pezzo_piccoli.png` | pezzi piccoli di WB-022: la china |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto. Misura
1536×1024 per tutti.

| Nome file | Cosa c'è | Riferimenti | Varianti |
|---|---|---|---|
| `bande_bordo` | quattro bande verticali e l'attacco dello scudo | R1, R1b, R2, R3 | 2 |
| `schegge_scia` | sedici schegge della scia | R1, R1b, R3 | 2 |

Le varianti si chiamano `bande_bordo_1.png`, `bande_bordo_2.png` e così via, in `art/WB-049/`.
Per ogni foglio Codex scrive un `.txt` con lo stesso nome.

### `bande_bordo`

```
Images 1 and 2 are two menu buttons of our game and are the STYLE to copy exactly: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, soft hand-drawn slightly crooked shapes, like a cartoon comic. Image 3 is a frame of a screen transition: when a button is tapped, its round shield reaches the edge of the screen and drags the new screen across, and the shield rides on a tall vertical band at the leading edge of that screen. The flat vertical band in image 3 is a placeholder: draw the real ones. Image 4 shows other small pieces of the same game.

Draw a sheet with FIVE separate pieces side by side, with green space between them:
1. CAMPAIGN band: a tall narrow vertical band, about seven times taller than wide, of ember (#F26419) with a lighter stripe (#FFB703) along its left side and small flame tongues licking out of its right side; its top and bottom ends are rounded and slightly crooked; between the ends it is plain and even so it can be stretched in height;
2. TRAINING band: the same shape, of worn steel (#8C929C, highlight #C9CED6) with a strip of wood (#8A6A4A) along its right side held by two iron bands near the ends;
3. EVENTS band: the same shape, of gold (#FFB703, lighter stripe #FFE08A, darker stripe #F26419), its left side cut in small swallow-tail notches like the end of a banner;
4. ARMOURY band: the same shape, of dark iron (#2B2530, highlight #6B6375) with an ice-blue edge (#38B6FF, highlight #CAF0F8) along its left side, cut like chipped ice;
5. the shield MOUNT: a short chunky dark iron bracket (#2B2530, highlight #6B6375) shaped like a clamp with two rivets, as wide as a band and a bit taller than wide, that holds a round shield on the band.
The four bands have exactly the same width and height.

Thick black ink outline on every piece, cartoon comic style like images 1 and 2. Flat colors only, at most five per piece, no detail thinner than the outline, so the pieces can be traced into vectors. No texture, no soft gradients, no glow, no motion blur, no drop shadow. No text, letters or numbers. Do not draw the shields. Flat pure green background (#00FF00). The pieces are well separated, none touching, none cut by the border of the picture.
```

### `schegge_scia`

```
Images 1 and 2 are two menu buttons of our game and are the STYLE to copy exactly: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, soft hand-drawn slightly crooked shapes, like a cartoon comic. Image 3 shows other small pieces of the same game. When a menu button is tapped, a tall band carrying its shield runs across the screen, and a few small bits fly off its edge: draw those bits.

Draw a sheet with SIXTEEN small separate pieces, in four rows of four, each one filling its cell:
row 1, EMBER (for CAMPAIGN): a round spark, a four-pointed spark, a small flame tongue, a curved ember streak shaped like a short comma, all in #F26419 and #FFB703;
row 2, STEEL AND WOOD (for TRAINING): a small steel chip (#8C929C, #C9CED6), a bent wood splinter (#8A6A4A, #B48A60), a small straw tuft (#E0B64A), a short curved steel streak;
row 3, GOLD (for EVENTS): a four-pointed gold glint (#FFB703, #FFE08A), a small gold coin seen from the side, a tiny ribbon scrap (#FFB703), a short curved gold streak;
row 4, ICE (for ARMOURY): a sharp ice shard (#38B6FF, #CAF0F8), a small snowflake made of six chunky arms, a tiny ice crystal cluster, a short curved ice streak.
Every bit is simple and chunky so it still reads when very small.

Thick black ink outline on every piece, cartoon comic style like images 1 and 2. Flat colors only, at most three per piece, no detail thinner than the outline, so the pieces can be traced into vectors. No texture, no soft gradients, no glow, no motion blur, no drop shadow. No text, letters or numbers. Flat pure green background (#00FF00). The pieces are well separated, none touching, none cut by the border of the picture.
```

## Criteri di accettazione

- [ ] quattro bande uguali di misura, il mezzo liscio, colori dei loro pulsanti
- [ ] l'attacco dello scudo è un pezzo a parte
- [ ] schegge piccole e semplici, si leggono anche minuscole
- [ ] colori pieni, china spessa, si ricalcano in vettori
- [ ] sfondo verde pieno, niente scritte, pezzi staccati

## Dopo le immagini (lo fa Claude)

- Ritaglia bande, attacco e schegge, li mette nella prova animata (stesso indirizzo) al posto dei
  segnaposti e la mostra a Sergio.
- Se va bene: nel gioco la transizione della home usa questi pezzi (`client/menu/home.lua`), il
  ritorno è la stessa animazione al contrario; con il movimento ridotto si salta.

## Decisione

Reversibile (solo immagini in un ramo): approvata su richiesta di Sergio.

## Consegna di Codex

Quattro fogli generati con `image_gen` da `main` (`dbce15cc`), in `art/WB-049/`.
Ogni PNG è affiancato dal TXT con il prompt integrale e i riferimenti nell'ordine della tabella.

| Nome (PNG e TXT) | Tentativi | Selezione | Dimensioni PNG |
|---|---:|---:|---:|
| `bande_bordo_1` | 1 | 1 | 1536×1024 |
| `bande_bordo_2` | 3 | 1 | 1536×1024 |
| `schegge_scia_1` | 1 | 1 | 1254×1254 |
| `schegge_scia_2` | 1 | 1 | 1254×1254 |

Verificati a vista quattro bande e un attacco per foglio, sedici schegge in griglia
4×4 per foglio, colori delle quattro famiglie, contorni neri e pezzi interi e
separati. Nessuna scritta o scudo. In `bande_bordo_2` ci sono puntini vicino alla
fiamma. I due tentativi successivi avevano l'attacco diviso in due, quindi ho
tenuto il primo. Le bande hanno altezze simili e larghezze diverse. Fiamme,
tacche e spigoli arrivano anche nella parte centrale.

I fogli delle schegge sono quadrati. Lo sfondo è verde opaco e nei punti campionati
differisce da `#00FF00`. Non verificati il conteggio delle tinte, il ricalco, la resa
delle schegge in piccolo o l'allungamento delle bande durante la transizione.

## Resoconto di Claude

Tutti e quattro i fogli sono buoni, senza difetti visibili. Ritagliati dal verde in
`art/WB-049/ritagli/`: le quattro bande e l'attacco dello scudo (`banda_<pulsante>_1|2`,
`attacco_scudo_1|2`) e le sedici schegge per foglio (`scia_<nome>_1|2`: brace, scintilla, fiamma,
ricciolo; ferro, cuoio, paglia, acciaio; stella, moneta, nastro, oro; ghiaccio, fiocco, cristallo,
gelo). Scelta di Claude: le bande e l'attacco della variante 1 (cima arrotondata, si allungano meglio
in alto), le schegge della variante 1; la 2 resta di scorta. Vanno nella prova animata allo stesso
indirizzo al posto della banda segnaposto.
