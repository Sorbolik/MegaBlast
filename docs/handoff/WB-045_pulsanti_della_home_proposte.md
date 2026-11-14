# WB-045 · Proposte nuove per i pulsanti grandi della home

- **Stato:** APPROVATA (Sergio, 14 nov: «possiamo fare generare a codex altre proposte per i pulsanti principali?»)
- **Data:** 2026-11-14
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-045`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-045` senza chiedere conferma (il repository è privato).

## Obiettivo

I quattro pulsanti grandi della home (CAMPAGNA, ALLENAMENTO, EVENTI, ARMERIA) oggi sono le
piastre di ferro di WB-022 (R2): tre sagome a caso (freccia, storta, stendardo), tutte uguali di
colore, senza niente che dica dove portano. Sergio (14 nov): «mi stanno un po' stancando, sono
un po' troppo a cazzo di cane». Servono **tre direzioni diverse**, ognuna con i quattro
pulsanti fatti come una famiglia: ogni pulsante ha un **emblema** che dice dove porta e una
forma pensata per quel posto, non a caso.

Il lingotto GIOCA resta com'è (R3 mostra lo stile): i pulsanti nuovi devono stare bene accanto
a lui, ma un gradino sotto (GIOCA è il più forte della schermata).

## Come devono essere fatti

- Pulsante largo (circa quattro volte più largo che alto), **emblema all'estremità sinistra**,
  il resto del pulsante con il **mezzo liscio e vuoto**: il gioco ci scrive il nome e una riga
  sotto, e lo allunga solo nel mezzo (tre parti come le piastre di oggi).
- Ricalcabili in vettori: colori pieni (al massimo cinque o sei per pulsante), china chiusa e
  spessa, nessun dettaglio più sottile della china. Claude li ricalca in SVG e li esporta alla
  misura di ogni schermo, anche più grandi.
- Il fuoco sta in basso a sinistra (CAMPAGNA, ALLENAMENTO), il ghiaccio e l'oro in alto a destra
  (EVENTI, ARMERIA): R1 mostra dove stanno sulla home.

## Cosa teniamo e cosa scartiamo

| Teniamo | Perché |
|---|---|
| China spessa, colori pieni, una luce e un'ombra piatte | stile approvato (R2, R3) |
| Un emblema per pulsante, una forma che vuol dire qualcosa | «un pulsante non cambia mai significato», e Sergio vuole che si capisca dove porta |
| Mezzo liscio e vuoto | il gioco scrive e allunga |

| Scartiamo | Perché |
|---|---|
| Sagome a caso tutte dello stesso ferro | è quello che Sergio non vuole più |
| Scritte, lettere, numeri | li mette il gioco |
| Texture, sfumature morbide, bagliori, 3D | non si ricalcano in vettori |

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-045/riferimenti/R1_home_oggi.jpg` | la home scelta: dove stanno i quattro pulsanti |
| R2 | `art/WB-022/pezzo_piastre.png` | le piastre di oggi, da superare |
| R3 | `art/WB-022/pezzo_lingotto_1.png` | il lingotto GIOCA: lo stile e il pezzo più forte |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto. Misura
1536×1024 per tutti.

| Nome file | Direzione | Riferimenti | Varianti |
|---|---|---|---|
| `porte_insegne` | A · insegne di bottega appese | R1, R2, R3 | 2 |
| `porte_stemmi` | B · stemma sulla lama | R1, R2, R3 | 2 |
| `porte_forgiate` | C · ogni porta del suo materiale | R1, R2, R3 | 2 |

Le varianti si chiamano `porte_insegne_1.png`, `porte_insegne_2.png` e così via, in
`art/WB-045/`. Per ogni foglio Codex scrive un `.txt` con lo stesso nome.

### `porte_insegne`

```
Image 1 is the home screen of our game: on the left two big buttons (CAMPAIGN, TRAINING), on the right two (EVENTS, ARMOURY), and the gold ingot PLAY button at the bottom right. Image 2 shows today's buttons, dark iron plates with random shapes: we want to replace them with something that has a clear meaning. Image 3 is the gold ingot PLAY button and is the STYLE to copy exactly: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, soft hand-drawn slightly crooked shapes, like a cartoon comic.

