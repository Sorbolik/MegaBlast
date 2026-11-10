# OPT-001 · Ottimizzazione Prestazioni Senza Degrado Grafico

- **Stato:** ESEGUITA IN PARTE (4 nov, Claude: vedi il resoconto in fondo)
- **Data:** 2026-11-04
- **Autore:** Codex / Antigravity
- **Destinatario:** Claude (Coordinatore del progetto MegaBlast) e Sergio (Direttore del gioco)
- **Vincolo primario:** **Zero degrado grafico** (nessuna riduzione di risoluzione, nessun abbassamento di densità texture, nessuna compressione lossy con artefatti visibili, preservazione del 100% dei dettagli visivi).

---

## 1. Obiettivo e Quadro di Riferimento

Garantire fluidità impeccabile a **60 Hz, 120 Hz e 165 Hz** (dai telefoni economici al PC di Sergio con schermo 2560×1600 @ 165 Hz), eliminando alla radice gli scatti (*stutters*) censiti in `docs/prestazioni.md` senza intaccare in alcun modo l'alta fedeltà visiva approvata da Sergio (decisione del 2 nov: *"il livello di dettaglio migliore possibile"*).

### Le Evidenze Attuali (da `docs/prestazioni.md` e test sul campo)
1. **Scatti `motore` sul PC di Sergio (RTX 4060, 2560×1600 @ 165 Hz)**: il frame normale gira in 6 ms, ma molti frame oscillano tra 10 ms e 18 ms (perdendo 1 o 2 refresh di vsync). In quei frame il tempo `lua` è quasi zero (0–1 ms): la causa risiede interamente nel sovraccarico di disegno/GPU (pixel shader bottleneck). A 165 Hz il budget per frame è di soli **6,06 ms**: qualsiasi micro-picco nel fragment shader fa slittare il frame al ciclo successivo (12,1 ms o 18,2 ms).
2. **Spike di caricamento ed entrata mappa (`maschera`, `dipinto`)**: entrare in missione o riprovare una mappa dopo una caduta genera picchi fino a 155 ms di puro tempo Lua su telefono Android per la riscrittura cella per cella del buffer della maschera.
3. **Scatti periodici `gc` (Garbage Collector)**: piccole allocazioni a ogni tick/frame nelle tabelle di input, vettori matematici e buffer temporanei che accumulano spazzatura e innescano cicli completi del GC.

---

## 2. Diagnosi Dettagliata e Interventi di Ottimizzazione

### AREA A: GPU & Fragment Shader (`client/battle/terrain.fp`)

#### A.1 Eliminazione delle chiamate trascendenti `pow()` per-fragment in `fila()`
- **File:** `client/battle/terrain.fp` (righe 78–81)
- **Diagnosi:**
  La funzione `fila` calcola il parallasse di ogni striscia di sfondo:
  ```glsl
  highp vec2 fila(highp vec2 camera, highp float quanto)
  {
      return CENTRO + (camera - CENTRO) * quanto + (schermo() - CENTRO) * pow(zoom(), -quanto);
  }
  ```
  `fila()` viene chiamata **5 volte per pixel**:
  1. `fila(camera, 0.02)` (cielo)
  2. `fila(camera, striscia1.z)` (lontano)
  3. `fila(camera, striscia2.z)` (medio)
  4. `fila(camera, 0.8)` (braci procedurali)
  5. `fila(camera, striscia3.z)` (davanti)

  A 2560×1600 ci sono **4.096.000 pixel**. A 165 Hz, la GPU esegue fino a **20,5 milioni di `pow()` per frame**, ovvero oltre **3,3 miliardi di operazioni trascendenti al secondo**!
  `zoom()` è dato da `var_zoom * opzioni.z`: entrambi sono costanti e uniformi per l'intero schermo durante un singolo frame. `quanto` per ciascuna striscia è un valore uniforme fisso (`0.02`, `s.z`, `0.8`).
  Calcolare `pow()` sui vettori per ogni singolo frammento satura le Special Function Units (SFU) della GPU.
