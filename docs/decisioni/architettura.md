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
| 29 ott | Roadmap: VPS europeo + SQLite + Litestream + Caddy; account ospite; pannello servito dal Go; GitHub Actions per i test; deploy a script; build anche browser dal nostro server. | docs/roadmap.md |

## Scartate

- Una goroutine e un ticker per stanza (1000 timer), pool di stati Lua
  (inutile sotto 1 ms) — 23 ott.
- Nakama, Firebase, Supabase come backend: raddoppierebbero il server (19 ott,
  confermato 29 ott).
- Pagine GitHub per la build web: repo privato richiede piano a pagamento
  (24 ott). Azione GitHub per le build automatiche: nessun host raggiungibile.
- LuaJIT via cgo sul server: leva futura, non ora.
- Kubernetes, piattaforme gestite, cloud gratuito (29 ott).

## Aperte

- Secondo nodo e matchmaker centrale: solo quando i numeri lo chiedono.
- Codex lanciato da Claude via controllo remoto: Sergio deve installarlo e
  fare il login una volta.
