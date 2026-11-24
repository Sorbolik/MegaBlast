# Prestazioni: misurare i frame e tenere il gioco fluido

La regola è di Sergio (19 ott, ribadita il 31 ott per il desktop): niente
scatti né micro-blocchi su nessun dispositivo, telefoni economici, schermi a
60-120 Hz e PC. Qui c'è come si misura, cosa si è trovato e cosa controlla che
non si torni indietro.

## Come si misura

### 1. Il contatore nel gioco (su ogni dispositivo)

IMPOSTAZIONI (la rotellina della home) → **CONTATORE FPS: ACCESO**. In alto al
centro compare una riga:

```
60 FPS  PEGGIORE 34 MS  99% SOTTO 17  SCATTI 2/MIN  ULTIMO: DIPINTO 34 MS
```

Online c'è anche **RETE 45 MS**: l'attesa più lunga fra due messaggi del
server negli ultimi 10 secondi (normale 17 ms: i tasti di ogni tick). Nel tuo
turno la rete non si vede (il telefono gioca subito, 22 nov); negli altri il
disegno nasconde le attese fino a 3-10 tick (50-170 ms, `CP.net_frame`): uno
scatto che si vede con gli FPS a posto e RETE sopra i 150 ms è la rete, non il
telefono.

- **FPS** e **99% SOTTO** sugli ultimi 10 secondi (a 60 Hz un frame è 16,7 ms;
  a 120 Hz 8,3 ms).
- **SCATTO**: un frame lungo più di 1,5 volte il frame normale (la mediana
  degli ultimi 10 secondi). A 60 Hz vuol dire un vsync perso: è quello che
  l'occhio vede come un saltello.
- **ULTIMO**: la causa più probabile dell'ultimo scatto:

| Causa | Cosa vuol dire |
|---|---|
| `dipinto` | si è decodificato e caricato un dipinto di `client/paintings` (terreno o sfondo) |
| `maschera` | si è ridisegnata tutta la maschera del terreno (nuova mappa) |
| `schermata NOME` | è cambiata la schermata (`local`, `menu`, `scelta`...) |
| `gc` | è passato il raccoglitore della memoria di Lua |
| `lua` | gli script hanno lavorato più della metà dello scatto (un calcolo lungo) |
| `bot` | in quel frame un bot ha pensato (prova le mosse su copie della partita, `client/sim/bot.lua`): sul telefono può costare più di un giro di schermo |
| `motore` | niente di quanto sopra: disegno, GPU, driver o sistema operativo |

Sul PC, lanciando dall'editor di Defold, ogni scatto va anche nella console:

```
SCATTO 48.2 ms (normale 16.7, lua 1.2 ms) causa: motore
```

