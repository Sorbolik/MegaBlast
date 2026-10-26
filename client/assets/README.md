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
| `diavoletto/` | Il diavoletto a fotogrammi, dai fogli di Ludo.ai (`<animazione>_<n>.png`) e la testa da sola che gira con la mira (`testa.png`): li fa `strumenti/grafica/diavoletto.py`, che scrive anche `client/battaglia/diavoletto.atlas` e `diavoletto.lua` |
| `esplosioni/` | `esplosione_base_12x256.png` (flipbook 12 fotogrammi da 256 px), fumo e fuoco additivo come livelli separati |
| `mappe/isole_cimitero/` | `maschera.png` 640×360 (nero vuoto, bianco terra, rosso indistruttibile; è la stessa di `client/sim/mapdata.lua`), `superficie.png`, `ossa.png`, `interno.png` (parete dei crateri), `colori.txt` (brace dei crateri). Immagini a 1920×1080, allineate alla maschera |
| `ui/` | Le tre forme bianche dell'interfaccia (`forma`, `bordo` 9-slice e `alone`), fatte da `strumenti/grafica/ui.py` e colorate da `client/ui/ui.lua`; `levette/` le levette del telefono (`strumenti/grafica/levette.py`) |
| `font/` | Cinzel Bold (licenza OFL in `OFL_Cinzel.txt`), il font dell'interfaccia (`client/ui/titolo.font`) |

## In battaglia

- `mappe/isole_cimitero/terreno.png` (superficie con sopra le ossa) e `interno_mezzo.png` (parete dei crateri a metà risoluzione) li prepara `strumenti/grafica/battaglia.py`, insieme a `fx/bagliore.png` (alone bianco per missile e mirino).
- La mappa è una mesh con lo shader `client/battaglia/terreno.fp`: sfondo fatto dallo shader (cielo, file di colline e guglie in parallasse, braci), terreno ritagliato dalla maschera viva, parete e brace dove si è scavato.
- Il personaggio è il diavoletto di `client/battaglia/scoria.lua`, a fotogrammi: i fogli di Ludo.ai e le basi di ChatGPT (sorgenti in `/mnt/project-files/animazioni_ludo/diavoletto_2026-10-26/`) diventano le immagini in `diavoletto/`, l'atlante `client/battaglia/diavoletto.atlas` e `client/battaglia/diavoletto.lua` con `strumenti/grafica/diavoletto.py`. Nella mira testa, pugni e arma li mette il codice; la fiammella è tinta col colore della squadra. Atlante `client/battaglia/battaglia.atlas`, esplosione `client/battaglia/esplosione.tilesource`.

## Interfaccia

- Niente immagini dipinte: `client/ui/ui.lua` disegna pannelli, bottoni, schede, barre e il bagliore del Nucleo con le tre forme di `ui/` (atlante `client/ui/ui.atlas`) e i colori della sua palette. I pezzi si aggiungono lì quando una schermata ne ha bisogno.
- `client/menu/home.lua` monta la home: fondo scuro, la Scoria di `battaglia/scoria.lua` col bagliore del Nucleo, il nome e i bottoni delle partite. Mentre si vede la home la mappa della battaglia è spenta.

## Rigenerare

Gli script in `strumenti/grafica/` (Python 3 con Pillow, numpy, scipy) ritagliano i fogli del generatore.
`mappa_in_lua.py` riscrive `client/sim/mapdata.lua` da `maschera.png`.
