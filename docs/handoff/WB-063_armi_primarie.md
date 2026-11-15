# WB-063 · Armi primarie: in mano, colpi e icone

- **Stato:** APPROVATA (Claude, 15 nov: Sergio ha chiesto di rifare la grafica di tutte le armi e ha detto «procedi»; reversibile)
- **Data:** 2026-11-15
- **Ramo della scheda:** `claude/project-thread-wfha2a` (eseguila da questo ramo: `git fetch origin claude/project-thread-wfha2a` e leggi la scheda e i riferimenti da lì; non serve che sia su `main`) · **Ramo delle immagini:** `design/WB-063`
- **Autorizzato:** pubblica PNG, prompt e scheda sul ramo `design/WB-063` senza chiedere conferma (il repository è privato).
- **Pagina della proposta:** https://claude.ai/artifact/Eb3oSF1ydmrdgXRV1mnBHX (Armeria del Fabbro: idea, storia, sagoma e bozze di ogni arma)

## Obiettivo

Rifare a mano le otto armi primarie (danno e stato), oggi disegnate a codice e tutte simili: in mano, i loro colpi e le icone. Famiglia **brace**: ferro scuro, pietra, corno e terracotta, con sempre un punto arancio acceso. Claude ricalca i fogli a vettori con `tools/stampino/tavolozze/armi.json` e li monta al posto delle armi di oggi. Prima scheda delle quattro (WB-063…066): fa da prova di stile.

## Riferimenti da allegare

| Codice | File | Cos'è |
|---|---|---|
| R1 | `art/WB-063/riferimenti/R1_bozze_primarie_lunghe.png` | bozze: Lanciarune, Cecchino, Trapano, Sciame di Schegge |
| R1 | `art/WB-063/riferimenti/R1_bozze_primarie_corte.png` | bozze: Uovo di Fiamma, Pugno del Titano, Falcetto, Pozza di Pece |
| R1 | `art/WB-063/riferimenti/R1_bozze_primarie_colpi.png` | bozze dei colpi: pietra-runa, goccia fusa, scheggia, uovo a tre stadi di crepe |
| R1 | `art/WB-063/riferimenti/R1_bozze_primarie_icone.png` | bozze delle otto icone |
| R2 | `art/WB-063/riferimenti/R2_stile_colori_piatti.png` | lo stile: colori piatti, contorno nero spesso (pezzi del Fornace, WB-057) |

## Regole comuni a tutti i fogli

- Ogni foglio è 1536×1024, con le varianti della tabella (`nome_1`, `nome_2`); ognuna col suo `.txt` del prompt in `art/WB-063/`.
- Allegare sempre **R1** (le bozze di Claude per quel foglio: dicono forma, idea, posizione e proporzioni; lo stile no) e **R2** (lo stile: colori piatti e contorno nero come i pezzi dei personaggi), in quest'ordine.
- Le armi in mano puntano **verso destra**, dritte in orizzontale, viste di lato, con l'impugnatura in basso come nella bozza. Niente mani né braccia: solo l'oggetto.
- Una sola fascia **verde #00FF00** per oggetto (è il colore della squadra, il gioco la ricolora): dove sta nella bozza.
- Il disegno deve restare chiaro rimpicciolito: niente dettagli più piccoli di un ventesimo dell'oggetto.

## Immagini da generare

Ogni prompt è completo e va usato così com'è.

| Nome file | Riferimenti | Misura | Varianti |
|---|---|---|---|
| `primarie_lunghe` | R1_bozze_primarie_lunghe, R2 | 1536×1024 | 2 |
| `primarie_corte` | R1_bozze_primarie_corte, R2 | 1536×1024 | 2 |
| `primarie_colpi` | R1_bozze_primarie_colpi, R2 | 1536×1024 | 2 |
| `primarie_icone` | R1_bozze_primarie_icone, R2 | 1536×1024 | 2 |

### `primarie_lunghe`

