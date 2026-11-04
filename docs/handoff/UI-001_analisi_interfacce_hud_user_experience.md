# UI-001 · Analisi Approfondita Interfacce, HUD e User Experience

- **Stato:** PROPOSTA (per Sergio e Claude)
- **Data:** 2026-11-04
- **Autore:** Codex / Antigravity
- **Destinatario:** Sergio (Direttore del gioco) e Claude (Coordinatore del progetto MegaBlast)
- **Riferimento decisioni:** [docs/decisioni/interfaccia.md](../decisioni/interfaccia.md) (stile minimale Sagoma, HUD essenziale, nessuna distorsione `ADJUST_FIT`).

---

## 1. Obiettivo e Quadro Generale

MegaBlast ha sviluppato un'identità visiva distintiva: interfaccia minimale in stile **Sagoma** (carbone, bordi chiari, accenti del colore di squadra, zero kit dipinto skeuomorfo, zero popup invasivi).
Con l'evoluzione rapida delle ultime settimane sono state integrate moltissime funzioni avanzate: zoom continuo, sala d'attesa online con cartellini, pillola di matchmaking persistente, orbi con soglie temporali, baratto del secondo attacco, oggetti tattici consumabili, vignette narrative e schede personaggio.

Questo report analizza **come tutti questi elementi convivono su schermo**, valutando:
1. **L'ergonomia dei pollici su dispositivi touch** (comfort, distanze, rischi di tocco accidentale).
2. **L'adattabilità agli schermi reali** (smartphone ultrawide 20:9 vs standard 16:9 vs tablet 4:3).
3. **La pulizia visiva e la gerarchia delle informazioni** in partita (evitare sovrapposizioni e distrazioni durante la mira).
4. **La fluidità del flusso utente** nei menu (onboarding, coerenza tra Home, Profilo e Armeria).

---

## 2. Analisi dell'HUD di Battaglia e Comandi Touch

```
+-------------------------------------------------------------------------------+
| [INGRANAGGIO]  (pillola coda)     [PUNTI / FUNE]                 [ZOOM SLIDER]|
|                                  [OBIETTIVO MISSIONE]                         |
|                                    (suggerimenti)                             |
|                                                                               |
|                                     [PERSONAGGI]                              |
|                                                                 (oggetti 4)   |
|                                                                 (oggetti 3)   |
|                                                                 (oggetti 2)   |
|                                                    [BARATTO]    (oggetti 1)   |
| (levetta sx)             [SLOT PRIMARIE]  [CRONOMETRO]  [SECONDARIE] [TP]     |
| [MOVE_PAD]              (1) (2) (3) (4)    [ORBI / SEC]  (1) (2)   [AIM_PAD]  |
+-------------------------------------------------------------------------------+
```

### 2.1 Congestione del Bordo Destro (Colonna Comandi vs Joystick Mira)
- **File:** `client/main/game.gui_script`, `client/battle/hud.lua`
- **Criticità:**
  Lungo il margine destro dello schermo (`x1 - 70`..`x1 - 115`), sono impilati **4 sistemi interattivi verticali differenti**:
  1. **Aim Pad (Levetta Mira)**: posizionata a `y0 + 117` con zona touch attiva che sale fino al 60% dello schermo (`y0 + 432`).
  2. **Tasto Teletrasporto Touch**: a `y0 + 257`.
  3. **Colonna Oggetti Consumabili (Trappola, Scudo, Trampolino, Paracadute)**: cresce verso l'alto sopra il teletrasporto da `y0 + 337` fino a `y0 + 541`.
  4. **Tasto e Guida dello Zoom Continuo**: tasto tondo a `y1 - 110` (`y0 + 610` a 16:9), la cui capsula-guida quando trascinata scende di 230 px fino a `y = 380`.
- **Problema di Giocabilità:**
  - **Sovrapposizione Spaziale**: Quando il giocatore trascina lo zoom verso il basso per allargare la visuale, il pollice scorre fisicamente sopra i pulsanti degli oggetti 2, 3 e 4.
  - **Interferenza con la Mira**: La mira verso l'alto (angoli 60°–90°) porta il pollice destro a salire nella zona tra `y = 250` e `y = 400`, vicinissima al tasto del teletrasporto e agli oggetti.
  - **Annullamento Mira a Destra**: La regola di Sergio (decisione 29 ott) stabilisce che *"un tocco sulla metà destra annulla la mira"*. Se un giocatore ha la levetta di mira attiva e tocca rapidamente a destra per annullare, c'è il rischio concreto di colpire un pulsante oggetto o lo zoom.
