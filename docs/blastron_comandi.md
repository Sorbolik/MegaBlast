# Blastron: comandi, hitbox e colpi corpo a corpo

Seguito di [blastron.md](blastron.md). Anche questa parte è ricostruita
dall'APK:
- il codice C# decompilato;
- le animazioni dei robot (curve degli `AnimationClip` esportati da SmoothMoves);
- le proprietà dei prefab delle armi.

Lo schema illustrato è in `blastron_analisi/comandi/schema_hitbox.png` (cartella del
progetto, fuori dal repository).

## I comandi in breve

| Dito | Cosa fa |
|---|---|
| **Levetta sinistra** | Spostata di lato oltre il 15% cammina. Inclinata in alto oltre 25° e spinta oltre il 25% salta, e risalta finché la tieni. |
| **Levetta destra** | La direzione è la mira, la distanza dal centro la potenza (si accende oltre il 20%, curva quadratica). La mira insegue il dito del 20% per frame. **Lasci e parte il colpo**; riportandola sotto il 10% si spegne e lasciando non parte niente. Il cerchio è azzurro da spenta e rosso da accesa. |
| **Teletrasporto** | Pulsante in alto a destra della levetta destra. |
| **Arma** | Pulsante dell'arma sull'HUD, poi la levetta destra. Per le armi corpo a corpo la potenza non conta: conta solo la direzione. |
| **Camera** | Un dito trascina, due dita fanno lo zoom (fino a 2,2 volte). Mentre miri la camera tiene il robot nell'85% × 75% centrale dello schermo; quando cammini lo rimette al centro. |

La camera non c'è: MegaBlast mostra sempre tutta la mappa.

### Le levette in MegaBlast

Sul telefono ci sono le due levette di Blastron, nello stesso posto (HUD del
tablet portato a 1280 × 720):
- movimento a (115, 117), mira a (1165, 117), corsa 94 px;
- teletrasporto a (1208, 257).

La logica è in `client/battaglia/levette.lua`, con le soglie del `Tuning`.
Abbiamo cambiato quattro cose:

1. **La levetta del movimento riportata al centro si ferma.** In Blastron, una
   volta partito, il robot camminava finché non alzavi il dito.
2. **Il colpo parte con la mira di 50 ms prima di staccare il pollice.** Mentre
   il pollice si alza la punta scivola e sposta la mira: in Blastron lo
   assorbiva solo il ritardo della mira, qui non conta proprio.
3. **La base va dove appoggi il pollice**, dentro la sua metà dello schermo, e
   torna al suo posto quando lo alzi. In Blastron la levetta contava già dal
   punto in cui appoggiavi il dito, ma la base restava ferma e il disegno non
   corrispondeva.
4. **Tutto è a tempo, non a fotogrammi.** Il ritardo della mira (20% per
   frame a 60 Hz) è lo stesso a 30, 60 o 120 Hz; in Blastron cambiava col
   frame rate.

Sul computer le levette non ci sono:
- A/D o le frecce per muoversi, W/spazio per saltare;
- mira col mouse dal robot, tasto destro per annullare;
- T per il teletrasporto (o il pulsante in basso a destra), 1-5 per le armi.

Telefono o computer si capisce dal sistema (Android, iOS, browser col touch) o
da `[megablast] comandi = telefono / computer`. Durante la partita si cambia da
soli: un dito sullo schermo accende le levette, un tasto le spegne.

## Proporzioni

L'arena di Blastron era larga 102,4 unità e il robot alto 3,612. In MegaBlast la
mappa è larga 1280 px, quindi nel profilo `blastron` un'unità vale 12,5 px e il
robot è alto 45 px (prima 16 px):
- `ROBOT_H` e `ROBOT_HALF_W` (il cerchio del corpo, raggio 1,18 u) sono nel profilo;
- tutte le misure di Blastron (velocità, salti, esplosioni) seguono, perché
  sono scritte in unità;
- le misure nostre (casse, schegge, ricerca del teletrasporto) crescono nella
  stessa proporzione.

Il profilo `megablast` resta col robot da 16 px.

## Cosa stacca dallo sfondo

Sono le regole di Blastron (`blastron_analisi/blastron_grafica.md`), applicate
senza rigenerare immagini:

- **Sfondo spento** (`strumenti/grafica/stacca.py`, scrive `sfondo_spento.png`):
  - sfocato, con contrasto e saturazione bassi;
  - schiarito verso la nebbia: luce 0,20 → 0,39.
  - Lo fa lo script una volta sola: in gioco non costa niente.
- **Terreno più deciso** (stesso script, `terreno_staccato.png`): più
  contrastato, più saturo e un po' più scuro (luce 0,31).
- **Contorno scuro e filo di luce sul bordo di sopra** (`battaglia/terreno.fp`):
  - calcolati dal disegno del terreno e dalla maschera;
  - seguono anche i crateri nuovi;
  - costano 5 letture di texture per pixel.
- **Scoria**:
  - la Scoria nera sullo sfondo chiaro stacca da sola;
  - in più ha un alone del colore della squadra.
- **Scritte** della battaglia col font Cinzel dei titoli; levette, armi e
  teletrasporto con le cornici del kit.

## Dove si viene colpiti

Ogni robot di Blastron ha due cerchi (codice in `Player`, valori dal `Tuning`):

| Forma | Misura (robot alto h = 3,612 u) | A cosa serve |
|---|---|---|
| Cerchio del **corpo** | raggio 1,18 u (0,33 h), centro a 0,33 h dai piedi | urta il terreno |
| Cerchio dei **colpi** | raggio 1,888 u (0,523 h), centro a metà altezza | lo toccano proiettili, lame e altri robot |
| Quadrato per le **esplosioni** | il quadrato attorno al cerchio dei colpi, più largo di 0,1 u per lato (lato 3,98 u) | la distanza di un'esplosione si misura dal suo punto più vicino |

Il cerchio dei colpi è più largo del robot (1,05 volte la sua altezza): in Blastron
si veniva presi facilmente anche "di striscio".

In MegaBlast: `HURTBOX = "cerchio"` con `HURT_R` = 23,6 px e `HURT_FAT` = 1,25 px
nel profilo `blastron`. Il corpo contro il terreno resta la nostra scatola di
celle.

## Colpi corpo a corpo

In Blastron un colpo corpo a corpo è fatto di tre pezzi.

1. **Un rettangolo attaccato all'arma.** Parte dal punto `gun_flash` (la punta
   dell'arma, 194 px dall'osso dell'arma nel disegno del robot, cioè 2,34 u) e si
   allunga lungo l'asse dell'arma. Per la spada va da 3 u prima a 3 u dopo
   `gun_flash`, è largo 1 u e segue l'animazione fotogramma per fotogramma.
2. **Una finestra.** Due eventi dell'animazione aprono e chiudono i colpi. Chi
   tocca il rettangolo mentre la finestra è aperta viene segnato; quando si
   chiude riceve il danno, una volta sola. La velocità del bersaglio viene
   sostituita con `direzione × spinta`, quindi con spinta 0 il bersaglio si
   **ferma**.
3. **La mira.** Questo è il punto che ricordavi. Nel disegno del robot, spalla,
   braccio e arma sono figli di un osso (`dummy_bone`) che il codice ruota ogni
   fotogramma sulla direzione della mira. L'animazione del colpo è scritta per
   la mira dritta, ma gira tutta insieme alla mira:
   - mirando in basso il fendente cala dall'alto verso il basso;
   - mirando in alto sale.

### Fendente (Hanzo Special, animazione `bot_hack`)

Sono 70 fotogrammi a 75 al secondo: 0,93 s.

| Fotogrammi | Tempo | Cosa fa la lama (rispetto alla mira) |
|---|---|---|
| 0–15 | 0–0,2 s | dalla mira sale fino a 90° (sopra la testa) |
| 15–30 | 0,2–0,4 s | continua dietro la schiena fino a 197° |
| **30–34** | **0,4–0,45 s** | **cala in avanti fino a +29°: il colpo vero** |
| 34–60 | 0,45–0,8 s | resta davanti e scende piano sulla mira |
| 60–70 | 0,8–0,93 s | torna a riposo |

La finestra va dal fotogramma 20 al 60: prende chi sta **sopra e dietro** durante
la carica e chi sta **davanti** durante la discesa (un arco di circa 200°). La
scossa della camera arriva al fotogramma 37, i danni al 60.

