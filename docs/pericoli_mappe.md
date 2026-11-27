# I pericoli delle mappe

Ogni girone della campagna ha una mappa dipinta con un pericolo suo
([campagna_gironi.md](campagna_gironi.md)), e le mappe dei gironi stanno anche nella
rotazione online (Sergio, 11 nov: crea varianza). Quindi un pericolo vive nella
simulazione (`client/sim/`), il server lo porta nello stato e il client lo disegna. Questa è
la ricetta, fissata con i primi tre (Limbo, Lussuria, Gola) e seguita dai tre dopo (Avarizia, Ira,
Eresia); i prossimi la seguono.

## Tre cose che una mappa può chiedere

Si scrivono come dati nella mappa (`client/sim/maps.lua`) e le fa `client/sim/hazards.lua`:

| Campo | Cosa fa | Esempio |
|---|---|---|
| `gravity = 0.6` | la gravità di tutta la partita, per il valore: salti e tiri vanno più lontano | nessuna per ora (era il Limbo fino al 27 nov) |
| `mud = { { x0, x1, y0, y1 } }` | rettangoli del mondo: chi sta a terra dentro prende lo stato «lento» (fino a fine del suo prossimo turno) | le pozze della Gola |
| `blood = { { x0, x1, y0, y1 } }` | come il fango ma dà lo stato «bruciatura» | le pozze del Flegetonte |
| `hazard = "wind"`, `"hail"`, `"fire_rain"`, `"bridges"`, `"ice"`, `"boulders"`, `"water"`, `"tombs"` o `"lever"` | un pericolo dei giri: la tabella `KINDS` di `hazards.lua` | Limbo, Lussuria, Gola, Avarizia, Ira, Eresia, Sabbione, Malebolge, Cocito e Lucifero |
| `bridges = { { x0, x1, y0, y1 } }` | con `bridges`: il rettangolo del mondo di ogni ponte che crolla | Malebolge |
| `ice = true` (o rettangoli), `wings = true` | con `ice`: dove si scivola; con `wings` a fine giro le ali spingono tutti lontano dal centro | Cocito, Lucifero |
| `levers = { { x, y, dx, dy } }` | con `lever`: le borchie d'acciaio dove può stare la leva e la faccia da cui spunta; le rinascite hanno anche `y2`, la cima della trave a mappa capovolta | Limbo |

Un pericolo dei giri ha quattro punti d'ingresso, tutti facoltativi tranne `setup`:
`setup(g, hz)` all'inizio, `round_end(g, hz)` quando l'ultimo turno del giro è finito
(i robot sono fermi, il turno dopo non è partito), `tick(g, hz)` a ogni tick e `busy(g, hz)`
(vero finché qualcosa è in aria: il turno non finisce sotto); la leva ne usa altri tre: `hold(g, hz)`
(vero: il tempo è fermo, `game:step` non fa altro), `blast` e `line` (un'esplosione o un colpo dritto
appena successi, da `game:blast` e `game:fire_eagle`). Il suo stato sta **solo** in
`g.hz`, una tabella di numeri e liste; tutto il casuale usa il generatore della partita
(`g.rng`), così server e client sorteggiano uguale. Nei tentativi del bot (`bot.world`)
`g.hz` non c'è: la copia del bot non simula il pericolo (la gravità e il fango sì); il bot lo vede dal rischio, vedi sotto.

## Server

Niente da fare per un pericolo nuovo: online ogni telefono gioca la stessa partita del
server coi tasti di ogni tick (dal 22 nov, `client/sim/netkeys.lua`), quindi il pericolo e i
suoi eventi (`g:emit`) ci sono da soli. `hz` va anche nello stato del server così com'è
(`server/net.lua`, `N.snapshot`), che serve ai test. Si aggiunge un
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
| Limbo | la leva (dal 27 nov, al posto della gravità ridotta): chi la colpisce con un colpo qualsiasi (esplosione, colpo in volo, schegge, Tonante, un colpo da vicino) o la tocca col corpo capovolge la mappa, vedi sotto | `C.LEVER`, `levers` e le rinascite con `y2` in `maps.lua` |
| Lussuria | la bufera: a fine giro una raffica sposta ogni robot (non i colpi) di `WIND.step` = 66 (un passo e mezzo), fermandosi ai muri; la freccia dice da che parte per tutto il giro | spuntoni d'acciaio per il Rampino, la gola in mezzo uccide |
| Gola | la grandine: `HAIL.count` = 3 chicchi per giro cadono dove le ombre li hanno annunciati il giro prima, scoppiano sul primo terreno o robot (`HAIL.blast`: 35 al centro, 15 al bordo, scava) | due pozze di fango (`mud`) |

