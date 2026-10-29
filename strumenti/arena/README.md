# Arena dei bot

Partite tra bot (`client/sim/bot.lua`) senza grafica, per bilanciare il gioco
e trovare le partite da guardare. Una partita di 5 minuti dura circa un
secondo; `arena.py` lancia un processo luajit per core, quindi la velocità
cresce coi core (circa 12.000 partite all'ora su 4 core).

```bash
python3 strumenti/arena/arena.py --partite 400                     # modi a turno, bot normali
python3 strumenti/arena/arena.py --partite 5000 --livello misto    # livelli mescolati
python3 strumenti/arena/arena.py --partite 1000 --modo ffa --mappa crogiolo
python3 strumenti/arena/arena.py --partite 1000 --punteggio variante.lua   # punti partita diversi
python3 strumenti/arena/arena.py --rapporto simulazione/arena/partite.jsonl   # rifà solo il rapporto
python3 strumenti/arena/arena.py --video 1                         # video del primo highlight
python3 strumenti/arena/arena.py --partite 10000 --cartella simulazione/arena/base   # prove tenute separate
python3 strumenti/arena/arena.py --partite 1000 --pesi popolazione.lua   # bot con pesi diversi
python3 strumenti/arena/evolvi.py --generazioni 8 --popolazione 12 --partite 400   # evoluzione dei pesi
```

`variante.lua` restituisce una tabella come `config.SCORE` (`return { damage = 1, kill = 60, ... }`):
finisce nelle opzioni della partita (`opts.score`) e nella ricetta.

`popolazione.lua` restituisce una lista di pesi del bot (`bot.PESI`, solo i
campi che cambiano, per esempio `return { {}, { morte = 10 }, { punteggio = { damage = 1, kill = 80, ... } } }`):
ogni robot ne prende uno a caso, che va nella ricetta (`players[i].pesi`) e nella riga
della partita (`individuo`). Con `punteggio` il bot giudica le mosse con altri punti
da quelli della partita: serve a separare l'effetto di una regola da quello del bot
che cambia stile.

`evolvi.py` è il primo passo dell'apprendimento: una popolazione di pesi gioca,
i migliori restano e gli altri si rifanno mutandoli; il primo è sempre il bot di
oggi, per confronto. Ogni generazione usa semi nuovi. Esce
`simulazione/arena/evolvi/evoluzione.md` (pesi migliori generazione per
generazione e come gioca il migliore rispetto al bot di oggi). Le quote delle
armi dipendono anche dalla scelta d'inizio partita, che è a caso.

Serve luajit (sul PC di Windows: `luajit.exe` nel PATH, o `--luajit C:\percorso\luajit.exe`).
Il video usa il simulatore (`strumenti/simula`), quindi solo su Linux.

## Cosa esce

In `simulazione/arena/` (ignorata da git):

- `partite.jsonl`: una riga per partita. `ricetta` basta a rigiocarla identica
  (seme, mappa, giocatori con armi e livello dei bot, impronte dello stato);
  poi l'esito, i numeri di ogni robot (armi scelte, punti, danno e uccisioni per
  arma, morti, cadute, teletrasporti), ogni evento di punti (tick, chi, a chi,
  punti, motivo, arma, categoria) e i turni con la loro firma (le mosse in
  ordine, per esempio `teleport>lunge+kill+fuori`).
- `rapporto.md`: prima le cose fuori misura (vittorie che si scostano dalla
  media di almeno 2 deviazioni standard, con almeno 30 robot), poi vittorie per
  secondaria e primaria modo per modo, danno e uccisioni per arma, punti per
  categoria e per motivo, mappe, livelli, e chi gioca per primo.
- `highlight.json`: i turni più spettacolari (danno, uccisioni, fuori mappa,
  combinazioni lunghe) pesati per quanto è rara la loro firma, uno per partita.

## Attenzione ai numeri

I numeri dicono come giocano **questi** bot: una strategia che i bot non sanno
fare (per esempio il Rampino per buttare giù) non compare. Prima di cambiare un
valore guardare gli highlight e qualche partita intera, e ripetere con più
partite: sotto qualche centinaio di robot per arma la differenza è rumore.
