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
- **Terreno in Go** (`terreno.go`): le celle stanno in un `[]byte` invece che in
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


Quando una coda è piena la stanza apre la scelta delle armi (`sim/draft.lua`):
ognuno riceve `{"t":"draft","offer":[…],"offer2":[…],"p":"","p2":"","you":1,"tok":…,"players":[{"team":1},…],"left":900}`
(`offer` le primarie, `offer2` le secondarie; `p` e `p2` le **sue** scelte:
quelle degli altri non si mandano, Sergio 30 ott; `left` i tick rimasti) e
manda `{"t":"pick","w":"shards"}` per ognuna (l'arma dice la categoria; si può
cambiare, i doppioni vanno bene anche fra compagni). La conferma torna solo a
chi ha scelto. L'attrezzo non si sceglie: il Rampino ce l'hanno tutti. Allo
scadere di `config.DRAFT_SECONDS` chi non ha scelto prende la prima arma di ogni
ventaglio e parte la partita (`start`, con `players`: squadra e scelte di
ognuno, `[{"team":1,"pick":"shards","secondary":"eagle"},…]`, e `regole`, quelle
dell'evento o `null`, così il client crea la sua copia della partita con le
stesse armi e le stesse regole). Chi esce dalla
rotellina in partita manda `{"t":"leave"}`: il server lo toglie subito (come chi
non torna in tempo, senza aspettare), chiude la sua connessione e manda `left`
agli altri; il suo robot sparisce dalla partita (`game:remove`: evento `gone`,
`gn` nello stato, non rinasce e non ha più turni) e si continua finché restano
almeno due squadre. Il client la
mostra con la schermata dello stesso telefono (`client/menu/scelta.lua`). Nello stato ogni robot
porta la sua secondaria in `sw`, l'attrezzo in `at` (e `lu`, `ml`: tick di Affondo e Maglio in
corso, `ms` e `md`: dove si è fermata la testa del Maglio e il suo lato; `hk`: chi lo tira col Rampino, o -1 se è appeso al terreno nel punto
`hx`, `hy`; `gs`: il suo uncino del Rampino è in volo, in `gx`, `gy`; `kn`: sbalzato da un colpo; `la`: direzione dello scatto
dell'Affondo).

## Eventi

Il calendario sta in un file JSON (`go run ./server -eventi eventi.json`, più
avanti lo scrive il pannello) che il server rilegge da solo quando cambia; un
file sbagliato non sostituisce quello buono e l'errore va nel log
(`server/eventi.go`, formato nel commento in cima). Un evento ha `id`, `tipo`
(`mod` = modificatore con la coda sua, `torneo`, `sfida`, `xp` = su una coda
normale, `coda`, di base `2v2`), `nome`, `riga`, `da` e `a` (ora di Roma,
`"2026-11-02 10:00"`), `ogni` (settimane fra una volta e l'altra, 0 = una
volta), `fino` (l'ultimo giorno in cui può ricominciare, vuoto = per sempre),
per i modificatori `modo` (le squadre) e `regole`, e `premi`/`obiettivo` che il
server passa al gioco così come sono. Le **regole** sono solo valori di una
lista bianca (`client/sim/regole.lua`: `casse`, `cure`, `livello`, `armi`,
`punti`): il server le controlla col Lua quando legge il file, le usa per la
scelta delle armi e per la partita, e le manda nello `start` perché il client
faccia la stessa partita.

`GET /eventi` dà `{"ora":…,"eventi":[…]}`: le occorrenze in corso e quelle che
cominciano nei prossimi 14 giorni, ognuna con `id` (`maglio-20261102`), `da`,
`a`, `torna` (la volta dopo), `coda` (da mettere nel `hello`: l'id stesso per un
modificatore, `2v2` per un Torneo), `modo` e `giocatori`. Il gioco le chiede
quando apre la home, la bacheca e DOVE GIOCHI?, e ogni minuto nella home. Un
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
   fase 1 della roadmap).
4. **Prove**: un test in `server/server_test.go` per il comportamento nuovo e
   l'online nel simulatore (`strumenti/simula/scenari/scelta_online.txt`:
   server vero e giocatori finti).
5. **Versione**: se un client vecchio non capirebbe i messaggi nuovi, si alza
   `protocolVersion` (e `PROTOCOL` nel client).

## Protocollo

Il primo messaggio del client è `{"t":"hello","v":6,"mode":"2v2"}` (la coda
scelta in DOVE GIOCHI?, o la `coda` di un evento). Se la
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
`{"t":"hello","v":6,"tok":…}`; il server gli rimanda `start` con
`"resume":true`, gli scavi del terreno e i Bastioni posati o crollati, in ordine (`sync`) e lo stato. Dopo 20 s senza
tornare il giocatore è fuori (`left`) e, se resta una sola squadra, la
partita si chiude.

## Numeri

Prova di carico (`go test ./server/ -run Carico -v -carico 100 -durata 15s`):
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

## Crescere

- **Più core**: i worker sono uno per core (`-workers`), basta una macchina più
  grande.
- **Più server**: ogni nodo è indipendente, non condivide stato con gli altri.
  Si mettono N nodi dietro un bilanciatore: `/health` risponde 503 quando il
  nodo è pieno (worker oltre l'80% del tick) o si sta spegnendo, `/stats` dà
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
