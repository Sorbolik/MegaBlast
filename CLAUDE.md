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
leggilo prima di proporre o cambiare una meccanica. Cosa si fa e in che ordine è
fissato in [docs/roadmap.md](docs/roadmap.md): consultalo prima di proporre lavoro nuovo.
La storia delle decisioni (prese, scartate, aperte) è in [docs/decisioni/](docs/decisioni/README.md):
leggi [regole.md](docs/decisioni/regole.md) e **solo il file dell'area che tocchi**; quando
decidi o scarti qualcosa, aggiorna quel file e `cronologia.md` nella stessa PR.

Per progettare, valutare, bilanciare e implementare meccaniche ci sono le skill
in [.claude/skills/](.claude/skills/README.md).

Il server usa un terreno suo in Go (`server/terreno.go`) per le funzioni di
`client/sim/terrain.lua` che toccano le celle: `new`, `get`, `set`, `solid`,
`any_solid`, `carve`, `ground_below`, `surface_y`. Se ne cambi una in Lua,
cambiala anche in Go: `go test ./server/` le confronta e fallisce se
divergono. Le funzioni nuove scritte in Lua con `get`/`set`/`t.data` vanno sul
server senza toccare il Go.

## Animazioni del diavoletto

Le pose del diavoletto (fermo, corsa, aria, paracadute, colpito, vittoria,
sconfitta, scenette) sono clip in `client/battaglia/animazioni.lua`, campionate da
`client/battaglia/pose.lua` sotto le molle e la mira di `scoria.lua`. Si fanno con
l'editor `strumenti/animazioni/editor.html`: `python3 strumenti/animazioni/prepara.py`
scrive `simulazione/animazioni/editor.html` (pezzi e animazioni dentro), che si
apre nel browser e si pubblica come Artifact sempre allo stesso indirizzo:
https://claude.ai/artifact/YJeMenvfJLGmto89yAbKJ5 . Se cambiano i pezzi o le animazioni,
ripubblicalo. "Manda a Claude" nell'editor salva il file nel database
dell'Artifact (documento `animazioni/ultima`, campo `lua`): da lì va copiato in
`client/battaglia/animazioni.lua`.

Dallo stesso editor si cambiano le hitbox (`client/sim/corpo.lua`: la capsula per
camminare e il cerchio dei colpi; è fisica, cambia il gioco anche online) e i
perni di testa, braccia, gambe e ala (`client/battaglia/perni.lua`). "Manda a
Claude" li mette nei documenti `corpo/ultima` e `perni/ultima` (campo `lua`).

Nella sezione Strumenti dell'editor Sergio manda anche: le richieste di pezzi o
personaggi nuovi (immagine e note; su claude.ai documento `richieste/<nome>` con
l'immagine fra gli asset dell'Artifact, su Cloudflare `richieste/<nome>.json` e
`.png` nel ramo `editor-ultima`): da lì Claude scrive la scheda per Codex in
`docs/handoff/`. E i ritocchi ai pezzi dello stampino (documento `ritocchi/ultima`
o `strumenti/stampino/ritocchi.json`): si applicano con
`python3 strumenti/stampino/taglia.py --ritocchi FILE`.

L'editor è anche su Cloudflare (Worker `megablast`, repository collegato: a ogni
push su main lo ricostruisce con `strumenti/animazioni/cloudflare/costruisci.sh`
e `wrangler.jsonc`). Da lì "Manda a Claude" (`worker.js`) scrive i file nel ramo
`editor-ultima` di GitHub: si prendono da lì.

## Pezzi nuovi del diavoletto (pelli)

Teste, corazze, maglie, ali, elmi o un personaggio intero si disegnano sullo
stampino e si tagliano con `strumenti/stampino/taglia.py`: regole e comandi in
[strumenti/stampino/README.md](strumenti/stampino/README.md). Il gioco li monta
con `scoria.new(colore, look)` (`client/battaglia/pelli.lua`, generato).

## Provare il gioco su iPhone

Su iPhone si prova la build HTML5 in Safari: `bash strumenti/web/build.sh` prepara
`simulazione/web/`, che si pubblica come Artifact di claude.ai (pagina
`megablast.html`, gli altri file come `files`) sempre allo stesso indirizzo:
https://claude.ai/artifact/WeHdWjA9HzabJJpfKKhH5G . Senza l'estensione WebSocket:
l'online usa la WebSocket del browser (`client/main/ws_browser.lua`), ma dalla pagina
su claude.ai le connessioni verso altri siti sono bloccate.

Altri test: `luajit tests/sim_test.lua` (simulazione), `luajit tests/battaglia_test.lua` (personaggio e camera),
`go test ./server/` (server).


## Immagini con ChatGPT (Codex)

Le immagini le genera Codex (ChatGPT) sul PC di Sergio, dai prompt che scrive Claude: niente
copia e incolla. Claude scrive una scheda in [docs/handoff/](docs/handoff/README.md) dal
[modello](docs/handoff/MODELLO.md), con ogni prompt completo, i riferimenti e i nomi dei file;
la approva se è reversibile (altrimenti chiede a Sergio) e la porta su `main` (solo
documenti e riferimenti, così Codex la trova). Codex la esegue
seguendo [AGENTS.md](AGENTS.md) e fa il push sul ramo `design/WB-xxx`. Poi Claude fa
`git fetch origin`, guarda ogni immagine in `art/WB-xxx/`, scarta quelle con difetti visibili,
integra le buone, gira la simulazione e scrive il "Resoconto di Claude". Le decisioni prese da
Claude in autonomia vanno in [DECISIONI.md](DECISIONI.md) con "(Claude)".
