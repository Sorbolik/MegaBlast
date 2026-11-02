# Grafica: direzione, mappe, asset, pipeline immagini

Il personaggio ha il suo file: [personaggio.md](personaggio.md). La UI:
[interfaccia.md](interfaccia.md).

## Decisioni prese

| Data | Decisione | Dove |
|---|---|---|
| 19–20 ott | Direzione artistica: proposte A "Orsetti gommosi", B rottami, C giocattoli a molla; Sergio voleva qualcosa di più serio e iconico → aggiunta e **scelta D "Le Scorie"** (carbone, cuori emissivi color squadra, 4 set Corvo/Fornace/Leviatano/Vuoto). Bibbia: https://claude.ai/code/artifact/3add0f2b-7fcb-44ee-8cdb-b1726fa3ccc4. I personaggi Scorie sono poi stati sostituiti dai diavoletti; i nomi dei set restano. | memoria |
| 20 ott | Analisi dell'APK del gioco di riferimento (Unity 4, SmoothMoves): leggibilità da regole (terreno scuro e saturo con contorno, sfondo chiaro e sfocato, poco dettaglio). I suoi asset restano in /mnt/project-files, mai nel repo. Doc accettato da Sergio. | memoria |
| 20 ott | Tentativo di copiare il look del gioco di riferimento (sfondo cotto, contorno del terreno, alone squadra, HUD Cinzel) **bocciato** ("sembra di qualità più bassa") e ripristinato. | PR #23 |
| 21 ott | **Mappe**: quello che si vede è esattamente quello su cui si cammina; bordi angolari (0/45/90°), travi e tubi indistruttibili piatti. Processo: Claude disegna la collisione come poligoni, Sergio genera i materiali con ChatGPT (pietra, crosta, travi, cratere, sfondo), Claude assembla. Mappa 2 **Forgia dei Titani** = default. Misure (robot 20 px): gradino ≤ 22, buco ≤ 28, tunnel ≥ 40, spessore ≥ 20, travi 12. | PR #23, memoria `mappe` |
| 24 ott | Guida alla creazione degli asset (formati PNG 32 bit, master 2×, atlas ≤ 2048, prompt STILE+SOGGETTO+FORMATO con sfondo magenta, mai "trasparente"). | https://claude.ai/artifact/X7kRLmiKwmCYebhNmV6pz3 |
| 26 ott | Scala: mondo ×1,5 (1920×1080, `CELL` 3), maschere restano 640×360. | PR #44 |
| 26 ott | Mappa 3 **Il Crogiolo** (plateau laterali con grotta, ponti d'acciaio, conca a 45°, tunnel, mestoli) e **mappa casuale a partita dal seed** tra Forgia e Crogiolo; mappa "isole" rimossa. Dal basso in alto solo col teletrasporto (Claude). | PR #52 |
| 26 ott | Texture compresse (profilo "Compressa", Basis UASTC) per gli atlas grandi; `--texture-compression true` nelle build. | PR #44 |
| 26 ott | Armi, icone, proiettili vettoriali (vedi arsenale.md); cassa = baule di Gabriella (PR #49, bozza). | PR #51 |
| 28 ott | **Immagini con ChatGPT via Codex**: schede `docs/handoff/WB-xxx` (stati PROPOSTA → APPROVATA → GENERATA → IMPLEMENTATA → VERIFICATA), Codex genera e committa su `design/WB-xxx`; i pezzi del personaggio si disegnano sullo stampino. WB-001 (pezzi del diavoletto di Gabriella) consegnata e montata. | PR #56, docs/handoff/README.md |
| 29 ott | Obiettivo 6 mappe alla pubblicazione; armi nuove solo come modificatori di evento; skin = pezzi sullo stampino con una ricetta ripetibile. | docs/roadmap.md |

| 1 nov | **Sfondi vivi dei gironi** (Sergio: "lo sfondo dell'ingresso in base al girone dove sei arrivato... con tutti i livelli di profondità previsti con Gabriella, e con la predisposizione per fare quelli successivi"): ogni girone è uno shader della GUI che mette uno sopra l'altro i piani della ricetta delle mappe dei gironi (`/mnt/project-files/gabriella/mappe_gironi`: cielo a gradiente con un bagliore, nubi, creste lontane, camini lontani, nebbia, creste medie, camini, catene, creste vicine, braci), ognuno che scorre alla sua velocità e si ripete ogni 2560 px senza stacchi. I piani sono funzioni in `client/gironi/strati.glsl`; il primo è il Prologo, **la Forgia** (`forgia.fp`). Un girone nuovo: un `.fp` con i suoi colori e piani, un `.material` e una riga in `game.gui`. Scelte di Claude: shader invece di strati PNG (niente memoria né peso nell'APK, bordi morbidi di un pixel vero a ogni schermo), il tempo passa nel colore del nodo. | `client/gironi/`, questa PR |
| 2 nov | **Il Limbo dietro la home** (Sergio: "lo sfondo vivo nella schermata di caricamento è uscito benissimo, fammi il secondo della campagna e mettilo nella homepage"): `client/gironi/limbo.fp` con i piani della tavola del Limbo (gironi2.py: nubi, alture a cime piatte, castello con mura merlate e torri a punta, nebbia, mura vicine, colonne spezzate, nebbia bassa, colonne vicine, acqua, polvere che galleggia), dipinti come nel documento delle mappe dell'apprendista di Gabriella (`/mnt/project-files/gabriella/mappe_apprendista`): una sola tinta verde salvia (tema "limbo" di temi.py), sfumatura dalla luce alla foschia su ogni sagoma, tratteggio obliquo in basso, raggi dall'alto, foschia bassa, angoli scuri e grana. Le funzioni dello stile dipinto sono in `strati.glsl` per i gironi dopo. Scelte di Claude, finché Sergio non risponde alle 4 scelte del documento dell'apprendista: stile dipinto come nel documento ma con la grana più leggera (sullo sfondo chiaro si vedeva troppo); tinta del Limbo quella del documento; l'ingresso resta la Forgia calda già approvata (il documento la propone blu: scelta aperta); "IL TUO PROFILO" col contorno scuro per leggersi sul chiaro. | `client/gironi/limbo.fp`, `client/menu/home.lua`, questa PR |
| 2 nov | **Le mappe dell'apprendista nel gioco** (Sergio, dal documento delle mappe di Gabriella: "si vede lo sfondo, A il pavimento"): nelle missioni libere dell'Addestramento e del I girone (partita guidata, Primo sangue, Il codardo, Battaglia della Forgia) il layout **il pavimento**, pochi punti di caduta; il Fabbro sul **pavimento con la fossa di lava** (scelta di Sergio sulla carta: "buttalo nella fossa"). Le missioni che insegnano una meccanica tengono il loro layout, tutto d'acciaio indistruttibile con la texture nuova. Terreno e sfondo dipinti da SVG, una immagine per ogni densità di schermo (`strumenti/grafica/mappe_dipinte.py`, `client/dipinti/`); lo sfondo è la Forgia dipinta che scorre piano (il «movimento calmo»); nei crateri si vede lo sfondo, con l'orlo bruciato. Scelte di Claude: l'acciaio delle arene più scuro di quello del documento (blocchi grandi e chiari rubavano l'occhio al personaggio); cassa di Primo sangue spostata (x 620 → 405) perché cadeva sotto una piattaforma; le immagini si caricano a runtime solo nella densità che serve (non tutte e due in memoria). | `client/dipinti`, `client/battaglia/terreno.*`, questa PR |
| 2 nov | **Banda intoccabile attorno a ogni mappa** (Sergio: "lo zoom livello mappa deve contenere tutta la mappa nel frame e lasciare delle bande laterali a destra e a sinistra, in alto e in basso"): il livello MAPPA mostra tutta la mappa con 40 px di banda ai lati e in cima e sotto lo spazio dell'HUD; anche da vicino la camera può mostrare la banda sul bordo. Nella banda solo lo sfondo. | `client/battaglia/camera.lua`, questa PR |
| 2 nov | **Home: lo sfondo dipinto della Forgia** che scorre piano al posto del Limbo, e l'apprendista nel fermo senza arma e senza scenette (Sergio). | `client/menu/home.lua`, questa PR |

