# WB-088 · Le icone delle azioni (ogni pulsante con la sua)

- **Stato:** PROPOSTA (si approva col sì di Sergio alla direzione della pagina «Interfaccia lineare»)
- **Data:** 2026-11-23
- **Ramo della scheda:** `claude/project-thread-5nnzn0` (Codex la esegue da qui: `git fetch origin claude/project-thread-5nnzn0`, non serve che sia su `main`) · **Ramo delle immagini:** `design/WB-088`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-088` senza chiedere conferma (il repository è privato).

## Obiettivo

Sergio, 23 nov: «tutti i tasti del gioco nella barra di sotto devono essere come quello
secondario [...] ed ogni singolo tasto deve avere la sua iconcina alla sinistra». Il pulsante
(principale in ferro rovente, secondario in ferro scuro) lo disegna il gioco a vettori come il
«Ferro liscio» di oggi (`tools/grafica/fucina.py`): servono **le icone**, una per azione, grandi
e leggibili, che sporgono dal capo sinistro del pulsante un po' storte (R1, R2). Alcune ci sono
già (calendario, chiave, maglio, scaglia, punto libero: R3) e restano; qui si fanno quelle che mancano.

Anteprime e catalogo: https://claude.ai/artifact/1Q194msz5CffxCcFgec87c ·
`docs/ui-catalogo.md` (scopi 1 e 2).

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-088/riferimenti/R1_pulsanti_proposti.png` | i pulsanti proposti: l'icona sporge dal capo sinistro (qui ci sono segnaposto) |
| R2 | `art/WB-088/riferimenti/R2_zaino_proposto.png` | lo zaino con i pulsanti nuovi: si vede quanto è grande l'icona sullo schermo |
| R3 | `art/WB-088/riferimenti/R3_icone_di_oggi.png` | icone che abbiamo già (calendario, chiave, maglio, due diavoletti, punto, scaglia): **lo stile da copiare** |

## Immagini da generare

Tre fogli da otto icone (due righe da quattro). Il prompt è completo e va usato così com'è.
Allega i riferimenti nell'ordine scritto: il primo è "image 1" e così via.

| Nome file | Icone | Riferimenti | Misura | Varianti |
|---|---|---|---|---|
| `azioni_1` | GIOCA, INDOSSA, POTENZIA, CONSEGNA, PRONTO, SALVA, TORNA AI MENU, ESCI | R3, R1, R2 | 1536×1024 | 2 |
| `azioni_2` | CHIAMA UN CLIENTE, SCAMBIA, CAMBIA, PROVA, RIPROVA, ELENCO, SALTA, VEDI TUTTE | R3, R1, R2 | 1536×1024 | 2 |
| `azioni_3` | MIRA, RILEGGI, TASTI DEL CONTROLLER, IL MIO PROFILO, ANNULLA, RIPRISTINA, 1 CONTRO 1, VIA | R3, R1, R2 | 1536×1024 | 2 |

Le varianti si chiamano `azioni_1_1.png`, `azioni_1_2.png` e così via, in `art/WB-088/`. Per ogni
foglio Codex scrive un `.txt` con lo stesso nome: cosa ha fatto e cosa non è riuscito a rispettare.

### `azioni_1`

```
Image 1 shows icons of our game, a cartoon turn-based artillery game played by little red horned devils: a calendar, a key, a hammer, two devil masks, a small flame, a gold scale coin. They are the STYLE to copy exactly: thick slightly irregular pure black ink outline, flat colors (ivory #F4ECE1 as the main color, with small touches of ember orange #F26419, gold #FFB703 or ice blue #38B6FF only where the meaning needs it), one flat highlight and one flat shadow, soft hand-drawn slightly crooked shapes, like a cartoon comic, bold and readable. Image 2 shows our buttons: a long dark iron slab with an icon sticking out of its left end, big and slightly tilted. Image 3 shows how big the icons are on the phone screen: about 70 pixels, so each icon must be ONE bold silhouette that reads at a glance, no thin details, no text.

Draw EIGHT separate icons on one sheet, in two rows of four, well apart, all the same visual size, each fitting a square, on plain green (#00FF00):
1. GIOCA (play): a short flaming sword pointing up-right, ivory blade, ember flame along the edge.
2. INDOSSA (wear): a horned helmet seen from the front, ivory with a gold band, with a small ivory down-arrow above it, as if it is being put on.
3. POTENZIA (upgrade): a small anvil with a hammer striking it and three orange sparks.
4. CONSEGNA (deliver): a paper ticket with a dog-ear corner and a round hole at the top, tied with a string, a gold tick on it.
5. PRONTO (ready): a big bold check mark, ivory with an ember glow line along its bottom edge.
6. SALVA (save): a stone tablet with a gold seal pressed in the middle.
7. TORNA AI MENU (back to the menus): a small arched wooden door, half open, with a curved arrow going into it.
8. ESCI (quit): an open door with an arrow coming out of it, toward the right.
No letters, no numbers, no shadow on the ground, no glow outside the ink. Background plain green #00FF00 so it can be cut out.
```

