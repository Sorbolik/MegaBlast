# WB-089 · Le icone delle porte della home (grandi, senza cornice tonda)

- **Stato:** IMPLEMENTATA (Sergio, 24 nov: scelte una per una)
- **Data:** 2026-11-24
- **Ramo della scheda:** `claude/project-thread-5nnzn0` (Codex la esegue da qui: `git fetch origin claude/project-thread-5nnzn0`, non serve che sia su `main`) · **Ramo delle immagini:** `design/WB-089`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-089` senza chiedere conferma (il repository è privato).

## Obiettivo

Le quattro porte della home (CAMPAGNA, ALLENAMENTO, EVENTI, BOTTEGA) diventano pulsanti come gli
altri: la lastra di ferro del gioco, riempita del colore del posto (proposta B, scelta da Sergio
il 24 nov, R3). Oggi l'icona di ogni porta è il disegno dentro un medaglione tondo con i rivetti
(R1). Sergio: «c'è modo di rendere le icone come le altre, ma un po' più particolari? O in generale
più grandi, ma senza la cornice tonda». Servono quindi **quattro icone grandi, senza cornice**,
nello stile delle icone delle azioni (R2) ma più ricche: sono le porte dei luoghi del gioco, non
semplici azioni. Sporgono dal capo esterno della lastra, verso il bordo dello schermo (R3), a
circa 120 pixel sul telefono (quasi il doppio delle icone dei pulsanti).

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-089/riferimenti/R1_medaglioni_di_oggi.png` | i quattro medaglioni di oggi (campagna, allenamento, eventi, bottega): i soggetti da tenere, la cornice tonda da togliere |
| R2 | `art/WB-089/riferimenti/R2_icone_delle_azioni.png` | le icone delle azioni (WB-088): **lo stile da copiare** |
| R3 | `art/WB-089/riferimenti/R3_porte_proposta_B.png` | la home con le porte nuove: lastre colorate, l'icona sporge dal capo verso il bordo (oggi c'è ancora il medaglione) |

## Immagini da generare

Due fogli da quattro icone (una riga da quattro), due varianti ciascuno. Il prompt è completo e
va usato così com'è. Allega i riferimenti nell'ordine scritto: il primo è "image 1" e così via.

| Nome file | Icone | Riferimenti | Misura | Varianti |
|---|---|---|---|---|
| `porte_oggetti` | CAMPAGNA, ALLENAMENTO, EVENTI, BOTTEGA come oggetti singoli | R2, R1, R3 | 1536×1024 | 2 |
| `porte_scenette` | le stesse come piccole scene ritagliate | R2, R1, R3 | 1536×1024 | 2 |

Le varianti si chiamano `porte_oggetti_1.png`, `porte_oggetti_2.png` e così via, in `art/WB-089/`.
Per ogni foglio Codex scrive un `.txt` con lo stesso nome: cosa ha fatto e cosa non è riuscito a rispettare.

### `porte_oggetti`

```
Image 1 shows icons of our game, a cartoon turn-based artillery game played by little red horned devils. They are the STYLE to copy exactly: thick slightly irregular pure black ink outline, flat colors, one flat highlight and one flat shadow, soft hand-drawn slightly crooked shapes, like a cartoon comic, bold and readable. Image 2 shows the four round medallions we use today for the four places of the home screen: they show WHAT each icon is about, but we do NOT want the round frame, the rivets or the dark round background any more. Image 3 shows the home screen: each place is a long colored iron slab, and its icon will stick out of the slab's outer end, big, about twice the size of the other icons.

Draw FOUR separate icons on one sheet, in one row, well apart, all the same visual size, each fitting a square, on plain green (#00FF00). Each is ONE bold free-standing object with NO frame, NO circle, NO badge behind it, richer and more special than the simple action icons (more color, a little more detail, still one clear silhouette that reads at 120 pixels):
1. CAMPAGNA (the campaign, a journey down through the circles of hell): a crooked wooden signpost with one arrow-shaped sign pointing down-right, small ember flames licking from the bottom of the post. Colors: wood brown, ember red-orange #E0402A flames.
2. ALLENAMENTO (training against bots): a round straw archery target on a small wooden easel, red and ivory rings, one arrow stuck in the centre. Colors: straw yellow, red #D9352B, ivory #F4ECE1, teal #2FB59A arrow fletching.
3. EVENTI (events): a big gold crown #FFB703 with three points, a red gem in the middle, a small ivory pennant flag stuck on top of the middle point.
4. BOTTEGA (the blacksmith's shop): a small iron anvil with a striped orange and ivory awning tilted above it, like a tiny market stall, a little gold coin on the anvil.
No letters, no numbers, no shadow on the ground, no glow outside the ink. Background plain green #00FF00 so it can be cut out.
```

### `porte_scenette`

```
Image 1 shows icons of our game, a cartoon turn-based artillery game played by little red horned devils. They are the STYLE to copy exactly: thick slightly irregular pure black ink outline, flat colors, one flat highlight and one flat shadow, soft hand-drawn slightly crooked shapes, like a cartoon comic, bold and readable. Image 2 shows the four round medallions we use today for the four places of the home screen: keep their subjects, but we do NOT want the round frame, the rivets or the round background any more. Image 3 shows the home screen: each place is a long colored iron slab, and its icon will stick out of the slab's outer end, big, about twice the size of the other icons.

Draw FOUR separate icons on one sheet, in one row, well apart, all the same visual size, each fitting a square, on plain green (#00FF00). Each is a tiny self-contained scene cut out on its own irregular ground (a small rock or a patch of floor under it), with NO frame and NO circle around it, the whole shape outlined in thick black ink so it reads as one silhouette at 120 pixels:
1. CAMPAGNA: a winding sand path going down into a rocky crater with ember flames #E0402A rising from the bottom, seen from slightly above.
2. ALLENAMENTO: a round straw target on a wooden post with an arrow in the bullseye, a small tuft of grass at its foot, teal #2FB59A arrow fletching.
3. EVENTI: a gold crown #FFB703 resting on a small red velvet cushion with gold tassels.
4. BOTTEGA: a tiny wooden market stall with a striped orange and ivory awning and an iron anvil on the counter.
No letters, no numbers, no glow outside the ink. Background plain green #00FF00 so it can be cut out.
```

## Criteri di accettazione

- [ ] sfondo verde pulito (si ritaglia), contorno nero puro e spesso, nessuna scritta
- [ ] nessuna cornice tonda, nessun disco o medaglione dietro l'icona
- [ ] stesso stile delle icone delle azioni (R2): colori piatti, una luce e un'ombra
- [ ] ogni icona leggibile a 120 px, una sagoma sola
- [ ] le quattro alla stessa grandezza visiva, ben separate

---

## Decisione

Proposte da far vedere a Sergio (Claude, 24 nov): si sceglie un foglio o un'icona per porta.

## Consegna di Codex

## Resoconto di Claude

Sergio ha scelto un'icona per porta (24 nov): CAMPAGNA il falò col sentiero (`porte_scenette_2`), ALLENAMENTO il
bersaglio (`porte_oggetti_2`), EVENTI la corona sul cuscino (`porte_scenette_1`), BOTTEGA la bancarella
(`porte_oggetti_2`). I tre fogli sono in `art/WB-089/`. `fai_porte` in `tools/grafica/fucina.py` le ritaglia col verde
tolto come le icone delle azioni e le salva alte 280. La bancarella aperta mostrava la home dietro: i buchi
sono chiusi di legno scuro finché non arriva WB-091. Scartati i cartelli con le fiamme staccate e le altre varianti.
