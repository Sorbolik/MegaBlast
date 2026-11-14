# MegaBlast

Documenti, CLAUDE.md, messaggi di commit e PR in italiano. Il codice (nomi di file,
funzioni, variabili e commenti) passa all'inglese a ondate (piano di Sergio, 2 nov):
già in inglese i nomi e i commenti di tutto `client/` e `server/` e dei loro test
(il bot con la PR 8: le chiavi dei pesi, `M.PESI`, e i campi che leggono gli strumenti
Python restano italiani, sono dati salvati dall'arena), e anche i file scritti
dagli strumenti o dall'editor (`body.lua`, `animations.lua`, `skins.lua`, `pivots.lua`,
`grips.lua`, `weapons.lua`, `devil.lua`, `paintings.lua`): i loro campi sono in inglese, ma
i nomi dei pezzi, dei posti, dei canali, delle clip e delle immagini restano italiani
(sono id, vanno con le immagini). L'editor delle animazioni dentro resta italiano e
traduce i campi quando legge e scrive i file.
Le cartelle del client sono in inglese (`client/battle/`, `client/paintings/`,
`client/assets/weapons/`, ...), e così i file di codice; i nomi delle immagini e dei
suoni restano italiani (sono id). Gli strumenti stanno in `tools/` (PR 7 della pulizia,
10 nov) ma dentro restano in italiano: nomi dei file, funzioni e commenti.
Un campo usato anche fuori dall'ondata o scritto come stringa (id, impostazioni, nodi
della GUI) resta italiano per ora. Nei file in
inglese si scrive in inglese; i testi del gioco e i messaggi che legge Sergio (log,
errori del server) restano in italiano. Si rinomina con `tools/rinomina/rinomina.py`.
Le frasi del gioco stanno in `client/lang/it.lua` (un gruppo per schermata, come si usano
in `client/lang/text.lua`; ci sono tutte quelle del client, fuori restano solo i testi della
simulazione: missioni, premi, campagna): una frase nuova va lì, non nel codice
(`tests/lang_test.lua` controlla le chiavi).

## Controlli: veloci in locale, completi su main (Sergio, 3 nov)

Sulle PR GitHub non fa più girare niente: lo sviluppo deve essere veloce. Prima
di aprire o aggiornare una PR è consigliato (non obbligatorio) il controllo
veloce in locale, circa un minuto:

```bash
bash tools/controlli/tutti.sh
```

Deve finire con `OK` (sintassi e globali del Lua, controlli dell'editor, tutti i
test Lua, le miniature delle missioni in pari con mappe e dipinti, `go vet`, `gofmt`, `go test ./server/`). Lo stesso controllo gira su
GitHub dopo ogni merge su `main` (`.github/workflows/controlli.yml`); prima di una
versione online si lancia a mano sul ramo (Actions > Controlli > Run workflow).
Se diventa rosso su main, il thread che ha mergiato lo sistema subito.
`/code-review` non è più obbligatorio: si usa sulle PR grandi o delicate.
Se una PR che cambia regole o simulazione (`client/sim/`) non deve cambiare il
gioco, dimostralo con `python3 tools/confronta/confronta.py` (200 partite di
bot e le missioni, identiche a main tick per tick) e scrivi il risultato nella PR;
per pulizie e rinomi fuori da `client/sim/` basta `tutti.sh`.

## Prima di consegnare una modifica al client

Se la PR cambia quello che si vede o le regole, simula il gioco e guarda le foto
prima di aprirla (per rinomi e pulizie che non cambiano niente sullo schermo non serve):

```bash
python3 tools/simula/simula.py
```

