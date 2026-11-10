# Il Figma dell'interfaccia

Sergio, 10 nov: «nel figma deve esserci tutto, e per ogni bordo, font, tabs,
bottone deve esserci un generico che venga riflesso su tutti gli elementi della
stessa tipologia», «che rifletta quello che c'è oggi nel gioco», «componenti a
full resolution che poi possano essere riflessi in gioco».

Ci sono due file. Tutti e due si modificano sia da Sergio sia da Claude (lo fa
col connettore Figma).

- **MegaBlast · Interfaccia** (Design): https://www.figma.com/design/i7CjXyRO8X6NQOk7ntONZh
  - *1 · Fondamenta e componenti*: le variabili (collezione **Colori ui C** = `ui.C` di
    `client/ui/ui.lua`, collezione **Misure ui lua** = le misure di `ui.lua` e delle forme di
    `tools/grafica/ui.py`), gli stili di testo (Lilita One, il font del gioco) e i
    componenti generici: Pannello, Bottone, Bottone principale, Tab, Angolo (indietro e
    rotellina), Pillola della coda, Barra, Testata. Ogni componente ha nella descrizione
    la funzione di `ui.lua` che lo disegna. Colori, raggi e bordi sono legati alle
    variabili: cambiata una variabile, cambiano tutti gli elementi di quel tipo.
  - *2 · Schermate di oggi*: una cornice 1280 x 720 per schermata, con sotto la foto vera
    dal simulatore (2560 x 1440, bloccata) e sopra la ricostruzione coi componenti, nelle
    posizioni del codice. Spegnendo il livello della foto si vede solo la ricostruzione.
  - *3 · Proposte*: regole proposte (taglie di testo, bottoni, tab, scheda, posto
    dell'azione principale), i componenti proposti e il piano per ogni menu. Finché
    Sergio non le approva sono solo proposte: il gioco segue la pagina 2.
- **Lavagna MegaBlast** (FigJam): https://www.figma.com/board/IZ5dnV76izRNgRs9SJFUF5 , sezione
  *INTERFACCIA · MAPPA DEI MENU*: le miniature di ogni schermata e le frecce dei
  passaggi (cosa si tocca per andare dove).

## Come restano in pari

**Dal Figma al gioco** (Sergio cambia un colore o una forma, o approva una proposta):

1. Claude passa `tools/figma/leggi.js` al tool `use_figma` sul file Design e salva quello che
   restituisce in `tools/figma/interfaccia.json` (la chiave `nota` resta).
2. `python3 tools/figma/applica.py` riscrive i colori di `ui.C` (e `ui.GOLD`, `ui.MEDAL`) in
   `client/ui/ui.lua` e rifà con `tools/grafica/ui.py` le forme bianche che dipendono dal
   Figma (forma, bordo, eroe, slot_arma, pillola, badge). Le altre immagini non le tocca.
   Senza cambiamenti nel Figma non cambia niente. Controlla anche che raggi e smussi
   stiano nel 9-slice di `NINE` in `ui.lua`.
3. Simulazione e foto, come per ogni modifica che si vede.

Le forme in gioco sono 9-slice a densità 1 (un pixel dell'immagine per pixel del gioco
negli angoli, vedi `tools/grafica/ui.py`): per questo dal Figma passano i numeri (raggio,
bordo, smusso) e non le immagini esportate, che nel 9-slice non resterebbero nitide. Gli
schermi grandi restano nitidi lo stesso, perché le forme si ridisegnano dai numeri.
Una disposizione nuova (un bottone spostato, un menu rifatto) passa invece dal codice
della schermata: Claude legge la cornice dal Figma e la riporta nel `.lua` del menu.

**Dal gioco al Figma** (una PR cambia l'interfaccia): nella stessa PR
- se cambiano `ui.C` o le forme, si aggiorna `interfaccia.json` e si passa a `use_figma`
  `tools/figma/scrivi.js` coi dati incollati al posto di `DATI`;
- se cambia una schermata, si rifanno le foto con `python3 tools/simula/simula.py --scala 2
  -s tools/simula/scenari/figma.txt` (anche `figma_online.txt` e `figma_fine.txt`) e si
  ricarica la foto nella sua cornice della pagina 2 (tool `upload_assets` con l'id del
  livello «Foto del gioco»), sistemando la ricostruzione sopra;
- se cambia un passaggio fra menu, si aggiorna la freccia nella lavagna.

Il connettore carica le foto da `mcp.figma.com`, che è fra gli host permessi
dell'ambiente cloud (10 nov).
