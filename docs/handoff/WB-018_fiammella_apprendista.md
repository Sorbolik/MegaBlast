# WB-018 · La fiammella dell'apprendista

- **Stato:** APPROVATA
- **Data:** 2026-11-08
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-018`

## Obiettivo

L'apprendista è nato con una caratteristica distintiva fondamentale: una fiammella viva tra le corna sulla sommità del capo (visibile chiaramente nel concept originale `R1_apprendista_concept.png` in tutte e tre le pose). Questa feature è andata persa per errore durante le modifiche del 2 novembre.

Questa scheda fa generare a Codex (ChatGPT) la fiammella isolata, nello stile grafico pulito del gioco (colori piatti, contorno nero spesso, nessuna sfumatura), pronta per essere montata come pezzo animabile sopra la testa dell'apprendista sia nell'editor delle animazioni che nel gioco vero e proprio.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-018/riferimenti/R1_apprendista_concept.png` | Il concept originale dell'apprendista in 3 pose: **mostra esattamente la fiammella arancione e gialla sopra la testa, tra le corna** |
| R2 | `art/WB-018/riferimenti/R2_apprendista_tre_quarti.png` | Il modello tre quarti ufficiale dell'apprendista oggi nel gioco: proporzioni della testa, corna e resa grafica pulita |
| R3 | `art/WB-018/riferimenti/R3_espressioni.png` | Le teste approvate: punto di innesto tra le corna |

## Immagini da generare

I prompt sono scritti in inglese per il generatore. Codex deve eseguirli sul ramo `design/WB-018` salvando le immagini in `art/WB-018/` con accanto il file `.txt` con il prompt.

| Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|
| `1_fiammella_base` | R1, R2 | 1024×1024 quadrato | 2 |
| `2_foglio_fiammelle` | R1, R2 | 1536×1024 orizzontale (o 1024×1024) | 1 |

---

### `1_fiammella_base`

```
Image 1 is the original concept art of our game's main character, a little red imp blacksmith apprentice: look ONLY at the small fiery flame on top of his head between his horns in the first pose on the left.
Image 2 is the official in-game character model: it shows the exact clean cartoon art style (thick black outline, flat cel colors, no gradients, no texture, no glow).

Draw ONLY the FLAME piece from Image 1, completely isolated, centered in the image, as a cutout game asset ready to be placed on top of his head.
The flame is lively, rising upward with sharp curling flame tongues, curving slightly to the right, exactly as seen in the left figure of Image 1.
The base at the bottom of the flame is rounded and clean, with a closed black outline, so it can rest right between his horns on the crown of his skull. Do NOT draw the head, horns or body: draw ONLY the flame itself.

Rendering rules, very strict, because this drawing will be traced into vector shapes:
- FLAT CEL COLORS ONLY: every area is one solid pure color, plus at most one hard-edged shadow shape in a darker tone. Absolutely NO gradients, NO glow, NO blur, NO smoke, NO particle sparks, NO textures, NO soft shading.
- Thick, clean, closed pure-black #000000 outline of even weight around the entire flame silhouette, with thinner inner black lines separating flame tongues.
- Palette:
  - Outline: pure black #000000
  - Outer flame body: bright vibrant fiery orange #FF7A29 (or #E5532D)
  - Inner core flame: bright warm yellow #FFF066 (or #F2C45A)
  - Hard-edged shadow: dark red-orange #B8432A
- Background: flat pure magenta #FF00FF everywhere, with no halo around the flame.
- No text, labels, arrows or signatures. Square format 1:1.
```

---

### `2_foglio_fiammelle`

```
Image 1 is the original concept art of our game's main character, a little red imp apprentice: look at the three different poses showing his head flame in different states of motion (pose 1: standing still; pose 2: running with flame trailing back; pose 3: leaping with vigorous flame).
Image 2 is the official character model showing the clean graphic style (flat colors, thick black outline).

Draw a SPRITE SHEET of FOUR distinct flame pieces side by side in a single horizontal row, well separated from each other, on a flat pure magenta #FF00FF background.
All four flames are sized to fit on top of the character's head between the horns, seen in three-quarter angle pointing to the right:
1) IDLE (fermo): upright lively flame with upward tongues and a small secondary tongue, confident and steady, as in pose 1 of Image 1.
2) RUNNING (corsa): flame stretched and tilted back to the left at about 45 degrees, blown by the wind of his run, dynamic and sleek, as in pose 2 of Image 1.
3) VIGOROUS / JUMP (salto): larger energetic roaring flame with multiple sharp crests, leaping upward, as in pose 3 of Image 1.
4) SURPRISE / IMPACT (colpito): smaller compact flame or straight candle-like flame popping straight up.

Each flame must be completely isolated, with a clean closed rounded base at the bottom where it connects to the skull. NO heads, horns or bodies drawn.

Rendering rules, very strict:
- FLAT CEL COLORS ONLY: solid pure colors with sharp shadow shapes. Absolutely NO gradients, NO glow halos, NO smoke trails, NO particles, NO soft shading.
- Thick, clean, closed pure-black #000000 outline around each flame.
- Palette: outline black #000000; outer flame fiery orange #FF7A29; inner flame bright warm yellow #FFF066; shadow red-orange #B8432A.
- Background: flat pure magenta #FF00FF everywhere, no halos.
- Landscape format, well spaced, no text, labels or numbers.
```

---

## Criteri di accettazione

