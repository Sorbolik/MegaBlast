# Controller

Si gioca anche col controller, collegato via Bluetooth o USB: Xbox,
PlayStation e generici, sul telefono Android, sul computer e nel browser. Il
tocco, la tastiera e il mouse restano come prima: chi usa il controller vede
le scritte del controller (lezioni, schede), un dito sullo schermo riaccende
le levette del telefono.

## Tasti in battaglia

Mappatura di Sergio (30 ott). Nomi Xbox; su PlayStation A = croce, B = cerchio,
X = quadrato, Y = triangolo.

| Tasto | Cosa fa |
|---|---|
| Levetta sinistra | Cammina; spinta in su salta (come la levetta del telefono) |
| Levetta destra | Mira: la direzione è l'angolo, quanto la spingi è la potenza (come sul telefono); riportata al centro si spegne |
| RT (grilletto destro) | Spara, con la mira della levetta destra |
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

La mappatura sta tutta in `controller.BATTAGLIA` (`client/ui/controller.lua`):
quando ci sarà la schermata delle impostazioni ([impostazioni.md](impostazioni.md))
i tasti personalizzati cambieranno solo quella tabella.

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
- `client/ui/ui.lua`: la luce sui bottoni (`ui.tocco` con `ui.PAD`).
- `client/main/game.gui_script`, tabella `PAD`: cosa fanno i tasti in battaglia.
- Simulatore: il controller finto (comandi `pad`, `pad_tieni`, `pad_lascia`,
  scenario `strumenti/simula/scenari/controller.txt`).

Scartate: leggere tutti i controller dall'azione grezza (sul computer l'ordine
dei tasti cambia da un controller all'altro, e i noti funzionano già meglio
tradotti da Defold); un file `.gamepads` nostro coi nomi dei controller
Android (i nomi sono infiniti: la traduzione dei grezzi li copre tutti);
tenere ferma la mira quando si lascia la levetta destra (era la prima
proposta: Sergio vuole le levette come sul telefono).
