# MegaBlast: design e architettura

MegaBlast è un remake per mobile di **Blastron** (Kabam, 2013): un gioco di artiglieria a turni nello stile di Worms, con robot al posto dei vermi.

La regola che guida ogni scelta è il **minimalismo**: app piccola, avvio quasi istantaneo, poche dipendenze, traffico di rete minimo. Quando ci sono due strade, si sceglie quella più leggera.

---

## 1. Il gioco

### Cosa riprendiamo da Blastron

| Elemento | Come funziona |
|---|---|
| Partita | Duello online 1 contro 1 (deathmatch). In seguito arriva una campagna single player contro bot. |
| Turni | Durano 25 s. Il giocatore di turno può muoversi e saltare per tutto il turno e fare fino a **due attacchi**: un'arma primaria (Lanciarune o un'arma trovata: agiscono sul mondo e sugli altri, con un effetto) e una secondaria (la Lama o quella scelta all'inizio: danno secco, illimitate, ognuna ti sposta a modo suo), in ordine libero; mai due della stessa categoria. Dopo il primo attacco restano 8 s, mai oltre la fine del turno: in tutti e 8 si può fare il secondo attacco, muoversi e usare il resto. La barra è gialla finché il secondo attacco c'è, blu quando li hai usati tutti e due, e lampeggia negli ultimi 2 s. Il turno finisce solo allo scadere di questi 8 s o del timer: chi muore nel proprio turno ricompare e continua. Tutti i numeri delle regole sono in `client/sim/config.lua`. |
| Teletrasporti | Si parte con 2 globi. Al primo attacco del turno i secondi rimasti diventano globi del teletrasporto (1 ogni 10 s, senza tetto): ogni lancio ne consuma uno; al primo turno se ne fa uno solo. L'attrezzo (Rampino o Bastione) si usa una volta per turno, il paracadute una volta per partita, lo scudo (solo dalle casse) e il salto in aria (solo con l'albero o il set Corvo) quando si vuole. Il Nucleo come risorsa non c'è più (Sergio, 24 ottobre 2026: non pesava sulle scelte). Nel Torneo le statistiche di albero ed equipaggiamento non contano. |
| Terreno | La terra è distruttibile: ogni esplosione scava un cratere tondo. I tubi d'acciaio sono indistruttibili e fanno da base solida. |
| Mappe | Fatte a mano, su più piani, con isole volanti. Niente vento. |
| Movimento | Salto libero (anche dritto verso l'alto) e controllo in aria a destra e sinistra. |
| Statistiche | Ogni robot ha velocità a terra, altezza del salto e velocità in aria. L'equipaggiamento le modificherà. Più un robot è veloce in aria, meno inerzia ha quando cambia direzione. |
| Danni | Dipendono dalla distanza dal centro dell'esplosione. Anche l'esplosione stessa spinge il robot (knockback). Chi cade dalla mappa o nell'acqua muore. |
| Collisioni | I robot non si attraversano: camminando contro un altro lo si spinge piano (30% della velocità) e chi cade su un robot gli resta in testa. Il globo del teletrasporto rimbalza sui robot e, se arriva forte, li sposta di 3 px; i globi rimbalzano anche tra loro. |
| Effetti di stato | Le Schegge rallentano (corsa, salto e velocità in aria più bassi), il Pugno incrina l'armatura (si prende il 25% di danno in più), l'Uovo brucia solo con il set Fornace (10 danni all'inizio di ogni proprio turno). Durano fino alla fine del prossimo turno di chi li subisce, si vedono sul robot (fiamma, anello ai piedi, crepa), quando arrivano sale una scritta sopra il robot e sotto la vita restano scritti coi turni che mancano. Lo scudo li ferma. |
| Oggetti tattici | Dalle casse: trappola (ai piedi, armata dal turno dopo), scudo (assorbe 60 e dimezza le spinte fino al proprio turno dopo), trampolino (si lancia). Paracadute (uno a partita): in aria un tocco lo apre e uno lo chiude; aperto si scende piano, ci si muove il 50% più veloci in orizzontale e non si prende danno da caduta. Rampino (uno a turno, sempre nella barra, non è un attacco): colpo dritto e istantaneo fino a 220 px. Su un robot, quello resta appeso alla fune e viene riavvolto dritto verso la tua mano (300 px/s, senza gravità) fin addosso a te, poi mollato dov'è: il pavimento sotto non lo ferma (scivola e sale i gradini), un muro alto o un robot in mezzo sì; intanto ti puoi muovere e la fune segue la mano. Sul terreno sei tu che sali lungo la fune (420 px/s) fino al punto colpito e ti metti in piedi sopra la piattaforma, se la cima è entro 64 px (il fianco di un muro alto no: resti lì e cadi). Niente danno: serve per le uccisioni ambientali e per salire. Al posto del Rampino si può avere il Bastione (anche lui uno a turno, non un attacco): posa un blocco di terreno vero di 48×12 px dove si mira, fino a 160 px secondo la potenza, in piedi se si mira oltre i 45°; non riempie le celle addosso ai robot, si scava come il resto della mappa; al massimo 2 a testa, posando il terzo crolla il più vecchio. |
| Cerchi di cura | Ogni 2 turni, all'inizio del turno, compare un cerchio in un punto a caso della superficie (al massimo 2 insieme, anche sotto un robot). A fine turno, di chiunque, chi ha i piedi dentro riprende 40 di vita e il cerchio sparisce. Numeri in `config.HEAL`. |
| Vittoria | La partita dura 5 minuti e la vince la squadra con più punti (in 1 contro 1 e tutti contro tutti ogni robot è una squadra). Punti: 1 per ogni punto di vita tolto a un avversario, 50 per un'uccisione, 50 in più se è ambientale (fuori dalla mappa o caduta), -20 a chi muore, ×1,5 colpendo chi è primo (la Corona) e 25 in più a chi lo abbatte, 10 a chi ha posato la trappola quando scatta su un avversario, mezzo punto per ogni punto di danno nemico fermato dallo scudo (al massimo 30 per scudo, che dura fino al proprio turno dopo). L'uccisione va a chi ha colpito per ultimo nei 10 s prima; contano come colpo anche il Rampino e il trampolino di un avversario. Chi muore nel proprio turno senza un colpo di un avversario nei 10 s prima (si butta giù, si colpisce da solo) perde 50 punti invece di 20, e l'uccisione (50, senza bonus ambientale) va all'avversario che gli ha fatto più danno in questa vita. Chi muore ricompare dopo 1,5 s, nello stesso turno (anche nel turno di chi l'ha ucciso, che può colpirlo ancora), con la vita piena in un punto libero a caso della mappa, e tiene teletrasporti e colpi. Allo scadere dei 5 minuti ci sono i supplementari: si finisce il giro di turni, fino a chi gioca per ultimo; a pari punti è pareggio. |
| Giocatori | Da 2 a 4: 1 contro 1, 2 contro 2 (le squadre si alternano: A1, B1, A2, B2) o tutti contro tutti. Colpire il compagno fa danno ma non dà punti. |
| Scelta d'inizio partita | Prima della partita due ventagli di 3 armi, uguali per tutti: le primarie delle casse e le secondarie (Tonante, Maglio, Affondo), più il ventaglio dell'attrezzo (Rampino e Bastione, sempre tutti e due), già scelto quello dell'assetto (si cambia nell'armeria). Ognuno prende una primaria (2 colpi), una secondaria (illimitata) e un attrezzo. Due compagni non possono prendere la stessa (possono scambiarsele); nel tutti contro tutti i doppioni vanno bene. Allo scadere dei 15 s chi non ha scelto prende la prima libera. Regole in `client/sim/draft.lua`, le gira la stanza del server prima della partita; sullo stesso telefono si sceglie a turno. |
| Tutorial | Sei passi, uno per regola, ognuno con un bersaglio che non gioca: muoviti e spara, riparati dopo il colpo, la spada, due attacchi (barra gialla, poi blu), il teletrasporto guadagnato attaccando presto, la combo teletrasporto e fendente. Passi e obiettivi in `client/battaglia/tutorial.lua`. Per ora si apre con `[megablast] tutorial = 1` (STESSO TELEFONO); il pulsante nella home arriva con la home nuova. |

### Armi iniziali (MVP)

| Arma | Comportamento |
|---|---|
| Lanciarune (missile) | Traiettoria balistica. Esplode al primo contatto. Sempre disponibile. |
| Uovo di Fiamma (granata) | Rimbalza sul terreno ed esplode dopo una miccia di 3 s (i secondi si vedono sopra l'uovo). Esplosione più grande del missile: cratere 40, danno fino a 57 al centro. Si trova nelle casse. |
| Sciame di Schegge (mitragliatrice) | Raffica di 8 schegge dritte e veloci (la potenza non conta), con danni piccoli (6,5 l'una) e crateri minuscoli. Si trova nelle casse. |
| Pugno del Titano (montante) | Corpo a corpo: 28 di danno a chi è subito davanti e lo lancia in alto; anche chi colpisce si solleva un po'. Si trova nelle casse. |
| Cecchino | Proiettile che parte veloce (520 px/s) e frena (ogni secondo gli resta il 70% della velocità) mentre la gravità cresce a poco a poco (piena dopo 0,8 s): all'inizio va quasi dritto, poi cala sempre di più, così da lontano è difficile mirare. Sul terreno rimbalza come una palla, ogni volta più basso e più lento (contro la superficie tiene il 50%, lungo l'85%), al massimo 6 volte o finché quasi si ferma, e a ogni rimbalzo si schiaccia e tremola come una gelatina; la mira mostra il primo secondo di volo. Chi viene colpito prende 30 di danno ed è sbalzato nella direzione in cui andava il proiettile (280 più una spinta in alto di 80): trampolino sotto i piedi e cecchino per mandarlo via. Si trova nelle casse. |
| Trampolino (oggetto) | Si lancia come l'Uovo e si posa dove tocca terra, o ai piedi del robot che colpisce. Largo 36 px (era 24). Qualsiasi cosa ci cada sopra rimbalza: robot, missili, Uova, schegge, Cecchino, globi del teletrasporto, casse e oggetti. Si rimbalza sempre a 300 px/s, poi restando sopra i salti calano (60% a ogni rimbalzo) finché non si scende o ci si ferma (un colpo allora tocca il terreno sotto: il missile scoppia e porta via il trampolino). Si trova nelle casse. |
| Lama di Nucleo | Secondaria, sempre disponibile. Spadone corpo a corpo: fendente di 240° che parte da dietro la schiena, passa sopra la testa e finisce davanti. Colpisce sia dietro sia davanti (40 unità), una volta per bersaglio, in 1/3 di secondo. Fa solo danno: non spinge via l'avversario. Il movimento non è lineare: prima uno slancio che porta la lama un po' indietro, poi accelera sempre di più fino alla fine. È un attacco: dopo il colpo restano i secondi per ripararsi. |
| Tonante | Secondaria, si sceglie all'inizio. Pistola pesante: colpo dritto e istantaneo (nessun proiettile, una traccia che sfuma) fino a 600 px, si ferma al primo robot o terreno; 23 di danno, niente effetti. Il rinculo spinge chi spara dritto dalla parte opposta alla mira, di 110 px (300 px/s per 22 tick) in qualsiasi direzione, senza gravità: contro il terreno scivola lungo l'asse libero, poi si cade da fermi. Si spara anche per spostarsi. |
| Maglio | Secondaria, si sceglie all'inizio. Martello a due mani che gira attorno alla spalla come la Lama: a riposo sta in spalla, mirando resta alto dietro la testa, nel colpo (12 tick, con lo stesso slancio indietro della Lama) cala davanti e finisce sotto i piedi. Lungo 44 px dalla spalla, colpisce (34) una volta ogni robot che tocca lungo l'arco, davanti, sopra e sotto. La testa si ferma dove sbatte sul terreno e resta lì 12 tick. **Rimbalzo, regola unica**: se il colpo è partito in aria e la testa sbatte su un robot o sul terreno mentre cala (dalla spalla in giù), chi colpisce va in alto a 320 px/s (pogo), una volta per colpo, anche se nel frattempo è atterrato; la targa scrive RIMBALZO!. Da terra non si rimbalza mai. |
| Affondo | Secondaria, si sceglie all'inizio. Scatto nella direzione della mira (520 px/s per 18 tick, circa 156 px) che passa attraverso i robot colpendoli una volta ciascuno (27) col corpo o con la lancia (lunga 40 px dal centro). Gradini e gobbe fino a 16 px li sale senza fermarsi; contro un ostacolo più alto scivola lungo il terreno con la parte di scatto che passa, e si ferma solo quando non passa per niente. Alla fine resta il 35% della velocità: oltre un bordo si vola. A riposo la lancia sta dritta in su. |

### Teletrasporto (Passo d'Ombra)

Non è un'arma della barra: ha un pulsante a parte, ma si usa come un'arma (lo attivi, miri, rilasci). Lancia un globo che vola come il missile e quando tocca il terreno rimbalza e rotola. Dopo 2 secondi il robot compare nel punto del globo **nello stesso stato in cui era**: chi cade continua a cadere con la stessa velocità, il fendente in corso continua e la direzione non cambia. Lanciare il globo non chiude il turno e consuma un teletrasporto: se ne possono lanciare quanti se ne hanno, in qualsiasi momento del turno come gli oggetti (anche dopo gli attacchi e nel riposizionamento), anche mentre altri sono ancora in volo (fino a 6 insieme): ognuno ti teletrasporta allo scadere dei suoi 2 secondi, nell'ordine in cui li hai lanciati, quindi si può attaccare subito dopo. Combo tipica: colpo con la spada dietro la schiena, teletrasporto a metà fendente, colpo davanti nel punto d'arrivo. Il teletrasporto avviene sempre: se il punto è troppo stretto per il robot si compare nel punto libero più vicino, e se il globo è uscito dalla mappa ci si finisce dietro e si cade.

### Casse

Ogni 3 turni (dal turno 4) cade dal cielo una cassa in un punto a caso della superficie, lontano dai robot (al massimo 3 casse in mappa). Scende piano e si posa sul primo terreno che trova; se un'esplosione le scava sotto, ricade. Chi la tocca (anche se viene sbalzato addosso fuori dal suo turno) trova un colpo di un'arma a caso tra Uovo di Fiamma, Sciame di Schegge, Pugno del Titano e Cecchino, o un oggetto tattico; il contenuto resta segreto finché non si apre. Punto e arma vengono dal generatore della partita, quindi server e client sono d'accordo.

### Cosa miglioriamo rispetto a Blastron

- **Movimento**: niente robot che si incastrano. Il robot "scala" automaticamente i gradini piccoli (fino a 4–6 pixel) e scivola sui pendii troppo ripidi.
- **Niente pay-to-win**: in partita contano solo abilità e strategia. Eventuali personalizzazioni sono solo estetiche.

### Controlli touch

- **Movimento**: due pulsanti, sinistra e destra, più il salto.
- **Mira**: trascini il dito dal robot. Riportare il dito sul robot e lasciarlo lì annulla il colpo (al PC: tasto destro mentre si tiene il sinistro). La direzione indica l'angolo, la lunghezza la potenza, e una linea tratteggiata mostra la traiettoria prevista per i primi istanti. Rilasci per sparare.
- **Armi**: una barra in basso al centro con le armi che hai, in tre gruppi col nome sopra: primarie (color brace: Lanciarune sempre, le armi delle casse col numero di colpi rimasti), secondarie (color acciaio: Lama di Nucleo sempre, più quella scelta all'inizio) e oggetti. Finiti i colpi l'arma sparisce dalla barra; usata un'arma, il suo gruppo si spegne per il resto del turno.

---

## 2. Architettura generale

```
┌──────────────────────┐   WebSocket (binario)    ┌──────────────────────┐
│  Client Defold (Lua) │ ◄──────────────────────► │  Server Go           │
│  - rendering         │   input / eventi         │  - matchmaking       │
│  - input touch       │                          │  - una goroutine     │
│  - predizione locale │                          │    per partita       │
│  - sim/ (Lua puro)   │                          │  - sim/ (stesso Lua  │
└──────────────────────┘                          │    via gopher-lua)   │
                                                  └──────────────────────┘
```

Il **server è autoritativo**: decide lui dove cade il colpo, i danni e le posizioni finali. Il client predice localmente per non far percepire attese, poi si allinea a quello che dice il server. Così si elimina il cheating e i due telefoni non vanno mai fuori sincronia.

### Una sola simulazione, scritta una volta

La logica di gioco (fisica, collisioni col terreno, armi, danni) vive in `client/sim/`, scritta in **Lua puro** e senza API di Defold. Sta dentro il progetto Defold perché Defold può caricare solo moduli che si trovano nel progetto, e il server la legge da lì.

- Il **client** Defold la usa direttamente.
- Il **server** Go la esegue con [gopher-lua](https://github.com/yuin/gopher-lua), un interprete Lua 5.1 scritto in Go e senza dipendenze C.

In questo modo client e server usano lo stesso identico codice e non serve riscrivere la fisica due volte. La simulazione gira a passo fisso di 60 tick al secondo.

---

## 3. Client: Defold

**Perché Defold**: il motore pesa circa 2–3 MB, l'app finita resta sotto i 10 MB e parte in meno di un secondo. Un solo progetto esporta su Android, iOS, desktop e web, ed è gratuito e open source. Si scrive in Lua.

Alternative scartate:
- **Godot**: buon motore, ma l'app parte da circa 30 MB.
- **Unity**: parte da oltre 40 MB e ha tempi di avvio più lunghi.
- **raylib/C**: è ancora più leggero, ma interfaccia, input touch e porting su iOS andrebbero scritti tutti a mano.

### Terreno distruttibile

- La mappa è una **maschera a 1 bit per pixel** (pieno o vuoto), ad esempio 2048×1024, cioè 256 KB in memoria.
- Un'esplosione azzera i pixel dentro un cerchio, quindi un cratere è un'operazione di pochi microsecondi.
- Le collisioni sono letture sulla maschera, senza motore fisico.
- **Rendering**: la maschera viene applicata come canale alfa sopra una texture di terreno disegnata. Quando c'è un cratere si aggiorna solo il rettangolo toccato della texture (`resource.set_texture` con regione).
- **Celle**: 0 vuoto, 1 terra (si scava), 2 acciaio (non si scava mai).
- **Mappe**: sono in `client/sim/maps.lua`. Una mappa si disegna con poche forme (rettangoli, cerchi, tubi) oppure carica una maschera disegnata da `client/sim/mapdata.lua`, generata da `maschera.png` (640×360: nero vuoto, bianco terra, rosso indistruttibile). Nelle partite (in locale e online) la mappa la sceglie il seed fra quelle di `maps.ROTATION`: "forgia" (Forgia dei Titani) e "crogiolo" (Il Crogiolo). Resta "casuale" (colline generate dal seed, per le prove).

### Dipendenze del client

Ce n'è una sola: [extension-websocket](https://github.com/defold/extension-websocket), l'estensione ufficiale Defold per i WebSocket.

---

## 4. Server: Go

**Perché Go**: produce un unico eseguibile statico di pochi MB, avvia in millisecondi e gestisce migliaia di connessioni con poca RAM. Il deploy consiste nel copiare un file.

### Struttura

- **Lobby e matchmaking**: una coda in memoria per modalità. Quando una coda ha abbastanza giocatori si crea una partita.
- **Partita (stanza)**: un proprio stato Lua (gopher-lua). Le stanze girano su un worker per core che le fa avanzare tutte a ogni tick: niente lock nel ciclo di gioco.
- Architettura, riconnessione, numeri di carico e come crescere su più server: [server.md](server.md).
- **Persistenza**: nessuna per l'MVP, perché le partite vivono in memoria. Quando serviranno account e classifiche si aggiunge SQLite: un file, zero amministrazione.

### Dipendenze del server

- [coder/websocket](https://github.com/coder/websocket), una libreria WebSocket minimale.
- [gopher-lua](https://github.com/yuin/gopher-lua).

Alternativa per più avanti: **Nakama** (open source, in Go) ha già account, matchmaking, amici e classifiche, oltre a un client ufficiale Defold. È più pesante perché richiede un database PostgreSQL o CockroachDB, quindi lo valutiamo solo se quelle funzioni diventano necessarie.

---

## 5. Rete e protocollo

Per ora i messaggi sono **JSON** su WebSocket: sono facili da leggere e da fare il debug, e anche così il traffico resta di pochi KB al secondo. Quando il gioco sarà stabile li si può passare in formato binario.

| Messaggio | Direzione | Contenuto |
|---|---|---|
| `{"t":"hello","v":2,"mode":"1v1","tool":"hook"}` | C → S | primo messaggio: versione del protocollo, modalità e attrezzo dell'assetto (o `"tok"` per tornare in partita) |
| `{"t":"error","e":"version"}` | S → C | errore: `version` (aggiorna il gioco), `expired` (partita finita), `draining` (server in spegnimento) |
| `{"t":"wait"}` | S → C | sei in attesa di un avversario |
| `{"t":"draft","offer":[…],"offer2":[…],"offer3":[…],"p":[…],"p2":[…],"p3":[…],"pr":[…],"sw":[…],"you":1,"tok":…,"players":[…],"left":900}` | S → C | scelta delle armi d'inizio partita: primarie, secondarie e attrezzi, scelte di tutti, proposte di scambio (vedi [server.md](server.md)) |
| `{"t":"pick","w":"shards"}` / `{"t":"swap","to":3}` | C → S | scelgo un'arma (primaria, secondaria o attrezzo, lo dice l'arma) / propongo lo scambio al compagno (`"to":0` ritira la proposta) |
| `{"t":"start","seed":…,"map":"forgia","you":1,"tok":…,"resume":false,"players":[{"team":1},…]}` | S → C | la partita parte: mappa, seed, quale robot sei, le squadre e il gettone per tornare se cadi |
| `{"t":"sync","x":[[x,y,r],…]}` | S → C | a chi torna: gli scavi fatti finora nel terreno |
| `{"t":"in","l":true,"r":false}` | C → S | tasti sinistra/destra premuti (inviato solo quando cambiano) |
| `{"t":"jump"}` | C → S | salto |
| `{"t":"fire","a":1.2,"p":0.7}` | C → S | sparo: angolo in radianti e potenza da 0 a 1 |
| `{"t":"state",…}` | S → C | fase, turno, timer, secondi dopo il primo attacco, supplementari, attacchi fatti (e attrezzo usato), teletrasporti, robot e missile (20 al secondo) |
| `{"t":"ev","type":…}` | S → C | eventi: `turn`, `fire`, `explosion` (x, y, raggio), `damage`, `death`, `miss`, `over` |
| `{"t":"away","robot":2}` / `{"t":"back","robot":2}` | S → C | un giocatore ha perso la connessione / è tornato |
| `{"t":"left","robot":2}` | S → C | non è tornato in tempo (20 s): è fuori |

### Flusso di un turno

1. Il server manda l'evento `turn`.
2. Il giocatore di turno si muove e il client invia `in` a ogni cambio di tasto. Il server simula e invia `state` a entrambi, che interpolano le posizioni per avere un movimento fluido.
3. Il giocatore spara con `fire`. Il server simula il volo del missile e lo trasmette dentro `state`. Quando il missile esplode, manda `explosion` e ogni client scava lo stesso cratere nel proprio terreno.
4. Quando i robot sono fermi, il server passa il turno.

Il terreno non viene mai inviato: ogni client lo genera dallo stesso seed e applica gli stessi crateri. Per ora il client non predice il proprio movimento e mostra quello che arriva dal server. In rete locale non si nota; su internet si potrà aggiungere la predizione.

Durante un turno di movimento il traffico è di pochi KB.

---

## 6. Struttura del repository

```
client/        progetto Defold (game.project, main/, input/)
client/sim/    simulazione condivisa in Lua puro (usata da client e server)
server/        server Go (server.go, lobby.go, room.go, sched.go, sim.go, terreno.go, net.lua)
go.mod         modulo Go (alla radice, così il server incorpora client/sim/)
tests/         test della simulazione
docs/          design e note di sviluppo
```

---

## 7. Roadmap

1. **Prototipo locale** (fatto): un client Defold con terreno distruttibile, un robot che cammina e salta e il missile. Hot-seat, cioè due giocatori sullo stesso telefono. Nessun server.
2. **Simulazione condivisa** (fatto): la logica in `client/sim/` gira anche nel server Go.
3. **Online** (fatto, in rete locale): matchmaking 1v1, turni a tempo e il protocollo sopra.
4. **Tutte le armi dell'MVP**, l'equipaggiamento con le statistiche e altre mappe fatte a mano.
5. **Rifinitura**: grafica, suoni, mappe.
6. **Più avanti**: campagna contro bot, account e classifiche.
