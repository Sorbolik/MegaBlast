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
consapevole». Le parti di questo file che parlano di Ossidiana alla consegna, del cambio
e del colpo buono valgono finché la Fornace non è nel gioco.

## A cosa servono

L'Ossidiana prendeva polvere. Le commesse la fanno spendere: i personaggi della
campagna chiedono un lavoro al Fabbro, tu lo fai **giocando online**, lo consegni
pagando Ossidiana e il Fabbro ti paga in Scaglie e in frammenti di famiglia.

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

(Dal 24 nov: al punto 2 la consegna è gratis, e l'Ossidiana va nella Fornace.)

1. Giochi online: le commesse in bacheca avanzano da sole (niente «accetta»).
2. Quando una è pronta la consegni nella BOTTEGA e paghi la sua Ossidiana.
3. Il Fabbro forgia (Ossidiana nel bocchettone, colpo, la pancia si apre) e paga
   subito: Scaglie e frammenti della famiglia del cliente.
4. I frammenti pagano un pezzo nuovo o i livelli dei pezzi di quella famiglia.

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
  commesse dello stesso cliente. Piccole (20 Ossidiana) o medie (40).
- **Commessa della settimana**: una, da lunedì a domenica, 100 Ossidiana, da tre
  clienti in su. È l'unica che scade.
- **Commessa del Fabbro**: sempre aperta, si rifà subito, 20 Ossidiana, famiglia
  dei frammenti a scelta, cambio più basso. È la valvola di chi ha tanta Ossidiana
  e la bacheca di chi non ha clienti.
- Ricambio: ogni mattina alle **5 ora italiana** (lo decide il server) i posti
  vuoti si riempiono. Una commessa pronta aspetta finché non la consegni.
- **Un cambio gratis al giorno**: strappi un cartellino e ne arriva un altro.
- **Chiama un cliente** (regola di Sergio): oggi lo chiami, domani c'è una sua
  commessa; **mai lo stesso due giorni di fila**. Con la bacheca piena aspetta il
  primo posto libero.
- I frammenti **non si convertono** fra famiglie.

## Costo e premi (passo 5 e 10)

- **Il cambio** è il numero che tara tutto: Scaglie di valore per ogni Ossidiana
  spesa. Le Scaglie dei premi sono fisse; coi prezzi del 23 nov (PR 410, frammento a 60)
  il cambio è **7 dai clienti (7,2 la settimana), 6 dal Fabbro** (era 6 e 5 coi prezzi
  vecchi; al passo 5 era 8 e 7).
- Il premio è **metà Scaglie, metà frammenti**.
- **Un frammento vale un centoventesimo di un pezzo del Catalogo** (oggi 60
  Scaglie, Catalogo a 7.200) e solo sulla sua famiglia: 120 frammenti = un pezzo nuovo. Se i prezzi
  salgono, il frammento li segue.
- I frammenti pagano **ogni livello e ogni scatto** dei pezzi della loro famiglia,
  in alternativa alle Scaglie (la Mano del Fabbro abbassa anche quel conto). Dopo
  il 30 pagheranno i potenziamenti solo grafici (la Tempra).
- Al cambio di partenza: piccola 20 Ossidiana = 80 Scaglie e 1 frammento; media 40
  = 160 e 2; settimana 100 = 360 e 6; Fabbro 20 = 60 e 1. Benvenuto: gratis, premio
  di una piccola più il Buono.
- **Colpo buono**: una consegna su otto, frammenti doppi. Resta finché non c'è il
  minigioco, che prenderà quel posto.
- Il **Lingotto** delle prime bozze non esiste più.
- L'Ossidiana data al Fabbro non va nelle firme: è una scelta vera fra le due.

## La Fornace: Il Tiro nella Fucina (24 nov)

Scelto da Sergio il 24 nov fra tre proposte (https://claude.ai/artifact/JSm7FyZ8HkhchARfBT8LTU:
scartati il poker «Le Cinque Fiamme», che somiglia a una slot, e il Maglio a tempo).

- **L'unico posto dove l'Ossidiana diventa valuta.** Una scheda **FORNACE** nella BOTTEGA,
  fra COMMESSE e BANCO. Una **colata costa 20 Ossidiana** e la paghi tu col pulsante, ogni
  volta: niente colate automatiche, niente inviti a comprare.
- **Come si gioca**: l'apprendista tira una goccia di Ossidiana fusa con **la stessa mira
  della battaglia** (trascini, vedi l'inizio della traiettoria, lasci) negli stampi sul muro
  della fucina. **Tre tiri per colata.**
- **Gli stampi**: alcuni di Scaglie, altri di frammenti di una famiglia. Quelli piccoli,
  lontani o appesi alle catene che dondolano rendono di più. A ogni colata cambiano posto.
  Mirando scegli la famiglia che ti serve.
- **Mai zero**: una goccia fuori dagli stampi cade nel secchio (20 Scaglie). Tre centri
  su tre danno un tiro in più.
- **Il cambio**: una colata rende in media circa **130 Scaglie di valore** (frammento = 60),
  dal peggio al meglio circa da 0,8 a 1,2 volte la media. Da ritarare coi conti delle ore
  (`tools/economia/conti.lua`) quando c'è il codice.
- **Il server decide**: il telefono manda i tre tiri (angolo e forza), il server rifà la
  colata con la stessa simulazione (seme del server) e paga. Il risultato non lo dice il
  telefono.
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
- Il colpo buono si scopre alla martellata. Poi lo scontrino, con un pulsante che
  porta a POTENZIA quando i frammenti bastano per un livello.
- Senza Ossidiana il pulsante è spento e dice quanta ne manca. Nessun invito a
  comprare.
- Il server paga e registra il premio prima della scena: se cade la rete non si
  perde niente e non si paga due volte.
- **La scena è la proposta A** (Sergio, 23 nov: «va bene A»), al banco del Fabbro,
  circa due secondi, un tocco salta allo scontrino:
  1. il cartellino si stacca e vola sul banco, l'Ossidiana cade sull'incudine;
  2. il Fabbro batte tre volte (al colpo buono la terza è più forte, lo schermo trema);
  3. il busto del cliente entra da destra, contento (fiero col colpo buono e alla quinta e
     alla decima perla) con una sua battuta, e il premio salta fuori dall'incudine;
  4. lo scontrino di carta: Scaglie, frammenti, fiducia con le perle, OK e, se i
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