- **Soluzione a Zero Perdita Grafica:**
  Sostituzione algebrica pura. Sapendo che `camera = var_uv * MONDO - (schermo() - CENTRO) / zoom()`, si ricava:
  $$\text{fila}(\text{camera}, q) = \text{CENTRO} + (\text{var\_uv} \cdot \text{MONDO} - \text{CENTRO}) \cdot q + (\text{schermo}() - \text{CENTRO}) \cdot \left(\text{zoom}^{-q} - \frac{q}{\text{zoom}}\right)$$
  Il coefficiente di scala:
  $$k = \text{zoom}^{-q} - \frac{q}{\text{zoom}}$$
  è rigorosamente **uniforme per l'intero frame**. Può essere precalcolato una sola volta per frame su CPU in `client/battle/terrain.script` o nel vertex shader `client/battle/terrain.vp`.
  Nel fragment shader, `fila()` collassa in sole 2 istruzioni hardware FMA (Fused Multiply-Add):
  ```glsl
  return CENTRO + d_uv * quanto + d_schermo * k;
  ```
  Zero chiamate a `pow()`, zero divisioni. Il risultato a schermo è identico al bit.

#### A.2 Early-Exit nel calcolo del rumore procedurale delle braci
- **File:** `client/battle/terrain.fp` (righe 84–94)
- **Diagnosi:**
  La funzione `braci()` genera le particelle procedurali nello sfondo:
  ```glsl
  highp float r = caso(cella.x * 7.31 + cella.y * 91.7);
  highp vec2 punto = (vec2(caso(r * 53.1 + 1.0), caso(r * 17.9 + 2.0)) * 0.8 + 0.1) * 52.0;
  highp float d = length(q - cella * 52.0 - punto);
  return step(0.72, r) * smoothstep(2.4, 0.3, d) * (0.55 + 0.45 * sin(t * 2.7 + r * 40.0));
  ```
  Il fattore `step(0.72, r)` è pari a zero per il **72% delle celle**. Nonostante ciò, lo shader esegue incondizionatamente altri 2 calcoli di hash `caso()`, un `length()`, uno `smoothstep()` e un `sin()`.
- **Soluzione:**
  Aggiungere un early-reject immediato:
  ```glsl
  if (r < 0.72) return 0.0;
  ```
  Nei moderni processori grafici con execution masking su quad 2x2, intere tessere di sfondo saltano l'ALU superflua. Resa visiva identica al 100%.

---

### AREA B: Allocazioni Garbage Collector nel Game Loop (`kb_frame`)

La regola di Sergio del 19 ottobre stabilisce: *"niente allocazioni a ogni frame (tabelle, stringhe, vettori nuovi)"*. Ogni allocazione aumenta la frequenza dei cicli GC di Lua (`scatto: gc`).

#### B.1 Tabella `input` riallocata a ogni tick di simulazione
- **File:** `client/main/game.gui_script` (righe 3842–3850)
- **Diagnosi:**
  Nel ciclo `while self.acc >= game.DT` (60 volte al secondo):
  ```lua
  local input = {
      left = move_left(self),
      right = move_right(self),
      jump = self.jump_pressed or jump_held(self) or false,
      hold = jump_held(self) or false,
      fire = self.fire,
  }
  ```
  Viene creata e distrutta una tabella Lua a ogni tick (3.600 tabelle al minuto).
- **Soluzione:**
  Pre-allocare `self.sim_input = { left = false, right = false, jump = false, hold = false, fire = nil }` in `init()` e riassegnarne i campi nel loop senza creare tabelle nuove.

#### B.2 Allocazioni continue di `vmath.vector3` in `battle/items.lua`
- **File:** `client/battle/items.lua` (righe 44–46)
- **Diagnosi:**
  In `items.lua`:
  ```lua
  local function pos(n, x, y)
      gui.set_position(n, vmath.vector3(x, y, 0))
  end
  ```
  `pos()` viene richiamata decine di volte per frame durante `update()` per anelli di cura, scintille, trappole, scudi e status (fiamme, gelo, crepe). A ogni chiamata istanzia un nuovo `vmath.vector3`. In una partita con 4 giocatori e oggetti attivi, vengono creati tra i 500 e i 1.000 vettori al secondo.
- **Soluzione:**
  Riutilizzare un vettore statico a livello di modulo (come già fatto correttamente in `scoria.lua` e `plate.lua`):
  ```lua
  local V = vmath.vector3(0, 0, 0)
  local function pos(n, x, y)
      V.x, V.y = x, y
      gui.set_position(n, V)
  end
  ```

