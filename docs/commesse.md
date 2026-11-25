# Le Commesse del Fabbro

Le regole decise da Sergio il 23 novembre 2026, passo per passo, con la pagina
https://claude.ai/artifact/MKh9TW93vC3V4FzKYdrsiW (bozze e scelte numerate).
**Questo file è la fonte**: chi tocca Ossidiana, Scaglie, pezzi, premi, podio, shop
o campagna lo legge prima. Le regole possono cambiare, ma si cambiano qui, con la
data, e con una riga in [decisioni/progressione.md](decisioni/progressione.md).

Stato (23 nov, sera): tutto quello che dice questo file è nel gioco, tranne quello che
aspetta altri: le martellate di Gabriella, le battute dei custodi da rivedere con Sergio,
i clienti veri (arrivano coi gironi) e la porta BOTTEGA chiusa prima di Forgia 6 (Sergio
non ha ancora deciso: per ora è aperta).

**24 nov, cambio di Sergio**: l'Ossidiana non si paga più alla consegna. Si spende solo
nella **Fornace**, il minigioco del Fabbro (Il Tiro nella Fucina, sezione più sotto):
«è strano pagare per aver finito una missione, il minigioco invece è una scelta
consapevole». Nel codice la consegna è già gratis (solo frammenti e fiducia) e il colpo
buono non c'è più; le regole della Fornace sono in `client/sim/forge.lua`.

## A cosa servono

L'Ossidiana prendeva polvere. I personaggi della campagna chiedono un lavoro al Fabbro,
tu lo fai **giocando online**, lo consegni e il Fabbro ti paga in frammenti di famiglia;
l'Ossidiana la spendi nella Fornace, dove diventa Scaglie e frammenti.

Principi di Sergio che reggono tutto:

- I premi che si ripetono vengono dall'**online**. La campagna premia una volta e
  non va mai rigiocata per forza.
- Chi ha fatto la campagna ha un **vantaggio per sempre** (i clienti).
- Niente pay to win: senza la richiesta fatta giocando, l'Ossidiana da sola non
  compra niente.
- **Niente fretta**: nessuna scadenza sulle commesse di tutti i giorni, nessuna
  commessa urgente, la fiducia non scende mai.
- **Si parte con la strada lunga**: numeri prudenti al lancio, perché abbassare
  un prezzo è un regalo e alzarlo è un torto.
- I conti si fanno in **ore di un giocatore forte** (`tools/economia/conti.lua`).

## Il giro

1. Giochi online: le commesse in bacheca avanzano da sole (niente «accetta»).
2. Quando una è pronta la consegni nella BOTTEGA, gratis (dal 24 nov).
3. Il Fabbro forgia e paga subito: frammenti della famiglia del cliente e fiducia.
4. I frammenti pagano un pezzo nuovo o i livelli dei pezzi di quella famiglia.
5. L'Ossidiana si spende nella **Fornace**, dove diventa Scaglie e frammenti.

## Clienti (passo 1)

- I clienti sono i **custodi dei gironi**, uno per girone. Un cliente arriva alla
  prima vittoria sul suo custode, senza bisogno di stelle.
- Ogni cliente ha una famiglia: Caronte LEVIATANO, Minosse CORVO, Cerbero FORNACE,
  Plutone FABBRO, Flegiàs LEVIATANO, Medusa VUOTO, Minotauro FORNACE, Malacoda
  CORVO. Lucifero non è un cliente. **La famiglia sta scritta sul cartellino**: il
  cliente ne è il volto.
- Chi non ha clienti ha solo la **commessa del Fabbro**. Finché i livelli dei custodi
  non sono nella campagna nessun cliente arriva nel gioco vero: si aspettano i gironi
  (Sergio, 23 nov; scartati un cliente ogni 5 partite online e tutti alla chiamata).
- La **prima commessa di ogni cliente** (di benvenuto, facile e gratis) dà il
  **Buono del Fabbro** insieme al suo premio. Il custode battuto dà solo il
  cliente. La Battaglia della Forgia tiene il Buono del Fabbro.
- Sblocchi intorno (passo 1 bis): Armeria e stivali del Fabbro a Forgia 6 (Il
  Fabbro); la Battaglia della Forgia dà storia, mappa dei gironi e Buono; l'online
  si apre a Caronte quando ci sarà il Limbo; le commesse si aprono dopo le prime
  **5 partite online**.
