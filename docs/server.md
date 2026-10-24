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

Le code sono `1v1`, `2v2`, `ffa` (tutti contro tutti) e `torneo` (1 contro 1
con le statistiche normalizzate: albero ed equipaggiamento non contano). I
giocatori e le squadre di ogni modo vengono da `config.MODES` della
simulazione.

Quando una coda è piena la stanza apre la scelta delle armi (`sim/draft.lua`):
ognuno riceve `{"t":"draft","offer":[…],"offer2":[…],"p":[…],"p2":[…],"you":1,"tok":…,"players":[{"team":1},…],"left":900}`
(`offer` le primarie, `offer2` le secondarie, `p` e `p2` le scelte fatte) e
manda `{"t":"pick","w":"shards"}` per ognuna delle due (l'arma dice la
categoria; si può cambiare). Nel 2 contro 2 due compagni si scambiano le
scelte, primaria e secondaria insieme, se tutti e due mandano
`{"t":"swap","to":N}`; chi riceve la proposta vede `{"t":"swap","from":N}`. A
ogni cambio tutti ricevono il `draft` aggiornato. Allo scadere di
`config.DRAFT_SECONDS` chi non ha scelto prende la prima arma libera di ogni
ventaglio e parte la partita (`start`, con `players`). Nello stato ogni robot
porta la sua secondaria in `sw` (e `lu`, `ml`: tick di Affondo e Maglio in
corso; `hk`: chi lo tira col Rampino, o -1 se è appeso al terreno nel punto
`hx`, `hy`). Il client online per ora non ha la schermata
della scelta: aspetta e riceve le armi date dal server.

## Protocollo

Il primo messaggio del client è `{"t":"hello","v":2,"mode":"1v1"}`. Se la
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
`{"t":"hello","v":2,"tok":…}`; il server gli rimanda `start` con
`"resume":true`, gli scavi del terreno (`sync`) e lo stato. Dopo 20 s senza
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
