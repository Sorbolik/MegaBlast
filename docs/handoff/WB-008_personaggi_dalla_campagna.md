# WB-008 · Personaggi ripensati dalla campagna: protagonista, equipaggiamento, Fabbro, Favilla

- **Stato:** APPROVATA
- **Data:** 2026-11-01
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-008`

## Obiettivo

Sergio vuole una proposta grafica nuova dei personaggi principali **partendo solo dal documento
della campagna** (https://claude.ai/artifact/2GwyRT7Q7b1XD86KXFNTCh), che è la bibbia del carattere
e della storia del gioco: il protagonista con le proposte per i pezzi di equipaggiamento, il Fabbro
e Favilla. Queste immagini servono a un documento di proposta, che Claude costruisce attorno a loro;
il gioco non cambia.

È una proposta libera: **non** deve somigliare al diavoletto attuale né ai personaggi in bianco e nero.
Se qualcosa qui sembra contraddire `DECISIONI.md` (per esempio la fiammella col colore della squadra
del 26 ottobre), è voluto: Sergio l'ha chiesto, non serve segnalarlo.

### Cosa prendono dal documento della campagna

- I diavoletti vivono nella **Forgia**, l'antinferno; tu e Favilla siete apprendisti del Fabbro.
- Il protagonista è un diavoletto piccolo: ha **le corna** (nel purgatorio sette crepe sulle corna si
  chiudono una alla volta) e **una fiammella** sua. I Malebranche, «diavoli come te, ma grossi e
  bugiardi», sono i bulli dei diavoletti.
- **Il Fabbro**: il primo custode, col Maglio; battuto, ti fa da guida come Virgilio fino al pozzo dei
  giganti, dove si ferma: «Il ghiaccio spegne il fuoco. Da qui vai da solo».
- **Favilla**: l'amica d'infanzia, la sua fiamma è **la più calda dell'inferno**. Lucifero, congelato
  nel Cocito, gliela beve per liberarsi; dopo è solo una scintilla, e nel purgatorio sale con te.
- Il tono: cartone, buffo e affettuoso, «niente supplizi crudi»; versi di Dante, cartigli di
  pergamena, fondo color mattone e brace.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-005/riferimenti/R1_favilla.png` | il disegno di Favilla di Sergio, quello che compare nel documento della campagna (solo per `favilla_A`) |

Tutte le altre immagini non hanno riferimenti: il prompt basta.

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Sfondo piatto color pergamena chiara, **non**
trasparente (eccezione alla regola di `AGENTS.md`: sono illustrazioni per un documento); solo `trio`
ha uno scenario.

| Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|
| `1_protagonista_A` | | 1536×1024 | 1 |
| `2_protagonista_B` | | 1536×1024 | 1 |
| `3_protagonista_C` | | 1536×1024 | 1 |
| `4_equip_pezzi` | | 1536×1024 | 1 |
| `5_equip_livelli` | | 1536×1024 | 1 |
| `6_equip_gironi` | | 1536×1024 | 1 |
| `7_equip_misto` | | 1536×1024 | 1 |
| `8_fabbro_A` | | 1536×1024 | 1 |
| `9_fabbro_B` | | 1536×1024 | 1 |
| `10_favilla_A` | R1 | 1536×1024 | 1 |
| `11_favilla_B` | | 1536×1024 | 1 |
| `12_favilla_stati` | | 1536×1024 | 1 |
| `13_trio` | | 1536×1024 | 1 |

### `1_protagonista_A`

