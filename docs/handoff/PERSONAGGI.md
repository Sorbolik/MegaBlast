# Come si genera un personaggio

La procedura standard per ogni personaggio (Sergio, 2026-11-01: «dobbiamo standardizzare la
generazione dei personaggi»). La prima scheda che la segue è WB-009, l'apprendista. Il
prossimo personaggio parte **solo** quando quello prima è validato: Sergio lo prova animato
nell'editor delle animazioni.

Ordine deciso da Sergio: 1) l'apprendista (WB-009); 2) Favilla B, la fiamma bianca, dopo la
prova dell'apprendista nell'editor; poi gli altri.

## Le fasi

| Fase | Cosa | Chi |
|---|---|---|
| 0 | Il concept approvato (per esempio una tavola di WB-008) | Sergio sceglie |
| 1 | Tre quarti verso destra nello stile pulito, camminata di prova, foglio di 9 espressioni | ChatGPT; Sergio sceglie, Claude salva in `art/WB-xxx/scelti/` |
| 2 | Foglio dei pezzi sullo stampino + teste in più, copiati dai file scelti | ChatGPT |
| 3 | Taglio con `taglia.py --allinea`, ricalco in SVG, PNG per ogni schermo, editor | Claude |
| 4 | Prova animata nell'editor delle animazioni | Sergio valida |

Mai saltare la fase 1: i pezzi devono copiare un tre quarti approvato (lezione di WB-006).
Claude non ridisegna mai un personaggio col proprio codice: si ricalca il disegno buono.

## Le regole di ogni prompt

- **Prompt in inglese**, completi, uno per immagine; riferimenti allegati in ordine ("image 1"...).
- **Colori piatti**: una tinta per area più al massimo un'ombra netta; niente sfumature,
  texture, tratteggi, bagliori. Serve al ricalco in SVG e a leggere il personaggio in piccolo.
- **Tavolozza fissa** scritta nella scheda con i codici esadecimali, ripetuta in ogni prompt.
- **Contorno nero `#000000` spesso e chiuso**, che **si assottiglia e sparisce alle estremità
  delle giunture** (fondo del collo, collo e spalle del busto, cima di braccia e gambe, radice
  della coda): lì il colore arriva fino al bordo, tondo e
  pieno, senza riga nera. Così sovrapposti non si vede la giuntura.
- **Colore uniforme alle giunture** (Sergio): nell'ultimo tratto prima della giuntura solo il
  colore base, senza ombre, luci o righe, soprattutto sulla pelle scoperta: due pezzi di pelle
  sovrapposti devono sembrare una superficie sola. Le ombre stanno lontane dalle giunture.
- **Tre quarti verso destra** sempre: è la vista dello stampino e quella con cui si cammina.
- **Colore della squadra** solo in verde `#00FF00` (ombra `#00B400`), su un solo dettaglio
  scelto per il personaggio (l'apprendista: il fazzoletto). Il verde non si usa per altro.
- **Niente fiammella** nelle teste (la disegna il gioco) e **niente equipaggiamento** nel
  corpo base (vestiti, ali, elmi sono pezzi a parte).
- **Stampino** rifatto ogni volta con `python3 strumenti/stampino/stampino.py`
  (`simulazione/stampino/stampino_ai.png` + `manichino.png`, copiati fra i riferimenti della scheda) solo per
  posizione e misura dei pezzi: il prompt dice di non copiarne le forme.
- **Sfondo**: bianco pieno in fase 1, magenta pieno `#FF00FF` in fase 2.
- **Le 9 espressioni**, sempre le stesse: furbo/normale, colpito, vittoria, stordito (le 4
  dello stampino), mira, arrabbiato, sconfitto, paura, provocazione.

- **Colori giusti alla fine, ovunque** (Sergio: «è troppo importante»): ChatGPT non rispetta
  mai la tavolozza al pixel, quindi nel ricalco ogni area va al codice esatto della tavolozza,
  in ogni pezzo e testa; uno script controlla gli SVG e fallisce se trova un colore fuori
  tavolozza. I PNG del gioco escono solo da quegli SVG.

## Dopo le immagini

Taglio (`strumenti/stampino/taglia.py --allinea`), ricalco in SVG a strati di colore,
PNG alla densità di ogni schermo, editor ripubblicato, simulazione: i dettagli e quello che
manca ancora nel codice sono nella sezione "Dopo le immagini" di WB-009.
