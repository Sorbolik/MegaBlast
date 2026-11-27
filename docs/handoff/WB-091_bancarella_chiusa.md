# WB-091 · La bancarella della BOTTEGA con il fondo chiuso

- **Stato:** APPROVATA (Claude, 24 nov: è reversibile; Sergio: «la bottega mi dà fastidio che faccia vedere quello che c'è dietro»)
- **Data:** 2026-11-24
- **Ramo della scheda:** `claude/project-thread-5nnzn0` (Codex la esegue da qui: `git fetch origin claude/project-thread-5nnzn0`) · **Ramo delle immagini:** `design/WB-091`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-091` senza chiedere conferma (il repository è privato).

## Obiettivo

L'icona della porta BOTTEGA della home (scelta da Sergio fra quelle di WB-089, R1) è una
bancarella aperta: fra i pali, sopra e sotto l'incudine, si vede lo sfondo della home. Serve la
**stessa identica bancarella** con il fondo chiuso da una parete di assi di legno scuro, così
dietro all'incudine non si vede niente. Tutto il resto (tenda, pali, incudine, moneta, banco,
contorno) resta uguale.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-091/riferimenti/R1_bancarella_di_oggi.png` | la bancarella di oggi (WB-089, `porte_oggetti_2`, quarta icona): **da copiare identica** |
| R2 | `art/WB-091/riferimenti/R2_porte_della_home.png` | la home con le porte nuove: la bancarella sta a destra di BOTTEGA (lì i buchi sono riempiti a mano, solo per la prova) |

## Immagini da generare

| Nome file | Cosa | Riferimenti | Misura | Varianti |
|---|---|---|---|---|
| `bancarella_chiusa` | la bancarella con il fondo di assi | R1, R2 | 1024×1024 | 2 |

Le varianti si chiamano `bancarella_chiusa_1.png` e `bancarella_chiusa_2.png`, in `art/WB-091/`, con un `.txt` ciascuna.

### `bancarella_chiusa`

```
Image 1 is an icon of our game: a tiny wooden market stall with a striped orange and ivory awning, an iron anvil with a gold coin on it, a wooden counter, thick black ink outline, flat colors. Image 2 shows it in the home screen, next to the BOTTEGA button.

Redraw EXACTLY the same stall, same shapes, same proportions, same colors, same ink outline, same awning, posts, anvil, coin and counter, with ONE change: the back of the stall is closed by a wall of vertical dark wooden planks (dark brown #4A2C1C with a slightly darker shadow and thin black ink lines between the planks), filling all the space between the two posts, from under the awning down to the counter, behind the anvil. Nothing of the background must show through the stall any more. The anvil stays in front of the planks, clearly readable.
One icon, centered, filling about 80% of the square, on plain green (#00FF00) so it can be cut out. No letters, no shadow on the ground, no glow outside the ink.
```

## Criteri di accettazione

- [ ] identica a R1 tranne il fondo di assi
- [ ] fra i pali non si vede più lo sfondo (verde) da nessuna parte
- [ ] l'incudine si legge bene davanti alle assi
- [ ] sfondo verde pulito, contorno nero puro e spesso, nessuna scritta

---

## Decisione

Approvata da Claude (24 nov), reversibile: si sceglie la variante migliore e va nella porta BOTTEGA.

## Consegna di Codex

## Resoconto di Claude
