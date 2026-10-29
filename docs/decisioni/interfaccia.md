# Interfaccia: UI, HUD, comandi

Modulo condiviso `client/ui/ui.lua` (palette `ui.C`, testo, pannelli, bottoni,
barre); un solo font (Cinzel, `client/ui/titolo.font`); forme disegnate in
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
| 26 ott | Il font di default non ha le lettere accentate: evitare accenti nelle stringhe nuove finché non si cambia font. Nome del giocatore che segue l'altezza del personaggio; la fiamma è l'indicatore del turno (freccia tolta). | PR #31, #54 |
| 29 ott | **Punti sempre in vista** (Sergio, tutto approvato): nel tutti contro tutti quattro caselle in alto in ordine di posto che si scambiano scorrendo; nel 2v2 e 1v1 una barra a tiro alla fune; posizione (1°…4°) e Corona sopra la testa; i numeri nascono sul colpo e volano nella casella di chi segna; distacco sotto la propria casella; riga di fine turno che sparisce da sola; tic che sale di tono nel turno. | PR successiva |
| 29 ott | **Tranquilla ed essenziale**: niente popup da cliccare, niente notifiche invadenti o badge rossi, una cosa per schermata, in partita solo ciò che serve al turno, transizioni sotto i 200 ms, suggerimenti solo contro i bot; ogni schermata nuova passa dal simulatore e da Sergio. | docs/roadmap.md |

## Scartate

- Kit UI dipinto v1 e v2, 20 icone, sfondi dipinti, logo (23 ott): la UI è di
  codice.
- Stili B e C (24 ott).
- Pulsanti MISSILE/SPADA separati: sostituiti dalla barra (20 ott).
- Impostazioni grafiche a livelli e rimappatura dei tasti (29 ott).
- Chat testuale: solo emote o frasi predefinite (29 ott).

## Aperte

- Schermata del draft online nel client (il server la gestisce già; il client
  riempie da solo): fase 0 della roadmap.
- Pulsante TUTORIAL in home: fase 0.
- Icone delle armi: vettoriali dal 26 ott; idea "sagome piatte" superata.