### Le armi corpo a corpo di Blastron

| Arma | Animazione | Rettangolo | Danno | Spinta |
|---|---|---|---|---|
| Hanzo Special (spada) | `bot_hack` | 6 × 1 u | 300 | 0 (ferma) |
| Knight Stick | `bot_hack` | 10 × 2 u | 1750 | 10 u/s |
| Plumber Pummeler | `bot_hack_fast` (0,28 s) | 5 × 3 u | 500 | 0 |
| Battering Ram | `bot_stab` (0,68 s) | 6 × 1,5 u | 750 | 700 u/s |
| Flame-Yuken (montante) | `bot_uppercut` (2,1 s) | 3,5 × 3 u | 1000 | 40 u/s dritto in alto; chi colpisce fa un saltello di 15 u/s |

L'abbinamento arma → rettangolo è dedotto dai nomi dei prefab (`melee_sword`,
`melee_excalibur`, `melee_pummeler`, `melee_batterup`, `melee_dragon_punch`).
Le animazioni sono certe: sono scritte nelle armi.

### Montante (Flame-Yuken, animazione `bot_uppercut`)

Sono 95 fotogrammi a 45 al secondo.
- **Fotogrammi 5–20 (finestra):** il pugno sale dal basso davanti (−40°) fin sopra la
  testa (+100°).
- **Fotogramma 10:** saltello di chi colpisce.
- **Fotogramma 20:** danno e lancio del bersaglio.
- **Fotogrammi 20–80:** il pugno resta su mentre il robot si alza.

Anche il montante gira con la mira.

## Cosa c'è in MegaBlast

Nel profilo `blastron`:

- **`client/sim/mischia.lua`**: le pose del fendente e del montante, fotogramma per fotogramma.
  - Per ogni fotogramma: la posizione dell'osso della mira e l'asse del rettangolo, in unità
    di Blastron.
  - Sono numeri ricavati dalle curve delle animazioni, non le animazioni stesse.
- **`SWORD_MODEL = "blastron"` e `PUNCH_MODEL = "blastron"`**:
  - la posa ruota sull'angolo di mira (girato verso destra e poi specchiato come in Blastron);
  - la lama è controllata 6 volte per tick contro il cerchio dei colpi;
  - i danni arrivano alla chiusura della finestra.
- **Valori**:
  - fendente: 15 danni (300 su 2000), ferma il bersaglio, 56 tick;
  - montante: 50 danni, lancio dritto in alto, saltello, 127 tick.
- **Disegno**: la Scoria tiene la spada puntata dove miri e, durante il colpo, il braccio
  segue l'angolo della lama (`game.sword_angle(t, base)`).
- **Online**: il server manda anche l'angolo di mira del colpo (`sb`, `pb`).

Il profilo `megablast` non cambia: il fendente da 240° e il pugno di prima.

## Differenze da quello che avevamo deciso

| Cosa | Deciso finora | Blastron (profilo predefinito del branch) |
|---|---|---|
| Arco della spada | 240° fissi, da dietro la schiena a davanti in basso | circa 200° dalla mira in su e dietro, poi giù fino alla mira: **gira con la mira** |
| Tempi della spada | 1/3 di secondo, danno nel momento in cui la lama passa | 0,93 s, colpo vero a 0,4 s, danno quando si chiude la finestra (0,8 s) |
| Danno della spada | 35 | 15 |
| Spinta della spada | nessuna, il bersaglio continua come prima | il bersaglio si ferma di colpo |
| Pugno | sempre in avanti, 0,4 s | gira con la mira, 2,1 s |
| Bersaglio | scatola 12 × 16 px | cerchio di raggio 1,888 u (23,6 px) a metà altezza |
| Grandezza del robot | 16 px, la mappa è larga 80 robot | 45 px, la mappa è larga 28 robot come in Blastron |
| Comandi sul telefono | pulsanti < > SALTA e mira dal robot | due levette e teletrasporto sopra quella della mira |

La combo dietro → teletrasporto → davanti funziona ancora:
- il teletrasporto non tocca il colpo in corso;
- chi viene toccato prima e dopo il salto prende il danno una volta sola.
