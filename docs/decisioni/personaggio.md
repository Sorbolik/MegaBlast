# Il personaggio: storia, decisioni, strumenti scartati

Stato attuale (28 ott): **diavoletto vettoriale** disegnato da
`strumenti/grafica/diavoletto.py` e animato in codice in
`client/battaglia/scoria.lua` (molle + clip dell'**editor delle animazioni**),
con **skin sullo stampino** (`strumenti/stampino/`, `client/battaglia/pelli.lua`).
Editor: https://claude.ai/artifact/YJeMenvfJLGmto89yAbKJ5 e come Worker
Cloudflare dal main.

## La storia in breve

1. **19–20 ott, le Scorie.** Direzione artistica D scelta da Sergio:
   creature di carbone con un occhio, nate dai Titani caduti; corpo tozzo e
   panciuto, pezzi ritagliati da immagini AI animati con molle in Lua. Rig in
   `scoria.lua` (PR #11).
2. **22 ott, personaggio v2** (aviario con maschera d'osso e gambe, da fogli di
   pezzi di Sergio): bocciato la sera stessa ("sembra monnezza": troppo alto,
   ginocchia complicate, presa innaturale, hitbox metà altezza). Sergio: basta
   improvvisare, prima si studia.
3. **22–23 ott, metodo a fasi** (doc "come si fa un personaggio vivo",
   https://claude.ai/artifact/9oaeQUqzevvVqXKs97HqNk): pilastri approvati
   (leggibile a colpo d'occhio sul telefono / ogni colpo si sente / poco ma con
   carattere), riferimenti Hollow Knight (forma e movimento), Lair of the
   Clockwork God (impatto dei colpi), Celeste (feel). Greybox a capsula
   (PR #25, vecchio rig cancellato), sagome vettoriali: scelta **Corona del
   Titano** con corna invertite e mantello corto, corpo ×1,4, game feel
   (hit-stop, shake, detriti), PR #26 mergiata.
4. **24–25 ott, il diavoletto di Gabriella** (vedi [designer.md](designer.md)):
   disegnato da lei, rifatto con ChatGPT, provati pezzi staccati, frame
   ChatGPT, video AI (Firefly ok, Ludo peggio), Ludo Indie, pixel art
   (PR #43). Circa 500 immagini, 4 buone: esasperazione. Ricerche su ossa
   (Spine consigliato, DragonBones solo come editor) e motori (restare su
   Defold).
5. **26 ott, "Dare il mio stile al pupazzetto di main"**: Sergio applica i suoi
   pezzi (ChatGPT: testa con occhiali, busto, gamba, fiammella) al diavoletto
   procedurale di main; coda a 5 segmenti con ritardo; fiamma = colore squadra
   e indicatore del turno; poi fogli Ludo per corsa, mira, salto, colpito,
   vittoria, teletrasporto, sconfitta; lampo bianco quando colpito; corsa solo
   quando ci si muove da soli; dimensione del corpo ×1,4 svincolata da tutto il
   resto. PR #44 mergiata con le mappe ×1,5.
6. **26 ott sera, "mi arrendo"**: ogni asset generato è una brutta copia delle
   armi disegnate in codice. Il diavoletto viene rifatto **tutto vettoriale**
   con la tecnologia delle armi (SVG → PNG, contorno nero spesso), pezzi
   ritagliati attorno al perno, animato in codice; fogli Ludo rimossi (4,9 MB →
   220 KB). Braccia a 2 ossa con IK (i tubi dritti erano "che schifo"), fiamma
   indicatore del turno, freccia tolta; paracadute e cerchio di cura nello
   stesso stile. PR #54, mergiata da Sergio il 28 ott.
7. **27–28 ott, editor delle animazioni** (invece di pagare Spine o cambiare
   motore): pagina web nostra, clip con tracce e curve, salvate in
   `client/battaglia/animazioni.lua`; edita anche hitbox e perni; **stampino**
   per disegnare skin (categorie sostituisci: personaggio, testa, corpo, ali,
   coda; sovrapponi: pantaloni, maglia, corazza, guanti, elmo), verde #00ff00
   = colore squadra; `taglia.py --allinea` monta pezzi liberi dai fogli
   ChatGPT. Prime skin: `gabriella`, `gabriella_squadra` (scheda WB-001 via
   Codex). PR #55 mergiata il 28 ott; Worker Cloudflare per usarlo dal
   telefono.

## Decisioni prese (quelle ancora valide)

| Data | Decisione | Dove |
|---|---|---|
| 23 ott | I 3 pilastri e i 3 riferimenti sopra. | doc personaggio vivo |
| 23 ott | Camera vicina con dezoom (livelli 2,2 / 1,5 / 1), sfondo procedurale invece di quello dipinto. | PR #25 |
| 26 ott | Corpo ×1,4 (`BLASTRON_CORPO`), tutto il resto (mondo, armi, casse, proiettili, mani, camera) alle dimensioni di main. Mappe più piccole in futuro. | PR #44 |
| 26 ott | Fiamma sopra la testa = colore della squadra, più grande e luminosa a chi è di turno; occhi disegnati sulla testa, niente Nucleo. Lampo bianco quando colpito. Corsa solo per movimento proprio. La mira vince su ogni animazione tranne la sconfitta. | PR #44 |
| 26 ott | Personaggio **vettoriale** disegnato da script, contorno nero puro, animato in codice; niente fogli di frame. | PR #54 |
| 26 ott | Braccia IK a 2 ossa: mano davanti sulla canna, mano dietro sull'impugnatura. | PR #54 |
| 28 ott | Editor nostro + stampino per le skin; hitbox e perni modificabili; **il diavoletto di Gabriella torna come skin "personaggio"** con contorno nero spesso. | PR #55 |
| 28 ott | Dimensione del disegno svincolata dalla fisica (`game.DISEGNO_H`). | PR #55 |
| 29 ott | L'editor entra nel pannello di Sergio come micro-frontend e avrà un connettore per i pezzi dello stampino (aggiungere/togliere pezzi a animazioni, personaggi, armi, skin). | docs/roadmap.md |

## Scartate, con il motivo

| Cosa | Perché |
|---|---|
| Spine (Essential 99 $, Pro ~370 €) | Essential senza mesh e IK; runtime in più; con l'editor nostro non serve (25–27 ott). Resta il piano B se servisse deformazione premium. |
| DragonBones | Editor fermo dal 2018, animazioni per armatura non condivise (Sergio l'ha visto, 25 ott), estensione Defold non testata su mobile. |
| Rive, Spriter, Creature, Live2D, Moho | Rive richiede GL 4.2+ e abbonamento; gli altri stantii o senza Defold. |
| Fogli di frame (ChatGPT, Ludo, video AI) | Deriva tra i frame, pesanti (fino a 15 MB di atlas), non reagiscono al gioco, code tagliate dal bordo; Sergio ha rinunciato il 26 ott. |
| Pixel art (PR #43) | Messa da parte: stile misto con mappe e UI, resa sfocata finché non si è fissato il filtro. |
| Pezzi staccati fluttuanti stile Blastron | Provati con Gabriella, tornata al diavoletto con le gambe. |
| Diavoletto senza braccia + braccia da AI | Prospettive sbagliate, spalle strappate; fermato dal coordinatore e da Sergio (25 ott). |
| Braccia a tubo dritto nella mira | "Che schifo" (26 ott): sostituite da IK. |
| Versione a colori piatti automatica dei pezzi dipinti | Chiazze; lo stile piatto deve venire dalla fonte. |
| Strato di contorno unico sull'immagine intera | Contorno cotto per pezzo; solo la coda usa una catena di bordi separata. |
| Corpo ×2 (`ROBOT_H` 56) | Scalava tutto il mondo; Sergio l'ha ribaltato lo stesso giorno. |
| Cambiare motore per avere editor migliori (Godot, Unity) | Vedi architettura.md: si resta su Defold. |

## Aperte

- Sergio ha "molte altre correzioni al personaggio da descrivere" (26 ott):
  non ancora arrivate.
- Quanto può spingersi il vettoriale: tutto ciò che è piatto con gradienti
  semplici, niente texture pittoriche (risposta data, 26 ott).
- Arma in mano dentro l'editor: non ancora.
