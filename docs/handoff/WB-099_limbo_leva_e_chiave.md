# WB-099 · Il Limbo: la leva che capovolge la mappa e la chiave

- **Stato:** APPROVATA (da Claude il 27 nov, sulle scelte di Sergio dello stesso giorno)
- **Data:** 2026-11-27
- **Ramo della scheda:** `claude/project-thread-t9n34l` (Codex la esegue da qui: `git fetch origin claude/project-thread-t9n34l`, non serve che sia su `main`) · **Ramo delle immagini:** `design/WB-099`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-099` senza chiedere conferma (il repository è privato).

## Obiettivo

Nel Limbo (girone I) la gravità non è più ridotta: sulla mappa spunta una **leva** d'acciaio. Chi la colpisce, con un
colpo o col corpo, fa capovolgere la mappa: tutti cadono dall'altra parte. Dopo lo scatto la leva sparisce e rispunta su
un'altra borchia d'acciaio, su qualsiasi faccia (sopra, sotto, di lato): il gioco la gira da solo, quindi va disegnata una
volta sola, dritta. Servono due pezzi separati, perché il manico scatta da una parte all'altra (il gioco lo ruota attorno
al perno): la **piastra** con il perno e il **manico**. Nel livello 2 c'è anche una **chiave** da prendere (l'uscita
segreta del girone).

Misure nel gioco: allo zoom più vicino la piastra è larga circa 60 px e il manico lungo circa 90 px, la chiave circa 50 px.
Nel foglio ogni pezzo va grande **almeno 400 px** (si rimpicciolisce, mai si ingrandisce).

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-099/riferimenti/R1_mappa_limbo.jpg` | la mappa del Limbo nuova, dipinta dal gioco: l'acciaio delle travi e delle borchie, i colori |
| R2 | `art/WB-099/riferimenti/R2_leva_segnaposto.png` | la leva segnaposto di Claude sulla borchia: dove sta e come scatta (solo per la posizione, non per lo stile) |
| R3 | `art/WB-099/riferimenti/R3_cassa.png` | la cassa del gioco: lo stile degli oggetti del mondo (contorno nero spesso, colori pieni, una luce e un'ombra piatte) |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto: il primo è "image 1", il secondo "image 2", il terzo "image 3".

| Nome file | Cosa c'è | Riferimenti | Misura | Varianti |
|---|---|---|---|---|
| `leva_e_chiave` | la piastra col perno, il manico e la chiave, separati | R3, R1, R2 | 1536×1024 | 2 |

Le varianti si chiamano `leva_e_chiave_1.png`, `leva_e_chiave_2.png`, in `art/WB-099/`. Per ogni foglio Codex scrive un `.txt` con lo stesso nome: cosa ha fatto e cosa non è riuscito a rispettare.

### `leva_e_chiave`

```
Image 1 is a supply crate from our cartoon game: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, no gradients. Image 2 is a map of the same game (the Limbo, a ruined grey-green castle): look at the riveted steel beams and the small square steel studs. Image 3 only shows WHERE a lever sits on one of those studs and how it snaps; ignore its drawing style.

Draw THREE SEPARATE OBJECTS in the style of image 1, on plain green (#00FF00), well apart from each other, seen straight from the front, nothing touching:
1. LEFT: the LEVER BASE, a square riveted steel plate like the studs of image 2 (steel #59666D, highlight #A9BDC8, dark edge #1B2124), with four rivets in the corners and a round iron hinge in the exact middle (a ring with a dark hole). At least 450 px wide.
2. MIDDLE: the LEVER HANDLE alone, lying horizontal: a straight steel rod (same steel colors) with, at its LEFT end, a round eye that fits on the hinge, and at its RIGHT end a big round knob of molten gold (#FFB703, highlight #FFE08A, shadow #C47A00), like a ball you want to hit. At least 600 px long, the rod about one eighth as thick as long.
3. RIGHT: an old castle KEY of tarnished gold (#E3B341, highlight #FFE7A0, shadow #9C6E12) with a ring bow shaped like a small crenellated tower and a two-tooth bit, lying horizontal, at least 450 px long.
Nothing else: no floor, no wall, no letters, no numbers, no shadow on the ground, no glow, no sparkles.
```

## Criteri di accettazione

- [ ] tre oggetti separati sul verde, nessuno che si tocca: piastra, manico, chiave
- [ ] la piastra è d'acciaio come le borchie della mappa (R1), quadrata, col perno in mezzo
- [ ] il manico è dritto e orizzontale, l'occhiello a sinistra combacia col perno, il pomo d'oro a destra
- [ ] la chiave d'oro vecchio con l'anello a torretta
- [ ] contorno nero spesso, colori pieni, nessuna scritta, nessun alone, fondo verde pieno (si ritaglia)

---

## Decisione

Approvata da Claude il 27 nov sulle scelte di Sergio (thread «Riprogettare la mappa del primo girone», pagina
https://claude.ai/artifact/DHLtwdfJhmDbXWPfZoQ4uF). Finché le immagini non ci sono il gioco usa una leva segnaposto disegnata
nel codice.

## Consegna di Codex

- `art/WB-099/leva_e_chiave_1.png` e `leva_e_chiave_1.txt` — tre tentativi, selezionato il primo.
- `art/WB-099/leva_e_chiave_2.png` e `leva_e_chiave_2.txt` — tre tentativi, selezionato il primo.

Prompt originale e riferimenti R3, R1, R2 in ordine. I fogli ImageGen sono stati ridimensionati in proporzione e centrati su tela verde da 1536×1024. Controllati i tre oggetti separati, i quattro rivetti, il perno centrale, il manico orizzontale con occhiello a sinistra e pomo a destra, la chiave a torretta con due denti e l'assenza di scritte.

La piastra misura 243–245 px, il manico 558–568 px e la chiave 418–421 px. Rimangono sotto i rispettivi minimi del prompt (450, 600 e 450 px). La piastra resta anche sotto i 400 px dell'obiettivo generale. Il verde si discosta da #00FF00. Accoppiamento del perno e resa in gioco da verificare.

## Resoconto di Claude