Draw FOUR wide menu buttons, one under the other with green space between them, as a family of HANGING SHOP SIGNS of a hellish blacksmith town: each is a wide wooden-and-iron sign board, about four times wider than tall, hanging from two short chains at the top, with a carved EMBLEM on a round boss at its LEFT end; the rest of the board is plain, even and empty, because the game writes the name there.
1. CAMPAIGN: board of dark charred wood (#3A2A24) with iron bands, emblem: a winding road going down into a flaming pit, ember (#F26419, #FFB703);
2. TRAINING: board of pale worn wood (#8A6A4A) with iron bands, emblem: a straw training dummy with a target on its chest;
3. EVENTS: board of dark iron with a gold rim (#FFB703), emblem: a crown over a small banner;
4. ARMOURY: board of dark iron (#2B2530) with an ice-blue rim (#38B6FF, highlight #CAF0F8), emblem: an anvil with a hammer on it.
The four signs have the same height and the same layout, only material, rim and emblem change; they must look calmer than the gold ingot of image 3.

Thick black ink outline, cartoon comic style like image 3. Flat colors only, at most six per button, no detail thinner than the outline, so the buttons can be traced into vectors. No texture, no wood grain lines thinner than the outline, no soft gradients, no glow, no drop shadow. No text, letters or numbers. Flat pure green background (#00FF00). The buttons are well separated, none touching, none cut by the border of the picture.
```

### `porte_stemmi`

```
Image 1 is the home screen of our game: on the left two big buttons (CAMPAIGN, TRAINING), on the right two (EVENTS, ARMOURY), and the gold ingot PLAY button at the bottom right. Image 2 shows today's buttons, dark iron plates with random shapes: we want to replace them with something that has a clear meaning. Image 3 is the gold ingot PLAY button and is the STYLE to copy exactly: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, soft hand-drawn slightly crooked shapes, like a cartoon comic.

Draw FOUR wide menu buttons, one under the other with green space between them, as a family of CRESTS ON BLADES: each button is a wide forged blade-shaped plate, about four times wider than tall, lying horizontally, and at its LEFT end a big heraldic SHIELD that overlaps the plate and sticks out above and below it, with an emblem on the shield. The plate is plain, even and empty, because the game writes the name there; each plate ends on the right with a different tip that matches its meaning.
1. CAMPAIGN: ember plate (#F26419 with a lighter band #FFB703), right end like a flame tongue; shield of dark iron with a winding road going down into a flaming pit;
2. TRAINING: plate of worn steel (#8C929C, highlight #C9CED6), right end like a blunt wooden practice sword; shield with a straw target with an arrow in the middle;
3. EVENTS: gold plate (#FFB703, lighter band #FFE08A, darker band #F26419), right end like a swallow-tail banner; shield with a crown;
4. ARMOURY: dark iron plate (#2B2530) with an ice-blue edge (#38B6FF), right end cut like a chipped ice shard; shield with an anvil and a hammer.
The four buttons have the same height and the same layout; they must look calmer than the gold ingot of image 3.

Thick black ink outline, cartoon comic style like image 3. Flat colors only, at most six per button, no detail thinner than the outline, so the buttons can be traced into vectors. No texture, no soft gradients, no glow, no drop shadow. No text, letters or numbers. Flat pure green background (#00FF00). The buttons are well separated, none touching, none cut by the border of the picture.
```

### `porte_forgiate`

```
Image 1 is the home screen of our game: on the left two big buttons (CAMPAIGN, TRAINING), on the right two (EVENTS, ARMOURY), and the gold ingot PLAY button at the bottom right. Image 2 shows today's buttons, dark iron plates with random shapes: we want to replace them with something that has a clear meaning. Image 3 is the gold ingot PLAY button and is the STYLE to copy exactly: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, soft hand-drawn slightly crooked shapes, like a cartoon comic.

Draw FOUR wide menu buttons, one under the other with green space between them, each made of the MATERIAL of the place it leads to, with a small round medallion EMBLEM set into its LEFT end; the rest of each button is plain, even and empty, because the game writes the name there. Each is about four times wider than tall, with soft slightly crooked corners.
1. CAMPAIGN: a slab of cooling lava rock (#3A2A2A) with glowing ember cracks only along its bottom edge (#F26419, #FFB703), medallion with a winding road going down into a flaming pit;
2. TRAINING: a wooden practice plank (#8A6A4A, highlight #B48A60) held by two iron straps, medallion with a straw training dummy;
3. EVENTS: a gold-trimmed dark plate (#2B2530 with a #FFB703 rim) with a short hanging pennant under its right end, medallion with a crown;
4. ARMOURY: a forged iron plate (#2B2530, highlight #6B6375) with ice crystals (#38B6FF, #CAF0F8) growing on its top right corner, medallion with an anvil and a hammer.
The four buttons have the same height and the same layout; they must look calmer than the gold ingot of image 3.

Thick black ink outline, cartoon comic style like image 3. Flat colors only, at most six per button, no detail thinner than the outline, so the buttons can be traced into vectors. No texture, no soft gradients, no glow, no drop shadow. No text, letters or numbers. Flat pure green background (#00FF00). The buttons are well separated, none touching, none cut by the border of the picture.
```

## Criteri di accettazione

- [ ] ogni pulsante dice dove porta (emblema e forma), e i quattro di un foglio sono una famiglia
- [ ] emblema a sinistra, mezzo liscio e vuoto, si allunga senza deformarsi
- [ ] stile del lingotto (R3), ma più calmi di lui
- [ ] colori pieni, china spessa, si ricalcano in vettori
- [ ] sfondo verde pieno, niente scritte, pulsanti staccati

## Dopo le immagini (lo fa Claude)

- Guarda i fogli, scarta quelli con difetti, monta le tre direzioni sulla home del Figma (una
  accanto all'altra, con i nomi scritti dal gioco) e le mostra a Sergio, che sceglie.
- Ricalca la direzione scelta in SVG, la taglia in tre parti per pulsante (`tools/grafica/fucina.py`)
  e la porta nel gioco al posto delle piastre di `client/menu/home.lua`.

## Decisione

Reversibile (solo proposte in un ramo): approvata da Claude su richiesta di Sergio; la direzione
la sceglie Sergio.

## Consegna di Codex

## Resoconto di Claude
