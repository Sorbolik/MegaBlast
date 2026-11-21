# WB-082 · L'icona del gioco sul telefono

- **Stato:** APPROVATA (Claude, 21 nov: è reversibile; Sergio ha chiesto l'icona adattiva)
- **Data:** 2026-11-21
- **Ramo della scheda:** `claude/project-thread-2j0xy8` (eseguila da questo ramo: `git fetch origin claude/project-thread-2j0xy8`) · **Ramo delle immagini:** `design/WB-082`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-082` senza chiedere conferma (il repository è privato).

## Obiettivo

Oggi MegaBlast sul telefono non ha un'icona sua: Android mostra quella di base. Serve
un'**icona adattiva** (Android 8+): un primo piano col diavoletto su fondo trasparente e uno
sfondo pieno, che il telefono ritaglia nella sua forma (cerchio, goccia, quadrato arrotondato) e
muove un poco. Dalle stesse due immagini Claude compone anche l'icona classica per i telefoni
vecchi. Stile del gioco: fumetto, contorno d'inchiostro, Filo di Brace (fuoco in basso a
sinistra, ghiaccio in alto a destra).

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `client/assets/skins/apprendista_nuovo_testa_felice_1.png` | la testa del diavoletto del gioco (apprendista nuovo), felice: è lui il soggetto |
| R2 | `client/assets/skins/apprendista_nuovo_testa_provocazione_1.png` | la stessa testa, espressione di sfida: per l'aria spavalda |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Tutto in `art/WB-082/`, ogni PNG col suo `.txt`
del prompt.

| Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|
| `icona_primo_piano.png` | R1, R2 | 1024×1024 | 2 |
| `icona_sfondo.png` | nessuno | 1024×1024 | 2 |

In tutto 4 immagini.

### `icona_primo_piano`

Allegati: R1, R2.

```
Images 1 and 2 are the head of the hero of our mobile game, a small red devil apprentice, drawn in our comic style. Draw an APP ICON FOREGROUND with this same character: his head and shoulders, three-quarter view, cheeky confident grin like image 2 with the happy eyes of image 1, looking at the viewer. He is the SAME character: same head shape, same big pointed ears, same red skin #B8402A with darker red shadow shapes, same cream muzzle #F2DCA8, same black outline, same eyes and teeth style. No new accessories, no hat, no horns, no text.

Composition, very strict, because Android crops this layer into a circle and moves it:
- Canvas 1024x1024, background fully TRANSPARENT (alpha), nothing drawn outside the character.
- The whole character fits inside a centered circle of diameter 660 px (the safe zone): no ear, no shoulder and no outline crosses that circle. Leave the rest of the canvas empty.
- The head is big and readable at 48 px: few large shapes, the face at the visual center.

Rendering rules:
- FLAT COLORS ONLY: every area is one solid color, plus at most one hard-edged shadow shape in the darker tone. No gradients, no textures, no soft shading, no glow, no drop shadow.
- Thick closed pure black #000000 outline, heavier than usual (it must survive being shown at 48 px).
- No text, numbers, letters, logos or signatures.
```

### `icona_sfondo`

Allegati: nessuno.

```
Draw an APP ICON BACKGROUND for a comic-style mobile game about a little fire devil: a full-bleed square 1024x1024, no character, no text. A dark warm night-red base #2A0E0A. From the bottom-left corner a big comic flame of orange #FF7A1A and yellow #FFC93C licks diagonally toward the center; from the top-right corner a cold cyan #19E6E6 frost shape answers it; the two meet in a jagged diagonal split behind the center. Large simple shapes only, readable when the square is cropped into a circle of diameter 1024 and when it is shrunk to 48 px.

Rendering rules:
- FLAT COLORS ONLY: solid areas with hard edges, no gradients, no textures, no noise, no glow.
- Ink-style black #000000 outlines around the flame and frost shapes, the same weight as a comic panel.
- The square is completely filled: no transparency, no border, no rounded corners, no vignette.
- No text, numbers, letters, logos or signatures.
```

## Criteri di accettazione

- [ ] il diavoletto è riconoscibile come quello del gioco (orecchie, muso crema, rosso, contorno)
- [ ] primo piano su trasparente pulito, tutto dentro il cerchio di 660 px al centro
- [ ] sfondo pieno fino ai bordi, nessuna trasparenza, nessun angolo arrotondato
- [ ] a 48 px si capisce ancora: faccia grande, poche forme
- [ ] colori piatti, contorno nero puro e spesso, nessuna scritta

## Come entra nel gioco (per Claude, dopo le immagini)

- `game.project`, sezione `[android]`: `app_icon_36x36` … `app_icon_192x192` con l'icona classica
  composta (sfondo ritagliato a quadrato arrotondato + primo piano), così il manifest ha
  `android:icon="@drawable/icon"`.
- Icona adattiva come risorsa dell'estensione `client/vibra`:
  `res/android/res/drawable-anydpi-v26/icon.xml` (`<adaptive-icon>` con `@drawable/icon_primo_piano`
  e `@drawable/icon_sfondo`, più `<monochrome>` col primo piano per le icone a tema) e i due PNG
  432×432 in `res/android/res/drawable-xxxhdpi/`. Su Android 8+ vince l'xml, sui vecchi il PNG.
- Prova: APK di prova da Actions e foto della schermata home del telefono.

---

## Decisione

Approvata da Claude il 21 nov (reversibile).

## Consegna di Codex

## Resoconto di Claude
