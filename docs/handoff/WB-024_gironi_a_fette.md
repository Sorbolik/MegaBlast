# WB-024 · I gironi a fette per la mappa della campagna

- **Stato:** APPROVATA (Sergio, 2026-11-12: «farei rifare a codex anche i gironi, li vorrei come fette, non come linee»)
- **Data:** 2026-11-12
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-024`

## Obiettivo

Nella mappa della campagna l'inferno è un imbuto di nove gironi, uno sotto l'altro. Nella
proposta (https://claude.ai/artifact/2RBh8w9T56E7P9kFDd4HKA) sono ellissi a linea: Sergio li
vuole **a fette**, cioè ogni girone un disco spesso, con la faccia di sopra e il bordo, impilati
dal più largo al più stretto, disegnati a fumetto come i pezzi di WB-022. In alto caldi (la
Forgia è sopra), in fondo di ghiaccio (lì sta Favilla).

Servono due cose: l'**imbuto intero** (per decidere l'aspetto e per la vista da lontano) e le
**fette singole**, che il gioco impila, ingrandisce (quella aperta), scurisce (quelle chiuse) e
su cui scrive nomi e livelli.

## Cosa teniamo e cosa scartiamo

| Teniamo | Perché |
|---|---|
| Lo stile dei pezzi di WB-022 (R2, R3): contorno nero a china spesso e un po' irregolare, colori pieni, una luce e un'ombra piatte | la mappa deve essere della stessa mano dei pulsanti |
| Fette storte e morbide, non dischi perfetti: bordo un po' irregolare, qualche tacca | «meno simmetrico, linee più morbide» (Sergio) |
| La faccia di sopra pulita e ampia | il gioco ci mette il percorso dei livelli, i nomi, i lucchetti |
| Caldo in alto, gelo in fondo | il dualismo fuoco e ghiaccio, in ogni schermata |
| Nove fette, sempre | i gironi sono nove |

| Scartiamo | Perché |
|---|---|
| Personaggi, dannati, edifici, archi, scene dentro i gironi | deve restare quasi astratta e leggibile; e niente figure nude |
| Texture, sfumature morbide, riflessi realistici, 3D, bagliori | stile di WB-020, scartato |
| Scritte, numeri, lucchetti, segnalini | li mette il gioco |
| Fiamme e ghiaccioli fitti dappertutto | pochi segni: due o tre per fetta al massimo |

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-024/riferimenti/R1_gironi_proposta.png` | la mappa della proposta: cosa c'è (nove gironi a imbuto, quello aperto più grande), **non** come è disegnata |
| R2 | `art/WB-024/riferimenti/R2_piastre.png` | le piastre di WB-022: lo stile da copiare |
| R3 | `art/WB-024/riferimenti/R3_lingotto.png` | il lingotto di WB-022: come si disegna un pezzo spesso, con la faccia di sopra e quella davanti |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto: il
primo è "image 1", il secondo "image 2" e così via. Sfondo verde pieno `#00FF00`.

| Nome file | Riferimenti | Formato | Varianti |
|---|---|---|---|
| `gironi_imbuto` | R1, R2, R3 | quadrato | 2 |
| `fetta_calda` | R3, R2 | largo | 1 |
| `fetta_pietra` | R3, R2 | largo | 1 |
| `fetta_ghiaccio` | R3, R2 | largo | 1 |
| `fetta_aperta` | R3, R2 | largo | 1 |

### `gironi_imbuto`

```
Image 1 is a mockup of a game map: it shows WHAT to draw (hell as a funnel of nine rings, one under the other, each smaller than the one above), but drawn as thin lines, which is NOT the look we want. Image 2 and image 3 show the drawing style to copy: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, like a cartoon.

Draw hell as a stack of NINE thick slices, like nine slabs cut from an upside-down cone and stacked with a small gap between them: the top slice is the widest, each one below is narrower, the last one at the bottom is small. We see the stack from the front and slightly from above, so each slice shows its flat top face (a wide flattened oval) and its thick front edge. The slices are hand-drawn, a bit crooked, not perfectly round, with soft irregular edges and one or two small notches each; they are not perfectly aligned, each one is shifted a little left or right.

Colors, flat: the top two slices are warm, like hot stone, ember orange and deep red-brown (#F26419, #8A2E12) with a molten gold top face edge (#FFB703); the middle slices are dark slate and iron (#3A3540, #2B2730); going down they get colder, blue-grey, and the bottom three slices are ice: night blue (#10283A) with glacial cyan edges (#38B6FF) and a pale frost highlight (#CAF0F8). Two or three tiny flames on the edge of the top slice, a few short icicles hanging under the bottom slices. The top face of every slice is clean and empty, because the game writes on it.

Thick black ink outline, cartoon comic style like images 2 and 3. No characters, no buildings, no arches, no people. No texture, no soft gradients, no realistic lighting, no glow. No text, letters, numbers or symbols. Flat pure green background (#00FF00), the whole stack inside the picture with a green margin all around.
```

### `fetta_calda`

