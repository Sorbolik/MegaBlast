# Skill del progetto

Skill di progetto per Claude Code: partono da sole quando servono, oppure si
chiamano per nome (`/progetta-meccanica`, ecc.).

| Skill | Cosa fa |
|---|---|
| [progetta-meccanica](progetta-meccanica/SKILL.md) | Da un'idea grezza a una scheda di design pronta da implementare. |
| [valuta-meccanica](valuta-meccanica/SKILL.md) | Cinque filtri (chiarezza, motivazione, risposta, soddisfazione, coerenza) e un verdetto. |
| [dottore-del-design](dottore-del-design/SKILL.md) | Bilanciamento, strategie che rompono il gioco e note di playtest, con correzioni in ordine di priorità. |
| [sviluppa-meccanica](sviluppa-meccanica/SKILL.md) | Dalla scheda al codice: simulazione Lua, test, server Go, client Defold, simulazione con le foto. |

Sono solo testo, senza script né hook. Sono scritte per MegaBlast prendendo
spunto da alcune skill di [Claude Code Game Studios](https://github.com/Donchitos/Claude-Code-Game-Studios)
(licenza MIT, © 2026 Donchitos): brainstorm, quick-design, design-review,
balance-check e playtest-report.

## Skill Defold

Skill in inglese prese da [defold-agent-config](https://github.com/indiesoftby/defold-agent-config)
(aglitchman / indiesoftby, licenza CC0, commit `da5bd18`). Aiutano a non sbagliare i
file di Defold che l'editor rifiuta anche quando `bob.jar` li accetta.

| Skill | Cosa fa |
|---|---|
| [defold-proto-file-editing](defold-proto-file-editing/SKILL.md) | Regole e campi dei file in Protobuf Text Format (`.collection`, `.go`, `.gui`, `.atlas`, `.material`, `.mesh`, ...). |
| [defold-scripts-editing](defold-scripts-editing/SKILL.md) | Struttura di `.script`, `.gui_script`, `.render_script` e moduli `.lua`. |
| [defold-shaders-editing](defold-shaders-editing/SKILL.md) | Shader `.vp`/`.fp` con `#version 140` e legame con i materiali. |
| [defold-api-fetch](defold-api-fetch/SKILL.md) | Link alla documentazione delle API in Markdown (`defold.com/llms/apis/`). |
| [defold-docs-fetch](defold-docs-fetch/SKILL.md) | Link ai manuali in Markdown (`defold.com/llms/manuals/`). |

Tolti rispetto all'originale: gli script Python per le forme di collisione Box2D
(MegaBlast usa il suo terreno a bitmap), e le skill per dipendenze, build
dall'editor, Monarch, xmath, estensioni native e manutenzione delle skill.
Nelle sessioni cloud `curl` verso defold.com è bloccato: apri i link con WebFetch.

## Skill gamedev generali

Skill in inglese prese da [awesome-gamedev-agent-skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills)
(licenza Apache-2.0, testo e NOTICE in [licenze/](licenze/)), installate il 9 nov con
`npx skills add gamedev-skills/awesome-gamedev-agent-skills -a claude-code --copy`
(`skills-lock.json` alla radice: `npx skills update -p` le aggiorna). Sono tecniche
generali: gli esempi sono in GDScript, C# o GLSL, vanno tradotti in Lua e Defold. Se
una skill dice una cosa diversa da `CLAUDE.md` o da `docs/`, vincono le regole del
progetto (per esempio: la verifica è `tutti.sh` e `simula.py`, non il build di prova
di `defold-core`; i livelli si scrivono nel Copione).

| Skill | Serve per |
|---|---|
| [performance-optimization](performance-optimization/SKILL.md) | Misurare prima di ottimizzare, budget del frame, CPU contro GPU, draw call, allocazioni per frame, pool. |
| [shader-programming](shader-programming/SKILL.md) | Basi di vertex e fragment shader, UV, effetti 2D (tinta, scorrimento, dissolvenza, contorno). |
| [defold-core](defold-core/SKILL.md) | Struttura di un progetto Defold, messaggi, factory, proxy; `scripts/check_defold_project.py` controlla i riferimenti ai file (solo lettura). |
| [game-feel](game-feel/SKILL.md) | Scossa della camera, hit-stop, easing, squash & stretch, feedback a strati. |
| [camera-systems](camera-systems/SKILL.md) | Camera che segue, zona morta, anticipo, limiti della mappa, inquadrare più bersagli. |
| [input-systems](input-systems/SKILL.md) | Azioni invece di tasti, rimappatura, zone morte delle levette, controller e tocco. |
| [physics-tuning](physics-tuning/SKILL.md) | Passo fisso e interpolazione, proiettili che attraversano i muri, tremolii. |
| [game-ui-ux](game-ui-ux/SKILL.md) | HUD e menu su ogni schermo, ancore, zone sicure, navigazione col controller. |
| [level-design](level-design/SKILL.md) | Misure del giocatore, ritmo tensione e pausa, percorso critico dei livelli. |
| [audio-design](audio-design/SKILL.md) | Bus e volumi in decibel, musica che si abbassa sotto le voci, varianti dei suoni. |
| [prototype-fast](prototype-fast/SKILL.md) | Provare una meccanica nuova in un'ora con una sola domanda e criteri scritti per tenerla o buttarla. Da noi la prova si fa con uno scenario di `tools/simula/scenari/` su un ramo a parte, non in una cartella `prototypes/`. |

Tolte (66 skill e il router): tutte quelle per Godot, Unity, Unreal, Roblox, Bevy,
Phaser, PixiJS, three.js, pygame, LÖVE ed Ebitengine (non usiamo quei motori); il
router (sceglie fra motori e skill che non abbiamo, le skill partono già dalla loro
descrizione); i generi (platform, roguelike, RPG, carte, ecc.: MegaBlast è un gioco
di artiglieria a turni, il design sta in `docs/game_design_competitivo.md`);
`create-game-assets` (le immagini le fa Codex dalle schede in `docs/handoff/`, e ha
script Python con dipendenze); `procedural-gen` (mappe disegnate a mano);
`game-ai` e `ai-behavior-trees-utility-ai` (il bot pensa provando le mosse sulla
simulazione); `dialogue-systems` (le righe stanno nel Copione); `save-systems`;
i flussi per game jam, itch e Steam. Tolto anche il file per Codex
`defold-core/agents/openai.yaml`.

Controllo di sicurezza: solo testo, nessun hook; l'unico script
(`defold-core/scripts/check_defold_project.py`) usa solo la libreria standard di
Python, legge i file del progetto e non scrive, non lancia comandi e non va in rete.
