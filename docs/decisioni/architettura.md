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
| 29 ott | **Bot** (Sergio: "vai, butta giù tutto"): euristico in `client/sim/bot.lua`, preme gli stessi tasti di un giocatore; prova le mosse su copie della partita con la fisica vera (`game:advance`, esplosioni senza cratere) e sceglie quella che vale più punti partita; pensa a pezzi con un tetto di lavoro per tick (~4 ms per tick senza JIT, 400 unità). Livelli facile/normale/difficile. Uguale su server e telefono (test `server/bot_test.go`). | PR del bot |
| 29 ott | **Ricette e impronte** (`client/sim/replay.lua`): seme, mappa, giocatori (livello dei bot), tasti dei giocatori veri solo quando cambiano, impronta dello stato (`game:impronta`) ogni 10 s e alla fine. Rigiocando devono tornare tutte: base per replay, validazione delle partite e video degli highlight. Sergio: "deve essere possibile ricostruire in maniera deterministica una partita, e validata". | PR del bot |
| 29 ott | **Arena dei bot** (`strumenti/arena/`): partite senza grafica, un processo luajit per core (~12.000 partite all'ora su 4 core), rapporto per il bilanciamento, highlight per rarità e spettacolo, video rigiocati nel simulatore. Le serie lunghe girano sul PC di Sergio. | PR del bot |
| 29 ott | **Bot con rete neurale che imparano da soli** (Sergio: "vorrei che si evolvessero, che imparassero il gioco da soli"): la rete (`client/sim/rete.lua`, solo somme, prodotti e ReLU, uguale su LuaJIT e gopher-lua) giudica ogni mossa che il bot prova guardando 20 caratteristiche della posizione che ne esce; il bot resta quello che preme i tasti, quindi non bara. `strumenti/arena/evolvi.py` le fa evolvere da pesi a caso, senza fine, col bot euristico come riferimento fisso, campioni passati come avversari ed esami ogni 5 generazioni. Tutti i bot, finiti gli attacchi, si riparano (a piedi o col Rampino) (Claude). | PR del bot |
| 29 ott | Roadmap: VPS europeo + SQLite + Litestream + Caddy; account ospite; pannello servito dal Go; GitHub Actions per i test; deploy a script; build anche browser dal nostro server. | docs/roadmap.md |

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
  sul telefono costerebbe a ogni tick. Apprendimento a gradiente (PyTorch, RL)
  per ora: l'evoluzione non chiede librerie né derivate, gira con luajit su
  tutti i core e la rete esce già in Lua (Claude) — 29 ott.
- Tetto di lavoro del bot a tempo (millisecondi): non deterministico, client e
  server sceglierebbero mosse diverse; si conta il lavoro — 29 ott.
- Kubernetes, piattaforme gestite, cloud gratuito (29 ott).

## Aperte

- Secondo nodo e matchmaker centrale: solo quando i numeri lo chiedono.
- Codex lanciato da Claude via controllo remoto: Sergio deve installarlo e
  fare il login una volta.