```
Image 1 shows how to draw a thick piece with a top face and a front face, image 2 shows more pieces in the same style: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, like a cartoon.

Draw ONE thick slice of hot stone, like a slab cut from a big round cake, seen from the front and slightly from above: a wide flattened oval top face and a thick front edge below it. Very wide (about four times wider than tall). Hand-drawn, a bit crooked, not a perfect oval, soft irregular edge with two small notches. Colors, flat: top face deep red-brown (#8A2E12), a thin molten gold line (#FFB703) where the top face meets the edge, front edge ember orange (#F26419) with one darker flat shadow band at the bottom. Two tiny flames on the left of the rim. The top face is clean and empty, because the game writes on it.

Thick black ink outline, cartoon comic style. No characters, no buildings. No texture, no soft gradients, no realistic lighting, no glow, no shadow on the ground. No text, letters or numbers. Flat pure green background (#00FF00), the slice centered with a green margin all around.
```

### `fetta_pietra`

```
Image 1 shows how to draw a thick piece with a top face and a front face, image 2 shows more pieces in the same style: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, like a cartoon.

Draw ONE thick slice of dark stone, like a slab cut from a big round cake, seen from the front and slightly from above: a wide flattened oval top face and a thick front edge below it. Very wide (about four times wider than tall). Hand-drawn, a bit crooked, not a perfect oval, soft irregular edge with two small notches and one short crack on the front edge. Colors, flat: top face dark slate (#3A3540), a thin lighter line (#5D5664) where the top face meets the edge, front edge dark iron (#2B2730) with one darker flat shadow band at the bottom. The top face is clean and empty, because the game writes on it.

Thick black ink outline, cartoon comic style. No characters, no buildings. No texture, no soft gradients, no realistic lighting, no glow, no shadow on the ground. No text, letters or numbers. Flat pure green background (#00FF00), the slice centered with a green margin all around.
```

### `fetta_ghiaccio`

```
Image 1 shows how to draw a thick piece with a top face and a front face, image 2 shows more pieces in the same style: thick slightly irregular ink outline, flat colors, one flat highlight and one flat shadow, like a cartoon.

Draw ONE thick slice of ice, like a slab cut from a frozen lake, seen from the front and slightly from above: a wide flattened top face and a thick front edge below it. Very wide (about four times wider than tall). Hand-drawn and angular: the outline is made of straight segments and hard corners instead of a smooth oval, not symmetric. Colors, flat: top face night blue (#10283A), a thin pale frost line (#CAF0F8) where the top face meets the edge, front edge a slightly lighter blue (#1C4460), outline drawn thick in glacial cyan (#38B6FF) with a thin black line outside it. One crack on the front edge and three short icicles hanging under it. The top face is clean and empty, because the game writes on it.

Cartoon comic style. No characters, no buildings. No texture, no soft gradients, no realistic reflections, no glow, no shadow on the ground. No text, letters or numbers. Flat pure green background (#00FF00), the slice centered with a green margin all around.
```

### `fetta_aperta`

```
Image 1 shows how to draw a thick piece with a top face and a front face, image 2 shows more pieces in the same style: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, like a cartoon.

Draw ONE big thick slice of dark stone, the one the player is standing on, like a slab cut from a big round cake, seen from the front and from a bit higher above than usual, so that its top face is large: a wide open oval top face and a thick front edge below it. Wide (about three times wider than tall). Hand-drawn, a bit crooked, not a perfect oval, soft irregular edge with two small notches. Colors, flat: top face dark slate (#3A3540), a clear molten gold line (#FFB703) all along where the top face meets the edge, as if the rim was red-hot, front edge dark iron (#2B2730) with one flat shadow band at the bottom. The top face is completely clean and empty, because the game draws a path with markers on it.

Thick black ink outline, cartoon comic style. No characters, no buildings, no path, no markers. No texture, no soft gradients, no realistic lighting, no glow, no shadow on the ground. No text, letters or numbers. Flat pure green background (#00FF00), the slice centered with a green margin all around.
```

## Criteri di accettazione

- [ ] sono fette spesse (faccia di sopra e bordo), non linee né anelli vuoti
- [ ] in `gironi_imbuto` le fette sono nove, dalla più larga alla più stretta, calde in alto e di ghiaccio in fondo
- [ ] contorno a china e colori pieni come i pezzi di WB-022: niente texture, sfumature morbide o bagliori
- [ ] forme storte e morbide (spigolose solo quelle di ghiaccio)
- [ ] la faccia di sopra di ogni fetta è pulita
- [ ] nessun personaggio, edificio, scritta o numero; sfondo verde pieno senza ombre

## Dopo le immagini (lo fa Claude)

Toglie il verde, prova nella pagina della proposta la mappa con le fette (impilate dal gioco,
quella aperta grande, le chiuse scurite col lucchetto di ghiaccio di WB-022, Favilla in fondo)
al posto delle ellissi, e la fa vedere a Sergio. Nel gioco: un atlante solo, compresso, bordi
lisci su ogni schermo.

---

## Decisione

Approvata da Sergio il 12 nov 2026 («farei rifare a codex anche i gironi, li vorrei come
fette»).

## Consegna di Codex

## Resoconto di Claude