```
Disegna il protagonista di un videogioco per telefono ambientato nell'Inferno di Dante, raccontato come un cartone animato buffo e affettuoso: un DIAVOLETTO APPRENDISTA FABBRO.

Il personaggio: piccolo e tozzo, testa grande (circa un terzo dell'altezza), sveglio e testardo, con un ghigno furbo. Pelle rosso mattone, pancia e muso color pergamena chiara. Due corna corte e robuste color osso, leggermente curve in avanti. Occhi grandi e gialli con pupille nere. Una piccola fiammella arancione che arde sopra la testa, fra le corna. Coda sottile e lunga con la punta a freccia. Mani a quattro dita e piedi nudi con tre dita tozze. Qualche macchia di fuliggine sulle guance e sulle mani. Al collo un fazzoletto annodato AZZURRO (il colore della squadra, l'unica cosa che porta sempre). Nient'altro addosso: niente vestiti, niente armatura.

Disegnalo tre volte, in fila da sinistra a destra, tutte della stessa grandezza e ben separate: 1) fermo, di fronte, mani sui fianchi; 2) di tre quarti verso destra, mentre cammina; 3) in salto verso destra, con in mano un martello da fabbro più grande della sua testa, pronto a colpire.

La sagoma deve leggersi anche se il personaggio è alto solo 80 pixel: corna, fiammella e coda ben staccate dal corpo.

Stile: illustrazione da cartone animato per un videogioco, contorno nero spesso e chiuso, colori piatti e pieni con una sola ombra netta (cel shading) e pochi tratteggi da incisione antica nelle ombre, come le vecchie incisioni della Divina Commedia ma in versione cartone. Palette calda: rosso mattone #B8432A, pergamena #F1DFB0, brace #FF8A3D, oro #F2C45A, bruno bruciato #2A160C. Sfondo piatto color pergamena chiara #F5EBD3, senza scenario e senza ombre a terra. Nessuna scritta, numero, etichetta, freccia o firma. Formato orizzontale 3:2.
```

### `2_protagonista_B`

```
Disegna il protagonista di un videogioco per telefono ambientato nell'Inferno di Dante, raccontato come un cartone animato buffo e affettuoso: un DIAVOLETTO FATTO DI CARBONE ACCESO, un tizzone vivo uscito dalla forgia.

Il personaggio: piccolo e rotondetto, testa grande (circa un terzo dell'altezza), sveglio e testardo, con un ghigno furbo. Il corpo è nero-bruno come carbone, opaco, con crepe sottili che brillano di brace arancione (sul petto, sulle braccia, sulle ginocchia). Due corna corte di ossidiana lucida. Occhi grandi, bianchi e gialli, molto luminosi sul nero. Una piccola fiammella arancione che arde sopra la testa, fra le corna. Coda sottile e lunga con la punta a freccia che brilla di brace. Mani a quattro dita e piedi nudi con tre dita tozze. Al collo un fazzoletto annodato AZZURRO (il colore della squadra, l'unica cosa che porta sempre). Nient'altro addosso: niente vestiti, niente armatura.

Disegnalo tre volte, in fila da sinistra a destra, tutte della stessa grandezza e ben separate: 1) fermo, di fronte, mani sui fianchi; 2) di tre quarti verso destra, mentre cammina; 3) in salto verso destra, con in mano un martello da fabbro più grande della sua testa, pronto a colpire.

La sagoma deve leggersi anche se il personaggio è alto solo 80 pixel: corna, fiammella e coda ben staccate dal corpo.

Stile: illustrazione da cartone animato per un videogioco, contorno nero spesso e chiuso, colori piatti e pieni con una sola ombra netta (cel shading) e pochi tratteggi da incisione antica nelle ombre, come le vecchie incisioni della Divina Commedia ma in versione cartone. Palette calda: rosso mattone #B8432A, pergamena #F1DFB0, brace #FF8A3D, oro #F2C45A, bruno bruciato #2A160C. Sfondo piatto color pergamena chiara #F5EBD3, senza scenario e senza ombre a terra. Nessuna scritta, numero, etichetta, freccia o firma. Formato orizzontale 3:2.
```

### `3_protagonista_C`

