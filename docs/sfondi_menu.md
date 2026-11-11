# Sfondi dei menu: una identità per ogni schermata

> **Superato l'11 nov** dall'interfaccia «Raggi» ([interfaccia_da_zero.md](interfaccia_da_zero.md)):
> ogni menu ora ha la scena coi raggi e il suo colore (`kit.scene`), e i temi qui sotto sono
> stati tolti da `client/ui/backdrop.lua`, che tiene solo il fondo pieno. Resta come storia;
> le regole sui contrasti valgono ancora.

Proposta del 5 novembre (Sergio: «dare un'identità in maniera simile ad ogni
schermata, quindi con un background semplice come quello della bacheca della
campagna, ma con la sua identità [...] stiamo attenti ai contrasti con i
testi»). La bacheca a tutto schermo è il primo tema (PR #218). **Approvate tutte**
(Sergio, 5 nov: «mi piacciono tutte») e fatte nella stessa PR, in
`client/ui/backdrop.lua`. Mockup fatti dalle foto vere
del simulatore: https://claude.ai/artifact/W6LDT6WtVB2fmgJQuprvED .

## Cosa resta uguale su tutte le schermate

- **La testata**: indietro in alto a sinistra, titolo a `ui.TITLE_X`, il posto
  della pillola al centro in alto (`ui.SLOT_W` x `ui.SLOT_H`), le schede sotto
  (`ui.TABS_Y`). Lo sfondo passa dietro, non cambia posizione a niente.
- **Pulsanti, pannelli, schede**: restano le sagome antracite col bordo chiaro
  (`ui.C.PANEL`, `ui.C.LINE`), uguali su ogni sfondo. Un pulsante non cambia
  mai aspetto né posto. Lo sfondo non tocca i colori dei comandi.
- **Il colore di ogni schermata viene dalla tacca della home** (UI-002): campagna
  oro (il legno), allenamento acciaio, armeria brace, eventi rosso. Chi tocca
  ARMERIA nella home trova lo stesso colore dietro l'ARMERIA.
- **Piatto, scuro, fermo**: solo forme piatte (rettangoli, dischi, anelli e
  l'alone dell'atlas `ui`), niente immagini dipinte (regola del 23 ott), niente
  movimento (il Limbo vivo resta solo dietro la home).
- **Su ogni proporzione**: lo sfondo copre 2 volte il quadro 1280 x 720 per lato
  (20:9, 4:3, pieghevoli quadrati). Quello che deve stare al bordo vero (l'alone
  in basso dell'armeria) si piazza con `screen.y0`, come `ui.root` usa `screen.y1`.

## Come si costruisce

Un tema per schermata in `client/ui/backdrop.lua` (c'è già, col tema `legno`):

```lua
a.fondo = backdrop.new("fucina")   -- al posto di ui.background()
```

Ogni tema colora la base di `ui.background()` e aggiunge le sue forme una volta,
alla creazione della schermata. Regole del modulo:

- **al massimo 200 nodi** per tema e **2 draw call**: prima tutti i rettangoli
  senza texture, poi le forme dell'atlas `ui` (dischi, anelli, alone);
- **nessun caso**: le variazioni (venature, giunte) vengono da una tabella fissa,
  lo sfondo è uguale ogni volta;
- i colori stanno in testa al tema come costanti, coi valori esadecimali qui
  sotto.

## Contrasti

Calcolati come WCAG 2.1 (rapporto di luminanza) contro **il pixel più chiaro di
ogni sfondo** (alone compresi), coi colori veri del testo di `ui.C`:

- testo normale `C.TEXT` `#F2E8D8`: almeno **7:1** (AAA) su ogni tema;
- testo spento `C.OFF` `#8C8484`: oggi sta sul nero (5,3:1), ma sui temi nuovi
  scende fra 3,7 e 4,4:1, sotto il 4,5:1 del testo piccolo. **Proposta: schiarire
  `C.OFF` a `#ACA4A0`** (una riga in `ui.lua`): sta sopra 4,5:1 su tutti i temi,
  legno compreso, e resta ben più spento di `C.TEXT` (rapporto 2:1 fra i due). Sul
  legno il suggerimento del capitolo chiuso tiene il crema `#C7B399` della #218 (6,2:1);
- colori delle squadre e degli accenti (`C.BRACE`, `C.GOLD`, rosso, blu): sul
  fondo nudo solo per testi grandi (sopra 3:1); il blu della squadra sul legno e
  sulla fucina sta a 2,9-3,0, quindi lì il testo blu va solo dentro i pannelli
  (oggi è già così).

| Tema | Pixel più chiaro | TEXT | OFF oggi | OFF `#ACA4A0` | GOLD | BLU squadra |
|---|---|---|---|---|---|---|
| legno (campagna) | `#54331C` | 9,3 | 3,1 | 4,6 | 6,9 | 2,9 |
| fucina (armeria) | `#4A3328` | 9,6 | 3,2 | 4,8 | 7,1 | 3,0 |
| campo (allenamento) | `#223042` | 11,0 | 3,7 | 5,5 | 8,1 | 3,5 |
| stendardi (eventi) | `#3A2414` | 12,0 | 4,0 | 5,9 | 8,9 | 3,8 |
| arena (gioca online) | `#2A2327` | 12,7 | 4,2 | 6,3 | 9,3 | 4,0 |
| banco (impostazioni) | `#1E222A` | 13,1 | 4,4 | 6,5 | 9,7 | 4,2 |
| camerino (profilo) | `#371A2B` | 12,9 | 4,3 | 6,4 | 9,5 | 4,1 |
| raggi (podio) | `#392B0E` | 11,3 | 3,8 | 5,6 | 8,4 | 3,6 |
| schieramento | `#2A2430` | 12,4 | 4,1 | 6,2 | 9,2 | 3,9 |

## Le schermate e il loro sfondo

Elenco preso dal codice (`client/menu/`): ogni modulo che chiama `ui.background()`.

### Restano come sono

- **Home** (`home.lua`): il Limbo vivo dei gironi (shader della GUI). È già
  l'identità del gioco: non si tocca.
- **Storia** (`story.lua`): fondo `#171212` dietro la cartolina delle tavole. La
  tavola è il quadro, uno sfondo con un disegno ci farebbe concorrenza.
- **Scelta delle armi** (`pick.lua`): è un velo `C.BOTTOM` all'86% sopra la mappa
  della partita; lo sfondo è già la mappa.
- **Sala d'attesa** (`lobby.lua`, CERCO GIOCATORI): sta già sopra il Limbo vivo
  della home, che si vede dietro i cartellini. Va bene così: si aspetta «a casa».
- **Cartolina della missione** (`ui/postcard.lua`): sta sopra la bacheca col suo
  velo, come oggi.

### 1. CAMPAGNA e fine del livello: «legno»

Fatto nella #218 per la bacheca. Proposta: **lo stesso legno dietro la fine del
livello** (`level_end.lua`), così la missione della campagna comincia e finisce
sulla bacheca. Base `#4A2B17`, asse alterna `#442814`, fessura `#3B2112`,
venatura `#54331C`. Circa 135 rettangoli.

### 2. ARMERIA: «fucina»

La parete della Forgia dove il Fabbro appende i pezzi: lastre di ferro chiodate
e la brace che illumina dal basso. Tacca della home: brace.

- base `#1A1311`; giunte fra le lastre `#100B0A` (4 px); lastre 320 x 240;
- un chiodo a ogni incrocio (disco 18 px `#2A201C` con il riflesso 8 px
  `#3A2C25`); nel mockup c'era anche un chiodo a metà delle giunte, tolto per stare
  sotto i 200 nodi;
- alone `C.BRACE` `#FF6B29` all'11% (additivo), 1600 px, centrato 120 px sotto il
  bordo vero in basso (`screen.y0`): più forte, il testo spento in basso scende
  sotto 4,5:1.
- Nodi: 16 giunte + 126 dischi + 1 alone.

### 3. ALLENAMENTO: «campo»

Il campo di prova: lavagna d'acciaio col reticolo a gesso e un bersaglio. Tacca:
acciaio.

- base `#141B24`; reticolo ogni 40 px `#1A2330` (2 px), ogni 160 px `#1F2A39` (3 px);
- bersaglio a destra del centro (1040, 300): quattro anelli (`ui.ring_node`)
  di diametro 660, 480, 300, 120 e spessore 6, `#223042`, più un disco di 36 px;
- nodi: circa 100 linee + 5 forme dell'atlas.

### 4. GIOCA ONLINE (DOVE GIOCHI?): «arena»

La schermata più importante. Il pavimento dell'arena visto dall'alto: cerchi
concentrici che salgono dal basso, e le luci delle quattro squadre che aspettano.

- base `#110F18`; dischi concentrici centrati 620 px sotto il centro, raggi da
  1300 a 200 ogni 110 px, alternati `#1C1826` e `#17141F` (12 dischi);
- quattro aloni additivi al 10%, 700 px, in basso, nei colori di
  `C.SQUADRA` (`#FF3B4E`, `#3D7BFF`, `#2EBF70`, `#F5C518`), da sinistra a destra.

### 5. EVENTI (bacheca e dettaglio): «stendardi»

I drappi degli eventi appesi nella sala: teli verticali color vino con le pieghe
e un filo d'oro. Tacca: rosso.

- base `#1E0C10`; un telo ogni due largo 150 px `#250F14`;
- piega a destra di ogni telo `#16080B` (4 px), filo al centro dei teli `#3A2414` (2 px);
- nodi: circa 50.

### 6. IMPOSTAZIONI: «banco»

Il banco da lavoro dei comandi, un foglio di progetto: neutro, come deve essere
una schermata tecnica, ma non più nero piatto.

- base `#13151A`; reticolo ogni 32 px `#181B21` (1 px), ogni 128 px `#1E222A` (2 px);
- nodi: circa 125 linee.

### 7. PROFILO (scheda, statistiche, partite): «camerino»

Il camerino del tuo diavoletto: carta da parati di velluto a righe e la luce del
tuo Nucleo dietro di lui.

- base `#17101C`; righe verticali larghe 24 px ogni 48 px `#1C1423`;
- l'alone del colore della tua squadra dietro il diavoletto c'è già nel profilo;
- nodi: circa 27.

### 8. PODIO: «raggi»

La vittoria: raggi d'oro che partono dal podio.

- base `#15100A`; 18 raggi (rettangoli 3400 x 70 ruotati di 10°) `#21180C`
  centrati sul podio (640, 200);
- alone `C.GOLD` `#F5C518` al 14%, 900 px, sopra il gradino più alto;
- nodi: 19.

### 9. SCHIERAMENTO prima della partita: «schieramento»

Le squadre una di fronte all'altra: lo schermo diviso in obliquo (8°) fra il
colore scuro della prima e della seconda squadra, la riga in mezzo dove sta «VS».

- sinistra `#1C0E12` (rosso scurito), destra `#0E1322` (blu scurito), riga
  `#2A2430` (6 px);
- con 3 o 4 squadre (tutti contro tutti) le fasce diventano 3 o 4, stessa regola;
- nodi: 3-5.

## Scartati, e perché

- **Immagini dipinte** dietro i menu (una per schermata, fatte da Codex): sono
  state tolte il 23 ottobre, pesano in memoria e su 20:9 vanno allungate o tagliate.
- **Uno shader vivo per ogni schermata**, come il Limbo della home: costa GPU
  a ogni frame su menu dove si legge, e la home perderebbe la sua particolarità.
- **Lo stesso sfondo con un colore diverso per schermata**: più semplice, ma
  dà meno identità di quella che Sergio chiede (la bacheca è un oggetto, non un colore).
- **Sfondi chiari** (pergamena, pietra chiara): il testo chiaro e i pannelli
  antracite andrebbero rifatti tutti; un tema deve restare scuro sotto il testo.
- **Mattoni per l'armeria**: con 40 x 120 px servono quasi 900 nodi; le lastre
  chiodate dicono la stessa forgia con 170.
- **Un'ombra ai bordi (vignetta)**: servirebbe un'immagine sfumata grande; l'alone
  che c'è già fa la stessa cosa dove serve (armeria, podio, profilo).

## Implementazione (fatta)

Nella #218: `C.OFF` a `#ACA4A0`, i temi in `backdrop.lua`, una riga in
ogni schermata (`backdrop.new("tema")` al posto di `ui.background()`), lo scenario
`menu_schermi.txt` esteso a tutte le schermate, foto a 4:3, 16:9 e 20:9.
