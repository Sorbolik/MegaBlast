# WB-069 · Profilo: le nove icone dei record

- **Stato:** IMPLEMENTATA (17 nov) · APPROVATA (Sergio, 17 nov 9:21: «se servono schede di codex dammele, ad esempio per le icone che ci si aspetta che siano icone nel profilo»)
- **Data:** 2026-11-17
- **Ramo della scheda:** `claude/project-thread-sqn69w` (Codex la esegue da qui: `git fetch origin claude/project-thread-sqn69w`, non serve che sia su `main`) · **Ramo delle immagini:** `design/WB-069`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-069` senza chiedere conferma (il repository è privato).

## Obiettivo

Nella pagina STATISTICHE del Profilo ogni record ha a sinistra un tondo colorato (R1): uno si
aspetta un'icona che dica che record è, e trova un pallino. Servono **nove icone piccole**, una
per record, nello stile del Filo di Brace. Il gioco le mette al posto dei tondi, alte 44 px.

## Come devono essere fatte

- **Si leggono a 40 px:** una sola figura grossa per icona, niente dettagli più sottili della china.
- **Ognuna il suo colore dominante** (quello del tondo di oggi), così si riconoscono anche di sfuggita.
- **Senza disco e senza cornice dietro:** la figura da sola, sul trasparente; stanno su una scheda
  di ferro scuro (#2B2530).
- **Ricalcabili in vettori:** colori pieni (al massimo cinque per icona), china nera chiusa e spessa.
- **Stessa famiglia** dei pezzi piccoli di WB-022 (R2), delle medaglie di WB-067 (R3) e delle icone
  delle armi (R4).

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-069/riferimenti/R1_profilo_statistiche.png` | la pagina com'è oggi: i tondi colorati a sinistra di ogni record sono i posti delle icone |
| R2 | `art/WB-022/pezzo_piccoli.png` | pezzi piccoli di WB-022: grandezza e mano della china |
| R3 | `art/WB-067/medaglie_1.png` | le medaglie che stanno sulla stessa scheda |
| R4 | `client/assets/weapons/grenade_icona.png` | un'icona del gioco: quanto dettaglio regge a 40 px |

## Immagini da generare

Il prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto: il primo è
"image 1", il secondo "image 2" e così via.

| Nome file | Cosa c'è | Riferimenti | Misura | Varianti |
|---|---|---|---|---|
| `icone_record` | le nove icone in una griglia 3 × 3 | R1, R2, R3, R4 | 1536×1536 | 3 |

Le varianti si chiamano `icone_record_1.png` e così via, in `art/WB-069/`. Per ogni foglio Codex
scrive un `.txt` con lo stesso nome: cosa ha fatto e cosa non è riuscito a rispettare.

### `icone_record`

```
Image 1 is the PLAYER STATS screen of our game, a cartoon turn-based artillery game played by little red horned devils: in the middle there are nine record cards, and each card has a plain colored dot on its left. Those dots are placeholders: each one must become a small icon that says what the record is. Images 2 and 3 show pieces of the same game interface and are the STYLE to copy exactly: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow per piece, soft hand-drawn slightly crooked shapes, like a cartoon comic. Image 4 is one of the weapon icons of the game: copy its level of detail, it must read at 40 pixels.
Draw a clean sheet on a fully transparent background with NINE separate small icons in a grid of 3 columns and 3 rows, well spaced, nothing touching, all the same visual size, each one a single bold shape that reads at 40 pixels, no disc and no frame behind them. In reading order:
1) GRAVEDIGGER (enemies knocked into the void): a shovel stuck upright in a small mound of earth; main color light blue #8FDBFF, with ivory #F4E9D8 blade highlight.
2) HUNTER (enemies knocked out): a small horned devil skull with two X eyes; main color red #FF5C5C with ivory horns.
3) AIM (shots on target): a round target with two rings and a bold center dot, one small notch at the top; main color orange-sand #FFB054, center dot dark #2A1208.
4) HAMMER (damage dealt): a short heavy blacksmith hammer tilted as if striking, with one small spark; main color ember #F26419 with a gold #FFB703 band.
5) LIGHTNING (orbs earned): a round orb with a bold lightning bolt inside; main color violet #B08CFF, bolt ivory.
6) FAR (longest shot): a dotted arc going from bottom left to bottom right that ends in a small flag; main color gold #FFC83D.
7) LOOTER (crates opened): a small wooden crate with its lid lifted open; main color wood brown #CC8A54 with darker #8A5428 planks.
8) WINNER (matches won): a simple trophy cup with two handles; main color mint green #5CDDA8 with a lighter band.
9) FALLS (times you fell): a little horned devil tumbling upside down with two short speed lines above his feet; main color warm grey #7D7069 with ivory horns.
At most five flat colors per icon. No letters, no numbers, no background, no shadows on the ground, no glow outside the ink.
```

