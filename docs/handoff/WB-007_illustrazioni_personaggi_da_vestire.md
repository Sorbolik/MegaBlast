# WB-007 · Illustrazioni della pagina "Personaggi da vestire"

- **Stato:** APPROVATA
- **Data:** 2026-11-01
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-007`

## Obiettivo

Le illustrazioni della pagina "Personaggi da vestire" (https://claude.ai/artifact/DkXLmSvd8MV597ZzNe3dnh)
le disegna ChatGPT nello stile di Sergio, al posto delle figure fatte tagliando i suoi disegni
(Sergio: "pezzi traballanti"). Sulle immagini il thread del designer costruisce il documento con
etichette e testi. Specifiche: `/mnt/project-files/gabriella/personaggi_vestibili/richiesta_immagini.md`.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/personaggi/maschio.png` | il maschio di Sergio, di fronte (disegno ufficiale) |
| R2 | `art/personaggi/femmina.png` | la femmina, di fronte |
| R3 | `art/personaggi/favilla.png` | Favilla, di fronte |
| R4 | `art/WB-002/espressioni.png` | le 9 espressioni approvate del maschio |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto: il primo è
"immagine 1", il secondo "immagine 2" e così via. Sfondo piatto color panna, non trasparente
(eccezione alla regola di `AGENTS.md`: sono illustrazioni per un documento).

| Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|
| `1_pezzi_A` | R1, R4 | 1536×1024 | 1 |
| `2_cammina_A` | R1 | 1536×1024 | 1 |
| `2_cammina_A_v2` | R1 | 1536×1024 | 1 |
| `3_facce` | R1, R3 | 1536×1024 | 1 |
| `4_livelli` | R1, R2, R3 | 1536×1024 | 1 |
| `5_equipaggiamento` | R1 | 1536×1024 | 1 |
| `6_proposta_B` | R2 | 1536×1024 | 1 |
| `7_proposta_C` | R3 | 1536×1024 | 1 |

### `1_pezzi_A`

```
Immagine 1 è il mio personaggio maschio, di fronte. Immagine 2 sono le sue espressioni approvate. Copia esattamente le forme, le proporzioni e lo stile del personaggio allegato: non reinterpretarlo, non aggiungere nasi, orecchie, capelli o dettagli.

Due modifiche rispetto al disegno allegato, valide per tutto: 1) sotto gli occhi c'è un MUSO bianco, una piccola forma ovale chiusa dal contorno nero, e la bocca sta DENTRO il muso (non galleggia più sul nero della testa); 2) braccia e gambe sono tubi neri morbidi e curvi, senza gomiti né ginocchia, che finiscono nel guanto bianco e nella scarpa nera.

Disegnalo smontato in vista esplosa, di fronte, con i pezzi ben distanziati fra loro (nessun pezzo tocca un altro) ma disposti più o meno dove stanno nel corpo, ognuno completo e chiuso tutto intorno dal contorno nero: la sagoma nera della testa a stella SENZA faccia; la faccia da sola (i due occhi bianchi con le pupille, il muso bianco con la bocca felice dentro); il busto (la maglietta nera); i pantaloncini bianchi; i due guanti bianchi; le due scarpe nere; quattro tubi neri separati: due braccia e due gambe.

Stile: ESATTAMENTE quello del mio personaggio allegato: bianco e nero piatto, cartone animato anni '30 (rubber hose), nero pieno e bianco pieno, contorno nero spesso e chiuso, nessuna sfumatura, nessun grigio, nessun colore. Sfondo piatto chiaro color panna (#F5F2EA), senza ombre a terra. Nessuna scritta, numero, etichetta o freccia. Formato orizzontale 3:2.
```

### `2_cammina_A`

