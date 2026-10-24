---
name: sviluppa-meccanica
description: Implementa in MegaBlast una meccanica già progettata (arma, regola, oggetto, cambio di numeri) seguendo l'architettura del gioco - simulazione Lua condivisa, server Go, client Defold 1.14. Usala quando si passa dalla scheda al codice.
---

# Sviluppa una meccanica

Ordine fisso: prima la simulazione, poi il server, poi il client. Così il
server autoritativo e i telefoni restano d'accordo.

## 1. Simulazione (`client/sim/`)

- Lua puro 5.1: niente API di Defold (`go.`, `gui.`, `vmath`, `msg`...), perché
  la stessa simulazione gira nel server Go con gopher-lua.
- Deterministica: numeri casuali solo da `sim/rng.lua` col seed della partita,
  mai `math.random` o l'ora. Niente `pairs` dove l'ordine cambia l'esito: usa
  `ipairs` o liste ordinate.
- Passo fisso a 60 tick al secondo: durate in tick (`M.X_TICKS = 2 * 60`),
  velocità in pixel al secondo moltiplicate per `M.DT`.
- Numeri da bilanciare (regole, costi, durate, statistiche per robot) in
  `client/sim/config.lua`; costanti di fisica in testa a `game.lua` come
  `M.NOME = valore -- commento`.
- Ciò che il client deve mostrare esce come evento (`self:emit{ type = ... }`)
  o dallo stato, mai calcolato a parte nel client.

## 2. Test (`tests/sim_test.lua`)

Aggiungi un test per ogni criterio della scheda, nello stile dei test che ci
sono (`check(cond, "messaggio")`). Poi:

```bash
luajit tests/sim_test.lua
```

## 3. Server (`server/`)

Solo se cambia il protocollo: nuovi messaggi o campi (es. il campo `w`
dell'arma nel messaggio `fire`, letto in `server/match.go`).
Aggiorna la tabella in `docs/design.md` §5 e lancia:

```bash
go test ./server/
```

## 4. Client Defold (`client/`)

- Controlla i nomi delle API su defold.com/ref per la 1.14 (es.
  `gui.cancel_animations` è plurale). `bob.jar` accetta cose che l'editor
  rifiuta: le regole note sono in `strumenti/simula/controlla.py`.
- Fluidità prima di tutto: niente allocazioni in `update` (riusa tabelle e
  `vmath.vector3`), disegno interpolato tra i tick, nessun lavoro per pixel
  sul terreno fuori dal rettangolo toccato.
- `buffer.create` non azzera la memoria: riempilo tu.
- Grafica nello stile "Le Scorie", con i PNG già tagliati in `client/assets/`.

## 5. Guarda il gioco

Scrivi uno scenario per la meccanica in `strumenti/simula/scenari/` (comandi
in [strumenti/simula/README.md](../../../strumenti/simula/README.md)), poi:

```bash
python3 strumenti/simula/simula.py
```

Deve finire con `OK`. Guarda `simulazione/foto/riepilogo.png` e le foto della
meccanica: si deve vedere davvero quello che hai cambiato.

## 6. Consegna

- `docs/design.md` aggiornato nella stessa PR.
- Commenti, commit e PR in italiano.
- PR in bozza; si unisce quando Sergio dice "mergia", poi si aggiorna il suo PC.
