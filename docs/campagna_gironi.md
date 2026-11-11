# La campagna dei gironi

Documento di riferimento per la campagna dopo il Cortile e la Forgia: nove gironi
dell'inferno, Lucifero, poi purgatorio e paradiso. Approvato da Sergio l'11 novembre 2026
(tutte e otto le scelte consigliate, più i due ritocchi qui sotto). La pagina con le
schermate disegnate, i grafici e le alternative scartate è
https://claude.ai/artifact/2GwyRT7Q7b1XD86KXFNTCh (stesso indirizzo sempre).
Le decisioni sono in [decisioni/progressione.md](decisioni/progressione.md); questo file
è la descrizione completa. Chi tocca la campagna lo legge prima e lo aggiorna.

## Le regole di Sergio che valgono per tutti

1. **Non si vede oltre il prossimo girone bloccato.** Nella mappa della campagna si vedono
   i gironi finiti, quello aperto e **uno solo** bloccato (con il suo custode in ombra);
   sotto c'è buio. Niente purgatorio, paradiso, anelli più in basso, conti delle stelle
   di capitoli che non si vedono. Il finale non deve sembrare un finale a metà.
2. **I pericoli dei gironi valgono anche online** (Sergio, 11 nov, ritocco alla scelta 8):
   bufera, grandine, massi, acqua che sale, ghiaccio e ponti entrano nelle mappe della
   rotazione online per dare varianza, non solo nella campagna. Quindi ogni pericolo è
   nella simulazione (`client/sim/`), il server va in pari nella stessa PR (terreno in
   Go compreso, `go test ./server/`) e il protocollo si aggiorna se serve.
3. **Le mappe di tutti i livelli si fanno subito e per ora si vedono tutte in ALLENAMENTO**
   (Sergio, 11 nov). Più avanti si sbloccheranno in Allenamento man mano che le vedi in
   campagna, ma finché non si decide si vedono tutte.
