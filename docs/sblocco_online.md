# Quando si sblocca l'online (proposte, 3 nov)

Proposte per il futuro, **niente codice per adesso** (Sergio, 3 nov: «per adesso lascia
così»). Pagina da leggere sul telefono, con gli schizzi della home:
https://claude.ai/artifact/AAFC3FbjbqW6jQ3aWCweB6 . Quando Sergio sceglie, la scelta va in
[decisioni/progressione.md](decisioni/progressione.md) e in `cronologia.md`.

## Cosa chiede Sergio

- Il pulsante si chiamerà **GIOCA ONLINE** (o simile) e all'inizio non c'è, o è spento con
  una riga tipo «le partite online si sbloccano da…».
- Non alla fine dell'Addestramento: sbloccare insieme campagna e online è un bivio piatto.
  Prima la gente deve dare **un'opportunità seria alla campagna**, magari fino a uno o due boss.
- Il più minimalista possibile: **niente accesso alla stessa cosa da due posti**.

## Come è oggi

Home: a destra CAMPAGNA, ALLENAMENTO, STESSO TELEFONO e il grande **GIOCA** dorato (online);
a sinistra EVENTI e ARMERIA (`client/menu/home.lua`). Chi non ha finito Primi passi e tocca
GIOCA finisce in Primi passi (`profilo.new_player`, `first_lesson`, regola di Claude del 29 ott).
Quindi **oggi Primi passi ha già due porte** (GIOCA e CAMPAGNA): è proprio la cosa che
Sergio non vuole, e qualunque proposta qui sotto la toglie.

Anche **EVENTI è una porta dell'online** (il suo GIOCA porta alla coda): in tutte le
proposte EVENTI segue l'online, si apre con lui.

## Il momento

La campagna oggi: Addestramento (6 lezioni) → I girone, la Forgia (si apre con 8 stelle):
5 missioni, il Fabbro (custode), la Battaglia della Forgia (2 contro 2 con un compagno bot).
Nella proposta dei gironi dell'inferno la Forgia diventa il Prologo e il secondo custode è
Caronte (I girone, Limbo).

**Aggiornato il 4 nov (Sergio): la fine della Forgia non apre l'online, apre i gironi**
(«dopo la forgia ci sono tutti i gironi [...] lì sbloccherei i gironi», con la mappa ad anelli).

Consiglio ora: **l'online si apre battendo Caronte, il custode del primo girone (il Limbo)**.
È il secondo boss («uno o due boss»), arriva dopo che hai visto la mappa dei gironi e ci hai
giocato un girone intero, e non coincide con nessun altro sblocco: la Forgia apre i gironi,
Caronte apre l'online. Il momento è un dato (l'id della missione che apre l'online), quindi
si sposta cambiando una parola. Alternativa più tardi: il custode del secondo girone (Minosse).

**Finché il Limbo non c'è** il lucchetto non si fa: l'online resta aperto come oggi e il
lucchetto arriva nella stessa PR del primo girone, così nessuno resta chiuso fuori.

## Dove stanno i gironi

Consiglio: **una porta sola, CAMPAGNA, che cambia faccia**. Prima della fine della Forgia
CAMPAGNA apre i capitoli di oggi (Addestramento, Forgia). Vinta la Battaglia della Forgia,
una vignetta della storia apre la porta dell'inferno e da lì in poi CAMPAGNA apre **la mappa
ad anelli**: in cima, fuori dall'imbuto, la Forgia e l'Addestramento (si rigiocano per le
stelle), sotto gli anelli dei gironi, quelli chiusi scuri. In home non cambia niente: il
pulsante è lo stesso, e l'interfaccia diversa è dentro.

Scartate: un pulsante GIRONI accanto a CAMPAGNA (due porte della stessa campagna, e la
Forgia dove starebbe?); la mappa ad anelli fin dall'inizio con tutto scuro (spoiler di tutto
l'inferno al primo tocco; si può valutare con la storia); un'opzione nella fine livello «vai
ai gironi» (seconda porta).

## Le proposte

### 1. Il lucchetto che promette (consigliata)

- **Prima**: CAMPAGNA è il pulsante grande dorato in basso a destra (la cosa da fare adesso).
  Sopra, al posto piccolo, **GIOCA ONLINE spento con un lucchetto** e sotto una riga:
  «Si apre nella campagna». EVENTI non c'è (un solo lucchetto in home, non due), ARMERIA neanche (arriva col regalo, sotto).
- **Tocco sul lucchetto**: il pulsante trema e la riga diventa per 3 secondi
  «Le partite online si aprono quando batti Caronte».
  Senza spoiler: «Le partite online si aprono quando batti il custode del primo girone».
  Nessun pulsante che porta alla campagna: la porta della campagna è una sola.
- **Lo sblocco**: nella fine livello di Caronte, sotto le stelle, una riga in più:
  «PARTITE ONLINE APERTE. Sfida altri giocatori dalla home.» Niente pulsante «vai online»
  lì (sarebbe una seconda porta). Tornando in home il lucchetto si rompe una volta sola,
  GIOCA ONLINE scende al posto grande dorato, CAMPAGNA sale al suo posto ed EVENTI appare.