## Criteri di accettazione

- [ ] sfondo trasparente pulito, contorno nero puro e spesso, nessuna scritta
- [ ] le nove icone si distinguono una dall'altra rimpicciolite a 40 px
- [ ] ognuna ha il suo colore dominante, come scritto
- [ ] stessa grandezza visiva, nessun disco o cornice dietro
- [ ] le icone non si toccano (si ritagliano una per una)

---

## Decisione

Sergio, 17 nov 9:21: approvata con tutte le proposte dell'audit grafico (proposta 8). I soggetti
delle nove icone li ha scelti Claude dai nomi delle medaglie (BECCHINO, CACCIATORE, MIRA, MARTELLO,
FULMINE, LONTANO, PREDONE, VINCITORE, e le cadute).

## Consegna di Codex

- `art/WB-069/icone_record_1.png` e `icone_record_1.txt` · 1 tentativo.
- `art/WB-069/icone_record_2.png` e `icone_record_2.txt` · 2 tentativi.
- `art/WB-069/icone_record_3.png` e `icone_record_3.txt` · 2 tentativi.

Generati con ImageGen integrato, prompt integrale e riferimenti R1–R4 nell'ordine della scheda. I tre PNG hanno alpha e misurano 1536×1536 px. Il generatore ha restituito tele più piccole, centrate su una tela trasparente senza ridimensionare le figure.

Verificati la griglia 3 × 3, l'ordine, le sagome separate, l'assenza di testo e di cornici, i colori dominanti e la leggibilità dei nove soggetti in anteprima a 40 px su #2B2530. Nei primi tentativi dei fogli 2 e 3 il grigio dominava sulla testa del martello. Nei fogli scelti le linee di movimento di Cadute sono poco visibili sul ferro scuro. Nel foglio 3 la tacca di Mira è resa da due intagli. I contorni appaiono neri e spessi a vista. L'antialias e le sfumature locali producono più valori RGB dei cinque colori piatti richiesti. I valori esatti del nero e della palette non sono stati certificati. Ricalco e resa nel gioco da verificare.

## Resoconto di Claude

17 nov. Guardati i tre fogli su ferro scuro (#2B2530). **Usato il foglio 1**: le nove figure sono le
più pulite e della stessa mano (pala, teschio, bersaglio, martello con la fascia oro, globo col
fulmine, arco con la bandierina, cassa, coppa, diavoletto che cade). Scartati il 2 (il manico del
martello ha una punta gialla che sembra un secondo pezzo, il diavoletto delle cadute si legge meno) e
il 3 (martello col manico nero, tacca del bersaglio doppia, cadute poco chiare).

- Tagliate da `tools/grafica/fucina.py` (`fai_record`): a caselle, perché ogni icona ha pezzi staccati;
  ognuna al centro di un quadrato di 96 px (`record_<id>` nell'atlante `fucina`). Delle cadute sono
  tolte le lineette di movimento: nere, sul ferro scuro non si vedevano.
- Nel gioco: `client/menu/profile_tabs.lua`, al posto dei tondi colorati, alte 48 px.
- Verificato: scenario `profilo.txt` nel simulatore, foto `docs/handoff/img/WB-069_profilo_icone.png`;
  controlli di sintassi, dell'editor e dei testi.
- Limiti visti: l'arco del COLPO PIÙ LUNGO è sottile e a 48 px è la meno forte delle nove; il grigio
  delle CADUTE stacca poco dal ferro. Si leggono, ma se Sergio le vuole più decise si rifanno solo quelle due.
- Non verificato: su telefono vero.
