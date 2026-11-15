# WB-062 · Sigilli: «o l'uno o l'altro» e le tacche dei punti

- **Stato:** APPROVATA (Sergio, 15 nov 22:48: «per i sigilli A e bivio»)
- **Data:** 2026-11-15
- **Ramo della scheda:** `claude/project-thread-bpo2v6` (Codex la esegue da qui: `git fetch origin claude/project-thread-bpo2v6`, non serve che sia su `main`) · **Ramo delle immagini:** `design/WB-062`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-062` senza chiedere conferma (il repository è privato).

## Obiettivo

Nella pagina dei Sigilli (R3) ogni gradino ha due poteri ma non si capisce che se ne tiene
**uno solo**; e i punti non si vedono uno per uno. Claude ha disegnato tre forme possibili
per il gradino (R1) e Sergio ha scelto la **2, il bivio**, dentro la pagina A (R2: il sentiero
dei punti corre in orizzontale, a ogni gradino si divide in un ramo verso l'alto e uno verso
il basso, il fuoco scorre solo nel ramo scelto; tacche e pulsanti − e +). Qui servono i pezzi
del bivio disegnati bene e i pezzi piccoli delle tacche.

## Come devono essere fatti

- **Interno piatto e senza scritte:** il gioco scrive i nomi dei poteri sopra. Lascia spazio
  vuoto e piatto dove in R1 ci sono le parole.
- **Ricalcabili in vettori:** colori pieni (al massimo cinque per pezzo), china nera chiusa e
  spessa, nessun dettaglio più sottile della china.
- **Stessa famiglia di WB-022** (R4, R5): stessa china, stesso ferro scuro, stessa brace.
- **Pezzi separati, da montare nel gioco:** il gioco li mette in fila e li allunga, quindi
  ogni pezzo sta da solo: tratto di sentiero, nodo del gradino, ramo su, ramo giù, piastra del
  potere. Ogni pezzo in tre stati: acceso (fuoco), spento (ferro), chiuso (ferro scuro).

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-062/riferimenti/R1_tre_forme_bivio.png` | le tre forme provate: va disegnata la 2, il bivio |
| R2 | `art/WB-062/riferimenti/R2_bozza_sigilli.png` | la pagina scelta (A col bivio) montata sul gioco vero: dove va ogni pezzo |
| R3 | `art/WB-062/riferimenti/R3_sigilli_oggi.png` | la pagina di oggi nel gioco |
| R4 | `art/WB-022/pezzo_pannello.png` | il pannello di WB-022: stile della china e del ferro |
| R5 | `art/WB-022/pezzo_piccoli.png` | pezzi piccoli di WB-022: grandezza della china |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto: il
primo è "image 1", il secondo "image 2" e così via.

| Nome file | Cosa c'è | Riferimenti | Misura | Varianti |
|---|---|---|---|---|
| `pezzi_bivio` | sentiero, nodo, ramo su, ramo giù, piastra, ognuno acceso, spento e chiuso | R2, R1, R4, R5 | 1536×1024 | 3 |
| `tacche` | tacca vuota e piena nei tre colori, fiamma dei punti liberi, pulsanti − e + | R2, R4, R5 | 1024×1024 | 2 |

Le varianti si chiamano `pezzi_bivio_1.png` e così via, in `art/WB-062/`. Per ogni foglio
Codex scrive un `.txt` con lo stesso nome: cosa ha fatto e cosa non è riuscito a rispettare.

### `pezzi_bivio`

```
Image 1 is a mock-up of a skill tree screen of our game: a horizontal path of points runs from left to right, at each step there is a round numbered node, and from the node the path splits into a branch going UP to one power plate and a branch going DOWN to another power plate; the player keeps only one of the two powers, so fire flows only in the chosen branch. Image 2 shows the fork idea alone (number 2, the Y-shaped path). Images 3 and 4 show pieces of the same game interface and are the STYLE to copy exactly: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow per piece, soft hand-drawn slightly crooked shapes, like a cartoon comic. Ember is #F26419 with a lighter band #FFB703 and a darker band #B8440F, dark iron is #2B2530 with highlight #6B6375, darker iron for locked is #1E1A20, gold is #FFC83D, ice blue for the points already earned is #8FDCFF with highlight #CAF0F8.
Draw a clean sheet on a fully transparent background with separate pieces, well spaced, nothing touching, in three rows. Row 1 LIT: a straight horizontal path segment (a thick rounded rail, ice blue, like a channel where points flow), a round node disc in gold with an empty flat center for a number, a branch that leaves the node going up and then curves to the right (glowing ember, fire flowing inside), the same branch going down and curving to the right, and a rounded power plate in ember (wide, flat empty center for two lines of text). Row 2 OFF: the same five pieces in dull dark iron (the branch not chosen, the plate not chosen), the plate keeps a clear ink border and a flat dark center. Row 3 LOCKED: the same five pieces in darker iron, the node with a tiny gold padlock instead of the empty center. All pieces must join edge to edge when placed side by side (same rail thickness everywhere). No letters, no numbers, no background, no shadows on the ground, no glow outside the ink.
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
- [ ] nel foglio del bivio si capisce a colpo d'occhio che il fuoco va in un ramo solo
- [ ] le zone per i nomi dei poteri sono piatte e vuote
- [ ] le tacche si leggono a 24 px: vuota e piena ben diverse
- [ ] i pezzi non si toccano (si ritagliano uno per uno)

---

## Decisione

Sergio, 15 nov 22:48: pagina A col bivio (forma 2).

## Consegna di Codex

| PNG e TXT omonimi in `art/WB-062/` | Tentativi | Esito visivo |
|---|---:|---|
| `pezzi_bivio_1` | 3 | Conservato il secondo tentativo. Tutti i 15 pezzi, con i nodi spento e chiuso in ferro. Rimangono aloni attorno ai pezzi. |
| `pezzi_bivio_2` | 3 | Conservato il primo tentativo per lo sfondo più pulito. Nodo spento e nodo chiuso dorati. Foglio adattato in proporzione con margini trasparenti. |
| `pezzi_bivio_3` | 3 | Conservato il secondo tentativo per gli attacchi orizzontali dei due rami. Nodi spento e chiuso dorati e aloni residui. |
| `tacche_1` | 1 | Quattro tacche, due fiamme e quattro pulsanti ben separati. Foglio adattato in proporzione con margini trasparenti. |
| `tacche_2` | 2 | Quattro tacche, due fiamme e quattro pulsanti. Secondo tentativo più pulito, adattato in proporzione con margini trasparenti. |

Controllati a vista conteggio, separazione, centri vuoti delle piastre e assenza di scritte. Verificato il canale alfa agli angoli. Innesti, resa dei singoli pezzi a 24 px e colori esatti da verificare nel gioco.

## Resoconto di Claude
