# MegaBlast

Repository in italiano (commenti, documenti, messaggi di commit).

## Prima di consegnare una modifica al client

Simula il gioco e guarda le foto prima di aprire o aggiornare una PR che tocca `client/`:

```bash
python3 strumenti/simula/simula.py
```

Deve finire con `OK`. Poi guarda `simulazione/foto/riepilogo.png` (e le foto
singole se serve) per controllare che quello che hai cambiato si veda davvero.
Per provare una funzione nuova scrivi uno scenario in `strumenti/simula/scenari/`.
Dettagli e comandi degli scenari: [strumenti/simula/README.md](strumenti/simula/README.md).

`simula.py` ripete anche i controlli che fa l'editor di Defold ma `bob.jar` no
(`strumenti/simula/controlla.py`). Se Sergio vede nell'editor un errore che la
simulazione non ha trovato, aggiungi lì la regola.

Le scelte di game design (tempo del turno, strategia, equipaggiamento,
ricompense) partono da [docs/game_design_competitivo.md](docs/game_design_competitivo.md):
leggilo prima di proporre o cambiare una meccanica.

Per progettare, valutare, bilanciare e implementare meccaniche ci sono le skill
in [.claude/skills/](.claude/skills/README.md).

Il server usa un terreno suo in Go (`server/terreno.go`) per le funzioni di
`client/sim/terrain.lua` che toccano le celle: `new`, `get`, `set`, `solid`,
`any_solid`, `carve`, `ground_below`, `surface_y`. Se ne cambi una in Lua,
cambiala anche in Go: `go test ./server/` le confronta e fallisce se
divergono. Le funzioni nuove scritte in Lua con `get`/`set`/`t.data` vanno sul
server senza toccare il Go.

## Provare il gioco su iPhone

Su iPhone si prova la build HTML5 in Safari: `bash strumenti/web/build.sh` prepara
`simulazione/web/`, che si pubblica come Artifact di claude.ai (pagina
`megablast.html`, gli altri file come `files`) sempre allo stesso indirizzo:
https://claude.ai/artifact/WeHdWjA9HzabJJpfKKhH5G . Senza l'estensione WebSocket:
l'online usa la WebSocket del browser (`client/main/ws_browser.lua`), ma dalla pagina
su claude.ai le connessioni verso altri siti sono bloccate.

Altri test: `luajit tests/sim_test.lua` (simulazione), `luajit tests/battaglia_test.lua` (personaggio e camera),
`go test ./server/` (server).


## Lavorare con ChatGPT

ChatGPT (anche come Codex) fa immagini e contenuti, Claude li integra: si passano il lavoro
solo con le schede in [docs/handoff/](docs/handoff/README.md) e i commit di ChatGPT sui rami
`design/...` o `codex/...` (regole sue in [AGENTS.md](AGENTS.md), decisioni in [DECISIONI.md](DECISIONI.md)).
Quando Sergio dice di leggere una scheda: `git fetch origin` e cerca la scheda anche sui rami
`design/...` e `codex/...`; controllala sul codice vero e presenta il piano prima di scrivere codice; poi
integra, gira la simulazione, metti le foto in `docs/handoff/img/` e scrivi il "Resoconto di
Claude" sotto (cosa hai verificato e cosa no), senza cancellare niente. `DECISIONI.md` si
cambia solo su ordine di Sergio. Se una richiesta di ChatGPT non si può fare, scrivilo nella
scheda e non cambiarla di nascosto.