### `azioni_2`

```
Image 1 shows icons of our game, a cartoon turn-based artillery game played by little red horned devils: a calendar, a key, a hammer, two devil masks, a small flame, a gold scale coin. They are the STYLE to copy exactly: thick slightly irregular pure black ink outline, flat colors (ivory #F4ECE1 as the main color, with small touches of ember orange #F26419, gold #FFB703 or ice blue #38B6FF only where the meaning needs it), one flat highlight and one flat shadow, soft hand-drawn slightly crooked shapes, like a cartoon comic, bold and readable. Image 2 shows our buttons: a long dark iron slab with an icon sticking out of its left end, big and slightly tilted. Image 3 shows how big the icons are on the phone screen: about 70 pixels, so each icon must be ONE bold silhouette that reads at a glance, no thin details, no text.

Draw EIGHT separate icons on one sheet, in two rows of four, well apart, all the same visual size, each fitting a square, on plain green (#00FF00):
1. CHIAMA UN CLIENTE (call a customer): a small shop bell with a wooden handle, ringing, two short ivory lines beside it.
2. SCAMBIA (swap): two curved arrows chasing each other in a circle, one ember and one ice blue.
3. CAMBIA (change): a single card flipping over, its back ivory, its edge ember.
4. PROVA (try on the test bench): a round target with a dart stuck in the centre, ivory and ember rings.
5. RIPROVA (retry): one thick circular arrow turning to the left, ivory with an ember tip.
6. ELENCO (list): a short scroll of parchment with three bold lines on it.
7. SALTA (skip): two bold triangles pointing right, one after the other, ivory.
8. VEDI TUTTE (see all): an eye, wide open, ivory with a gold iris.
No letters, no numbers, no shadow on the ground, no glow outside the ink. Background plain green #00FF00 so it can be cut out.
```

### `azioni_3`

```
Image 1 shows icons of our game, a cartoon turn-based artillery game played by little red horned devils: a calendar, a key, a hammer, two devil masks, a small flame, a gold scale coin. They are the STYLE to copy exactly: thick slightly irregular pure black ink outline, flat colors (ivory #F4ECE1 as the main color, with small touches of ember orange #F26419, gold #FFB703 or ice blue #38B6FF only where the meaning needs it), one flat highlight and one flat shadow, soft hand-drawn slightly crooked shapes, like a cartoon comic, bold and readable. Image 2 shows our buttons: a long dark iron slab with an icon sticking out of its left end, big and slightly tilted. Image 3 shows how big the icons are on the phone screen: about 70 pixels, so each icon must be ONE bold silhouette that reads at a glance, no thin details, no text.

Draw EIGHT separate icons on one sheet, in two rows of four, well apart, all the same visual size, each fitting a square, on plain green (#00FF00):
1. MIRA (aim): a round crosshair, ivory, with a small ember dot in the middle.
2. RILEGGI (read again): an open book with a small curved arrow above it.
3. TASTI DEL CONTROLLER (controller buttons): a game controller seen from the front, ivory, with four round buttons.
4. IL MIO PROFILO (my profile): the head of a little horned devil in a round frame, ivory frame, red face, big friendly eyes.
5. ANNULLA (cancel): a bold X made of two crossed ivory bars with an ember edge.
6. RIPRISTINA (reset): a small wrench crossed with a circular arrow.
7. 1 CONTRO 1 (one versus one): ONE devil mask, the same style as the two masks of image 1, alone and looking forward.
8. VIA (go): a small pennant flag on a short pole, ember cloth.
No letters, no numbers, no shadow on the ground, no glow outside the ink. Background plain green #00FF00 so it can be cut out.
```

## Criteri di accettazione

- [ ] contorno nero puro e spesso, nessuna scritta
- [ ] stesso stile delle icone di R3 (china, avorio, tocchi di colore piatti)
- [ ] ogni icona si capisce a 48 px e sta in un quadrato
- [ ] le otto icone di un foglio hanno la stessa grandezza visiva e sono ben separate

---

## Decisione

(in attesa: Sergio approva la direzione della pagina «Interfaccia lineare»)

Claude, 23 nov: pulsanti, card minimale, pillola e solco della barra li disegna il gioco a vettori
in `tools/grafica/fucina.py`, come il «Ferro liscio» approvato il 18 nov (linee pulite, «senza bump
e senza sporcizie»); a Codex vanno solo le icone, che sono disegni. Le icone che ci sono già
(calendario, chiave, maglio, due diavoletti, punto libero, scaglia, frammenti, gemma) restano.

## Consegna di Codex

## Resoconto di Claude