- **Proposta di Miglioramento:**
  - **Layout ad Arco Naturale per gli Oggetti**: Invece di una colonna verticale rigida verso il soffitto, disporre i 3–4 pulsanti degli oggetti lungo un **arco radiale ergonomico** attorno alla levetta di mira destra (a raggio costante di ~140 px dal centro di riposo della levetta). Questo rispetta la naturale rotazione del pollice e libera completamente la fascia superiore destra.
  - **Spostamento del Pulsante Zoom**: Spostare il tasto dello zoom sul bordo superiore (es. `y1 - 40`) o sul lato sinistro alto (sotto la rotellina/ingranaggio), dove non interferisce con la mano che mira e spara.

### 2.2 Rischio di Collisione tra Slot Primarie e Levetta Movimento a Sinistra
- **File:** `client/main/game.gui_script`
- **Criticità:**
  Gli slot delle armi primarie si espandono dal centro verso sinistra:
  `x = W/2 - from_pt - d/2 - k * (d + gap)`.
  Quando un giocatore raccoglie casse e accumula 4 o 5 armi primarie, lo slot 5 scende fino a `x = 162`.
  La levetta di movimento (`MOVE_PAD`) si trova a `x0 + 115`. Il suo raggio di base è 90 px, coprendo fino a `x = 205`.
- **Problema:**
  Quando il pollice sinistro spinge verso destra per camminare in avanti, invade la bounding box degli slot 4 e 5 delle primarie. Un micro-rilascio o un tocco imperfetto rischia di selezionare un'arma invece di continuare a camminare.
- **Proposta di Miglioramento:**
  - Limitare la larghezza totale del gruppo primarie: quando ci sono più di 3 primarie, adottare slot compatti da 56 px o disporli a ventaglio orizzontale a quota leggermente ribassata, garantendo sempre una **safe-zone di almeno 50 px** tra il limite destro della levetta e il primo slot.

### 2.3 Ergonomia del Tasto "Baratta con Teletrasporto" (Swap)
- **File:** `client/battle/hud.lua`
- **Criticità:**
  Il pulsante di baratto compare sopra il cronometro centrale (`x = 640`, `y ≈ 180`).
  Sergio ha voluto che il baratto fosse un'azione intenzionale e non accidentale (lontana dai pollici).
  Tuttavia, su smartphone moderni con schermi grandi (6.5" – 6.8"), la posizione `x = 640` è esattamente nel "punto morto" centrale: né il pollice sinistro né il destro riescono a raggiungerla senza staccare la mano dalla presa salda del telefono. Durante gli 8 secondi del secondo attacco (spesso mentre il terreno crolla o bisogna riposizionarsi), cambiare impugnatura per premere il baratto fa perdere preziosi secondi.
- **Proposta di Miglioramento:**
  - Mantenere la posizione centrale pulita, ma aggiungere una **gestualità alternativa opzionale**: ad esempio, toccare due volte il pulsante del Teletrasporto quando la finestra di secondo attacco è aperta attiva direttamente il baratto.

---

## 3. Adattabilità Responsiva e Gestione degli Spazi a Schermo

MegaBlast viene renderizzato in coordinate virtuali 1280×720 con nodi sempre `ADJUST_FIT`. Su schermi con proporzioni diverse, lo spazio varia in larghezza o altezza:

```
+---------------------------------------------------------------------------------+
| Aspect Ratio   | Dimensioni Gioco  | x0 .. x1   | y0 .. y1   | Caratteristica   |
|----------------|-------------------|------------|------------|------------------|
| 16:9 (Standard)| 1280 x 720        | 0 .. 1280  | 0 .. 720   | Perfetta base    |
| 20:9 (Phone)   | 1600 x 720        | -160..1440 | 0 .. 720   | Molto più largo  |
| 4:3 (iPad)     | 1280 x 960        | 0 .. 1280  | -120..840  | Molto più alto   |
+---------------------------------------------------------------------------------+
```

