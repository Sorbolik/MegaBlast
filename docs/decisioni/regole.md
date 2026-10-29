# Regole di lavoro (Sergio)

Valgono per ogni chat e per il coordinatore. Sono le più importanti del
repository: leggerle costa poco.

## Decisioni prese

| Data | Regola | Dove |
|---|---|---|
| 19 ott | **Minimalismo**: sempre la soluzione più leggera, veloce, con meno dipendenze e avvio breve; giustificare tutto ciò che è più pesante. Costi: il piano più economico a pari qualità. | memoria, docs/design.md |
| 19 ott | **Fluidità**: scatti e micro-blocchi non sono ammessi su nessun telefono, anche economici, a 60–120 Hz. Interpolare il rendering tra i tick, niente allocazioni per frame, niente upload di texture intere. | memoria `performance` |
| 19 ott | Il gioco è **solo a turni**, remake mobile di Blastron (Kabam 2013). Il nome del gioco è **MegaBlast** (20 ott); "Sorblastron" è solo il nome del progetto su claude.ai. | README |
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
| 29 ott | **Storia e decisioni** in questa cartella: ogni chat aggiorna il file della sua area nella stessa PR; l'obiettivo è che una sessione legga solo ciò che le serve. | questo README |

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
