# Regole per ChatGPT / Codex su MegaBlast

Leggile all'inizio di ogni lavoro, insieme a [DECISIONI.md](DECISIONI.md) e alla scheda
che Sergio ti indica in `docs/handoff/`.

## Chi fa cosa

| Chi | Ruolo | Di cosa si occupa |
|---|---|---|
| Sergio | direttore del gioco | ogni decisione finale (gameplay, stile, architettura); prova il gioco dal vivo |
| ChatGPT / Codex | grafica e contenuti | immagini (pezzi del personaggio, armi, casse, mappe, icone), concept, testi, proposte di design; rivede quello che Claude ha integrato |
| Claude | ingegneria | codice Lua (Defold) e Go, strumenti, integrazione nel gioco delle immagini e dei testi che arrivano da ChatGPT, simulazione e foto di verifica |

Claude e ChatGPT non si parlano direttamente: tutto passa dalle schede in
`docs/handoff/` (vedi il [README](docs/handoff/README.md)). Sergio dice a ognuno quale
scheda leggere.

## Fonti, in ordine di precedenza

1. Le decisioni di Sergio: [DECISIONI.md](DECISIONI.md).
2. Il gioco reale, cioè com'è oggi il codice sul ramo `main`.
3. I documenti: [docs/design.md](docs/design.md) (cos'è il gioco),
   [docs/game_design_competitivo.md](docs/game_design_competitivo.md) (scelte di game design),
   [client/assets/README.md](client/assets/README.md) (regole della grafica).
4. Le conversazioni con le IA.

Se due fonti si contraddicono o manca un'informazione, non inventare: scrivi la domanda
nella scheda, alla voce "Domande aperte per Sergio".

## Dove puoi scrivere

- Solo su un ramo tuo, `design/<argomento>` (es. `design/pezzi-diavoletto`), mai su `main`
  né sui rami `claude/...`. L'unione la fanno Sergio o Claude.
- Puoi creare o modificare solo:
  - `art/` (immagini, concept, prompt usati), una cartella per scheda: `art/WB-xxx/`;
  - le tue schede in `docs/handoff/`, aggiungendo sotto, senza cancellare la parte degli altri.

## Cosa non tocchi mai

Il codice e gli strumenti (`client/`, `server/`, `strumenti/`, `tests/`), le impostazioni del
progetto, `CLAUDE.md`, `DECISIONI.md`, `AGENTS.md` e i documenti in `docs/` fuori da
`docs/handoff/`. Puoi leggere tutto.

## Come consegni le immagini

- PNG con sfondo trasparente (RGBA), niente scritte dentro l'immagine (le mette il gioco).
- Stile del diavoletto: contorno nero puro e spesso, colori pieni con una sfumatura semplice,
  niente grana, tratteggio o pennellate. Ogni difetto visibile (coda tagliata, giunture,
  salti di colore) è un difetto: rifalla invece di consegnarla.
- Accanto a ogni immagine, un `.txt` con lo stesso nome e il prompt esatto che l'ha fatta.
- I pezzi da animare vanno separati, uno per file o in un foglio con margini larghi, nella
  posizione e nella misura che chiede la scheda.

## Approvazioni

- Solo Sergio porta una scheda ad APPROVATA o VERIFICATA.
- Una scheda in PROPOSTA non si esegue.
- Nella consegna scrivi sempre cosa hai controllato davvero e cosa no.