Deve finire con `OK`. Poi guarda `simulazione/foto/riepilogo.png` (e le foto
singole se serve) per controllare che quello che hai cambiato si veda davvero.
Per provare una funzione nuova scrivi uno scenario in `tools/simula/scenari/`.
La simulazione conta anche i frame (`simulazione/fotogrammi.txt`) e fallisce se Lua
tiene fermo un frame più di 150 ms (300 sotto l'iride): misure, contatore FPS nel gioco e regole in
[docs/prestazioni.md](docs/prestazioni.md).
Dettagli e comandi degli scenari: [tools/simula/README.md](tools/simula/README.md).

Niente si deve mai deformare (Sergio, 29 ott): ogni nodo GUI è `gui.ADJUST_FIT`, mai
`ADJUST_STRETCH` (lo controlla `controlla.py`). Il gioco è disegnato a 1280 x 720 al
centro; su 20:9 o 4:3 lo schermo vero va da `schermo.x0` a `x1` e da `y0` a `y1`
(`client/ui/screen.lua`), e quello che sta su un bordo si attacca lì. Se tocchi
l'HUD o i menu prova anche `--schermo 1600x720` e `--schermo 960x720` (scenario `schermo.txt`).

Le estensioni native del client (cartelle con `ext.manifest`, per ora `client/vibra`:
la micro-vibrazione) si compilano solo sul build server di Defold: simulazione e build
web nel cloud compilano una copia del client senza (`tools/simula/senza_estensioni.py`),
e la build di prova dell'APK (`.github/workflows/build-pr.yml`, da lanciare a mano sul
ramo da Actions quando si tocca un'estensione o il manifest del motore) dice se compilano.

`simula.py` ripete anche i controlli che fa l'editor di Defold ma `bob.jar` no
(`tools/simula/controlla.py`). Se Sergio vede nell'editor un errore che la
simulazione non ha trovato, aggiungi lì la regola.

Le scelte di game design (tempo del turno, strategia, equipaggiamento,
ricompense) partono da [docs/game_design_competitivo.md](docs/game_design_competitivo.md):
leggilo prima di proporre o cambiare una meccanica. Cosa si fa e in che ordine è
fissato in [docs/roadmap.md](docs/roadmap.md): consultalo prima di proporre lavoro nuovo.
Ogni impostazione che Sergio nomina (anche di passaggio) va subito in
[docs/impostazioni.md](docs/impostazioni.md), nella stessa PR: lì si raccolgono
tutte per quando si farà la schermata delle impostazioni.
La storia delle decisioni (prese, scartate, aperte) è in [docs/decisioni/](docs/decisioni/README.md):
leggi [regole.md](docs/decisioni/regole.md) e **solo il file dell'area che tocchi**; quando
decidi o scarti qualcosa, aggiorna quel file e `cronologia.md` nella stessa PR.

Per progettare, valutare, bilanciare e implementare meccaniche ci sono le skill
in [.claude/skills/](.claude/skills/README.md).

## Pericoli delle mappe

Le mappe dei gironi (Limbo, Lussuria, Gola, Avarizia, Ira, Eresia...) hanno un pericolo ciascuna, anche online:
gravità, fango, bufera, grandine, massi, acqua che sale, tombe. Si scrive come dati sulla mappa più `client/sim/hazards.lua`,
il server porta `hz` nello stato, il client lo disegna in `client/battle/hazards.lua`:
la ricetta per aggiungerne uno è in [docs/pericoli_mappe.md](docs/pericoli_mappe.md).

## Server sempre in pari con main (Sergio, 29 ott)

Il server deve essere **sempre** in pari con quello che va su `main`: ogni PR che
cambia regole, simulazione (`client/sim/`) o protocollo aggiorna anche il server
**nella stessa PR**. La simulazione il server la incorpora da sola, ma non basta:
controlla ogni volta la lista in [docs/server.md](docs/server.md#server-in-pari-con-main)
(campi nuovi in `server/net.lua`, messaggi in `server/room.go`, dati che il client
manda solo in locale, test in `server/server_test.go`) e prova l'online nel
simulatore (`tools/simula/scenari/scelta_online.txt`, server vero e giocatori finti).

Il server fa girare la simulazione in LuaJIT, come il telefono (9 nov): il Go tiene
connessioni, code e stanze, e ogni worker ha un processo `luajit` con le partite
delle sue stanze (`server/proc.go`, `server/worker.lua`). Serve `luajit` nel PATH
(o `-luajit PERCORSO`). Sul server le celle del terreno stanno in un array di byte
(FFI, `server/net.lua`): la simulazione deve leggere e scrivere `t.data[i]` solo
dentro la griglia (da 1 a `w * h`), come fa `client/sim/terrain.lua`.

## Animazioni del diavoletto

Le pose del diavoletto (fermo, corsa, aria, paracadute, colpito, vittoria,
sconfitta, scenette) sono clip in `client/battle/animations.lua`, campionate da
`client/battle/pose.lua` sotto le molle e la mira di `scoria.lua`. Si fanno con
l'editor `tools/animazioni/editor.html`: `python3 tools/animazioni/prepara.py`
scrive `simulazione/animazioni/editor.html` (pezzi e animazioni dentro), che si
apre nel browser e si pubblica come Artifact sempre allo stesso indirizzo:
https://claude.ai/artifact/YJeMenvfJLGmto89yAbKJ5 . Se cambiano i pezzi o le animazioni,
ripubblicalo. "Manda a Claude" nell'editor salva il file nel database
dell'Artifact (documento `animazioni/ultima`, campo `lua`): da lì va copiato in
`client/battle/animations.lua`.

Dallo stesso editor si cambiano le hitbox (`client/sim/body.lua`: la capsula per
camminare e il cerchio dei colpi; è fisica, cambia il gioco anche online) e i
perni di testa, braccia, gambe e ala (`client/battle/pivots.lua`) e le
impugnature di ogni arma: presa (`grip`, dove la tiene chi la impugna), perno (`pivot`,
dove gira) e spalla (`shoulder`, dove sta il perno nel corpo) in `client/battle/grips.lua`. Ogni clip sceglie chi
impugna l'arma (`held_by`) e l'ordine dei pezzi davanti e dietro (`layers`).
"Manda a Claude" li mette nei documenti `corpo/ultima`, `perni/ultima` e
`impugnature/ultima` (campo `lua`). Il "Manda a Claude" in alto manda tutto quello che è cambiato, anche i
ritocchi dei pezzi (`ritocchi/ultima`) e il mantello: se il gioco non è uguale all'editor,
guarda prima `ritocchi/ultima`. Una clip con l'arma può avere la versione di
una sola arma (`fermo_arma_mallet`): il gioco la preferisce a quella di tutte.
Nel pannello Mantello dell'editor Sergio tara dal vivo il mantello (peso, aria, piega, angoli,
spinte, grandezza, attacco: la stessa catena e lo stesso shader del gioco); "Manda a Claude"
scrive il documento `mantello/ultima` (campo `lua`), da copiare in `client/battle/cape_tuning.lua`.

Nella sezione Strumenti dell'editor Sergio manda anche: le richieste di pezzi o
personaggi nuovi (immagine e note; su claude.ai documento `richieste/<nome>` con
l'immagine fra gli asset dell'Artifact, su Cloudflare `richieste/<nome>.json` e
`.png` nel ramo `editor-ultima`): da lì Claude scrive la scheda per Codex in
`docs/handoff/`. E i ritocchi ai pezzi dello stampino (documento `ritocchi/ultima`
o `tools/stampino/ritocchi.json`): si applicano con
`python3 tools/stampino/taglia.py --ritocchi FILE`.

L'editor è anche su Cloudflare (Worker `megablast`, repository collegato: a ogni
push su main lo ricostruisce con `tools/animazioni/cloudflare/costruisci.sh`
e `wrangler.jsonc`). Da lì "Manda a Claude" (`worker.js`) scrive i file nel ramo
`editor-ultima` di GitHub: si prendono da lì.