#### B.3 Allocazione buffer transitorio per ogni cratere (`buffer.create`)
- **File:** `client/main/game.gui_script` (riga 388)
- **Diagnosi:**
  Nella funzione `redraw_cells`:
  ```lua
  local buf = buffer.create(w * h, MASK_FORMAT)
  ```
  A ogni esplosione che scava il terreno viene creato un nuovo oggetto buffer Defold nativo di dimensione `w * h`, usato per caricare il rettangolo sulla texture via `resource.set_texture` e poi abbandonato al GC.
- **Soluzione:**
  Pre-allocare un buffer riutilizzabile `self.crater_buf` dimensionato per l'esplosione massima (`MAX_CRATER_CELLS`, circa 64×64 celle = 16 KB). Se il rettangolo rientra nei limiti, riutilizzare lo stesso buffer; allocare un buffer nuovo solo se eccezionalmente superiore.

#### B.4 Chiusure ed allocazione tabelle in `scoria.lua:levels()`
- **File:** `client/battle/scoria.lua` (righe 337–352)
- **Diagnosi:**
  Ogni volta che l'ordine dei layer visivi cambia (`s.z_order ~= l`):
  ```lua
  local steps_count, first_one = {}, nil
  local function above(nome) ... end
  ```
  Viene creata una tabella temporanea `steps_count` e una closure `above`.
- **Soluzione:**
  Definire `above` come funzione locale statica fuori da `levels` e riutilizzare una tabella fissa `steps_count` azzerata con un id/contatore progressivo.

---

### AREA C: Inizializzazione e Reset Maschera Terreno (Fino a 155 ms di Freeze)

#### C.1 Loop di 230.400 celle in puro Lua in `paint_terrain()`
- **File:** `client/main/game.gui_script` (righe 351–364)
- **Diagnosi:**
  Quando si ridisegna la maschera completa (entrando in partita o riprovando un livello), il codice esegue un loop su tutte le celle del mondo (640 × 360 = 230.400):
  ```lua
  for i = 1, TW * TH do
      local v = data[i] ~= 0 and 255 or 0
      local j = i * 4 - 3
      st[j], st[j + 1], st[j + 2], st[j + 3] = v, v, 255, 255
  end
  ```
  In Defold, lo stream `st` è esposto a Lua con metametodi C (`CheckBufferStream`). Questo loop esegue **921.600 chiamate C-Lua bridge individuali**, impiegando ~30 ms su PC e fino a **155 ms su dispositivi Android** (come annotato nel codice a riga 407).
- **Soluzione a Zero Perdita Grafica:**
  1. **Template Buffer Pristino per le Mappe Ufficiali**: MegaBlast ha attualmente solo due mappe competitive in rotazione (`pavimento` e `fossa`). All'avvio, il buffer pristino delle due mappe può essere conservato in memoria come template immutabile.
  2. **Fast Reset**: Quando si riavvia una partita o si ritenta un livello (`RIPROVA`), la funzione `CR.undig()` (linea 408) ripristina già con successo solo i rettangoli scavati in meno di 1 ms. Estendere questo approccio in modo che `paint_terrain` non riesegua mai il loop completo se la mappa non è cambiata.
  3. **Canali Invariati**: I canali B (distanza) e A sono costantemente pari a 255 nel buffer base; se serve riscrivere, toccare solo R e G riduce le operazioni del 50%.

---

### AREA D: GUI Batching e Ridondanze C-Bridge

#### D.1 Chiamate C-Bridge ridondanti in `client/battle/plate.lua`
- **File:** `client/battle/plate.lua` (righe 266–268)
- **Diagnosi:**
  A ogni frame, per ciascun robot presente (fino a 4):
  ```lua
  span(t.trail, 0, W * t.trail_f)
  span(t.full, 0, W * t.hp_f)
  span(t.scudo, W * t.hp_f, W * t.shield_f)
  ```
  La funzione `span` invoca incondizionatamente:
  - `gui.set_enabled(n, w > 0.05)`
  - `gui.set_position(n, V)`
  - `gui.set_size(n, V)`
  Nei frame in cui vita, scia e scudo rimangono stazionari (la maggioranza dei frame di gioco), vengono comunque effettuate 36 chiamate C-Bridge ogni singolo frame.
