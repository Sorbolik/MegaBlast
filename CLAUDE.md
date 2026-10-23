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
leggilo prima di proporre o cambiare una meccanica.

Per progettare, valutare, bilanciare e implementare meccaniche ci sono le skill
in [.claude/skills/](.claude/skills/README.md).

Altri test: `luajit tests/sim_test.lua` (simulazione), `luajit tests/battaglia_test.lua` (personaggio e camera),
`go test ./server/` (server).
