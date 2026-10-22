# Grafica del gioco

Pezzi pronti per il gioco, ricavati dalle immagini del generatore con gli script in `strumenti/grafica/`.
Lo stile e le regole sono nella bibbia grafica "MegaBlast – Bibbia grafica: Le Scorie".

## Regole comuni

- PNG RGBA, alfa non premoltiplicato.
- I file `*_luce.png` sono bianchi su trasparente: si disegnano in **additivo** sopra il pezzo base e si **tingono nel codice** con il colore della squadra (occhio, Nucleo, crepe, bagliori delle armi e dei set al livello III).
- Le scritte non sono mai nelle immagini, tranne il logo: le mette il gioco con i font.

## Cartelle

| Cartella | Cosa c'è |
|---|---|
| `personaggio/` | Il personaggio a pezzi (`pg_<pezzo>.png`, 2,5 px per unità del rig alto 128, schiariti un po' per staccarsi dallo sfondo): testa con maschera, collo, busto, Nucleo, bacino, spallacci, braccia, avambracci, mani in tre pose (aperta, artigli, pugno), cosce, stinchi, piedi, `pg_occhio.png` (luce nel buco della maschera). Li fa `strumenti/grafica/personaggio_esporta.py` dai master in `grafica/personaggio/master/`, con lo scheletro `client/battaglia/personaggio_rig.lua` |
| `set/` | 4 set (corvo, fornace, leviatano, vuoto) × 5 pezzi (maschera, corazza, mantello, gambali davanti/dietro). Per ogni pezzo: base (livello I), `_finiture` (ottone, livello II), `_luce` (bagliore, livello III), `_icona`. `<set>_maschera_occhio.png` sostituisce l'occhio quando si indossa la maschera; la maschera nasconde le corna. Posizioni in `set_rig.json` |
| `armi/` | 6 armi con base, `_luce` e `_icona`. `armi_rig.json` ha il punto dell'impugnatura e gli angoli del fendente della Lama di Nucleo (da 205° dietro la schiena a -35° davanti) |
| `esplosioni/` | `esplosione_base_12x256.png` (flipbook 12 fotogrammi da 256 px), fumo e fuoco additivo come livelli separati |
| `mappe/isole_cimitero/` | `maschera.png` 640×360 (nero vuoto, bianco terra, rosso indistruttibile; è la stessa di `client/sim/mapdata.lua`), `superficie.png`, `ossa.png`, `interno.png` (parete dei crateri), `sfondo_lontano.png`, `colori.txt` (brace dei crateri). Immagini a 1920×1080, allineate alla maschera |
| `ui/kit/` | Bottoni, pannelli, carte, slot, barre, schede, badge. `kit_ui.json` ha i bordi 9-slice di ogni pezzo |
| `ui/icone/` | 20 icone 128 px (`icona_<nome>.png`) |
| `ui/sfondi/` | Sfondi delle schermate: home, forgia, podio (4 gradini), campagna, caricamento |
| `ui/` | `logo.png` e `logo_luce.png` |
| `menu/` | Versioni per la home, fatte da `strumenti/grafica/menu.py`: kit e logo rimpiccioliti, `home_sfondo.png` largo 2048, il personaggio a 4 px per unità in `menu/personaggio/`, le armi grandi in `menu/scoria/` |
| `font/` | Cinzel Bold (licenza OFL in `OFL_Cinzel.txt`), il font dei titoli della home |

## In battaglia

- `mappe/isole_cimitero/terreno.png` (superficie con sopra le ossa) e `interno_mezzo.png` (parete dei crateri a metà risoluzione) li prepara `strumenti/grafica/battaglia.py`, insieme a `fx/bagliore.png` (alone bianco per missile e mirino).
- La mappa è una mesh con lo shader `client/battaglia/terreno.fp`: sfondo lontano, terreno ritagliato dalla maschera viva, parete e brace dove si è scavato.
- Il personaggio è montato in `client/battaglia/scoria.lua`: nodi GUI sullo scheletro di `personaggio_rig.lua`, animazioni nel codice (molle e IK a due ossa per braccia e gambe); atlante `client/battaglia/battaglia.atlas`, esplosione `client/battaglia/esplosione.tilesource`.
- Per cambiare perni o posa di riposo: `strumenti/grafica/personaggio_rig.json`, anteprima con `personaggio_anteprima.py`, poi `personaggio_esporta.py`.

## Nella home

- `client/menu/home.lua` monta la home con i nodi GUI: sfondo (atlante `sfondo_home`, adattato in ZOOM così copre ogni schermo), la Scoria di `battaglia/scoria.lua` con l'atlante `scoria_hd`, bottoni del kit con 9-slice (atlante `menu`), testi con `menu/titoli.font`.
- Mentre si vede la home la mappa della battaglia è spenta, così il telefono non la disegna sotto lo sfondo.

## Rigenerare

Gli script in `strumenti/grafica/` (Python 3 con Pillow, numpy, scipy) ritagliano i fogli del generatore.
`mappa_in_lua.py` riscrive `client/sim/mapdata.lua` da `maschera.png`.
