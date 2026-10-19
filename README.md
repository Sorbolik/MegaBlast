# MegaBlast

Repository del gioco **MegaBlast** (progetto Sorblastron).

## Stato

C'è un primo prototipo in hot-seat, con due giocatori sullo stesso dispositivo: terreno distruttibile, robot che camminano e saltano, missile con vento e turni a tempo. Si gioca sullo stesso telefono oppure online tramite il server Go. Per avviarlo segui [docs/setup.md](docs/setup.md).

## Struttura

- `client/` — client Defold (Lua)
- `client/sim/` — simulazione di gioco in Lua puro, condivisa con il server
- `server/` — server Go per le partite online
- `tests/` — test della simulazione
- `docs/` — [design e architettura](docs/design.md), [setup del PC](docs/setup.md)