- **Soluzione:**
  Aggiungere un controllo di modifica (*dirty flag*):
  ```lua
  if w ~= n_last_w or x ~= n_last_x then ... end
  ```
  Nessuna chiamata GUI inviata a meno che i valori non siano effettivamente cambiati.

#### D.2 Suddivisione dei batch di disegno tra Corpo e Armi
- **File:** `client/battle/scoria.lua` (righe 356–358), `client/battle/devil.atlas`, `client/battle/weapons.atlas`
- **Diagnosi:**
  I pezzi anatomici del diavoletto risiedono in `devil.atlas`, mentre le armi impugnate risiedono in `weapons.atlas`.
  Poiché l'arma impugnata è ordinata graficamente tra il busto e il braccio anteriore (`... busto -> arma -> braccio_a ...`), il renderer GUI di Defold (che disegna da dietro in avanti) deve forzatamente:
  1. Disegnare i pezzi posteriori (atlas: `devil`)
  2. Spezzare il batch e cambiare texture su GPU (atlas: `weapons`) per disegnare l'arma
  3. Spezzare nuovamente il batch e cambiare texture su GPU (atlas: `devil`) per disegnare braccio e mano anteriori
  Questo genera 3 draw call per robot. In match 2v2 o FFA (4 robot), solo i personaggi consumano 12 draw call con continui cambi di texture.
- **Soluzione:**
  Nelle build di release, consolidare le texture usate durante la battaglia in un atlas unificato (o unire `devil` e `weapons` in un atlas battaglia condiviso). Un unico atlas consente a Defold di disegnare tutti e 4 i robot e le loro armi in **una sola draw call**.
  *Nota di garanzia qualitativa:* Le immagini restano al 100% PNG 32-bit non compresse con mipmap intatte, senza alcun ridimensionamento.

#### D.3 Unificazione dei materiali `flash.material` e `pieces.material`
- **File:** `client/battle/flash.fp`, `client/battle/pieces.fp`
- **Diagnosi:**
  Attualmente i pezzi che possono lampeggiare di bianco usano il materiale `lampo`, mentre gli altri usano `pezzi`.
  In `flash.fp`:
  ```glsl
  mediump float q = 1.0 - var_color.g / max(var_color.a, 0.0001);
  out_fragColor = vec4(mix(t.rgb, vec3(t.a), q), t.a) * var_color.a;
  ```
  Quando il robot non è colpito, `var_color.g == var_color.a`, il fattore `q` è esattamente 0.0 e l'output è matematicamente identico a `pieces.fp` (`out_fragColor = t * var_color`).
  Avere due materiali diversi forza Defold a cambiare stato shader durante il rendering dello stesso personaggio.
- **Soluzione:**
  Utilizzare `flash.material` per tutti i nodi del personaggio. Elimina i cambi di materiale tra nodi contigui senza alcuna differenza visiva.

---

### AREA E: Campionamento Animazioni e Curve Catmull-Rom (`battle/pose.lua`)

#### E.1 Precalcolo delle tangenti delle spline
- **File:** `client/battle/pose.lua` (righe 68–86)
- **Diagnosi:**
  In `animations.lua` ci sono 45 clip e 1.423 tracce totali. Per ogni traccia curva attiva, ad ogni frame `pose.valore()` invoca due volte `slope(tr, i, ...)` e `slope(tr, j, ...)`.
  All'interno di `slope()` vengono eseguiti controlli di indice, accessi a tabella e divisioni float per determinare la pendenza tra keyframe adiacenti.
  I keyframe delle animazioni sono **costanti statiche e immutabili** definite a monte.
- **Soluzione:**
  Precalcolare le tangenti `m` dei keyframe una volta sola durante il parsing iniziale di `animations.lua` (salvandole come array associato alla traccia).
  A runtime, la valutazione Catmull-Rom si riduce al solo calcolo dei coefficienti di Hermite (`2*u^3 - 3*u^2 + 1`, ecc.), eliminando i rami condizionali e le ricerche di vicinato. Risultato matematico dell'animazione: identico al 100%.

#### E.2 Iterazione canali in `pose.azzera()`
- **File:** `client/battle/pose.lua` (righe 52–56)
- **Diagnosi:**
  `for c, v in pairs(M.NEUTRAL) do p[c] = v end`
  L'uso di `pairs()` su una tabella hash di oltre 40 chiavi crea un iteratore e fa ricerche hash ripetute 60-120 volte al secondo per ogni robot.
