# Progressione, podio, equipaggiamento, premi

Codice: `client/sim/abilita.lua`, `equipaggiamento.lua`, `assetto.lua`,
`riconoscimenti.lua`; schermate `client/menu/profilo.lua`, `podio.lua`,
`armeria.lua`. Principi in [../game_design_competitivo.md](../game_design_competitivo.md),
futuro in [../roadmap.md](../roadmap.md) (aree 9, 10).

## Decisioni prese

| Data | Decisione | Dove |
|---|---|---|
| 19 ott | L'equipaggiamento modifica le statistiche (velocità a terra, salto, velocità in aria). | PR #7 |
| 20 ott | **Niente pay-to-win**: in partita contano abilità e strategia; le personalizzazioni a pagamento sono solo estetiche. | docs/design.md |
| 23 ott | Equipaggiamento = **sidegrade** (più/meno in %) + **tier** solo estetici; niente ranked permanente: modalità Torneo a tempo con normalizzazione. | game_design_competitivo.md |
| 23 ott | **Albero delle abilità**: sì, piccolo, sempre rispeccabile gratis; meno punti che nodi (20 su 70), nodi misti (statistiche + risorse), divario ≤ 10% in partita normale; nel Torneo tutti al massimo. 3 loadout salvati. La differenza di livello si deve sentire ma deve essere colmabile con la strategia. | game_design_competitivo.md, PR #33 |
| 23 ott | Riconoscimenti di fine partita: sì. **Calendario di eventi** al posto delle stagioni, premi a fasce (es. top 100 skin + pezzo, 101–300 skin). Negozio: solo estetica; il resto marginale e raggiungibile giocando. | game_design_competitivo.md |
| 23 ott | Implementato: 3 rami (Mobilità, Difesa, Arsenale), 2 punti per livello, cancello di riga 3; 4 set × 4 slot (Corvo doppio salto, Fornace bruciatura, Leviatano spinta e caduta, Vuoto teletrasporto), tier da partite giocate 0/10/30; XP 120/80/60/50 per piazzamento + 25 per riconoscimento, livello n→n+1 = 100 + 25(n−1); podio 1,5 s dopo la fine (tutti valori Claude). Progresso locale dell'hot-seat al robot 1. | PR #33 |
| 23 ott | Revisione del coordinatore: niente voci "in arrivo"; nodi e bonus solo per meccaniche già in gioco; negozio, calendario eventi e valuta tolti finché non esistono account e server (erano nel commit ad29ffd). | PR #33 |
| 24 ott | Col Nucleo rimosso: nodi "Globo di riserva" (+1 teletrasporto) e "Ali di riserva" (+1 paracadute); Guscio e Passo leggero tolti; Vuoto B e Fornace +1 globo; Corvo B = 2 salti in aria; riconoscimento Tesoriere tolto. | PR #39 |
| 24 ott | Colori delle squadre solo da `ui.C.SQUADRA`, ordine Rosso, Blu, Verde, Oro. | PR #33 |
| 29 ott | Progressione **sul server** (XP, livello, mastery, inventario, loadout), rating nascosto solo per il matchmaking, profilo pubblico leggero. **Statistiche di ogni tipo** con obiettivi a soglie esponenziali e **badge** visibili accanto al nome. Negozio: estetica + valuta morbida + pacchetti; tornei a iscrizione con moneta dura; pass dell'evento più avanti. | docs/roadmap.md |
| 29 ott | **Set liberi e progressione a poco a poco** (Sergio): i pezzi si potranno mischiare (non più solo 4 set fissi, i pezzi nuovi si fanno con l'editor); all'inizio non si regala un set completo, si parte senza niente e si comprano i pezzi. Il gioco è da late game ma con progressione: il divario lo colmano matchmaking, livello fisso nei tornei e il fatto che in qualche mese si completa l'equipaggiamento; escono sempre pezzi nuovi per far girare il meta. | thread del bot |
| 29 ott | **Campagna** (proposta https://claude.ai/artifact/DaLXhFApbxLpa1reyPtenC, Sergio: "applica tutto"): bottone CAMPAGNA in home con i capitoli in schede; **Capitolo 0 Addestramento** = le 8 lezioni (la lezione delle casse diventa **Il Tonante**: col rinculo sul pilastro, le casse cadono a caso e non fanno un rompicapo); poi **I girone: la Forgia**, che si apre con 8 stelle: Primo sangue, Fuori portata (si arriva solo col globo), Due mani (primaria e secondaria nello stesso turno), Giù dal bordo (tre bersagli da buttare nel vuoto), Il codardo, e il custode **Il Fabbro** (180 di vita e il Maglio). Bot con un **carattere** (codardo, testa calda, cecchino, spingitore: pesi diversi del bot, `bot.CARATTERI`). In missione **equipaggiamento fisso** uguale per tutti (niente assetto del profilo). **Stelle**: fatta, entro N turni, bonus della missione (senza morire, un solo globo, buttalo nel vuoto); sulla carta si legge cosa serve. **Aiuto silenzioso**: dalla terza missione persa di fila i bot scendono di un livello e partono con 3/4 della vita, senza dirlo. Missioni come dati (`client/sim/campagna.lua`, motore `client/sim/missioni.lua`) con pochi verbi (usa, raggiungi, colpisci, abbatti), così un giorno le manda il server. Il I girone è anticipato alla fase 2 (roadmap). Scelte di Claude: soglie delle stelle alla mediana dei turni del bot normale nel collaudo (`strumenti/arena/collaudo.lua`); arene d'acciaio a conci; il profilo vecchio tiene le stelle delle lezioni. | questa PR |
| 29 ott | **Taratura delle stelle della campagna** (Sergio: "parametri che ci facciano capire se ci sono missioni in cui le stelle vanno abbassate [...] se dimezzo la vita dei bot, o se la raddoppio, prevedere di quanto cambiano"): il collaudo dice per ogni missione quante delle vinte dal bot normale prendono la seconda e la terza stella e cosa guardare (seconda stella a più di un turno dalla mediana, bonus sotto il 15% o sopra l'85% delle vinte, bot normale sotto il 60% di vinte; se nemmeno il difficile la vince è il bot che non la sa giocare e si tara a mano). Con `--vita 0.5,1,2` rigioca con la vita degli avversari moltiplicata e dice di quanti turni si sposta la seconda stella a ogni raddoppio; con `--ritocchi` qualunque altro numero. Gira da solo su ogni PR che cambia le regole (avvisi sulla PR, non blocca). Scelte di Claude: il bot normale come giocatore di riferimento; avvisi e non errori, perché il bot non è una persona (un bonus "senza morire" gli riesce più facile, "buttalo nel vuoto" non lo cerca). | `strumenti/arena/collaudo.lua`, `.github/workflows/stelle.yml`, questa PR |
| 29 ott | **L'Addestramento parte dalle basi** (Sergio: la prima partita guidata era troppo, "le cose base"): tre lezioni nuove all'inizio, una cosa per lezione: **Camminare**, **Saltare** (un gradino più alto di quello che si sale camminando), **Sparare** (col Lanciarune, e lì si impara ad annullare la mira). Poi le meccaniche, e **la Prima partita diventa l'ultima** del capitolo: dopo le lezioni, una prima vera partita corta che mette in pratica tutto (Sergio). Il capitolo ha ora 12 lezioni; per il I girone servono sempre 8 stelle. Il I girone finisce, dopo il Fabbro, con **la Battaglia della Forgia**: una partita completa 2 contro 2 (tu e un compagno bot normale contro il Fabbro e il cecchino facile; collaudo: il bot normale al tuo posto vince il 50%, il difficile l'83%), stelle per la vittoria, 3 abbattuti e al massimo una morte (Claude). **GIOCA per chi è nuovo** porta alla prima delle basi (Camminare, Saltare, Sparare) che manca, finché non le ha finite tutte; poi va online (Claude, reversibile). | questa PR |
| 29 ott | **Il codardo codardo davvero e i personaggi parlano** (Sergio): il codardo a ogni turno attacca subito (così guadagna i globi), una volta sola, e poi scappa col globo nella tana peggiore: un posto coperto dall'alto e che nessuno vede (`tana` nei pesi del carattere, più lanci provati). I bot con un carattere e i custodi dicono battute in una nuvoletta sopra la testa quando comincia il loro turno, colpiscono, li colpiscono, scappano, abbattono o muoiono (`client/battaglia/battute.lua`, solo nel client: la partita non cambia). Col collaudo (vita 100 e danni della #79) il bot normale lo finisce in 2 turni: restano la seconda stella a 3 e il limite di 7 turni della #79. | questa PR |
| 29 ott | **Primi passi, una lezione sola** (Sergio: "i primi livelli del tutorial sono veramente troppo basilari"): Camminare, Saltare e Sparare diventano un percorso. Si parte **senza armi**. Cammini fino a una **bandierina a scacchi**, salti sul gradino (stare sopra è fatto), **ti piove una cassa dal cielo** col Lanciarune e la sua **scheda tecnica** (la Carta, `battaglia/scheda.lua`) ferma il gioco finché non tocchi PROVALA, poi spari al bersaglio. **Niente tempo e niente turni** ("i tutorial devono essere una cosa totalmente diversa rispetto alla partita"): se manchi ti ridà subito il colpo e scrive "Ritenta! Prendi confidenza con i comandi, prenditi il tuo tempo" con la frase per l'analogico. **Le stelle contano i tiri a vuoto**, non i turni (Sergio: la stella "in pochi turni" solo nelle partite a turni contro i bot, mai nelle lezioni): fatta, al massimo 2 a vuoto, al primo tiro. **Niente cerchi di cura nelle lezioni**. **Armi e draft** spostata appena prima della Prima partita. **Ogni arma nuova mostra la sua scheda**: nelle lezioni sempre, in locale la prima volta (`profilo.armi`); online ancora niente, in attesa della scelta di Sergio sulla variante (proposta: il Cartellino). Il meccanismo (`senza_tempo`, `senza_armi`, `casse`, `prendi`) vale per tutte le lezioni: la scaletta accorpata in 6 lezioni è proposta e aspetta Sergio. | questa PR |

## Scartate

- Nodi dell'albero legati al Nucleo (23 ott): superati con la rimozione del Nucleo.
- Mezzi Nuclei come sconto dell'albero: "il primo è gratis" (Claude, 23 ott).
- Camminare, Saltare e Sparare come tre lezioni separate (29 ott, Sergio: troppo basilari; ora Primi passi).
- Stelle "in N turni" nelle lezioni (29 ott, Sergio): nelle lezioni non si aspetta mai un turno per riprovare.
- Scheda tecnica coi numeri veri, con un video, o solo nell'Armeria (29 ott, Claude): i numeri cambiano a ogni bilanciamento, il video pesa, e nell'Armeria nessuno la apre al momento giusto.
- Classifica globale permanente con rating visibile (29 ott): contro la
  decisione del 23 ott; il rating resta nascosto.
- Pubblicità con premio, app a pagamento, casse a pagamento con contenuto
  casuale (29 ott).
- Campagna (29 ott): storia con dialoghi e scene (contro "niente popup", costosa;
  basta una riga per missione); mappa del mondo a rami (più interfaccia, scelte
  senza senso all'inizio); missioni generate a caso (non garantiscono che serva
  la meccanica: il caso va nel rompicapo del giorno); equipaggiamento del
  giocatore in campagna (impossibile da tarare, sembra pay-to-win); sbloccare
  armi online con la campagna (il draft è uguale per tutti); energia o vite,
  saltare missioni pagando; bot che barano (i custodi sono più forti solo con
  regole che si vedono); stelle solo a turni (monotone); difficoltà a occhio
  (la misura il collaudo); obiettivi solo come funzioni Lua (non arrivano dal
  server: restano per la partita guidata).

## Aperte

- Nome della valuta morbida ("Scorie"? il nome viene dalla vecchia direzione
  artistica).
- Premi delle stelle della campagna e gironi dopo il primo (fase 5).
- Giù dal bordo: il bot del collaudo non la vince mai (i test provano che ogni
  bersaglio cade con un colpo): da guardare come la gioca Sergio.
- Sconto del negozio e prezzi: da provare con sola valuta morbida in fase 4.