- [ ] Contorno nero spesso (`#000000`), pulito, continuo e chiuso attorno alla sagoma di ogni fiamma.
- [ ] Colori piatti puri (giallo interno, arancione fuoco esterno, ombra rosso mattone): nessun gradiente, nessun alone di bagliore (glow) o fumo.
- [ ] Base della fiammella chiusa e arrotondata per innestarsi alla sommità del cranio tra le corna.
- [ ] Sfondo magenta uniforme `#FF00FF` senza aloni attorno ai bordi neri.
- [ ] Nessuna scritta, etichetta o watermark.

---

## Decisione

Approvata da Claude su richiesta di Sergio (2026-11-08).

## Consegna di Codex

2026-11-08 · Eseguita la scheda APPROVATA dal `main` aggiornato, sul ramo `design/WB-018`, con imagegen integrato. Prompt integrali invariati e riferimenti R1, R2 allegati in questo ordine. Sfondo magenta richiesto dalla scheda, non trasparente.

File consegnati in `art/WB-018/`:
- `1_fiammella_base_1.png` e `.txt`;
- `1_fiammella_base_2.png` e `.txt`;
- `2_foglio_fiammelle.png` e `.txt`.

Controllo visivo effettuato su tutte le prove: solo fiamme, nessuna testa o corpo, nessuna scritta, contorni neri spessi e basi chiuse; le quattro pose del foglio sono distinte e separate. Tre generazioni complessive del prompt base: consegnate le prime due come varianti, terza scartata perché non migliora i difetti. Tre tentativi del foglio: consegnato il secondo, gli altri non migliorano le difformità. Nessun ritocco o ricalco.

**Limiti: consegna non pienamente conforme ai criteri di accettazione.** Restano leggere variazioni/texture nei riempimenti, anziché colori perfettamente piatti; la punta principale delle basi curva a sinistra anziché a destra. Il foglio conserva una lingua secondaria staccata nella prima posa. Il generatore ha restituito basi di 1254×1254 e foglio di 2172×724, non le misure della scheda; originali conservati senza deformazioni. Anche lo sfondo non è magenta puro: pixel d'angolo RGB (243,14,241), (243,16,241) e (242,16,242) rispettivamente, anziché (255,0,255). Non è stata certificata l'uniformità di tutti i pixel o l'esattezza dell'intera palette. Da rivedere da Claude prima del ricalco e dell'integrazione.

Non verificati montaggio sulla testa, resa alle dimensioni del gioco e animazione. Nessuna modifica al gioco. La scheda ripristina la fiammella mentre `DECISIONI.md` contiene ancora la rimozione del 2 novembre: discrepanza segnalata, documento lasciato invariato.


## Resoconto di Claude

2026-11-08 · Revisione, ricalco vettoriale e integrazione nel gioco e nell'editor.

1. **Revisione della consegna di Codex**:
   - Immagini esaminate: `1_fiammella_base_1.png`, `1_fiammella_base_2.png`, `2_foglio_fiammelle.png`.
   - Come segnalato da Codex, la punta principale curvava a sinistra; specchiando orizzontalmente `1_fiammella_base_1` si ottiene l'orientamento esatto del concept originale R1 (punta che curva leggermente verso destra/indietro rispetto al verso di marcia a tre quarti).
2. **Ricalco vettoriale e asset di gioco**:
   - Sfondo magenta rimosso con soglia pulita;
   - Tracciamento delle curve con Potrace (`strumenti/stampino/pelli/svg/apprendista_fiamma.svg`) a quattro strati sovrapposti: sagoma corpo arancione fuoco (`#FF7A29`), ombra rosso mattone (`#B8432A`), nucleo giallo caldo (`#FFF066`) e contorno nero continuo (`#000000`);
   - Renderizzato l'asset raster pulito `client/assets/skins/apprendista_fiamma.png` (95×111 px) per Defold e registrato in `client/battle/devil.atlas`;
   - Registrato il pezzo `fiamma` in `strumenti/stampino/pelli/apprendista.json`.
3. **Editor animazioni e schiaccia/allunga per effetto fuoco**:
   - Aggiunti canali di animazione in `client/battle/pose.lua`, `client/battle/scoria.lua` e `strumenti/animazioni/editor.html`:
     - `fiamma_schiaccia`: controllo rapido schiaccia/allunga mantenendo il volume (valori da 0.1 a 4.0, neutro 1);
     - `fiamma_scala_x`: controllo indipendente della larghezza (valori da 0.1 a 4.0, neutro 1);
     - `fiamma_scala_y`: controllo indipendente dell'altezza (valori da 0.1 a 4.0, neutro 1);
   - Il giunto `s.fiamma` scala dal perno alla base sulla testa, permettendo di allungare, appiattire e far pulsare la fiammella frame per frame;
   - Editor ricompilato tramite `prepara.py`.

2026-11-09 · Fiammella viva (Claude). Il ricalco Potrace di sopra veniva quasi tutto rosso mattone (lo strato d'ombra copriva l'arancio): rifatta direttamente da `1_fiammella_base_2.png` (scontorno del magenta col bordo antialias, nessun alone), in `client/paintings/flame/apprendista.png` (256 x 256, con spazio per ondeggiare) per lo shader `client/battle/flame.fp` e ritagliata in `apprendista_fiamma.png` per l'editor (pezzo 38,3 x 54, le proporzioni del disegno). Nessuna immagine nuova da chiedere a Codex.
