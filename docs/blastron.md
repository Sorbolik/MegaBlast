# Blastron (Kabam, v2.3) — com'è fatto dentro

Analisi dell'APK `Blastron-v2-3-01.apk` (build del 4 marzo 2014), fatta per
MegaBlast. Qui ci sono solo descrizioni e numeri: nel nostro repository non è
stato copiato né codice né grafica di Kabam.

## In breve

- **Motore**: Unity 4.1.5 con scripting Mono (C#). Tutta la logica sta in due
  DLL .NET (`Assembly-CSharp.dll` e `Assembly-CSharp-firstpass.dll`), che si
  decompilano quasi perfettamente: circa 1.150 classi leggibili.
- **Fisica**: Farseer Physics, la versione C# di Box2D, inclusa come sorgente.
  Il terreno è fatto di **poligoni** (non pixel): ogni esplosione sottrae un
  cerchio con un clipper poligonale e ricostruisce i corpi statici.
- **Rete**: client autoritativo. Ogni telefono simula il proprio robot e i
  propri proiettili e manda posizione e colpi agli altri (ENet su UDP o
  WebSocket, passando da un server di gioco). Uno dei telefoni fa da "host" e
  decide l'ordine dei turni e le casse.
- **Regole della partita**: non sono nel codice ma in "sequenze" (scripting
  visuale fatto in casa, serializzato negli asset): turni, troncamento del
  tempo dopo lo sparo, fine partita.
- **Numeri**: le costanti di gioco stanno in un componente `Tuning` dentro gli
  asset (che il server poteva sovrascrivere), le armi in prefab con un
  componente per tipo. Li ho estratti tutti; sono le tabelle più sotto.

## Cosa c'è nel file

| Parte | Contenuto |
|---|---|
| `lib/armeabi-v7a/` | `libunity.so`, `libmono.so` (stub che caricano i veri in `assets/libs`), `libenetlib.so` (rete UDP), `libapkprotect.so` (controllo firma) |
| `assets/bin/Data/Managed/` | le DLL: gioco, plugin (Farseer, NGUI, HOTween, SmoothMoves, crittografia) |
| `assets/bin/Data/` | `mainData`, `level0` (scena di avvio), 863 file "Resources" con nome esadecimale (prefab del robot, UI, materiali) |
| `assets/scenes/` | 11 mappe come asset bundle (castello, ponte, acquedotti, cavallo di Troia, isola del teschio, tempio, montagne, valle western, teschio di drago, poligono di tiro, tutorial) |
| `assets/inventory/` | il bundle delle armi (64 armi, 25 potenziamenti) con le icone |
| `assets/characters/` | robot e pezzi di armatura (bundle da 20 MB) |
| `assets/singleplayer/`, `multiplayer/`, `championship/` | dati delle modalità: `Tuning`, casse, campagna, premi |

## Architettura del codice

```
Setup ──► Tuning (costanti)            EB.Sparx (backend Kabam: login, negozio,
  │                                       inventario, matchmaking, tuning remoto)
  ▼
LevelData (una per mappa)  ◄── Sequenze (turni, timer, fine partita)
  │  terreno poligonale, crateri, griglia di navigazione per l'IA,
  │  ordine dei giocatori, query "chi è nel raggio"
  ▼
Player ◄── PlayerControlByGUI ◄── ButtonJoystick (levetta movimento)
  │                            ◄── ButtonAim (levetta mira)
  │  corpo Farseer, movimento, salto, caduta, animazioni, colpi ricevuti
  ▼
Weapon (voce di inventario) ──► RangeWeapon (proiettili)
                              ├► MeleeWeapon (corpo a corpo)
                              ├► BeamWeapon (raggi e pistole istantanee)
                              └► CarpetBomb (bombardamento dal cielo)
Health / Shield / StatusEffects   Scoring   CrateManager   CameraController
EB.Replication (RPC e sincronizzazione)  ──►  EB.ENet / WebSocket
```

- **Player** (3.500 righe) è il cuore: crea il corpo fisico, applica i
  comandi, controlla se il robot tocca terra, calcola il danno da caduta,
  riceve i colpi (`ApplyHit`) e anima il robot (SmoothMoves, animazione a ossa 2D).
- **PlayerControlByGUI** traduce le due levette in "istruzioni" (sinistra,
  destra, salta, mira, potenza, spara) e le passa a Player una volta per frame.
- **RangeWeapon** è un unico script molto parametrico che fa tutti i
  proiettili: missili, granate rimbalzanti, mine che si attaccano, bombe che
  strisciano sul terreno, frammenti, teletrasporto. Cambiano solo i numeri del prefab.
- **LevelData** tiene il terreno diviso in 4 × 4 regioni; un'esplosione
  sottrae un cerchio (12–20 lati) dai poligoni della regione, li semplifica e
  ricrea i corpi statici. Il disegno è una texture a cui si azzera l'alfa nel
  cerchio (sulla GPU se possibile).
- **Sequenze**: un sistema di nodi (eventi, condizioni, azioni) scritto da
  Kabam. "Next Turn" gestisce ordine, durata e troncamento del turno.

### La rete, in confronto alla nostra

Blastron si fidava dei client: chi è di turno simula il suo robot e i suoi
proiettili sul telefono e manda agli altri posizione e velocità (in virgola
fissa a 16 bit), più gli RPC `FireRPC` (sparo) e `ApplyHit` (danno, spinta).
L'host fa partire i turni e le casse. Per questo la fisica non doveva essere
deterministica. MegaBlast invece ha il server che fa girare la stessa
simulazione Lua: è più robusto contro i trucchi e le desincronizzazioni, e
resta la scelta giusta.

## La fisica

### Unità

Il mondo usa "unità" Farseer. Il robot è alto **3,61 unità** (36,12 decimi;
molte grandezze nel Tuning sono in decimi). Le mappe sono larghe circa
**102 unità** e alte 51: un robot è alto il 7% della mappa e la telecamera di
default mostra quasi tutta l'altezza. La fisica fa un passo fisso per
`FixedUpdate`.

### Il robot

| Grandezza | Blastron | In altezze di robot |
|---|---|---|
| Gravità | 25 u/s² | 6,9 /s² |
| Corsa (a terra e in aria) | 5 u/s | 1,4 robot/s |
| Altezza del salto | 5,2 u | 1,44 robot |
| Velocità del salto | √(2·25·5,2) = 16,1 u/s | tempo in aria 1,29 s |
| Caduta senza danno | fino a 40 u | 11 robot |
| Danno da caduta | (caduta − 40) × 15, al massimo 60 × 15 = 900 | 45% della vita base |
| Vita base | 2.000 (più i bonus dei pezzi d'armatura) | |
| Danno a sé stessi | 50% | |
| Pavimento della morte | 10 unità sotto lo zero della mappa | |

Come si muove (è la parte più importante per la sensazione di gioco):

- **Niente accelerazione**: la velocità orizzontale è impostata direttamente
  a ±corsa quando tieni la direzione, sia a terra sia in aria. Controllo in
  aria pieno e istantaneo, anche per cambiare verso.
- **A terra** senza comandi si ferma di colpo. **In aria** senza comandi
  mantiene la velocità orizzontale che aveva.
- La velocità orizzontale del robot di turno è sempre limitata a ±corsa, anche
  dopo una spinta: chi viene sbalzato durante il proprio turno può subito
  frenare o girarsi. Gli altri robot volano liberi.
- **Salto**: solo da terra, imposta la velocità verticale; se in quel momento
  tieni una direzione parte anche in quella direzione. Tenendo la levetta in
  alto salta di nuovo appena tocca terra.
- Il corpo è un cerchio a rotazione bloccata con attrito 1 (attrito quasi zero
  mentre salta), quindi sale gradini e pendenze da solo. "A terra" vuol dire che
  un raggio verso il basso trova una superficie con pendenza fino a circa 75°.
- I robot si scontrano tra loro: camminando contro un altro lo si spinge.
- Il danno da caduta conta dal punto più alto raggiunto da quando ha iniziato
  a scendere (anche se ci è finito per un'esplosione).

### Proiettili

Per ogni proiettile la velocità di lancio è
`velocità = min + (max − min) × curva(potenza)`, con `min` quasi sempre 0 e
la curva quasi lineare. Poi è un corpo Box2D normale: gravità × un fattore
per arma, rimbalzo, smorzamento dopo il primo urto, timer di esplosione. Il
proprio robot viene ignorato per mezzo secondo dopo lo sparo.

### Esplosioni

Ogni esplosione ha due raggi: il **cratere** (`blastRadius`) e il raggio del
**danno e della spinta** (`concussionRadius`, sempre più grande). Per ogni
robot nel raggio:

- la distanza si misura dal centro dell'esplosione al **punto più vicino del
  rettangolo** del robot (non al suo centro);
- `t = 1 − distanza / raggio`;
- danno = `danno_min + t × (danno_max − danno_min)`, ridotto del 50% se è il proprio;
- spinta: la velocità del robot viene **sostituita** con
  `vettore_dal_centro_al_punto_più_vicino × impulso × t`. Il vettore non è
  normalizzato, quindi la spinta è massima a metà raggio e **zero** se
  l'esplosione è proprio addosso al robot (colpo diretto: tanto danno, nessuna
  spinta). È quasi certamente una svista del codice originale, ma è il
  comportamento che i giocatori conoscevano. Per i robot non c'è la spinta
  verso l'alto extra: quella vale solo per casse e oggetti.

### Le armi che ci servono (valori originali)

| Arma | Velocità max | Gravità | Rimbalzo | Timer | Cratere | Raggio danno | Danno | Impulso |
|---|---|---|---|---|---|---|---|---|
| Rocket | 75 u/s | ×1,1 | esplode al contatto | — | 5 u | 9 u | 150–300 | 10 |
| Grenade | 85 u/s | ×1,3 | 0,4, smorzamento 1/s dopo l'urto | 5 s | 5,5 u | 10 u | 300–550 | 15 |
| Teleport Grenade | 80 u/s | ×1,1 | 0,4, smorzamento 1,1/s | 3 s | — | — | — | — |
| Hand Cannon | 90 u/s | ×1,5 | 0,5 | 3 s | 8 u | 12 u | 330–1000 | 15 |
| Little A Bomb | 90 u/s | ×1,5 | al contatto | — | 17,5 u | 22,5 u | 500–1500 | 25 |
| Big Ol' Bomb | 90 u/s | ×1,6 | al contatto | — | 25 u | 35 u | 750–2000 | 30 |

Altre famiglie: granate a grappolo (6 frammenti a ventaglio di 80°),
rimbalzanti (rimbalzo 1, timer 12 s), mine che si attaccano e scattano se ti
avvicini, "Mr. Nibbles" che striscia sul terreno, missili multipli a ventaglio
(fino a 8 colpi su 25°), bombardamenti dal cielo dove punti.

- **Teletrasporto** (Teleport Grenade): **non** chiude il turno. Allo scoppio
  sposta il robot nel punto della granata **senza toccare la sua velocità**. Se
  nasce dentro il terreno esplode subito senza teletrasportare.
- **Corpo a corpo**: un rettangolo attaccato all'osso dell'arma che segue
  l'animazione; i colpi contano solo nella "finestra" aperta e chiusa da eventi
  dell'animazione. Hanzo Special (spada): 6 × 1 u, 300 danni, nessuna spinta.
  Flame-Yuken (montante): 3,5 × 3 u, 1.000 danni, lancia il bersaglio dritto
  in alto a 40 u/s e chi colpisce fa un saltello di 15 u/s.
- **Raggi e pistole** (Six Shooter, Minigun, laser): colpi istantanei lungo la
  mira, ripetuti a intervalli (Six Shooter: 100 danni ogni 0,5 s per 3 s). Con
  alcune si può **continuare a mirare mentre sparano**.

## I comandi

Due levette virtuali, una per lato:

- **Levetta sinistra (movimento)**: spostata di lato oltre il 15% cammina; se
  è inclinata verso l'alto oltre 25° e spinta oltre il 25% salta (e risalta
  finché la tieni). Per smettere di camminare bisogna portarla quasi in
  verticale (oltre 60°).
- **Levetta destra (mira)**: la direzione è la mira, la distanza dal centro la
  potenza. Sotto il 20% non mira; la potenza è `((spinta − 0,2) / 0,8)²`,
  quindi quadratica: tanta precisione sui tiri corti. La mira non segue il dito
  di colpo: ogni frame copre il 20% della differenza. **Lasci e spara**;
  riportandola al centro (sotto il 10%) si annulla.
- La **traiettoria non si vedeva**: solo una freccia lunga quanto la potenza.
  La traiettoria completa compariva solo nel tutorial o con il potenziamento
  "mira assistita".

## Turni e partita

| | Blastron |
|---|---|
| Turno | 25 s, **30 s se i giocatori sono 2** |
| Dopo lo sparo | il tempo rimasto scende a **5 s** (se ne restava di più): ci si può ancora muovere, ma non sparare |
| Pausa tra i turni | 1 s |
| Partita (deathmatch) | 5 minuti, a punti |
| Punti | ogni colpo dà punti in proporzione a `t`, un'uccisione 1.000, un suicidio −250, moltiplicatore per colpi consecutivi |
| Ordine | alternato per squadra |
| Inattività | dopo 3 turni senza fare niente si viene espulsi |
| Casse | a ogni turno una probabilità che ne cada una in un punto fisso della mappa: 90% se non ce ne sono, 50% con una, 30% con due, 10% con tre, mai con quattro |

Il turno finisce quando scade il tempo, anche se qualcosa sta ancora volando.

## Come l'ho portata in MegaBlast

Profilo di fisica `blastron` nella simulazione condivisa (client e server),
vedi la PR. Le unità sono convertite con le **proporzioni dell'arena di
Blastron**: là era larga 102,4 unità, la nostra mappa 1280 pixel, quindi 1 unità
= **12,5 pixel** e il robot (3,61 unità) è alto 45 pixel. La vita resta 100 e
tutti i danni sono riscalati da 2.000 a 100.

Così la mappa è larga 28 robot come in Blastron, e attraversarla a piedi
richiede circa 20 s. All'inizio la scala andava per altezze di robot (robot da
16 pixel, 1 unità = 4,43 pixel): le mappe erano tre volte più grandi rispetto al
robot. Altri dettagli in [comandi e hitbox](blastron_comandi.md#proporzioni).

## Dove la ricostruzione è diversa da quello che avevamo deciso

Il profilo `blastron` è quello predefinito sul branch; `megablast` tiene i
valori di prima. Per ogni punto puoi scegliere quale tenere.

| Cosa | Deciso finora (megablast) | Blastron |
|---|---|---|
| Velocità | corsa 70 px/s, salto 56 px, gravità 600 (robot da 16 px) | corsa 5 u/s, salto 5,2 u, gravità 25 u/s²: rispetto al robot tutto più lento e "galleggiante" |
| Controllo in aria | accelerazione (air_speed²/8), niente controllo mentre si è sbalzati | istantaneo, anche da sbalzati; il robot di turno non supera mai la sua corsa |
| Ritirata dopo lo sparo | 3 s in più | il tempo rimasto scende a 5 s (non si aggiunge niente) |
| Turno | 15 s | 30 s (25 con più di due giocatori) |
| Partita | 3 minuti, vince chi ha più vita | 5 minuti; là era a punti con rinascita, qui resta la nostra regola della vita |
| Danni | missile fino a 45 | missile 8–15, granata 15–28: partite molto più lunghe |
| Danno a sé stessi | pieno | metà |
| Spinta delle esplosioni | dal centro, più forte al centro, sempre un po' in alto | modello Blastron: massima a metà raggio, zero nel colpo diretto, niente spinta verso l'alto |
| Danno da caduta | nessuno | oltre 500 px (40 u), fino a 45 |
| Linea di mira | tutta la traiettoria | solo una freccia corta, lunga quanto la potenza |
| Potenza | proporzionale alla distanza del dito | zona morta 20% e curva quadratica |
| Mira | segue il dito subito | insegue il dito (20% per frame): un attimo di ritardo |
| Movimento | pulsanti < e > | sul telefono due levette come in Blastron: movimento (in alto salta) e mira ([comandi e hitbox](blastron_comandi.md)) |
| Salto | uno per pressione | tenendo premuto risalta appena tocca terra |
| Teletrasporto | 2 s, illimitato | 3 s (illimitato e fino a 6 globi restano come avevi deciso) |
| Casse | una ogni 3 turni | a ogni turno una probabilità: 90%, 50%, 30%, 10% secondo quante ce ne sono |
| Pugno del Titano | 30 danni, lancio 480 px/s in alto e 140 avanti, sempre in avanti | 50 danni, lancio 40 u/s dritto in alto; il montante **gira con la mira** e dura 2,1 s ([comandi e hitbox](blastron_comandi.md)) |
| Lama di Nucleo | il tuo fendente da 240°, uguale per ogni mira, 35 danni subito, 1/3 di secondo | fendente di Hanzo Special **ruotato sulla mira** (mirando in basso cala dall'alto verso il basso), arco di circa 200° che prende anche dietro, 15 danni a chi tocca quando il colpo finisce (0,8 s), ferma il bersaglio ([comandi e hitbox](blastron_comandi.md)) |
| Dove si viene colpiti | la scatola del robot (12 × 16 px) | un cerchio di raggio 1,888 u a metà altezza; le esplosioni misurano da un quadrato di 3,98 u di lato |
| Grandezza del robot | 16 px | 45 px: la mappa è larga 28 robot come l'arena di Blastron |
| Sciame di Schegge | raffica di schegge esplosive | **non toccato** (in Blastron le mitragliatrici erano colpi istantanei e si poteva mirare mentre sparavano) |
| Vento | niente | niente neanche in Blastron |

Per tornare ai valori di prima in locale: in `game.project`, sezione
`[megablast]`, `fisica = megablast`. Per cambiarli anche online:
`M.DEFAULT_PHYSICS` in `client/sim/game.lua` (lo usa anche il server).

## Limiti dell'analisi

- I valori del `Tuning` sono quelli dentro l'APK. Il gioco li poteva
  aggiornare dal server all'avvio: se Kabam li cambiava online, qui non si vede.
- Quello che succede dentro le sequenze (turni, fine partita) l'ho ricostruito
  dalle azioni che usano e dai loro parametri, non aprendo il grafo dei nodi.
- La fisica Box2D (rotolamento, attrito, rimbalzi su pendenze) non è
  riproducibile al decimale sulla nostra griglia di celle: ho portato i
  parametri e i comportamenti, non il solver.
