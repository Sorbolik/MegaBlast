# Arsenale: armi, casse, oggetti

Valori correnti in `client/sim/config.lua`; descrizioni in
[../design.md](../design.md). Pagina della proposta dell'arsenale (24 ott):
https://claude.ai/artifact/W8SfXvxVNLSZDAx4Wc8QXJ

## Decisioni prese

| Data | Decisione | Dove |
|---|---|---|
| 20 ott | "Ogni 3 turni una cassa con una delle altre armi" (Sergio). Armi delle casse: Uovo di Fiamma (granata, miccia 3 s), Sciame di Schegge (8 schegge), Pugno del Titano (montante). Cassa: dal turno 4, punto a caso, max 3, contenuto nascosto, 1 colpo. Valori (Claude). | PR #19 |
| 23 ott | Ogni arma trovata = 1 colpo, ritrovarla accumula; missile e spada infiniti. Le casse portano anche trappole, scudi, trampolini. | game_design_competitivo.md, PR #31 |
| 24 ott | **Primarie** (agiscono sul mondo, con effetto: Lanciarune base, Uovo, Schegge, Pugno, Cecchino) e **secondarie** (danno secco, illimitate, ognuna ti sposta: Lama base + una scelta nel draft tra Tonante, Maglio, Affondo). Una per categoria a turno. Categorie con colori diversi (brace / acciaio). Vicino/lontano non conta. | PR #36, #38 |
| 24 ott | Secondarie scelte nel draft, non nel kit base; Tonante = Desert Eagle con rinculo; il rampino ha lasciato il posto al Maglio tra le secondarie. Colpi del draft 2. | PR #38 |
| 24 ott | **Rampino**: oggetto sempre nella barra, non un attacco, colpo dritto 220 px. Su un robot lo tira verso la mano; sul terreno il tiratore sale sulla piattaforma colpita (entro 64 px dalla cima). Una volta per turno (dal 24 ott sera). | PR #38, #39 |
| 24 ott | Cecchino: "non scende per niente" → parte veloce (480) e frena, gravità che cresce in 0,8 s, rimbalza come una palla (max 6), si schiaccia a ogni rimbalzo. | PR #37, #38 |
| 24 ott | Granata con hitbox che rimbalza sui robot come il globo. Trampolino si lancia come l'Uovo. | PR #36 |
| 26 ott | Rampino su nemico a terra: scivola lungo il terreno invece di fermarsi; tiro intero fino al tiratore (220, "ce lo dobbiamo tirare per bene"). | PR #48 |
| 26 ott | **Maglio** ruota attorno alla spalla come la Lama (115° → −100°, portata 44); regola del rimbalzo (Claude): fendente iniziato in aria + testa che colpisce scendendo = pogo 320 px/s una volta. **Affondo** scala gradini fino a 16 px, scivola sul terreno, colpisce col corpo o la punta (portata 40), 18 tick. Codice condiviso `game:sweep_arc`. | PR #50 |
| 26 ott | **Tonante** portata 600 (raddoppiata), rinculo uniforme in ogni direzione: 300 px/s × 22 tick = 110 px senza gravità, scivola sul terreno; sollevamento tolto. | PR #47 |
| 26 ott | Skin delle armi **vettoriali** disegnate da script (`strumenti/grafica/armi.py`, SVG → PNG, contorno nero spesso): le 11 armi in mano, icone, proiettili (disegnati 1,6×). Affondo = forcone del diavolo. | PR #51 |
| 26 ott | Cassa = baule aperto con i denti di Gabriella (bozza, PR #49). | PR #49 |
| 29 ott | **Attrezzo del turno**: accanto al Rampino entra il **Bastione** (posa un blocco di terreno vero, 48×12 px, entro 160 px; max 2 a testa, il terzo fa crollare il più vecchio). L'attrezzo si **sceglie nel draft** in un terzo ventaglio, preselezionato dall'assetto; compagni diversi, doppioni ammessi nel tutti contro tutti. Fatto in #60; scelte di Claude: in piedi se si mira oltre 45°, distanza = potenza × 160; le celle addosso a un robot restano vuote; crollando tornano vuote solo le sue celle ancora piene; il blocco si vede come le piattaforme (conci di pietra, cima d'ottone, `terreno.fp`); l'attrezzo dell'assetto è solo "proposto": se un compagno sceglie lo stesso, chi lo aveva proposto passa all'altro; nell'armeria si sceglie in fondo alla scheda SET. | #60 |
| 29 ott | **Ritocchi dall'arena dei bot** (Sergio: "ok applicali"): Affondo 30 → 27, Pugno 50 → 28, Maglio 30 → 34, Uovo 27,5 → 57 al centro, Cecchino 25 → 30, Schegge 7 → 6,5, Tonante 25 → 23. Nel tutti contro tutti le armi passano da 19–30% a 22–28% di vittorie, con i punti di oggi e con la variante A. **Fornace**: brucia solo con l'Uovo (col set completo vinceva il 69% nell'1v1, ora 52%). Proposte: https://claude.ai/artifact/BwaY8mNMU9ZRkgNEWCCu4v | PR del bot |

## Scartate

- Casse ogni 2 turni (24 ott, Sergio).
- Attrezzi Scambio, Onda (anche perché doppione della Campana di bronzo proposta dal bot), Àncora e Scatto (29 ott, Sergio ha scelto solo il Bastione). Àncora: spegne le uccisioni ambientali; Scatto: è solo altro movimento.
- Attrezzo uguale per tutti, equipaggiato solo nell'assetto, o legato al set (29 ott).
- Rampino come secondaria del draft: sostituito dal Maglio (24 ott).
- Cecchino a 1400 px/s dritto (24 ott): "non scende per niente".
- Skill-check sul Cecchino: rinviato.
- Immagini AI per le armi (ChatGPT, Ludo): stile incoerente e crediti scarsi;
  vecchie armi delle Scorie: stile sbagliato; pixel art; forme di codice
  ricolorate (26 ott, PR #51).
- Rinculo del Tonante solo verso il basso: era un effetto collaterale del
  profilo fisico (clamp della velocità orizzontale).

## Aperte

- Pesi degli oggetti tattici nelle casse (vedi gameplay.md).
- Cassa di Gabriella (PR #49) da mergiare o no.
