# Regole per Codex (ChatGPT) su MegaBlast

Su MegaBlast tu generi le immagini. I prompt li scrive Claude, che coordina il progetto,
nelle schede in `docs/handoff/`: ogni scheda contiene già tutto quello che devi generare.
Sergio ti dice solo quale scheda eseguire (es. "esegui WB-001").

## Chi fa cosa

| Chi | Ruolo |
|---|---|
| Sergio | direttore del gioco: l'ultima parola su tutto, prova il gioco dal vivo |
| Claude | coordinatore e ingegneria: scrive le schede con i prompt, rivede le immagini, le taglia e le integra nel gioco |
| Codex (ChatGPT) | generatore di immagini: esegue le schede approvate |

## Come esegui una scheda

1. Prendi la scheda dal ramo che ti indica Sergio (se non la trovi su `main`,
   `git fetch origin` e cercala sui rami `claude/...`). Eseguila solo se lo stato è
   APPROVATA.
2. Crea il ramo `design/WB-xxx` dal ramo della scheda.
3. Per ogni riga della tabella "Immagini da generare" genera l'immagine con il tuo strumento
   di generazione immagini, usando **esattamente** il prompt scritto e le immagini di
   riferimento indicate. Non cambiare, accorciare o "migliorare" i prompt: se un prompt non
   si può eseguire, scrivi perché nella consegna e passa al successivo.
4. Sfondo trasparente (salvo che la scheda chieda altro): se lo strumento non lo dà diretto, genera su verde pieno (#00FF00) e
   togli il verde, senza lasciare un alone verde attorno al contorno nero.
5. Salva ogni immagine in `art/WB-xxx/<nome>.png` (il nome è nella tabella) e accanto
   `<nome>.txt` con il prompt usato e i riferimenti. Se la scheda chiede più varianti:
   `<nome>_1.png`, `<nome>_2.png`...
6. Guarda ogni immagine prima di salvarla: se ha un difetto visibile (coda tagliata,
   giunture, pezzi mancanti, contorno non nero, scritte, sfondo sporco) rigenerala, al
   massimo 3 tentativi, e nella consegna scrivi quanti ne sono serviti.
7. Scrivi sotto la scheda la sezione "Consegna di Codex": l'elenco dei file, cosa hai
   controllato e cosa no, i problemi.
8. Fai un commit sul ramo `design/WB-xxx` e fai il push. Non aprire PR verso `main` e non
   unire niente: lo fa Claude.

## Cosa puoi toccare

- Scrivi solo in `art/WB-xxx/` e nella sezione "Consegna di Codex" della scheda.
- Non tocchi mai: `client/`, `server/`, `strumenti/`, `tests/`, `CLAUDE.md`, `AGENTS.md`,
  `DECISIONI.md`, gli altri documenti, le parti della scheda scritte da altri.
- Puoi leggere tutto. Lo stile e le decisioni sono in [DECISIONI.md](DECISIONI.md): se la
  scheda e le decisioni si contraddicono, segnalalo nella consegna, non scegliere tu.
