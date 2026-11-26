# Arena dei bot

Partite tra bot (`client/sim/bot.lua`) senza grafica, per bilanciare il gioco
e trovare le partite da guardare. Una partita di 5 minuti dura circa un
secondo; `arena.py` lancia un processo luajit per core, quindi la velocità
cresce coi core (circa 12.000 partite all'ora su 4 core).

```bash
python3 tools/arena/arena.py --partite 400                     # modi a turno, bot normali
python3 tools/arena/arena.py --partite 5000 --livello misto    # livelli mescolati
python3 tools/arena/arena.py --partite 1000 --modo ffa --mappa fossa
python3 tools/arena/arena.py --partite 1000 --punteggio variante.lua   # punti partita diversi
python3 tools/arena/arena.py --rapporto simulazione/arena/partite.jsonl   # rifà solo il rapporto
python3 tools/arena/arena.py --video 1                         # video del primo highlight
python3 tools/arena/arena.py --partite 10000 --cartella simulazione/arena/base   # prove tenute separate
python3 tools/arena/arena.py --partite 1000 --pesi popolazione.lua   # bot con pesi diversi
python3 tools/arena/arena.py --partite 300 --pesi due.lua --assegna turno   # due individui sempre alla pari
python3 tools/arena/evolvi.py                                  # specialisti del bot del gioco, senza fine
python3 tools/arena/impara.py                                  # bot con rete neurale che imparano a gradiente, senza fine
python3 tools/arena/trovate.py simulazione/arena/evolvi        # video e pagina delle trovate dei bot
python3 tools/arena/maestro.py                                 # maestro e allievo: rollout e correzione imparata, senza fine
```

`variante.lua` restituisce una tabella come `config.SCORE` (`return { damage = 1, kill = 60, ... }`):
finisce nelle opzioni della partita (`opts.score`) e nella ricetta.

`popolazione.lua` restituisce una lista di pesi del bot (`bot.PESI`, solo i
campi che cambiano, per esempio `return { {}, { morte = 10 }, { punteggio = { damage = 1, kill = 80, ... } } }`):
ogni robot ne prende uno a caso (con `--assegna turno` a turno: il robot i prende
il numero i + partita, e le partite vanno a coppie, la stessa partita due volte
con i numeri scambiati: due bot uguali fanno esattamente metà e metà), e il suo
numero va nella riga della partita (`individuo`).
I pesi non vanno nella ricetta (una rete sono centinaia di numeri): la riga ha il
file dei pesi e per il video `arena.py` li rimette dal `.json` accanto al `.lua`.
Con `punteggio` il bot giudica le mosse con altri punti da quelli della partita:
serve a separare l'effetto di una regola da quello del bot che cambia stile. Con
`rete` (`{ strati = {...}, w = {...} }`, `client/sim/rete.lua`) giudica le mosse
una rete neurale.

`evolvi.py` fa evolvere cinque specialisti del bot del gioco (`bot.PESI`: quanto
teme di perdere vita o di morire, quando prova il globo, quanto gli piace buttare
nel vuoto, uccidere, fare danno, e il gusto per le armi da vicino, da lontano e
per il Mantice, che guida anche la scelta d'inizio partita). Il bot resta quello
del gioco, quindi uno specialista si mette nel gioco così com'è (`migliori.json`).
Gli specialisti: spingitore (uccisioni nel vuoto), acrobata (globi e Rampino),
cecchino (danno da lontano), picchiatore (danno da vicino), sopravvissuto (muore
poco). Ognuno ha la sua popolazione; giocano tutti insieme col bot di oggi. Si
giudicano sulla bravura (da tutte le partite giocate, tirata verso 0,5 se sono
poche) meno una penalità se fanno il loro mestiere meno della soglia; la soglia
parte dal bot di oggi e sale verso il campione finché il campione resta bravo
quasi quanto il bot di oggi. Ogni `--esame` generazioni il campione di ognuno
gioca contro il bot di oggi a coppie. Se uno per `--stallo` esami non migliora
cambia da solo (più mutazione, metà popolazione a caso) e lo scrive nel rapporto.
Quando cambiano le regole si rifà con `--nuova`. Salva a ogni generazione: si
ferma con Ctrl+C e riparte da dove era. Esce `simulazione/arena/evolvi/`:
`evoluzione.md`, `storia.json`, `specialisti.json`, `migliori.json` e
`trovate.jsonl` (i turni rari che fanno tanti punti, con ricetta e pesi).

`trovate.py` sceglie le trovate (i turni che fanno tanti punti con una
combinazione di mosse che quasi nessuno fa: punti per rarità, tutte diverse)
dalle partite di una cartella dell'arena o da `trovate.jsonl` di `evolvi.py`, ne
fa i video col simulatore e scrive `galleria/galleria.html`, da pubblicare come
Artifact con i video accanto. I video vanno fatti con lo stesso codice che ha
giocato le partite.

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
Il video usa il simulatore (`tools/simula`), quindi solo su Linux.

## Maestro e allievo

```bash
python tools/arena/maestro.py                 # la notte: cicli senza fine, riparte da dov'era
python tools/arena/maestro.py --cicli 1 --partite 30 --esame 120   # prova breve
python tools/arena/maestro.py --solo-esame simulazione/arena/maestro/migliore.lua
```

Un altro modo di allenare, invece di numeri a caso giudicati su partite intere (lì il caso
copre differenze di qualche punto). Il Maestro (`maestro.lua`) è il bot del gioco che, a ogni
scelta (attacco e riparo), prende le sue migliori candidate (`b.scegli` in `client/sim/bot.lua`),
copia la partita intera e gioca avanti il resto del giro con tutti i bot, più volte con semi
diversi (gli stessi per ogni candidata), e tiene quella che lascia la squadra più avanti in
punti più metà della vita di differenza (`--vita`). È il rollout del backgammon.

Le sue vittorie contro il bot di oggi dicono quanto rende pensare meglio, anche mappa per mappa
(il tetto di bravura: dove resta vicino al 50% decide il caso). Le sue scelte, con le
caratteristiche della posizione dopo ogni candidata, insegnano all'allievo una correzione
(`pesi.correzione` per l'attacco, `pesi.riparo` per il riparo: venti numeri ciascuna, ridge
dentro ogni scelta). L'allievo è il bot del gioco con quei numeri, senza rollout: si esamina
contro il bot di oggi a coppie, e se fa meglio del migliore il ciclo dopo il Maestro sceglie e
gioca avanti con lui (expert iteration). Esce `simulazione/arena/maestro/`: `maestro.md`,
`stato.json`, `migliore.lua`, `ciclo_N/`. Una partita del Maestro dura qualche minuto (circa
20 rollout a scelta): sui 16 core del PC fa circa un ciclo ogni mezz'ora.
Il codice dei rollout è `client/sim/master.lua`, lo stesso del livello MAESTRO dell'Allenamento
(`bot.LEVELS.maestro`, che pensa a pezzi come il bot); il livello si prova con
`luajit tools/arena/maestro.lua --grado maestro --maestro 0 --avversario difficile`.

## Turni delle persone

```bash
luajit tools/arena/turni_umani.lua partite/*.lua                 # contro il grado 10
luajit tools/arena/turni_umani.lua --pesi nuovo.lua partite/*.lua  # un bot nuovo: ha imparato?
```

Le partite giocate sul telefono arrivano al server e ogni notte finiscono nel ramo
`partite-registrate` (`git fetch origin partite-registrate`, cartella `partite/`). Per ogni
turno di una persona lo strumento rimette la partita a quel momento e fa giocare il turno al
bot (`--grado`, `--semi` volte), poi confronta i punti di vantaggio della squadra in quel turno
e le mosse: `simulazione/arena/umani/confronto.md` dice in quali mosse la persona fa meglio
del bot, `turni.jsonl` ha ogni turno. Rifatto col bot nuovo dice se ha imparato.

## Collaudo delle missioni

```bash
luajit tools/arena/collaudo.lua 10              # 10 semi per missione e livello
luajit tools/arena/collaudo.lua 10 il_fabbro    # una missione sola
```

Un bot gioca al posto tuo ogni missione dei gironi (`client/sim/levels.lua`)
a ogni livello e scrive `simulazione/arena/collaudo.md`: quante ne vince, in
quanti turni, con quanti punti fatti, quante stelle. La prima stella è la
vittoria; la seconda va alla mediana dei punti fatti dal bot normale nelle vinte,
la terza all'80° percentile (Sergio, 14 nov: soglie di punti fatti, non più il
vantaggio né i bonus); il girone deve salire di difficoltà. Con `collaudo.senza` nella
missione rifà la prova col bot senza la meccanica richiesta (deve vincere lo
0%), con `collaudo.carattere` e `collaudo.piano` il bot gioca con quel
carattere (`bot.PERSONALITIES`) o quel piano. Le lezioni no: le risolvono i copioni
di `tests/campaign_test.lua`.

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
