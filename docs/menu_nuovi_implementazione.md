# Menu nuovi del 14 novembre: inventario per l'implementazione

Riferimento: il Figma, sezione «RIORGANIZZAZIONE MENU · 14 nov» della pagina 3 (le nove
«Consigliata», la home con la pedana scelta) e la prova animata
https://claude.ai/artifact/NUZURUfk3Gt2eaFpnN7roq. Decisioni in
[decisioni/interfaccia.md](decisioni/interfaccia.md) (14 nov). Si segue il procedimento del
12 nov (PR #294 e #297): pezzi di Codex al doppio e mai deformati, scritte nello spazio misurato
del pezzo, niente pezzi vecchi, dove manca un pezzo un segnaposto (mai adattare un pezzo nuovo a
un posto che non è il suo), foto a 20:9, 16:9 e 4:3, controlli, APK di prova.

Regole che valgono per tutto (Sergio):
- armonia degli spazi sempre e su tutto, su ogni schermo (telefono, tablet, desktop);
- immagini alla massima qualità per ogni risoluzione;
- il codice che non serve più si butta;
- le animazioni della prova sono tutte approvate.

## Home

| Nel Figma | Nel codice oggi | Cosa si fa |
|---|---|---|
| tondo del profilo in alto a sinistra (faccia, nome, livello, barra) | logo MEGABLAST in alto a sinistra | via il logo; il tondo apre il PROFILO |
| portafoglio in alto a destra | uguale (`ui/coins.lua`) | resta |
| apprendista sulla pedana a griglia (WB-050 n. 4), zainetto sul ripiano | apprendista sul filo, zona che apre il PROFILO | pedana e zainetto; tocco su apprendista, pedana o zainetto apre lo ZAINO |
| tre segnali di tocco: luce sul bordo della pedana, riflesso di brace sul contorno, respiro al tocco | piega verso il tocco | i tre segnali; via la piega |
| CAMPAGNA e ALLENAMENTO a sinistra, EVENTI e ARMERIA a destra, pulsanti WB-046 con lo scudo verso il bordo | piastre WB-022, IL TUO DIAVOLETTO a destra | pulsanti nuovi; via IL TUO DIAVOLETTO (diventa il tondo del profilo) |
| riga sotto il nome (girone, contro i bot, evento e posto, offerte) | riga sotto il nome e tacche della campagna | resta la riga; le tacche non ci sono nel Figma: via |
| GIOCA online nel sigillo fuso, in basso a destra | lingotto GIOCA | sigillo fuso |
| rotella in basso a sinistra, pillola della coda al centro sotto il filo | uguali | restano |
| | entrata coi pulsanti che volano e l'apprendista che cade | resta, coi pezzi nuovi |
| | CAMPAGNA spenta in coda, sblocchi della campagna | restano |

## Transizioni (prova animata)

- Pulsante: parte veloce verso il suo bordo e frena; l'inversione al bordo è il momento più lento;
  poi riparte accelerando trascinando la schermata; il pulsante intero è la linguetta della
  schermata, sul bordo disegnato (WB-049) con la sua scia di schegge. Ritorno: al contrario.
- Arrivati, lo scudo resta nella testata della schermata come segno di dove sei (lettura di
  Claude di «mantenere l'indicazione nella pagina in cui siamo approdati»).
- ZAINO: esce dall'apprendista e ci rientra.
- Le altre schermate (profilo, gioca online, impostazioni) tengono il passaggio di oggi.

## ZAINO (dall'apprendista): INVENTARIO e SIGILLI

| Nel Figma | Nel codice oggi | Cosa si fa |
|---|---|---|
| testata ZAINO con le schede INVENTARIO e SIGILLI | PROFILO con SCHEDA, SIGILLI, STATISTICHE, PARTITE | lo ZAINO prende INVENTARIO e SIGILLI |
| assetti 1 2 3 dei pezzi; assetto dei sigilli a parte | tre assetti con pezzi e sigilli insieme | assetti separati per pezzi e sigilli (dato nuovo nel profilo) |
| diavoletto con le etichette dei pezzi addosso (linea, chiodo, casella) | SCHEDA con le etichette | casella WB-044 col livello |
| inventario a caselle filtrabile (pezzo e famiglia), 20 pezzi | lista dei pezzi nell'ARMADIO | griglia nuova |
| statistiche a destra con le differenze | colonna statistiche nell'armeria | pannello nuovo |
| pezzo scelto in basso e INDOSSA | | barra in basso |
| SIGILLI: tre vie con barre, dischi a 5 10 15 20, nomi dei poteri, SALVA | `menu/seals.lua` | si rifà coi pezzi nuovi |

## ARMERIA: POTENZIA e BOTTEGA

| Nel Figma | Nel codice oggi | Cosa si fa |
|---|---|---|
| POTENZIA: pezzo scelto, grado, livello con barra e scatti 10 20 30, effetti, prossimo scatto, prova, gli altri pezzi di quel posto, prezzo, POTENZIA | ARMADIO (`menu/pieces.lua`) | POTENZIA nuova; via l'ARMADIO |
| BOTTEGA: 4 offerte del Fabbro scontate e 10 pezzi del giorno, USA UN BUONO, COMPRA | BOTTEGA (4) e CATALOGO | una sola BOTTEGA; via il CATALOGO |
| buoni nel portafoglio dal primo | | dato nel profilo |

## PROFILO (dal tondo in alto a sinistra): STATISTICHE e CRONOLOGIA PARTITE

| Nel Figma | Nel codice oggi | Cosa si fa |
|---|---|---|
| quattro numeri grandi, filtri, righe coi badge, danno per arma | STATISTICHE coi badge | si rifà coi pezzi nuovi; il danno per arma è un segnaposto se il profilo non lo conta |
| cronologia: esito, modo, mappa, facce, punti, classifica, quando, RIVEDI | PARTITE | si rifà |

## EVENTI

| Nel Figma | Nel codice oggi | Cosa si fa |
|---|---|---|
| podio dei primi tre, classifica mondiale fino al 100° e i vicini, il tuo evento, calendario, GIOCA | ORA e PROSSIMI (`menu/board.lua`) | classifica mondiale: il server non la tiene ancora, segnaposto; calendario dietro il suo pulsante |

## GIOCA ONLINE

| Nel Figma | Nel codice oggi | Cosa si fa |
|---|---|---|
| 2 CONTRO 2 grande, STANZA PRIVATA, eventi con coda, in arrivo, GIOCA | `menu/queue.lua` | si rifà coi pannelli e le icone nuove |

## Da buttare alla fine

Il logo della home, la porta IL TUO DIAVOLETTO, le tacche della campagna sulla home, le piastre
dei pulsanti della home che nessuno usa più, l'ARMADIO e il CATALOGO, le schede SCHEDA del
profilo, ORA e PROSSIMI degli eventi, i testi di `lang/it.lua` rimasti senza uso, i pezzi
dell'atlas che nessuno usa più.
