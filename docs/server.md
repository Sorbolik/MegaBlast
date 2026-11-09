# Server di MegaBlast

Un nodo è un solo eseguibile Go (`go run ./server`). Accetta i giocatori via
WebSocket, li mette in coda per modalità e fa girare le partite con la
simulazione Lua di `client/sim/`, la stessa del client.

## Come è fatto

```
connessione (goroutine) ──hello──► Lobby (una coda per modalità)
        │                               │ coda piena
        │ input                         ▼
        └──────────► Room.in ──► worker (uno per core, ticker a 60 Hz)
                                  └─ a ogni tick, per ogni sua stanza:
                                     legge gli input, Step della sim,
                                     eventi e stato ai giocatori
```

- **Stanze sui worker** (`sched.go`): un worker per core, ognuno con un solo
  ticker che fa avanzare tutte le sue stanze. Una stanza vive sempre sullo
  stesso worker, quindi la sua partita non ha lock; le connessioni le passano
  gli input con un canale. Le stanze nuove vanno al worker più scarico.
- **Uno stato Lua per stanza** (`sim.go`): il codice Lua si compila una volta
  per processo e gli stati lo condividono. Tutti i moduli di `client/sim/` si
  caricano da soli: chi ne aggiunge uno non tocca il server.
- **Terreno in Go** (`terrain.go`): le celle stanno in un `[]byte` invece che in
  una tabella Lua da 230.400 valori, e le funzioni che leggono o scrivono le
  celle (collisioni, scavi) girano in Go. Le mappe fisse si disegnano una volta
  per processo e ogni partita copia le celle. Il resto di `terrain.lua` resta
  Lua. `TestGoTerrainMatchesLua` e `TestGoTerrainSameMatch` confrontano cella per
  cella e tick per tick con il terreno Lua puro: se `terrain.lua` cambia e il Go
  non lo segue, i test lo dicono.
- **JSON in Go** (`luajson.go`): `net.lua` prepara stato ed eventi come tabelle,
  il server le scrive in JSON. In gopher-lua `string.format` era la parte più
  lenta di tutto il tick.
- **Messaggi**: ogni messaggio si costruisce una volta e va a tutti i giocatori
  della stanza. La coda di uscita di un giocatore non blocca mai la partita: se
  si riempie (client che non legge) la connessione si chiude e il client torna
  con la riconnessione, che gli rimanda tutto. Perdere un messaggio invece gli
  lascerebbe un terreno sbagliato.

## Code e scelta dell'arma

Le code normali sono `2v2` (quella di sempre, la prediletta), `1v1` e `ffa`
(tutti contro tutti: nel gioco solo come evento). I giocatori e le squadre di
ogni modo vengono da `config.MODES` della simulazione. Gli eventi con la coda
loro aggiungono una coda per occorrenza (sotto).

Finché la coda non è piena, a ogni entrata e uscita tutti quelli in coda
ricevono `{"t":"wait","of":4,"you":2,"vetrine":[{"liv":12,"bdg":[…]},{}]}`:
quanti servono alla partita, il proprio posto e i cartellini di chi aspetta,
nell'ordine della coda (la sala d'attesa del gioco, `client/menu/lobby.lua`).
Chi si scollega in coda esce dalla coda (`Lobby.Leave`).

