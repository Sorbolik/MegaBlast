# La fisica di MegaBlast

Come si muovono robot, colpi ed esplosioni. I numeri veri sono nel codice:
`client/sim/game.lua` (fisica), `client/sim/config.lua` (regole e armi),
`client/sim/body.lua` (forme del corpo), `client/sim/melee.lua` (colpi corpo
a corpo), `client/battle/sticks.lua` (comandi sul telefono). La simulazione
è la stessa per client e server: chi la cambia, la cambia per tutti.

Qui si spiega il perché e come stanno insieme i pezzi. Se un numero qui e uno
nel codice non tornano, vale il codice (e va corretto questo documento).

## Unità

- La simulazione fa 60 tick al secondo, sempre (`M.DT`).
- Le distanze sono in pixel del mondo (mappe da 1920 × 1080).
- Molte grandezze sono scritte in **U**, un'unità legata all'altezza del robot
  di riferimento: `REF_H` = 28 px vale 3,612 U, quindi `U = 28 / 3,612 = 7,75 px`.
  Cambiando `REF_H` cambia tutto in proporzione: velocità, salti, esplosioni.
- Il diavoletto disegnato è `CORPO` = 1,4 volte più grande del robot di
  riferimento (`DISEGNO_H` = 39,2 px). Proiettili, casse e armi in mano sono
  disegnati per un robot alto 16 e poi ingranditi (nel client `K = 1,75`).

## Il robot

| Cosa | Valore | Nel codice |
|---|---|---|
| Gravità | 25 U/s² | `GRAVITY` |
| Corsa a terra e in aria | 5 U/s | `DEFAULT_STATS` |
| Altezza del salto | 5,2 U | `DEFAULT_STATS.jump_height` |
| Caduta senza danno | 40 U | `FALL_SAFE` |
| Danno da caduta | 1,25 ogni U in più, al massimo 75 | `FALL_DAMAGE`, `FALL_DAMAGE_MAX` |
| Vita | 100 | `config.STATS` |
| Danno a sé stessi | metà | `SELF_DAMAGE` |
| Gradino che sale da solo | 10,5 px | `MAX_CLIMB` |

L'equipaggiamento e l'albero di abilità cambiano queste statistiche
(`sim/gear.lua`, `sim/skills.lua`).

Come si muove (è la parte più importante per la sensazione di gioco):

- **Niente inerzia.** Tenendo una direzione la velocità orizzontale è subito
  quella di corsa, a terra e in aria; si cambia verso all'istante anche in aria.
- A terra senza comandi si ferma di colpo; in aria senza comandi tiene la
  velocità orizzontale che aveva.
- Il robot di turno non va mai di lato più veloce della sua corsa (col
  paracadute aperto il 50% in più), nemmeno dopo un'esplosione: può subito
  frenare o girarsi. Gli altri volano liberi.
- **Salto**: da terra, e anche per `COYOTE_TICKS` dopo essere scesi da un bordo;
  un salto chiesto poco prima di toccare terra parte all'atterraggio
  (`JUMP_BUFFER_TICKS`). Lasciando il tasto presto la salita si taglia
  (`JUMP_CUT`). Tenendo premuto risalta appena tocca terra.
- Il danno da caduta conta dal punto più alto raggiunto da quando ha iniziato
  a scendere, anche se ci è finito per un'esplosione.
- I robot sono solidi fra loro: camminando contro un altro lo si spinge piano.

### Le forme del corpo

Due forme, che si cambiano dall'editor delle animazioni (`sim/body.lua`):

- la **capsula per camminare** (largo 29,4, alto 39,2): urta il terreno, le
  casse e gli altri robot;
- il **cerchio dei colpi** (raggio 20,49, centro a 19,6 dai piedi): lo toccano
  proiettili, lame, pugni e globi. Per le esplosioni conta il quadrato attorno
  al cerchio, più largo di `HURT_FAT` per lato.

## Colpi e proiettili

La velocità di lancio cresce con la potenza fino al massimo dell'arma (la
curva della potenza è sotto, nei comandi). Poi il proiettile vola con la
gravità moltiplicata per un fattore dell'arma, rimbalza se l'arma rimbalza,
frena dopo il primo urto (`*_DAMPING`) e scoppia al contatto o allo scadere
del timer. Per `OWNER_SAFE_TICKS` dopo il lancio non tocca chi l'ha lanciato.

| Arma | Velocità massima | Gravità | Rimbalzo | Timer |
|---|---|---|---|---|
| Lanciarune (missile) | 75 U/s | ×1,1 | scoppia al contatto | |
| Uovo di Fiamma | 85 U/s | ×1,3 | 0,4, frenata 1/s dopo il primo urto | 5 s |
| Globo del teletrasporto | 80 U/s | ×1,1 | 0,4, frenata 1,1/s | 3 s |
| Sciame di Schegge | sempre uguale (la potenza non conta) | ×0,2 | | 8 schegge, una ogni 4 tick |
| Cecchino | sempre uguale | `config.SNIPER` | `config.SNIPER` | |

Le altre armi (Tonante, Maglio, Affondo, Mantice, Rampino, oggetti) hanno i
loro numeri in `config.lua`.

### Il teletrasporto

Il globo vola come il missile e rotola sul terreno. Dopo `TELEPORT_TICKS` il
robot appare dov'è il globo **nello stesso stato**: velocità, colpo in corso e
direzione restano quelli di prima. Non chiude il turno. Così funziona la combo
colpo dietro → teletrasporto → colpo davanti: chi viene toccato prima e dopo
il salto prende il danno una volta sola.

