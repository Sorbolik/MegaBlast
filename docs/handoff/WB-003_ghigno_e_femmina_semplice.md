# WB-003 · Personaggio di Sergio: ghigno furbo corretto e femmina semplice

- **Stato:** APPROVATA (Claude, 2026-11-01: prove di stile, reversibili, non entrano nel gioco)
- **Data:** 2026-11-01
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-003`

## Obiettivo

Seguito di WB-002. Sergio approva il foglio di espressioni tranne il **ghigno furbo**, da
rifare. La versione femminile va ripensata **più semplice**: quasi uguale al maschio, con
una o due differenze al massimo. Sfondo bianco, non trasparente (sono prove).

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-002/riferimenti/R1_felice.png` | il personaggio di Sergio, felice |
| R2 | `art/WB-002/riferimenti/R2_arrabbiato.png` | lo stesso, arrabbiato (sopracciglia bianche) |
| R3 | `art/WB-002/riferimenti/R3_sorpreso.png` | lo stesso, sorpreso |
| R4 | `art/WB-002/espressioni.png` | il foglio di espressioni approvato (se c'è sul PC; se manca, salta R4) |

## Immagini da generare

Ogni prompt è completo e va usato così com'è.

| Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|
| `ghigno` | R1, R2, R4 | 1024×1024 | 3 |
| `femmina_semplice` | R1 | 1536×1024 orizzontale | 1 (quattro personaggi affiancati) |

### `ghigno`

Archivio prompt: P-001 v2 (solo il ghigno furbo).

```
Ti allego il mio personaggio originale (felice e arrabbiato) e, se c'è, il foglio di espressioni che hai già fatto e che mi piace. Rifai SOLO la testa con l'espressione "ghigno furbo", nello stesso identico stile e con la stessa sagoma delle altre teste: testa nera piena a stella con le punte, due occhi enormi ovali bianchi che si toccano al centro, contorni neri spessi, bianco e nero puro, nessun grigio, nessun colore.

Il ghigno furbo deve leggersi subito, anche piccolo, come qualcuno che sta per fare uno scherzo:
- occhio sinistro: palpebra nera che copre la metà superiore dell'ovale bianco, taglio dritto e un po' inclinato verso il centro
- occhio destro: aperto, con un sopracciglio bianco sottile alzato e curvo sopra
- pupille piccole tutte e due spostate di lato, verso destra, come se guardasse il bersaglio con la coda dell'occhio
- bocca: un sorriso storto bianco con contorno nero, sale solo da un lato (verso destra), chiuso, senza denti

Una sola testa, centrata, su sfondo bianco puro, nessuna scritta. Stessa grandezza e angolazione delle altre teste del foglio.
```

### `femmina_semplice`

Archivio prompt: P-002 v2.

```
Ti allego il mio personaggio originale maschile. Disegna la sua versione FEMMINILE, ma SEMPLICE: deve sembrare quasi identica al maschio, stesso corpo, stessa testa a stella con le stesse punte, stessi occhi, stessi guanti, stesse gambe e scarpe, stessa posa (in piedi frontale, pugni alzati ai lati), stessa espressione felice. Non aggiungere gioielli, cuori, trucco, capelli o altri dettagli.

Stile da rispettare alla lettera: bianco e nero puro, nero pieno e bianco pieno, contorni neri spessi e regolari, nessuna sfumatura, nessun grigio, nessun colore. Cartone animato anni '30 "rubber hose", pulito.

Fammi 4 varianti affiancate da sinistra a destra, ognuna con UNA SOLA differenza dal maschio:
A. tre ciglia nere spesse sul bordo esterno di ogni occhio, tutto il resto identico
B. al posto dei pantaloncini bianchi una gonnellina bianca corta a campana, tutto il resto identico
C. un piccolo fiocco bianco con contorno nero alla base della punta più alta della testa, tutto il resto identico
D. le due punte alte della testa un po' più morbide e curve verso l'esterno, come due codini, tutto il resto identico

Sfondo bianco puro, i quattro personaggi della stessa grandezza e ben separati, sotto ciascuno solo la lettera A, B, C o D.
```

## Criteri di accettazione

- [ ] bianco e nero puro, contorni neri spessi, nessun grigio né colore, sfondo bianco
- [ ] `ghigno`: stessa sagoma delle teste di WB-002, un occhio socchiuso, sorriso storto da un lato
- [ ] `femmina_semplice`: ogni variante ha una sola differenza dal maschio

---

## Decisione

Approvata da Claude il 2026-11-01 (prove reversibili). Sergio sceglie dopo aver visto le immagini.

## Consegna di Codex

## Resoconto di Claude