```
Disegna il protagonista di un videogioco per telefono ambientato nell'Inferno di Dante, raccontato come un cartone animato buffo e affettuoso: un DIAVOLETTO CON LE CORNA GRANDI, come un piccolo montone testardo.

Il personaggio: piccolo, tondo e compatto, testa grande (circa un terzo dell'altezza), sveglio e testardo, con un ghigno furbo. Pelle rosso scuro tendente al bordeaux, pancia e muso color pergamena chiara. Il suo tratto principale sono DUE CORNA GRANDI DA MONTONE, arrotolate a spirale ai lati della testa, color osso con anelli in rilievo: grandi quasi quanto la testa. Occhi grandi e gialli con pupille nere, sopracciglia folte. Una piccola fiammella arancione che arde sopra la testa, fra le corna. Coda corta e grossa con un ciuffo a punta. Mani a quattro dita e zoccoli piccoli al posto dei piedi. Al collo un fazzoletto annodato AZZURRO (il colore della squadra, l'unica cosa che porta sempre). Nient'altro addosso: niente vestiti, niente armatura.

Disegnalo tre volte, in fila da sinistra a destra, tutte della stessa grandezza e ben separate: 1) fermo, di fronte, mani sui fianchi; 2) di tre quarti verso destra, mentre cammina; 3) in salto verso destra, con in mano un martello da fabbro più grande della sua testa, pronto a colpire.

La sagoma deve leggersi anche se il personaggio è alto solo 80 pixel: corna, fiammella e coda ben staccate dal corpo.

Stile: illustrazione da cartone animato per un videogioco, contorno nero spesso e chiuso, colori piatti e pieni con una sola ombra netta (cel shading) e pochi tratteggi da incisione antica nelle ombre, come le vecchie incisioni della Divina Commedia ma in versione cartone. Palette calda: rosso mattone #B8432A, pergamena #F1DFB0, brace #FF8A3D, oro #F2C45A, bruno bruciato #2A160C. Sfondo piatto color pergamena chiara #F5EBD3, senza scenario e senza ombre a terra. Nessuna scritta, numero, etichetta, freccia o firma. Formato orizzontale 3:2.
```

### `4_equip_pezzi`

```
Disegna un foglio di pezzi di equipaggiamento per un diavoletto piccolo e tozzo (testa grande con due corna corte, coda sottile con la punta a freccia), protagonista di un videogioco a cartoni ambientato nell'Inferno di Dante. Il diavoletto è apprendista nella Forgia dei diavoli e all'inizio non ha niente: questi sono i suoi PRIMI pezzi, rimediati con gli scarti della forgia, buffi e arrangiati.

Sei pezzi, staccati, senza personaggio, visti di fronte, in due righe da tre, ben separati fra loro e ognuno chiuso tutto intorno dal contorno nero:
1) TESTA: un pentolino di ferro ammaccato usato come elmo, con due buchi per far passare le corna;
2) BUSTO: un grembiule di cuoio bruciacchiato con una toppa cucita, legato con una corda;
3) MANI: due guantoni da forno di cuoio spesso, troppo grandi;
4) PIEDI: due zoccoli di ferro grezzo legati con lo spago;
5) CODA: un ditale di ferro infilato sulla punta della coda come puntale, con un pezzetto di coda dentro;
6) SCHIENA: un paio di piccole ali fatte di tela da sacco cucita su un telaio di bacchette, con le cuciture in vista.

Stile: illustrazione da cartone animato per un videogioco, contorno nero spesso e chiuso, colori piatti e pieni con una sola ombra netta (cel shading) e pochi tratteggi da incisione antica nelle ombre. Materiali leggibili: ferro grigio-azzurro scuro, cuoio bruno, tela beige, spago. Palette calda: rosso mattone #B8432A, pergamena #F1DFB0, brace #FF8A3D, oro #F2C45A, bruno bruciato #2A160C. Sfondo piatto color pergamena chiara #F5EBD3, senza ombre a terra. Nessuna scritta, numero, etichetta, freccia o firma. Formato orizzontale 3:2.
```

### `5_equip_livelli`

