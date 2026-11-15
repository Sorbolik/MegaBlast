# WB-061 · Lo striscione EVENTI più ricco e i segni di chi sale e chi scende

- **Stato:** APPROVATA (Sergio, 15 nov 19:17: «fammi proposte grafiche, con tutte le schede per codex necessarie»)
- **Data:** 2026-11-15
- **Ramo della scheda:** `claude/project-thread-w00xhp` (Codex la esegue da qui, non serve che sia su `main`) · **Ramo delle immagini:** `design/WB-061`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-061` senza chiedere conferma (il repository è privato).

## Obiettivo

Due cose piccole uscite dalla valutazione estetica del 15 nov.

1. Nella home (R1) la porta **EVENTI** è la più povera delle quattro: CAMPAGNA ha la lingua di
   fuoco, ALLENAMENTO la spada di legno con la fascia di ferro, ARMERIA la scheggia di
   ghiaccio, EVENTI solo una fascia gialla tagliata a coda di rondine (R2). Serve uno
   striscione di stoffa vero, con la stessa ricchezza delle altre (R3, R4), senza cambiare
   emblema, colori e misure.
2. Nelle statistiche il valore che cambia oggi è tutto giallo, sia quando migliora sia quando
   peggiora. Sergio ha approvato (15 nov) il pannello con colori distinti: servono due
   **segni piccoli**, sale e scende, che si leggano anche senza il colore.

## Come devono essere fatti

- **Striscione:** stessa lunghezza, stessa altezza e stesso emblema tondo a destra di R2. Il
  **mezzo resta liscio e vuoto** (il gioco ci scrive EVENTI e una riga sotto e lo allunga solo
  lì): pieghe, cuciture e frange stanno solo vicino alla coda, a sinistra, e sotto l'emblema.
- **Segni:** sagome piene, un colore solo più l'ombra, si leggono a 14 pixel.
- Ricalcabili in vettori: colori pieni, china chiusa e spessa, nessun dettaglio più sottile
  della china.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-061/riferimenti/R1_home_oggi.jpg` | la home di oggi: le quattro porte a confronto |
| R2 | `art/WB-046/ritagli/porta_eventi.png` | la porta EVENTI di oggi: misure, emblema e colori da tenere |
| R3 | `art/WB-046/ritagli/porta_campagna.png` | la porta CAMPAGNA: la ricchezza da raggiungere |
| R4 | `art/WB-046/ritagli/porta_armeria.png` | la porta ARMERIA: come è disegnata una coda speciale |
| R5 | `art/WB-022/pezzo_piccoli.png` | pezzi piccoli di WB-022: lo stile dei segni |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto: il
primo è "image 1", il secondo "image 2" e così via.

| Nome file | Cosa c'è | Riferimenti | Misura | Varianti |
|---|---|---|---|---|
| `porta_eventi` | lo striscione EVENTI ridisegnato, tre idee una sotto l'altra | R1, R2, R3, R4 | 1536×1024 | 2 |
| `segni_sale_scende` | freccia che sale, freccia che scende, segno uguale | R5 | 1024×1024 | 2 |

Le varianti si chiamano `porta_eventi_1.png`, `porta_eventi_2.png` e così via, in
`art/WB-061/`. Per ogni foglio Codex scrive un `.txt` con lo stesso nome: cosa ha fatto e cosa
non è riuscito a rispettare.

### `porta_eventi`

```
Image 1 is the home screen of our game with four big menu buttons: CAMPAIGN (ember, ending in a tongue of flame), TRAINING (steel, ending in a wooden practice sword tip), EVENTS (gold banner with a round crown medallion on its right end) and ARMOURY (dark iron with an ice edge, ending in a chipped ice shard). Image 2 is the EVENTS button alone: it is the poorest of the four, just a flat gold band cut like a swallow tail. Images 3 and 4 are the CAMPAIGN and ARMOURY buttons: they show how rich and special the end of a button should be, and the ink STYLE to copy exactly: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, soft hand-drawn slightly crooked shapes, like a cartoon comic.

Redraw the EVENTS button as a real cloth tournament banner, THREE different ideas one under the other with green space between them. Each one keeps exactly the layout of image 2: the same length and height, the same round medallion with the gold rim, the dark red (#8E1E1E) disc and the crown at the RIGHT end, the tail at the LEFT end, and a plain, even, empty gold body in the middle (the game writes the name there and stretches only the middle). Gold is #FFB703 with a lighter band #FFE08A and a darker band #F26419; the back of the cloth is a darker gold (#C77800); dark red is #8E1E1E.
1. FOLDED RIBBON: at the left end the cloth folds back on itself once before the swallow tail, showing its darker back (#C77800), and the two points of the swallow tail are slightly uneven, like cloth moving.
2. FRINGED STANDARD: the left end is cut into a swallow tail with a short dark red (#8E1E1E) hem along the cut and three chunky gold tassels hanging from it; a short dark red hem also runs behind the medallion.
3. WAVING PENNANT: the left end narrows into one long waving point with a single soft fold, and a small dark red (#8E1E1E) stripe follows the lower edge only in the last quarter near the point.
In all three the middle of the band stays perfectly plain and even, with no folds, seams or decoration, so text can be written on it with a comfortable margin.

Thick black ink outline, cartoon comic style, same line weight as images 3-4. Flat colors only, at most six per button, no detail thinner than the outline, so the buttons can be traced into vectors. No texture, no soft gradients, no realistic lighting, no glow, no drop shadow. No text, letters or numbers. Flat pure green background (#00FF00). The three buttons are well separated from each other with green between them, none touching, none cut by the border of the picture.
```

