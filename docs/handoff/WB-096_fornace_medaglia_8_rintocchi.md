# WB-096 · La Fornace: la medaglia degli 8 rintocchi

- **Stato:** APPROVATA (Claude, 25 nov: Sergio vuole le medaglie da 6, 8 e 10 rintocchi; quelle da 6 e 10 sono di WB-095, questa è la terza della stessa famiglia)
- **Data:** 2026-11-25
- **Ramo della scheda:** `claude/project-thread-ft5von` (Codex la esegue da qui: `git fetch origin claude/project-thread-ft5von`, non serve che sia su `main`) · **Ramo delle immagini:** `design/WB-096`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-096` senza chiedere conferma (il repository è privato).

## Obiettivo

Nella Fornace ([docs/commesse.md](../commesse.md), «Le medaglie dei rintocchi») un rintocco è un colpo della goccia sul ferro di uno stampo nello stesso tiro. La medaglia di bronzo dei 6 rintocchi e quella d'argento con l'intarsio di Ossidiana dei 10 sono nel gioco (WB-095, R1). Manca quella degli **8 rintocchi**: in mezzo alle due, di **acciaio azzurrato**, così non si confonde né col bronzo né con l'argento bianco dei 10.

Misure: nel profilo è un disco di 64 px, nella Fornace salta fuori a 130 px. Nel foglio va larga **almeno 600 px**.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-096/riferimenti/R1_medaglie_6_e_10.png` | le medaglie dei 6 (bronzo, a sinistra) e dei 10 rintocchi (argento con l'intarsio, a destra), nel gioco: la nuova è della stessa famiglia, con lo stesso disegno in diagonale |
| R2 | `art/WB-096/riferimenti/R2_stampi.png` | gli stampi di ferro della Fornace |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto: il primo è "image 1", il secondo "image 2".

| Nome file | Cosa c'è | Riferimenti | Misura | Varianti |
|---|---|---|---|---|
| `medaglia_8` | la medaglia degli 8 rintocchi | R1, R2 | 1024×1024 | 2 |

Le varianti si chiamano `medaglia_8_1.png` e `medaglia_8_2.png`, in `art/WB-096/`. Per ogni foglio Codex scrive un `.txt` con lo stesso nome: cosa ha fatto e cosa non è riuscito a rispettare.

### `medaglia_8`

```
Image 1 shows two medals of our cartoon game: on the left the bronze medal of 6 bounces, on the right the silver medal of 10 bounces. In the middle of each, in relief, a drop of molten obsidian bounces down a diagonal row of iron moulds (like those of image 2), its path a zigzag line of small sparks, a small starburst of short gold rays at every bounce, short rays all around behind. Thick slightly irregular black ink outline, flat colors, one flat highlight.

Draw ONE more medal of the SAME family, the medal of 8 bounces, on plain green (#00FF00), centered, as big as most of the image (at least 600 px wide): round, with the same raised rim and the same ring of round studs as the bronze medal of image 1, in BLUED STEEL (#8FA8C2, highlight #D3E1EE, shadow #4E6278), studs a little lighter. In the middle, in relief, exactly as in image 1: the drop of molten obsidian at the top left, a diagonal row of EIGHT iron moulds going down to the right, each with a colored dot, the zigzag of sparks with EIGHT bounces, a small starburst of gold rays at every bounce, short pale rays behind.
Nothing else: no ribbon, no letters, no numbers, no shadow on the ground, no glow halo around the medal.
```

## Criteri di accettazione

- [ ] una medaglia, acciaio azzurrato, stesso bordo con le borchie del bronzo di R1
- [ ] otto stampi in diagonale e otto rimbalzi che si contano
- [ ] nessuna scritta, nessun numero, nessun alone, fondo verde pieno (si ritaglia)

---

## Decisione

Approvata da Claude il 25 nov sulla richiesta di Sergio («fai sia medaglia da 6 che da 8 e da 10 ... poi te la faccio con Codex»). Il gioco è già pronto: la medaglia si dà quando c'è il suo disegno (`orders.FORGE_BADGES`, `art = true`).
