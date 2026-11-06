# Il copione dei livelli

Ogni livello della campagna è **solo dati** in `client/sim/levels.lua` (i capitoli,
in ordine e con le stelle che li aprono, in `client/sim/campaign.lua`). Il motore
che li fa girare è `client/sim/missions.lua`; il Copione (`strumenti/copione/`) è la
dashboard che li mostra e li cambia. Niente funzioni: un livello deve poter viaggiare
come testo verso la build web e verso la pagina. `luajit strumenti/copione/controlla.lua`
(dentro `tutti.sh`) controlla che tutto quello che segue stia in piedi.

Un verbo nuovo (un trigger, un obiettivo) si aggiunge una volta: in `missions.lua`,
in `controlla.lua`, in questa pagina e nel Copione.

## Il livello

| Campo | Cosa è |
|---|---|
| `id`, `titolo` | nome interno (non cambia mai: ci sono legate stelle e miniature) e nome che si legge |
| `tipo` | corsa, bersagli, duello, squadra, orda, resistenza, bottino, custode: solo per la carta e la cartolina |
| `mappa` oppure `arena` + `spawns` | una mappa del gioco, oppure i rettangoli d'acciaio `{ x, y, w, h }` e i punti di partenza `{ x, from }` (il primo è il tuo). Coordinate del mondo: 1920 x 1080, y verso l'alto |
| `giocatori` | chi gioca: `team`, `bot` (grado 1-10), `dummy` (fantoccio), `carattere`, `pick`, `secondary`, `nome`, `battute`, `pelle` |
| `nascosti` | robot che non ci sono (il gioco ne vuole almeno due) |
| `vedi` | cosa mostra l'HUD nelle lezioni (`missile`, `primarie`, `secondarie`, `teleport`, `parachute`, `tempo`, `punti`, `baratto`...) |
| `no_weapons`, `without_time` | parti senza armi; niente cronometro né turni |
| `goal_text`, `highlight` | la prima riga, nella vignetta grande d'apertura, e il comando che accende |
| `obiettivo` | i passi, in ordine, ognuno col suo `testo` (la scritta d'oro) |
| `righe` | quello che si dice durante il livello (sotto) |
| `casse`, `cards` | `{ dopo = passo, arma, x }`: dopo quel passo (0: subito) cade la cassa lì, o si apre la carta dell'arma (`give`: e te la dà) |
| `guida`, `scintilla` | Favilla nel cortile: da quale passo parte e il suo percorso `{ x, y, t, salto }`; la scintilla della medaglia |
| `globi`, `vita`, `punti`, `regrow`, `al_posto`, `secondi`, `al_tempo`, `turni`, `plans` | regole della partita (vedi l'intestazione di `missions.lua`) |
| `stelle`, `medaglia`, `collaudo` | stelle dei gironi, medaglia delle lezioni, come lo prova il bot |

## I passi dell'obiettivo

| Verbo | Fatto quando |
|---|---|
| `reach = { x, y }` (`flag`: con la bandiera) | sei in piedi sopra quell'altezza, oltre quella x |
| `prendi = arma` | prendi la cassa con quell'arma |
| `hit = robot`, `con = arma` | colpisci quel robot (con quell'arma) |
| `down = robot` o `"nemico"`, `come = "vuoto"`, `times` | abbatti (nel vuoto, N volte) |
| `usa = "globi"`, `"rampino"`, `"pogo"`, `"kickback"`, `"paracadute"`, `"baratto"` | usi quella mossa |
| `win = true` | la tua squadra vince |

Nelle lezioni: `only` (cosa si può usare finché il passo non è fatto), `zoom`.

## Le righe

Una riga: `testo` (con i segnaposto `{salta}`, `{cammina}`, `{mira}`, `{annulla}`,
che diventano il gesto dei comandi che hai), `quando` parte, `fino` a quando resta,
`highlight` (il comando che lampeggia), `mostra`, `faccia`, `subito`, `stops`.

- `mostra = "grande"`: il gioco si ferma sulla vignetta grande col disegno del comando
  e va avanti solo con VAI; poi la riga resta nella striscia. Senza: solo la striscia
  in alto, il gioco non si ferma. La vignetta grande è delle lezioni.
- `highlight`: nelle lezioni il tempo resta fermo finché non tocchi quel comando
  (`stops = false`: solo la luce, per le righe che arrivano in aria).
- `subito`: la riga prende il posto di quella che c'è (la mira è già partita).
- `faccia`: calma, ride, spiega, sorpresa, preoccupata, arrabbiata, fiera, triste.

## I trigger (`quando`, `fino`)

Una tabella di condizioni: devono valere **tutte**. `uno = { {...}, {...} }` vale se
ne vale una.

| Condizione | Vale quando |
|---|---|
| `passo = 2` | il passo 2 è fatto |
| `turno = 2` / `turno_altri = 2` | è il tuo secondo turno / il secondo turno degli altri |
| `di_turno = "tu"` o `"altri"` | di chi è il turno adesso |
| `evento = "crate_pick"` | succede quell'evento della simulazione; `di = "tu"` o `"altri"` (senza: tuo o di nessuno), `arma = "punch"` |
| `tocca = "mira"` | in questo turno hai toccato quel comando |
| `usato = "primaria"`, `"secondaria"`, `"attrezzo"` | in questo turno l'hai già usato |
| `finestra = true` | dopo il primo attacco, finché la sua finestra è aperta |
| `in_caduta = true` | stai cadendo veloce e hai ancora il paracadute |
| `corona = "tu"` | sei primo |
| `conta = "prima"`, `almeno = 1` | un contatore della missione (morti, globi, scintille, prima...) |

Esempio, dal Duello con Favilla:

```lua
{ testo = "Ora la secondaria, a destra del cronometro: toccala e colpisci", mostra = "grande",
	highlight = "secondaria",
	quando = { turno = 2, di_turno = "tu", usato = "primaria" },
	fino = { usato = "secondaria" } },
```
