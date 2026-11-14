# WB-050 · La pedana del diavoletto al centro della home

- **Stato:** APPROVATA (Sergio, 14 nov 23:22: «una pedana per il proprio personaggio ci stava, fammi delle proposte con codex, devono starci veramente bene lì al centro della schermata principale, poi se è il caso ci mettiamo pure lo zainetto lì poggiato»)
- **Data:** 2026-11-14
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-050`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-050` senza chiedere conferma (il repository è privato).

## Obiettivo

Al centro della home il diavoletto del giocatore sta in piedi sul filo. Serve una **pedana** su cui
sta, che lo metta in mostra come il pezzo più importante della schermata e stia bene con lo
sfondo della Forgia e con i pulsanti nuovi (R1). Toccando il diavoletto (o la pedana) si apre lo
ZAINO. Sul lato destro della pedana deve restare un piccolo ripiano libero dove poi si può
appoggiare lo zainetto di WB-048.

## Come deve essere fatta

- Vista un po' dall'alto: il piano di sopra è un ovale schiacciato, largo circa una volta e mezza
  il diavoletto, e la pedana è bassa (lo spessore è circa un quarto della larghezza).
- Il piano di sopra è **liscio e vuoto**: lì stanno i piedi del diavoletto.
- Stile dei pulsanti nuovi (WB-046) e del diavoletto: china spessa, colori pieni, una luce e
  un'ombra piatte, forme morbide un po' storte. Ricalcabile in vettori (al massimo sei colori,
  niente più sottile della china), così Claude la ricalca in SVG e la esporta a ogni misura.
- Più calma del diavoletto e del GIOCA: non deve rubargli la scena.
- Niente ombra a terra, niente bagliori.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-050/riferimenti/R1_home_nuova.png` | la home con i pulsanti nuovi: il diavoletto al centro, dove va la pedana |
| R2 | `art/WB-050/riferimenti/R2_apprendista.png` | il diavoletto: la pedana deve stare bene sotto di lui |
| R3 | `art/WB-046/ritagli/porta_campagna.png` | un pulsante nuovo: lo stile |
| R4 | `art/WB-022/pezzo_piccoli.png` | pezzi piccoli di WB-022: la china |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto.

| Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|
| `pedane` | R1, R2, R3, R4 | 1536×1024 | 2 |

Le varianti si chiamano `pedane_1.png`, `pedane_2.png`, in `art/WB-050/`. Per ogni foglio Codex
scrive un `.txt` con lo stesso nome.

### `pedane`

```
Image 1 is the home screen of our game: the little red devil apprentice stands in the middle of a hellish forge, with menu buttons on both sides. Image 2 is the devil alone. Images 3 and 4 show pieces of the same game and are the STYLE to copy exactly: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, soft hand-drawn slightly crooked shapes, like a cartoon comic.

Draw FOUR different proposals for a low round PEDESTAL the devil stands on in the middle of that screen, in two rows of two, well separated. Each pedestal is seen a little from above: its top is a flattened oval, about one and a half times as wide as the devil, and it is low, its thickness about a quarter of its width. The top surface is plain, even and empty, because the devil stands there. On its right side each pedestal has a small flat ledge, a little lower than the top, where a small backpack can rest later; leave it empty.
1. FORGE STONE: a slab of dark basalt (#3A2A2A, highlight #5A4444) with a band of forged iron (#2B2530, highlight #6B6375) around its side held by rivets, and thin ember cracks (#F26419, #FFB703) only along the bottom edge;
2. COOLED LAVA: a rounded disc of cooled black lava rock (#2E2428, highlight #4A3D42) whose rim is a ring of flat ember stripes (#F26419, #FFB703), like lava that has just set;
3. ANVIL BASE: a wide round block of dark iron (#2B2530, highlight #6B6375) with a gold rim on top (#FFB703, darker #F26419) and four chunky feet, like the base of a big anvil;
4. FORGE GRATE: a round iron forge cover (#2B2530) with a thick gold rim (#FFB703) and a ring of small rivets, standing on a short stack of dark stones (#3A2A2A).
All four are calmer than the devil: dark, with only small warm accents, so the devil stays the star.

Thick black ink outline, cartoon comic style like images 3 and 4. Flat colors only, at most six per pedestal, no detail thinner than the outline, so the pedestals can be traced into vectors. No texture, no soft gradients, no glow, no drop shadow on the ground. No text, letters or numbers. Do not draw the devil. Flat pure green background (#00FF00). The pedestals do not touch each other and are not cut by the border of the picture.
```

## Criteri di accettazione

- [ ] piano liscio e vuoto, un po' dall'alto, largo circa una volta e mezza il diavoletto
- [ ] ripiano libero sul lato destro per lo zainetto
- [ ] più calma del diavoletto, sta bene con lo sfondo della Forgia e i pulsanti nuovi
- [ ] colori pieni, china spessa, si ricalca in vettori
- [ ] sfondo verde pieno, niente scritte, niente diavoletto

## Dopo le immagini (lo fa Claude)

- Ritaglia le pedane, le monta sotto il diavoletto sulla home del Figma (una copia per pedana,
  con lo zainetto di WB-048 appoggiato se è arrivato) e le mostra a Sergio, che sceglie.
- Poi ricalco in SVG; nel gioco toccando il diavoletto o la pedana si apre lo ZAINO.

## Decisione

Reversibile (solo immagini in un ramo): approvata su richiesta di Sergio. La pedana la sceglie Sergio.

## Consegna di Codex

Due fogli ImageGen a 1536 × 1024, con quattro proposte ciascuno. I TXT omonimi riportano il prompt integrale e i riferimenti nell'ordine R1–R4.

| File in art/WB-050/ | Tentativi | Controllo visivo |
|---|---:|---|
| pedane_1.png e pedane_1.txt | 1 | Quattro sagome distinte. Il basalto ha una fascia rivettata e crepe basse. La base a incudine mostra quattro appoggi, uno in parte nascosto. |
| pedane_2.png e pedane_2.txt | 1 | Quattro sagome distinte. La lava ha una fascia continua e le crepe del basalto sono più marcate. Nella base a incudine si distinguono solo tre appoggi. |

Ho verificato i piani ovali liberi, i ripiani a destra, la separazione delle sagome e l'assenza di scritte, personaggi e ombre a terra. Ho uniformato il verde dominante a #00FF00 e verificato le dimensioni e i margini esterni a livello di pixel. Le fasce oro e lava sono più vistose degli accenti piccoli richiesti e conservano lievi variazioni di tono. Il limite cromatico, il rapporto di scala con il diavoletto e la resa con lo zainetto sulla home restano da verificare.

## Resoconto di Claude