```
Disegna il protagonista di un videogioco a cartoni ambientato nell'Inferno di Dante: un diavoletto apprendista fabbro, piccolo e tozzo, testa grande, pelle rosso mattone con pancia e muso color pergamena, due corna corte color osso, occhi grandi e gialli, una piccola fiammella arancione sopra la testa, coda sottile con la punta a freccia, fazzoletto azzurro annodato al collo.

Disegnalo QUATTRO volte, in fila da sinistra a destra, di fronte, tutte della stessa grandezza e ben separate, sempre con la stessa posa fiera. Indossa lo stesso set di sei pezzi (elmo, corazza sul busto, guanti, stivali, puntale della coda, ali sulla schiena), che diventa più bello a ogni passo. La forma di ogni pezzo resta riconoscibile da una figura all'altra: cambiano materiale e dettagli.
1) ROTTAMI: pentolino ammaccato come elmo, grembiule di cuoio bruciacchiato, guantoni da forno, zoccoli di ferro legati con lo spago, ditale sulla coda, alette di tela da sacco.
2) FERRO BATTUTO: gli stessi pezzi rifatti bene in ferro scuro con rivetti e bordi di ottone; l'elmo ha due anelli per le corna; le ali hanno un telaio di ferro.
3) BRACE: lo stesso ferro con le giunture e i bordi che brillano di brace arancione, piccole fiamme che escono dalle spalle e dalla punta della coda; le ali sono di cuoio con nervature roventi.
4) GLORIA: gli stessi pezzi in ferro nero e oro, con incisioni a spirale e una gemma di fuoco sul petto; l'elmo ha una cresta di fiamme; le ali sono grandi e piene di fiamma.
Il fazzoletto azzurro resta sempre visibile al collo. La faccia resta sempre scoperta.

Stile: illustrazione da cartone animato per un videogioco, contorno nero spesso e chiuso, colori piatti e pieni con una sola ombra netta (cel shading) e pochi tratteggi da incisione antica nelle ombre. Palette calda: rosso mattone #B8432A, pergamena #F1DFB0, brace #FF8A3D, oro #F2C45A, bruno bruciato #2A160C. Sfondo piatto color pergamena chiara #F5EBD3, senza scenario e senza ombre a terra. Nessuna scritta, numero, etichetta, freccia o firma. Formato orizzontale 3:2.
```

### `6_equip_gironi`

```
Disegna un foglio di otto pezzi di equipaggiamento per un diavoletto piccolo e tozzo (testa grande con due corna corte, coda sottile con la punta a freccia), protagonista di un videogioco a cartoni ambientato nell'Inferno di Dante. Ogni pezzo è un trofeo: il Fabbro lo forgia con quello che il diavoletto si porta via dal guardiano di un girone. Tono buffo, mai macabro.

Otto pezzi staccati, senza personaggio, visti di fronte, in due righe da quattro, ben separati fra loro e ognuno chiuso tutto intorno dal contorno nero:
1) ELMO DI CERBERO: un elmo di cuoio scuro con tre musetti di cane sul davanti, orecchie a punta e un collare borchiato come bordo;
2) CORAZZA DI PLUTONE: una corazza fatta di monete d'oro sovrapposte come squame, con un bottone a forma di sacchetto di monete;
3) PUNTALE DI MINOSSE: un puntale per la coda a forma di spirale di coda di serpente arrotolata, verde scuro e oro;
4) ALI DELLE ARPIE: due ali di penne grigio-viola, scompigliate, con artigli piccoli sulle punte;
5) ZOCCOLI DEL MINOTAURO: due stivali pesanti a forma di zoccolo di toro, ferro e pelo marrone;
6) MANOPOLE DI DITE: due guanti di ferro rosso rovente con le nocche che fumano;
7) MANTELLO DI PECE: un mantello corto nero lucido e appiccicoso che cola in gocce, col cappuccio a due punte come le corna dei Malebranche;
8) CORONA DEL COCITO: una corona di ghiaccio azzurro chiaro con punte di cristallo e due anelli per le corna.

Stile: illustrazione da cartone animato per un videogioco, contorno nero spesso e chiuso, colori piatti e pieni con una sola ombra netta (cel shading) e pochi tratteggi da incisione antica nelle ombre. Ogni pezzo ha il colore del suo girone ma tutti stanno insieme. Palette di base: rosso mattone #B8432A, pergamena #F1DFB0, brace #FF8A3D, oro #F2C45A, bruno bruciato #2A160C, ghiaccio #BFE9FF. Sfondo piatto color pergamena chiara #F5EBD3, senza ombre a terra. Nessuna scritta, numero, etichetta, freccia o firma. Formato orizzontale 3:2.
```

