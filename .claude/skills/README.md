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