4. **Il girone dopo si apre battendo il custode**, non con le stelle: le stelle danno premi.
5. Il Cortile (l'Addestramento) è l'antinferno; la Forgia viene dopo. Sull'imbuto
   stanno in alto, sopra i nove gironi.
6. Niente bot che barano: la difficoltà sale con i gradi del bot (1-10, `bot.GRADES`)
   e con regole che si vedono (più nemici, pericoli più forti, custodi con più vita).
   L'aiuto silenzioso dopo tre sconfitte resta.

## La trama

Favilla (l'aspetto è la versione B di WB-008, scelta da Sergio) è l'apprendista più
grande della Forgia: nell'Addestramento ti spiega le basi, nella Battaglia della Forgia è
la tua compagna di squadra, il Fabbro è il maestro fin dall'inizio. Vinta la Battaglia,
un artiglio di ghiaccio la prende e la porta nel Cocito: Lucifero, piantato nel lago fino
al petto, le ruba il calore per liberarsi (la sua fiamma bianco-azzurra è la più calda
dell'inferno). Il Fabbro ti guida fino al pozzo dei giganti, poi si ferma («il ghiaccio
spegne il fuoco»): da lì si va da soli. Lucifero si batte in tre fasi; quando cade, titoli
di coda e FINE, come se non ci fosse altro. Dopo i titoli la mappa si capovolge e
l'imbuto diventa la montagna del purgatorio; purgatorio e paradiso si fanno in 2 contro 2
con Favilla, contro l'Ombra di Lucifero. Le tavole illustrate seguono il fumetto a capitoli
del 4 novembre (nessuna animazione, solo vignette in grande).

## Numeri

| Capitolo | Livelli | Gradi del bot |
|---|---|---|
| Cortile (Addestramento) e Forgia | quelli che ci sono | 2 → 5 |
| I Limbo | 6 | 3 → 5 |
| II Lussuria | 6 | 3 → 6 |
| III Gola | 6 | 4 → 6 |
| IV Avarizia | 6 | 4 → 7 |
| V Ira | 6 | 5 → 7 |
| VI Eresia | 6 | 5 → 8 |
| VII Violenza | 7 | 6 → 8 |
| VIII Frode | 7 | 7 → 9 |
| IX Tradimento (con Lucifero) | 6 | 8 → 10 |
| Purgatorio | 9 | 7 → 9, con Favilla (grado 8) |
| Paradiso | 8 | 8 → 10, con Favilla (grado 8) |

Ogni girone ha la stessa ossatura: scopri il pericolo (intro o fuga), usalo in un duello o
in un rompicapo, un 2 contro 2 col Fabbro o un'orda, poi il custode. I tipi di livello:
intro, fuga, duello, rompicapo, squadra, orda, resisti, raccolta, speciale, passaggio,
custode. I verbi che mancano nel motore (`resisti`, `raccogli`, `proteggi`, `arriva primo`)
si aggiungono come dati in `client/sim/missions.lua`.

## Interfaccia

Dalla home la CAMPAGNA apre la mappa a imbuto in sezione, già sul girone dove sei; si
scorre in verticale. Tre schermate: l'imbuto (gironi finiti con le stelle, quello aperto, un
solo bloccato), la porta del girone (numero romano, nome, verso di Dante, pericolo, cosa
conviene, custode, ENTRA) e il sentiero (i livelli in fila sul bordo dell'anello, il
custode si apre dopo i primi quattro). Battuto il custode l'anello si incrina e la camera
scende (solo la prima volta, saltabile). Tutto disegnato in codice come il resto dell'interfaccia
(`client/ui/kit.lua`); lo stile finale dei custodi e dei colori lo decide Gabriella.

## I gironi

Colori, pericoli, livelli e custodi di ogni girone. Le anime e i nomi sono di Dante, il
tono è da cartone: niente supplizi crudi. Le mappe dei livelli vanno disegnate con la regola
dei colori della campagna (sfondo più scuro e spento del terreno, terreno più spento dei
personaggi; attenzione al rosso della squadra sui gironi rossi).

### Forgia — la casa dei diavoletti, dopo il Cortile

- Verso: «Per me si va ne la città dolente» (Inf. III, 1)
- Storia: Esiste già. Cambia il nome del capitolo e la Battaglia della Forgia finisce col rapimento di Favilla (prima tavola).
- Mappa: Forgia dei Titani (c'è).
- Pericolo: Nessuno: si imparano le basi.
- Conviene: Le basi; Uovo e Schegge dalle casse.. Gradi del bot: 2 → 5.
- Colori: #2a1410 #5a2a1a #ff7a1a #ffd27a
- Livelli:
  1. **Primo sangue** (duello): c'è già
  2. **Fuori portata** (fuga): c'è già
  3. **Due mani** (duello): c'è già
  4. **Giù dal bordo** (rompicapo): c'è già
  5. **Il codardo** (duello): c'è già
  6. **Il Fabbro** (custode): c'è già
  7. **Battaglia della Forgia** (squadra): c'è già, con Favilla come compagna al posto del bot anonimo; alla fine l'artiglio prende Favilla
- Custode **Il Fabbro** (vita 180): Com'è oggi: tanta vita e il Maglio. È l'esame del maestro. Dopo il rapimento diventa la tua guida fino al pozzo dei giganti (il ruolo di Virgilio) e tuo compagno nei 2 contro 2 dell'inferno.

### I · Limbo — Il castello dei sette muri

- Verso: «sanza speme vivemo in disio» (Inf. IV, 42)
- Storia: Anime sospese, né buone né cattive. Per passare nel vero inferno bisogna attraversare l'Acheronte, e Caronte i diavoletti non li traghetta.
- Mappa: Mura a gradoni di un castello in rovina, colonne spezzate, un ruscello in basso, nebbia grigio-verde e luce pallida dall'alto. Quasi simmetrica: va bene anche online.
- Pericolo: Gravità ridotta: si salta più lontano e i colpi volano di più. Sono sospese le anime, e lo sei anche tu.
- Conviene: Paracadute, controllo in aria, tiri lunghi.. Gradi del bot: 3 → 5.
- Colori: #1d2522 #55665e #d9cfa8 #a9bdb3
- Livelli:
  1. **Lasciate ogne speranza** (intro): Oltre la porta: arriva alla bandierina saltando fra le mura. Senti quanto voli.
  2. **Senza peso** (duello): Un'ombra testa calda che tira da lontanissimo.
  3. **I sette muri** (rompicapo): Sette bersagli nelle mura, otto colpi. Con poca gravità l'Uovo rimbalza diverso.
  4. **Il ruscello** (squadra): Il primo 2 contro 2 col Fabbro, contro due ombre.
  5. **Gli spiriti magni** (orda): Tu contro tre anime antiche, deboli ma insieme.
  6. **Caronte** (custode): Sulla riva dell'Acheronte.
- Custode **Caronte** (vita 200): Sta sulla barca in mezzo al fiume e colpisce col remo, che spinge come il Mantice verso l'acqua. Il fiume butta fuori. A ogni giro la barca affonda di un gradino: lui diventa più facile da colpire, ma anche tu sei più vicino all'acqua.

### II · Lussuria — La bufera

- Verso: «La bufera infernal, che mai non resta» (Inf. V, 31)
- Storia: Minosse giudica chi entra. Con due diavoletti non sa cosa fare, allora ti giudica a modo suo.
- Mappa: Scogliere spezzate a zig-zag, una gola in mezzo, nubi viola e lampi. Spuntoni d'acciaio indistruttibili dove aggrapparsi col Rampino.
- Pericolo: La bufera: a fine giro una raffica sposta tutti i corpi (non i colpi) di un passo a destra o a sinistra. Una freccia dice per tutto il giro da che parte soffierà. L'eccezione al «niente vento», solo qui e da Lucifero.
- Conviene: Rampino, Mantice, uccisioni nel vuoto.. Gradi del bot: 3 → 6.
- Colori: #1b1229 #4b2d6b #e05fa8 #c9b8ff
- Livelli:
  1. **La bufera infernal** (resisti): Resta sulle scogliere per tre giri: il bot vuole solo buttarti giù.
  2. **Coppie nel vento** (squadra): Tu e il Fabbro contro due anime legate (Paolo e Francesca): si muovono sempre insieme.
  3. **Aggrappati** (rompicapo): Tre bersagli oltre la gola: ci si arriva solo col Rampino sugli spuntoni.
  4. **Spingi col vento** (duello): I punti valgono doppio se il nemico cade nel vuoto con la raffica.
  5. **La ruina** (duello): Un cecchino sulla scogliera più alta, col vento contro.
  6. **Minosse** (custode): Sul trono in mezzo alla gola.
- Custode **Minosse** (vita 220): La coda è un rampino lunghissimo: nel suo turno afferra chi vede più vicino e lo scaglia su una cengia più in basso. Dietro un riparo non ti trova. Mentre la coda è tesa prende danno doppio.

### III · Gola — La piova eterna

- Verso: «Io sono al terzo cerchio, de la piova etterna, maladetta, fredda e greve» (Inf. VI, 7-8)
- Storia: Fango, grandine e neve nera. Cerbero sbarra la strada con tre bocche affamate.
- Mappa: Una conca di fango con tre collinette e una sporgenza alta da un lato. Pozze di fango che rallentano (lo stato «lento» c'è già).
- Pericolo: La grandine: a ogni giro tre chicchi enormi cadono dove un'ombra li annuncia dal giro prima. È la caduta delle casse, ma fa male.
- Conviene: Uovo (nel fango non rimbalza), Mantice.. Gradi del bot: 4 → 6.
- Colori: #1a1d1a #4a4931 #9aa36a #d8dde0
- Livelli:
  1. **Grandine** (intro): Arriva sulla sporgenza senza farti centrare: le ombre ti dicono dove non stare.
  2. **Nel fango** (duello): Duello fra le pozze: chi ci finisce è lento.
  3. **Il banchetto** (raccolta): Cinque casse cadono dal cielo: prendine più del bot.
  4. **Le tre bocche** (orda): Tre cagnacci piccoli e veloci: la prova di Cerbero.
  5. **Ciacco** (duello): Un'anima grassa con tanta vita: si fa prima a spingerla nel fango alto.
  6. **Cerbero** (custode): In mezzo alla conca.
- Custode **Cerbero** (vita 3 × 90): Un corpo enorme fermo al centro e tre teste, ognuna con vita, arma (Lanciarune, Uovo, Tonante) e turno suoi. Un'esplosione in una pozza vicina gli butta il fango in bocca e quella testa salta il turno, come fa Virgilio.

### IV · Avarizia — I massi

- Verso: «Pape Satàn, pape Satàn aleppe!» (Inf. VII, 1)
- Storia: Avari e prodighi spingono massi enormi e si scontrano urlando. Plutone, seduto sull'oro, ti vuole far pagare il passaggio.
- Mappa: Una valle a V con due pendii lunghi e un piano in mezzo; monete d'oro sparse, massi in cima.
- Pericolo: I massi: a ogni giro ne parte uno da ogni pendio e rotola verso il centro. Fanno male a chi trovano e, fermi, fanno da riparo. Sono un colpo grosso e lento che rotola.
- Conviene: Maglio (rimbalza), Tonante.. Gradi del bot: 4 → 7.
- Colori: #22180c #6e4a22 #e8b84a #a7782d
- Livelli:
  1. **Perché tieni?** (intro): Sali in cima al pendio contro i massi che scendono.
  2. **Avari e prodighi** (squadra): 2 contro 2 col Fabbro, i massi passano in mezzo.
  3. **Il tesoro** (raccolta): Più monete del bot in quattro giri.
  4. **Rotola** (rompicapo): Butta tre massi su tre bersagli, un colpo per masso.
  5. **Il prodigo** (duello): Un bot che usa tutto subito: piovono casse.
  6. **Plutone** (custode): Sul mucchio d'oro.
- Custode **Plutone** (vita 250): Ogni colpo che prende gli fa cadere monete. Nel suo turno, se ci arriva, le raccoglie e si cura. Se le prendi tu fai punti e lui resta ferito. Si vede tutto: le monete sono a terra.

### V · Ira — La palude Stige

- Verso: «Tutti gridavano: «A Filippo Argenti!»» (Inf. VIII, 61)
- Storia: Gli iracondi si picchiano nel fango, gli accidiosi borbottano sott'acqua. In fondo brillano rosse le mura di Dite. Flegiàs arriva di corsa sulla sua barca.
- Mappa: Isolotti nella palude, due torri con le fiaccole, le mura rosse di Dite sullo sfondo.
- Pericolo: L'acqua sale: dal terzo giro la palude sale di un gradino per giro e chi ci cade è fuori. Il finale classico dei giochi d'artiglieria, qui dentro la missione.
- Conviene: Globi del teletrasporto, Rampino, Affondo.. Gradi del bot: 5 → 7.
- Colori: #0d1a1c #23484a #4f8b8a #e0532f
- Livelli:
  1. **La palude** (intro): Arriva in cima alla torre prima dell'acqua.
  2. **Gli iracondi** (orda): Tre teste calde che si picchiano anche fra loro: tutti contro tutti.
  3. **Filippo Argenti** (duello): Il bot più rabbioso dell'inferno: attacca sempre, non si ripara mai.
  4. **I segnali** (rompicapo): Accendi le fiaccole delle due torri prima che l'acqua le spenga.
  5. **La barca** (squadra): 2 contro 2 col Fabbro sugli isolotti, con l'acqua che sale.
  6. **Flegiàs** (custode): Sulla palude.
- Custode **Flegiàs** (vita 260): Nel suo turno sperona: corre dritto sull'acqua da un lato all'altro (un Affondo lunghissimo) e travolge chi sta in basso. Prima di partire la scia si illumina: sali in alto e ti passa sotto. Dopo resta fermo e scoperto.

### VI · Eresia — La città di Dite

- Verso: «s'appressa la città c'ha nome Dite» (Inf. VIII, 68)
- Storia: Le porte di ferro rovente ti si chiudono davanti: ora è l'inferno intero a non volerti. Le Furie gridano dalle torri.
- Mappa: Dentro le mura: file di tombe aperte con le fiamme, torri di ferro (travi indistruttibili, come in Blastron), un cancello rovente.
- Pericolo: Le arche: le tombe si aprono e si chiudono a giri alterni. Chi sta dentro un'arca aperta brucia (lo stato c'è già); chiuse sono ripari.
- Conviene: Ripari, Uovo, bruciatura.. Gradi del bot: 5 → 8.
- Colori: #170b09 #3b1712 #ff5a1f #ffcc33
- Livelli:
  1. **Le porte chiuse** (intro): Supera le mura col Rampino e apri il cancello da dentro.
  2. **Le Furie** (orda): Tre cecchine sulle torri, tu sotto.
  3. **Le arche** (duello): Duello fra le tombe: aspetta che si chiudano.
  4. **Farinata** (speciale): Un'anima che non si muove mai, dritta nella sua tomba, ma con la mira perfetta.
  5. **Il messo** (squadra): 2 contro 2 col Fabbro: il cancello si è aperto.
  6. **Medusa** (custode): In cima alla torre più alta.
- Custode **Medusa** (vita 240): Alla fine del suo turno guarda: chi lei vede (linea dritta, nessun muro in mezzo) diventa di pietra e nel turno dopo non si muove, può solo sparare. Un raggio mostra prima dove guarda. Nascondersi conta più che colpire.

### VII · Violenza — Sangue, selva e sabbia

- Verso: «l'infamia di Creti» (Inf. XII, 12)
- Storia: Tre gironi in uno: il fiume di sangue bollente coi centauri, il bosco dei suicidi con le arpie, il deserto sotto la pioggia di fuoco. Il Minotauro fa la guardia.
- Mappa: Due mappe: il Flegetonte con la selva (fiume rosso in basso, alberi secchi che si spezzano) e il Sabbione (piatto, senza ripari).
- Pericolo: Il sangue bollente brucia chi ci cade; gli alberi fermano i colpi finché non li spezzi; sul sabbione piove fuoco (la grandine della Gola, ma brucia).
- Conviene: Cecchino, Lama, Affondo.. Gradi del bot: 6 → 8.
- Colori: #1a090c #8e1b22 #6b6274 #f2a65a
- Livelli:
  1. **Il Flegetonte** (fuga): Attraversa il fiume sui sassi sotto le frecce di tre centauri.
  2. **Nesso** (duello): Un centauro velocissimo: a ogni turno si sposta tantissimo.
  3. **La selva** (rompicapo): Spezza gli alberi giusti per aprire il tiro sui nidi.
  4. **Le arpie** (orda): Uccellacci che a ogni giro piombano su chi sta allo scoperto.
  5. **Il sabbione** (squadra): 2 contro 2 col Fabbro sotto la pioggia di fuoco, senza ripari.
  6. **Il Minotauro** (custode): Sul ciglio della frana.
  7. **Gerione** (passaggio): In groppa a Gerione: tre turni di caduta a spirale, colpisci i bersagli sulle pareti mentre passi.
- Custode **Il Minotauro** (vita 320): Nel suo turno carica in linea dritta (tre volte un Affondo). Se sbatte contro un muro resta stordito un giro e prende danno doppio. Mettiti davanti a un muro e salta all'ultimo.

### VIII · Frode — Le Malebolge

- Verso: «Luogo è in inferno detto Malebolge» (Inf. XVIII, 1)
- Storia: Dieci fossati di pietra con i ponti sopra. Comandano i Malebranche: diavoli come te, ma grossi e bugiardi, i bulli che da sempre prendono in giro i diavoletti.
- Mappa: Fossati a gradoni con archi di pietra indistruttibili; in fondo la pece nera che bolle.
- Pericolo: Ponti falsi: alcuni archi crollano appena ci metti piede; un colpo li fa tremare e te lo dice. La pece: chi ci cade resta incollato ed è fuori.
- Conviene: Tutto; gioco di squadra.. Gradi del bot: 7 → 9.
- Colori: #101112 #3a3d40 #9fbf3f #ff8a2a
- Livelli:
  1. **Malebolge** (fuga): Attraversa i ponti: alcuni crollano.
  2. **I Malebranche** (squadra): Tu e il Fabbro contro tre Malebranche.
  3. **La pece** (duello): Barbariccia: buttalo nella pece prima che ci butti te.
  4. **Il ponte che non c'è** (rompicapo): Malacoda ti indica la strada nella nuvoletta. Mente.
  5. **La fiamma antica** (speciale): Una fiamma che parla (Ulisse) racconta del suo ultimo viaggio verso una montagna in mezzo al mare. Proteggila da due Malebranche per tre giri.
  6. **I ladri** (duello): Ogni volta che lo colpisci, il ladro si scambia di posto con te.
  7. **Malacoda e la banda** (custode): Sopra la pece.
- Custode **Malacoda** (vita 4 × 100): Quattro Malebranche, due alla volta: quando uno cade un altro salta fuori dalla pece. Tu sei col Fabbro. Malacoda parla a ogni turno e metà di quello che dice è falso. Dopo, il Fabbro si ferma: «Il ghiaccio spegne il fuoco. Da qui vai da solo».

### IX · Tradimento — Il lago di Cocito

- Verso: «E quindi uscimmo a riveder le stelle» (Inf. XXXIV, 139)
- Storia: Il lago gelato, quattro zone sempre più fredde. Al centro, nel ghiaccio fino al petto, Lucifero. Il ghiaccio scricchiola: sta bevendo il calore di Favilla.
- Mappa: Lastre di ghiaccio piatte e larghe, facce di anime sotto la superficie (solo decoro), crepe. Al centro il pozzo.
- Pericolo: Ghiaccio: si scivola, e le esplosioni lo rompono. Sotto c'è acqua gelata: chi ci cade è fuori.
- Conviene: Precisione, Cecchino, Paracadute.. Gradi del bot: 8 → 10.
- Colori: #0a1424 #1f4e79 #bfe9ff #d4202a
- Livelli:
  1. **I giganti** (fuga): Nembrot parla una lingua che non esiste («Raphèl maì amècche zabì almi») e lancia massi. Arriva alla mano di Anteo, che ti cala giù.
  2. **Caina** (duello): Duello sul ghiaccio che scivola.
  3. **Antenora** (orda): Traditori che escono dal ghiaccio quando passi vicino.
  4. **Tolomea** (resisti): Ogni due giri ti congeli: puoi solo sparare. Resisti cinque giri.
  5. **Giudecca** (duello): Il bot più forte del gioco (grado 10), da solo, sul ghiaccio più sottile.
  6. **Lucifero** (custode): Al centro del lago. Vedi la sezione 7.
- Custode **Lucifero** (vita 3 fasi): Tre facce, sei ali, la gabbia con Favilla. Tre fasi con ripartenza: le facce, il disgelo, due fiamme.

## Lucifero (girone IX, un livello in tre fasi)

Un gigante piantato nel ghiaccio fino al petto, tre facce (rossa, gialla, nera), sei ali
che col vento di fine giro spingono tutti verso i bordi; al petto una gabbia con Favilla.
Se perdi riparti dalla fase in cui sei. Fase 1, le tre facce: ognuna è un bersaglio con la
sua vita e il suo turno (rossa Lanciarune a pioggia, gialla cecchino, nera soffio di ghiaccio
che rallenta). Fase 2, il disgelo: il ghiaccio si spacca in lastre e l'acqua sale a ogni
giro, le mani spazzano il lago; colpisci la gabbia finché si apre. Fase 3, due fiamme:
Favilla torna a combattere con te, due contro uno; si vince buttandolo nel pozzo al centro
(uccisione ambientale) o finendogli la vita.

## Purgatorio (9 livelli, dopo i titoli)

Alba, mare, erba e pietra chiara. Sempre 2 contro 2 con Favilla. Ogni cornice ha **una sola
regola** della lista bianca delle regole degli eventi, così costa poco. Sette segni sulle
corna del diavoletto che si chiudono uno alla volta.

| # | Cornice | Livello | Regola |
|---|---|---|---|
| 0 | Spiaggia | Catone | Tu e Favilla resistete tre giri contro Catone (insegna il 2 contro 2 con lei) |
| 1 | Superbia | I massi sulle spalle | Doppia vita, si muovono piano e saltano basso |
| 2 | Invidia | Lo specchio | I nemici copiano il tuo draft |
| 3 | Ira | Il fumo | La camera resta vicina: vedi solo attorno a te |
| 4 | Accidia | Di corsa | Metà tempo per turno, globi doppi |
| 5 | Avarizia | Faccia a terra | Niente salto: si cammina, Rampino e globi |
| 6 | Gola | L'albero | Le casse sono appese a un albero: solo il Rampino ci arriva; nemici magri e veloci |
| 7 | Lussuria | Il muro di fuoco | Un muro di fuoco taglia la mappa: i diavoli passano, le ombre nemiche no |
| 8 | Eden | Il Drago | Custode: i morsi scavano pezzi enormi di terreno e la mappa si rimpicciolisce |

## Paradiso (8 livelli)

Il più breve: cerchi concentrici di luce verso il centro. Pochi duelli, molte prove; gli
spiriti sono avversari leali. Il cattivo resta l'Ombra di Lucifero, fino al Primo Mobile.

| # | Cielo | Livello | Cosa succede |
|---|---|---|---|
| 1 | Luna | Le macchie | Rompicapo: metà dei bersagli sono riflessi, colpirli non conta |
| 2 | Mercurio e Venere | Le luci che danzano | Bersagli che si spostano e saltano a ogni giro |
| 3 | Sole | La corona | Dodici luci in cerchio, da colpire nell'ordine che si legge sopra |
| 4 | Marte | La croce | 2 contro 2 leale contro due spiriti guerrieri, senza globi |
| 5 | Giove | L'Aquila | Custode: sei luci con la loro vita, ogni due giri cambiano forma e posto |
| 6 | Saturno | La scala d'oro | Corsa in salita contro due ombre: vince chi arriva prima in cima |
| 7 | Stelle fisse | L'esame | Tre prove che ricordano l'Addestramento: un colpo, resisti, salva Favilla |
| 8 | Primo Mobile | L'Ombra | Custode finale: a ogni giro la gravità si gira; poi l'Empireo senza battaglia |

## Cosa serve nel motore

Basso: gravità diversa per missione, pioggia annunciata (come le casse), spinta a fine giro
con freccia, zone che bruciano o rallentano (gli stati ci sono), stati pietra e congelato,
i verbi nuovi, le regole a lista bianca. Medio: acqua che sale, massi che rotolano, ghiaccio
che scivola e si rompe, ponti che crollano, custodi grandi o a più pezzi, fasi con
ripartenza. Tutto quello che tocca il terreno va anche in `server/terreno.go`. Scartati
perché troppo cari: barche e mappe che si muovono davvero (si usano trucchi che si vedono
uguale: barca che affonda, scia annunciata, gravità che si gira).

## Ordine di lavoro

1. La mappa a imbuto con la regola «non si vede oltre il prossimo bloccato».
2. Le mappe di tutti i livelli e i pericoli, a blocchi (Limbo-Lussuria-Gola, Avarizia-Ira-
   Eresia, Violenza-Frode-Tradimento, purgatorio e paradiso), tutte in ALLENAMENTO.
3. I pericoli in `client/sim/` con il server in pari; poi nelle rotazioni online.
4. Favilla, il Fabbro, i nemici e i custodi come pelli; Lucifero per ultimo.
5. Le missioni vere in `client/sim/levels.lua` (via Copione), un girone alla volta, tarate
   con `tools/arena/collaudo.lua`.

## Scartato (dettagli sulla pagina)

Stile pixel come la reference; mappa a spirale; schede orizzontali; mappa a rami;
capitoli bloccati in grigio (spoiler); gironi che si aprono con le stelle; 81 livelli;
purgatorio e paradiso lunghi come l'inferno; scene animate; Virgilio come guida (il
Fabbro fa lo stesso ruolo); vento vero sui colpi (la raffica sposta solo i corpi);
supplizi crudi; angeli come nemici; Lucifero come bot grosso o come scena da guardare;
barche e mappe che si muovono davvero; trama dello sfratto.
