# WB-046 · Pulsanti della home e nuovo GIOCA online

- **Stato:** APPROVATA (Sergio, 14 nov 22:48: «lo stemma della A con la "coda" della B, e coi colori della B»; «rivoluzioniamo anche il tasto gioca online con lo stesso stile, magari più particolare»)
- **Data:** 2026-11-14
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-046`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-046` senza chiedere conferma (il repository è privato).

## Obiettivo

Sergio ha visto le tre direzioni di WB-045 e le vuole mescolate: dei pulsanti A (insegne) prende
l'**emblema tondo** con la ghiera e i chiodi, dei pulsanti B (stemmi sulla lama) prende la **coda**
a destra (lingua di fuoco, spada di legno, coda di rondine, scheggia di ghiaccio) e i **colori**
(brace, acciaio, oro, ferro scuro col filo di ghiaccio). Le catene delle insegne non servono.
Poi va ripensato anche il pulsante principale **GIOCA online** (oggi il lingotto d'oro di WB-022)
nello stesso stile, più particolare perché è il più importante della schermata.

## Come devono essere fatti

- Pulsante largo (circa quattro volte più largo che alto), emblema tondo all'estremità sinistra,
  coda all'estremità destra, il **mezzo liscio e vuoto**: il gioco ci scrive il nome e una riga
  sotto e lo allunga solo nel mezzo (tre parti: emblema, mezzo, coda).
- Ricalcabili in vettori: colori pieni (al massimo sei per pulsante), china chiusa e spessa,
  nessun dettaglio più sottile della china. Claude li ricalca in SVG e li esporta alla misura di
  ogni schermo, anche più grandi.
- GIOCA online: stessa famiglia, ma più grande (circa una volta e mezza l'altezza degli altri),
  più ricco e più caldo; anche lui con il mezzo liscio dove il gioco scrive «GIOCA» e «online».

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-045/riferimenti/R1_home_oggi.jpg` | la home: dove stanno i pulsanti e GIOCA |
| R2 | `art/WB-046/riferimenti/R2_emblema_tondo.png` | proposta A: da qui SOLO l'emblema tondo con ghiera e chiodi |
| R3 | `art/WB-046/riferimenti/R3_coda_e_colori.png` | proposta B: da qui la coda a destra e i colori del corpo |
| R4 | `art/WB-022/pezzo_lingotto_1.png` | il lingotto GIOCA di oggi: lo stile della china, da superare |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto.

| Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|
| `porte_ibride` | R1, R2, R3, R4 | 1536×1024 | 2 |
| `gioca_online` | R1, R2, R3, R4 | 1536×1024 | 2 |

Le varianti si chiamano `porte_ibride_1.png`, `porte_ibride_2.png` e così via, in `art/WB-046/`.
Per ogni foglio Codex scrive un `.txt` con lo stesso nome.

### `porte_ibride`

```
Image 1 is the home screen of our game: on the left two big buttons (CAMPAIGN, TRAINING), on the right two (EVENTS, ARMOURY), and the gold PLAY button at the bottom right. Image 2 and image 3 are two earlier proposals for these four buttons; we want a MIX of the two. From image 2 take ONLY the round EMBLEM at the left end: a round medallion with a thick metal rim, four small rivets on the rim and a carved emblem inside. Do NOT take the chains of image 2. From image 3 take the BODY and its COLORS and the special TAIL at the right end of each button. Image 4 shows the ink style to copy: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, soft hand-drawn slightly crooked shapes, like a cartoon comic.

Draw FOUR wide menu buttons, one under the other with green space between them. Each button is about four times wider than tall: on its LEFT end a big round medallion (like image 2) that is a little taller than the body and overlaps it, in the middle a plain, even, empty body (the game writes the name there), and on its RIGHT end the tail of image 3.
1. CAMPAIGN: ember body (#F26419 with a lighter band #FFB703), right end like a flame tongue; medallion with a dark iron rim, inside a winding road going down into a flaming pit;
2. TRAINING: worn steel body (#8C929C, highlight #C9CED6), right end like the blunt tip of a wooden practice sword held by an iron band; medallion with a dark iron rim, inside a straw target with an arrow in the middle;
3. EVENTS: gold body (#FFB703, lighter band #FFE08A, darker band #F26419), right end like a swallow-tail banner; medallion with a gold rim on dark red (#8E1E1E), inside a crown;
4. ARMOURY: dark iron body (#2B2530) with an ice-blue edge (#38B6FF, highlight #CAF0F8), right end cut like a chipped ice shard; medallion with an ice-blue rim, inside an anvil with a hammer.
The four buttons have the same height, the same medallion size and the same layout; only colors, emblem and tail change. They must look calmer than the gold PLAY button of image 1.

Thick black ink outline, cartoon comic style like image 4. Flat colors only, at most six per button, no detail thinner than the outline, so the buttons can be traced into vectors. No texture, no soft gradients, no glow, no drop shadow. No text, letters or numbers. Flat pure green background (#00FF00). The buttons are well separated, none touching, none cut by the border of the picture.
```

### `gioca_online`

```
Image 1 is the home screen of our game: the gold PLAY button is at the bottom right, it is the main button of the screen. Image 2 and image 3 show the new family of the other menu buttons: a round medallion emblem with a metal rim and rivets at the left end (image 2), a plain body with a meaningful tail at the right end and flat bold colors (image 3). Image 4 is today's PLAY button, a gold ingot: we want to replace it with something more special. Copy its ink style: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, soft hand-drawn slightly crooked shapes, like a cartoon comic.

Draw THREE different proposals for the new PLAY ONLINE button, one under the other with green space between them. Each belongs to the same family as images 2 and 3 but is bigger, richer and warmer, clearly the most important button of the game: about three and a half times wider than tall, with a plain, even, empty middle where the game writes "PLAY" and "online" (leave it empty).
1. FORGED GOLD BLADE: a thick gold body (#FFB703, lighter band #FFE08A, darker band #F26419), on its LEFT end a BIG round medallion with a dark iron rim and rivets, inside two crossed pitchforks over a small round world; on its RIGHT end a big double flame tongue (#F26419, #FFB703) curling upward;
2. MOLTEN SEAL: a gold body with a thin ember rim, on its LEFT end a BIG round wax-seal medallion in deep red (#8E1E1E) with a gold rim, inside two little devil horns facing each other (two players meeting); its RIGHT end shaped like the hot glowing tip of a blade fresh from the forge (#F26419 with a #FFE08A core);
3. ANVIL SIGN: a gold body resting on a dark iron base (#2B2530) that sticks out a little below it, on its LEFT end a BIG round medallion with a gold rim, inside a little globe with a flame on top; its RIGHT end like a forged arrow point pointing right, with two small flames trailing behind it.
Each proposal is one single piece with a strong silhouette, warm fire colors, at most six flat colors, and must stay readable when small.

Thick black ink outline, cartoon comic style like image 4. Flat colors only, no detail thinner than the outline, so the buttons can be traced into vectors. No texture, no soft gradients, no glow, no drop shadow. No text, letters or numbers. Flat pure green background (#00FF00). The three buttons are well separated, none touching, none cut by the border of the picture.
```

## Criteri di accettazione

- [ ] emblema tondo di A, coda e colori di B, senza catene; i quattro sono una famiglia
- [ ] mezzo liscio e vuoto, si allunga senza deformarsi
- [ ] GIOCA online della stessa famiglia ma chiaramente il più forte, tre idee diverse
- [ ] colori pieni, china spessa, si ricalcano in vettori
- [ ] sfondo verde pieno, niente scritte, pulsanti staccati

## Dopo le immagini (lo fa Claude)

- Guarda i fogli, scarta quelli con difetti, monta i quattro pulsanti e le tre idee di GIOCA sulla
  home del Figma e le mostra a Sergio, che sceglie GIOCA.
- Ricalca in SVG, taglia in tre parti per pulsante (`tools/grafica/fucina.py`) e porta tutto nel
  gioco al posto delle piastre e del lingotto di `client/menu/home.lua`.

## Decisione

Reversibile (solo proposte in un ramo): approvata su richiesta di Sergio. Il GIOCA lo sceglie Sergio.

## Consegna di Codex

## Resoconto di Claude

Guardati i quattro fogli (14 nov): tutti buoni. Pulsanti: variante 1 (le due sono quasi uguali).
GIOCA: variante 1 per la lama d'oro e l'insegna sull'incudine, variante 2 per il sigillo fuso (più
da sigillo); nel foglio 2 i tre GIOCA si toccano, il sigillo è tagliato nel punto più stretto.
Ritagli in `art/WB-046/ritagli/`. Sergio (14 nov 23:16) vuole lo scudo sempre verso il bordo: per
EVENTI e ARMERIA Claude ha girato il pulsante tenendo dritto lo scudo (`porta_eventi_dx.png`,
`porta_armeria_dx.png`). Prova animata della transizione con i tre GIOCA da confrontare:
https://claude.ai/artifact/NUZURUfk3Gt2eaFpnN7roq . I pezzi della transizione sono in WB-049.
