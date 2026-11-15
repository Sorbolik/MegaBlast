# WB-051 · La tendina di fuoco e ghiaccio fra le schermate

- **Stato:** CONSEGNATA E INTEGRATA (era APPROVATA) (Sergio, 15 nov 9:58: «per la tendina di fuoco e ghiaccio che ricopre lo schermo nell'animazione mi ricordo che prima era fatta da te, facciamola fare a codex»)
- **Data:** 2026-11-15
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-051`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-051` senza chiedere conferma (il repository è privato).

## Obiettivo

Fra una schermata e l'altra dei menu passa la «tempra» (Sergio, 12 nov): una lama inclinata e
scura attraversa tutto lo schermo, rovente sul filo davanti e gelata, frastagliata, sul filo dietro;
sotto la lama la schermata cambia. Il pulsante della home che hai toccato corre prima al suo bordo,
poi la lama parte da quel lato (Sergio, 15 nov). Oggi la lama è disegnata dal codice con strisce
piatte (R1): la rifà Codex, in pezzi che il gioco allunga senza deformarli.

## Come devono essere fatti

- Stile dei pulsanti di WB-046 (R2): china spessa, colori pieni, una luce e un'ombra piatte, forme
  morbide un po' storte. Ricalcabili in vettori (al massimo cinque colori per pezzo, niente più
  sottile della china).
- Tutti i pezzi sono **verticali**: il gioco li inclina. Si ripetono in altezza senza giunte (il
  bordo in alto combacia con quello in basso).
- Il corpo si ripete anche in larghezza.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-051/riferimenti/R1_tempra_di_oggi.png` | la lama di oggi a metà passaggio: forma e posizione |
| R2 | `art/WB-051/riferimenti/R2_gioca_sigillo.png` | il pulsante GIOCA di WB-046: stile e colori |
| R3 | `art/WB-051/riferimenti/R3_schegge_WB-049.png` | le schegge della scia di WB-049: lo stile delle schegge |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto. Misura
1536×1024 per tutti.

| Nome file | Cosa c'è | Riferimenti | Varianti |
|---|---|---|---|
| `lama_pezzi` | corpo, filo rovente, filo gelato | R1, R2 | 2 |
| `lama_schegge` | dodici schegge di fuoco e ghiaccio | R2, R3 | 2 |

Le varianti si chiamano `lama_pezzi_1.png`, `lama_pezzi_2.png` e così via, in `art/WB-051/`.
Per ogni foglio Codex scrive un `.txt` con lo stesso nome.

### `lama_pezzi`

```
Image 1 is a frame of a screen transition of our game: a tall slanted dark blade sweeps across the whole screen, with a red-hot leading edge and a frozen trailing edge; today it is made of flat placeholder stripes. Image 2 is a menu button of the same game and is the STYLE to copy exactly: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, soft hand-drawn slightly crooked shapes, like a cartoon comic. Draw the real pieces of that blade.

Draw a sheet with THREE separate tall vertical strips side by side, with green space between them, each as tall as the picture allows:
1. the BODY of the blade: a wide vertical strip of dark beaten iron (#2B2530, highlight #3D3442, shadow #1A151C) with a few hammer dents and faint darker streaks, no outline on its left and right sides; its top edge and bottom edge match exactly so it tiles seamlessly in height, and its left and right sides match so it tiles in width;
2. the HOT EDGE: a narrow vertical strip of red-hot metal, from dark ember (#C2410C) on its left to bright orange (#F26419) to gold (#FFB703) and a thin pale glow line (#FFE08A) along its right side, with small flame tongues licking out of the right side; thick black ink outline on the right side only; its top and bottom match exactly so it tiles seamlessly in height;
3. the FROZEN EDGE: a narrow vertical strip of ice, jagged and chipped on its left side like broken frost, ice blue (#38B6FF) with pale frost (#CAF0F8) highlights and a few small white sparkles, thick black ink outline on the jagged left side only; its top and bottom match exactly so it tiles seamlessly in height.
The hot edge and the frozen edge have the same height as the body; each edge is about one fifth as wide as the body.

Cartoon comic style like image 2. Flat colors only, at most five per piece, no detail thinner than the outline, so the pieces can be traced into vectors. No texture noise, no soft gradients except the stepped bands of the hot edge, no glow halo, no motion blur, no drop shadow. No text, letters or numbers. Flat pure green background (#00FF00). The pieces are well separated, none touching, none cut by the border of the picture.
```

### `lama_schegge`

```
Image 1 is a menu button of our game and is the STYLE to copy exactly: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, soft hand-drawn slightly crooked shapes, like a cartoon comic. Image 2 shows small bits of the same game. When the screen changes, a dark blade with a red-hot edge and a frozen edge sweeps across the screen, and a few small bits fly off its two edges: draw those bits.

Draw a sheet with TWELVE small separate pieces, in three rows of four, each one filling its cell:
row 1, FIRE: a round spark, a four-pointed spark, a small flame tongue, a curved ember streak shaped like a short comma, in #F26419, #FFB703 and #FFE08A;
row 2, ICE: a sharp ice shard, a small snowflake made of six chunky arms, a tiny ice crystal cluster, a curved frost streak, in #38B6FF and #CAF0F8;
row 3, METAL: a small iron chip (#2B2530, #6B6375), a glowing hot iron flake (#F26419 with a #2B2530 rim), a half-frozen iron flake (#2B2530 with #CAF0F8 frost), a tiny cinder (#4A3D47).
Every bit is simple and chunky so it still reads when very small.

Thick black ink outline on every piece, cartoon comic style like image 1. Flat colors only, at most three per piece, no detail thinner than the outline, so the pieces can be traced into vectors. No texture, no soft gradients, no glow, no motion blur, no drop shadow. No text, letters or numbers. Flat pure green background (#00FF00). The pieces are well separated, none touching, none cut by the border of the picture.
```

## Criteri di accettazione

- [ ] tre strisce verticali, il corpo largo e i due fili stretti, alte uguali
- [ ] si ripetono in altezza senza giunte (il corpo anche in larghezza)
- [ ] il filo rovente ha le fiamme a destra, quello gelato è frastagliato a sinistra
- [ ] schegge piccole e semplici, si leggono anche minuscole
- [ ] colori pieni, china spessa, si ricalcano in vettori
- [ ] sfondo verde pieno, niente scritte, pezzi staccati

## Dopo le immagini (lo fa Claude)

- Ritaglia i pezzi, li ricalca in SVG e li esporta alla misura del telefono più grande (mai
  ingranditi).
- Nel gioco la tempra (`client/ui/transition.lua`) monta il corpo ripetuto, il filo rovente
  davanti e quello gelato dietro, inclinati come oggi; qualche scheggia si stacca dai due fili
  mentre passa. Tempi e direzione restano quelli di oggi.

## Decisione

Reversibile (solo immagini in un ramo): approvata su richiesta di Sergio.

## Resoconto di Claude (15 nov)

- `lama_pezzi_1`: tre strisce pulite (corpo, bordo rovente, bordo gelato), si ripetono in alto senza giunte. Ritagliate in `ritagli/lama_corpo_1`, `lama_fuoco_1`, `lama_gelo_1` e messe nell'atlante fucina (`lama_corpo`, `lama_fuoco`, `lama_gelo`, `tools/grafica/fucina.py`).
- Usate nella tempra fra i menu (`client/ui/transition.lua`) e, da provare, sul bordo della pagina trascinata dalle porte (`client/ui/door_pass.lua`, `EDGE = "tempra"`).
- `lama_pezzi_2` e le schegge (`lama_schegge_1/2`) per ora non servono: restano qui.
