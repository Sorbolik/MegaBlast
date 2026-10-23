# Grafica del gioco

Pezzi pronti per il gioco, ricavati dalle immagini del generatore con gli script in `strumenti/grafica/`.
Lo stile e le regole sono nella bibbia grafica "MegaBlast – Bibbia grafica: Le Scorie".

## Regole comuni

- PNG RGBA, alfa non premoltiplicato.
- I file `*_luce.png` sono bianchi su trasparente: si disegnano in **additivo** sopra il pezzo base e si **tingono nel codice** con il colore della squadra.
- Le scritte non sono mai nelle immagini, tranne il logo: le mette il gioco con i font.

## Cartelle

| Cartella | Cosa c'è |
|---|---|
| `armi/` | Le icone delle armi della barra (`_icona`), il globo del teletrasporto (`passo_ombra`) e l'Uovo di Fiamma in volo, con le loro `_luce`. Le armi intere sono in `grafica/armi/` dei file del progetto |
| `esplosioni/` | `esplosione_base_12x256.png` (flipbook 12 fotogrammi da 256 px), fumo e fuoco additivo come livelli separati |
| `mappe/isole_cimitero/` | `maschera.png` 640×360 (nero vuoto, bianco terra, rosso indistruttibile; è la stessa di `client/sim/mapdata.lua`), `superficie.png`, `ossa.png`, `interno.png` (parete dei crateri), `colori.txt` (brace dei crateri). Immagini a 1920×1080, allineate alla maschera |
| `ui/kit/` | Bottoni, pannelli, carte, slot, barre, schede, badge. `kit_ui.json` ha i bordi 9-slice di ogni pezzo |
| `ui/icone/` | 20 icone 128 px (`icona_<nome>.png`) |
| `ui/sfondi/` | Sfondi delle schermate: home, forgia, podio (4 gradini), campagna, caricamento |
| `ui/` | `logo.png` e `logo_luce.png` |
| `menu/` | Versioni per la home, fatte da `strumenti/grafica/menu.py`: kit e logo rimpiccioliti, `home_sfondo.png` largo 2048 |
| `font/` | Cinzel Bold (licenza OFL in `OFL_Cinzel.txt`), il font dei titoli della home |

## In battaglia

- `mappe/isole_cimitero/terreno.png` (superficie con sopra le ossa) e `interno_mezzo.png` (parete dei crateri a metà risoluzione) li prepara `strumenti/grafica/battaglia.py`, insieme a `fx/bagliore.png` (alone bianco per missile e mirino).
- La mappa è una mesh con lo shader `client/battaglia/terreno.fp`: sfondo fatto dallo shader (cielo, file di colline e guglie in parallasse, braci), terreno ritagliato dalla maschera viva, parete e brace dove si è scavato.
- Il personaggio per ora è il corpo in grigio di `client/battaglia/grigio.lua` (fase 2 della roadmap): capsula e occhio disegnati con nodi GUI, nessuna immagine. Atlante `client/battaglia/battaglia.atlas`, esplosione `client/battaglia/esplosione.tilesource`.

## Nella home

- `client/menu/home.lua` monta la home con i nodi GUI: sfondo (atlante `sfondo_home`, adattato in ZOOM così copre ogni schermo), il corpo in grigio di `battaglia/grigio.lua`, bottoni del kit con 9-slice (atlante `menu`), testi con `menu/titoli.font`.
- Mentre si vede la home la mappa della battaglia è spenta, così il telefono non la disegna sotto lo sfondo.

## Rigenerare

Gli script in `strumenti/grafica/` (Python 3 con Pillow, numpy, scipy) ritagliano i fogli del generatore.
`mappa_in_lua.py` riscrive `client/sim/mapdata.lua` da `maschera.png`.