### 3.1 Sovrapposizione Personaggio / Pulsanti Home su Tablet 4:3 (iPad)
- **File:** `client/menu/home.lua`
- **Diagnosi:**
  In `home.lua`, il diavoletto protagonista è posizionato a coordinate fisse:
  `BODY_X = 400`, `BODY_Y = 200`, con zona di tocco larga 260 px (da `x = 270` a `x = 530`).
  Il gruppo dei pulsanti di sinistra (`ARMERIA` ed `EVENTI`, larghi 240 px) è ancorato con `ANCHOR_LEFT`:
  `x = x0 + 48 + 120`.
  A 16:9 (`x0 = 0`), il centro pulsanti è a `x = 168` (ingombro da `x = 48` a `x = 288`).
  Se la viewport varia o su layout compatti, la sagoma del personaggio e i pulsanti arrivano a lambirsi.
  Inoltre, la label `"IL TUO PROFILO"` sotto i piedi del diavoletto (`y = 166`) e il pulsante `EVENTI` (`y = 160`) sono alla medesima quota orizzontale a ridosso l'uno dell'altro.
- **Soluzione:**
  Posizionare il diavoletto della Home rispetto al centro reale dello schermo (`screen.W / 2`), con un offset proporzionale che mantenga sempre almeno 60 px di luce tra i pulsanti di sinistra e la spalla del personaggio su qualsiasi proporzione.

### 3.2 Distacco Testata / Schede nei Menu su Schermi Taller (4:3)
- **File:** `client/ui/ui.lua`
- **Diagnosi:**
  Il nuovo sistema `ui.header` fissa la testata (`h.left` e `h.right`) con `gui.ANCHOR_TOP` a `y1 - 62`.
  Su un iPad 4:3 (`y1 = 840`), la testata sale a `y = 778`.
  I tab di navigazione (`ui.header_tabs`) sono invece creati con `ANCHOR_NONE` e posizionati alla coordinata statica `M.TABS_Y = 578`.
  **Risultato visivo:**
  Tra la riga della testata (Titolo e Freccia Indietro) e la riga dei Tab (SET, ALBERO, ecc.) si crea uno stacco anomalo di 200 pixel, mentre il contenuto sottostante rimane compresso verso il centro, lasciando spazio vuoto sul fondo.
- **Soluzione:**
  Agganciare il contenitore dei tab e il corpo del menu alla testata, in modo che l'offset verticale tra testata, tab e contenuto rimanga costante (`24 px`), distribuendo armoniosamente lo spazio extra in basso.

### 3.3 Bande Laterali Vuote di 380 px nei Menu su Smartphone 20:9
- **File:** `client/menu/armory.lua`, `client/menu/profile_tabs.lua`
- **Diagnosi:**
  Sui telefoni 20:9 (schermo largo 1600 px):
  - Il tasto Indietro e il Titolo sono spinti all'estrema cornice sinistra (`x = -130`).
  - I comandi contestuali (es. `ASSETTO 1 2 3`) sono spinti all'estrema cornice destra (`x = +1410`).
  - Il contenuto effettivo (carte dei set, pannello statistiche) rimane limitato all'interno del box 1280.
  Si generano circa 190 px di vuoto per lato, scollante la testata dal corpo.
- **Soluzione:**
  Nelle schermate dense a due colonne (come Armeria), ancorare il pannello statistiche al margine destro reale (`h.right - 250`), lasciando allargare fluidamente la colonna centrale delle carte.

---

## 4. Gerarchia Visiva e Leggibilità in Battaglia

### 4.1 Sovrapposizione del Bordo Superiore Centrale
- **Criticità:**
  Al centro in alto convergono 4 informazioni diverse nello stesso spazio verticale:
  1. **Tacca del proiettile uscito in alto** (`CP.notch`, bordo superiore a `y1`).
  2. **Tabellone dei punti / Fune del tiro alla fune** (a quota `y1 - 40`).
  3. **Obiettivo missione in oro** ("2/3 Sali sulla piattaforma") sotto i punti.
  4. **Riga di testo del suggerimento / Favilla** sotto l'obiettivo.
- **Problema:**
  Durante le missioni con salti alti o lanci verticali, questa colonna di 4 elementi copre fino a 140 px dall'alto al centro. Se un diavoletto salta su una piattaforma alta o usa il paracadute, la sua targa e la sua mira rischiano di finire sotto i testi.
- **Proposta di Miglioramento:**
  - Quando il giocatore mira in alto o il personaggio supera una quota elevata (`y > 600`), sfumare temporaneamente la riga del suggerimento in semitrasparenza (alpha 0.2), ripristinandola a riposo.

### 4.2 Leggibilità del Conteggio Munizioni e Orbi a Colpo d'Occhio
- **File:** `client/main/game.gui_script`, `client/battle/hud.lua`
- **Criticità:**
  Il numero di munizioni residue negli slot quadrati è scritto come una semplice etichetta testuale `"x2"`, `"x1"` in basso a destra nell'angolo dello slot (`label(22, -26)`).
  Su schermi piccoli ad alta densità (Full HD / 1440p mobile), il testo grigio scuro su sfondo scanalato ha un contrasto ridotto.