### `segni_sale_scende`

```
Image 1 shows small pieces of our game interface and is the STYLE to copy exactly: thick slightly irregular black ink outline, flat colors, one flat highlight or shadow per piece, soft hand-drawn slightly crooked shapes, like a cartoon comic.

Draw a sheet with THREE separate small signs, side by side, each one large and centered in its cell. Every sign is a single bold silhouette in ivory (#F4ECE1) with ONE flat darker shadow shape (#C9BFB2) and a thick black outline, so the game can tint it; no other colors.
1. UP: a chunky short arrow head pointing straight up, like a fat rounded triangle with a very short stem;
2. DOWN: the same arrow pointing straight down, exactly the same shape turned upside down;
3. SAME: two short chunky horizontal bars one above the other, like a fat equals sign.

The three signs have the same size feeling and the same line weight. They will be shown as small as 14 pixels, so no detail thinner than the outline. Flat colors only, no texture, no soft gradients, no glow, no drop shadow. No text, letters or numbers. Flat pure green background (#00FF00). The signs are well separated from each other with green between them, none touching, none cut by the border of the picture.
```

## Criteri di accettazione

- [ ] le tre idee dello striscione hanno la stessa lunghezza, altezza ed emblema di R2
- [ ] il mezzo dello striscione è liscio e vuoto: pieghe e frange solo vicino alla coda e all'emblema
- [ ] lo striscione è ricco quanto le porte di R3 e R4, ma resta più calmo del pulsante GIOCA
- [ ] i tre segni sono avorio con un'ombra sola e si leggono a 14 pixel; sale e scende sono la stessa forma capovolta
- [ ] china spessa, colori pieni, nessuna sfumatura morbida, niente scritte
- [ ] pezzi staccati fra loro e dal bordo, sfondo pieno

## Dopo le immagini (lo fa Claude)

- Mostra a Sergio le tre idee dello striscione montate nella home accanto alle altre porte:
  la sceglie lui.
- Ricalca in SVG la scelta e i segni, li esporta nell'atlante `fucina`
  (`tools/grafica/fucina.py`) e sostituisce i segni provvisori del pannello delle statistiche.
- Prova la home a 1280x720, 1600x720, 960x720 e a doppia risoluzione.

---

## Decisione

Reversibile (solo immagini nuove in un ramo): approvata da Claude su richiesta di Sergio
(15 nov). Lo striscione lo sceglie Sergio fra le tre idee.

## Consegna di Codex

Generati con `image_gen` da `claude/project-thread-w00xhp` (`1a47caba`).
Ogni PNG in `art/WB-061/` ha il TXT omonimo con prompt integrale,
riferimenti in ordine ed esito.

| Nome | Tentativi | Selezione | Dimensioni PNG |
|---|---:|---:|---:|
| `porta_eventi_1` | 2 | 2 | 1536×1024 |
| `porta_eventi_2` | 1 | 1 | 1536×1024 |
| `segni_sale_scende_1` | 2 | 2 | 2172×724 |
| `segni_sale_scende_2` | 3 | 3 | 2172×724 |

Controllati a vista tre striscioni per foglio, corona a destra, tre code
diverse a sinistra e centro vuoto. Il primo tentativo di `porta_eventi_1`
aveva medaglioni a contatto. La rigenerazione li separa. Verificati i tre
segni per foglio, i contorni neri, i margini e l'assenza di scritte.

R2 mostra la corona a sinistra. La home R1 e il prompt la richiedono a
destra. Le immagini seguono il prompt integrale. Gli ingombri e la
corrispondenza esatta con il medaglione di R2 restano da verificare.
Le frecce sono simili, con differenze di sagoma. Il secondo foglio dei segni
ha ancora riflessi oltre all'ombra. La leggibilità a 14 pixel e il ricalco
restano da verificare.

I fogli dei segni sono rettangolari anziché 1024×1024. Il verde opaco
differisce da #00FF00 nei punti campionati. Conservati i PNG originali.

## Resoconto di Claude
