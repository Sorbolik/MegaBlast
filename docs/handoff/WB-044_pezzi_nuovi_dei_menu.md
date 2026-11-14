# WB-044 · I pezzi nuovi dei menu riorganizzati

- **Stato:** APPROVATA (Sergio, 14 nov: «qualsiasi cosa nuova che abbiamo concepito facciamola fare a codex in una scheda fatta per bene»)
- **Data:** 2026-11-14
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-044`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-044` senza chiedere conferma (il repository è privato).

## Obiettivo

Sergio ha scelto la proposta consigliata per ogni schermata dei menu riorganizzati (home,
ZAINO (nelle bozze ancora CORREDO) con inventario e sigilli, ARMERIA con potenzia e bottega, GIOCA ONLINE, EVENTI con la
classifica mondiale, PROFILO con statistiche e cronologia partite: R4, e nel Figma la sezione
«RIORGANIZZAZIONE MENU · 14 nov»). Nelle bozze ogni pezzo nuovo è disegnato a mano da Claude
con rettangoli piatti: caselle dell'inventario, tondi del livello, spunta, cartellino dello
sconto, righe della classifica e della cronologia, podio, cartellino sopra la testa, pillola
della coda, finestra a comparsa, icone delle sezioni e delle modalità. Servono tutti **nello
stile di WB-022 e WB-029**, come pezzi staccati che il gioco monta.

Le icone dei pezzi e il buono del Fabbro sono in WB-043; i pulsanti grandi della home in WB-045.
Lingotto, piastre, piastrine (schede e filtri), pannelli, monete, barre, stelle, corona e
cornici tonde di ferro e d'oro ci sono già (WB-022, WB-029): non vanno rifatti.

## Pezzi che crescono senza perdere qualità

Ogni pezzo deve restare perfetto su ogni schermo (Sergio, 14 nov): a 1280x720, a doppia
risoluzione e su un tablet. Perciò:

- **Disegnati grandi:** ogni pezzo riempie bene la sua cella del foglio, mai piccolo in un angolo.
- **Ricalcabili in vettori:** solo colori pieni (al massimo quattro o cinque per pezzo), china
  chiusa e spessa, nessun dettaglio più sottile della china. Claude li ricalca in SVG e li
  esporta alla misura giusta per ogni schermo, e può rifarli più grandi senza sgranare.
- **Si allungano senza deformarsi:** barre, righe, cartellini e cornici hanno il mezzo liscio e
  uguale (si allunga solo quello, 3 o 9 parti come le piastre); le parti che non si allungano
  (punte, rivetti, angoli) stanno solo alle estremità o negli angoli.
- **Interno vuoto:** dentro cornici, righe e finestre non c'è niente: testi, numeri e icone li
  mette il gioco.
- **Icone di un colore solo:** le icone sono avorio con un'ombra piatta, così il gioco le tinge.

## Cosa teniamo e cosa scartiamo

| Teniamo | Perché |
|---|---|
| China spessa e un po' irregolare, colori pieni, una luce e un'ombra piatte | è lo stile approvato di WB-022 e WB-029 (R1, R2, R3) |
| Forme morbide e un po' storte | «forme morbide, non simmetriche» (Sergio) |
| Ferro scuro, brace, avorio, ghiaccio | fuoco contro ghiaccio in ogni schermata |
| Interni vuoti e mezzi lisci | il gioco scrive e allunga |

