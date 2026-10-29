# Grafica: direzione, mappe, asset, pipeline immagini

Il personaggio ha il suo file: [personaggio.md](personaggio.md). La UI:
[interfaccia.md](interfaccia.md).

## Decisioni prese

| Data | Decisione | Dove |
|---|---|---|
| 19–20 ott | Direzione artistica: proposte A "Orsetti gommosi", B rottami, C giocattoli a molla; Sergio voleva qualcosa di più serio e iconico → aggiunta e **scelta D "Le Scorie"** (carbone, cuori emissivi color squadra, 4 set Corvo/Fornace/Leviatano/Vuoto). Bibbia: https://claude.ai/code/artifact/3add0f2b-7fcb-44ee-8cdb-b1726fa3ccc4. I personaggi Scorie sono poi stati sostituiti dai diavoletti; i nomi dei set restano. | memoria |
| 20 ott | Analisi dell'APK di Blastron (Unity 4, SmoothMoves): leggibilità da regole (terreno scuro e saturo con contorno, sfondo chiaro e sfocato, poco dettaglio). Gli asset di Kabam restano in /mnt/project-files, mai nel repo. Doc accettato da Sergio. | memoria |
| 20 ott | Tentativo di "look Blastron" (sfondo cotto, contorno del terreno, alone squadra, HUD Cinzel) **bocciato** ("sembra di qualità più bassa") e ripristinato. | PR #23 |
| 21 ott | **Mappe**: quello che si vede è esattamente quello su cui si cammina; bordi angolari (0/45/90°), travi e tubi indistruttibili piatti. Processo: Claude disegna la collisione come poligoni, Sergio genera i materiali con ChatGPT (pietra, crosta, travi, cratere, sfondo), Claude assembla. Mappa 2 **Forgia dei Titani** = default. Misure (robot 20 px): gradino ≤ 22, buco ≤ 28, tunnel ≥ 40, spessore ≥ 20, travi 12. | PR #23, memoria `mappe` |
| 24 ott | Guida alla creazione degli asset (formati PNG 32 bit, master 2×, atlas ≤ 2048, prompt STILE+SOGGETTO+FORMATO con sfondo magenta, mai "trasparente"). | https://claude.ai/artifact/X7kRLmiKwmCYebhNmV6pz3 |
| 26 ott | Scala: mondo ×1,5 (1920×1080, `CELL` 3), maschere restano 640×360. | PR #44 |
| 26 ott | Mappa 3 **Il Crogiolo** (plateau laterali con grotta, ponti d'acciaio, conca a 45°, tunnel, mestoli) e **mappa casuale a partita dal seed** tra Forgia e Crogiolo; mappa "isole" rimossa. Dal basso in alto solo col teletrasporto (Claude). | PR #52 |
| 26 ott | Texture compresse (profilo "Compressa", Basis UASTC) per gli atlas grandi; `--texture-compression true` nelle build. | PR #44 |
| 26 ott | Armi, icone, proiettili vettoriali (vedi arsenale.md); cassa = baule di Gabriella (PR #49, bozza). | PR #51 |
| 28 ott | **Immagini con ChatGPT via Codex**: schede `docs/handoff/WB-xxx` (stati PROPOSTA → APPROVATA → GENERATA → IMPLEMENTATA → VERIFICATA), Codex genera e committa su `design/WB-xxx`; i pezzi del personaggio si disegnano sullo stampino. WB-001 (pezzi del diavoletto di Gabriella) consegnata e montata. | PR #56, docs/handoff/README.md |
| 29 ott | Obiettivo 6 mappe alla pubblicazione; armi nuove solo come modificatori di evento; skin = pezzi sullo stampino con una ricetta ripetibile. | docs/roadmap.md |

## Scartate

- Direzioni A, B, C (20 ott): Sergio voleva "mostriciattoli mai visti".
- SVG a runtime per la leggibilità: non è la risposta (20 ott).
- Kit UI dipinto v1/v2, icone, loghi, sfondi dipinti: ritirati il 23 ott
  (vedi interfaccia.md).
- Mappa "isole del cimitero": solo un test, rimossa (26 ott).
- Scale sulla mappa Crogiolo dal basso in alto: si scontravano col ponte;
  merli: cuciture visibili (Claude, 26 ott).
- Editor di mappe nel gioco, generazione procedurale come contenuto (29 ott).
- API di OpenAI per generare immagini (28 ott).
- Scenario.gg Pro (45 $/mese) prima che lo stile sia fisso (25 ott).

## Aperte

- Cassa di Gabriella (PR #49): mergiare?
- Maglietta rossa o color squadra per la skin di Gabriella (WB-001).
- Mappe 4–6: chi le disegna e con quale pipeline (Crogiolo = script Python +
  materiali Forgia).