## Scartate

- Direzioni A, B, C (20 ott): Sergio voleva "mostriciattoli mai visti".
- SVG a runtime per la leggibilità: non è la risposta (20 ott).
- Kit UI dipinto v1/v2, icone, loghi, sfondi dipinti: ritirati il 23 ott
  (vedi interfaccia.md).
- Mappa "isole del cimitero": solo un test, rimossa (26 ott).
- Il Limbo dietro la home (2 nov): al suo posto lo sfondo dipinto della Forgia (Sergio, 2 nov); tolti `limbo.fp` e le funzioni dello stile dipinto in `strati.glsl`, che le immagini da SVG fanno meglio.
- Crateri con l'interno scuro sulle mappe dell'apprendista (2 nov, era il consiglio del documento): Sergio ha scelto "si vede lo sfondo".
- Scale sulla mappa Crogiolo dal basso in alto: si scontravano col ponte;
  merli: cuciture visibili (Claude, 26 ott).
- Editor di mappe nel gioco, generazione procedurale come contenuto (29 ott).
- API di OpenAI per generare immagini (28 ott).
- Scenario.gg Pro (45 $/mese) prima che lo stile sia fisso (25 ott).

## Aperte

- Cassa di Gabriella (PR #49): mergiare?
- Maglietta rossa o color squadra per la skin di Gabriella (WB-001).
- Mappe 4–6: chi le disegna e con quale pipeline (Crogiolo = script Python +
  materiali Forgia).
