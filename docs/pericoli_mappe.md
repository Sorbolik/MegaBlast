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
| `gravity = 0.6` | la gravità di tutta la partita, per il valore: salti e tiri vanno più lontano | Limbo |
| `mud = { { x0, x1, y0, y1 } }` | rettangoli del mondo: chi sta a terra dentro prende lo stato «lento» (fino a fine del suo prossimo turno) | le pozze della Gola |
| `hazard = "wind"`, `"hail"`, `"boulders"`, `"water"` o `"tombs"` | un pericolo dei giri: la tabella `KINDS` di `hazards.lua` | Lussuria, Gola, Avarizia, Ira, Eresia |

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
mappa, così sale; il bot non vede massi, acqua né tombe (può restare su un isolotto che
affoga). Non fatto: i globi del teletrasporto dell'Ira e le torri con le fiaccole (sono dei livelli).
