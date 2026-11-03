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
python3 strumenti/simula/simula.py -s strumenti/simula/scenari/fluidita.txt --senza-video
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
- La maschera intera costa ancora ~30 ms di Lua (230 mila celle scritte una per
  una nel buffer): si può dimezzare scrivendo solo il canale che cambia.

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
