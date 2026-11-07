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
| `giocatori` | chi gioca: `team`, `bot` (grado 1-10), `dummy` (fantoccio), `carattere`, `pick`, `secondary`, `nome`, `battute`, `pelle`, `insegna` (Favilla vera che mostra le mosse, sotto) |
| `nascosti` | robot che non ci sono (il gioco ne vuole almeno due) |
| `vedi` | cosa mostra l'HUD nelle lezioni (`missile`, `primarie`, `secondarie`, `teleport`, `parachute`, `tempo`, `punti`, `baratto`...) |
| `no_weapons`, `without_time` | parti senza armi; niente cronometro né turni |
| `goal_text`, `highlight` | la prima riga, nella vignetta grande d'apertura, e il comando che accende |
| `obiettivo` | i passi, in ordine, ognuno col suo `testo` (la scritta d'oro) |
| `righe` | quello che si dice durante il livello (sotto) |
| `casse`, `cards` | `{ dopo = passo, arma, x }`: dopo quel passo (0: subito) cade la cassa lì, o si apre la carta dell'arma (`give`: e te la dà) |
| `guida`, `scintilla` | Favilla comparsa nel cortile: da quale passo parte e il suo percorso `{ x, y, t, salto }` (corre mentre giochi); la scintilla della medaglia |
| `dimostra` | Favilla vera che ti mostra le mosse facendole (sotto) |
| `globi`, `globi_tempo`, `vita`, `punti`, `regrow`, `al_posto`, `secondi`, `al_tempo`, `turni`, `plans` | regole della partita (vedi l'intestazione di `missions.lua`; `globi_tempo`: i secondi risparmiati diventano globi) |
| `stelle`, `medaglia`, `collaudo` | stelle dei gironi, medaglia delle lezioni, come lo prova il bot |
| `bravo`, `bravo_faccia` | il «bravo» di Favilla quando l'ultimo passo è fatto (faccia: senza, `ride`) |

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

`nuova = true`: in questo passo il giocatore impara una mossa nuova. Il principio di
Sergio (6 nov) è **spiega, mostra, tocca a te, bravo**: prima del passo (fra la mossa
nuova di prima e questa) ci devono essere una vignetta grande (o la frase d'apertura,
per la prima) e una dimostrazione di Favilla (o la comparsa `guida`), e quando il passo
è fatto una riga con la `faccia` che parte da lì (o `bravo` del livello, se è l'ultimo).
`strumenti/copione/controlla.lua` fallisce se ne manca uno («mossa nuova senza
«mostra»»), e il Copione lo segna in rosso sotto il passo. Le informazioni (una cosa
da sapere, non da fare) restano nella striscia; un'arma da cassa ha la sua carta.

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
- `faccia`: calma, ride, spiega, sorpresa, preoccupata, arrabbiata, fiera, triste. Una
  riga con la faccia che parte finito un passo è il «bravo» di quel passo.
- `secondi`: quanto resta nella striscia (senza: il tempo normale).

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
| `conta = "morti"`, `almeno = 1` | un contatore della missione (morti, globi, scintille, misses...) |
| `vicino = 250` | sei a meno di 250 pixel da Favilla (`insegna`): lei ti aspetta |

Esempio, dal Duello con Favilla:

```lua
{ testo = "Ora la secondaria, a destra del cronometro: toccala e colpisci", mostra = "grande",
	highlight = "secondaria",
	quando = { turno = 2, di_turno = "tu", usato = "primaria" },
	fino = { usato = "secondaria" } },
```

## Favilla mostra le mosse (`insegna`, `dimostra`)

Il principio di Sergio (6 nov): Favilla prima ti mostra una mossa facendola, poi la
fai tu. Per questo è un robot vero della tua squadra: un giocatore con
`insegna = true` (con `nome = "Favilla"`, `pelle = "favilla"` e un punto di partenza
suo). Non gioca turni suoi, non si fa male, i suoi colpi non fanno i tuoi passi e non è
mai d'intralcio: passa attraverso gli altri robot e loro attraverso lei. Nelle lezioni
senza globi non ne guadagna nemmeno lei.

`dimostra` è la lista delle sue dimostrazioni: `{ quando = {...}, mosse = {...} }`.
Quando vale `quando` (come per le righe; senza: subito), tu sei fermo nel tuo turno e la
vignetta grande di quel momento è stata letta (VAI: prima spiega, poi mostra),
il turno passa a lei: fa le mosse in ordine coi tasti e la fisica veri, la sua mira
si vede come la tua, e poi il turno torna a te com'era (il tempo resta fermo). Ogni
dimostrazione una volta sola. Dopo, le righe possono partire con
`quando = { evento = "demo_end" }`.

| Mossa | Cosa fa |
|---|---|
| `cammina = 900` | cammina fino a quella x (si ferma anche se cade da un bordo: dopo, il paracadute) |
| `salta = "destra"`, `"sinistra"`, `"su"` | salta pieno da quella parte e aspetta di atterrare; con `in_aria = true` passa alla mossa dopo appena smette di salire (il Tonante o il Maglio in cima al salto) |
| `arma = "missile"`, `angolo = 45`, `potenza = 0.7` | mira per un secondo (si vede) e spara; vale per ogni arma e attrezzo: `"sword"`, `"hook"` (rampino), `"teleport"` (globo), `"parachute"` (appena è in aria, senza mira), `"shield"`... Angolo in gradi: 0 a destra, 90 in su, 180 a sinistra; potenza da 0 a 1 (senza: 1). Poi aspetta che tutto sia fermo. `subito = true`: spara senza il secondo di mira (in aria). `verso = "destra"` o `"sinistra"`: intanto tiene premuto quel lato (col paracadute plana di lato, col Maglio sale sul pilastro), fino a `fino_a = x` se c'è |
| `aspetta = 1.5` | sta ferma tanti secondi |
| `dice = "Guarda!"` | la battuta sopra la testa, come i bot |
| `posa = "vittoria"`, `secondi = 1.5` | fa una clip delle animazioni (`vittoria`, `naso`, `sbadiglio`, `guarda_coda`, `colpito`...) |

Esempio:

```lua
giocatori = { { team = 1 }, { team = 2, dummy = true },
	{ team = 1, insegna = true, nome = "Favilla", pelle = "favilla" } },
dimostra = {
	{ quando = { vicino = 250 }, mosse = {
		{ dice = "Guarda: miro e lascio andare!" },
		{ arma = "missile", angolo = 30, potenza = 0.8 },
		{ posa = "vittoria", secondi = 1 } } },
},
righe = { { testo = "Ora tu!", quando = { evento = "demo_end" } } },
```

La comparsa (`guida`) resta per le gare e per accompagnarti mentre giochi: un
livello ha l'una o l'altra Favilla, non tutte e due.