- **Perché**: chi scarica un gioco online vede subito che l'online c'è e cosa serve per
  arrivarci, quindi non pensa che manchi. Il posto grande va sempre alla cosa da fare adesso.
- **Minimale**: una funzione nel profilo (online aperto sì o no) al posto di `new_player` e
  `first_lesson`, il pulsante spento esiste già in `ui.button` (`spento`), lo scambio dei due
  posti è un `if` in `home.lua`.

### 2. La porta nascosta

- **Prima**: l'online non c'è. In home CAMPAGNA grande, ALLENAMENTO e STESSO TELEFONO;
  niente EVENTI.
- **Il segnale**: nella campagna, sull'anello del Limbo nella mappa, un sigillo
  piccolo: «Vincila e si aprono le partite online». È un'informazione, non una porta.
- **Lo sblocco**: come la 1, e in home il pulsante nuovo appare con la scritta NUOVO.
- **Pro**: in home nessun pulsante morto, ed è una sorpresa.
- **Contro**: chi ha scaricato il gioco per l'online non lo trova per qualche ora (Addestramento,
  Forgia e Limbo) e può pensare che non ci sia. Il sigillo lo vede solo chi arriva alla mappa.

### 3. La home che cresce (scelta da Sergio il 4 nov, vedi sotto)

- **Prima**: solo CAMPAGNA, grande, più il profilo e le impostazioni.
- **Dopo l'Addestramento**: appaiono ALLENAMENTO e STESSO TELEFONO (sono offline, si usa
  quello che hai imparato). ARMERIA arriva col regalo del Fabbro (sotto).
  La riga in fine livello: «Nuovo nella home: ALLENAMENTO e STESSO TELEFONO».
- **Dopo Caronte**: GIOCA ONLINE (grande, dorato) ed EVENTI, come nella 1.
  Prima di allora un lucchetto piccolo sotto CAMPAGNA: «Gioca online: si apre nella campagna».
- **Pro**: la home più pulita per chi comincia; ogni pulsante arriva quando ha senso.
- **Contro**: tre stati della home da provare invece di due; un bivio piccolo (offline) alla
  fine dell'Addestramento. Si può fare dopo la 1 senza buttare niente.

### 4. La soglia di stelle

- **Prima**: GIOCA ONLINE spento col lucchetto, come la 1, ma con un contatore: «★ 14 / 25».
- **Il momento**: 25 stelle, con la stessa regola dei capitoli (`serve`). L'Addestramento ne dà
  al massimo 18, quindi servono almeno 7 stelle della Forgia.
- **Pro**: la stessa regola dei capitoli, si vede quanto manca, niente spoiler.
- **Contro**: si arriva rifacendo le missioni facili per le stelle invece di battere un custode;
  le stelle diventano la moneta per l'online, e quando daranno premi (fase 5) avranno due significati.

## L'Armeria: si apre col primo regalo (Sergio, 4 nov)

Punto fermo di Sergio: **ARMERIA appare quando un personaggio (il Fabbro o Favilla) ti
regala il primo pezzo da mettere addosso**, un pezzo semplice. Vale per tutte le proposte:
prima del regalo ARMERIA non c'è (negli schizzi è tolta).

Una cosa da sapere: **in missione l'equipaggiamento è fisso** (29 ott), quindi il pezzo
regalato in campagna non si sente in campagna, solo in Allenamento, Stesso telefono e online.
Per questo il regalo conviene vicino al momento in cui serve:

- **A (consigliata): il Fabbro te lo regala quando lo batti** («Te lo sei guadagnato»), una
  missione prima della Battaglia della Forgia che apre i gironi. Tre sblocchi, ognuno col suo
  momento: ARMERIA (Fabbro), i gironi (Battaglia), GIOCA ONLINE (Caronte).
- B: il Fabbro te lo regala alla fine dell'Addestramento, come diploma. Serve subito solo in
  Allenamento; ARMERIA resta lì un'ora prima dell'online.
- C: Favilla te lo regala nella storia d'ingresso, prima di essere rapita. È il momento più
  forte per la storia, ma ARMERIA si aprirebbe subito, quando l'equipaggiamento non serve
  ancora; si può tenere il regalo nella storia e aprire ARMERIA più tardi (il pezzo ti
  aspetta lì), ma sono due momenti per una cosa sola.

Il pezzo: uno solo, semplice, che si vede addosso (gli stivali da forgia, vedi sotto), con un
bonus piccolo. La scena del regalo è una vignetta della storia (thread della storia
illustrata).

Ancora da decidere (Sergio, 4 nov): se gli altri pulsanti appaiono a poco a poco (proposta 3)
o ci sono già spenti col lucchetto (proposta 1). L'Armeria col regalo va bene con tutte e due.

## Deciso il 4 nov: i pulsanti appaiono a poco a poco

