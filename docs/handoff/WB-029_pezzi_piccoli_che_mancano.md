# WB-029 · I pezzi piccoli che mancano: stelle, barre, tacche, sigilli

- **Stato:** APPROVATA (Sergio, 2026-11-12: «i componenti che hai lasciato a vecchio, rifacciamoli, anche con codex se serve... non lasciamo niente indietro»)
- **Data:** 2026-11-12
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-029`

## Obiettivo

I pezzi di WB-022 (lingotto, piastre, pannello, lucchetto, scaglia, gemma) sono nel gioco, ma
accanto restano forme vecchie, piatte e senza china: le stelle delle missioni, la medaglia di
Favilla, la rotella delle impostazioni, le barre (esperienza, statistiche, grado dei pezzi), le
tacche, le cornici tonde dei sigilli, le linguette dell'assetto. Sergio non vuole lasciare
indietro niente: servono gli stessi pezzi **nello stile di WB-022**.

Sono tre fogli, ognuno con più pezzi staccati su verde: il gioco li ritaglia da solo
(`tools/grafica/fucina.py`), li ricolora dove serve e non li deforma mai (le barre si
allungano solo nel mezzo).

## Cosa teniamo e cosa scartiamo

| Teniamo | Perché |
|---|---|
| China spessa e un po' irregolare, colori pieni, una luce e un'ombra piatte | è lo stile approvato di WB-022 (R1, R2, R3) |
| Forme morbide e un po' storte | «forme morbide, non simmetriche» (Sergio) |
| I colori della fucina: ferro scuro, brace, avorio, ghiaccio | fuoco contro ghiaccio in ogni schermata |
| L'interno di cornici, gusci e linguette vuoto | ci scrive e ci disegna il gioco |

| Scartiamo | Perché |
|---|---|
| Texture, sfumature morbide, bagliori, 3D, ombre a terra | stile di WB-020, scartato |
| Scritte, lettere, numeri | li mette il gioco |
| Pezzi che si toccano o tagliati dal bordo | il gioco li ritaglia uno per uno |

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-029/riferimenti/R1_piccoli.png` | i pezzi piccoli di WB-022: stile e grandezza da copiare |
| R2 | `art/WB-029/riferimenti/R2_piastre.png` | le piastre di WB-022: lo stile |
| R3 | `art/WB-029/riferimenti/R3_lingotto.png` | il lingotto di WB-022: lo stile |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto: il
primo è "image 1", il secondo "image 2", il terzo "image 3". Sfondo verde pieno `#00FF00`.

| Nome file | Cosa c'è | Riferimenti | Formato | Varianti |
|---|---|---|---|---|
| `pezzo_segni` | stella accesa e spenta, medaglia, ingranaggio, corona, freccia | R1, R2, R3 | largo | 2 |
| `pezzo_barre` | guscio della barra, riempimento di brace e di gelo, tacca accesa e spenta | R1, R2, R3 | largo | 2 |
| `pezzo_tondi` | cornice tonda di ferro, d'oro e di ghiaccio (sigilli, misure), linguetta dell'assetto | R1, R2, R3 | largo | 2 |

### `pezzo_segni`

```
Images 1, 2 and 3 show pieces of the same game interface and are the STYLE to copy exactly: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow per piece, soft hand-drawn slightly crooked shapes, like a cartoon comic. Dark iron is #2B2530 with highlight #6B6375, ember is #F26419 to #FFB703, ivory is #F4ECE1, ice is #38B6FF with highlight #CAF0F8.

Draw a sheet with SIX separate small pieces, in two rows of three, all about the same size:
1. a five-pointed star, lit: chunky, soft rounded points, slightly crooked, gold (#FFB703) with one flat lighter highlight (#FFE08A) on the upper left and one flat darker band (#F26419) at the bottom;
2. the same star, unlit: same shape, dark iron (#2B2530) with a small flat highlight (#6B6375);
3. a round medal: a gold disc with a simple small flame embossed in the middle and a short red ribbon (#FF3B4E) with two tails on top;
4. a gear wheel with eight chunky rounded teeth and a round hole, ivory (#F4ECE1) with one flat grey shadow;
5. a small crown with three soft points, dark iron with a thin gold band at the base;
6. a chunky arrowhead pointing right (a thick chevron), ivory with one flat grey shadow.

Thick black ink outline on every piece, cartoon comic style, same line weight as images 1-3. No texture, no soft gradients, no realistic lighting, no glow, no drop shadow. No text, letters or numbers. Flat pure green background (#00FF00). The pieces are well separated from each other with green between them, none touching, none cut by the border of the picture.
```

### `pezzo_barre`

```
Images 1, 2 and 3 show pieces of the same game interface and are the STYLE to copy exactly: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow per piece, soft hand-drawn slightly crooked shapes, like a cartoon comic. Dark iron is #2B2530 with highlight #6B6375, ember is #F26419 to #FFB703, ivory is #F4ECE1, ice is #38B6FF with highlight #CAF0F8.

Draw a sheet with FIVE separate pieces, stacked one under the other with green between them:
1. a long empty bar housing, about ten times wider than tall: a hollow trough of dark iron (#2B2530), rounded slightly crooked ends, the inside darker (#141116) and completely empty, a thin flat highlight (#6B6375) on the top lip, one rivet at each end;
2. a long plain strip of the same length, a bit thinner, ember: flat #FFB703 with a thin lighter band (#FFE08A) on top and a darker band (#F26419) at the bottom, rounded ends, no rivets;
3. the same strip in ice: flat #38B6FF with a thin lighter band (#CAF0F8) on top and a darker band (#1D6FA8) at the bottom, the right end cut sharp like a shard;
4. a small slanted notch, like a short leaning tile about twice as tall as wide, ivory (#F4ECE1) with one flat shadow;
5. the same notch in dark iron (#2B2530) with a small highlight.

Thick black ink outline on every piece, cartoon comic style, same line weight as images 1-3. No texture, no soft gradients, no realistic lighting, no glow, no drop shadow. No text, letters or numbers. Flat pure green background (#00FF00). The pieces are well separated from each other with green between them, none touching, none cut by the border of the picture.
```

