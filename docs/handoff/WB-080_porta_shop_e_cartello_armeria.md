# WB-080 · Porta SHOP della home e cartello ARMERIA

- **Stato:** APPROVATA (Sergio, 18 nov 21:37: «mi piace l'animazione [...] fammi la scheda»; 21:38: «e il tasto dello shop?»)
- **Data:** 2026-11-18
- **Ramo della scheda:** `claude/project-thread-rc20kg` (Codex la esegue da lì, non serve che sia su `main`) · **Ramo delle immagini:** `design/WB-080`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-080` senza chiedere conferma (il repository è privato).

## Obiettivo

L'armeria (potenziare i pezzi) adesso sta dentro lo ZAINO: ci si entra da POTENZIA, una lama taglia
le schede INVENTARIO e SIGILLI e dal taglio scende appeso un **cartello ARMERIA**. Nella home il
pulsante ARMERIA diventa lo **SHOP** (la Bottega del Fabbro: pezzi del giorno e offerte), quindi
serve una porta nuova della stessa famiglia delle altre quattro.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-080/riferimenti/R1_home_oggi.png` | la home di oggi: le quattro porte e GIOCA |
| R2 | `art/WB-080/riferimenti/R2_porta_armeria.png` | la porta ARMERIA di oggi: è lei che diventa SHOP (stessa misura, medaglione a destra, coda a sinistra) |
| R3 | `art/WB-080/riferimenti/R3_porta_eventi.png` | l'altra porta di destra: la famiglia da seguire |
| R4 | `art/WB-080/riferimenti/R4_armeria_nello_zaino.png` | l'armeria nello zaino con il cartello segnaposto sotto le schede tagliate |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto.

| Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|
| `porta_shop` | R1, R2, R3 | 1536×1024 | 2 |
| `cartello_armeria` | R4, R2 | 1536×1024 | 2 |

Le varianti si chiamano `porta_shop_1.png`, `porta_shop_2.png` e così via, in `art/WB-080/`.
Per ogni foglio Codex scrive un `.txt` con lo stesso nome.

### `porta_shop`

```
Image 1 is the home screen of our game. On the right there are two wide menu buttons, EVENTS (gold) and ARMOURY (dark iron with an ice-blue edge). Image 2 is the ARMOURY button alone and image 3 the EVENTS button alone: they are the family to follow. The ARMOURY button is being replaced by a new SHOP button (the blacksmith's shop where you buy pieces of armour with coins), so draw THREE proposals for the new SHOP button, one under the other with flat green space between them.

Each proposal has EXACTLY the layout of image 2: about four times wider than tall, a big round medallion with a metal rim and rivets at the RIGHT end that is a little taller than the body and overlaps it, the meaningful tail at the LEFT end, and in the middle a plain, even, empty body with no marks (the game writes "SHOP" and a small line under it there, and stretches only the middle). Same height, same medallion size and same thickness of ink as images 2 and 3.
1. COPPER AND PRICE TAG: warm copper body (#B5651D, lighter band #E39B4F, darker band #7A3E12); the left tail is cut like a big shop price tag with a round hole and a short string; medallion with a dark iron rim (#2B2530), inside a bulging leather coin pouch tied with a cord, with one gold coin with a flame on it (#FFB703) peeking out;
2. VIOLET VELVET AND PENNANT: deep violet body (#3B2152, lighter band #6B3F94, thin edge #C49CFF); the left tail is a merchant's pennant with two points; medallion with a gold rim (#FFB703), inside a small balance scale holding a gold coin with a flame on one plate and a little helmet on the other;
3. FORGE STALL: dark wood body (#5A3A22, lighter band #8A5A34) with an ember edge (#F26419); the left tail is a striped shop awning (ember and cream #F4ECE1) seen from the side, scalloped; medallion with a copper rim (#B5651D), inside a little market stall with an anvil on the counter.
Each must clearly differ in color from the other home buttons (ember CAMPAIGN, steel TRAINING, gold EVENTS) and look calmer than the gold PLAY button of image 1.

Thick black ink outline, cartoon comic style like images 2 and 3. Flat colors only, at most six per button, no detail thinner than the outline, so the buttons can be traced into vectors. No texture, no soft gradients, no glow, no drop shadow. No text, letters or numbers. Flat pure green background (#00FF00) around every button.
```

### `cartello_armeria`

```
Image 1 is a screen of our game: at the top there are two tab titles, INVENTORY and SEALS, cut through by a blade; from the cut a small sign drops down on two short chains and says ARMOURY. The sign in image 1 is only a placeholder: draw the real one. Image 2 shows the ink style and the dark iron colors of our buttons.

Draw THREE proposals for this hanging sign, one under the other with flat green space between them. Each is ONE piece: two short chains on top (each about a quarter of the sign's height, ending in a small ring that will hook to the cut line), and under them a wide sign about four times wider than tall, with a plain, even, empty face (the game writes ARMOURY on it in glowing gold letters, so leave it empty and dark).
1. FORGED IRON PLATE: dark iron (#2B2530, lighter #4A4550) with a thin ember rim (#F26419) and four round rivets in the corners;
2. ANVIL PLATE: dark iron face shaped like the top of an anvil, the horn pointing left, small hammer marks only along the border;
3. WOODEN SHOP SIGN WITH IRON BANDS: dark wood (#3A2A22) held by two iron bands (#4A4550) at the ends, a thin ember edge (#F26419) on the bottom.
The sign must read on a dark purple background and must look like the same world as image 2.

Thick black ink outline, cartoon comic style like image 2. Flat colors only, at most six per sign, no detail thinner than the outline, so it can be traced into vectors. No texture, no soft gradients, no glow, no drop shadow. No text, letters or numbers. Flat pure green background (#00FF00) around every sign.
```

## Criteri di accettazione

- [ ] porta SHOP: stessa disposizione e misura di ARMERIA (medaglione a destra, coda a sinistra, mezzo liscio e vuoto), colori diversi dalle altre porte
- [ ] cartello: un pezzo solo con due catenelle in alto, faccia scura liscia e vuota
- [ ] contorno nero puro e spesso, colori pieni, niente sfumature né bagliori, nessuna scritta
- [ ] sfondo verde pieno attorno a ogni pezzo, nessun pezzo che tocca un altro o il bordo

---

## Decisione

Approvata da Claude il 18 nov (reversibile: sono solo immagini), dopo il sì di Sergio all'animazione.

## Consegna di Codex

## Resoconto di Claude