Sergio (4 nov): all'inizio c'è **solo CAMPAGNA**, che deve essere molto bella; gli altri
pulsanti appaiono a poco a poco; **i pulsanti già apparsi non cambiano mai aspetto né posto**;
ogni sblocco ha una transizione elegante e soddisfacente. Proposta concreta (schizzi nella pagina):

**Posti fissi.** Ogni pulsante ha da subito il suo posto definitivo; un posto non ancora
aperto è semplicemente vuoto (niente sagoma, niente lucchetto). Quando un pulsante arriva,
occupa il suo posto e nessun altro si sposta. Colonna di destra, dal basso:

| Posto | Pulsante | Quando appare |
|---|---|---|
| in basso, grande (340 × 160) | **CAMPAGNA**, il portale | subito |
| sopra, grande dorato (340 × 100) | GIOCA ONLINE | battuto Caronte |
| sopra (340 × 64) | ALLENAMENTO | finito l'Addestramento |
| sopra (340 × 64) | STESSO TELEFONO | finito l'Addestramento |

A sinistra, dal basso: ARMERIA (il regalo del Fabbro) ed EVENTI (con l'online).

**CAMPAGNA, il portale.** Non è un pulsante come gli altri: è una carta grande nel posto
più comodo per il pollice, con dentro l'illustrazione del capitolo in cui sei (il cortile, la
Forgia, poi l'anello del girone) che respira piano, il bordo di brace e sotto una riga sola
col punto in cui sei («LA FORGIA · 4/7»). Forma, posto e misura non cambiano mai; cambia solo
il disegno dentro, quando cambi capitolo. Così è la cosa più bella della home all'inizio e
resta la porta della campagna anche quando arriva l'online, che le sta sopra, dorato.
Alternativa (scartata per ora): CAMPAGNA in alto e il posto in basso libero per GIOCA ONLINE;
ma allora all'inizio CAMPAGNA starebbe lontana dal pollice, sopra un vuoto.

**La transizione dello sblocco** (una volta sola, circa 1,5 s, un tocco la salta):
1. Torni in home dall'ultima schermata della missione che l'ha aperto; la home si scurisce un poco.
2. Una scintilla parte dal portale della CAMPAGNA (lì l'hai guadagnato) e vola al posto vuoto.
3. Il contorno del pulsante si disegna di brace, poi si riempie dal basso come metallo fuso,
   con un piccolo rimbalzo (1,08 → 1), il colpo di martello della forgia e una vibrazione breve.
4. Resta la pastiglia NUOVO finché non lo tocchi la prima volta.
Se arrivano due pulsanti insieme (ALLENAMENTO e STESSO TELEFONO) vanno uno dopo l'altro.
I pulsanti già presenti non si muovono: si abbassano solo un poco di luce per l'animazione.

**Il regalo che apre l'Armeria: gli stivali.** I guanti non sono sicuri (Sergio: corazza,
elmo e stivali sì; coi guanti non si sa come si tengono le armi). Consiglio gli **stivali da
forgia**: il pezzo più semplice da capire (camminare sulla brace), si vede subito ai piedi e
l'equipaggiamento cambia già la velocità a terra, quindi il bonus piccolo è naturale. Elmo e
corazza restano per dopo (la corazza è il pezzo più grande, meglio come premio di un girone).

## Scartate

- **Fine dell'Addestramento**: è il bivio piatto che Sergio non vuole, la campagna non è ancora provata.
- **Livello del giocatore (esperienza)**: l'esperienza arriva soprattutto dalle partite, si
  farmerebbe in Allenamento e non dice niente sulla campagna.
- **Tempo o giorni dall'installazione**: arbitrario, chi gioca tanto aspetta lo stesso.
- **Pulsante «Salta, sono esperto»** o un codice: svuota la regola. Per chi viene invitato da un
  amico se ne riparla con le partite private (fase 11).
- **Tocco sul lucchetto che porta alla campagna**: seconda porta della campagna.
- **GIOCA che manda alle lezioni** (com'è oggi): seconda porta di Primi passi; va tolto.
- **Una missione «L'Arena» nella campagna che è già una partita online**: la campagna
  diventerebbe una seconda porta dell'online e le missioni avrebbero bisogno del server.
- **1 contro 1 prima e 2 contro 2 dopo**: due sblocchi invece di uno, e l'1 contro 1 forse sparisce.
- **Bivio nella fine livello («VAI ONLINE» / «CONTINUA LA CAMPAGNA»)**: è il bivio piatto, e
  una seconda porta dell'online.
- **EVENTI aperti prima dell'online**: il loro GIOCA porta alla coda, sarebbe una porta laterale.

## Note per quando si fa

- Il profilo sta sul telefono fino agli account (fase 1): finché c'è solo quello il server
  non controlla lo sblocco; con gli account basta un campo e il server rifiuta la coda.
- Per Sergio e per il simulatore serve un modo di avere l'online sempre aperto (come oggi
  `prova_nuovo` nei scenari).
- L'Allenamento e lo Stesso telefono restano aperti nella 1, 2 e 4 (sono offline).