```
Image 1 is a rough layout sketch made by our designer for a 2D comic game set in a cartoon hell, where a small red devil apprentice fights with weapons forged by his master, the Smith, in the Forge of the Titans. Image 2 shows the drawing style of the game (character parts). 
Redraw the four long weapons of image 1, one per row, in the same order and positions, each lying horizontal, seen from the side, pointing RIGHT, each about 1100 px long (the drill and the shard thrower can be shorter, about 800 px):
1. Rune Launcher: a short thick dark-iron tube with two brass bands, a small grip under it, a team-green band on the tube, ending in the head of a horned gargoyle with its mouth wide open toward the right; inside the mouth sits a glowing orange carved stone. The gargoyle has two curved bone-white horns like a little devil and small yellow eyes.
2. The Long One (sniper): the longest and thinnest gun, a slim dark-iron barrel, a curved white horn stock on the left, a brass scope shaped like a round yellow eye on top, a small wooden grip, a thin team-green band on the barrel.
3. Drill: a twisted ram's horn shaped like a long spiral cone pointing right, bone-white with darker spiral grooves, a brass tip, mounted on a brass collar and a wooden handle with a crank grip, a team-green band on the handle.
4. The Hedgehog (shard thrower): a round dark-iron drum with nail spikes on top, three short iron barrels fanning out to the right with glowing orange muzzles, a wooden stock on the left, a small crank under the drum, a team-green band on the stock.
Rendering rules, very strict, because every shape will be traced into vector layers:
- Same drawing style as image 2: thick closed pure black #000000 outline around every shape and between colour areas, chunky soft slightly asymmetric comic shapes.
- FLAT COLORS ONLY: every area is one solid colour, plus at most one hard-edged shadow shape in the darker tone of the same material. No gradients, no textures, no soft shading, no glow halos, no blur, no sparkles, no motion lines.
- Use ONLY these colours: dark iron #3B404B, iron #59606E, light iron #8F98A8; dark brass #A8761F, brass #D9A441; dark leather #4A3019, leather #6B4A2B, light leather #C89255, wood #8A5A33; horn shadow #C9B48E, bone/horn #EFE3C8; dark ember #C2410C, ember orange #FF7A1A, hot yellow #FFD15A; team band pure green #00FF00 with shadow #00B400; white #FFFFFF; black #000000.
- Background: flat pure magenta #FF00FF everywhere, no halo around the objects, no ground shadow. Objects never touch each other.
- No text, numbers, letters, labels, arrows or signatures.
```

### `primarie_corte`

```
Image 1 is a rough layout sketch made by our designer for a 2D comic game set in a cartoon hell, where a small red devil apprentice fights with weapons forged by his master, the Smith, in the Forge of the Titans. Image 2 shows the drawing style of the game (character parts). 
Redraw the four short weapons of image 1 in a 2 by 2 grid, same order and positions, each about 400 px tall:
1. Fire Egg (top left): a black cast-iron dragon egg, upright, wider at the bottom, with zig-zag cracks glowing orange and a small flame coming out of the top crack; a team-green band around its belly.
2. Titan Fist (top right): a huge closed fist of pale cracked stone, knuckles to the right, thumb visible, one glowing orange crack on the knuckles, worn like a glove over a short dark-iron cuff with a team-green band.
3. Sickle (bottom left): a crescent-moon sickle of black iron with a glowing orange cutting edge on the inside of the curve, a short wooden handle, a brass ring at the end of the handle, a team-green band on the handle.
4. Pitch Amphora (bottom right): a round-bellied terracotta amphora with two small handles, a narrow neck closed by a pale wax plug, black pitch dripping down from the neck over the belly, a team-green band around the belly.
Rendering rules, very strict, because every shape will be traced into vector layers:
- Same drawing style as image 2: thick closed pure black #000000 outline around every shape and between colour areas, chunky soft slightly asymmetric comic shapes.
- FLAT COLORS ONLY: every area is one solid colour, plus at most one hard-edged shadow shape in the darker tone of the same material. No gradients, no textures, no soft shading, no glow halos, no blur, no sparkles, no motion lines.
- Use ONLY these colours: dark iron #3B404B, iron #59606E, light iron #8F98A8; dark brass #A8761F, brass #D9A441; dark leather #4A3019, leather #6B4A2B, light leather #C89255, wood #8A5A33; horn shadow #C9B48E, bone/horn #EFE3C8; pitch #2E2433, pitch sheen #5E4870; dark terracotta #9C4A26, terracotta #C8693A; dark ember #C2410C, ember orange #FF7A1A, hot yellow #FFD15A; team band pure green #00FF00 with shadow #00B400; white #FFFFFF; black #000000.
- Background: flat pure magenta #FF00FF everywhere, no halo around the objects, no ground shadow. Objects never touch each other.
- No text, numbers, letters, labels, arrows or signatures.
```

