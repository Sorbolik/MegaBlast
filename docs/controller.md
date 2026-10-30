# Controller

Si gioca anche col controller, collegato via Bluetooth o USB: Xbox,
PlayStation e generici, sul telefono Android, sul computer e nel browser. Il
tocco, la tastiera e il mouse restano come prima: chi usa il controller vede
le scritte del controller (lezioni, schede), un dito sullo schermo riaccende
le levette del telefono.

## Tasti in battaglia

Mappatura di base di Sergio (30 ott); ognuno la cambia nelle IMPOSTAZIONI
(sotto). Di base la levetta destra muove e la sinistra mira (Sergio, 30 ott);
LEVETTA CHE MUOVE nelle impostazioni le rimette al contrario. Nomi Xbox, cioè il posto del tasto: A in basso, B a destra, X a
sinistra, Y in alto. Su PlayStation sono croce, cerchio, quadrato e triangolo;
su Nintendo, allo stesso posto, B, A, Y e X.

| Tasto | Cosa fa |
|---|---|
| Levetta destra | Cammina; spinta in su salta (come la levetta del telefono). Se SALTA ha un tasto (impostazioni) cammina soltanto |
| Levetta sinistra | Mira: la direzione è l'angolo, quanto la spingi è la potenza (come sul telefono); riportata al centro si spegne |
| RT (grilletto destro) | Spara, con la mira della levetta destra di un attimo prima (0,05 s, come il pollice che si stacca dal telefono). Di base **lasciandolo**: premuto carica, lasciato parte; riportando la levetta destra al centro prima di lasciarlo non parte niente. Nelle impostazioni si sceglie anche PREMENDO, o la potenza dal GRILLETTO (sotto) |
| LB | La primaria dopo, a giro (1, 2, 3, 1...), dal cronometro verso fuori |
| RB | La secondaria dopo, a giro |
| A | Teletrasporto in mano |
| X | Rampino in mano |
| Y | Paracadute (in aria) |
| LT (grilletto sinistro) | Accende l'oggetto dopo nella colonna OGGETTI, a giro |
| Croce giù | Usa l'oggetto acceso *(scelta di Claude)* |
| B | Baratto: il secondo attacco diventa un teletrasporto *(scelta di Claude: Sergio voleva "finisci il turno saltando il secondo attacco", che nelle regole non c'è; il baratto è la cosa più vicina)* |
| Select | Zoom *(scelta di Claude)* |
| Start | Rotellina (RIPROVA, ESCI, MIRA): la croce sposta la luce, A conferma, B o Start la chiude *(scelta di Claude)* |

Come i pulsanti dell'HUD, LB, RB, A e X scelgono sempre; quello che ora non si
può usare fa no e dice perché. LB e RB saltano le armi che nel tuo turno non
puoi usare.

La mappatura di base sta in `controller.BATTAGLIA` (`client/ui/controller.lua`);
quella in uso è `c.tasti`, che le impostazioni cambiano.

Su Android B manda anche il tasto "indietro" del telefono: il gioco lo
riconosce (B tenuto o premuto da meno di 0,3 s) e non apre la rotellina.

## Impostazioni: i tasti da cambiare

Nella home, la rotellina in alto a destra apre IMPOSTAZIONI
(`client/menu/impostazioni.lua`, [impostazioni.md](impostazioni.md)). In alto
tre scelte: MIRA (lancetta o mirino), SPARO COL CONTROLLER (premendo o
lasciando) e POTENZA COL CONTROLLER (levetta o grilletto). Sotto una riga per
ogni comando, col suo tasto. Si sceglie la riga (col tocco o con la luce e A) e
si preme il tasto nuovo: il comando che lo aveva prende quello lasciato libero
(o, se il comando nuovo non ne aveva, il primo tasto che nessuno usa: la
croce). **Y** sulla riga accesa toglie il tasto: il comando resta senza. Start
annulla e resta sempre alla rotellina; quale levetta muove si sceglie a parte (LEVETTA CHE MUOVE). RIPRISTINA torna
alla mappatura di Sergio. Si salva subito nel profilo (`tasti`, `sparo`, `potenza`).

- **SALTA** (Sergio, 30 ott: "la gente lo vuole sulla A"): di base non ha un
  tasto e si salta con la levetta sinistra in su. Con un tasto si salta finché
  è tenuto e la levetta sinistra cammina soltanto (conta solo di lato), così
  camminando in diagonale non si salta per sbaglio. Non ha un pulsante
  sull'HUD, quindi nemmeno il disegno del tasto; le lezioni dicono il tasto.
- **Potenza dal grilletto**: la levetta destra dà solo la direzione (accesa
  oltre il 20%), quanto è premuto il tasto di SPARA dà la potenza (oltre il 6%,
  si vede nel cartellino) e lasciandolo parte il colpo con la potenza di 0,08 s
  prima, perché il grilletto torna su in un attimo. Su un tasto che non è un
  grilletto la potenza è sempre piena.

## I tasti sull'HUD

Col controller in mano ogni pulsante dell'HUD mostra, nell'angolo, il tasto che
lo usa (`client/ui/glifo.lua`, `PAD.glifi` in `game.gui_script`), anche dopo
averlo cambiato. Il tasto è disegnato come sul controller che si usa,
riconosciuto dal nome che dà il sistema (`controller.famiglia`):

- **Xbox** (e tutti quelli che non si riconoscono): A verde, B rosso, X blu, Y giallo; LB, RB, LT, RT, MENU, VISTA.
- **PlayStation**: croce, cerchio, quadrato e triangolo disegnati; L1, R1, L2, R2, OPTIONS, CREATE.
- **Nintendo**: le lettere al loro posto (B in basso, A a destra, Y a sinistra, X in alto); L, R, ZL, ZR, +, −.

La croce è disegnata col braccio acceso. Le schede, le lezioni e la scelta
delle armi scrivono il nome giusto del tasto (`controller.nome_di`). Negli
scenari `imposta prova_pad playstation` (o `nintendo`) prova la grafica degli
altri controller.

## Menu e scelta delle armi

La croce (o la levetta sinistra) accende una luce su un pulsante e la sposta
verso quello più vicino in quella direzione; A conferma, B torna indietro. La
prima pressione accende la luce sul pulsante principale (o sull'ultimo
confermato). Nella scelta delle armi la luce va anche sulle carte e sulle
scelte fatte, Y apre la scheda della carta (al posto del tocco lungo), Start
apre ESCI. Le schede delle armi nuove in battaglia si chiudono con A, il podio
e le stelle si passano con A.

## Come funziona

- `client/input/game.input_binding`: le azioni `pad_*` dei tasti e delle levette,
  `pad_grezzo` e `pad_connesso`.
- `client/ui/controller.lua`: legge le azioni e dà i tasti premuti e lasciati e le
  due levette (senza nodi GUI, si prova con `luajit tests/battaglia_test.lua`).
  I controller che Defold conosce (`/builtins/input/default.gamepads`)
  arrivano già tradotti. Quelli che non conosce danno solo l'azione grezza:
  su Android e nel browser i numeri dei tasti sono uguali per tutti (Android
  li prende dai codici standard, il browser dallo "standard gamepad"), quindi
  li traduciamo noi. Sul computer un controller sconosciuto non funziona
  (Windows e Linux non hanno un ordine standard).
  Su Android gli assi verticali delle levette arrivano capovolti (giù è su):
  `c.su = -1` li raddrizza, per i controller noti e per i grezzi. Un
  controller letto dai grezzi non conta anche dalle azioni tradotte (una fonte
  sola). Su Android un controller PlayStation arriva come tre controller: il
  controller, il touchpad ("Wireless Controller Touchpad", che Defold traduce
  con gli assi del controller) e i sensori di movimento: touchpad e sensori non
  contano mai (dal nome), e le levette contano solo dal controller che ha
  premuto un tasto per ultimo.
  Dalle azioni tradotte si legge solo `action.value`, mai `action.released`:
  Defold mette released quando un valore scende sotto 0,9 (la sua soglia di
  "premuto"), non quando torna a zero, e il ritorno a zero arriva comunque
  col valore 0. Leggerlo come "lasciato" azzerava per un fotogramma il lato
  della levetta che scendeva sotto 0,9 (la mira scattava sempre allo stesso
  angolo, 27° o 34° secondo il controller, a destra e a sinistra) e lasciava
  il grilletto appena cominciava a tornare su (partiva il colpo, poi ancora
  oltre metà corsa si ripremeva e partiva anche l'arma dopo) (Sergio, 30 ott).
  `c.valore` dice quanto sono premuti i grilletti. Un grilletto è premuto
  oltre metà corsa e lasciato solo sotto il 20% (con la potenza dal grilletto:
  carica oltre il 15%, parte sotto il 6%): senza questo margine un grilletto
  tenuto a metà poteva tremare fra premuto e lasciato. Un tasto
  lasciato conta solo dal controller in uso.
- `client/ui/ui.lua`: la luce sui bottoni (`ui.tocco` con `ui.PAD`).
- `client/ui/glifo.lua`: il disegno dei tasti; `client/menu/impostazioni.lua`: la schermata.
- `client/main/game.gui_script`, tabella `PAD`: cosa fanno i tasti in battaglia.
- Simulatore: il controller finto (comandi `pad`, `pad_tieni`, `pad_lascia`,
  scenari `strumenti/simula/scenari/controller.txt` e `impostazioni.txt`).

Scartate: leggere tutti i controller dall'azione grezza (sul computer l'ordine
dei tasti cambia da un controller all'altro, e i noti funzionano già meglio
tradotti da Defold); un file `.gamepads` nostro coi nomi dei controller
Android (i nomi sono infiniti: la traduzione dei grezzi li copre tutti);
tenere ferma la mira quando si lascia la levetta destra (era la prima
proposta: Sergio vuole le levette come sul telefono); icone dipinte dei tasti
(pesano e vanno rifatte per ogni famiglia: bastano le forme di `ui.lua`);
rimappare anche le levette (restano come sul telefono finché Sergio non chiede
altro).
