# WB-048 · Lo zaino a terra accanto al diavoletto

- **Stato:** SUPERATA da WB-090 (Sergio, 24 nov: via lo zainetto dalla home; le immagini restano nella storia di git)
- **Data:** 2026-11-14
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-048`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-048` senza chiedere conferma (il repository è privato).

## Obiettivo

Sulla home si apre lo ZAINO dal diavoletto. Le prime tre proposte (pezzi appesi al corpo,
piedistallo, medaglioni al tocco) non convincono Sergio. Proposta nuova di Claude: uno **zaino
vero**, una sacca di cuoio e ferro appoggiata al piede del diavoletto. Si capisce senza scritte:
lo tocchi (o tocchi il diavoletto) e si apre lo zaino; quando ci sono pezzi o sigilli nuovi ha il
pallino degli avvisi. Non tocca il personaggio e i suoi pezzi: è un oggetto a parte, a terra.

R2 è la bozza di Claude: la sacca lì è solo un segnaposto squadrato, va disegnata bene.

## Come deve essere fatto

- Un oggetto solo, alto circa un quarto del diavoletto, appoggiato a terra e un po' inclinato,
  come se il diavoletto l'avesse appena posato.
- Stile del diavoletto e dei pezzi di WB-022: china spessa, colori pieni, una luce e un'ombra
  piatte, forme morbide un po' storte. Ricalcabile in vettori (al massimo sei colori, niente più
  sottile della china), così Claude lo ricalca in SVG e lo esporta a ogni misura.
- Due stati: chiuso (di solito) e con la patta un po' sollevata e una scintilla (ci sono cose
  nuove). Stessa sagoma e stessa misura, così il gioco li scambia.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-048/riferimenti/R1_home_consigliata.png` | la home scelta: il diavoletto e dove sta lo zaino |
| R2 | `art/WB-048/riferimenti/R2_bozza_zaino_a_terra.png` | la bozza: posizione e grandezza della sacca (segnaposto) |
| R3 | `art/WB-022/pezzo_piccoli.png` | pezzi piccoli di WB-022: lo stile e la china |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto.

| Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|
| `zaino_a_terra` | R1, R2, R3 | 1536×1024 | 2 |

Le varianti si chiamano `zaino_a_terra_1.png`, `zaino_a_terra_2.png`, in `art/WB-048/`. Per ogni
foglio Codex scrive un `.txt` con lo stesso nome.

### `zaino_a_terra`

```
Image 1 is the home screen of our game: a little red devil apprentice stands in the middle, with menu buttons on both sides. Image 2 is the same screen with a rough square placeholder satchel leaning against his right foot: it shows WHERE the object goes and HOW BIG it is (about a quarter of the devil's height). Tapping it opens the player's backpack (his pieces of armour and his seals). Image 3 shows small pieces of the same game and is the STYLE to copy exactly: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow, soft hand-drawn slightly crooked shapes, like a cartoon comic.

Draw TWO versions of the same object side by side, well separated, each one large and filling half of the picture: a small adventurer's BACKPACK of a hellish blacksmith apprentice, resting on the ground and tilted a little to the left, as if he just put it down.
The backpack: a chubby rounded bag of warm brown leather (#7A5236, flat shadow #5E3E29), a big flap of dark forged iron (#2B2530, flat highlight #6B6375) covering its top half, held by a chunky gold buckle (#FFB703 with a small ember center #F26419); a short leather carry handle on top; one rolled strap peeking out on the side; a small scorch mark near the bottom; two small rivets on the flap.
1. CLOSED: the flap shut, the buckle closed.
2. SOMETHING NEW INSIDE: exactly the same backpack, same outline and same size, but the flap lifted a little and a small four-pointed ember spark (#FFB703, #F26419) popping out from under it.
The two versions have the same silhouette, so the game can swap them.

Thick black ink outline, cartoon comic style like image 3. Flat colors only, at most six, no detail thinner than the outline, so the object can be traced into vectors. No texture, no leather grain lines thinner than the outline, no soft gradients, no glow, no drop shadow on the ground. No text, letters or numbers. Do not draw the devil. Flat pure green background (#00FF00). The two versions do not touch each other and are not cut by the border of the picture.
```

## Criteri di accettazione

- [ ] si capisce che è uno zaino, nello stile del diavoletto, più calmo dei pulsanti
- [ ] due stati con la stessa sagoma
- [ ] colori pieni, china spessa, si ricalca in vettori
- [ ] sfondo verde pieno, niente scritte, niente diavoletto

## Dopo le immagini (lo fa Claude)

- Ritaglia lo zaino, lo monta sulla home del Figma al posto del segnaposto e lo mostra a Sergio.
- Se va bene: ricalco in SVG, nel gioco tocchi lo zaino o il diavoletto e si apre lo ZAINO, il
  secondo stato quando ci sono pezzi o sigilli nuovi.

## Decisione

Reversibile (solo immagini in un ramo): approvata su richiesta di Sergio. Se lo zaino non piace,
resta la proposta 3 (medaglioni al tocco), la più minimale.

## Consegna di Codex

Generati con `image_gen` da `main` (`63dbbed9`) e salvati in `art/WB-048/`.

| File | Tentativi | Dimensioni PNG |
|---|---:|---:|
| `zaino_a_terra_1.png` e `zaino_a_terra_1.txt` | 1 | 1774×887 |
| `zaino_a_terra_2.png` e `zaino_a_terra_2.txt` | 1 | 1774×887 |

I TXT contengono il prompt integrale e i riferimenti R1, R2, R3 nell'ordine allegato.
Controllati a vista gli stati chiuso e aperto con scintilla, la patta, la fibbia,
i due rivetti, il manico, la cinghia e la bruciatura. Gli oggetti sono separati,
interi, con contorno nero e senza scritte o personaggi. La variante 2 è più
diritta. In entrambi i fogli le sagome dei due stati sono simili a vista,
con piccole differenze. L'allineamento al pixel e la resa in home restano da verificare.

I PNG originali misurano 1774×887. La misura richiesta è 1536×1024.
Lo sfondo è verde opaco come richiesto, con valori campionati diversi da `#00FF00`.
Si vedono lievi variazioni di tono nelle campiture. Il limite di sei colori e il
ricalco in SVG restano da verificare.

## Resoconto di Claude

Entrambi i fogli sono buoni: contorno pulito, colori pieni, niente difetti visibili. Ritagliati
dal verde in `art/WB-048/ritagli/`: `zaino_chiuso_1`, `zaino_aperto_1`, `zaino_chiuso_2`,
`zaino_aperto_2` (l'aperto ha la scintilla, per quando ci sono pezzi nuovi). Scelta di Claude: la
variante 1, più inclinata come chiedeva la scheda; la 2 resta di scorta. Montato nel Figma al posto
del segnaposto (proposta «Zaino dal diavoletto/4»), appoggiato al piede destro del diavoletto. Da
decidere con Sergio se tenerlo al posto dei medaglioni al tocco; con la pedana di WB-050 può stare
sul suo ripiano.