```
Immagine 1 è il mio personaggio maschio, di fronte. Copia esattamente le forme, le proporzioni e lo stile del personaggio allegato: non reinterpretarlo, non aggiungere nasi, orecchie, capelli o dettagli.

Due modifiche rispetto al disegno allegato, valide per tutto: 1) sotto gli occhi c'è un MUSO bianco, una piccola forma ovale chiusa dal contorno nero, e la bocca sta DENTRO il muso (non galleggia più sul nero della testa); 2) braccia e gambe sono tubi neri morbidi e curvi, senza gomiti né ginocchia, che finiscono nel guanto bianco e nella scarpa nera.

Disegna 4 pose di camminata verso destra, in fila da sinistra a destra, tutte della stessa grandezza. Il corpo resta di fronte, ma il personaggio va a destra: la faccia (occhi e muso) è spostata verso destra sulla testa, con l'occhio di destra un po' più stretto di quello di sinistra; la sagoma della testa non cambia. Tutte e due le scarpe puntano a destra. Le gambe-tubo si alternano come in un vero passo (contatto, passaggio, contatto con l'altra gamba, passaggio) e le braccia-tubo oscillano opposte alle gambe.

Stile: ESATTAMENTE quello del mio personaggio allegato: bianco e nero piatto, cartone animato anni '30 (rubber hose), nero pieno e bianco pieno, contorno nero spesso e chiuso, nessuna sfumatura, nessun grigio, nessun colore. Sfondo piatto chiaro color panna (#F5F2EA), senza ombre a terra. Nessuna scritta, numero, etichetta o freccia. Formato orizzontale 3:2.
```

### `3_facce`

```
Immagine 1 è il mio personaggio maschio, immagine 2 è Favilla, la mia personaggia con la testa a fiamma. Copia esattamente le forme, le proporzioni e lo stile del personaggio allegato: non reinterpretarlo, non aggiungere nasi, orecchie, capelli o dettagli.

Modifica valida per tutto: sotto gli occhi c'è un MUSO bianco, una piccola forma ovale chiusa dal contorno nero, e la bocca felice sta DENTRO il muso.

Disegna solo le teste, 6 in tutto, in 2 righe da 3, ben separate, tutte della stessa grandezza. Riga 1: la testa del maschio che guarda a sinistra, davanti, a destra. Riga 2: la testa di Favilla (con le sue ciglia) che guarda a sinistra, davanti, a destra. La sagoma nera della testa resta IDENTICA nelle tre colonne: si spostano solo gli occhi e il muso, verso sinistra o verso destra, e l'occhio dal lato verso cui guarda diventa un po' più stretto.

Stile: ESATTAMENTE quello del mio personaggio allegato: bianco e nero piatto, cartone animato anni '30 (rubber hose), nero pieno e bianco pieno, contorno nero spesso e chiuso, nessuna sfumatura, nessun grigio, nessun colore. Sfondo piatto chiaro color panna (#F5F2EA), senza ombre a terra. Nessuna scritta, numero, etichetta o freccia. Formato orizzontale 3:2.
```

### `4_livelli`

