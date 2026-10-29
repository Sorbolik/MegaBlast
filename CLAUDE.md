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

Niente si deve mai deformare (Sergio, 29 ott): ogni nodo GUI è `gui.ADJUST_FIT`, mai
`ADJUST_STRETCH` (lo controlla `controlla.py`). Il gioco è disegnato a 1280 x 720 al
centro; su 20:9 o 4:3 lo schermo vero va da `schermo.x0` a `x1` e da `y0` a `y1`
(`client/ui/schermo.lua`), e quello che sta su un bordo si attacca lì. Se tocchi
l'HUD o i menu prova anche `--schermo 1600x720` e `--schermo 960x720` (scenario `schermo.txt`).

Le estensioni native del client (cartelle con `ext.manifest`, per ora `client/vibra`:
la micro-vibrazione) si compilano solo sul build server di Defold: simulazione e build
web nel cloud compilano una copia del client senza (`strumenti/simula/senza_estensioni.py`),
e la build di prova dell'APK su ogni PR (`.github/workflows/build-pr.yml`) dice se compilano.

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

## Server sempre in pari con main (Sergio, 29 ott)

Il server deve essere **sempre** in pari con quello che va su `main`: ogni PR che
cambia regole, simulazione (`client/sim/`) o protocollo aggiorna anche il server
**nella stessa PR**. La simulazione il server la incorpora da sola, ma non basta:
controlla ogni volta la lista in [docs/server.md](docs/server.md#server-in-pari-con-main)
(campi nuovi in `server/net.lua`, messaggi in `server/room.go`, dati che il client
manda solo in locale, test in `server/server_test.go`) e prova l'online nel
simulatore (`strumenti/simula/scenari/scelta_online.txt`, server vero e giocatori finti).

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
perni di testa, braccia, gambe e ala (`client/battaglia/perni.lua`) e le
impugnature di ogni arma: presa (dove la tiene chi la impugna), perno (dove gira) e spalla
(dove sta il perno nel corpo) in `client/battaglia/impugnature.lua`. Ogni clip sceglie chi
impugna l'arma (`impugna`) e l'ordine dei pezzi davanti e dietro (`livelli`).
"Manda a Claude" li mette nei documenti `corpo/ultima`, `perni/ultima` e
`impugnature/ultima` (campo `lua`). Una clip con l'arma può avere la versione di
una sola arma (`fermo_arma_mallet`): il gioco la preferisce a quella di tutte.

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
`luajit tests/bot_test.lua` (bot e ricette), `luajit tests/campagna_test.lua` (missioni della campagna e partita guidata), `luajit strumenti/arena/collaudo.lua` (i bot giocano le missioni dei gironi), `go test ./server/` (server).

## Sezione "Per Telegram" in ogni PR (Sergio, 29 ott)

A ogni push su main GitHub Actions manda a Sergio l'APK su Telegram con un
messaggio sulle novità (`strumenti/apk/novita.py`). Per ogni PR il messaggio
prende la sezione `## Per Telegram` del corpo: **scrivila sempre**, 2-4 righe in
italiano semplice per una persona, non per un programmatore: cosa cambia nel
gioco, cosa si vede, cosa provare sul telefono. Niente nomi di file o funzioni.
Se la PR non tocca il gioco, dillo in una riga (per esempio "Solo strumenti:
nel gioco non cambia niente").

## Bot e arena

Il bot (`client/sim/bot.lua`) preme gli stessi tasti di un giocatore e pensa
provando le mosse su copie della partita (`bot.mondo`, `game:advance`): se
cambi la fisica il bot la segue da solo. Deve restare deterministico e uguale
su LuaJIT e gopher-lua (`go test ./server/ -run TestBot`): niente tempo vero,
niente `pairs` dove conta l'ordine, `table.sort` sempre con lo spareggio.
Ogni partita ha la sua ricetta (`client/sim/replay.lua`) con le impronte dello
stato: rigiocandola devono tornare tutte. L'arena (`strumenti/arena/`, vedi il
README) fa giocare i bot tra loro su tutti i core e scrive il rapporto per il
bilanciamento e gli highlight.


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
