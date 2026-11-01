# WB-002 · Personaggio di Sergio: espressioni e versione femminile

- **Stato:** APPROVATA (Claude, 2026-11-01: sono prove di stile, reversibili, non entrano nel gioco)
- **Data:** 2026-11-01
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-002`

## Obiettivo

Sergio ha disegnato un personaggio nuovo (maschio, bianco e nero, tre espressioni). Prima
di smontarlo in pezzi servono due prove: tante espressioni della stessa testa, e una
versione femminile coerente. Sono solo prove da guardare insieme: **sfondo bianco**, non
trasparente (eccezione alla regola 4 di `AGENTS.md`), e nessun taglio in pezzi.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-002/riferimenti/R1_felice.png` | il personaggio di Sergio, felice |
| R2 | `art/WB-002/riferimenti/R2_arrabbiato.png` | lo stesso, arrabbiato (sopracciglia bianche) |
| R3 | `art/WB-002/riferimenti/R3_sorpreso.png` | lo stesso, sorpreso (bocca a "o") |

## Immagini da generare

Ogni prompt è completo e va usato così com'è.

| Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|
| `espressioni` | R1, R2, R3 | 1024×1024 | 1 |
| `femmina` | R1 | 1536×1024 orizzontale | 1 (con tre personaggi affiancati) |

### `espressioni`

Archivio prompt: P-001 v1.

```
Ti allego tre disegni del mio personaggio originale (stessa posa, tre espressioni: felice, arrabbiato, sorpreso). È il riferimento ESATTO di stile e di forme: non reinterpretarlo.

Disegna un foglio di espressioni dello stesso personaggio: 9 teste in una griglia 3x3, su sfondo bianco puro, ogni testa ben separata dalle altre, tutte della stessa grandezza e nella stessa angolazione dei miei disegni.

Il personaggio, da rispettare alla lettera:
- testa nera piena a forma di stella con punte irregolari: due punte alte in cima (la destra più alta e sottile), una punta per lato più corta
- due occhi enormi ovali bianchi con contorno nero spesso, che si toccano e si sovrappongono un po' al centro; pupille nere ovali piccole
- bocca piccola sotto gli occhi, sul nero
- stile: bianco e nero puro, nero pieno e bianco pieno, contorni neri spessi e regolari, nessuna sfumatura, nessun grigio, nessun colore, nessuna texture. Look da cartone animato anni '30 "rubber hose", disegnato a mano ma pulito

Le espressioni cambiano SOLO con: forma e posizione delle pupille, palpebre (taglio nero sopra o sotto l'occhio bianco), sopracciglia bianche sottili come nel disegno arrabbiato, forma della bocca. La sagoma della testa e degli occhi resta identica.

Le 9 espressioni (scrivi il nome sotto ciascuna in piccolo):
1. felice (come il mio disegno)
2. arrabbiato (come il mio disegno)
3. sorpreso (come il mio disegno)
4. ghigno furbo (un occhio socchiuso, bocca storta a mezzaluna)
5. concentrato a mirare (occhi stretti, pupille verso destra, bocca piatta stretta)
6. dolore, appena colpito (occhi chiusi strizzati a forma di > <, bocca aperta a zigzag)
7. stordito (pupille a spirale, bocca ondulata)
8. vittoria (occhi chiusi a mezzaluna felici, bocca grande aperta che ride)
9. triste, sconfitto (pupille in basso, palpebre calate, bocca all'ingiù)

Non aggiungere naso, orecchie, capelli, denti, lingua colorata o altri dettagli che non ci sono nel mio disegno.
```

### `femmina`

Archivio prompt: P-002 v1.

```
Ti allego il mio personaggio originale maschile. Disegna la sua versione FEMMINILE, come se fossero due personaggi della stessa serie animata: stesso stile, stesse proporzioni, stessa posa, stessa grandezza.

Stile da rispettare alla lettera: bianco e nero puro, nero pieno e bianco pieno, contorni neri spessi e regolari, nessuna sfumatura, nessun grigio, nessun colore. Cartone animato anni '30 "rubber hose", pulito.

Cosa resta UGUALE al maschio:
- corpo nero pieno, braccia corte a tubo, guanti bianchi grossi con le dita a pugno, gambe nere sottili, scarpe nere grandi e tonde
- occhi enormi ovali bianchi che si toccano al centro, pupille nere ovali, bocca piccola
- testa nera a forma di stella con punte
- posa: in piedi frontale, pugni alzati ai lati del corpo, espressione felice

Cosa cambia per renderla femminile (poche differenze ma leggibili anche in piccolo, come una sagoma):
- le punte della testa più morbide e curve all'indietro, con una punta lunga che scende di lato come un ciuffo o una coda
- ciglia: tre ciglia nere spesse sul bordo esterno di ogni occhio
- un fiocco bianco con contorno nero su una punta della testa
- al posto dei pantaloncini bianchi una gonnellina bianca corta a campana, con contorno nero
- scarpe nere tonde con un piccolo cinturino bianco

Sfondo bianco puro. Un solo personaggio per variante, intero, centrato, nessun testo.
Fammi 3 varianti affiancate, da sinistra a destra: A con tutte le differenze sopra, B senza fiocco, C con le punte della testa uguali al maschio e solo ciglia, fiocco e gonnellina.
```

## Criteri di accettazione

- [ ] bianco e nero puro, contorni neri spessi, nessun grigio né colore, sfondo bianco
- [ ] sagoma di testa, occhi, guanti e scarpe uguale ai disegni di Sergio
- [ ] `espressioni`: 9 teste uguali di forma, cambiano solo occhi, sopracciglia e bocca
- [ ] `femmina`: tre varianti A, B, C riconoscibili come la stessa serie del maschio

---

## Decisione

Approvata da Claude il 2026-11-01 (prove reversibili). Sergio sceglie dopo aver visto le immagini.

## Consegna di Codex

## Resoconto di Claude
