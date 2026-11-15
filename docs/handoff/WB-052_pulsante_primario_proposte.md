# WB-052 · Tre direzioni per il pulsante primario dei menu

- **Stato:** CONSEGNATA E INTEGRATA (era APPROVATA) (Sergio, 15 nov 9:59: «Dobbiamo inventarci un altro pulsante primario, adesso è diverso in base alle pagine, ed in ogni caso non è coerente con i cambi di ui che abbiamo fatto»; 10:17: «voglio un altro pulsante primario, quello [il sigillo fuso] è solo per entrare nel gioca online dalla schermata principale»)
- **Data:** 2026-11-15
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-052`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-052` senza chiedere conferma (il repository è privato).

## Obiettivo

In basso a destra di ogni menu c'è l'azione della schermata: GIOCA in allenamento e in campagna,
INDOSSA nello zaino, POTENZIA e COMPRA in armeria, SALVA nei sigilli, CERCA in gioca online. Oggi è
il lingotto arancione di WB-022 (R1), grigio quando è spento: non somiglia ai pulsanti nuovi della
home (R2, R3). Il sigillo fuso (R4) resta solo per GIOCA online nella home e **non** va copiato.

Servono **tre direzioni diverse** per un pulsante primario solo, uguale in ogni schermata, con i suoi
stati: **acceso**, **premuto** e **spento** (l'azione non si può fare: deve leggersi spento a colpo
d'occhio, non solo più grigio).

## Come devono essere fatti

- Pulsante largo, circa tre volte e mezzo più largo che alto, con il **mezzo liscio e vuoto**: il
  gioco ci scrive l'azione in nero e lo allunga solo nel mezzo (tre parti).
- Stile dei pulsanti di WB-046 (R2, R3): china spessa e un po' irregolare, colori pieni, una luce e
  un'ombra piatte, forme morbide un po' storte. Il fuoco sta in basso a sinistra, il ghiaccio in alto
  a destra (regola del «Filo di brace»).
- Ricalcabili in vettori: al massimo sei colori per pezzo, niente più sottile della china.
- Deve essere il pezzo più forte della schermata, più dei pulsanti della home, ma diverso dal sigillo.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-052/riferimenti/R1_lingotto_oggi.png` | una schermata di oggi: il lingotto GIOCA in basso a destra |
| R2 | `art/WB-052/riferimenti/R2_porta_campagna.png` | pulsante CAMPAGNA di WB-046: lo stile |
| R3 | `art/WB-052/riferimenti/R3_porta_armeria.png` | pulsante ARMERIA di WB-046: lo stile, il ghiaccio |
| R4 | `art/WB-052/riferimenti/R4_gioca_sigillo.png` | il sigillo fuso: da NON copiare |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto. Misura
1536×1024 per tutti.

| Nome file | Direzione | Riferimenti | Varianti |
|---|---|---|---|
| `primario_colata` | A · metallo appena colato | R1, R2, R3, R4 | 2 |
| `primario_punzone` | B · piastra a punta di freccia | R1, R2, R3, R4 | 2 |
| `primario_brace_gelo` | C · brace in basso, gelo in alto | R1, R2, R3, R4 | 2 |

Le varianti si chiamano `primario_colata_1.png`, `primario_colata_2.png` e così via, in
`art/WB-052/`. Per ogni foglio Codex scrive un `.txt` con lo stesso nome.

### `primario_colata`

```
Image 1 is a menu screen of our game: the orange button at the bottom right is the main action button of every menu, and it must be redesigned. Images 2 and 3 are two new menu buttons of the same game and are the STYLE to copy exactly: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, soft hand-drawn slightly crooked shapes, like a cartoon comic. Image 4 is another button that must NOT be copied: no wax seal, no round emblem.

Draw the new MAIN ACTION BUTTON as a slab of freshly POURED MOLTEN METAL: a wide rounded slab about three and a half times wider than tall, bright molten gold (#FFB703) with a lighter top band (#FFE08A) and a darker ember bottom edge (#F26419), a thin dark crust (#2B2530) along its outline, one fat drip hanging from its bottom-left corner and two tiny sparks above it; at its top-right corner a small patch of pale frost (#CAF0F8) where it is cooling. The middle of the slab is plain and even, with nothing on it, so text can be written there and the slab can be stretched in width.

Draw it THREE times on the sheet, one above the other, with green space between them:
1. LIT: as described;
2. PRESSED: the same slab pushed down: a bit flatter, the top band darker (#FFD15C), the drip shorter;
3. OFF: the same slab cooled down and dead: dark grey iron (#4A4550, highlight #6B6375), the crust cracked, frost (#CAF0F8) spread over the top-right half, no sparks, no glow colors at all.

Thick black ink outline on every piece, cartoon comic style like images 2 and 3. Flat colors only, at most six per piece, no detail thinner than the outline, so the pieces can be traced into vectors. No texture, no soft gradients, no glow halo, no drop shadow. No text, letters or numbers. Flat pure green background (#00FF00). The pieces are well separated, none touching, none cut by the border of the picture.
```

### `primario_punzone`

```
Image 1 is a menu screen of our game: the orange button at the bottom right is the main action button of every menu, and it must be redesigned. Images 2 and 3 are two new menu buttons of the same game and are the STYLE to copy exactly: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, soft hand-drawn slightly crooked shapes, like a cartoon comic. Image 4 is another button that must NOT be copied: no wax seal, no round emblem.

Draw the new MAIN ACTION BUTTON as a hammered HOT IRON PLATE shaped like a broad ARROW pointing right: a wide plate about three and a half times wider than tall, its left end cut square with two big rivets, its right end a short chunky arrow point; the face glowing hot orange (#F26419) with a lighter band along the top (#FFB703) and a dark iron rim (#2B2530, highlight #6B6375) all around; a few small flame tongues lick out of the bottom-left corner and a few small ice crystals (#38B6FF, #CAF0F8) sit on the top edge near the point. The middle of the plate is plain and even, with nothing on it, so text can be written there and the plate can be stretched in width.

Draw it THREE times on the sheet, one above the other, with green space between them:
1. LIT: as described;
2. PRESSED: the same plate hammered down: a bit flatter, the face darker (#C2410C), the flames smaller;
3. OFF: the same plate cold and dead: dark iron face (#4A4550, highlight #6B6375), no flames, the ice crystals grown along the whole top edge, the rivets dull.

Thick black ink outline on every piece, cartoon comic style like images 2 and 3. Flat colors only, at most six per piece, no detail thinner than the outline, so the pieces can be traced into vectors. No texture, no soft gradients, no glow halo, no drop shadow. No text, letters or numbers. Flat pure green background (#00FF00). The pieces are well separated, none touching, none cut by the border of the picture.
```

### `primario_brace_gelo`

```
Image 1 is a menu screen of our game: the orange button at the bottom right is the main action button of every menu, and it must be redesigned. Images 2 and 3 are two new menu buttons of the same game and are the STYLE to copy exactly: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, soft hand-drawn slightly crooked shapes, like a cartoon comic. Image 4 is another button that must NOT be copied: no wax seal, no round emblem.

Draw the new MAIN ACTION BUTTON as a thick GOLD PLATE caught between FIRE and ICE: a wide slightly slanted plate about three and a half times wider than tall, of bright gold (#FFB703) with a lighter top band (#FFE08A) and a darker bottom band (#E09A00), framed by a chunky black-ink rim; big flame tongues (#F26419, #FFB703) wrap around its bottom-left corner and lick up its left side; sharp ice crystals and frost (#38B6FF, #CAF0F8) grow on its top-right corner and along the top of its right side. The middle of the plate is plain and even, with nothing on it, so text can be written there and the plate can be stretched in width.

Draw it THREE times on the sheet, one above the other, with green space between them:
1. LIT: as described;
2. PRESSED: the same plate pushed down: a bit flatter, the gold darker (#F0A800), the flames smaller;
3. OFF: the same plate frozen over: the gold turned dull grey (#6B6375, highlight #8C929C), no flames at all, the ice and frost spread over the whole right half.

Thick black ink outline on every piece, cartoon comic style like images 2 and 3. Flat colors only, at most six per piece, no detail thinner than the outline, so the pieces can be traced into vectors. No texture, no soft gradients, no glow halo, no drop shadow. No text, letters or numbers. Flat pure green background (#00FF00). The pieces are well separated, none touching, none cut by the border of the picture.
```

## Criteri di accettazione

- [ ] tre direzioni diverse fra loro e diverse dal sigillo fuso
- [ ] per ogni direzione acceso, premuto e spento, della stessa misura
- [ ] lo spento si legge spento a colpo d'occhio (freddo, senza fuoco)
- [ ] mezzo liscio e vuoto, si allunga in larghezza
- [ ] colori pieni, china spessa, si ricalcano in vettori
- [ ] sfondo verde pieno, niente scritte, pezzi staccati

## Dopo le immagini (lo fa Claude)

- Ritaglia le tre direzioni, le monta su una schermata vera (allenamento, zaino, armeria) con le
  scritte del gioco e le mostra a Sergio una accanto all'altra.
- Scelta la direzione: la ricalca in SVG, la mette in `kit.action` (tutti i menu) con i tre stati;
  il lingotto di WB-022 se ne va.

## Decisione

Reversibile (solo immagini in un ramo): approvata su richiesta di Sergio.

## Resoconto di Claude (15 nov)

- Arrivati tutti e sei i fogli, ognuno coi tre stati. Montati su allenamento, armeria e zaino: `/mnt/project-files/menu_14nov/WB-052_tre_pulsanti_primari.png`.
- Sergio sceglie la **C · brace e gelo** (variante 1). Ritagliati acceso, premuto e spento in `ritagli/primario_*_1.png`, nell'atlante fucina come `primario_acceso`, `primario_premuto` e `primario_spento`, in tre parti (`tools/grafica/fucina.py`).
- Ora sono in `kit.action`, cioè in tutti i menu: il premuto si vede mentre il dito è sopra (`on_press` in `ui.ui`).
- Il lingotto di WB-022 è tolto.
- Sergio vuole comunque altre tre proposte: WB-054.
