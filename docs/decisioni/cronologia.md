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
| 29 ott | Editor: pannello Livelli per clip, chi impugna l'arma (braccio o manina), perno dell'arma separato dalla presa, Alt per spostare i perni. | #67 |
| 29 ott | Tutorial: la prima partita guidata contro il bot, righe sopra il diavoletto, 8 lezioni da 3 stelle; CONTRO I BOT diventa ALLENAMENTO (lezioni e bot); rompicapo del giorno e fantasmi in roadmap (Eventi). | #66 |
| 29 ott | Animazioni rifatte da Sergio nell'editor su main; Gabriella personaggio di tutti. | #69 |
| 29 ott | APK su Telegram: bot @ultrablastbot, GitHub Actions costruisce e manda l'APK a ogni push su main. | questa PR |
| 29 ott | Il tocco che annulla la mira sul telefono vale solo sulla metà destra (a sinistra si cammina). | questa PR |
| 29 ott | Motore Android snello (manifest dell'app senza fisica, Vulkan, registratore, profiler, particellari) e UI senza mipmap. | questa PR |
