# Architettura, strumenti, infrastruttura

Dettagli tecnici in [../design.md](../design.md), [../server.md](../server.md),
[../setup.md](../setup.md), [../../strumenti/simula/README.md](../../strumenti/simula/README.md).
Il futuro (server pubblico, account, pannello) è in [../roadmap.md](../roadmap.md).

## Decisioni prese

| Data | Decisione | Dove |
|---|---|---|
| 19 ott | **Defold** (motore 2–3 MB, app sotto i 10 MB, Lua, un progetto per tutte le piattaforme). Scartati Godot (~30 MB), Unity (40+ MB), raylib (tutto a mano). | docs/design.md |
| 19 ott | **Un repo** per client e server; sim Lua pura in `client/sim/` (Defold carica solo moduli nel progetto), modulo Go alla radice che la incorpora con gopher-lua. **Server autoritativo**, JSON su WebSocket (coder/websocket, extension-websocket). Terreno = maschera 1 bit, crateri come operazioni sulla maschera. | PR #1–#3 |
| 20 ott | Il sandbox non può scaricare Defold per i build; poi trovato il modo: `bob.jar` dalle release GitHub + Java 25 da apt + Xvfb → **simulatore** `strumenti/simula/simula.py` (controlli dell'editor, test, build, scenario, foto e video). Va eseguito prima di ogni consegna al client. | PR #14 |
| 21 ott | Skill del progetto in `.claude/skills/` (progetta, valuta, dottore del design, sviluppa meccanica; 5 skill Defold CC0). | PR #24, #30 |
| 23 ott | **Server scalabile**: un worker per core con un ticker a 60 Hz condiviso (niente lock nel ciclo di gioco); terreno in Go (`server/terreno.go`) con test differenziali contro il Lua; JSON scritto in Go; protocollo v2 con gettone di riconnessione (20 s di grazia); client lento disconnesso; scala orizzontale con nodi indipendenti e `/health`. Numeri: < 1 ms per creare una stanza, 0,9 MB a stanza, ~75 partite 1v1 per core. | PR #34, docs/server.md |
| 24 ott | Code `1v1`, `2v2`, `ffa`, `torneo`; draft nella stanza. | PR #34 |
| 24 ott | **Build HTML5** per provare su iPhone (niente account Apple né Mac): `strumenti/web/build.sh`, pubblicata come Artifact sempre allo stesso indirizzo https://claude.ai/artifact/WeHdWjA9HzabJJpfKKhH5G ; online dal browser con `ws_browser.lua`, ma dalla pagina claude.ai le WebSocket esterne sono bloccate: quando il server sarà pubblico, la build web la serve lui. | PR #35 |
| 25 ott | **Valutazione motori** (Unity, Godot, altri): si resta su Defold; Godot ~10× più pesante, Unity richiede riscrivere sim e server. Scartati Cocos, Phaser, LÖVE, Solar2D, Bevy, GameMaker, MonoGame. Pagina: https://claude.ai/artifact/BfPbDf2r1Gfdb2DV9JPoaL | memoria |
| 26 ott | Texture compresse nelle build (`--texture-compression true`); l'editor di Defold non comprime. | PR #44 |
| 28 ott | **Editor delle animazioni su Cloudflare** (Worker "megablast" dal main, cartella `strumenti/animazioni/cloudflare`, segreti `EDITOR_CHIAVE` e `GITHUB_TOKEN`); "Manda a Claude" scrive solo sul ramo `editor-ultima`. Il container di Claude non raggiunge Cloudflare. | PR #55, #57 |
| 28 ott | Codex sul PC di Sergio esegue le schede immagini (vedi grafica.md); possibile in futuro lanciarlo da Claude via controllo remoto. | PR #56 |
| 29 ott | **Server sempre in pari con main** (Sergio, regola permanente: vedi [regole.md](regole.md)). Verificato e allineato in questa PR: l'attrezzo dell'assetto arriva col `hello`; `start` porta le scelte del draft (il client crea la partita con le stesse armi); lo stato porta `kn` (sbalzato) e `la` (direzione dell'Affondo), che il client usava solo in locale. Punti, Corona e Bastione erano già in pari. | questa PR |
| 29 ott | **L'online si prova nel simulatore**: nella build del simulatore senza estensione il client usa una WebSocket su LuaSocket (`client/main/ws_socket.lua`); il comando `server MODO N` degli scenari avvia il server vero e N giocatori finti (`strumenti/simula/finti`). Scelte di Claude: LuaSocket invece di un server finto dentro il client (prova il protocollo vero, nessun codice di prova nel gioco oltre al trasporto); giocatori finti in Go come quelli della prova di carico. Scartati: un client Python (dipendenza in più), bot nel server (il bot del thread dedicato non è ancora su main). | questa PR |
| 29 ott | **Bot** (Sergio: "vai, butta giù tutto"): euristico in `client/sim/bot.lua`, preme gli stessi tasti di un giocatore; prova le mosse su copie della partita con la fisica vera (`game:advance`, esplosioni senza cratere) e sceglie quella che vale più punti partita; pensa a pezzi con un tetto di lavoro per tick (~4 ms per tick senza JIT, 400 unità). Livelli facile/normale/difficile. Uguale su server e telefono (test `server/bot_test.go`). | PR del bot |
| 29 ott | **Ricette e impronte** (`client/sim/replay.lua`): seme, mappa, giocatori (livello dei bot), tasti dei giocatori veri solo quando cambiano, impronta dello stato (`game:impronta`) ogni 10 s e alla fine. Rigiocando devono tornare tutte: base per replay, validazione delle partite e video degli highlight. Sergio: "deve essere possibile ricostruire in maniera deterministica una partita, e validata". | PR del bot |
| 29 ott | **Arena dei bot** (`strumenti/arena/`): partite senza grafica, un processo luajit per core (~12.000 partite all'ora su 4 core), rapporto per il bilanciamento, highlight per rarità e spettacolo, video rigiocati nel simulatore. Le serie lunghe girano sul PC di Sergio. | PR del bot |
| 29 ott | **Bot con rete neurale che imparano da soli** (Sergio: "vorrei che si evolvessero, che imparassero il gioco da soli"): la rete (`client/sim/rete.lua`, solo somme, prodotti e ReLU, uguale su LuaJIT e gopher-lua) giudica ogni mossa che il bot prova guardando 20 caratteristiche della posizione che ne esce; il bot resta quello che preme i tasti, quindi non bara. `strumenti/arena/evolvi.py` le fa evolvere da pesi a caso, senza fine, col bot euristico come riferimento fisso, campioni passati come avversari ed esami ogni 5 generazioni. Tutti i bot, finiti gli attacchi, si riparano (a piedi o col Rampino) (Claude). | PR del bot |
| 29 ott | **Apprendimento a gradiente** (Sergio: "perché non metti in piedi anche l'apprendimento a gradiente... facciamo partire una bella larga scala sul mio computer"): `strumenti/arena/impara.py` fa imparare alla rete quanto rende una posizione (da ogni fine turno a fine partita), giro dopo giro sulle partite che gioca, con numpy; corsa lunga sul PC di Sergio. Rete e strumenti restano fuori dal gioco, che usa il bot euristico. | PR del bot |
| 29 ott | **Gradiente, seconda corsa** (Claude): la prima corsa sul PC sale dal 28% al 42-47% all'esame contro il bot euristico e lì si ferma (oscilla 35-47%). L'obiettivo diventa il ritorno a passi TD(λ = 0,7) invece dell'esito a fine partita (troppo rumoroso: varianza spiegata ferma a 0,26), rete 64-32 (3457 pesi), memoria di 5 giri, esame su 480 partite, normalizzazione con deviazione minima 0,1 (le morti dei compagni davano pesi da -5000) e la rete migliore tenuta in `migliore.json`. Riparte da zero con il punteggio di main. | PR del bot 2 |
| 29 ott | **Dalle reti al bot del gioco** (Sergio: fermare la corsa e passare le lezioni al bot euristico, valutando il gioco nuovo): la seconda corsa si ferma fra 39% e 46% (la migliore è del giro 4). Sul gioco nuovo (vita 100, danni 5/3, Mantice, globi a soglie) quella rete batte il bot di prima (53%) perché si teletrasporta molto di più. Nel bot: soglia del teletrasporto da 20 a 100 (72% contro il bot di prima, provato a coppie di partite uguali), il riparo col globo quando vale almeno 3 più di quello a piedi (76%), caratteri codardo 225 e cecchino 25 (stesse proporzioni). Scartati: meno paura di morire (54%, niente in più), il Baratto del secondo attacco (70%, peggio che senza), la rete come correzione del bot (dal 56% al 25-38%). | PR del bot 3 |
| 29 ott | **Generazioni del bot del gioco, per stili** (Sergio: "fai addestrare altri bot di altre generazioni [...] tutta la notte, se ti trovi in uno stallo prendi decisioni autonome per aumentare varianza"): `evolvi.py` non fa più evolvere reti ma i numeri del bot del gioco (paure, voglia di globo, di vuoto, di uccidere, di danno), che passano nel gioco così come sono. Due obiettivi: battere il bot di oggi sulle stesse partite (esame ogni 3 generazioni, 600 partite) e un campione per stile (quanto butta nel vuoto per quanto si sposta), che dà metà dei genitori e gioca da avversario. Stallo (4 esami senza migliorare): a giro più mutazione, metà popolazione a caso, tutti gli stili e più partite; ogni scelta scritta nel rapporto. Si rifà con `--nuova` a ogni cambio di regole. Scartate: reti con due mosse di anticipo (circa 10 volte più lente, stesso rischio di fermarsi), un'altra corsa delle reti (due corse ferme sotto il 50%). **Trovate dei bot** (Sergio: "voglio delle preview di cosa si inventano di nuovo per fare punti"): `trovate.py` sceglie i turni rari che fanno tanti punti (punti per rarità della combinazione, tutte diverse) e ne fa una pagina di video. Prima notte (30 ott, 25 generazioni): esami fermi al 42-47%, il primo di ogni generazione era quasi sempre un fortunato (150-200 partite a testa); scelta di Claude: chi resta somma le partite e si giudica con la stima tirata verso 0,5. | `strumenti/arena/evolvi.py`, `strumenti/arena/trovate.py`, questa PR |
| 29 ott | Roadmap: VPS europeo + SQLite + Litestream + Caddy; account ospite; pannello servito dal Go; GitHub Actions per i test; deploy a script; build anche browser dal nostro server. | docs/roadmap.md |
| 29 ott | **APK su Telegram in automatico**: GitHub Actions costruisce l'APK a ogni push su main (con l'online, firmato con la chiave di Sergio dai segreti del repository) e il bot @ultrablastbot lo manda a Sergio (Claude). | .github/workflows/apk.yml, docs/setup.md |
| 29 ott | **Motore Android snello** (Sergio: "ottimizzare senza rinunciare a qualità"): `client/megablast.appmanifest` toglie fisica 2D/3D, Vulkan (resta OpenGL ES), registratore, profiler, particellari, tilemap, image.load e live update; la UI (`/ui/**`) senza mipmap. Grafica e suoni identici (Claude). | client/megablast.appmanifest |

## Scartate

- Una goroutine e un ticker per stanza (1000 timer), pool di stati Lua
  (inutile sotto 1 ms) — 23 ott.
- Nakama, Firebase, Supabase come backend: raddoppierebbero il server (19 ott,
  confermato 29 ott).
- Pagine GitHub per la build web: repo privato richiede piano a pagamento
  (24 ott). Azione GitHub per le build automatiche: nessun host raggiungibile.
- LuaJIT via cgo sul server: leva futura, non ora.
- Bot: copiare la partita intera per una ricerca ad albero (MCTS) a ogni mossa
  (troppo per i telefoni deboli), rete neurale come bot del gioco (resta
  esperimento del Laboratorio bot e livello "assurdo"), bot che legge il caso
  o le casse (barerebbe), bot solo sul server (offline non ci sarebbe), cammini
  A* su tutta la griglia (bastano i passi provati con la fisica vera), librerie
  di behavior tree/GOAP (pesano più del bot) — 29 ott.
- Rete neurale che preme i tasti tick per tick (dalla grafica o dallo stato
  all'input): impara troppo lentamente per le partite che possiamo giocare e
  sul telefono costerebbe a ogni tick (Claude) — 29 ott.
- PyTorch per l'apprendimento a gradiente: installazione pesante e GPU inutile
  per una rete di un migliaio di pesi; basta numpy (Claude) — 29 ott.
- Tetto di lavoro del bot a tempo (millisecondi): non deterministico, client e
  server sceglierebbero mosse diverse; si conta il lavoro — 29 ott.
- Kubernetes, piattaforme gestite, cloud gratuito (29 ott).
- APK costruito nella sessione cloud: il build server di Defold non si
  raggiunge, quindi niente online, e la chiave è diversa da quella del PC.
  APK costruito e mandato dal PC col controllo remoto: va acceso il PC e il
  token di Telegram finirebbe nelle istruzioni della sessione (Claude) — 29 ott.
- Texture delle mappe compresse per la GPU (ASTC/ETC2): 4 volte meno memoria
  ma rischio di sbavature visibili sul terreno dipinto; restano RGBA. Togliere
  il suono wav o ogg: wav lo usa il punto, ogg servirà per l'audio base
  (Claude) — 29 ott.

## Aperte

- Secondo nodo e matchmaker centrale: solo quando i numeri lo chiedono.
- Codex lanciato da Claude via controllo remoto: Sergio deve installarlo e
  fare il login una volta.
