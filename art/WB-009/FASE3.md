# WB-009 · fase 3: pacchetto per la prova animata

Aprire `fase3/editor.html` nel browser: parte con l'apprendista, contiene tutte
le immagini e funziona senza servizi esterni. `Avvia` riproduce la clip selezionata;
il menu `Faccia` offre nove espressioni. Il fazzoletto cambia con la squadra.
Il gioco in `client/` non è modificato: questa è una prova autonoma sul suo editor
e sullo stesso scheletro, per la validazione di Sergio prima dell'integrazione.

## Contenuto

- `fase3/svg/`: 27 SVG trasparenti (incluse nove teste, cinque segmenti di coda
  con i rispettivi strati di bordo, maschera squadra e ala trasparente).
- `fase3/png/1x/`, `2x/`, `3x/`: 81 PNG, tutti renderizzati dagli SVG. Le densità
  moltiplicano i pixel dello scheletro, non la misura fisica del personaggio.
- `fase3/pelli/apprendista.json`, `fase3/pelli.lua`: montaggio e perni, dimensioni,
  lunghezze e angoli della coda per il pacchetto.
- `fase3/controlli.json`: tavolozza, file, dimensioni e conteggio dei tracciati.
- `fase3/prove/`: foto di fermo, corsa, colpito e risultati dei controlli browser.

## Rigenerare dal repository

Dipendenze: Python 3, numpy, scipy, Pillow, cairosvg e il programma `potrace` nel PATH.

```sh
python3 art/WB-009/fase3.py
python3 art/WB-009/verifica_fase3.py
```

Il taglio riusa `taglia.py` con `--allinea` e ala assente, indirizzando gli output
nel pacchetto. Le teste extra sono separate per componente connessa: il programma
fallisce se non trova esattamente cinque teste. I raster montati sono quantizzati
al colore RGB più vicino della tavolozza, con voto locale 3×3 per ridurre le isole;
potrace ricalca ogni maschera di colore in curve. Un pixel di sovrapposizione fra
strati colorati elimina le fessure del ricalco; il nero dei dettagli è sopra.
Non sono forme inventate o SVG disegnati a codice: i tracciati provengono dai raster.

Il controllo SVG rifiuta colori estranei, CSS e immagini incorporate. I colori
della maschera squadra sono bianco con opacità 1 o 180/255: nessun riempimento
grigio fuori tavolozza. I PNG hanno normali pixel intermedi ai bordi antialias;
la garanzia di tavolozza riguarda i riempimenti degli SVG.

L'editor riusa la preparazione e il template comuni senza modificarli; aggiunge le
cinque facce soltanto nei propri dati incorporati. Per il gioco serviranno ancora
i posti delle facce aggiuntive, la selezione delle densità e l'integrazione degli asset.
Non sostituire `client/battaglia/pelli.lua` con questo file isolato: contiene solo
l'apprendista, mentre quello del gioco contiene tutte le pelli.

## Prove e limiti

Verificati 27 SVG e 81 PNG identici al rendering degli SVG, rifiuto di un colore
fuori tavolozza e di un raster incorporato, nove teste, cinque segmenti di coda,
ala invisibile e riferimenti immagini del montaggio. Nel browser Chromium:
fermo, corsa, colpito, vittoria, sconfitta e mira cambiano fotogramma; nove facce
sono selezionabili, quattro squadre disponibili, nessun errore JavaScript.

Le foto mostrano ancora difetti dei disegni e dell'allineamento automatico:
collo e spalle con giunture visibili, coda più spessa/rigida del concept e sul lato
destro, piccole variazioni delle sagome delle teste e zone di colore sulle corna.
La tavolozza ora è esatta, ma questo non equivale ad approvare il disegno o il
montaggio. Non eseguita una partita in Defold né una prova su telefono. Non
pubblicato l'editor online, non cambiato il personaggio predefinito del gioco.
Sergio deve ancora validarlo nell'editor; l'integrazione nel gioco resta a Claude.
