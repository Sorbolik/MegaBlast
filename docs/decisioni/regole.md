# Regole di lavoro (Sergio)

Valgono per ogni chat e per il coordinatore. Sono le più importanti del
repository: leggerle costa poco.

## Decisioni prese

| Data | Regola | Dove |
|---|---|---|
| 19 ott | **Minimalismo**: sempre la soluzione più leggera, veloce, con meno dipendenze e avvio breve; giustificare tutto ciò che è più pesante. Costi: il piano più economico a pari qualità. | memoria, docs/design.md |
| 19 ott | **Fluidità**: scatti e micro-blocchi non sono ammessi su nessun telefono, anche economici, a 60–120 Hz. Interpolare il rendering tra i tick, niente allocazioni per frame, niente upload di texture intere. | memoria `performance` |
| 19 ott | Il gioco è **solo a turni**, sul modello di un gioco di artiglieria del 2013 (il gioco di riferimento). Il nome del gioco è **MegaBlast** (20 ott). | README |
| 19 ott | Ogni modifica va in una **PR**; il merge lo fa Claude quando Sergio dice "mergia". Mai pushare su main direttamente (eccezione: le schede per Codex in docs/handoff, dal 28 ott). | memoria |
| 23 ott | **Igiene del codice**: in ogni momento il repository contiene solo ciò che serve. Quando una cosa viene sostituita, codice, asset e strumenti vecchi si cancellano nella stessa PR (la storia resta in git). | memoria |
| 23 ott | **Autonomia tracciata**: coordinatore e chat decidono da soli quando la scelta è ragionevole e reversibile; ogni scelta autonoma va nella descrizione della PR e in una riga di memoria (ora: nel file dell'area qui). | istruzioni del progetto |
| 23 ott | **Coordinatore**: controlla che le PR tolgano il codice superato, interroga le chat sul perché delle scelte, riporta a Sergio solo i problemi rilevanti; al ritorno di Sergio gli dà il riepilogo delle scelte autonome e le scelte aperte numerate con raccomandazione. Dal 25 ott: tiene tutte le chat coerenti tra loro. | istruzioni del progetto |
| 24 ott | **Modelli**: il coordinatore sceglie quando usare Fable 5.1 (lavori grandi o delicati, ~2,5× il costo di Opus); Opus di default. Nessun modello Claude genera immagini. | memoria |
| 24 ott | Sergio vuole che Claude **mergi e faccia il pull sul suo PC** da solo (thread di controllo remoto), e che provi il gioco prima di consegnarlo. | memoria |
| 25 ott | **Ricerche**: ogni volta che si confrontano strumenti o opzioni, dire anche quali sono state scartate e perché. Mai far sparire un'opzione in silenzio. | memoria |
| 26 ott | **Difetti visibili**: mai liquidare un difetto grafico con "a misura di gioco si nota poco". O si corregge, o si dice chiaramente che va rigenerato. Niente animazioni rattoppate. | memoria |
| 26 ott | **Scalare solo ciò che Sergio nomina**: "svincola le grandezze" vuol dire che tutto il resto deve apparire esattamente come prima, camera compresa (lezione della PR #44). | PR #44 |
| 28 ott | **Immagini con ChatGPT**: Claude scrive le schede in docs/handoff, Codex sul PC di Sergio le esegue e committa su `design/WB-xxx`. Niente API OpenAI, niente copia-incolla di prompt. Claude resta il coordinatore. | docs/handoff/README.md |
| 29 ott | **Roadmap fissata** in docs/roadmap.md; ogni chat la consulta prima di proporre lavoro nuovo. | docs/roadmap.md |
| 29 ott | **Sfida tra chat** ("challenge"): quando una chat fa una proposta, il coordinatore la passa a un'altra chat perché la critichi e la arricchisca prima di portarla a Sergio: strade trascurate, alternative fuori dall'ordinario, cosa va oltre la roadmap. La roadmap e i principi sono una base, non un recinto: una proposta che li contraddice si presenta lo stesso, dicendo cosa romperebbe e perché ne vale la pena. Mai scartare un'idea solo perché "non segue i principi". | questa cartella |
| 29 ott | **Server sempre in pari con main**: ogni PR che cambia regole, simulazione o protocollo aggiorna anche il server nella stessa PR (campi di `server/net.lua`, messaggi di `server/room.go`, dati che il client usa solo in locale, test Go) e prova l'online nel simulatore. Lista dei controlli in docs/server.md. | CLAUDE.md, docs/server.md |
| 29 ott | **Storia e decisioni** in questa cartella: ogni chat aggiorna il file della sua area nella stessa PR; l'obiettivo è che una sessione legga solo ciò che le serve. | questo README |
| 2 nov | **Revisione prima di ogni PR**: `bash strumenti/controlli/tutti.sh` deve dire OK (lo ripete GitHub), e prima di chiedere il merge il thread passa `/code-review` e corregge. Una PR che non deve cambiare il gioco lo dimostra con `strumenti/confronta/confronta.py` (OK nella descrizione). | CLAUDE.md, [architettura.md](architettura.md) |
| 2 nov | **Pulizia e codice in inglese** (Sergio approva il piano in 9 PR, https://claude.ai/artifact/8vyroX263ieG6ViH6hpmco): una sola fisica, quella di oggi; niente nomi né analisi del gioco di riferimento nel repository (nella cartella del progetto i file restano, tolto solo l'APK doppione); storia delle decisioni riscritta con "il gioco di riferimento"; la storia di git non si riscrive; codice, nomi di file e commenti in inglese; documenti, CLAUDE.md, commit e PR restano in italiano; i testi del gioco in `client/lang/it.lua`; il salvataggio sul telefono riparte da zero (Sergio: "così riprovo tutto anche io"); PR #41 di Gabriella chiusa. Il codice resta in italiano finché non arriva l'ondata della sua area. | questo file |
| 2 nov | **Via dal repository le analisi del gioco di riferimento** (PR 3 del piano di pulizia): le due analisi dell'APK sono sostituite da `docs/fisica.md`, che descrive solo la fisica di oggi; nella storia delle decisioni si scrive "il gioco di riferimento". `docs/design.md` aggiornato coi numeri di oggi (Uovo 5 s, Lama ad arco che gira con la mira, Pugno 47, globi 3 s, casse a probabilità, due levette). La storia di git resta com'è. | questa PR |
| 2 nov | **Prima ondata in inglese: simulazione e server** (PR 4 del piano di pulizia): file, funzioni, variabili e commenti di `client/sim/` (tranne bot, rete e corpo) e di `server/` in inglese, coi loro test (`tests/sim_test.lua`, `campaign_test.lua`, `events_test.lua`, `loadout_test.lua`). Si rinomina con `strumenti/rinomina/rinomina.py` e un dizionario (vecchio → nuovo), che si potrà ripassare sui rami aperti (la rete del bot) per togliere i conflitti. Scelte di Claude: un campo di una tabella resta italiano finché lo usa anche codice fuori dall'ondata (client, bot, strumenti) e si traduce nell'ondata di chi lo usa, così ogni PR resta piccola e non cambia il gioco; restano italiane le chiavi dei dati salvati fuori dal codice (eventi del pannello in KV, `corpo.lua` scritto dall'editor: `strumenti/rinomina/chiavi_fisse.txt`) e i messaggi che legge Sergio (log ed errori del server, nomi dei flag come `-eventi`); protocollo, ricette e salvataggi invariati (nessun nome salvato o mandato in rete è cambiato). Scartati: tradurre tutto in un colpo (una PR enorme che blocca tutte le chat), rinominare a mano o con cerca e sostituisci (prenderebbe anche le parole nei testi e nei dati). | questa PR |
| 3 nov | **Seconda ondata in inglese: il client** (PR 5a del piano di pulizia): nomi e commenti di `client/` (menu, interfaccia, battaglia, `game.gui_script`) e dei loro test in inglese, più i campi della simulazione che restavano italiani perché li usava il client. Scelte di Claude: la PR 5 si divide in due. Questa (5a) tocca solo il codice scritto a mano; la 5b farà i nomi di file e cartelle (`battaglia/` → `battle/`, ...) insieme ai file scritti dagli strumenti e dall'editor delle animazioni (`animazioni.lua`, `pelli.lua`, `perni.lua`, `impugnature.lua`, `armi.lua`, `diavoletto.lua`, `dipinti.lua`, `corpo.lua`) e ai loro strumenti, che li leggono per nome e percorso (`prepara.py`, `taglia.py`, `armi.py`, il Worker): spostarli adesso avrebbe voluto dire cambiare anche gli strumenti e l'editor. Restano italiani per ora i campi scritti anche come stringa (id dei traguardi, valori delle impostazioni, azioni dei bottoni, nodi della GUI, chiavi composte come `"mostra_" .. posto`), quelli usati dagli strumenti e dal bot, e l'estensione `vibra`: si traducono con le loro ondate. Il salvataggio del profilo passa alla versione 2: quello vecchio si ignora e si riparte da zero (scelta 7b di Sergio); tolte le conversioni dei salvataggi di prima. Scartati: tradurre anche le stringhe (cambierebbe dati salvati, id mandati in rete e testi del gioco), un elenco a mano dei campi da tenere (lo strumento li trova da solo e si ripassa sui rami aperti). | questa PR |

## Preferenze pratiche

- Scrivere a Sergio in italiano, risposte brevi, decisioni in cima. Le proposte
  lunghe vanno in una pagina o in un documento, non in chat.
- Il PC di Sergio è Windows, `C:\Sviluppo\MegaBlast`, Defold 1.14.0: controllare
  i nomi delle API su defold.com/ref. I file `client/debug.keystore*` non
  tracciati devono restare.
- Il telefono di prova è un iPhone senza account Apple: build HTML5 pubblicata
  sempre allo stesso indirizzo (vedi [architettura.md](architettura.md)).
- Ludo.ai: piano Indie, crediti scarsi dal 26 ott; non chiedere rigenerazioni
  alla leggera. Dal 26 ott sera Sergio ha rinunciato agli asset generati per il
  personaggio (vedi [personaggio.md](personaggio.md)).

## Scartate

- Installare interi pacchetti di skill o agenti (Claude Code Game Studios):
  troppo pesanti, impongono cartelle e agenti per altri motori (21 ott). Prese
  solo 4 skill scritte in italiano e 5 skill Defold (CC0).
- Proporre di nuovo l'API di OpenAI per le immagini: rifiutata il 28 ott.