- **Soluzione:**
  Poiché `M.CHANNELS` è già una tabella sequenziale indicizzata (`1..#M.CHANNELS`), scorrere con ciclo numerico diretto:
  ```lua
  for i = 1, #M.CHANNELS do
      local c = M.CHANNELS[i]
      p[c] = M.NEUTRAL[c]
  end
  ```
  Esecuzione lineare rapida, cache-friendly e ottimizzabile dal JIT.

---

## 3. Matrice Riassuntiva degli Interventi

| ID | Area | Descrizione Intervento | Guadagno Stimato | Impatto Visivo | Rischio |
|---|---|---|---|---|---|
| **OPT-A1** | GPU / Shader | Precalcolo uniformi del parallasse in `terrain.fp` (eliminazione `pow` per pixel) | **Risparmio di 2-5 ms per frame su GPU a 2560x1600 e 1080p**; azzera i frame persi a 165 Hz | **Identico al 100%** (equivalenza algebrica) | Minimo |
| **OPT-A2** | GPU / Shader | Early-reject `r < 0.72` nelle braci procedurali di `terrain.fp` | Riduzione ALU di ~70% sulle aree di sfondo non interessate da braci | **Identico al 100%** | Nullo |
| **OPT-B1** | Lua / Memoria | Preallocazione tabella `self.sim_input` in `game.gui_script` | -3.600 tabelle allocate/minuto; previene scatti da GC | **Nessuno** | Nullo |
| **OPT-B2** | Lua / Memoria | Vettore statico `V` riutilizzato in `battle/items.lua` | -30.000+ allocazioni `vector3`/minuto | **Nessuno** | Nullo |
| **OPT-B3** | Lua / Memoria | Buffer riutilizzabile `crater_buf` in `redraw_cells` | Elimina allocazioni native buffer a ogni esplosione | **Nessuno** | Nullo |
| **OPT-B4** | Lua / Memoria | Eliminazione closure e tabella temporanea in `scoria.levels()` | Nessuna allocazione al cambio clip animazione | **Nessuno** | Nullo |
| **OPT-C1** | Lua / Terreno | Template pristino per `pavimento` e `fossa` in `paint_terrain()` | **Elimina fino a 155 ms di blocco Lua** su smartphone all'avvio / restart | **Identico al 100%** | Basso |
| **OPT-D1** | GUI / Bridge | Dirty checking su barre vita e scudo in `plate.lua` | Risparmia ~36 chiamate C-Bridge al frame a riposo | **Nessuno** | Nullo |
| **OPT-D2** | GUI / Batch | Atlas unificato per personaggi e armi in battaglia | Riduce draw calls robot da 12 a 1-2 | **Identico al 100%** | Basso |
| **OPT-D3** | GUI / Batch | Unificazione `flash.material` e `pieces.material` | Elimina cambi materiale durante il rendering del robot | **Identico al 100%** | Nullo |
| **OPT-E1** | Animazioni | Precalcolo statico delle tangenti spline in `pose.lua` | Riduce il tempo di campionamento pose ad alto refresh | **Identico al 100%** | Minimo |
| **OPT-E2** | Animazioni | Scorrimento lineare indicizzato in `pose.azzera()` | Iterazione sequenziale senza hash iterator | **Nessuno** | Nullo |

---

## 4. Protocollo di Verifica e Controllo di Non-Regressione

Prima del merge di ciascun intervento:
1. **Controlli Sintassi e Globali:**
   ```bash
   python3 tools/controlli/globali.py
   python3 tools/simula/controlla.py client
   ```
2. **Suite di Test Deterministica (Lua & Go):**
   ```bash
   bash tools/controlli/tutti.sh
   ```
3. **Confronto Impronte Partite Bot (`confronta.py`):**
   Per gli interventi su simulazione o logica, verificare che 200 partite bot producano impronte tick per tick identiche:
   ```bash
   python3 tools/confronta/confronta.py --partite 200
   ```
4. **Misurazione Scatti con Contatore FPS:**
   Lanciare lo scenario di fluidità per confermare la riduzione del tempo peggiore e l'azzeramento degli scatti:
   ```bash
   python3 tools/simula/simula.py -s tools/simula/scenari/fluidita.txt --senza-video
   ```

