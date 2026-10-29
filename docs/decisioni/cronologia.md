# Cronologia

Un rigo per giorno e per PR. I dettagli stanno nei file delle aree.

| Data | Cosa | PR |
|---|---|---|
| 19 ott | Nasce il progetto: README, design e architettura (Defold + Go, sim condivisa), prototipo hot-seat con terreno distruttibile, server online in rete locale, fisica e mappe (niente vento, salto libero), fluidità (interpolazione). | #1–#8 |
| 20 ott | Nome MegaBlast. Direzione artistica D "Le Scorie". Analisi dell'APK di Blastron. Mappa isole, integrazione grafica in battaglia, home, teletrasporto e Lama, casse e armi, collisioni tra robot. | #9–#22 |
| 21 ott | Profilo fisico "blastron", levette, mappa Forgia dei Titani; skill del progetto. Tentativo di look Blastron bocciato. | #23, #24 |
| 22 ott | Personaggio v2 (bocciato la sera); discussione di game design competitivo (tempo del turno, strategia, equipaggiamento). | — |
| 23 ott | Decisioni del design competitivo (Nucleo, due attacchi, draft, albero, calendario eventi). Pilastri del personaggio, greybox, Corona del Titano, game feel. UI minimale stile Sagoma. Server scalabile. Regole di igiene del codice e autonomia tracciata. | #25–#28, #31–#34 (bozze) |
| 24 ott | Mergiate regole competitive, UI minimale, podio e albero, server con code e draft; Nucleo rimosso (globi di teletrasporto); arsenale primarie/secondarie; Cecchino rifatto; cerchi di cura; build HTML5 per iPhone; `max_nodes` 2048. Regole per lavorare con Gabriella. | #29, #31–#40 |
| 25 ott | Gabriella: frame, video AI, Ludo, pixel art (PR #43 messa da parte). Ricerche: ossa (Spine), motori (restare su Defold), scheletro unico, DragonBones solo editor. Regola "scartate e perché". | #41 (mai), #42, #43 |
| 26 ott | Il diavoletto di Sergio su main (pezzi ChatGPT + Ludo), corpo ×1,4 svincolato, mappe ×1,5; trampolino; morte da soli; teletrasporto sempre; rampino che trascina; Maglio e Affondo; armi vettoriali; mappa Crogiolo e rotazione. Sera: "mi arrendo" agli asset AI, diavoletto vettoriale. Proposta di roadmap. | #44–#53 |
| 27 ott | Editor delle animazioni (clip, pose, hitbox, perni); stampino per le skin. | #55 (bozza) |
| 28 ott | Mergiati diavoletto vettoriale, editor e stampino, schede ChatGPT via Codex (WB-001 generata e montata); editor su Cloudflare. | #54–#57 |
| 29 ott | Punti in partita (variante A con Corona, trappola, parata; Rampino e trampolino danno l'uccisione), HUD dei punti e attrezzo Bastione scelti da Sergio; prove nell'arena dei bot a coppie col thread del bot. Fatti tutti e tre: regole, HUD (`punteggio.lua`, primo suono), Bastione col terzo ventaglio del draft e la scelta nell'armeria. | #60 |
| 29 ott | Roadmap fissata da Sergio (21 aree, novità: torneo della community, tornei a iscrizione, laboratorio bot, statistiche e badge, interfaccia tranquilla, clan e guerre); cartella delle decisioni; regola della sfida tra chat; proposta del bot. | #58 |
| 29 ott | Editor: arma in mano con clip sue e idle con l'arma a caso, secchio dei pezzi trascinabili sul palco (manine libere), spalla dell'arma come perno, fiammella con la sua clip, zoom fisso, Strumenti (nuovo pezzo da immagine, ritocco dello stampino). | #61 |
| 29 ott | Editor: impugnature di ogni arma trascinabili (file `impugnature.lua`) e clip solo per un'arma (`fermo_arma_mallet`); fiammella ufficiale dal disegno di Sergio; braccia libere con l'arma; clip loro per Maglio e Spada. | #62 |
| 29 ott | Un braccio solo per lato anche con l'arma: arma nel secchio, presa da trascinare (un punto per arma), via braccia IK e braccia libere. | #63 |
| 29 ott | Draft collegato alle partite online (schermata, tempo, cambio scelta, scambio col compagno, attrezzo dell'assetto); regola permanente "server sempre in pari con main" e allineamento del server; l'online si prova nel simulatore con un server vero. | questa PR |
| 29 ott | HUD della battaglia rifatto su proposte disegnate: punti in alto al centro, cronometro ad anello con battiti, armi divise attorno all'anello, oggetti sopra le secondarie, attrezzo e teletrasporto tondi a destra, levette nuove, tocco che annulla la mira, font Lilita One. | #65 |
| 29 ott | Bot euristico a tre livelli, CONTRO I BOT nella home, ricette con impronte (replay deterministico e validato), arena dei bot in parallelo con rapporto, highlight e video. | PR del bot |
| 29 ott | Notte di arena (circa 34.000 partite): pesi del bot che evolvono, prove di punteggio e di ordine dei turni, documento delle proposte. Sergio applica i ritocchi delle armi e la Fornace, lascia l'ordine dei turni, vuole la rinascita su punti fissi, set mischiabili senza set iniziale e bot con rete neurale. | PR del bot |
| 29 ott | Bot con rete neurale che evolvono da zero (evolvi.py, senza fine, con esami contro il bot euristico); tutti i bot si riparano dopo gli attacchi. | PR del bot |
| 29 ott | Apprendimento a gradiente dei bot (impara.py) e corsa lunga sul PC di Sergio. | PR del bot |
| 29 ott | Gradiente fermo sotto il bot euristico: seconda versione con TD(λ), rete più grande e esame più lungo. | PR del bot 2 |
| 29 ott | Editor: pannello Livelli per clip, chi impugna l'arma (braccio o manina), perno dell'arma separato dalla presa, Alt per spostare i perni. | #67 |
| 29 ott | Tutorial: la prima partita guidata contro il bot, righe sopra il diavoletto, 8 lezioni da 3 stelle; CONTRO I BOT diventa ALLENAMENTO (lezioni e bot); rompicapo del giorno e fantasmi in roadmap (Eventi). | #66 |
| 29 ott | Animazioni rifatte da Sergio nell'editor su main; Gabriella personaggio di tutti. | #69 |
| 29 ott | APK su Telegram: bot @ultrablastbot, GitHub Actions costruisce e manda l'APK a ogni push su main. | questa PR |
| 29 ott | Il tocco che annulla la mira sul telefono vale solo sulla metà destra (a sinistra si cammina). | questa PR |
| 29 ott | Schermata di fine livello con le stelle (lezioni, pronta per la campagna); rotellina in ogni partita con ESCI DALLA PARTITA (anche online: messaggio `leave` al server). | questa PR |
| 29 ott | Il tocco che annulla la mira sul telefono vale solo sulla metà destra (a sinistra si cammina). | #71 |
| 29 ott | Motore Android snello (manifest dell'app senza fisica, Vulkan, registratore, profiler, particellari) e UI senza mipmap. | questa PR |
| 29 ott | Camera quando si spara: finché chi spara può muoversi inquadra lui e il colpo, allontanandosi quanto basta; a turno finito segue il colpo come prima. | #73 |
| 29 ott | Niente si deforma: GUI tutta FIT su ogni proporzione dello schermo, comandi attaccati ai bordi veri; la camera scende sotto la mappa così l'HUD non copre il terreno. | #74 |
| 29 ott | Campagna: Addestramento (le lezioni, il Tonante al posto delle casse) e I girone: la Forgia con il custode; bot con carattere; stelle con bonus; aiuto silenzioso; ALLENAMENTO solo contro i bot; collaudo delle missioni coi bot. | questa PR |
| 29 ott | Lezioni rifinite: solo l'HUD che serve, tempo fermo finché non tocchi i comandi, come si salta, oggetti con un'identità (colonna OGGETTI), ESCI torna al menù di prima, ogni stella col suo criterio; Due mani e Fuori portata di nuovo finibili (il bot si rimetteva a 150 di vita); IL TUO TURNO / TURNO DI: nome; RIPROVA nella rotellina. | #80 |
| 29 ott | Addestramento dalle basi (Camminare, Saltare, Sparare) e guidato: il suggerimento mette in luce il comando e ferma il tempo finché non lo tocchi; dito disegnato per saltare e annullare la mira sul telefono; nei gironi la luce senza fermare il gioco. | questa PR |
| 29 ott | Il codardo attacca a ogni turno e scappa col globo nelle tane; i bot con un carattere e i custodi parlano in nuvoletta. | questa PR |