## Esplosioni

Ogni esplosione ha due raggi: il **cratere** (`r`) e il raggio del **danno e
della spinta** (`damage_r`, sempre più grande). Per ogni robot nel raggio:

- la distanza si misura dal centro dell'esplosione al **punto più vicino del
  quadrato** attorno al cerchio dei colpi (non dal centro del robot);
- `t = 1 − distanza / damage_r`;
- danno = `damage_min + t × (damage − damage_min)`, metà se è il proprio;
- spinta: la velocità del robot viene **sostituita** con
  `(punto più vicino − centro dell'esplosione) × impulse × t`, moltiplicata per
  quanto quel robot si fa spingere (`knockback_mul`, metà con lo scudo).
  Il vettore non è normalizzato, quindi la spinta è massima a metà raggio e
  **zero** nel colpo diretto: tanto danno, nessuna spinta.

| Esplosione | Cratere | Raggio del danno | Danno | Impulso |
|---|---|---|---|---|
| Lanciarune | 5 U | 9 U | 12,5–25 | 10 |
| Uovo di Fiamma | 5,5 U | 10 U | 25–80 | 15 |
| Scheggia | 12,25 px | 21 px | 0–11 | 30 |

## Colpi corpo a corpo

La Lama (fendente) e il Pugno del Titano (montante) sono fatti di tre pezzi
(`sim/melee.lua`):

1. **Un rettangolo lungo l'asse dell'arma** che segue la posa del colpo
   fotogramma per fotogramma (fendente largo 1 U, montante 3 U).
2. **Una finestra**: i colpi contano solo fra il fotogramma `apri` e `chiudi`.
   Chi tocca il rettangolo mentre è aperta viene segnato, e quando si chiude
   riceve il colpo una volta sola.
3. **La mira**: la posa è scritta per la mira dritta, ma gira tutta insieme
   alla mira. Mirando in basso il fendente cala dall'alto verso il basso,
   mirando in alto sale.

| Colpo | Durata | Finestra | Danno | Effetto |
|---|---|---|---|---|
| Fendente (Lama) | 70 fotogrammi a 75/s (0,93 s) | 20–60 | 25 | ferma il bersaglio |
| Montante (Pugno) | 95 fotogrammi a 45/s (2,1 s) | 5–20 | 47 | lancia dritto in alto a 40 U/s; chi colpisce fa un saltello di 15 U/s al fotogramma 10 |

Il fendente: dal fotogramma 0 al 30 la lama sale sopra la testa e va dietro
la schiena, dal 30 al 34 cala in avanti (il colpo vero), poi resta davanti e
torna a riposo. La finestra prende chi sta sopra e dietro durante la carica e
chi sta davanti durante la discesa: un arco di circa 200°.

Il Maglio è diverso: gira lungo un arco fisso (`config.MALLET`, curva
`arc_progress` in `game.lua`) e si ferma sul terreno.

Online il server manda anche l'angolo di mira del colpo (`sb`, `pb`), così il
client disegna la stessa posa.

## I comandi

Sul telefono ci sono due levette (`client/battle/sticks.lua`):

- **Levetta sinistra (movimento)**: di lato oltre il 15% cammina; inclinata in
  alto oltre 25° e spinta oltre il 25% salta, e risalta finché resta lì.
  Riportata al centro si ferma.
- **Levetta destra (mira)**: la direzione è la mira, la distanza dal centro la
  potenza. Sotto il 20% non mira (`AIM_DEADZONE`), poi la potenza cresce col
  quadrato (`AIM_EXPONENT` = 2): tanta precisione sui tiri corti. La mira
  insegue il dito (`AIM_SMOOTH`, a tempo e non a fotogrammi, uguale a 30, 60 o
  120 Hz). **Lasci e parte il colpo**, con la mira di 50 ms prima di staccare
  il pollice; riportandola sotto il 10% si spegne e lasciando non parte niente.
- La base di ogni levetta va dove appoggi il pollice, dentro la sua metà dello
  schermo, e torna al suo posto quando lo alzi.
- Per le armi corpo a corpo la potenza non conta: conta solo la direzione.

Sul computer: A/D o le frecce per muoversi, W, freccia su o spazio per
saltare, mira col mouse dal robot, tasto destro per annullare, T per il
teletrasporto, 1-9 per le armi (`client/input/game.input_binding`). Col controller: [controller.md](controller.md).

La mira mostra solo angolo e potenza, mai la traiettoria (la traiettoria
intera solo come aiuto nell'Addestramento).

## Turni e casse

Le durate sono in `config.lua`: turno di 25 s, dopo il primo attacco restano
al massimo `AFTER_ATTACK_SECONDS`, partita di 5 minuti, 1 s tra un turno e
l'altro. Dal secondo turno, a ogni turno può cadere una cassa con una
probabilità che dipende da quante ce ne sono già (`CRATE_CHANCE`: 90% con
nessuna, 50% con una, 30% con due; con `CRATE_MAX` = 3 in mappa non ne cadono
altre); eventi e missioni possono chiedere invece una cassa ogni tanti
turni (`opts.crate_every`).

## La rete

Il server fa girare la stessa simulazione Lua dei client (in LuaJIT anche lui)
ed è lui a decidere: i client mandano i tasti, non le posizioni. Per questo la
simulazione deve essere deterministica ([server.md](server.md)).
