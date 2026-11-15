# WB-065 · Oggetti: Rampino, Giano, Teletrasporto, paracadute, Molla, trappola, scudo

- **Stato:** APPROVATA (Claude, 15 nov: Sergio ha chiesto di rifare la grafica di tutte le armi e ha detto «procedi»; reversibile)
- **Data:** 2026-11-15
- **Ramo della scheda:** `claude/project-thread-wfha2a` (eseguila da questo ramo: `git fetch origin claude/project-thread-wfha2a` e leggi la scheda e i riferimenti da lì; non serve che sia su `main`) · **Ramo delle immagini:** `design/WB-065`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-065` senza chiedere conferma (il repository è privato).
- **Pagina della proposta:** https://claude.ai/artifact/Eb3oSF1ydmrdgXRV1mnBHX (Armeria del Fabbro: idea, storia, sagoma e bozze di ogni arma)

## Obiettivo

Gli oggetti (non sono attacchi), famiglia **ottone e corda**; il viola solo per il Teletrasporto. Pezzi in gioco e icone dei pulsanti. Il simbolo del baratto resta a vettori e non è qui.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-065/riferimenti/R1_bozze_oggetti_pezzi.png` | bozze: Rampino, Giano, globo d'ombra, paracadute, Molla, tagliola, scudo |
| R1 | `art/WB-065/riferimenti/R1_bozze_oggetti_icone.png` | bozze delle sette icone |
| R2 | `art/WB-065/riferimenti/R2_stile_colori_piatti.png` | lo stile: colori piatti, contorno nero spesso (pezzi del Fornace, WB-057) |

## Regole comuni a tutti i fogli

- Ogni foglio è 1536×1024, con le varianti della tabella (`nome_1`, `nome_2`); ognuna col suo `.txt` del prompt in `art/WB-065/`.
- Allegare sempre **R1** (le bozze di Claude per quel foglio: dicono forma, idea, posizione e proporzioni; lo stile no) e **R2** (lo stile: colori piatti e contorno nero come i pezzi dei personaggi), in quest'ordine.
- Le armi in mano puntano **verso destra**, dritte in orizzontale, viste di lato, con l'impugnatura in basso come nella bozza. Niente mani né braccia: solo l'oggetto.
- Una sola fascia **verde #00FF00** per oggetto (è il colore della squadra, il gioco la ricolora): dove sta nella bozza.
- Il disegno deve restare chiaro rimpicciolito: niente dettagli più piccoli di un ventesimo dell'oggetto.

## Immagini da generare

Ogni prompt è completo e va usato così com'è.

| Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|
| `oggetti_pezzi` | R1_bozze_oggetti_pezzi, R2 | 1536×1024 | 2 |
| `oggetti_icone` | R1_bozze_oggetti_icone, R2 | 1536×1024 | 2 |

### `oggetti_pezzi`

```
Image 1 is a rough layout sketch made by our designer for a 2D comic game set in a cartoon hell, where a small red devil apprentice fights with weapons forged by his master, the Smith, in the Forge of the Titans. Image 2 shows the drawing style of the game (character parts). 
Redraw the objects of image 1 in a 3 by 3 grid, same order and positions, each about 300 px:
1. Grappling crossbow: a small brass hand crossbow pointing right with a wooden grip and a rope spool, loaded with a light-iron four-pronged grappling hook; a team-green band on the body. Also draw, in the last free cell at the bottom right, the grappling hook alone with a short piece of hemp rope.
2. Janus coin: a big brass coin seen from the front, split vertically: left half gold with an engraved profile looking left, right half team green with an engraved profile looking right, the two faces back to back.
3. Shadow globe: a violet glass globe with a small dark shadow devil inside (round head, two little horns, two yellow eyes).
4. Bat-wing parachute: an umbrella-like canopy made of three pointed bat wings sewn together in dark leather, ribs visible, three thin cords meeting at a hooked wooden handle, a team-green band on the canopy.
5. Spring: a big dark-iron zig-zag spring between a wooden base and a brass top plate, a small team-green triangle on top of the plate.
6. Bear trap: an open iron jaw trap seen three quarters from the front, two half-moon jaws with sharp light-iron teeth, a brass pivot in the middle.
7. Round shield: a round wooden shield with a thick dark-iron rim and four brass rivets, a dark-iron anvil emblem in the middle, a team-green band above the anvil.
Rendering rules, very strict, because every shape will be traced into vector layers:
- Same drawing style as image 2: thick closed pure black #000000 outline around every shape and between colour areas, chunky soft slightly asymmetric comic shapes.
- FLAT COLORS ONLY: every area is one solid colour, plus at most one hard-edged shadow shape in the darker tone of the same material. No gradients, no textures, no soft shading, no glow halos, no blur, no sparkles, no motion lines.
- Use ONLY these colours: dark iron #3B404B, iron #59606E, light iron #8F98A8; dark brass #A8761F, brass #D9A441; dark leather #4A3019, leather #6B4A2B, light leather #C89255, wood #8A5A33; dark violet #4B2D8A, violet #9466EA, pale violet #DCC8FF; team band pure green #00FF00 with shadow #00B400; white #FFFFFF; black #000000. The shadow devil inside the globe uses pitch #2E2433.
- Background: flat pure magenta #FF00FF everywhere, no halo around the objects, no ground shadow. Objects never touch each other.
- No text, numbers, letters, labels, arrows or signatures.
```

