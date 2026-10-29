# Decisioni e storia del progetto

Qui vive tutto quello che è stato deciso, scartato o lasciato aperto dal primo
giorno (19 ottobre 2026). È diviso per area, così una sessione legge **solo il
file dell'area che tocca** e non spende token sul resto.

## Come usarlo

1. Prima di proporre o cambiare qualcosa, leggi il file dell'area (tabella sotto)
   e [../roadmap.md](../roadmap.md). Non leggere `cronologia.md` se non ti serve
   la sequenza degli eventi.
2. Quando Sergio decide qualcosa, o una chat decide in autonomia, chi lo fa
   aggiunge nella stessa PR: una riga nel file dell'area (tabella "Decisioni
   prese", con data, chi, dove) e una riga in `cronologia.md`. Le scelte
   autonome portano "(Claude)" dopo la data.
3. Quando una decisione viene ribaltata, non si cancella: si segna
   "superata il …" e si aggiunge la nuova riga. La storia resta leggibile.
4. Quello che viene scartato va nella sezione "Scartate" con il motivo: è una
   regola di Sergio (25 ottobre) e evita di riproporre le stesse cose.
5. Le domande senza risposta stanno in `aperte.md`, una riga ciascuna, con chi
   deve rispondere. Quando una si chiude, la riga si sposta nel file dell'area.

## I file

| File | Cosa contiene | Leggilo quando |
|---|---|---|
| [regole.md](regole.md) | Le regole fisse di Sergio su come si lavora: minimalismo, igiene del codice, difetti visibili, ricerche, merge, modelli, coordinatore | Sempre, è corto |
| [gameplay.md](gameplay.md) | Regole della partita: turni, due attacchi, teletrasporti, punteggio, respawn, morte da soli, cure, draft, modalità | Tocchi `client/sim/` o le regole |
| [arsenale.md](arsenale.md) | Armi primarie e secondarie, casse, oggetti tattici, rampino, valori decisi | Tocchi un'arma o un oggetto |
| [progressione.md](progressione.md) | Albero, set, loadout, podio, XP, Torneo normalizzato, negozio ed eventi (principi) | Tocchi profilo, armeria, podio, premi |
| [personaggio.md](personaggio.md) | Tutta la storia del personaggio: Scoria, greybox, diavoletto dipinto, Ludo, vettoriale, editor e stampino; strumenti scartati | Tocchi `scoria.lua`, animazioni, skin, editor |
| [grafica.md](grafica.md) | Direzione artistica, analisi di Blastron, mappe (Forgia, Crogiolo, scala), armi vettoriali, casse, pipeline immagini con ChatGPT/Codex | Tocchi asset, mappe, prompt |
| [interfaccia.md](interfaccia.md) | UI minimale stile Sagoma, home, comandi touch, regole "tranquilla ed essenziale" | Tocchi una schermata o l'HUD |
| [architettura.md](architettura.md) | Defold, repo, server Go, protocollo, simulatore, build web, valutazione motori, Cloudflare, skill | Tocchi server, build, strumenti |
| [designer.md](designer.md) | Come si lavora con Gabriella, il suo ramo, cosa ha provato | Parli con lei o tocchi i suoi file |
| [aperte.md](aperte.md) | Decisioni ancora da prendere, con chi decide | Prima di chiedere qualcosa a Sergio |
| [cronologia.md](cronologia.md) | Un rigo per giorno e per PR, dal 19 ottobre | Ti serve "quando" o "in che PR" |

Il documento di game design (varianti e scelte, 22–24 ottobre) resta
[../game_design_competitivo.md](../game_design_competitivo.md); la roadmap
fissata è [../roadmap.md](../roadmap.md). Le schede per ChatGPT sono in
[../handoff/](../handoff/README.md).

## Convenzioni

- Date in forma `26 ott`; anno 2026 salvo diversa indicazione.
- "Sergio" = decisione sua; "(Claude)" = scelta autonoma, Sergio può ribaltarla.
- Un link a PR è `#NN`; le pagine claude.ai si citano con l'indirizzo intero.
- Ogni file sta sotto le 300 righe: se cresce, si divide per sotto-area e si
  aggiorna la tabella sopra.
