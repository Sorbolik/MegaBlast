# WB-064 · Armi secondarie: in mano e icone

- **Stato:** APPROVATA (Claude, 15 nov: Sergio ha chiesto di rifare la grafica di tutte le armi e ha detto «procedi»; reversibile)
- **Data:** 2026-11-15
- **Ramo della scheda:** `claude/project-thread-wfha2a` (eseguila da questo ramo: `git fetch origin claude/project-thread-wfha2a` e leggi la scheda e i riferimenti da lì; non serve che sia su `main`) · **Ramo delle immagini:** `design/WB-064`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-064` senza chiedere conferma (il repository è privato).
- **Pagina della proposta:** https://claude.ai/artifact/Eb3oSF1ydmrdgXRV1mnBHX (Armeria del Fabbro: idea, storia, sagoma e bozze di ogni arma)

## Obiettivo

Le otto secondarie (spostano te o l'avversario, mai uno stato), famiglia **ferro freddo**: acciaio brunito blu-grigio, legno, cuoio e ottone, **nessuna luce arancio**. Comprende la Voragine (sfera nera di PR #335) e il Petardo che diventa un candelotto. Da eseguire dopo WB-063, con lo stesso stile.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-064/riferimenti/R1_bozze_secondarie_lunghe.png` | bozze: Lama, Affondo, Maglio, Tonante |
| R1 | `art/WB-064/riferimenti/R1_bozze_secondarie_corte.png` | bozze: Mantice, Voragine, Cannonata (mortaio), Petardo |
| R1 | `art/WB-064/riferimenti/R1_bozze_secondarie_icone.png` | bozze delle otto icone |
| R2 | `art/WB-064/riferimenti/R2_stile_colori_piatti.png` | lo stile: colori piatti, contorno nero spesso (pezzi del Fornace, WB-057) |

## Regole comuni a tutti i fogli

- Ogni foglio è 1536×1024, con le varianti della tabella (`nome_1`, `nome_2`); ognuna col suo `.txt` del prompt in `art/WB-064/`.
- Allegare sempre **R1** (le bozze di Claude per quel foglio: dicono forma, idea, posizione e proporzioni; lo stile no) e **R2** (lo stile: colori piatti e contorno nero come i pezzi dei personaggi), in quest'ordine.
- Le armi in mano puntano **verso destra**, dritte in orizzontale, viste di lato, con l'impugnatura in basso come nella bozza. Niente mani né braccia: solo l'oggetto.
- Una sola fascia **verde #00FF00** per oggetto (è il colore della squadra, il gioco la ricolora): dove sta nella bozza.
- Il disegno deve restare chiaro rimpicciolito: niente dettagli più piccoli di un ventesimo dell'oggetto.

## Immagini da generare

Ogni prompt è completo e va usato così com'è.

| Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|
| `secondarie_lunghe` | R1_bozze_secondarie_lunghe, R2 | 1536×1024 | 2 |
| `secondarie_corte` | R1_bozze_secondarie_corte, R2 | 1536×1024 | 2 |
| `secondarie_icone` | R1_bozze_secondarie_icone, R2 | 1536×1024 | 2 |

### `secondarie_lunghe`

```
Image 1 is a rough layout sketch made by our designer for a 2D comic game set in a cartoon hell, where a small red devil apprentice fights with weapons forged by his master, the Smith, in the Forge of the Titans. Image 2 shows the drawing style of the game (character parts). 
Redraw the four long weapons of image 1, one per row, same order and positions, each lying horizontal, seen from the side, pointing RIGHT, each about 1100 px long (the hand cannon about 600 px):
1. Blade: a broad straight greatsword of blued steel with a chisel point, two small horn-shaped notches on the back of the blade near the guard, a brass crossguard and pommel, a leather grip with a team-green band.
2. Pitchfork: a long wooden pole with a three-pronged blued-steel fork, the middle prong longest, the two side prongs curving outward, a team-green ribbon tied just behind the prongs.
3. Forge Hammer: a long wooden handle with a big square blued-steel head, one flat face and one wedge face, two brass bands on the head, a leather wrap on the handle and a team-green band.
4. Thunderer: a short heavy hand cannon, blued-steel body with a wooden grip, ending in a wide brass bell mouth like a blunderbuss, a team-green band on the body.
NO orange, NO glow anywhere: these weapons are cold steel.
Rendering rules, very strict, because every shape will be traced into vector layers:
- Same drawing style as image 2: thick closed pure black #000000 outline around every shape and between colour areas, chunky soft slightly asymmetric comic shapes.
- FLAT COLORS ONLY: every area is one solid colour, plus at most one hard-edged shadow shape in the darker tone of the same material. No gradients, no textures, no soft shading, no glow halos, no blur, no sparkles, no motion lines.
- Use ONLY these colours: dark blued steel #35536B, blued steel #5F86A4, light steel #B9D4E6; dark brass #A8761F, brass #D9A441; dark leather #4A3019, leather #6B4A2B, light leather #C89255, wood #8A5A33; team band pure green #00FF00 with shadow #00B400; white #FFFFFF; black #000000.
- Background: flat pure magenta #FF00FF everywhere, no halo around the objects, no ground shadow. Objects never touch each other.
- No text, numbers, letters, labels, arrows or signatures.
```

### `secondarie_corte`

