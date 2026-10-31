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
| 29 ott | Globi più facili: 2 entro 9 s, 1 entro 17 s, mai 3; tacche viola sul cronometro; baratto del secondo attacco con un teletrasporto (pulsante sopra il cronometro). | questa PR |
| 29 ott | Teletrasporto guadagnato sempre usabile (anche al primo turno); globi più chiari che volano in curva al pulsante, numerino che sale all'arrivo con lampo e primo suono dei globi. | questa PR |
| 29 ott | Campagna: Addestramento (le lezioni, il Tonante al posto delle casse) e I girone: la Forgia con il custode; bot con carattere; stelle con bonus; aiuto silenzioso; ALLENAMENTO solo contro i bot; collaudo delle missioni coi bot. | questa PR |
| 29 ott | Lezioni rifinite: solo l'HUD che serve, tempo fermo finché non tocchi i comandi, come si salta, oggetti con un'identità (colonna OGGETTI), ESCI torna al menù di prima, ogni stella col suo criterio; Due mani e Fuori portata di nuovo finibili (il bot si rimetteva a 150 di vita); IL TUO TURNO / TURNO DI: nome; RIPROVA nella rotellina. | #80 |
| 29 ott | Si muore molto prima: vita 100, danni a 5/3, punti per la percentuale di vita tolta; missioni ritarate. | #79 |
| 29 ott | Nuova regola delle categorie (primarie: danno ed effetti di stato; secondarie: tutto ma mai effetti), secondaria nuova Mantice che spinge il nemico, Rampino a 400 px con l'uncino che vola, cade e si dissolve; Cecchino e Mantice in "Giù dal bordo". | questa PR |
| 29 ott | Salto dal telefono: tacche dell'arco del salto sulla levetta e micro-vibrazione quando ci si entra (estensione `client/vibra`); build di prova dell'APK sulle PR. | #83 |
| 29 ott | Mira più chiara: puntini uguali con la punta del colore della squadra, cartellino con gradi e potenza sopra la testa, grandi uguali a ogni zoom; micro-vibrazione a ogni 5% di potenza. | #84 |
| 29 ott | Addestramento dalle basi (Camminare, Saltare, Sparare), la Prima partita come esame finale, il I girone chiuso da una partita 2 contro 2, e guidato: il suggerimento mette in luce il comando e ferma il tempo finché non lo tocchi; dito disegnato per saltare e annullare la mira sul telefono; nei gironi la luce senza fermare il gioco. | #86 |
| 29 ott | Il codardo attacca a ogni turno e scappa col globo nelle tane; i bot con un carattere e i custodi parlano in nuvoletta. | #86 |
| 29 ott | Pallini della mira più piccoli (Sergio): metà grandezza, uno ogni 10 px. Di base il telefono vibra solo quando il colpo diventa sganciabile (la vibrazione a ogni 5% di potenza diventa un'impostazione). Nasce [docs/impostazioni.md](../impostazioni.md): ogni impostazione nominata da Sergio va lì subito. | questa PR |
| 29 ott | Mira: solo angolo e potenza, uguale per tutte le armi: mirino che si riempie con la potenza e cartellino coi gradi; niente traiettoria, se non come aiuto nelle lezioni dell'Addestramento. | #87 |
| 29 ott | Rampino: quando la fune finisce a metà strada si spezza con uno schiocco, "STRAPPO!" e il filo cade. | #88 |
| 29 ott | Mira più chiara: puntini uguali con la punta del colore della squadra, cartellino con gradi e potenza sopra la testa, grandi uguali a ogni zoom; micro-vibrazione a ogni 5% di potenza. | #84 |
| 29 ott | Corona del primo più grande, sopra il personaggio e sul gettone dei punti. | #89 |
| 29 ott | Corse delle reti fermate; il bot del gioco prende le loro lezioni: si teletrasporta molto di più e si ripara col globo. | #90 |
| 29 ott | Mantice più debole: spinge meno (400 invece di 520, meno in su, meno al bordo del raggio); spingeva fuori troppo facilmente. | #91 |
| 29 ott | Rampino sul terreno: ti porta sopra la piattaforma anche agganciandola da sotto in diagonale (soglie più larghe). | #91 |
| 29 ott | Mira a lancetta di base (tacche che si accendono con la potenza); il mirino si sceglie dalla rotellina in partita (MIRA) e resta salvato. | #92 |
| 29 ott | Armi da vicino: niente lancetta, una punta nella direzione del colpo e un anello ai piedi di chi verrebbe colpito. | #92 |
| 29 ott | Nuove generazioni dei bot: evolvono i numeri del bot del gioco, un campione per stile, scelte da sole quando non migliorano; pagina coi video delle trovate dei bot. | #93 |
| 29 ott | Stelle della campagna tarate coi bot: quote di seconda e terza stella, missioni da guardare, previsione se cambia la vita degli avversari; controllo su ogni PR che cambia le regole. | #93 |
| 29 ott | Primi passi: Camminare, Saltare e Sparare in un percorso solo, senza tempo né turni (bandierina, gradino, cassa col Lanciarune e la sua scheda, bersaglio; se manchi ritenti subito); stelle a tiri a vuoto; l'interfaccia delle lezioni si scopre a poco a poco; niente cerchi di cura nelle lezioni; Armi e draft prima della Prima partita. | #95 |
| 29 ott | Baratto del secondo attacco con un tocco solo (prima si teneva premuto). | #94 |
| 30 ott | Addestramento in sei lezioni: Primi passi, Il turno (anche il baratto), Armi che ti muovono, Attrezzi e paracadute, Punti e Corona, Prima partita (che comincia con la scelta delle armi); ogni arma arriva da una cassa con la sua scheda. | #96 |
| 30 ott | Esame dei bot a coppie (prima era storto di 6-8 punti); provati e scartati due attacchi pensati insieme, riparo che guarda la risposta del nemico e il campione della notte: tutti alla pari col bot di oggi. | #98 |
| 30 ott | Più calcolo non rende il bot più forte (51% col doppio, 49% con la metà); cinque bot specialisti (spingitore, acrobata, cecchino, picchiatore, sopravvissuto) con gusto per le armi che guida anche la scelta d'inizio partita. | #98 |
| 30 ott | Scelta delle armi rifatta: tenendo premuta una carta si apre la scheda; prima la primaria poi la secondaria, scelte altrui nascoste, doppioni liberi, niente scambio né attrezzi (Rampino per tutti; il Bastione, da ripensare, è tolto dal codice e dalla lezione Attrezzi); la prima scelta è alla Battaglia della Forgia, guidata e con le armi già viste; il tutorial non ha scelta. Protocollo 3. | questa PR |
| 30 ott | Tutorial a mossa quasi obbligata: in ogni lezione si accende solo il comando che serve, il tempo si ferma a 1 s finché non lo usi, un tentativo a vuoto ti rimette dov'eri. Il turno solo con Lanciarune e Lama (isola col teletrasporto, baratto); Rampino e paracadute senza casse, niente Bastione né Cecchino; Prima partita senza scelta delle armi. | #99 |
| 30 ott | Nel I girone una cassa con l'Uovo (Primo sangue) e una con le Schegge (Due mani): le armi che l'Addestramento non presenta (Claude). | #99 |
| 30 ott | Tutorial: angoli rossi sul bersaglio da colpire, il bersaglio abbattuto che non serve più resta giù (anche in Giù dal bordo), la scheda della Lama dopo che il missile è arrivato; se cadi o sprechi i globi torni com'eri all'ultimo passo, globi compresi. | #101 |
| 30 ott | Il tempo della partita non scende mentre si aspetta che tutto si fermi fra un turno e l'altro. | #101 |
| 30 ott | I pulsanti dell'HUD scelgono sempre (il teletrasporto non si spegne più toccandolo di nuovo); quello che non si può usare fa no e dice perché in due parole; l'arma scelta resta in mano a inizio turno, anche scelta nel turno degli altri. | #100 |
| 30 ott | Supporto ai controller con la mappatura di Sergio (levette come sul telefono, RT spara, bumper a giro su primarie e secondarie, A teletrasporto, X Rampino, Y paracadute, LT oggetti); luce sui pulsanti dei menu e sulle carte della scelta; il tutorial parla coi tasti del controller. | #102 |
| 30 ott | Controller, secondo giro: assi verticali raddrizzati su Android, RT spara con la mira di un attimo prima, B non apre più la rotellina, un dito che cambia schermata non preme la schermata dopo (in tutto il gioco); IMPOSTAZIONI nella home (mira e tasti del controller da cambiare); sull'HUD ogni pulsante mostra il suo tasto, disegnato come sul controller (Xbox, PlayStation, Nintendo). | #104 |
| 30 ott | Controller, terzo giro: SALTA su un tasto (con un tasto la levetta non salta più), sparo lasciando il tasto (di base) o premendo, potenza dal grilletto, Y toglie un tasto, una fonte sola per controller (la mira che scattava). Maglio direzionale (l'arco gira con la mira) e rimbalzo al primo urto su terreno o robot, a terra come in aria. | #105 |
| 30 ott | Controller: di base la levetta destra muove e la sinistra mira (Sergio); nelle IMPOSTAZIONI si sceglie quale levetta muove. | #106 |
| 30 ott | Controller: la mira che scattava a 35°: touchpad e sensori del PlayStation su Android non contano più come controller, le levette contano da un controller solo. | #107 |
| 30 ott | Controller: una pressione del grilletto non spara più due volte (margine fra premuto e lasciato). | #108 |
| 30 ott | Controller, la causa vera della mira che scattava e del doppio colpo: Defold segna "lasciato" quando un valore scende sotto 0,9, e noi lo leggevamo come zero. Ora conta solo il valore. | questa PR |
| 30 ott | Campagna a 10 gradi di difficoltà misurati coi bot (ogni grado batte quello sotto nel 55-75%); la Forgia sale dal 2 al 5, niente più burrone fra Due mani e Il codardo. | questa PR |
| 31 ott | Ultimo giro a punti doppi (il giro che comincia con meno di mezzo giro di tempo, al posto dei supplementari) con striscione e oro; nel 2 contro 2 il tabellone è a turni pari, coi punti in attesa, "+N PER PAREGGIARE" e i pallini dei turni. Il 2 contro 2 è la modalità prediletta. | #112 |
| 31 ott | La Corona arriva solo dopo il primo giro di turni (chi apre non è più primo solo perché ha già sparato); la parte della fune coi punti in attesa è a fasce diagonali. | questa PR |
| 31 ott | Niente punti nelle lezioni che non li spiegano; nei gironi la seconda stella è per i punti di vantaggio invece che per i turni, soglie misurate coi bot. | questa PR |
| 31 ott | Eventi: calendario fatto da Sergio con modelli e ripetizioni, eventi sovrapposti permessi, premi badge/skin/monete, fasce a percentuale, bozza del pannello. | questa PR |
| 31 ott | Eventi nel gioco, passo 1: regole come dati, calendario degli eventi sul server (file che si rilegge, ripetizioni, code degli eventi), EVENTI nella home, bacheca, dettaglio e DOVE GIOCHI? dopo GIOCA; nel Torneo un tetto ai livelli invece della normalizzazione. | questa PR |
