# WB-054 · Altre tre direzioni per il pulsante primario dei menu

- **Stato:** CONSEGNATA E INTEGRATA (Sergio, 15 nov 12:34: sceglie E · gemma)
- **Data:** 2026-11-15
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-054`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-054` senza chiedere conferma (il repository è privato).

## Obiettivo

Il pulsante primario dei menu ora è la C di WB-052 («brace e gelo»): una piastra d'oro con le fiamme in basso a
sinistra e il ghiaccio in alto a destra, in tre stati (acceso, premuto, spento). È già nel gioco (R1).
Sergio lo tiene ma vuole **altre tre direzioni** da confrontare, diverse da quella, dalle altre due di WB-052
(colata d'oro con la goccia, piastra a freccia coi rivetti) e dal sigillo fuso di GIOCA online (R5).

Valgono le stesse regole:
- un pulsante solo, uguale in ogni schermata, con acceso, premuto e spento;
- lo spento si legge spento a colpo d'occhio: freddo, senza fuoco, non solo più grigio.

## Come devono essere fatti

- Pulsante largo, circa tre volte e mezzo più largo che alto, con il **mezzo liscio e vuoto**: il gioco ci scrive
  l'azione in nero e lo allunga solo nel mezzo (tre parti).
- Stile dei pulsanti di WB-046 (R2, R3):
  - china spessa e un po' irregolare;
  - colori pieni, una luce e un'ombra piatte;
  - forme morbide un po' storte.
- Il fuoco sta in basso a sinistra e il ghiaccio in alto a destra (regola del «Filo di brace»).
- Ricalcabili in vettori: al massimo sei colori per pezzo, niente più sottile della china.
- Deve essere il pezzo più forte della schermata, ma diverso dal sigillo e dalle direzioni di WB-052.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-054/riferimenti/R1_primario_oggi.png` | una schermata di oggi: il pulsante GIOCA in basso a destra |
| R2 | `art/WB-054/riferimenti/R2_porta_campagna.png` | pulsante CAMPAGNA di WB-046: lo stile |
| R3 | `art/WB-054/riferimenti/R3_porta_armeria.png` | pulsante ARMERIA di WB-046: lo stile, il ghiaccio |
| R4 | `art/WB-054/riferimenti/R4_brace_gelo_scelto.png` | il pulsante scelto (WB-052 C): da NON rifare |
| R5 | `art/WB-054/riferimenti/R5_gioca_sigillo.png` | il sigillo fuso: da NON copiare |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto. Misura 1536×1024 per tutti.

| Nome file | Direzione | Riferimenti | Varianti |
|---|---|---|---|
| `primario_tizzone` | D · asse che brucia | R1, R2, R3, R4, R5 | 2 |
| `primario_gemma` | E · gemma di brace | R1, R2, R3, R4, R5 | 2 |
| `primario_crosta` | F · pietra con la lava dentro | R1, R2, R3, R4, R5 | 2 |

Le varianti si chiamano `primario_tizzone_1.png`, `primario_tizzone_2.png` e così via, in `art/WB-054/`.
Per ogni foglio Codex scrive un `.txt` con lo stesso nome.

### `primario_tizzone`

```
Image 1 is a menu screen of our game: the button at the bottom right is the main action button of every menu. Images 2 and 3 are two menu buttons of the same game and are the STYLE to copy exactly: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, soft hand-drawn slightly crooked shapes, like a cartoon comic. Image 4 is the main button we use today and image 5 is another button: both must NOT be copied, we want a different idea.

Draw a new MAIN ACTION BUTTON as a thick BURNING WOODEN PLANK: a wide chunky plank about three and a half times wider than tall, its face of warm light wood (#E0A060, highlight #F2C48A, shadow #B8743C) with a few short dark grain lines only near its two ends, its bottom-left corner charred black (#2B2530) with glowing ember cracks (#F26419, #FFB703) and three fat flame tongues rising from it; its top-right corner covered by a cap of thick snow and frost (#CAF0F8) with two small icicles (#38B6FF) hanging from the top edge. The middle of the plank is plain and even, with nothing on it, so text can be written there and the plank can be stretched in width.

Draw it THREE times on the sheet, one above the other, with green space between them:
1. LIT: as described;
2. PRESSED: the same plank pushed down: a bit flatter, the wood darker (#C98A4E), the flames smaller;
3. OFF: the same plank burnt out and frozen: grey ash wood (#6B6375, highlight #8C929C), the charred corner cold with no embers and no flames, the frost spread over the whole right half.

Thick black ink outline on every piece, cartoon comic style like images 2 and 3. Flat colors only, at most six per piece, no detail thinner than the outline, so the pieces can be traced into vectors. No texture, no soft gradients, no glow halo, no drop shadow. No text, letters or numbers. Flat pure green background (#00FF00). The pieces are well separated, none touching, none cut by the border of the picture.
```

### `primario_gemma`

```
Image 1 is a menu screen of our game: the button at the bottom right is the main action button of every menu. Images 2 and 3 are two menu buttons of the same game and are the STYLE to copy exactly: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, soft hand-drawn slightly crooked shapes, like a cartoon comic. Image 4 is the main button we use today and image 5 is another button: both must NOT be copied, we want a different idea.

Draw a new MAIN ACTION BUTTON as a long cut EMBER GEM: a wide flat faceted gem about three and a half times wider than tall, its ends cut in a few big soft facets, its large front face flat and even, of glowing orange (#F26419) with a broad lighter top facet (#FFB703), a thin bright spark highlight (#FFE08A) and a darker bottom facet (#C2410C); a small flame flickers out of its bottom-left facet; a few sharp ice crystals (#38B6FF, #CAF0F8) grow on its top-right facet. The large front face in the middle is plain and even, with nothing on it, so text can be written there and the gem can be stretched in width.

Draw it THREE times on the sheet, one above the other, with green space between them:
1. LIT: as described;
2. PRESSED: the same gem pushed down: a bit flatter, the face darker (#D9520F), the flame smaller;
3. OFF: the same gem dead and frozen: dull grey-blue stone (#4A4550, top facet #6B6375), no flame, no glow colors at all, a crust of ice and frost (#CAF0F8, #38B6FF) grown over its whole top-right half.

Thick black ink outline on every piece, cartoon comic style like images 2 and 3. Flat colors only, at most six per piece, no detail thinner than the outline, so the pieces can be traced into vectors. No texture, no soft gradients, no glow halo, no drop shadow. No text, letters or numbers. Flat pure green background (#00FF00). The pieces are well separated, none touching, none cut by the border of the picture.
```

### `primario_crosta`

```
Image 1 is a menu screen of our game: the button at the bottom right is the main action button of every menu. Images 2 and 3 are two menu buttons of the same game and are the STYLE to copy exactly: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, soft hand-drawn slightly crooked shapes, like a cartoon comic. Image 4 is the main button we use today and image 5 is another button: both must NOT be copied, we want a different idea.

Draw a new MAIN ACTION BUTTON as a slab of dark VOLCANIC STONE WITH LAVA INSIDE: a wide rounded slab about three and a half times wider than tall, of dark stone (#3D3442, highlight #5A4E60) with a wide window in its middle where bright lava shows through (#FFB703, lighter top band #FFE08A, darker bottom edge #F26419), the window's edge a chunky rim of the same stone; at its bottom-left corner the lava breaks out through two cracks with small flames; at its top-right corner the stone is frosted (#CAF0F8) with a few small ice crystals (#38B6FF). The lava window in the middle is plain and even, with nothing on it, so text can be written there and the slab can be stretched in width.

Draw it THREE times on the sheet, one above the other, with green space between them:
1. LIT: as described;
2. PRESSED: the same slab pushed down: a bit flatter, the lava darker (#F0A800), the flames smaller;
3. OFF: the same slab cold and dead: the lava window turned to dull grey cooled rock (#6B6375, highlight #8C929C) with a few cracks, no flames, no glow colors at all, frost (#CAF0F8) spread over the whole right half.

Thick black ink outline on every piece, cartoon comic style like images 2 and 3. Flat colors only, at most six per piece, no detail thinner than the outline, so the pieces can be traced into vectors. No texture, no soft gradients, no glow halo, no drop shadow. No text, letters or numbers. Flat pure green background (#00FF00). The pieces are well separated, none touching, none cut by the border of the picture.
```

## Criteri di accettazione

- [ ] tre direzioni diverse fra loro, diverse dalle tre di WB-052 e dal sigillo fuso
- [ ] per ogni direzione acceso, premuto e spento
- [ ] lo spento si legge spento a colpo d'occhio (freddo, senza fuoco)
- [ ] mezzo liscio e vuoto, si allunga in larghezza
- [ ] colori pieni, china spessa, si ricalcano in vettori
- [ ] sfondo verde pieno, niente scritte, pezzi staccati

## Dopo le immagini (lo fa Claude)

- Ritaglia le tre direzioni e le monta su una schermata vera (allenamento, armeria, zaino), insieme a quella di
  oggi, e le mostra a Sergio una accanto all'altra.
- Se Sergio ne sceglie una nuova, la mette in `kit.action` (atlante fucina, `primario_*`) al posto di quella di oggi.

## Decisione

Reversibile (solo immagini in un ramo): approvata su richiesta di Sergio.

## Resoconto di Claude

- Arrivati i sei fogli (due varianti per direzione), tutti puliti: acceso, premuto e spento ben staccati, sfondo verde pieno, niente scritte.
- Ritagliati `primario_tizzone_2`, `primario_gemma_2` e `primario_crosta_1` (le varianti con le proporzioni più vicine a tre e mezzo per uno) in `art/WB-054/ritagli/`.
- Montati nel gioco vero accanto alla C di WB-052 su armeria, zaino e gioca online (`/mnt/project-files/menu_14nov/WB-054_confronto_primari.png`).
- Sergio sceglie la **E · gemma**: ora è il pulsante primario di tutti i menu (`tools/grafica/fucina.py`; `PRIMARIO=tizzone`, `crosta` o `brace` per rivedere le altre).