`lua` è quanto hanno lavorato gli script in quel frame (update e input della
GUI, messaggi del terreno; non l'update del terreno, che sono pochi `go.set`):
se è piccolo e lo scatto è grande, il tempo l'ha preso il disegno o il
sistema. Una pausa di più di un secondo (il gioco in secondo piano) non conta.
Spento, il contatore non fa niente.

Il codice è `client/ui/frames.lua`. Chi aggiunge un lavoro pesante (un
caricamento, una schermata grande) chiama `fotogrammi.segna("nome")`, così il
contatore lo riconosce.

### 2. Il profiler di Defold (per i casi difficili, sul PC)

Con la build di debug lanciata dall'editor (Project → Build), il motore apre il
profiler web su **http://localhost:8002**: registra i frame e mostra, per ogni
frame, quanto hanno preso script, GUI, disegno e caricamenti, fino alla
singola funzione. Quando il contatore dice `motore` e non si capisce perché,
si registra lì uno scatto e si guarda quale barra è lunga. Nella build di
release (l'APK di Telegram) il profiler non c'è: lì resta il contatore.

### 3. Il simulatore (ripetibile, nel cloud)

```bash
python3 tools/simula/simula.py -s tools/simula/scenari/fluidita.txt --senza-video
```

Lo scenario `fluidita.txt` accende il contatore dalle impostazioni, resta nella
home dipinta, entra in Primi passi, esce, gioca una partita contro il bot.
Ogni scenario scrive gli scatti e un riassunto ogni 5 secondi in
`simulazione/fotogrammi.txt`, e `simula.py` stampa una riga con gli scatti per
causa. `--senza-video` perché ffmpeg ruba la CPU al gioco.

Attenzione: nel simulatore disegna la CPU (llvmpipe), quindi i millisecondi del
disegno non sono quelli di un telefono o di una GPU vera, e gli scatti
`motore` lì sono quasi tutti rumore. Valgono invece i millisecondi di Lua e i
caricamenti, che sono lavoro della CPU come sul PC.

### I caricamenti sotto il velo

Entrare in una missione è il frame più pesante del gioco: dipinti (decodifica e
GPU) e maschera del terreno, 209-234 ms sul telefono di Sergio (2 nov, a 120 Hz,
114 FPS in partita, il 99% dei frame sotto 10 ms). Succede sotto l'iride chiusa:
dopo il cambio di scena il velo resta chiuso ancora 3 frame (`passaggio.HOLD_FRAMES`,
`client/ui/transition.lua`, #159), così il frame lungo cade sul nero e l'iride si
riapre intera invece di saltare. Lo stesso vale per lo scivolo fra i menu (la
schermata nuova arriva tre frame dopo, a velo pieno). Il contatore segna questi
scatti `(coperto)` e non li conta fra gli SCATTI/MIN, perché non si vedono; nel
simulatore hanno un tetto loro di 300 ms di Lua (sotto).

Preparare i dipinti prima (durante la scelta delle armi) è stato scartato: la
decodifica gira sul thread principale e lo scatto passerebbe su una schermata
che si vede. Per questo anche la partita che parte dopo la scelta delle armi
(sullo stesso telefono, in missione e online) parte sotto l'iride (3 nov, da
quando online si gioca sulle mappe dipinte): online i messaggi del server che
arrivano mentre l'iride si chiude aspettano e passano subito dopo.

## Il controllo che lo mantiene

`simula.py` fallisce se in un frame Lua lavora più di **150 ms** (`LUA_MAX`),
con qualsiasi scenario: CLAUDE.md chiede di girare il simulatore prima di ogni
PR che tocca `client/`, quindi un caricamento o un calcolo nuovo che blocca il
gioco si vede prima del merge. Il tetto è largo perché è tempo vero e, col
video, ffmpeg ruba la CPU al gioco: serve a fermare i blocchi nuovi grossi, non
i millisecondi.

I frame `(coperto)`, sotto l'iride chiusa, hanno un tetto loro di **300 ms**
(`LUA_MAX_COPERTO`, 3 nov). Oggi il caso peggiore è entrare in una mappa dipinta
grande (pavimento o fossa: un PNG di 2880 x 1620 da decodificare), 105-125 ms
nel simulatore e fino a 162 col video (le arene delle lezioni, più piccole, circa
60; su un telefono 3-5 volte di più: va abbassato, vedi sotto). Da quando le
mappe vecchie sono state tolte lo scenario base gioca sul pavimento, e con 150
falliva per caso. Scartati: tenere la mappa in cache (c'è già: sfondo e terreno
non si ricaricano se non cambiano, ma la prima volta va decodificata comunque),
misurare senza il caricamento (sparirebbe proprio il controllo sui caricamenti
nuovi), lasciare lo scenario base su una mappa piccola (non proverebbe più una
partita vera).

Regole per il codice (dalla regola di Sergio del 19 ott):

- niente allocazioni a ogni frame (tabelle, stringhe, vettori nuovi): il
  contatore nel simulatore riporta `kb_frame`, i KB nuovi per frame (oggi 1-15;
  è un minimo: i frame in cui passa il gc non si possono contare);
- i lavori pesanti (decodificare immagini, ridisegnare la maschera, costruire
  schermate) solo dietro una transizione, una volta sola, e segnati con
  `fotogrammi.segna`;
- niente upload di texture intere durante la partita (i crateri aggiornano
  solo il loro rettangolo);
- il disegno si interpola fra i tick della simulazione.

## Cosa si è trovato (2 nov, dopo la PR #147)

Misure nel simulatore, stesso scenario, prima (de591e4) e dopo la #147:

| | Prima | Dopo | Con questa PR |
|---|---|---|---|
| Frame normale in Primi passi (llvmpipe) | 15,9 ms | 22-28 ms | uguale |
| Frame più lungo entrando in una missione | 326 ms | 885 ms | 613-689 ms |
| Lavoro di Lua in quel frame | — | ~135 ms | ~60 ms |

- **La maschera del terreno si ridisegnava 3 volte** nello stesso frame entrando
  in una missione (230 mila celle ogni volta, ~35 ms l'una nel simulatore) e
  ogni volta in un buffer nuovo da 900 KB. Ora si ridisegna una volta sola a
  fine update, nello stesso buffer: **corretto in questa PR**.
- **I dipinti** si decodificano dal PNG sul thread principale: terreno ~26 ms,
  le quattro strisce dello sfondo ~37 ms (all'avvio). È uno scatto solo, al
  cambio di mappa, dietro la transizione. Il thread "Il tempio di Gabvi" li
  porta nella pipeline di Defold (texture già pronte, niente decodifica).
- **Lo shader del terreno** costa di più: nel simulatore il frame normale in
  Primi passi passa da 15,9 a 22-28 ms. Sul PC con una GPU dedicata non
  dovrebbe pesare; su una GPU integrata a 2560 x 1600 (lo schermo del portatile
  di Sergio) potrebbe. È il primo sospetto per gli scatti "ogni tanto" durante il
  gioco, ma va confermato col contatore sul PC.
- **Il bot** non ha mai tenuto un tick più di 4 ms (pensa a pezzi).
- **Sul PC di Sergio** (2 nov, RTX 4060, schermo 2560 x 1600 a 165 Hz, il
  contatore in console per una sessione di campagna): il frame normale è 6 ms,
  ma molti frame durano 10-18 ms (un giro di schermo perso) con Lua a 0-1 ms,
  quindi il tempo lo prende il disegno; entrare in una missione blocca un frame
  80-135 ms di Lua (maschera e dipinto grande, densità 2). Lo shader del terreno
  lo riscrive per primo il thread di Gabvi (crateri nuovi), con l'idea del canale
  blu qui sotto; poi si rimisura col contatore.

## Cosa si è trovato (4 nov, scatti contro il Fabbro)

Sergio sentiva scatti sul telefono dopo i merge della notte (#184-#193). Nel
simulatore, con lo scenario nuovo `fluidita_forgia.txt` (scelta delle armi e
Battaglia della Forgia 2 contro 2 coi tre bot, colpi e zoom), rigiocato a #159,
prima della notte, a ogni PR della notte e su main, il frame normale (14-16 ms),
il Lua peggiore (6-8 ms ogni 5 secondi) e i KB per frame stanno nel rumore (lo
stesso commit rigiocato cambia di 1 ms). Col profiler di Defold (`profiler.enable_ui`
in una build del simulatore) le chiamate di disegno sono 72 contro 68 di #159 e i
vertici della GUI 4412 contro 3830 (il pulsante tondo dello zoom); la memoria
massima scende da 311 a 275 MB; entrare nella Forgia costa 280-370 ms sotto
l'iride (a #159 509-713 ms, visibili).

Il contatore sul telefono ha detto il resto: nella Forgia 116 FPS, il 99% dei
frame sotto 9 ms, 0 scatti al minuto; nel cortile **MASCHERA 155 ms**. RIPROVA
dalla rotellina e Ritenta dopo una lezione fallita ricominciano sulla stessa mappa
senza iride, e `start_mission` ridisegnava ogni volta tutta la maschera (230 mila
celle). Ora il gioco ricorda i rettangoli scavati nella partita e, se la mappa è
la stessa, rimette solo quelli dal terreno nuovo (`CR.undig`): nel simulatore lo
scatto da 74 ms (61 di Lua) sparisce (scenario `riprova_mappa.txt`). Scartato
mettere RIPROVA sotto l'iride: costa uno scatto nero ogni volta che si ritenta,
mentre qui il lavoro si può proprio togliere.

## Cosa si è trovato (4 nov, scatti online sul teletrasporto)

Sergio: online, anche solo coi bot, «il primo sparo che faccio del teletrasporto
scatta più volte, e a volte anche altre cose». Il server manda uno stato ogni 2
tick (30 al secondo) e il client, a ogni stato arrivato, ripartiva da quello che
c'era sullo schermo verso il nuovo in 33 ms esatti. Sul WiFi del telefono gli
stati arrivano a mucchi: uno in ritardo (il globo si ferma) e poi due o tre
insieme (il globo salta avanti). Il contatore FPS non lo vede, perché i frame
sono tutti puntuali. Lo scenario `rete_tele.txt` fa la stessa cosa con una rete
finta (`imposta prova_rete 120`: a volte trattiene i messaggi fino a 120 ms):
prima il globo in volo restava fermo 2-3 frame di fila e poi faceva 10-13 px in
un frame; con la coda (`client/main/playout.lua`) fa 5-6 px a ogni frame per
tutto il volo. Dal 22 nov la coda è dei tasti, non degli stati (online in
lockstep, `CP.net_frame`): la partita si gioca sul telefono un tick alla volta
come in locale, quindi il globo non salta mai, e i tasti che arrivano a mucchi
aspettano qualche tick in coda.

## Cosa si è trovato (19 nov, scatti nello SHOP e nello ZAINO)

Sergio col contatore acceso vedeva tanti scatti nelle animazioni dello SHOP e dello
ZAINO. Scenario `tools/simula/scenari/fluidita_zaino_shop.txt` (porta SHOP, ZAINO che
cresce, griglia che scorre, POTENZIA con lama e cartello, SIGILLI), con `--senza-video`.
Due cause, tutte e due del contorno illuminato dei pezzi (`menu/outline.lua`):

- **Le sette immagini delle sagome rifatte di continuo.** Il render script le rifaceva
  ogni volta che il rettangolo del diavoletto cambiava misura: scorrendo con la porta
  o coi pezzi che entrano cambia di un pixel avanti e indietro (753/754), e con lo
  ZAINO che cresce cambia a ogni frame. Ogni volta sette immagini cancellate e create
  sulla GPU. Ora si fanno grandi come il diavoletto fermo (`room`, mandato da
  `outline.lua`) e non si rimpiccioliscono mai; i passaggi disegnano solo il
  rettangolo nel loro angolo. Nello scenario: da 91 volte a 2 (la prima e una a metà
  del rimbalzo dello ZAINO, un quarto più grande e poi più).
- **Il diavoletto ombra ricopiava tutto a ogni frame** (`scoria.mirror`: posto, giro,
  scala e misura di ogni pezzo con `gui.get_*`, centinaia di vettori nuovi): 33-40 KB
  di memoria nuova per frame nello ZAINO e scatti `gc`. Ora copia una volta e poi
  segue: quello che la posa scrive su un pezzo lo scrive subito anche sull'ombra
  (`FOLLOW` in `battle/scoria.lua`). Memoria per frame 2-10 KB, scatti `gc` da 22 a 7.
  Controllato pezzo per pezzo che l'ombra resti identica (zero differenze).

Resta il costo fisso del contorno: nel simulatore (disegno sulla CPU) lo ZAINO fa
un frame normale di 70 ms con il contorno e 28 senza. Sulla GPU vera pesa molto meno,
ma sono sette passaggi grandi quasi quanto lo schermo: se il contatore su telefono
mostra ancora FPS bassi (non scatti) nello ZAINO, il prossimo passo è lì.

## Il piano di ottimizzazione (9 nov)

Sergio (8 nov): analizzare il client col manuale di Defold (`docs/llms-full.md`) e
ottimizzare CPU, memoria e garbage collection senza toccare la qualità visiva.
Il piano, con le violazioni trovate (V1-V13) e le fasi, è
https://claude.ai/artifact/Ltr5MyxwvEd1pNQKHB3pUW . Ogni fase è una PR e si chiude
con le misure qui sotto, rifatte sulla stessa macchina.

### 4. Il banco della simulazione e del bot

```bash
luajit tools/prestazioni/banco.lua          # col JIT (Android, PC)
luajit -joff tools/prestazioni/banco.lua    # senza JIT, come su iPhone
```

Gioca tre partite fra bot "difficile" senza disegno (240 secondi di gioco l'una)
e misura per tick il tempo di `bot.input` + `game:step` e la memoria nuova,
separata fra bot e simulazione (col raccoglitore fermo, così i KB sono veri).

### Le etichette del profiler

Nel profiler web di Defold (build di debug sul PC, http://localhost:8002) i lavori
pesanti hanno una barra col loro nome (`fotogrammi.scope`, `client/ui/frames.lua`):
`simulazione` (i tick del frame, bot compresi), `disegno` (robot, colpi, schegge),
`maschera` (la maschera del terreno ridisegnata), `dipinto` (decodifica e upload di
un dipinto). Nella build di release non fanno niente.

### Punto di partenza (Fase 0, main c6b2cc3)

Banco, CPU del cloud (sul telefono 3-5 volte di più):

| Partita | JIT | Tick medio | 99% | Peggiore | KB/tick bot | KB/tick simulazione |
|---|---|---|---|---|---|---|
| 2v2 pavimento | acceso | 0,096 ms | 0,93 ms | 3,2 ms | 8,0 | 0,26 |
| 2v2 fossa | acceso | 0,096 ms | 0,94 ms | 2,6 ms | 9,4 | 0,25 |
| 1v1 pavimento | acceso | 0,083 ms | 0,92 ms | 6,9 ms | 4,6 | 0,28 |
| 2v2 pavimento | spento | 0,277 ms | 2,28 ms | 7,6 ms | 6,7 | 0,07 |
| 2v2 fossa | spento | 0,303 ms | 2,52 ms | 8,3 ms | 8,0 | 0,07 |
| 1v1 pavimento | spento | 0,201 ms | 1,96 ms | 8,2 ms | 3,0 | 0,07 |

Quasi tutta la memoria nuova è del bot (le copie della partita, V2): circa
400-550 KB al secondo in 2v2.

Simulatore (`--senza-video`, disegno su llvmpipe: valgono Lua, KB e cause, non i ms del disegno):

| Scenario | Frame normale (mediana) | 99% (mediana) | KB per frame (mediana / max) | Scatti per causa |
|---|---|---|---|---|
| `fluidita.txt` | 14,0 ms | 22,1 ms | 2,7 / 14,7 | motore 135, **gc 81** (fino a 30 ms), bot 16 (fino a 23 ms) |
| `fluidita_forgia.txt` | 13,8 ms | 19,9 ms | 3,1 / 18,4 | motore 54, **bot 13** (fino a 41 ms), lua 1 |

Entrare in una missione sotto l'iride: 337 ms (cortile) e 268 ms (Forgia) di
frame, coperti. Restano da aggiungere le misure di Sergio col contatore sul
telefono e sul PC.

### Fase 1: il ciclo di update (9 nov)

- Col bot che pensa, al massimo 4 tick di recupero per frame (`CATCHUP_BOT`).
- `render()`: uovo, missile, scia e schegge accesi, spenti e colorati solo quando cambiano.
- Il raccoglitore fa un passo da 8 KB a ogni frame (`fotogrammi.GC_STEP`, in `fotogrammi.fine`).
- Accelerometro spento (`use_accelerometer = 0`).

| Scenario | Scatti `gc` prima / dopo | Lua peggiore negli scatti `bot` prima / dopo | Frame normale prima / dopo |
|---|---|---|---|
| `fluidita.txt` | 81 (fino a 30 ms) / **5** (fino a 23 ms) | 4,3 / 6,9 ms | 14,0 / 13,3 ms |
| `fluidita_forgia.txt` | 0 / 1 | 12,4 / **7,5** ms | 13,8 / 14,6 ms |

Gli scatti segnati `bot` sono di più (16 → 25, 13 → 25), ma in quasi tutti Lua
lavora 1-3 ms: è il disegno di llvmpipe in un frame in cui un bot ha pensato. Il
lavoro di Lua più lungo nella Forgia scende del 40%. Il banco non cambia (la
simulazione e il bot non sono toccati).

### Fase 2: la memoria (9 nov)

- Il bot riusa le sue copie della partita (`bot.world(g, into)`, una per ogni punto
  del ragionamento in `b.worlds`; `bot.hits`, che il client chiama a ogni frame
  mirando con le armi da mischia, ne ha una sola). Prima ogni copia era una tabella
  nuova da circa 10 KB, centinaia al secondo.
- Hash e indirizzo della mesh calcolati una volta in `terrain.script`; `hash("touch")`
  non più a ogni input (`ui.TOUCH`).
- La maschera intera non riscrive più il canale alfa (sempre 255) se il buffer c'è già.

| Banco, 2v2 pavimento | KB/tick bot prima | dopo | Tick medio prima | dopo |
|---|---|---|---|---|
| JIT spento | 6,7 | **1,0** | 0,277 ms | 0,275 ms |
| JIT acceso | 8,0 | **2,2** | 0,10-0,11 ms | 0,10 ms |

Nella Forgia del simulatore gli scatti segnati `bot` scendono da 25 a 5 e il Lua
peggiore fra quelli da 7,5 a 2,7 ms; gli scatti `gc` restano 1-2 in tutti e due gli
scenari. `confronta.py`: 207 partite identiche a main.
Non toccati: la tabella dei tasti a ogni tick (la ricetta la conserva in `r.ultimo`:
riusarla rompe le ricette, già visto il 4 nov) e la lista degli eventi della
simulazione (pochi byte, e gira anche sul server).

## Da fare

- Sergio accende il contatore sul PC e gioca: se gli scatti sono `motore` con
  `lua` piccolo, è il disegno (shader o GPU integrata); se sono `gc`, `dipinto` o
  altro, la causa è scritta lì.
- Lo shader può fare la stessa immagine con meno letture: oggi ogni pixel di
  terreno legge la maschera 9 volte per l'orlo dei crateri (`scavo_attorno`), anche
  lontano da ogni cratere; con un segno "vicino a un cratere" nel canale blu
  della maschera (che oggi non si usa) ne basta una. Nessun dettaglio della
  mappa cambia (Sergio, 2 nov: "senza perdere il livello di dettaglio delle
  mappe"). Si fa dopo la misura sul PC e insieme al thread di Gabvi, che tocca
  lo stesso shader.
- ~~La maschera intera costa ancora ~30 ms di Lua~~ fatto in #243 (sotto).

## Memoria video e peso dell'APK (16 nov)

Gli atlanti sono texture RGBA non compresse: in memoria video pesano
larghezza × altezza × 4 byte (un terzo in più con le mipmap), e nell'APK
stanno compressi solo con LZ4. Il peso di un atlante lo decide la potenza di 2
che contiene tutte le sue immagini: poco oltre 4096×4096 diventa 8192×8192,
quattro volte tanto.

| Atlante | Prima | Dopo | Memoria video dopo |
|---|---|---|---|
| `battle/devil.atlas` (diavoletto, con mipmap) | 8192×8192 | 4096×4096 | 89 MB (prima 341) |
| `ui/fucina.atlas` | 4096×4096 | uguale | 64 MB |
| `ui/fette.atlas` | 4096×2048 | uguale | 32 MB |
| `ui/ui.atlas` | 2048×2048 | 2048×1024 | 8 MB (tolte ellissi e monete che non si usavano più) |
| gli altri cinque | | uguali | 30 MB in tutto |

Causa del 8192: teste, corna, cappucci ed elmi erano a 13,5 pixel per unità
del disegno invece di 4 come il resto del corpo (`taglia.py da_svg` ingrandiva
di nuovo gli SVG delle teste, già scritti a 4 px). La misura più grande in cui
si vede il diavoletto è la home (338 punti di altezza per 200 unità): sul
telefono o tablet più grande sono ~3,5 pixel veri per unità, quindi 4 basta e
la GPU usava comunque una mipmap più piccola. Regola: **nessun pezzo oltre
4 px per unità** (i mantelli 4,5, perché lo shader li stira).

APK (arm64, release): 73,4 MB → 63,5 MB (teste −6,7, dipinti PNG ricompressi
senza perdita con oxipng −2, immagini non più usate −0,8). Il resto: atlanti 30 MB, dipinti 28 MB, motore
5 MB. Oltre i 50 MB Telegram rifiuta il file dal server normale dei bot: con i
segreti `TELEGRAM_API_ID` e `TELEGRAM_API_HASH` l'APK passa da un server dei bot
locale sul runner (fino a 2 GB, `.github/workflows/apk.yml`).

Scartate per ora: compressione ASTC degli atlanti per Android (4 volte meno
memoria video, ma è con perdita; con bob 1.14 l'APK di prova è cresciuto a
81 MB perché tiene anche la copia RGBA), dividere l'atlante del diavoletto in due
(stessa memoria, più codice), togliere i dipinti `_1` dall'APK (i telefoni
sotto i 1000 pixel li usano).

## Fase 3: la maschera a strisce (9 nov)

Misura nel simulatore (`fluidita.txt`, JIT spento come sul telefono): entrando in
una missione la maschera intera costava 77,6 ms di Lua, la voce più grossa del
caricamento (i dipinti 2-18 ms l'uno). Ora ogni striscia di celle uguali di una
riga (piene o vuote) è una sola copia (`buffer.copy_stream`) da una riga già
pronta, invece di tre scritture per cella: **3,2-3,9 ms**, byte per byte uguale
alla maschera di prima (controllato su tutte le celle nel simulatore). Nessun
dettaglio cambia, la partita neanche.

Il resto della Fase 3 e la Fase 4 non valgono la pena, misurato: i contatori dei
componenti sono già esatti (niente factory), lo shader legge già la maschera una
volta sola (#157), un nodo padre per l'HUD e i layer della GUI danno poco e
rischiano l'ordine di disegno, il caricamento asincrono delle texture toglie solo
l'upload (1-6 ms) mentre la decodifica resta. In partita Lua usa 0,5-0,8 ms per
frame (disegno 0,37, personaggi 0,15, simulazione 0,05): il resto è GPU.

## I log dal telefono, senza cavo (9 nov)

L'APK di tutti i giorni è "release": Defold lì non scrive log. Per le misure c'è
l'APK coi log: Actions > "APK su Telegram" > Run workflow con **log** spuntato
(arriva su Telegram con "📋 CON I LOG"). È la variante debug, stesso nome e stessa
chiave: si installa sopra; dopo le prove si rimette quello normale.

1. Sul telefono: Opzioni sviluppatore > **Debug wireless** acceso (Android 11+),
   telefono e PC sulla stessa WiFi; "Associa dispositivo con codice" mostra
   indirizzo, porta e codice.
2. Sul PC (Android Platform-Tools): `adb pair IP:PORTA CODICE`, poi
   `adb connect IP:PORTA` (la porta della schermata Debug wireless, non quella
   dell'associazione).
3. `adb logcat -c` e poi `adb logcat -s defold:* > log_telefono.txt` mentre si gioca
   col CONTATORE FPS acceso (IMPOSTAZIONI): ogni scatto è una riga
   `SCATTO 23.0 ms (normale 8.3, lua 0.6 ms) causa: ...`.

## Dipinti HD per i PC (19 nov)

Con lo zoom vicino (camera a 2,2) un'unità del mondo occupa 2,2 × (altezza dello
schermo / 720) pixel veri. Il terreno a densità 2 ha 1,78 pixel per unità: su un
telefono 1080p era ingrandito 1,85 volte, sul PC di Sergio (2560 × 1600) 2,75, su
un 4K 3,7. Era la sfocatura che Sergio sentiva sul desktop.

Ora c'è la **densità 3** (il doppio della 2, `DENSITA_HD` in
`tools/grafica/mappe_dipinte.py`, `--hd` per rifare solo quella): terreno
6840 × 3240, piani dello sfondo fino a 8192 di lato. Sta in `client/paintings_hd`
(29 MB a tavolozza) e la usano solo Windows, Mac e Linux con lo schermo alto almeno
1400 pixel (`battle/terrain.script`); senza la cartella si torna alla 2. L'APK e la
build web non la portano (`custom_resources` riscritto in `apk.yml` e
`tools/web/build.sh`). Memoria video in più su un PC: circa 100 MB. Scenario
`tools/simula/scenari/nitidezza.txt` (con `--scala 2`).

Scartate nella stessa ricerca: più thread (Lua usa 0,5-0,8 ms a frame, il resto è
la GPU; suono e caricamento delle texture sono già su thread a parte), MSAA (le
immagini e il bordo del terreno sono già morbidi, costerebbe GPU senza vedersi),
Vulkan su Android (driver peggiori sui telefoni economici), ASTC (vedi sopra), mipmap
dell'interfaccia (il manuale di Defold avverte che con lo slice-9 rimpicciolito danno
artefatti, e i telefoni non mostrano difetti oggi). Da tenere per dopo: DirectX 12 su
Windows (Defold 1.14, con OpenGL di riserva) per i portatili con grafica integrata,
Metal per una build nativa iPhone. 120 Hz sui telefoni: il contatore di Sergio dice
già 120 FPS.

## Opzioni scartate e perché

- **Solo il dt del motore** per misurare: dipende da come il motore lo
  calcola (vsync, frame bloccati); il contatore usa l'orologio vero
  (`socket.gettime`), che vede anche i frame persi.
- **Solo la media degli FPS**: nasconde gli scatti (un frame da 100 ms in un
  secondo dà ancora 55 FPS). Per questo peggiore, 99° percentile e scatti.
- **Il profiler di Defold sempre acceso o nell'APK**: c'è solo nelle build di
  debug e pesa lui stesso; resta per i casi difficili sul PC.
- **Un test di prestazioni su GitHub a ogni PR** (main contro ramo): lì
  disegna la CPU, quindi i millisecondi del disegno sono rumore, e costerebbe
  5-10 minuti a PR (già scartato il 2 nov per `simula.py`, vedi
  [architettura](decisioni/architettura.md)). Il controllo su Lua lo fa già
  `simula.py`, che si gira prima delle PR che cambiano ciò che si vede.
- **Confrontare main e ramo con una soglia sugli FPS** nel simulatore: troppo
  rumoroso, perché lì disegna la CPU e gli scatti `motore` vanno e vengono; si
  confronta a mano, come sopra, quando serve.
- **Uno strumento esterno** (RenderDoc, PIX, Android GPU Inspector): utili per
  la GPU, ma pesanti da installare; prima il contatore dice se il problema è la
  GPU.

## Nodi della GUI

La GUI del gioco (`client/main/game.gui`) ha `max_nodes: 8192` (24 nov): con i pulsanti a lastra
lo ZAINO del profilo di prova, ricostruito a ogni pezzo scelto, restava
con circa 400 nodi liberi su 4096 e sul telefono li finiva (scritte e INDOSSA mancanti in basso).
Ogni pulsante a lastra è una sola lastra di tre nodi: cambiando stato (acceso, chiaro, premuto)
cambia i disegni, non accende altri nodi. Uscendo dallo ZAINO i suoi nodi tornano liberi (misurato).
Se la GUI scrive `Could not create the node since the buffer is full`, la simulazione fallisce:
scenario `zaino_fine_gioco.txt`.
