---
name: valuta-meccanica
description: Passa una meccanica di MegaBlast (proposta o già nel gioco) attraverso cinque filtri (chiarezza, motivazione, risposta, soddisfazione, coerenza) e dà un verdetto con le correzioni. Usala prima di implementare una scheda o quando qualcosa "non convince".
---

# Valuta una meccanica

Giudica una meccanica con cinque filtri. Per ognuno dai un voto (✅ regge,
⚠️ da sistemare, ❌ non regge) con una riga di motivo concreto, citando la
regola o il numero che lo causa.

Fonti: la scheda o la sezione di `docs/design.md`, e il codice in `client/sim/`
se la meccanica esiste già. Se manca un'informazione per un filtro, scrivi
"non valutabile: manca X" invece di indovinare.

## I cinque filtri

1. **Chiarezza.** Un giocatore nuovo capisce cosa fa guardandola una volta?
   Il risultato si prevede dalla mira (linea tratteggiata, raggio visibile,
   timer sopra l'oggetto)? Si spiega in una riga della tabella armi?
2. **Motivazione.** C'è un momento della partita in cui è la scelta migliore,
   e uno in cui non lo è? Se è sempre la migliore schiaccia le altre; se non lo
   è mai, nessuno la userà. Crea una decisione nuova (posizione, tempo, rischio)?
3. **Risposta.** Ogni azione ha un riscontro immediato e leggibile su un
   telefono piccolo: animazione, numero del danno, scuotimento, suono? Si capisce
   chi ha colpito chi anche guardando il turno dell'avversario?
4. **Soddisfazione.** Il colpo riuscito si sente (peso, impatto, cratere)? Chi
   lo subisce capisce cosa è successo e pensa "potevo evitarlo", non "è
   ingiusto"? C'è spazio per un colpo da maestro (combo, rimbalzo, teletrasporto)?
5. **Coerenza.** Rispetta le regole del gioco: turni brevi, server autoritativo
   e simulazione deterministica, niente vento, niente pay-to-win, mobile e
   leggero, stile "Le Scorie"? Interagisce bene con armi, casse, teletrasporto,
   collisioni tra robot e ritirata già esistenti?

## Controlli in più, specifici di MegaBlast

- **Turno**: si usa bene in 25 s compresa la mira? Lascia senso ai due attacchi e agli 8 s dopo il primo?
- **Online**: tutto ciò che decide l'esito sta nella simulazione e non dipende
  dal client? Servono messaggi nuovi?
- **2v2 e 1v1v1v1**: funziona anche con quattro robot e con un compagno vicino?
- **Fuga dalla partita**: si può usare per perdere tempo fino ai 3 minuti?

## Risultato

```markdown
## Valutazione: <nome>
| Filtro | Voto | Motivo |
|---|---|---|
...
**Verdetto**: PRONTA / DA RIVEDERE / DA RIPENSARE / NON VALUTABILE
**Correzioni** (in ordine di importanza): 1. ... 2. ...
```

PRONTA solo se nessun ❌ e al massimo un ⚠️ minore. Proponi sempre la
correzione più piccola che risolve il problema.
