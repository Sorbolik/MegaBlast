# MegaBlast

Repository del gioco **MegaBlast** (progetto Sorblastron).

## Stato

C'è un primo prototipo in hot-seat, con due giocatori sullo stesso dispositivo: terreno distruttibile con tubi d'acciaio indistruttibili, una mappa a più piani, salto libero con controllo in aria, missile e turni a tempo con qualche secondo per ripararsi dopo lo sparo. Si gioca sullo stesso telefono oppure online tramite il server Go. Per avviarlo segui [docs/setup.md](docs/setup.md).

## Struttura

- `client/` — client Defold (Lua)
- `client/sim/` — simulazione di gioco in Lua puro, condivisa con il server
- `server/` — server Go per le partite online
- `tests/` — test della simulazione
- `docs/` — [design e architettura](docs/design.md), [setup del PC](docs/setup.md), [game design competitivo](docs/game_design_competitivo.md), [roadmap](docs/roadmap.md)
- `strumenti/simula/` — [simulazione automatica del gioco](strumenti/simula/README.md)
- `docs/handoff/`, `art/` — [schede con i prompt per Codex](docs/handoff/README.md) e immagini generate; regole di Codex in [AGENTS.md](AGENTS.md), decisioni in [DECISIONI.md](DECISIONI.md)