```
Image 1 is a rough layout sketch made by our designer for a 2D comic game set in a cartoon hell, where a small red devil apprentice fights with weapons forged by his master, the Smith, in the Forge of the Titans. Image 2 shows the drawing style of the game (character parts). 
Redraw the four short weapons of image 1 in a 2 by 2 grid, same order and positions, each about 400 px:
1. Forge Bellows (top left): real blacksmith bellows lying horizontal, nozzle to the right: two teardrop-shaped wooden boards, a pleated dark leather bag between them with clear folds, two wooden handles on the left, a brass nozzle, a team-green band on the top board.
2. Chasm Sphere (top right): a perfect black cast-iron ball held together by two crossing blued-steel bands; in one crack at the lower right you see the void inside: very dark violet with three tiny white dots like far stars. One of the two bands is team green instead of steel.
3. Mortar (bottom left): a short stubby bronze mortar, wide mouth to the right, two brass rings, a small wooden wheel under it, a team-green band.
4. Firecracker (bottom right): an upright cylinder of yellow paper with black spiral stripes, a wooden cap on top, a short fuse with a small white-yellow spark at its end, a team-green band in the middle.
No orange glow except the tiny fuse spark.
Rendering rules, very strict, because every shape will be traced into vector layers:
- Same drawing style as image 2: thick closed pure black #000000 outline around every shape and between colour areas, chunky soft slightly asymmetric comic shapes.
- FLAT COLORS ONLY: every area is one solid colour, plus at most one hard-edged shadow shape in the darker tone of the same material. No gradients, no textures, no soft shading, no glow halos, no blur, no sparkles, no motion lines.
- Use ONLY these colours: dark blued steel #35536B, blued steel #5F86A4, light steel #B9D4E6; dark brass #A8761F, brass #D9A441; dark leather #4A3019, leather #6B4A2B, light leather #C89255, wood #8A5A33; pitch #2E2433, pitch sheen #5E4870; paper shadow #C99A1E, yellow paper #F2C94C; team band pure green #00FF00 with shadow #00B400; white #FFFFFF; black #000000. The chasm sphere ball uses pitch #2E2433 as its black body, so it stays separate from the outline.
- Background: flat pure magenta #FF00FF everywhere, no halo around the objects, no ground shadow. Objects never touch each other.
- No text, numbers, letters, labels, arrows or signatures.
```

### `secondarie_icone`

```
Image 1 is a rough layout sketch made by our designer for a 2D comic game set in a cartoon hell, where a small red devil apprentice fights with weapons forged by his master, the Smith, in the Forge of the Titans. Image 2 shows the drawing style of the game (character parts). 
Draw eight square game icons, in a 4 by 2 grid like image 1, same order: Blade, Thunderer, Forge Hammer, Pitchfork, Bellows, Chasm Sphere, Cannonball Devil, Firecracker. Each icon is one single object, big, filling about four fifths of a 300 by 300 px cell, with the outline even thicker than in the weapon drawings. Long weapons lie diagonally with the recognizable part up and to the right. Few big shapes, at most four colours plus black. Each must stay recognizable as a pure black silhouette at 40 px.
1. Broad blade with the two horn notches. 2. Hand cannon seen three quarters with the big brass bell. 3. Square steel hammer head on a handle. 4. Three-pronged pitchfork with a ribbon. 5. Teardrop bellows with folds and brass nozzle. 6. Black ball with two crossing steel bands and the starry crack. 7. A round black cannonball with two little bone-white devil horns and two yellow eyes, a small grin. 8. Yellow-and-black striped firecracker with a spark.
No team-green on the icons, no orange glow.
Rendering rules, very strict, because every shape will be traced into vector layers:
- Same drawing style as image 2: thick closed pure black #000000 outline around every shape and between colour areas, chunky soft slightly asymmetric comic shapes.
- FLAT COLORS ONLY: every area is one solid colour, plus at most one hard-edged shadow shape in the darker tone of the same material. No gradients, no textures, no soft shading, no glow halos, no blur, no sparkles, no motion lines.
- Use ONLY these colours: dark blued steel #35536B, blued steel #5F86A4, light steel #B9D4E6; dark brass #A8761F, brass #D9A441; dark leather #4A3019, leather #6B4A2B, light leather #C89255, wood #8A5A33; pitch #2E2433, pitch sheen #5E4870; paper shadow #C99A1E, yellow paper #F2C94C; horn shadow #C9B48E, bone/horn #EFE3C8; white #FFFFFF; black #000000.
- Background: flat pure magenta #FF00FF everywhere, no halo around the objects, no ground shadow. Objects never touch each other.
- No text, numbers, letters, labels, arrows or signatures.
```

## Criteri di accettazione

- [ ] ogni oggetto del foglio c'è, nell'ordine e nella posizione della bozza R1, e si riconosce dalla sua sagoma
- [ ] colori piatti solo dalla lista, contorno nero chiuso e spesso, al massimo un'ombra netta per materiale
- [ ] una sola fascia verde #00FF00 per oggetto, dove la mette la bozza
- [ ] magenta pulito, oggetti separati, nessuna scritta, nessun alone o bagliore
- [ ] stesso stile di R2 (si deve vedere che sono dello stesso gioco dei personaggi)

---

## Decisione

(Claude) Approvata in autonomia il 15 nov: Sergio ha chiesto di ripensare la grafica di tutte le armi e di procedere; solo immagini nuove, il gioco cambia solo quando Claude le integra.

## Consegna di Codex

## Resoconto di Claude