Scelte di Claude (11 nov): gravità 0,6 e non 0,5 (con 0,5 ogni tiro attraversava tutta la
mappa); la raffica sposta subito i robot a fine giro invece di aprire un turno apposta (non
cambia le fasi della partita, quindi né il server né il client); i chicchi cadono durante il
primo turno del giro dopo, come le casse, e il turno non finisce finché cadono; il fango è lo
stato «lento» che c'era già. Non fatto: l'Uovo che
nel fango non rimbalza (Gola, scheda della campagna).

## La leva del Limbo (Sergio, 27 nov 2026)

La leva sta su una delle 20 borchie d'acciaio della mappa (indistruttibili), su qualsiasi faccia,
anche quelle sotto: chi gioca deve pesare se vale un colpo. La colpisci (con un colpo, che conta
come attacco) o la tocchi col corpo entrandoci, e alla fine del tick **la mappa si capovolge
davvero**: le righe di celle si scambiano con la loro specchiata e così tutto quello che c'è sopra
(robot coi piedi in basso, colpi, globi, schegge, casse, trappole; cerchi di cura e pozze di pece
cadono sul terreno sotto o spariscono). Non si gioca mai a testa in giù. Poi il tempo si ferma per
`LEVER.freeze` = 60 tick (1 s): niente si muove, nemmeno il cronometro del turno, e un anello con la
freccia mostra dove atterrerà ognuno (`hz.lx`, `hz.ly`, -1 se cade fuori). Poi tutti cadono, col
danno da caduta normale. Le rinascite stanno sulle 8 travi d'acciaio libere sopra e sotto: a ogni
capovolgimento passano all'altra faccia (`y2`). La leva non scatta da sola (Sergio: «resta ferma
finché qualcuno la tira»).

