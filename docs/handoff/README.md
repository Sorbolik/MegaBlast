# Schede di lavoro

Claude e ChatGPT si passano il lavoro solo da qui. Una scheda per attività, numerata
(`WB-001_<argomento>.md`, `WB-002_...`), copiata da [MODELLO.md](MODELLO.md).
Le foto di verifica di Claude vanno in `img/`, le immagini di ChatGPT in `art/WB-xxx/`.

## Il ciclo

1. **Nasce la scheda**, di solito da Claude che coordina (a volte da ChatGPT o Sergio):
   obiettivo, riferimenti, requisiti, cosa non toccare, criteri di accettazione, consegne,
   domande aperte.
2. **PROPOSTA**: finché resta così nessuno la esegue.
3. **Si decide** nella sezione "Decisione": Claude approva da solo le scelte ragionevoli e
   reversibili (e lo scrive), le altre le decide Sergio; sempre con la data.
4. **Chi la riceve la esegue**:
   - ChatGPT fa le immagini sul suo ramo `design/...` e scrive la "Consegna di ChatGPT";
   - Claude controlla la scheda sul codice vero, la integra nel gioco, gira la simulazione
     e scrive il "Resoconto di Claude" (file cambiati, cosa ha verificato, cosa no, foto).
   Stato IMPLEMENTATA.
5. **L'altro rivede** nella sezione "Revisione" e segnala le differenze dalla richiesta.
6. **Sergio prova nel gioco**: solo allora VERIFICATA. Claude aggiorna `DECISIONI.md` se serve.

Nella scheda non si cancella niente: ognuno aggiunge la sua parte sotto. Se una richiesta
non si può fare, lo si scrive lì e la scheda torna a chi decide.

## Passaggi densi

Ogni messaggio in più costa tempo e token. Una scheda deve bastare da sola: numeri, misure,
nomi dei file, riferimenti alle immagini, formato della consegna, tutto in un colpo.