```
Immagine 1 è il mio personaggio maschio, immagine 2 la femmina (uguale ma con le ciglia e la gonnellina), immagine 3 Favilla (testa a fiamma, ciglia, gonnellina). Copia esattamente le forme, le proporzioni e lo stile del personaggio allegato: non reinterpretarlo, non aggiungere nasi, orecchie, capelli o dettagli.

Due modifiche rispetto al disegno allegato, valide per tutto: 1) sotto gli occhi c'è un MUSO bianco, una piccola forma ovale chiusa dal contorno nero, e la bocca sta DENTRO il muso (non galleggia più sul nero della testa); 2) braccia e gambe sono tubi neri morbidi e curvi, senza gomiti né ginocchia, che finiscono nel guanto bianco e nella scarpa nera.

Disegna una griglia di 9 figure intere di fronte, 3 righe da 3, ben separate e tutte della stessa grandezza. Righe: maschio, femmina, Favilla. Colonne: lo stesso set di equipaggiamento a livello 1, 10 e 20.
Livello 1: un pettorale semplice sul petto e due bracciali sui tubi delle braccia, vicino ai polsi.
Livello 10: come il livello 1, più borchie e rifiniture sul pettorale, due spallacci sulle spalle e una cintura in vita.
Livello 20: come il livello 10, più una fascia sulla fronte con due piccole corna, ghette sopra le scarpe e dettagli di fuoco ROSSO sui pezzi dell'equipaggiamento.
Gli oggetti si appoggiano SOLO su fronte, petto, spalle, polsi, vita e caviglie: la sagoma della testa non cambia mai e la faccia resta scoperta. Il set è identico per i tre personaggi.

Stile: ESATTAMENTE quello del mio personaggio allegato: bianco e nero piatto, cartone animato anni '30 (rubber hose), nero pieno e bianco pieno, contorno nero spesso e chiuso, nessuna sfumatura, nessun grigio, nessun colore tranne il rosso del fuoco, solo nella colonna del livello 20. Sfondo piatto chiaro color panna (#F5F2EA), senza ombre a terra. Nessuna scritta, numero, etichetta o freccia. Formato orizzontale 3:2.
```

### `5_equipaggiamento`

```
Immagine 1 è il mio personaggio maschio, di fronte: serve solo per lo stile e per la grandezza dei pezzi rispetto al corpo.

Disegna un foglio di pezzi di equipaggiamento staccati, senza personaggio, visti di fronte, in 3 colonne: livello 1 (semplice), livello 10 (con borchie, rifiniture e bordi), livello 20 (più ricco, con piccole corna e dettagli di fuoco ROSSO). Una riga per ogni pezzo, nell'ordine: fascia o corona da fronte; elmo intero (prende il posto della sagoma della testa, ma lascia scoperti gli occhi e il muso); pettorale; spallaccio; bracciale da polso; cintura; stivale; mantello. Ogni pezzo è ben separato dagli altri e chiuso tutto intorno dal contorno nero spesso.

Stile: ESATTAMENTE quello del mio personaggio allegato: bianco e nero piatto, cartone animato anni '30 (rubber hose), nero pieno e bianco pieno, contorno nero spesso e chiuso, nessuna sfumatura, nessun grigio, nessun colore tranne il rosso del fuoco, solo nella colonna del livello 20. Sfondo piatto chiaro color panna (#F5F2EA), senza ombre a terra. Nessuna scritta, numero, etichetta o freccia. Formato orizzontale 3:2.
```

### `6_proposta_B`

```
Immagine 1 è la mia personaggia femmina, di fronte. Copia esattamente le forme, le proporzioni e lo stile del personaggio allegato: non reinterpretarlo, non aggiungere nasi, orecchie, capelli o dettagli.

Modifiche: sotto gli occhi c'è un MUSO bianco, una piccola forma ovale chiusa dal contorno nero, con la bocca felice dentro. Lei NON ha braccia né gambe: i due guanti bianchi e le due scarpe nere fluttuano staccati vicino al corpo, nel punto dove sarebbero mani e piedi, con un piccolo spazio vuoto fra loro e il corpo.

Disegnala due volte, affiancata, della stessa grandezza: a sinistra ferma, di fronte; a destra mentre cammina verso destra (corpo di fronte, faccia spostata verso destra, scarpe che puntano a destra e si alternano come in un passo, guanti che oscillano).

Stile: ESATTAMENTE quello del mio personaggio allegato: bianco e nero piatto, cartone animato anni '30 (rubber hose), nero pieno e bianco pieno, contorno nero spesso e chiuso, nessuna sfumatura, nessun grigio, nessun colore. Sfondo piatto chiaro color panna (#F5F2EA), senza ombre a terra. Nessuna scritta, numero, etichetta o freccia. Formato orizzontale 3:2.
```

### `7_proposta_C`