- **Set nuovi**: arrivano con un cliente nuovo che li indossa (un personaggio
  dell'Inferno, da un girone o da un evento), con la commessa fissa in bacheca
  nella settimana di lancio; i tre custodi che ripetono una famiglia possono
  passare a un set loro; dal Fabbro la famiglia si sceglie sempre.

## Materiali (passo 2)

- Uno per mappa della rotazione online: Piuma del Limbo, Vento in bottiglia
  (Lussuria), Chicco di grandine (Gola), Scheggia di masso (Avarizia), Acqua dello
  Stige (Ira), Polvere di tomba (Eresia), Sangue bollente (Flegetonte), Sabbia
  rovente (Sabbione), Pece (Malebolge), Ghiaccio di Cocito. Le due mappe della
  Forgia (pavimento, fossa) danno la **Scoria**, che vale come qualunque materiale.
- **2 a partita online finita, 3 se vinci**, solo se in partita c'è almeno
  un'altra persona. Chi esce prima non prende niente. Allenamento, stesso
  telefono e campagna: niente.
- **Lo scambio**: 3 di un materiale per 1 di un altro (la Scoria non si scambia: vale già da sola per qualunque materiale). Non c'entra
  con la lezione «Il baratto del Fabbro».
- Massimo 99 per tipo. Si vedono sullo scontrino del podio, sullo scaffale della
  bottega e sui cartellini: non nello ZAINO.

## Richieste (passo 3)

- Una commessa chiede **una cosa sola**: materiali oppure un'impresa online. Solo
  quella della settimana chiede tutte e due.
- Imprese solo coi numeri che il gioco conta già a fine partita. **Verdi**
  (coincidono col vincere, valgono ovunque, anche nei tornei futuri): partite
  giocate, vittorie, vittorie in 2 contro 2, punti, nemici buttati giù, danno,
  migliore in campo. **Gialle** (innocue, non nei tornei): casse aperte,
  teletrasporti, premi di fine partita. **Rosse** (solo un'arma, nel fango, senza
  teletrasporto): non nella prima versione.
- I materiali chiesti sono quelli di casa del cliente. Ogni cliente ha il suo
  gusto di imprese.
- Lunghezze: benvenuto 2-3 partite, piccola 3-4, media 6-8, settimana circa 20.
  Da ritarare per il 2 contro 2 (vedi sotto).
- Si seguono sulla schermata delle squadre prima della partita e sullo scontrino
  del podio. **Niente nell'HUD.** Sulle squadre (Sergio, 23 nov, 1A): nella striscia in
  basso, su carta, al posto di «tocca per scegliere le armi», le commesse che la partita
  fa avanzare (al massimo due, prima la più vicina a finire) e il materiale che cade sulla
  mappa (il server la manda già con la scelta delle armi). Solo online con un'altra persona.
- **In 2 contro 2 le imprese contano i numeri della squadra** (passo 8): nemici
  buttati giù, danno, punti. La commessa con un amico arriverà con inviti e
  squadre fisse.

## Bacheca (passo 4)

- Posti dei clienti: 1 con 1-2 clienti, 2 da tre clienti, 3 da sei. Mai due
  commesse dello stesso cliente. Piccole (1 frammento) o medie (2).
- **Commessa della settimana**: una, da lunedì a domenica, 6 frammenti, da tre
  clienti in su. È l'unica che scade.
- **Commessa del Fabbro**: sempre aperta, si rifà subito, 1 frammento della famiglia
  che scegli. È la bacheca di chi non ha clienti.
- Ricambio: ogni mattina alle **5 ora italiana** (lo decide il server) i posti
  vuoti si riempiono. Una commessa pronta aspetta finché non la consegni.
- **Un cambio gratis al giorno**: strappi un cartellino e ne arriva un altro.
- **Chiama un cliente** (regola di Sergio): oggi lo chiami, domani c'è una sua
  commessa; **mai lo stesso due giorni di fila**. Con la bacheca piena aspetta il
  primo posto libero.
- I frammenti **si fondono nella Fornace**, sempre in perdita (Sergio, 24 nov; prima non si
  convertivano): **4 frammenti di una famiglia per 1 di un'altra**, oppure **20 Scaglie l'uno**
  (un terzo del loro valore). Conviene sempre usarli nella loro famiglia.

## Premi (passo 5 e 10, consegna gratis dal 24 nov)

- La consegna è **gratis** e paga **solo frammenti della famiglia del cliente e fiducia**:
  benvenuto 1 più il Buono, piccola 1, media 2, settimana 6, Fabbro 1 della famiglia che
  scegli. Da 5 perle di fiducia un frammento in più. Le Scaglie e il cambio dell'Ossidiana
  stanno nella Fornace.
- **Un frammento vale un centoventesimo di un pezzo del Catalogo** (oggi 60
  Scaglie, Catalogo a 7.200) e solo sulla sua famiglia: 120 frammenti = un pezzo nuovo. Se i prezzi
  salgono, il frammento li segue.
- I frammenti pagano **ogni livello e ogni scatto** dei pezzi della loro famiglia,
  in alternativa alle Scaglie (la Mano del Fabbro abbassa anche quel conto). Dopo
  il 30 pagheranno i potenziamenti solo grafici (la Tempra).
- Il **colpo buono** (una consegna su otto, frammenti doppi) non c'è più dal 24 nov:
  la fortuna e l'abilità stanno nella Fornace.
- Il **Lingotto** delle prime bozze non esiste più.

## La Fornace: Il Tiro nella Fucina (24 nov)

Scelto da Sergio il 24 nov fra tre proposte (https://claude.ai/artifact/JSm7FyZ8HkhchARfBT8LTU:
scartati il poker «Le Cinque Fiamme», che somiglia a una slot, e il Maglio a tempo).

- **L'unico posto dove l'Ossidiana diventa valuta.** Una scheda **FORNACE** nella BOTTEGA,
  fra COMMESSE e BANCO. Una **colata costa 15 Ossidiana** (20 fino al 25 nov: Sergio, «forse costa troppo?»; con 20
  rendeva 7,5 Scaglie di valore per Ossidiana a un giocatore medio, come le Commesse, e nessuno
  convertiva; con 15 circa 10, il tetto della media chiesto dal thread delle valute) e la paghi tu col pulsante, ogni
  volta: niente colate automatiche, niente inviti a comprare.
- **La scheda FORNACE è il muro in vetrina** (Sergio, 24 nov, proposte A e A su
  https://claude.ai/artifact/NtdiVrugGEEvKiBsyifAv2): il Fabbro al banco, il muro di oggi in
  piccolo coi premi, cosa resta e fra quanto arriva il muro nuovo, FONDI e COLA. Con COLA il
  muro si allarga a tutto schermo, le 20 gemme volano dal contatore nel mestolo e si fondono
  nella goccia, compaiono i tiri; finiti i tiri si torna alla vetrina e si può colare ancora
  finché il muro ha premi. Se esci a metà (il tasto indietro mentre miri) i tiri restano: in
  vetrina COLA diventa **TIRA** e riparti da dove eri, senza pagare.
- **Nel gioco** (`client/menu/forge_ui.lua`, foto `tools/simula/scenari/fornace.txt` e
  `fornace_telefono.txt`): la mira si fa vedendo tutto il muro; quando lasci il dito la telecamera
  torna vicina sull'apprendista (zoom 1,9) e parte il tiro, poi segue la goccia da vicino come in
  battaglia, si ferma sullo stampo preso e torna su tutto il muro per il tiro dopo. Per la colata
  la telecamera è vicina all'apprendista (zoom 2,2): lì i dipinti di fondo (WB-092, 1536 px) si
  avvicinano solo fino ai loro pixel e restano lontani come un fondale, mai ingranditi.
  **La mira è quella della partita** (Sergio, 24 nov): sul telefono la levetta di mira a destra
  (lo stesso disegno e le stesse regole della battaglia, `battle/stick_pad.lua` e `battle/sticks.lua`:
  si accende oltre il 20% della corsa, lasciando il pollice parte il tiro); sul computer si trascina
  dall'apprendista; col controller la levetta di mira e SPARA.
- **Come si gioca**: l'apprendista tira una goccia di Ossidiana fusa con **la stessa mira
  della battaglia** (trascini, vedi l'inizio della traiettoria, lasci) negli stampi sul muro
  della fucina. **Tre tiri per colata.**
- **L'apprendista** (Sergio, 24 nov): è il personaggio indossato, grande come in battaglia, con
  le animazioni di sempre della mira; **non si muove** (niente camminata né salto). La goccia vola
  come il Lanciarune senza potenziamenti, la telecamera è quella della battaglia.
- **L'arma è il Mestolo** (Sergio, 24 nov, fra tre proposte animate): un mestolo da colata col
  manico lungo, la goccia nella coppa, **grande** (quasi il doppio della prima versione: spiega la
  lentezza del tiro). Si impugna **come la spada**, rivolto indietro sopra la spalla anche mentre
  si riempie, con la bocca della coppa dal lato dei premi. Il tiro è la clip `lancio_mestolo` di
  ogni personaggio (circa un secondo e mezzo: indietro, trema pieno, frustata, saltello), che
  Sergio ritocca nell'editor delle animazioni («con mestolo»); la goccia parte dalla coppa nel
  momento in cui il mestolo va più veloce in quella clip, così resta giusta anche dopo i ritocchi.
  L'anticipazione è solo da vedere: angolo e potenza sono quelli scelti. Disegni: WB-093.
- **I premi si leggono sul muro** (Sergio, 24 nov): sopra ogni stampo l'icona del premio e la
  quantità (moneta delle Scaglie col numero, o il frammento della famiglia con x1 o x2), sempre
  della stessa grandezza sullo schermo a ogni zoom; la placca dello stampo ha il colore della
  famiglia, ferro per le Scaglie. Quando la goccia entra il gioco si ferma un attimo, la camera
  trema e il premio vola al contatore.
- **La traiettoria arriva fino alla cima e un po' oltre** (Sergio, 24 nov, scelta sul prototipo
  https://claude.ai/artifact/4Zyv54v6i7epW4eVjpawst): i puntini fanno la salita e un altro mezzo
  tratto dopo la cima, dove sfumano; mai oltre il primo rimbalzo. La discesa nello stampo la
  indovini tu, così gli stampi lontani non sono più difficili di quelli vicini.
- **Gli stampi**: 12 sul muro, 6 di Scaglie (15, 20, 30, 50, 60, 80) e 6 di frammenti (x1 o
  x2), **255 Scaglie e 8 frammenti per muro**. Più lontano e più in alto, più rende; quelli
  lontani sono piccoli e chiedono quasi tutta la forza. Mirando scegli la famiglia che ti
  serve. Le catene (degli stampi alti) per ora stanno ferme.
- **Tre muri al giorno, uno dopo l'altro** (Sergio, 25 nov; prima erano tre a orario, alle 5,
  13 e 21, ma riempirne uno costava più Ossidiana di quella che si fa in 8 ore): il secondo si
  apre quando hai riempito il primo, il terzo dopo il secondo; hai tutto il giorno di gioco, e
  alle 5 di mattina si riparte dal primo muro nuovo (anche se eri a metà). I premi crescono:
  **x1, x1,25, x1,5** (Scaglie arrotondate a 5, frammenti 8, 10, 12), e il **jackpot 500, 750,
  1000** (`forge.LEVELS`, `forge.JACKPOTS`, `forge.current`). I tre muri sono uguali per tutti.
  **Nel gioco si vede così** (Sergio, 25 nov, «A e B insieme»): nella vetrina, sotto i frammenti,
  «I MURI DI OGGI» con tre stampi (quello pieno col coperchio e PIENO, quello di adesso
  incandescente col suo premio, quelli dopo spenti) e «NUOVI FRA» col conto alla rovescia; sul
  foglio del Fabbro «3 muri al giorno: riempi questo e si apre il prossimo.» e sotto i premi e
  l'ora del nuovo giro (alle 5 di mattina).
  **Ogni muro nuovo mette gli stampi in posti nuovi** (Sergio, 24 nov): sempre staccati e
  tutti centrabili **con un tiro diretto, senza rimbalzi** (Sergio, 25 nov; il gioco lo
  controlla quando li appende, con la grandezza vera di ogni stampo, e sposta quello che non si
  prende). Le famiglie cambiano e gli
  stampi riempiti tornano vuoti.
- **La sponda in fondo spinge in alto** (Sergio, 25 nov: «quasi un booster verso l'alto», numeri
  scelti sulla pagina di prova https://claude.ai/artifact/9RZpeMBV7fuPz6nM6fquiJ): la goccia torna
  indietro con lo stesso angolo con cui è arrivata, salendo o scendendo, ma sempre verso l'alto,
  fra 30 e 85 gradi, con il 75% della sua velocità (`forge.BACK_PUSH`, `BACK_MIN`, `BACK_MAX`;
  prima era un rimbalzo normale all'85%).
- **I colpi di sponda pagano di più** (Sergio, 25 nov): ogni rintocco sul ferro degli stampi
  prima di entrare vale +50% del premio dello stampo, passare dalla sponda in fondo lo
  raddoppia, al massimo x3 (`forge.KNOCK_BONUS`, `WALL_BONUS`, `BANK_MAX`); nel gioco
  «DI SPONDA x1,5». Il premio di consolazione è **30 Scaglie per ogni goccia**, nel secchio
  e anche a segno (il centro aggiunge il premio dello stampo), su tutti i muri (`forge.MISS`,
  `r.base`; Sergio, 25 nov: «mettiamolo a 30 e lasciamolo sempre a 30», «non voglio penalizzare
  chi fa centro»; era 20 e solo nel secchio).
- **Il muro è uguale per tutti** (Sergio, 24 nov sera: «sempre randomico, ma uguale per tutti
  quanti, crea più unione tra la gente»): posti, premi e stampo fortunato vengono solo dal
  muro di quel momento (`forge.wall`, seme `forge.SEED` uguale per tutti), non più da un seme
  del giocatore.
- **Muro specchiato metà delle volte** (Sergio, 24 nov sera): un muro su due, a caso ma uguale
  per tutti, si vede rovesciato, con l'apprendista a destra (`forge.mirrored`). Le regole lo
  vedono sempre da sinistra: si gira solo il disegno (e la mira, che resta giusta per il dito).
- **La sponda in fondo** (Sergio, 24 nov sera): a destra, dopo l'ultimo stampo, un muro che si
  raggiunge col tiro e rimanda indietro la goccia con un «toc», come una sponda di gomma
  (`forge.BACK_X`, rende l'85% della velocità). Disegno di Codex WB-095 (sponda 2): ferro
  rivettato con cinque cuscini di gomma rossa.
- **Lo stampo fortunato** (Sergio, 24 nov): ogni tanto un muro ha uno stampo che dà il
  doppio, un muro ogni 8 di fila (uguale per tutti: sempre entro 15 muri, `forge.lucky_slot`). Uno
  stampo pieno non paga due volte: una goccia che lo prende è come il ferro, va nel secchio.
  Una colata cominciata resta sul suo muro anche se intanto il muro cambia; non si torna mai
  a un muro vecchio.
- **Stampi un pelo più larghi e bordo che prende al 30%** (Sergio, 24 nov, sulla pagina
  https://claude.ai/artifact/Gjq7oJAtJP1yXvLshSxXAa): gli stampi sono il 6% più larghi, disegno
  compreso; la riga che prende la goccia sta sopra i bordi e copre la bocca più il 30% dei bordi:
  una goccia che scende sulla parte interna di un bordo cade dentro, sulla parte esterna rimbalza
  fuori (`forge.CATCH`, da ritarare giocando).
- **Premi secondo la difficoltà vera** (Sergio, 24 nov: «quelli con altri davanti e quelli in
  basso sono difficili»): quando appende il muro il gioco prova 600 tiri (30 angoli per 20
  forze) e conta quanti finiscono in ogni stampo; i premi si scambiano fra gli stampi dello
  stesso tipo (Scaglie con Scaglie, frammenti con frammenti) così il più difficile ha il più
  ricco. I totali del muro non cambiano (`forge.ease`, `forge.by_ease`).
- **Il jackpot del muro pieno** (Sergio, 24 nov, «Medaglia + 500 Scaglie»): chi riempie tutti
  i 12 stampi di un muro prende **500 Scaglie** ogni volta e, la prima volta, la medaglia
  **Jackpot della Fornace** (`forge.JACKPOT`, il conto in `fornace.jackpot`). La medaglia è un badge del profilo, d'oro, nella casella dei clienti di fiducia: si mette accanto al nome come gli altri (`orders.badges`). Scartati: un
  frammento per famiglia e una colata gratis. Il jackpot **chiude la colata** anche se restano tiri
  (persi, niente tiro in più) e un muro pieno **non si cola più** fino al muro dopo (Sergio, 25 nov:
  «non ti deve permettere di rifarla su quel muro»; `forge.full`, la colata risponde `"pieno"`).
- **Le medaglie dei rintocchi** (Sergio, 24 e 25 nov): un rintocco è un colpo della goccia sul
  ferro degli stampi nello stesso tiro (solo sugli stampi: la sponda non conta); la prima volta
  che un tiro ne fa **6**, **8** e **10** si vince una medaglia: bronzo, acciaio, argento con
  l'Ossidiana (`forge.KNOCKS`, il record in `fornace.rintocchi`). Nel gioco la scritta «6
  RINTOCCHI!», la medaglia che salta fuori e la sua riga nel riepilogo; nel profilo sono badge come
  quella del jackpot (`orders.FORGE_BADGES`). Disegni di Codex: 6 e 10 da WB-095, 8 da WB-096 (la
  regola la conta già; la medaglia compare quando c'è il disegno). Misurato su 611.780 tiri a caso
  su 20 muri: 6 o più circa 1 tiro su 2.900, 10 mai (il massimo è 8): Sergio la vuole lo stesso.
- **Quando la goccia entra e quando lo stampo è preso** (Sergio, 24 nov, sulla pagina
  https://claude.ai/artifact/LcTuEFuH5XKmmmeDPgtGN2): entrando, **la fiammata**, una colonna di
  fuoco di Ossidiana dalla bocca; lo stampo preso lo chiude **un coperchio di ferro** che scende
  con sopra l'icona del premio preso. Lo stampo che si riempie di metallo non si usa più (la
  goccia è una palla). Disegni di Codex WB-094 (coperchi 1, fiammata 1, medaglia 1). Scartati: risucchio,
  campana, incandescente e bollo. Le animazioni sono quelle della pagina (Sergio, 24 nov sera:
  «falla in quel modo»): lo schermo si scurisce un attimo, lampo caldo, colonna di fuoco con
  scintille d'oro e viola, onda d'urto, lo stampo incandescente che trema, «CENTRO!» grande;
  il coperchio scende quando il fuoco è finito. Il jackpot: dopo l'ultima fiammata gli stampi si
  accendono uno dopo l'altro come lampadine, lampo, il muro trema, «JACKPOT!» enorme che
  ondeggia, «MURO PIENO», pioggia di Scaglie e frammenti, poi la medaglia.
- **Il riepilogo della colata** (Sergio, 24 nov): finiti i tiri, prima di uscire, una card «LA
  COLATA» con le Scaglie, i frammenti per famiglia, il tiro in più, il jackpot e la medaglia;
  COLA ANCORA (se c'è Ossidiana e il muro non è pieno) o CHIUDI. **Dopo il jackpot solo CHIUDI**
  (Sergio, 25 nov: con COLA ANCORA il muro nuovo si vedeva coi calderoni del muro vecchio): il
  muro dopo si vede nella vetrina e si cola da lì.
- **La colata va come una partita** (Sergio, 25 nov: «sensibile al calo degli FPS»): dallo zoom
  d'entrata a quello d'uscita il telefono va al massimo dello schermo (90/120 Hz), non ai 60 dei
  menù né ai 30 dopo 12 secondi senza tocchi (`forge_ui.busy`, `main/phone.lua`). La mira calcola
  solo il tratto del volo che serve ai puntini (prima tutto il volo, ~900 tabelle a ogni frame).
- **La goccia entra solo dall'alto**: deve passare dentro l'orlo scendendo. **Sul ferro rimbalza**
  (Sergio, 24 nov: «finché non tocca terra è valido»): la goccia è una palla, la pancia e i due
  bordi di ogni stampo la fanno rimbalzare (rende metà della velocità contro il ferro) e può finire
  in un altro stampo più in basso; conta solo quando tocca terra. Uno stampo pieno è chiuso dal
  coperchio, che la fa rimbalzare via (un cerchio sul disegno del coperchio, `forge.LID_R`;
  Sergio, 24 nov sera: «l'hitbox del coperchio più coerente col coperchio»; `fly`).
- **Mai zero**: una goccia fuori dagli stampi cade nel secchio, e ogni goccia dà 30 Scaglie, anche a segno. Tre centri
  su tre danno un tiro in più (uno solo per colata).
- **Il cambio**: una colata rende in media circa **130 Scaglie di valore** (frammento = 60),
  dal peggio al meglio circa da 0,8 a 1,2 volte la media. Da ritarare coi conti delle ore
  (`tools/economia/conti.lua`) quando c'è il codice.
- **Il server decide**: il telefono manda il muro che vede, poi angolo e forza di ogni tiro
  (azioni `colata`, `tiro`, `fondi` del profilo); il server rifà il volo con le stesse regole
  (`client/sim/forge.lua`) e paga. Il risultato non lo dice il telefono, e niente è a caso.
- **Arte**: stampi, goccia, catene e secchio da Codex (scheda in `docs/handoff/`); lo sfondo
  è quello della fucina che c'è già.
- **Da decidere prima di vendere l'Ossidiana**: l'Ossidiana comprata con soldi veri non
  entra nella Fornace (se no la Fornace diventa «compro Scaglie»), oppure l'Ossidiana non si
  vende.

### Le commesse con la Fornace (proposta A, confermata da Sergio il 24 nov)

- La consegna è **gratis**. Il premio è solo **frammenti della famiglia e fiducia**:
  piccola 1, media 2, settimana 6; la commessa del Fabbro 1 frammento della famiglia che
  scegli. Le Scaglie arrivano dalla Fornace.
- Il **colpo buono** sparisce: la fortuna e l'abilità stanno nella Fornace.
- Restano come sono: perle, benvenuto col Buono, chiamata, bacheca, scambio, cambio gratis.
- Scartata (B): consegna gratis col premio intero, perché sarebbe un regalo in più a
  ogni consegna e costringerebbe ad alzare ancora i prezzi.

## Consegna (passo 6)

- CONSEGNA sul cartellino pronto, oppure CONSEGNA TUTTE in una scena sola.
- Dopo le martellate lo scontrino, con un pulsante che porta a POTENZIA quando i
  frammenti bastano per un livello.
- Il server paga e registra il premio prima della scena: se cade la rete non si
  perde niente e non si paga due volte.
- **La scena è la proposta A** (Sergio, 23 nov: «va bene A»), al banco del Fabbro,
  circa due secondi, un tocco salta allo scontrino:
  1. il cartellino si stacca e vola sul banco;
  2. il Fabbro batte tre volte;
  3. il busto del cliente entra da destra, contento (fiero alla quinta e alla decima
     perla) con una sua battuta, e il premio salta fuori dall'incudine;
  4. lo scontrino di carta: frammenti, fiducia con le perle, OK e, se i
     frammenti bastano per un livello di un pezzo della famiglia, POTENZIA (apre lo ZAINO).
  CONSEGNA TUTTE: una martellata per cartellino, più veloce, e uno scontrino solo.
- **Le martellate del Fabbro sono di Gabriella**: finché non arrivano, il Fabbro al
  banco di WB-085 sobbalza a ogni colpo (provvisorio). I busti contento e fiero sono di
  WB-086 e WB-087.

## Fiducia (passo 7)

- Una perla per ogni consegna a quel cliente, tre per quella della settimana. Non
  scende mai. Il Fabbro non ha fiducia.
- A 5 perle: le sue commesse danno 1 frammento in più, per sempre. A 10: 30
  frammenti della sua famiglia e il suo cartellino per la scheda. Poi il filo
  ricomincia: 10 frammenti ogni 10 consegne.
- **La fiducia è un numero che non si ferma mai** (al centesimo filo: 1.000) e
  dice a che filo sei; il filo cambia metallo coi giri: le perle piene sono di bronzo,
  poi d'argento, d'oro e di brace per sempre, i colori dei gradi dei pezzi (Sergio, 23 nov).
- **Il libro I TUOI CLIENTI** (Sergio, 23 nov): il pulsante in basso nelle COMMESSE si
  chiama I TUOI CLIENTI; dentro, sulla foto di ogni cliente, nell'angolo, il numero della
  fiducia nel metallo del suo filo; si sceglie un cliente e lo si chiama col pulsante CHIAMA
  (uno solo, per chiamare chi vuoi).
- **Il badge del cliente** (il «cartellino per la scheda» dei 10 perle, Sergio 23 nov): il
  busto del cliente in un cerchio, come il tondo del profilo: la testa parte dalla base e
  sopra o di lato può uscire; l'anello è del metallo del suo filo. Si sceglie nel PROFILO,
  nella casella dopo i record, come gli altri badge, e lo vedono tutti, anche online.

## Dove sta nel gioco (passo 9)

- La porta dello SHOP in home si chiama **BOTTEGA**. Dentro, due schede:
  **COMMESSE** (la prima) e **BANCO** (comprare i pezzi: la «Bottega del giorno»
  diventa il Banco del giorno). Al banco c'è il Fabbro.
- Avvisi: sulla porta un numero per le commesse pronte e un puntino la mattina per
  le nuove; righe sullo scontrino del podio, senza pulsanti in più; in POTENZIA i
  frammenti accanto al prezzo. Nessuna finestra, nessuna notifica.
- La prima volta: dopo la quinta partita online il Fabbro ti chiama; la prima
  commessa è sua, già fatta e gratis.
- Cartellini di carta, da confermare sulle bozze di Codex (carta e ferro scuro
  fianco a fianco).

## Custodi: ritratti e battute (passo 11)

- Un busto con tre espressioni (chiede, contento, fiero), disegnato da Codex.
  **Prima Caronte** come prova di stile, poi gli altri. Finché non ci sono, il
  segnaposto è la miniatura della mappa.
- Cinque righe a custode (tre richieste, grazie, colpo buono), riviste da Sergio.

## Come si costruisce e si prova (passi 10 e 12)

- **Si costruisce tutto adesso**, clienti compresi, anche senza i gironi.
- Le regole stanno in **un modulo solo** che non guarda l'orologio e non sa cos'è
  una partita: riceve «è finita una partita con questi numeri» e «oggi è il giorno
  tale». Il server gli dà quelli veri. **Nessun «se sono in prova» nella logica.**
- Ogni cliente ha nei dati **il livello della campagna che lo fa arrivare**:
  finché il livello non esiste, nel profilo vero non arriva. Niente di provvisorio
  da togliere.
- **Banco di prova** dentro la BOTTEGA (pulsante PROVA nella scheda COMMESSE; Sergio, 23 nov:
  lì l'effetto si vede subito), solo coi profili di prova: finisci una
  partita finta, passa un giorno, passa una settimana, arriva un cliente, prossimo
  colpo buono, ricomincia. DA ZERO mostra la prima volta; FINE GIOCO parte con
  tutti i clienti e stati diversi.
- Il simulatore fotografa ogni stato con gli stessi comandi.
- **Il giorno del gioco gira alle 5 di mattina, ora italiana**, per tutto: bacheca,
  cambio, chiamata, Banco del giorno, prima vittoria, partite coi bot (Sergio, 23
  nov: «non voglio che la gente giochi a mezzanotte, voglio che si corichi
  tranquilla e l'indomani ha il premio di vedere le novità»). `today` in
  `server/accounts.go`, `wallet.today` sul telefono.
- **Dove sta il codice**: regole in `client/sim/orders.lua` (prove in
  `tests/orders_test.lua`), campo `commesse` del profilo. A fine partita online il
  server (`server/worker.lua`, `prizes`) aggiunge all'azione `partita` il riassunto
  `commesse` (mappa, quante persone, numeri tuoi e della squadra); le righe per lo
  scontrino tornano in `gain.commesse`. Azioni del profilo (`client/sim/progress.lua`):
  `bacheca` (guardo la bacheca: rifornimento del giorno), `consegna {n, set}`,
  `scambia {da, a}`, `cambia {n}`, `chiama {cliente}`, e `compra` / `potenzia` con
  `frammenti = true`. Una partita dichiarata dal telefono non muove le commesse.
- La simulazione della partita non si tocca: le commesse leggono solo i numeri di
  fine partita.

## Scartate

- La Cascata (plinko), il Lingotto, le commesse urgenti, la conversione dei
  frammenti fra famiglie, lo sconto come unico uso dei frammenti, i clienti
  provvisori regalati a tutti, legare lo scambio al «baratto del Fabbro».
