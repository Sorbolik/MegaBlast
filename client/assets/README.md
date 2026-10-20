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
| `scoria/` | 7 pezzi del corpo (128 px di altezza), `scoria_nucleo_luce.png`, 6 occhi (`scoria_occhio_<espressione>.png`), `scoria_rig.json` con perni, agganci e ordine di disegno |
| `set/` | 4 set (corvo, fornace, leviatano, vuoto) × 5 pezzi (maschera, corazza, mantello, gambali davanti/dietro). Per ogni pezzo: base (livello I), `_finiture` (ottone, livello II), `_luce` (bagliore, livello III), `_icona`. `<set>_maschera_occhio.png` sostituisce l'occhio quando si indossa la maschera; la maschera nasconde le corna. Posizioni in `set_rig.json` |
| `armi/` | 6 armi con base, `_luce` e `_icona`. `armi_rig.json` ha il punto dell'impugnatura e gli angoli del fendente della Lama di Nucleo (da 205° dietro la schiena a -35° davanti) |
| `esplosioni/` | `esplosione_base_12x256.png` (flipbook 12 fotogrammi da 256 px), fumo e fuoco additivo come livelli separati |
| `mappe/isole_cimitero/` | `maschera.png` 640×360 (nero vuoto, bianco terra, rosso indistruttibile; è la stessa di `client/sim/mapdata.lua`), `superficie.png`, `ossa.png`, `interno.png` (parete dei crateri), `sfondo_lontano.png`, `colori.txt` (brace dei crateri). Immagini a 1920×1080, allineate alla maschera |
| `ui/kit/` | Bottoni, pannelli, carte, slot, barre, schede, badge. `kit_ui.json` ha i bordi 9-slice di ogni pezzo |
| `ui/icone/` | 20 icone 128 px (`icona_<nome>.png`) |
| `ui/sfondi/` | Sfondi delle schermate: home, forgia, podio (4 gradini), campagna, caricamento |
| `ui/` | `logo.png` e `logo_luce.png` |

## Rigenerare

Gli script in `strumenti/grafica/` (Python 3 con Pillow, numpy, scipy) ritagliano i fogli del generatore.
`mappa_in_lua.py` riscrive `client/sim/mapdata.lua` da `maschera.png`.