### `7_equip_misto`

```
Disegna il protagonista di un videogioco a cartoni ambientato nell'Inferno di Dante: un diavoletto apprendista fabbro, piccolo e tozzo, testa grande, pelle rosso mattone con pancia e muso color pergamena, due corna corte color osso, occhi grandi e gialli, una piccola fiammella arancione sopra la testa, coda sottile con la punta a freccia, fazzoletto azzurro annodato al collo.

Disegnalo TRE volte, in fila da sinistra a destra, tutte della stessa grandezza e ben separate, per far vedere che i pezzi si mescolano liberamente:
1) SENZA NIENTE: solo il fazzoletto azzurro, un po' imbarazzato, si copre la pancia con le mani.
2) MESCOLATO: un pentolino ammaccato come elmo con le corna che escono dai buchi, una corazza di monete d'oro sovrapposte come squame, due guantoni da forno di cuoio, due stivali di ferro battuto con rivetti, niente ali, un ditale sulla punta della coda. Contento e un po' buffo.
3) TUTTO DEI GIRONI: una corona di ghiaccio azzurro con punte di cristallo, un mantello corto nero di pece che cola, due guanti di ferro rosso rovente con le nocche che fumano, due stivali a zoccolo di toro, un puntale a spirale di coda di serpente, due ali di penne grigio-viola scompigliate. Fiero, in posa da eroe.
La faccia resta sempre scoperta e il fazzoletto azzurro sempre visibile.

Stile: illustrazione da cartone animato per un videogioco, contorno nero spesso e chiuso, colori piatti e pieni con una sola ombra netta (cel shading) e pochi tratteggi da incisione antica nelle ombre. Palette calda: rosso mattone #B8432A, pergamena #F1DFB0, brace #FF8A3D, oro #F2C45A, bruno bruciato #2A160C, ghiaccio #BFE9FF. Sfondo piatto color pergamena chiara #F5EBD3, senza scenario e senza ombre a terra. Nessuna scritta, numero, etichetta, freccia o firma. Formato orizzontale 3:2.
```

### `8_fabbro_A`

```
Disegna il FABBRO, un personaggio di un videogioco a cartoni ambientato nell'Inferno di Dante: il vecchio diavolo che manda avanti la Forgia dei diavoletti e fa da maestro agli apprendisti. Burbero fuori, buono dentro: è il loro primo avversario e poi la loro guida, come Virgilio per Dante.

Il personaggio: un diavolo anziano ENORME, alto quasi tre volte un diavoletto, spalle larghissime e braccia grosse come incudini, gambe corte e storte. Pelle rosso scuro segnata da cicatrici di scintille. Un corno intero e uno spezzato a metà. Barba lunga e folta grigio cenere, con qualche brace accesa che fuma fra i peli. Sopracciglia enormi, occhi piccoli e furbi, naso grosso. Grembiule di cuoio pesante pieno di bruciature e toppe, polsiere di ferro, occhialoni da fabbro alzati sulla fronte. Tiene in spalla un MAGLIO gigante, con la testa di ferro grande come un barile e il manico di legno fasciato di cuoio.

Disegnalo tre volte, in fila da sinistra a destra, tutte della stessa grandezza e ben separate: 1) fermo, di fronte, col maglio in spalla, serio; 2) di tre quarti verso destra, mentre sbatte il maglio a terra (pronto a combattere); 3) di tre quarti verso sinistra, che ride con una mano sulla pancia, il maglio appoggiato a terra.

Stile: illustrazione da cartone animato per un videogioco, contorno nero spesso e chiuso, colori piatti e pieni con una sola ombra netta (cel shading) e pochi tratteggi da incisione antica nelle ombre, come le vecchie incisioni della Divina Commedia ma in versione cartone. Palette calda: rosso mattone #B8432A, pergamena #F1DFB0, brace #FF8A3D, oro #F2C45A, bruno bruciato #2A160C. Sfondo piatto color pergamena chiara #F5EBD3, senza scenario e senza ombre a terra. Nessuna scritta, numero, etichetta, freccia o firma. Formato orizzontale 3:2.
```