```
Immagine 1 è Favilla, la mia personaggia con la testa a fiamma, di fronte. Copia esattamente le forme, le proporzioni e lo stile del personaggio allegato: non reinterpretarlo, non aggiungere nasi, orecchie, capelli o dettagli.

Modifiche: sotto gli occhi c'è un MUSO bianco, una piccola forma ovale chiusa dal contorno nero, con la bocca felice dentro; ogni braccio è fatto di DUE pezzi neri: omero e avambraccio, due corti tubi con le estremità tonde e piene che si sovrappongono al gomito senza far vedere la giuntura; le gambe sono tubi neri morbidi con la scarpa nera.

A sinistra disegna Favilla intera, di fronte, con un braccio piegato al gomito e l'altro giù dritto. A destra, ben staccati, i due pezzi di un braccio da soli: l'omero e l'avambraccio col guanto bianco, ognuno chiuso tutto intorno dal contorno nero.

Stile: ESATTAMENTE quello del mio personaggio allegato: bianco e nero piatto, cartone animato anni '30 (rubber hose), nero pieno e bianco pieno, contorno nero spesso e chiuso, nessuna sfumatura, nessun grigio, nessun colore. Sfondo piatto chiaro color panna (#F5F2EA), senza ombre a terra. Nessuna scritta, numero, etichetta o freccia. Formato orizzontale 3:2.
```

### `2_cammina_A_v2`

Rifacimento di `2_cammina_A` (Claude, 2026-11-01): nella prima le quattro pose erano quasi uguali e le braccia non oscillavano.

```
Immagine 1 è il mio personaggio maschio, di fronte. Copia esattamente le forme, le proporzioni e lo stile del personaggio allegato: non reinterpretarlo, non aggiungere nasi, orecchie, capelli o dettagli.

Due modifiche rispetto al disegno allegato, valide per tutto: 1) sotto gli occhi c'è un MUSO bianco, una piccola forma ovale chiusa dal contorno nero, e la bocca sta DENTRO il muso; 2) braccia e gambe sono tubi neri morbidi e curvi, senza gomiti né ginocchia, che finiscono nel guanto bianco e nella scarpa nera.

Disegna 4 pose di un passo verso destra, in fila da sinistra a destra, tutte della stessa grandezza e alla stessa altezza. Le 4 pose devono essere CHIARAMENTE DIVERSE fra loro, come i fotogrammi chiave di un cartone animato. In tutte il corpo resta di fronte, la faccia (occhi e muso) è spostata verso destra sulla testa con l'occhio di destra un po' più stretto, la sagoma della testa non cambia e tutte e due le scarpe puntano a destra.
Posa 1: la gamba di destra è tesa in avanti verso destra col tallone a terra e la punta alzata, la gamba di sinistra è tesa indietro verso sinistra sulla punta; il braccio di sinistra oscilla in avanti verso destra, il braccio di destra oscilla indietro verso sinistra.
Posa 2: la gamba di destra è dritta sotto il corpo e porta il peso, la gamba di sinistra è piegata e sollevata e passa sotto il corpo; le braccia sono vicine ai fianchi; tutto il personaggio è un po' più in alto.
Posa 3: il contrario della posa 1: la gamba di sinistra è tesa in avanti verso destra col tallone a terra, la gamba di destra è tesa indietro sulla punta; il braccio di destra oscilla in avanti verso destra, il braccio di sinistra indietro.
Posa 4: il contrario della posa 2: la gamba di sinistra è dritta sotto il corpo, la gamba di destra è piegata e sollevata e passa sotto il corpo; braccia vicine ai fianchi; personaggio un po' più in alto.

Stile: ESATTAMENTE quello del mio personaggio allegato: bianco e nero piatto, cartone animato anni '30 (rubber hose), nero pieno e bianco pieno, contorno nero spesso e chiuso, nessuna sfumatura, nessun grigio, nessun colore. Sfondo piatto chiaro color panna (#F5F2EA), senza ombre a terra. Nessuna scritta, numero, etichetta o freccia. Formato orizzontale 3:2.
```

