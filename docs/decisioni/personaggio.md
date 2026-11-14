# Il personaggio: storia, decisioni, strumenti scartati

Stato attuale (28 ott): **diavoletto vettoriale** disegnato da
`tools/grafica/diavoletto.py` e animato in codice in
`client/battle/scoria.lua` (molle + clip dell'**editor delle animazioni**),
con **skin sullo stampino** (`tools/stampino/`, `client/battle/skins.lua`).
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
   `client/battle/animations.lua`; edita anche hitbox e perni; **stampino**
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
| 26 ott | Corpo ×1,4 (oggi `game.CORPO`), tutto il resto (mondo, armi, casse, proiettili, mani, camera) alle dimensioni di main. Mappe più piccole in futuro. | PR #44 |
| 26 ott | Fiamma sopra la testa = colore della squadra, più grande e luminosa a chi è di turno; occhi disegnati sulla testa, niente Nucleo. Lampo bianco quando colpito. Corsa solo per movimento proprio. La mira vince su ogni animazione tranne la sconfitta. | PR #44 |
| 26 ott | Personaggio **vettoriale** disegnato da script, contorno nero puro, animato in codice; niente fogli di frame. | PR #54 |
| 26 ott | Braccia IK a 2 ossa: mano davanti sulla canna, mano dietro sull'impugnatura. | PR #54 |
| 28 ott | Editor nostro + stampino per le skin; hitbox e perni modificabili; **il diavoletto di Gabriella torna come skin "personaggio"** con contorno nero spesso. | PR #55 |
| 28 ott | Dimensione del disegno svincolata dalla fisica (`game.DISEGNO_H`). | PR #55 |
| 29 ott | L'editor entra nel pannello di Sergio come micro-frontend e avrà un connettore per i pezzi dello stampino (aggiungere/togliere pezzi a animazioni, personaggi, armi, skin). | docs/roadmap.md |
| 29 ott | Arma in mano **il più possibile** (Sergio): clip a parte con l'arma (`fermo_arma`, `corsa_arma`, `aria_arma`, `sale_arma`, `scende_arma`, `mira`), partite come copie di quelle senza; se una manca si usa quella senza. Chi non è di turno alterna a caso fermo (con scenette) e fermo con l'arma, ogni 4–12 s (Claude: tempi e niente scenette con l'arma in mano). | PR #61 |
| 29 ott | **Secchio dei pezzi** (Sergio: "tutto separato e tutto piazzabile", niente caselle): nell'editor tutti i pezzi (testa, busto, braccia, manine, gambe, ala, coda) stanno in un secchio; trascinati sul palco vanno in scena dove li lasci, dal palco al secchio escono, a chiave nella clip (canali `mostra_*`). Le manine (il pezzo `pugno`) sono pezzi liberi sul corpo, che le clip spostano e girano; da ferme stanno dove finiscono le braccia. Con l'arma in mano il pugno resta sull'arma anche senza braccio. | PR #61 |
| 29 ott | La spalla dell'arma (dove l'arma gira mirando) è segnata nell'editor ed è un perno come gli altri (`arma` in perni.lua): da mirare dritto l'arma resta dov'era. Il canale `arma` gira l'arma quando non si mira. | PR #61 |
| 29 ott | La fiammella non è un pezzo del personaggio: ce l'hanno tutti, qualunque testa indossino. Ha **la sua clip** (`fiammella`: gira, larga, alta, spostamento) che il gioco suona sempre sopra le altre; le tre forme a scatti e la grandezza su chi è di turno restano nel codice. Nelle altre clip dell'editor è spenta di default (casella "fiammella"). | PR #61 |
| 29 ott | Editor, sezione Strumenti: pezzo o personaggio nuovo da un'immagine (va a Claude, che scrive la scheda per Codex: niente prompt da copiare) e ritocco dei pezzi dello stampino (sposta e ingrandisci; `taglia.py --ritocchi` li rimette nelle pelli). Lo zoom del palco non dipende più dai canali aperti. | PR #61 |
| 29 ott | Impugnature per arma fatte nell'editor: si trascinano i punti delle mani (canna e impugnatura) sull'arma e si sceglie quante mani (nessuna, una, due); file unico `client/battle/grips.lua` letto dal gioco, dall'editor e dall'anteprima delle armi (via le `mani` da `armi.py`). Una clip con l'arma può avere una versione solo per un'arma (`fermo_arma_mallet`, `mira_mallet`): il gioco la preferisce, se manca usa quella di tutte. Sergio d'accordo sulla proposta di Claude: impugnatura una volta per arma, varianti solo dove servono. | PR #62 |
| 29 ott | Fiammella ufficiale: il disegno mandato da Sergio dall'editor (bianco e grigio col contorno nero, fiamma grande con goccia e scintilla), in `art/fiammella/fiammella.png`. Un disegno solo al posto delle tre forme a vettori alternate a scatti: si muove con la clip `fiammella`, il gioco tinge bianco e grigio col colore della squadra e la ingrandisce su chi è di turno. Usata così com'era, senza scheda per Codex (Claude). | PR #62 |
| 29 ott | Braccia libere con l'arma (canale `arma_libera`, casella nell'editor): l'arma sta nella mano del braccio davanti con l'impugnatura sul pugno, e le braccia le anima la clip come senza arma; spento, le braccia si piegano da sole sull'arma. Mirando le braccia vanno sempre da sole (la mira le comanda). Maglio e Spada hanno le loro clip con l'arma (`*_mallet`, `*_sword`, partite come copie), le altre armi usano quelle di tutte (del lanciamissili). Richiesta di Sergio: scegliere gli arti con l'arma in mano e il perno dell'arma (in braccia libere è l'impugnatura). | PR #62 |
| 29 ott | Un braccio solo per lato, anche con l'arma: l'arma sta sempre nella mano del braccio davanti (quello normale, con perno e pezzi delle pelli), girata rispetto al braccio ("Arma, gira"); mirando il braccio punta dove si mira e l'arma lo prolunga. L'arma è un pezzo del secchio (`mostra_arma`) che si toglie e si rimette; il suo perno è la **presa**, un punto per arma in `impugnature.lua` che si trascina sull'arma. Tolti i pezzi nascosti `omero`/`avambraccio` (base, stampino e pelle di Gabriella), la spalla dell'arma e il canale `arma_libera`. Richiesta di Sergio: "devo poter scegliere tutto, i pezzi di braccia da usare, i pivot, tutto". Un secondo punto di presa per la mano dietro resta possibile se lo vuole. | PR #63 |
| 29 ott | Livelli, chi impugna e perno dell'arma, scelti da Sergio nell'editor: ogni clip ha l'ordine dei pezzi (`livelli`, pannello Livelli come After Effects, in alto quello davanti) e chi impugna l'arma (`impugna`: braccio davanti o dietro, che gira verso la presa; manina davanti o dietro, che ci sta sopra; nessuno). Ogni arma ha presa, perno (dove gira, anche mirando) e spalla (dove sta il perno nel corpo), più i canali `arma_x`/`arma_y`. Di base il perno è sulla spalla davanti, dietro la presa quanto è lungo il braccio: il braccio ci arriva a ogni angolo. Alt + trascina sposta i perni (sull'arma anche la spalla, così l'arma resta ferma). Nel gioco vince la clip col peso più grande (Claude). | PR #67 |
| 29 ott | Il personaggio di Gabriella (pelle `gabriella`) è quello di tutti nel gioco (home, battaglia, podio: `scoria.PERSONAGGIO`) finché non c'è l'armeria che lo sceglie; l'editor parte con lei addosso. Animazioni rifatte da Sergio nell'editor (clip loro per lanciamissili, cecchino, granata, schegge e spada; la manina davanti impugna missile e cecchino). Richiesta di Sergio. | PR #69 |
| 1 nov | Personaggi ripensati dalla campagna (WB-008, pagina https://claude.ai/artifact/JoPBZRtznYF3xGEao2pTXF): Sergio sceglie il protagonista **A, l'apprendista** (diavoletto rosso mattone, corna corte, fazzoletto al collo) e poi **Favilla B**, la fiamma bianca. Il **colore della squadra sta sul fazzoletto**. I personaggi si generano con una **procedura standard** (`docs/handoff/PERSONAGGI.md`): tre quarti e espressioni approvati, poi pezzi sullo stampino, colori piatti di una tavolozza fissa, contorno nero spesso che sparisce alle giunture, poi SVG e PNG per schermo. Un personaggio alla volta: Favilla solo dopo che Sergio ha provato l'apprendista animato nell'editor. | WB-009 |
| 2 nov | **L'apprendista è il personaggio principale** (Sergio: "ho appena completato le animazioni, mettile in gioco, il personaggio principale adesso è ufficialmente l'apprendista"): `scoria.PERSONAGGIO = { "apprendista" }` in home, battaglia, podio, schede e cartellini (icone dell'equipaggiamento con i suoi pezzi; il mantello con l'ala di base, l'apprendista non ha le ali). Clip, hitbox, perni e impugnature sono quelli mandati da Sergio dall'editor. Le pelli `gabriella` e `gabriella_squadra` sono tolte dal gioco (superate; restano nella storia di git e nei file di Gabriella). | questa PR |
| 13 nov | **Il nuovo apprendista (WB-037) è il personaggio principale** con le clip mandate da Sergio dall'editor, la fiammella viva e le sue hitbox: capsula larga 14,9 (era 29,4), alta 39,2 come prima (Sergio: «se l'ho fatto più basso di prima riportalo all'altezza standard»); cerchio dei colpi raggio 20 a 20,5 da terra (era 20,49 a 19,6). | personaggio.md, #308, #310, questa PR |
| 2 nov | **Via la fiammella** sopra la testa, dalla home e dal gioco (Sergio: "togli la fiammella... ci dobbiamo inventare un altro modo per indicare il giocatore attivo"): tolti la clip, i canali, i disegni, il pezzo nell'editor e il codice. Il nuovo indicatore del giocatore di turno è da scegliere: proposte con le immagini di ChatGPT (scheda WB-010). | questa PR |
| 12 nov | **Mantelli liberi** (Sergio: "I mantelli vorrei che si muovessero liberi, seguendo la fisica di chi si sposta"): il mantello si disegna intero nella casella nuova `mantello` dello stampino (fra busto e ala, le altre non si spostano), `taglia.py` lo divide in tre strisce un po' sovrapposte e il gioco muove ognuna con la sua molla (corsa, caduta, colpi). Solo grafica, non cambia la simulazione. Categoria nuova `stivali` sopra le gambe. Scartato (Claude): far disegnare a ChatGPT le tre strisce separate, che difficilmente combaciano. Lo stampino ha l'apprendista come manichino al posto del diavoletto di base (Sergio: "mi sembra vecchio questo stampino, siamo passati all'apprendista"): stesse caselle e perni, cambia solo il grigio. | questa PR |
| 13 nov | **Mantello vero, strada B** (Sergio: le strisce «squallide», vuole pezzi che «sembrano veri» e reagiscono a salti e rinculo; poi «inizia con la b, la voglio provare col mantello del vuoto»): il mantello disegnato intero pende da una catena di sei punti simulata (Verlet a passo fisso, peso, aria, angolo limitato alla spalla, non entra nel corpo né nel terreno, spinte da colpi e rinculo) e uno shader piega tutto il disegno lungo la catena. Solo grafica. Sostituisce le tre strisce con le molle. Scartati per ora (Claude): Spine (Defold non mescola pelli né cambia immagini in gioco) e una mesh nel mondo (il diavoletto è nella GUI). | questa PR |
| 13 nov | **Mantello del Vuoto di Codex nel gioco** (WB-019 fase 2): base e forgiato, al posto del mantello finto. Ingrandito 1,35 volte rispetto alla casella dello stampino, che sull'apprendista lo lasciava quasi tutto dietro il corpo (Claude). Cappuccio, corazza e stivali del Vuoto aspettano: il cappuccio copre il viso e ha le corna dentro (passo 2 della roadmap dei pezzi). | questa PR |
| 13 nov | **Pannello Mantello nell'editor e mantello ampio** (Sergio: «Pannello Mantello + nuovo disegno»): i numeri del mantello escono da `scoria.lua` e vanno in `client/battle/cape_tuning.lua`, che Sergio tara dal vivo nell'editor delle animazioni (stessa catena e stesso shader del gioco, il diavoletto corre e salta per finta) e manda con "Manda a Claude". Taratura unica per tutti i mantelli (Claude: una per mantello solo se servirà). Scheda WB-032 per un mantello del Vuoto più ampio, fatto per muoversi. | questa PR |
| 13 nov | **Mantello ampio del Vuoto (WB-032 B) nel gioco** (Sergio sceglie B, strisce lunghe, fra A a campana e B): base e forgiata al posto del mantello stretto di WB-019. Alla qualità migliore su ogni schermo (Sergio: «tutto alla qualità migliore possibile su ogni schermo»): Codex l'ha disegnato grande (circa 4,8 pixel per unità), `taglia.py --mantello-px` lo taglia da solo e i mantelli si salvano a 4,5 pixel per unità invece di 3, senza ingrandire. Scartato (Claude): rifare la scheda su un foglio quadrato, la consegna era già fitta abbastanza. | #306 |
| 13 nov | **Il mantello non tocca terra e si piega in curva** (Sergio: «nell'editor vedo ancora che si spezzetta»): il mantello appeso dritto finisce poco sopra i piedi (B ritagliato più piccolo, `--mantello-px 7.2`), perché toccando terra la catena piegava ad angolo retto e il disegno si spezzava; lo shader piega il disegno lungo una curva liscia per la catena (15 quad invece di 5). Scartato (Claude): lasciarlo lungo fino a terra e farlo strisciare (il disegno non può piegarsi ad angolo senza rompersi). | questa PR |
| 3 nov | **Freccia di ferro sopra chi è di turno** (Sergio ha scelto la proposta 2 della scheda WB-010, https://claude.ai/artifact/TQ2Y2jyLQFTjRfkSAJJwYU: sopra il nome, con la brace che pulsa). Una sola freccia, sopra il nome o sopra la Corona di chi è primo, che dondola piano; la brace ha il colore della squadra ed è più accesa quando la freccia è in basso, come nel foglio di ChatGPT. Mirando, il cartellino coi gradi, le battute e la riga delle missioni stanno sopra la freccia. Scelte di Claude: dal foglio un solo fotogramma (il più acceso) diviso in tre strati (ferro, brace bianca tinta dal gioco, cuore bianco), così vale per le quattro squadre e non solo per blu e oro; il dondolio e la pulsazione li fa il codice (i fotogrammi del foglio non hanno la stessa forma); larga 28 unità della targa (circa come il nome, si legge anche da lontano); sobbalza con la targa quando arriva un colpo, come il nome e la Corona, così non li copre. Scartate: i quattro fotogrammi del foglio (forme diverse, la freccia tremerebbe), il disegno vettoriale nuovo (Sergio vuole le immagini di ChatGPT). | questa PR |
| 4 nov | **Favilla coi suoi pezzi** (WB-013 fase 2, pelle `favilla`): i tre fogli di Codex tenuti tutti, ricalcati con la tavolozza di Favilla e tagliati sullo stampino come l'apprendista; la vestono la comparsa del cortile e l'avversaria del Duello (campo `pelle` della missione, solo disegno), col nome azzurro sopra. Scelte di Claude: stivali `#8A5228`/`#6B3F22` (ChatGPT li ha fatti più chiari della scheda); regole nuove del ricalco (colori tolti per foglio, macchioline, marroni che non diventano righe) solo nella tavolozza di Favilla, così l'apprendista non cambia; niente ritocco a mano alle spalle a sbuffo finché Sergio non le vede nell'editor. | `tools/stampino/`, `client/battle/favilla.lua`, questa PR |

## Scartate, con il motivo

| Cosa | Perché |
|---|---|
| Spine (Essential 99 $, Pro ~370 €) | Essential senza mesh e IK; runtime in più; con l'editor nostro non serve (25–27 ott). Resta il piano B se servisse deformazione premium. |
| DragonBones | Editor fermo dal 2018, animazioni per armatura non condivise (Sergio l'ha visto, 25 ott), estensione Defold non testata su mobile. |
| Rive, Spriter, Creature, Live2D, Moho | Rive richiede GL 4.2+ e abbonamento; gli altri stantii o senza Defold. |
| Fogli di frame (ChatGPT, Ludo, video AI) | Deriva tra i frame, pesanti (fino a 15 MB di atlas), non reagiscono al gioco, code tagliate dal bordo; Sergio ha rinunciato il 26 ott. |
| Pixel art (PR #43) | Messa da parte: stile misto con mappe e UI, resa sfocata finché non si è fissato il filtro. |
| Pezzi staccati fluttuanti come nel gioco di riferimento | Provati con Gabriella, tornata al diavoletto con le gambe. |
| Diavoletto senza braccia + braccia da AI | Prospettive sbagliate, spalle strappate; fermato dal coordinatore e da Sergio (25 ott). |
| Braccia a tubo dritto nella mira | "Che schifo" (26 ott): sostituite da IK. |
| Versione a colori piatti automatica dei pezzi dipinti | Chiazze; lo stile piatto deve venire dalla fonte. |
| Strato di contorno unico sull'immagine intera | Contorno cotto per pezzo; solo la coda usa una catena di bordi separata. |
| Corpo ×2 (`ROBOT_H` 56) | Scalava tutto il mondo; Sergio l'ha ribaltato lo stesso giorno. |
| Cambiare motore per avere editor migliori (Godot, Unity) | Vedi architettura.md: si resta su Defold. |
| Ruotare i pezzi nel ritocco dello stampino (29 ott) | I pezzi non hanno un angolo: servirebbe ridisegnare l'immagine; per ora si spostano e si ingrandiscono. |
| Strumento che scrive da solo i prompt per ChatGPT nell'editor (29 ott) | La regola è che i prompt li scrive Claude nelle schede per Codex: l'editor manda immagine e note, niente testo da copiare. |
| Fiammella dentro le pelli o ridisegnata per ogni testa (29 ott) | È l'indicatore di chi gioca, uguale per tutti: resta un pezzo del gioco sopra la testa. |
| Impugnature diverse per ogni fotogramma di ogni clip e di ogni arma (29 ott) | Proposta di Sergio, scartata insieme: lavoro moltiplicato per ogni arma nuova (se ne usciranno spesso) e le mani scivolerebbero sull'arma; si fa una volta per arma, e se un'arma deve muoversi diversa ha la sua versione della clip. |
| Impugnature scritte nel codice delle armi (`armi.py`) (29 ott) | Si cambiavano solo a mano rigenerando le armi; ora le fa l'editor in un file solo. |
| Tre forme della fiammella alternate a scatti (29 ott) | Con il disegno di Sergio la fiamma è una sola e la anima la clip; lo scatto fra tre forme diverse non serve più. |
| Braccia IK a 2 ossa sull'arma (pezzi `omero`/`avambraccio`) e la casella "braccia libere" (29 ott) | Pezzi di braccia nascosti attaccati all'arma che Sergio non poteva togliere né scegliere; sostituiti da un braccio solo per lato con l'arma nella mano. |
| L'arma attaccata alla mano del braccio davanti, col perno nella presa (29 ott, PR #63) | Sergio vuole scegliere chi impugna e il perno su cui gira, separato dalla presa; tornati al perno che sta nel corpo e la mano che segue. |
| Ordine dei pezzi come canale animato (29 ott) | Le pose si sommano a pesi: un ordine a metà fra due clip non esiste. È della clip e vince quella col peso più grande (Claude). |
| Due mani automatiche sull'arma (canna e impugnatura) (29 ott) | Ripartiamo con un punto di presa solo e la mano dietro posata da Sergio (Claude); il secondo punto si aggiunge se lo chiede. |
| Caselle per mostrare e togliere i pezzi, manine fisse in fondo alle braccia (29 ott) | Sergio: non va bene, i pezzi stanno in punti fissi; vuole vedere tutto separato e piazzabile. Sostituite dal secchio e dalle manine libere. |

## Aperte

- Sergio ha "molte altre correzioni al personaggio da descrivere" (26 ott):
  non ancora arrivate.
- Quanto può spingersi il vettoriale: tutto ciò che è piatto con gradienti
  semplici, niente texture pittoriche (risposta data, 26 ott).
- Ritocchi dei pezzi di base (non delle pelli): ora solo le pelli.

## Fiammella viva (9 nov, Claude)

Sergio (8 nov) chiede la fiammella animata «senza spritesheet» con le tecniche
dei giochi (rumore che scorre, erosione, punta che oscilla, base ancorata) e
lo stesso per i capelli di fuoco di Favilla. Fatto così (`client/battle/flame.fp`,
`client/battle/flame.lua`):

- La fiamma dell'Apprendista è un pezzo a parte (opzione A): il disegno
  `art/WB-018/1_fiammella_base_2.png` (la più vicina al concept, colori pieni),
  scontornato pulito, in `client/paintings/flame/apprendista.png` con spazio
  attorno per ondeggiare. Lo shader piega l'immagine: la base resta ferma, più si
  sale più si muove (due onde che salgono e un rumore morbido che scorre verso
  l'alto), l'altezza respira del 6-9%. Tutto torna uguale ogni 16 s (niente salti).
- Favilla: lo stesso shader sulla testa intera, con un peso che è zero su viso,
  orecchie e corna e cresce verso le ciocche di fuori: si muovono le punte dei
  capelli, il viso no. Niente immagini nuove: le sue nove teste vanno bene così.
- Le immagini vive si caricano a parte (non nell'atlante), così lo shader sa dove
  è dentro l'immagine; il tempo e il lampo del colpo arrivano dal colore del nodo,
  come negli altri shader del gioco.
- La targa (nome e vita) ora sta sopra la fiamma e sopra la testa com'è nella posa
  da fermo: con le animazioni per personaggio del 7 nov copriva la fiamma e i
  capelli di Favilla.

Scartati: l'**erosione** (il rumore che buca la fiamma) e i colori a temperatura
(blu-bianco al centro): rompono il contorno nero e il colore piatto dello stile,
sbavature; le **particelle** di scintille per ora (si possono aggiungere dopo);
la **mesh** con più vertici (in GUI un nodo ha 4 vertici, e la piega nel frammento
basta); staccare i capelli di Favilla in un pezzo a parte (servirebbero 9 teste
rifatte).

9 nov, dopo #233: sul telefono di Sergio su Favilla si muoveva il viso e non i capelli. Causa probabile: l'immagine caricata a parte arriva con le coordinate verticali al contrario rispetto al PC, e il basso diventa l'alto. Lo shader ora lo chiede all'immagine (un punto pieno vicino al fondo e vuoto alla stessa altezza dall'alto) e funziona nei due versi. Sul PC non cambia niente.
