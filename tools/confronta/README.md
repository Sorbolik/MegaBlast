# Confronto prima/dopo

Per le PR che non devono cambiare il gioco (pulizia, rinomi, traduzione):
le stesse partite giocate su `origin/main` e sul ramo devono essere identiche.

```bash
python3 tools/confronta/confronta.py              # 200 partite di bot + le missioni dei gironi
python3 tools/confronta/confronta.py --partite 20 # più veloce
python3 tools/confronta/confronta.py --base HEAD~1
```

- `registra.lua` gioca le partite (modi, mappe, gradi dei bot e set a rotazione)
  e scrive per ognuna l'impronta di tutto lo stato ogni 10 tick. L'impronta non
  dipende dai nomi dei campi né dalle stringhe, così anche una traduzione si
  confronta. Il terreno conta a ogni cambio di turno.
- `confronta.py` prende la base con `git worktree`, gioca su tutte e due le
  versioni (metà dei core ciascuna, circa 5 minuti su 4 core) e dice OK o la
  prima partita diversa e il secondo in cui diverge.

Una modifica di un miliardesimo alla gravità basta a farlo fallire.

## Sempre identica

`identica.py` (gira in `tutti.sh` con 2 partite) controlla che la simulazione dia
sempre la stessa partita: niente `^` in `client/sim` (interprete e JIT di LuaJIT
possono dare un'ultima cifra diversa: si usa `x * x` o `game.ipow`), e le stesse
partite giocate normali, senza JIT (`-joff`) e con `caos.lua` (ordine di `pairs`
a caso e memoria spostata) devono avere le stesse impronte.

```bash
python3 tools/confronta/identica.py               # 4 partite e le missioni
python3 tools/confronta/identica.py --partite 40
```
