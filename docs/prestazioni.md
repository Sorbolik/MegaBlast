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

Online c'è anche **RETE 45 MS**: l'attesa più lunga fra due stati del server
negli ultimi 10 secondi (normale 33 ms, il server ne manda 30 al secondo). Il
disegno nasconde le attese fino a 4 stati (133 ms, `client/main/playout.lua`):
uno scatto che si vede con gli FPS a posto e RETE sopra i 130-150 ms è la rete,
non il telefono.

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
tutto il volo. `tests/playout_test.lua` lo controlla con arrivi a mucchi.

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
