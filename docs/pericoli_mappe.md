# I pericoli delle mappe

Ogni girone della campagna ha una mappa dipinta con un pericolo suo
([campagna_gironi.md](campagna_gironi.md)), e le mappe dei gironi stanno anche nella
rotazione online (Sergio, 11 nov: crea varianza). Quindi un pericolo vive nella
simulazione (`client/sim/`), il server lo porta nello stato e il client lo disegna. Questa è
la ricetta, fissata con i primi tre (Limbo, Lussuria, Gola); i prossimi (massi, acqua che
sale, tombe...) la seguono.

## Tre cose che una mappa può chiedere

Si scrivono come dati nella mappa (`client/sim/maps.lua`) e le fa `client/sim/hazards.lua`:

| Campo | Cosa fa | Esempio |
|---|---|---|
| `gravity = 0.6` | la gravità di tutta la partita, per il valore: salti e tiri vanno più lontano | Limbo |
| `mud = { { x0, x1, y0, y1 } }` | rettangoli del mondo: chi sta a terra dentro prende lo stato «lento» (fino a fine del suo prossimo turno) | le pozze della Gola |
| `blood = { { x0, x1, y0, y1 } }` | come il fango ma dà lo stato «bruciatura» | le pozze del Flegetonte |
| `hazard = "wind"`, `"hail"`, `"fire_rain"`, `"bridges"` o `"ice"` | un pericolo dei giri: la tabella `KINDS` di `hazards.lua` | Lussuria, Gola, Sabbione, Malebolge, Cocito e Lucifero |
| `bridges = { { x0, x1, y0, y1 } }` | con `bridges`: il rettangolo del mondo di ogni ponte che crolla | Malebolge |
| `ice = true` (o rettangoli), `wings = true` | con `ice`: dove si scivola; con `wings` a fine giro le ali spingono tutti lontano dal centro | Cocito, Lucifero |

Un pericolo dei giri ha quattro punti d'ingresso, tutti facoltativi tranne `setup`:
`setup(g, hz)` all'inizio, `round_end(g, hz)` quando l'ultimo turno del giro è finito
(i robot sono fermi, il turno dopo non è partito), `tick(g, hz)` a ogni tick e `busy(g, hz)`
(vero finché qualcosa è in aria: il turno non finisce sotto). Il suo stato sta **solo** in
`g.hz`, una tabella di numeri e liste; tutto il casuale usa il generatore della partita
(`g.rng`), così server e client sorteggiano uguale. Nei tentativi del bot (`bot.world`)
`g.hz` non c'è: il bot non vede il pericolo (la gravità e il fango sì).

## Server

Niente da fare per un pericolo nuovo oltre a quello che c'è: `hz` va nello stato così com'è
(`server/net.lua`, `N.snapshot`) e il client lo ricopia in `apply_state`
(`client/main/game.gui_script`). Gli eventi (`g:emit`) arrivano da soli. Si aggiunge un
controllo in `tests/hazards_test.lua` e, se serve, in `server/server_test.go`.

## Client

`client/battle/hazards.lua` disegna `g.hz` e i dati della mappa (mai le regole): nodi del
mondo (le ombre e i chicchi della grandine), un pezzo di HUD (la pillola della bufera, con
la freccia della prossima raffica). I testi nuovi stanno in `client/lang/it.lua` (gruppo
`match`). Le immagini della mappa si fanno con `tools/grafica/mappe_dipinte.py` (layout,
tema di `tools/grafica/gironi/temi.py`, spuntoni d'acciaio con `acciaio`), poi
`mappa_in_lua.py` e `miniature_mappe.py`. Il fango è dipinto nella mappa: i numeri di `mud`
in `maps.lua` e `GOLA_POZZE` in `mappe_dipinte.py` vanno tenuti uguali (un test controlla
che ogni pozza abbia il terreno dentro il rettangolo).

## I primi tre

| Mappa | Pericolo | Numeri (`config.lua` e `maps.lua`) |
|---|---|---|
| Limbo | gravità ridotta | `gravity = 0.6`: il salto passa da 40 a 67 e una Lanciarune a 45° fa 1,7 volte la strada |
| Lussuria | la bufera: a fine giro una raffica sposta ogni robot (non i colpi) di `WIND.step` = 66 (un passo e mezzo), fermandosi ai muri; la freccia dice da che parte per tutto il giro | spuntoni d'acciaio per il Rampino, la gola in mezzo uccide |
| Gola | la grandine: `HAIL.count` = 3 chicchi per giro cadono dove le ombre li hanno annunciati il giro prima, scoppiano sul primo terreno o robot (`HAIL.blast`: 35 al centro, 15 al bordo, scava) | due pozze di fango (`mud`) |

Scelte di Claude (11 nov): gravità 0,6 e non 0,5 (con 0,5 ogni tiro attraversava tutta la
mappa); la raffica sposta subito i robot a fine giro invece di aprire un turno apposta (non
cambia le fasi della partita, quindi né il server né il client); i chicchi cadono durante il
primo turno del giro dopo, come le casse, e il turno non finisce finché cadono; il fango è lo
stato «lento» che c'era già; il bot non vede la grandine né la raffica. Non fatto: l'Uovo che
nel fango non rimbalza (Gola, scheda della campagna).

## Violenza, Frode, Tradimento e Lucifero (terzo blocco)

| Mappa | Pericolo | Numeri (`config.lua` e `maps.lua`) |
|---|---|---|
| Flegetonte | il fiume di sangue uccide (si cade, come nelle altre gole); tre sassi per passare; i tronchi morti sono terreno che si spezza e fermano i colpi finché non li rompi; due pozze di sangue (`blood`) bruciano | stato «bruciatura» già esistente |
| Sabbione | pioggia di fuoco: la grandine con `FIRE_RAIN` (4 chicchi, 30 di danno al centro) e ogni chicco dà bruciatura; piatto, senza ripari | `C.FIRE_RAIN` |
| Malebolge | due fosse di pece larghe 54 con un ponte crepato ciascuna: quando un robot ci sale, o un colpo gli toglie celle, trema (rettangolo arancione) e dopo `BRIDGE.delay` = 150 tick cade (`carve` a cerchietti, così il client online scava uguale) | `C.BRIDGE`, `hz.t`, `hz.solid` |
| Cocito | lastre di ghiaccio sottili sull'acqua gelata, separate da crepe di 28; chi smette di camminare scivola (`ICE`: decade del 3% a tick, al massimo 1,2 per tick); le esplosioni bucano e sotto si muore | `C.ICE`, `hz.vel`, `hz.prev` |
| Lucifero (arena, non online) | il lago largo col pozzo in mezzo (160) e due lastre per passarlo; ghiaccio che scivola e `wings`: a fine giro ognuno è spinto di `WIND.step` lontano dal centro, fermandosi ai muri; la sua battaglia in tre fasi è una missione (Copione), non c'è ancora | `maps.OFFLINE` |

Scelte di Claude (11 nov): i ponti falsi sono quelli dipinti crepati (tutti crollano, nessuno a caso:
si vedono); quanto è largo il ponte (54 = 81 unità del mondo) e `delay` sono fatti perché lo
si attraversi di corsa senza fermarsi (si cammina a circa 0,65 unità per tick) e non se ci si
ferma; la scivolata è un attrito, non una fisica nuova: resta in `hz`, quindi niente campi nei
robot; il bot non vede ponti, ghiaccio, ali né pioggia (copia della partita senza `hz`);
Lucifero ha una mappa propria fuori dalla rotazione perché la sua battaglia è una missione.
