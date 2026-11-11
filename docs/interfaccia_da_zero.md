# Interfaccia «Raggi» (10-11 nov)

L'interfaccia dei menu ridisegnata da zero e approvata da Sergio sul Figma («implementa
tutto il figma che mi hai proposto»; sulla home: «ok mi piace»). **È nel gioco**: questo
file dice com'è fatta e cosa manca.

- Figma «MegaBlast · Interfaccia», pagina 3, tavolozza INFERNO:
  https://www.figma.com/design/i7CjXyRO8X6NQOk7ntONZh
- Lavagna FigJam con la mappa dei menu: https://www.figma.com/board/IZ5dnV76izRNgRs9SJFUF5

## Le regole (Sergio)

1. **Home con poche porte.** GIOCA (solo online), ALLENAMENTO (quello che si gioca senza
   rete: contro i bot e stesso telefono), CAMPAGNA, EVENTI, il diavoletto, l'ingranaggio.
2. **Un solo posto per il diavoletto**: pezzi, sigilli, statistiche e partite insieme.
3. **Una sola azione principale per schermata**, gialla, da sola in basso a destra. Un
   bottone non cambia mai scopo.
4. **Ogni menu ha il suo colore** (l'accento della scena e del titolo).
5. **Testata**: il titolo scritto come il logo in alto a sinistra; il ritorno è una piastra
   in basso a sinistra, con scritto sotto dove porta.
6. I regolatori (più e meno, frecce) sono tondi. Una stella sola non sta mai in un riquadro.
7. **L'HUD in partita resta quello di prima**: non si ridisegna.
8. La campagna è la bacheca fino al rapimento di Favilla; dopo diventerà la mappa a imbuto
   (vedi «Cosa manca»).

## Com'è fatta

Dietro c'è il mondo del gioco scurito, i raggi che partono dal diavoletto, la cucitura di
brace in basso e le scintille (`kit.scene`). Sopra, piastre a parallelogramma con l'ombra
piena spostata: scure per i bottoni, color sabbia per i nomi, gialla e luminosa per l'azione.

Tutto passa da `client/ui/kit.lua`, che si usa con le coordinate del Figma (1280 x 720, y
dall'alto, testo sulla linea di base):

| Pezzo | Funzione |
|---|---|
| Scena (velo, raggi, alone, cucitura, scintille) | `kit.scene`, `kit.scene_show` |
| Titolo e ritorno | `kit.header`, `kit.title` |
| Piastra scura, piastra sabbia | `kit.plate`, `kit.sand` |
| Azione principale | `kit.action` |
| Carta, carta con l'immagine, immagine inclinata | `kit.card`, `kit.card_picture`, `kit.picture` |
| Scelta fra poche voci, schede | `kit.choice`, `kit.tabs` |
| Riga d'informazione, etichetta | `kit.info`, `kit.label` |
| Avanzamento | `kit.pips`, `kit.bar` |
| Regolatore tondo, più e meno | `kit.round`, `kit.stepper` |
| Entrate | `kit.arrive`, `kit.pop` (mai su un testo: si fa sul nodo che lo tiene) |

I colori sono in `kit.C`. Quello che sta su un bordo si attacca con `kit.anchor` al bordo
vero dello schermo; il resto sta nei 1280 al centro. Niente si deforma.

Una schermata è fatta così: fondo pieno (`backdrop.new()`), scena col suo accento, un gruppo
al centro e due ancore in basso (sinistra per il ritorno e le secondarie, destra per
l'azione). I figli si disegnano col padre: quello che deve stare sopra la scena è un nodo a
parte, non un figlio del velo.

## Schermate fatte

Home, IL TUO DIAVOLETTO (pezzi, sigilli, statistiche, partite), campagna (bacheca, e la mappa a imbuto
dopo il rapimento), cartolina della missione, storia, allenamento, GIOCA ONLINE, sala d'attesa, schieramento,
scelta delle armi, podio, fine del livello, impostazioni, scatto del pezzo, portafoglio.

## Cosa manca

- **I gironi veri**: la mappa a imbuto c'è (dopo il rapimento: Cortile e Forgia in alto, sotto i
  nove gironi), ma i gironi sono segnaposto: nomi e custodi in `client/lang/it.lua`
  (`campaign.rings`), cinque livelli e il custode ciascuno, tutti IN ARRIVO. Quando un girone
  entra in `client/sim/levels.lua` il suo anello prende i livelli veri. In alto, al posto dei
  disegni dei luoghi, ci sono le miniature delle missioni: i disegni vanno chiesti a Codex.
- Sfondo della home: deciso, il mondo del livello in vista e i raggi solo un accenno
  (`kit.scene` con `world`; Sergio, 11 nov).
- Il cartellino grande (si apre toccando quello piccolo) e la pillola della coda hanno
  ancora le forme di prima.
- PRONTO nella scelta delle armi online è solo uno stato: il server non ha ancora il «pronto».
- Nome del giocatore e serie di vittorie: nel Figma ci sono, i dati nel gioco no.
- Misure da desktop: per ora una serie sola, quella da telefono.
