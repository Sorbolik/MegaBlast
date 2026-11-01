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