### `oggetti_icone`

```
Image 1 is a rough layout sketch made by our designer for a 2D comic game set in a cartoon hell, where a small red devil apprentice fights with weapons forged by his master, the Smith, in the Forge of the Titans. Image 2 shows the drawing style of the game (character parts). 
Draw seven square game icons in a 4 by 2 grid like image 1 (the last cell stays empty magenta), same order: Grappling hook, Janus coin, Shadow globe, Bat-wing parachute, Spring, Bear trap, Shield. Each icon is one single object, big, filling about four fifths of a 300 by 300 px cell, with the outline even thicker than in the object drawings. Few big shapes, at most four colours plus black. Each must stay recognizable as a pure black silhouette at 40 px.
1. Four-pronged hook with a coil of rope below. 2. Two-faced coin, gold half and red half (use #E5484D for the red half on the icon). 3. Violet globe with the shadow devil and yellow eyes. 4. Open bat-wing umbrella with cords. 5. Zig-zag spring between wood and brass, small arrow-triangle on top. 6. Open jaw trap. 7. Round wooden shield with the anvil.
Rendering rules, very strict, because every shape will be traced into vector layers:
- Same drawing style as image 2: thick closed pure black #000000 outline around every shape and between colour areas, chunky soft slightly asymmetric comic shapes.
- FLAT COLORS ONLY: every area is one solid colour, plus at most one hard-edged shadow shape in the darker tone of the same material. No gradients, no textures, no soft shading, no glow halos, no blur, no sparkles, no motion lines.
- Use ONLY these colours: dark iron #3B404B, iron #59606E, light iron #8F98A8; dark brass #A8761F, brass #D9A441; dark leather #4A3019, leather #6B4A2B, light leather #C89255, wood #8A5A33; dark violet #4B2D8A, violet #9466EA, pale violet #DCC8FF; white #FFFFFF; black #000000. Only for the coin icon also red #E5484D.
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

Generati con `image_gen` dal ramo della scheda (`1a1e172d`). Ogni PNG è
affiancato dal TXT con prompt integrale e riferimenti in ordine.

| PNG e TXT in `art/WB-065/` | Tentativi | Selezione | Dimensioni |
|---|---:|---:|---:|
| `oggetti_icone_1` | 3 | 2 | 1536×1024 |
| `oggetti_icone_2` | 3 | 3 | 1536×1024 |
| `oggetti_pezzi_1` | 3 | 1 | 1536×1024 |
| `oggetti_pezzi_2` | 3 | 2 | 1536×1024 |

Controllati otto pezzi per foglio (sette oggetti e il rampino sciolto), sette\nicone, ordine, contorni, fasce verdi dove previste e separazione. Dopo tre\ntentativi per variante il rampino mostra ancora tre punte visibili. Scelti\ni tentativi con i pezzi più leggibili: nella seconda variante dei pezzi si\nvedono entrambe le ganasce dentate. Leggibilità a 40 px non provata.

Magenta opaco, diverso da #FF00FF negli angoli campionati. Conservati i PNG
originali. Corrispondenza esatta della palette, ricalco e resa in gioco
restano da verificare.

## Resoconto di Claude
