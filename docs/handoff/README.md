# Schede di lavoro

Claude scrive qui i prompt delle immagini, Codex (ChatGPT) le genera: nessun copia e incolla
di prompt. Una scheda per attività, numerata (`WB-001_<argomento>.md`, `WB-002_...`),
copiata da [MODELLO.md](MODELLO.md). Le regole di Codex sono in [AGENTS.md](../../AGENTS.md).

## Il ciclo

1. **Claude scrive la scheda**: obiettivo, riferimenti, e la tabella "Immagini da generare"
   con il prompt completo di ogni immagine, i riferimenti da allegare e il nome del file.
   Stato PROPOSTA.
2. **Si decide**: Claude approva da solo le schede ragionevoli e reversibili (e lo scrive),
   le altre le decide Sergio. Stato APPROVATA. Claude fa il commit e il push della scheda.
3. **Codex genera**: Sergio gli dice "esegui WB-xxx". Codex genera tutto in `art/WB-xxx/`,
   scrive la consegna, fa il commit sul ramo `design/WB-xxx` e il push. Stato GENERATA.
4. **Claude rivede e integra**: guarda le immagini, scarta quelle con difetti (e se serve
   aggiunge una scheda nuova coi prompt corretti), taglia e integra quelle buone, gira la
   simulazione, scrive il "Resoconto di Claude" con le foto in `img/`. Stato IMPLEMENTATA.
5. **Sergio prova nel gioco**: solo allora VERIFICATA.

Nella scheda non si cancella niente: ognuno aggiunge la sua parte sotto.

## Le chat da cancellare

Con Codex le immagini non passano dalle chat di ChatGPT, quindi non restano chat aperte da
ripulire. Le sessioni di Codex stanno solo sul PC (`%USERPROFILE%\.codex\sessions`) e le
immagini generate in `%USERPROFILE%\.codex\generated_images`: dopo il push si possono
cancellare tutte e due.

## Fogli sullo stampino

Per i pezzi del personaggio (`strumenti/stampino/`, taglio con `taglia.py --allinea`): un
pezzo per casella, nell'ordine dello stampino, staccati fra loro, sfondo magenta; la coda
intera con la radice più spessa della punta; il verde #00FF00 solo per il colore della
squadra. Il disegno di riferimento va allegato per primo e il prompt deve dire che lo
stampino serve solo per posizioni e misure, altrimenti Codex copia le forme del manichino.
