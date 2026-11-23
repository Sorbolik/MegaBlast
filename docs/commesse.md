# Le Commesse del Fabbro

Le regole decise da Sergio il 23 novembre 2026, passo per passo, con la pagina
https://claude.ai/artifact/MKh9TW93vC3V4FzKYdrsiW (bozze e scelte numerate).
**Questo file è la fonte**: chi tocca Ossidiana, Scaglie, pezzi, premi, podio, shop
o campagna lo legge prima. Le regole possono cambiare, ma si cambiano qui, con la
data, e con una riga in [decisioni/progressione.md](decisioni/progressione.md).

Stato: **solo regole, nessun codice ancora.** Il minigioco della forgia (poker
«Cinque Fiamme», martello a tempo) è un lavoro a parte, dopo.

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
- Chi non ha clienti ha solo la **commessa del Fabbro**.
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
- **Lo scambio**: 3 di un materiale per 1 di un altro (la Scoria 1 a 1). Non c'entra
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
  del podio. **Niente nell'HUD.**
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
  spesa. Si parte **prudenti: 6 dai clienti, 5 dal Fabbro** (al passo 5 era 8 e 7:
  si alzerà dopo).
- Il premio è **metà Scaglie, metà frammenti**.
- **Un frammento vale un centoventesimo di un pezzo del Catalogo** (oggi 40
  Scaglie) e solo sulla sua famiglia: 120 frammenti = un pezzo nuovo. Se i prezzi
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

## Consegna (passo 6)

- CONSEGNA sul cartellino pronto, oppure CONSEGNA TUTTE in una scena sola.
- Il colpo buono si scopre alla martellata. Poi lo scontrino, con un pulsante che
  porta a POTENZIA quando i frammenti bastano per un livello.
- Senza Ossidiana il pulsante è spento e dice quanta ne manca. Nessun invito a
  comprare.
- Il server paga e registra il premio prima della scena: se cade la rete non si
  perde niente e non si paga due volte.
- **L'animazione è di Gabriella** (lavoro con Blender, altro thread): qui sono
  fissate solo le regole.

## Fiducia (passo 7)

- Una perla per ogni consegna a quel cliente, tre per quella della settimana. Non
  scende mai. Il Fabbro non ha fiducia.
- A 5 perle: le sue commesse danno 1 frammento in più, per sempre. A 10: 30
  frammenti della sua famiglia e il suo cartellino per la scheda. Poi il filo
  ricomincia: 10 frammenti ogni 10 consegne.
- **La fiducia è un numero che non si ferma mai** (al centesimo filo: 1.000) e
  dice a che filo sei; il filo cambia metallo coi giri.

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
- **Banco di prova** nelle IMPOSTAZIONI, solo coi profili di prova: finisci una
  partita finta, passa un giorno, passa una settimana, arriva un cliente, prossimo
  colpo buono, ricomincia. DA ZERO mostra la prima volta; FINE GIOCO parte con
  tutti i clienti e stati diversi.
- Il simulatore fotografa ogni stato con gli stessi comandi.
- **Il giorno delle commesse gira alle 5 di mattina, ora italiana** (Sergio, 23 nov:
  «non voglio che la gente giochi a mezzanotte, voglio che si corichi tranquilla e
  l'indomani ha il premio di vedere le novità»): il server passa alle azioni due
  giorni, quello del gioco (mezzanotte: Banco del giorno, prima vittoria) e quello
  delle commesse (`boardDay` in `server/accounts.go`, `wallet.board_day` sul telefono).
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