## Pannello degli eventi

Sergio programma gli eventi dal pannello su Cloudflare (Worker `megablast-eventi`,
`tools/eventi`, vedi il README): modelli, calendario, versioni. Il server lo
scarica con `-eventi https://…/eventi.json`. Se cambiano armi, punti o regole
degli eventi, rifai `luajit tools/eventi/dati.lua` (`go test ./server/` lo
controlla); `node tools/eventi/prova.mjs` prova pagina e Worker.

## Copione dei livelli (Sergio, 6 nov)

Lo script di ogni livello della campagna (mappa o arena, spawn, passi dell'obiettivo,
righe e vignette coi loro trigger, casse, carte, Favilla) sta solo come dati in
`client/sim/levels.lua`; i capitoli in `client/sim/campaign.lua`. Niente funzioni nei
livelli: i trigger sono i verbi di `client/sim/missions.lua` (un verbo nuovo va lì e in
`tools/copione/controlla.lua`, che gira in `tutti.sh`). È la base del Copione, la
dashboard della campagna (`tools/copione/`, README): `python3 tools/copione/prepara.py --gioco`
scrive `simulazione/copione/`, che si pubblica come Artifact sempre allo stesso indirizzo
(https://claude.ai/artifact/D4mVBtXrXMEzpghAb8Sukv , i file di `game/` come `files`, capacità `db`):
ripubblicalo quando cambiano livelli, mappe, verbi o la build. "Manda a Claude" scrive il
documento `copione/ultima` (campo `lua`: tutto `client/sim/levels.lua`). È anche su Cloudflare
(Worker `megablast-copione`, repository collegato al ramo `copione-pubblica`, che
`.github/workflows/copione.yml` riscrive già costruito dopo ogni merge su main): da lì "Manda a Claude" scrive `client/sim/levels.lua` e `copione/ultima.json` nel ramo
`editor-ultima`. Il formato è in
[docs/copione.md](docs/copione.md).

## Vignette

Le righe di chi ti guida (Favilla nel cortile, il Fabbro nei gironi) parlano nella
striscia in alto, sotto il punteggio, col ritratto; le battute di tutti i bot sono
testo semplice sopra la loro testa (`targa.battuta`, Sergio, 4 nov). Quello che
spiega un comando ferma il gioco, ogni volta, sulla vignetta grande col disegno della mossa
e va avanti solo col suo pulsante
(`client/battle/vignette.lua`, piano dei livelli
https://claude.ai/artifact/12CRugbQCR2oB32LHt6aS2). I ritratti si ritagliano dai
fogli scelti di WB-012 con `python3 tools/ritratti/taglia.py`. Scenario
`vignette.txt` (tutti i disegni); gli scenari che provano altro hanno
`imposta prova_vignette no`.
Nel cortile Favilla è una comparsa su un percorso fisso (`guida` della lezione in
`client/sim/levels.lua`, disegnata da `client/battle/favilla.lua`), non un robot: non
cambia la simulazione. Per mostrare una mossa facendola (poi la fai tu) Favilla è invece un
giocatore vero con `insegna = true` e le sue `dimostra` (cammina, salta, arma con angolo e
forza, aspetta, dice, posa): dopo il VAI della vignetta grande il turno passa a lei e torna a te; passa
attraverso gli altri robot. Ogni mossa nuova (`nuova = true` sul passo) ha i quattro tempi, spiega, mostra,
tocca a te, bravo: li controlla `controlla.lua` (docs/copione.md, scenario
`favilla_mostra.txt`). Medaglie facoltative: `medaglia = { conta, at_least | at_most, testo }`.

## Pezzi nuovi del diavoletto (pelli)

Teste, corazze, maglie, ali, elmi o un personaggio intero si disegnano sullo
stampino e si tagliano con `tools/stampino/taglia.py`: regole e comandi in
[tools/stampino/README.md](tools/stampino/README.md). Il gioco li monta
con `scoria.new(colore, look)` (`client/battle/skins.lua`, generato).

## Controller

Il gioco si usa anche col controller (Bluetooth o USB): mappatura di Sergio e
come funziona in [docs/controller.md](docs/controller.md). Cosa fa ogni tasto
in battaglia di base sta solo in `controller.BATTLE` (`client/ui/controller.lua`;
ognuno la cambia nelle IMPOSTAZIONI della home); un comando nuovo dell'HUD va
aggiunto anche lì, in `controller.COMMANDS`, in `PAD.COMMANDS` e, se ha un pulsante, in `PAD.GLYPHS`
(dove si vede il suo tasto sull'HUD, `client/main/game.gui_script`). Una
schermata nuova con `ui.touch` ha già la luce del controller. Si prova col
controller finto: scenari `tools/simula/scenari/controller.txt` e
`impostazioni.txt` (con `imposta prova_pad playstation` o `nintendo`).

## Provare il gioco su iPhone

Su iPhone si prova la build HTML5 in Safari: `bash tools/web/build.sh` prepara
`simulazione/web/`, che si pubblica come Artifact di claude.ai (pagina
`megablast.html`, gli altri file come `files`) sempre allo stesso indirizzo:
https://claude.ai/artifact/WeHdWjA9HzabJJpfKKhH5G . Senza l'estensione WebSocket:
l'online usa la WebSocket del browser (`client/main/ws_browser.lua`), ma dalla pagina
su claude.ai le connessioni verso altri siti sono bloccate.

I test (tutti insieme in `tools/controlli/tutti.sh`): `luajit tests/sim_test.lua` (simulazione), `luajit tests/battaglia_test.lua` (personaggio e camera),
`luajit tests/bot_test.lua` (bot e ricette), `luajit tests/campaign_test.lua` (missioni della campagna e partita guidata), `luajit tests/events_test.lua` (eventi nel gioco), `luajit tests/hazards_test.lua` (pericoli delle mappe dei gironi), `luajit tests/scheda_test.lua` (scheda personaggio: badge, statistiche, cartellini, replay), `luajit tests/lang_test.lua` (testi del gioco), `luajit tools/arena/collaudo.lua` (i bot giocano le missioni dei gironi), `go test ./server/` (server).

## Sezione "Per Telegram" in ogni PR (Sergio, 29 ott)

A ogni push su main GitHub Actions manda a Sergio l'APK su Telegram con un
messaggio sulle novità (`tools/apk/novita.py`). Per ogni PR il messaggio
prende la sezione `## Per Telegram` del corpo: **scrivila sempre**, 2-4 righe in
italiano semplice per una persona, non per un programmatore: cosa cambia nel
gioco, cosa si vede, cosa provare sul telefono. Niente nomi di file o funzioni.
Se la PR non tocca il gioco, dillo in una riga (per esempio "Solo strumenti:
nel gioco non cambia niente").

## Bot e arena

Il bot (`client/sim/bot.lua`) preme gli stessi tasti di un giocatore e pensa
provando le mosse su copie della partita (`bot.world`, `game:advance`): se
cambi la fisica il bot la segue da solo. Deve restare deterministico: niente tempo vero,
niente `pairs` dove conta l'ordine, `table.sort` sempre con lo spareggio.
Ogni partita ha la sua ricetta (`client/sim/replay.lua`) con le impronte dello
stato: rigiocandola devono tornare tutte. L'arena (`tools/arena/`, vedi il
README) fa giocare i bot tra loro su tutti i core e scrive il rapporto per il
bilanciamento e gli highlight.
`tools/arena/evolvi.py` fa evolvere i numeri di cinque bot specialisti (sul PC di Sergio, di
notte; da rifare con `--nuova` quando cambiano le regole) e `tools/arena/trovate.py` fa la
pagina coi video delle trovate dei bot (i turni rari che fanno tanti punti).

Stelle della campagna: dopo ogni merge su main che tocca `client/sim/` il controllo "Stelle
della campagna" (`.github/workflows/stelle.yml`) rigioca le missioni coi bot (`collaudo.lua
--vita 0.5,1,2`) e mette un avviso per ogni stella da guardare; su un ramo si lancia a mano
da Actions, o in locale con `luajit tools/arena/collaudo.lua 12 --vita 0.5,1,2`. Se ci
sono avvisi nuovi, ritara le soglie in `client/sim/levels.lua` (nella stessa PR se l'hai
lanciato prima, se no in una PR subito dopo).


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
