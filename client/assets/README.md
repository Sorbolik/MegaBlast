# Grafica del gioco

Pezzi pronti per il gioco, ricavati dalle immagini del generatore con gli script in `strumenti/grafica/`.
Lo stile e le regole sono nella bibbia grafica "MegaBlast – Bibbia grafica: Le Scorie".

## Regole comuni

- PNG RGBA, alfa non premoltiplicato.
- I file `*_luce.png` sono bianchi su trasparente: si disegnano in **additivo** sopra il pezzo base e si **tingono nel codice** con il colore della squadra.
- Le scritte non sono mai nelle immagini: le mette il gioco con i font.

## Cartelle

| Cartella | Cosa c'è |
|---|---|
| `weapons/` | Le armi del diavoletto, disegnate a vettori da `strumenti/grafica/armi.py` (stile del diavoletto: contorno nero spesso, colori pieni): ogni arma in mano (`<arma>.png`, punta a destra), la sua icona della barra (`_icona`), i colpi in volo (`razzo`, `palla`, `uovo`, `scheggia`, `globo`) e per tutti le parti col colore della squadra (`_tinta`, bianche e grigie, tinte nel codice in modo normale, non additivo). Lo script scrive anche `client/battle/weapons.atlas` (non compresso, per il dettaglio) e `weapons.lua` con misure e pugni in unità del mondo |
| `devil/` | I pezzi del diavoletto, disegnati a vettori da `strumenti/grafica/diavoletto.py` con lo stesso stile e motore delle armi (`vettori.py`): testa in quattro facce, busto, gambe, braccia, pugno (le manine staccate), ala, coda in segmenti (`_bordo` e colore) e paracadute (le parti `_tinta` prendono il colore della squadra). Lo script scrive anche `client/battle/devil.atlas` (non compresso, per il dettaglio) e `devil.lua` con misure e perni; il gioco li anima nel codice |
| `maps/miniature/` | Le cartoline delle mappe della campagna per SCEGLI LA MAPPA in allenamento (504 × 284, atlante `client/ui/maps.atlas`), fatte da `strumenti/grafica/miniature_mappe.py` con le immagini di `client/paintings/`: da rifare quando cambia una mappa dipinta o se ne aggiunge una |
| `ui/` | Le forme bianche dell'interfaccia (`forma`, `bordo` 9-slice e `alone`; una sagoma per famiglia di comandi: `eroe_*` il pulsante principale, `slot_arma_*` le armi della barra, `badge_*` la pillola dei colpi, `gettone_*` ottagono e `oggetto_*` esagono; stelle e rotellina), fatte da `strumenti/grafica/ui.py` e colorate da `client/ui/ui.lua`; `favilla.png`, la testa di Favilla nel disco di carta dell'ingresso, ritagliata dal disegno di Sergio (`art/personaggi/favilla.png`) da `strumenti/grafica/ingresso.py` |
| `sounds/` | `punto.wav`, il tic dei punti che salgono nel gettone (fatto da `strumenti/suoni/punto.py`; il gioco lo suona sempre più acuto) |
| `font/` | Lilita One (licenza OFL in `OFL_LilitaOne.txt`), il font dell'interfaccia (`client/ui/title.font`): provvisorio, la scelta finale è di Gabriella |

## In battaglia

- `fx/bagliore.png` (alone bianco per missile e mirino) lo fa `strumenti/grafica/battaglia.py`. `fx/targa_corona.png` e `targa_bianco.png` sono per la targa sopra i personaggi, fatti da `strumenti/grafica/targa.py`: la Corona d'oro, tagliata dal foglio di ChatGPT `art/WB-011/c_lama_foglio.png`, e un quadratino bianco per la vita, i fondi e la punta a V di chi è di turno.
- La mappa è una mesh con lo shader `client/battle/terrain.fp`: sfondo dipinto in parallasse con le braci, terreno dipinto ritagliato dalla maschera viva, crateri che mostrano lo sfondo con l'orlo bruciato.
- Le mappe (il pavimento, la fossa del Fabbro, il cortile del Duello e le arene delle missioni, quelle del cortile dipinte come il cortile, le altre d'acciaio) non stanno qui ma in `client/paintings/` (risorse a parte, `custom_resources`): terreno e sfondo dipinti da SVG con `strumenti/grafica/mappe_dipinte.py`, una volta per ogni densità di schermo (`_1` e `_2`, 1,5 volte più grande). Il gioco carica solo quella che serve (`client/battle/terrain.script`, numeri in `client/battle/paintings.lua`). Lo sfondo è un cielo e tre strisce larghe un giro (la Forgia, che scorre piano, e il cortile, fermo); nei crateri si vede lo sfondo, con l'orlo bruciato.
- Il personaggio è il diavoletto di `client/battle/scoria.lua`, a pezzi disegnati a vettori (`strumenti/grafica/diavoletto.py`) e animati nel codice con molle e pose: corsa, salto, mira (testa e avambracci seguono l'arma), colpito, paracadute, vittoria, sconfitta e le scenette dell'attesa. Il paracadute è tinto col colore della squadra. Atlante `client/battle/battle.atlas`; le esplosioni sono particelle (`client/battle/impact.lua`).

## Interfaccia

- Niente immagini dipinte: `client/ui/ui.lua` disegna pannelli, bottoni, schede, barre e il bagliore del Nucleo con le tre forme di `ui/` (atlante `client/ui/ui.atlas`) e i colori della sua palette. I pezzi si aggiungono lì quando una schermata ne ha bisogno.
- `client/menu/home.lua` monta la home: dietro lo sfondo dipinto della Forgia (lo disegna la mesh del terreno, senza mappa), l'apprendista fermo senza arma col bagliore della squadra, il nome e i bottoni delle partite.

## Rigenerare

Gli script in `strumenti/grafica/` (Python 3 con Pillow, numpy, scipy) ritagliano i fogli del generatore.
`mappa_in_lua.py` riscrive `client/sim/mapdata.lua` dalle `maschera.png` delle mappe.
`mappe_dipinte.py` (Python, più node con Playwright per disegnare gli SVG) rifà le mappe dell'apprendista: i layout del pavimento e della fossa, il cortile (sfondo, mappa e lezioni in `strumenti/grafica/cortile.py`), le arene delle missioni prese da `client/sim/levels.lua`, le immagini di `client/paintings/`, le maschere in `strumenti/grafica/mappe/` e `client/battle/paintings.lua`; poi vanno rilanciati `mappa_in_lua.py` e `miniature_mappe.py` (le cartoline della scelta della mappa). Le scene vengono da `strumenti/grafica/gironi/` (la ricetta di Gabriella).