### `9_fabbro_B`

```
Disegna il FABBRO, un personaggio di un videogioco a cartoni ambientato nell'Inferno di Dante: il vecchio diavolo che manda avanti la Forgia dei diavoletti e fa da maestro agli apprendisti. Burbero fuori, buono dentro: è il loro primo avversario e poi la loro guida, come Virgilio per Dante. Il suo fuoco è la sua vita: per questo, quando arriva al lago di ghiaccio, non può andare oltre.

Il personaggio: un diavolo anziano ENORME, alto quasi tre volte un diavoletto, a forma di stufa: il busto è una FORNACE di ferro nero con un portello a grata sulla pancia, dentro il quale arde un fuoco arancione vivo; dalla schiena esce un corto camino che fuma. Braccia grosse di pelle rosso scuro, con le mani enormi annerite. Gambe corte e robuste. Testa piccola rispetto al corpo, con due corna lunghe piegate all'indietro, baffoni grigi a manubrio, sopracciglia folte, occhi piccoli e gentili. Grembiule di cuoio sotto la fornace, polsiere di ferro. Tiene in spalla un MAGLIO gigante, con la testa di ferro grande come un barile e il manico di legno fasciato di cuoio.

Disegnalo tre volte, in fila da sinistra a destra, tutte della stessa grandezza e ben separate: 1) fermo, di fronte, col maglio in spalla, il fuoco della pancia ben acceso; 2) di tre quarti verso destra, mentre sbatte il maglio a terra (pronto a combattere), le fiamme escono dalla grata; 3) di fronte, fermo su un bordo di ghiaccio azzurro, la brina sui baffi e il fuoco della pancia quasi spento, triste ma deciso.

Stile: illustrazione da cartone animato per un videogioco, contorno nero spesso e chiuso, colori piatti e pieni con una sola ombra netta (cel shading) e pochi tratteggi da incisione antica nelle ombre, come le vecchie incisioni della Divina Commedia ma in versione cartone. Palette calda: rosso mattone #B8432A, pergamena #F1DFB0, brace #FF8A3D, oro #F2C45A, bruno bruciato #2A160C, ghiaccio #BFE9FF. Sfondo piatto color pergamena chiara #F5EBD3, senza scenario e senza ombre a terra (solo il bordo di ghiaccio sotto la terza figura). Nessuna scritta, numero, etichetta, freccia o firma. Formato orizzontale 3:2.
```

### `10_favilla_A`

```
Immagine 1 è il disegno di Favilla fatto da Sergio, in bianco e nero: prendi da lì SOLO l'idea della testa (una fiamma nera arricciata in cima, con gli occhioni) e dell'abito (vestito scuro con la gonna chiara, guanti chiari). Non copiare lo stile in bianco e nero.

Disegna FAVILLA, un personaggio di un videogioco a cartoni ambientato nell'Inferno di Dante: una diavoletta apprendista nella Forgia dei diavoli, l'amica d'infanzia del protagonista. La sua fiamma è la più calda di tutto l'inferno. È coraggiosa, allegra e sveglia.

Il personaggio: piccola come un diavoletto, testa grande (circa un terzo dell'altezza). La testa è una goccia di fiamma scura, nero-bruno con il bordo che brilla di brace arancione, con un ricciolo di fiamma arricciato in cima. Occhi enormi e luminosi con le ciglia, guance color brace. Due cornini corti. Vestitino scuro con la gonna color pergamena, guanti color pergamena, scarpette scure. Coda sottile con la punta a cuore.

Disegnala tre volte, in fila da sinistra a destra, tutte della stessa grandezza e ben separate: 1) ferma, di fronte, che saluta con la mano; 2) di tre quarti verso destra, mentre corre; 3) di fronte, arrabbiata, con il ricciolo di fiamma che si alza più alto e più luminoso.

Stile: illustrazione da cartone animato per un videogioco, contorno nero spesso e chiuso, colori piatti e pieni con una sola ombra netta (cel shading) e pochi tratteggi da incisione antica nelle ombre. Palette calda: rosso mattone #B8432A, pergamena #F1DFB0, brace #FF8A3D, oro #F2C45A, bruno bruciato #2A160C. Sfondo piatto color pergamena chiara #F5EBD3, senza scenario e senza ombre a terra. Nessuna scritta, numero, etichetta, freccia o firma. Formato orizzontale 3:2.
```

