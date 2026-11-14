# WB-047 · Segni ed emblemi dei menu ancora improvvisati

- **Stato:** APPROVATA (Sergio, 14 nov 22:52: «fammi delle schede anche per tutte le altre cose che hai "improvvisato"»)
- **Data:** 2026-11-14
- **Ramo della scheda:** `main` · **Ramo delle immagini:** `design/WB-047`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-047` senza chiedere conferma (il repository è privato).

## Obiettivo

Dopo WB-043, WB-044 e WB-046, nelle nove schermate scelte restano pochi segni disegnati da
Claude con forme piatte. Claude li ha passati tutti (14 nov):

| Improvvisato | Come si sistema |
|---|---|
| barra del livello del pezzo, barre dei danni per arma, barra dell'esperienza, binari delle vie dei sigilli | con le barre brace, chiara e ghiaccio di WB-029 (ci sono già) |
| tacche 10, 20, 30 sulla barra del livello | con la tacca di WB-029 (c'è già) |
| nodi delle vie dei sigilli | con i tondi di ferro, oro e ghiaccio di WB-029 (ci sono già) |
| pallini colorati delle famiglie (filtri e caselle) | con la gemma della famiglia di WB-044, tinta dal gioco |
| scheda grande della modalità scelta, tabellone della classifica | con i pannelli caldo e scuro di WB-022 |
| **targhette dei badge** (BADGE I, II, III, IV nelle statistiche) | **questa scheda** |
| **prezzo vecchio barrato** nella bottega | **questa scheda** |
| **segno «sei qui»** nella classifica mondiale | **questa scheda** |
| **emblemi delle modalità e degli eventi** (Gran Torneo, Sfida del Maglio, Notte dei gironi, evento generico) | **questa scheda** |

## Come devono essere fatti

- Stessa regola di WB-044: disegnati grandi, colori pieni (al massimo cinque per pezzo), china
  chiusa e spessa, niente più sottile della china, così Claude li ricalca in SVG e li esporta a
  ogni misura, anche più grandi.
- Le targhette hanno il mezzo liscio e vuoto (si allungano e il gioco ci scrive).
- Gli emblemi sono avorio con un'ombra piatta, come le icone delle sezioni di WB-044 (R3), così il
  gioco li tinge.
- Niente scritte, lettere o numeri.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-022/pezzo_piccoli.png` | pezzi piccoli di WB-022: stile e china |
| R2 | `art/WB-029/pezzo_segni_1.png` | stelle, medaglia e corona di WB-029 |
| R3 | `art/WB-047/riferimenti/R3_icone_sezioni.png` | le icone delle sezioni di WB-044: lo stile degli emblemi |
| R4 | `art/WB-044/riferimenti/R4_bozze_menu.jpg` | le nove schermate: dove va ogni pezzo |

## Immagini da generare

Ogni prompt è completo e va usato così com'è. Allega i riferimenti nell'ordine scritto. Misura
1536×1024 per tutti.

| Nome file | Cosa c'è | Riferimenti | Varianti |
|---|---|---|---|
| `pezzo_badge` | quattro targhette dei badge, prezzo barrato, segno «sei qui» | R1, R2, R4 | 2 |
| `emblemi_eventi` | sei emblemi di modalità ed eventi | R3, R2, R4 | 2 |

Le varianti si chiamano `pezzo_badge_1.png`, `pezzo_badge_2.png` e così via, in `art/WB-047/`.
Per ogni foglio Codex scrive un `.txt` con lo stesso nome.

### `pezzo_badge`

```
Images 1 and 2 show pieces of the same game interface and are the STYLE to copy exactly: thick slightly irregular black ink outline, flat colors, one flat highlight and one flat shadow per piece, soft hand-drawn slightly crooked shapes, like a cartoon comic. Dark iron is #2B2530 with highlight #6B6375, ember is #F26419 to #FFB703, ivory is #F4ECE1, ice is #38B6FF with highlight #CAF0F8. Image 3 is a mock-up of the game's menus: the yellow "BADGE" capsules next to the player's statistics, the crossed old prices in the shop and the highlighted own row of the world ranking are drawn there as plain placeholders, these pieces replace them.

Draw a sheet with SEVEN separate pieces, each one large and filling its cell:
1. a small badge plaque for grade I: a short plate about three times wider than tall in dull iron (#5A5560, highlight #8A8590), its left end shaped like a small notched ribbon tail, its right end rounded, the middle plain, even and empty;
2. the same badge plaque for grade II in bronze (#B5673A, highlight #E0975F);
3. the same badge plaque for grade III in silver (#B9C2CC, highlight #E8EEF3);
4. the same badge plaque for grade IV in gold (#FFB703, lighter band #FFE08A, darker band #F26419), with a tiny flame tongue rising from its top right corner;
5. a strike-through mark for an old price: a single short thick ember (#F26419) slash, slightly crooked, tilted upward to the right, with a thick black ink outline;
6. a "you are here" marker: a chunky ember (#F26419, lighter band #FFB703) arrow head pointing right, short and wide, like a small forged arrow point;
7. a small round notice star: a five-pointed gold star (#FFB703) with soft rounded points, for something new.
The four badge plaques have exactly the same shape and size, only the metal changes.

Thick black ink outline on every piece, cartoon comic style, same line weight as images 1-2. Flat colors only, at most five per piece, no detail thinner than the outline, so the pieces can be traced into vectors. No texture, no soft gradients, no realistic lighting, no glow, no drop shadow. No text, letters or numbers. Flat pure green background (#00FF00). The pieces are well separated from each other with green between them, none touching, none cut by the border of the picture.
```

