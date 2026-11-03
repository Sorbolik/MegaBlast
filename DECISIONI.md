# Decisioni prese

Una riga per decisione, con data e motivo. Le scrivono Sergio o Claude (il coordinatore);
Codex mai. Quelle prese da Claude in autonomia hanno "(Claude)" e Sergio può ribaltarle.
Le più recenti in fondo.

- 2026-10-19 · Gioco per telefono sul modello di un gioco di artiglieria del 2013 (il gioco di riferimento): a turni, multigiocatore dal vivo, 2-4 giocatori (1v1, 2v2, tutti contro tutti) con podio finale.
- 2026-10-19 · Client Defold (Lua), server Go autoritativo, terreno distruttibile a celle: il più leggero e veloce da caricare.
- 2026-10-19 · Fluido su ogni telefono, anche economico, a ogni frequenza dello schermo (60-120 Hz): scatti non accettati.
- 2026-10-19 · Salto libero con controllo in aria, niente vento, mappe fatte a mano.
- 2026-10-20 · Il gioco si chiama MegaBlast.
- 2026-10-23 · Nel codice resta solo ciò che serve: i sistemi superati si tolgono prima di unire.
- 2026-10-24 · Il Nucleo come risorsa è tolto: non pesava sulle scelte.
- 2026-10-26 · Il personaggio è il diavoletto: occhiali con gli occhi, fiammella sopra la testa col colore della squadra e più grande nel proprio turno, coda a segmenti, contorno nero puro e spesso, la testa gira con la mira.
- 2026-10-26 · Mappe ingrandite 1,5 volte: mondo 1920×1080.
- 2026-10-26 · Il diavoletto è fatto a pezzi animati nel codice, non a fogli di fotogrammi (pesanti, deriva delle IA, nessuna reazione ai colpi).
- 2026-10-26 · I difetti visivi che si vedono (coda tagliata, giunture, salti di colore) non si accettano mai: si correggono o si rigenera.
- 2026-10-28 · Le immagini le genera Codex (ChatGPT) dalle schede in `docs/handoff/` scritte da Claude, che resta il coordinatore: niente copia e incolla di prompt, consegna con commit sul ramo `design/WB-xxx` (regole in `AGENTS.md`).
- 2026-11-01 · Prove del personaggio nuovo di Sergio (espressioni e versione femminile) nella scheda WB-002, su sfondo bianco perché sono solo prove (Claude).
- 2026-11-01 · Personaggi nuovi di Sergio (maschio, femmina, Favilla): corpo 30% più piccolo rispetto ai disegni originali, testa uguale. Disegni ufficiali in `art/personaggi/`.
- 2026-11-01 · Maschio, femmina e Favilla si animano come il diavoletto: pezzi disegnati sullo stampino del gioco (scheda WB-006), con le quattro teste felice, colpita, vittoria e stordita; ala e coda vuote. Il foglio a pezzi liberi (P-007) è scartato (Claude, su richiesta del thread delle animazioni dopo la bocciatura di Sergio).
- 2026-11-01 · I fogli a pezzi liberi di maschio, femmina e Favilla (due versioni ciascuno, mandati da Sergio) entrano come sei pelli nuove `maschio_1`, `maschio_2`, `femmina_1`, `femmina_2`, `favilla_1`, `favilla_2`, rimontate sullo stampino con `pezzi_liberi.py`; senza ala e coda. Gabriella resta il personaggio di tutti nel gioco (Claude).
- 2026-11-01 · Dei sei set a tre quarti c'è anche la versione vettoriale (`_vett`), ricalcata con potrace: Sergio vuole provarli tutte e due (Sergio).
- 2026-11-01 · Protagonista: l'apprendista (A di WB-008), col colore della squadra sul fazzoletto; poi Favilla B (fiamma bianca). Si generano con la procedura di `docs/handoff/PERSONAGGI.md`, un personaggio alla volta, validato da Sergio nell'editor delle animazioni (Sergio).
- 2026-11-03 · Freccia di ferro di chi è di turno (WB-010): dal foglio di ChatGPT un solo fotogramma diviso in tre strati (ferro, brace tinta col colore della squadra, cuore), così vale per tutte e quattro le squadre; il dondolio e la pulsazione li fa il codice; larga 28 unità della targa; segue il sobbalzo della targa come il nome (Claude).