### `primarie_colpi`

```
Image 1 is a rough layout sketch made by our designer for a 2D comic game set in a cartoon hell, where a small red devil apprentice fights with weapons forged by his master, the Smith, in the Forge of the Titans. Image 2 shows the drawing style of the game (character parts). 
Redraw the six flying shots of image 1 in a 3 by 2 grid, same order and positions, each about 300 px wide:
1. Rune stone: a flat six-sided dark stone with a simple carved angular rune sign (not a letter) glowing orange in the middle, a team-green band along the lower edge.
2. Molten drop: a round blob of molten metal, ember orange with a hard-edged hot yellow highlight at the top left, a small team-green band at the bottom.
3. Shard: a thin iron splinter three times longer than wide, pointing right, with a glowing orange tip.
4-6. Fire egg in three stages: the same black cast-iron egg with a small flame on top; stage 1 has one short orange crack, stage 2 has a long zig-zag crack, stage 3 is covered in glowing cracks.
Rendering rules, very strict, because every shape will be traced into vector layers:
- Same drawing style as image 2: thick closed pure black #000000 outline around every shape and between colour areas, chunky soft slightly asymmetric comic shapes.
- FLAT COLORS ONLY: every area is one solid colour, plus at most one hard-edged shadow shape in the darker tone of the same material. No gradients, no textures, no soft shading, no glow halos, no blur, no sparkles, no motion lines.
- Use ONLY these colours: dark iron #3B404B, iron #59606E, light iron #8F98A8; horn shadow #C9B48E, bone/horn #EFE3C8; pitch #2E2433, pitch sheen #5E4870; dark ember #C2410C, ember orange #FF7A1A, hot yellow #FFD15A; team band pure green #00FF00 with shadow #00B400; white #FFFFFF; black #000000.
- Background: flat pure magenta #FF00FF everywhere, no halo around the objects, no ground shadow. Objects never touch each other.
- No text, numbers, letters, labels, arrows or signatures.
```

### `primarie_icone`

```
Image 1 is a rough layout sketch made by our designer for a 2D comic game set in a cartoon hell, where a small red devil apprentice fights with weapons forged by his master, the Smith, in the Forge of the Titans. Image 2 shows the drawing style of the game (character parts). 
Draw eight square game icons, in a 4 by 2 grid like image 1, same order: Rune Launcher, Fire Egg, Shard Thrower, Titan Fist, Long Sniper, Sickle, Pitch Amphora, Horn Drill. Each icon is one single object, big, filling about four fifths of a 300 by 300 px cell, with the outline even thicker than in the weapon drawings. Long weapons lie diagonally with the recognizable part up and to the right. Keep each icon as simple as in image 1: few big shapes, at most four colours plus black, no detail smaller than a twentieth of the icon. Each icon must stay recognizable as a pure black silhouette at 40 px.
1. Gargoyle head with horns, mouth open, glowing rune inside, the tube going down-left. 2. Black egg with glowing cracks and a flame. 3. Round spiked drum with three glowing barrels. 4. Stone fist, knuckles up, one orange crack. 5. Long thin gun with the yellow eye scope. 6. Crescent sickle with orange edge and brass ring. 7. Terracotta amphora with black pitch dripping. 8. Spiral horn drill with brass tip.
No team-green on the icons.
Rendering rules, very strict, because every shape will be traced into vector layers:
- Same drawing style as image 2: thick closed pure black #000000 outline around every shape and between colour areas, chunky soft slightly asymmetric comic shapes.
- FLAT COLORS ONLY: every area is one solid colour, plus at most one hard-edged shadow shape in the darker tone of the same material. No gradients, no textures, no soft shading, no glow halos, no blur, no sparkles, no motion lines.
- Use ONLY these colours: dark iron #3B404B, iron #59606E, light iron #8F98A8; dark brass #A8761F, brass #D9A441; dark leather #4A3019, leather #6B4A2B, light leather #C89255, wood #8A5A33; horn shadow #C9B48E, bone/horn #EFE3C8; pitch #2E2433, pitch sheen #5E4870; dark terracotta #9C4A26, terracotta #C8693A; dark ember #C2410C, ember orange #FF7A1A, hot yellow #FFD15A; white #FFFFFF; black #000000.
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
