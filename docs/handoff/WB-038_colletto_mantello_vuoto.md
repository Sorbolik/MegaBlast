# WB-038 · Colletto del mantello del Vuoto, attorno al collo

- **Stato:** PROPOSTA
- **Data:** 2026-11-13
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-038`

## Obiettivo

Quando l'apprendista si mette un mantello, il fazzoletto sparisce e il mantello gira attorno al
collo (Sergio, 13 nov). Il busto col collo nudo e il fazzoletto a parte sono in WB-037
(`corpo_1`). Serve il colletto del mantello del Vuoto (WB-032 B, base e forgiata) **disegnato sul
foglio di `corpo_1`**, sopra il busto, nella stessa posizione: così il colletto si ritaglia per
differenza dal foglio di partenza e combacia col busto senza metterlo a occhio. Il resto del
mantello (quello che pende dietro) resta quello di WB-032: il colletto è solo la parte davanti,
attorno al collo, da cui il mantello scende dietro la spalla.
Il colore della squadra, che oggi sta sul fazzoletto, passa al colletto: una fascia nel verde
#00FF00, che il gioco tinge (scelta di Sergio sulla scheda, raccomandata da Claude).

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-038/riferimenti/R1_corpo_collo_nudo.png` | il foglio `corpo_1` di WB-037: busto col collo nudo, fazzoletto in alto |
| R2 | `art/WB-032/vuoto_base_B.png` | il mantello del Vuoto, forma base (colori, strappi, pieghe) |
| R3 | `art/WB-032/vuoto_forgiata_B.png` | lo stesso mantello, forma forgiata (occhio e finiture ciano) |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Si lavora SOPRA R1: stesso foglio, stessa misura.

| Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|
| `art/WB-038/colletto_base.png` | R1, R2 | 1536×1024 | 2 |
| `art/WB-038/colletto_forgiata.png` | R1, R3, `colletto_base_N.png` scelto | 1536×1024 | 1 |

Le varianti si chiamano `colletto_base_1.png`, `colletto_base_2.png`. La forgiata parte dalla
base migliore (Codex sceglie quella con il busto più identico a R1 e lo scrive nel `.txt`).

### `colletto_base`

```
Image 1 is a sheet of body parts of our character on flat magenta. Image 2 is the cape this character wears (basic form): indigo cloth, darker folds, thick black outline, torn hem.

Edit image 1 and return the SAME sheet: every part stays exactly where it is, same size, same shapes, same colors, same pixels. Change only two things:
1. Remove the green neckerchief at the top of the sheet: there is only flat magenta there.
2. On the torso in the middle, draw the COLLAR of the cape of image 2, wrapped around the bare neck stub at the top of the torso: a short band of the same indigo cloth that goes around the neck, closed in front by a small round clasp, with the cloth falling a little over the top of the back shoulder (the left side of the torso), where the long part of the cape will hang behind the body. Inside the collar band, a stripe of flat bright green #00FF00 with its shadow #00B400 runs all around the neck: it is the only green on the sheet. The collar covers the top of the torso only: the belly, the arms, the legs, the tail and the fist do not change at all.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Cloth indigo #2B2147 with folds #1A1430, thick closed black #000000 outline like the other parts, green #00FF00 with shadow #00B400 only in the collar stripe.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

### `colletto_forgiata`

```
Image 1 is a sheet of body parts of our character on flat magenta. Image 2 is the forged form of the cape this character wears. Image 3 is the same sheet with the collar of the basic cape already drawn on the torso.

Return image 3 again, the SAME sheet with every part exactly where it is, same size and same pixels, and change only the collar: make it the FORGED collar of image 2. Same outline and same place as in image 3, the same bright green #00FF00 stripe around the neck (shadow #00B400), and add a thin pure cyan #00FFFF trim along the lower edge of the collar and a tiny cyan eye on the round clasp in front. Nothing else on the sheet changes.

Rendering rules, very strict, because these parts will be traced into vector shapes:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow.
- Cloth indigo #2B2147 with folds #1A1430, thick closed black #000000 outline, cyan #00FFFF trims, green #00FF00 with shadow #00B400 only in the collar stripe.
- Background: flat pure magenta #FF00FF everywhere, with no halo around the parts.
- No text, numbers, labels, arrows or signatures.
```

## Criteri di accettazione

- [ ] il foglio è R1 identico (stessi pezzi, stesse posizioni, stessa misura) tranne il colletto e il fazzoletto tolto
- [ ] il colletto gira attorno al collo, chiuso davanti, e scende un poco sulla spalla di dietro
- [ ] una fascia verde #00FF00 nel colletto, nessun altro verde
- [ ] contorno nero chiuso e spesso, colori piatti, magenta pulito, nessuna scritta
- [ ] la forgiata ha la stessa sagoma della base, con finitura e occhio ciano

---

## Decisione

In attesa di Sergio.

## Consegna di Codex

## Resoconto di Claude