| Scartiamo | Perché |
|---|---|
| Texture, sfumature morbide, bagliori, 3D, ombre a terra | non si ricalcano in vettori e non sono lo stile |
| Scritte, lettere, numeri | li mette il gioco |
| Pezzi che si toccano o tagliati dal bordo | il gioco li ritaglia uno per uno |

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-022/pezzo_piccoli.png` | pezzi piccoli di WB-022: stile, china, grandezza |
| R2 | `art/WB-029/pezzo_segni_1.png` | stelle, medaglia, corona di WB-029: lo stile delle icone |
| R3 | `art/WB-022/pezzo_pannello.png` | il pannello di WB-022: lo stile delle cornici |
| R4 | `art/WB-044/riferimenti/R4_bozze_menu.jpg` | le nove schermate scelte: dove va ogni pezzo |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto: il
primo è "image 1", il secondo "image 2" e così via. Misura 1536×1024 per tutti.

| Nome file | Cosa c'è | Riferimenti | Varianti |
|---|---|---|---|
| `pezzo_caselle` | casella dell'inventario (ferro, brace, vuota), tondo del livello (ferro, oro), spunta, cartellino dello sconto, gemma della famiglia | R1, R3, R4 | 2 |
| `pezzo_righe` | riga scura, riga d'oro, bordino brace e ghiaccio, pillola della coda, cartellino sopra la testa con la sua punta, chiodo della linea | R1, R3, R4 | 2 |
| `pezzo_podio` | tre gradini del podio (oro, argento, bronzo), cornici tonde d'argento e di bronzo | R1, R3, R4 | 2 |
| `pezzo_finestra` | finestra a comparsa, nastro del titolo, pulsante chiudi, fumetto con punta, pallino degli avvisi | R1, R3, R4 | 2 |
| `icone_sezioni` | dodici icone: inventario, sigilli, potenzia, bottega, statistiche, cronologia, calendario, classifica, 2 contro 2, stanza privata, rivedi, orologio | R2, R1, R4 | 2 |

Le varianti si chiamano `pezzo_caselle_1.png`, `pezzo_caselle_2.png` e così via, in
`art/WB-044/`. Per ogni foglio Codex scrive un `.txt` con lo stesso nome: cosa ha fatto e cosa
non è riuscito a rispettare.

### `pezzo_caselle`

```
Images 1 and 2 show pieces of the same game interface and are the STYLE to copy exactly: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow per piece, soft hand-drawn slightly crooked shapes, like a cartoon comic. Dark iron is #2B2530 with highlight #6B6375, ember is #F26419 to #FFB703, ivory is #F4ECE1, ice is #38B6FF with highlight #CAF0F8. Image 3 is a mock-up of the game's menus: the squares of the inventory, the small level discs on their corner, the check mark on worn pieces and the discount tags are drawn there as plain placeholders, these pieces replace them.