### `pezzo_tondi`

```
Images 1, 2 and 3 show pieces of the same game interface and are the STYLE to copy exactly: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow per piece, soft hand-drawn slightly crooked shapes, like a cartoon comic. Dark iron is #2B2530 with highlight #6B6375, ember is #F26419 to #FFB703, ivory is #F4ECE1, ice is #38B6FF with highlight #CAF0F8.

Draw a sheet with FOUR separate pieces, in two rows of two:
1. a round medallion frame: a thick slightly crooked ring of dark iron (#2B2530) with highlight (#6B6375), four small rivets, the inside a flat darker disc (#141116), completely empty;
2. the same medallion with the ring in gold (#FFB703, lighter band #FFE08A, darker band #F26419), the inside the same flat dark disc, empty;
3. the same medallion with the ring in ice (#38B6FF, highlight #CAF0F8), slightly angular outside like chipped ice, the inside the same flat dark disc, empty;
4. a small squarish tab plate of dark iron, a bit wider than tall, soft crooked corners, one corner cut, one rivet, the middle plain and empty.

Thick black ink outline on every piece, cartoon comic style, same line weight as images 1-3. No texture, no soft gradients, no realistic lighting, no glow, no drop shadow. No text, letters or numbers. Flat pure green background (#00FF00). The pieces are well separated from each other with green between them, none touching, none cut by the border of the picture.
```

Le varianti si chiamano `pezzo_segni_1.png`, `pezzo_segni_2.png` e così via, in `art/WB-029/`.

## Criteri di accettazione

- Ogni pezzo ha la china spessa come quelli di R1, colori pieni, niente sfumature morbide.
- I pezzi sono staccati fra loro e dal bordo, su verde pieno.
- L'interno di cornici, guscio della barra e linguetta è vuoto e di un colore solo.
- La stella accesa e quella spenta hanno la stessa forma; così le due tacche e le tre cornici.
- Niente scritte, lettere o numeri.

## Dopo le immagini (lo fa Claude)

- Guarda ogni foglio, sceglie la variante migliore per pezzo e scarta quelle con difetti.
- Li taglia con `tools/grafica/fucina.py` (atlante `fucina`) e li monta in `client/ui/kit.lua`
  e `client/ui/ui.lua` al posto di stelle, medaglia, rotella, barre, tacche, sigilli e linguette.
- Prova i menu nel simulatore a 1280x720, 1600x720, 960x720 e a doppia risoluzione.

## Decisione

Reversibile (solo immagini nuove in un ramo): approvata da Claude su richiesta di Sergio.

## Consegna di Codex

### 2026-11-12

Sei fogli generati con lo strumento integrato da `main` aggiornato
(`4d911bf1`). Ogni tentativo ha usato il prompt integrale della scheda
e R1, R2, R3 in quest'ordine.

File in `art/WB-029/`. Ogni nome indica un PNG RGB originale e un TXT
omonimo con il prompt e i riferimenti.

| Nome | Tentativi | Tentativo consegnato |
|---|---:|---:|
| `pezzo_segni_1` | 3 | 1 |
| `pezzo_segni_2` | 3 | 3 |
| `pezzo_barre_1` | 3 | 1 |
| `pezzo_barre_2` | 3 | 3 |
| `pezzo_tondi_1` | 3 | 1 |
| `pezzo_tondi_2` | 3 | 2 |

**Verifiche.** Ho controllato a vista i contorni, i colori, la disposizione
e l'assenza di scritte e ombre a terra. Nei fogli selezionati ci sono
rispettivamente sei segni, cinque pezzi per le barre e quattro pezzi
nel foglio dei tondi. I pezzi sono separati e c'è margine verde su tutti
i lati. Gli interni di gusci e cornici sono scuri e privi di simboli.
Stelle e tacche abbinate hanno sagome simili, con piccole differenze.

**Scostamenti.** I prompt integrali non specificano il formato largo
indicato nella tabella. Il generatore integrato non espone un parametro
per imporlo. I sei PNG selezionati sono quadrati, da 1254 × 1254 px,
dopo tre tentativi per variante. Lo sfondo è verde acceso, ma i campioni
prevalenti sono circa RGB (3–4, 249–250, 3–6), rispetto a `#00FF00`.
Il guscio è largo circa 6,4 volte la sua altezza, rispetto alle dieci
del prompt. Le tacche sono meno slanciate del previsto. Le cornici in
ghiaccio hanno un bordo più angolare e `pezzo_tondi_1` ha un piccolo
segno sulla linguetta.

Ho conservato i PNG originali per la selezione e il ritaglio.
Il ritaglio automatico, la corrispondenza esatta della tavolozza e la
resa dei pezzi nel gioco restano da verificare.

## Resoconto di Claude
