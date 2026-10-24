---
name: dottore-del-design
description: Analizza MegaBlast com'è oggi (numeri della simulazione, regole, note di playtest di Sergio) per trovare problemi di bilanciamento, strategie che rompono il gioco e cali di divertimento, con correzioni in ordine di priorità. Usala per "è bilanciato?", "cosa non va?" o per sistemare le note di una partita di prova.
---

# Dottore del design

Fai una diagnosi del gioco basata sui dati, non sulle impressioni.

## Regola principale: niente dati, niente verdetto

Prima elenca cosa hai letto e cosa manca. Una sezione senza dati si scrive
**NON VALUTATA: manca X**, non si stima. Un controllo che non trova problemi
perché non c'era niente da controllare non è un "tutto ok".

## 1. Raccogli i dati

- Numeri: regole in `client/sim/config.lua` (vita, Nucleo, durata di turno,
  tempo dopo il primo attacco e partita, in secondi), fisica in
  `client/sim/game.lua` (danni, raggi, tick, velocità, `*_BLAST`, casse). I tempi in game.lua sono in tick a 60 al
  secondo, le distanze in pixel.
- Regole e intenzioni: `docs/design.md`.
- Mappe: `client/sim/maps.lua` (spawn, acciaio, bordi).
- Note di playtest: quelle che Sergio incolla o allega.
- Se serve un numero che non si legge dal codice (es. gittata reale, quanto
  rotola un globo), misuralo con uno script Lua che usa `sim.game` come fa
  `tests/sim_test.lua`, e scrivi che è misurato.

## 2. Controlli

**Combattimento**
- Danno massimo per turno di ogni arma e combinazione possibile in un turno
  (es. fendente + teletrasporto + fendente), e quanti turni servono per
  uccidere da 100 di vita.
- Un'arma batte le altre in ogni situazione? Una non serve mai?
- Corpo a corpo contro distanza: il rischio di avvicinarsi è ripagato?
- Spinta (knockback) e bordi: si può uccidere con un colpo solo buttando fuori?

**Tempo e turni**
- Si riesce a fare quello che il gioco chiede in 15 s su touch?
- Gli 8 s dopo il primo attacco bastano per ripararsi, o rendono ogni colpo senza rischio?
- La regola dei 3 minuti premia chi scappa e si nasconde?

**Casse e fortuna**
- Quanto pesa la fortuna della cassa sull'esito? Chi è più vicino agli spawn è
  avvantaggiato?

**Mappe**
- Spawn equi (distanza, copertura, altezza)? Punti dove si è intoccabili?

**Divertimento (dalle note di playtest)**
- Momenti morti (attese, turni senza scelte), confusione, frustrazione,
  momenti belli da proteggere.

## 3. Referto

```markdown
## Referto: <tema>
**Dati letti**: file e note usate. **Mancano**: ...
**Stato**: SANO / DA SISTEMARE / GRAVE / NON VALUTATO

### Problemi
| Priorità | Problema | Prova (numero o nota) | Correzione proposta | Effetto atteso |
|---|---|---|---|---|

### Strategie che rompono il gioco
### Da proteggere (cose che funzionano)
```

GRAVE se c'è una strategia che vince sempre, un'arma che rende inutili le
altre o un modo per non perdere mai. Ordina le correzioni per impatto diviso
fatica, e proponi prima un cambio di numero, poi un cambio di regola.

## 4. Dopo

Chiedi a Sergio quale correzione applicare. Un cambio di numero si fa in
`client/sim/config.lua` (o `game.lua` se è fisica), con `docs/design.md` aggiornato e `tests/sim_test.lua`
che passa (vedi [sviluppa-meccanica](../sviluppa-meccanica/SKILL.md)).