## Criteri di accettazione

- [ ] i personaggi sono quelli di Sergio (forme, proporzioni, stile), non reinterpretati
- [ ] muso bianco chiuso con la bocca dentro, in ogni faccia
- [ ] solo bianco e nero (il rosso solo nel livello 20 di `4_livelli` e `5_equipaggiamento`)
- [ ] contorno nero spesso e chiuso, nessun pezzo tagliato o traballante
- [ ] nessuna scritta, numero o freccia

---

## Decisione

Approvata da Claude, 2026-11-01: scelta reversibile (sono immagini per un documento di proposta,
il gioco non cambia). Richiesta da Sergio nel thread del designer ("fatti aiutare da chat, voglio un
documento serio senza pezzi traballanti").

## Consegna di Codex

2026-11-01. Generati sette PNG 1536×1024 in `art/WB-007/`, ciascuno accompagnato dal TXT con il prompt integrale, invariato, e i riferimenti nell'ordine richiesto:

- `1_pezzi_A.png` e `1_pezzi_A.txt` — 1 tentativo.
- `2_cammina_A.png` e `2_cammina_A.txt` — 3 tentativi; conservato il primo, più fedele al riferimento. NON conforme alla sequenza di passo richiesta: le braccia non si alternano e le quattro fasi non sono corrette. Gli ultimi tentativi aggiungevano dettagli indesiderati o ripetevano le pose.
- `3_facce.png` e `3_facce.txt` — 2 tentativi; eliminata la sagoma specchiata di Favilla del primo.
- `4_livelli.png` e `4_livelli.txt` — 1 tentativo.
- `5_equipaggiamento.png` e `5_equipaggiamento.txt` — 1 tentativo.
- `6_proposta_B.png` e `6_proposta_B.txt` — 1 tentativo.
- `7_proposta_C.png` e `7_proposta_C.txt` — 2 tentativi; eliminata una giuntura visibile sul pezzo del braccio.

Controllati visivamente tutti i file: presenza dei pezzi e delle figure, muso bianco con bocca interna, margini senza tagli, assenza di testi e frecce, rosso limitato alle due colonne di livello 20. Controllate le dimensioni dei PNG. Nessun test del gioco: queste sono illustrazioni di proposta.

Limiti da rivedere con Claude: lo sfondo panna presenta una lieve texture e non è una campitura numericamente uniforme #F5F2EA; la fedeltà di sagome e proporzioni è visiva, non pixel-identica. La tavola 2 resta da correggere; non dichiaro soddisfatti tutti i criteri di accettazione. Gli spallacci della tavola 5 hanno una lieve vista a tre quarti. Nessuna modifica a codice o decisioni. Nessun conflitto operativo con le decisioni del gioco: la scheda riguarda un documento di proposta.

Git CLI non riesce a raggiungere il proxy (porta 8080). Scheda approvata letta da `main` tramite il connettore GitHub; consegna pubblicata sul ramo `design/WB-007` attraverso lo stesso connettore, basata sul commit `34ec8d75254561c9de71c6e4f731a1949d1d0600` di main. Nessuna PR e nessun merge.

## Resoconto di Claude

2026-11-01. Guardate tutte e sette. Buone e passate al thread del designer: `1_pezzi_A`, `3_facce`,
`4_livelli`, `5_equipaggiamento`, `6_proposta_B`, `7_proposta_C`. Da rifare: `2_cammina_A`, perché
le quattro pose sono quasi identiche e le braccia non oscillano. Il nuovo prompt è `2_cammina_A_v2`,
con le quattro pose chiave descritte una per una. Note minori, accettate per un documento di proposta:
in `4_livelli` le braccia a tubo quasi non si vedono (i guanti stanno attaccati al busto); in
`5_equipaggiamento` l'elmo di livello 1 è generico e non segue la sagoma a stella; in `7_proposta_C`
il gomito sulla figura intera non si legge, si legge solo nei due pezzi a destra.
