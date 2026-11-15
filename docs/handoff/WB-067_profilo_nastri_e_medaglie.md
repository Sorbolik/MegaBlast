# WB-067 · Profilo: nastri delle partite, medaglie dei record, pulsante rivedi

- **Stato:** APPROVATA (Sergio, 15 nov 22:48: «il resto quello che hai consigliato», cioè le due pagine del Profilo proposte da Claude)
- **Data:** 2026-11-15
- **Ramo della scheda:** `claude/project-thread-bpo2v6` (Codex la esegue da qui: `git fetch origin claude/project-thread-bpo2v6`, non serve che sia su `main`) · **Ramo delle immagini:** `design/WB-067`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-067` senza chiedere conferma (il repository è privato).

## Obiettivo

Le pagine del Profilo (R1 statistiche, R2 cronologia) oggi sono scatole scure. Nella proposta
scelta ogni partita ha un **nastro** a sinistra (fiamma per la vittoria, ghiaccio per la
sconfitta, come il Filo di Brace), i record hanno una **medaglia** (bronzo, argento, oro) e
ogni partita un **pulsante rotondo per rivederla**. Il resto (barre, grafico, teste) lo
disegna il gioco.

## Come devono essere fatti

- **Interno piatto e senza scritte:** il gioco scrive VITTORIA, SCONFITTA e i numeri delle
  medaglie sopra.
- **Il nastro si allunga in alto senza deformarsi:** la punta a fiamma (o a scheggia) sta solo
  sul lato destro, il resto è liscio.
- **Ricalcabili in vettori:** colori pieni (al massimo cinque per pezzo), china nera chiusa e
  spessa, nessun dettaglio più sottile della china.
- **Stessa famiglia di WB-022 e del pulsante principale** (R3, R4, R5).

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-067/riferimenti/R1_bozza_profilo_statistiche.png` | la pagina STATISTICHE proposta: record con medaglia |
| R2 | `art/WB-067/riferimenti/R2_bozza_profilo_cronologia.png` | la pagina CRONOLOGIA proposta: nastri e pulsante rivedi |
| R3 | `art/WB-022/pezzo_pannello.png` | il pannello di WB-022: stile della china e del ferro |
| R4 | `art/WB-022/pezzo_piccoli.png` | pezzi piccoli di WB-022: grandezza della china |
| R5 | `art/WB-054/ritagli/primario_gemma_acceso.png` | il pulsante principale: la fiamma e i cristalli da riprendere |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto: il
primo è "image 1", il secondo "image 2" e così via.

| Nome file | Cosa c'è | Riferimenti | Misura | Varianti |
|---|---|---|---|---|
| `nastri_e_rivedi` | nastro vittoria, nastro sconfitta, pulsante rivedi (normale e premuto) | R2, R3, R4, R5 | 1536×1024 | 3 |
| `medaglie` | medaglia bronzo, argento, oro, e la stessa vuota (record non ancora preso) | R1, R3, R4 | 1024×1024 | 2 |

Le varianti si chiamano `nastri_e_rivedi_1.png` e così via, in `art/WB-067/`. Per ogni foglio
Codex scrive un `.txt` con lo stesso nome: cosa ha fatto e cosa non è riuscito a rispettare.

### `nastri_e_rivedi`

```
Image 1 is a mock-up of the MATCH HISTORY screen of our game: every match is a dark card with a result ribbon on the left (orange with a flame-shaped tip for a WIN, light blue with an ice-shard tip for a LOSS) and a round orange play button on the right to watch the replay. These are hand-made placeholders to redraw well. Images 2 and 3 show pieces of the same game interface and are the STYLE to copy exactly: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow per piece, soft hand-drawn slightly crooked shapes, like a cartoon comic. Image 4 is the main button of the game: copy the way its flame and its ice crystals are drawn. Ember is #F26419 with a lighter band #FFB703 and a darker band #B8440F, ice is #38B6FF with highlight #CAF0F8 and a deeper band #1E7FC2, dark text color is #2A1208.
Draw a clean sheet on a fully transparent background with separate pieces, well spaced, nothing touching:
1) the WIN ribbon: a wide horizontal banner (about 2 to 1), straight left side, the right side ends in a short licking flame shape; ember colors with one lighter band along the top; large flat empty center for a word.
2) the LOSS ribbon: same size and same left side, the right side ends in two or three sharp ice shards; ice colors; large flat empty center for a word.
3) a round REPLAY button: ember gradient disc with a thick ink outline and a dark #2A1208 play triangle in the middle, small flat highlight on top.
4) the same replay button pressed: slightly darker, highlight gone, a few pixels lower.
No letters, no numbers, no background, no shadows on the ground, no glow outside the ink.
```

### `medaglie`

```
Image 1 is a mock-up of the PLAYER STATS screen of our game: each record card has a small round medal in its top right corner, with a roman numeral written by the game on top. Images 2 and 3 show pieces of the same game interface and are the STYLE to copy exactly: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow per piece, soft hand-drawn slightly crooked shapes, like a cartoon comic.
Draw a clean sheet on a fully transparent background with four separate small medals, well spaced, nothing touching, each readable at 32 pixels: a BRONZE medal (#D08A4A with lighter #F0B07A and darker #8A5428), a SILVER medal (#C9C6D2 with lighter #F0EEF5 and darker #8A8696), a GOLD medal (#FFC83D with lighter #FFE59A and darker #C9901A), and an EMPTY medal slot (dashed ivory outline on dark iron #2B2530, for a record not reached yet). Each medal is a slightly crooked round coin with a thick ink outline, a flat empty center for a roman numeral, and a tiny ember spark notch on its rim. No letters, no numbers, no ribbons, no background, no glow outside the ink.
```

## Criteri di accettazione

- [ ] sfondo trasparente pulito, contorno nero puro e spesso, nessuna scritta
- [ ] vittoria e sconfitta si distinguono anche senza colore (fiamma contro scheggia)
- [ ] il centro dei nastri e delle medaglie è piatto e vuoto
- [ ] le medaglie si leggono a 32 px
- [ ] i pezzi non si toccano (si ritagliano uno per uno)

---

## Decisione

Sergio, 15 nov 22:48: le pagine del Profilo come proposte da Claude.

## Consegna di Codex

## Resoconto di Claude