Dopo lo scatto salta su un'altra borchia, a caso con i pesi (`LEVER`): `min(d, 700) / 700` con `d` la
distanza da dove atterra chi l'ha tirata, per 0,2 entro 250, per 0,5 vicino (350) a un suo compagno;
mai la borchia di prima. Per `LEVER.cool` = 90 tick dopo il fermo non si può ritirare (se no chi
atterra lì vicino la tira subito di nuovo). Il client cambia dipinto (`limbo_sotto`, lo stesso
disegno specchiato con la luce dall'alto: `tools/grafica/mappe_dipinte.py`, `limbo(True)`),
ridisegna la maschera specchiata coi crateri e disegna la leva di Codex (`docs/handoff/WB-099`, ritagliata
da `tools/grafica/leva.py`). I bot non la vedono ancora (niente `risk`): non la tirano apposta.

## Violenza, Frode, Tradimento e Lucifero (terzo blocco)

| Mappa | Pericolo | Numeri (`config.lua` e `maps.lua`) |
|---|---|---|
| Flegetonte | il fiume di sangue uccide (si cade, come nelle altre gole); tre sassi per passare; i tronchi morti sono terreno che si spezza e fermano i colpi finché non li rompi; due pozze di sangue (`blood`) bruciano | stato «bruciatura» già esistente |
| Sabbione | pioggia di fuoco: la grandine con `FIRE_RAIN` (4 chicchi, 30 di danno al centro) e ogni chicco dà bruciatura; piatto, senza ripari | `C.FIRE_RAIN` |
| Malebolge | due fosse di pece larghe 54 con un ponte crepato ciascuna: quando un robot ci sale, o un colpo gli toglie celle, trema (rettangolo arancione) e dopo `BRIDGE.delay` = 150 tick cade (`carve` a cerchietti, così il client online scava uguale) | `C.BRIDGE`, `hz.t`, `hz.solid` |
| Cocito | lastre di ghiaccio sottili sull'acqua gelata, separate da crepe di 28; chi smette di camminare scivola (`ICE`: decade del 3% a tick, al massimo 1,2 per tick); le esplosioni bucano e sotto si muore | `C.ICE`, `hz.vel`, `hz.prev` |
| Lucifero (arena, non online) | il lago largo col pozzo in mezzo (160) e due lastre per passarlo; ghiaccio che scivola e `wings`: a fine giro ognuno è spinto di `WIND.step` lontano dal centro (i bordi sono il vuoto: chi sta sul ciglio cade); la sua battaglia in tre fasi è una missione (Copione), non c'è ancora | `maps.OFFLINE` |

Scelte di Claude (11 nov): i ponti falsi sono quelli dipinti crepati (tutti crollano, nessuno a caso:
si vedono); quanto è largo il ponte (54 = 81 unità del mondo) e `delay` sono fatti perché lo
si attraversi di corsa senza fermarsi (si cammina a circa 0,65 unità per tick) e non se ci si
ferma; la scivolata è un attrito, non una fisica nuova: resta in `hz`, quindi niente campi nei
robot;
Lucifero ha una mappa propria fuori dalla rotazione perché la sua battaglia è una missione.

Niente muretti ai lati (Sergio, 11 nov): il suolo arriva al bordo e oltre si cade; i muri di lato restano solo nel cortile. Le mappe dei gironi sono asimmetriche, ma tengono l'assetto che serve ai loro pericoli.

## Il secondo blocco

| Mappa | Pericolo | Numeri (`config.lua` e `maps.lua`) |
|---|---|---|
| Avarizia | i massi: a fine giro ne parte uno da ogni pendio (`rocks = { { x, dir } }`), rotola verso il piano (più veloce in discesa, rallenta in salita e sul piano) e si sbriciola quando si ferma, cade in un buco o trova un muro; chi tocca prende `BOULDER.damage` = 22 una volta e viene spinto di `shove` = 18 | `BOULDER` (raggio 33, velocità massima 300), il turno non finisce finché un masso rotola |
| Ira | l'acqua che sale: parte da `water.y` = 90; dal terzo giro (`WATER.from`) sale di `WATER.step` = 40 a fine giro, e chi sta sotto la superficie annega (come cadere dalla mappa); una linea gialla dice dove arriverà (`hz.rise`) | cinque isolotti bassi che si coprono in cinque giri, palafitte alte |
| Eresia | le tombe: quattro vani bassi nel pavimento (`tombs`, si esce camminando); a giri alterni si aprono due sì e due no (`hz.phase`); in una aperta chi sta dentro prende lo stato «brucia» (17 a inizio turno), nelle chiuse no | i rettangoli in `maps.lua` e `ERES_TOMBE` in `mappe_dipinte.py` vanno tenuti uguali (un test controlla il fondo) |

Scelte di Claude (11 nov): niente terreno aggiunto dai pericoli (il server manda solo i crateri
scavati, quindi un masso fermo non resta come riparo: si sbriciola, e le tombe chiuse sono un
coperchio disegnato, non un muro; il vano basso fa già da riparo dai colpi); le tombe sono basse
(18 unità) per non intrappolare chi ci cade; l'acqua è disegnata dal gioco e non dipinta nella
mappa, così sale. Non fatto: i globi del teletrasporto dell'Ira e le torri con le fiaccole (sono dei livelli).
Forma delle mappe (Sergio, 11 nov): niente muretti ai lati (restano solo nel Cortile) e i bordi possono essere mortali; più asimmetria. Avarizia ha un pendio lungo a sinistra e uno corto con gradino a destra, l'Ira isolotti di larghezze diverse, l'Eresia un terrazzo a sinistra, una rampa e un gradino in giù a destra.

## Lo sfondo

Ogni girone ha il suo sfondo fatto a mano in `tools/grafica/gironi/sfondi.py` (un luogo riconoscibile a
più piani, con le luci accese e il buio che sale dal fondo, come il cortile): un girone nuovo aggiunge lì
la sua scena. Una mappa più piccola si fa con `stringi` di `mappe_dipinte.py` (Gola, Sabbione, Cocito),
e i suoi numeri in `client/sim/maps.lua` (spawn, rettangoli dei pericoli) vanno stretti uguali.


## Il bot e i pericoli (rischio)

Un pericolo dei giri può avere `risk(g, hz)` in `KINDS`: restituisce `f(rb)`, i punti vita
che quel robot perderebbe se restasse dov'è fino al prossimo fine giro (`hazards.DEATH`: muore).
È l'unica cosa del pericolo che vede il bot (`hazards.risk(g)`, nil se la mappa non ne ha):
niente casi per mappa. Ogni pericolo nuovo con un `risk` è subito evitato dai bot.

| Pericolo | Rischio |
|---|---|
| bufera, ali | muore se la spinta (`WIND.step`) lo porta nel vuoto |
| ghiaccio | muore se la scivolata nel verso in cui guarda lo porta nel vuoto |
| grandine, pioggia di fuoco | il danno dei chicchi annunciati o in volo, dal punto dove atterrano (sotto un tetto è meno) |
| ponti | muore sopra un ponte che regge |
| massi | il danno se è sulla strada di un masso che rotola o che partirà (`roll_on`, provato da solo) |
| acqua | muore sotto la superficie del prossimo giro, 8 se è a meno di un passo sopra |
| tombe | 17 (la bruciatura) in qualunque tomba |

In `bot.lua` (`peril`): per la squadra del bot il rischio è una perdita come un colpo (e la morte
pesa `morte`), per gli avversari un quarto è un guadagno (un colpo che li lascia sulla strada
dell'acqua vale di più). Per scegliere da dove attaccare conta il 40% (si può lasciare il
posto dopo), per il riparo del tutto. Il grado conta: `pericolo` in `M.LEVELS` (tutorial 0,
facile 0,5, normale 0,8, difficile 1): i gradi bassi cadono ancora ogni tanto in acqua.
Non fatto: percorso (il bot controlla dove finisce, non cosa attraversa), ghiaccio per chi non
cammina, ponti che stanno già tremando in base ai tick rimasti.
