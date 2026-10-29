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
| `armi/` | Le armi del diavoletto, disegnate a vettori da `strumenti/grafica/armi.py` (stile del diavoletto: contorno nero spesso, colori pieni): ogni arma in mano (`<arma>.png`, punta a destra), la sua icona della barra (`_icona`), i colpi in volo (`razzo`, `palla`, `uovo`, `scheggia`, `globo`) e per tutti le parti col colore della squadra (`_tinta`, bianche e grigie, tinte nel codice in modo normale, non additivo). Lo script scrive anche `client/battaglia/armi.atlas` (compresso) e `armi.lua` con misure e pugni in unità del mondo |
| `diavoletto/` | I pezzi del diavoletto, disegnati a vettori da `strumenti/grafica/diavoletto.py` con lo stesso stile e motore delle armi (`vettori.py`): testa in quattro facce, busto, gambe, braccia, pugno (le manine staccate), ala, coda in segmenti (`_bordo` e colore), fiammella in tre forme e paracadute (le parti `_tinta` prendono il colore della squadra). Lo script scrive anche `client/battaglia/diavoletto.atlas` (compresso) e `diavoletto.lua` con misure e perni; il gioco li anima nel codice |
| `esplosioni/` | `esplosione_base_12x256.png` (flipbook 12 fotogrammi da 256 px), fumo e fuoco additivo come livelli separati |
| `mappe/forgia/`, `mappe/crogiolo/` | Per ogni mappa `terreno.png` 1920×1080 con l'alfa (allineato alla maschera di 640×360 celle di `client/sim/mapdata.lua`: una cella, 3 px) e `interno_mezzo.png` (parete dei crateri a metà risoluzione) |
| `ui/` | Le tre forme bianche dell'interfaccia (`forma`, `bordo` 9-slice e `alone`), fatte da `strumenti/grafica/ui.py` e colorate da `client/ui/ui.lua` |
| `suoni/` | `punto.wav`, il tic dei punti che salgono nel gettone (fatto da `strumenti/suoni/punto.py`; il gioco lo suona sempre più acuto) |
| `font/` | Lilita One (licenza OFL in `OFL_LilitaOne.txt`), il font dell'interfaccia (`client/ui/titolo.font`): provvisorio, la scelta finale è di Gabriella |

## In battaglia

- `terreno.png` e `interno_mezzo.png` delle mappe: la Forgia da `grafica/strumenti/mappa_forgia_finale.py` dei file del progetto, il Crogiolo da `strumenti/grafica/mappa_crogiolo.py` (stessi materiali). `fx/bagliore.png` (alone bianco per missile e mirino) lo fa `strumenti/grafica/battaglia.py`.
- La mappa è una mesh con lo shader `client/battaglia/terreno.fp`: sfondo fatto dallo shader (cielo, file di colline e guglie in parallasse, braci), terreno ritagliato dalla maschera viva, parete e brace dove si è scavato.
- Il personaggio è il diavoletto di `client/battaglia/scoria.lua`, a pezzi disegnati a vettori (`strumenti/grafica/diavoletto.py`) e animati nel codice con molle e pose: corsa, salto, mira (testa e avambracci seguono l'arma), colpito, paracadute, vittoria, sconfitta e le scenette dell'attesa. La fiammella e il paracadute sono tinti col colore della squadra. Atlante `client/battaglia/battaglia.atlas`, esplosione `client/battaglia/esplosione.tilesource`.

## Interfaccia

- Niente immagini dipinte: `client/ui/ui.lua` disegna pannelli, bottoni, schede, barre e il bagliore del Nucleo con le tre forme di `ui/` (atlante `client/ui/ui.atlas`) e i colori della sua palette. I pezzi si aggiungono lì quando una schermata ne ha bisogno.
- `client/menu/home.lua` monta la home: fondo scuro, il diavoletto di `battaglia/scoria.lua` col bagliore della squadra, il nome e i bottoni delle partite. Mentre si vede la home la mappa della battaglia è spenta.

## Rigenerare

Gli script in `strumenti/grafica/` (Python 3 con Pillow, numpy, scipy) ritagliano i fogli del generatore.
`mappa_in_lua.py` riscrive `client/sim/mapdata.lua` dalle `maschera.png` delle mappe.