### `11_favilla_B`

```
Disegna FAVILLA, un personaggio di un videogioco a cartoni ambientato nell'Inferno di Dante: una diavoletta apprendista nella Forgia dei diavoli, l'amica d'infanzia del protagonista. La sua fiamma è la più calda di tutto l'inferno, e per questo NON è arancione come le altre: è bianca e azzurra, come il fuoco più caldo. È coraggiosa, allegra e sveglia.

Il personaggio: piccola come un diavoletto, testa grande (circa un terzo dell'altezza), pelle rosso mattone con muso color pergamena, due cornini corti. Al posto dei capelli una grande FIAMMA VIVA che parte dalla fronte e sale come una coda di cavallo: bianca al centro, azzurro chiaro ai bordi, con poche punte dorate. Occhi grandi e gialli con le ciglia, un sorriso sicuro. Una tuta da apprendista di tela color pergamena con le maniche arrotolate, un grembiulino di cuoio, stivaletti bruni. Coda sottile con la punta a cuore.

Disegnala tre volte, in fila da sinistra a destra, tutte della stessa grandezza e ben separate: 1) ferma, di fronte, con le mani sui fianchi; 2) di tre quarti verso destra, mentre corre, con la fiamma che svolazza dietro; 3) di fronte, che tiene una piccola sfera di fuoco bianco-azzurro sul palmo della mano e la guarda.

Stile: illustrazione da cartone animato per un videogioco, contorno nero spesso e chiuso, colori piatti e pieni con una sola ombra netta (cel shading) e pochi tratteggi da incisione antica nelle ombre. Palette calda: rosso mattone #B8432A, pergamena #F1DFB0, brace #FF8A3D, oro #F2C45A, bruno bruciato #2A160C, e per la sua fiamma bianco #FFFFFF e azzurro #BFE9FF. Sfondo piatto color pergamena chiara #F5EBD3, senza scenario e senza ombre a terra. Nessuna scritta, numero, etichetta, freccia o firma. Formato orizzontale 3:2.
```

### `12_favilla_stati`

```
Disegna FAVILLA, un personaggio di un videogioco a cartoni ambientato nell'Inferno di Dante: una diavoletta piccola, testa grande, pelle rosso mattone con muso color pergamena, due cornini corti, occhi grandi e gialli con le ciglia, tuta da apprendista color pergamena con le maniche arrotolate, grembiulino di cuoio, stivaletti bruni, coda sottile con la punta a cuore. Al posto dei capelli ha una FIAMMA VIVA bianca e azzurra, il fuoco più caldo dell'inferno.

Racconta la sua storia in TRE figure, in fila da sinistra a destra, tutte della stessa grandezza e ben separate, di fronte:
1) PIENA: la fiamma bianca e azzurra è grande, alta e luminosa; lei ride.
2) RUBATA: è chiusa in una gabbia rotonda di ghiaccio azzurro; la sua fiamma viene tirata via verso l'alto in un lungo filo bianco-azzurro che esce dalle sbarre; la fiamma sulla testa è piccola, lei è stanca ma pugni stretti, ancora testarda.
3) SCINTILLA: libera, senza gabbia, ma sulla testa le resta solo una scintilla arancione piccolissima; è triste ma sorride, con una mano che protegge la scintilla.

Stile: illustrazione da cartone animato per un videogioco, contorno nero spesso e chiuso, colori piatti e pieni con una sola ombra netta (cel shading) e pochi tratteggi da incisione antica nelle ombre. Tono tenero, mai cupo o spaventoso. Palette: rosso mattone #B8432A, pergamena #F1DFB0, brace #FF8A3D, oro #F2C45A, bruno bruciato #2A160C, ghiaccio #BFE9FF, e per la sua fiamma bianco #FFFFFF e azzurro #BFE9FF. Sfondo piatto color pergamena chiara #F5EBD3, senza scenario e senza ombre a terra. Nessuna scritta, numero, etichetta, freccia o firma. Formato orizzontale 3:2.
```

