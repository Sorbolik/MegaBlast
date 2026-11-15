# WB-059 · Il Fabbro: spalline forgiate sulle braccia col pugno (rifacimento)

- **Stato:** APPROVATA (Claude, 15 nov: un foglio solo, rifà `pugni_forgiata` di WB-055 che Sergio ha approvato; reversibile)
- **Data:** 2026-11-15
- **Ramo della scheda:** `claude/project-thread-e8poye` (eseguila da questo ramo: `git fetch origin claude/project-thread-e8poye`) · **Ramo delle immagini:** `design/WB-059`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-059` senza chiedere conferma (il repository è privato).

## Obiettivo

In WB-055 il foglio `pugni_forgiata` è venuto sbagliato tre volte: sulle braccia col pugno Codex ha
messo il grembiule con la croce, perché il riferimento era tutto il foglio del corpo. Qui i
riferimenti sono solo braccia: R1 sono le braccia col pugno con la spallina base (buone), R2 le due
braccia aperte con la spallina forgiata. Serve lo stesso foglio di R1 con la spallina forgiata.

## Riferimenti da allegare

| File | Cosa è |
|---|---|
| `art/WB-059/riferimenti/R1_pugni_spalline_base.png` | le due braccia col pugno, spallina base: il foglio da modificare |
| `art/WB-059/riferimenti/R2_spalline_forgiate.png` | due braccia con la spallina forgiata: solo per come è fatta la spallina |

## Immagini da generare

Una immagine, 1536x1024, due varianti (`pugni_forgiata_1`, `pugni_forgiata_2`) in `art/WB-059/`,
ognuna col suo `.txt` del prompt. Allegare R1 e R2 in quest'ordine.

### `pugni_forgiata`

```
Image 1 is a sheet with two arms of our character with a closed fist, on flat magenta; each arm wears a small leather shoulder pad with a round brass stud. Image 2 shows two other arms wearing the FORGED version of that pad: a leather cap with a light strap, and at its lower edge a brass band with two cyan rivets.

Edit image 1 and return the SAME sheet: both arms exactly where they are, same size, same shapes. Change ONLY the shoulder pad on top of each arm: remove the round brass stud and give the pad a brass band along its lower edge with two round cyan rivets, like the pads of image 2. Keep the pad the same size and in the same place as in image 1. Do NOT add anything else: no apron, no crossed straps, no chest piece. The rest of each arm and the fist stay bare and unchanged.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Leather dark brown #6B4A2B with folds #4A3019, lighter straps #C89255, brass #D9A441, amber lenses #F2B92C, thick closed black #000000 outline like the heads. The leather must be clearly browner and darker than the red skin.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

## Criteri di accettazione

- [ ] il foglio è R1 identico (stesse braccia, stesse posizioni, stessa misura) tranne le spalline
- [ ] su ogni braccio solo la spallina: calotta di cuoio, fascia d'ottone in basso con due borchie ciano; niente grembiule né croce
- [ ] colori piatti, contorno nero chiuso e spesso, magenta pulito, nessuna scritta

---

## Decisione

(Claude) Approvata in autonomia: è il rifacimento di un foglio di una scheda già approvata da Sergio.

## Consegna di Codex

## Resoconto di Claude
