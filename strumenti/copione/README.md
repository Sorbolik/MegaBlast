# Il Copione

Il formato dei livelli è in [docs/copione.md](../../docs/copione.md).

La dashboard della campagna (Sergio, 6 nov 2026; proposta
https://claude.ai/artifact/2EPgEANUbEMLYJhG2iaGBi): tutti i capitoli e i loro
livelli, e per ogni livello un editor grafico (mappa da scorrere, spawn,
piattaforme, casse e trigger da trascinare, vignette agganciate ai trigger),
GIOCA per provarlo nella build web e "Manda a Claude".

Si fa in tre PR:

1. **Livelli come dati** (fatta): `client/sim/levels.lua` contiene solo dati, i
   trigger sono i verbi di `client/sim/missions.lua` e la vignetta grande si
   scrive nella riga (`mostra = "grande"`). Il controllo:

   ```bash
   luajit strumenti/copione/controlla.lua
   ```

   Gira in `strumenti/controlli/tutti.sh`: niente funzioni, passi, eventi, armi,
   comandi, facce e segnaposto che esistono, disegno per ogni vignetta grande,
   punti dentro la mappa.
2. **La pagina** (fatta): https://claude.ai/artifact/D4mVBtXrXMEzpghAb8Sukv ,
   sempre allo stesso indirizzo. Cruscotto dei capitoli (carte dei livelli con
   tipo, passi, vignette grandi, righe e problemi; sposta, duplica, elimina,
   nuovo), editor del livello (mappa da scorrere e ingrandire, piattaforme,
   giocatori, passi, casse, Favilla e scintilla da trascinare; colonne del tempo
   con le righe agganciate ai passi; ispettore con l'anteprima della vignetta),
   annulla e rifai, la bozza resta nel browser. Tutto quello che si legge è in italiano
   (gli id del gioco, come gli eventi `crate_pick`, hanno il loro nome in `NOMI_EVENTI`
   e vicini in `pagina.html`: un evento o un comando nuovo va anche lì), con «Come si usa»
   e la legenda in cima al pannello. I passi si inseriscono anche in mezzo («+ passo
   nuovo» nella sequenza, o prima/dopo quello scelto): frasi, casse, carte e Favilla
   legate ai passi si rinumerano da sole (`rinumera`). Si rifà e si ripubblica così:

   ```bash
   python3 strumenti/copione/prepara.py --gioco
   ```

   poi si pubblica `simulazione/copione/index.html` all'indirizzo di sopra con
   i file di `simulazione/copione/game/` (come `game/...`) e la capacità `db`.
   - **GIOCA** apre `game/megablast.html?copione=1#<il livello in Lua>` in un
     riquadro: il gioco (`CP.copione` in `client/main/game.gui_script`) legge il
     livello e lo fa partire con `missions.prova`. Se l'arena è cambiata il
     livello gira senza dipinto (il dipinto lo rifà Claude). In simulazione:
     `imposta prova_copione FILE` (scenario `copione.txt`).
   - **Manda a Claude** scrive il documento `copione/ultima` del database
     dell'Artifact (campi `lua`: tutto `levels.lua`, `capitoli`: `M.CAPITOLI`,
     `json`, `livello`, `quando`). **Copia il testo** fa lo stesso negli appunti.
   - **Su Cloudflare** (Worker `megablast-copione`, `strumenti/copione/cloudflare/`),
     come l'editor e il pannello degli eventi: repository collegato, ma dal ramo
     `copione-pubblica`, già costruito (la build del gioco vuole Java, che la build
     di Cloudflare non ha). Dopo ogni merge su main che tocca `client/`, il Copione
     o la build web, `.github/workflows/copione.yml` rifà pagina e build
     (`costruisci.sh`) e riscrive quel ramo (a mano: Actions > Copione > Run
     workflow). Nel pannello di Cloudflare: Import repository, ramo
     `copione-pubblica`, niente comando di build, deploy `npx wrangler deploy`;
     variabili cifrate `EDITOR_CHIAVE` e `GITHUB_TOKEN`, le stesse dell'editor. Da lì
     "Manda a Claude" chiede la chiave la prima volta e scrive
     `client/sim/levels.lua` e `copione/ultima.json` nel ramo `editor-ultima`.
   - I commenti di `levels.lua` la pagina non li vede: chi prende il copione
     unisce a mano (o con `git diff`) e li tiene.
3. **Il ritorno**: Claude scrive `levels.lua` da quello che arriva, rifà
   dipinti e miniature se è cambiata una mappa, gira la simulazione del livello.
