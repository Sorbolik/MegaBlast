# Interfaccia: UI, HUD, comandi

Modulo condiviso `client/ui/ui.lua` (palette `ui.C`, testo, pannelli, bottoni,
barre, dischi e anelli); un solo font (Lilita One dal 29 ott, provvisorio:
la scelta finale è di Gabriella; `client/ui/titolo.font`); forme disegnate in
codice. Regole della roadmap: [../roadmap.md](../roadmap.md) area 21.

## Decisioni prese

| Data | Decisione | Dove |
|---|---|---|
| 20 ott | Home: GIOCA (oro) = online, STESSO TELEFONO = locale. | PR #16 |
| 21 ott | Comandi touch: due pulsanti sinistra/destra + salto; mira trascinando il dito dal robot (direzione = angolo, lunghezza = potenza, tratteggio della traiettoria), tornare sul robot annulla. Poi (PR #23) **due levette** tipo Blastron con smorzamento della mira mantenuto, teletrasporto sopra la levetta di mira; "meglio di Blastron, basato sul tempo". | docs/design.md, PR #23 |
| 23 ott | **UI super minimale**: tutto il kit dipinto ritirato; elementi aggiunti solo quando una schermata li richiede; stile provvisorio che anticipa quello finale. **Mai più asset dipinti per la UI.** | PR #32 |
| 24 ott | Stile **A "Sagoma"** scelto (carbone + contorno chiaro, accento acceso sul pulsante principale); B "Nucleo" e C "Maschera" scartati. I colori vivono solo in `ui.C`; `config.lua` della sim non ha colori. | PR #32 |
| 24 ott | Barra delle armi in basso al centro in tre gruppi col nome: PRIMARIE (brace), SECONDARIA (acciaio), OGGETTI; l'arma usata nel turno si spegne. Barra del turno: gialla finché resta il secondo attacco, blu dopo, lampeggia negli ultimi 2 s. Effetti di stato: scritta che sale, icona coi turni accanto alla vita. | PR #36, #38 |
| 24 ott | Targhe dei giocatori: 4 colori, vita fino a `max_hp`, scudo visibile; podio con pareggi e 2v2. GUI `max_nodes` 2048 (il podio superava 1024). | PR #33, #40 |
| 26 ott | Il font di default non ha le lettere accentate: evitare accenti nelle stringhe nuove finché non si cambia font (Lilita One, dal 29 ott, li ha). Nome del giocatore che segue l'altezza del personaggio; la fiamma è l'indicatore del turno (freccia tolta). | PR #31, #54 |
| 29 ott | **Punti sempre in vista** (Sergio, tutto approvato): nel tutti contro tutti quattro caselle in alto in ordine di posto che si scambiano scorrendo; nel 2v2 e 1v1 una barra a tiro alla fune; posizione (1°…4°) e Corona sopra la testa; i numeri nascono sul colpo e volano nella casella di chi segna; distacco sotto la propria casella; riga di fine turno che sparisce da sola; tic che sale di tono nel turno. Fatto in `client/battaglia/punteggio.lua` (il primo suono del gioco: `client/assets/suoni/punto.wav`); scelte di Claude: i numeri dello stesso colpo (danno e uccisione) si sommano in uno, la Corona sul gettone appare quando il numero arriva, quella sulla testa segue la regola (chi è primo davvero), i punti persi nascono sul robot stesso e sono grigi. | #60 |
| 29 ott | **Draft online** con la stessa schermata dello stesso telefono (`menu/scelta.lua`): sceglie solo chi gioca sul telefono, si cambia fino allo scadere, la barra segue il tempo del server; nel 2 contro 2 un bottone accanto alla barra propone lo scambio di tutte le scelte al compagno ("SCAMBIA CON ROSSO 2" → "SCAMBIO PROPOSTO", ritoccandolo si ritira) e il titolo dice quando è il compagno a proporlo ("ACCETTA LO SCAMBIO"). Niente popup. Scelte di Claude: in ogni fila dove hai già scelto resta accesa solo la tua carta (vale anche sullo stesso telefono: con i colori di squadra non si capiva quale fosse la tua); la coda online è quella di `[megablast] giocatori` finché la home non ha la scelta del modo. | questa PR |
| 29 ott | **HUD della battaglia rifatto** (proposte disegnate https://claude.ai/artifact/517GdYx8Cb7hFFN3rnU7xH, scelte di Sergio): punti in alto al centro; **cronometro ad anello** in basso al centro che si consuma liscio in senso orario, secondi grandi dentro, stessi colori di fase (bianco, giallo "SECONDO!", blu "RIPARATI"), un battito al secondo che cresce verso la fine del turno (3% sopra 10 s, 4→8% fino a 5 s, 10→18% con onda negli ultimi 5) e della finestra del secondo attacco (5→16%), respiro fisso del 2% quando ci si ripara; bordino del colore di chi gioca; tempo della partita sopra, più piccolo. Primarie a sinistra dell'anello (Lanciarune accanto), secondarie a destra con gli **oggetti tondi sopra** (variante A); Rampino/Bastione tondo e viola accanto al teletrasporto, anch'esso tondo coi teletrasporti rimasti in un numerino. **Il lato sinistro resta libero**: sul telefono la mano sinistra muove, armi ed equipaggiamento si cambiano con la destra (un giorno l'HUD si potrà sistemare a piacere, ma i predefiniti devono essere solidi). Quello in mano si alza, prende il bordo chiaro, l'alone del tuo colore e un cartellino col nome; via le scritte PRIMARIE/SECONDARIE. Levette disegnate come nelle proposte (dischi e anelli). Sul telefono, **mentre si mira un tocco in qualsiasi punto annulla la mira** (poi solo sulla metà destra, vedi sotto) (sul computer resta il tasto destro, che ora annulla anche la levetta). Font **Lilita One**. Icone vettoriali nuove per teletrasporto, trappola, scudo, trampolino e paracadute (`strumenti/grafica/armi.py`). Scelte di Claude: Lanciarune sempre accanto all'anello (il posto non cambia quando arrivano le casse); sul telefono slot da 72 (62 con cinque primarie, così non toccano la levetta); il giallo entra con un lampo. | `client/battaglia/hud.lua`, PR #65 |
| 29 ott | **Tranquilla ed essenziale**: niente popup da cliccare, niente notifiche invadenti o badge rossi, una cosa per schermata, in partita solo ciò che serve al turno, transizioni sotto i 200 ms, suggerimenti solo contro i bot; ogni schermata nuova passa dal simulatore e da Sergio. | docs/roadmap.md |
| 29 ott | **Tutorial** (proposte https://claude.ai/artifact/6Ftj79qZsYg18TWQr7fYTc, scelte di Sergio 1B 2A 3A 4 5 7): la prima partita insegna, GIOCA porta alla partita guidata contro il bot finché non la finisci; una riga alla volta sopra il diavoletto (o sopra il bot quando spiega cosa fa lui) e l'HUD che pulsa; il bot sbaglia un colpo su due e nel primo turno il tempo è fermo finché non attacchi. Niente pulsante TUTORIAL in home: **CONTRO I BOT diventa ALLENAMENTO** con due schede, LEZIONI (8 lezioni da 3 stelle: armi, globi, casse, paracadute, rampino, bastione, maglio, corona) e CONTRO I BOT. Le lezioni sono dati (`client/sim/lezioni.lua`) e `tests/lezioni_test.lua` controlla che ognuna si risolva con la sua meccanica e non senza. Scelte di Claude: le righe passano una alla volta e un turno nuovo le cancella; si aprono sempre le LEZIONI finché ce n'è una da fare; la cura non ha riga (la annuncia già il gioco). | `client/sim/lezioni.lua`, `client/menu/allenamento.lua`, #66 |
| 29 ott | **Camera quando si spara** (Sergio: "da vicino è ingiocabile, appena sparo la camera segue il colpo"): finché chi spara può ancora muoversi (fase di mira: secondo attacco e riparo negli 8 s) la camera **inquadra lui e il colpo insieme**, allontanandosi solo quanto basta perché ci stiano tutti e due sopra l'HUD (al massimo tutta la mappa), poi lui e l'esplosione per un attimo, poi torna allo zoom scelto; quando il turno è finito segue il colpo come prima (lì non c'è niente da comandare). Scelta di Claude, alternative scartate sotto. Allontanarsi è svelto (molla 12/s) e, se le molle restano indietro, lo zoom si apre subito perché nessuno dei due esca; avvicinarsi resta morbido (6/s). | `client/battaglia/camera.lua` (`inquadra`), `strumenti/simula/scenari/camera_colpo.txt`, questa PR |
| 29 ott | **Annullare la mira solo a destra** (Sergio): il tocco che annulla la mira sul telefono vale solo sulla metà destra dello schermo, perché con il tocco ovunque, appena si iniziava a camminare con la sinistra mentre si mirava, la mira spariva. | `client/main/game.gui_script`, questa PR |

## Scartate

- Kit UI dipinto v1 e v2, 20 icone, sfondi dipinti, logo (23 ott): la UI è di
  codice.
- Stili B e C (24 ott).
- Camera quando si spara (29 ott), scartate: **finestrella** che segue il colpo
  con la camera che resta sul diavoletto (un secondo disegno del terreno a ogni
  frame, troppo per i telefoni deboli, e un riquadro in più su uno schermo già
  coperto dall'HUD); **solo una freccia** al bordo verso il colpo (si perde lo
  spettacolo del colpo che Sergio vuole tenere e da vicino non si vede dove
  colpisce); **pulsante "segui il colpo"** (un altro tasto e un'altra scelta in
  turni da 25 s); **passare a tutta la mappa a ogni colpo** (salto brusco, il
  diavoletto diventa minuscolo anche per i colpi corti); **rallentatore o replay**
  (allunga i turni e online il tempo lo conta il server).
- Pulsanti MISSILE/SPADA separati: sostituiti dalla barra (20 ott).
- Impostazioni grafiche a livelli e rimappatura dei tasti (29 ott).
- Chat testuale: solo emote o frasi predefinite (29 ott).
- Oggetti nell'angolo in basso a sinistra (variante B delle proposte, 29 ott):
  Sergio vuole il lato sinistro libero per la mano che muove.
- Anello a tacche, una al secondo (29 ott): sul telefono 25 tacche sono troppo
  piccole, i secondi li dice il numero.
- Font scartati (29 ott): Luckiest Guy e Bangers (solo maiuscole, piccoli si
  impastano), Chewy e Grandstander (troppo morbidi a 14 punti), font a pixel
  (il gioco non è pixel art), Baloo 2 (troppo largo); Titan One seconda scelta,
  Rubik la scelta sobria, Fredoka da tagliare statico. Cinzel: freddo e stretto.
- Tutorial a passi prima di giocare, pulsante TUTORIAL fisso in home, popup che
  fermano la partita (29 ott): chi gioca da un anno non deve vedere un pulsante
  del tutorial; le lezioni stanno nell'Allenamento.

## Aperte

- Scelta della coda online (1v1, 2v2, tutti contro tutti) nella home: oggi la
  dice `[megablast] giocatori` nella build. Serve per l'uscita della fase 0.
- Icone delle armi: vettoriali dal 26 ott; idea "sagome piatte" superata.
- Font definitivo: lo sceglie Gabriella (oggi Lilita One).
- HUD sistemabile dal giocatore (posizione dei pulsanti): più avanti.