- **Proposta di Miglioramento:**
  - Racchiudere il contatore in una **micro-pillola ad alto contrasto** (fondo carbone puro con bordino chiaro), identica nello stile ai badge del gioco. Quando resta **1 solo colpo**, tingere il numerino o il contorno di un tenue giallo d'avviso.

---

## 5. User Experience dei Menu e Flusso di Navigazione

### 5.1 Onboarding e Nomenclatura delle Modalità
- **Evidenza:**
  Attualmente in Home figurano sia `CAMPAGNA` sia `ALLENAMENTO`.
  Per un nuovo utente, la distinzione tra Campagna (storia con tutorial progressivo) e Allenamento (bot liberi) può risultare inizialmente ambigua.
- **Proposta:**
  - Nella Home, aggiungere un sobrio sottotitolo o indicazione di contesto:
    - **CAMPAGNA**: *"Storia & Lezioni"*
    - **ALLENAMENTO**: *"Partita libera contro i Bot"*

### 5.2 Coerenza Navigazionale: Armeria in Home vs Armeria nel Profilo
- **Evidenza:**
  L'`ARMERIA` è accessibile sia dalla Home sia dall'interno del `PROFILO`.
- **Proposta:**
  - Garantire che la transizione Indietro (`indietro`) mantenga memoria del contesto di provenienza: chi entra da Home torna a Home, chi entra dal Profilo torna al Profilo senza scatti o ricaricamenti anomali.

---

## 6. Matrice delle Proposte di Miglioramento UI/UX

| ID | Area | Problema Risolto | Soluzione Proposta | Impatto |
|---|---|---|---|---|
| **UI-P1** | HUD Mobile | Congestione e sovrapposizione comandi sul bordo destro (Zoom, Oggetti, Teleport, Aim) | Disporre gli oggetti a ventaglio/arco attorno alla levetta di mira; spostare lo zoom sul bordo alto-sinistro | **Alto**: elimina tocchi accidentali e rende la mira verso l'alto pulita |
| **UI-P2** | Responsive 4:3 | Rischio contatto personaggio e pulsanti Home su schermi tablet | Centrare il personaggio rispetto al centro reale della viewport con safe-margin garantito | **Alto**: pulizia estetica su tablet |
| **UI-P3** | Responsive 4:3 | Vuoto di 200 px tra testata e tab nei menu | Collegare l'ancoraggio dei tab alla testata reale (`ANCHOR_TOP`) | **Medio**: interfaccia coerente e compatta su iPad |
| **UI-P4** | Responsive 20:9 | Bande laterali vuote di 380 px e testata scollata dal contenuto nei menu | Layout fluido a due colonne che ancora il pannello statistiche al margine destro reale | **Medio**: sfrutta appieno gli schermi moderni |
| **UI-P5** | HUD Mobile | Possibile conflitto tra slot primarie 4/5 e levetta movimento sinistra | Introdurre safe-zone di 50 px con compressione proporzionale degli slot oltre il 3° | **Medio**: previene cambi arma involontari durante la corsa |
| **UI-P6** | Leggibilità | Numeri munizioni e orbi poco evidenti nella visione periferica durante il turno | Micro-pillola ad alto contrasto per le munizioni; avviso visivo sull'ultimo colpo | **Basso**: leggibilità immediata a colpo d'occhio |
| **UI-P7** | Ergonomia | Difficoltà a raggiungere il tasto Baratto a centro schermo con una mano | Doppio tocco sul tasto Teletrasporto come scorciatoia per attivare il baratto | **Basso**: comodità per chi gioca su telefoni grandi |

---

## 7. Raccomandazioni di Sequenza Operativa

1. **Priorità Immediata**: Risolvere il posizionamento relativo della Home su schermi 4:3 (**UI-P2**) e l'ancoraggio coerente testata/schede (**UI-P3**), poiché impattano direttamente la pulizia estetica dell'applicazione su tablet e desktop.
2. **Priorità di Gameplay**: Riorganizzare l'arco dei pulsanti oggetti a destra (**UI-P1**) per liberare l'escursione dello zoom e scongiurare interferenze con la mira.
3. **Preservazione dello Stile**: Tutte le modifiche rispettano rigorosamente la filosofia di Sergio: **forme pure di codice, zero asset dipinti, palette `ui.C`, transizioni a scivolo/iride sotto i 200 ms e nessun popup modale**.
