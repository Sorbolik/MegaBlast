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
| 2 | Foglio del corpo sullo stampino + 9 teste senza collo + braccia col pugno chiuso, copiati dai file scelti | ChatGPT |
| 3 | Ricalco in SVG coi colori esatti, taglio, un SVG per pezzo, PNG per ogni schermo, editor | Claude |
| 4 | Prova animata nell'editor delle animazioni (pezzi in SVG, zoom, specchio, ogni disegno in qualsiasi posto) | Sergio valida |

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

## I prompt da cui si parte sempre

Ogni personaggio nuovo parte **dal set di prompt di WB-009** (Sergio, 2026-11-02), con le
correzioni qui sotto già dentro: si copia la scheda, si cambiano solo descrizione, tavolozza
e dettaglio della squadra. Ogni ritocco che si fa a un personaggio si riporta qui e nel set.

Fase 1: `1_tre_quarti`, `2_camminata` (solo prova: non serve allo scheletro, si può
saltare), `3_espressioni`; nel tre quarti entrambi i piedi girati a destra (come
`6_tre_quarti`). Fase 2: il foglio del corpo come `8_corpo_fedele` (non come
`4_foglio_pezzi`), le nove teste come `7_teste`, le braccia col pugno come `9_braccia_chiuse`.

Lezioni di WB-009, da tenere nei prompt:

- **Copiare forma per forma** dal tre quarti scelto: busto, gambe, braccia e coda con le
  stesse proporzioni e la stessa curva. Senza questa frase ChatGPT ingrassa il busto, gli
  mette le spalline, ingrossa le gambe e cambia la coda.
- **Busto senza spalline**: alle spalle il busto finisce tondo, di pelle piena, senza
  contorno e senza righe nere fra spalla e pancia (lì si attaccano le braccia).
- **Teste senza collo, contorno chiuso** (Sergio, 2026-11-02): tutte e nove in un foglio
  3×3, disegnate come se fossero ritagliate dal tre quarti lungo il contorno della testa,
  col nero chiuso anche sotto il mento e la mascella. Il collo è del busto. Tagliare il collo
  dopo, con lo script, lasciava resti neri e un bordo aperto.
- **Tutti e due i piedi verso destra** nel tre quarti (Sergio, 2026-11-02): la gamba davanti
  dello stampino è già messa per guardare a destra; con un piede girato a sinistra non torna.
- **Braccia col pugno chiuso** (davanti e dietro), oltre a quelle con la mano aperta: servono
  alle impugnature delle armi.
- **Tutte le nove facce** sempre, nello stesso foglio e nello stesso ordine delle espressioni.
- Il **controllo dei colori** si fa sull'SVG, non sull'immagine di ChatGPT: i colori di
  ChatGPT non sono mai esatti.

## Dopo le immagini

1. `vettoriale.py --tavolozza strumenti/stampino/tavolozze/<nome>.json FOGLIO.png FOGLIO.svg
   FOGLIO_col.png [RITOCCHI.json]`: ricalco a strati coi soli colori della tavolozza (si
   ferma se ne trova un altro). I ritocchi a mano (JSON accanto all'SVG, poligoni con il colore
   da cambiare) correggono gli errori di ChatGPT, per esempio il nero sulle spalle.
2. `taglia.py FOGLIO_col.png --nome <nome> --categoria personaggio --allinea --senza ala
   --teste TESTE_col.png --tavolozza strumenti/stampino/tavolozze/<nome>.json`: i pezzi del
   gioco e un SVG per pezzo, anche ogni segmento della coda (`strumenti/stampino/pelli/svg/`);
   le nove teste (foglio 3×3 senza collo) prendono il posto di quelle del foglio.
3. `prepara.py` e l'editor ripubblicato: la cassetta dei pezzi in SVG del personaggio.
   Nell'editor ogni pezzo ha il suo perno (corpo, testa, braccia, manine, gambe, ala, coda,
   arma). Le scelte di Sergio (disegno per posto, specchio, spostamenti) tornano con "Manda a
   Claude" e si applicano con `taglia.py --ritocchi`.

4. Simulazione con `imposta prova_pelli <nome>` (come `strumenti/simula/scenari/apprendista.txt`).

Ancora da fare nel codice: i PNG alla densità di ogni schermo fatti dagli SVG.
