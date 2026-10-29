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
python3 strumenti/arena/arena.py --partite 300 --pesi due.lua --assegna turno   # due individui sempre alla pari
python3 strumenti/arena/evolvi.py --partite 1500                   # bot con rete neurale che evolvono, senza fine
python3 strumenti/arena/impara.py                                  # bot con rete neurale che imparano a gradiente, senza fine
```

`variante.lua` restituisce una tabella come `config.SCORE` (`return { damage = 1, kill = 60, ... }`):
finisce nelle opzioni della partita (`opts.score`) e nella ricetta.

`popolazione.lua` restituisce una lista di pesi del bot (`bot.PESI`, solo i
campi che cambiano, per esempio `return { {}, { morte = 10 }, { punteggio = { damage = 1, kill = 80, ... } } }`):
ogni robot ne prende uno a caso (con `--assegna turno` a turno: il robot i prende
il numero i + partita), e il suo numero va nella riga della partita (`individuo`).
I pesi non vanno nella ricetta (una rete sono centinaia di numeri): la riga ha il
file dei pesi e per il video `arena.py` li rimette dal `.json` accanto al `.lua`.
Con `punteggio` il bot giudica le mosse con altri punti da quelli della partita:
serve a separare l'effetto di una regola da quello del bot che cambia stile. Con
`rete` (`{ strati = {...}, w = {...} }`, `client/sim/rete.lua`) giudica le mosse
una rete neurale.

`evolvi.py` fa imparare il gioco ai bot da soli: reti neurali che partono da
pesi a caso e si evolvono generazione dopo generazione (le migliori restano, le
altre si rifanno mutando e incrociando le migliori). In ogni generazione giocano
anche il bot di oggi (riferimento fisso) e alcuni campioni passati; ogni 5
generazioni il campione fa l'esame contro il bot di oggi sulle stesse partite.
Con la rete evolve anche la soglia del teletrasporto. Più partite per generazione
(`--partite`) vuol dire meno caso nella scelta delle migliori. Salva a ogni generazione: si ferma con Ctrl+C e riparte da dove era (`--nuova`
ricomincia). Esce `simulazione/arena/reti/`: `evoluzione.md`, `storia.json`
(tutte le generazioni: bravura, armi, morti, mosse preferite), `campioni.json`
(la rete migliore di ogni generazione, da mettere in `players[i].pesi`).

`impara.py` fa imparare la rete a gradiente (numpy, niente PyTorch): a ogni giro
gioca (la rete di adesso con un po' di esplorazione, le reti dei giri passati e
il bot di oggi), raccoglie da ogni fine turno le caratteristiche della posizione
e quanto ha reso fino a fine partita (`arena.py --impara 1`), e la rete impara a
prevederlo: non l'esito vero ma il ritorno a passi TD(λ) (`--lambda`, 1 per
l'esito vero), che ha molto meno rumore. Poi l'esame contro il bot di oggi, come
`evolvi.py`; la rete con l'esame migliore resta in `migliore.json`. Esce
`simulazione/arena/impara/`. Serve `pip install numpy`. Né la rete né questi
strumenti finiscono nel gioco: il gioco usa il bot euristico.

Serve luajit (sul PC di Windows: `luajit.exe` nel PATH, o `--luajit C:\percorso\luajit.exe`).
Il video usa il simulatore (`strumenti/simula`), quindi solo su Linux.

## Collaudo delle missioni

```bash
luajit strumenti/arena/collaudo.lua 10              # 10 semi per missione e livello
luajit strumenti/arena/collaudo.lua 10 il_fabbro    # una missione sola
```

Un bot gioca al posto tuo ogni missione dei gironi (`client/sim/campagna.lua`)
a ogni livello e scrive `simulazione/arena/collaudo.md`: quante ne vince, in
quanti turni, quante stelle. La seconda stella va alla mediana dei turni del
bot normale; il girone deve salire di difficoltà. Con `collaudo.senza` nella
missione rifà la prova col bot senza la meccanica richiesta (deve vincere lo
0%), con `collaudo.carattere` e `collaudo.piano` il bot gioca con quel
carattere (`bot.CARATTERI`) o quel piano. Le lezioni no: le risolvono i copioni
di `tests/campagna_test.lua`.

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
