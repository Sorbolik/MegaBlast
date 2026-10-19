# MegaBlast: design e architettura

MegaBlast è un remake per mobile di **Blastron** (Kabam, 2013): un gioco di artiglieria a turni nello stile di Worms, con robot al posto dei vermi.

La regola che guida ogni scelta è il **minimalismo**: app piccola, avvio quasi istantaneo, poche dipendenze, traffico di rete minimo. Quando ci sono due strade, si sceglie quella più leggera.

---

## 1. Il gioco

### Cosa riprendiamo da Blastron

| Elemento | Come funziona |
|---|---|
| Partita | Duello online 1 contro 1 (deathmatch). In seguito arriva una campagna single player contro bot. |
| Turni | Sono a tempo e brevi (proposta: 15 s). Il giocatore di turno può muoversi, saltare, mirare e sparare **un** colpo. Il turno finisce dopo lo sparo, allo scadere del timer o quando il robot muore. |
| Terreno | È distruttibile: ogni esplosione scava un cratere. |
| Danni | Dipendono dalla distanza dal centro dell'esplosione. Anche l'esplosione stessa spinge il robot (knockback). Chi cade dalla mappa o nell'acqua muore. |
| Vittoria | Vince l'ultimo robot rimasto in piedi. |

### Armi iniziali (MVP)

| Arma | Comportamento |
|---|---|
| Missile | Traiettoria balistica con vento. Esplode al primo contatto. |
| Granata | Rimbalza sul terreno ed esplode dopo una miccia di 3 s. |
| Mitragliatrice | Raffica di colpi rapidi in linea retta, con danni piccoli e crateri minuscoli. |
| Montante | Attacco corpo a corpo che lancia in alto l'avversario se è adiacente. |
| Teletrasporto | Tocchi un punto libero della mappa e ti ci sposti, al posto dello sparo. |

### Cosa miglioriamo rispetto a Blastron

- **Movimento**: niente robot che si incastrano. Il robot "scala" automaticamente i gradini piccoli (fino a 4–6 pixel) e scivola sui pendii troppo ripidi.
- **Niente pay-to-win**: in partita contano solo abilità e strategia. Eventuali personalizzazioni sono solo estetiche.

### Controlli touch

- **Movimento**: due pulsanti, sinistra e destra, più il salto.
- **Mira**: trascini il dito dal robot. La direzione indica l'angolo, la lunghezza la potenza, e una linea tratteggiata mostra la traiettoria prevista per i primi istanti. Rilasci per sparare.
- **Armi**: una barra in basso con le 5 armi.

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

La logica di gioco (fisica, collisioni col terreno, armi, danni) vive in una cartella `sim/` scritta in **Lua puro**, senza API di Defold.

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
- **Mappe**: ogni mappa è un PNG in bianco e nero (la maschera) più una texture decorativa. Si possono generare anche proceduralmente da un seed.

### Dipendenze del client

Ce n'è una sola: [extension-websocket](https://github.com/defold/extension-websocket), l'estensione ufficiale Defold per i WebSocket.

---

## 4. Server: Go

**Perché Go**: produce un unico eseguibile statico di pochi MB, avvia in millisecondi e gestisce migliaia di connessioni con poca RAM. Il deploy consiste nel copiare un file.

### Struttura

- **Lobby e matchmaking**: una coda in memoria. Quando ci sono due giocatori in attesa si crea una partita.
- **Partita**: una goroutine con il proprio stato Lua (gopher-lua). Tiene il timer del turno, riceve gli input del giocatore di turno, li fa girare nella simulazione e trasmette il risultato a entrambi.
- **Persistenza**: nessuna per l'MVP, perché le partite vivono in memoria. Quando serviranno account e classifiche si aggiunge SQLite: un file, zero amministrazione.

### Dipendenze del server

- [coder/websocket](https://github.com/coder/websocket), una libreria WebSocket minimale.
- [gopher-lua](https://github.com/yuin/gopher-lua).

Alternativa per più avanti: **Nakama** (open source, in Go) ha già account, matchmaking, amici e classifiche, oltre a un client ufficiale Defold. È più pesante perché richiede un database PostgreSQL o CockroachDB, quindi lo valutiamo solo se quelle funzioni diventano necessarie.

---

## 5. Rete e protocollo

Si usano messaggi **binari** compatti su WebSocket: un byte di tipo seguito da campi a dimensione fissa.

| Messaggio | Direzione | Contenuto |
|---|---|---|
| `JOIN` | C → S | versione del client |
| `MATCH_START` | S → C | id partita, seed della mappa, chi inizia |
| `TURN_START` | S → C | giocatore di turno, vento, scadenza |
| `INPUT` | C → S | tick, tasti premuti (bitmask: sinistra, destra, salto) |
| `STATE` | S → C | tick e posizione/velocità dei robot (10 al secondo durante il movimento) |
| `FIRE` | C → S | arma, angolo, potenza |
| `SHOT_RESULT` | S → C | traiettoria (seed), crateri, danni, posizioni finali |
| `TURN_END` | S → C | HP aggiornati |
| `MATCH_END` | S → C | vincitore |

### Flusso di un turno

1. Il server manda `TURN_START`.
2. Il giocatore di turno si muove. Il client mostra subito il movimento (predizione) e invia `INPUT` a ogni cambio di tasto. Il server simula e invia `STATE` a entrambi, e l'avversario vede il robot muoversi interpolando tra gli `STATE`.
3. Il giocatore spara con `FIRE`. Il server simula il colpo fino alla fine e manda `SHOT_RESULT`. Entrambi i client animano la traiettoria con la stessa simulazione e applicano il risultato del server.
4. Il server manda `TURN_END` e passa il turno.

Durante un turno di movimento il traffico è di pochi KB.

---

## 6. Struttura del repository

```
client/     progetto Defold (game.project, main/, assets/)
server/     server Go (go.mod, main.go, match/)
sim/        simulazione condivisa in Lua puro (usata da client e server)
docs/       design e note di sviluppo
```

---

## 7. Roadmap

1. **Prototipo locale**: un client Defold con terreno distruttibile, un robot che cammina e salta e il missile. Hot-seat, cioè due giocatori sullo stesso telefono. Nessun server.
2. **Simulazione condivisa**: si sposta la logica in `sim/` e la si fa girare anche nel server Go.
3. **Online**: matchmaking 1v1, turni a tempo e il protocollo sopra.
4. **Tutte le armi dell'MVP**, il vento e il knockback.
5. **Rifinitura**: grafica, suoni, mappe.
6. **Più avanti**: campagna contro bot, account e classifiche.