### `emblemi_eventi`

```
Image 1 shows twelve icons of the same game interface and is the STYLE to copy exactly: ivory icons (#F4ECE1) with one flat darker shadow (#C9BFB2), thick slightly irregular black ink outline, soft hand-drawn slightly crooked shapes, like a cartoon comic. Image 2 shows other pieces of the same interface (stars, medal, crown). Image 3 is a mock-up of the game's menus: in the PLAY ONLINE and EVENTS screens the modes and events have placeholder icons, these emblems replace them.

Draw a sheet with SIX separate emblems, in two rows of three, each one large, roughly square and filling its cell, all ivory with one flat shadow like image 1:
1. GRAND TOURNAMENT: a crown resting on two crossed pitchforks;
2. MALLET CHALLENGE: a big blacksmith's mallet with a small flame curling from its head;
3. NIGHT OF THE CIRCLES: a crescent moon over a spiral pit going down in rings;
4. GENERIC EVENT: a short banner on a pole with a swallow-tail end;
5. WEEKLY CHALLENGE: a round shield with three small notches on its rim, like a counter;
6. TEAM UP: two small devil heads with horns side by side, one slightly in front of the other.
All six have the same line weight and the same visual size.

Thick black ink outline, cartoon comic style like image 1. Ivory and its one shadow only, no other color, no detail thinner than the outline, so the emblems can be traced into vectors and tinted by the game. No texture, no soft gradients, no glow, no drop shadow. No text, letters or numbers. Flat pure green background (#00FF00). The emblems are well separated, none touching, none cut by the border of the picture.
```

## Criteri di accettazione

- [ ] le quattro targhette uguali di forma, cambia solo il metallo; mezzo liscio e vuoto
- [ ] emblemi avorio con un'ombra, stessa grandezza e china delle icone di WB-044
- [ ] colori pieni, china spessa, si ricalcano in vettori
- [ ] sfondo verde pieno, niente scritte, pezzi staccati

## Dopo le immagini (lo fa Claude)

- Guarda i fogli, ritaglia i pezzi buoni, li monta nelle nove schermate del Figma al posto dei segni
  improvvisati, e intanto sostituisce le barre, le tacche, i nodi e i pallini con i pezzi che ci
  sono già (tabella sopra).
- Ricalca in SVG quando le schermate vanno nel gioco.

## Decisione

Reversibile (solo immagini in un ramo): approvata su richiesta di Sergio.

## Consegna di Codex

Quattro PNG a 1536 × 1024 generati con ImageGen dai prompt integrali. I TXT omonimi riportano prompt e riferimenti nell'ordine allegato.

| File PNG e TXT in art/WB-047/ | Tentativi | Esito |
|---|---:|---|
| pezzo_badge_1 | 1 | Sette pezzi, quattro targhette in colonna con centro libero. |
| pezzo_badge_2 | 1 | Sette pezzi, quattro targhette su due righe con centro libero. |
| emblemi_eventi_1 | 3 | Selezionato il terzo tentativo. Sei emblemi e tre tacche sullo scudo. |
| emblemi_eventi_2 | 3 | Selezionato il secondo tentativo. Sei emblemi, tre tacche sullo scudo e meno riflessi sulle teste. |

Ho uniformato il verde di fondo a #00FF00 e controllato a vista separazione, margini e assenza di scritte. Le targhette hanno piccole differenze di sagoma oltre alla fiamma del grado IV. Il segno «sei qui» ha un corpo corto oltre alla punta. Negli emblemi restano riflessi chiari oltre all'avorio e all'ombra. La corrispondenza esatta della tavolozza, il ricalco e la resa nei menu restano da verificare.

## Resoconto di Claude