### `13_trio`

```
Disegna la copertina di un videogioco a cartoni ambientato nell'Inferno di Dante: i tre personaggi principali insieme nella Forgia dei diavoli, prima che inizi l'avventura. Tono buffo e affettuoso.

A sinistra il FABBRO: un diavolo anziano enorme, alto quasi tre volte gli altri due, a forma di stufa: il busto è una fornace di ferro nero con un portello a grata sulla pancia dove arde un fuoco arancione; corto camino che fuma dalla schiena; braccia grosse rosso scuro; testa piccola con due corna lunghe piegate all'indietro, baffoni grigi a manubrio; grembiule di cuoio; un maglio gigante appoggiato a terra. Sorride sotto i baffi, con le braccia incrociate.
Al centro il PROTAGONISTA: un diavoletto apprendista piccolo e tozzo, testa grande, pelle rosso mattone con pancia e muso color pergamena, due corna corte color osso, occhi grandi e gialli, una piccola fiammella arancione sopra la testa, coda sottile con la punta a freccia, fazzoletto azzurro annodato al collo, nient'altro addosso. Tiene un martello da fabbro più grande della sua testa, ghigno furbo.
A destra FAVILLA: una diavoletta piccola come lui, pelle rosso mattone con muso color pergamena, due cornini corti, occhi grandi e gialli con le ciglia, una grande fiamma viva bianca e azzurra al posto dei capelli, tuta da apprendista color pergamena con le maniche arrotolate, grembiulino di cuoio, coda con la punta a cuore. Gli dà una gomitata e ride.

Dietro di loro, semplice e più scuro dei personaggi, la Forgia: un'incudine, il bagliore arancione di una fornace, catene e attrezzi appesi, scintille. Lo sfondo deve essere scuro e spento, i personaggi chiari e netti: devono staccarsi molto dallo sfondo.

Stile: illustrazione da cartone animato per un videogioco, contorno nero spesso e chiuso, colori piatti e pieni con una sola ombra netta (cel shading) e pochi tratteggi da incisione antica nelle ombre, come le vecchie incisioni della Divina Commedia ma in versione cartone. Palette: rosso mattone #B8432A, pergamena #F1DFB0, brace #FF8A3D, oro #F2C45A, bruno bruciato #2A160C, e per la fiamma di Favilla bianco e azzurro #BFE9FF. Nessuna scritta, numero, etichetta, freccia o firma. Formato orizzontale 3:2.
```

## Criteri di accettazione

- [ ] stesso stile in tutte le immagini: cartone, contorno nero spesso e chiuso, colori piatti, una sola ombra netta
- [ ] il protagonista è piccolo, ha corna, fiammella, coda e fazzoletto azzurro; nessun vestito dove il prompt non lo chiede
- [ ] nei fogli dei pezzi ogni pezzo è staccato e intero, nessuno tagliato dal bordo
- [ ] in `5_equip_livelli` la forma di ogni pezzo si riconosce dalla prima alla quarta figura
- [ ] la fiamma di Favilla B è bianca e azzurra, non arancione
- [ ] nessuna scritta, numero, freccia o firma; niente di cruento

---

## Decisione

Approvata da Claude, 2026-11-01: scelta reversibile (immagini per un documento di proposta, il gioco
non cambia). Richiesta da Sergio nel thread "Ripensare i personaggi dalla campagna": «mi fai una
proposta grafica dei personaggi ... come se non conoscessi niente del gioco oltre al documento della
campagna ... se ti serve chat per produrre delle immagini fai i prompt per lui tramite git e poi li
eseguo».

## Consegna di Codex

## Resoconto di Claude