Draw a sheet with EIGHT separate pieces, in two rows of four, each one large and filling its cell:
1. a square inventory slot frame: a thick square ring of dark iron (#2B2530) with soft slightly crooked corners, a thin flat highlight (#6B6375) on the top edge, a small rivet in each corner; the inside is a flat darker square (#141116), completely empty. The four sides are plain and even, so the frame can be stretched.
2. the same slot frame, SELECTED: same shape, the ring in ember (#F26419 with a lighter band #FFB703 on top), the inside the same flat dark square, empty.
3. the same slot frame, EMPTY SLOT: same shape, the ring in a duller iron (#3A3540) without rivets, the inside a flat #1C181F, empty; it must look quiet.
4. a small round level disc: a chunky dark iron coin (#2B2530, highlight #6B6375), the middle flat and empty for a number.
5. the same level disc in gold (#FFB703, lighter band #FFE08A, darker band #F26419), the middle flat and empty.
6. a round check badge: a gold disc (#FFB703) with a chunky dark (#141116) check mark shape in the middle.
7. a discount tag: a short ember ribbon (#F26419, lighter band #FFB703) about three times wider than tall, the right end cut like a swallow tail, a small hole with a rivet at the left end, the middle plain and empty for a number.
8. a small faceted gem, ivory (#F4ECE1) with two flat facet shadows (#C9BFB2), shaped like a short rounded diamond.

Thick black ink outline on every piece, cartoon comic style, same line weight as images 1-2. Flat colors only, at most five per piece, no detail thinner than the outline, so the pieces can be traced into vectors. No texture, no soft gradients, no realistic lighting, no glow, no drop shadow. No text, letters or numbers. Flat pure green background (#00FF00). The pieces are well separated from each other with green between them, none touching, none cut by the border of the picture.
```

### `pezzo_righe`

```
Images 1 and 2 show pieces of the same game interface and are the STYLE to copy exactly: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow per piece, soft hand-drawn slightly crooked shapes, like a cartoon comic. Dark iron is #2B2530 with highlight #6B6375, ember is #F26419 to #FFB703, ivory is #F4ECE1, ice is #38B6FF with highlight #CAF0F8. Image 3 is a mock-up of the game's menus: the rows of the world ranking and of the match history, the queue pill at the bottom of the home, the name tag above the little devil's head and the lines that point to his body are drawn there as plain placeholders, these pieces replace them.

Draw a sheet with EIGHT separate pieces, each one large:
1. a long table row strip, about eight times wider than tall: a flat dark iron plate (#2B2530) with soft slightly crooked rounded ends, a thin flat highlight (#6B6375) along the top edge, the middle plain, even and empty so it can be stretched;
2. the same row strip in gold, for the player's own row: #FFB703 with a lighter band (#FFE08A) on top and a darker band (#F26419) at the bottom, plain and empty;
3. a short vertical edge tab in ember (#F26419, lighter band #FFB703), as tall as the row strip and about a fifth as wide, rounded on the left side and straight on the right side (it is glued to the left end of a row to mark a victory);
4. the same edge tab in ice (#38B6FF, highlight #CAF0F8), its left side slightly angular like chipped ice (it marks a defeat);
5. a capsule pill, about five times wider than tall: dark iron (#2B2530) with fully rounded ends, a thin highlight on top, a small round ember dot (#F26419) near the left end, the rest plain and empty;
6. a name plate: an ivory (#F4ECE1) plate about four times wider than tall, soft slightly crooked corners, one flat shadow band (#C9BFB2) at the bottom, the middle plain and empty;
7. the small pointer that hangs under that name plate: a short chunky ivory triangle pointing down, with the same shadow, its top edge flat so it can sit under the plate;
8. a round iron rivet head, dark iron (#2B2530) with a small flat highlight (#6B6375), the end of a pointing line.

Thick black ink outline on every piece, cartoon comic style, same line weight as images 1-2. Flat colors only, at most five per piece, no detail thinner than the outline, so the pieces can be traced into vectors. No texture, no soft gradients, no realistic lighting, no glow, no drop shadow. No text, letters or numbers. Flat pure green background (#00FF00). The pieces are well separated from each other with green between them, none touching, none cut by the border of the picture.
```

### `pezzo_podio`

```
Images 1 and 2 show pieces of the same game interface and are the STYLE to copy exactly: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow per piece, soft hand-drawn slightly crooked shapes, like a cartoon comic. Dark iron is #2B2530 with highlight #6B6375, ember is #F26419 to #FFB703, ivory is #F4ECE1, ice is #38B6FF with highlight #CAF0F8. Image 3 is a mock-up of the game's menus: in the EVENTI screen (bottom left) the podium of the world ranking is drawn as plain placeholder boxes, these pieces replace it.

Draw a sheet with FIVE separate pieces, each one large:
1. the FIRST place pedestal: a tall forged block, a bit taller than wide, gold (#FFB703) top cap with a lighter band (#FFE08A), the front face dark iron (#2B2530) with a thin gold edge, the front face plain, even and empty (a number goes there), a few rivets only along the top cap;
2. the SECOND place pedestal: the same block a bit shorter, silver steel cap (#C9CED6, lighter band #F1F3F6, darker band #8C929C), dark iron front face with a thin silver edge, empty;
3. the THIRD place pedestal: the same block shorter still, bronze cap (#C67A3A, lighter band #E5A266, darker band #8A4E22), dark iron front face with a thin bronze edge, empty;
4. a round portrait frame: a thick slightly crooked ring of silver steel (#C9CED6, highlight #F1F3F6, shadow #8C929C) with four small rivets, the inside a flat dark disc (#141116), completely empty;
5. the same portrait frame in bronze (#C67A3A, highlight #E5A266, shadow #8A4E22), the inside empty.

The three pedestals have the same width and the same front-face design: only the height and the cap color change, and the front face is plain in the middle so it can be stretched upward.

Thick black ink outline on every piece, cartoon comic style, same line weight as images 1-2. Flat colors only, at most five per piece, no detail thinner than the outline, so the pieces can be traced into vectors. No texture, no soft gradients, no realistic lighting, no glow, no drop shadow. No text, letters or numbers. Flat pure green background (#00FF00). The pieces are well separated from each other with green between them, none touching, none cut by the border of the picture.
```

### `pezzo_finestra`

```
Images 1 and 2 show pieces of the same game interface and are the STYLE to copy exactly: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow per piece, soft hand-drawn slightly crooked shapes, like a cartoon comic. Dark iron is #2B2530 with highlight #6B6375, ember is #F26419 to #FFB703, ivory is #F4ECE1, ice is #38B6FF with highlight #CAF0F8. Image 3 is a mock-up of the game's menus; the game also needs a pop-up window (to confirm a purchase, to show a piece, to show a reward), drawn in the same style.

Draw a sheet with FIVE separate pieces, each one large:
1. a pop-up window frame, about one and a half times wider than tall: a thick dark iron border (#2B2530, highlight #6B6375 on the top edge) with soft slightly crooked corners, a forged corner bracket with one rivet in each of the four corners, the inside a flat dark area (#1C181F), completely empty. The four sides between the corner brackets are plain and even, so the window can be stretched in both directions.
2. a title ribbon that sits on the top edge of the window: an ember banner (#F26419, lighter band #FFB703) about five times wider than tall, both ends folded back with a darker fold (#B8440F) and cut like a swallow tail, the middle plain, even and empty.
3. a round close button: a dark iron disc (#2B2530, highlight #6B6375) with a chunky ivory (#F4ECE1) X shape in the middle.
4. a speech bubble for hints: an ivory plate (#F4ECE1, shadow band #C9BFB2) about three times wider than tall, soft crooked corners, with a short chunky pointer at the bottom left; the middle plain and empty.
5. a small round notice dot: a red disc (#FF3B4E) with a flat lighter spot (#FF8A96) on the upper left, the middle empty for a number.

Thick black ink outline on every piece, cartoon comic style, same line weight as images 1-2. Flat colors only, at most five per piece, no detail thinner than the outline, so the pieces can be traced into vectors. No texture, no soft gradients, no realistic lighting, no glow, no drop shadow. No text, letters or numbers. Flat pure green background (#00FF00). The pieces are well separated from each other with green between them, none touching, none cut by the border of the picture.
```

### `icone_sezioni`

```
Image 1 shows small icons of our game interface (star, medal, crown, gear) and is the STYLE to copy exactly: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, soft hand-drawn slightly crooked shapes, like a cartoon comic. Image 2 shows more pieces of the same interface. Image 3 is a mock-up of the game's menus: the tabs, the play modes and the buttons need these icons.

Draw an ICON SHEET of TWELVE separate icons, in a grid of 4 columns and 3 rows, each one large and centered in its cell. Every icon is a single bold silhouette in ivory (#F4ECE1) with ONE flat darker shadow shape (#C9BFB2) and a thick black outline, so the game can tint it; no other colors. Left to right, top to bottom:
1. INVENTORY: a small treasure chest with the lid open;
2. SEALS: a round wax seal stamp with a flame embossed on it;
3. UPGRADE: a smith's hammer with a chunky upward arrow behind it;
4. SHOP: a small market stall with a striped awning;
5. STATISTICS: three chunky bars of growing height on a short base;
6. MATCH HISTORY: an hourglass;
7. CALENDAR: a calendar page with two rings on top and a grid of four blank squares;
8. RANKING: a trophy cup with two handles;
9. TWO VERSUS TWO: two little horned devil heads side by side, seen from the front, simple silhouettes;
10. PRIVATE ROOM: a big old key;
11. REPLAY: a round button with a chunky play triangle inside;
12. CLOCK: a round clock face with two hands.

All twelve icons with the same line weight, the same size feeling and the same simple level of detail: they will be shown as small as 32 pixels and as big as 256 pixels, so no detail thinner than the outline. Flat colors only, no texture, no soft gradients, no glow, no drop shadow. No text, letters or numbers. Flat pure magenta background (#FF00FF), with wide magenta gaps between the icons, none touching, none cut by the border of the picture.
```

## Criteri di accettazione

- [ ] ogni pezzo ha la china spessa come R1, colori pieni (al massimo cinque), nessuna sfumatura morbida
- [ ] ogni pezzo è grande nella sua cella e si ricalca in vettori senza perdere niente
- [ ] i mezzi di righe, cartellini, pillola, cornici, finestra e gradini sono lisci e uguali
- [ ] gli interni sono vuoti e di un colore solo
- [ ] le tre caselle hanno la stessa forma; così i due tondi del livello, le due righe, i due bordini, i tre gradini, le due cornici
- [ ] le icone sono avorio con un'ombra sola, si leggono a 32 pixel
- [ ] pezzi staccati fra loro e dal bordo, sfondo pieno, niente scritte

## Dopo le immagini (lo fa Claude)

- Guarda ogni foglio, sceglie la variante migliore per pezzo e scarta quelle con difetti.
- Ricalca i pezzi in SVG e li esporta alla misura giusta (atlante `fucina`, `tools/grafica/fucina.py`;
  le icone nell'atlante delle icone), così si rifanno più grandi senza sgranare.
- Li monta nelle nove schermate del Figma al posto dei segnaposto, le rivede con Sergio, poi
  li porta nel gioco (`client/ui/kit.lua`, `client/ui/ui.lua`, i menu) e prova a 1280x720,
  1600x720, 960x720 e a doppia risoluzione.

## Decisione

Reversibile (solo immagini nuove in un ramo): approvata da Claude su richiesta di Sergio.

## Consegna di Codex

## Resoconto di Claude