**Bot che riempiono la coda** (Sergio, 3 nov): nelle code normali, se la coda
non è piena `BotAfter` dopo l'entrata del primo (25 s, flag `-bot-dopo`, 0 =
mai), la stanza parte coi posti vuoti presi dai bot. Il `wait` ha allora anche
`"bot_in":N`, i secondi che mancano (il gioco li conta da solo). Le persone
prendono i posti di `config.MODES` nell'ordine, che alterna le squadre: due
persone in un 2 contro 2 finiscono in squadre diverse. Il grado del bot
(`sim/bot.lua`, `M.GRADES`) è 3 + il livello medio delle persone / 5, al massimo
8 (`botGrade`). Nella scelta delle armi il bot sceglie subito (`bot.choose`), il
suo cartellino è `{"bot":true}` e in `players` ha `"bot":G`; in partita
`N.step` usa i suoi tasti (`bot.input`). Sul server il bot pensa al massimo
`N.WORK` = 100 tick simulati per tick (sul telefono 400): con 400 una stanza
da 4 bot "normale" costava 2,2 ms a tick con punte di 50 ms in gopher-lua, con
100 1,6 ms e punte di 21 ms (misure del 3 nov). Così pensava fino a 8 s fermo
a inizio turno e spesso tirava allo scadere: dopo `N.THINK_MAX` = 120 tick
(2 s) di pensiero gioca la mossa migliore trovata fino lì (`think_max` del
livello in `sim/bot.lua`, che sul telefono non c'è). Primo attacco del turno
in una 2v2 di bot grado 5: mediana da 5,3 a 2 s, il più lento da 18,6 a 8 s
(9 nov). Dare al bot più lavoro (250) quando il worker è scarico è stato
provato e scartato: 0,3 s in meno in media, tick fino a 34 ms. Mentre pensa
il bot mostra dove mira (`aim` nello stato, `bot.shown_aim`). Le stanze coi bot girano su
worker loro (`botSched`), così le punte non rallentano le partite fra persone;
`/health` dice `bot_rooms` e `bot_late_ticks`. Una stanza resta aperta finché
c'è almeno una persona. Le code degli eventi non hanno bot.


Quando una coda è piena la stanza apre la scelta delle armi (`sim/draft.lua`):
ognuno riceve `{"t":"draft","offer":[…],"offer2":[…],"p":"","p2":"","you":1,"tok":…,"players":[{"team":1},…],"vetrine":[{"liv":12,"bdg":[…]},…],"left":1200}`
(`offer` le primarie, `offer2` le secondarie; `p` e `p2` le **sue** scelte:
quelle degli altri non si mandano, Sergio 30 ott; `left` i tick rimasti;
`vetrine` il cartellino di ognuno, livello e badge, arrivati col `hello` e
controllati dal server) e
manda `{"t":"pick","w":"shards"}` per ognuna (l'arma dice la categoria; si può
cambiare, i doppioni vanno bene anche fra compagni). La conferma torna solo a
chi ha scelto. L'attrezzo non si sceglie: il Rampino ce l'hanno tutti. Allo
scadere di `config.DRAFT_SECONDS` chi non ha scelto prende la prima arma di ogni
ventaglio e parte la partita. Il tempo della scelta comprende anche i
`config.LINEUP_SECONDS` dello schieramento (i cartellini di tutti, prima
di scegliere: `client/menu/lineup.lua`), in cui si può già scegliere
(`start`, anche lui con `vetrine`, e con `players`: squadra e scelte di
ognuno, `[{"team":1,"pick":"shards","secondary":"eagle"},…]`, e `regole`, quelle
dell'evento o `null`, così il client crea la sua copia della partita con le
stesse armi e le stesse regole). Chi esce dalla
rotellina in partita manda `{"t":"leave"}`: il server lo toglie subito (come chi
non torna in tempo, senza aspettare), chiude la sua connessione e manda `left`
agli altri; il suo robot sparisce dalla partita (`game:remove`: evento `gone`,
`gn` nello stato, non rinasce e non ha più turni) e si continua finché restano
almeno due squadre. Lo stesso `leave` mandato mentre si è ancora in coda
(ESCI DALLA CODA, o un'altra coda) toglie subito dalla coda e chiude la
connessione, così chi esce non resta primo della fila (l'orologio dei bot) né
prende un posto nella partita dopo. Il client la
mostra con la schermata dello stesso telefono (`client/menu/pick.lua`). Nello stato ogni robot
porta la sua secondaria in `sw` (i suoi colpi in `ss`), l'attrezzo in `at` (e `lu`, `ml`: tick di Affondo e Maglio in
corso, `ms` e `md`: dove si è fermata la testa del Maglio e il suo lato; `hk`: chi lo tira col Rampino, o -1 se è appeso al terreno nel punto
`hx`, `hy`; `gs`: il suo uncino del Rampino è in volo, in `gx`, `gy`; `kn`: sbalzato da un colpo; `la`: direzione dello scatto
dell'Affondo).

## Partite private

Per provare con gli amici o coi bot (Sergio, 6 nov; `server/private.go`, nel
gioco PARTITA PRIVATA in DOVE GIOCHI?, `client/menu/private.lua`). Il `hello`
con `"privata":"nuova"` apre una stanza e le dà un codice di 4 cifre; con
`"privata":"4821"` si entra in quella stanza, al posto del primo bot (codice
sbagliato: `{"t":"error","e":"codice"}`; stanza piena di persone: `"piena"`).
La stanza ha un posto per ogni giocatore del modo (`config.MODES`, quindi le
squadre), ognuno una persona o un bot di un grado da 1 a 10 (`sim/bot.lua`
`GRADES`; all'inizio quello della coda, `botGrade`). A ogni cambio tutti
ricevono
`{"t":"privata","code":"4821","mode":"2v2","you":1,"host":1,"posti":[{"team":1,"vetrina":{…}},{"team":2,"bot":5},…]}`.
Chi ha creato la stanza (`host`) manda `{"t":"modo","mode":"1v1"}` (le persone
vanno nei primi posti), `{"t":"bot","i":3,"g":7}` e `{"t":"via"}`; tutti
possono mandare `{"t":"posto","i":3}` per passare al posto di un bot (il bot
prende il loro: così si sceglie la squadra, con o contro i bot) e
`{"t":"leave"}`. Se l'host esce, lo diventa la prossima persona; una stanza
vuota sparisce. Col `via` la stanza diventa una stanza normale (`newRoom` con
i posti come sono, `seatSpec`): scelta delle armi, schieramento e partita come
in coda; con dei bot gira sui worker dei bot.

## Eventi

Il calendario lo fa Sergio nel **pannello degli eventi** (Worker di Cloudflare
`megablast-eventi`, [strumenti/eventi](../strumenti/eventi/README.md)): il
server lo scarica ogni 30 secondi
(`go run ./server -eventi https://megablast-eventi.….workers.dev/eventi.json`,
con l'ETag) e nella domanda dice quale versione ha preso e, se l'ha rifiutata,
perché, così il pannello lo mostra. Oppure da un file JSON
(`go run ./server -eventi eventi.json`) che il server rilegge da solo quando
cambia. In tutti e due i casi un calendario sbagliato non sostituisce quello
buono e l'errore va nel log (`server/events.go`, formato nel commento in cima). Un evento ha `id`, `tipo`
(`mod` = modificatore con la coda sua, `torneo`, `sfida`, `xp` = su una coda
normale, `coda`, di base `2v2`), `nome`, `riga`, `da` e `a` (ora di Roma,
`"2026-11-02 10:00"`), `ogni` (settimane fra una volta e l'altra, 0 = una
volta), `fino` (l'ultimo giorno in cui può ricominciare, vuoto = per sempre),
per i modificatori `modo` (le squadre) e `regole`, e `premi`/`obiettivo` che il
server passa al gioco così come sono. Le **regole** sono solo valori di una
lista bianca (`client/sim/rules.lua`: `casse`, `cure`, `livello`, `armi`,
`punti`, `tetto`; su una coda normale solo `tetto`, il tetto ai livelli dei
pezzi, che non cambia la partita e conta quando online arrivano gli assetti): il server le controlla col Lua quando legge il file, le usa per la
scelta delle armi e per la partita, e le manda nello `start` perché il client
faccia la stessa partita.

`GET /eventi` dà `{"ora":…,"eventi":[…]}`: le occorrenze in corso e quelle che
cominciano nei prossimi 14 giorni, ognuna con `id` (`maglio-20261102`), `da`,
`a`, `torna` (la volta dopo), `coda` (da mettere nel `hello`: l'id stesso per un
modificatore, `2v2` per un Torneo), `modo` e `giocatori`. Il gioco le chiede
nella schermata d'ingresso, prima di aprire la home (`client/ui/entry.lua`),
poi tornando alla home, aprendo la bacheca e DOVE GIOCHI?, e ogni minuto nella
home. La risposta ha `Cache-Control: no-store`: mai una copia vecchia. Un
`hello` con la coda di un evento non in corso riceve `{"t":"error","e":"evento"}`.
Una partita conta per tutti gli eventi della sua coda (classifiche e premi col
passo 2, quando ci sono gli account).

Per provarli sul PC: `python3 strumenti/simula/eventi_prova.py` scrive
`simulazione/eventi.json` col calendario di prova alle date di oggi, poi
`go run ./server -eventi simulazione/eventi.json`.

## Server in pari con main

Regola permanente di Sergio (29 ottobre): il server è sempre in pari con
`main`. Ogni PR che cambia regole, simulazione o protocollo aggiorna anche il
server nella stessa PR. La simulazione la incorpora da solo (tutti i moduli di
`client/sim/`), ma ogni volta si controlla:

1. **Stato** (`net.lua`, `N.snapshot`): ogni campo di robot o partita nuovo che
   il client legge (`apply_state` in `client/main/game.gui_script`, HUD,
   personaggio) va nello stato; altrimenti online resta fermo al valore
   iniziale. Lo stesso per gli eventi che cambiano il terreno (`N.events`,
   `N.sync`).
2. **Messaggi** (`room.go`, `server.go`): un comando nuovo del giocatore (arma,
   attrezzo, oggetto) passa da `fire.w` o da un messaggio nuovo; il server lo
   deve accettare.
3. **Dati del client**: quello che il client passa a `game.new` o a
   `draft.new` solo in locale (assetto, profilo) online deve arrivare col
   `hello` o restare fuori consapevolmente (oggi: le statistiche
   dell'equipaggiamento, che arriveranno con la progressione sul server,
   fase 1 della roadmap; del cartellino arrivano solo livello e badge, e il
   cartellino online mostra le statistiche che valgono davvero, quelle di base).
4. **Prove**: un test in `server/server_test.go` per il comportamento nuovo e
   l'online nel simulatore (`strumenti/simula/scenari/scelta_online.txt`:
   server vero e giocatori finti).
5. **Versione**: se un client vecchio non capirebbe i messaggi nuovi, si alza
   `protocolVersion` (e `PROTOCOL` nel client).

## Protocollo

Il primo messaggio del client è `{"t":"hello","v":8,"mode":"2v2","vetrina":{"liv":12,"bdg":[{"id":"mira","grado":2}]}}`
(`mode`: la coda scelta in DOVE GIOCHI?, o la `coda` di un evento; `vetrina`:
livello e al massimo tre badge, il server tiene solo i valori validi, livello
1-999, badge di lettere minuscole con grado 1-4). Se la
versione non è quella del server la risposta è `{"t":"error","e":"version"}` e
il client chiede di aggiornare il gioco. La versione (`protocolVersion` in
`server.go`, `PROTOCOL` nel client) va alzata quando i messaggi cambiano in un
modo che un client vecchio non capirebbe. Gli altri messaggi sono in
[design.md](design.md#5-rete-e-protocollo).

### Riconnessione

Con `start` il client riceve un gettone. Se la connessione cade (sui telefoni
succede, per questo il server manda anche un ping ogni 10 s), gli altri
ricevono `away`, i tasti tenuti premuti si lasciano e la partita va avanti: se
era il suo turno, il tempo scorre. Si può tornare anche durante la scelta
dell'arma (il gettone arriva già col primo `draft`). Il client riprova da solo per circa 18 s con
`{"t":"hello","v":8,"tok":…}`; il server gli rimanda `start` con
`"resume":true`, gli scavi del terreno e i Bastioni posati o crollati, in ordine (`sync`) e lo stato. Dopo 20 s senza
tornare il giocatore è fuori (`left`) e, se resta una sola squadra, la
partita si chiude.

## Numeri

Prova di carico (`go test ./server/ -run Load -v -carico 100 -durata 15s`):
partite 1v1 con giocatori finti collegati via WebSocket che camminano, saltano
e sparano a caso. I giocatori finti girano nello stesso processo, quindi
rubano CPU al server: i numeri veri sono un po' migliori. Macchina: 4 core
Xeon a 2,8 GHz.

| | Prima | Adesso |
| --- | --- | --- |
| Creare una partita | 144 ms di CPU | meno di 1 ms |
| Memoria per partita | 6–10 MB | 0,9 MB |
| Scrivere uno stato in JSON | 150 µs | 29 µs |
| CPU per partita e tick | 560–670 µs | 230 µs |
| 100 partite insieme | worker pieni, 10–15% dei tick in ritardo | 34% dei worker, 0,5% in ritardo |

Con le regole competitive (teletrasporti, due attacchi, oggetti tattici, effetti di
stato, partite che finiscono solo a tempo):

| Modo | CPU per partita e tick | Partite per core | Giocatori per core |
| --- | --- | --- | --- |
| 1v1 | 220 µs | circa 75 | circa 150 |
| Tutti contro tutti (4) | 320 µs | circa 50 | circa 200 |

Un server da 4 core regge circa 300 partite 1v1 o 200 partite a 4, cioè
600–800 giocatori. Il collo di bottiglia ora è la
simulazione stessa in gopher-lua (lettura delle costanti del modulo e
chiamate di funzione): metà del tempo del tick va lì.

**Partite con i bot** (`-bot`: una persona per partita, i bot della coda negli
altri posti, come online quando si è in pochi; le partite girano sui worker dei
bot). Misure del 9 nov, 4 core, `-carico 30 -durata 20s -modo 2v2 -bot`:

| | CPU per partita e tick | Partite per core | Tick in ritardo |
| --- | --- | --- | --- |
| 2v2, una persona e 3 bot | circa 1.200 µs | circa 14 | 8–9% con 30 partite |

Rifatta dopo #240 (il bot riusa le copie della partita: sul telefono molta meno
spazzatura): sul server uguale, circa 1.250 µs, perché in gopher-lua il tempo
non va nel creare le copie ma nel farle avanzare. Una partita coi bot costa quasi 5 volte una fra persone: è il bot che pensa
provando le mosse su copie della partita (`sim/bot.lua`), in gopher-lua. Finché
online si è in pochi quasi ogni partita ha bot, quindi un server da 4 core regge
circa **50 persone** che giocano contro i bot. Le leve sono nel bot (meno copie,
ricerca più corta: le condivide col telefono) o LuaJIT (sotto, «Crescere»).

Il 9 nov (analisi https://claude.ai/artifact/Ru2WqL6KzafQbuYYzkBY1e):
- lo stato riusa le tabelle dei robot (`net.lua`, stesso JSON di prima) e il
  raccoglitore di Go parte con `GOGC` = 200 (`main.go`, se non è nell'ambiente):
  1v1 da circa 265 a 245 µs per tick (-8%); con i bot non si vede, è tutto pensiero;
- il carico di un worker è la media degli ultimi 32 tick, non l'ultimo: un bot
  che pensa 30 ms in un tick non fa più rispondere 503 a `/health`; le stanze
  nuove vanno al worker meno carico per tempo misurato, non per numero di stanze
  (una partita con 3 bot ne vale 5 senza);
- al più 30 messaggi al secondo per connessione (60 di fila), il resto si butta:
  un client rotto non riempie la coda della stanza facendo perdere i tasti agli
  altri; il rientro di chi si riconnette ha una coda sua e non si perde più;
- `-pprof 127.0.0.1:6060` accende i profili di Go sul server vero (solo in
  locale: `go tool pprof http://127.0.0.1:6060/debug/pprof/profile`).

## Crescere

- **Più core**: i worker sono uno per core (`-workers`), basta una macchina più
  grande.
- **Più server**: ogni nodo è indipendente, non condivide stato con gli altri.
  Si mettono N nodi dietro un bilanciatore: `/health` risponde 503 quando il
  nodo è pieno (worker oltre l'80% del tick, in media sugli ultimi 32 tick) o si sta spegnendo, `/stats` dà
  giocatori, coda, stanze e carico. Il gettone di riconnessione comincia col
  nome del nodo (`-node eu1`), così il bilanciatore può rimandare chi torna al
  nodo giusto. Quando i nodi saranno tanti, la coda passa a un matchmaker
  centrale che assegna la stanza a un nodo; le stanze non cambiano.
- **Aggiornare senza interrompere**: con SIGTERM il nodo smette di prendere
  partite (chi è in coda riceve `draining` e cerca un altro nodo) e si spegne
  quando le partite in corso sono finite.
- **Se servisse ancora più CPU**: far girare la simulazione con LuaJIT invece di
  gopher-lua (via cgo). È molto più veloce, ma il server non sarebbe più un
  eseguibile Go puro.
