# Blender per le animazioni (prova: la fornace del Fabbro)

Prova di Blender come editor delle animazioni a pezzi ritagliati. Si comincia da una sola
animazione: il Fabbro che apre lo sportello della fornace e dà l'oggetto (il minigioco
dell'Ossidiana). Nel gioco non è ancora collegato niente: prima si guarda l'anteprima.

## I file

| File | Cosa fa |
|---|---|
| `scena_fornace.py` | monta la scena: i pezzi PNG come piani coi perni, la camera di fronte, un'animazione di esempio |
| `esporta.py` | scrive l'animazione in un file Lua per il gioco (posizione, rotazione, scala, trasparenza di ogni pezzo) |
| `rigioca.py` | rigioca il file esportato come farebbe il gioco, per vedere che è uguale a Blender |
| `taglia_fabbro.py` | ritaglia i pezzi provvisori dalla figura intera di WB-012 |
| `pezzi_provvisori/` | corpo, sportello, fumo: provvisori, finché Codex non disegna i pezzi veri |

Il buio dietro lo sportello (`interno_segnaposto`) è un rettangolo scuro di segnaposto: il
pezzo vero (l'interno della fornace col fuoco) lo disegnerà Codex.

## Installare Blender (una volta)

Da PowerShell: `winget install BlenderFoundation.Blender`, oppure da https://www.blender.org/download/
(gratis). Va bene la 4.2 o più nuova.

## Aprire la scena

Da PowerShell, nella cartella `C:\Sviluppo\MegaBlast`:

```powershell
blender --python tools\blender\scena_fornace.py
```

(se `blender` non si trova: `& "C:\Program Files\Blender Foundation\Blender 5.0\blender.exe" --python tools\blender\scena_fornace.py`,
col numero della tua versione). Blender si apre con il Fabbro già montato e guardato dalla
camera. Salva subito il file (Ctrl+S) come `simulazione\blender\fornace.blend`: da lì in poi
apri quello, lo script rifà la scena da zero e cancellerebbe le tue modifiche.

## Guida veloce: timeline e keyframe

Le cose da sapere sono poche.

1. **Guardare.** Il tasto `0` del tastierino numerico guarda dalla camera; la rotella fa lo zoom,
   la rotella premuta sposta la vista. In alto a destra della vista, la sfera "Material Preview"
   mostra i colori veri.
2. **Scegliere un pezzo.** Clic sinistro sul pezzo, o sul suo nome nell'elenco in alto a destra
   (Outliner): `corpo`, `sportello`, `oggetto`, `fumo`.
3. **Muovere, girare, allargare.** `G` sposta, `R` gira, `S` allarga; dopo il tasto, `X` o `Z`
   bloccano l'asse (`G` `Z` = solo su e giù). Ogni pezzo gira sul suo perno (il puntino arancione):
   lo sportello sul cardine, il corpo sui piedi.
4. **La timeline** è la striscia in basso coi numeri dei fotogrammi: 60 fotogrammi = 1 secondo.
   Clic su un numero per andare a quel momento; `Spazio` fa partire e fermare; `Shift+←`
   torna all'inizio.
5. **Mettere una chiave (keyframe).** Vai al fotogramma, metti il pezzo come lo vuoi, poi con il
   mouse sulla vista premi `I`: la posa è fissata in quel momento (un rombo giallo nella
   timeline). Blender riempie da solo il movimento fra una chiave e l'altra.
6. **Cambiare una chiave.** Torna sul fotogramma della chiave, cambia la posa e premi di nuovo
   `I`. Per spostarla nel tempo: clic sul rombo nella timeline, `G`, trascina. Per toglierla:
   clic sul rombo, `X`.
7. **Il ritmo del movimento.** Seleziona i rombi, `T` nella timeline: "Bezier" parte e arriva
   morbido, "Linear" va dritto, "Constant" scatta; sotto "Easing" ci sono anche Back (va oltre e
   torna), Bounce (rimbalza) ed Elastic. Si vedono tutti uguali anche nel gioco.
8. **La trasparenza.** Pannello a destra, linguetta arancione (Object) > Viewport Display >
   Color: l'ultimo numero (Alpha) va da 0 (invisibile) a 1. Ci passi sopra col mouse e premi `I`
   per la chiave. Così entra e sparisce il fumo.
9. **Lo sportello si apre** girando sull'asse verticale: selezionalo, `R` `Z`, scrivi `-110`, Invio.
   Visto di fronte è lo sportello che si spalanca.
10. **Davanti o dietro.** L'asse Y (verso la camera) decide chi sta davanti: `G` `Y` e un numero
    piccolo, per esempio `-0.05` porta il pezzo davanti al corpo. L'oggetto parte dietro (dentro
    la fornace) e passa davanti mentre salta fuori.
11. **Quanto dura.** In fondo alla timeline, Start e End (ora 0 e 150).

## Mandare il lavoro a Claude

Non serve nessun collegamento dentro Blender:

1. salva con Ctrl+S in `C:\Sviluppo\MegaBlast\simulazione\blender\fornace.blend` (sempre lì);
2. scrivi a Claude nel thread «fatto, prendi la fornace».

Claude prende il file dal PC (la cartella `C:\Sviluppo\MegaBlast` è già collegata ai thread del
progetto), lo esporta, lo rigioca e ti manda l'anteprima. Se il PC non è collegato, trascina il
file `.blend` nella chat del thread: va bene lo stesso.

## Esportare e controllare

```bash
blender --background simulazione/blender/fornace.blend --python tools/blender/esporta.py -- --uscita simulazione/blender/fornace.lua
python3 tools/blender/rigioca.py simulazione/blender/fornace.lua simulazione/blender/rigioca
```

Il file Lua ha per ogni pezzo immagine, padre, perno, profondità e le tracce
`<pezzo>_x`, `_y`, `_rot`, `_scale_x`, `_scale_y`, `_alpha`, `_z` nel formato delle clip del
diavoletto (`{ t, valore, 1, ... }`). Si campiona ogni fotogramma e si tengono solo le chiavi
che servono (a meno di un quarto di pixel): il gioco muove i suoi pezzi, niente sequenze di
immagini, e resta liscio a 120 FPS. Le sequenze di fotogrammi restano solo per effetti brevi
(scintille, vampate) disegnati da Codex.
