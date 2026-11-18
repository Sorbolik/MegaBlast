# WB-071 · Il pulsante secondario di ferro e le due monete

- **Stato:** APPROVATA (Sergio, 18 nov 10:12, sulle targhe chiare usate come pulsanti: «non li vorrei usare per nulla, dobbiamo inventarci un'altra soluzione, una sorta di pulsante secondario»)
- **Data:** 2026-11-18
- **Ramo della scheda:** `claude/project-thread-echcwc` (Codex la esegue da qui: `git fetch origin claude/project-thread-echcwc`, non serve che sia su `main`) · **Ramo delle immagini:** `design/WB-071`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-071` senza chiedere conferma (il repository è privato).

## Obiettivo

Oggi le azioni secondarie (ACCENDI LA FIRMA e USA UN BUONO in armeria, POTENZIA nello zaino,
CALENDARIO negli eventi, PIAZZA I PUNTI nella ricevuta) sono **targhe chiare color sabbia** (R1, in
basso al centro): le stesse che usiamo anche come targhe per i titoli, quindi non si capisce cosa si
tocca. Serve **un pulsante secondario** solo, uguale in ogni schermata, con i suoi tre stati:
**acceso**, **premuto** e **spento**. Il primario (la gemma, R2) resta il pezzo più forte della schermata.

## Come devono essere fatti

- **Ferro battuto scuro**, non sabbia né oro: si legge come pulsante (bordo in rilievo, un po' di
  spessore sotto) ma più quieto della gemma.
- Largo circa **quattro volte e mezzo l'altezza**, il **mezzo liscio e vuoto**: il gioco ci scrive
  l'azione in sabbia chiara e lo allunga solo nel mezzo (tre parti: sinistra, mezzo, destra).
- **A sinistra un incavo tondo** vuoto, scuro, incastonato nel ferro: il gioco ci mette l'icona
  dell'azione (gemma, scaglia, buono, calendario). Nessuna icona disegnata dentro.
- **Filo di brace:** un filo di brace sul bordo in basso a sinistra, un tocco di gelo sul bordo in alto
  a destra, sottili (non fiamme né cristalli che escono come nella gemma).
- Stile dei pulsanti della home (R3): china spessa e un po' irregolare, colori pieni, una luce e
  un'ombra piatte, forme morbide un po' storte. Ricalcabile in vettori: al massimo sei colori.
- **Spento** si deve capire a colpo d'occhio: ferro freddo grigio-blu, brace spenta, incavo opaco.
  **Premuto**: lo stesso dell'acceso, schiacciato di qualche pixel (meno spessore sotto), brace più viva.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-071/riferimenti/R1_targhe_chiare_oggi.png` | l'armeria di oggi: in basso al centro la targa chiara ACCENDI LA FIRMA, da sostituire; a destra la gemma +1 LIVELLO |
| R2 | `art/WB-071/riferimenti/R2_primario.png` | la gemma, il pulsante primario: stessa famiglia, ma il secondario deve essere più quieto |
| R3 | `art/WB-071/riferimenti/R3_porta_armeria.png` | un pulsante della home: lo stile della china e del ferro |
| R4 | `art/WB-071/riferimenti/R4_monete_iniziali.png` | le due monete com'erano all'inizio (fatte in codice): la scaglia d'oro e l'ossidiana nera col filo magenta |
| R5 | `art/WB-071/riferimenti/R5_scaglia_oggi.png` | la scaglia di oggi: va tenuta la fiammella dentro |

## Immagini da generare

Il prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto: il primo è
"image 1", il secondo "image 2" e così via.

| Nome file | Cosa c'è | Riferimenti | Misura | Varianti |
|---|---|---|---|---|
| `secondario` | i tre stati, uno sotto l'altro | R1, R2, R3 | 1536×1024 | 3 |
| `monete` | la Scaglia e l'Ossidiana, una accanto all'altra | R4, R5, R3 | 1536×1024 | 3 |

Le varianti si chiamano `secondario_1.png` e così via, in `art/WB-071/`. Per ogni foglio Codex
scrive un `.txt` con lo stesso nome: cosa ha fatto e cosa non è riuscito a rispettare.

### `secondario`

```
Image 1 is a menu screen of our game, a cartoon turn-based artillery game played by little red horned devils. At the bottom center there is a light sand-colored plate with a blue gem and the words ACCENDI LA FIRMA: it is a secondary button, and it must be redesigned because it looks like a title plate, not like something to press. At the bottom right there is the main action button, the orange gem with a flame on the left and ice crystals on the right (image 2 shows it alone): it stays as it is and must remain the strongest button on the screen. Image 3 is another button of the same game and is the STYLE to copy exactly: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, soft hand-drawn slightly crooked shapes, like a cartoon comic.

Draw the new SECONDARY BUTTON as a slab of dark FORGED IRON: a wide rounded slab about four and a half times wider than tall, dark iron (#3A3340) with a lighter top bevel (#5A5263) and a darker thick bottom edge (#1E1A22) that gives it a little thickness, like a key you can press. Along its bottom-left edge a thin glowing ember seam (#F26419 with #FFB703 core), as if the iron was still hot there; along its top-right edge a thin pale frost rim (#CAF0F8). No flames and no crystals sticking out: the slab keeps a clean rounded outline. On the LEFT end there is an empty round socket set into the iron, dark (#151217) with a thin bright rim, about as tall as two thirds of the slab, where the game will place an icon: draw NOTHING inside the socket. The middle of the slab is plain and even, with nothing on it, so text can be written there and the slab can be stretched in width.

Draw it THREE times on the sheet, one above the other, same size, with plenty of plain green (#00FF00) space between them:
1. LIT: as described.
2. PRESSED: the same slab pushed down: the bottom edge much thinner, the whole top a little lower, the ember seam brighter.
3. OFF: the same slab cold: grey-blue iron (#4A5560, bevel #66727D, edge #2A3138), the ember seam dark and dead (#5A3A30), the frost rim dull, the socket matte.
No letters, no numbers, no icons, no shadow on the ground, no glow outside the ink. Background plain green #00FF00 so it can be cut out.
```

### `monete`

Sergio, 18 nov 10:15: «le gemme hanno cambiato forma e colore, voglio tornare almeno al colore
iniziale; anche le scaglie hanno cambiato tutto, così non sembrano più scaglie, però mi piace che
abbiano la fiammella dentro». Il gioco le usa da 20 a 46 px (portafoglio, prezzi, pulsanti).

```
Image 1 shows the two currencies of our game as they were at the beginning: on the left the SCAGLIA, a gold flake shaped like a scale, and on the right the OSSIDIANA, a dark obsidian shard with a bright magenta rim. Image 2 is the gold coin we use today: it no longer looks like a scale, but the little flame inside it is good and must be kept. Image 3 is a button of the same game and is the STYLE to copy exactly: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, soft hand-drawn slightly crooked shapes, like a cartoon comic.

Draw TWO separate icons side by side, well apart, same visual size, on plain green (#00FF00):
1. SCAGLIA: a single thick dragon SCALE, unmistakably a scale: a rounded shield shape, wide and round at the top and coming to a soft point at the bottom, slightly curved like it was pulled off a dragon, with a raised rim. Gold (#FFB703) with a lighter top band (#FFE08A) and a darker bottom edge (#C77A06); in its middle a small orange flame (#F26419 with a #FFB703 core) like the one in image 2.
2. OSSIDIANA: a sharp shard of black volcanic glass, taller than wide, with three or four flat cut faces in near-black purples (#1A1220, #2E2140, #4A3366) and a thin glowing magenta rim along its outline (#FF70D1), one thin pale pink highlight (#FFD6F2) on the top face, like the right icon of image 1 but drawn in the comic style of image 3.
Each icon must read at 24 pixels: one bold silhouette, no thin details. No letters, no numbers, no shadow on the ground, no glow outside the ink.
```

## Criteri di accettazione

- [ ] contorno nero puro e spesso, nessuna scritta, nessuna icona nell'incavo
- [ ] il mezzo è liscio e uguale: si allunga in larghezza senza deformare i capi
- [ ] accanto alla gemma (R2) si legge come secondario: più scuro e più quieto
- [ ] spento si distingue dall'acceso anche in bianco e nero
- [ ] i tre stati hanno la stessa sagoma e la stessa grandezza (si sovrappongono)
- [ ] la scaglia si riconosce come scaglia anche a 24 px, con la fiammella dentro
- [ ] l'ossidiana ha il colore iniziale: nera e viola col filo magenta

---

## Decisione

Sergio, 18 nov 10:15: le monete tornano almeno al colore iniziale (l'ossidiana nera col filo
magenta), la scaglia torna a sembrare una scaglia e tiene la fiammella. Aggiunte a questa scheda
per lanciarle insieme.

Sergio, 18 nov 10:12: le targhe chiare non vanno più usate come pulsanti né come targhe. Claude ha
scelto: ferro scuro con l'incavo per l'icona (il secondario dice l'azione con l'icona, il primario
con la forma), tre stati come la gemma. Numero assegnato dal coordinatore.

## Consegna di Codex

- `art/WB-071/secondario_1.png`, `secondario_2.png`, `secondario_3.png` e i tre `.txt` omonimi. Rispettivamente 2, 1 e 1 tentativi con immagine prodotta.
- `art/WB-071/monete_1.png`, `monete_2.png`, `monete_3.png` e i tre `.txt` omonimi. Un'immagine prodotta per variante. Due chiamate per la terza variante si sono fermate alla lettura dei riferimenti.

I sei PNG misurano 1536×1024 px. I tre fogli delle monete sono stati ridotti in proporzione e centrati con margini verdi. Il verde generato presenta lievi scostamenti da #00FF00. Verificati contorni spessi, separazione, assenza di scritte, incavi vuoti e centri liberi. Il premuto è più basso e nello spento la brace è scura. Il contrasto fra acceso e spento è tenue in scala di grigi. I tre stati differiscono leggermente in altezza e nei bordi e non si sovrappongono esattamente. Le sfumature e l'antialias producono più di sei valori RGB. La Scaglia con fiammella e l'Ossidiana nera e viola con bordo magenta si riconoscono in anteprima a 24 px. Ritaglio, allungamento a tre parti, ricalco e resa in gioco da verificare.

## Resoconto di Claude