---

## 5. Consegna di Codex (per Claude)

Questo report identifica le cause precise alla radice degli scatti rilevati su PC e smartphone, separando nettamente i colli di bottiglia GPU (pixel shader e parallasse) da quelli CPU (allocazioni GC e scrittura buffer cella per cella).
Tutti gli interventi proposti rispettano rigorosamente il vincolo di Sergio: **nessun abbassamento di qualità grafica, nessun cambio di asset, nessuna perdita di fedeltà visiva**.

Le modifiche sono modulari e possono essere affrontate in sequenza (ad esempio: prima GPU Shader OPT-A1/A2, poi Lua GC OPT-B1/B2/B3, infine Mask Buffer OPT-C1).

---

## Resoconto di Claude (4 nov)

Ogni proposta controllata sul codice e, dove si poteva, misurata nel simulatore. Sul
telefono di Sergio (contatore FPS, 4 nov) la home e la Forgia fanno già 116-120 FPS col
99% dei frame sotto 9-10 ms: i guadagni veri sono per il PC a 165 Hz e per i telefoni
economici.

**Applicate** (nessuna differenza sullo schermo):

- **A1** · niente `pow()` per pixel: `log2(zoom)` si calcola una volta in `sfondo()` e ogni
  fila fa solo `exp2(-quanto * lz)`, che è la stessa formula (i driver fanno `pow` proprio
  così). Più semplice del precalcolo su CPU proposto, che avrebbe chiesto lo zoom della
  vista allo script del terreno e costanti anche nel vertex shader.
- **A2** · braci: uscita anticipata se `r < 0.72` (stesso risultato di `step(0.72, r)`).
  A1 + A2: la home ferma a 2560 x 1440 nel simulatore (scenario `home_ferma.txt`,
  `--scala 2`, dove conta solo lo shader) passa da 60-61 a 51-52 ms per frame, il 15% in meno.
- **B2** · `items.lua`: un vettore solo per `pos()`.
- **E2** · `pose.azzera`: ciclo numerico su `CHANNELS` (le chiavi di `NEUTRAL` sono le stesse).

**Già fatta:** **C1** per RIPROVA e Ritenta (#196, `CR.undig`). Il ridisegno intero
resta solo entrando in una mappa nuova, sotto l'iride.

**Scartate:**

- **B1** (tabella `input` riusata): rompe le ricette. `replay.input` salva la tabella in
  `r.ultimo` e al tick dopo la confronta con quella nuova per decidere se scrivere i tasti:
  con la stessa tabella sarebbero sempre uguali e la ricetta perderebbe i tasti (replay e
  partite rigiocate sbagliati). Una tabella a tick è poca roba.
- **B3** (buffer riusato per i crateri): un buffer a esplosione, non a frame; e
  `resource.set_texture` vuole un buffer della misura del rettangolo.
- **B4** (`scoria.levels`): gira solo quando cambia l'ordine dei pezzi, non a frame.
- **C1 template per mappa**: entrare in una mappa nuova succede sotto l'iride e la
  prima volta va calcolata comunque; tenere 900 KB per mappa in memoria non serve.
- **D1** (`plate.lua`, controllo prima di `span`): 36 chiamate a frame sono microsecondi;
  in partita Lua lavora meno di 1 ms a frame.
- **D2** (un atlas solo per corpo e armi): il profiler dice 72 chiamate di disegno in
  tutto in una partita 2 contro 2, e il telefono fa 116-120 FPS; un atlas più grande
  pesa in memoria e sui limiti delle texture dei telefoni. Da rivedere solo se il
  contatore dice `motore` su un telefono.
- **D3** (`flash.material` per tutti i pezzi): non è uguale a `pieces.fp`. `flash.fp` usa del
  colore del nodo solo l'alfa (e il verde come quantità di lampo), mentre `pieces.fp`
  moltiplica per tutto il colore: i pezzi tinti (le squadre) perderebbero la tinta.
- **E1** (tangenti precalcolate): campionare le pose costa poco nel profilo di Lua e
  cambierebbe l'ordine delle operazioni sui numeri delle animazioni, che oggi tornano
  identiche all'editor.
