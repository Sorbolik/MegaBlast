# WB-062 · Sigilli: «o l'uno o l'altro» e le tacche dei punti

- **Stato:** APPROVATA (Claude, 15 nov: Sergio ha chiesto «altre proposte anche usando codex per fare capire che quei pulsanti ti fanno scegliere o l'una o l'altra»; sono solo immagini di prova, reversibili)
- **Data:** 2026-11-15
- **Ramo della scheda:** `claude/project-thread-bpo2v6` (Codex la esegue da qui: `git fetch origin claude/project-thread-bpo2v6`, non serve che sia su `main`) · **Ramo delle immagini:** `design/WB-062`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-062` senza chiedere conferma (il repository è privato).

## Obiettivo

Nella pagina dei Sigilli (R3) ogni gradino ha due poteri ma non si capisce che se ne tiene
**uno solo**; e i punti non si vedono uno per uno. Claude ha disegnato tre forme possibili
per il gradino (R1: sigillo spezzato, bivio, leva) e la bozza della pagina (R2: tacche a
fiamma, pulsanti − e +). Qui servono i fogli disegnati bene, per far scegliere a Sergio la
forma, e i pezzi piccoli delle tacche.

## Come devono essere fatti

- **Interno piatto e senza scritte:** il gioco scrive i nomi dei poteri sopra. Lascia spazio
  vuoto e piatto dove in R1 ci sono le parole.
- **Ricalcabili in vettori:** colori pieni (al massimo cinque per pezzo), china nera chiusa e
  spessa, nessun dettaglio più sottile della china.
- **Stessa famiglia di WB-022** (R4, R5): stessa china, stesso ferro scuro, stessa brace.
- **Tre stati per ogni forma:** scelto a sinistra, scelto a destra, chiuso (punti non
  ancora arrivati: tutto spento, con un piccolo lucchetto).

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-062/riferimenti/R1_tre_forme_bivio.png` | le tre forme del gradino (segnaposto di Claude, da ridisegnare bene) |
| R2 | `art/WB-062/riferimenti/R2_bozza_sigilli.png` | la bozza della pagina: tacche a fiamma, pulsanti − e + |
| R3 | `art/WB-062/riferimenti/R3_sigilli_oggi.png` | la pagina di oggi nel gioco |
| R4 | `art/WB-022/pezzo_pannello.png` | il pannello di WB-022: stile della china e del ferro |
| R5 | `art/WB-022/pezzo_piccoli.png` | pezzi piccoli di WB-022: grandezza della china |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto: il
primo è "image 1", il secondo "image 2" e così via.

| Nome file | Cosa c'è | Riferimenti | Misura | Varianti |
|---|---|---|---|---|
| `forme_gradino` | le tre forme, ognuna nei tre stati (griglia 3×3) | R1, R3, R4, R5 | 1536×1024 | 3 |
| `tacche` | tacca vuota e piena nei tre colori, fiamma dei punti liberi, pulsanti − e + | R2, R4, R5 | 1024×1024 | 2 |

Le varianti si chiamano `forme_gradino_1.png` e così via, in `art/WB-062/`. Per ogni foglio
Codex scrive un `.txt` con lo stesso nome: cosa ha fatto e cosa non è riuscito a rispettare.

### `forme_gradino`

```
Image 1 is a rough mock-up made by hand of three ways to draw ONE step of a skill tree where the player can keep only one of two powers: (1) a round seal broken in two halves with a zig-zag crack, the chosen half lit and the other half dull and slightly detached; (2) a Y-shaped path that splits in two branches, fire flows only in the chosen branch, a small gold disc sits at the fork; (3) a forge lever between two plates, the lever points at the chosen plate. Image 2 is the game screen where these steps go today. Images 3 and 4 show pieces of the same game interface and are the STYLE to copy exactly: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow per piece, soft hand-drawn slightly crooked shapes, like a cartoon comic. Dark iron is #2B2530 with highlight #6B6375, ember is #F26419 with a lighter band #FFB703 and a darker band #B8440F, gold is #FFC83D, dull grey is #3A3340.
Draw a clean sheet on a fully transparent background with a 3 by 3 grid of separate pieces, well spaced, nothing touching. Row 1: the broken seal. Row 2: the Y path. Row 3: the lever. Column 1: the LEFT power chosen (left part glowing ember, right part dull iron). Column 2: the RIGHT power chosen (mirror). Column 3: LOCKED (both parts dull dark iron, a small round gold padlock in the middle). The parts where a power name goes must be large, flat and EMPTY, no letters, no icons, no numbers anywhere. Same ink thickness on every piece. No background, no shadows on the ground, no glow outside the ink, no text.
```

### `tacche`

```
Image 1 is a rough mock-up of a game screen where the player spends points one by one on three paths: each path has a row of 25 small pips in groups of five, a round minus button and a round plus button, and on top a small flame counter of free points. Images 2 and 3 show pieces of the same game interface and are the STYLE to copy exactly: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow per piece, soft hand-drawn slightly crooked shapes, like a cartoon comic.
Draw a clean sheet on a fully transparent background with separate small pieces, well spaced, nothing touching, each piece readable at 24 pixels tall:
row 1: an EMPTY pip (a small slightly crooked rounded diamond, dark iron #1A1418 inside, black ink) and the same pip FULL in ice blue #8FDCFF with highlight #CAF0F8;
row 2: the pip FULL in ember #F26419 with lighter band #FFB703, and the pip FULL in mint green #5FE0B0 with a lighter band;
row 3: a small flame shaped pip in ember (the free point to spend), and the same flame dull grey (#3A3340, spent);
row 4: a round MINUS button (dark iron #3A3340 with a flat ivory #F4ECE1 minus sign) and a round PLUS button (ember gradient body #FFB347 to #F26419 with a dark #2A1208 plus sign), each also in a dull disabled version.
No letters, no numbers, no background, no glow outside the ink.
```

## Criteri di accettazione

- [ ] sfondo trasparente pulito, contorno nero puro e spesso, nessuna scritta
- [ ] nei fogli delle forme si capisce a colpo d'occhio che si tiene una parte sola
- [ ] le zone per i nomi dei poteri sono piatte e vuote
- [ ] le tacche si leggono a 24 px: vuota e piena ben diverse
- [ ] i pezzi non si toccano (si ritagliano uno per uno)

---

## Decisione

Approvata da Claude il 15 nov (immagini di prova). La forma da usare la sceglie Sergio
dai fogli.

## Consegna di Codex

## Resoconto di Claude
